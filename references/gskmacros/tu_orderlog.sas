/*******************************************************************************
|
| Macro Name:      tu_orderlog
|
| Macro Version:   1 build 1
|
| SAS Version:     8.2
|                                                             
| Created By:      Bob Newman (Amadeus) 
|
| Date:            21 September 2006
|
| Macro Purpose:   To create an ORDER clause suitable for a logarithmic axis
|                  to be used when plotting data from a given dataset.
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
|  logbase           Base of logarithms                             REQ      10
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
| %tu_orderlog(macrovar=x_order
|   , dsname=work.mydata
|   , varlist=hilimit lolimit
|   , logbase=10
|   , minvalue=0.1 
|   , maxvalue=
|  );
|
| This looks at the range of values of the HILIMIT and LOWLIMIT variables 
| of the MYDATA dataset, and generates an ORDER clause for a log axis suitable
| for plotting the full range. The lowest valued tick mark is forced to be
| at 0.1. The ORDER clause is stored as the value of MACROVAR, which is 
| declared as a global.
|
|******************************************************************************
| Change Log
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     21-Sep-06
| New version/draft number: 01.001
| Modification ID:          RCN.01.001
| Reason For Modification:  Original version
|
| Modified By:
| Date of Modification:
| New version/draft number:
| Modification ID:
| Reason For Modification:
*******************************************************************************/
  
%macro tu_orderlog(
   macrovar=             /* Name of macro variable to receive ORDER */
  ,dsetin=               /* Dataset name */
  ,varlist=              /* List of variables to be accommodated */
  ,logbase=10            /* Base of logarithms */
  ,minvalue=             /* Minimum ORDER value (optional) */
  ,maxvalue=             /* Maximum ORDER value (optional) */ 
  );
  
  /**---------------------------------------------------------------------*/
  /*--Normal Processing (NP1) -  Echo parameter values and global macro variables to the log */
  %local MacroVersion prefix currentDataset i macroname;
  %let macroname = &sysmacroname.;
  %let MacroVersion = 1 build 1;
  %let prefix = %substr(&sysmacroname,3); 
  %let currentDataset=&dsetin;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_analy_disp);

  /*----------------------------------------------------------------------*/ 
  /*-- NP2 - Parameter cleanup */
  %let macrovar=%nrbquote(&macrovar);
  %let dsetin=%nrbquote(&dsetin);
  %let varlist = %nrbquote(&varlist);
  %let logbase = %nrbquote(&logbase);
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

  /*--PV4 - LOGBASE: check is 2 or 10 */
  %if %length(&logbase) = 0
  %then
    %do;
      %put %str(RTE)RROR: &macroname: No Log base specified;
      %let pv_abort = 1;
      %let base_OK=N;
    %end;
  %else
    %do;
      %if &logbase=2 or &logbase=10
      %then
        %do;
          %let base_OK=Y;
        %end;
      %else
        %do;
          %put %str(RTE)RROR: &macroname: Log base must be either 2 or 10;
          %let pv_abort = 1;
          %let base_OK=N;
        %end;
    %end;
  
  /*--PV4 - MINVALUE: check that any value specified is numeric, and a power of LOGBASE */
  %if %length(&minvalue) > 0
  %then
    %do;
      %if %datatyp(&minvalue) ne NUMERIC 
      %then
        %do;
          %put %str(RTE)RROR: &macroname: Specified axis minimum "&minvalue" is not numeric; 
          %let pv_abort = 1;
        %end;
      %else 
        %do;
        %if %sysevalf(&minvalue le 0)
        %then
          %do;
            %put %str(RTE)RROR: &macroname: Specified axis minimum "&minvalue" is not positive; 
            %let pv_abort = 1;            
          %end;
        %else
          %do;
            %if &base_OK=Y
            %then
              %do;
                /*
                / The log function we use here happens to use base E.
                / We could equally well use log2 or log 10 - it does not matter.
                / All we are doing is working out what power MINVALUE is of LOGBASE */
                %let logmin=%sysevalf(%sysfunc(log(&minvalue))/%sysfunc(log(&logbase)));
                /* Now see whether it is an integer power */
                %let fraction=%sysevalf(&logmin - %sysfunc(round(&logmin)));
                %let fraction=%sysfunc(abs(&fraction));
                %if %sysevalf(&fraction ge 1E-10)          /* Testing for exactly zero is dicey */ 
                %then
                  %do;
                    %put %str(RTE)RROR: &macroname: Specified axis minimum "&minvalue" is not a power of logbase "&logbase"; 
                    %let pv_abort = 1;
                  %end; 
              %end;
          %end;
        %end; 
    %end;
    
  /*--PV5 - MAXVALUE: check that any value specified is numeric, and a power of LOGBASE */ 
  %local logmax fraction;
  %if %length(&maxvalue) > 0 
  %then
    %do;
      %if %datatyp(&maxvalue) ne NUMERIC 
      %then
        %do;
          %put %str(RTE)RROR: &macroname: Specified axis maximum "&maxvalue" is not numeric; 
          %let pv_abort = 1;
        %end;
      %else
        %if %sysevalf(&maxvalue le 0)
        %then
          %do;
          %put %str(RTE)RROR: &macroname: Specified axis maximum "&maxvalue" is not positive; 
          %let pv_abort = 1;
          %end;
        %else
          %do;
            %if &base_OK=Y
            %then
              %do;
                %let logmax=%sysevalf(%sysfunc(log(&maxvalue))/%sysfunc(log(&logbase)));
                /* Now see whether it is an integer power */
                %let fraction=%sysevalf(&logmax - %sysfunc(round(&logmax)));
                %let fraction=%sysfunc(abs(&fraction));
                %if %sysevalf(&fraction ge 1E-10)          /* Testing for exactly zero is dicey */
                %then
                  %do;
                    %put %str(RTE)RROR: &macroname: Specified axis maximum "&maxvalue" is not a power of logbase "&logbase"; 
                    %let pv_abort = 1; 
                  %end;  
              %end;
          %end;
      %end;
  
  /*--PV6 - MINVALUE vs MAXVALUE: if both specified, check for silly values */
  %if %length(&maxvalue) > 0 and %length(&minvalue) > 0 and &minvalue >= &maxvalue 
  %then 
    %do;
      %put %str(RTE)RROR: &macroname: Specified axis minimum not less than specified maximum; 
      %let pv_abort = 1;
    %end;
      
