/******************************************************************************* 
|
| Macro Name: tu_sdtmconv_mid_append_irp
|
| Macro Version/Build: 7 build 1
|
| SAS Version: SAS 9.1.3
|
| Created By: Bruce Chambers
|
| Date:            12-Aug-2009
|
| Macro Purpose: Macro to transpose data to a common normalised format   
|                based on SI keys, merge with study_t to create an all   
|                study data Item Result Pair master dataset
|
| Macro Design:  Procedure
|
| Input Parameters:
|
| NAME              DESCRIPTION                         DEFAULT 
| DS                Source dataset name                 N/A
|
| Output: Source data transposed by default keys is appended to mid_sdtm.study_t
|         dataset.      
|
| Global macro variables created:
|
|
| Macros called:
| (@) tu_tidyup
| (@) tu_varattr
| (@) tu_nobs
|
| Example:
|         %tu_sdtmconv_mid_append_irp(RUCAM);
|
|******************************************************************************* 
| Change Log 
|
| Modified By:                  Bruce Chambers
| Date of Modification:         13aug2010
| New Version/Build Number:     2/1
| Reference :                   bjc001
| Description for Modification: Update source item label (instead of current variable name) into COREF
| Reason for Modification:      Make data more suitable for reviewer - the decode/label is more meaningful
|
| Modified By:                  Bruce Chambers
| Date of Modification:         22Nov2010
| New Version/Build Number:     3/1
| Reference :                   bjc002
| Description for Modification: Create multiple study_t datasets with n suffix
| Reason for Modification:      For efficiency and speed of processing - especially for larger volume studies
|
| Modified By:                  Bruce Chambers
| Date of Modification:         09Feb2011
| New Version/Build Number:     3/1
| Reference :                   bjc003
| Description for Modification: Add USUBJID to list of common keys, and remove SUBJID (only kept for IDSL DEMO)
| Reason for Modification:      Now we have pre_adjust_usubjid we will always have USUBJID as a variable
|
| Modified By:                  Bruce Chambers
| Date of Modification:         25Oct2012
| New Version/Build Number:     4/1
| Reference :                   bjc004
| Description for Modification: Allow for VISITNUM as well as SEQ as a CO domain link item that is also a key
|                               for transposed mid conversion datasets. Other items that are not transpose keys
|                               such as EGGRPID need adding to transpose keys for later adding into CO domain.
|                               Its just SEQ and VISITNUM that are transpose KEYS, other CO keys need allowing for.
| Reason for Modification:      Allow more CO domain link scenarios than just --SEQ.
|
| Modified By:                  Bruce Chambers
| Date of Modification:         25Jan2013
| New Version/Build Number:     5/1
| Reference :                   bjc005
| Description for Modification: May have scenario where a dataset has mappings that dont apply to study.
| Reason for Modification:      Improve Error handling to explain issue to user and continue processing.
|
| Modified By:                  Bruce Chambers
| Date of Modification:         11Jul2013
| New Version/Build Number:     6/1
| Reference :                   bjc006
| Description for Modification: Amend ORIGIN=DERIVED to ASSIGNED for several CO items
| Reason for Modification:      Correct define.xml metadata
|
| Modified By:                  Bruce Chambers
| Date of Modification:         27Jul2013
| New Version/Build Number:     7/1
| Reference :                   bjc007
| Description for Modification: Amend CO domain processing to allow >1 bundle of comment variables per SI dataset
| Reason for Modification:      Correct CO domain data
|
********************************************************************************/ 

%macro tu_sdtmconv_mid_append_irp(
                                  ds   /* Source dataset name */
                                  );

/* the list of keys is a master set - the actual data processed may have less of the keys
/   so the next few steps pick out the keys actually present in the data from the master list */

