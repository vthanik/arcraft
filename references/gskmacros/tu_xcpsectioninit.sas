/*******************************************************************************
|
| Macro Name:     tu_xcpsectioninit.sas
|
| Macro Version:  2
|
| SAS Version:    8.2
|
| Created By:     Trevor Welby
|
| Date:           9th December 2004
|
| Macro Purpose:  This macro shall begin a new section of the Exception Report
|
| Macro Design:   Statement style
|
| Input Parameters:
|
| NAME            DESCRIPTION                                   DEFAULT
|
| HEADER          Optionally specifies text to be used as a     [blank]
|                 title paragraph for the new section.
|
| TBLPATH         Specifies the name of the ODS template        xcprpt.tmplate
|                 that shall be created for subsequent use in
|                 writing to the Exception Report file
|                 (by %tu_xcpput)
|
| Output:         none
|
| Global macro variables created: none
|
| Macros called:
|(@) tu_putglobals
|
| Example:
|
| %tu_xcpsectioninit(header=Section_Header)
|
|*******************************************************************************
| Change Log
|
| Modified By: Trevor Welby
| Date of Modification: 25th January 2005
| New version/draft number: 01-002
| Modification ID: TQW9753.01-002
| Reason For Modification: Increase the length of variable __xcpmsg from 100
|                          to 256 bytes. This is to avoid truncation of the
|                          exception report message(s)
|
|*******************************************************************************
| Change Log
|
| Modified By: Trevor Welby
| Date of Modification: 25th April 2005
| New version/draft number: 02-001
| Modification ID: TQW9753.02-001
| Reason For Modification: Change the definition of the TBLPATH parameter.
|                          It previously defined the name of the template path.  
|                          It now defines the name of the template 
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

%macro tu_xcpsectioninit(header=                   /* Section title */
                        ,tblpath=xcprpt.tmplate    /* Name of ODS template */
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
  / verify TBLPATH parameter is not missing
  /------------------------------------------------------------------------------*/
  %if %bquote(&tblpath) eq %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: Macro parameter TBLPATH (tblpath=&tblpath) is missing;
    %let g_abort = 1;
  %end;

  /*
  / Perform Normal Processing
  /------------------------------------------------------------------------------*/

   %if %length(&header) ne 0 %then
   %do;
     title2 "&header";
   %end;
   %else %do;
     title2 "";
   %end;

  /*
  / Re-route output using a report template
  /------------------------------------------------------------------------------*/
  file print ods=(template="&tblpath");

  /*
  / Define report variables
  /------------------------------------------------------------------------------*/
  attrib __xcptype length=$12  label='Exception type'
         __xcpmsg  length=$256 label='Exception message'  /* [TQW9753.01-002] */
         ;

  drop __xcptype __xcpmsg;

  /*
  / Create temporary variables as defined below:
  /
  / xcpErorFlag     : This variable indicates if an %str(e)rror condition
  /                   occurred during the iteration of the entire
  /                   datastep.  This value will be used to set the
  /                   value of &g_abort macro parameter to 1 if true.
  /                   Valid values:  0 (no %str(e)rrors) ,
  /                                  1 (%str(e)rror(s) identified
  /
  / xcpErorCount    : This variable holds the number of %str(e)rror messages
  /                   that were issued to the exception report during
  /                   the iteration of the datastep.
  /
  / xcpWrningCount  : This variable holds the number of %str(w)arning messages
  /                   that were issued to the exception during the
  /                   iteration of the datastep.
  /
  / xcpNteCount     : This variable holds the number of %str(not)e messages
  /                   that were issued to the exception during the
  /                   iteration of the datastep.
  /------------------------------------------------------------------------------*/
  retain __xcpErorFlag __xcpErorCount __xcpWrningCount __xcpNteCount 0;
  drop   __xcpErorFlag __xcpErorCount __xcpWrningCount __xcpNteCount  ;

%mend tu_xcpsectioninit;
