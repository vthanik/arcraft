/****************************************************************************************************
|
| Macro Name:      tc_sdtmconv
|
| Macro Version:   4 build 1
|
| SAS Version:     9.1
|
| Created By:      Ian Barretto
|
| Date:            14 August 2009 
|
| Macro Purpose:   Wrapper macro to convert SI datasets to SDTM structure
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| ------------------------------------------------------------------
| ------------------------------------------------------------------
|                 FOR INPUT PARAMETERS, REFER TO
|                  DOCUMENTATION FOR TU_SDTMCONV
| ------------------------------------------------------------------
| ------------------------------------------------------------------
|
| Global macro variables created: NONE
|
| Macros called:
|(@) tu_abort
|(@) tu_tidyup
|(@) tu_sdtmconv_sys_setup
|(@) tu_sdtmconv_create 
|(@) tu_sdtmconv_sys_error_check 
|
|****************************************************************************************************
| Change Log
|
| Modified By:              Bruce Chambers 
| Date of Modification:     11Jan2010
| New version/draft number: 2/1
| Modification ID:          BJC001
| Reason For Modification:  Addition of new date_window parameter (used in ...pst_sv_finisher macro)
|                            and setting default value of 0 if it is not set by the driver
|
| Modified By:              Bruce Chambers 
| Date of Modification:     11Jan2010
| New version/draft number: 2/1
| Modification ID:          BJC002
| Reason For Modification:  Addition of new check_only parameter 
|                            and setting default value of N if it is not set by the driver
|
| Modified By:              Deepak Sriramulu
| Date of Modification:     05Aug2011
| New version/draft number: 3/1
| Modification ID:          DSS001
| Reason For Modification:  Addition of new optional parameters for DM domain, so that old studies and 
|                           DM studies will still run ? they can?t be required parameters
|                           Create null fields if the variables not defined so the bespoke_dm macro wont crash
|
|
| Modified By:              Ashwin Venkat
| Date of Modification:     15May2012
| New version/draft number: 4/1
| Modification ID:          AV001
| Reason For Modification:  Addition of new parameters genericblYN, if Y then apply generic baseline flagging as per 
|                           SDTMIG guide, if N then specify baseline values (for CTSD tool)
|
| Modified By:              Ashwin Venkat
| Date of Modification:     16Oct2012
| New version/draft number: 4/1
| Modification ID:          AV002
| Reason For Modification:  Added new parameter sdtm_version which gives options to select SDTM version to be used 
							during the conversion.If missing then default version specified in MSA will be taken.
****************************************************************************************************/

