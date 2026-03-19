/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_si_bespoke_mh
|
| Macro Version/Build:  3/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009
|
| Macro Purpose:        Pre-process MEDHIST data according to mapping specs
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
|
| Example:
|
| %tu_sdtmconv_pre_si_bespoke_mh
|
|*******************************************************************************
| Change Log:
|
| Modified By:                  Bruce Chambers
| Date of Modification:         05april2011
| New Version/Build Number:     2/1      
| Description for Modification: Null out MHOCCUR when value moves to MHREASND
| Reason for Modification:      Correct presentation of data
|
| Modified By:                  Deepak Sriramulu
| Date of Modification:     	18April2011      
| New Version/Build Number: 	V2 Build 1    
| Reference:                    DSS001
| Description for Modification: Store MHCLASS values in MHCAT instead of MHSCAT and for liver event records MHCAT 
|                                will be LIVER EVENT
| Reason for Modification:      MHSCAT needs to be MHCAT. Also, if VISITNUM= a liver event visit(811-8nn), then 
|                               MHCAT=LIVER EVENT. 
|
| Modified By:                  Bruce Chambers
| Date of Modification:     	22Jan2013      
| New Version/Build Number: 	V3 Build 1    
| Reference:                    BJC002
| Description for Modification: Deal with MHSTAT and MHOCCUR in same dataset (multiple forms in study)
| Reason for Modification:      More complex scenario than seen before.
|
*******************************************************************************/
%macro tu_sdtmconv_pre_si_bespoke_mh(
);

** check if the data has MHTERM present and act accordingly **;
%if %tu_chkvarsexist(pre_sdtm.medhist,mhterm) eq %then %do; 

 /* Some studies seem to have MHTERM present but all values empty - this is not desirable 
    and needs to be identified and the empty column dropped */
 proc sql noprint;
  select count(*) into :null_mhterm 
  from pre_sdtm.medhist
  where mhterm is null;
  
  select count(*) into :all_mhterm 
  from pre_sdtm.medhist;
 quit;

 %if &null_mhterm=&all_mhterm %then %do;
  proc sql noprint; 
   alter table pre_sdtm.medhist drop MHTERM;
  quit;
 %end;
%end;

** Redo the check for MHTERM after we have made sure MHTERM is not present in the study but all null **;
%let MHTERM= %tu_chkvarsexist(pre_sdtm.medhist,mhterm,Y); 

/* BJC002: check for MHSTAT and MHOCCUR */
%let MHSTAT= %tu_chkvarsexist(pre_sdtm.medhist,mhstat,Y); 
%let MHOCCUR= %tu_chkvarsexist(pre_sdtm.medhist,mhoccur,Y); 

data pre_sdtm.medhist;
  %if &mhstat^= and &mhoccur^= %then %do;
    attrib MHOCCUR length=$100;
  %end;
 set pre_sdtm.medhist
                     /* BJC002: rename if MHSTAT present without MHOCCUR */
                     %if &mhstat^= and &mhoccur= %then %do;
                      (rename=(MHSTAT=MHOCCUR))
					 %end; 
					  ;
 
 **MHSTAT in SI is not the same as MHSTAT in SDTM so rename here **;
 ** MHOCCUR is decoded to Y and N later in the MSA mapping **;

 ** If there is no MHTERM then rename MHCLASS to MHTERM **;
 %if &MHTERM= %then %do; 
  rename MHCLASS=MHTERM;
 %end;

 /* BJC002: if mhstat and mhoccur both present we need to move data to one and drop the other */
 %if &mhstat^= and &mhoccur^= %then %do;
  if missing(mhoccur) and not missing(mhstat) then do;
   mhoccur=mhstat;
   mhstat='';
   drop mhstatcd;
  end; 
 %end;
 
 ** If MHTERM is present and populated then populate MHCLASS into MHCAT **;
 ** however MHTERM may be null for non liver event rows **;
 %if &MHTERM^= %then %do; 
  if MHTERM='' then MHTERM=MHCLASS;
  
  /* DSS001: Change MHSCAT to MHCAT */
  else MHCAT=MHCLASS;
  if 811<=int(visitnum) <=819 then MHCAT = 'LIVER EVENT'; 
  /* End of DSS001 */

 %end;

 if MHOCCUR='Current' then do;
  MHSTRF='BEFORE';
  MHENRF='DURING/AFTER';
 end;

 if MHOCCUR='Past' then do;
  MHSTRF='BEFORE';
  MHENRF='BEFORE';
 end;

 if MHOCCUR='Not assessed' then do;
  MHSTAT='NOT DONE';
  MHREASND=MHOCCUR;
  MHOCCUR='';
 end; 

run; 

%mend tu_sdtmconv_pre_si_bespoke_mh;
