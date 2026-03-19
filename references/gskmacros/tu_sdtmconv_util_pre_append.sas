/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_util_pre_append
|
| Macro Version/Build:  1/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009
|
| Macro Purpose :       Append contents of specified item to the item it is 
|                       linked to
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
| (@)tu_tidyup
|
| Example:
|
| %tu_sdtmconv_util_pre_append
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
%macro tu_sdtmconv_util_pre_append(
);

proc sql noprint;
 create table _pre_append as
 select vm.si_dset, vm.si_var, vm.instructions, 
 substr(instructions,12,index(instructions,';')-13) as append
 from instructions vm, dictionary.columns dc
 where dc.libname='PRE_SDTM'
   and dc.memname=vm.si_dset
   and dc.name=vm.si_var
   and index(vm.instructions,'pre_append')>0
   and si_dset in (select basetabname from view_tab_list);
quit; 

/* Count the number of datasets (if any) to process */
%if &sqlobs>=1 %then %do;

 data _pre_append;
  set _pre_append;
  num=_n_;
 run;

 %DO w=1 %TO &sqlobs;

  /* For each iteration - apply the append */
  data _null_ ;set _pre_append (where=(num=&w));
   call symput('si_dset',trim(si_dset));
   call symput('si_var',trim(si_var));
   call symput('append',trim(append));
  run;

  data pre_sdtm.&si_dset;
   attrib &append length=$280; 
   set pre_sdtm.&si_dset;
   if &si_var^='' then &append=trim(&append)||' : '||trim(&si_var);
  run; 
  
 %end;
%end;

%if &sysenv=BACK %then %do;  

%tu_tidyup(
rmdset = _pre_append:,
glbmac = none
);
%end;

%mend tu_sdtmconv_util_pre_append;
