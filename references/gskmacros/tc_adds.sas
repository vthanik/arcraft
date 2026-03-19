/*******************************************************************************
| Program Name: tc_adds.sas
|
| Program Version: 2 build 2
|
| HARP Compound/Study/Reporting Effort:
|
| Program Purpose: To create the ADaM dataset of Subject Disposition domain using the SDTM DS
|                  and supplemental SUPPDS atasets.
|
| SAS Version: SAS v9.1.3
|
| Created By:  David Ainsworth [daa62284]
| Date: 14MAY2014
|
|*******************************************************************************
|
| Output: adamdata.adds
|
|
|
| Nested Macros:
| (@) tu_adsuppjoin
| (@) tu_addatetime
| (@) tu_adgetadslvars
| (@) tu_adgettrt
| (@) tu_adperiod
| (@) tu_adreldays
| (@) tu_advisit 
| (@) tu_attrib
| (@) tu_chknames
| (@) tu_chkvarsexist
| (@) tu_putglobals
| (@) tu_misschk
| (@) tu_decode
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
| Modified By: seymol00
| Date of Modification: 15-May-2014
| Version :           1 build 1
| Modification ID: LJS001
| Reason For Modification: Corrections to parameter validation steps 
|*******************************************************************************
| Modified By:          David Ainsworth
| Date of Modification: 15AUG2014
| Version :            2 build 1
| Modification ID:     HRT301 
| Reason For Modification: Set PARAMCD from PARCAT1N using array (PARAMN no longer required)
|*******************************************************************************
| Modified By:          Lee Seymour
| Date of Modification: 23Sep2014
| Version :            2 build 2
| Modification ID:     LJS001 
| Reason For Modification: Corrections to parameter validation steps 
********************************************************************************/

