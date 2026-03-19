/*******************************************************************************
|
| Macro Name:      tu_adperiod
|
| Macro Version:   1 build 2
|
| SAS Version:     9.1.3
|
| Created By:      Anthony J Cooper
|
| Date:            14-Apr-2014
|
| Macro Purpose:   Derive ADaM period variables
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                                        DEFAULT
| -----------------  -------------------------------------------------  ----------
| DSETIN             Specifies the dataset for which the derivations    (None)
|                    are to be done.
|                    Valid values: valid dataset name
|
| DSETOUT            Specifies the name of the output dataset to be     (None)
|                    created.
|                    Valid values: valid dataset name
|
| DSETINADTRT        Specifies the ADTRT dataset which contrains        (None)
|                    APERIOD/APERIODC and date variables.
|                    Valid values: valid dataset name
|
| EVENTTYPE          Specifies the the type of events in the input      (None)
|                    dataset, either PL (planned) or SP (spontaneous)
|                    When EVENTTYPE=PL, the period variables APERIOD
|                    and APERIODC shall be derived.
|                    When EVENTTYPE=SP, the period variables TPERIOD
|                    and TPERIODC shall be derived.
|                    Valid values: PL or SP
|
| -----------------  -------------------------------------------------  ----------
|
| The macro references the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETIN            Req      Parameter specified dataset
| &DSETINADTRT       Req      Parameter specified dataset
| -----------------  -------  -------------------------------------------------
|
| Output:
|
| The macro outputs the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETOUT           Req      Parameter specified dataset
| -----------------  -------  -------------------------------------------------
|
| Global macro variables created: NONE
|
| Macros called:
|(@) tr_putlocals
|(@) tu_putglobals
|(@) tu_words
|(@) tu_abort
|(@) tu_chkvarsexist
|(@) tu_tidyup
|
| Example:
|    %tu_adperiod(
|         dsetin            = _ae1,
|         dsetout           = _ae2,
|         dsetinadtrt       = adamdata.adtrt,
|         eventtype         = SP
|         );
|
|******************************************************************************
| Change Log
|
| Modified By:              Anthony J Cooper
| Date of Modification:     08-May-2014
| New version/draft number: 1 build 2
| Modification ID:          AJC001
| Reason For Modification:  Change TRTSTDT to TRSDT for period treatment start date 
| 
***************************************************************************************************/

