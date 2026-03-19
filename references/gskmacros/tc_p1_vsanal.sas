/****************************************************************************************************
|
| Macro Name:      tc_p1_vsanal
|
| SAS Version:     9.1.3
|
| Created By:      Andy Miskell
|
| Date:            March 18, 2009
|
| Macro Purpose:   Create VSANAL A&R data set for Phase 1 requirements
|                  (PG & XO studies)
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| ------------------------------------------------------------------
| ------------------------------------------------------------------
|                 FOR INPUT PARAMETERS, REFER TO
|                 DOCUMENTATION FOR TC_P1_VSANAL
| ------------------------------------------------------------------
| ------------------------------------------------------------------
|
| Global macro variables created: NONE
|
| Macros called:
| (@) tc_vsanal
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_chkvarsexist
| (@) tu_attrib
| (@) tu_valparms
| (@) tu_misschk
| (@) tu_p1_studyday
| (@) tu_p1_periodday
| (@) tu_p1_acttrt_PG
| (@) tu_p1_acttrt_XO
| (@) tu_tidyup
| (@) tu_p1_mean
| (@) tu_putglobals
|
|****************************************************************************************************
| Change Log 
|
| Modified By: 
| Date of Modification: 
| New Version/Build Number:
| Modification ID: 
| Reason For Modification: 
|
****************************************************************************************************/

