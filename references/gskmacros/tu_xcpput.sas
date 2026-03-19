/*******************************************************************************
|
| Macro Name:     tu_xcpput.sas
|
| Macro Version:  2
|
| SAS Version:    8.2
|
| Created By:     Trevor Welby
|
| Date:           9th December 2004
|
| Macro Purpose:  This macro shall put record(s) to the exception report
|
| Macro Design:   Statement style
|
| Input Parameters:
|
| NAME            DESCRIPTION                                    DEFAULT
|
| TEXT            Specifies the text of the message to be        none
| (positional)    written to the active section of the active 
|                 Exception Report.  The text shall be enclosed
|                 in quotes. It is the callers responsibility 
|                 to create an exception message that uniquely
|                 identifies the record. e.g. invid subjid 
|                 visitnum
|
| TYPE            Optionally specifies the type of message.      none
| (positional)    if %str(ERR)OR is specified, %tu_xcpsectionterm
|                 will issue an abort at the end of the 
|                 DATA step.
|
|                 Valid values: %str(NOT)E, %str(WAR)NING, %str(ERR)OR
|
| Output:         Exception report output record(s)
|
| Global macro variables created:
|
| Macros called:
|(@) tu_putglobals
|
| Example:
|
| %tu_xcpput(%str(RECORD ID: Orphaned Record),ERROR)
|
|*******************************************************************************
| Change Log
|
| Modified by:             Yongwei Wang
| Date of modification:    02Apr2008
| New version number:      2/1
| Modification ID:         YW001
| Reason for modification: Based on change request HRT0193
|                          1. Echo macro name and version and local/global macro                                            
|                             variables to the log when g_debug > 0    
|                          2. Replaced %inc tr_putlocal.sas with %put statements
|
| Modified By:
| Date of Modification:
| New version/draft number:
| Modification ID:
| Reason For Modification:
|
********************************************************************************/

%macro tu_xcpput(text         /* Exception message         */ 
                ,type         /* Type of exception message */
                 );

  /*
  / Echo values of parameters and global macro variables to the log.
  /------------------------------------------------------------------------------*/
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
    
    %tu_putglobals();
    
  %end;

  /*    
  / Perform parameter validation
  /------------------------------------------------------------------------------*/

  /*    
  / verify TYPE positional parameter is not missing
  /------------------------------------------------------------------------------*/
  %if %bquote(&text) eq %then 
  %do;
    %put %str(RTE)RROR: &sysmacroname.: Macro positional parameter TEXT (text=&text) is missing;
    %let g_abort = 1;    
  %end; 

  /*    
  / verify TYPE positional parameter is not missing or has valid values
  /------------------------------------------------------------------------------*/
  %if %bquote(&type) eq %then 
  %do;
    %put %str(RTE)RROR: &sysmacroname.: Macro parameter TYPE (type=&type) is missing;
    %let g_abort = 1;    
  %end; 
  %else %if %bquote(%upcase(&type)) eq %str(ERRO)R %then 
    %do;  /* Value OK */
    %end; /* Value OK */
  %else %if %bquote(%upcase(&type)) eq %str(WAR)NING %then 
    %do;  /* Value OK */
    %end; /* Value OK */
  %else %if %bquote(%upcase(&type)) eq %str(NOT)E %then 
    %do;  /* Value OK */
    %end; /* Value OK */
  %else 
    %do;  /* Invalid value */
    %put %str(RTE)RROR: &sysmacroname.: Macro parameter TYPE (type=&type) is invalid, valid values are: ERROR, WARNING and NOTE;
    %let g_abort = 1;
    %end; /* Invalid value */   

  /*
  / Perform Normal Processing 
  /------------------------------------------------------------------------------*/

  /*    
  / Populate the variables: __xcpmsg, __xcptype respectively
  /------------------------------------------------------------------------------*/
  __xcpmsg  =  &text ;
  __xcptype = upcase("&type");

  /*
  / For each value of __XCPTYPE set the corresponding flag variable and increment
  / the count respectively.  For example :  
  /
  /      When __XCPTYPE equals %str(ERR)OR then set the value of _xcpErorFLAG to 1
  /      and increment by 1 the value of __xcpErorCOUNT
  /
  /      When __XCPTYPE equals WARNING then increment by 1 the value of 
  /      __xcpWrnINGCOUNT
  /
  /      When __XCPTYPE equals NOTE then increment by 1 the value of 
  /      __xcpNteCOUNT
  /
  /      Write out the message text and type to the reconciliation report 
  / 
  /------------------------------------------------------------------------------*/

  select (__xcptype);
    when ("ERRO"!!"R") do;
      __xcpErorFlag  = 1;
      __xcpErorCount + 1;
	    put _ods_;
    end;
    when ("WAR"!!"NING") do;
      __xcpWrningCount + 1;
	    put _ods_;
    end;
    when ("NOT"!!"E") do;
      __xcpNteCount + 1;
	    put _ods_;
    end;
  end;

%mend tu_xcpput;