/*----------------------------------------------------------------------*/
  /*- complete parameter validation */
  %if %eval(&g_abort. + &pv_abort.) gt 0 %then %do;
    %put %str(RTE)RROR: &macroname: Macro has failed parameter validation check for reasons stated with %str(RTE)RRORs above;
    %tu_abort(option=force);
  %end;
  /*----------------------------------------------------------------------*/

  /*----------------------------------------------------------------------*/ 
  /*-- NP4 - Get maximum and minimum values from dataset */
  
  %local i vmin vmax thismin thismax;
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
 %if %length(&thismax) > 0
    %then
      %do;
        %let vmax=%sysfunc(max(&vmax,&thismax));
      %end;
    %if %length(&thismin) > 0
    %then
      %do;
        %let vmin=%sysfunc(min(&vmin,&thismin));
      %end;
    %let i=%eval(&i+1);
  %end;
  
  %if %sysevalf(&vmin=.) or %sysevalf(&vmin=.)
  %then
    %do;
       %put %str(RTE)RROR: &macroname: The variables do not have any non-missing values; 
       %let g_abort = 1; 
       %tu_abort; 
    %end;
    
  %if %sysevalf(&vmin <= 0)
  %then
    %do;
       %put %str(RTE)RROR: &macroname: Data for logarithmic axis includes non-positive values; 
       %let g_abort = 1; 
       %tu_abort; 
    %end;

  /*----------------------------------------------------------------------*/ 
  /*-- NP5 - Round VMIN and VMAX to powers of LOGBASE */
  %local logmin logmax;  
  %let logmin=%sysevalf(%sysfunc(log(&vmin))/%sysfunc(log(&logbase)));
  %let vmin=%sysevalf(&logbase ** %sysfunc(floor(&logmin)));
  %let logmax=%sysevalf(%sysfunc(log(&vmax))/%sysfunc(log(&logbase)));
  %let vmax=%sysevalf(&logbase ** %sysfunc(ceil(&logmax)));
 
  /*----------------------------------------------------------------------*/ 
  /*-- NP6 - Apply possible overrides from input parameters */
  
  /* All values here are now guaranteed to be powers of LOGBASE */
  %if &minvalue ne
  %then
    %do;
      %if &vmin < &minvalue
      %then
        %do;
              %put RTW%str(ARNING): &macroname: Data set contains values lower than the specified axis minimum;
        %end;
      %let vmin=&minvalue;
    %end;
  
  %if &maxvalue ne
  %then
    %do;
      %if &vmax > &maxvalue
      %then
        %do;
              %put RTW%str(ARNING): &macroname: Data set contains values higher than the specified axis maximum;
        %end;
      %let vmax=&maxvalue;
    %end;
    
/* We make this check only after MINVALUE and MAXVALUE have had the opportunity to solve the problem */
 %if &vmin=&vmax %then
    %do;
       %put %str(RTE)RROR: &macroname: Zero-length axis; 
       %let g_abort = 1; 
       %tu_abort; 
    %end;
 
  /*----------------------------------------------------------------------*/ 
  /*-- NP7 - Put together the ORDER clause */
  
  %local logorder val;
  %let logorder=LOGBASE=&logbase LOGSTYLE=EXPAND ORDER=%nrstr(%();
  %let val=&vmin;
  %do %while(&val le &vmax);
    %let logorder=&logorder &val;
    %let val=%sysevalf(&val*&logbase);
  %end;
  %let logorder=&logorder %nrstr(%));
  %let logorder=%sysfunc(compbl(&logorder));    /* Compress blanks */
  
  %global &macrovar;
  %let &macrovar=&logorder;
  
  /*----------------------------------------------------------------------*/
  /*--NP8 - Tidy up and call tu_abort   */
  
  /* In fact no datasets have been created and no globals need deleting. */ 
  %tu_tidyup(rmdset=&prefix:, glbmac=NONE);
  %tu_abort;

%mend tu_orderlog;

