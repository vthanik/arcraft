/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_si_bespoke_diar
|
| Macro Version/Build:  7/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009
|
| Macro Purpose:        Pre-process RESP diary data according to mapping specs
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
| (@)tu_sdtmconv_sys_register
| (@)tu_sdtmconv_sys_message
| (@)tu_chkvarsexist
|
| Example:
|
| %tu_sdtmconv_pre_si_bespoke_diar
|
|*******************************************************************************
| Change Log:
|
| Modified By:                 Bruce Chambers
| Date of Modification:        17Jun2010
| New Version/Build Number:    2/1
| Reference:                   bjc001
| Description for Modification:DIARY Exposure data not output correctly
| Reason for Modification:     To ensure the number of PUFFs and other related columns 
|                              appear in EX domain
|
| Modified By:                 Bruce Chambers
| Date of Modification:        29Mar2011
| New Version/Build Number:    3/1
| Reference:                   bjc002
| Description for Modification:DIARY Exposure data not output correctly
| Reason for Modification:     To ensure the number of PUFFs and other related columns 
|                              appear correctly in EX domain - 0 puffs are important/needed in the data
|
| Modified By:                 Ashwin Venkat
| Date of Modification:        17Aug2011
| New Version/Build Number:    3/1
| Reference:                   AV001
| Description for Modification:Added new Diary variables
| Reason for Modification:     Added new Diary variables
|
| Modified By:                 Bruce Chambers
| Date of Modification:        11Jul2012
| New Version/Build Number:    4/1
| Reference:                   BJC003
| Description for Modification:Added new Diary variables : AMDOSETM
| Reason for Modification:     Added new Diary variables : AMDOSETM
|
| Modified By:                 Bruce Chambers
| Date of Modification:        20Jul2012
| New Version/Build Number:    4/1
| Reference:                   BJC004
| Description for Modification:Update register statement to also provide source dataset name
| Reason for Modification:     Correct data product
|
| Modified By:                 Bruce Chambers
| Date of Modification:        16Nov2012
| New Version/Build Number:    4/1
| Reference:                   BJC005
| Description for Modification:Process AMDOSETM onto a separate row with EXTRT=Study Medication.
|                              Also include PMPEFDT in steps, some references were missing - spotted by S&P.
| Reason for Modification:     Correct data product
|
| Modified By:                 Bruce Chambers
| Date of Modification:        16Nov2012
| New Version/Build Number:    5/1
| Reference:                   BJC005
| Description for Modification:Addition to BJC004: default PMPEFDT with correct format if not present (for date macro).
| Reason for Modification:     Correct data product
|
| Modified By:                 Bruce Chambers
| Date of Modification:        16Nov2012
| New Version/Build Number:    6/1
| Reference:                   BJC006
| Description for Modification:Addition to BJC005: set as null the dosing detail for study medication rows from diary.
|                              Also for DIARY_EX data - use ACTDT (not PMPEFDT) for all rows based on S&P request/feedback.
| Reason for Modification:     Correct data product
|
| Modified By:                 Bruce Chambers
| Date of Modification:        13Feb2013
| New Version/Build Number:    7/1
| Reference:                   BJC007
| Description for Modification:EXTPT AM/PM assignments need reversing - request from S&P.
| Reason for Modification:     Correct data product -Nighttime puffs of rescue med are recorded in the morning, 
|                              and daytime puffs are recorded in the PM
|
*******************************************************************************/
%macro tu_sdtmconv_pre_si_bespoke_diar(
);

/* Define as macro vars all the variables that we know this macro can deal with currently */
/*AV001: added new diary variables */
%let dia_vars='ACTDT','ACTTM','PEFDT','PEFTM','PMPEFTM','PMPEFDT','SYSCPM','SYSCAM','SYSCPMCD','SYSCAMCD','AMDOSETM',
              'PUFFAM','PUFFPM','ICSTKN','PEFAM','PEFPM' ,'BR24H','COU24H','SPU24H','BR24HCD','COU24HCD','SPU24HCD','OCCBD24';

%let ACTDT   = %tu_chkvarsexist(pre_sdtm.diaries,ACTDT,Y); 
%let ACTTM   = %tu_chkvarsexist(pre_sdtm.diaries,ACTTM,Y); 
%let PMPEFTM = %tu_chkvarsexist(pre_sdtm.diaries,PMPEFTM,Y); 
%let PEFDT   = %tu_chkvarsexist(pre_sdtm.diaries,PEFDT,Y); 
/* BJC005 - add check for PMPEFDT */
%let PMPEFDT   = %tu_chkvarsexist(pre_sdtm.diaries,PMPEFDT,Y); 
%let PEFTM   = %tu_chkvarsexist(pre_sdtm.diaries,PEFTM,Y); 
%let SYSCPM  = %tu_chkvarsexist(pre_sdtm.diaries,SYSCPM,Y); 
%let SYSCAM  = %tu_chkvarsexist(pre_sdtm.diaries,SYSCAM,Y); 
%let SYSCPMCD= %tu_chkvarsexist(pre_sdtm.diaries,SYSCPMCD,Y); 
%let SYSCAMCD= %tu_chkvarsexist(pre_sdtm.diaries,SYSCAMCD,Y); 
%let PUFFAM  = %tu_chkvarsexist(pre_sdtm.diaries,PUFFAM,Y); 
%let PUFFPM  = %tu_chkvarsexist(pre_sdtm.diaries,PUFFPM,Y); 
%let ICSTKN  = %tu_chkvarsexist(pre_sdtm.diaries,ICSTKN,Y); 

