/*************************************************************************************************
|
| Macro Name:           ta_gen_define_meta
|
| Macro Version/Build:  4/2
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 26-Mar-2010
|
| Macro Purpose:        Part 1:Study definitions: dataset and variable details:
|                       Queries to return dataset and variable attributes.
| 
|                       Part 2: Value Level Metadata:
|                       Generate list of distinct combinations of value level metadata
|                       from SDTM domain SAS datasets for a given study (libname).
|
|                       The actual value level metadata (--TEST and --TESTCD values) will
|                       differ from domain to domain, and differ from study to study. The 
|                       only way to get these details is to interrogate the study data.
|
|                       This query uses the 1) Oracle UI database to identify both the 
|                       Findings and Findings About domains that are possible along with 
|                       the variable attributes from the UI database such as Role and CT definition, 
|                       then joins with the 2) SAS metadata dictionaries to return study  
|                       specific details for the study data to which a libname has been set.
|
|                       Part 3: Controlled terms:
|                       Return distinct controlled terms present in the study data.
|                       Based on advice from Randall Austin only provide the submission value
|
|                       The VLM attribute of the domain variable from the SDTMCONV UI database 
|                       is used to drive this query.
|
|                       Part 4: Computational algorithms from DSM and the SDTMCONV database
|
|                       Part 5: Generate a to_do list of missing pieces to draw users attention to
|
| Macro Design:         Procedure
|
| Input Parameters:     
| 
| NAME                DESCRIPTION                                  DEFAULT           
|
| SDTM_DB libname     Oracle libname to SDTM UI database	       N/A	   
| SDTMDATA libname    SAS libname to SDTM domain datasets          N/A
|
| Output:	      One (meta)dataset for each type of metadata needed with SDTMM_ (SDTM meta) prefix
|
| Global macro variables created:
|
| Macros called: None                
|
|
| Example:
|
|
|*******************************************************************************
| Change Log:
|
| Modified By:                  Bruce Chambers
| Date of Modification:         06December2010
| New Version/Build Number:     2/1
| Reference:                    bjc001
| Description for Modification: Use new fields from MSA database to populate REPEATING and ISREFERENCEDATA
|                               domain metadata fields
| Reason for Modification:      Population of MSA definitions to define.xml
|
| Modified By:                  Bruce Chambers
| Date of Modification:         06August2012
| New Version/Build Number:     3/1
| Reference:                    bjc002
| Description for Modification: Numerous changes for CDICE reporting tactical solution
| Reason for Modification:      Give users a better define.xml metadata starting point to work with in HARP
|
| Modified By:                  Bruce Chambers
| Date of Modification:         13March2013
| New Version/Build Number:     4/1
| Reference:                    bjc003
| Description for Modification: 1)Allow for non-default mapping for code/decode pairs e.g IDSL EVALINT/EVLINTCD
|                               2)Enforce restriction that CT can only be at lowest level between domain vars and VLM
|                               3)Add/action addition of comments and minor augmentation of code from recent SCR
|                               4)Filter runs to only run on content of RE SDTMDATA libname - not all converted data
|                               5)Remove code relic of hardcoded studyid in comp method section
|
| Reason for Modification:      1)Ensure correct sdtmm_define_ct  metadataset produced
|                               2)Ensure sdtmm_define_domain_vars is as HARP expects
|                               3)More commenting will assist review of the code. Also one step re-written in a better way.
|                               4)Ability to filter runs is more how HARP users can sometimes work and can also help support
|                               5)Correct execution of code for all studies
|
*******************************************************************************/

%macro gen_define_meta(
);
*********************************************************************************************;

/* Set HARP libname for process control */

LIBNAME _webout xml 
    %IF %LENGTH(&xml_outfile) GT 0 %THEN "&xml_outfile";
;

%global G_DEBUG;
%let g_debug=0;

/* Pick up parameters supplied by HARP application to this macro */
libname sdtm_db oracle username=&sdtm_user password=&sdtm_pass path=&sdtm_path;
libname dsm_db oracle username=&dsm_user password=&dsm_pass path=&dsm_path schema=spectre_ds_owner;
libname spec_db oracle username=&dsm_user password=&dsm_pass path=&dsm_path ;

libname sdtmdata "&sdtmdata_path";
libname sdtmmeta "&refdata_path";

/* First: Get the Spectre spec and related DSM details for the study */

proc sql; connect to oracle
   (user=&dsm_user orapw=&dsm_pass path=&dsm_path buffsize=500);

/* Query to get (max version of) var attributes from DSM for decodes (includes archived variables)*/
   
  create table dsm_attribs as select * from connection to oracle
    (select main.var_nm as name, main.var_short_desc, 
	 trim(decode(main.var_sas_datatype_desc,'Char','char','Numeric','num',main.var_sas_datatype_desc))		 
	 ||' '||trim(main.var_format) as src_data_type
       from spectre_ds_owner.var_v main,
            (SELECT  var_nm , max(version_no) as maxver
             FROM spectre_ds_owner.var_v
             GROUP BY var_nm) maxresults
      WHERE main.var_nm = maxresults.var_nm
        AND main.version_no = maxresults.maxver);   
 	   
/* Query to get DSM code-decode relationship metadata */

   create table dsm_var_rel as select * from connection to oracle
   (select code.var_nm as code, 
          decode.var_nm as decode
          from var_cat code,
               var_cat decode,
                var_relationship rel
            where rel.parent_var_cat_id=code.var_cat_id
              and rel.child_var_cat_id=decode.var_cat_id
              and var_rel_type_id=1);   	   

/* Query to get study SI spec from Spectre */   
/* BJC003: change 1. Remove curved brackets from codelist_nm as many are null here - add them later to popualted values */
create table spec as select * from connection to oracle
 (select %str(/)%str(*)+ use_nl(a,b,c) %str(*)%str(/)
       b.dataset_nm as si_dset, 
	   b.var_nm as si_var, 
	   a.spec_id,
	   b.codelist_nm,
       trim(decode(b.var_sas_datatype_desc,'Char','char','Numeric','num',b.var_sas_datatype_desc))
	   ||' '||trim(b.var_format) as src_data_type
    from study_spec_max_v a, 
         spec_ds_info_var_detail_v b
   where a.spec_id=b.spec_id
     and a.spec_type='01'    
     and a.study_id=upper(%unquote(%str(%')%upcase(&studyid)%str(%')))  
   order by b.dataset_nm, b.var_nm);			  
quit;

/* Re-direct any batch log to the refdata area for ease of review and support questions.
   If run interactively the log will not switch.
   We apply this after the oracle queries ran so passwords are not shown to users */

%if &sysenv ^= FORE %then %do;
 filename myfile "&refdata_path/ta_gen_define_meta.log";
 proc printto log=myfile;
 run;
 options source source2 notes;
%end;

%if &sqlobs=0 %then %do;
 %put ERROR: no rows found for Spectre spec for study &studyid - program aborting;
 data _null; 
 abort return;
 run;
%end; 

/* BJC002: efficiency change - only fetch from various DB tables once */

data vw_monitor_varmap;
 set sdtm_db.vw_monitor_varmap (where=(upcase(studyid)="&studyid"));
run;

/* BJC002: Get the SDTM version used for the study from the MSA monitor table */
proc sql noprint;
 select distinct count(distinct sdtm_ig_version) into :num_sdtm_ver 
   from vw_monitor_varmap 
  where sdtm_ig_version is not null;
   
 select distinct sdtm_ig_version into :sdtm_ver 
   from vw_monitor_varmap
  where sdtm_ig_version is not null ;   
quit;

%if &num_sdtm_ver ^=1 %then %do;
 %put ERROR: There are &num_sdtm_ver versions of SDTM present in transform metadata for this study, report to support staff.;
%end;   

/* Fetch domain level records from MSA database */
data vw_mapping_domain_ref ;
 set sdtm_db.vw_mapping_domain_ref(where=(upcase(status)='APPROVED' and sdtm_ig_version=%left(%trim("&sdtm_ver")) ));
run;

/* Fetch domain variable level records from MSA database */
data vw_mapping_domain_var_ref ;
 set sdtm_db.vw_mapping_domain_var_ref(where=(upcase(status)='APPROVED' and sdtm_ig_version=%left(%trim("&sdtm_ver")) ));
run;

/* Fetch source IDSL data group detail records from MSA database */
data vw_monitor_view_tab_list;
 set sdtm_db.vw_monitor_view_tab_list(where=(upcase(studyid)="&studyid" ));
run;

/* Fetch terminilogy mapping records from MSA database */
data term_map;
 set sdtm_db.vw_mapping_term_map(where=(upcase(status)='APPROVED'));
run;

/* Fetch master CDISC controlled term records from MSA database */
data cdisc_ct_main(keep=cdisc_submission_value codelist_name code codelist_code);
 set sdtm_db.vw_mapping_codelist_details;
run;

/* Extract from MSA Oracle the SI RULES data (data groups collected in normalised format) */
data si_rules(where=(pre_norm='Y'));
 set sdtm_db.vw_mapping_si_rules(where=(upcase(status)='APPROVED'));
run;

/* BJC003 - query for study specifc SI_RULE definitions */
data si_rules_ss(where=(pre_norm='Y'));
 set sdtm_db.vw_monitor_si_rules_ss(where=(upcase(studyid)="&studyid" ));
run;

/* BJC003 - append study specific ones to generic list */
data si_rules; 
 set si_rules si_rules_ss;
run;

/* Fetch CRF page numbers and domain-variable associations where present */
data pagesum;
 set sdtm_db.pagesum (where=(upcase(studyid)=upcase(%unquote(%str(%')%trim(&studyid)%str(%'))) ));
run;

