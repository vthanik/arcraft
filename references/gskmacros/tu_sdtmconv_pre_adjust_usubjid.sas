/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_adjust_usubjid
|
| Macro Version/Build:  4 build 1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 08-Feb-2011 
|
| Macro Purpose:        To pre-process and verify SUBJID and USUBJID
|
| Macro Design:         Procedure
|
| Input Parameters:
| 
| NAME                  DESCRIPTION                                  DEFAULT           
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
| (@)tu_chkvarsexist
| (@)tu_sdtmconv_sys_message
|
| Example:
|
| %tu_sdtmconv_pre_adjust_usubjid
|
|*******************************************************************************
| Change Log:
|
| Modified By                 : Bruce Chambers
| Date of Modification        : 15 May 2011
| New Version/Build Number    : 2/1
| Reference                   : BJC001
| Description for Modification: Enhance SQL where clause to exclude null usubjids
|                               Correct one if clause
| Reason for Modification     : Avoid one possible error
|
| Modified By                 : Bruce Chambers
| Date of Modification        : 5 Apr 2012
| New Version/Build Number    : 3/1
| Reference                   : BJC002
| Description for Modification: Create work dataset with all datasets and usubjids for debugging
| Reason for Modification     : Faster debugging
|
| Modified By                 : Bruce Chambers
| Date of Modification        : 5 Oct 2012
| New Version/Build Number    : 3/1
| Reference                   : BJC003
| Description for Modification: Upgrade current WARNING to ERROR to abort when flag any datasets with missing usubjids
| Reason for Modification     : Avoid a massive study_t<n> dataset that will eat up all of /saswork
|
| Modified By                 : Bruce Chambers
| Date of Modification        : 15 Feb 2013
| New Version/Build Number    : 4/1
| Reference                   : BJC004
| Description for Modification: Amend USUBJID format from z7 to z6 
| Reason for Modification     : To conform with R&D Information standard
|
*******************************************************************************/
%macro tu_sdtmconv_pre_adjust_usubjid(
); 

/* Get a list of the A&R datasets with USUBJID (and SUBJID). 
   NB: If only USUBJID is present (i.e. SUBJID is missing) this code will fail. 
       Unlikely scenario and if it happens the data is not IDSL compliant and not fit for purpose. */
 
proc sql noprint;
  create table _pre_adjust_USUBJID_dsets as
  select dc.memname 
  from view_tab_list vtl,
       dictionary.columns dc
  where vtl.basetabname=dc.memname
    and dc.name='USUBJID'
    and dc.libname='PRE_SDTM';
quit;  

%let usubjids=&sqlobs;

/* If all incoming datasets have USUBJID then check values are all consistent */
%if &usubjids = %eval(%tu_nobs(view_tab_list)) %then %do;
 %let _cmd = %str(%STR(RTN)OTE: All source datasets have USUBJID populated.);%tu_sdtmconv_sys_message;    
%end; 

/* If no incoming datasets have USUBJID then we have all DM SI data - so create and populate USUBJID */
   /*REMOVE STEP FROM MID_TRANS !!!! */
%if &usubjids=0 and %eval(%tu_nobs(view_tab_list)) >=1 %then %do;
 
 %let _cmd = %str(%STR(RTN)OTE: Creating USUBJID for all source datasets.);%tu_sdtmconv_sys_message;
 
 proc sql noprint; 
     select basetabname
     into :memname1 - :memname%left(%eval(%tu_nobs(view_tab_list)))
     from view_tab_list;
 quit;

 %do a=1 %to %eval(%tu_nobs(view_tab_list));
 
  data pre_sdtm.&&memname&a;
   set pre_sdtm.&&memname&a;
    length USUBJID $20;
    USUBJID=trim(left(studyid))||'.'||put(subjid,z6.); 
  run;  
 
 %end;
%end; 

