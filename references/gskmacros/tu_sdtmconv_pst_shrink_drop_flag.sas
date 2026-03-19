/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_pst_shrink_drop_flag
|
| Macro Version/Build:  7/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009
|
| Macro Purpose:        Flag any missing values in required and expected items
|
|                       Create any empty expected columns that are not present
|
|                       Check length of --TEST and --TESTCD contents dont exceed
|                       limits
|
|                       Resize char columns from default $200 to minimum needed
|                       - sometimes length can be $1 to make domain datasets
|                         smaller
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
| (@)tu_sdtmconv_sys_message
| (@)tu_tidyup
|
| Example:
|
| %tu_sdtmconv_pst_shrink_drop_flag
|
|*******************************************************************************
| Change Log:
|
| Modified By:                 Bruce Chambers
| Date of Modification:        23august2010
| New Version/Build Number:    2/1      
| Reference:                   bjc001
| Description for Modification:Correctly report missing required columns
| Reason for Modification:     Correctly report missing required columns in all data scenarios
|
| Modified By:                 Bruce Chambers
| Date of Modification:        18October2010
| New Version/Build Number:    3/1
| Reference:                   bjc002
| Description for Modification:Amend SDTM libname to SDTMDATA
| Reason for Modification:     Preparation for new HARP release
|
| Modified By:                 Bruce Chambers
| Date of Modification:        05November2010
| New Version/Build Number:    4/1
| Reference:                   bjc003
| Description for Modification:Correct the SQL to build all_sdtm_vars, crt_exp_vars and missing_vars
|                              Add RELREC to list of additional datasets, and move the statement
|                              that strips formats to be after the set, not before.
| Reason for Modification:     Ensure processing of ALL non IDSL sourced domains 
|                              and that any (in)formats present are removed.
|
| Modified By:                 Bruce Chambers
| Date of Modification:        05November2010
| New Version/Build Number:    5/1
| Reference:                   bjc004
| Description for Modification:Correct the SQL to build crt_exp_vars                         
| Reason for Modification:     SUPPDM.IDVAR(VAL) were not being identified as missing
|
| Modified By:                 Ashwin Venkat	
| Date of Modification:        07Feb2011
| New Version/Build Number:    5/1
| Reference:                   VA001
| Description for Modification:correct variable order, Exp variables with missing value were added in the end                  
| Reason for Modification:     correct labels, Exp variables with missing values were not having labels 
|
| Modified By:                 Ashwin Venkat	
| Date of Modification:        17Aug2011
| New Version/Build Number:    6/1
| Reference:                   VA002
| Description for Modification:resolved variable resize issue                 
| Reason for Modification:     variables like usubjid were not getting resized for all the variables 
|
| Modified By:                 Bruce Chambers	
| Date of Modification:        04Oct2012
| New Version/Build Number:    7/1
| Reference:                   BJC005
| Description for Modification:For TD domains, SE, RELREC, instead of referring to SDTMDATA lib, use PST_SDTM                
| Reason for Modification:     The TD domains, SE, RELREC are copied to PST_SDTM. tu_sdtmconv_pst_drop_null_cols 
|                              macro before this drops permissible columns where all values are null. This macro
|                              should also use the same data (not the original SDTMDATA) to check here and onwards.
*******************************************************************************/
%macro tu_sdtmconv_pst_shrink_drop_flag(
);

/* First - create any missing expected columns. Dont create missing required columns
/  as the user must go and find or create the data for required columns              */

/*BJC003: modify queries to build driver datasets to correctly pick up missing vars in non CRF domain */
proc sql noprint;

 create table all_sdtm_vars as 
 select distinct libname, memname, name, type
 from dictionary.columns
 where libname='PST_SDTM'
 and (memname in (select domain from sdtm_dom)
      or memname in (select 'SUPP'||trim(domain) from sdtm_dom))

 %if &tab_list eq and &tab_exclude eq and %length(&subset_clause)=0 %then %do;
      union     
      select libname, memname, name, type
        from dictionary.columns
		/* BJC005 : amend SDTMDATA libname to PST_SDTM */
       where libname='PST_SDTM'
         and memname in ('TA','TE','TS','TI','TV','SE','RELREC')
 %end;
 order by memname, name;

