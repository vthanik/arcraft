/******************************************************************************* 
|
| Macro Name: tu_sdtmconv_mid_norm
|
| Macro Version/Build: 6/1
|
| SAS Version: SAS 9.1.3
|
| Created By: Bruce Chambers
|
| Date:            12-Aug-2009
|
| Macro Purpose: To normalise findings domains - to split the dataset into tests (i.e 
|                those mapped to an --ORRES variable) and qualifiers e.g. timing vars 
|                and process accordingly (all those not mapped to an --ORRES variable).
|
| Macro Design:  Procedure
|
| Input Parameters:
|                   none
|
| Output:
|         mid_sdtm.&dom._&dset e.g. mid_sdtm.DS_RAND sub-domain dataset
|
| Global macro variables created:
|
|
| Macros called:
| (@) tu_nobs
| (@) tu_sdtmconv_mid_ecg_alter
| (@) tu_tidyup
| (@) tu_sdtmconv_sys_message
|
| Example:
|
|******************************************************************************* 
| Change Log 
|
| Modified By:                  Bruce Chambers
| Date of Modification:         05November2010
| New Version/Build Number:     2/1
| Reference:                    bjc001
| Description for Modification: For FA-- domains ensure the SEQ numbers are unique
| Reason for Modification:      SDTM compliance
|
| Modified By:                  Bruce Chambers
| Date of Modification:         05November2010
| New Version/Build Number:     2/1
| Reference:                    bjc002
| Description for Modification: Continue with (w)arning instead of (e)rror when only
|                               tests or qualifiers are present.
| Reason for Modification:      Programmer efficiency
|
| Modified By:                  Bruce Chambers
| Date of Modification:         05November2010
| New Version/Build Number:     3/1
| Reference:                    bjc003
| Description for Modification: Use USUBJID instead of SUBJID now that pre_adjust_subjid is present
| Reason for Modification:      Use the more differentiating key
|
| Modified By:                  Bruce Chambers
| Date of Modification:         15May2011
| New Version/Build Number:     4/1
| Reference:                    bjc004
| Description for Modification: Use tu_tidyup for more large work datasets
| Reason for Modification:      Efficient use of /saswork
|
| Modified By:                  Bruce Chambers
| Date of Modification:         03Apr2012
| New Version/Build Number:     5/1
| Reference:                    bjc005
| Description for Modification: Enable processing of scored questionnaires
| Reason for Modification:      Correct SDTM product
|
| Modified By:                  Bruce Chambers
| Date of Modification:         27Jul2013
| New Version/Build Number:     6/1
| Reference:                    bjc006
| Description for Modification: Avoid duplication of qualifiers from source rows 
|                               Allow for QS mapping to be a hybrid of regular and scored within a source dataset
| Reason for Modification:      Correct SDTM product
|
********************************************************************************/ 

