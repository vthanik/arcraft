/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_si_bespoke_viral
|
| Macro Version/Build:  2 build 1
|
| SAS Version:          9.1.3
|
| Created By:           Deepak Sriramulu (based on original code by Bruce Chambers)
|
| Date:                 07-Feb-2011 
|
| Macro Purpose:        VIRAL pre processing 
|                       1) Run LAB flagging
|                       2) Create LBCAT, LBNRIND if missing
|                       3) Create LBORRES if LBORRESN if not missing
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
| %tu_sdtmconv_pre_si_bespoke_viral
|
|*******************************************************************************
| Change Log:
|
| Modified By                 : Ashwin Venkat
| Date of Modification        : 12Feb2011
| New Version/Build Number    : 1/1
| Description for Modification: mapping LBTSTCOM to LBREASND or  to CO domain based on LBORRES 
| Reason for Modification     : if LBORRES is missing then LBTSTCOM should get mapped to LBREASND else mapped to 
|                               CO domain
|
| Modified By                 : Bruce Chambers
| Date of Modification        : 16Jul2012
| New Version/Build Number    : 2/1
| Reference                   : BJC001 - changes not annotated individually as global edit made to all file content.
| Description for Modification: amend all dmdata. references to combine. to allow for SI or A&R conversions
| Reason for Modification     : streamline conversion
|
| Modified By                 : Bruce Chambers
| Date of Modification        : 07Oct2012
| New Version/Build Number    : 2/1
| Reference:                  : BJC004
| Description for Modification: Update tu_labfg convertyn param from N to Y so LBSTNRLO and LBSTNRHI get populated if absent 
| Reason for Modification     : Complete lab data needed for all scenarios
|
| Modified By                 : Bruce Chambers
| Date of Modification        : 07Oct2012
| New Version/Build Number    : 2/1
| Reference:                  : BJC005
| Description for Modification: Create and populate LBCAT if missing 
| Reason for Modification     : Complete lab data needed for all scenarios
|
*******************************************************************************/
%macro tu_sdtmconv_pre_si_bespoke_viral(
); 

%if %tu_chkvarsexist(pre_sdtm.viral,LBNRIND) ne and (not %sysfunc(exist(combine.demo)) or not %sysfunc(exist(combine.nr))) %then %do; 
   %let _cmd = %str(%STR(RTW)ARNING: Cannot run lab flagging on VIRAL data as combine.DEMO and-or combine.NR are not present.);%tu_sdtmconv_sys_message;
%end;

/* bjc005 - Create and populate LBCAT if missing (only expected to happen with DM SI data) */
%if %tu_chkvarsexist(pre_sdtm.viral,LBCAT) ne and %sysfunc(exist(pre_sdtm.viral)) and %sysfunc(exist(combine.lbtestcd)) %then %do ;

 %let _cmd = %str(Create and populate LBCAT);%tu_sdtmconv_sys_message;

  proc sql noprint;
     alter table pre_sdtm.viral add LBCAT char(4);
     
     update pre_sdtm.viral a set LBCAT=(select LBCAT from combine.lbtestcd b
     where a.lbtestcd=b.lbtestcd);
   quit;
  
%end;

%if %tu_chkvarsexist(pre_sdtm.viral,LBNRIND) ne and %sysfunc(exist(combine.demo)) and %sysfunc(exist(combine.nr)) %then %do; 
      %let _cmd = %str(Run lab flagging on VIRAL data.);%tu_sdtmconv_sys_message;

 ** Add lab flagging - to populate LBNRIND column in pre-SDTM data **;
 /* bjc004 - Update tu_labfg convertyn param from N to Y so LBSTNRLO and LBSTNRHI get populated if absent (DM SI) */

 %tu_labfg (
      dsetin          = pre_sdtm.viral ,   /* Input dataset name */
      dsetout         = pre_sdtm.viral ,   /* Output dataset name */
      nrfgyn          = Y,               /* F1 Normal Range flagging */
      bsfgyn          = N,               /* F2 Change from Baseline flagging */
      ccfgyn          = N,               /* F3 Clinical Concern flagging */
      convertyn       = Y,               /* Laboratory value and normal range conversion */
      baselineyn      = N,               /* Calculation of baseline */
      labcritdset     = combine.LABCRIT,  /* Lab flagging criteria dataset name */
      nrdset          = combine.NR,       /* Normal range dataset name */
      demodset        = combine.DEMO,     /* Demography dataset name */
      stmeddset       = combine.EXPOSURE, /* Study medication dataset name */
      stmeddsetsubset = ,                /* Where clause to be applied to study medication dataset */
      convdset        = combine.CONV,     /* Conversion dataset name */
      flaggingsubset  = %STR(LBCAT IN ('VIRO')), /* IF clause to identify records to be flagged */
      baselineoption  = DATE,            /* Calculation of baseline option */
      reldays         = ,                /* Number of days prior to start of study medication */
      startvisnum     = ,                /* VISITNUM value for start of baseline range */
      endvisnum       = ,                /* VISITNUM value for end of baseline range */
      dgcd            = ,                /* LABCRIT compound identifier */
      studyid         =                  /* LABCRIT study identifier */
        );
 %end;


 /*VA001: mapping LBTSTCOM to LBREASND or  to CO domain based on LBORRES value*/
** Copy LBORRESN into LBORRES and drop LBORRESN **;

%let lborrn = %length(%tu_chkvarsexist(pre_sdtm.viral,lborresn));
%let lbcom = %length(%tu_chkvarsexist(pre_sdtm.viral,lbtstcom));

data pre_sdtm.viral(drop=lborresn);
  set pre_sdtm.viral;
  %if &lborrn eq 0 %then %do;
       if not missing(lborresn) then lborres=left(put(lborresn,best32.));
  %end;
  %if &lbcom eq 0 %then %do;
      if missing(lborres) and not missing(lbtstcom) then do;
         lbreasnd = lbtstcom;
         lbstat = "NOT DONE";
         lbtstcom = "";
      end;
  %end;
run;

%mend tu_sdtmconv_pre_si_bespoke_viral;
