/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pst_sort_dup_chk
|
| Macro Version/Build:  8/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009
|
| Macro Purpose:        Sort data by a set of pre-defined keys e.g. STUDYID, USUBJID, --SEQ
|
|                       Check data for two possible types of duplicate rows:
|                       1) by keys and 
|                       2) by SEQ (unlikely to happen)
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
| (@)tu_nobs
| (@)tu_tidyup
| (@)tu_sdtmconv_sys_message
|
| Example:
|
| %tu_sdtmconv_pst_sort_dup_chk
|
|*******************************************************************************
| Modified By:             	    Bruce Chambers
| Date of Modification:         07Apr2010
| New Version/Build Number:     v2 build 1
| Reference:                    BJC001
| Description for Modification: Update references to variable prefix to use DOMREF
|                               instead of DOMAIN e.g. FA instead of FAMH so that
|                               variables referenced are FASEQ and not FAMHSEQ.
| Reason for Modification: 	    Need to use FA instead of FAMH so that variables 
|                               referenced are FASEQ and not FAMHSEQ.
|
| Modified By:             	    Bruce Chambers
| Date of Modification:         03Sep2010
| New Version/Build Number:     v3 build 1
| Reference:                    BJC002
| Description for Modification: Correct dataset name for the sort nodupkey of duplicate SEQ vars
| Reason for Modification:      Only need one row in user listing
|
| Modified By:             	    Bruce Chambers
| Date of Modification:         08November2010
| New Version/Build Number:     v4 build 1
| Reference:                    BJC003
| Description for Modification: Check TD, SE and RELREC domains as well
| Reason for Modification:      Perform checks not availble in OPENCDISC checks
|
| Modified By:             	    Bruce Chambers
| Date of Modification:         04Feb2011
| New Version/Build Number:     v5 build 1
| Reference:                    BJC004
| Description for Modification: Amend the data sorting to use domain keys and not 
|                               STUDY/USUBJID/--SEQ but only for TDx5, SE and RELREC
| Reason for Modification:      Sort data in a more useful way
|
| Modified By:             	    Bruce Chambers
| Date of Modification:         04Feb2011
| New Version/Build Number:     v6 build 1
| Reference:                    BJC005
| Description for Modification: Use PST_SDTM copy for reference data
| Reason for Modification:      Ensure correct run of check and convert modes
|
| Modified By:             	    Bruce Chambers
| Date of Modification:         27Sep2012
| New Version/Build Number:     v7 build 1
| Reference:                    BJC006
| Description for Modification: Use dom_ref instead of dom_desc for SUPP domain labels
| Reason for Modification:      Ensure length of label <=40
|
| Modified By:             	    Bruce Chambers
| Date of Modification:         27Jul2013
| New Version/Build Number:     v8 build 1
| Reference:                    BJC007
| Description for Modification: Ensure unique row content for CO domain
| Reason for Modification:      Data often retained in IDSL
|
*******************************************************************************/
%macro tu_sdtmconv_pst_sort_dup_chk(
);

/* BJC001: add  , dr.domref as dom_ref  to the select clause below */
/* BJC003: add SDTMDATA libname to _pst_sdc_unq_keys and _pst_sdc_sort_keys steps below */
/* BJC005: amend SDTMDATA libname to PST_SDTM */
proc sql noprint;
 create table _pst_sdc_unq_keys as 
 select dc.memname , dr.dom_keys, dr.domref as dom_ref, dc.libname
   from dictionary.tables dc,
        domain_ref dr
  where (dc.libname = 'PST_SDTM'
    and (dc.memname in (select domain from sdtm_dom)
         or dc.memname in (select 'SUPP'||trim(domain) from sdtm_dom))  
    and (dc.memname =dr.domain
         or substr(dc.memname,1,4)=dr.domain))
   %if &tab_list eq and &tab_exclude eq and %length(&subset_clause)=0 %then %do;        
     OR
     (dc.libname = 'PST_SDTM'
     and dc.memname =dr.domain
     and memname in ('TA','TE','TI','TS','TV','SE','RELREC')
     and dc.memname in (select domain from sdtm_dom))
   %end;
  ;
    
  select count(distinct memname) into :num_dsets from _pst_sdc_unq_keys;
 
  create table _pst_sdc_sort_keys as 
  select dc.memname , dc.name , dc.libname
    from dictionary.columns dc
   where (dc.libname = 'PST_SDTM'
     and (dc.memname in (select domain from sdtm_dom)
          or dc.memname in (select 'SUPP'||trim(domain) from sdtm_dom))  
     and (name in ('STUDYID','USUBJID','IDVAR','IDVARVAL','QNAM')
         or substr(reverse(trim(name)),1,3)='QES'))
     %if &tab_list eq and &tab_exclude eq and %length(&subset_clause)=0 %then %do;         
      OR
       (dc.libname = 'PST_SDTM'
       and dc.memname in ('TA','TE','TI','TS','TV','SE','RELREC')
       and dc.memname in (select domain from sdtm_dom))
     %end;  
     ;  
