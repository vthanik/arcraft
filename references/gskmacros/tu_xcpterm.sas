/*******************************************************************************
|
| Macro Name:     tu_xcpterm.sas
|
| Macro Version:  2
|
| SAS Version:    8.2
|
| Created By:     Trevor Welby
|
| Date:           15th December 2004
|
| Macro Purpose:  The macro shall close the current exception report
|
| Macro Design:   Procedure style
|
| Input Parameters: None
|
| Output: None        
|
| Global macro variables created: None
|
| Macros called:
|(@) tu_putglobals
|(@) tu_tidyup
|(@) tu_abort
|
| Example:
|
| %tu_xcpterm
|
|*******************************************************************************
| Change Log
|
| Modified By: Ian Barretto
| Date of Modification: 15th December 2004
| New version/draft number: 01-002
| Modification ID: IB10254.01-002
| Reason For Modification: Change to the macro definition statement to add ()
|                          so that the HARP parser can check-in the macro.
|
|*******************************************************************************
| Change Log
|
| Modified By: Trevor Welby
| Date of Modification: 26th April 2005
| New version/draft number: 01-003
| Modification ID: TQW9753.01-003
| Reason For Modification: Add calls to %tu_tidyup and %tu_abort at the end 
|                          of the macro call
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
|*******************************************************************************
| Change Log
|
| Modified By:  
| Date of Modification: 
| New version/draft number:
| Modification ID: 
| Reason For Modification: 
|
********************************************************************************/
%macro tu_xcpterm ();
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
    
    %tu_putglobals(varsin=g_xcpodsdest);
    
  %end;

  /*    
  / Perform parameter validation
  /------------------------------------------------------------------------------*/
  /* None required */

  /*
  / Perform Normal Processing 
  /------------------------------------------------------------------------------*/
  %local prefix; *[TQW9753.01-003];
  %let prefix=_xcpterm;

  ods &g_xcpodsdest close; /* Close output destination */

  %put %str(RTN)OTE: &sysmacroname.: Global macro variable G_XCPODSDEST (g_xcpodsdest=&g_xcpodsdest) has been deleted;
  %symdel g_xcpodsdest;   /* Remove global macro variable from the symbol table */

  ods listing;  /* Reset default output destination */
  
  /*
  / Tidyup the session TQW9753.01-003
  /------------------------------------------------------------------------------*/
  %tu_tidyup(rmdset=&prefix:
             ,glbmac=NONE
             );
  quit;

  %tu_abort();

%mend tu_xcpterm;

