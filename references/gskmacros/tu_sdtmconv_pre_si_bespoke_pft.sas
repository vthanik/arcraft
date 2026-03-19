/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_si_bespoke_pft
|
| Macro Version/Build:  4 build 1
|
| SAS Version:          9.1.3
|
| Created By:           Deepak Sriramulu (based on original code by Bruce Chambers)
|
| Date:                 07-Feb-2011 
|
| Macro Purpose:        PFT & BRONCH pre processing 
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
| %tu_sdtmconv_pre_si_bespoke_pft
|
|*******************************************************************************
| Change Log:
|
| Modified By                 : Bruce Chambers
| Date of Modification        : 08AUG2011
| New Version/Build Number    : 2/1
| Reference                   : BJC001
| Description for Modification: Correctly process old studies with BRONCH and new studies where BR6HYN is in PFT
| Reason for Modification     : Correct data conversion
|
| Modified By                 : Bruce Chambers
| Date of Modification        : 08OCT2012
| New Version/Build Number    : 3/1
| Reference                   : BJC002
| Description for Modification: Clean up varmap rows for PFT/BRONCH. If rescue=EX then remove rows for CM and vice-versa
| Reason for Modification     : Correct traceability data at the end of conversion
|
| Modified By                 : Bruce Chambers
| Date of Modification        : 27NOV2012
| New Version/Build Number    : 4/1
| Reference                   : BJC003
| Description for Modification: Ensure correct population of EX domain when DSTM is present.
| Reason for Modification     : Correct SDTM product for this scenario.
|
*******************************************************************************/
%macro tu_sdtmconv_pre_si_bespoke_pft(
); 

 %if &rescue= %then %do;
  %let _cmd = %str(%str(RTW)ARNING: TU_SDTMCONV_PRE_SI_BESPOKE_PFT: Conversion of PFT [and BRONCH] data requires RESCUE driver parameter EX or CM);%tu_sdtmconv_sys_message;
 %end;

 /* BJC001 - add code to check for BRONCH for older studies */
 %if %sysfunc(exist(pre_sdtm.BRONCH)) %then %do;
 
   data pre_sdtm.bronch(drop=DSTM ACTDT);
    set pre_sdtm.bronch;
    format XFDM DATETIME20.;
    
    &rescue.OCCUR=BR6HYN;
    
     %if &rescue=EX %then %do;
      format EXSTDM DATETIME20.;
     %end;

     %if &rescue=CM %then %do;
      format CMDM DATETIME20.;
     %end;

     if upcase(substr(&rescue.OCCUR, 1, 1)) eq 'Y' then do;
        %if &rescue=EX %then %do;
          EXSTDM=DHMS(ACTDT,0,0,DSTM);
          XFDM=EXSTDM; 
        %end;  
        %if &rescue=CM %then %do;
           CMDM=DHMS(ACTDT,0,0,DSTM);
           XFDM=CMDM; 
        %end;         
     end;                           
   run;    
  %end;
   
   %if %sysfunc(exist(pre_sdtm.PFT)) %then %do;
    /* BJC001 - add code to check for BRONCH for older studies */
    %if %sysfunc(exist(pre_sdtm.BRONCH)) %then %do;
     /* BJC003 - define and populate PTM and PTMNUM macro vars */
     %local pftusub bronchusub ptm ptmnum;
     %let pftusub= %tu_chkvarsexist(pre_sdtm.pft,usubjid,Y);     
     %let bronchusub= %tu_chkvarsexist(pre_sdtm.bronch,usubjid,Y);     
     %let ptm= %tu_chkvarsexist(pre_sdtm.pft,ptm,Y);     
     %let ptmnum= %tu_chkvarsexist(pre_sdtm.pft,ptmnum,Y);     

     %if %qupcase(&pftusub) eq USUBJID and %qupcase(&bronchusub) ne USUBJID %then
     %do;
      %put %str(RTN)OTE: &sysmacroname: USUBJID exists in PRE_SDTM.PFT, but;
      %put %str(        )does not exist in PRE_SDTM.BRONCH - USUBJID will not be used as a BY;
      %put %str(        )variable for merging PRE_SDTM.PFT and PRE_SDTM.BRONCH.;
      %let pftusub = ;
     %end;
     %else %if %qupcase(&pftusub) ne USUBJID and %qupcase(&bronchusub) eq USUBJID %then
     %do;
      %put %str(RTN)OTE: &sysmacroname: USUBJID does not exist in PRE_SDTM.PFT,;
      %put %str(        )but does exist in PRE_SDTM.BRONCH - USUBJID will not be used as a BY;
      %put %str(        )variable for merging PRE_SDTM.PFT and PRE_SDTM.BRONCH.;
      %let pftusub = ;
     %end;

    /* The BR6HYN actually needs to be SUPPQUAL to PFT data */
    
    /* BJC003 - add PTM and PTMNUM macro vars to 4 keep and by steps */

    data pft_add; 
     set pre_sdtm.bronch(keep=STUDYID SUBJID &pftusub VISIT VISITNUM &ptm &ptmnum BR6HYN);   
    run;
    
    data pre_sdtm.bronch; 
     set pre_sdtm.bronch(drop=BR6HYN);
    run; 
    
    proc sort data=pre_sdtm.PFT;
     by STUDYID SUBJID &pftusub VISIT VISITNUM &ptm &ptmnum;
    run;
    
    proc sort data=pft_add;
     by STUDYID SUBJID &pftusub VISIT VISITNUM &ptm &ptmnum;
    run;
    
    data pre_sdtm.PFT;
     merge pre_sdtm.PFT pft_add;
     by STUDYID SUBJID &pftusub VISIT VISITNUM &ptm &ptmnum;
	 format XFDM DATETIME20.;
     XFDM=DHMS(PFTDT,0,0,PFTTM);
    run; 
	
    /* Amend the mapping data to reflect this move. We cant set it to BRONCH in the master file
       as the data doesnt come from there - it gets moved. */
	/* BJC002: ensure correct varmap entry present for SI vs A&R QC purposes */
    %let vm_present=0;
    proc sql noprint;
    select count(*) into :vm_present
      from varmap
     where si_dset="PFT" and si_var in ("BR4HYN","BR6HYN") ;
    quit; 
	
	%if &vm_present=0 %then %do;
     data varmap;
      set varmap;
      if si_var in ("BR4HYN","BR6HYN") and si_dset='BRONCH' then si_dset='PFT';
     run; 
    %end;
   %end;
  %end;

  /* BJC001: add code for newer studies with only PFT data and no BRONCH */
  /* BJC003: Ensure correct population of EX domain when DSTM is present */

  %if %length(%tu_chkvarsexist(pre_sdtm.pft,DSTM))=0 %then %do;

   proc sql noprint;    
    select distinct si_var into :drop_pft_test separated by ' '
      from varmap vm,
           dictionary.columns dc
    where dc.libname='PRE_SDTM'
      and dc.memname=vm.si_dset
      and dc.name=vm.si_var
      and dc.memname='PFT'
      and index(vm.sdtm_var,'ORRES')>=1;
   quit;
   

   data pft_ex (drop=&drop_pft_test);
    set pre_sdtm.pft(where=(dstm^=.));  
	
    format EXSTDM datetime20.;
	EXSTDM=DHMS(PFTDT,0,0,DSTM);
    DSTM=.;	
	
	 %if %length(%tu_chkvarsexist(pre_sdtm.pft,PTM))=0 %then %do;
	  &rescue.PTM=PTM;
	 %end;
	 %if %length(%tu_chkvarsexist(pre_sdtm.pft,PTMNUM))=0 %then %do;
	  &rescue.PTMNUM=PTMNUM;
	 %end;

	 /* BJC003:  augment code to allow for BR6HYN or BR4HYN */
     %if %length(%tu_chkvarsexist(pre_sdtm.pft,BR6HYN))=0 and &rescue=EX %then %do;
      EXOCCUR=BR6HYN;
     %end;
     %if %length(%tu_chkvarsexist(pre_sdtm.pft,BR4HYN))=0 and &rescue=EX %then %do;
      EXOCCUR=BR4HYN;
     %end;
	 
     %if %length(%tu_chkvarsexist(pre_sdtm.pft,BR6HYN))=0 and &rescue=CM %then %do;
      CMOCCUR=BR6HYN;
     %end;
     %if %length(%tu_chkvarsexist(pre_sdtm.pft,BR4HYN))=0 and &rescue=CM %then %do;
      CMOCCUR=BR4HYN;
     %end;	 
	
     %if &rescue=EX %then %do;
      format EXSTDM DATETIME20.;
     %end;

     %if &rescue=CM %then %do;
      format CMDM DATETIME20.;
     %end;
	 
     if upcase(substr(&rescue.OCCUR, 1, 1)) eq 'Y' then do;
        %if &rescue=EX %then %do;
           EXSTDM=DHMS(PFTDT,0,0,PFTTM);           
        %end;  
        %if &rescue=CM %then %do;
           CMDM=DHMS(PFTDT,0,0,PFTTM);           
        %end;         
     end;     		
   run;    

   data pre_sdtm.pft;
    set pre_sdtm.pft(drop=dstm) pft_ex;
   run;
   
  %end; 

  /* BJC002 : clean up varmap rows for whichever EX/CM scenario in mappings is not used - for correct traceability data for define.xml */
   data varmap; set varmap;
    %if &rescue=%str(EX) %then %do;
     if si_dset in ('PFT','BRONCH') and domain='CM' then delete;
    %end;	
    %if &rescue=%str(CM) %then %do;
     if si_dset in ('PFT','BRONCH') and domain='EX' then delete;
    %end;	
   run; 

%mend tu_sdtmconv_pre_si_bespoke_pft;
