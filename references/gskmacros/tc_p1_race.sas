/****************************************************************************************************
|
| Macro Name:      tc_p1_race
|
| SAS Version:     9.1
|
| Created By:      Suzanne Johnes
|
| Date:            29 April 2008
|
| Macro Purpose:   Create RACE A&R data set for Phase1 requirements
|                  (PG & XO studies)
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| ------------------------------------------------------------------
| ------------------------------------------------------------------
|                 FOR INPUT PARAMETERS, REFER TO
|                  DOCUMENTATION FOR TC_P1_RACE
| ------------------------------------------------------------------
| ------------------------------------------------------------------
|
| Global macro variables created: NONE
|
| Macros called:
|(@) tu_putglobals
|(@) tr_putlocals
|(@) tu_valparms
|(@) tu_abort
|(@) tc_race
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
| Date of Modification:     17-Oct-08
| New version/draft number: 2
| Modification ID:          NA
| Reason For Modification:  Changes 1 & 2 are based on the updated TC_RACE macro and require P1 macro 
|                           to surface these parameters.
|                           1. Added data set parameters, which will be passed to the new version of 
|                              TU macros: demodset, enroldset, exposuredset,investigdset, randalldset,
|                              randdset, visitdset
|                           2. Added parameter DECODEPAIRS, which will be passed to %tu_decode
|                           3. Changed &treatvarsyn in TC_ call to 'N' as this parameter shall be 
|                              referenced further on during the call to tu_rantrt
|                           4. Validation check included to prevent output dataset having the same 
|                              name as the input dataset 
|                           5. EXPOSUREDSET to be passed as a macro parameter to tu_p1_acttrt_pg 
|                           6. Included validation check for treatvarsyn, attributesyn, misschkyn and 
|                              trt_dev_exists
|                              
| Modified By:           
| Date of Modification:   
| New version/draft number:
| Modification ID:          
| Reason For Modification:
|
****************************************************************************************************/