quit;

data _pst_sdc_sort_keys; 
 set _pst_sdc_sort_keys;
 if name='STUDYID' then num=1;
 if name='USUBJID' then num=2;
 if substr(reverse(trim(name)),1,3)='QES' then num=3;
 if name='IDVAR' then num=3;
 if name='IDVARVAL' then num=4;
 if name='QNAM' then num=5;
run;

proc sort data =_pst_sdc_sort_keys;
by memname num;
run;

/* datasets created with proc sql dont seem to have _n_ , so create it */
data _pst_sdc_unq_keys; 
 set _pst_sdc_unq_keys;
  num=_n_;
  dom_keys_no_comma=tranwrd(dom_keys,',',' ');
  dom_keys2=compress(dom_keys);
  dom_keys_inlist=tranwrd(dom_keys2,',','","');
  if memname in ("&noseq_dom") then noseq_dom='Y';
  
  /* BJC004 : add step to select correct sort keys based on CRF domain or not. For the domains
     affected the keys are all expected or required and so will always be present. No need to 
     check if the variables are present before using as keys */  
     
  if memname in ('TA','TE','TI','TS','TV','SE','RELREC') then sort_src='_pst_sdc_these_unq_keys';
  else sort_src='_pst_sdc_sort_keys';
run;

/* Create empty template dataset to log issues for later reporting */
data _pst_sdc_dup_dsets;
   attrib memname length=$32;
run;

%if &num_dsets >=1 %then %do;    

 /* Create look up table of correct domain names */
 /* BJC003: add SDTMDATA libname to _pst_sdc_dom_desc step below */
 /* BJC005: amend SDTMDATA libname to PST_SDTM */
 
 proc sql noprint;
    create table _pst_sdc_dom_desc as
    select dc.memname as domain, dr.dom_desc ,dc.libname
      from domain_ref dr,
           dictionary.tables dc
     where (dc.libname='PST_SDTM'      
       and (dr.domain=dc.memname
           or 'SUPP'||trim(dr.domain)=dc.memname))      
      %if &tab_list eq and &tab_exclude eq and %length(&subset_clause)=0 %then %do;           
        OR
        (dc.libname = 'PST_SDTM'
       and dr.domain=dc.memname 
       and dr.domain in ('TA','TE','TI','TS','TV','SE','RELREC')
       and dr.domain in (select domain from sdtm_dom))
       %end;
       ;
 quit;

/* BJC006: add domain to use instead of dom_desc for SUPP labels and amend prefix text */
 data _pst_sdc_dom_desc; 
  set _pst_sdc_dom_desc;
  if domain=:'SUPP' then dom_desc='Supplemental Qualifiers for '||trim(domain);
 run; 
 
 %do i = 1 %to &num_dsets;
     
/* Need to check which of the possible keys are present as they are not all Req items 
/  Also provide a dataset of the key order, so the order can be preserved with a subset of keys */

