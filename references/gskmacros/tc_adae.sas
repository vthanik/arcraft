/******************************************************************************* 
| Program Name: tc_adae.sas
|
| Program Version: 3 build 3
|
| HARP Compound/Study/Reporting Effort: 
|
| Program Purpose: To create the ADaM dataset of AE domain using the SDTM AE
|                  and supplemental AE datasets.
|
| SAS Version: SAS v9.1.3
|
| Created By: Spencer Renyard (sr550750)
| Date:       5th March 2014
|
|******************************************************************************* 
|
| Output: adamdata.adae
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
| (@) tu_decode
| (@) tu_getformatnames
| (@) tu_putglobals
| (@) tu_misschk
| (@) tu_tidyup
| (@) tu_chkvarsexist
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
| Reason For Modification: The AESEV variable is permissible in SDTM so may not
|                          be present in input SDTM dataset (AE). Update code
|                          to check whether variable present.
|
| Modified By: Spencer Renyard (sr550750)
| Date of Modification: 5th August 2014
| New version/draft number: 2/2
| Modification ID: SR002
| Reason For Modification: When deriving the pre-treatment, on-treatment and
|                          follow-up flags use the analysis start date rather 
|                          than the source variable.
|
| Modified By: Spencer Renyard (sr550750)
| Date of Modification: 15th August 2014
| New version/draft number: 2/3
| Modification ID: SR003
| Reason For Modification: Metadata change: AEONGO now AONGO
|
| Modified By: Spencer Renyard (sr550750)
| Date of Modification: 22nd August 2014
| New version/draft number: 2/4
| Modification ID: SR004
| Reason For Modification: Add derivations of ADURN, ADURC, ADURC.
|                          Add parameter: DURATIONUNITS
|
| Modified By: Robert Croft (rlc25434)
| Date of Modification: 14th April 2015
| New version/draft number: 3/1
| Modification ID: RLC005
| Reason For Modification: Derive new adverse event occurrence flags: AOCC11FL,
|                          AOCC12FL, AOCC13FL, AOCC21FL, AOCC22FL, AOCC23FL, AOCC33FL,
|                          AOCC41FL, AOCC42FL and AOCC43FL
|
| Modified By: Robert Croft (rlc25434)
| Date of Modification: 20th April 2015
| New version/draft number: 3/2
| Modification ID: RLC006
| Reason For Modification: Addition of utility macro tu_getformatnames to derive new macro
|                          variables &asevnformat and &aetoxgrnformat, which will be used
|                          in derivation of numeric versions of ASEV and AETOXGR
|
| Modified By: Robert Croft (rlc25434)
| Date of Modification: 6th May 2015
| New version/draft number: 3/3
| Modification ID: RLC007
| Reason For Modification: ONTRTFLDAYS replaced by TRTEMFLDAYS parameter and ONTRTFL calculation
|                          replaced by TRTEMFL calculation
|
********************************************************************************/ 

