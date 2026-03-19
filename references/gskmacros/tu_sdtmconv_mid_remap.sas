/******************************************************************************* 
|
| Macro Name: tu_sdtmconv_mid_remap
|
| Macro Version/Build: 6/1
|
| SAS Version: SAS 9.1.3
|
| Created By: Bruce Chambers
|
| Date:            12-Aug-2009
|
| Macro Purpose:   Take the normalised mid_sdtm.study_t dataset and merge it with the
|                  varmap data source to give a data product with the source and target
|                  dataset/column details along with the actual data points in one mega
|                  normalised dataset. 
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
| Macros called:
| (@)tu_nobs          
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
| Date of Modification:         29Apr2010
| New Version/Build Number:     2/1
| Reference:                    BJC002
| Description for Modification: prune down the varmap_mrg file for traceability and also 
|                               system efficiency purposes 
| Reason for Modification:      so define.xml traceability only deals with items present
|                               and the big merge will run faster with less rows
|
| Modified By:                  Bruce Chambers
| Date of Modification:         18May2010
| New Version/Build Number:     2/1
| Reference:                    BJC003
| Description for Modification: add SRC_DATA_TYPE to varmap_mrg file for traceability 
|                              
| Reason for Modification:      so define.xml traceability has the details of the
|                               source data attributes (mainly for VLM section)
|
| Modified By:                  Bruce Chambers
| Date of Modification:         22Nov2010
| New Version/Build Number:     3/1
| Reference:                    BJC004
| Description for Modification: Rearrange steps so multiple study_t and multiple study_sdtm
|                               dataset production is accommodated                            
| Reason for Modification:      Performance enhancement for larger volume studies
|
| Modified By:                  Bruce Chambers
| Date of Modification:         22Nov2010
| New Version/Build Number:     3/1
| Reference:                    BJC005
| Description for Modification: Clarify unmapped datasets listing                     
| Reason for Modification:      Give more detail on study specific datasets and 
|                               clearly show if a dataset is only in DMDATA library.
|
| Modified By:                  Ashwin Venkat
| Date of Modification:         8Feb2011
| New Version/Build Number:     3/1
| Reference:                    VA001
| Description for Modification: flag any entry in study specific varmaps.csv file that are       
| Reason for Modification:      not used in the study. i.e where si_dset/si_var combination don't exist.
|
| Modified By:                  Bruce Chambers
| Date of Modification:         12May2011
| New Version/Build Number:     4/1
| Reference:                    BJC006
| Description for Modification: Correct typo in dataset name to be cleaned up  
|                               Also move step to run earlier for each iteration    
| Reason for Modification:      Ensure /saswork disk space used effectively.
|
| Modified By:                  Deepak Sriramulu
| Date of Modification:         28Jun2011
| New Version/Build Number:     5/1
| Reference:                    DSS001
| Description for Modification: Code added to overcome duplicate variable mapping issue in 
|                               varmap.                             
| Reason for Modification:      Sometimes we may end up having multiple rows for variable mapping.
|
| Modified By:                  Bruce Chambers
| Date of Modification:         01May2012
| New Version/Build Number:     6/1
| Reference:                    BJC007
| Description for Modification: Remove limitation on records placed in varmap_mrg 
| Reason for Modification:      So all data available for traceability purposes.
|
| Modified By:                  Bruce Chambers
| Date of Modification:         20Jul2012
| New Version/Build Number:     6/1
| Reference:                    BJC008
| Description for Modification: Only report unmapped datasets that have 8 or less chars in name (IDSL names)
|                               and also include empty ones that were previously excluded.
| Reason for Modification:      Exclude any EDU working dataset names from the listing and include and flag empty ones.
|
| Modified By:                  Bruce Chambers
| Date of Modification:         20Jul2012
| New Version/Build Number:     6/1
| Reference:                    BJC009
| Description for Modification: Dont remove added variables from the varmap metadata for later reference.
| Reason for Modification:      Full traceability available for later process e.g. eCRF re-annotation.
|
********************************************************************************/ 

%macro tu_sdtmconv_mid_remap(
);

/* DSS001: Code added to over come duplicate variable mapping issue in varmap. */
  
  proc sort data = varmap noduplicate;
  by _all_;
  run; 

/* BJC004: Rearrange this macro so the STUDY_T and STUDY_SDTM steps are in one place and can be looped through
   we we now have the potential for >1 of these datasets. Steps are the same just in a different order. 
   Only code change is addition of a do until loop to process multiple datasets */

