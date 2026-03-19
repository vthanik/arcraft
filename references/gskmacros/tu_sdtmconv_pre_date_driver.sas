/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_date_driver
|
| Macro Version/Build:  4/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009
|
| Macro Purpose:        Combine dates, times and char dups into ISO8601 format
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
| (@)tu_sdtmconv_pre_iso8601_datetm
| (@)tu_tidyup
| (@)tu_sdtmconv_sys_message
|
| Example:
|
| %tu_sdtmconv_pre_date_driver
|
|*******************************************************************************
| Change Log:
|
| Modified By:                 Bruce Chambers     
| Date of Modification:        10May2010    
| New Version/Build Number:    2/1
| Reference:                   BJC001
| Description for Modification:Keep the driver dataset to assist with define.xml traceability
| Reason for Modification:     Dont allow driver dataset to be cleaned up by tu_tidyup
|
| Modified By:                 Deepak Sriramulu     
| Date of Modification:        01Sep2010    
| New Version/Build Number:    3/1
| Reference:                   DSS001
| Description for Modification:Along with Time 5., TIME8. format will be processed by the macro
| Reason for Modification:     Time8. format is also checked with Time5. format as from last year 
|                              these became allowed in DSM
|
| Modified By:                 Bruce Chambers     
| Date of Modification:        14Sep2010    
| New Version/Build Number:    3/1
| Reference:                   BJC002
| Description for Modification:Create new varmap record with correct SUPPQUAL and ORIGIN references
| Reason for Modification:     Place date in correct location in SDTM if a SUPP variable with correct
|                              detail for define.xml
|
| Modified By:                 Bruce Chambers     
| Date of Modification:        21Feb2011   
| New Version/Build Number:    4/1
| Reference:                   BJC003
| Description for Modification:Check we dont create duplicate varmap records
| Reason for Modification:     If a duplicate record is present the system will try to map the data twice
|                              It is rare to map twice to one SDTM date - but CHDPOT is an example
|
*******************************************************************************/
%macro tu_sdtmconv_pre_date_driver(
);

/* Identify any date/time and char dup combinations within a dataset.
/  the system removes any ---DM (datetime) vars when data is copied to pre_sdtm 
/  work area however there are some pre-processing conversions that use datetime
/  fields to combine different dates and times together so there may be examples
/  of datetimes present in the incoming data */

/*BJC001 remove leading underscore from driver dataset so it wont be cleaned up */
/*DSS001 Add Time8. format. Conversion should handle time8 items as from last year these became allowed in DSM */
proc sql noprint;
 create table date_meta_driver as 
     select *,  
     substr(name,1,(length(name)-2)) as sub_name
   from dictionary.columns
  where libname='PRE_SDTM' 
  and memname in (select basetabname from view_tab_list)  
  and (format in ('DATE9.', 'TIME5.', 'TIME8.', 'DATETIME20.')
       or (type='char' and length=9 and substr(reverse(trim(name)),1,1)='_'))
  and name in (select distinct si_var from varmap)
  order by memname, sub_name;
quit;  

** Get hit list of date/time pair combinations, and char dups within a dataset **;
/*BJC001 remove leading underscore from driver dataset so it wont be cleaned up */
data _date_meta_groups; 
 set date_meta_driver;
 by memname sub_name;
 * Remove any char9 items that are not partial dates - rare but possible *;
 if (first.sub_name+last.sub_name=2) and format='$9.' 
 and substr(reverse(trim(memname)),1,2)^='_D' then delete;
run;

** Count number of datasets and fields to be processed **;
proc sql noprint; 
 create table _date_meta_to_do as 
 select distinct memname 
 from _date_meta_groups 
 order by memname;
 
 select count(distinct memname) into :num_dsets 
 from _date_meta_groups;
quit;

data _date_meta_to_do; 
 set _date_meta_to_do;
 num=_n_;
run;

%if &num_dsets >=1 %then %do;    

 * Loop through each source dataset in turn *;
 %global DSET dmvarname dtvarname tmvarname pdvarname;
 %do i = 1 %to &num_dsets;
     
  data _null_;
   set _date_meta_to_do(where=(num=&i));
    call symput('DSET', left(trim(memname)));
  run; 
  
  ** Count number of datasets and date/time related fields to be processed **;
  proc sql noprint; 
   select count(distinct sub_name) into :num_groups from _date_meta_groups where memname="&DSET";
  quit;

  data _date_meta_to_convert;
   set _date_meta_groups(where=(memname="&DSET")) end=last;
   retain num_groups 0;
   by memname sub_name;
   if first.sub_name then num_groups=num_groups+1;
   if last then call symput('num_groups', left(trim(num_groups)));
  run; 
  
  * Process each group of items e.g. AEENDT, AEENTM and AEEND_ will be one group **;
  %do j = 1 %to &num_groups;
  
  %let dmvarname= ;%let dtvarname=; %let tmvarname=; %let pdvarname=;

