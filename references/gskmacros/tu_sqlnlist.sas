/******************************************************************************* 
|
| Macro Name:      tu_sqlnlist.sas
|
| Macro Version:   2.0
|
| SAS Version:     8.2
|
| Created By:      Stephen J. Griffiths
|
| Date:            12-Jun-2003
|
| Macro Purpose:   This macro is designed to facilitate the use of macro variables within SAS PROC SQL.
|                  It will provide the following functionality:
|                   Compose a variable list from an input macro list for use within a select statement
|                   Create a variable match list for use within the merge statement. 
|
| Macro Design:    FUNCTION SYTLE MACRO
|                  Macro value dump to log file
|                  Parameter validation 
|                  Add period to alias if given to allow standard call regardless of existence
|                  Define and initialise local macro variables
|                  Loop through each word in the list...
|                   Building the join clause if alias2 defined...
|                   and placing necessary commas for initial select clause     
| 
| Input Parameters:
|
| NAME              DESCRIPTION                         DEFAULT 
| varlist           List of variables to be included in 
|                   PROC SQL statements
| alias             Table alias for first table
| alias2            Table alias for 2nd table.
|
| Output: Code to perform PROC SQL select / merge
|
|
| Global macro variables created:  None
|
|
| Macros called:
| (@) tu_putglobals
|
| Examples:
| proc sql;
|   create table _xxx_ as select %sqlnlist(&variable_list)
|   from original;
| quit;
|
| proc sql;
|   create table _xxx_ as select %sqlnlist(&variable_list,x), y.var
|   from original x, secondary y
|   where %sqlnlist(&variable_list,x,y);
| quit;
|
|******************************************************************************* 
| Change Log 
|
| Modified By:              Stephen Griffiths
| Date of Modification:     03 Jul 03 
| New version number:       001.000.002
| Modification ID: 
| Reason For Modification:  Findings from testing incorporated
|
| Modified by:             Yongwei Wang
| Date of modification:    02Apr2008
| New version number:      2/1
| Modification ID:         YW001
| Reason for modification: Based on change request HRT0193
|                          1. Echo macro name and version and local/global macro                                            
|                             variables to the log when g_debug > 0    
|                          2. Remove a %put _local_; statement
********************************************************************************/ 

%macro tu_sqlnlist (
  varlist  ,    /* List of variables to be included in PROC SQL statements     */
  alias    ,    /* Table alias for first table                                 */
  alias2   ,    /* Table alias for 2nd table. Only for use during SQL merging  */
  );

  /*
  / Identification of Macros to log          
  /----------------------------------------------------------------------------*/
  %local MacroVersion;
  %let MacroVersion=2.0;
  
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
    
    %tu_putglobals
  
  %end;

  /*
  / Parameter validation
  / VARLIST is not allowed to be missing
  /----------------------------------------------------------------------------*/
  %if %length(&varlist) eq 0 %then
  %do;
    %put %str(RTERR)%str(OR):TU_SQLNLIST: Varlist parameter is missing;
    %let g_abort=1;
  %end;

  /*
  / If ALIAS2 is not missing, then check ALIAS is also not missing
  /----------------------------------------------------------------------------*/
  %if %length(&alias2) ne 0 and %length(&alias) eq 0 %then 
  %do;
    %put %str(RTERR)%str(OR):TU_SQLNLIST: Alias2 parameter is not null, yet alias parameter is null;
    %let g_abort=1;
  %end;

  /*
  / Define and initialise local macro variables
  /----------------------------------------------------------------------------*/
  %local i var list ;
  %let i = 1;
  %let var = %scan(&varlist, &i, %str( ));

  /*
  / Add period to alias if given to allow standard call regardless of existence
  / Add period to alias2 if present       
  /----------------------------------------------------------------------------*/
  %if %length(&alias) ne 0 %then %let alias = &alias%str(.);
  %if %length(&alias2) ne 0 %then %let alias2 = &alias2%str(.);

  /*
  / Loop through each word in the list...
  /----------------------------------------------------------------------------*/
  %do %while(%length(&var));

    /*
    / Building the join clause if alias2 defined... 
    /--------------------------------------------------------------------------*/
    %if %index(&alias2,%str(.)) gt 0 %then 
    %do;
      %if &i = 1 %then %let list = &alias.&var %quote(=) &alias2.&var;
      %else %let list = &list and &alias.&var %quote(=) &alias2.&var;
    %end;

    /*
    / and placing necessary commas for initial select clause
    /--------------------------------------------------------------------------*/
    %else 
    %do;
      %if &i eq 1 %then %let list = &alias.&var;
      %else %let list = &list, &alias.&var;
    %end;
    %let i = %eval(&i + 1);
    %let var = %scan(&varlist,&i,%str( ));
  %end;

  &list

%mend tu_sqlnlist;