/* BJC003 : filter spec, vw_monitor_varmap and vw_monitor_view_tab_list on just the SDTM domains in the RE
            To exclude SDTM domains that map from the study spec but are not (yet) imported to HARP is useful to do */

proc sql;
 delete from vw_monitor_varmap where domain not in (select memname 
                                                      from dictionary.tables 
													 where libname='SDTMDATA');			
 
 delete from spec where si_dset not in (select distinct si_dset from vw_monitor_varmap);
 
 delete from vw_monitor_view_tab_list where basetabname not in (select distinct si_dset from vw_monitor_varmap);
quit; 													 
			
/**************************************************************************************************/
/* Part 1: Two queries to produce domain and variable metadata by combining the SAS 
/  dictionary data for the actual SDTM domain data with the pertinent MSA UI database details needed.
/  NB: the keys field in MSA is a superset, not necessarily the keys actually present, so we filter */

/* bjc001: populate repeating and isreferencedata from MSA database instead of defaulting values */
proc sql;    
 create table sdtmmeta.sdtmm_define_domain_vars as
 select dc.memname as domain, 
        dc.name as variable_name, dvr.label, dvr.type, dvr.role, dvr.core, dvr.var_order, dvr.controlled,
        dc.length
 from vw_mapping_domain_ref dr,
      vw_mapping_domain_var_ref dvr,
      dictionary.columns dc
 where libname='SDTMDATA'
  and dvr.status='Approved'
  and dr.status='Approved'
  and (dc.memname=dr.domain 
         or substr(dc.memname,1,4)=dr.domain)
    and dr.domain=dvr.domain
    and dvr.variable_name=dc.name
  order by dc.memname, dvr.var_order;        
    
 /* BJC003 - improve code step below (based on SCR feedback ) */
 create table sdtmmeta_define_domain as
 select dt.memname as domain, dr.dom_desc, dr.dom_det, dr.dom_type, dr.dom_keys, dr.sdtm_ig_version,        
        case(repeating)
           when 'Y' then 'Yes'
           when 'N' then 'No'
         else
          'UNK' 
         end as repeating, 
        case (ISREFERENCEDATA)
           when 'Y' then 'Yes'
           when 'N' then 'No'
         else
           'UNK' 
         end as ISREFERENCEDATA 
 from vw_mapping_domain_ref dr,
      dictionary.tables dt
 where libname='SDTMDATA' 
 and dr.status='Approved'
  and (dt.memname=dr.domain 
         or substr(dt.memname,1,4)=dr.domain)
 order by dt.memname;     
quit;

/* Update the dataset label for SUPPQUAL domains to populate the domain name */

data sdtmmeta.sdtmm_define_domain; 
 set sdtmmeta_define_domain;
 if substr(domain,1,4)='SUPP' then do;
  /* dom_desc field is $40 and the last bracket is stripped of the default from MSA */
  dom_desc=tranwrd(dom_desc,'[domain name',substr(domain,5,2));
 end;
run; 

/* Prune the MSA superset list of keys (DOM_KEYS) to contain only the keys actually present in the study */
%do a=1 %to &sqlobs;
 data _null_;
  set sdtmmeta.sdtmm_define_domain;
  dom_keys=compress(tranwrd(dom_keys,',','","'));
   if _n_=&a then do;
    call symput ('dom_keys',trim(dom_keys));
    call symput ('domain',trim(domain));
   end;    
  run;
  
  proc sql noprint;
   select trim(variable_name) into :key_string&a separated by ', ' 
    from sdtmmeta.sdtmm_define_domain_vars 
   where domain="&domain" and variable_name in ("&dom_keys");
  quit;
  
  proc sql noprint;
   update sdtmmeta.sdtmm_define_domain set DOM_KEYS=("&&key_string&a" ) where domain="&domain";
  quit;

%end;

/* Provide a starting point for define.xml traceability - populate ORIGIN and SRC_COLUMN for as many 
/  SDTM variables as possible by interrogating oracle metadata collected from the conversion performed 
/  on the study data */

proc sql noprint;    
 alter table sdtmmeta.sdtmm_define_domain_vars add added char(1);
 alter table sdtmmeta.sdtmm_define_domain_vars add origin char(100);
 alter table sdtmmeta.sdtmm_define_domain_vars add src_column char(1000);
 
 /* Get a count of the number of fields we are going to try and populate with ORIGIN etc 
    We can exlude some values up front to make the code run faster */
	
 select count(*) into :num_orig 
   from sdtmmeta.sdtmm_define_domain_vars
  where domain not in ('TA','TE','TI','TS','TV','SE','CO')
    and variable_name not in ('DOMAIN','STUDYID','USUBJID','VISIT','VISITNUM')
    and variable_name not like '%SEQ'
    and variable_name not like '%STAT'
    and variable_name not like '%REASND'
    and variable_name not like '%STRESC'
    and variable_name not like '%STRESN'
    and variable_name not like '%STRESU'
    and variable_name not like '%BLFL'
    and domain not like 'SUPP%'
  order by domain, variable_name ;
quit;

/* Create macro vars to drive the queries */
proc sql noprint;
  select distinct domain, variable_name
     into :or_dset1- :or_dset%left(&num_orig),
          :or_nm1- :or_nm%left(&num_orig)
     from sdtmmeta.sdtmm_define_domain_vars
    where domain not in ('TA','TE','TI','TS','TV','SE','CO')
      and variable_name not in ('DOMAIN','STUDYID','USUBJID','VISIT','VISITNUM')
      and variable_name not like '%SEQ'
      and variable_name not like '%STAT'
      and variable_name not like '%REASND'
      and variable_name not like '%STRESC'
      and variable_name not like '%STRESN'
      and variable_name not like '%STRESU'
      and variable_name not like '%BLFL'      
      and domain not like 'SUPP%'
    order by domain, variable_name;
quit;

/* Loop through all variables where we might expect to find an ORIGIN value from covnersion metadata */
%do c=1 %to &num_orig;
 /*Initialise as null update variables */
 %let added =;
 %let origin=;
 %let source=;
 
 proc sql noprint; 
  select distinct origin into :origin separated by ',' 
   from (select * from vw_monitor_varmap where si_var not like '%DTC') vm,
        vw_mapping_domain_var_ref dvr,
        vw_monitor_view_tab_list vtl        
  where dvr.domain=vm.domain
    and dvr.status='Approved'
    and dvr.variable_name=vm.sdtm_var
    and vtl.basetabname=vm.si_dset
    and dvr.domain="&&or_dset&c"
    and dvr.variable_name="&&or_nm&c";

  select distinct added into :added 
   from (select * from vw_monitor_varmap where si_var not like '%DTC') vm,
        vw_mapping_domain_var_ref dvr,
        vw_monitor_view_tab_list vtl        
  where dvr.domain=vm.domain
    and dvr.status='Approved'
    and dvr.variable_name=vm.sdtm_var
    and vtl.basetabname=vm.si_dset
    and dvr.domain="&&or_dset&c"
    and dvr.variable_name="&&or_nm&c";
 
  update sdtmmeta.sdtmm_define_domain_vars set origin="&origin"
   where domain="&&or_dset&c"
     and variable_name="&&or_nm&c";

  update sdtmmeta.sdtmm_define_domain_vars set added="&added"
   where domain="&&or_dset&c"
     and variable_name="&&or_nm&c";

  select distinct trim(libname)||'.'||trim(si_dset)||'.'||trim(coalesce(orig_si_var,si_var)) 
    into :source separated by ', ' 
    from (select * from vw_monitor_varmap where si_var not like '%DTC') vm,
         vw_mapping_domain_var_ref dvr,
         vw_monitor_view_tab_list vtl        
   where dvr.domain=vm.domain
     and dvr.status='Approved'
     and dvr.variable_name=vm.sdtm_var
     and vtl.basetabname=vm.si_dset
     and dvr.domain="&&or_dset&c"
     and dvr.variable_name="&&or_nm&c" ; 

  update sdtmmeta.sdtmm_define_domain_vars set src_column="&source"
   where domain="&&or_dset&c"
     and variable_name="&&or_nm&c";      	 
 quit;   
%end;

/* Perform separate steps to update ORIGIN and SOURCE for SUPP data - ADDED metadata field not needed here */
proc sql noprint;    
 select count(*) into :num_sorig 
   from sdtmmeta.sdtmm_define_domain_vars
  where domain like 'SUPP%' and variable_name='QORIG'
  order by domain, variable_name ;
quit;

%if &num_sorig >=1 %then %do;
 proc sql noprint;
  select distinct domain, variable_name
     into :or_dset1- :or_dset%left(&num_sorig),
          :or_nm1- :or_nm%left(&num_sorig)
     from sdtmmeta.sdtmm_define_domain_vars
    where domain like 'SUPP%' and variable_name='QORIG'
    order by domain, variable_name;
 quit;

 %do d=1 %to &num_sorig;
  /*Initialise as null update variables */
  %let origin=;
  %let source=;
 
  proc sql noprint;
 
  select distinct qorig into :origin separated by ',' 
   from sdtmdata.&&or_dset&d;
 
  update sdtmmeta.sdtmm_define_domain_vars set origin="&origin"
   where domain="&&or_dset&d"
     and variable_name="&&or_nm&d";

  select distinct trim(vtl.libname)||'.'||trim(vm.si_dset)||'.'||trim(coalesce(vm.orig_si_var,vm.si_var)) 
  into :source separated by ', ' 
    from vw_monitor_varmap vm,
         vw_monitor_view_tab_list vtl  
   where vm.suppqual like 'YES%'
     and vm.si_dset=vtl.basetabname
     and vm.domain=substr("&&or_dset&d",5,4) ;

  update sdtmmeta.sdtmm_define_domain_vars set src_column="&source"  
   where domain="&&or_dset&d"
     and variable_name="&&or_nm&d";      
      
  quit;   
 %end; 