proc sort data=varmap;
  by si_dset si_var;
run;

/* Only do the big merge on mapped SI reference data */
/* BJC001: amend origin where clause in this query */
/* BJC007: remove (where=(origin ^='DROPPED' or instructions^='')) from set statement in step below */

data varmap_mrg;
 set varmap;
 by si_dset si_var;
run; 

/* BJC002: add one proc sql step for big efficiency gain - delete mapping rows not used 
/          prior to big merge. Keep a work dataset for support and reference */

/* BJC009 : add "and added^='Y'" to the SQL for varmap deletions - to keep more useful rows */

proc sql noprint;

 create table varmap_not_used as select * from varmap_mrg vm
   where vm.domain ^='CO'
    and trim(vm.si_dset)||trim(vm.si_var) not in
    (select trim(dc.memname)||trim(dc.name) 
       from dictionary.columns dc,
            view_tab_list vtl
      where vtl.libname in ('ARDATA','DMDATA') 
        and vtl.basetabname=dc.memname)
        
   and trim(vm.si_dset)||trim(vm.si_var) not in
    (select trim(memname)||trim(name) from pre_sdtm)        

   and trim(vm.si_dset)||trim(vm.si_var) not in
    (select trim(memname)||trim(name) from date_meta_driver);

 delete from varmap_mrg vm
   where added^='Y'
    and trim(vm.si_dset)||trim(vm.si_var) not in
    (select trim(dc.memname)||trim(dc.name) 
       from dictionary.columns dc,
            view_tab_list vtl
      where vtl.libname in ('ARDATA','DMDATA') 
        and vtl.basetabname=dc.memname)
        
   and trim(vm.si_dset)||trim(vm.si_var) not in
    (select trim(memname)||trim(name) from _pre_vars_all) /* BJC009: use _pre_vars_all not pre_sdtm for full traceability */     

   and trim(vm.si_dset)||trim(vm.si_var) not in
    (select trim(memname)||trim(name) from date_meta_driver);
quit;    


/* start of section to match up IRP data with mapping data and output sdtm datasets */
/* BJC004 : add do loop for multiple datasets */
%do a= 1 %to &num_mid;

 /* sort both study_t and varmap datasets */
 proc sort data=mid_sdtm.study_t&a(rename=(_name_=si_var));
  by si_dset si_var;
 run;

 /* to assist this big merge subset the varmap data */
 proc sql noprint;    
  create table varmap_mrg&a as 
  select * from varmap_mrg
  where si_dset in (select distinct si_dset from mid_sdtm.study_t&a);
 quit;

 /* proc tranpose increases the length of si_var - this must be adjusted to match the source
 /  varmap attributes so artifically set both of them to avoid merge warnings */
 data mid_sdtm.study_t&a; 
  attrib si_var length=$20;
  si_var=upcase(si_var);
  set mid_sdtm.study_t&a;
 run;

/* to assist this big merge add index beforehand */
proc sql noprint;
 create index si_dset on mid_sdtm.study_t&a;
quit;

 /* Do the big merge and provide datasets of any variables not mapped */
 data mid_sdtm.study_sdtm&a 
     no_study&a (keep=si_dset si_var) ;
  merge mid_sdtm.study_t&a(in=ina)
        varmap_mrg&a(in=inb drop=instructions specification_details mapping_type status sdtm_ig_version 
                               source_standard modified_user);
  by si_dset si_var;
  if (ina*inb) and sdtm_var ^= '' then output mid_sdtm.study_sdtm&a;
  else if (inb*^ina) then output no_study&a;
 run;
 
 /* BJC006: correct dataset name and move step to run earlier */
 %if &sysenv=BACK and %symexist(__utc_workpath) eq 0 %then %do;  

   proc datasets memtype=data library=mid_sdtm nolist;
                delete study_t&a;
   run;
   
 %end; 
 
%end; /* BJC004 : end of do loop for multiple datasets */

/* BJC003 - one step to update SRC_DATA_TYPE into VARMAP_MRG dataset */
/* BJC008: for EMPTY datasets update ADDED column for varmap_mrg - flag rows with ADDED='E' for empty. 
   For rows from empty datasets that already had ADDED=Y then set it to Z. 
   i.e. Z shows it was added to an empty dataset (Z is the next value after the default Y value) */

