/******************************************************************************* 
| Program Name: tc_adliver.sas
|
| Program Version: 1 build 1
|
| HARP Compound/Study/Reporting Effort: 
|
| Program Purpose: To create the ADaM dataset of ADLIVER domain using the SDTM
|                  CE, FACE, QS, MI, XI domain datasets and CE, QS, XI
|                  supplemental datasets.
|
| SAS Version: SAS v9.3
|
| Created By: Anthony J Cooper
| Date:       11-Nov-2014
|
|******************************************************************************* 
|
| Output: adamdata.adliver
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
| (@) tu_words
| (@) tu_chkvarsexist
| (@) tu_chknames
| (@) tu_times
| (@) tu_adappend
|
| Metadata:
|
|
|******************************************************************************* 
| Change Log 
|
| Modified By: 
| Date of Modification: 
| New version/draft number: 
| Modification ID: 
| Reason For Modification: 
|
********************************************************************************/ 

%macro tc_adliver(
               dsetince=sdtmdata.ce(where=(cecat='LIVER EVENT')), /* Input Liver Event dataset */
               dsetinface=sdtmdata.face(where=(facat='LIVER EVENT')), /* Input Findings About Liver Event dataset */
               dsetinqs=sdtmdata.qs(where=(qscat='RUCAM')), /* Input RUCAM dataset */
               dsetinmi=sdtmdata.mi(where=(micat='LIVER BIOPSY')), /* Input Liver Biopsy dataset */
               dsetinxi=sdtmdata.xi(where=(xicat='LIVER IMAGING')), /* Input Liver Imaging dataset */
               dsetinex=sdtmdata.ex,       /* Input Exposure dataset */
               dsetout=adamdata.adliver,   /* Output dataset to be created*/
               adsuppjoinyn=Y,             /* If supplemental dataset is required to be joined with parent domain Y/N */
               dsetinsuppce=sdtmdata.suppce, /* Input Liver Event supplemental dataset */
               dsetinsuppqs=sdtmdata.suppqs, /* Input RUCAM supplemental dataset */
               dsetinsuppxi=sdtmdata.suppxi, /* Input Liver Imaging supplemental dataset */
               addatetimeyn=Y,             /* Flag to indicate if If tu_addatetime utility is to be executed Y/N */
               getadslvarsyn=Y,            /* Flag to indicate if tu_adgetadslvars utility need to be called */
               dsetinadsl=adamdata.adsl,   /* Input ADSL or ADTRT dataset */          
               adslvars=siteid age sex race acountry trtsdt trtedt trtseq: fasfl ittfl saffl pprotfl, /* List of variable from DSETINADSL dataset for tu_adgetadslvars utility to merge on by USUBJID*/
               adgettrtyn=Y,               /* Flag to indicate if tu_adgettrt utility is to be executed Y/N */
               adgettrtmergevars=USUBJID,  /* Variables used to merge treatment information from DSETINADSL onto work dataset */
               adgettrtvars=trt01p trt01pn trt01a trt01an,   /* List of variables from treatment dataset DSETINADSL for tu_adgettrt utility to add to work dataset */
               decodeyn=Y,                 /* Flag to indicate if tu_decode utility is to be executed Y/N */
               decodepairs=paramcd param,  /* A list of paired code/decode variables for which the decode is to be created*/ 
               codepairs=parcat1n parcat1, /* A list of paired code/decode variables for which the code is to be created*/
               adreldaysyn=Y,              /* Flag to indicate if tu_adreldays utility is to be executed*/
               dyrefdatevar=,              /* Reference date variable for analysis relative days derivation: ADY, ASTDY, AENDY*/
               advisityn=Y,                /* Flag to indicate if tu_advisit utility is to be executed Y/N */
               avisitnfmt=,                /* Format used to derive AVISITN from VISITNUM*/
               avisitfmt=,                 /* Format used to derive AVISIT from VISIT*/ 
               adperiodyn=N,               /* Flag to indicate if tu_adperiod utility is to be executed Y/N */
               attributesyn=Y,             /* Flag to indicate if tu_attrib utility is to be executed Y/N */
               misschkyn=Y                 /* Flag to indicate if tu_misschk utility is to be executed Y/N */
               );

  /*
  / Echo parameter values and global macro variables to the log.
  /----------------------------------------------------------------------------*/

  %local MacroVersion;
  %let MacroVersion = 1 build 1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_dsplanfile g_abort g_refdata);

  /*
  /  Set up local macro variables
  /---------------------------------------------------------------------------*/

  %local prefix lastdset domain dsetinlist dsetinsupplist loopi thisdset mappeddsetinlist datevars astenvars;
  %let prefix = _adliver;
  %let domain=LV;
  %let dsetinlist=DSETINCE DSETINFACE DSETINQS DSETINMI DSETINXI;
  %let dsetinsupplist=DSETINSUPPCE DSETINSUPPQS DSETINSUPPXI;

  /*
  / PARAMETER VALIDATION
  /----------------------------------------------------------------------------*/

  %let dsetince          = %nrbquote(&dsetince.);
  %let dsetinface        = %nrbquote(&dsetinface.);
  %let dsetinqs          = %nrbquote(&dsetinqs.);
  %let dsetinmi          = %nrbquote(&dsetinmi.);
  %let dsetinxi          = %nrbquote(&dsetinxi.);
  %let dsetinex          = %nrbquote(&dsetinex.);
  %let dsetout           = %nrbquote(&dsetout.);
  %let dsetinsuppce      = %nrbquote(&dsetinsuppce.);
  %let dsetinsuppqs      = %nrbquote(&dsetinsuppqs.);
  %let dsetinsuppxi      = %nrbquote(&dsetinsuppxi.);
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

  /* Validating if non-missing values are provided for parameters DSETINCE, DSETINEX and DSETOUT */
  %if &dsetince. eq %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro parameter DSETINCE is a required parameter, provide a dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &dsetinex. eq %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro parameter DSETINEX is a required parameter, provide a dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &dsetout. eq %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro parameter DSETOUT is a required parameter, provide a dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;

  /* calling tu_chknames to validate name provided in DSETIN parameters */
  %do loopi=1 %to %tu_words(&dsetinlist);
    %let thisdset=%scan(&dsetinlist, &loopi, %str( ));
    %if %nrbquote(&&&thisdset) ne %then
    %do;
      %if %tu_chknames(%scan(&&&thisdset, 1, %str(%() ), DATA ) ne %then %do;
        %put RTE%str(RROR:) &sysmacroname.: Macro parameter &thisdset refers to dataset &&&thisdset which is not a valid dataset name;
        %let g_abort = 1;
        %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
      %end;
    %end;
  %end;

  /* calling tu_chknames to validate name provided in DSETINEX parameter */
  %if %tu_chknames(%scan(&dsetinex., 1, %str(%() ), DATA) ne %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro parameter DSETINEX refers to dataset %nrbquote(%upcase("&dsetinex.")) which is not a valid dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* calling tu_chknames to validate name provided in DSETINSUPP parameters */
  %do loopi=1 %to %tu_words(&dsetinsupplist);
    %let thisdset=%scan(&dsetinsupplist, &loopi, %str( ));
    %if %nrbquote(&&&thisdset) ne %then
    %do;
      %if %tu_chknames(%scan(&&&thisdset, 1, %str(%() ), DATA ) ne %then
      %do;
        %put RTE%str(RROR:) &sysmacroname.: Macro parameter &thisdset refers to dataset &&&thisdset which is not a valid dataset name;
        %let g_abort = 1;
        %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
      %end;
    %end;
  %end;

  /* calling tu_chknames to validate name provided in DSETOUT parameter */
  %if %tu_chknames(&dsetout., DATA) ne %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro parameter DSETOUT refers to dataset %nrbquote(%upcase("&dsetout.")) which is not a valid dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;

  /* Validating if DSETINCE dataset exists */
  %if %SYSFUNC(EXIST(%scan(&dsetince, 1, %str(%() ) )) NE 1 %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro parameter DSETINCE refers to dataset %upcase("&dsetince.") which does not exist.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* If DSETINFACE, DSETINQS, DSETINMI, DSETINXI do not exist, inform the user and carry on */
  %do loopi=2 %to %tu_words(&dsetinlist);
    %let thisdset=%scan(&dsetinlist, &loopi, %str( ));
    %if %nrbquote(&&&thisdset) ne %then
    %do;
      %if %SYSFUNC(EXIST(%scan(&&&thisdset, 1, %str(%() ) )) NE 1 %then
      %do;
        %put RTW%str(ARNING:) &sysmacroname.: Macro parameter &thisdset refers to dataset %upcase("&&&thisdset.") which does not exist.;
        %put RTW%str(ARNING:) &sysmacroname.: Since &thisdset is an optional dataset the value will be ignored. This is an acceptable RTW%str(ARNING) message.;
        %let &thisdset=;
      %end;
    %end;
  %end;

  /* Validating if DSETINEX dataset exists */
  %if %SYSFUNC(EXIST(%scan(&dsetinex, 1, %str(%() ) )) NE 1 %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro parameter DSETINEX refers to dataset %upcase("&dsetinex.") which does not exist.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Validating if DSETOUT is not same as any of the DSETIN parameters */
  %do loopi=1 %to %tu_words(&dsetinlist);
    %let thisdset=%scan(&dsetinlist, &loopi, %str( ));
    %if %nrbquote(&&&thisdset) ne %then
    %do;
      %if %qupcase(&dsetout.) eq %qupcase(%scan(&&&thisdset, 1, %str(%() )) %then
      %do;
        %put RTE%str(RROR:) &sysmacroname.: Macro parameter DSETOUT refers to dataset %nrbquote(%upcase("&dsetout.")) which is the same as macro parameter &thisdset.;
        %let g_abort = 1;
        %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
      %end;
    %end;
  %end;
  %if %qupcase(&dsetout.) eq %qupcase(%scan(&dsetinex, 1, %str(%() )) %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro parameter DSETOUT refers to dataset %nrbquote(%upcase("&dsetout.")) which is the same as macro parameter DSETINEX.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
  %do loopi=1 %to %tu_words(&dsetinsupplist);
    %let thisdset=%scan(&dsetinsupplist, &loopi, %str( ));
    %if %nrbquote(&&&thisdset) ne %then
    %do;
      %if %qupcase(&dsetout.) eq %qupcase(%scan(&&&thisdset, 1, %str(%() )) %then
      %do;
        %put RTE%str(RROR:) &sysmacroname.: Macro parameter DSETOUT refers to dataset %nrbquote(%upcase("&dsetout.")) which is the same as macro parameter &thisdset.;
        %let g_abort = 1;
        %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
      %end;
    %end;
  %end;

  /* Validating ADSUPPJOINYN, ADDATETIMEYN, GETADSLVARSYN, ADGETTRTYN, ADVISITYN, ADPERIODYN, ADRELDAYSYN, DECODEYN, ATTRIBUTESYN and MISSCHKYN parameters */ 
  %if &adsuppjoinyn. ne Y and &adsuppjoinyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro parameter ADSUPPJOINYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &addatetimeyn. ne Y and &addatetimeyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro parameter ADDATETIMEYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
  
  %if &getadslvarsyn. ne Y and &getadslvarsyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro parameter GETADSLVARSYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &adgettrtyn. ne Y and &adgettrtyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro parameter ADGETTRTYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &advisityn. ne Y and &advisityn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro parameter AVISITYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &adperiodyn. ne Y and &adperiodyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro parameter ADPERIODYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &adreldaysyn. ne Y and &adreldaysyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro parameter ADRELDAYSYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &decodeyn. ne Y and &decodeyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro parameter DECODEYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &attributesyn. ne Y and &attributesyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro parameter ATTRIBUTESYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &misschkyn. ne Y and &misschkyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro parameter MISSCHKYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Validate supplemental datasets if ADSUPPJOINYN is set to Y */
  %if %upcase(&adsuppjoinyn) eq Y %then
  %do;

    /* DSETINSUPPCE should be provided and dataset must exist */
    %if &dsetinsuppce. eq %str() %then
    %do;
      %put RTE%str(RROR:) &sysmacroname.: Macro parameter DSETINSUPPCE is a required parameter when ADSUPPJOINYN=Y, provide a dataset name.;
      %let g_abort = 1;
      %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
    %end;
    %else %if %SYSFUNC(EXIST(%scan(&dsetinsuppce, 1, %str(%() ) )) NE 1 %then
    %do;
      %put RTE%str(RROR:) &sysmacroname.: Macro parameter DSETINSUPPCE refers to dataset %upcase("&dsetinsuppce.") which does not exist.;
      %let g_abort = 1;
      %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
    %end;

    /* DSETINSUPPQS is not required if DSETINQS is missing, otherwise check it exists */
    %if &dsetinsuppqs. ne %str() %then
    %do;
      %if &dsetinqs. eq %str() %then
      %do;
        %put RTW%str(ARNING:) &sysmacroname.: Macro parameter DSETINSUPPQS is provided when macro parameter DSETINQS either is not specified or specifies a dataset which does not exist.;
        %put RTW%str(ARNING:) &sysmacroname.: Since DSETINSUPPQS is an optional dataset the value will be ignored. This is an acceptable RTW%str(ARNING) message.;
        %let dsetinsuppqs=;
      %end;
      %else %if %SYSFUNC(EXIST(%scan(&dsetinsuppqs, 1, %str(%() ) )) NE 1 %then
      %do;
        %put RTW%str(ARNING:) &sysmacroname.: Macro parameter DSETINSUPPQS refers to dataset %upcase("&dsetinsuppqs.") which does not exist.;
        %put RTW%str(ARNING:) &sysmacroname.: Since DSETINSUPPQS is an optional dataset the value will be ignored. This is an acceptable RTW%str(ARNING) message.;
        %let dsetinsuppqs=;
      %end;
    %end;

    /* DSETINSUPPXI is not required if DSETINXI is missing, otherwise check it exists */
    %if &dsetinsuppxi. ne %str() %then
    %do;
      %if &dsetinxi. eq %str() %then
      %do;
        %put RTW%str(ARNING:) &sysmacroname.: Macro parameter DSETINSUPPXI is provided when macro parameter DSETINXI either is not specified or specifies a dataset which does not exist.;
        %put RTW%str(ARNING:) &sysmacroname.: Since DSETINSUPPXI is an optional dataset the value will be ignored. This is an acceptable RTW%str(ARNING) message.;
        %let dsetinsuppxi=;
      %end;
      %else %if %SYSFUNC(EXIST(%scan(&dsetinsuppxi, 1, %str(%() ) )) NE 1 %then
      %do;
        %put RTW%str(ARNING:) &sysmacroname.: Macro parameter DSETINSUPPXI refers to dataset %upcase("&dsetinsuppxi.") which does not exist.;
        %put RTW%str(ARNING:) &sysmacroname.: Since DSETINSUPPXI is an optional dataset the value will be ignored. This is an acceptable RTW%str(ARNING) message.;
        %let dsetinsuppxi=;
      %end;
    %end;

  %end;

  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;

  /*
  / Main Processing starts here.
  / ---------------------------------------------------------------------------*/

  /* Pre-process each of the domain input datasets to map variable names etc. */

  %macro pre_process(
    dsetin=,
    dsetout=,
    mapped_domain=
    );

    %local prefix source_domain;
    %let prefix = _adliver_pre;

    data &prefix._dsetin;
      set %unquote(&dsetin.);
    run;

    /* Determine the source dataset domain code by looking for the SDTM xxSEQ variable. */

    proc sql noprint;
      select upcase(substr(name,1,2)) length=2 into: source_domain
      from sashelp.vcolumn
      where libname='WORK' and memname="%upcase(&prefix._dsetin)" and upcase(name) like '__SEQ'
      ;
    quit;

    data &dsetout;
      set &prefix._dsetin;

      /* Date and study day variables */

      %if %length(%tu_chkvarsexist(&prefix._dsetin, &source_domain.DTC)) eq 0 %then
        &mapped_domain.DTC=&source_domain.DTC;;
      %if %length(%tu_chkvarsexist(&prefix._dsetin, &source_domain.STDTC)) eq 0 %then
        &mapped_domain.STDTC=&source_domain.STDTC;;
      %if %length(%tu_chkvarsexist(&prefix._dsetin, &source_domain.ENDTC)) eq 0 %then
        &mapped_domain.ENDTC=&source_domain.ENDTC;;

      %if %length(%tu_chkvarsexist(&prefix._dsetin, &source_domain.DY)) eq 0 %then
        &mapped_domain.DY=&source_domain.DY;;
      %if %length(%tu_chkvarsexist(&prefix._dsetin, &source_domain.STDY)) eq 0 %then
        &mapped_domain.STDY=&source_domain.STDY;;
      %if %length(%tu_chkvarsexist(&prefix._dsetin, &source_domain.ENDY)) eq 0 %then
        &mapped_domain.ENDY=&source_domain.ENDY;;

      /* Timepoint variables */

      %if %length(%tu_chkvarsexist(&prefix._dsetin,&source_domain.TPT)) eq 0 %then
      %do;
        if ^missing(&source_domain.TPT) then ATPT=&source_domain.TPT;
        else ATPT='UNSCHEDULED';
      %end;
      %if %length(%tu_chkvarsexist(&prefix._dsetin,&source_domain.TPTREF)) eq 0 %then 
        ATPTREF=&source_domain.TPTREF;;
      %if %length(%tu_chkvarsexist(&prefix._dsetin,&source_domain.TPTNUM)) eq 0 %then
      %do;
        if missing(&source_domain.TPTNUM) or ATPT eq 'UNSCHEDULED' then ATPTN=999;
        else ATPTN=&source_domain.TPTNUM;
      %end;

      /* Parameter and result variables */

      %if %length(%tu_chkvarsexist(&prefix._dsetin, &source_domain.CAT)) eq 0 %then
        PARCAT1=&source_domain.CAT;;

      %if %length(%tu_chkvarsexist(&prefix._dsetin, &source_domain.TESTCD)) eq 0 %then
      %do;

        PARAMCD=&source_domain.TESTCD;;

        %if %length(%tu_chkvarsexist(&prefix._dsetin, &source_domain.STRESC &source_domain.STRESN)) eq 0 %then
        %do;
          if input(&source_domain.STRESC,??best.) ne &source_domain.STRESN or &source_domain.STRESN=. then
            AVALC=&source_domain.STRESC;
          else
            AVALC='';
          AVAL=&source_domain.STRESN;
        %end;
        %else %if %length(%tu_chkvarsexist(&prefix._dsetin, &source_domain.STRESC)) eq 0 %then
        %do;
          AVALC=&source_domain.STRESC;
          AVAL=.;
        %end;
        %else %if %length(%tu_chkvarsexist(&prefix._dsetin, &source_domain.STRESN)) eq 0 %then
        %do;
          AVALC='';
          AVAL=&source_domain.STRESN;
        %end;

      %end;

      /* Source variables */

      %if %length(%tu_chkvarsexist(&prefix._dsetin, DOMAIN)) eq 0 %then
      %do;
        %if &source_domain eq FA %then
          SRCDOM="FACE";
        %else 
          SRCDOM=DOMAIN;;
      %end;
      %if %length(%tu_chkvarsexist(&prefix._dsetin, &source_domain.SEQ)) eq 0 %then
        SRCSEQ=&source_domain.SEQ;;
      %if %length(%tu_chkvarsexist(&prefix._dsetin, &source_domain.TESTCD)) eq 0 %then
      %do;
        if PARAMCD='BIOPSZ' then
          SRCVAR="&source_domain.STRESN";
        else
          SRCVAR="&source_domain.STRESC";
      %end;

    run;

  %mend pre_process;

  %do loopi=1 %to %tu_words(&dsetinlist);
    %let thisdset=%scan(&dsetinlist, &loopi, %str( ));
    %if %nrbquote(&&&thisdset) ne %then %do;
      %pre_process(
        dsetin=%nrbquote(&&&thisdset),
        dsetout=&prefix._mapped_&thisdset,
        mapped_domain=&domain
        );
      %let mappeddsetinlist=&mappeddsetinlist &prefix._mapped_&thisdset;
    %end;
  %end;

  /* Set together the mapped domain input datasets */
  %tu_adappend(
    dsetinlist=&mappeddsetinlist,
    dsetout=&prefix._mappeddomain
    );

  %let lastdset=&prefix._mappeddomain;

  /* Calling tu_adsuppjoin to merge supplemental dataset with parent domain dataset, if adsuppjoinyn parameter is Y */
  %if %upcase(&adsuppjoinyn) eq Y %then
  %do;

    %tu_adappend(
      dsetinlist=&dsetinsuppce &dsetinsuppqs &dsetinsuppxi,
      dsetout=&prefix._suppall
      );

    %tu_adsuppjoin(dsetin = &lastdset.,
                   dsetinsupp = &prefix._suppall,
                   dsetout = &prefix._supp
                  );

    %let lastdset=&prefix._supp;
  %end;

  /* Calling tu_addatetime to convert character date to numeric date, time and datetime, if addatetimeyn parameter is Y */
  %if %upcase(&addatetimeyn) eq Y %then
  %do;

    %let datevars=%tu_chkvarsexist(&lastdset, &domain.DTC &domain.STDTC &domain.ENDTC, Y);
    %tu_addatetime(dsetin = &lastdset.,
                   dsetout = &prefix._date,
                   datevars = &datevars.
                  );

    /* Deriving event dates to ADaM variable naming conventions */
    data &prefix._daterename;
      set &prefix._date;
      %if %tu_chkvarsexist(&prefix._date,&domain.DT)=%str() %then ADT=&domain.DT;;
      %if %tu_chkvarsexist(&prefix._date,&domain.TM)=%str() %then ATM=&domain.TM;;
      %if %tu_chkvarsexist(&prefix._date,&domain.DTM)=%str() %then ADTM=&domain.DTM;;
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

  /* Calling tu_adperiod to bring in either APERIOD/APERIODC or TPERIOD/TPERIODC from ADTRT dataset */

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

  /* Populate the start date on RUCAM rows with the value from the LIVER EVENT */

  %if &dsetinqs ne %then
  %do;

    %let astenvars=%tu_chkvarsexist(&lastdset., ASTDT ASTDY TPERSTDY AENDT AENDY TPERENDY, Y);

    proc sort data=&lastdset. out=&prefix._le_start (keep=usubjid visit &astenvars);
      by usubjid visit;
      where srcdom='CE';
    run;

    proc sort data=&lastdset. out=&prefix._rucam %if %length(&astenvars) gt 0 %then (drop=&astenvars);;
      by usubjid visit;
      where srcdom='QS';
    run;

    data &prefix._rucam;
      merge &prefix._rucam (in=a) &prefix._le_start;
      by usubjid visit;
      if a;
    run;

    data &lastdset;
      set &lastdset. (where=(srcdom ne 'QS')) &prefix._rucam;
    run;

  %end;

  /* Derive new liver event PARAMCD: LERMX, CEOUT */

  data &prefix._ceparam;
    set &lastdset.(where=(srcdom='CE') %if %length(%tu_chkvarsexist(&lastdset., AVALC)) eq 0 %then drop=avalc;);
    length 
      avalc $200 
      %if %length(%tu_chkvarsexist(&lastdset., PARAMCD)) gt 0 %then paramcd $8;
      %if %length(%tu_chkvarsexist(&lastdset., SRCVAR)) gt 0 %then srcvar $8;
      ;
    %if %length(%tu_chkvarsexist(&lastdset, LERMX)) eq 0 %then
    %do;
      paramcd='LERMX';
      avalc=lermx;
      srcvar='LERMX';
      output;
    %end;
    %if %length(%tu_chkvarsexist(&lastdset, CEOUT)) eq 0 %then
    %do;
      paramcd='CEOUT';
      avalc=ceout;
      srcvar='CEOUT';
      output;
    %end;
  run;

  data &prefix._allparam;
    set &prefix._ceparam &lastdset;
  run;

  %let lastdset=&prefix._allparam;

  /*
  / Derive new liver imaging PARAMCD: IMGMETH, SPCQUAL
  / Note: liver imaging expected to move from XI domain to MO domain in
  / future version of SDTM.
  /---------------------------------------------------------------------------*/

  %if &dsetinxi ne %then
  %do;

    proc sort data=&lastdset out=&prefix._xiparam;
      by studyid usubjid visitnum adt ady srcseq;
      where srcdom='XI' or srcdom='MO';
    run;

    data &prefix._xiparam;
      set &prefix._xiparam %if %length(%tu_chkvarsexist(&lastdset., AVALC)) eq 0 %then (drop=avalc);;
      by studyid usubjid visitnum adt ady srcseq;
      if first.ady;
      length 
        avalc $200 
        %if %length(%tu_chkvarsexist(&lastdset., PARAMCD)) gt 0 %then paramcd $8;
        %if %length(%tu_chkvarsexist(&lastdset., SRCVAR)) gt 0 %then srcvar $8;
        ;
      %if %length(%tu_chkvarsexist(&lastdset, XIMETHOD)) eq 0 %then
      %do;
        paramcd='IMGMETH';
        avalc=ximethod;
        srcvar='XIMETHOD';
        output;
      %end;
      %if %length(%tu_chkvarsexist(&lastdset, MOMETHOD)) eq 0 %then
      %do;
        paramcd='IMGMETH';
        avalc=momethod;
        srcvar='MOMETHOD';
        output;
      %end;
      %if %length(%tu_chkvarsexist(&lastdset, SPCQUAL)) eq 0 %then
      %do;
        paramcd='SPCQUAL';
        avalc=spcqual;
        srcvar='SPCQUAL';
        output;
      %end;
    run;

    data &lastdset;
      set &lastdset &prefix._xiparam;
    run;

  %end;

  /* Find the date of the last dose before the event start */

  %tu_addatetime(dsetin = &dsetinex.,
                 dsetout = &prefix._exposure,
                 datevars = exstdtc
                 );

  proc sort data=&prefix._exposure nodupkey;
    by usubjid exstdt;
    where exstdt ne .;
  run;

  proc sort data=&lastdset.;
    by usubjid astdt;
  run;

  data &prefix._dosedates;
    set
      &prefix._exposure (in=expo keep=usubjid exstdt rename=(exstdt=astdt))
      &lastdset         (in=event)
      ;
    by usubjid astdt;
    format astdt first_dose_d %if %tu_chkvarsexist(&lastdset, tperiod) eq %str() %then period_dose_d; last_dose_d date9.;
    retain last_dose_d;

    if first.usubjid then
      last_dose_d=.;

    if expo then
      last_dose_d=astdt;

    first_dose_d=trtsdt;
    %if %tu_chkvarsexist(&lastdset, tperiod trsdt) eq %str() %then period_dose_d=trsdt;;

    if event;

  run;

  %let lastdset=&prefix._dosedates;

  /* Derive time since dose variables etc. */
    
  data &prefix._derive ;
    set &lastdset;
    where ^missing(paramcd);

    * Create analysis start relative to first/first period/last dose variables *;

    %tu_times(unit=D, start=first_dose_d, end=astdt, output=aftrtst, outputc=aftrtstc);
    if ^missing(aftrtst) then aftrtstu='DAYS';

    %tu_times(unit=D, start=last_dose_d, end=astdt, output=altrtst, outputc=altrtstc);
    if ^missing(altrtst) then altrtstu='DAYS';

    %if %tu_chkvarsexist(&lastdset, tperiod) eq %str() %then
    %do;
      %tu_times(unit=D, start=period_dose_d, end=astdt, output=apftrst, outputc=apftrstc);
      if ^missing(apftrst) then apftrstu='DAYS';
    %end;

    * Create on-treatment and follow-up flags *;

    %if %length(%tu_chkvarsexist(&lastdset, ONTRTFL)) gt 0 %then
    %do;
      if (nmiss(adt, trtsdt, trtedt)=0 and (trtsdt <= adt <= trtedt)) or
        (nmiss(astdt, trtsdt, trtedt)=0 and (trtsdt <= astdt <= trtedt)) then
        ontrtfl='Y';
    %end;
    %if %length(%tu_chkvarsexist(&lastdset, FUPFL)) gt 0 %then
    %do;
      if (nmiss(adt, trtedt)=0 and (adt > trtedt)) or
        (nmiss(astdt, trtedt)=0 and (astdt > trtedt)) then
        fupfl='Y';
    %end;

    * Create an order variable for stopping/monitoring criteria to use later *;

    if paramcd='LERMX' then
    do;

      if indexw(upcase(avalc), 'STOPPING') gt 0 then _eventord=1;
      else if indexw(upcase(avalc), 'MONITORING') gt 0 then _eventord=2;

    end;

  run;
       
  %let lastdset=&prefix._derive;

  /* Find the maximum status per subject (earliest stopping event, else earliest monitoring) */

  proc sort data=&lastdset. out=&prefix._maxstat (keep=usubjid _eventord astdt);
    by usubjid _eventord astdt;
    where paramcd='LERMX' and _eventord ne . and astdt ne .;
  run;

  data &prefix._maxstat1;
    set &prefix._maxstat;
    by usubjid _eventord astdt;
    if first.usubjid;
  run;

  proc sort data=&lastdset.;
    by usubjid;
  run;

  data &prefix._anlfl;
    merge &lastdset. &prefix._maxstat1 (rename=(astdt=_maxdt));
    by usubjid;
    if _maxdt ne . and (astdt=_maxdt or adt=_maxdt) and srcdom in ('CE' 'FACE' 'QS') then
      anl01fl='Y';
    drop _eventord _maxdt;
  run;

  %let lastdset=&prefix._anlfl;

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
  %else 
  %do;
     data &dsetout.;
        set &lastdset.;
     run;
  %end;

  %if %tu_nobs(&dsetout) gt 0 %then
  %do;

    %if %upcase(&misschkyn) eq Y %then
    %do;
        %tu_misschk(dsetin=&dsetout);
    %end;

  %end;

  /* Calling tu_tidyup to delete the temporary datasets. */

  %tu_tidyup(rmdset=&prefix.:, glbmac=none);

%mend tc_adliver;
