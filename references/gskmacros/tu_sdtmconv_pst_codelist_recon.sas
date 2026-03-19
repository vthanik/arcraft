/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pst_codelist_recon
|
| Macro Version/Build:  7/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009
|
| Macro Purpose:        First apply SDTM formats to decode coded data with known
|                       decodes.
|
|                       Then reconcile codelisted items with controlled
|                       terminology and create a dataset of any codelisted terms
|                       in the SDTM data that dont match the controlled CDISC
|                       terminology.
|
|                       The removal of extensible terms from user output happens
|                       later when in the sys_print module to suppress print of
|                       extensible terms  
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
|   The following dataset is created:
|
|     _report_collect (one row per codelist term that is not in CDISC master list)
|
| Global macro variables created:
|
|
| Macros called:
| (@)tu_nobs
| (@)tu_tidyup
| (@)tu_sdtmconv_sys_message
| (@)tu_chkvarsexist
|
| Example:
|
| %tu_sdtmconv_pst_codelist_recon
|
|*******************************************************************************
| Change Log:
|
| Modified By:                   Bruce Chambers  
| Date of Modification:          26May2010
| New Version/Build Number:      2/1      
| Reference:                     BJC001
| Description for Modification:  update value of EGTESTCD=OTHER to OTHERABN
| Reason for Modification:       Result of DSO mapping update
|
| Modified By:                   Bruce Chambers  
| Date of Modification:          09Aug2010
| New Version/Build Number:      3/1      
| Reference:                     BJC002
| Description for Modification:  Suppress reporting of --TESTCD=--ALL as these are valid
| Reason for Modification:       Brief user output to review, exclude non-issues
|
| Modified By:                   Bruce Chambers  
| Date of Modification:          09Aug2010
| New Version/Build Number:      3/1      
| Reference:                     BJC003
| Description for Modification:  Suppress check of MB/MS CT where MS/MBCAT ^=ORGANISM
| Reason for Modification:       Brief user output to review, exclude non-issues
|
| Modified By:                   Bruce Chambers  
| Date of Modification:          09Aug2010
| New Version/Build Number:      3/1      
| Reference:                     BJC004
| Description for Modification:  Add RTWARNING for controlled term issues, and upgrade any 
|                                issues for Fixed lists to error
| Reason for Modification:       Ensure data integrity
|
| Modified By:                   Bruce Chambers  
| Date of Modification:          13Aug2010
| New Version/Build Number:      3/1      
| Reference:                     BJC005
| Description for Modification:  Where a CT issue is created for the listing file, output more of 
|                                the string and remove the C:nnnnn section
| Reason for Modification:       Ensure fullest possible text string details are provided for DSO
|                                however, any over 39 chars in length will still be truncated.
|
| Modified By:                   Bruce Chambers  
| Date of Modification:          22Nov2010
| New Version/Build Number:      4/1      
| Reference:                     BJC006
| Description for Modification:  Reduce # of R/W steps to one per dataset for applying formats
| Reason for Modification:       Some datasets were being read/written many/multiple times with 
|                                resulting poor performance.
|
| Modified By:                   Bruce Chambers  
| Date of Modification:          01Feb2011
| New Version/Build Number:      4/1      
| Reference:                     BJC007
| Description for Modification:  Only apply CT for DSDECOD for DSCAT=PROTOCOL MILESTONE
| Reason for Modification:       Correct selective application of CT.
|
| Modified By:                   Bruce Chambers  
| Date of Modification:          01Feb2011
| New Version/Build Number:      4/1      
| Reference:                     BJC008
| Description for Modification:  Flag study_review=Y CT terms for reporting in .LST file
| Reason for Modification:       Ensure review of CT mappings that arent generic.
|
| Modified By:                   Deepak Sriramulu  
| Date of Modification:          03May2011
| New Version/Build Number:      5/1      
| Reference:                     DSS001
| Description for Modification:  Flag case versus total differences
| Reason for Modification:       Assist review of outputs
|
| Modified By:                   Ashwin Venkat(VA755193)  
| Date of Modification:          10May2011
| New Version/Build Number:      5/1      
| Reference:                     VA001
| Description for Modification:  invalid values for extensible codelist appears in log when 
| Reason for Modification:       there are study review terminology issues. Corrected to report only 
|                                 terminology issues.
|								 
| Modified By:                   Ashwin Venkat(VA755193)  
| Date of Modification:          04July2011
| New Version/Build Number:      6/1      
| Reference:                     VA002
| Description for Modification:  setting length of 200 to all variables that have CT mapping 
| Reason for Modification:       setting length of 200 to CT variables, so there will be no truncation 								 
|
| Modified By:                   Deepak Sriramulu  
| Date of Modification:          08Aug2011
| New Version/Build Number:      6/1      
| Reference:                     DSS002
| Description for Modification:  Modify SQL code not to check for --ALL rows
| Reason for Modification:       --TEST values were reported as CT issue when --TESTCD eq '--ALL'
|
| Modified By:                   Ashwin Venkat 
| Date of Modification:          18Oct2012
| New Version/Build Number:      7/1      
| Reference:                     VA003
| Description for Modification:  Added code to check CT in SUPP-- datasets 
| Reason for Modification:       if CT is having case/total difference in SUPP-- datasets then flag

