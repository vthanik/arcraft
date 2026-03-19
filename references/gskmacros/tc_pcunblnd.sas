/*----------------------------------------------------------------------------+
| Macro Name    : tc_pcunblnd.sas
|
| Macro Version : 2 Build 1
|
| SAS version   : SAS v9.4
|
| Created By    : Daniel McDonald (dwm95161)
|
| Date          : September 2016
|
| Macro Purpose : Macro to create unblinded SDTM PC dataset
|
| Macro Design  : PROCEDURE STYLE
|
| Input Parameters :
|
| NAME			DESCRIPTION                             	DEFAULT
|
| DSETIN        Specifies the name of the blinded SDTM PC	rawdata.pc (Req)
|				dataset
|
| SMSFILE       Specifies the name and location of the input    [blank] (Req)
|               SMS2000 file. Passed as %tu_getsms2k's
|               parameter of the same name
|
| DELIM			Passed to %tu_getsms2k as its DELIM parameter	|  (Req)
|
| DSETOUT       Specifies the name of the SDTM PC output	sdtmdata.pc (Req)
|               dataset to be created
|
|---------------------------------------------------------------------------------------------------
|
| Output:   1. SDTMDATA.PC dataset
|
| Global macro variables created: None
|
|
| Macros called :
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_abort
| (@) tu_getsms2k
| (@) tu_chknames
| (@) tu_nobs
| (@) tu_maxvarlen
| (@) tu_sqlnlist
| (@) tu_tidyup
|
| Example:
|	%tc_pcunblnd(
|	    dsetin=rawdata.pc,
|	    smsfile=/arenv/arwork/sb497115/tpl104054/final_01/dmdata/SMS2000_TPL104054.dat,
|	    delim=|,
|	    dsetout=sdtmdata.pc
|	    );
|
| **************************************************************************
| Change Log :
|
| Modified By : Daniel McDonald
| Date of Modification : 22-Sep-2016
| New Version Number : 01-002
| Modification ID : DM2
| Reason For Modification :
|	BDS/HARP_RT Defect 571 - PCREASND values are incorrect when RESULT_CONC is NA, NR, NS, and IS
|	BDS/HARP_RT Defect 584 - Code not generating RTERROR for output dataset name same as input dataset name
|	Changed parsing of RESULT_CONC to use best16 format to ensure full value is retained.
|	RD_IT/AR_HARP_195808 Defect 547 - PCREASND values are incorrect when RESULT_CONC is NA, NR, NS, and IS
|	RD_IT/AR_HARP_195808 Defect 589 - PCUNBLND should preserve dataset label from input
|
| Modified By : Chau Tran
| Date of Modification : 29-AUG-17
| New Version Number : 01-003
| Modification ID : CT003
| Reason For Modification : 
|   Defect - If sample IDs are not in sms2000 but in blinded SDTM.PC,  change RTERROR to RTWARNINGs and produce a list of these IDs.
|   Defect - Merge using sample IDs and analyst names
|   Enhancement - Check if sample IDs are in sms2000 but not in blinded SDTM.PC, ERROR/ABBORT macro
|   Enhancement - Check the names of analysts between blinded SDTM PC and SMS2000. If there is a discrepancy, give RTWARNING and produce list of different analysts
|
| Modified By : Anthony J Cooper
| Date of Modification : 30-APR-2018
| New Version Number : 02-001
| Modification ID : AJC001
| Reason For Modification : Set macro version to "2 build 1" in the header and
|                           MacroVersion local macro variable ready for release.
|
+----------------------------------------------------------------------------*/

