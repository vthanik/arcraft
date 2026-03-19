/******************************************************************************* 
|
| Macro Name: tu_sdtmconv_pst_check_td
|
| Macro Version/Build: 7/1
|
| SAS Version: SAS 9.1.3
|
| Created By: Bruce Chambers
|
| Date:            12-Aug-2009
|
| Macro Purpose: To add the Trial design datasets (if present) in the sdtm directory for 
|                the current run. Do this later in the process after the main domain creation 
|                steps so that they will be added to the driver tables post domain creation,
|                This means they will be included in the checks for controlled terms 
|                and duplicates etc.
|
|                The trial design domains are TA,TE,TI,TS and TV. Also add SE if present.
|
| Macro Design:  Procedure
|
| Input Parameters:
|
|             None
|
| Output:
|	Rows in sdtm_dom driver table
|
| Global macro variables created:
| 
|  None
|
| Macros called:
|(@) tu_tidyup
|(@) tu_chkvarsexist
|
| Example:
|     %tu_sdtmconv_pst_check_td;
|
|******************************************************************************* 
| Change Log 
|
| Modified By:                 Bruce Chambers
| Date of Modification:        16August2010
| New Version/Build Number:    2/1
| Reference:                   bjc001
| Description for Modification:Add in RELREC to list of datasets to pick up and check
| Reason for Modification:     Ensure RELREC data conform to the various domain specifications
|                              i.e. it will be checked for correct columns and duplicate rows etc
|
| Modified By:                 Bruce Chambers
| Date of Modification:        16August2010
| New Version/Build Number:    2/1
| Reference:                   bjc002
| Description for Modification:List any mismatches between VISIT values in SV vs TV 
|                              and IETEST(CD) values in IE vs TI, and ARM(CD) between TA and DM
| Reason for Modification:     Ensure data is consistent within CRF and TD domains
|
| Modified By:                 Bruce Chambers
| Date of Modification:        18October2010
| New Version/Build Number:    3/1
| Reference:                   bjc003
| Description for Modification:Amend SDTM libname to SDTMDATA
| Reason for Modification:     Preparation for new HARP release
|
| Modified By:                 Bruce Chambers
| Date of Modification:        04November2010
| New Version/Build Number:    4/1
| Reference:                   bjc004
| Description for Modification:Add trims to sql queries and correct the SQL, 
|                              and check for PERIOD/EPOCH matches.
|                              Update _td_doms with dom_desc and dom_type field
| Reason for Modification:     Ensure only real issues are identified
|
|
| Modified By:                 Ashwin Venkat
| Date of Modification:        9May2011
| New Version/Build Number:    5/1
| Reference:                   VA001
| Description for Modification: Issue a note if TD domains were or were Not checked
| Reason for Modification:     if full/non-subset is run and no TD then issue warning
|
| Modified By:                  Bruce Chambers
| Date of Modification:         26aug2011
| New Version/Build Number:     6/1
| Reference:                    BJC005
| Description for Modification: If not in check mode, copy TD domains to PST_SDTM
|                               (If in check mode this copy happens already)
| Reason for Modification:      Ensure check and convert modes both run correctly
|
|
| Modified By:                 Ashwin Venkat
| Date of Modification:        9May2011
| New Version/Build Number:    7/1
| Reference:                   VA002
| Description for Modification: Check dm.actarm(cd) where present matches with a value in ta.arm(cd). if not 
| 								set dm.actarm to UNPLANNED  
|Reason for Modification:       Check dm.actarm(cd) where present matches with a value in ta.arm(cd). if not 
| 								set dm.actarm to UNPLANNED
|
| Modified By:                 Ashwin Venkat
| Date of Modification:        9May2011
| New Version/Build Number:    7/1
| Reference:                   VA003
| Description for Modification: setting ACTARM(CD) TO 'Not Treated' if RFXSTDTC is missing and arm=actarm 
| Reason for Modification:    setting ACTARM(CD) TO 'Not Treated' if RFXSTDTC is missing and arm=actarm
|
| Modified By:                 Ashwin Venkat
| Date of Modification:        18Jun2011
| New Version/Build Number:    7/1
| Reference:                   VA004
| Description for Modification: Defaulting ACTARM(CD) to ARM(CD) for DM data from SI
| Reason for Modification:      Defaulting ACTARM(CD) to ARM(CD) for DM data from SI
|
********************************************************************************/ 

%macro tu_sdtmconv_pst_check_td(
);

