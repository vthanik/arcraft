/******************************************************************************* 
|
| Macro Name: tu_sdtmconv_mid_norm_add
|
| Macro Version/Build: 7/1
|
| SAS Version: SAS 9.1.3
|
| Created By: Bruce Chambers
|
| Date:            12-Aug-2009
|
| Macro Purpose: Add various fields in FINDINGS domains :
|
|                --STRESU is copied from --ORRESU if not already defined
|                --REASND and --STAT populated where --ORRES = 'No Result','NA' 
|                    but only if not already populated e.g. GENPRO data
|                --STRESC created from --ORRES if not already populated
|                --STRESN created from --ORRES if not already populated
|
| Macro Design: Procedure
|
| Input Parameters:
|
| None
|
| Output:
|        mid_sdtm.&dom._&dset
|
| Global macro variables created:
|
|
| Macros called:
| (@) tu_chkvarsexist
|
| Example:
|
|******************************************************************************* 
| Change Log 
|
| Modified By:                  Bruce Chambers
| Date of Modification:         28april2010
| New Version/Build Number:     v2 build 1
| Reference:                    BJC001
| Description for Modification: Update 'NO RESULT' string to add 'NO RESULT','NA','N/A','NOT DONE','NQ'
| Reason for Modification:      When processing findings data, if an -ORRES field contains
|                               any of the above entries they should be moved to --REASND.
|                               Also null out --STRESC if that data is already present from source
|                               Added code to move 'IS','NC','NS','ND' values from PC/PP domains to --REASND
|                               NB: Code Matches partner code section in tu_sdtmconv_mid_trans.sas 
|
| Modified By:                  Bruce Chambers
| Date of Modification:         04august2010
| New Version/Build Number:     v3 build 1
| Reference:                    BJC002
| Description for Modification: Add full complement of 2 letter PC/PP codes to move to --REASND
| Reason for Modification:      Ensure data is SDTM compliant
|
| Modified By:                  Bruce Chambers
| Date of Modification:         22November2010
| New Version/Build Number:     v4 build 1
| Reference:                    BJC003
| Description for Modification: Move attrib statement to correct place
| Reason for Modification:      Ensure SDTM data is formatted correctly
|
| Modified By:                  Ashwin Venkat
| Date of Modification:         4Feb2011
| New Version/Build Number:     v4 build 1
| Reference:                    VA001
| Description for Modification: Clean up __ORRES  and __ORRESU combinations  for OPENCDISC checks
| Reason for Modification:    
|  
| Modified By:                  Deepak Sriramulu
| Date of Modification:         4May2011
| New Version/Build Number:     v5 build 1
| Reference:                    DSS001
| Description for Modification: Set --REASND for PC and PP to larger size to allow later decode
| Reason for Modification:      To provide full data
|
| Modified By:                  Bruce Chambers
| Date of Modification:         14Feb2013
| New Version/Build Number:     v6 build 1
| Reference:                    BJC004
| Description for Modification: Correct a &dom_ref to &dom
| Reason for Modification:      To ensure correct data product and error free run
|
| Modified By:                  Bruce Chambers
| Date of Modification:         05Aug2013
| New Version/Build Number:     v7 build 1
| Reference:                    BJC005
| Description for Modification: Correct scenario for where lab data underwent unit conversion 
| Reason for Modification:      LBSTRESC not being populated correctly for all scenarios
|
********************************************************************************/ 