%end;

/* Finally we only have the ORIGIN and SRC_COLUMN for FINDINGS --ORRES columns. Update the --TEST and --ORRESU
/  with the same details as --ORRES for ORIGIN and SRC_COLUMN. 
/  Also update --BLFL with default ORIGIN values */

/* Use a temporary copy as an update statement cant concurrently read and write the same dataset in proc sql */
data _tmp;
 set sdtmmeta.sdtmm_define_domain_vars;
run;

proc sql;
 update sdtmmeta.sdtmm_define_domain_vars a set src_column= 
 (select src_column from _tmp
  where substr(variable_name,3,5)='ORRES' and substr(variable_name,8,1)^='U'
  and substr(variable_name,1,2)=substr(a.variable_name,1,2)
  and domain=a.domain)
  where substr(variable_name,3,4)='TEST' or substr(variable_name,3,6)='ORRESU'
  and substr(variable_name,1,2)=substr(a.variable_name,1,2)
  and domain=a.domain;
  
  update sdtmmeta.sdtmm_define_domain_vars a set origin= 
   (select origin from _tmp
    where substr(variable_name,3,5)='ORRES' and substr(variable_name,8,1)^='U'
    and substr(variable_name,1,2)=substr(a.variable_name,1,2)
    and domain=a.domain)
    where substr(variable_name,3,4)='TEST' or substr(variable_name,3,6)='ORRESU'
    and substr(variable_name,1,2)=substr(a.variable_name,1,2)
  and domain=a.domain;
  
  update sdtmmeta.sdtmm_define_domain_vars a set origin='DERIVED'
   where substr(variable_name,3,4)='BLFL' or substr(variable_name,3,6) in ('STRESU','STRESC','STRESN');
  
  update sdtmmeta.sdtmm_define_domain_vars a set origin='DERIVED'
   where variable_name in ('USUBJID','IDVARVAL') or substr(variable_name,3,3)='SEQ'
      or substr(variable_name,3,2)='DY' or substr(variable_name,3,4)='STDY' or substr(variable_name,3,4)='ENDY' ;
   
  update sdtmmeta.sdtmm_define_domain_vars a set origin='PROTOCOL'
   where variable_name='STUDYID';
   
  update sdtmmeta.sdtmm_define_domain_vars a set origin='ASSIGNED'
   where variable_name in ('DOMAIN','SUBJID','RDOMAIN','IDVAR','QNAM','QLABEL','QEVAL','VISITNUM','VISIT') 
      or substr(variable_name,3,4)='STAT'; 

  update sdtmmeta.sdtmm_define_domain_vars a set origin='PROTOCOL'
   where domain in ('TA','TE','TI','TV','TS') 
      and origin is null;       
quit;

/* Final step for domain variable definitions is to define the SAS/ODM/XML formats for the data */

proc sql noprint;
 select count(*) into :num_doms from sashelp.vtable where libname='SDTMDATA' and substr(memname,1,4)^='SUPP';
quit;
proc sql noprint;
  select distinct memname
    into :dsname1- :dsname%left(&num_doms)
    from sashelp.vtable 
   where libname='SDTMDATA' and substr(memname,1,4)^='SUPP'; /* SUPP-- have no numeric vars */
quit;

%do a=1 %to &num_doms;

 proc sql noprint;
 /* BJC003: add more explanatory comments here: 
   Create lists of numeric variables with attributes e.g. LBSTRESN, 3.4/3.3/-
   - Length (char: variable length, num: total number of digits as per ODM definition)
   - SignificantDigits (number of digits after decimal as per ODM definition)
   - SASLength (char: variable length, num: total length including digits, any decimal point and any minus sign)
 */
 select variable_name,
       cats('catx(''/'',',
                  'max(lengthn(compress(scan(put(',variable_name,',best32.-l),1,''.''),'' '',''kd''))),',
                  'max(lengthn(scan(put(',variable_name,',best32.-l),2,''.''))),',
                  'sign(min(',variable_name,')))'),
       cats(':',variable_name)

 into : numvars  separated by ' ',
      : sizes    separated by ',',
      : intos    separated by ','
 from sdtmmeta.sdtmm_define_domain_vars
 where domain = upcase("&&dsname&a")
   and type = 'Num';

 %let nnumvar = &sqlobs;

/* Create a macro variables for each numeric variable containing a slash-delimited list of
   - max intLength (number of digits before any decimal point)
   - max SignificantDigits (number of digits after the decimal point)
   - sign (-1, 0 or 1) of the minimum non-missing value
*/

/* TE domain has no numeric variables, other domains may be added with all char/text vars - check for this scenario */
 %if &sqlobs >=1 %then %do;
  select &sizes
   into &intos
   from sdtmdata.&&dsname&a;
  quit;
 %end;
/* Add metadata attributes to the metadata dataset
   - DataType (ODM data type)
   - Length (char: variable length, num: total number of digits as per ODM definition)
   - SignificantDigits (number of digits after decimal as per ODM definition)
   - SASLength (char: variable length, num: total length including digits, any decimal point and any minus sign)
   - SASFormat (populated for both char and num variables)
*/

 data sdtmmeta.sdtmm_define_domain_vars;
  set sdtmmeta.sdtmm_define_domain_vars;
 length DataType $ 8 Length intlength SignificantDigits SASLength sign 8 SASFormat $ 8 sizes $ 20;
 array numattr(3) 8. intlength significantdigits sign;
 if domain eq upcase("&&dsname&a") then
  do;
    if type eq 'Num' then
      do;
        sizes = symget(variable_name);
        do i = 1 to 3;
          numattr{i} = input(scan(sizes,i,'/'),best.);
        end;
        if SignificantDigits gt 0 then
          do;
            DataType = 'Float';
            Length = intlength + SignificantDigits;
            SASLength = (sign eq -1) + intlength + 1 + SignificantDigits;
            SASFormat = catx('.',SASLength,SignificantDigits);
          end;
        else
          do;
            DataType = 'Integer';
            Length = intlength;
            SignificantDigits = .;
            SASLength = (sign eq -1) + intlength;
            SASFormat = cats(SASLength,'.');
          end;
      end;
    else
      do;
        DataType = 'Text';
        SASLength = length;
        SASFormat = cats('$',length,'.');
      end;
  end;
 drop intlength sign sizes i;
 run;
 
%end;

/* Update the page number references from automated CRF annotations (where available) */
proc sql noprint;
update sdtmmeta.sdtmm_define_domain_vars a set origin= 
   (select pagelist from pagesum
    where src_var is null
	  and domain=a.domain
	  and sdtm_var=a.variable_name)  
where origin='CRF'
  and trim(domain)||trim(variable_name) in (select trim(domain)||trim(sdtm_var) from pagesum);
quit;

/* For findings data - the VLM has the ORIGIN - set a pointer that can be used for later updates of ORIGIN superset */

data sdtmmeta.sdtmm_define_domain_vars;
 set sdtmmeta.sdtmm_define_domain_vars;
 if length(variable_name) >=6 then do;
  if substr(reverse(trim(variable_name)),1,4)='TSET' or substr(reverse(trim(variable_name)),1,6)='DCTSET' 
  or substr(reverse(trim(variable_name)),1,5)='SERRO' or substr(reverse(trim(variable_name)),1,6)='USERRO' 
  then ORIGIN='(SEE VLM)';
  if variable_name='QVAL' then ORIGIN='(SEE VLM)';
 end;
run;

/* Finally for the domain vars - update the char variable details for the SUPP domains */

proc sql noprint;
update sdtmmeta.sdtmm_define_domain_vars a 
   set datatype =(select case type when 'char' then 'Text' else type end from sashelp.vcolumn 
                   where libname='SDTMDATA' and memname=a.domain and name=a.variable_name), 
       saslength=(select length from sashelp.vcolumn 
	               where libname='SDTMDATA' and memname=a.domain and name=a.variable_name), 
	   sasformat=(select compress('$'||put(length,8.)||'.') from sashelp.vcolumn 
	               where libname='SDTMDATA' and memname=a.domain and name=a.variable_name)
where substr(domain,1,4)='SUPP';
quit;	   

*********************************************************************************************;
/* Part 2: Process the (3 types) of Value Level Metadata (VLM) needed */

proc sql noprint;
 create table vlm_driver as 
  select distinct dc.memname as domain, dr.domref, dvr.variable_name, dvr.controlled, 
         dc.name, dvr.define_xml_metadata                  
  from vw_mapping_domain_ref dr,
       vw_mapping_domain_var_ref dvr,
       dictionary.columns dc
  where dvr.define_xml_metadata='Y'  
    and dvr.status='Approved'
    and dr.status='Approved'
	and dc.memname^='TI' /* TI is a reference domain and no VLM needed/expected */
    and libname='SDTMDATA' 
    and (dc.memname=dr.domain 
         or substr(dc.memname,1,4)=dr.domain)
    and dr.domain=dvr.domain
    and dvr.variable_name=dc.name;

 create table vlm_driver_dist as 
  select distinct domain from vlm_driver;
quit;    

/* Store the sqlobs from here as subsequent proc sqls will overwrite the value and it is needed later */
%let num_doms=&sqlobs;
%if &sqlobs >=1 %then %do;

/* For TEST/QLABEL and TESTCD/QNAM set an ALIAS field used by the later query so the created columns
   all get called the same name. */

