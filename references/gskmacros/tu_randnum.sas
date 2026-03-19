/*----------------------------------------------------------------------------+
| Macro Name    : tu_randnum.sas
|
| Macro Version : 1 Build 2
|
| SAS version   : SAS v9.4
|
| Created By    : Daniel McDonald (dwm95161)
|
| Date          : September 2016
|
| Macro Purpose : Macro to create RANDNUM working dataset
|
| Macro Design  : PROCEDURE STYLE
|
| Input Parameters :
|
| NAME			DESCRIPTION                             	DEFAULT
|
| DSETIN		The SDTM DS data set to process			rawdata.ds
|
| DSETINSUPP		The SDTM SUPPDS data set to process		rawdata.suppds
|
| DSETOUT		Specifies the name of the output data set to	work.randnum
|			be created
|
|---------------------------------------------------------------------------------------------------
|
| Output:   1. WORK.RANDNUM dataset
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
|	%tu_randnum(
|	    dsetin=rawdata.ds,
|	    dsetinsupp=rawdata.suppds,
|	    dsetout=work.randnum
|	    );
|
| **************************************************************************
| Change Log :
|
| Modified By : Daniel McDonald
| Date of Modification : 21-Sep-2016
| New Version Number : 01-002
| Modification ID : DM2
| Reason For Modification :
|	BDS/HARP_RT Defect 606 - IDVAR macro not resloved to show RTERROR: IDVAR in suppds2 is not well defined. Expected a single value
|	BDS/HARP_RT Defect 609 - There were no observations in randnum dataset (due to RANDOMISED)
|
| Modified By :
| Date of Modification :
| New Version Number :
| Modification ID :
| Reason For Modification :
|
+----------------------------------------------------------------------------*/

%macro tu_randnum(
    dsetin=rawdata.ds,		/* The SDTM DS data set to process */
    dsetinsupp=rawdata.suppds,	/* The SDTM SUPPDS data set to process */
    dsetout=work.randnum	/* Specifies the name of the output data set to be created */
);
    %local macroname;
    %let macroname=&sysmacroname;

    /*
    / Echo parameter values and global macro variables to the log.
    /------------------------------------------------------------------------*/
    %local MacroVersion;
    %let MacroVersion = 1 Build 2;
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
    / Generate RANDNUM dataset
    /------------------------------------------------------------------------*/
    *-- Determine the IDVAR join column between DS and SUPPDS for RANDNUM;
    proc sql noprint;
    	select distinct s.idvar
	  into :idvar separated by " " /*DM2-thanks to bb984435 for the fix*/
	  from &dsetinsupp s
	 where qnam='RANDNUM';
    quit;

    *-- verify that there is only one IDVAR value and error out otherwise;
    %if %sysfunc(countw(&idvar)) gt 1 %then %do; /*DM2-thanks to bb984435 for the fix*/
	%put %str(RTE)RROR: &macroname.: IDVAR in &dsetinsupp is not well defined. Expected a single value, but found: &idvar.;
	%let g_abort = 1;
	%tu_abort;
    %end;

    *-- Select records from &DSETIN where the DSDECOD variable has the value RANDOMIZED; /*DM2*/
    proc sql;
    	create table &dsetout as
	select distinct d.USUBJID, s.qval as RANDNUM, d.dsstdtc as RANDDT
	  from &dsetin d
	  join &dsetinsupp s
	    on s.usubjid=d.usubjid
	   and s.idvarval=btrim(both ' ' from put(d.&idvar,best.))
	 where s.qnam='RANDNUM'
	   and d.dsdecod='RANDOMIZED' /*DM2*/
	 order by USUBJID, RANDNUM, RANDDT;
    quit;

    /* 
    / Tidy up - nothing to tidy up here
    /------------------------------------------------------------------------*/

%mend tu_randnum;

