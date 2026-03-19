/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_util_pre_get_visit
|
| Macro Version/Build:  7/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers 
|
| Date:                 28-Jul-2009
|
| Macro Purpose :       Using VISIT dataset as source, create a target date field
|                       and update VISITDT into new date by linking on 
|                       VISIT/SUBJID as keys
|            
|                       If VISITNUM is absent the code also updates VISITNUM from
|                       VISIT
|
|                       The macro requires at least VISIT column to be present, 
|                       and for the source VISIT dataset to also be present in
|                       the run. 
|
|                       If we have a VISIT='Unscheduled' in the dataset to be 
|                       updated and any subject has more than one unscheduled 
|                       visit then the VISITNUM updated will be 999 and the date
|                       field will be set null
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
| (@)tu_chkvarsexist
| (@)tu_tidyup
| (@)tu_nobs
| (@)tu_sdtmconv_sys_message
|
| Example:
|
| %tu_sdtmconv_util_pre_get_visit
|
|*******************************************************************************
| Change Log :
|
| Modified By:                  Bruce Chambers
| Date of Modification:         13Sep2010
| New Version/Build Number:     V2 build 1      
| Reference :                   bjc001
| Description for Modification: proc sql statement needs to be outside if loop
| Reason for Modification:      so code will run for all scenarios
|
| Modified By:                  Bruce Chambers
| Date of Modification:         13Sep2010
| New Version/Build Number:     V3 build 1      
| Reference :                   bjc002
| Description for Modification: Remove code to process and flag where >1 unscheduled
| Reason for Modification:      The system now uniquely IDs unscheduled visits in the
|                               tu_sdtmconv_pre_adjust_visit.sas macro so this is no
|                               longer needed. To remove avoids potential errors in complex code
|
| Modified By:                  Bruce Chambers
| Date of Modification:         07Jan2011
| New Version/Build Number:     V4 build 1      
| Reference :                   bjc003
| Description for Modification: Optimise SQL code as performs badly on large volumes
| Reason for Modification:      Optimise SQL code as performs badly on large volumes
|
|
| Modified By:                  Ashwin Venkat (VA755193)
| Date of Modification:         11May2011
| New Version/Build Number:     V5 build 1      
| Reference :                   VA001
| Description for Modification: change RTNOTE for null (VISIT)NUM --DTC to RTWARNING 
| Reason for Modification:      because this issue needs to be fixed 
|
| Modified By:                  Ashwin Venkat (VA755193)
| Date of Modification:         17Aug2011
| New Version/Build Number:     V6 build 1      
| Reference :                   VA002
| Description for Modification: called tidyup macro to remove some work datasets
| Reason for Modification:      removed some work datasets as they are no longer required
|
| Modified By:                  Bruce Chambers
| Date of Modification:         24Jan2013
| New Version/Build Number:     V7 build 1      
| Reference :                   BJC004
| Description for Modification: remove code to try and populate missing data
| Reason for Modification:      QC review found it makes invalid assumptions. have to populate missings study by study
*******************************************************************************/
%macro tu_sdtmconv_util_pre_get_visit(
);

proc sql noprint; 
 create table _pre_get_vis_info as
 select vm.si_dset, vm.si_var, vm.instructions, 
        substr(instructions,14,index(instructions,';')-15) as date_name
  from instructions vm, 
       dictionary.columns dc
 where dc.libname='PRE_SDTM'
   and dc.memname=vm.si_dset
   and dc.name=vm.si_var
   and index(vm.instructions,'get_vis_info')>0
   and si_dset in (select basetabname from view_tab_list);
quit; 

