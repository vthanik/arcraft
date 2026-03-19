/******************************************************************************* 
|
| Macro Name: tu_sdtmconv_mid_trans
|
| Macro Version/Build: 11/1
|
| SAS Version: SAS 9.1.3
|
| Created By: Bruce Chambers
|
| Date:          12-Aug-2009
|
| Macro Purpose: Macro to take the study_sdtm dataset and process each of
|                the constituent domains into separate sub-domain and sub-SUPP   
|                datasets where needed. 
|
|                This macro is really the crux of the SDTM conversion process.
|
| Macro Design:
|
| Input Parameters:
|
| NAME              DESCRIPTION                         DEFAULT 
|
| Output:
|
|
| Global macro variables created:
|
|
| Macros called:
| (@) tu_nobs
| (@) tu_sdtmconv_mid_norm
| (@) tu_sdtmconv_mid_norm_add
| (@) tu_sdtmconv_sys_error_check
| (@) tu_sdtmconv_sys_message
| (@) tu_sdtmconv_util_mid_add_nu
| (@) tu_tidyup
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
| Description for Modification: Update 'NO RESULT' string to add 'NA','N/A','NOT DONE'
| Reason for Modification:      When processing findings data, if an -ORRES field contains
|                               any of the above entries they should be moved to --REASND.
|                               Also null out --STRESC if that data is already present from source
|                               Added code to move 'IS','NC','NS','ND' values from PC/PP domains to --REASND
|                               NB: Matches partner code section in tu_sdtmconv_mid_norm_add.sas 
|
| Modified By:                  Bruce Chambers
| Date of Modification:         28april2010
| New Version/Build Number:     v2 build 1
| Reference:                    BJC002
| Description for Modification: check for existence of values in --REASND before updating
| Reason for Modification:      Make the code the same as the matching section that is in 
|                               tu_sdtmconv_mid_norm_add.sas so that the presence of --REASND 
|                               is checked for and if already present existing content will not 
|                               be overwritten.
|
| Modified By:                  Bruce Chambers
| Date of Modification:         28april2010
| New Version/Build Number:     v2 build 1
| Reference:                    BJC003
| Description for Modification: For FA domains the values of DOMAIN must be FA not FA--
| Reason for Modification:      Ensure data is SDTM compliant
|
| Modified By:                  Bruce Chambers
| Date of Modification:         04august2010
| New Version/Build Number:     v3 build 1
| Reference:                    BJC004
| Description for Modification: Add full complement of 2 letter PC/PP codes to move to --REASND
| Reason for Modification:      Ensure data is SDTM compliant
|
| Modified By:                  Bruce Chambers
| Date of Modification:         05august2010
| New Version/Build Number:     v4 build 1
| Reference:                    BJC005
| Description for Modification: Call symput dom_desc from domain_ref meta data set 
| Reason for Modification:      For use in future populating --TEST when --TESTCD='--ALL' scenario 
|
| Modified By:                  Bruce Chambers
| Date of Modification:         06august2010
| New Version/Build Number:     v4 build 1
| Reference:                    BJC006
| Description for Modification: Shorten work dataset name as _mid_link_items_dist_<dom>_<dset> 
|                               to _mid_link_ditems_<dom>_<dset>
|                               can reach 34 chars and the limit is 32.
| Reason for Modification:      Avoid SAS errors if name exceeds 32 char length limit
|
| Modified By:                  Bruce Chambers
| Date of Modification:         06august2010
| New Version/Build Number:     v4 build 1
| Reference:                    BJC007
| Description for Modification: Reinstate a piece of code inadvertently removed in the last build  
|                               two lines of the removed code IS required - the rest of the removed 
|                               section was duplicated.
| Reason for Modification:      Correctly process all data scenarios
|
| Modified By:                  Bruce Chambers
| Date of Modification:         22Nov2010
| New Version/Build Number:     5/1
| Reference:                    BJC008
| Description for Modification: Rearrange steps so multiple study_t and multiple study_sdtm
|                               dataset production is accommodated, and removal of some unnecessary datasets                            
| Reason for Modification:      Performance enhancement for larger volume studies
|
| Modified By:                  Bruce Chambers
| Date of Modification:         22Nov2010
| New Version/Build Number:     5/1
| Reference:                    BJC009
| Description for Modification: Re-code derivation of USUBJID                
| Reason for Modification:      Ensure correct data presented in SDTM domains
|
| Modified By:                  Bruce Chambers
| Date of Modification:         22Nov2010
| New Version/Build Number:     6/1
| Reference:                    BJC010
| Description for Modification: Add compound indexes to speed up some of the possible SUPP linking scenarios              
| Reason for Modification:      Performance boost
|
| Modified By:                  Bruce Chambers
| Date of Modification:         22Nov2010
| New Version/Build Number:     6/1
| Reference:                    BJC011
| Description for Modification: Remove derivation of USUBJID                
| Reason for Modification:      Superceded by pre_adjust_subjid that ensure USUBJID present on all incoming data
|
| Modified By:                  Deepak Sriramulu
| Date of Modification:         4May2011
| New Version/Build Number:     7/1
| Reference:                    DSS001
| Description for Modification: Set --REASND for PC and PP to larger size to allow later decode
| Reason for Modification:      To provide full data
|
|Modified By:                  Ashwin Venkat
| Date of Modification:         10Apr2012
| New Version/Build Number:     8/1
| Reference:                    AV001
| Description for Modification: modified code which identifies domains with no rows i.e where only SUPP item is present 
| Reason for Modification:      to flag empty domains so they dont get processed further
|
| Modified By:                  Bruce Chambers
| Date of Modification:         25Oct2012
| New Version/Build Number:     9/1
| Reference :                   bjc012
| Description for Modification: Allow for VISITNUM as well as SEQ as a CO domain link item that is also a key
|                               for transposed mid conversion datasets. Other items that are not transpose keys
|                               such as EGGRPID need adding to transpose keys for later adding into CO domain.
|                               Its just SEQ and VISITNUM that are transpose KEYS, other CO keys need allowing for.
| Reason for Modification:      Allow more CO domain link scenarios than just --SEQ.
|
| Modified By:                  Bruce Chambers
| Date of Modification:         02May2013
| New Version/Build Number:     10/1
| Reference :                   bjc013
| Description for Modification: In creation of MID_LINK_ITEMS work dataset, dont include USUBJID
| Reason for Modification:      mid_append macro processes USUBJID links differently as its a key like SEQ/VISITNUM
|
| Modified By:                  Bruce Chambers
| Date of Modification:         22Jul2013
| New Version/Build Number:     11/1
| Reference :                   bjc014
| Description for Modification: In creation of MID_LINK_ITEMS work dataset, duplicates may appear where patterns repeat
| Reason for Modification:      Efficiency purposes
|
| Modified By:                  Bruce Chambers
| Date of Modification:         22Jul2013
| New Version/Build Number:     11/1
| Reference :                   bjc015
| Description for Modification: In creation of CO domain rows an extra sort was needed for a more complex scenario
| Reason for Modification:      Ensure conversion can run error free to completion
|
********************************************************************************/ 
%macro tu_sdtmconv_mid_trans(
);

