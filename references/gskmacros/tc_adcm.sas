/******************************************************************************* 
| Program Name: tc_adcm.sas
|
| Program Version: 2.2
|
| HARP Compound/Study/Reporting Effort: 
|
| Program Purpose: To create the ADaM dataset of ADCM domain using the SDTM CM
|                  and supplemental CM datasets.
|
| SAS Version: SAS v9.1.3
|
| Created By: Spencer X Renyard (sr550750)
| Date:       1st July 2014
|
|******************************************************************************* 
|
| Output: adamdata.ADCM
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
| (@) tu_decode
| (@) tu_putglobals
| (@) tu_misschk
| (@) tu_tidyup
| (@) tu_chkvarsexist
| (@) tu_nobs
| (@) tu_abort
|
| Metadata:
|
|******************************************************************************* 
| Change Log 
|
| Modified By: Mark D. Hopton
| Date of Modification: 06-Nov-2017
| New Version Number: 2
| Modification ID: MDH001
| Reason For Modification: Based on v2 of requirements document:
| 1. Allow coding to be performed via GSKDRUG or WHODDE dictionaries.
| 2. Derivation of ADaM v1.1 variables added (e.g. ADURN, ATC1, DICTVER).
| 3. Derivation of treatment phase flags updated to take account of missing dates.
| 4. Analysis flags populated for coded records only.
| 5. Output RTWARNING messages to highlight number of uncoded records and records where length of ADECOD=200.
| 6. CMBASED derived as an 8 rather than 6 digit code
| 7. General bug fixes and maintenance
|
| Modified By: Mark D. Hopton
| Date of Modification: 08-Mar-2018
| New Version Number: 2 build 2
| Modification ID: MDH002
| Reason For Modification: Based on v3 of requirements document:
| 1. Apply IDSL guidance on handling of filler compounds.
| 2. Allow for tu_adsuppjoin being called before tc_adcm, i.e. ADSUPPJOINYN=N.
|
********************************************************************************/ 
%macro tc_adcm(dsetin=sdtmdata.cm,         /* Input dataset */
               dsetout=adamdata.adcm,      /* Output dataset to be created*/
               adsuppjoinyn=Y,             /* If supplemental dataset is required to be joined with parent domain Y/N */
               dsetinsupp=sdtmdata.suppcm, /* Input supplemental dataset */
               addatetimeyn=Y,             /* Flag to indicate if If tu_addatetime utility is to be executed Y/N */
               datevars=cmstdtc cmendtc,   /* Datetime variables in input dataset to be converted to numeric dates times datetimes*/
               getadslvarsyn=Y,            /* Flag to indicate if tu_adgetadslvars utility need to be called */
               dsetinadsl=adamdata.adsl,   /* Input ADSL or ADTRT dataset */          
               adslvars=siteid age sex race acountry trtsdt trtedt trtseq: fasfl ittfl saffl pprotfl, /* List of variable from DSETINADSL dataset for tu_adgetadslvars utility to merge on by USUBJID*/
               adgettrtyn=Y,               /* Flag to indicate if tu_adgettrt utility is to be executed Y/N */
               adgettrtmergevars=USUBJID,  /* Variables used to merge treatment information from DSETINADSL onto work dataset */
               adgettrtvars=trt01p trt01pn trt01a trt01an,   /* List of variables from treatment dataset DSETINADSL for tu_adgettrt utility to add to work dataset */
               decodeyn=N,                 /* Flag to indicate if tu_decode utility is to be executed Y/N */
               decodepairs=,               /* A list of paired code/decode variables for which the decode is to be created*/ 
               codepairs=,                 /* A list of paired code/decode variables for which the code is to be created*/
               adreldaysyn=Y,              /* Flag to indicate if tu_adreldays utility is to be executed*/
               dyrefdatevar=,              /* Reference date variable for analysis relative days derivation: ADY, ASTDY, AENDY*/
               advisityn=N,                /* Flag to indicate if tu_adreldays utility is to be executed Y/N */
               avisitnfmt=,                /* Format used to derive AVISITN from VISITNUM*/
               avisitfmt=,                 /* Format used to derive AVISIT from VISIT*/ 
               adperiodyn=N,               /* Flag to indicate if tu_adperiod utility is to be executed Y/N */
               dictdecodeyn=Y,             /* Flag to indicate if code to add MedDRA dictionary variables is to be executed Y/N */
               dicttype=GSKDRUG,           /* Flag to indicate which coding dictionary will be applied */
               dictdrugcodevar=CMDRGCOL,   /* Dictionary variable containg drug collection code*/
               ontrtfldays=0,              /* Wash-out period (days) post-treatment for on-treatment flag (default=0)*/
               fupfldays=0,                /* Wash-out period (days) post-treatment for follow-up flag (default=0)*/
               durationunits=DAYS,         /* Units to use fur duration derivations */ 
               misschkyn=Y,                /* Flag to indicate if tu_misschk utility is to be executed Y/N */
               attributesyn=Y              /* Flag to indicate if tu_attrib utility is to be executed Y/N */
               );
               
