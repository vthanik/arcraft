/******************************************************************************* 
|
| Macro Name:      tu_quotelst.sas
|
| Macro Version:   2
|
| SAS Version:     8.2
|
| Created By:      Stephen J. Griffiths
|
| Date:            13-Jun-2003
|
| Macro Purpose:   This macro is designed to add quotes around each item in a list
|                  It can consist of individual items or a previously defined macro variable 
|                  containing values
|
| Macro Design:    FUNCTION STYLE MACRO
|                  Macro value dump to log file
|                  Parameter validation 
|                  Assign default  delimit character if necessary
|                  Define and initialise local macro variables
|                  Loop through each word in the list...
|                   Adding each quoted value in turn             
| 
| Input Parameters:
|
| NAME              DESCRIPTION                         DEFAULT 
| list              List of words to be quoted          
| delimit           Word delimiter                      %str( ) 
|
| Output: Expanded input list, with quotes placed around each item
|
|
| Global macro variables created:  None
|
|
| Macros called:
| (@) tu_putglobals
|
| Examples:
| %let labtest = WBC RBC NA K CL;           
| 
| where labtest in  ( %tu_quotelst(&labtest) ) ;
|
| where labtest in  ( %tu_quotelst(wbc rbc na k cl) ) ;
|
|******************************************************************************* 
| Change Log 
|
| Modified By:               Stephen Griffiths 
| Date of Modification:      23 June 2003 
| New version number:        01.000.002
| Modification ID:           
| Reason For Modification:   Amendments following source code review
|
|*******************************************************************************
| Change Log
|
| Modified By:               Stephen Griffiths
| Date of Modification:      04 July 2003
| New version number:        01.000.003
| Modification ID:
| Reason For Modification:   Amendments following testing            
|
|*******************************************************************************
| Change Log
|
| Modified By:               Stephen Griffiths
| Date of Modification:      08 July 2003
| New version number:        01.000.004
| Modification ID:
| Reason For Modification:   Additional amendments following new source code review
|
|*******************************************************************************
| Modified by:             Yongwei Wang
| Date of modification:    02Apr2008
| New version number:      2/1
| Modification ID:         YW001
| Reason for modification: Based on change request HRT0193
|                          1. Echo macro name and version and local/global macro                                            
|                             variables to the log when g_debug > 0    
********************************************************************************/ 

%macro tu_quotelst (
  list       ,         /* List of words                                        */
  delimit  = %str( )   /* Word delimiter                                       */
  );

  /*
  / Identification of Macros to log          
  /----------------------------------------------------------------------------*/
  %local MacroVersion;
  %let MacroVersion=2;
  
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

  /*
  / Parameter validation
  / List parameter can not be missing
  /----------------------------------------------------------------------------*/
  %if %quote(&list)eq %then 
  %do;
    %put %str(RTERR)%str(OR):TU_QUOTELST: Variable list is empty;
    %let g_abort=1; 
  %end;

  /*
  / Delimiter must be one character
  /----------------------------------------------------------------------------*/
  %if %length(&delimit) gt 1 %then 
  %do;
    %put %str(RTERR)%str(OR):TU_QUOTELST: Delimiter has more than one character;
    %let g_abort=1;
  %end;

  /*
  / Assign default delimit character                                         
  /----------------------------------------------------------------------------*/
  %if %length(&delimit)eq 0 %then 
  %do;
    %put %str(RTERR)%str(OR):TU_QUOTELST: Delimiter can not be null;
    %let g_abort=1;
  %end;

  /*
  / Define and initialise local macro variables
  /----------------------------------------------------------------------------*/
  %local i word wordlist indelim;
  %let i = 1;
  %let indelim = %str( );
  %let wordlist=;
  %let word = %qscan(&list, &i, &indelim);

  /*
  / Loop through each word in the list...
  /----------------------------------------------------------------------------*/
  %do %while(%length(&word));

    /*
    / Adding each item in turn with quotes to master wordlist
    /--------------------------------------------------------------------------*/
    %let wordlist=&wordlist."&word"; 

    %let i=%eval(&i+1);
    %let word=%qscan(&list, &i, &indelim);
    %if %length(&word) %then %let wordlist=&wordlist.&delimit;
 
  %end;

  &wordlist

%mend tu_quotelst;