/*BJC003: replace SUBJID with USUBJID in list of keys */
data _mid_dskey_master;
  length dskey $35 dskey2 $42;
  dskey="STUDYID USUBJID VISIT VISITNUM SEQ";
  dskey2=tranwrd(dskey,' ','","');
  call symput ('dskey2',trim(dskey2));
run;

/* Put out the master list of keys one per row in the order specified with a num counter */
data _mid_dskey_master1; 
 set _mid_dskey_master(drop=dskey2) end=last;
    posn=index(dskey,' '); 
     if posn=0 then output;  
     else if posn >=1 then do;  
       len_all=length(trim(dskey));
       len_space=length(trim(compress(dskey,' ')));
       num_spaces=len_all-len_space;
       tempcd=dskey;
        do num=1 to num_spaces+1;	
    	 if num<=num_spaces then do;
          dskey=substr(tempcd,1,index(tempcd,' ')-1);	
          tempcd=substr(tempcd,index(tempcd,' ')+1,length(trim(tempcd))-index(tempcd,' '));
    	  output; 
    	 end;	
    	 
    	 else if num=num_spaces+1 then do;
    	  dskey=tempcd;
          output;
    	 end;	
    	end;	
     end;
   drop len_all len_space num_spaces tempcd posn;
run;

proc sql noprint;
  create table _mid_current_keys as 
  select name
    from dictionary.columns
   where libname='PRE_SDTM'
     and memname="&ds"
     and upper(name) in ("&dskey2");
 
  select c.name into :dskey_present separated by ' '
    from _mid_current_keys c, _mid_dskey_master1 m
   where upper(c.name)=m.dskey
   order by m.num;
  
   select distinct si_var, origin 
         into 
         :cur_cat_item , :origin
     from  varmap 
    where si_dset="&ds"
      and substr(reverse(trim(sdtm_var)),1,3)='TAC'
      and length(sdtm_var) in (5,7)
      order by origin;  
quit; 

/* Now we have a list of keys present in the correct order, proceed with processing the data */

proc sort data=pre_sdtm.&ds out=mid_sdtm.flip_&ds;
  by &dskey_present;
run;

/* BJC004: specific addition for CO domain to ID keys other than --SEQ and VISITNUM */
%let co_link=;
proc sql noprint;
 select distinct substr(suppqual,7,length(suppqual)-6) into :CO_LINK
   from varmap 
  where domain='CO' 
    and si_dset="&ds"	
    and substr(suppqual,7,length(suppqual)-6) ^='VISITNUM'
    and substr(reverse(substr(suppqual,7,length(suppqual)-6)),1,3)^='QES'
	and substr(suppqual,1,6)="IDVAR=";
quit;	  

/* BJC004: specific addition for CO domain to add transpose keys other than --SEQ and VISITNUM */
proc transpose data=mid_sdtm.flip_&ds out=mid_sdtm.&ds._t;
    by &dskey_present &CO_LINK;
	var _all_;
run;

/* Left justify numeric data otherise it gets lost after the tranpose 
   Also upper case any lower case SI var names (_name_) otherwise the data wont merge */
/*BJC003: replace SUBJID with USUBJID in list of keys */

data mid_sdtm.&ds._t; 
 set mid_sdtm.&ds._t(where=( left(trim(col1))^= '' and upcase(_name_) not in
                     ('STUDYID','USUBJID','VISITNUM','VISIT','SEQ')));** delete any blank obs **;
     if _name_ ='' then delete;
     col1=left(trim(col1));   
     _name_=upcase(_name_);     
     si_dset=upcase("&ds");
run;     

/* BJC005 : add error handling step here */
%if %eval(%tu_nobs(mid_sdtm.&ds._t))=0 %then %do;
   %let _cmd = %str(%STR(RTE)RROR: Aborting for &DS : No mapped data to process for this study - augment mapping set.);%tu_sdtmconv_sys_message;
   %goto endloop;
%end;

