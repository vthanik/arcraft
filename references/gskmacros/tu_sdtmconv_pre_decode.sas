/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_decode
|
| Macro Version/Build:  6/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009
|
| Macro Purpose:        Decode coded source items to get decode variables.
|
|                       As the source data will ususally be A+R, the code prunes
|                       the driver fmtvars dataset first and removes rows for
|                       decoded items already present. Any decodes that are
|                       still missing will get created. 
|
|                       This code automatically defines the parameters by using
|                       the variable relationships defined in DSM metadata, so
|                       is reliant on this DSM detail being present and correct
|                       (which it reliably is).
|
|                       Also - there are examples of variable relationships
|                       defined in DSM with different decode variable names, so
|                       users use the default name so some source datasets may
|                       have two decode items with (hopefully!) identical content.
|                       e.g. AE.AEACTRCD decode to AEACTTRT according to DSM,
|                       the expected value is AEACTR which is not correct, tho
|                       some studies have it.
|                       Another good example is INVPCOMP (Resp TST Std).
|                       VISIPDCD decodes to VISIPDIS (not VISIP)
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
| (@)tu_nobs
| (@)tu_tidyup
| (@)tu_sdtm_decode
|
| Example:
|
| %tu_sdtmconv_pre_decode
|
|*******************************************************************************
| Change Log:
|
| Modified By:                  Bruce Chambers
| Date of Modification:         11august2010
| New Version/Build Number:     2/1
| Reference:                    bjc001
| Description for Modification: Prevent creation of a decode pair if a later variable will 
|                               be renamed, as the existing data may be correct for the study.
|                               Codelist decodes can change in DSM over time, we dont want the 
|                               new copy if it has changed and we haev the original.                               
| Reason for Modification:      People often create the wrong decode item 
|                               e.g. AEACTRCD should have AEACTTRT as its decode pair. however,
|                               many people create AEACTR which will be renamed to AEACTTRT 
|                               (if its not already present).
|
| Modified By:                  Bruce Chambers
| Date of Modification:         20august2012
| New Version/Build Number:     3/1
| Reference:                    bjc002
| Description for Modification: Populate rows for decoded vars to varmap metadata
| Reason for Modification:      To give traceability for SI dataset decodes that get added
|
| Modified By:                  Bruce Chambers
| Date of Modification:         12Mar2013
| New Version/Build Number:     4/1
| Reference:                    bjc003
| Description for Modification: Remove from fmtvars variables already decoded
| Reason for Modification:      To allow more flexible pre-processing
|
| Modified By:                  Bruce Chambers
| Date of Modification:         12Mar2013
| New Version/Build Number:     5/1
| Reference:                    bjc004
| Description for Modification: Back out previous change as impacts adversely if >1 dataset with same var names
|                               Implement in a different place instead, and use new customised tu_sdtm_decode
| Reason for Modification:      To allow more flexible pre-processing
|
| Modified By:                  Bruce Chambers
| Date of Modification:         18Jul2013
| New Version/Build Number:     6/1
| Reference:                    bjc005
| Description for Modification: Add tu_sdtm_decode to header so it gets copied (by HARP) to arprod                             
| Reason for Modification:      Enable use of conversion toolset in /arprod
|
*******************************************************************************/
%macro tu_sdtmconv_pre_decode(
);

/* Get list of datasets to decode */
proc sql; 
 
 /* BJC001: Get list of variables to be renamed to use later so that we dont decode
 /  a variable that will be later created by applying a rename */  
 create table _pre_rename as
 select vm.si_dset, vm.si_var, vm.instructions,
 substr(instructions,8,index(instructions,';')-9) as rename
 from instructions vm, dictionary.columns dc
 where dc.libname='PRE_SDTM'
   and dc.memname=vm.si_dset
   and dc.name=vm.si_var
   and index(instructions,'rename')>0
   and si_dset in (select basetabname from view_tab_list);   
 
 /* BJC004: update this query */
 create table _pre_decode_dset_vars as 
   select distinct dc1.memname , dc1.name
    from (dictionary.columns as dc1
         inner join
         fmtvars as fv
         on dc1.name = fv.name)
         left join
	     dictionary.columns as dc2
	     on dc1.libname = dc2.libname
         and dc1.memname = dc2.memname
         and fv.decode = dc2.name
   where dc1.libname='PRE_SDTM'
     and dc2.memname is missing;
 
  create table _pre_decode_dsets as 
   select distinct memname
     from dictionary.tables
    where libname='PRE_SDTM';  
   
quit;

%if &sqlobs>=1 %then %do;  

  data _pre_decode_dsets;
   set _pre_decode_dsets;
    num=_n_;
  run;

 /* Iterate through each dataset and decode SI data */
 %DO z=1 %TO &sqlobs;
 
  data _null_ ;set _pre_decode_dsets(where=(num=&z));
   call symput('memname',trim(memname));
  run;
  
  data _pre_decode_sub_vars;
   merge _pre_decode_dset_vars(where=(memname="&memname") in=a)
         fmtvars;
   by name;
   if a and decode ^='';
  run; 
  
  /* Delete any items from driver table that are already decoded.
  /  NB Potential here for the item to be decoded already if in A&R data so the
  /  queries need to deal with this scenario, and not re-decode any existing variables */  
  
  /* BJC001 - Add a delete step below so we dont create any decode variables that will later be created by a rename
  /  as we should use existing decode data where it is present as codelist entries can change in DSM over time */
  
  proc sql;
   delete from _pre_decode_sub_vars 
    where trim(memname)||trim(decode) in 
    (select trim(si_dset)||trim(rename) from _pre_rename);
   
   delete from _pre_decode_sub_vars 
    where decode in 
    (select distinct name 
    from dictionary.columns
    where libname='PRE_SDTM' and memname="&memname");
	
   /* BJC003: add extra delete step to metadata (removed for BJC004 and nowdone above/earlier) */	
   
  quit;  
  
  %let var_string=;
  data _pre_decode_sub_vars;
   set _pre_decode_sub_vars end=last;
        length var_string $2000;
        retain var_string '';
        var_string = trim(name)||' '||trim(decode)||' '||var_string;
        if last then call symput('var_string',trim(var_string));
  run;    

  %if %eval(%tu_nobs(_pre_decode_sub_vars))=0 %then %goto skip;

  /* BJC004: use modified version of tu_decode to allow selective decodes */
  
  %tu_sdtm_decode(
        dsetin  = pre_sdtm.&memname,
        dsetout = pre_sdtm.&memname,
        decodepairs= &var_string,
        formatnamesdset= fmtvars
       );

 /* BJC002: Add to the working varmap dataset details of decodes added (for traceability) */
 
 proc sql noprint;
  update varmap vm set ADDED=(
  select 'Y' as added 
  from _pre_decode_sub_vars
  where memname=vm.si_dset
  and decode=vm.si_var)
  where added is null;
 quit;
 
 %skip:

 %end;
%end;

%if &sysenv=BACK %then %do;  

%tu_tidyup(
rmdset = _pre_decode_:,
glbmac = none
);
%end;

%mend tu_sdtmconv_pre_decode;
