/*******************************************************************************
|
| Macro Name:           tu_sdtmconv_sys_monitor
|
| Macro Version/Build:  9/1
|
| SAS Version:          9.1.3
|
| Created By:           Bruce Chambers
|
| Date:                 28-Jul-2009
|
| Macro Purpose:        Update to a central metadata store issues arising during 
|                       the SDTM transformation for each complete study run.
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
|
| Example:
|
| %tu_sdtmconv_sys_monitor
|
|*******************************************************************************
| Change Log :
|
| Modified By:                 Bruce Chambers
| Date of Modification:        10May2010
| New Version/Build Number:    2/1      
| Reference:                   BJC001
| Description for Modification:Add ORIG_SI_VAR and SRC_DATA_TYPE to variables to 
|                              populate to monitor_varmap
| Reason for Modification:     For define.xml traceability purposes
|
| Modified By: 		           Deepak Sriramulu
| Date of Modification: 	   14Feb2011
| New Version/Build Number:	   3 Build 1
| Reference:                   dss001
| Description for Modification:Create a CSV report and SAS dataset that shows the overall study mappings
| Reason for Modification: 	   To Aid Study Team's QC
|
| Modified By: 		           Deepak Sriramulu
| Date of Modification: 	   06May2011
| New Version/Build Number:	   4 Build 1
| Reference:                   dss002
| Description for Modification:Suppress VARMAP_MRG use when the conversion is run for CHECK mode
| Reason for Modification: 	   Writing out of the /refdata files needs to only run if system is not in CHECK mode. 
|
| Modified By: 		           Deepak Sriramulu
| Date of Modification: 	   22Aug2011
| New Version/Build Number:	   5 Build 1
| Reference:                   dss003
| Description for Modification:Add Variable status (Approved/Draft) information to study mappings dataset and Excel file
| Reason for Modification: 	   To make sure all the varmap rows get approved in MSA otherwise the conversion won�t work when |                              it gets imported to arprod
|
| Modified By: 		           Bruce Chambers
| Date of Modification: 	   01Aug2012
| New Version/Build Number:	   6 Build 1
| Reference:                   BJC002
| Description for Modification:Remove check for g_stype to make dmenv runs place out mapping history files
| Reason for Modification: 	   Enable user review of mappings applied
|
| Modified By: 		           Bruce Chambers
| Date of Modification: 	   01Oct2012
| New Version/Build Number:	   6 Build 1
| Reference:                   BJC003
| Description for Modification:Upcase studyid values before insert into monitor tables
| Reason for Modification: 	   So we dont get duplicate rows with upper and lower case versions of same study.
|
| Modified By: 		           Bruce Chambers
| Date of Modification: 	   01Oct2012
| New Version/Build Number:	   6 Build 1
| Reference:                   BJC004
| Description for Modification:Allow monitor tables to be populated for runs on HBU079 or PHU059 even if metadata/specs
|                              are coming from PRD (using PRD_QUERY=Y)
| Reason for Modification: 	   To enable testing of all functionality in DEV/TST e.g. define.xml aeCRF generation
|
| Modified By: 		           Bruce Chambers
| Date of Modification: 	   16Oct2012
| New Version/Build Number:	   6 Build 1
| Reference:                   BJC005
| Description for Modification:Add TERMAP and ORIG_SI_DSET to monitor_varmap
| Reason for Modification: 	   To give full data traceability details
|
|
| Modified By: 		           Ashwin Venkat(va755193)
| Date of Modification: 	   16Oct2012
| New Version/Build Number:	   6 Build 1
| Reference:                   VA001
| Description for Modification:Increased  SUPPQUAL variable length, to remove truncation.
| Reason for Modification: 	   Increased  SUPPQUAL variable length, to show full details of SUPPQUAL link 
|
| Modified By: 		           Bruce Chambers
| Date of Modification: 	   26Jan2013
| New Version/Build Number:	   7 Build 1
| Reference:                   BJC006
| Description for Modification:Add ORIG_SI_DSET and TERMAP to study_mappings user reference.
|                              Disable PDF version as now too wide for landscape: user still has SAS or xls to choose from 
|                              (Change BJC005 above only added columns to oracle store but this is not seen by users)
| Reason for Modification: 	   To give full data traceability details for users and other systems
|
| Modified By: 		           Bruce Chambers
| Date of Modification: 	   17May013
| New Version/Build Number:	   8 Build 1
| Reference:                   BJC007
| Description for Modification:Translate any " in instructions/algorithms to '
| Reason for Modification: 	   double quotes mess up the define.xml import in HARP
|
| Modified By: 		           Bruce Chambers
| Date of Modification: 	   03Jun2013
| New Version/Build Number:	   9 Build 1
| Reference:                   BJC008 
| Description for Modification:Redo BJC007: Translate any " in instructions/algorithms to '
| Reason for Modification: 	   double quotes mess up the define.xml import in HARP
|                              For BJC007 the line was in the wrong place in the datastep - missed in testing
|                              Move line from before to after set statment
*******************************************************************************/
%macro tu_sdtmconv_sys_monitor(
);

