/******************************************************************************* 
|
| Macro Name: tu_sdtmconv_create
|
| Macro Version/Build: 7 build 1
|
| SAS Version: SAS 9.1.3
|
| Created By: Bruce Chambers
|
| Date:            12-Aug-2009
|
| Macro Purpose: The main program that calls the sub macros in the pre-set order
|                as well as doing the preparation of the data, and some final 
|                reporting pieces at completion time.
|
|                As a useful aide the macros are specified in their order of execution
|                The exception being the last few that are called repeatedly.
|
| Macro Design: Procedure
|
| Input Parameters:
|
| NAME              DESCRIPTION                         DEFAULT 
|
| Output:
|
| Global macro variables created:
|
|
| Macros called:
| (@) tu_sdtmconv_pre_debug_subset
| (@) tu_sdtmconv_pre_adjust_visit 
| (@) tu_sdtmconv_pre_adjust_usubjid
| (@) tu_sdtmconv_util_pre_subset  
| (@) tu_sdtmconv_pre_decode 
| (@) tu_sdtmconv_pre_si_bespoke_all  
| (@) tu_sdtmconv_util_pre_rename 
| (@) tu_sdtmconv_util_pre_hardcode 
| (@) tu_sdtmconv_util_pre_get_visit 
| (@) tu_sdtmconv_pre_date_driver 
| (@) tu_sdtmconv_pre_dictdecode 
| (@) tu_sdtmconv_pre_adjust_cmdecod
| (@) tu_sdtmconv_util_pre_char2num 
| (@) tu_sdtmconv_util_pre_decode 
| (@) tu_sdtmconv_util_pre_upcase  
| (@) tu_sdtmconv_pre_seq_add 
| (@) tu_sdtmconv_util_pre_copy 
| (@) tu_sdtmconv_util_pre_replace  
| (@) tu_sdtmconv_util_pre_append 
| (@) tu_sdtmconv_util_pre_num_fmt 
| (@) tu_sdtmconv_pre_si_add_dsmlabs 
| (@) tu_sdtmconv_util_pre_add_label
| (@) tu_sdtmconv_pre_comb_eltm 
| (@) tu_sdtmconv_pre_drop_vars
| (@) tu_sdtmconv_mid_flip_si          
| (@) tu_sdtmconv_mid_remap 
| (@) tu_sdtmconv_mid_trans  
| (@) tu_sdtmconv_mid_type_convert 
| (@) tu_sdtmconv_util_mid_datepart 
| (@) tu_sdtmconv_util_mid_hardcode 
| (@) tu_sdtmconv_mid_norm_bsln
| (@) tu_sdtmconv_mid_append 
| (@) tu_sdtmconv_pst_check_td 
| (@) tu_sdtmconv_pst_sv_finisher 
| (@) tu_sdtmconv_pst_add_dy_vars 
| (@) tu_sdtmconv_pst_baseln;
| (@) tu_sdtmconv_pst_drop_null_cols 
| (@) tu_sdtmconv_pst_codelist_recon 
| (@) tu_sdtmconv_pst_shrink_drop_flag 
| (@) tu_sdtmconv_pst_sort_dup_chk 
| (@) tu_sdtmconv_sys_error_check
| (@) tu_sdtmconv_sys_message
| (@) tu_sdtmconv_sys_monitor 
| (@) tu_sdtmconv_sys_print 
| (@) tu_nobs
|
| Example:
|
|******************************************************************************* 
| Change Log 
|
| Modified By:                   Bruce Chambers
| Date of Modification:     	 13August2010      
| New Version/Build Number: 	 V2 Build 1    
| Reference:                     BJC001
| Description for Modification:  Change the run order of 3 of the macros:
|                                1) Move tu_sdtmconv_pst_drop_null_cols to after any ru_sdtmconv_adjust_sdtm
|                                2) Move tu_sdtmconv_util_pre_copy to before tu_sdtmconv_util_pre_replace 
|                                   so we can keep original values of variables that map to --TERM/--DECOD SDTM 
|                                3) Move tu_sdtmconv_util_pre_seq_add up to run before tu_sdtmconv_util_pre_copy 
| Reason for Modification:       1) So that missing expected/required values are checked AFTER any final 
|                                adjustments are made, this will reduce the size of listings, and not list 
|                                data problems that are later cured.
|                                2) For STOPDRUG the original term and the same term updated with the 
|                                'other, specify' reason are both needed in different SDTM columns
|                                3) So that where we copy SEQ numbers we can be sure they exist
|
| Modified By:                   Bruce Chambers
| Date of Modification:     	 13August2010      
| New Version/Build Number: 	 V2 Build 1    
| Reference:                     BJC002
| Description for Modification:  add "and not %symexist(prd_query)" to the metadata write check
| Reason for Modification:       So the system will only write out to the database tables if its a run on a
|                                production server. If a run is on DEV/TST but using production mappings 
|                                then dont write metrics out to the prod database to preserve prd integrity.
|
| Modified By:                   Bruce Chambers
| Date of Modification:     	 13August2010      
| New Version/Build Number: 	 V2 Build 1    
| Reference:                     BJC003
| Description for Modification:  Prevent processing of varmap entries where domain variables are not approved
| Reason for Modification:       To prevent errors in later conversion processing
|
| Modified By:                   Bruce Chambers
| Date of Modification:     	 13August2010      
| New Version/Build Number: 	 V2 Build 1    
| Reference:                     BJC004
| Description for Modification:  If a variable is dropped in AR dataset, but we are using the SI data to convert 
|                                then fixing the AR dataset does not need to be a MUST DO issue, so no * prefix
|                                is needed in this scenario
| Reason for Modification:       To keep issue output as brief as possible
|
| Modified By:                   Bruce Chambers
| Date of Modification:     	 16August2010      
| New Version/Build Number: 	 V2 Build 1    
| Reference:                     BJC005
| Description for Modification:  List any new DM/SI variables that appear in A&R as they may need dropping
|                                as only collected data needs converting.
| Reason for Modification:       To ensure SDTM data only contains collected data
|
| Modified By:                   Ashwin Venkat
| Date of Modification:     	 06September2010      
| New Version/Build Number: 	 V2 Build 1    
| Reference:                     VA001
| Description for Modification:  Changed sdtm library reference from sdtm to sdtmdata. To make it compatible with 
| Reason for Modification:       HARP
|
| Modified By:                   Bruce Chambers
| Date of Modification:     	 22November2010      
| New Version/Build Number: 	 V3 Build 1    
| Reference:                     BJC006
| Description for Modification:  Check for presence of mid_sdtm.study_sdtm1 instead of mid_sdtm.study_sdtm, as the more
|                                efficient code allows for >1 of these datasets, so this module checks if the first is present
| Reason for Modification:       To ensure code runs with other new efficiency enhancements.
|
| Modified By:                   Bruce Chambers
| Date of Modification:     	 22November2010      
| New Version/Build Number: 	 V3 Build 1    
| Reference:                     BJC007
| Description for Modification:  Add RELREC to list of datasets not generated by the conversion system
| Reason for Modification:       To ensure older created domains are correctly identified.
|
| Modified By:                   Bruce Chambers
| Date of Modification:     	 07January2011      
| New Version/Build Number: 	 V3 Build 1    
| Reference:                     BJC008
| Description for Modification:  Add tu_sdtmconv_pst_sv_finisher and tu_sdtmconv_pre_adjust_period
|                                and tu_sdtmconv_pre_adjust_usubjid to the conversion system
| Reason for Modification:       To augment the SV domain and process USUBJID and [T]PERIOD IDSL data correctly
|
| Modified By:                   Ashwin Venkat
| Date of Modification:     	 01February2011      
| New Version/Build Number: 	 V3 Build 1    
| Reference:                     VA002
| Description for Modification:  Indicate by output to driver file when DM SI and S&R datasets with same 
| Reason for Modification:       name have different number of rows
|
| Modified By:                   Bruce Chambers
| Date of Modification:     	 02February2011      
| New Version/Build Number: 	 V3 Build 1    
| Reference:                     BJC009
| Description for Modification:  Add ability to not convert but just check content of /sdtm directory
| Reason for Modification:       Enable checking of external SDTM data versus MSA definitions
|
| Modified By:                   Deepak Sriramulu
| Date of Modification:     	 10February2011      
| New Version/Build Number: 	 V3 Build 1    
| Reference:                     DSS001
| Description for Modification:  Add macro call to create study day variables (--DY, --STDY and --ENDY)
| Reason for Modification:       Study day variables were not getting created if they don't exist 
|
| Modified By:                   Deepak Sriramulu
| Date of Modification:     	 18April2011      
| New Version/Build Number: 	 V4 Build 1    
| Reference:                     DSS002
| Description for Modification:  Reword the output to fit the final output
| Reason for Modification:       Truncated output : i.e. No room on output for the final 'te' of Investigate ! 
|
| Modified By:                   Ashwin Venkat(va755193)
| Date of Modification:     	 25April2011      
| New Version/Build Number: 	 V4 Build 1    
| Reference:                     VA003
| Description for Modification:  moved tu_sdtmconv_adjust_sdtm macro call to before tu_sdtmconv_pst_check_td macro call,
| Reason for Modification:       so any fixes to ARM/ARMCD in pre processing does not get reported even if the issue is resolved 
|
| Modified By:                   Ashwin Venkat(va755193)
| Date of Modification:     	 2May2011      
| New Version/Build Number: 	 V4 Build 1    
| Reference:                     VA004
| Description for Modification:  Removing macro call tu_sdtmconv_pst_remove_viskeys because we dont want to drop visitnum/visit
| Reason for Modification:       even if it has null values. 
|
| Modified By:                   Bruce Chambers
| Date of Modification:     	 13May2011      
| New Version/Build Number: 	 V4 Build 1    
| Reference:                     BJC010
| Description for Modification:  Move check for column name = COL2 (bad product of transpose) to earlier as datasets get cleaned up
| Reason for Modification:       Ensure problems are flagged
|
| Modified By:                   Deepak Sriramulu
| Date of Modification:     	 26July2011      
| New Version/Build Number: 	 V5 Build 1    
| Reference:                     DSS003
| Description for Modification:  Reword the output to fit the final output
| Reason for Modification:       Truncated output : i.e. No room on output for the final 'ctify' of Rectify ! 
|
| Modified By:                   Ashwin Venkat
| Date of Modification:     	 11Apr2012      
| New Version/Build Number: 	 V6 Build 1    
| Reference:                     VA005
| Description for Modification:  some variables with datetime20. are mapped into SDTM data(eg HIMINT) 
| Reason for Modification:       so removing drop code where format = datetime20 
|
| Modified By:                   Ashwin Venkat
| Date of Modification:     	 15May2012      
| New Version/Build Number: 	 V6 Build 1    
| Reference:                     VA006
| Description for Modification:  Add generic baseline to all findings datasets 
| Reason for Modification:       baseline visits needs to be flagged 
|
| Modified By:                   Bruce Chambers
| Date of Modification:     	 15Aug2012      
| New Version/Build Number: 	 V6 Build 1    
| Reference:                     BJC011
| Description for Modification:  Add nobs to view_tab_list and process all datasets in PRE_SDTM library
| Reason for Modification:       Provide additional details of empty data groups for aCRF auto-annotation
|
| Modified By:                   Bruce Chambers
| Date of Modification:     	 15Aug2012      
| New Version/Build Number: 	 V6 Build 1    
| Reference:                     BJC012
| Description for Modification:  Partially undo BJC002 so that DEV/TST databases get monitor data tables populated
| Reason for Modification:       Ensure we can test all functionality
|
| Modified By:                   Bruce Chambers
| Date of Modification:     	 15Aug2012      
| New Version/Build Number: 	 V6 Build 1    
| Reference:                     BJC013
| Description for Modification:  Change order to run tu_sdtmconv_pre_adjust_cmdecod after tu_sdtmconv_pre_dictdecode
| Reason for Modification:       So multiple ingredients populated for SI datasets
|
| Modified By:                   Bruce Chambers
| Date of Modification:     	 08Aug2013      
| New Version/Build Number: 	 V7 Build 1    
| Reference:                     BJC014
| Description for Modification:  Retire/remove call to tu_sdtmconv_pre_adjust_period
| Reason for Modification:       EPOCH will always be derived from SE SDTM domain not from IDSL (A&R data only)
|
********************************************************************************/ 

