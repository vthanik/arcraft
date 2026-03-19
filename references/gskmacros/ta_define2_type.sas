/* Used by the HARP application starting in Version 8     */
/* Convert source_* datasets metadata             */
/* datasets and then create define.xml.              */

%macro ta_define2_type(
);

filename cstmacs "/local1/apps/SAS_CST/cstGlobalLibrary/standards/cdisc-definexml-2.0.0-1.7/macros";
options sasautos=(cstmacs, sasautos);
options mautosource;

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



%let debug=1;
%let _cstStandard=CDISC-DEFINE-XML;
%let _cstStandardVersion=2.0.0;

%cst_setStandardProperties(_cstStandard=CST-FRAMEWORK,_cstSubType=initialize);
%let studyRootPath=/&pArenv/define_stage/working/&pREID;
%let studyOutputPath=/&pArenv/define_stage/working/&pREID;
%let workPath=%sysfunc(pathname(work));
%let _cstSetupSrc=SASREFERENCES;
%cst_createdsfromtemplate( _cstStandard=CST-FRAMEWORK, _cstType=control, _cstSubType=reference, _cstOutputDS=work.sasreferences );


/* Determine if the request is for ADaM or SDTM */

%GLOBAL standname;

%macro setval(flag);
%put &flag;
%if &flag = A
   %then %do;
     %let standname = adam;
     %end;
%else %do;
     %let standname = sdtm;
     %end;
%mend setval;
%setval(&pASflag);

/* Set up the parameters used by define_sourcetodefine */
proc sql;
insert into work.SASReferences
values ("CST-FRAMEWORK" "1.2" "messages" "" "messages" "libref" "input" "dataset" "N" "" "" 1 "" "")
values ("&_cstStandard" "&_cstStandardVersion" "messages" "" "defmsg" "libref" "input" "dataset" "N" "" "" 2 "" "")
values ("&_cstStandard" "&_cstStandardVersion" "autocall" "" "auto1" "fileref" "input" "folder" "N" "" "" 1 "" "")
values ("&_cstStandard" "&_cstStandardVersion" "properties" "initialize" "inprop" "fileref" "input" "file" "N" "" "" 1 "" "")
values ("&_cstStandard" "&_cstStandardVersion" "results" "results" "results" "libref" "output" "dataset" "Y" "" "&studyOutputPath/results" . "definexml_results_&standname" "")
values ("&_cstStandard" "&_cstStandardVersion" "sourcemetadata" "" "sampdata" "libref" "input" "dataset" "N" "" "&studyRootPath/input" . "source_study.sas7bdat" "") 
values ("&_cstStandard" "&_cstStandardVersion" "sourcedata" "" "srcdata" "libref" "input" "folder" "N" "" "&studyRootPath/srcdata" . "" "") 
values ("&_cstStandard" "&_cstStandardVersion" "externalxml" "xml" "extxml" "fileref" "output" "file" "Y" "" "&studyOutputPath/sourcexml" . "define.xml" "") 
values ("&_cstStandard" "&_cstStandardVersion" "report" "outputfile" "html" "fileref" "output" "file" "Y" "" "&studyOutputPath/sourcexml" . " define.html" "")
values ("&_cstStandard" "&_cstStandardVersion" "referencexml" "stylesheet" "xslt" "fileref" "input" "file" "Y" "" "/local1/apps/SAS_CST/cstSampleLibrary/cdisc-definexml-2.0.0-1.7/sourcexml" . "define2-0-0.xsl" "") 
;
quit;

****************************************************;
* Process SASReferences file. *;
****************************************************;
%cstutil_processsetup();

****************************************************;
* Read the source metadata ;
****************************************************;


%macro setval(flag);
%put &flag;
%if &flag = A
   %then %do;
	%define_sourcetodefine(
	_cstOutLib=srcdata,
	_cstSourceStudy=sampdata.source_study,
	_cstSourceTables=sampdata.source_tables,
	_cstSourceColumns=sampdata.source_columns,
	_cstSourceCodeLists=sampdata.source_codelists,
	_cstSourceValues=sampdata.source_values,
	_cstSourceDocuments=sampdata.source_documents,
	_cstSourceAnalysisResults=sampdata.source_analysisresults
	);
     %end;
%else %do;
	%define_sourcetodefine(
	_cstOutLib=srcdata,
	_cstSourceStudy=sampdata.source_study,
	_cstSourceTables=sampdata.source_tables,
	_cstSourceColumns=sampdata.source_columns,
	_cstSourceCodeLists=sampdata.source_codelists,
	_cstSourceValues=sampdata.source_values,
	_cstSourceDocuments=sampdata.source_documents
	);     
   %end;
%mend setval;
%setval(&pASflag);



* Create the Define-XML file;
%define_write(_cstCreateDisplayStyleSheet=1);

* Validate the Define-XML file;
%cstutilxmlvalidate();

*proc export data=sampdata.source_analysisresults
*  outfile="/arenv/";
*run;

*******************************************************************************************;
* Create HTML rendition for browsers that do not allow local rendition of XSLT stylesheet *;
*******************************************************************************************;
proc xsl
in=extxml xsl=xslt out=html;
run;

%mend;
%ta_define2_type;

