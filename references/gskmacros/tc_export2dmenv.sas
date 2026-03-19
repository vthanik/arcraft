/*----------------------------------------------------------------------------+
| Macro Name    : tc_export2dmenv.sas
|
| Macro Version : 1 Build 2
|
| SAS version   : SAS v9.4
|
| Created By    : Daniel McDonald (dwm95161)
|
| Date          : September 2016
|
| Macro Purpose : Macro to copy reference datasets and SDTM datasets from the AR environment (ARENV) to the DM environment (DMENV)
|
| Macro Design  : PROCEDURE STYLE
|
| Input Parameters :
|
| NAME			DESCRIPTION                             	DEFAULT
|
| REFDSETS		Specifies the names of datasets in refdata	EXPTRT CONTLST
|			to copy to dmdata (under dmenv)
|
| SDTMDSETS		Specifies the names of SDTM datasets to copy	DM EX SE PC PP
|			to raw (under dmenv)
|
|---------------------------------------------------------------------------------------------------
|
| Output:   1. Datasets copied to DMENV
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
|	%tc_export2dmenv(
|	    refdsets=EXPTRT CONTLST,
|	    sdtmdsets=DM EX SE PC PP
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
| 	RD_IT/AR_HARP_195808 Derect 575 - TC_EXPORT2DMENV tranfers data to wrong destination
|
| Modified By :
| Date of Modification :
| New Version Number :
| Modification ID :
| Reason For Modification :
|
+----------------------------------------------------------------------------*/

%macro tc_export2dmenv(
    refdsets=EXPTRT CONTLST,	/* Specifies the names of datasets in refdata to copy to dmdata (under dmenv) */
    sdtmdsets=DM EX SE PC PP	/* Specifies the names of SDTM datasets to copy to raw (under dmenv) */
);
    %local macroname;
    %let macroname=&sysmacroname;

    /*
    / Echo parameter values and global macro variables to the log.
    /------------------------------------------------------------------------*/
    %local MacroVersion;
    %let MacroVersion = 1 Build 2;
    %include "&g_refdata/tr_putlocals.sas";
    %tu_putglobals(varsin=g_dmdata g_rfmtdir g_sdtmdata g_abort);

    /*
    / PARAMETER VALIDATION
    /------------------------------------------------------------------------*/
    %let refdsets	= %nrbquote(%upcase(&refdsets));
    %let sdtmdsets	= %nrbquote(%upcase(&sdtmdsets));

    /*
    / Check for required parameters.
    /------------------------------------------------------------------------*/

    *-- This macro does not have required parameters;

    /*
    / Check for valid parameter values.
    /------------------------------------------------------------------------*/

    %if &refdsets ne %then %do;
	%let ref_invalid_names=%tu_chknames(&refdsets., DATA);
	%if &ref_invalid_names ne %then %do;
	    %put %str(RTE)RROR: &macroname.: Macro Parameter REFDSETS contains invalid dataset names: "&ref_invalid_names.";
	    %let g_abort = 1;
	%end;
    %end;

    %if &sdtmdsets ne %then %do;
	%let sdtm_invalid_names=%tu_chknames(&sdtmdsets., DATA);
	%if &sdtm_invalid_names ne %then %do;
	    %put %str(RTE)RROR: &macroname.: Macro Parameter SDTMDSETS contains invalid dataset names: "&sdtm_invalid_names.";
	    %let g_abort = 1;
	%end;
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
    / Copy Reference Datasets to DMENV/dmdata
    /------------------------------------------------------------------------*/
    *-- From: /arenv/arprod/cpd/study/re/refdata;
    *--   To: /dmenv/dmwork/cpd/study/re/dmdata;
    %let arenv=%scan(%bquote(&g_dmdata), 1, '/'); /*DM2*/
    %let dmenv=dmenv; /*DM2*/
    %if "&arenv" eq "arenv_test" %then %do; /*DM2*/
	%let dmenv=dmenv_test; /*DM2*/
    %end; /*DM2*/
    %let dmenv_dmdata=%sysfunc(tranwrd(&g_dmdata.,/&arenv./ar,/&dmenv./dm));  /*DM2*/
    %let dmenv_dmdata=%sysfunc(tranwrd(&dmenv_dmdata,/&dmenv./dmprod,/&dmenv./dmwork));  /*DM2*/
    %let numdsets=%sysfunc(countw(&refdsets,%str( )));
    %do dset_index=1 %to &numdsets;
	    %let dset=%lowcase(%scan(%bquote(&refdsets), &dset_index, ' '));
	    %let dsetfile=&g_rfmtdir./&dset..sas7bdat;
	    %if %sysfunc(fileexist(&dsetfile)) %then %do;
	    	%let cmd=cp -f &dsetfile. &dmenv_dmdata.;
		%sysexec %bquote(&cmd);
		%put %str(RTN)OTE: &macroname.: %upcase(&dset) copied from &g_rfmtdir to &dmenv_dmdata;
	    %end;
	    %else %do;
	    	%put %str(RTN)OTE: &macroname.: Reference dataset %upcase(&dset) (&dsetfile) was not found;
	    %end;
    %end;

    /* 
    / Copy SDTM Datasets to DMENV/raw
    /------------------------------------------------------------------------*/
    *-- From: /arenv/arprod/cpd/study/re/sdtm;
    *--   To: /dmenv/dmwork/cpd/study/re/raw;
    %let dmenv_raw=%sysfunc(tranwrd(%sysfunc(tranwrd(&g_sdtmdata,/sdtm,/raw)),/&arenv./ar,/&dmenv./dm));  /*DM2*/
    %let dmenv_raw=%sysfunc(tranwrd(&dmenv_raw,/&dmenv./dmprod,/&dmenv./dmwork));  /*DM2*/
    %let numdsets=%sysfunc(countw(&sdtmdsets,%str( )));
    %do dset_index=1 %to &numdsets;
	    %let dset=%lowcase(%scan(%bquote(&sdtmdsets), &dset_index, ' '));
	    %let dsetfile=&g_sdtmdata./&dset..sas7bdat;
	    %if %sysfunc(fileexist(&dsetfile)) %then %do;
	    	%let cmd=cp -f &dsetfile. &dmenv_raw.;
		%sysexec %bquote(&cmd);
		%put %str(RTN)OTE: &macroname.: %upcase(&dset) copied from &g_sdtmdata to &dmenv_raw;
	    %end;
	    %else %do;
	    	%put %str(RTN)OTE: &macroname.: SDTM dataset %upcase(&dset) (&dsetfile) was not found;
	    %end;
    %end;

    /* 
    / Tidy up - nothing to tidy up here
    /------------------------------------------------------------------------*/

%mend tc_export2dmenv;