%let PEFAM  = %tu_chkvarsexist(pre_sdtm.diaries,PEFAM,Y); /*The only processing this needs is to add PMPEFDT */
%let PEFPM  = %tu_chkvarsexist(pre_sdtm.diaries,PEFPM,Y); /*The only processing this needs is to add PMPEFDT */
%let BR24H  = %tu_chkvarsexist(pre_sdtm.diaries,BR24H,Y); 
%let COU24H  = %tu_chkvarsexist(pre_sdtm.diaries,COU24H,Y); 
%let SPU24HR  = %tu_chkvarsexist(pre_sdtm.diaries,SPU24HR,Y); 
%let OCCBD24 =  %tu_chkvarsexist(pre_sdtm.diaries,OCCBD24,Y);

%let AMDOSETM =  %tu_chkvarsexist(pre_sdtm.diaries,AMDOSETM,Y);

/* USUBJID may or may not be present for A&R datasets */
%let USUBJID= %tu_chkvarsexist(pre_sdtm.diaries,USUBJID,Y); 

/* Report if we have unmapped DIARY variables that will not be processed and skip to the end to avoid errors */
proc sql noprint;
 create table non_mapped_diary_vars as 
 select name from dictionary.columns
    where libname='PRE_SDTM'
      and memname='DIARIES'
      and name not in (&dia_vars)
      and name not in (select name from excluded where type='ITEM')
      and name not in ('STUDYID','USUBJID','SUBJID','VISIT','VISITNUM','SEQ','ACTDY')
      and name in (select var_nm from dsm_meta where dataset_nm='DIARIES' and dm_subset_flag='Y');
quit;

%if &sqlobs>=1 %then %do;
 %let _cmd = %str(%str(RTW)ARNING: Unmapped columns in DIARIES dataset - skipping pre-processing. See output for details.);%tu_sdtmconv_sys_message;
 %let _cmd = %str(Update missing vars into tu_sdtmconv_pre_si_bespoke_diar.sas);%tu_sdtmconv_sys_message;
 %goto endmac;
%end;

**************************************************************************************;
** Separate out the QS questions and place in DIARY_QS **;

%if (&SYSCPMCD=SYSCPMCD and &SYSCAMCD=SYSCAMCD and &PMPEFDT=PMPEFDT) %then %do;
 data pre_sdtm.diary_qs;
  /* BJC005: use ACTDT/TM (AM) instead of PM (PEFDT/TM) as ACTDT updated with PM entries in step above */
  set pre_sdtm.diaries(keep=STUDYID SUBJID &USUBJID &ACTTM &ACTDT &SYSCPM &SYSCAM &SYSCPMCD &SYSCAMCD 
                            where=(&SYSCAMCD^='' or &SYSCPMCD^=''));
 run; 

 /* Add a record to the system view_tab_list driver table so this pseudo source dataset will get processed */
  /* BJC004: update register call to include source dataset */
 %if %eval(%tu_nobs(pre_sdtm.diary_qs))>=1 %then %do;
  %tu_sdtmconv_sys_register(DIARY_QS,DIARIES);
 %end;
 
%end;

