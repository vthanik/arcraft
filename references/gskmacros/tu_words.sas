/* 
/
/ Macro Name: tu_words
/
/ Macro Version:  2
/
/ SAS Version: 8
/
/ Created By: John Henry King
/
/ Date: 27May2003
/
/ Macro Purpose: A macro to count the number of words in a list.
/
/ Macro Design: Function Style.
/
/ Input Parameters:
/
/ NAME              DESCRIPTION                         DEFAULT
/
/ STRING            String to count number of words     No default
/ DELIM             Delimiter(s)                        %str( )
/
/
/ Output: Returns the number of &DELIM delimited words in &STRING.
/
/ Global macro variables created: NONE
/
/
/ Macros called: NONE
/
/ Example:
/    %local i;
/    %do i = 1 %to %tu_words(&VARSIN);
/       Processing for each variable
/    %end;
/
/
/*******************************************************************************
/ Change Log
/
/ Modified By: John Henry King
/ Date of Modification: 23Jun2003
/ New version number: 01.002
/ Modification ID: 01.002
/ Reason For Modification: Three small changes to meet requirements for SCR.
/
/-------------------------------------------------------------------------------
/ Modified By: John Henry King
/ Date of Modification: 07JUL2003
/ New version number: 01.003
/ Modification ID: 01.003
/ Reason For Modification: Made DELIM a keyword parameter and coded a check
/                          for DELIM must not be blank.
/-------------------------------------------------------------------------------
/ Modified By: John Henry King
/ Date of Modification: 08JUL2003
/ New version number: 01.004
/ Modification ID: 01.004
/ Reason For Modification: Add call to %tu_putglobals                      
/-------------------------------------------------------------------------------
/ Modified by:             Yongwei Wang
/ Date of modification:    02Apr2008
/ New version number:      2/1
/ Modification ID:         YW001
/ Reason for modification: Based on change request HRT0193
/                          1. Echo macro name and version and local/global macro                                            
/                             variables to the log when g_debug > 0    
/-------------------------------------------------------------------------------
/ Modified By:
/ Date of Modification:
/ New version number:
/ Modification ID:
/ Reason For Modification:
/
********************************************************************************/
%macro tu_words(
         string,             /* List of words */
         delim  = %str( )    /* Delimiter(s)  */
      );


   %local MacroVersion;
   %let MacroVersion = 2;
   
   %if &g_debug GT 0 %then
   %do; 
   
      %put *******************************************************************;
      %put * Macro name: &sysmacroname,  Macro Version: &macroVersion ;
      %put *******************************************************************;
   
      %put * &sysmacroname has been called with the following parameters: ;
      %put * ;
      %put _local_;
      %put * ;
      %put *******************************************************************;
      
      %tu_putglobals()
   
   %end;

   %local
      i              /* internal counter   */
      w              /* variable for words */
      uniquechar     /* a character unique to &string */
      uniquechar0    /* position of unique character in list */
      rx             /* return code for RXPARSE */
      times          /* change repeats for RXCHANGE */
      pattern        /* value of pattern */
      ;

   %if %length(&delim) EQ 0 %then %do;
      %put %str(RTERR)OR: &sysmacroname: DELIM must not be blank.;
      %put RTNOTE: &sysmacroname: G_ABORT has been set to 1.;
      %let i = -1;
      %let g_abort = 1;
      %goto exit;
      %end;

   /*
   / If &string is NULL then just return 0
   /-------------------------------------------*/
   %let i = 0;
   %if %nrbquote(&string) EQ %then %goto exit;
   /*
   / Otherwise
   / 1) if &delim is the space character use COMPBL and COMPRESS and count the
   /    number of spaces
   / 2) if &delim is something else
   /    a) normalize the delimiters by changing them all to a single character
   /       that is unique to the string.
   /    b) count the number of delimiters and determine the number of words
   /------------------------------------------------------------------------------*/
   %else
   %do;
      /*
      / BLANK delimiter
      /-------------------------*/
      %if %bquote(&delim) EQ %str( ) %then
      %do;
         %let i = %eval(1 + %length(%sysfunc(compbl(&string)))-%length(%sysfunc(compress(&string))));
      %end;
      /*
      / OTHER delimiter(s)
      /-------------------------*/
      %else
      %do;
         /*
         / Find a character that is UNIQUE to &string
         /---------------------------------------------------*/
         %let string      = &delim.&string.&delim;
         %let uniquechar  = abcdefghijklmnopqrstuvwxyz;
         %let uniquechar  = %qupcase(&uniquechar.)&uniquechar.0123456789%str(~!#$%^&*%(%)-={}[]/\:;<,>.?/)%sysfunc(byte(255));
         %let uniquechar0 = %sysfunc(verify(&uniquechar,%bquote(&string),%bquote(&delim)));

         %if &uniquechar0 GT 0 %then %let uniquechar  = %substr(&uniquechar,&uniquechar0,1);
         /*
         / If no unique character was found, seems unlikely,
         / print an error and return 0
         /----------------------------------------------------*/
         %else
         %do;
            %let i = 0;
            %put %str(RTE)RROR: &sysmacroname: String is too complex;
            %let g_abort = 1;
            %goto exit;
         %end;

         /*
         / Replace all occurrences of delimiters with the unique character
         /----------------------------------------------------------------*/
         %let string  = %sysfunc(translate(%bquote(&string),%sysfunc(repeat(&uniquechar,%length(&delim)-1)),%bquote(&delim)));
         %let times   = 999;
         /*
         / Change all multiple occurrences of the unique character with
         / a single occurrence of unique character
         /----------------------------------------------------------------*/
         %let pattern = %str(%'&uniquechar.%'+ TO %'&uniquechar.%');
         %let rx      = %sysfunc(rxparse(%unquote(&pattern)));
         %syscall rxchange(rx,times,string,string);
         %syscall rxfree(rx);
         /*
         / Count the words by counting the delimiters
         /----------------------------------------------*/
         %let i       = %eval(%length(&string)-%length(%sysfunc(compress(&string,&uniquechar)))-1);
      %end;
   %end;
 %EXIT:
   &i   
%mend tu_words;

