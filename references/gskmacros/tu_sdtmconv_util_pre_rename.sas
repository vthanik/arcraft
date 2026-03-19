/******************************************************************************* 
|
| Macro Name: tu_sdtmconv_util_pre_rename
|
| Macro Version/Build: 3/1
|
| SAS Version: SAS 9.1.3
|
| Created By: Bruce Chambers
|
| Date:            12-Aug-2009
|
| Macro Purpose: Rename an item while the data is still in source format. This is
|                usually for times that are not the same name prefix as their partner 
|                date e.g. LBACTTM we would rename to LBTM so it marries with LBDT.
|                Also used to rename source variables that become findings --TESTCDs 
|                e.g. rename HEART to become PULSE (controlled terminology)
|
| Macro Design:  Procedure
|
| Input Parameters:
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
| (@) tu_chkvarsexist
| (@) tu_tidyup
| (@) tu_sdtmconv_sys_message
|
| Example:
|         %tu_sdtmconv_util_pre_rename;
|
|******************************************************************************* 
| Change Log 
|
| Modified By:                  Bruce Chambers
| Date of Modification:         10May2010
| New Version/Build Number:     2/1
| Reference:                    BJC001
| Description for Modification: To store the original variable name when a rename is
|                               performed 
| Reason for Modification:      To facilitate traceability for later define.xml generation
|
| Modified By:                  Bruce Chambers
| Date of Modification:         10Oct2012
| New Version/Build Number:     3/1
| Reference:                    BJC002
| Description for Modification: Upgrade RTNOTE to RTWARNING
| Reason for Modification:      Note easily missed and expected data not provided
********************************************************************************/ 

%macro tu_sdtmconv_util_pre_rename(
);

proc sql noprint;
 create table _pre_rename as
 select vm.si_dset, vm.si_var, vm.instructions,
 substr(instructions,8,index(instructions,';')-9) as rename
 from instructions vm, dictionary.columns dc
 where dc.libname='PRE_SDTM'
   and dc.memname=vm.si_dset
   and dc.name=vm.si_var
   and index(instructions,'rename')>0
   and si_dset in (select basetabname from view_tab_list);
quit; 

/* Count the number of datasets (if any) to process */
%if &sqlobs>=1 %then %do;

data _pre_rename;
 set _pre_rename;
 num=_n_;
run;

 %DO w=1 %to &sqlobs;

  /* For each iteration - apply the rename */
  data _null_ ;set _pre_rename (where=(num=&w));
   call symput('si_dset',trim(si_dset));
   call symput('rename',trim(rename));
   call symput('si_var',trim(si_var));
  run;

   %if %length(%tu_chkvarsexist(pre_sdtm.&si_dset,&rename))=0 %then %do;
      /* BJC002: upgrade note to warning */
     %let _cmd = %str(%str(RTW)ARNING: Default &si_dset rename of &si_var to &rename not applied as &rename exists);%tu_sdtmconv_sys_message;
   %end;

   %if %length(%tu_chkvarsexist(pre_sdtm.&si_dset,&rename))>=1 %then %do;
     %let _cmd = %str(Rename of &si_var to &rename in &si_dset applied);%tu_sdtmconv_sys_message;

     data pre_sdtm.&si_dset;
      set pre_sdtm.&si_dset(rename=(&si_var=&rename));
     run; 
   %end; 
      
   /* Update the varmap file with the renamed variable - but only if a row is not already present
   /  e.g. AEACTR we rename above if it is present (without AEACTTRT being present ) to AEACTTRT. 
   /  But we wont add a row for AEACTTRT to varmap as it is already there. 
   /  However BIACTTM is renamed to BITM (to pair with BIDT to make the ISO8601 combined field)
   /  and BITM wont already be present as it is not in DSM. 
   / Also update instructions file so that any util macros run AFTER this point will reference
   / the new details for the variable */
   
   %let rename_present=0;
   proc sql noprint;
    select count(*) into :rename_present
      from varmap
     where si_dset="&si_dset" and si_var="&rename";
   quit;  
   
   /* BJC001 - amend the steps below to populate ORIG_SI_VAR */

   %if &rename_present=0 %then %do;
    data varmap; 
     attrib orig_si_var length=$8;
     set varmap;
     if si_dset="&si_dset" and si_var="&si_var" then do;
      si_var="&rename";
      orig_si_var="&si_var";
     end; 
    run; 
   
    data instructions; 
     set instructions;
     if si_dset="&si_dset" and si_var="&si_var" then si_var="&rename";
    run; 
      
   %end;
   
   %if &rename_present^=0 %then %do;
    data varmap; 
     attrib orig_si_var length=$8;
     set varmap;
      if si_dset="&si_dset" and si_var="&rename" then do;
       orig_si_var="&si_var";
      end; 
     run;
   %end;

 %end;
%end;



%if &sysenv=BACK %then %do; 

%tu_tidyup(
 rmdset = _pre_rename:,
 glbmac = none
);

%end;

%mend tu_sdtmconv_util_pre_rename;
