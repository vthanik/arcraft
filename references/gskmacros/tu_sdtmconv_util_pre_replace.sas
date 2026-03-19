/******************************************************************************* 
|
| Macro Name: tu_sdtmconv_util_pre_replace
|
| Macro Version/Build: 3/1
|
| SAS Version: SAS 9.1.3
|
| Created By: Bruce Chambers
|
| Date:            12-Aug-2009
|
| Macro Purpose: Replace the contents of one source item with the contents of another
|                For example: BLRSOTH will replace the contents of BLREAS
|                BLREAS in this case would be 'Other', replacing it with BLRSOTH means
|                the actual text (e.g. SAE) will appear instead of other.
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
| (@) tu_tidyup
|
| Example:
|         %tu_sdtmconv_util_pre_replace;
|
|******************************************************************************* 
| Change Log 
|
| Modified By:                  Bruce Chambers
| Date of Modification:         18Jan2011
| New Version/Build Number:     2/1
| Reference:                    bjc001
| Description for Modification: To apply Option 1 as default from 4.1.2.7.2 of SDTM 312 IG. 
| Reason for Modification:      When we replace content of a variable the original
|                               content should be placed in the --STRESC field if
|                               its a findings domain.
|
| Modified By:                  Bruce Chambers
| Date of Modification:         25Apr2011
| New Version/Build Number:     3/1
| Reference:                    bjc002
| Description for Modification: To apply Option 1 as default from 4.1.2.7.2 of SDTM 312 IG. 
| Reason for Modification:      When we replace content of a variable the original
|                               content should be placed in the --STRESC field if
|                               its a findings domain. Add code to check its not a 
|                               SUPPQUAL variable
|
| Modified By:                  Bruce Chambers
| Date of Modification:         16Jul2012
| New Version/Build Number:     3/1
| Reference:                    bjc003
| Description for Modification: To apply Option 1 as default from 4.1.2.7.2 of SDTM 312 IG. 
| Reason for Modification:      When we replace content of a variable the original
|                               content should be placed in the --STRESC field if
|                               its a findings domain. Add code to check its not a 
|                               SUPPQUAL variable in a more specific way than before
|                               and also use dom_ref (not domain) macro var for FA domains.
|
| Modified By:                  Bruce Chambers
| Date of Modification:         07Oct2012
| New Version/Build Number:     3/1
| Reference:                    bjc004
| Description for Modification: Code was adding duplicate rows to varmap
| Reason for Modification:      ensure integrity of varmap driver data
|
********************************************************************************/ 

%macro tu_sdtmconv_util_pre_replace(
);

/* BJC001 - add domain and dom_type to query */
/* BJC002 : add SUPPQUAL to query */
/* BJC003: add dom_ref to query*/

proc sql noprint;
 create table _pre_replace as
 select vm.si_dset, vm.si_var, vm.instructions, vm.domain, dr.dom_type, vm.suppqual,
 substr(instructions,13,index(instructions,';')-14) as replace, dr.domref as dom_ref
 from instructions vm, dictionary.columns dc, domain_ref dr
 where dc.libname='PRE_SDTM'
   and dr.domain=vm.domain
   and dc.memname=vm.si_dset
   and dc.name=vm.si_var
   and index(vm.instructions,'pre_replace')>0
   and si_dset in (select basetabname from view_tab_list);
quit; 
 
/* Count the number of instructions (if any) to process */
%if &sqlobs>=1 %then %do;

 data _pre_replace;
  set _pre_replace;
  num=_n_;
 run;

 %DO w=1 %TO &sqlobs;

  /* BJC001 - add domain and dom_type to macro vars */
  /* BJC002 : add SUPPQUAL to macro vars */
  /* BJC003: add dom_ref to macro vars */
  /* For each iteration - apply the replace */
  data _null_ ;set _pre_replace (where=(num=&w));
   call symput('si_dset',trim(si_dset));
   call symput('si_var',trim(si_var));
   call symput('replace',trim(replace));
   call symput('domain',trim(domain));
   call symput('dom_ref',trim(dom_ref));
   call symput('origin',trim(origin));
   call symput('suppqual',trim(suppqual));
   call symput('dom_type',trim(dom_type));
  run;

  data pre_sdtm.&si_dset;
   attrib &replace length=$200;
   set pre_sdtm.&si_dset;
   
   /* BJC001: add code to process findings replace statements as per option 1 4.1.2.7.2 of SDTM 312 IG */
   /* BJC002 : add SUPPQUAL to conditional check  */
   /* BJC003 : make SUPPQUAL conditional check more specific */

   if &si_var^='' then do; 
    %if %index(%upcase(&dom_type),FINDINGS)>=1 and %substr(suppqual,1,3)^="YES" %then %do;
     &dom_ref.STRESC=upcase(&replace);
    %end;
    &replace=&si_var;
   end; 
  run; 

  /* BJC004: check that the replace specification is on a dropped, not a mapped variable 
             eCRF Traceability programs will remap it to the destination */
  %let Dreplace_present=0;
  proc sql noprint;
    select count(*) into :Dreplace_present
      from varmap
     where si_dset="&si_dset" and si_var="&si_var" and trim(origin)='DROPPED';
  quit;  
  %if &Dreplace_present=0 %then %do;
  %let _cmd = %str(%str(RTW)ARNING: PRE_REPLACE: Replace variable &si_var in &si_dset must be specified in VARMAP as
   ORIGIN=DROPPED);%tu_sdtmconv_sys_message;
  %end;
  
  /* BJC001: populate new row into varmap with ADDED=Y flag */
  %if %index(%upcase(&dom_type),FINDINGS)>=1 %then %do;

   proc sql noprint;
    select distinct origin into :origin 
      from varmap 
     where si_var="&replace" and si_dset="&si_dset";
   quit;

   /* BJC004: check there is not already a row existing e.g. for LIMAGING there are >1 replace statement */
   %let replace_present=0;
    proc sql noprint;
     select count(*) into :replace_present
       from varmap
      where si_dset="&si_dset" and si_var="&dom_ref.STRESC";
    quit;  
   
    %if &replace_present=0 %then %do;
   
     /* BJC003: for sdtm_var and si_var update domain with dom_ref for FA domains */
     data _pre_replace_varmap_add;      
        si_dset="&si_dset"; 
        si_var="&dom_ref.STRESC";
        origin="&origin";
        domain="&domain";
        sdtm_var="&dom_ref.STRESC";
        suppqual='NO';
        added='Y';
       run; 
        
       data varmap;
        set varmap 
            _pre_replace_varmap_add;
     run;
    %end;
  %end;
  
 %end;
%end;

%if &sysenv=BACK %then %do;  

%tu_tidyup(
 rmdset = _pre_replace:,
 glbmac = none
);
%end;

%mend tu_sdtmconv_util_pre_replace;
