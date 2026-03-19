/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_si_bespoke_dm
|
| Macro Version/Build:  13 build 1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009
|
| Macro Purpose:        Pre-process DEMO data according to mapping specs.
|                       NB:Great examples for RACE processing are ukwsv80d:gw642444/b2c109575 subjids:1712,3155
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
| (@)tu_nobs
| (@)tu_sdtmconv_sys_message 
| (@)tu_decode
| (@)tu_chkvarsexist
| (@)tu_tidyup 
|
| Example:
|
| %tu_sdtmconv_pre_si_bespoke_dm
|
|*******************************************************************************
| Change Log:
|
| Modified By:                   Deepak Sriramulu
| Date of Modification:          30 Aug 2010
| New Version/Build Number:      2 build 1
| Reference:                     DSS001
| Description for Modification:  combine both DM & A&R library into one and look for RACE dataset
| Reason for Modification:       DMDATA.RACE dataset expected by DM conversion piece. Need a check to confirm this is present, as it has often not been!
|
| Modified By:                   Deepak Sriramulu
| Date of Modification:          04 Jan 2011
| New Version/Build Number:      3 build 1
| Reference:                     DSS002
| Description for Modification:  Prefix RTWARNING onto DM domain may be incomplete - DS [or DISPOSIT-SCRNFAIL] source dataset needed to populate ARM/ARMCD for non-treated subjects
| Reason for Modification:       To notify the user that DS/DISPOSIT dataset is required to populate ARM/ARMCD for SCREEN FAIL subjects
|
| Modified By:                   Bruce Chambers
| Date of Modification:          24 January 2011
| New Version/Build Number:      3 build 1
| Reference:                     BJC001
| Description for Modification:  Only create new randall and investig dataset if correctly formatted datasets not already present
| Reason for Modification:       Efficiency purposes - also ensures same data used to build SDTM as was reported from
|
| Modified By:                   Bruce Chambers
| Date of Modification:          24 January 2011
| New Version/Build Number:      3 build 1
| Reference:                     BJC002
| Description for Modification:  Refer to combine.enrol instead of dmdata.enrol 
| Reason for Modification:       Flexibility - Allow for scenarios where dmdata not available
|
| Modified By:                   Bruce Chambers
| Date of Modification:          29 March 2011
| New Version/Build Number:      4 build 1
| Reference:                     BJC003
| Description for Modification:  Initialise RACE variables as null for each subject - they were incorrectly retained  
| Reason for Modification:       The data was not correct, spotted in QC
|
| Modified By:                   Bruce Chambers
| Date of Modification:          29 March 2011
| New Version/Build Number:      4 build 1
| Reference:                     BJC004
| Description for Modification:  RACEORn variables and multiple race scenarios not populating correctly
| Reason for Modification:       The data was not correct, spotted in QC
|
| Modified By:                   Bruce Chambers
| Date of Modification:          29 March 2011
| New Version/Build Number:      4 build 1
| Reference:                     BJC005
| Description for Modification:  RAND references changed to RANDALL 
| Reason for Modification:       To ensure we only pull new data from RANDALL when necessary
|
| Modified By:                   Bruce Chambers
| Date of Modification:          15 May 2011
| New Version/Build Number:      5 build 1
| Reference:                     BJC006
| Description for Modification:  Amend if /end statments to only run tu_chkvars exist if randall data present
| Reason for Modification:       To avoid potential g_abort scenario
|
| Modified By:                   Bruce Chambers
| Date of Modification:          08 Aug 2011
| New Version/Build Number:      6 build 1
| Reference:                     BJC007
| Description for Modification:  Set correct counter to not retain previous details and also check for RFSTDM
|                                when processing AGE
| Reason for Modification:       The data was not correct, spotted in QC
|
| Modified By:                   Bruce Chambers
| Date of Modification:          04 Nov 2011
| New Version/Build Number:      7 build 1
| Reference:                     BJC008
| Description for Modification:  Populate RACEOR1 for non-multiple race subjects
| Reason for Modification:       The data was not correct, spotted in QC
|
| Modified By:                   Deepak Sriramulu
| Date of Modification:          05Aug2011
| New version/draft number:      8/1
| Modification ID:               DSS003
| Reason For Modification:       Addition of new optional parameters for DM domain, so that old studies and 
|                                DM studies will still run � they can�t be required parameters
|
| Modified By:                   Deepak Sriramulu
| Date of Modification:          12Feb2012
| New version/draft number:      9 build 1
| Modification ID:               DSS004
| Reason For Modification:       Remove code to populate ACTARM & ACTARMCD from exposure. Now this is taken from DEMO itself. Mapping added to MSA.
|
| Modified By:                   Ashwin V
| Date of Modification:          13FEb2012
| New Version/Build Number:      9 build 1
| Reference:                     AV001
| Description for Modification:  modified macro to first check ardata.investig for required variables, if missing then
| Reason for Modification:       fall back to dmdata.investig
|                                
| Modified By:                   Bruce Chambers
| Date of Modification:          04 Mar 2012
| New Version/Build Number:      9 build 1
| Reference:                     BJC009
| Description for Modification:  Further fix to BJC008: Populate RACEOR1 for non-multiple race subjects
| Reason for Modification:       The data was not correct, spotted in QC
|
| Modified By:                   Bruce Chambers
| Date of Modification:          16 Jul 2012
| New Version/Build Number:      10 build 1
| Reference:                     BJC010
| Description for Modification:  Further fix to BJC002: One definition of dmdata.enrol not updated to combine.enrol
| Reason for Modification:       Ensure all scenarios process correctly
|
| Modified By:                   Bruce Chambers
| Date of Modification:          26 Sep 2012
| New Version/Build Number:      10 build 1
| Reference:                     BJC011
| Description for Modification:  Flag to users subjects with a RANDNUM that are also SF/RIDO
| Reason for Modification:       Ensure SDTM reflects the scenario correctly - the DM.ARM will be the treatment group, 
|                                not the SF/RIDO value
|
| Modified By:                   Bruce Chambers
| Date of Modification:          19 Feb 2013
| New Version/Build Number:      11 build 1
| Reference:                     BJC012
| Description for Modification:  Process country data in a better way
| Reason for Modification:       To ensure non-CT compliant issues are reported as such and not left as null
|
| Modified By:                   Bruce Chambers
| Date of Modification:          19 Mar 2013
| New Version/Build Number:      12 build 1
| Reference:                     BJC013
| Description for Modification:  Add new DTH IDSL datagroup as a variant of DEATH 
| Reason for Modification:       To ensure correct merge of additional data for DM domain
|
| Modified By:                   Bruce Chambers
| Date of Modification:          17 May 2013
| New Version/Build Number:      12 build 1
| Reference:                     BJC014
| Description for Modification:  Deal with South Korea having >1 synonym 
| Reason for Modification:       To ensure correct merge of additional data for DM domain
|
| Modified By:                   Bruce Chambers
| Date of Modification:          19 May 2013
| New Version/Build Number:      13 build 1
| Reference:                     BJC015
| Description for Modification:  Create a temporary RFSTDT if RFSTDM is present
| Reason for Modification:       Enable age calculation for SI data using RFSTDM (datetime version)
|                                (Not an issue previously as A&R datasets already had age in DEMO)
|
*******************************************************************************/
%macro tu_sdtmconv_pre_si_bespoke_dm(
);

