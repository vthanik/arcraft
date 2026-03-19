/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_si_bespoke_genp
|
| Macro Version/Build:  6/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009
|
| Macro Purpose:        Pre-process GENPRO data  to create BE,SUPPBE,PR and DS domains considering mappings specs
|
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
| (@)tu_sdtmconv_sys_register
|
| Example:
|
| %tu_sdtmconv_pre_si_bespoke_genp
|
|*******************************************************************************
| Change Log:
|
| Modified By:                 Bruce Chambers
| Date of Modification:        11august2010
| New Version/Build Number:    2/1
| Reference:                   bjc001
| Description for Modification:Process additional sample types into X5SCAT 
| Reason for Modification:     Uniquely identify rows
|
| Modified By:                 Bruce Chambers
| Date of Modification:        11Jan2011
| New Version/Build Number:    3/1
| Reference:                   bjc002
| Description for Modification:allow for no pre_sdtm.genpro records
| Reason for Modification:     May happen when run on subsets e.g. a problem subject
|
| Modified By:                 Bruce Chambers
| Date of Modification:        10Feb2011
| New Version/Build Number:    3/1
| Reference:                   bjc003
| Description for Modification:amend a SUBJID reference to USUBJID
| Reason for Modification:     USUBJID is now the main subject key, not subjid
|
| Modified By:                 Bruce Chambers
| Date of Modification:        06Oct2012
| New Version/Build Number:    4/1
| Reference:                   bjc004
| Description for Modification:Correction of one scenario
|                              Amend some keep/drops for full traceability for define.xml
| Reason for Modification:     Correct Y1 domain production compliant with --STAT and --REASND SDTM rules
|
| Modified By:                 Ashwin Venkat(va755193)
| Date of Modification:        23May2013
| New Version/Build Number:    5/1
| Reference:                   AV001
| Description for Modification:Corrected GENPRO mapping for GPCNSWD, GPDSREQ and GPDSRS variable, so values go to 
|                              Y1ORRES 
| Reason for Modification:     Corrected Y1 domain mapping 
|
| Modified By:                 Megha A (ma833192)/Snehal P (sp390780)
| Date of Modification:        28Nov2013
| New Version/Build Number:    6/1
| Reference:                   MS001
| Description for Modification: Re-written the macro to incorporate new mappings as per latest mapping spec for GENPRO 
| Reason for Modification:     Mappings to PR,DS,BE 

| Modified By:                Snehal P (sp390780)
| Date of Modification:        16Jan2014
| New Version/Build Number:    6/1
| Reference:                   S002
| Description for Modification: corrected typo
| Reason for Modification:     added () to the macro call
*******************************************************************************/
/*S002: added () to the macro call */
%macro tu_sdtmconv_pre_si_bespoke_genp(
);
/* MS001:Re-written the macro to incorporate new mappings as per latest mapping spec for GENPRO */
 %if %sysfunc(exist(pre_sdtm.genpro)) %then %do;
 
    /**** Processing GENPRO data to BE domain data ****/
    /* ma833192: Removing hardcodes on --CAT based on mail from Rajinder dated 14th Jan 2013
     		"I discussed this issue with Randall today. We agreed to map GPCAT to DSSCAT, PRCAT, BECAT (see below). 
     		 That means that the value can't be defaulted by the macros - it should come from the source data value" **/
     		 
     data pre_sdtm.genprobe;

     	length bedecod $200 ;
     	
     	set pre_sdtm.genpro;
     	 	   
     	if gpdsreq="Y" then do;
     		beterm ="REQUEST FOR SAMPLE DESTRUCTION";
     		if gpdsoth ne "" then gpdsrs = " ";

			bedecod = beterm; 

		output;
     	end;
     		
     	
     run;
     	
     /**Registering GENPROBE domain****/
     	
     %tu_sdtmconv_sys_register(GENPROBE, GENPRO);
     
     /**** Processing GENPRO data to PR domain data ****/
     
     data pre_sdtm.genpropr;

     	length prtrt $200;
     	set pre_sdtm.genpro;
     		
     	if gpsmpcol="Y" then do;
     		prtrt = "SAMPLE COLLECTION";
     		output;
     	end;
      run;
     
     /**Registering GENPROPR domain****/		
     %tu_sdtmconv_sys_register(GENPROPR, GENPRO);
     
     /**** Processing GENPRO data to DS domain data ****/
     /**** All DS related Mappings remain in GENPRO dataset ***/
     
     data pre_sdtm.genpro;
     	length dsdecod $200;
      	length dscat $80;
     	length dsterm $100;
      	format dsstdt date9.;
       set pre_sdtm.genpro;
         
       /*has informed consent been obtained*/
       
       if gpcns = 'Y' then do;
          dsdecod = 'CONSENT OBTAINED';
          dsterm = dsdecod;
       end;
       
       else if gpcns = 'N' then do;
          dsdecod = "CONSENT NOT OBTAINED";
         	 if missing(gpcnsoth) and missing(gpcnrscd) then do;
              	dsterm = 'CONSENT NOT OBTAINED';
          	 end;
          	
             else if not missing(gpcnsoth) then do;
                dsterm=gpcnsoth;
             end;
          
             else if not missing(gpcnrscd) and missing(gpcnsoth) then do;
                dsterm = gpcnsrs;
             end;
       
       end;
       
       if not missing(dsdecod) or not missing(dsterm) then do;
       
          DSCAT = 'PROTOCOL MILESTONE';
          dsstdt = gpcnsdt; /*date of informed consent obtained*/
          OUTPUT;
       end;
       
       if gpcnswd = 'Y' and not missing(gpcnswdt) then do;
          dsdecod = 'CONSENT WITHDRAWN';
          dsterm = 'CONSENT WITHDRAWN';
          dscat = 'OTHER EVENT';
          DSSTDT = GPCNSWDT;/* DATE OF INFORMED CONSENT WITHDRAWN*/
        OUTPUT;
       end;
       
      run;
  
  %end;
  	
%mend;

