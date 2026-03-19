/*******************************************************************************
| Macro Name: 	  tu_adgettrt.sas
|
| Macro Version:  1 build 2
|
| SAS Version: 	  SAS v9.1
|
| Created By:     Gaurav Gupta (gg158110)
|
| Date:           05-Dec-2012
|
| Macro Purpose:  The purpose of the code is to merge the input dataset 
|			      with the treatment dataset by the merge variables provided 
|                 by the user and create an output dataset with the input
|			      and treatment data.
|
| Macro Design:	  Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION						        DEFAULT
| -----------------  ------------------------------------------	----------
| DSETIN             Specifies the input dataset name.      	None
|                    Valid values: valid dataset name
|
| DSETINADSL         Specifies the treatment dataset name.  	None
|                    Valid values: valid dataset name
|
| MERGEVARS          Specifies the space separated list of 		USUBJID
|                    variables to merge input and treatment
|                    datasets.
|                    Valid values: valid variable names
|                    which exist on DSETIN and DSETINADSL
|
| TRTVARS		     Specifies the space separated list of 		None
|			         variables to fetch from the 
|                    treatment dataset.
|                    Valid values: valid variable names
|                    which exist on DSETINADSL
|
| DSETOUT            Specifies the output dataset name.     	None
|                    Valid values: valid dataset name
| -----------------  ------------------------------------------ ----------
|
| The macro references the following datasets :-
| -----------------  -------  --------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETIN            Req      Parameter specified dataset
| &DSETINADSL        Req      Parameter specified dataset
| -----------------  -------  -------------------------------------------------
|
| Output:
|
| The macro outputs the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETOUT           Req      Parameter specified dataset
| -----------------  -------  -------------------------------------------------
|
| Global macro variables created: NONE
|
| Macros called :
|  (@) tr_putlocals
|  (@) tu_putglobals
|  (@) tu_abort
|  (@) tu_chknames
|  (@) tu_chkvarsexist
|  (@) tu_expvarlist
|  (@) tu_nobs
|  (@) tu_tidyup
|
| Example:
|    %tu_adgettrt (dsetin     = ae,
|                  dsetinadsl = adamdata.adsl,
|                  mergevars  = usubjid,
|                  trtvars    = trt01p: trt01a:,
|			       dsetout    = ae_gettrt);
|
|*******************************************************************************
| Change Log
|
| Modified By:              Anthony J Cooper
| Date of Modification:     09-May-2014
| New version/draft number: 1 build 2
| Modification ID:          AJC001
| Reason For Modification:  Merge of input and treatment datasets now driven
|                           by MERGEVARS only. Removed parameters no longer
|                           required, updated parameter validation and normal
|                           processing sections.
********************************************************************************/

