/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_si_bespoke_pc
|
| Macro Version/Build:  4/1
|
| SAS Version:          9.1.3
|
| Created By:           Ian Barretto
|
| Date:                 01-Oct-2009
|
| Macro Purpose:        Pre-process PK Concentration data according to mapping specs
|
| Macro Design:         Procedure
|
| Input Parameters: None
|
| Output:
|
| Global macro variables created: None
|
|
| Macros called:
| (@)tu_chkvarsexist
| (@)tu_tidyup
| (@)tu_varattr
|
| Example:
|
| sdtmconv_pre_si_bespoke_pc
|
|*******************************************************************************
| Change Log:
|
| Modified By                 : Deepak Sriramulu (dss27908)
| Reference	                  : DSS001
| Date of Modification        : 13 Sep 2010 
| New Version/Build Number    : 2 build 1     
| Description for Modification: 1) rename PCSPEC1 to PCSPEC. 
|				2) if PCCOM and PCORRES IDSL data have same value - remove PCCOM version - otherwise same data recorded twice
| Reason for Modification     : As per DSO request
|
|Modified By                  : Ashwin Venkat
| Reference	                  : VA001
| Date of Modification        : 12Feb 2011
| New Version/Build Number    : 3 build 1     
| Description for Modification:mapping PCCOM to PCREASND or to CO domain based on value in PCORRES
| Reason for Modification     :if PCORRES is missing then PCCOM should get mapped to PCREASND and not CO domain, if PCORRES
|                              is not missing then map to CO domain
|
| Modified By                 : Deepak Sriramulu
| Reference	                  : DSS002
| Date of Modification        : 27 Apr 2011
| New Version/Build Number    : 4 build 1     
| Description for Modification: Remove code which concatenates PCTYP with PCSPEC
| Reason for Modification     : Using PCTYP/CD is not correct as there are a lot of MATRIX values which are not used  
|                              
*******************************************************************************/
%macro tu_sdtmconv_pre_si_bespoke_pc(
);

 ** Check if any of the PCAN values are >8 in length as these end up as PCTEST **;
 proc sql noprint;
  select count(*) into :pcan_gt8 from pre_sdtm.pkcnc
  where length(pcan)>8;
 quit;

 data pre_sdtm.pkcnc;
  set pre_sdtm.pkcnc;
  length PCTESTCD $8.;
  ** If all the PCAN values are less than 8 then populate PCTEST directly **;
  %if &pcan_gt8 =0 %then %do;
   PCTESTCD=PCAN;
  %end;
 run;

 ** If any of the PCAN values are >8 then populate PCTESTCD with a derived value for those >8 **;
 %if &pcan_gt8 >=1 %then %do;
  proc sql noprint;
   create table pcan as
   select distinct pcan from pre_sdtm.pkcnc
   where length(pcan)>8;
  quit;

  data pcan;
   set pcan;
   if length(PCAN)>8 then PCTESTCD=compress('ANALYT'||trim(put(_n_,8.)));
   else PCTESTCD=PCAN;

   FMTNAME='$PCTEST';
   rename PCAN=start PCTESTCD=label;
  run;

  proc format cntlin=pcan lib=work;
  run;

  data pre_sdtm.pkcnc;
   set pre_sdtm.pkcnc;
   if length(PCAN)>8 then PCTESTCD=put(PCAN,$PCTEST.);
   else PCTESTCD=PCAN;
  run;
 %end;

/* DSS002: Remove code which concatenates PCTYP with PCSPEC */

** Get master PKCNC dataset to check for non-blood variables **;
** Otherwise will be appending to ever growing dataset   **;

 data pkcnc_volume;
   set pre_sdtm.pkcnc;
 run;

** Append PCVOL and PCVOLU if both are present **;
 %if %tu_chkvarsexist(pre_sdtm.pkcnc, PCVOL PCVOLU) eq %then %do;

   data pkcnc_pcvol;
     set pkcnc_volume;
     where pcvol ne .;
     PCCAT='SPECIMEN';
     PCTESTCD='VOLUME';
     PCAN=left("%tu_varattr(pre_sdtm.pkcnc,pcvol,varlabel)");

     PCORRES=input(pcvol,best.);
     PCORRESU=pcvolu;

     PCSTRESC=input(pcvol,best.);
     PCSTRESN=pcvol;
     PCSTRESU=pcvolu;
   run;

   data pre_sdtm.pkcnc;
    set pre_sdtm.pkcnc pkcnc_pcvol;
   run;
 %end;

** Append PCWT and PCWTU if both are present **;
 %if %tu_chkvarsexist(pre_sdtm.pkcnc, PCWT PCWTU) eq %then %do;

   data pkcnc_pcwt;
     set pkcnc_volume;
     where pcwt ne .;
     PCCAT='SPECIMEN';
     PCTESTCD='WEIGHT';
     PCAN=left("%tu_varattr(pre_sdtm.pkcnc,pcwt,varlabel)");

     PCORRES=input(pcwt,best.);
     PCORRESU=pcwtu;

     PCSTRESC=input(pcwt,best.);
     PCSTRESN=pcwt;
     PCSTRESU=pcwtu;
   run;

   data pre_sdtm.pkcnc;
    set pre_sdtm.pkcnc pkcnc_pcwt;
   run;
 %end;

** Append PCPH if present **;
 %if %tu_chkvarsexist(pre_sdtm.pkcnc, PCPH) eq %then %do;

   data pkcnc_pcph;
     set pkcnc_volume;
     where pcph ne .;
     PCCAT='SPECIMEN';
     PCTESTCD='PH';
     PCAN=left("%tu_varattr(pre_sdtm.pkcnc,pcph,varlabel)");

     PCORRES=input(pcph,best.);
     PCORRESU='';

     PCSTRESC=input(pcph,best.);
     PCSTRESN=pcph;
     PCSTRESU='';
   run;

   data pre_sdtm.pkcnc;
    set pre_sdtm.pkcnc pkcnc_pcph;    
   run;
 %end;

/* DSS001 if PCCOM and PCORRES IDSL data have same value - remove PCCOM version - otherwise same data recorded twice */   
   data pre_sdtm.pkcnc;
    set pre_sdtm.pkcnc ;
    if PCORRES eq PCCOM then PCCOM='';
   run;

/*VA001: mapping PCCOM to PCREASND or to CO domain based on value in PCORRES*/
%let pcorr = %length(%tu_chkvarsexist(pre_sdtm.pkcnc,pcorres));
%let pccom = %length(%tu_chkvarsexist(pre_sdtm.pkcnc,pccom));

data pre_sdtm.pkcnc;
	set pre_sdtm.pkcnc;
	%if &pcorr eq 0 and &pccom eq 0 %then %do;
		if missing(pcorres) and not missing(pccom) then do;
			pcreasnd = pccom;
			pcstat = "NOT DONE";
			pccom = "";
		end;
	%end;
run; 
%if &sysenv=BACK %then %do;

  %tu_tidyup(
    rmdset = _pre_bespoke_pc:,
    glbmac = none
    );

%end;

%mend tu_sdtmconv_pre_si_bespoke_pc;
