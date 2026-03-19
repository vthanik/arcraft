/*
| Macro Name:         tu_stdderive
|
| Macro Version:      1
|
| SAS Version:        8.2
|
| Created By:         Yongwei Wang (YW62951)
|
| Date:               13-Sep-2007
|
| Macro Purpose:      The will will derive several variables from existing variables
|                     based on standard algorithm given in Statistical Algorithm
|                     defined in IDSL LotusNotes Database
|
| Macro Design:       Procedure Style
|
| Input Parameters:
|
| Name                Description                                  Default
| -----------------------------------------------------------------------------------
| DSETIN              Specifies the dataset for which the          (Blank)
|                     derivations are to be done.
|                     Valid values: an existing dataset
|
| DSETOUT             Specifies the name of the output dataset to  (Blank)
|                     be created.
|                     Valid values: valid dataset name
|
| DEMODSET            Specifies the name of DEMO SI data set as    DMDATA.DEMO
|                     defined IDSL data set manager
|                     Valid values: Blank or an existing data set
|
| EXPOSUREDSET        Specifies the name of EXPOSURE SI data set   DMDATA.EXPOSURE
|                     as defined IDSL data set manager
|                     Valid values: Blank or an existing data set
|
| RANDALLDSET         Specifies the name of RANDALL SI data set    DMDATA.RANDALL
|                     as defined IDSL data set manager
|                     Valid values: Blank or an existing data set
|
| RANDDSET            Specifies the name of RANDALL SI data set    DMDATA.RAND
|                     as defined IDSL data set manager
|                     Valid values: Blank or an existing data set
|
| TMSLICEDSET         Specifies the name of TMSLICE SI data set    DMDATA.TMSLICE
|                     as defined IDSL data set manager
|                     Valid values: Blank or an existing data set
|
| VISITDSET           Specifies the name of TMSLICE SI data set    DMDATA.VISIT
|                     as defined IDSL data set manager
|                     Valid values: Blank or an existing data set
|
| BIRTHDTVAR          Specifies the name of birth date variable    BIRTHDT
|                     Valid values: Blank or a variable exists in
|                     &DEMODSET
|
| STUDYIDVAR          Specifies the name of study ID variable      STUDYID
|                     Valid values: Blank or a variable exists in
|                     &DSETIN
|
| SUBJIDVAR           Specifies the name of subject ID variable    SUBJID
|                     Valid values: Blank or a variable exists in
|                     &DSETIN
|
| EVENTSTDTVAR        Specifies the Name of assessment start date  (Blank)
|                     variable
|                     Valid values: Blank or a variable exists in
|                     &DSETIN
|
| EVENTSTTMVAR        Specifies the Name of assessment start time  (Blank)
|                     variable
|                     Valid values: Blank or a variable exists in
|                     &DSETIN
|
| EVENTENDTVAR        Specifies the name of assessment end date    (Blank)
|                     variable
|                     Valid values: Blank or a variable exists in
|                     &DSETIN
|
| EVENTENTMVAR        Specifies the name of assessment end time    (Blank)
|                     variable
|                     Valid values: Blank or a variable exists in
|                     &DSETIN
|
| DURATIONUNITS       Specifies the Units of event duration,        Days
|                     time from first dose, time from last dose
|                     time from treatment period first dose 
|                     Valid values: MINUTES, HOURS, DAYS, WEEKS, 
|                     MONTHS, YEARS or a list of combination of 
|                     units listed above wiht variable name in 
|                     fomrat UNIT(Variable). If (Variable) is not 
|                     given, the unit will be take as default units.
|                     Otherwise, the Unit is for the given variable 
|                     only.
|
| REFDATEDSETSUBSET   May be used regardless of the value of       (Blank)
|                     REFDATEOPTION in order to better select the
|                     reference date.
|
| REFDATEOPTION       The reference date will be used in the       Treat
|                     calculation of the age values.
|                     > TREAT - Trt start date from
|                     DMDATA.EXPOSURE
|                     > VISIT - Visit date from
|                     DMDATA.VISIT
|                     > RAND  - Randomization date from
|                     DMDATA.RAND
|                     > OTHER  Date from the
|                     REFDATESOURCEVAR
|                     variable on the
|                     REFDATESOURCEDSET
|                     dataset
|                     Valid values: TREAT, VISIT, RAND or OTHER
|
| REFDATESOURCEDSET   Required if REFDATEOPTION is OTHER. Use the  (Blank)
|                     variable REFDATESOURCEVAR from the
|                     REFDATESOURCEDSET.
|
| REFDATESOURCEVAR    Required if REFDATEOPTION is OTHER. Use the  (Blank)
|                     variable REFDATESOURCEVAR from the
|                     REFDATESOURCEDSET.
|
| REFDATEVISITNUM     Required if REFDATEOPTION is VISIT.          (Blank)
|
| REFTIMESOURCEVAR    Required if REFDATEOPTION is OTHER. Use the  (Blank)
|                     variable REFTIMESOURCEVAR from the
|                     REFDATESOURCEDSET.
|
| ACTEDYVAR           Specifies the name of derived variable for   (Blank)
|                     actual end day within study of an event
|                     Valid values: Blank or a valid SAS variable
|                     name
|
| ACTSDYVAR           Specifies the name of derived variable for   (Blank)
|                     Actual start day within study or an event
|                     Valid values: Blank or a valid SAS variable
|                     name
|
| ACTTRTVAR           Specifies the name of derived variable for   (Blank)
|                     ctual treatment at assessment time point
|                     Valid values: Blank or a valid SAS variable
|                     name
|
| DURATIONCVAR        Specifies the name of derived variable for   (Blank)
|                     duration of an event in character
|                     Valid values: Blank or a valid SAS variable
|                     name
|
| DURATIONUVAR        Specifies the name of derived variable for   (Blank)
|                     duration unit of an event
|                     Valid values: Blank or a valid SAS variable
|                     name
|
| DURATIONVAR         Specifies the name of derived variable for   (Blank)
|                     duration of an event
|                     Valid values: Blank or a valid SAS variable
|                     name
|
| EVENTAGEDAYVAR      Specifies the name of derived variable for   (Blank)
|                     age in days at event time
|                     Valid values: Blank or a valid SAS variable
|                     name
|
| EVENTAGEMONTHVAR    Specifies the name of derived variable for   (Blank)
|                     age in months at event time
|                     Valid values: Blank or a valid SAS variable
|                     name
|
| EVENTAGEWEEKVAR     Specifies the name of derived variable for   (Blank)
|                     age in weeks at event time
|                     Valid values: Blank or a valid SAS variable
|                     name
|
| EVENTAGEYEARVAR     Specifies the name of derived variable for   (Blank)
|                     age in years at event time
|                     Valid values: Blank or a valid SAS variable
|                     name
|
| PEREDYVAR           Specifies the name of derived variable for   (Blank)
|                     actual day within period of end of event
|                     Valid values: Blank or a valid SAS variable
|                     name
|
| PERSDYVAR           Specifies the name of derived variable for   (Blank)
|                     actual day within start of event
|                     Valid values: Blank or a valid SAS variable
|                     name
|
| PTRT1STCVAR         Specifies the name of derived variable Time  (Blank)
|                     from first treatment period dose to start
|                     of event in character
|                     Valid values: Blank or a valid SAS variable
|                     name
|
| PTRT1STVAR          Specifies the name of derived variable Time  (Blank)
|                     from first treatment period dose to start
|                     of event
|                     Valid values: Blank or a valid SAS variable
|                     name
|
| SEQVAR              Specifies the name of derived variable for   (Blank)
|                     sequence
|                     Valid values: Blank or a valid SAS variable
|                     name
|
| TPEREDYVAR          Specifies the name of derived variable for   (Blank)
|                     actual end day within treatment period
|                     Valid values: Blank or a valid SAS variable
|                     name
|
| TPERSDYVAR          Specifies the name of derived variable for   (Blank)
|                     actual start day within treatment period
|                     Valid values: Blank or a valid SAS variable
|                     name
|
| TRT1STCVAR          Specifies the name of derived variable Time  (Blank)
|                     from first dose to start of event in
|                     character
|                     Valid values: Blank or a valid SAS variable
|                     name
|
| TRT1STVAR           Specifies the name of derived variable for   (Blank)
|                     Time from first dose to start of the event
|                     Valid values: Blank or a valid SAS variable
|                     name
|
| TRTSTCVAR           Specifies the name of derived variable Time  (Blank)
|                     from last doset to start of event in
|                     character
|                     Valid values: Blank or a valid SAS variable
|                     name
|
| TRTSTVAR            Specifies the name of derived variable Time  (Blank)
|                     from last doset to start of event
|                     Valid values: Blank or a valid SAS variable
|                     name
|
| VSDTVAR             Specifies the name of derived variable for   (Blank)
|                     actual day within treatment period
|                     Valid values: Blank or a valid SAS variable
|                     name
|
| XPEREDYVAR          Specifies the name of derived variable for   (Blank)
|                     actual day in collection period end
|                     Valid values: Blank or a valid SAS variable
|                     name
|
| XPERSDYVAR          Specifies the name of derived variable for   (Blank)
|                     actual day in collection period start
|                     Valid values: Blank or a valid SAS variable
|                     name
|
| NODERIVEVARS        Specivies a lists the variables for which    (Blank)
|                     derivation is not to be done.
|                     Valid values: Blank or a string
|
| XOVARSFORPGYN       If derive crossover stydy specific           (Blank)
|                     variables for parallel study
|                     Valid values: Y or N
|----------------------------------------------------------------------------------------
| Output:
|
| The macro outputs the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETOUT           Req      Parameter specified dataset
| -----------------  -------  -------------------------------------------------
|
|----------------------------------------------------------------------------------------
| Global macro variables created: &G_STYPE
|----------------------------------------------------------------------------------------
| Macros called:
|(@) tr_putlocals
|(@) tu_abort
|(@) tu_chkvarsexist
|(@) tu_acttrt
|(@) tu_visitdt
|(@) tu_refdat
|(@) tu_perstd
|(@) tu_nobs
|(@) tu_putglobals
|(@) tu_tidyup
|----------------------------------------------------------------------------------------
| Example: (The following example derive variables for AE data set)
|   %tu_stdderive (
|      DSETIN              =dmdata.ae,
|      DSETOUT             =dmdata.ae,
|      DEMODSET            =dmdata.DEMO,
|      EXPOSUREDSET        =dmdata.EXPOSURE,
|      RANDALLDSET         =dmdata.RANDALL,
|      RANDDSET            =dmdata.RAND,
|      TMSLICEDSET         =dmdata.TMSLICE,
|      VISITDSET           =dmdata.VISIT,
|      BIRTHDTVAR          =BIRTHDT,
|      STUDYIDVAR          =STUDYID,
|      SUBJIDVAR           =SUBJID,
|      EVENTSTDTVAR        =aestdt,
|      EVENTSTTMVAR        =aeacttm,
|      EVENTENDTVAR        =aeendt,
|      DURATIONUNITS       =days,
|      REFDATEOPTION       =treat,
|      ACTEDYVAR           =aeactedy,
|      ACTSDYVAR           =aeactsdy,
|      DURATIONUVAR        =aeduru,
|      DURATIONVAR         =aedur,
|      PERSDYVAR           =aepersdy,
|      PEREDYVAR           =aeperedy,
|      PERTSTDTVAR         =pertstdt,
|      TPEREDYVAR          =tperedy,
|      TPERSDYVAR          =tpersdy,
|      XPEREDYVAR          =xperedy,
|      XPERSDYVAR          =xpersdy
|      );
|----------------------------------------------------------------------------------------
| Change Log
|
| Modified By:              Yongwei Wang
| Date of Modification:     16-Jan-2008
| New version/draft number: 1/2
| Modification ID:          YW001
| Reason For Modification:  fixed a NOTE "Note: Variable exsttm is uninitialized", which
|                           was found during UAT. 
|
| Modified By:
| Date of Modification:
| New version/draft number:
| Modification ID:
| Reason For Modification:
|
|--------------------------------------------------------------------------------------*/