%macro tu_sdtmconv_create(
);
/* BJC009 : ability to skip PRE and MID stages and go direct to PST stage to check (external) SDTM data */
%if &check_only eq Y %then %goto check_start;

/* Create driver dataset of all datasets processed with their libname/source */
/* BJC011: remove and nobs >=1 filter and add nobs to view_tab_list */
proc sql;
  create table view_tab_list as 
  (select libname, memname as basetabname, nobs
  from dictionary.tables
  where libname='DMDATA' 
    and memname not in (select name from excluded where type='DATASET')
    and memname in (select distinct si_dset from varmap_all)
    %if &si_dsets ^= %then %do;
       and memname in (&si_dsets)
    %end;
    %if &tab_list ^= %then %do; 
       and memname in (&tab_list)
    %end;
    %if &tab_exclude ^= %then %do;
       and memname not in (&tab_exclude)
    %end; 
  )
  union
  (select libname, memname as basetabname, nobs
    from dictionary.tables
    where libname='ARDATA' 
      and memname not in (select name from excluded where type='DATASET')
      and memname in (select distinct si_dset from varmap_all)      
      %if &si_dsets ^= %then %do;
         and memname not in (&si_dsets)
      %end;
      %if &tab_list ^= %then %do;
         and memname in (&tab_list)
      %end;
      %if &tab_exclude ^= %then %do;
         and memname not in (&tab_exclude)
      %end; 
  )
  order by basetabname;
  
    create table empty_tab_list as 
    (select libname, memname as basetabname
    from dictionary.tables
    where libname='DMDATA' 
      and nobs =0
      and memname not in (select name from excluded where type='DATASET')
      %if &si_dsets ^= %then %do;
         and memname in (&si_dsets)
      %end;
      %if &tab_list ^= %then %do;
         and memname in (&tab_list)
      %end;
      %if &tab_exclude ^= %then %do;
         and memname not in (&tab_exclude)
      %end; 
    )
    union
    (select libname, memname as basetabname
      from dictionary.tables
      where libname='ARDATA' 
        and nobs =0
        and memname not in (select name from excluded where type='DATASET')
        %if &si_dsets ^= %then %do;
           and memname not in (&si_dsets)
        %end;
        %if &tab_list ^= %then %do;
           and memname in (&tab_list)
        %end;
        %if &tab_exclude ^= %then %do;
           and memname not in (&tab_exclude)
        %end; 
    )
  order by basetabname; 
