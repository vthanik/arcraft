/****************************************************************************************************
|
| Macro Name:      tc_p1_elig
|
| SAS Version:     9.1
|
| Created By:      Suzanne Johnes
|
| Date:            29 April 2008
|
| Macro Purpose:   Create ELIG A&R data set for Phase1 requirements
|                  (PG & XO studies)
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| ------------------------------------------------------------------
| ------------------------------------------------------------------
|                 FOR INPUT PARAMETERS, REFER TO
|                  DOCUMENTATION FOR TC_P1_ELIG
| ------------------------------------------------------------------
| ------------------------------------------------------------------
|
| Global macro variables created: NONE
|
| Macros called:
|(@) tu_putglobals
|(@) tr_putlocals
|(@) tu_valparms
|(@) tu_nobs
|(@) tu_abort
|(@) tc_elig
|(@) tu_rantrt
|(@) tu_p1_acttrt_pg
|(@) tu_attrib
|(@) tu_misschk
|(@) tu_tidyup
|
|****************************************************************************************************
| Change Log
|
| Modified By:              Suzanne Johnes (SEJ66932)
| Date of Modification:     16-Oct-08
| New version/draft number: 2
| Modification ID:          NA
| Reason For Modification:  Changes 1 & 2 are based on the updated TC_ELIG macro and require P1 macro 
|                           to surface these parameters.
|                           1. Added data set parameters, which will be passed to the new version of 
|                              TU macros: demodset, enroldset, exposuredset, investigdset, racedset, 
|                              randalldset, randdset, visitdset
|                           2. Added parameter DECODEPAIRS, which will be passed to %tu_decode
|                           3. Added calls to %tu_nobs to check that input ELIG dataset is not empty
|                              before performing validation on IEFORMAT macro parameter.
|                           4. Changed &treatvarsyn in TC_ call to 'N' as this parameter shall be 
|                              referenced further on during the call to tu_rantrt
|                           5. Validation check included to prevent output dataset having the same 
|                              name as the input dataset 
|                           6. EXPOSUREDSET to be passed as a macro parameter to tu_p1_acttrt_pg 
|                           7. Included validation check for treatvarsyn, attributesyn, misschkyn and 
|                              trt_dev_exists
|                           8. Allow for parameter values of IEFORMAT to contain '.' at end of format 
|                              name e.g. '$IEFMT.' - this is now default value of parameter IEFORMAT. 
| 
| Modified By:           
| Date of Modification:   
| New version/draft number:
| Modification ID:          
| Reason For Modification:
|
****************************************************************************************************/


