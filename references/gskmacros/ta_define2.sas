/* Used by the HARP application to extract 7 datasets to create the define.xml */
/* Used from version 8 forward */
/* Each dataset (7 for ADaM and 6 for SDTM) is an extraction of a VIEW */ 

%macro ta_gen_ds(
);

/* Call to this macro includes 
/*   REID    THe ID of the reporting effort    */
/*   ENV [DEV|TST|VAL|PRD]                     */
/*   RUNID - Used to get the list of datasets for this run */
/*   ASFLAG    [A|S] for ADaM or SDTM   */


%GLOBAL pArenv pEnv user password path; 

%let pREID = %sysget(REID);
%let pRUNID = %sysget(RUNID);
%let pEnv  = %sysget(ENV);
%let pASflag    = %sysget(ASFLAG);
%put &pEnv;
%put &pASflag;
%put &pRUNID;

%include "/arenv/artools/sas/harp_app/define_sas_sct_cred.sas";


libname oralib oracle user=&user password=&password path="&path";
/* set option to automatically create missing required directories */
options dlcreatedir;

%let root_dir=/&pArenv/define_stage/working/&pREID;
%put &root_dir;
libname rootd "&root_dir";

/* set up other required Directories and Files */
%let src_dir=/&pArenv/define_stage/working/&pREID/srcdata;
%put &src_dir;
libname srcd "&src_dir";
%let source_dir=/&pArenv/define_stage/working/&pREID/sourcexml;
%put &source_dir;
libname rootd "&source_dir";
%let input_dir=/&pArenv/define_stage/working/&pREID/input;
%put &input_dir;
libname inputd "&input_dir";
%let results_dir=/&pArenv/define_stage/working/&pREID/results;
%put &results_dir;
libname resultsd "&results_dir";

/* Determine if the request is for ADaM or SDTM */
%GLOBAL filename_s filename_t filename_c filename_l filename_a filename_d filename_v;

%macro setval(flag);
%put &flag;
%if &flag = A
   %then %do;
     %let filename_s = harp_d2_SOURCE_STUDY;
     %let filename_t = harp_d2_SOURCE_TABLES;
     %let filename_c = harp_d2_SOURCE_COLUMNS;
     %let filename_l = harp_d2_SOURCE_CODELISTS;
     %let filename_a = harp_d2_SOURCE_ANALYSISRESULTS;
     %let filename_d = harp_d2_SOURCE_DOCUMENTS;
     %let filename_v = harp_d2_SOURCE_VALUES;
     %end;
%else %do;
     %let filename_s = harp_d2s_SOURCE_STUDY;
     %let filename_t = harp_d2s_SOURCE_TABLES;
     %let filename_c = harp_d2s_SOURCE_COLUMNS;
     %let filename_l = harp_d2s_SOURCE_CODELISTS;
     %*let filename_a = harp_d2s_SOURCE_ANALYSISRESULTS;
     %let filename_d = harp_d2s_SOURCE_DOCUMENTS;
     %let filename_v = harp_d2s_SOURCE_VALUES;
     %end;
%mend setval;
%setval(&pASflag);

%put &filename_s;

proc sql noprint;
  create table work.harp_source_study as
  select sasref                            as sasref                 format=$8.       length=8       label="SASreferences sourcedata libref",
         studyname                         as studyname              format=$128.     length=128     label="Short external name for the study",
	 studydescription                  as studydescription       format=$2000.    length=2000    label="Description of the study",
         protocolname                      as protocolname           format=$128.     length=128     label="Sponsors internal name for the protocol",
         formalstandardname                as formalstandardname     format=$2000.    length=2000    label="Formal Name of Standard",
         formalstandardversion             as formalstandardversion  format=$2000.    length=2000    label="Formal Version of Standard",
         studyversion                      as studyversion           format=$128.     length=128     label="Unique study version identifier",
         standard                          as standard               format=$20.      length=20      label="Name of Standard",
         standardversion                   as standardversion        format=$20.      length=20      label="Version of Standard"
  from oralib.&filename_s
  where re_id = &pREID;
quit;

data inputd.source_study;
  set work.harp_source_study;
run;