quit; 
 
/* Print out empty_tab_list to user listing in remap macro later on */

/* Reduce number of rows in varmap - only check and stop run for rows affecting this study.
/  Dont let other work stop this study running */
proc sql;
 create table varmap as select * from varmap_all 
  where si_dset in 
        (select distinct basetabname from view_tab_list);
quit; 

/*BJC003: Identify where any mappings relate to domains that have no approved variables in MSA yet
/ Remove row and notify user - this will prevent later errors and conversion problems. These will nearly
/ always be rows in study varmap.csv file - or possibly data loaded to MSA varmap table via back end. */

proc sql noprint;
 create table no_domain as 
 select distinct si_dset, domain 
   from varmap
  where domain not in (select distinct domain from reference);
quit;  
%if &sqlobs >=1 %then %do;
  %let ndobs=&sqlobs;

 proc sql noprint;

  delete from view_tab_list where basetabname in (select distinct trim(si_dset) from no_domain);

  delete from varmap where trim(si_dset)||trim(domain) in
   (select trim(si_dset)||trim(domain) from no_domain);  

  select si_dset, domain
   into :si_dset1 - :si_dset%left(%trim(&ndobs)),
        :dom1 - :dom%left(%trim(&ndobs))
  from no_domain;
 quit;
   
 %do a=1 %to &ndobs;
    %let _cmd = %str(%STR(RTE)RROR: Variable mappings from &&si_dset&a source to invalid &&dom&a domain.);%tu_sdtmconv_sys_message;

  %if &a=&ndobs %then %do;
     %let _cmd = %str(NB: Domain may not yet be approved in MSA. The system will ignore these mappings.);%tu_sdtmconv_sys_message;
  %end;
 %end;
%end; 
/* end of new section for BJC003 */

/* Copy the source datasets from current location to SDTM directory and then work on them there */
%let _cmd = %str(Copying source datasets to pre-SDTM conversion work area);%tu_sdtmconv_sys_message;
%local _ar_dataset_list _si_dataset_list;

/* BJC011: remove "and dt.nobs >=1" restriction to also copy empty datasets to PRE_SDTM library */

proc sql noprint;
      select unique vtl.basetabname into :_si_dataset_list separated by ' '
         from view_tab_list vtl, 
              dictionary.tables dt
        where vtl.basetabname=dt.memname
          and vtl.libname='DMDATA'   
          and vtl.libname=dt.libname      
          and vtl.basetabname not in (select name from excluded where type='DATASET')
          and substr(dt.memname,1,1)^='_'
         order by vtl.basetabname;

      select unique vtl.basetabname into :_ar_dataset_list separated by ' '
         from view_tab_list vtl, 
              dictionary.tables dt
        where vtl.basetabname=dt.memname
          and vtl.libname='ARDATA'
          and vtl.libname=dt.libname
          and vtl.basetabname not in (select name from excluded where type='DATASET')
          and substr(dt.memname,1,1)^='_'
         order by vtl.basetabname;         
