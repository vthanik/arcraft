/******************************************************************************* 
|
| Macro Name: tu_sdtmconv_sys_print
|
| Macro Version/Build: 11 Build 1
|
| SAS Version: SAS 9.1.3
|
| Created By: Bruce Chambers
|
| Date:            12-Aug-2009
|
| Macro Purpose: Collect together and report the various meta-datasets of conversion 
|                issues that have been collated during the SDTM transformation
|
|                List out as an FYI any study specific mappings applied for a study
|
| Macro Design:  Procedure
|
| Input Parameters:
|
|    None
|
| Output:
|    sdtm_issues dataset
|
| Global macro variables created:
| 
|
| Macros called:
| (@)tu_nobs
| (@)tu_sdtmconv_sys_message
| (@)tu_tidyup
|
| Example:
|
|******************************************************************************* 
| Change Log 
|
| Modified By: 			Bruce Chambers
| Date of Modification: 	08March2010
| New Version/Build Number:	1 Build 2
| Description for Modification: Database field changed, update related attributes in this code
| Reason for Modification: 	As above
|
| Modified By: 			Bruce Chambers
| Date of Modification: 	19July2010
| New Version/Build Number:	2 Build 1
| Reference:                    bjc001
| Description for Modification: Correction of item name in debug dataset
| Reason for Modification: 	As above
|
| Modified By: 			Bruce Chambers
| Date of Modification: 	09august2010
| New Version/Build Number:	3 Build 1
| Reference:                    bjc002
| Description for Modification: Move the clean up of CT issue to the codelist_recon macro
| Reason for Modification: 	To be able to report and issue warnings/erros on the CT issues in one place.
|
| Modified By: 			Bruce Chambers
| Date of Modification: 	13august2010
| New Version/Build Number:	3 Build 1
| Reference:                    bjc003
| Description for Modification: Title of a proc print was being truncated - correct this
| Reason for Modification: 	To give clear header to each listing page.
|
| Modified By: 			Bruce Chambers
| Date of Modification: 	13august2010
| New Version/Build Number:	3 Build 1
| Reference:                    bjc004
| Description for Modification: List missing IDVARVAL entries in SUPP domains as MUST DOs
| Reason for Modification: 	To ensure SDTM domains are fit for purpose. IDVARVAL is only Core=Exp as 
|                               it is not used in DM domain, for all others it is really Req.
|
| Modified By: 			Bruce Chambers
| Date of Modification: 	13august2010
| New Version/Build Number:	3 Build 1
| Reference:                    bjc005
| Description for Modification: Differentiate overrides and study specific varmap entries
| Reason for Modification: 	For user clarity in output listings 
|
| Modified By: 			Bruce Chambers
| Date of Modification: 	17august2010
| New Version/Build Number:	3 Build 1
| Reference:                    bjc006
| Description for Modification: Provide an overall and high level mapping summary
| Reason for Modification: 	For user clarity in output listings 
|
| Modified By: 			Bruce Chambers
| Date of Modification: 	17august2010
| New Version/Build Number:	3 Build 1
| Reference:                    bjc007
| Description for Modification: Add output from TA, TI and TV cross checks and SI_NEW_IN_AR check
| Reason for Modification: 	To give output that cross checks TD vs CRF domain content 
|
| Modified By: 			Bruce Chambers
| Date of Modification: 	25august2010
| New Version/Build Number:	3 Build 1
| Reference:                    bjc008
| Description for Modification: Add RT output to flag any remaining must dos in the LOG as RT-WARNING.
| Reason for Modification: 	Accurate and useful log file.Cant flag as ER-ROR as some are unresolvable 
|                               and need to be documented as such in SCPA
|
| Modified By: 			Bruce Chambers
| Date of Modification: 	06sep2010
| New Version/Build Number:	3 Build 1
| Reference:                    bjc009
| Description for Modification: Flag exemption (_X) variables clearly as such when unmapped.
| Reason for Modification: 	Accurate and useful output listing
|
| Modified By: 			Ashwin Venkat
| Date of Modification: 	15sep2010
| New Version/Build Number:	3 Build 1
| Reference:                    VA001
| Description for Modification: VA001 - display number of null values and total columns in dataset
| Reason for Modification: 	
|
| Modified By: 			Bruce Chambers
| Date of Modification: 	04November2010
| New Version/Build Number:	4 Build 1
| Reference:                    bjc010
| Description for Modification: add _report_ta_issues3 if present to user listing
| Reason for Modification: 	Complete set of issues output
|
| Modified By: 			Bruce Chambers
| Date of Modification: 	22November2010
| New Version/Build Number:	5 Build 1
| Reference:                    bjc011
| Description for Modification: Clarify listing header for varmap overrides
| Reason for Modification: 	Clarity for user
|
| Modified By: 			Bruce Chambers
| Date of Modification: 	22November2010
| New Version/Build Number:	5 Build 1
| Reference:                    bjc012
| Description for Modification: Add any output from SV_finisher macro
| Reason for Modification: 	Complete set of issues output
|
| Modified By: 			Bruce Chambers
| Date of Modification: 	14Jan2011
| New Version/Build Number:	5 Build 1
| Reference:                    bjc013
| Description for Modification: Flag unmapped T(PERIOD) items as MUST-DOs
| Reason for Modification: 	Correct set of issues output
|
| Modified By: 			Bruce Chambers
| Date of Modification: 	01Feb2011
| New Version/Build Number:	5 Build 1
| Reference:                    bjc014
| Description for Modification: List out study review varmap issues
| Reason for Modification: 	Complete set of issues output
|
| Modified By: 			Ashwin Venkat
| Date of Modification: 	02Feb2011
| New Version/Build Number:	5 Build 1
| Reference:                    va002
| Description for Modification: List out SI/AR row count discrpancy issues
| Reason for Modification: 	Complete set of issues output
|
| Modified By: 			Bruce Chambers
| Date of Modification: 	04Feb2011
| New Version/Build Number:	5 Build 1
| Reference:                    bjc015
| Description for Modification: Add if exist logic to allow for less metadatasets when in CHECK mode
| Reason for Modification: 	Complete set of issues output and clean execution of code
|
| Modified By: 			Ashwin Venkat(va755193)
| Date of Modification: 	21Apr2011
| New Version/Build Number:	6 Build 1
| Reference:                    va003
| Description for Modification: export SDTM_ISSUES work dataset to issues.csv file and save in refdata
| Reason for Modification: 	this is to save time when updating issues excel sheet
|
| Modified By: 			Ashwin Venkat(va755193)
| Date of Modification: 	11May2011
| New Version/Build Number:	6 Build 1
| Reference:                    va004
| Description for Modification: issue RTWARNING with number of DRAFT mapping in varmap
| Reason for Modification: 	    Once the study moves to ARPROD, draft entry will not be used so needs to be fixed.
|
| Modified By: 			        Deepak Sriramulu(dss27908)
| Date of Modification: 	    29July2011
| New Version/Build Number:	    7 Build 1
| Reference:                    DSS001
| Description for Modification: Append * to all the --BLFL flags where they are expected and have null values.
| Reason for Modification: 	    Baseline information is a must, as per FDA guide line
|
| Modified By: 			         Ashwin Venkat(va755193)
| Date of Modification: 	     4Aug2011
| New Version/Build Number:	     7 Build 1
| Reference:                     VA005
| Description for Modification:  Must-do rtwarning is given even when there are no must-do issues.
| Reason for Modification: 	     Must-do rtwarning should only appear when there are must-do issue
|
|
| Modified By: 			         Ashwin Venkat(va755193)
| Date of Modification: 	     15May2012
| New Version/Build Number:	     8 Build 1
| Reference:                     VA006
| Description for Modification:  Flag any SDTM dataset that is larger then 1GB, and give a warning to split data
| Reason for Modification: 	     Request S&P to create datasets smaller than 1GB by splitting dataset by --CAT --SCAT
|
| Modified By: 		             Ashwin Venkat(va755193)
| Date of Modification: 	     2Aug2012
| New Version/Build Number:	     8 Build 1
| Reference:                     VA007
| Description for Modification:  Added more details to issues.csv file 
| Reason for Modification: 	     This is to save time when updating issues excel sheet
|
| Modified By: 			         Bruce Chambers
| Date of Modification: 	     14Aug2012
| New Version/Build Number:	     8 Build 1
| Reference:                     BJC016
| Description for Modification:  Filter warning on Draft varmap rows to exlcude rows where: ADDED in ('E','Z')
| Reason for Modification: 	     users cant approve rows in MSA if dataset is empty. Need data to review/approve
|
| Modified By: 			         Bruce Chambers
| Date of Modification: 	     07Oct2012
| New Version/Build Number:	     8 Build 1
| Reference:                     BJC017
| Description for Modification:  VARMAP_MRG now has all potential data mappings - including those for empty datasets
|                                This bigger picture is for later eCRF re-annoation and define.xml use.
| Reason for Modification: 	     Users only need to remediate issues and study review items etc for data present.
|                                Create a varmap_present for data that is present only to reduce user listing size.
|
| Modified By: 			         Bruce Chambers
| Date of Modification: 	     13Mar2013
| New Version/Build Number:	     9 Build 1
| Reference:                     BJC018
| Description for Modification:  Allow for null EXEMP values - amend check to ^='Y'
| Reason for Modification: 	     Users get more informative issue output.
|
| Modified By: 			         Ashwin Venkat(va755193)
| Date of Modification: 	     23May2013
| New Version/Build Number:	     10 Build 1
| Reference:                     AV009
| Description for Modification:  Modified label of study specific mapping report
| Reason for Modification: 	     Modified label of study specific mapping report
|
| Modified By: 			         Bruce Chambers
| Date of Modification: 	     25Jun2013
| New Version/Build Number:	     11 Build 1
| Reference:                     BJC019
| Description for Modification:  output code relied on all domains having usubjid - remove reliance
| Reason for Modification: 	     TD domains may be included in /sdtm directory (for check mode)
|
********************************************************************************/ 

