/*----------------------------------------------------------------------------+
| Macro Name    : tc_dsetcompare.sas
|
| Macro Version : 2 Build 1
|
| SAS version   : SAS v9.4
|
| Created By    : Daniel McDonald (dwm95161)
|
| Date          : September 2016
|
| Macro Purpose : Macro to compare SDTM datasets for expected and unexpected differences
|
| Macro Design  : PROCEDURE STYLE
|
| Input Parameters :
|
| NAME			DESCRIPTION                             	DEFAULT
|
| DSETNAME1		Specifies the name of a dataset found in both	dm
|			rawdata (blinded) and sdtm (unblinded)
|
| VARDIFFS1		Specifies the variables which are allowed to	ARMCD ARM ACTARMCD ACTARM
|			differ between the datasets for DSETNAME1
|
| SORTVARS1		Variables to sort by prior to comparison	USUBJID
|
| DSETNAME2		Specifies the name of a dataset found in both	ex
|			rawdata (blinded) and sdtm (unblinded)
|
| VARDIFFS2		Specifies the variables which are allowed to	EXTRT EXDOSE EXDOSU EXDOSFRM EXDOSTXT
|			differ between the datasets for DSETNAME2
|
| SORTVARS2		Variables to sort by prior to comparison	USUBJID EXSEQ
|
| DSETNAME3		Specifies the name of a dataset found in both	se
|			rawdata (blinded) and sdtm (unblinded)
|
| VARDIFFS3		Specifies the variables which are allowed to	ETCD ELEMENT
|			differ between the datasets for DSETNAME3
|
| SORTVARS3		Variables to sort by prior to comparison	USUBJID SESEQ
|
| DSETNAME4		Specifies the name of a dataset found in both	pc
|			rawdata (blinded) and sdtm (unblinded)
|
| VARDIFFS4		Specifies the variables which are allowed to	PCORRES PCORRESU PCSTRESC PCSTRESN PCSTRESU
|			differ between the datasets for DSETNAME4	PCSTAT PCREASND
|
| SORTVARS4		Variables to sort by prior to comparison	USUBJID PCSEQ
|
| DSETNAME5		Specifies the name of a dataset found in both	[blank]
|			rawdata (blinded) and sdtm (unblinded)
|
| VARDIFFS5		Specifies the variables which are allowed to	[blank]
|			differ between the datasets for DSETNAME5
|
| SORTVARS5		Variables to sort by prior to comparison	[blank]
|
|---------------------------------------------------------------------------------------------------
|
| Output:   1. List file containing dataset comparison report for up to 5 datasets
|	       indicated by the parameters
|
| Global macro variables created: None
|
|
| Macros called :
| (@) tu_putglobals
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_chkvarsexist
| (@) tu_tidyup
|
| Example:
|	%tc_dsetcompare(
|	    dsetname1=dm,
|	    vardiffs1=ARMCD ARM ACTARMCD ACTARM,
|	    sortvars1=USUBJID,
|	    dsetname2=ex,
|	    vardiffs2=EXTRT EXDOSE EXDOSU EXDOSFRM EXDOSTXT,
|	    sortvars2=USUBJID EXSEQ,
|	    dsetname3=se,
|	    vardiffs3=ETCD ELEMENT,
|	    sortvars3=USUBJID SESEQ,
|	    dsetname4=pc,
|	    vardiffs4=PCORRES PCORRESU PCSTRESC PCSTRESN PCSTRESU PCSTAT PCREASND,
|	    sortvars4=USUBJID PCSEQ,
|	    dsetname5=,
|	    vardiffs5=,
|	    sortvars5=
|	    );
|
| **************************************************************************
| Change Log :
|
| Modified By : Daniel McDonald
| Date of Modification : 16-Sep-2016
| New Version Number : 01-002
| Modification ID : DM2
| Reason For Modification :
|	BDS/HARP_RT Defect 623 - %End statement missing ';'
|	BDS/HARP_RT Defect 624 - Macro giving error when running second time interactively
|	BDS/HARP_RT Defect 625 - Change comment in code at line number 337
|	BDS/HARP_RT Defect 626 - Add more descriptive comment about when RTERRORS generated
|	BDS/HARP_RT Defect 627 - Add descriptive comment to explain why 'include_value_diffyn' is set to 'n' .
|
| Modified By : Chau Tran
| Date of Modification : 27-Sep-1017
| New Version Number : 02
| Modification ID : CT003
| Reason For Modification : Check scenario where PCSTAT, PCREASND absence from unblinded PC.
|                           Check scenario where SEUPDES variable and UNPLAN records added to unblinded SE.
|
| Modified By : Anthony J Cooper
| Date of Modification : 30-APR-2018
| New Version Number : 02-001
| Modification ID : AJC001
| Reason For Modification : Set macro version to "2 build 1" in the header and
|                           MacroVersion local macro variable ready for release.
|
+----------------------------------------------------------------------------*/

