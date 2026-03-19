/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_sys_register
|
| Macro Version/Build:  3/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009
|
| Macro Purpose:        Register in the system tables any new pseudo-source
|                       datasets that have been created during pre-processing
|                       steps e.g. GENPRO data goes to two domains and due to the
|                       complexity of this, two source GENPRO datasets are
|                       created during pre-processing. The additional dataset
|                       will need to be registered with the system for it to
|                       be further processed by the system.
|
| Macro Design:         Procedure
|
| Input Parameters (both are required):
| 
| NAME                DESCRIPTION                                  DEFAULT           
|
| memname             Name of pseudo source dataset to add to      N/A
|                     driver table
|
| src_name            Name of the source dataset for traceability   N/A
|
| Output:
|
|  Additional row in view_tab_list driver table
|
| Global macro variables created:
|
| None
|
| Macros called:
| (@)tu_tidyup
| (@)tu_nobs
|
| Example:
|
| %tu_sdtmconv_sys_register
|
|*******************************************************************************
| Change Log :
|
| Modified By:                  Bruce Chambers
| Date of Modification:         04aug2010
| New Version/Build Number:     2/1
| Reference                   : bjc001
| Description for Modification: Apply subset clause to datasets added to conversion
| Reason for Modification :     Some data e.g. PKCNC appends will not have been subset previously
|
| Modified By:                  Bruce Chambers
| Date of Modification:         12jun2012
| New Version/Build Number:     3/1
| Reference                   : bjc002
| Description for Modification: Dont register empty datasets 
| Reason for Modification :     AS this causes problem with later SEQ re-numbering
|
| Modified By:                  Bruce Chambers
| Date of Modification:         12Oct2012
| New Version/Build Number:     3/1
| Reference                   : bjc003
| Description for Modification: Supply source dataset as additional parameter 
| Reason for Modification :     Give full traceability for most data converted
|
*******************************************************************************/
%macro tu_sdtmconv_sys_register(
   memname /* Name of pseudo source dataset to add to driver table */,
   src_name /* Name of source dataset to add to monitor_varmap metadata table */
);

/* BJC003: the source name is required for traceability - confirm its presence */  
%if &src_name= %then %do;
 %put RTE%str(RROR): &memname pseudo dataset must have source dataset supplied as second parameter;
 %let syscc=999;	 
%end;

** Re-Add back into varmap any records for the added table **;
proc sql noprint;
  create table varmap_sub as 
   select * from varmap_all
  where si_dset="&memname"
      %if &tab_list ^= %then %do; 
         and si_dset in (&tab_list)
      %end;
      %if &tab_exclude ^= %then %do;
         and si_dset not in (&tab_exclude)
      %end; 
  ;
  /* BJC003: update the source name too for traceability */  
  alter table varmap_sub add orig_si_dset char(8);
  update varmap_sub set orig_si_dset=("&src_name");  
quit;
 
data varmap;
 set varmap varmap_sub;
run; 

/* BJC001 - New if/end step to apply any subset to newly created dataset - may not already be applied e.g. PKCNC appends */
%if %length(&subset_clause) >= 1 %then %do;

      data pre_sdtm.&memname; 
       set pre_sdtm.&memname(&subset_clause);                
      run;
%end;

** Add new dataset to the view_tab_list driver table **;
/* bjc002: only register non-empty datasets and warn user if empty ones are present */

%if %eval(%tu_nobs(pre_sdtm.&memname)) =0 %then %do;
     %put RTW%str(ARNING): &memname pseudo dataset has 0 rows, not registered with system for processing; 
%end;

%if %eval(%tu_nobs(varmap_sub))>=1 and %eval(%tu_nobs(pre_sdtm.&memname))>=1 %then %do;  
 data to_add;
   length basetabname $32;
   basetabname="&memname";
 run;
 
 data view_tab_list; 
  set view_tab_list
      to_add;
 run;     

 proc sort data=view_tab_list;
   by basetabname;
 run; 
 
%end;

%if &sysenv=BACK %then %do;  
 
%tu_tidyup(
 rmdset = to_add,
 glbmac = none
);
%end;

%mend tu_sdtmconv_sys_register;
