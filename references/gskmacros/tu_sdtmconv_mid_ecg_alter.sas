/******************************************************************************* 
|
| Macro Name: tu_sdtmconv_mid_ecg_alter
|
| Macro Version/Build: 6/1
|
| SAS Version: SAS 9.1.3
|
| Created By: Bruce Chambers
|
| Date:            12-Aug-2009
|
| Macro Purpose: ECG specific steps that are added mid-way through SDTM conversion
|                to correctly manipulate IDSL data to SDTM as per mapping instructions.
|                IDSL Project LN DB\SDTM\SDTM Implementation\Mapping for core standards\ECG
|
|                It is called by : tu_sdtmconv_mid_norm
|
|                PLEASE NOTE: Any changes to this code should be mirrored in tc_eganal. The 
|                requirements for the two sets of code should be maintained in common.
|
| Macro Design: Procedure
|
| Input Parameters:
|
| NAME              DESCRIPTION                         DEFAULT 
| None
| 
| Output:
|        mid_sdtm.EG_ECG dataset
|
| Global macro variables created:
|                                 none
|
| Macros called:
| (@) tu_sdtmconv_sys_message
|
| Example:
|         %tu_sdtmconv_mid_ecg_alter;
|
|******************************************************************************* 
| Change Log 
|
| Modified By:                   Bruce Chambers
| Date of Modification:          29April 2010
| New Version/Build Number:      2/1
| Reference:                     BJC001
| Description for Modification:  Add in numerous missing EGFIND codes. Also make the
|                                code output in the future to EGTEST any unmapped codes. 
|                                These will then later get automatically flagged by the CT compliance checks.
|                                Also - amend TESTCD = OTHER to OTHERABN as per DSO amended guidance.
| Reason for Modification:       To ensure all IDSL EGFIND codes are mapped to SDTM TEST(CD) values.
|
| Modified By:                   Bruce Chambers
| Date of Modification:          30 July 2010
| New Version/Build Number:      3/1
| Reference:                     BJC002
| Description for Modification:  For 99 source codes EGORRES and EGSTRESC need to differ
| Reason for Modification:       To ensure for %99 source IDSL codes that EGORRES and EGSTRESC are correct.
|
| Modified By:                   Bruce Chambers
| Date of Modification:          09 August 2010
| New Version/Build Number:      4/1
| Reference:                     BJC003
| Description for Modification:  As a result of amending pre-processing ECG macro to get unique sets of keys
|                                the way data is selected in this macro needs to change subtly.
| Reason for Modification:       To ensure correct SDTM conversion output.
|
| Modified By:                   Bruce Chambers
| Date of Modification:          13 August 2010
| New Version/Build Number:      4/1
| Reference:                     BJC004
| Description for Modification:  check for and report if there are EGFOTH values with no EGFINDCD
| Reason for Modification:       To ensure correct SDTM conversion output.
|
| Modified By:                   Bruce Chambers
| Date of Modification:          23 July 2010
| New Version/Build Number:      4/1
| Reference:                     BJC005
| Description for Modification:  For 99 source codes EGORRES and EGSTRESC need to differ, but must also
|                                always have an entry even where EGFOTH is missing.
| Reason for Modification:       To ensure for %99 source IDSL codes that EGORRES and EGSTRESC are correct.
|
| Modified By:                   Ashwin
| Date of Modification:          10 Oct 2012
| New Version/Build Number:      5/1
| Reference:                     va002
| Description for Modification:  Added missing EGFIND codes and create new warning dataset to aid review and 
|                                identification of future comment issues
| Reason for Modification:       Added missing EGFIND codes and facilitate future troubleshooting.
|
| Modified By:                   Bruce Chambers
| Date of Modification:          01 may 2013
| New Version/Build Number:      6/1
| Reference:                     BJC006
| Description for Modification:  Added missing EGFIND codes 
| Reason for Modification:       Added missing EGFIND codes to ensure correct conversion
|
********************************************************************************/ 
%macro tu_sdtmconv_mid_ecg_alter(
);