%macro tc_pcunblnd(
    dsetin=rawdata.pc,			/* Specifies the name of the blinded SDTM PC dataset */
    smsfile=,					/* Specifies the name and location of the SMS2000 input file */
    delim=|,					/* Specifies the character to be used to delimit the SMS2000 text file */
    dsetout=sdtmdata.pc			/* Specifies the name of the SDTM PC output dataset to be created */
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
    %let dsetin		= %nrbquote(&dsetin);
    %let smsfile	= %nrbquote(&smsfile);
    %let delim		= %nrbquote(&delim);
    %let dsetout	= %nrbquote(&dsetout);

    /*
    / Check for required parameters.
    /------------------------------------------------------------------------*/

    %if &dsetin eq %then %do;
	%put %str(RTE)RROR: &macroname: The parameter DSETIN is required.;
	%let g_abort=1;
    %end;

    %if &smsfile eq %then %do;
	%put %str(RTE)RROR: &macroname: The parameter SMSFILE is required.;
	%let g_abort=1;
    %end;

    %if &delim eq %then %do;
	%put %str(RTE)RROR: &macroname: The parameter DELIM is required.;
	%let g_abort=1;
    %end;

    %if &dsetout eq %then %do;
	%put %str(RTE)RROR: &macroname: The parameter DSETOUT is required.;
	%let g_abort=1;
    %end;

    *-- abort if required parameters missing;
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

    *-- Validate if DSETOUT is a valid dataset name and DSETOUT is not same as DSETIN or other input dataset;
    %if %qupcase(&dsetout.) eq %qupcase(%scan(&dsetin, 1, %str(%() )) %then %do;/*DM2*/
	%put %str(RTE)RROR: &macroname.: The Output dataset name is same as Input dataset name.;
	%let g_abort = 1;
    %end;
    %else %if %nrbquote(%tu_chknames(&dsetout., data)) ne %then %do;
	%put %str(RTE)RROR: &macroname.: The parameter DSETOUT (&dsetout.) is not a valid SAS datatset name.;
	%let g_abort=1;
    %end;

    *-- abort if required parameters missing;
    %if &g_abort eq 1 %then %do;
	%tu_abort;
    %end;

	*--------------------------------------------;
    *-- add ID to retain original order for use later;
    *--------------------------------------------;
	data _pc;
  	  set &dsetin;
  	  id=_n_;
	run;

	*--------------------------------------------;
    *-- Verify PCSTATUSMAP RESULT_CONC values;
	*-- %tu_getsms2k does check if &smsfile not exist then abort;
    *--------------------------------------------;
    *-- 1. Get SMS2000 data;
    %tu_getsms2k(smsfile=&smsfile
		,keep=PCSMPID SUBJID2000 PCSPEC PCAN PCLLQC PCORRES PCORRESU STUDYID2000 PERIOD2000 PCPTMNUM2000 PCPTMU2000
		,rename=
		,dsetout=&macroname._ds1
		,delim=&delim
		);

	* sms2000 DAT file contains NO data;
    %let not_found_count = %tu_nobs(&macroname._ds1);
    %if &not_found_count eq 0 %then %do;
	  %put %str(RTE)RROR: &macroname: SMS2000 DAT file contains no data;
	  %let g_abort=1;
    %end;

	*-- abort if sms2000 DAT file is empty;
    %if &g_abort eq 1 %then %do;
	%tu_abort;
    %end;

    *-- 2. Confirm all RESULT_CONC values from SMSFILE are a number or a valid non-numeric code;
    *-- RegEx to match floating point numbers with optional sign and exponent;
    %local is_float;
    %let is_float = '/^[-+]?[0-9]*\.?[0-9]*([eE][-+]?[0-9]+)?$/';
    /* RegEx Translation:
    	^	At beginning of string, match
	[-+]?	a single, optional - or + followed by
	[0-9]*	zero or more occurrences of digits 0-9 followed by
	\.?	a single, optional . followed by
	[0-9]*	zero or more occurrences of digits 0-9 followed by
	(...)?	an optional exponent consisting of
	[eE]	a single e or E followed by
	[-+]?	a single, optional - or + followed by
	[0-9]+	one or more occurrences of digits 0-9 
	$	matched to the end of the string.  */
    %local not_found_count;
    proc sql;
    	create table &macroname._ck1 as
    	select distinct PCORRES, PCSMPID, PCAN
	  from &macroname._ds1 s
	 where upcase(pcorres) not in ('NQ', 'NA', 'NR', 'NS', 'IS')
	   and prxmatch(&is_float, trim(left(pcorres))) = 0;
    quit;

    %let not_found_count = %tu_nobs(&macroname._ck1);
    %if &not_found_count gt 0 %then %do;
	%put %str(RTE)RROR: &macroname: Some (&not_found_count) SMS2000 RESULT_CONC non-numeric values are not valid (Valid=NQ, NA, NR, NS, IS);
	data _null_;
	    set &macroname._ck1;
	    put "RTE" "RROR: For PCSMPID=" pcsmpid ", PCAN=" pcan ", RESULT_CONC value " pcorres "from SMS2000 is not valid";
	run;
	%let g_abort=1;
    %end;

	*-- abort if parameter validation failed;
    %if &g_abort eq 1 %then %do;
	%tu_abort;
    %end;

    *-- 3. Confirm all PCREFID values match a SAMPLE_NUMBER (PCSMPID);
    * CT003: PCREFID not in SMS2000, allow to continue. Update to RTWARNING (Records in PC some do not get Analysed);
    proc sql;
	create table &macroname._ck2 as
	select distinct p.PCREFID
	  from _pc p
	 where not exists (select s.PCSMPID
	 		    from &macroname._ds1 s
			   where s.PCSMPID = p.PCREFID);
    quit;

    %let not_found_count = %tu_nobs(&macroname._ck2);
	%if &not_found_count gt 0 %then %do;
	%put %str(RTW)ARNING: &macroname: Some (&not_found_count) PC PCREFID values are not found in SMS2000 data;
	data _null_;
	    set &macroname._ck2;
		put "RTW" "ARNING: PCREFID " pcrefid " is not found in SMS2000 data";
	run;
    %end;

   * Check to if pcsmpid, Sample in sms2000 not exist in blind PC then ABORT;
	proc sql noprint;
      create table &macroname._ck3 as
	  select  s.*
		   	, p.pcrefid
	  from  &macroname._ds1 s  
	  left join _pc p 
 	  on 	s.pcsmpid = p.pcrefid	  
	  where missing(p.pcrefid);
    quit;

	%let not_found_count = %tu_nobs(&macroname._ck3);
    * CT003: PCSMPID in SMS2000 but not is PC then ABORT;
    %if &not_found_count gt 0 %then %do;
	  %put %str(RTE)RROR: &macroname: Some (&not_found_count) SMS2000 PCSMPID values are not found in blinded PC data;
	  data _null_;
	    set &macroname._ck3;
	    put "RTE" "RROR: PCSMPID " pcsmpid " is not found in blinded PC data";
	  run;
	  %let g_abort=1;
    %end;

	*-- abort if parameter validation failed;
    %if &g_abort eq 1 %then %do;
	%tu_abort;
    %end;

    * Check to if pcan, Analyte Sample in sms2000 not exist in PC then ABORT;
	* Note: macro allow to continue where Analyte is differ only on type casing;
	proc sql noprint;
      create table &macroname._ck4 as
	  select  s.*
		   	, p.pcrefid, p.pctest
	  from  &macroname._ds1 s  
	  left join _pc p 
 	  on 	(s.pcsmpid = p.pcrefid
	  and 	 upcase(s.pcan) = upcase(p.pctest))
	  where missing(p.pctest);	  
    quit;
     
    %let not_found_count = %tu_nobs(&macroname._ck4);

	* CT003: PCAN Analyte in SMS2000 but not is PC, ABORT ;
    %if &not_found_count gt 0 %then %do;
	  %put %str(RTE)RROR: &macroname: Some (&not_found_count) SMS2000 PCAN Analyte values are not found in blinded PC data;
	  data _null_;
	    set &macroname._ck4;
		put "RTE" "RROR: PCSMPID/PCAN " pcsmpid "/" pcan " is not found in blinded PC data";	

	  run;
	  %let g_abort=1;
    %end;

	*-- abort if parameter validation failed;
    %if &g_abort eq 1 %then %do;
	%tu_abort;
    %end;

	* Duplicates in sms2000 DATA file;  
    proc sql noprint;
	  create table &macroname._ck5 as
	  select pcsmpid, pcan, count(*) as count
	  from &macroname._ds1
	  group by pcsmpid, pcan
	  having count(*) gt 1;
	quit;

	%let not_found_count = %tu_nobs(&macroname._ck5);
    * CT003: Check Duplicates Sample/Analyte;
    %if &not_found_count gt 0 %then %do;
	%put %str(RTE)RROR: &macroname: Some (&not_found_count) Duplicates SAMPLE/ANALYTE in SMS2000 DAT file;
	data _null_;
	    set &macroname._ck5;
		put "RTE" "RROR: PCSMPID/PCAN " pcsmpid "/" pcan " duplicates in SMS2000 DAT file ";	
	run;
	%let g_abort=1;
    %end;

	*-- abort if parameter validation failed;
    %if &g_abort eq 1 %then %do;
	%tu_abort;
    %end;

	* Handle case when Blinded PC do not contains variable PCSTAT/PCREASND;
	* Initialise var;
    %let pcstat_pcreasnd_missing=;
	%let pcstat_pcreasnd_null=;
	%let missing_pcstat=%tu_chkvarsexist(_pc, pcstat,Y);
	%let missing_pcreasnd=%tu_chkvarsexist(_pc, pcreasnd,Y);

	%if &missing_pcstat ne and &missing_pcreasnd ne %then %do;
	  * Set Flag to Y if Blind PC NULL values in PCSTAT/PCREASND;
      proc sql noprint;
	    create table &macroname._ck6 as
	    select *
	    from  _pc
	    where not missing(pcstat) or not missing(pcreasnd);
	  quit;

      %let not_found_count = %tu_nobs(&macroname._ck6);
      %let pcstat_pcreasnd_null=N;
      %if &not_found_count eq 0 %then %do;
        %let pcstat_pcreasnd_null=Y;
	  %end;
  	%end;
	%else %do;
  	  %let pcstat_pcreasnd_missing=Y;
	%end;


	* Set Flag SMS2000 DATA does not contain any (NA,NR,NS,IS);
    proc sql noprint;
	  create table &macroname._ck7 as
	  select pcsmpid, pcan, pcorres
	  from  &macroname._ds1
	  where pcorres in ('NA' 'NR' 'NS' 'IS');	  
	quit;

    %let not_found_count = %tu_nobs(&macroname._ck7);
 	%let sms2000_not_na=N;
    %if &not_found_count eq 0 %then %do;
      %let sms2000_not_na=Y;
	%end;

    /*
    / Macro parameters have valid values if the program has
    / not terminated by this point.
    /------------------------------------------------------------------------*/

    /* 
    / Generate unblinded SDTM PC dataset
    /------------------------------------------------------------------------*/
    *-- merge SMS2000 and PCSTATUSMAP into _DS2;
    proc sql;
      create table &macroname._ds2 as
	  select p.*
	     , s.PCORRES as RESULT_CONC
	     , s.PCORRESU as RESULT_CONC_UNITS
	  from _pc p
	  left join &macroname._ds1 s 
      on 		(p.pcrefid = s.pcsmpid
			 and upcase(p.pctest) = upcase(s.pcan))
	  order by p.id;
    quit;

    *-- get a list of all the variables so we can keep the order in the new dataset;
    proc contents data=&macroname._ds2
	out=&macroname._vars(keep=varnum name)
	noprint;
    run;
    proc sql noprint;
	select name
	     , varnum
	  into :orderedvars separated by ' '
	     , :varnums  /*not used*/
	  from &macroname._vars
	 order by varnum;
    quit;

    *-- copy _DS2 to &DSETOUT and set concentration info;
    data &macroname._ds3;  /*DM2*/
    	*-- use FORMAT statement to keep the order of variables from the input dataset;
	format &orderedvars;
    	*-- define the data type and length for blinded PC variables;
	length PCORRES $ 20;  /*DM2*/
	length PCORRESU $ 20;  /*DM2*/
	length PCSTRESC $ 20;  /*DM2*/
	length PCSTRESN 8;
	length PCSTRESU $ 20;  /*DM2*/
	length PCSTAT $ 10;
	length PCREASND $ 200;
	*-- labels from PC dataset definition;
	/* DM2-keep label from existing variables
	label PCORRES="Result or Finding in Original Units";
	label PCORRESU="Original Units";
	label PCSTRESC="Character Result/Finding in Std Format";
	label PCSTRESN="Numeric Result/Finding in Standard Units";
	label PCSTRESU="Standard Units";
	label PCSTAT="Completion Status";
	label PCREASND="Reason Test Not Done";
	*/
    	set &macroname._ds2; *-- copy records from _DS2 into &DSETOUT;
	drop RESULT_CONC RESULT_CONC_UNITS ID;
	if prxmatch(&is_float, trim(left(RESULT_CONC))) eq 0 then do;
	    *-- Non-numeric RESULT_CONC ;
	    if RESULT_CONC eq 'NQ' then do;
		  PCORRES='NQ';
		  PCORRESU=RESULT_CONC_UNITS;
		  PCSTRESC='NQ';
		  PCSTRESN=.;
		  PCSTRESU=RESULT_CONC_UNITS;
		  PCSTAT=' ';
		  PCREASND=' ';
	    end;
	    else do;
		  PCORRES=.;
		  PCORRESU=.;
		  PCSTRESC=.;
		  PCSTRESN=.;
		  PCSTRESU=.;
		  PCSTAT='NOT DONE';
		  if RESULT_CONC eq 'NA' then do;
		    PCREASND='NA: Not analysed'; /*DM2*/
		  end;
		  else if RESULT_CONC eq 'NR' then do;
		    PCREASND='NR: Not reportable'; /*DM2*/
		  end;
		  else if RESULT_CONC eq 'NS' then do;
		    PCREASND='NS: No sample received'; /*DM2*/
		  end;
		  else if RESULT_CONC eq 'IS' then do;
		    PCREASND='IS: Insufficient sample'; /*DM2*/
		  end;
	    end;
	end;
	else do;
	    *-- Numeric RESULT_CONC ;
	    PCORRES=RESULT_CONC;
	    PCORRESU=RESULT_CONC_UNITS;
	    PCSTRESC=RESULT_CONC;
	    PCSTRESN=input(RESULT_CONC, best16.); /*DM2*/
	    PCSTRESU=RESULT_CONC_UNITS;
	    PCSTAT=' ';
	    PCREASND=' ';
	end;
    run;

    * Optimised Variable length;
    data pc1;
      set &macroname._ds3;
    run;

    /* Identify maximum length of character variables in input dataset */
    %tu_maxvarlen(dsetin=pc1,
                  dsetout=pc1_mxvarlen);

    * Only unblind RESULTS/PCSTAT/PCREASND;
    data pc1_mxvarlen;
      set pc1_mxvarlen;
      where name in ('PCORRES' 'PCORRESU' 'PCSTRESC' 'PCSTRESU' 'PCSTAT' 'PCREASND');
    run;

    /* Build new series of attrib statements */ 
    filename tmp1 temp;
    data _null_;
      file tmp1;
      set pc1_mxvarlen;
      name=upcase(name);  
      put 'attrib ' name 'length=$' mlen ';';
    run;
	
    /* Get original variables order */
    proc sql noprint;
      select name into : varlist separated by ' ' 
      from dictionary.columns
      where libname eq 'WORK'
        and memname eq 'PC1';
    quit;

    /***************************************************************
     * Apply attrib statements to reset variable length attributes *
     ***************************************************************/
    data pc2;
      %inc tmp1;
      set pc1;
    run;
  
    /**************************************************
     * Reset variable order to planned variable order *
     **************************************************/
    proc sql noprint;
      create table pc3 as
      select %tu_sqlnlist(&varlist)
      from pc2;
    quit;

	* Check if blind PC NULL values in PCSTAT and PCREASND and SMS2000 does not contains any (NA NR NS IS)
	* CT003: Drop PCSTAT and PCREASND from unblind PC;
    %if &pcstat_pcreasnd_null=Y and &sms2000_not_na=Y %then %do;
	  data &dsetout. (drop=PCSTAT PCREASND label='Pharmacokinetic Concentrations');
        set pc3; /*&macroname._ds3;*/ 
      run;
	  * Provide message PCSTAT, PCREASND dropped;
	  %put %str(RTN)OTE: &macroname.: PCSTAT, PCREASND dropped from Un-blinded PC;
	%end;
	%else %if &pcstat_pcreasnd_missing=Y and &sms2000_not_na=Y %then %do;
	  data &dsetout. (drop=PCSTAT PCREASND label='Pharmacokinetic Concentrations');
        set  pc3;
      run;
	  * no need to provide RTNOTE on dropping PCSTAT, PCREASND because they were not in blinded PC;
	%end;
	%else %do;
	  data &dsetout. (label='Pharmacokinetic Concentrations');
        set pc3;
      run;       
	%end;
	
    /* 
    / Tidy up
    /------------------------------------------------------------------------*/
    %tu_tidyup(rmdset=&macroname.:, glbmac=none);

%mend tc_pcunblnd;

