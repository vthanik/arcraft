/******************************************************************************* 
| Program Name: tc_adsu.sas
|
| Program Version: 1.0
|
| HARP Compound/Study/Reporting Effort: 
|
| Program Purpose: To create the ADaM dataset of ADSU domain using the SDTM SU
|                  and supplemental SU datasets.
|
| SAS Version: SAS v9.1.3
|
| Created By: Spencer Renyard (sr550750)/David Ainsworth
| Date:       11th August 2014/16th Februray 2015
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
%macro tc_adsu(dsetin=sdtmdata.su,          /* Input dataset */
               dsetout=adamdata.adsu,       /* Output dataset to be created*/
               adsuppjoinyn=N,              /* If supplemental dataset is required to be joined with parent domain Y/N */
               dsetinsupp=sdtmdata.suppsu,  /* Input supplemental dataset */
               addatetimeyn=Y,              /* Flag to indicate if If tu_addatetime utility is to be executed Y/N */
               datevars=sudtc sustdtc suendtc,  /* Datetime variables in input dataset to be converted to numeric dates times datetimes*/
               getadslvarsyn=Y,             /* Flag to indicate if tu_adgetadslvars utility need to be called */
               dsetinadsl=adamdata.adsl,    /* Input ADSL or ADTRT dataset */          
               adslvars=siteid age sex race acountry trtsdt trtedt trtseq: fasfl ittfl saffl pprotfl, /* List of variable from DSETINADSL dataset for tu_adgetadslvars utility to merge on by USUBJID*/
               adgettrtyn=Y,                /* Flag to indicate if tu_adgettrt utility is to be executed Y/N */
               adgettrtmergevars=USUBJID,   /* Variables used to merge treatment information from DSETINADSL onto work dataset */
               adgettrtvars=trt01p trt01pn trt01a trt01an, /* List of variables from treatment dataset DSETINADSL for tu_adgettrt utility to add to work dataset */
               decodeyn=Y,                  /* Flag to indicate if tu_decode utility is to be executed Y/N */
               decodepairs=paramcd param,   /* A list of paired code/decode variables for which the decode is to be created*/ 
               codepairs=,                  /* A list of paired code/decode variables for which the code is to be created*/
               adreldaysyn=Y,               /* Flag to indicate if tu_adreldays utility is to be executed*/
               dyrefdatevar=,               /* Reference date variable for analysis relative days derivation: ADY, ASTDY, AENDY*/
               advisityn=Y,                 /* Flag to indicate if tu_advisit utility is to be executed Y/N */
               avisitnfmt=,                 /* Format used to derive AVISITN from VISITNUM*/
               avisitfmt=,                  /* Format used to derive AVISIT from VISIT*/ 
               adperiodyn=N,                /* Flag to indicate if tu_adperiod utility is to be executed Y/N */
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
  %let prefix = _adsu;
  %let domain=SU;

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
  %if %qupcase(&dsetout.) eq %qupcase(%scan(&dsetin, 1, %str(%() )) %then                /*update to only look at dataset component only*/
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

  /* Validating ADSUPPJOINYN, ADDATETIMEYN, GETADSLVARSYN, ADGETTRTYN, ADVISITYN, ADPERIODYN, ADRELDAYSYN, DECODEYN, ATTRIBUTESYN and MISSCHKYN parameters */ 
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

  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;

/* Create work dataset if DSETIN contains dataset options */
  %if %index(&dsetin,%str(%() ) gt 0 %then 
  %do;
    data &prefix._dsetin;
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

    /* Deriving event dates to ADaM variable naming conventions */  /*pick up code from adae or adds*/
    
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
  data &prefix._derive_temp;
    LENGTH avalc $200 paramcd $8;
    set &lastdset;
      %if %tu_chkvarsexist(&lastdset.,&domain.TPT)=%str() %then ATPT=&domain.TPT;;
      %if %tu_chkvarsexist(&lastdset.,&domain.TPTREF)=%str() %then ATPTREF=&domain.TPTREF;;
      %if %tu_chkvarsexist(&lastdset.,&domain.TPTNUM)=%str() %then ATPTN=&domain.TPTNUM;;

      parcat1 = sucat;
      srcdom = "%UPCASE(&domain)";
      srcseq = &domain.seq;

      /* If EVALUATION PERIOD variables have not been previously created, then populate with null values */
      %IF %tu_chkvarsexist(&lastdset.,suevlint,Y)=%STR() %then suevlint='';;
      %IF %tu_chkvarsexist(&lastdset.,suevintx,Y)=%STR() %then suevintx='';; 
          
      IF UPCASE(sutrt) = "TOBACCO (CIGARETTE)" THEN DO;
        if suevlint='' and suevintx='' then do; /* Cigarette history */
          paramcd = "SUSMHS"; aval = .; avalc = suoccur; OUTPUT;
          if suoccur='Y' then do;
            %IF %tu_chkvarsexist(&lastdset.,sudostot)=%STR() %THEN %DO;
               IF UPCASE(sudosu) = "COUNT" AND UPCASE(sudosfrq) = "QD" THEN DO;
                 paramcd = "SUCGSMDY"; aval = sudostot; avalc = ''; srcvar='SUDOSTOT'; OUTPUT;
               END;
            %END;

            %IF %tu_chkvarsexist(&lastdset.,sudur)=%STR() %THEN %DO;
               paramcd = "SUSMYR";
               IF FIRST(UPCASE(sudur)) = "P" AND CHAR(UPCASE(sudur),LENGTH(sudur)) = "Y" THEN aval = INPUT(COMPRESS(sudur,,'A'),best.);
               avalc = ''; srcvar='SUDUR'; OUTPUT;
            %END;

            %IF %tu_chkvarsexist(&lastdset.,supkyr)=%STR() %THEN %DO;
                paramcd = "SUPKYR"; aval = INPUT(supkyr,best.); avalc = ''; srcvar='SUPKYR'; OUTPUT;
            %END;

            %IF %tu_chkvarsexist(&lastdset.,suendtc)=%STR() %THEN %DO;
               paramcd = "SUSMLSDT"; aval = .; avalc = IFC(INDEX(suendtc,'T'),SUBSTR(suendtc,1,10),suendtc); srcvar='SUENDTC'; OUTPUT;
            %END;
          END;
        END;
        ELSE DO;  /* Cigarettes in defined period */
          paramcd = "SUSMLV"; aval = .; avalc = suoccur; OUTPUT;

          %IF %tu_chkvarsexist(&lastdset.,susmdy)=%STR() %THEN %DO;
             if suoccur='Y' then do;
                paramcd = "SUSMDY"; avalc = susmdy; aval =.; srcvar='SUSMDY'; OUTPUT;
             end;      
          %END;
        END;
      END; * End of UPCASE(sutrt) = "TOBACCO (CIGARETTE)" ;

      ELSE IF UPCASE(sutrt) = "ALCOHOL" THEN DO;
        if suevlint='' and suevintx='' then do; /* Alcohol history */
          paramcd = "SUAL"; aval = .; avalc = suoccur; OUTPUT;
           
          %IF %tu_chkvarsexist(&lastdset.,sudose)=%STR() %THEN %DO;
             IF UPCASE(sudosfrq) = "QS" and sudosu='U' and suoccur='Y' THEN DO;
                paramcd = "SUALUNWK"; aval = sudose; avalc = ''; OUTPUT;
             END;
          %END;
        END; 
        ELSE DO; /* Alcohol used in defined period */
          paramcd = "SUALUS"; aval = .; avalc = suoccur; OUTPUT;   

         %IF %tu_chkvarsexist(&lastdset.,sustdtc)=%STR() %THEN %DO;
             if suoccur='Y' then do;
               paramcd = "SUFRALDT"; aval = .; avalc = IFC(INDEX(sustdtc,'T'),SUBSTR(sustdtc,1,10),sustdtc); /*put(ASTDT,DATE9.);*/ SRCVAR='SUSTDTC'; OUTPUT;
               IF index(sustdtc,'T')>0 then do;
                    paramcd = "SUFRALTM"; aval = .; avalc = substr(sustdtc,12); /* put(ASTTM,hhmm5.);*/ SRCVAR='SUSTDTC'; OUTPUT;
               end;             
             end;
          %END;
        END; 
      END; * End of UPCASE(sutrt) = "ALCOHOL" ;

      ELSE IF UPCASE(sutrt) = "CAFFEINE" THEN DO;
        if suevlint='' and suevintx='' then do; /* Caffeine history */      
          paramcd = "SUCF"; aval = .; avalc = suoccur; OUTPUT;
          %IF %tu_chkvarsexist(&lastdset.,sudose)=%STR() %THEN %DO;
             IF UPCASE(sudosu) = "SERVING" and suoccur='Y' THEN DO;
               paramcd = "SUCFSVDY"; aval = sudose; avalc = ''; srcvar='SUDOSE'; OUTPUT;
             END;
          %END;
        END; 
        ELSE DO; /* Caffeine used in defined period */
          paramcd = "SUCFUS"; aval = .; avalc = suoccur; OUTPUT;   

          %IF %tu_chkvarsexist(&lastdset.,sustdtc)=%STR() %THEN %DO;
             if suoccur='Y' then do;
               paramcd = "SUFRCFDT"; aval = .; avalc = IFC(INDEX(sustdtc,'T'),SUBSTR(sustdtc,1,10),sustdtc); /*put(ASTDT,DATE9.);*/ SRCVAR='SUSTDTC'; OUTPUT;
               IF index(sustdtc,'T')>0 then do;
                    paramcd = "SUFRCFTM"; aval = .; avalc = substr(sustdtc,12); /* put(ASTTM,hhmm5.);*/ SRCVAR='SUSTDTC'; OUTPUT;
               end;             
             end;
          %END;
        END;
      END; * End of UPCASE(sutrt) = "CAFFEINE" ;

      ELSE IF UPCASE(sutrt) = "TOBACCO" THEN DO;
        if suevlint='' and suevintx='' then do;  /* Tobacco use */
            paramcd = "SUSM"; aval = .; avalc = suoccur; OUTPUT;
        end;
        ELSE DO; /* Tobacco used in defined period */
          paramcd = "SUTOBUS"; aval = .; avalc = suoccur; OUTPUT;   

          %IF %tu_chkvarsexist(&lastdset.,sustdtc)=%STR() %THEN %DO;
             if suoccur='Y' then do;
               paramcd = "SUFRSMDT"; aval = .; avalc = IFC(INDEX(sustdtc,'T'),SUBSTR(sustdtc,1,10),sustdtc); /*put(ASTDT,DATE9.);*/ SRCVAR='SUSTDTC'; OUTPUT;
               IF index(sustdtc,'T')>0 then do;
                    paramcd = "SUFRSMTM"; aval = .; avalc = substr(sustdtc,12); /* put(ASTTM,hhmm5.);*/ SRCVAR='SUSTDTC'; OUTPUT;
               end;             
             end;
          %END;
        END;
      END; * End of UPCASE(sutrt) = "TOBACCO" ;

      ELSE IF UPCASE(sutrt) = "NICOTINE ORAL/TOPICAL USE" THEN DO;
        if suevlint='' and suevintx='' then do;  /* Nicotine use */
          paramcd = "SUNICTRT"; aval = .; avalc = suoccur; OUTPUT;
        end;
        ELSE PUT "WAR" "NING: Nicotine use not defined";
      END; * End of UPCASE(sutrt) = "NICOTINE ORAL/TOPICAL USE" ;

      ELSE IF UPCASE(sutrt) = "SMOKELESS TOBACCO" THEN DO;
        if suevlint='' and suevintx='' then do;  /* Smokeless Tobacco use */
           paramcd = "SUSLHS"; aval = .; avalc = suoccur; OUTPUT;

           %IF %tu_chkvarsexist(&lastdset.,suendtc)=%STR() %THEN %DO;
              if suoccur='Y' then do;
                paramcd = "SUSLLSDT"; aval = .; avalc = IFC(INDEX(suendtc,'T'),SUBSTR(suendtc,1,10),suendtc); SRCVAR='SUENDTC'; OUTPUT;
              end;
           %END;
        end;
        else DO;  /* Smokeless Tobbaco use in defined period */
           paramcd = "SUSMLSLV"; aval = .; avalc = suoccur; OUTPUT;
        END;
      END; * End of UPCASE(sutrt) = "SMOKELESS TOBACCO" ;

      ELSE IF UPCASE(sutrt) = "BETEL QUID/ARECA" THEN DO;
        if suevlint='' and suevintx='' then do; 
            paramcd = "SUBQHX"; aval = .; avalc = suoccur; OUTPUT;

            %IF %tu_chkvarsexist(&lastdset.,suendtc)=%STR() %THEN %DO;
               if suoccur='Y' then do;
                  paramcd = "SUBQLSDT"; aval = .; avalc = IFC(INDEX(suendtc,'T'),SUBSTR(suendtc,1,10),suendtc); SRCVAR='SUENDTC'; OUTPUT;
               end;
            %end;
        end;
        else do;
            paramcd = "SUBQLV"; aval = .; avalc = suoccur; OUTPUT;  
        end;
      END; * End of UPCASE(sutrt) = "BETEL QUID/ARECA" ;
  run;

  /* Last step after derivations and study-specific derivations */
  /* Derive source variables */
  DATA &prefix._derive;
    SET &prefix._derive_temp;
      * If DTYPE has not been previously created, define DTYPE with a null value ;
      %IF %tu_chkvarsexist(&lastdset.,dtype,Y)=%str() %THEN dtype = ' ';;
      IF dtype = '' and srcvar='' THEN DO; * If not a derived observation then set value of SRCVAR ;
        IF aval NE . THEN srcvar = "SUDOSE";
        ELSE IF avalc NE '' THEN srcvar = "SUOCCUR";
      END;
      ELSE IF dtype NE '' THEN DO; * If a derived observation then ensure values of SRCDOM and SRCSEQ are null ;
        IF srcdom NE '' THEN srcdom = '';
        IF srcvar NE '' THEN srcvar = '';
        IF srcseq NE . THEN srcseq = .; 
      END;
  RUN;
       
  %let lastdset=&prefix._derive;


  /* Calling tu_decode to derive codes or decodes using formats specified in &g_dsplanfile */

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
  %else 
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

%mend tc_adsu;
