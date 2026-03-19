/****************************************************************************************************
|
| Macro Name:      tc_p1_ipdisc
|
| SAS Version:     9.1
|
| Created By:      Suzanne Johnes
|
| Date:            26 June 2008
|
| Macro Purpose:   Create IPDISC A&R data set for Phase1 requirements
|                  (PG & XO studies)
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| ------------------------------------------------------------------
| ------------------------------------------------------------------
|                 FOR INPUT PARAMETERS, REFER TO
|                 DOCUMENTATION FOR TC_P1_IPDISC
| ------------------------------------------------------------------
| ------------------------------------------------------------------
|
| Global macro variables created: NONE
|
| Macros called:
|(@) tu_putglobals
|(@) tr_putlocals
|(@) tu_valparms
|(@) tu_chkvarsexist
|(@) tu_abort
|(@) tc_ipdisc
|(@) tu_p1_acttrt_pg
|(@) tu_p1_acttrt_xo
|(@) tu_p1_periodday
|(@) tu_rantrt
|(@) tu_p1_calctpernum
|(@) tu_calctpernum
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

%macro tc_p1_ipdisc (
  dsetin_ipdisc       = dmdata.ipdisc,     /* Input dataset name */
  dsetout             = ardata.ipdisc,     /* Output dataset name */
  preprocess          = ,                  /* Any processing required after reading in the input dataset */
  postprocess         = ,                  /* Any processing required before writing out to final output dataset */
  addmultiobsyn       = N,                 /* Append additional rows to output dataset (1 row per subject and period until subject stopped taking study drug) */
  calctpernum_version = TU_P1_CALCTPERNUM, /* Either the TU_P1_CALCTPERNUM or TU_CALCTPERNUM macro is called to assign treatment */
  trt_dev_exists      = N,                 /* Do Treatment Deviations exists for your study? */
  demodset            = dmdata.demo,       /* Name of DEMO dataset to use */
  enroldset           = dmdata.enrol,      /* Name of ENROL dataset to use */
  exposuredset        = dmdata.exposure,   /* Name of EXPOSURE dataset to use */
  investigdset        = dmdata.investig,   /* Name of INVESTIG dataset to use */
  racedset            = dmdata.race,       /* Name of RACE dataset to use */
  randalldset         = dmdata.randall,    /* Name of RANDALL dataset to use */
  randdset            = dmdata.rand,       /* Name of RAND dataset to use */
  tmslicedset         = dmdata.tmslice,    /* Name of TMSLICE dataset to use */
  visitdset           = dmdata.visit,      /* Name of VISIT dataset to use */
  agedaysyn           = N,                 /* Calculation of age in days. */
  agemonthsyn         = N,                 /* Calculation of age in months. */
  ageweeksyn          = N,                 /* Calculation of age in weeks. */
  attributesyn        = Y,                 /* Reconcile A&R dataset with planned A&R dataset */
  commonvarsyn        = Y,                 /* Add common variables. */
  datetimeyn          = Y,                 /* Derive datetime variables */
  decodeyn            = Y,                 /* Decode coded variables */
  derivationyn        = Y,                 /* Dataset specific derivations */
  misschkyn           = Y,                 /* Print warning message for variables in &DSETOUT with missing values on all records */
  recalcvisityn       = N,                 /* Recalculate VISIT */
  timeslicingyn       = Y,                 /* Add timeslicing variables */
  treatvarsyn         = Y,                 /* Add treatment variables. */
  xovarsforpgyn       = N,                 /* If Y derive crossover study specific variables for parallel study */
  refdat              = actdt,             /* Reference data variable name for recalculating visit */
  reftim              = ,                  /* Reference time variable name for recalculating visit */
  refdatedsetsubset   = ,                  /* WHERE clause applied to source dataset */
  refdateoption       = TREAT,             /* Reference date source option. */
  refdatesourcedset   = ,                  /* Reference date source dataset. */
  refdatesourcevar    = ,                  /* Reference date source variable. */
  refdatevisitnum     = ,                  /* Specific visit number at which reference date is to be taken. */
  dyrefdateoption     = ,                  /* Reference date source option for the calculation of Study Day values in tu_derive^Reference date source option for tu_derive.*/   
  dyrefdatedsetsubset = ,                  /* WHERE clause applied to source dataset for tu_derive. */
  dyrefdatesourcedset = ,                  /* Reference date source dataset for tu_derive. */
  dyrefdatesourcevar  = ,                  /* Reference date source variable for tu_derive. */
  dyrefdatevisitnum   = ,                  /* Specific visit number at which reference date is to be taken for tu_derive. */
  dsettemplate        = ,                  /* Planned A&R dataset template name. */
  dsplan              = &g_dsplanfile,     /* Path and filename of tab-delimited file containing HARP A&R dataset plan. */
  decodepairs         = ,                  /* Code and decode variables in pair */
  decoderename        = ,                  /* List of renames for decoded variables */
  formatnamesdset     = ,                  /* Format names dataset name. */
  sortorder           = ,                  /* Planned A&R dataset sort order. */
  ptrtcdinf           = ,                  /* Informat to derive PTRTCD from PTRTGRP. */
  trtcdinf            = ,                  /* Informat to derive TRTCD from TRTGRP. */
  noderivevars        =                    /* List of variables not to derive. */ 
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
  %let dsetin_ipdisc       = %nrbquote(&dsetin_ipdisc.);               
  %let dsetout             = %nrbquote(&dsetout.);
  %let preprocess          = %nrbquote(&preprocess.);
  %let postprocess         = %nrbquote(&postprocess.);
  %let trt_dev_exists      = %nrbquote(%upcase(&trt_dev_exists));
  %let calctpernum_version = %nrbquote(%upcase(&calctpernum_version));
  %let treatvarsyn         = %nrbquote(%upcase(&treatvarsyn));
  %let attributesyn        = %nrbquote(%upcase(&attributesyn));
  %let misschkyn           = %nrbquote(%upcase(&misschkyn));
  %let xovarsforpgyn       = %nrbquote(%upcase(&xovarsforpgyn));
  %let addmultiobsyn       = %nrbquote(%upcase(&addmultiobsyn));

  /* 
  / Check for valid parameter values
  / set up a macro variable to hold the pv_abort flag
  /----------------------------------------------------------------------------*/
  %local pv_abort prefix preprocessdset postprocessdset loopi thisvar listvars ;
  %let pv_abort = 0 ;
  %let prefix = _tc_p1_ipdisc;   /* Root name for temporary work datasets */

  /*
  / If the input dataset name is the same as the output dataset name,
  / write an error to the log.
  /----------------------------------------------------------------------------*/
  %if %qscan(&dsetin_ipdisc, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
    %do;
      %put %str(RTE)RROR: &sysmacroname: The input dataset name DSETIN(=&dsetin_ipdisc) is the same as output data set name DSETOUT(=&dsetout).;
      %let pv_abort=1;
    %end;

  /*
  / Check for required parameters.
  /----------------------------------------------------------------------------*/
  %let listvars=DSETIN_IPDISC DSETOUT;

  %do loopi=1 %to 2;
    %let thisvar=%scan(&listvars, &loopi, %str( ));
    %let &thisvar=%nrbquote(&&&thisvar);
    
    %if &&&thisvar eq %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: The parameter &thisvar cannot be blank.;
       %let pv_abort=1;
    %end;    
  %end;  /* end of do-to loop */

  /* 
  / Check for valid values of TREATVARSYN, ATTRIBUTESYN, MISSCHKYN, XOVARSFORPGYN, 
  / ADDMULTIOBSYN and TRT_DEV_EXISTS 
  /---------------------------------------------------------------------------------------*/ 
  %tu_valparms(
    macroname=&macroname., 
    chktype=isOneOf, 
    pv_varsin= treatvarsyn attributesyn misschkyn xovarsforpgyn addmultiobsyn trt_dev_exists,      
    valuelist = Y N, 
    abortyn = N
    );

  /*
  / Validation of dataset
  /   Check existence of datasets and variables
  /----------------------------------------------------------------------------*/

  /* Macro Parameter DSETIN_IPDISC */
  %if not %sysfunc(exist(&dsetin_ipdisc)) %then 
    %do;
      %put RTE%str(RROR): &sysmacroname.: DSETIN_IPDISC(=&dsetin_ipdisc) does not exist;
      %let pv_abort = 1;
    %end;

  /* Macro Parameter TMSLICEDSET */
  %if &g_stype=XO and &addmultiobsyn=Y %then 
    %do;
      %if %length(&tmslicedset) = 0 %then %do;
        %put %str(RTE)RROR: &macroname: Macro parameter (tmslicedset) cannot be blank;
        %let pv_abort = 1;
      %end; 
      %if not %sysfunc(exist(&tmslicedset)) %then %do;
        %put RTE%str(RROR): &sysmacroname.: The TMSLICEDSET(=&tmslicedset) dataset does not exist;
        %let pv_abort = 1;
      %end;
      %else %do;
        %if %length(%tu_chkvarsexist(&tmslicedset, PERNUM PERIOD)) gt 0 %then %do;
          %put RTE%str(RROR): &sysmacroname.: &tmslicedset dataset does not contain PERNUM and/or PERIOD variables;
          %let pv_abort=1;
        %end;
      %end;
  %end;

  /* Check if use tu_p1_calctpernum or tu_calctpernum macro */
  %if &g_stype = XO or (&g_stype = PG and &xovarsforpgyn = Y) %then 
    %do;
      %if %length(&calctpernum_version) = 0 %then %do;
        %put %str(RTE)RROR: &macroname: Macro parameter (calctpernum_version) cannot be blank;
        %let pv_abort = 1;
      %end;
      %else %if (&calctpernum_version ne TU_P1_CALCTPERNUM) and (&calctpernum_version ne TU_CALCTPERNUM) %then %do;
        %put %str(RTE)RROR: &macroname: Value of CALCTPERNUM_VERSION(=&calctpernum_version) is invalid. Valid values are TU_P1_CALCTPERNUM or TU_CALCTPERNUM.;
        %let pv_abort=1;
      %end;
    %end;

  /*
  / Complete validation
  /----------------------------------------------------------------------------*/
  %if %eval(&g_abort. + &pv_abort.) gt 0 %then 
    %do;
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
  %let preprocessdset = &dsetin_ipdisc;

  %if %nrbquote(&preprocess) ne %then %do;
     data &prefix._preprocess;
        set &dsetin_ipdisc ;
        %unquote(&preprocess);;
     run;
     %let preprocessdset = &prefix._preprocess;
  %end;

  /*
  / Call DAMA macro tc_ipdisc
  /----------------------------------------------------------------------------*/
  %tc_ipdisc (
   dsetin              = &preprocessdset,      /* Input dataset name */
   dsetout             = &prefix._ipdisc1,     /* Output dataset name */
   demodset            = &demodset,            /* Name of DEMO dataset to use */
   enroldset           = &enroldset,           /* Name of ENROL dataset to use */
   exposuredset        = &exposuredset,        /* Name of EXPOSURE dataset to use */
   investigdset        = &investigdset,        /* Name of INVESTIG dataset to use */
   racedset            = &racedset,            /* Name of RACE dataset to use */
   randalldset         = &randalldset,         /* Name of RANDALL dataset to use */
   randdset            = &randdset,            /* Name of RAND dataset to use */
   tmslicedset         = &tmslicedset,         /* Name of TMSLICE dataset to use */
   visitdset           = &visitdset,           /* Name of VISIT dataset to use */
   agedaysyn           = &agedaysyn,           /* Calculation of age in days. */
   agemonthsyn         = &agemonthsyn,         /* Calculation of age in months. */
   ageweeksyn          = &ageweeksyn,          /* Calculation of age in weeks. */
   attributesyn        = N,                    /* Reconcile A&R dataset with planned A&R dataset */
   commonvarsyn        = &commonvarsyn,        /* Add common variables. */
   datetimeyn          = &datetimeyn,          /* Derive datetime variables */
   decodeyn            = &decodeyn,            /* Decode coded variables */
   derivationyn        = &derivationyn,        /* Dataset specific derivations */
   misschkyn           = N,                    /* Print warning message for variables in &DSETOUT with missing values on all records */
   recalcvisityn       = &recalcvisityn,       /* Recalculate VISIT */
   timeslicingyn       = &timeslicingyn,       /* Add timeslicing variables */
   treatvarsyn         = N,                    /* Add treatment variables. */
   xovarsforpgyn       = N,                    /* If Y derive crossover study specific variables for parallel study */ 
   refdat              = &refdat,              /* Reference data variable name for recalculating visit */
   reftim              = &reftim,              /* Reference time variable name for recalculating visit */
   refdatedsetsubset   = &refdatedsetsubset,   /* WHERE clause applied to source dataset */
   refdateoption       = &refdateoption,       /* Reference date source option. */
   refdatesourcedset   = &refdatesourcedset,   /* Reference date source dataset. */
   refdatesourcevar    = &refdatesourcevar,    /* Reference date source variable. */
   refdatevisitnum     = &refdatevisitnum,     /* Specific visit number at which reference date is to be taken. */
   dyrefdateoption     = &dyrefdateoption,     /* Reference date source option for the calculation of Study Day values in tu_derive^Reference date source option for tu_derive.*/   
   dyrefdatedsetsubset = &dyrefdatedsetsubset, /* WHERE clause applied to source dataset for tu_derive. */
   dyrefdatesourcedset = &dyrefdatesourcedset, /* Reference date source dataset for tu_derive. */
   dyrefdatesourcevar  = &dyrefdatesourcevar,  /* Reference date source variable for tu_derive. */
   dyrefdatevisitnum   = &dyrefdatevisitnum,   /* Specific visit number at which reference date is to be taken for tu_derive. */
   dsettemplate        = &dsettemplate,        /* Planned A&R dataset template name. */
   dsplan              = &dsplan,              /* Path and filename of tab-delimited file containing HARP A&R dataset plan. */
   decodepairs         = &decodepairs,         /* Code and decode variables in pair */
   decoderename        = &decoderename,        /* List of renames for decoded variables */
   formatnamesdset     = &formatnamesdset,     /* Format names dataset name. */
   sortorder           = &sortorder,           /* Planned A&R dataset sort order. */
   trtcdinf            = &trtcdinf,            /* Informat to derive TRTCD from TRTGRP. */
   ptrtcdinf           = &ptrtcdinf,           /* Informat to derive PTRTCD from PTRTGRP. */
   noderivevars        = &noderivevars         /* List of variables not to derive. */
   );

  /* Set a temporary macro variable containing dataset reference */
  %let postprocessdset = &prefix._ipdisc1;

  %if &g_stype = XO or (&g_stype = PG and &xovarsforpgyn = Y) %then %do;

    %if "&calctpernum_version"="TU_P1_CALCTPERNUM" %then %do;

      /*
      / Set TPERNUM to null prior to call to tu_p1_calctpernum.
      /----------------------------------------------------------------------------*/
      data &prefix._ipdisc2;
        set &prefix._ipdisc1;
        * set oldtpernum to tpernum for debug ;
        oldtpernum = tpernum ;
        * reset value of tpernum ;
        tpernum=.;
      run;

      /* Set a temporary macro variable containing dataset reference */
      %let postprocessdset = &prefix._ipdisc2;

      /*
      / Call macro tu_p1_calctpernum to add the correct TPERNUM & TPERIOD
      /----------------------------------------------------------------------------*/
      %tu_p1_calctpernum ( dsetin       = &postprocessdset    /* Input dataset name */
                          ,dsetout      = &prefix._ipdisc3    /* Output dataset name */
                          ,datadomain   = IP                  /* Data Domain - One of (AE,BL,CM,DS,DS2,SD,IP) */
                          ,refdat       = &refdat             /* Reference date variable name */
                          ,reftim       = &reftim             /* Reference time variable name */
                          ,exposuredset = &exposuredset       /* Exposure dataset name */
                          ,tmslicedset  = &tmslicedset        /* Time Slicing dataset name*/
                          );

    %end;
    %else %if "&calctpernum_version"="TU_CALCTPERNUM" %then %do ;

      %tu_calctpernum ( dsetin       = &postprocessdset  /* Input dataset name */
                       ,dsetout      = &prefix._ipdisc3  /* Output dataset name */
                       ,exposuredset = &exposuredset     /* Exposure dataset name */
                       ,refdat       = &refdat           /* Variable name for reference date */
                       ,reftim       = &reftim           /* Variable name for reference time */
                       ,tmslicedset  = &tmslicedset      /* Time slice dataset name */
                       ,visitdset    = &visitdset        /* Visit dataset name */
                       );
    %end ;

    /* Set a temporary macro variable containing dataset reference */
    %let postprocessdset = &prefix._ipdisc3;

  %end;

  /*
  / Append additional rows to output dataset in order to produce
  / summary table by period treatment for XO studies 
  / (1 row per subject and period until subject stopped taking study drug) 
  /-----------------------------------------------------------------------*/
  %if &g_stype=XO and &addmultiobsyn=Y %then %do;

    data &prefix._ipdisc4 (drop=tperiod pernum);
      set &postprocessdset;

        sddrvfl='';

        output;

        sddrvfl='Y';
        sdstopp='N';
        sdseq=.;
        sdrscd=.;
        sdrs='';
        sdsubrcd='';
        sdsubr='';
        sdendt=.;
        sdentm=.;
        tperdy=.;
        sdrssp='';
        sdsubrsp='';;

        do while (tpernum gt 1);
          tpernum=tpernum-1;
          output;
        end;
    run;

    /* Use TMSLICE dataset to add TPERIOD */
    proc sql;
    create table &prefix._ipdisc5 as
    select distinct a.*, b.period as tperiod, b.pernum as pernum
    from &prefix._ipdisc4 a left join &tmslicedset b
    on a.tpernum=b.pernum
    order by a.subjid, a.tpernum;
    quit;

    /* Set a temporary macro variable containing dataset reference */
    %let postprocessdset = &prefix._ipdisc5;

  %end;

  /*
  / Treatment assignment
  /-----------------------------------------------------------------------------*/
  %if &treatvarsyn=Y %then %do;

    /*
    / Add treatment variables to dataset
    /---------------------------------------------------------------------------*/
    %tu_rantrt ( dsetin      = &postprocessdset  /* Input dataset name */ 
                ,dsetout     = &prefix._ipdisc6  /* Output dataset name */
                ,ptrtcdinf   = &ptrtcdinf        /* Informat to derive PTRTCD from PTRTGRP */
                ,randalldset = &randalldset      /* RANDALL data set name */
                ,randdset    = &randdset         /* RAND data set name */
                ,trtcdinf    = &trtcdinf         /* Informat to derive TRTCD from TRTGRP */
               );

    /*
    / Call %tu_p1_acttrt_pg/xo to add the correct Treatment and Actual Treatment
    /---------------------------------------------------------------------------*/
    %if &g_stype=PG %then %do;

      %tu_p1_acttrt_pg (dsetin         = &prefix._ipdisc6,  /* Name of input dataset */
                        dsetout        = &prefix._ipdisc7,  /* Name of output dataset */ 
                        trt_dev_exists = &trt_dev_exists,   /* Do treatment deviations exist for your study? */
                        exposuredset   = &exposuredset      /* Name of EXPOSURE dataset to use */
                        );

    %end;
    %else %if &g_stype=XO %then %do;

      %tu_p1_acttrt_xo (dsetin         = &prefix._ipdisc6,  /* Name of input dataset */
                        dsetout        = &prefix._ipdisc7,  /* Name of output dataset */
                        trt_dev_exists = &trt_dev_exists,   /* Do treatment deviations exist for your study? */
                        exposuredset   = &exposuredset,     /* Name of EXPOSURE dataset to use */
                        tmslicedset    = &tmslicedset       /* Name of TMSLICE dataset to use */
                        );

    %end;

    /*
    / Set the Treatment at the time investigational product stopped to the actual treatment last taken
    /------------------------------------------------------------------------------------------------*/
    data &prefix._ipdisc8;
      set &prefix._ipdisc7;
        %if &g_stype = PG %then %str(sdacttrt=atrtgrp;);
        %else %if &g_stype = XO %then %str(sdacttrt=tpatrtgp;);
    run;

   /* Set a temporary macro variable containing dataset reference */
   %let postprocessdset = &prefix._ipdisc8;

  %end;

  %if "&g_stype"="XO" and %tu_chkvarsexist(&dsetin_ipdisc, &refdat) eq %then %do;

    /*
    / Create Treatment Period Day
    /---------------------------------------------------------------------------*/
    %tu_p1_periodday ( dsetin         = &postprocessdset /* Input dataset                                    */
                      ,dsetout        = &prefix._ipdisc9 /* Output dataset                                   */
                      ,refdate        = &refdat          /* Reference date variable on input dataset         */
                      ,eventtype      = SP               /* Specifies if the event is planned or spontaneous */
                      ,varout         = tperdy           /* Name of Period Day variable created              */
                      ,exposuredset   = &exposuredset    /* Name of EXPOSURE dataset to use */ 
                      ,tmslicedset    = &tmslicedset     /* Name of TMSLICE dataset to use */ 
    );

    /* Set a temporary macro variable containing dataset reference */
    %let postprocessdset = &prefix._ipdisc9;

  %end;

  /*
  / Post-processing of input dataset
  /   This step allows for the user to post-process the dataset in way of
  /     using simple SAS code. This post-process step is invoked before
  /     calling of the tu_attrib and tu_misschk macros
  /   e.g. in the driver call, the user could include information such as
  /     postprocess = where studypart = 'B' ;
  /----------------------------------------------------------------------------*/
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

%mend tc_p1_ipdisc;
