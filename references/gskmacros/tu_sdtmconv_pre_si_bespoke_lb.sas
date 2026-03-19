/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_si_bespoke_lb
|
| Macro Version/Build:  2 build 1
|
| SAS Version:          9.1.3
|
| Created By:           Deepak Sriramulu (based on original code by Bruce Chambers)
|
| Date:                 07-Feb-2011 
|
| Macro Purpose:        LAB pre processing 
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
| %tu_sdtmconv_pre_si_bespoke_lb
|
|*******************************************************************************
| Change Log:
|
| Modified By                 : Ashwin Venkat   
| Date of Modification        : 11Feb2011
| New Version/Build Number    : 1/1
| Description for Modification: mapping LBTSTCOM to LBREASND or CO domain based on LBORRES value
| Reason for Modification     : if LBORRES is missing then LBTSTCOM gets mapped to CO domain, else 
|                               gets mapped to CO domain
|
| Modified By                 : Bruce Chambers
| Date of Modification        : 16Jul2012
| New Version/Build Number    : 2/1
| Reference:                  : BJC002 - global change applied to code - each change not individually annotated
| Description for Modification: amend all dmdata. references to combine. to allow for SI or A&R conversions
| Reason for Modification     : streamline conversion
|
| Modified By                 : Bruce Chambers
| Date of Modification        : 07Oct2012
| New Version/Build Number    : 2/1
| Reference:                  : BJC002
| Description for Modification: 1. Update list of LBCAT values that can be flagged 
|                               2. Populate LBSTRESN where missing for numeric values, seems to happen for LBCAT=URIN
| Reason for Modification     : Complete lab data needed for all scenarios
|
*******************************************************************************/
%macro tu_sdtmconv_pre_si_bespoke_lb(
); 

%if %tu_chkvarsexist(pre_sdtm.lab,LBNRIND) ne and (not %sysfunc(exist(combine.demo)) or not %sysfunc(exist(combine.nr))) %then %do; 
   %let _cmd = %str(%STR(RTW)ARNING: Cannot run lab flagging on LAB data as combine.DEMO and-or combine.NR are not present.);%tu_sdtmconv_sys_message;
%end;

/* bjc005 - Create and populate LBCAT if missing (only expected to happen with DM SI data) */
%if %tu_chkvarsexist(pre_sdtm.lab,LBCAT) ne and %sysfunc(exist(pre_sdtm.lab)) and %sysfunc(exist(combine.lbtestcd)) %then %do ;

 %let _cmd = %str(Create and populate LBCAT);%tu_sdtmconv_sys_message;

  proc sql noprint;
     alter table pre_sdtm.lab add LBCAT char(4);
     
     update pre_sdtm.lab a set LBCAT=(select LBCAT from combine.lbtestcd b
     where a.lbtestcd=b.lbtestcd);
   quit;
  
%end;

/* VA001: only run the HARP lab macros if the normal ranges and LBNRIND  are not     
          already present.                                                       */    

%if %length(%tu_chkvarsexist(pre_sdtm.lab,LBSTNRLO LBSTNRHI)) ge 1  %then %do;
   %if %sysfunc(exist(combine.demo)) and %sysfunc(exist(combine.nr)) %then %do; 
        %let _cmd = %str(Run lab flagging on LAB data.);%tu_sdtmconv_sys_message;
       ** Add lab flagging - to populate LBNRIND column in pre-SDTM data **;
       /* bjc004 - Update tu_labfg convertyn param from N to Y so LBSTNRLO and LBSTNRHI get populated if absent (DM SI) */

       %tu_labfg (
            dsetin          = pre_sdtm.lab ,    /* Input dataset name */
            dsetout         = pre_sdtm.lab ,    /* Output dataset name */
            nrfgyn          = Y,                /* F1 Normal Range flagging */
            bsfgyn          = N,                /* F2 Change from Baseline flagging */
            ccfgyn          = N,                /* F3 Clinical Concern flagging */
            convertyn       = Y,                /* Laboratory value and normal range conversion */
            baselineyn      = N,                /* Calculation of baseline */
            labcritdset     = combine.LABCRIT,  /* Lab flagging criteria dataset name */
            nrdset          = combine.NR,       /* Normal range dataset name */
            demodset        = combine.DEMO,     /* Demography dataset name */
            stmeddset       = combine.EXPOSURE, /* Study medication dataset name */
            stmeddsetsubset = ,                 /* Where clause to be applied to study medication dataset */
            convdset        = combine.CONV,     /* Conversion dataset name */
			                  /* BJC002 - update LBCAT values */
            flaggingsubset  = %STR(LBCAT IN ('CHEM','COAG','DCSR','ENDO','HAEM','IMMU','OTHR','URIN','VIRO')), 
			                                    /* IF clause to identify records to be flagged */
            baselineoption  = DATE,             /* Calculation of baseline option */
            reldays         = ,                 /* Number of days prior to start of study medication */
            startvisnum     = ,                 /* VISITNUM value for start of baseline range */
            endvisnum       = ,                 /* VISITNUM value for end of baseline range */
            dgcd            = ,                 /* LABCRIT compound identifier */
            studyid         =                   /* LABCRIT study identifier */
              );
    %end;