%macro tu_sdtmconv_sys_print(
);

/* BJC017 - create a varmap_present dataset with any records for empty datasets removed.
   Amend all later references in this program from varmap_mrg to varmap_present */
proc sql noprint;
 create table varmap_present as 
 select * from varmap_mrg
  where si_dset in (select basetabname from view_tab_list where recs >=1);
quit; 

/* BJC014: create varmap_sr to print varmap.csv rows that are for study review */
%if %sysfunc(exist(varmap_present)) %then %do;

 data _report_varmap_sr(keep=si_dset si_var problem_desc); 
   attrib si_var length=$8 format=$8. ;
   attrib si_dset length=$8 format=$32.;
  set varmap_present(where=(study_review='Y'));
   attrib problem_desc length=$60;
   problem_desc='Variable mapping flagged as Study Review - please check data';
 run;  
%end;

/* End of BJC014 */

%if not %sysfunc(exist(varmap_ss)) %then %do;
 %let _cmd = %str(No study specific varmap entries found for this run);%tu_sdtmconv_sys_message;
%end;

%if %sysfunc(exist(varmap_ss)) and %sysfunc(exist(varmap_present)) %then %do;

 /* If a subset run then remove non-applicable rows */
 %if &tab_list ne or &tab_exclude ne or %length(&subset_clause)^=0 %then %do;

  /* BJC005: use varmap_present to source varmap.csv rows from as that dataset has the SS flag/column */
  proc sql noprint;
   delete from varmap_present where si_dset not in (select basetabname from view_tab_list)
                              and si_dset not in (select si_dset from varmap_ss);
  quit;
  
 %end;
