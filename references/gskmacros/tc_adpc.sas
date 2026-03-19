/******************************************************************************* 
|
| Macro Name:      tc_adpc.sas
|
| Macro Version:   1 build 3
|
| SAS Version:     9.4
|
| Created By:      Warwick Benger, Andy Miskell, Anthony Cooper
|
| Date:            22-Nov-2012
|
| Macro Purpose:   This macro shall create an ADaM ADPC dataset from the SDTM sources (PC, EX, SUPPPC)
|
| Macro Design:    PROCEDURE STYLE MACRO
| 
| Input Parameters:
|
| NAME              DESCRIPTION                               REQ/OPT  DEFAULT
| ----------------  ----------------------------------------  -------  ---------------
| DSETIN            Specifies the name of the input SDTM      REQ      sdtmdata.pc
|                   dataset 
|
| DSETINEXP         Specifies the name of the input SDTM      REQ      sdtmdata.ex
|                   exposure dataset 
|
| ADSUPPJOINYN      Specifies whether to call TU_ADSUPPJOIN   REQ      Y
|
| DSETINSUPP   		Specifies the name of the input SDTM      OPT      sdtmdata.supppc
|                   SUPP dataset 
|
| DSETOUT           Specifies the name of the output dataset  REQ      adamdata.adpc [WJB1]
|                   to be created 
|
| PREPROCESSPC      Specifies subsetting for input SDTM       OPT      (Blank)
|                   dataset
|
| PREPROCESSEX      Specifies subsetting for input SDTM       OPT      (Blank)
|                   exposure dataset
|
| POSTPROCESS       Specifies subsetting for output dataset   OPT      (Blank)
|
| EXPJOINBYVARS     Specifies the variables by which the      OPT      &g_subjid visitnum
|                   exposure dataset shall be merged with the
|                   the PK data
|
| XCPFILE           Specifies the value to be passed          REQ      &g_pkdata/&g_fnc._recon
|                   to %tu_xcpinit's outfile parameter
|
| JOINMSG           Specifies whether unmatched records in    REQ      WARNING
|                   joins (e.g. PK/SMS2000) should be treated
|                   as warnings or errors
|
| IMPUTEBY          Specifies the variables by which the      REQ      &g_subjid pcspec pctestcd visitnum 
|                   imputation shall be done. The dataset is           pcrfdsdm pctptnum
|                   sorted prior to imputation using any 
|                   variables in IMPUTEBY which are found in
|                   the dataset. Imputation is then performed
|                   restarting whenever any IMPUTEBY variable
|                   other than the last one changes.              
| 
| IMPUTETYPE        Specifies either standard (S)             REQ      S
|                   or alternative (A) imputation.
|  
| ARELTMCUNIT       Specifies the format for displaying the   REQ      HM
|                   the Analysis Relative Time character
|                   variable. Either "DDd HHh MMm" (DHM), 
|                   "HHh MMm" (HM) or "MMm" (M).
|
| ASTTMDVCUNIT      Specifies the format for displaying the   REQ      HM
|                   the Analysis Relative Time Deviation
|                   character variable. Either
|                   "DDd HHh MMm" (DHM), "HHh MMm" (HM)
|                   or "MMm" (M).
|
| GETADSLVARSYN     Specifies whether to call                 REQ      Y
|                   TU_ADGETADSLVARS
| 
| DSETINADSL        Specifies the treatment dataset name.     OPT      adamdata.adsl
|
| ADSLVARS          Space separated list of variables to be   OPT	   siteid age sex race ethnic
|                   fetched from ADSL dataset.			               acountry trtsdt trtedt trtseq: pkfl
| 
| ADVISITYN         Specifies whether to call TU_ADVISIT      REQ      Y
| 
| ADVISITNFMT       Format to derive AVISITN from VISITNUM    OPT      (Blank)
|
| ADVISITFMT        Format to derive AVISIT from VISIT        OPT      (Blank)
|
| ADPERIODYN        Specifies whether to call TU_ADPERIOD     REQ      N
| 
| ADGETTRTYN        Specifies whether to call TU_ADGETTRT     REQ      Y
| 
| ADGETTRTMERGEVARS Specifies the space separated list of     OPT      USUBJID
|                   variables to merge input and treatment
|                   datasets.
|                   Valid values: valid variable names
|                   which exist on DSETIN and DSETINADSL
|
| ADGETTRTVARS      Specifies the space separated list of 	  OPT	   TRT01PN TRT01P TRT01AN TRT01A
|                   variables to fetch from the treatment
|                   dataset.
|                   Valid values: valid variable names
|                   which exist on DSETINADSL
|
| ADRELDAYSYN       Specifies whether to call TU_ADRELDAYS    REQ      Y
| 
| DYREFDATEVAR	    dsetinadsl var to identify start          OPT      (Blank)
|                   of treatment period 
|
| DECODEYN          Flag to indicate if tu_decode utility     REQ      N
|                   is to be executed Y/N
|
| DECODEPAIRS       A list of paired code/decode variables    OPT      (Blank)
|                   for which the decode is to be created
|
| CODEPAIRS         A list of paired code/decode variables    OPT      (Blank)
|                   for which the code is to be created
|
| ATTRIBUTESYN      Specifies whether to call TU_ATTRIB       REQ      Y
| 
| MISSCHKYN         Specifies whether to call TU_MISSCHK      REQ      Y
| 
| Output: An ADaM PC dataset and exception report
|
| Global macro variables created:  None
|
| Macros called:
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_chkvarsexist
| (@) tu_words
| (@) tu_decode
| (@) tu_xcpinit
| (@) tu_adreldays
| (@) tu_adsuppjoin
| (@) tu_adgettrt
| (@) tu_pkcncderv
| (@) tu_adgetadslvars
| (@) tu_adperiod
| (@) tu_advisit
| (@) tu_xcpterm
| (@) tu_chknames
| (@) tu_nobs
| (@) tu_attrib
| (@) tu_misschk
| (@) tu_tidyup
| (@) tu_abort
|
| Example macro call
|
| %tc_adpc(
|      dsetin=sdtmdata.pc                          
|     ,dsetinexp=sdtmdata.ex                       
|     ,adsuppjoin=Y                  
|     ,dsetinsupp=sdtmdata.supppc                  
|     ,dsetout=adamdata.adpc                       
|     ,preprocesspc=%nrstr(length atptref $8; atptref=pctptref; if pctestcd="ANAL1" then do; pcorresu="pg/mL"; pcstresu="pg/mL"; end;)
|     ,preprocessex=%nrstr(length atptref $8; atptref=cat(trim(scan(extpt,3)),' DOSE');)                               
|     ,postprocess=                                
|     ,decodeyn=N
|     ,decodepairs=
|     ,codepairs=
|     ,expjoinbyvars=&g_subjid visitnum visit      
|     ,xcpfile=&g_pkdata./&g_fnc._recon            
|     ,joinmsg=WARNING                             
|     ,imputeby=&g_subjid pcspec pctestcd visitnum pcrfdsdm pctptnum 
|     ,imputetype=S                               
|     ,areltmcunit=HM
|     ,asttmdvcunit=HM
|     ,adgettrtyn=Y                                   
|     ,dsetinadsl=adamdata.adtrt                      
|     ,adreldaysyn=Y
|     ,dyrefdatevar=trsdt                            
|     ,attributesyn=Y                                 
|     ,misschkyn=Y                                
|     );
|
|******************************************************************************* 
| Change Log 
|
| Modified By:              Suzanne Brass
| Date of Modification:     12-Apr-2017
| New version number:       N/A
| Modification ID:          N/A
| Reason For Modification:  Updated SAS Version to 9.4
|
| Modified By:              Anthony J Cooper
| Date of Modification:     05-Oct-2017
| New version number:       1 build 2
| Modification ID:          AJC001
| Reason For Modification:  1) Initialise variables expected by tu_pkcncderv
|                           which originate from permissible SDTM variables
|                           2) Clean up uni(n)itialised variable notes
|                           3) Use chkvarsexist when deriving ATPT etc.
|                           4) Upcase variables like PCSPEC when used in comparisons
|                           5) Change ADSUPPJOINYN default from N to Y
|                           6) Upcase all YN parameters at the start of the 
|                           parameter validation section so that checks work
|                           correctly and to remove need to use upcase throughout
|                           the rest of the code.
|
| Modified By:              Anthony J Cooper
| Date of Modification:     05-Jun-2018
| New version number:       1 build 3
| Modification ID:          AJC002
| Reason For Modification:  1) Derive ARELTMC and ASTTMDVC according to new
|                           parameters ARELTMCUNIT and ASTTMDVCUNIT. Possible 
|                           formats are: "DDd HHh MMm", "HHh MMm" (default)
|                           and "MMm".
|                           2) Modify derivation of ANL01FL, ANL02FL, and ANL03FL
|                           flags to handle more than one analyte
|                           3) Correct derivation of flags on non-imputed rows 
|                           4) Remove redundant derivations, drop some temporary
|                           variables, rename some datasets to facilitate debugging
|                           5) Keep Sample Volume, pH and Weight results as rows
|                           and pass through tu_pkcncderv to maintain traceability.
|                           Rework pre- and post-processing to accomdate this
|                           6) Use numeric part of PCTESTCD to derive PARAMCD, e.g.
|                           when PCTESTCD=ANAL0103 then PARAMCD is P0103RES etc.
|
|********************************************************************************/ 