data vlm_driver;
 set vlm_driver;
 length ALIAS $25;
 length DOM_NAME $7;
 length suffix $6;
 
 /* Create Alias names so we get the same column names for all TEST(CD) fields. 
 /  also create CATVAR to differentiate the various potential hierarchical grouping items */
 catvar='Y';
 if substr(reverse(trim(variable_name)),1,4)='TSET' or variable_name = 'QLABEL' then do;
  alias=' as LABEL';
  catvar='N';
 end; 
 else if length(variable_name) >=6 then do;
  if substr(reverse(trim(variable_name)),1,6)='DCTSET'  then do;
   alias=' as VALUE';
   catvar='N';
  end;
 end; 
 else if variable_name = 'QNAM' then do;
  alias=' as VALUE';
  catvar='N';
 end;

 /* Re-jig the data for SUPPQUAL */
 if substr(domain,1,4)='SUPP' then do;
  DOM_NAME='RDOMAIN';
  catvar='N';
 end; 
 else DOM_NAME='DOMAIN';
 
 if substr(domain,1,4)='SUPP' then domref=substr(domain,5,2);
 
 /* Now deal with the categorisation variables --CAT, --SCAT, --SPEC, --METHOD */
 if catvar='Y' and substr(domain,1,4)^='SUPP' then do;
   length suffix $6. ; length val_name grp_name $25;
   suffix=substr(name,3);
   val_name=trim(variable_name)||" as val_"||trim(suffix);
   grp_name="'"||trim(variable_name)||"' as grp_"||trim(suffix);
 end; 
run; 

/* Loop through each domain with VLM and summarise it out */
%do a=1 %to &num_doms;

 data _null_;
  set vlm_driver_dist  ;
   if _n_=&a then do;
    call symput ('domain',trim(domain));
    output;
   end;
 run; 

 /* Categorisation variables for VLM : grpv_string and grpn_string (N=name, V=value) only present for some domains 
    initialise as null */
 %let grpn_string=;
 %let grpv_string=;
 
 proc sql noprint;
   select trim(variable_name)||alias into :var_string separated by ',' 
     from vlm_driver where domain="&domain" and alias is not null;
   select distinct trim(dom_name) into :dom_name from vlm_driver where domain="&domain";  
   select val_name into :grpv_string separated by ',' 
     from vlm_driver where domain="&domain" and catvar ='Y';
   select grp_name into :grpn_string separated by ',' 
     from vlm_driver where domain="&domain" and catvar ='Y';	 
 quit;
  
 data _null_;
  set vlm_driver(where=(domain="&domain"));
   call execute('proc sql;');
   call execute("create table VLM_&a as");
   call execute('select dom.*, meta.* ');
   call execute('from (select distinct &dom_name as dummy_dom , &var_string ');
   %if %length(&grpv_string)>=1 %then %do;
    call execute(' , &grpv_string'); 
   %end;
   call execute('from sdtmdata.'||domain||') dom ,');
   call execute('(select distinct domain, domref, controlled, alias ');   
   %if %length(&grpn_string)>=1 %then %do;
    call execute(' , &grpn_string'); 
   %end;   
   call execute('from VLM_driver where catvar ="N") meta');
   call execute('where meta.domref=dom.dummy_dom');
   call execute('and meta.domain="&domain"');
   call execute('and meta.alias ^=" as LABEL";');
   call execute('quit;');
 run;

%end;

/* Generate one overall VLM dataset from the domain sub-datasets */

data sdtmm_define_VLM(drop=dummy_dom alias domref); 
 attrib DOMAIN length=$8;
 attrib SOURCE  length=$8;
 /* IETEST and TITEST can be $200 - all other --TEST fields are $40 */
 attrib LABEL  length=$200;
 attrib VALUE  length=$8;
 attrib SRC_DATA_TYPE length=$54;
 length GRP_CAT GRP_SCAT GRP_SPEC GRP_METHOD $8;
 length VAL_CAT VAL_SCAT VAL_SPEC VAL_METHOD $200;
 set 
 %do a=1 %to &num_doms;
   VLM_&a
 %end; 
  ;  
 /* Default SOURCE as the domain --TESTCD. There is a default of QNAM value needed for SUPPQUAL rows */
 if substr(domain,1,4)^='SUPP' then do;
  SOURCE=compress(substr(domain,1,2)||'TESTCD');
 end;   
 else SOURCE='QNAM'; 
run;

/* for VLM - attempt to update the source data type from Spectre spec for the source data from 
/  which the tests are created - may be incomplete !!!! e.g. pre-processed variables RACE1,2,3 etc */

/* Using DSM variable catalog data update the src_data_type from vw_monitor_varmap 
   as this MSA data is woefully incomplete. src_data_type is now superceded later by datatype, left for reference */
proc sql noprint;
   update vw_monitor_varmap a set src_data_type=(select src_data_type from dsm_attribs
    where name=coalesce(a.orig_si_var,a.si_var))
   where src_data_type is null;
quit;	
	 
/* Create a driver table of all the values in VLM that are in the source datasets so we can 
/ derive the source attributes. */

proc sql noprint;
 create table src_driver as select distinct value from sdtmm_define_vlm
 where trim(value) in (select trim(si_var)   from vw_monitor_varmap)    
	or trim(value) in (select trim(sdtm_var) from vw_monitor_varmap);
quit; 

%let num_src=&sqlobs;
%if &sqlobs >= 1 %then %do;
 proc sql noprint;
  select value
    into :var1- :var%left(&num_src)
    from src_driver;
 quit;   
     
 %do d=1 %to &num_src;
     
 proc sql noprint;
  update sdtmm_define_VLM set src_data_type=(
  select distinct src_data_type
    from vw_monitor_varmap  
    where substr(reverse(trim(si_var)),1,1)^='_' and added=''
     and src_data_type is not null      
     and (si_var ="&&var&d"
          or (substr(suppqual,1,3)='YES' and sdtm_var="&&var&d")))
     where (trim(domain)||trim(value) in 
  (select trim(domain)||trim(si_var)
     from vw_monitor_varmap 
    where si_var ="&&var&d") 
      OR
      (trim(domain)||trim(value) in 
       (select 'SUPP'||trim(domain)||trim(sdtm_var)
          from vw_monitor_varmap  
         where substr(suppqual,1,3)='YES'
           and sdtm_var ="&&var&d")) );
 quit;    
 %end;
%end;

/* Finally for data that is collected in normalised format - assume that the VLM src_data_type is char 
   NB: later on a more accurate datatype field is derived that looks at each test*/
   
proc sql noprint;
 update sdtmm_define_VLM a set src_data_type=(select distinct 'char' 
   from si_rules b, vw_monitor_varmap c
  where a.domain=c.domain
    and c.si_dset=b.si_dset
	and c.domain^='CO')
where src_data_type is null;
quit;	

/* Update the page number references into VLM and then opther ORIGIN values if no page present.
   Stepwise approach, each query ends with 'where origin is null' so gradually more and more 
   row origin values get populated */

proc sql noprint;
alter table sdtmm_define_vlm add origin char(100);

/* this query updates the VLM --TESTCD for IDSL non-normalised data e.g. INVPCOMP */
update sdtmm_define_vlm a set origin= 
   (select pagelist from pagesum
    where src_var is not null
	  and domain=a.domain
	  and src_var=a.value
	  and upper(studyid)=upper(%unquote(%str(%')%trim(&studyid)%str(%'))) );

/* this next query updates much of the other VLM including --SUPP */  
update sdtmm_define_vlm a set origin= 
   (select distinct pagelist from pagesum
    where domain=a.domain 
	  and sdtm_var=a.value) 
where origin is null;	  

/* this query updates IDSL normalised data like ELIG */
update sdtmm_define_VLM a set origin=(select distinct c.pagelist 
   from si_rules b, pagesum c
  where a.domain=c.domain 
	and substr(reverse(trim(c.sdtm_var)),1,5)='SERRO'
	and substr(a.source,3,6)='TESTCD'
    and a.value=c.src_var
	and c.domain^='CO')
where origin is null;

/* this query updates IDSL non-normalised data like FA */
update sdtmm_define_VLM a set origin=(select distinct c.pagelist 
   from si_rules b, pagesum c
  where a.domain=c.domain
	and c.sdtm_var=a.source    
	and c.domain^='CO')
where origin is null;

/* the next two queries are very similar and update the VARMAP origin non eCRF data e.g. ASSIGNED 
   This had to be split into two queries as the same domain may have >1 feeder data group mapped differently*/
update sdtmm_define_VLM a set origin=(select distinct c.origin 
   from vw_monitor_varmap c
  where origin^='DROPPED'
    and (a.domain=c.domain or 'SUPP'||trim(c.domain)=a.domain)
    and c.si_var=a.value
	and c.domain^='CO')
where origin is null;

update sdtmm_define_VLM a set origin=(select distinct c.origin 
   from vw_monitor_varmap c
  where origin^='DROPPED'
    and (a.domain=c.domain or 'SUPP'||trim(c.domain)=a.domain)
    and c.si_var=a.source
	and c.domain^='CO')
where origin is null;
quit;

/* Final step for VLM is to define the SAS/ODM/XML formats for the data */

data sdtmm_define_VLM; set sdtmm_define_VLM;
 length result $8;
  if source='QNAM' then result='QVAL';  
  else if substr(reverse(trim(source)),1,6)='DCTSET' then result=trim(substr(domain,1,2))||'ORRES';
  else result=source; 
  
  if domain=:'SUPP' then dom_typ='SUPP';
  else dom_typ='REG';
run;

proc sql noprint;
 select count(distinct domain) into :num_doms 
   from sdtmm_define_VLM 
   where substr(src_data_type,1,3)='num' and substr(src_data_type,1,8)^='num DATE';
quit;