/* AV009: Modified label of study specific mapping report*/

  /* BJC005: use varmap_present to print varmap.csv rows from as that dataset has the SS flag/column.
  / Create dataset to list of only original varmap.csv file entries */
  data varmap_lst;
   set varmap_present(where=(SS^=''));
   sts = ss; /*AV009:creating a copy of SS variable, this will be used during printing of report*/
  run;  

 %if %eval(%tu_nobs(varmap_lst))>=1 %then %do;
 
  /* bjc003: correct the title length */
  /* BJC005: use varmap_present to print varmap.csv rows from as that dataset has the SS flag/column*/
  /* BJC011 : update label for ss column with newly created values */
  
  proc sort data=varmap_lst;
  by sts ss si_dset si_var;
  run;
  /* AV009: Modified label of study specific mapping report to "mapping type"*/
  proc print data=varmap_lst noobs label split='*' width=minimum;
  title3 "SDTM conversion: &g_study_id Listing of Study specific varmap mappings present";
  title4 "for the following SI dataset-items :";
  var ss si_dset si_var ;
  by sts;
  label si_dset='Source dataset';
  label sts = 'Mapping Type';
  label si_var='Source variable';
  label ss='S=Study specific * O=Override of Approved MSA entry * A=Matching Draft MSA row needing approval * X=MSA draft row match with diff attribs (by si_dset,si_var)';
  run;
  
 %end; 
%end;

%if not %sysfunc(exist(si_rules_ss)) %then %do;
 %let _cmd = %str(No study specific si_rules entries found for this run);%tu_sdtmconv_sys_message;
%end;