create table crt_exp_vars as 
  (select dc.memname, ref.variable_name as name, ref.core, ref.type, dc.libname
    from (select * from reference where core ='Exp') ref, dictionary.tables dc
   where dc.libname ='PST_SDTM'
   and (dc.memname in (select domain from sdtm_dom)
        or dc.memname in (select 'SUPP'||trim(domain) from sdtm_dom))  
   and (dc.memname =ref.domain
        or substr(dc.memname,1,4)=ref.domain)     
   and trim(dc.memname)||trim(ref.variable_name) not in
       (select trim(memname)||trim(name) from all_sdtm_vars)  
  %if &tab_list eq and &tab_exclude eq and %length(&subset_clause)=0 %then %do;
   UNION
   select dc.memname, ref.variable_name as name, ref.core, ref.type, dc.libname
       from (select * from reference where core ='Exp') ref, dictionary.tables dc
   where ref.domain=dc.memname
   /* BJC005 : amend SDTMDATA libname to PST_SDTM */
   and dc.libname ='PST_SDTM' 
   and dc.memname in ('TA','TE','TI','TS','TV','SE','RELREC')
   and dc.memname in (select domain from sdtm_dom)
   and trim(dc.memname)||trim(ref.variable_name) not in
       (select trim(memname)||trim(name) from all_sdtm_vars)
  %end;   
     ); 
quit;

%let dsobs= %eval(%tu_nobs(crt_exp_vars));
%if &dsobs>=1 %then %do;  
 %let _cmd = %str(%str(RTN)OTE: TU_SDTMCONV_PST_SHRINK_DROP_FLAG: Creating additional expected variables as empty columns in the DOMAINs);%tu_sdtmconv_sys_message;
 %let _cmd = %str(%str(RTN)OTE: TU_SDTMCONV_PST_SHRINK_DROP_FLAG: REQUIRED variables will NOT be created empty/blank- they must be populated);%tu_sdtmconv_sys_message;

 /* summary listing of dropped and flagged columns printed out at the end of the run by sdtm_print */
 
 /* format chat and num string correct for proc sql alter table statement */
 data crt_exp_vars;
  attrib type length=$7 format=$7.;
  set crt_exp_vars;
  if type='Char' then type='char(1)';
  if type='Num' then type='numeric';
 run;
 
 /* Generate macro vars for each change */
 proc sql noprint;
  select distinct libname, memname, name, type
     into :exp_lib1- :exp_lib%left(&dsobs),
          :exp_dset1- :exp_dset%left(&dsobs),
          :exp_nm1- :exp_nm%left(&dsobs),
          :exp_ty1- :exp_ty%left(&dsobs)          
     from crt_exp_vars
    order by libname, memname, name;
 quit;

 /* apply the alter table commands to create empty expected columns */

 proc sql noprint;
  %do e=1 %to &dsobs;
    alter table &&exp_lib&e...&&exp_dset&e add &&exp_nm&e &&exp_ty&e ;
  %end;
 quit;

 %do e=1 %to &dsobs;
  %let _cmd = %str(Created empty EXPECTED column &&exp_nm&e in the &&exp_dset&e DOMAIN);%tu_sdtmconv_sys_message; 
 %end;

%end;
proc sql noprint ;
/*VA001: recreating all_sdtm_vars dataset, so it gets updated with expected variables that were added newly */

create table all_sdtm_vars as 
 select distinct libname, memname, name, type
 from dictionary.columns
 where libname='PST_SDTM'
 and (memname in (select domain from sdtm_dom)
      or memname in (select 'SUPP'||trim(domain) from sdtm_dom))

 %if &tab_list eq and &tab_exclude eq and %length(&subset_clause)=0 %then %do;
      union     
      select libname, memname, name, type
        from dictionary.columns
       where libname='PST_SDTM'
         and memname in ('TA','TE','TS','TI','TV','SE','RELREC')
 %end;
 order by memname, name;
quit;
*****************************************************************************************;

/* Create various meta datasets that act as driver datasets for later steps,
/  also the final steps in the proc sql create macro variable lists of the datasets 
/  to process. 
/  For full runs i.e. where spec_tabs/tab_list/tab_exclude is not used, also check the TD datasets if present */

/* BJC002 : amend libname SDTM to SDTMDATA below */
/* BJC003 : add RELREC to list of non-CRF domains and update missing_vars query */
  