%macro tc_sdtmconv (
   subset_clause   = ,  /* Specify cross source data subject subset, e.g. %str(where=(subjid in (152,164,3216))) */
   si_dsets        = ,  /* Datasets where DM SI is source data instead of A&R dataset e.g %str('RAND','VISIT') */
   visit_orig      = ,  /* A&R datasets that have not had updated VISIT values applied  e.g %str('RAND','VISIT') */
   rescue          = ,  /* Is rescue med supplied by GSK? EX = GSK does supply, rescue med goes to EX domain. CM = GSK does not supply, rescue med goes to CM domain. Leave null for non RESPiratory studies */
   rfstdt          = %str(select subjid, min(dmrefdt) as RFSTDT format=date9. from ardata.demo group by subjid) , /* Subject reference start date */
   rfendt          = %str(select subjid, max(exendt) as RFENDT format=date9. from ardata.exposure group by subjid) , /* Subject reference end date */
   svendt          = %str(select subjid, visit, visitnum, visitdt as SVENDT format=date9. from pre_sdtm.visit) , /* Subject visit end date */
   rfxstdt         = %str(select subjid, min(exstdt) as RFXSTDT format=date9. from ardata.exposure group by subjid), /* Defaults to same as RFSTDTC */
   rfxendt         = %str(select subjid, max(exendt) as RFXENDT format=date9. from ardata.exposure group by subjid), /* Defaults to same as RFENDTC */
   rfpendt         = %str(select subjid, max(dsstdt) as RFENDT format=date9. from ardata.ds where dsstdt is not null and dsscatcd=1 group by subjid), /* Defaults to same as RFENDTC */   
   rficdt		   = ,  /* This is not generally captured by GSK ; if the information has been captured by the study then  it should be mapped to this variable */
   tab_list        = ,  /* List of SI datasets to process for conversion, e.g %str('DISDUR','MEDHIST','AE','INVPCOMP') */
   tab_exclude     = ,  /* List of SI datasets to exclude from conversion , e.g %str('LAB') */
   baselineoption  = ,  /* Calculation of baseline option */
   stmeddset       = ,  /* Study medication dataset name, usually mid_sdtm.ex_exposure */
   stmeddsetsubset = ,  /* WHERE clause applied to study medication dataset */
   reldays         = ,  /* Number of days prior to start of study medication */
   startvisnum     = ,  /* VISITNUM and/or TPTNUM value for start of baseline range */
   endvisnum       = ,  /* VISITNUM and/or TPTNUM value for end of baseline range */
   genericblYN	   = ,  /* Apply generic baseline flag i.e visit just before drug exposure */
   exsubset        = ,  /* if genericblYN = Y and if exposure dataset needs to be subset then specify the condition e.g: exsubset = %str(where=(visitnum ge 20))*/
   baselinetype    = ,  /* How to calculate baseline for multiple baseline records: first, last, mean or median */
   baseln_xml      = ,  /* Pathname of an XML file for specifying parameter values to pass to tu_baseln_sdtm, in order to override  the default parameter values */ 
   versioning_dt   = ,  /* Holds the Oracle versioning date time value, format is ddmonyyyy hh24:mi */
   rand_study_id   = ,  /* RANDALL study ID when different to the eTrack study ID*/
   date_window     = ,  /* Window of days that assessments dates may precede the visit date e.g. a value of 3 means asmts up to and including 3 days before a visit wont be flagged*/
   check_only      = ,   /* Set to Y if not converting and only want to check content of /sdtm versus MSA database metadata */
   sdtm_version = /*set the SDTM version that should be used for the conversion, if blank then default version in MSA will be used */
	);

  /*
  / Parameter validation
  /----------------------------------------------------------------------------*/

  /* DSS001: Create macro parameters RFXSTDT, RFXENDT, RFPENDT & RFICDT if they are not created. */
  /* This is done to make sure the programs will run for the conversions which are already completed. */
     
	 %if not %symexist(RFXSTDT) %then %let RFXSTDT=;
     %if not %symexist(RFXENDT) %then %let RFXENDT=;
	 %if not %symexist(RFPENDT) %then %let RFPENDT=;
	 %if not %symexist(RFICDT) %then %let RFICDT=;
  
  /*
  / BJC001 - default value for new date_window parameter if not defined (used in ...pst_sv_finisher macro) 
  /----------------------------------------------------------------------------*/

  %if %length(&date_window) eq 0 %then
  %do;
   %let date_window=0;
  %end;

  /*
  / BJC002 - default value for new check_only parameter if not defined  
  /----------------------------------------------------------------------------*/

  %if %length(&check_only) eq 0 %then
  %do;
   %let check_only=N;
  %end;


  %if &rescue NE EX and &rescue NE CM and &rescue NE %then %do;
    %put RTE%str(RROR): &sysmacroname.: RESCUE must have a value of EX,CM or null;
    %let g_abort=1;
  %end;

  %if %length(&rfstdt) eq 0 %then 
  %do;
    %put RTE%str(RROR): &sysmacroname.: A value must be supplied for RFSTDT;
    %let g_abort=1;
  %end;

  %if %length(&rfendt) eq 0 %then 
  %do;
    %put RTE%str(RROR): &sysmacroname.: A value must be supplied for RFENDT;
    %let g_abort=1;
  %end;

  %if %length(&svendt) eq 0 %then 
  %do;
    %put RTE%str(RROR): &sysmacroname.: A value must be supplied for SVENDT;
    %let g_abort=1;
  %end;

  * CANNOT HAVE TAB_LIST and TAB_EXCLUDE active at same time;
  %if %length(&tab_list) NE 0 and %length(&tab_exclude) NE 0 %then 
  %do;
    %put RTE%str(RROR): &sysmacroname.: Cannot have included and exclude Spectre table lists;
    %let g_abort=1;
  %end;

  /*
  / The BASELN_XML parameter is optional, but if a non-blank value is specified,
  / then it must be the pathname for a file that actually exists. SL001
  /----------------------------------------------------------------------------*/

  %if %length(&baseln_xml) gt 0 %then
  %do;
    %if %sysfunc(fileexist(&baseln_xml)) eq 0 %then
    %do;
      %put RTE%str(RROR): &sysmacroname.: BASELN_XML (=&baseln_xml) has been specified, but does not correspond to a file that exists;
      %let g_abort=1;
    %end;
  %end;

  /*
  / Complete validation
  /----------------------------------------------------------------------------*/
  %if %eval(&g_abort) gt 0 %then %do;
    %put %str(RTE)RROR: &sysmacroname: Macro has failed parameter validation check for reasons stated with %str(RTE)RRORs above;
    %tu_abort(option=force);
  %end;

  /*
  / Format parameters if blank prior to running the main macro
  /----------------------------------------------------------------------------*/
  %if %length(&si_dsets) eq 0 %then 
  %do;
    %let si_dsets=%str('null');
  %end;

  %if %length(&visit_orig) eq 0 %then 
  %do;
    %let visit_orig=%str('null');
  %end;


  /*
  / NORMAL PROCESSING
  /----------------------------------------------------------------------------*/

  /* Globalise all parameter to be use by lower level macros */
  %global g_sdtmconv_env set_options;

  /* Check if running in AR or DM environment by checking if TS_SETUP global exists*/

  %if %symexist(g_stype) %then %do;
    %let g_sdtmconv_env=AR;
  %end;
  %else %do;
    %let g_sdtmconv_env=DM;
  %end;

  /* Set options to enable to the abort to operate imediately if in batch mode */

  %if &SYSENV eq BACK %then
  %do;
    options errorabend;
  %end;
  %else
  %do;
    options noerrorabend;
  %end;

  /*
  / Set Up debugging options
  /----------------------------------------------------------------------------*/

  %if &g_debug>=5 %then %do;
	%let set_options=mprint mlogic symbolgen source source2 notes;
  %end;
  %else %if &g_debug=0 %then %do;
	%let set_options=nomprint nomlogic nosymbolgen nosource nosource2 nonotes;
  %end;
  %else %if &g_debug= %then %do;
 	%let set_options=nomprint nomlogic nosymbolgen nosource nosource2 nonotes; 
  %end;


  /*
  / Set versioning_dt macro variable with current date and time if nothing
  / is passed in by the user.
  /----------------------------------------------------------------------------*/
  %local l_curr_date l_curr_time;

  %if %length(&versioning_dt) eq 0 %then
  %do;

     data _NULL_;
        call symput('l_curr_time',trim(left(put(time(),time5.))));
        call symput('l_curr_date',trim(left(put(date(),date9.))));
     run;

     %let versioning_dt = %str(%')&l_curr_date &l_curr_time%str(%'); 
     %put %str(RTN)OTE: &sysmacroname.: Version_dt macro is missing so value will be set to current date and time: &versioning_dt;

  %end;
  %else 
     %let versioning_dt = %str(%')&versioning_dt%str(%');

  * check for any errors up to this point **;
  %tu_sdtmconv_sys_error_check;

  * Set up the SDTMCONV environment;
  %tu_sdtmconv_sys_setup;


  *Perform the conversion of SI datasets to SDTM structure;
  %tu_sdtmconv_create;

  /*
  / Delete temporary datasets used in this macro.
  / Only delete if running in batch and if the __UTC_WORKPATH global macro
  / variable is not used.  If running interactively assume you want to keep 
  / the datasets.
  /----------------------------------------------------------------------------*/
  %if &sysenv=BACK and %symexist(__utc_workpath) eq 0 %then %do; 
    %tu_tidyup(glbmac=NONE);
  %end;
  %else %if %symexist(__utc_workpath) ne 0  %then %do; 
    * Take a copy of the WORK library and place in the __UTC_WORKPATH if requested;
    %if %sysfunc(fileexist(&work_path.work_sdtm)) ne 1 %then %do;
      x mkdir &work_path.work_sdtm;  
     %end;

    libname wrk_sdtm "&work_path.work_sdtm";

    proc copy in=work out=wrk_sdtm;
    run;

    %tu_tidyup(glbmac=NONE);
  %end;
  
  
%mend tc_sdtmconv;