** Count the number of datasets (if any) to process **;
%if &sqlobs>=1 %then %do;

 data _pre_get_vis_info;
  set _pre_get_vis_info;
  num=_n_;
 run; 

 %if not %sysfunc(exist(pre_sdtm.visit)) %then %do;
    %let _cmd = %str(%str(RTW)ARNING: VISIT source dataset needed to derive some dates/VISITNUMs [provide source data to the run]);%tu_sdtmconv_sys_message; 
 %end;
 
 %if %sysfunc(exist(pre_sdtm.visit)) %then %do;
  
  proc sort data=pre_sdtm.visit out=visit;
  by subjid visit;run;
  
  /* BJC003: For efficiency create look up table (just once) from the VISIT data */
  proc sql noprint;
   create table minvisn as
   select subjid, 
       case
           when upcase(visit) like 'UNS' then 'UNS'
           else visit
       end as visit, 
       min(visitnum) as minvisn
   from visit
   group by subjid,
         case
             when upcase(visit) like 'UNS' then 'UNS'
             else visit
         end;
         
   create index subjvis on visit (subjid, visit, visitnum);          
   create index subjvis on minvisn (subjid, visit, minvisn);
  quit; 

  /* bjc002: remove steps for multiple unscheduled visits */
      
  /* Loop through and execute each instruction */
  %DO w=1 %TO %eval(%tu_nobs(_pre_get_vis_info));
  
   data _null_ ;set _pre_get_vis_info (where=(num=&w));
    call symput('si_dset',trim(si_dset));
    call symput('si_var',trim(si_var));
    call symput('date_name',trim(date_name));
   run;
 
   %local visitnum_present date_name_present visit;

   %let visit= %tu_chkvarsexist(pre_sdtm.&si_dset,VISIT,Y);
   %if &VISIT eq %then %do;     
    %let _cmd = %str(%str(RTW)ARNING: Cant derive &date_name for &si_dset as VISIT is not present);%tu_sdtmconv_sys_message; 
    %goto skip;
   %end;
   
   %if &VISIT ne %then %let visit=VISIT;

    proc sort data=pre_sdtm.&si_dset;
    by subjid &visit;run;

    %let date_name_present=%tu_chkvarsexist(pre_sdtm.&si_dset,&date_name,Y);  
    %let visitnum_present=%tu_chkvarsexist(pre_sdtm.&si_dset,VISITNUM,Y);     

    /* bjc002: remove steps for multiple unscheduled visits */

    /* If only the VISIT column is present then add and derive VISITNUM.
    /  Limited solution - will only update min(visitdt) if more than one unscheduled 
    / this correctly updates for most subjects i.e. one unscheduled. as min=the only one.*/
     
    %if &visitnum_present eq %then %do;    

     proc sql noprint;
      alter table pre_sdtm.&si_dset add VISITNUM numeric;
     
     %let _cmd = %str(Derive VISITNUM for &si_dset);%tu_sdtmconv_sys_message;

     update pre_sdtm.&si_dset p set visitnum=
      (select minvisn 
         from minvisn (idxname=subjvis) v
        where p.subjid=v.subjid
          and p.visit=v.visit
        group by subjid, visit)
        where visitnum is null;    
     quit; 
    %end;
                        
    %if &date_name_present eq %then %do;
      proc sql noprint;
       alter table pre_sdtm.&si_dset add &date_name numeric format=DATE9. ;
      quit;   
    %end;

    %let _cmd = %str(Derive &date_name for &si_dset);%tu_sdtmconv_sys_message;
    proc sql noprint;
       update pre_sdtm.&si_dset p set &date_name=
       (select min(visitdt) 
         from visit (idxname=subjvis) v
        where p.subjid=v.subjid
          and p.visit=v.visit
        group by subjid, visit)
        where &date_name is null;    
    quit; 
     
	/* BJC004: remove the section that tried to populate remaining null values - assumptions made were not always valid */

    /* check for any null values remaining after update */
    proc sql noprint;
     select count(*) into :null_vnum from pre_sdtm.&si_dset where visitnum is null;
     select count(*) into :null_vis from pre_sdtm.&si_dset where visit is null;
     select count(*) into :null_date from pre_sdtm.&si_dset where &date_name is null;
    quit;
     /*VA001: change RTNOTE to RTWARNING*/
    %if &null_vnum>=1 or &null_date>=1 or &null_vis>=1 %then %do;
      %let _cmd = %str(%str(RTW)ARNING: At least one VISIT[NUM] or &date_name in &si_dset still null after update);%tu_sdtmconv_sys_message;      
    %end;
      
    /* Add a row to the varmap file with the new additional ----DT variable 
    /  Need to derive the domain this relates to from varmap 
    /  Also some pre-processed datasets may already have the ---DT so we dont want a duplicate */
        
      %let domain=;
      proc sql noprint; 
       select distinct domain into :domain
         from varmap
        where sdtm_var="&date_name" 
          and si_dset="&si_dset";
             
       select count(sdtm_var) into :COUNT_SDTM_VAR
         from varmap
        where sdtm_var="&date_name"
          and si_var="&date_name"
          and si_dset="&si_dset";       
      quit;    
             
      %if %length(&domain)>=1 and &COUNT_SDTM_VAR=0 %then %do;    
       data _pre_get_vis_varmap_add;      
          si_dset="&si_dset"; 
          si_var="&date_name";
          origin='CRF';
          domain="&domain";
          sdtm_var="&date_name";
          suppqual='NO';
          added='Y';
       run; 
             
       data varmap;
        set varmap 
            _pre_get_vis_varmap_add;
       run;  
          
      %end;            
    
    %skip:
  
  %end;   
 %end;
%end;
/*AV002: removed some work datasets that are not required later on*/
%if &sysenv=BACK %then %do;  

%tu_tidyup(
 rmdset = minvisn,
 glbmac = none
);

%tu_tidyup(
 rmdset = visit,
 glbmac = none
);

%tu_tidyup(
 rmdset = _pre_get_vis:,
 glbmac = none
);
%end;

%mend tu_sdtmconv_util_pre_get_visit;