proc sql;
 alter table varmap_mrg add SRC_DATA_TYPE char(54);
 
 update varmap_mrg vm set SRC_DATA_TYPE=(
 select src_data_type 
   from pre_sdtm
  where vm.si_dset=memname 
    and vm.si_var=name);

 update varmap_mrg vm set ADDED=(
  select 'Z' as added 
  from empty_tab_list
  where basetabname=vm.si_dset)
  where added is not null 
  and si_dset in (select basetabname from empty_tab_list);

 update varmap_mrg vm set ADDED=(
  select 'E' as added 
  from empty_tab_list
  where basetabname=vm.si_dset)
  where added is null;

quit;

/* Perform a gross check for any non-mapped datasets */
/* BJC005: add and populate dm_only flag */
/* BJC008: only report valid IDSL dataset names where length <=8 (i.e. not the ones from EDU ) and remove "and nobs >=1" */

proc sql noprint;
 create table non_mapped_si_datasets as 
 (select distinct memname as si_dset 
    from dictionary.tables where libname in ('DMDATA','ARDATA')
    and length(memname) <=8
  except
  select distinct si_dset from varmap);
    
  delete from non_mapped_si_datasets 
   where si_dset in (select name from excluded where type='DATASET');
  
  %if &tab_list ne or &tab_exclude ne %then %do;
   delete from non_mapped_si_datasets where si_dset not in (select basetabname from view_tab_list);
  %end;
  
  alter table non_mapped_si_datasets add dm_only char(1);

  update non_mapped_si_datasets set dm_only='Y' 
  where si_dset in (select memname from dictionary.tables where libname='DMDATA')
   and si_dset not in (select memname from dictionary.tables where libname='ARDATA');
quit;  

/* print high level source dataset summary listing */
/* BJC005: clarify the output for study specific mapping to show if they are Spectre or A&R study specific */
proc sort data=non_mapped_si_datasets;
         by si_dset;
run;
proc sort data=study_specific_meta out=ssm nodupkey;
         by dataset_nm;
run;


data non_mapped_si_datasets; 
 length level $50;
 merge non_mapped_si_datasets(in=a) 
       dsm_tabs(in=b)
       ssm(in=c rename=(dataset_nm=si_dset)
               drop=dm_subset_flag stnd_dataset_type_desc clinical_dict codelist_nm var_nm);
  by si_dset;
  if a;
  
  /* abbreviate long entries so they fit on screen */
  thrpy_nm=tranwrd(thrpy_nm, 'Clinical', 'Clin');
  thrpy_nm=tranwrd(thrpy_nm, 'Pharmacology', 'Pharm');
  sub_thrpy_nm=tranwrd(sub_thrpy_nm, 'Clinical', 'Clin');
  sub_thrpy_nm=tranwrd(sub_thrpy_nm, 'Pharmacology', 'Pharm');
 
  if dataset_type_desc^='' then do;
   level=trim(dataset_type_desc)||'-'||trim(thrpy_nm)||'-'||trim(sub_thrpy_nm);
  end;
  if c and level='' then level='DM SI Spectre: Study Specific';
  else if not c and level='' then level='A&R Study Specific';  
run;

proc print data=non_mapped_si_datasets noobs label split='*';
title3 "SDTM conversion: &g_study_id source dataset not (yet) in master/study Mappings";
title4 ;
title5 "   Does the data need converting, if so, place request for mapping to be defined ";
title6 " OR";
title7 "The dataset is available in the DM SI but not the A+R library. ";
var si_dset dm_only level;
label si_dset='Source dataset name'
      dm_only='Only in * DMDATA library'
      level='Core/TST/TST sub-type/Study specifics';
run;

proc print data=empty_tab_list noobs;
title3 "SDTM conversion: &g_study_id SI datasets with 0 rows - conversion not attempted";
run;

/*VA001: flag any entry in study specific varmaps.csv file that are not used in the study.
 i.e where si_dset/si_var combination don't exist.*/
%if %eval(%tu_nobs(varmap_not_used))>=1 %then %do;
    %if &tab_list eq and &tab_exclude eq and %length(&subset_clause)=0 %then %do;
        proc print data = varmap_not_used noobs label split = '*' width = min;
        title3 "SDTM conversion: entries in varmap.csv but not used in &g_study_id SDTM conversion";
        title4;
        title5 "this could be because of typos or unwanted mapping.If not needed remove them";
        var si_dset si_var domain sdtm_var;
        where ss ne '';
        label si_dset = 'Source dataset name'
              si_var  = 'Source variable name'
              domain  = 'SDTM domain'
              sdtm_var = 'SDTM variable name';
        run;
    %end;
%end;

%mend tu_sdtmconv_mid_remap;

