/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_si_bespoke_all
|
| Macro Version/Build:  9 build 1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009 
|
| Macro Purpose:        More complex pre-processing steps that cannot be
|                       specified as simple instructions via the SDTM mapping
|                       interface.
|
|                       Separate macros for each data group are called from here to
|                       make it more readable 
|
|                       NOTE: Order of events is crucial 
|                             e.g. DS must run before DM as DM uses some DS data
|
|                       Apart from such exceptions they are ordered alphabetically
|                       by data group name
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
| (@)tu_sdtmconv_pre_si_bespoke_chd
| (@)tu_sdtmconv_pre_si_bespoke_blnk
| (@)tu_sdtmconv_pre_si_bespoke_diar
| (@)tu_sdtmconv_pre_si_bespoke_dm
| (@)tu_sdtmconv_pre_si_bespoke_ds
| (@)tu_sdtmconv_pre_si_bespoke_sr
| (@)tu_sdtmconv_pre_si_bespoke_ecg
| (@)tu_sdtmconv_pre_si_bespoke_mh
| (@)tu_sdtmconv_pre_si_bespoke_pc
| (@)tu_sdtmconv_pre_si_bespoke_pp
| (@)tu_sdtmconv_pre_si_bespoke_disp
| (@)tu_sdtmconv_pre_si_bespoke_genp
| (@)tu_sdtmconv_pre_si_bespoke_su
| (@)tu_sdtmconv_pre_si_bespoke_lb
| (@)tu_sdtmconv_pre_si_bespoke_pft
| (@)tu_sdtmconv_pre_si_bespoke_cm
| (@)tu_sdtmconv_pre_si_bespoke_disdr
| (@)tu_sdtmconv_pre_si_bespoke_viral
| (@)tu_sdtmconv_pre_si_bespoke_visit
| (@)tu_sdtmconv_pre_si_bespoke_biomr
| (@)tu_sdtmconv_pre_si_bespoke_lbiop
| (@)tu_sdtmconv_pre_si_bespoke_ipd
| (@)tu_chkvarsexist
| (@)tu_labfg
| (@)tu_sdtmconv_sys_message
| (@)tu_sdtmconv_sys_error_check
|
| Example:
|
| %tu_sdtmconv_pre_si_bespoke_all
|
|*******************************************************************************
| Change Log:
|
| Modified By                 : Ian Barretto (ib10254 - 001)            
| Date of Modification        : 07Jan2010   
| New Version/Build Number    : 1 build 1      
| Description for Modification: Removal of DISPOSIT, GENPRO and SUBUSE processing
| Reason for Modification     : Due to insufficient requirements the _bespoke macros for
|                               the DISPOSIT, GENPRO and SUBUSE macros have been commented
|                               out for the first build of the SDTMCONV macros.   
|                               It is intended to include the processing in a future 
|                               release.
|
| Modified By                 : Barry Ashby (bra13711 - 002)
| Date of Modification        : 08Apr2010 
| New Version/Build Number    : 2 build 1     
| Description for Modification: Added DISPOSIT, GENPRO and SUBUSE processing back into code
| Reason for Modification     : GENPRO, DISPOSIT and SUBUSE pre-processing code has been updated  
|                               and is ready for general use.
|
| Modified By                 : Bruce Chambers (bjc22940 - reference bjc003)
| Date of Modification        : 08Apr2010 
| New Version/Build Number    : 2 build 1     
| Description for Modification: Modify BRONCH pre-processing to allow for PTM and PTMNUM 
| Reason for Modification     : Modify BRONCH pre-processing to allow for PTM and PTMNUM  
|
| Modified By                 : Bruce Chambers (bjc22940 - reference bjc004)
| Date of Modification        : 02Aug2010 
| New Version/Build Number    : 3 build 1     
| Description for Modification: Update tu_labfg convertyn param from N to Y 
| Reason for Modification     : So that LBSTNRLO and LBSTNRHI get populated if absent
|
| Modified By                 : Bruce Chambers (bjc22940 - reference bjc005)
| Date of Modification        : 02Aug2010 
| New Version/Build Number    : 3 build 1     
| Description for Modification: Derive LBCAT if not present - needed for tu_labfg 
| Reason for Modification     : In order that tu_labfg can run next
|
| Modified By                 : Deepak Sriramulu (dss27908 - reference DSS001)
| Date of Modification        : 09Sep2010 
| New Version/Build Number    : 4 build 1     
| Description for Modification: Check if the user wants to skip Diary or Subuse pre processing
| Reason for Modification     : option to opt out of DIARIES and SUBUSE pre-processing system macro
|
| Modified By                 : Ashwin Venkat (va755193 - reference VA001)
| Date of Modification        : 18JAN2011
| New Version/Build Number    : 5 build 1     
| Description for Modification: only run the HARP lab macros if the normal ranges and LBNRIND  are not 
| Reason for Modification     : already present.
|
| Modified By                 : Deepak Sriramulu (dss27908 - reference DSS002)
| Date of Modification        : 07FEB2011
| New Version/Build Number    : 5 build 1 
| Description for Modification: Create seperate bespoke programs for each domain
| Reason for Modification     : For maintainance purpore
|
| Modified By                 : Ashwin Venkat (va755193 - reference VA002)
| Date of Modification        : 5MAY2011
| New Version/Build Number    : 6 build 1 
| Description for Modification: Create seperate bespoke programs to process SUBRACE 
| Reason for Modification     : data
|
| Modified By                 : Ashwin Venkat (va755193 - reference VA003)
| Date of Modification        : 9MAY2011
| New Version/Build Number    : 6 build 1 
| Description for Modification: Create seperate bespoke programs to process IPDISC 
| Reason for Modification     : data
|
| Modified By                 : Bruce Chambers (bjc22940 - reference BJC006)
| Date of Modification        : 08AUG2011
| New Version/Build Number    : 7 build 1 
| Description for Modification: Amend call for PFT pre-processing from BRONCH to PFT
| Reason for Modification     : Ensure correct processing of old and new studies
|
| Modified By                 : Ashwin Venkat (va755193 - reference VA004)
| Date of Modification        : 08AUG2011
| New Version/Build Number    : 7 build 1 
| Description for Modification: created seperate bespoke program to process EXACERB 
| Reason for Modification     : data
|
|
| Modified By                 : Ashwin Venkat (va755193 - reference AV005)
| Date of Modification        : 7Sep2011
| New Version/Build Number    : 7 build 1 
| Description for Modification: created seperate bespoke program to process CHDPOT 
| Reason for Modification     : data
|
| Modified By                 : Ashwin Venkat (va755193 - reference AV006)
| Date of Modification        : 29Nov2012
| New Version/Build Number    : 8 build 1 
| Description for Modification: Delete call to bespoke program to process EXACERB data
| Reason for Modification     : due to recent mapping changes _bespoke_exa macro is no longer needed
|
| Modified By                 : Ashwin Venkat (va755193 - reference AV007)
| Date of Modification        : 11Nov2013
| New Version/Build Number    : 9 build 1 
| Description for Modification: added biolink bespoke macro
| Reason for Modification     : added biolink bespoke macro
*******************************************************************************/
%macro tu_sdtmconv_pre_si_bespoke_all(
); 
/*AV005: pre processing for chdpot data*/

