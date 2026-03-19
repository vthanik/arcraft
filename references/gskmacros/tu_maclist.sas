/*
| Macro name:    tu_maclist.sas
|
| Macro version: 2
|
| SAS version:   8.2
|
| Created by:    Alfred Montalvo Jr
|
| Date:          06may2003
|
| Macro purpose: The current macro has two functions:
|                1. Count the number of words in a macro list and create a macro
|                  variable to represent the number of words in the list
|                2. Create a global/local macro variable for each word in the macro list
|
| Macro Design:  Call routine style
|
| Input parameters:
|
|  Name         Description                        default
|
|  string       input string                       no default/blank
|
|  delim        delimeter                          no default/blank
|
|  prefix       macro variable prefix              _maclist_
|
|  cntname      macro variable name for            &prefix.0
|               word count(i.e. number of words)
|
|  scope        specify if global or local macro   global
|               variables are to be created
|-----------------------------------------------------------------------------------
|  Output:
|-----------------------------------------------------------------------------------
|  Global macro variables created:
|
|          Global or local macro variable(s) with values that resolve to the text
|          specified in the STRING parameter. &prefix1 to &prefixn
|-----------------------------------------------------------------------------------
|  Macros called:
|  (@) tu_abort
|  (@) tu_putglobals
|-----------------------------------------------------------------------------------
| Change Log
|
| Modified by: Alfred Montalvo Jr
| Date of modification: 09jul03
| New version number: 1/2
| Modification ID: 01
| Reason for modification: Code was modifed to resolve error issues from UTC. 
|                          Modifications include replacing options= with option= in
|                          macro call to tu_abort. Also added default value to
|                          PREFIX macro parameter and added code provided by Andy
|                          to utilize scan functions default values.
|-----------------------------------------------------------------------------------
| Modified by: Tamsin Corfield
| Date of modification: 10-Jul-03
| New version number: 1/3
| Modification ID: TC01
| Reason for modification: 
|   Amend comments for parameters on macro statement to match Unit Spec.
|   To match Unit Spec, remove code that was setting a value for cntname if cntname 
|     was blank.
|   Remove use of sysmacroname as a prefix to all local macro vars (unnecessary 
|     complexity).
|   Use default values of scan function in ALL appropriate places (if delim is blank).
|-----------------------------------------------------------------------------------
| Modified by:             Yongwei Wang
| Date of modification:    02Apr2008
| New version number:      2/1
| Modification ID:         YW001
| Reason for modification: Based on change request HRT0193
|                          1. Change macro header style (for mfile)                                      
|                          2. Echo macro name and version and local/global macro                                            
|                             variables to the log when g_debug > 0    
|                          3. Replaced %inc tr_putlocal.sas with %put statements
|-----------------------------------------------------------------------------------*/

%macro tu_maclist(
         string    = ,           /*String to be split into individual macro variables*/
         delim     = ,           /*Delimiter*/
         prefix    = _maclist_,  /*Prefix for name of macro variables*/
         cntname   = &prefix.0,  /*Macro variable name for word count*/
         scope     = global      /*Specify global or local macro variable*/
      );

  %local MacroVersion;
  %let MacroVersion = 2;
 
  %if &g_debug GT 0 %then
  %do;
  
      %put ************************************************************;
      %put * Macro name: &sysmacroname,  Macro Version: &macroVersion ;
      %put ************************************************************;
    
      %put * &sysmacroname has been called with the following parameters: ;
      %put * ;
      %put _local_;
      %put * ;
      %put ************************************************************;
      
      %tu_putglobals()
      
  %end;
 
  /*  verify STRING parameter is not missing   */
  
  
  %if %bquote(&string) eq %then 
  %do;
          %put %str(RTE)RROR: TU_MACLIST: - Macro parameter STRING (string=&string) is missing;
          %put %str(RTE)RROR: TU_MACLIST: calling tu_abort to stop executing program;
              
          %tu_abort(option=force);
  %end;
  
  /*  verify PREFIX parameter is not missing   */
  
  
  %if %bquote(&prefix) eq %then 
  %do;
          %put %str(RTE)RROR: TU_MACLIST: - Macro parameter PREFIX (prefix=&prefix) is missing;
          %put %str(RTE)RROR: TU_MACLIST: calling tu_abort to stop executing program;
              
          %tu_abort(option=force);
  %end;
  
  /*  verify CNTNAME parameter is not missing   */
  
  
  %if %bquote(&cntname) eq %then 
  %do;
          %put %str(RTE)RROR: TU_MACLIST: - Macro parameter CNTNAME (cntname=&cntname) is missing;
          %put %str(RTE)RROR: TU_MACLIST: calling tu_abort to stop executing program;
              
          %tu_abort(option=force);
  %end;
  


   %local Lcount Lword;  /*TC01*/

   /*
   / define global or local macro vars below
   / For LOCAL don't use %LOCAL, because we don't want the variables local
   / to this macro but the calling macro.
   /-----------------------------------------------------------------------*/

   %let scope = %qupcase(&scope);
   %if &scope EQ GLOBAL %then %global &cntname;

   /*
   / use qscan function to parse words from string parameter
   /-------------------------------------------------------------*/

   %let Lcount=1;  /*TC01*/
   
   %if %str(&delim) ne %str() %then
   %do;  /* Use delim supplied by caller */
     %let Lword=%qscan(&string,&Lcount,%str(&delim));  /*TC01*/
   %end; /* Use delim supplied by caller */
   %else
   %do;  /* Use default delims of scan function */
     %let Lword=%qscan(&string,&Lcount);  /*TC01*/
   %end; /* Use default delims of scan function */

   %do %while ( %bquote(&&Lword) NE);  /*TC01*/

      %if &scope EQ GLOBAL %then %global &prefix.&Lcount;  /*TC01*/

      %let &prefix.&Lcount = &Lword;  /*TC01*/

      %let Lcount = %eval(&Lcount+1);  /*TC01*/

      %if %str(&delim) ne %str() %then  /*TC01*/
      %do;  /* Use delim supplied by caller */
         %let Lword  = %qscan(&string,&Lcount,%str(&delim));  /*TC01*/
      %end; /* Use delim supplied by caller */
      %else
      %do;  /* Use default delims of scan function */
         %let Lword  = %qscan(&string,&Lcount);  /*TC01*/
      %end; /* Use default delims of scan function */

   %end;

   %let &cntname = %eval(&Lcount-1);  /*TC01*/

%mend tu_maclist;
