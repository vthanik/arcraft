/******************************************************************************* 
| Program Name: tc_admh.sas
|
| Program Version: 1.0
|
| HARP Compound/Study/Reporting Effort: 
|
| Program Purpose: To create the ADaM dataset of ADMH domain using the SDTM MH
|                  and supplemental SUPPMH datasets.
|
| SAS Version: SAS v9.1.3
|
| Created By: David Ainsworth [daa62284]
| Date:       08JUL2014
|
|******************************************************************************* 
|
| Output: 
|
|
|
| Nested Macros: 
| (@) tu_adsuppjoin
| (@) tu_addatetime
| (@) tu_adgetadslvars
| (@) tu_adgettrt
| (@) tu_advisit
| (@) tu_attrib
| (@) tu_decode
| (@) tu_chknames
| (@) tu_chkvarsexist
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
%macro tc_admh(dsetin=sdtmdata.mh,          /* Input dataset */
               dsetout=adamdata.admh,       /* Output dataset to be created*/
               adsuppjoinyn=N,              /* If supplemental dataset is required to be joined with parent domain Y/N */
               dsetinsupp=sdtmdata.suppmh,  /* Input supplemental dataset */
               addatetimeyn=Y,              /* Flag to indicate if If tu_addatetime utility is to be executed Y/N */
               datevars=mhdtc mhstdtc mhendtc, /* Datetime variables in input dataset to be converted to numeric dates times datetimes*/
               getadslvarsyn=Y,             /* Flag to indicate if tu_adgetadslvars utility need to be called */
               dsetinadsl = adamdata.adsl,  /* Input ADSL or ADTRT dataset */          
               adslvars=siteid age sex race acountry trtsdt trtedt trtseq: fasfl ittfl saffl pprotfl, /* List of variable from DSETINADSL dataset for tu_adgetadslvars utility to merge on by USUBJID*/
               adgettrtyn=Y,                /* Flag to indicate if tu_adgettrt utility is to be executed Y/N */
               adgettrtmergevars =USUBJID,  /* Variables used to merge treatment information from DSETINADSL onto work dataset */
               adgettrtvars =trt01p trt01pn trt01a trt01an,   /* List of variables from treatment dataset DSETINADSL for tu_adgettrt utility to add to work dataset */
               decodeyn=N,                  /* Flag to indicate if tu_decode utility is to be executed Y/N */
               decodepairs=,                /* A list of paired code/decode variables for which the decode is to be created*/ 
               codepairs=,                  /* A list of paired code/decode variables for which the code is to be created*/
               advisityn = Y,               /* Flag to indicate if tu_advisit utility is to be executed Y/N */
               avisitnfmt =,                /* Format used to derive AVISITN from VISITNUM*/
               avisitfmt = ,                /* Format used to derive AVISIT from VISIT*/ 
               misschkyn=Y,                 /* Flag to indicate if tu_misschk utility is to be executed Y/N */
               attributesyn=Y               /* Flag to indicate if tu_attrib utility is to be executed Y/N */
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

  %local prefix lastdset domain;   /* add here any other local macro variables defined within the code - this comment to be deleted in production versionv */
  %let prefix = _admh;
  %let domain=MH;

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

  /* Validating ADSUPPJOINYN, ADDATETIMEYN, GETADSLVARSYN, ADGETTRTYN, ADVISITYN, DECODEYN, ATTRIBUTESYN, MISSCHKYN parameters */
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
%if %index(&dsetin,%str(%()) gt 0 %then 
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
                   datevars = &datevars.
                  );

    %let lastdset=&prefix._date;
    
    /* Deriving event dates to ADaM variable naming conventions */  
    
    data &prefix._daterename;
    set &prefix._date;
    %if %tu_chkvarsexist(&lastdset.,&domain.DT)=%str() %then ADT=&domain.DT; ;
    %if %tu_chkvarsexist(&lastdset.,&domain.TM)=%str() %then ATM=&domain.TM; ;
    %if %tu_chkvarsexist(&lastdset.,&domain.DTM)=%str() %then ADTM=&domain.DTM; ;
    %if %tu_chkvarsexist(&lastdset.,&domain.STDT)=%str() %then ASTDT=&domain.STDT; ;
    %if %tu_chkvarsexist(&lastdset.,&domain.STTM)=%str() %then ASTTM=&domain.STTM; ;
    %if %tu_chkvarsexist(&lastdset.,&domain.STDTM)=%str() %then ASTDTM=&domain.STDTM; ;
    %if %tu_chkvarsexist(&lastdset.,&domain.ENDT)=%str() %then AENDT=&domain.ENDT; ;
    %if %tu_chkvarsexist(&lastdset.,&domain.ENTM)=%str() %then AENTM=&domain.ENTM; ;
    %if %tu_chkvarsexist(&lastdset.,&domain.ENDTM)=%str() %then AENDTM=&domain.ENDTM; ;
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


  /*Domain specific derivations*/

    
    data &prefix._derive ;
    set &lastdset;
    %if %tu_chkvarsexist(&lastdset.,&domain.TPT)=%str() %then ATPT=&domain.TPT; ;
    %if %tu_chkvarsexist(&lastdset.,&domain.TPTREF)=%str() %then ATPTREF=&domain.TPTREF; ;
    %if %tu_chkvarsexist(&lastdset.,&domain.TPTNUM)=%str() %then ATPTN=&domain.TPTNUM; ;
    %if %tu_chkvarsexist(&lastdset.,&domain.TOXGR)=%str() %then ATOXGR=&domain.TOXGR; ;
    run;
       
    %let lastdset=&prefix._derive;



  /* Calling tu_decode to derive codes or decodes using formats specified in &g_dsplanfile */

  %if %upcase(&decodeyn.) eq Y %then
  %do;
    %tu_decode (dsetin =&lastdset.,
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

%mend tc_admh;
