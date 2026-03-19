/******************************************************************************* 
|
| Macro Name: tu_sdtmconv_sys_setup
|
| Macro Version/Build: 8 build 1
|
| SAS Version: SAS 9.1.3
|
| Created By: Bruce Chambers
|
| Date:            12-Aug-2009
|
| Macro Purpose: Set-up various environment and metadata sources needed for SDTM conversion
|
|                Oracle passwords are stored in a macro catalog that is not accessible to users,
|                set macro vars to get the connection details. The passwords are subject to 
|                later %symdel commands once they are used.
|
|                Create PRE_SDTM, MID_SDTM and PST_SDTM work libraries under /saswork/<sessionid> 
|                directory so that the large number of work datasets are helpfully separated
|                to avoid confusion and faciliatate debugging.  
|
|                Query Spectre to get study specific dataset specs from Spectre 
|                Query DSM to get selected item level metadata (where var.codelist_nm is not null 
|                                                           or var.clinical_dict is not null)
|                Query DSM to get selected dataset level metadata
|                Query DSM to get code-decode relationship metatdata
|                Query DSM to get (max version of) variable labels from DSM to add using attrib 
|                                              (NOTE: includes archived variables)
|                Query DSM for the codelist name details needed
|
|                Steps to join some of the above data into the format needed to process SDTM conversion
|
|                Query the SITOSDTM oracle schema for conversion mapping metadata - 7 tables
|
|                Create template mid_sdtm.study_t normalised dataset
|
|                Import study specific varmap and si_rules entries if present for study being run
|
|                Get list of domains with NO --SEQ item e.g. DM as this is used later on
|
|                Create a series of SDTM specific SAS formats to use to decode data to the SDTM/CDISC 
|                controlled terms. Most are managed in the term_map data source. 
|
|                Process the instructions/algorithms from multiple entries per row in the varmap data source
|                into one row per instruction to faciliate later processing.
|
| Macro Design: Procedure
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
|(@) tu_tidyup
|(@) tu_sdtmconv_sys_message
|(@) tu_sdtmconv_sys_error_check
|
| Example:
|
|******************************************************************************* 
| Change Log 
|
| Modified By:                   Bruce Chambers
| Date of Modification:     	 10Mar2010      
| New Version/Build Number: 	 V1 Build 2    
| Description for Modification:  Length of instructions field increased in the database but the field was too big 
|                                for some of the later proc sql to deal with. As the setup breaks the string into 
|                                individual instructions, set the size of each instruction to a limit of 500
| Reason for Modification:       To prevent later errors in proc sql with char(4000) field sizes
|
| Modified By:                   Bruce Chambers
| Date of Modification:     	 24May2010      
| New Version/Build Number: 	 V2 Build 1    
| Reference:                     BJC001
| Description for Modification:  Left justify instructions field
| Reason for Modification:       To prevent later errors in parsing definitions if leading spaces are present
|                                theese could be from UI mapping table or study specific mapping files
|
| Modified By:                   Bruce Chambers
| Date of Modification:     	 13August2010      
| New Version/Build Number: 	 V3 Build 1    
| Reference:                     BJC002
| Description for Modification:  Flag varmap.csv overrides of MSA maps versus study specific mappings
| Reason for Modification:       To give clarity in user output later
|
| Modified By:                   Deepak Sriramulu
| Date of Modification:     	 06September2010      
| New Version/Build Number: 	 V3 Build 1    
| Reference:                     DSS001
| Description for Modification:  Add libname statement which combines both DM and A&R into one
| Reason for Modification:       This libname statement is used in bespoke processing macros so it has been kept in one place 
|
| Modified By:                   Bruce Chambers
| Date of Modification:     	 06September2010      
| New Version/Build Number: 	 V3 Build 1    
| Reference:                     BJC003
| Description for Modification:  Make DSM dataset and variable query pick up exemption datasets
| Reason for Modification:       Ensure complete listing of unmapped SI variables  
|
| Modified By:                   Ashwin Venkat
| Date of Modification:     	 07September2010      
| New Version/Build Number: 	 V3 Build 1    
| Reference:                     VA001
| Description for Modification:  Removed code for creation of SDTM libname, Because SDTMDATA library is automatically created by new    
| Reason for Modification:       version of ts_setup macro                                                                               
|
| Modified By:                   Bruce Chambers
| Date of Modification:     	 22November2010      
| New Version/Build Number: 	 V4 Build 1    
| Reference:                     BJC004
| Description for Modification:  Only populate jobs from production servers into MONITOR_JOB Oracle table
| Reason for Modification:       Old code populated all jobs, even where run on DEV/TST database but using                                                                               
|                                the production database.
|
| Modified By:                   Bruce Chambers
| Date of Modification:     	 22November2010      
| New Version/Build Number: 	 V4 Build 1    
| Reference:                     BJC005
| Description for Modification:  Define studyt1 table - instead of studyt. Also initialise num_mid counter. 
| Reason for Modification:       New code allows for multiple study_t tables.- this code defines the template for the first one
|                                from which any others are copied.
|
| Modified By:                   Bruce Chambers
| Date of Modification:     	 22November2010      
| New Version/Build Number: 	 V4 Build 1    
| Reference:                     BJC006
| Description for Modification:  Flag rows in varmap that have Draft rows in MSA. 
| Reason for Modification:       Give conversion programmer clear list of mappings to be promoted to Approved in MSA
|
| Modified By:                   Ashwin Venkat
| Date of Modification:     	 10January2011      
| New Version/Build Number: 	 V4 Build 1    
| Reference:                     VA002
| Description for Modification:  Added format for LBLOC. 
| Reason for Modification: 
|
| Modified By:                   Bruce Chambers
| Date of Modification:     	 22November2010      
| New Version/Build Number: 	 V4 Build 1    
| Reference:                     BJC007
| Description for Modification:  Resize varmap data as it is read in - due to a quirk of oracle it is 3x larger 
| Reason for Modification:       Reduce dataset size and I/O
|
| Modified By:                   Bruce Chambers
| Date of Modification:     	 22November2010      
| New Version/Build Number: 	 V4 Build 1    
| Reference:                     BJC008
| Description for Modification:  Remove Draft MSA rows from varmap and varmap_all- system used draft to check the  
| Reason for Modification:       study specific varmap file 
|
| Modified By:                   Ashwin Venkat(va755193)
| Date of Modification:     	 3May2011      
| New Version/Build Number: 	 V5 Build 1    
| Reference:                     VA003
| Description for Modification:  use Draft MSA rows from varmap and varmap_all when in arwork else delete Draft rows
| Reason for Modification:       sthis helps simplify testing of draft varmap entry in MSA
|
| Modified By:                   Deepak Sriramulu
| Date of Modification:     	 25April2011
| New Version/Build Number: 	 V5 Build 1    
| Reference:                     DSS002
| Description for Modification:  Add formats for PCREASND and PPREASND variables
| Reason for Modification:       The two letter codes in the PC and PP data need to be decoded to the full english.
|
| Modified By:                   Bruce Chambers
| Date of Modification:     	 15May2011
| New Version/Build Number: 	 V5 Build 1    
| Reference:                     BJC009
| Description for Modification:  Add formats and informat for varmap data
| Reason for Modification:       Prevent strange behaviour later
|
| Modified By:                   Ashwin Venkat
| Date of Modification:     	 19Apr2012
| New Version/Build Number: 	 V6 Build 1    
| Reference:                     VA004
| Description for Modification:  preserve study review flagging for mapping that is coming from varmap.csv
| Reason for Modification:       prevents overlooking study review comments 
|
| Modified By:                   Bruce Chambers
| Date of Modification:     	 04Jul2012
| New Version/Build Number: 	 V6 Build 1    
| Reference:                     BJC010
| Description for Modification:  use spectre study spec instead of DSM master spec
| Reason for Modification:       removes versioning issues and solves other problems too
|
| Modified By:                   Bruce Chambers
| Date of Modification:     	 04Oct2012
| New Version/Build Number: 	 V6 Build 1    
| Reference:                     BJC011
| Description for Modification:  MSA default for SUPP amended to YES[SEQ] for user clarity
| Reason for Modification:       system expects YES for SUPP joins - amend as data read in to avoid complex
|                                code updates elsewhere.
|
| Modified By:                   Ashwin Venkat(va755193)
| Date of Modification:     	 19Oct2012
| New Version/Build Number: 	 V6 Build 1    
| Reference:                     VA005
| Description for Modification:  MSA amended to have mapping for different SDTMIG versions, so modified code to use user 
| Reason for Modification:       specified versions, if not provided then take default version from MSA
|
| Modified By:                   Ashwin Venkat(va755193)
| Date of Modification:     	 19Oct2012
| New Version/Build Number: 	 V6 Build 1    
| Reference:                     VA006
| Description for Modification:  new version of MSA has VLM tab, so amended macro to use information from VLM tab, and create 
| Reason for Modification:       a sdtm_pre_hardcode algorithm in instructions dataset
|
| Modified By:                   Bruce Chambers
| Date of Modification:     	 19Oct2012
| New Version/Build Number: 	 V7 Build 1    
| Reference:                     BJC012
| Description for Modification:  Back out SDTM_version filter on si_rules (source dataset flags) as all are 3.1.2
| Reason for Modification:       Process normalised source data correctly
|
| Modified By:                   Bruce Chambers
| Date of Modification:     	 16Jul2013
| New Version/Build Number: 	 V8 Build 1    
| Reference:                     BJC013
| Description for Modification:  Amend and move definition of combine libname
| Reason for Modification:       To allow continuation study to re-use previous pseudo-RACE data
|
| Modified By:                   Bruce Chambers
| Date of Modification:     	 28aug2013
| New Version/Build Number: 	 V8 Build 1    
| Reference:                     BJC014
| Description for Modification:  Add EVLINT format entry 61 -> -P30D
| Reason for Modification:       To allow correct ISO8601 representation of intervals where possible
|
********************************************************************************/ 

