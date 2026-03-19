/*******************************************************************************
|
| Macro Name:      tc_p1_demo
|
| SAS Version:     9.1
|
| Created By:      Khilit Shah
|
| Date:            13 March 2008
|
| Macro Purpose:   Create AR DEMO data set to Phase1 requirements
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                            REQ/OPT  DEFAULT
| -----------------  -------------------------------------  -------  ----------
|
| The macro references the following datasets :-
| ------------------  -------  ------------------------------------------------
| Name                Req/Opt  Description
| ------------------  -------  ------------------------------------------------
| Output:
|
| The macro outputs the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETOUT           Req      Parameter specified dataset
| -----------------  -------  -------------------------------------------------
|
| Global macro variables created: NONE
|
| Macros called:
| (@) tc_demo
| (@) tu_abort
| (@) tu_attrib
| (@) tu_chkvarsexist
| (@) tu_p1_acttrt_pg
| (@) tu_misschk
| (@) tu_nobs
| (@) tu_putglobals
| (@) tr_putlocals
| (@) tu_rantrt
| (@) tu_tidyup
| (@) tu_valparms
|
|
*******************************************************************************
| Change Log
|
| Modified By:              Khilit Shah (kys41925)
| Date of Modification:     14-Oct-2008
| New version/draft number: 2
| Modification ID:          n/a
| Reason For Modification:  Changes 1-3 are based on the updated to TC_DEMO macro
|                             and require P1 macro to surface these parameters
|                           1. Added data set parameters, which will be passed 
|                              to new version of TU macros: enroldset,
|                              exposuredset, investigdset, racedset, randalldset, 
|                              randdset, tmslicedset, visitdset       
|                           2. Added 5 new DYREF* parameters, which will be passed 
|                              %tu_derive REF* parameters: dyrefdateoption, 
|                              dyrefdatedsetsubset, dyrefdatesourcedset
|                              dyrefdatesourcevar, dyrefdatevisitnum  
|                           3. Added parameter DECODEPAIRS, which will be 
|                              passed to %tu_decode
|                           4  Change &treatvarsyn in TC_ call to 'N'. This 
|                              parameter shall be referenced during the call 
|                              to tu_rantrt within the macro.
|                           5  Validation check included to prevent 
|                              output LIBNAME.dataset not being the same as
|                              input LIBNAME.dataset name.
|                           6 Included EXPOSUREDSET to be passed 
|                               on as macro parameters to TU_P1_ACTTRT
|
|*******************************************************************************
| Modified By:              
| Date of Modification:     
| New version/draft number: 
| Modification ID:          
| Reason For Modification:  
|
*******************************************************************************/

