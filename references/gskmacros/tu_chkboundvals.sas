/******************************************************************************* 
| Program Name: tu_chkboundvals
|
| Program Version: 1.1
|
| HARP Compound/Study/Reporting Effort: 
|
| Program Purpose: Flags observations where specified value variable (VALUEVAR)is 
|                  deemed to be close to a boundary value (COMPVARS) based on a level
|                  of accuracy (CRITERIA) using the algorithm :-
/                  if COMPVAR ne . and abs(COMPVAR-VALUEVAR) lt VALUEVAR*10**-CRITERIA
|
| SAS Version: SAS v9.4
|
| Created By: Lee Seymour
| Date:       03Oct2017
|
|******************************************************************************* 
|  Example Usage 
|
| %tu_chkboundvals(dsetin=mydset, 
|                  valuevar=aval, 
|                  compvars=a1lo a1hi, 
|                  obsidvars=usubjid visit param,
|                  criteria=6
|				   dsetout=check_results
|                  );
|
| %tu_chkboundvals(dsetin=mydset, 
|                  valuevar=aval, 
|                  compvars=a1lo a1hi, 
|                  obsidvars=usubjid visit param,
|                  criteria=6
|				   dsetout=
|                  );
|
|******************************************************************************* 
| Output: Messages to log file
|
| Nested Macros: 

| (@) tu_putglobals
| (@) tu_abort  
| (@) tu_tidyup
| (@) tu_chkvarsexist
| (@) tu_words
| (@) tu_chknames
|
| Metadata:
|
|******************************************************************************* 
| Change Log 
|
| Modified By: Chau Tran
| Date of Modification: 17-APR-2018
| Modification ID: CT001
| Reason For Modification: Make further updates based on review comments
|
| Modified By: Chau Tran
| Date of Modification: 01-MAY-2018
| Modification ID: CT002
| Reason For Modification: Bug fix
********************************************************************************/ 
%macro tu_chkboundvals(dsetin=,                    /* Input dataset */
                       valuevar=,                  /* Single variable containing the variable used to check against comparator variables */
                       compvars=,                  /* Comparator variable(s)  */
                       obsidvars= ,                /* Variables used to identify the unique observation include in output dataset */
                       criteria= ,                 /* Data check criteria */
                       dsetout =                   /* Optional output dataset containing OBSIDVARS VALUEVAR COMPVARS and various flags. If parameter left blank please make sure to review RTNOTE in log, search for "CHKBOUNDVALS: Data Check Required" */
                      );

  /*
  / Echo parameter values and global macro variables to the log.
  /----------------------------------------------------------------------------*/

  %local MacroVersion;
  %let MacroVersion = 1.1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin= g_abort g_refdata);

  /*
  /  Set up local macro variables
  / ---------------------------------------------------------------------------*/

  %local prefix cvars cvarsx;
  %let prefix = _chkboundvals;         

  /*
  / PARAMETER VALIDATION
  /----------------------------------------------------------------------------*/

  %let dsetin            = %nrbquote(&dsetin.);
  %let valuevar          = %nrbquote(&valuevar.);
  %let compvars          = %nrbquote(&compvars.);
  %let obsidvars         = %nrbquote(&obsidvars.);
  %let criteria          = %nrbquote(&criteria.);
  %let dsetout           = %nrbquote(&dsetout.);

  /* Validating for missing values are provided for parameters DSETIN , VALUEVAR and COMPVARS  */

  %if &dsetin. eq %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETIN is a required parameter, provide a dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &valuevar. eq %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter VALUEVAR is a required parameter, provide a variable;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if %length(&compvars)=0 %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: At least one comparator variable COMPVARS is required;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if %length(&obsidvars)=0 %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: At least one unique observation variable OBSIDVARS is required;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Check VALUEVAR is a single variable */  
  %if %scan(&valuevar,1) ne %scan(&valuevar,-1) %then %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter (VALUEVAR=&valuevar) has more than one variables, provide a single variable only;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end; 

  /* Check if CRITERIA is a positive integer and not zero 
*********************************************************/

  %IF %BQUOTE(&criteria) = %THEN %DO;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter CRITERIA may not be null or blank.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %END;
  %ELSE %IF %datatyp(&criteria) = CHAR %THEN %DO;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter CRITERIA must be a numeric value.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %END;
  %ELSE %IF (&criteria eq 0 or (%BQUOTE(&criteria) NE %SYSFUNC(ABS(%SYSFUNC(INT(&criteria)))))) %THEN %DO;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter CRITERIA must be a positive integer.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %END; 
 
  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;

  /* calling tu_chknames to validate name provided in DSETIN parameter */
  %if %tu_chknames(%scan(&dsetin, 1, %str(%() ), DATA ) ne %then %do;
     %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETIN refers to dataset &dsetin which is not a valid dataset name;
     %let g_abort = 1;
     %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;

  /* Validating if DSETIN dataset exists */
  %if %SYSFUNC(EXIST(%scan(&dsetin, 1, %str(%() ) )) NE 1 %then %do;
     %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETIN refers to dataset %upcase("&dsetin.") which does not exist.;
     %let g_abort = 1;
     %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;

  /* Validation if DSETOUT is specified, is valid, not same as DSETIN */
  %if %length(&dsetout) gt 0 %then
  %do;
    %if %qupcase(&dsetout.) eq %qupcase(%scan(&dsetin, 1, %str(%() )) %then %do;
        %put %str(RTE)RROR: &sysmacroname.: The Output dataset name is same as Input dataset name.;
        %let g_abort = 1;
    %end;

	/* calling tu_chknames to validate name provided in DSETOUT parameter */
    %if %tu_chknames(&dsetout., DATA) ne %then %do;
      %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETOUT refers to dataset &dsetout which is not a valid dataset name;
      %let g_abort = 1;
    %end;
  %end;

  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;

  /* Validation if variables VALUEVAR, OBSIDVARS, COMPVARS exist in dataset DSETIN if specified */
   %if %length(%tu_chkvarsexist(&dsetin,&valuevar)) gt 0 %then
   %do;
     %put RTE%str(RROR:) &sysmacroname.: Macro Parameter VALUEVAR=&valuevar refers to variable that does not exist in DSETIN=&dsetin;
     %let g_abort = 1;
     %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
   %end;
   
   %if %length(%tu_chkvarsexist(&dsetin,&obsidvars)) gt 0 %then
   %do;
     %put RTE%str(RROR:) &sysmacroname.: Macro Parameter OBSIDVARS=&obsidvars refers to variable(s) %tu_chkvarsexist(&dsetin,&obsidvars) that does not exist in DSETIN=&dsetin;
     %let g_abort = 1;
     %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
   %end;

   %if %length(%tu_chkvarsexist(&dsetin,&compvars)) gt 0 %then
   %do;
     %put RTE%str(RROR:) &sysmacroname.: Macro Parameter COMPVARS=&compvars refers to variable(s) %tu_chkvarsexist(&dsetin,&compvars) that does not exist in DSETIN=&dsetin;
     %let g_abort = 1;
     %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
   %end;

  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;

   /* Normal Processing */
  data &prefix._chk(keep=obs &obsidvars &valuevar &compvars cbverr cbvflag: diff:);
    set &dsetin;
	attrib obs length=8 label="Observation ID"
	       cbverr length=$1 label="Observation Near Boundary Flag";
    obs=_n_;
    %do cvars=1 %to %tu_words(&compvars);
      %let cvarsx=%scan(&compvars,&cvars.);

      attrib diff&cvars length=8 label="Compare Difference %upcase(&valuevar) %upcase(&cvarsx)"
             cbvflag&cvars length=$4 label="Observation Near Boundary %upcase(&cvarsx)";

        diff&cvars=abs(&cvarsx - &valuevar.);

        if diff&cvars=0 then cbvflag&cvars="ON";
        else if &cvarsx ne . and diff&cvars lt &valuevar*10**-&criteria then 
        do;
            cbvflag&cvars="NEAR";
            cbverr="Y";
        end;

    %end;
  run;

  /* Filter on observation flag as error only */
  data &prefix._chk1;
	set &prefix._chk(where=(cbverr='Y'));
  run;

  /* Get observations count */
  proc sql noprint;
    select count(*) into :cbverrcount from &prefix._chk1;
  quit;

  /* Has observation flag */
  %if &cbverrcount gt 0 %then %do;

    %if %length(&dsetout) gt 0 %then %do;
      data &dsetout (label=SAS precision check on variable &VALUEVAR);
        set &prefix._chk1;
      run;	  	
	  /* Output one RTNOTE to log */
      %put RTN%str(OTE:) &sysmacroname: Data Check Required. Review contents of &dsetout dataset;
	%end;
	%else %do;
      data _null_;
        set &prefix._chk1;
	    /* Output RTNOTE for each observation to log */
        put "RTN" "OTE: &sysmacroname: Data Check Required : Observation Num= " obs ", Value=" &valuevar;
      run;
	%end;

  %end;
  %else %do;

    %if %length(&dsetout) gt 0 %then %do;
	  /* Create empty dataset */
      data &dsetout (label=SAS precision check on variable &VALUEVAR);
	    set &prefix._chk1;
      run;	
	%end;
    %put RTN%str(OTE:) &sysmacroname.: SAS precision check on observations near boundary. NO ISSUE FOUND;	/* No observation flag with error */
  %end;

  /* Calling tu_tidyup to delete the temporary datasets. */
  %tu_tidyup(rmdset=&prefix.:, glbmac=none);

%mend;