%macro tu_sdtmconv_sys_setup(
);

%let _cmd = %str( );%tu_sdtmconv_sys_message;
%let _cmd = %str(SDTM data conversion starting );%tu_sdtmconv_sys_message;
%let _cmd = %str( );%tu_sdtmconv_sys_message;

/* Permanent options - NOT FOR TOGGLING ON/OFF */
options missing='' nodate nofmterr mrecall spool ps=55 ls=80 validvarname=upcase;


/*VA001*/
/*Removed code for creation of SDTM libname, Because SDTMDATA library is automatically created by new 
/ version of ts_setup macro
/------------------------------------------------------------------------------------------------*/

/*
/ locate SAS work area and use it to hold CSV file results in later steps
/------------------------------------------------------------------------------------------------*/
   /* Use of __UTC_WORKPATH for unit testing only */
   /* The purpose of the __UTC_WORKPATH is to redirect datasets in the PRE_SDTM, MID_SDTM and       */
   /* PST_SDTM libnames to an external unix area for interrogation.                                 */
   /* Other macros effected by _UTC_WORKPATH are tu_sdtmconv_mid_flip_si and tu_sdtmconv_mid_append */
   /* which have been altered to not clean up the PRE_SDTM and MID_SDTM directories respectively    */
   /* if _UTC_WORKPATH has been set.                                                                */
   /* The wrapper macro tc_sdtmconv will only clear up in batch if __UTC_WORKPATH has been set      */
   
   %global work_path;

   %if %symexist(__utc_workpath) %then %do;
     %if %sysfunc(fileexist(%cmpres(&__utc_workpath))) ne 1 %then %do;
       %let _cmd = %str(%str(RTE)RROR: UTC workpath does not exist - aborting );  %tu_sdtmconv_sys_message;
       %let syscc=999;
       %tu_sdtmconv_sys_error_check;
     %end;
     %else %do;
       /* Clear up __UTC_WORKPATH areas */
       %if %sysfunc(fileexist(%cmpres(&__utc_workpath./pre_sdtm))) eq 1 %then %do; 
         x rm -Rf %cmpres(&__utc_workpath./pre_sdtm);
       %end;
       %if %sysfunc(fileexist(%cmpres(&__utc_workpath./main_sdtm))) eq 1 %then %do;
          x rm -Rf %cmpres(&__utc_workpath./main_sdtm);
       %end;
       %if %sysfunc(fileexist(%cmpres(&__utc_workpath./pst_sdtm))) eq 1 %then %do;
          x rm -Rf %cmpres(&__utc_workpath./pst_sdtm);
       %end;

       %if %sysfunc(fileexist(&__utc_workpath)) ne 1 %then %do;
          x mkdir &__utc_workpath;  
       %end;
       %let work_path = %cmpres(&__utc_workpath)/;
     %end;
   %end;
   %else %do;
     proc sql noprint;
        select distinct path into :work_path
        from dictionary.members where libname = 'WORK';
     quit;
     %let work_path = %cmpres(&work_path)/;
   %end;