%if %sysfunc(exist(pre_sdtm.chdpot)) %then %do;
 %tu_sdtmconv_pre_si_bespoke_chd;
 %tu_sdtmconv_sys_error_check;
%end;

%put "put log";
/*va007 BIOLINK PROCESSING */
** run pre_processing for BIOLINK data **;
%if %sysfunc(exist(pre_sdtm.biolink)) %then %do;
 /* DSS002 :- pre-processing code moved to tu_sdtmconv_pre_si_bespoke_biomr program and add a call to it. */
 %tu_sdtmconv_pre_si_bespoke_blnk;
 %tu_sdtmconv_sys_error_check;
%end;

** run pre-procesing for LB(BIOMARK) data **;

%if %sysfunc(exist(pre_sdtm.biomark)) %then %do;
 /* DSS002 :- pre-processing code moved to tu_sdtmconv_pre_si_bespoke_biomr program and add a call to it. */
 %tu_sdtmconv_pre_si_bespoke_biomr;
 %tu_sdtmconv_sys_error_check;
%end;

********************************************************************************************************;
** run pre-procesing for CM/EX(BRONCH) data **;
/* BJC006: amend check to look for PFT and not BRONCH */ 

%if %sysfunc(exist(pre_sdtm.PFT)) %then %do;
/* DSS002 :- pre-processing code moved to tu_sdtmconv_pre_si_bespoke_bronch program and add a call to it. */ 
 %tu_sdtmconv_pre_si_bespoke_pft;  
 %tu_sdtmconv_sys_error_check;
