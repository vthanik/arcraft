/*******************************************************************************
|
| Macro Name:      tu_adreldays
|
| Macro Version:   1 build 2
|
| SAS Version:     9.1.3
|
| Created By:      Anthony J Cooper
|
| Date:            04-Apr-2014
|
| Macro Purpose:   Derive analysis relative day and analysis relative day
|                  in period variables
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
| DOMAINCODE         Specifies the SDTM domain code. Used to            (None)
|                    identify SDTM day variables when DYREFDATEVAR
|                    is not supplied. Also used to identify date
|                    variables when DYREFDATEVAR is supplied but 
|                    analysis date variables are not found.
|                    Valid values: Blank or SDTM domain code
|
| DYREFDATEVAR       Specifies the reference date variable which        (None)
|                    will be used to derive analysis relative day
|                    variables: ADY, ASTDY, AENDY.
|                    Valid values: Blank or variable on DSETIN
|
| -----------------  -------------------------------------------------  ----------
|
| The macro references the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETIN            Req      Parameter specified dataset
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
|(@) tu_nobs
|(@) tu_tidyup
|
| Example:
|    %tu_adreldays(
|         dsetin            = _ae1,
|         dsetout           = _ae2,
|         domaincode        = AE,
|         dyrefdatevar      = TRTSDT
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

%macro tu_adreldays (
   DSETIN       =,   /* Input dataset */
   DSETOUT      =,   /* Output dataset */
   DOMAINCODE   =,   /* SDTM dataset domain code used to identify day/date variables: AE, LB, etc. */
   DYREFDATEVAR =    /* Reference date variable for analysis relative days derivation: ADY, ASTDY, AENDY */
   );

   /*
   / Echo parameter values and global macro variables to the log.
   /----------------------------------------------------------------------------*/

   %local MacroVersion;
   %let MacroVersion = 1 build 2;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals();

   %local prefix listvars thisvar loopi lastdset adtvarlist domaindtvarlist adtvarexist domaindtvarexist
      dtvar stdtvar endtvar dayvars perady perstdy perendy;

   %let prefix = _adreldays;  /* Root name for temporary work datasets */
   %let domaincode = %upcase(&domaincode);

   /*
   / PARAMETER VALIDATION
   /----------------------------------------------------------------------------*/

   %let dsetin  = %nrbquote(&dsetin);
   %let dsetout = %nrbquote(&dsetout);

   /*
   / Check required parameters DSETIN DSETOUT are not blank
   /----------------------------------------------------------------------------*/

   %let listvars=DSETIN DSETOUT;

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
   / Check that at least one of DOMAINCODE or DYREFDATEVAR is not blank.
   /----------------------------------------------------------------------------*/

   %if ( %nrbquote(&domaincode) eq ) and ( %nrbquote(&dyrefdatevar) eq  ) %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: One of DOMAINCODE or DYREFDATEVAR is required.;
      %let g_abort=1;
   %end;  /* end-if on both parameters: &domaincode and &dyrefdatevar both missing */

   /*
   / Check input dataset exists.
   /----------------------------------------------------------------------------*/

   %if %sysfunc(exist(%qscan(&dsetin, 1, %str(%()))) eq 0 %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: The dataset DSETIN(=&dsetin) does not exist.;
      %let g_abort=1;
   %end;  /* end-if on &dsetin dataset does not exist */

   /*
   / If input dataset exists, check DYREFDATEVAR exists if it was supplied.
   /----------------------------------------------------------------------------*/

   %else %if %nrbquote(&dyrefdatevar) ne %then
   %do;

      %if %length(%tu_chkvarsexist(&dsetin,&dyrefdatevar)) gt 0 %then
      %do;
         %put %str(RTE)RROR: &sysmacroname: The DYREFDATEVAR Variable (&DYREFDATEVAR) does not exist on the DSETIN dataset (&DSETIN).;
         %let g_abort=1;
      %end;

   %end;  /* end-if on &dsetin dataset does exist */

   %if &g_abort eq 1 %then
   %do;
      %tu_abort;
   %end;

   /*
   / Check if any relative day variables already exist on the input dataset.
   /----------------------------------------------------------------------------*/

   %let dayvars=%tu_chkvarsexist(&dsetin,ADY ASTDY AENDY,Y);

   %if %length(&dayvars) gt 0 %then
   %do;
      %put %str(RTW)ARNING: &sysmacroname: Relative day variable(s) (&dayvars) exist on the DSETIN dataset (&DSETIN) and may be overwritten.;
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
   / Determine which, if any, date variables exist on the input dataset.
   / These will be used in conjunction with DYREFDATEVAR to drive the analysis
   / relative day variable processing.
   / The date variables will also be used to derive analysis relative day in
   / period variables in period (APERIOD or TPERIOD) exist in the input dataset.
   /----------------------------------------------------------------------------*/

   %let adtvarlist=ADT ASTDT AENDT;
   %let adtvarexist=%tu_chkvarsexist(&dsetin,&adtvarlist,Y);

   %if %length(&adtvarexist) gt 0 %then
   %do;
      %if %sysfunc(indexw(&adtvarexist, ADT))   gt 0 %then %let dtvar=ADT;
      %if %sysfunc(indexw(&adtvarexist, ASTDT)) gt 0 %then %let stdtvar=ASTDT;
      %if %sysfunc(indexw(&adtvarexist, AENDT)) gt 0 %then %let endtvar=AENDT;
   %end;  /* end-if on analysis date variables exist */

   %else %if %nrbquote(&domaincode) ne %then
   %do;
      %let domaindtvarlist=&domaincode.DT &domaincode.STDT &domaincode.ENDT;
      %let domaindtvarexist=%tu_chkvarsexist(&dsetin,&domaindtvarlist,Y);
      %if %sysfunc(indexw(&domaindtvarexist, &domaincode.DT))   gt 0 %then %let dtvar=&domaincode.DT;
      %if %sysfunc(indexw(&domaindtvarexist, &domaincode.STDT)) gt 0 %then %let stdtvar=&domaincode.STDT;
      %if %sysfunc(indexw(&domaindtvarexist, &domaincode.ENDT)) gt 0 %then %let endtvar=&domaincode.ENDT;
   %end;  /* end-if on domaincode not missing */

   /*
   / If reference date variable was provided, attempt to derive relative study
   / day variables from the analysis date variables.
   /----------------------------------------------------------------------------*/

   %if %nrbquote(&dyrefdatevar) ne %then
   %do;

      /*
      / If analysis date variables exist (which they should if tu_adreldays is 
      / called by a TC macro) use those, otherwise use domain date variables.
      /-------------------------------------------------------------------------*/

      %if %length(&adtvarexist) gt 0 %then
      %do;
         %put %str(RTN)OTE: &sysmacroname: Using analysis date variables (&adtvarexist) to derive analysis relative days.;
      %end;  /* end-if on analysis date variables exist */

      %else
      %do;

         %if %nrbquote(&domaincode) eq %then
         %do;
            %put %str(RTW)ARNING: &sysmacroname: No analysis date variables (&adtvarlist) exist on the DSETIN dataset (&DSETIN) and DOMAINCODE is missing.;
            %put %str(RTW)ARNING: &sysmacroname: Analysis relative day variables will not be derived.;
         %end;  /* end-if on domain code is missing */

         %else %if %length(&domaindtvarexist) gt 0 %then
         %do;
            %put %str(RTN)OTE: &sysmacroname: No analysis date variables (&adtvarlist) exist on the DSETIN dataset (&DSETIN);
            %put %str(RTN)OTE: &sysmacroname: Using domain date variables (&domaindtvarexist) to derive analysis relative days.;
         %end;  /* end-if on domain date variables exist */

         %else
         %do;
            %put %str(RTW)ARNING: &sysmacroname: No analysis date variables (&adtvarlist) or domain date variables (&domaindtvarlist) exist on the DSETIN dataset (&DSETIN).;
            %put %str(RTW)ARNING: &sysmacroname: Analysis relative day variables will not be derived.;
         %end;  /* end-if on domain date variables do not exist */

      %end;  /* end-if on analysis date variables do not exist */

      data &prefix._studyday;
         set %unquote(&dsetin);

         %* Analysis relative day from the date of the event *;
         %if &dtvar ne %then
         %do;
            if ( &dtvar ne .) and ( &dyrefdatevar ne . ) then
            do;
               if &dtvar ge &dyrefdatevar then ady=&dtvar - &dyrefdatevar + 1;
               else ady=&dtvar - &dyrefdatevar;
            end;
         %end;

         %* Analysis relative day from the start of the event *;
         %if &stdtvar ne  %then
         %do;
            if ( &stdtvar ne .) and ( &dyrefdatevar ne . ) then
            do;
               if &stdtvar ge &dyrefdatevar then astdy=&stdtvar - &dyrefdatevar + 1;
               else astdy=&stdtvar - &dyrefdatevar;
            end;
         %end;

         %* Analysis relative day from the end of the event *;
         %if &endtvar ne  %then
         %do;
            if ( &endtvar ne .) and ( &dyrefdatevar ne . ) then
            do;
               if &endtvar ge &dyrefdatevar then aendy=&endtvar - &dyrefdatevar + 1;
               else aendy=&endtvar - &dyrefdatevar;
            end;
         %end;

      run;

      %let lastdset=&prefix._studyday;

   %end;  /* end-if on reference date variable was provided */

   /*
   / If reference date variable was not provided, attempt to derive relative
   / day variables from the SDTM domain variables if they exist.
   /----------------------------------------------------------------------------*/

   %else
   %do;

      /*
      / Check which SDTM domain relative day variables exist.
      /-------------------------------------------------------------------------*/

      %let listvars=&domaincode.DY &domaincode.STDY &domaincode.ENDY;
      %let dayvars=%tu_chkvarsexist(&dsetin,&listvars,Y);

      %if %length(&dayvars) eq 0 %then
      %do;
         %put %str(RTW)ARNING: &sysmacroname: No SDTM domain relative day variables (&listvars) exist on the DSETIN dataset (&DSETIN).;
         %put %str(RTW)ARNING: &sysmacroname: Analysis relative day variables will not be derived.;
      %end;  /* end-if on SDTM domain variables do not exist */

      /*
      / Use the SDTM domain relative day variables to create the analysis
      / dataset variable equivalents.
      /-------------------------------------------------------------------------*/

      data &prefix._studyday;
         set %unquote(&dsetin);

         %* Actual study day from the date of the event *;
         %if %sysfunc(indexw(&dayvars, &domaincode.DY)) gt 0 %then
         %do;
            ady=&domaincode.DY;
         %end;

         %* Actual study day from the start of the event *;
         %if %sysfunc(indexw(&dayvars, &domaincode.STDY)) gt 0 %then
         %do;
            astdy=&domaincode.STDY;
         %end;

         %* Actual study day from the end of the event *;
         %if %sysfunc(indexw(&dayvars, &domaincode.ENDY)) gt 0 %then
         %do;
            aendy=&domaincode.ENDY;
         %end;

      run;

      %let lastdset=&prefix._studyday;

   %end;  /* end-if on reference date variable was not provided */

   /*
   / Derive analysis relative day in period variables if APERIOD or TPERIOD 
   / exist on the input dataset. TRSDT should have been merged on, e.g. using
   / the tu_adgettrt macro.
   /----------------------------------------------------------------------------*/

   %if %length(%tu_chkvarsexist(&dsetin, APERIOD TPERIOD, Y)) gt 0 %then
   %do;

      %if %length(%tu_chkvarsexist(&dsetin, APERIOD, Y)) gt 0 %then
      %do;
         %let perady=APERADY;
         %let perstdy=APERSTDY;
         %let perendy=APERENDY;
      %end;
    
      %else %if %length(%tu_chkvarsexist(&dsetin, TPERIOD, Y)) gt 0 %then
      %do;
         %let perady=TPERADY;
         %let perstdy=TPERSTDY;
         %let perendy=TPERENDY;
      %end;

      %if %length(%tu_chkvarsexist(&dsetin, TRSDT, Y)) gt 0 %then
      %do;

         data &prefix._periodday;
            set &lastdset;
    
            %* Analysis relative day in period from the date of the event *;
            %if &dtvar ne %then
            %do;
               if ( &dtvar ne .) and ( trsdt ne . ) then
               do;
                  if &dtvar ge trsdt then &perady=&dtvar - trsdt + 1;
                  else &perady=&dtvar - trsdt;
               end;
            %end;
    
            %* Analysis relative day in period from the start of the event *;
            %if &stdtvar ne  %then
            %do;
               if ( &stdtvar ne .) and ( trsdt ne . ) then
               do;
                  if &stdtvar ge trsdt then &perstdy=&stdtvar - trsdt + 1;
                  else &perstdy=&stdtvar - trsdt;
               end;
            %end;
    
            %* Analysis relative day in period from the end of the event *;
            %if &endtvar ne  %then
            %do;
               if ( &endtvar ne .) and ( trsdt  ne . ) then
               do;
                  if &endtvar ge trsdt then &perendy=&endtvar - trsdt + 1;
                  else &perendy=&endtvar - trsdt;
               end;
            %end;
   
         run;
   
         %let lastdset=&prefix._periodday;

      %end;  /* end-if on TRSDT exists in input dataset */

      %else
      %do;
         %put %str(RTW)ARNING: &sysmacroname: Period variable APERIOD or TPERIOD exists on the DSETIN dataset (&DSETIN);
         %put %str(RTW)ARNING: &sysmacroname: but Treatment start date in period variable TRSDT does not.;
         %put %str(RTW)ARNING: &sysmacroname: Analysis relative day in period variables will not be derived.;
      %end;  /* end-if on TRSDT does not exist in input dataset */

   %end;  /* end-if on period APERIOD or TPERIOD exists */

   /*
   / Create the output dataset.
   /----------------------------------------------------------------------------*/

   data &dsetout;
      set &lastdset;
   run;

   /*
   / Delete temporary datasets used in this macro.
   /----------------------------------------------------------------------------*/

   %tu_tidyup(
      rmdset =&prefix:,
      glbmac =NONE
      );

%mend tu_adreldays;