/*
/ Create the SAS Registry file to change Proc Import guessing rows option on the fly...
/------------------------------------------------------------------------------------------------*/
   filename reg_updt "&work_path.registry_update.sasxreg" NEW ;
   data _NULL_;
      file reg_updt ;
      put '[HKEY_USER_ROOT\PRODUCTS\BASE\EFI]';
      put '"GuessingRows"=int:217483648';
   run;

/*
/ Import new Registry value
/------------------------------------------------------------------------------------------------*/
   proc registry import="&work_path.registry_update.sasxreg";
   run;

/* Set up items required by the SDTMCONV the environment */
%let _cmd = %str(Setting up SDTM conversion environment);
%tu_sdtmconv_sys_message;

/* Setup environment to get Oracle password to Query Spectre/DSM and GRIP */

/* Cannot clear a libname createdusing MSTORE. If a user repeats interactive runs they will
/ get an error if thelibname tries to get reassigned, so only assign it the first time round */
proc sql noprint ;
  select count(distinct libname) into :sourceLibFound
  from dictionary.libnames
  where upcase(libname) eq 'SOURCE';
quit ;

%if not(&sourceLibFound) %then %do ;
   libname source '/local/apps/comntools/sdtm_pw' access=readonly;
%end;

%global mip_ac  mip_pw  mip_db
        spec_ac spec_pw spec_db
        dsm_ac  dsm_pw  dsm_db
        benv_ac benv_pw codes_db
        sdtm_ac sdtm_pw sdtm_db;

options mstored sasmstore=source nomprint nomlogic nosymbolgen nosource nosource2 nonotes;
%sdtm_pw;

/*
/*  Check if the user provided VERSIONING_DT parameter is set to a date
/*  prior to SDTMCONV database creation date.  If so abort the run to avoid
/*  SAS blowing up.
/*****************************************************************************/
%if &versioning_dt ne %then %do;
   %local min_date err_flag;
   %let min_date =;

   proc sql noprint;
      connect to oracle (username=&sdtm_ac password=&sdtm_pw path=&sdtm_db);
         select createtime into :min_date
            from connection to oracle
           (select to_char(min(createtime),'DD-MON-YYYY HH24:MI') AS CREATETIME
                FROM mapping_si_rules_approved_lt);  /* Find the record with minimum date in this table */
      disconnect from oracle;
   quit;
   %let min_date = &min_date;

   %let err_flag = 0;  /* Assume the date is OK */
   data _NULL_;
      if "&versioning_dt"dt LT "&min_date"dt + 86400 then call symput('err_flag','1');
   run;
  
   %if &err_flag %then %do;
      %let _cmd = %str(%str(RTE)RROR: User versioning_dt parameter is prior to DB creation - aborting );  %tu_sdtmconv_sys_message;
      %let syscc=999;
      %tu_sdtmconv_sys_error_check;
    %end;