/* BJC001: Add RELREC to list of domains to check if present in /sdtmdata directory */
/* BJC003: amend lib refs of sdtm to sdtmdata */
/* BJC004: add dom_desc and dom_type to _td_doms lookup and populate */
/* BJC005: initialise ref_doms macro var */
%let ref_doms=;

 proc sql noprint;
   create table _td_doms as
   select memname as domain
     from dictionary.tables 
    where libname = 'SDTMDATA' 
      and memname in ('TA','TE','TI','TS','TV','SE','RELREC') 
      and memtype = 'DATA';  
 
   alter table _td_doms add dom_desc char(300) ;
   update _td_doms dom set dom_desc=(select dom_desc from domain_ref dr
   where dr.domain=dom.domain); 
   
   alter table _td_doms add dom_type char(75) ;
   update _td_doms dom set dom_type=(select dom_type from domain_ref dr
   where dr.domain=dom.domain);     
   
   /* BJC005: create string to specify which of the TD and other added domains are present */
   select domain into :ref_doms separated by ' ' from _td_doms;
quit;

** Add any of the potential datasets present to the sdtm_dom driver table if found **;

 data sdtm_dom; 
  set sdtm_dom 
      _td_doms;
 run; 
/*VA001: if full/non-subset run and no TD domains present then issue warning*/

%if %eval(%tu_nobs(_td_doms))=0 %then %do;  
	%let _cmd = %str(%STR(RTW)ARNING:Running full Study but no TD domains found.);%tu_sdtmconv_sys_message;
%end;	
/*VA001: check if TD domains are used during conversion*/ 
%else %do;  
		%let _cmd = %str(TD domains found...);%tu_sdtmconv_sys_message;
%end;


 proc sort data=sdtm_dom;
  by domain;
 run;

/* BJC002: checks for mismatches between VISIT values in SV vs TV and IETEST(CD) values in IE vs TI, 
/  and ARM(CD) between TA and DM
/  We only list values in the CRF data that are not found in the Trial Design data, not the reverse.
/
/  The TD domains are a super set of all potential values. Not all possible TI.IETEST(CD) and TV.VISIT
/  values will always appear in the study IE and SV data. */

/* BJC003: amend lib refs of sdtm to sdtmdata in all steps below*/
/* BJC004: add trims to the sql queries below where trims are not present */

%if %sysfunc(exist(pst_sdtm.SV)) and %sysfunc(exist(sdtmdata.TV)) %then %do;

 proc sql noprint;
  create table _report_tv_issues as 
  select distinct '* SV VISIT='||trim(visit)||' not in TV domain' as problem_desc, 
    'TV' as memname, 'VISIT' as name
    from pst_sdtm.sv
  where (upcase(visit) not like 'UNS%'
         and visitnum=int(visitnum) ) 
    and trim(visit) not in (select trim(visit) from sdtmdata.tv);
 quit; 

%end;

%if %sysfunc(exist(pst_sdtm.DM)) and %sysfunc(exist(sdtmdata.TA)) %then %do;
 %if %tu_chkvarsexist(pst_sdtm.DM, ARM ARMCD) eq %then %do;

  proc sql noprint;
   create table _report_ta_issues1 as 
   select distinct '* DM ARMCD='||trim(armcd)||' not in TA domain' as problem_desc, 
     'TA' as memname, 'ARMCD' as name
     from pst_sdtm.dm
   where trim(armcd) not in ('SCRNFAIL','NOTASSGN')
     and trim(armcd) not in (select distinct trim(armcd) from sdtmdata.ta);
 
   create table _report_ta_issues2 as 
   select distinct armcd as name,
          '* DM ARM is not in TA domain [for this ARMCD]' as problem_desc,
          'TA' as memname
     from pst_sdtm.dm a
    where trim(armcd) not in ('SCRNFAIL','NOTASSGN')
      and trim(armcd) not in (select trim(name) from _report_ta_issues1)
      and trim(arm) not in (select distinct trim(arm) from sdtmdata.ta b 
                             where a.armcd=b.armcd);
  quit; 

  /*VA002: Check dm.actarm(cd) where present matches with a value in ta.arm(cd). if not 
  set dm.actarm to UNPLANNED*/
 

    proc sql noprint;
        select distinct quote(strip(armcd)) into : taarmcd separated by ' ' 
        from sdtmdata.ta;
    quit;

    %let rfxstdt = %length(%tu_chkvarsexist(pst_sdtm.DM, rfxstdtc));

    /* Setting treatment to unplanned if not in TA domain*/
	
    data pst_sdtm.dm;       
        set pst_sdtm.dm;
		/* May run in check mode (from CRO) with vars present - so check before setting length */
		%if %tu_chkvarsexist(pst_sdtm.DM, ACTARM ACTARMCD) ne %then %do;
		 length ACTARM $200 ACTARMCD $20 ;
		%end; 
		
		/* DM and TA ARMCD must always match, but S&P may define a different ACTARM in TA domain to meet reporting needs.
           The DM.ACTARM comes from RANDALL and in-stream will contain DUMMY and never match TA domain definition so the
		   values of DM.ACTARM vs TA.ACTARM are not reliable for (in-stream) comparison. */
		   
        if not missing(actarm) and not missing(arm) and actarmcd not in (&taarmcd "SCRNFAIL" "NOTASSGN" "NOTTRT") then do ;
        	ACTARMCD = 'UNPLAN';
        	ACTARM = 'Unplanned Treatment';
        end;
		
        /* Setting ACTARM(CD) TO 'Not Treated' if RFXSTDTC is missing and arm=actarm*/
        %if %tu_chkvarsexist(pst_sdtm.DM, RFXSTDTC) eq %then %do;
            if ARMCD^='' and ARMCD=ACTARMCD and arm not in ('Screen Failure','Not Assigned') and missing(RFXSTDTC) then do;
                ACTARMCD='NOTTRT';
                ACTARM='Not Treated';              
            end;
        %end;  
    run;

 %end;
