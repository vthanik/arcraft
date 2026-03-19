/******************************************************************************* 
|
| Macro Name: tu_sdtmconv_mid_type_convert
|
| Macro Version/Build: 1
|
| SAS Version: SAS 9.1.3
|
| Created By: Bruce Chambers
|
| Date:            12-Aug-2009
|
| Macro Purpose:   Convert data when in SUB-DOMAIN from char to num if needed
|                  i.e. all data will be char after the main transpose - but if 
|                  the SDTM column definition is numeric we need to convert it.
|                  (There are examples of SI char vars that are numeric in SDTM 
|                   anyway so this step is not caused by the transpose approach).
|
| Macro Design: Procedure
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
| (@) tu_sdtmconv_sys_message
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

%macro tu_sdtmconv_mid_type_convert(
);

proc sql noprint;
  create table _mid_tc_type_conv as 
  select dc.memname, dc.name, 
         ref.type as dom_type, dc.type as wrong_type
    from dictionary.columns dc,
         reference ref
   where dc.libname='MID_SDTM'
   and substr(reverse(trim(dc.memname)),1,2)^='A1'
     and ref.domain=substr(dc.memname,1,index(dc.memname,"_")-1)
     and ref.variable_name=dc.name
     and upper(ref.type)^=upper(dc.type)
     order by dc.memname, dc.name;
quit;    

data _mid_tc_char2num _mid_tc_num2char;
 set _mid_tc_type_conv;
  by memname name;
  if wrong_type='char' and dom_type='Num' then output _mid_tc_char2num;
  else if wrong_type='num' and dom_type='Char' then output _mid_tc_num2char;
run;

******************************************************************;
** Count the number of datasets (if any) to process for char2num**;
%if %eval(%tu_nobs(_mid_tc_char2num))>=1 %then %do;

 ** Count number of datasets and fields to be processed **;
 proc sql noprint; 
  create table _mid_tc_to_do as select distinct memname from _mid_tc_char2num order by memname;
  select count(distinct memname) into :num_dsets from _mid_tc_char2num;
 quit;

 * datasets created with proc sql dont seem to have _n_ , so create it !! *;
 data _mid_tc_char2num; 
  set _mid_tc_char2num;
    by memname;
    retain num 0;
    if first.memname then num=num+1;
 run;

 %if &num_dsets >=1 %then %do;    

  %do i = 1 %to &num_dsets;
     
   data _null_;
    set _mid_tc_char2num(where=(num=&i));
     call symput('DSET', left(trim(memname)));
   run; 
  
   ** Count number of datasets and fields to be processed **;
   proc sql noprint; 
    select count(distinct name) into :num_groups from _mid_tc_char2num where memname="&DSET";
   quit;

   data _mid_tc_to_convert;
    set _mid_tc_char2num(where=(memname="&DSET")) end=last;
    retain num_groups 0;
    by memname name;
    if first.name then num_groups=num_groups+1;
    if last then call symput('num_groups', left(trim(num_groups)));
   run; 
    
    ** For each iteration - output the dataset name and name **;  
    proc sql noprint;
    select memname, name
      into :sdtm_dset1- :sdtm_dset%left(&num_groups),
           :sdtm_name1- :sdtm_name%left(&num_groups)
      from _mid_tc_to_convert
     order by memname, name;
    quit;

    %do k=1 %to &num_groups;
       %let _cmd = %str(Converting &&sdtm_dset&k...&&sdtm_name&k from character to numeric);%tu_sdtmconv_sys_message;
       %let count_&&sdtm_name&k = 0;
    %end;
    
    ** change si_var from character to numeric **;
    data mid_sdtm.&dset (drop=

         %do k=1 %to &num_groups;
            tmpvar&k
         %end;     
       ) ;
         %do k=1 %to &num_groups;
            retain totcount&k 0;
         %end;     
     set mid_sdtm.&dset(rename=(
   
         %do k=1 %to &num_groups;
           &&sdtm_name&k=tmpvar&k
         %end;     
       )) end=eof ;
       length 
         %do k=1 %to &num_groups;
           &&sdtm_name&k
         %end;     
           8. ;

         %do k=1 %to &num_groups;   
           if tmpvar&k^='' and input(tmpvar&k, ?? 8.) ^=. then do;
              &&sdtm_name&k = input(left(tmpvar&k), 8.);
           end;          
           if tmpvar&k^='' and input(tmpvar&k, ?? 8.) = . then do;
             put "%str(RTW)ARNING: Unconvertible data found for: " usubjid &&sdtm_name&k =tmpvar&k.;
             totcount&k + 1;
           end;
           drop totcount&k;
         %end;  

         if eof then do;
            %do indx=1 %to &num_groups;   
               call symput("count_&&sdtm_name&indx",trim(left(put(totcount&indx.,8.))));
            %end; /* do indx=1 %to &num_groups */
          end;
    run;
 
    %do jndx=1 %to &num_groups;
       %let name = count_&&sdtm_name&jndx;
       %if &&&name %then %do;
          %let _cmd = %str(For &&sdtm_dset&jndx...&&sdtm_name&jndx &&&name conversion issues were found. Check log for details.);
          %tu_sdtmconv_sys_message;
        %end;
    %end;     

  %end;
 %end; 