quit;

/* Use noclone in case some v8 datasets present */
%if &_si_dataset_list ^= %then %do;
 proc copy in=dmdata out=pre_sdtm memtype=data noclone;
 select &_si_dataset_list;
 run;
%end;

%if &_ar_dataset_list ^= %then %do;
 proc copy in=ardata out=pre_sdtm memtype=data noclone;
 select &_ar_dataset_list;
 run;
%end;

/* If a subset clause is present - apply it to the incoming datasets */
%if %length(&subset_clause) >= 1 %then %do;
 %let _cmd = %str(Subsetting copy of source datasets on &subset_clause );%tu_sdtmconv_sys_message;
 %tu_sdtmconv_pre_debug_subset;
 %tu_sdtmconv_sys_error_check;

  /* Abort if no dataset to process or subset resulted in no data to process.  */
  /* The step is specifically inside subset_clause loop as need to ensure that */
  /* datasets created by the ru_sdtmconv_pre_adjust macro later are included.  */
  %if %eval(%tu_nobs(view_tab_list))=0 %then %do;  
    %let _cmd = %str(%STR(RTE)RROR: Aborting : No datasets to process.);%tu_sdtmconv_sys_message;
    %goto endmac;
  %end;
%end; 

%tu_sdtmconv_sys_error_check;

/* If a full run then Perform a gross check to ensure all the populated SI source 
/  variables are  present in the A+R datasets as this doesnt always seem to occur */

%if &tab_list eq and &tab_exclude eq and %length(&subset_clause)=0 %then %do;
 %let _cmd = %str(Full run - perform gross check to ensure SI vars are present in A+R datasets  );%tu_sdtmconv_sys_message;

 proc sql noprint;
  create table si_not_in_ar as
   select memname as si_dset, name 
     from dictionary.columns
    where libname='DMDATA'
      and memname in (select basetabname from view_tab_list)
      and memname in (select memname from dictionary.tables where libname='ARDATA')
     except
   select memname as si_dset, name 
     from dictionary.columns
    where libname='ARDATA'
      and memname in (select basetabname from view_tab_list)
      and memname in (select memname from dictionary.tables where libname='DMDATA');
 quit; 

 %if &sqlobs >=1 %then %do;
 
  %let _cmd = %str(%STR(RTW)ARNING: columns present in SI but missing from A+R datasets. Investigate/Rectify);%tu_sdtmconv_sys_message;

   /* Create empty dataset to report issues */
   data _report_missing_si_items;
    length problem_desc $60 si_dset $30 name $8;
    stop;
   run; 
 
   %let chkobs=&sqlobs;
   proc sql noprint;
    select si_dset, name
      into :si_dset1 - :si_dset%left(%trim(&chkobs)),
           :name1 - :name%left(%trim(&chkobs))
      from si_not_in_ar;
   quit;

    %do a=1 %to &chkobs;
     proc sql noprint;
      create table check&a as
      select "&&si_dset&a" as si_dset, "&&name&a" as name, count(*) as chk_count 
        from dmdata.&&si_dset&a 
       where &&name&a is not null;
     quit; 

      /* Append to work dataset for later use any issues to report later */ 
      /* bjc004: if variables dropped in AR dataset, but we are using the SI data to convert then fixing
      /  the AR dataset does not need to be a MUST DO issue, so no * prefix in this scenario */
      
      data _report_missing_si_items;
       set _report_missing_si_items check&a(in=b where=(chk_count>=1));
       if b then do;
	   /* DSS003: Reword the output text */
        if si_dset in (&si_dsets) then problem_desc=compress(put(chk_count,8.))||' non-missing in SI, missing in A&R. Rectify?';
        else problem_desc='* '||compress(put(chk_count,8.))||' non-missing in SI, missing in A&R. Investigate/Rectify';
       end; 
      run;
    %end;      
 %end;

/* VA002: Indicate by output to driver file when DM SI and S&R datasets with same name have different 
 /  of rows  */
 
 proc sql noprint;
  create table si_row_not_in_ar as
   select dtsi.memname as si_dset, dtsi.nobs as siobs, dtar.nobs as arobs 
     from dictionary.tables dtar,
          dictionary.tables dtsi
    where dtsi.libname='DMDATA'
      and dtar.libname='ARDATA'
      and dtsi.memname in (select basetabname from view_tab_list)
      and dtsi.memname = dtar.memname
      and dtsi.nobs ^= dtar.nobs ;  
    
 quit; 

 %if &sqlobs >=1 %then %do;
 
  %let _cmd = %str(%STR(RTW)ARNING: mismatch of observations between  SI and A+R datasets. Rectify.);%tu_sdtmconv_sys_message;

   
   data _report_mismatching_si_rows;
    length problem_desc $100 si_dset $30 name $8;
        set si_row_not_in_ar;
        name ="ALL";
/* DSS002: Reword the output text */
        problem_desc='* Obs mismatch: SI:'!! trim(left(put(siobs,best.)))!! ',A+R:' !!trim(left(put(arobs,best.)))!! ' Rectify?';
   run;
 %end;

 /* BJC005: check for any new SI variables that appear in A&R. These are probably derived and may need
 /  to be dropped from the final conversion product. Draw users attention to these items.  */
 proc sql noprint;
  create table _report_si_new_in_ar as
   select memname as si_dset, name ,'SI item new in AR data: if derived then consider dropping?' as problem_desc
     from dictionary.columns
    where libname='ARDATA'
      and name not in (select name from excluded where type='ITEM')
      and trim(memname)||trim(name) in (select trim(dataset_nm)||trim(var_nm) 
                                        from dsm_meta where dm_subset_flag='Y')                                      
      and memname in (select basetabname from view_tab_list)
      and memname in (select memname from dictionary.tables where libname='DMDATA')
     except
   select memname as si_dset, name ,'SI item new in AR data: if derived then consider dropping?' as problem_desc
     from dictionary.columns
    where libname='DMDATA'
      and memname in (select basetabname from view_tab_list)
      and memname in (select memname from dictionary.tables where libname='ARDATA');
 quit; 

