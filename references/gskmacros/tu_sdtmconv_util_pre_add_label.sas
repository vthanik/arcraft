/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_util_pre_add_label
|
| Macro Version/Build:  2/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009
|
| Macro Purpose:        Apply a defined label for the variable specified. 
|
|                       This is often to rename a variable label so that when converted to findings 
|                       normalised format, the correct entry is placed in the --TEST field which is 
|                       the destination of the label.
|
|                       A label must be present for each item for the proc
|                       transpose steps to work correctly later
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
| (@)tu_nobs
| (@)tu_tidyup
|
| Example:
|
| %tu_sdtmconv_util_pre_add_label
|
|*******************************************************************************
| Change Log:
|
| Modified By:                   Bruce Chambers   
| Date of Modification:          10May2013
|
| New Version/Build Number:      2/1 
| Reference:                     BJC001
| Description for Modification:  enable re-labelling of a renamed date that maps to a test/result (not--DTC)
| Reason for Modification:       flexible conversion
|
*******************************************************************************/
%macro tu_sdtmconv_util_pre_add_label(
);

/* BJC001: add another query to get any renames of date fields included */
proc sql noprint;
 create table add_missing_labels as
 (select vm.si_dset, vm.si_var, vm.instructions,dc.length, dc.type
 from instructions vm, dictionary.columns dc
 where dc.libname='PRE_SDTM'
   and dc.memname=vm.si_dset
   and dc.name=vm.si_var
   and index(instructions,'add_label')>0
   and si_dset in (select basetabname from view_tab_list)
  UNION 
 select vm.si_dset, trim(dmd.sub_name)||'DTC' as si_var, vm.instructions,dc.length, dc.type
 from instructions vm, dictionary.columns dc, date_meta_driver dmd
 where dc.libname='PRE_SDTM'
   and dc.memname=vm.si_dset
   and dc.memname=dmd.memname
   and dc.name=trim(dmd.sub_name)||'DTC'
   and vm.si_var=dmd.name
   and index(instructions,'add_label')>0
   and si_dset in (select basetabname from view_tab_list));
quit; 

* Derive the label from the string, regardless of how many instructions there may be**;
data add_missing_labels; 
 attrib type length=$9 format=$9.;
 set add_missing_labels;
 endpos=index(instructions,';');
 label=substr(instructions,12,(endpos)-14);
 if type='char' then type=compress('char('||length||')');
 if type='num' then type='numeric';
 num=_n_;
run;

** Count the number of datasets (if any) to process **;
%if %eval(%tu_nobs(add_missing_labels))>=1 %then %do;  

 %DO w=1 %TO %eval(%tu_nobs(add_missing_labels));

  ** For each iteration - apply the variable label **;  
  data _null_ ;set add_missing_labels (where=(num=&w));
  call symput('memname',trim(si_dset));
  call symput('name',trim(si_var));
  call symput('type',trim(type));
  call symput('label',trim(label));
  run;

  proc sql noprint;
   alter table pre_sdtm.&memname add &name &type label="%str(&label)";
  quit; 
  
 %end;
%end;

%if &sysenv=BACK %then %do;  

%tu_tidyup(
rmdset = add_missing_labels:,
glbmac = none
);
%end;

%mend tu_sdtmconv_util_pre_add_label;