proc sql noprint;
 
 create table sdtm_vars as 
  select distinct asv.* ,ref.label, ref.var_order
  from all_sdtm_vars asv, reference ref
  where ((asv.memname=ref.domain) 
          or (substr(asv.memname,1,4)='SUPP' and ref.domain='SUPP'))
    and asv.name=ref.variable_name
 order by memname, var_order;

 create table invalid_vars as 
  ((select memname, name 
      from all_sdtm_vars 
     where substr(memname,1,4)^='SUPP'  
       and memname in (select domain from sdtm_dom))
   except
   (select domain as memname, variable_name as name 
    from reference));

 create table missing_rvars as 
     select r.domain as memname, r.variable_name as name, r.core, dc.libname
       from (select * from reference where core in ('Req')) r, 
            dictionary.tables dc
      where r.domain=dc.memname
      and ((dc.libname ='PST_SDTM' )    
       %if &tab_list eq and &tab_exclude eq and %length(&subset_clause)=0 %then %do;     
            OR
			/* BJC005 : amend SDTMDATA libname to PST_SDTM */
               (dc.libname ='PST_SDTM'       
             and dc.memname in ('TA','TE','TI','TS','TV','SE','RELREC'))
       %end; 
       )
      and dc.memname in (select domain from sdtm_dom)
      and trim(r.domain)||trim(variable_name) not in
         (select trim(memname)||trim(name) from all_sdtm_vars)
  order by memname, name;
      
 alter table sdtm_vars add max_len numeric;

 select count(*) into :num_vars from sdtm_vars where type='char';

 select memname, name, libname
  into :sdtm_dset1- :sdtm_dset%left(&num_vars),
       :sdtm_name1- :sdtm_name%left(&num_vars),
       :sdtm_lbnm1- :sdtm_lbnm%left(&num_vars)
  from sdtm_vars
 where type='char'
 order by memname, var_order;

 select count(distinct memname) into :num_dsets from sdtm_vars;

quit;

*************************************************************************;
/* Draw user attention to any errors by putting string in the log file */
%if %eval(%tu_nobs(invalid_vars))>=1 %then %do;
 %let _cmd = %str(%str(RTW)ARNING: Variables present that are not valid in the DOMAINs);%tu_sdtmconv_sys_message;
 /* Data printed out at the end of the run by tu_sdtmconv_sys_print */
%end;

/* Only put out error if missing Required variables need addressing, 
/  missing expected variables get an empty column created earlier  */
/* BJC001 : add step to make sure the missing required variables warning only identifies these rows and not 
/  expected ones e.g. if TD domains present then TV.ARMCD will usually get added as expected here */

%if %eval(%tu_nobs(missing_rvars))>=1 %then %do;

 %let _cmd = %str(%str(RTW)ARNING: Variables missing that are required in the DOMAINs);%tu_sdtmconv_sys_message;
 /* Data printed out at the end of the run by tu_sdtmconv_sys_print */
%end;

/* Add to missing vars the list of expected vars created as empty columns
/  so the detail gets listed later */
data missing_vars;
 set missing_rvars
     crt_exp_vars(keep=memname name core);       
run;     
/*AV002: some domains did not get resized because of Tx domains getting resized in both 
sdtm_data and in pst_sdtm , resolved issue by hardcoding to pst_sdtm*/

****************************************************************************************;
/* Update driver dataset with max length of content for all the char items in all domains 
   Create macro vars for the libname and dataset combinations to process */
proc sql noprint;
 %do i = 1 %to &num_vars;
   update sdtm_vars set max_len=(select max(length(&&sdtm_name&i)) 
   from &&sdtm_lbnm&i...&&sdtm_dset&i sdtm)
   where name="&&sdtm_name&i"
     and type='char'
     and memname="&&sdtm_dset&i";
 %end;
 
 %do j = 1 %to &num_dsets;
  select distinct memname
    into :sdtm_dset1- :sdtm_dset%left(&num_dsets)
    from sdtm_vars
    order by memname;
 %end;
quit;

********************************************************************************;
/* Now we have the metadata, write some attrib statements to reduce the size of
   all char vars from 200 to whatever is needed (i.e. max size of the content).
    Also - set null formats and informats on all data */
   