%if %sysfunc(exist(si_rules_ss)) %then %do;

 /* If a subset run then remove non-applicable rows */
 %if &tab_list ne or &tab_exclude ne or %length(&subset_clause)^=0 %then %do;

  proc sql noprint;
   delete from si_rules_ss where si_dset not in (select basetabname from view_tab_list);
  quit;
  /* tu_nobs wont pick up _n_ changes from proc sql so write a new dataset with a datstep */
  data si_rules_ss; set si_rules_ss;
  run;  
 %end;

 %if %eval(%tu_nobs(si_rules_ss))>=1 %then %do;
 
  /* bjc003: correct the title length */
  proc print data=si_rules_ss noobs label;
  title3 "SDTM conversion: &g_study_id Listing of Study specific si_rules mappings present";
  title4 "for the following SI datasets :";
  var si_dset;
  label si_dset='Source dataset';
  run;
  
 %end; 
%end;

*************************************************************************************;
/* for datasets that come from the source data (and are not domain based) update the domain 
/  they correspond to into the reporting dataset */
/* bjc007: add update for si_new_in_ar to update domain values into the data */
/* bjc015: add if sysfunc exists clauses for those datasets not present in CHECK mode */

proc sql;
 %if %sysfunc(exist(_report_no_map)) %then %do;
  alter table _report_no_map add memname char(12);
 
  update _report_no_map a set memname=
   (select min(domain)
      from sdtm_dom b
     where a.si_dset=b.si_dset and b.domain ne 'CO');
 %end;
 
 %if %sysfunc(exist(_report_missing_si_items)) %then %do;
  alter table _report_missing_si_items add memname char(12);

  update _report_missing_si_items a set memname=
   (select min(domain)
      from sdtm_dom b
     where a.si_dset=b.si_dset and b.domain ne 'CO');
 %end; 
 
 /*VA002: adding domain to _report_mismatching_si_rows dataset*/
 %if %sysfunc(exist(_report_mismatching_si_rows)) %then %do;
  alter table _report_mismatching_si_rows add memname char(12);

  update _report_mismatching_si_rows a set memname=
   (select min(domain)
      from sdtm_dom b
     where a.si_dset=b.si_dset and b.domain ne 'CO');
 %end; 
 
 %if %sysfunc(exist(_report_si_new_in_ar)) %then %do;
  alter table _report_si_new_in_ar add memname char(12);

  update _report_si_new_in_ar a set memname=
   (select min(domain)
      from sdtm_dom b
     where a.si_dset=b.si_dset and b.domain ne 'CO');
 %end;  
 
 /*BJC014: adding domain to _report_varmap_sr dataset*/
 %if %sysfunc(exist(_report_varmap_sr)) %then %do;
 
  alter table _report_varmap_sr add memname char(12);

  update _report_varmap_sr a set memname=
   (select min(domain)
      from sdtm_dom b
     where a.si_dset=b.si_dset and b.domain ne 'CO');  
 %end; 
quit;
*************************************************************************************;
** Produce main issues listing from various sub-metadatasets **;