%end;

%tu_sdtmconv_sys_error_check;

/* remove any datetime fields from the data as we use the date and time components as they are present
/ for all sources e.g. not in SI and not always in A&R. It is of note that some of the pre-processing 
/ does create DM (datetime) variables which do get used. */
/*VA005: Sometimes variables with DATETIME20. are mapped to sdtm domain eg. HMINT so removing the below drop statement since the 
variables will be drop*/

/* Opportunity to inject study specific SAS code to correct any anomalies on the incoming datasets */
%if %sysfunc(fileexist(&g_rfmtdir/ru_sdtmconv_pre_adjust.sas)) %then %do;
  %let _cmd = %str(Found &g_rfmtdir/ru_sdtmconv_pre_adjust.sas - running ); %tu_sdtmconv_sys_message;
  %include "&g_rfmtdir/ru_sdtmconv_pre_adjust.sas";
  %ru_sdtmconv_pre_adjust; 
%end;
%tu_sdtmconv_sys_error_check;

/* Harmonise VISIT values in any alternate source (DM SI) dataset used with main source (A+R) VISIT data values */
%let _cmd = %str(Harmonise VISIT values in any alternate source [DM SI] dataset used with main source [A+R] VISIT data values);%tu_sdtmconv_sys_message;
%tu_sdtmconv_pre_adjust_visit;
%tu_sdtmconv_sys_error_check;

/* BJC013: move CMDECOD derivation for multiple ingredients to later after tu_sdtmconv_pre_dictdecode */

/* BJC014:  Retire/remove call to tu_sdtmconv_pre_adjust_period as EPOCH will always be derived from SE SDTM domain 
            and not from IDSL [T]PERIOD (A&R data only) */

/* BJC009: Add macro to process USUBJID and SUBJID */
%let _cmd = %str(Pre-process USUBJID/SUBJID where necessary);%tu_sdtmconv_sys_message;
%tu_sdtmconv_pre_adjust_usubjid;
%tu_sdtmconv_sys_error_check;

********************************************************************************************;
/* Source data is ready - start processing */

/* apply a series of pre-processing steps to the incoming source datasteps 
/  NB the order of these is important 0- changing the order may adversely impact current defined 
/  mappings so is not recommended */

/* Subset data e.g. only keep rows where a check Q = Y */
%let _cmd = %str(Subset data e.g. only keep rows where a check Q = Y);%tu_sdtmconv_sys_message;
%tu_sdtmconv_util_pre_subset; 
%tu_sdtmconv_sys_error_check;

/* Use HARP decode macro to add decode versions of columns based on links in DSM (not manually defined)*/
%let _cmd = %str(Decoding and renaming variables that end in CD e.g. AEOUTCD to AEOUT);%tu_sdtmconv_sys_message;
%tu_sdtmconv_pre_decode;

/* Make some necessary generic pre-manipulations to SI data first */
%let _cmd = %str(Making bespoke manipulations e.g. DS and MEDHIST data reformat, DEMO additions );%tu_sdtmconv_sys_message;
%tu_sdtmconv_pre_si_bespoke_all; 
%tu_sdtmconv_sys_error_check;

/* Rename any source items as per instructions e.g. rename of time fields or tests */
%let _cmd = %str(Rename any source items as per instructions e.g. rename of time fields or tests);%tu_sdtmconv_sys_message;
%tu_sdtmconv_util_pre_rename;
%tu_sdtmconv_sys_error_check;

/* Adding hardcodes specific to source 
/ e.g. RAND source goes to DS SDTM domain along with DS source and needs different hardcodes */
%let _cmd = %str(Add hardcodes specific to data source);%tu_sdtmconv_sys_message;
%tu_sdtmconv_util_pre_hardcode;
%tu_sdtmconv_sys_error_check;

/* Derive visit details where needed */
%let _cmd = %str(Derive visit details where needed);%tu_sdtmconv_sys_message;
%tu_sdtmconv_util_pre_get_visit;
%tu_sdtmconv_sys_error_check;

%let _cmd = %str(Processing all date fields to ISO8601 format);%tu_sdtmconv_sys_message;
%tu_sdtmconv_pre_date_driver;
%tu_sdtmconv_sys_error_check;

/* Use HARP dict decode macro to add Meddra/GSKdrug columns */
%let _cmd = %str(Adding MedDRA and GSK drug dictionary data );%tu_sdtmconv_sys_message;
%tu_sdtmconv_pre_dictdecode;
%let syscc=0;
%tu_sdtmconv_sys_error_check;

/* Populate CMDECOD with each ingredient where 'Multiple Ingredient' populated in source dataset */
/* BJC013 - move this step from earlier on to after tu_sdtmconv_pre_dictdecode for SI dataset processing */
%let _cmd = %str(Populate CMDECOD with each ingredient where 'Multiple Ingredient' populated in CMDECOD in source dataset);%tu_sdtmconv_sys_message;
%tu_sdtmconv_pre_adjust_cmdecod;
%tu_sdtmconv_sys_error_check;

/* Amend item types if needed */
%let _cmd = %str(Amending item from char to num and create extra item for char data e.g.CMDOSTXT);%tu_sdtmconv_sys_message;
%tu_sdtmconv_util_pre_char2num;
%tu_sdtmconv_sys_error_check;

