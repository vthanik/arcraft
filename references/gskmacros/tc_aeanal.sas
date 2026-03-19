/*
| Macro Name:         tc_aeanal
|
| Macro Version:      1
|
| SAS Version:        8.2
|
| Created By:         Yongwei Wang
|
| Date:               25-Sep-2007
|
| Macro Purpose:      Adverse events analysis data set wrapper macro
|
| Macro Design:       Procedure Style
|
| Input Parameters:
|
| Name                Description                                  Default
| -----------------------------------------------------------------------------------
| DSETIN              Specifies the LAB-format SI dataset which    dmdata.ae
|                     needs to be transformed into a LAB-format
|                     A&R dataset.
|                     Valid values: valid dataset name
|
| DSETOUT             Specifies the name of the output dataset to  ardata.aeanal
|                     be created.
|                     Valid values: valid dataset name
|
| AEDETAILDSET        Specifies an SI-format AEDETAIL dataset to   dmdata.aedetail
|                     use for deriving AEANAL variables
|
| DEMODSET            Specifies an SI-format DEMO dataset to use   dmdata.demo
|                     for various derivations.
|
| ENROLDSET           Specifies an SI-format ENROL dataset to use  dmdata.enrol
|                     for various derivations.
|
| EXPOSUREDSET        Specifies an SI-format EXPOSURE dataset to   dmdata.exposure
|                     use for various derivations.
|
| INVESTIGDSET        Specifies an SI-format INVESTIG dataset to   dmdata.investig
|                     use for various derivations.
|
| RACEDSET            Specifies an SI-format RACE dataset to use   dmdata.race
|                     for various derivations.
|
| RANDALLDSET         Specifies an SI-format RANDALL dataset to    dmdata.randall
|                     use for various derivations.
|                     Note: This parameter is not used in the
|                     current version. It should be passed to
|                     %tu_acttrt in a future release.
|
| RANDDSET            Specifies an SI-format RAND dataset to use   dmdata.rand
|                     for various derivations.
|
| TMSLICEDSET         Specifies an SI-format TMSLICE dataset to    dmdata.tmslice
|                     use for various derivations.
|
| VISITDSET           Specifies an SI-format VISIT dataset to use  dmdata.visit
|                     for various derivations.
|
| ATTRIBUTESYN        Call %tu_attrib to reconcile the             Y
|                     A&R-defined attributes to the planned A&R
|                     dataset?
|                     Valid values: Y, N
|
| COMMONVARSYN        Call %tu_common to add common variables?     Y
|                     Valid values: Y, N
|
| DATETIMEYN          Call %tu_datetm to derive datetime           Y
|                     variables?
|                     Valid values: Y, N
|
| DECODEYN            Call %tu_decode to decode coded variables?   Y
|                     Valid values: Y, N
|
| DERIVATIONYN        Call %tu_derive to perform specific          Y
|                     derivations for this domain code (LB)?
|                     Valid values: Y, N
|
| MISSCHKYN           Call %tu_misschk to print RTWARNING          Y
|                     messages for each variable in &DSETOUT
|                     which has missing values on all records.
|                     Valid values: Y, N
|
| RECALCVISITYN       Call %tu_recalcvisit to recalculate          N
|                     VISITNUM based on the AE start date?
|                     Valid values: Y, N
|
| TIMESLICINGYN       Call %tu_timslc to add timeslicing           Y
|                     variables?
|                     Valid values: Y, N
|
| TREATVARSYN         Call %tu_rantrt to add treatment variables?  Y
|                     Valid values: Y, N
|
| XOVARSFORPGYN       Specifies whether to derive crossover study  N
|                     specific variables for parallel study
|                     Valid values: Y, N.
|
| AGEDAYSYN           Calculate age in days?                       N
|                     Valid values: Y, N
|
| AGEMONTHSYN         Calculate age in months?                     N
|                     Valid values: Y, N
|
| AGEWEEKSYN          Calculate age in weeks?                      N
|                     Valid values: Y, N
|
| REFDAT              Specify a reference date variable name to    adstdt
|                     pass to %tu_recalcvisit to calculate the
|                     visit. Will be checked in %tu_recalcvisit
|
| REFTIM              Specify a reference time variable name to    (Blank)
|                     pass to %tu_recalcvisit to calculate the
|                     visit. Will be checked in %tu_recalcvisit
|
| REFDATEOPTION       This reference date will be used in the      TREAT
|                     calculation of the age values, in
|                     tu_common.
|                     TREAT -  Trt start date from DMDATA.EXPOSURE
|                     VISIT -  Visit date from DMDATA.VISIT
|                     RAND  -  Randomization date from DMDATA.RAND
|                     OTHER    Date from the REFDATESOURCEVAR
|                     variable on the REFDATESOURCEDSET Dataset
|
| REFDATEVISITNUM     Specific visit number at which reference     (Blank)
|                     date is to be taken for tu_common.
|                     Used if REFDATEOPTION is VISIT.
|
| REFDATESOURCEDSET   The dataset that contains the date used for  (Blank)
|                     Age calculations in tu_common.
|                     Used if REFDATEOPTION is OTHER.
|
| REFDATESOURCEVAR    The variable in REFDATESOURCEDSET that       (Blank)
|                     contains the reference date used for Age
|                     calculations, in tu_common.
|                     Used if REFDATEOPTION is OTHER.
|
| REFDATEDSETSUBSET   WHERE clause applied to source dataset for   (Blank)
|                     tu_common.
|                     Used to specify a subset of the reference
|                     dataset for tu_common to better select the
|                     reference date.
|                     This may be used regardless of the value of
|                     REFDATEOPTION.
|
| DYREFDATEOPTION     Reference date source option for tu_derive.  treat
|                     Specifies how to derive the reference date
|                     for the computation of actual study days,
|                     in tu_derive.
|                     TREAT -  Trt start date from DMDATA.EXPOSURE
|                     VISIT -  Visit date from DMDATA.VISIT
|                     RAND  -  Randomization date from DMDATA.RAND
|                     OTHER    Date from the DYREFDATESOURCEVAR
|                     variable on the DYREFDATESOURCEDSET Dataset
|
| DYREFDATEVISITNUM   Specific visit number at which the           (Blank)
|                     reference date is to be taken for
|                     tu_derive.
|                     Used when DYREFDATEOPTION is VISIT.
|
| DYREFDATESOURCEDSE  The dataset that contains the date used for  (Blank)
| T                   Study Day calculations in tu_derive.
|                     Used when DYREFDATEOPTION is OTHER.
|
| DYREFDATESOURCEVAR  The variable in DYREFDATESOURCEDSET that     (Blank)
|                     contains the reference date used for Study
|                     Day calculations, in tu_derive.
|                     Used when DYREFDATEOPTION is OTHER.
|
| DYREFDATEDSETSUBSE  WHERE clause applied to reference dataset    (Blank)
| T                   for tu_derive.
|                     Used to specify a subset of the reference
|                     dataset for tu_derive to better select the
|                     reference date.
|                     This may be used regardless of the value of
|                     DYREFDATEOPTION.
|
| ADWINDOWSUBSET      Specifies a condition statement wichih can   (Blank)
|                     be used in if statement to define ADWINDOW.
|                     If statement is meet, ADWINDOW=Y, else
|                     ADWINDOW=N.
|
| DURATIONUNITS       Specifies the Units of event duration,       Days
|                     time from first dose, time from last dose
|                     time from treatment period first dose
|
|                     Valid values: MINUTES, HOURS, DAYS, WEEKS,
|                     MONTHS, YEARS or a list of combination of
|                     units listed above wiht variable name in
|                     fomrat UNIT(Variable). If (Variable) is not
|                     given, the unit will be take as default
|                     units.
|                     Otherwise, the Unit is for the given
|                     variable
|                     only.
|
| DSETTEMPLATE        Specifies the name of the empty dataset      (Blank)
|                     containing the variables and attributes
|                     desired for the A&R dataset.
|                     NOTE: If DSETTEMPLATE is specified as
|                     anything non-blank, then DSPLAN must be
|                     specified as blank (DSPLAN=,).
|
| DSPLAN              Specifies the path and file name of the      &g_dsplanfile
|                     tab-delimited HARP A&R dataset metadata.
|                     This will define the attributes to use to
|                     define the A&R dataset.
|                     NOTE: If DSPLAN is not specified (i.e. left
|                     to its default value), or is specified as
|                     anything other than blank, then both
|                     DSETTEMPLATE and SORTORDER must be blank.
|                     If DSETTEMPLATE and SORTORDER are specified
|                     as anything non-blank, then DSPLAN must be
|                     specified as blank (DSPLAN=,).
|
| FORMATNAMESDSET     Specifies the name of a dataset which        (Blank)
|                     contains VAR_NM (a variable name of a code)
|                     and format_nm (the name of a format to
|                     produce the decode).
|
| SORTORDER           Specifies the sort order desired for the     (Blank)
|                     A&R dataset.
|                     NOTE: If SORTORDER is specified as anything
|                     non-blank, then DSPLAN must be specified as
|                     blank (DSPLAN=,).
|
| TRTCDINF            Name of pre-existing informat to derive      (Blank)
|                     TRTCD from TRTGRP
|
| PTRTCDINF           Name of pre-existing informat to derive      (Blank)
|                     PTRTCD from PTRTGRP.
|
| DECODERENAME        DECODERENAME      By default, a coded        aeactr=aeacttrt 
|                     variable named  ZZZcd will produce a         aetxhv=aetoxhiv
|                     decoded variable ZZZ.  This can be changed   adtxhv=adtoxhiv
|                     by using                  this parameter,    adptxh=adptxhiv
|                     i.e.            decoderename=zzz=abc_text    adactr=adacttrt
|                     will create the decode of ZZZcd in a
|                     variable named ABC_TEXT.
|
| DECODEPAIRS         Specifies code and decode variables in       (Blank)
|                     pair. The decode variables will be created
|                     and populated with format value of the code
|                     variable. The format is defined in &DSPLAN
|                     file.
|
| NODERIVEVARS        List of domain-specific variables not to     (Blank)
|                     derive when %tu_derive is called.

|
| NAME               DESCRIPTION                            REQ/OPT  DEFAULT
| -----------------  -------------------------------------  -------  ----------
| DSETIN             Specifies the AE-format SI dataset     REQ      DMDATA.AE
|                    which needs to be transformed into an
|                    AE-format A&R dataset.
|                    Valid values: valid dataset name
|
| DSETOUT            Specifies the name of the output       REQ      ARDATA.AE
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
| RECALCVISITYN      Call %tu_recalcvisit to recalculate    REQ      Y
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
| DICTDECODEYN       Call %tu_dictdcod to add MedDRA        REQ      Y
|                    dictionary variables?
|                    Valid values: Y, N
|
| DERIVATIONYN       Call %tu_derive to perform specific    REQ      Y
|                    derivations for this domain code (AE)?
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
| REFDAT             Specify a reference date variable name OPT      AESTDT
|                    to pass to %tu_recalcvisit to
|                    calculate the visit. Will be checked
|                    in %tu_recalcvisit
|
| REFTIM             Specify a reference time variable name OPT      AESTTM
|                    to pass to %tu_recalcvisit to
|                    calculate the visit. Will be checked
|                    in %tu_recalcvisit
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
| DSETTEMPLATE       Specifies the name of the empty        OPT      (Blank)
|                    dataset containing the variables
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
|                    NOTE: If SORTORDER is specified
|                          as anything non-blank, then
|                          DSPLAN must be specified as
|                          blank (DSPLAN=,).
|
| NODERIVEVARS       List of domain-specific variables not  OPT      (Blank)
|                    to derive when %tu_derive is called.
|
| DYREFDATEVISITNUM  Specific visit number at which the              (None)
|                    reference date is to be taken for
|                    tu_derive.
|                    Used when DYREFDATEOPTION is VISIT.
|
| DYREFDATESOURCEDSE The dataset that contains the date used for     (None)
| T                  Study Day calculations in tu_derive.
|                    Used when DYREFDATEOPTION is OTHER.
|
| DYREFDATESOURCEVAR The variable in DYREFDATESOURCEDSET that        (None)
|                    contains the reference date used for Study
|                    Day calculations, in tu_derive.
|                    Used when DYREFDATEOPTION is OTHER.
|
| DYREFDATEDSETSUBSE WHERE clause applied to reference dataset       (None)
| T                  for tu_derive.
|                    Used to specify a subset of the reference
|                    dataset for tu_derive to better select the
|                    reference date.
|                    This may be used regardless of the value of
|                    DYREFDATEOPTION.
|
| RANDALLDSET        Specifies an SI-format RANDALL dataset to       dmdata.randall
|                    use for various derivations.
|                    Note: This parameter is not used in the
|                    current version. It should be passed to
|                    %tu_acttrt in a future release.
|
| RANDDSET           Specifies an SI-format RAND dataset to use      dmdata.rand
|                    for various derivations.
|
| EXPOSUREDSET       Specifies an SI-format EXPOSURE dataset to      dmdata.exposure
|                    use for various derivations.
|
| TMSLICEDSET        Specifies an SI-format TMSLICE dataset to       dmdata.tmslice
|                    use for various derivations.
|
| VISITDSET          Specifies an SI-format VISIT dataset to use     dmdata.visit
|                    for various derivations.
|
| DEMODSET           Specifies an SI-format DEMO dataset to use      dmdata.demo
|                    for various derivations.
|
| RACEDSET           Specifies an SI-format RACE dataset to use      dmdata.race
|                    for various derivations.
|
| ENROLDSET          Specifies an SI-format ENROL dataset to use     dmdata.enrol
|                    for various derivations.
|
| INVESTIGDSET       Specifies an SI-format INVESTIG dataset to      dmdata.investig
|                    use for various derivations.
|
| DECODEPAIRS        Specifies code and decode variables in          (Blank)
|                    pair. The decode variables will be created
|                    and populated with format value of the code
|                    variable. The format is defined in &DSPLAN
|                    file.
|
| DURATIONUNITS      Units to use for duration in EX and AE and       Days
|                    AE) derivations.
|                    Valid Values:
|                    (EXPOSURE  Days Years, Months, Weeks, Days
|                     or Hours
|-------------------------------------------------------------------------------
| The macro references the following datasets :-
| ------------------  -------  ------------------------------------------------
| Name                Req/Opt  Description
| ------------------  -------  ------------------------------------------------
| &DSETIN             Req      Parameter specified dataset
| &REFDATESOURCEDSET  Opt      Parameter specified dataset
| &DSETTEMPLATE       Opt      Parameter specified dataset
| SI data sets        Opt      Parameter specified dataset
|
| &FORMATNAMESDSET    Opt      Parameter specified dataset with variables:
|
|                              NAME       DESCRIPTION
|                              ---------  -------------------------------------
|                              VAR_NM     Variable name   (CD suffix)
|                              FORMAT_NM  SAS format name ($ prefix, e.g. $FMT)
|-------------------------------------------------------------------------------
| Output:
| The macro outputs the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETOUT           Req      Parameter specified dataset
|-------------------------------------------------------------------------------
| Global macro variables created: NONE
|-------------------------------------------------------------------------------
| Macros called:
|(@) tr_putlocals
|(@) tu_abort
|(@) tu_chkvarsexist
|(@) tu_nobs
|(@) tc_nonstandard
|(@) tu_putglobals
|(@) tu_stdderive
|(@) tu_tidyup
|-------------------------------------------------------------------------------
| Example:
|    %tc_aeanal(
|         refdateoption   = visit,
|         refdatevisitnum = 10,
|         dsplan          = &g_dsplanfile
|         );
|
|-------------------------------------------------------------------------------
| Change Log
|
| Modified By:              Yongwei Wang
| Date of Modification:     16-Jan-2008
| New version/draft number: 1/2
| Modification ID:          YW001
| Reason For Modification:  1. Fixed two NOTE "Note: Variable XXX is uninitialized", 
|                              which was found during UAT. 
|                           2. Fixed two bugs in RTWARNING messages, which were 
|                              found during UAT.  |
|                           3. Added a RTWARNING when ADSTDT is missing while deriving
|                              ADSEQ.  
|
| Modified By:
| Date of Modification:
| New version/draft number:
| Modification ID:
| Reason For Modification:
|-----------------------------------------------------------------------------*/

