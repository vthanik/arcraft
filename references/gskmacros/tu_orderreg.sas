/*******************************************************************************
|
| Macro Name:      tu_orderreg
|
| Macro Version:   1 build 3
|
| SAS Version:     8.2
|                                                             
| Created By:      Bob Newman (Amadeus) 
|
| Date:            20 September 2006
|
| Macro Purpose:   To create an ORDER clause suitable for an axis to be used
|                  when plotting data from a given dataset.
|                  This macro is specifically for the case where data points are
|                  evenly spaced along the axis, and tick marks are required 
|                  to coincide with the data points.
|                  NB if spacing is irregular, an empty string will be returned. 
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME             DESCRIPTION                                  REQ/OPT  DEFAULT
| --------------   -----------------------------------          -------  --------------
|  macrovar          Name of macro variable to receive ORDER clause REQ      NONE
|  dsetin            Dataset name                                   REQ      NONE
|  varlist           List of variables to be covered by the ORDER   REQ      NONE
|  minvalue          Minimum value for use in ORDER clause          OPT      [BLANK]
|  maxvalue          Maximum value for use in ORDER clause          OPT      [BLANK]
|
| Output: macrovar contains the required ORDER clause.
|
| Global macro variables created: 
|   macrovar (whose name is passed as a parameter) is declared global. 
| 
| Macros called: 
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_chknames
| (@) tu_putglobals
| (@) tu_tidyup
| (@) tu_valparms
|
| Example:
| %tu_order(macrovar=x_order
|   , dsname=work.mydata
|   , varlist=hilimit lolimit
|   , minvalue=0 
|   , maxvalue=
|  );
|
| This looks at the range of values of the HILIMIT and LOWLIMIT variables 
| of the MYDATA dataset, and generates an ORDER clause for an axis suitable
| for plotting the full range. The lowest valued tick mark is forced to be
| at 0. The ORDER clause is stored as the value of MACROVAR, which is 
| declared as a global.
|
|******************************************************************************
| Change Log
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     20-Sep-06
| New version/draft number: 01.001
| Modification ID:          RCN.01.001
| Reason For Modification:  Original version
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     03-Oct-06
| New version/draft number: 01.002
| Modification ID:          RCN.01.002
| Reason For Modification:  Use of formatted values to solve problems with non-integer intervals.
|                           (Applied to both INT and CHECK datasets.)
|                           Check MACROVAR and VARLIST not blank.
|                           Introduced VALVALFMT - see comments inline.
|                           Use MOD function when evaluating OURMIN, OURMAX.
|                           Added %local declarations.
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     17-Oct-06
| New version/draft number: 01.003
| Modification ID:          RCN.01.003
| Reason For Modification:  NOPRINT on all use of PROC SQL.
|
*******************************************************************************/
  
