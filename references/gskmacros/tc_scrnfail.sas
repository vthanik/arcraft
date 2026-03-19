/*******************************************************************************
|
| Macro Name:      tc_scrnfail
|
| Macro Version:   1
|
| SAS Version:     8.2
|
| Created By:      Eric Simms
|
| Date:            29-Jun-2004
|
| Macro Purpose:   Scrnfail wrapper macro
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                            REQ/OPT  DEFAULT
| -----------------  -------------------------------------  -------  ----------
| DSETIN             Specifies the SCRNFAIL-format SI       REQ      DMDATA.SCRNFAIL
|                    dataset which needs to be transformed 
|                    into a SCRNFAIL-format A&R dataset.
|                    Valid values: valid dataset name
|
| DSETOUT            Specifies the name of the output       REQ      ARDATA.SCRNFAIL
|                    dataset to be created.
|                    Valid values: valid dataset name 
|
| COMMONVARSYN       Call %tu_common to add common          REQ      Y
|                    variables?
|                    Valid values: Y, N
|
| TREATVARSYN        Call %tu_rantrt to add treatment       REQ      Y
|                    variables?
|                    Valid values: Y, N
|
| TIMESLICINGYN      Call %tu_timslc to add timeslicing     REQ      Y
|                    variables?
|                    Valid values: Y, N 
|
| DATETIMEYN         Call %tu_datetm to derive datetime     REQ      Y
|                    variables?
|                    Valid values: Y, N
|
| DECODEYN           Call %tu_decode to decode coded        REQ      Y
|                    variables?
|                    Valid values: Y, N
|
| DERIVATIONYN       Call %tu_derive to perform specific    REQ      Y
|                    derivations for this domain code (SF)?
|                    Valid values: Y, N
|
| ATTRIBUTESYN       Call %tu_attrib to reconcile the       REQ      Y
|                    A&R-defined attributes to the planned 
|                    A&R dataset?
|                    Valid values: Y, N
|
| MISSCHKYN          Call %tu_misschk to print RTWARNING    REQ      Y
|                    messages for each variable in 
|                    &DSETOUT which has missing values
|                    on all records.                    
|                    Valid values: Y, N.  
|
| AGEMONTHSYN        Calculate age in months?               OPT      N
|                    Valid values: Y, N
|
| AGEWEEKSYN         Calculate age in weeks?                OPT      N
|                    Valid values: Y, N
|
| AGEDAYSYN          Calculate age in days?                 OPT      N
|                    Valid values: Y, N
|
| REFDATEOPTION      The reference date will be used in     OPT      TREAT
|                    the calculation of the age values.
|                    Valid values:
|                    TREAT - Trt start date from 
|                            DMDATA.EXPOSURE
|                    VISIT - Visit date from 
|                            DMDATA.VISIT
|                    RAND  - Randomization date from 
|                            DMDATA.RAND
|                    OTHER - Date from the 
|                            REFDATESOURCEVAR variable on
|                            the REFDATESOURCEDSET dataset
|
| REFDATEVISITNUM    Specific visit number at which         OPT      (Blank)
|                    reference date is to be taken.  
|                    Required if REFDATEOPTION is VISIT.
|
| REFDATESOURCEDSET  Use the variable REFDATESOURCEVAR      OPT      (Blank)
|                    from the REFDATESOURCEDSET.
|                    Required if REFDATEOPTION is OTHER. 
|
| REFDATESOURCEVAR   Use the variable REFDATESOURCEVAR      OPT      (Blank)
|                    from the REFDATESOURCEDSET.
|                    Required if REFDATEOPTION is OTHER.  
|
| REFDATEDSETSUBSET  WHERE clause applied to source         OPT      (Blank)
|                    dataset.  May be used regardless of 
|                    the value of REFDATEOPTION in order 
|                    to better select the reference date.
|
| TRTCDINF           Name of pre-existing informat to       OPT      (Blank)
|                    derive TRTCD from TRTGRP.
|
| PTRTCDINF          Name of pre-existing informat to       OPT      (Blank)
|                    derive PTRTCD from PTRTGRP.
|                    
| DSPLAN             Specifies the path and file name of    OPT     &g_dsplanfile
|                    the HARP A&R dataset metadata. This 
|                    will define the attributes to use to 
|                    define the A&R dataset.
|                    NOTE: If DSPLAN is not specified
|                          i.e. left to its default value,
|                          or is specified as anything 
|                          other than blank, then 
|                          DSETTEMPLATE, SORTORDER and 
|                          FORMATNAMESDSET must not be
|                          specified as anything non-blank.
|                          If DSETTEMPLATE, SORTORDER and
|                          FORMATNAMESDSET are specified
|                          as anything non-blank, then
|                          DSPLAN must be specified as
|                          blank (DSPLAN=,).
|
| DSETTEMPLATE       Specifies the name to give to the      OPT      (Blank)
|                    empty dataset containing the variables 
|                    and attributes desired for the A&R 
|                    dataset.
|                    NOTE: If DSETTEMPLATE is specified
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
| FORMATNAMESDSET    Specifies the name of a dataset which  OPT      (Blank)
|                    contains VAR_NM (a variable name of a 
|                    code) and format_nm (the name of a 
|                    format to produce the decode).
|                    NOTE: If FORMATNAMESDSET is specified
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
|
| &FORMATNAMESDSET    Opt      Parameter specified dataset with variables:
|
|                              NAME       DESCRIPTION
|                              ---------  -------------------------------------
|                              VAR_NM     Variable name   (CD suffix)
|                              FORMAT_NM  SAS format name ($ prefix, e.g. $FMT)
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
|(@) tu_common
|(@) tu_datetm
|(@) tu_decode
|(@) tu_derive
|(@) tu_misschk
|(@) tu_putglobals
|(@) tu_rantrt
|(@) tu_tidyup
|(@) tu_timslc
|
| Example:
|    %tc_scrnfail(
|         refdateoption   = visit,
|         refdatevisitnum = 10,
|         dsplan          = &g_dsplanfile
|         );
|
|******************************************************************************
| Change Log
|
| Modified By:           
| Date of Modification:   
| New version/draft number:
| Modification ID:          
| Reason For Modification:
|
*******************************************************************************/
%macro tc_scrnfail (
     dsetin            = DMDATA.SCRNFAIL,  /* Input dataset name */
     dsetout           = ARDATA.SCRNFAIL,  /* Output dataset name */

     commonvarsyn      = Y,          /* Add common variables */
     treatvarsyn       = Y,          /* Add treatment variables */
     timeslicingyn     = Y,          /* Add timeslicing variables */
     datetimeyn        = Y,          /* Derive datetime variables */
     decodeyn          = Y,          /* Decode coded variables */
     derivationyn      = Y,          /* Dataset specific derivations */
     attributesyn      = Y,          /* Reconcile A&R dataset with planned A&R dataset */
     misschkyn         = Y,          /* Print warning message for variables in &DSETOUT with missing values on all records */
     agemonthsyn       = N,          /* Calculation of age in months */
     ageweeksyn        = N,          /* Calculation of age in weeks */
     agedaysyn         = N,          /* Calculation of age in days */
     refdateoption     = TREAT,      /* Reference date source option */
     refdatevisitnum   = ,           /* Reference date visit number */
     refdatesourcedset = ,           /* Reference date source dataset */
     refdatesourcevar  = ,           /* Reference date source variable */
     refdatedsetsubset = ,           /* Where clause applied to source dataset */
     trtcdinf          = ,           /* Informat to derive TRTCD from TRTGRP */
     ptrtcdinf         = ,           /* Informat to derive PTRTCD from PTRTGRP */
     dsplan            = &g_dsplanfile, /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
     dsettemplate      = ,           /* Planned A&R dataset template name */
     sortorder         = ,           /* Planned A&R dataset sort order */
     formatnamesdset   = ,           /* Format names dataset name */
     noderivevars      =             /* List of variables not to derive */
        );

 /*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion;
 %let MacroVersion = 1;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals() 

 /*
 / PARAMETER VALIDATION
 /----------------------------------------------------------------------------*/

 %let dsetin            = %nrbquote(&dsetin);
 %let dsetout           = %nrbquote(&dsetout);

 %let commonvarsyn      = %nrbquote(%upcase(%substr(&commonvarsyn, 1, 1)));
 %let treatvarsyn       = %nrbquote(%upcase(%substr(&treatvarsyn, 1, 1)));
 %let timeslicingyn     = %nrbquote(%upcase(%substr(&timeslicingyn, 1, 1)));
 %let datetimeyn        = %nrbquote(%upcase(%substr(&datetimeyn, 1, 1)));
 %let decodeyn          = %nrbquote(%upcase(%substr(&decodeyn, 1, 1)));
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

 %if &commonvarsyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter COMMONVARSYN is required.;
    %let g_abort=1;
 %end;

 %if &treatvarsyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter TREATVARSYN is required.;
    %let g_abort=1;
 %end;

 %if &timeslicingyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter TIMESLICINGYN is required.;
    %let g_abort=1;
 %end;

 %if &datetimeyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter DATETIMEYN is required.;
    %let g_abort=1;
 %end;

 %if &decodeyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter DECODEYN is required.;
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

 %if &treatvarsyn ne Y and &treatvarsyn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: TREATVARSYN should be either Y or N.;
    %let g_abort=1;
 %end;

 %if &timeslicingyn ne Y and &timeslicingyn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: TIMESLICINGYN should be either Y or N.;
    %let g_abort=1;
 %end;

 %if &datetimeyn ne Y and &datetimeyn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: DATETIMEYN should be either Y or N.;
    %let g_abort=1;
 %end;

 %if &decodeyn ne Y and &decodeyn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: DECODEYN should be either Y or N.;
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
 / Check for existing datasets.
 /----------------------------------------------------------------------------*/

 %if %sysfunc(exist(&dsetin)) eq 0 %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The dataset &dsetin does not exist.;
    %let g_abort=1;
 %end;

 /*
 / If the input dataset name is the same as the output dataset name,
 / write an error to the log.
 /----------------------------------------------------------------------------*/

 %if &dsetin=&dsetout %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The input dataset name (&dsetin) is the same as the output dataset name (&dsetout).;
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
 %let prefix = _tc_scrnfail;   /* Root name for temporary work datasets */

 /*
 / Initialise counter for appending to temporary dataset names for the
 / purpose of tracking datasets through a number of optional sequential
 / data processing steps.
 /----------------------------------------------------------------------------*/

 %local i;
 %let i = 1;

 /*
 / Add common variables.
 /----------------------------------------------------------------------------*/

 %if &commonvarsyn eq Y %then
 %do;
    %tu_common (
         dsetin            = &dsetin,
         dsetout           = &prefix._ds&i,
         agemonthsyn       = &agemonthsyn,           /* Calculation of age in months */
         ageweeksyn        = &ageweeksyn,            /* Calculation of age in weeks */
         agedaysyn         = &agedaysyn,             /* Calculation of age in days */
         refdateoption     = &refdateoption,         /* Reference date source option */
         refdatevisitnum   = &refdatevisitnum,       /* Reference date visit number */
         refdatesourcedset = &refdatesourcedset,     /* Reference date source dataset */
         refdatesourcevar  = &refdatesourcevar,      /* Reference date source variable */
         refdatedsetsubset = &refdatedsetsubset      /* Where clause applied to source dataset */
    );
 %end;
 %else
 %do;
    data &prefix._ds&i;
         set &dsetin;
    run;
 %end;

 /*
 / Add timeslicing variables.
 /----------------------------------------------------------------------------*/

 %if &timeslicingyn eq Y %then
 %do;
    %tu_timslc (
         dsetin  = &prefix._ds&i,
         dsetout = &prefix._ds%eval(&i+1)
    );

    %let i = %eval(&i + 1);
 %end;

 /*
 / Add treatment variables.
 /----------------------------------------------------------------------------*/

 %if &treatvarsyn eq Y %then
 %do;
    %tu_rantrt (
         dsetin    = &prefix._ds&i,
         dsetout   = &prefix._ds%eval(&i+1),
         trtcdinf  = &trtcdinf,
         ptrtcdinf = &ptrtcdinf
    );

    %let i = %eval(&i + 1);
 %end;

 /*
 / Decode coded variables.
 /----------------------------------------------------------------------------*/

 %if &decodeyn eq Y %then
 %do;
    %tu_decode (
         dsetin          = &prefix._ds&i,
         dsetout         = &prefix._ds%eval(&i+1),
         dsplan          = &dsplan,
         formatnamesdset = &formatnamesdset
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
         domaincode        = sf,                     /* Domain Code - type of dataset */
         noderivevars      = &noderivevars,          /* List of variables not to derive */
         refdateoption     = &refdateoption,         /* Reference date source option */
         refdatevisitnum   = &refdatevisitnum,       /* Reference date visit number */
         refdatesourcedset = &refdatesourcedset,     /* Reference date source dataset */
         refdatesourcevar  = &refdatesourcevar,      /* Reference date source variable */
         refdatedsetsubset = &refdatedsetsubset      /* Where clause applied to source dataset */
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
    data &dsetout;
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

%mend tc_scrnfail;