/* Sort the DEMO data as it now wont happen in the RAND step to allow the run to proceed */
proc sort data=pre_sdtm.demo;
 by SUBJID;
run;

** combine demo data with investig to get country and investigator info **;
** also combine demo data with race and randall data **;
*******************************************************************************;
** Extract RANDALL data to combine onto DEMO data **;

%if not %sysfunc(exist(pre_sdtm.rand)) %then %do;
 %let _cmd = %str(%str(RTW)ARNING: DM domain will be incomplete - RAND source dataset needed as RANDNUM is a link item);
 %tu_sdtmconv_sys_message; 
 %let _cmd = %str(ARM and ARMCD will not be present in DM domain data);%tu_sdtmconv_sys_message;
 
%end;

%if %sysfunc(exist(pre_sdtm.rand)) %then %do;

 /* BJC001 - only create new RANDALL data if standard RANDALL dataset not already present */
 /* BJC005: amend RAND dataset reference to RANDALL for tu_chkvarsexist calls */
 /* BJC006: amend how if statements are set out */
 %if %sysfunc(exist(combine.randall)) %then %do;
     %if %tu_chkvarsexist(combine.randall,RANDNUM) eq 
     and %tu_chkvarsexist(combine.randall,TRTDESC) eq and %tu_chkvarsexist(combine.randall,TRTGRP) eq
     and %tu_chkvarsexist(combine.randall,PTRTGRP) eq and %tu_chkvarsexist(combine.randall,PERNUM) eq %then %do;
     
  %let _cmd = %str(Standard RANDALL dataset found in ardata and/or dmdata library);%tu_sdtmconv_sys_message;

   data _pre_bespoke_dm_tmprandall;
    set combine.randall(rename=(randnum=treatment_allocation trtdesc=description
                                trtgrp=seq ptrtgrp=code pernum=period));
   run; 
  %end;
 %end; 
 %else %do;
 
  ** May need to set a different Randall ID - this can be done in driver using rand_study_id **;
  %if &rand_study_id eq %then %let ra_protocol = upper(%unquote(%str(%')%upcase(&g_study_id)%str(%')));
  %if &rand_study_id ne %then %let ra_protocol = upper(%unquote(%str(%')%upcase(&rand_study_id)%str(%')));

  %let _cmd = %str(Fetching RANDALL data for &rand_study_id &g_study_id);%tu_sdtmconv_sys_message;

  ** Prevent password being echoed under any circumstance *;
  options nomprint nomlogic nosymbolgen nosource nosource2 nonotes;

  proc sql noerrorstop exec;
      connect to oracle as db (user=&spec_ac password=&spec_pw path=&spec_db);
      execute(SET ROLE ALL) by db;
      create table _pre_bespoke_dm_tmprandAll as select * from connection to db
      (select * from table(cast(fSAS_ET(&ra_protocol) as cSAS_ET)));
      disconnect from db;
  quit;
 
  options &set_options;
 
 %end; /* BJC001 - END for IF only create randall data if not already present */
  
 %if %eval(%tu_nobs(_pre_bespoke_dm_tmprandall))=0 %then %do;
  %let _cmd = %str(%str(RTW)ARNING: No RANDALL data rows found for &g_study_id);%tu_sdtmconv_sys_message;
  %let _cmd = %str(The DM domain will deficient as ARM and ARMCD will not be present );%tu_sdtmconv_sys_message;
  %let _cmd = %str(Specify correct RANDALL studyID as rand_study_id macro var );%tu_sdtmconv_sys_message;
 %end;
 %if %eval(%tu_nobs(_pre_bespoke_dm_tmprandall))>=1 %then %do;
  
  data _pre_bespoke_dm_randall(keep=randnum ARM ARMCD period); 
   set _pre_bespoke_dm_tmprandall(rename=(treatment_allocation=randnum seq=ARM code=ARMCD));
  run; 

  /* Deal with how crossover versus non-crossover studies are set up in Randall 
  /  for crossovers, Randall will store one row per period. As this is used to populate ARM/ARMCD in
  /  the DM domain, we need one row per subject. SEQ will always be ARM in SDTM. CODE will be ARMCD, 
  /  but multiple values of code for a RANDNUM will be denormalised e.g. a row with CODE/ARMCD=A, 
  /  one row with CODE/ARMCD=B - these will be become one row (for the RANDNUM) with CODE/ARMCD=A-B */
  
  %let num_period=0; 
   proc sql noprint;
      select count(unique(period)) into :num_period
        from _pre_bespoke_dm_randall;
   quit;
  
  %if &num_period>1 %then %do;
   proc sort data=_pre_bespoke_dm_randall;
    by randnum period;
   run;
  
   data _pre_bespoke_dm_randall(drop=period ); 
    set _pre_bespoke_dm_randall(rename=(ARMCD=orig_code));
    length ARMCD $200;
    retain ARMCD ;
    by randnum ;
    if first.randnum  then ARMCD=orig_code;
    else ARMCD=compress(ARMCD||'-'||orig_code);
    if last.randnum  then output;
    if length(ARMCD)>20 then do;
     put "RTW" "ARNING:  Length of ARMCD will be more than 20 chars" ; 
     put ARMCD=;
    end;
   run;
  %end; 
 
  proc sort data=_pre_bespoke_dm_randall nodupkey;
   by randnum; run;

  proc sort data=pre_sdtm.rand out=_pre_bespoke_dm_rand;
   by randnum; run;

  data _pre_bespoke_dm_comb_rand;
   merge _pre_bespoke_dm_rand(in=a) _pre_bespoke_dm_randall;
   by randnum;
   if a;
  run;

  proc sort data=_pre_bespoke_dm_comb_rand;
   by SUBJID;
  run;
  
  proc sort data=pre_sdtm.demo;
     by SUBJID;
  run;
 
  /* merge demo data with randall data - RANDNUM comes from RAND source data to DS via separate 
  / route, so drop this copy of RANDNUM */;
  data pre_sdtm.demo;
   merge pre_sdtm.demo(in=ina)
         _pre_bespoke_dm_comb_rand(keep=SUBJID ARM ARMCD);
      by SUBJID;
      if (ina) then output pre_sdtm.demo;    
  run;
 
 %end;
