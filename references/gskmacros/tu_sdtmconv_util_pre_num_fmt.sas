/******************************************************************************* 
|
| Macro Name: tu_sdtmconv_util_pre_num_fmt
|
| Macro Version/Build: 1
|
| SAS Version: SAS 9.1.3
|
| Created By: Bruce Chambers
|
| Date:            12-Aug-2009
|
| Macro Purpose: Apply a specific numeric format to a source numeric variable.
|                the format in DSM is the max possible, and for some studies 
|                it may be appropriate to format the data with a different 
|                format in order that it displays how it was actually collected.
|
|                Examples found in RESP PFT data where DSM format may be 8.3 but
|                the data may have been collected as 8.1 or 8.2 and should be 
|                processed as such
|
| Macro Design:  Procedure
|
| Input Parameters:
|
| None
|
| Output:
|
|
| Global macro variables created:
|
|
| Macros called:
| (@) tu_tidyup
|
| Example:
|         %tu_sdtmconv_util_pre_num_fmt;
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

%macro tu_sdtmconv_util_pre_num_fmt(
);

proc sql noprint;
 create table _pre_num_fmt as
 select vm.si_dset, vm.si_var, vm.instructions, 
 substr(instructions,13,index(instructions,';')-14) as format
 from instructions vm, dictionary.columns dc
 where dc.libname='PRE_SDTM'
   and dc.memname=vm.si_dset
   and dc.name=vm.si_var
   and index(vm.instructions,'pre_num_fmt')>0
   and si_dset in (select basetabname from view_tab_list);
quit; 

/* Count the number of datasets (if any) to process */
%if &sqlobs>=1 %then %do;

 data _pre_num_fmt;
  set _pre_num_fmt;
  num=_n_;
 run;

 %DO w=1 %TO &sqlobs;

  /* For each iteration - apply the format */  
  data _null_ ;set _pre_num_fmt (where=(num=&w));
   call symput('si_dset',trim(si_dset));
   call symput('si_var',trim(si_var));
   call symput('format',trim(format));
  run;

  data pre_sdtm.&si_dset;
   set pre_sdtm.&si_dset;
   format &si_var &format;
  run; 
  
 %end;
%end;

%if &sysenv=BACK %then %do;  

%tu_tidyup(
 rmdset = _pre_num_fmt:,
 glbmac = none
);
%end;

%mend tu_sdtmconv_util_pre_num_fmt;
