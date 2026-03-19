/*******************************************************************************
|
| Macro Name:      tc_tmslice
|
| Macro Version:   2
|
| SAS Version:     8.2
|
| Created By:      Eric Simms
|
| Date:            28-Jun-2004
|
| Macro Purpose:   Timeslicing wrapper macro
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                            REQ/OPT  DEFAULT
| -----------------  -------------------------------------  -------  ----------
| DSETIN             Specifies the TMSLICE-format SI        REQ      DMDATA.TMSLICE
|                    dataset which needs to be transformed 
|                    into a TMSLICE-format A&R dataset.
|                    Valid values: valid dataset name
|
| DSETOUT            Specifies the name of the output       REQ      ARDATA.TMSLICE
|                    dataset to be created.
|                    Valid values: valid dataset name
|
| DERIVATIONYN       Call %tu_derive to perform specific    REQ      Y
|                    derivations for this domain code (TS)?
|                    Valid values: Y, N
|
| ATTRIBUTESYN       Call %tu_attrib to reconcile the       REQ      Y
|                    A&R-defined attributes to the planned 
|                    A&R  dataset?
|                    Valid values: Y, N
|
| MISSCHKYN          Call %tu_misschk to print RTWARNING    REQ      Y
|                    messages for each variable in 
|                    &DSETOUT which has missing values
|                    on all records.                    
|                    Valid values: Y, N.              
|
| DSPLAN             Specifies the path and file name of    OPT      &g_dsplanfile
|                    the tab-delimited HARP A&R dataset 
|                    metadata. This will define the 
|                    attributes to use to define the A&R 
|                    dataset.
|                    NOTE: If DSPLAN is not specified
|                          (i.e. left to its default
|                          value), or is specified as
|                          anything other than blank,
|                          then both DSETTEMPLATE and
|                          SORTORDER must not be
|                          specified as anything
|                          non-blank. If DSETTEMPLATE
|                          or SORTORDER are specified
|                          as anything non-blank, then
|                          DSPLAN must be specified as
|                          blank (DSPLAN=,).
|
| DSETTEMPLATE       Specifies the name of the empty        OPT      (Blank)
|                    dataset containing the variables and 
|                    attributes desired for the A&R dataset.
|                    NOTE: If DSSETTEMPLATE is specified
|                          as anything non-blank, then
|                          DSPLAN must be specified as
|                          blank (DSPLAN=,).
|
| SORTORDER          Specifies the sort order desired for   OPT      (Blank)
|                    the A&R dataset.
|                    NOTE: If SORTORDER is specified
|                          as anything non-blank, then
|                          DSPLAN must be specified as
|                          blank (DSPLAN=,).
|
| NODERIVEVARS       List of domain-specific variables not  OPT      (Blank)
|                    to derive when %tu_derive is called.
| -----------------  -------------------------------------  -------  ----------
|
| The macro references the following datasets :-
| ------------------  -------  ------------------------------------------------
| Name                Req/Opt  Description
| ------------------  -------  ------------------------------------------------
| &DSETIN             Req      Parameter specified dataset
| &REFDATESOURCEDSET  Opt      Parameter specified dataset
| &DSETTEMPLATE       Opt      Parameter specified dataset
| ------------------  -------  ------------------------------------------------
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
|
| Macros called:
|(@) tr_putlocals
|(@) tu_abort
|(@) tu_attrib
|(@) tu_derive
|(@) tu_misschk
|(@) tu_nobs
|(@) tu_putglobals
|(@) tu_tidyup    
|
| Examples:
|    %tc_tmslice(
|         dsplan          = &g_dsplanfile
|         );
|
|    %tc_tmslice(
|         dsplan          = ,
|         dsettemplate    = attrib_data,
|         sortorder       = studyid visitnum
|         );
|
|******************************************************************************
| Change Log
|
| Modified By:              Yongwei Wang
| Date of Modification:     17-Sep-07
| New version/draft number: 2/1
| Modification ID:          YW001
| Reason For Modification:  Based on change request HRT0184 and HRT0172:
|                           1. Added call of %tu_nobs to check if data set exist
|
| Modified By:  
| Date of Modification:  
| New version/draft number:
| Modification ID: 
| Reason For Modification: 
|                          
|
*******************************************************************************/
%macro tc_tmslice (
     dsetin            = DMDATA.TMSLICE,  /* Input dataset name */
     dsetout           = ARDATA.TMSLICE,  /* Output dataset name */
     
     derivationyn      = Y,       /* Dataset specific derivations */
     attributesyn      = Y,       /* Reconcile A&R dataset with planned A&R dataset */
     misschkyn         = Y,       /* Print warning message for variables in &DSETOUT with missing values on all records */ 
     dsplan            = &g_dsplanfile, /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
     dsettemplate      = ,        /* Planned A&R dataset template name */
     sortorder         = ,        /* Planned A&R dataset sort order */
     noderivevars      =          /* List of variables not to derive */
        );

 /*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion;
 %let MacroVersion = 2;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals() 

 /*
 / PARAMETER VALIDATION
 /----------------------------------------------------------------------------*/

 %let dsetin            = %nrbquote(&dsetin);
 %let dsetout           = %nrbquote(&dsetout);

 %let derivationyn      = %nrbquote(%upcase(%substr(&derivationyn, 1, 1)));
 %let attributesyn      = %nrbquote(%upcase(%substr(&attributesyn, 1, 1)));
 %let misschkyn         = %nrbquote(%upcase(%substr(&misschkyn, 1, 1)));

 /*
 / Check for required parameters.
 /----------------------------------------------------------------------------*/

 %if &dsetin eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter DSETIN is required.;
    %let g_abort=1;
 %end;

 %if &dsetout eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter DSETOUT is required.;
    %let g_abort=1;
 %end;

 %if &derivationyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter DERIVATIONYN is required.;
    %let g_abort=1;
 %end;

 %if &attributesyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter ATTRIBUTESYN is required.;
    %let g_abort=1;
 %end;

 /* ems002 */
 %if &misschkyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter MISSCHKYN is required.;
    %let g_abort=1;
 %end;

 /*
 / Check for valid parameter values.
 /----------------------------------------------------------------------------*/

 %if &derivationyn ne Y and &derivationyn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: DERIVATIONYN should be either Y or N.;
    %let g_abort=1;
 %end;

 %if &attributesyn ne Y and &attributesyn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: ATTRIBUTESYN should be either Y or N.;
    %let g_abort=1;
 %end;

 /* ems002 */
 %if &misschkyn ne Y and &misschkyn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: MISSCHKYN should be either Y or N.;
    %let g_abort=1;
 %end;

 /*
 / If the input dataset name is the same as the output dataset name,
 / write an error to the log.
 /----------------------------------------------------------------------------*/

 %if %qscan(&dsetin, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The input dataset name DSETIN(=&dsetin) is the same as the output dataset name DSETOUT(=&dsetout).;
    %let g_abort=1;
 %end;

 /*
 / Check for existing datasets.
 /----------------------------------------------------------------------------*/

 %if &dsetin ne %then    
    %if %tu_nobs(&dsetin) lt 0 %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: Data set DSETIN(=&dsetin) does not exist.;
       %let g_abort=1;
    %end;

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;

 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/

 %local prefix;
 %let prefix = _tc_tmslice;   /* Root name for temporary work datasets */

 /*
 / Initialise counter for appending to temporary dataset names for the
 / purpose of tracking datasets through a number of optional sequential
 / data processing steps.
 /----------------------------------------------------------------------------*/

 %local i;
 %let i = 1;

 /*
 / Dataset specific derivations.
 /----------------------------------------------------------------------------*/

 %if &derivationyn eq Y %then
 %do;
    %tu_derive (
         dsetin            = &dsetin,
         dsetout           = &prefix._ds&i,
         domaincode        = ts,                     /* Domain Code - type of dataset */
         noderivevars      = &noderivevars           /* List of variables not to derive */
    );
 %end;
 %else
 %do;
    data &prefix._ds&i;
         set %unquote(&dsetin);
    run;
 %end;

 /*
 / ems003
 / Reconcile A&R dataset with planned A&R dataset.
 /----------------------------------------------------------------------------*/

 %if &attributesyn eq Y %then
 %do;
    %tu_attrib(
         dsetin        = &prefix._ds&i,
         dsetout       = &dsetout,
         dsplan        = &dsplan,
         dsettemplate  = &dsettemplate,
         sortorder     = &sortorder
    );
 %end;
 %else
 %do;
    data %unquote(&dsetout);
      set &prefix._ds&i;
    run;
 %end;

 /*
 / ems002
 / Call tu_misschk macro in order to identify any variables in the 
 / &DSETOUT dataset which have missing values on all records.
 /----------------------------------------------------------------------------*/

 %if &misschkyn eq Y %then
 %do;
    %tu_misschk(
         dsetin        = &dsetout
    );
 %end;

 /*
 / Delete temporary datasets used in this macro.
 /----------------------------------------------------------------------------*/

 %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tc_tmslice;
