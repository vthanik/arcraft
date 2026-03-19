/******************************************************************************* 
|
| Macro Name: tu_sdtmconv_sys_error_check
|
| Macro Version/Build: 1
|
| SAS Version: SAS 9.1.3
|
| Created By: Bruce Chambers
|
| Date:            12-Aug-2009
|
| Macro Purpose: To check the &syscc system value after each major step and stop
|                processing if an unhandled system ERROR or WARNING has been encountered
|
|                If running interactively stop the system instead of continuing with NOREPLACE
|                option set.
|
| Macro Design: Procedure
|
| Input Parameters:
|
|   None
|
| Output:
|
|   None
|
| Global macro variables created:
|
|   None
|
| Macros called:
|
| (@)tu_sdtmconv_sys_message
|
| Example:
|         %tu_sdtmconv_sys_error_check;
|
|******************************************************************************* 
| Change Log 
|
| Modified By: 
| Date of Modification: 
| New Version/Build Number:
| Description for Modification:
| Reason for Modification: 
|
********************************************************************************/ 

%macro tu_sdtmconv_sys_error_check(
);

/* Abort the run if there is a problem so far */
%if &syscc ge 2 or &g_abort>0 %then %do;
  %put SYSCC= &syscc;
  %let _cmd = %str(Problem encountered with run - aborting );  %tu_sdtmconv_sys_message;
  
  %if &sysenv = FORE %then %do;
   data _null_;
    abort; run;
  %end;
  %else %do;
   data _null_;
    abort return 8;
   run;
  %end;
  
%end;

%mend tu_sdtmconv_sys_error_check;