%macro tc_p1_elig (
  dsetin_elig       = dmdata.elig,     /* Input dataset name */
  dsetout           = ardata.elig,     /* Output dataset name */
  preprocess        = ,                /* Any processing required after reading in the input dataset */
  postprocess       = ,                /* Any processing required before writing out to final output dataset */
  ieformat          = $iefmt.,         /* Name of user specified format for coding the IETEXT variable */
  trt_dev_exists    = N,               /* Do Treatment Deviations exists for your study? */
  demodset          = dmdata.demo,     /* Name of DEMO dataset to use */        
  enroldset         = dmdata.enrol,    /* Name of ENROL dataset to use */       
  exposuredset      = dmdata.exposure, /* Name of EXPOSURE dataset to use */    
  investigdset      = dmdata.investig, /* Name of INVESTIG dataset to use */ 
  racedset          = dmdata.race,     /* Name of RACE dataset to use */        
  randalldset       = dmdata.randall,  /* Name of RANDALL dataset to use */     
  randdset          = dmdata.rand,     /* Name of RAND dataset to use */        
  visitdset         = dmdata.visit,    /* Name of VISIT dataset to use */ 
  commonvarsyn      = Y,               /* Add common variables */
  treatvarsyn       = Y,               /* Add treatment variables */
  datetimeyn        = Y,               /* Derive datetime variables */
  decodeyn          = Y,               /* Decode coded variables */
  derivationyn      = Y,               /* Dataset specific derivations */
  attributesyn      = Y,               /* Reconcile A&R dataset with planned A&R dataset */
  misschkyn         = Y,               /* Print warning message for variables in &DSETOUT with missing values on all records */
  agemonthsyn       = N,               /* Calculation of age in months */
  ageweeksyn        = N,               /* Calculation of age in weeks */
  agedaysyn         = N,               /* Calculation of age in days */
  refdateoption     = TREAT,           /* Reference date source option */
  refdatevisitnum   = ,                /* Reference date visit number */
  refdatesourcedset = ,                /* Reference date source dataset */
  refdatesourcevar  = ,                /* Reference date source variable */
  refdatedsetsubset = ,                /* Where clause applied to source dataset */
  trtcdinf          = ,                /* Informat to derive TRTCD from TRTGRP */
  ptrtcdinf         = ,                /* Informat to derive PTRTCD from PTRTGRP */
  dsplan            = &g_dsplanfile,   /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
  dsettemplate      = ,                /* Planned A&R dataset template name */
  sortorder         = ,                /* Planned A&R dataset sort order */
  decodepairs       = ,                /* Code and decode variables in pair */ 
  formatnamesdset   = ,                /* Format names dataset name */
  noderivevars      =                  /* List of variables not to derive */
  );

  /*
  / Echo parameter values and global macro variables to the log
  /----------------------------------------------------------------------------*/
  %local MacroVersion macroname;
  %let MacroName=&sysmacroname.;
  %let MacroVersion=2;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals();

  /*
  / Parameter validation
  /----------------------------------------------------------------------------*/
  %let dsetin_elig    = %nrbquote(&dsetin_elig.);               
  %let dsetout        = %nrbquote(&dsetout.);
  %let preprocess     = %nrbquote(&preprocess.);
  %let postprocess    = %nrbquote(&postprocess.);
  %let ieformat       = %nrbquote(&ieformat.);
  %let trt_dev_exists = %nrbquote(%upcase(&trt_dev_exists));
  %let treatvarsyn    = %nrbquote(%upcase(&treatvarsyn));
  %let attributesyn   = %nrbquote(%upcase(&attributesyn));
  %let misschkyn      = %nrbquote(%upcase(&misschkyn));

  /* Check for valid parameter values
  /  set up a macro variable to hold the pv_abort flag
  /----------------------------------------------------------------------------*/
  %local pv_abort prefix preprocessdset postprocessdset loopi listvars thisvar;
  %let pv_abort = 0 ;
  %let prefix = _tc_p1_elig;   /* Root name for temporary work datasets */

  /*
  / If the input dataset name is the same as the output dataset name,
  / write an error to the log.
  /----------------------------------------------------------------------------*/
  %if %qscan(&dsetin_elig, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
    %do;
      %put %str(RTE)RROR: &sysmacroname: The input dataset name DSETIN(=&dsetin_elig) is the same as output data set name DSETOUT(=&dsetout).;
      %let pv_abort=1;
    %end; 

  /*
  / Check for required parameters.
  /----------------------------------------------------------------------------*/
  
  %let listvars=DSETIN_ELIG DSETOUT;

  %do loopi=1 %to 2;
    %let thisvar=%scan(&listvars, &loopi, %str( ));
    %let &thisvar=%nrbquote(&&&thisvar);
    
    %if &&&thisvar eq %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: The parameter &thisvar cannot be blank.;
       %let pv_abort=1;
    %end;    
  %end;  /* end of do-to loop */

  /* Check for valid values of TREATVARSYN, ATTRIBUTESYN, MISSCHKYN and TRT_DEV_EXISTS */ 
  %tu_valparms(
    macroname=&macroname., 
    chktype=isOneOf, 
    pv_varsin= treatvarsyn attributesyn misschkyn trt_dev_exists,      
    valuelist = Y N, 
    abortyn = N
    );

  /*
  / Validation of dataset
  /   Check existence of datasets and variables
  /----------------------------------------------------------------------------*/

  * Macro Parameter DSETIN_ELIG;
  %if not %sysfunc(exist(&dsetin_elig)) %then 
  %do;
    %put RTE%str(RROR): &sysmacroname.: DSETIN_ELIG(=&dsetin_elig) does not exist; 
    %let pv_abort = 1;
  %end;

  * Macro Parameter IEFORMAT;
  %if %tu_nobs(&dsetin_elig) gt 0 %then
    %do;

    %if %length(&ieformat) = 0 %then
      %do;
        %put %str(RTE)RROR: &macroname: Macro parameter (ieformat) cannot be blank; 
        %let pv_abort = 1;
    %end;
   
    * Check user supplied format for coding IETEXT variable exists in formats catalog;
    %if &ieformat ne  %then
      %do;

       %if %index(&ieformat,.) >0 %then 
         %do;
           %let fmttemp=%upcase(%scan(%scan(&ieformat,1,'.'),-1,'$'));
         %end;
         %else %do;
           %let fmttemp=%upcase(%scan(&ieformat,-1,'$'));
         %end;

       %if %sysfunc(cexist(rfmtdir.formats.&fmttemp..formatc)) eq 0 %then
         %do;
           %put %str(RTE)RROR: &macroname: The format &ieformat does not exist.; 
           %let pv_abort = 1;
         %end;

    %end;

  %end;
   
  /*
  / Complete validation
  /----------------------------------------------------------------------------*/
  %if %eval(&g_abort. + &pv_abort.) gt 0 %then %do;
    %put %str(RTE)RROR: &macroname: Macro has failed parameter validation check for reasons stated with %str(RTE)RRORs above;
    %tu_abort(option=force);
  %end;

  /*
  / NORMAL PROCESSING
  /----------------------------------------------------------------------------*/

  /*
  / Pre-processing of input dataset
  /   This step allows for the user to pre-process the input dataset in way of
  /   using simple SAS code.
  /   e.g. in the driver call, the user could include information such as
  /   preprocess = if 1 LE SUBJID LE 5 then studypart='A' else studypart = 'B' ;
  /----------------------------------------------------------------------------*/
  %let preprocessdset = &dsetin_elig;

  %if %nrbquote(&preprocess) ne %then %do;
     data &prefix._preprocess;
        set &dsetin_elig ;
        %unquote(&preprocess);;
     run;
     %let preprocessdset = &prefix._preprocess;
  %end;

  /*
  / Derivation of IETEXT (Criteria text) variable using user 
  / specified format created from concatenation of IECRTYCD 
  / (Criteria type code) and / IECRTNUM (Criteria / number failed)
  /------------------------------------------------------------------*/
  %if %tu_nobs(&dsetin_elig) gt 0 %then
    %do;
      data &prefix._elig1(drop=ietemp);
        set &preprocessdset;
          ietemp=compress(iecrtycd || iecrtnum);
          ietext=put(ietemp, %upcase(&fmttemp..));
      run;
      %let preprocessdset = &prefix._elig1;
  %end;

  /*
  / Call DAMA macro tc_elig
  /----------------------------------------------------------------------------*/
  %tc_elig (
    dsetin            = &preprocessdset,     /* Input dataset name */
    dsetout           = &prefix._elig2,      /* Output dataset name */
    demodset          = &demodset,           /* Name of DEMO dataset to use */        
    enroldset         = &enroldset,          /* Name of ENROL dataset to use */       
    exposuredset      = &exposuredset,       /* Name of EXPOSURE dataset to use */    
    investigdset      = &investigdset,       /* Name of INVESTIG dataset to use */        
    racedset          = &racedset,           /* Name of RACE dataset to use */        
    randalldset       = &randalldset,        /* Name of RANDALL dataset to use */     
    randdset          = &randdset,           /* Name of RAND dataset to use */        
    visitdset         = &visitdset,          /* Name of VISIT dataset to use */  
    commonvarsyn      = &commonvarsyn,       /* Add common variables */
    treatvarsyn       = N,                   /* Add treatment variables */
    datetimeyn        = &datetimeyn,         /* Derive datetime variables */
    decodeyn          = &decodeyn,           /* Decode coded variables */
    derivationyn      = &derivationyn,       /* Dataset specific derivations */
    attributesyn      = N,                   /* Reconcile A&R dataset with planned A&R dataset */
    misschkyn         = N,                   /* Print warning message for variables in &DSETOUT with missing values on all records */
    agemonthsyn       = &agemonthsyn,        /* Calculation of age in months */
    ageweeksyn        = &ageweeksyn,         /* Calculation of age in weeks */
    agedaysyn         = &agedaysyn,          /* Calculation of age in days */
    refdateoption     = &refdateoption,      /* Reference date source option */
    refdatevisitnum   = &refdatevisitnum,    /* Reference date visit number */
    refdatesourcedset = &refdatesourcedset,  /* Reference date source dataset */
    refdatesourcevar  = &refdatesourcevar,   /* Reference date source variable */
    refdatedsetsubset = &refdatedsetsubset,  /* Where clause applied to source dataset */
    trtcdinf          = &trtcdinf,           /* Informat to derive TRTCD from TRTGRP */
    ptrtcdinf         = &ptrtcdinf,          /* Informat to derive PTRTCD from PTRTGRP */
    dsplan            = &dsplan,             /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
    dsettemplate      = &dsettemplate,       /* Planned A&R dataset template name */
    sortorder         = &sortorder,          /* Planned A&R dataset sort order */
    formatnamesdset   = &formatnamesdset,    /* Format names dataset name */
    noderivevars      = &noderivevars        /* List of variables not to derive */
    );

   * Set a temporary macro variable containing dataset reference ;
   %let postprocessdset = &prefix._elig2;

  /*
  / Treatment.assignment
  /----------------------------------------------------------------------------*/
  %if &treatvarsyn eq Y %then
  %do;

     /*
     / Add treatment variables to dataset
     / ---------------------------------------------------------------------------*/
     %tu_rantrt ( dsetin      = &prefix._elig2  /* Input dataset name */
                 ,dsetout     = &prefix._elig3  /* Output dataset name */
                 ,ptrtcdinf   = &ptrtcdinf      /* Informat to derive PTRTCD from PTRTGRP */
                 ,randalldset = &randalldset    /* RANDALL data set name */
                 ,randdset    = &randdset       /* RAND data set name */
                 ,trtcdinf    = &trtcdinf       /* Informat to derive TRTCD from TRTGRP */
                );

     /*
     / Call tu_p1_acttrt to cater for any treatment deviations
     /---------------------------------------------------------------------------*/
     %tu_p1_acttrt_pg (dsetin         = &prefix._elig3,   /* Name of input dataset */ 
                       dsetout        = &prefix._elig4,   /* Name of output dataset */
                       trt_dev_exists = &trt_dev_exists,  /* Do treatment deviations exist for your study? */
                       exposuredset   = &exposuredset     /* Name of EXPOSURE dataset to use */
                       );
 
     * Set a temporary macro variable containing dataset reference ;
     %let postprocessdset = &prefix._elig4;

   %end;  /*EndOf if treatvarsyn = Y */

   /*
   / Post-processing of input dataset
   /   This step allows for the user to post-process the dataset in way of
   /     using simple SAS code. This post-process step is invoked before
   /     calling of the tu_attrib and tu_misschk macros
   /   e.g. in the driver call, the user could include information such as
   /     postprocess = where studypart = 'B' ;
   /----------------------------------------------------------------------------*/
   %let postprocessdset = &postprocessdset; 

   %if %nrbquote(&postprocess) ne %then %do;
      data &prefix._postprocess;
         set &postprocessdset;
         %unquote(&postprocess);;
      run;
      %let postprocessdset=&prefix._postprocess;
   %end;

   /*
   / Reconcile A&R dataset with planned A&R dataset.
   /----------------------------------------------------------------------------*/
   %if &attributesyn eq Y %then %do;
     %tu_attrib(dsetin       = &postprocessdset,
                dsetout      = &dsetout,
                dsplan       = &g_dsplanfile,
                dsettemplate = &dsettemplate,
                sortorder    = &sortorder
                );
    %end;

    %else %do;
      data &dsetout;
        set &postprocessdset;
      run;
    %end;

    /*
    / Call tu_misschk macro in order to identify any variables in the output
    / dataset which have missing values on all records.
    /----------------------------------------------------------------------------*/
    %if &misschkyn eq Y %then %do;
      %tu_misschk(dsetin = &dsetout);
    %end;

    /*
    / Delete temporary datasets used in this macro.
    /----------------------------------------------------------------------------*/
    %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tc_p1_elig;