/* MDH001: Macro parameters DICTTYPE, DICTDRUGCODEVAR and DURATIONUNITS added to macro definition above
           Buf fix - trailing comma removed from macro definition */

  /*
  / Echo parameter values and global macro variables to the log.
  /----------------------------------------------------------------------------*/

  %local MacroVersion;
  %let MacroVersion = 2 build 2;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_dsplanfile g_abort g_refdata) 

  /*
  /  Set up local macro variables
  / ---------------------------------------------------------------------------*/

  %local prefix lastdset domain dictver l_countatc l_countdecod l_i;
  %let prefix = _adcm;
  
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
  %let dictdecodeyn      = %nrbquote(%upcase(&dictdecodeyn.));
  %let dicttype          = %nrbquote(%upcase(&dicttype.));        /* MDH001 */
  %let dictdrugcodevar   = %nrbquote(%upcase(&dictdrugcodevar.)); /* MDH001 */
  %let durationunits     = %nrbquote(%upcase(&durationunits.));   /* MDH001 */

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

  /* Validating if DSETIN is a valid dataset name */
  %if %tu_chknames(%scan(&dsetin, 1, %str(%() ), DATA ) ne %then %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETIN refers to dataset &dsetin which is not a valid dataset name;
    %let g_abort=1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;

  /* Validating if DSETIN dataset exists */
  %if %SYSFUNC(EXIST(%scan(&dsetin, 1, %str(%() ) )) NE 1 %then %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETIN refers to dataset &dsetin which does not exist;
    %let g_abort=1;
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

  /* Validating ADSUPPJOINYN parameter */
  %if &adsuppjoinyn. ne Y and &adsuppjoinyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ADSUPPJOINYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Validating ADDATETIMEYN, GETADSLVARSYN, ADGETTRTYN, ADVISITYN, ADPERIODYN, ADRELDAYSYN, DECODEYN, ATTRIBUTESYN, MISSCHKYN, DICTDECODEYN parameters */
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

  %if &dictdecodeyn. ne Y and &dictdecodeyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DICTDECODEYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
  
  /* MDH001: Validating DICTTYPE parameters */
  %if &dictdecodeyn. eq Y and &dicttype. ne GSKDRUG and &dicttype. ne WHODDE %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DICTTYPE should either be GSKDRUG or WHODDE.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
  
  /* MDH001: Validating DURATIONUNITS parameter */
  %if &durationunits. ne HOURS and &durationunits. ne DAYS and &durationunits. ne WEEKS and &durationunits. ne MONTHS and &durationunits. ne YEARS %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DURATIONUNITS should either be HOURS, DAYS, WEEKS, MONTHS or YEARS.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
  
  /* MDH001: Validating DICTDRUGCODEVAR parameters */
  %if &dictdecodeyn. eq Y and &dictdrugcodevar. eq %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DICTDRUGCODEVAR should be populated when DICTDECODEYN=Y;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
  
  /* Validate ONTRTFLDAYS */
  %IF %BQUOTE(&ontrtfldays) = %THEN %DO;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ONTRTFLDAYS may not be null or blank.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %END;
  %ELSE %IF %datatyp(&ontrtfldays) = CHAR %THEN %DO;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ONTRTFLDAYS must be a numeric value.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %END;
  %ELSE %IF (%BQUOTE(&ontrtfldays) NE %SYSFUNC(ABS(%SYSFUNC(INT(&ontrtfldays))))) %THEN %DO;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ONTRTFLDAYS must be zero or a positive integer.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %END;

  /* Validate FUPFLDAYS */
  %IF %BQUOTE(&fupfldays) = %THEN %DO;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter FUPFLDAYS may not be null or blank.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %END;
  %ELSE %IF %datatyp(&fupfldays) = CHAR %THEN %DO;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter FUPFLDAYS must be a numeric value.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %END;
  %ELSE %IF (%BQUOTE(&fupfldays) NE %SYSFUNC(ABS(%SYSFUNC(INT(&fupfldays))))) %THEN %DO;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter FUPFLDAYS must be zero or a positive integer.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %END;

  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;
    
  /* Create work dataset if DSETIN contains dataset options */
  /* MDH001: Derive local macro variable DOMAIN from &DSETIN.DOMAIN
             Bug fix - %UNQUOTE added to &DSETIN to allow where clause processing */
    data  &prefix._dsetin;
      set %unquote(&dsetin) end=last;
      if last then call symput('domain',strip(upcase(domain)));
    run;

    %let lastdset=&prefix._dsetin;
 
  /* MDH001: Derive local macro variable DICTVER from DICTION.&DICTTYPE */
  %if %upcase(&dictdecodeyn) eq Y %then %do;
    data  &prefix._dictver;
      set diction.&dicttype end=last;
      if last then call symput('dictver',strip(upcase(cmver)));
    run;
  %end;
  /*
  / Main Processing starts here.
  / ---------------------------------------------------------------------------*/

  /* Calling tu_adsuppjoin to merge supplemental dataset with parent domain dataset, if adsuppjoinyn parameter is Y */
  %if %upcase(&adsuppjoinyn) eq Y %then
  %do;
        
    %tu_adsuppjoin(dsetin=&lastdset.,
                   dsetinsupp=&dsetinsupp,
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

    /* Deriving event dates to ADaM variable naming conventions */  /*pick up code from adae or adds*/
    
    
    data &prefix._daterename;
      set &prefix._date;
        %if %LENGTH(%tu_chkvarsexist(&prefix._date,&domain.DT)) LE 0 %then ADT = &domain.DT;;
        %if %LENGTH(%tu_chkvarsexist(&prefix._date,&domain.TM)) LE 0 %then ATM = &domain.TM;;
        %if %LENGTH(%tu_chkvarsexist(&prefix._date,&domain.DTM)) LE 0 %then ADTM = &domain.DTM;;
        %if %LENGTH(%tu_chkvarsexist(&prefix._date,&domain.STDT)) LE 0 %then ASTDT = &domain.STDT;;
        %if %LENGTH(%tu_chkvarsexist(&prefix._date,&domain.STTM)) LE 0 %then ASTTM = &domain.STTM;;
        %if %LENGTH(%tu_chkvarsexist(&prefix._date,&domain.STDTM)) LE 0 %then ASTDTM = &domain.STDTM;;
        %if %LENGTH(%tu_chkvarsexist(&prefix._date,&domain.ENDT)) LE 0 %then AENDT = &domain.ENDT;;
        %if %LENGTH(%tu_chkvarsexist(&prefix._date,&domain.ENTM)) LE 0 %then AENTM = &domain.ENTM;;
        %if %LENGTH(%tu_chkvarsexist(&prefix._date,&domain.ENDTM)) LE 0 %then AENDTM = &domain.ENDTM;;
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
                 dsetinadtrt=&dsetinadsl,
                 eventtype=SP
                 );

    %let lastdset=&prefix._period;
  %end;


  /* Calling tu_adgettrt to assign treatment variables to records also bring in selected "other" variables from adtrt such as period trt start stop etc*/

  %if %upcase(&adgettrtyn)=Y %then
  %do;
    %tu_adgettrt(dsetin=&lastdset.,
                 dsetinadsl=&dsetinadsl,
                 mergevars=&adgettrtmergevars,
                 trtvars=&adgettrtvars,
                 dsetout=&prefix._trt
                 );
    %let lastdset=&prefix._trt;
  %end;


  /* Calling tu_adreldays to derive relative days ADY, ASTDY, AENDY */

  %if %upcase(&adreldaysyn)=Y %then
  %do;
    %tu_adreldays(dsetin=&lastdset,
                  dsetout=&prefix._reldays,
                  dyrefdatevar=&dyrefdatevar,
                  domaincode=&domain
                  );

    %let lastdset=&prefix._reldays;
  %end;


  /*Domain specific derivations*/

  /* Code to add dictionary variables */
  
  %if %upcase(&dictdecodeyn)=Y %then %do;
    /* Get number of supplemental CMDECOD# variables - used in derivation of ADECOD */
    /* MDH001: Variable prefix CM replaced within &domain */
    %LET l_countdecod = 0;
    
    PROC SQL NOPRINT;
      SELECT COUNT(name) INTO :l_countdecod
      FROM sashelp.vcolumn
      WHERE UPCASE(libname)="WORK" AND 
            UPCASE(memname)="%UPCASE(&lastdset)" AND
            (UPCASE(name) EQT "&domain.DECOD" AND UPCASE(name) NE "&domain.DECOD");
    QUIT;
        
    /* MDH001: Temporarily replace '+' with '@' within medication names to allow correct expansion of multiple ingredient medications*/     

    %IF &l_countdecod GT 0 %THEN %DO;

      data &prefix._tempname;
        set &lastdset;
        %do l_i =1 %to &l_countdecod;
          &domain.DECOD&l_i=tranwrd(&domain.DECOD&l_i,'+','@');
        %end;
      run;
      %let lastdset=&prefix._tempname;

    %END;

    DATA &prefix._mult0 %IF &l_countdecod GT 0 %THEN (DROP=_i _loops temp_adecod);;
      LENGTH adecod %IF &l_countdecod GT 0 %THEN temp_adecod; $200;
      SET &lastdset;
        * ADECOD ;
      /* MDH001: Bug fix - FLAGMULT variable initialised for single ingredient medications to ensure variable is present
                           when no mutltiple ingredient medications are reported */
        IF UPCASE(&domain.decod) NE 'MULTIPLE' THEN DO;
          adecod = &domain.decod;
          flagmult = '';
          OUTPUT;
        END;
        *If CMDECOD# variables present in dataset, concatenate CMDECOD#, otherwise equals CMDECOD, which equals MULTIPLE;
        ELSE IF UPCASE(&domain.decod) = 'MULTIPLE' THEN DO;
          adecod = %IF &l_countdecod GT 0 %THEN CATX('+',OF &domain.decod1-&domain.decod%LEFT(&l_countdecod));
                                          %ELSE %IF &l_countdecod = 0 %THEN &domain.decod;;
          OUTPUT;
          * Output one record per component for drugs with multiple components;
          %IF &l_countdecod GT 0 %THEN %DO;
            _loops = LENGTH(adecod)-LENGTH(COMPRESS(adecod,'+'))+1;
            temp_adecod = adecod;
            DO _i = 1 TO _loops;
              adecod = SCAN(temp_adecod,_i,'+');
              flagmult = 'Y';
              OUTPUT;
            END;
          %END;
        END;
    RUN;
    
    /* MDH001: If performed, revert temporary replacement of '+' with '@' within medication names */
    data &prefix._mult1;
      set &prefix._mult0;
      %IF &l_countdecod GT 0 %THEN
        adecod = tranwrd(adecod,'@','+');;
      /*MDH002: Derive based on existence of &dictdrugcodevar rather than call to tu_adsuppjoin */
      %IF %LENGTH(%tu_chkvarsexist(&prefix._mult0,&dictdrugcodevar)) LE 0 %then
        drgcol = &dictdrugcodevar;;
    run;
    
    /* MDH001: Variable CMDRGCOL replaced with &dictdrugcodevar when sourced from non-dictionary data */
    %if %tu_chkvarsexist(&lastdset, &dictdrugcodevar) eq  %then %do; *  Check CMDRGCOL is present in dataset ;

      * For individual components get CMCOMPCD from dictionary and populate CMDRGCOL ;
      /* MDH001: Dictionary data subset on CMNC='C'
                 DICTION.GSKDRUG replaced with DICTION.&DICTTYPE */
      PROC SQL;
        CREATE TABLE &prefix._mult2 AS
          SELECT c.*, g.cmcompcd AS &dictdrugcodevar, g.cmcompcd AS compcd
          FROM &prefix._mult1 (DROP=&dictdrugcodevar) c LEFT JOIN (SELECT DISTINCT cmdecod, cmcompcd
                                                           FROM diction.&dicttype
                                                           WHERE cmdecod IN (SELECT DISTINCT adecod
                                                                             FROM &prefix._mult1
                                                                             WHERE flagmult='Y') AND UPCASE(cmnc) eq 'C') g ON c.adecod=g.cmdecod
          WHERE c.flagmult='Y';

        * Set back with single ingredient data ;
        CREATE TABLE &prefix._mult3 (DROP=flagmult) AS
          SELECT *
          FROM (SELECT *
                FROM &prefix._mult1
                WHERE flagmult='')
            OUTER UNION CORR
               (SELECT *
                FROM &prefix._mult2);

        * Merge expanded CM data with dictionary ;
        CREATE TABLE &prefix._dictdcod_step1 AS
          SELECT c.*,
                 FIRST(g.cmatccd) AS dcl1c LENGTH=200,
                 SUBSTR(g.cmatccd,1,3) AS dcl2c LENGTH=200,
                 SUBSTR(g.cmatccd,1,4) AS dcl3c LENGTH=200,
                 cmatccd AS dcl4c LENGTH=200,
                 g.cmatc1 AS dcl1t LENGTH=200,
                 g.cmatc2 AS dcl2t LENGTH=200,
                 g.cmatc3 AS dcl3t LENGTH=200,
                 g.cmatc4 AS dcl4t LENGTH=200,
                 FIRST(g.cmatccd) AS atc1cd LENGTH=200,
                 SUBSTR(g.cmatccd,1,3) AS atc2cd LENGTH=200,
                 SUBSTR(g.cmatccd,1,4) AS atc3cd LENGTH=200,
                 cmatccd AS atc4cd LENGTH=200,
                 g.cmatc1 AS atc1 LENGTH=200,
                 g.cmatc2 AS atc2 LENGTH=200,
                 g.cmatc3 AS atc3 LENGTH=200,
                 g.cmatc4 AS atc4 LENGTH=200,
                 g.cmver,
                 /* MDH001: CMBASECD derived as an 8 rather than 6 digit code */
                 CASE
                   WHEN c.&dictdrugcodevar NE '' THEN SUBSTR(c.&dictdrugcodevar,1,6)||'01'
                   ELSE ''
                 END AS &domain.basecd
          FROM &prefix._mult3 c LEFT JOIN (SELECT DISTINCT cmdrgcol, cmatccd, cmatc1, cmatc2, cmatc3, cmatc4, cmver
                                           FROM diction.&dicttype
                                           WHERE cmdrgcol IN (SELECT DISTINCT &dictdrugcodevar
                                                              FROM &prefix._mult3) AND UPCASE(cmnc) eq 'C') g ON c.&dictdrugcodevar=g.cmdrgcol;

        CREATE TABLE &prefix._dictdcod AS
          SELECT c.*, g.cmdecod AS &domain.base
          FROM &prefix._dictdcod_step1 c LEFT JOIN (SELECT DISTINCT cmdrgcol, cmdecod
                                                    FROM diction.&dicttype
                                                    WHERE cmdrgcol IN (SELECT DISTINCT &domain.basecd
                                                                       FROM &prefix._dictdcod_step1) AND
                                                          UPCASE(cmdecod) NE 'MULTIPLE INGREDIENT' AND UPCASE(cmnc) eq 'C') g ON c.&domain.basecd=g.cmdrgcol;

        * For the records with no base record in dictionary set values to highlight this ;
        /* MDH001: Default value of CMBASECD changed from 999999 (6 digits) to 99999999 (8 digits)
                   WHERE clause updated to prevent single ingredient values of ADECOD containing '+' from being selected */
        UPDATE &prefix._dictdcod
          SET &domain.basecd='99999999', &domain.base='NO BASE SPECIFIED'
          WHERE &domain.base=' ' AND &domain.basecd NE '' AND ^(INDEX(adecod,'+') AND COMPCD eq '');

        * If CMBASECD has a value but CMBASE does not, e.g. multiple ingredient rows, set CMBASECD to null ;
        UPDATE &prefix._dictdcod
          SET &domain.basecd=' '
          WHERE &domain.base=' ' AND &domain.basecd NE '';
     QUIT;
    %end;   /* end-if Variable CMDRGCOL exists in dataset.*/
    %else %do; /* CMDRGCOL variable not found on dataset. */
      %put %str(RTN)OTE: TU_ADCM: The input dataset (&LASTDSET) does not have &dictdrugcodevar variable.;
      %put %str(RTN)OTE: TU_ADCM: The output dataset (&PREFIX._dictdcod) is set to the input dataset (&prefix._mult1) as is.;

      data &prefix._dictdcod;
        set &prefix._mult1;
      run;
    %end;  /* end-else CMDRGCOL variable not found on dataset */

    %let lastdset=&prefix._dictdcod;
  %end;
  
  /* MDH001: Remove individual components of multiple ingredient medications if coding performed via WHODDE */
  %if &dictdecodeyn eq Y and &dicttype eq WHODDE %then %do;
    data &prefix._dictdcod2;
      set &lastdset;
      if length(&dictdrugcodevar) gt 8 or (&dictdrugcodevar eq '' and &domain.decod1 ne '') then delete;
    run;
    
    %let lastdset=&prefix._dictdcod2;
  %end;

  data &prefix._derive;
    set &lastdset;
      %if %LENGTH(%tu_chkvarsexist(&lastdset,&domain.TPT)) LE 0 %then ATPT = &domain.TPT;;
      %if %LENGTH(%tu_chkvarsexist(&lastdset,&domain.TPTREF)) LE 0 %then ATPTREF = &domain.TPTREF;;
      %if %LENGTH(%tu_chkvarsexist(&lastdset,&domain.TPTNUM)) LE 0 %then ATPTN = &domain.TPTNUM;;

      * Create ADaM on-treatment flag if not present in dataset ;
      %IF %LENGTH(%tu_chkvarsexist(&lastdset,ontrtfl)) GE 1 %THEN %DO; *ONTRTFL not present in dataset, so create;
        /* MDH001: Updated derivation of ONTRTFL to take account of missing/partial dates */
        IF NMISS(trtsdt) eq 0 AND ((astdt eq . and (aendt eq . or aendt ge trtsdt gt .)) or
        (. lt astdt lt trtsdt and (aendt eq . or aendt ge trtsdt gt .)) or trtsdt le astdt le (trtedt + &ontrtfldays)) THEN ontrtfl = 'Y' ;
      %END;

      * Pre-treatment, Follow-up flags ;
      %IF %LENGTH(%tu_chkvarsexist(&lastdset,prefl)) GE 1 %THEN %DO; *PREFL not present in dataset, so create;
        /* MDH001: Derivation of PREFL updated to take account of missing/partial dates */
        IF NMISS(trtsdt) eq 0 and (astdt eq . or . lt astdt lt trtsdt) THEN prefl = 'Y' ;
      %END;

      %IF %LENGTH(%tu_chkvarsexist(&lastdset,fupfl)) GE 1 %THEN %DO; *FUPFL not present in dataset, so create;
        /* MDH001: Derivation of FUPFL updated to take account of missing/partial dates */
        IF NMISS(trtsdt,trtedt) eq 0 AND (aendt eq . or aendt gt (trtedt + &fupfldays) gt .) THEN fupfl = 'Y';
      %END;

      * ANF01/02FL variables ;
      %IF %LENGTH(%tu_chkvarsexist(&lastdset,adecod)) LE 0 %THEN %DO;
        /* MDH001: ANL01FL only populated for coded records */
        /*MDH002: Derive based on existence of compcd rather than call to tu_adsuppjoin */
        %IF %LENGTH(%tu_chkvarsexist(&lastdset,compcd)) LE 0 %THEN %DO;
          IF UPCASE(&domain.decod) NOT IN ('' 'MULTIPLE') OR
             (UPCASE(&domain.decod)='MULTIPLE' AND ^(INDEX(adecod,'+') AND compcd eq '') AND adecod NOT IN ('' 'MULTIPLE'))
             THEN anl01fl = 'Y';
        %end;
        %else %do;
          IF UPCASE(&domain.decod) NOT IN ('' 'MULTIPLE') OR
             (UPCASE(&domain.decod)='MULTIPLE' AND INDEX(adecod,'+')=0 AND adecod NOT IN ('' 'MULTIPLE'))
             THEN anl01fl = 'Y';
        %end;
        ELSE anl01fl = '';
        /* MDH001: ANL02FL only populated for coded records */
        /*MDH002: Derive based on existence of compcd rather than call to tu_adsuppjoin */
        %IF %LENGTH(%tu_chkvarsexist(&lastdset,compcd)) LE 0 %THEN %DO;
          IF UPCASE(&domain.decod) NOT IN ('' 'MULTIPLE') OR 
             (UPCASE(&domain.decod)='MULTIPLE' AND (INDEX(adecod,'+') AND compcd eq '') AND adecod NOT IN ('' 'MULTIPLE'))
             THEN anl02fl = 'Y';
        %end;
        %else %do;
          IF UPCASE(&domain.decod) NOT IN ('' 'MULTIPLE') OR 
             (UPCASE(&domain.decod)='MULTIPLE' AND INDEX(adecod,'+') AND adecod NOT IN ('' 'MULTIPLE'))
             THEN anl02fl = 'Y';
        %end;
        ELSE anl02fl = '';
      %END;
      %ELSE %DO;
        anl01fl = '';
        anl02fl = '';
      %END;
      
      %IF %LENGTH(%tu_chkvarsexist(&lastdset, &dictdrugcodevar)) LE 0 %THEN %DO;
        /* MDH001: Ensure dictionary code variables are only populated if the corresponding text variable is populated */
        %IF &dictdecodeyn eq Y %THEN %DO i=1 %TO 4;
          IF dcl&i.t eq '' THEN dcl&i.c = '';
          IF atc&i eq '' THEN atc&i.cd = '';
        %END;
              
        /*MDH001: Derivation of ADRGCOL and &DICTDRUGCODEVAR */
        %IF %LENGTH(%tu_chkvarsexist(&lastdset,&dictdrugcodevar)) LE 0 %THEN %DO;
          adrgcol = &dictdrugcodevar;
          %if %upcase(&dictdecodeyn) eq Y %then %do;
            &dictdrugcodevar = drgcol;
          %end;
        %END;
      %END;
      
      /* MDH001: Derivation of ADURN and ADURU */
      %IF %LENGTH(%tu_chkvarsexist(&lastdset,astdt)) LE 0 AND
          %LENGTH(%tu_chkvarsexist(&lastdset,aendt)) LE 0 %THEN %DO;
        IF NMISS(astdt,aendt) eq 0 THEN DO;
          %IF &durationunits EQ YEARS %THEN %DO;
             adurn = INTCK('year', astdt, aendt+1) -
                     ((MONTH(aendt+1) LT MONTH(astdt)) OR
                     ((MONTH(aendt+1) EQ MONTH(astdt)) AND (DAY(aendt+1) LT DAY(astdt))));
          %END;
          %ELSE %IF &durationunits EQ MONTHS %THEN %DO;
            adurn = ((YEAR(aendt+1) - YEAR(astdt)) * 12) +
                    (MONTH(aendt+1) - MONTH(astdt)-1) +
                    (DAY(aendt+1) GE DAY(astdt));
          %END;
          %ELSE %IF &durationunits EQ WEEKS %THEN %DO;
            adurn = ((aendt+1) - astdt) / 7;
          %END;
          %ELSE %IF &durationunits EQ DAYS %THEN %DO;
            adurn = (aendt+1) - astdt;
          %END;
          %ELSE %IF &durationunits EQ HOURS %THEN %DO;
            adurn = (aendt - astdt) * 3600 * 24; /* convert to seconds */

            %IF %LENGTH(%tu_chkvarsexist(&lastdset,asttm)) LE 0 AND
                %LENGTH(%tu_chkvarsexist(&lastdset,aentm)) LE 0 %THEN %DO;
              IF NMISS(asttm,aentm) eq 0 THEN adurn = adurn + (aentm - asttm);
            %END;

            adurn = adurn / 3600;

            IF adurn eq CEIL(adurn) THEN adurn = adurn + 1;
            ELSE adurn = CEIL(adurn);

          %END;

          IF adurn NE . THEN aduru = "&durationunits";
        END;
      %END;
      
      /*MDH001: Derivation of DICTVER */
      %IF %LENGTH(%tu_chkvarsexist(&lastdset,cmver)) LE 0 %THEN %DO;
        if &dictdrugcodevar ne '' then dictver = "&dicttype &dictver";
      %END;
      
      /*MDH002: Apply IDSL guidance on handling of filler compounds within GSKDRUG*/
      %if &dictdecodeyn eq Y and &dicttype eq GSKDRUG and %LENGTH(%tu_chkvarsexist(&lastdset,&dictdrugcodevar)) LE 0 %then %do;
        if atc1 eq '' and adrgcol ne '' and upcase(adecod) ne 'NO DRUG TERM AVAILABLE'
        then atc1='PHARMACOLOGICAL PROPERTIES CANNOT BE REFERENCED';
        if dcl1t eq '' and adrgcol ne '' and upcase(adecod) ne 'NO DRUG TERM AVAILABLE'
        then dcl1t='PHARMACOLOGICAL PROPERTIES CANNOT BE REFERENCED';
      %end;
  run;

  %let lastdset=&prefix._derive;
  
  /* MDH001: Highlight number of uncoded records via a RTWARNING log message
             Highlight values of ADECOD that have a length of 200 and may be truncted via a RTWARNING log message */
  %IF %LENGTH(%tu_chkvarsexist(&lastdset, adecod)) LE 0 %THEN %DO;
    proc freq data=&lastdset noprint;
      tables adecod / out=&prefix._freq (keep=adecod count);
      where &domain.trt ne '';
    run;
  
    data &prefix._freq;
      set &prefix._freq;
      if adecod eq '' and count gt 0 then put "RTW" "ARNING: &sysmacroname.: " count "uncoded records.";
      if length(adecod) eq 200 then put "RTW" "ARNING: &sysmacroname.: Length of variable ADECOD=200, possible truncation. ADECOD=" adecod;
    run;
  %END;
  
  /* Sort data prior to determining the first CM record where ANL02FL is Y, then derive ANL03FL */
  %IF %LENGTH(%tu_chkvarsexist(&prefix._derive,dcl1c)) LE 0 %THEN %DO;
    PROC SORT DATA=&prefix._derive
               OUT=&prefix._derive2;
      BY usubjid astdt asttm aendt aentm &dictdrugcodevar &domain.seq adecod dcl1c dcl2c dcl3t dcl4c;
    RUN;

    DATA &prefix._derive3;
      SET &prefix._derive2;
        BY usubjid astdt asttm aendt aentm &dictdrugcodevar &domain.seq adecod dcl1c dcl2c dcl3t dcl4c;
        IF anl02fl = 'Y' AND FIRST.adecod THEN anl03fl = 'Y';
        ELSE anl03fl = '';
    RUN;
       
    %let lastdset=&prefix._derive3;
  %END;

  /* Calling tu_decode to derive codes or decodes using formats specified in &g_dsplanfile */
  /* MDH001: Bug fix - trailing period removed from DSETOUT parameter */
             
  %if %upcase(&decodeyn.) eq Y %then
  %do;
    %tu_decode (dsetin=&lastdset.,
                dsetout=&prefix._decode,
                codepairs=&codepairs,
                decodepairs=&decodepairs,
                dsplan=&g_dsplanfile
                );
    %let lastdset=&prefix._decode;
  %end;


  /* Calling tu_attrib to apply the attributes to the variables in output dataset, if attributesyn parameter is Y. */

  %if %upcase(&attributesyn.) eq Y %then
  %do;
    %tu_attrib (dsetin=&lastdset.,
                dsetout=&dsetout.,
                dsplan=&g_dsplanfile
                );
  %end;
  /* Else if attributesyn parameter is N create output dataset */
  /* MDH001: Bug fix - %UNQUOTE added to &DSETOUT to allow where clause processing */
  %ELSE %DO;
    DATA %unquote(&dsetout);
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

  %tu_tidyup(rmdset=&prefix.:,
             glbmac=none);

%mend tc_adcm;
