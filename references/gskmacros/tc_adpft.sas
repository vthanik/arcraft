/******************************************************************************* 
| Program Name: tc_adpft.sas
|
| Program Version: 1 build 4
|
| HARP Compound/Study/Reporting Effort: 
|
| Program Purpose: To create the ADaM dataset of Pulmonary Function Tests domain using the SDTM XF
|                  and supplemental XF dataset.
|
| SAS Version: SAS v9.3
|
| Created By: Robert Croft (rlc25434)
| Date:       31/07/2014
|
|******************************************************************************* 
|
| Output: adamdata.adpft
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
| (@) tu_adbaseln
| (@) tu_times
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
| Examples:
|    %tc_adpft(
|         dsetin=sdtmdata.xf (where=(upcase(xfcat) eq 'PULMONARY FUNCTION TESTS')),
|         dsetout=adamdata.adpft,     
|         domain=XF,                  
|         adsuppjoinyn=Y,            
|         dsetinsupp=sdtmdata.suppxf, 
|         dsetinex=sdtmdata.ex,       
|         addatetimeyn=Y,             
|         datetimevars=xfdtc,         
|         getadslvarsyn=Y,            
|         dsetinadsl=adamdata.adsl,           
|         adslvars=siteid age sex race acountry trtsdt trtsdtm ittfl, 
|         adgettrtyn=Y,               
|         adgettrtmergevars=usubjid,  
|         adgettrtvars=trt01p trt01pn trt01a trt01an,  
|         decodeyn=Y,                 
|         decodepairs=,              
|         codepairs=paramn param,     
|         adreldaysyn=Y,            
|         dyrefdatevar=trtsdt,    
|         advisityn=Y,                
|         avisitnfmt=,               
|         avisitfmt=,                 
|         adperiodyn=N,              
|         adbaselnyn=Y,              
|         basen=19,                     
|         rederivebase=N,            
|         baselineoption=DATE,        
|         reldays=,                   
|         startvisnum=,               
|         endvisnum=,                 
|         baselinetype=LAST,          
|         derivedbaselinerowinfo=,    
|         firstdose=TRTSDTM,          
|         lastdose=EXENDTM,           
|         firstperdose=TRSDTM,        
|         timedate=ADTM,              
|         maximumyn=Y,                
|         minimumyn=Y,                
|         averageyn=Y,                
|         averagedescvisit=%str(avisitn=998;avisit='Average Post Baseline'),          
|         maxdescvisit=%str(avisitn=997;avisit='Maximum Post Baseline'),              
|         mindescvisit=%str(avisitn=996;avisit='Minimum Post Baseline'),              
|         maxminsubset=%str(ady gt 1 and aval ne .),              
|         timedevref=ALTRTTP,         
|         misschkyn=Y,                
|         attributesyn=Y             
|              );
|
|
|******************************************************************************* 
| Change Log 
|
| Modified By: Robert Croft (rlc25434)
| Date of Modification: 02/10/2014
|
| Modification ID: version 1 build 2
| Reason For Modification: Addition of tu_times macro. Baseline observations added for non-rederived
|                          baseline value. Maximum, minimum and average observations added for each subject per
|                          visit, timepoint and pulmonary function test
|
| Modified By: Robert Croft (rlc25434)
| Date of Modification: 07/11/2014
|
| Modification ID: version 1 build 3
| Reason For Modification: ALTRTTP derived differently from sdtmdata.ex and removal of change of baseline
|                          calculations for Pre-treatment records.
|
| Modified By: Robert Croft (rlc25434)
| Date of Modification: 17/12/2014
|
| Modification ID: version 1 build 4
| Reason For Modification: Maximum, minimum and average observations derivation adjusted so that each observation keeps
|                          its original VISIT and VISITNUM value
|                          
********************************************************************************/ 
%macro tc_adpft(dsetin=sdtmdata.xf (where=(upcase(xfcat) eq 'PULMONARY FUNCTION TESTS')), /* Input dataset SDTMDATA.XF */
               dsetout=adamdata.adpft,     /* Output dataset to be created */
               domain=XF,                  /* Domain of sdtm respiratory data, valid values: RE, XF */
               adsuppjoinyn=Y,             /* If supplemental dataset is required to be joined with parent domain Y/N */
               dsetinsupp=sdtmdata.suppxf, /* Input supplemental dataset SDTMDATA.SUPPXF */
               dsetinex=sdtmdata.ex,       /* Input dataset SDTMDATA.EX to merge EXENDTC variable */
               addatetimeyn=Y,             /* Flag to indicate if If tu_addatetime utility is to be executed Y/N */
               datetimevars=xfdtc,         /* Datetime variables in input dataset to be converted to numeric dates times datetimes*/
               getadslvarsyn=Y,            /* Flag to indicate if tu_adgetadslvars utility need to be called */
               dsetinadsl=adamdata.adsl,   /* Input ADSL or ADTRT dataset */          
               adslvars=siteid age sex race acountry trtsdt trtedt trtsdtm ittfl, /* List of variable from DSETINADSL dataset for tu_adgetadslvars utility to merge on by USUBJID*/
               adgettrtyn=Y,               /* Flag to indicate if tu_adgettrt utility is to be executed Y/N */
               adgettrtmergevars=usubjid,  /* Variables used to merge treatment information from DSETINADSL onto work dataset */
               adgettrtvars=trt01p trt01pn trt01a trt01an,  /* List of variables from treatment dataset DSETINADSL for tu_adgettrt utility to add to work dataset */
               decodeyn=Y,                 /* Flag to indicate if tu_decode utility is to be executed Y/N */
               decodepairs=,               /* A list of paired code/decode variables for which the decode is to be created*/ 
               codepairs=paramn param,     /* A list of paired code/decode variables for which the code is to be created*/
               adreldaysyn=Y,              /* Flag to indicate if tu_adreldays utility is to be executed*/
               dyrefdatevar=trtsdt,        /* Reference date variable for analysis relative days derivation: ADY, ASTDY, AENDY*/
               advisityn=Y,                /* Flag to indicate if tu_advisit utility is to be executed Y/N */
               avisitnfmt=,                /* Format used to derive AVISITN from VISITNUM*/
               avisitfmt=,                 /* Format used to derive AVISIT from VISIT*/ 
               adperiodyn=N,               /* Flag to indicate if tu_adperiod utility is to be executed Y/N */
               adbaselnyn=Y,               /* Flag to indicate if tu_adbaseln utility is to be executed Y/N */
               basen=,                     /* Specifies a visit number to represent baseline visit observation, Required if REDERIVEBASE = N */
               rederivebase=N,             /* Flag to specify whether the baseline will be re-derived according to BASELINEOPTION and BASELINETYPE or SDTM baseline flag Y/N */
               baselineoption=DATE,        /* Specifies the option which is used to identify the observations from which baseline will be determined, Required if REDERIVEBASELINEYN = Y */
               reldays=,                   /* Specifies the number of days prior to treatment start date, used to identify records to be considered as baseline, Required if BASELINEOPTION = RELDAY */
               startvisnum=,               /* Specifies the start VISITNUM and/or ATPTN values to be used to identify records to be considered as baseline, Required if BASELINEOPTION = VISIT/TPT/VISITTPT */
               endvisnum=,                 /* Specifies the end VISITNUM and/or ATPTN values to be used to identify records to be considered as baseline, Required if BASELINEOPTION = VISIT/TPT/VISITTPT */
               baselinetype=LAST,          /* Calculation of baseline option when there are multiple records following into baseline range, Required if REDERIVEBASELINEYN = Y */
               derivedbaselinerowinfo=,    /* Specifies user-defined SAS statement(s) which can be used to populate analysis visit/timepoint variables on derived baseline observations when BASELINETYPE = MEAN or MEDIAN */
               firstdose=TRTSDTM,          /* Specifies the first dose date/datetime variable to calculate time of first dose to timepoint */
               lastdose=EXENDTM,           /* Specifies the last dose date/datetime variable to calculate time of last dose to timepoint */
               firstperdose=TRSDTM,        /* Specifies the first period dose date/datetime variable to calculate time of first period dose to timepoint */
               timedate=ADTM,              /* Specifies the timepoint date/datetime variable to calculate time of (first/last/first period) dose to timepoint */
               maximumyn=N,                /* Flag to indicate if maximum row observations are to be created for repeated measures */
               minimumyn=N,                /* Flag to indicate if minimum row observations are to be created for repeated measures */
               averageyn=N,                /* Flag to indicate if average row observations are to be created for repeated measures */
               averagedescvisit=,          /* SAS statement(s) to define visit/timepoint variables on derived average observations, Required if MAXMINAVEYN = Y */
               maxdescvisit=,              /* SAS statement(s) to define visit/timepoint variables on derived maximum observations, Required if MAXMINAVEYN = Y */
               mindescvisit=,              /* SAS statement(s) to define visit/timepoint variables on derived minimum observations, Required if MAXMINAVEYN = Y */
               maxminsubset=,              /* SAS statement which can be used in a WHERE clause to subset rows to calculate new max, min and average observations, Required if MAXMINAVEYN = Y */
               timedevref=ALTRTTP,         /* Specifies the reference time deviation variable to derive the analysis relative time deviation ASTTMDV */
               misschkyn=Y,                /* Flag to indicate if tu_misschk utility is to be executed Y/N */
               attributesyn=Y              /* Flag to indicate if tu_attrib utility is to be executed Y/N */
               );


  /*
  / Echo parameter values and global macro variables to the log.
  /----------------------------------------------------------------------------*/

  %local MacroVersion;
  %let MacroVersion = 1 build 4;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_dsplanfile g_abort g_refdata);

  /*
  /  Set up local macro variables
  / ---------------------------------------------------------------------------*/

  %local prefix lastdset;   
  %let prefix = _adpft;

  /* 02/10/14 v1 build 2: Reassign DSETIN and DSETINSUPP parameter values if DOMAIN is equal to RE */
  %if %upcase(&domain.) = RE %then %do;
  %let dsetin = sdtmdata.&domain. (where=(&domain.cat eq 'PULMONARY FUNCTION TESTS'));
  %let dsetinsupp = sdtmdata.supp&domain.;
  %end;

  /*
  / PARAMETER VALIDATION
  /----------------------------------------------------------------------------*/

  %let dsetin            = %nrbquote(&dsetin.);
  %let dsetout           = %nrbquote(&dsetout.);
  %let domain            = %upcase(&domain.);
  %let adsuppjoinyn      = %nrbquote(%upcase(&adsuppjoinyn.));
  %let dsetinex          = %nrbquote(&dsetinex.);
  %let addatetimeyn      = %nrbquote(%upcase(&addatetimeyn.));
  %let getadslvarsyn     = %nrbquote(%upcase(&getadslvarsyn.));
  %let adgettrtyn        = %nrbquote(%upcase(&adgettrtyn.));
  %let advisityn         = %nrbquote(%upcase(&advisityn.));
  %let adperiodyn        = %nrbquote(%upcase(&adperiodyn.));
  %let adreldaysyn       = %nrbquote(%upcase(&adreldaysyn.));
  %let adbaselnyn        = %nrbquote(%upcase(&adbaselnyn.));
  %let maximumyn         = %nrbquote(%upcase(&maximumyn.));
  %let minimumyn         = %nrbquote(%upcase(&minimumyn.));
  %let averageyn         = %nrbquote(%upcase(&averageyn.));
  %let decodeyn          = %nrbquote(%upcase(&decodeyn.));
  %let attributesyn      = %nrbquote(%upcase(&attributesyn.));
  %let misschkyn         = %nrbquote(%upcase(&misschkyn.));
  %let firstdose         = %upcase(&firstdose.);
  %let lastdose          = %upcase(&lastdose.);
  %let firstperdose      = %upcase(&firstperdose.);
  %let timedate          = %upcase(&timedate.);


  /* Validating if non-missing values are provided for parameters DSETIN, DSETINEX and DSETOUT */
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

   %if &dsetinex. eq %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETINEX is a required parameter, provide a dataset name.;
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

  /* calling tu_chknames to validate name provided in DSETINEX parameter */
  %if %tu_chknames(%scan(&dsetinex, 1, %str(%() ), DATA ) ne %then %do;
     %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETINEX refers to dataset &dsetinex which is not a valid dataset name;
     %let g_abort = 1;
     %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;


  /* Validating if DSETINEX dataset exists */
  %if %SYSFUNC(EXIST(%scan(&dsetinex, 1, %str(%() ) )) NE 1 %then %do;
     %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETINEX refers to dataset %upcase("&dsetinex.") which does not exist.;
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

  /* Validating DOMAIN, ADSUPPJOINYN, ADDATETIMEYN, GETADSLVARSYN, ADGETTRTYN, ADVISITYN, ADPERIODYN, 
     ADBASELNYN, MAXIMUMYN, MINIMUMYN, AVERAGEYN, ADRELDAYSYN, DECODEYN, ATTRIBUTESYN, MISSCHKYN,
     FIRSTDOSE, LASTDOSE, FIRSTPERDOSE, TIMEDATE, MAXDESCVISIT, MINDESCVISIT, AVERAGEDESCVISIT and
     MAXMINSUBSET parameters */

  %if &domain. ne RE and &domain. ne XF %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DOMAIN should either be RE or XF.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
   
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

  %if &adbaselnyn. ne Y and &adbaselnyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ADBASELNYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &maximumyn. ne Y and &maximumyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter MAXIMUMYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

   %if &minimumyn. ne Y and &minimumyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter MINIMUMYN should either be Y or N.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

   %if &averageyn. ne Y and &averageyn. ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter AVERAGEYN should either be Y or N.;
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

  %if &firstdose. eq %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter FIRSTDOSE should be a DATETIME variable.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &lastdose. eq %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter LASTDOSE should be a DATETIME variable.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &firstperdose. eq %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter FIRSTPERDOSE should be a DATETIME variable.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &timedate. eq %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter TIMEDATE should be a DATETIME variable.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &maximumyn. eq Y and &maxdescvisit. eq %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter MAXDESCVISIT should be valid SAS statements when MAXIMUMYN equals Y.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &minimumyn. eq Y and &mindescvisit. eq %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter MINDESCVISIT should be valid SAS statements when MINIMUMYN equals Y.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &averageyn. eq Y and &averagedescvisit. eq %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter AVERAGEDESCVISIT should be valid SAS statements when AVERAGEYN equals Y.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if (&maximumyn. eq Y or &minimumyn. eq Y or &averageyn. eq Y) and &maxminsubset. eq %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter MAXMINSUBSET should be valid SAS statements when either MAXIMUMYN, MINIMUMYN or AVERAGEYN equals Y.;
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
    data &prefix._daterename;
    format ADT date9.;
    format ATM time5.;
    format ADTM datetime20.;
    set &prefix._date;
    %if %tu_chkvarsexist(&prefix._date,&domain.DT)=%str() %then ADT= &domain.DT; ;
    %if %tu_chkvarsexist(&prefix._date,&domain.TM)=%str() %then ATM= &domain.TM; ;
    %if %tu_chkvarsexist(&prefix._date,&domain.DTM)=%str() %then ADTM= &domain.DTM; ;
    run;

    %let lastdset=&prefix._daterename;

   %end;

  /* 07/11/14 Merge in EXENDTC variable from SDTMDATA.EX for calculation of last dose to timepoint */

  %if %length(%tu_chkvarsexist(&dsetinex, exendtc)) eq 0 and %length(%tu_chkvarsexist(&lastdset, &domain.tptnum)) eq 0 %then
  %do;
    
    %tu_addatetime(dsetin = &dsetinex.,
                   dsetout = &prefix._ex,
                   datevars = exendtc
                   );

    proc sort data=&prefix._ex out=&prefix._ex2 (keep=usubjid extrt exendtm);
    by usubjid exendtm;
    where exendtm > .;
    run;

    proc sort data=&lastdset.;
    by usubjid adtm;
    run;

    proc sql;
      create table &prefix._ex3 as
      select a.*, b.extrt, b.exendtm
      from &lastdset. a left join &prefix._ex2 b
      on a.usubjid = b.usubjid and a.adtm >= b.exendtm;
    quit; 

    proc sort data=&prefix._ex3;
    by usubjid &domain.testcd visitnum &domain.tptnum adtm exendtm;
    run;

    data &prefix._ex4;
    set &prefix._ex3;
    by usubjid &domain.testcd visitnum &domain.tptnum adtm exendtm;
    if last.adtm;
    run;

    %let lastdset=&prefix._ex4;

  %end;

  /* 07/11/14 End of new code */

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
                 eventtype= PL             
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

   /* Derivations */

    data &prefix._derive ;
    set &lastdset;
    %if %tu_chkvarsexist(&lastdset.,&domain.TPT)=%str() %then ATPT=&domain.TPT;;
    %if %tu_chkvarsexist(&lastdset.,&domain.TPTREF)=%str() %then ATPTREF=&domain.TPTREF;;
    %if %tu_chkvarsexist(&lastdset.,&domain.TPTNUM)=%str() %then ATPTN=&domain.TPTNUM;;

   /* Analysis variable */

    %if %length(%tu_chkvarsexist(&lastdset, &domain.STRESN)) eq 0 %then
      AVAL=&domain.STRESN;;

   /* Analysis variable (character) */

    %if %length(%tu_chkvarsexist(&lastdset, &domain.STRESC)) eq 0 %then
      AVALC=&domain.STRESC;;

   /* Parameter type variables */

    %if %length(%tu_chkvarsexist(&lastdset, &domain.TESTCD)) eq 0 %then
      PARAMCD=&domain.TESTCD;;

    %* Need to include units etc.;
    %if %length(%tu_chkvarsexist(&lastdset, &domain.TEST)) eq 0 and %length(%tu_chkvarsexist(&lastdset, &domain.STRESU)) eq 0 %then
    %do;

     if &domain.STRESU ne ' ' then do;
      PARAM=strip(&domain.TEST)||' ('||strip(&domain.STRESU)||')';
     end;
     else do;
      PARAM=strip(&domain.TEST);
     end;

    %end;

    run;

  %let lastdset=&prefix._derive;

  /* Create Baseline values and Change from baseline */

  /* Calling tu_adbaseln to derive  */

  %if %upcase(&adbaselnyn)=Y and %length(%tu_chkvarsexist(&lastdset, avisitn)) eq 0 and %length(%tu_chkvarsexist(&lastdset, atptn)) eq 0 %then
  %do;

  /* 07/11/14 Add sorting so that Pre-treatment change from baseline is not calculated */

    proc sort data=&lastdset. out=&prefix._basesort;
    by usubjid avisitn atptn;
    run;

  /* 07/11/14 End of new code */

    %tu_adbaseln(dsetin=&prefix._basesort,
                 dsetout=&prefix._baseln,
                 rederivebaselineyn=&rederivebase,
                 domaincode=&domain,
                 baselineoption=&baselineoption.,
                 reldays=&reldays,
                 startvisnum=&startvisnum.,
                 endvisnum=&endvisnum.,
                 baselinetype=&baselinetype.,
                 derivedbaselinerowinfo=&derivedbaselinerowinfo.,
                 dsetinadsl=&dsetinadsl,
                 adslvars=&adslvars.,
                 adgettrtmergevars=&adgettrtmergevars.,
                 adgettrtvars=&adgettrtvars
                 );

  /* Create Percentage Change from Baseline variable PCHG */

    data &prefix._derive2;
    set &prefix._baseln;

    if base ne . and aval ne . and a2indcd not in ('P','R') then do;
      PCHG=((AVAL-BASE)/BASE)*100;
    end;
    else do;
      PCHG=.;
    end;

    run;

    %let lastdset=&prefix._derive2;

    /*02/10/14 v1 build 2: Create Baseline observations for when baseline is not rederived */

    %if %upcase(&rederivebase)=N and &basen. ne %then
    %do;

     data &prefix._baseline;
     set &prefix._derive2;
     where ABLFL = 'Y';
     
     AVISITN = &basen.;
     AVISIT = 'Baseline';
     DTYPE = 'BASELINE';
     ABLFL = ' ';
      
     run;

     proc sort data=&prefix._baseline out=&prefix._baseline_1 nodupkey;
     by studyid usubjid paramcd;
     run;

     data &prefix._derive2_1;
     set &prefix._derive2 &prefix._baseline_1;
     run;

    %let lastdset=&prefix._derive2_1;

    %end;

  %end;

  /* Create Time duration variables */

    data &prefix._derive3;
    set &lastdset;

  /* 02/10/14 v1 build 2: Time from first dose to timepoint using tu_times */
    %if %length(%tu_chkvarsexist(&lastdset, &timedate.)) eq 0 and %length(%tu_chkvarsexist(&lastdset, &firstdose.)) eq 0 %then
    %do;
      if &timedate. ne . and &firstdose. ne . then do;
      %tu_times(dsetin =&lastdset.,
                unit   =m,
                start  =&firstdose.,
                end    =&timedate.,
                output =AFTRTTP,
                outputc=AFTRTTPC,
                negyn  =Y
                );

      /* Convert AFTRTTP into hours */
      AFTRTTP=(AFTRTTP)/60;
      AFTRTTPU='HRS';

      end;
      else do;
      AFTRTTPC=' ';
      AFTRTTP = . ;
      AFTRTTPU=' ';
      end;
    %end;

  /*02/10/14 v1 build 2: Time from last dose to timepoint using tu_times */
    %if %length(%tu_chkvarsexist(&lastdset, &timedate.)) eq 0 and %length(%tu_chkvarsexist(&lastdset, &lastdose.)) eq 0 %then
    %do;
      if &timedate. ne . and &lastdose. ne . then do;
      %tu_times(dsetin =&lastdset.,
                unit   =m,
                start  =&lastdose.,
                end    =&timedate.,
                output =ALTRTTP,
                outputc=ALTRTTPC,
                negyn  =Y
                );

      /* Convert ALTRTTP into hours */
      ALTRTTP=(ALTRTTP)/60;
      ALTRTTPU='HRS';

      end;
      else do;
      ALTRTTPC=' ';
      ALTRTTP = . ;
      ALTRTTPU=' ';
      end;

      %put RTW%str(ARNING:) Check the derivation of variable ALTRTTP is correctly being applied to the study data, may require post-processing.;

    %end;

  /*02/10/14 v1 build 2: Time from period first dose to timepoint using tu_times */
    %if %length(%tu_chkvarsexist(&lastdset, &timedate.)) eq 0 and %length(%tu_chkvarsexist(&lastdset, &firstperdose.)) eq 0 %then
    %do;
      if &timedate. ne . and &firstperdose. ne . then do;
      %tu_times(dsetin =&lastdset.,
                unit   =m,
                start  =&firstperdose.,
                end    =&timedate.,
                output =APFTRTP,
                outputc=APFTRTPC,
                negyn  =Y
                );

      /* Convert APFTRTP into hours */
      APFTRTP=(APFTRTP)/60;
      APFTRTPU='HRS';

      end;
      else do;
      APFTRTPC=' ';
      APFTRTP = . ;
      APFTRTPU=' ';
      end;
    %end;

  /* 02/10/14 v1 build 2: Analysis relative time deviation using new derivations */
    %if %length(%tu_chkvarsexist(&lastdset, &domain.ELTM)) eq 0 and &timedevref. ne %str() %then
    %do;
      if &domain.ELTM ne . then do;
      call is8601_convert('du','du',&domain.ELTM,APRELTM);

      /* Convert APRELTM into hours */

      APRELTM=((APRELTM)/60)/60;
      APRELTMU='HRS';

      ASTTMDV=&timedevref.-APRELTM;
      ASTTMDVU='HRS';

      /* Convert ASTTMDV into minutes to calculate ASTTMDVC */

      ASTTMDVM=ASTTMDV*60;
      ASTTMDVC=LEFT(TRIM(compress(put(int(ASTTMDVM/(60 * 24)),best.))||'d'||' '||compress(put(int(ASTTMDVM/60)-(int(ASTTMDVM/(60 * 24)) * 24),best.))||'h'||' '||compress(put(mod(ASTTMDVM,60),best.))||'m' ));
      
      drop ASTTMDVM;

      end;
      else do;
      ASTTMDV=.;
      ASTTMDVU=' ';
      ASTTMDVC=' ';
      end;
    %end;

    run;
       
    %let lastdset=&prefix._derive3;

  /* 17/12/14 v1 build 4: Derive the Maximum, Minimum and Average Post Baseline observations per visit/timepoint/pulmonary function test */

    proc sort data= &lastdset. out= &prefix._derive4;
    by studyid usubjid avisitn atptn paramcd;
    run;

    /* Maximum observations */
    %if %upcase(&maximumyn)=Y %then
    %do;
      data &prefix._max (drop=max);
      set &prefix._derive4 (where=(%unquote(&maxminsubset.)));
      by studyid usubjid avisitn atptn paramcd;
      retain max;
      if first.paramcd then max=.;
      if aval gt max then max=aval;
      if last.paramcd then do;
      ady=.;
      adt=.;
      atm=.;
      adtm=.;
      &domain.seq=.;
      &domain.dtc='';
      %if %length(%tu_chkvarsexist(&prefix._derive4, PPROTFL)) eq 0 %then %do;
      PPROTFL=' ';
      %end;
      %unquote(&maxdescvisit.);
      aval=max;
      dtype="MAXIMUM";
      chg=max-base;
      pchg=((max-base)/base)*100;
      ablfl=' ';
      %if %length(%tu_chkvarsexist(&prefix._derive4, AFTRTTP)) eq 0 %then %do;
      AFTRTTPC=' ';
      AFTRTTP = . ;
      AFTRTTPU=' ';
      %end;
      %if %length(%tu_chkvarsexist(&prefix._derive4, ALTRTTP)) eq 0 %then %do;
      ALTRTTPC=' ';
      ALTRTTP = . ;
      ALTRTTPU=' ';
      %end;
      %if %length(%tu_chkvarsexist(&prefix._derive4, APFTRTP)) eq 0 %then %do;
      APFTRTPC=' ';
      APFTRTP = . ;
      APFTRTPU=' ';
      %end;
      %if %length(%tu_chkvarsexist(&prefix._derive4, ASTTMDV)) eq 0 %then %do;
      ASTTMDV=.;
      ASTTMDVU=' ';
      ASTTMDVC=' ';
      %end;
      output;
      end;
      run;
    %end;
    %else %if %upcase(&maximumyn)=N %then
    %do;
      data &prefix._max;
      set _NULL_;
      run;
    %end;

    /* Minimum observations */
    %if %upcase(&minimumyn)=Y %then
    %do;
      data &prefix._min (drop=min);
      set &prefix._derive4 (where=(%unquote(&maxminsubset.)));
      by studyid usubjid avisitn atptn paramcd;
      retain min;
      if first.paramcd then min=aval;
      if aval lt min then min=aval;
      if last.paramcd then do;
      ady=.;
      adt=.;
      atm=.;
      adtm=.;
      &domain.seq=.;
      &domain.dtc='';
      %if %length(%tu_chkvarsexist(&prefix._derive4, PPROTFL)) eq 0 %then %do;
      PPROTFL=' ';
      %end;
      %unquote(&mindescvisit.);
      aval=min;
      dtype="MINIMUM";
      chg=min-base;
      pchg=((min-base)/base)*100;
      ablfl=' ';
      %if %length(%tu_chkvarsexist(&prefix._derive4, AFTRTTP)) eq 0 %then %do;
      AFTRTTPC=' ';
      AFTRTTP = . ;
      AFTRTTPU=' ';
      %end;
      %if %length(%tu_chkvarsexist(&prefix._derive4, ALTRTTP)) eq 0 %then %do;
      ALTRTTPC=' ';
      ALTRTTP = . ;
      ALTRTTPU=' ';
      %end;
      %if %length(%tu_chkvarsexist(&prefix._derive4, APFTRTP)) eq 0 %then %do;
      APFTRTPC=' ';
      APFTRTP = . ;
      APFTRTPU=' ';
      %end;
      %if %length(%tu_chkvarsexist(&prefix._derive4, ASTTMDV)) eq 0 %then %do;
      ASTTMDV=.;
      ASTTMDVU=' ';
      ASTTMDVC=' ';
      %end;
      output;
      end;
      run;
    %end;
    %else %if %upcase(&minimumyn)=N %then
    %do;
      data &prefix._min;
      set _NULL_;
      run;
    %end;

    /* Average observations */
    %if %upcase(&averageyn)=Y %then
    %do;
      data &prefix._mean (drop=total totalc count);
      set &prefix._derive4 (where=(%unquote(&maxminsubset.)));
      by studyid usubjid avisitn atptn paramcd;
      if first.paramcd then do;
      count=0;
      total=.;
      totalc=.;
      end;
      count+1;
      total+aval;
      totalc+chg;
      if last.paramcd then do;
      aval=total/count;
      chg=totalc/count;
      pchg=((totalc/count)/base)*100;
      dtype="AVERAGE";
      ady=.;
      adt=.;
      atm=.;
      adtm=.;
      &domain.seq=.;
      &domain.dtc='';
      %if %length(%tu_chkvarsexist(&prefix._derive4, PPROTFL)) eq 0 %then %do;
      PPROTFL=' ';
      %end;
      %unquote(&averagedescvisit.);
      %if %length(%tu_chkvarsexist(&prefix._derive4, AFTRTTP)) eq 0 %then %do;
      AFTRTTPC=' ';
      AFTRTTP = . ;
      AFTRTTPU=' ';
      %end;
      %if %length(%tu_chkvarsexist(&prefix._derive4, ALTRTTP)) eq 0 %then %do;
      ALTRTTPC=' ';
      ALTRTTP = . ;
      ALTRTTPU=' ';
      %end;
      %if %length(%tu_chkvarsexist(&prefix._derive4, APFTRTP)) eq 0 %then %do;
      APFTRTPC=' ';
      APFTRTP = . ;
      APFTRTPU=' ';
      %end;
      %if %length(%tu_chkvarsexist(&prefix._derive4, ASTTMDV)) eq 0 %then %do;
      ASTTMDV=.;
      ASTTMDVU=' ';
      ASTTMDVC=' ';
      %end;
      output;
      end;
      run;
    %end;
    %else %if %upcase(&averageyn)=N %then
    %do;
      data &prefix._mean;
      set _NULL_;
      run;
    %end;

    /* Bring all datasets together */

    data &prefix._derive5;
    set &prefix._derive4 &prefix._max &prefix._min &prefix._mean;
    run;

    %let lastdset = &prefix._derive5;
    

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
  %end;%else 
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

%mend tc_adpft;
