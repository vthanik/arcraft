/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_util_pre_upcase
|
| Macro Version/Build:  1/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009
|
| Macro Purpose :       Upper case item contents while the data is still in
|                       source format 
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
| %tu_sdtmconv_util_pre_upcase
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
%macro tu_sdtmconv_util_pre_upcase(
);

proc sql noprint;
 create table _pre_upcase as
 select vm.si_dset, vm.si_var, vm.instructions
 from instructions vm, dictionary.columns dc
 where dc.libname='PRE_SDTM'
   and dc.memname=vm.si_dset
   and dc.name=vm.si_var
   and index(vm.instructions,'upcase')>0
   and si_dset in (select basetabname from view_tab_list);
quit; 

/* Count the number of datasets (if any) to process */
%if &sqlobs>=1 %then %do;

 data _pre_upcase ;
  set _pre_upcase ;
  num=_n_;
 run; 

 %DO w=1 %TO &sqlobs;

  /* For each iteration - apply the upcase function */
  data _null_ ;set _pre_upcase (where=(num=&w));
   call symput('memname',trim(si_dset));
   call symput('name',trim(si_var));
  run;

  data pre_sdtm.&memname;
   set pre_sdtm.&memname;
   &name=upcase(&name);
  run; 
  
 %end;
%end;

%if &sysenv=BACK %then %do;  

%tu_tidyup(
 rmdset = _pre_upcase:,
 glbmac = none
);

%end;

%mend tu_sdtmconv_util_pre_upcase;
