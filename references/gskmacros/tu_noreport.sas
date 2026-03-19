/*----------------------------------------------------------------------------+
 | Macro Name    : tu_noreport
 |
 | Macro Version : 1
 |
 | SAS version   : SAS v8.2
 |
 | Created By    : Neeraj Malhotra
 |
 | Date          : 10-Jul-03
 |
 | Macro Purpose : This macro shall create a report whose body text consists
 |                 of localised version of MESSAGEKEY variable
 |
 | Macro Design  : Procedure Style
 |
 | Input Parameters :
 |
 | NAME           DESCRIPTION                                             DEFAULT
 |
 | MESSAGEKEY    Specifies the localisation key of the message             NODATA
 |               to be written to the output page
 |
 |
 | Output: The unit shall write the "report" to the standard listing destination
 |
 |
 | Global macro variables created: None
 |
 |
 | Macros called :
 |
 | (@) tr_putlocals
 | (@) tu_abort
 | (@) tu_putglobals
 |
 | Example: %tu_noreport;
 |
 |
 | **************************************************************************
 | Change Log :
 |
 | Modified By : Neeraj Malhotra
 | Date of Modification : 11 July 2003
 | New Version Number : 1/2
 | Modification ID : 01
 | Reason For Modification : Changes from SCR
 |
 | Change Log :
 |
 | Modified By : Neeraj Malhotra
 | Date of Modification : 14 July 2003
 | New Version Number : 1/3
 | Modification ID : nm02
 | Reason For Modification : Changes from Failed Testing
 |
 | Change Log :
 |
 | Modified By : Neeraj Malhotra
 | Date of Modification : 16 July 2003
 | New Version Number : 1/4
 | Modification ID : nm03
 | Reason For Modification : Changes from Failed Testing- added parameter
 |                           validation for g_ls
 +----------------------------------------------------------------------------*/


%macro tu_noreport (
     messagekey =  NODATA /*Key of message to be written*/
        );


  %local MacroVersion;
  %let MacroVersion = 1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_ls);


  /*
  / PARAMETER VALIDATION
  /
  / CHECKING THAT MESSAGEKEY IS NOT BLANK
  /-------------------------------------------*/


   %if %upcase(&messagekey) eq %then
   %do;
      %put %str(RTE)RROR TU_NOREPORT : MESSAGEKEY is blank. This macro will abort;
      %let g_abort=1;
      %tu_abort(option=force);
   %end;

   /*CHECKING THAT G_LS IS NOT BLANK*/

   %if &g_ls eq %then
   %do;
      %put %str(RTE)RROR TU_NOREPORT : G_LS is blank. This macro will abort;
      %let g_abort=1;
      %tu_abort(option=force);
   %end;


   /*Using a Null data step to put a message to the output destination*/

   data _null_;
     file print footnote;
     do i=1 to 10;
       put ' ';
     end;
     msg=put("&messagekey",$local.);
     put msg $&g_ls.. -c;
   run;

   %tu_tidyup(rmdset=_none_, glbmac=none);

%mend tu_noreport;
