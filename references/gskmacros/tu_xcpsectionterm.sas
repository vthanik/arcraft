/*******************************************************************************
|
| Macro Name:     tu_xcpsectionterm.sas
|
| Macro Version:  2
|
| SAS Version:    8.2
|
| Created By:     Trevor Welby
|
| Date:           10th December 2004
|
| Macro Purpose:  This macro shall end the current active 
|                 section in the exception report that was 
|                 initiated by the %tu_xcpsectioninit
|                 macro.
|
|                 A summary report shall be written at the
|                 end of each section detailing the exception 
|                 types and number.
|
| Macro Design:   Statement style
|
| Input Parameters:
|
| NAME            DESCRIPTION                                   DEFAULT
|
| END             Specifies the name of a variable that         [blank]
|                 shall indicate the last row of the merge.
|                 It shall be the macro caller's 
|                 responsibility to ensure that the value 
|                 of the variable shall be zero for all 
|                 rows of the merge process except the last; 
|                 for the last row the value of the variable
|                 shall be 1.
|
|                 Typically this variable would also be 
|                 specified as the END=<variable> on the 
|                 MERGE statement in the DATA step in 
|                 which %tu_xcpsectionterm is called
|
|                 Valid Values:
|
|                 Name of a variable that exists in the 
|                 DATA step's PDV
|
| Output:        The macro creates a summary report at the 
|                end of each section.
|
| Global macro variables created: none
|
| Macros called:
|(@) tu_putglobals
|
| Example:
|
| %tu_xcpsectionterm(END=SectionEnd)
|
|*******************************************************************************
| Change Log
|
| Modified By: Trevor Welby
| Date of Modification: 10th December 2004
| New version/draft number: 01-002
| Modification ID: TQW9753:01-002
| Reason For Modification: Add further comments to clarify normal processing and
|                          correct incorrect variable name to __xcperorCount.
|
|*******************************************************************************
| Change Log
|
| Modified By: Trevor Welby
| Date of Modification: 20th January 2005
| New version/draft number: 01-003
| Modification ID: TQW9753:01-003
| Reason For Modification: Added a message if exceptions are identified
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

%macro tu_xcpsectionterm(end=    /* Variable to specify end of dataset marker  */ 
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
  / verify END keyword parameter is not missing
  /------------------------------------------------------------------------------*/
  %if %bquote(&end) eq %then 
  %do;
    %put %str(RTE)RROR: &sysmacroname.: Macro keyword parameter END (end=&end) is missing;
    %let g_abort = 1;    
  %end; 

  /*
  / Perform Normal Processing 
  /------------------------------------------------------------------------------*/

  /*
  / TQW9753:01-002
  / 1) If one or more ERR!!OR messages were written to the exception report for this
  /    section the macro shall set the value of the global macro variable G_ABORT=1
  /
  / 2) A summary record shall be presented at the end of each section of the 
  /    exception report.  This will document the number of ERR!!ORS, WARN!!INGS
  /    and NOTE!!S (if any).  A summary report will be produced even when no 
  /    exceptions have been identified 
  /------------------------------------------------------------------------------*/
  if &end = 1 then
  do; /* BEGIN: Execute for the last record in the datastep */

    drop __xcpstring;

    /* Build the string for the summary record */
    __xcpstring = "Summary: " !! "erro" !! "rs=" !! compress(putn(__xcperorcount,'BEST.')) !! ', '
                !! "war" !! "nings="!! compress(putn(__xcpWrningcount,'BEST.')) !! ', '
                !! "not" !! "es="!! compress(putn(__xcpNtecount,'BEST.')) 
                ;
    
    __xcpmsg  = __xcpstring;
    __xcptype = "SUMMARY";

    /* Output the summary record to the exception report */
    put _ods_;

    /* Check if an ERR!!OR has been issued during the execution of the
    /  datastep and issue an error message and set g_abort=1 if true.  
		/  The value of __xcperorCount is set by the call to tu_xcpput macro
    /------------------------------------------------------------------------------*/
    if __xcperorCount gt 0 then
    do; /* BEGIN: Err!!or message issued during datastep execution */ 
		  file log; *[TQW9753:01-003];
			put 'RTE' 'RROR: ' "&sysmacroname.:" ' Exception report Err' 'or message(s) were issued during datastep execution';
      call symput('g_abort','1');  
    end;  /* END: Err!!or message issued during datastep execution */

  end; /* END: Execute for the last record in the datastep */

%mend tu_xcpsectionterm;