/* Applying data item level decodes e.g. AEREL Y -> RELATED */
%let _cmd = %str(Applying data item level decodes);%tu_sdtmconv_sys_message;
%tu_sdtmconv_util_pre_decode;
%tu_sdtmconv_sys_error_check;

/* Upper case some variable content */
%let _cmd = %str(Upper case variable content where specified);%tu_sdtmconv_sys_message;
%tu_sdtmconv_util_pre_upcase; 
%tu_sdtmconv_sys_error_check;

/* Add any SEQ identifiers needed */
/* BJC001: move tu_sdtmconv_util_pre_seq_add up to run before tu_sdtmconv_util_pre_copy 
/          so that where we copy SEQ numbers we can be sure they exist */

%let _cmd = %str(Adding SEQ identifiers as needed );%tu_sdtmconv_sys_message;
%tu_sdtmconv_pre_seq_add;
%tu_sdtmconv_sys_error_check;

/* Copying items specific to source e.g. we may want to keep a SEQ number but call it --GRPID */
/* BJC001: move tu_sdtmconv_util_pre_copy up to run before tu_sdtmconv_util_pre_replace 
/          so we can keep original values of variables that map to --TERM/--DECOD SDTM */

%let _cmd = %str(Copying variable specific to data source);%tu_sdtmconv_sys_message;
%tu_sdtmconv_util_pre_copy;
%tu_sdtmconv_sys_error_check;

/* Replace variable content - mainly ....SP and ...OTH variables */
%let _cmd = %str(Replace variable content - mainly ....SP and ...OTH variables);%tu_sdtmconv_sys_message;
%tu_sdtmconv_util_pre_replace; 
%tu_sdtmconv_sys_error_check;

/* Appending specified items  */
%let _cmd = %str(Appending source items );%tu_sdtmconv_sys_message;
%tu_sdtmconv_util_pre_append;
%tu_sdtmconv_sys_error_check;

/* Apply a specific numeric format if the default is too large */
%let _cmd = %str(Apply a specific numeric format if the default is too large);%tu_sdtmconv_sys_message;
%tu_sdtmconv_util_pre_num_fmt;
%tu_sdtmconv_sys_error_check;

/* Add var labels directly from DSM metadata for those columns that dont have them e.g from TU_decode */
%let _cmd = %str(Adding labels from DSM to faciliate later transpose);%tu_sdtmconv_sys_message;
%tu_sdtmconv_pre_si_add_dsmlabs;
%tu_sdtmconv_sys_error_check;

/* Add var labels for those columns that need remaing e.g. --TEST values for findings domains */
%let _cmd = %str(Adding labels from mapping file to faciliate later transpose);%tu_sdtmconv_sys_message;
%tu_sdtmconv_util_pre_add_label;
%tu_sdtmconv_sys_error_check;

/* Combine ELTMNUM and ELTMUNIT into --ELTM  */
%let _cmd = %str(Combine ELTMNUM and ELTMUNIT into --ELTM );%tu_sdtmconv_sys_message;
%tu_sdtmconv_pre_comb_eltm;
%tu_sdtmconv_sys_error_check;

/* Dropping any items not specified as being mapped to an SDTM destination  */
%let _cmd = %str(Dropping any source items not specified as being mapped to an SDTM destination  );%tu_sdtmconv_sys_message;
%tu_sdtmconv_pre_drop_vars;
%tu_sdtmconv_sys_error_check;

/* Up to here we use the PRE_SDTM libname **;
******************************************************************************************
** The next set of macros use the MID_SDTM library to do the major transform on the data */

%let _cmd = %str(Transposing source datasets to normalised format... can take a while....);%tu_sdtmconv_sys_message;
%tu_sdtmconv_mid_flip_si;            /* calls tu_sdtmconv_append_irp  */
%tu_sdtmconv_sys_error_check;

%let _cmd = %str(Mapping source data content to master SDTM map... can take a while....);%tu_sdtmconv_sys_message;
%tu_sdtmconv_mid_remap;
%tu_sdtmconv_sys_error_check;

/* BJC006: add a 1 suffix to mid_sdtm.study_sdtm name - as a result of efficiency code changes */
%if %eval(%tu_nobs(mid_sdtm.study_sdtm1))=0 %then %do;
   %let _cmd = %str(%STR(RTE)RROR: Aborting : No mapped data to process.);%tu_sdtmconv_sys_message;
   %goto endmac;
%end;

/* Now run the main transform steps */

%let _cmd = %str(Polling mapped data and preparing for build of SDTM sub-domain datasets);%tu_sdtmconv_sys_message;
%tu_sdtmconv_mid_trans; /* Calls tu_sdtmconv_mid_norm,tu_sdtmconv_mid_norm_add */
%tu_sdtmconv_sys_error_check;

/* Making any char to num or num to char conversions */
%let _cmd = %str(Making any char to num or num to char conversions);%tu_sdtmconv_sys_message;
%tu_sdtmconv_mid_type_convert;
%tu_sdtmconv_sys_error_check;

/* Apply any datepart conversion */
%let _cmd = %str(Applying any datepart conversions);%tu_sdtmconv_sys_message;
%tu_sdtmconv_util_mid_datepart;
%tu_sdtmconv_sys_error_check;

/* Apply any SDTM hardcodes */
%let _cmd = %str(Applying any SDTM hardcodes);%tu_sdtmconv_sys_message;
%tu_sdtmconv_util_mid_hardcode;
%tu_sdtmconv_sys_error_check;

/* VA006 : dont run this if generic flags assigned */
%if &genericblYN ne Y %then %do;
 /* Run norm_baseline routine - re-use amended HARP macro */
 %let _cmd = %str(Run norm_baseline routine to add --BLFL flags to findings domains);%tu_sdtmconv_sys_message;
 %tu_sdtmconv_mid_norm_bsln;
 %tu_sdtmconv_sys_error_check;
