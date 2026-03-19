/******************************************************************************* 
|
| Macro Name: tu_sdtmconv_mid_append
|
| Macro Version/Build: 12/1
|
| SAS Version: SAS 9.1.3
|
| Created By: Bruce Chambers
|
| Date:            12-Aug-2009
|
| Macro Purpose: Macro to take the individual sub-domain datasets and append them
|                where multiples are present, or rename where only one present.
|
|                For SUPP-- Findings domains, update ID values from the parent domain data
|
| Macro Design:  Procedure
|
| Input Parameters:
|
| none
|
| Output:
|
|
| Global macro variables created:
|
|
| Macros called:
| (@) tu_chkvarsexist
| (@) tu_nobs
| (@) tu_sdtmconv_mid_seq
| (@) tu_sdtmconv_sys_error_check
| (@) tu_sdtmconv_sys_message
| (@) tu_tidyup
|
| Example:
|         %tu_sdtmconv_mid_append;
|
|******************************************************************************* 
| Modified By:             	Bruce Chambers
| Date of Modification:         07Apr2010
| New Version/Build Number:     v2 build 1
| Reference:                    BJC001
| Description for Modification: Update references to variable prefix to use DOMREF
|                               instead of DOMAIN e.g. FA instead of FAMH so that
|                               variables referenced are FASEQ and not FAMHSEQ.
| Reason for Modification: 	Need to use FA instead of FAMH so that variables 
|                               referenced are FASEQ and not FAMHSEQ.
|
| Modified By:                  Bruce Chambers
| Date of Modification:         28april2010
| New Version/Build Number:     v3 build 1
| Reference:                    BJC002
| Description for Modification: Include --STAT and --REASND fields in check for existing fields
| Reason for Modification:      When processing findings data, if an -ORRES field is null then the
|                               row will be removed. however, we need to check if --STAT or --REASND 
|                               have data before deleting any rows.
|
| Modified By:                  Bruce Chambers
| Date of Modification:         04august2010
| New Version/Build Number:     v4 build 1
| Reference:                    BJC003
| Description for Modification: Implement --TESTCD="--ALL" for groups of tests that are missing. 
|                               See Section 4.1.5.1.2 of the 312 IG for full details.
| Reason for Modification:      To flag where no tests were present for a group of data and to prevent
|                               orphan SUPP records being present.e.g. EGDTC present with no EG TESTS present
|                               but EGMTCL (SUPPQUAL) present for that row.
|                               
| Modified By:                  Bruce Chambers
| Date of Modification:         04august2010
| New Version/Build Number:     v4 build 1
| Reference:                    BJC004
| Description for Modification: Define VISITNUM correctly for SUPPQUAL joins
| Reason for Modification:      To ensure the VISITNUM in parent domain matches any VISITNUM as IDVARVAL
|
| Modified By:                  Bruce Chambers
| Date of Modification:         04august2010
| New Version/Build Number:     v4 build 1
| Reference:                    BJC005
| Description for Modification: Add check for orphan SEQ rows
| Reason for Modification:      To ensure all SEQ values in SUPP are in parent domain - creation of TESTCD=--ALL
|                               may leave orphan SUPP rows that are not easily noticed.
|
| Modified By:                  Bruce Chambers
| Date of Modification:         12October2010
| New Version/Build Number:     v5 build 1
| Reference:                    BJC006
| Description for Modification: Add --LINKID, --EVAL(ID) to list of items checked when creating --TESTCD=--ALL rows
| Reason for Modification:      To ensure TESTCD=--ALL rows create correctly for Oncology tumour domains that use
|                               the extra items not (yet) in the SDTM model.
|
| Modified By:                  Bruce Chambers
| Date of Modification:         22November2010
| New Version/Build Number:     v6 build 1
| Reference:                    BJC007
| Description for Modification: Remove si_dset from order_by statement
| Reason for Modification:      The efficiency rework means this si_dset is no longer needed
|
| Modified By:                  Bruce Chambers
| Date of Modification:         22November2010
| New Version/Build Number:     v6 build 1
| Reference:                    BJC008
| Description for Modification: Move check for orphan SEQ rows - it is in wrong place and reports non issues
| Reason for Modification:      To ensure all SEQ values in SUPP are in parent domain - creation of TESTCD=--ALL
|                               may leave orphan SUPP rows that are not easily noticed.
|
| Modified By:                  Bruce Chambers
| Date of Modification:         19January2011
| New Version/Build Number:     v6 build 1
| Reference:                    BJC009
| Description for Modification: Enable definition/population of QEVAL in SUPP domains from MSA varmap data
| Reason for Modification:      Populate all SDTM variables that we are able to
|
| Modified By:                  Bruce Chambers
| Date of Modification:         24January2011
| New Version/Build Number:     v6 build 1
| Reference:                    BJC010
| Description for Modification: Add SDTM_VAR to distinct statement
| Reason for Modification:      Enable multiple link items to be processed. (Deficiency uncovered during testing).
|
| Modified By:                  Bruce Chambers
| Date of Modification:         08February2011
| New Version/Build Number:     v6 build 1
| Reference:                    BJC011
| Description for Modification: Remove drop subjid variables and references to SUBJID - no longer needed
| Reason for Modification:      Introduction of pre_adjust_usubjid streamlines all this
|
| Modified By:                  Deepak Sriramulu		
| Date of Modification:         20April2011
| New Version/Build Number:     v7 build 1
| Reference:                    DSS001
| Description for Modification: Create a template dataset with all the maximum lengths of the variables
| Reason for Modification:      The values of --REASND and --DTC were getting truncated. 
|   							This was happening when we append data from multiple SI datasets into one SDTM domain.
|
| Modified By:                  Bruce Chambers		
| Date of Modification:         13May2011
| New Version/Build Number:     v7 build 1
| Reference:                    BJC012
| Description for Modification: When IDVAR=SEQ for Fa domain assign with &dom_ref(FA) not &dom (FAXX) to make FASEQ, not FAXXSEQ
| Reason for Modification:      IDVAR was incorrectly populating with FAXXSEQ - must be FASEQ
|
| Modified By:                  Deepak Sriramulu
| Date of Modification:         01Aug2011
| New Version/Build Number:     v8 build 1
| Reference:                    DSS002
| Description for Modification: Modify the SQL code which checkes for rows with --TESTCD='<domain>ALL' and associated values
|								where a whole set of tests are missing for any possible set of timepoints 
| Reason for Modification:      Performance improvement to run on large studies.
|
| Modified By:                  Ashwin Venkat		
| Date of Modification:         5Aug2011
| New Version/Build Number:     v8 build 1
| Reference:                    AV001
| Description for Modification: put RTNOTE containing Keys used for creating --TESTCD= '<domain>ALL'
| Reason for Modification:      this note will be useful detail to know if investigating/debugging
|
| Modified By:                  Bruce Chambers		
| Date of Modification:         25Sep2012
| New Version/Build Number:     V9 build 1
| Reference:                    BJC013
| Description for Modification: allow for PC domain to be partial i.e. no tests, just dates and IDs
| Reason for Modification:      Conversion from SI PK instead of A&R PKCNC, set PCTESTCD to be $5 for 'PCALL' value
|
| Modified By:                  Bruce Chambers		
| Date of Modification:         15Jan2013
| New Version/Build Number:     V10 build 1
| Reference:                    BJC014
| Description for Modification: Null VISIT(NUM)s for EOS/End of Study records
| Reason for Modification:      These are not real visits (per protocol), just a collection of screens.
|
| Modified By:                  Bruce Chambers		
| Date of Modification:         05Feb2013
| New Version/Build Number:     V10 build 1
| Reference:                    BJC015
| Description for Modification: Make --TESTCD='--ALL' creation ignore any keys used for CO IDVAR population
|                               Also remove some keys from query for --ALL creation
| Reason for Modification:      Ensure appropriate creation of --TESTCD='--ALL'.
|
| Modified By:                  Ashwin Venkat		
| Date of Modification:         03May2013
| New Version/Build Number:     V11 build 1
| Reference:                    AV002
| Description for Modification: Add back in --CAT and --SCAT keys for query in --ALL creation
| Reason for Modification:      Ensure appropriate creation of --TESTCD='--ALL'.
|
| Modified By:                  Bruce Chambers		
| Date of Modification:         02May2013
| New Version/Build Number:     V11 
| Reference:                    BJC017
| Description for Modification: Enable USUBJID as a SUPP linking var e.g. VAS average scores
| Reason for Modification:      Flexibility in SUPP linking
|
| Modified By:                  Bruce Chambers		
| Date of Modification:         22May2013
| New Version/Build Number:     V11 
| Reference:                    BJC018
| Description for Modification: Replace this_ds reference with &&dom&m to get correct domain
| Reason for Modification:      This had been wrong all along but never failed until recent code updates - not sure why !
|
| Modified By:                  Bruce Chambers		
| Date of Modification:         22Jul2013
| New Version/Build Number:     V12 
| Reference:                    BJC019
| Description for Modification: Add one more macro param to SUPP metadata to ensure correct product
| Reason for Modification:      Fix where there are >1 SUPPQUAL=YES[SEQ]<TEST_CODE> definitions across feeder data groups
|
| Modified By:                  Bruce Chambers		
| Date of Modification:         12Sep2013
| New Version/Build Number:     V12 
| Reference:                    BJC020
| Description for Modification: Allow for --REASND to already be defined when creating --TESTCD=--ALL rows to explain absence
| Reason for Modification:      Example of this is to process BIOLINK data
|
********************************************************************************/ 