%macro tc_adae(dsetin=sdtmdata.ae,         /* Input dataset */
               dsetout=adamdata.adae,      /* Output dataset to be created*/
               adsuppjoinyn=N,             /* If supplemental dataset is required to be joined with parent domain Y/N */
               dsetinsupp=sdtmdata.suppae, /* Input supplemental dataset */
               addatetimeyn=Y,             /* Flag to indicate if tu_addatetime utility is to be executed Y/N */
               datevars=aestdtc aeendtc,   /* Datetime variables in input dataset to be converted to numeric dates times datetimes*/
               getadslvarsyn=Y,            /* Flag to indicate if tu_adgetadslvars utility needs to be called Y/N */
               dsetinadsl=adamdata.adsl,   /* Input ADSL or ADTRT dataset */          
               adslvars=siteid age sex race acountry trtseq: trtsdt trtedt fasfl ittfl saffl pprotfl, /* List of variables from DSETINADSL dataset for tu_adgetadslvars utility to merge on by USUBJID*/
               adgettrtyn=Y,               /* Flag to indicate if tu_adgettrt utility is to be executed Y/N */
               adgettrtmergevars=USUBJID,  /* Variables used to merge treatment information from DSETINADSL onto work dataset */
               adgettrtvars=trt01p trt01pn trt01a trt01an, /* List of variables from treatment dataset DSETINADSL for tu_adgettrt utility to add to work dataset */
               decodeyn=Y,                 /* Flag to indicate if tu_decode utility is to be executed Y/N */
               decodepairs=,               /* A list of paired code/decode variables for which the decode is to be created*/ 
               codepairs=asevn asev aeoutn aeout, /* A list of paired code/decode variables for which the code is to be created*/
               adreldaysyn=Y,              /* Flag to indicate if tu_adreldays utility is to be executed Y/N */
               dyrefdatevar=,              /* Reference date variable for analysis relative days derivation: ADY, ASTDY, AENDY*/
               advisityn=N,                /* Flag to indicate if tu_advisit utility is to be executed Y/N */
               avisitnfmt=,                /* Format used to derive AVISITN from VISITNUM*/
               avisitfmt=,                 /* Format used to derive AVISIT from VISIT*/ 
               adperiodyn=N,               /* Flag to indicate if tu_adperiod utility is to be executed Y/N */
               trtemfldays=0,              /* Wash-out period (days) post-treatment for treatment emergent flag (default=0)*/
               fupfldays=0,                /* Wash-out period (days) post-treatment for follow-up flag (default=0)*/
               durationunits=Days,         /* Units to use for duration derivation (default=Days) */
               misschkyn=Y,                /* Flag to indicate if tu_misschk utility is to be executed Y/N */
               attributesyn=Y ,            /* Flag to indicate if tu_attrib utility is to be executed Y/N */
              );


  /*
  / Echo parameter values and global macro variables to the log.
  /----------------------------------------------------------------------------*/

  %local MacroVersion;
  %let MacroVersion = 3 build 3;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_dsplanfile) 

  /*
  /  Set up local macro variables
  / ---------------------------------------------------------------------------*/

  %local prefix domain lastdset;
  %let prefix = adae;
  %LET domain = AE;

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
  %let durationunits     = %nrbquote(%upcase(&durationunits)); /* SR004 */
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

  /* Validating ADDATETIMEYN, GETADSLVARSYN, ADGETTRTYN, ADVISITYN, ADPERIODYN, ADRELDAYSYN, DECODEYN, ATTRIBUTESYN and MISSCHKYN parameters */
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

  /* 06/05/15 RLC007: Validate TRTEMFLDAYS */
  %IF %BQUOTE(&trtemfldays) = %THEN %DO;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter TRTEMFLDAYS may not be null or blank.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %END;
  %ELSE %IF %datatyp(&trtemfldays) = CHAR %THEN %DO;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter TRTEMFLDAYS must be a numeric value.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %END;
  %ELSE %IF (%BQUOTE(&trtemfldays) NE %SYSFUNC(ABS(%SYSFUNC(INT(&trtemfldays))))) %THEN %DO;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter TRTEMFLDAYS must be zero or a positive integer.;
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

  /* Validate DURATIONUNITS */ /* SR004 */
  %IF (&durationunits NE DAYS) AND (&durationunits NE HOURS) AND (&durationunits NE YEARS) AND
      (&durationunits NE MONTHS) AND (&durationunits NE WEEKS) %THEN %DO;
    %PUT %str(RTE)RROR: &sysmacroname: DURATIONUNITS(=&durationunits) must be Days, Hours, Years, Months or Weeks.;
    %LET g_abort=1;
    %PUT RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %END;

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


  /* Calling tu_addatetime to convert character date to numeric date, time and datetime, if addatetimeyn parameter is Y */
  %if %upcase(&addatetimeyn) eq Y %then
  %do;
    %tu_addatetime(dsetin = &lastdset.,
                   dsetout = &prefix._date,
                   datevars = &datevars.
                   );

    /* Renaming event dates to ADaM variable naming conventions */
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


  /* Calling tu_advisit to reassign unscheduled visits */

  %if %upcase(&advisityn)=Y %then
  %do;
    %tu_advisit(dsetin = &lastdset.,
                dsetout = &prefix._visit,
                avisitfmt = &avisitfmt,
                avisitnfmt = &avisitnfmt
                );

    %let lastdset=&prefix._visit;
  %end;


  /* Calling tu_adperiod to assign period variables to records */

  %if %upcase(&adperiodyn)=Y %then
  %do;
    %tu_adperiod(dsetin = &lastdset.,
                 dsetout = &prefix._period,
                 dsetinadtrt = &dsetinadsl,
                 eventtype = SP
                 );

    %let lastdset=&prefix._period;
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


  /* Calling tu_adreldays to derive relative days */

  %if %upcase(&adreldaysyn)=Y %then
  %do;
    %tu_adreldays(dsetin = &lastdset,
                  dsetout = &prefix._reldays,
                  dyrefdatevar = &dyrefdatevar,
                  domaincode = &domain
                  );

    %let lastdset=&prefix._reldays;
  %end;


  /*
  / Domain specific derivations.
  / ---------------------------------------------------------------------------*/

  data &prefix._derive ;
    set &lastdset;
      %if %LENGTH(%tu_chkvarsexist(&lastdset,&domain.TPT)) LE 0 %then ATPT = &domain.TPT;;
      %if %LENGTH(%tu_chkvarsexist(&lastdset,&domain.TPTREF)) LE 0 %then ATPTREF = &domain.TPTREF;;
      %if %LENGTH(%tu_chkvarsexist(&lastdset,&domain.TPTNUM)) LE 0 %then ATPTN = &domain.TPTNUM;;

      * Create unique value for each record for use when deriving the AE occurrence flags ;
      _seqn = _n_;

      * Pre-treatment, Follow-up, Ongoing flags, plus create ADaM treatment emergent flag if not already present ;
      * Create ADaM ASEV if not present in dataset ;
      %IF %LENGTH(%tu_chkvarsexist(&lastdset,asev)) GE 1 AND %LENGTH(%tu_chkvarsexist(&lastdset,aesev))=0 %THEN
          asev = aesev;; *Default map is ASEV = AESEV from SDTM dataset; /* SR001 */

      * 06/05/15 RLC007: Create ADaM treatment emergent flag if not present in dataset ;
      %IF %LENGTH(%tu_chkvarsexist(&lastdset,trtemfl)) GE 1 %THEN %DO; *TRTEMFL not present in dataset, so create;
        IF NMISS(astdt,trtsdt,trtedt) = 0 AND (trtsdt LE astdt LE (trtedt + &trtemfldays)) THEN trtemfl = 'Y'; /* SR002 */
      %END;

      * Pre-treatment, Follow-up, Ongoing flags ;
      %IF %LENGTH(%tu_chkvarsexist(&lastdset,prefl)) GE 1 %THEN %DO; *PREFL not present in dataset, so create;
        IF NMISS(astdt,trtsdt) = 0 AND (astdt LT trtsdt) THEN prefl = 'Y'; /* SR002 */
      %END;

      %IF %LENGTH(%tu_chkvarsexist(&lastdset,fupfl)) GE 1 %THEN %DO; *FUPFL not present in dataset, so create;
        IF NMISS(astdt,trtedt) = 0 AND (astdt GT (trtedt + &fupfldays)) THEN fupfl = 'Y'; /* SR002 */
      %END;

      IF UPCASE(aeout) IN ('RECOVERING/RESOLVING' 'NOT RECOVERED/NOT RESOLVED') THEN aongo = 'Y'; /* SR003 */
      ELSE aongo = 'N'; /* SR003 */

      * Anaysis duration variables ; /* SR004 */
      IF NMISS(astdt,aendt) = 0 THEN DO;
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

          %IF %LENGTH(%tu_chkvarsexist(&lastdset,asttm)) LE 0 %THEN %DO;
            IF NMISS(asttm,aentm) = 0 THEN adurn = adurn + (aentm - asttm);
          %END;

          adurn = adurn / 3600;

          IF adurn = CEIL(adurn) THEN adurn = adurn + 1;
          ELSE adurn = CEIL(adurn);

        %END;

        IF adurn NE . THEN DO;
          aduru = "&durationunits";
          adurc = CATX(' ',adurn,aduru);
        END;
      END;
  run;

  %let lastdset=&prefix._derive;


  /*
  / Derive AE occurrence flags.
  / ---------------------------------------------------------------------------*/

  /* 20/04/15 RLC version 3 build 2: Add macro variables &asevnformat and &aetoxgrnformat in calculation of ASEVN
                                     and AETOXGRN */

  /* 20/04/15 RLC006: Call tu_getformatnames to create a dataset of formats */

  %tu_getformatnames(dsplan = &g_dsplanfile,
                     formatnamesdset = &prefix._formats
                     );

  %IF %LENGTH(%tu_chkvarsexist(&lastdset,asevn,Y))=0 AND %LENGTH(%tu_chkvarsexist(&lastdset,aesev,Y)) GE 1 %THEN %DO; /* SR001 */
    /* Derive numeric version of ASEV to use during sort - ASEVN should be ascending order of severity - using format defined */
    /* CDISC ADaM Data Structure for Adverse Event Analysis Version 1.0 - Low intensity should correspond to low value */
    %tu_decode(dsetin = &lastdset,
               dsetout = &prefix._asev,
               codepairs = asevn asev,
               dsplan = &g_dsplanfile);

    /* Check that ASEVN has been created, else abort */
    %IF %LENGTH(%tu_chkvarsexist(&prefix._asev,asevn,Y)) = 0 %THEN %DO;
      %put RTE%str(RROR:) &sysmacroname.: Variable ASEVN not derived correctly - check metadata.;
      %let g_abort = 1;
      %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
    %END;

    /* Aborting the execution */
    %if &g_abort eq 1 %then %do;
      %tu_abort;
    %end;

    /* 20/04/15 RLC006: Create macro variable &asevnformat to establish the format name in deriving ASEVN */

    PROC SQL noprint;
      SELECT compress(format_nm,".")
      INTO :asevnformat
      FROM &prefix._formats(where=(var_nm = 'ASEVN'));
    QUIT;

    /* Delete format from catalog so that main call to tu_decode further down works without error */
    PROC CATALOG CAT=work.formats;
      DELETE &asevnformat / ET=infmt;
    QUIT;

    %LET lastdset = &prefix._asev;
  %END;

  /* 14/04/15 RLC version 3 build 1: Add additional adverse event occurrence variables AOCC11FL-A0CC43FL */

  %IF %LENGTH(%tu_chkvarsexist(&lastdset,aetoxgrn,Y))=0 AND %LENGTH(%tu_chkvarsexist(&lastdset,aetoxgr,Y)) GE 1 %THEN %DO;
    /* Derive numeric version of AETOXGR to use during sort - AETOXGRN should be ascending order of toxicity - using format defined */
    /* CDISC ADaM Data Structure for Adverse Event Analysis Version 1.0 - Low toxicity should correspond to low value */
    %tu_decode(dsetin = &lastdset,
               dsetout = &prefix._aetoxgr,
               codepairs = aetoxgrn aetoxgr,
               dsplan = &g_dsplanfile);

    /* Check that AETOXGRN has been created, else abort */
    %IF %LENGTH(%tu_chkvarsexist(&prefix._aetoxgr,aetoxgrn,Y)) = 0 %THEN %DO;
      %put RTE%str(RROR:) &sysmacroname.: Variable AETOXGRN not derived correctly - check metadata.;
      %let g_abort = 1;
      %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
    %END;

    /* Aborting the execution */
    %if &g_abort eq 1 %then %do;
      %tu_abort;
    %end;

    /* 20/04/15 RLC006: Create macro variable &asevnformat to establish the format name in deriving ASEVN */

    PROC SQL noprint;
      SELECT compress(format_nm,".")
      INTO :aetoxgrnformat
      FROM &prefix._formats(where=(var_nm = 'AETOXGRN'));
    QUIT;

    /* Delete format from catalog so that main call to tu_decode further down works without error */
    PROC CATALOG CAT=work.formats;
      DELETE &aetoxgrnformat / ET=infmt;
    QUIT;

    %LET lastdset = &prefix._aetoxgr;
  %END;

  /* 14/04/15 RLC005: update to AEOCCFL macro to allow for SAE, Drug Related Events and Toxicity */

  %MACRO aeoccfl(varlist=/*Variable list for sort order*/,
                 serious=/*Serious adverse event occurence flags to be derived*/,
                 related=/*Drug related occurence flags to be derived*/,
                 occflvar=/*AE occurence flag variable name*/);

    %IF &serious. EQ N AND &related. EQ N %THEN %DO;
    
      /* Checking for presence of trtemFL variable to deteremine whether to subset the data */
      PROC SORT DATA=&lastdset
                 OUT=&prefix._&occflvar (KEEP=usubjid astdt asttm aesoc aedecod %IF %LENGTH(%tu_chkvarsexist(&lastdset,aesev,Y)) GE 1 %THEN asevn;
                                                                              %IF %LENGTH(%tu_chkvarsexist(&lastdset,aetoxgr,Y)) GE 1 %THEN aetoxgrn; _seqn); /* SR001 */
        BY &varlist;
        %IF %LENGTH(%tu_chkvarsexist(&lastdset,trtemfl,Y)) GE 1 %THEN %DO; *RLC007: Check whether treatment emergent flag is present and, if so, subset;
          WHERE trtemfl = 'Y';
        %END;
      RUN;

    %END;

    %ELSE %IF &serious. EQ Y AND &related. EQ N %THEN %DO;

      /* Checking for presence of TRTEMFL and AESER variables to deteremine whether to subset the data */
      PROC SORT DATA=&lastdset
                 OUT=&prefix._&occflvar (KEEP=usubjid astdt asttm aesoc aedecod %IF %LENGTH(%tu_chkvarsexist(&lastdset,aeser,Y)) GE 1 %THEN aeser; _seqn);
        BY &varlist;
        %IF %LENGTH(%tu_chkvarsexist(&lastdset,trtemfl,Y)) GE 1 %THEN %DO; *RLC007: Check whether treatment emergent flag is present and, if so, subset;
          WHERE trtemfl = 'Y' and aeser = 'Y';
        %END;
      RUN;

    %END;

    %ELSE %IF &serious. EQ N AND &related. EQ Y %THEN %DO;

      /* Checking for presence of TRTEMFL and AEREL variables to deteremine whether to subset the data */
      PROC SORT DATA=&lastdset
                 OUT=&prefix._&occflvar (KEEP=usubjid astdt asttm aesoc aedecod %IF %LENGTH(%tu_chkvarsexist(&lastdset,aerel,Y)) GE 1 %THEN aerel; _seqn);
        BY &varlist;
        %IF %LENGTH(%tu_chkvarsexist(&lastdset,trtemfl,Y)) GE 1 %THEN %DO; *RLC007: Check whether treatment emergent flag is present and, if so, subset;
          WHERE trtemfl = 'Y' and aerel = 'Y';
        %END;
      RUN;

    %END;  

    %ELSE %IF &serious. EQ Y AND &related. EQ Y %THEN %DO;

      /* Checking for presence of TRTEMFL, AESER and AEREL variables to deteremine whether to subset the data */
      PROC SORT DATA=&lastdset
                 OUT=&prefix._&occflvar (KEEP=usubjid astdt asttm aesoc aedecod %IF %LENGTH(%tu_chkvarsexist(&lastdset,aeser,Y)) GE 1 %THEN aeser;
                                                                              %IF %LENGTH(%tu_chkvarsexist(&lastdset,aerel,Y)) GE 1 %THEN aerel; _seqn);
        BY &varlist;
        %IF %LENGTH(%tu_chkvarsexist(&lastdset,trtemfl,Y)) GE 1 %THEN %DO; *RLC007: Check whether treatment emergent flag is present and, if so, subset;
          WHERE trtemfl = 'Y' and aeser = 'Y' and aerel = 'Y';
        %END;
      RUN;

    %END;    

    DATA &prefix._&occflvar (KEEP=usubjid _seqn &occflvar);
      SET &prefix._&occflvar;
        BY &varlist;
        IF FIRST.%SCAN(&varlist,&scannum);
        &occflvar = 'Y';
    RUN;

    PROC SORT DATA=&prefix._&occflvar;
      BY usubjid _seqn;
    RUN;
  %MEND aeoccfl;

  /* 14/04/15 RLC005: updates to macro calls to include new macro parameters */

  %LET scannum = -3;
  %aeoccfl(varlist=usubjid astdt asttm,
           serious=N,
           related=N,
           occflvar=aoccfl);
  %aeoccfl(varlist=usubjid aesoc astdt asttm,
           serious=N,
           related=N,
           occflvar=aoccsfl);
  %aeoccfl(varlist=usubjid aesoc aedecod astdt asttm,
           serious=N,
           related=N,
           occflvar=aoccpfl);

  %IF %LENGTH(%tu_chkvarsexist(&lastdset,aesev,Y)) GE 1 %THEN %DO; /* SR001 */
    %LET scannum = -5;
    %aeoccfl(varlist=usubjid DESCENDING asevn astdt asttm,
             serious=N,
             related=N,
             occflvar=aoccifl);
    %aeoccfl(varlist=usubjid aesoc DESCENDING asevn astdt asttm,
             serious=N,
             related=N,
             occflvar=aoccsifl);
    %aeoccfl(varlist=usubjid aesoc aedecod DESCENDING asevn astdt asttm,
             serious=N,
             related=N,
             occflvar=aoccpifl);
  %END; /* SR001 */

  /* 14/04/15 RLC005: Derivations of new variables AOCC11FL-AOCC43FL */

  %IF %LENGTH(%tu_chkvarsexist(&lastdset,aeser,Y)) GE 1 %THEN %DO;
    %LET scannum = -3;
    %aeoccfl(varlist=usubjid astdt asttm,
             serious=Y,
             related=N,
             occflvar=aocc11fl);
    %aeoccfl(varlist=usubjid aesoc astdt asttm,
             serious=Y,
             related=N,
             occflvar=aocc12fl);
    %aeoccfl(varlist=usubjid aesoc aedecod astdt asttm,
             serious=Y,
             related=N,
             occflvar=aocc13fl);
  %END; 

  %IF %LENGTH(%tu_chkvarsexist(&lastdset,aerel,Y)) GE 1 %THEN %DO;
    %LET scannum = -3;
    %aeoccfl(varlist=usubjid astdt asttm,
             serious=N,
             related=Y,
             occflvar=aocc21fl);
    %aeoccfl(varlist=usubjid aesoc astdt asttm,
             serious=N,
             related=Y,
             occflvar=aocc22fl);
    %aeoccfl(varlist=usubjid aesoc aedecod astdt asttm,
             serious=N,
             related=Y,
             occflvar=aocc23fl);
  %END;

  %IF %LENGTH(%tu_chkvarsexist(&lastdset,aerel,Y)) GE 1 AND %LENGTH(%tu_chkvarsexist(&lastdset,aeser,Y)) GE 1 %THEN %DO;
    %LET scannum = -3;
    %aeoccfl(varlist=usubjid astdt asttm,
             serious=Y,
             related=Y,
             occflvar=aocc31fl);
    %aeoccfl(varlist=usubjid aesoc astdt asttm,
             serious=Y,
             related=Y,
             occflvar=aocc32fl);
    %aeoccfl(varlist=usubjid aesoc aedecod astdt asttm,
             serious=Y,
             related=Y,
             occflvar=aocc33fl);
  %END;

  %IF %LENGTH(%tu_chkvarsexist(&lastdset,aetoxgr,Y)) GE 1 %THEN %DO;
    %LET scannum = -5;
    %aeoccfl(varlist=usubjid DESCENDING aetoxgrn astdt asttm,
             serious=N,
             related=N,
             occflvar=aocc41fl);
    %aeoccfl(varlist=usubjid aesoc DESCENDING aetoxgrn astdt asttm,
             serious=N,
             related=N,
             occflvar=aocc42fl);
    %aeoccfl(varlist=usubjid aesoc aedecod DESCENDING aetoxgrn astdt asttm,
             serious=N,
             related=N,
             occflvar=aocc43fl);
  %END;

  PROC SORT DATA=&lastdset
             OUT=&prefix._ae_occ_fl;
    BY usubjid _seqn;
  RUN;

  /* 14/04/15 RLC005: Update to data merge step to include new variable datasets */

  DATA &prefix._occfl (DROP=_seqn);
    MERGE &prefix._ae_occ_fl
          &prefix._aoccfl
          &prefix._aoccsfl
          &prefix._aoccpfl
          %IF %LENGTH(%tu_chkvarsexist(&lastdset,aesev))=0 %THEN %DO; /* SR001 */
            &prefix._aoccifl
            &prefix._aoccsifl
            &prefix._aoccpifl
          %END; /* SR001 */
          %IF %LENGTH(%tu_chkvarsexist(&lastdset,aeser))=0 %THEN %DO;
            &prefix._aocc11fl
            &prefix._aocc12fl
            &prefix._aocc13fl
          %END;
          %IF %LENGTH(%tu_chkvarsexist(&lastdset,aerel))=0 %THEN %DO;
            &prefix._aocc21fl
            &prefix._aocc22fl
            &prefix._aocc23fl
          %END;
          %IF %LENGTH(%tu_chkvarsexist(&lastdset,aeser aerel))=0 %THEN %DO;
            &prefix._aocc31fl
            &prefix._aocc32fl
            &prefix._aocc33fl
          %END;
          %IF %LENGTH(%tu_chkvarsexist(&lastdset,aetoxgr))=0 %THEN %DO;
            &prefix._aocc41fl
            &prefix._aocc42fl
            &prefix._aocc43fl
          %END;
          ;
      BY usubjid _seqn;
  RUN;

  /* 14/04/15 RLC005: End of new code */
  
  %LET lastdset=&prefix._occfl;


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
      %tu_misschk(dsetin=&dsetout);
    %end;
  %end;

  /* Calling tu_tidyup to delete the temporary datasets. */

  %tu_tidyup(rmdset = &prefix.:,
             glbmac = none);

%mend tc_adae;