*******************************************************************************/
%macro tu_sdtmconv_pst_codelist_recon(
);

/* Get the coded items from the master domain reference data */

data _recon_coded_domain_items(rename=(controlled=list_name 
                                domain=memname
                                variable_name=name));
 set reference (where=(index(controlled,'(')>0 or controlled=: 'BEFORE'));
 controlled=translate(controlled,'','(');
 controlled=left(translate(controlled,'',')'));
run;

/* VA003 : getting controlled terms for SUPP-- data from varmap*/
data _recon_codelist_varmap (rename=(domain=memname sdtm_var=name)keep = domain sdtm_var list_name);
    length domain $6;
    set varmap(where=(index(termap,'(')>0 ) );
    list_name=translate(termap,'','(');
    list_name=left(translate(list_name,'',')'));
    /* since only SUPP-- datasets will have termap populated append SUPP to domain*/
    domain = compress('SUPP'!!DOMAIN);

run;

data _recon_coded_domain_items ;
    set _recon_coded_domain_items _recon_codelist_varmap;
run;

/* Get a work dataset of the codelists and their details - this si done by using the domain variables
/  master reference table but only selecting entries with controlled lists i.e. bracket prefix or
/ those with a fixed list of values - and all these start with BEFORE.
/ This means default values such as AE, CM and others such as * and ISO8601 would not be selected */

data _recon_code_names(rename=(cdisc_submission_value=list_name codelist_extensible=cltype) 
                keep=cdisc_submission_value code codelist_extensible) ;
 set codelist_details;

 if codelist_code ='HEADER' then do;
  if codelist_extensible=:'Y' then codelist_extensible='E';
  else if codelist_extensible=:'N' then codelist_extensible='F';
  output _recon_code_names;
 end;
run;

/* some variables are not controlled using lists, instead lists of valid values are used for each
/ item as the same values dont apply across all items so a list cant be used. */

data _recon_sub_list(keep=codelist_code cdisc_submission_value type);
 set reference(where=(Controlled=:'BEFORE'));
   codelist_code=variable_name;
   Controlled=compress(Controlled);
   posn=index(Controlled,',');
   codelist_extensible='F';
    if posn=0 then output;                         			
    else if posn >=1 then do;                      			
      len_all=length(trim(Controlled));						
      len_comma=length(trim(compress(Controlled,',')));			
      num_commas=(len_all-len_comma);
      clause=Controlled;								
       do a=1 to num_commas+1;							
   	 if a<=num_commas then do;						
           cdisc_submission_value=substr(clause,1,index(clause,',')-1);			
           clause=substr(clause,index(clause,',')+1,length(trim(clause))-index(clause,',')); 
   	  output;									
   	 end;										
   	 else if a=num_commas+1 then do;					
   	  cdisc_submission_value=substr(clause,1,length(clause));
           output;									
   	 end;										
       end;										
   end;
run;


/* Append the two sets of data with all valid values for the two types of controlled terms */
data _recon_codelist_details;   
 set codelist_details _recon_sub_list ;
run;

/* Join with domain data actually present to get list of current variables to check 
/  Two queries needed - the first for items that are controlled by codelists and the
/  second for items with non-codelist valid values e.g. AEENRTPT. The code reconciles 
/  both types of data/items */

