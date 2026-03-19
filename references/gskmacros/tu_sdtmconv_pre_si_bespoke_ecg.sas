/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_si_bespoke_ecg
|
| Macro Version/Build:  6/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009 
|
| Macro Purpose:        Pre-processing for ECG data as per the Data Standards specifications. 
|                       As more than one finding may be present for a set of ECGs, if the 
|                       incoming data has the ECG test results repeated for each finding then 
|                       we only want the first set of test results, but all findings.
|
|                       There is a double whammy as the IDSL ECG dataset is "double L-shaped". 
|                       There are the tests and forking from those are findings and/or tech comments.
|
|                       The aim of this macro is basically to fragment the data into tests/findings/comments
|                       so that they are on separate rows for common timepoints.
|
| Macro Design:         Procedure
|
| Input Parameters:
| 
| NAME                DESCRIPTION                                  DEFAULT           
|
|
| Output:
|
|
| Global macro variables created:
|
|
| Macros called:
|  
| (@)tu_chkvarsexist
|
| Example:
|
| %tu_sdtmconv_pre_si_bespoke_ecg
|
|*******************************************************************************
| Change Log:
|
| Modified By:                  Bruce Chambers     
| Date of Modification:         09August2010
| New Version/Build Number:     2/1
| Reference :                   bjc001
| Description for Modification: Need to merge the two subsets of data, not append as sets of duplicate
|                               keys were being created that causes problems later
| Reason for Modification:      Ensure key integrity is maintained
|
| Modified By:                  Deepak Sriramulu     
| Date of Modification:         27July2011
| New Version/Build Number:     3/1
| Reference :                   dss001
| Description for Modification: Include EGINTP in the BY statement of MERGE.
| Reason for Modification:      ECG pre-processing macro doesnt deal with ECG data correctly   
|
| Modified By:                  Ashwin Venkat(va755193)     
| Date of Modification:         15-Oct-2012
| New Version/Build Number:     4/1
| Reference :                   VA001
| Description for Modification: extracting technical comments from EGFOTH, as older studies do not have EGERRCOM(1/2/3)
| Reason for Modification:      and put it in EGERRCOM 
|
| Modified By:                  Bruce Chambers    
| Date of Modification:         27-Oct-2012
| New Version/Build Number:     5/1
| Reference :                   BJC002
| Description for Modification: add VISITNUM/EGDT/EGACTTM to list of distinct fields checked for
| Reason for Modification:      Partial re-write of whole module upon detailed QC of data and to allow for the
|                               possibility of tests only, test and abnorms/findings, tests and tech comments 
|                               (but no abnorms), or all 3 ! (Tech comments have 2 variant structures as well).
|
| Modified By:                  Bruce Chambers    
| Date of Modification:         10-May-2013
| New Version/Build Number:     6/1
| Reference :                   BJC003
| Description for Modification: deal corectly with new EGERRCOM variable
| Reason for Modification:      new variant of how ECG IDSL data can be presented
|
********************************************************************************************************/
%macro tu_sdtmconv_pre_si_bespoke_ecg(
);

/* Only run the following steps if the ECG data has findings or tech comments in it, if its just ECG readings do nothing */

