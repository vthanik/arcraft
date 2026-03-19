/******************************************************************************* 
|
| Macro Name: tu_sdtmconv_pre_si_add_dsmlabs
|
| Macro Version/Build: 1
|
| SAS Version: SAS 9.1.3
|
| Created By: Bruce Chambers
|
| Date:            12-Aug-2009
|
| Macro Purpose:   One of the few pre-processing macros that is specific to SI/AR 
|                  datasets as it needs variable meta-data from DSM.
|
|                  Fetch variables labels from DSM and update onto any items that
|                  are DSM items and have no label - needed for later transpose step.
|
|                  Uses pre_label dataset created by system startup macros
|
| Macro Design:    Procedure
|
| Input Parameters: 
|
| None
|
| Output:
|
|
| Global macro variables created:
|
|
| Macros called:
| (@) tu_nobs
| (@) tu_tidyup
|
| Example:
|
|******************************************************************************* 
| Change Log 
|
| Modified By: 
| Date of Modification: 
| New Version/Build Number:
| Description for Modification:
| Reason for Modification: 
|
********************************************************************************/ 

%macro tu_sdtmconv_pre_si_add_dsmlabs(
);

proc sql noprint;
 create table _pre_label_missing as select memname, upcase(name) as name ,type, length
 from dictionary.columns where libname='PRE_SDTM'
 and label='';
quit; 

/* Rename labels for date items (not all dates have a time equivalent, so use DATE) */
data _pre_label_dsm;
 set label_dsm;
 if substr(reverse(trim(name)),1,2)='TD' then name=compress(name)||'C';
run;

proc sort data= _pre_label_dsm;
by name; run;

proc sort data= _pre_label_missing;
by name; run;

data _pre_label_missing;
 attrib type length=$9 format=$9.;
 merge _pre_label_missing(in=a) _pre_label_dsm(in=b);
 by name;
 if a;
 if a and not b then var_short_desc=name;
 if type='char' then type=compress('char('||length||')');
 if type='num' then type='numeric';
run;

/* Count the number of datasets (if any) to process to add dsm labels */
%if %eval(%tu_nobs(_pre_label_missing))>=1 %then %do;  

 data _pre_label_missing; 
  set _pre_label_missing;
  num=_n_;
 run;

 %DO w=1 %TO %eval(%tu_nobs(_pre_label_missing));

  /* For each iteration - add the label from DSM */  
  data _null_ ;set _pre_label_missing (where=(num=&w));
  call symput('memname',trim(memname));
  call symput('name',trim(name));
  call symput('type',trim(type));
  call symput('var_short_desc',trim(var_short_desc));
  run;

  proc sql noprint;
   alter table pre_sdtm.&memname add &name &type label="&var_short_desc";
  quit; 
    
 %end;
%end;

%if &sysenv=BACK %then %do;  

%tu_tidyup(
 rmdset = _pre_label_:,
 glbmac = none
);

%end;

%mend tu_sdtmconv_pre_si_add_dsmlabs;