%macro tu_stdderive (
   DSETIN              =,                  /* Input data set */
   DSETOUT             =,                  /* Output data set */
   DEMODSET            =DMDATA.DEMO,       /* Name of DEMO data set */
   EXPOSUREDSET        =DMDATA.EXPOSURE,   /* Name of EXPOSURE data set */
   RANDALLDSET         =DMDATA.RANDALL,    /* Name of RANDALL data set */
   RANDDSET            =DMDATA.RAND,       /* Name of RAND data set */
   TMSLICEDSET         =DMDATA.TMSLICE,    /* Name of TMSLICE data set */
   VISITDSET           =DMDATA.VISIT,      /* Name of VISIT data set */

   BIRTHDTVAR          =BIRTHDT,           /* Name of birth date variable */
   STUDYIDVAR          =STUDYID,           /* Name of study ID variable */
   SUBJIDVAR           =SUBJID,            /* Name of subject ID variable */
   EVENTSTDTVAR        =,                  /* Name of assessment start date variable */
   EVENTSTTMVAR        =,                  /* Name of assessment start time variable */
   EVENTENDTVAR        =,                  /* Name of assessment end date variable */
   EVENTENTMVAR        =,                  /* Name of assessment end time variable */
   DURATIONUNITS       =Days,              /* Units of event duration, time from first dose, time from last do time from treatment period first dose. ( i.e. DAYS HOURS(AEDUR) MINUTES(ADTRTST) ) */
   REFDATEDSETSUBSET   =,                  /* WHERE clause applied to source dataset */
   REFDATEOPTION       =Treat,             /* Reference date source option */
   REFDATESOURCEDSET   =,                  /* Reference date source dataset */
   REFDATESOURCEVAR    =,                  /* Reference date source date variable */
   REFDATEVISITNUM     =,                  /* Specific visit number at which reference date is to be taken */
   REFTIMESOURCEVAR    =,                  /* Reference time source time variable */

   ACTEDYVAR           =,                  /* Derived variable for actual end day within study of an event */
   ACTSDYVAR           =,                  /* Derived variable for actual start day within study or an event */
   ACTTRTVAR           =,                  /* Derived variable for actual treatment at assessment time point */
   DURATIONCVAR        =,                  /* Derived variable for duration of an event - character */
   DURATIONUVAR        =,                  /* Derived variable for duration unit of an event */
   DURATIONVAR         =,                  /* Derived variable for duration of an event */
   EVENTAGEDAYVAR      =,                  /* Derived variable for age in days at event time */
   EVENTAGEMONTHVAR    =,                  /* Derived variable for age in months at event time */
   EVENTAGEWEEKVAR     =,                  /* Derived variable for age in weeks at event time */
   EVENTAGEYEARVAR     =,                  /* Derived variable for age in years at event time */
   PEREDYVAR           =,                  /* Derived variable for actual day within period of end of event */
   PERSDYVAR           =,                  /* Derived variable for actual day within start of event */
   PTRT1STCVAR         =,                  /* Time from first treatment period dose to start of event - character */
   PTRT1STVAR          =,                  /* Time from first treatment period dose to start of event */
   SEQVAR              =,                  /* Derived variable for sequence */
   TPEREDYVAR          =,                  /* Derived variable for actual end day within treatment period */
   TPERSDYVAR          =,                  /* Derived variable for actual start day within treatment period */
   TRT1STCVAR          =,                  /* Time from first dose to start of event  character */
   TRT1STVAR           =,                  /* Time from first dose to start of the event */
   TRTSTCVAR           =,                  /* Time from last dose to start of event  character */
   TRTSTVAR            =,                  /* Time from last dose to start of event */
   VSDTVAR             =,                  /* Derived variable for actual day within treatment period */
   XPEREDYVAR          =,                  /* Derived variable for actual day in collection period end */
   XPERSDYVAR          =,                  /* Derived variable for actual day in collection period start */
   NODERIVEVARS        =,                  /* List of variables to not be derived */
   XOVARSFORPGYN       =                   /* If derive crossover stydy specific variables for parallel study */
   );

   /*
   / Echo parameter values and global macro variables to the log.
   /----------------------------------------------------------------------------*/

   %local MacroVersion;
   %let MacroVersion = 1;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals(varsin=g_stype);

   %local prefix i refdatevar xovars listvars thisvar loopi byvars dropvars
          persdyvar1 tpersdyvar1 xpersdyvar1 pos len rx tmpvar1 tmpvar2
          derivevar derivecvar deriveunit startdatevar enddatevar starttimevar endtimevar
           /* local variables for unit */
          durationunit ptrt1stunit trt1stunit trtstunit stdunit durationunitsold;


   %let prefix=_stdderive;   /* Root name for temporary work datasets */
   %let durationunits=%qupcase(&durationunits);

   /* save &actsdyvar, &tpersdyvar and &xpersdyvar */
   %let persdyvar1=&persdyvar;
   %let tpersdyvar1=&tpersdyvar;
   %let xpersdyvar1=&xpersdyvar;

   %let noderivevars=%qupcase(&noderivevars);
   %let xovars=%qupcase(&PTRT1STVAR &PTRT1STCVAR &PERSDYVAR &PEREDYVAR &XPEREDYVAR &TPERSDYVAR &XPEREDYVAR &XPERSDYVAR);

   /*
   / PARAMETER VALIDATION
   /----------------------------------------------------------------------------*/

   /*
   / Check required parameter DSETIN DSETOUT and XOVARSFORPGYN are not blank
   /----------------------------------------------------------------------------*/

   %let listvars=DSETIN DSETOUT XOVARSFORPGYN;

   %do loopi=1 %to 3;
      %let thisvar=%scan(&listvars, &loopi, %str( ));
      %let &thisvar=%nrbquote(&&&thisvar);

      %if &&&thisvar eq %then
      %do;
         %put %str(RTE)RROR: &sysmacroname: The parameter &thisvar is required.;
         %let g_abort=1;
      %end;
   %end;  /* end of do-to loop */

   /*
   / Check if XOVARSFORPGPGYN is Y or N
   /----------------------------------------------------------------------------*/

   %if ( %qupcase(&XOVARSFORPGYN) ne Y ) and ( %qupcase(&XOVARSFORPGYN) ne N ) %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: XOVARSFORPGYN(=&XOVARSFORPGYN) should be either Y or N.;
      %let g_abort=1;
   %end;

   /*
   / Check that required dataset &DSETIN exists.
   /----------------------------------------------------------------------------*/

   %if &dsetin ne %then
   %do;

      %if %tu_nobs(&dsetin) lt 0 %then
      %do;
         %put %str(RTE)RROR: &sysmacroname: The dataset DSETIN(=&dsetin) does not exist.;
         %let g_abort=1;
      %end;

   /*
   / If the input dataset name is the same as the output dataset name,
   / write a note to the log.
   /----------------------------------------------------------------------------*/
      %if %qscan(&dsetin, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
      %do;
         %put %str(RTN)OTE: &sysmacroname: The input dataset name DSETIN(=&dsetin) is the same as the output dataset name DSETOUT(=&dsetout).;
      %end;

   %end; /* end-if on &dsetin ne */

   /*
   / Validate that &DURATIONUNITS is valid
   /----------------------------------------------------------------------------*/

   %let durationunitsold=&durationunits;
   %let durationunits=%upcase(&durationunits);
   %let listvars=DURATION TRTST TRT1ST PTRT1ST;

   %let rx=%sysfunc(rxparse($(10)));
   %let pos=0;
   %let len=0;
   %syscall rxsubstr(rx, durationunits, pos, len);
   %do %while ((&pos gt 0) and (&len gt 0));
      %if &len le 3 or &pos le 1 %then
      %do;
         %put %str(RTE)RROR: &sysmacroname: Value of DURATIONUNITS(=&durationunitsold) is invalid;
         %put %str(RTE)RROR: &sysmacroname: Valid value should like WEEKS or WEEKS DAYS(AEDUR) MONTH(ADDUR), etc;
         %let g_abort=1;
         %goto endmac;
      %end;
      %let dropvars=%qsubstr(&durationunits, 1, %eval(&pos - 1));
      %let tmpvar2=%qsubstr(&durationunits, %eval(&pos + 1), %eval(&len - 2));
      %if %eval(&pos + &len + 1) lt %length(&durationunits) %then
         %let durationunits=%qsubstr(&durationunits, %eval(&pos + &len + 1));
      %else %let durationunits=;
      %let tmpvar1=%scan(&dropvars, -1);
      %let dropvars=%scan(&dropvars, 1);
      %if %qscan(&dropvars, 3) ne %then
      %do;
         %put %str(RTE)RROR: &sysmacroname: Value of DURATIONUNITS(=&durationunitsold) is invalid;
         %put %str(RTE)RROR: &sysmacroname: Valid value should like WEEKS or WEEKS DAYS(AEDUR) MONTH(ADDUR), etc;
         %let g_abort=1;
         %goto endmac;
      %end;
      %if %nrbquote(&dropvars) ne %nrbquote(&tmpvar1) %then
      %do;
         %if %nrbquote(&stdunit) ne %then
         %do;
            %put %str(RTE)RROR: &sysmacroname: Value of DURATIONUNITS(=&durationunitsold) is invalid;
            %put %str(RTE)RROR: &sysmacroname: Valid value should like WEEKS or WEEKS DAYS(AEDUR) MONTH(ADDUR), etc;
            %let g_abort=1;
            %goto endmac;
         %end;
         %else %let stdunit=&dropvars;
      %end;
      %do loopi=1 %to 4;
         %if %nrbquote(%unquote(&&%scan(&listvars, &loopi)var)) ne %then
         %do;
            %if %sysfunc(indexw(%upcase(&tmpvar2), %upcase(%unquote(&&%scan(&listvars, &loopi)var)))) gt 0 %then %let %scan(&listvars, &loopi)unit=&tmpvar1;
         %end;
      %end;
      %let pos=0;
      %let len=0;
      %let durationunits=%unquote(&durationunits);
      %syscall rxsubstr(rx, durationunits, pos, len);
   %end;

   %syscall rxfree(rx);

   %if %nrbquote(&stdunit) ne and %nrbquote(&durationunits) ne %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: Value of DURATIONUNITS(=&durationunitsold) is invalid;
      %put %str(RTE)RROR: &sysmacroname: Valid value should like WEEKS or WEEKS DAYS(AEDUR) MONTH(ADDUR), etc;
      %let g_abort=1;
      %goto endmac;
   %end;

   %if %nrbquote(&durationunits) ne %then %let stdunit=&durationunits;

   %if %nrbquote(&stdunit) eq %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: Overall unit is not given in DURATIONUNITS(=&durationunitsold).;
      %let g_abort=1;
   %end;

   %if %sysfunc(indexw(MINUTES HOURS DAYS WEEKS MONTHS YEARS, &stdunit)) le 0  %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: Overunit (=&stdunit) given in DURATIONUNITS(=&durationunitsold) must be Minutes, Hours, Days Years, Months and Weeks.;
      %let g_abort=1;
   %end;
   %else %if &stdunit eq MONTHS %then stdunit=mo;
   %else %let stdunit=%lowcase(%substr(&stdunit, 1, 1));

   %do loopi=1 %to 4;
      %if %nrbquote(%unquote(&&%scan(&listvars, &loopi)unit)) eq %then
      %do;
         %let %scan(&listvars, &loopi)unit=&stdunit;
      %end;
      %else %do;
         %let tmpvar1=%unquote(&&%scan(&listvars, &loopi)unit);
         %if %sysfunc(indexw(MINUTES HOURS DAYS WEEKS MONTHS YEARS, &tmpvar1)) le 0  %then
         %do;
            %put %str(RTE)RROR: &sysmacroname: Unit (&tmpvar1) given in DURATIONUNITS(=&durationunits) for variable %scan(&listvars, &loopi) must be Minutes, Hours, Days Years, Months and Weeks.;
            %let g_abort=1;
         %end;
         %else %if &tmpvar1 eq MONTHS %then %let %scan(&listvars, &loopi)unit=mo;
         %else %let %scan(&listvars, &loopi)unit=%lowcase(%substr(&tmpvar1, 1, 1));
      %end;
   %end; /* %do loopi=1 %to 8 */

   %if &g_abort gt 0 %then %goto endmac;

   /*
   /  Variable &XOVARS is/are for crossover study. If the study is parallel,
   /  write a RTNOTE to the log.
   /---------------------------------------------------------------------------*/

   %if ( %qupcase(&XOVARSFORPGYN) eq N ) and ( %qupcase(&g_stype) eq PG ) and ( %nrbquote(&xovars) ne ) %then
   %do;
      %put %str(RTN)OTE: &sysmacroname: Period related variable &xovars will not be derived for parallel study.;
   %end;
   %else %let xovars=;

   /*
   / NORMAL PROCESSING
   /----------------------------------------------------------------------------*/

   /*
   / Initialise counter for appending to temporary dataset names for the
   / purpose of tracking datasets through a number of optional sequential
   / data processing steps.
   /----------------------------------------------------------------------------*/

   %let i = 1;

   data &prefix._temp&i;
      set %unquote(&dsetin);
   run;

   /*
   /  If a deriving variable is in &NODERIVEVARS or it already exists, do not
   /  derive it and write a RTNOTE to the log file to let user know that the
   /  variable will not be derived.
   /----------------------------------------------------------------------------*/

   %let listvars=ACTEDYVAR ACTSDYVAR ACTTRTVAR DURATIONUVAR DURATIONVAR
                 EVENTAGEDAYVAR EVENTAGEMONTHVAR EVENTAGEWEEKVAR EVENTAGEYEARVAR
                 PEREDYVAR PERSDYVAR SEQVAR TPEREDYVAR
                 TPERSDYVAR VSDTVAR XPEREDYVAR XPERSDYVAR TRT1STVAR TRTSTVAR
                 TRT1STCVAR TRTSTCVAR PTRT1STVAR PTRT1STCVAR DURATIONCVAR
                 ;

   %do loopi=1 %to %tu_words(&listvars);
      %let thisvar=%scan(&listvars, &loopi);
      %if %nrbquote(&&&thisvar) ne %then
      %do;
         %if %sysfunc(indexw(&xovars, %upcase(&&&thisvar))) gt 0 %then
         %do;
            %put %str(RTN)OTE: &sysmacroname: Variable &thisvar(=&&&thisvar) is in XOVARS(=&xovars) and will not be derived for parallel study.;
            %put %str(RTN)OTE: &sysmacroname: Please set XOVARSFORPGYN to Y to derive it.;
            %let &thisvar=;
         %end;
         %else %if %sysfunc(indexw(&noderivevars, %upcase(&&&thisvar))) gt 0 %then
         %do;
            %put %str(RTN)OTE: &sysmacroname: Variable &thisvar(=&&&thisvar) is in NODERIVEVARS(=&noderivevars) and will not be derived.;
            %let &thisvar=;
         %end;
         %else %if %tu_chkvarsexist(&prefix._temp&i, &&&thisvar) eq %then
         %do;
            %put %str(RTW)ARNING: &sysmacroname: Variable &thisvar(=&&&thisvar) already exists in DSETIN (=&dsetin) and will not be derived.;
            %let &thisvar=;
         %end;
      %end; /* %if %nrbquote(&&&thisvar) ne */
   %end; /* %do loopi=1 %to %tu_words(&listvars) */

   /*
   / Call %tu_visitdt to derived Date based on VISITNUM.
   / Derived variables: &VSDTVAR
   / Note: VISITNUM should be validated in %tu_visitdt. Because tu_visitdt
   / current create RTERRORS if VISITNUM doesn't exist. So, it is checked here.
   /----------------------------------------------------------------------------*/

   %if %nrbquote(&vsdtvar) ne %then
   %do;
      %if %tu_chkvarsexist(&prefix._temp&i, VISITNUM) ne %then
      %do;
         %put %str(RTW)ARNING: &sysmacroname: VISITNUM does not exist in input data set and variable &vsdtvar will not be derived.;
         %let vsdtvar=;
      %end;
   %end;

   %if %nrbquote(&vsdtvar) ne %then
   %do;
      %if %tu_chkvarsexist(&prefix._temp&i, VISITNUM) eq %then
      %do;
         %tu_visitdt(
             dsetin    =&prefix._temp&i,
             dsetout   =&prefix._temp%eval(&i+1),
             visitdset =&visitdset,
             varname   =&vsdtvar.
             );
         %let i = %eval(&i + 1);
      %end;
   %end; /* end-if on %nrbquote(&vsdtvar) ne */

   /*
   / Call %tu_perstd to derive period day.
   / Derived variables: &PERSDYVAR, &XPERSDYVAR, &TPERSDYVAR
   /----------------------------------------------------------------------------*/

   %if %nrbquote(&persdyvar.&xpersdyvar.&tpersdyvar.&ptrt1stvar) ne %then
   %do;
      %if %nrbquote(&eventsttmvar) ne %then
      %do;
         %if %tu_chkvarsexist(&prefix._temp&i, &eventsttmvar) ne %then
         %do;
            %put %str(RTN)OTE: &sysmacroname: Time variable &eventsttmvar does not exist in DSETIN (=&dsetin).;
            %put %str(RTN)OTE: &sysmacroname: It will not be used to derive PTRT1STVAR(=&ptrt1stvar), PERSDYVAR(=&persdyvar), TPERSDYVAR(=&tpersdyvar) or XPERSDYVAR(=&xpersdyvar).;
            %let eventsttmvar=;
         %end;
      %end;
      %else %do;
         %put %str(RTN)OTE: &sysmacroname: Time variable is not given and will not be used to derive &persdyvar.;
      %end; /* end-if on %nrbquote(&eventsttmvar) ne */

      %if %tu_chkvarsexist(&prefix._temp&i, &eventstdtvar) ne %then
      %do;
         %put %str(RTW)ARNING: &sysmacroname: Variable &eventstdtvar does not exist in DSETIN (=&dsetin).;
         %put %str(RTW)ARNING: &sysmacroname: PTRT1STVAR(=&ptrt1stvar), PERSDYVAR(=&persdyvar), TPERSDYVAR(=&tpersdyvar), XPERSDYVAR(=&xpersdyvar) can not be derived.;
         %let persdyvar=;
         %let xpersdyvar=;
         %let tpersdyvar=;
         %let ptrt1stvar=;
      %end;
   %end;

   %if %nrbquote(&persdyvar.&xpersdyvar.&tpersdyvar.&ptrt1stvar) ne %then
   %do;
      %if %nrbquote(&persdyvar)  eq %then %let persdyvar =__persdyvar__;
      %if %nrbquote(&xpersdyvar) eq %then %let xpersdyvar=__xpersdyvar__;
      %if %nrbquote(&tpersdyvar) eq %then %let tpersdyvar=__tpersdyvar__;

      %tu_perstd(
         dsetin       =&prefix._temp&i,
         dsetout      =&prefix._temp%eval(&i+1),
         exposuredset =&exposuredset,
         refdat       =&eventstdtvar,
         reftim       =&eventsttmvar,
         tmslicedset  =&tmslicedset,
         varname      =&persdyvar,
         vartname     =&tpersdyvar,
         varxname     =&xpersdyvar,
         visitdset    =&visitdset
         );

      %let i = %eval(&i + 1);
      %let dropvars=;

      %if %nrbquote(&persdyvar) eq __persdyvar__  %then
      %do;
         %if %tu_chkvarsexist(&prefix._temp&i,&persdyvar) eq %then %let dropvars=&dropvars &persdyvar;
         %let persdyvar=;
      %end;
      %if %nrbquote(&tpersdyvar) eq __tpersdyvar__  %then
      %do;
         %if %tu_chkvarsexist(&prefix._temp&i,&tpersdyvar) eq %then %let dropvars=&dropvars &tpersdyvar;
         %let tpersdyvar=;
      %end;
      %if %nrbquote(&xpersdyvar) eq __xpersdyvar__  %then
      %do;
         %if %tu_chkvarsexist(&prefix._temp&i,&xpersdyvar) eq %then %let dropvars=&dropvars &xpersdyvar;
         %let tpersdyvar=;
      %end;

      %if %nrbquote(&ptrt1stvar) ne %then
      %do;
         %if %tu_chkvarsexist(&prefix._temp&i, pertstdt) ne %then %let ptrt1stvar=;
      %end;

      %if %nrbquote(&dropvars) ne %then
      %do;
         data &prefix._temp%eval(&i+1);
            set &prefix._temp&i;
            %if %nrbquote(&dropvars) ne %then
            %do;
               drop &dropvars;
            %end;
         run;
         %let i = %eval(&i + 1);
      %end;
   %end; /* end-if on %nrbquote(&persdyvar) ne */

   /*
   / For deriving &TRTSTVAR or TRT1STVAR, add _firstdose_ and _lastdose_ to
   / data set.  _firstdose_ and _lastdose_ will be droped after the derivation
   / of &TRTSTVAR or TRT1STVAR.
   /----------------------------------------------------------------------------*/
   
   %let thisvar=%nrbquote(&TRTSTVAR.&TRT1STVAR);

   %if %nrbquote(&thisvar) ne %then
   %do;
      %if %nrbquote(&exposuredset) eq %then
      %do;
         %put %str(RTW)ARNING: &sysmacroname: Can not derive TRTSTVAR(=&trtstvar) or TRT1STVAR(=&trt1stvar) because parameter EXPOSUREDSET is blank.;
         %let thisvar=;
      %end;
      %else %if %qsysfunc(exist(%qscan(&exposuredset, 1, %str(%()))) le 0 %then
      %do;
         %put %str(RTW)ARNING: &sysmacroname: Can not derive TRTSTVAR(=&trtstvar) or TRT1STVAR(=&trt1stvar) because data set EXPOSUREDSET (=&exposuredset) does not exist.;
         %let thisvar=;
      %end;
      %else %do;
         data &prefix.exposure;
            set %unquote(&exposuredset);
         run;
      %end;
      %if %nrbquote(&eventstdtvar) ne %then
      %do;
         %if %tu_chkvarsexist(&prefix._temp&i, &eventstdtvar) ne %then
         %do;
            %put %str(RTW)ARNING: &sysmacroname: Can not derive TRTSTVAR(=&trtstvar) or TRT1STVAR(=&trt1stvar) because EVENTSTDTVAR(=&eventstdtvar) does not exist in DSETIN(=&dsetin).;
            %let thisvar=;         
         %end;
      %end;
      %else %do;      
         %put %str(RTW)ARNING: &sysmacroname: Can not derive TRTSTVAR(=&trtstvar) or TRT1STVAR(=&trt1stvar) because EVENTSTDTVAR is not given.;
         %let thisvar=;
      %end; 
      %if %nrbquote(&studyidvar) ne %then
      %do;
         %if %tu_chkvarsexist(&prefix._temp&i, &studyidvar) ne %then
         %do;
            %put %str(RTW)ARNING: &sysmacroname: Can not derive TRTSTVAR(=&trtstvar) or TRT1STVAR(=&trt1stvar) because STUDYIDVAR(=&studyidvar) does not exist in DSETIN(=&dsetin).;            
            %let thisvar=;            
         %end;
      %end;
      %if %nrbquote(&subjidvar) ne %then
      %do;
         %if %tu_chkvarsexist(&prefix._temp&i, &subjidvar) ne %then
         %do;
            %put %str(RTW)ARNING: &sysmacroname: Can not derive TRTSTVAR(=&trtstvar) or TRT1STVAR(=&trt1stvar) because SUBJIDVAR(=&subjidvar) does not exist in DSETIN(=&dsetin).;            
            %let thisvar=;         
         %end;
      %end;           
   %end; /* %if %nrbquote(&TRTSTVAR) ne or %nrbquote(&TRT1STVAR) ne */

   %if %nrbquote(&thisvar) ne %then
   %do;
      %if %nrbquote(&eventsttmvar) ne %then
      %do;
         %if %tu_chkvarsexist(&prefix._temp&i, &eventsttmvar) ne %then
         %do;
            %put %str(RTN)OTE: &sysmacroname: Variable EVENTSTTMVAR(=&eventsttmvar) does not exist in DSETIN(=&dsetin) and will be set to blank.;
            %let eventsttmvar=;
         %end;
      %end;

      /* if exendt does not exist, or has no non-missing values, use exstdt */
      %let enddatevar=exendt;
      %let endtimevar=exentm;
      %let starttimevar=exsttm;

      %if %tu_chkvarsexist(&prefix.exposure, &enddatevar) ne %then %let enddatevar=;
      %if %nrbquote(&eventsttmvar) eq %then %let starttimevar=;
      %if %nrbquote(&eventsttmvar) eq %then %let endtimevar=;

      %if %nrbquote(&enddatevar) ne %then
      %do;
          %let loopi=0;
          proc sql noprint;
             select count(*) into :loopi
             from &prefix.exposure
             where not missing(&enddatevar)
             ;
          quit;
          %if &loopi eq 0 %then %let enddatevar=;
      %end;

      %if %nrbquote(&enddatevar) eq %then %let endtimevar=;

      %if %nrbquote(&endtimevar) ne %then
      %do;
         %if %tu_chkvarsexist(&prefix.exposure, &endtimevar) ne %then  %let endtimevar=;
      %end;

      %if %nrbquote(&starttimevar) ne %then
      %do;
         %if %tu_chkvarsexist(&prefix.exposure, &starttimevar) ne %then  %let starttimevar=;
      %end;

      proc sort data=%unquote(&exposuredset) nodupkey
         out=&prefix.exp1(keep=&studyidvar &subjidvar exstdt &enddatevar &starttimevar &endtimevar );
         by &studyidvar &subjidvar exstdt &starttimevar;
         where not missing(exstdt);
      run;

      proc sort data=&prefix._temp&i;
         by &studyidvar &subjidvar &eventstdtvar &eventsttmvar;
      run;

      data &prefix._temp%eval(&i + 1);
         merge &prefix._temp&i(in=__in1__)
               &prefix.exp1(in=__in2__ rename=(exstdt=&eventstdtvar
                  %if %nrbquote(&starttimevar) ne %then
                  %do;
                     &starttimevar=&eventsttmvar
                  %end;
                  ));
         by &studyidvar &subjidvar &eventstdtvar &eventsttmvar;
         format  _firstdosedt_ _lastdosedt_ date9.;
         %if %nrbquote(&endtimevar.&enddatevar) ne %then
            drop &endtimevar &enddatevar;;
         retain _firstdosedt_ _lastdosedt_
         %if %nrbquote(&starttimevar) ne %then _firstdosetm_;
         %if ((%nrbquote(&enddatevar) eq) and (%nrbquote(&starttimevar) ne)) or
             ((%nrbquote(&enddatevar) ne) and (%nrbquote(&endtimevar) ne)) %then _lastdosetm_;;
         if first.&subjidvar then
         do;
            _firstdosedt_=.;
            _lastdosedt_=.;
            %if %nrbquote(&starttimevar) ne %then _firstdosetm_=.;;
            %if %nrbquote(&endtimevar) ne %then _lastdosetm_=.;;
         end;
         if __in2__ then
         do;
           if missing(_firstdosedt_) then
           do;
              _firstdosedt_=&eventstdtvar;
              %if %nrbquote(&starttimevar) ne %then _firstdosetm_=&eventsttmvar;;
           end;
           %if %nrbquote(&enddatevar) eq %then
           %do;
              _lastdosedt_=&eventstdtvar;
              %if %nrbquote(&starttimevar) ne %then _lastdosetm_=&eventsttmvar;;
           %end;
           %else %do;
               _lastdosedt_=&enddatevar;
               %if %nrbquote(&endtimevar) ne %then _lastdosetm_=&endtimevar;;
           %end;
         end;
         if __in1__ then output;
      run;
      %let i=%eval(&i + 1);
   %end; /* %if %nrbquote(&TRTSTVAR) ne or %nrbquote(&TRT1STVAR) ne */

   /*
   / Call %tu_acttrt to derive actual treatment at the  time of the event by
   / calling %tu_acttrt
   / Derived variables: &ACTTRTVAR
   /----------------------------------------------------------------------------*/

   %if %nrbquote(&acttrtvar) ne %then
   %do;
      %if %tu_chkvarsexist(&prefix._temp&i, &eventstdtvar) ne %then
      %do;
         %put %str(RTW)ARNING: &sysmacroname: Variable &eventstdtvar does not exist in DSETIN (=&dsetin) and will not be used to derive &acttrtvar.;
         %let acttrtvar=;
      %end;
        %if %nrbquote(&eventsttmvar) ne %then
      %do;
         %if %tu_chkvarsexist(&prefix._temp&i, &eventsttmvar) ne %then
         %do;
            %put %str(RTN)OTE: &sysmacroname: Time variable &eventsttmvar does not exist in DSETIN (=&dsetin) and will not be used to derive &acttrtvar.;
            %let eventsttmvar=;
         %end;
      %end;
   %end; /*  %nrbquote(&acttrtvar) ne */

   %if %nrbquote(&acttrtvar) ne %then
   %do;
      %if %qupcase(&eventstdtvar) EQ EXSTDT or %qupcase(&eventsttmvar) eq EXSTTM  %then
      %do;
         %let eventstdtvar=_exstdt;
         %if %nrbquote(&eventsttmvar) ne %then %let eventsttmvar=_exsttm;

         data &prefix._temp&i;
            set &prefix._temp&i;
            rename %if %qupcase(&eventstdtvar) EQ EXSTDT %then exstdt=__exstdt;
                   %if %qupcase(&eventsttmvar) EQ EXSTTM %then exsttm=_exsttm;;
         run;
      %end;

      %tu_acttrt(
         dsetin       =&prefix._temp&i,
         dsetout      =&prefix._temp%eval(&i+1),
         exposuredset =&exposuredset,
         randdset     =&randdset,
         randalldset  =&randalldset,
         refdat       =&eventstdtvar,
         reftim       =&eventsttmvar,
         visitdset    =&visitdset,
         tmslicedset  =&tmslicedset,
         varname      =&acttrtvar
         );

      %let i = %eval(&i + 1);

      %if %qupcase(&eventstdtvar) EQ  __EXSTDT or %qupcase(&eventsttmvar) eq __EXSTTM %then
      %do;
         data &prefix._temp&i;
            set &prefix._temp&i;
            rename %if %qupcase(&eventstdtvar) EQ __EXSTDT %then __exstdt=exstdt;
                   %if %qupcase(&eventsttmvar) EQ __EXSTTM %then __exsttm=exsttm;;
         run;
      %end;
   %end; /* end-if on %nrbquote(&acttrtvar) ne */

   /*
   / Call %tu_refdat to derive reference day based on a time point.
   / Derived variables: &ACTSDYVAR and &ACTEDYVAR
   /----------------------------------------------------------------------------*/

   %let refdatevar=_temp_refdat;
   %let reftimevar=;

   %if %nrbquote(&actsdyvar) ne %then
   %do;
      %if %tu_chkvarsexist(&&prefix._temp&i, &eventstdtvar) ne %then %do;
         %put %str(RTW)ARNING: &sysmacroname: Can not derive ACTSDYVAR(=&ACTSDYVAR), because EVENTSTDTVAR(=&EVENTSTDTVAR) does not exist.;
         %let actsdyvar=;
      %end;
   %end; /* end-if on %nrbquote(&actsdyvar.&actsdyvar) ne */

   %if %nrbquote(&actedyvar) ne %then
   %do;
      %if %tu_chkvarsexist(&&prefix._temp&i, &eventendtvar) ne %then %do;
         %put %str(RTN)OTE: &sysmacroname: Can not derive ACTEDYVAR(=&ACTEDYVAR), because EVENTENDTVAR(=&EVENTENDTVAR) does not exist.;
         %let actedyvar=;
      %end;
   %end; /* end-if on %nrbquote(&actsdyvar.&actsdyvar) ne */

   %if  %nrbquote(&actsdyvar.&actedyvar) ne  %then
   %do;
      %tu_refdat(
         dsetin            = &prefix._temp&i,
         dsetout           = &prefix._temp%eval(&i+1),
         exposuredset      = &exposuredset,
         randdset          = &randdset,
         visitdset         = &visitdset,

         refdatevar        = &refdatevar,
         reftimevar        = ,
         refdateoption     = &refdateoption,
         refdatevisitnum   = &refdatevisitnum,
         refdatesourcedset = &refdatesourcedset,
         refdatesourcevar  = &refdatesourcevar,
         reftimesourcevar  = &reftimesourcevar,
         refdatedsetsubset = &refdatedsetsubset
         );

      %let i = %eval(&i + 1);

      data &prefix._temp%eval(&i+1);
         set &prefix._temp&i;
         drop &refdatevar;

         /* Actual study day from the start of the event */
         %if %nrbquote(&actsdyvar) ne %then
         %do;
            if ( &eventstdtvar ne .) and (  &refdatevar ne . ) then
            do;
               if &eventstdtvar ge &refdatevar then &actsdyvar=&eventstdtvar - &refdatevar + 1;
               else &actsdyvar=&eventstdtvar - &refdatevar;
            end;
         %end;

         /* Actual study day from the end of the event */
         %if %nrbquote(&actedyvar) ne %then
         %do;
            if ( &eventendtvar ne .) and (  &refdatevar ne . ) then
            do;
               if ( &eventendtvar ge &refdatevar ) then &actedyvar=&eventendtvar - &refdatevar + 1;
               else &actedyvar=&eventendtvar - &refdatevar;
            end;
         %end;
      run;

      %let i = %eval(&i + 1);
   %end; /* %if  %nrbquote(&actsdyvar) ne */

   /*
   / Derive variables for period day from end period.
   / Derived variables: &PEREDYVAR, &TPEREDYVAR and &XPEREDYVAR
   /----------------------------------------------------------------------------*/

   /* Recover saved &persdyvar, &xpersdyvar and &tpersdyvar */
   %let persdyvar=&persdyvar1;
   %let xpersdyvar=&xpersdyvar1;
   %let tpersdyvar=&tpersdyvar1;

   %if %nrbquote(&peredyvar) ne %then
   %do;
      %if %nrbquote(&persdyvar) eq %then
      %do;
         %put %str(RTN)OTE: &sysmacroname: Can not derive PEREDYVAR(=&peredyvar), because PERSDYVAR is not given.;
         %let peredyvar=;
      %end;
      %else %if %tu_chkvarsexist(&prefix._temp&i,&persdyvar) ne %then
      %do;
         %put %str(RTN)OTE: &sysmacroname: Can not derive PEREDYVAR(=&peredyvar), because PERSDYVAR(=&persdyvar) does not exist in DSETIN(=&dsetin).;
         %let peredyvar=;
      %end;
   %end; /* %if %nrbquote(&peredyvar) ne */

   %if %nrbquote(&tperedyvar) ne %then
   %do;
      %if %nrbquote(&tpersdyvar) eq %then
      %do;
         %put %str(RTN)OTE: &sysmacroname: Can not derive TPEREDYVAR(=&tperedyvar), because TPERSDYVAR is not given.;
         %let tperedyvar=;
      %end;
      %else %if %tu_chkvarsexist(&prefix._temp&i,&tpersdyvar) ne %then
      %do;
         %put %str(RTN)OTE: &sysmacroname: Can not derive TPEREDYVAR(=&tperedyvar), because TPERSDYVAR(=&TPERSDYVAR) does not exist in DSETIN(=&dsetin).;
         %let tperedyvar=;
      %end;
   %end; /* %nrbquote(&tperedyvar) ne */

   %if %nrbquote(&xperedyvar) ne %then
   %do;
      %if %nrbquote(&xpersdyvar) eq %then
      %do;
         %put %str(RTN)OTE: &sysmacroname: Can not derive XPEREDYVAR(=&xperedyvar), because XPERSDYVAR is not given.;
         %let xperedyvar=;
      %end;
      %else %if %tu_chkvarsexist(&prefix._temp&i,&xpersdyvar) ne %then
      %do;
         %put %str(RTN)OTE: &sysmacroname: Can not derive XPEREDYVAR(=&xperedyvar), because XPERSDYVAR(=&XPERSDYVAR) does not exist in DSETIN(=&dsetin).;
         %let xperedyvar=;
      %end;
   %end; /* %if %nrbquote(&xperedyvar) ne */

   %if %nrbquote(&peredyvar.&xperedyvar.&tperedyvar) ne %then
   %do;
      %if %tu_chkvarsexist(&prefix._temp&i, &eventstdtvar &eventendtvar) ne %then
      %do;
         %put %str(RTN)OTE: &sysmacroname: Can not derive &peredyvar, TPEREDY and XPEREDY, because EVENTENDTVAR(=&eventendtvar) or EVENTSTDTVAR(=&eventstdtvar) does not exist in data set &dsetin.;
         %let peredyvar=;
         %let xperedyvar=;
         %let tperedyvar=;
      %end;
   %end;

   %if %nrbquote(&peredyvar.&xperedyvar.&tperedyvar) ne %then
   %do;
      data &prefix._temp%eval(&i+1);
         set &prefix._temp&i;
         if ( &eventendtvar ne . ) and ( &eventstdtvar ne . ) then
         do;
            %if %nrbquote(&peredyvar) ne %then
            %do;
               &peredyvar = &eventendtvar - &eventstdtvar + &persdyvar;
               if &persdyvar lt 0 and &peredyvar ge 0 then &peredyvar=&peredyvar + 1;
            %end;
            %if %nrbquote(&tperedyvar) ne %then
            %do;
               &tperedyvar = &eventendtvar - &eventstdtvar + &tpersdyvar;
               if &tpersdyvar lt 0 and &tperedyvar ge 0 then &tperedyvar=&tperedyvar + 1;
            %end;
            %if %nrbquote(&xperedyvar) ne %then
            %do;
               &xperedyvar = &eventendtvar - &eventstdtvar + &xpersdyvar;
               if &tpersdyvar lt 0 and &xperedyvar ge 0 then &xperedyvar=&xperedyvar + 1;
            %end;
         end;
      run;

      %let i=%eval(&i + 1);
   %end; /* %if %nrbquote(&peredyvar) ne %then */

   /*
   / Derive event duration
   / Derived variables: &DURATIONUVAR, &DURATIONVAR, &DURATIONCVAR, &TRT1STVAR
   /                    &TRT1STCVAR, &PTRT1STVAR, &PTRT1STCVAR, &TRTSTVAR,
   /                    &TRTSTCVAR
   /----------------------------------------------------------------------------*/

   %do loopi=1 %to 4;
      %if &loopi eq 1 %then
      %do;
         %let derivevar=&durationvar;
         %let derivecvar=&durationcvar;
         %let deriveunit=&durationunit;
         %let startdatevar=&eventstdtvar;
         %let enddatevar=&eventendtvar;
         %let starttimevar=&eventsttmvar;
         %let endtimevar=&evententmvar;
      %end;
      %if &loopi eq 2 %then
      %do;
         %let derivevar=&trt1stvar;
         %let derivecvar=&trt1stcvar;
         %let deriveunit=&trt1stunit;
         %let startdatevar=_firstdosedt_;
         %let enddatevar=&eventstdtvar;
         %let starttimevar=_firstdosetm_;
         %let endtimevar=&eventsttmvar;
      %end;
      %if &loopi eq 3 %then
      %do;
         %let derivevar=&trtstvar;
         %let derivecvar=&trtstcvar;
         %let deriveunit=&trtstunit;
         %let startdatevar=_lastdosedt_;
         %let enddatevar=&eventstdtvar;
         %let starttimevar=_lastdosetm_;
         %let endtimevar=&eventsttmvar;
      %end;
      %if &loopi eq 4 %then
      %do;
         %let derivevar=&ptrt1stvar;
         %let derivecvar=&ptrt1stcvar;
         %let deriveunit=&ptrt1stunit;
         %let startdatevar=pertstdt;
         %let enddatevar=&eventstdtvar;
         %let starttimevar=pertsttm;
         %let endtimevar=&eventsttmvar;
      %end;

      %if %nrbquote(&derivevar) ne %then
      %do;
         %if %nrbquote(&endtimevar) eq %then %let starttimevar=;
         %if %nrbquote(&starttimevar) eq %then %let endtimevar=;

         %if %nrbquote(&starttimevar) ne %then
         %do;
            %if %tu_chkvarsexist(&prefix._temp&i, &endtimevar &starttimevar) ne %then
            %do;
               %put %str(RTN)OTE: &sysmacroname: start time (=&starttimevar) or end time (&endtimevar) is not used in deriving &derivevar.;
               %put %str(RTN)OTE: &sysmacroname: Not all of them exist in DSETIN(=&dsetin).;

               %let endtimevar=;
               %let starttimevar=;
            %end;
         %end;

         %if %nrbquote(&startdatevar) eq or %nrbquote(&enddatevar) eq %then
         %do;
            %put %str(RTW)ARNING: &sysmacroname: Can not derive &derivevar, start date (=&startdatevar) or end date (&enddatevar) is not given.;
            %let derivevar=;
         %end;
         %else %if %tu_chkvarsexist(&prefix._temp&i, &enddatevar &startdatevar) ne %then
         %do;
            %put %str(RTW)ARNING: &sysmacroname: Can not derive &derivevar, start date (=&startdatevar) or end date (=&enddatevar) does not exist.;
            %let derivevar=;
         %end;
      %end;

      %if %nrbquote(&derivevar) ne %then
      %do;
         data &prefix._temp%eval(&i+1);
            set &prefix._temp&i;

            %if &loopi gt 1 %then drop &starttimevar &startdatevar;;

            %if &deriveunit eq y %then
            %do;
               &derivevar=intck('year', &startdatevar, &enddatevar + 1) -
                            ( ( month(&enddatevar + 1) lt month(&startdatevar) ) or
                            ( ( month(&enddatevar + 1) eq month(&startdatevar) ) and
                              ( day(&enddatevar + 1)   lt day(&startdatevar)   ) );
               %if &loopi eq 3 %then
                  if not missing(&derivevar) and &derivevar le 0 then &derivevar=1;
               %else     
                  if not missing(&derivevar) and &derivevar le 0 then &derivevar=.;;
            %end;
            %else %if &deriveunit eq mo %then
            %do;
               &derivevar=( year(&enddatevar + 1) - year(&startdatevar) ) * 12 +
                            ( month(&enddatevar + 1) - month(&startdatevar) - 1) +
                            ( day(&enddatevar + 1) ge day(&startdatevar) );
               %if &loopi eq 3 %then
                  if not missing(&derivevar) and &derivevar le 0 then &derivevar=1;
               %else
                  if not missing(&derivevar) and &derivevar le 0 then &derivevar=.;;
            %end;
            %else %if &deriveunit eq w %then
            %do;
               &derivevar=int(((&enddatevar + 1) - &startdatevar)/7);

               %if &loopi eq 3 %then
                  if not missing(&derivevar) and &derivevar le 0 then &derivevar=1;
               %else
                  if not missing(&derivevar) and &derivevar le 0 then &derivevar=.;;
            %end;
            %else %if &deriveunit eq d %then
            %do;
               &derivevar=&enddatevar - &startdatevar + 1;
               %if &loopi eq 3 %then
                  if not missing(&derivevar) and &derivevar le 0 then &derivevar=1;
               %else
                  if not missing(&derivevar) and &derivevar le 0 then &derivevar=.;;
            %end;
            %else %if (&deriveunit eq h) or (&deriveunit eq m) %then
            %do;
               &derivevar=(&enddatevar - &startdatevar) * 3600 * 24; /* convert to seconds */
               %if %nrbquote(&starttimevar) ne %then
               %do;
                  if ( &endtimevar gt . ) and ( &starttimevar gt . ) then
                     &derivevar=&derivevar + (&endtimevar - &starttimevar );
               %end;

               %if &loopi eq 3 %then
                  if not missing(&derivevar) and &derivevar lt 0 then &derivevar=0;
               %else     
                  if not missing(&derivevar) and &derivevar lt 0 then &derivevar=.;;

               %if  (&deriveunit eq h) %then
               %do;
                  &derivevar=int(&derivevar / 3600) + 1;

                  %if %nrbquote(&derivecvar) ne %then
                  %do;
                     length &derivecvar $20;
                     drop __days__ __hours__;
                     __days__  = int(&derivevar/ 24);
                     __hours__ = mod(&derivevar, 24);

                     if &derivevar eq 0 then  &derivecvar='0h';
                     if __days__ gt 0 then &derivecvar=compress(put(__days__, best.))||'d';
                     if __hours__ gt 0 then &derivecvar=trim(left(&derivecvar))||' '||compress(put(__hours__, best.))||'h';
                     %let derivecvar=;
                  %end;
               %end; /* %if  (&deriveunit eq h) */

               %else %if &deriveunit eq m %then
               %do;               
                  &derivevar=int(&derivevar/60) + 1;

                  %if %nrbquote(&derivecvar) ne %then
                  %do;
                     length &derivecvar $ 20;
                     drop __days__ __hours__ __minutes__;
                     __days__    = int(&derivevar/(60 * 24));
                     __hours__   = int(&derivevar/60) - (__days__ * 24);
                     __minutes__ = mod(&derivevar, 60);

                     if &derivevar eq 0 then  &derivecvar='0m';
                     if __days__ gt 0 then &derivecvar=compress(put(__days__, best.))||'d';
                     if __hours__ gt 0 then &derivecvar=trim(left(&derivecvar))||' '||compress(put(__hours__, best.))||'h';
                     if __minutes__ gt 0 then &derivecvar=trim(left(&derivecvar))||' '||compress(put(__minutes__, best.))||'m';
                     %let derivecvar=;
                  %end;
               %end; /* %if &deriveunit eq h */
            %end; /* %if (&deriveunit eq h) or (&deriveunit eq m) */

            %if %nrbquote(&derivecvar) ne %then
            %do;
               length &derivecvar $ 20;
               if not missing(&derivevar) then &derivecvar=trim(left(put(&derivevar, best.))) || left("&deriveunit");
            %end; /* %if %nrbquote(&deriveunit) ne */
         run;
         %let i = %eval(&i + 1);
      %end; /* %if %nrbquote(&deriveunit) ne */

      %if &loopi eq 1 and %nrbquote(&durationuvar) ne %then
      %do;
         data &prefix._temp%eval(&i+1);
            set &prefix._temp&i;
            length &durationuvar $3;           
            &durationuvar=compress("&deriveunit");
            select (&durationuvar);
            when('d')  &durationuvar='DAY';
            when('h')  &durationuvar='HRS';
            when('m')  &durationuvar='MIN';
            when('mo') &durationuvar='MTH';
            when('w')  &durationuvar='WKS';
            when('y')  &durationuvar='YRS';
            otherwise  &durationuvar='';
            end;
         run;
         %let i = %eval(&i + 1);
      %end;
   %end; /* %do loopi=1 %to 4 */

   /*
   / Derivation of SEQUENCE variables.
   / Derived variables: &SEQVAR
   /----------------------------------------------------------------------------*/

   %if %nrbquote(&seqvar) ne  %then
   %do;
      %if %nrbquote(&subjidvar) eq %then
      %do;
         %put %str(RTW)ARNING: &sysmacroname: Can not derive SEQVAR(=&seqvar). The parameter SUBJIDVAR is blank.;
         %let seqvar=;
      %end;
      %else %if %tu_chkvarsexist(&prefix._temp&i, &subjidvar) ne %then
      %do;
         %put %str(RTW)ARNING: &sysmacroname: Can not derive SEQVAR(=&seqvar). Variable SUBJIDVAR(=&subjidvar) does not exist in DSETIN(=&dsetin).;
         %let seqvar=;
      %end;
      %else %if %nrbquote(&studyidvar) ne %then
      %do;
         %if %tu_chkvarsexist(&prefix._temp&i, &studyidvar) ne %then
         %do;
            %put %str(RTW)ARNING: &sysmacroname: Can not derive SEQVAR(=&seqvar). Variable STUDYIDVAR(=&studyidvar) does not exist in DSETIN(=&dsetin).;
            %let seqvar=;
         %end;
      %end;
   %end; /* %if %nrbquote(&seqvar) ne */

   %if %nrbquote(&seqvar) ne  %then
   %do;
      %let byvars=&studyidvar &subjidvar ;
      %if %tu_chkvarsexist(&prefix._temp&i, &eventstdtvar) eq %then %let byvars=&byvars &eventstdtvar;
      %if %nrbquote(&eventsttmvar) ne %then
      %do;
         %if %tu_chkvarsexist(&prefix._temp&i, &eventsttmvar) eq %then %let byvars=&byvars &eventsttmvar;
      %end;
      %if %tu_chkvarsexist(&prefix._temp&i, cycle) eq %then %let byvars=&byvars cycle;
      %if %tu_chkvarsexist(&prefix._temp&i, visitnum) eq %then %let byvars=&byvars visitnum;

      proc sort data=&prefix._temp&i;
         by &byvars;
      run;

      data &prefix._temp%eval(&i+1);
         set &prefix._temp&i;
         by &byvars;
         retain &seqvar;
         if first.&subjidvar then &seqvar=0;
         if missing(&eventstdtvar) then &seqvar=.;
         else if missing(&seqvar) then &seqvar=0;
         &seqvar=&seqvar + 1;
      run;

      %let i = %eval(&i + 1);

   %end; /* %if %nrbquote(&seqvar) ne */

   /*
   / Derive AGE variable at a time point.
   / Derived variables: &EVENTAGEYEARVAR, &EVENTAGEMONTHVAR, &EVENTAGEWEEKVAR
   /                    and &EVENTAGEDAYVAR
   /----------------------------------------------------------------------------*/

   %let thisvar=&eventageyearvar.&eventagemonthvar.&eventageweekvar.&eventagedayvar;
   
   %if %nrbquote(&thisvar) ne %then
   %do;
      %if %nrbquote(&eventstdtvar) eq %then
      %do;
         %put %str(RTW)ARNING: &sysmacroname: The parameter EVENTSTDTVAR is blank.;
         %put %str(RTW)ARNING: &sysmacroname: Age variables(EVENTAGEYEARVAR=&eventageyearvar, EVENTAGEMONTHVAR&eventagemonthvar, EVENTAGEWEEKVAR=&eventageweekvar and EVENTAGEDAYVAR=&eventagedayvar) will not be derived.;
         %let thisvar=;
      %end;
      %else %if %tu_chkvarsexist(&prefix._temp&i, &eventstdtvar) ne %then
      %do;
         %put %str(RTW)ARNING: &sysmacroname: The EVENTSTDTVAR(=&eventstdtvar) does not exist in DSETIN(=&dsetin).;
         %put %str(RTW)ARNING: &sysmacroname: Age variables(EVENTAGEYEARVAR=&eventageyearvar, EVENTAGEMONTHVAR&eventagemonthvar, EVENTAGEWEEKVAR=&eventageweekvar and EVENTAGEDAYVAR=&eventagedayvar) will not be derived.;
         %let thisvar=;
      %end;      
      %if %nrbquote(&demodset) eq %then
      %do;
         %put %str(RTW)ARNING: &sysmacroname: The parameter DEMODSET is blank.;
         %put %str(RTW)ARNING: &sysmacroname: Age variables(EVENTAGEYEARVAR=&eventageyearvar, EVENTAGEMONTHVAR&eventagemonthvar, EVENTAGEWEEKVAR=&eventageweekvar and EVENTAGEDAYVAR=&eventagedayvar) will not be derived.;
         %let thisvar=;
      %end;
      %else %if %qsysfunc(exist(%qscan(&demodset, 1, %str(%()))) le 0 %then
      %do;
         %put %str(RTW)ARNING: &sysmacroname: The &sysmacroname: DEMODSET(=&demodset) specifies a dataset which does not exist.;
         %put %str(RTW)ARNING: &sysmacroname: Age variables(EVENTAGEYEARVAR=&eventageyearvar, EVENTAGEMONTHVAR&eventagemonthvar, EVENTAGEWEEKVAR=&eventageweekvar and EVENTAGEDAYVAR=&eventagedayvar) will not be derived.;
         %let thisvar=;
      %end;
      %if %nrbquote(&subjidvar) eq %then
      %do;
         %put %str(RTW)ARNING: &sysmacroname: The parameter SUBJIDVAR is blank.;
         %put %str(RTW)ARNING: &sysmacroname: Age variables(EVENTAGEYEARVAR=&eventageyearvar, EVENTAGEMONTHVAR&eventagemonthvar, EVENTAGEWEEKVAR=&eventageweekvar and EVENTAGEDAYVAR=&eventagedayvar) will not be derived.;
         %let thisvar=;
      %end;                  
   %end; /* %if %nrbquote(&thisvar) ne */
         
   %if %nrbquote(&thisvar) ne %then
   %do;
      data &prefix.demo;
         set %unquote(&demodset);
      run;
      %if %nrbquote(&BIRTHDTVAR) eq %then
      %do;
         %put %str(RTW)ARNING: &sysmacroname: Parameter BIRTHDTVAR is not given.;
         %put %str(RTW)ARNING: &sysmacroname: Age variables(EVENTAGEYEARVAR=&eventageyearvar, EVENTAGEMONTHVAR&eventagemonthvar, EVENTAGEWEEKVAR=&eventageweekvar and EVENTAGEDAYVAR=&eventagedayvar) will not be derived.;
         %let thisvar=;
      %end;
      %else %if %tu_chkvarsexist(&prefix.demo, &BIRTHDTVAR) ne  %then
      %do;
         %put %str(RTW)ARNING: &sysmacroname: Variable BIRTHDTVAR(=&birthdtvar) does not exist in DEMODSET(=&demodset).;
         %put %str(RTW)ARNING: &sysmacroname: Age variables(EVENTAGEYEARVAR=&eventageyearvar, EVENTAGEMONTHVAR&eventagemonthvar, EVENTAGEWEEKVAR=&eventageweekvar and EVENTAGEDAYVAR=&eventagedayvar) will not be derived.;
         %let thisvar=;
      %end;
      %if %tu_chkvarsexist(&prefix.demo, &SUBJIDVAR &STUDYIDVAR) ne  %then
      %do;
         %put %str(RTW)ARNING: &sysmacroname: Variable STUDYIDVAR(=&studyidvar) or SUBJIDVAR(=&subjidvar) does not exist in DEMODSET(=&demodset).;
         %put %str(RTW)ARNING: &sysmacroname: Age variables(EVENTAGEYEARVAR=&eventageyearvar, EVENTAGEMONTHVAR&eventagemonthvar, EVENTAGEWEEKVAR=&eventageweekvar and EVENTAGEDAYVAR=&eventagedayvar) will not be derived.;
         %let thisvar=;
      %end;          
      %if %tu_chkvarsexist(&prefix._temp&i, &SUBJIDVAR &STUDYIDVAR) ne %then
      %do;
         %put %str(RTW)ARNING: &sysmacroname: Variable STUDYIDVAR(=&studyidvar) or SUBJIDVAR(=&subjidvar) does not exist in DEMODSET(=&demodset).;
         %put %str(RTW)ARNING: &sysmacroname: Age variables(EVENTAGEYEARVAR=&eventageyearvar, EVENTAGEMONTHVAR&eventagemonthvar, EVENTAGEWEEKVAR=&eventageweekvar and EVENTAGEDAYVAR=&eventagedayvar) will not be derived.;
         %let thisvar=;
      %end;              
   %end; /* %if %nrbquote(&thisvar) ne */

   %if %nrbquote(&thisvar) ne %then
   %do;
      /* Obtain birth date of subject from the &DEMODSET dataset. */
      proc sort data=&prefix.demo(keep=&studyidvar &subjidvar &birthdtvar) out=&prefix._agedemo nodupkey;
          by &studyidvar &subjidvar;
          where not missing(&birthdtvar);
      run;

      proc sort data=&prefix._temp&i out=&prefix.agedsetin;
         by &studyidvar &subjidvar;
      run;

      data &prefix._temp%eval(&i+1);
         merge &prefix.agedsetin(in=__IN__) &prefix._agedemo(rename=(&birthdtvar=_birthdt));
         by &studyidvar &subjidvar;
         drop _birthdt;

         if __IN__;

         if &eventstdtvar. ne . and _birthdt ne . then
         do;
            %if %nrbquote(&EVENTAGEYEARVAR) ne  %then
            %do;
                &EVENTAGEYEARVAR=intck('year',_birthdt,&eventstdtvar.) -
                           ( month(&eventstdtvar.) lt month(_birthdt) or
                           (month(&eventstdtvar.) eq month(_birthdt) and
                            day(&eventstdtvar.) lt day(_birthdt)) );
            %end;

            %if %nrbquote(&EVENTAGEMONTHVAR) ne  %then
            %do;
                &EVENTAGEMONTHVAR = (year(&eventstdtvar.) - year(_birthdt)) * 12
                          + (month(&eventstdtvar.)-month(_birthdt)-1)
                          + (day(&eventstdtvar.) ge day(_birthdt));
            %end;

            %if %nrbquote(&EVENTAGEWEEKVAR) ne  %then
            %do;
                &EVENTAGEWEEKVAR = int((&eventstdtvar. - _birthdt)/7);
            %end;

            %if %nrbquote(&EVENTAGEDAYVAR) ne  %then
            %do;
                &EVENTAGEDAYVAR = &eventstdtvar. - _birthdt;
            %end;
         end;
      run;

      %let i=%eval(&i+1);
   %end;

   /*
   / create output data set.
   /----------------------------------------------------------------------------*/

   data %unquote(&dsetout);
      set &prefix._temp&i;
      %if %tu_chkvarsexist(&prefix._temp&i, _lastdosedt_) eq %then drop _lastdosedt_;;
      %if %tu_chkvarsexist(&prefix._temp&i, _lastdosetm_) eq %then drop _lastdosetm_;;
      %if %tu_chkvarsexist(&prefix._temp&i, _firstdosedt_) eq %then drop _firstdosedt_;;
      %if %tu_chkvarsexist(&prefix._temp&i, _firstdosetm_) eq %then drop _firstdosetm_;;
   run;

   /*
   / Delete temporary datasets used in this macro.
   /----------------------------------------------------------------------------*/

   %tu_tidyup(
      rmdset =&prefix:,
      glbmac =NONE
      );

%endmac:
   %tu_abort();

%mend tu_stdderive;

