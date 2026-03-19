/******************************************************************************* 
|
| Macro Name: tu_sdtmconv_mid_flip_si
|
| Macro Version/Build: 4/1
|
| SAS Version: SAS 9.1.3
|
| Created By: Bruce Chambers
|
| Date:            12-Aug-2009
|
| Macro Purpose: For each source dataset prepare to call the next macro that will
|                transpose the data into a normalised structure
|
|                Add records to varmap for potential --CAT grouping identifiers
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
| (@) tu_nobs
| (@) tu_sdtmconv_mid_append_irp
| (@) tu_sdtmconv_sys_error_check
| (@) tu_sdtmconv_sys_message
|
| Example:
|         %tu_sdtmconv_mid_flip_si;
|
|******************************************************************************* 
| Change Log 
|
| Modified By:                 Bruce Chambers
| Date of Modification:        17May2010
| New Version/Build Number:    2/1
| Reference:                   BJC001 
| Description for Modification:Keep list of datasets/variables/attributes in pre_sdtm library
| Reason for Modification:     Use to subset data later for efficiency and for
|                              define.xml VLM attributes
|
| Modified By:                 Bruce Chambers
| Date of Modification:        12May2011
| New Version/Build Number:    3/1
| Reference:                   BJC002
| Description for Modification:Clean up pre_sdtm copy at each dataset iteration, not all at the end                              
| Reason for Modification:     Clean up as we go along - use disk space more efficiently for mega studies
|
| Modified By:                 Bruce Chambers
| Date of Modification:        12May2011
| New Version/Build Number:    3/1
| Reference:                   BJC003
| Description for Modification:Move check for any COL2 columns (bad transpose) to earlier as datasets get cleaned up
|                              Move creation of pre_sdtm reference dataset to earlier
| Reason for Modification:     Ensure any data uniqueness problems are spotted 
|
| Modified By:                 Bruce Chambers
| Date of Modification:        12Aug2012
| New Version/Build Number:    4/1
| Reference:                   BJC004
| Description for Modification:Only process PRE_SDTM library datasets with >=1 rows
| Reason for Modification:     Metadata augmented to include empty datasets as details needed for eCRF auto-annotation
|                              However, we only need to process past this point datasets with rows present.
|
| Modified By:                 Bruce Chambers
| Date of Modification:        07Oct2012
| New Version/Build Number:    4/1
| Reference:                   BJC005
| Description for Modification:Check for duplicates in varmap by si_dset, si_var
| Reason for Modification:     Ensure the transpose steps will run. remove affected rows from driver varmap and data
|                              Inform user but continue to process all other data
|
********************************************************************************/ 

%macro tu_sdtmconv_mid_flip_si(
);

** Only process data in the current run - may not be whole study **;
proc sql noprint;

 delete from view_tab_list 
  where basetabname not in (select distinct si_dset from varmap);
 
alter table view_tab_list add recs numeric;
 
 /* BJC004 - ensure datasets created by register also have nobs */		 
 update view_tab_list a set nobs=(
 select nobs from sashelp.vtable
  where libname='PRE_SDTM'
  and memname=a.basetabname)
where nobs is null;		 

 update view_tab_list vtl set recs=(select (nobs*nvar) as recs from dictionary.tables dt
       where vtl.basetabname=dt.memname
         and dt.libname='PRE_SDTM');
quit;
   
%if %eval(%tu_nobs(view_tab_list))=0 %then %do;

 %let _cmd = %str(%STR(RTE)RROR: Aborting : No datasets/subjects to map.); %tu_sdtmconv_sys_message;
 %let syscc=999;
 %tu_sdtmconv_sys_error_check;
%end;

/* BJC001 - keep a record of the pre_sdtm data that was present (now moved to earlier) */
proc sql noprint;
 create table pre_sdtm as 
 select memname , name, trim(type)||' '||trim(format) as src_data_type
   from dictionary.columns
  where libname='PRE_SDTM';
quit;  

/* BJC005: check varmap for duplicates and remove before attempting transpose */

proc sort data = varmap noduplicate;
by _all_;
run; 