%macro tu_adgettrt (
       dsetin = ,           /* Name of the input dataset */
       dsetinadsl = ,       /* Name of Treatment dataset */
       mergevars = USUBJID, /* List of variables to merge input and treatment datasets */
       trtvars = ,          /* List of variables to fetch from treatment dataset */
       dsetout =            /* Name of the output dataset */
       );

  /*
  / Write details of macro start to log
  / ---------------------------------------------------------------------------*/

  %local MacroVersion;
  %let MacroVersion = 1 build 2;

  %include "&g_refdata/tr_putlocals.sas";

  %tu_putglobals()

  /*
  /  Set up local macro variables
  / ---------------------------------------------------------------------------*/

  %local
    prefix       /* used for uniquely identifying temporary datasets created by this program */
    dinexst      /* captures output from tu_chkvarsexist */
    trtexst      /* captures output from tu_chkvarsexist */
    trtvexst     /* captures output from tu_chkvarsexist */
    indtexst     /* captures output from tu_chkvarsexist */
    trtmergevars /* copy of mergevars with TPERIOD changed to APERIOD if present */ 
    lastmergevar /* last variable in list of mergevars */
    ;

  %let prefix = adgettrt;
    
  /*
  / Parameter Validation
  / ---------------------------------------------------------------------------*/

  %let dsetin     = %qupcase(%nrbquote(&dsetin.));
  %let dsetinadsl = %qupcase(%nrbquote(&dsetinadsl.));
  %let dsetout    = %qupcase(%nrbquote(&dsetout.));
  %let mergevars  = %upcase(&mergevars.);
  %let trtvars    = %upcase(&trtvars.);

  /* Validating if non-missing values are provided for parameters DSETIN, DSETOUT, DSETINADSL, MERGEVARS and TRTVARS  */

  %if &dsetin. eq %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETIN is a required parameter, provide a dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &dsetout. eq %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETOUT is a required parameter, provide a dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &dsetinadsl. eq %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETINADSL is a required parameter, provide a dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &mergevars. eq %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter MERGEVARS is a required parameter, provide space separated list of variables.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &trtvars. eq %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter TRTVARS is a required parameter, provide space separated list of variables.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;

  /* Validating if DSETIN and dsetinadsl exist and dsetinadsl is not same as DSETIN */

  %if %sysfunc(exist(&dsetin.)) eq 0 %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: The Input dataset DSETIN(=&dsetin.) does not exist.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if %sysfunc(exist(&dsetinadsl.)) eq 0 %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: The Treatment dataset DSETINADSL(=&dsetinadsl.) does not exist.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
  %else %if &dsetinadsl. eq &dsetin. %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: The Treatment dataset name DSETINADSL(=&dsetinadsl.) is same as Input dataset name DSETIN(=&dsetin.).;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;

  /* Validating if DSETOUT is a valid dataset name and DSETOUT is not same as DSETIN or dsetinadsl */

  %if %qupcase(&dsetout.) eq %qupcase(&dsetin.) or %qupcase(&dsetout.) eq %qupcase(&dsetinadsl.) %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: The Output dataset name DSETOUT(=&dsetout.) is same as Input dataset name DSETIN(=&dsetin.) or Treatment dataset name DSETINADSL(=&dsetinadsl.).;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
  /* calling tu_chknames to validate name provided in DSETOUT parameter */
  %else %if %tu_chknames(&dsetout., DATA) ne %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETOUT refers to dataset %nrbquote(%upcase("&dsetout.")) which is not a valid dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;

  /*
  / Check that MERGEVARS exist on the input and treatment datasets.
  / If MERGEVARS includes TPERIOD then check APERIOD exists on the treatment dataset
  / instead of TPERIOD.
  / ---------------------------------------------------------------------------------------*/

  %let dinexst = %tu_chkvarsexist(&dsetin.,&mergevars.);

  %if &dinexst. ne %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter MERGEVARS refers to variable(s) "&dinexst.", which do not exist in input dataset DSETIN(=&dsetin.) .;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %let trtexst = %tu_chkvarsexist(&dsetinadsl., %sysfunc(tranwrd(&mergevars.,TPERIOD, )));

  %if &trtexst. ne %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter MERGEVARS refers to variable(s) "&trtexst.", which do not exist in treatment dataset DSETINADSL(=&dsetinadsl.).;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if %index(&mergevars.,TPERIOD) gt 0 and %tu_chkvarsexist(&dsetinadsl.,APERIOD) ne %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Variable APERIOD must exist in treatment dataset DSETINADSL(=&dsetinadsl.) when Macro Parameter MERGEVARS contains TPERIOD.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /*
  / Calling tu_expvarlist to expand treatment variables to be fetched from Treatment dataset.
  / Also checking the existence of variables in treatment dataset.
  / ---------------------------------------------------------------------------------------*/

  %tu_expvarlist(dsetin = &dsetinadsl., varsin = &trtvars., scope = global, varout = exptrtvars)

  %let trtvexst = %tu_chkvarsexist(&dsetinadsl.,&exptrtvars.);

  %if &trtvexst. ne %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter TRTVARS refers to variable(s) "&trtvexst.", which do not exist in treatment dataset DSETINADSL(=&dsetinadsl.).;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;

  /*
  / Check for duplicate values of MERGEVARS in DSETINADSL.
  / If TPERIOD is specified as a merge variable check APERIOD.
  / ---------------------------------------------------------------------------------------*/

  %let trtmergevars = %sysfunc(tranwrd(&mergevars.,TPERIOD,APERIOD));
  %let lastmergevar = %scan(&trtmergevars.,-1);

  proc sort data = &dsetinadsl. (keep=&trtmergevars.) out = &prefix._trtsort;
    by &trtmergevars.;
  run;

  data &prefix._trtsortdups;
    set &prefix._trtsort;
    by &trtmergevars.;
    if not (first.&lastmergevar. and last.&lastmergevar.);
  run;

  %if %tu_nobs(&prefix._trtsortdups) gt 0 %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Treatment dataset DSETINADSL(=&dsetinadsl.) contains duplicate values of merge variables MERGEVARS(=&mergevars.) so cannot be merged with input dataset DSETIN(=&dsetin.).;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;

  /*
  / Main Processing starts here.
  / Sort both input and treatment datasets by MERGEVARS ready for merging.
  / If MERGEVARS contains TPERIOD then rename APERIOD to TPERIOD on the
  / treatment dataset.
  / For parallel group studies, rename specified variables if they exist.
  / ---------------------------------------------------------------------------*/

  proc sort data = &dsetin. out = &prefix._dsetin;
    by &mergevars.;
  run;

  data &prefix._dsetinadsl;
    set &dsetinadsl. (keep = %sysfunc(tranwrd(&mergevars.,TPERIOD,APERIOD)) &exptrtvars.);
    %if %upcase(&g_stype) eq PG %then
    %do;
      %if %index(%upcase(&exptrtvars.),TRT01P) gt 0 %then rename TRT01P = TRTP;;
      %if %index(%upcase(&exptrtvars.),TRT01A) gt 0 %then rename TRT01A = TRTA;;
      %if %index(%upcase(&exptrtvars.),TRT01PN) gt 0 %then rename TRT01PN = TRTPN;;
      %if %index(%upcase(&exptrtvars.),TRT01AN) gt 0 %then rename TRT01AN = TRTAN;;
    %end;
    %if %index(%upcase(&mergevars.),TPERIOD) gt 0 %then rename APERIOD = TPERIOD;;
  run;

  proc sort data = &prefix._dsetinadsl;
    by &mergevars.;
  run;

  data &dsetout.;
    merge &prefix._dsetin (in = a) &prefix._dsetinadsl;
    by &mergevars.;
    if a;
  run;

  /*
  / Delete temporary datasets used in this macro.
  /---------------------------------------------------------------------------*/

  %tu_tidyup (rmdset = &prefix:, glbmac = exptrtvars);

%mend tu_adgettrt;