%if &num_doms >=1 %then %do;
 proc sql noprint;
  select distinct domain , source, result
    into :dsname1- :dsname%left(&num_doms),
	     :dssrc1- :dssrc%left(&num_doms),		 
		 :dsres1- :dsres%left(&num_doms)
    from sdtmm_define_VLM 
   where substr(src_data_type,1,3)='num' 
   and substr(src_data_type,1,8)^='num DATE'; 
 quit;

 %do a=1 %to &num_doms;

 proc sql noprint;
 create table tmp1_&&dsname&a as
 select distinct result, source,         	
       cats('catx(''/'',',
	             
                  'max(lengthn(compress(scan(put(input(',result,',best32.),best32.-l),1,''.''),'' '',''kd''))),',
                  'max(lengthn(trim(scan(put(input(',result,',best32.),best32.),2,''.'')))),',
                  'sign(min(input(',result,',best32.))))'),		  
       cats(':',value)	    
  from sdtmm_define_vlm
 where domain = upcase("&&dsname&a") 
   and substr(src_data_type,1,3)='num' 
   and substr(src_data_type,1,8)^='num DATE';

 select distinct result, source,        	
       cats('catx(''/'',',
                  'max(lengthn(compress(scan(put(input(',result,',best32.),best32.-l),1,''.''),'' '',''kd''))),',
                  'max(lengthn(trim(scan(put(input(',result,',best32.),best32.),2,''.'')))),',
                  'sign(min(input(',result,',best32.))))'),		  
       cats(':',value)	   
 into : result ,
      : source ,     
      : sizes    separated by ',',
      : intos    separated by ',' 
  from sdtmm_define_vlm
 where domain = upcase("&&dsname&a") 
   and substr(src_data_type,1,3)='num' 
   and substr(src_data_type,1,8)^='num DATE';
 quit;
%let nnumvar = &sqlobs;

/* Create a macro variables for each numeric variable containing a slash-delimited list of
   - max intLength (number of digits before any decimal point)
   - max SignificantDigits (number of digits after the decimal point)
   - sign (-1, 0 or 1) of the minimum non-missing value
*/
 proc sql noprint;
 create table tmp2_&&dsname&a as
  select &source, &sizes
  from sdtmdata.&&dsname&a
 where &source in (select value from sdtmm_define_vlm
                    where domain = upcase("&&dsname&a") 
                      and substr(src_data_type,1,3)='num' 
                      and substr(src_data_type,1,8)^='num DATE')
  group by &source;  

 select &source, &sizes
  into :source , &intos
  from sdtmdata.&&dsname&a
 where &source in (select value from sdtmm_define_vlm
                    where domain = upcase("&&dsname&a") 
                      and substr(src_data_type,1,3)='num' 
                      and substr(src_data_type,1,8)^='num DATE')  
  group by &source; 
 quit;
 %end;
%end;
/* Add metadata attributes to the metadata dataset
   - DataType (ODM data type)
   - Length (char: variable length, num: total number of digits as per ODM definition)
   - SignificantDigits (number of digits after decimal as per ODM definition)
   - SASLength (char: variable length, num: total length including digits, any decimal point and any minus sign)
   - SASFormat (populated for both char and num variables)
*/

data sdtmm_define_vlm;
 set sdtmm_define_vlm;
length DataType $ 8 Length intlength SignificantDigits SASLength sign 8 SASFormat $ 8 sizes $ 20;
array numattr(3) 8. intlength significantdigits sign;
/*if domain eq upcase("&&dsname&a") then
  do;*/
    if substr(src_data_type,1,3)='num' and substr(src_data_type,1,8)^='num DATE' then
      do;
        sizes = symget(value);
		
        do i = 1 to 3;
          numattr{i} = input(scan(sizes,i,'/'),best.);
        end;
        if SignificantDigits gt 0 then
          do;
            DataType = 'Float';
            Length = intlength + SignificantDigits;
            SASLength = (sign eq -1) + intlength + 1 + SignificantDigits;
            SASFormat = catx('.',SASLength,SignificantDigits);
          end;
        else
          do;
            DataType = 'Integer';
            Length = intlength;
            SignificantDigits = .;
            SASLength = (sign eq -1) + intlength;
            SASFormat = cats(SASLength,'.');
          end;
      end;
    else
      do;
        DataType = 'Text';
        SASLength = length;
        SASFormat = cats('$',length,'.');
      end;
  *end;
drop intlength sign sizes i;
run;

/* Finally for the VLM - update the char variable details  */

proc sql noprint;
 select count(distinct domain) into :num_doms 
   from sdtmm_define_VLM 
   where datatype not in ('Float','Integer');
quit;
proc sql noprint;   
  select distinct domain , source, result
    into :dsname1- :dsname%left(&num_doms),
	     :dssrc1- :dssrc%left(&num_doms),		 
		 :dsres1- :dsres%left(&num_doms) 
    from sdtmm_define_VLM 
   where datatype not in ('Float','Integer'); 
quit;

%do a=1 %to &num_doms;

proc sql noprint;
 create table char_&&dsname&a as 
 select &&dssrc&a , max(length(&&dsres&a)) as length
   from sdtmdata.&&dsname&a
    where &&dssrc&a in (select value from sdtmm_define_vlm
                    where domain = upcase("&&dsname&a") 
                      and datatype not in ('Float','Integer'))
  group by &&dssrc&a;
quit;  

proc sql noprint;
update sdtmm_define_vlm a 
   set datatype =( 'Text'), 
       length=(select length from char_&&dsname&a
	               where &&dssrc&a=a.value and value=a.value),    
       saslength=(select length from char_&&dsname&a
	               where &&dssrc&a=a.value and value=a.value), 
	   sasformat=(select compress('$'||put(length,8.)||'.') from char_&&dsname&a
                   where &&dssrc&a=a.value and value=a.value)
where datatype not in ('Float','Integer') and domain = upcase("&&dsname&a");
quit;	 

%end;
 	   
/* Write out the final dataset */

data sdtmmeta.sdtmm_define_VLM; 
 set sdtmm_define_VLM(drop=result dom_typ);
run;

/* Summarise the VLM origins into domain supersets to update domain variable rows */

proc sql noprint;
 create table vlm_origin_ss
     as select distinct domain, origin
   from sdtmmeta.sdtmm_define_VLM
   where origin is not null
   order by domain;
quit;  

/* Strip out page and number references to give the bare bones origin values */
data vlm_origin_ss; set vlm_origin_ss;
origin=compress(tranwrd(tranwrd(origin,' page:',''),' page(s):',''),'0123456789,.');
run;

proc sort data=vlm_origin_ss nodupkey;
by domain origin;
run;

/* Create a comma separated string where multiple origins present for VLM/SUPP within a domain e.g. CRF, eDT */
data vlm_origin_ss; 
 set vlm_origin_ss;
 by domain origin;
 retain lag1_origin;length lag1_origin $100;
 
 if not last.domain then lag1_origin=origin;
 if last.domain then do;
  if lag1_origin^='' then origin=trim(lag1_origin)||', '||trim(origin);
  output;
  lag1_origin='';
 end; 
run;

proc sql noprint;
 update sdtmmeta.sdtmm_define_domain_vars a set origin=(
 select origin 
   from vlm_origin_ss
  where domain=a.domain)
where origin='(SEE VLM)';
quit;  
%end; /* end for if &sqlobs >=1 on VLM_DRIVER work dataset (near start of section 2) */ 

*********************************************************************************************;
/* BJC003: add more explanatory comments here:  
  Part 3 : queries to list out CT (controlled terms) in correct format for use in define.xml 
   This section is rather complex as there are 3 scenarios to identify and process: 
   1. There are SDTM variables controlled by CDISC CT. CDISC CT goes to define.xml 
   2. There are SDTM variables where content was controlled by an IDSL codelist, but no SDTM CT. IDSL CT -> define.xml
   3. There are SDTM variables where content was controlled by an IDSL codelist, and also SDTM CT is applied.
      For these we provide only the SDTM CT and not the IDSL.
 */

/* BJC002 : add in sponsor CT definitions for define.xml */
   
/* For coded variables add in the decode pair */ 
  proc sql noprint;
   create table spec1 as 
   select * from spec
    where codelist_nm is not null and si_var in (select code from dsm_var_rel);
  
   update spec1 a set si_var=(
    select decode from dsm_var_rel
	 where code=a.si_var);
  quit;	
  
  /* Append the decodes to the spec metadata */
  data spec;
   set spec spec1;
   /* BJC003: Change 1: add curved brackets here to only populated entries - not nulls as well */
   if codelist_nm ^='' then codelist_nm='('||trim(codelist_nm)||')';
  run;    

/* Join the 3 sets of data above to get the items with sponsor CT and not CDISC CT */
/* BJC003: change 1: add more to the final line of the where clause in second query below to filter more */

 proc sql noprint;
 create table sponsor_ct_vars as
       select a.si_dset, a.si_var, a.orig_si_var,'SUPP'||trim(a.domain) as domain, a.sdtm_var, 
	   b.codelist_nm, '' as controlled
    from vw_monitor_varmap a,
         spec b
      where substr(a.suppqual,1,3)='YES'
	    and a.si_dset= b.si_dset
        and coalescec(a.orig_si_var,a.si_var) = b.si_var       
        and b.codelist_nm is not null 
UNION
       select a.si_dset, a.si_var, a.orig_si_var, a.domain, a.sdtm_var, b.codelist_nm, c.controlled
    from vw_monitor_varmap a,
         spec b,
         vw_mapping_domain_var_ref c
      where a.si_dset = b.si_dset
        and coalescec(a.orig_si_var,a.si_var)  = b.si_var
        and a.domain = c.domain
        and a.sdtm_var = c.variable_name
        and (b.codelist_nm is not null or (index(c.controlled,'(')=0 and c.controlled is not null 
		                                   and c.controlled not in ('[MEDDRA]','*','ISO 8601')) );
  quit;  

