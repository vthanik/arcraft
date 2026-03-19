/*----------------------------------------------------------------------------+
| Macro Name    : tc_trtextract.sas
|
| Macro Version : 1 Build 2
|
| SAS version   : SAS v9.4
|
| Created By    : Daniel McDonald
|
| Date          : September 2016
|
| Macro Purpose : Macro to extract treatment and container randomization data from RandAll NG
|
| Macro Design  : PROCEDURE STYLE
|
| Input Parameters :
|
| NAME			DESCRIPTION                             	DEFAULT
|
| BLINDTYPE		DRAFT or FINAL.  Indicates whether DRAFT	DRAFT
|			(blind) data or FINAL (un-blind) data
|			should be extracted.
|
| NETWORKTIMEOUT	Specifies the maximum number of seconds to	600
|			wait for extraction from RandAll NG to
|			complete.
|
|---------------------------------------------------------------------------------------------------
|
| Output:   1. A raw CSV file containing treatment randomization reference data for the study
|           2. A raw CSV file containing container randomization reference data for the study
|	    3. A CSV file containing unique treatment group codes and descriptions (template for TRTGRPMAP)
|	    4. A CSV file containing unique treatment codes and descriptions (template for EXPCTMAP)
|	    5. A CSV file containing unique container type codes and descriptions (template for CTTYPMAP)
|
| Global macro variables created: None
|
|
| Macros called :
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_abort
| (@) tu_tidyup
|
| Example:
|	%tc_trtextract(
|	    blindtype=FINAL,
|	    networktimeout=600
|	    );
|
| **************************************************************************
| Change Log :
|
| Modified By : Daniel McDonald
| Date of Modification : 20-Sep-2016
| New Version Number : 01-002
| Modification ID : DM2
| Reason For Modification :
|	RD_IT/AR_HARP_195808 Defect 542 - TRTGRPMAP contains truncated TRTGRPC and TRTGRPD variables
|	RD_IT/AR_HARP_195808 Defect 596 - On executing TRTEXTRACT macro with Debug Level as '0' for studies which generate
|					  ERROR files, temporary files are not deleted
|	BDS/HARP_RT Defect 580 - Macro is creating .error files when program aborts due to No Final treatment data available
|
| Modified By :
| Date of Modification :
| New Version Number :
| Modification ID :
| Reason For Modification :
|
+----------------------------------------------------------------------------*/