/* See if any of the SI data needs to go to the comments (CO) DOMAIN and add extra records to facilitate this */
/* bjc001: Refine the query to ID comment variables to only process vars present, not potential ones for a dataset */
/* bjc004: Pick first 7 chars of si_var for uniqeness for EGERCOM1/2/3 etc - and rename num_cmts to com_prefix for 
           this step to aid clarity. */

proc sql noprint;
  select count(distinct substr(si_var,1,7)) into :com_prefix 
    from varmap vm, dictionary.columns dc
   where substr(vm.suppqual,1,5)='IDVAR'
     and vm.si_dset="&ds"
     and dc.memname=vm.si_dset
     and dc.libname='PRE_SDTM'
     and dc.name=vm.si_var
   order by substr(si_var,1,7);
   
   create table co_vars as 
    select distinct si_var,
	       substr(si_var,1,7)as prefix, 
           substr(vm.suppqual,7,length(vm.suppqual)-6) as supp_id     
      from varmap vm, dictionary.columns dc
     where substr(vm.suppqual,1,5)='IDVAR'
       and vm.si_dset="&ds"
       and dc.memname=vm.si_dset
       and dc.libname='PRE_SDTM'
       and dc.name=vm.si_var;   
quit;

/* BJC007 : for comments we need to identify if they are standalone/single ones or if they are a bundle where the 
             convention that the stem is length of 7 applies */
proc sort data=co_vars;
by  prefix si_var;
run;

data co_vars; 
  attrib prefix length=$8.;
 set co_vars;
  by prefix si_var;
  if first.prefix+last.prefix=2 then do;
    prefix=si_var;
  end;
run;
 