%end;

********************************************************************************************************;
** Extract INVESTIG data to combine onto DEMO data **;

/* BJC001 : If INVESTIG data exists (with COUNTRY present) then re-use it */
/* AV001: modified macro to first check ardata.investig for required variables if not fall back to dmdata.investig */

%let source = dmdata;
%if %sysfunc(exist(ardata.investig)) %then %do;
    %if %length(%tu_chkvarsexist(ardata.investig, country etsbjsts centreid invid invname)) eq 0 %then %do;
        %let source = ardata;
    %end;
    %else %do;
       %let _cmd = %str(%str(RTW)ARNING: AR INVESTIG dataset does not have some of the required SI variables);
  %tu_sdtmconv_sys_message;

    %end;
%end;

%if %sysfunc(exist(&source..investig)) %then %do;
    %if %length(%tu_chkvarsexist(&source..investig, country etsbjsts centreid invid invname)) eq 0 %then %do;

     %let _cmd = %str(Standard INVESTIG dataset found in &source library);%tu_sdtmconv_sys_message;

     data _pre_bespoke_dm_investig;
      set &source..investig(rename=(invname=invnam country=country_name));
     run; 
    %end;
%end;  /*AV001 : end of code modification*/
%else %do;
 %let _cmd = %str(Fetching INVESTIG data for &g_study_id);%tu_sdtmconv_sys_message;

 ** Prevent password being echoed under any circumstance *;
 options nomprint nomlogic nosymbolgen nosource nosource2 nonotes;

 proc sql; connect to oracle
    (user=&mip_ac orapw=&mip_pw path=&mip_db buffsize=500);
  
    create table _pre_bespoke_dm_investig as select 
      %* Get the Phase 2 - 4 data ;
        "&g_study_id" as studyid format $10. length=10 label='Unique identifier for the study',
         subject_id as SUBJID format 10. label='Subject ID',
         centre||"                                              " as CENTREID	format $45. length=45 label='Centre ID',
         invs_id as INVID format $8.length=8  label='Investigator ID',
	 invs_last_name as INVNAM format $30. length=30 label='Investigator Name', 
	 subject_status as etsbjsts format $40. length=40 label='Subject status from eTrack',
	 upper(MANAGING_COUNTRY_NM) as country_name
	 from connection to oracle
	 (select b.subject_id,
	         c.centre,
	         a.invs_id,
	         a.invs_last_name,
	         b.subject_status,
	         d.MANAGING_COUNTRY_NM
             from mip_met_mcrr_investigator a,
                 mip_met_mcrr_subject b,
                 mip_met_mcrr_center c,
                 mip_met_mcrr_country d,
                 mip_met_mcrr_study e
            where a.center_id = c.center_id AND
                  c.study_id = e.study_id AND
                  c.center_id = b.center_id AND
                  c.country_id = d.country_id AND 
                  e.business_area_desc ^= ('CPDM') AND
                  e.clinical_study_id = upper(%unquote(%str(%')%upcase(&g_study_id)%str(%'))) AND
                  b.subject_status ^= 'Moved Centre'
 UNION ALL
      %* Get the Phase 1 data that has no subject level tracking ;
         select 0,
	 	c.centre,
	 	a.invs_id,
	 	a.invs_last_name,
	        '',
	        d.MANAGING_COUNTRY_NM 
            from mip_met_mcrr_investigator a,
                 mip_met_mcrr_center c, 
                 mip_met_mcrr_country d,
                 mip_met_mcrr_study e
            where a.center_id = c.center_id AND
                  c.study_id = e.study_id AND 
                  c.country_id = d.country_id AND
                  e.business_area_desc = ('CPDM') AND
                  e.clinical_study_id = upper(%unquote(%str(%')%upcase(&g_study_id)%str(%'))) );
 disconnect from oracle;                  
 quit;

 /* Now we are done with all the Oracle queries to Spectre/DSM and GRIP- remove the password so that 
 /  they cant be obtained by a user */
 %symdel mip_pw spec_pw dsm_pw benv_pw;

 options &set_options;