%end; 

/* Append/rename multiple sub-domains to single domain datasets and write datasets to PST_SDTM working library*/
%let _cmd = %str(Rename or Append multiple sub-domains to the single domain datasets);%tu_sdtmconv_sys_message;
%tu_sdtmconv_mid_append;
%tu_sdtmconv_sys_error_check;

** The previous set of macros use the MID_SDTM library to process datasets **;
******************************************************************************************;
** From here we use the PST_SDTM libname **;

/* BJC009: Add point at which checking process starts if conversion parts are skipped */
%check_start:

%if &check_only=Y %then %do;

 proc sql noprint;
  create table sdtm_dom as 
  select distinct memname as domain 
  from sashelp.vtable 
  where libname='SDTMDATA'
    and memname not in ('TA','TE','TI','TS','TV','SE','RELREC') 
    and memtype = 'DATA';
 
    alter table sdtm_dom add dom_type char(75) ;
    alter table sdtm_dom add dom_ref char(24) ;
    alter table sdtm_dom add pre_norm char(21) ;
    alter table sdtm_dom add seqvar char(30) ;
    alter table sdtm_dom add empty char(1) ;
       
    update sdtm_dom dom set dom_type=(select dom_type from domain_ref dr
    where dr.domain=dom.domain);
    
    update sdtm_dom dom set dom_ref=(select domref from domain_ref dr
    where dr.domain=dom.domain);
 
    update sdtm_dom dom set seqvar=(select variable_name from reference ref
    where ref.domain=dom.domain
      and substr(reverse(trim(ref.variable_name)),1,3)='QES');
      
    alter table sdtm_dom add dom_desc char(300) ;
 
    update sdtm_dom dom set dom_desc=(select dom_desc from domain_ref dr
    where dr.domain=dom.domain); 
    
    /* Check for and flag domains that are non-approved in MSA */
    create table invalid_domain as 
    select domain 
    from sdtm_dom 
    where (domain not in (select domain from domain_ref)
            and domain not in (select 'SUPP'||trim(domain) from domain_ref));
    
    delete from sdtm_dom where domain in (select domain from invalid_domain);
 quit;

 data sdtm_dom; set sdtm_dom;
  if substr(domain,1,4)='SUPP' then si_dset='SUPP';
 run; 

 %local invalid_domain; 
 %if %eval(%tu_nobs(invalid_domain))>=1 %then %do;   
  proc sql noprint;
   select domain
    into :dom1 - :dom%left(%trim(%eval(%tu_nobs(invalid_domain))))
    from invalid_domain;
    
   select domain into :invalid_domain separated by ' '
    from invalid_domain;
  quit;
   
  %do a=1 %to %eval(%tu_nobs(invalid_domain));
    %let _cmd = %str(%STR(RTE)RROR: Invalid &&dom&a domain in /sdtm directory - not approved in MSA. Will not be checked.);%tu_sdtmconv_sys_message;
  %end;
 %end; 

 /* Proc copy datasets into PST library */
 proc copy in=sdtmdata out=pst_sdtm memtype=data;
 /* Need to exclude SE RELREC and 5xTD */
  %if &invalid_domain ne %then %do;
   exclude &invalid_domain;
  %end; 
 run;

%end;

/* BJC009:end */

/*VA003: moved tu_sdtmconv_adjust_sdtm macro call to before tu_sdtmconv_pst_check_td macro call, so any fixes to ARM/ARMCD in pre processing
does not get reported even if the issue is resolved 
*/
 
/* apply any study-specific post-processing steps */
%if %sysfunc(fileexist(&g_rfmtdir/ru_sdtmconv_adjust_sdtm.sas)) %then %do;
  %let _cmd = %str(Found &g_rfmtdir/ru_sdtmconv_adjust_sdtm.sas - running ); %tu_sdtmconv_sys_message;
  %include "&g_rfmtdir/ru_sdtmconv_adjust_sdtm.sas";
  %ru_sdtmconv_adjust_sdtm;
%end;
%tu_sdtmconv_sys_error_check;

%if &tab_list eq and &tab_exclude eq and %length(&subset_clause)=0 %then %do;
 %let _cmd = %str(Checking consistency of common data between CRF and Trial design datasets [if present]);%tu_sdtmconv_sys_message;
 %tu_sdtmconv_pst_check_td;
 %tu_sdtmconv_sys_error_check;
%end;
/*VA004:removing macro call tu_sdtmconv_pst_remove_viskeys as we dont want to drop visit/visitnum even if values are null */
/* copy CO code from tu_sdtmconv_pst_remove_viskeys */
%if %sysfunc(exist(pst_sdtm.co)) %then %do;

 %if %length(%tu_chkvarsexist(pst_sdtm.co,visit visitnum,Y)) gt 0 %then %do;

  data pst_sdtm.co;
    set pst_sdtm.co;
    drop visit visitnum;
  run;

 %end;
%end;
 
%if %sysfunc(exist(pst_sdtm.dm)) %then %do;

 %if %length(%tu_chkvarsexist(pst_sdtm.dm,visit visitnum,Y)) gt 0 %then %do;

  data pst_sdtm.dm;
    set pst_sdtm.dm;
    drop visit visitnum;
  run;

 %end;
%end;

%if &tab_list eq and &tab_exclude eq and %length(&subset_clause)=0 and %sysfunc(exist(pst_sdtm.sv)) %then %do;
 %let _cmd = %str(Augment the SV domain: add in additional visit details found in other domains);%tu_sdtmconv_sys_message;
 %tu_sdtmconv_pst_sv_finisher;
 %tu_sdtmconv_sys_error_check;
%end;

/* DSS001: Add macro call to create study day variables (--DY, --STDY and --ENDY) */
 %tu_sdtmconv_pst_add_dy_vars;
 %tu_sdtmconv_sys_error_check;