/* Finally - get the subset codelist entries from spectre for the study */

 proc sql noprint;
  select distinct spec_id into : specids separated by ',' 
  from spec;

  create table spec_stuff as 
   select spec_dataset_var_id, dataset_nm, var_nm
     from spec_db.spec_ds_info_var_detail_v 
    where spec_id in (&specids);
 quit;

/* For coded variables add in the decode pair */ 

  proc sql noprint;
   create table spec_stuff1 as 
   select * from spec_stuff
    where var_nm in (select code from dsm_var_rel);
  
   update spec_stuff1 a set var_nm=(
    select decode from dsm_var_rel
	 where code=a.var_nm);
  quit;	
  
  /* Append the decodes to the spec metadata */
  data spec_stuff;
   set spec_stuff spec_stuff1;
  run;

 proc sql noprint;
  select distinct spec_dataset_var_id into : sdvids separated by ','
  from spec_stuff;

  create table spec_code as 
   select spec_dataset_var_id, code, code_desc
  from spec_db.spec_code
  where spec_dataset_var_id in (&sdvids);
 quit;

/* Create the dataset of sponsor CT entries for addition to define.xml */

proc sql noprint;
 create table sponsor_define_xml_entries as
 select distinct c.si_dset, c.si_var, c.orig_si_var, c.domain, c.sdtm_var as variable_name, 
  c.codelist_nm as list, a.code, a.code_desc as value
 from spec_code a,
      spec_stuff b,
      sponsor_ct_vars c
 where index(c.controlled,'(')=0
   and c.si_dset=b.dataset_nm
   and coalescec(c.orig_si_var,c.si_var)=b.var_nm
   and a.spec_dataset_var_id=b.spec_dataset_var_id
   order by c.domain, c.sdtm_var, c.si_dset, c.si_var, a.code_desc;
quit;

/* BJC002: end of chunk of code added for sponsor CT in this update */

/* Once we are done with sponsor CT above, then we move on to the SDTM CT values */
proc sql noprint;
  create table ct_to_do as 
  select distinct domain, variable_name, controlled 
    from sdtmmeta.sdtmm_define_domain_vars
   where substr(controlled,1,1)="("
   order by controlled, domain, variable_name; 
quit;

%let num_cts=&sqlobs;

proc sql noprint;
  select distinct domain, variable_name, controlled
     into :ct_dset1- :ct_dset%left(&num_cts),
          :ct_nm1- :ct_nm%left(&num_cts),
          :ct_ls1- :ct_ls%left(&num_cts)          
     from ct_to_do
    order by controlled, domain, variable_name;
quit;

proc sql noprint;
  %do b=1 %to &num_cts;
    create table ct_&b as 
    select distinct &&ct_nm&b as value , 
           "&&ct_nm&b" as variable_name,
           %if %length(&&ct_dset&b) >= 6 %then %do;
            %if %substr(&&ct_dset&b,1,4)=SUPP %then %do;
             rdomain as domain , 
            %end; 
           %end;
           %else %do;
	        domain , 
           %end;
           "&&ct_ls&b" as list
      from sdtmdata.&&ct_dset&b 
     where &&ct_nm&b is not null
     
      %if &&ct_dset&b=EG and &&ct_nm&b=EGSTRESC %then %do;
            and EGCAT='FINDING' and EGTESTCD^='OTHER'
      %end;             
     /* BJC is code needed here for DS and MB/MS CT exceptions ? */
     ; 
  %end;
quit;

/* Deal with fields that have both sponsor and CDISC CT - merge all the terminology data to give consolidated picture */

 proc sql noprint;
 create table cdisc_and_sponsor_ct_vars as
       select * from sponsor_ct_vars 
      where codelist_nm is not null and index(controlled,'(')^=0;
 quit;

/* Get the CDISC CT into a more friendly format for use */
proc sql noprint;
 create table cdisc_ct as 
 select '('||trim(a.cdisc_submission_value)||')' as list, b.cdisc_submission_value as sdtm_value
 from cdisc_ct_main a, cdisc_ct_main b
 where a.codelist_code ='HEADER'
 and a.code=b.codelist_code;
quit;

/* subset the MSA CT and term_map to codelists used in the study */
proc sql noprint;
 create table term_map as select * from term_map where '('||trim(list_name)||')' in (select controlled from
                                                                                    cdisc_and_sponsor_ct_vars);
 create table cdisc_ct as select * from cdisc_ct where list in (select controlled from cdisc_and_sponsor_ct_vars );
quit;

proc sql noprint;
 create table cdisc_and_sponsor as
 select distinct c.si_dset, c.si_var, c.domain, c.sdtm_var as variable_name, c.codelist_nm as idsllist, 
        c.controlled as list, a.code, a.code_desc as value
 from spec_code a,
      spec_stuff b,
      cdisc_and_sponsor_ct_vars c 
   where c.si_var=b.var_nm   
   and a.spec_dataset_var_id=b.spec_dataset_var_id   
  order by c.domain, c.sdtm_var, c.si_dset, c.si_var, a.code_desc;
quit;

proc sql noprint;
 create table cdisc_and_sponsor_xml as select a.*, b.sdtm_value, b.ext_term 
   from cdisc_and_sponsor a left join term_map b
     on upper(a.value)=upper(b.source_value)
    and a.list= '('||trim(b.list_name)||')'
   order by domain, variable_name, value;
quit;

/* Upper case values for for *TESt and *UNIT lists */
data cdisc_and_sponsor_xml;
 set cdisc_and_sponsor_xml;
 if index(list,'TEST)')=0 and index(list,'UNIT)')=0 then value=upcase(value);
run;

/* Write out the CT metadata */
data sdtmm_define_ct(rename=(value=collected_value)); 
  length VALUE $200;
  length LIST $15;
  length VARIABLE_NAME DOMAIN $8;
  attrib value label='Collected value';
  attrib sdtm_value label='CDISC Submission value';
  attrib list label='Codelist short name';
  set
 %do b=1 %to &num_cts;
   ct_&b (in=ctonly) 
 %end;
 /* BJC002: Add in the sponsor CT entries previously queried */
  sponsor_define_xml_entries (in=idslonly)
  cdisc_and_sponsor_xml (in=mix)
  ; 
  if mix then source='BOTH';
  else if idslonly then source='IDSL';
  else if ctonly then source='SDTM';
run;

/* Separate this step out as the last statement behaves strangely when included in the datastep above */  
data sdtmm_define_ct1 ; set sdtmm_define_ct;  
 /* Default datatype to text as all --ORRES fields are text. 
    If DATATYPE refers to the source data then we will need to revise this code */
 DATATYPE='Text';
 /* Copy (collected) value to sdtm_value where this is null */
 if sdtm_value='' then sdtm_value=collected_value;
run;

proc sort data=sdtmm_define_ct1 out=sdtmmeta.sdtmm_define_ct ; 
by list collected_value sdtm_value domain variable_name;
run;

/* Finally - for sponsor CT - update the codelist name into the domain variables and Findings VLM/SUPP metadata */

/* Do a clean up to remove any duplicates of sponsor CT entries */
proc sort data=sponsor_define_xml_entries out=dxe nodupkey;
by domain variable_name list;
run;

data dxe_compressed;
 set dxe;
by domain variable_name list;
length mult_list ctlist $ 200;
retain ctlist;
ctlist = catx(', ',ctlist,list); /* Note: CATX only inserts delimiter if there's more than one value to concatenate */
if last.variable_name then do;  
   if index(ctlist,',')>=1 then do;
    mult_list=ctlist;ctlist='';
   end;	
   output;
   ctlist = ''; /* Reinitialise pagelist to blank (after having output the list) */
end;
drop list code value si_dset si_var;
run;

/* for non-findings/tests that have >1 sponsor codelist e.g. DSTERM - write these out as VLM instead */
proc sql noprint;
 create table dxe_mult as 
 select domain, variable_name as source, coalesce(orig_si_var,si_var) as value, list as controlled
   from dxe
  where substr(reverse(trim(variable_name)),1,5)^='SERRO' 
    and substr(reverse(trim(variable_name)),1,6)^='NSERTS' 
    and list not in ( select ctlist from dxe_compressed )
	and domain in (select memname from dictionary.tables where libname='SDTMDATA');

 alter table dxe_mult add origin char(100);	
 alter table dxe_mult add label char(120);
 alter table dxe_mult add src_data_type char(4000);
 
 update dxe_mult a set label=(select var_short_desc from dsm_attribs
  where a.value=name);

 update dxe_mult a set src_data_type=(select src_data_type from dsm_attribs
  where a.value=name);  
quit;										  

/* Append to the VLM any variables with multiple sponsor codelist sources */
/* BJC003 - amend the code to run for subset/filtered REs where a subset of total SDTM data converted is present */

%let dsid=%sysfunc(open(dxe_mult, is));
%let fnrc = %sysfunc(attrn(&dsid,nobs));
%let dsRc=%sysfunc(close(&dsid));


%if &fnrc >=1 %then %do;
 %if %sysfunc(exist(sdtmmeta.sdtmm_define_vlm)) %then %do;
   
   data sdtmmeta.sdtmm_define_vlm;
    set sdtmmeta.sdtmm_define_vlm dxe_mult;
   run; 
  %end; 
  %else %do;
   data sdtmmeta.sdtmm_define_vlm;
    set dxe_mult;
   run; 
 %end;
%end;

%if &fnrc =0 %then %do;
 %if not %sysfunc(exist(sdtmmeta.sdtmm_define_vlm)) %then %do;
   data sdtmmeta.sdtmm_define_vlm;
    set dxe_mult;
   run; 
 %end;
%end;   
   