%end;

%if %sysfunc(exist(_pre_bespoke_dm_investig)) %then %do;

 %if %eval(%tu_nobs(_pre_bespoke_dm_investig))=0 %then %do;
  %let _cmd = %str(%str(RTW)ARNING: No INVESTIG data rows found for &g_study_ID.);%tu_sdtmconv_sys_message;
  %let _cmd = %str(The DM domain will be deficient as SITEID and COUNTRY will not be present );%tu_sdtmconv_sys_message;
 %end;

 /* The country system format is used in a different way to all other formats as the SDTM_VALUE or the 
 /  value is not the SDTM version, it is a decode used to combine with a list of ISO3166 countries
 /  stored as system metadata */
 /* BJC012 - append a 1 to the dataset name below so in the next proc sql step we dont get an overwrite warning */
 data _pre_bespoke_dm_investig1 ;
  set _pre_bespoke_dm_investig;
  country_name=put(upcase(country_name),$country.);
 run; 

 /* BJC012 - remove sort step and datastep as no longer needed*/

 proc sql noprint;
  create table sdtm_cntry as
   select cdisc_synonyms as country_name, cdisc_submission_value as COUNTRY
   from codelist_details 
   where codelist_code = 'C66786'
   order by cdisc_synonyms;
 quit;
 
/* BJC014: Deal with one quirky entry in the CDISC master data for HONG KONG */
 data sdtm_cntry;
  set sdtm_cntry;
  if country_name='SOUTH KOREA; KOREA, REPUBLIC OF' then country_name='SOUTH KOREA';
 run; 
 
 /* BJC012: rewrite step to keep non-CT country values so they get reported as non-CT compliant */
 
 proc sql noprint;
      create table _pre_bespoke_dm_investig as
      select a.studyid, a.subjid, a.centreid, a.invnam, a.invid, a.etsbjsts, coalesce(b.country,a.country_name) as country
      from _pre_bespoke_dm_investig1 as a left join sdtm_cntry as b
      on a.country_name=b.country_name
      order by subjid;