/* VA006: Apply generic baseline */
%if &genericblYN eq Y and &check_only^=Y %then %do;
 
	%if %sysfunc(exist(pst_sdtm.ex)) %then %do;
		%let _cmd = %str(Applying generic baseline flagging );%tu_sdtmconv_sys_message;
		%tu_sdtmconv_pst_baseln;
		%tu_sdtmconv_sys_error_check;
	%end;
	%else %do;
		%let _cmd = %str(%STR(RTW)ARNING:Include EX domain in conversion to apply generic baseline flagging);%tu_sdtmconv_sys_message;
	%end;
%end;

/* Drop any columns where all values are null */
/* BJC001: move tu_sdtmconv_pst_drop_null_cols to after any ru_sdtmconv_adjust_sdtm so that missing 
/  expected/required values are checked AFTER any final adjustments are made, this will reduce the size 
/  of listings, and not list problems that are later cured */

%let _cmd = %str(Dropping any [permissible] columns where all values are empty);%tu_sdtmconv_sys_message;
%tu_sdtmconv_pst_drop_null_cols;
%tu_sdtmconv_sys_error_check;



/* Apply SDTM formats to decode data then reconcile codelist values with controlled terminology */
%let _cmd = %str(Apply SDTM formats to decode data then reconcile codelist values with controlled terminology);%tu_sdtmconv_sys_message;
%tu_sdtmconv_pst_codelist_recon;
%tu_sdtmconv_sys_error_check;

/* Reformat, sort and perform basic structural checks */
%let _cmd = %str(Reformat, order, sort and perform basic structural checks );%tu_sdtmconv_sys_message;
%tu_sdtmconv_pst_shrink_drop_flag;
%tu_sdtmconv_sys_error_check;
%tu_sdtmconv_pst_sort_dup_chk;
%tu_sdtmconv_sys_error_check;

/*VA001 - changing output library reference from sdtm to sdtmdata */

/* Copy the final datasets to the SDTM area if we get this far */
%let _cmd = %str(Writing SDTM domain datasets to final /study/utility/sdtm directory location );%tu_sdtmconv_sys_message;
proc copy in=pst_sdtm out=sdtmdata memtype=data;
run;

/* Print out issues for user review */
%tu_sdtmconv_sys_print;

* Report metadata from any complete runs to a central reference store *;
* Any errors AFTER here will have no impact on SDTM data integrity as the data is all written out by this stage*;
/* bjc002 - add "and not %symexist(prd_query)" so the system will only write out to the database tables 
/  if its a run on a production server - if its a run on DEV/TST but using production mappings then dont write
/  metrics out to the prod database */
/* BJC011: Undo BJC002 so that the DEV/TST databases get monitor data populated */

%if &tab_list eq and &tab_exclude eq and %length(&subset_clause)=0  %then %do;
 %let _cmd = %str(Writing out metadata store. );%tu_sdtmconv_sys_message;
 %tu_sdtmconv_sys_monitor;
%end;

/* BJC010 - move check for presence of COL2 to earlier on (mip_flip_si)- as the datasets get cleaned up */

/* final integrity check - check for any data with formats/informats present */
/* BJC bizarre - cant subset libname and memname in the first proc sql - dont know why */

proc sql noprint;
 create table fmt_inf as 
 select libname, memname, name , format, informat
   from dictionary.columns 
  where format is not null or informat is not null ;
quit;

%if &tab_exclude ne or &tab_list ne %then %do;
 proc sql noprint;
  delete from fmt_inf where memname not in (select domain from sdtm_dom);
 quit;
%end;

data fmt_inf; 
 set fmt_inf;
 if libname ^='SDTM' then delete;
run;

%if %eval(%tu_nobs(fmt_inf))>=1 %then %do;
 %let _cmd = %str(%STR(RTE)RROR: data with formats/informats present - report to developers);%tu_sdtmconv_sys_message;
 proc print data=fmt_inf;
 title3 "SDTM conversion: data with formats/informats present - report to developers";
 run;
%end;

/* final integrity check - 3) check for any old domain datsets that are still present on a full run.
/  this can happen if a mapping changes a lot i.e. a dataset is mapped to a different domain, or suppqual 
/  variables are changed. A domain may be left behind that is no longer reflecting the current mappings, 
/  or a mapping has been changed but is no longer working to produce expected output. */
%if &tab_list eq and &tab_exclude eq and %length(&subset_clause)=0 %then %do;

 /* BJC007: Add RELREC to the list of non-system generated domains, we would expect these to have different creation dates*/
 proc sql noprint;
  create table max_current as 
  select max(modate) as max_last_step from dictionary.tables
  where libname='PST_SDTM';
 
  create table old_sdtm as 
   select memname, modate 
     from dictionary.tables 
  where libname='SDTM'
    and modate lt (select max_last_step from max_current)
    and memname not in ('TA','TE','TI','TS','TV','SE','RELREC');
 quit;

 %if &sqlobs>=1 %then %do;
  %let _cmd = %str(%STR(RTE)RROR: Old domain datasets still present - check why and clean up/amend as needed);%tu_sdtmconv_sys_message;
  proc print data=old_sdtm;
   title3 "SDTM conversion: Old datasets still present in /sdtm directory on a full run.";
   title4 "This happens if a mapping changes i.e. a dataset is mapped to a different domain";
   title5 "or suppqual variables have changed. A domain may remain that no longer reflects";
   title6 "current mappings, or a mapping has changed that does not produce expected output";
   title7 "All domains are not deleted before each run in case a subset has been applied.";
  run;
 %end;
%end;

%endmac:

%let _cmd = %str( );%tu_sdtmconv_sys_message;
%let _cmd = %str(Completed SDTM dataset creation - see .lst file for any actions);%tu_sdtmconv_sys_message;
%let _cmd = %str( );%tu_sdtmconv_sys_message;

%mend tu_sdtmconv_create;