/* any remaining dups are probably incorrectly defined/duplicted differing ORIGIN values */
proc sql;
create table varmap_dups as
select distinct si_dset, si_var, count(*)
from varmap
where si_dset in (select basetabname from view_tab_list where nobs >=1)
group by si_dset, si_var
having count(*)>=2;
quit;

%if %eval(%tu_nobs(varmap_dups))>=1 %then %do; 
 %let _cmd = %str(%STR(RTW)ARNING: Duplicate mappings present - see driver.lst file.); %tu_sdtmconv_sys_message;
 %let _cmd = %str(varmap rows for these variables will be removed so all other data will process); %tu_sdtmconv_sys_message;
 %let _cmd = %str(Investigate cause,rectify and re-run.); %tu_sdtmconv_sys_message;
 
 proc sql noprint;
  create table dup_data_print as 
  select si_dset, si_var, domain, sdtm_var, origin, suppqual
    from varmap
	where trim(si_dset)||trim(si_var) in (select trim(si_dset)||trim(si_var) from varmap_dups);
  delete from varmap 
   where trim(si_dset)||trim(si_var) in (select trim(si_dset)||trim(si_var) from varmap_dups);
 quit;
 
 proc print data=dup_data_print;
 title3 "SDTM conversion: Duplicate varmap rows: si_dset and si_var are unique keys";
 run;
 
 /* Drop affected columns from the pre_sdtm version of the dataset */
 proc sql noprint;
  select si_dset, si_var
    into :si_dset1 - :si_dset%left(%trim(%eval(%tu_nobs(varmap_dups)))),
         :name1 - :name%left(%trim(%eval(%tu_nobs(varmap_dups))))
    from varmap_dups;
 quit;

  %do a=1 %to %eval(%tu_nobs(varmap_dups));
     proc sql noprint;
	  alter table pre_sdtm.&&si_dset&a drop &&name&a;
     quit; 
  %end; 
%end;
/* End of BJC005 change */

/* To prevent lots of big reads and writes, process smaller volume datasets first */   
proc sort data=view_tab_list;
by recs;

/* BJC004 : view_tab_list now also has empty data groups as varmap metadata needed for eCRF autoannotation
   libname='' are pseudo datasets added by the system - none will have 0 rows if they get added to view_tab_list
   However the datasets with 0 rows dont need processing beyond this point */   
data view_tab_list1;
 set view_tab_list(where=(nobs>=1 or libname='')) end=last;
 num=_n_;
 if last then call symput('nflip' , _n_ );
run;

/* Drop the nobs as no longer needed and not in MONITOR table in MSA database */
data view_tab_list(drop=nobs);
 set view_tab_list;
 num=_n_;
run;

** Iterate through each dataset and transpose source data **;

%DO z=1 %TO &nflip;


 data _null_ ;set view_tab_list1;
  where num=&z;
  call symput('si_dset',trim(basetabname));
 run;

  %if %eval(%tu_nobs(pre_sdtm.&si_dset))>=1 %then %do;  

    %tu_sdtmconv_mid_append_irp(
                  ds      = &si_dset
                               );

    /* BJC003: data integrity check - check for any data that has not transposed correctly (moved from a later stage) */

    proc sql noprint;
     create table dup_data as 
     select memname from dictionary.columns
     where libname='MID_SDTM' and memname="&si_dset._T"
      and name='COL2';
    quit;

    %if %eval(%tu_nobs(dup_data))>=1 %then %do;
       %let _cmd = %str(%STR(RTE)RROR: data with inadequate system keys for uniqueness - report to developers);%tu_sdtmconv_sys_message;
       proc print data=dup_data;
        title3 "SDTM conversion: Duplicate source data in system table - report to developers";
       run;
    %end;							   
							   
    %tu_sdtmconv_sys_error_check;

	/* BJC002: move clean up step from end of the loop to run in each loop using SELECT statement*/
    /* Delete temporary PRE_SDTM datasets used in this macro if __UTC_WORKPATH */
    /* is not used to redirect to external unix directory.                     */
    %if &sysenv=BACK and %symexist(__utc_workpath) eq 0 %then %do;  

     proc datasets library=pre_sdtm memtype=DATA nolist ;
     delete &si_dset;
	 quit; 

    %end;
	
  %end;
%end;

%mend tu_sdtmconv_mid_flip_si;