%macro tc_p1_race (
  dsetin_race       = dmdata.race,     /* Input dataset name */
  dsetout           = ardata.race,     /* Output dataset name */
  preprocess        = ,                /* Any processing required after reading in the input dataset */
  postprocess       = ,                /* Any processing required before writing out to final output dataset */
  trt_dev_exists    = N,               /* Do Treatment Deviations exists for your study? */
  demodset          = dmdata.demo,     /* Name of DEMO dataset to use */        
  enroldset         = dmdata.enrol,    /* Name of ENROL dataset to use */       
  exposuredset      = dmdata.exposure, /* Name of EXPOSURE dataset to use */    
  investigdset      = dmdata.investig, /* Name of INVESTIG dataset to use */ 
  randdset          = dmdata.rand,     /* Name of RAND dataset to use */        
  randalldset       = dmdata.randall,  /* Name of RANDALL dataset to use */     
  visitdset         = dmdata.visit,    /* Name of VISIT dataset to use */  
  attributesyn      = Y,               /* Reconcile A&R dataset with planned A&R dataset */
  commonvarsyn      = Y,               /* Add common variables */
  datetimeyn        = Y,               /* Derive datetime variables */
  decodeyn          = Y,               /* Decode coded variables */
  misschkyn         = Y,               /* Print warning message for variables in &DSETOUT with missing values on all records */ 
  treatvarsyn       = Y,               /* Add treatment variables */
  agedaysyn         = N,               /* Calculation of age in days */
  agemonthsyn       = N,               /* Calculation of age in months */
  ageweeksyn        = N,               /* Calculation of age in weeks */
  refdateoption     = TREAT,           /* Reference date source option */
  refdatedsetsubset = ,                /* Where clause applied to source dataset */
  refdatesourcedset = ,                /* Reference date source dataset */
  refdatesourcevar  = ,                /* Reference date source variable */
  refdatevisitnum   = ,                /* Specific visit number at which reference date is to be taken. */
  dsettemplate      = ,                /* Planned A&R dataset template name */
  dsplan            = &g_dsplanfile,   /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
  decoderename      = ,                /* List of renames for decoded variables */
  decodepairs       = ,                /* Code and decode variables in pair */
  formatnamesdset   = ,                /* Format names dataset name */
  sortorder         = ,                /* Planned A&R dataset sort order */
  ptrtcdinf         = ,                /* Informat to derive PTRTCD from PTRTGRP */
  trtcdinf          =                  /* Informat to derive TRTCD from TRTGRP */
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
  %let dsetin_race     = %nrbquote(&dsetin_race.);               
  %let dsetout         = %nrbquote(&dsetout.);
  %let preprocess      = %nrbquote(&preprocess.);
  %let postprocess     = %nrbquote(&postprocess.);
  %let trt_dev_exists  = %nrbquote(%upcase(&trt_dev_exists));
  %let treatvarsyn     = %nrbquote(%upcase(&treatvarsyn));
  %let attributesyn    = %nrbquote(%upcase(&attributesyn));
  %let misschkyn       = %nrbquote(%upcase(&misschkyn));

  /* Check for valid parameter values
  /  set up a macro variable to hold the pv_abort flag
  /----------------------------------------------------------------------------*/
  %local pv_abort prefix preprocessdset postprocessdset loopi listvars thisvar;
  %let pv_abort = 0 ;
  %let prefix = _tc_p1_race;   /* Root name for temporary work datasets */

  /*
  / If the input dataset name is the same as the output dataset name,
  / write an error to the log.
  /----------------------------------------------------------------------------*/
  %if %qscan(&dsetin_race, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
    %do;
      %put %str(RTE)RROR: &sysmacroname: The input dataset name DSETIN(=&dsetin_race) is the same as output data set name DSETOUT(=&dsetout).;
      %let pv_abort=1;
    %end; 

  /*
  / Check for required parameters.
  /----------------------------------------------------------------------------*/
  
  %let listvars=DSETIN_RACE DSETOUT;

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

  * Macro Parameter DSETIN_RACE;
  %if not %sysfunc(exist(&dsetin_race)) %then 
  %do;
    %put RTE%str(RROR): &sysmacroname.: DSETIN_RACE(=&dsetin_race) does not exist; 
    %let pv_abort = 1;
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
  %let preprocessdset = &dsetin_race ;

  %if %nrbquote(&preprocess) ne %then %do;
     data &prefix._preprocess;
        set &dsetin_race;
        %unquote(&preprocess);;
     run;
     %let preprocessdset = &prefix._preprocess;
  %end;

  /*
  / Call DAMA macro tc_race
  /----------------------------------------------------------------------------*/
  %tc_race (
    dsetin            = &preprocessdset,     /* Input dataset name */
    dsetout           = &prefix._race1,      /* Output dataset name */
    demodset          = &demodset,           /* Name of DEMO dataset to use */        
    enroldset         = &enroldset,          /* Name of ENROL dataset to use */       
    exposuredset      = &exposuredset,       /* Name of EXPOSURE dataset to use */    
    investigdset      = &investigdset,       /* Name of INVESTIG dataset to use */        
    randdset          = &randdset,           /* Name of RAND dataset to use */        
    randalldset       = &randalldset,        /* Name of RANDALL dataset to use */     
    visitdset         = &visitdset,          /* Name of VISIT dataset to use */ 
    attributesyn      = N,                   /* Reconcile A&R dataset with planned A&R dataset */
    commonvarsyn      = &commonvarsyn,       /* Add common variables */
    datetimeyn        = &datetimeyn,         /* Derive datetime variables */
    decodeyn          = &decodeyn,           /* Decode coded variables */
    misschkyn         = N,                   /* Print warning message for variables in &DSETOUT with missing values on all records */ 
    treatvarsyn       = N,                   /* Add treatment variables */
    agedaysyn         = &agedaysyn,          /* Calculation of age in days */
    agemonthsyn       = &agemonthsyn,        /* Calculation of age in months */
    ageweeksyn        = &ageweeksyn,         /* Calculation of age in weeks */
    refdateoption     = &refdateoption,      /* Reference date source option */
    refdatedsetsubset = &refdatedsetsubset,  /* Where clause applied to source dataset */
    refdatesourcedset = &refdatesourcedset,  /* Reference date source dataset */
    refdatesourcevar  = &refdatesourcevar,   /* Reference date source variable */
    refdatevisitnum   = &refdatevisitnum,    /* Specific visit number at which reference date is to be taken. */
    dsettemplate      = &dsettemplate,       /* Planned A&R dataset template name */
    dsplan            = &dsplan,             /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
    decoderename      = &decoderename,       /* List of renames for decoded variables */
    decodepairs       = &decodepairs,        /* Code and decode variables in pair */
    formatnamesdset   = &formatnamesdset,    /* Format names dataset name */
    sortorder         = &sortorder,          /* Planned A&R dataset sort order */
    ptrtcdinf         = &ptrtcdinf,          /* Informat to derive PTRTCD from PTRTGRP */
    trtcdinf          = &trtcdinf            /* Informat to derive TRTCD from TRTGRP */
    ); 

   * Set a temporary macro variable containing dataset reference ;
   %let postprocessdset = &prefix._race1;

  /*
  / Treatment.assignment
  /----------------------------------------------------------------------------*/
  %if &treatvarsyn eq Y %then
  %do;

     /*
     / Add treatment variables to dataset
     /---------------------------------------------------------------------------*/
     %tu_rantrt ( dsetin      = &prefix._race1  /* Input dataset name */
                 ,dsetout     = &prefix._race2  /* Output dataset name */
                 ,ptrtcdinf   = &ptrtcdinf      /* Informat to derive PTRTCD from PTRTGRP */
                 ,randalldset = &randalldset    /* RANDALL data set name */
                 ,randdset    = &randdset       /* RAND data set name */
                 ,trtcdinf    = &trtcdinf       /* Informat to derive TRTCD from TRTGRP */
                 );

     /*
     / Call tu_p1_acttrt to cater for any treatment deviations
     /---------------------------------------------------------------------------*/
     %tu_p1_acttrt_pg (dsetin         = &prefix._race2,   /* Name of input dataset */ 
                       dsetout        = &prefix._race3,   /* Name of output dataset */
                       trt_dev_exists = &trt_dev_exists,  /* Do treatment deviations exist for your study? */
                       exposuredset   = &exposuredset     /* Name of EXPOSURE dataset to use */
                       );
 
     * Set a temporary macro variable containing dataset reference ;
     %let postprocessdset = &prefix._race3;

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

%mend tc_p1_race;