%macro tu_sdtmconv_mid_append(
);

/* BJC011 - remove code to drop SUBJID - now redundant */

/* Append any component domains e.g DIARY_QS and RUCAM_QS to QS
    some domains have >1 feeder SI, so have Multiple Feeds (MF)    */

/* Identify which domains have multiple populated feeder datasets. */

data sdtm_dom; set sdtm_dom;
 by domain seqvar;
 
 /* flag domains with multiple SI feeding datasets */
 retain mult_feeds 0;
 
 if first.domain+last.domain=2 then mult_feeds=0;
 else if first.domain and not last.domain then mult_feeds=1;
 else mult_feeds=mult_feeds+1;
 
 if last.domain then last='Y';
 
run;

proc sql noprint;
 select count(*) into :dsobs from sdtm_dom;
quit;

/* BJC007: remove si_dset from order_by statement - the efficiency rework means this is no longer needed */
proc sql noprint;
  select distinct domain, si_dset, mult_feeds, last
    into :dom1- :dom%left(&dsobs),
         :dset1- :dset%left(&dsobs),
         :mf1- :mf%left(&dsobs),
         :last1- :last%left(&dsobs) 
    from sdtm_dom    
    order by domain, mult_feeds;
quit;   
/* Start of code added by DSS001 */
/* Create dataset with variable's max length as first obs record   */
/*******************************************************************/
data concat;
   set sdtm_dom;     
   if si_dset ne 'SUPP' then do; memname = strip(domain)||"_"||strip(si_dset); output; end;   