/* bjc015: add if sysfunc exists clauses for those datasets not present in CHECK mode */
data sdtm_issues;
set invalid_vars(in=a)
    missing_vars(in=b)
    %if %sysfunc(exist(_report_no_map)) %then %do;
     _report_no_map(in=c)
    %end; 
    _report_length_issues(in=e)
    _report_len_issue_detail(in=f) 
    _report_flag_items(in=g rename=(si_dset=memname))
    _report_drop_items(in=h rename=(si_dset=memname) where=(name not in ('VISIT','VISITNUM')) )
    %if %sysfunc(exist(_report_collect)) %then %do;
      _report_collect (in=i)
    %end;         
    _report_dup_dsets(in=j where=(memname^='')) 
    %if %sysfunc(exist(_report_null_test)) %then %do;
     _report_null_test(in=k where=(memname^='')) 
    %end;
    %if %sysfunc(exist(_report_missing_si_items)) %then %do;
     _report_missing_si_items(in=l)
    %end; 

    /* BJC007 add in the TD domain cross check datasets if they are present in a run */
    
    %if %sysfunc(exist(_report_tv_issues)) %then %do;
     _report_tv_issues(in=m)
    %end; 
    %if %sysfunc(exist(_report_ti_issues1)) %then %do;
     _report_ti_issues1(in=n)
    %end; 
    %if %sysfunc(exist(_report_ti_issues2)) %then %do;
     _report_ti_issues2(in=o)
    %end; 
    %if %sysfunc(exist(_report_si_new_in_ar)) %then %do;
     _report_si_new_in_ar(in=p)
    %end; 
    %if %sysfunc(exist(_report_ta_issues1)) %then %do;
     _report_ta_issues1(in=q)
    %end; 
    %if %sysfunc(exist(_report_ta_issues2)) %then %do;
     _report_ta_issues2(in=r)
    %end; 

    /* BJC010 : add _report_ta_issues3 to output if present */
    %if %sysfunc(exist(_report_ta_issues3)) %then %do;
     _report_ta_issues3(in=s)
    %end; 

    /* BJC012 : add _report_sv_issues to output if present */
    %if %sysfunc(exist(_report_sv_issues)) %then %do;
     _report_sv_issues(in=t)
    %end;
    
    /* VA002: add issues with mismatching SI & A+R dataset rows*/
     %if %sysfunc(exist(_report_mismatching_si_rows)) %then %do;
     _report_mismatching_si_rows(in=u)
    %end;
    
    /* BJC014 : add _report_varmap_sr to output if present */
    %if %sysfunc(exist(_report_varmap_sr)) %then %do;
     _report_varmap_sr(in=v rename=(si_var=name))
    %end;
    
    ;
    attrib problem_desc length=$60;
     
    if a then problem_desc='* Invalid column in domain';
    else if b and core='Req' then problem_desc='* '||trim(core)||' variable missing from domain, not added';
    else if b and core='Exp' then problem_desc=trim(core)||' variable missing from domain, empty column added';
    
    /* BJC013 - flag unmapped T(PERIOD) items as MUST-DOs */
    else if c and name ='PERIOD'  then problem_desc='* PERIOD must be mapped to SDTM EPOCH';
    else if c and name ='TPERIOD' then problem_desc='* TPERIOD must be mapped to SDTM EPOCH';

    /* BJC009 - flag exemption (_X) variables as such in output */
	/* BJC018: Allow for null EXEMP values - amend check to ^='Y' */
    else if c and dm_subset_flag='Y' and exemp^='Y' then problem_desc='* IDSL SI item in source data and not in SDTM maps';
    else if c and dm_subset_flag='Y' and exemp='Y' then problem_desc='* IDSL SI (_X) item in source data and not in SDTM maps';    
    else if c and ar_subset_flag='Y' and exemp^='Y' then problem_desc='FYI:IDSL A+R item present and wont be mapped to SDTM';    
    else if c and ar_subset_flag='Y' and exemp='Y' then problem_desc='FYI:IDSL A+R (_X) item present and wont be mapped to SDTM';    

    else if c and missing(dm_subset_flag) and missing(ar_subset_flag) then 
                   problem_desc='FYI:Non-IDSL data item in source data and will not be mapped to SDTM';
    /* VA001 - display number of null values and total columns */
    else if g and type='Req' then problem_desc='* '||trim(type)||' column with null values: '||trim(left(put(item_count,8.))) ||' out of '||trim(left(put(total,8.))) ;
    /* BJC004 - process IDVARVAL to flag as MUST DO if missing for any domain but DM */
    else if g and type='Exp' then do;
      if memname=:'SUPP' and name='IDVARVAL' then problem_desc='* '||trim(type)||' column with null values: '||trim(left(put(item_count,8.))) ||' out of '||trim(left(put(total,8.))) ;
      else problem_desc=trim(type)||' column with null values: '||trim(left(put(item_count,8.))) ||' out of '||trim(left(put(total,8.))) ;
    end; 
    else if h then problem_desc='Permitted empty items that were dropped';       
run;

%if %eval(%tu_nobs(sdtm_issues))=0 %then %do;
  data _report_noprin;
    comment = "There are no data issues found by this tool for data in this run";
  run;

  proc print data=_report_noprin noobs label;
       label comment = ' ';
       title3 'No issues found in this run';
  run;
%end;

%if %eval(%tu_nobs(sdtm_issues))>=1 %then %do;

 ** Format issues in a better format so they can be managed **;

 data sdtm_issues;
   attrib name    length=$30 format=$9.;
   attrib memname length=$30 format=$8.;
   attrib problem_desc_full length=$100;
  set sdtm_issues;
  if problem_desc_full='' then problem_desc_full=problem_desc;
  if memname=:'SUPP' then do;
   si_dset='SUPP';
   memname=substr(memname,5,length(memname)-4);
  end;
  if si_dset='' then si_dset='DOMAIN';
  
  /* DSS001:  if baseline flag is marked as expected then issue a Must-Do ,as baseline information is a must, as per FDA guide line */
  if reverse(strip(name)) =: "LFLB" and upcase(core) eq 'EXP' then do;
       problem_desc = '* ' || strip(problem_desc);
       problem_desc_full = '* ' || strip(problem_desc_full);
  end;
 run; 

 /* BJC002: Move clean up step of CT issues to codelist_recon macro */

 proc sort data=sdtm_issues;
  by memname si_dset ordervar name ;
 run;

