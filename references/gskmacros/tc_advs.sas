/******************************************************************************* 
| Program Name: tc_advs
|
| Program Version: 1.0
|
| HARP Compound/Study/Reporting Effort: 
|
| Program Purpose: To create the ADaM dataset of ADVS domain using the SDTM VS
|                  and supplemental VSSUPP datasets.
|
| SAS Version: SAS v9.1.3
|
| Created By: David Ainsworth (daa62284)
| Date:       10NOV2014
|
|******************************************************************************* 
|
| Output: adamdata.ADVS
|
|
|
| Nested Macros: 
| (@) tu_adsuppjoin
| (@) tu_adbaseln
| (@) tu_adchgccfg
| (@) tu_addatetime
| (@) tu_adgetadslvars
| (@) tu_adgettrt
| (@) tu_attrib
| (@) tu_advisit
| (@) tu_adperiod
| (@) tu_adreldays
| (@) tu_chknames
| (@) tu_chkvarsexist
| (@) tu_decode
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_misschk
| (@) tu_nobs   
| (@) tu_abort  
| (@) tu_tidyup
|
| Metadata:
|
|
|******************************************************************************* 
| Change Log 
|
| Modified By: 
| Date of Modification: 
|
| Modification ID: 
| Reason For Modification: 
|
********************************************************************************/ 
%macro tc_advs(dsetin=sdtmdata.vs,                     /* Input dataset */
               dsetout=adamdata.advs,                    /* Output dataset to be created*/
               adsuppjoinyn=N,              /* If supplemental dataset is required to be joined with parent domain Y/N */
               dsetinsupp=,                 /* Input supplemental dataset */
               addatetimeyn=Y,              /* Flag to indicate if If tu_addatetime utility is to be executed Y/N */
               datevars=vsdtc,              /* Datetime variables in input dataset to be converted to numeric dates times datetimes*/
               getadslvarsyn=Y,             /* Flag to indicate if tu_adgetadslvars utility need to be called */
               dsetinadsl = adamdata.adsl,  /* Input ADSL or ADTRT dataset */          
               adslvars=siteid age sex race acountry trtsdt trtedt trtseq: fasfl ittfl saffl pprotfl, /* List of variable from DSETINADSL dataset for tu_adgetadslvars utility to merge on by USUBJID*/
               adgettrtyn=Y,               /* Flag to indicate if tu_adgettrt utility is to be executed Y/N */
               adgettrtmergevars=USUBJID,  /* Variables used to merge treatment information from DSETINADSL onto work dataset */
               adgettrtvars=trt01p trt01pn trt01a trt01an, /* List of variables from treatment dataset DSETINADSL for tu_adgettrt utility to add to work dataset */
               decodeyn=N,                /* Flag to indicate if tu_decode utility is to be executed Y/N */
               decodepairs=,               /* A list of paired code/decode variables for which the decode is to be created*/ 
               codepairs=,                 /* A list of paired code/decode variables for which the code is to be created*/
               adreldaysyn=Y,              /* Flag to indicate if tu_adreldays utility is to be executed*/
               dyrefdatevar=,              /* Reference date variable for analysis relative days derivation: ADY, ASTDY, AENDY*/
               advisityn = Y,               /* Flag to indicate if tu_adreldays utility is to be executed Y/N */
               avisitnfmt =,               /* Format used to derive AVISITN from VISITNUM*/
               avisitfmt = ,               /* Format used to derive AVISIT from VISIT*/ 
               adperiodyn= N,              /* Flag to indicate if tu_adperiod utility is to be executed Y/N */
               misschkyn=Y,                 /* Flag to indicate if tu_misschk utility is to be executed Y/N */
               attributesyn=Y,              /* Flag to indicate if tu_attrib utility is to be executed Y/N */
               paramcdmappingdset=DICTION.ADVSPARM, /* Dataset for mapping PARAMCD from VSTESTCD and qualifiers */
               flaggingsubset= ,            /* IF clause to identify records to be flagged */
               adbaselnyn=Y,                /* Flag to indicate if tu_adbaseln utility is to be executed Y/N */
               rederivebaselineyn = N,      /* Flag to indicate if baseline is to be re-derived, otherwise use SDTM baseline flag */
               baselineoption= DATE,        /* Calculation of baseline option: date, time, relday, visit, tpt or visittpt */
               reldays= ,                   /* Number of days prior to start of study medication */
               startvisnum= ,               /* VISITNUM and/or ATPTN value for start of baseline range */
               endvisnum= ,                 /* VISITNUM and/or ATPTN value for end of baseline range */
               baselinetype= LAST,          /* How to calculate baseline for multiple baseline records: first, last, mean or median */
               derivedbaselinerowinfo = ,   /* SAS statement(s) to define visit/timepoint variables on derived baseline observations (baselinetype of mean or median) */
               adchgfgyn=Y,                 /* Flag to indicate if tu_adchgccfg utility is to be executed Change from Baseline (CH/CHG) Y/N */
               adccfgyn=Y,                  /* Flag to indicate if tu_adchgccfg utility is to be executed Clinical Concern (CC) Y/N */
               cpdsrng= ,                   /* Clinical Pharmacolog Range identifier */
               critdset= ,                  /* Flagging criteria dataset name */
               dgcd= ,                      /* Compound identifier */ 
               studyid=                     /* Study identifier */
               );


  /*
  / Echo parameter values and global macro variables to the log.
  /----------------------------------------------------------------------------*/

  %local MacroVersion;
  %let MacroVersion = 1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_dsplanfile g_abort g_refdata);

  /*
  /  Set up local macro variables
  / ---------------------------------------------------------------------------*/

  %local prefix lastdset domain mergevars word_cnt i;
  %let prefix = advs;
  %let domain=VS;

  /*
  / PARAMETER VALIDATION
  /----------------------------------------------------------------------------*/

  %let dsetin            = %nrbquote(&dsetin.);
  %let dsetout           = %nrbquote(&dsetout.);
  %let adsuppjoinyn      = %nrbquote(%upcase(&adsuppjoinyn.));
  %let addatetimeyn      = %nrbquote(%upcase(&addatetimeyn.));
  %let getadslvarsyn     = %nrbquote(%upcase(&getadslvarsyn.));
  %let adgettrtyn        = %nrbquote(%upcase(&adgettrtyn.));
  %let advisityn         = %nrbquote(%upcase(&advisityn.));
  %let adperiodyn        = %nrbquote(%upcase(&adperiodyn.));
  %let adreldaysyn       = %nrbquote(%upcase(&adreldaysyn.));
  %let decodeyn          = %nrbquote(%upcase(&decodeyn.));
  %let attributesyn      = %nrbquote(%upcase(&attributesyn.));
  %let misschkyn         = %nrbquote(%upcase(&misschkyn.));
  %let paramcdmappingdset = %nrbquote(%upcase(&paramcdmappingdset.));
  %let flaggingsubset  = %nrbquote(&flaggingsubset);
  %let adbaselnyn         = %nrbquote(%upcase(&adbaselnyn.));
  %let adchgfgyn         = %nrbquote(%upcase(&adchgfgyn.));
  %let adccfgyn         = %nrbquote(%upcase(&adccfgyn.));


  /* Validating if non-missing values are provided for parameters DSETIN and DSETOUT */
  %if &dsetin. eq %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETIN is a required parameter, provide a dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &dsetout. eq %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETOUT is a required parameter, provide a dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;


  /* calling tu_chknames to validate name provided in DSETIN parameter */
  %if %tu_chknames(%scan(&dsetin, 1, %str(%() ), DATA ) ne %then %do;
     %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETIN refers to dataset &dsetin which is not a valid dataset name;
     %let g_abort = 1;
     %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;


  /* Validating if DSETIN dataset exists */
  %if %SYSFUNC(EXIST(%scan(&dsetin, 1, %str(%() ) )) NE 1 %then %do;
     %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETIN refers to dataset %upcase("&dsetin.") which does not exist.;
     %let g_abort = 1;
     %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;


  /* Validating if DSETOUT is a valid dataset name and DSETOUT is not same as DSETIN */
  %if %qupcase(&dsetout.) eq %qupcase(%scan(&dsetin, 1, %str(%() )) %then                
/*update to only look at dataset component only*/ %do;
    %put RTE%str(RROR:) &sysmacroname.: The Output dataset name is same as Input dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
  /* calling tu_chknames to validate name provided in DSETOUT parameter */
  %else %if %tu_chknames(&dsetout., DATA) ne %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETOUT refers to dataset %nrbquote(%upcase("&dsetout.")) which is not a valid dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Validating ADSUPPJOINYN, ADDATETIMEYN, GETADSLVARSYN, ADGETTRTYN, ADVISITYN, ADPERIODYN, ADRELDAYSYN, DECODEYN, ATTRIBUTESYN, MISSCHKYN parameters */
  %if &adsuppjoinyn. ne Y and &adsuppjoinyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ADSUPPJOINYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &addatetimeyn. ne Y and &addatetimeyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ADDATETIMEYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &getadslvarsyn. ne Y and &getadslvarsyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter GETADSLVARSYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &adgettrtyn. ne Y and &adgettrtyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ADGETTRTYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

    %if &advisityn. ne Y and &advisityn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter AVISITYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

    %if &adperiodyn. ne Y and &adperiodyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ADPERIODYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

    %if &adreldaysyn. ne Y and &adreldaysyn. ne N %then
  %do;  
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ADRELDAYSYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &decodeyn. ne Y and &decodeyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DECODEYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &attributesyn. ne Y and &attributesyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ATTRIBUTESYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &misschkyn. ne Y and &misschkyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter MISSCHKYN should either be Y or N.; 
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Validating if non-missing values are provided for parameter PARAMCDMAPPINGDSET */
  %if &paramcdmappingdset=%str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter PARAMCDMAPPINGDSET is a required parameter, provide a dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;

      /* Aborting the execution */
      %if &g_abort eq 1 %then
      %do;
        %tu_abort;
      %end;
  %end;

  /* calling tu_chknames to validate name provided in PARAMCDMAPPINGDSET parameter */
  %if %tu_chknames(%scan(&paramcdmappingdset, 1, %str(%() ), DATA ) ne %then 
  %do;
     %put RTE%str(RROR:) &sysmacroname.: Macro Parameter PARAMCDMAPPINGDSET refers to dataset &paramcdmappingdset which is not a valid dataset name;
     %let g_abort = 1;
     %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;

       /* Aborting the execution */
      %if &g_abort eq 1 %then
      %do;
        %tu_abort;
      %end;
  %end;

  /* Validating if PARAMCDMAPPINGDSET dataset exists */

  %if %SYSFUNC(EXIST(%scan(&paramcdmappingdset, 1, %str(%() ) )) NE 1 %then %do;
     %put RTE%str(RROR:) &sysmacroname.: Macro Parameter PARAMCDMAPPINGDSET refers to dataset %upcase("&paramcdmappingdset.") which does not exist.;
     %let g_abort = 1;
     %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Validating ADBASELNYN, ADCHGFGYN, ADCCFGYN parameters */

  %if &adbaselnyn. ne Y and &adbaselnyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ADBASELNYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &adchgfgyn. ne Y and &adchgfgyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ADCHGFGYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &adccfgyn. ne Y and &adccfgyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ADCCFGYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;


  /* Create work dataset if DSETIN contains dataset options */

  %if %index(&dsetin,%str(%() ) gt 0 %then 
  %do;
    data  &prefix._dsetin;
    set %unquote(&dsetin.);
    run;
    %let lastdset=&prefix._dsetin;
  %end; %else 
  %do;
    %let lastdset=&dsetin;
  %end;


  /*
  / Main Processing starts here.
  / ---------------------------------------------------------------------------*/

  /* Calling tu_adsuppjoin to merge supplemental dataset with parent domain dataset, if adsuppjoinyn parameter is Y */
  %if %upcase(&adsuppjoinyn) eq Y %then
  %do;
    %tu_adsuppjoin(dsetin = &lastdset.,
                   dsetinsupp = &dsetinsupp.,
                   dsetout = &prefix._supp
                  );

    %let lastdset=&prefix._supp;
  %end;


  /* Calling tu_addatetime to convert character date to numeric date, time and datetime, if addatetimeyn parameter is Y */
  %if %upcase(&addatetimeyn) eq Y %then
  %do;
    %tu_addatetime(dsetin = &lastdset.,
                   dsetout = &prefix._date,
                   datevars = &datevars.
                  );

    /* Deriving event dates to ADaM variable naming conventions */
    
    
    data &prefix._daterename;
    set &prefix._date;
    %if %tu_chkvarsexist(&prefix._date, &domain.DT)=%str() %then ADT=&domain.DT; ;
    %if %tu_chkvarsexist(&prefix._date, &domain.TM)=%str() %then ATM=&domain.TM; ;
    %if %tu_chkvarsexist(&prefix._date, &domain.DTM)=%str() %then ADTM=&domain.DTM; ;
    %if %tu_chkvarsexist(&prefix._date, &domain.STDT)=%str() %then ASTDT=&domain.STDT; ;
    %if %tu_chkvarsexist(&prefix._date, &domain.STTM)=%str() %then ASTTM=&domain.STTM; ;
    %if %tu_chkvarsexist(&prefix._date, &domain.STDTM)=%str() %then ASTDTM=&domain.STDTM; ;
    %if %tu_chkvarsexist(&prefix._date, &domain.ENDT)=%str() %then AENDT=&domain.ENDT; ;
    %if %tu_chkvarsexist(&prefix._date, &domain.ENTM)=%str() %then AENTM=&domain.ENTM; ;
    %if %tu_chkvarsexist(&prefix._date, &domain.ENDTM)=%str() %then AENDTM=&domain.ENDTM; ;
    run;
    
    %let lastdset=&prefix._daterename;

%end;


  /* Calling tu_adgetadslvars to fetch specified variables from the ADSL/ADTRT dataset, if getadslvarsyn parameter is Y */
  %if &getadslvarsyn=Y %then
  %do;
    %tu_adgetadslvars(dsetin = &lastdset.,
                      adsldset = &dsetinadsl.,
                      adslvars = &adslvars.,
                      dsetout = &prefix._adslout
                      );

    %let lastdset=&prefix._adslout;
  %end;



  /* Calling tu_advisit to derive AVISIT and AVISITN - Reassign unscheduled visits */

  %if %upcase(&advisityn)=Y %then
  %do;
    %tu_advisit(dsetin = &lastdset.,
                dsetout = &prefix._visit,
                avisitfmt=&avisitfmt,
                avisitnfmt=&avisitnfmt
                );

    %let lastdset=&prefix._visit;
  %end;


  /* Calling tu_adperiod to bring in either APERIOD/APERIODC or TPERIOD/TPERIODC from ADTRT dataset */

  %if %upcase(&adperiodyn)=Y %then
  %do;
    %tu_adperiod(dsetin = &lastdset.,
                 dsetout = &prefix._period,
                 eventtype= PL
                 );

    %let lastdset=&prefix._period;
  %end;


  /* Calling tu_adgettrt to assign treatment variables to records also bring in selected "other" variables from adtrt such as period trt start stop etc*/

  %if %upcase(&adgettrtyn)=Y %then
  %do;
    %tu_adgettrt(dsetin = &lastdset.,
                 dsetinadsl = &dsetinadsl.,
                 mergevars = &adgettrtmergevars.,
                 trtvars = &adgettrtvars.,
                 dsetout = &prefix._trt
                );

    %let lastdset=&prefix._trt;
  %end;


  /* Calling tu_adreldays to derive relative days ADY, ASTDY, AENDY */

  %if %upcase(&adreldaysyn)=Y %then
  %do;
  %tu_adreldays(dsetin=&lastdset.,
               dsetout=&prefix._reldays,
               dyrefdatevar=&dyrefdatevar,
               domaincode=&domain
               );

    %let lastdset=&prefix._reldays;
  %end;


  /*Domain specific derivations*/
    
   
  data &prefix._derive ;
    set &lastdset;
    %if %tu_chkvarsexist(&lastdset.,&domain.TPT)=%str() %then 
    %do; 
        if &domain.TPT ne '' then ATPT=&domain.TPT;
        else ATPT='UNSCHEDULED';
    %end;
    %if %tu_chkvarsexist(&lastdset.,&domain.TPTREF)=%str() %then ATPTREF=&domain.TPTREF;;
    %if %tu_chkvarsexist(&lastdset.,&domain.TPTNUM)=%str() %then 
    %do;
        IF &domain.tptnum = . OR atpt = 'UNSCHEDULED' THEN atptn = 999;
        ELSE IF &domain.tptnum NE . THEN ATPTN=&domain.TPTNUM;
    %end;
    %if %tu_chkvarsexist(&lastdset.,&domain.CAT)=%str() %then PARCAT1=&domain.CAT;;
    %if %tu_chkvarsexist(&lastdset.,&domain.LOC &domain.POS &domain.TEST)=%str() %then %do; PARAM=catx(' ', &domain.POS, &domain.LOC, &domain.TEST,ifc(&domain.STRESU ne '',cats('(',&domain.STRESU,')'),''));; %end;
    %else %if %tu_chkvarsexist(&lastdset.,&domain.POS &domain.TEST)=%str() %then %do; PARAM=catx(' ', &domain.POS, &domain.TEST,ifc(&domain.STRESU ne '',cats('(',&domain.STRESU,')'),''));; %end;
    %else %do; PARAM=catx(' ', propcase(&domain.TEST),ifc(&domain.STRESU ne '',cats('(',&domain.STRESU,')'),''));; %end;
    PARAMLBL=catx(' ', propcase(&domain.TEST),ifc(&domain.STRESU ne '',cats('(',&domain.STRESU,')'),''));;
    %if %tu_chkvarsexist(&lastdset.,&domain.STRESC)=%str() %then if input(&domain.STRESC,??best.) ne &domain.STRESN or &domain.STRESN=. then AVALC=&domain.STRESC;;
    %if %tu_chkvarsexist(&lastdset.,&domain.STRESN)=%str() %then AVAL=&domain.STRESN;;
    %if %tu_chkvarsexist(&lastdset.,&domain.STNRLO)=%str() %then ANRLO=&domain.STNRLO;;
    %if %tu_chkvarsexist(&lastdset.,&domain.STNRHI)=%str() %then ANRHI=&domain.STNRHI;;
    %if %tu_chkvarsexist(&lastdset.,&domain.NRIND)=%str() %then ANRIND=&domain.NRIND;;
    %if %tu_chkvarsexist(&lastdset.,domain)=%str() %then SRCDOM=domain;;
    %if %tu_chkvarsexist(&lastdset.,&domain.SEQ)=%str() %then SRCSEQ=&domain.SEQ;;
    if aval>.z then srcvar="&domain.STRESN";
        else if avalc ne '' then srcvar="&domain.STRESC";
  run;
 
  %let lastdset=&prefix._derive;
  
  
 /*
 / Add PARAMCD based on the DICTION.ADVSPARM dataset and check for missing PARAMCD
 /----------------------------------------------------------------------------*/

  %let mergevars=%tu_chkvarsexist(&lastdset., &domain.TESTCD &domain.POS &domain.LOC, Y);
  %let word_cnt=%sysfunc(countw(&mergevars));
  
  proc sort data=&paramcdmappingdset out=&prefix._parm;
    by &mergevars;
    where
      %if %tu_chkvarsexist(&lastdset., &domain.POS,Y)=%str() %then %do;
        &domain.pos='' and
      %end;
      %if %tu_chkvarsexist(&lastdset., &domain.LOC,Y)=%str() %then %do;
        &domain.loc='' and
      %end;
      1 ;
  run;

  proc sql ;
    create table &prefix._paramcd as
    select a.*, b.paramcd
    from &lastdset as a left join &prefix._parm as b
    on a.vstestcd=b.vstestcd 
          %do i=2 %to &word_cnt; 
                   and a.%scan(&mergevars,&i)=b.%scan(&mergevars,&i)
          %end; ;


    create table &prefix._paramchk as
    select distinct %do i=1 %to &word_cnt;
                       %scan(&mergevars,&i) ,
                    %end;     
                    vstest, vsstresu, paramcd, param, paramlbl
    from &prefix._paramcd
    where vstestcd ne '' and paramcd='';
  quit;

  data _null_;
    set &prefix._paramchk;
    put "RTWARN" "ING: No PARAMCD for the following rawdata"   vstestcd= vsloc= vspos= vstest= paramcd= param= paramlbl=;
  run;

  %let lastdset=&prefix._paramcd;

 
 /*
 / Split data according to &FLAGGINGSUBSET into data to be processed and
 / data to be left as is.               
 /----------------------------------------------------------------------------*/

 data &prefix._vs1 &prefix._vsu;
      set &lastdset.;

      %if &flaggingsubset ne %then
      %do;
         if %unquote(&flaggingsubset) then
            output &prefix._vs1;
         else
            output &prefix._vsu;
      %end;

      %else
      %do;
         output &prefix._vs1;
      %end;
 run;

  %let lastdset=&prefix._vs1;


 /* Calling tu_adbaseln to derive ABLFL, BASE, BASEC, BNRIND, CHG, A2INDCD, A2IND */

  %if %upcase(&adbaselnyn)=Y %then
  %do;
    %tu_adbaseln(dsetin=&lastdset.,
                dsetout=&prefix._baseln,
                rederivebaselineyn=&rederivebaselineyn,             
                baselineoption=&baselineoption,
                baselinetype=&baselinetype,
                reldays=&reldays,    
                startvisnum=&startvisnum,       
                endvisnum=&endvisnum,
                domaincode=&domain,
                derivedbaselinerowinfo=&derivedbaselinerowinfo,
                dsetinadsl         =&dsetinadsl,
                adslvars           =&adslvars,
                adgettrtmergevars  =&adgettrtmergevars,
                adgettrtvars       =&adgettrtvars
                );

     %let lastdset=&prefix._baseln;
  %end;
 
  /* Calling tu_adchgccfg to derive A2LO, A2HI, 2INDCD, A2IND - Change from Baseline */

  %if %upcase(&adchgfgyn)=Y %then
  %do;
    %tu_adchgccfg(dsetin=&lastdset.,
                 dsetout=&prefix._chg,
                 chgorcc=CHG,
                 cpdsrng=&cpdsrng,
                 dgcd=&dgcd,
                 studyid=&studyid,
                 domaincode=&domain,
                 critdset=&critdset
                 );

    %let lastdset=&prefix._chg;
  %end;
   
  /* Calling tu_adchgccfg to derive A1LO, A1HI, A1INDCD, A1IND - Clinical Concern */

  %if %upcase(&adccfgyn)=Y %then
  %do;
    %tu_adchgccfg(dsetin=&lastdset.,
                 dsetout=&prefix._cc,
                 chgorcc=CC,
                 cpdsrng=&cpdsrng,
                 dgcd=&dgcd,
                 studyid=&studyid,
                 domaincode=&domain,
                 critdset=&critdset
                 );
       
    %let lastdset=&prefix._cc;
  %end;
    
 /*
 / Add non-processed data back into processed data. These records were
 / split above based on the &FLAGGINGSUBSET parameter.
 /----------------------------------------------------------------------------*/

   data &prefix._derive1;
      set &lastdset &prefix._vsu;
   run;

  %let lastdset=&prefix._derive1;


  proc sort data=&lastdset;
      by &g_subjid adtm vsseq;
  run;


  /* Derive SHIFTxN/SHIFTx variables for post-baseline records */

   %if %tu_chkvarsexist(&lastdset.,ANRIND A2INDCD)=%str() %then %do;
    
   data &prefix._derive2;
     set &lastdset;
     length shift1n 8  shift1 $23;
     if A2INDCD not in ('P','R') then do;  
        if upcase(anrind)='NORMAL' or anrind=bnrind then do;
            shift1n=2;
            shift1='To Normal or No Change';
        end;
        else if upcase(anrind)='LOW' then do;
            shift1n=1;
            shift1='To Low';
        end;
        else if upcase(anrind)='HIGH' then do;
            shift1n=3;
            shift1='To High';
        end;
     end;
  run;

  %let lastdset=&prefix._derive2;

  %end;


  /* Derive ANL70FL/ANL71FL/ANL72FL - flag all records for SUBJID, if ANRIND/A1INDCD/A2INDCD is 'H' or 'L' */
  
  data &prefix._anl70fl(keep=&g_subjid anl70fl anl71fl anl72fl);
    set &lastdset;
    by &g_subjid;
    retain anl70fl anl71fl anl72fl;
    if first.&g_subjid then do;
        anl70fl=' ';
        anl71fl=' ';
        anl72fl=' ';
    end;

    %if %tu_chkvarsexist(&lastdset.,ANRIND)=%str() %then %do;
       if upcase(anrind) in ('HIGH', 'LOW') then anl70fl='Y';
    %end;
    %if %tu_chkvarsexist(&lastdset.,A2INDCD)=%str() %then %do;
       if a2indcd in ('H', 'L') then anl71fl='Y';
    %end;
    %if %tu_chkvarsexist(&lastdset.,A1INDCD)=%str() %then %do;
       if a1indcd in ('H', 'L') then anl72fl='Y';
    %end;

    if last.&g_subjid then output;
  run;

  data &prefix._derive3;
    merge &lastdset &prefix._anl70fl;
    by &g_subjid;
  run;

  %let lastdset=&prefix._derive3; 


  /* Calling tu_decode to derive codes or decodes using formats specified in &g_dsplanfile */

  %if %upcase(&decodeyn.) eq Y %then
  %do;
    %tu_decode (dsetin= &lastdset.,
                dsetout=&prefix._decode.,
                codepairs=&codepairs,
                decodepairs=&decodepairs,
                dsplan=&g_dsplanfile
               );
  %let lastdset=&prefix._decode;
  %end;


  /* Calling tu_attrib to apply the attributes to the variables in output dataset, if attributesyn parameter is Y. */

  %if %upcase(&attributesyn.) eq Y %then
  %do;
    %tu_attrib (dsetin = &lastdset.,
                dsetout= &dsetout.,
                dsplan = &g_dsplanfile
               );
  %end; %else 
  %do;
     data &dsetout.;
        set &lastdset.;
     run;
  %end;


  %if %tu_nobs(&dsetout) gt 0 %then %do;

    %if %upcase(&misschkyn) eq Y %then
    %do;
        %tu_misschk(dsetin=&dsetout);
    %end;

  %end;


  /* Calling tu_tidyup to delete the temporary datasets. */

  %tu_tidyup(rmdset=&prefix.:, glbmac=none);

%mend tc_advs;
