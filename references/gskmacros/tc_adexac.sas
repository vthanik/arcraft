/******************************************************************************* 
| Program Name: tc_adexac.sas
|
| Program Version: 1 build 2
|
| HARP Compound/Study/Reporting Effort: 
|
| Program Purpose: To create the ADaM dataset of Exacerbations domain using the SDTM CE
|                  and supplemental CE dataset.
|
| SAS Version: SAS v9.3
|
| Created By: Robert Croft (rlc25434)
| Date:       22/10/2014
|
|******************************************************************************* 
|
| Output: adamdata.adexac
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
| (@) tu_decode
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_misschk
| (@) tu_tidyup
| (@) tu_chknames
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
| Modified By: Robert Croft (rlc25434)
| Date of Modification: 27/03/15
| New version/draft number: version 1 build 2
| Modification ID: RLC001
| Reason For Modification: Addition of calculations of ASTTM, AENTM, ASTDTM and AENDTM
|                          in case such variables exist in SDTMDATA.CE
|
********************************************************************************/ 
%macro tc_adexac(dsetin=sdtmdata.ce (where=(index(upcase(cecat), 'EXACERBATION'))), /* Input dataset SDTMDATA.CE */
               dsetout=adamdata.adexac,    /* Output dataset to be created */
               adsuppjoinyn=Y,             /* If supplemental dataset is required to be joined with parent domain Y/N */
               dsetinsupp=sdtmdata.suppce, /* Input supplemental dataset SDTMDATA.SUPPCE */
               dsetincm=sdtmdata.cm,       /* Input concomitant medications dataset SDTMDATA.CM */
               dsetinsuppcm=sdtmdata.suppcm, /* Input supplemental concomitant medications dataset SDTMDATA.SUPPCM */
               dsetinface=sdtmdata.face,   /* Input findings about clinical events dataset SDTMDATA.FACE */
               dsetinhu=sdtmdata.hu,       /* Input healthcare utilisation dataset SDTMDATA.HU */
               addatetimeyn=Y,             /* Flag to indicate if If tu_addatetime utility is to be executed Y/N */
               datetimevars=cestdtc ceendtc, /* Datetime variables in input dataset to be converted to numeric dates times datetimes*/
               getadslvarsyn=Y,            /* Flag to indicate if tu_adgetadslvars utility need to be called */
               dsetinadsl=adamdata.adsl,   /* Input ADSL or ADTRT dataset */          
               adslvars=siteid age sex race acountry trtsdt trtedt complfl fasfl ittfl saffl pprotfl, /* List of variable from DSETINADSL dataset for tu_adgetadslvars utility to merge on by USUBJID*/
               adgettrtyn=Y,               /* Flag to indicate if tu_adgettrt utility is to be executed Y/N */
               adgettrtmergevars=usubjid,  /* Variables used to merge treatment information from DSETINADSL onto work dataset */
               adgettrtvars=trt01p trt01pn trt01a trt01an,  /* List of variables from treatment dataset DSETINADSL for tu_adgettrt utility to add to work dataset */
               decodeyn=N,                 /* Flag to indicate if tu_decode utility is to be executed Y/N */
               decodepairs=,               /* A list of paired code/decode variables for which the decode is to be created*/ 
               codepairs=,                 /* A list of paired code/decode variables for which the code is to be created*/
               adreldaysyn=Y,              /* Flag to indicate if tu_adreldays utility is to be executed*/
               dyrefdatevar=,              /* Reference date variable for analysis relative days derivation: ADY, ASTDY, AENDY*/
               advisityn=N,                /* Flag to indicate if tu_advisit utility is to be executed Y/N */
               avisitnfmt=,                /* Format used to derive AVISITN from VISITNUM*/
               avisitfmt=,                 /* Format used to derive AVISIT from VISIT*/ 
               adperiodyn=N,               /* Flag to indicate if tu_adperiod utility is to be executed Y/N */
               durationunits=DAYS,         /* Units to be used in calculating analysis duration variables */
               misschkyn=Y,                /* Flag to indicate if tu_misschk utility is to be executed Y/N */
               attributesyn=Y,             /* Flag to indicate if tu_attrib utility is to be executed Y/N */
               ontrtflyn=Y,                /* Flag to indicate if On-treatment, Post-treatment and follow-up flags will be derived */
               ontrtfldays=0,              /* Number of days for Wash-out period to add to last date of treatment */
               collapseyn=Y,               /* Flag to indicate if collapsing of exacerbation observations will be executed Y/N */
               collapsedays=0              /* Number of days used in derivation of collapsing exacerbations that occur 'X' days apart */
               );


  /*
  / Echo parameter values and global macro variables to the log.
  /----------------------------------------------------------------------------*/

  %local MacroVersion;
  %let MacroVersion = 1 build 2;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_dsplanfile g_abort g_refdata);

  /*
  /  Set up local macro variables
  / ---------------------------------------------------------------------------*/

  %local prefix lastdset domain dsetinlist loopi thisdset;   
  %let prefix = _adexac;
  %let domain=CE;
  %let dsetinlist=DSETINCM DSETINFACE DSETINHU;

  /*
  / PARAMETER VALIDATION
  /----------------------------------------------------------------------------*/

  %let dsetin            = %nrbquote(&dsetin.);
  %let dsetout           = %nrbquote(&dsetout.);
  %let adsuppjoinyn      = %nrbquote(%upcase(&adsuppjoinyn.));
  %let dsetincm          = %nrbquote(&dsetincm.);
  %let dsetinface        = %nrbquote(&dsetinface.);
  %let dsetinhu          = %nrbquote(&dsetinhu.);
  %let addatetimeyn      = %nrbquote(%upcase(&addatetimeyn.));
  %let getadslvarsyn     = %nrbquote(%upcase(&getadslvarsyn.));
  %let adgettrtyn        = %nrbquote(%upcase(&adgettrtyn.));
  %let advisityn         = %nrbquote(%upcase(&advisityn.));
  %let adperiodyn        = %nrbquote(%upcase(&adperiodyn.));
  %let adreldaysyn       = %nrbquote(%upcase(&adreldaysyn.));
  %let decodeyn          = %nrbquote(%upcase(&decodeyn.));
  %let attributesyn      = %nrbquote(%upcase(&attributesyn.));
  %let misschkyn         = %nrbquote(%upcase(&misschkyn.));
  %let durationunits     = %nrbquote(%upcase(&durationunits.));
  %let ontrtflyn         = %nrbquote(%upcase(&ontrtflyn.));
  %let collapseyn        = %nrbquote(%upcase(&collapseyn.));


  /* Validating if non-missing values are provided for parameters DSETIN, DSETINCM, DSETINFACE, DSETINHU and DSETOUT */

  %if &dsetin. eq %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETIN is a required parameter, provide a dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %do loopi=1 %to %tu_words(&dsetinlist);
    %let thisdset=%scan(&dsetinlist, &loopi, %str( ));
      %if &&&thisdset eq %str() %then
      %do;
        %put RTE%str(RROR:) &sysmacroname.: Macro Parameter &thisdset is a required parameter, provide a dataset name.;
        %let g_abort = 1;
        %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
      %end;
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

  /* calling tu_chknames to validate name provided in DSETINCM, DSETINFACE, DSETINHU parameters */
  %do loopi=1 %to %tu_words(&dsetinlist);
    %let thisdset=%scan(&dsetinlist, &loopi, %str( ));
    %if %nrbquote(&&&thisdset) ne %then %do;
      %if %tu_chknames(%scan(&&&thisdset, 1, %str(%() ), DATA ) ne %then %do;
        %put RTE%str(RROR:) &sysmacroname.: Macro parameter &thisdset refers to dataset &&&thisdset which is not a valid dataset name;
        %let g_abort = 1;
        %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
      %end;
    %end;
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

  /* Validating if DSETINCM, DSETINFACE, DSETINHU datasets exist */
  %do loopi=1 %to %tu_words(&dsetinlist);
    %let thisdset=%scan(&dsetinlist, &loopi, %str( ));
    %if %nrbquote(&&&thisdset) ne %then %do;
      %if %SYSFUNC(EXIST(%scan(&&&thisdset, 1, %str(%() ) )) NE 1 %then %do;
        %put RTE%str(RROR:) &sysmacroname.: Macro parameter &thisdset refers to dataset %upcase("&&&thisdset.") which does not exist.;
        %let g_abort = 1;
        %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
      %end;
    %end;
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

  /* Validating ADSUPPJOINYN, ADDATETIMEYN, GETADSLVARSYN, ADGETTRTYN, ADVISITYN, ADPERIODYN, ADRELDAYSYN, 
     DECODEYN, ATTRIBUTESYN, MISSCHKYN, DURATIONUNITS, ONTRTFLYN, ONTRTFLDAYS, COLLAPSEYN and COLLAPSEDAYS parameters */   
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

  %if &durationunits. ne YEARS and &durationunits. ne MONTHS and &durationunits. ne WEEKS and &durationunits. ne DAYS and &durationunits. ne HOURS %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DURATIONUNITS should either be YEARS, MONTHS, WEEKS, DAYS or HOURS.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &ontrtflyn. ne Y and &ontrtflyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ONTRTFLYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &collapseyn. ne Y and &collapseyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter COLLAPSEYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Validating ONTRTFLDAYS */

  %if %upcase(&ontrtflyn) = Y %then %do; 
    %if %bquote(&ontrtfldays) eq %str() %then %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ONTRTFLDAYS may not be null or blank.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
    %end;
    %else %if %datatyp(&ontrtfldays) = CHAR %then %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ONTRTFLDAYS must be a numeric value.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
    %end;
    %else %if %bquote(&ontrtfldays) ne %str() and (%bquote(&ontrtfldays) ne %sysfunc(abs(%sysfunc(int(&ontrtfldays))))) %then %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ONTRTFLDAYS must be zero or a positive integer.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
    %end;
  %end;

  /* Validating COLLAPSEDAYS */

  %if %upcase(&collapseyn) = Y %then %do; 
    %if %bquote(&collapsedays) eq %str() %then %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter COLLAPSEDAYS may not be null or blank.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
    %end;
    %else %if %datatyp(&collapsedays) = CHAR %then %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter COLLAPSEDAYS must be a numeric value.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
    %end;
    %else %if %bquote(&collapsedays) ne %str() and (%bquote(&collapsedays) ne %sysfunc(abs(%sysfunc(int(&collapsedays))))) %then %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter COLLAPSEDAYS must be zero or a positive integer.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
    %end;
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
                   datevars = &datetimevars.
                   );

    /* Deriving event dates to ADaM variable naming conventions */
    /* RLC001: Addition of derivation of ASTTM, AENTM, ASTDTM and AENDTM */
    data &prefix._daterename;
    set &prefix._date;
    %if %tu_chkvarsexist(&prefix._date,&domain.STDT)=%str() %then ASTDT=&domain.STDT;;
    %if %tu_chkvarsexist(&prefix._date,&domain.STTM)=%str() %then ASTTM=&domain.STTM;;
    %if %tu_chkvarsexist(&prefix._date,&domain.STDTM)=%str() %then ASTDTM=&domain.STDTM;;
    %if %tu_chkvarsexist(&prefix._date,&domain.ENDT)=%str() %then AENDT=&domain.ENDT;;
    %if %tu_chkvarsexist(&prefix._date,&domain.ENTM)=%str() %then AENTM=&domain.ENTM;;
    %if %tu_chkvarsexist(&prefix._date,&domain.ENDTM)=%str() %then AENDTM=&domain.ENDTM;;

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


  /* Calling tu_adperiod to bring in either APERIOD/APERIODC or TPERIOD/TPERIODC from ADTRT dataset in XO studies */

  %if %upcase(&adperiodyn)=Y %then
  %do;
    %tu_adperiod(dsetin = &lastdset.,
                 dsetout = &prefix._period,
                 dsetinadtrt = &dsetinadsl.,
                 eventtype= SP             
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

  /* Retrieve flags from "findings about" domain */

   %if %length(%tu_chkvarsexist(&dsetinface., fagrpid)) eq 0 and %length(%tu_chkvarsexist(&lastdset., &domain.grpid)) eq 0 %then
   %do;

   proc sort data=&dsetinface. out=&prefix._dsetinface;
     by usubjid fagrpid;
   run;

   proc transpose data = &prefix._dsetinface (where = (upcase(faobj) eq 'ASTHMA EXACERBATION' and
                                                upcase(facat) eq 'ASTHMA EXACERBATION'))
                  out  = &prefix._face (rename = (fagrpid = &domain.grpid)
                                        drop = _:);
     by usubjid fagrpid;
     id fatestcd;
     var faorres;
   run;

  /* Combine all variables by subject and event ID */

   proc sort data=&lastdset.;
     by usubjid &domain.grpid;
   run;

   data &prefix._derive;
     merge &lastdset. (in=a) &prefix._face;
     by usubjid &domain.grpid;
     if a;
   run;

   %let lastdset = &prefix._derive;

   %end;

  /* Retrieve healthcare utilisation variables */

   %if %length(%tu_chkvarsexist(&dsetinhu., hugrpid)) eq 0 and %length(%tu_chkvarsexist(&lastdset., &domain.grpid)) eq 0 %then
   %do;

   proc sort data=&dsetinhu. out=&prefix._dsetinhu;
     by usubjid hugrpid;
   run;

   proc transpose data = &prefix._dsetinhu (where = (upcase(hucat) eq 'EXACERBATION DETAILS'))
                  out = &prefix._hu (rename = (hugrpid = &domain.grpid)
                            drop = _:);
     by usubjid hugrpid;
     id hutestcd;
     var hustresn;
   run;

  /* Combine all variables by subject and event ID */

   proc sort data=&lastdset.;
     by usubjid &domain.grpid;
   run;

   data &prefix._derive2;
     merge &lastdset. (in=a) &prefix._hu;
     by usubjid &domain.grpid;
     if a;

    /* Summarize for total day/night measures */

   %if %length(%tu_chkvarsexist(&prefix._hu, hmdyvsn hmntvsn)) eq 0 %then
   %do;
    hmdyntv = sum(hmdyvsn, hmntvsn);
   %end;
   %if %length(%tu_chkvarsexist(&prefix._hu, gwdynum icudynum)) eq 0 %then
   %do;
    hspdynum = sum(gwdynum, icudynum);
   %end;

   run;

   %let lastdset = &prefix._derive2;

   %end;

   /* Create analysis duration and analysis category variables */

   data &prefix._derive3;
     set &lastdset.;

     if nmiss(astdt,aendt) = 0 then do;
     %if &durationunits. eq YEARS %then %do;
       
       adurn = intck('year', astdt, aendt+1) - ((month(aendt+1) lt month(astdt)) or
                                               ((month(aendt+1) eq month(astdt)) and (day(aendt+1) lt day(astdt))));
     %end;

     %else %if &durationunits. eq MONTHS %then %do;

       adurn = ((year(aendt+1) - year(astdt))* 12) + (month(aendt+1) - month(astdt) - 1) + (day(aendt+1) ge day(astdt));
       
     %end;
     
     %else %if &durationunits. eq WEEKS %then %do;
     
       adurn = ((aendt+1) - astdt)/ 7;
       
     %end;
     
     %else %if &durationunits. eq DAYS %then %do;
     
       adurn = (aendt+1) - astdt;
       
     %end;
     
     %else %if &durationunits. eq HOURS %then %do;
     
       adurn = (aendt - astdt)* 3600 * 24; /* convert to seconds */

       %if %length(%tu_chkvarsexist(&lastdset,asttm)) le 0 %then %do;
         if nmiss(asttm,aentm) = 0 then adurn = adurn + (aentm - asttm);
       %end;

       adurn = adurn / 3600;

       if adurn ne ceil(adurn) then adurn = ceil(adurn);

     %end;

     if adurn ne . then do;
       
       aduru = "&durationunits.";

     end;

     end;

    /* ANL01FL = 'Y' for all exacerbations in the CRF */

    ANL01FL = 'Y';

   run;

   %let lastdset=&prefix._derive3;

  /* Derive On-Treatment and Post-treatment flags */

  %if %upcase(&ontrtflyn)=Y %then 
  %do;

    data &prefix._ontrt;
      set &lastdset;

      %if %length(%tu_chkvarsexist(&lastdset,ontrtfl)) ge 1 %then %do;
        if nmiss(astdt,trtsdt,trtedt) = 0 and (trtsdt le astdt le (trtedt + &ontrtfldays)) then ontrtfl = 'Y';
      %end;

      %if %length(%tu_chkvarsexist(&lastdset,postrtfl)) ge 1 %then %do;
        if nmiss(astdt,trtedt) = 0 and (astdt gt (trtedt + &ontrtfldays)) then postrtfl = 'Y';
      %end;

    run;

    %let lastdset = &prefix._ontrt;

  %end;

  /* Deriving OCSEXB variable */

  /* Combine cm with the cm supplemental data to retrieve CMDRGCOL */

  %if %length(%tu_chkvarsexist(&dsetincm., cmrefid)) eq 0 and %length(%tu_chkvarsexist(&lastdset., &domain.refid)) eq 0 %then
  %do;
  
    %tu_adsuppjoin(dsetin=&dsetincm,
                 dsetinsupp=&dsetinsuppcm,
                 dsetout=&prefix._cm1
                 );

    /* Pull ATC information from the dictionary, this joins up to six ATC codes to each record */
  
    proc sql noprint;
       create table &prefix._gskdrug1 as
       select cmdrgcol, cmatccd as dclc, cmatc1 as dcl1t, cmatc2 as dcl2t, cmatc3 as dcl3t, cmatc4 as dcl4t
       from diction.gskdrug
       where cmdrgcol in (select distinct cmdrgcol from &prefix._cm1)
       and   cmnc eq 'C'
       order by cmdrgcol, dclc;
    quit;
  
    data &prefix._gskdrug2;
       set &prefix._gskdrug1;
       by cmdrgcol dclc;
  
       if first.dclc;

       rename cmdrgcol=_drgcol1;
    run;
  
    proc sql noprint;
       create table &prefix._cm2 (drop = _drgcol1) as
       select a.*, b.*
       from &prefix._cm1 as a left join &prefix._gskdrug2 as b
       on  a.cmdrgcol eq b._drgcol1;
    quit;
  
  
    /* Identify all corticosteroids from Conmeds data */

    data &prefix._allcorts;
      set &prefix._cm2;
      array atc $ dcl2t dcl3t dcl4t;
      do over atc;
        IF INDEX(UPCASE(atc),'CORTICOSTEROID') AND INDEX(UPCASE(atc),'EXCLUDING CORTICOSTEROID')=0 AND
           INDEX(UPCASE(atc),'EXCL. CORTICOSTEROID')=0 AND INDEX(UPCASE(dcl1t),'DERMATOLOGICAL')=0 AND
           INDEX(UPCASE(dcl3t),'EXCL. COMBINATIONS WITH CORTICOSTEROIDS')=0 AND
           INDEX(UPCASE(dcl1t),'SENSORY ORGAN')=0  or cmdecod = 'STEROIDS NOS' THEN 
             csgrp='Corticosteroid'; 

    end;

    if csgrp ne '';
    run;

    /* Subset conmeds for OCS */

    data &prefix._allcorts2; 
      set &prefix._allcorts;

      if csgrp='Corticosteroid' and index(upcase(compress(cmroute)),'INHALATION')>0 then cmroutgp=catx(' - ',csgrp,'Inhaled');    
      else if csgrp='Corticosteroid' and upcase(compress(cmroute)) in ('ORAL', 'SUBLINGUAL')then cmroutgp=catx(' - ',csgrp,'Oral');    
      else if csgrp='Corticosteroid' and upcase(compress(cmroute)) in  ('SUBCUTANEOUS', 'INTRAVENOUS', 'INTRAMUSCULAR', 'INJECTION') then cmroutgp=catx(' - ',csgrp,'Parenteral'); 
      else if csgrp='Corticosteroid' then cmroutgp=catx(' - ',csgrp,'Other');
  
    /* Subset for only OCS and Systemic corticosteroids */
    if cmroutgp  in ( 'Corticosteroid - Oral') or (cmroutgp  in ( 'Corticosteroid - Parenteral') and cmroute in ('INTRAVENOUS' ,'INTRAMUSCULAR' )); 
  
    if compress(upcase(cmdecod)) in ('FLUTICASONE',  'FLUTICASONEPROPIONATE' , 'MOMETASONEFUROATE') then delete;       
    run;

    proc sort data = &prefix._allcorts2 (where = (index(upcase(cmroutgp), 'ORAL'))
                                       keep = usubjid cmrefid cmroutgp cmindc)
              out = &prefix._unique_ocs (drop = cmroutgp)
            nodupkey;
      by usubjid cmrefid;
    run;

    proc sort data = &lastdset.;
      by usubjid cerefid;
    run;

    data &prefix._ocs;
      merge &lastdset. (in = a)
          &prefix._unique_ocs (in = b
                      rename = (cmrefid = cerefid));
      by usubjid cerefid;

      if a;

      if b then ocsexb = 'Y';
      else ocsexb = 'N';

      if cmindc = '' then ocsexb = 'N';

    run;

    %let lastdset = &prefix._ocs;

  %end;

  /* Collapse exacerbations that occurred less than 7 days apart */

  %if %upcase(&collapseyn)=Y %then 
  %do;

    /* Collapsing is done within RCDST so as to keep clinically
       significant and investigator defined summaries separate.
  
       Algorithm for collapsing other CRF variables:
       ASTDT = ASTDT of first exacerbation in the series
       AENDT = AENDT of last exacerbation in the series
       ASTDY = ASTDY of first exacerbation in the series
       AENDY = AENDY of last exacerbation in the series
       CEOUT = "Worst" outcome in the series 
             (worst to best: Fatal, Not Resolved, Resolved)
       EBCAUSE = EBCAUSE of first exacerbation in the series
       EBWD, OCSEXB, CTSEXB, HSPEXB, EREXB, INTUBEXB = "Y" if any 
       value in the series = "Y"
       TPCNUM, HMDYVSN, HMNTVSN, HMDYNTV, OFCVSN, UCOUTVSN, ERVSN, 
       ICUDYNUM, GWDYNUM, HSPDYNUM = sum of values in the series
       for each variable */

    /* Put the onset and resolution dates from each subsequent record  
       on the record prior to it */
  
    proc sort data = &lastdset;
      by usubjid rcdst descending astdt descending aendt;
    run;
  
    data &prefix._exac;
      set &lastdset;
      by usubjid rcdst descending astdt descending aendt;
    
      next_astdt = lag(astdt);
      next_aendt = lag(aendt);
      next_astdy = lag(astdy);
      next_aendy = lag(aendy);
    
      if first.rcdst then do;
        next_astdt = .;
        next_aendt = .;
        next_astdy = .;
        next_aendy = .;
      end;
    run;
         
    proc sort data = &prefix._exac;
      by usubjid rcdst astdt aendt;
    run;

    /* Generate the collapsed records (output is ONLY the collapsed
       records) */

    data &prefix._collapsed (drop = ceseq anl01fl adurn aduru);
      set &prefix._exac;
      by usubjid rcdst astdt aendt;

      length _ceout $40 _ebcause $80 _ebwd _ocsexb _ctsexb _hspexb _erexb _intubexb $1;
      retain _ceout _ebcause _ebwd _ocsexb _ctsexb _hspexb _erexb _intubexb
             _tpcnum _hmdyvsn _hmntvsn _hmdyntv _ofcvsn _ucoutvsn _ervsn _icudynum _gwdynum _hspdynum 
             _astdt _astdy overlap_astdt overlap_aendt overlap_astdy overlap_aendy;
                                              
      array  ynvar $  ebwd  ocsexb  ctsexb  hspexb  erexb  intubexb;
      array _ynvar $ _ebwd _ocsexb _ctsexb _hspexb _erexb _intubexb;
      array  numvar   tpcnum  hmdyvsn  hmntvsn  hmdyntv  ofcvsn  ucoutvsn  ervsn  icudynum  gwdynum  hspdynum;
      array _numvar  _tpcnum _hmdyvsn _hmntvsn _hmdyntv _ofcvsn _ucoutvsn _ervsn _icudynum _gwdynum _hspdynum;

      if first.rcdst then series_count = .;
    
      if not(missing(overlap_astdt)) then do;
        astdt = overlap_astdt;
        aendt = overlap_aendt;
        astdy = overlap_astdy;
        aendy = overlap_aendy;
      end;
    
      /* Nested exacerbations */
      if (. < astdt <= next_astdt and . < next_aendt <= aendt) then do;
        overlap_astdt = astdt;
        overlap_aendt = aendt;
        overlap_astdy = astdy;
        overlap_aendy = aendy;
      end;
    
      else do;
        overlap_astdt = .;
        overlap_aendt = .;
        overlap_astdy = .;
        overlap_aendy = .;
      end;
           
      /* Next exacerbation is less than x days from this one or the next
        record is overlapped by the current set of dates -- set retained values
        to hold for processing of the next record */
      if (. < (next_astdt - aendt) < &COLLAPSEDAYS) or not(missing(overlap_astdt)) then do;
        if series_count = . then do;
      
          series_count = 0;
        
          if not(missing(overlap_astdt)) then _astdt = overlap_astdt;
          else _astdt = astdt;

          if not(missing(overlap_astdy)) then _astdy = overlap_astdy;
          else _astdy = astdy;

          /* EBCAUSE from first record in the series */
          _ebcause = ebcause;
      
        end;
    
        link collapse_vars;
      end;  
    
      /* Next exacerbation is either at least x days from this one, 
        or this record is a continuation of an existing series that
        is being collapsed */
      else do;
    
        /* Not part of an on-going series */
        if series_count = . then delete;
      
        /* Part of an on-going series -- add the current variables to the mix and output */
        else do;
        
          link collapse_vars;

          /* Assign the retained values to the real variables */
          astdt = _astdt;
          astdy = _astdy;
          ebcause = _ebcause;
          ceout = _ceout;

          do over ynvar;
            ynvar = _ynvar;
          end;

          do over numvar;
            numvar = _numvar;
          end;

          /* Collapsed records to be made available for summaries */
          anl02fl = 'Y';
          colapsfl = 'Y';
          cestdtc = '';
          ceendtc = '';

          output;  
        
          series_count = .;
        end;
      
        /* Reset the retained variables for the next series */
        _ebcause = '';
        _ceout = '';

        do over _ynvar;
          _ynvar = '';
        end;

        do over _numvar;
          _numvar = .;
        end;

      end;
    
      return;
            
      collapse_vars:
      
        series_count + 1;
      
        /* Take worst outcomes in the series (worst to best: 'FATAL', 'NOT RESOLVED', 'RESOLVED') */
        if upcase(ceout) = 'FATAL' then _ceout = ceout;
        else if upcase(ceout) =: 'NOT' and _ceout ne 'FATAL' then _ceout = ceout;
        else if missing(_ceout) then _ceout = ceout;
      
        /* For these parameters, set to Y if any in the series are Y */
        do over ynvar;
          if ynvar eq 'Y' then _ynvar = 'Y';
          else if missing(_ynvar) then _ynvar = ynvar;
        end;
      
        /* For these parameters, sum values over the entire series */
        do over numvar;
          _numvar = sum(_numvar, numvar);
        end;
    
      return;

      drop _: overlap_: series_count;
    run; 
    
    /* For Collapsed records, ADURN and ADURU are calculated for the new collapsed period */
    
    data &prefix._collapsed_2;
      set &prefix._collapsed;
      
        %if &durationunits. eq YEARS %then %do;
       
          adurn = intck('year', astdt, aendt+1) - ((month(aendt+1) lt month(astdt)) or
                                                  ((month(aendt+1) eq month(astdt)) and (day(aendt+1) lt day(astdt))));
        %end;

        %else %if &durationunits. eq MONTHS %then %do;

          adurn = ((year(aendt+1) - year(astdt))* 12) + (month(aendt+1) - month(astdt) - 1) + (day(aendt+1) ge day(astdt));
       
        %end;
     
        %else %if &durationunits. eq WEEKS %then %do;
     
          adurn = ((aendt+1) - astdt)/ 7;
       
        %end;
     
        %else %if &durationunits. eq DAYS %then %do;
     
          adurn = (aendt+1) - astdt;
       
        %end;
     
        %else %if &durationunits. eq HOURS %then %do;
     
          adurn = (aendt - astdt)* 3600 * 24; /* convert to seconds */

          adurn = adurn / 3600;

          if adurn ne ceil(adurn) then adurn = ceil(adurn);

        %end;

        if adurn ne . then do;
       
          aduru = "&durationunits.";

        end;
    run;


    /* Flag the recorded events that will be used in summaries --
       all but those from which the collapsed records were
       formed */

    proc sql;
      create table &prefix._recexac as
        select e.*, case
                      when (&prefix._collapsed_2 ne 'Y') then 'Y'
                      else ' '
                    end as anl02fl
        from &prefix._exac as e 
             left join 
             (select usubjid, rcdst, astdt, aendt, astdy, aendy, adurn, aduru, 'Y' as &prefix._collapsed_2
              from &prefix._collapsed_2) as c
        on e.usubjid eq c.usubjid and 
           e.rcdst eq c.rcdst and
           (e.astdt eq c.astdt or e.aendt eq c.aendt);
    quit;


    /* Combine the recorded events and the newly collapsed
       records */

    data &prefix._final;
      set &prefix._recexac
          &prefix._collapsed_2;
      drop next_:;
    run;

    %let lastdset = &prefix._final;

  %end;

  /* End of domain specific code */

  /* Calling tu_decode to derive codes or decodes using formats specified in &g_dsplanfile */

  %if %upcase(&decodeyn.) eq Y %then
  %do;
    %tu_decode (dsetin = &lastdset.,
                dsetout= &prefix._decode,
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

  %end;
  %else %do;
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

%mend tc_adexac;