%macro tc_dsetcompare(
    dsetname1=dm,				/* Specifies the name of a dataset found in both rawdata (blinded) and sdtm (unblinded) */
    vardiffs1=ARMCD ARM ACTARMCD ACTARM,	/* Specifies the variables which are allowed to differ between the datasets for DSETNAME1 */
    sortvars1=USUBJID,				/* Variables to sort by prior to comparison 1 */
    dsetname2=ex,				/* Specifies the name of a dataset found in both rawdata (blinded) and sdtm (unblinded) */
    vardiffs2=EXTRT EXDOSE EXDOSU EXDOSFRM EXDOSTXT, /* Specifies the variables which are allowed to differ between the datasets for DSETNAME2 */
    sortvars2=USUBJID EXSEQ,			/* Variables to sort by prior to comparison 2 */
    dsetname3=se,				/* Specifies the name of a dataset found in both rawdata (blinded) and sdtm (unblinded) */
    vardiffs3=ETCD ELEMENT,			/* Specifies the variables which are allowed to differ between the datasets for DSETNAME3 */
    sortvars3=USUBJID SESEQ,			/* Variables to sort by prior to comparison 3 */
    dsetname4=pc,				/* Specifies the name of a dataset found in both rawdata (blinded) and sdtm (unblinded) */
    vardiffs4=PCORRES PCORRESU PCSTRESC PCSTRESN PCSTRESU PCSTAT PCREASND,	/* Specifies the variables which are allowed to differ between the datasets for DSETNAME4 */
    sortvars4=USUBJID PCSEQ,			/* Variables to sort by prior to comparison 4 */
    dsetname5=,					/* Specifies the name of a dataset found in both rawdata (blinded) and sdtm (unblinded) */
    vardiffs5=,					/* Specifies the variables which are allowed to differ between the datasets for DSETNAME5 */
    sortvars5=					/* Variables to sort by prior to comparison 5 */
);
    %local macroname;
    %let macroname=&sysmacroname;

    /*
    / Echo parameter values and global macro variables to the log.
    /------------------------------------------------------------------------*/
    %local MacroVersion;
    %let MacroVersion = 2 Build 1;
    %include "&g_refdata/tr_putlocals.sas";
    %tu_putglobals(varsin=g_abort);

    /*
    / PARAMETER VALIDATION
    /------------------------------------------------------------------------*/
    %let dsetname1	= %upcase(%nrbquote(&dsetname1));
    %let vardiffs1	= %upcase(%nrbquote(&vardiffs1));
    %let sortvars1	= %upcase(%nrbquote(&sortvars1));
    %let dsetname2	= %upcase(%nrbquote(&dsetname2));
    %let vardiffs2	= %upcase(%nrbquote(&vardiffs2));
    %let sortvars2	= %upcase(%nrbquote(&sortvars2));
    %let dsetname3	= %upcase(%nrbquote(&dsetname3));
    %let vardiffs3	= %upcase(%nrbquote(&vardiffs3));
    %let sortvars3	= %upcase(%nrbquote(&sortvars3));
    %let dsetname4	= %upcase(%nrbquote(&dsetname4));
    %let vardiffs4	= %upcase(%nrbquote(&vardiffs4));
    %let sortvars4	= %upcase(%nrbquote(&sortvars4));
    %let dsetname5	= %upcase(%nrbquote(&dsetname5));
    %let vardiffs5	= %upcase(%nrbquote(&vardiffs5));
    %let sortvars5	= %upcase(%nrbquote(&sortvars5));

    /*
    / Check for required parameters.
    /------------------------------------------------------------------------*/

    *-- All parameters are optional;

    /*
    / Check for valid parameter values.
    /------------------------------------------------------------------------*/

    %do i=1 %to 5;
	%if &&dsetname&i ne %then %do;
	    %if not %sysfunc(exist(rawdata.&&dsetname&i)) %then %do;
		%put %str(RTE)RROR: &macroname: The dataset DSETNAME&i(=&&dsetname&i) does not exist in &g_rawdata;
		%let g_abort=1;
	    %end;
	    %else %do;
		%let missingvars&i=%tu_chkvarsexist(rawdata.&&dsetname&i, &&vardiffs&i);
		%if &&missingvars&i ne %then %do;
		    %put %str(RTE)RROR: &macroname: The dataset (rawdata.&&dsetname&i) is missing variables (&&missingvars&i) referenced in VARDIFFS&i(=&&vardiffs&i);
		    %let g_abort=1;
		%end;
		%let missingvars&i=%tu_chkvarsexist(rawdata.&&dsetname&i, &&sortvars&i);
		%if &&missingvars&i ne %then %do;
		    %put %str(RTE)RROR: &macroname: The dataset (rawdata.&&dsetname&i) is missing variables (&&missingvars&i) referenced in SORTVARS&i(=&&sortvars&i);
		    %let g_abort=1;
		%end;
	    %end;
	    %if not %sysfunc(exist(sdtmdata.&&dsetname&i)) %then %do;
		%put %str(RTE)RROR: &macroname: The dataset DSETNAME&i(=&&dsetname&i) does not exist in &g_sdtmdata;
		%let g_abort=1;
	    %end;
	%end;

	%let where&i._in=;
	%let where&i._notin=;
    %end;
	%let subjects_unplan=;

    *-- abort if parameter validation failed;
    %if &g_abort eq 1 %then %do;
	%tu_abort;
    %end;

    /*
    / Check that the same variables are present in both datasets.
    /------------------------------------------------------------------------*/

    %do i=1 %to 5;
	%if &&dsetname&i ne %then %do;
	    *-- get the variables in the rawdata dataset;
	    proc contents data=rawdata.&&dsetname&i
	    	out=&macroname._rawvars&i(keep=varnum name)
		order=varnum
		noprint;
	    run;
	    proc sql noprint;
		select name into :rawvars&i separated by ' ' from &macroname._rawvars&i;
	    quit;

	    *-- get the variables in the sdtm dataset;
	    proc contents data=sdtmdata.&&dsetname&i
	    	out=&macroname._sdtmvars&i(keep=varnum name)
		order=varnum
		noprint;
	    run;
	    proc sql noprint;
		select name into :sdtmvars&i separated by ' ' from &macroname._sdtmvars&i;
	    quit;

		/* Check if number of variables in blinded PC and unblinded PC don't match */
		%if "&&rawvars&i" ne "&&sdtmvars&i" and "&&dsetname&i"="PC" %then %do;

			/* Check for PCREASND which can potentially be dropped in PC unblind */
		    %if %index(&&rawvars&i,PCREASND) %then %do;                
                data _null_;
                  call symput("rawvars&i",compbl(tranwrd("&&rawvars&i","PCREASND"," ")));
                run;
				/* Drop row from temp dataset blinded */
				data &macroname._rawvars&i;
				  set &macroname._rawvars&i;
				  where upcase(name) ne 'PCREASND';
				run;
			%end;

			/* Check for PCSTAT which can potentially be dropped in PC unblind */
		    %if %index(&&rawvars&i,PCSTAT) %then %do;                
                data _null_;
                  call symput("rawvars&i",compbl(tranwrd("&&rawvars&i","PCSTAT"," ")));
                run;
				/* Drop row from temp dataset blinded */
				data &macroname._rawvars&i;
				  set &macroname._rawvars&i;
				  where upcase(name) ne 'PCSTAT';
				run;			
			%end;
		%end;

		/* Check if number of variables in blinded SE and unblinded SE don't match                  *
		 * In the case where Unblind has UNPLAN Treatement. Unblind SE will have additional records */			
		%if "&&rawvars&i" ne "&&sdtmvars&i" and "&&dsetname&i"="SE" %then %do;
		    %if %index(&&sdtmvars&i,SEUPDES) %then %do;                
                data _null_;
                  call symput("sdtmvars&i",compbl(tranwrd("&&sdtmvars&i","SEUPDES"," ")));
                run;
				/* Drop row from temp dataset unblinded */
				data &macroname._sdtmvars&i;
				  set &macroname._sdtmvars&i;
				  where upcase(name) ne 'SEUPDES';
				run;		

				/* Subjects has UNPLAN Treatment */
				proc sql noprint;
  				  select distinct "'"||strip(usubjid)||"'" into :subjects_unplan separated by ' ' 
                  from sdtmdata.&&dsetname&i 
                  where  ETCD eq 'UNPLAN';
				quit;

				/* Build where clause for later use */
				%let where&i._notin=%str( where usubjid not in (&subjects_unplan););
				%let where&i._in=%str( where usubjid in (&subjects_unplan););

				data _null_;
		    	  set sdtmdata.&&dsetname&i;
				  where ETCD eq 'UNPLAN';
		    	  put "RTN" "OTE: &macroname: USUBJID=" usubjid "ETCD=" etcd "(UNPLAN records was found in unblinded sdtmdata.&&dsetname&i..)";
				run;
			%end;
		%end;

	    *-- report errors for differences;
	    %if "&&rawvars&i" ne "&&sdtmvars&i" %then %do;
	    	proc sql;
		    create table &macroname._rawdiffs&i as
		    select r.name
		      from &macroname._rawvars&i r
		     where not exists (select s.name from &macroname._sdtmvars&i s
		     			where s.name = r.name);
		quit;
		data _null_;
		    set &macroname._rawdiffs&i;
		    msg = cats('RTE', "RROR: &macroname: Variable (", name, ") from rawdata.&&dsetname&i. was not found in sdtmdata.&&dsetname&i..");
		    put msg;
		    call symputx('g_abort', 1);
		run;
	    	proc sql;
		    create table &macroname._sdtmdiffs&i as
		    select s.name
		      from &macroname._sdtmvars&i s
		     where not exists (select r.name from &macroname._rawvars&i r
		     			where r.name = s.name);
		quit;
		data _null_;
		    set &macroname._sdtmdiffs&i;
		    msg = cats('RTE', "RROR: &macroname: Variable (", name, ") from sdtmdata.&&dsetname&i. was not found in rawdata.&&dsetname&i..");
		    put msg;
		    call symputx('g_abort', 1);
		run;
	    %end;
	%end;
    %end; /*DM2*/

    *-- abort if parameter validation failed;
    %if &g_abort eq 1 %then %do;
	%tu_abort;
    %end;

    /*
    / Macro parameters have valid values if the program has
    / not terminated by this point.
    /------------------------------------------------------------------------*/

    /*
    / This code provides an ERROR/WARNING based on the SYSINFO from PROC COMPARE
    / See http://support.sas.com/documentation/cdl/en/proc/61895/HTML/default/viewer.htm#a000146743.htm
    / NOTE: (DM2)
    / 	Not all of the errors included in %translate_proc_compare_result below
    /	can be generated.  The full list of possible errors is included for
    /	consistency with the PROC COMPARE documentation and for completeness.
    /	LENGTH, VALUE - excluded because these changes are allowed
    /	BASEVAR, COMPVAR - earlier validation check prevents seeing these errors
    /	BASEBY, COMPBY, BYVAR - not seen because sorting is overridden before comparison
    /------------------------------------------------------------------------*/
    %macro translate_proc_compare_result(
	macroname,			/* name of parent macro to include in output messages */
	rc=&sysinfo,		/* proc compare result code to translate */
	include_value_diffyn='y'	/* flag to include value and length differences (16 + 4096) */
    );
	data _null_;
	    %if &rc eq %then %do;
		biff='1...............'b;
	    %end;
	    %else %do;
		biff=&rc;
	    %end;
	    if biff = '1'b then do; put 'RTE' 'RROR: ' "&macroname: DSLABEL: Data set labels differ"; end;
	    if biff = '1.'b then do; put 'RTE' 'RROR: ' "&macroname: DSTYPE: Data set types differ"; end;
	    if biff = '1..'b then do; put 'RTE' 'RROR: ' "&macroname: INFORMAT: Variable has different informat"; end;
	    if biff = '1...'b then do; put 'RTE' 'RROR: ' "&macroname: FORMAT: Variable has different format"; end;
	    %if "&include_value_diffyn" eq 'y' %then %do;
		if biff = '1....'b then do; put 'RTE' 'RROR: ' "&macroname: LENGTH: Variable has different length"; end;
	    %end;
	    if biff = '1.....'b then do; put 'RTE' 'RROR: ' "&macroname: LABEL: Variable has different label"; end;
	    if biff = '1......'b then do; put 'RTE' 'RROR: ' "&macroname: BASEOBS: Base data set has observation not in comparison"; end;
	    if biff = '1.......'b then do; put 'RTE' 'RROR: ' "&macroname: COMPOBS: Comparison data set has observation not in base"; end;
	    if biff = '1........'b then do; put 'RTE' 'RROR: ' "&macroname: BASEBY: Base data set has BY group not in comparison"; end;
	    if biff = '1.........'b then do; put 'RTE' 'RROR: ' "&macroname: COMPBY: Comparison data set has BY group not in base"; end;
	    if biff = '1..........'b then do; put 'RTE' 'RROR: ' "&macroname: BASEVAR: Base data set has variable not in comparison"; end;
	    if biff = '1...........'b then do; put 'RTE' 'RROR: ' "&macroname: COMPVAR: Comparison data set has variable not in base"; end;
	    %if "&include_value_diffyn" eq 'y' %then %do;
		if biff = '1............'b then do; put 'RTE' 'RROR: ' "&macroname: VALUE: A value comparison was unequal"; end;
	    %end;
	    if biff = '1.............'b then do; put 'RTE' 'RROR: ' "&macroname: TYPE: Conflicting variable types"; end;
	    if biff = '1..............'b then do; put 'RTE' 'RROR: ' "&macroname: BYVAR: BY variables do not match"; end;
	    if biff = '1...............'b then do; put 'RTE' 'RROR: ' "&macroname: comparison not done"; end;
	run;
    %mend translate_proc_compare_result;

    /* 
    / Compare datasets
    /------------------------------------------------------------------------*/
    *-- repeat for all 5 datasets;
    %do i=1 %to 5;
	%if &&dsetname&i ne %then %do;
	    footnote;  *-- cancel prior footnote;
	    *-- sort the rawdata version;
	    proc sort data=rawdata.&&dsetname&i out=&macroname._RAW_&&dsetname&i.._SORTED&i (keep=&&rawvars&i);
		by &&sortvars&i;  &&where&i._notin;
	    run;  %put here7; %put &&where&i._notin;
	    *-- sort the sdtmdata version, add where clause to exclude UNPLAN record in SE if applicable;
	    proc sort data=sdtmdata.&&dsetname&i out=&macroname._SDTM_&&dsetname&i.._SORTED&i (keep=&&sdtmvars&i);
		by &&sortvars&i; &&where&i._notin;
	    run;	
	    *-- get a list of all the variables except the variables which allow differences;
	    proc contents data=rawdata.&&dsetname&i (drop=&&vardiffs&i)
		out=&macroname._vars&i(keep=varnum name)
		order=varnum noprint;
	    run;
	    proc sql noprint;
		select name into :orderedvars&i separated by ' '
		  from &macroname._vars&i;
	    quit;
	    *-- compare the datasets;
	    proc compare
		base=&macroname._RAW_&&dsetname&i.._SORTED&i
		compare=&macroname._SDTM_&&dsetname&i.._SORTED&i
		out=&macroname._compare&i outdif
		method=exact;  /*id &&sortvars&i;*/
		title "Comparison of RAWDATA.&&dsetname&i to SDTMDATA.&&dsetname&i";
		footnote justify=left "If expected differences are not shown, verify that your dataset modification (e.g., unblinding script) worked as expected.";
	    run;
	    *-- Check for differences, such as extra variables;
	    *-- 0       0000X   No differences;
	    *-- 16	0010X	Variable has different length;
	    *--	4096	1000X	A value comparison was unequal;
	    %let rc=&sysinfo;
	    %if &rc ne 0 and &rc ne 4096 and &rc ne 16 and &rc ne 4112 %then %do; *-- not an error if only values or lengths differ; /*DM2*/
		%put %str(RTE)RROR: &macroname: Differences found in &&dsetname&i dataset (code=&rc). See list file for details.;
		*-- translate proc compare output to log messages;
		*-- setting include_value_diffyn to n avoids reporting allowed value or length differences; /*DM2*/
		%translate_proc_compare_result(&macroname, rc=&rc, include_value_diffyn='n');
	    %end;
	    *-- Check for value differences in columns other than where diffs are allowed;
	    %let dsid&i=%sysfunc(open(&macroname._compare&i));
	    %let nvars=%sysfunc(countw("&&orderedvars&i",%str( )));
	    %do j=1 %to &nvars;
		%let var=%upcase(%scan(%bquote(&&orderedvars&i), &j, ' '));
		%let ftype=%sysfunc(vartype(&&dsid&i, %sysfunc(varnum(&&dsid&i, &var))));
		proc sql noprint;
		    select count(*) into :diffcount&i._&j
		      from &macroname._compare&i c
		    %if &ftype eq N %then %do;
			 where &var > 0;
		    %end;
		    %else %do;
			 where index(&var, 'X') > 0;
		    %end;
		quit;
		%if &&diffcount&i._&j gt 0 %then %do;
		    %put %str(RTE)RROR: &macroname: Unexpected differences found in &&dsetname&i dataset variable &var;
		%end;
	    %end;
	    %let rc=%sysfunc(close(&&dsid&i)); /*DM2*/

		* Staghe 2 compare, reserve from checking SE with UNPLAN treatment records;
		* No deciphering on message from Proc Compare results;
		%if &&dsetname&i=SE and &subjects_unplan ne %then %do;		  
		    *-- sort the rawdata version;
		    proc sort data=rawdata.&&dsetname&i out=&macroname._RAW_&&dsetname&i.._SORTED&i;
			by &&sortvars&i; &&where&i._in;
		    run;  %put here7; 
		    *-- sort the sdtmdata version, add where clause to exclude UNPLAN record in SE if applicable;
		    proc sort data=sdtmdata.&&dsetname&i out=&macroname._SDTM_&&dsetname&i.._SORTED&i;
			by &&sortvars&i; &&where&i._in;
	    	run;	
		    *-- get a list of all the variables except the variables which allow differences;
		    proc contents data=rawdata.&&dsetname&i (drop=&&vardiffs&i)
			out=&macroname._vars&i(keep=varnum name)
			order=varnum noprint;
		    run;
	    	proc sql noprint;
			select name into :orderedvars&i separated by ' '
		  		from &macroname._vars&i;
		    quit;
		    *-- compare the datasets;
	    	proc compare
			base=&macroname._RAW_&&dsetname&i.._SORTED&i
			compare=&macroname._SDTM_&&dsetname&i.._SORTED&i
			out=&macroname._compare&i outdif
			method=exact; 
			title1 "Comparison of RAWDATA.&&dsetname&i to SDTMDATA.&&dsetname&i";
			title2 "************************************************************************************************";
			title3 "Requires manual review on these following subjects have UNPLAN treatments.";
			title4 "&subjects_unplan";
			title5 "************************************************************************************************";
			footnote justify=left "If expected differences are not shown, verify that your dataset modification (e.g., unblinding script) worked as expected.";
	    	run;
		%end;

	%end;
    %end;

    /* 
    / Tidy up
    /------------------------------------------------------------------------*/
    %tu_tidyup(rmdset=&macroname.:, glbmac=none);

%mend tc_dsetcompare;

