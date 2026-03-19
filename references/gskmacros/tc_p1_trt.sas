/****************************************************************************************************
|
| Macro Name:      tc_p1_trt
|
| SAS Version:     9.1
|
| Created By:      Suzanne Johnes
|
| Date:            26 March 2008
|
| Macro Purpose:   Create TRT A&R data set for Phase1 requirements
|                  (PG & XO studies)
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| ------------------------------------------------------------------
| ------------------------------------------------------------------
|                 FOR INPUT PARAMETERS, REFER TO
|                  DOCUMENTATION FOR TC_P1_TRT
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
|(@) tu_chkvarsexist
|(@) tc_trt
|(@) tu_p1_acttrt_pg
|(@) tu_p1_acttrt_xo
|(@) tu_rantrt
|(@) tu_attrib
|(@) tu_misschk
|(@) tu_tidyup
|
|****************************************************************************************************
| Change Log
|
| Modified By:              
| Date of Modification:     
| New version/draft number: 
| Modification ID:          
| Reason For Modification:  
*****************************************************************************************************/

%macro tc_p1_trt ( 
    trt_dev_exists    = N,               /* Do Treatment Deviations exists for your study? */
    postprocess       = ,                /* Any processing required before writing out to final output dataset */
    dsetout           = ardata.trt,      /* Output dataset name */
    demodset          = dmdata.demo,     /* Name of DEMO dataset to use */ 
    enroldset         = dmdata.enrol,    /* Name of ENROL dataset to use */       
    exposuredset      = dmdata.exposure, /* Name of EXPOSURE dataset to use */    
    investigdset      = dmdata.investig, /* Name of INVESTIG dataset to use */        
    racedset          = dmdata.race,     /* Name of RACE dataset to use */        
    randalldset       = dmdata.randall,  /* Name of RANDALL dataset to use */     
    randdset          = dmdata.rand,     /* Name of RAND dataset to use */        
    tmslicedset       = dmdata.tmslice,  /* Name of TMSLICE dataset to use */      
    visitdset         = dmdata.visit,    /* Name of VISIT dataset to use */ 
    commonvarsyn      = Y,               /* Add common variables */
    treatvarsyn       = Y,               /* Add treatment variables */
    datetimeyn        = Y,               /* Derive datetime variables */
    decodeyn          = Y,               /* Decode coded variables */
    derivationyn      = Y,               /* Dataset specific derivations */
    attributesyn      = Y,               /* Reconcile A&R dataset with planned A&R dataset */
    misschkyn         = Y,               /* Print warning message for variables in &DSETOUT with missing values on all records */
    exrecalcvisityn   = N,               /* Recalculate visit based on &REFDAT and &REFTIM for &EXPOSURE data set of crossover study */
    agemonthsyn       = N,               /* Calculation of age in months */
    ageweeksyn        = N,               /* Calculation of age in weeks */
    agedaysyn         = N,               /* Calculation of age in days */
    exrefdat          = exstdt,          /* Reference date variable name for recalculating visit for &EXPOSURE data set of crossover study */
    exreftim          = exsttm,          /* Reference time variable name for recalculating visit for &EXPOSURE data set of crossover study */
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
    decodepairs       = ,                /* Specifies the code and decode variables in pair */
    formatnamesdset   = ,                /* Format names dataset name */
    noderivevars      =                  /* List of variables not to derive */
    );

   /*
   / Echo parameter values and global macro variables to the log
   /----------------------------------------------------------------------------*/
   %local MacroVersion macroname;
   %let MacroName=&sysmacroname.;
   %let MacroVersion=1;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals();

   /*
   / Parameter validation
   /----------------------------------------------------------------------------*/    
   %let exposuredset   = %nrbquote(&exposuredset.);         
   %let randalldset    = %nrbquote(&randalldset.);   
   %let randdset       = %nrbquote(&randdset.);    
   %let tmslicedset    = %nrbquote(&tmslicedset.);  
   %let visitdset      = %nrbquote(&visitdset.);
   %let dsetout        = %nrbquote(&dsetout.);
   %let postprocess    = %nrbquote(&postprocess.);
   %let trt_dev_exists = %nrbquote(%upcase(&trt_dev_exists));
   %let treatvaryn     = %nrbquote(%upcase(&treatvarsyn));
   %let attributesyn   = %nrbquote(%upcase(&attributesyn));
   %let misschkyn      = %nrbquote(%upcase(&misschkyn));

   /* Check for valid parameter values
   /  set up a macro variable to hold the pv_abort flag
   /----------------------------------------------------------------------------*/
   %local pv_abort prefix loopi thisvar listvars loopj thisdset listdset 
          postprocessdset trtdset trtdset2;
   %let pv_abort = 0 ;
   %let prefix = _tc_p1_trt ;   /* Root name for temporary work datasets */

  /*
  / Check for required parameters.
  /----------------------------------------------------------------------------*/
  %let listvars=EXPOSUREDSET RANDDSET RANDALLDSET TMSLICEDSET DSETOUT;

  %do loopi=1 %to 5;
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
  %let listdset=EXPOSUREDSET RANDDSET RANDALLDSET TMSLICEDSET;

  %do loopj=1 %to 4;
    %let thisdset=%scan(&listdset, &loopj, %str( ));
    %let &thisdset=%nrbquote(&&&thisdset);
    
    %if not %sysfunc(exist(&&&thisdset)) %then
    %do;
       %put %str(RTE)RROR: &sysmacroname.: The &thisdset(=&&&thisdset) dataset does not exist; 
       %let pv_abort=1;
    %end;    
  %end;  /* end of do-to loop */

  /* Macro Parameter VISITDSET */
  %if &g_stype=XO %then %do;
    %if not %sysfunc(exist(&visitdset)) %then 
      %do;
        %put RTE%str(RROR): &sysmacroname.: The VISITDSET(=&visitdset) dataset does not exist;
        %let pv_abort = 1;
      %end;
    %if %length(&visitdset) = 0 %then %do;
        %put %str(RTE)RROR: &macroname: Macro parameter (visitdset) cannot be blank;
        %let pv_abort = 1;
      %end; 
  %end;

  * Check for existence of multiple subject IDs on RANDDSET;
  %if %sysfunc(exist(&randdset)) ne 0 %then %do;
    proc sort data=&randdset out=&prefix._rand1;
      by subjid;
    run;
  
    data _NULL_ ;
      set &prefix._rand1;
      by subjid;
        if first.subjid + last.subjid < 2 then do;
          put "RTE" "RROR: &macroname: Duplicate Subject ID records in %UPCASE(&randdset): " subjid= ; 
          call symput('pv_abort', 1) ;
        end;
    run;
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
  / Create "dummy" TMSLICE dataset - 
  / Only keep those period numbers on TMSLICE dataset that exist on RANDALL dataset
  /--------------------------------------------------------------------------------*/
  %if %tu_chkvarsexist(&tmslicedset, pernum) eq %then %do;
    proc sql; 
      create table &prefix._tmslice as
      select distinct a.* from &tmslicedset a, &randalldset b
      where a.pernum=b.pernum;
    quit;
  %end;
  %else %do;
    data &prefix._tmslice;
      set &tmslicedset;
    run;
  %end;

  /*
  / Create "dummy" EXPOSURE dataset - 
  / Only keep one record per Subject/Time point, including Screening and Follow-Up
  /-------------------------------------------------------------------------------*/ 
  proc sql;
    create table &prefix._exposure as
    select distinct a.studyid, a.subjid, b.visitnum, b.visit, 
    %if %tu_chkvarsexist(&prefix._tmslice, ptmnum) eq  %then b.ptmnum, b.ptm, ; 
    c.exstdt 
    from (&randdset a, &prefix._tmslice b) left join &exposuredset c
    %if %tu_chkvarsexist(&prefix._tmslice, ptmnum) eq  %then %do;
      on a.subjid=c.subjid and b.visitnum=c.visitnum and b.ptmnum=c.ptmnum;
    %end;
    %else %do;
      on a.subjid=c.subjid and b.visitnum=c.visitnum;
    %end;
  quit;

  /*
  / Call DAMA macro tc_trt
  /----------------------------------------------------------------------------*/
  %tc_trt (
     dsetout           = &prefix._trt1,      /* Output dataset name */     
     demodset          = &demodset,          /* Name of DEMO dataset to use */        
     enroldset         = &enroldset,         /* Name of ENROL dataset to use */       
     exposuredset      = &prefix._exposure,  /* Name of EXPOSURE dataset to use */    
     investigdset      = &investigdset,      /* Name of INVESTIG dataset to use */        
     racedset          = &racedset,          /* Name of RACE dataset to use */        
     randalldset       = &randalldset,       /* Name of RANDALL dataset to use */     
     randdset          = &randdset,          /* Name of RAND dataset to use */        
     timeslicdset      = &prefix._tmslice,   /* Name of TMSLICE dataset to use */      
     visitdset         = &visitdset,         /* Name of VISIT dataset to use */          
     commonvarsyn      = &commonvarsyn,      /* Add common variables */
     treatvarsyn       = N,                  /* Add treatment variables */
     datetimeyn        = &datetimeyn,        /* Derive datetime variables */
     decodeyn          = &decodeyn,          /* Decode coded variables */
     derivationyn      = &derivationyn,      /* Dataset specific derivations */
     attributesyn      = N,                  /* Reconcile A&R dataset with planned A&R dataset */
     misschkyn         = N,                  /* Print warning message for variables in &DSETOUT with missing values on all records */ 
     exrecalcvisityn   = &exrecalcvisityn,   /* Recalculate visit based on &REFDAT and &REFTIM for &EXPOSURE data set of crossover study */
     agemonthsyn       = &agemonthsyn,       /* Calculation of age in months */
     ageweeksyn        = &ageweeksyn,        /* Calculation of age in weeks */
     agedaysyn         = &agedaysyn,         /* Calculation of age in days */
     exrefdat          = &exrefdat,          /* Reference date variable name for recalculating visit for &EXPOSURE data set of crossover study */
     exreftim          = &exreftim,          /* Reference time variable name for recalculating visit for &EXPOSURE data set of crossover study */
     refdateoption     = &refdateoption,     /* Reference date source option */
     refdatevisitnum   = &refdatevisitnum,   /* Specific visit number at which reference date is to be taken. */
     refdatesourcedset = &refdatesourcedset, /* Reference date source dataset */
     refdatesourcevar  = &refdatesourcevar,  /* Reference date source variable */
     refdatedsetsubset = &refdatedsetsubset, /* Where clause applied to source dataset */
     trtcdinf          = &trtcdinf,          /* Informat to derive TRTCD from TRTGRP */
     ptrtcdinf         = &ptrtcdinf,         /* Informat to derive PTRTCD from PTRTGRP */
     dsplan            = &dsplan,            /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
     dsettemplate      = &dsettemplate,      /* Planned A&R dataset template name */
     sortorder         = &sortorder,         /* Planned A&R dataset sort order */
     decodepairs       = &decodepairs,       /* Specifies code and decode variables in pair */
     formatnamesdset   = &formatnamesdset,   /* Format names dataset name */
     noderivevars      = &noderivevars       /* List of variables not to derive */
     );

  * Set a temporary macro variable containing dataset reference ;
  %let postprocessdset = &prefix._trt1;

  /*
  / Treatment assignment
  /----------------------------------------------------------------------------*/
  %if &treatvarsyn eq Y %then %do;

    /*
    / Add treatment variables to dataset
    /---------------------------------------------------------------------------*/
    %tu_rantrt ( dsetin      = &postprocessdset /* Input dataset name */
                ,dsetout     = &prefix._trt2    /* Output dataset name */
                ,ptrtcdinf   = &ptrtcdinf       /* Informat to derive PTRTCD from PTRTGRP */ 
                ,randalldset = &randalldset     /* RANDALL data set name */
                ,randdset    = &randdset        /* RAND data set name */
                ,trtcdinf    = &trtcdinf        /* Informat to derive TRTCD from TRTGRP */ 
                );

   /*
   / For XO studies - Reset Screening observations for TPTRTGRP and TPATRTGP variables
   / to match text assigned for Pre-treatment AE's and Conmeds, for example
   /--------------------------------------------------------------------------*/
   %let trtdset = &prefix._trt2;

   %if &g_stype=XO %then %do;
     data &prefix._trt3;
        set &prefix._trt2;
          if pernum=0 then do;
            tptrtgrp='Pre-Treatment';
            tpatrtgp='Pre-Treatment';
          end;
     run;
     %let trtdset = &prefix._trt3;
   %end;

   /*
   / Call tu_p1_acttrt to cater for any treatment deviations
   /-----------------------------------------------------------------*/
   %if &g_stype=PG %then %do;

     %tu_p1_acttrt_pg (dsetin         = &trtdset,         /* Name of input dataset */
                       dsetout        = &prefix._trt4,    /* Name of output dataset */
                       trt_dev_exists = &trt_dev_exists,  /* Do treatment deviations exist for your study? */
                       exposuredset   = &exposuredset     /* Name of EXPOSURE dataset to use */
                       );

   %end;
   %else %if &g_stype=XO %then %do;

     %tu_p1_acttrt_xo (dsetin         = &trtdset,        /* Name of input dataset */
                       dsetout        = &prefix._trt4,   /* Name of output dataset */
                       trt_dev_exists = &trt_dev_exists, /* Do treatment deviations exist for your study? */
                       exposuredset   = &exposuredset,   /* Name of EXPOSURE dataset to use */
                       tmslicedset    = &tmslicedset     /* Name of TMSLICE dataset to use */
                       );
   %end;

   * Set a temporary macro variable containing dataset reference ;
   %let postprocessdset = &prefix._trt4;

  %end;

  /*
  / Read in RAND dataset to populate RANDNUM. 
  /---------------------------------------------------------------------------*/
  proc sort data=&postprocessdset nodupkey;
    by subjid 
      %if %tu_chkvarsexist(&postprocessdset, pernum) eq  %then %do;
        pernum;
      %end;
  run; 

  data &prefix._rand2 (keep=subjid randnum);
    set &prefix._rand1;
      by subjid;
  run;
 
  data &prefix._trt5;
    merge &postprocessdset (in=a) &prefix._rand2;
      by subjid;
      if a;
  run;

  proc sort data=&prefix._trt5;
    by subjid 
      %if %tu_chkvarsexist(&prefix._trt5, pernum) eq  %then %do;
        pernum;
      %end;
  run;

  /*                                                                           
  / For XO studies - Drop "Follow-Up" records for any subject that dropped out 
  / before follow-up
  /----------------------------------------------------------------------------*/
  %let trtdset2 = &prefix._trt5;

  %if &g_stype=XO and %tu_chkvarsexist(&tmslicedset, pernum) eq  %then %do;

    proc sort data=&visitdset out=&prefix._visit1 (keep=subjid visitnum) nodupkey; 
      by visitnum subjid;
    run;

    proc sort data=&tmslicedset out=&prefix._tmslice1 (keep=visitnum pernum) nodupkey; 
      by visitnum pernum;
      where visitnum ne . and pernum ne .;
    run;

    data &prefix._visit2;
      merge &prefix._tmslice1 (in=a) &prefix._visit1 (in=b);
        by visitnum;
        if a and b;
    run;

    proc sort data=&prefix._visit2 out=&prefix._visit3 (drop=visitnum) nodupkey; 
      by subjid pernum;
    run;

    data &prefix._trt6;
      merge &prefix._trt5(in=a) &prefix._visit3(in=b where=(pernum=999));
      by subjid pernum;
      if not (pernum=999 and a and not b);
    run;

    %let trtdset2 = &prefix._trt6;

  %end;
 
  /*
  / Post-processing of input dataset
  /   This step allows for the user to post-process the dataset in way of
  /   using simple SAS code. This post-process step is invoked before
  /   calling of the tu_attrib and tu_misschk macros
  /   e.g. in the driver call, the user could include information such as
  /   postprocess = where studypart = 'B' ;
  /----------------------------------------------------------------------------*/
  %let postprocessdset = &trtdset2;

  %if %nrbquote(&postprocess) ne %then %do;
     data &prefix._postprocess;
        set &postprocessdset ;
        %unquote(&postprocess);
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

%mend tc_p1_trt;
