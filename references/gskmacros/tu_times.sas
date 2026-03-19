/*******************************************************************************
|
| Macro Name:      tu_times
|
| SAS Version:     9.1
|
| Created By:      Barry Ashby
|
| Date:            25-Feb-2008
|
| Macro Purpose:   Creates time variables by Day, Hour and Minute
|
| Macro Design:    Statement Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                              REQ/OPT  DEFAULT
| -----------------  -------------------------------------    -------  ----------
| DSETIN             Specifies existing dataset name.         REQ      _LAST_
|
| UNIT               Specifies whether the output will be     REQ      <blank>
|                    the number of days (D) or the elapsed
|                    time in days, hours, and minutes (M).
|                    Valid Values: D or M
|
| START              Specifies the variable that contains     REQ      <blank>
|                    the start datetime.
|                    Valid Values: An existing date or 
|                    datetime variable,
|
| END                Specifies the variable that contains     REQ      <blank>
|                    the end datetime.
|                    Valid Values: An existing date or 
|                    datetime variable,
|
| OUTPUT             Name of the output variable for the      REQ      <blank>
|                    numeric output.
|                    Valid Values: Valid sas variable name    REQ      <blank>
|
| OUTPUTC            Name of the output variable for the 
|                    character output.
|                    Valid Values: Valid sas variable name    REQ      <blank>
|
| NEGYN              Specifies whether or not negative        REQ      N
|                    negative values will be allowed.
|                    Valid Values: Y or N,
|
| The macro references the following datasets :-
| ------------------  -------  ------------------------------------------------
| Name                Req/Opt  Description
| ------------------  -------  ------------------------------------------------
| &DSETIN             Req      Parameter specified dataset
|
| The macro outputs the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
|
| -----------------  -------  -------------------------------------------------
|
| Global macro variables created: NONE
|
| Macros called:
|(@) tr_putlocals
|(@) tu_abort
|(@) tu_chkvarsexist
|(@) tu_nobs
|(@) tu_putglobals
|
| Example:  %tu_times(dsetin = dataset,
|                     unit   = D,
|                     start  = startdate,
|                     end    = enddate,
|                     output = outnum,
|                     outputc= outchar,
|                     negyn  = N);
|
|*******************************************************************************
| Modified By:              Khilit Shah (kys41925)
| Date of Modification:     14-Oct-2008
| New version/draft number: 2
| Modification ID:          n/a
| Reason For Modification:  
|                           1 For calculating time in xD yH zM  calculation will be
|                             END datetime minus START datetime
|                             - IF END datetime minus START datetime is -ve result then
|                               (end - start) 
|                             - IF END datetime minus START datetime is +ve result then
|                               (end - start) + 1
|                           2 When STARTDTM minus ENDDTM and NEGYN = Y, the output 
|                             i.e was getting produced as -xD -yH -zM. Should be
|                             displayed as -xD yH zM
|*******************************************************************************
| Modified By:              
| Date of Modification:     
| New version/draft number: 
| Modification ID:          
| Reason For Modification:  
*******************************************************************************/