%macro tc_p1_vsanal (
trt_dev_exists      = N,
/* Do Treatment Deviations exists for your study? */
meanbyvars          = vstestcd,
/* By variables e.g. visitnum visit ;  exclude SUBJID from list */
meangrp1            = ,
/* Values of first group of observations to mean using where-clause syntax */
meangrpval1         = ,
/* Assignment statements to identify the new observation holding the mean value created from meangrp1 e.g. ptmnum=25; ptm='Mean Pre-dose'; */
meangrp2            = ,
/* Values of second group of observations to mean in where-clause syntax */
meangrpval2         = ,
/* Assignment statements to identify the new observation holding the mean value created from meangrp2 e.g. ptmnum=15; ptm='Mean Screening'; */
   varstomiss          = vsacttm vscccd vsccind vschcd vschind,  /* Variables to set to missing for the mean observation e.g. egacttm egintpcd egleadcd */
   preprocess          = ,                                       /* Any processing required after reading in the input dataset */               
   postprocess         = ,                                       /* Any processing required before writing out to final output dataset */       
   dsetin_vitals       =dmdata.vitals,                           /* Input dataset name */
   dsetout             =ardata.vsanal,                           /* Output dataset name */   
   critdset            =dmdata.vscrit,                           /* Vital Signs flagging criteria dataset name */
   demodset            =dmdata.demo,                             /* Name of DEMO dataset to use */
   enroldset           =dmdata.enrol,                            /* Name of ENROL dataset to use */
   exposuredset        =dmdata.exposure,                         /* Name of EXPOSURE dataset to use */
   investigdset        =dmdata.investig,                         /* Name of INVESTIG dataset to use */
   racedset            =dmdata.race,                             /* Name of RACE dataset to use */
   randalldset         =dmdata.randall,                          /* Name of RANDALL dataset to use */
   randdset            =dmdata.rand,                             /* Name of RAND dataset to use */
   tmslicedset         =dmdata.tmslice,                          /* Name of TMSLICE dataset to use */
   visitdset           =dmdata.visit,                            /* Name of VISIT dataset to use */
   baselinetype        =MEAN NOUNS,                              /* Select method of calculating baseline, when there are multiple baseline obs. */
   attributesyn        =Y,                                       /* Reconcile A&R dataset with planned A&R dataset */
   baselineyn          =Y,                                       /* Calculation of baseline */
   bsfgyn              =Y,                                       /* F2 Change from Baseline flagging */
   ccfgyn              =Y,                                       /* F3 Clinical Concern flagging */
   commonvarsyn        =Y,                                       /* Add common variables. */
   datetimeyn          =Y,                                       /* Derive datetime variables */
   decodeyn            =Y,                                       /* Decode coded variables */
   derivationyn        =Y,                                       /* Dataset specific derivations */
   misschkyn           =Y,                                       /* Print warning message for variables in &DSETOUT with missing values on all records */
   recalcvisityn       =N,                                       /* Recalculate VISIT based on the AE start date */
   timeslicingyn       =Y,                                       /* Add timeslicing variables */
   treatvarsyn         =Y,                                       /* Add treatment variables. */
   xovarsforpgyn       =N,                                       /* If Y derive crossover stydy specific variables for parallel study */
   agedaysyn           =N,                                       /* Calculation of age in days. */
   agemonthsyn         =N,                                       /* Calculation of age in months. */
   ageweeksyn          =N,                                       /* Calculation of age in weeks. */
   refdat              =vsdt,                                    /* Reference date variable name for recalculating visit */
   reftim              =vsacttm,                                 /* Reference time variable name for recalculating visit */
   refdatedsetsubset   =,                                        /* WHERE clause applied to source dataset */
   refdateoption       =TREAT,                                   /* Reference date source option. */
   refdatesourcedset   =,                                        /* Reference date source dataset. */
   refdatesourcevar    =,                                        /* Reference date source variable. */
   refdatevisitnum     =,                                        /* Specific visit number at which reference date is to be taken. */
   dyrefdateoption     =,                                        /* Reference date source option for the calculation of Study Day values in tu_derive Reference date source option for tu_derive.*/   
   dyrefdatedsetsubset =,                                        /* WHERE clause applied to source dataset for tu_derive. */
   dyrefdatesourcedset =,                                        /* Reference date source dataset for tu_derive. */
   dyrefdatesourcevar  =,                                        /* Reference date source variable for tu_derive. */
   dyrefdatevisitnum   =,                                        /* Specific visit number at which reference date is to be taken for tu_derive. */
   dgcd                =CLINPHARM_PCI_HVT,                       /* VSCRIT compound identifier */
   cpdsrng             =,                                        /* VSCRIT clinical pharamcolgy range identifier */
   studyid             =,                                        /* VSCRIT study identifier */
   baselineoption      =DATE,                                    /* alculation of baseline option */
   reldays             =,                                        /* Number of days prior to start of study medication */
   startvisnum         =,                                        /* VISITNUM value for start of baseline range */
   endvisnum           =,                                        /* VISITNUM value for end of baseline range */
   flaggingsubset      =,                                        /* IF clause to identify records to be flagged */
   stmeddset           =DMDATA.EXPOSURE,                         /* Study medication dataset name */
   stmeddsetsubset     =,                                        /* Where clause applied to study medication dataset */
   ptrtcdinf           =,                                        /* Informat to derive PTRTCD from PTRTGRP. */
   trtcdinf            =,                                        /* Informat to derive TRTCD from TRTGRP. */
   sortorder           =,                                        /* Planned A&R dataset sort order. */
   dsettemplate        =,                                        /* Output dataset template name. */
   dsplan              =&G_DSPLANFILE,                           /* Path and filename of tab-delimited file containing HARP A&R dataset plan. */
   decodepairs         =,                                        /* code and decode variables in pair */
   formatnamesdset     =,                                        /* Format names dataset name. */
   noderivevars        =                                         /* List of variables not to derive. */
   );                                                            


  /* Echo parameter values and global macro variables to the log
  /----------------------------------------------------------------------------*/
  %local MacroVersion MacroName postprocessdset preprocessdset;
  %let MacroName=&sysmacroname.;
  %let MacroVersion=1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals();

  /*
  / Check for valid parameter values
  /   set up a macro variable to hold the pv_abort flag
  /----------------------------------------------------------------------------*/
  %local loopi listvars thisvar byvara
         prefix pv_abort abortyn;
  %let pv_abort = 0 ;


  %let prefix=_tc_p1_vsanal;   /* Root name for temporary work datasets */


  /*
  / PARAMETER VALIDATION
  /----------------------------------------------------------------------------*/

  %let dsetin_vitals     = %nrbquote(&dsetin_vitals.);               
  %let dsetout           = %nrbquote(&dsetout.);
  %let preprocess        = %nrbquote(&preprocess.);
  %let postprocess       = %nrbquote(&postprocess.);
  %let treatvarsyn       = %nrbquote(%upcase(&treatvarsyn));
  %let attributesyn      = %nrbquote(%upcase(&attributesyn));
  %let misschkyn         = %nrbquote(%upcase(&misschkyn));

  /*
  / Check for required parameters.
  /----------------------------------------------------------------------------*/
  
  %let listvars=dsetin_vitals dsetout attributesyn misschkyn treatvarsyn;
 
  %do loopi=1 %to 5;
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

  %if %qscan(&dsetin_vitals, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
  %do;
    %put %str(RTE)RROR: &sysmacroname: The input dataset name dsetin_vitals(=&dsetin_vitals) is the same as the output dataset name DSETOUT(=&dsetout).;
    %let pv_abort=1;
  %end;
 
  /*
  / Check for existing datasets.and valid values
  /----------------------------------------------------------------------------*/

  %tu_valparms(
      macroname =tc_p1_vsanal,
      chktype   =dsetExists,
      pv_dsetin =dsetin_vitals
      );

  %tu_valparms(
    macroname   = tc_p1_vsanal,
    chktype     = isOneOf,
    pv_varsin   = treatvarsyn attributesyn misschkyn,
    valuelist   = Y N,
    abortyn     = N
   );

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
  %let preprocessdset = &dsetin_vitals ;

  %if %nrbquote(&preprocess) ne %then %do;
    data &prefix._preprocess;
      set &dsetin_vitals;
      %unquote(&preprocess);;
    run;
    %let preprocessdset = &prefix._preprocess;
  %end;

  /*
  / The following data step subsets the PCI flagging dataset to ensure 
  / that only the DGCD and STUDYID specified in the macro call are passed to tc_vsanal.
  /----------------------------------------------------------------------------*/

  data &prefix._vscritt (drop=vsposcd);
    set &critdset;
    if dgcd="&dgcd" and studyid = "&studyid";
  run;

  %tc_vsanal(
DSETIN              =&preprocessdset,
/* Input dataset name */
DSETOUT             =&prefix._vsanal1,
/* Output dataset name */
CRITDSET            =&prefix._vscritt,
/* Vital Signs flagging criteria dataset name */
DEMODSET            =&DEMODSET           ,
/* Name of DEMO dataset to use */
ENROLDSET           =&ENROLDSET          ,
/* Name of ENROL dataset to use */
EXPOSUREDSET        =&EXPOSUREDSET       ,
/* Name of EXPOSURE dataset to use */
INVESTIGDSET        =&INVESTIGDSET       ,
/* Name of INVESTIG dataset to use */
RACEDSET            =&RACEDSET           ,
/* Name of RACE dataset to use */
RANDALLDSET         =&RANDALLDSET        ,
/* Name of RANDALL dataset to use */
RANDDSET            =&RANDDSET           ,
/* Name of RAND dataset to use */
TMSLICEDSET         =&TMSLICEDSET,
/* Name of TMSLICE dataset to use */
VISITDSET           =&VISITDSET          ,
/* Name of VISIT dataset to use */
BASELINETYPE        =&BASELINETYPE       ,                   /* Select method of calculating baseline,
when there are multiple baseline obs. */  /* GK001 */
ATTRIBUTESYN        =N,
/* Reconcile A&R dataset with planned A&R dataset */
BASELINEYN          =&BASELINEYN         ,
/* Calculation of baseline */
BSFGYN              =&BSFGYN             ,
/* F2 Change from Baseline flagging */
CCFGYN              =&CCFGYN             ,
/* F3 Clinical Concern flagging */
COMMONVARSYN        =&COMMONVARSYN       ,
/* Add common variables. */
DATETIMEYN          =&DATETIMEYN         ,
/* Derive datetime variables */
DECODEYN            =&DECODEYN           ,
/* Decode coded variables */
DERIVATIONYN        =&DERIVATIONYN       ,
/* Dataset specific derivations */
MISSCHKYN           =N,
/* Print warning message for variables in &DSETOUT with missing values on all records */
RECALCVISITYN       =&RECALCVISITYN      ,
/* Recalculate VISIT based on the AE start date */
TIMESLICINGYN       =&TIMESLICINGYN      ,
/* Add timeslicing variables */
TREATVARSYN         =&TREATVARSYN        ,
/* Add treatment variables. */
XOVARSFORPGYN       =&XOVARSFORPGYN      ,
/* If Y derive crossover stydy specific variables for parallel study */
AGEDAYSYN           =&AGEDAYSYN          ,
/* Calculation of age in days. */
AGEMONTHSYN         =&AGEMONTHSYN        ,
/* Calculation of age in months. */
AGEWEEKSYN          =&AGEWEEKSYN         ,
/* Calculation of age in weeks. */
REFDAT              =&REFDAT             ,
/* Reference date variable name for recalculating visit */
REFTIM              =&REFTIM             ,
/* Reference time variable name for recalculating visit */
REFDATEDSETSUBSET   =&REFDATEDSETSUBSET  ,
/* WHERE clause applied to source dataset */
REFDATEOPTION       =&REFDATEOPTION      ,
/* Reference date source option. */
REFDATESOURCEDSET   =&REFDATESOURCEDSET  ,
/* Reference date source dataset. */
REFDATESOURCEVAR    =&REFDATESOURCEVAR   ,
/* Reference date source variable. */
REFDATEVISITNUM     =&REFDATEVISITNUM    ,
/* Specific visit number at which reference date is to be taken. */
DYREFDATEOPTION     =&DYREFDATEOPTION    ,
/* Reference date source option for the calculation of Study Day values in tu_derive Reference date source option for tu_derive.*/
DYREFDATEDSETSUBSET =&DYREFDATEDSETSUBSET,
/* WHERE clause applied to source dataset for tu_derive. */
DYREFDATESOURCEDSET =&DYREFDATESOURCEDSET,
/* Reference date source dataset for tu_derive. */
DYREFDATESOURCEVAR  =&DYREFDATESOURCEVAR ,
/* Reference date source variable for tu_derive. */
DYREFDATEVISITNUM   =&DYREFDATEVISITNUM  ,
/* Specific visit number at which reference date is to be taken for tu_derive. */
DGCD                =&DGCD               ,
/* VSCRIT compound identifier */
CPDSRNG             =&CPDSRNG            ,
/* VSCRIT clinical pharamcolgy range identifier */
STUDYID             =&STUDYID            ,
/* VSCRIT study identifier */
BASELINEOPTION      =&BASELINEOPTION     ,
/* alculation of baseline option */
RELDAYS             =&RELDAYS            ,
/* Number of days prior to start of study medication */
STARTVISNUM         =&STARTVISNUM        ,
/* VISITNUM value for start of baseline range */
ENDVISNUM           =&ENDVISNUM          ,
/* VISITNUM value for end of baseline range */
FLAGGINGSUBSET      =&FLAGGINGSUBSET     ,
/* IF clause to identify records to be flagged */
STMEDDSET           =&STMEDDSET          ,
/* Study medication dataset name */
STMEDDSETSUBSET     =&STMEDDSETSUBSET    ,
/* Where clause applied to study medication dataset */
PTRTCDINF           =&PTRTCDINF          ,
/* Informat to derive PTRTCD from PTRTGRP. */
TRTCDINF            =&TRTCDINF           ,
/* Informat to derive TRTCD from TRTGRP. */
SORTORDER           =&SORTORDER          ,
/* Planned A&R dataset sort order. */
DSETTEMPLATE        =&DSETTEMPLATE       ,
/* Output dataset template name. */
DSPLAN              =&DSPLAN             ,
/* Path and filename of tab-delimited file containing HARP A&R dataset plan. */
DECODEPAIRS         =&DECODEPAIRS        ,
/* code and decode variables in pair */
FORMATNAMESDSET     =&FORMATNAMESDSET    ,
/* Format names dataset name. */
NODERIVEVARS        =&NODERIVEVARS                           /* List of variables not to derive. */

    );

  %let postprocessdset = &prefix._vsanal1;

  /*
  / Call TU_P1_MEAN macro to mean replicate observations
  /----------------------------------------------------------------------------*/

  %if "&meangrp1"^="" %then %do;

    %local chgvar;

    /*
    / Check to see if Change from Baseline has been calculated
    / If not, then chgvar will be blank and that variable will not be
    / passed to tu_p1_mean.
    /----------------------------------------------------------------------------*/
    %if %length(%tu_chkvarsexist(&postprocessdset, stdchgbl)) = 0 %then %do;
      %let chgvar=stdchgbl;
    %end;
    %else %do;
      %let chgvar=;
    %end;

    %tu_p1_mean(dsetin    = &postprocessdset,
         dsetout          = &prefix._vsanal2,
         meanbyvars       = &meanbyvars,
         meangrp1         = &meangrp1 ,
         meangrpval1      = &meangrpval1  ,
         meangrp2         = &meangrp2,
         meangrpval2      = &meangrpval2 ,
         varstomean       = vsstresn vsorresn &chgvar,
         varstomiss       = &varstomiss
         );
    %let postprocessdset = &prefix._vsanal2;

  %end;

  /*
  / Call tu_p1_acttrt to add the correct Treatment and Actual Treatment
  /---------------------------------------------------------------------------*/

  %if &g_stype=PG and &treatvarsyn=Y %then %do;

    %tu_p1_acttrt_PG(dsetin  = &postprocessdset,
             dsetout         = &prefix._vsanal3,
             trt_dev_exists  = &trt_dev_exists,
             exposuredset    = &exposuredset
             );

    %let postprocessdset = &prefix._vsanal3;

  %end;
  %if &g_stype=XO and &treatvarsyn=Y %then %do;

    %tu_p1_acttrt_XO(dsetin  = &postprocessdset,
             dsetout         = &prefix._vsanal3,
             trt_dev_exists  = &trt_dev_exists,
             exposuredset    = &exposuredset,
             tmslicedset     = &tmslicedset
             );

    %let postprocessdset = &prefix._vsanal3;

  %end;

  /*
  / Call tu_p1_studyday to create the VSACTDY variable
  /---------------------------------------------------------------------------*/

  %tu_p1_studyday (dsetin   = &postprocessdset,
            dsetout         = &prefix._vsanal4,
            refdate         = vsdt,
            varout          = vsactdy
              );

  %let postprocessdset = &prefix._vsanal4;


  %if &g_stype=XO %then %do;
    /*
    / Call tu_p1_periodday to create the XPERDY variable
    /---------------------------------------------------------------------------*/

    %tu_p1_periodday (dsetin  = &postprocessdset,
              dsetout         = &prefix._vsanal5,
              refdate         = vsdt,
              eventtype       = PL,
              varout          = xperdy
              );

    %let postprocessdset = &prefix._vsanal5;

  %end;

  /*
  / This section will determine if a subject had any abnormal PCI values (H or L)
  / If the subject had any abnormal value, CRITCCFL will be assigned as Y for the entire subject
  / Otherwise, CRITCCFL will be assigned as N for the entire subject
  /---------------------------------------------------------------------------*/
  /* Call if baseline flagging is turned on */
  %if &bsfgyn=Y %then %do;

    /*
    / If VSCHCD exists, assign value to TEMPDVAR
    / Otherwise, TEMPDVAR is set to missing
    /---------------------------------------------------------------------------*/
    data &prefix._vsanal6;
      set &postprocessdset;
      length tempdvar $ 1;
      tempdvar=vschcd;
    run;

    /* 
    / Subset dataset if there are any PCI abnormalities
    / &prefix._pciabnorm dataset holds subjid for all subjects with any PCI abnormality
    /---------------------------------------------------------------------------*/
    proc sort data=&prefix._vsanal6 out=&prefix._pciabnorm (keep=subjid);
      by subjid;
      where vscccd in ('H' 'L') or tempdvar in ('H' 'L');
    run;

    data &prefix._vsanal7 (drop=tempdvar);
      set &prefix._vsanal6;
    run;

  %end;

  /* Call if baseline flagging is turned off */
  %else %do;

    /* Call if PCI raw flagging is turned on */
    %if &ccfgyn=Y %then %do;
      /* 
      / Subset dataset if there are any PCI abnormalities
      / &prefix._pciabnorm dataset holds subjid for all subjects with any PCI abnormality
      /---------------------------------------------------------------------------*/
      proc sort data=&postprocessdset out=&prefix._pciabnorm (keep=subjid);
        by subjid;
        where vscccd in ('H' 'L');
      run;

      data &prefix._vsanal7 (drop=tempdvar);
        set &postprocessdset;
      run;

    %end;

  %end;

  %let postprocessdset = &prefix._vsanal7;

  /* Call if PCI raw flagging is turned on */
  %if &ccfgyn=Y %then %do;
  
    proc sort data=&prefix._pciabnorm out=&prefix._pciabnorm nodupkey;
      by subjid;
    run;

    proc sort data=&postprocessdset out=&prefix._vsanal8;
      by subjid;
    run;

    /* Merge dataset of PCI abnormalities onto full dataset by subject              */
    /* and flag every observation within subject if there are any PCI abnormalities */
    data &prefix._vsanal9;
      merge &prefix._pciabnorm (in=a) &prefix._vsanal8;
      by subjid;
      if a then critccfl = 'Y';
      else critccfl = 'N';
    run;

    %let postprocessdset = &prefix._vsanal9;

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
      set &postprocessdset ;
      %unquote(&postprocess);;
    run;
    %let postprocessdset=&prefix._postprocess;
  %end;

  %if &attributesyn eq Y %then
  %do;
    %tu_attrib(
         dsetin       = &postprocessdset,
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

  %if &misschkyn eq Y %then
  %do;
    %tu_misschk(
         dsetin        = &dsetout
         );
  %end;

  /*
  / Delete temporary datasets used in this macro.
  /----------------------------------------------------------------------------*/

  %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tc_p1_vsanal;

