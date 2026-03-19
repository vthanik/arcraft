/*----------------------------------------------------------------------------+
| Macro Name    : tc_contlst.sas
|
| Macro Version : 1 Build 2
|
| SAS version   : SAS v9.4
|
| Created By    : Daniel McDonald (dwm95161)
|
| Date          : September 2016
|
| Macro Purpose : Macro to create CONTLST reference dataset
|
| Macro Design  : PROCEDURE STYLE
|
| Input Parameters :
|
| NAME			DESCRIPTION                             	DEFAULT
|
| CONTCSVIN		Specifies which container codes CSV file to 	LATEST
|			use to create the CONTLST dataset.
|			Valid values:  LATEST or a file name
|
| CTTYPMAP 		References the container type map spreadsheet	&g_rfmtdir./cttypmap.csv
|
| EXPCTMAP		References the expected container type map	&g_rfmtdir./expctmap.csv
|			spreadsheet
|
|---------------------------------------------------------------------------------------------------
|
| Output:   1. CONTLST dataset
|
| Global macro variables created: None
|
|
| Macros called :
| (@) tu_nobs
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_abort
| (@) tu_tidyup
|
| Example:
|	%tc_contlst(
|	    contcsvin=LATEST,
|	    cttypmap=&g_rfmtdir./cttypmap.csv
|	    expctmap=&g_rfmtdir./expctmap.csv
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
| 	BDS/HARP_RT Defect 636 - Log shows 'RTNOTE: RC_CONTLST: deleting container codes CSV files.'
|				 for study without container lists
|
| Modified By :
| Date of Modification :
| New Version Number :
| Modification ID :
| Reason For Modification :
|
+----------------------------------------------------------------------------*/