%macro tu_adperiod (
   DSETIN       =,                  /* Input dataset */
   DSETOUT      =,                  /* Output dataset */
   DSETINADTRT  =adamdata.adtrt,    /* ADTRT input dataset */
   EVENTTYPE    =                   /* Specifies if the event is Planned or Spontaneous */
   );

   /*
   / Echo parameter values and global macro variables to the log.
   /----------------------------------------------------------------------------*/

   %local MacroVersion;
   %let MacroVersion = 1 build 2;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals();

   %local prefix listvars thisvar loopi adatevars trtdatevars adtvar atmvar adtmvar adtrttmvar periodvars apstvar apenvar;

   %let prefix = _adperiod;   /* Root name for temporary work datasets */
   %let eventtype = %upcase(&eventtype);

   /*
   / PARAMETER VALIDATION
   /----------------------------------------------------------------------------*/

   %let dsetin       = %nrbquote(&dsetin);
   %let dsetout      = %nrbquote(&dsetout);
   %let dsetinadtrt  = %nrbquote(&dsetinadtrt);

   /*
   / Check required parameters DSETIN DSETOUT DSETINADTRT are not blank
   /----------------------------------------------------------------------------*/

   %let listvars=DSETIN DSETOUT DSETINADTRT;

   %do loopi=1 %to %tu_words(&listvars);
      %let thisvar=%scan(&listvars, &loopi, %str( ));
      %let &thisvar=%nrbquote(&&&thisvar);

      %if &&&thisvar eq %then
      %do;
         %put %str(RTE)RROR: &sysmacroname: The parameter &thisvar is required.;
         %let g_abort=1;
      %end;
   %end;  /* end of do-to loop */

   /*
   / Check that EVENTTYPE is PL (planned) or SP (spontaneous).
   /----------------------------------------------------------------------------*/

   %if ( %nrbquote(&eventtype) ne PL) and ( %nrbquote(&eventtype) ne SP ) %then
   %do; 
      %put %str(RTE)RROR: &sysmacroname: Value of parameter EVENTTYPE(=&eventtype) is invalid. Valid values are PL or SP.;
      %let g_abort=1;
   %end;  /* end-if on &eventtype not equal to PL or SP */

   %if &g_abort eq 1 %then
   %do;
      %tu_abort;
   %end;

   /*
   / Check input dataset exists.
   /----------------------------------------------------------------------------*/

   %if %sysfunc(exist(%qscan(&dsetin, 1, %str(%()))) eq 0 %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: The dataset DSETIN(=&dsetin) does not exist.;
      %let g_abort=1;
   %end;  /* end-if on &dsetin dataset does not exist */

   /*
   / If input dataset exists, check analysis date variable(s) exist.
   /----------------------------------------------------------------------------*/

   %else
   %do;

      %let listvars=ADT ASTDT;
      %let adatevars=%tu_chkvarsexist(&dsetin,&listvars,Y);
    
      %if %length(&adatevars) eq 0 %then
      %do;
         %put %str(RTERR)OR: &sysmacroname: No analysis date variables (&listvars) exist on the DSETIN dataset (&DSETIN).;
         %let g_abort=1;
      %end;  /* end-if on no analysis date variables exist */
    
   %end;  /* end-if on &dsetin dataset does exist */

   /*
   / Check ADTRT dataset exists.
   /----------------------------------------------------------------------------*/

   %if %sysfunc(exist(%qscan(&dsetinadtrt, 1, %str(%()))) eq 0 %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: The dataset DSETINADTRT(=&dsetinadtrt) does not exist.;
      %let g_abort=1;
   %end;  /* end-if on &dsetinadtrt dataset does not exist */

   /*
   / If ADTRT dataset exists, check expected variables exist.
   /----------------------------------------------------------------------------*/

   %else
   %do;

      %let listvars=APERIOD APERIODC;
      %let periodvars=%tu_chkvarsexist(&dsetinadtrt,&listvars);
   
      %if %length(&periodvars) gt 0 %then
      %do;
         %put %str(RTERR)OR: &sysmacroname: Expected period variables (&periodvars) do not exist on the DSETINADTRT dataset (&DSETINADTRT).;
         %let g_abort=1;
      %end;
   
      %if &eventtype=PL %then
         %let listvars=APSDT APEDT;
      %else %if &eventtype=SP %then
         %let listvars=TRSDT;
      %else
         %let listvars=;

      %if &listvars ne %then   
         %let trtdatevars=%tu_chkvarsexist(&dsetinadtrt,&listvars);
   
      %if %length(&trtdatevars) gt 0 %then
      %do;
         %put %str(RTERR)OR: &sysmacroname: Expected period date variables (&trtdatevars) do not exist on the DSETINADTRT dataset (&DSETINADTRT).;
         %let g_abort=1;
      %end;
    
   %end;  /* end-if on &dsetinadtrt dataset does exist */

   %if &g_abort eq 1 %then
   %do;
      %tu_abort;
   %end;

   /*
   / Check if period variables already exist on the input dataset.
   /----------------------------------------------------------------------------*/

   %if &eventtype=PL %then
      %let listvars=APERIOD APERIODC;
   %else %if &eventtype=SP %then
      %let listvars=TPERIOD TPERIODC;

   %let periodvars=%tu_chkvarsexist(&dsetin,&listvars,Y);

   %if %length(&periodvars) gt 0 %then
   %do;
      %put %str(RTW)ARNING: &sysmacroname: Period variable(s) (&periodvars) exist on the DSETIN dataset (&DSETIN) and will be overwritten.;
   %end;  /* end-if on day variables already exist */

   /*
   / If the input dataset name is the same as the output dataset name,
   / write a note to the log.
   /----------------------------------------------------------------------------*/
  
   %if %qscan(&dsetin, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
   %do;
      %put %str(RTN)OTE: &sysmacroname: The input dataset name (&dsetin) is the same as the output dataset name (&dsetout).;
   %end;  /* end-if on both parameters &dsetin and &dsetout passed with same values.  */

   /*
   / NORMAL PROCESSING
   /----------------------------------------------------------------------------*/

   /*
   / Set up unique row identifier variable.
   / Drop period variables if they already exist.
   /----------------------------------------------------------------------------*/

   data &prefix._dsetin;
      set %unquote(&dsetin);

      _rownum_ = _n_;

      %if %length(&periodvars) gt 0 %then
      %do;
         drop &periodvars;
      %end;

   run;

   /*
   / Planned event type:
   / Derive APERIOD/APERIODC by comparing domain dataset date/time variables
   / with ADTRT dataset period date/time variables.
   /----------------------------------------------------------------------------*/

   %if &eventtype=PL %then
   %do;

      /*
      / Loop over the analysis date variables found on the input dataset.
      / Domains such as LIVER are expected to have ADT and ASTDT as they
      / are combination of several SDTM datasets.
      /-------------------------------------------------------------------------*/

      %do loopi=1 %to %tu_words(&adatevars);
    
         /*
         / If datetime variables exist on both the domain input dataset and
         / ADTRT dataset then use them in the merge to find APERIOD/APERIODC.
         / Otherwise just use date variables.
         /-------------------------------------------------------------------------*/
    
         %let adtvar=%scan(&adatevars, &loopi);
         %let adtmvar=%tu_chkvarsexist(&dsetin,&adtvar.M,Y);

         %if (&adtmvar eq ) or %length(%tu_chkvarsexist(&dsetinadtrt,APSDTM APEDTM)) gt 0 %then
         %do;
            %let apstvar=APSDT;
            %let apenvar=APEDT;
            %put RTNOTE: &sysmacroname: Using date variables to determine APERIOD/APERIODC.;
         %end;
         %else
         %do;
            %let apstvar=APSDTM;
            %let apenvar=APEDTM;
            %let adtvar=&adtmvar;
            %put RTNOTE: &sysmacroname: Using datetime variables to determine APERIOD/APERIODC.;
         %end;

         /*
         / Retrieve the period information from the ADTRT dataset.
         / Drop rows where both the period start and end date are missing as
         / ADTRT will contain rows for every subject and period even if they did
         / not enter the period.
         / Also drop rows where either the start or end date is missing and inform
         / the user.
         /-------------------------------------------------------------------------*/
    
         data &prefix._adtrt (keep=studyid usubjid aperiod aperiodc &apstvar &apenvar);

            set %unquote(&dsetinadtrt);
            where not (&apstvar eq . and &apenvar eq .);

            if &apstvar eq . or &apenvar eq . then
               put "RTW" "ARNING: &sysmacroname: DSETINADTRT dataset (&DSETINADTRT) contains incomplete period date/datetime start and end variables for " /
                  usubjid= aperiod= aperiodc= &apstvar= &apenvar=;
            else
               output;

         run;

         data &prefix._domain;
            set &prefix._dsetin;
            where &adtvar ne .;
         run;
   
         /*
         / Find the period in which the treatment occurred
         /-------------------------------------------------------------------------*/
   
         proc sql noprint;
            create table &prefix._aperiod as
            select a.*, b.aperiod, b.aperiodc, b.&apstvar, b.&apenvar
            from &prefix._domain a left join &prefix._adtrt b
            on a.studyid=b.studyid and a.usubjid=b.usubjid and b.&apstvar <= a.&adtvar <= b.&apenvar
            order by _rownum_, b.&apstvar, b.&apenvar
            ;
         quit;

         /*
         / Highlight any rows to the user where period cannot be unequivocally
         / determined, e.g. due to overlapping period dates. For these cases,
         / keep the first observation and set APERIOD/APERIODC to missing.
         /-------------------------------------------------------------------------*/
   
         data 
            &prefix._aperiod&loopi (keep=_rownum_ aperiod aperiodc)
            &prefix._equivocal     (keep=usubjid &adtvar aperiod aperiodc &apstvar &apenvar)
            ;

            set &prefix._aperiod;
            by _rownum_ &apstvar &apenvar;

            if not (first._rownum_ and last._rownum_) then
               output &prefix._equivocal;

            if first._rownum_ and not last._rownum_ then do;
               aperiod=.;
               aperiodc='';
            end;

            if first._rownum_ then
               output &prefix._aperiod&loopi;

         run;

         proc sort data=&prefix._equivocal nodupkey;
            by usubjid &adtvar;
         run;

         data _null_;
            set &prefix._equivocal end=last;
            put "RTW" "ARNING: APERIOD cannot be uniquevocally determined, e.g. due to overlapping period dates, for " usubjid= &adtvar=;
            if last then
               put "RTW" "ARNING: APERIOD/APERIODC have been set to missing for the above subjects and dates/datetimes";
         run;

      %end;  /* end-if on do loopi=1 to number of analysis variables */

      /*
      / Merge period variables back on by unique row indicator.
      / Any events which had a missing start date/datetime will having missing
      / APERIOD/APERIODC.
      /-------------------------------------------------------------------------*/

      data &prefix._final;
        merge 
           &prefix._dsetin
           %do loopi=1 %to %tu_words(&adatevars);
              &prefix._aperiod&loopi
           %end;
           ;
        by _rownum_;
      run;

   %end;  /* end-if on &eventtype is PL */

   /*
   / Spontaneous event type:
   / Derive TPERIOD/TPERIODC by comparing domain dataset date/time variables
   / with ADTRT dataset treatment period date/time variables.
   /----------------------------------------------------------------------------*/

   %else %if &eventtype=SP %then
   %do;

      /*
      / Retrieve the period information from the ADTRT dataset.
      / Drop rows where the period treatment start date is missing as ADTRT
      / will contain rows for every subject and period even if they did
      / not enter the period.
      / Treatment periods with missing start time have time set to 00:00:00.
      / This ensure events that occur on the day of dosing are allocated to the
      / dose taken on that day.
      /-------------------------------------------------------------------------*/

      %let adtrttmvar=%tu_chkvarsexist(&dsetinadtrt, TRSTM, Y);

      data &prefix._adtrt (keep=studyid usubjid aperiod aperiodc trsdt &adtrttmvar &prefix._trtDM);

         set %unquote(&dsetinadtrt);
         where TRSDT ne .;

         %if %length(&adtrttmvar) eq 0 %then
         %do;
            &prefix._trtDM=dhms(TRSDT, 0, 0, 0);
         %end;
         %else
         %do;
            if &adtrttmvar ne . then
               &prefix._trtDM=dhms(TRSDT, 0, 0, &adtrttmvar);
            else do;
               put "RTW" "ARNING: &sysmacroname: Missing treatment period start time for " usubjid= aperiod= aperiodc= TRSDT=;
               &prefix._trtDM=dhms(TRSDT, 0, 0, 0);
            end;
         %end;

         format &prefix._trtDM datetime20.;

      run;

      /*
      / Loop over the analysis date variables found on the input dataset.
      / Domains such as LIVER are expected to have ADT and ASTDT as they
      / are combination of several SDTM datasets.
      /-------------------------------------------------------------------------*/

      %do loopi=1 %to %tu_words(&adatevars);
    
         %let adtvar=%scan(&adatevars, &loopi);
         %let atmvar=%tu_chkvarsexist(&dsetin,%substr(&adtvar,1,%length(&adtvar)-2)TM,Y);
    
         /*
         / Events with missing start time have time set to 23:59:59.
         / This ensure events that occur on the first day of dosing are allocated
         / to the dose taken on that day.
         /-------------------------------------------------------------------------*/
   
         data &prefix._domain;
            set &prefix._dsetin;
            where &adtvar ne .;
   
            %if %length(&atmvar) eq 0 %then
            %do;
               &prefix._domainDM=dhms(&adtvar, 23, 59, 59);
            %end;
            %else
            %do;
               if &atmvar ne . then
                  &prefix._domainDM=dhms(&adtvar, 0, 0, &atmvar);
               else do;
                  put "RTW" "ARNING: &sysmacroname: Missing event start time for " usubjid= &adtvar=;
                  &prefix._domainDM=dhms(&adtvar, 23, 59, 59);
               end;
            %end;
   
            format &prefix._domainDM datetime20.;
   
         run;
    
         /*
         / Find the latest treatment start date which is on or before the event
         / start date.
         / Events which occur prior to first treatment will have missing 
         / TPERIOD/TPERIODC.
         /-------------------------------------------------------------------------*/
   
         proc sql noprint;
            create table &prefix._tperiod as
            select a.*, b.aperiod as tperiod, b.aperiodc as tperiodc, b.&prefix._trtDM
            from &prefix._domain a left join &prefix._adtrt b
            on a.studyid=b.studyid and a.usubjid=b.usubjid and b.&prefix._trtDM <= a.&prefix._domainDM
            order by _rownum_, b.&prefix._trtDM
            ;
         quit;
   
         data &prefix._tperiod&loopi (keep=_rownum_ tperiod tperiodc);
            set &prefix._tperiod;
            by _rownum_ &prefix._trtDM;
            if last._rownum_;
         run;
   
      %end;  /* end-if on do loopi=1 to number of analysis variables */

      /*
      / Merge period variables back on by unique row indicator.
      / Any events which had a missing start date will having missing
      / TPERIOD/TPERIODC.
      /-------------------------------------------------------------------------*/

      data &prefix._final;
        merge 
           &prefix._dsetin
           %do loopi=1 %to %tu_words(&adatevars);
              &prefix._tperiod&loopi
           %end;
           ;
        by _rownum_;
      run;

   %end;  /* end-if on &eventtype is SP */

   /*
   / Print subjects/dates with missing period when appropriate debug flag is set.
   /----------------------------------------------------------------------------*/

   %if &g_debug ge 5 %then
   %do;

      title "&sysmacroname: Print out of subjects and dates/datetimes with missing period assignment";

      %let listvars=%tu_chkvarsexist(&prefix._final,ADT ATM ASTDT ASTTM,Y);

      proc sort data=&prefix._final out=&prefix._missing (keep=studyid usubjid &listvars) nodupkey;
        by studyid usubjid &listvars;
        where missing(
           %if &eventtype=PL %then APERIOD; %else %if &eventtype=SP %then TPERIOD;
           );
      run;

      proc print data=&prefix._missing;
      run;

   %end;

   data &dsetout;
      set &prefix._final;
      drop _rownum_;
   run;

   /*
   / Delete temporary datasets used in this macro.
   /----------------------------------------------------------------------------*/

   %tu_tidyup(
      rmdset =&prefix:,
      glbmac =NONE
      );

%mend tu_adperiod;