%if &com_prefix>=1 %then %do;
 /* BJC006: Amend all the ORIGIN entries for CO data to ASSIGNED (instead of DERIVED) */
 /* Add rows to VARMAP to map the comments data fields */
 data varmap_cmt1;
   si_dset="&ds";
   si_var='IDVAR';
   origin='ASSIGNED';
   domain='CO';
   sdtm_var='IDVAR';
   SUPPQUAL='NO';
   ADDED='Y';
  run;
  
 data varmap_cmt2;
   si_dset="&ds";
   si_var='IDVARVAL';
   origin='ASSIGNED';
   domain='CO';
   sdtm_var='IDVARVAL';
   SUPPQUAL='NO';
   ADDED='Y';   
 run; 
 
 data varmap_cmt3;
    si_dset="&ds";
    si_var='RDOMAIN';
    origin='ASSIGNED';
    domain='CO';
    sdtm_var='RDOMAIN';
    SUPPQUAL='NO';
    ADDED='Y';
 run; 

 data varmap_cmt4;
      si_dset="&ds";
      si_var='COREF';
      origin='ASSIGNED';
      domain='CO';
      sdtm_var='COREF';
      SUPPQUAL='NO';
      ADDED='Y';
   run; 
  
 data varmap;
  set varmap 
      varmap_cmt1
      varmap_cmt2
      varmap_cmt3
      varmap_cmt4;
 run; 

 /* Get list of comments items to be processed for this dataset - there can be more than one per dataset */
 /* bjc001: Refine the query to identify comment variables to only process vars present, not potential ones for a dataset */
 /* BJC004: use extra macro var for substring prefix first 7 chars for multiples e.g. EGERRCOM1/2/3 */
 /* BJC007: amend SQL to fetch same number of rows as there are substr1-7 comment field names in com_prefix macro var 
            SI_PVAR macro var is the 1-7char prefix e.g. for EGERCOM,1,2 it will be EGERCOM */
 
 proc sql noprint;
    select distinct 
	       prefix, 
           supp_id
      into 	       
           :si_pvar1 - :si_pvar%left(&com_prefix) , 
           :id_var1 - :id_var%left(&com_prefix) 
      from co_vars;
       
    select domain
      into :dom1    - :dom%left(&com_prefix)
      from varmap 
     where si_dset="&ds" 
       and domain^='CO' 
       and substr(domain,1,2)^='CO' 
       and substr(suppqual,1,5)^='IDVAR' 
       and si_var^=substr(suppqual,7,length(suppqual)-6);       
 quit; 

 proc sql noprint;
   select max(seq) into :max_seq from mid_sdtm.flip_&ds;
 quit; 

 /* Add indexes to make updates perform better 
 proc sql noprint;
    create index usubjid on mid_sdtm.&ds._t;   
 quit;

 /* For each comment variable in the source dataset - loop through steps below */
 %do a=1 %to &com_prefix;
     
  /* the link variable definition is the source (IDSL) var. However, in the domain, the variable may be
     renamed, so we may need to update a different SDTM variable into the records. e.g. PCSPMID is the link 
     variable for PCNUM and PCNUMCOM. However PCSMPID is renamed to PCGRPID during conversion */
   %let sdtm_link_var=;
   
   proc sql noprint;
    select distinct sdtm_var into :sdtm_link_var
      from varmap 
     where si_dset="&ds"
       and si_var="&&id_var&a";
   quit;
   %if &sqlobs=0 %then %do;
    /* BJC007: use si_pvar instead of si_var */
    %let sdtm_link_var=&&si_pvar&a;
   %end; 
 
   /* For each comment variable - add extra rows to the IRP normalised structure to contain the comments.
     Also try to ensure unique SEQ values across the CO domain. */
	 
   data mid_sdtm.&ds._t ;
    set mid_sdtm.&ds._t;
    output;
	/* BJC007: use si_pvar instead of si_var */
    if _name_="&&si_pvar&a" and col1^='' then do;
      _name_ ="IDVAR";
      _label_="&&si_pvar&a";      
      col1="&&id_var&a";      
      seq = (&max_seq * (&a - 1)) + seq;
     output;
     
      _name_ ="IDVARVAL";
      _label_="&sdtm_link_var";
      col1='';
     output;

      _name_ ="RDOMAIN";
      _label_="RDOMAIN";
      col1="&&dom&a";
     output;

      _name_ ="COREF";
      _label_="COREF";
      
      /* BJC001 : Populate the linking item (COREF) variable label instead of the variable name for reviewer clarity */ 
      /* BJC007: use si_pvar instead of si_var */	  
      col1="%tu_varattr(pre_sdtm.&ds, &&si_pvar&a, varlabel)";      
     output;

    end;
   run; 
   
   /* Take a copy of the data and use this as a reference for the next update statements */
   data _mid_temp&ds; 
    set mid_sdtm.&ds._t;
   run;

   /* If a SEQ is used as an IDVAR then as a key we need to pull this from its own column 
      as SEQ is not an item result pair */
 	  
   %if %substr(%sysfunc(reverse(%trim(&&id_var&a))),1,3)=QES %then %do;
     %let col1=%bquote(put%str(%()SEQ,8.%str(%)));
   %end;
   /* BJC004 - allow for VISITNUM as well as SEQ being a transpose key and a CO domain link item */
   %else %if &&id_var&a=VISITNUM %then %do;
     %let col1=%bquote(put%str(%()VISITNUM,7.2%str(%)));
   %end;   
   %else %let col1=COL1;

   /* Add indexes to make updates perform better  */
   /* BJC003: replace subjid with usubjid in steps below */
   
   proc sql noprint;
    create index usubjid on _mid_temp&ds;
   quit;

   proc sql;
    update mid_sdtm.&ds._t a set col1=(select distinct left(%unquote(&col1))
    from _mid_temp&ds b
    where a.usubjid=b.usubjid and a.seq = (&max_seq * (&a - 1)) + b.seq

      %if %str(&col1) = %str(COL1)  %then %do;
        and _name_="&&id_var&a"
      %end;
    )
    where _name_='IDVARVAL' and _label_="&sdtm_link_var" and col1 is null;
   
    update mid_sdtm.&ds._t a set seq=(select distinct seq
      from _mid_temp&ds b
    where a.usubjid=b.usubjid and b.seq = (&max_seq * (&a - 1)) + a.seq

       %if %str(&col1) = %str(COL1)  %then %do;
         and _name_='IDVAR'
       %end;            
      )
	/* BJC004: use substr 7 chars of si_var for the update */  
	/* BJC007: use si_pvar instead of si_var */
    where substr(_name_,1,7)="&&si_pvar&a" and col1 is not null;  
    
    /* Where a link variable is renamed in the conversion - update the data value to the new name */
	/* BJC007: use si_pvar instead of si_var */
    %if &&si_pvar&a ne &sdtm_link_var %then %do;
     update mid_sdtm.&ds._t a set col1=("&sdtm_link_var") 
                                         where _label_="&&si_pvar&a" 
                                           and _name_='IDVAR';    
    %end;
    
   quit; 
  
   %if &sysenv=BACK %then %do;  
  
    /* tidy up a potential large non-work datasets if not in interactive mode */
  
    proc datasets memtype=data library=work nolist;
                  delete _mid_temp&ds;
    run;
   %end;
  
  %end;
 