/* BJC004 - enable monitor data to be written to DEV/TST DB even if spec etc coming from PRD 
   NB: Definition of PRD_QUERY in driver must be preceded by global definition */
   
%if %symexist(prd_query) %then %do;
  %symdel prd_query;
    /* Re-run SDTM_PW macro to point to DEV/TST DB for monitor table data updates when running on hbu079/phu059 
      (i.e. system never writes to PRD monitor tables from DEV/TST hbu079/phu059) */   
	libname sdtm_db clear;  	
    %sdtm_pw;
	libname sdtm_db oracle username=&sdtm_ac password=&sdtm_pw path=&sdtm_db;
%end;

   %if %sysfunc(exist(varmap_mrg)) %then %do;
      proc sql noprint;
         delete from sdtm_db.vw_monitor_varmap
            where upcase(studyid) = "%upcase(&g_study_id)";
      quit;
	  
	  /* BJC003: upper case studyid before insert */ 
      data varmap_mrg;
         attrib studyid               format=$10.;
         attrib si_var                format=$20.;
         attrib si_dset               format=$32.;
         attrib origin                format=$9.;
         attrib domain                format=$4.;
         attrib sdtm_var              format=$12.;
         attrib suppqual              format=$32.;
         attrib instructions          format=$500.;
         attrib specification_details format=$200.;
         attrib comments              format=$200.;
         attrib ss                    format=$1.;
         attrib added                 format=$1.;
         attrib mapping_type          format=$30.;
         attrib status                format=$30.;
         attrib sdtm_ig_version       format=$20.;
         attrib source_standard       format=$50.;
         attrib modified_user         format=$20.;
         format modified_date         datetime20.;
         /* BJC001 - add orig_si_var */
         attrib orig_si_var           length=$20;
         attrib src_data_type         length=$54;
         /* BJC005 - check for ORIG_SI_DSET and TERMAP - add null columns if missing */
         attrib orig_si_dset          length=$32;
		 attrib termap                length=$288; 
		 
         set varmap_mrg;
		 /* BJC008: move BJC007 to below the set statment
		    Translate any " in instructions/algorithms to ' as double quotes mess up the define.xml import in HARP */
		 instructions=translate(instructions,"'",'"');	
         studyid = upcase("&g_study_id");
         modified_date = datetime();
         modified_user = "&sysuserid";
      run;

      proc append base=sdtm_db.vw_monitor_varmap data=varmap_mrg FORCE;
      run;
	  
    %end;

   %if %sysfunc(exist(view_tab_list)) %then %do;
      proc sql noprint;
         delete from sdtm_db.vw_monitor_view_tab_list
            where upcase(studyid) = "%upcase(&g_study_id)";
      quit;

	  /* BJC003: upper case studyid before insert */
      data view_tab_list;
         attrib studyid       format=$10.;
         attrib basetabname   format=$32.;
         attrib libname       format=$8. ;
         attrib domain        format=$4.;
         format modified_user $20.;
         format modified_date datetime20.;
         set view_tab_list;
         studyid = upcase("&g_study_id");
         modified_date = datetime();
         modified_user = "&sysuserid";
      run;

      proc append base=sdtm_db.vw_monitor_view_tab_list data=view_tab_list FORCE;
      run;
    %end;

   %if %sysfunc(exist(non_mapped_si_datasets)) %then %do;

      proc sql noprint;
         delete from sdtm_db.vw_monitor_non_mapped_si_ds
            where upcase(studyid) = "%upcase(&g_study_id)";
      quit;

	  /* BJC003: upper case studyid before insert */
      data non_mapped_si_datasets;
         attrib studyid                format=$10.;
         attrib si_dset                format=$32.;
         attrib dataset_type_desc      format=$32.;
         attrib thrpy_nm               format=$32.;
         attrib sub_thrpy_nm           format=$32.;
         attrib dataset_notes          format=$300.;
         attrib dataset_structure_desc format=$100.;
         attrib version_status_desc    format=$32.;
         attrib archive_flag           format=$1.;
         attrib chg_desc               format=$300.;
         format modified_user          $20.;
         format modified_date          datetime20.;
         set non_mapped_si_datasets(drop=level);
         studyid = upcase("&g_study_id");
         modified_date = datetime();
         modified_user = "&sysuserid";
      run;

      proc append base=sdtm_db.vw_monitor_non_mapped_si_ds data=non_mapped_si_datasets FORCE;
      run;
    %end;

   %if %sysfunc(exist(sdtm_issues)) %then %do;
      proc sql noprint;
         delete from sdtm_db.vw_monitor_sdtm_issues
            where upcase(studyid) = "%upcase(&g_study_id)";
      quit;

	  /* BJC003: upper case studyid before insert */
      data sdtm_issues;
         attrib studyid           format=$10.;
         attrib name              format=$8.;
         attrib memname           format=$30.;
         attrib problem_desc_full format=$200. ;
         attrib code              format=$8.;
         format modified_user     $20.;
         format modified_date     datetime20.;
         set sdtm_issues(keep= memname si_dset name code problem_desc_full);
         studyid = upcase("&g_study_id");
         modified_date = datetime();
         modified_user = "&sysuserid";
      run;

      proc append base=sdtm_db.vw_monitor_sdtm_issues data=sdtm_issues FORCE;
      run;
    %end;

   %if %sysfunc(exist(si_rules_ss)) %then %do;
      %if %eval(%tu_nobs(si_rules_ss))>=1 %then %do;
 
         proc sql noprint;
            delete from sdtm_db.vw_monitor_si_rules_ss
               where upcase(studyid) = "%upcase(&g_study_id)";
         quit;

		 /* BJC003: upper case studyid before insert */
         data si_rules_ss;
            attrib studyid       format=$10.;
            attrib si_dset       format=$32.;
            attrib pre_norm      format=$1.;
            attrib comments      format=$200.;
            format modified_user $20.;
            format modified_date datetime20.;
            set si_rules_ss;
            studyid = upcase("&g_study_id");
            modified_date = datetime();
            modified_user = "&sysuserid";
         run;

         proc append base=sdtm_db.vw_monitor_si_rules_ss data=si_rules_ss FORCE;
         run;

      %end; 
   %end;

   /* Save datasets into Oracle that passed all quality checks */
   %if %sysfunc(exist(report_summ_domains)) %then %do;
      /* BJC003: upper case studyid before insert */
      proc sql noprint;
         create table _oracle_report_summ_domains as
            select domain format=$8. length=8, 
                   si_dset                       format=$32.         length=32, 
                   "%upcase(&g_study_id)" as studyid      format=$10.         length=10,
                   descr                                             length=20, 
                   count as count_iss,
                   datetime() as modified_date   format=datetime20.,
                   "&sysuserid" as modified_user format=$20.         length=20
               from report_summ_domains;
       delete from sdtm_db.vw_monitor_qc_summ where upcase(studyid) = "%upcase(&g_study_id)";
    quit;

    proc append base=sdtm_db.vw_monitor_qc_summ data=_oracle_report_summ_domains FORCE;
    run;
   %end;