proc sql noprint;
 create table _recon_lists_present1 as
 select dc.memname, cdi.name, cdi.list_name, cn.code
   from dictionary.columns dc,
        _recon_coded_domain_items cdi,
        _recon_code_names cn
  where dc.libname='PST_SDTM' 
    and dc.memname=cdi.memname
    and (dc.name=cdi.name or dc.name='QNAM')
    and cn.list_name=cdi.list_name;
    
create table _recon_lists_present2 as
 select dc.memname, cdi.name, dc.name as list_name, dc.name as code
   from dictionary.columns dc,
        _recon_coded_domain_items cdi,
        (select distinct codelist_code from _recon_sub_list) sl
  where dc.libname='PST_SDTM' 
    and dc.memname=cdi.memname
    and (dc.name=cdi.name or dc.name ='QNAM')
    and cdi.name=sl.codelist_code;    
quit;
/* Combine the two lists into one dataset */
data _recon_lists_present ; 
 set _recon_lists_present1
     _recon_lists_present2;
run;     

/* apply SDTM SAS formats (from term_map) for controlled term mapping that we already know about */

proc sql noprint;
 create table _recon_format as
 select * from _recon_lists_present1
 where list_name in (select distinct list_name from to_format);
quit;

/*BJC006: sort and flag the data so we can process by source dataset/memname */
proc sort data =_recon_format;
by memname name;run;

data _recon_format;
 set _recon_format;
 by memname name;
 fm=first.memname;lm=last.memname;
run;

%if %eval(%tu_nobs(_recon_format))>=1 %then %do;

 /* VA002: resetting lengths for variables that have CT mapping - adding another loop per domain */  
 proc sql noprint; 
  select count(distinct memname) into :num_mem from _recon_format;
 quit;
 proc sql noprint;
 select distinct memname into :mem1 - :mem%left(&num_mem) from _recon_format;
 quit;

 %DO M=1 %TO &num_mem;
 
  proc sql noprint;
   create table _recon_format_&&mem&m as 
   select * from _recon_format
   where memname="&&mem&m";
 
  proc sql noprint;
  select memname, name, list_name, fm, lm
   into :memname1- :memname%left(%eval(%tu_nobs(_recon_format_&&mem&m))),
        :name1- :name%left(%eval(%tu_nobs(_recon_format_&&mem&m))),
        :list_name1- :list_name%left(%eval(%tu_nobs(_recon_format_&&mem&m))),
        :fm1- :fm%left(%eval(%tu_nobs(_recon_format_&&mem&m))),
        :lm1- :lm%left(%eval(%tu_nobs(_recon_format_&&mem&m)))
    from _recon_format_&&mem&m
   order by memname, name;
  quit;

  ** BJC006: process the formats for each dataset in one swoop for efficiency purposes **;

   %DO w=1 %TO %eval(%tu_nobs(_recon_format_&&mem&m));
    %let _cmd = %str(Applying &&list_name&w SDTM format to &&name&w in &&memname&w to decode controlled terms);%tu_sdtmconv_sys_message;
   %end;
 
   %DO w=1 %TO %eval(%tu_nobs(_recon_format_&&mem&m));

    %if &&fm&w=1 %then %do;
     data pst_sdtm.&&memname&w; 
    %end;
    %if %index(&&memname&w,%str(SUPP)) eq 0 %then %do; 
	 /* VA002: resetting lengths for variables that have CT mapping */  
	 length &&name&w $200;
    %end;
    %if &&lm&w=1 %then %do; 
      set pst_sdtm.&&memname&w;
    %end; 
   %end;
   %DO w=1 %TO %eval(%tu_nobs(_recon_format_&&mem&m));
        /*BJC008: keep the old version for later reference in this macro */
        
        %if %index(&&memname&w, SUPP) gt 0 %then %do;
            if compress(qnam) = "&&name&w" then do;
                old_qval=qval;
                qval=put(trim(qval),&&list_name&w...);
            end;
        %end;
        %else %do;
        old_&&name&w=&&name&w;    
        &&name&w=put(trim(&&name&w),&&list_name&w...);
        %end;
    %if &&lm&w=1 %then %do;
        run; 
    %end;
  %end; 
 %end;
%end; 


*********************************************************************************;
/* Now formats have been applied to give known decodes, the code will go through each item with 
/  controlled terminology and check if data conforms to CT and flag if not */

