/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pre_seq_add
|
| Macro Version/Build:  5/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009
|
| Macro Purpose:        Redefine any existing SEQ numbers and define SEQ values
|                       for any datasets without SEQ numbers.
| 
|                       Take into account that a given domain may be fed by more
|                       than one dataset. So assign the SEQ for the source
|                       datasets to be unique across those that feed a domain
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
| (@)tu_nobs
| (@)tu_tidyup
| (@)tu_sdtmconv_sys_message
| (@)tu_sdtmconv_sys_error_check 
|
| Example:
|
| %tu_sdtmconv_pre_seq_add
|
|*******************************************************************************
| Change Log:
|
| Modified By:                 Bruce Chambers
| Date of Modification:        11Sep2010
| New Version/Build Number:    2 build 1 
| Reference:                   BJC001
| Description for Modification:Allow for FA domains when assigning next SEQ numbers
| Reason for Modification:     Ensure unique SEQ numbers for all source data feeding a domain
|
| Modified By:                 Ashwin Venkat(va755193)
| Date of Modification:        27Apr2011
| New Version/Build Number:    3 build 1 
| Reference:                   VA001
| Description for Modification:resolved duplicate SEQ numbers issue
| Reason for Modification:   
|
| Modified By:                  Bruce Chambers
| Date of Modification:         13May2011
| New Version/Build Number:     3 build 1 
| Reference:                    BJC002
| Description for Modification: Remove lower seq number query - upcase the main query . 
|                               Remove any CO domain related rows
|                               If a dataset gets SEQ added - update this in the driver table - in case it gets run again
| Reason for Modification:      Changes to simplify code and reduce chance of problems
| 
| Modified By:                  Bruce Chambers
| Date of Modification:         04April2012
| New Version/Build Number:     4 build 1 
| Reference:                    BJC003
| Description for Modification: Replace SUBJID references with USUBJID to ensure uniqueness
| Reason for Modification:      Ensure integrity/uniqueness of data
|  
| Modified By:                  Bruce Chambers
| Date of Modification:         16Aug2012
| New Version/Build Number:     4 build 1 
| Reference:                    BJC004
| Description for Modification: Apply nobs>=1 filter to only process data with rows present
| Reason for Modification:      Empty ones now present for aCRF annotations
|   
| Modified By:                  Bruce Chambers
| Date of Modification:         02JanMay2013
| New Version/Build Number:     5 build 1 
| Reference:                    BJC005
| Description for Modification: Allow for the same dataset being processed more than once. Use the previous SEQ number, 
|                               dont start from 1 again
| Reason for Modification:      Ensure unique SEQ numbers are produced. 
|                               NB: If system is ever redesigned - this should be done much later in PST stage!
|  
*******************************************************************************/
%macro tu_sdtmconv_pre_seq_add(
);

%let _cmd = %str ();%tu_sdtmconv_sys_message;
%let _cmd = %str (Checking for any SEQ items to [re]create for SDTM datasets....);%tu_sdtmconv_sys_message;

** Check if SEQ present in SI data, if it is drop it. 
   Also if SEQ is needed for SDTM then recalculate it. **;
   
proc sql noprint;
 create table _pre_seq_present as 
 (select dc.memname, dc.name
      from dictionary.columns dc, dictionary.tables dt
     where dt.libname='PRE_SDTM'
       and dt.libname=dc.libname
       and dt.memname=dc.memname
       and dt.nobs>=1
       and dc.memname in (select basetabname from view_tab_list)
      and substr(reverse(trim(upcase(dc.name))),1,3)='QES')
   order by dc.memname;  
   
 /* BJC002: remove query for lower_seq_present - upper case the above query instead, and remove CO domain related rows
    from si_domain_link - these are not needed */
   
 create table si_domain_link as 
 (select distinct si_dset as memname, domain
      from varmap
     where si_dset in (select basetabname from view_tab_list)
	   and domain ^='CO'
       and sdtm_var is not null)
   order by si_dset;    
quit;

data si_domain_link;
 attrib memname length=$32;
 set si_domain_link;
run;

/* BJC004: add nobs>=1 to where statement */
data _pre_seq_add;
 length orig_dom $4;
 merge si_domain_link(in=b)
       view_tab_list(where=(nobs>=1 or libname='') in=a rename=(basetabname=memname))
       _pre_seq_present(in=c);
 by memname;
 if a and b and memname ^='DEMO';
 /* BJC001: add if/end step to process FA domains */
 if substr(domain,1,2)='FA' then do;
  orig_dom=domain;
  domain=substr(domain,3,2);
 end;
run;

proc sort data=_pre_seq_add;
by domain memname;
run;
/*VA001: resolve duplicate SEQ */
/* BJC001: add line to remove FA domain rows where the parent domain is from the same source dataset 
/  and resort data to reset first/last variables */
data _pre_seq_add; 
 set _pre_seq_add;
  by domain memname;
  if orig_dom ^='' and last.memname=0 then delete;
run;

proc sort data=_pre_seq_add;
by domain memname;
run;

