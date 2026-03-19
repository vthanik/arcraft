/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_util_mid_hardcode
|
| Macro Version/Build:  6 build 1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009
|
| Macro Purpose:        Apply hardcode to the converted data, but while it is 
|                       still in the sub-domain e.g. BLIND_DS so that the 
|                       hardcodes are specific to the source/feeder dataset. 
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
| (@)tu_chkvarsexist
| (@)tu_sdtmconv_sys_message
|
| Example:
|
| %tu_sdtmconv_util_mid_hardcode
|
|*******************************************************************************
| Change Log :
|
| Modified By:             	Bruce Chambers
| Date of Modification:         01Mar2010
| New Version/Build Number:     v1 build 2     
| Description for Modification: Added a missing clause to an if statement to correctly
|                               parse a specific type of instruction
| Reason for Modification: 	To ensure correct parsing of instructions
|
|*******************************************************************************
| Modified By:             	Bruce Chambers
| Date of Modification:         07Apr2010
| New Version/Build Number:     v2 build 1
| Reference:                    BJC001 
| Description for Modification: Update references to variable prefix to use DOMREF
|                               instead of DOMAIN e.g. FA instead of FAMH so that
|                               variables referenced are FASEQ and not FAMHSEQ.
| Reason for Modification: 	Need to use FA instead of FAMH so that variables 
|                               referenced are FASEQ and not FAMHSEQ.
|
| Modified By:             	Bruce Chambers
| Date of Modification:         11May2010
| New Version/Build Number:     v3 build 1
| Reference:                    BJC002 
| Description for Modification: Update ADDED to varmap_mrg file used to populate traceability data
| Reason for Modification: 	used to populate define.xml traceability data
|
| Modified By:             	Bruce Chambers
| Date of Modification:         31Aug2010
| New Version/Build Number:     v4 build 1
| Reference:                    BJC003 
| Description for Modification: enable alternative origin values to be defined for hardcodes
| Reason for Modification:      Ensure correct define.xml production
|
| Modified By:             	Bruce Chambers
| Date of Modification:         31Aug2010
| New Version/Build Number:     v4 build 1
| Reference:                    BJC004 
| Description for Modification: process definition of a new hardcode item correctly
| Reason for Modification:      Ensure clean error free run of macro
|
| Modified By:                  Deepak Sriramulu
| Date of Modification:         10January2011
| New Version/Build Number:     5 Build 1
| Reference:                    DSS001
| Description for Modification: Report any ORIGIN=TBD or invalid (in varmap_mrg) at the end of  
|                               each run so that the programmers will go back and add/update 
|                               hardcode origin definitions
| Reason for Modification: 	    Ensure define.xml metadata is complete    
|
| Modified By:                  Bruce Chambers
| Date of Modification:         11March2013
| New Version/Build Number:     6 Build 1
| Reference:                    BJC005
| Description for Modification: check if data pre_normalised to apply row level TESTCD checks
| Reason for Modification: 	    Ensure correct end product    
|
********************************************************************************/ 
%macro tu_sdtmconv_util_mid_hardcode(
);

/* BJC001: add   , dr.domref as dom_ref   to the select clause below and augment the from and 
   where statement using joins from other queries that are already tested and validated/proven */
proc sql noprint;
 create table _mid_add_hc as
 select distinct compress(vm.domain)||'_'||compress(vm.si_dset) as memname,
        vm.si_dset, vm.domain, vm.suppqual, vm.sdtm_var, 
        vm.instructions, dc.type, vm.si_var, vm.num, dr.domref as dom_ref
   from instructions vm, 
       dictionary.columns dc,
       domain_ref dr
  where index(instructions,'sdtm_hardcode')>0
    and dc.libname='MID_SDTM'
    and vm.domain=dr.domain
    and substr(dc.memname,1,index(dc.memname,"_")-1)=vm.domain 
    and dc.name=vm.sdtm_var
    and vm.si_dset in (select basetabname from view_tab_list)   
    and compress(vm.domain)||'_'||compress(vm.si_dset) in 
         (select memname from dictionary.tables where libname='MID_SDTM')
    order by vm.num;