/* get list of unique domains in sdtm data - add and update additional columns for 
/  attributes of the SDTM data transforms */
/* BJC008: query from multiple STUDY_SDTM<n> datasets */

proc sql;
  create table sdtm_dom as (
   %do a=1 %to &num_mid;
    %if &a>=2 %then %do;
     union all
    %end; 
    select distinct &a as num_mid, si_dset, domain from mid_sdtm.study_sdtm&a
   %end;
   );
   
   alter table sdtm_dom add dom_type char(75) ;
   alter table sdtm_dom add dom_ref char(24) ;
   alter table sdtm_dom add pre_norm char(21) ;
   alter table sdtm_dom add seqvar char(30) ;
   alter table sdtm_dom add empty char(1) ;
      
   update sdtm_dom dom set dom_type=(select dom_type from domain_ref dr
   where dr.domain=dom.domain);

   update sdtm_dom dom set pre_norm=(select pre_norm from si_rules sir
   where dom.si_dset=sir.si_dset);
   
   update sdtm_dom dom set dom_ref=(select domref from domain_ref dr
   where dr.domain=dom.domain);

   update sdtm_dom dom set seqvar=(select variable_name from reference ref
   where ref.domain=dom.domain
     and substr(reverse(trim(ref.variable_name)),1,3)='QES');
     
   /* BJC005: add dom_desc to sdtm_dom lookup and populate */
   alter table sdtm_dom add dom_desc char(300) ;

   update sdtm_dom dom set dom_desc=(select dom_desc from domain_ref dr
   where dr.domain=dom.domain);       