quit;

 ** Check if the study is a Clin Pharm study (no subject level data in eTrack)**;
 proc sql noprint;
  select count(*) into :null_subs 
  from _pre_bespoke_dm_investig
  where SUBJID=0;
 quit; 
  
 %if &null_subs=0 %then %do;
 
  ** Fully tracked study - use SUBJID as link **;
  ** merge demo data with investig **;
  data pre_sdtm.demo(drop=etsbjsts) 
       _pre_bespoke_dm_no_demo_inv 
       _pre_bespoke_dm_no_invest;
   merge pre_sdtm.demo(in=ina)
          _pre_bespoke_dm_investig(in=inb keep=SUBJID centreid invid invnam country etsbjsts);
    by SUBJID;
    if (ina) then output pre_sdtm.demo;
    
    if (ina*^inb) then output _pre_bespoke_dm_no_invest;
    else if (inb*^ina) then output _pre_bespoke_dm_no_demo_inv;
  run;
  
  %if %length(&subset_clause)=0 %then %do;
   %if %eval(%tu_nobs(_pre_bespoke_dm_no_demo_inv))>=1 %then %do;
    %let _cmd = %str(%str(RTW)ARNING: One or more subjects in eTrack not in SI DEMO dataset);%tu_sdtmconv_sys_message;
     proc print data=_pre_bespoke_dm_no_demo_inv noobs label;
      where etsbjsts not in ('Screen Failure','Pre-screen Failure');
      var SUBJID etsbjsts;  
      label etsbjsts='eTrack subject status';
      title3 "SDTM conversion:  &g_study_id : Subjects in eTrack not in SI DEMO dataset";
     run;

     proc sql noprint;
      select count(*) into :scr_fail 
      from _pre_bespoke_dm_no_demo_inv
      where etsbjsts ='Screen Failure';
     quit; 

     %let _cmd = %str(%str(RTN)OTE: TU_SDTMCONV_PRE_SI_BESPOKE_DM: &scr_fail screen fail subjects in eTrack not in SI DEMO dataset);%tu_sdtmconv_sys_message;

   %end;
  %end;
 %end;

 /* BJC002: Refer to combine.enrol instead of dmdata.enrol to make code more flexible */
 %if &null_subs>=1 and %sysfunc(exist(combine.enrol)) %then %do;
 
   ** Clin Pharm tracked study - need to add SUBJID from ENROL to use as link **;
   ** merge enrol data with investig first**;
   
   proc sort data=_pre_bespoke_dm_investig out=_pre_bespoke_dm_investig;
     by centreid;run;
   
   proc sort data=combine.enrol
     %if %length(&subset_clause) >= 1 %then %do;
      (&subset_clause)
     %end;   
             out=_pre_bespoke_dm_enrol;
     by centreid;
   run;
   
   data _pre_bespoke_dm_investig;
    merge _pre_bespoke_dm_investig(in=inv) 
          _pre_bespoke_dm_enrol(keep=studyid centreid SUBJID);
       by centreid;
       if inv;
   run;
         
   proc sort data=_pre_bespoke_dm_investig;
   by SUBJID;
   run;      
        
   data pre_sdtm.demo _pre_bespoke_dm_no_demo_inv _pre_bespoke_dm_no_invest;
    merge pre_sdtm.demo(in=ina)
           _pre_bespoke_dm_investig(in=inb keep=SUBJID centreid invid invnam country);
     by SUBJID;
     if (ina) then output pre_sdtm.demo;
     
     if (ina*^inb) then output _pre_bespoke_dm_no_invest;
     else if (inb*^ina) then output _pre_bespoke_dm_no_demo_inv;
  run;
  
 %end; 
 
 /* BJC010: one instance of dmdata.enrol not changed to combine.enrol - fix this */
 %if &null_subs>=1 and not %sysfunc(exist(combine.enrol)) %then %do;
  %let _cmd = %str(%str(RTW)ARNING: Need DM SI ENROL dataset to merge with eTrack INVESTIG data);%tu_sdtmconv_sys_message;
  %let _cmd = %str(DM DOMAIN data will not have required COUNTRY data present);%tu_sdtmconv_sys_message;
 %end;
 

 %if %sysfunc(exist(_pre_bespoke_dm_no_invest)) %then %do;
  ** print no_invest as this means data from eTrack is not up to date **; 
  proc print data=_pre_bespoke_dm_no_invest noobs;
     var studyid SUBJID;  
    title3 "SDTM conversion &g_study_id : Data in DEMO but not in eTrack Investigator details";
    title4 "NOTE: DM domain country details may not decode correctly in SDTM for these subjects.";
  run;
 %end;
  
%end;

******************************************************************************;
** Pre process RACE SI dataset to subset out subject with >=2 RACE values **;
** Seondary race values are recorded in SC domain **;

/* DSS001 */

%if %sysfunc(exist(combine.race)) eq 0 %then %do;
   %let _cmd = %str(%str(RTW)ARNING: No RACE data found with SI or A+R datasets.);%tu_sdtmconv_sys_message;
   %let _cmd = %str(The DM domain will be deficient as RACEC will not be present );%tu_sdtmconv_sys_message;
   
%end;

/*DSS001 */

%if %sysfunc(exist(combine.race)) %then %do;
 /* If the RACE dataset is present in DMDATA and ARDATA libraries, then use the ARDATA version.
 /  If the RACE dataset is only present in the DM SI then use that.
 /  Not possible for RACE to be present in ARDATA and not DMDATA so no need to code for that */
 