%macro tu_times (
   dsetin           = _LAST_,   /* Input dataset                     */
   unit             =,          /* d for days or m for minutes       */
   start            =,          /* start datetime variable           */
   end              =,          /* end datetime variable             */
   output           =,          /* numeric output in days or minutes */
   outputc          =,          /* character output                  */
   negyn            = N         /* allow negative values?            */
   );

   /*
   / Echo parameter values and global macro variables to the log.
   /----------------------------------------------------------------------------*/
   %local MacroVersion;
   %let MacroVersion = 2;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals();
  
   %local macroname prefix l_thisvar l_listvars i l_rc l_start_type l_end_type l_start_format l_end_format l_dsname l_libname;

   %let macroname = &sysmacroname.;
   %let prefix = _tu_times;         /* Root name for temporary work datasets */

   %let l_start_type =;
   %let l_start_format =;
   %let l_end_type =;
   %let l_end_format =;
   
   /*
   / PARAMETER VALIDATION
   /----------------------------------------------------------------------------*/
   
   /*
   / Check if &DSETIN is an existing dataset.
   /----------------------------------------------------------------------------*/
   %if %nrbquote(&dsetin) eq %then %do;
      %put %str(RTERR)OR: &sysmacroname: the required parameter DSETIN is blank.;
      %let g_abort=1;
      %tu_abort(option=force);
   %end;

   /*
   / Check if &DSETIN is using _LAST_ dataset option, if so find and set name to dsetin
   /------------------------------------------------------------------------------------*/
   %let dsid=%sysfunc(open(&dsetin,i));
   %if (&dsid = 0) %then %do;
      %put %str(RTERR)OR: &sysmacroname: input data set DSETIN(=&dsetin) does not exist;
      %let g_abort=1;
      %tu_abort(option=force);
   %end;
   %else %do;
      %let l_dsname = %upcase(%sysfunc(attrc(&dsid,mem)));
      %let l_libname = %upcase(%sysfunc(attrc(&dsid,lib))); 
      %if %upcase(&dsetin) = _LAST_ %then %do;
         %let dsetin = &l_libname..&l_dsname;
         %put %str(RTN)OTE: &macroname: _LAST_ dataset is &dsetin, setting value to parameter DSETIN;
      %end;
      %let l_num = %sysfunc(attrn(&dsid,nvars));
      %do indx=1 %to &l_num;
         %if %upcase(&start) = %upcase(%sysfunc(varname(&dsid,&indx))) %then %do;
            %let l_start_type=%sysfunc(vartype(&dsid,&indx));
            %let l_start_format=%sysfunc(varfmt(&dsid,&indx));
         %end;
         %if %upcase(&end) = %upcase(%sysfunc(varname(&dsid,&indx))) %then %do;
            %let l_end_type=%sysfunc(vartype(&dsid,&indx));
            %let l_end_format=%sysfunc(varfmt(&dsid,&indx));
         %end;
      %end;
      %let l_rc=%sysfunc(close(&dsid));
   %end;

   %if %tu_nobs(&dsetin) LT 0 %then %do;
      %put %str(RTERR)OR: &sysmacroname: input data set DSETIN(=&dsetin) does not exist;
      %let g_abort=1;
      %tu_abort(option=force);
   %end;
   
   /*
   / Check for required parameters.
   /----------------------------------------------------------------------------*/
  
   %let l_listvar=UNIT START END OUTPUT OUTPUTC NEGYN;
  
   %let i=1;
   %let l_thisvar=%scan(&l_listvar, &i, %str( ));

   %do %while (%nrbquote(&l_thisvar) ne ) ;
      %if %nrbquote(&&&l_thisvar) eq %then %do;
         %put %str(RTE)RROR: &sysmacroname: The parameter (&l_thisvar) is required.;
         %let g_abort=1;
      %end;    
      
      %let i=%eval(&i + 1);
      %let l_thisvar=%scan(&l_listvar, &i, %str( ));
   %end;  /* end of do while loop */

   /*
   / Check if &START exist in &DSETIN dataset.
   /----------------------------------------------------------------------------*/
   %if %nrbquote(%tu_chkvarsexist(&dsetin, &START)) NE %then %do;
      %put %str(RTERR)OR: &sysmacroname: Variable START(=&START) does not exist in data set DSETIN(=&DSETIN).;
      %let g_abort=1;
   %end;
   %else %do;
   /*
   / Check if &START data type is not numeric or if the format value is missing
   /----------------------------------------------------------------------------*/
      %if &l_start_type = CHAR OR &l_start_format eq %then %do;
         %put %str(RTERR)OR: &sysmacroname: Variable START(=&START) is not numeric or is missing a format.;
         %let g_abort=1;
      %end;
   /*
   / Check if &START format is TIME, if so then set abort flag
   /----------------------------------------------------------------------------*/
      %else %if %substr(&l_start_format,1,4) = TIME %then %do;
         %put %str(RTERR)OR: &sysmacroname: Variable START(=&START) is not a date and not a datetime format.;
         %let g_abort=1;
      %end;
   %end;

   /*
   / Check if &END exist in &DSETIN dataset.
   /----------------------------------------------------------------------------*/
   %if %nrbquote(%tu_chkvarsexist(&dsetin, &END)) NE %then %do;
      %put %str(RTERR)OR: &sysmacroname: Variable END(=&END) does not exist in data set DSETIN(=&DSETIN).;
      %let g_abort=1;
   %end;                                   
   %else %do;
   /*
   / Check if &END data type is not numeric or if the format value is missing
   /----------------------------------------------------------------------------*/
      %if &l_end_type = CHAR OR &l_end_format eq %then %do;
         %put %str(RTERR)OR: &sysmacroname: Variable END(=&END) is not numeric or is missing a format.;
         %let g_abort=1;
      %end;
   /*
   / Check if &END format is TIME, if so then set abort flag
   /----------------------------------------------------------------------------*/
      %else %if %substr(&l_end_format,1,4) = TIME %then %do;
         %put %str(RTERR)OR: &sysmacroname: Variable END(=&END) is not a date and not a datetime format.;
         %let g_abort=1;
      %end;
   %end;
   
   /*
   / Check NEGYN for Y/N parameter values.
   /----------------------------------------------------------------------------*/
   
   %if (%upcase(&NEGYN) ne Y) and (%upcase(&NEGYN) ne N) %then %do;
      %put %str(RTE)RROR: &SYSMACRONAME.: Value of parameter NEGYN(=&negyn) is invalid. Valid values: Y or N.;       
      %let g_abort=1;    
   %end;
  
   /*
   / Check UNIT for valid values D/M.
   /----------------------------------------------------------------------------*/
   
   %if (%upcase(&unit) ne D) and (%upcase(&unit) ne M) %then %do;
      %put %str(RTE)RROR: &SYSMACRONAME.: Value of parameter UNIT(=&unit) is invalid. Valid values: D or M.;       
      %let g_abort=1;    
   %end;

   %if &g_abort eq 1 %then %do;
      %tu_abort;
   %end;   
   
   /*
   / NORMAL PROCESSING
   /----------------------------------------------------------------------------*/

   /*
   / Will only create negative times if NEGYN is set to Y. Otherwise, if end date
   / is earlier than start date then output will be null.  
   /----------------------------------------------------------------------------*/

   %let l_start_format = %substr(&l_start_format,1,%sysfunc(min(8,%length(&l_start_format))));  /* Reset variable to hold DATETIME value if available */
   %let l_end_format   = %substr(&l_end_format,1,%sysfunc(min(8,%length(&l_end_format))));      /* Reset variable to hold DATETIME value if available */

   &output=.;
   &outputc='                    ';

   /*
   / Note for the checks and calculations below, the code will check for unit = Days and if true to only  
   / use the date part for datetime variables.
   /-----------------------------------------------------------------------------------------------------*/

   /*
   / If one of the parameters START or END is not a datetime format and the unit = Minutes
   / then the code will output a RTWARNING msg to the log and change unit = Days so the
   / code calculations will generate day results.
   /-----------------------------------------------------------------------------------------*/
   %if %upcase(&unit) = M AND (&l_end_format ne DATETIME OR &l_start_format ne DATETIME) %then %do;
      %put %str(RTW)ARNING: &SYSMACRONAME.: Units requested in days, hours, and minutes however one of the variables: %upcase(&start) OR %upcase(&end) is not a DATETIME format, changing UNITS to Days;
       %let unit = D;  /* Change the Unit to Days, process below */
   %end;

   /*
   / This line will resolve after macro processing to resemble this:
   / if &start and &end and ("&unit" = 'Y' OR &end ge &start ) then do;
   /----------------------------------------------------------------------------*/
   if &start and &end and ("%upcase(&negyn)" = 'Y' OR 
      %if &l_end_format = &l_start_format %then &end ge &start; %else %do;
         %if &l_end_format = DATETIME %then datepart(&end); %else &end; ge %if &l_start_format = DATETIME %then datepart(&start); %else &start;
      %end ;
      ) then do;
    
   /* If unit = D then subtract two DATE variables (not datetime) */
      if "%upcase(&unit)" = 'D' then do;
         if %if &l_end_format = DATETIME %then datepart(&end); %else &end; ge %if &l_start_format = DATETIME %then datepart(&start); %else &start; then 
            &output = ceil(%if &l_end_format = DATETIME %then datepart(&end); %else &end; - %if &l_start_format = DATETIME %then datepart(&start); %else &start;);
         else 
            &output = floor(%if &l_end_format = DATETIME %then datepart(&end); %else &end; - %if &l_start_format = DATETIME %then datepart(&start); %else &start;);
         if &output ge 0 then &output + 1;
         &outputc = compress(put(&output,best.))||'d';
       end; /* if unit = D */

  /* else if unit = M then subtract two DATETIME variables */
      else if "%upcase(&unit)" = 'M' then do;
         &output = int((&end-&start)/60) ;
         if sign(&output) GE 0 then do ;
           &output + 1 ;
         end;
         &outputc=LEFT(TRIM(compress(put(int(&output/(60 * 24)),best.))||'d'||' '||compress(put(int(&output/60)-(int(&output/(60 * 24)) * 24),best.))||'h'||' '||compress(put(mod(&output,60),best.))||'m' ));
         * if negyn = y, then ensure the sign, '-' only appears once ;
         *   and not for every combination of D,H and M              ;                                 
         * i.e. appears as -xD yH zM and not as -xD -yH -zM          ;
         if indexc(&outputc,'-') then do;
           &outputc = LEFT(COMPBL('-'!!tranwrd(&outputc, '-', ''))) ;
         end;
      end; /* else if unit = M */
   end; /* if &start and &end and (negyn = Y OR &end GE &start) */

%mend tu_times;