%do k = 1 %to &num_dsets;
 proc sql noprint;
 select  count(name)
      into :sdtm_count
      from sdtm_vars
	  where memname="&&sdtm_dset&k"
      group by memname;
 quit;

 proc sql noprint;
  select  max_len, label, type, name
    into  :this_len1- :this_len%left(&sdtm_count),
          :this_label1- :this_label%left(&sdtm_count),
          :this_type1- :this_type%left(&sdtm_count),
          :this_name1- :this_name%left(&sdtm_count)
    from sdtm_vars
	where memname="&&sdtm_dset&k"
    order by var_order;
  quit;

  data pst_sdtm.&&sdtm_dset&k ;

   %do l=1 %to &sdtm_count;
    attrib &&this_name&l label="&&this_label&l"

    %if &&this_type&l=char %then %do;
     length=$&&this_len&l
    %end; 
    ;
   %end;
   set pst_sdtm.&&sdtm_dset&k;
   
   /* BJC003: Move this format and informat removal to after the set statement */
   %do l=1 %to &sdtm_count;
        format   &&this_name&l;
        informat &&this_name&l;
   %end;
   
    format STUDYID DOMAIN VISIT VISITNUM;
    informat STUDYID DOMAIN VISIT VISITNUM;
  run;

%end;

************************************************************************************;
/* Perform some checking of data attributes - for reporting later if issues found */

data length_issues(drop=type label var_order); 
 set sdtm_vars;
 attrib problem_desc length=$60;
 attrib ordervar length=$3;
 if length(trim(name))>4 then do;

  if length(trim(name))>6 then do;

   if max_len>8 and substr(reverse(trim(name)),1,6)='DCTSET' then do;
    problem_desc='* >=1 xxTESTCD value > 8 chars in length: max length='||compress(put(max_len,8.));
    compare=8;ordervar ='A1';
    output;
   end;
  end;
  
  if max_len>40 and substr(reverse(trim(name)),1,4)='TSET' and name not in ('IETEST','TITEST') then do;
    problem_desc='* >=1 xxTEST value > 40 chars in length: max length='||compress(put(max_len,8.));
    compare=40;ordervar ='B1';
    output;
  end;

 end; 
  
 if max_len>200  then do;
   problem_desc='* >=1 data value >200 chars in length: max length='||compress(put(max_len,8.));
   compare=200;ordervar ='C1';
   output;
 end; 
 
run; 

****************************************************************************************;
/* Flag errors in log and create datasets of any content length issue to report later */
%if %eval(%tu_nobs(length_issues))>=1 %then %do;
 %let _cmd = %str(%str(RTW)ARNING: Issues with length of some fields defined in the DOMAINs);%tu_sdtmconv_sys_message;
 /* Data printed out at the end of the run by tu_sdtmconv_sys_print */
%end;

data _report_length_issues; 
 set length_issues;
 num=_n_;
run; 

/* Create empty template dataset */
data len_issue_detail;
 length ordervar $5; 
 length problem_desc $60
 length text $200 problem_desc_full $230;
 length memname $32;
run; 

%do m=1 %to %eval(%tu_nobs(length_issues));

  /* For each column with issues, generate more detail to report */
   data _null_ ;set _report_length_issues (where=(num=&m));
    call symput('libname',trim(libname));
    call symput('memname',trim(memname));
    call symput('name',trim(name));
    call symput('compare',trim(compare));
    call symput('ordervar',trim(ordervar));
  run;

 /* Produce output listing for each invalid entry */
 proc sql; 
  create table too_big as 
  select distinct &name as text, 
         "&ordervar"||'2' as ordervar, 
         "&memname" as memname, 
         '* Value too long:' as problem_desc ,       
         '* Value too long:' as problem_desc_full
    from &libname..&memname 
   where length(&name)>&compare;
 quit;
 
 data len_issue_detail;
  set len_issue_detail(where=(ordervar^='')) too_big;
 run; 
%end;

/* Prepare data for later listing in user output */
data _report_len_issue_detail(drop=text);
 set len_issue_detail(where=(memname^=''));
  problem_desc=trim(problem_desc)||trim(text);
  problem_desc_full=trim(problem_desc_full)||trim(text);
run; 

%if &sysenv=BACK %then %do;  

%tu_tidyup(
 rmdset = len_issue_:,
 glbmac = none
);

%tu_tidyup(
 rmdset = length_issue_:,
 glbmac = none
);

%end;
%mend tu_sdtmconv_pst_shrink_drop_flag;