%end;
 
/* Append this dataset to the master study_t dataset */
/* BJC002: keep the dataset as small as possible - monitor and reset size of COL1 variable */

%local cur_t_len cur_t_len tnobs new_nobs col1_size;
%let cur_t_len=0;
%let new_len=0;
%let new_nobs=0;
%let tnobs=0;

proc sql noprint;
  select length into :cur_t_len 
  from dictionary.columns 
  where libname="MID_SDTM" and memname="STUDY_T&num_mid" and name="COL1";
   
  select max(length(col1)) into :new_len 
  from mid_sdtm.&ds._t;  

  select nobs into :tnobs
  from dictionary.tables 
  where libname="MID_SDTM" and memname="STUDY_T&num_mid" ;  
  
  select nobs into :new_nobs
  from dictionary.tables 
  where libname="MID_SDTM" and memname="&ds._T" ;    
quit; 
 
/* If its the first iteration and STUDY_t is empty then set the size to whatever is needed 
   If its after the first iteration and STUDY_T has rows, then increase the size as needed */
 
%if &tnobs=0 %then %let col1_size=&new_len;
%else %if &new_len>=&cur_t_len %then %let col1_size=&new_len;
%else %if &new_len<&cur_t_len %then %let col1_size=&cur_t_len;

/* Set obs limit at 500000 rows. If the dataset is in excess of this, or the next dataset to be processed 
   is large then trigger the creation of a new intermediate holding dataset for the normalised data.
   If starting a new study_t dataset then increment counter and set correct length for COL1 */
   
%if %eval(&z) ne 1 and (&tnobs>=500000 or &new_nobs >=500000) %then %do;

  %let num_mid=%eval(&num_mid+1);
  %let col1_size=&new_len;
  
  /* Create empty template for the next one */
  data mid_sdtm.study_t&num_mid;
   set mid_sdtm.study_t%eval(&num_mid-1);
   if _n_>0 then stop;
  run;  
%end;
  
data mid_sdtm.study_t&num_mid;
  attrib col1 length = $&col1_size ;
  set mid_sdtm.study_t&num_mid
      mid_sdtm.&ds._t;
run;

/* End of changes for BJC002 */

/* BJC005 : jump point for error handling step */
%endloop:

%if &sysenv=BACK and %symexist(__utc_workpath) eq 0 %then %do;  

/* tidy up two large non-work datasets if not in interactive mode */

proc datasets memtype=data library=mid_sdtm nolist;
                delete &ds._t flip_&ds;
run;

%tu_tidyup(
rmdset = _mid_&ds:,
glbmac = none
);

%tu_tidyup(
rmdset = varmap_cmt:,
glbmac = none
);

%end;

%mend tu_sdtmconv_mid_append_irp;
