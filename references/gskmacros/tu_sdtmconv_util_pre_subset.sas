/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_util_pre_subset
|
| Macro Version/Build:  1/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009
|
| Macro Purpose :       Apply a subset clause while the data is still in source
|                       format 
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
| Macros called :
| (@)tu_nobs
| (@)tu_tidyup
| (@)tu_sdtmconv_sys_message
|
| Example:
|
| %tu_sdtmconv_util_pre_subset
|
|*******************************************************************************
| Change Log :
|
| Modified By:             
| Date of Modification:    
| New Version/Build Number:      
| Description for Modification:
| Reason for Modification: 
|
*******************************************************************************/
%macro tu_sdtmconv_util_pre_subset(
);

proc sql noprint;
 create table _pre_subset as
 select vm.si_dset, vm.si_var, vm.instructions,
 substr(instructions,12,index(instructions,';')-13) as subset
 from instructions vm, dictionary.columns dc
 where dc.libname='PRE_SDTM'
   and dc.memname=vm.si_dset
   and dc.name=vm.si_var
   and index(vm.instructions,'pre_subset')>0
   and si_dset in (select basetabname from view_tab_list);
quit; 

/* Count the number of datasets (if any) to process */
%if &sqlobs >=1 %then %do;

 data _pre_subset;
  set _pre_subset;
  num=_n_;
 run; 

 %DO w=1 %TO &sqlobs;

  /* For each iteration - apply the subset clause */
  data _null_ ;set _pre_subset (where=(num=&w));
   call symput('si_dset',trim(si_dset));
   call symput('si_var',trim(si_var));
   call symput('subset',trim(subset));
  run;

  %let _cmd = %str(Applying &si_var &subset to &si_dset );%tu_sdtmconv_sys_message;

  data pre_sdtm.&si_dset;
   set pre_sdtm.&si_dset;
   if &si_var &subset;
  run; 
  
  /* If a subset results in an empty SI dataset then delete it from the library and driver table */
  %if %eval(%tu_nobs(pre_sdtm.&si_dset))=0 %then %do;  
   %let _cmd = %str(%str(RTW)ARNING: TU_SDTMCONV_UTIL_PRE_SUBSET: Application of &si_var &subset to &si_dset resulted in empty dataset);%tu_sdtmconv_sys_message;

   proc datasets library=pre_sdtm memtype=DATA nolist ;
    delete &si_dset;
   run;
   
   proc sql;
    delete from view_tab_list where basetabname="&si_dset";
   quit;
    
  %end;  
  
 %end;
%end;

%if &sysenv=BACK %then %do;  

%tu_tidyup(
 rmdset = _pre_subset:,
 glbmac = none
);
%end;

%mend tu_sdtmconv_util_pre_subset;