%end;

******************************************************************;
** Count the number of datasets (if any) to process for num2char**;
%if %eval(%tu_nobs(_mid_tc_num2char))>=1 %then %do;

 ** Count number of datasets and fields to be processed **;
 proc sql noprint; 
  create table _to_do as select distinct memname from _mid_tc_num2char order by memname;
  select count(distinct memname) into :num_dsets from _mid_tc_num2char;
 quit;

 * datasets created with proc sql dont seem to have _n_ , so create it !! *;
 data _mid_tc_num2char; 
  set _mid_tc_num2char;
     by memname;
     retain num 0;
  if first.memname then num=num+1;
 run;

 %if &num_dsets >=1 %then %do;    

  %do i = 1 %to &num_dsets;
     
   data _null_;
    set _mid_tc_num2char(where=(num=&i));
     call symput('DSET', left(trim(memname)));
   run; 
  
   ** Count number of datasets and fields to be processed **;
   proc sql noprint; 
    select count(distinct name) into :num_groups from _mid_tc_num2char where memname="&DSET";
   quit;

   data _mid_tc_to_convert;
    set _mid_tc_num2char(where=(memname="&DSET")) end=last;
    retain num_groups 0;
    by memname name;
    if first.name then num_groups=num_groups+1;
    if last then call symput('num_groups', left(trim(num_groups)));
   run; 
    
    ** For each iteration - output the dataset name and name **;  
    proc sql noprint;
    select memname, name
      into :sdtm_dset1- :sdtm_dset%left(&num_groups),
           :sdtm_name1- :sdtm_name%left(&num_groups)
      from _mid_tc_to_convert
     order by memname, name;
    quit;

    %do k=1 %to &num_groups;
      %let _cmd = %str(Converting &&sdtm_dset&k...&&sdtm_name&k from numeric to character);%tu_sdtmconv_sys_message;
    %end;


    ** change si_var from character to numeric **;
    data mid_sdtm.&dset (drop=

         %do k=1 %to &num_groups;
            tmpvar&k
         %end;     
       );
     set mid_sdtm.&dset(rename=(
   
         %do k=1 %to &num_groups;
           &&sdtm_name&k=tmpvar&k 
         %end;     
       ));
       length 
         %do k=1 %to &num_groups;
           &&sdtm_name&k
         %end;     
           $200 ;

         %do k=1 %to &num_groups;   
     
           if tmpvar&k^=. and put(tmpvar&k, 8.) >=0 then do;
              &&sdtm_name&k = put(left(tmpvar&k), 8.);
           end;          

         %end;  
    run;

  %end;
 %end; 
%end;

%if &sysenv=BACK %then %do;  

%tu_tidyup(
rmdset = _mid_tc_:,
glbmac = none
);
%end;

%mend tu_sdtmconv_mid_type_convert;