/* bjc004: set macro param for later warning*/
%local egwarn;
/*VA002: Added missing EGFIND codes */
data mid_sdtm.EG_ECG (drop=EGFINDCD EGFOTH)
     warning;
 set mid_sdtm.EG_ECG;
 length EGSTRESC EGCAT $200;
 
 /* BJC003 - amend the subset for the findings processing to EGTESTCD='EGFIND', and directly output rows that 
 /  dont meet this criteria */
 
 if EGTESTCD^='EGFIND' then output mid_sdtm.EG_ECG; 
 if EGTESTCD='EGFIND' then do;
 
  /* BJC006: added missing and new codes */
  if EGFINDCD in ('A1','A21','A22','A23','A3','A2','A4','A20','A17','A26','A6','A7','A8','A5','A25','A24','A9',
                  'A12','A13','A28','A14','A29','A18','A19','A10','A11','A32','A33','A27','A30','A15','A31','A16',
                  'A40','A35','A34','A36','A37','A38','A39','A181','A182','XA1','XA2','XA3','XA4','XA5','XA6','XA7',
				  'XA8','XA9','XA10','XA11','XA12','XA13','XA14','XA15','XA16')
   then do;
    EGTESTCD='RHYTHM';
    EGTEST='Rhythm';
    EGSTRESC=EGORRES;
    EGCAT='FINDING';
  end;   

  else if EGFINDCD in ('A99') then do;
    EGTESTCD='RHYTHM';
    EGTEST='Rhythm';
    /* BJC002: Values of EGSTRESC and EGORRRES do need to differ */
    /* BJC005: make this code deal correctly with null EGFOTH values */
    EGSTRESC=EGORRES;
    if EGFOTH^='' then do;
     EGORRES=EGFOTH;
    end;     
    EGCAT='FINDING';
  end;  
 
  else if EGFINDCD in ('B1','B2','B3','B5','B6','B7','B9','B10','B16','D14','B4','B8','B15') then do;
    EGTESTCD='PQRSMOR';
    EGTEST='P-Wave and QRS Morphology';
    EGSTRESC=EGORRES;
    EGCAT='FINDING';    
  end;   
 
  else if EGFINDCD in ('B99') then do;
    EGTESTCD='PQRSMOR';
    EGTEST='P-Wave and QRS Morphology';
    /* BJC002: Values of EGSTRESC and EGORRRES do need to differ */
    /* BJC005: make this code deal correctly with null EGFOTH values */
    EGSTRESC=EGORRES;
    if EGFOTH^='' then do;
     EGORRES=EGFOTH;
    end;     
    EGCAT='FINDING';    
  end;   
 
  /* BJC006: added missing and new codes */
  else if EGFINDCD in ('C1','C20','C2','C3','C16','C4','C5','C6','C7','C13','C8','C14','C15','C9','C17','C10',
                       'C11','C19','C12','C18','C28','C29','C30','C31','C21','C22','C23','C24','C25','C26','C27',
                       'C32','C33','C34','XC1','XC2','XC3','XC4','XC5','XC6','XC7','B11','B12','B13','B14','XC19',
					   'XC20','XC21','XC9','XC8','XC10','XC11','XC12','XC13') 
   then do;
    EGTESTCD='CONDUCTN';
    EGTEST='Conduction';
    EGSTRESC=EGORRES;
    EGCAT='FINDING';    
  end;   

  else if EGFINDCD in ('C99') 
   then do;
    EGTESTCD='CONDUCTN';
    EGTEST='Conduction';
    /* BJC002: Values of EGSTRESC and EGORRRES do need to differ */
    /* BJC005: make this code deal correctly with null EGFOTH values */
    EGSTRESC=EGORRES;
    if EGFOTH^='' then do;
     EGORRES=EGFOTH;
    end;     
    EGCAT='FINDING';    
  end;   
 
  else if EGFINDCD in ('D1','D2','D3','D4','D5','D6','D20') then do;
    EGTESTCD='MI';
    EGTEST='Myocardial Infarction';
    EGSTRESC=EGORRES;
    EGCAT='FINDING';    
  end;   
 
  else if EGFINDCD in ('D98') then do;
    EGTESTCD='MI';
    EGTEST='Myocardial Infarction';
    /* BJC002: Values of EGSTRESC and EGORRRES do need to differ */
    /* BJC005: make this code deal correctly with null EGFOTH values */
    EGSTRESC=EGORRES;
    if EGFOTH^='' then do;
     EGORRES=EGFOTH;
    end;     
    EGCAT='FINDING';    
  end;   
 
  /* BJC006: added missing and new codes */
  else if EGFINDCD in ('D7','D19','D8','D21','D9','D96','D10','D11','D12','D15','D16','D18','D13','D17',
                       'D22','D97','D23','D24','D25','D26','D27','XD1','XD2','XD3','XD4','XD5','XD6') then do;
    EGTESTCD='DEREPOL';
    EGTEST='Depolarisation/Repolarisation (QRS-T)';
    EGSTRESC=EGORRES;
    EGCAT='FINDING';    
  end;   
 
  else if EGFINDCD in ('D99') then do;
    EGTESTCD='DEREPOL';
    EGTEST='Depolarisation/Repolarisation (QRS-T)';
    /* BJC002: Values of EGSTRESC and EGORRRES do need to differ */
    /* BJC005: make this code deal correctly with null EGFOTH values */
    EGSTRESC=EGORRES;
    if EGFOTH^='' then do;
     EGORRES=EGFOTH;
    end;     
    EGCAT='FINDING';    
  end;   

  else if EGFINDCD in ('E99') then do;
    EGTESTCD='OTHERABN';
    EGTEST='Other abnormalities';
    /* BJC002: Values of EGSTRESC and EGORRRES do need to differ */
    /* BJC005: make this code deal correctly with null EGFOTH values */
    
    EGSTRESC=EGORRES;
    if EGFOTH^='' then do;
     EGORRES=EGFOTH;
    end; 
    EGCAT='FINDING';    
  end;  
  
  /* BJC001 - for any unmapped codes, flag clearly in EGTEST field. This is subject to controlled terminology
  /  and so will get clearly reported to the user that this macro needs updating. */
  else do;
   EGTEST=trim(EGFINDCD)||' not recognised -report to support';
   EGTESTCD=EGFINDCD;
  end;
  
  /* BJC003 - output the findings rows separately */
  output mid_sdtm.EG_ECG;

 end;

 /* BJC004 - if EGFIND is not populated but EGFOTH is then we still need to output these rows for completeness 
 /  this data may need to be pre-processed further to correct this but at least the scenario will be flagged by 
 /  the conversion macros */

 if EGFINDCD ='' and EGFOTH ^='' then do; 
      EGTESTCD='OTHERABN';
      EGTEST='Other abnormalities';
      /* Values of EGSTRESC and EGORRRES both from EGFOTH in this scenario */
      EGSTRESC=EGFOTH;
      EGORRES=EGFOTH;
      EGCAT='FINDING';   
      call symput('EGWARN','Y');
      output warning;
 end;   
run; 

/* bjc004: check for specific problem data scenario - warn user if found */
%if &egwarn ne %then %do;
  %let _cmd = %str(%str(RTW)ARNING: tu_sdtmconv_mid_ecg_alter: ECG data problem: EGFOTH present with no EGFINDCD- investigate and rectify);
  %tu_sdtmconv_sys_message;
%end;

%mend tu_sdtmconv_mid_ecg_alter;
