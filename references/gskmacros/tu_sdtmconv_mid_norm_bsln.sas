/******************************************************************************* 
|
| Macro Name: tu_sdtmconv_mid_norm_bsln
|
| Macro Version/Build: 3/1
|
| SAS Version: SAS 9.1.3
|
| Created By: Bruce Chambers
|
| Date:            12-Aug-2009
|
| Macro Purpose: Update baseline flags to findings domains using modified version of HARP RT
|
| Macro Design:  Procedure
|
| Input Parameters:   These come from the wrapper/driver macro
|
| NAME              DESCRIPTION                         DEFAULT 
|
| Output:
|
|   Invoke modified HARP reporting tool to add and populate --BLFL column
|
| Global macro variables created:
|
|  None
|
| Macros called:
| (@)tu_chkvarsexist
| (@)tu_sdtmconv_sys_message
| (@)tu_sdtmconv_sys_error_check
| (@)tu_baseln_sdtmconv
| (@)tu_tidyup
|
| Example:
|         %tu_sdtmconv_mid_norm_bsln;
|
|******************************************************************************* 
| Change Log |
| Modified By:                      Ashwin V
| Date of Modification:             31-Aug-2010
| New Version/Build Number:         2/1
| Reference:                        VA001
| Description for Modification:     Some baseline flagging options add a --STDBL variable that is not
| Reason for Modification:          valid in domains,checking if the --STDBL variable exist and if
|                                   exist then dropping it.                               
|
| Modified By:                      Ashwin V
| Date of Modification:             31-Aug-2010
| New Version/Build Number:         2/1
| Reference:                        VA002
| Description for Modification:     Downgrade to RTNOTEs the 2 RTWARNINGs: TU_SDTMCONV_MID_NORM_BSLN:
| Reason for Modification:          BASELINETYPE and BASELINEOPTION because some datasets dont have 
|                                    --BLFL assigned
|
| Modified By:                      Deepak Sriramulu
| Date of Modification:             04-Dec-2011
| New Version/Build Number:         3/1
| Reference:                        DSS001
| Description for Modification:     Put RTWARNING and continue the conversion when --DTC --TESTCD --STRESN 
|									are missing from mid_sdtm.&domain_si_dset dataset 
| Reason for Modification:          tu_baseln_sdtmconv macro was crashing, when mid_sdtm.&domain_si_dset dataset does not contain 
|                                   one of the following variables --DTC --TESTCD --STRESN 
|                                    
********************************************************************************/ 

%macro tu_sdtmconv_mid_norm_bsln(
);

%local l_baselinetype l_baselineoption l_stmeddset l_stmeddsetsubset l_reldays l_startvisnum l_endvisnum run_baseln;

/* query all the findings domains in the current run so we know which domains need --BLFL */
proc sql noprint;
  create table _mid_norm_baseline as 
  select distinct trim(domain) || "_" || si_dset as domain_si_dset
                 ,dom_ref
  from sdtm_dom
  where dom_type contains 'Findings' and domain in 
   (select domain from reference where substr(reverse(trim(variable_name)),1,4)='LFLB');
quit;

/* Count the number of datasets (if any) to process */