/* VA003: create issue.csv file from sdtm_issues dataset */
/* VA007: Added more details to issue.csv file */
proc sort data = varmap(keep = si_var si_dset sdtm_var specification_details rename=(si_var=name)) out = issue_varmap;
    by si_dset name ;
run;

proc sort data = sdtm_issues out = sdtm_issues_s;
    by  si_dset name;
run;

data sdtm_issues_s;
    merge sdtm_issues_s(in = a)  issue_varmap;
        by si_dset name;
        if a;
run;


data sdtm_issues_csv(keep = name memname problem_desc_full core comments libname si_dset owner);
    length owner $30;
    length  comments $200;
    length name $8;
	set sdtm_issues_s;

   if index(problem_desc_full,'FYI') gt 0 then do ;
        owner = "FYI Only";
        comments = "FYI Only";
    end;

   if index(problem_desc_full,'* Exp variable missing from domain') gt 0 and index(name,'BLFL') then do;
    owner = "Programmer/Study team";
    comments='please give baseline visit information';
   end;

   if index(problem_desc_full, 'Variable mapping flagged as Study Review') gt 0 then do;
    owner = "Programmer/Study team";
    comments= specification_details;
   end;

   if index(problem_desc_full, 'Duplicate sets of keys-see earlier listing section') gt 0 then do;
    owner = 'Programmer/Study team/DSO';
   end;

   /*remove newline char*/
   comments = compress(comments,,'kw');
   name = compress(name);
run;
/*decode SDTM variables with missing value to its SI variable for easy varification*/

proc sort data = varmap(keep = sdtm_var si_var rename=(sdtm_var=name)) out = varmap_si;
    by name;
    where not missing(name);
run;

proc sort data = sdtm_issues_csv ;
    by name;
run;

data sdtm_issues_csv req;
    merge sdtm_issues_csv(in = a) varmap_si;
        by name;
        if a ;

   if index(problem_desc_full, 'Exp column with null values:' ) gt 0 then do;
    owner = 'Programmer/Study team';
    comments = compress(si_var) ||" has missing values please check";
   end;

    if index(problem_desc_full, '* Req column with null values:') then do;
    owner = 'Study team';
    output req;
    end;

    if index(problem_desc_full, 'Exp variable missing from domain, empty column added') and index(name,'BLFL') eq 0 then do;
    owner = 'Programmer/Study team';
    comments = 'missing ' || compress(si_var) || ', please derive or explain reason for missing variable';
   end;

   output sdtm_issues_csv;
run;

data miss_f ;
    attrib name length=$8
           usubjid length=$20;
    stop;
run;
;

run;
%if %eval(%tu_nobs(req)) >= 1 %then %do;

    %do i =1 %to %eval(%tu_nobs(req));
    data _null_;
        set req;
		/* BJC019: not all domains have USUBJID */
		if memname in ('TA','TE','TI','TS','TV') then idvar='STUDYID';
		else idvar='USUBJID';
		
        if _n_ =&i;
        call symput('memname',trim(memname));
        call symput('name',trim(name));
		/* BJC019: not all domains have USUBJID */
		call symput('idvar',trim(idvar));
    run;
    
	/* BJC019: not all domains have USUBJID */
    proc sort data = pst_sdtm.&memname (keep = &idvar &name) out = miss(keep = &idvar );
         by &idvar ;
         where missing(&name);
    Run ;

    data miss_f ;
        set miss  %if %sysfunc(exist(miss_f)) %then %do;
                    miss_f
                    %end;;
        name = compress("&name");

    run;
    %end;

%end;
/* now remove duplicates and merge with issues csv file to give subject num ber examples */

    proc sort data = miss_f nodupkey;
        by name;
    run; ;

 data sdtm_issues_csv(drop =  usubjid core libname);
 attrib SI_DSET SI_VAR MEMNAME NAME PROBLEM_DESC_FULL OWNER COMMENTS label = "issues";
    merge  miss_f(in  = b) sdtm_issues_csv(in = a);
        by name ;
        if a;
        if index(problem_desc_full, '* Req column with null values:') then do;
            comments = "for example please check (u)subjid "||compress(usubjid) ||"with missing "||compress(si_var); 
        end;

        if index(problem_desc_full, '* Req variable missing from domain') then do;
            comments = "missing "||compress(si_var) || ' variable';
            owner = 'Study team';
        end;
 run;
/*VA007 : modifying issue.csv to give more details*/

proc export data = sdtm_issues_csv
    outfile ="&g_rfmtdir/issue.csv"
    dbms=csv replace;