%macro tc_p1_demo(
     trt_dev_exists    = N ,            /* Do Treatment Deviations exists for your study? */
     dsetin_demo       = DMDATA.DEMO,   /* Input  dataset name */
     dsetout           = ARDATA.DEMO,   /* Output dataset name */
     preprocess        = ,              /* Any processing required after reading in the input dataset */
     postprocess       = ,              /* Any processing required before writing out to final output dataset */
     dsetin_vitals     = DMDATA.VITALS, /* Input VITALS dataset name */
     vitals_subset     = where height ne . and weight ne . , /* Subset VITALs dataset for selective observations that contain Height and weight info */
     enroldset         = dmdata.enrol,    /* Name of ENROL dataset to use */       
     exposuredset      = dmdata.exposure, /* Name of EXPOSURE dataset to use */    
     investigdset      = dmdata.investig, /* Name of RACE dataset to use */        
     racedset          = dmdata.race,     /* Name of RACE dataset to use */        
     randalldset       = dmdata.randall,  /* Name of RANDALL dataset to use */     
     randdset          = dmdata.rand,     /* Name of RAND dataset to use */        
     tmslicedset       = dmdata.tmslice,  /* Name of TMSLICE dataset to use */      
     visitdset         = dmdata.visit,    /* Name of VISIT dataset to use */   
     commonvarsyn      = Y,       /* Add common variables */
     treatvarsyn       = Y,       /* Add treatment variables */
     datetimeyn        = Y,       /* Derive datetime variables */
     decodeyn          = Y,       /* Decode coded variables */
     derivationyn      = Y,       /* Dataset specific derivations */
     attributesyn      = Y,       /* Reconcile A&R dataset with planned A&R dataset */
     misschkyn         = Y,       /* Print warning message for variables in &DSETOUT with missing values on all records */
     agemonthsyn       = N,       /* Calculation of age in months */
     ageweeksyn        = N,       /* Calculation of age in weeks */
     agedaysyn         = N,       /* Calculation of age in days */
     refdateoption     = TREAT,   /* Reference date source option */
     refdatevisitnum   = ,        /* Specific visit number at which reference date is to be taken. */
     refdatesourcedset = ,        /* Reference date source dataset */
     refdatesourcevar  = ,        /* Reference date source variable */
     refdatedsetsubset = ,        /* Where clause applied to source dataset */
     dyrefdateoption    = ,       /* Reference date source option for the calculation of Study Day values in tu_derive Reference date source option for tu_derive.*/                                  
     dyrefdatedsetsubset= ,       /* WHERE clause applied to source dataset for tu_derive. */            
     dyrefdatesourcedset= ,       /* Reference date source dataset for tu_derive. */                                            
     dyrefdatesourcevar = ,       /* Reference date source variable for tu_derive. */                                           
     dyrefdatevisitnum  = ,       /* Specific visit number at which reference date is to be taken for tu_derive. */         
     trtcdinf          = ,        /* Informat to derive TRTCD from TRTGRP */
     ptrtcdinf         = ,        /* Informat to derive PTRTCD from PTRTGRP */
     dsplan            = &g_dsplanfile, /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
     dsettemplate      = ,        /* Planned A&R dataset template name */
     sortorder         = ,        /* Planned A&R dataset sort order */
     decodepairs       = ,        /* code and decode variables in pair */
     formatnamesdset   = ,        /* Format names dataset name */
     noderivevars      =          /* List of variables not to derive */
    );


  /*
  / Echo parameter values and global macro variables to the log
  /----------------------------------------------------------------------------*/
  %local MacroVersion MacroName;
  %let MacroName=&sysmacroname.;
  %let MacroVersion=2;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals()

  /*
  / Parameter validation
  /----------------------------------------------------------------------------*/
  %let trt_dev_exists    = %nrbquote(%upcase(&trt_dev_exists));
  %let dsetin_demo       = %nrbquote(&dsetin_demo.);
  %let dsetout           = %nrbquote(&dsetout.);
  %let dsetin_vitals     = %nrbquote(&dsetin_vitals.);
  %let vitals_subset     = %nrbquote(&vitals_subset.);
  %let preprocess        = %nrbquote(&preprocess.);
  %let postprocess       = %nrbquote(&postprocess.);

  %let attributesyn      = %nrbquote(%upcase(&attributesyn));
  %let misschkyn         = %nrbquote(%upcase(&misschkyn));

  /*
  / Check for valid parameter values
  /   set up a macro variable to hold the pv_abort flag
  /----------------------------------------------------------------------------*/
  %local pv_abort abortyn loopi listvars thisvar demo_varlist vs_varlist;
  %let pv_abort = 0 ;

  /*
  / Check for required parameters.
  /----------------------------------------------------------------------------*/
  
  %let listvars=DSETIN_DEMO DSETOUT DSETIN_VITALS;

  %do loopi=1 %to 3;
    %let thisvar=%scan(&listvars, &loopi, %str( ));
    %let &thisvar=%nrbquote(&&&thisvar);
    
    %if &&&thisvar eq %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: The parameter &thisvar cannot be blank.;
       %let pv_abort=1;
    %end;    
  %end;  /* end of do-to loop */

  /*
  / If the input dataset name is the same as the output dataset name,
  / write an error to the log.
  /----------------------------------------------------------------------------*/
  %if %qscan(&dsetin_demo, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
  %do;
    %put %str(RTE)RROR: &sysmacroname: The input dataset name DSETIN(=&dsetin_demo) is the same as output data set name DSETOUT(=&dsetout).;
    %let pv_abort=1;
  %end;

  /*
  / Validation of dataset
  /----------------------------------------------------------------------------*/
  * DMDATA.DEMO exists? ;
  %if not %sysfunc(exist(&dsetin_demo)) %then 
  %do;
    %put RTE%str(RROR): &sysmacroname.: &dsetin_demo does not exist;
    %let pv_abort = 1;
  %end;

  * DMDATA.VITALS exists? ;
  %if not %sysfunc(exist(&dsetin_vitals)) %then 
  %do;
    %put RTE%str(RROR): &sysmacroname.: &dsetin_vitals does not exist;
    %let pv_abort = 1;
  %end;

  /*
  / Validation of variables within dataset
  /----------------------------------------------------------------------------*/
  * DMDATA.DEMO variable check ;
  %let demo_varlist=subjid;
  %tu_valparms(
    macroname=tc_p1_demo,
    chktype=varexists,
    pv_dsetin=dsetin_demo,
    pv_varsin=demo_varlist
   );

  * DMDATA.VITALS variable check ;
  %let vs_varlist=subjid ;
  %tu_valparms(
    macroname=tc_p1_demo,
    chktype=varexists,
    pv_dsetin=dsetin_vitals,
    pv_varsin=vs_varlist
   );


  /*
  / Complete parameter validation
  /----------------------------------------------------------------------------*/
  %if %eval(&g_abort. + &pv_abort.) gt 0 %then %do;
    %put %str(RTE)RROR: &macroname: Macro has failed parameter validation check for reasons stated with %str(RTE)RRORs above;
    %tu_abort(option=force);
  %end;

  /*
  / NORMAL PROCESSING
  /----------------------------------------------------------------------------*/

  %local prefix preprocessdset postprocessdset bylist ;
  %let prefix = _tc_p1_demo ;   /* Root name for temporary work datasets */

  /*
  / Pre-processing of input dataset
  /   This step allows for the user to pre-process the input dataset in way of
  /   using simple SAS code.
  /   e.g. in the driver call, the user could include information such as
  /   preprocess = if 1 LE SUBJID LE 5 then studypart='A' else studypart = 'B' ;
  /----------------------------------------------------------------------------*/
  %let preprocessdset = &dsetin_demo ;

  %if %nrbquote(&preprocess) ne %then %do;
     data &prefix._preprocess;
        set &dsetin_demo ;
        %unquote(&preprocess);;
     run;
     %let preprocessdset = &prefix._preprocess;
  %end;


  /*
  / Call DAMA macro tc_demo
  /----------------------------------------------------------------------------*/
  %tc_demo (  dsetin            = &preprocessdset     /* Input dataset name */
             ,dsetout           = &prefix._dm1        /* Output dataset name */
             ,enroldset         = &enroldset          /* Name of ENROL dataset to use */       
             ,exposuredset      = &exposuredset       /* Name of EXPOSURE dataset to use */    
             ,investigdset      = &investigdset       /* Name of RACE dataset to use */        
             ,racedset          = &racedset           /* Name of RACE dataset to use */        
             ,randalldset       = &randalldset        /* Name of RANDALL dataset to use */     
             ,randdset          = &randdset           /* Name of RAND dataset to use */        
             ,tmslicedset       = &tmslicedset        /* Name of TMSLICE dataset to use */      
             ,visitdset         = &visitdset          /* Name of VISIT dataset to use */   
             ,commonvarsyn      = &commonvarsyn       /* Add common variables */
             ,treatvarsyn       = N                   /* Add treatment variables */
             ,datetimeyn        = &datetimeyn         /* Derive datetime variables */
             ,decodeyn          = &decodeyn           /* Decode coded variables */
             ,derivationyn      = &derivationyn       /* Dataset specific derivations */
             ,attributesyn      = N       /* Reconcile A&R dataset with planned A&R dataset */
             ,misschkyn         = N       /* Print warning message for variables in &DSETOUT with missing values on all records */ 
             ,agemonthsyn       = &agemonthsyn        /* Calculation of age in months */
             ,ageweeksyn        = &ageweeksyn         /* Calculation of age in weeks */
             ,agedaysyn         = &agedaysyn          /* Calculation of age in days */
             ,refdateoption     = &refdateoption      /* Reference date source option */
             ,refdatevisitnum   = &refdatevisitnum    /* Specific visit number at which reference date is to be taken. */
             ,refdatesourcedset = &refdatesourcedset  /* Reference date source dataset */
             ,refdatesourcevar  = &refdatesourcevar   /* Reference date source variable */
             ,refdatedsetsubset = &refdatedsetsubset  /* Where clause applied to source dataset */     
             ,dyrefdateoption    = &dyrefdateoption       /* Reference date source option for the calculation of Study Day values in tu_derive Reference date source option for tu_derive.*/                                  
             ,dyrefdatedsetsubset= &dyrefdatedsetsubset   /* WHERE clause applied to source dataset for tu_derive. */            
             ,dyrefdatesourcedset= &dyrefdatesourcedset   /* Reference date source dataset for tu_derive. */                                            
             ,dyrefdatesourcevar = &dyrefdatesourcevar    /* Reference date source variable for tu_derive. */                                           
             ,dyrefdatevisitnum  = &dyrefdatevisitnum     /* Specific visit number at which reference date is to be taken for tu_derive. */         
             ,trtcdinf          = &trtcdinf           /* Informat to derive TRTCD from TRTGRP */
             ,ptrtcdinf         = &ptrtcdinf          /* Informat to derive PTRTCD from PTRTGRP */
             ,dsplan            = &g_dsplanfile       /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
             ,dsettemplate      = &dsettemplate       /* Planned A&R dataset template name */
             ,sortorder         = &sortorder          /* Planned A&R dataset sort order */
             ,decodepairs       = &decodepairs        /* code and decode variables in pair */
             ,formatnamesdset   = &formatnamesdset    /* Format names dataset name */
             ,noderivevars      = &noderivevars       /* List of variables not to derive */
            );


  * Set a temporary macro variable containing dataset reference ;
  %let postprocessdset = &prefix._dm1;

  /*
  / Treatment.assignment
  /----------------------------------------------------------------------------*/
  %if &treatvarsyn eq Y %then
  %do;

    /*
    / Add treatment variables to dataset
    /---------------------------------------------------------------------------*/
    %tu_rantrt ( dsetin      = &prefix._dm1     /* Input dataset name */
                ,dsetout     = &prefix._dm2     /* Output dataset name */
                ,ptrtcdinf   = &ptrtcdinf       /* Informat to derive PTRTCD from PTRTGRP */
                ,randalldset = &randalldset     /* RAND data set name */
                ,randdset    = &randdset        /* RANDALL data set name */
                ,trtcdinf    = &trtcdinf        /* Informat to derive TRTCD from TRTGRP */
               );

  
      /*
      / Call tu_p1_acttrt to cater for any treatment deviations
      /---------------------------------------------------------------------------*/
      %tu_p1_acttrt_pg ( dsetin         = &prefix._dm2      /* Name of input dataset */
                        ,dsetout        = &prefix._dm3      /* Name of output dataset */
                        ,trt_dev_exists = &trt_dev_exists   /* Do treatment deviations exist in your study? */
                        ,exposuredset   = &exposuredset     /* Name of EXPOSURE dataset to use */
                        );

      * Set a temporary macro variable containing dataset reference ;
      %let postprocessdset = &prefix._dm3;
  
  %end; /*EndOf if treatvarsyn = Y */

  /*
  / Merge on Weight, Height & BMI (as required for Phase1 IDSL displays)
  / An optional macro parameter is available such that the user can subset the
  /   dataset containing this information with any user supplied SAS code
  / e.g. in the driver call, the user could include information such as
  /     vitals_subset = where height ne . and weight ne . ;
  /----------------------------------------------------------------------------*/

  %LET vitalsSubsetdset = &dsetin_vitals ;

  %IF %tu_chkvarsexist(&vitalsSubsetdset,height) EQ or %tu_chkvarsexist(&vitalsSubsetdset,weight) EQ  %THEN 
  %DO;

    %IF %nrbquote(&vitals_subset) ne %THEN 
    %DO;
       DATA &prefix._vitalsSubset;
          SET &vitalsSubsetdset ; ;
          %UNQUOTE(&vitals_subset) ;;
       RUN;
       %LET vitalsSubsetdset = &prefix._vitalsSubset;
    %END;

    %let bylist = subjid ;
    %if %tu_chkvarsexist(&vitalsSubsetdset, height) eq  %then %let bylist = &bylist height;
    %if %tu_chkvarsexist(&vitalsSubsetdset, weight) eq  %then %let bylist = &bylist weight;
    %if %tu_chkvarsexist(&vitalsSubsetdset, vsbmi)  eq  %then %let bylist = &bylist vsbmi;

    PROC SORT DATA = &vitalsSubsetdset
               OUT = vitals_dm1 NODUPKEY ;;
      BY &BYLIST;
    RUN;

    DATA vitals_dm2 ;
      SET vitals_dm1 (KEEP = &bylist);
      BY &bylist;

      %IF %tu_chkvarsexist(vitals_dm1,vsbmi) NE %THEN 
      %DO;
        %IF %tu_chkvarsexist(vitals_dm1,height weight) = %THEN 
        %DO;
          vsbmi = (weight/(height/100)**2) ;
        %END ;
      %END ;

      IF FIRST.subjid + LAST.subjid < 2 THEN
        PUT "ER" "ROR: Duplicate height and/or weight records in vitals: " subjid= weight= height= vsbmi=;
    RUN;

    PROC SORT DATA = &postprocessdset
               OUT = &prefix._dm4;
      BY subjid ;
    RUN;

    DATA &prefix._dm5 ;
      MERGE &prefix._dm4 (IN=a) vitals_dm2;
      BY subjid;
      IF a;
    RUN;

    * Set a temporary macro variable containing dataset reference ;
    %let postprocessdset = &prefix._dm5;

  %END ; /*EndOf if Height and Weight exist in VITALs dataset */
  %ELSE %DO ;
    %PUT %str(RTW)ARNING: &macroname: Variable WEIGHT and/or HEIGHT is not included in macro parameter dsetin_vitals (&dsetin_vitals);
  %END ;

  /*
  / Post-processing of input dataset
  /   This step allows for the user to post-process the dataset in way of
  /     using simple SAS code. This post-process step is invoked before
  /     calling of the tu_attrib and tu_misschk macros
  /   e.g. in the driver call, the user could include information such as
  /     postprocess = where studypart = 'B' ;
  /----------------------------------------------------------------------------*/
  %if %nrbquote(&postprocess) ne %then 
  %do;
     data &prefix._postprocess;
        set &postprocessdset ;
        %unquote(&postprocess);;
     run;
     %let postprocessdset=&prefix._postprocess;
  %end;

  /*
  / HALT creation of the A&R dataset if the dataset contains 0 (zero) observations
  /----------------------------------------------------------------------------*/
  %if %tu_nobs(&postprocessdset.) le 0 %then
  %do ;
    %put %str(RTE)RROR: &sysmacroname: Dataset &postprocessdset does not exist or contains zero observations ;
    %tu_abort (option=force) ;
  %end ;

  /*
  / Reconcile A&R dataset with planned A&R dataset.
  /----------------------------------------------------------------------------*/
  %if &attributesyn eq Y %then
  %do;
    %tu_attrib( dsetin        =&postprocessdset
               ,dsetout       =&dsetout
               ,dsplan        =&g_dsplanfile
               ,dsettemplate  =&dsettemplate
               ,sortorder     =&sortorder
               );
  %end;
  %else
  %do;
    data &dsetout;
         set &postprocessdset;
    run;
 %end;

  /*
  / Call tu_misschk macro in order to identify any variables in the output
  / dataset which have missing values on all records.
  /----------------------------------------------------------------------------*/
  %if &misschkyn eq Y %then
  %do;
    %tu_misschk(dsetin = &dsetout);
  %end;

  /*
  / Delete temporary datasets used in this macro.
  /----------------------------------------------------------------------------*/
  %tu_tidyup(rmdset=&prefix:, glbmac=NONE);


%mend tc_p1_demo;
