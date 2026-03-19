/*******************************************************************************
| Macro Name: 	tu_adtrt.sas
|
| Macro Version: 	1.0
|
| SAS Version: 	SAS v9.1
|
| Created By:     Gaurav Gupta (gg158110)
|
| Date:           25-Oct-2012
|
| Macro Purpose:	This program normalizes the source ADSL data for the actual and
|                 planned treatment variables in the output dataset.
|
| Macro Design:	Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                            DEFAULT
| -----------------  -------------------------------------  ----------
| ATTRIBUTESYN       Specifies the flag to apply attributes None
|                    in output dataset.
|
| DSETIN             Specifies the input dataset name.      None
|
| DSETOUT            Specifies the output dataset name.     None
| -----------------  -------------------------------------  ----------
|
| Output: 		This code creates a dataset by transposing all treatment variables
|			from horizontal structure to vertical structure.
|
| Global macro variables created: None
|
| Macros called :
|  (@) tr_putlocals
|  (@) tu_putglobals
|  (@) tu_abort
|  (@) tu_chknames
|  (@) tu_norm
|  (@) tu_attrib
|  (@) tu_tidyup
|
| Example:
|    %tu_adtrt (dsetin  = adsl,
|               dsetout = adtrt,
|               attributesyn = n );
|
|*******************************************************************************
| Change Log
|
| Modified By:
| Date of Modification:
| New Version/Build Number:
| Description for Modification:
| Reason For Modification:
|
********************************************************************************/

%macro tu_adtrt (
       dsetin = , /* Name of the input dataset */
       dsetout = ,  /* Name of the output dataset */
       attributesyn = /* Flag to indicate if attributes should be applied in output dataset */
                );

  /*
  / Write details of macro start to log
  /---------------------------------------------------------------------------*/

  %local MacroVersion;
  %let MacroVersion = 1;

  %include "&g_refdata/tr_putlocals.sas";

  %tu_putglobals()

  /*
  /  Set up local macro variables
  /---------------------------------------------------------------------------*/

  %local
    prefix  /* used for uniquely identifying temporary datasets created by this program */
  ;

  %let prefix = adtrt;

  /*
  / Parameter Validation
  /---------------------------------------------------------------------------*/

  %let dsetin = %qupcase(%nrbquote(&dsetin));
  %let dsetout = %qupcase(%nrbquote(&dsetout));

  /* Validating DSETIN parameter */

  %if &dsetin. eq %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETIN is a desired parameter, provide a dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
  %else
  %do;
    %if %sysfunc(exist(&dsetin.)) eq 0 %then
    %do;
      %put RTE%str(RROR:) &sysmacroname.: Input dataset &dsetin. does not exist.;
      %let g_abort = 1;
      %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
    %end;
  %end;

  /* Validating DSETOUT parameter */

  %if &dsetout. eq %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETOUT is a desired parameter, provide a dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
  %else
  %do;
    %if &dsetout. eq &dsetin. %then
    %do;
      %put RTE%str(RROR:) &sysmacroname.: The Output dataset name is same as Input dataset name.;
      %let g_abort = 1;
      %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
    %end;
 
    /* calling tu_chknames to validate name provided in DSETOUT parameter */

    %else %if %tu_chknames(&dsetout., DATA) ne %then
    %do;
      %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETOUT refers to dataset %nrbquote("&dsetout.") which is not a valid dataset name.;
      %let g_abort = 1;
      %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
    %end;
  %end;

  /* Validating ATTRIBUTESYN parameter */

  %if %upcase(&attributesyn.) ne Y and %upcase(&attributesyn.) ne N %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ATTRIBUTESYN should be either Y or N,;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Aborting the execution, if any of the parameter validation fails. */

  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;

  /*
  / Main Processing starts here.
  /---------------------------------------------------------------------------*/

  %local lib mem;

  %if %index(&dsetin,.) gt 0 %then
  %do;
    %let lib = %qscan(&dsetin.,-2, .);
    %let mem = %qscan(&dsetin.,-1, .);
  %end;
  %else
  %do;
    %let lib = WORK;
    %let mem = &dsetin.;
  %end;

  proc sql noprint;
    select count(distinct(name)) into : numtrtperiod
    from dictionary.columns
    where upcase(libname) eq "&lib." and upcase(memname) eq "&mem." and upcase(name) like 'TRT__P'
    ;
  quit;

  /* Dropping the TRTXXP, TRTXXPN, TRTXXA, TRTXXAN, TRXXSDT and TRXXEDT variables. */

  data &prefix._adsl;
    set &dsetin. (drop=trt0: tr0:);
  run;

  /*
  / Creating macro loopit to identify the source variables to be normalized and
  / call tu_norm utility for normalization and creating a dataset with planned and 
  / actual treatment variables to be kept in the output dataset.
  /-------------------------------------------------------------------------------*/

  %macro loopit (varstr=, varcreate=, dsetout=, trtsuffix=);

    proc sql noprint;
      select name into : varx
      separated by ' '
      from dictionary.columns
      where upcase(libname) eq "&lib." and upcase(memname) eq "&mem." and upcase(name) like "&varstr" 
      ;
    quit;

    %tu_norm(dsetin=&dsetin.,
             dsetout=&prefix._temp(keep=studyid usubjid tt_normval tt_normvar rename=(tt_normval=&varcreate )),
             varstonorm=&varx,
             fmtkeepyn=N
             );

    data &dsetout.;
      set &prefix._temp;
      ordvar=compress(tt_normvar,,'kd');
    run;

  %mend loopit;

  /* Calling loopit macro for each treatment variable. */

  %loopit(varstr=TRT__P, varcreate=TRTP, dsetout=&prefix._ds_normedp);
  %loopit(varstr=TRT__PN, varcreate=TRTPN, dsetout=&prefix._ds_normedpn);
  %loopit(varstr=TRT__A, varcreate=TRTA, dsetout=&prefix._ds_normeda);
  %loopit(varstr=TRT__AN, varcreate=TRTAN, dsetout=&prefix._ds_normedan);
  %loopit(varstr=TR__SDT, varcreate=TRTSTDT, dsetout=&prefix._ds_normsdt);
  %loopit(varstr=TR__EDT, varcreate=TRTENDT, dsetout=&prefix._ds_normedt);


  /* Appending all the normalized datasets into one dataset. */

  data &prefix._all (drop=tt_normvar);
    merge &prefix._ds_normedp &prefix._ds_normeda &prefix._ds_normedpn &prefix._ds_normedan 
      &prefix._ds_normsdt &prefix._ds_normedt;
    by studyid usubjid ordvar;
  run;

  /* Creating final dataset by merging it with source ADSL dataset. */

  data &prefix._adsl_noattrib (drop = ordvar);
    merge &prefix._all &prefix._adsl;
    by studyid usubjid;
  run;

  /* Calling tu_attrib to apply the attributes to the variables in output dataset, if attributesyn parameter is Y. */

  %if %upcase(&attributesyn.) eq Y %then
  %do;
    %tu_attrib (
       dsetin = &prefix._adsl_noattrib,
       dsetout= &dsetout.,
       dsplan = &g_dsplanfile
      );
  %end;
  %else
  %do;
    data &dsetout.;
      set &prefix._adsl_noattrib;
    run;
  %end;

  /*
  / Delete temporary datasets used in this macro.
  /---------------------------------------------------------------------------*/

  %tu_tidyup (rmdset = &prefix:, glbmac = NONE);

%mend tu_adtrt;
