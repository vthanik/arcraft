/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_util_mid_add_nu
|
| Macro Version/Build:  1/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009
|
| Macro Purpose:        Add normal units from SDTM mapping definitions to --TEST
|                       findings data 
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
| (@)tu_tidyup
|
| Example:
|
| %tu_sdtmconv_util_mid_add_nu
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
%macro tu_sdtmconv_util_mid_add_nu(
);

proc sql noprint;
 create table _pst_add_units as
 select vm.domain, vm.suppqual, vm.sdtm_var, vm.si_var, vm.instructions, 
 substr(instructions,16,index(instructions,';')-18) as unit
 from instructions vm, dictionary.columns dc, sdtm_dom sd
 where dc.libname='MID_SDTM'
   and sd.si_dset=substr(dc.memname,index(dc.memname,'_')+1,index(dc.memname,'_')-length(dc.memname) )
   and sd.domain=vm.domain
   and dc.memname=compress(vm.domain||'_'||vm.si_dset)
   and dc.name=vm.sdtm_var
   and vm.domain="&dom"
   and index(vm.instructions,'add_norm_unit')>=1;
quit; 

/* Count the number of datasets (if any) to process */
%if &sqlobs>=1 %then %do;

 data _pst_add_units;
  set _pst_add_units;
  num=_n_;
 run;

 %DO w=1 %TO &sqlobs;

  /* For each iteration - define the normal unit field and values into the domain */  
  data _null_ ;set _pst_add_units (where=(num=&w));
  call symput('domain',trim(domain));
  call symput('sdtm_var',trim(sdtm_var));
  call symput('unit',trim(unit));
  call symput('suppqual',trim(suppqual));
  call symput('si_var',trim(si_var));
  call symput('unit_var',trim(sdtm_var)||'U');
  run;

  %if &suppqual=NO %then %do;
   data mid_sdtm.&domain._&dset;
    attrib &unit_var length=$50;
    set mid_sdtm.&domain._&dset;
    if &domain.TESTCD="&si_var" then &unit_var ="&unit";
   run; 
  %end;
  
 %end;
%end;

%if &sysenv=BACK %then %do;  

%tu_tidyup(
rmdset = _pst_add_units:,
glbmac = none
);
%end;

%mend tu_sdtmconv_util_mid_add_nu;