%end; /* %if &versioning_dt ne %then %do  */


libname sdtm_db oracle username=&sdtm_ac password=&sdtm_pw path=&sdtm_db
   DBCONINIT="EXEC dbms_wm.gotodate(%unquote(&versioning_dt),%unquote(%str(%')ddmonyyyy hh24:mi%str(%')))";
option nonotes;

** Set error flag back to 0 - be = 1 from password macro **;
%let syscc=0;

options &set_options;

/*
/* Add a record to the MONITOR_JOB table to show details about the job run
/****************************************************************************/

/* BJC004: dont populate system job table if job run from DEV/TST server but using PRD mappings */
%if not %symexist(prd_query) %then %do;
 proc sql noprint;
   insert into sdtm_db.vw_monitor_job 
       set study_id = "&g_study_id", 
           user_id = "%upcase(&sysuserid)", 
           hostname = "%sysget(HOSTNAME)",
           timestamp = datetime();
 quit;
%end;
/* Create separate SDTM work directories UNDER saswork dir for MAIN, PRE and POST processing */
%if %sysfunc(fileexist(&work_path.pre_sdtm)) ne 1 %then %do;
  x mkdir &work_path.pre_sdtm;  
%end;

libname pre_sdtm "&work_path.pre_sdtm";

%if %sysfunc(fileexist(&work_path.pst_sdtm)) ne 1 %then %do;
  x mkdir &work_path.pst_sdtm;  
%end;
libname pst_sdtm "&work_path.pst_sdtm";

%if %sysfunc(fileexist(&work_path.main_sdtm)) ne 1 %then %do;
  x mkdir &work_path.main_sdtm;  
%end;
libname mid_sdtm "&work_path.main_sdtm";

/* DSS001*/
/* Setup libname so that bespoke processing macros can refer to ardata or dmdata libraries, 
   ARDATA will be used in preference */

/* BJC013 : to allow continuation study to re-use previous pseudo-RACE data */
libname combine (pre_sdtm ardata dmdata);  

******************************************************************************;
* Queries to Oracle to get details of SI specs from Dataset Manager/Spectre [and Clintrial for codelists - see note in code] **;

** Reset options temporarily to prevent password being echoed under any circumstance *;
options nomprint nomlogic nosymbolgen nosource nosource2 nonotes;

%let _cmd = %str(Querying Dataset Manager/Spectre for the SI spec and codelist details needed); %tu_sdtmconv_sys_message;
proc sql; connect to oracle
   (user=&dsm_ac orapw=&dsm_pw path=&dsm_db buffsize=500);
 %if &sqlrc GE 8 %then %do;
  %let _cmd = %str( Oracle Connection issue Occured); %tu_sdtmconv_sys_message;
 %end;
 
  /* Query to get study specific dataset specs from Spectre 
     Adding "and stnd_dataset_type_desc is null" here makes the query perform badly - subset later for speed! */
	 
	 /* BJC010 : add version columns to query */
  create table study_specific_meta as select * from connection to oracle
    (select %str(/)%str(*)+ use_nl(a,b,c) %str(*)%str(/)    
            b.dataset_nm ,
            b.var_nm ,
            b.codelist_nm,
            b.clinical_dict, 
            c.stnd_dataset_type_desc,
            'Y' as dm_subset_flag,
			b.version_no as var_ver,
			c.thrpy_nm,
			c.sub_thrpy_nm
       from study_spec_max_v a, spec_ds_info_var_detail_v b , spec_dataset_info_v c     
      where a.spec_id=b.spec_id
	    and b.spec_id=c.spec_id
		and b.dataset_nm=c.dataset_nm
        and a.spec_type='01'         
       and a.study_id=upper(%unquote(%str(%')%upcase(&g_study_id)%str(%'))));
 
   /* Query to get item level metadata and (var.codelist_nm is not null or var.clinical_dict is not null) */
   /* BJC003: update query to include exemption dataset definitions */
   /* BJC010 : add version columns to query */
   create table dsm_meta as select * from connection to oracle
    
      (SELECT   'N' as exemp, ds.dataset_nm, ds.dataset_nm as dsname_x, ds.thrpy_nm, ds.sub_thrpy_nm,
         var.var_nm, var.codelist_nm, var.clinical_dict,
         var.sid_subset_flag AS dm_subset_flag, var.ar_subset_flag, ds.version_no as ds_ver, var.version_no as var_ver
       FROM spectre_ds_owner.dataset_standard_max_v ds,
         spectre_ds_owner.dataset_var_appr_v var
       WHERE ds.dataset_stnd_id = var.dataset_stnd_id
       AND ds.dataset_nm NOT LIKE '%\_X' ESCAPE '\'
      UNION 
       SELECT   'Y' as exemp, ds.dataset_nm, dsx.dataset_nm as dsname_x , ds.thrpy_nm, ds.sub_thrpy_nm,
         var.var_nm, var.codelist_nm, var.clinical_dict,
         var.sid_subset_flag AS dm_subset_flag, var.ar_subset_flag, ds.version_no as ds_ver, var.version_no as var_ver
       FROM spectre_ds_owner.dataset_standard_max_v ds,
         spectre_ds_owner.dataset_standard_max_v dsx,
         spectre_ds_owner.dataset_var_appr_v var
       WHERE dsx.dataset_nm = SUBSTR (ds.dataset_nm, 1, 6) || '_X'
       AND dsx.thrpy_id = ds.thrpy_id
       AND dsx.dataset_stnd_id = var.dataset_stnd_id
       AND ds.dataset_nm NOT LIKE '%\_X' ESCAPE '\'
       AND dsx.dataset_nm LIKE '%\_X' ESCAPE '\'
      ORDER BY  2, 3);

   /* Query to get dataset level metatdata */
   create table dsm_tabs as select * from connection to oracle
   
  (select dataset_nm as si_dset, dataset_type_desc,thrpy_nm, sub_thrpy_nm,dataset_notes,
   dataset_structure_desc,version_status_desc,  archive_flag, chg_desc
   from spectre_ds_owner.dataset_standard_max_v 
   order by dataset_nm);
   
   /* Query to get code-decode relationship metatdata */
   create table dsm_var_rel as select * from connection to oracle
   (select code.var_nm as code, 
          decode.var_nm as decode
          from var_cat code,
               var_cat decode,
                var_relationship rel
            where rel.parent_var_cat_id=code.var_cat_id
              and rel.child_var_cat_id=decode.var_cat_id
              and var_rel_type_id=1);           
   
   /* Query to get (max version of) variable labels from DSM to add using attrib (includes archived variables)*/
       create table label_dsm as select * from connection to oracle
          (select main.var_nm as name, main.var_short_desc, main.version_no
             from spectre_ds_owner.var_v main,
               (SELECT  var_nm , max(version_no) as maxver
                  FROM spectre_ds_owner.var_v
                GROUP BY var_nm) maxresults
         WHERE main.var_nm = maxresults.var_nm
           AND main.version_no = maxresults.maxver);

   /* Querying for the codelist name details needed */

   create table fmtnames as select * from connection to oracle
   (SELECT codelist as codelist_nm, format_name as format_nm, codetype
      FROM SPECTRE_DM_SELECT.CODELIST_DETAILS_BO
     where codelist not like 'CTS_%' and
                 codelist not like 'CTS$%' and
                 codelist not like 'CTG$%'
  ORDER BY codelist);
 disconnect from oracle;
 %if &sqlrc GE 8 %then %do;
  %let _cmd = %str(Oracle Query issue Occured); %tu_sdtmconv_sys_message;
  %tu_sdtmconv_sys_error_check;
 %end;