%macro tu_sdtmconv_mid_norm_add(
);

 data mid_sdtm.&dom._&dset;
  /*DSS001 - set the PC/PPREASND fields to be larger to allow later decoding */
  %if &dom_ref = PC or &dom_ref = PP %then %do;
   attrib &dom_ref.REASND length=$200;
  %end;
  set mid_sdtm.&dom._&dset;
  
  /* BJC001 and BJC002 : increase the list of entries moved to --REASND */  

  if upcase(&dom_ref.ORRES) in ('NO RESULT','NA','N/A','NOT DONE','NQ','---------')
     or ("&dom_ref" in ("PP","PC") and upcase(&dom_ref.ORRES) in ('IS','NR','NQ','NC','NS','ND') )  then do;
  
     /* Some data groups can create --REASND in pre-processing steps e.g. bespoke_GENP
     / we need to make sure we dont overwrite any existing entries that may be present */
     %if %tu_chkvarsexist(mid_sdtm.&dom._&dset,&dom_ref.REASND) eq %then %do;
      if &dom_ref.REASND='' then 
     %end;      
                                  &dom_ref.REASND=&dom_ref.ORRES;
        
   &dom_ref.STAT='NOT DONE';
   &dom_ref.ORRES='';
   
   %if %tu_chkvarsexist(mid_sdtm.&dom._&dset,&dom_ref.STRESC) eq %then %do;
    &dom_ref.STRESC='';
   %end;
  end;
 run;

 /* If not already in the data (e.g. LAB) then add in extra variables needed */
     data mid_sdtm.&dom._&dset; 

      /* BJC003: move the attrib to in between data and set statements */
      %if %tu_chkvarsexist(mid_sdtm.&dom._&dset,&dom_ref.STRESC) eq %then %do;
       attrib &dom_ref.STRESC length=$200;
      %end;

      set mid_sdtm.&dom._&dset;
            
       /* BJC005: To allow for ECG/EG pre-processing where STRESC may already be pre-set
           and for LAB where STRESN (but not STRESC may be populated */
       
	    /* NOTE: where the tu_chkvarsexist check product is null then the variable exists */
		
        %if %tu_chkvarsexist(mid_sdtm.&dom._&dset,&dom_ref.STRESC) eq %then %do;
         if &dom_ref.STRESC = '' then 
        %end; 
            &dom_ref.STRESC = upcase(&dom_ref.ORRES); 	
			
        %if %tu_chkvarsexist(mid_sdtm.&dom._&dset,&dom_ref.STRESN) eq %then %do;
		   if not(missing(&dom_ref.STRESN)) then &dom_ref.STRESC = left(input(&dom_ref.STRESN, ?? 8.)); 
		   if missing(&dom_ref.STRESN) then &dom_ref.STRESN = input(&dom_ref.ORRES, ?? 8.); 
        %end;
		
 /* Even though --STRESN is later numeric, after the main proc transpose step 
 /  it is still a char type column at this point 
 /  NOTE: this step will not place char data in the --STRESN field */
 
 %if %tu_chkvarsexist(mid_sdtm.&dom._&dset,&dom_ref.STRESN) ne %then %do;
 
     /* NOTE: If converting LAB DM SI data the STRESN will most likely not be present
     /        and may be inappropriately defaulted here.  */
 
      data mid_sdtm.&dom._&dset; 
       set mid_sdtm.&dom._&dset;      
      if input(&dom_ref.ORRES, ?? 8.) ^=. then &dom_ref.STRESN = &dom_ref.ORRES; 
      run;
      
 %end; 
       
 %if %tu_chkvarsexist(mid_sdtm.&dom._&dset,&dom_ref.STRESU) ne 
  and %tu_chkvarsexist(mid_sdtm.&dom._&dset,&dom_ref.ORRESU) eq %then %do;
  
    /* NOTE: If converting LAB DM SI data the STRESU will most likely not be present
    /        and may be inappropriately defaulted here.  */
    
    data mid_sdtm.&dom._&dset; 
     attrib &dom_ref.STRESU length=$200;
     set mid_sdtm.&dom._&dset; 
      &dom_ref.STRESU=&dom_ref.ORRESU;
    run;
  
  %end;
  /*VA001: if __ORRES  is missing then make __ORRESU missing*/

  %if %tu_chkvarsexist(mid_sdtm.&dom._&dset,&dom_ref.ORRES &dom_ref.ORRESU) eq %then %do;
    data mid_sdtm.&dom._&dset;
	    /* BJC004: replace &dom_ref in set statement with &dom */
        set mid_sdtm.&dom._&dset;
        if missing(&dom_ref.ORRES)  then &dom_ref.ORRESU = '';
    run;
  %end;
 %if %tu_chkvarsexist(mid_sdtm.&dom._&dset,&dom_ref.STRESC &dom_ref.STRESU) eq %then %do;
    data mid_sdtm.&dom._&dset;	
        set mid_sdtm.&dom._&dset;
        if missing(&dom_ref.STRESC) then &dom_ref.STRESU = '';
    run;
  %end;

%mend tu_sdtmconv_mid_norm_add;
