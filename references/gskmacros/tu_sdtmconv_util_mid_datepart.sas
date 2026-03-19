/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_util_mid_datepart
|
| Macro Version/Build:  1/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009
|
| Macro Purpose:        Return the datepart of a ISO8601 datetime field, IF time
|                       present
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
| %tu_sdtmconv_util_mid_datepart
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
%macro tu_sdtmconv_util_mid_datepart(
);

proc sql noprint;
 create table _pst_datepart as
 select distinct compress(vm.domain)||'_'||compress(vm.si_dset) as memname,
        vm.si_dset, vm.domain, vm.suppqual, vm.sdtm_var, 
        vm.instructions, dc.type, vm.si_var
 from instructions vm, 
      dictionary.columns dc
 where dc.libname='MID_SDTM'
   and substr(dc.memname,1,index(dc.memname,"_")-1)=vm.domain
   and dc.name=vm.sdtm_var
   and index(instructions,'sdtm_datepart')>0
   and si_dset in (select basetabname from view_tab_list)
   and compress(vm.domain)||'_'||compress(vm.si_dset) in 
     (select memname from dictionary.tables where libname='MID_SDTM');
quit; 

/* Count the number of datasets (if any) to process */
%if &sqlobs>=1 %then %do;

 data _pst_datepart; 
  set _pst_datepart;
  num=_n_;
 run; 

 %DO w=1 %TO &sqlobs;

  /* For each iteration - apply the instruction */
  data _null_ ;set _pst_datepart (where=(num=&w));
   call symput('memname',trim(memname));
   call symput('sdtm_var',trim(sdtm_var));
  run;
  
  data mid_sdtm.&memname;     
   set mid_sdtm.&memname;
       &sdtm_var=substr(&sdtm_var,1,ifn(index(&sdtm_var,'T')=0,length(&sdtm_var)+1,index(&sdtm_var,'T'))-1);
  run; 
  
 %end;
%end;

%if &sysenv=BACK %then %do;  

%tu_tidyup(
 rmdset = _pst_datepart:,
 glbmac = none
);
%end;

%mend tu_sdtmconv_util_mid_datepart;