proc sql noprint;
  create table work.harp_source_tables as
  select 
  sasref                               format=$8.    length=8     label="SASreferences sourcedata libref",
  xtable           as table            format=$8.    length=8     label="Table Name",   /* the specific domain instance e.g. SDTM.LBC */
  label                                format=$200.  length=200   label="Table Label", 
  xorder           as order            format=8.     length=8     label="Table order",   /* ADSL must go first, then alphabetical (different order for SDTM) */
  domain                               format=$32.   length=32    label="Domain",      /* this would apply to the parent domain e.g. SDTM.LB */
  domaindescription                    format=$256.  length=256   label="Domain description", 
  xclass           as class            format=$40.   length=40    label="Observation Class within Standard", 
  xmlpath,                              
  xmltitle,                             
  xstructure as structure,                          
  purpose                              format=$10.   length=10    label="Purpose", 
  keys                                 format=$200.  length=200   label="Table Keys", 
  state                                format=$20.   length=20    label="Data Set State (Final, Draft)", 
  xdate         as date                length=20     label="Release Date", 
  xcomment      as comment             format=$1000. length=1000  label="Comment", 
  studyversion                         format=$128.    length=128 label="Unique study version identifier",                       
  standard                             format=$20.      length=20      label="Name of Standard",
  standardversion                      format=$20.      length=20      label="Version of Standard"
  from oralib.&filename_t
  where re_id = &pREID
     AND dataset_id in (SELECT dataset_id from oralib.harp_define_gen_run_ds where run_id = &pRUNID);
quit;

data inputd.source_tables;
  set work.harp_source_tables;
run;


proc sql noprint;
  create table work.harp_source_columns as
  select sasref                            format=$8.    length=8    label="SASreferences sourcedata libref",
         xtable           as table         format=$32.   length=32   label="Table Name",
         xcolumn          as column        format=$32.   length=32   label="Column Name",
         label                             format=$200.  length=200  label="Column Description",
         xorder           as order         format=8.     length=8     label="Column Order",
         xtype            as type          format=$1.    length=1    label="Column Type",
         length                            format=8.     length=8     label="Column Length",
         displayformat                     format=$200.  length=200  label="Display Format",
         significantdigits                 format=8.     length=8     label="Significant Digits",
         xmldatatype                        format=$18.   length=18   label="XML Data Type",
         xmlcodelist                        format=$128.  length=128  label="SAS Format/XML Codelist",
         core                               format=$10.   length=10   label="Column Required or Optional",
         origin                             format=$40.   length=40   label="Column Origin",
         origindescription                  format=$1000. length=1000 label="Column Origin Description",
         role                               format=$200.  length=200  label="Column Role",   /* not used for ADaM, only SDTM */
         algorithm                          format=$1000. length=1000 label="Computational Algorithm or Method",
         algorithmtype                      format=$11.    length=11  label="Type of Algorithm",
         formalexpression                   format=$1000. length=1000 label="Formal Expression of Algorithm",
         formalexpressioncontext            format=$1000. length=1000 label="Context to be used when evaluating the FormalExpression context",
         xcomment          as comment       format=$1000. length=1000 label="Comment",
         studyversion                       format=$128.  length=128  label="Unique study version identifier",
         standard                           format=$20.   length=20   label="Name of Standard",
         standardversion                    format=$20.   length=20   label="Version of Standard"
  from oralib.&filename_c        
  where re_id = &pREID
     AND dataset_id in (SELECT dataset_id from oralib.harp_define_gen_run_ds where run_id = &pRUNID);
quit;

data inputd.source_columns;
  set work.harp_source_columns;
run;


proc sql noprint;
  create table work.harp_source_codelists as
  select sasref                            format=$8.    length=8    label="SASreferences sourcedata libref", 
         codelist                          format=$128.  length=128  label="Unique identifier for this CodeList",
         codelistname                      format=$128.  length=128  label="CodeList Name",
         codelistdescription               format=$2000. length=2000 label="CodeList Description",
         codelistncicode                   format=$10.   length=10   label="Codelist NCI Code",
         codelistdatatype                  format=$7.    length=7    label="CodeList item value data type (integer| float | text | string)",
         sasformatname                     format=$32.   length=32   label="SAS format name",
         codedvaluechar                    format=$512.  length=512  label="Value of the codelist item (character)",
         codedvaluenum                          label="Value of the codelist item (numeric)",
         decodetext                        format=$2000. length=2000 label="Decode value of the codelist item",
         decodelanguage                    format=$17.   length=17   label="Language",
         codedvaluencicode                 format=$10.   length=10   label="Codelist Item NCI Code", /*length??*/
         rank                              format=8.     length=8     label="CodedValue order relative to other item values",
         ordernumber                       format=8.     length=8     label="Display order of the item within the CodeList",
         extendedvalue                     format=$3.    length=3    label="Coded value that has been used to extend external controlled terminology",
         "controlled terminology"          format=$200.  length=200  label="Name of the external codelist",
         version                           format=$200.  length=200  label="Version designator of the external codelist",
         dictionary                        format=$512.  length=512  label="Reference to a local instance of the dictionary",
         ref                               format=$512.  length=512  label="URL of an external instance of the dictionary",
         href ,                             
         studyversion                      format=$128.  length=128  label="Unique study version identifier",
         standard                          format=$20.   length=20   label="Name of Standard",
         standardversion                   format=$20.   length=20   label="Version of Standard"    
  from oralib.&filename_l 
  where re_id = &pREID;