run;
   
proc sql noprint;
      create table dsList as
      select name, type, length, scan(memname,1,'_') as dsname, memname as form_name
         from dictionary.columns
         where libname = 'MID_SDTM' and
               upcase(type)='CHAR' and
               memtype = 'DATA' and
               memname in (select memname from concat)
      order by dsname,name,length desc;
   quit;
   
 /* (DSS001)
 /  Create a dataset that contains any variable with varying
 /  lengths less than the maximum length for that variable
 /***************************************************************/
   data diff_var_lengths;
      set dslist;
      by dsname name;
      retain max_length;
      if first.name then 
         max_length = length;
      else 
         if length ne max_length then output;
   run;
  
 /* (DSS001)
 /  Remove any duplicate rows from dataset for next data step
 /***************************************************************/
   proc sort data=diff_var_lengths out=max_diff_var_length nodupkey;
      by dsname name;
   run;

   /* (DSS001)
   /  Build a macro variable to contain list of dataset names
   /***************************************************************/
   proc sql noprint;
      select dsname, name into :_dsname separated by ' ', :_name separated by ' '
      from max_diff_var_length;
   quit;
   %let _total_obs = &sqlobs;
   %let this_ds = %str();
  
  /* Check if there are any datasets with differing lengths */
  %if &sqlobs gt 0 %then %do;
  
  %do _ndx = 1 %to &_total_obs;
      %let _cmd = %str( );
      %if &_ndx = 1 %then %tu_sdtmconv_sys_message;
      %let _dsname_ = %scan(&_dsname, &_ndx, %str( ));
      %let _name_ = %scan(&_name, &_ndx, %str( ));
      proc sql noprint;
        /* 
        / Get the max length for the selected variable
        /*******************************************************************/
         select unique max_length into :_max_length separated by ' '
         from diff_var_lengths
         where upcase(dsname) = "%upcase(&_dsname_)" AND
               upcase(name)   = "%upcase(&_name_)";
        /* 
        / Get the list of varying lengths for the selected variable
        /*******************************************************************/
         select unique length into :_var_length separated by ', '
         from diff_var_lengths
         where upcase(dsname) = "%upcase(&_dsname_)" AND
               upcase(name)   = "%upcase(&_name_)"
         order by length desc;
      quit;
      %let _cmd = %str(ATTENTION: Found varying char lengths for: &_dsname_  variable: &_name_, using max length for append product.); %tu_sdtmconv_sys_message;
      %let _cmd = %str(ATTENTION: For variable: &_name_, Maximum length: &_max_length   Other lengths found: %quote(&_var_length).); %tu_sdtmconv_sys_message;      
      %if &_ndx = &_total_obs %then %tu_sdtmconv_sys_message;
   %end;
   
  /* (DSS001)
  /  Get just the obs with the max length value variables only
  /***************************************************************/
    
   proc sql noprint;
       select count(distinct(dsname)) into: _total_ds from dslist;
   quit;  
   
   %do indx = 1 %to &_total_ds;
      %let this_ds=%scan(&_dsname, &indx, %str( ));  /* Retrive the dataset name from the list to process in the loop below */

      /* (DSS001)
      /  Build dataset with only 1 dataset and all form names
      /***************************************************************/
      proc sort data=dslist(where=(dsname=:"&this_ds")) nodupkey out=varList;
         by dsname name;
      run;

      /* (DSS001)
      /  Create a set of lists that contain all variable names,
      /  their types (char or num), and max lengths for one dataset
      /***************************************************************/
      proc sql noprint;
         select name,type,length into :name separated by ' ', :type separated by ' ', :length separated by ' '
            from varlist;
      quit;
      %let varcnt = &sqlobs;  /* Save the number of variables to process in next step */

      /* (DSS001)
      / Using lists from above, build an empty shell dataset so the
      / char variables use the max length and numeric variables are
      / always set to 8. Use this dataset as first dataset in the 
      / dataset append process to the dmxfer folder.
      /***************************************************************/
      data _tmp_&this_ds;        
        %do ndx = 1 %to &varcnt;
           attrib %scan(&name,&ndx,%str( )) length= %if %upcase(%scan(&type,&ndx,%str( ))) = NUM %then 8.; %else $%scan(&length,&ndx,%str( )) ;;
        %end; /* do ndx 1 to varcnt */
        stop;
      run;
      %end; /* DO indx = 1 %to &_total_ds */
      
      %end; /* End of %if &sqlobs gt 0 %then %do; */
   