/* BJC002: remove restriction to run in arenv only - now runs for dmenv too */

/* DSS001 Create a Excel, PDF report and SAS dataset that shows the overall study mappings and CT maps */
/* Writing out of the /refdata files needs to only run if system is not in CHECK mode */
%if &tab_list eq and &tab_exclude eq and %length(&subset_clause)=0 and &check_only ^=Y %then %do;
 proc sql noprint;
    select '$'||left(compress(put(max(length(strip(instructions))),8.))) into :max_len
           from varmap_mrg;
    select '$'||compress(put(max(length(strip(instructions))),8.))||"." into :fmt
           from varmap_mrg;
 quit;
 
/*VA001: Increased  SUPPQUAL variable length, to show full details of SUPPQUAL link */
/* Apply descriptive labels and intuitive order for the variables to assist review */
/* DSS003: Add  status (Approved/Draft) information to study mappings dataset and Excel file */
 data rfmtdir.study_mappings;
   /* BJC006 add orig_si_dset and termap labels*/
   attrib ORIG_SI_DSET	 label	= 'Original Source dataset name' length = $8 format=$8. informat=$8. 
          SI_DSET	     label	= 'Source dataset name' length = $8 format=$8. informat=$8.
           SI_VAR	     label	= 'Source dataset variable' length = $8 format=$8. informat=$8.
	   ORIG_SI_VAR       label	= 'Original source variable name'  length = $8 format=$8. informat=$8.
           DOMAIN	     label	= 'Destination domain' length = $4 format=$4. informat=$4.
           SDTM_VAR	     label	= 'Destination variable' length=$8 format=$8.informat=$8.
	    SUPPQUAL	     label	= 'SUPPQUAL link/join details' length=$15 format=$15. informat=$15.
	      ORIGIN	     label	= 'Data ORIGIN ' length=$8 format=$8. informat=$8.
	   STUDY_REVIEW      label	= 'Mapping flagged for study review' length=$1 format=$1. informat=$1.
	   INSTRUCTIONS      label	= 'Algorithms applied' length = &max_len format=&fmt informat=&fmt
           ADDED	     label	= 'Variable/Mapping added during conversion' length=$1 format=$1. informat=$1.
	       SS 	         label	= 'Study specific mapping' length=$1 format=$1. informat=$1.
		   STATUS        label  = 'Status (Approved/Draft)'
		   TERMAP        label  = 'Terminology mapping list name (for SUPP vars only)';
     set varmap_mrg;        
     keep si_dset si_var orig_si_var domain sdtm_var suppqual origin study_review instructions added ss status
	 /* BJC006 add orig_si_dset and termap to keep */
	      orig_si_dset termap;
 run;

 proc sort data = rfmtdir.study_mappings;
    by orig_si_dset si_dset si_var;
 run;  

 ods listing close;
 