/* BJC001: add dom_ref to the symputs below */
/* BJC003 - output libname in step below as can be PST_SDTM or SDTMDATA */

  data _pst_sdc_these_unq_keys;
   set _pst_sdc_unq_keys(where=(num=&i)) end=last;
    if last then do;
     call symput('LIBNAME', left(trim(libname)));
     call symput('DSET', left(trim(memname)));
     call symput('dom_ref', left(trim(dom_ref)));
     call symput('noseq_dom', left(trim(noseq_dom)));
     call symput('dom_keys_inlist', left(trim(dom_keys_inlist)));    
     /* BJC004 : add sort source macro variable */
     call symput('sort_src', left(trim(sort_src)));
    end;
    
    posn=index(dom_keys2,','); 
     if posn=0 then output;  
     else if posn >=1 then do;  
       len_all=length(trim(dom_keys2));
       len_comma=length(trim(compress(dom_keys2,',')));
       num_commas=len_all-len_comma;
       tempcd=dom_keys2;
        do num=1 to num_commas+1;	
    	 if num<=num_commas then do;
          name=substr(tempcd,1,index(tempcd,',')-1);	
          tempcd=substr(tempcd,index(tempcd,',')+1,length(trim(tempcd))-index(tempcd,','));
    	  output; 
    	 end;	
    	 
    	 else if num=num_commas+1 then do;
    	  name=tempcd;
          output;
    	 end;	
    	end;	
     end;
   drop len_all len_comma num_commas tempcd posn;    
  run; 
    
  /* Select the correct data into the appropriate macro variables */
  /* BJC003: use libname parameter as can be PST_SDTM or SDTMDATA */
  /*BJC004: For TDx5, SE and RELREC use sort_src to replace _pst_sdc_sort_keys 
            with  _pst_sdc_these_unq_keys to use keys to sort these domains */

  proc sql noprint;
   select dc.name into :present_prim_keys_comma separated by ','
     from dictionary.columns dc,
          _pst_sdc_these_unq_keys tsk
   where dc.memname="&dset"
     and dc.name=tsk.name
     and dc.libname="&libname"
     and dc.name in ("&dom_keys_inlist")
     order by tsk.num;

     
   select dc.name into :present_sort_space separated by ' '
     from dictionary.columns dc , &sort_src tsk         
   where dc.memname="&dset"
     and tsk.memname="&dset"
     and dc.name=tsk.name
     and dc.libname="&libname"
     order by tsk.num;
     
   select dom_desc into :dom_desc
     from _pst_sdc_dom_desc where domain="&dset";
  quit;

  /* Run generic step to re-populate SEQ item for CO domain. SEQ numbers may be duplicate as comments
  /  can come from multiple feeding domains. */
  
  %if &dset=CO %then %do;
  
   /* Use empty shell dataset as template to retain correct column [not sort] ordering of variables*/
   /* BJC007 - rejig COSEQ recalculation to seize change to get distinct row content - where IDSL comments retained over 
       multiple rows, this will now remove such duplicates */
   data co_shell pst_sdtm.CO(drop=COSEQ); 
    set pst_sdtm.CO;
   run; 
   
   proc sort data=pst_sdtm.CO nodupkey;
   by _all_; run;

   proc sort data= pst_sdtm.CO;
     by usubjid;
   run;   
 
   data CO; set pst_sdtm.CO; 
    retain COSEQ 0; by usubjid; 
    if first.usubjid then COSEQ=0;
    COSEQ=COSEQ+1 ;
   run;  
   
   data pst_sdtm.CO; 
      set co_shell(obs=0) CO;
   run; 
    
   %let _cmd = %str (COSEQ re-populated for CO dataset);%tu_sdtmconv_sys_message;  
  %end;
  
  /* Add label descriptor from central metadata store to the dataset */
  /* BJC003: use libname parameter as can be PST_SDTM or SDTMDATA */
  proc datasets library=&libname nolist;
    modify &dset (label="%trim(&dom_desc)");
  run;
  
  /* Perform the sort by the keys that are present */
  /* BJC003: use libname parameter as can be PST_SDTM or SDTMDATA */
  proc sort data= &&libname..&&dset;
   by &present_sort_space;
  run;  
   
  /* Check the data for uniqueness based on the keys that are present */
  /* BJC001: replace domain with dom_ref as the variable prefix below */     
  /* BJC003: use libname parameter as can be PST_SDTM or SDTMDATA, and exclude USUBJID when
     checking TS and use TSPARMCD instead as this is the only domain to have --SEQ but no USUBJID  */

  proc sql noprint;
   create table _pst_sdc_dup_&dset as 
    select &present_prim_keys_comma , count(*) as count
      from &&libname..&&dset
    group by &present_prim_keys_comma
    having count(*) >1;
  
   %if &noseq_dom= %then %do;
    %if %index(&dset,%str(SUPP)) =0 %then %do;

    create table _pst_sdc_seq_dup_&dset as 
     select 
      %if &dset ^=TS %then %do;
       usubjid , 
      %end;
      %if &dset =TS %then %do;
       tsparmcd , 
      %end;
       &dom_ref.seq , count(*) as count
       from &&libname..&&dset
     group by 
      %if &dset ^=TS %then %do;
       usubjid , 
      %end;     
      %if &dset =TS %then %do;
       tsparmcd , 
      %end;
       &dom_ref.seq 
     having count(*) >1;
     
    %end;  
   %end;
   
  quit;
  
  /* Collect one row for each key-issue dataset with duplicate rows to report in later summary */
  
  %if %eval(%tu_nobs(_pst_sdc_dup_&dset))>=1 %then %do;  
   %let _cmd = %str(%str(RTW)ARNING: Duplicate data [by domain keys] in &dset domain);%tu_sdtmconv_sys_message;

   proc print data=_pst_sdc_dup_&dset (obs=30);
    title3 "SDTM conversion: duplicates (by domain keys) for &dset in &g_study_id";
    title4 'Keys for first 30 rows listed as an FYI to help spot the issue/pattern.';
   run;

   /* Create a one row dataset to report later */
   data _pst_sdc_dup_&dset(keep=memname name problem_desc); 
    attrib memname length=$32;
    set _pst_sdc_dup_&dset;
    memname="&dset";
    name='SDTM-KEYS';
    problem_desc='* '||compress(put(%eval(%tu_nobs(_pst_sdc_dup_&dset)),8.))||' Duplicate sets of keys-see earlier listing section';
   run;
   
   proc sort data=_pst_sdc_dup_&dset nodupkey;
   by memname; run;

  %end;
  
  %if &noseq_dom= and %index(&dset,%str(SUPP)) =0 %then %do;
   /* If present -Collect one row for each SEQ issue dataset with duplicate rows to report in later summary */

   %if %eval(%tu_nobs(_pst_sdc_seq_dup_&dset))>=1 %then %do;  
     %let _cmd = %str(%str(RTW)ARNING: Duplicate SEQ values for one or more subjects in &dset domain);%tu_sdtmconv_sys_message;

     proc print data=_pst_sdc_seq_dup_&dset (obs=30);
      title3 "SDTM conversion: duplicate SEQ data for &dset in &g_study_id";
      title4 'Keys for first 30 rows listed as an FYI to help spot the issue/pattern.';
     run;
  
     /* Create a one row dataset to report later */
     data _pst_sdc_seq_dup_&dset(keep=memname name problem_desc); 
      attrib memname length=$32;
      set _pst_sdc_seq_dup_&dset;
      memname="&dset";
      name='SDTM-KEYS';
      problem_desc='* '||compress(put(%eval(%tu_nobs(_pst_sdc_dup_&dset)),8.))||' Duplicate sets of SEQs - see earlier listing section.';
     run;

     /* BJC002 - correct dataset name to ensure removal of duplicates before reporting data */
     proc sort data=_pst_sdc_seq_dup_&dset nodupkey ;
     by memname; run;
      
   %end;
  %end;
    
  /* Collect one row for each dataset with duplicate rows to report in later summary */
  data _pst_sdc_dup_dsets;
   set _pst_sdc_dup_dsets 
       _pst_sdc_dup_&dset
    %if &noseq_dom= and %index(&dset,%str(SUPP)) =0 %then %do;
       _pst_sdc_seq_dup_&dset
    %end;
   ;
  run;     
  
 %end;
%end; 

 /* Create final dataset for reporting so others can be cleaned up */
 data _report_dup_dsets;
  set _pst_sdc_dup_dsets;
 run; 

%if &sysenv=BACK %then %do;  

%tu_tidyup(
 rmdset = _pst_sdc_:,
 glbmac = none
);
%end;

%mend tu_sdtmconv_pst_sort_dup_chk;
