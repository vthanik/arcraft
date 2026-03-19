/******************************************************************************* 
| Program Name: tc_adeg
|
| Program Version: 2 build 2
|
| HARP Compound/Study/Reporting Effort: 
|
| Program Purpose: To create the ADaM dataset of ADEG domain using the SDTM EG
|                  and supplemental SUPPEG datasets.
|
| SAS Version: SAS V9.1.3
|
| Created By: Spencer Renyard (sr550750)
| Date:       04JUL2014
|
|******************************************************************************* 
|
| Output: adamdata.ADEG
|
|
|
| Nested Macros: 
| (@) tu_adsuppjoin
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
| (@) tu_tidyup
| (@) tu_adbaseln
| (@) tu_adchgccfg
|
| Metadata:
|
|
|******************************************************************************* 
| Change Log 
|
| Modified By:              Anthony J Cooper
| Date of Modification:     07-Apr-2017
| New version/draft number: 2 build 1
| Modification ID:          AJC001
| Reason For Modification:  1) Correct derivation of ANL71FL and ANL72FL variables
|                           to use A2INDCD and A1INDCD respectively.
|                           2) Derive AVALC from EGORRES when EGTESTCD is "INTP"
|                           so that the full interpretation is stored. Also update
|                           derivation of SRCVAR for this situation.
|
| Modified By:              Anthony J Cooper
| Date of Modification:     30-Jun-2017
| New version/draft number: 2 build 2
| Modification ID:          AJC002
| Reason For Modification:  Update call to tu_decode to remove trailing period in 
|                           DSETOUT parameter and supply value for DSPLAN.
|
********************************************************************************/ 
%macro tc_adeg(dsetin=sdtmdata.eg,         /* Input dataset */
               dsetout=adamdata.adeg,      /* Output dataset to be created*/
               adsuppjoinyn=N,             /* If supplemental dataset is required to be joined with parent domain Y/N */
               dsetinsupp=,                /* Input supplemental dataset */
               addatetimeyn=Y,             /* Flag to indicate if tu_addatetime utility is to be executed Y/N */
               datevars=egdtc,             /* Datetime variables in input dataset to be converted to numeric dates times datetimes*/
               getadslvarsyn=Y,            /* Flag to indicate if tu_adgetadslvars utility need to be called */
               dsetinadsl=adamdata.adsl,   /* Input ADSL or ADTRT dataset */          
               adslvars=siteid age sex race acountry trtsdt trtedt trtseq: fasfl ittfl saffl pprotfl, /* List of variable from DSETINADSL dataset for tu_adgetadslvars utility to merge on by USUBJID*/
               adgettrtyn=Y,               /* Flag to indicate if tu_adgettrt utility is to be executed Y/N */
               adgettrtmergevars=USUBJID,  /* Variables used to merge treatment information from DSETINADSL onto work dataset */
               adgettrtvars=trt01p trt01pn trt01a trt01an, /* List of variables from treatment dataset DSETINADSL for tu_adgettrt utility to add to work dataset */
               decodeyn=N,                 /* Flag to indicate if tu_decode utility is to be executed Y/N */
               decodepairs=,               /* A list of paired code/decode variables for which the decode is to be created*/ 
               codepairs=,                 /* A list of paired code/decode variables for which the code is to be created*/
               adreldaysyn=Y,              /* Flag to indicate if tu_adreldays utility is to be executed*/
               dyrefdatevar=,              /* Reference date variable for analysis relative days derivation: ADY, ASTDY, AENDY*/
               advisityn=Y,                /* Flag to indicate if tu_adreldays utility is to be executed Y/N */
               avisitnfmt=,                /* Format used to derive AVISITN from VISITNUM*/
               avisitfmt=,                 /* Format used to derive AVISIT from VISIT*/ 
               adperiodyn=N,               /* Flag to indicate if tu_adperiod utility is to be executed Y/N */
               paramcdmappingdset=diction.adegparm, /* Dataset containing PARAMCD mappings for EGTESTCD and qualifiers */
               misschkyn=Y,                /* Flag to indicate if tu_misschk utility is to be executed Y/N */
               attributesyn=Y,             /* Flag to indicate if tu_attrib utility is to be executed Y/N */
               adbaselnyn=Y,               /* Flag to indicate if tu_adbaseln utility is to be executed Y/N */
               rederivebaselineyn=N,       /* Flag to indicate if baseline is to be re-derived, otherwise use SDTM baseline flag */
               baselineoption=DATE,        /* Calculation of baseline option: date, time, relday, visit, tpt or visittpt */
               reldays=,                   /* Number of days prior to start of study medication */
               startvisnum=,               /* VISITNUM and/or ATPTN value for start of baseline range */
               endvisnum=,                 /* VISITNUM and/or ATPTN value for end of baseline range */
               baselinetype=LAST,          /* How to calculate baseline for multiple baseline records: first, last, mean or median */
               derivedbaselinerowinfo=,    /* SAS statement(s) to define visit/timepoint variables on derived baseline observations (baselinetype of mean or median) */
               adchgfgyn=Y,                /* Flag to indicate if tu_adchgccfg utility is to be executed Change from Baseline (CH/CHG) Y/N */
               adccfgyn=Y,                 /* Flag to indicate if tu_adchgccfg utility is to be executed Clinical Concern (CC) Y/N */
               cpdsrng=,                   /* Clinical Pharmacolog Range identifier */
               critdset=,                  /* Flagging criteria dataset name */
               dgcd=,                      /* Compound identifier */ 
               studyid=                    /* Study identifier */
               );


  /*
  / Echo parameter values and global macro variables to the log.
  /----------------------------------------------------------------------------*/

  %local MacroVersion;
  %let MacroVersion = 2 build 2;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_dsplanfile g_abort g_refdata);

  /*
  /  Set up local macro variables
  / ---------------------------------------------------------------------------*/

  %local prefix lastdset domain;
  %let prefix = adeg;
  %let domain=EG;

  /*
  / PARAMETER VALIDATION
  /----------------------------------------------------------------------------*/

  %let dsetin             = %nrbquote(&dsetin.);
  %let dsetout            = %nrbquote(&dsetout.);
  %let paramcdmappingdset = %nrbquote(&paramcdmappingdset.);
  %let adsuppjoinyn       = %nrbquote(%upcase(&adsuppjoinyn.));
  %let addatetimeyn       = %nrbquote(%upcase(&addatetimeyn.));
  %let getadslvarsyn      = %nrbquote(%upcase(&getadslvarsyn.));
  %let adgettrtyn         = %nrbquote(%upcase(&adgettrtyn.));
  %let advisityn          = %nrbquote(%upcase(&advisityn.));
  %let adperiodyn         = %nrbquote(%upcase(&adperiodyn.));
  %let adreldaysyn        = %nrbquote(%upcase(&adreldaysyn.));
  %let decodeyn           = %nrbquote(%upcase(&decodeyn.));
  %let attributesyn       = %nrbquote(%upcase(&attributesyn.));
  %let misschkyn          = %nrbquote(%upcase(&misschkyn.));
  %let adbaselnyn         = %nrbquote(%upcase(&adbaselnyn.));
  %let adchgfgyn          = %nrbquote(%upcase(&adchgfgyn.));
  %let adccfgyn           = %nrbquote(%upcase(&adccfgyn.));


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
  %do;
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

  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;

  
  /* Validating ADSUPPJOINYN, ADDATETIMEYN, GETADSLVARSYN, ADGETTRTYN, ADVISITYN, ADPERIOD, ADRELDAYSYN, DECODEYN, ADBASELNYN, ADCHGFGYN, */
  /*            ADCCFGYN, MISSCHKYN and ATTRIBUTESYN parameters  */
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


  /* Validating if non-missing value is provided for parameter PARAMCDMAPPINGDSET */
  %if &paramcdmappingdset. eq %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter PARAMCDMAPPINGDSET is a required parameter, provide a dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

    /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;

  /* calling tu_chknames to validate name provided in PARAMCDMAPPINGDSET parameter */
  %else %if %tu_chknames(&paramcdmappingdset., DATA) ne %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter PARAMCDMAPPINGDSET refers to dataset %nrbquote(%upcase("&paramcdmappingdset.")) which is not a valid dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;

  /* Validating if PARAMCDMAPPINGDSET dataset exists */
  %if %SYSFUNC(EXIST(%scan(&paramcdmappingdset, 1, %str(%() ) )) NE 1 %then %do;
     %put RTE%str(RROR:) &sysmacroname.: Macro Parameter PARAMCDMAPPINGDSET refers to dataset %upcase("&paramcdmappingdset.") which does not exist.;
     %let g_abort = 1;
     %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;


/* Create work dataset if DSETIN contains dataset options */
  %if %index(&dsetin,%str(())) gt 0 %then 
  %do;
    data &prefix._dsetin;
      set &dsetin;
    run;

    %let lastdset=&prefix._dsetin;
  %end;
  %else 
  %do;
    %let lastdset=&dsetin;
  %end;


  /*
  / Main Processing starts here.
  / ---------------------------------------------------------------------------*/

  /* Calling tu_adsuppjoin to merge supplemental dataset with parent domain dataset, if adsuppjoinyn parameter is Y */
  %if %upcase(&adsuppjoinyn) eq Y %then
  %do;
    %tu_adsuppjoin(dsetin=&lastdset.,
                   dsetinsupp=&dsetinsupp.,
                   dsetout=&prefix._supp
                  );

    %let lastdset=&prefix._supp;
  %end;


  /* Calling tu_addatetime to convert character date to numeric date, time and datetime, if addatetimeyn parameter is Y */
  %if %upcase(&addatetimeyn) eq Y %then
  %do;
    %tu_addatetime(dsetin=&lastdset.,
                   dsetout=&prefix._date,
                   datevars=&datevars.
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
    %tu_adgetadslvars(dsetin=&lastdset.,
                      adsldset=&dsetinadsl.,
                      adslvars=&adslvars.,
                      dsetout=&prefix._adslout
                     );

    %let lastdset=&prefix._adslout;
  %end;


  /* Calling tu_advisit to derive AVISIT and AVISITN - Reassign unscheduled visits */

  %if %upcase(&advisityn)=Y %then
  %do;
    %tu_advisit(dsetin=&lastdset.,
                 dsetout=&prefix._visit,
                 avisitfmt=&avisitfmt,
                 avisitnfmt=&avisitnfmt
                );

    %let lastdset=&prefix._visit;
  %end;


  /* Calling tu_adperiod to bring in either APERIOD/APERIODC or TPERIOD/TPERIODC from ADTRT dataset */

  %if %upcase(&adperiodyn)=Y %then
  %do;
    %tu_adperiod(dsetin=&lastdset.,
                 dsetout=&prefix._period,
                 eventtype=PL
                );

    %let lastdset=&prefix._period;
  %end;


  /* Calling tu_adgettrt to assign treatment variables to records also bring in selected "other" variables from adtrt such as period trt start stop etc*/

  %if %upcase(&adgettrtyn)=Y %then
  %do;
    %tu_adgettrt(dsetin=&lastdset.,
                 dsetinadsl=&dsetinadsl.,
                 mergevars=&adgettrtmergevars.,
                 trtvars=&adgettrtvars.,
                 dsetout=&prefix._trt
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


  /* Merge on paramcd mapping dataset to bring in paramcd */
  PROC SQL;
    CREATE TABLE &prefix._paramcd AS
      SELECT l.*, p.paramcd
      FROM &lastdset l LEFT JOIN &paramcdmappingdset p ON l.&domain.testcd=p.&domain.testcd;

  * Check for any EGTESTCD with a missing map to PARAMCD ;
    CREATE TABLE &prefix._misscd AS
      SELECT DISTINCT &domain.testcd, &domain.test, &domain.stresu
      FROM &prefix._paramcd
      WHERE &domain.testcd NE '' AND paramcd = ''
      ORDER BY &domain.testcd, &domain.test, &domain.stresu;
  QUIT;

  %IF &sqlobs GE 1 %THEN %DO;
    DATA _null_;
      SET &prefix._misscd;
        PUT "RTW" "ARNING: &sysmacroname.: PARAMCD mapping missing for - " &domain.testcd= &domain.test= &domain.stresu=;
    RUN;
  %END;

  %LET lastdset = &prefix._paramcd;

  /* ---------------------------------------------------------------------------- */
       
  data &prefix._derive (DROP=i);
    set &lastdset;
      %if %tu_chkvarsexist(&lastdset.,&domain.TPTREF)=%str() %then ATPTREF=&domain.TPTREF;;
      %if %tu_chkvarsexist(&lastdset.,&domain.TPT)=%str() %then %DO;
        IF &domain.TPT NE '' THEN ATPT=&domain.TPT;
        ELSE atpt = 'UNSCHEDULED';
      %END;
      %if %tu_chkvarsexist(&lastdset.,&domain.TPTNUM)=%str() %then %DO;
        IF &domain.tptnum = . OR atpt = 'UNSCHEDULED' THEN atptn = 999;
        ELSE IF &domain.tptnum NE . THEN ATPTN=&domain.TPTNUM;
      %END;
      %if %tu_chkvarsexist(&lastdset.,&domain.CAT)=%str() %then PARCAT1=&domain.CAT;;

      %IF %tu_chkvarsexist(&lastdset.,&domain.test)=%STR() %THEN %DO;
        param = CATX(' ',&domain.test,IFC(&domain.stresu NE '', CATS('(',&domain.stresu,')'),' '));
        paramlbl = CATX(' ',PROPCASE(&domain.test),IFC(&domain.stresu NE '', CATS('(',&domain.stresu,')'),' '));
        * PROPCASE function on test label has changed case of some abbreviations which need to be changed back ;
        ARRAY _from (7) $ _TEMPORARY_ ('Qtcb','Qtcf','Qt','Qrs','Pr','Rr','And');
        ARRAY _to   (7) $ _TEMPORARY_ ('QTcB','QTcF','QT','QRS','PR','RR','and');
        DO i = 1 TO DIM(_from);
          IF INDEX(paramlbl,STRIP(_from{i})) THEN paramlbl = TRANWRD(paramlbl,STRIP(_from{i}),STRIP(_to{i}));
        END;
      %END;

      /* AJC001: Amend derivation of AVALC to use EGORRES when EGTESTCD="INTP" */
      %if %tu_chkvarsexist(&lastdset.,&domain.STRESC &domain.STRESN)=%str() %then %do;
          IF INPUT(&domain.STRESC,??best.) NE &domain.STRESN OR &domain.STRESN=. THEN DO;
            %if %tu_chkvarsexist(&lastdset.,&domain.ORRES)=%str() %then %do;
                IF UPCASE(&domain.testcd) EQ 'INTP' THEN
                  AVALC=&domain.ORRES;
                ELSE
            %end;
            AVALC=&domain.STRESC;
          END;
      %end;

      /*   SJG001 */
*      IF UPCASE(&domain.test) EQ 'INTERPRETATION' AND &domain.ORRES ne ' ' THEN AVALC=&domain.ORRES;
      
      %if %tu_chkvarsexist(&lastdset.,&domain.STRESN)=%str() %then IF &domain.STRESN NE . THEN AVAL=&domain.STRESN;;
      %if %tu_chkvarsexist(&lastdset.,&domain.STNRLO)=%str() %then ANRLO=&domain.STNRLO;;
      %if %tu_chkvarsexist(&lastdset.,&domain.STNRHI)=%str() %then ANRHI=&domain.STNRHI;;
      %if %tu_chkvarsexist(&lastdset.,&domain.NRIND)=%str() %then ANRIND=&domain.NRIND;;
      %if %tu_chkvarsexist(&lastdset.,&domain.SEQ)=%str() %then SRCSEQ=&domain.SEQ;;
      %if %tu_chkvarsexist(&lastdset.,domain)=%str() %then SRCDOM=domain;;
  run;
 
  %let lastdset=&prefix._derive;
  
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
                 dsetinadsl=&dsetinadsl,
                 adslvars=&adslvars,
                 adgettrtmergevars=&adgettrtmergevars,
                 adgettrtvars=&adgettrtvars
                );

     %let lastdset=&prefix._baseln;
  %end;
 
  /* Calling tu_adchgccfg to derive A2LO, A2HI, A2INDCD, A2IND - Change from Baseline */

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

  /* Derive analysis flags based on range flagging */
  /* AJC001: Correct derivation to use A2INDCD for ANL71FL and A1INDCD for ANL72FL */
  %IF %LENGTH(%tu_chkvarsexist(&lastdset.,a1indcd a2indcd,Y)) GT 0 %THEN %DO;
    PROC SQL;
      CREATE TABLE &prefix._anlfl AS
        SELECT l.*
               %IF %tu_chkvarsexist(&lastdset.,a2indcd)=%str() %THEN ,f2.anl71fl;
               %IF %tu_chkvarsexist(&lastdset.,a1indcd)=%str() %THEN ,f3.anl72fl;
        FROM &lastdset l %IF %tu_chkvarsexist(&lastdset.,a2indcd)=%str() %THEN %DO;
                           LEFT JOIN (SELECT DISTINCT usubjid, 'Y' AS anl71fl
                                      FROM &lastdset
                                      WHERE a2indcd IN ('H' 'L')) f2 ON l.usubjid=f2.usubjid
                         %END;
                         %IF %tu_chkvarsexist(&lastdset.,a1indcd)=%str() %THEN %DO;
                           LEFT JOIN (SELECT DISTINCT usubjid, 'Y' AS anl72fl
                                      FROM &lastdset
                                      WHERE a1indcd IN ('H' 'L')) f3 ON l.usubjid=f3.usubjid
                         %END;;
    QUIT;

    %LET lastdset=&prefix._anlfl;
  %END;

  /* Last step after derivations and study-specific derivations */
  /* Derive source variables */
  /* AJC001: Updated derivation for ECG interpretation test */
  DATA &prefix._derive99;
    SET &lastdset;
      * If DTYPE has not been previously created, define DTYPE with a null value ;
      %IF %tu_chkvarsexist(&lastdset.,dtype,Y)=%str() %THEN dtype = ' ';;
      IF dtype = '' THEN DO; * If not a derived observation then set value of SRCVAR ;
        IF &domain.stresn NE . THEN srcvar = "%UPCASE(&domain)STRESN";
        ELSE IF UPCASE(&domain.testcd) EQ 'INTP' and &domain.orres NE '' THEN srcvar = "%UPCASE(&domain)ORRES";
        ELSE IF &domain.stresc NE '' THEN srcvar = "%UPCASE(&domain)STRESC";
      END;
      ELSE IF dtype NE '' THEN DO; * If a derived observation then ensure values of SRCDOM and SRCSEQ are null ;
        IF srcdom NE '' THEN srcdom = '';
        IF srcseq NE . THEN srcseq = .; 
      END;
  RUN;
  
  %let lastdset=&prefix._derive99;


  /* Calling tu_decode to derive codes or decodes using formats specified in &g_dsplanfile */

  %if %upcase(&decodeyn.) eq Y %then
  %do;
    %tu_decode (dsetin = &lastdset.,
                dsetout= &prefix._decode,
                codepairs=&codepairs,
                decodepairs=&decodepairs,
                dsplan=&g_dsplanfile
               ); /*AJC002: Correct DSETOUT parameter value and specify DSPLAN */
    %let lastdset=&prefix._decode;
  %end;


  /* Calling tu_attrib to apply the attributes to the variables in output dataset, if attributesyn parameter is Y. */

  %if %upcase(&attributesyn.) eq Y %then
  %do;
    %tu_attrib (dsetin = &lastdset.,
                dsetout= &dsetout.,
                dsplan = &g_dsplanfile
               );
  %end;
  /* Else if attributesyn parameter is N create output dataset */
  %ELSE %DO;
    DATA &dsetout;
      SET &lastdset;
    RUN;
  %END;


  %if %tu_nobs(&dsetout) gt 0 %then %do;
    %if %upcase(&misschkyn) eq Y %then
    %do;
        %tu_misschk(dsetin=&dsetout);
    %end;
  %end;


  /* Calling tu_tidyup to delete the temporary datasets. */

  %tu_tidyup(rmdset=&prefix.:, glbmac=none);

%mend tc_adeg;