/*DSS001 Add Time8. format. Conversion should handle time8 items as from last year these became allowed in DSM */    
   data _null_;
     set _date_meta_to_convert(where=(num_groups=&j));
      call symput('MEMNAME', left(trim(memname)));
      call symput('SDTMNAME', left(trim(sub_name))||'DTC');
  
      if format ='DATE9.'         then call symput('DTVARNAME', left(trim(name)));
      else if format in ('TIME5.','TIME8.') then call symput('TMVARNAME', left(trim(name)));
      else if type='char' and length=9 then call symput('PDVARNAME', left(trim(name)));
      else if format ='DATETIME20.'    then call symput('DMVARNAME', left(trim(name)));
   run; 
      
   /* Derive the correct ----DTC variable to map to. For most data this is the default of 
   /  adding DTC to the root of the name, but some pre-processed datasets may differ.
   /  Findings rows where dates become tests e.g. DISCHA1 for Oncology need special treatment 
   /  to get the correct mapping */
   
   %let sdtm_var=;
   proc sql noprint; 
    select count(*) into :present 
      from dictionary.columns
     where libname='PRE_SDTM'
       and memname="&memname"
       and name in ("&DTVARNAME","&TMVARNAME","&PDVARNAME","&DMVARNAME"); 

    select %str(sdtm_var) into :sdtm_var
      from (select sdtm_var from varmap
     where si_dset="&memname"
       and si_var in ("&DTVARNAME","&TMVARNAME","&PDVARNAME","&DMVARNAME")
       and substr(sdtm_var,3,5)^='ORRES' 
       and sdtm_var is not null
       and origin^='DROPPED'
     union
     select distinct trim(sub_name)||'DTC' as sdtm_var 
          from varmap vm, _date_meta_groups dmg
          where vm.si_dset="&memname"
           and dmg.memname=vm.si_dset
           and dmg.name=si_var
            and vm.si_var in ("&DTVARNAME","&TMVARNAME","&PDVARNAME","&DMVARNAME")
            and substr(vm.sdtm_var,3,5)='ORRES'
            and vm.origin^='DROPPED') ;    
   quit;    

   %if &sdtm_var= %then %let sdtm_var=&sdtmname;

   /* For pre-processed data the same source date may get referenced twice, check we have not 
   /  already processed the data for the scenario present 
   /  NB: If this code is ever changed please test it on BRONCH data using BOTH EX and CM RESCUE variants */
   %if &present=0 %then %goto skip;
   
   %if &sqlobs>1 %then %do;
    %let _cmd = %str(RTWARNING: More than one source group of date-time-chardups map to &sdtm_var);%tu_sdtmconv_sys_message;
   %end;
   
   ** Use existing conversion macro **;
   %tu_sdtmconv_pre_iso8601_datetm (
        dsetin      = pre_sdtm.&MEMNAME,  /* Input dataset  */
        dsetout     = pre_sdtm.&MEMNAME,  /* Output dataset */
        dtcvarname  = &SDTM_VAR,          /* IS08601 ---DTC variable name */
        dmvarname   = &DMVARNAME,         /* Datetime variable name */
        dtvarname   = &DTVARNAME,         /* Date variable name */
        tmvarname   = &TMVARNAME,         /* Time variable name */
        pdvarname   = &PDVARNAME          /* Partial date variable name */
        );

   /* Add a row to the varmap file with the new additional ----DTC variable 
   /  Need to derive the domain this relates to from varmap 
   /  Also some pre-processed datasets may already have the ---DTC so we dont want a duplicate */
  
   %let domain=;
   /* BJC003 : define count_rec */
   %let count_rec=0;
   
   proc sql noprint;    
   
    select distinct domain into :domain
      from (select domain from varmap
              where si_dset="&memname"
                and si_var in ("&DTVARNAME","&TMVARNAME","&PDVARNAME","&DMVARNAME")               
                and sdtm_var is not null
                and origin^='DROPPED');
       
    select distinct sdtm_var into :DIST_SDTM_VAR    
    from (select sdtm_var from varmap
            where si_dset="&memname"
              and si_var in ("&DTVARNAME","&TMVARNAME","&PDVARNAME","&DMVARNAME") 
              and sdtm_var is not null
              and origin^='DROPPED'); 

    /* BJC002 - define SUPP macro variable to ensure correct date location if a SUPP variable*/
    select distinct suppqual into :DIST_SUPP_VAR    
    from (select suppqual from varmap
            where si_dset="&memname"
              and si_var in ("&DTVARNAME","&TMVARNAME","&PDVARNAME","&DMVARNAME") 
              and sdtm_var is not null
              and origin^='DROPPED'); 

    /* BJC002 - define ORIGIN macro variable to ensure correct date location if a SUPP variable*/
    select distinct origin into :DIST_ORIG_VAR    
    from (select origin from varmap
            where si_dset="&memname"
              and si_var in ("&DTVARNAME","&TMVARNAME","&PDVARNAME","&DMVARNAME") 
              and sdtm_var is not null
              and origin^='DROPPED'); 

    /* BJC003 : define a counter to ensure we are not adding the same record twice e.g. CHDPOT -> X9STDTC */
     select count(*) into :count_rec 
       from varmap
      where si_dset="&memname" 
        and si_var="&SDTM_VAR"
        and domain="&domain"
        and sdtm_var="&DIST_SDTM_VAR";
                 
   quit;    
       
   /* BJC003 : add count_rec=0 to the if clause before adding row to varmap */
   
   %if %length(&domain)>=1 and %length(&DIST_SDTM_VAR)>0 and &count_rec=0 %then %do;    
    data _date_meta_varmap_add;      
       si_dset="&memname"; 
       si_var="&SDTM_VAR";
       domain="&domain";
       added='Y';
       sdtm_var="&DIST_SDTM_VAR";
       /* BJC002 - use ORIG macro variable to ensure correct date metadata for define.xml */
       origin="&DIST_ORIG_VAR";
       /* BJC002 - use SUPP macro variable to ensure correct date location */
       suppqual="&DIST_SUPP_VAR";
    run; 
       
    data varmap;
     set varmap 
         _date_meta_varmap_add;
    run;      
 
   %end;
      
   %skip:
  %end; 
 %end;
%end;

%if &sysenv=BACK %then %do;  

%tu_tidyup(
 rmdset = _date_meta_:,
 glbmac = none
);
%end;

%mend tu_sdtmconv_pre_date_driver;

