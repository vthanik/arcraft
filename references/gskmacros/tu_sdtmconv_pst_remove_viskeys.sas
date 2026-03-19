/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pst_remove_viskeys
|
| Macro Version/Build:  3/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009
|
| Macro Purpose:        If VISIT and VISITNUM are present in the source data
|                       they will carry through to the domains, but if all values
|                       are the same for all rows then they can be seen as
|                       meaningless and are dropped if this situation occurs
|                       and VISITNUM has Core=Perm attribute.
|                       Timing variables should be present when useful.
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
| (@)tu_tidyup
| (@)tu_sdtmconv_sys_message
| (@)tu_chkvarsexist
|
| Example:
| 
| %tu_sdtmconv_pst_remove_viskeys
|
|*******************************************************************************
| Change Log:
|
| Modified By:                 Bruce Chambers
| Date of Modification:        13August2010
| New Version/Build Number:    2/1
| Reference:                   bjc001
| Description for Modification:Drop VISIT(NUM) from CO domain
| Reason for Modification:     Ensure data is compliant with domain definitions 
|
| Modified By:                 Bruce Chambers
| Date of Modification:        02Feb2011
| New Version/Build Number:    3/1
| Reference:                   bjc002
| Description for Modification:Add one line to where clause
| Reason for Modification:     Enable checking of external data in CHECK mode
|
*******************************************************************************/
%macro tu_sdtmconv_pst_remove_viskeys(
);

proc sql noprint;
 create table _pst_vis_keys as 
 select memname, name 
   from dictionary.columns dc
  where libname = 'PST_SDTM'
    and name in ('VISIT','VISITNUM')
    /* BJC002: add one line to where clause : and memname in (select domain from sdtm_dom) */
    and memname in (select domain from sdtm_dom)
    and memname not in (select domain from reference where variable_name='VISITNUM' and core in ('Exp','Req'));
           
 select count(distinct memname) into :num_dsets from _pst_vis_keys;           
quit;

/* datasets created with proc sql dont seem to have _n_ , so create it  */
data _pst_vis_keys; 
 set _pst_vis_keys;
  by memname;
  retain num 0;
 if first.memname then num=num+1;
run;

%if &num_dsets >=1 %then %do;    

 %do i = 1 %to &num_dsets;
     
  data _null_;
   set _pst_vis_keys(where=(num=&i));
    call symput('DSET', left(trim(memname)));
  run; 
  
  /* Check if there is only one distinct value in the two fields */
  proc sql noprint;
   select count(distinct visitnum) into :visnum from pst_sdtm.&dset where visitnum is not null;
   select count(distinct visit) into :vis from pst_sdtm.&dset where visit is not null;
  quit;
  
  %if &visnum=1 and &vis=1 %then %do;

   %let _cmd = %str(Dropping VISIT and VISITNUM from &dset as all values are the same);%tu_sdtmconv_sys_message;

   /* If all values are the same then drop the columns as they are of no value */
   data pst_sdtm.&dset;
    set pst_sdtm.&dset(drop=VISIT VISITNUM);
   run; 
   
  %end;
    
 %end;
%end; 

/* BJC001: New step added.The CO domain does not need and should not have VISIT and VISITNUM.  
/  However, if they are present in the source data the system will populate them - so drop them here */

%if %sysfunc(exist(pst_sdtm.co)) %then %do;

 %if %length(%tu_chkvarsexist(pst_sdtm.co,visit visitnum,Y)) gt 0 %then %do;

  data pst_sdtm.co;
    set pst_sdtm.co;
    drop visit visitnum;
  run;

 %end;
  
%end;

%if &sysenv=BACK %then %do;  

%tu_tidyup(
 rmdset = _pst_vis_keys:,
 glbmac = none
);
%end;

%mend tu_sdtmconv_pst_remove_viskeys;
