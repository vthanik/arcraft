/*******************************************************************************
| Macro Name    : tu_percent.sas
|
| Macro Version : 2
|
| SAS version   : V8.2
|
| Created By    : Stephen Griffiths
|
| Date          : 25 June 2003
|
| Macro Purpose : Calculate percentage based on denominator and numerator and create
|                 a char field containing calculation information in selected style
|                 eg  73  (65%)
|
| Macro Design  : PROCEDURE STYLE MACRO
|                 Identification of Macros to log
|                 Define local macro variables
|                 Quick check for data set options
|                 Parameter Validation
|                 Apply any necessary data set options
|                 Continue with parameter validation for existence of variables since
|                    rename may have occurred
|                 Assign defaults where applicable
|                 Sort input data sets in preparation for the merge
|                 Call tu_abort in case any errors found
|                 Create picture format to apply to numeric percentage
|                 Merge two datasets together, creating the both a numeric and character
|                    version of the percentage
|                 Determine max lengths of all components for display formatting
|                 Create relevant result variable, with alignment applied
|                 Call tu_tidyup
|
|
| Input Parameters :
|
| NAME         DESCRIPTION                                                DEFAULT
| dsetinNumer  Specifies the name of the input numerator dataset
| dsetinDenom  Specifies the name of the input denominator dataset
| numerCntVar  Specifies the variable to be used as the numerator
| denomCntVar  Specifies the variable to be used as the denominator
| mergeVars    Specifies the variables to join the two input datasets on
| pctDps       Specify reporting precision for percentages                0
| resultStyle  Specifies the final format style to apply                  numerPct
| dsetout      Specifies the name of the output dataset
|
| Output: Data set containing the required percentage result, unformatted, and
|         formatted containing combinations of numerator, denominator and percentage
|         as requested via parameter.
|
| Global macro variables created: None
|
|
| Macros called :
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_chkvarsexist
| (@) tu_chknames
| (@) tu_sqlnlist
| (@) tu_tidyup
| (@) tu_abort
| (@) tu_quotelst
|
|
| *****************************************************************************
| Change Log :
|
| Modified By : Stephen Griffiths
| Date of Modification : 2 Oct 2003
| New Version Number : 1/2
| Modification ID :
| Reason For Modification : Error message clarification and missing numerator values
|                           set to blank.
|
|******************************************************************************
|
| Modified By : Stephen Griffiths
| Date of Modification : 3 Oct 2003
| New Version Number : 1/3
| Modification ID :
| Reason For Modification : Changed from full join to left join in SQL
|
*******************************************************************************
|
| Modified By :             Yongwei Wang
| Date of Modification :    21 May 2004
| New Version Number :      2/1
| Modification ID :         YW001
| Reason For Modification : 1. Added resultstyle=NUMER
|                           2. Modified resultstyle=NUMERDENOM or NUMERDENOMPCT
|                              so that if missing denominator, no '/' will be
|                              added.
|
*******************************************************************************
|
| Modified By :             Yongwei Wang
| Date of Modification :    22 Oct 2004
| New Version Number :      2/2
| Modification ID :         YW002
| Reason For Modification : Modified resultstyle=NUMERDENOM or NUMERDENOMPCT
|                           so that if denominator equals 0, no '/' will be
|                           added.
|
*******************************************************************************/
%macro tu_percent(
  dsetinNumer= ,          /* Numerator dataset                                */
  dsetinDenom= ,          /* Denominator dataset                              */
  numerCntVar= ,          /* Numerator variable                               */
  denomCntVar= ,          /* Denominator variable                             */
  mergeVars  = ,          /* Merge variables                                  */
  pctDps     =0 ,         /* Percentage decimal precision                     */
  resultStyle=numerPct ,  /* Result style to use                              */
  dsetout    =            /* Output dataset                                   */
  );
  /*
  / Identification of Macros to log
  /---------------------------------------------------------------------------*/
  %local MacroVersion;
  %let MacroVersion=2;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals()
  /*
  / Define local macro variables
  /---------------------------------------------------------------------------*/
  %local dsetNumer dsetDenom prefix i numer_l denom_l pct_l numer_rename
         denom_rename _blanks_ dsetNumer dsetDenom numervarlist denomvarlist
         bothvarlist match j k novars d1 d2 word;
  %let prefix=_percent;
  /*
  / Quick check for data set options
  /---------------------------------------------------------------------------*/
  %if %index(&dsetinNumer,%str(%()) %then %let dsetNumer=%scan(&dsetinNumer,1,%str(%());
  %else %let dsetNumer=&dsetinNumer;
  %if %index(&dsetinDenom,%str(%()) %then %let dsetDenom=%scan(&dsetinDenom,1,%str(%());
  %else %let dsetDenom=&dsetinDenom;
  %let d1=&dsetDenom;
  %let d2=&dsetNumer;
  /*
  / Parameter Validation
  /---------------------------------------------------------------------------*/
  %do i=1 %to 2;
    %let word=%scan(Denominator\Numerator,&i,%str(\));
    %if %length(&&d&i) eq 0 %then
    %do;
      %put %str(RTERR)%str(OR):TU_PERCENT: Input &word data set is missing;
      %let g_abort=1;
    %end;
    %if %sysfunc(exist(&&d&i)) eq 0 %then
    %do;
      %put %str(RTERR)%str(OR):TU_PERCENT: Input &word data set does not exist;
      %let g_abort=1;
    %end;
  %end;
  %if %quote(&dsetout) eq %then
  %do;
    %put %str(RTERR)%str(OR):TU_PERCENT: Missing output dataset name. ;
    %let g_abort=1;
  %end;
  %let d1=&denomCntVar;
  %let d2=&numerCntVar;
  %do i=1 %to 2;
    %let word=%scan(DenomCntVar\NumerCntVar,&i,%str(\));
    %if %length(&&d&i) eq 0 %then
    %do;
      %put %str(RTERR)%str(OR):TU_PERCENT: &word parameter is missing;
      %let g_abort=1;
    %end;
  %end;
  %*** YW001: Added NUMER ***;
  %if %quote(%upcase(&resultStyle)) ne NUMERPCT and
      %quote(%upcase(&resultStyle)) ne NUMERDENOMPCT and
      %quote(%upcase(&resultStyle)) ne NUMERDENOM and
      %quote(%upcase(&resultStyle)) ne PCT and
      %quote(%upcase(&resultStyle)) ne NUMER %then
  %do;
    %put %str(RTERR)%str(OR):TU_PERCENT: Invalid value (&resultstyle) given for resultStyle parameter;
    %let g_abort=1;
  %end;
  %if %length(&mergevars) eq 0 %then
  %do;
    %put %str(RTNO)%str(TE):TU_PERCENT: No variables supplied in mergevars. ;
  %end;
  %if %sysfunc(indexc(&pctDps,0123456789)) ne 0 %then
  %do;
    %if %sysfunc(mod(%sysfunc(abs(&pctDps)),1)) ne 0 or
        %sysfunc(abs(&pctDps)) ne %sysfunc(int(&pctDps)) %then
    %do;
      %put %str(RTERR)%str(OR):TU_PERCENT: Negative or Non-Integer value supplied in pctDps;
      %let g_abort=1;
    %end;
  %end;
  %else
  %do;
    %put %str(RTERR)%str(OR):TU_PERCENT: Missing or invalid value supplied in pctDps;
    %let g_abort=1;
  %end;
 %if %index(&dsetinDenom,%str(%()) %then %let dsetDenom=%scan(&dsetinDenom,1,%str(%());
  %if %tu_chknames(%scan(&dsetout,1,%str(%()),DATA) ne %then %do;
    %put %str(RTERR)%str(OR):TU_PERCENT: Invalid name given for output dataset;
    %let g_abort=1;
  %end;
  %tu_abort;
  /*
  / Since pctDps must have valid value, it is okay to change 1.0 into 1
  /---------------------------------------------------------------------------*/
  %let pctDps=%sysfunc(int(&pctDps));
  /*
  / Apply any necessary data set options
  /---------------------------------------------------------------------------*/
  data &prefix._numer;
   set &dsetinNumer;
  run;
  data &prefix._denom;
   set &dsetinDenom;
  run;
  /*
  / Continue with parameter validation for existence of variables since rename may
  / have occurred
  /---------------------------------------------------------------------------*/
  %if %quote(&mergevars) ne %then
  %do;
    %let novars=%tu_chkvarsexist(&prefix._numer,&mergevars);
    %if &novars ne %then
    %do;
      %put %str(RTERR)%str(OR):TU_PERCENT: Merge variable(s) &novars not present in dsetinNumer (&dsetnumer);
      %let g_abort=1;
    %end;
    %let novars=%tu_chkvarsexist(&prefix._denom,&mergevars);
    %if &novars ne %then
    %do;
      %put %str(RTERR)%str(OR):TU_PERCENT: Merge variable(s) &novars not present in dsetinDenom (&dsetdenom);
      %let g_abort=1;
    %end;
  %end;
  %tu_abort;
  %if %tu_chkvarsexist(&prefix._numer, &numerCntVar) ne %then
  %do;
    %put %str(RTERR)%str(OR):TU_PERCENT: %upcase(&numerCntVar) variable not present in numerator dataset;
    %let g_abort=1;
  %end;
  %if %tu_chkvarsexist(&prefix._denom, &denomCntVar) ne %then
  %do;
    %put %str(RTERR)%str(OR):TU_PERCENT: %upcase(&denomCntVar) variable not present in denominator dataset;
    %let g_abort=1;
  %end;
  %tu_abort;
  /*
  / Create picture format to apply to numeric percentage
  /---------------------------------------------------------------------------*/
  %let _blanks_ = %str(                                                                                                 );
  proc format;
  picture pcnt_f (round)
  0-<100="0009%left(%substr(%str( .9999999),%sysfunc(sign(&pctdps))+1,&pctdps+1)))%substr(&_blanks_&_blanks_,1,1)"
          (prefix='(')
     100=" (100%sysfunc(compress(%substr(%str( .00000),%sysfunc(sign(&pctdps))+1,&pctdps+1),' ')))%substr(&_blanks_&_blanks_,1,1)"
               (noedit)
  . -.Z =" " (noedit)
      0 =" " (noedit)
  ;
  run;
  /*
  / Create macro list of all variables in numerator data set
  /---------------------------------------------------------------------------*/
  proc contents data=&prefix._numer noprint out=&prefix._numerlist(keep=name);
  run;
  data _null_;
   set &prefix._numerlist end=eof;
   length _tmp_ $900;
   retain _tmp_ "";
   _tmp_=trim(left(_tmp_))||" "||trim(left(name));
   if eof then call symput('numervarlist',trim(left(_tmp_)));
  run;
  /*
  / Now create macro list of all variables in denominator data set, excluding
  / those already in numerator data set
  /---------------------------------------------------------------------------*/
  proc contents data=&prefix._denom noprint
                out=&prefix._denomlist(keep=name where=(upcase(name) not in (%upcase(%tu_quotelst(&numervarlist)))));
  run;
  data _null_;
   set &prefix._denomlist end=eof;
   length _tmp_ $900;
   retain _tmp_ "";
   _tmp_=trim(left(_tmp_))||" "||trim(left(name));
   if eof then call symput('denomvarlist',trim(left(_tmp_)));
  run;
  %if %length(&mergevars) ne 0 %then
  %do;
    /*
    / Now create the inverse, a list of vars in both data sets
    /-------------------------------------------------------------------------*/
    proc contents data=&prefix._denom noprint
                  out=&prefix._bothlist(keep=name where=(upcase(name) in (%upcase(%tu_quotelst(&numervarlist)))));
    run;
    data _null_;
     set &prefix._bothlist  end=eof;
     length _tmp_ $900;
     retain _tmp_ "";
     _tmp_=trim(left(_tmp_))||" "||trim(left(name));
     if eof then call symput('bothvarlist',trim(left(_tmp_)));
    run;
    %let match=0;
    %do j=1 %to %tu_words(&bothvarlist);
      %do k=1 %to %tu_words(&mergevars);
        %let curr_both=%upcase(%qscan(&bothvarlist,&j));
        %let curr_merge=%upcase(%qscan(&mergevars,&k));
        %if %quote(&curr_both) eq %quote(&curr_merge) %then %let match=%eval(&match+1);
      %end;
    %end;
    %if &match ne %tu_words(&bothvarlist) %then
    %do;
      %put %str(RTNO)%str(TE):TU_PERCENT: SQL join has more than one data set with repeats of MERGEVARS values.;
      %put %str(RTNO)%str(TE):TU_PERCENT: The MERGEVARS are &mergevars;
    %end;
  %end;
  /*
  / Merge two datasets together, creating the both a numeric and character
  / version of the percentage.
  /---------------------------------------------------------------------------*/
  proc sql feedback;
   create table &prefix._merged as
   select %tu_sqlnlist(&numervarlist,alias=numer), %tu_sqlnlist(&denomvarlist,alias=denom)
   from &prefix._numer numer
     %if %quote(&mergevars) ne %then
        left join;
     %else
        %str(,);
        &prefix._denom denom
   %if %quote(&mergevars) ne %then on %tu_sqlnlist(&mergevars, alias=numer, alias2=denom);
   ;
  quit;
  data &prefix._all;
   length tt_pct_c $15;
   set &prefix._merged;
   if &denomCntVar gt 0 and &numerCntVar ge 0 then tt_pct= &numerCntVar / &denomCntVar *100;
   else tt_pct=.;
   if tt_pct gt 0 then
   tt_pct_c=right(reverse(')%'||substr(reverse(trim(left(put(tt_pct,pcnt_f.)))),2)));
   if 0 lt tt_pct lt 1/(10**&pctdps) then tt_pct_c="(<"||trim(left(put(1/(10**&pctdps),best.)))||'%)';
   if (100-1/(10**&pctdps)) lt tt_pct lt 100 then tt_pct_c="(>"||trim(left(put(100-1/(10**&pctdps),best.)))||'%)';
  run;
  /*
  / Determine max lengths of all components for display formatting
  /---------------------------------------------------------------------------*/
  proc sql feedback noprint;
   select distinct
          max(length(trim(left(put(&numerCntVar,best.))))),
          max(length(trim(left(put(&denomCntVar,best.))))),
          max(length(trim(left(tt_pct_c))))  into : numer_l, : denom_l, : pct_l
   from &prefix._all;
  quit;
  /*
  / Create relevant result variable, with alignment applied
  /---------------------------------------------------------------------------*/
  data &dsetout;
  set &prefix._all;
  %*** YW001: added resultStyle=NUMER ***;
  %if %quote(%upcase(&resultStyle)) eq NUMER %then
  %do;
    length tt_result $%eval(&numer_l + 1);
    if missing(&numerCntVar) then tt_result=' ';
    else
       tt_result=repeat(' ',&numer_l - length(trim(left(put(&numerCntVar,best.)))))||trim(left(put(&numerCntVar,best.)));
  %end;
  %if %quote(%upcase(&resultStyle)) eq NUMERPCT %then
  %do;
    length tt_result $%eval(&numer_l + &pct_l + 2);
    tt_result=repeat(' ',&numer_l - length(trim(left(put(&numerCntVar,best.)))))||trim(left(put(&numerCntVar,best.)))||
              repeat(' ',&pct_l - length(trim(left(tt_pct_c))))||trim(left(tt_pct_c));
    if &numerCntVar=. then tt_result=' ';
  %end;
  %else %if %quote(%upcase(&resultStyle)) eq NUMERDENOMPCT %then
  %do;
    %*** YW001: Added if missing(&denomCntVar). YW002: Added ( &denomCntVar eq 0 )  ***;
    length tt_result $%eval(&numer_l + &denom_l + &pct_l + 5);
    if &numerCntVar=. then
       tt_result=' ';
    else if missing(&denomCntVar) or ( &denomCntVar eq 0 )  then
       tt_result=repeat(' ',&numer_l - length(trim(left(put(&numerCntVar,best.)))))||trim(left(put(&numerCntVar,best.)));
    else
       tt_result=repeat(' ',&numer_l - length(trim(left(put(&numerCntVar,best.)))))||trim(left(put(&numerCntVar,best.)))||' /'||
                 repeat(' ',&denom_l - length(trim(left(put(&denomCntVar,best.)))))||trim(left(put(&denomCntVar,best.)))||
                 repeat(' ',&pct_l - length(trim(left(tt_pct_c))))||trim(left(tt_pct_c));
  %end;
  %else %if %quote(%upcase(&resultStyle)) eq NUMERDENOM %then
  %do;
    %*** YW001: Added if missing(&denomCntVar). YW002: Added ( &denomCntVar eq 0 )  ***;
    length tt_result $%eval(&numer_l + &denom_l + 4);
    if &numerCntVar=. then
       tt_result=' ';
    else if missing(&denomCntVar) or ( &denomCntVar eq 0 ) then
       tt_result=repeat(' ',&numer_l - length(trim(left(put(&numerCntVar,best.)))))||trim(left(put(&numerCntVar,best.)));
    else
       tt_result=repeat(' ',&numer_l - length(trim(left(put(&numerCntVar,best.)))))||trim(left(put(&numerCntVar,best.)))||' /'||
                 repeat(' ',&denom_l - length(trim(left(put(&denomCntVar,best.)))))||trim(left(put(&denomCntVar,best.)));
  %end;
  /*
  / Special case for use by other utility macros, namely tu_freq
  /---------------------------------------------------------------------------*/
  %else %if %quote(%upcase(&resultStyle)) eq PCT %then
  %do;
    tt_result=tt_pct;
  %end;
  attrib tt_pct    label='Numerical percentage'
         tt_pct_c  label='Numerical percentage (character)'
         tt_result label='Result - formatted';
  run;
  /*
  / Perform house-keeping tasks
  /--------------------------------------------------------------------------*/
  %tu_tidyup(rmdset=&prefix.:,
             glbmac=none);
  %tu_abort();
%mend tu_percent;
