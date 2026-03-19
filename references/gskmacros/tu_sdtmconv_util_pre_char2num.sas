/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_util_pre_char2num
|
| Macro Version/Build:  3/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009
|
| Macro Purpose :       Convert char item to numeric, and add a new item with
|                       any char contents while the data is still in source 
|                       format e.g. CMDOSE may have 100/50 as a value that wont
|                       fit in the numeric CMDOSE field so create CMDOSTXT to 
|                       store the char versions
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
| Macros called :
| (@)tu_tidyup
|
| Example:
|
| %tu_sdtmconv_util_pre_char2num
|
|*******************************************************************************
| Change Log :
|
| Modified By:                  Bruce Chambers
| Date of Modification:         01Feb2011
| New Version/Build Number:     2/1
| Reference:                    BJC001
| Description for Modification: populate algorithm with defaulted value
| Reason for Modification:      ensure define.xml is complete
|
| Modified By:                  Bruce Chambers
| Date of Modification:         30Apr2013
| New Version/Build Number:     3/1
| Reference:                    BJC002
| Description for Modification: only add a varmap row if not already present
| Reason for Modification:      ensure no duplicate metadata rows
|
*******************************************************************************/
%macro tu_sdtmconv_util_pre_char2num(
);

proc sql noprint;
 create table _pre_char2num as
 select distinct vm.si_dset, vm.si_var, vm.instructions, vm.domain,
 substr(instructions,15,index(instructions,';')-17) as chardup
 from instructions vm, dictionary.columns dc
 where dc.libname='PRE_SDTM'
   and dc.memname=vm.si_dset
   and dc.name=vm.si_var
   and index(vm.instructions,'pre_char2num')>0
   and si_dset in (select basetabname from view_tab_list);
quit; 

/* Count the number of datasets (if any) to process */
%if &sqlobs>=1 %then %do;

 data _pre_char2num;
  set _pre_char2num;
  num=_n_;
 run;
 
 %DO w=1 %TO &sqlobs;

  /* For each iteration - apply the conversion */
  data _null_ ;set _pre_char2num (where=(num=&w));
   call symput('si_dset',trim(si_dset));
   call symput('chardup',trim(chardup));
   call symput('si_var',trim(si_var));
   call symput('domain',trim(domain));
  run;

  /* change si_var from character to numeric */
  data pre_sdtm.&si_dset(drop=tmpvar);
       set pre_sdtm.&si_dset(rename=(&si_var=tmpvar));
         
       length &si_var 8. ;
       if tmpvar^='' and input(tmpvar, ?? 8.) >=0 then do;
          &si_var = input(tmpvar, ?? 8.);
       end;
       
       ** Create new character duplicate type item (defined as argument) to store char data **;   
       if tmpvar^='' and input(tmpvar, ?? 8.) =. then do;
          &chardup = tmpvar;
       end;            
  run;
 

  /* Add a row to the varmap file with the additional variable */

  /* Added for BJC002 - only add a row to varmap if the row doesnt already exist */
  proc sql noprint;
     select count(*) into :in_varmap from varmap
      where si_dset="&si_dset"
        and sdtm_var="&chardup"
        and domain="&domain";
  quit;     
      
  %if &in_varmap=0 %then %do;
  
   data _pre_char2num_varmap_add;      
    si_dset="&si_dset"; 
    si_var="&chardup";
    origin='CRF';
    domain="&domain";
    sdtm_var="&chardup";
    suppqual='NO';
    added='Y';
    /* BJC002: default algorithm entry */
    instructions="Content is a direct copy of non-NUMERIC content from source data &si_var column";    
   run; 
   
   data varmap;
    set varmap 
       _pre_char2num_varmap_add;
   run; 
  
  %end;  
 %end;
%end;      

%if &sysenv=BACK %then %do;  

%tu_tidyup(
  rmdset = _pre_char2num:,
  glbmac = none
);
%end;

%mend tu_sdtmconv_util_pre_char2num;