%if (%tu_chkvarsexist(pre_sdtm.ecg,EGFINDCD) eq or %tu_chkvarsexist(pre_sdtm.ecg,EGERRCOM) eq ) %then %do;     

 /* Check for EGSEQ - drop if present */
 %local EGSEQ;
 %let EGSEQ= %tu_chkvarsexist(pre_sdtm.ecg,EGSEQ,Y);           
 /* Check for any timeslicing keys we need to keep on the findings data */
 %let ELTMNUM= %tu_chkvarsexist(pre_sdtm.ecg,ELTMNUM,Y); 
 %let ELTMUNIT= %tu_chkvarsexist(pre_sdtm.ecg,ELTMUNIT,Y); 
 %let PTMNUM= %tu_chkvarsexist(pre_sdtm.ecg,PTMNUM,Y); 
 %let PTM= %tu_chkvarsexist(pre_sdtm.ecg,PTM,Y); 
 %let TPTREF= %tu_chkvarsexist(pre_sdtm.ecg,TPTREF,Y); 
 %let TPTREFN= %tu_chkvarsexist(pre_sdtm.ecg,TPTREFN,Y); 
 %let CYCLE= %tu_chkvarsexist(pre_sdtm.ecg,CYCLE,Y); 
 %let ECGNUM= %tu_chkvarsexist(pre_sdtm.ecg,ECGNUM,Y); 
 
 /*va001: extracting technical comments from EGFOTH, as older studies do not have the EGERRCOM(1,2,3) 
          variables to store these comments. If EGERRCOM is there then it will hold technical comments 
		  so no need to extract from EGFOTH */
 %let EGERRCOM = %tu_chkvarsexist(pre_sdtm.ecg,EGERRCOM,Y);
 %let EGERCOM1 = %tu_chkvarsexist(pre_sdtm.ecg,EGERCOM1,Y);
 %let EGERCOM2 = %tu_chkvarsexist(pre_sdtm.ecg,EGERCOM2,Y);
 /* BJC002: add more variables to check for uniqueness of rows */
 %let EGACTTM= %tu_chkvarsexist(pre_sdtm.ecg,EGACTTM,Y);   
 %let EGFINDCD = %tu_chkvarsexist(pre_sdtm.ecg,EGFINDCD,Y);
 %let EGEVALCD = %tu_chkvarsexist(pre_sdtm.ecg,EGEVALCD,Y);
 %let EGLEADCD = %tu_chkvarsexist(pre_sdtm.ecg,EGLEADCD,Y);
 
 /* Set up strings with all the required and possible keys in the study data */
 %let bystr=studyid usubjid subjid &cycle visit visitnum egdt &egacttm &ptm &ptmnum &tptref &tptrefn &eltmnum &eltmunit &ecgnum &egevalcd &egleadcd;			
	
 /* split ECG tests and findings out separately */ 
 /* BJC003 : drop EGERRCOM vars for ECG_TEST work dataset */
 
 data ecg_test(drop=egfind egfindcd egfoth &EGERRCOM &EGERCOM1 &EGERCOM2)
      ecg_find(keep= &bystr egfindcd egfind egfoth &EGERRCOM &EGERCOM1 &EGERCOM2);
  set pre_sdtm.ecg
    %if &EGSEQ=EGSEQ %then %do;
     (drop=EGSEQ)
    %end; 
      ;
   /* Output all tests to ecg_test dataset */
    output ecg_test;
   /* Separate any findings and put to ecg_find */
   if
    %if %length(&EGFINDCD) ^= 0 %then %do;    
     egfindcd^='' or egfoth^= ''    
	%end; 
    %if %length(&EGERRCOM) ^= 0 %then %do;
     or EGERRCOM^=''
    %end;	 
      then output ecg_find;
 run;

 /* BJC002: check for uniqueness and filter out any duplicate rows of tests/qualifiers and keys and sort once the findings 
    and comments are temporarily removed */
	
 proc sql noprint;   
   select count(distinct 
   compress(studyid||usubjid||put(subjid,8.)
    %if &cycle ne %then %do;    
     ||put(cycle,8.)
    %end;
     ||visit||put(visitnum,7.2)||put(egdt,8.)
    %if &egacttm ne %then %do;
     ||put(egacttm,8.)
    %end;
    %if &ptmnum ne %then %do;
     ||put(ptmnum,7.2)
    %end;
    %if &ptm ne %then %do;
     ||ptm
    %end;
    %if &tptref ne %then %do;    
     ||tptref
    %end;
    %if &tptrefn ne %then %do;    
     ||put(tptrefn,7.2)
    %end;	
    %if &eltmnum ne %then %do;
     ||put(eltmnum,7.2)
    %end;
    %if &eltmunit ne %then %do;
     ||eltmunit
    %end;
    %if &ecgnum ne %then %do;
     ||put(ecgnum,8.)
    %end;
	)) into :confirm_dist_test from ecg_test;
   
   create table ecg_dist_test as
   select distinct * from ecg_test;
 quit;
 
 %if &sqlobs^=&confirm_dist_test %then %do;
    %let _cmd = %str(%str(RTW)ARNING: ECG problem: Sets of tests and qualifiers are replicated incompletely where);
    %tu_sdtmconv_sys_message;
	%let _cmd = %str(multiple EGFIND[CD]/EGFOTH and tech comments are present. Report to developers for assistance.);
    %tu_sdtmconv_sys_message;
 %end;
 
 proc sort data= ecg_dist_test;
    by &bystr;
  run;
  
 /* bjc001: From this point onwards the rest of the macro now changes for this enhancement. 
 /  As more than one finding may be present for a set of ECGs, if the incoming data has the tests repeated
 /  for each finding then we only want the first set of test results, but each finding must be kept */

 /* Build a concatenated string of all the possible keys present to use to identify duplicate findings */
    
 data ecg_find;
  set ecg_find;
  
    /* BJC002: add more variables to check for uniqueness of rows */
    length strvar $2000;
    strvar=   compress(studyid||usubjid||put(subjid,8.)
    %if &cycle ne %then %do;    
     ||put(cycle,8.)
    %end;
     ||visit||put(visitnum,7.2)||put(egdt,8.)
    %if &egacttm ne %then %do;
     ||put(egacttm,8.)
    %end;
    %if &ptmnum ne %then %do;
     ||put(ptmnum,7.2)
    %end;
    %if &ptm ne %then %do;
     ||ptm
    %end;
    %if &tptref ne %then %do;    
     ||tptref
    %end;
    %if &tptrefn ne %then %do;    
     ||put(tptrefn,7.2)
    %end;	
    %if &eltmnum ne %then %do;
     ||put(eltmnum,7.2)
    %end;
    %if &eltmunit ne %then %do;
     ||eltmunit
    %end;
    %if &ecgnum ne %then %do;
     ||put(ecgnum,8.)
    %end;
    ); 
 run;	

 proc sort data= ecg_find;
    by strvar;
  run;

 /* For each set of ECG rows for a timepoint, output the first finding to ecg_find1
 /  and any subsequent ones to ecg_find2 work dataset. Append ecg_find1 and 2 in final steps later.*/
  
 /* BJC003 : drop original EGERRCOM vars for ECG_FINDn work datasets as comments processed later */ 
  
 data ecg_find1(drop=strvar &EGERRCOM &EGERCOM1 &EGERCOM2)
      ecg_find2 (drop=strvar &EGERRCOM &EGERCOM1 &EGERCOM2);
  set ecg_find(where=(egfindcd^=''));
    by strvar;
    if first.strvar=1 then output ecg_find1;
    else output ecg_find2;
  run;

 proc sort data= ecg_find1;
   by &bystr;
  run;

 /* Append any subsequent findings to the above data (without also repeating the test results in the data) */
 data all_com;
  set ecg_find; 
 
  /* Copy technical comment to EGERRCOM and null EGFOTH  */		
  %if %length(&EGFINDCD) ^= 0 and %length(&EGERRCOM) = 0 %then %do;
   length EGERRCOM EGERCOM1 EGERCOM2 $200;
   %let _cmd = %str(%str(RTN)OTE: Checking for technical comments in EGFOTH);%tu_sdtmconv_sys_message;
   
      if missing(EGFINDCD) and egfoth^='' then do;
		    EGERRCOM=EGFOTH;EGFOTH='';
	  end;
  %end;	    
 run;