**************************************************************************************;
/* Separate out and place related data in CM or EX depending on macro var */
/* BJC004: keep AMDOSETM where present for DIARY_EX */
%if &rescue=EX and (&PUFFAM=PUFFAM and &PUFFPM=PUFFPM) %then %do;

 data pre_sdtm.diary_ex;
  set pre_sdtm.diaries(keep=STUDYID SUBJID &USUBJID &ACTDT &AMDOSETM &PEFTM &PMPEFTM &PMPEFDT &PUFFAM &PUFFPM);   
 run; 
 
 /* Add a record to the system view_tab_list driver table so this pseudo source dataset will get processed */
 %if %eval(%tu_nobs(pre_sdtm.diary_ex))>=1 %then %do;
 /* BJC004: update register call to include source dataset */
  %tu_sdtmconv_sys_register(DIARY_EX,DIARIES);

  /* We only need to keep one set of date-time fields (ACTDT not PEFDT as evening ones can be same day or next), so drop the other. 
     NB:The dates are usually the same as the PM version is copied from the mapped AM field - if its the only one collected 
        some studies also have AMDOSETM so need to allow for this too */
     
 /* BJC001 - output PUFFAM and PUFFPM as EXDOSE along with EXDOSFRM, EXCAT and EXTRT*/     
 /* BJC005: Drop 3 original times and create and populate ACTTM from 3 source times (in next step). 
            Also populate PMPEFDT with ACTDT where it is null - so normalised version has date on all rows */
			
  data pre_sdtm.diary_ex(drop=&puffam &puffpm 
   %if &PUFFPM=PUFFPM %then %do;
                               puffpm2
   %end;
  );
   set pre_sdtm.diary_ex;
		
    /* BJC002 - ensure puff=0 gets output */
    if puffam ^=. or puffpm^=. then do;       
       PUFFPM2=PUFFPM;
       
       EXCAT='DIARY DATA';
       EXTRT='RESCUE MEDICATION';
       EXDOSU='PUFF';
       EXDOSFRM='AEROSOL';

	  /* BJC007 - switch AM/PM as Nighttime puffs of rescue albuterol are recorded in the morning, 
	              and daytime puffs are recorded in the PM */
      if puffam^=. then do ;
       EXTPT='PM';
       EXDOSE=PUFFAM;
       puffpm=.;
       output;
      end;
      if puffpm2^=. then do ;
       EXTPT='AM';
       EXDOSE=PUFFPM2;
       puffam=.;
       output;
      end;   	  
   end; 
   /* BJC005: Process AMDOSETM onto a separate row - and process the times logically into one field ACTTM */
   /* BJC006 : set as null the dosing detail for study medication rows from diary */
   if amdosetm^=. then do;
       EXCAT='DIARY DATA';
       EXTRT='STUDY MEDICATION';
	   EXTPT='AM';
       EXDOSU='';
       EXDOSFRM=''; 
	   EXDOSE=.;
	   output;
   end;
run;

 data pre_sdtm.diary_ex(drop= peftm pmpeftm amdosetm );
   set pre_sdtm.diary_ex; 
   format ACTTM time5.;
   if extrt='RESCUE MEDICATION' and EXTPT='AM' then ACTTM=.;
   else if extrt='RESCUE MEDICATION' and EXTPT='PM' then ACTTM=.;
   else if extrt='STUDY MEDICATION' then ACTTM=AMDOSETM;
 
   %if (&ACTDT=ACTDT and &PMPEFDT=PMPEFDT) %then %do;   
      format PMPEFDT date9.;
      /* BJC004: copy ACTDT to PMPEFDT if null so that we have a PM date for every row */
	  /* BJC005: use ACTDT (not PMPEFDT) for all rows based on S&P request/feedback */
       PMPEFDT=ACTDT; 
   %end;  
  run;
 
 %end;

 %if &rescue= %then %do;
  %let _cmd = %str(%str(RTW)ARNING: RESCUE macro variables needs value setting in driver program);%tu_sdtmconv_sys_message; 
  %let _cmd = %str(Set to EX if rescue meds for this study are supplied by GSK. Set to CM if not supplied by GSK.);%tu_sdtmconv_sys_message; 
 %end;

%end;

**************************************************************************************;
** If RESCUE=CM then separate out the PUFFAM/PM questions and place in CM2 **;
%if &rescue=CM and (&PUFFAM=PUFFAM and &PUFFPM=PUFFPM) %then %do;

 data pre_sdtm.DIARYCM2 (drop=&PUFFAM &PUFFPM PUFFPM2);
  set pre_sdtm.diaries (keep=STUDYID SUBJID &USUBJID &PUFFAM &PUFFPM &PMPEFTM &PMPEFDT where=(&PUFFAM^=. or &PUFFPM^=.));
 
  PUFFPM2=PUFFPM;
 
  if puffam^=. then do ;
   CMTPT='AM';
   PUFF=PUFFAM;
   puffpm=.;
   output;
  end;
  if puffpm2^=. then do ;
   CMTPT='PM';
   PUFF=PUFFPM2;
   puffam=.;
   output;
  end; 
 run; 

 %if %eval(%tu_nobs(pre_sdtm.diarycm2))>=1 %then %do;
  %tu_sdtmconv_sys_register(DIARYCM2,DIARIES);
 %end;
%end;

/* Delete the moved data from the remaining diary data - for performance reasons */
data pre_sdtm.diaries;
 set pre_sdtm.diaries(drop=&PUFFAM &PUFFPM &SYSCAM &SYSCPM &SYSCAMCD &SYSCPMCD &AMDOSETM);
  /* BJC005: copy ACTDT to PMPEFDT if null so that we have a PM date for every row.
  / If ACTDT is present - we need to create PMPEFDT with a copy of the date - ACTDT is used 
  /  for AM records and (optionally) PMPEFDT for PM records. (The data will already have PMPEFTM collected.) */
  
  %if &PMPEFDT= %then %do;
   format PMPEFDT DATE9.;
  %end;
  
  if XFTPT='PM' and PMPEFDT^=. and PMPEFDT^=ACTDT then ACTDT=PMPEFDT;
  else if PMPEFDT=. then PMPEFDT=ACTDT; 
run; 

%endmac:

%mend tu_sdtmconv_pre_si_bespoke_diar;
