/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_drop_vars
|
| Macro Version/Build:  5/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009
|
| Macro Purpose:        Before the major transpose is run, drop any variables
|                       that are not needed for the SDTM product so that the
|                       transposed data is as small in data volume as possible
|                       for efficiency purposes.
|
|                       Also produce listing of non-mapped data and show if it 
|                       is SI or A&R DSM source or neither (added/analysis A&R).
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
| (@)tu_nobs
|
| Example:
|
| %tu_sdtmconv_pre_drop_vars
|
|*******************************************************************************
| Change Log:
|
| Modified By:                  Bruce Chambers
| Date of Modification:         04august2010
| New Version/Build Number:     2/1
| Reference :                   bjc001
| Description for Modification: Report no map should only report data in current run
| Reason for Modification:      When sys_register is called we may add to pre_sdtm library
|                               a dataset that is not in the current run and is not converted
|                               and this data should not appear in outputs.
|
| Modified By:                  Bruce Chambers
| Date of Modification:         06Sep2010
| New Version/Build Number:     2/1
| Reference :                   bjc002
| Description for Modification: correct a reference in SQL where statement name -> memname
|                               and remove one line of where clause
| Reason for Modification:      Ensure all non-mapped SI variables are reported
|
| Modified By:                  Bruce Chambers
| Date of Modification:         06Sep2010
| New Version/Build Number:     2/1
| Reference :                   bjc003
| Description for Modification: Flag exemption variables as such
| Reason for Modification:      Clarity of user listings for later review
|
| Modified By:                  Bruce Chambers
| Date of Modification:         06Sep2010
| New Version/Build Number:     3/1
| Reference :                   bjc004
| Description for Modification: Dont tidy up _pre_vars_to_drop dataset
| Reason for Modification:      It is now used later in sys_print macro
|
| Modified By:                  Bruce Chambers
| Date of Modification:         09Feb2011
| New Version/Build Number:     3/1
| Reference :                   bjc005
| Description for Modification: Dont drop SUBJID for DEMO dataset
| Reason for Modification:      Introduction of pre_adjust_usubjid means this now needed
|
| Modified By:                  Bruce Chambers
| Date of Modification:         07 Oct2012
| New Version/Build Number:     4/1
| Reference :                   bjc006
| Description for Modification: Only drop variables for populated datasets (nobs>=1)
| Reason for Modification:      Avoids un-necessary user listing to reivew and confuse
|                               Empty datasets are not processed past pre stage anyway
|
| Modified By:                  Bruce Chambers
| Date of Modification:         07 Oct2012
| New Version/Build Number:     5/1
| Reference :                   bjc007
| Description for Modification: Refine SQL to avoid conflicts with flagging of EXEMP Y/Y or null
| Reason for Modification:      If the same dataset name used for SS and MCD (or Core) domain
|                               then the EXEMP variable will be null for the SS one - allow for this
|
*******************************************************************************/
%macro tu_sdtmconv_pre_drop_vars(
);

/* _pre_vars_to_keep is a list of source dataset-variable combinations that are in varmap
/  _pre_vars_to_drop is the remainder of the columns present that are not in varmap
/  _report_no_map is used to list later any non-mapped data, and excluded items are removed */

/* bjc001: add clause "and name in (select basetabname from view_tab_list)" to _report_no_map query */

proc sql noprint;
 /* BJC006: filter further down to exclude empty datasets */
 create table _pre_vars_all as 
 (select dc.memname, dc.name
    from dictionary.columns dc, dictionary.tables dt
   where dc.libname='PRE_SDTM'
     and dt.libname=dc.libname
	 and dt.memname=dc.memname
	 and dt.nobs>=1);

 create table _pre_vars_to_keep as 
 (select memname, name
    from _pre_vars_all 
     where trim(memname)||trim(name) in
        (select distinct trim(si_dset)||trim(si_var) from varmap
         where trim(origin) ^= 'DROPPED' ));

 create table _pre_vars_to_drop as 
 (select memname, name, 'drop '||name as drop_name
    from _pre_vars_all
   where name not in ('STUDYID','USUBJID','SUBJID','VISIT','VISITNUM','SEQ')
   and trim(memname)||trim(name) not in
         (select trim(si_dset)||trim(si_var) from _pre_add_hc)
   and trim(memname)||trim(name) not in
         (select trim(si_dset)||trim(si_var) from _pre_copy)
     and trim(memname)||trim(name) not in
         (select trim(memname)||trim(name) from _pre_vars_to_keep)
      or name in (select trim(name) from excluded where type='ITEM'));
 
 /* BJC002: correct name to memname in "MEMname in (select basetabname from view_tab_list)"
 /          and remove "and name not in (select var_nm from fmtvars)" as we still need to 
 /          map any coded items as ORIGIN=DROPPED in MSA */
 create table _report_no_map as 
   select memname as si_dset, name, drop_name
     from _pre_vars_to_drop
    where name not in (select trim(name) from excluded where type='ITEM')
     and trim(memname)||trim(name) not in
            (select distinct trim(si_dset)||trim(si_var) from varmap
         where trim(origin) = 'DROPPED' )
     and memname in (select basetabname from view_tab_list)
     and substr(reverse(trim(name)),1,2)^='MD';