/* DSS001 */ 
  ** As RACE mappings are associated with DEMO with have to copy data manually **;
  data pre_sdtm.race; 
   set combine.race
    %if %length(&subset_clause) >= 1 %then %do;
      (&subset_clause)
   %end;   
   ;
  run;

   /* If the DM SI is used then decode the coded items */
  %if %tu_chkvarsexist(pre_sdtm.race,racec) ne %then %do;   
   %tu_decode(
        dsetin  = pre_sdtm.race,
        dsetout = pre_sdtm.race,
        dsplan  = ,
        formatnamesdset = FMTVARS
       );
  %end;

  %if %eval(%tu_nobs(pre_sdtm.race))>=1 %then %do;
   
   proc sql noprint;
    create table SUBJIDs_with_mult_races as
    select distinct SUBJID 
    from pre_sdtm.race
    where seq >=2;
    
    create table _pre_bespoke_dm_mult_races as 
    select * from pre_sdtm.race
    where SUBJID in (select SUBJID from SUBJIDs_with_mult_races);
   quit;
   
   proc sql noprint;
    select trim(left(put(max(seq),8.))) into :max_race_seq
    from _pre_bespoke_dm_mult_races;
    
    delete from pre_sdtm.race 
    where SUBJID in (select SUBJID from SUBJIDs_with_mult_races);
   quit;
 
   proc sort data=_pre_bespoke_dm_mult_races;
   by SUBJID;run;
   
   proc sort data=pre_sdtm.race;
   by SUBJID;run;
  
   ** Only process array if multiple races are found **;
   %if %eval(%tu_nobs(_pre_bespoke_dm_mult_races))>=1 %then %do;

    data _pre_bespoke_dm_mult_races (drop=seq RACE0);
     set _pre_bespoke_dm_mult_races;
     
       /* BJC003: set length as variables are now initialised on first pass. 
                  Also set dummy RACE0 variable to prevent format warning but later gets dropped */
       length RACE0-RACE&max_race_seq RACEOR1-RACEOR&max_race_seq $200;

       retain RACE1-RACE&max_race_seq RACEOR1-RACEOR&max_race_seq;
       by SUBJID;
       
        /* BJC003: fix to reinitialise variables for each new subject */
		/* BJC007: amend the hardcoded 3 to &max_race_seq */
        if first.subjid then do;
         %DO z=1 %TO &max_race_seq;
          RACE&z='';
          RACEOR&z='';
         %end;
        end;       
       
         %DO z=1 %TO &max_race_seq;
           %let y=%eval(&z-1);
           attrib RACE&Z label="RACE &z";
           attrib RACEOR&Z label="Original RACE value &z";
           attrib RACE&Z label="RACE value &z";           

           if seq=&z then do;
            RACE&z=RACEC;
            ** Keep a copy of the original race value to later report **;
            RACEOR&z=RACE&z;
            ** Decode the race values now **;

            /* BJC004 -rewrite this step to deal with complex multiples */
            if last.SUBJID then do;
             RACEC='MULTIPLE';            
            end;           
              
            /* for the first race - do a complete decode */  
            if &z=1 then RACE&z=put(RACEC,$RACE.);
            /* For the second and subsequent RACE - check the value is not the same DECODE as the one before */
            /* NB-BJC: still need to sort by decoded race to be sure */
	    else if &z>=2 then do;
	     if (put(RACE&z,$RACE.) ^= put(RACE&y,$RACE.)) then RACE&z=put(RACE&z,$RACE.);  
	     /* If the decode is the same as the one before then null the second SDTM decode */	     
	     if (put(RACE&z,$RACE.) = put(RACE&y,$RACE.)) then do;
               /* If there are only 2 race values then reset/update the main RACE value for the DM domain data */
	       if first.subjid=1 or last.subjid=1 then do;
	        RACEC=put(RACE&z,$RACE.);
	        /* If there are only two races for a subject then also remove the previous value */
	        RACE&y='';
	       end;
	      /* whatever the total number - remove the last duplicate value */ 
	      RACE&z='';
	     end; 
	    end; 
           end; 
         %end;
        if last.SUBJID then do;
          output;
        end;
    run;
   
   /* BJC004: Add check for any multiple race data for which there is no mapping. At time of writing the
      MSA mappings go up to RACE4 and RACEOR4 */
      
    %let race_max=0;  
    proc sql noprint;
     select count(*) into :race_max from varmap 
     where si_var="RACEOR&max_race_seq";
    quit; 
    
    %if &race_max = 0 %then %do;
     %let _cmd = %str(%str(RTW)ARNING: DM domain RACE mapping incomplete - up to RACEOR&max_race_seq and RACE&max_race_seq need mapping);%tu_sdtmconv_sys_message; 
    %end;
    
   %end;
   
   ** merge demo data with first and multiple race data **;
   data pre_sdtm.demo _pre_bespoke_dm_no_demo_race _pre_bespoke_dm_no_race;
    merge _pre_bespoke_dm_mult_races (in=inc)
          pre_sdtm.race(in=inb drop=seq)
          pre_sdtm.demo(in=ina);
    by SUBJID;

	** BJC008: Keep a copy of the original race value to later report **;
	** BJC009: Add 'and not inc' so this only runs for subjects with one race **;
    if RACEC^='MULTIPLE' and not inc then RACEOR1=RACEC;
	
    /* BJC004: Clean up RACEOR definitions as variable not needed */
    ** Decode the race values now **;
    RACEC=put(RACEC,$RACE.);   
	
    if (ina) then output pre_sdtm.demo ;
    else if (ina*^inb) then output _pre_bespoke_dm_no_race;
    else if (inb*^ina) then output _pre_bespoke_dm_no_demo_race;
   run;
  
   ** print no_race  **; 
   proc print data=_pre_bespoke_dm_no_race noobs;
     var studyid SUBJID;  
     title3 "SDTM conversion &g_study_id: Data in Demo but not in Race";
   run;
 
   /* Delete pre_sdtm.race so it doesnt appear on outputs and confuse */   
   proc datasets memtype=data library=pre_sdtm nolist;
                delete race;
   run;

  %end; 
%end;

**************************************************************;
/* DSS003 add definitions to process new DM variables */
/* Move this step - sort the DEMO data once at the start */
**************************************************************;
proc sort data=pre_sdtm.demo;
 by SUBJID; run;
 
%if %length(&RFPENDT)=0 %then %do;
  %let _cmd = %str(%str(RTN)OTE: No derivation defined for RFPENDT[C], DM domain will be incomplete);%tu_sdtmconv_sys_message;
