/*----------------------------------------------------------------------------+
| Macro Name    : tc_randall1.sas
|
| Macro Version : 2 Build 1
|
| SAS version   : SAS v9.4
|
| Created By    : Daniel McDonald (dwm95161)
|
| Date          : September 2016
|
| Macro Purpose : Macro to create RANDALL1 reference dataset
|
| Macro Design  : PROCEDURE STYLE
|
| Input Parameters :
|
| NAME			DESCRIPTION                             	DEFAULT
|
| TRTCSVIN		Specifies which treatment randomisation CSV	LATEST
|			file to convert in case multiple extraction
|			attempts have been performed.
|			Valid values:  LATEST or a file name
|
|---------------------------------------------------------------------------------------------------
|
| Output:   1. RANDALL1 dataset
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
|	%tc_randall1(
|	    trtcsvin=LATEST
|	    );
|
| **************************************************************************
| Change Log :
|
| Modified By : Daniel McDonald
| Date of Modification : 7-Sep-2016
| New Version Number : 01-002
| Modification ID : DM2
| Reason For Modification :
| 	BDS/HARP_RT Defect 568 - Resolution of LATEST for TRTCSVIN parameter is incorrect when
|				 refdata contains subdirectories with Treatment Data CSV files
|	RD_IT/AR_HARP_195808 Defect 544 - RANDALL1 contains truncated TRTGRPC and TRTGRPD variables
|
| Modified By : Anthony J Cooper
| Date of Modification : 29-Mar-2018
| New Version Number : 02-001
| Modification ID : AJC001
| Reason For Modification : Update TRTGRPC label to match Dataset Manager
|
+----------------------------------------------------------------------------*/

%macro tc_randall1(
    trtcsvin=LATEST		/* LATEST or the name of an existing file in the current reporting effort's refdata directory */
);
    %local macroname;
    %let macroname=&sysmacroname;

    /*
    / Echo parameter values and global macro variables to the log.
    /------------------------------------------------------------------------*/
    %local MacroVersion;
    %let MacroVersion = 2 Build 1;
    %include "&g_refdata/tr_putlocals.sas";
    %tu_putglobals(varsin=g_rfmtdir g_debug g_abort);

    /*
    / PARAMETER VALIDATION
    /------------------------------------------------------------------------*/
    %let trtcsvin=%nrbquote(&trtcsvin);

    /*
    / Check for required parameters.
    /------------------------------------------------------------------------*/

    %if &trtcsvin eq %then %do;
	%put %str(RTE)RROR: &macroname: The parameter TRTCSVIN is required.;
	%let g_abort=1;
    %end;

    *-- abort if required parameters missing;
    %if &g_abort eq 1 %then %do;
	%tu_abort;
    %end;

    *-- verify TRTCSVIN parameter;
    %local file_found;
    %if %upcase(%bquote(&trtcsvin)) eq LATEST %then %do;
	*-- find the latest file of either blindtype in the refdata folder of the reporting effort;
	*-- DM2-Interpretation of command line;
	*-- -type f	=> find files only, no directories; 
	*-- -maxdepth 1	=> do not search subdirectories;
	*-- -name ...	=> find files matching the name pattern;
	*-- -printf	=> print out file details in a user defined format;
	*-- %Ts		=> print the file timestamp;
	*-- \t		=> print a tab character;
	*-- %p		=> print the file path;
	*-- \n		=> print a newline character;
	*-- sort -nr	=> sort by the numerical timestamp in reverse order;
	*-- cut -f2	=> discard the timestamp and keep just the file path;
	*-- grep -v '_Error_' => discard paths with _Error_ in them;
	%local fmt;
	%let fmt=%nrstr(%Ts\t%p\n);  /*DM2*/
	filename lsrfdata pipe "find &g_rfmtdir -type f -maxdepth 1 -name \*_TreatmentData_\*.csv -printf '&fmt' | sort -nr | cut -f2 | grep -v '_Error_'";  /*DM2*/
	data _null_;
	    call symputx('file_found', 0); *-- set to 0 for No;
	    infile lsrfdata truncover obs=1; *-- read first obs only and truncate if value too long;
	    length filenm $ 256;
	    input filenm $ char256.;
	    call symputx('file_found', 1); *-- if got here there are obs so set to 1 for Yes;
	    *-- replace trtcsvin with file name of latest treatment data CSV file;
	    call symputx('trtcsvin', filenm); *-- set trtcsvin to the file path;
	    stop;
	run;

	%if &file_found eq 0 %then %do;
	    *-- if no file found, generate error and abort;
	    %put %str(RTE)RROR: &macroname: No treatment data CSV file was found in &g_rfmtdir;
	    %let g_abort=1;
	%end;
    %end;
    %else %if %sysfunc(fileexist(&g_rfmtdir/&trtcsvin)) eq 1 %then %do; *-- if file exists in refdata directory;
    	%let trtcsvin=&g_rfmtdir/&trtcsvin;
    %end;
    %else %do;
    	%put %str(RTE)RROR: &macroname: parameter TRTCSVIN must be LATEST or the name of a file in &g_rfmtdir;
	%let g_abort=1;
    %end;

    %put %str(RTN)OTE &macroname: refdata location is &g_rfmtdir;
    %put %str(RTN)OTE &macroname: trtcsvin resolves to &trtcsvin;

    *-- abort if parameter validation failed;
    %if &g_abort eq 1 %then %do;
	%tu_abort;
    %end;

    /*
    / Macro parameters have valid values if the program has
    / not terminated by this point.
    /------------------------------------------------------------------------*/

    /* 
    / Generate RANDALL1 dataset
    /------------------------------------------------------------------------*/
    *-- import treatment randomisation CSV file;
    /* to ensure correct data types, use modified data block generated from proc import
    proc import datafile="&trtcsvin"
	out=&macroname._trtrand
	dbms=csv
	replace;
	getnames=yes;
    run;
    */
    data &macroname._trtrand; /*DM2*/
	infile "&trtcsvin" delimiter = ',' MISSOVER DSD lrecl=32767 firstobs=2 ;
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

    *-- copy the treatment dataset to randall1 output dataset;
    data rfmtdir.randall1(label='Randomisation information');
    	*-- define the data type and length for each RANDALL1 variable;
	length RANDNUM 6;
	length STRATUM $ 200;
	length TRTGRPD $ 200;
	length TRTGRPC $ 120;
	length TRTD $ 200;
	length TRTC $ 120;
	length PERNUM 6.2;
	length SCHEDNUM 6;
	length SCHEDTX $ 200;
	label RANDNUM="Randomisation number"; *-- labels from RANDALL1 dataset definition;
	label STRATUM="Randomization stratum";
	label TRTGRPD="Treatment Group Description";
	label TRTGRPC="Treatment Group Code"; /* AJC001 - update label */
	label TRTD="Treatment Description";
	label TRTC="Treatment Code";
	label PERNUM="Period Number";
	label SCHEDNUM="Schedule number";
	label SCHEDTX="Schedule description";
    	set &macroname._trtrand; *-- copy records from TRTRAND into RANDALL1;
    run;

    /* 
    / Remove treatment randomisation CSV files
    /------------------------------------------------------------------------*/
    filename delcsv pipe "ls -tr1 &g_rfmtdir/*.csv | grep '_TreatmentData_'"; /*DM2*/
    %if &g_debug gt 0 %then %do;
    	%put %str(RTN)OTE: &macroname: deleting treatment randomisation CSV files;
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

    /* 
    / Tidy up
    /------------------------------------------------------------------------*/
    %tu_tidyup(rmdset=&macroname.:, glbmac=none);

%mend tc_randall1;

