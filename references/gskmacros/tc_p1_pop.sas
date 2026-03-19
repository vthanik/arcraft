/****************************************************************************************************
|
| Macro Name:      tc_p1_pop
|
| SAS Version:     9.1
|
| Created By:      Suzanne Johnes
|
| Date:            28 May 2008
|
| Macro Purpose:   Create POP A&R data set for Phase1 requirements
|                  (PG & XO studies)
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| ------------------------------------------------------------------
| ------------------------------------------------------------------
|                 FOR INPUT PARAMETERS, REFER TO
|                 DOCUMENTATION FOR TC_P1_POP
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
|(@) tc_pop
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
| Reason For Modification:  Changes 1 & 2 are based on the updated TC_POP macro and require P1 macro 
|                           to surface these parameters.
|                           1. Added data set parameters, which will be passed to the new version of 
|                              TU macros: demodset, enroldset, exposuredset, investigdset, racedset, 
|                              randalldset, randdset, visitdset
|                           2. Added parameter DECODEPAIRS, which will be passed to %tu_decode
|                           3. Removed P1 macro parameters dsetin_enrol, dsetin_investig and
|                              dsetin_exposure. These have now been replaced by TC_POP parameters
|                              enroldset, investigdset and exposuredset respectively. 
|                           4. Removed 'NQ' and 'ND' and added 'IS' to list of values for PCORRES used 
|                              for subsetting the input PKCNC dataset(s) when deriving the PK 
|                              Concentration population.
|                           5. Changed &treatvarsyn in TC_ call to 'N' as this parameter shall be 
|                              referenced further on during the call to tu_rantrt
|                           6. Validation check included to prevent output dataset having the same 
|                              name as the input dataset 
|                           7. EXPOSUREDSET to be passed as a macro parameter to tu_p1_acttrt_pg
|                           8. Included validation check for treatvarsyn, attributesyn, misschkyn and 
|                              trt_dev_exists 
|
| Modified By:           
| Date of Modification:   
| New version/draft number:
| Modification ID:          
| Reason For Modification:
|
****************************************************************************************************/

