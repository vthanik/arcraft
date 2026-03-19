/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_sys_message
|
| Macro Version/Build:  2/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009
|
| Macro Purpose:        Echo details of run progress to screen for interactive
|                       runs to the or log for batch runs.
|
| Macro Design:         Procedure
|
| Input Parameters:
| 
| NAME                DESCRIPTION                                  DEFAULT           
|
|
|
|
|
| Output:
|
|
| Global macro variables created:
|
|
| Macros called:
|   none
|
| Example:
|
| %tu_sdtmconv_sys_message
|
|*******************************************************************************
| Change Log :
|
| Modified By:                  Lee Seymour/Bruce Chambers 
| Date of Modification:         30 July 2010 
| New Version/Build Number    : 2/1
| Reference                   : LJS001
| Description for Modification: To keep the log brief when run in HARP app
| Reason for Modification     : To keep the log brief when run in HARP app
|
*******************************************************************************/
%macro tu_sdtmconv_sys_message(
);

   %let _max_len_break = 250;  /* SAS SYSTEM command cannot handle strings longer than this */
   %let _max_len_display = 72; /* For string exceeding MAX break size above break into a displayable size */

   %put &_cmd;  /* Output to the log first before echo string to user */
/*
/  Check if the output string is longer than SYSTEM can handle, if so then output smaller
/  string size so SAS Warning is not generated in the log.
/********************************************************************************************/

/* LJS001 - only echo to screen if run from arwork */

%if %index(%upcase(&g_sdtmdata),ARWORK) gt 0 or %index(%upcase(&g_sdtmdata),DMENV) gt 0 %then
%do;


   %if %length(&_cmd) > &_max_len_break %then %do;
      %do %until(%length(&_cmd) <= &_max_len_display);
         %if %length(&_cmd) >= &_max_len_display %then %do;
            %let rc = %sysfunc(system(echo %substr(&_cmd,1,&_max_len_display)));
            %let _cmd = %substr(&_cmd,&_max_len_display+1);
         grep "system(echo" * %end;
      %end;  /* END DO UNTIL */
      %let rc = %sysfunc(system(echo &_cmd));
    %end;  /* END IF length(&_cmd) > &_max_len_break THEN */
   %else %do; /* ELSE the _cmd string is less than _MAX_LEN_BREAK */
      %let rc = %sysfunc(system(echo &_cmd));
    %end;


%end;

%mend tu_sdtmconv_sys_message;