quit;

data inputd.source_codelists;
  set work.harp_source_codelists;
run;

proc sql noprint;
  create table work.harp_source_documents as
  select sasref,
         doctype,
         href,
         title,
         pdfpagereftype,
         pdfpagerefs,
         xtable as table  format=$32.   length=32   label="Table Name",
         xcolumn as column             format=$32.   length=32   label="Column Name",
         whereclause,
         displayidentifier,
         resultidentifier,
         studyversion,
         standard,
         standardversion 
  from oralib.&filename_d 
  where re_id= &pREID;
quit;

data inputd.source_documents;
  set work.harp_source_documents;
run;

proc sql noprint;
  create table work.harp_source_values as
  select sasref                         format=$8.    length=8    label="SASreferences sourcedata libref",
         xtable            as table             format=$32.   length=32   label="Table Name",
         xcolumn           as column             format=$32.   length=32   label="Column Name",
         whereclause                    format=$1000. length=1000 label="Where Clause",
         whereclausecomment             format=$1000. length=1000 label="Where Clause comment",
         label                          format=$200.  length=200  label="Column Description",
         xorder            as order             format=8.     length=8    label="Column Order",
         xtype             as type             format=$1.    length=1    label="Column Type",
         length                         format=8.     length=8    label="Column Length",
         displayformat                  format=$200.  length=200  label="Display Format",
         significantdigits              format=8.     length=8    label="Significant Digits",
         xmldatatype                    format=$18.   length=18   label="XML Data Type",
         xmlcodelist                    format=$128.  length=128  label="SAS Format/XML Codelist",
         core                           format=$10.   length=10   label="Column Required or Optional",
         origin                         format=$40.   length=40   label="Column Origin",
         ORIGINDESCRIPTION              format=$1000. length=1000 label="Column Origin Description",
         xrole             as role             format=$200.  length=200  label="Column Role",
         algorithm                      format=$1000. length=1000 label="Computational Algorithm or Method",
         xcomment         as comment              format=$1000. length=1000 label="Comment",
         studyversion                   format=$128.  length=128  label="Unique study version identifier",
         standard                       format=$20.   length=20   label="Name of Standard",
         standardversion                 format=$20.   length=20   label="Version of Standard" 
   from oralib.&filename_v      
  where re_id = &pREID;
quit;

data inputd.source_values;
  set work.harp_source_values;
run;

%macro arvals(flag);
%put &flag;
%if &flag = A
   %then %do;
	proc sql noprint;
	  create table work.harp_source_analysisresults as
	  select sasref,
	         displayidentifier,
	         displayname,
	         displaydescription,
	         resultidentifier,
	         resultdescription,
	         parametercolumn,
	         analysisreason,
	         analysispurpose,
	         tablejoincomment,
	         resultdocumentation,
	         codecontext,
	         code,
	         xtable as table,
	         analysisvariables,
	         whereclause,
	         studyversion,
	         standard,
	         standardversion
	  from oralib.&filename_a
	  where re_id = &pREID
             AND upper(xtable) in (SELECT UPPER(ds.name) from oralib.harp_define_gen_run_ds dds, oralib.harp_dataset ds 
                      where run_id = &pRUNID and dds.dataset_id = ds.dataset_id);
	quit;
	
	data inputd.source_analysisresults;
	  set work.harp_source_analysisresults;
	run;  
      %end;
%mend arvals;
%arvals(&pASflag);


%mend;
%ta_gen_ds;

 