quit; 

/* Derive the hardcode from the string*/
data _mid_add_hc; set _mid_add_hc;
 
 /* BJC003: add step to process alternative ORIGIN value */
 length ORIGIN $8;
 if index(upcase(instructions),'ORIGIN') >=1 then do;   
  origin=substr(instructions,23,index(upcase(instructions), ',' )-24);
  instructions=trim('sdtm_hardcode('||substr(instructions,index(upcase(instructions),',')+1,length(instructions)-index(upcase(instructions),',')));
 end;  

 endpos=index(instructions,';');
 hardcode=substr(instructions,15,endpos-16); 
 startpos=index(hardcode,'=');
 
 if (upcase(substr(hardcode,1,2))^='IF' and upcase(substr(hardcode,1,4))^='DROP') then hcitem=substr(hardcode,1,startpos-1);
 /*BJC004: derive hardcode item cleanly */
 else do;
   hcitem=scan(hardcode,1,'=');
   hcitem=tranwrd(upcase(hcitem),'IF','');
   hcitem=tranwrd(hcitem,'^','');  
   hcitem=left(hcitem);
 end;
 num=_n_;    
 if (upcase(substr(hardcode,1,2))='IF' or upcase(substr(hardcode,1,4))='DROP') then if_drop_start='Y';
 if ORIGIN='' then ORIGIN='TBD'; 
run;

/* update/add hardcode type */
/* BJC005 : add si_rules.pre_norm flag */

proc sql noprint;
 alter table _mid_add_hc add hctype char(75);
 alter table _mid_add_hc add pre_norm char(3);
 
 update _mid_add_hc ah set hctype=(select type from reference ref
   where ah.domain=ref.domain
     and ah.hcitem=ref.variable_name);
	 
update _mid_add_hc ah set pre_norm=(select pre_norm from si_rules sir
   where ah.si_dset=sir.si_dset);	 
quit; 

/* Count the number of datasets (if any) to process */
%if %eval(%tu_nobs(_mid_add_hc))>=1 %then %do;

 %DO w=1 %TO %eval(%tu_nobs(_mid_add_hc));

  ** For each iteration - apply the instruction **;  
  /* BJC001: add dom_ref to the symputs below */
  
  data _null_ ;set _mid_add_hc (where=(num=&w));

   /*BJC003 set default if value not present and create ORIGIN to update varmap_mrg file used for define.xml traceability */
 
   call symput('origin',trim(origin));        
   call symput('memname',trim(memname));
   call symput('dom_ref',trim(dom_ref));
   call symput('domain',trim(domain));
   call symput('si_var',trim(si_var));
   call symput('sdtm_var',trim(sdtm_var));
   call symput('hardcode',trim(hardcode));
   call symput('suppqual',trim(suppqual));
   call symput('type',trim(type));
   call symput('hcitem',trim(hcitem));
   call symput('if_drop_start',trim(if_drop_start));
   
   /* BJC002 - add si_dset to update varmap_mrg file used for define.xml traceability */
   call symput('si_dset',trim(si_dset));   

   /* BJC005 : add si_rules.pre_norm flag */
   call symput('pre_norm',trim(pre_norm)); 
run;  
  
