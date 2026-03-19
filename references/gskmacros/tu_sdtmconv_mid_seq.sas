/******************************************************************************* 
|
| Macro Name: tu_sdtmconv_mid_seq
|
| Macro Version/Build: 3/1
|
| SAS Version: SAS 9.1.3
|
| Created By: Bruce Chambers
|
| Date:            12-Aug-2009
|
| Macro Purpose: Redefine any existing SEQ numbers to ensure uniqueness once findings
|                data are converted onto one test per row, in the incoming data multiple
|                tests will share a SEQ number from the row of source data
|
| Macro Design:  Procedure
|
| Input Parameters:
|
| none
|
| Output:
|        mid_sdtm.&dom domain dataset with unique SEQ values per row
|
| Global macro variables created:
|
| Macros called:
| (@) tu_tidyup
|
| Example:
|
|******************************************************************************* 
| Change Log 
|
| Modified By:                  Bruce Chambers
| Date of Modification:         09Feb2011
| New Version/Build Number:     2/1
| Reference:                    bjc001
| Description for Modification: Replace SUBJID with USUBJID
| Reason for Modification:      Use USUBJID as the more differentiating key
|
| Modified By:                  Bruce Chambers
| Date of Modification:         15May2011
| New Version/Build Number:     3/1
| Reference:                    bjc002
| Description for Modification: Add more tu_tidyups
| Reason for Modification:      efficient use of /saswork space for mega studies
|
********************************************************************************/ 

%macro tu_sdtmconv_mid_seq(
);

/* First check for any null SEQ values in the overall domain dataset 
/   (still including SUPP data at this time), and get overall max value, 
/   so we can use max+1 as next start point */
   
proc sql noprint;
  select count(*) into :null_seq 
    from mid_sdtm.&dom
   where seq is  null;
    
   select max(seq) into :max_seq
     from mid_sdtm.&dom
    where seq is not null;

 /* Get max seq value for each subject - use to set as new start point 
    for new unique SEQ numbers */
 /* BJC001: replace SUBJID with USUBJID */   
 
 create table max_seq_&dom as
  select usubjid, max(seq) as max_seq
   from mid_sdtm.&dom
   where seq is not null
  group by usubjid
  order by usubjid;
 
 /* Get the number of distinct seq numbers and records */
 /* BJC001: replace SUBJID with USUBJID */   

 create table num_seq_&dom as
  select usubjid, 
         count(distinct seq) as dist_seq,
         count(seq) as tot_seq,
         count(*) as dist_recs
    from mid_sdtm.&dom
    where seq is not null
    group by usubjid
    order by usubjid;
 quit; 
 
 /* If the number of unique sequence values per subject doesnt match the number of rows per subject then
 /  we know we have duplciates from the source data (more than one item from each source row) */
 /* BJC001: replace SUBJID with USUBJID */   

 %let recalc=; 
 data _seq_&dom;
  merge max_seq_&dom
        num_seq_&dom;
  by usubjid;
  if dist_seq ^= tot_seq then call symput('RECALC','Y');
 run; 

/* Set Default max_seq=0 */
%if &max_seq= %then %let max_seq=0;  

/*  If there are null seq values then update so that each feeding datasets gets 
/   a distinct value. There is an assumption here that if a feeding dataset had 2 
/   or more sets of data values it would already have SEQ. If any of these are
/   missed then we do check for duplicate SEQs later. */
%if &null_seq ^=0 or &recalc^= %then %do;

 /* Restore the sort order needed to transpose later */
 /* BJC001: replace SUBJID with USUBJID */   

 proc sort data=mid_sdtm.&dom;
  by studyid domain usubjid visitnum visit seq;
 run;

 /* Assign SEQ to missing values - starting with the next integer value */
 /* BJC001: replace SUBJID with USUBJID */   

 data mid_sdtm.&dom; 
  set mid_sdtm.&dom(drop=seq) end=last;
      by studyid domain usubjid visitnum visit;
      length seq 8.;
      retain seq 0;
      if first.usubjid then seq=0;
      seq=seq+1;      
 run;

%end;

%if &sysenv=BACK %then %do;  

%tu_tidyup(
rmdset = _seq:,
glbmac = none
);

%tu_tidyup(
rmdset = max_seq_&dom,
glbmac = none
);

%tu_tidyup(
rmdset = num_seq_&dom,
glbmac = none
);

%end;

%mend tu_sdtmconv_mid_seq;