%end;
 
********************************************************************************************************;
%if %sysfunc(exist(pre_sdtm.conmeds)) %then %do;
/* DSS002 :- pre-processing code moved to tu_sdtmconv_pre_si_bespoke_conmeds program and add a call to it. */
 %tu_sdtmconv_pre_si_bespoke_cm; 
 %tu_sdtmconv_sys_error_check;
%end;

********************************************************************************************************;
** run pre-procesing for DISPOSIT data **;
** ib10254 - 001                     **;
** REMOVED FOR FIRST VERSION BUILD   **;
** bra13711 - 002: Added back into execution **;


%if %sysfunc(exist(pre_sdtm.disposit)) %then %do;
 %tu_sdtmconv_pre_si_bespoke_disp;
 %tu_sdtmconv_sys_error_check;
%end;


********************************************************************************************************;
** run pre-procesing for DISDUR data **;
%if %sysfunc(exist(pre_sdtm.disdur)) %then %do;
/* DSS002 :- pre-processing code moved to tu_sdtmconv_pre_si_bespoke_disdur program and add a call to it. */
 %tu_sdtmconv_pre_si_bespoke_disdr; 
 %tu_sdtmconv_sys_error_check; 
%end;

********************************************************************************************************;
** run pre-procesing for DS data **;
%if %sysfunc(exist(pre_sdtm.ds)) %then %do;
 %tu_sdtmconv_pre_si_bespoke_ds;
 %tu_sdtmconv_sys_error_check;
%end;

********************************************************************************************************;
/** Add on INVESTIGATOR and RANDALL details to DEMOG data - and process RACE data (complex!) 
    This must come after DS (above) as some data used in DEMO build may be created by DS data **/

%if %sysfunc(exist(pre_sdtm.demo)) %then %do;
 %tu_sdtmconv_pre_si_bespoke_dm;
 %tu_sdtmconv_sys_error_check;
%end;

********************************************************************************************************;
/** Process DIARY data   **/

/* DSS001 Check if the user wants to skip Diary pre processing */
%if %sysfunc(exist(pre_sdtm.diaries)) and not %symexists(pre_diaries) %then %do;
 %tu_sdtmconv_pre_si_bespoke_diar;
 %tu_sdtmconv_sys_error_check;
%end;

********************************************************************************************************;
/*AV004: added code to process  EXACERB data */
/*AV006: Delete call to _bespoke_exa macro. This macro is not needed because of 
recent changes to EXACERB mappings */


********************************************************************************************************;
%if %sysfunc(exist(pre_sdtm.ecg)) %then %do;
 %tu_sdtmconv_pre_si_bespoke_ecg;
 %tu_sdtmconv_sys_error_check;
%end;
********************************************************************************************************;
** run pre-procesing for GENPRO data **;
** ib10254 - 001                     **;
** REMOVED FOR FIRST VERSION BUILD   **;
** bra13711 - 002: Added back into execution **;

