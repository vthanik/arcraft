/******************************************************************************* 
|
| Macro Name: tu_sdtmconv_pre_defrag
|
| Macro Version/Build: 2/1
|
| SAS Version: SAS 9.1.3
|
| Created By: Bruce Chambers
|
| Date:            12-Aug-2009
|
| Macro Purpose: Some source data may be incorrectly presented with fragmented
|                data - this macro when called will get all data for one --TYPCD 
|                value onto a single row
|
|                NB: If --TYPCD present but at least one null value is found the 
|                    macro outputs an error and stops processing.
|
| Macro Design: Procedure
|
| Input Parameters:
|
| NAME              DESCRIPTION                         DEFAULT 
| DSET              Source dataset name                 N/A
|
| BYVAR             The --TYP variable to use to        N/A
|                   re-group the data
|
| Output:
|        Defragmented dataset
|
| Global macro variables created:
|
|        None
|
| Macros called:
| (@) tu_sdtmconv_sys_message
| (@) tu_tidyup
|
| Example:
|
|******************************************************************************* 
| Change Log 
|
| Modified By:                  Bruce Chambers
| Date of Modification:         18Jun2012
| New Version/Build Number:     2/1
| Reference:                    BJC001
| Description for Modification: Make sure empty columns dont get dropped
| Reason for Modification:      Ensure correct later data processing for data
|
********************************************************************************/ 

%macro tu_sdtmconv_pre_defrag(
                              dset, /* Input source dataset name */
                              byvar /* The --TYP variable to use to re-group the data */
                              );

/* Get a count and list of distinct by_vars present in the data */
proc sql noprint;

 create table _pre_defrag_by_vars as
 select distinct &byvar
   from &dset where &byvar is not null;

select count(*) into :num_byvars from _pre_defrag_by_vars;

select count(*) into :null_byvars from &dset where &byvar is null;

 select &byvar
   into :byvar1- :byvar%trim(%left(&num_byvars))
   from _pre_defrag_by_vars;
quit;

%if &null_byvars>=1 %then %do;
  %let _cmd = %str(%str(RTW)ARNING: &null_byvars records have null &byvar values. Skipping defrag macro); %tu_sdtmconv_sys_message;
  %goto endmac;
%end;

/* Split the data up into one dataset per by variable */
data 
%do a = 1 %to &num_byvars;
  _pre_defrag_sub_&a(where=(&byvar="&&byvar&a")) 
%end;
    ;
 set &dset;
run;

/* Get a list of variables in each sub dataset */
%do a = 1 %to &num_byvars;
 proc sql noprint;
  select name , name
    into :key_present1 separated by ',' ,
	 :key_present2 separated by ' ' 
    from dictionary.columns
   where libname='WORK'
     and memname=upper("_pre_defrag_sub_&a")
     and name in ('STUDYID','USUBJID','SUBJID','VISITNUM','VISIT',"&byvar");

  create table _pre_defrag_subcols_present as select name
    from dictionary.columns
   where libname='WORK'
     and memname=upper("_pre_defrag_sub_&a")
     and name not in ('STUDYID','USUBJID','SUBJID','VISITNUM','VISIT',"&byvar")
     and substr(reverse(trim(name)),1,3)^='QES';

  select count(*) into :num_cols from _pre_defrag_subcols_present;

  select name
   into :name1- :name%trim(%left(&num_cols))
   from _pre_defrag_subcols_present;
 quit; 

 /* Loop through and for each column create a sub dataset of just the keys and one populated eCRF item */
 proc sql noprint;
  %do b = 1 %to &num_cols;
   create table _pre_defrag_col_&&a._&b as
   select distinct &key_present1, &&name&b 
     from _pre_defrag_sub_&a 
    where &&name&b is not null
   order by &key_present1;
  %end;
 quit;

%end;

/* find which of those sub datasets actually have rows in them */
/* BJC001 - remove restriction for nobs >=1 and use nobs for later processing */
proc sql noprint;
  create table _pre_defrag_cols_populated as select memname, nobs
    from dictionary.tables
   where libname='WORK'
     and memname like '_PRE_DEFRAG_COL%' ;

  select count(*) into :num_pop from _pre_defrag_cols_populated;
quit;

/* BJC001 - add nobs to macro var generation */
proc sql noprint;
  select memname, nobs
    into :namepop1- :namepop%trim(%left(&num_pop)), :nobs1- :nobs%trim(%left(&num_pop))
    from _pre_defrag_cols_populated;
quit;

/* For each of the populated subsets, merge them back on the keys to get new
/  defragmented data product */

/* BJC001 - For datasets with 0 obs - still merge but on nobs=0 so null rows are not added, only columns */
    
data &dset;
  merge
 %do c = 1 %to &num_pop;
    &&namepop&c
	%if &&nobs&c = 0 %then %do;
	 (obs=0)
	%end;
 %end;
     ;
   by &key_present2;
run;

%endmac:

%if &sysenv=BACK %then %do;  

%tu_tidyup(
rmdset = _pre_defrag_:,
glbmac = none
);
%end;

%mend tu_sdtmconv_pre_defrag;
