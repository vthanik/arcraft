/******************************************************************************* 
| Program Name: tc_adrace.sas
|
| Program Version: 2.3
|
| HARP Compound/Study/Reporting Effort: 
|
| Program Purpose: To create the ADaM dataset of RACE domain using the SDTM DM
|                  and supplemental DM datasets.
|
| SAS Version: SAS v9.1.3
|
| Created By: Spencer Renyard (sr550750)
| Date:       30th June 2014
|
|******************************************************************************* 
|
| Output: 
|
|
|
| Nested Macros: 
| (@) tu_adsuppjoin
| (@) tu_adgetadslvars
| (@) tu_adgettrt
| (@) tu_attrib
| (@) tu_chknames
| (@) tu_chkvarsexist
| (@) tu_decode
| (@) tu_putglobals
| (@) tu_misschk
| (@) tu_tidyup
| (@) tu_nobs
| (@) tu_abort
|
| Metadata:
|
|
|******************************************************************************* 
| Change Log 
|
| Modified By: Spencer Renyard (sr550750)
| Date of Modification: 18th July 2014
| New version/draft number: 2/1
| Modification ID: SR001
| Reason For Modification: Updated logic when deriving RACEDET and RACECOMB records
|
| Modified By: Spencer Renyard (sr550750)
| Date of Modification: 26th August 2014
| New version/draft number: 2/2
| Modification ID: SR002
| Reason For Modification: Records containing the values of the supplemental
|                          RACEOR# variables added - PARAMCD = "RACEOR"
|
| Modified By: Spencer Renyard (sr550750)
| Date of Modification: 16th September 2014
| New version/draft number: 2/3
| Modification ID: SR003
| Reason For Modification: Ensure that text case is correct for RACEDET values
|
********************************************************************************/ 