/* If EGERRCOM is present and technical comments are NOT in EGFOTH this is the end of pre-processing */
 
 /* Now process old style technical comments that are still in EGFOTH (not new items)*/

  data all_com;
   set all_com(where=(EGERRCOM^=''));	

        /* BJC003 : if EGERRCOM present output row anyway */
        %if %length(&EGERRCOM) ^= 0 %then %do;
		 output;
        %end;
		
		/* Need to allow for one timepoint having >1 technical comment (all other data is duplicated).
		   Issue found in programmed QC compare */		
		
		/* Process all the technical comments row by row. We array them later in this module */
        if missing(EGFINDCD) and index(EGERRCOM,"TE:") EQ 1 then do;                
                output;
            end;
        if missing(EGFINDCD) and index(EGERRCOM,"TE2:") EQ 1  then do;                
                EGERCOM1 = EGERRCOM; EGERRCOM=''; output;
            end;
        if missing(EGFINDCD) and index(EGERRCOM,"TE3:") EQ 1  then do;                
                EGERCOM2 = EGERRCOM; EGERRCOM='';output;
            end;	
        if missing(EGFINDCD) and index(EGERRCOM,"OC:") EQ 1 then do;               
                output;
            end;
        if missing(EGFINDCD) and index(EGERRCOM,"OC2:") EQ 1 then do;                
                EGERCOM1 = EGERRCOM; EGERRCOM='';output;
            end;
        if missing(EGFINDCD) and index(EGERRCOM,"OC3:") EQ 1 then do;               
                EGERCOM2 = EGERRCOM; EGERRCOM=''; output;
            end;				
  run;
 
  /* Old style ECG data - comments can be fragmented across rows - get them back onto one row for each common set of keys.
    This is the only way to get them on the same row in the CO domain. */
 
  data egerrcom (keep=&bystr egerrcom)
       EGERCOM1 (keep=&bystr egercom1)
	   EGERCOM2 (keep=&bystr egercom2);
   set all_com;
   if EGERRCOM^='' then output EGERRCOM;
   if EGERCOM1^='' then output EGERCOM1;
   if EGERCOM2^='' then output EGERCOM2;
  run;
 
  proc sort data =egerrcom nodupkey;
    by &bystr egerrcom;
  run;

  proc sort data =egercom1 nodupkey;
    by &bystr egercom1;
  run;

  proc sort data =egercom2 nodupkey;
    by &bystr egercom2;
  run; 
 
  data egerr; 
  merge egerrcom EGERCOM1 EGERCOM2;
    by &bystr;
  run;	 

  proc sort data=egerr nodupkey;
     by &bystr egerrcom egercom1 egercom2;
  run;

  /* Build a concatenated string of all the possible keys present to use to identify >1 comment per timepoint */
    
  data egerr;
   set egerr;
    length strvar $2000;
    strvar=compress(studyid||usubjid||put(subjid,8.)
    %if &cycle ne %then %do;    
     ||put(cycle,8.)
    %end;
     ||visit||put(visitnum,7.2)||put(egdt,8.)
    %if &egacttm ne %then %do;
     ||put(egacttm,8.)
    %end;
    %if &ptmnum ne %then %do;
     ||put(ptmnum,7.2)
    %end;
    %if &ptm ne %then %do;
     ||ptm
    %end;
    %if &tptref ne %then %do;    
     ||tptref
    %end;
    %if &tptrefn ne %then %do;    
     ||put(tptrefn,7.2)
    %end;	
    %if &eltmnum ne %then %do;
     ||put(eltmnum,7.2)
    %end;
    %if &eltmunit ne %then %do;
     ||eltmunit
    %end;
    %if &ecgnum ne %then %do;
     ||put(ecgnum,8.)
    %end;
    );
  run;	

  proc sort data= egerr;
    by strvar;
  run;
 
  /* For each set of ECG rows for a timepoint, output the first comment set to ecg_err1
 /  and any subsequent ones to ecg_err2 work dataset */
  
 data ecg_err1(drop=strvar)
      ecg_err2 (drop=strvar);
  set egerr;
    by strvar;
    if first.strvar=1 then output ecg_err1;
    else output ecg_err2;
  run;

 proc sort data= ecg_err1;
   by &bystr;
  run; 
 
 /* Merge on any first comments/findings to existing sets of tests */
 data pre_sdtm.ecg;
  merge ecg_dist_test
        ecg_err1 ecg_find1;
   by &bystr;
 run;
  
  /* Append any subsequent comments to the above data (without also repeating the test results in the data) */
 data pre_sdtm.ecg;
  set pre_sdtm.ecg ecg_err2 ecg_find2; 
 run;
 
%end;  /* end for check for EGFINDCD field */      
 
/* DSS001: Add tidy up to clear work space */

%if &sysenv=BACK and %symexist(__utc_workpath) eq 0 %then %do;  
   %tu_tidyup(
      rmdset = ecg:,
       glbmac = none
    );
%end;

%mend tu_sdtmconv_pre_si_bespoke_ecg;
