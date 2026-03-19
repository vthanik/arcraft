/*----------------------------------------------------------------------------+
| Macro Name    : tc_exptrt.sas
|
| Macro Version : 1 Build 2
|
| SAS version   : SAS v9.4
|
| Created By    : Daniel McDonald (dwm95161)
|
| Date          : September 2016
|
| Macro Purpose : Macro to create EXPTRT reference dataset
|
| Macro Design  : PROCEDURE STYLE
|
| Input Parameters :
|
| NAME			DESCRIPTION                             	DEFAULT
|
| TRTGRPMAP		References the treatment group map spreadsheet	&g_rfmtdir./trtgrpmap.csv
|
| EXPCTMAP		Refernences the expected container type map	&g_rfmtdir./expctmap.csv
|			spreadsheet
|
| CTTYPMAP		Refernences the container type map spreadsheet	&g_rfmtdir./cttypmap.csv
|
| TADSET		Name of TA dataset to use to validate the 	sdtmdata.ta
|			TRTGRPMAP reference spreadsheet
|
|---------------------------------------------------------------------------------------------------
|
| Output:   1. EXPTRT dataset
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
|	%tc_exptrt(
|	    trtgrpmap=&g_rfmtdir./trtgrpmap.csv,
|	    expctmap=&g_rfmtdir./expctmap.csv,
|	    cttypmap=&g_rfmtdir./cttypmap.csv,
|	    tadset=sdtmdata.ta
|	    );
|
| **************************************************************************
| Change Log :
|
| Modified By : Daniel McDonald
| Date of Modification : 23-Sep-2016
| New Version Number : 01-002
| Modification ID : DM2
| Reason For Modification :
|	RD_IT/AR_HARP_195808 Defect 542 - TRTGRPMAP contains truncated TRTGRPC and TRTGRPD variables
|	BDS/HARP_RT Defect 628 - Excessive errors reported if RANDALL1 dataset is not found
|	BDS/HARP_RT Defect 629 - additional observations missing when multiple container codes
|				 are associated with treatments
|
| Modified By :
| Date of Modification :
| New Version Number :
| Modification ID :
| Reason For Modification :
|
+----------------------------------------------------------------------------*/

