/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_si_bespoke_disdr
|
| Macro Version/Build:  1 build 1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 18-Jan-2011 
|
| Macro Purpose:        Pre process to create Medhist Duration (MHDUR)  
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
| %tu_sdtmconv_pre_si_bespoke_disdr
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
%macro tu_sdtmconv_pre_si_bespoke_disdr(
); 

data pre_sdtm.disdur(drop=DURYR DURMNTH);
  set pre_sdtm.disdur;
  length MHDUR $200;
  if DURYR >= 1 and DURMNTH >= 1 then do;
   MHDUR=compress('P'||put(DURYR,8.)||'Y'||put(DURMNTH,8.)||'M');
  end;
  else if DURYR < 1 and DURMNTH >= 1 then do;
   MHDUR=compress('P'||put(DURMNTH,8.)||'M');
  end;
  else if DURYR >= 1 and DURMNTH <1 then do;
     MHDUR=compress('P'||put(DURYR,8.)||'Y');
  end;
 run;

%mend tu_sdtmconv_pre_si_bespoke_disdr;
