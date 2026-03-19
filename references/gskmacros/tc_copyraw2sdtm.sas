/*----------------------------------------------------------------------------+
| Macro Name    : tc_copyraw2sdtm.sas
|
| Macro Version : 1 Build 2
|
| SAS version   : SAS v9.4
|
| Created By    : Daniel McDonald (dwm95161)
|
| Date          : September 2016
|
| Macro Purpose : Macro to copy SDTM datasets from the rawdata directory where
|		  they are imported by HARP from DMENV into the sdtm directory
|
| Macro Design  : PROCEDURE STYLE
|
| Input Parameters :
|
| NAME			DESCRIPTION                             	DEFAULT
|
| EXCLUDEDSETS		Specifies the names of datasets to exclude	DM EX SE PC
|			from the copy process
|
|---------------------------------------------------------------------------------------------------
|
| Output:   1. Datasets copied to sdtm directory
|
| Global macro variables created: None
|
|
| Macros called :
| (@) tu_putglobals
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_chknames
|
| Example:
|	%tc_copyraw2sdtm(
|	    excludedsets=DM EX SE PC
|	    );
|
| **************************************************************************
| Change Log :
|
| Modified By : Daniel McDonald
| Date of Modification : 29-Sep-2016
| New Version Number : 01-002
| Modification ID : DM2
| Reason For Modification :
| 	BDS/HARP_RT Defect 588 - File copy does not preserve timestamp of the original file
|	BDS/HARP_RT Defect 613 - Log has RTNOTE stating dataset was copied when it was not actually copied
|	BDS/HARP_RT Defect 635 - excludes dataset when name is a substring of an excluded dataset name
|
| Modified By :
| Date of Modification :
| New Version Number :
| Modification ID :
| Reason For Modification :
|
+----------------------------------------------------------------------------*/

%macro tc_copyraw2sdtm(
    excludedsets=DM EX SE PC	/* Specifies the names of datasets to exclude from the copy process */
);
    %local macroname;
    %let macroname=&sysmacroname;

    /*
    / Echo parameter values and global macro variables to the log.
    /------------------------------------------------------------------------*/
    %local MacroVersion;
    %let MacroVersion = 1 Build 2;
    %include "&g_refdata/tr_putlocals.sas";
    %tu_putglobals(varsin=g_rawdata g_sdtmdata g_abort);

    /*
    / PARAMETER VALIDATION
    /------------------------------------------------------------------------*/
    %let excludedsets	= %nrbquote(%upcase(&excludedsets));

    /*
    / Check for required parameters.
    /------------------------------------------------------------------------*/

    *-- This macro does not have required parameters;

    /*
    / Check for valid parameter values.
    /------------------------------------------------------------------------*/

    %let excl_invalid_names=%tu_chknames(&excludedsets., DATA);
    %if &excl_invalid_names ne %then %do;
	%put %str(RTE)RROR: &macroname.: Macro Parameter EXCLUDEDSETS contains invalid dataset names: "&excl_invalid_names.";
	%let g_abort = 1;
    %end;

    *-- abort if parameter validation failed;
    %if &g_abort eq 1 %then %do;
	%tu_abort;
    %end;

    /*
    / Macro parameters have valid values if the program has
    / not terminated by this point.
    /------------------------------------------------------------------------*/

    /* 
    / Copy Datasets from rawdata to sdtm
    /------------------------------------------------------------------------*/
    *-- From: /arenv/arprod/cpd/study/re/rawdata;
    *--   To: /arenv/arprod/cpd/study/re/sdtm;

    *-- 1. Get a list of datasets to copy;
    %let copydsets=;
    filename dirlist pipe "ls -1 &g_rawdata.";
    data _null_;
	length dset $32;
	length fname $256;
	length dsets $32767;
	retain dsets ' ';
	infile dirlist length=reclen end=eof;
	input fname $varying256. reclen;
	dset = substr(fname, 1, index(fname, ".") - 1);
	if substr(fname, index(fname, ".")) eq ".sas7bdat" then do;
	    dsets = catx(' ', dsets, dset);
	end;
	if eof then call symputx('copydsets', dsets);
    run;

    %put %str(RTN)OTE: &macroname.: Found datasets: &copydsets;

    *-- 2. Copy the datasets which are not excluded;
    %let numdsets=%sysfunc(countw("&copydsets",%str( )));
    %do dset_index=1 %to &numdsets;
	    %let dset=%lowcase(%scan(%bquote(&copydsets), &dset_index, ' '));
	    %let dsetfile=&g_rawdata./&dset..sas7bdat;
	    %if %sysfunc(fileexist(&dsetfile)) and %sysfunc(indexw("&excludedsets", %upcase(&dset), " ")) eq 0 %then %do; /*DM2*/
	    	%let cmd=cp -u --preserve=timestamps &dsetfile. &g_sdtmdata.; *-- -u means update if source is newer; /*DM2*/
		%put %str(RTN)OTE: &macroname.: Attempting to copy %upcase(&dset) from &g_rawdata to &g_sdtmdata; /*DM2*/
		%sysexec %bquote(&cmd);
	    %end;
	    %else %do;
	    	%put %str(RTN)OTE: &macroname.: Skipping excluded dataset %upcase(&dset);
	    %end;
    %end;

    /* 
    / Tidy up - nothing to tidy up here
    /------------------------------------------------------------------------*/

%mend tc_copyraw2sdtm;