/* End of code added by DSS001 */
%do m=1 %to &dsobs;

 %if &&mf&m=0 %then %do;
   %let _cmd = %str( Rename &&dom&m.._&&dset&m SDTM sub-domain dataset to &&dom&m);%tu_sdtmconv_sys_message;

   proc datasets library = mid_sdtm nolist ;
   change &&dom&m.._&&dset&m  = &&dom&m;
   quit; run;

 %end;
  
 %if &&mf&m>=1 %then %do;
    %if &&mf&m=1 %then %do;  
     /* Rename domain */
     %let _cmd = %str( Create &&DOM&m SDTM domain from component sub-domain datasets);%tu_sdtmconv_sys_message;
     data mid_sdtm.&&dom&m; set
	 %if %sysfunc(exist(_tmp_&&dom&m)) %then %do;
	              /* BJC018: replace _tmp_&this_ds with _tmp_&&dom&m */
     _tmp_&&dom&m /* DSS001 Set template dataset with maximum variable length first _tmp_&this_ds */
     %end;
    %end; 
         mid_sdtm.&&dom&m.._&&dset&m
    %if &&last&m=Y %then %do;  
         ;run;       
    %end;     
 %end;
%end;
%tu_sdtmconv_sys_error_check;
 
/* Rename suppqual separate step*/
%do m=1 %to &dsobs;
 %if &&mf&m=0 %then %do;
    data mid_sdtm.supp&&dom&m; 
	/* DSS001 set the value of QVAL and QLABLE to max to avoid truncation of values */
	 attrib QVAL    length=$200.;
	 attrib QLABEL  length=$200.;
     set mid_sdtm.supp&&dom&m.._&&dset&m ;	 
    run;
    
 %end;  
  
 %if &&mf&m>=1 %then %do;

    /* Rename suppqual */
    %if &&mf&m=1 %then %do;  
     data mid_sdtm.supp&&dom&m ; 
    /* DSS001 set the value of QVAL and QLABLE to max to avoid truncation of values */
	 attrib QVAL    length=$200.;
	 attrib QLABEL  length=$200.; set
    %end; 
         mid_sdtm.supp&&dom&m.._&&dset&m
    %if &&last&m=Y %then %do;  
         ;run;
    %end; 
 %end;
 
%end; 
%tu_sdtmconv_sys_error_check;
 
***************************************************************************************;
/* Perform final steps on each unique concatentated domain */

%let dsobs= %eval(%tu_nobs(sdtm_dom_unq));
%if &dsobs >0 %then %do;

/* Create empty template dataset to summarise null findings data */
data _report_null_test;
   length problem_desc $60 name $10 memname $4 ;
run;   