/* Create PDF & Excel Reports for review */
/* BJC006 add orig_si_dset and termap to xls and disable/remove PDF listing as now too wide (too many columns) */

    ods html file  = "&g_rfmtdir/study_mappings.xls";
    options orientation=landscape;
    PROC REPORT DATA = rfmtdir.study_mappings HEADLINE HEADSKIP NOWD
         PS=40 LS=160 WRAP SPLIT = '*'  STYLE(column)={font_size=9 pt}                                                              
         STYLE(header)={FONT=(arial) FONT_size=9 pt font_weight=bold};

    TITLE1 "Variable Mapping for the %upcase(&g_study_id) Study";
	Columns orig_si_dset si_dset si_var orig_si_var domain sdtm_var suppqual origin study_review instructions added 
	        ss status termap;  		
	   DEFINE orig_si_dset 	/ DISPLAY width=8 FLOW;	
       DEFINE si_dset   	/ DISPLAY width=8 FLOW;
       DEFINE si_var  	    / DISPLAY WIDTH=8 FLOW;  
	   DEFINE orig_si_var   / DISPLAY WIDTH=8 FLOW;  
	   DEFINE domain   	    / DISPLAY WIDTH=8 FLOW;   	 
	   DEFINE sdtm_var 	    / DISPLAY WIDTH=8 FLOW;
	   DEFINE suppqual 	    / DISPLAY WIDTH=13 FLOW;
 	   DEFINE origin 	    / DISPLAY width=8 FLOW; 	
	   DEFINE study_review  / DISPLAY WIDTH=7 FLOW; 
	   DEFINE instructions  / DISPLAY WIDTH=20 FLOW;
	   DEFINE added  	    / DISPLAY WIDTH=5 FLOW;  		                
	   DEFINE ss     	    / DISPLAY WIDTH=5 FLOW;
	   DEFINE status     	/ DISPLAY WIDTH=10 FLOW;
	   DEFINE termap     	/ DISPLAY WIDTH=10 FLOW;
    RUN;

    ods html close;
     
    proc format library=work
                out=rfmtdir.ct_mappings(keep=fmtname start end); 
    run;
    
    ods listing;
	
%end; /* End of %if &tab_list eq and &tab_exclude eq and %length(&subset_clause)=0 %then %do; */	

/* End of DSS001 update */

%mend tu_sdtmconv_sys_monitor;