quit;

/* Reset SAS options back to user specified default to protect passwords */
options &set_options;

/* BJC010: Use study spec as main driver instead of DSM specs. */

/* We used to remove core and TST specs from study_specific_meta dataset as we got the most recent version from DSM. 
/  The reason for not using Spectre specs for CORE and TST is that some follow on studies use datasets
/  from the parent studies and so the follow on study SI spec may not have all datasets that were actually 
/  used in the follow on studies.
/  However, we now wish to use the study specific specs where available, and augment with DSM specs for any absent parts 
/  e.g. the follow on study scenario above */


/* update the study spec details to show which are exemption variables */
proc sql noprint;
 alter table study_specific_meta add exemp char(1);
 update study_specific_meta ssm set exemp=(select exemp from dsm_meta
 where dataset_nm=ssm.dataset_nm
   and var_nm=ssm.var_nm
   and sub_thrpy_nm=ssm.sub_thrpy_nm
   and thrpy_nm=ssm.thrpy_nm);
quit;   

/* Separate out true study specific specs versus copies of DSM Core/TST specs */
data study_specific_meta dsm_meta2; 
 set study_specific_meta;
 if stnd_dataset_type_desc^='' then output dsm_meta2;
 else output study_specific_meta;
run;

/* Remove from the main DSM dataset rows where the study spec has that row already */
proc sql;

 create index dataset_nm on dsm_meta ;
 create index var_nm on dsm_meta ;

 create index dataset_nm on dsm_meta2 ;
 create index var_nm on dsm_meta2 ;


 delete from dsm_meta dsm1 where exists 
 (select * from dsm_meta2 dsm2 
 where dsm1.dataset_nm=dsm2.dataset_nm
   and dsm1.var_nm=dsm2.var_nm
   and dsm1.sub_thrpy_nm=dsm2.sub_thrpy_nm
   and dsm1.thrpy_nm=dsm2.thrpy_nm);
 quit;  

 /* finally append the datasets specs from the study spec to the main core set from DSM (for all datasets) */
 data dsm_meta;
  set dsm_meta dsm_meta2 study_specific_meta;
 run;

 /* Drop var_ver and exemp as not needed */
 data study_specific_meta;
  set study_specific_meta(drop=var_ver exemp);
 run;

 /* End of BJC010 change */
 
/* combine datasets from above queries to get dataset with code-decode pairs and formats 
/  used, needed to automate input for tu_decode macro */

proc sql;
  create table fmtvars as
  select distinct c.decode, a.var_nm, a.var_nm as name, b.*
  from dsm_meta a,
       fmtnames b,
       dsm_var_rel c
  where a.codelist_nm = b.codelist_nm
    and a.var_nm=c.code
    order by a.var_nm;
quit; 

/*VA005: MSA amended to have mapping for different SDTMIG versions, so modified code to use user 
/ specified versions, if not provided then take default version from MSA
*/

 /*
 /Extract from Oracle the Default SDTM version data
 /*******************************************************************************************/

