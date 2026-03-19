/******************************************************************************* 
|
| Macro Name: tu_sdtmconv_util_pre_copy
|
| Macro Version/Build: 5/1
|
| SAS Version: SAS 9.1.3
|
| Created By: Bruce Chambers
|
| Date:            12-Aug-2009
|
| Macro Purpose: Copy one item to another while the data is still in source format 
|
| Macro Design:  Procedure
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
|
| none
|
| Example:
|         %tu_sdtmconv_util_pre_copy;
|
|******************************************************************************* 
| Change Log 
|
| Modified By:                  Bruce Chambers
| Date of Modification:         29Apr2010
| New Version/Build Number:     2/1
| Reference:                    BJC001
| Description for Modification: systematic error in clause: 
|                               where origin in ('CRF','DERIVED') needs to be corrected to 
|                               where origin ^='DROPPED'
| Reason for Modification:      systematic error in where clause impacting 3 macros
|
| Modified By:                  Bruce Chambers
| Date of Modification:         01Feb2011
| New Version/Build Number:     3/1
| Reference:                    BJC002
| Description for Modification: populate algorithm with defaulted value
| Reason for Modification:      ensure define.xml is complete
|
| Modified By:                  Bruce Chambers
| Date of Modification:         05Apr2012
| New Version/Build Number:     4/1
| Reference:                    BJC003
| Description for Modification: populate ORIGIN with value for source item
| Reason for Modification:      ensure ORIGIN values in define.xml are correct
|
| Modified By:                  Bruce Chambers
| Date of Modification:         12Jun2012
| New Version/Build Number:     4/1
| Reference:                    BJC004
| Description for Modification: dont create a copy item if it already exists
| Reason for Modification:      dont overwrite copy items populated during pre-processing
|
| Modified By:                  Bruce Chambers
| Date of Modification:         22May2013
| New Version/Build Number:     5/1
| Reference:                    BJC005
| Description for Modification: allow specification of a remote domain in copy argument
|                               re-design the macro flow slightly to allow removal of non-needed rows
| Reason for Modification:      enable more flexible copying of source variables
|
********************************************************************************/ 

%macro tu_sdtmconv_util_pre_copy(
);

/* Get list of copy instructions to be executed */
/* BJC001: amend origin where clause in this query */
/* BJC004: add query to ID if a copy variable already exists and also delete any copy instructions 
           for existing variables so they are not executed */
		   
proc sql noprint;
 create table _pre_copy as
 select vm.si_dset, vm.si_var, vm.instructions, vm.domain,
 substr(instructions,10,index(instructions,'=')-10) as target,
 substr(instructions,index(instructions,'=')+1,length(instructions)-index(instructions,'=')-2) as source

 from instructions vm, dictionary.columns dc
 where dc.libname='PRE_SDTM'
   and dc.memname=vm.si_dset
   and dc.name=vm.si_var
   and index(vm.instructions,'pre_copy')>0
   and si_dset in (select basetabname from view_tab_list)
   and (vm.origin ^='DROPPED' or vm.instructions^='')
    and trim(si_dset)||trim(si_var) in 
      (select trim(memname)||trim(name) 
         from dictionary.columns 
        where libname='PRE_SDTM');     
 
 create table _pre_copy_exists as
  select memname, name
  from dictionary.columns
  where libname='PRE_SDTM'
  and trim(memname)||trim(name) in 
  (select trim(si_dset)||trim(target) 
   from _pre_copy);	

   select trim(memname)||trim(name) into :copy_exists separated by ',' from _pre_copy_exists;	 
   
   delete from _pre_copy where trim(si_dset)||trim(target) in (select trim(memname)||trim(name) from _pre_copy_exists);
   /* BJC005 - move the count to later in case we remove any rows in improved checking routine below */
quit;   
  

/* BJC005: notify user where deletions of copy instructions for existing variables have occurred*/

%if %eval(%tu_nobs(_pre_copy_exists))>=1 %then %do;   
     %put RTN%str(OTE): At least one copy not performed as data already exists: ;
	 %put Affected column(s): &copy_exists ;
