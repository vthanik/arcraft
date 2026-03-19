/******************************************************************************* 
|
| Macro Name: tu_sdtmconv_pre_debug_subset
|
| Macro Version/Build: 1
|
| SAS Version: SAS 9.1.3
|
| Created By: Bruce Chambers
|
| Date:            12-Aug-2009
|
| Macro Purpose: To speed up testing and development users can select a subset of
|                subjects using any valid (where=(xxxxx)) clause that is applied once 
|                the datasets have been copied from the source.
|
|                If the subset results in an empty dataset then delete that record 
|                from the main driver table so the system will not process it further.
|
| Macro Design:  Procedure
|
| Input Parameters:  (optional) &subset_clause
|
| NAME              DESCRIPTION                         DEFAULT 
|
| Output:
|
|
| Global macro variables created:
|
|
| Macros called:
| (@) tu_nobs
| (@) tu_tidyup
| (@) tu_sdtmconv_sys_message
|
| Example:
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

%macro tu_sdtmconv_pre_debug_subset(
);
  
proc sql noprint;
 create table _pre_subset_data as 
 (select memname
 from dictionary.tables
 where libname='PRE_SDTM');
quit;

** Count the number of datasets (if any) to process **;
%if &sqlobs >=1 %then %do;

 data _pre_subset_data; 
  set _pre_subset_data;
  num=_n_;
 run;

 /* Add log file spacer */
 %let _cmd = %str();%tu_sdtmconv_sys_message;
 %DO w=1 %TO &sqlobs;

  /* For each iteration - output the daatset name and SEQ item name */
  data _null_ ;set _pre_subset_data (where=(num=&w));
   call symput('memname',trim(memname));   
  run;

  /* Run generic step to subset on user-defined clause */
  data pre_sdtm.&memname;
   set pre_sdtm.&memname(&subset_clause) ; 
  run;  

  /* If a subset results in an empty SI dataset then delete it from the PRE_SDTM library and system driver table */
  %if %eval(%tu_nobs(pre_sdtm.&memname))=0 %then %do;

   %let _cmd = %str(%str(RTW)ARNING: TU_SDTMCONV_PRE_DEBUG_SUBSET: Application of &subset_clause to &memname resulted in empty dataset);%tu_sdtmconv_sys_message;

   proc datasets library=pre_sdtm memtype=DATA nolist ;
    delete &memname;
   run;
   
   data view_tab_list; 
    set view_tab_list(where=(basetabname^="&memname"));
   run;
   
  %end;
 %end;
%end;

%if &sysenv=BACK %then %do;  

%tu_tidyup(
 rmdset = _pre_subset:,
 glbmac = none
);
%end;

** Add log file spacer **;
%let _cmd = %str();%tu_sdtmconv_sys_message;
  
%mend tu_sdtmconv_pre_debug_subset;