proc sql noprint;
 select count(*) into :dsobs from _recon_lists_present;
quit;

%if &dsobs=0 %then %goto endmac;

/* Create driver macro variables */
proc sql noprint;
select memname, name, list_name, code
  into :memname1- :memname%left(&dsobs),
       :name1- :name%left(&dsobs),
       :list_name1- :list_name%left(&dsobs),
       :code1- :code%left(&dsobs)       
  from _recon_lists_present
 order by memname, name;
quit;

** Template problem collection dataset**;
data _recon_collect;
 attrib memname   length=$32;
 attrib value     length=$200;
 memname='';
 attrib name      length=$32;
 attrib list_name length=$52;
 attrib code      length=$8;
 /* BJC008 : add TYPE column to classify output rows */
 attrib type      length=$2;
 stop;
run;

%let _cmd = %str(Check that CT controlled data maps to CDISC controlled or extensible terms);%tu_sdtmconv_sys_message;

%do k = 1 %to &dsobs;
   proc sql noprint;
/* DSS001 */
  create table dist_val&k as select distinct 
  %if %index(&&memname&k,SUPP) EQ 0 %then %do;
    &&name&k 
  %end;
  %else %do;
    qval 
  %end;
       %if &&name&k=DSDECOD and %length(%tu_chkvarsexist(pst_sdtm.&&memname&k,&&memname&k..CAT))=0 %then %do;
	    ,DSCAT
	   %end;
	   %if &&memname&k=EG and &&name&k=EGSTRESC %then %do;
         ,EGCAT, EGTESTCD
       %end;	
 	   %if (&&name&k=MBSTRESC or &&name&k=MSSTRESC) and %length(%tu_chkvarsexist(pst_sdtm.&&memname&k,&&memname&k..CAT))=0 %then %do;
         , &&memname&k..CAT
	   %end;	 
  from pst_sdtm.&&memname&k
  
  /* DSS002: Don't check for CT issues for --TESTCD & --TEST when --TESTCD eq '--ALL' */
    %if (&&name&k=&&memname&k..TESTCD or &&name&k=&&memname&k..TEST) %then 
	%do; 
	   where substr(&&memname&k..TESTCD,3,3) ne 'ALL'
	%end;
    %if %index(&&memname&k,SUPP) gt 0 %then %do;
        where qnam ="&&name&k"
    %end;
	;

  create table _recon_nomatch&k as 
  select distinct
  %if %index(&&memname&k,SUPP) eq 0 %then %do;
     &&name&k
  %end;
  %else %do;
    qval
  %end;
  as value,
         "&&code&k" as code,
         "&&memname&k" as memname,
         "&&name&k" as name,
         "&&list_name&k"  as list_name,
         cdisc_submission_value as cds,
         /* DSS001 - add CASE statements */
		 case cdisc_submission_value
          when 
          %if %index(&&memname&k,SUPP) eq 0 %then %do;
               &&name&k
          %end;
          %else %do;
               qval
          %end;
          then ''    /* If the values are exactly the same, the flag is blank */
          when '' then 'TOTAL'     /* If no matching values were found when both sides where uppered, it?s a total mismatch */
          else 'CASE'              /* Anything else must be a case mismatch */
         end as FLAG
		 /* DSS001 */
         %if %index(&&memname&k,SUPP) EQ 0 %then %do;
                 from dist_val&k left join (select codelist_code, cdisc_submission_value
	        								from _recon_codelist_details where codelist_code="&&code&k" or codelist_code="&&name&k")
                 on trim(upper(&&name&k)) = trim(upper(cdisc_submission_value))		 
                 where &&name&k is not null 
	        	 and trim(&&name&k) ^= trim(cdisc_submission_value)	
            
            /*DSS001 - remove main WHERE clauses as now in CASE statements above and amend where clause below */ 				   
	        /* DSS001 end of this change */
	        
	        /* BJC001: amend EGTESTCD^='OTHER' to EGTESTCD^='OTHERABN' */
	         %if &&memname&k=EG and &&name&k=EGSTRESC %then %do;
               and EGCAT='FINDING' and EGTESTCD^='OTHERABN'
             %end;	  
             
            /*BJC003 - update specific CT check for MB/MS domains */
            
             %if (&&name&k=MBSTRESC or &&name&k=MSSTRESC) and %length(%tu_chkvarsexist(pst_sdtm.&&memname&k,&&memname&k..CAT))=0 %then %do;
              and &&memname&k..CAT^='ORGANISM' 
              and trim(&&memname&k..CAT) in (select trim(cdisc_submission_value)
                                         from _recon_codelist_details where codelist_code='C85491')
             %end;     
            
            /*BJC007 - update specific CT check for DS domain DSDECOD */
            
             %if &&name&k=DSDECOD and %length(%tu_chkvarsexist(pst_sdtm.&&memname&k,&&memname&k..CAT))=0 %then %do;
              and &&memname&k..CAT='PROTOCOL EVENT' 
              and trim(&&memname&k..CAT) in (select trim(cdisc_submission_value) 
                                         from _recon_codelist_details where codelist_code='C66727')
             %end;     
                   ;
        %end;
        %else %do;
                 from dist_val&k left join (select codelist_code, cdisc_submission_value
	        								from _recon_codelist_details where codelist_code="&&code&k" or codelist_code="&&name&k")
                 on trim(upper(qval)) = trim(upper(cdisc_submission_value))		 
                 where qval is not null 
	        	 and trim(qval) ^= trim(cdisc_submission_value)	
        ;
        %end;

 quit;    
 
 /* BJC008: add new step to proc sql to collect CT flaged as study_review */
 proc sql noprint;                  
     create table _recon_sr&k as 
       select distinct 
       %if %index(&&memname&k,SUPP) eq 0 %then %do;
            &&name&k
       %end;
       %else %do;
            qval
       %end; 
       as value,
              "&&code&k" as code,
              "&&memname&k" as memname,
              "&&name&k" as name,
              "&&list_name&k"  as list_name
      from pst_sdtm.&&memname&k 
     where 
        %if %index(&&memname&k,SUPP) eq 0 %then %do;
            &&name&k is not null and &&name&k in (select trim(sdtm_value) from term_map
                           where code="&&code&k" and list_name="&&list_name&k" and study_review='Y')
           /* If there is a format created then multiple source values may feed one sdtm value, so check this too */
           %if %length(%tu_chkvarsexist(pst_sdtm.&&memname&k,old_&&name&k))=0  %then %do;                         
              and old_&&name&k in (select trim(source_value) from term_map
                           where code="&&code&k" and list_name="&&list_name&k" and study_review='Y')
           %end; 
           ;
       %end;
       %else %do;
           qval is not null and qnam ="&&name&k" and qval in (select trim(sdtm_value) from term_map
                           where code="&&code&k" and list_name="&&list_name&k" and study_review='Y')
           /* If there is a format created then multiple source values may feed one sdtm value, so check this too */
           %if %length(%tu_chkvarsexist(pst_sdtm.&&memname&k,old_qval))=0  %then %do;                         
              and old_qval in (select trim(source_value) from term_map
                           where code="&&code&k" and list_name="&&list_name&k" and study_review='Y')
           %end; 
           ; 
       %end; 
                     
                                    
 quit;  


 /* Append any results to collection dataset */
 /* BJC008 : append _recon_sr<n> datasets */
 data _recon_collect; 
  set _recon_collect
      _recon_nomatch&k(in=a)
      _recon_sr&k(in=b);
  if a then type='CT';
  else if b then type='SR';
 run;
 