%macro tc_aeanal (
   DSETIN              =dmdata.ae,         /* Input dataset name */
   DSETOUT             =ardata.aeanal,     /* Output dataset name */

   AEDETAILDSET        =dmdata.aedetail,   /* Name of AEDETAIL dataset to use */
   DEMODSET            =dmdata.demo,       /* Name of DEMO dataset to use */
   ENROLDSET           =dmdata.enrol,      /* Name of ENROL dataset to use */
   EXPOSUREDSET        =dmdata.exposure,   /* Name of EXPOSURE dataset to use */
   INVESTIGDSET        =dmdata.investig,   /* Name of RACE dataset to use */
   RACEDSET            =dmdata.race,       /* Name of RACE dataset to use */
   RANDALLDSET         =dmdata.randall,    /* Name of RANDALL dataset to use */
   RANDDSET            =dmdata.rand,       /* Name of RAND dataset to use */
   TMSLICEDSET         =dmdata.tmslice,    /* Name of TMSLICE dataset to use */
   VISITDSET           =dmdata.visit,      /* Name of VISIT dataset to use */
   
   ATTRIBUTESYN        =Y,                 /* Reconcile A&R dataset with planned A&R dataset */
   COMMONVARSYN        =Y,                 /* Add common variables. */
   DATETIMEYN          =Y,                 /* Derive datetime variables */
   DECODEYN            =Y,                 /* Decode coded variables */
   DERIVATIONYN        =Y,                 /* Dataset specific derivations */
   DICTDECODEYN        =Y,                 
   MISSCHKYN           =Y,                 /* Print warning message for variables in &DSETOUT with missing values on all records */
   RECALCVISITYN       =N,                 /* Recalculate VISIT */
   TIMESLICINGYN       =Y,                 /* Add timeslicing variables */
   TREATVARSYN         =Y,                 /* Add treatment variables. */
   XOVARSFORPGYN       =N,                 /* If Y derive crossover study specific variables for parallel study */
   AGEDAYSYN           =N,                 /* Calculation of age in days. */
   AGEMONTHSYN         =N,                 /* Calculation of age in months. */
   AGEWEEKSYN          =N,                 /* Calculation of age in weeks. */
   
   REFDAT              =adstdt,            /* Reference data variable name for recalculating visit */
   REFTIM              =,                  /* Reference time variable name for recalculating visit */
   REFDATEOPTION       =TREAT,             /* Reference date source option for the calculation of Age values in tu_common. */
   REFDATEVISITNUM     =,                  /* Specific visit number at which reference date is to be taken for tu_common. */
   REFDATESOURCEDSET   =,                  /* Reference date source dataset for tu_common. */
   REFDATESOURCEVAR    =,                  /* Reference date source variable for tu_common. */
   REFDATEDSETSUBSET   =,                  /* WHERE clause applied to source dataset for tu_common */
   DYREFDATEOPTION     =treat,             /* Reference date source option for the calculation of Study Day values in tu_derive */
   DYREFDATEVISITNUM   =,                  /* Specific visit number at which reference date is to be taken for tu_derive. */
   DYREFDATESOURCEDSET =,                  /* Reference date source dataset for tu_derive. */
   DYREFDATESOURCEVAR  =,                  /* Reference date source variable for tu_derive. */
   DYREFDATEDSETSUBSET =,                  /* WHERE clause applied to source dataset for tu_derive. */
   ADWINDOWSUBSET      =,                  /* If statement which defines ADWINDOW */
   DURATIONUNITS       =Days,              /* Units of event duration, time from first dose, time from last do time from treatment period first dose. ( i.e. DAYS HOURS(AEDUR) MINUTES(ADTRTST) ) */
   DSETTEMPLATE        =,                  /* Planned A&R dataset template name. */
   DSPLAN              =&g_dsplanfile,     /* Path and filename of tab-delimited file containing HARP A&R dataset plan. */
   FORMATNAMESDSET     =,                  /* Format names dataset name. */
   SORTORDER           =,                  /* Planned A&R dataset sort order. */
   TRTCDINF            =,                  /* Informat to derive TRTCD from TRTGRP. */
   PTRTCDINF           =,                  /* Informat to derive PTRTCD from PTRTGRP. */
   DECODERENAME        =aeactr=aeacttrt aetxhv=aetoxhiv adtxhv=adtoxhiv adptxh=adptxhiv adactr=adacttrt, /* List of renames for decoded variables */
   DECODEPAIRS         =,                  /* code and decode variables in pair */
   NODERIVEVARS        =                   /* List of variables not to derive. */
   );                         
                             
   /*   
   / Echo parameter values and global macro variables to the log.
   /----------------------------------------------------------------------------*/

   %local MacroVersion;
   %let MacroVersion = 1;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals()

   %local i prefix dropvars periodvar adpsevcdvar adptoxcdvar adptxhcdvar
          studyidvar loopi timevar adpvar1 adpvar2 j adseqvar datevar;

   %let prefix = _tc_aeanal;   /* Root name for temporary work datasets */
   %let i=1;
   %let adseqvar=ADSEQ;
   
   /*
   / Parameter validation
   /----------------------------------------------------------------------------*/

   %if %nrbquote(&aedetaildset) ne %then
   %do;
      %if not %sysfunc(exist(%scan(&aedetaildset, 1, %str(%()))) %then
      %do;
         %put %str(RTW)ARNING: &sysmacroname: Data set AEDETAILDSET(=&aedetaildset) does not exist. Set it to blank;
         %let aedetaildset=;
      %end;
   %end;

   %if %nrbquote(&aedetaildset) eq %then
   %do;   
      %let noderivevars=&noderivevars ADPSEVCD ADPTOXCD ADPTXHCD ADWORSE ADWINDOW ADENDT ADENTM;
      %let adseqvar=AESEQ;
      %put %str(RTN)OTE: &sysmacroname: Data set AEDETAILDSET is not given. The macro will not create AEANAL, but AE data set;
   %end;

   %if %sysfunc(indexw(&noderivevars, ADWINDOW)) and %nrbquote(&adwindowsubset) ne %then
   %do;
      %put %str(RTN)OTE: &sysmacroname: Because ADWINDOW is in NODERIVEVARS(=&nowidowvars), ADWINDOWSUBSET(=&adwindowsubset) will be set to blank;
      %let adwindowsubset=;
   %end;

   %if %nrbquote(&derivationyn) ne %then %let derivationyn=%upcase(%substr(&derivationyn, 1, 1));

   %if ( %nrbquote(&derivationyn) ne Y ) and ( %nrbquote(&derivationyn) ne N ) %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: Value of DERIVATIONYN (=&derivationyn) is invalid. Valid value should be Y or N;
      %let g_abort=1;
   %end;

   %if %nrbquote(&dsetin) eq %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: Value of DSETIN is not given and it is required.;
      %let g_abort=1;
   %end;
   %else %if %tu_nobs(&dsetin) lt 0 %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: Data set DSETIN(=&dsetin) does not exist.;
      %let g_abort=1;
   %end;

   %if %nrbquote(&dsetout) eq %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: Value of DSETOUT is not given and it is required.;
      %let g_abort=1;
   %end;

   %if ( %nrbquote(&dsetin) ne ) and ( %nrbquote(&dsetout) ne ) %then
   %do;
      %if %qscan(&dsetin, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
      %do;
         %put %str(RTE)RROR: &sysmacroname: Data set DSETIN(=&dsetin) and DSETOUT(=&dsetout) are the same data set.;
         %let g_abort=1;
      %end;
   %end;

   %if &g_abort gt 0 %then %goto endmac;

   /*
   / NORMAL PROCESSING
   /----------------------------------------------------------------------------*/

   data &prefix._ds&i;
      set %unquote(&dsetin);
   run;

   %let studyidvar=;
   %if %tu_chkvarsexist(&prefix._ds&i, studyid) eq %then %let studyidvar=studyid;

   /*
   / Derive AETRTST based on AEONLDSH or AEONLDSM.
   /----------------------------------------------------------------------------*/

   %if %sysfunc(indexw(&noderivevars, AETRTST)) eq 0 %then
   %do;
      %let notexistvars=%tu_chkvarsexist(&prefix._ds&i, AEONLDSH AEONLDSM);

      %if %qscan(&notexistvars, 2, %str( )) eq %then
      %do;
         /* Time to onset variables exist */
         data &prefix._ds%eval(&i+1);
            set &prefix._ds&i;
            length aetrtstc $ 20;
            aetrtst = .;

            %if %qupcase(&notexistvars) ne AEONLDSH %then
            %do;
               if aeonldsh ne . then aetrtst = aeonldsh/24;
            %end;

            %if %qupcase(&notexistvars) ne AEONLDSM %then
            %do;
               if aeonldsm ne . then aetrtst = sum(aetrtst, aeonldsm/(24*60));
            %end;

            aetrtst=floor(aetrtst) + 1;

            if aetrtst ne . then aetrtstc = trim(left(put(aetrtst, 8.))) || "d";
         run;

         %let noderivevars=&noderivevars AETRTSTC AETRTST;
         %let i = %eval(&i + 1);
      %end;
   %end; /* %if %sysfunc(indexw(&noderivevars, AETRTST)) eq 0 */

   /*
   / call %tu_stdderive to derive standard AE derivations, AEDURHR and AEDURMIN
   /----------------------------------------------------------------------------*/
   %if %nrbquote(&derivationyn) eq Y %then
   %do;
      %tu_stdderive (
         DSETIN              =&prefix._ds&i,
         DSETOUT             =&prefix._ds%eval(&i + 1),
         DEMODSET            =&DEMODSET,
         EXPOSUREDSET        =&EXPOSUREDSET,
         RANDALLDSET         =&RANDALLDSET,
         RANDDSET            =&RANDDSET,
         TMSLICEDSET         =&TMSLICEDSET,
         VISITDSET           =&VISITDSET,

         BIRTHDTVAR          =BIRTHDT,
         STUDYIDVAR          =&STUDYIDVAR,
         SUBJIDVAR           =SUBJID,
         EVENTSTDTVAR        =aestdt,
         EVENTSTTMVAR        =aeacttm,
         EVENTENDTVAR        =aeendt,
         EVENTENTMVAR        =aeentm,
         DURATIONUNITS       =&durationunits,

         REFDATEDSETSUBSET   =&DYREFDATEDSETSUBSET,
         REFDATEOPTION       =&DYREFDATEOPTION    ,
         REFDATESOURCEDSET   =&DYREFDATESOURCEDSET,
         REFDATESOURCEVAR    =&DYREFDATESOURCEVAR ,
         REFDATEVISITNUM     =&DYREFDATEVISITNUM  ,
         REFTIMESOURCEVAR    =,
         
         %if %nrbquote(&aedetaildset) eq %then
         %do;
            ACTSDYVAR        =aeactsdy,
            ACTEDYVAR        =aeactedy,
            XPERSDYVAR       =xpersdy,
            XPEREDYVAR       =xperedy,
            PERSDYVAR        =aepersdy,
            PEREDYVAR        =aeperedy,
            TPERSDYVAR       =tpersdy,
            TPEREDYVAR       =tperedy,
         %end;

         DURATIONUVAR        =aeduru,
         DURATIONVAR         =aedur,
         DURATIONCVAR        =aedurc,
         TRTSTVAR            =aetrtst,
         TRTSTCVAR           =aetrtstc,
         TRT1STVAR           =aetrt1st,
         TRT1STCVAR          =aetrt1sc,
         PTRT1STVAR          =aeptr1st,
         PTRT1STCVAR         =aeptr1sc,

         NODERIVEVARS        =&noderivevars,
         XOVARSFORPGYN       =&xovarsforpgyn
         );
      
      %let i=%eval(&i + 1);
      
      %if %sysfunc(indexw(&noderivevars, ADDURHR)) eq 0 %then
      %do;
         %tu_stdderive (
            DSETIN              =&prefix._ds&i,
            DSETOUT             =&prefix._ds%eval(&i + 1),
            DEMODSET            =&DEMODSET,
            EXPOSUREDSET        =&EXPOSUREDSET,
            RANDALLDSET         =&RANDALLDSET,
            RANDDSET            =&RANDDSET,
            TMSLICEDSET         =&TMSLICEDSET,
            VISITDSET           =&VISITDSET,
        
            BIRTHDTVAR          =BIRTHDT,
            STUDYIDVAR          =&STUDYIDVAR,
            SUBJIDVAR           =SUBJID,
            EVENTSTDTVAR        =aestdt,
            EVENTSTTMVAR        =aeacttm,
            EVENTENDTVAR        =aeendt,
            EVENTENTMVAR        =aeentm,
            DURATIONUNITS       =hours,
        
            REFDATEDSETSUBSET   =&DYREFDATEDSETSUBSET,
            REFDATEOPTION       =&DYREFDATEOPTION,
            REFDATESOURCEDSET   =&DYREFDATESOURCEDSET,
            REFDATESOURCEVAR    =&DYREFDATESOURCEVAR,
            REFDATEVISITNUM     =&DYREFDATEVISITNUM,
            
            DURATIONVAR         =aedurhr,
        
            NODERIVEVARS        =&noderivevars,
            XOVARSFORPGYN       =&xovarsforpgyn
            );
                 
         %let i=%eval(&i + 1);
      %end; /* %if %sysfunc(indexw(&noderivevars, ADDURHR)) eq 0 */
       
      %if %sysfunc(indexw(&noderivevars, ADDURMIN)) eq 0 %then
      %do;
         %tu_stdderive (
            DSETIN              =&prefix._ds&i,
            DSETOUT             =&prefix._ds%eval(&i + 1),
            DEMODSET            =&DEMODSET,
            EXPOSUREDSET        =&EXPOSUREDSET,
            RANDALLDSET         =&RANDALLDSET,
            RANDDSET            =&RANDDSET,
            TMSLICEDSET         =&TMSLICEDSET,
            VISITDSET           =&VISITDSET,
        
            BIRTHDTVAR          =BIRTHDT,
            STUDYIDVAR          =&STUDYIDVAR,
            SUBJIDVAR           =SUBJID,
            EVENTSTDTVAR        =aestdt,
            EVENTSTTMVAR        =aeacttm,
            EVENTENDTVAR        =aeendt,
            EVENTENTMVAR        =aeentm,
            DURATIONUNITS       =minutes,
        
            REFDATEDSETSUBSET   =&DYREFDATEDSETSUBSET,
            REFDATEOPTION       =&DYREFDATEOPTION,
            REFDATESOURCEDSET   =&DYREFDATESOURCEDSET,
            REFDATESOURCEVAR    =&DYREFDATESOURCEVAR,
            REFDATEVISITNUM     =&DYREFDATEVISITNUM,
            
            DURATIONVAR         =aedurmin,
        
            NODERIVEVARS        =&noderivevars,
            XOVARSFORPGYN       =&xovarsforpgyn
            );
                 
         %let i=%eval(&i + 1);
      %end; /* %if %sysfunc(indexw(&noderivevars, ADDURMIN)) eq 0 */              
   %end; /* %if %nrbquote(&derivationyn) eq Y */

   /*
   / Merge AEDETAIL and AE data set together
   /----------------------------------------------------------------------------*/

   %if %nrbquote(&aedetaildset) ne %then
   %do;
      %let dropvars=%tu_chkvarsexist(%qscan(&aedetaildset, 1, %str(%()), SUBJID AEREFID AETERM);
      %if  %nrbquote(&dropvars) ne %then
      %do; 
         %put %str(RTE)RROR: &sysmacroname: Required variables - &dropvars - do not exist in AEDETAILDSET(=&aedetaildset);
         %let g_abort=1;         
         %goto endmac;
      %end;
      
      %let dropvars=%tu_chkvarsexist(&prefix._ds&i, SUBJID AEREFID AETERM);
      %if  %nrbquote(&dropvars) ne %then
      %do; 
         %put %str(RTE)RROR: &sysmacroname: Required variables - &dropvars - do not exist in DSETIN(=&dsetin);
         %let g_abort=1;         
         %goto endmac;
      %end;
      
      proc contents data=%unquote(&aedetaildset) out=&prefix.aedetailcon(keep=name) noprint;
      run;

      proc contents data=&prefix._ds&i out=&prefix.dsetincon(keep=name) noprint;
      run;

      %let dropvars=;

      proc sql noprint;
         select a.name into :dropvars separated by ' '
         from &prefix.aedetailcon as a, &prefix.dsetincon as b
         where upcase(a.name) eq upcase(b.name)
         and   upcase(a.name) ne 'STUDYID'
         and   upcase(a.name) ne 'SUBJID'
         and   upcase(a.name) ne 'AEREFID'
         and   upcase(a.name) ne 'AETERM'
         ;
      quit;

      %if %tu_chkvarsexist(%qscan(&aedetaildset, 1, %str(%()), studyid) ne %then %let studyidvar=;
      
      data &prefix.aedetail2 &prefix.aedetail1(drop=aeterm);
         set %unquote(&aedetaildset);
         %if %nrbquote(&dropvars) ne %then
         %do;
            drop &dropvars;
            %put %str(RTN)OTE: &sysmacroname: Vairabels (&dropvars) have been droped from AEDETAILDSET(=&aedetaildset) because they exist in DSETIN(=&dsetin).;
         %end;                   
         if missing(aeterm) then output &prefix.aedetail1;
         else output &prefix.aedetail2;
      run;      

      proc sort data=&prefix._ds&i;
         by &studyidvar subjid aeterm aerefid;
      run;

      data &prefix._ds&i;
         set &prefix._ds&i;
         by &studyidvar subjid aeterm aerefid;
         if last.aerefid and (not first.aerefid) then
            put "RTW" "ARNING: &sysmacroname: mutilple records are found is in DSETIN(=&dsetin) and only first will be kept for " subjid= aerefid= aeterm=;
         if first.aerefid;
      run;
      
      /* Add AETERM from AE data set to missing AETERM in AEDETAIL */
      proc sort data=&prefix._ds&i out=&prefix.aeterm (keep=&studyidvar subjid aeterm aerefid) nodupkey;
         by &studyidvar subjid aerefid;
         where not missing(aeterm);
      run;
      
      proc sort data=&prefix.aedetail1;
         by &studyidvar subjid aerefid;
      run;
      
      data &prefix.aedetail1;
         merge &prefix.aedetail1(in=_in1_) &prefix.aeterm;
         by &studyidvar subjid aerefid;
         if _in1_;
      run;
      
      data &prefix.aedetail;
         set &prefix.aedetail1 &prefix.aedetail2;
      run;
      
      proc sort data=&prefix.aedetail;
         by &studyidvar subjid aeterm aerefid;
      run;

      data &prefix._ds%eval(&i+1);
         merge &prefix._ds&i(in=__in1__) &prefix.aedetail(in=__in2__);
         by &studyidvar subjid aeterm aerefid;
         if __in2__ and (not __in1__) then
         do;
            put "RTW" "ARNING: &sysmacroname: this record is in AEDETAILDSET(=&aedetaildset)," " but not in DSETIN(=&dsetin):" subjid= aerefid= aeterm=;
         end;
         if __in1__ and (not __in2__) then
         do;
            put "RTW" "ARNING: &sysmacroname: this record is not in AEDETAILDSET(=&aedetaildset)," " but in DSETIN(=&dsetin):" subjid= aerefid= aeterm=;
         end;
      run;

      %let i=%eval(&i + 1);
   %end; /* %if %nrbquote(&aedetaildset) ne */

   /*
   / Derive ADWORSE and ADWINDOW
   /----------------------------------------------------------------------------*/

   %let timevar=;
   %if %tu_chkvarsexist(&prefix._ds&i, adsttm) eq %then %let timevar=adsttm;
                  
   %let adpvar1=;
   
   %if %sysfunc(indexw(&noderivevars, ADWORSE)) eq 0 %then   
   %do j=1 %to 3;
      %if       &j eq 1 %then %let adpsevcdvar=ADSEVCD;            
      %else %if &j eq 2 %then %let adpsevcdvar=ADTOXCD;
      %else %if &j eq 3 %then %let adpsevcdvar=ADTXHVCD;
   
      %if %tu_chkvarsexist(&prefix._ds&i, &adpsevcdvar) ne %then %let adpsevcdvar=;   
      %else %do;
         %if %nrbquote(&adpvar1) ne %then
         %do;
            %put %str(RTW)ARNING: &sysmacroname: ADWORSE has been derived based on &adpvar1 and will not be derived based on &adpsevcdvar;
            %let adpsevcdvar=;
         %end;
         %else %let adpvar1=&adpsevcdvar;
      %end;
      
      %if %nrbquote(&adpsevcdvar) ne %then
      %do;
          proc sort data=&prefix._ds&i;
             by &studyidvar subjid aeterm aerefid adstdt &timevar;
          run;
         
          data &prefix._ds%eval(&i + 1);          
             length __adsevcd__ $5;
             set &prefix._ds&i;
             by &studyidvar subjid aeterm aerefid adstdt &timevar;
             retain __adsevcd__;
             drop __adsevcd__;
             /* ADWORSE */
             if first.aerefid then 
             do;
                if not missing(&adpsevcdvar) then ADWORSE='Y';
                __adsevcd__=' ';
             end;
             else do;
                if (upcase(&adpsevcdvar) eq 'X' and __adsevcd__ ne 'X') or 
                   (upcase(&adpsevcdvar) ne 'X' and __adsevcd__ eq 'X') then           
                do;      
                   put "RTW" "ARNING:  &sysmacroname: &adpsevcdvar changed from/to 'X' at " subjid= aeterm= aerefid= adstdt=;
                end;
                else if (missing(&adpsevcdvar) and not missing(__adsevcd__)) or
                        (not missing(&adpsevcdvar) and missing(__adsevcd__)) then
                do;
                   put "RTW" "ARNING:  &sysmacroname: &adpsevcdvar changed from/to missing at " subjid= aeterm= aerefid= adstdt=; 
                end;
                else if input(&adpsevcdvar, ??best.) gt input(__adsevcd__, ??best.) then ADWORSE='Y';
                else if missing(ADWORSE) then ADWORSE='N';
             end;
             __adsevcd__=upcase(left(&adpsevcdvar));
         run;     
         %let i=%eval(&i + 1);         
      %end; /* %if %nrbquote(&adpsevcdvar) ne */
   %end; /* %do j=1 %to 3 */
   
   /*
   / Derive ADENDT and ADENTM
   /----------------------------------------------------------------------------*/

   %let timevar=;
   %if %tu_chkvarsexist(&prefix._ds&i, adsttm) eq %then %let timevar=adsttm;

   %if %sysfunc(indexw(&noderivevars, ADENDT)) eq 0 %then
   %do;
      %if %sysfunc(indexw(&noderivevars, ADENTM)) gt 0 %then timevar=;

      proc sort data=&prefix._ds&i;
         by &studyidvar subjid aeterm aerefid descending adstdt
            %if %nrbquote(&timevar) ne %then descending &timevar;;
      run;

      data &prefix._ds%eval(&i + 1);
         set &prefix._ds&i;
         by &studyidvar subjid aeterm aerefid descending adstdt
            %if %nrbquote(&timevar) ne %then descending &timevar;;
         format adendt date9. %if %nrbquote(&timevar) ne %then adentm time5.;;         
         retain __adendt__  %if %nrbquote(&timevar) ne %then __adentm__;;
         drop __adendt__  %if %nrbquote(&timevar) ne %then __adentm__;;
         if first.aerefid then
         do;
            adendt=aeendt;
            %if %nrbquote(&timevar) ne %then adentm=aeentm;;
         end;
         else do;
            %if %nrbquote(&timevar) ne %then
            %do;          
               if  ( __adendt__ ge adstdt ) and ( not missing(__adentm__) ) and
                   ( dhms(__adendt__,0,0,__adentm__) gt dhms(adstdt,0,0,adsttm) ) then
               do;              
                  adendt=datepart(dhms(__adendt__,0,0,__adentm__) -1);
                  adentm=timepart(dhms(__adendt__,0,0,__adentm__) -1);
               end;
               else do;
                  adendt=__adendt__;
                  adentm=__adentm__;
               end;
            %end;
            %else %do;
               if __adendt__ gt adstdt then adendt=__adendt__ - 1;
               else adendt=__adendt__;
            %end;
         end;
         __adendt__=adstdt;
         %if %nrbquote(&timevar) ne %then __adentm__=adsttm;;
      run;
      %let i=%eval(&i + 1);
   %end; /* %if %sysfunc(indexw(&noderivevars, ADENDT)) eq 0 */

   /*
   / call %tu_stdderive to derive standard AEDETAIL derivations
   /----------------------------------------------------------------------------*/

   %if ( %nrbquote(&aedetaildset) ne ) and ( &derivationyn eq Y) %then
   %do;
      %tu_stdderive (
         DSETIN              =&prefix._ds&i,
         DSETOUT             =&prefix._ds%eval(&i+1),
         DEMODSET            =&DEMODSET,
         EXPOSUREDSET        =&EXPOSUREDSET,
         RANDALLDSET         =&RANDALLDSET,
         RANDDSET            =&RANDDSET,
         TMSLICEDSET         =&TMSLICEDSET,
         VISITDSET           =&VISITDSET,

         BIRTHDTVAR          =BIRTHDT,
         STUDYIDVAR          =&STUDYIDVAR,
         SUBJIDVAR           =SUBJID,
         EVENTSTDTVAR        =adstdt,
         EVENTSTTMVAR        =adsttm,
         EVENTENDTVAR        =adendt,
         EVENTENTMVAR        =adentm,
         DURATIONUNITS       =&durationunits,

         REFDATEDSETSUBSET   =&DYREFDATEDSETSUBSET,
         REFDATEOPTION       =&DYREFDATEOPTION    ,
         REFDATESOURCEDSET   =&DYREFDATESOURCEDSET,
         REFDATESOURCEVAR    =&DYREFDATESOURCEVAR ,
         REFDATEVISITNUM     =&DYREFDATEVISITNUM  ,
         REFTIMESOURCEVAR    =,

         ACTSDYVAR           =adactsdy,
         ACTEDYVAR           =adactedy,
         DURATIONUVAR        =adduru,
         DURATIONVAR         =addur,
         DURATIONCVAR        =addurc,
         PERSDYVAR           =adpersdy,
         PEREDYVAR           =adperedy,
         TPERSDYVAR          =tpersdy,
         TPEREDYVAR          =tperedy,
         TRTSTVAR            =adtrtst,
         TRTSTCVAR           =adtrtstc,
         TRT1STVAR           =adtrt1st,
         TRT1STCVAR          =adtrt1sc,
         PTRT1STVAR          =adptr1st,
         PTRT1STCVAR         =adptr1sc,
         XPERSDYVAR          =xpersdy,
         XPEREDYVAR          =xperedy,

         NODERIVEVARS        =&noderivevars,
         XOVARSFORPGYN       =&xovarsforpgyn
         );

      %let i=%eval(&i + 1);
   %end; /* %if %nrbquote(&aedetaildset) ne */

   /*
   / call %tu_stdderive to derive ADREMFUR and ADRMFURC
   /----------------------------------------------------------------------------*/

   %if ( %nrbquote(&aedetaildset) ne ) and ( &derivationyn eq Y ) %then
   %do;
      %tu_stdderive (
         DSETIN              =&prefix._ds&i,
         DSETOUT             =&prefix._ds%eval(&i+1),
         DEMODSET            =&DEMODSET,
         EXPOSUREDSET        =&EXPOSUREDSET,
         RANDALLDSET         =&RANDALLDSET,
         RANDDSET            =&RANDDSET,
         TMSLICEDSET         =&TMSLICEDSET,
         VISITDSET           =&VISITDSET,

         BIRTHDTVAR          =BIRTHDT,
         STUDYIDVAR          =&STUDYIDVAR,
         SUBJIDVAR           =SUBJID,
         EVENTSTDTVAR        =adstdt,
         EVENTSTTMVAR        =adsttm,
         EVENTENDTVAR        =aeendt,
         EVENTENTMVAR        =aeentm,
         DURATIONUNITS       =&durationunits,

         REFDATEDSETSUBSET   =&DYREFDATEDSETSUBSET,
         REFDATEOPTION       =&DYREFDATEOPTION    ,
         REFDATESOURCEDSET   =&DYREFDATESOURCEDSET,
         REFDATESOURCEVAR    =&DYREFDATESOURCEVAR ,
         REFDATEVISITNUM     =&DYREFDATEVISITNUM  ,
         REFTIMESOURCEVAR    =,

         DURATIONVAR         =adremdur,
         DURATIONCVAR        =adrmdurc,

         NODERIVEVARS        =&noderivevars,
         XOVARSFORPGYN       =&xovarsforpgyn
         );

      %let i=%eval(&i + 1);
   %end; /* %if %nrbquote(&aedetaildset) ne */

   /*
   / call %tc_nonstandard to derive standard derivations
   /----------------------------------------------------------------------------*/
   
   %if %qupcase(&xovarsforpgyn) eq N and  %qupcase(&g_stype) eq XO %then %let xovarsforpgyn=Y;
   
   %tc_nonstandard(
      dsetin            =&prefix._ds&i,
      dsetout           =&prefix._ds%eval(&i+1),

      demodset          =&demodset,
      enroldset         =&enroldset,
      exposuredset      =&exposuredset,
      investigdset      =&investigdset,
      racedset          =&racedset,
      randalldset       =&randalldset,
      randdset          =&randdset,
      tmslicedset       =&tmslicedset,
      visitdset         =&visitdset,

      attributesyn      =N,
      commonvarsyn      =&commonvarsyn,
      datetimeyn        =N,
      decodeyn          =N,
      dictdecodeyn      =N,
      misschkyn         =N,
      recalcvisityn     =&recalcvisityn,
      timeslicingyn     =&timeslicingyn,
      treatvarsyn       =&treatvarsyn,
      calctpernumyn     =&xovarsforpgyn,
      agedaysyn         =&agedaysyn,
      agemonthsyn       =&agemonthsyn,
      ageweeksyn        =&ageweeksyn,
      refdat            =&refdat,
      reftim            =&reftim,
      refdatedsetsubset =&refdatedsetsubset,
      refdateoption     =&refdateoption,
      refdatesourcedset =&refdatesourcedset,
      refdatesourcevar  =&refdatesourcevar,
      refdatevisitnum   =&refdatevisitnum,
      dsettemplate      =&dsettemplate,
      dsplan            =&dsplan,
      sortorder         =&sortorder,
      ptrtcdinf         =&ptrtcdinf,
      trtcdinf          =&trtcdinf,
      decoderename      =,
      decodepairs       =&decodepairs,
      formatnamesdset   =&formatnamesdset
      );

   %let i=%eval(&i + 1);

   /*
   / Derive non-standard variables for AEANAL.
   /----------------------------------------------------------------------------*/

   /*
   / Derive ADPSEVCD, ADPTOXCD and ADPTXHCD
   /----------------------------------------------------------------------------*/

   %let periodvar=;
   %let adpsevcdvar=;
   %let adptoxcdvar=;
   %let adptxhcdvar=;

   %if %tu_chkvarsexist(&prefix._ds&i, tpatrtcd) eq %then %let periodvar=tpatrtcd;
   %else %if %tu_chkvarsexist(&prefix._ds&i, tptrtcd) eq %then %let periodvar=tptrtcd;
   %else %if %tu_chkvarsexist(&prefix._ds&i, patrtcd) eq %then %let periodvar=patrtcd;
   %else %if %tu_chkvarsexist(&prefix._ds&i, ptrtcd) eq %then %let periodvar=ptrtcd;

   %if %sysfunc(indexw(&noderivevars, ADPSEVCD)) eq 0 and %tu_chkvarsexist(&prefix._ds&i, adpsevcd) ne %then %let adpsevcdvar=adsevcd;
   %if %sysfunc(indexw(&noderivevars, ADPTOXCD)) eq 0 and %tu_chkvarsexist(&prefix._ds&i, adptoxcd) ne %then %let adptoxcdvar=adtoxcd;
   %if %sysfunc(indexw(&noderivevars, ADPTXHCD)) eq 0 and %tu_chkvarsexist(&prefix._ds&i, adptxhvcd) ne %then %let adptxhcdvar=adtxhvcd;

   %if %tu_chkvarsexist(&prefix._ds&i, adsevcd)  ne %then %let adpsevcdvar=;     
   %if %tu_chkvarsexist(&prefix._ds&i, adtoxcd)  ne %then %let adptoxcdvar=;     
   %if %tu_chkvarsexist(&prefix._ds&i, adtxhvcd) ne %then %let adptxhcdvar=;   
   
   %if %nrbquote(&adpsevcdvar.&adptoxcdvar.&adptxhcdvar) ne %then
   %do;
      proc sort data=&prefix._ds&i;
         by &studyidvar subjid aeterm &periodvar aerefid adstdt &timevar;
      run;
      
      data &prefix.max;
         set &prefix._ds&i;
         by &studyidvar subjid aeterm &periodvar aerefid adstdt &timevar;
         keep &studyidvar subjid aeterm &periodvar aerefid;
         
         %do j=1 %to 3;
            %if &j eq 1 %then %let adpvar1=SEV;            
            %else %if &j eq 2 %then %let adpvar1=TOX;
            %else %let adpvar1=TXH; 
            
            %if &j eq 3 %then %let adpvar2=V;
            %else %let adpvar2=;

            %if %nrbquote(&&ADP&adpvar1.CDVAR) ne %then
            %do;            
               retain ADP&adpvar1.CD;
               length ADP&adpvar1.CD  $5;
               keep   ADP&adpvar1.CD;            
               if first.aerefid then 
               do;
                  if upcase(AD&adpvar1.&adpvar2.CD) eq 'X' then ADP&adpvar1.CD='X';               
                  else ADP&adpvar1.CD=AD&adpvar1.&adpvar2.CD;
               end;               
               else do;
                  if ( upcase(AD&adpvar1.&adpvar2.CD) eq 'X' ) and ( ADP&adpvar1.CD ne 'X' ) then 
                     put "RTW" "ARNING:  &sysmacroname:  AD&adpvar1.&adpvar2.CD changed from " adp&adpvar1.CD " to 'X' at " subjid= aerefid= aeterm=;
                  else if upcase(AD&adpvar1.&adpvar2.CD) eq 'X' then ADP&adpvar1.CD='X';               
                  else if ADP&adpvar1.CD eq 'X' then 
                  do;
                     put "RTW" "ARNING:  &sysmacroname:  AD&adpvar1.&adpvar2.CD changed from 'X' to " AD&adpvar1.&adpvar2.CD " at " subjid= aerefid= aeterm=;
                     ADP&adpvar1.CD=AD&adpvar1.&adpvar2.CD;
                  end;
                  else ADP&adpvar1.CD=left(put(max(input(ADP&adpvar1.CD, ??best.), input(AD&adpvar1.&adpvar2.CD, ??best.)), best.));
               end;               
            %end; /* %if %nrbquote(&&adp&adpvar1.cdvar) ne */
         %end; /* %do j=1 %to 3 */
         
         if last.aerefid then output;
      run;          

      data &prefix._ds%eval(&i + 1);
         merge &prefix._ds&i &prefix.max;
         by &studyidvar subjid aeterm &periodvar aerefid;
      run;

      %let i=%eval(&i + 1);
   %end;

   /*
   / Derive AEONGO and ADWINDOW
   /----------------------------------------------------------------------------*/

   data &prefix._ds%eval(&i+1);
      set &prefix._ds&i;

      %if %sysfunc(indexw(&noderivevars, AEONGO)) eq 0 %then
      %do;
         if aeoutcd in ('2','3') then aeongo='Y';
         else aeongo='N';
      %end;

      %if %nrbquote(&adwindowsubset) ne %then
      %do;
         if %unquote(&adwindowsubset) then ADWINDOW='Y';
         else ADWINDOW='N';
      %end;
   run;

   %let i = %eval(&i + 1);
   
   /*
   / Derive ADSEQ
   /----------------------------------------------------------------------------*/
   
   %if %sysfunc(indexw(&noderivevars, &adseqvar)) eq 0 %then
   %do;
      %if %tu_chkvarsexist(&prefix._ds&i, &adseqvar) eq %then 
      %do;
         %put %str(RTN)OTE: &sysmacroname: &adseqvar already exists and will not be derived.;
         %let noderivevars=&noderivevars &adseqvar;
      %end;
   %end;
   
   %if %sysfunc(indexw(&noderivevars, &adseqvar)) eq 0 %then   
   %do;
      %local byvars;  
      %let byvars=;
      %if &adseqvar eq ADSEQ %then
      %do;
         %let datevar=ADSTDT;
         %let timevar=ADSTTM;         
      %end;
      %else %do;
         %let datevar=AESTDT;
         %let timevar=AESTTM;
      %end;
      
      %if %tu_chkvarsexist(&prefix._ds&i, studyid) eq %then %let byvars=studyid &byvars;      
      %if %tu_chkvarsexist(&prefix._ds&i, aerefid) eq %then %let byvars=&byvars aerefid;      
      %if %tu_chkvarsexist(&prefix._ds&i, aeterm)  eq %then %let byvars=&byvars aeterm;            
      %let byvars=&byvars subjid;          
      %if %tu_chkvarsexist(&prefix._ds&i, &datevar)  eq %then %let byvars=&byvars &datevar;      
      %if %tu_chkvarsexist(&prefix._ds&i, &timevar)  eq %then %let byvars=&byvars &timevar;
      
      proc sort data= &prefix._ds&i;
         by &byvars;
      run;
                      
      data &prefix._ds%eval(&i+1);
         set &prefix._ds&i;        
         by &byvars;
         retain &adseqvar;
         if first.subjid then &adseqvar=0;
         if missing(&datevar) then 
         do;
            &adseqvar=.;            
            put "RTW" "ARNING: &sysmacroname: &adseqvar can't be derived because an &datevar is missing for " subjid= aerefid= aeterm=;
         end;
         else if missing(&adseqvar) then &adseqvar=0;
         &adseqvar=&adseqvar + 1;        
      run;      
      
      %let i = %eval(&i + 1);       
   %end; /* %if %sysfunc(indexw(&noderivevars, &adseqvar)) eq 0 */      

   /*
   / call %tc_nonstandard to derive standard derivations
   /----------------------------------------------------------------------------*/
   
   %tc_nonstandard(
      dsetin            =&prefix._ds&i,
      dsetout           =&dsetout,

      demodset          =&demodset,
      enroldset         =&enroldset,
      exposuredset      =&exposuredset,
      investigdset      =&investigdset,
      racedset          =&racedset,
      randalldset       =&randalldset,
      randdset          =&randdset,
      tmslicedset       =&tmslicedset,
      visitdset         =&visitdset,

      attributesyn      =&attributesyn,
      commonvarsyn      =N,
      datetimeyn        =&datetimeyn,
      decodeyn          =&decodeyn,
      dictdecodeyn      =&dictdecodeyn,
      misschkyn         =&misschkyn,
      recalcvisityn     =N,
      timeslicingyn     =N,
      treatvarsyn       =N,
      calctpernumyn     =N,
      agedaysyn         =N,
      agemonthsyn       =N,
      ageweeksyn        =N,
      refdat            =&refdat,
      reftim            =&reftim,
      refdatedsetsubset =&refdatedsetsubset,
      refdateoption     =&refdateoption,
      refdatesourcedset =&refdatesourcedset,
      refdatesourcevar  =&refdatesourcevar,
      refdatevisitnum   =&refdatevisitnum,
      dsettemplate      =&dsettemplate,
      dsplan            =&dsplan,
      sortorder         =&sortorder,
      ptrtcdinf         =&ptrtcdinf,
      trtcdinf          =&trtcdinf,
      decoderename      =&decoderename,
      decodepairs       =&decodepairs,
      formatnamesdset   =&formatnamesdset
      );

   /*
   / Delete temporary datasets used in this macro.
   /----------------------------------------------------------------------------*/

%endmac:

   %tu_tidyup(rmdset=&prefix:, glbmac=NONE);
   %tu_abort;

%mend tc_aeanal;

