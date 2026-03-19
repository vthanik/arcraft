/******************************************************************************* 
|
| Macro Name: tu_sdtmconv_util_pre_hardcode
|
| Macro Version/Build: 5/1
|
| SAS Version: SAS 9.1.3
|
| Created By: Bruce Chambers
|
| Date:            12-Aug-2009
|
| Macro Purpose: Add any default values to all rows while the data is still in source 
|                format. This macro will only assign the hardcode if the item it is 
|                attached to in the mapping is present, so hardcodes should be added to
|                required items. They may need to be added to more than one item if there
|                required items differ across real life use of a dataset.
|                
| Macro Design: Procedure
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
| (@) tu_nobs
| (@) tu_sdtmconv_sys_message
|
| Example:
|
|******************************************************************************* 
| Change Log 
|
| Modified By:                  Bruce Chambers
| Date of Modification:         29Apr2010
| New Version/Build Number:     2/1
| Reference:                    BJC001
| Description for Modification: systematic error in clause: 
|                               where origin in ('CRF','DERIVED') needs to be corrected to 
|                               where origin ^='DROPPED'
| Reason for Modification:      systematic error in where clause impacting 3 macros
|
| Modified By:                  Bruce Chambers
| Date of Modification:         31Aug2010
| New Version/Build Number:     3/1
| Reference:                    BJC002
| Description for Modification: enable alternative origin values to be defined for hardcodes
| Reason for Modification:      Ensure correct define.xml production
|
| Modified By:                  Bruce Chambers
| Date of Modification:         15Nov2010
| New Version/Build Number:     4/1
| Reference:                    BJC003
| Description for Modification: correction to enable alternative origin values to be defined for hardcodes
| Reason for Modification:      Ensure correct define.xml production
|
| Modified By: 			Deepak Sriramulu
| Date of Modification: 	10January2011
| New Version/Build Number:	5 Build 1
| Reference:                    DSS001
| Description for Modification: Report any ORIGIN=TBD or invalid (in varmap_mrg) at the end of each run so that the programmers will go 
|                               back and add/update hardcode origin definitions
| Reason for Modification: 	Ensure define.xml metadata is complete   
|
********************************************************************************/ 

%macro tu_sdtmconv_util_pre_hardcode(
);

/* BJC001: amend origin where clause in this query */

/* The SQL below pulls the entire string into HARDCODE and the first word into HCITEM. 
/  For many strings the first word will be the name of the item to be hardcoded. 
/  For those strings with additional ALL or ORIGIN definitions the HCITEM gets re-updated later */

proc sql noprint;
 create table _pre_add_hc as
 select vm.si_dset, vm.si_var, vm.instructions, dc.type, vm.domain, vm.num,
 substr(instructions,14,index(instructions,';')-15) as hardcode,
 substr(substr(instructions,14,index(instructions,';')-15),1,index(substr(instructions,14,index(instructions,';')-15),'=')-1) as hcitem
 from instructions vm, dictionary.columns dc
 where dc.libname='PRE_SDTM'
   and dc.memname=vm.si_dset
   and dc.name=vm.si_var
   and index(vm.instructions,'pre_hardcode')>0
   and si_dset in (select basetabname from view_tab_list)
   and (vm.origin ^='DROPPED' or vm.instructions^='')
    and trim(si_dset)||trim(si_var) in 
      (select trim(memname)||trim(name) 
         from dictionary.columns 
        where libname='PRE_SDTM')
  order by vm.num;
quit;  

/* Count the number of instructions (if any) to process */
%if &sqlobs>=1 %then %do;

 data _pre_add_hc;
  set _pre_add_hc;
  /* BJC002: define new ORIGIN variable */
  length ORIGIN $8;

  if substr(hcitem,1,3)='ALL' then do;
   ALL='ALL';
   hcitem=substr(hcitem,5,length(hcitem)-4);
   hardcode=substr(hardcode,5,length(hardcode)-4);
  end;
    
  /* BJC002: add step to process alternative */
  /* BJC003: correction to hcitem derivation */
  if index(upcase(hcitem),'ORIGIN') >=1 then do;   
   origin=substr(hardcode,9,index(upcase(hardcode),',')-10);
   hardcode=substr(hardcode,index(upcase(hardcode),',')+1,length(hardcode)-index(upcase(hardcode),','));
   hcitem=substr(hardcode,1,index(upcase(hardcode),'=')-1);
  end;  
  
 run;

 /* check if a hardcode column is already present in the data, if so then dont perform the hardcode */
 
 proc sql noprint;
  create table _pre_add_hc_present
   as select si_dset, hcitem, 'present' as type from _pre_add_hc
   where all='' and trim(si_dset)||trim(hcitem) in
   (select trim(memname)||trim(name) from dictionary.columns
    where libname='PRE_SDTM');

  create table _pre_add_hc_alias 
     as select si_dset, hcitem, 'alias' as type from _pre_add_hc
     where all='' and trim(si_dset)||trim(hcitem) in
     (select trim(si_dset)||trim(sdtm_var)
       from varmap where trim(si_dset)||trim(si_var) in
       (select trim(memname)||trim(name) from dictionary.columns
       where libname='PRE_SDTM')); 

  delete from _pre_add_hc
  where trim(si_dset)||trim(hcitem) in
   (select trim(si_dset)||trim(hcitem) from _pre_add_hc_present)
   or trim(si_dset)||trim(hcitem) in
   (select trim(si_dset)||trim(hcitem) from _pre_add_hc_alias );
 quit;
 
 data _pre_add_hc_prevent;
  set _pre_add_hc_present
      _pre_add_hc_alias;
 run;    
 
 %if %eval(%tu_nobs(_pre_add_hc_prevent)) >=1 %then %do;
  proc sql noprint;
   select si_dset, hcitem, type
     into :si_dset1 - :si_dset%left(%eval(%tu_nobs(_pre_add_hc_prevent))),
          :hcitem1 - :hcitem%left(%eval(%tu_nobs(_pre_add_hc_prevent))),
          :type1 - :type%left(%eval(%tu_nobs(_pre_add_hc_prevent)))
     from _pre_add_hc_prevent;
  quit;
 
  %do a=1 %to %eval(%tu_nobs(_pre_add_hc_prevent));
    %let _cmd = %str(%str(RTN)OTE: &&hcitem&a not hardcoded in &&si_dset&a as &&type&a in source data.);%tu_sdtmconv_sys_message;
  %end;
 %end;

 data _pre_add_hc;
  set _pre_add_hc;  
  num=_n_;
  if origin='' then origin='TBD';
  if upcase(substr(hcitem,1,2))='IF' then if_start='IF';
 run;

 %if %eval(%tu_nobs(_pre_add_hc))=0 %then %goto endmac;

 %DO w=1 %TO %eval(%tu_nobs(_pre_add_hc));

  /* For each iteration - process the instruction */
  data _null_ ;set _pre_add_hc (where=(num=&w));
   
   /* BJC002: set default for new ORIGIN variable - only used where the above code has not populated a different 
   /  value. Then populate into macro variable for use. */
   call symput('origin',trim(origin));     
   call symput('si_dset',trim(si_dset));
   call symput('si_var',trim(si_var));
   call symput('domain',trim(domain));
   call symput('hardcode',trim(hardcode));
   call symput('type',trim(type));
   call symput('hcitem',trim(hcitem));
   call symput('if_start',trim(if_start));
   call symput('all',trim(all));
  run;   

