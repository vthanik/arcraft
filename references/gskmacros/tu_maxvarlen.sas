/*******************************************************************************
|
| Macro Name:      tu_maxvarlen
|
| Macro Version:   1
|
| SAS Version:     8.2
|
| Created By:      Prakash Chandra
|
| Date:            31-Aug-2012
|
| Macro Purpose:   Create a dataset containing character variable name and its 
|                  length
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                            REQ/OPT  DEFAULT
| -----------------  -------------------------------------  -------  ----------
| DSETIN             Specifies the dataset for which        REQ      (Blank)
|                    the maximum length for each character
|                    variable is to be found and stored 
|                    in a dataset.
|                    Valid values: Valid dataset name.
|
| DSETOUT            Specifies the output dataset name      REQ      (Blank)
|                    which will contain the variable and  
|                    its maximum size.        
| -----------------  -------------------------------------  -------  ----------
| The macro references the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETIN            Req      Parameter specified dataset
| &DSETOUT           Req      Parameter specified dataset
| -----------------  -------  -------------------------------------------------
| Global macro variables created: NONE
| Macros called:
|(@) tu_putglobals
|(@) tr_putlocals
|(@) tu_abort
|(@) tu_chknames
|(@) tu_tidyup
|
| Example:
|    %tu_maxvarlen(dsetin  = _ae1,
|                  dsetout = _dsplan );
|
*******************************************************************************/

%macro tu_maxvarlen(
       dsetin  = ,/* Input dataset name */
       dsetout =  /* Output dataset name*/
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

   %let dsetin = %nrbquote(&dsetin);
   %let dsetout = %nrbquote(&dsetout);

   %if &dsetin eq %then
   %do;
      %put %str(RTE)RROR: TU_MAXVARLEN: The parameter DSETIN is required.;
      %let g_abort=1;
   %end;  /* end-if Required parameter DSETIN is not specified.  */

   %if &dsetout eq %then
   %do;
      %put %str(RTE)RROR: TU_MAXVARLEN: The parameter DSETOUT is required.;
      %let g_abort=1;
   %end;  /* end-if Required parameter DSETOUT is not specified.  */

   %if &g_abort eq 1 %then
   %do;
      %tu_abort;
   %end;

   %if &dsetout ne %str() %then
   %do;
     %if %tu_chknames(&dsetout, DATA) ne %then
     %do;
       %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETOUT refers to dataset %nrbquote(%upcase("&dsetout")) which is not a valid dataset name.;
       %let g_abort = 1;
       %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
     %end;
   %end; /* Calling tu_chknames to validate DSETOUT parameter */

   %if &g_abort eq 1 %then
   %do;
      %tu_abort;
   %end;

 /*
 / Check for existing datasets.                                               
 /----------------------------------------------------------------------------*/

   %if %sysfunc(exist(&dsetin)) eq 0 %then
   %do;
      %put %str(RTE)RROR: TU_MAXVARLEN: The dataset DSETIN (&dsetin) does not exist.; 
      %let g_abort=1;
   %end;  /* end-if  Specified dataset DSETIN does not exist  */

   %if &g_abort eq 1 %then
   %do;
      %tu_abort;
   %end;

 /*
 / Check if input dataset name is same as output dataset name                 
 /----------------------------------------------------------------------------*/

   %if %upcase(&dsetin) eq %upcase(&dsetout) %then 
   %do;
      %put %str(RTE)RROR: TU_MAXVARLEN: The input dataset name is same as output dataset name.; 
      %let g_abort=1;

   %end; /** end-if input datasetname same as output dataset name**/

   %if &g_abort eq 1 %then
   %do;
      %tu_abort;
   %end;

 /*
 / Normal processing.
 / Get the dataset.
 / Find the character variable.
 / Find the length of a character variable and store it in dataset
 /----------------------------------------------------------------------------*/

   %local lib mem i prefix; /*lib : library name mem: input dataset name prefix: prefix for temporary dataset*/

   %if %index(&dsetin,.) %then 
   %do;
     %let lib = %scan(%upcase(&dsetin),-2, .);
     %let mem = %scan(%upcase(&dsetin),-1, .);
   %end; /* if parameter dsetin contains both library and dataset name*/

   %else %do;
     %let lib = WORK;
     %let mem = %upcase(&dsetin);
   %end; /* if parameter dsetin contains only dataset name*/

   %let i = 1;
   %let prefix=_maxvarlen;
 
   proc sql noprint;
     create table &prefix._prefinal as select name   /*table with character variable only is created*/
     from dictionary.columns
     where upcase(libname) eq "&lib" and
     upcase(memname) = "&mem" and upcase(type)="CHAR";

     select name into :l_variable separated by ' '   /* macro variable containing all character variable names is created*/
     from &prefix._prefinal;
   quit;

   %do %while(%upcase(%scan(&l_variable,&i, %str( ))) ne );
     %let l_var = %upcase(%scan(&l_variable,&i, %str( ))); /* single character variable name is extracted from l_variable*/

     proc sql noprint; 
       select max(length(&l_var)) into :maxlength from &dsetin;  /* maximum length for a character variable is found*/
     quit;

     %let maxlength = &maxlength;

     data &prefix._prefinal;
       set &prefix._prefinal;
       if upcase(name) = symget('l_var') then mlen = input(symget('maxlength'),8.); /*maximum length is written in the dataset*/
     run;
    
     %let i = %eval(&i + 1);

   %end;

 /*
 / Creating final dataset: DSETOUT
 /----------------------------------------------------------------------------*/
  
   data &dsetout;
     set &prefix._prefinal;
   run;

 /*
 / Deleting temporary datset                                                
 /----------------------------------------------------------------------------*/

   %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

 %mend;
