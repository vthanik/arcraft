/*----------------------------------------------------------------------------+
| Macro Name    : tu_usubjid.sas
|
| Macro Version : 1
|
| SAS version   : SAS v9.4
|
| Created By    : Daniel McDonald (dwm95161)
|
| Date          : May 2016
|
| Macro Purpose : Macro to create USUBJID temporary dataset
|
| Macro Design  : PROCEDURE STYLE
|
| Input Parameters :
|
| NAME			DESCRIPTION                             	DEFAULT
|
| DSETIN		The SDTM DM data set to process			rawdata.dm
|
| DSETINSUPP		The SDTM SUPPDM data set to process		rawdata.suppdm
|
| DSETOUT		Specifies the name of the output data set to	work.usubjid
|			be created
|
|---------------------------------------------------------------------------------------------------
|
| Output:   1. USUBJID dataset
|
| Global macro variables created: None
|
|
| Macros called :
| (@) tu_abort
| (@) tu_chknames
| (@) tu_putglobals
| (@) tr_putlocals
| (@) tu_tidyup
|
| Example:
|	%tu_usubjid(
|	    dsetin=rawdata.dm,
|	    dsetinsupp=rawdata.suppdm,
|	    dsetout=work.usubjid
|	    );
|
| **************************************************************************
| Change Log :
|
| Modified By :
| Date of Modification :
| New Version Number :
| Modification ID :
| Reason For Modification :
|
+----------------------------------------------------------------------------*/

%macro tu_usubjid(
    dsetin=rawdata.dm,		/* The SDTM DM data set to process */
    dsetinsupp=rawdata.suppdm,	/* The SDTM SUPPDM data set to process */
    dsetout=work.usubjid	/* Specifies the name of the output data set to be created */
);
    %local macroname;
    %let macroname=&sysmacroname;

    /*
    / Echo parameter values and global macro variables to the log.
    /------------------------------------------------------------------------*/
    %local MacroVersion;
    %let MacroVersion = 1;
    %include "&g_refdata/tr_putlocals.sas";
    %tu_putglobals(varsin=g_abort);

    /*
    / PARAMETER VALIDATION
    /------------------------------------------------------------------------*/
    %let dsetin		= %nrbquote(%upcase(&dsetin));
    %let dsetinsupp	= %nrbquote(%upcase(&dsetinsupp));
    %let dsetout	= %nrbquote(%upcase(&dsetout));

    /*
    / Check for required parameters.
    /------------------------------------------------------------------------*/

    %if &dsetin eq %then %do;
	%put %str(RTE)RROR: &macroname: The parameter DSETIN is required.;
	%let g_abort=1;
    %end;

    %if &dsetinsupp eq %then %do;
	%put %str(RTE)RROR: &macroname: The parameter DSETINSUPP is required.;
	%let g_abort=1;
    %end;

    %if &dsetout eq %then %do;
	%put %str(RTE)RROR: &macroname: The parameter DSETOUT is required.;
	%let g_abort=1;
    %end;

    *-- abort if required parameters are missing;
    %if &g_abort eq 1 %then %do;
	%tu_abort;
    %end;

    /*
    / Check for valid parameter values.
    /------------------------------------------------------------------------*/

    %if not %sysfunc(exist(&dsetin)) %then %do;
	%put %str(RTE)RROR: &macroname: The dataset DSETIN(=&dsetin) does not exist.;
	%let g_abort=1;
    %end;

    %if not %sysfunc(exist(&dsetinsupp)) %then %do;
	%put %str(RTE)RROR: &macroname: The dataset DSETINSUPP(=&dsetinsupp) does not exist.;
	%let g_abort=1;
    %end;

    /* Validating if DSETOUT is a valid dataset name and DSETOUT is not same as DSETIN or DSETINSUPP */
    %if %qupcase(&dsetout.) eq %qupcase(%scan(&dsetin, 1, %str(%() )) %then %do;
	%put %str(RTE)RROR: &macroname.: The Output dataset name is same as Input dataset name.;
	%let g_abort = 1;
    %end;
    %else %if %qupcase(&dsetout.) eq %qupcase(%scan(&dsetinsupp, 1, %str(%() )) %then %do;
	%put %str(RTE)RROR: &macroname.: The Output dataset name is same as Input supplemental dataset name.;
	%let g_abort = 1;
    %end;
    /* calling tu_chknames to validate name provided in DSETOUT parameter */
    %else %if %tu_chknames(&dsetout., DATA) ne %then %do;
	%put %str(RTE)RROR: &macroname.: Macro Parameter DSETOUT refers to dataset "&dsetout." which is not a valid dataset name.;
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
    / Generate USUBJID dataset
    /------------------------------------------------------------------------*/
    *-- Select distinct SUBJID, USUBJID pairs from the SDTM DM data set;
    proc sql;
    	create table &macroname._ds1 as
	select distinct upcase(dm.SUBJID) as SUBJIDC, dm.USUBJID, suppdm.QVAL
	  from &dsetin as dm
	  left join &dsetinsupp as suppdm on dm.usubjid = suppdm.usubjid
	   and upcase(dm.subjid) = 'MULTIPLE'
	   and upcase(suppdm.qnam) like 'SUBJID%'
	 order by subjidc, qval;
    quit;

    *-- copy ds1 to USUBJID;
    data &dsetout.(label='SUBJID to USUBJID Map');
	length SUBJID $ 10;
	length USUBJID $ 20;
	label SUBJID="Subject ID";
	label USUBJID="Unique Subject ID";
    	set &macroname._ds1; *-- copy records from ds1 into USUBJID;
	if SUBJIDC eq 'MULTIPLE' then do;
	    SUBJID=trim(left(QVAL));
	end;
	else do;
	    SUBJID=trim(left(SUBJIDC));
	end;
	drop SUBJIDC QVAL;
    run;

    proc sort data=&dsetout;
    	by subjid;
    run;

    /* 
    / Tidy up
    /------------------------------------------------------------------------*/
    %tu_tidyup(rmdset=&macroname._ds1:, glbmac=none);

%mend tu_usubjid;

