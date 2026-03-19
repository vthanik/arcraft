/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_si_bespoke_visit
|
| Macro Version/Build:  1 build 1
|
| SAS Version:          9.1.3
|
| Created By:           Deepak Sriramulu (based on original code by Bruce Chambers)
|
| Date:                 07-Feb-2011 
|
| Macro Purpose:        Visit pre processing
|
| Macro Design:         Procedure
|
| Input Parameters:
| 
| NAME                  DESCRIPTION                                  DEFAULT           
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
| (@)tu_sdtmconv_sys_message
| (@)tu_sdtmconv_sys_error_check
|
| Example:
|
| %tu_sdtmconv_pre_si_bespoke_visit
|
|*******************************************************************************
| Change Log:
|
| Modified By                 : 
| Date of Modification        : 
| New Version/Build Number    : 
| Description for Modification: 
| Reason for Modification     : 
|
*******************************************************************************/
%macro tu_sdtmconv_pre_si_bespoke_visit(
);
%if %length(&SVENDT) >= 1 %then %do;
 
  proc sql noprint;
   create table svendt as (&svendt);
  quit; 
 
  proc sort data=pre_sdtm.visit;
   by subjid visit visitnum;
  run;
  
  proc sort data=svendt;
     by subjid visit visitnum;
  run;
 
  data pre_sdtm.visit;
   merge pre_sdtm.visit svendt;
   by subjid visit visitnum;
  run; 
 
 %end;

%mend tu_sdtmconv_pre_si_bespoke_visit;