proc sql;
 update sdtmmeta.sdtmm_define_domain_vars a set controlled=(select distinct ctlist from dxe_compressed
 where domain=a.domain
  and variable_name=a.variable_name
  and trim(domain)||trim(variable_name) not in (select distinct trim(domain)||trim(value) 
                                                    from sdtmmeta.sdtmm_define_vlm))
 where substr(reverse(trim(variable_name)),1,6)^='NSERTS'
   and substr(reverse(trim(variable_name)),1,5)^='SERRO'
   and (controlled is null or controlled='*');

 update sdtmmeta.sdtmm_define_vlm a set controlled=(select distinct list
                                                     from sponsor_define_xml_entries 
 where domain=a.domain
  and (variable_name=a.value or si_var=a.value))
 where (controlled is null or controlled='*');
 
 /* BJC003: Change 2: Business rule agreed to only have CT list referenced at lowest level of variables and VLM. 
    So where CT list assignment is in both vars and VLM - remove entry from vars reference */

 update sdtmmeta.sdtmm_define_domain_vars set controlled=null where trim(domain)||trim(variable_name) in 
 (select trim(domain)||trim(source) from sdtmmeta.sdtmm_define_vlm where controlled is not null)
 and index(controlled,'(')^=0;
quit;
   
/* To complete the CT section - where present, create a pdf of terminology mappings for inclusion in submission */

proc sql noprint;
create table study_term_map as 
 select * from sdtmmeta.sdtmm_define_ct
  where sdtm_value^=collected_value 
  order by list, sdtm_value;
quit; 
   
%if &sqlobs >=1 %then %do;   

 proc sort data = study_term_map nodupkey;
 by list sdtm_value collected_value;
 run;   
   
 ods listing close;
  
    ods pdf file  = "&refdata_path/controlled_terminology_mappings.pdf";    
    options orientation=landscape;
    PROC REPORT DATA = study_term_map HEADLINE HEADSKIP NOWD
         WRAP SPLIT = '*'  STYLE(column)={font_size=9 pt}                                                              
         STYLE(header)={FONT=(arial) FONT_size=9 pt font_weight=bold};

    TITLE1 "Controlled Terminology Mapping for Study %upcase(&studyid)";
	TITLE2 "NB: for LB domain, values of LBSPEC and LBMETHOD are added to uniquely identify the SDTM tests";
	Columns list sdtm_value collected_value;  		
       DEFINE collected_value 	/ DISPLAY width=200 FLOW STYLE(column)={cellwidth=35%};
       DEFINE sdtm_value    	/ DISPLAY WIDTH=200 FLOW STYLE(column)={cellwidth=35%};  
	   DEFINE list              / DISPLAY WIDTH=30 FLOW;  	 
    RUN;

 ods pdf close;                     
 ods listing;
%end;   

*********************************************************************************************;
/* Part 4: Get computational methods that refer to SDTM data (1)from DSM and (2) from SDTMCONV database */ 

proc sql noprint;
create table sdtmm_define_compmeth1 as 
 
 (select dc.memname as domain, dc.name as sdtm_variable_name, vm.si_dset as src_dataset_name, 
         dsm.var_nm as src_variable_name, dsm.var_algorithm, dsm.version_no as dsm_version_number
   from (select distinct main.var_nm, main.var_short_desc, main.var_algorithm, main.version_no
             from dsm_db.var_v main,
        (SELECT  distinct var_nm , var_algorithm, max(version_no) as maxver
           FROM dsm_db.var_v
       GROUP BY var_nm) maxresults
         WHERE main.var_nm = maxresults.var_nm
           AND main.version_no = maxresults.maxver) dsm,        
        vw_monitor_varmap vm,
        dictionary.columns dc
 where dsm.var_algorithm is not null
   and dsm.var_algorithm not like 'Decode of%'
   and upper(vm.studyid)="&studyid"
   and vm.si_var=dsm.var_nm
   and vm.origin^='DROPPED'
   and dc.libname='SDTMDATA' 
   and (dc.memname=vm.domain 
            or substr(dc.memname,5,4)=vm.domain)       
    and (trim(vm.sdtm_var)=trim(dc.name) and trim(coalesce(orig_si_var,si_var))=trim(dsm.var_nm)) );

 /* BJC003 - remove code relic of a hardcoded studyId in this query */
 
create table sdtmm_define_compmeth2 as 
  (select distinct dc.memname as domain, vm.sdtm_var as sdtm_variable_name,
          vm.si_dset as src_dataset_name, trim(coalesce(vm.orig_si_var,vm.si_var)) as src_variable_name,
          vm.instructions        
     from vw_monitor_varmap vm,
          dictionary.columns dc,
          sdtmmeta.sdtmm_define_domain_vars dv
    where vm.instructions is not null
      and dc.libname='SDTMDATA' 
      and upper(vm.studyid)="&studyid"
      and (dc.memname=dv.domain 
             or substr(dc.memname,1,4)=dv.domain)        
      and (vm.domain=dc.memname 
             or substr(dc.memname,5,4)=vm.domain)       
           and ((vm.sdtm_var=dc.name 
                and dc.name=dv.variable_name)
             or (vm.suppqual like 'YES%' and dc.name='QVAL' and dv.variable_name='QVAL'))  ) ;           
quit;     

******************************************************************************************;
/* Get all the instructions from the varmap source (can be multiples on one row) into
/  a format of one row per instruction. Each utility macro can then poll this dataset.
/  Must have entire set for current run of SI dataset and allow each utility macro to select
/  its own algorithms to process */

data sdtmm_define_compmeth2a; 
 set sdtmm_define_compmeth2;
 instructions=trim(instructions);
 posn=index(instructions,';');                      			
   if posn=0 then output;                         			
   else if posn >=1 then do;                      			
     len_all=length(trim(instructions));						
     len_semicolon=length(trim(compress(instructions,';')));			
     num_semicolons=(len_all-len_semicolon)-1;
     clause=instructions;								
      do a=1 to num_semicolons+1;							
  	 if a<=num_semicolons then do;						
          instructions=substr(clause,1,index(clause,';'));			
          clause=substr(clause,index(clause,';')+1,length(trim(clause))-index(clause,';')+1); 
  	  output;									
  	 end;										
  	 else if a=num_semicolons+1 then do;					
  	  instructions=substr(clause,1,length(clause));
          output;									
  	 end;										
  	end;										
   end;										
   drop len_all len_semicolon num_semicolons clause posn a;	
run;

data sdtmm_define_compmeth2a; 
 set sdtmm_define_compmeth2a; 

/* Strip out several algorithms that do not need to be put out to define.xml as they are transforms not derivations */
if instructions=: 'rename' then delete;
if instructions=: 'upcase' then delete;
if instructions=: 'add_label' then delete;

if instructions =:'pre_hardcode' then 
hcitem=substr(substr(instructions,14,index(instructions,';')-15),1,index(substr(instructions,14,index(instructions,';')-15),
       '=')-1);

if instructions =:'sdtm_hardcode' then do;
 endpos=index(instructions,';');
 string=substr(instructions,15,endpos-16); 
 startpos=index(string,'=');

 if (upcase(substr(string,1,2))^='IF' and upcase(substr(string,1,4))^='DROP') then hcitem=substr(string,1,startpos-1);
 else hcitem=left(reverse(substr(reverse(trim(string)),index(reverse(trim(string)),'=')+1,
                    index(reverse(trim(string)),' ')-(index(reverse(trim(string)),'=')))));
end; 
hcitem=tranwrd(tranwrd(upcase(hcitem),'ALL,',''),'IF ','');
if length(hcitem)>8 then do;
 hcitem='';
 instructions='Unlinkable SDTM conversion derivation applies here - look up in refdata/mappings or MSA web interface';
end; 

/* Due to the way some more complex algorithms are specified e.g. 'if missing(XXX)' or 'if X in ('A','B') then' 
/  these cannot be readily resolved to find the source item they pertain to, so there will be no entry retained.
/  this means that the derivation of conversion algorithms is about 90% reliable but some will be missing.
/  The missing ones are however flagged to the user in the code above. */
hcitem=left(hcitem);
run;

data sdtmm_define_compmeth3a; 
 attrib HCITEM length=$8;
 set sdtmm_define_compmeth2a; 
run; 

/* Now update the HCITEM values to either src_ or sdtm_ variable_name field to complete the link */
proc sql;
 create table temp as select * from sdtmm_define_compmeth3a;
 
 update sdtmm_define_compmeth3a a set sdtm_variable_name=(
  select hcitem 
    from temp
   where trim(domain)||trim(hcitem) in (select trim(domain)||trim(hcitem) from sdtmmeta.sdtmm_define_domain_vars) 
     and hcitem is not null
     and domain=a.domain
     and src_dataset_name=a.src_dataset_name
     and src_variable_name=a.src_variable_name
     and instructions=a.instructions)
   where hcitem is not null
     and instructions like '%hardcode%'
     and trim(domain)||trim(hcitem) in (select trim(domain)||trim(variable_name) from sdtmmeta.sdtmm_define_domain_vars);

 update sdtmm_define_compmeth3a a set src_variable_name=(
  select hcitem 
    from temp
   where trim(domain)||trim(hcitem) not in (select trim(domain)||trim(hcitem) from sdtmmeta.sdtmm_define_domain_vars) 
     and hcitem is not null
     and domain=a.domain
     and sdtm_variable_name=a.sdtm_variable_name
     and src_variable_name=a.src_variable_name
     and instructions=a.instructions)
    where hcitem is not null 
      and instructions like '%hardcode%'
      and trim(domain)||trim(hcitem) not in (select trim(domain)||trim(variable_name) 
	                                           from sdtmmeta.sdtmm_define_domain_vars);
quit;   
 