quit;

/* Update DSM flag to indicate whether any unmapped data is in DSM or not i.e. A+R variable if not 
   this then gets relected in the descriptions for issue listings later */
/* BJC003 add column and update exemption variable flag into _report_no_map */

proc sql noprint;
 alter table _report_no_map add dm_subset_flag char(1);
 alter table _report_no_map add ar_subset_flag char(1);
 alter table _report_no_map add exemp char(1);
 /* BJC007: add: "and exemp is not null" to where clause */
 update _report_no_map nm set exemp=(select distinct exemp 
    from dsm_meta dsm
    where dsm.dataset_nm=nm.si_dset
      and dsm.var_nm=nm.name and exemp is not null);
 
 update _report_no_map nm set dm_subset_flag=(select distinct 'Y' 
   from dsm_meta dsm
   where dsm.dataset_nm=nm.si_dset
     and dsm.var_nm=nm.name and dm_subset_flag='Y');

 update _report_no_map nm set ar_subset_flag=(select distinct 'Y' 
   from dsm_meta dsm
   where dsm.dataset_nm=nm.si_dset
     and dsm.var_nm=nm.name and ar_subset_flag='Y'); 

 /* This is a slight fudge as we cant tell from DSM if a study specific spec variable is A&R  
    - for study specific datasets this is only stored in the HARP reporting dataset plans */
    
 update _report_no_map nm set ar_subset_flag=(select 'Y' 
   from label_dsm alldsmvars
   where alldsmvars.name=nm.name 
     and nm.si_dset in (select dataset_nm from study_specific_meta))
     where ar_subset_flag is null;      
quit;

/* There are exceptions that are added to many/all AR datasets that are only needed in the
/  SDTM product once. These are kept for the data groups or domains where they are needed */

data _pre_vars_to_drop;
 set _pre_vars_to_drop;
 /* BJC005: add clause to not drop SUBJID from DEMO - this is an exception */
 if memname='DEMO' and drop_name in ('drop SUBJID','drop INVID','drop CENTREID','drop RACE','drop SEX','drop AGE','drop COUNTRY') then delete;
 if memname='RAND' and drop_name in ('drop RANDNUM') then delete;
run;

/* Get list of dataset names to process */
proc sort data=_pre_vars_to_drop 
          out=_pre_vars_to_drop_unq_ds nodupkey;
by memname ;
run;

data _pre_vars_to_drop_unq_ds;
 set _pre_vars_to_drop_unq_ds;
 num=_n_;
run;

/* Count the number of datasets (if any) to process */
%if %eval(%tu_nobs(_pre_vars_to_drop_unq_ds))>=1 %then %do;  

 %do w=1 %to %eval(%tu_nobs(_pre_vars_to_drop_unq_ds));
 
  /* For each dataset - get a subset of the entire variable list */  
  data _null_ ;set _pre_vars_to_drop_unq_ds (where=(num=&w));
   call symput('memname',trim(memname));
  run;

  data _pre_vars_to_drop_sub; 
   set _pre_vars_to_drop(where=(memname="&memname"));
  run;
  
  /* Write the variable list out into a string */
  proc sql noprint;
   select distinct drop_name
     into :drop_nm separated by ' '        
     from _pre_vars_to_drop_sub
    order by drop_name;
  quit;
  
  /* Delete all non-needed variables for current dataset loop */
  proc sql noprint;
   alter table pre_sdtm.&memname &drop_nm ; 
  quit; 
  
 %end; 
%end;

/* Clean up the work datasets, including any previous ones kept until this stage */
%if &sysenv=BACK %then %do;  

/* BJC004 : remove tidy up of _pre_vars_to_drop */

%tu_tidyup(
 rmdset = _pre_add_hc:,
 glbmac = none
);

%tu_tidyup(
 rmdset = _pre_copy:,
 glbmac = none
);
%end;

%mend tu_sdtmconv_pre_drop_vars;