%macro tc_adds(dsetin=sdtmdata.ds(WHERE=(dscat='DISPOSITION EVENT')), /* Input dataset with */
               dsetout=adamdata.adds,       /* Output dataset to be created*/
               adsuppjoinyn=Y,              /* If supplemental dataset is required to be joined with parent domain Y/N */
               dsetinsupp=sdtmdata.suppds,  /* Input supplemental dataset */
               addatetimeyn=Y,              /* Flag to indicate if If tu_addatetime utility is to be executed Y/N */
               datevars=dsstdtc,            /* Datetime variables in input dataset to be converted to numeric dates times datetimes*/
               getadslvarsyn=Y,             /* Flag to indicate if tu_adgetadslvars utility need to be called Y/N */
               dsetinadsl = adamdata.adsl,  /* Input ADSL or ADTRT dataset */          
               adslvars=siteid age sex race acountry fasfl ittfl saffl pprotfl trtseq: trtsdt, /* List of variable from DSETINADSL dataset for tu_adgetadslvars utility to merge on by USUBJID*/
               adgettrtyn=Y,               /* Flag to indicate if tu_adgettrt utility is to be executed Y/N */
               adgettrtmergevars=usubjid,  /* Variables used to merge treatment information from DSETINADSL onto work dataset */
               adgettrtvars=trt01pn trt01p trt01an trt01a, /* List of variables from treatment dataset DSETINADSL for tu_adgettrt utility to add to work dataset */
               decodeyn=Y,                 /* Flag to indicate if tu_decode utility is to be executed Y/N */
               codepairs=parcat1n parcat1, /* A list of paired code/decode variables for which the code is to be created*/ 
               decodepairs=paramcd param,  /* A list of paired code/decode variables for which the decode is to be created*/
               adreldaysyn=Y,              /* Flag to indicate if tu_adreldays utility is to be executed*/
               dyrefdatevar=,              /* Reference date variable for analysis relative days derivation: ADY, ASTDY, AENDY*/
               advisityn=Y,                /* Flag to indicate if tu_adreldays utility is to be executed Y/N */
               avisitnfmt=,                /* Format used to derive AVISITN from VISITNUM*/
               avisitfmt = ,               /* Format used to derive AVISIT from VISIT*/ 
               adperiodyn= N,              /* Flag to indicate if tu_adperiod utility is to be executed Y/N */
               misschkyn=Y,                /* Flag to indicate if tu_misschk utility is to be executed Y/N */
               attributesyn=Y              /* Flag to indicate if tu_attrib utility is to be executed Y/N */
               );


  /*
  / Echo parameter values and global macro variables to the log.
  /----------------------------------------------------------------------------*/

  %local MacroVersion;
  %let MacroVersion = 2;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_dsplanfile g_abort g_refdata); 

  /*
  /  Set up local macro variables
  / ---------------------------------------------------------------------------*/

  %local prefix lastdset domain;
  %let prefix = adds;
  %let domain=DS;

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

  
  /* Validating if non-missing values are provided for parameters DSETIN and DSETOUT */
  %if &dsetin. eq %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETIN is a desired parameter, provide a dataset name.;
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
     %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETIN refers to dataset &dsetin which is not a valid dataset name; /*LJS001*/
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
  %if %qupcase(&dsetout.) eq %qupcase(%scan(&dsetin, 1, %str(%( ))) %then                /*LJS001*/
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

  /* Validating ADDATETIMEYN, GETADSLVARSYN, ADGETTRTYN, ATTRIBUTESYN, DATEVARS and ADSLVARS parameters */
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
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ADRELDAYS should either be Y or N.;
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
  %if %index(&dsetin,%str(%()) ne 0 %then 
  %do;
    data  &prefix._dsetin;
      set %unquote(&dsetin.) ;
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

    /* Remapping event dates to ADaM variable naming conventions */
    
    
    data &prefix._daterename;
      set &prefix._date;
    %if %tu_chkvarsexist(&prefix._date,&domain.STDT)=%str() %then ADT=&domain.STDT;;
    %if %tu_chkvarsexist(&prefix._date,&domain.STTM)=%str() %then ATM=&domain.STTM;;
    %if %tu_chkvarsexist(&prefix._date,&domain.STDTM)=%str() %then ADTM=&domain.STDTM;;
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
                 avisitfmt=&avisitfmt,
                 avisitnfmt=&avisitnfmt
                );

    %let lastdset=&prefix._visit;
  %end;


  /* Calling tu_adperiod to reassign unscheduled visits */

  %if %upcase(&adperiodyn)=Y %then
  %do;
   %tu_adperiod(dsetin = &lastdset.,
                 dsetinadtrt = &dsetinadsl.,
                 dsetout = &prefix._period,
                 eventtype= SP             /*Either SP or PL depending on domain */
                );

    %let lastdset=&prefix._period;
  %end;


  /* Calling tu_adgettrt to assign treatment variables to records */

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


   /* Calling tu_adreldays to derive relative days */

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

  data &prefix._domain ;
    set &lastdset;
    %if %tu_chkvarsexist(&lastdset ,&domain.TPT)=%str() %then atpt=&domain.TPT;;
    %if %tu_chkvarsexist(&lastdset ,&domain.TPTREF)=%str() %then atpt=&domain.TPTREF;;
    %if %tu_chkvarsexist(&lastdset, &domain.TPTNUM)=%str() %then atpt=&domain.TPTNUM;;
    
    ady=astdy;
    parcat1=upcase(dsscat);
  run;

  /* Create Numeric Variable PARCAT1N using Controlled Term informat */
  %tu_decode(dsetin = &prefix._domain,
                dsetout= &prefix._domain1,
                dsplan=&g_dsplanfile,
                codepairs=parcat1n parcat1
               );

  /* Create records for Disposition Events other than Screening Failure/Run-in Failure/Follow-up */ 
  data &prefix._domain2;
    set &prefix._domain1;
    by usubjid;
    length paramcd $8 avalc $200 srcdom $8 srcvar $8 srcseq 8; 
    array dsd dsdecod:;
    array dst dsterm:;
    array cd (8) $2. _temporary_ ('SC' 'SF' 'RF' 'PH' 'TC' 'SJ' 'SS' 'FU');
    
    if index(parcat1,'FAILURE')=0 and index(parcat1,'FOLLOW')=0
        then do;
            /* Status */
            paramcd=cd(parcat1n)||'STAT';
            if dsdecod in ('UNKNOWN' 'COMPLETED')
                then avalc=dsdecod;
                else avalc='WITHDRAWN';
            srcdom=domain;
            srcvar="DSDECOD";
            srcseq=dsseq;
            output;

            /* Reason */
            paramcd=cd(parcat1n)||'WRES';
            if dsdecod not in ('UNKNOWN' 'COMPLETED')
                then do over dsd;
                    avalc=dsd;
                    if avalc ne '' then do;
                        srcdom=domain;
                        srcvar="DSDECOD";
                        srcseq=dsseq;
                        output;
                    end;
            end;

            /* Sub-reason */
            paramcd=cd(parcat1n)||'WSRES';
            if dsdecod not in ('UNKNOWN' 'COMPLETED')
                then do over dst;
                    avalc=dst;
                    if avalc ne '' and dst ne dsdecod then do;
                        srcdom=domain;
                        srcvar="DSTERM";
                        srcseq=dsseq;
                        output;
                    end;
                end;
        end;
   run;

  /* Create records for Screening Failure/Run-in Failure/Follow-up */ 
  data &prefix._domain2a;
    set &prefix._domain1;
    by usubjid;
    length paramcd $8 avalc $200 srcdom $8 srcvar $8 srcseq 8; 
    array dsd dsdecod:;
    array dst dsterm:;
    array cd (8) $2. _temporary_ ('SC' 'SF' 'RF' 'PH' 'TC' 'SJ' 'SS' 'FU');
    
    if index(parcat1,'FAILURE')>0
        then do;
            /* Status */
            paramcd=cd(parcat1n)||'STAT';
            avalc='FAILED';
            srcdom=domain;
            srcvar="DSDECOD";
            srcseq=dsseq;
            output;

            /* Reason */
            paramcd=cd(parcat1n)||'RES';
            do over dsd;
               avalc=dsd;
               if avalc ne '' then do;
                   srcdom=domain;
                   srcvar="DSDECOD";
                   srcseq=dsseq;
                   output;
               end;
            end;
            
            /* Sub-reason */
            paramcd=cd(parcat1n)||'SRES';
            if dsdecod not in ('ENROLLED')
                then do over dst;
                    avalc=dst;
                    if avalc ne ''  and dst ne dsdecod then do;
                        srcdom=domain;
                        srcvar="DSTERM";
                        srcseq=dsseq;
                    output;
                    end;
                end;
        end;
  run;

/* Create records for Follow-up */ 
  data &prefix._domain2b;
    set &prefix._domain1;
    by usubjid;
    length paramcd $8 avalc $200 srcdom $8 srcvar $8 srcseq 8; 
    array dsd dsdecod:;
    array dst dsterm:;
    array cd (8) $2. _temporary_ ('SC' 'SF' 'RF' 'PH' 'TC' 'SJ' 'SS' 'FU');
    
    if index(parcat1,'FOLLOW')>0
        then do;
            /* Status */
            paramcd=cd(parcat1n)||'STAT';
            avalc=dsdecod;
            srcdom=domain;
            srcvar="DSDECOD";
            srcseq=dsseq;
            output;

            /* Reason */
            paramcd=cd(parcat1n)||'RES';
            if dsdecod not in ('UNKNOWN' 'COMPLETED')
                then do over dsd;
                    avalc=dsd;
                    if avalc ne '' then do;
                        srcdom=domain;
                        srcvar="DSDECOD";
                        srcseq=dsseq;
                        output;
                    end;
            end;

            /* Sub-reason */
            paramcd=cd(parcat1n)||'SRES';
            if dsdecod not in ('UNKNOWN' 'COMPLETED')
                then do over dst;
                    avalc=dst;
                    if avalc ne '' and dst ne dsdecod then do;
                        srcdom=domain;
                        srcvar="DSTERM";
                        srcseq=dsseq;
                        output;
                    end;
                end;
        end;
   run;

  /* Combine datasets */
  data &prefix._domain3;
    set &prefix._domain2 
        &prefix._domain2a
        &prefix._domain2b;
 run;

  %let lastdset=&prefix._domain3;

  %if %upcase(%scan(&codepairs,2))=PARCAT1
      %then %do; 
           %if %scan(&codepairs,3)=%str() 
              %then %let l_codepairs= ;
                        %else %let l_codepairs=%substr(&codepairs,17);
                %end;
            %else %let l_codepairs=&codepairs;                 

  /* Calling tu_decode to apply other Controlled Term formats */
  %if %upcase(&decodeyn.) eq Y %then
  %do;
    %tu_decode (dsetin = &lastdset.,
                dsetout= &prefix._decode,
                dsplan=&g_dsplanfile,
                codepairs=&l_codepairs,
                decodepairs=&decodepairs 
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
     data &dsetout;
       set &lastdset;
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



%mend tc_adds;