%end;

/* BJC005 - rearranged code- remove IF (any rows in pre_copy) statement that was here  */

 data _pre_copy;
  set _pre_copy;      
   
   /* BJC005 : check for specification of remote/other domain */
   length newdom $4;
   if index(target,'.')>=1 then do;
    newdom=substr(target,1,index(target,'.'));
	target=substr(target,index(target,'.')+1,length(target)-index(target,'.'));
   end;
  run; 

  /* BJC005 : only copy items to a remote domain if other variables are mapped there - the copy items are nearly always 
     linking items and there is no point creating them from generic mapping if there is no other data to also map */
  
proc sql noprint;
 delete from _pre_copy where newdom is not null and newdom not in 
 (select distinct vm.domain 
    from varmap vm, dictionary.columns dc
   where vm.si_dset=dc.memname
     and dc.libname='PRE_SDTM'
     and vm.si_var=dc.name	);
quit;	 

/* BJC005: now we have the final rows - set the counter */
 data _pre_copy;
  set _pre_copy;   
   num=_n_;
 run;  
	
 /* BJC005 - change the way the second TO <n> argument is provided to be more dynamic */ 
 %DO w=1 %TO %eval(%tu_nobs(_pre_copy));

  /* For each iteration - process the instruction */
  data _null_ ;set _pre_copy (where=(num=&w));
   call symput('si_dset',trim(si_dset));
   call symput('source',trim(source));
   call symput('target',trim(target));
   call symput('domain',trim(domain));
   /* BJC005 : add newdom macro var */
   call symput('newdom',trim(newdom));
  run;

  data pre_sdtm.&si_dset;
   set pre_sdtm.&si_dset;
   &target=&source;
  run; 

  /* Add a row to the varmap file with the additional variable. */

  /* Added for BJC004 - sometime we copy SEQ - these wont be in varmap but for SEQ are ORIGIN=ASSIGNED
     However, default values to CRF unless they are ASSIGNED */ 
  
  %let ORIGIN=CRF;
  
   /* BJC003: get any differing ORIGIN value for source data field to assign ORIGIN for the new variable */
   proc sql noprint;
    select distinct origin into :origin 
      from varmap 
     where si_var="&source" and si_dset="&si_dset";
   quit;
   
  /* Added for BJC004 - sometimes we copy SEQ - these wont be in varmap but are ORIGIN=ASSIGNED */ 
  %if &source=SEQ and &origin =CRF %then %let origin=ASSIGNED;
  
  /* Added for BJC004 - only add a row to varmap if the row doesnt already exist */
  proc sql noprint;
     select count(*) into :in_varmap from varmap
      where si_dset="&si_dset"
        and sdtm_var="&target"
		/* BJC005: Use current or remote domain as appropriate */
		%if &newdom eq %then %do;
         and domain="&domain"
		%end;
		%else %do;
		 and domain="&newdom"
		%end;		
		;
  quit;     
      
  %if &in_varmap=0 %then %do;
  
   data _pre_copy_varmap_add;      
    si_dset="&si_dset"; 
    si_var="&target";
	/* BJC003: use ORIGIN value from source data for the new variable */
    origin="&origin";
		/* BJC005: Use current or remote domain as appropriate */
		%if &newdom eq %then %do;
         domain="&domain";
		%end;
		%else %do;
		 domain="&newdom";
		%end;		    
    sdtm_var="&target";
    suppqual='NO';
    added='Y';
    /* BJC002: default algorithm entry */
    instructions="Content is a direct copy of content of source data &source column";
   run; 
   
   data varmap;
    set varmap 
       _pre_copy_varmap_add;
   run;
  %end;
 
 /* DSS001: Code added to over come duplicate variable issue in varmap_mrg. */
  
  proc sort data = varmap noduplicate;
  by _all_;
  run; 

 %end;
 
/* dont use tu_tidyup as this _pre_copy dataset is used tu_sdtmconv_drop_vars */
 
%mend tu_sdtmconv_util_pre_copy;