%macro tc_adrace(dsetin=sdtmdata.dm,         /* Input dataset name */
                 dsetout=adamdata.adrace,    /* Output dataset name */
                 adsuppjoinyn=Y,             /* If supplemental dataset is required to be joined with parent domain Y/N */
                 dsetinsupp=sdtmdata.suppdm, /* Input supplemental dataset name */
                 getadslvarsyn=Y,            /* Flag to indicate if tu_adgetadslvars utility needs to be called Y/N */
                 dsetinadsl=adamdata.adsl,   /* Input ADSL or ADTRT dataset */
                 adslvars=siteid age sex race acountry trtsdt trtedt trtseq: fasfl ittfl saffl pprotfl, /* List of variables from treatment dataset DSETINADSL for tu_adgetadslvars utility to merge on by USUBJID */
                 adgettrtyn=Y,               /* Flag to indicate if tu_adgettrt utility is to be executed Y/N */
                 adgettrtmergevars=USUBJID,  /* Variables used to merge treatment information from DSETINADSL onto work dataset */
                 adgettrtvars=trt01p trt01pn trt01a trt01an, /* List of variables from treatment dataset DSETINADSL for tu_adgettrt utility to add to work dataset */
                 decodeyn=Y,                 /* Flag to indicate if tu_decode utility needs to be called Y/N */
                 decodepairs=paramcd param,  /* A list of paired code/decode variables for which the decode is to be created */ 
                 codepairs=,                 /* A list of paired code/decode variables for which the code is to be created */
                 misschkyn=Y,                /* Flag to indicate if tu_misschk utility is to be executed Y/N */
                 attributesyn=Y ,            /* Flag to indicate if tu_attrib utility is to be executed Y/N */
                );

  /*
  / Echo parameter values and global macro variables to the log.
  /----------------------------------------------------------------------------*/

  %local MacroVersion;
  %let MacroVersion = 2.3;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_dsplanfile) 

  /*
  /  Set up local macro variables
  / ---------------------------------------------------------------------------*/

  %local prefix l_n_raceor;
  %let prefix = adrace;
  %LET l_n_raceor = 0;


  /*
  / PARAMETER VALIDATION
  /----------------------------------------------------------------------------*/

  %let dsetin            = %nrbquote(&dsetin.);
  %let dsetout           = %nrbquote(&dsetout.);
  %let adsuppjoinyn      = %nrbquote(%upcase(&adsuppjoinyn.));
  %let getadslvarsyn     = %nrbquote(%upcase(&getadslvarsyn.));
  %let adgettrtyn        = %nrbquote(%upcase(&adgettrtyn.));
  %let decodeyn          = %nrbquote(%upcase(&decodeyn.));
  %let attributesyn      = %nrbquote(%upcase(&attributesyn.));
  %let misschkyn         = %nrbquote(%upcase(&misschkyn.));


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

  /* Validating GETADSLVARSYN, ADGETTRTYN, DECODEYN, ATTRIBUTESYN and MISSCHKYN parameters */
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

  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;


  /* Create work dataset if DSETIN contains dataset options */
  %if %SCAN(&dsetin,2,()) NE %STR() %then %do;
    data  &prefix._dsetin;
      set &dsetin;
    run;

    %let lastdset=&prefix._dsetin;
  %end;
  %else %do;
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


  /* Calling tu_adgetadslvars to fetch specified variables from the ADSL dataset, if getadslvarsyn parameter is Y */
  %if &getadslvarsyn=Y %then
  %do;
    %tu_adgetadslvars(dsetin = &lastdset.,
                      adsldset = &dsetinadsl.,
                      adslvars = &adslvars.,
                      dsetout = &prefix._adslout
                      );
    %let lastdset=&prefix._adslout;
  %end;


  /* Calling tu_adgettrt to assign treatment variables to records */

  %if %upcase(&adgettrtyn)=Y %then
  %do;
    %tu_adgettrt(dsetin = &lastdset.,
                 dsetinadsl = &dsetinadsl,
                 mergevars = &adgettrtmergevars,
                 trtvars = &adgettrtvars,
                 dsetout = &prefix._trt
                 );

    %let lastdset=&prefix._trt;
  %end;


  /*
  / Domain specific derivations.
  / ---------------------------------------------------------------------------*/

  /* Get the number of variables containing race details (RACEOR#) for use in next data step */
  PROC SQL NOPRINT;
    SELECT COUNT(name) INTO :l_n_raceor
    FROM sashelp.vcolumn
    WHERE UPCASE(libname)='WORK' AND
          UPCASE(memname)="%UPCASE(&lastdset)" AND
          UPCASE(SUBSTR(name,1,6))='RACEOR';
  QUIT;

  data &prefix._derive_race;
    LENGTH avalc $200
           paramcd $8;
    set &lastdset;

      * Derive records for RACEDET ;
      paramcd = 'RACEDET';
      IF race = 'MULTIPLE' THEN avalc = 'Mixed Race';
      /* SR001 */
      %IF %LENGTH(%tu_chkvarsexist(&lastdset,RACEOR2)) LE 0 %THEN %DO; %* If RACEOR2 variable present ;
        ELSE IF UPCASE(race) IN ('WHITE','ASIAN') AND raceor2 NE '' THEN avalc = CATX(' - ',PROPCASE(race),'Mixed Race');
      %END;
      %IF %LENGTH(%tu_chkvarsexist(&lastdset,RACEOR1)) LE 0 %THEN %DO; %* If RACEOR1 variable present ;
        ELSE avalc = raceor1; /* SR003 */
      %END;
      %ELSE avalc = TRANWRD(TRANWRD(PROPCASE(race),'or','Or'),'other','Other');; %* Else use RACE ; /* SR003 */
      /* End of SR001 */
      OUTPUT;

      %IF &l_n_raceor GT 0 %THEN %DO; %* Can only derive if RACEOR# variable(s) present ;
        ARRAY raceor (&l_n_raceor) $ raceor:;
        ARRAY __raceor_ (&l_n_raceor) $200;

        * Derive record(s) for RACEOR ;
        paramcd = 'RACEOR'; /* SR002 */
        DO __k = 1 TO &l_n_raceor;
          IF raceor{__k} NE '' THEN DO;
            avalc = raceor{__k};
            OUTPUT;
          END;
        END;  /* End of SR002 */       

        * Derive records for RACECOMB ;
        paramcd = 'RACECOMB';
        DO __i = 1 TO &l_n_raceor;
          __raceor_{__i} = STRIP(SCAN(raceor{__i},1,'-'));
        END;
        IF race = 'MULTIPLE' THEN avalc = CATX('/',OF __raceor_:);
        ELSE avalc = __raceor_1;
        OUTPUT;

        * Derive additional records for Asian subjects ;
        IF UPCASE(race) = 'ASIAN' THEN DO;
          anl01fl = 'Y';
          paramcd = 'RACECOMB';
          __flag1 = 0;
          __flag2 = 0;
          __flag3 = 0;
          __flag4 = 0;
          DO __j = 1 TO DIM(raceor);
            IF UPCASE(STRIP(SCAN(raceor{__j},2,'-'))) IN ('JAPANESE HERITAGE','EAST ASIAN HERITAGE','SOUTH EAST ASIAN HERITAGE')
               THEN __flag1 = __flag1 + 1; /* SR001 */
            IF UPCASE(STRIP(SCAN(raceor{__j},2,'-'))) IN ('CENTRAL/SOUTH ASIAN HERITAGE','MIXED RACE')
               THEN __flag2 = __flag2 + 1; /* SR001 */
            IF UPCASE(STRIP(SCAN(raceor{__j},2,'-'))) IN ('CENTRAL/SOUTH ASIAN HERITAGE') THEN __flag3 = __flag3 + 1; /* SR001 */
            IF UPCASE(STRIP(SCAN(raceor{__j},2,'-'))) IN ('JAPANESE HERITAGE','EAST ASIAN HERITAGE','SOUTH EAST ASIAN HERITAGE','MIXED RACE')
               THEN __flag4 = __flag4 + 1; /* SR001 */
          END;

          IF __flag1 GT 0 AND __flag2 = 0 THEN avalc = 'Japanese/East Asian Heritage/South East Asian Heritage';
          ELSE IF __flag3 = 1 THEN DO;
            IF __flag4 GT 0 THEN avalc = 'Mixed Asian Heritage';
            ELSE IF __flag4 = 0 THEN avalc = 'Central/South Asian Heritage';
          END;

          DROP __i __j __k __raceor_: __flag1-__flag4;

          OUTPUT;
        END;
      %END;
  run;

  /* Determine sort order (AVALORD) for display of RACEDET values - order is alphabetical, with 'Mixed Race' being */
  /* ordered last overall or within each race category                                                             */
  PROC SQL;
    CREATE TABLE &prefix._racedet_order AS
      SELECT DISTINCT paramcd, avalc, STRIP(SCAN(avalc,1,'-')) AS __string1 LENGTH=40,
             STRIP(SCAN(avalc,2,'-')) AS __string2 LENGTH=40,
             CASE
               WHEN UPCASE(CALCULATED __string1)='MIXED RACE' THEN 99
               ELSE 0
             END AS __ord
      FROM &prefix._derive_race
      WHERE paramcd='RACEDET' AND avalc IS NOT MISSING
      ORDER BY __ord, __string1, __string2;
  QUIT;

  DATA &prefix._racedet_order2 (DROP=__:);
    RETAIN avalord 0;
    SET &prefix._racedet_order;
      avalord = avalord + 1;
  RUN;

  /* Determine sort order (AVALORD) for display of RACECOMB values - order is alphabetical, with 'Multiple' races */
  /* being ordered last, again alphabetically                                                                     */
  PROC SQL;
    CREATE TABLE &prefix._racecomb_order AS
      SELECT DISTINCT paramcd, avalc,
             CASE
               WHEN race='MULTIPLE' THEN 1
               ELSE 0
             END AS __multflag
      FROM &prefix._derive_race
      WHERE paramcd='RACECOMB' AND avalc NE ''
      ORDER BY CALCULATED __multflag, avalc;
  QUIT;

  DATA &prefix._racecomb_order2 (DROP=__:);
    RETAIN avalord 0;
    SET &prefix._racecomb_order;
      avalord = avalord + 1;
  RUN;

  PROC SQL;
    CREATE TABLE &prefix._derive AS
      SELECT r.*,
             CASE
               WHEN r.paramcd='RACEDET' THEN d.avalord
               WHEN r.paramcd='RACECOMB' THEN c.avalord
               ELSE .
             END AS avalord
      FROM &prefix._derive_race r LEFT JOIN &prefix._racedet_order2 d ON r.paramcd=d.paramcd AND
                                                                         r.avalc=d.avalc
                                  LEFT JOIN &prefix._racecomb_order2 c ON r.paramcd=c.paramcd AND
                                                                          r.avalc=c.avalc;
  QUIT;

  %let lastdset=&prefix._derive;


  /*
  / End of Domain specific derivations.
  / ---------------------------------------------------------------------------*/

  /* Calling tu_decode to apply code and decodes based on dataset plan and values of CODEPAIRS and DECODEPAIRS */

  %if %upcase(&decodeyn.) eq Y %then
  %do;
    %tu_decode(dsetin = &lastdset,
               dsetout = &prefix._decode,
               codepairs = &codepairs,
               decodepairs = &decodepairs,
               dsplan = &g_dsplanfile
               );

    %let lastdset=&prefix._decode;
  %end;

  /* Calling tu_attrib to apply the attributes to the variables in output dataset, if attributesyn parameter is Y. */

  %if %upcase(&attributesyn.) eq Y %then
  %do;
    %tu_attrib(dsetin = &lastdset,
               dsetout = &dsetout,
               dsplan = &g_dsplanfile
               );
  %end;
  /* Else if attributesyn parameter is N create output dataset */
  %ELSE %DO;
    DATA &dsetout;
      SET &lastdset;
    RUN;
  %END;

  /* If dataset contains observations check for missing values */
  %if %tu_nobs(&dsetout) gt 0 %then %do;
    %if %upcase(&misschkyn) eq Y %then
    %do;
      %tu_misschk(dsetin = &dsetout);
    %end;
  %end;

  /* Calling tu_tidyup to delete the temporary datasets. */

  %tu_tidyup(rmdset = &prefix.:,
             glbmac = none);

%mend tc_adrace;