%end;

%if %length(&RFPENDT) >= 1 %then %do;

 proc sql noprint;
  create table _pre_bespoke_dm_rfpendt as (&rfpendt);
 quit; 

 proc sort data=_pre_bespoke_dm_rfpendt ;
 by SUBJID; run;

 data pre_sdtm.demo;
  merge pre_sdtm.demo(in=a) _pre_bespoke_dm_rfpendt;
  by SUBJID;
  if a;
 run;

%end;

%if %length(&RFXSTDT)=0 %then %do;
  %let _cmd = %str(%str(RTN)OTE: No derivation defined for RFXSTDT[C], DM domain will be incomplete);%tu_sdtmconv_sys_message;
%end;

%if %length(&RFXSTDT) >= 1 %then %do;

 proc sql noprint;
  create table _pre_bespoke_dm_rfxstdt as (&rfxstdt);
 quit; 

 proc sort data=_pre_bespoke_dm_rfxstdt ;
 by SUBJID; run;

 data pre_sdtm.demo;
  merge pre_sdtm.demo(in=a) _pre_bespoke_dm_rfxstdt;
  by SUBJID;
  if a;
 run;

%end;

%if %length(&RFXENDT)=0 %then %do;
  %let _cmd = %str(%str(RTN)OTE: No derivation defined for RFXENDT[C], DM domain will be incomplete);%tu_sdtmconv_sys_message;
%end;

%if %length(&RFXENDT) >= 1 %then %do;

 proc sql noprint;
  create table _pre_bespoke_dm_rfxendt as (&rfxendt);
 quit; 

 proc sort data=_pre_bespoke_dm_rfxendt ;
 by SUBJID; run;

 data pre_sdtm.demo;
  merge pre_sdtm.demo(in=a) _pre_bespoke_dm_rfxendt;
  by SUBJID;
  if a;
 run;

%end;

%if %length(&RFICDT)=0 %then %do;
  %let _cmd = %str(%str(RTN)OTE: No derivation defined for RFICDT[C], DM domain will be incomplete);%tu_sdtmconv_sys_message;
%end;

%if %length(&RFICDT) >= 1 %then %do;

 proc sql noprint;
  create table _pre_bespoke_dm_rficdt as (&rficdt);
 quit; 

 proc sort data=_pre_bespoke_dm_rficdt ;
 by SUBJID; run;

 data pre_sdtm.demo;
  merge pre_sdtm.demo(in=a) _pre_bespoke_dm_rficdt;
  by SUBJID;
  if a;
 run;

%end;

/* If the AE or DEATH dataset is present (as well as DEMO) then use it to calculate the death date(DTHDT) and death flag(DTHFL) */

%if %sysfunc(exist(pre_sdtm.ae)) %then %do;
 data ae(keep=subjid dthdt);
   set pre_sdtm.ae;
   where aeoutcd eq '5';
   if aeendt eq . then aeendt = aestdt;
   rename aeendt=dthdt;
 run;
%end; 
 
 
%if %sysfunc(exist(ae)) %then %do;   
 %if %eval(%tu_nobs(ae)) >= 1 %then %do;
%let _cmd = %str(%str(RTN)OTE: Death data found. Creating Death date and Flag in DM); %tu_sdtmconv_sys_message;
 data _pre_bespoke_dm_dthdt_flag;
    set ae
        %if %sysfunc(exist(combine.death)) %then %do;
            %if %eval(%tu_nobs(combine.death)) >= 1 %then %do; 		    
	            combine.death(keep=subjid dthdt where=(dthdt ne .))		    
	        %end;	
	    %end;
		/* BJC013: add new DTH IDSL datagroup as a variant of old IDSL DEATH  */
		%if %sysfunc(exist(combine.dth)) %then %do;
            %if %eval(%tu_nobs(combine.dth)) >= 1 %then %do; 		    
	            combine.dth(keep=subjid dddt where=(dddt^=.))		    
	        %end;	
	    %end;
		
		;
		dthfl = 'Y';
 run;	

 proc sort data = _pre_bespoke_dm_dthdt_flag nodupkey;
    by subjid dthdt;
 run;   
 
 data _pre_bespoke_dm_dthdt_flag;
    set _pre_bespoke_dm_dthdt_flag;
	by subjid;
	if last.subjid;
run;	

 data pre_sdtm.demo;
  merge pre_sdtm.demo(in=a) _pre_bespoke_dm_dthdt_flag;
  by SUBJID;
  if a;
 run;
 %end; /* End of %if %eval(%tu_nobs(ae)) >= 1 %then %do; */
%end; /* End of %if %sysfunc(exist(ae)) %then do; */

/* DSS004: Remove code to populate ACTARM & ACTARMCD from exposure. Now this is taken from DEMO itself. Mapping added to MSA.  */
/* End of DSS003 changes */

******************************************************************************;
/* Derive RFSTDT(C) and RFENDT(C) to add into DM domain data */

%if %length(&RFSTDT)=0 %then %do;
  %let _cmd = %str(%str(RTW)ARNING: No derivation defined for RFSTDT[C], DM domain will be incomplete);%tu_sdtmconv_sys_message;
%end;

%if %length(&RFENDT)=0 %then %do;
  %let _cmd = %str(%str(RTW)ARNING: No derivation defined for RFENDT[C], DM domain will be incomplete);%tu_sdtmconv_sys_message;