data sdtmm_define_compmeth4a(drop=endpos startpos hcitem string num instructions); 
 set sdtmm_define_compmeth3a; 
 /* Note tranwrd truncates fields to $200 - this is actually $500 but the chances of such a 
 /  long string is very small */
 var_algorithm=tranwrd(tranwrd(instructions,'pre_',''),'sdtm_','');
   num=_n_;
run;  

/* Add standard comp method defaults for USUBJID, IDVARVAL, QVAL and --SEQ vars */
proc sql noprint;
 create table sdtmm_define_compmeth5 as 
 select domain, variable_name as sdtm_variable_name
   from sdtmmeta.sdtmm_define_domain_vars
  where variable_name in ('USUBJID','IDVARVAL','QVAL') or substr(variable_name,3,3)='SEQ' 
  or substr(variable_name,3,2)='DY' or substr(variable_name,3,4)='STDY' or substr(variable_name,3,4)='ENDY' 
  or substr(variable_name,3,4)='BLFL' or substr(variable_name,3,6) in ('STRESN','STRESC','STRESU');
quit;

data sdtmm_define_compmeth5; set sdtmm_define_compmeth5;
 length var_algorithm $500;
 if sdtm_variable_name='USUBJID' 
  then var_algorithm="Original STUDYID concatenated with '.' concatenated with original SUBJID. Unless same subject
  participated in another study, then a unique USUBJID across the submission is assigned.";
 else if substr(sdtm_variable_name,3,3)='SEQ' then 
     var_algorithm="Within USUBJID, --SEQ=1 for the first record, increment by 1 for each additional record";
 else if sdtm_variable_name='IDVARVAL' then var_algorithm='Value of source data key field';
 else if sdtm_variable_name='QVAL' then var_algorithm='Value of source data field';
 else if sdtm_variable_name in ('&&or_nm&c','LBSTRESC','LBSTRESU') 
  then var_algorithm='Lab conversion applied to SI units where applicable';
 else if substr(sdtm_variable_name,3,6) in ('STRESN','STRESC','STRESU') then var_algorithm='Copy of source data field';
 else if substr(sdtm_variable_name,3,4)='BLFL' 
  then var_algorithm='Last test prior to treatment start [EX.EXSTDTC]';
 else if substr(sdtm_variable_name,3,2)='DY' 
  then var_algorithm='--DY variables use the subjects DM.RFSTDTC as the reference date.';
 else if substr(sdtm_variable_name,3,4)='STDY' 
  then var_algorithm='--DY variables use the subjects DM.RFSTDTC as the reference date.';
 else if substr(sdtm_variable_name,3,4)='ENDY' 
  then var_algorithm='--DY variables use the subjects DM.RFSTDTC as the reference date.';
run;

/* Append the two set of computational methods we have got so far. */
data sdtmm_define_compmeth; 
 attrib var_algorithm length =$2000.;
 format var_algorithm   ;
 informat var_algorithm   ;

 set sdtmm_define_compmeth4a
     sdtmm_define_compmeth1
     sdtmm_define_compmeth5; 
run;   

/* We can only have one row per domain/variable combination 
/  - so any examples where >1 row present need to be rolled up */ 

proc sort data=sdtmm_define_compmeth; 
 by domain sdtm_variable_name src_variable_name;
run;
 
data sdtmm_define_compmeth cm_rollup; 
 set sdtmm_define_compmeth;
  by domain sdtm_variable_name src_variable_name;

  if first.src_variable_name+last.src_variable_name=2 then output sdtmm_define_compmeth;
  else output cm_rollup;
run; 

/* Provide the algorithms with their source details for user reference - these may be removed during editing 
/  but actually provide useful details if multiple sources are involved */

data cm_rollup(drop=src_dataset_name src_variable_name dsm_version_number var_algorithm );
 set cm_rollup;
 by domain sdtm_variable_name src_variable_name;
 length new_alg $2000;
 retain new_alg last_alg;
 if first.src_variable_name  
    then new_alg='['||trim(src_dataset_name)||'.'||trim(src_variable_name)||']:'||trim(var_algorithm);
  else if last_alg^=var_algorithm then new_alg=trim(new_alg)||' '||trim(var_algorithm);
  last_alg=var_algorithm;
  if last.src_variable_name then output;
run; 

proc sql noprint;
 select count(distinct domain||sdtm_variable_name) into :num_combs from cm_rollup;
 
 create table dist_combs as select distinct domain ,sdtm_variable_name from cm_rollup;
quit;

/* run datastep to populate _n_ as proc sql doesnt do this ! */
data dist_combs;
 set dist_combs;
run;

/* Loop through each domain-variable combination with >1 row and roll up the details into one row */
%do f=1 %to &sqlobs;

 %if &f=1 %then %do;
  proc sql noprint;
   alter table dist_combs add var_algorithm char(2000);
  quit;
 %end;

 data _null_;
  set dist_combs;
   if _n_=&f then do;
    call symput ('sdtm_variable_name',trim(sdtm_variable_name));
    call symput ('domain',trim(domain));
   end;    
  run;
  
  proc sql noprint;
   select distinct trim(new_alg) into :new_alg&f separated by ' ' 
    from cm_rollup 
   where domain="&domain" and sdtm_variable_name ="&sdtm_variable_name";
  quit;
  
  proc sql noprint;
   update dist_combs set var_algorithm=("&&new_alg&f") where domain="&domain" 
   and sdtm_variable_name ="&sdtm_variable_name";
  quit;
%end;

data sdtmmeta.sdtmm_define_compmeth; 
 set dist_combs 
     sdtmm_define_compmeth;
 format var_algorithm   ;
 informat var_algorithm   ;     
run;   

*********************************************************************************************************;
/* BJC003: add more explanatory comments here: 
   The last section ! - Finally provide a dataset of anything the user needs to be aware of and address.
   Query for and provide these issues in a to_do list stored in a SAS dataset in /refdata */

/* BJC003 - amend the code to run for subset/filtered REs where a subset of total SDTM data converted is present */
   
   
proc sql;
 create table to_do1 as 
select c.domain, c.variable_name, trim(c.origin)||
' ORIGIN: nulls can be caused by added null Expected columns, CRF means no eCRF page link (can often correct to eDT ?), or complex mapping. [CRF valid as superset if row refers to VLM]' as problem 
  from (select a.domain, a.variable_name, a.origin 
     from sdtmmeta.sdtmm_define_domain_vars a
    where (a.origin is null or a.origin='CRF')
	and substr(reverse(trim(variable_name)),1,4)^='TSET' 
	and substr(reverse(trim(variable_name)),1,6)^='DCTSET' 
    and substr(reverse(trim(variable_name)),1,5)^='SERRO' 
	and substr(reverse(trim(variable_name)),1,6)^='USERRO' 
    and variable_name not in ('QVAL','QORIG')
	
	%if %sysfunc(exist(sdtmmeta.sdtmm_define_vlm)) %then %do;
 	 UNION 
	 select b.domain, b.value as variable_name, b.origin 
	  from sdtmmeta.sdtmm_define_vlm b
     where b.origin is null or b.origin='CRF'
	%end; 
	
	 ) c ; 

 create table to_do2 as 
 select domain, variable_name, 'Source DERIVED variable with no computational method' as problem
  from sdtmmeta.sdtmm_define_domain_vars
 where origin='DERIVED'
   and added=''   
   and trim(domain)||trim(variable_name) not in 
  (select trim(domain)||trim(sdtm_variable_name) from sdtmmeta.sdtmm_define_compmeth);
   
 create table to_do3 as 
 select domain, variable_name, 'Variable added by conversion with no computational method' as problem
   from sdtmmeta.sdtmm_define_domain_vars
  where added='Y' and origin ='DERIVED'   
    and trim(domain)||trim(variable_name) not in 
  (select trim(domain)||trim(sdtm_variable_name) from sdtmmeta.sdtmm_define_compmeth);   

 create table to_do4 as 
 select 'MULTIPLE' as domain, 'MULTIPLE' as variable_name ,var_algorithm as problem from
 (select distinct 'REPEATS OF:'||var_algorithm as var_algorithm, count(*), 
   count(sdtm_variable_name), count(distinct sdtm_variable_name)
  from sdtmmeta.sdtmm_define_compmeth
  group by var_algorithm
  having count(*) >1 and count( distinct sdtm_variable_name) >1);  

 create table to_do5 as select distinct 'MULTIPLE' as domain, 'MULTIPLE' as variable_name , 
 trim(codelist_nm)||' codelist is in study Spectre spec but not present at all in define.xml 
 (usual cause is complex mapping)' as problem from 
 (select codelist_nm from spec 
   where codelist_nm is not null and codelist_nm ^='()'
     and si_dset in 
        (select basetabname from vw_monitor_view_tab_list)
 except
 (select distinct list as codelist_nm from sdtmm_define_ct 
  union
  select distinct idsllist as list from cdisc_and_sponsor where idsllist is not null));
 
 create table to_do6 as select distinct 'MULTIPLE' as domain, 'MULTIPLE' as variable_name , 
 trim(list)||' codelist is in master define CT but not linked to a domain var or VLM entry 
 (complex mapping/CT is usual cause). HARP_USED flag will be set to N.' as problem from 
 (select distinct a.list from dxe a
  except
  (select distinct b.controlled as list from sdtmmeta.sdtmm_define_vlm b
   union
   select distinct c.controlled as list from sdtmmeta.sdtmm_define_domain_vars c));
quit;  
 
data sdtmmeta.sdtmm_define_to_do;
 attrib domain length=$8;
 attrib variable_name length=$8;
 attrib problem length=$500;
 set to_do1 to_do2 to_do3 to_do4 to_do5 to_do6;
run; 

/* code to pass control back to HARP process */
DATA _webout.results_label (KEEP=results_label);
    results_label="Done";        
RUN;  
  
%mend gen_define_meta;
%gen_define_meta;