/* 
/ Begin tc_contlst macro
/------------------------------------------------------------------------*/
%macro tc_contlst(
    contcsvin=LATEST,			/* Specifies which container codes CSV file to use to create the CONTLST dataset. */
    cttypmap=&g_rfmtdir./cttypmap.csv,	/* References the container type map spreadsheet */
    expctmap=&g_rfmtdir./expctmap.csv	/* References the expected container type map spreadsheet */
);
    %local macroname;
    %let macroname=&sysmacroname;

    /*
    / Echo parameter values and global macro variables to the log.
    /------------------------------------------------------------------------*/
    %local MacroVersion;
    %let MacroVersion = 1 Build 2;
    %include "&g_refdata/tr_putlocals.sas";
    %tu_putglobals(varsin=g_rfmtdir g_debug g_abort);

    /*
    / PARAMETER VALIDATION
    /------------------------------------------------------------------------*/
    %let contcsvin	= %nrbquote(&contcsvin);
    %let cttypmap	= %nrbquote(&cttypmap);
    %let expctmap	= %nrbquote(&expctmap);

    /*
    / Check for required parameters.
    /------------------------------------------------------------------------*/

    %if &contcsvin eq %then %do;
    	%if &expctmap eq %then %do;
	    %put %str(RTE)RROR: &macroname: One of the parameters CONTCSVIN or EXPCTMAP is required.;
	    %let g_abort=1;
	%end;
    %end;

    %if &cttypmap eq %then %do;
	%put %str(RTE)RROR: &macroname: The parameter CTTYPMAP is required.;
	%let g_abort=1;
    %end;

    *-- abort if required parameters are not provided;
    %if &g_abort eq 1 %then %do;
	%tu_abort;
    %end;

    /*
    / Check for valid parameter values.
    /------------------------------------------------------------------------*/

    %if %sysfunc(fileexist(&cttypmap)) ne 1 %then %do; *-- if file does not exist;
	%put %str(RTE)RROR: &macroname: CTTYPMAP should reference an existing file.;
	%let g_abort=1;
    %end;

    %if &expctmap ne %then %do;
	%if %sysfunc(fileexist(&expctmap)) ne 1 %then %do; *-- if file does not exist;
	    %put %str(RTE)RROR: &macroname: EXPCTMAP should reference an existing file.;
	    %let g_abort=1;
	%end;
    %end;

    %if &contcsvin ne %then %do;
	%if %bquote(%upcase(&contcsvin)) eq LATEST %then %do;
	    *-- find the latest file of either blindtype in the refdata folder of the reporting effort;
	    filename lsrfdata pipe "ls -t1 &g_rfmtdir/*.csv | grep '_ContainerCodes_' | grep -v '_Error_'"; *ls -t1 => sort by time, output single column;
	    data _null_;
		call symputx('file_found', 0); *-- set to 0 for No;
		infile lsrfdata truncover obs=1; *-- read first obs only and truncate if value too long;
		length filenm $ 256;
		input filenm $ char256.;
		call symputx('file_found', 1); *-- if got here there are obs so set to 1 for Yes;
		*-- replace contcsvin with file name of latest treatment data CSV file;
		call symputx('contcsvin', filenm); *-- set contcsvin to the file path;
		%if &g_debug gt 0 %then %do;
		    put filenm=;
		%end;
		stop;
	    run;

	    %if &file_found eq 0 %then %do;
		*-- if no file found, generate error and abort;
		%put %str(RTE)RROR: &macroname: No container codes CSV file was found in &g_rfmtdir;
		%let g_abort=1;
	    %end;
	%end;
	%else %if %sysfunc(fileexist(&g_rfmtdir/&contcsvin)) eq 1 %then %do; *-- if file exists in refdata directory;
	    %let contcsvin=&g_rfmtdir/&contcsvin;
	%end;
	%else %do;
	    %put %str(RTE)RROR: &macroname: parameter CONTCSVIN must be LATEST or the name of a file in &g_rfmtdir;
	    %let g_abort=1;
	%end;
    %end;

    *-- abort if parameter validation failed;
    %if &g_abort eq 1 %then %do;
	%tu_abort;
    %end;

    %let contcsvin = %nrbquote(&contcsvin);
    %put %str(RTN)OTE &macroname: contcsvin resolves to &contcsvin;

    /*
    / Check for valid dependencies.
    /------------------------------------------------------------------------*/

    /* 
    / Internal helper macro to check field lengths and test for allowed blank values.
    / Parameters:
    /   maptable		The suffix of a dataset named &macroname._&maptable
    /   fields		A list of the fields to be checked for validity
    /   lengths		A list of the maximum lengths of the fields
    /   allowblanks		A list of fields which allow blanks
    /   exclusiveblanks	A list of field pairs of which only one may be blank
    /			(e.g., "CTDOSE:CTDOSTXT CTDOSEU:CTDOSTXT")
    / Behavior:
    /   Message logged and g_abort set to 1 if noncompliance is discovered
    /------------------------------------------------------------------------*/
    %macro check_field_lengths_allow_blanks(maptable, fields, lengths, allowblanks, exclusiveblanks);
	%global g_abort;
	%local numfields compliant blankval noncompliant_fields blank_fields field maxlen dsid ftype rc;
	%let compliant=1; *-- assume compliant with field lengths;
	%let blankval=0; *-- assume no blank values;
	%let numfields=%sysfunc(countw(&fields, %str( )));
	data _null_;
	    length noncompliant_fields $200;
	    length blank_fields $200;
	    retain noncompliant_fields ' ';
	    retain blank_fields ' ';
	    set &macroname._&maptable end=eof;
	    %let dsid=%sysfunc(open(&macroname._&maptable));
	    %do i=1 %to &numfields;
		%let field=%scan(%bquote(&fields), &i, ' ');
		%let maxlen=%scan(%bquote(&lengths), &i, ' ');
		*-- test for too long values;
		%let ftype=%sysfunc(vartype(&dsid, %sysfunc(varnum(&dsid, &field))));
		*-- handle numeric variables separately from character variables;
		%if &ftype eq N %then %do;
		    len_&field = lengthn(strip(put(&field, best32.)));
		%end;
		%else %do;
		    len_&field = lengthn(&field);
		%end;
		if len_&field gt &maxlen then do;
		    call symputx('compliant', 0);
		    if index(noncompliant_fields, "&field") eq 0 then noncompliant_fields = catx(', ', noncompliant_fields, "&field(&maxlen)");
		end;
		*-- test for blank values;
		if index("&allowblanks", "&field") eq 0 and len_&field eq 0 then do;
		    *-- keep track of blank fields which are not allowed;
		    call symputx('blankval', 1);
		    if index(blank_fields, "&field") eq 0 then blank_fields = catx(', ', blank_fields, "&field");
		end;
	    %end;
	    *-- test for exclusive blank fields;
	    %let count=%sysfunc(countw(&exclusiveblanks, %str( )));
	    %do i=1 %to &count;
		%let field_pair=%scan(%bquote(&exclusiveblanks), &i, ' ');
		%let field1=%scan(&field_pair, 1, ':');
		%let field2=%scan(&field_pair, 2, ':');
		
		*-- Test if both fields are blank;
		if len_&field1 eq 0 and len_&field2 eq 0 then do;
		    put "RTE" "RROR: &macroname: The &maptable fields &field1 and &field2 on row " _N_ " cannot both be blank";
		    call symputx('g_abort', 1);
		end;
		*-- Test if both fields are not blank;
		if len_&field1 gt 0 and len_&field2 gt 0 then do;
		    put "RTE" "RROR: &macroname: One of the &maptable fields &field1 and &field2 on row " _N_ " must be blank";
		    call symputx('g_abort', 1);
		end;
	    %end;
	    %let rc=%sysfunc(close(&dsid));
	    if eof then call symputx('noncompliant_fields', noncompliant_fields);
	    if eof then call symputx('blank_fields', blank_fields);
	run;

	%if &compliant eq 0 %then %do;
	    %put %str(RTE)RROR: &macroname: The &maptable fields do not comply with expected field lengths: &noncompliant_fields.;
	    %let g_abort=1;
	%end;

	%if &blankval eq 1 %then %do;
	    %put %str(RTE)RROR: &macroname: The &maptable is incomplete. Blank values found in column(s): &blank_fields.;
	    %let g_abort=1;
	%end;
    %mend check_field_lengths_allow_blanks;

    *------------------------------------------------------;
    *-- Verify container codes and dose details in CTTYPMAP;
    *------------------------------------------------------;
    proc import datafile="&cttypmap"
	out=&macroname._cttypmap
	dbms=csv
	replace;
	getnames=yes;
	guessingrows=1000000; /*DM2*/
    run;

    %if %sysfunc(exist(&macroname._cttypmap)) eq 0 %then %do;
	%put %str(RTE)RROR: &macroname: Failed to import CTTYPMAP. Check that the file &cttypmap is complete.;
	%let g_abort=1;
    	%tu_abort;
    %end;

    *-- 1. Verify CTTYPMAP field lengths and ensure no blank values;
    %local maptable fields lengths allowblanks exclusiveblanks;
    %let maptable=CTTYPMAP;
    %let fields=CTTYPC CTTYPD CTRT CTDOSE CTDOSEU CTDOSFRM CTDOSTXT; *-- these are the fields in &maptable;
    %let lengths=10 200 40 8 20 80 20;		 *-- these are the field lengths in &maptable;
    %let allowblanks=CTDOSE CTDOSEU CTDOSFRM CTDOSTXT;
    *-- Verify that one and only one of CTDOSE and CTDOSTXT are provided;
    *-- Verify that CTDOSEU is provided only if CTDOSE is provided;
    %let exclusiveblanks=CTDOSE:CTDOSTXT CTDOSEU:CTDOSTXT;
    %check_field_lengths_allow_blanks(&maptable, &fields, &lengths, &allowblanks, &exclusiveblanks);

    *-- abort if field length validation failed;
    %if &g_abort eq 1 %then %do;
	%tu_abort;
    %end;

    *-- import container randomisation CSV file;
    %if &contcsvin ne %then %do;
	/* to ensure correct data types, use modified data block generated from proc import
	proc import datafile="&contcsvin"
	    out=&macroname._contcode
	    dbms=csv
	    replace;
	    getnames=yes;
	run;
	*/

	data WORK.&macroname._CONTCODE;
	    infile "&contcsvin" delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2;
	    informat CTREFID $20.;
	    informat CTTYPC $10.;
	    informat CTTYPD $200.;
	    format CTREFID $20.;
	    format CTTYPC $10.;
	    format CTTYPD $200.;
	    input
		   CTREFID $  /*DM2*/
		   CTTYPC $
		   CTTYPD $
	    ;
	run;

	proc sql;
	    create table &macroname._uniqctcd as
	    select distinct cttypc, cttypd
	      from &macroname._contcode;
	quit;

	*-- 2. Confirm all CTTYPC, CTTYPD value pairs from Container Codes CSV are present in CTTYPMAP;
	%local not_found_count;
	proc sql;
	    create table &macroname._ck1 as
	    select distinct cttypc, cttypd
	      from &macroname._uniqctcd c
	     where not exists (select cttypc, cttypd
				from &macroname._cttypmap m
			       where c.cttypc = m.cttypc
				 and c.cttypd = m.cttypd);
	quit;

	%let not_found_count = %tu_nobs(&macroname._ck1);
	%if &not_found_count gt 0 %then %do;
	    %put %str(RTE)RROR: &macroname: The CTTYPMAP reference spreadsheet is missing some (&not_found_count) CTTYPC, CTTYPD pairs from &contcsvin;
	    data _null_;
		set &macroname._ck1;
		msg = cats('RTE', 'RROR: (CTTYPC,CTTYPD) values (', cttypc, ',', cttypd, ') from CTTYPMAP not found in container codes CSV');
		put msg;
	    run;
	    %let g_abort=1;
	%end;
    %end;

    %if &expctmap ne %then %do;
	*-- Import EXPCTMAP spreadsheet;
	proc import datafile="&expctmap"
	    out=&macroname._expctmap
	    dbms=csv
	    replace;
	    getnames=yes;
	    guessingrows=1000000; /*DM2*/
	run;

	%if %sysfunc(exist(&macroname._expctmap)) eq 0 %then %do;
	    %put %str(RTE)RROR: &macroname: Failed to import EXPCTMAP. Check that the file &expctmap is complete.;
	    %let g_abort=1;
	    %tu_abort;
	%end;

	*-- 3. Confirm all CTTYPC, CTTYPD value pairs from CTTYPMAP are in EXPCTMAP as EXPCTYPC, EXPCTYPD;
	%local not_found_count;
	proc sql;
	    create table &macroname._ck2 as
	    select distinct cttypc, cttypd
	      from &macroname._cttypmap m
	     where not exists (select expctypc, expctypd
				from &macroname._expctmap e
			       where e.expctypc = m.cttypc
				 and e.expctypd = m.cttypd);
	quit;

	%let not_found_count = %tu_nobs(&macroname._ck2);
	%if &not_found_count gt 0 %then %do;
	    %put %str(RTE)RROR: &macroname: The CTTYPMAP reference spreadsheet is missing some (&not_found_count) CTTYPC, CTTYPD pairs from &expctmap;
	    data _null_;
		set &macroname._ck2;
		msg = cats('RTE', 'RROR: (CTTYPC,CTTYPD) values (', cttypc, ',', cttypd, ') from CTTYPMAP not found in EXPCTMAP spreadsheet');
		put msg;
	    run;
	    %let g_abort=1;
	%end;
    %end;

    *-- 4. Confirm all CTTYPD values consistently have "Draft-" prefix or not;
    %local draft_count;
    proc sql noprint;
    	select count(*)
	  into :draft_count
	  from &macroname._cttypmap m
	 where cttypd like 'Draft-%';
    quit;

    %let nobs_cttypmap = %tu_nobs(&macroname._cttypmap);
    %if &draft_count ne &nobs_cttypmap and &draft_count ne 0 %then %do;
	%put %str(RTE)RROR: &macroname: Some (%left(&draft_count)) but not all (&nobs_cttypmap) CTTYPMAP CTTYPD values have the 'Draft-' prefix;
	data _null_;
	    set &macroname._cttypmap;
	    if index(cttypd, 'Draft-') ne 1 then do;
		msg = cats('RTE', "RROR: CTTYPD value (", cttypd, ") from CTTYPMAP does not have the 'Draft-' prefix");
		put msg;
	    end;
	run;
	%let g_abort=1;
    %end;

    *-- 5. Confirm all CTRT values have "Draft-" prefix only if CTTYPD has it;
    data _null_;
	set &macroname._cttypmap;
	i1 = index(cttypd, 'Draft-');
	i2 = index(ctrt, 'Draft-');
	if i1 eq 1 and i2 eq 0 then do;
	    msg = cats('RTE', "RROR: CTRT value (", ctrt, ") from CTTYPMAP must have the 'Draft-' prefix");
	    put msg;
	    call symputx('g_abort', 1);
	end;
	else if i1 eq 0 and i2 eq 1 then do;
	    msg = cats('RTE', "RROR: CTRT value (", ctrt, ") from CTTYPMAP must not have the 'Draft-' prefix");
	    put msg;
	    call symputx('g_abort', 1);
	end;
    run;

    *-- abort if parameter validation failed;
    %if &g_abort eq 1 %then %do;
	%tu_abort;
    %end;
    /*
    / Macro parameters have valid values if the program has
    / not terminated by this point.
    /------------------------------------------------------------------------*/

    /* 
    / Generate CONTLST dataset
    /------------------------------------------------------------------------*/
    %if &contcsvin ne %then %do;
	*-- merge container codes CSV and CTTYPMAP into tmpcontlst1;
	proc sort data=&macroname._contcode;
	    by cttypc;
	run;

	proc sort data=&macroname._cttypmap;
	    by cttypc;
	run;

	data &macroname._tmpcontlst1;
	    merge &macroname._contcode &macroname._cttypmap (drop=cttypd);
	    by cttypc;
	run;

	proc sort data=&macroname._tmpcontlst1;
	    by ctrefid;
	run;
    %end;
    %else %do;
    	*-- copy CTTYPMAP contents into tmpcontlst1 with missing CTREFID values;
	data &macroname._tmpcontlst1;
	    length CTREFID $ 20;
	    set &macroname._cttypmap;
	    CTREFID=.;
	run;
    %end;

    *-- copy tmpcontlst1 to CONTLST;
    data rfmtdir.contlst(label='Container ID information');
    	*-- define the data type and length for each CONTLST variable;
	length CTREFID $ 20;
	length CTTYPC $ 10;
	length CTTYPD $ 200;
	length CTRT $ 40;
	length CTDOSE 8;
	length CTDOSEU $ 20;
	length CTDOSFRM $ 80;
	length CTDOSTXT $ 20;
	label CTREFID="Container Reference ID"; *-- labels from CONTLST dataset definition;
	label CTTYPC="Container Type Code";
	label CTTYPD="Container Type Description";
	label CTRT="Name of Treatment";
	label CTDOSE="Dose Per Administration";
	label CTDOSEU="Dose Unit";
	label CTDOSFRM="Dose Form";
	label CTDOSTXT="Dose Text";
    	set &macroname._tmpcontlst1; *-- copy records from tmpcontlst1 into CONTLST;
    run;

    /* 
    / Remove container codes CSV files
    /------------------------------------------------------------------------*/
    %if %sysfunc(exist(rfmtdir.contlst)) %then %do;
    	%if &contcsvin ne %then %do;  /*DM2-only attempt deletion if contcsvin provided*/
	    filename delcsv pipe "ls -tr1 &g_rfmtdir/* | grep '_ContainerCodes_'";
	    %if &g_debug gt 0 %then %do;
		%put %str(RTN)OTE: &macroname: deleting container codes CSV files;
	    %end;
	    data _null_;
		infile delcsv truncover;
		length filenm $ 256;
		input filenm $ char256.;
		csvfile="csvfile";
		rc=filename(csvfile, filenm);
		rc=fdelete(csvfile);
		%if &g_debug gt 0 %then %do;
		    put filenm=;
		    put rc=;
		%end;
	    run;
	%end;  /*DM2*/
    %end;

    /* 
    / Tidy up
    /------------------------------------------------------------------------*/
    %tu_tidyup(rmdset=&macroname.:, glbmac=none);

%mend tc_contlst;