%macro tc_adpc(
     dsetin=sdtmdata.pc                          /* Name of input SDTM PC (concentration) dataset */
    ,dsetinexp=sdtmdata.ex                       /* Name of input SDTM EX (exposure) dataset */
    ,adsuppjoinyn=Y                              /* If supplemental dataset is required to be joined with parent domain Y/N */
    ,dsetinsupp=sdtmdata.supppc                  /* Name of input SDTM SUPPPC dataset */
    ,dsetout=adamdata.adpc                       /* Output dataset */
    ,preprocesspc=                               /* Processing clause for DSETIN */
    ,preprocessex=                               /* Processing clause for DSETINEXP */
    ,postprocess=                                /* Processing clause for DSETOUT */
    ,expjoinbyvars=&g_subjid visitnum            /* Variables by which exposure is merged with PK data */
    ,xcpfile=&g_pkdata./&g_fnc._recon            /* Name and location of exception report */
    ,joinmsg=WARNING                             /* Type of messages to be issued from joins (error or warning) */
    ,imputeby=&g_subjid pcspec pctestcd visitnum pcrfdsdm pctptnum /* Variables to impute by */
    ,imputetype=S                                /* Imputation type. Specifies either standard (S) or alternative (A) imputation */
    ,areltmcunit=HM                              /* Format to use for ARELTMC derivation */
    ,asttmdvcunit=HM                             /* Format to use for ASTTMDVC derivation */
    ,getadslvarsyn=Y                             /* Flag to indicate if tu_adgetadslvars utility need to be called */
    ,dsetinadsl=adamdata.adsl                    /* Input ADSL or ADTRT dataset */
    ,adslvars=siteid age sex race ethnic acountry trtsdt trtedt trtseq: pkfl /* List of variable from DSETINADSL dataset for tu_adgetadslvars utility to merge on by USUBJID*/
    ,advisityn=Y                                 /* Flag to indicate if tu_advisit utility is to be executed Y/N */
    ,advisitnfmt=                                /* Format used to derive AVISITN from VISITNUM*/
    ,advisitfmt=                                 /* Format used to derive AVISIT from VISIT*/ 
    ,adperiodyn=N                                /* Flag to indicate if tu_adperiod utility is to be executed Y/N */
    ,adgettrtyn=Y                                /* Flag to indicate if tu_adgettrt utility is to be executed Y/N */
    ,adgettrtmergevars=USUBJID                   /* Variables used to merge treatment information from DSETINADSL onto work dataset */
    ,adgettrtvars=trt01p trt01pn trt01a trt01an  /* List of variables from treatment dataset DSETINADSL for tu_adgettrt utility to add to work dataset */
    ,adreldaysyn=Y                               /* Flag to indicate if tu_adreldays utility is to be executed*/
    ,dyrefdatevar=                               /* Reference date variable for analysis relative days derivation: ADY, ASTDY, AENDY*/
    ,decodeyn=N                                  /* Flag to indicate if tu_decode utility is to be executed Y/N */
    ,decodepairs=                                /* A list of paired code/decode variables for which the decode is to be created*/ 
    ,codepairs=                                  /* A list of paired code/decode variables for which the code is to be created*/
    ,attributesyn=Y                              /* Apply attributes? */
    ,misschkyn=Y                                 /* Check for variables with all values missing, and values of PARAMCD with no values? */
    );

  /*
  / Echo macro version number and values of parameters and global macro
  / variables to the log.
  /----------------------------------------------------------------------------*/
  %local MacroVersion /* Carries macro version number */
         prefix       /* Carries file prefix for work files */
         __debug_obs; /* Sets debug maximum number of observations */

  %let MacroVersion = 1 build 3;
  %let prefix=%substr(&sysmacroname,3);
  %let domain=PC;

  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_refdata g_abort g_debug g_subjid g_dsplanfile g_pkdata g_fnc)

  %if &g_debug ge 3 %then %let __debug_obs=obs=max;
  %else                   %let __debug_obs=obs=100;
   
  /*
  / PARAMETER VALIDATION
  /----------------------------------------------------------------------------*/
  %let dsetin=%nrbquote(&dsetin.);
  %let dsetout=%nrbquote(&dsetout.);
  %let adreldaysyn=%nrbquote(%upcase(&adreldaysyn.));
  %let adsuppjoinyn=%nrbquote(%upcase(&adsuppjoinyn.));
  %let decodeyn=%nrbquote(%upcase(&decodeyn.));
  %let advisityn=%nrbquote(%upcase(&advisityn.)); /* AJC001: upcase parameter value */
  %let getadslvarsyn=%nrbquote(%upcase(&getadslvarsyn.)); /* AJC001: upcase parameter value */
  %let adperiodyn=%nrbquote(%upcase(&adperiodyn.)); /* AJC001: upcase parameter value */
  %let adgettrtyn=%nrbquote(%upcase(&adgettrtyn.)); /* AJC001: upcase parameter value */
  %let attributesyn=%nrbquote(%upcase(&attributesyn.)); /* AJC001: upcase parameter value */
  %let misschkyn=%nrbquote(%upcase(&misschkyn.)); /* AJC001: upcase parameter value */
  %let areltmcunit=%nrbquote(%upcase(&areltmcunit.)); /* AJC002: new parameter */
  %let asttmdvcunit=%nrbquote(%upcase(&asttmdvcunit.)); /* AJC002: new parameter */

  /* 1. Check that DSETIN is provided and exists */
  %if %length(&dsetin) eq 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname: The DSETIN parameter must not be blank;
    %let g_abort=1;
  %end;
  %else
  %do;
    %if not %sysfunc(exist(&dsetin)) %then
    %do;
      %put RTE%str(RROR): &sysmacroname: The DSETIN dataset (&dsetin) does not exist;
      %let g_abort=1;
    %end;
  %end;

  /* 2. Check that DSETINEXP is provided and exists */
  %if %length(&dsetinexp) eq 0 %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: The parameter DSETINEXP is required.;
    %let g_abort=1;
  %end;
  %else
  %do; 
    %if not %sysfunc(exist(&dsetinexp)) %then 
    %do;  
      %put %str(RTE)RROR: &sysmacroname.: The DSETINEXP dataset (&dsetinexp.) does not exist.;
      %let g_abort=1;
    %end;
  %end;
  
  /* 3. Check that DSETINSUPP exists if provided */
  %if %length(&dsetinsupp) ne 0 %then
  %do;
    %if not %sysfunc(exist(&dsetinsupp)) %then 
    %do;  
      %put %str(RTE)RROR: &sysmacroname.: The DSETINSUPP dataset (&dsetinsupp.) does not exist.;
      %let g_abort=1;
    %end;
  %end;
  
  /* 4. Check that DSETOUT is provided, has a valid name, and is not the same as DSETIN */
  %if %length(&dsetout) eq 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname: The DSETOUT parameter must not be blank;
    %let g_abort=1;
  %end;
  %else
  %do;
    %if %length(%tu_chknames(&dsetout,DATA)) ne 0 %then
    %do;
      %put RTE%str(RROR): &sysmacroname: The DSETOUT parameter (&dsetout) does not specify a valid dataset name;
      %let g_abort=1;
    %end;
  %end;
  %if %qupcase(&dsetout.) eq %qupcase(%scan(&dsetin, 1, %str(%() )) %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: The Output dataset name is same as Input dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
  
  /* 5. Check DECODEYN/ADGETTRTYN/ATTRIBUTESYN/MISSCHKYN/ADSUPPJOINYN/GETADSLVARSYN/ADPERIODYN/ADVISITYN/ADRELDAYSYN are populated with Y or N */
  %if &decodeyn. ne Y and &decodeyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DECODEYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
  %if &adgettrtyn ne Y and &adgettrtyn ne N %then %do;
    %put RTE%str(RROR): &sysmacroname: The parameter(s) ADGETTRTYN should be Y or N;
    %let g_abort=1;
  %end;
  %if &attributesyn ne Y and &attributesyn ne N %then %do;
    %put RTE%str(RROR): &sysmacroname: The parameter(s) ATTRIBUTESYN should be Y or N;
    %let g_abort=1;
  %end;
  %if &misschkyn ne Y and &misschkyn ne N %then %do;
    %put RTE%str(RROR): &sysmacroname: The parameter(s) MISSCHKYN should be Y or N;
    %let g_abort=1;
  %end;
  %if &adsuppjoinyn. ne Y and &adsuppjoinyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ADSUPPJOINYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
  %if &getadslvarsyn. ne Y and &getadslvarsyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter GETADSLVARSYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
  %if &adperiodyn. ne Y and &adperiodyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ADPERIODYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
  %if &advisityn. ne Y and &advisityn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ADVISITYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
  %if &adreldaysyn. ne Y and &adreldaysyn. ne N %then
  %do;  
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ADRELDAYSYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
  
  /* 6. Check ARELTMCUNIT and ASTTMDVCUNIT are populated with DHM, HM or M */

  %if &areltmcunit. ne DHM and &areltmcunit. ne HM and &areltmcunit. ne M %then
  %do;  
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ARELTMCUNIT should either be DHM, HM or M.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
  
  %if &asttmdvcunit. ne DHM and &asttmdvcunit. ne HM and &asttmdvcunit. ne M %then
  %do;  
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ASTTMDVCUNIT should either be DHM, HM or M.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
  
  %tu_abort;
  
  %local currentDataset;
  %let currentDataset=&dsetin;

/*
/ NORMAL PROCESSING
/----------------------------------------------------------------------------*/

/*** PRE PROCESSING ***/

  /* Calling tu_adsuppjoin to merge supplemental dataset with parent domain dataset, if adsuppjoinyn parameter is Y */
  %if &adsuppjoinyn eq Y %then
  %do; /* AJC001: remove upcase function */
    %tu_adsuppjoin(dsetin     = &currentDataset
                  ,dsetinsupp = &dsetinsupp
                  ,dsetout    = &prefix._dsetin_addsupp
                  );
    %let currentDataset = &prefix._dsetin_addsupp;
  %end;

  /* Determine list of SDTM variables to use as "keys" in sort/merge */
  %local allInKeys foundInKeys;
  %let allInKeys = DOMAIN STUDYID USUBJID PCSPEC VISITNUM VISIT PCTPTREF PCTPTNUM PCTPT PCREFID;
  %let foundInKeys = %tu_chkvarsexist(&currentdataset,&allInKeys,Y);
  %if &g_debug gt 0 %then;
    %put RTD%str(EBUG): &sysmacroname: FOUNDINKEYS=&foundInKeys;

  /* PC dataset */    
  data &prefix._dsetin_presubset;
    set &currentDataset;
    %if %length(%tu_chkvarsexist(&currentDataset,PCDTC)) eq 0 %then %do;
      PCSTDT = input(substr(PCDTC,1,10),yymmdd10.);
      PCSTTM = input(substr(PCDTC,12,5),time5.);
    %end;
    %else %do;
      PCSTDT = .;
      PCSTTM = .;
    %end; /* AJC001: Initialise variable(s) used by tu_pkcncderv */
    %if %length(%tu_chkvarsexist(&currentDataset,PCENDTC)) eq 0 %then %do;
      PCENDT = input(substr(PCENDTC,1,10),yymmdd10.);
      PCENTM = input(substr(PCENDTC,12,5),time5.);
    %end;
    %else %do;
      PCENDTC = '';
      PCENDT = .;
      PCENTM = .;
    %end; /* AJC001: Initialise variable(s) used by tu_pkcncderv */
    %if %length(%tu_chkvarsexist(&currentDataset,PCLLOQ)) eq 0 %then %do;
      PCLLQN = PCLLOQ;
    %end;
    %if %length(%tu_chkvarsexist(&currentDataset,PCTPT)) eq 0 %then %do;
      PTM = PCTPT;
    %end;
    %else %do;
      PTM='';
    %end; /* AJC001: Initialise variable(s) used by tu_pkcncderv */
    %if %length(%tu_chkvarsexist(&currentDataset,PCTYPCD)) ^= 0 %then %do;
      PCTYPCD='';
    %end;
    %if %length(%tu_chkvarsexist(&currentDataset,PCELTM)) eq 0 %then %do;
      if PCELTM ne '' then do;
        if not index(pceltm,"PT") then do;  /* DAYS, MONTHS or YEARS are present */
          pceltm_dt=scan(pceltm,1,"PT");
          if index(pceltm_dt,"Y") then do;
            pceltm_y=input(scan(pceltm_dt,1,"Y"),??best.);
            pceltm_dt=scan(pceltm_dt,2,"Y");
          end;
          if index(pceltm_dt,"M") then do;
            pceltm_mon=input(scan(pceltm_dt,1,"M"),??best.);
            pceltm_dt=scan(pceltm_dt,2,"M");
          end;
          if index(pceltm_dt,"D") then pceltm_d=input(scan(pceltm_dt,1,"D"),??best.);
        end;
        if index(pceltm,"T") then do;  /* HOURS, MINUTES or SECONDS are present */
          pceltm_tm=scan(pceltm,2,"T");
          if index(pceltm_tm,"H") then do;
            pceltm_h=input(scan(pceltm_tm,1,"H"),??best.);
            pceltm_tm=scan(pceltm_tm,2,"H");
          end;
          if index(pceltm_tm,"M") then do;
            pceltm_m=input(scan(pceltm_tm,1,"M"),??best.);
            pceltm_tm=scan(pceltm_tm,2,"M");
          end;
          if index(pceltm_tm,"S") then pceltm_s=input(scan(pceltm_tm,1,"S"),??best.);
        end;
        eltmnum=sum((pceltm_d*24),pceltm_h,(pceltm_m/60),(pceltm_s/3600));
        ELTMUNIT="HRS";
      end;
      drop pceltm_: ; /* AJC002: drop temporary variables */
    %end;
    %else %do;
        eltmnum=.;
        eltmunit="";
    %end; /* AJC001: Initialise variable(s) used by tu_pkcncderv */
    %if %length(%tu_chkvarsexist(&currentDataset,PKALLCOL)) eq 0 %then %do;
      rename PKALLCOL = PCALLCOL;
    %end;
    %if %length(&preprocesspc) gt 0 %then %do;
      &preprocesspc.;
    %end;
  proc sort;
    by &foundInKeys;
  run;
  %let currentDataset=&prefix._dsetin_presubset;

  /* EX dataset */    
  data &prefix._dsetinexp_presubset1;
    set &dsetinexp;
    %if %length(&preprocessex) gt 0 %then %do;
      &preprocessex.;
    %end;
  run;
  data &prefix._dsetinexp_presubset2;
    set &prefix._dsetinexp_presubset1;
    %if %length(%tu_chkvarsexist(&dsetinexp,EXSTDTC)) eq 0 %then %do;
      EXSTDT = input(substr(exstdtc,1,10),yymmdd10.);
      EXSTTM = input(substr(exstdtc,12,5),time5.);
    %end;
  run;
  %let dsetinexp=&prefix._dsetinexp_presubset2;

  /* Define list of ADaM variables plus units to be derived by tu_pkcncderv */
  /* AJC002: remove duplicates and unnecessary variables from ADAMPARMVALS */
  %local adamparmvals;
  %let adamparmvals= ELTMSTN PCATMNUM PCATMC PCWNLRT PCDUR PCSTTMDV PCUAE PCSTIMPN PCSTIMSN PCWNLN PCUER;
  %let adamparmvals = &adamparmvals ELTMSTU PCATMU PCDURU PCTMDVU PCUAEU PCWNLU;

  /* AJC002: Add PCSTRESC/PCSTRESU to adamparmvals if they do not already exist in SDTM */
  %local pcstresc pcstresu;
  %let pcstresc=%tu_chkvarsexist(&currentDataset,PCSTRESC);
  %let pcstresu=%tu_chkvarsexist(&currentDataset,PCSTRESU);
  %let adamparmvals=&adamparmvals &pcstresc &pcstresu;
  %if &g_debug gt 0 %then;
    %put RTD%str(EBUG): &sysmacroname: ADAMPARMVALS=&adamparmvals;

  /*** Denormalise PCVOL / PCWT / PCPH records ***/
  data &prefix._dsetin_vol &prefix._dsetin_wt &prefix._dsetin_ph;
    set &currentDataset;
    if pctestcd="PKSMPVOL" then do;
      PCVOL=pcstresn;
      length pcvolu $20;
      pcvolu=pcstresu;
      output &prefix._dsetin_vol;
    end;
    else if pctestcd="PKSMPWT" then do;
      PCWT=pcstresn;
      length pcwtu $20;
      pcwtu=pcstresu;
      output &prefix._dsetin_wt;
    end;
    else if pctestcd="PKSMPPH" then do;
      PCPH=pcstresn;
      length pcphu $20;
      pcphu=pcstresu;
      output &prefix._dsetin_ph;
    end;
  run;
  
  %local incvol incwt incph;
  %if %tu_nobs(&prefix._dsetin_vol) ne 0 %then %let incvol=Y;
  %if %tu_nobs(&prefix._dsetin_wt) ne 0 %then %let incwt=Y;
  %if %tu_nobs(&prefix._dsetin_ph) ne 0 %then %let incph=Y;

  /* AJC002: Remove where clause which dropped "PKSMPPH" "PKSMPVOL" "PKSMPWT" records from source dataset. */
  /* These are needed to keep the traceability of the source data from SDTM */
  %if &incvol eq Y or &incwt eq Y or &incph eq Y %then %do;
    data &prefix._dsetin_trans;
      merge &currentDataset(in=a) 
            %if &incvol eq Y %then &prefix._dsetin_vol(keep=&foundInKeys pcvol pcvolu);
            %if &incwt eq Y %then &prefix._dsetin_wt(keep=&foundInKeys pcwt pcwtu);
            %if &incph eq Y %then &prefix._dsetin_ph(keep=&foundInKeys pcph pcphu);
            ;
      by &foundInKeys;
      if a;
    run;
    %let currentDataset = &prefix._dsetin_trans;
  %end;
  
  /* AJC002: Inform user if any of the variables about to be derived by TU_PKCNCDERV already exist from SDTM */
  
  %local sdtmvarexist;  
  %let sdtmvarexist = %tu_chkvarsexist(&currentDataset, PCRFDSDT PCRFDSTM PCRFDSDM &ADAMPARMVALS, Y);

  %if %length(&sdtmvarexist) gt 0 %then %do;
    %put RTN%str(OTE): &sysmacroname.: Variable(s) &sdtmvarexist exist in dataset &currentDataset.;
    %put RTN%str(OTE): &sysmacroname.: Values for these variable(s) may be overwritten by derivations in TU_PKCNCDERV.;
  %end;  
  
/*** Call TU_PKCNCDERV to generate derived variables ***/
  /* Open the exception reporting */
  %tu_xcpinit(
      header     = TC_ADPC
     ,odsdest    = html
     ,outfilesfx = html
     ,outfile    = &xcpfile
     );

  /* Call TU_PKCNCDERV */
  /* AJC002: Set PCWTU parameter to missing, this has already been derived */
  %tu_pkcncderv(
     dsetin=&currentDataset
    ,dsetinexp=&dsetinexp
    ,dsetinperiod=
    ,dsetout=&prefix._adpc1
    ,pcwtu=
    ,joinmsg=&joinmsg
    ,expjoinbyvars=&expjoinbyvars
    ,imputeby=&imputeby
    ,imputetype=&imputetype
    ,adamparmvals=&adamparmvals
    );
  %let currentDataset = &prefix._adpc1;

  /* Close the exception reporting */
  %tu_xcpterm;  
   
  /* Handle samples with 0 volume, by accumulating the duration to the first non-zero sample */
  %local imputelast incpcallcol;
  %let imputelast=%scan(&imputeby,%tu_words(&imputeby) - 1);    
  %if %length(%tu_chkvarsexist(&currentDataset,PCALLCOL)) eq 0 %then %let incpcallcol=Y;
  %else %let incpcallcol=N;
  %if &g_debug gt 0 %then %do;
    %put RTD%str(EBUG): &sysmacroname: IMPUTELAST=&imputelast;
    %put RTD%str(EBUG): &sysmacroname: INCPCALLCOL=&incpcallcol;
    %put RTD%str(EBUG): &sysmacroname: IMPUTEBY=&imputeby;
  %end;
  
  /* AJC001: Initialise PCVOL if it does not exist to prevent notes in next data step */
  data &prefix._adpc2;
    set &currentDataset;
    %if &incvol ne Y %then retain pcvol .;;
  run;

  %let currentDataset = &prefix._adpc2;

  proc sort data=&currentDataset;
    by &imputeby;
  run;

  data &prefix._adpc3;
    set &currentDataset;
    by &imputeby;
    retain cumdur;
    /* AJC001: Modified to prevent un(initialised) variable messages */
    if first.&imputelast %if &incpcallcol eq Y %then or pcallcol eq "N"; then cumdur=0;
    if lag(pcvol) eq 0 and lag(pcstresc) eq 'NS' then cumdur=cumdur+pcdur;
    else cumdur=pcdur;
    if upcase(pcspec)="URINE" %if &incpcallcol eq Y %then and pcallcol ne "N"; and eltmnum > 0 then do;
      if pcorres^='NQ' then pcuer=pcuae/cumdur;
      pcwnln=pcuer;
    end;
  run;
  %let currentDataset = &prefix._adpc3;    

/*** Rename variables to ADaM variable names ***/

  /* AJC002: Derive ARELTMC and ASTTMDVC in "DDd HHh MMm" format via local macro. */
  /* ARELTMC was previously a rename of PCATMC from tu_pkcncderv. */

  %macro reltime2char(nvar=,cvar=,unit=);

      %local pcatsign pcatd pcath pcatm nvar cvar derivationd derivationm derivationh;

      /* Set up all the derivations based on requested unit value: DHM, HM or M */

      %let pcatsign = substr(put(repeat('-',(sign(&nvar._temp)-1)/-2),$2.),2,1);

      %let pcatd = right(right(compbl(&pcatsign)) || left(abs(int((&nvar._temp)/24)))) || "d";

      %if %index(&unit,D) %then
        %let pcath = put(put(abs(mod(int(&nvar._temp),24)),2.) || "h",$3.);
      %else
        %let pcath = put(put(abs(int(&nvar._temp)),4.) || "h",$5.);

      %if %index(&unit,H) %then
        %let pcatm = put(put(abs((&nvar._temp-int(&nvar._temp)))*60,2.)||left("m"),$3.);
      %else
        %let pcatm = put(put(abs( (&nvar._temp) )*60,8.)||left("m"),$9.);

      %let derivationd = right(put( right(compbl(&pcatd)) || " " || right(compbl(&pcath)) || " " || right(&pcatm) ,$14.));
      %let derivationh = right(put( right(right(compbl(&pcatsign)) || left(compbl(&pcath))) || " " || right(&pcatm) ,$14.));
      %let derivationm = right(put( right(compbl(&pcatsign)) || left(compbl(&pcatm)) ,$14.));

      /* Create a temporary duplicate of the numeric relative time variable */

      &nvar._temp=&nvar;

      if &nvar._temp ne . then do;

        /* For urine samples, derived relative time may be very close to a whole number of hours, e.g. 18.992. */
        /* In this example the character relative time would come out as 18h 60m so the round function is used to get 19h 0m */

        if &pcatm. eq "60m" then
          &nvar._temp=round(&nvar._temp);

        /* Depending on the relative time value (always in hours) and the requested unit, create the character variable */
        /* as "DDd HHm MMm", "HHm MMm" or "MMm". Note: if DHM is rquested, a value of 23.5 hours will be displayed as "23h 30m" */
        /* rather than "0d 23h 30m" */

        if abs(&nvar._temp) ge 24 and index("&unit", "D") gt 0 then
          &cvar = &derivationd;
        else if abs(&nvar._temp) ge 1 and index("&unit", "H") gt 0 then
          &cvar = &derivationh;
        else
          &cvar=&derivationm;

      end;

      drop &nvar._temp;

  %mend reltime2char;

  data &prefix._adpc4;
    set &currentDataset (rename=( 
                                 PCRFDSDT = AEXLSDT     PCRFDSTM = AEXLSTM      
                                 PCRFDSDM = AEXLSDTM    PCSTDT   = ASTDT
                                 PCSTTM   = ASTTM       PCENDT   = AENDT
                                 PCENTM   = AENTM       ELTMSTN  = APRELTM
                                 ELTMSTU  = APRELTMU    PCATMNUM = ARELTM
                                 PCATMU   = ARELTMU     /* AJC002: ARELTMC re-derived */
                                 PCDUR    = ADURN       PCDURU   = ADURU
                                 PCWNLRT  = AWNLRT      PCSTTMDV = ASTTMDV
                                 PCTMDVU  = ASTTMDVU    /* AJC001: let tu_adreldays handle the derivation of ADY */
                                 PCRESIMP = IMPFLAG     /* AJC002: keep tu_pkcncderv imputation flag to aid debugging */
                                 )
                         drop=PCATMC /*AJC002: drop as ARELTMC re-derived*/);
    AWNLRTU = ARELTMU;
    ASTDTM=dhms(astdt,0,0,asttm);
    if asttmdv = . then asttmdvu='';
    if adurn = . then aduru='';
    if apreltm = . then apreltmu='';
    %reltime2char(nvar=ARELTM, cvar=ARELTMC, unit=&ARELTMCUNIT);
    %reltime2char(nvar=ASTTMDV, cvar=ASTTMDVC, unit=&ASTTMDVCUNIT);
  run;
  %let currentDataset = &prefix._adpc4;

/*** Establish which variables were actually created ***/
  /* AJC001: Add additional SDTM.PC source variables to allKeys1 including PCDY for tu_adreldays */
  /* AJC002: Add ASTTMDVC and IMPFLAG to allKeys2 */
  %local allCols foundCols redADaMVars allKeys1 allKeys2 foundKeys1 foundKeys2 allkeysn removeCols ptr word;

  /* AJC002: Ensure that PCSTRESC/PCSTRESU are included adamparmvals ready for the transpose */
  %if %length(&pcstresc) eq 0 %then  
    %let adamparmvals=&adamparmvals PCSTRESC;
  %if %length(&pcstresu) eq 0 %then  
    %let adamparmvals=&adamparmvals PCSTRESU;

  %let allCols=%upcase(&adamparmvals);
  %let allKeys1 = SRCDOM SITEID STUDYID USUBJID SUBJID PCSEQ PCREFID PCSPEC PCTESTCD PCTEST PCLLOQ PCSTRESC PCSTRESN PCSTRESU PCSTAT PCREASND PCALLCOL VISITNUM VISIT PCTPTREF PCTPTNUM PCTPT PCVOLU PCUAEU PCDY PCRFTDTC PCDTC PCENDT PCENDY PCCAT PCSCAT;
  %let allKeys2 = ADT ATM ADY ATPTN ATPTREF AEXLSDT AEXLSTM AEXLSDTM ASTDT ASTTM ASTDTM AENDT AENTM APRELTM APRELTMU ARELTM ARELTMC ARELTMU AWNLRT AWNLRTU ADURN ADURU ASTTMDV ASTTMDVC ASTTMDVU DTYPE IMPFLAG;
  
  /* Establish any variables missing from either allCols or allKeys */
  %let removeCols=%tu_chkvarsexist(&currentdataset,&allCols) %tu_chkvarsexist(&currentdataset,&allKeys1) %tu_chkvarsexist(&currentdataset,&allKeys2);

  /* AJC002: Add variables that were merged onto the PC dataset prior to tu_pkcncderv so they will be dropped when the dataset is normalised */
  %let removeCols=&removeCols PCVOL PCVOLU PCWT PCWTU PCPH PCPHU;

  /* Create foundCols by removing any variables not found by chkvarsexist from allCols */
  %do ptr=1 %to %tu_words(&allCols);
    %let word = %scan(&allCols,&ptr);
    %if not %sysfunc(indexw(&removeCols,&word)) %then
      %let foundCols = &foundCols &word;
  %end;

  /* Create foundKeys by removing any variables not found by chkvarsexist from allKeys */
  %do allkeysn = 1 %to 2;
    %do ptr=1 %to %tu_words(&&allKeys&allkeysn.);
      %let word = %scan(&&allKeys&allkeysn.,&ptr);
      %if not %sysfunc(indexw(&removeCols,&word)) %then
        %let foundKeys&allkeysn. = &&foundKeys&allkeysn. &word;
    %end;
  %end;
  
  %if &g_debug gt 0 %then %do;
    %put RTD%str(EBUG): &sysmacroname: ALLCOLS=&allCols;
    %put RTD%str(EBUG): &sysmacroname: ALLKEYS=&allKeys1 &allKeys2;
    %put RTD%str(EBUG): &sysmacroname: REMOVECOLS=&removeCols;
    %put RTD%str(EBUG): &sysmacroname: FOUNDCOLS=&foundCols;
    %put RTD%str(EBUG): &sysmacroname: FOUNDKEYS=&foundKeys1 &foundKeys2;
  %end;
  
/*** Normalise ***/
  proc sort data=&currentDataset;
    by &foundKeys1 &foundKeys2;
  run;

  proc transpose data=&currentDataset 
                 out=&prefix._adpc5 (rename=(AVALC1=AVALC) drop=_label_)
                 name=PARAMCD
                 prefix=AVALC;
                                            
    by &foundKeys1 &foundKeys2;
    var &foundCols;
    /* AJC002: Do not normalise sample volume, weight and pH records. These are handled later. */
    where (upcase(pctestcd) not in ("PKSMPPH" "PKSMPVOL" "PKSMPWT"));
  run;
  %let currentDataset = &prefix._adpc5;

/*** Denormalise unit variables and use them and labels to generate PARAM. ***/
  proc format; 
    value $unitvars
      "PCSTIMPN" = "PCSTRESU"
      "PCSTIMSN" = "PCSTRESU"
      "PCWNLN"   = "PCWNLU"
      "PCUAE"    = "PCUAEU"
      "PCUER"    = "PCWNLU"
      "PCVOL"    = "PCVOLU"
      "PCWT"     = "PCWTU"
      ;
   
    value $adamlbl
      "PCUAE"    = "Amount excreted"
      "PCUER"    = "Excretion rate"
      "PCSTRESC" = "Concentration"
      "PCSTIMPN" = "Concentration imputed for summary statistics"
      "PCSTIMSN" = "Concentration imputed for plots"
      "PCWNLN"   = "Concentration imputed for NCA"
      "PCVOL"    = "Sample volume"
      "PCWT"     = "Sample weight"
      "PCPH"     = "Sample pH"
      ;
  run;

  /* Split dataset into data and units */
  data &prefix._adpc5_res(drop=unit) 
       &prefix._adpc5_unit(keep=&foundKeys1 &foundKeys2 UNITVAR UNIT);
    set &currentDataset;
    paramcd=upcase(paramcd);
    if paramcd in ("PCSTRESU" "PCUAEU" "PCVOLU" "PCWNLU" "PCWTU") then do;
      unitvar=paramcd;
      unit=avalc;
      output &prefix._adpc5_unit;
    end;
    else if indexw("&adamparmvals.",trim(paramcd)) then do;
      unitvar=put(paramcd,$unitvars.);
      output &prefix._adpc5_res;
    end;
  run;

  /* Merge units back onto other data and generate PARAM */
  proc sort data=&prefix._adpc5_res;
    by &foundKeys1 &foundKeys2 unitvar;
  run;
  proc sort data=&prefix._adpc5_unit;
    by &foundKeys1 &foundKeys2 unitvar;
  run;

  data &prefix._adpc6;
    merge &prefix._adpc5_res(in=a) &prefix._adpc5_unit;
    attrib PARAM length=$200;
    length pcuaeu $ 20;
    by &foundKeys1 &foundKeys2 unitvar;
    pcuaeu=scan(pcstresu,1);
    PARAM=trim(left(put(paramcd,$adamlbl.)));
    if a;
  run;

  /* AJC002: Retrieve the sample volume, weight and pH records and add them to the normalised concentration results. */
  data &prefix._adpc6_pksmp (keep=&foundKeys1 &foundKeys2 paramcd param avalc unit);
    set &prefix._adpc4;
    where (upcase(pctestcd) in ("PKSMPPH" "PKSMPVOL" "PKSMPWT"));
    /* AJC002: Intentionally increase length of PARAMCD for the next data steps. Final length is set by tu_attrib. */
    length paramcd $10 param $200 avalc $200 unit $20;
    paramcd=compress("PC"||substr(pctestcd,6));
    PARAM=trim(left(put(paramcd,$adamlbl.)));
    avalc=pcstresc;
    unit=pcstresu;
  run;

  data &prefix._adpc6_all;
    set &prefix._adpc6_pksmp &prefix._adpc6;
  run;

  %let currentDataset = &prefix._adpc6_all;

/*** Augment/modify PARAM and PARAMCD using PCSPEC and PCTESTCD to make them unique,                  ***/
/*** derive remaining A* variables and DTYPE  and subset parameters in accordance with specimen type  ***/

  data &prefix._adpc7;
    set &currentDataset;
    attrib DTYPE format=$8.;

    AENDTM  = dhms(AENDT,hour(AENTM),minute(AENTM),second(AENTM));
    /* AJC001: Use tu_chkvarsexist to check if source variables exist */
    %if %length(%tu_chkvarsexist(&currentDataset,PCTPTNUM)) eq 0 %then
      ATPTN   = PCTPTNUM;; /* ATPTN is a duplicate of PCTPTNUM, initially */
    %if %length(%tu_chkvarsexist(&currentDataset,PCTPT)) eq 0 %then
      ATPT    = PCTPT;;    /* ATPT is a duplicate of PCTPT, initially */
    %if %length(%tu_chkvarsexist(&currentDataset,PCTPTREF)) eq 0 %then
      ATPTREF = PCTPTREF;; /* ATPTREF is a duplicate of PCTPTREF */
    if areltm eq . then areltmu = "";
    if asttmdv eq . then asttmdvu = "";
    if awnlrt eq . then awnlrtu = "";

    if trim(paramcd) in ("PCSTRESC" "PCSTIMPN" "PCSTIMSN" "PCLLQN" "PCUAE" "PCUER" "PCVOL" "PCWNLN") 
      then AVAL=input(strip(avalc),??best.);
    avalc=strip(avalc);

    if paramcd in ("PCSTIMPN" "PCSTIMSN" "PCWNLN") and pcstresn eq . and aval ne . then dtype="IMPUTED";

    /* AJC001: upcase pcspec for comparison */
    if upcase(pcspec) eq "URINE" then do;
      if trim(paramcd) in ("PCSTIMPN" "PCSTIMSN" "PCWNLN") then delete;
    end;
    else do;
      if trim(paramcd) in ("PCALLCOL" "PCDUR" "PCUAE" "PCUER" "PCVOL" "PCATMEN" "PCENTMDV" "PCPTMEN") then delete;
    end;

    /* AJC002: For Plasma concentration results, derive PARAMCD as PxxxxRESC, PxxxxIMPN, PxxxxIMSN or PxxxxWNLN for now */
    if upcase(pcspec) ne 'URINE' then do;
      if paramcd eq 'PCWNLN' then
        paramcd=cat(substr(pcspec,1,1),compress(pctestcd,,"kd"),substr(paramcd,3));
      else 
        paramcd=cat(substr(pcspec,1,1),compress(pctestcd,,"kd"),substr(paramcd,5));
    end;

    /* AJC002: For Urine concentration results, derive PARAMCD as UxxxxRES */ 
    else if paramcd='PCSTRESC' then paramcd=cat(substr(pcspec,1,1),compress(pctestcd,,"kd"),substr(paramcd,5,3));
    /* AJC002: For Urine sample measurements, derive PARAMCD as USMPVOL, USMPWT, USMPPH */
    else if paramcd in ('PCVOL' 'PCWT' 'PCPH') then paramcd=cat(substr(pcspec,1,1),'SMP',substr(paramcd,3));
    /* AJC002: For Urine derived parameters, derive PARAMCD as UxxxxUAE, UxxxxUER */ 
    else paramcd=cat(substr(pcspec,1,1),compress(pctestcd,,"kd"),substr(paramcd,3));

    /* AJC002: Correct PARAM derivation for volume, weight and pH observations */
    if substr(paramcd,2,3) eq 'SMP' then param=cat(trim(pcspec),": ",param);
    else param=cat(trim(pcspec),": ",trim(pctest),": ",param);
    if index(param,'Amount excreted') gt 0 and pcuaeu^='' then param=trim(left(param))||' ('||trim(left(pcuaeu))||')';
    else if unit^='' then param=trim(left(param))||' ('||trim(left(unit))||')';
    else if pcstresu^='' then param=trim(left(param))||' ('||trim(left(pcstresu))||')';

    /* AJC002: removed code that set PCSTRESC to missing for certain sample results */

    drop pcuaeu unitvar unit; /* AJC002: Drop temporary variables */
  run;
  %let currentDataset = &prefix._adpc7;


  /* AJC002: Removed redundant datastep &prefix._adpc8 */


  /* Combine PK records for PARAMCD=PxxxxIMPN, PxxxxIMSN, and PxxxxWNLN and create ANL01FL, ANL02FL, and ANL03FL flags */

  /* First subset out any non-PK blood/plasma data */
  data &prefix._adpc8_nonpk &prefix._adpc8_pk;
    set &currentDataset;
    /* AJC002: Modify subsetting so all analytes are considered */
    if upcase(compress(paramcd,,"d")) in ('PRESC' 'PIMPN' 'PIMSN' 'PWNLN') then output &prefix._adpc8_pk;
    else output &prefix._adpc8_nonpk;
  run;

  proc sort data=&prefix._adpc8_pk;
    by &g_subjid pctestcd pcseq dtype;
  run;

  data &prefix._adpc8_pk1;
    set &prefix._adpc8_pk;
    by &g_subjid pctestcd pcseq dtype;
    /* AJC002: Derive a temporary version of PARAMCD to make the flagging code work for all analytes */
    _paramcd=compress(paramcd,,"d");
    _paramcd=cat(substr(_paramcd,1,1),"1",substr(_paramcd,2));
  run;

  proc sort data=&prefix._adpc8_pk1;
    by &g_subjid pctestcd pcseq dtype;
  run;

/* Transpose to separate P1RESC, P1IMPN, P1IMSN, P1WNLN */
  proc transpose out=&prefix._adpc8_pk2;
    by &g_subjid pctestcd pcseq dtype;
    var avalc;
    id _paramcd;
  run;

/* Set cntr variable to determine if there is more than one observation per timepoint (i.e. check for imputed records) */
  data &prefix._adpc8_pk3;
    set &prefix._adpc8_pk2;
    by &g_subjid pctestcd pcseq dtype;
    retain cntr;
    if first.pcseq then cntr=0;
    cntr+1;
  run;

  proc sort data=&prefix._adpc8_pk3;
    by &g_subjid pctestcd pcseq descending cntr;
  run;

/* Derive anl01fl (P1IMPN), anl02fl (P1IMSN), and anl03fl (P1WNLN) flags */
  data &prefix._adpc8_pk4;
    set &prefix._adpc8_pk3;
    by &g_subjid pctestcd pcseq descending cntr;
    length anl01fl anl02fl anl03fl $ 1 avalc $ 120;
    retain flg1 flg2 flg3;
    /* flg1, flg2, and flg3 variables will be used to remember if an imputed value is already being used for the timepoint */
    if first.pcseq then do;
      flg1=0;
      flg2=0;
      flg3=0;
    end;
    /* If there is only one observation per timepoint (no imputed observations) */
    if cntr=1 and first.pcseq then do;
      /* Derive anl01fl flag and see if 02 and 03 flags can also be used on the same observation */
      if P1IMPN=input(P1RESC,?? best.) and p1impn^=. then anl01fl='Y';
      if P1IMPN=P1IMSN and p1impn^=. then anl02fl='Y';
      if P1IMPN=P1WNLN and p1impn^=. then anl03fl='Y';
      avalc=p1impn;
      if avalc ne '' then output;
      /* Derive anl02fl flag if it has not been derived already */
      if P1IMSN=input(P1RESC,?? best.) and P1IMSN^=P1IMPN then do;
        anl01fl=' ';
        anl02fl='Y';
        /* Determine if 03 flag can be used on the same observation */
        if P1IMSN=P1WNLN and p1imsn^=. then anl03fl='Y';
        else anl03fl=' ';
        avalc=p1imsn;
        output;
      end;
      /* Derive anl02fl flag if it has not been derived already */
      if P1WNLN=input(P1RESC,?? best.) and P1WNLN^=P1IMPN and P1WNLN^=P1IMSN and p1wnln^=. then do;
        anl01fl=' ';
        anl02fl=' ';
        anl03fl='Y';
        avalc=p1wnln;
        output;
      end;
      /* If none of the values = P1RESC then set all flags to missing */
      if input(P1RESC,?? best.)^=P1IMPN and input(P1RESC,?? best.)^=P1IMSN and input(P1RESC,?? best.)^=P1WNLN then do;
        anl01fl=' ';
        anl02fl=' ';
        anl03fl=' ';
        avalc=p1resc;
        output;
      end;
      else if P1RESC^='' and P1IMPN=. and P1IMSN=. and P1WNLN=. then do;
        anl01fl=' ';
        anl02fl=' ';
        anl03fl=' ';
        avalc=p1resc;
        output;
      end;
    end;
    /* If there is more than one observation per timepoint (imputed timepoints) */
    else do;
      /* cntr^1 subsets out the non-imputed observations at timepoints where imputations were done */
      if cntr^=1 then do;
        /* If P1IMPN^=P1RESC means P1IMPN was imputed */
        if P1IMPN^=input(P1RESC,?? best.) then anl01fl='Y';
        /* See if 02 and 03 flags can be used on the same observation */
        if P1IMPN^=input(P1RESC,?? best.) and P1IMPN=P1IMSN then anl02fl='Y';
        if P1IMPN^=input(P1RESC,?? best.) and P1IMPN=P1WNLN then anl03fl='Y';
        if anl01fl='Y' then flg1=1;
        if anl02fl='Y' then flg2=1;
        if anl03fl='Y' then flg3=1;
        avalc=p1impn;
        output;
        /* If P1IMSN^=P1RESC means P1IMSN was imputed.  Also check to ensure 02 flag has not already been created */
        if P1IMSN^=P1IMPN and P1IMSN^=input(P1RESC,?? best.) then do;
          anl01fl=' ';
          anl02fl='Y';
          /* See if 03 flag can be used on the same observation */
          if P1IMSN=P1WNLN then anl03fl='Y';
          else anl03fl=' ';
          avalc=p1imsn;
          if anl01fl='Y' then flg1=1;
          if anl02fl='Y' then flg2=1;
          if anl03fl='Y' then flg3=1;
          output;
        end;
        /* If P1WNLN^=P1RESC means P1WNLN was imputed.  Also check to ensure 03 flag has not already been created */
        if P1WNLN^=P1IMPN and P1WNLN^=P1IMSN and P1WNLN^=input(P1RESC,?? best.) then do;
          anl01fl=' ';
          anl02fl=' ';
          anl03fl='Y';
          avalc=p1wnln;
          if anl01fl='Y' then flg1=1;
          if anl02fl='Y' then flg2=1;
          if anl03fl='Y' then flg3=1;
          output;
        end;
      end;
      /* If it is an imputed timepoint and this is the non-imputed observation, determine which flags have not already
         been used.  For those flags, check that the values are equal to the raw value.  If so, set flag to Y.
         This is for situations where one derivation (i.e. P1IMPN) is imputed but another one (i.e. P1WNLN) is not
         imputed */
      /* AJC002: Modified to check for non-missing imputed values before setting flag, e.g. for trailing NQ scenario */
      if cntr=1 then do;
        if P1IMPN=input(P1RESC,?? best.) and P1IMPN ne . and flg1=0 then anl01fl='Y';
        if P1IMSN=input(P1RESC,?? best.) and P1IMSN ne . and flg2=0 then anl02fl='Y';
        if P1WNLN=input(P1RESC,?? best.) and P1WNLN ne . and flg3=0 then anl03fl='Y';
        avalc=p1resc;
        output;
      end;
    end;
  run;

  /* Merge new flagged dataset back with PK observations */
  /* AJC002: Create an output dataset from the proc sort to aid debugging */
  proc sort data=&prefix._adpc8_pk4 out=&prefix._adpc8_pk4_flags (keep=&g_subjid pctestcd pcseq dtype anl01fl anl02fl anl03fl avalc);
    by &g_subjid pctestcd pcseq dtype;
  run;

  /* AJC002: Create an output dataset from the proc sort nodupkey to aid debugging */
  proc sort data=&prefix._adpc8_pk1 (drop=avalc _paramcd) out=&prefix._adpc8_pk1_uniq nodupkey;
    by &g_subjid pctestcd pcseq dtype;
  run;

  data &prefix._adpc8_pk5;
    merge &prefix._adpc8_pk1_uniq &prefix._adpc8_pk4_flags;
    by &g_subjid pctestcd pcseq dtype;
    aval=input(avalc,?? best.);
  run;

  /* In case of missing units, keep only last observation to put units in PARAM value */
  proc sort data=&prefix._adpc8_pk5 out=&prefix._adpc8_pk6 (keep=pctestcd pcstresu) nodupkey;
    by pctestcd pcstresu;
  run;

  data &prefix._adpc8_pk7 (rename=(pcstresu=pcstresu1));
    set &prefix._adpc8_pk6;
    by pctestcd pcstresu;
    if last.pctestcd;
  run;

  proc sort data=&prefix._adpc8_pk5;
    by pctestcd;
  run;

  data &prefix._adpc8_pk9;
    merge &prefix._adpc8_pk7 &prefix._adpc8_pk5;
    by pctestcd;
  run;

  data &prefix._adpc8_pk10;
    set &prefix._adpc8_pk9;
    /* AJC002: derive final PLasma concentration PARAMCD as PxxxxRES */
    paramcd=cat(substr(paramcd,1,1), compress(paramcd,,"kd"), 'RES');
    if pcstresu ne '' then param=cat(trim(pcspec),": ",trim(pctest),": Concentration (",trim(left(PCSTRESU)),")");
    else param=cat(trim(pcspec),": ",trim(pctest),": Concentration (",trim(left(PCSTRESU1)),")");
    drop pcstresu1; /* AJC002: Drop temporary variables */
  run;

  proc sort data=&prefix._adpc8_pk10;
    by &g_subjid pcrefid;
  run;

  /* AJC002: Removed redundant datastep &prefix._adpc8_pk11 */

  data &prefix._adpc8_nonpk1;
    set &prefix._adpc8_nonpk;
    length ANL01FL ANL02FL ANL03FL $ 1;
    if (aval ne . or avalc ne '') and index(upcase(paramcd),'UER') gt 0 then do;
      anl01fl='Y';
      anl02fl='Y';
      anl03fl='Y';
    end;
  run;

  /* Set together with full PK dataset including non-blood/plasma data */
  data &prefix._adpc9;
    set &prefix._adpc8_pk10 &prefix._adpc8_nonpk1;
  run;

  %let currentDataset = &prefix._adpc9;

/*** Add treatment and period information ***/
/* Calling tu_adgetadslvars to fetch specified variables from the ADSL/ADTRT dataset, if getadslvarsyn parameter is Y */

  %if &getadslvarsyn=Y %then
  %do;
    %tu_adgetadslvars(dsetin=&currentDataset,
                      adsldset=&dsetinadsl.,
                      adslvars=&adslvars.,
                      dsetout=&prefix._adslout
                     );

    %let currentDataset=&prefix._adslout;
  %end;


  /* Calling tu_advisit to derive AVISIT and AVISITN - Reassign unscheduled visits */

  %if &advisityn=Y %then
  %do; /* AJC001: remove upcase function */
    %tu_advisit(dsetin=&currentDataset,
                 dsetout=&prefix._visit,
                 avisitfmt=&advisitfmt,
                 avisitnfmt=&advisitnfmt
                );

    %let currentDataset=&prefix._visit;
  %end;

  /* Calling tu_adperiod to bring in either APERIOD/APERIODC or TPERIOD/TPERIODC from ADTRT dataset */

  %if &adperiodyn=Y %then
  %do; /* AJC001: remove upcase function */
    %tu_adperiod(dsetin=&currentDataset,
                 dsetout=&prefix._period,
                 eventtype=PL
                );

    %let currentDataset=&prefix._period;
  %end;

  %if &adgettrtyn eq Y %then %do;
    %tu_adgettrt(dsetin     = &currentDataset,
                 dsetinadsl=&dsetinadsl.,
                 mergevars=&adgettrtmergevars.,
                 trtvars=&adgettrtvars.,
                 dsetout    = &prefix._adpc10);

    %let currentDataset = &prefix._adpc10;
  %end;

  data &prefix._adpc11;
    set &currentDataset;
      adt=astdt;
      atm=asttm;
      adtm=astdtm;

      /* Ensure AVALC and AVAL are not both populated */
      if aval ne . then avalc='';
      if avalc='NQ' and pclloq ne . then avalc=trim(left(avalc))||' (<'||trim(left(input(pclloq,?? best.)))||')';
  run;
  %let currentDataset = &prefix._adpc11;

  /* Calling tu_adreldays to derive relative days ADY, ASTDY, AENDY */

  %if &adreldaysyn=Y %then
  %do;
    %tu_adreldays(dsetin=&currentDataset,
                  dsetout=&prefix._adpc12,
                  dyrefdatevar=&dyrefdatevar,
                  domaincode=&domain
                 );

    %let currentDataset=&prefix._adpc12;
  %end;

  /* Calling tu_decode to derive codes or decodes using formats specified in &g_dsplanfile */

  %if &decodeyn eq Y %then
  %do;
    %tu_decode (dsetin = &currentDataset,
                dsetout= &prefix._adpc13,
                codepairs=&codepairs,
                decodepairs=&decodepairs,
                dsplan=&g_dsplanfile
               );
    %let currentDataset=&prefix._adpc13;
  %end;

  /*** Create DSETOUT ***/

  data &dsetout;
    set &currentDataset;
    /* AJC002: remove redundant paramcd subsetting */
    if avalc ne '' or aval ne .
      %if %length(%tu_chkvarsexist(&currentDataset,PCSTAT))=0 %then or pcstat ne '';
      %if %length(%tu_chkvarsexist(&currentDataset,PCREASND))=0 %then or pcreasnd ne '';
      ;
    %if %length(&postprocess) gt 0 %then %do;
      &postprocess.;
    %end;
  run;

  /*** Check PARAMCD and PARAM are 1:1 ***/

  proc sql noprint;
    create table &prefix._param_unique as
    select param, count(distinct paramcd) as paramcd_ct
    from &dsetout
    group by param;
    create table &prefix._paramcd_unique as
    select paramcd, count(distinct param) as param_ct
    from &dsetout
    group by paramcd;
  quit;
  data _null_;
    set &prefix._param_unique &prefix._paramcd_unique;
    if paramcd_ct gt 1 then 
      put "RTW" "ARNING: &sysmacroname: There are more than one value of PARAMCD for PARAM=" param ".";
    if param_ct gt 1 then 
      put "RTW" "ARNING: &sysmacroname: There are more than one value of PARAM for PARAMCD=" paramcd ".";
  run;

/*** Set attributes if required ***/
  %if &attributesyn eq Y %then %do;
    %tu_attrib(dsetin=&dsetout
              ,dsetout=&dsetout
              ,dsplan=&g_dsplanfile
              );
  %end;

/*** Check for variables with all values missing, and values of PARAMCD with no values ***/

  %if &misschkyn eq Y %then %do;
    proc sql noprint;
      create table &prefix._null_params as
      select distinct paramcd, case when avalc eq '' and aval=. then 'Y' else 'N' end as blank, count(*) as count
      from &dsetout
      group by paramcd, blank;
    quit;
    proc transpose data=&prefix._null_params out=&prefix._null_trans;
      var count;
	by paramcd;
      id blank;
    run;

    data _null_;
      set &prefix._null_trans;
	where n le 0;
      put "RTW" "ARNING: &sysmacroname: All records for PARAMCD=" paramcd " have missing values of AVAL/AVALC.";
    run;

    %tu_misschk(dsetin=&dsetout);
  %end;
  
/*** Tidy up temporary datasets ***/

  %tu_tidyup(rmdset=&prefix:
            ,glbmac=NONE
            );

  %tu_abort;

%mend tc_adpc;