%macro tc_p1_pop (
  dsetin_pkcnc      = ,                /* PK Concentration dataset(s) to derive PK Concentration population */ 
  dsetin_pkpar      = ,                /* PK Parameter dataset(s) to derive PK Parameter population */
  dsetout           = ardata.pop,      /* Output dataset name */
  postprocess       = ,                /* Any processing required before writing out to final output dataset */
  trt_dev_exists    = N,               /* Do Treatment Deviations exists for your study? */
  enroldset         = dmdata.enrol,    /* Name of ENROL dataset to use */
  investigdset      = dmdata.investig, /* Name of INVESTIG dataset to use */
  demodset          = dmdata.demo,     /* Name of DEMO dataset to use */        
  exposuredset      = dmdata.exposure, /* Name of EXPOSURE dataset to use */    
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
  %let enroldset       = %nrbquote(&enroldset.); 
  %let dsetout         = %nrbquote(&dsetout.);
  %let postprocess     = %nrbquote(&postprocess.);
  %let trt_dev_exists  = %nrbquote(%upcase(&trt_dev_exists));
  %let treatvarsyn     = %nrbquote(%upcase(&treatvarsyn));
  %let attributesyn    = %nrbquote(%upcase(&attributesyn));
  %let misschkyn       = %nrbquote(%upcase(&misschkyn));

  /* Check for valid parameter values
  /  set up a macro variable to hold the pv_abort flag
  /----------------------------------------------------------------------------*/
  %local pv_abort prefix loopi listvars thisvar enrol_dset num_pkcnc num_pkpar postprocessdset; 
  %let pv_abort = 0 ;
  %let prefix = _tc_p1_pop;   /* Root name for temporary work datasets */

  /*
  / Check for required parameters.
  /----------------------------------------------------------------------------*/
  
  %let listvars=ENROLDSET DSETOUT;

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
  * Macro Parameter ENROLDSET;
  %if not %sysfunc(exist(&enroldset)) %then 
  %do;
    %put RTE%str(RROR): &sysmacroname.: The ENROLDSET(=&enroldset) dataset does not exist; 
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

  /* Sort ENROL input dataset by Subject ID */
  proc sort data=&enroldset out=&prefix._enrol;
    by &g_subjid;
  run;

  data &prefix._1;
    set &prefix._enrol;

    /* All Subjects population */ 
    PNALLCD=1;
    PNALL='Y';
  run;

  %let enrol_dset = &prefix._1;

  /* If required, derive Safety population -  all subjects that received a dose */ 
  %if %nrbquote(&exposuredset) ne %then %do;

    proc sort data=&exposuredset out=&prefix._exp(keep=&g_subjid) nodupkey; 
      by &g_subjid;
      where exstdt ^=.;
    run;

    data &prefix._2;
      merge &enrol_dset &prefix._exp(in=a);
      by &g_subjid;
        if a then do;
          PNSAFECD=1;
          PNSAFE='Y';
        end;
        else do;
          PNSAFECD=0;
          PNSAFE='N';
        end;
    run;
    %let enrol_dset = &prefix._2;
  %end;

  /* If required, derive PK concentration population - all subjects that have a quantifiable concentration*/
  %if %nrbquote(&dsetin_pkcnc) ne %then %do;

    /* Determine the number of datasets listed in &dsetin_pkcnc */
    %let num_pkcnc=0;
    %do %while (%qscan(%nrbquote(&dsetin_pkcnc), &num_pkcnc + 1, %str( )) ne );
      %let num_pkcnc = %eval(&num_pkcnc + 1);
    %end;

    %do i=1 %to &num_pkcnc;
      proc sort data=%qscan(&dsetin_pkcnc,&i,%str( )) out=&prefix._pkcnc_&i (keep=&g_subjid) nodupkey; 
        by &g_subjid;
        where pcorres ^in ('NS' 'NA' 'IS');
      run;
    %end;

    data &prefix._pkcnc;
      merge 
        %do i=1 %to &num_pkcnc;
          &prefix._pkcnc_&i
        %end;
      ;
      by &g_subjid;
    run;

    data &prefix._3;
      merge &enrol_dset &prefix._pkcnc(in=a);
      by &g_subjid;
        if a then do;
          PNPKCCD=1;
          PNPKC='Y';
        end;
        else do;
          PNPKCCD=0;
          PNPKC='N';
        end;
    run;
    %let enrol_dset = &prefix._3;
  %end;

  /* If required, define PK parameter population - all subjects that have a parameter value */
  %if %nrbquote(&dsetin_pkpar) ne %then %do;

    /* Determine the number of datasets listed in &dsetin_pkpar */
    %let num_pkpar=0;
    %do %while (%qscan(%nrbquote(&dsetin_pkpar), &num_pkpar + 1, %str( )) ne );
      %let num_pkpar = %eval(&num_pkpar + 1);
    %end;

    %do j=1 %to &num_pkpar;
      proc sort data=%qscan(&dsetin_pkpar,&j,%str( )) out=&prefix._pkpar_&j (keep=&g_subjid) nodupkey; 
        by &g_subjid;
        where pporresn ^=.;
      run;
    %end;

    data &prefix._pkpar;
      merge 
        %do j=1 %to &num_pkpar;
          &prefix._pkpar_&j
        %end;
      ;
      by &g_subjid;
    run;

    data &prefix._4;
      merge &enrol_dset &prefix._pkpar(in=a);
      by &g_subjid;
        if a then do;
          PNPKPCD=1;
          PNPKP='Y';
        end;
        else do;
          PNPKPCD=0;
          PNPKP='N';
        end;
    run;
    %let enrol_dset = &prefix._4;
  %end;

  /*
  / Call DAMA macro tc_pop
  /----------------------------------------------------------------------------*/
  %tc_pop (
     enroldset         = &enrol_dset,        /* Name of ENROL dataset to use */
     investigdset      = &investigdset,      /* Name of INVESTIG dataset to use */ 
     demodset          = &demodset,          /* Name of DEMO dataset to use */        
     exposuredset      = &exposuredset,      /* Name of EXPOSURE dataset to use */    
     racedset          = &racedset,          /* Name of RACE dataset to use */        
     randalldset       = &randalldset,       /* Name of RANDALL dataset to use */     
     randdset          = &randdset,          /* Name of RAND dataset to use */        
     visitdset         = &visitdset,         /* Name of VISIT dataset to use */ 
     dsetout           = &prefix._pop1,      /* Output dataset name */
     commonvarsyn      = &commonvarsyn,      /* Add common variables */
     treatvarsyn       = N,                  /* Add treatment variables */
     datetimeyn        = &datetimeyn,        /* Derive datetime variables */
     decodeyn          = &decodeyn           /* Decode coded variables */
     derivationyn      = &derivationyn,      /* Dataset specific derivations */
     attributesyn      = N,                  /* Reconcile A&R dataset with planned A&R dataset */
     misschkyn         = N,                  /* Print warning message for variables in &DSETOUT with missing values on all records */
     agemonthsyn       = &agemonthsyn,       /* Calculation of age in months */
     ageweeksyn        = &ageweeksyn,        /* Calculation of age in weeks */
     agedaysyn         = &agedaysyn,         /* Calculation of age in days */
     refdateoption     = &refdateoption,     /* Reference date source option */
     refdatevisitnum   = &refdatevisitnum,   /* Reference date visit number */
     refdatesourcedset = &refdatesourcedset, /* Reference date source dataset */
     refdatesourcevar  = &refdatesourcevar,  /* Reference date source variable */
     refdatedsetsubset = &refdatedsetsubset, /* Where clause applied to source dataset */
     trtcdinf          = &trtcdinf,          /* Informat to derive TRTCD from TRTGRP */
     ptrtcdinf         = &ptrtcdinf,         /* Informat to derive PTRTCD from PTRTGRP */
     dsplan            = &dsplan,            /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
     dsettemplate      = &dsettemplate ,     /* Planned A&R dataset template name */
     sortorder         = &sortorder,         /* Planned A&R dataset sort order */
     decodepairs       = &decodepairs,       /* Code and decode variables in pair */
     formatnamesdset   = &formatnamesdset,   /* Format names dataset name */
     noderivevars      = &noderivevars       /* List of variables not to derive */
     );

   * Set a temporary macro variable containing dataset reference ;
   %let postprocessdset = &prefix._pop1;

  /*
  / Treatment.assignment
  /----------------------------------------------------------------------------*/
  %if &treatvarsyn eq Y %then
  %do;

     /*
     / Add treatment variables to dataset
     /---------------------------------------------------------------------------*/
     %tu_rantrt ( dsetin      = &prefix._pop1   /* Input dataset name */
                 ,dsetout     = &prefix._pop2   /* Output dataset name */
                 ,ptrtcdinf   = &ptrtcdinf      /* Informat to derive PTRTCD from PTRTGRP */
                 ,randalldset = &randalldset    /* RANDALL data set name */
                 ,randdset    = &randdset       /* RAND data set name */
                 ,trtcdinf    = &trtcdinf       /* Informat to derive TRTCD from TRTGRP */
                 );

     /*
     / Call tu_p1_acttrt to cater for any treatment deviations
     /---------------------------------------------------------------------------*/
     %tu_p1_acttrt_pg (dsetin         = &prefix._pop2,   /* Name of input dataset */ 
                       dsetout        = &prefix._pop3,   /* Name of output dataset */
                       trt_dev_exists = &trt_dev_exists, /* Do treatment deviations exist for your study? */
                       exposuredset   = &exposuredset    /* Name of EXPOSURE dataset to use */
                       );
 
     * Set a temporary macro variable containing dataset reference ;
     %let postprocessdset = &prefix._pop3;

   %end; /*EndOf if treatvarsyn = Y */
 
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

%mend tc_p1_pop;
