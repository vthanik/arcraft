/*----------------------------------------------------------------------------+
| Macro Name    : tu_dmunblnd.sas
|
| Macro Version : 1 Build 2
|
| SAS version   : SAS v9.4
|
| Created By    : Daniel McDonald (dwm95161)
|
| Date          : September 2016
|
| Macro Purpose : Macro to replace blinded treatment arm designations in the SDTM DM
|		  dataset to create the un-blinded SDTM DM dataset
|
| Macro Design  : PROCEDURE STYLE
|
| Input Parameters :
|
| NAME			DESCRIPTION                             	DEFAULT
|
| DSETIN                Specifies the name of the blinded SDTM DM	rawdata.dm
|			dataset
|
| DSETINEXPTRT		Specifies the reference EXPTRT dataset		rfmtdir.exptrt	
|			containing the un-blinding information from
|			RandAll NG
|
| DSETINRANDNUM		Specifies the temporary dataset relating	work.randnum
|			USUBJID to RANDNUM and RANDDT
|
| DSETINTA		Specifies the SDTM TA (trial arm) dataset	sdtmdata.ta
|
| DSETOUT               Specifies the name of the SDTM PC output	work.dm
|                       dataset to be created
|
|---------------------------------------------------------------------------------------------------
|
| Output:   1. WORK.DM dataset
|
| Global macro variables created: None
|
|
| Macros called :
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_abort
| (@) tu_chknames
| (@) tu_tidyup
|
| Example:
|	%tu_dmunblnd(
|	    dsetin=rawdata.dm,
|	    dsetinexptrt=rfmtdir.exptrt,
|	    dsetinrandnum=work.randnum,
|	    dsetinta=sdtmdata.ta,
|	    dsetout=work.dm
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
|	BDS/HARP_RT Defect 572 - ARMCD is not constructed correctly when subject has multiple randomisation numbers
|	BDS/HARP_RT Defect 574 - Output dataset name is not checked to see that it is different from the input
|
| Modified By :
| Date of Modification :
| New Version Number :
| Modification ID :
| Reason For Modification :
|
+----------------------------------------------------------------------------*/