%macro tc_trtextract(
    blindtype=DRAFT,		/* DRAFT or FINAL.  Indicates whether DRAFT (blind) data or FINAL (un-blind) data should be extracted. */
    networktimeout=600		/* Specifies the maximum number of seconds to wait for extraction from RandAll NG to complete. */
);
    %local macroname;
    %let macroname=&sysmacroname;

    /*
    / Echo parameter values and global macro variables to the log.
    /------------------------------------------------------------------------*/
    %local MacroVersion;
    %let MacroVersion = 1 Build 2;
    %include "&g_refdata/tr_putlocals.sas";
    %tu_putglobals(varsin=g_study_id g_rfmtdir g_debug g_abort);

    /*
    / Declare operating system specific details
    /------------------------------------------------------------------------*/
    filename soapreq "&g_rfmtdir./&macroname._soapreq.xml";
    filename soapresp "&g_rfmtdir./&macroname._soapresp.xml";
    filename respmap "&g_rfmtdir./&macroname._soapresp.map"; *-- SAS XMLMap file for parsing the response XML;
    filename soapcred "/local1/apps/HARPRT/harp_bridge_creds.sas";

    /*
    / PARAMETER VALIDATION
    /------------------------------------------------------------------------*/
    %let blindtype	= %sysfunc(propcase(%nrbquote(&blindtype)));
    %let networktimeout	= %nrbquote(&networktimeout);

    /*
    / Check for required parameters.
    /------------------------------------------------------------------------*/

    %if &blindtype eq %then %do;
	%put %str(RTE)RROR: &macroname: The parameter BLINDTYPE is required.;
	%let g_abort=1;
    %end;

    %if &networktimeout eq %then %do;
	%put %str(RTE)RROR: &macroname: The parameter NETWORKTIMEOUT is required.;
	%let g_abort=1;
    %end;

    *-- verify BLINDTYPE parameter;
    %if &blindtype ne Draft and &blindtype ne Final %then %do;
    	%put %str(RTE)RROR: &macroname: parameter BLINDTYPE must be DRAFT or FINAL;
	%let g_abort=1;
    %end;

    *-- verify NETWORKTIMEOUT parameter;
    %local regex;
    %let regex = '^ *\d+ *$'; * one or more digits optionally surrounded by spaces;
    %if %sysfunc(prxmatch(&regex, &networktimeout)) eq 0 %then %do;
	%put %str(RTE)RROR: &macroname: parameter NETWORKTIMEOUT must be a positive integer;
	%let g_abort=1;
    %end;

    %if &networktimeout lt 10 %then %do;
	%put %str(RTE)RROR: &macroname: parameter NETWORKTIMEOUT must be greater than or equal to 10;
	%let g_abort=1;
    %end;

    *-- abort if parameter validation failed;
    %if &g_abort eq 1 %then %do;
	%tu_abort;
    %end;

    /*
    / Macro parameters have valid values if the program has
    / not terminated by this point.
    /------------------------------------------------------------------------*/

    *-- Truncate the study ID to just the six digits of the clinical master study id;
    %local study_id;
    %if %length(&g_study_id) gt 6 %then %do;
	%let study_id=%substr(&g_study_id, 4, 6);
    %end;
    %else %do;
	%let study_id=%str(&g_study_id);
    %end;

    /*
    / Create temporary XML file containing SOAP request
    / pass study id, blind type, and output location (refdata folder)
    /------------------------------------------------------------------------*/
    *-- Set up integration transaction details;
    %local business_trans_id source_app_id source_ean;
    %let business_trans_id=%sysfunc(uuidgen()); *-- new GUID for each transaction;
    %let source_app_id=%str(P000266353); *-- harp analysis and reporting app prd;
    %let source_ean=%str(5051150022577); *-- EAN from service catalog request #10662005;

    *-- determine the DNS domain name of the host computer;
    %local domainname;
    filename domain pipe "dnsdomainname";
    data _null_;
	infile domain truncover;
	length domainname $ 256;
	input domainname $ char256.;
    	call symputx('domainname', domainname);
	stop;
    run;

    *-- write out SOAP request to a file;
    data _null_;
        file soapreq;
	put '<soap:Envelope';
	put '	xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"';
	put '	xmlns:v1="http://gsk.com/Contract/RD/HARPBridge/Facade/HARPBridgeInterface_SF/v1"';
	put '	xmlns:v11="http://gsk.com/Entities/RD/Facade/Common/TransactionHeaderType/v1"';
	put '	xmlns:v12="http://gsk.com/Entities/RD/HARPBridge/Facade/HARPBridgeInterface_SF/GetStudyRandomisationData/GetStudyRandomisationDataRequestType/v1">';
	put '   <soap:Header>';
	put '      <v1:TransactionHeader>';
	put "         <v11:BusinessTransactionID>&business_trans_id</v11:BusinessTransactionID>";
	put "         <v11:SourceApplicationID>&source_app_id</v11:SourceApplicationID>";
	put "         <v11:SourceEAN>&source_ean</v11:SourceEAN>";
	put '      </v1:TransactionHeader>';
	put '   </soap:Header>';
	put '   <soap:Body>';
	put '      <v1:GetStudyRandomisationData>';
	put '         <Request>';
	put "            <v12:ClinicalStudyID>&study_id</v12:ClinicalStudyID>";
	put "            <v12:StudyRandomisationType>&blindtype</v12:StudyRandomisationType>";
	put "            <v12:OutputFileServer>&syshostname..&domainname</v12:OutputFileServer>";
	put "            <v12:OutputFileFolder>&g_rfmtdir</v12:OutputFileFolder>";
	put '         </Request>';
	put '      </v1:GetStudyRandomisationData>';
	put '   </soap:Body>';
	put '</soap:Envelope>';
    run;

    *-- Write out XMLmap file to use in parsing the SOAP response;
    *-- See http://support.sas.com/documentation/cdl/en/engxml/65362/HTML/default/viewer.htm#p1l4r1tyrnsapdn1gcdrf9t00c8m.htm;
    data _null_;
        file respmap;
	put '<?xml version="1.0" ?>';
	put '<SXLEMAP version="2.1">';
	put '    <NAMESPACES count="6">';
	put '        <NS id="1" prefix="soap">http://schemas.xmlsoap.org/soap/envelope/</NS>';
	put '        <NS id="2" prefix="v1">http://gsk.com/Contract/RD/HARPBridge/Facade/HARPBridgeInterface_SF/v1</NS>';
	put '        <NS id="3" prefix="v11">http://gsk.com/Entities/RD/HARPBridge/Facade/HARPBridgeInterface_SF/GetStudyRandomisationData/GetStudyRandomisationDataResponseType/v1</NS>';
	put '        <NS id="4" prefix="soapenv">http://schemas.xmlsoap.org/soap/envelope/</NS>';
	put '        <NS id="5" prefix="v1">http://gsk.com/Contract/RD/HARPBridge/Facade/HARPBridgeInterface_SF/v1</NS>';
	put '        <NS id="6" prefix="v11">http://gsk.com/Entities/RD/Facade/Common/FaultType/v1</NS>';
	put '    </NAMESPACES>';
	put "    <TABLE name='&macroname._RESPONSE'>";
	put '        <TABLE-PATH syntax="XPathENR">/{2}GetStudyRandomisationDataResponse/Response</TABLE-PATH>';
	put '        <COLUMN name="Success">';
	put '            <PATH syntax="XPathENR">/{2}GetStudyRandomisationDataResponse/Response/{3}Success</PATH>';
	put '            <TYPE>character</TYPE>';
	put '            <DATATYPE>STRING</DATATYPE>';
	put '            <LENGTH>30</LENGTH>';
	put '        </COLUMN>';
	put '        <COLUMN name="ReceivedDateTime">';
	put '            <PATH syntax="XPathENR">/{2}GetStudyRandomisationDataResponse/Response/{3}ReceivedDateTime</PATH>';
	put '            <TYPE>character</TYPE>';
	put '            <DATATYPE>STRING</DATATYPE>';
	put '            <LENGTH>30</LENGTH>';
	put '        </COLUMN>';
	put '    </TABLE>';
	put "    <TABLE name='&macroname._FAULT'>";
	put '        <TABLE-PATH syntax="XPathENR">/{4}Fault</TABLE-PATH>';
	put '        <COLUMN name="CODE">';
	put '            <PATH syntax="XPathENR">/{4}Fault/faultcode</PATH>';
	put '            <TYPE>character</TYPE>';
	put '            <DATATYPE>STRING</DATATYPE>';
	put '            <LENGTH>200</LENGTH>';
	put '        </COLUMN>';
	put '        <COLUMN name="SUBCODE">';
	put '            <PATH syntax="XPathENR">/{4}Fault/detail/{5}Fault/{6}ErrorType</PATH>';
	put '            <TYPE>character</TYPE>';
	put '            <DATATYPE>STRING</DATATYPE>';
	put '            <LENGTH>200</LENGTH>';
	put '        </COLUMN>';
	put '        <COLUMN name="REASON">';
	put '            <PATH syntax="XPathENR">/{4}Fault/faultstring</PATH>';
	put '            <TYPE>character</TYPE>';
	put '            <DATATYPE>STRING</DATATYPE>';
	put '            <LENGTH>200</LENGTH>';
	put '        </COLUMN>';
	put '        <COLUMN name="ERRORCODE">';
	put '            <PATH syntax="XPathENR">/{4}Fault/detail/{5}Fault/{6}ErrorCode</PATH>';
	put '            <TYPE>character</TYPE>';
	put '            <DATATYPE>STRING</DATATYPE>';
	put '            <LENGTH>10</LENGTH>';
	put '        </COLUMN>';
	put '        <COLUMN name="ADDITIONALDETAIL">';
	put '            <PATH syntax="XPathENR">/{4}Fault/detail/{5}Fault/{6}AdditionalDetail</PATH>';
	put '            <TYPE>character</TYPE>';
	put '            <DATATYPE>STRING</DATATYPE>';
	put '            <LENGTH>200</LENGTH>';
	put '        </COLUMN>';
	put '    </TABLE>';
	put '</SXLEMAP>';
    run;

    /*
    / Retrieve the HARP Bridge access credentials from a secure file location.
    / This should define macro variables harp_bridge_ep, harp_bridge_ac, harp_bridge_pw.
    / Ref: http://www.lexjansen.com/pnwsug/2007/Dave%20Steven%20-%20Keep%20your%20database%20passwords%20out%20of%20the%20clear.pdf
    /------------------------------------------------------------------------*/
    %include soapcred;

    /*
    / Invoke the HARP Bridge SOAP web service to initiate treatment data extraction.
    / The response from the server is written to the temporary response file.
    /------------------------------------------------------------------------*/
    proc soap in=soapreq
	out=soapresp
	url="&harp_bridge_ep"
	wssusername="&harp_bridge_ac"
	wsspassword="&harp_bridge_pw";
    run;
    
    /*
    / Parse the response file to determine if request was successfully submitted.
    / See http://support.sas.com/documentation/cdl/en/engxml/62845/HTML/default/viewer.htm#a002484895.htm
    /------------------------------------------------------------------------*/

    *-- import the SOAP response using the XMLMap defined above;
    libname soapresp xmlv2 xmlmap=respmap access=readonly;

    *-- the SOAP response file produces two datasets:  response and fault;
    *-- only one dataset should have a row, depending on which type of response it is;
    proc datasets library=soapresp;
    run;
    quit;

    *-- NOTE: tu_nobs does not work with soapresp xml datasets;
    %local found_success timestamp;

    data _null_;
    	call symputx('found_success', 0); *-- set to 0 for No;
	set soapresp.&macroname._response;
	call symputx('found_success', 1); *-- if got here there are obs so set to 1 for Yes;
	stop;
    run;

    %if &found_success gt 0 %then %do;
	%put %str(RTN)OTE: &macroname: Received successful response from HARP Bridge integration web service.;
	%put %str(RTN)OTE: &macroname: Dump of successful response from web service, if any:;

	*-- record the success response from the web service into the log file;
	data _null_;
	    set soapresp.&macroname._response;
	    put "RTN" "OTE: &macroname: " success=;
	    put "RTN" "OTE: &macroname: " receiveddatetime=;
	    call symputx('timestamp', receiveddatetime);
	run;
    %end; *-- if found_success gt 0;

    *-- NOTE: tu_nobs does not work with soapresp xml datasets;
    %local found_fault;

    data _null_;
    	call symputx('found_fault', 0); *-- set to 0 for No;
	set soapresp.&macroname._fault;
	call symputx('found_fault', 1); *-- if got here there are obs so set to 1 for Yes;
	stop;
    run;

    %if &found_fault gt 0 %then %do;
	%put %str(RTE)RROR: &macroname: Failure returned from HARP Bridge integration web service.;
	%put %str(RTN)OTE: &macroname: Dump of failure response from web service:;

	*-- record the failure response from the web service into the log file;
	data _null_;
	    set soapresp.&macroname._fault;
	    put "RTE" "RROR: &macroname: " code=;
	    put "RTE" "RROR: &macroname: " subcode=;
	    put "RTE" "RROR: &macroname: " reason=;
	    put "RTE" "RROR: &macroname: " errorcode=;
	    put "RTE" "RROR: &macroname: " additionaldetail=;
	run;

	%let g_abort=1;
	%tu_abort;
    %end;

    %if &found_success eq 0 and &found_fault eq 0 %then %do;
	%put %str(RTE)RROR: &macroname: Call to HARP Bridge integration web service appears to have failed.;
	%put %str(RTE)RROR: &macroname: Could not determine success or failure from the response file.;
	%put %str(RTE)RROR: &macroname: Check log file for errors invoking the web service and contact the support team.;

	%let g_abort=1;
	%tu_abort;
    %end;

    /* 
    / Monitor output location for files and completion indicator
    /------------------------------------------------------------------------*/
    %put %str(RTN)OTE: &macroname: Waiting for completion files to indicate that extraction background processing is complete.;

    %local treatment_file_success treatment_file_failure treatment_file_data treatment_file_error;
    %local container_file_success container_file_failure container_file_data container_file_error;
    %let treatment_file_success=&g_rfmtdir./&study_id._TreatmentData_Flag_&timestamp..success;
    %let treatment_file_failure=&g_rfmtdir./&study_id._TreatmentData_Flag_&timestamp..%str(er)ror;
    %let treatment_file_data=   &g_rfmtdir./&study_id._TreatmentData_&blindtype._&timestamp..csv;
    %let treatment_file_error=  &g_rfmtdir./&study_id._TreatmentData_Error_&timestamp..csv;
    %let container_file_success=&g_rfmtdir./&study_id._ContainerCodes_Flag_&timestamp..success;
    %let container_file_failure=&g_rfmtdir./&study_id._ContainerCodes_Flag_&timestamp..%str(er)ror;
    %let container_file_data=   &g_rfmtdir./&study_id._ContainerCodes_&blindtype._&timestamp..csv;
    %let container_file_error=  &g_rfmtdir./&study_id._ContainerCodes_Error_&timestamp..csv;
    %if &g_debug gt 0 %then %do;
	%put %str(RTN)OTE: &macroname: treatment_file_success=&treatment_file_success;
	%put %str(RTN)OTE: &macroname: treatment_file_failure=&treatment_file_failure;
	%put %str(RTN)OTE: &macroname: treatment_file_data=&treatment_file_data;
	%put %str(RTN)OTE: &macroname: treatment_file_error=&treatment_file_error;
	%put %str(RTN)OTE: &macroname: container_file_success=&container_file_success;
	%put %str(RTN)OTE: &macroname: container_file_failure=&container_file_failure;
	%put %str(RTN)OTE: &macroname: container_file_data=&container_file_data;
	%put %str(RTN)OTE: &macroname: container_file_error=&container_file_error;
    %end;

    *-- set the file permissions to owner read-write and group read;
    %local perms;
    %let perms=640;

    *-- change permissions on the treatment data file;
    %sysexec %bquote(touch &treatment_file_data.);
    %sysexec %bquote(chmod &perms &treatment_file_data.);
    *-- change permissions on the container codes file;
    %sysexec %bquote(touch &container_file_data.);
    %sysexec %bquote(chmod &perms &container_file_data.);

    %local wait_time_sec trt_success trt_data trt_err cont_success cont_data cont_err no_containers;

    %let trt_data=0; *-- initialize to 0/false;
    %let trt_err=0;
    %let cont_data=0;
    %let cont_err=0;
    %let no_containers=0;  *-- default to having containers;

    data _null_;
    	do i=1 by 1 until(i > &networktimeout);
	    trtcomplete=0;
	    cntcomplete=0;
	    *-- test for completion files to be created;
	    if fileexist("&treatment_file_success") or fileexist("&treatment_file_failure") then trtcomplete=1;
	    if fileexist("&container_file_success") or fileexist("&container_file_failure") then cntcomplete=1;
	    if trtcomplete eq 1 and cntcomplete eq 1 then leave;
	    call sleep(1, 1); *-- wait for 1 second;
	end;
	call symputx('wait_time_sec', i);
	if fileexist("&treatment_file_success") then do;
	    call symputx('trt_success', 1);
	end;
	if fileexist("&treatment_file_failure") then do;
	    call symputx('trt_success', 0);
	end;
	if fileexist("&treatment_file_data") then do;
	    call symputx('trt_data', 1);
	end;
	if fileexist("&treatment_file_error") then do;
	    call symputx('trt_err', 1);
	end;
	if fileexist("&container_file_success") then do;
	    call symputx('cont_success', 1);
	end;
	if fileexist("&container_file_failure") then do;
	    call symputx('cont_success', 0);
	end;
	if fileexist("&container_file_data") then do;
	    call symputx('cont_data', 1);
	end;
	if fileexist("&container_file_error") then do;
	    call symputx('cont_err', 1);
	end;
    run;

    /* 
    / Upon integration failure, log error and abort macro
    /------------------------------------------------------------------------*/

    *-- check that max time was not exceeded and both files are present;
    %if &wait_time_sec ge &networktimeout and (&trt_data eq 0 or &cont_data eq 0) %then %do;
	%put %str(RTE)RROR: &macroname: Extraction did not complete within &networktimeout seconds.  Aborting macro.;
	%let g_abort=1;
	%tu_abort;
    %end;
    %else %do;
	%put %str(RTN)OTE: &macroname: Extraction background processing completed in &wait_time_sec seconds.;
    %end;

    *-- check if err files exist;
    %if &trt_success eq 0 and &trt_err eq 0 %then %do;
	%put %str(RTE)RROR: &macroname: Treatment data extraction %str(er)ror file not found.  Expected file &treatment_file_error;
	%let g_abort=1;
    %end;
    %if &cont_success eq 0 and &cont_err eq 0 %then %do;
	%put %str(RTE)RROR: &macroname: Container data extraction %str(er)ror file not found.  Expected file &container_file_error;
	%let g_abort=1;
    %end;

    *-- if treatment failure file exists, read contents of err file into the log;
    %if &trt_success eq 0 and &trt_err eq 1 %then %do;
	%put %str(RTE)RROR: &macroname: Extraction of treatment data failed.  Messages from service:;
	filename failfile "&treatment_file_error";
    	data _null_;
	    infile failfile truncover;
	    length line $ 256;
	    input line $ char256.;
	    put "RTE" "RROR: &macroname: " line;
	run;
	*-- remove the treatment data file which was not populated by the service;
	%sysexec %bquote(rm &treatment_file_data.);
	%let g_abort=1;
    %end;

    *-- if container failure file exists, read contents of err file into the log;
    %if &cont_success eq 0 and &cont_err eq 1 %then %do;
	filename failfile "&container_file_error";
    	data _null_;
	    infile failfile truncover;
	    length line $ 256;
	    input line $ char256.;
	    call symputx('errormsg', line);
	    stop;
	run;
	*-- Ignore missing container codes if none defined in RandAll NG (assume non-container study);
	%if %sysfunc(index(&errormsg, %str(No container codes defined))) ne 1 %then %do;
	    %put %str(RTE)RROR: &macroname: Extraction of container data failed.  Message from service:;
	    %put %str(RTE)RROR: &macroname: &errormsg;
	    %let g_abort=1;
	%end;
	%else %do;
	    %let no_containers=1;
	%end;
	*-- remove the container data file which was not populated by the service;
	%sysexec %bquote(rm &container_file_data.);
    %end;

    *-- check that data files exist;
    %if &trt_success eq 1 and &trt_data eq 0 %then %do;
	%put %str(RTE)RROR: &macroname: Extracted treatment data not found.  Expected file &treatment_file_data;
	%let g_abort=1;
    %end;
    %if &no_containers eq 0 %then %do;
	%if &cont_success eq 1 and &cont_data eq 0 %then %do;
	    %put %str(RTE)RROR: &macroname: Extracted container data not found.  Expected file &container_file_data;
	    %let g_abort=1;
	%end;
    %end;

    /* 
    / Clean up temporary files - (only if g_debug is 0)
    / DM2-moved cleanup code from end of macro to before tu_abort call
    /------------------------------------------------------------------------*/
    %if &g_debug eq 0 %then %do;
	*-- delete soap request/response files;
	*-- delete xmlmap file;
	*-- delete success/failure flag files;
	*-- delete error files;
	filename flist pipe "ls -1 &g_rfmtdir./{&macroname._*.xml,&macroname._*.map,&study_id._*_Flag_*.*,&study_id._*_Error_*.csv}";
	data _null_;
	    infile flist truncover;
	    length filenm $ 256;
	    input filenm $ char256.;
	    if fileexist(filenm) then do;
		delfile="delfile";
		rc=filename(delfile, filenm);
		put "RTNOTE: Deleting file [" filenm "]";
		rc=fdelete(delfile);
	    end;
	run;
    %end;

    *-- abort if an error was detected;
    %if &g_abort gt 0 %then %do;
    	%tu_abort;
    %end;

    /* 
    / Generate templates for TRTGRPMAP, EXPCTMAP, and CTTYPMAP
    /------------------------------------------------------------------------*/
    *-- import treatment randomisation CSV file;
    /* DM2-to ensure correct data types, use modified data block generated from proc import
    proc import datafile="&treatment_file_data"
	out=&macroname._trtrand
	dbms=csv
	replace;
	getnames=yes;
    run;
    */
    data &macroname._trtrand; /*DM2*/
	infile "&treatment_file_data" delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
	informat RANDNUM best32. ;
	informat STRATUM $200. ;
	informat TRTGRPD $200. ;
	informat TRTGRPC $120. ;
	informat TRTD $200. ;
	informat TRTC $120. ;
	informat PERNUM best32. ;
	informat SCHEDNUM best32. ;
	informat SCHEDTX $200. ;
	format RANDNUM best12. ;
	format STRATUM $200. ;
	format TRTGRPD $200. ;
	format TRTGRPC $120. ;
	format TRTD $200. ;
	format TRTC $120. ;
	format PERNUM best12. ;
	format SCHEDNUM best12. ;
	format SCHEDTX $200. ;
	input
                RANDNUM
                STRATUM $
                TRTGRPD $
                TRTGRPC $
                TRTD $
                TRTC $
                PERNUM
                SCHEDNUM
                SCHEDTX $
	;
    run;

    *-- create TRTGRPMAP template;
    %if %sysfunc(fileexist(&g_rfmtdir./trtgrpmap.csv)) ne 1 %then %do; *-- if file does not exist;
	proc sql;
	    create table &macroname._trtgrpmap as
	    select distinct TRTGRPC format $120., TRTGRPD format $200., '' as EXPARMCD format $20., '' as EXPARM format $200. /*DM2*/
	      from &macroname._trtrand
	     order by trtgrpc;
	quit;

	proc export
	    data=&macroname._trtgrpmap
	    dbms=csv
	    outfile="&g_rfmtdir./trtgrpmap.csv"; *-- NOTE: without replace option, existing file will be retained;
	run;
    %end;
    %else %do;
    	%put %str(RTN)OTE: &macroname: Generation of template skipped because file &g_rfmtdir./trtgrpmap.csv already exists.;
    %end;

    *-- create EXPCTMAP template;
    %if %sysfunc(fileexist(&g_rfmtdir./expctmap.csv)) ne 1 %then %do; *-- if file does not exist;
	proc sql;
	    create table &macroname._expctmap as
	    select distinct TRTC format $120., TRTD format $200., '' as EXPCTYPC format $55., '' as EXPCTYPD format $200. /*DM2*/
	      from &macroname._trtrand
	     order by trtc;
	quit;

	proc export
	    data=&macroname._expctmap
	    dbms=csv
	    outfile="&g_rfmtdir./expctmap.csv"; *-- NOTE: without replace option, existing file will be retained;
	run;
    %end;
    %else %do;
    	%put %str(RTN)OTE: &macroname: Generation of template skipped because file &g_rfmtdir./expctmap.csv already exists.;
    %end;
    
    *-- import container randomisation CSV file;
    %if %sysfunc(fileexist(&g_rfmtdir./cttypmap.csv)) ne 1 %then %do; *-- if file does not exist;
	%if &no_containers eq 0 %then %do;
	    /* DM2-to ensure correct data types, use modified data block generated from proc import
	    proc import datafile="&container_file_data"
		out=&macroname._contrand
		dbms=csv
		replace;
		getnames=yes;
	    run;
	    */
	    data &macroname._contrand; /*DM2*/
		infile "&container_file_data" delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2;
		informat CTREFID $20.;
		informat CTTYPC $10.;
		informat CTTYPD $200.;
		format CTREFID $20.;
		format CTTYPC $10.;
		format CTTYPD $200.;
		input
		       CTREFID $
		       CTTYPC $
		       CTTYPD $
		;
	    run;
	%end;
	%else %do;
	    *-- create dummy, empty contrand dataset if no containers;
	    data &macroname._contrand;
		length CTTYPC $ 10;
		length CTTYPD $ 200;
		label CTTYPC="Container type code";
		label CTTYPD="Container type description";
		CTTYPC="";
		CTTYPD="";
		stop;
	    run;
	%end;

	*-- create CTTYPMAP template;
	proc sql;
	    create table &macroname._cttypmap as
	    select distinct CTTYPC format $10. /*DM2*/
	         , CTTYPD format $200. /*DM2*/
	         , '' as CTRT format $40. /*DM2*/
		 , '' as CTDOSE format $8. /*DM2*/
		 , '' as CTDOSEU format $20. /*DM2*/
		 , '' as CTDOSFRM format $80. /*DM2*/
		 , '' as CTDOSTXT format $20. /*DM2*/
	      from &macroname._contrand
	     order by cttypc;
	quit;

	proc export
	    data=&macroname._cttypmap
	    dbms=csv
	    outfile="&g_rfmtdir./cttypmap.csv"; *-- NOTE: without replace option, existing file will be retained;
	run;
    %end;
    %else %do;
    	%put %str(RTN)OTE: &macroname: Generation of template skipped because file &g_rfmtdir./cttypmap.csv already exists.;
    %end;

    /* 
    / Tidy up temporary datasets
    /------------------------------------------------------------------------*/
    %tu_tidyup(rmdset=&macroname.:, glbmac=none);

%mend tc_trtextract;