%end;

/*VA004: Defaulting ACTARM(CD) to ARM(CD) for DM data from SI*/

%if %sysfunc(exist(pst_sdtm.DM)) %then %do;
	data pst_sdtm.dm;
		length ACTARM $200 ACTARMCD $20 ;
		set pst_sdtm.dm;
		if ACTARMCD= '' then ACTARMCD = ARMCD;
		if ACTARM='' then ACTARM = ARM;
	run;
%end;

%if %sysfunc(exist(pst_sdtm.IE)) and %sysfunc(exist(sdtmdata.TI)) %then %do;

 proc sql noprint;
   create table _report_ti_issues1 as 
   select distinct ietestcd as name, 
          '* IE IETESTCD is not in TI domain [for same IECAT]' as problem_desc,
          'TI' as memname
     from pst_sdtm.ie a
    where trim(ietestcd)||trim(substr(iecat,1,9)) not in (select trim(ietestcd)||trim(iecat) from sdtmdata.ti );
   
   create table _report_ti_issues2 as 
   select distinct ietestcd as name,
          '* IE IETEST is not in TI domain [for same IECAT]' as problem_desc,
          'TI' as memname
     from pst_sdtm.ie a
    where trim(ietest)||trim(substr(iecat,1,9)) not in (select trim(ietest)||trim(iecat) from sdtmdata.ti );
 quit; 
 
%end;

/* BJC004: add check of PERIOD values in all domains versus EPOCH in TA */

%if %sysfunc(exist(sdtmdata.TA)) %then %do;

 proc sql noprint;
  create table _td_doms_epoch as
  select memname 
    from dictionary.columns
   where libname='PST_SDTM' 
     and name='EPOCH';
 quit; 

 %if &sqlobs=0 %then %goto skip;
 %let ep_num=&sqlobs;
 
 proc sql noprint;
  select memname
     into :ep_dset1- :ep_dset%left(&ep_num)      
     from _td_doms_epoch
    order by memname;
 quit;

 proc sql noprint;
  %do a=1 %to &ep_num;
    create table _td_doms_epoch_&a as
    select distinct "EPOCH" as name, 
         '* EPOCH '||trim(EPOCH)||' is not in TA domain ' as problem_desc,
          "&&ep_dset&a" as memname
      from pst_sdtm.&&ep_dset&a
     where epoch is not null 
       and trim(epoch) not in (select distinct trim(epoch) from sdtmdata.TA);
  %end;
 quit; 
 
  data _report_ta_issues3;
   attrib problem_desc length=$60;
   set
    %do a=1 %to &ep_num;
      _td_doms_epoch_&a
    %end;
      ;
  run;
  
 %skip:
%end;

/* BJC005: if reference domains present - copy to PST_SDTM libname to they can be shrunk, CT checked etc 
/          NB: If in check mode this copy already happened earlier in create macro */

%if &check_only ^= Y and &ref_doms ^= %then %do; 
 /* Proc copy datasets into PST library */
 proc copy in=sdtmdata noclone out=pst_sdtm memtype=data;
   select &ref_doms;
 run;
%end;  

/* BJC004: end of new section */

%if &sysenv=BACK %then %do;  

%tu_tidyup(
 rmdset = _td_doms:,
 glbmac = none
);
%end;

%mend tu_sdtmconv_pst_check_td;