%end;

/* due to use of select distinct **cat etc variables above - there may be occasional duplciates reported - remove these */
proc sort data=_recon_collect nodupkey;
by _all_;
run;

/* BJC008: Now drop the original value that had the formats applied - we only needed it to 
           check for study review CT and can now drop it */

%if %eval(%tu_nobs(_recon_format))>=1 %then %do;

 proc sql noprint;
 select memname, name, list_name, fm, lm
  into :memname1- :memname%left(%eval(%tu_nobs(_recon_format))),
       :name1- :name%left(%eval(%tu_nobs(_recon_format))),
       :list_name1- :list_name%left(%eval(%tu_nobs(_recon_format))),
       :fm1- :fm%left(%eval(%tu_nobs(_recon_format))),
       :lm1- :lm%left(%eval(%tu_nobs(_recon_format)))
   from _recon_format
  order by memname, name;
 quit;
           
 %DO w=1 %TO %eval(%tu_nobs(_recon_format));
  
     %if &&fm&w=1 %then %do;
       data pst_sdtm.&&memname&w; 
        set pst_sdtm.&&memname&w;
     %end; 
     %if %index(&&memname&w,SUPP) eq 0 %then %do;
             drop old_&&name&w;                
             %if &&lm&w=1 %then %do;
             run; 
             %end; 
     %end;
     %else %do;
             %if &&lm&w=1 %then %do;
             drop old_qval;
             run;
             %end;
    %end;
 %end;
