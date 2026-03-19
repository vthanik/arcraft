/*******************************************************************************
|
| Macro Name:      tu_datetm
|
| Macro Version:   2
|
| SAS Version:     8.2
|
| Created By:      Mark Luff / Eric Simms
|
| Date:            19-Jul-2004
|
| Macro Purpose:   Derive DATETIME variables
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME              DESCRIPTION                             REQ/OPT  DEFAULT
| ----------------  --------------------------------------  -------  ----------
| DSETIN            Specifies the dataset for which         REQ      (Blank)
|                   DATETIME variables are to be added. 
|                   Valid values: valid dataset name
| DSETOUT           Specifies the name of the ouput         REQ      (Blank)
|                   dataset to be created.
|                   Valid values: valid dataset name
| ----------------  --------------------------------------  -------  ----------
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
|
| Macros called:
|(@) tu_abort
|(@) tr_putlocals
|(@) tu_putglobals
|(@) tu_tidyup
|
| Example:
|    %tu_datetm(
|         dsetin  = _ae1,
|         dsetout = _ae2
|         );
|
|******************************************************************************
| Change Log
|
| Modified By:               Yongwei Wang
| Date of Modification:      08-Feb-2005
| New version/draft number:  1/2
| Modification ID:           YW001
| Reason For Modification:   1. Added upcase functions so the the macros work for
|                               mixed-case variable names
|                            2. Added format for DATETIME variable
|                          
| Modified By:               Yongwei Wang
| Date of Modification:      07-Nov-2007
| New version/draft number:  2/1
| Modification ID:           YW002
| Reason For Modification:   1. Make data set options work for &DSETIN and &DSETOUT
|                               - HRT0184
|                            2. If date/time is like BLDT/BLTM, the macro will
|                               derive the datetime variable like BLDM - HRT0180
*******************************************************************************/

%macro tu_datetm (
     dsetin      = ,      /* Input dataset  */
     dsetout     =        /* Output dataset */
        );

 /*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion;
 %let MacroVersion = 2;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals() 

 /*
 / PARAMETER VALIDATION
 /----------------------------------------------------------------------------*/

 %let dsetin  = %nrbquote(&dsetin);
 %let dsetout = %nrbquote(&dsetout);

 %if &dsetin eq %then
 %do;
    %put %str(RTE)RROR: TU_DATETM: The parameter DSETIN is required.;
    %let g_abort=1;
 %end;  /* end-if  Required DSETIN parameter not specified.  */

 %if &dsetout eq %then
 %do;
    %put %str(RTE)RROR: TU_DATETM: The parameter DSETOUT is required.;
    %let g_abort=1;
 %end;  /* end-if  Required DSETOUT parameter not specified.  */

 /*
 / Check that required dataset exists.
 /----------------------------------------------------------------------------*/

 %if %sysfunc(exist(%qscan(&dsetin, 1, %str(%()))) eq 0 %then
 %do;
    %put %str(RTE)RROR: TU_DATETM: The dataset DSETIN(=&dsetin) does not exist.;
    %let g_abort=1;
 %end;  /* end-if  Specified DSETIN parameter does not exist.  */

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;

 /*
 / If the input dataset name is the same as the output dataset name,
 / write a note to the log.
 /----------------------------------------------------------------------------*/

 %if %qscan(&dsetin, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
 %do;
    %put %str(RTN)OTE: TU_DATETM: The input dataset name (&dsetin) is the same as the output dataset name (&dsetout).;
 %end;  /* end-if  Specified values for DSETIN and DSETOUT parameters are the same.  */

 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/

 %local prefix;
 %let prefix = _datetm;   /* Root name for temporary work datasets */

 proc contents data = %unquote(&dsetin)
               out  = &prefix._vnames (keep=name)
               noprint;
 run;

 /*
 / Identify variable names ending in TM and create
 / a list of possible date variables ending in DT.
 /----------------------------------------------------------------------------*/

 %local tmlist;
 %let tmlist=' ';

 proc sql noprint;
      select "'"||upcase(substr(name,1,max(1,length(name)-2)))||"DT'" into :tmlist separated by ' '
      from &prefix._vnames
      where upcase(name) like '%TM';             /* YW001: Added two upcase functions */
 quit;

 /*
 / Some date variable names have a different stem than the time
 / variable names. Set the date variable name so that it agrees
 / with the time variable name.
 / With the exception of DSDT, the date variable name which will agree with
 / the time variable name can be derived by taking the first two characters 
 / from a four character variable name ending in DT and adding ACTDT to it.
 /----------------------------------------------------------------------------*/
 
 data &prefix._vnames;
      set &prefix._vnames;

      length _nm $ 100;

      _nm=upcase(name);  /* YW001 */       
      output; /* YW002: Added output to output twice for special cases */
      
      if length(name) eq 4 and upcase(substr(name,3,2)) eq 'DT' then
      do;
         if upcase(name) eq 'DSDT' then _nm = 'DSWDDT';
         else _nm=upcase(substr(name,1,2)) || "ACTDT";
         output;
      end; /* end-if  Set prefix to  date-time variables if name is 'DT' or 'DSDT'.  */
 run; 

 /*
 / Determine stem to use for variable names.
 / Write notes to log about which datetime variables will be created.
 /----------------------------------------------------------------------------*/

 %local any_flag;

 data &prefix._dtvars(drop=any_flag);
      set &prefix._vnames end=EOF;
      retain any_flag 'N';

      *** Subset on date variable names ***;
      if _nm in (&tmlist) then
      do;
         any_flag='Y';
         stem=substr(_nm,1,length(_nm)-2);
         output &prefix._dtvars;
         put "RTN" "OTE: TU_DATETM: Variable " stem +(-1) "DM will be created from the " name "and " stem +(-1) "TM variables.";
      end;  /* end-if Create datetime variable if Date/Time variable pair is found.  */

      if EOF then
      do;
         if any_flag='N' then put "RTN" "OTE: TU_DATETM: No Date/Time variable pairs found. No DATETIME variables will be created.";
      end;
 run;

 /*
 / Create program statement to derive the datetime variables.
 /----------------------------------------------------------------------------*/

 filename tmp1 temp;
 data _null_;
      set &prefix._dtvars;
      file tmp1;      
      put 'format ' stem +(-1) 'dm datetime20.;';                       /* YW001 */
      put 'if ' name 'ne . and ' stem +(-1) 'tm ne . then ' stem +(-1) 'dm=86400*' name '+' stem +(-1) 'tm;';
 run;

 /*
 / Execute statements within file.     
 /----------------------------------------------------------------------------*/

 data %unquote(&dsetout);
      set %unquote(&dsetin);
      %inc tmp1;
 run;

 /*
 / Delete temporary datasets used in this macro.      
 /----------------------------------------------------------------------------*/

 %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tu_datetm;
