/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_si_bespoke_cm
|
| Macro Version/Build:  2 build 1
|
| SAS Version:          9.1.3
|
| Created By:           Deepak Sriramulu (based on original code by Bruce Chambers)
|
| Date:                 18-Jan-2011
|
| Macro Purpose:        Conmeds pre processing
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
| %tu_sdtmconv_pre_si_bespoke_cm
|
|*******************************************************************************
| Change Log:
|
| Modified By:                   Deepak Sriramulu
| Date of Modification:     	 18April2011      
| New Version/Build Number: 	 V2 Build 1    
| Reference:                     DSS001
| Description for Modification:  Check if cmstd_ & cmend_ have non missing values
| Reason for Modification:       Code needs to take into account population with partial dates
|
*******************************************************************************/
%macro tu_sdtmconv_pre_si_bespoke_cm(
); 

* check if CMONGO (CMENRF) is present before starting this code step **;
 
 %if %tu_chkvarsexist(pre_sdtm.conmeds,cmongo) eq %then %do;     
/* DSS001: Add a check to see if there are non missing values in the character version of the date variables like cmstd_ & cmend_ */
   data pre_sdtm.conmeds; 
    attrib CMONGO length=$15 format=$15.;
    set pre_sdtm.conmeds;
     if missing(cmendt) and missing(compress(cmend_,"-")) and cmongo='Y' then cmongo='AFTER';
     if missing(cmendt) and missing(compress(cmend_,"-")) and cmongo ='N' then cmongo='U';
/* CMONGO should not be populated if CMENDT or CMEND_ are populated */
     if not missing(cmendt) or not missing(compress(cmend_,"-")) then cmongo='';
   run;
 %end;
 
 * Note: CMPRIOR(CMSTRF) has been decoded using the xls mappings Y=BEFORE,N=DURING *;
 ** BEFORE/DURING was requested but refused for CMSTRF so we assign U **;
  %let vexist= %tu_chkvarsexist(pre_sdtm.conmeds,cmprior,Y);     

    data pre_sdtm.conmeds; 
     attrib CMONGO length=$15 format=$15.;
     set pre_sdtm.conmeds;
     if cmendt=. and cmongo in ('N','U') then do;
      %if &vexist^= %then %do;
       if cmprior='Y' then cmongo='U';
       if cmprior='N' then cmongo='DURING';       
       if missing(cmendt) and missing(compress(cmend_,"-")) and cmongo='U' and cmprior='N' then cmongo='DURING/AFTER';
       if missing(cmprior)  then cmongo='U';
      %end;
      %else %do;
       cmongo='U';
      %end; 
     end;
     
     if not missing(cmstdt) or not missing(compress(cmstd_,"-")) then cmprior='';
    run;

%mend tu_sdtmconv_pre_si_bespoke_cm;
