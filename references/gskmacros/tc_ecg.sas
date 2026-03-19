/*******************************************************************************
|
| Macro Name:      tc_ecg
|
| Macro Version:   2
|
| SAS Version:     8.2
|
| Created By:      Eric Simms
|
| Date:            29-Jun-2004
|
| Macro Purpose:   ECG wrapper macro
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                            REQ/OPT  DEFAULT
| -----------------  -------------------------------------  -------  ----------
| DSETIN             Specifies the ECG-format SI dataset    REQ      DMDATA.ECG
|                    which needs to be transformed into an 
|                    ECG-format A&R dataset.
|                    Valid values: valid dataset name 
|
| DSETOUT            Specifies the name of the output       REQ      ARDATA.ECG
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
| RECALCVISITYN      Call %tu_recalcvisit to recalculate    REQ      N
|                    VISIT based on the AE start date?
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
|                    derivations for this domain code (EG)?
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
| XOVARSFORPGYN      Specifies whether to derive crossover stydy     N
|                    specific variables for parallel study                 
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
| REFDAT             Specify a reference date variable name OPT      EGDT
|                    to pass to %tu_recalcvisit to  
|                    calculate the visit. Will be checked  
|                    in %tu_recalcvisit
|
| REFTIM             Specify a reference time variable name OPT      EGACTTM
|                    to pass to %tu_recalcvisit to  
|                    calculate the visit. Will be checked  
|                    in %tu_recalcvisit
|
| REDERIVERRQTCBVYN  Re-derive RR, QTCB and QTCF even if    OPT      N
|                    they already exist in &DSETIN?
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
| DSPLAN             Specifies the path and file name of    OPT      &g_dsplanfile
|                    the HARP A&R dataset metadata. This 
|                    will define the attributes to use to 
|                    define the A&R dataset.
|                    NOTE: If DSPLAN is not specified
|                          (i.e. left to its default value),
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
|(@) tu_calctpernum
|(@) tu_chkvarsexist
|(@) tu_common
|(@) tu_datetm
|(@) tu_decode
|(@) tu_derive
|(@) tu_misschk
|(@) tu_putglobals
|(@) tu_rantrt
|(@) tu_recalcvisit
|(@) tu_tidyup
|(@) tu_timslc
|
| Example:
|    %tc_ecg(
|         refdateoption   = visit,
|         refdatevisitnum = 10,
|         dsplan          = &g_dsplanfile
|         );
|
|******************************************************************************
| Change Log
|
| Modified By:              Yongwei Wang
| Date of Modification:     23-Mar-2005
| New version/draft number: 1/2
| Modification ID:          YW001
| Reason For Modification:  Fixed typos on lines 375, 376, 386, and 387.
|
| Modified By:              Yongwei Wang
| Date of Modification:     04-Apr-2005
| New version/draft number: 1/3
| Modification ID:          YW002
| Reason For Modification:  Removed RR, QTCB, QTCF from &noderivevars
|
| Modified By:              Yongwei Wang
| Date of Modification:     18-Oct-05
| New version/draft number: 2/1
| Modification ID:          YW003
| Reason For Modification:  1. Added new parameter XOVARSFORPGYN, REFDAT, 
|                              REFTIM and RECALCVISITYN. 
|                           2. Added call of %tu_calctpernum
|                           3. Added call of %tu_recalvisityn
|                           4. Passed XOVARSFORPGYN to %tu_deriv
|                           5. Call %tu_datetm after %tu_derive
|
| Modified By:               
| Date of Modification:      
| New version/draft number:  
| Modification ID:           
| Reason For Modification:   
|
*******************************************************************************/
%macro tc_ecg (
     dsetin            = DMDATA.ECG, /* Input dataset name */
     dsetout           = ARDATA.ECG, /* Output dataset name */

     commonvarsyn      = Y,       /* Add common variables */
     treatvarsyn       = Y,       /* Add treatment variables */
     recalcvisityn     = N,       /* Recalculate visit based on the AE start date */
     timeslicingyn     = Y,       /* Add timeslicing variables */
     datetimeyn        = Y,       /* Derive datetime variables */
     decodeyn          = Y,       /* Decode coded variables */
     derivationyn      = Y,       /* Dataset specific derivations */
     attributesyn      = Y,       /* Reconcile A&R dataset with planned A&R dataset */
     misschkyn         = Y,       /* Print warning message for variables in &DSETOUT with missing values on all records */ 
     xovarsforpgyn     = N,       /* If derive crossover stydy specific variables for parallel study */
     agemonthsyn       = N,       /* Calculation of age in months */
     ageweeksyn        = N,       /* Calculation of age in weeks */
     agedaysyn         = N,       /* Calculation of age in days */
     rederiverrqtcbfyn = N,       /* re-derive RR, QTCB and QTCF even if they already exist in &DSETIN */
     refdat            = egdt,    /* Reference data variable name for recalculating visit and calculating treatment period */
     reftim            = egacttm, /* Reference data variable name for recalculating visit and calculating treatment period */
     refdateoption     = TREAT,   /* Reference date source option */
     refdatevisitnum   = ,        /* Reference date visit number */
     refdatesourcedset = ,        /* Reference date source dataset */
     refdatesourcevar  = ,        /* Reference date source variable */
     refdatedsetsubset = ,        /* Where clause applied to source dataset */
     trtcdinf          = ,        /* Informat to derive TRTCD from TRTGRP */
     ptrtcdinf         = ,        /* Informat to derive PTRTCD from PTRTGRP */
     dsplan            = &g_dsplanfile, /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
     dsettemplate      = ,        /* Planned A&R dataset template name */
     sortorder         = ,        /* Planned A&R dataset sort order */
     formatnamesdset   = ,        /* Format names dataset name */
     noderivevars      =          /* List of variables not to derive */
        );

 /*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion;
 %let MacroVersion = 2;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals() 

 %local addrryn addqtcbyn addqtcfyn notexistvars prefix loopi thisparm parmlist
        listvars thisvar;
 %let prefix = _tc_ecg;   /* Root name for temporary work datasets */

 /*
 / PARAMETER VALIDATION
 /----------------------------------------------------------------------------*/

 /*
 / Check for required parameters.
 /----------------------------------------------------------------------------*/
  
 %let listvars=DSETIN DSETOUT COMMONVARSYN TREATVARSYN TIMESLICINGYN DATETIMEYN 
               DECODEYN ATTRIBUTESYN MISSCHKYN DERIVATIONYN REDERIVERRQTCBFYN
               RECALCVISITYN XOVARSFORPGYN;
 
 %do loopi=1 %to 13;
    %let thisvar=%scan(&listvars, &loopi, %str( ));
    %let &thisvar=%nrbquote(&&&thisvar);
    
    %if &&&thisvar eq %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: The parameter &thisvar is required.;
       %let g_abort=1;
    %end;    
 %end;  /* end of do-to loop */
 
 /*
 / Check for Y/N parameter values.
 /----------------------------------------------------------------------------*/
 
 %let listvars=COMMONVARSYN TREATVARSYN TIMESLICINGYN DATETIMEYN DECODEYN  
               ATTRIBUTESYN MISSCHKYN DERIVATIONYN REDERIVERRQTCBFYN 
               RECALCVISITYN XOVARSFORPGYN;
 
 %do loopi=1 %to 11;
    %let thisvar=%scan(&listvars, &loopi, %str( ));
    %let &thisvar=%qupcase(%substr(&&&thisvar, 1, 1));
    
    %if (&&&thisvar ne Y) and (&&&thisvar ne N) %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: &thisvar should be either Y or N.;
       %let g_abort=1;
    %end;    
 %end;  /* end of do-to loop */

 %if %qupcase(&g_stype) eq XO %then %let XOVARSFORPGYN=Y;
 
 %let noderivevars=%qupcase(&noderivevars);                    /* YW002 */
 %if &derivationyn eq N %then %let noderivevars=RR QTCB QTCF;  /* YW002 */
 
 /*
 / Check for existing datasets.
 /----------------------------------------------------------------------------*/

 %if &dsetin ne %then
 %do;
    %if %sysfunc(exist(&dsetin)) eq 0 %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: The dataset DSETIN(=&dsetin) does not exist.;
       %let g_abort=1;
    %end;
 %end;

 /*
 / If the input dataset name is the same as the output dataset name,
 / write an error to the log.
 /----------------------------------------------------------------------------*/

 %if &dsetin eq &dsetout %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The input dataset name DSETIN(=&dsetin) is the same as the output dataset name DSETOUT(=&dsetout).;
    %let g_abort=1;
 %end;

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;
 
 /*
 / If &RECALCVISITYN equals Y or &XOVARSFORPGYN equals Y or &G_STYPE equals XO, 
 / and &REFTIM is not blank, check if &REFTIM exists in &DSETIN. If not, write 
 / a RTWARNING message to the log and set &REFTIM to blank, but do not abort
 /----------------------------------------------------------------------------*/
 
 %if ( (&recalcvisityn eq Y) or (&xovarsforpgyn eq Y) ) and (%nrbquote(&reftim) ne) %then 
 %do;      
    %if %tu_chkvarsexist(&dsetin, &reftim) ne %then 
    %do;   
       %put %str(RTW)ARNING: &sysmacroname: REFTIM (=&reftim) is given, but it does not exist in DSETIN (=&dsetin). Set it to blank;
       %let reftim=;
    %end;
 %end; /* end-if on  ( (&recalcvisityn eq Y) or (&xovarsforpgyn eq Y) ) and (%nrbquote(&reftim) ne) */

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
 / Derived variables: QTCB QTCF RR
 /----------------------------------------------------------------------------*/
 
 %let addrryn=Y;
 %let addqtcbyn=Y;
 %let addqtcfyn=Y;

 %let notexistvars=%upcase(%tu_chkvarsexist(&dsetin, eghr qt rr qtcb qtcf));
 
 /* 
 / If any of RR, QTCB and QTCF is in &NODERIVEVARS,do not derive it                               
 /----------------------------------------------------------------------------*/ 
 %if %sysfunc(indexw(&noderivevars, RR))   gt 0 %then %let addrryn=N;
 %if %sysfunc(indexw(&noderivevars, QTCB)) gt 0 %then %let addqtcbyn=N;
 %if %sysfunc(indexw(&noderivevars, QTCF)) gt 0 %then %let addqtcfyn=N; 
  
 /* 
 / If any of RR, QTCB and QTCF, which is used for derivation, is not in &dsetin and will 
 / not be derived, do not derive it 
 /----------------------------------------------------------------------------*/ 
 %if ( %sysfunc(indexw(&notexistvars, EGHR)) gt 0 ) %then %let addrryn=N;       
 %if ( %sysfunc(indexw(&notexistvars, QT))   gt 0 ) or ( &addrryn eq N ) %then 
 %do;
    %let addqtcfyn=N;   
    %let addqtcbyn=N;  
 %end;
 
 /*
 / If any of RR, QTCB and QTCF already exists, and no rederivation is 
 / required, do not derive it 
 /----------------------------------------------------------------------------*/   
 %if &rederiverrqtcbfyn eq N %then 
 %do;
    %if %sysfunc(indexw(&notexistvars, RR))   eq 0  %then %let addrryn=N;
    %if %sysfunc(indexw(&notexistvars, QTCB)) eq 0  %then %let addqtcbyn=N;
    %if %sysfunc(indexw(&notexistvars, QTCF)) eq 0  %then %let addqtcfyn=N;
 %end;
 
 /*
 / YW002: Remove RR, QTCB and QTCF from &noderivevars
 /----------------------------------------------------------------------------*/    
  
 %if %nrbquote(&noderivevars) ne %then 
 %do;
    %let noderivevars=%qsysfunc(tranwrd(&noderivevars, RR , %str()));
    %let noderivevars=%qsysfunc(tranwrd(&noderivevars, QTCB , %str()));
    %let noderivevars=%qsysfunc(tranwrd(&noderivevars, QTCF , %str()));  
 %end;
 
          
 data &prefix._ds&i;
    set &dsetin;
    
    %if &addrryn eq Y %then
    %do;
        rr=1/((eghr/60)/1000);   
    %end;
    
    %if &addqtcbyn eq Y %then
    %do;    
        qtcb=qt/((rr/1000) ** (1/2));
    %end;
    
    %if &addqtcfyn eq Y %then
    %do; 
       qtcf=qt/((rr/1000) ** (1/3));
    %end;
 run;

 /*
 / Add common variables.
 /----------------------------------------------------------------------------*/

 %if &commonvarsyn eq Y %then
 %do;
    %tu_common (
         dsetin            = &prefix._ds&i,
         dsetout           = &prefix._ds%eval(&i + 1),
         agemonthsyn       = &agemonthsyn,           /* Calculation of age in months */
         ageweeksyn        = &ageweeksyn,            /* Calculation of age in weeks */
         agedaysyn         = &agedaysyn,             /* Calculation of age in days */
         refdateoption     = &refdateoption,         /* Reference date source option */
         refdatevisitnum   = &refdatevisitnum,       /* Reference date visit number */
         refdatesourcedset = &refdatesourcedset,     /* Reference date source dataset */
         refdatesourcevar  = &refdatesourcevar,      /* Reference date source variable */
         refdatedsetsubset = &refdatedsetsubset      /* Where clause applied to source dataset */
    );

    %let i = %eval(&i + 1);
 %end;

 /*
 / Recalculate visit based on AE start date.
 /----------------------------------------------------------------------------*/

 %if &recalcvisityn eq Y %then
 %do;
    %tu_recalcvisit (
         dsetin  = &prefix._ds&i,
         dsetout = &prefix._ds%eval(&i+1),
         refdat  = &refdat,
         reftim  = &reftim
    );

    %let i = %eval(&i + 1);
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
 / If &G_STYPE eqyaks XO or &XOVARSFORPGYN equals Y, call %tu_calctpernum
 / add TPERIOD/TPERNUM.
 /----------------------------------------------------------------------------*/
  
 %if &XOVARSFORPGYN eq Y %then 
 %do;  
    %tu_calctpernum (
      dsetin      = &prefix._ds&i,                
      dsetout     = &prefix._ds%eval(&i+1),                
      exposuredset= dmdata.exposure, 
      refdat      = &refdat,                
      reftim      = &reftim,                
      tmslicedset = dmdata.tmslice,  
      visitdset   = dmdata.visit     
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
 / Dataset specific derivations.
 /----------------------------------------------------------------------------*/

 %if &derivationyn eq Y %then
 %do;
    %tu_derive (
         dsetin            = &prefix._ds&i,
         dsetout           = &prefix._ds%eval(&i+1),
         domaincode        = eg,                     /* Domain Code - type of dataset */
         noderivevars      = &noderivevars,          /* List of variables not to derive */
         refdateoption     = &refdateoption,         /* Reference date source option */
         refdatevisitnum   = &refdatevisitnum,       /* Reference date visit number */
         refdatesourcedset = &refdatesourcedset,     /* Reference date source dataset */
         refdatesourcevar  = &refdatesourcevar,      /* Reference date source variable */
         refdatedsetsubset = &refdatedsetsubset,     /* Where clause applied to source dataset */
         xovarsforpgyn     = &xovarsforpgyn     
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
 / Decode coded variables.
 /----------------------------------------------------------------------------*/

 %if &decodeyn eq Y %then
 %do;
    %tu_decode (
         dsetin          = &prefix._ds&i,
         dsetout         = &prefix._ds%eval(&i+1),
         dsplan          = &dsplan,
         formatnamesdset = &formatnamesdset,
         decoderename    = egchin=egchintp
    );

    %let i = %eval(&i + 1);
 %end;

 /*
 / Reconcile A&R dataset with planned A&R dataset.
 /----------------------------------------------------------------------------*/

 %if &attributesyn eq Y %then
 %do;
    %tu_attrib(
         dsetin          = &prefix._ds&i,
         dsetout         = &dsetout,
         dsplan          = &dsplan,
         dsettemplate    = &dsettemplate,
         sortorder       = &sortorder
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

%mend tc_ecg;