data sdtmversions ;
    set sdtm_db.sdtm_versions;

run;

   proc sql noprint;
        select version_name into :sdtm_ver 
            from sdtm_db.sdtm_versions
            %if %symexist(sdtm_version)  %then %do;
				%if %length(&sdtm_version) ne 0 %then %do;
                	where compress(version_name) = compress("&sdtm_version")
				%end;
				%else %do;
					where compress(default_version) = 'Y'
				%end;
            %end;
            %else %do;
                where compress(default_version) = 'Y'
            %end;;
    quit;

    %if not %symexist(sdtm_ver) %then %do;
       %put %str(RTE)RROR: SDTM version number &sdtm_version does not exist in MSA;  
       %let g_abort=1;
    %end;

 /*
 / If any errors have been identified, abort.
 /----------------------------------------------------------------------------*/
 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;

 /*
 / Extract from Oracle the VARMAP data
 /*******************************************************************************************/
 

 /* BJC006: use min view so we get draft and approved rows in varmap - drop some additional columns 
            available in this view but not needed */
   data varmap;
      set sdtm_db.vw_mapping_varmap_min(where=(compress(sdtm_ig_version) = "&sdtm_ver"));
   run;

**When transposed the length of si_var in study_t increases - this must match the xls file size 
  so artifically set both of them to avoid merge warnings **;
  
  /* BJC007: Set specific attributes to make data set smaller - as this gets merged onto the normalised
     study data, the smaller it is the faster it will process. These attribs all match the database attribs. */
  /* BJC009:  Add formats and informat for varmap data - prevent strange behaviour later */
  
   data varmap_all; 
      attrib si_var       length=$8   format=$8.  informat=$8.;
      attrib si_dset      length=$8   format=$8.  informat=$8.;
      attrib origin       length=$9   format=$9.  informat=$9.;
      attrib domain       length=$6   format=$6.  informat=$6.;
      attrib sdtm_var     length=$8   format=$8.  informat=$8.;
      attrib suppqual     length=$32  format=$32. informat=$32.;
      attrib study_review length=$1   format=$1.  informat=$1.;
      attrib evaluator    length=$50  format=$50. informat=$50.;      
      set varmap(rename=(ALGORITHMS=INSTRUCTIONS) drop=DESCRIPTION GENERIC_MAPPING VARMAP_ID READY_FOR_REVIEW);
   run;


 /*
 / Extract from Oracle the EXCLUDED data
 /*******************************************************************************************/
   data excluded;
      set sdtm_db.vw_mapping_excluded;
   run;

 /*
 / Extract from Oracle the DOMAIN VAR REF data
 /*******************************************************************************************/
   data reference;
      set sdtm_db.vw_mapping_domain_var_ref(where=(upcase(status)='APPROVED' and compress(sdtm_ig_version) = "&sdtm_ver"));
   run;

 /*
 / Extract from Oracle the DOMAIN REF data
 /*******************************************************************************************/
   data domain_ref;
      set sdtm_db.vw_mapping_domain_ref(where=(upcase(status)='APPROVED' and compress(sdtm_ig_version) = "&sdtm_ver"));
   run;

/*
 / Extract from Oracle the FORM LEVEL METADATA data
 /*******************************************************************************************/
   data vlm;
      set sdtm_db.vw_mapping_vlm_all(where=(upcase(status)='APPROVED' ));
   run;
 /*
 / Extract from Oracle the SI RULES data
 /*******************************************************************************************/
 /* BJC012 - back out filter on SDTM version as not actually applicable to this data so values are static */
   data si_rules;
      set sdtm_db.vw_mapping_si_rules(where=(upcase(status)='APPROVED'));
   run;

 /*
 / Extract from Oracle the TERM_MAP data
 /*******************************************************************************************/
   data term_map;
      set sdtm_db.vw_mapping_term_map(where=(upcase(status)='APPROVED'));
   run;

 /*
 / Extract from Oracle the CODELIST_DETAILS data
 /*******************************************************************************************/
   data codelist_details;
      set sdtm_db.vw_mapping_codelist_details(where=(upcase(status)='APPROVED'));
   run; 

  
******************************************************************************;
/* create mid_sdtm.study_t empty template dataset to hold all transposed data */
/* BJC005: rename study_t to study_t1 as to improve performance we will use >1 dataset per 
   study. This definition is the template and used for the first one, also set counter num_mid 
   Also rename SUBJID to USUBJID */


%global num_mid;
%let num_mid=1;   

data mid_sdtm.study_t1;
  attrib SI_DSET  length=$12  label='Former Dataset'
         STUDYID  length=$10  label='Study ID'
         USUBJID  length=$20  label='Subject ID'
         VISITNUM length=8    label='Visit sequence number'
         VISIT    length=$40  label='Visit description'
         _NAME_   length=$9   label='Name of Former Variable'  
         _LABEL_  length=$40  label='Label of Former Variable'
         COL1     length=$200 label='Value of Former Variable'
         SEQ      length=8    label='Sequence No';
  stop;         
run;
******************************************************************************;

/* Enabling/importing study specific mapping at the variable level */
%if not %sysfunc(fileexist(&g_rfmtdir/varmap.csv)) %then %do;
   /* Add SS column if not study specific varmap file */
   data varmap_all; 
    set varmap_all ;
    length SS $1;
   run;
