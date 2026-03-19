/*******************************************************************************
|
| Macro Name:      tc_cycle
|
| Macro Version:   1
|
| SAS Version:     8.2
|
| Created By:      Mark Luff / Eric Simms
|
| Date:            30-Jun-2004
|
| Macro Purpose:   CYCLE wrapper macro
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                            REQ/OPT  DEFAULT
| -----------------  -------------------------------------  -------  ----------
| EXPOSUREDSET       Specifies the EXPOSURE-format SI       OPT      DMDATA.EXPOSURE
|                    dataset which is used to create the 
|                    output CYCLE-format A&R dataset.
|                    Valid values: valid dataset name 
|
| VISITDSET          Specifies the VISIT-format SI dataset  REQ      DMDATA.VISIT
|                    which will be used along with the 
|                    EXPOSUREDSET to produce a CYCLE-format 
|                    A&R dataset.
|                    Valid values: valid dataset name    
|
| DSETOUT            Specifies the name of the output       REQ      ARDATA.CYCLE
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
| DATETIMEYN         Call %tu_datetm to derive datetime     REQ      Y
|                    variables?
|                    Valid values: Y, N
|
| DECODEYN           Call %tu_decode to decode coded        REQ      Y
|                    variables?
|                    Valid values: Y, N
|
| DERIVATIONYN       Call %tu_derive to perform specific    REQ      Y
|                    derivations for this domain code (CY)?
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
|                    in all records.
|                    Valid values: Y, N
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
| REFDATESOURCEDSET  Required if REFDATEOPTION is OTHER.    OPT      (Blank)
|                    Use the variable REFDATESOURCEVAR 
|                    from the REFDATESOURCEDSET.
|
| REFDATESOURCEVAR   Required if REFDATEOPTION is OTHER.    OPT      (Blank)
|                    Use the variable REFDATESOURCEVAR 
|                    from the REFDATESOURCEDSET.
|
| REFDATEDSETSUBSET  Where clause applied to source         OPT      (Blank)
|                    dataset. May be used regardless of the 
|                    value of REFDATEOPTION in order to 
|                    better select the reference date.
|
| TRTCDINF           Name of pre-existing informat to       OPT      (Blank)
|                    derive TRTCD from TRTGRP.
|
| PTRTCDINF          Name of pre-existing informat to       OPT      (Blank)
|                    derive PTRTCD from PTRTGRP.
|
| DSPLAN             Specifies the path and file name of    OPT      &g_dsplanfile
|                    the HARP A&R dataset metadata. This 
|                    will define the attributes to use 
|                    to define the A&R dataset.
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
|
| Example:
|    %tc_cycle(
|         refdateoption   = visit,
|         refdatevisitnum = 10,
|         dsplan          = &g_dsplanfile
|         );
|
|******************************************************************************
| Change Log
|
| Modified By:               Yongwei Wang
| Date of Modification:      27-Apr-2005
| New version/draft number:  1/2
| Modification ID:           YW001
| Reason For Modification:   1. Added derivation of CYCENDT, CYCENTM
|                            2. Droped _tstdt, _tsttm and _tmtdm from output 
|                               data set.
|
*******************************************************************************
| Modified By:
| Date of Modification:
| New version/draft number:
| Modification ID:
| Reason For Modification:
|
*******************************************************************************/
%macro tc_cycle (
     exposuredset      = DMDATA.EXPOSURE, /* EXPOSURE Input dataset name */
     visitdset         = DMDATA.VISIT,    /* VISIT Input dataset name */
     dsetout           = ARDATA.CYCLE,    /* Output dataset name */

     commonvarsyn      = Y,          /* Add common variables */
     treatvarsyn       = Y,          /* Add treatment variables */
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

 %let exposuredset      = %nrbquote(&exposuredset);
 %let visitdset         = %nrbquote(&visitdset);
 %let dsetout           = %nrbquote(&dsetout);

 %let commonvarsyn      = %nrbquote(%upcase(%substr(&commonvarsyn, 1, 1)));
 %let treatvarsyn       = %nrbquote(%upcase(%substr(&treatvarsyn, 1, 1)));
 %let datetimeyn        = %nrbquote(%upcase(%substr(&datetimeyn, 1, 1)));
 %let decodeyn          = %nrbquote(%upcase(%substr(&decodeyn, 1, 1)));
 %let derivationyn      = %nrbquote(%upcase(%substr(&derivationyn, 1, 1)));
 %let attributesyn      = %nrbquote(%upcase(%substr(&attributesyn, 1, 1)));
 %let misschkyn         = %nrbquote(%upcase(%substr(&misschkyn, 1, 1)));

 /*
 / Check for required parameters.
 /----------------------------------------------------------------------------*/

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

 %if &treatvarsyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter TREATVARSYN is required.;
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

 %if &exposuredset ne  %then
 %do;
    %if %sysfunc(exist(&exposuredset)) eq 0 %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: EXPOSUREDSET dataset &exposuredset does not exist.;
    %let g_abort=1;
    %end;
 %end;

 %if %sysfunc(exist(&visitdset)) eq 0 %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: VISITDSET dataset &visitdset does not exist.;
    %let g_abort=1;
 %end;

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
 / If variable CYCLE is not on the VISITDSET dataset, then we cannot process 
 / anything. Give an error message and halt.
 /----------------------------------------------------------------------------*/

 %if %tu_chkvarsexist(&visitdset, cycle) ne  %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The variable CYCLE must be on the &VISITDSET dataset: &visitdset;
    %let g_abort=1;
 %end;

 /*
 / If one of the input dataset names is the same as the output dataset name,
 / write an error to the log.
 /----------------------------------------------------------------------------*/

 %if &exposuredset=&dsetout %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The exposure dataset name (&exposuredset) is the same as the output dataset name (&dsetout).;
    %let g_abort=1;
 %end;

 %if &visitdset=&dsetout %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The visit dataset name (&visitdset) is the same as the output dataset name (&dsetout).;
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
 %let prefix = _tc_cycle;   /* Root name for temporary work datasets */

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
         dsetin            = &visitdset,
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
       set &visitdset;
    run;
 %end;

 /*
 / Check for use of visit times 
 /----------------------------------------------------------------------------*/

 %local exist_visittm visittm;
 %let exist_visittm=%tu_chkvarsexist(&prefix._ds&i, visittm);
 %if &exist_visittm ne  %then %let visittm=;
 %else %let visittm=VISITTM;

 /*
 / Order visit records by cycle and visit dates/times.
 /----------------------------------------------------------------------------*/

 proc sort data=&prefix._ds&i(where = (cycle ne . and visitdt ne .));
      by studyid subjid cycle visitdt &visittm;
 run;

 /*
 / Set cycle start date/time to the first visit date/time within each cycle.
 /----------------------------------------------------------------------------*/

 data &prefix._ds%eval(&i+1);
      set &prefix._ds&i;
      by studyid subjid cycle;

      if first.cycle;

      cycstdt = visitdt;
      drop visitdt;

      %if &exist_visittm ne  %then
      %do;
         cycsttm = visittm;
         /* Number of seconds in a day = 24 hours * 60 minutes * 60 seconds = 86400 */
         if cycstdt ne . and cycsttm ne . then cycstdm=(86400*cycstdt) + cycsttm; 
         drop visittm;
      %end;
 run;

 %let i = %eval(&i + 1);

 /*
 / Obtain treatment start and stop dates/times within cycles by adding 
 / date/time of next cycle to each record, and matching up treatments which 
 / fit into those ranges (from start of cycle to the start of next cycle). 
 /----------------------------------------------------------------------------*/

 %if %sysfunc(exist(&exposuredset)) ne 0 %then
 %do;
    /* Treatment data exists */

    /* Order by reverse cycle number */
    proc sort data=&prefix._ds&i;
         by studyid subjid decending cycle;
    run;

    /* Obtain cycle date/time from last record */
    data &prefix._ds%eval(&i+1);
         set &prefix._ds&i;
         by studyid subjid;

         %if &visittm eq  %then 
         %do;
             cycstdt = lag(cycstdt) - 1;
         %end;
         %else
         %do;      
             format cycentm time5.; 
             cycentm = lag(cycsttm);   
             
             if cycentm ne '00:00'T then cycendt = lag(cycstdt);
             else cycendt = lag(cycstdt) - 1;
             
             cycentm = cycsttm - 1;
         %end;
    run;

    %let i = %eval(&i + 1);

    /*
    / For last cycle of each subject, date set to 10000 days   
    / after start of cycle, time to set to zero, if applicable.
    /----------------------------------------------------------------------------*/

    data &prefix._ds%eval(&i+1);
         set &prefix._ds&i;
         by studyid subjid;

         if first.subjid then cycendt = cycstdt + 10000;

         %if &exist_visittm ne  %then
         %do;
             if first.subjid then cycentm = 0;
         %end;
    run;

    %let i = %eval(&i + 1);

    /*
    / Check for existence of start and end times of treatment.
    /----------------------------------------------------------------------------*/

    %local exist_exsttm exsttm;
    %let exist_exsttm=%tu_chkvarsexist(&exposuredset, exsttm);
    %if &exist_exsttm ne  %then %let exsttm=;
    %else %let exsttm=EXSTTM;

    %local exist_exentm exentm;
    %let exist_exentm=%tu_chkvarsexist(&exposuredset, exentm);
    %if &exist_exentm ne  %then %let exentm=;
    %else %let exentm=EXENTM;

    proc sql noprint;
         create table &prefix._ds%eval(&i+1) as

         %if &visittm eq  or &exsttm eq  %then
         %do;
             /* Visit times or treatment times not used */
             select a.*, b.exstdt as _tstdt, b.exendt as cyctendt
             from &prefix._ds&i as a left join &exposuredset as b
             on  a.studyid eq b.studyid
             and a.subjid  eq b.subjid
             and a.cycstdt le b.exstdt
             and a.cycendt ge b.exendt
             and b.exstdt is not null;
         %end;

         %else %if &visittm ne  and
                   &exsttm  ne  and
                   &exentm  ne  %then 
         %do;
             /* Visit times and treatment start/stop times used.                        */
             /* Number of seconds in a day = 24 hours * 60 minutes * 60 seconds = 86400 */
             select a.*, b.exstdt as _tstdt, b.exsttm as _tsttm,
                         b.exendt as cyctendt, b.exentm as cyctentm,
                         86400*b.exstdt+b.exsttm as _tstdm,
                         86400*b.exendt+b.exentm as cyctendm
             from &prefix._ds&i as a left join &exposuredset as b
             on  a.studyid eq b.studyid
             and a.subjid  eq b.subjid
             and ( (a.cycstdt lt b.exstdt) or (a.cycstdt eq b.exstdt and a.cycsttm le b.exsttm) )
             and ( (a.cycendt gt b.exendt) or (a.cycendt eq b.exendt and a.cyctm ge b.exentm) )
             and b.exstdt is not null;
         %end;

         %else %if &visittm ne  and &exsttm ne  %then 
         %do;
             /* Visit times and treatment start times used.                             */
             /* Number of seconds in a day = 24 hours * 60 minutes * 60 seconds = 86400 */
             select a.*, b.exstdt as _tstdt, b.exsttm as _tsttm,
                         86400*b.exstdt+b.exsttm as _tstdm,
                         b.exendt as cyctendt
             from &prefix._ds&i as a left join &exposuredset as b
             on  a.studyid eq b.studyid
             and a.subjid  eq b.subjid
             and ( (a.cycstdt lt b.exstdt) or (a.cycstdt eq b.exstdt and a.cycsttm le b.exsttm) )
             and a.cycendt ge b.exendt
             and b.exstdt is not null;
         %end;

         %let i = %eval(&i + 1);
    quit;

    /* Check for existence of treatment start time */

    %local exist__tsttm _tsttm;
    %let exist__tsttm=%tu_chkvarsexist(&prefix._ds&i, _tsttm);
    %if &exist__tsttm ne  %then %let _tsttm=;
    %else %let _tsttm=_TSTTM;

    proc sort data=&prefix._ds&i;
         by studyid subjid cycle _tstdt &_tsttm;
    run;

    data &prefix._ds%eval(&i+1);
         set &prefix._ds&i;
         by studyid subjid cycle;

         retain cyctstdt
                %if &_tsttm ne  %then 
                %do;
                    cyctsttm cyctstdm
                %end;
         ;
         drop _tstdt;
         %if &_tsttm ne  %then 
         %do;
             drop _tsttm _tstdm;
         %end;
        
         if first.cycle then
         do;
            cyctstdt = _tstdt;
            %if &_tsttm ne  %then 
            %do;
                cyctsttm = _tsttm;
                cyctstdm = _tstdm;
            %end;
         end;

         if last.cycle then output;
    run;

    %let i = %eval(&i + 1);

 %end; /* Treatment data exists */

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
         domaincode        = cy,                     /* Domain Code - type of dataset */
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

%mend tc_cycle;

