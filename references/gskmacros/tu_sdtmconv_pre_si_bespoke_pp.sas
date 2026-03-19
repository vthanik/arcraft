/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_si_bespoke_pp
|
| Macro Version/Build:  2/1
|
| SAS Version:          9.1.3
|
| Created By:           Ian Barretto
|
| Date:                 06-Oct-2009
|
| Macro Purpose:        Pre-process PK Parameter data according to mapping specs
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
| (@)tu_nobs
| (@)tu_sdtmconv_sys_message
| (@)tu_tidyup
|
| Example:
|
| sdtmconv_pre_si_bespoke_pp
|
|*******************************************************************************
| Change Log:
|
| Modified By:					Deepak Sriramulu (DSS001)
| Date of Modification:			04May2011
| New Version/Build Number:	    2/1
| Description for Modification: Add PCSTDT & PCSTTM to PKPAR from PKCNC dataset for later creation of PPDTC
| Reason for Modification:      PPDTC was missing from the PP dataset.
|
*******************************************************************************/
%macro tu_sdtmconv_pre_si_bespoke_pp(
);


** run pre-procesing for PP(pkpar) data **;
%if %sysfunc(exist(pre_sdtm.pkpar)) %then %do;

 %if %tu_chkvarsexist(pre_sdtm.pkpar,pporresc) eq %then %do;
  
   ** Copy PPORRESN into PPORRES and drop PPORRESN **;
   data pre_sdtm.pkpar(drop=pporresn) problem_pkpar(keep=pporresn pporresc);
    set pre_sdtm.pkpar;
       
     if pporresn ^=. and pporresc^='' and left(put(pporresn,best32.))^=pporresc then output problem_pkpar;
        
     *if pporresn ^=. then PPORRES=left(put(pporresn,best32.));
     if pporresc ^= '' then PPORRES=pporresc;
     output pre_sdtm.pkpar;
   run;   
     
   proc sort data=problem_pkpar nodupkey;
   by pporresn pporresc;
   run;
    
   %if %eval(%tu_nobs(problem_pkpar))>=1 %then %do;
    
     proc print data=problem_pkpar (obs=30);
        title3 "SDTM conversion: &g_study_id PKPAR[PP] rows where PPORRESC and PPORRESN populated";
        title4 "different values on same row. Unique combinations listed, some may occur >1.";
        title5 "System will take and process the numeric field in these cases.";
        var pporresn pporresc;
     run;

     %let _cmd = %str(%str(RTW)ARNING: PKPAR data has PPORRESC and PPORRESN populated with different values on same row);
     %tu_sdtmconv_sys_message;
     %let _cmd = %str(       The system will process the numeric value);%tu_sdtmconv_sys_message;

   %end;
   
 %end;

 ** Check if any of the PPPAR values are >8 in length as these end up as PPTEST **;
  proc sql noprint;
   select count(*) into :pppar_gt8 from pre_sdtm.pkpar
   where length(pppar)>8;
  quit;
 
  data pre_sdtm.pkpar;
   set pre_sdtm.pkpar;
   length PPTESTCD $8.;
   ** If all the PPPAR values are less than 8 then populate PPTESTCD directly **;
   %if &pppar_gt8 =0 %then %do;
    PPTESTCD=PPPAR;
   %end;
  run;
 
  ** If any of the PCAN values are >8 then populate PCAN with a derived value for those >8 **;
  %if &pppar_gt8 >=1 %then %do;
   proc sql noprint;
    create table pppar as
    select distinct pppar from pre_sdtm.pkpar
    where length(pppar)>8;
   quit;
 
   data pppar;
    set pppar;
    if length(PPPAR)>8 then PPTESTCD=compress('TEST'||trim(put(_n_,8.)));
    else PPTESTCD=PPPAR;
    
    FMTNAME='$PPTEST';
    rename PPPAR=start PPTESTCD=label;
   run;
 
   proc format cntlin=pppar lib=work;
   run;
 
   data pre_sdtm.pkpar;
    set pre_sdtm.pkpar;
    if length(PPPAR)>8 then PPTESTCD=put(PPPAR,$PPTEST.);
    else PPTESTCD=PPPAR;
   run;
 %end;

  ** Merge on PCRFDSDT and PCRFDSTM  from PKCNC to create PPRFTDTC**;
  %if %sysfunc(exist(pre_sdtm.pkcnc)) %then %do;
    data pkpar_spec;
      attrib spec length=$80;
      set pre_sdtm.pkpar;
      spec=upcase(ppspec);
    run;

    proc sort data=pkpar_spec;
      by usubjid spec visitnum;
    run;
    /* DSS001:  Add PCSTDT & PCSTTM for later creation of PPDTC */
    data pkcnc_spec (keep=usubjid spec visitnum pcstdt pcsttm pcrfdsdt pcrfdstm);
      attrib spec length=$80;
      set pre_sdtm.pkcnc;
      spec=upcase(pcspec);
    run;

    proc sort data=pkcnc_spec nodupkey;
      by usubjid spec visitnum;
    run;

    data pre_sdtm.pkpar (drop=spec);
      merge pkpar_spec(in=a) pkcnc_spec;
      by usubjid spec visitnum;
      if a;
    run;
  %end;

%end;

%if &sysenv=BACK %then %do;
  %tu_tidyup(
    rmdset = _pre_bespoke_pp:,
    glbmac = none
    );
%end;

%mend tu_sdtmconv_pre_si_bespoke_pp;
