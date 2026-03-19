/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_si_bespoke_biomr
|
| Macro Version/Build:  1 build 1
|
| SAS Version:          9.1.3
|
| Created By:           Deepak Sriramulu (based on original code by Bruce Chambers)
|
| Date:                 18-Jan-2011
|
| Macro Purpose:        Copy --ORRESN into --ORRES and drop --ORRESN
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
| %tu_sdtmconv_pre_si_bespoke_biomr
|
|*******************************************************************************
| Change Log:
|
| Modified By                 : Ashwin Venkat
| Date of Modification        : 12Feb2011 
| New Version/Build Number    : 1/1
| Description for Modification: mapping BITSTCOM to BIREASND or  to CO domain based on BIORRES value
| Reason for Modification     : if BIORRES is missing then BITSTCOM should get mapped to  BIREASND and if not missing then
|                               mapped to CO domain
*******************************************************************************/
%macro tu_sdtmconv_pre_si_bespoke_biomr(
); 

 /*VA001: mapping BITSTCOM to BIREASND or  to CO domain based on BIORRES value*/
** Copy BIORRESN into BIORRES and drop BIORRESN **;

%let biorrn = %length(%tu_chkvarsexist(pre_sdtm.biomark,biorresn));
%let bicom = %length(%tu_chkvarsexist(pre_sdtm.biomark,bitstcom));

data pre_sdtm.biomark(drop=biorresn);
  set pre_sdtm.biomark;
  %if &biorrn eq 0 %then %do;
       if not missing(biorresn) then biorres=left(put(biorresn,best32.));
  %end;
  %if &bicom eq 0 %then %do;
      if missing(biorres) and not missing(bitstcom) then do;
         lbreasnd = bitstcom;
         lbstat = "NOT DONE";
         bitstcom = "";
      end;
  %end;
run;
%mend tu_sdtmconv_pre_si_bespoke_biomr;