%if &sqlobs>=1 %then %do;  

 data _mid_norm_baseline; 
  set _mid_norm_baseline;
  num=_n_;
 run;

 %if %length(&baseln_xml) gt 0 %then
 %do;

   /*
   / Assign a libref corresponding to the XML file that stores values of parameters to
   / pass to the tu_baseln_sdtmconv macro.
   / The set-up macro should already have checked that BASELN_XML corresponds to a 
   / valid XML file if it is not blank.
   /------------------------------------------------------------------------------------*/

   libname bsln_xml xml "&baseln_xml";

 %end;

 %DO w=1 %TO &sqlobs;

  /* For each iteration - attempt to run the existing HARP RT to derive baseline flags */

  data _null_ ;set _mid_norm_baseline (where=(num=&w));
   call symput('domain_si_dset',trim(domain_si_dset));
   call symput('domain_ref',trim(dom_ref));
  run;

  %if %tu_chkvarsexist(mid_sdtm.&domain_si_dset, &domain_ref.BLFL) eq %then %do;     
     %let _cmd = %str(%str(RTN)OTE: TU_SDTMCONV_MID_NORM_BSLN: &domain_ref.BLFL already exists);%tu_sdtmconv_sys_message;
  %end;
  %if %tu_chkvarsexist(mid_sdtm.&domain_si_dset,&domain_ref.BLFL) ne %then %do;     
     
     %let _cmd = %str(Assigning &domain_ref.BLFL for &domain_si_dset);%tu_sdtmconv_sys_message;

     %let l_baselinetype = &baselinetype;
     %let l_baselineoption = &baselineoption;
     %let l_stmeddset = &stmeddset;
     %let l_stmeddsetsubset = &stmeddsetsubset;
     %let l_reldays = &reldays;
     %let l_startvisnum = &startvisnum;
     %let l_endvisnum = &endvisnum;

     %if %length(&baseln_xml) gt 0 %then
     %do;

       /*
       / The set-up macro should include parameters corresponding to each of the parameters of the
       / tu_baseln_sdtmconv macro, except for DSETIN, DSETOUT and DOMAINCODE.   
       / Check whether or not the XML file includes a record corresponding to the current domain. 
       / If a record exists, then overwrite the values of BASELINEOPTION, STMEDDSET etc with the
       / values of the corresponding variables from the XML file. 
       / If the XML file does not include a record corresponding to the current domain, then
       / leave BASELINEOPTION, STMEDDSET etc unchanged, so they will continue to hold the default
       / values defined by the set-up macro.
       /------------------------------------------------------------------------------------------*/

       data _null_;
	 set bsln_xml.baseln_parms;
	 if upcase(domain_si_dset) eq upcase("&domain_si_dset") then
	 do;
	   call symput('l_baselinetype', trim(baselinetype));
	   call symput('l_baselineoption', trim(baselineoption));
	   call symput('l_stmeddset', trim(stmeddset));
	   call symput('l_stmeddsetsubset', trim(stmeddsetsubset));
	   call symput('l_reldays', trim(reldays));
	   call symput('l_startvisnum', trim(startvisnum));
	   call symput('l_endvisnum', trim(endvisnum));

	   put / 'RTN' "OTE: &sysmacroname: for &domain_si_dset, " 'the default parameter values passed to TU_BASELN_SDTMCONV will be overwritten with the following:'
	       / baselinetype = baselineoption = stmeddset = stmeddsetsubset = reldays = startvisnum = endvisnum =
	       / ;
	   stop;
	 end;
       run;

     %end; /* %if %length(&baseln_xml) gt 0 %then */

     %let run_baseln = 1;

     /* VA002:Downgrade to RTNOTEs the 2 RTWARNINGs for  BASELINETYPE and BASELINEOPTION*/

     %if %length(&l_baselinetype) eq 0 %then
     %do;
       %let run_baseln = 0;
       %let _cmd = %str(%str(RTN)OTE: TU_SDTMCONV_MID_NORM_BSLN: BASELINETYPE not specified for &domain_si_dset, so baseline flag will not be assigned); 
       %tu_sdtmconv_sys_message;
     %end;

     %if %length(&l_baselineoption) eq 0 %then
     %do;
       %let run_baseln = 0;
       %let _cmd = %str(%str(RTN)OTE: TU_SDTMCONV_MID_NORM_BSLN: BASELINEOPTION not specified for &domain_si_dset, so baseline flag will not be assigned);
       %tu_sdtmconv_sys_message;
     %end;

     /* DSS001 : prevent baseline flagging running if variables not present - ensure clean runs */ 
     %if %length(&l_baselineoption) ne 0 and %length(&l_baselinetype) ne 0 
       and %length(%tu_chkvarsexist(mid_sdtm.&domain_si_dset, &domain_ref.DTC &domain_ref.TESTCD &domain_ref.STRESN)) gt 0 %then
     %do;
       %let run_baseln = 0;
       %let _cmd = %str(%str(RTW)ARNING: TU_SDTMCONV_MID_NORM_BSLN: mid_sdtm.&domain_si_dset dataset does not contain one of the following variables &domain_ref.DTC &domain_ref.TESTCD &domain_ref.STRESN);
       %tu_sdtmconv_sys_message;
     %end;

     %if &run_baseln %then
     %do;

       /* Use modified version of HARP RT */

       %tu_baseln_sdtmconv(
	     dsetin          = mid_sdtm.&domain_si_dset,
	     dsetout         = mid_sdtm.&domain_si_dset,
	     baselinetype    = &l_baselinetype,
	     baselineoption  = &l_baselineoption,
	     stmeddset       = &l_stmeddset,
	     stmeddsetsubset = &l_stmeddsetsubset,                                 
	     reldays         = &l_reldays,
	     startvisnum     = &l_startvisnum,
	     endvisnum       = &l_endvisnum,
	     domaincode      = &domain_ref
	   );
       
       /* Drop unwanted columns and lose the R values from LBCHGCD so we only keep P codes, and decode P to Y */
	 
       data mid_sdtm.&domain_si_dset; 
	set mid_sdtm.&domain_si_dset (drop=&domain_ref.chind rename=(&domain_ref.chcd=&domain_ref.BLFL));
	if &domain_ref.blfl='P' then &domain_ref.blfl='';
	if &domain_ref.blfl='R' then &domain_ref.blfl='Y';
       run; 

     /* VA001: drop --STDBL field if the baseline options had created it */
    %if %length(%tu_chkvarsexist(mid_sdtm.&domain_si_dset,&domain_ref.stdbl,Y)) gt 0 %then %do;
  
     data mid_sdtm.&domain_si_dset;
      set mid_sdtm.&domain_si_dset;
      drop &domain_ref.STDBL;
     run;
  
    %end;

     %end;
    
     %tu_sdtmconv_sys_error_check;    

  %end; /* %if %tu_chkvarsexist(mid_sdtm.&domain_si_dset,&domain_ref.BLFL) ne %then %do; */ 

 %end; /* %DO w=1 %TO &sqlobs; */

%end; /* %if &sqlobs>=1 %then %do; */


%if &sysenv eq BACK %then
%do;

  %tu_tidyup(
  rmdset = _mid_norm_:,
  glbmac = none
  );

%end;

%mend tu_sdtmconv_mid_norm_bsln;
