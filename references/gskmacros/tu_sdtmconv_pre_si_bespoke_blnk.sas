/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_si_bespoke_blnk
|
| Macro Version/Build:  1
|
| SAS Version:          9.1.3
|
| Created By:           Sujoy Ghosh / Ashwin Venkat
|
| Date:                 28Nov2013
|
| Macro Purpose:        Pre-process BIOLINK data according to mapping specs to map it with DS,PR,X5 domain
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
| (@)tu_chkvarsexist
| (@)tu_sdtmconv_sys_register
| (@)tu_sdtmconv_pre_decode
|
| Example:
|
| %tu_sdtmconv_pre_si_bespoke_mh
|
|*******************************************************************************
| Change Log:
|
| Modified By                  : 
| Date of Modification         : 
| New Version/Build Number     : 
| Reference                    : 
| Description for Modification : 
| Reason for Modification      : 
|
*******************************************************************************/
%macro tu_sdtmconv_pre_si_bespoke_blnk(
);


%let GPCNSRS= %tu_chkvarsexist(pre_sdtm.biolink,GPCNSRS,Y); 

%let BIDT= %tu_chkvarsexist(pre_sdtm.biolink,BIDT,Y); 


 %if %sysfunc(exist(pre_sdtm.biolink)) %then %do;
 %tu_sdtmconv_pre_decode;
 /*Processing DS domain from BIOLINK data*/
 /*The variable BIDT is dropped as it is getting mapped to some other domain*/

 data pre_sdtm.biolnkds
 	%if %length(&bidt) gt 0 %then %do; 
 		(drop=bidt)
 	%end;
 	;
  length dscat $80;
  length dsdecod $80;
  length dsscat $80;
  length dsterm $100;
  format dsstdt date9.;
  set pre_sdtm.biolink;
 
 
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
     DSSCAT = 'BIOMARKER';
     dsstdt = gpcnsdt;/*date of informed consent obtained*/
     OUTPUT;
  end;
 
  if gpcnswd = 'Y' and not missing(gpcnswdt) then do;

     dsdecod = 'CONSENT WITHDRAWN';
     dsterm = 'CONSENT WITHDRAWN';
     dscat = 'OTHER EVENT';
     DSSCAT='BIOMARKER';
     DSSTDT = GPCNSWDT;/* DATE OF INFORMED CONSENT WITHDRAWN*/
     OUTPUT;
  end;
 run;
 
 data pre_sdtm.biolnkds;
    set  pre_sdtm.biolnkds;
    dsterm=upcase(dsterm);
 run;
 /**Registering BIOLNKDS**/
 %tu_sdtmconv_sys_register(BIOLNKDS, BIOLINK);

 /*Processing PR domain from BIOLINK data*/
 data pre_sdtm.biolnkpr;
     length prsub $200;
     length prreasnd $200;
     length prcat $200;
     set pre_sdtm.biolink;
     PRCAT="BIOMARKER";
     if bismpcol = 'N' then do;
         PRTRT = 'SAMPLE COLLECTION';
         PRSTAT = "NOT DONE";
     end;
 
     else if bismpcol = 'Y' then do;
           
         if missing(bitsprcd) and missing(bioptcd) then do;
             PRTRT = "SAMPLE COLLECTION";
         end;
         if missing(bioptcd) and not missing(bitsprcd) then do;
             PRTRT = BITSPR;
         end;
         else do;
             PRSUB=BITSPR;/* map this to supp*/
         end;
     end;

     if missing(bismrscd) and not missing(bismrstx) then do;
        prreasnd = bismrstx;
     end;
 run; 
  
 data pre_sdtm.biolnkpr;
    set pre_sdtm.biolnkpr;
    prreasnd=upcase( prreasnd);
    PRTRT=upcase( prtrt);
 run;

 /**Registering BIOLNKPR**/
 %tu_sdtmconv_sys_register(BIOLNKPR, BIOLINK);                

 /*Processing X5 domain from BIOLINK data*/
 data pre_sdtm.biolink 
 	%if %length(&gpcnsrs) gt 0 %then %do; 
 		(drop=gpcnsrs)
 	%end;
 	;
     set pre_sdtm.biolink;
     BISCOL=upcase(BISCOL);
     SMPTY=upcase(SMPTY);
     X5CAT="BIOMARKER";
 run;
 %end;
 
%mend tu_sdtmconv_pre_si_bespoke_blnk;