%end;

/* Add the controlled list type E=extensible and F=fixed */
proc sql noprint;
 alter table _recon_collect add cltype char(9);
 
 update _recon_collect cl set cltype=
  (select cltype 
     from _recon_code_names cn
    where cn.code=cl.code);
quit;    

/* BJC004: Clean up the issues to remove any that are GSK extensible terminology mappings 
/  This section of code moved here from tu_sdtmconv_sys_print macro.*/

proc sql noprint;
   create table _CT_removed as select * from _recon_collect
    where trim(list_name)||trim(code)||trim(value)
       in (select trim(list_name)||trim(code)||trim(sdtm_value)
             from term_map where ext_term='Y');
 
   delete from _recon_collect
    where trim(list_name)||trim(code)||trim(value)
       in (select trim(list_name)||trim(code)||trim(sdtm_value)
             from term_map where ext_term='Y');
quit;            

/* Add issue description for later reporting */
data _report_collect; 
 set _recon_collect;
  attrib problem_desc length=$60 ;
  attrib problem_desc_full length=$230;
  /* If cltype is null it is one of the items with a list of values supplied separately in the REFERENCE data source 
  /  In this case default to F(ixed) */
  if cltype='' then cltype='F';
  /* BJC008 : process the two types with appropriate text */
  if type='CT' and flag ='TOTAL' then do;
   problem_desc_full='* '||left(trim(value))||' not in '||trim(list_name)||':'||trim(code)||'('||trim(cltype)||')';
   /* BJC005: put as much of the text string as possible to the output issue listing */
   problem_desc='* '||trim(substr(value,1,39))||' not in '||trim(list_name)||'('||trim(cltype)||')';
  end;
  /* DSS001 - add ! flag for case differences in CT*/
  if type='CT' and flag ='CASE' then do;  
   problem_desc_full='*!'||left(trim(value))||' not in '||trim(list_name)||':'||trim(code)||'('||trim(cltype)||')';
   /* BJC005: put as much of the text string as possible to the output issue listing */
   problem_desc='*!'||trim(substr(value,1,39))||' not in '||trim(list_name)||'('||trim(cltype)||')';
   end; 
  if type='SR' then do;
   problem_desc_full='* Study Review: '||left(trim(value))||' for '||trim(list_name)||':'||trim(code)||'('||trim(cltype)||')';
   /* BJC005: put as much of the text string as possible to the output issue listing */
   problem_desc='* Study Review: '||trim(substr(value,1,30))||' in '||trim(list_name)||'('||trim(cltype)||')';
  end; 
  
run;

/* Report to the log any non-valid entries for data being processed */
proc sql noprint;
 select count(*) into :num_fixed 
   from _recon_collect 
  where cltype='F';
quit;  

/* BJC004 - for clarity separate out issues for Fixed and Extensible lists */
%if &num_fixed >=1 %then %do;
  %let _cmd = %str(%str(RTE)RROR: One or more invalid entries for Fixed codelist/controlled terminology. Review and decode/correct the values.); 
  %tu_sdtmconv_sys_message;
%end;
/* VA001: modified to report only Terminology mapping issues and not study review issues*/
/* Report to the log any non-valid entries for data being processed */
proc sql noprint;
 select count(*) into :num_fixed 
   from _recon_collect 
  where cltype='E' and type='CT';
quit;  

%if &num_fixed >=1 %then %do;
  %let _cmd = %str(%str(RTW)ARNING: One or more invalid entries for Extensible codelist/controlled terminology. Review and decode/correct the values.); 
%tu_sdtmconv_sys_message;
%end;

%if &sysenv=BACK %then %do;  
 
%tu_tidyup(
rmdset = _recon_:,
glbmac = none
); 
%end;

%endmac:

%mend tu_sdtmconv_pst_codelist_recon;