%if %sysfunc(exist(pre_sdtm.genpro)) %then %do;
 %tu_sdtmconv_pre_si_bespoke_genp;
 %tu_sdtmconv_sys_error_check;
%end;

/*VA003: call bespoke_ipd to preprocess IPDISC data */
********************************************************************************************************;
** run pre-procesing for IPDISC data **;
%if %sysfunc(exist(pre_sdtm.ipdisc)) %then %do;
 %tu_sdtmconv_pre_si_bespoke_ipd;
 %tu_sdtmconv_sys_error_check;
%end;

********************************************************************************************************;
%if %sysfunc(exist(pre_sdtm.lab)) %then %do;
/* DSS002 :- pre-processing code moved to tu_sdtmconv_pre_si_bespoke_lab program and add a call to it. */
  %tu_sdtmconv_pre_si_bespoke_lb;
 %tu_sdtmconv_sys_error_check;  
%end; 

********************************************************************************************************;
** run pre-procesing for MH(medhist) data **;
%if %sysfunc(exist(pre_sdtm.medhist)) %then %do;
 %tu_sdtmconv_pre_si_bespoke_mh;
 %tu_sdtmconv_sys_error_check;
%end;

********************************************************************************************************;
** run pre-procesing for PC(pkcnc) data **;

%if %sysfunc(exist(pre_sdtm.pkcnc)) %then %do;
 %tu_sdtmconv_pre_si_bespoke_pc;
 %tu_sdtmconv_sys_error_check;
%end;

********************************************************************************************************;
** run pre-procesing for PP (pkpar) data **;

%if %sysfunc(exist(pre_sdtm.pkpar)) %then %do;
 %tu_sdtmconv_pre_si_bespoke_pp;
 %tu_sdtmconv_sys_error_check;
%end;

********************************************************************************************************;

/**VA002: Add SUBRACE to DEMO if SUBRACE dataset present and process SUBRACE data
this must be after dm bespoke macro**/

%if %sysfunc(exist(combine.subrace)) %then %do;
    %tu_sdtmconv_pre_si_bespoke_sr;
    %tu_sdtmconv_sys_error_check;
%end;
********************************************************************************************************;
** run pre-procesing for SU(subuse) data **;
** ib10254 - 001                     **;
** REMOVED FOR FIRST VERSION BUILD   **;
** bra13711 - 002: Added back into execution **;

/* DSS001 Check if the user wants to skip Subuse pre processing */
%if %sysfunc(exist(pre_sdtm.subuse)) and not %symexists(pre_subuse) %then %do;
 %tu_sdtmconv_pre_si_bespoke_su;
 %tu_sdtmconv_sys_error_check;
%end;


********************************************************************************************************;
** run pre-procesing for VIRAL data **;
%if %sysfunc(exist(pre_sdtm.viral)) %then %do;
/* DSS002 :- pre-processing code moved to tu_sdtmconv_pre_si_bespoke_viral program and add a call to it. */
 %tu_sdtmconv_pre_si_bespoke_viral;
 %tu_sdtmconv_sys_error_check;  
%end; 

********************************************************************************************************;
** Derive SVENDT using definition supplied at startup **;
%if %sysfunc(exist(pre_sdtm.visit)) %then %do;
/* DSS002 :- pre-processing code moved to tu_sdtmconv_pre_si_bespoke_visit program and add a call to it. */
 %tu_sdtmconv_pre_si_bespoke_visit; 
 %tu_sdtmconv_sys_error_check;
%end;

********************************************************************************************************;
** Pre-process LBIOPSY data according to mapping specs **;
%if %sysfunc(exist(pre_sdtm.lbiopsy)) %then %do;
/* DSS002 :- pre-processing code newly added to tu_sdtmconv_pre_si_bespoke_lbiop program and added call. */
 %tu_sdtmconv_pre_si_bespoke_lbiop; 
 %tu_sdtmconv_sys_error_check;
%end;

%endmac:

%mend tu_sdtmconv_pre_si_bespoke_all;