%end;

%if %sysfunc(fileexist(&g_rfmtdir/varmap.csv)) %then %do;

  %let _cmd = %str(%str(RTN)OTE: Importing User supplied study specific mappings);
  %tu_sdtmconv_sys_message;

 /*  
 / Remove (Windows OS) carriage return char from CSV file 
 /------------------------------------------------------------------------------------------------*/
   %sysexec tr -d "\015" < &g_rfmtdir/varmap.csv > &work_path.varmap.csv;

 /*  
 / Import CSV file and create the varmap_ss dataset 
 /------------------------------------------------------------------------------------------------*/
   proc import datafile="&work_path.varmap.csv" 
      out=varmap_ss
      dbms=csv replace; 
   run;

 /*VA004 : preserve study review flagging for mappings coming from varmap.csv */
  
  proc sql noprint;
   alter table varmap_ss add study_review char(3);
   update varmap_ss ss set study_review=(select study_review from varmap
  where ss.si_dset eq  si_dset and ss.si_var = si_var);
  quit;
  
  /* Remove any master varmap entries (if present) for study specific items) */
  /* BJC002 - add code to flag overrides as SS='O' - study specific rows will remain flagged in varmap as SS='Y' */
   proc sql noprint;
    create table override as select * from varmap_all where trim(si_dset)||trim(si_var) in 
           (select trim(si_dset)||trim(si_var) from varmap_ss);
    delete from varmap_all where trim(si_dset)||trim(si_var) in (select trim(si_dset)||trim(si_var) from varmap_ss);
   quit;

   data varmap_all; 
    set varmap_all varmap_ss(in=a drop=COMMENTS rename=(ALGORITHMS=INSTRUCTIONS));
    if a then SS='S';
	/* BJC011 : MSA updated to SUPPQUAL=[YES] as default for user clarity - programs just expect YES for SEQ ones 
	   Update here as its read in instead of changing mid_append that has many references to this. */
	if trim(suppqual)='YES[SEQ]' then suppqual='YES';
   run;

  /* BJC008 - flag rows where there is an exact match Draft in MSA as A - i.e. to Approve. 
     X is a Draft with mismatch on details other than si_dset and si_var (the link keys) */
     
   option ibufsize=32767;  
   proc sql noprint;
    update varmap_all set SS='O' where SS='S' and trim(si_dset)||trim(si_var) 
            in (select trim(si_dset)||trim(si_var) from override where status='Approved');
    
    update varmap_all set SS='A' where SS='S' and trim(si_dset)||trim(si_var)||trim(origin)||trim(domain)||
                                       trim(sdtm_var)||trim(suppqual)||trim(INSTRUCTIONS) 
            in (select trim(si_dset)||trim(si_var) ||trim(origin)||trim(domain)||
                trim(sdtm_var)||trim(suppqual)||trim(INSTRUCTIONS) from override where status='Draft');

    update varmap_all set SS='X' where trim(si_dset)||trim(si_var) 
            in (select trim(si_dset)||trim(si_var) from override where status='Draft')
            and trim(si_dset)||trim(si_var)||trim(origin)||trim(domain)||
                                       trim(sdtm_var)||trim(suppqual)||trim(INSTRUCTIONS) 
            not in (select trim(si_dset)||trim(si_var) ||trim(origin)||trim(domain)||
                trim(sdtm_var)||trim(suppqual)||trim(INSTRUCTIONS) from override where status='Draft');;
   quit;
%end;

/* BJC008: Remove Draft MSA rows from varmap and varmap_all - not needed for later processing 
           The system only used draft rows to check the study specific varmap file - previous step */
/* VA003: Use Draft MSA rows from varmap and varmap_all - this is to simplify testing of Draft entry in 
MSA application. this is only when in ARWORK area not in ARPROD , if prod then delete draft entry */

%if %index(%upcase(&g_sdtmdata),ARPROD)gt 0 %then
%do;
	%let _cmd = %str(%str(RTN)OTE: Deleting 'Draft' varmap entries from MSA);
	%tu_sdtmconv_sys_message; 
	proc sql noprint;
 		delete from varmap_all where status='Draft';
	run; 
%end;
%else 
%do;
	%let _cmd = %str(%str(RTN)OTE: Using 'Draft' varmap entries from MSA);
	%tu_sdtmconv_sys_message; 
%end;
   
/* Enabling/importing study specific si_rules at the dataset level */

%if %sysfunc(fileexist(&g_rfmtdir/si_rules.csv)) %then %do;

  %let _cmd = %str(%str(RTN)OTE: Importing User supplied study specific SI rules);
  %tu_sdtmconv_sys_message;

 /*  
 / Remove (Windows OS) carriage return char from CSV file 
 /------------------------------------------------------------------------------------------------*/
   %sysexec tr -d "\015" < &g_rfmtdir/si_rules.csv > &work_path.si_rules.csv;

 /*  
 / Import CSV file and create the si_rules_ss dataset 
 /------------------------------------------------------------------------------------------------*/
   proc import datafile="&work_path.si_rules.csv" 
      out=si_rules_ss 
      dbms=csv replace; 
   run;
   
   data si_rules_ss;
    attrib pre_norm length=$1;
    set si_rules_ss;
   run;  
   
  /*
  / Remove any master si_rules entries (if present) for study specific items) */
  
   proc sql noprint;
    delete from si_rules where si_dset in (select si_dset from si_rules_ss);
   quit;

   data si_rules; 
    set si_rules si_rules_ss;
   run;