%end;

/*if LBNRIND is missing */
%if %length(%tu_chkvarsexist(pre_sdtm.lab,LBNRIND LBNRCD)) ge 1 %then %do;
    %if %sysfunc(exist(combine.demo)) and %sysfunc(exist(combine.nr)) %then %do; 
        %let _cmd = %str(Run lab flagging on LAB data.);%tu_sdtmconv_sys_message;
       ** Add lab flagging - to populate LBNRIND column in pre-SDTM data **;
       /* bjc004 - Update tu_labfg convertyn param from N to Y so LBSTNRLO and LBSTNRHI get populated if absent (DM SI) */
       %tu_labfg (
            dsetin          = pre_sdtm.lab ,   /* Input dataset name */
            dsetout         = pre_sdtm.lab ,   /* Output dataset name */
            nrfgyn          = Y,               /* F1 Normal Range flagging */
            bsfgyn          = N,               /* F2 Change from Baseline flagging */
            ccfgyn          = N,               /* F3 Clinical Concern flagging */
            convertyn       = Y,               /* Laboratory value and normal range conversion */
            baselineyn      = N,               /* Calculation of baseline */
            labcritdset     = combine.LABCRIT, /* Lab flagging criteria dataset name */
            nrdset          = combine.NR,      /* Normal range dataset name */
            demodset        = combine.DEMO,    /* Demography dataset name */
            stmeddset       = combine.EXPOSURE,/* Study medication dataset name */
            stmeddsetsubset = ,                /* Where clause to be applied to study medication dataset */
            convdset        = combine.CONV,    /* Conversion dataset name */
			                         /* BJC002 - update LBCAT values */
            flaggingsubset  = %STR(LBCAT IN ('CHEM','COAG','DCSR','ENDO','HAEM','IMMU','OTHR','URIN','VIRO')), 
			                                   /* IF clause to identify records to be flagged */
            baselineoption  = DATE,            /* Calculation of baseline option */
            reldays         = ,                /* Number of days prior to start of study medication */
            startvisnum     = ,                /* VISITNUM value for start of baseline range */
            endvisnum       = ,                /* VISITNUM value for end of baseline range */
            dgcd            = ,                /* LABCRIT compound identifier */
            studyid         =                  /* LABCRIT study identifier */
              );
    %end;
%end;

run;

%let lborrn = %length(%tu_chkvarsexist(pre_sdtm.lab,lborresn));
%let lbcom = %length(%tu_chkvarsexist(pre_sdtm.lab,lbtstcom));


 /*VA001: mapping LBTSTCOM to LBREASND or  to CO domain based on LBORRES value*/
** Copy LBORRESN into LBORRES and drop LBORRESN **;
data pre_sdtm.lab(drop=lborresn);
  set pre_sdtm.lab;
  %if &lborrn eq 0 %then %do;
       if not missing(lborresn) then lborres=left(put(lborresn,best32.));
	   /* BJC002: populate LBSTRESN if null and the result is numeric - seems to happen for LBCAT=URIN */
	   if missing(lbstresn) then lbstresn=left(put(lborresn,best32.));
  %end;
  %if &lbcom eq 0 %then %do;
      if missing(lborres) and not missing(lbtstcom) then do;
         lbreasnd = lbtstcom;
         lbstat = "NOT DONE";
         lbtstcom = "";
      end;
  %end;
run;

%mend tu_sdtmconv_pre_si_bespoke_lb;
