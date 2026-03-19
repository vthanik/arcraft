/*******************************************************************************
|
| Macro Name:      tu_misschk
|
| Macro Version:   1
|
| SAS Version:     8.2
|
| Created By:      James Roberts / Eric Simms
|
| Date:            21-Dec-2004
|
| Macro Purpose:   Flag variables that only contain missing values
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME              DESCRIPTION                             REQ/OPT  DEFAULT
| ----------------  --------------------------------------  -------  ----------
| DSETIN            Specifies the dataset which             REQ      (Blank)
|                   will be checked for variables
|                   containing only missing values.
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
| N/A                                                     
| -----------------  -------  -------------------------------------------------
|
| Global macro variables created: NONE
|
|
| Macros called:
|(@) tr_putlocals
|(@) tu_abort
|(@) tu_putglobals
|(@) tu_tidyup
|
| Example:
|    %tu_misschk(
|         dsetin  = _ae1
|         );
|
|******************************************************************************
| Change Log
|
| Modified By:
| Date of Modification:
| New version/draft number:
| Modification ID:
| Reason For Modification:
|
*******************************************************************************/

%macro tu_misschk(
     dsetin=                 /* Input dataset */
        );

 /*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion;
 %let MacroVersion = 1;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals() 

 /*
 / PARAMETER VALIDATION
 /----------------------------------------------------------------------------*/

 %let dsetin  = %nrbquote(&dsetin);

 %if &dsetin eq %then
 %do;
    %put %str(RTE)RROR: TU_MISSCHK: The parameter DSETIN is required.;
    %let g_abort=1;
 %end;  /* end-if  Required DSETIN parameter not specified.  */

 /*
 / Check that required dataset exists.
 /----------------------------------------------------------------------------*/

 %if %sysfunc(exist(&dsetin)) eq 0 %then
 %do;
    %put %str(RTE)RROR: TU_MISSCHK: The dataset DSETIN (&dsetin) does not exist.;
    %let g_abort=1;
 %end;  /* end-if  Specified DSETIN parameter does not exist.  */

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end; /* end-if abort flag was set. */

 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/

 %local prefix;
 %let prefix = _misschk;   /* Root name for temporary work datasets */

 /*
 / Get input dataset metadata.
 /----------------------------------------------------------------------------*/

 proc contents data=&dsetin out=&prefix._vnames(keep=name) noprint;
 run;               

 /*
 / Create macro variables for dataset variable names 
 / and number of observations in the dataset       
 /----------------------------------------------------------------------------*/

 data _null_;
      set &prefix._vnames end=last;
      if last then do;
         call symput ('s',_n_);
      end;
      call symput ('var'||left(_n_),trim(name));
 run;

 /*
 / Identify variables in the dataset with only missing values
 / and output error message to log                 
 /----------------------------------------------------------------------------*/

 proc sql; 
      create table &prefix._missvar as 
      select
      %do i=1 %to %eval(&s-1);
             count(distinct &&var&i) as no_&&var&i,
      %end;
      %do i=&s %to &s;
             count(distinct &&var&i) as no_&&var&i 
      %end;
      from &dsetin;
 quit;

 data _null_;
      set &prefix._missvar;
      %do i=1 %to &s;
          if no_&&var&i eq 0 then 
          do;
             put "RTW" "ARNING: TU_MISSCHK: The variable &&var&i on the DSETIN dataset (&dsetin) contains missing values on all records";
          end;
      %end;
 run;

 /*
 / Delete temporary datasets used in this macro.      
 /----------------------------------------------------------------------------*/

 %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tu_misschk;
 
