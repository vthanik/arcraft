/*******************************************************************************
|
| Macro Name:      tu_order
|
| Macro Version:   1 build 3
|
| SAS Version:     8.2
|                                                             
| Created By:      Bob Newman (Amadeus) 
|
| Date:            18 September 2006
|
| Macro Purpose:   To create an ORDER clause suitable for an axis to be used
|                  when plotting data from a given dataset.
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
| Date of Modification:     18-Sep-06
| New version/draft number: 01.001
| Modification ID:          RCN.01.001
| Reason For Modification:  Original version
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     02-Oct-06
| New version/draft number: 01.002
| Modification ID:          RCN.01.002
| Reason For Modification:  %SYSEVALF around tests, so we handle -ve floating-point numbers e.g. -1.2
|                           Check MACROVAR and VARLIST strings not empty.
|                           Handle case where ill-judged maxvalue or minvalue leaves no data in range.
|                           Check for invalid characters in MACROVAR.
|                           %local declarations added.
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     17-Oct-06
| New version/draft number: 01.003
| Modification ID:          RCN.01.003
| Reason For Modification:  NOPRINT on all calls to PROC SQL.
|
*******************************************************************************/
  
%macro tu_order(
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
  /*-- NP4 - Get maximum and minimum values from dataset */
  
  %local i vmin vmax thismax thismin;
  %let i=1;
  %let vmin=.;
  %let vmax=.;
  %do %while (%length(%scan(&varlist,&i)) > 0);
    %let thisvar=%scan(&varlist,&i);
    proc sql noprint;
      select max(&thisvar) into :thismax from &dsetin;
      select min(&thisvar) into :thismin from &dsetin;
    quit;
    /*
    / We take extreme care here since max & min functions will crash if called with all arguments missing.
    / This only applies when they are called from macro (and %sysevalf is implicitly involved).
    / Note that we use both "." and blank in the code here. It works - do not attempt to fix it.
    /*----------------------------------------------------------------------*/
    %if %sysevalf(&thismax ne)
    %then
      %do;
        %let vmax=%sysfunc(max(&vmax,&thismax));
      %end;
    %if %sysevalf(&thismin ne)
    %then
      %do;
        %let vmin=%sysfunc(min(&vmin,&thismin));
      %end;
    %let i=%eval(&i+1);
  %end;
  
  %if %sysevalf(&vmin=) or %sysevalf(&vmin=.)
  %then
    %do;
       %put %str(RTE)RROR: &macroname: The variables do not have any non-missing values; 
       %let g_abort = 1; 
       %tu_abort; 
    %end;
    
  /*----------------------------------------------------------------------*/ 
  /*-- NP5 - Apply possible overrides from input parameters */
  
  %if %sysevalf(&minvalue ne)
  %then
    %do;
      %if %sysevalf(&vmin < &minvalue)
      %then
        %do;
              %put RTW%str(ARNING): &macroname: Data set contains values lower than the specified axis minimum;
        %end;
      %let vmin=&minvalue;
    %end;
  
  %if %sysevalf(&maxvalue ne)
  %then
    %do;
      %if %sysevalf(&vmax > &maxvalue)
      %then
        %do;
              %put RTW%str(ARNING): &macroname: Data set contains values higher than the specified axis maximum;
        %end;
      %let vmax=&maxvalue;
    %end;
  
/* We make this check only after MINVALUE and MAXVALUE have had the opportunity to solve the problem */
 %if %sysevalf(&vmin=&vmax) %then
    %do;
       %put %str(RTE)RROR: &macroname: Zero-length axis; 
       %let g_abort = 1; 
       %tu_abort; 
    %end;
 
 %if %sysevalf(&vmin>&vmax) %then
    %do;
       %put %str(RTE)RROR: &macroname: Specified max or min leaves no data points in range; 
       %let g_abort = 1; 
       %tu_abort; 
    %end;
 
  /*----------------------------------------------------------------------*/ 
  /*-- NP6 - Calculate range, and its order of magnitude */
  %local vrange logrange magrange interval intcnt ourmin ourmax;
  %let vrange=%sysevalf(&vmax-&vmin);
  %let logrange=%sysfunc(log10(&vrange));
  %let magrange=%sysfunc(floor(&logrange));
  %let interval=%sysevalf(10.**&magrange);

  /*----------------------------------------------------------------------*/ 
  /*-- NP7 - Adjust interval until we have between about 5 and 10 tickmarks */

/* How many tickmarks with our currently proposed interval? */
  %let intcnt=%sysevalf(&vrange/&interval);

/* Adjust range so that we get between about 5 and 10 tickmarked intervals */
 %if &intcnt < 2
  %then
    %do;
	  %let interval=%sysevalf(&interval/5);
	%end;
  %else %if &intcnt < 5
  %then
    %do;
	  %let interval=%sysevalf(&interval/2);
    %end;

  /*----------------------------------------------------------------------*/ 
  /*-- NP8 - Calculate nice round values for endpoints */

  %let ourmin=%sysevalf(&interval.*%sysfunc(floor(&vmin./&interval.)));
  %let ourmax=%sysevalf(&interval.*%sysfunc(ceil(&vmax./&interval.)));

  /*----------------------------------------------------------------------*/ 
  /*-- NP9 - Set macro variable to contain required ORDER clause */
  
  %global &macrovar;
  %let &macrovar=order=(&ourmin to &ourmax by &interval);
  
  /*----------------------------------------------------------------------*/
  /*--NP10 - Tidy up and call tu_abort   */
  
  /* In fact no datasets have been created and no globals need deleting. */ 
  %tu_tidyup(rmdset=&prefix:, glbmac=NONE);
  %tu_abort;

%mend tu_order;