%end;

******************************************************************************;
/* Get list of domains with NO --SEQ item e.g. DM as this is used later on */
%global noseq_dom;
%let noseq_dom=;

proc sql noprint;
 select distinct domain into :noseq_dom separated by '","'
   from 
   (select distinct domain
      from reference
   except
   select domain
     from reference
    where substr(reverse(trim(variable_name)),1,3)='QES');
quit;

******************************************************************************;
/* Create a series of SAS formats for each codelist in term_map that has a source 
/  and target code-decode pair */

data to_format;
 set term_map(where=(source_value^=sdtm_value and length(list_name)<=8));
 retain default 200;
run; 

proc sql noprint;
 select count(distinct list_name) 
   into :numfmts from to_format;
quit;
proc sql noprint;
 select distinct list_name
   into :list_name1-:list_name%left(&numfmts)
   from to_format;   
quit;   

%do f= 1 %to &numfmts;

 data to_format_&f;
  set to_format(where=(list_name="&&list_name&f"));   
   FMTNAME=list_name;
   rename source_value=start sdtm_value=label;
   type='C';
 run;

 proc format cntlin=to_format_&f lib=work;
 run;

%end;

/* Define two additions formats for LBSPEC and LBMETHOD */

data to_format_ls;
  set to_format(where=(list_name="LBTESTCD"));   
   FMTNAME='LBSPEC';
   rename source_value=start LBSPEC=label;
   type='C';
run;

proc format cntlin=to_format_ls lib=work;
run;

data to_format_lm;
  set to_format(where=(list_name="LBTESTCD"));   
   FMTNAME='LBMETHOD';
   rename source_value=start LBMETHOD=label;
   type='C';
run;

proc format cntlin=to_format_lm lib=work;
run;

/*VA002 Define formats for LBLOC */

data to_format_ll;
  set to_format(where=(list_name="LBTESTCD"));   
   FMTNAME='LBLOC';
   rename source_value=start LBLOC=label;
   type='C';
run;

proc format cntlin=to_format_ll lib=work;
run;

/* BJC Dont seem able to define the values prefixed with '-' in Excel sheet - to investigate 
       move to oracle should fix this ? */ 
/* BJC014: add 61 -> -P30D format entry */
	   
proc format library=work;
        
   value $evlint
     '1'='-P1W'
     '2'='-P4W'
     '3'='-PT48H'
     '5'='-P2W'
     '8'='-P5D'
     '10'='-PT24H'
     '11'='-P1M'
     '13'='-P7D'
     '15'='-P3D'
     '19'='-P6M'
     '22'='-P12W'
     '24'='-P1W'
     '25'='-P2W'
     '26'='-P2W'
     '31'='-P3M'
     '41'='-P1Y'
     '61'='-P30D'     
     OTHER=' ' ;
     
   value $zevlint
     '1'='-P1W'
     '15'='-P7D'
     '3'='-P4W'
     '4'='-P26W'
     '7'='-PT24H'
     '9'='-P3Y'   
;                        
run;

******************************************************************************************;
/* Get all the instructions from the varmap source (can be multiples on one row) into
/  a format of one row per instruction. Each utility macro can then poll this dataset.
/  Must have entire set for current run of SI dataset and allow each utility macro to select
/  its own algorithms to process */
   
data instructions; 
 set varmap_all(where=(instructions^=''));

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
/*VA006: new version of MSA has VLM tab, so amended macro to use information from VLM tab, and create 
sdtm_pre_hardcode algorithm in instructions dataset
*/
data instructions_vlm(drop= algorithm);
    length instructions $500;
    set vlm(keep = si_dset si_var algorithm ) ;
        instructions ="pre_hardcode("!!trim(left(algorithm))!!");";
run;

data instructions; 
 attrib instructions length=$500;
 set instructions instructions_vlm; 
  num=_n_;
  /* BJC001 - left justify all instructions - some leading spaces may be present */
  instructions=left(instructions);
run;

/* DSS002: The two letter codes in the PC and PP data need to be decoded to the full english. */
/* These formats will be used in the algorithms column in MSA to decode the data */

proc format;
     value $PCREASND
     'IS'='Insufficient sample for primary assay (attributed to a sample which was received but not assayed due to insufficient sample)'
     'NA'='Not analysed (attributed to a sample which was received but not assayed)'
     'NR'='Not reportable (attributed to a sample which was assayed but to which a result cannot be attributed)'
     'NQ'='Not quantifiable (attributed to a sample which was assayed, for which the result fell below the lower limit of quantification (LLQ))'
     'NS'='No sample received'
	 ;
	 
     value $PPREASND   	 
	 'NC'='PK parameter not estimated due to NQs'
     'ND'='PK parameter not determined'
	 ;
run;	 
/* End of DSS002 */

/* finally clean up datasets that are not needed later */
%if &sysenv=BACK %then %do;  

%tu_tidyup(
rmdset = to_format_:,
glbmac = none
);
%end;

/* Check for errors */
%tu_sdtmconv_sys_error_check;


%mend tu_sdtmconv_sys_setup;
