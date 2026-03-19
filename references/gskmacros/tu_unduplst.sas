/*******************************************************************************
|
| Macro Name:      tu_unduplst
|
| Macro Version:   3 
|
| SAS Version:     8.2
|
| Created By:      David Ward
|
| Date:            06-June-2003
|
| Macro Purpose:   This unit shall be a function macro that accepts as input a
|                  list of words and resolves to the same list of words but with
|                  any duplicates removed.
|
| Macro Design:    Function style
|
| Input Parameters:
|
| NAME              DESCRIPTION                         DEFAULT
|
| LISTIN            The list of words to be used in     No default
|                   the creation of a unique list of
|                   words.
|                   Required positional parameter
|
| Output:
|                   This function macro resolves to one of the following:
|                   1. A unique list of words contained in LISTIN, if no errors
|                      captured during parameter or other processing.
|                   2. The value -1, if errors are captured captured during
|                      parameter or other processing.
|
| Global macro variables created: None
|
|
| Macros called:
|  (@)tu_putglobals
|
| Example:
|
| %tu_unduplst(Aa bb cc aa bb aaa);
|
| Will return: AA BB CC AAA
|
|*******************************************************************************
| Change Log
|
| Modified By: Lee Seymour
| Date of Modification: 07-Jul-03
| New version number: 1/2 
| Modification ID: LS01
| Reason For Modification:  Error handling added when listin is blank 
|
|
| Modified By: Lee Seymour
| Date of Modification: 08-Jul-03
| New version number: 1/3 
| Modification ID: LS01
| Reason For Modification:  %let added to g_abort statement
|
| Modified By: Lee Seymour
| Date of Modification: 10-Jul-03
| New version number: 1/4 
| Modification ID: LS01
| Reason For Modification:  %index changed to %sysfunc(%indexw(
|
| Modified By: Yongwei Wang
| Date of Modification: 8-Jan-04
| New version number: 2/1 
| Modification ID: YW01
| Reason For Modification: 1. When the length of macro parameter value for &listin 
|     is greater than 262 characters, a SAS warning is written to the log 
|     indcating that the quoted string is greater than 262 characters. This is 
|     due to the inappropraite use of quoted strings.
|     2. The return value is not -1 while error is reported.
|
| Modified by:             Yongwei Wang
| Date of modification:    02Apr2008
| New version number:      3/1
| Modification ID:         YW001
| Reason for modification: Based on change request HRT0193
|                          1. Echo macro name and version and local/global macro                                            
|                             variables to the log when g_debug > 0    
********************************************************************************/

%MACRO tu_unduplst (
                  listin /* List of words to be used in the creation of a unique list of words.*/
                 ) ;


  /*
  / Echo the macro name and version number to the log. Also echo the parameter
  / values and values of global macro variables used by this macro.
  /----------------------------------------------------------------------------*/

  %local MacroVersion;
  %let MacroVersion = 3;

  %if &g_debug GT 0 %then
  %do;  
  
    %put ************************************************************;
    %put * Macro name: &sysmacroname,  Macro Version: &macroVersion ;
    %put ************************************************************;
   
    %put * ;
    %put _local_;
    %put * ;
    %put ************************************************************;
   
    %tu_putglobals()
    
  %end;

  /*
  / Declare local macro variables that are needed in parameter validation.
  /----------------------------------------------------------------------------*/

  %local listout ;


  /*
  / Parameter validation
  / - Uppercase LISTIN
  / - Check LISTIN does not contain single or double quotes
  /   or commas
  /----------------------------------------------------------------------------*/

  %let listin = %qupcase(&listin) ;



  %if &listin eq %then     
  %do ;
    %put %str(RTE)RROR: TU_UNDUPLST: List of words: &listin is blank. tu_unduplst will abort ;
    %let listout = -1 ;
    %let g_abort = 1 ;   /* LS01 */
  %end;

  %if %index(%str(&listin), %str(,)) %then     /* YW01: removed the double quote */
  %do ;
    %put %str(RTE)RROR: TU_UNDUPLST: List of words: &listin contains comma(s). tu_unduplst will abort ;
    %let listout = -1 ;
    %let g_abort = 1;
  %end ;

  %else %if %index(%nrbquote(&listin), %str(%')) %then     /* YW01: changed first %str to %nrbquote */ 
  %do ;
    %put %str(RTE)RROR: TU_UNDUPLST: List of words: &listin contains single quote(s). tu_unduplst will abort ;
    %let listout = -1 ;
    %let g_abort = 1;
  %end ;

  %else %if %index(%str(&listin), %str(%")) %then
  %do ;
    %put %str(RTE)RROR: TU_UNDUPLST: List of words: &listin contains double quote(s). tu_unduplst will abort ;
    %let listout = -1 ;
    %let g_abort = 1;
  %end ;

  %else
  %do ; /* listin contains no quotes or commas (ie. continue with normal processing) */

    %if %EVAL(&g_debug) GT 0 %then
      %put %str(RTD)EBUG: TU_UNDUPLST: Parameters passed validation, so continue to normal processing ;

    /*
    / Normal Processing
    / - Take each word in the input string LISTIN in sequence
    / - If it is not already in the output string LISTOUT then
    /   add it
    / - Return the output string LISTOUT
    /
    / Note that  LISTOUT has already been declared as a local macro variable,
    / just prior to parameter validation. The %local statement below has not
    / been combined with the %local statement just prior to parameter validation
    / because these variables are only required if parameter validation has
    / passed, and the subsequent normal processing code is executed.
    /--------------------------------------------------------------------------*/

    %local word i;
    %let i = 1;
    %let word = %qscan(&listin,&i,%str( ));

    %do %while(&word NE);

       %if not %sysfunc(indexw(&listout,&word)) %then
       %do;
          %let listout = &listout &word;
       %end;

       %let i = %eval(&i + 1);
       %let word = %qscan(&listin,&i,%str( ));

    %end; /* %do %while(&word NE) */

    %put %str(RTN)OTE: TU_UNDUPLST: Returning: &listout;

  %end ; /* end of normal processing */
  
  &listout /* YW01: Moved from the %end above */

%MEND tu_unduplst ;