%macro tu_orderreg(
   macrovar=             /* Name of macro variable to receive ORDER */
  ,dsetin=               /* Dataset name */
  ,varlist=              /* List of variables to be accommodated */
  ,minvalue=             /* Minimum ORDER value (optional) */
  ,maxvalue=             /* Maximum ORDER value (optional) */ 
  );
  
  /**---------------------------------------------------------------------*/
  /*--Normal Processing (NP1) -  Echo parameter values and global macro variables to the log */
  %local MacroVersion prefix currentDataset i macroname;
  %let macroname = &sysmacroname.;
  %let MacroVersion = 1 build 3;
  %let prefix = %substr(&sysmacroname,3); 
  %let currentDataset=&dsetin;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_analy_disp);

  /*----------------------------------------------------------------------*/ 
  /*-- NP2 - Parameter cleanup */
  %let macrovar=%nrbquote(&macrovar);
  %let dsetin=%nrbquote(&dsetin);
  %let varlist = %nrbquote(&varlist);
  %let minvalue=%nrbquote(&minvalue);
  %let maxvalue=%nrbquote(&maxvalue);

  /*----------------------------------------------------------------------*/ 
  /*-- NP3 - Perform Parameter validation*/
  /*-- set up a macro variable to hold the pv_abort flag*/
  %local pv_abort;
  %let pv_abort = 0;

  /*--PV1 - MACROVAR: check that the macro variable name is valid */
  %if %length(%qcmpres(&macrovar.)) = 0
  %then
    %do;
      %put %str(RTE)RROR: &macroname: The macro variable name is null;
      %let pv_abort = 1;
    %end;
  %else
    %do;
      %local validchars;
      %let validchars=ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz_0123456789;
      %if %verify(&macrovar,&validchars) ne 0
      %then
        %do;
          %put %str(RTE)RROR: &macroname: The macro variable name "&macrovar" contains an invalid character; 
          %let pv_abort = 1;
        %end;
      %else
        %if %length(%tu_chknames(&macrovar., VARIABLE)) > 0 
        %then
          %do;
            %put %str(RTE)RROR: &macroname: The macro variable name "&macrovar" is invalid; 
            %let pv_abort = 1;
          %end;
    %end;
  
  /*--PV2 - DSNAME: check that the dsetin exists*/
  %tu_valparms(macroname = &macroname., chktype=dsetExists, pv_dsetin = dsetin, abortyn = N);

  /*--PV3 - VARLIST: check that the variables exist and are numeric*/
  %if %length(%qcmpres(&varlist.)) = 0
  %then
    %do;
      %put %str(RTE)RROR: &macroname: The varlist string is empty;
      %let pv_abort = 1;
    %end;
  %else
    %do;
  %tu_valparms(macroname = &macroname., chktype=varExists, pv_dsetin = dsetin, pv_varsin=varlist, abortyn = N);
  %tu_valparms(macroname = &macroname., chktype=isNum, pv_dsetin = dsetin, pv_varsin=varlist, abortyn = N);
    %end;

  /*--PV4 - MINVALUE: check that any value specified is numeric */
  %if %length(&minvalue) > 0 and %datatyp(&minvalue) ne NUMERIC
  %then
    %do;
      %put %str(RTE)RROR: &macroname: Specified axis minimum "&minvalue" is not numeric;
      %let pv_abort = 1;
    %end;
    
  /*--PV5 - MAXVALUE: check that any value specified is numeric */
  %if %length(&maxvalue) > 0 and %datatyp(&maxvalue) ne NUMERIC
  %then
    %do;
      %put %str(RTE)RROR: &macroname: Specified axis maximum "&maxvalue" is not numeric; 
      %let pv_abort = 1;
    %end;
  
  /*--PV6 - MINVALUE vs MAXVALUE: if both specified, check for silly values */
  %if %length(&maxvalue) > 0 and %length(&minvalue) > 0 and &minvalue >= &maxvalue 
  %then 
    %do;
      %put %str(RTE)RROR: &macroname: Specified axis minimum not less than specified maximum; 
      %let pv_abort = 1;
    %end;
    
/*
/ Having MIN > MAX might make sense if we allowed axes to have decreasing values. 
/ We could then specify the interval as negative. 
/ However no need for this at present so we do not implement it.
/*----------------------------------------------------------------------*/
  
/*----------------------------------------------------------------------*/
  /*- complete parameter validation */
  %if %eval(&g_abort. + &pv_abort.) gt 0 %then %do;
    %put %str(RTE)RROR: &macroname: Macro has failed parameter validation check for reasons stated with %str(RTE)RRORs above;
    %tu_abort(option=force);
  %end;
  /*----------------------------------------------------------------------*/

  /*----------------------------------------------------------------------*/ 
  /*-- NP4 - Get all the different values into a dataset */
    
    /* If no fit found, we will return empty string */
    %global &macrovar;
      %do;
        %let &macrovar=;
      %end;
      
  /* First a separate dataset for each variable */
  
  %local i;
  %let i=1;
  %do %while (%length(%scan(&varlist,&i)) > 0);
    %let thisvar=%scan(&varlist,&i);
    proc sql noprint;
      create table &prefix._v&i. as
        select distinct &thisvar as varval from &dsetin(where=(&thisvar ne .)) 
        order by &thisvar;
    quit;
    %let i=%eval(&i+1);
  %end;
  
  %local numvars;
  %let numvars=%eval(&i-1);
  
  /* Then concatenate them all */
  
  data &prefix._all;
    set
    %do i=1 %to &numvars;
      &prefix._v&i
    %end;
    ;
    varvalfmt=put(varval,best12.);
    * varvalfmt needed if we are to handle the case of large values with small intervals;
    * Default precision of macro variables ds_min etc would not be sufficient;
    * We also have to handle negative values correctly;
    * Technique used in next SQL step meets all these requirements; 
  run;

  /* Now reduce to unique values, and get some basic statistics */
  %local ds_min ds_max numvals;
  proc sql noprint;
    create table &prefix._uniq as
      select distinct varval,varvalfmt from &prefix._all
      order by varval;
    select varvalfmt into :ds_min from &prefix._uniq
      where varval in (select min(varval) from &prefix._uniq);
    select varvalfmt into :ds_max from &prefix._uniq
      where varval in (select max(varval) from &prefix._uniq);
    select count(*) into :numvals from &prefix._uniq;
  quit;