/* DSS001*/
/* Report any ORIGIN=TBD or invalid (in varmap_mrg) at the end of each run so that the programmers will go 
                               back and add/update hardcode origin definitions */

  %if &origin eq TBD and &if_start eq %then %do;
    %let _cmd = %str(%STR(RTW)ARNING: Assign ORIGIN value for &hcitem in &si_dset - this needs to be hardcoded where ORIGIN value is NULL/TBD);
    %tu_sdtmconv_sys_message;
  %end;

   /* Add hardcode values */
   data pre_sdtm.&si_dset ;
   
     /* if its a complex if-then type statement then it is likely to be on the si_var - so set the length longer */
     %if &if_start= %then %do;
      attrib &HCITEM length= $200 ;
     %end; 
     %if &if_start=IF %then %do;
      attrib &si_var length= $200 ;
     %end;     
    set pre_sdtm.&si_dset;

    /* If its a conditional hardcode then run this section */
    %if &all= %then %do;
     %if &type=char %then %do;
      if &si_var^='' then &hardcode ;
     %end;
     %if &type=num %then %do;
      if &si_var^=. then &hardcode ;
     %end;
    %end;
 
    /* If its NOT a conditional hardcode then run this section */
    %if &all=ALL %then %do;
                         &hardcode ;
    %end;                     
    
    run; 
  
   /* Add a row to the varmap file with the additional variable 
   /  If the statement is a complex one e.g. with an IF prefix then dont try and add variable, 
   /  must be added to varmap manually for this scenario as it is hard to parse the string to 
   /  derive the additional hardcoded variable */
  
   %if %length(&if_start)=0 %then %do;
       
   proc sql noprint;
     select count(*) into :in_varmap from varmap
      where si_dset="&si_dset"
        and si_var="&hcitem"
        and domain="&domain";
   quit;     
      
   %if &in_varmap=0 %then %do;
   
    data _pre_add_hc_varmap_add;      
     si_dset="&si_dset"; 
     si_var="&hcitem";
     /* BJC002: use new ORIGIN macro variable */
     origin="&origin";
     domain="&domain";
     sdtm_var="&hcitem";
     suppqual='NO';
     added='Y';
    run; 
     
    data varmap;
     set varmap 
         _pre_add_hc_varmap_add;
    run;
   %end;
  %end;  
  
 %end;
 
  /*BJC002: Add a check for user defined values of ORIGIN that are in the approved list */
  
  proc sql noprint;
   create table origin as 
   select distinct origin, si_dset, hcitem 
     from _pre_add_hc 
    where origin is not null and if_start is null and origin not in (select distinct origin from varmap_all);
  quit;  
  
  %if &sqlobs >=1 %then %do;
    %let ndobs=&sqlobs;
  
   proc sql noprint;  
    select origin, si_dset, hcitem
     into :origin1 - :origin%left(%trim(&ndobs)),
          :si_dset1 - :si_dset%left(%trim(&ndobs)),
          :hcitem1 - :hcitem%left(%trim(&ndobs))
    from origin;
   quit;
     
   %do a=1 %to &ndobs;
      %let _cmd = %str(%STR(RTW)ARNING: Invalid ORIGIN value &&origin&a for &&hcitem&a in &&si_dset&a source.);%tu_sdtmconv_sys_message;
   %end;
 %end; 
 
%end;

%endmac:

/* dont use tu_tidyup as this dataset is used tu_sdtmconv_drop_vars */

%mend tu_sdtmconv_util_pre_hardcode;