%macro tu_dmunblnd(
    dsetin=rawdata.dm,			/* Specifies the name of the blinded SDTM DM dataset */
    dsetinexptrt=rfmtdir.exptrt,	/* Specifies the reference EXPTRT dataset containing the un-blinding information from RandAll NG */
    dsetinrandnum=work.randnum,		/* Specifies the temporary dataset relating USUBJID to RANDNUM and RANDDT */
    dsetinta=sdtmdata.ta,		/* Specifies the SDTM TA (trial arm) dataset */
    dsetout=work.dm			/* Specifies the name of the partially unblinded SDTM DM output dataset to be created */
);
    %local macroname;
    %let macroname=&sysmacroname;

    /*
    / Echo parameter values and global macro variables to the log.
    /------------------------------------------------------------------------*/
    %local MacroVersion;
    %let MacroVersion = 1 Build 2;
    %include "&g_refdata/tr_putlocals.sas";
    %tu_putglobals(varsin=g_debug);

    /*
    / PARAMETER VALIDATION
    /------------------------------------------------------------------------*/
    %let dsetin		= %nrbquote(&dsetin);
    %let dsetinexptrt	= %nrbquote(&dsetinexptrt);
    %let dsetinrandnum	= %nrbquote(&dsetinrandnum);
    %let dsetinta	= %nrbquote(&dsetinta);
    %let dsetout	= %nrbquote(&dsetout);

    /*
    / Check for required parameters.
    /------------------------------------------------------------------------*/

    %if &dsetin eq %then %do;
	%put %str(RTE)RROR: &macroname: The parameter DSETIN is required.;
	%let g_abort=1;
    %end;

    %if &dsetinexptrt eq %then %do;
	%put %str(RTE)RROR: &macroname: The parameter DSETINEXPTRT is required.;
	%let g_abort=1;
    %end;

    %if &dsetinrandnum eq %then %do;
	%put %str(RTE)RROR: &macroname: The parameter DSETINRANDNUM is required.;
	%let g_abort=1;
    %end;

    %if &dsetinta eq %then %do;
	%put %str(RTE)RROR: &macroname: The parameter DSETINTA is required.;
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
	%put %str(RTE)RROR: &macroname: The DSETIN dataset (&dsetin) does not exist;
	%let g_abort=1;
    %end;

    %if not %sysfunc(exist(&dsetinexptrt)) %then %do;
	%put %str(RTE)RROR: &macroname: The DSETINEXPTRT dataset (&dsetinexptrt) does not exist;
	%let g_abort=1;
    %end;

    %if not %sysfunc(exist(&dsetinrandnum)) %then %do;
	%put %str(RTE)RROR: &macroname: The DSETINRANDNUM dataset (&dsetinrandnum) does not exist;
	%let g_abort=1;
    %end;

    %if not %sysfunc(exist(&dsetinta)) %then %do;
	%put %str(RTE)RROR: &macroname: The DSETINTA dataset (&dsetinta) does not exist;
	%let g_abort=1;
    %end;

    *-- Validate if DSETOUT is a valid dataset name and DSETOUT is not same as DSETIN or other input dataset;
    %if %qupcase(&dsetout.) eq %qupcase(%scan(&dsetin, 1, %str(%() )) %then %do;/*DM2*/
	%put %str(RTE)RROR: &macroname.: The Output dataset name is same as Input dataset name.;
	%let g_abort = 1;
    %end;
    %else %if %qupcase(&dsetout.) eq %qupcase(%scan(&dsetinexptrt, 1, %str(%() )) %then %do;/*DM2*/
	%put %str(RTE)RROR: &macroname.: The Output dataset name is same as Input EXPTRT dataset name.;
	%let g_abort = 1;
    %end;
    %else %if %qupcase(&dsetout.) eq %qupcase(%scan(&dsetinrandnum, 1, %str(%() )) %then %do;/*DM2*/
	%put %str(RTE)RROR: &macroname.: The Output dataset name is same as Input RANDNUM dataset name.;
	%let g_abort = 1;
    %end;
    %else %if %qupcase(&dsetout.) eq %qupcase(%scan(&dsetinta, 1, %str(%() )) %then %do;/*DM2*/
	%put %str(RTE)RROR: &macroname.: The Output dataset name is same as Input TA dataset name.;
	%let g_abort = 1;
    %end;
    %else %if %nrbquote(%tu_chknames(&dsetout., data)) ne %then %do;
	%put %str(RTE)RROR: &macroname.: The parameter DSETOUT (&dsetout.) is not a valid SAS datatset name.;
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

    /* 
    / Generate unblinded SDTM DM dataset
    /------------------------------------------------------------------------*/
    /*
    For each unique subject id S in DM:
	For each randnum R of S ordered by RANDDT:
	    select distinct EXPARMCD from EXPTRT where R = EXPTRT.RANDNUM
	DM.ARMCD = concatenate distinct EXPARMCD in RANDDT order delimited by underscore
	DM.ARM = lookup description of arm in TA where ARMCD = TA.ARMCD
    */
    *-- Join DM to RANDNUM and EXPTRT;
    proc sql;
    	create table &macroname._ds1 as
	select distinct d.*
	     , r.RANDNUM
	     , r.RANDDT
	     , e.EXPARMCD
	  from &dsetin d
	  left join &dsetinrandnum r on d.usubjid = r.usubjid
	  left join &dsetinexptrt e on r.randnum = strip(put(e.randnum, best12.))
	  order by d.usubjid, r.randdt;
    quit;

    *-- Concatenate EXPARMCD in RANDDT order delimited by underscore;
    data &macroname._ds2;
    	do until (last.usubjid);
	    set &macroname._ds1;
	    by usubjid;
	    length CONCAT_ARMCD $120.;
	    if lengthn(CONCAT_ARMCD) gt 0 then do;
		CONCAT_ARMCD=catx('_', CONCAT_ARMCD, EXPARMCD); /*DM2-thanks to ss693934 for fix*/
	    end;
	    else do;
		CONCAT_ARMCD=EXPARMCD;
	    end;
	end;
	do until (last.usubjid);
	    set &macroname._ds1;
	    by usubjid;
	    output;
	end;
	*-- drop randomization variables here to avoid multiple observations during ARM description lookup;
	drop RANDNUM RANDDT EXPARMCD; /*DM2-thanks to ss693934 for fix*/
    run;

    *-- Look up ARM description in TA dataset;
    proc sql;
    	create table &macroname._ds3 as
	select distinct d2.*
	     , t.ARM as CONCAT_ARM
	  from &macroname._ds2 d2
	  left join &dsetinta t on d2.CONCAT_ARMCD = t.ARMCD;
    quit;

    *-- Output the unblinded DM;
    data &dsetout;
    	set &macroname._ds3;
	ARMCD=CONCAT_ARMCD;
	ARM=CONCAT_ARM;
	ACTARMCD='';
	ACTARM='';
	drop CONCAT_ARMCD CONCAT_ARM; /*DM2-thanks to ss693934 for fix*/
    run;

    /* 
    / Tidy up
    /------------------------------------------------------------------------*/
    %tu_tidyup(rmdset=&macroname._ds1 &macroname._ds2 &macroname._ds3:, glbmac=none);

%mend tu_dmunblnd;

