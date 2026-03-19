/*******************************************************************************
|
| Macro Name:      tc_period
|
| Macro Version:   2
|
| SAS Version:     8.2
|
| Created By:      Mark Luff / Eric Simms
|
| Date:            30-Jun-2004
|
| Macro Purpose:   PERIOD wrapper macro
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                            REQ/OPT  DEFAULT
| -----------------  -------------------------------------  -------  ----------
| EXPOSUREDSET       Specifies the EXPOSURE SI dataset      OPT      DMDATA.EXPOSURE
|                    which will be used along with the
|                    TMSLICEDSET and VISITDSET datasets
|                    to produce a PERIOD A&R dataset.
|                    Valid values: valid dataset name.
|
| TMSLICEDSET        Specifies the TMSLICEDSET SI dataset   REQ      DMDATA.TMSLICE 
|                    which will be used along with the
|                    EXPOSUREDSET and VISITDSET datasets
|                    to produce a PERIOD A&R dataset.
|                    Valid values: valid dataset name.
|
| VISITDSET          Specifies the VISIT SI dataset         REQ      DMDATA.VISIT   
|                    which will be used along with the
|                    EXPOSUREDSET and TMSLICEDSET datasets
|                    to produce a PERIOD A&R dataset.
|                    Valid values: valid dataset name.
|
| DSETOUT            Specifies the name of the output       REQ      ARDATA.PERIOD
|                    dataset to be created.
|                    Valid values: valid dataset name.
|
| COMMONVARSYN       Call %tu_common to add common          REQ      Y
|                    variables?                       
|                    Valid values: Y, N.              
|
| DATETIMEYN         Call %tu_datetime to derive            REQ      Y
|                    datetime variables?              
|                    Valid values: Y, N.              
|
| DERIVATIONYN       Call %tu_derive to perform specific    REQ      Y
|                    for this domain code (PR)?       
|                    Valid values: Y, N.              
|
| ATTRIBUTESYN       Call %tu_attrib to assign the          REQ      Y
|                    A&R-defined attribute to the output
|                    dataset.
|                    Valid values: Y, N.              
|
| MISSCHKYN          Call %tu_misschk to print RTWARNING    REQ      Y
|                    messages for each variable in 
|                    &DSETOUT which has missing values
|                    on all records.                    
|                    Valid values: Y, N.              
|
| DSPLAN             Specifies the path and file name of    OPT      &g_dsplanfile
|                    the HARP A&R dataset metadata. This 
|                    will define the attributes to use to 
|                    define the A&R dataset.
|                    NOTE: If DSPLAN is not specified (i.e.
|                          left to its default value) or
|                          is specified as anything other
|                          than blank, then both 
|                          DSETTEMPLATE and SORTORDER must
|                          not be specified as anything
|                          non-blank. If DSETTEMPLATE and 
|                          SORTORDER are specified as 
|                          anything non-blank, then DSPLAN
|                          must be specified as blank 
|                          (DSPLAN=,).
|
| DSETTEMPLATE       Specifies the name to give to the      OPT      (Blank)
|                    empty dataset containing the variables 
|                    and attributes desired for the A&R 
|                    dataset.
|                    NOTE: If DSETTEMPLATE is specified as
|                          anything non-blank, then DSPLAN
|                          must be specified as blank
|                          (DSPLAN=,).
|
| SORTORDER          Specifies the sort order desired for   OPT      (Blank)
|                    the A&R dataset.
|                    NOTE: If SORTORDER is specified as
|                          anything non-blank, then DSPLAN
|                          must be specified as blank
|                          (DSPLAN=,).
|
| NODERIVEVARS       List of domain-specific variables not  OPT      (Blank)
|                    to derive when %tu_derive is called.
| -----------------  -------------------------------------  -------  ----------
|
| The macro references the following datasets :-
| ------------------  -------  ------------------------------------------------
| Name                Req/Opt  Description
| ------------------  -------  ------------------------------------------------
| &EXPOSUREDSET       Opt      Parameter specified dataset
| &TMSLICEDSET        Req      Parameter specified dataset
| &VISITDSET          Req      Parameter specified dataset
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
|(@) tu_chkvarsexist
|(@) tu_common
|(@) tu_datetm
|(@) tu_derive
|(@) tu_misschk
|(@) tu_nobs
|(@) tu_pernum
|(@) tu_putglobals
|(@) tu_tidyup
|
| Example:
|    %tc_period(
|         dsplan = &g_dsplanfile
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
| Modified By:              Ian Barretto
| Date of Modification:     03-Mar-2010
| New version/draft number: 2/2
| Modification ID:          IB001
| Reason For Modification:  Correct bug when issuing RTWARNING if exposure
|                           dataset (EXPOSUREDSET) is provided but does not exist
|                           (Change Request HRT0241)
|                           
| Modified By:              
| Date of Modification:     
| New version/draft number: 
| Modification ID:          
| Reason For Modification:  
|                           
*******************************************************************************/
%macro tc_period (
     exposuredset      = DMDATA.EXPOSURE, /* Exposure dataset name */
     tmslicedset       = DMDATA.TMSLICE,  /* Time slice dataset name */
     visitdset         = DMDATA.VISIT,    /* Visit dataset name */
     dsetout           = ARDATA.PERIOD,   /* Output dataset name */
     commonvarsyn      = Y,       /* Add common variables */
     datetimeyn        = Y,       /* Derive datetime variables */
     derivationyn      = Y,       /* Dataset specific derivations */
     attributesyn      = Y,       /* Reconcile A&R dataset with planned A&R dataset */
     misschkyn         = Y,       /* Print warning message for variables in &DSETOUT with missing values on all records */ 
     dsplan            = &G_DSPLANFILE, /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
     dsettemplate      = ,        /* Planned A&R dataset template name */
     sortorder         = ,        /* Planned A&R dataset sort order */
     noderivevars      =          /* List of variables not to derive */
        );

 /*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion;
 %let MacroVersion = 2 build 2;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals() 

 %local prefix;
 %let prefix = _tc_period;   /* Root name for temporary work datasets */

 /*
 / PARAMETER VALIDATION
 /----------------------------------------------------------------------------*/

 %let exposuredset      = %nrbquote(&exposuredset);
 %let tmslicedset       = %nrbquote(&tmslicedset);
 %let visitdset         = %nrbquote(&visitdset);
 %let dsetout           = %nrbquote(&dsetout);

 %let commonvarsyn      = %nrbquote(%upcase(%substr(&commonvarsyn, 1, 1)));
 %let datetimeyn        = %nrbquote(%upcase(%substr(&datetimeyn, 1, 1)));
 %let derivationyn      = %nrbquote(%upcase(%substr(&derivationyn, 1, 1)));
 %let attributesyn      = %nrbquote(%upcase(%substr(&attributesyn, 1, 1)));
 %let misschkyn         = %nrbquote(%upcase(%substr(&misschkyn, 1, 1)));

 /*
 / Check for required parameters.
 /----------------------------------------------------------------------------*/

 %if &tmslicedset eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter TMSLICEDSET is required.;
    %let g_abort=1;
 %end;

 %if &visitdset eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter VISITDSET is required.;
    %let g_abort=1;
 %end;

 %if &dsetout eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter DSETOUT is required.;
    %let g_abort=1;
 %end;

 %if &commonvarsyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter COMMONVARSYN is required.;
    %let g_abort=1;
 %end;

 %if &datetimeyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter DATETIMEYN is required.;
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

 %if &misschkyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter MISSCHKYN is required.;
    %let g_abort=1;
 %end;

 /*
 / Check for valid parameter values.
 /----------------------------------------------------------------------------*/

 %if &commonvarsyn ne Y and &commonvarsyn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: COMMONVARSYN should be either Y or N.;
    %let g_abort=1;
 %end;

 %if &datetimeyn ne Y and &datetimeyn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: DATETIMEYN should be either Y or N.;
    %let g_abort=1;
 %end;

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

 %if &misschkyn ne Y and &misschkyn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: MISSCHKYN should be either Y or N.;
    %let g_abort=1;
 %end;

 /*
 / If one of the input dataset names is the same as the output dataset name,
 / write an error to the log.
 /----------------------------------------------------------------------------*/

 %if  %qscan(&exposuredset, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The exposure dataset name EXPOSUREDSET(=&exposuredset) is the same as the output dataset name DSETOUT(=&dsetout).;
    %let g_abort=1;
 %end;

 %if %qscan(&tmslicedset, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The tmslice dataset name TMSLICEDSET(=&tmslicedset) is the same as the output dataset name DSETOUT(=&dsetout).;
    %let g_abort=1;
 %end;

 %if %qscan(&visitdset, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The visit dataset name VISITDSET(=&visitdset) is the same as the output dataset name DSETOUT(=&dsetout).;
    %let g_abort=1;
 %end;
 
 /*
 / Check for existance of input data set.
 /----------------------------------------------------------------------------*/

 /*
 / IB001: 
 / 1. Change operator lt to le so that RTWARNING appears 
 / 2. Set EXPOSUREDSET to missing so that TU_PERNUM does not error if dataset
 /    is not provided.
 /----------------------------------------------------------------------------*/
 
 %if &exposuredset ne  %then
    %if %sysfunc(exist(%qscan(&exposuredset, 1, %str(%()))) le 0 %then
    %do;
       %put %str(RTW)ARNING: &sysmacroname: Data set EXPOSUREDSET(=&exposuredset) does not exist.;
       %put %str(RTW)ARNING: &sysmacroname: The following variables will not be derived: PERTSTDT, PERTSTTM, PERTENDT, PERTENTM.;
       %put %str(RTW)ARNING: &sysmacroname: The parameter EXPOSUREDSET(=&exposuredset) will be set to missing.;
       %let exposuredset=;
    %end;

 %if &tmslicedset ne %then                 
    %if %tu_nobs(&tmslicedset) lt 0 %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: Data set TMSLICEDSET(=&tmslicedset) does not exist.;
       %let g_abort=1;
    %end;
    %else %do;
    /*
    / If variables PERNUM/PERIOD are not on the TMSLICEDSET dataset, then we cannot  
    / process anything. Give an error message and halt.
    /----------------------------------------------------------------------------*/
       
       data &prefix.tmslice;
          set %unquote(&tmslicedset);
       run;

       %if %tu_chkvarsexist(&prefix.tmslice, pernum) ne  %then
       %do;
          %put %str(RTE)RROR: &sysmacroname: The variable PERNUM must be on the data set TMSLICEDSET(=&tmslicedset);
          %let g_abort=1;
       %end;

       %if %tu_chkvarsexist(&prefix.tmslice, period) ne  %then
       %do;
          %put %str(RTE)RROR: &sysmacroname: The variable PERIOD must be on the data set TMSLICEDSET(=&tmslicedset);
          %let g_abort=1;
        %end;
    %end;

 %if &visitdset ne %then
    %if %tu_nobs(&visitdset) lt 0 %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: Data set VISITDSET(=&visitdset) does not exist.;
       %let g_abort=1;
    %end;

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;

 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/

 /*
 / Initialise counter for appending to temporary dataset names for the
 / purpose of tracking datasets through a number of optional sequential
 / data processing steps.
 /----------------------------------------------------------------------------*/

 %local i;
 %let i = 1;

 /*
 / YW001: Call %tu_pernum to create a data set which contains variable PERENDT, 
 / PERENTM, PERIOD, PERNUM, PERSTDT, PERSTTM, PERTENDT, PERTENTM, PERTSTDT, 
 / PERTSTTM, STUDYID and SUBJID
 / Removed the normal process which did the same thing.
 /----------------------------------------------------------------------------*/
 
 %tu_pernum (
    dsetout      = &prefix._ds&i,   
    exposuredset = &exposuredset, 
    tmslicedset  = &tmslicedset,  
    visitdset    = &visitdset     
    ); 

  
 /*
 / Derive common variables.
 /----------------------------------------------------------------------------*/

 %if &commonvarsyn eq Y %then
 %do;
    %tu_common (
         dsetin  = &prefix._ds&i,
         dsetout = &prefix._ds%eval(&i+1)
    );

    %let i = %eval(&i + 1);
 %end;

 /*
 / Dataset specific derivations.
 /----------------------------------------------------------------------------*/

 %if &derivationyn eq Y %then
 %do;
    %tu_derive (
         dsetin            = &prefix._ds&i,
         dsetout           = &prefix._ds%eval(&i+1),
         domaincode        = pr,                     /* Domain Code - type of dataset */
         noderivevars      = &noderivevars           /* List of variables not to derive */
    );

    %let i = %eval(&i + 1);
 %end;

 /*
 / Derive datetime variables.
 /----------------------------------------------------------------------------*/

 %if &datetimeyn eq Y %then
 %do;
    %tu_datetm (
         dsetin  = &prefix._ds&i,
         dsetout = &prefix._ds%eval(&i+1)
    );

    %let i = %eval(&i + 1);
 %end;
 
 /*
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

%mend tc_period;
 