run;

 
 %if %eval(%tu_nobs(sdtm_issues))=0 %then %do;
  data _report_noprin;
    comment = "There are no data issues found by this tool for data in this run";
  run;

  proc print data=_report_noprin noobs label;
       label comment = ' ';
       title3 'No issues found in this run';
  run;
 %end;

 proc print data=sdtm_issues noobs label;
  label memname='Domain name'
        si_dset='Source'
        name ='Variable name'
        problem_desc='Details of problem';
  by memname si_dset;
  var name problem_desc;
  title3 "SDTM conversion issues summary for &g_study_id";
  title4 "Issues prefixed with * are MUST-DO fixes";
 run;

%end;

/* Query for and list out any domains that converted with issues and with no issues at all */
proc sql noprint;

 create table _report_fyis_only  as 
 select a.si_dset, b.memname as domain,'FYIs only' as descr  length=20 ,count_fyi as count from
  (select si_dset, memname, count(problem_desc_full) as count_all
  FROM sdtm_issues
  group by si_dset, memname) a,

  (select si_dset, memname, count(problem_desc_full) as count_fyi
  FROM sdtm_issues 
  where substr(problem_desc_full,1,3)='FYI'
  group by si_dset, memname) b
 where a.si_dset=b.si_dset
 and a.memname=b.memname
 and a.count_all=b.count_fyi;
   
 create table _report_reviews  as 
  (select si_dset, memname as domain, 'REVIEWs' as descr  length=20, count(problem_desc_full) as count
  FROM sdtm_issues 
  where substr(problem_desc_full,1,1)^='*' and substr(problem_desc_full,1,3)^='FYI'
  group by si_dset, memname);   

 create table _report_must_dos  as 
  (select si_dset, memname as domain, 'MUST DOs' as descr  length=20, count(problem_desc_full) as count
  FROM sdtm_issues 
  where substr(problem_desc_full,1,1)='*'
  group by si_dset, memname);
 
quit;

/* BJC008 : Add RT output to flag any remaining must dos. Cant flag as er-ror as some are unresolvable and need
/  to be documented as such in SCPA. 
/  Also:Switch _report_must_dos to be the last dataset generated in the above proc sql step so we can use sqlobs */

%if &sqlobs>=1 %then %do;
  %let _cmd = %str(%str(RTW)ARNING: One or more MUST-DO entries remaining. Review and correct the problems.); 
  %tu_sdtmconv_sys_message;

  %let _cmd = %str(Any remaining ones will need documenting in SCPA once study is Ready For QC.); 
  %tu_sdtmconv_sys_message;
%end;
/*VA005: moved RTWARNING for DRAFT mapping to after RTWARNING for MUST-DO*/
/*VA004: issue RTWARNING with number of DRAFT mapping in MSA, which needs to be fixed before study is run 
in ARPROD area, where DRAFT mapping will not be used*/

%if &check_only ne Y %then %do;
    /* BJC016 : add filter to exclude ADDED in ('E','Z') rows as users cant approve MSA rows if no data present */
	proc sql noprint;
		select count(*) into :num_draft 
		from varmap_present 
		where status='Draft' and added not in ('E','Z');
	quit;  

	%if &num_draft >=1 %then %do;
		%let _cmd = %str(%str(RTW)ARNING: there are %qsysfunc(compress(&num_draft)) Draft varmap rows from MSA - ensure these get approved [review study_mappings for affected rows]);%tu_sdtmconv_sys_message;
        %let _cmd = %str(NB: Draft rows applicable to empty datasets are not included in this count as cant be approved without data to review);
		%tu_sdtmconv_sys_message;
	%end;
%end;
data _report_summ_domains;
 set _report_fyis_only
     _report_must_dos
     _report_reviews;
run;

proc sql noprint;
 create table _report_ok_domains as
 select domain format=$8., si_dset format=$8. , 'No issues' as descr  length=20 from sdtm_dom
  where trim(domain) not in (select trim(domain) from _report_summ_domains)
  order by domain; 
quit;

data report_summ_domains;
 set _report_summ_domains _report_ok_domains;
run; 

proc sort data= report_summ_domains;
by domain si_dset;
run;

proc print data=report_summ_domains label noobs;
  var domain si_dset descr count;
  label domain='Domain name'
        si_dset='Source dataset'
        descr='Status summary'
        count='Number of issues';
  title3 "SDTM conversion issues summary for &g_study_id";
  title4 "Source datasets/Domains that converted with no issues reported in listing/report";
  title5 "NOTE: Any RTWARNINGS from the log may still impact these datasets -needs review";