%macro tu_sdtmconv_mid_norm(
);

 /* BJC005: code added to identify scored questionnaire type data that is part of code-decode pair */
 
 proc sql noprint; 
  select count(*) into :STRESN from varmap
  where domain="&dom" and si_dset="&dset"
    and substr(reverse(trim(sdtm_var)),1,5) ='NSERT'
	and si_var in (select code from dsm_var_rel);
	
	select si_var into :STRESN_str separated by '","' from varmap
  where domain="&dom" and si_dset="&dset"
    and substr(reverse(trim(sdtm_var)),1,5) ='NSERT'
	and si_var in (select code from dsm_var_rel);
 quit;	

 /* split data that need to be on all rows then transpose 
 /  and for data in correct format just rename columns    */
 
 data test&dom._&dset 
      /* BJC005: dataset added to process scored questionnaire type data */
      %if &STRESN >= 1 % then %do;
	   testn&dom._&dset
	  %end;
      qual&dom._&dset ;
  set mid_sdtm.&dom._&dset;
    if length(sdtm_var)>=5 then do;
     if substr(reverse(trim(sdtm_var)),1,5) ='SERRO' 
	 then output test&dom._&dset;  
	 
	 /* BJC005: code added to process scored questionnaire type data numeric results separately */
     %if &STRESN >= 1 % then %do;
      else if (substr(reverse(trim(sdtm_var)),1,5) ='NSERT' and si_var in ("&stresn_str"))
	  then output testn&dom._&dset;  	 
	 %end;
	 
     else output qual&dom._&dset;
    end;   
    else output qual&dom._&dset;
 run;
    
 /* bjc006 :Avoid duplication of qualifiers from source rows */
 proc sort data=qual&dom._&dset noduprecs;
  by _all_;
 run;

 proc sort data=qual&dom._&dset noduprecs;
  by studyid domain usubjid visitnum visit seq;
 run;
 
 /* tranpose qualifiers i.e. non-test (--ORRES) related data */
 proc transpose data=qual&dom._&dset
                 out=quala&dom._&dset(drop=_name_ _label_);
  by studyid domain usubjid visitnum visit seq;
     id sdtm_var;
     var col1;
 run;
  
 /* process test results */
 data testa&dom._&dset;
  set test&dom._&dset;
    by studyid domain usubjid visitnum visit seq;
    &dom_ref.TESTCD = si_var;
    &dom_ref.TEST = _label_;
    &dom_ref.ORRES = left(col1); 
    keep studyid domain usubjid visitnum visit seq 
         &dom_ref.testcd &dom_ref.test &dom_ref.ORRES;
 run;

 /* BJC005: code added to process scored questionnaire type data numeric results */
  %if &STRESN >= 1 % then %do; 
   /* process test results */
   data testna&dom._&dset;
    set testn&dom._&dset;
     by studyid domain usubjid visitnum visit seq;
     &dom_ref.TESTCD = si_var; 
     &dom_ref.TEST = _label_;
     &dom_ref.STRESN = left(col1); 
     keep studyid domain usubjid visitnum visit seq 
         &dom_ref.testcd &dom_ref.test &dom_ref.STRESN;
   run;
   
   /* Use DSM_VAR_REL dataset to link data up correctly/reliably to produce joined Product of the
      numeric and character results from code/decode pairs */
   
   proc sql noprint;
    create table testap&dom._&dset
	 as (select a.*, b.&dom_ref.STRESN
	 from testa&dom._&dset a, testna&dom._&dset b, dsm_var_rel c
	 where a.usubjid=b.usubjid
	   and a.visitnum=b.visitnum
	   and a.visit=b.visit
	   and a.seq=b.seq
	   and c.decode=a.&dom_ref.TESTCD
	   and c.code=b.&dom_ref.TESTCD);
   quit;
   
   /* bjc006 : fix to keep the numeric/scored questions as a separate dataset for later append/set statement */
   proc sort data=testap&dom._&dset;
    by studyid domain usubjid visitnum visit seq;
   run;
   
   proc sort data=testa&dom._&dset;
     by studyid domain usubjid visitnum visit seq &dom_ref.TESTCD;
   run;

   proc sort data=testap&dom._&dset;
     by studyid domain usubjid visitnum visit seq &dom_ref.TESTCD;
   run;
   
   data testa&dom._&dset;
    merge testa&dom._&dset   
		  testap&dom._&dset;
    by studyid domain usubjid visitnum visit seq &dom_ref.TESTCD;		
   run;		
		 
    proc sort data=testa&dom._&dset;
     by studyid domain usubjid visitnum visit seq;
    run;
    /* end of bjc006 change */
	
  %end;
 /* BJC005: end of changes */ 
  
 /* BJC002 - dont generate (e)rror situation for two scenarios where tests or qualifiers are missing- warn user and continue */
  %if %eval(%tu_nobs(test&dom._&dset))=0 %then %do;

  %let _cmd = %str(%str(RTW)ARNING: Cant build full &dom._&dset sub-domain, no source data mapped to --ORRES items, so no --TEST entries for &dom._&dset);%tu_sdtmconv_sys_message;

   data mid_sdtm.&dom._&dset ;
    SET quala&dom._&dset;
   run;  
  %end;
 
  %if %eval(%tu_nobs(qual&dom._&dset))=0 %then %do;
    %let _cmd = %str(%str(RTW)ARNING: Cant build full &dom._&dset sub-domain, no --TEST qualifiers e.g. --DTC, --CAT and Timeslicing vars mapped for &dom._&dset);%tu_sdtmconv_sys_message;

   data mid_sdtm.&dom._&dset ;
    SET testa&dom._&dset;
   run;  
  %end;
  
  
 /* Merge test data back with qualifiers */    
 /* BJC002 - run the merge only when  both parts are present */
 
 %if %eval(%tu_nobs(test&dom._&dset))>=1 and %eval(%tu_nobs(qual&dom._&dset))>=1 %then %do;

  data mid_sdtm.&dom._&dset _mid_null_tst_&dom._&dset;
   MERGE testa&dom._&dset 
         quala&dom._&dset;
   by studyid domain usubjid visitnum visit seq;
  run;  
 %end;

 %if &dom=EG %then %do;
  %tu_sdtmconv_mid_ecg_alter;
 %end; 

 /* for findings datasets there will be multiple SDTM rows where there was one SI row, so
 /  we need to reset the SEQ values to unique SEQ values */
  
 proc sql noprint;
    create table _mid_num_seq_norm_&dom._&dset as
     select usubjid, 
            count(distinct seq) as dist_seq,
            count(*) as dist_recs
       from mid_sdtm.&dom._&dset
       where seq is not null
       group by usubjid
       having count(distinct seq)^=count(*)
       order by usubjid;
 quit;
  
 /* Re-Assign SEQ to make it unique where we have more than one test present */
 /* BJC001 - set a counter for FA domains to track the seq numbers used across FA domains */
 %if %eval(%tu_nobs(_mid_num_seq_norm_&dom._&dset))>=1 or %symexist(fa_seq) %then %do;  

     /* BJC001: If its the first FA-- domain in a run then initilise the seq counter */
     %if %substr(&dom,1,2)=FA and not %symexist(fa_seq) %then %do;
      %global fa_seq;
      %let fa_seq=0;
     %end;
          
     /* BJC001:Use the FA_SEQ counter for FA--, else re-initialise the SEQ for other Findings domains*/
     
     data mid_sdtm.&dom._&dset; 
      set mid_sdtm.&dom._&dset(rename=(SEQ=OLD_SEQ_VALUE));
         by studyid domain usubjid visitnum visit;
         length SEQ 8.;
         retain SEQ 
                   %if %substr(&dom,1,2)=FA %then %do;
                    &fa_seq;
                   %end;
                   %else %do;
                     0;
                   %end;  
         if first.usubjid then SEQ=
                   %if %substr(&dom,1,2)=FA %then %do;
                    &fa_seq;
                   %end;
                   %else %do;
                     0;
                   %end;          
         SEQ=SEQ+1;
    run;
    
    /* BJC001: Make the next available (overall) SEQ number available for the next FA domain */
    %if %substr(&dom,1,2)=FA %then %do;
     proc sql noprint;
        select max(seq)
          into :fa_seq
      from mid_sdtm.&dom._&dset;
     quit; 
         
    %end;
 %end;

 /* So SUPPQUAL data can be later joined correctly, take a copy of SEQ number anyway even if not recalculated */
 %if %eval(%tu_nobs(_mid_num_seq_norm_&dom._&dset))=0 %then %do;  

     data mid_sdtm.&dom._&dset; 
      set mid_sdtm.&dom._&dset;
         by studyid domain usubjid visitnum visit;         
         OLD_SEQ_VALUE=SEQ;
    run;
 %end;

%skip: 

/* Tidy up work datasets */
%if &sysenv=BACK %then %do;  

/* BJC004 two new steps in tu_tidyup for more large work datasets, also combine into one macro call */
/* BJC005: add new tidyup calls */

%tu_tidyup(
rmdset = test&dom._&dset: qual&dom._&dset: testa&dom._&dset: testna&dom._&dset: testap&dom._&dset: quala&dom._&dset: _mid_num_seq_:,
glbmac = none
);

%end;

%mend tu_sdtmconv_mid_norm;          