data _pre_seq_add; 
 set _pre_seq_add;
 by domain memname;
 retain DOMSEQ 0;  
   
  if first.domain then DOMSEQ=0;
  DOMSEQ=DOMSEQ+1 ;
  ** If a domain is fed by more than one dataset then flag this and later *;
  ** Use this to ensure we get unique SEQs nos in all datasets feeding a domain**;
  if first.domain+last.domain^=2 then mult_doms=1;
  else mult_doms=0;
  /* BJC005 : remove references to domseq_more - use "if domseq>=2" instead for clarity */
run;  

proc sort data=_pre_seq_add ;
by memname domain domseq  ;
run;

/* Some datasets get sorted twice with this code - but will get the max seq numbers set */
 
data _pre_seq_add; 
 set _pre_seq_add;
 
 /* BJC005: add last_max_seq to keep track of SEQ number assignments - default to 0 */
 length last_max_seq 8.;
 last_max_seq = 0;
 
 by memname domain domseq;
  /* BJC005: Correct next line to only drop and recreate SEQ once (first time)  per dataset */
  if not first.memname then name ='';
run; 

proc sort data=_pre_seq_add ;
by domain memname domseq  ;
run;

/* remove old check for lower case SEQ field - for some data this was a different data field i.e. not a SEq number */

/* BJC005: initial next_seq to 0 */
%let next_seq=0;

** Count the number of datasets (if any) to process **;
%if %eval(%tu_nobs(_pre_seq_add))>=1 %then %do;

 data _pre_seq_add; set _pre_seq_add;
 num=_n_;run;

 %DO w=1 %TO %eval(%tu_nobs(_pre_seq_add));

  ** For each iteration - output the dataset name and SEQ item name **;  
  data _null_ ;set _pre_seq_add (where=(num=&w));
   call symput('memname',trim(memname));
   call symput('name',trim(name));
   call symput('domseq',trim(domseq));
   /* BJC003 : remove references to domseq_more - use "if domseq>=2" instead for clarity */
   call symput('mult_doms',trim(mult_doms));
   /* BJC003: add last_max_seq macro variables to enable later sql update statement */
   call symput('last_max_seq',trim(last_max_seq));
  run;

/* BJC003: replace subjid with USUBJID in steps below */
  proc sort data=pre_sdtm.&memname; 
  by usubjid;run;  

  /* BJC005: add check for scenario that may cause SEQ integrity issues - a recalculation may be triggered later
     but if existing rows have SUPP qualifiers using SEQ to link then this may pose a problem */
	 
  %if &next_seq >=1 and &last_max_seq >=1 and (&last_max_seq < &next_seq) %then %do;
    %let _cmd = %str (RTNOTE: Ensure SEQ uniqueness for domains fed by &memname data);%tu_sdtmconv_sys_message;
	%let _cmd = %str (Run OPENCDISC checks and report any issues to developers);%tu_sdtmconv_sys_message;
  %end;
  
  /* BJC005 : dont re-assign SEQ values if already done before */
  %if &last_max_seq=0 %then %do;
  
   ** Run generic step to create and populate SEQ item **;
   data pre_sdtm.&memname;
    set pre_sdtm.&memname
    %if &name^= %then %do;
     (drop=&name)
    %end;
    ; 
   retain SEQ              
             /* BJC005 : remove references to domseq_more - use "if domseq>=2" instead for clarity */
             %if &domseq>=2 %then %do;
                &next_seq
             %end;
             %else %do;
                &domseq
             %end;
  ; by usubjid; 
   if first.usubjid then SEQ=
             /* BJC005 : remove references to domseq_more - use "if domseq>=2" instead for clarity */
             %if &domseq>=2 %then %do;
                &next_seq
             %end;
             %else %do;
                &domseq
             %end;
                           ;
   if not first.usubjid then SEQ=SEQ+1 ;
   run;  

   /* BJC002 - if a dataset does get processed more than once - update the driver data so that the 
     the previous SEQ number will get dropped and recreated */
   proc sql;
    update _pre_seq_add set name='SEQ' where memname ="&memname";
   quit; 
  
  %end; /* End for BJC005 IF clause addition */
  
  %if &mult_doms=1 %then %do;
   proc sql noprint;
      
    select max(seq)+1
      into :next_seq
      from pre_sdtm.&memname;
	  
	/* BJC005 - update driver table with max seq number reached. DONT use 'and domain="&domain"' so that all rows for 
	   source dataset get updated if used in multiple domains */
    update _pre_seq_add set last_max_seq=&next_seq where memname ="&memname" ;  
	  
   quit;   
  %end;

  %tu_sdtmconv_sys_error_check;

  %let _cmd = %str (&name [re]created and populated for &memname dataset);%tu_sdtmconv_sys_message;
  /* BJC005 : remove references to domseq_more - use "if domseq>=2" instead for clarity */
  %if &domseq >=2 %then %do;
   %let _cmd = %str (Ensuring SEQ uniqueness within domains fed by this data);%tu_sdtmconv_sys_message;
  %end;
 %end;
%end;

%if &sysenv=BACK %then %do;  

%tu_tidyup(
 rmdset = _pre_seq_:,
 glbmac = none
);
%end;

%mend tu_sdtmconv_pre_seq_add;