/* Loop through each domain/dataset combination */
 %do i=1 %to &dsobs;
  ** set macro variables for each domain - then process each domain **;
  /* BJC003: add dom_desc to symputs */
  
  %let seqvar=;
  data _null_;
     set sdtm_dom_unq;
      if _n_ = &i then do;
        call symput('dom',trim(upcase(domain)));
        call symput('dset',trim(upcase(si_dset)));
        call symput('dom_ref',trim(upcase(dom_ref)));
        call symput('dom_desc',trim(upcase(dom_desc)));
        call symput('dom_type',trim(upcase(dom_type)));        
        call symput('seqvar',trim(upcase(seqvar)));
      end;
  run;

  ** get data from each domain **;
  ** do any post transpose processing here **;
  
  %if %eval(%tu_nobs(mid_sdtm.&dom))=0 %then %do;
   %let _cmd = %str( &DOM has no rows - dataset not created);%tu_sdtmconv_sys_message;
  %end;
  %else %do;
 
  ** VISIT values of LOGS and visitnum=0.00 are not part of SDTM concepts - remove any such values **;
  /* BJC014 - expand on removal of logs to also remove EOS details */
  
  %let VISIT=%tu_chkvarsexist(mid_sdtm.&dom,VISIT,Y);
  %let VISITNUM=%tu_chkvarsexist(mid_sdtm.&dom,VISITNUM,Y);

  %if &VISIT=VISIT and &VISITNUM=VISITNUM %then %do;   
        data mid_sdtm.&dom; set mid_sdtm.&dom;
         if upcase(VISIT) in ('SUBJECT LOGS','LOGS','EOS','END OF STUDY') then VISIT='';
         if VISITNUM=0 then VISITNUM=.;
        run;     
  %end; 
  
  ** For all data check for SEQ values and update if necessary to ensure SEQ uniqueness **;
  %if &dom^=DM %then %do;
      %tu_sdtmconv_mid_seq;
  %end; 

  /* Remove any rows with null --TESTCD values, and report a summary of them to the output */ 
  %if %index(%upcase(&dom_type),FINDINGS)>=1 %then %do;

  /* BJC001: replace domain with dom_ref as the variable prefix below */     
  /* BJC003: create temporary _mid_all_dom dataset of all rows present at the start to use as reference */
  /* DSS002: Remove _mid_all_&dom creation as it is redundant and uses lot of space when run on large studies */
   data mid_sdtm.&dom 
        _mid_null_tst_&dom;
    
    /* BJC013: If PK SI data converted - no tests present, so PCTESTCD would be created as $1, 
	           set to $5 to allow for PCALL value to be updated later */
	%if %length(%tu_chkvarsexist(mid_sdtm.&dom, &dom_ref.TESTCD)) > 0 %then %do;
	 length &dom_ref.testcd $5. ;
	%end;	
    
	set mid_sdtm.&dom;
     select;
	    when(&dom_ref.TESTCD eq '') output _mid_null_tst_&dom;
	    otherwise output mid_sdtm.&dom;
	 end;	 
   run;
  
   %if %eval(%tu_nobs(_mid_null_tst_&dom))>=1 %then %do;  
   %let _cmd = %str( Checking blank tests in &DOM to see if rows with --TESTCD= &dom.ALL need creating);%tu_sdtmconv_sys_message;
 
    /* BJC002: add checks for --STAT and --REASND columns to list of columns to check for data */
    proc sql noprint;
     select count(*) into :num_cols from dictionary.columns
     where libname='WORK' and memname="_MID_NULL_TST_&DOM"
     and upper(name) not in ('DOMAIN','STUDYID','USUBJID','SUBJID','VISIT','VISITNUM','SEQ','OLD_SEQ_VALUE')
     and upper(name) not like '%STAT' and upper(name) not like '%REASND';
   
     select  name
       into :name1- :name%left(&num_cols)    
       from dictionary.columns
     where libname='WORK' and memname="_MID_NULL_TST_&DOM"
     and upper(name) not in ('DOMAIN','STUDYID','USUBJID','SUBJID','VISIT','VISITNUM','SEQ','OLD_SEQ_VALUE')
     and upper(name) not like '%STAT' and upper(name) not like '%REASND';
  
     select count(*) into :num_rows from _mid_null_tst_&dom;
    quit; 
  
    proc sql noprint;
     %do a=1 %to &num_cols;
      select count(*) into :num_rows&a 
        from _mid_null_tst_&dom
       where &&name&a is not null ;
     %end; 
    quit; 
   
    data _mid_null_report_&dom;
     length name $10 memname $4 ;
     %do a=1 %to &num_cols;
      memname="&dom";
      name="&&name&a";
      tot=&num_rows;
      present=&&num_rows&a;
      if present >=1 then output;
     %end;
    run; 

	/* BJC015: specific addition for CO domain to ID keys other than --SEQ and VISITNUM */
    %let co_link=;
    proc sql noprint;
     select distinct substr(suppqual,7,length(suppqual)-6) into :CO_LINK separated by ''
       from varmap_mrg 
      where domain='CO' 	
	    and si_dset in (select distinct si_dset from varmap_mrg where domain="&dom")
        and substr(suppqual,7,length(suppqual)-6) ^='VISITNUM'
        and substr(reverse(substr(suppqual,7,length(suppqual)-6)),1,3)^='QES'
	    and substr(suppqual,1,6)="IDVAR=";
    quit;
	
    /* BJC003 - create rows with --TESTCD='<domain>ALL' and associated values where a 
    /  whole set of tests are missing for any possible set of timepoints 
    /  i.e. (U)SUBJID, VISIT(NUM) and optionally --ELTM, --TPT, --TPTREF, --TPTNUM where present */
    
    /* BJC011 - remove references in SQL to SUBJID - now redundant */
    /* VA001: - put RTNOTE containing Keys used for creating --TESTCD= '<domain>ALL' */    
    /* BJC015 : Add --LNKGRP and �-LNKID as these are new keys in SDTM 313 
	            Also remove --CAT, --SCAT, --EVAL, --EVALID - these keys can be defined at row level e.g. ECG/EG data
				the intent of --ALL is where a bundle of tests are missing - usally group keys or timepoints. */
	/* AV002: add back in --CAT and --SCAT to list of keys to use in --ALL row creation  */
	
     %let keys = %tu_chkvarsexist(mid_sdtm.&dom, STUDYID USUBJID VISIT VISITNUM EPOCH &dom_ref.ELTM &dom_ref.TPT
	 &dom_ref.TPTREF &dom_ref.TPTNUM &dom_ref.DTC &dom_ref.STDTC &dom_ref.ENDTC &dom_ref.OBJ &dom_ref.CAT &dom_ref.SCAT  
	 &dom_ref.SPID &dom_ref.GRPID &dom_ref.REFID &dom_ref.LINKID &dom_ref.LNKID &dom_ref.LNKGRP , Y);      
      
	 /* BJC020: add check for any --REASND variables already populated */
	 %let reasnd = %tu_chkvarsexist(mid_sdtm.&dom, &dom_ref.REASND, Y); 
	  
	 data _null_;
       keys1 = translate(trim("&keys"),","," ");
       keys2 = tranwrd(tranwrd(tranwrd(trim(keys1),",","||"),
               "VISITNUM","put(VISITNUM,7.2)"),
               "&dom_ref.TPTNUM","put(&dom_ref.TPTNUM,7.2)");	   

       /* BJC015: remove keys from list where used for CO IDVAR as these often cause blank domain rows for non-CO data. 
	              Such keys are usually concatenations of other keys that will still be in list e.g. if we remove EGGRPID
				  it should not be a problem as EGGRPID may be VISITNUM || PTMNUM which are both in the key list anyway */
				  
       %if &co_link ^= %then %do;
	    keys1 = tranwrd(keys1,",&co_link","");	   		   
	    keys2 = tranwrd(keys2,"||&co_link","");
	    keys1 = tranwrd(keys1,", ,",",");	   		   
	    keys2 = tranwrd(keys2,"|| ||","||");		
	   %end;	
       call symput('keys1',keys1);
       call symput('keys2',keys2);
    run;

    /* Then create a dataset of any unique timeslicing combinations where all --TESTCDs are null */
    /* DSS002: Modify SQL code - Improve performance to run on large studies. */  	
	
	proc sql noprint;
             
      create table _mid_null_dist_&dom as 
        select distinct domain, &keys1 
		/* BJC020: add check for any --REASND variables where these are already populated */
        %if %length(&reasnd)>=1 %then %do;
		 , &dom_ref.REASND
		%end;
            from _mid_null_tst_&dom
        where &keys2 not in (select distinct &keys2 from mid_sdtm.&dom); 	
    quit;
    
      %if %eval(%tu_nobs(_mid_null_dist_&dom)) ge 1 %then %do;
     
       /* Create content of the entry to go to the .lst file and SCPA tracking tool */
       data _mid_filler_report_&dom ;
        length problem_desc $60;
        name="&dom_ref.TESTCD";
        memname="&dom";
        problem_desc="Rows with &dom_ref.TESTCD='&dom_ref.ALL' created:>=1 sets of tests missing";
       run;
      
       /* AV001: put RTNOTE containing Keys used for creating --TESTCD= '<domain>ALL' */	   
	   %let _cmd = %str(%STR(RTN)OTE: The following keys were used to assign &dom_ref.TESTCD=&DOM_REF.ALL :);%tu_sdtmconv_sys_message;		
       %let _cmd = %str(&keys);%tu_sdtmconv_sys_message;
	 
       /* Update the filler ALL entries for the appropriate columns to add to the main domain */
       data _mid_null_dist_&dom;
        set _mid_null_dist_&dom;
        &dom_ref.TESTCD="&dom_ref.ALL";
        &dom_ref.TEST="&dom_desc";
        &dom_ref.STAT='NOT DONE';
		/* BJC020: add check for any --REASND variables where already populated */
		%if %length(&reasnd)>=1 %then %do;
		  if &dom_ref.REASND ='' then 
		%end;
         &dom_ref.REASND='Data not collected';
       run;
     
    /* Update the filler rows with the next available SEQ number(s) for each subject */	   
    /* DSS002: Use mid_sdtm.&dom instead of _mid_all_&dom */
	%if %eval(%tu_nobs(mid_sdtm.&dom)) >=1 %then %do;
       proc sql noprint;
        create table _mid_next_seq_&dom
         as select usubjid, max(seq)+1 as next_seq
         from mid_sdtm.&dom
         group by usubjid;
        
         alter table _mid_null_dist_&dom add SEQ num;
         
         update _mid_null_dist_&dom a set SEQ=
          (select next_seq 
             from _mid_next_seq_&dom b
            where a.usubjid=b.usubjid);    
         
		 /* Default SEQ to 1 if a USUBJID has no other (test/result populated) rows */
 		 update _mid_null_dist_&dom a set SEQ=1 where SEQ is null;
		 
       quit;  

       proc sort data=_mid_null_dist_&dom;
       by usubjid visitnum;
       run;
       
       data _mid_null_dist_&dom(drop=lag_seq);
        set _mid_null_dist_&dom;
        by usubjid ;
        retain lag_seq;		
        if first.usubjid then lag_seq=seq;
     	if not first.usubjid then do;	              
     	  lag_seq=lag_seq+1;
     	  seq=lag_seq;
        end; 
       run;
	%end; 

    %else %do;
       proc sort data=_mid_null_dist_&dom;
       by usubjid visitnum;
       run;
         
       data _mid_null_dist_&dom;
        set _mid_null_dist_&dom;
        by usubjid;
        retain seq;
        if first.usubjid then seq=1;
     	else seq+1;
       run;
    %end; 	       

       /* Finally - append the <domain>ALL filler rows to the rest of the domain data */
       data mid_sdtm.&dom;
        set mid_sdtm.&dom
           _mid_null_dist_&dom;
       run;
     
      %end;
    /* BJC003: End of main set of code changes */
      
    /* BJC001: replace domain with dom_ref as the variable prefix below */     
   
    data _mid_null_report_&dom ; 
     set _mid_null_report_&dom end=last;
     length problem_desc $60;
     retain problem_desc '';
     if _n_=1 then problem_desc="nulls removed BUT:";
     problem_desc=trim(problem_desc)||trim(name);
     if not last then do;
       problem_desc=trim(problem_desc)||',';
     end;
     if last then do;
      problem_desc=trim(problem_desc)||' values non-missing';
      name="&dom_ref.TEST";
      output;
     end;
    run; 
   
    data _report_null_test;
     set _report_null_test
         /* BJC003: add an entry to the .lst file to say <domain>ALL entries created */
         %if %sysfunc(exist(_mid_filler_report_&dom)) %then %do;
               _mid_filler_report_&dom
         %end;
         _mid_null_report_&dom;
    run;
  
   %end;
  %end;

  ** if seq is present then rename seq to domainseq eg aeseq **;
  /* BJC011 - remove references to SUBJID - now redundant */

  data pst_sdtm.&dom;
   set mid_sdtm.&dom;
   %if &dom^=DM %then %do; 
    format seq ;
    informat seq ;    
   %end; 
   %if &dom=DM %then %do;
    drop SEQ;
   %end; 
   %if &seqvar^= and &dom^=DM %then %do;
    rename seq=&dom_ref.SEQ;
   %end;
   %if &seqvar= %then %do;
    drop seq;
   %end;    
  run;
  
  /* BJC011 - remove references to SUBJID - now redundant */

 %end;
 
 %if %eval(%tu_nobs(mid_sdtm.supp&dom))=0 %then %do;
  %let _cmd = %str( SUPP&DOM has no rows - dataset not created);%tu_sdtmconv_sys_message;
  
  %if %tu_chkvarsexist(pst_sdtm.&dom,old_seq_value) eq %then %do;

    proc sql noprint;
         alter table pst_sdtm.&dom drop old_seq_value ;
    quit;
  %end;   
   
 %end;
 %else %do;
  %let _cmd = %str( Creating SUPP&DOM SDTM domain dataset );%tu_sdtmconv_sys_message;

   /*Add a record to SDTM_DOM for any SUPP domains that get created */
   
   data update_sdtm_dom;
    length DOMAIN $6 SI_DSET $12;
    DOMAIN="&dom";
    SI_DSET="SUPP";
   run;
   
   data sdtm_dom;
    set sdtm_dom update_sdtm_dom;
   run;
   
   ** Set macro var to drop SEQ/ID vars var if not used or keep if it is used *;
   ** also - only populate IDVAR where there is a SEQ value **;
   /* BJC012 : update &dom with &dom_ref to create IDVAR=FASEQ correctly for FAXXSUPP domains */
   %let keep_seqvar= %str(IDVAR="&dom_ref.SEQ");
   %let keep_idvar= %str(keep idvar idvarval;);

   /* Get any linked SEQ item details to apply in the next step */
   data _supp_link; 
    set mid_link_items(where=(domain="&dom"));
    num=_n_;
   run;
   
   %if %eval(%tu_nobs(_supp_link)) >=1 %then %do;
   
      proc sql noprint;
       select link_item
          into :link_item1- :link_item%left(%eval(%tu_nobs(_supp_link)))    
          from _supp_link;
      quit;
   
   %end; 
   
   data pst_sdtm.supp&dom;
    set mid_sdtm.supp&dom;
      attrib IDVARVAL length=$200.;
      attrib IDVAR    length=$10.;
      attrib QEVAL    length=$200.;
	  
      ** set qualifying variables - this has to be checked, may not be same for all data **;
      ** not done anything with QEVAL (for subjective results ) **;
      RDOMAIN = domain;  ** related domain **; 
      QNAM    = sdtm_var;** short name of variable **;
      QLABEL  = _label_; ** long name or label associated with QNAM **;
      QVAL    = col1;    ** value of QNAM **;
      QORIG   = origin;  ** Origin of data, e.g. CRF or DERIVED **;

      /* BJC009 - add population of QEVAL */
      QEVAL   = evaluator;      

      ** Now populate correct link variables into IDVAR and IDVARVAL (from SUPPQUAL column)**;
      if SUPPQUAL=:"YES" then do;
        %if &seqvar ^= %then %do;
         &keep_seqvar;** identifying variable - usually SEQ  **;
        %end;
          IDVARVAL = left(put(seq,8.));  ** value of identifying variable **;
      end;
      if suppqual="YES[VISITNUM]" then do;
        ** value of identifying variables **;
        /* BJC004 correction to how VISITNUM is placed in IDVARVAL. Use rounded value for integer, 
        /  and decimal for unscheduled. This then matches the (unformatted) parent domain values */
        if round(visitnum)=visitnum then IDVARVAL=left(put(visitnum,8.));
        else IDVARVAL=left(put(visitnum,7.2));
        IDVAR = "VISITNUM";
      end;
      
	  /* BJC017: add USUBJID as a SUPP link var - processed differently as its a key 
	     (see SUPPDM where IDVAR and IDVARVAL are null in the IG examples - apply same here) */
	  if suppqual="YES[USUBJID]" then do;            
        IDVAR = " ";
		IDVARVAL = " ";
      end;
	  
      /* Loop through and apply any link items that are not the regular (key) visitnum and seq */
      %do s=1 %to %eval(%tu_nobs(_supp_link));
      
       if suppqual="YES[&&link_item&s]" then do;
        IDVARVAL = left(&&link_item&s);  ** value of identifying variable **;
        IDVAR = "&&link_item&s";                 ** value of identifying variable **;
       end;
      %end;
      
      %if &seqvar ^= %then %do;
       &keep_idvar;   
      %end;
      
       keep STUDYID RDOMAIN USUBJID QNAM QLABEL QVAL QORIG QEVAL suppqual;      
   run;

   ** Finally update the correct SEQ values into IDVARVAL for those linked on SEQ **;
   %if %index(%upcase(&dom_type),FINDINGS)>=1 %then %do;
   
     /* BJC010: Add SDTM_VAR to distinct statement */
     proc sql noprint; 
        select count(distinct sdtm_var||substr(suppqual,9,length(suppqual)-8)) 
               into :num_links 
          from mid_sdtm.supp&dom
        where substr(suppqual,1,8)="YES[SEQ]";
     quit; 
   
     proc sql noprint; 
           select count(distinct sdtm_var) 
                  into :num_seqlnk 
             from mid_sdtm.supp&dom
           where suppqual="YES";
     quit; 

     %if &num_links >=1 or &num_seqlnk >=1 %then %do;

      proc sql noprint;
        create index usubjid on pst_sdtm.&dom;
        create index usubjid on pst_sdtm.supp&dom;
      quit;

     %end;
 
     /* update SUPPQUAL link for default simple SEQ-type joins */
     %if &num_seqlnk >=1 %then %do;
  
      /* Update any findings SUPPQUAL rows where a simple SEQ join is used */ 
      /* BJC001: replace domain with dom_ref as the variable prefix below */     
      /* BJC005: Add check for orphan SEQ values */

      proc sql noprint;
           update pst_sdtm.supp&dom sq set idvarval=
           (select left(put(&dom_ref.SEQ,8.))
              from pst_sdtm.&dom dm
             where dm.usubjid=sq.usubjid
               and input(sq.idvarval,8.)=dm.old_seq_value)
           where SUPPQUAL='YES';  
      quit;
     %end;

     /* update SUPPQUAL link for non-default simple SEQ-type joins */
     %if &num_links >=1 %then %do;
	 
	  /* BJC019: Add SUPPQUAL macro param */
      proc sql noprint; 
       select distinct suppqual,
	          substr(suppqual,9,length(suppqual)-8)  ,
              sdtm_var 
         into :sq1 - :sq%left(&num_links),
		      :link1 - :link%left(&num_links) ,
              :sdtm_var1 - :sdtm_var%left(&num_links)
         from mid_sdtm.supp&dom
       where substr(suppqual,1,8)="YES[SEQ]";
      quit; 

      
      /* Update any findings SUPPQUAL rows where a test specific SEQ join is used */ 
      /* BJC001: replace domain with dom_ref as the variable prefix below */     

      %do l=1 %to &num_links;	 	  
	   
       %let _cmd = %str(  Updating SEQ values in SUPP&dom for &&sdtm_var&l linked to &&link&l );%tu_sdtmconv_sys_message;
	   /* BJC019: Add SUPPQUAL macro param */
       proc sql noprint;
         update pst_sdtm.supp&dom sq set idvarval=
         (select left(put(&dom_ref.SEQ,8.))
            from pst_sdtm.&dom dm
           where &dom_ref.TESTCD="&&link&l" 
             and dm.usubjid=sq.usubjid
             and input(sq.idvarval,8.)=dm.old_seq_value)
         where qnam="&&sdtm_var&l" and suppqual="&&sq&l";  
       quit;
     %end;
     
    %end;   

    %if &num_links >=1 or &num_seqlnk >=1 %then %do;

      /* BJC005: Query for and Report any orphan SEQ values */ 
      /* BJC008: move this checking step - it was being performed before SEQ numbers were finalised */
      
      proc sql noprint;
           create table _mid_orphan_seq_&dom as 
           select usubjid, idvarval 
             from pst_sdtm.supp&dom
            where idvar="&dom_ref.SEQ"
              and idvarval is not null
              and compress(usubjid)||compress(IDVARVAL) not in
              (select compress(usubjid)||compress(put(&dom_ref.SEQ,8.))
                  from pst_sdtm.&dom);
      quit;
       
      %if &sqlobs >=1 %then %do;      
       %let _cmd = %str(%str(RTW)ARNING: Orphan SEQ values in SUPP&dom domain);%tu_sdtmconv_sys_message;
      
       proc print data=_mid_orphan_seq_&dom (obs=30);
            title3 "SDTM conversion: orphan rows for SUPP&dom in &g_study_id";
            title4 'SEQ values in SUPP dataset are not present in parent domain.';
            title5 'Usual cause is where the --TESTCD=--ALL rows are rolled up into';
            title6 'one summary row per time point and --SEQ values are reset.';
            title6 'For brevity only the first 30 are listed as the cause is usally common';
       run;
      
      %end;       
    %end;     
    
    /* Findings datasets can have qualifiers e.g. EGCHINTP from the source data that are stored multiple times
    /  within rows for each VISITNUM (for example). In SUPPQUAL we only want one of these to be kept */
    proc sql noprint;
     create table supp&dom as select distinct * from pst_sdtm.supp&dom;
    quit;
    
    data pst_sdtm.supp&dom;
     set supp&dom;
    run;     
    
   %end;      

   %if %tu_chkvarsexist(pst_sdtm.&dom,old_seq_value) eq %then %do;
    proc sql noprint;
         alter table pst_sdtm.&dom drop old_seq_value ;
    quit;
   %end;   
   %if %tu_chkvarsexist(pst_sdtm.supp&dom,suppqual) eq %then %do;
    proc sql noprint;
         alter table pst_sdtm.supp&dom drop suppqual;
    quit;
   %end;   

   ** check for errors after each loop **;
   %tu_sdtmconv_sys_error_check;  
  %end; 
 %end;
%end; /* if &dsobs>0 */ 

/* Delete temporary MID_SDTM datasets used in this macro if __UTC_WORKPATH */
/* is not used to redirect to external unix directory.                     */
%if &sysenv=BACK and %symexist(__utc_workpath) eq 0 %then %do;  

proc datasets library=mid_sdtm memtype=DATA nolist nowarn kill;
quit;  

%tu_tidyup(
 rmdset = _mid_:,
 glbmac = none
);
%end;

%endmac:
 
%mend tu_sdtmconv_mid_append;