%if &numvals =0 or %length(&numvals)=0
%then
  %do;
    %put %str(RTE)RROR: &macroname: The variables do not have any non-missing values; 
    %let g_abort = 1; 
    %tu_abort; 
  %end;

%if &numvals =1
%then
  %do;
    %put %str(RTE)RROR: &macroname: The variables only have one non-missing value;
    %let g_abort = 1; 
    %tu_abort; 
  %end;

  /*----------------------------------------------------------------------*/ 
  /*-- NP5 - Calculate intervals, and their frequencies */
  
data &prefix._int;
  set &prefix._uniq;
  * Use of formatted value protects us from rounding issues;
  interval=put(dif(varval),best12.);
run;

* Count the frequency of each interval, and see what interval is most common;
%local maxfreq ourint;
proc sql noprint;
  create table &prefix._intcnt as
    select count(*) as _freq_,interval
	  from &prefix._int
	  group by interval;
  select max(_freq_) into :maxfreq from &prefix._intcnt;
  select interval into :ourint from &prefix._intcnt where _freq_=&maxfreq;
quit;

  /*----------------------------------------------------------------------*/ 
  /*-- NP6 - If one interval predominates, see if we can make tick marks
  /    hit most of the data points. 
  /************************************************************************/
%local ourmin ourmax;
    /* If more than half are the same, we give it a go */
%if %eval(2*&maxfreq) > &numvals
%then
  %do;
    /* Set tentative max and min as multiples of interval,
    /  unless overridden by input parameters */
    
    %if %length(&minvalue) > 0
	%then
	  %do;
	     %let ourmin=&minvalue;
         %if %sysevalf(&ds_min < &minvalue)
         %then
           %do;
             %put RTW%str(ARNING): &macroname: Data set contains values lower than the specified axis minimum; 
           %end;
	  %end;
	%else
	  %do;
        %let ourmin=%sysevalf(&ds_min-%sysfunc(mod(&ds_min,&ourint)));
      %end;
	%if %length(&maxvalue) > 0
	%then
	  %do;
	     %let ourmax=&maxvalue;
         %if %sysevalf(&ds_max > &maxvalue)
         %then
           %do;
             %put RTW%str(ARNING): &macroname: Data set contains values higher than the specified axis maximum;
           %end;
	  %end;
	%else
	  %do;
        %if %sysfunc(mod(&ds_max,&ourint)) > 0
        %then
          %do;
            %let ourmax=%sysevalf(&ds_max+&ourint);
          %end;
        %else
          %do;
            %let ourmax=&ds_max;
          %end;
      %end;
      
	/* We think we need "order=(ourxmin to ourxmax by ourint)".
	/* We now check how many of the data points would hit our tick marks exactly */ 
    data &prefix._check;
	  set &prefix._uniq;
      vdif=put(varval-&ourmin,best12.);
      rdif=put(round(varval-&ourmin,%sysevalf(&ourint/10.)),best12.);
      OK=(vdif=rdif); 
    run;
    
    %local numok answer;    
	proc sql noprint;
	  select count(*) into :numok from &prefix._check(where=(OK));
	quit; 

  /*----------------------------------------------------------------------*/ 
  /*-- NP7 - Set macro variable to contain required ORDER clause */
  /* If more than half data points are at tick marks, that is good enough */

	%if %eval(2*&numok) > &numvals
	%then
	  %do;
        %let answer=order=(&ourmin to &ourmax by &ourint);
        %let answer=%sysfunc(compbl(&answer));  /* Compress blanks */
	    %let &macrovar=&answer;
      %end;
  %end;

  /*----------------------------------------------------------------------*/
  /*--NP8 - Tidy up and call tu_abort   */
  
  %tu_tidyup(rmdset=&prefix:, glbmac=NONE);
  %tu_abort;

%mend tu_orderreg;

