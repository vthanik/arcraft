/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_adjust_period
|
| Macro Version/Build:  1/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jan-2011
|
| Macro Purpose:        Rename TPERIOD to PERIOD where both are present and drop original PERIOD
|                       OR
|                       If TPERIOD present with no PERIOD then rename TPERIOD to PERIOD
|                       NB:If PERIOD present with no TPERIOD: this is the default MSA PERIOD->EPOCH mapping
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
| (@)tu_tidyup
| (@)tu_sdtmconv_sys_message
|
| Example:
|
| %tu_sdtmconv_pre_adjust_period
|
|*******************************************************************************
| Change Log:
|
| Modified By:             
| Date of Modification:    
| New Version/Build Number:      
| Description for Modification:
| Reason for Modification: 
|
*******************************************************************************/
%macro tu_sdtmconv_pre_adjust_period(
);

/* Get list of any source datasets containing PERIOD and TPERIOD columns (count=2) - drop and rename
   AND also any with TPERIOD and not containing PERIOD (count=1) - rename only
   (NB: Those with PERIOD and no TPERIOD need no remapping here
        the default MSA varmap PERIOD-EPOCH mapping applies.)   */

   
proc sql noprint;
  create table _pre_period as 
  select * from 
  (
  (select distinct memname, count(name) as counter
    from dictionary.columns
   where libname='PRE_SDTM'   
     and name in ('TPERIOD','PERIOD')
   group by memname
  having count(name)=2)
 UNION
  ((select distinct memname, 1 as counter
  from dictionary.columns
  where libname='PRE_SDTM'   
  and name ='TPERIOD')
  EXCEPT
  (select distinct memname, 1 as counter 
    from dictionary.columns
    where libname='PRE_SDTM'   
  and name ='PERIOD'))
  )
;
quit;

/* Count the number of datasets (if any) to process */

%if &sqlobs>=1 %then %do;  

 data _pre_period;
  set _pre_period;
  num=_n_;
 run; 

 %DO w=1 %TO &sqlobs;

  /* For each iteration - create macro var with dataset name */  
  data _null_ ;set _pre_period (where=(num=&w));
   call symput('memname',trim(memname));
   call symput('counter',trim(counter));
  run;

  /* Those containing PERIOD and TPERIOD columns (count=2) - drop PERIOD and rename TPERIOD to PERIOD
     AND any with TPERIOD and not containing PERIOD (count=1) - rename TPERIOD to PERIOD only
     (NB: Those with PERIOD and no TPERIOD need no remapping here -
          the default MSA varmap PERIOD-EPOCH mapping applies.) */

  %if &counter=1 %then %do;
   %let _cmd = %str(%str(RTN)OTE: TPERIOD renamed to PERIOD in &memname [maps to SDTM EPOCH]);%tu_sdtmconv_sys_message; 
  %end;

  %if &counter=2 %then %do;
   %let _cmd = %str(%str(RTN)OTE: Original PERIOD dropped and TPERIOD renamed to PERIOD in &memname [maps to SDTM EPOCH]);%tu_sdtmconv_sys_message; 
  %end;

 data pre_sdtm.&memname(rename=(TPERIOD=PERIOD));
  set pre_sdtm.&memname
  %if &counter=2 %then %do;
   (drop=PERIOD)
  %end; 
  ;
 run;

 %end;
%end;

%if &sysenv=BACK %then %do;  

%tu_tidyup(
rmdset = _pre_period:,
glbmac = none
);
%end;

%mend tu_sdtmconv_pre_adjust_period;