%end;


%if %length(&RFSTDT) >= 1 %then %do;

 proc sql noprint;
  create table _pre_bespoke_dm_rfstdt as (&rfstdt);
 quit; 

 proc sort data=_pre_bespoke_dm_rfstdt ;
 by SUBJID; run;

 proc sort data=pre_sdtm.demo;
 by SUBJID; run;

 data pre_sdtm.demo;
  merge pre_sdtm.demo(in=a) _pre_bespoke_dm_rfstdt;
  by SUBJID;
  if a;
 run;

%end;

%if %length(&RFENDT) >= 1 %then %do;
 proc sql noprint;
  create table _pre_bespoke_dm_rfendt as (&rfendt);
 quit; 
 
 proc sort data=_pre_bespoke_dm_rfendt;
 by SUBJID; run;
 
 proc sort data=pre_sdtm.demo;
 by SUBJID; run;
 
 data pre_sdtm.demo;
  merge pre_sdtm.demo(in=a) _pre_bespoke_dm_rfendt;
  by SUBJID;
  if a;
 run;
 
%end;

******************************************************************************;
** Update ARM and ARMCD to DEMO (DM domain) for screen fails and RIDOs **;
** RAND data needed for ARM and ARMCD to be present in the first place **;

/* DSS002 */
/* Prefix RTWARNING onto DM domain may be incomplete - DS [or DISPOSIT-SCRNFAIL] source dataset needed to populate ARM/ARMCD for non-treated subjects */

%if %sysfunc(exist(pre_sdtm.rand)) %then %do;
 %if not %sysfunc(exist(ds_sub_demo)) %then %do;
  %let _cmd = %str(%str(RTW)ARNING: DM domain may be incomplete - DS [or DISPOSIT-SCRNFAIL] source dataset needed to populate ARM/ARMCD for non-treated subjects);%tu_sdtmconv_sys_message; 
 %end;
%end;

%if %sysfunc(exist(ds_sub_demo)) and %sysfunc(exist(pre_sdtm.rand)) %then %do;

data pre_sdtm.demo;
 attrib ARM   length=$200;
 attrib ARMCD length=$100;
 set pre_sdtm.demo;
run;

/* BJC011 - code to flag subjects that are both randomised and SF/RIDO. The DM.ARM will be the RAND value, not SF/RIDO
   but will alert the user to this scenario for investigation. */
   
proc sql noprint;
 create table treated_sf_rido as select * from pre_sdtm.demo
  where arm^='' and subjid in (select subjid from ds_sub_demo where dsscatcd^=1 );

 select trim(put(subjid,8.)) into :treated_sf_rido_subjid separated by ',' from treated_sf_rido order by subjid;
  
 update pre_sdtm.demo dm set ARM=
 (select distinct ARM 
  from ds_sub_demo sub
  where sub.SUBJID=dm.SUBJID)
  where ARM is null;

 update pre_sdtm.demo dm set ARMCD=
 (select distinct ARMCD 
  from ds_sub_demo sub
  where sub.SUBJID=dm.SUBJID)
  where ARMCD is null;
 quit; 
 
 %if %eval(%tu_nobs(treated_sf_rido))>=1 %then %do;    
    %put RTE%str(RROR): DS dataset : following subjects are both randomised to an arm and screen failure or RIDO,  ;
	%put NOTE: The SDTM DM.ARM will be set as the treatment group, not the Screenfail or RIDO value;
	%put Investigate/query. Final data must be clean and should NOT have this scenario, only for in-stream/dirty data.;
	%put If left as is, affected subjects should be documented by S+P in Reviewers Guide.;
	%put Affected Subjid(s): &treated_sf_rido_subjid ;
 %end;
 
%end;

**********************************************************************************;
** Last but not least update AGE **;
/* BJC007: add check for RFSTDM as well as RFSTDT */
%if %tu_chkvarsexist(pre_sdtm.demo,rfstdt) eq or %tu_chkvarsexist(pre_sdtm.demo,rfstdm) eq %then %do; 

 %let age_present=%tu_chkvarsexist(pre_sdtm.DEMO,AGE,Y);  

 data pre_sdtm.demo; 
  set pre_sdtm.demo;
  attrib AGEU label='Age Units';
  attrib AGE length=8.;
 
  %if &age_present eq %then %do;
 
   /* BJC015 : create RFSTDT as a temporary variable if RFSTDM (datetime) variant is present */
   %if %tu_chkvarsexist(pre_sdtm.demo,rfstdm) eq %then %do; 
    length RFSTDT 8.; format RFSTDT date9.;
	RFSTDT=datepart(RFSTDM);
   %end;
   
   if not missing(rfstdt) then 
   AGE=intck('year',birthdt,rfstdt)  -
          ( month(rfstdt) lt month(birthdt) or
          ( month(rfstdt) eq month(birthdt) and 
              day(rfstdt) lt day(birthdt)) ); 
  %end;
      
  if not missing(AGE) then AGEU='YEARS';
 run;
%end;

%if &sysenv=BACK %then %do;  

%tu_tidyup(
rmdset = _pre_bespoke_dm:,
glbmac = none
);

%end;

%mend tu_sdtmconv_pre_si_bespoke_dm;