%macro tc_exptrt(
    trtgrpmap=&g_rfmtdir./trtgrpmap.csv, /* References the treatment group map spreadsheet */
    expctmap=&g_rfmtdir./expctmap.csv,   /* References the expected container type map spreadsheet */
    cttypmap=&g_rfmtdir./cttypmap.csv,   /* References the container type map spreadsheet to use to validate the EXPCTMAP container type code and description values */
    tadset=sdtmdata.ta		       /* Name of the TA dataset to use to validate the TRTGRPMAP reference spreadsheet */
);
    %local macroname;
    %let macroname=&sysmacroname;

    /*
    / Echo parameter values and global macro variables to the log.
    /------------------------------------------------------------------------*/
    %local MacroVersion;
    %let MacroVersion = 1 Build 2;
    %include "&g_refdata/tr_putlocals.sas";
    %tu_putglobals(varsin=g_rfmtdir g_abort);

    /*
    / PARAMETER VALIDATION
    /------------------------------------------------------------------------*/
    %let trtgrpmap	= %nrbquote(&trtgrpmap);
    %let expctmap	= %nrbquote(&expctmap);
    %let cttypmap	= %nrbquote(&cttypmap);
    %let tadset		= %nrbquote(&tadset);

    /*
    / Check for required parameters.
    /------------------------------------------------------------------------*/

    %if &trtgrpmap eq %then %do;
	%put %str(RTE)RROR: &macroname: The parameter TRTGRPMAP is required.;
	%let g_abort=1;
    %end;

    %if &expctmap eq %then %do;
	%put %str(RTE)RROR: &macroname: The parameter EXPCTMAP is required.;
	%let g_abort=1;
    %end;

    %if &cttypmap eq %then %do;
	%put %str(RTE)RROR: &macroname: The parameter CTTYPMAP is required.;
	%let g_abort=1;
    %end;

    *-- abort if required parameters are missing;
    %if &g_abort eq 1 %then %do;
	%tu_abort;
    %end;

    /*
    / Check for valid parameter values.
    /------------------------------------------------------------------------*/

    %if %sysfunc(fileexist(&trtgrpmap)) ne 1 %then %do; *-- if file does not exist;
	%put %str(RTE)RROR: &macroname: TRTGRPMAP should reference an existing file.;
	%let g_abort=1;
    %end;

    %if %sysfunc(fileexist(&expctmap)) ne 1 %then %do; *-- if file does not exist;
	%put %str(RTE)RROR: &macroname: EXPCTMAP should reference an existing file.;
	%let g_abort=1;
    %end;

    %if %sysfunc(fileexist(&cttypmap)) ne 1 %then %do; *-- if file does not exist;
	%put %str(RTE)RROR: &macroname: CTTYPMAP should reference an existing file.;
	%let g_abort=1;
    %end;

    *-- abort if initial parameter validation failed;
    %if &g_abort eq 1 %then %do;
	%tu_abort;
    %end;

    %local ta_available;
    %let ta_available=0; *-- assume TA not available;
    %if &tadset ne %then %do;
    	%if not %sysfunc(exist(&tadset)) %then %do;
	    %put %str(RTE)RROR: &macroname: The dataset TADSET(=&tadset) does not exist.;
	    %let g_abort=1;
	%end;
	%else %do;
	    %let ta_available=1; *-- set flag that TA is available;
	%end;
    %end;

    /*
    / Check for valid dependencies.
    /------------------------------------------------------------------------*/

    *-- Verify RANDALL1 dataset is found in the current reporting effort refdata directory;
    %if not %sysfunc(exist(rfmtdir.randall1)) %then %do;
	%put %str(RTE)RROR: &macroname: The dataset RANDALL1(=rfmtdir.randall1) is required and does not exist.;
	%let g_abort=1;
    %end;

    *-- DM2-abort if parameter validation failed;
    %if &g_abort eq 1 %then %do;
	%tu_abort;  /*DM2*/
    %end;

    /* 
    / Internal helper macro to check field lengths and test for blank values.
    / Parameters:
    /   maptable	The suffix of a dataset named &macroname._&maptable
    /   fields	A list of the fields to be checked for validity
    /   lengths	A list of the maximum lengths of the fields
    / Behavior:
    /   Message logged and g_abort set to 1 if noncompliance is discovered
    /------------------------------------------------------------------------*/
    %macro check_field_lengths_and_blanks(maptable, fields, lengths);
	%local numfields compliant blankval noncompliant_fields blank_fields;
	%let compliant=1; *-- assume compliant with field lengths;
	%let blankval=0; *-- assume no blank values;
	%let numfields=%sysfunc(countw(&fields, %str( )));
	data _null_;
	    length noncompliant_fields $200;
	    length blank_fields $200;
	    retain noncompliant_fields ' ';
	    retain blank_fields ' ';
	    set &macroname._&maptable end=eof;
	    %do i=1 %to &numfields;
		%let field=%scan(%bquote(&fields), &i, ' ');
		%let maxlen=%scan(%bquote(&lengths), &i, ' ');
		len_&field = lengthn(&field);
		*-- test for too long values;
		if len_&field gt &maxlen then do;
		    call symputx('compliant', 0);
		    if index(noncompliant_fields, "&field.(") eq 0 then noncompliant_fields = catx(', ', noncompliant_fields, "&field(&maxlen)");  /*DM2-fixed missing field when name is a subset of another field name*/
		end;
		*-- test for blank values;
		if len_&field eq 0 then do;
		    call symputx('blankval', 1);
		    if index(blank_fields, "'&field.'") eq 0 then blank_fields = catx(', ', blank_fields, "'&field.'");  /*DM2-fixed missing field when name is a subset of another field name*/
		end;
	    %end;
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
    %mend check_field_lengths_and_blanks;

    *--------------------------------------------;
    *-- Verify treatment group codes in TRTGRPMAP;
    *--------------------------------------------;
    proc import datafile="&trtgrpmap"
	out=&macroname._trtgrpmap
	dbms=csv
	replace;
	getnames=yes;
	guessingrows=1000000; /*DM2*/
    run;

    %if %sysfunc(exist(&macroname._trtgrpmap)) eq 0 %then %do;
	%put %str(RTE)RROR: &macroname: Failed to import TRTGRPMAP. Check that the file &trtgrpmap is complete.;
	%let g_abort=1;
    	%tu_abort;
    %end;

    *-- 1. Verify TRTGRPMAP field lengths and ensure no blank values;
    %local maptable fields lengths;
    %let maptable=TRTGRPMAP;
    %let fields=TRTGRPC TRTGRPD EXPARMCD EXPARM; *-- these are the fields in &maptable;
    %let lengths=120 200 20 200;		 *-- these are the field lengths in &maptable;

    %check_field_lengths_and_blanks(&maptable, &fields, &lengths);

    *-- 2a. Confirm all TRTGRPC, TRTGRPD value pairs from RANDALL1 are present in TRTGRPMAP;
    %local not_found_count;
    proc sql;
    	create table &macroname._ck1 as
    	select distinct trtgrpc, trtgrpd
	  from rfmtdir.randall1 r
	 where not exists (select trtgrpc, trtgrpd
	 		    from &macroname._trtgrpmap m
			   where r.trtgrpc = m.trtgrpc
			     and r.trtgrpd = m.trtgrpd);
    quit;

    %let not_found_count = %tu_nobs(&macroname._ck1);
    %if &not_found_count gt 0 %then %do;
	%put %str(RTE)RROR: &macroname: Some (&not_found_count) RANDALL1 TRTGRPC,TRTGRPD value pairs are not found in the TRTGRPMAP reference spreadsheet;
	data _null_;
	    set &macroname._ck1;
	    msg = cats('RTE', 'RROR: (TRTGRPC,TRTGRPD) values (', trtgrpc, ',', trtgrpd, ') from RANDALL1 not found in TRTGRPMAP');
	    put msg;
	run;
	%let g_abort=1;
    %end;

    *-- 2b. Confirm all TRTGRPC, TRTGRPD value pairs from TRTGRPMAP are present in RANDALL1;
    %local not_found_count;
    proc sql;
    	create table &macroname._ck1b as
    	select distinct trtgrpc, trtgrpd
	  from &macroname._trtgrpmap m
	 where not exists (select trtgrpc, trtgrpd
	 		    from rfmtdir.randall1 r
			   where r.trtgrpc = m.trtgrpc
			     and r.trtgrpd = m.trtgrpd);
    quit;

    %let not_found_count = %tu_nobs(&macroname._ck1b);
    %if &not_found_count gt 0 %then %do;
	%put %str(RTE)RROR: &macroname: Some (&not_found_count) TRTGRPMAP TRTGRPC,TRTGRPD value pairs are not found in the RANDALL1 dataset;
	data _null_;
	    set &macroname._ck1b;
	    msg = cats('RTE', 'RROR: (TRTGRPC,TRTGRPD) values (', trtgrpc, ',', trtgrpd, ') from TRTGRPMAP not found in RANDALL1');
	    put msg;
	run;
	%let g_abort=1;
    %end;

    *-- 3. Verify EXPARMCD and EXPARM are not blank and match TA ARMCD and ARM allowing for "Draft-" prefix;
    %local not_found_count2;
    %if &ta_available eq 1 %then %do;
    	proc sql;
	    create table &macroname._ck2 as
	    select distinct exparmcd, exparm
	      from &macroname._trtgrpmap m
	     where not exists (select armcd, arm
	     			 from &tadset ta
				where ta.armcd = m.exparmcd
				  and (ta.arm = m.exparm or 'Draft-' || ta.arm = m.exparm));
	quit;

	%let not_found_count2 = %tu_nobs(&macroname._ck2);
	%if &not_found_count2 gt 0 %then %do;
	    %put %str(RTE)RROR: &macroname: Some (&not_found_count2) TRTGRPMAP EXPARMCD, EXPARM pairs are not found in SDTM TA dataset (&tadset);
	    data _null_;
	    	set &macroname._ck2;
		msg = cats('RTE', 'RROR: (EXPARMCD,EXPARM) values (', exparmcd, ',', exparm, ') from TRTGRPMAP not found in SDTM TA dataset');
		put msg;
	    run;
	    %let g_abort=1;
	%end;
    %end;

    *-- 4. Confirm all TRTGRPD values consistently have "Draft-" prefix or not;
    %local draft_count;
    proc sql noprint;
    	select count(*)
	  into :draft_count
	  from &macroname._trtgrpmap m
	 where trtgrpd like 'Draft-%';
    quit;

    %let nobs_trtgrpmap = %tu_nobs(&macroname._trtgrpmap);
    %if &draft_count ne &nobs_trtgrpmap and &draft_count ne 0 %then %do;
	%put %str(RTE)RROR: &macroname: Some (%left(&draft_count)) but not all (&nobs_trtgrpmap) TRTGRPMAP TRTGRPD values have the 'Draft-' prefix;
	data _null_;
	    set &macroname._trtgrpmap;
	    if index(trtgrpd, 'Draft-') ne 1 then do;
		msg = cats('RTE', "RROR: TRTGRPD value (", trtgrpd, ") from TRTGRPMAP does not have the 'Draft-' prefix");
		put msg;
	    end;
	run;
	%let g_abort=1;
    %end;

    *-- 5. Confirm all EXPARM values have "Draft-" prefix only if TRTGRPD has it;
    data _null_;
	set &macroname._trtgrpmap;
	i1 = index(trtgrpd, 'Draft-');
	i2 = index(exparm, 'Draft-');
	if i1 eq 1 and i2 eq 0 then do;
	    msg = cats('RTE', "RROR: EXPARM value (", exparm, ") from TRTGRPMAP must have the 'Draft-' prefix");
	    put msg;
	    call symputx('g_abort', 1);
	end;
	else if i1 eq 0 and i2 eq 1 then do;
	    msg = cats('RTE', "RROR: EXPARM value (", exparm, ") from TRTGRPMAP must not have the 'Draft-' prefix");
	    put msg;
	    call symputx('g_abort', 1);
	end;
    run;

    *--------------------------------------------;
    *-- Verify values in EXPCTMAP;
    *--------------------------------------------;
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

    *-- 1. Verify EXPCTMAP field lengths and ensure no blank values;
    %let maptable=EXPCTMAP;
    %let fields=TRTC TRTD EXPCTYPC EXPCTYPD; *-- these are the fields in &maptable;
    %let lengths=120 200 55 200;	     *-- these are the field lengths in &maptable;

    %check_field_lengths_and_blanks(&maptable, &fields, &lengths);

    *-- 2a. Confirm all TRTC, TRTD pairs found in RANDALL1 are listed in EXPCTMAP;
    %local not_found_count3;
    proc sql;
    	create table &macroname._ck3 as
    	select distinct trtc, trtd
	  from rfmtdir.randall1 r
	 where not exists (select trtc, trtd
	 		    from &macroname._expctmap m
			   where r.trtc = m.trtc
			     and r.trtd = m.trtd);
    quit;

    %let not_found_count3 = %tu_nobs(&macroname._ck3);
    %if &not_found_count3 gt 0 %then %do;
	%put %str(RTE)RROR: &macroname: Some (&not_found_count3) RANDALL1 (TRTC, TRTD) pairs are not found in the EXPCTMAP reference spreadsheet;
	data _null_;
	    set &macroname._ck3;
	    msg = cats('RTE', 'RROR: (TRTC,TRTD) values (', trtc, ',', trtd, ') from RANDALL1 not found in EXPCTMAP');
	    put msg;
	run;
	%let g_abort=1;
    %end;

    *-- 2b. Confirm all TRTC, TRTD pairs found in EXPCTMAP are listed in RANDALL1;
    %local not_found_count3b;
    proc sql;
    	create table &macroname._ck3b as
    	select distinct trtc, trtd
	  from &macroname._expctmap m
	 where not exists (select trtc, trtd
	 		    from rfmtdir.randall1 r
			   where r.trtc = m.trtc
			     and r.trtd = m.trtd);
    quit;

    %let not_found_count3b = %tu_nobs(&macroname._ck3b);
    %if &not_found_count3b gt 0 %then %do;
	%put %str(RTE)RROR: &macroname: Some (&not_found_count3b) EXPCTMAP (TRTC, TRTD) pairs are not found in the RANDALL1 dataset;
	data _null_;
	    set &macroname._ck3b;
	    msg = cats('RTE', 'RROR: (TRTC,TRTD) values (', trtc, ',', trtd, ') from EXPCTMAP not found in RANDALL1');
	    put msg;
	run;
	%let g_abort=1;
    %end;

    *-- 3. Verify EXPCTYPC and EXPCTYPD against CTTYPMAP;
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

    %local not_found_count4;
    proc sql;
    	create table &macroname._ck4 as
	select distinct expctypc, expctypd
	  from &macroname._expctmap e
	 where not exists (select cttypc, cttypd
	 		     from &macroname._cttypmap c
			    where c.cttypc = e.expctypc
			      and c.cttypd = e.expctypd);
    quit;

    %let not_found_count4 = %tu_nobs(&macroname._ck4);
    %if &not_found_count4 gt 0 %then %do;
	%put %str(RTE)RROR: &macroname: Some (&not_found_count4) EXPCTMAP (EXPCTYPC, EXPCTYPD) pairs are not found in the CTTYPMAP reference spreadsheet;
	data _null_;
	    set &macroname._ck4;
	    msg = cats('RTE', 'RROR: (EXPCTYPC,EXPCTYPD) values (', expctypc, ',', expctypd, ') from EXPCTMAP not found in CTTYPMAP');
	    put msg;
	run;
	%let g_abort=1;
    %end;

    *-- 4. Verify CTTYPC and CTTYPD against EXPCTMAP;
    %local not_found_count5;
    proc sql;
    	create table &macroname._ck5 as
	select distinct cttypc, cttypd
	  from &macroname._cttypmap c
	 where not exists (select expctypc, expctypd
	 		     from &macroname._expctmap e
			    where c.cttypc = e.expctypc
			      and c.cttypd = e.expctypd);
    quit;

    %let not_found_count5 = %tu_nobs(&macroname._ck5);
    %if &not_found_count5 gt 0 %then %do;
	%put %str(RTE)RROR: &macroname: Some (&not_found_count5) CTTYPMAP (CTTYPC, CTTYPD) pairs are not found in the EXPCTMAP reference spreadsheet;
	data _null_;
	    set &macroname._ck5;
	    msg = cats('RTE', 'RROR: (CTTYPC,CTTYPD) values (', cttypc, ',', cttypd, ') from CTTYPMAP not found in EXPCTMAP');
	    put msg;
	run;
	%let g_abort=1;
    %end;

    *-- 5. Confirm all TRTD values consistently have "Draft-" prefix or not;
    %local draft_count2;
    proc sql noprint;
    	select count(*)
	  into :draft_count2
	  from &macroname._expctmap m
	 where trtd like 'Draft-%';
    quit;

    %let nobs_expctmap = %tu_nobs(&macroname._expctmap);
    %if &draft_count2 ne &nobs_expctmap and &draft_count2 ne 0 %then %do;
	%put %str(RTE)RROR: &macroname: Some (%left(&draft_count2)) but not all (&nobs_expctmap) EXPCTMAP TRTD values have the 'Draft-' prefix;
	data _null_;
	    set &macroname._expctmap;
	    if index(trtd, 'Draft-') ne 1 then do;
		msg = cats('RTE', "RROR: TRTD value (", trtd, ") from EXPCTMAP does not have the 'Draft-' prefix");
		put msg;
	    end;
	run;
	%let g_abort=1;
    %end;

    *-- 6. Confirm all EXPCTYPD values have "Draft-" prefix only if TRTD has it;
    data _null_;
	set &macroname._expctmap;
	i1 = index(trtd, 'Draft-');
	i2 = index(expctypd, 'Draft-');
	if i1 eq 1 and i2 eq 0 then do;
	    msg = cats('RTE', "RROR: EXPCTYPD value (", expctypd, ") from EXPCTMAP must have the 'Draft-' prefix");
	    put msg;
	    call symputx('g_abort', 1);
	end;
	else if i1 eq 0 and i2 eq 1 then do;
	    msg = cats('RTE', "RROR: EXPCTYPD value (", expctypd, ") from EXPCTMAP must not have the 'Draft-' prefix");
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
    / Generate EXPTRT dataset
    /------------------------------------------------------------------------*/
    *-- merge RANDALL1 and TRTGRPMAP into tmpexptrt1;
    proc sort data=rfmtdir.randall1;
    	by trtgrpc;
    run;

    proc sort data=&macroname._trtgrpmap;
    	by trtgrpc;
    run;

    data &macroname._tmpexptrt1;
    	merge rfmtdir.randall1 &macroname._trtgrpmap (drop=trtgrpd);
	by trtgrpc;
    run;

    *-- merge tmpexptrt1 and EXPCTMAP into tmpexptrt2;
    *-- DM2-this needs to be done using PROC SQL to get the cartesion product;
    proc sql;
    	create table &macroname._tmpexptrt2 as
	select t1.*
	     , e.expctypc
	     , e.expctypd
	  from &macroname._tmpexptrt1 t1
	  join &macroname._expctmap e on e.trtc = t1.trtc  /* DM2-cartesian product */
	  order by t1.randnum, t1.pernum, e.expctypc;
    quit;

    *-- copy tmpexptrt2 to EXPTRT;
    data rfmtdir.exptrt(label='Expected Treatment');
    	*-- define the data type and length for each EXPTRT variable;
	length RANDNUM 6;
	length STRATUM $ 200;
	length TRTGRPD $ 200;
	length TRTGRPC $ 120;
	length TRTD $ 200;
	length TRTC $ 120;
	length PERNUM 6.2;
	length SCHEDNUM 6;
	length SCHEDTX $ 200;
	length EXPARM $ 200;
	length EXPARMCD $ 20;
	length EXPCTYPC $ 55;
	length EXPCTYPD $ 200;
	label RANDNUM="Randomisation number"; *-- labels from EXPTRT dataset definition;
	label STRATUM="Randomization stratum";
	label TRTGRPD="Treatment Group Description";
	label TRTGRPC="Treatment Group Code";
	label TRTD="Treatment Description";
	label TRTC="Treatment Code";
	label PERNUM="Period Number";
	label SCHEDNUM="Schedule number";
	label SCHEDTX="Schedule description";
	label EXPARM="Expected ARM Description";
	label EXPARMCD="Expected Arm Code";
	label EXPCTYPC="Expected IP/Container Type Codes";
	label EXPCTYPD="Expected IP/Container Description";
    	set &macroname._tmpexptrt2; *-- copy records from tmpexptrt2 into EXPTRT;
    run;

    /* 
    / Tidy up
    /------------------------------------------------------------------------*/
    %tu_tidyup(rmdset=&macroname.:, glbmac=none);

%mend tc_exptrt;