quit;

proc sort data=sdtm_dom ;
by domain seqvar;
run;

proc sort data=sdtm_dom out=sdtm_dom_unq nodupkey;
by domain;
run;

/* Create template dataset to hold SUPP domain link item details - used in append macro later */

data mid_link_items;
 stop;
run;

/* BJC008 : add do loop for multiple datasets */
%let _cmd = %str(Adding indexes to speed performance );%tu_sdtmconv_sys_message;
%do a=1 %to &num_mid;

 /* sort the main study_sdtm dataset by the keys */
 proc sort data=mid_sdtm.study_sdtm&a;
  by studyid usubjid visitnum visit seq sdtm_var;
 run;
  
 proc sql noprint;
  create index si_dset on mid_sdtm.study_sdtm&a;
 quit;  
%end;

%let dsobs= %eval(%tu_nobs(sdtm_dom));
%if &dsobs>0 %then %do;

/* Loop through each domain/dataset combination */
 %do i=1 %to &dsobs;
    %let seqvar=.;
    
    ** set macro variables for each domain - then process each domain **;
    /* BJC008 : create num_mid macro var for multiple datasets */

    data _null_;
     set sdtm_dom;
      if _n_ = &i then do;
        call symput('dom',trim(upcase(domain)));
        call symput('dset',trim(upcase(si_dset)));
        call symput('seqvar',trim(upcase(seqvar)));
        call symput('dom_type',trim(upcase(dom_type)));
        call symput('dom_ref',trim(upcase(dom_ref)));
        call symput('pre_norm',trim(upcase(pre_norm)));
        call symput('num_mid',num_mid);        
      end;
    run;

    /* get data from each domain */
    /* Create SUPP and MAIN domain datasets */

    %let _cmd = %str( Creating &DOM._&dset SDTM sub-domain dataset );%tu_sdtmconv_sys_message;

    /* Create SUPP and MAIN domain datasets */
    /* BJC008 : add correct &num_mid dataset suffix to pull from the correct one of the potential multiple datasets */
    
    data mid_sdtm.&dom._&dset
         mid_sdtm.supp&dom._&dset;
     set mid_sdtm.study_sdtm%left(%trim(&num_mid)) (where=(upcase(domain) = "&dom" and upcase(si_dset) = "&dset"));
     
     /* BJC003 - update domain values to FA instead of FA-- */
     %if &dom_ref=FA %then %do;
      DOMAIN='FA';     
     %end;   

     /* BJC009: USUBJID needs to be derived only if not already present */
     /* BJC011: remove 2 lines for USUBJID derivation - this now happens in pre_adjust_usubjid */

     %if &dom^=CO %then %do;
       if suppqual=:'YES' then output mid_sdtm.supp&dom._&dset;
          else                 output mid_sdtm.&dom._&dset;
     %end;
     %if &dom=CO %then %do;
       output mid_sdtm.&dom._&dset;
     %end;      
    run; 
    /*AV001 : Check if &dom.&dset dataset is having any data after removing SUPP rows
    */  
    %let no_data = %tu_nobs(mid_sdtm.&dom._&dset);
    /* ID any link variables used for SUPPQUAL data. VISITNUM and SEQ are keys that will already be present
    /  in SUPP datsets so no need to add them */
	
	/* BJC013: dont include USUBJID links in mid_link_items work dataset(s) - key links are processed differently
	   later on in mid_append macro */
	   
    proc sql noprint;
     create table _mid_link_items_&dom._&dset as
     select distinct si_var, suppqual , "&dom" as domain length=4
       from mid_sdtm.supp&dom._&dset
      where suppqual like '%YES[%' and suppqual not like '%VISITNUM%' and suppqual not like '%SEQ%'
	    and suppqual ^='YES[USUBJID]';
    quit;  

    data _mid_link_items_&dom._&dset;
     set _mid_link_items_&dom._&dset;
     length LINK_ITEM $8;
     num=_n_;
     if index(suppqual,'[')>=1 then do;
      link_item=substr(suppqual,index(suppqual,'[')+1,index(suppqual,']')-index(suppqual,'[')-1);
     end; 
    run;  

    data mid_link_items;
     set _mid_link_items_&dom._&dset
         mid_link_items;
    run;

	/* BJC014: for later efficiency remove duplicates that may build if same links used for multiple feeder sub domains */
	proc sort data=mid_link_items nodupkey;
	by _all_;
	run;
	
    /* bjc006:shorten work dataset name for distinct link items to _mid_link_ditems_<dom>_<dset> */
     
    proc sql;
     create table _mid_link_ditems_&dom._&dset as 
     select distinct link_item from _mid_link_items_&dom._&dset;
    quit; 
     
    /* If SUPPQUAL links on items other than VISITNUM or SEQ then update values from the main domain
    / as extra pseudo-key columns into the SUPP domain */

    /* bjc005: reference new shortened work dataset name for distinct link items to _mid_link_ditems_<dom>_<dset> */
    %if %eval(%tu_nobs(_mid_link_ditems_&dom._&dset)) >=1 %then %do;
    
      /* BJC010: Define compound indexes to speed up some of the possible SUPP linking scenarios */
      proc sql noprint;
            create index svs on mid_sdtm.&dom._&dset     (usubjid, visitnum, seq);           
            create index svs on mid_sdtm.supp&dom._&dset (usubjid, visitnum, seq);
      quit;

     /* bjc005: reference new shortened work dataset name for distinct link items to _mid_link_ditems_<dom>_<dset> */
     %do s=1 %to %eval(%tu_nobs(_mid_link_ditems_&dom._&dset));
     
      data _null_;
       set _mid_link_items_&dom._&dset;
        if _n_ = &s then do;
         call symput('LINK_ITEM',trim(LINK_ITEM));
        end; 
      run;
      
      /* BJC010: Force use of compound indexes to speed up some of the possible SUPP linking scenarios */
      proc sql noprint;
       alter table mid_sdtm.supp&dom._&dset add &LINK_ITEM char(200);
       
       update mid_sdtm.supp&dom._&dset a set &link_item=
       (select col1
          from mid_sdtm.&dom._&dset (idxname=svs) b
         where a.studyid=b.studyid
           and a.usubjid=b.usubjid           
           and a.visitnum=b.visitnum
           and a.visit=b.visit
           and a.seq=b.seq
           and b.sdtm_var="&link_item");
      quit;     
    
     %end;
    %end;

    /* Where FINDINGS domain data needs to be normalised then follow SDTM conventions-rules 
    / pre_norm values come from si_rules data source */
    
    %if %index(%upcase(&dom_type),FINDINGS)>=1 and %length(&pre_norm)=0 %then %do; 
       %tu_sdtmconv_mid_norm;      
       %tu_sdtmconv_sys_error_check;
       
       %if &dom ^=IE %then %do;

         data mid_sdtm.&dom._&dset; 
		   /*DSS001 - set the PC/PPREASND fields to be larger to allow later decoding */
           %if &dom_ref = PC or &dom_ref = PP %then %do;
            attrib &dom_ref.REASND length=$200;
           %end;
		  set mid_sdtm.&dom._&dset;
         
          /* BJC001 and BJC004 : increase the list of entries moved to --REASND */
          /* NB: Code Matches partner code section in tu_sdtmconv_mid_norm_add.sas */

          if upcase(&dom_ref.ORRES)in ('NO RESULT','NA','N/A','NOT DONE','NQ','---------') 
             or ("&dom_ref" in ("PP","PC") and upcase(&dom_ref.ORRES) in ('IS','NR','NQ','NC','NS','ND') ) then do;    
          
           /* BJC002 : make the code the same as the matching section that is in 
           /  tu_sdtmconv_mid_norm_add.sas so that the presence of --REASND is checked for
           / and if already present existing content will not be overwritten */
           
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

          /* Add normal units if defined in mapping i.e. not in data already*/
          %tu_sdtmconv_util_mid_add_nu;           
       %end;
       %tu_sdtmconv_mid_norm_add;
       %tu_sdtmconv_sys_error_check;
    %end;
    
    /* Where FINDINGS domain data dont need to be normalised then follow SDTM conventions-rules 
    / pre_norm values come from si_rules data source */
    
    %else %if %index(%upcase(&dom_type),FINDINGS)>=1 and %length(&pre_norm)>=1 %then %do; 

        /* transpose the domain dataset by keys */
      	
	proc transpose data=mid_sdtm.&dom._&dset out=mid_sdtm.&dom._&dset(drop=_name_ _label_);
	   by studyid domain usubjid visitnum visit seq;
	   id sdtm_var;
	   var col1;
        run; 
         
        /* With bjc004 removal of redundant step that was here - it was a redundant partial duplication
        /  of what happens next in tu_sdtmconv_mid_norm_add */
        /* bjc007 adds back in two lines of the removed code that are actually not duplicated and are needed
        /  for one data scenario */
        
         %if &dom ^=IE %then %do;

         data mid_sdtm.&dom._&dset; set mid_sdtm.&dom._&dset;
          length OLD_SEQ_VALUE 8.;           
          OLD_SEQ_VALUE=seq;
         run;

         ** Assume incoming normalised data will already have UNIT columns so dont add them here *; 
        %end;

        ** Assume incoming normalised data will already have UNIT columns so dont add them here *;        
        
        ** ELIG/IE data is already normalised (pre_norm=1) but we dont add units etc for ELIG **;
        %if &dom ^=IE %then %do;
         %tu_sdtmconv_mid_norm_add;
         %tu_sdtmconv_sys_error_check;
        %end; 
        
    %end;
    
    /* If not a FINDINGS domain then this step will run */
    %else %do;                             
							 
     /* BJC012: specific addition for CO domain to allow for non-default transpose keys such as EGGRPID */
	 %let co_link=;
     %if &dom=CO %then %do;
      proc sql noprint;
	   select distinct substr(suppqual,7,length(suppqual)-6) into :CO_LINK
	     from varmap 
		where domain='CO' 
          and si_dset="&dset"	
          and substr(suppqual,7,length(suppqual)-6) ^='VISITNUM'
          and substr(reverse(substr(suppqual,7,length(suppqual)-6)),1,3)^='QES'
		  and substr(suppqual,1,6)="IDVAR=";
	  quit;	  
	 %end;
	 
     ** transpose the domain dataset by keys **; 
	 /* BJC999: specific addition for CO domain - tranpose by any additional CO key but then also drop it */
	 /* BJC015: add forced proc sort for CO domain data */
	  proc sort data=mid_sdtm.&dom._&dset force;
       by studyid domain usubjid visitnum visit seq &co_link;
      run;
	 
      proc transpose data=mid_sdtm.&dom._&dset out=mid_sdtm.&dom._&dset(drop=_name_ _label_ &co_link);	    
        by studyid domain usubjid visitnum visit seq &co_link;
        id sdtm_var;
        var col1;
      run;
    %end;    
    
    /* If the domain results in no rows e.g. where only SUPP item is present then flag as empty in the
    /  driver table to prevent further processing on this main domain */
    %if %eval(&no_data)=0 %then %do;
          
      %let _cmd = %str(%STR(RTW)ARNING: Empty intermediate domain for &dom._&dset - investigate);%tu_sdtmconv_sys_message;

      proc sql noprint;
          update sdtm_dom set empty='Y' where domain="&dom" and si_dset="&dset";
      quit;    
         
      /* The transpose will have made a 0 record dataset into a 1 record datasets with nothing in
         So where this happens, tidy up the dataset so that it will not cause a null record in the domain */
      data mid_sdtm.&dom._&dset;
       set mid_sdtm.&dom._&dset(keep=STUDYID);
        stop;
      run;
      
    %end;    
    
    %tu_sdtmconv_sys_error_check;
 %end;
%end; 

%if &sysenv=BACK %then %do;  
 
%tu_tidyup(
 rmdset = _mid_:,
 glbmac = none
);
%end;

%mend tu_sdtmconv_mid_trans;

         

 