run;

/* BJC006: Add steps to create a high level mapping summary - useful for user review */

/* Create a dataset that gives the forward link between source data and domain */
/* bjc015: only run step below when not in CHECK mode - as we wont haev the SI_DSET source details */

%if &check_only ne Y %then %do;

  proc sql noprint;
   create table _report_src_to_sdtm as 
   select distinct domain
   from sdtm_dom
   where si_dset^='SUPP';
  quit;
  %let dsobs=&sqlobs;

  proc sql noprint;
   select domain
    into :domain1- :domain%left(&dsobs)
    from _report_src_to_sdtm
   order by domain;

   alter table _report_src_to_sdtm add src char(62);
  quit;

  proc sql noprint;
    %do a=1 %to &dsobs;
      select si_dset into :src_string separated by ','
      from sdtm_dom where domain="&&domain&a" and si_dset^='SUPP'; 
    
      update _report_src_to_sdtm  set src=("&src_string") where domain="&&domain&a"; 
    %end;
  quit;

  proc sort data=_report_src_to_sdtm;
  by src;
  run;

  data _report_src_to_sdtm(drop=src domain);
   set _report_src_to_sdtm;
   type='SOURCE to SDTM';
   length string $70;
   string=trim(src)||' -> '||trim(domain);
  run; 
 
  /* Create a dataset that gives the backward link from domain back to source data */
  proc sql noprint;
   create table _report_sdtm_to_src as 
   select distinct si_dset
   from sdtm_dom
   where si_dset^='SUPP';
  quit;
  %let dsobs=&sqlobs;

  proc sql noprint;
   select si_dset
    into :si_dset1- :si_dset%left(&dsobs)
    from _report_sdtm_to_src
   order by si_dset;

   alter table _report_sdtm_to_src add dest char(62);
  quit;

  proc sql noprint;
    %do a=1 %to &dsobs;
      select domain into :dest_string separated by ','
      from sdtm_dom where si_dset="&&si_dset&a" and si_dset^='SUPP'; 
    
      update _report_sdtm_to_src set dest=("&dest_string") where si_dset="&&si_dset&a"; 
    %end;
  quit;

  data _report_sdtm_to_src(drop=dest si_dset);
   set _report_sdtm_to_src;
   type='SDTM from SOURCE';
   length string $70;
   string=trim(dest)||' <- '||trim(si_dset);
  run; 
  
  /* append the two sets of data and print for user review */

  data _report_map_summary;
   set _report_sdtm_to_src
       _report_src_to_sdtm;
  run;

  proc print data=_report_map_summary noobs label width=minimum;
  title3 "SDTM conversion: &g_study_id High level source data/domain level mapping summary";
  title4 "NB: Source datasets that split across >1 domain may need RELREC to detail links";
  title5 "A main exception being the CO domain which is self documenting in this respect";
  label type='Mapping direction'
        string='Map summary';
  by type;
  run;
 
%end;

/*VA006: if dataset is larger than 1GB then issue RTWarning and request S&P to create smaller dataset split by 
--CAT --SCAT, for easy review, while keeping the original dataset unchanged */

proc sql noprint;
	create table datasize as 
	select memname, filesize, compress(put(filesize/(1024*1024*1024),8.1)||"GB") as size  from dictionary.tables
	where libname = 'SDTMDATA' and filesize ge (1024*1024*1024)/*1gb*/
	order by memname;
quit;

 %if %eval(%tu_nobs(datasize)) gt 0 %then %do;
	%let _cmd = %str(%str(RTW)ARNING: SDTM datasets larger than 1GB found, S&P needs to create smaller datasets split by --CAT/--SCAT, check list file for details) ; 
	%tu_sdtmconv_sys_message;
	
	proc print data = datasize noobs label width = minimum;
		title3 "SDTM datasets larger than 1GB found. As per FDA guideline, S&P needs to create";
		title4 "smaller dataset split by --CAT (eg: LBCAT= URIN then create LBU DATASET)and if";
		title5 "size is still 1GB then split by --SCAT while keeping the original dataset".;
		title6 "The datasets created should be in a seperate subfolder in SDTM folder ";
		label memname="SDTM dataset"
			  size = "dataset Size";
	var memname size;
	run;
 %end;

/* Dont use tu_tidyup for the master datasets as some meta-datasets are later copied to 
/ a data store so we can review issues across studies */

%if &sysenv=BACK %then %do;  

%tu_tidyup(
 rmdset = _report_:,
 glbmac = none
);
%end;

%mend tu_sdtmconv_sys_print;