/* DSS001*/
/* Report any ORIGIN=TBD or invalid (in varmap_mrg) at the end of each run so that the programmers will go 
                               back and add/update hardcode origin definitions */

  %if &origin eq TBD and &if_drop_start eq %then %do;
    %let _cmd = %str(%STR(RTW)ARNING: Assign ORIGIN value for &hcitem in &si_dset - this needs to be hardcoded as ORIGIN value is NULL/TBD);
    %tu_sdtmconv_sys_message;
  %end;

  %local sdtm_type;
  proc sql noprint;
   select type into :sdtm_type from dictionary.columns
   where libname='MID_SDTM' 
   and memname="&memname"
   and name="&sdtm_var";
  quit;

  /* If a hardcode on a FINDINGS dataset then run this code 
     NOTE: If the findings are pre normalised this doesnt work */

  /* BJC001: replace domain with dom_ref as the variable prefix below */     
     
  %if %index(&sdtm_var,%str(ORRES)) >=1 and %index(&sdtm_var,%str(ORRESU)) =0 %then %do;
     data mid_sdtm.&memname;
      %if &sdtm_type=char and &if_drop_start eq %then %do;
       attrib &HCITEM length= $200 ;
      %end;
      set mid_sdtm.&memname;
	  /* BJC005: do row level check for tranposed source data only - if pre-normalised dont apply row level check */
      %if %length(&pre_norm)=0 %then %do;
       if &dom_ref.TESTCD="&si_var" then 
	  %end;	   
	   &hardcode ;
     run; 
  %end;
  
  /* If NOT a hardcode on a FINDINGS dataset then run this code */
  
  %if not (%index(&sdtm_var,%str(ORRES)) >=1 and %index(&sdtm_var,%str(ORRESU)) =0) %then %do;
   data mid_sdtm.&memname;
    %if &if_drop_start eq %then %do;
     attrib &HCITEM length= $200 ;
    %end; 
    set mid_sdtm.&memname;
    
    %if &if_drop_start eq and &type=char %then %do;
     if &sdtm_var^='' 
    %end;
    %if &if_drop_start eq and &type=num %then %do;
     if &sdtm_var^=. 
    %end;
    
    /*BJC004 - split into two if statements to ensure clean running of macro */
    %if &if_drop_start eq %then %do;
     %if %length(%tu_chkvarsexist(mid_sdtm.&memname,&hcitem))=0 %then %do;
      and &HCITEM =''
     %end;
    %end;
    
    %if &if_drop_start eq %then %do;
     then 
    %end;
    
    &hardcode ;
    
   run; 
  %end;
  
  /* BJC002 - update added hardcode into varmap_mrg file used for define.xml traceability */
  
  /* Add a row to the varmap file with the additional variable 
  /  If the statement is a complex one e.g. with an IF prefix then dont try and add variable, 
  /  must be added to varmap manually for this scenario as it is hard to parse the string to 
  /  derive the additional hardcoded variable */

  %if %length(&if_drop_start)=0 %then %do;

   proc sql noprint;
    select count(*) into :in_varmap from varmap_mrg
     where sdtm_var="&hcitem"
       and domain="&domain";
   quit;     

   %if &in_varmap=0 %then %do;

    data _mid_add_hc_varmap_add;      
    si_dset="&si_dset"; 
    si_var="&hcitem";
    
    /* BJC003: update the correct ORIGIN value for later define.xml generation */
    origin="&origin";
    
    domain="&domain";
    sdtm_var="&hcitem";
    suppqual='NO';
    added='Y';
    run; 

    data varmap_mrg;
     set varmap_mrg 
     _mid_add_hc_varmap_add;
    run;
   %end;
  %end;  

 %end;
 
 /*BJC003: Add a check for user defined values of ORIGIN that are in the approved list */
 
 proc sql noprint;
  create table origin as 
  select distinct origin, domain, hcitem 
    from _mid_add_hc 
   where origin is not null and if_drop_start is null and origin not in (select distinct origin from varmap_all);
 quit;  
 
 %if &sqlobs >=1 %then %do;
   %let ndobs=&sqlobs;
 
  proc sql noprint;  
   select origin, domain, hcitem 
    into :origin1 - :origin%left(%trim(&ndobs)),
         :domain1 - :domain%left(%trim(&ndobs)),
         :hcitem1 - :hcitem%left(%trim(&ndobs))
   from origin;
  quit;
    
  %do a=1 %to &ndobs;
     %let _cmd = %str(%STR(RTW)ARNING: Invalid ORIGIN value &&origin&a for &&hcitem&a in &&domain&a domain.);%tu_sdtmconv_sys_message;
  %end;
 %end; 
  
%end;

%if &sysenv=BACK %then %do;  

 %tu_tidyup(
  rmdset = _mid_add_hc:,
  glbmac = none
 );
%end;

%mend tu_sdtmconv_util_mid_hardcode;