/* If we have some ARDATA and some DMDATA then update the DMDATA with the appropriate USUBJID */
%if (&usubjids ^= %eval(%tu_nobs(view_tab_list))) 
          and &usubjids>=1 and %eval(%tu_nobs(view_tab_list)) >=1 %then %do;

 /* Build lists of the DMDATA(no USUBJID) and ARDATA(with USUBJID) datasets to be processed 
    NB: This doesnt always match the content of the dmdata and ardata libraries */
    
 proc sql noprint;
  select count(*) into :dmdata_n from view_tab_list where basetabname not in (select memname from _pre_adjust_USUBJID_dsets);
  select count(*) into :ardata_n from _pre_adjust_USUBJID_dsets;
 quit;
 
 proc sql noprint; 
     select basetabname
     into :dmname1 - :dmname%left(%trim(&dmdata_n))
     from view_tab_list
     where basetabname not in (select memname from _pre_adjust_USUBJID_dsets);

     select memname
     into :arname1 - :arname%left(%trim(&ardata_n))
     from _pre_adjust_USUBJID_dsets;
 quit;

 proc sql noprint;
  %do a=1 %to &ardata_n;
   create table _pre_adjust_usubjid_&&arname&a as
   select distinct STUDYID, USUBJID, SUBJID, "&&arname&a" as dataset
     from pre_sdtm.&&arname&a;  
  %end;
 quit;

 /* Create a master dataset to store unique combinations of studyid usubjid and subjid */
 /* BJC002: create _dist1 dataset for debugging - the dist later gets sorted by nodupkey and useful data lost */
 
 data _pre_adjust_usubjid_dist1;
  length STUDYID $10;
  length USUBJID $20;
  length SUBJID  8.;
  length dataset $8 ;
  set 
  %do a=1 %to &ardata_n;
    _pre_adjust_usubjid_&&arname&a    
  %end;
     ;    
 run;
 
 /* Reduce down to unique combinations */
 proc sort data= _pre_adjust_usubjid_dist1(drop=dataset) out=_pre_adjust_usubjid_dist nodupkey;
  by _all_;
 run;
 
 /* Check for if USUBJID assigned a different value to USUBJID||SUBJID - and flag if DMDATA used */
 /* BJC003: another missing USUBJID scenario to ID */
 data _pre_adjust_usubjid_diff
      _pre_adjust_usubjid_miss
      _pre_adjust_usubjid_dist; 
  set _pre_adjust_usubjid_dist;
   /* BJC001 : correct If clause */
   if USUBJID ^=trim(left(studyid))||'.'||put(subjid,z6.) and usubjid ^='' then output _pre_adjust_usubjid_diff; 
   /* BJC003: another missing USUBJID scenario to flag */
   if USUBJID ^=trim(left(studyid))||'.'||put(subjid,z6.) and usubjid ='' then output _pre_adjust_usubjid_miss; 
   output _pre_adjust_usubjid_dist;
 run;
 
 %if %eval(%tu_nobs(_pre_adjust_usubjid_diff)) >=1 %then %do;
  %let _cmd=%str(%STR(RTN)OTE: %eval(%tu_nobs(_pre_adjust_usubjid_diff)) distinct USUBJIDs differ from STUYDID.USUBJID.);%tu_sdtmconv_sys_message;
  %if &dmdata_n >=1 %then %do;
   %let _cmd=%str(%STR(RTN)OTE: &dmdata_n DM SI datasets will be updated with correct USUBJIDs );%tu_sdtmconv_sys_message;
  %end;
 %end;
 
 /* BJC003: another missing USUBJID scenario to ID */
  %if %eval(%tu_nobs(_pre_adjust_usubjid_miss)) >=1 %then %do;
  
  %let _cmd=%str(%STR(RTE)RROR: %eval(%tu_nobs(_pre_adjust_usubjid_miss)) missing USUBJIDs - see .lst file);%tu_sdtmconv_sys_message;
  proc sql noprint;
   create table miss_usubjids as 
   select dataset, subjid 
     from _pre_adjust_usubjid_dist1
	where usubjid is null;
  quit;	
  
  proc print data=miss_usubjids;
  title1 "Missing USUBJIDs - must be resolved to continue";
  run;
  
  %let syscc=999;
 %end;
 
 /* Update the DMDATA/SI (non-USUBJID) sets with the relevant USUBJIDs */
 /* BJC001 - add where usubjid is not null to where clause  */
 
  proc sql noprint;
   %do a=1 %to &dmdata_n;
     alter table pre_sdtm.&&dmname&a add USUBJID char(20);
     
     update pre_sdtm.&&dmname&a dm set usubjid=(select usubjid
       from _pre_adjust_usubjid_dist
      where subjid=dm.subjid
        and studyid=dm.studyid
		and usubjid is not null);        
        
     select count(*) into :miss_&&dmname&a
       from pre_sdtm.&&dmname&a
      where usubjid is null;            
     
   %end;
  quit;

  /* Notify of any PRE_SDTM records that did not get a USUBJID assigned */
  %do a=1 %to &dmdata_n;   
   %let dsname=&&dmname&a;   
   %if &&miss_&dsname >=1 %then %do;
    /* BJC003: upgrade warning to error for this scenario - set syscc flag to abort system  */
    %let _cmd=%str(%STR(RTE)RROR: &&miss_&dsname USUBJIDs cannot be updated in &&dmname&a DM SI dataset. Investigate. );
	%tu_sdtmconv_sys_message;
	%let _cmd=%str(All rows for all datasets must have USUBJID present to be processed further.  );
	%tu_sdtmconv_sys_message;
	%let _cmd=%str(Recommended quick fix. Assign USUBJID in DEMO dataset in pre_adjust. [Assumes DEMO has all subjects].);
	%tu_sdtmconv_sys_message;
	%let syscc=999;
   %end;
  %end;
 
%end;          

%if &sysenv=BACK %then %do;  

%tu_tidyup(
rmdset = _pre_adjust_usubjid:,
glbmac = none
);
%end;


%mend tu_sdtmconv_pre_adjust_usubjid;
