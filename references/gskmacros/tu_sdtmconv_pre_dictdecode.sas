/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_dictdecode
|
| Macro Version/Build:  3/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009
|
| Macro Purpose:        Run HARP tu_dictdcod macro to add coded dictionary
|                       fields if not present or present but all values are null.
|                       If the coded field is partially populated then the data
|                       will not get re-coded.
|
|                       In a future release, we might consider enhancing this
|                       macro to call TU_DICTDCOD even for A&R datasets, if
|                       the new variables have not already been created in the
|                       A&R datasets.
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
| (@)tu_chkvarsexist
| (@)tu_tidyup
| (@)tu_dictdcod_sdtm
|
| Example:
|
| %tu_sdtmconv_pre_dictdecode
|
|*******************************************************************************
| Change Log:
|
| Modified By:                  Ashwin Venkat (VA001)         
| Date of Modification:         4 July 2011    
| New Version/Build Number:     2/1     
| Description for Modification: Changed macro call from tu_dictdcod to tu_dictdcod_sdtm
| Reason for Modification:      new macro tu_dictdcod_sdtm derives additional 
|                               variables required as per SDTM IG amendment 1
|
| Modified By:                  Bruce Chambers      
| Date of Modification:         10 July 2012    
| New Version/Build Number:     3/1     
| Description for Modification: Amend driver query to allow for SI datasets
| Reason for Modification:      Ensure all coded data processed
*******************************************************************************/
%macro tu_sdtmconv_pre_dictdecode(
);

/*VA001: check if AE dataset is in pre_sdtm library */
/* BJC001: add "and dm_subset_flag='Y' " to the query and remove ARDATA clause */
proc sql; 
 create table _pre_dec_dsets as 
 select distinct dt.memname 
 from dictionary.tables dt, dsm_meta dsm, view_tab_list vtl
 where dt.libname='PRE_SDTM'
 and dt.memname=dsm.dataset_nm
 and dt.memname=vtl.basetabname
 and dsm.clinical_dict^='' and dm_subset_flag='Y';
quit;


%if &sqlobs>=1 %then %do;  

 data _pre_dec_dsets;
  set _pre_dec_dsets;
  num=_n_;
 run;

 ** Iterate through each dataset and decode SI data **;
 %DO z=1 %TO &sqlobs;
  data _null_ ;set _pre_dec_dsets (where=(num=&z));
   call symput('memname',trim(memname));
  run;

  %let coded=;
  %let coded_var=;
  %let coded_count=;
 

  /* Get the name of the field flagged as the dictionary field for the current dataset */
  /* BJC001: add "and dm_subset_flag='Y' " to the query */
  proc sql noprint;
   select var_nm into :coded_var 
     from dsm_meta
    where clinical_dict is not null and dm_subset_flag='Y' and dataset_nm="&memname";
  quit;
  
  /* Check if the coded item is already present in the source, and if it is present and has
  /  values */
     
  %let coded= %tu_chkvarsexist(pre_sdtm.&memname,&coded_var,Y);
  %if &coded ne %then %do; 
   proc sql noprint;
    select count(*) into :coded_count 
     from pre_sdtm.&memname
    where &coded_var is not null;
   quit;
  %end;

  /* Only use TU_DICTDCOD to create new variables if the coded item (e.g. CMDRGCOL) exists and
  / is populated in at least one observation.  */

/*VA001: call new macro tu_dictdcod_sdtm which derives additional AE 
variables */
  %if &coded_count >= 1 %then %do;
   
   %tu_dictdcod_sdtm(
        dsetin =pre_sdtm.&memname,
        dsetout=pre_sdtm.&memname,
        cmanalyn=N
       );       
  %end;    
 %end;
%end;

%if &sysenv=BACK %then %do;  

%tu_tidyup(
rmdset = _pre_dec_:,
glbmac = none
);
%end;

%mend tu_sdtmconv_pre_dictdecode;
