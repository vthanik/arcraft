/*
/ Macro Name: td_ae4vctr
/
/ Macro Version: 1 build 2
/
/ SAS Version: 9.3
/
/ Created By: Anthony J Cooper
/
/ Date: 11-Feb-2016
/
/ Macro Purpose: A macro to summarise Serious Adverse Events or most frequently
/                occurring non-serious Adverse Events for Clinical Disclosure 
/                Reporting. Also creates US and EU results format XML files
/                for loading into VCTR.
/
/ Macro Design: Procedure style.
/
/ Input Parameters:
/
/ Name               Description                                Default
/------------------- ------------------------------------------ -----------
/ ACROSSVAR          Variable to transpose the data across to   &g_trtcd
/                    make columns of results. This is passed
/                    to the proc transpose ID statement hence
/                    the values of this variable will be used
/                    to name the new columns. Typically this
/                    will be the code variable containing
/                    treatment.
/                    Valid Values:
/                    Blank
/                    Name of a SAS variable that exists in
/                    DSETINNUMER
/
/ ACROSSVARDECODE    A variable or format used in the           &g_trtgrp
/                    construction of labels for the result
/                    columns.
/                    Valid values:
/                    If DENORMYN is not Y, blank
/                    Otherwise:
/                    Blank
/                    Name of a SAS variable that exists in
/                    DSETINNUMER
/                    An available SAS format
/
/ BREAK1             For input of user-specified break          (Blank)
/ BREAK2             statements
/ BREAK3             Valid values: valid PROC REPORT BREAK
/ BREAK4             statements (without "break")
/ BREAK5             The value of these parameters are passed
/                    directly to PROC REPORT as:
/                    BREAK &break1;
/
/ BYVARS             By variables. The variables listed here    (Blank)
/                    are processed as standard SAS by
/                    variables
/                    Valid values: one or more variable names
/                    from DSETIN
/                    No formatting of the display for these
/                    variables is performed by %tu_display.
/                    The user has the option of the standard
/                    SAS BY line, or using OPTIONS NOBYLINE
/                    and #BYVAL #BYVAR directives in title
/                    statements
/
/ CENTREVARS         Variables to be displayed as centre        (Blank)
/                    justified
/                    Valid values: one or more variable names
/                    from DSETIN that are also defined with
/                    COLUMNS
/                    Variables not appearing in any of the
/                    parameters CENTREVARS, LEFTVARS, or
/                    RIGHTVARS will be displayed using the
/                    PROC REPORT default. Character variables
/                    are left justified while numeric
/                    variables are right justified
/
/ CODEDECODEVARPAIRS Specifies code and decode variable pairs.  &g_trtcd &g_trtgrp
/                    Those variables should be in parameter
/                    GROUPBYVARSNUMER. One variable in the
/                    pair will contain the code and the other
/                    will contain decode.
/                    Valid values:  Blank or a list of SAS
/                    variable names in pairs that are given in
/                    GROUPBYVARSNUMER
/
/ COLSPACING         The value of the between-column spacing    2
/                    Valid values: positive integer
/
/ COLUMNS            A PROC REPORT column statement             tt_spsort aesoc 
/                    specification.  Including spanning         summaryLevel
/                    titles and variable names                  tt_pct999 aedecod
/                    Valid values: one or more variable names   tt_svid tt_svnm 
/                    from DSETIN plus other elements of valid   tt_ac:
/                    PROC REPORT COLUMN statement syntax
/
/ COMPUTEBEFOREPAGE  See Unit Specification for HARP            (Blank)
 /LINES              Reporting Tools TU_LIST for complete
/                    details
/
/ COMPUTEBEFOREPAGE  See Unit Specification for HARP            (Blank)
/ VARS               Reporting Tools TU_LIST for complete
/                    details
/
/ COUNTDISTINCTWHATV Variable(s) that contain values to be      &g_centid
/ AR                 counted uniquely within any output         &g_subjid
/                    grouping.
/                    Valid values:
/                    Blank
/                    Name of one or more SAS variables that
/                    exists in DSETINNUMER
/
/ COMPLETETYPESVARS  Passed to %tu_statswithtotal. Specify a    &g_trtcd             
/                    list of variables which are in 
/                    GROUPBYVARSANALY and the COMPLETETYPES                    
/                    given by PSOPTIONS should be applied to.                         
/                    If it equals _ALL_, all variables in                    
/                    GROUPBYVARSANALY will be included.                                  
/                    Valid values:                                                       
/                    _ALL_                                                               
/                    A list of variable names which are in                               
/                    GROUPBYVARSANALY                                                    
/                                                                                         
/ DDDATASETLABEL     Specifies the label to be applied to the   DD dataset
/                    DD dataset                                 for ae4vctr
/                    Valid values: a non-blank text string      display
/
/ DEFAULTWIDTHS      Specifies column widths for all            aedecod aesoc 30
/                    variables not listed in the WIDTHS         tt_ac: 15
/                    parameter
/                    Valid values: values of column names and
/                    numeric widths such as form valid syntax
/                    for a SAS LENGTH statement
/                    For variables that are not given widths
/                    through either the WIDTHS or
/                    DEFAULTWIDTHS parameter will be width
/                    optimised using:
/                    MAX (variable?s format width,
/                    width of  column header)
/
/ DESCENDING         List of ORDERVARS that are given the       tt_spsort tt_pct999
/                    PROC REPORT define statement attribute
/                    DESCENDING
/                    Valid values: one or more variable names
/                    from DSETIN that are also defined with
/                    ORDERVARS
/
/ DISPLAY            Specifies whether the report should be     Y
/                    created.
/                    Valid values:
/                    Y, N
/                    If &g_analy_disp is D, DISPLAY shall be ignored
/
/ DSETINDENOM        Input dataset containing data to be        &g_popdata
/                    counted to obtain the denominator. This
/                    may or may not be the same as the dataset
/                    specified to DSETINNUMER.
/                    Valid values:
/                    &g_popdata
/                    any other valid SAS dataset reference
/
/ DSETINNUMER        Input dataset containing data to be        adamdata.adae
/                    counted to obtain the numerator.
/                    Valid Values: Valid sas dataset name
/
/ DSETOUT            Name of output dataset                     (Blank)
/                    Valid values: Dataset name
/
/
/ FLOWVARS           Variables to be defined with the flow      aedecod aesoc
/                    option                                     tt_svnm
/                    Valid values: one or more variable names
/                    from DSETIN that are also defined with
/                    COLUMNS
/                    Flow variables should be given a width
/                    through the WIDTHS.  If a flow variable
/                    does not have a width specified, the
/                    column width will be determined by
/                    MIN(variable's format width,
/                    width of  column header)
/
/ FORMATS            Variables and their format for display.    (Blank)
/                    For use where format for display differs
/                    to the format on the DSETIN.
/                    Valid values: values of column names and
/                    formats such as form valid syntax for a
/                    SAS FORMAT statement
/
/ GROUPBYVARPOP      Specifies a list of variables to group by  &g_trtcd
/                    when counting big N using %tu_addbignvar.
/                    Usually one variable &g_trtcd.
/                    It will be passed to GROUPBYVARS of
/                    %tu_addbignvar.
/                    Required if ADDBIGNYN =Y
/                    Valid values:
/                    Blank if ADDBIGNYN=N
/                    Otherwise, a list of valid SAS variable
/                    names that exist in population dataset
/                    created by %tu_freq's calling %tu_getdata
/
/ GROUPBYVARSDENOM   Variables in DSETINDENOM to group the      &g_trtcd
/                    data by when counting to obtain the
/                    denominator.
/                    Valid values:
/                    Blank, _NONE_ (to request an overall
/                    total for the whole dataset)
/                    Name of a SAS variable that exists in
/                    DSETINDENOM
/
/ GROUPBYVARSNUMER   Variables in DSETINNUMER to group the      &g_trtcd (aedecod='ANY EVENT';
/                    data by, along with ACROSSVAR, when        aesoc='DUMMY') aesoc aedecod
/                    counting to obtain the numerator.         
/                    Additionally a set of brackets may be
/                    inserted within the variables to generate
/                    records containing summary counts grouped
/                    by variables specified to the left of the
/                    brackets. Summary records created may be
/                    populated with values in the grouping
/                    variables by specifying variable value
/                    pairs within brackets, seperated by semi
/                    colons. eg aesoccd aesoc(aeptcd=0;
/                    aept="Any Event";) aeptcd aept.
/                    Valid values:
/                    Blank
/                    Name of one or more SAS variables that
/                    exist in DSETINNUMER
/                    SAS assignment statements within brackets
/
/ IDVARS             Variables to appear on each page if the    tt_spsort aesoc  aedecod
/                    report is wider than 1 page. If no value   summaryLevel tt_pct999
/                    is supplied to this parameter then all     tt_svid tt_svnm
/                    displayable order variables will be
/                    defined as IDVARS
/                    Valid values: one or more variable names
/                    from DSETIN that are also defined with
/                    COLUMNS
/
/ LABELS             Variables and their label for display.     (Blank)
/                    For use where label for display differs
/                    to the label on the DSETIN
/                    Valid values: pairs of variable names
/                    and labels
/
/ LEFTVARS           Variables to be displayed as left          (Blank)
/                    justified
/                    Valid values: one or more variable names
/                    from DSETIN that are also defined with
/                    COLUMNS
/
/ LINEVARS           List of order variables that are printed   (Blank)
/                    with LINE statements in PROC REPORT
/                    Valid values: one or more variable names
/                    from DSETIN that are also defined with
/                    ORDERVARS
/                    These values shall be written with a
/                    BREAK BEFORE when the value of one of
/                    the variables changes. The variables
/                    will automatically be defined as NOPRINT
/
/ NOPRINTVARS        Variables listed in the COLUMN parameter   tt_spsort summaryLevel 
/                    that are given the PROC REPORT define      tt_ac999 tt_pct999 tt_svid
/                    statement attribute noprint               
/                    Valid values: one or more variable names
/                    from DSETIN that are also defined with
/                    COLUMNS
/                    These variables are ORDERVARS used to
/                    control the order of the rows in the
/                    display
/
/ NOWIDOWVAR         Variable whose values must be kept         aedecod
/                    together on a page
/                    Valid values: names of one or more
/                    variables specified in COLUMNS
/
/ ORDERDATA          Variables listed in the ORDERVARS          (Blank)
/                    parameter that are given the PROC REPORT
/                    define statement attribute order=data
/                    Valid values: one or more variable names
/                    from DSETIN that are also defined with
/                    ORDERVARS
/                    Variables not listed in ORDERFORMATTED,
/                    ORDERFREQ, or ORDERDATA are given the
/                    define attribute order=internal
/
/ ORDERFORMATTED     Variables listed in the ORDERVARS          (Blank)
/                    parameter that are given the PROC REPORT
/                    define statement attribute
/                    order=formatted
/                    Valid values: one or more variable names
/                    from DSETIN that are also defined with
/                    ORDERVARS
/                    Variables not listed in ORDERFORMATTED,
/                    ORDERFREQ, or ORDERDATA are given the
/                    define attribute order=internal
/
/ ORDERFREQ          Variables listed in the ORDERVARS          (Blank)
/                    parameter that are given the PROC REPORT
/                    define statement attribute order=freq
/                    Valid values: one or more variable names
/                    from DSETIN that are also defined with
/                    ORDERVARS
/                    Variables not listed in ORDERFORMATTED,
/                    ORDERFREQ, or ORDERDATA are given the
/                    define attribute order=internal
/
/ ORDERVARS          List of variables that will receive the    tt_spsort aesoc 
/                    PROC REPORT define statement attribute     summaryLevel tt_pct999 
/                    ORDER                                      aedecod tt_svid tt_svnm
/                    Valid values: one or more variable names
/                    from DSETIN that are also defined with
/                    COLUMNS
/
/ OVERALLSUMMARY     Setting to Y will cause the macro to       Y
/                    produce an overall summary line, for use 
/                    with sharecolvars
/
/ PAGEVARS           Variables whose change in value causes     (Blank)
/                    the display to continue on a new page
/                    Valid values: one or more variable names
/                    from DSETIN that are also defined with
/                    COLUMNS
/
/ POSTSUBSET         SAS expression to be applied to data        (Blank)
/                    immediately prior to creation of the
/                    permanent presentation dataset. Used for
/                    subsetting records required for
/                    computation but not for display.
/                    Valid values:
/                    Blank
/                    A complete, syntactically valid SAS where
/                    or if statement for use in a data step
/
/ PROPTIONS          PROC REPORT statement options to be used    Headline
/                    in addition to MISSING
/                    Valid values: proc report options
/                    The option ?Missing? can not be
/                    overridden
/
/ PSOPTIONS          PROC SUMMARY Options to use. MISSING        COMPLETETYPES MISSING NWAY
/                    ensures that class variables with missing
/                    values are treated as a valid grouping.
/                    COMPLETETYPES adds records showing a freq
/                    or n of 0 to ensure a cartesian product
/                    of all class variables exists in the
/                    output. NWAY writes output for the lowest
/                    level  combinations of CLASS variables,
/                    suppressing all higher level totals.
/                    Valid values:
/                    Blank
/                    One or more valid PROC SUMMARY options
/
/ PSCLASSOPTIONS     PROC SUMMARY Class Statement Options.       PRELOADFMT
/                    Valid values:
/                    Blank
/                    Valid PROC SUMMARY CLASS Options (without 
/                    the leading '/')
/                    Eg: PRELOADFMT  which can be used in
/                    conjunction with PSFORMAT and 
/                    COMPLETETYPES (default in PSOPTIONS) to 
/                    create records for possible categories 
/                    that are specified in a format but which 
/                    may not exist in data being summarised.
/                                                                      
/ PSFORMAT           Passed to the PROC SUMMARY FORMAT .         &g_trtcd &g_trtfmt
/                    statement
/                    Valid values:
/                    Blank
/                    Valid PROC SUMMARY FORMAT statement part.
/
/ RESULTPCTDPS       The reporting precision for percentages    0
/                    Valid values:
/                    0 or any positive integer
/
/ RESULTSTYLE        The appearance style of the result         NUMERPCT
/                    columns that will be displayed in the
/                    report. The chosen style will be placed
/                    in variable &RESULTVARNAME.
/                    Valid values:
/                    As documented for tu_percent in [6]. In
/                    typical usage, NUMERPCT.
/
/ RIGHTVARS          Variables to be displayed as right         (Blank)
/                    justified
/                    Valid values: one or more variable names
/                    from DSETIN that are also defined with
/                    COLUMNS
/
/ SHARECOLVARS       List of variables that will share print    aesoc aedecod
/                    space. The attributes of the last
/                    variable in the list define the column
/                    width and flow options
/                    Valid values: one or more variable names
/                    from DSETIN
/                    AE1 shows an example of this style of
/                    output
/                    The formatted values of the variables
/                    shall be written above each other in one
/                    column
/
/ SHARECOLVARSINDENT Indentation factor for ShareColVars.       2
/                    Stacked values shall be progressively
/                    indented by multiples of
/                    ShareColVarsIndent
/                    Valid values: positive integer
/
/ SKIPVARS           Variables whose change in value causes     aesoc 
/                    the display to skip a line
/                    Valid values: one or more variable names
/                    from DSETIN that are also defined with
/                    COLUMNS
/
/ SPLITCHAR          The split character used in column         ~
/                    labels. Used in the creation of the label
/                    for the result columns, and in
/                    %tu_stackvar, %tu_display (PROC REPORT).
/                    Usually ~
/                    Valid values:
/                    Valid SAS split character.
/
/ SPSORTGROUPBYVARSD Special sort: variables in DSETINDENOM to  (Blank)
/ ENOM               group the data by when counting to obtain
/                    the denominator.
/                    Valid values:
/                    Blank if SPSORTRESULTVARNAME is blank
/                    Otherwise,
/                    Blank
/                    _NONE_
/                    Name of a SAS variable that exists in
/                    DSETINDENOM
/
/ SPSORTGROUPBYVARSN Special sort: variables in DSETINNUMER to  aesoc
/ UMER               group the data by when counting to obtain
/                    the numerator.
/                    Valid values:
/                    Blank if SPSORTRESULTVARNAME is blank
/                    Otherwise,
/                    Name of one or more SAS variables that
/                    exist in DSETINNUMER
/
/ SPSORTRESULTSTYLE  Special sort: the appearance style of the  PCT
/                    result data that will be used to sequence
/                    the report. The chosen style will be
/                    placed in variable SPSORTRESULTVARNAME
/                    Valid values:
/                    Blank if SPSORTRESULTVARNAME is blank
/                    Otherwise, as documented for tu_percent.
/                    In typical usage, NUMERPCT.
/
/ TOTALDECODE        Label for the total result column.         Total
/                    Usually the text Total
/                    Valid values:
/                    Blank
/                    SAS data step expression resolving to a
/                    character.
/
/ TOTALFORVAR        Variable for which total is required       &g_trtcd
/                    within all other grouped classvars
/                    (usually trtcd). If not specified, no
/                    total will be produced
/                    Valid values: Blank if TOTALID is blank,
/                    else the name of a variable that exists
/                    in DSETIN.
/
/ TOTALID            Value used to populate the variable        999
/                    specified in ACROSSVAR on data that
/                    represents the overall total for the
/                    ACROSSVAR variable.
/                    If no value is specified to this
/                    parameter then no overall total of the
/                    ACROSSVAR variable will be generated.
/                    Valid values
/                    Blank
/                    A value that can be entered into
/                    &ACROSSVAR without SAS error or
/                    truncation
/
/ VARSPACING         Spacing for individual columns             (Blank)
/                    Valid values: variable name followed by
/                    a spacing value, e.g.
/                    Varspacing=a 1 b 2 c 0
/                    This parameter does NOT allow SAS
/                    variable lists.
/                    These values will override the overall
/                    COLSPACING parameter.
/                    VARSPACING defines the number of blank
/                    characters to leave between the column
/                    being defined and the column immediately
/                    to its left
/
/ WIDTHS             Variables and width to display             (Blank)
/                    Valid values: values of column names and
/                    numeric widths, a list of variables
/                    followed by a positive integer, e.g.
/
/                    widths = a b 10 c 12 d1-d4 6
/                    Numbered range lists are supported in
/                    this parameter however name range lists,
/                    name prefix lists, and special SAS name
/                    lists are not.
/                    Display layout will be optimised by
/                    default, however any specified widths
/                    will cause the default to be overridden
/
/ VCTRCR8USXMLYN     Controls whether the tu_cr8xml4vctr        Y
/                    utility macro creates a US results format
/                    XML file
/                    Valid values: Y or N
/
/ VCTRCR8EUXMLYN     Controls whether the tu_cr8xml4vctr        Y
/                    utility macro creates a EU results format
/                    XML file
/                    Valid values: Y or N
/
/ VCTRSTUDYID        Specifies the VCTR study identifier which  %upcase(&g_study_id)
/                    may be different to the HARP study
/                    identifier
/
/ SERIOUSAE          Controls whether Serious AEs only will     Y
/                    be summarised. If Y then any threshold
/                    value (FREQPCTCUTOFF) will be ignored
/                    Valid values: Y or N
/
/ FREQPCTCUTOFF      Percentage cut off value that is used to   (blank)
/                    subset the non-serious adverse events.
/                    Any adverse event that has a percentage
/                    greater than or equal to FREQPCTCUTOFF
/                    in any treatment arm will be included.
/                    Numeric value, required when SERIOUSAE=N
/
/ RELATEDAESUBSET    SAS where clause that is used to subset    aerel eq 'Y'
/                    serious adverse events which are related
/                    to treatment
/                    Required when SERIOUSAE=Y
/
/ FATALAESUBSET      SAS where clause that is used to subset    upcase(aeout)
/                    serious adverse events which are fatal      eq 'FATAL'
/                    Required when SERIOUSAE=Y
/
/ VCTRTRTDESCRFMT    SAS format used to format the treatment    (blank)
/                    code value to the long treatment 
/                    description (passed into the armDescription
/                    field in the XML file)
/                    Valid values: Valid SAS format name or blank
/
/ VCTRFREQUENCTDSET  Specifies a name of a work or permanent    (blank)
/ OUT                dataset which will contain the frequency
/                    threshold data which is used to create
/                    the XML output file
/
/ VCTRFGROUPSDSETOUT Specifies a name of a work or permanent    (blank)
/                    dataset which will contain the treatment
/                    arms data prior to the call to the XML
/                    creation utility
/
/ VCTRFRESULTSDSET   Specifies a name of a work or permanent    (blank)
/ OUT                dataset which will contain the adverse
/                    events summary data prior to the call 
/                    to the XML creation utility
/
/-----------------------------------------------------------------------
/
/ Output: Printed output.
/
/ Global macro variables created: NONE
/
/
/ Macros called:
/
/ (@) tr_putlocals
/ (@) tu_putglobals
/ (@) tu_chknames
/ (@) tu_chkvarsexist
/ (@) tu_words
/ (@) tu_nobs
/ (@) tu_getdata
/ (@) tu_freq
/ (@) tu_list
/ (@) tu_align
/ (@) tu_cr8xml4vctr
/ (@) tu_abort
/ (@) tu_tidyup
/
/ Example:
/    %td_ae4vctr()
/
/*******************************************************************************
/ Change Log
/
/ Modified By: Anthony J  Cooper
/ Date of Modification: 11-Apr-2016
/ New version number: 1 build 2
/ Modification ID: AJC001
/ Reason For Modification: 1. Add new macro parameter to allow VCTR study
/                             identifer to be passed in, which may be different
/                             to the HARP study identifier. Default is
/                             uppercase of HARP study identifier.
/
/************************************************************************************************/

%macro td_ae4vctr (
         acrossvar               = &g_trtcd,          /* Variable(s) that will be transposed to columns */
         acrossvardecode         = &g_trtgrp,         /* The name of the decode variable(s) for ACROSSVAR */
         break1                  =  ,                 /* Break statements. */
         break2                  =  ,                 /* Break statements. */
         break3                  =  ,                 /* Break statements. */
         break4                  =  ,                 /* Break statements. */
         break5                  =  ,                 /* Break statements. */
         byvars                  =  ,                 /* By variables */
         centrevars              =  ,                 /* Centre justify variables */
         codeDecodeVarPairs      =  &g_trtcd &g_trtgrp, /* Code and Decode variables in pairs */
         colspacing              =  2,                /* Overall spacing value. */
         columns                 =  tt_spsort aesoc summaryLevel tt_pct999 aedecod tt_svid tt_svnm tt_ac:, /* Column parameter */
         computebeforepagelines  =  ,                 /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt colon labelvar) */
         computebeforepagevars   =  ,                 /* Names of variables that shall define the sort order for Compute Before Page lines */
         countDistinctWhatVar    =  &g_centid &g_subjid, /* Variable(s) that contain values to be counted uniquely within any output grouping. Eg &g_subjid */
         completetypesvars       =  &g_trtcd,         /* Variables which COMPLETETYPES should be applied to */ 
         dddatasetlabel          =  DD dataset for ae4vctr display,/* Label to be applied to the DD dataset */
         defaultwidths           =  aedecod aesoc 30 tt_ac: 15, /* List of default column widths */
         descending              =  tt_spsort tt_pct999, /* Descending ORDERVARS */
         display                 =  Y,                /* Specifies whether the report should be created */
         dsetinDenom             =  &g_popdata,       /* Input dataset containing data to be counted to obtain the denominator. */
         dsetinNumer             =  adamdata.adae,    /* Input dataset containing data to be counted to obtain the numerator. */
         dsetout                 =  ,                 /* Name of output dataset */
         flowvars                =  aedecod aesoc tt_svnm, /* Variables with flow option */
         formats                 =  ,                 /* Format specification */
         groupByVarPop           =  &g_trtcd,         /* Variables to group by when counting big N  */
         groupByVarsDenom        =  &g_trtcd,         /* Variables in DSETINDENOM to group the data by when counting to obtain the denominator. */
         groupByVarsNumer        =  &g_trtcd (aedecod='ANY EVENT'; aesoc='DUMMY') aedecod aesoc, /* Variables in DSETINNUMER to group the data by when counting to obtain the numerator. */
         idvars                  =  tt_spsort aesoc summaryLevel tt_pct999 aedecod tt_svid tt_svnm, /* ID variables */
         labels                  =  aedecod='System Organ Class~   Preferred Term',
         leftvars                =  ,                 /* Left justify variables */
         linevars                =  ,                 /* Order variable printed with line statements. */
         noprintVars             =  tt_spsort summaryLevel tt_ac999 tt_pct999 tt_svid, /* No print vars (usually used to order the display) */
         nowidowvar              =  aedecod,          /* Variable whose values must be kept together on a page */
         orderdata               =  ,                 /* ORDER=DATA variables */
         orderformatted          =  ,                 /* ORDER=FORMATTED variables */
         orderfreq               =  ,                 /* ORDER=FREQ variables */
         ordervars               =  tt_spsort aesoc summaryLevel tt_pct999 aedecod tt_svid tt_svnm, /* Order variables */
         overallsummary          =  Y,                /* Does the display contain an overallsummary line */
         pagevars                =  ,                 /* Break after <var> / page */
         postSubset              =  ,                 /* SAS IF statement to apply to data immediately prior to creation of the permanent presentation dataset */
         proptions               =  headline,         /* PROC REPORT statement options */
         psOptions               =  COMPLETETYPES NWAY MISSING, /* PROC SUMMARY options to use */
         psclassoptions          =  PRELOADFMT,       /* PROC SUMMARY CLASS Statement Options */
         psformat                =  &g_trtcd &g_trtfmt, /* Passed to the PROC SUMMARY FORMAT statement. */
         resultPctDps            =  0,                /* The reporting precision for percentages */
         resultStyle             =  NUMERPCT,         /* The appearance style of the result columns that will be displayed in the report. */
         resultVarName           =  tt_result,        /* Name of the variable to hold the result of the frequency count */
         rightVars               =  ,                 /* Right justify variables */
         sharecolvars            =  aesoc aedecod,    /* Order variables that share print space. */
         sharecolvarsindent      =  2,                /* Indentation factor */
         skipvars                =  aesoc,            /* Break after <var> / skip */
         splitChar               =  ~,                /* The split character used in column labels. */
         spSortGroupByVarsDenom  =  ,                 /* Special sort: variables in DSETINDENOM to group the data by when counting to obtain the denominator. */
         spSortGroupByVarsNumer  =  aesoc,            /* Special sort: variables in DSETINNUMER to group the data by when counting to obtain the numerator. */
         spSortResultStyle       =  PCT,              /* Special sort: the appearance style of the result data that will be used to sequence the report. */
         totalDecode             =  Total,            /* Label for the total result column. */
         totalForVar             =  &g_trtcd,         /* Variables in DSETINDENOM to group the data by when counting to obtain the denominator. */
         totalID                 =  999,              /* Value used to populate the variable specified in ACROSSVAR on data that represents the overall total for the ACROSSVAR variable. */
         varspacing              =  ,                 /* Spacing for individual variables. */
         widths                  =  ,                 /* Column widths */
         vctrcr8usxmlyn          =  Y,                /* Create US format results XML file for loading into VCTR? */
         vctrcr8euxmlyn          =  Y,                /* Create EU format results XML file for loading into VCTR? */
         vctrstudyid             =  %upcase(&g_study_id), /* VCTR study identifier */
         seriousAE               =  Y,                /* Controls whether serious adverse events only are summarised  */
         freqpctcutoff           =  ,                 /* Percentage cut off value for most frequent adverse events */
         relatedaesubset         =  aerel eq 'Y',     /* Where clause to identify adverse events related to treatment */
         fatalaesubset           =  upcase(aeout) eq 'FATAL', /* Where clause to identify fatal adverse events */
         vctrtrtdescrfmt         =  ,                 /* User defined format to format the treatment code to the long treatment text field */
      	 vctrfrequencydsetout    =  ,                 /* Output dataset to contain the frequency threshold data prior to call to the xml creation utility */ 
         vctrgroupsdsetout       =  ,                 /* Output dataset to contain the treatment arms source data prior to call to the xml creation utility */
	     vctrresultsdsetout      =                    /* Output dataset to contain the adverse event summary data prior to call to the xml creation utility */
      );

  /*
  / Echo parameter values and global macro variables to the log.
  /----------------------------------------------------------------------------*/

  %local MacroVersion MacroName;
  %let MacroVersion = 1 build 2;
  %let MacroName=&sysmacroname.;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_study_id) 

  /*
  / Parameter validation
  /----------------------------------------------------------------------------*/

  %let vctrcr8usxmlyn = %nrbquote(%upcase(&vctrcr8usxmlyn));
  %let vctrcr8euxmlyn = %nrbquote(%upcase(&vctrcr8euxmlyn));
  %let seriousAE=%nrbquote(%upcase(&seriousAE));
  %let display=%nrbquote(%upcase(&display));

  %local l_wordlist l_thisword l_i;

  %let l_wordlist=VCTRCR8USXMLYN VCTRCR8EUXMLYN SERIOUSAE DISPLAY;
  %do l_i = 1 %to 4;
    %let l_thisword = %scan(&l_wordlist, &l_i);
    %if ( %qupcase(&&&l_thisword) ne Y ) and ( %qupcase(&&&l_thisword) ne N ) %then 
    %do;
      %put %str(RTE)RROR: &sysmacroname: Value of parameter &l_thisword (=&&&l_thisword) is invalid. Valid value should be Y or N;
      %let g_abort=1;
    %end;
  %end;

  %if %length(&vctrstudyid) eq 0 %then
  %do;
     %put %str(RTE)RROR: &sysmacroname: The parameter VCTRSTUDYID is required.;
     %let g_abort=1;
  %end; /* AJC001: Validation for VCTR study identifier parameter */

  %if &seriousAE eq Y %then
  %do;

    %if %length(&relatedaesubset) eq 0 %then
    %do;
      %put %str(RTE)RROR: &sysmacroname: Parameter RELATEDAESUBSET is required when reporting serious adverse events.;
      %let g_abort=1;
    %end;

    %if %length(&fatalaesubset) eq 0 %then
    %do;
      %put %str(RTE)RROR: &sysmacroname: Parameter FATALAESUBSET is required when reporting serious adverse events.;
      %let g_abort=1;
    %end;

    %if %length(&freqpctcutoff) gt 0 %then
    %do;
      %put %str(RTW)ARNING: &sysmacroname: Parameter FREQPCTCUTOFF is not required when reporting serious adverse events. It will be ignored.;
    %end;

    %if %length(&VCTRFREQUENCYDSETOUT) gt 0 %then
    %do;
      %put %str(RTW)ARNING: &sysmacroname: Dataset specified in parameter VCTRFREQUENCYDSETOUT (=&VCTRFREQUENCYDSETOUT) will not be created when reporting serious adverse events.;
    %end;

  %end;

  %else %if &seriousAE eq N %then
  %do;

    %if %length(&freqpctcutoff) eq 0 %then
    %do;
      %put %str(RTE)RROR: &sysmacroname: Parameter FREQPCTCUTOFF is required when reporting most frequently occurring non-serious adverse events.;
      %let g_abort = 1;
    %end;

    %else %if %datatyp(&freqpctcutoff) ne NUMERIC %then
    %do;
      %put %str(RTE)RROR: &sysmacroname: Parameter FREQPCTCUTOFF (=&FREQPCTCUTOFF) must contain a numeric value.;
      %let g_abort = 1;
    %end;

    %if %length(&relatedaesubset) gt 0 %then
    %do;
      %put %str(RTW)ARNING: &sysmacroname: Parameter RELATEDAESUBSET is not required when reporting most frequently occurring non-serious adverse events. It will be ignored.;
    %end;

    %if %length(&fatalaesubset) gt 0 %then
    %do;
      %put %str(RTW)ARNING: &sysmacroname: Parameter FATALAESUBSET is not required when reporting most frequently occurring non-serious adverse events. It will be ignored.;
    %end;

  %end;

  %if %length(&dsetout) gt 0 %then
  %do;
    %if %length(%tu_chknames(&dsetout, DATA)) gt 0 %then
    %do;
      %put %str(RTE)RROR: &sysmacroname: Parameter DSETOUT (=&dsetout) should be either blank or resolve to a valid SAS dataset name.;
      %let g_abort = 1;
    %end;
  %end;

  %if %length(&vctrfrequencydsetout) gt 0 %then
  %do;
    %if %length(%tu_chknames(&vctrfrequencydsetout, DATA)) gt 0 %then
    %do;
      %put %str(RTE)RROR: &sysmacroname: Parameter VCTRFREQUENCYDSETOUT (=&vctrfrequencydsetout) should be either blank or resolve to a valid SAS dataset name.;
      %let g_abort = 1;
    %end;
  %end;

  %if %length(&vctrgroupsdsetout) gt 0 %then
  %do;
    %if %length(%tu_chknames(&vctrgroupsdsetout, DATA)) gt 0 %then
    %do;
      %put %str(RTE)RROR: &sysmacroname: Parameter VCTRGROUPSDSETOUT (=&vctrgroupsdsetout) should be either blank or resolve to a valid SAS dataset name.;
      %let g_abort = 1;
    %end;
  %end;

  %if %length(&vctrresultsdsetout) gt 0 %then
  %do;
    %if %length(%tu_chknames(&vctrresultsdsetout, DATA)) gt 0 %then
    %do;
      %put %str(RTE)RROR: &sysmacroname: Parameter VCTRRESULTSDSETOUT (=&vctrresultsdsetout) should be either blank or resolve to a valid SAS dataset name.;
      %let g_abort = 1;
    %end;
  %end;

  %if %length(&vctrtrtdescrfmt) gt 0 %then
  %do;

    data _null_;
      rx = prxparse('/^(?:(?:\$(_|[a-z])\w{0,30})|(?:(_|[a-z])\w{0,31}))\./i');
      if not prxmatch(rx, "&vctrtrtdescrfmt") then
      do;
        put "RTE" "RROR: &sysmacroname: Parameter VCTRTRTDESCRFMT (=&vctrtrtdescrfmt) should be either blank or resolve to a valid SAS format name.";
        call symput('g_abort', '1');
      end;
      call prxfree(rx);
      stop;
    run;

  %end;

  %if &g_abort eq 1 %then
  %do;
    %tu_abort
  %end;

  /*
  / NORMAL PROCESSING
  /----------------------------------------------------------------------------*/
 
  %local
    prefix             /* Root name for temporary work datasets */
    datatype           /* Type of data to pass to XML utility macro */
    aefrequencydset    /* Name of frequency threshold dataset to pass to XML utility macro */
    numSubjectsEvents  /* Name of variable in Groups dataset containing number of subjects affected */
    numSubjects        /* Name of variable in Groups dataset containing number of subjects exposed */
    aesubset           /* Initial subset to apply to input dataset (serious or non-serious events) */
    preftermvar        /* Name of AE Preferred Term variable */
    ;

  %let prefix = &sysmacroname._;  

  %if &seriousAE eq Y %then
  %do;
    %let datatype = SERIOUSAE;
    %let aefrequencydset =;
    %let numSubjectsEvents = numSubjectsSeriousEvents;
    %let numSubjects = partAtRiskSeriousEvents;
    %let aesubset=aeser eq 'Y';
  %end;
  %else %if &seriousAE eq N %then
  %do;
    %let datatype = FREQUENTAE;
    %let aefrequencydset = &prefix.frequency;
    %let numSubjectsEvents = numSubjectsFrequentEvents;
    %let numSubjects = partAtRiskFrequentEvents;
    %let aesubset=aeser eq 'N';
  %end;

  /*
  / Delete any existing XML file
  --------------------------------------------------------------------------*/
  
  %tu_cr8xml4vctr(
    usage=DELETE,
    vctrstudyid=&vctrstudyid,
    datatype=&datatype
    ); /* AJC001: Pass VCTR study ID to utility macro */

  /*
  / Perform initial dataset subset for serious or non-serious events,
  / then call tu_getdata to perform any user subsetting before
  / checking if we have any events to report.
  --------------------------------------------------------------------------*/
  
  data &prefix.dsetinNumer0;
    set &dsetinNumer;
    where &aesubset;
  run;

  %tu_getdata(
    dsetin=&prefix.dsetinNumer0,
    dsetout1=&prefix.dsetinNumer
    );

  %let preftermvar=%tu_chkvarsexist(&prefix.dsetinNumer, aept aedecod, Y);
  %put RTNOTE: &sysmacroname: Preferred Term variable identified as &preftermvar..;

  %if %tu_words(&preftermvar) ne 1 %then
  %do;
    %put %str(RTE)RROR: &sysmacroname: Unable to uniquely identify preferred term variable in input dataset DSETINNUMER (=&dsetinnumer).;
    %let g_abort=1;
  %end;

  %if &g_abort eq 1 %then
  %do;
    %tu_abort
  %end;

  %if %tu_nobs(&prefix.dsetinNumer)=0 %then
  %do;
        
    data &prefix.final;
      set &prefix.dsetinNumer;
    run;
    
    %goto noevents;

  %end;

  /*
  / For non-serious adverse events identify the most commonly occurring 
  / events, i.e. those with a percentage (unrounded) greater than or equal
  / to the user defined threshold in any treatment group.
  --------------------------------------------------------------------------*/
  
  %if &seriousAE eq N %then
  %do;

    %tu_freq(
	   acrossColListName       =  ,
	   acrossColVarPrefix      =  ,
	   acrossVar               =  ,
	   acrossVarDecode         =  ,
	   addBigNYN               =  N,
	   BigNVarName             =  tt_bnnm,
	   codeDecodeVarPairs      =  &codeDecodeVarPairs,
	   completetypesvars       =  &completetypesvars,
	   countDistinctWhatVar    =  &countDistinctWhatVar,
	   denormYN                =  N,
	   display                 =  N,
	   dsetinDenom             =  &dsetinDenom,
	   dsetinNumer             =  &prefix.dsetinNumer,
	   dsetout                 =  &prefix.all_events,
	   groupByVarPop           =  &groupByVarPop,
	   groupByVarsDenom        =  &groupByVarsDenom,
	   groupByVarsNumer        =  &groupByVarsNumer,
	   groupminmaxvar          =  ,
	   labelvarsyn             =  Y,
	   postSubset              =  ,
	   psByvars                =  ,
	   psClass                 =  ,
	   psClassOptions          =  &psClassOptions,
	   psFormat                =  &psFormat,
	   psFreq                  =  ,
	   psid                    =  ,
	   psOptions               =  &psOptions,
	   psOutput                =  ,
	   psOutputOptions         =  ,
	   psTypes                 =  ,
	   psWays                  =  ,
	   psWeight                =  ,
	   remSummaryPctYN         =  N,
	   resultPctDps            =  &resultPctDps,
	   resultStyle             =  &resultStyle,
	   resultVarName           =  &resultVarName,
	   rowLabelVarName         =  ,
	   spsort2groupbyvarsdenom =  ,                   
	   spsort2groupbyvarsnumer =  ,                   
	   spsort2resultstyle      =  ,                   
	   spsort2resultvarname    =  ,                   
	   spSortGroupByVarsDenom  =  &spSortGroupByVarsDenom,
	   spSortGroupByVarsNumer  =  &spSortGroupByVarsNumer,
	   spSortResultStyle       =  &spSortResultStyle,
	   spSortResultVarName     =  tt_spsort,
	   summaryLevelVarName     =  summaryLevel,
	   totalDecode             =  ,
	   totalForVar             =  ,
	   totalID                 =  ,
	   varlabelstyle           =  SHORT,
	   varsToDenorm            =  
       );

    %if &g_debug ge 5 %then
    %do;
      title "&sysmacroname.: List of non-serious AEs with percentage >=&freqpctcutoff in any treatment group";
      proc print data=&prefix.all_events width=min;
        where summarylevel=2 and tt_pct>=&freqpctcutoff;
        var aesoc &preftermvar &acrossvardecode tt_numercnt tt_pct; 
      run;
    %end;

    proc sort data=&prefix.all_events out=&prefix.events2include (keep=aesoc &preftermvar tt_pct) nodupkey;
      by aesoc &preftermvar;
      where summarylevel=2 and tt_pct>=&freqpctcutoff;
    run;

    proc sort data=&prefix.dsetinNumer;
      by aesoc &preftermvar;
    run;

    data &prefix.dsetinNumer;
      merge &prefix.dsetinNumer (in=a) &prefix.events2include (keep=aesoc &preftermvar in=b);
      by aesoc &preftermvar;
      if a and b;
    run;

    %if %tu_nobs(&prefix.dsetinNumer)=0 %then
    %do;
          
      data &prefix.final;
        set &prefix.dsetinNumer;
      run;
      
      %goto noevents;

    %end;

  %end; /* %if &seriousAE eq N %then %do; */

  /*
  / Determine the numbers and percentages of subjects affected by the
  / events to be reported 
  /----------------------------------------------------------------------*/

  %tu_freq(
	 acrossColListName       =  acrossColList,
	 acrossColVarPrefix      =  tt_ac,
	 acrossVar               =  &acrossVar,
	 acrossVarDecode         =  &acrossVarDecode,
	 addBigNYN               =  Y,
	 BigNVarName             =  tt_bnnm,
	 codeDecodeVarPairs      =  &codeDecodeVarPairs,
	 completetypesvars       =  &completetypesvars,
	 countDistinctWhatVar    =  &countDistinctWhatVar,
	 denormYN                =  Y,
	 display                 =  N,
	 dsetinDenom             =  &dsetinDenom,
	 dsetinNumer             =  &prefix.dsetinNumer,
	 dsetout                 =  &prefix.listed_events,
	 groupByVarPop           =  &groupByVarPop,
	 groupByVarsDenom        =  &groupByVarsDenom,
	 groupByVarsNumer        =  &groupByVarsNumer,
	 groupminmaxvar          =  ,
	 labelvarsyn             =  Y,
	 postSubset              =  tt_svid=1,
	 psByvars                =  ,
	 psClass                 =  ,
	 psClassOptions          =  &psClassOptions,
	 psFormat                =  &psFormat,
	 psFreq                  =  ,
	 psid                    =  ,
	 psOptions               =  &psOptions,
	 psOutput                =  ,
	 psOutputOptions         =  ,
	 psTypes                 =  ,
	 psWays                  =  ,
	 psWeight                =  ,
	 remSummaryPctYN         =  N,
	 resultPctDps            =  &resultPctDps,
	 resultStyle             =  &resultStyle,
	 resultVarName           =  &resultVarName,
	 rowLabelVarName         =  ,
	 spsort2groupbyvarsdenom =  ,                   
	 spsort2groupbyvarsnumer =  ,                   
	 spsort2resultstyle      =  ,                   
	 spsort2resultvarname    =  ,                   
	 spSortGroupByVarsDenom  =  &spSortGroupByVarsDenom,
	 spSortGroupByVarsNumer  =  &spSortGroupByVarsNumer,
	 spSortResultStyle       =  &spSortResultStyle,
	 spSortResultVarName     =  tt_spsort,
	 summaryLevelVarName     =  summaryLevel,
	 totalDecode             =  &totalDecode,
	 totalForVar             =  &totalForVar,
	 totalID                 =  &totalID,
	 varlabelstyle           =  SHORT,
	 varsToDenorm            =  tt_result tt_pct
     );

  /*
  / Determine the number of events (as opposed to subjects)
  / Same call to tu_freq as before except countDistinctWhatVar is set to 
  / missing, resultstyle=NUMER, resultvarname=num_event and no totals
  /----------------------------------------------------------------------*/

  %tu_freq(
	 acrossColListName       =  acrossColList,
	 acrossColVarPrefix      =  tt_ac,
	 acrossVar               =  &acrossVar,
	 acrossVarDecode         =  &acrossVarDecode,
	 addBigNYN               =  Y,
	 BigNVarName             =  tt_bnnm,
	 codeDecodeVarPairs      =  &codeDecodeVarPairs,
	 completetypesvars       =  &completetypesvars,
	 countDistinctWhatVar    =  ,
	 denormYN                =  Y,
	 display                 =  N,
	 dsetinDenom             =  &dsetinDenom,
	 dsetinNumer             =  &prefix.dsetinNumer,
	 dsetout                 =  &prefix.num_events,
	 groupByVarPop           =  &groupByVarPop,
	 groupByVarsDenom        =  &groupByVarsDenom,
	 groupByVarsNumer        =  &groupByVarsNumer,
	 groupminmaxvar          =  ,
	 labelvarsyn             =  Y,
	 postSubset              =  tt_svid=2,
	 psByvars                =  ,
	 psClass                 =  ,
	 psClassOptions          =  &psClassOptions,
	 psFormat                =  &psFormat,
	 psFreq                  =  ,
	 psid                    =  ,
	 psOptions               =  &psOptions,
	 psOutput                =  ,
	 psOutputOptions         =  ,
	 psTypes                 =  ,
	 psWays                  =  ,
	 psWeight                =  ,
	 remSummaryPctYN         =  N,
	 resultPctDps            =  &resultPctDps,
	 resultStyle             =  NUMER,
	 resultVarName           =  &resultVarName,
	 rowLabelVarName         =  ,
	 spsort2groupbyvarsdenom =  ,                   
	 spsort2groupbyvarsnumer =  ,                   
	 spsort2resultstyle      =  ,                   
	 spsort2resultvarname    =  ,                   
	 spSortGroupByVarsDenom  =  ,
	 spSortGroupByVarsNumer  =  ,
	 spSortResultStyle       =  ,
	 spSortResultVarName     =  ,
	 summaryLevelVarName     =  summaryLevel,
	 totalDecode             =  &totalDecode,
	 totalForVar             =  &totalForVar,
	 totalID                 =  &totalID,
	 varlabelstyle           =  SHORT,
	 varsToDenorm            =  tt_result
     );

  /*
  / Merge the sorting variables for each AE onto each row so available
  / for ordering the display.
  /----------------------------------------------------------------------*/

  proc sort data=&prefix.listed_events out=&prefix.sortvars (keep=summaryLevel aesoc &preftermvar tt_spsort tt_pct999);
    by summaryLevel aesoc &preftermvar;
  run;

  proc sort data=&prefix.num_events;
    by summaryLevel aesoc &preftermvar;
  run;

  data &prefix.num_events;
    merge &prefix.num_events &prefix.sortvars;
    by summaryLevel aesoc &preftermvar;
  run;

  data &prefix.comb1;
    set &prefix.listed_events &prefix.num_events;
  run;

  /*
  / For serious adverse events determine the following additional counts: 
  /   1. Number of SAEs related to treatment
  /   2. Number of fatal SAEs
  /   3. Number of fatal SAEs related to treatment
  --------------------------------------------------------------------------*/
  
  %if &seriousAE eq Y %then
  %do;

    %tu_freq(
       acrossColListName       =  acrossColList,
       acrossColVarPrefix      =  tt_ac,
       acrossVar               =  &acrossVar,
       acrossVarDecode         =  &acrossVarDecode,
       addBigNYN               =  Y,
       BigNVarName             =  tt_bnnm,
       codeDecodeVarPairs      =  &codeDecodeVarPairs,
       completetypesvars       =  &completetypesvars,
       countDistinctWhatVar    =  ,
	   denormYN                =  Y,
       display                 =  N,
       dsetinDenom             =  &dsetinDenom,
       dsetinNumer             =  &prefix.dsetinNumer(where=(&relatedaesubset)),
       dsetout                 =  &prefix.num_related,
       groupByVarPop           =  &groupByVarPop,
       groupByVarsDenom        =  &groupByVarsDenom,
       groupByVarsNumer        =  &groupByVarsNumer,
       groupminmaxvar          =  ,
       labelvarsyn             =  Y,
       postSubset              =  ,
       psByvars                =  ,
       psClass                 =  ,
       psClassOptions          =  &psClassOptions,
       psFormat                =  &psFormat,
       psFreq                  =  ,
       psid                    =  ,
       psOptions               =  &psOptions,
       psOutput                =  ,
       psOutputOptions         =  ,
       psTypes                 =  ,
       psWays                  =  ,
       psWeight                =  ,
       remSummaryPctYN         =  N,
       resultPctDps            =  &resultPctDps,
	   resultStyle             =  NUMER,
       resultVarName           =  &resultVarName,
       rowLabelVarName         =  ,
       spsort2groupbyvarsdenom =  ,                   
       spsort2groupbyvarsnumer =  ,                   
       spsort2resultstyle      =  ,                   
       spsort2resultvarname    =  ,                   
	   spSortGroupByVarsDenom  =  ,
	   spSortGroupByVarsNumer  =  ,
	   spSortResultStyle       =  ,
	   spSortResultVarName     =  ,
       summaryLevelVarName     =  summaryLevel,
       totalDecode             =  &totalDecode,
	   totalForVar             =  &totalForVar,
	   totalID                 =  &totalID,
       varlabelstyle           =  SHORT,
	   varsToDenorm            =  tt_result
       );

    proc sort data=&prefix.num_related;
      by summaryLevel aesoc &preftermvar;
    run;

    data &prefix.num_related;
      merge &prefix.num_related &prefix.sortvars;
      by summaryLevel aesoc &preftermvar;
      tt_svid=3;
    run;

    %tu_freq(
       acrossColListName       =  acrossColList,
       acrossColVarPrefix      =  tt_ac,
       acrossVar               =  &acrossVar,
       acrossVarDecode         =  &acrossVarDecode,
       addBigNYN               =  Y,
       BigNVarName             =  tt_bnnm,
       codeDecodeVarPairs      =  &codeDecodeVarPairs,
       completetypesvars       =  &completetypesvars,
       countDistinctWhatVar    =  ,
	   denormYN                =  Y,
       display                 =  N,
       dsetinDenom             =  &dsetinDenom,
       dsetinNumer             =  &prefix.dsetinNumer(where=(&fatalaesubset)),
       dsetout                 =  &prefix.num_fatal,
       groupByVarPop           =  &groupByVarPop,
       groupByVarsDenom        =  &groupByVarsDenom,
       groupByVarsNumer        =  &groupByVarsNumer,
       groupminmaxvar          =  ,
       labelvarsyn             =  Y,
	   postSubset              =  ,
       psByvars                =  ,
       psClass                 =  ,
       psClassOptions          =  &psClassOptions,
       psFormat                =  &psFormat,
       psFreq                  =  ,
       psid                    =  ,
       psOptions               =  &psOptions,
       psOutput                =  ,
       psOutputOptions         =  ,
       psTypes                 =  ,
       psWays                  =  ,
       psWeight                =  ,
       remSummaryPctYN         =  N,
       resultPctDps            =  &resultPctDps,
	   resultStyle             =  NUMER,
       resultVarName           =  &resultVarName,
       rowLabelVarName         =  ,
       spsort2groupbyvarsdenom =  ,                   
       spsort2groupbyvarsnumer =  ,                   
       spsort2resultstyle      =  ,                   
       spsort2resultvarname    =  ,                   
	   spSortGroupByVarsDenom  =  ,
	   spSortGroupByVarsNumer  =  ,
	   spSortResultStyle       =  ,
	   spSortResultVarName     =  ,
       summaryLevelVarName     =  summaryLevel,
       totalDecode             =  &totalDecode,
	   totalForVar             =  &totalForVar,
	   totalID                 =  &totalID,
       varlabelstyle           =  SHORT,
	   varsToDenorm            =  tt_result
       );

    proc sort data=&prefix.num_fatal;
      by summaryLevel aesoc &preftermvar;
    run;

    data &prefix.num_fatal;
      merge &prefix.num_fatal &prefix.sortvars;
      by summaryLevel aesoc &preftermvar;
      tt_svid=4;
    run;

    %tu_freq(
       acrossColListName       =  acrossColList,
       acrossColVarPrefix      =  tt_ac,
       acrossVar               =  &acrossVar,
       acrossVarDecode         =  &acrossVarDecode,
       addBigNYN               =  Y,
       BigNVarName             =  tt_bnnm,
       codeDecodeVarPairs      =  &codeDecodeVarPairs,
       completetypesvars       =  &completetypesvars,
       countDistinctWhatVar    =  ,
	   denormYN                =  Y,
       display                 =  N,
       dsetinDenom             =  &dsetinDenom,
       dsetinNumer             =  &prefix.dsetinNumer(where=(&fatalaesubset and &relatedaesubset)),
       dsetout                 =  &prefix.num_relfatal,
       groupByVarPop           =  &groupByVarPop,
       groupByVarsDenom        =  &groupByVarsDenom,
       groupByVarsNumer        =  &groupByVarsNumer,
       groupminmaxvar          =  ,
       labelvarsyn             =  Y,
	   postSubset              =  ,
       psByvars                =  ,
       psClass                 =  ,
       psClassOptions          =  &psClassOptions,
       psFormat                =  &psFormat,
       psFreq                  =  ,
       psid                    =  ,
       psOptions               =  &psOptions,
       psOutput                =  ,
       psOutputOptions         =  ,
       psTypes                 =  ,
       psWays                  =  ,
       psWeight                =  ,
       remSummaryPctYN         =  N,
       resultPctDps            =  &resultPctDps,
	   resultStyle             =  NUMER,
       resultVarName           =  &resultVarName,
       rowLabelVarName         =  ,
       spsort2groupbyvarsdenom =  ,                   
       spsort2groupbyvarsnumer =  ,                   
       spsort2resultstyle      =  ,                   
       spsort2resultvarname    =  ,                   
	   spSortGroupByVarsDenom  =  ,
	   spSortGroupByVarsNumer  =  ,
	   spSortResultStyle       =  ,
	   spSortResultVarName     =  ,
       summaryLevelVarName     =  summaryLevel,
       totalDecode             =  &totalDecode,
	   totalForVar             =  &totalForVar,
	   totalID                 =  &totalID,
       varlabelstyle           =  SHORT,
	   varsToDenorm            =  tt_result
       );

    proc sort data=&prefix.num_relfatal;
      by summaryLevel aesoc &preftermvar;
    run;

    data &prefix.num_relfatal;
      merge &prefix.num_relfatal &prefix.sortvars;
      by summaryLevel aesoc &preftermvar;
      tt_svid=5;
    run;

    data &prefix.comb1;
      set &prefix.comb1 &prefix.num_related &prefix.num_fatal &prefix.num_relfatal;
    run;

  %end; /* %if &seriousAE eq Y %then %do; */

  /*
  / Prepare final reporting dataset
  --------------------------------------------------------------------------*/
  
  proc format;
    value svnmfmt
      %if &seriousAE eq Y %then
      %do;
        1='Number of Subjects with SAEs'
        2='Number of SAEs'
        3='Number of Drug-related SAEs'
        4='Number of Fatal SAEs'
        5='Number of Drug-related Fatal SAEs'
      %end;
      %else
      %do;
        1='Number of Subjects with AEs'
        2='Number of AEs'
      %end;
      ;
  quit;

  data &prefix.comb2;
    set &prefix.comb1;
    array columns[*] tt_ac:;
    do _i=1 to dim(columns);
      if missing(columns[_i]) then columns[_i]='0';
    end;
    drop _i;
    tt_svnm=put(tt_svid, svnmfmt.);
  run;

  %tu_align(
    dsetin=&prefix.comb2,
    dsetout=&prefix.comb2,
    varsin=tt_ac:
    );

  data &prefix.final;
    set &prefix.comb2;
    %if %nrbquote(&postsubset) ne %then
    %do;
      %unquote(&postsubset);
    %end;
  run;

  %noevents:

  %if &g_debug ge 5 %then
  %do;

    title "&sysmacroname.: Final reporting dataset";
    proc print data=&prefix.final width=min;
    run;

  %end;

  /*
  / Create output dataset if requested
  /----------------------------------------------------------------------*/

  %if %length(&dsetout) gt 0 %then
  %do;
    data &dsetout (label="Output dataset created by &sysmacroname.");
      set &prefix.final;
    run;
  %end;

  /*
  / Prepare datasets for the XML utility macro
  / Do this before tu_list otherwise the tu_freq call when the are no 
  / events to report would delete the data display
  /----------------------------------------------------------------------*/

  %if &seriousAE eq N %then
  %do;

    data &aefrequencydset;
      studyID="&vctrstudyid"; /* AJC001: Use VCTR study identifier */
      frequencyReportingThreshold=&freqpctcutoff;
      output;
      stop;
    run;

  %end;

  %if %tu_nobs(&prefix.final) gt 0 %then
  %do;

    /*
    / Tranpose final reporting dataset to get:
    /   1. Multiple treatment columns (tt_ac:) into single column
    /      (trtarmcd/trtarm)
    /   2. Summary values (tt_svid/tt_svnm) from single column into
    /      multiple columns (result_char:)
    /--------------------------------------------------------------------*/

    %local l_tt_ac_list;

    proc sql noprint;
      select distinct(trim(name)) into : l_tt_ac_list separated by ' '
      from dictionary.columns
      where upcase(libname) eq "WORK" and upcase(memname) = "%upcase(&prefix.final)" and
        upcase(substr(name, 1, 5)) eq 'TT_AC'  and upcase(name) ne 'TT_AC'||"&totalid";
    quit;

    %put RTNOTE: &sysmacroname: List of treatment columns (excluding total) l_tt_ac_list=&l_tt_ac_list..;

    proc sort data=&prefix.final out=&prefix.final_sorted;
      by summarylevel aesoc &preftermvar tt_pct999 tt_svid;
    run;

    proc transpose
      data = &prefix.final_sorted
      out = &prefix.final_tran1
      name = trtarmcd
      label = trtarm
      ;
      by summarylevel aesoc &preftermvar tt_pct999 tt_svid tt_svnm;
      var &l_tt_ac_list;
    run;

    proc sort data=&prefix.final_tran1;
      by summarylevel aesoc &preftermvar tt_pct999 trtarmcd trtarm;
    run;

    proc transpose
      data = &prefix.final_tran1
      out = &prefix.final_tran2 (drop=_name_)
      prefix=result_char
      ;
      by summarylevel aesoc &preftermvar tt_pct999 trtarmcd trtarm;
      id tt_svid;
      idlabel tt_svnm;
      var col1;
    run;

    data &prefix.xmlmap (keep=studyID arm: summaryLevel organSystemName aeTerm tt_pct999 num:);
      set &prefix.final_tran2 (rename=(aesoc=organSystemName &preftermvar=aeTerm)) end=last;
      length armTitle $200 armDescription $2000;
      retain studyID "&vctrstudyid" g_abort 0 rx rx2; /* AJC001: Use VCTR study identifier */

      if _n_ eq 1 then 
      do;

        /*
        / Define a Perl regular expression to match text in the data dislay
        / column headers. The regular expression will include capturing
        / parentheses, to capture the respective components of the column
        / header that correspond to the label used to identify arm of the
        / comparison group and the 'big N' value.
        /--------------------------------------------------------------------*/

        rx = prxparse('/^(.+)~\(N=(\d+)\)/i');

        /*
        / Define a Perl regular expression to capture the frequency component
        / of any text that stores number and percentage in the format of
        / either '0' or 'nnn (nn%)'.
        /--------------------------------------------------------------------*/

        rx2 = prxparse('/(\d+)/');

      end;

      /*
      /  Get armID from the name of the treatment variables (tt_ac001, 
      /  tt_ac002 etc.) which were transposed into TRTARMCD.
      /--------------------------------------------------------------------*/

      armID = input(substr(trtarmcd, 6), 8.); 

      /*
      / Get armTitle and numSubjects from the variable TRTARM, which 
      / contains the labels of the treatment variables (tt_ac001,
      /  tt_ac002 etc.) which were transposed into TRTARM.
      /--------------------------------------------------------------------*/

      if prxmatch(rx, trtarm) then
      do;
        armTitle = prxposn(rx, 1, trtarm);
        numSubjects = input(prxposn(rx, 2, trtarm), 8.);
      end;
      else
      do;
        put / 'RTE' "RROR: &sysmacroname: expecting data display column"
            / 'labels to be in the format XXXXXXXX~(N=DDD)'
            / 'These values have been stored in the variable TRTARM'
            / trtarm = 
            / ;
        g_abort = 1;   
      end;

      %if %length(&vctrTrtDescrFmt) gt 0 %then
      %do;
        armDescription=put(armID,&vctrTrtDescrFmt.);
      %end;
      %else 
      %do;
        armDescription=' ';
      %end;

      /*
      / Get the number of subjects affected etc. from the transposed 
      / results variables.
      /--------------------------------------------------------------------*/

      if prxmatch(rx2, result_char1) then
      do;
        numSubjectsAffected = input(prxposn(rx2, 1, result_char1), 8.);
      end; 
      else
      do;
        put / "RTE" "RROR: &sysmacroname: frequency could not be obtained from variable"
            / "  storing numbers and percentage of subjects affected"
            / result_char1 =
            / ; 
        g_abort = 1;
      end;

      if prxmatch(rx2, result_char2) then
      do;
        numEvents = input(prxposn(rx2, 1, result_char2), 8.);
      end; 
      else
      do;
        put / "RTE" "RROR: &sysmacroname: frequency could not be obtained from variable"
            / "  storing number of events"
            / result_char2 =
            / ; 
        g_abort = 1;
      end;

      %if &seriousAE=Y %then
      %do;

        numDeathsAllCauses=.;
        numDeathsAdverseEvents=.;

        if prxmatch(rx2, result_char3) then
        do;
          numEventsRelated = input(prxposn(rx2, 1, result_char3), 8.);
        end; 
        else
        do;
          put / "RTE" "RROR: &sysmacroname: frequency could not be obtained from variable"
              / "  storing number of drug-related events"
              / result_char3 =
              / ; 
          g_abort = 1;
        end;

        if prxmatch(rx2, result_char4) then
        do;
          numFatalities = input(prxposn(rx2, 1, result_char4), 8.);
        end; 
        else
        do;
          put / "RTE" "RROR: &sysmacroname: frequency could not be obtained from variable"
              / "  storing number of fatal events"
              / result_char4 =
              / ; 
          g_abort = 1;
        end;

        if prxmatch(rx2, result_char5) then
        do;
          numFatalitiesRelated = input(prxposn(rx2, 1, result_char5), 8.);
        end; 
        else
        do;
          put / "RTE" "RROR: &sysmacroname: frequency could not be obtained from variable"
              / "  storing number of drug-related fatal events"
              / result_char5 =
              / ; 
          g_abort = 1;
        end;

      %end;

      if last then
      do;
        call symput('g_abort', put(g_abort, 1.));
        call prxfree(rx);
        call prxfree(rx2);
      end;

      format _all_;
      informat _all_;

    run;

    %if &g_abort eq 1 %then
    %do;
      %tu_abort
    %end;

    proc sort 
      data=&prefix.xmlmap 
      out=&prefix.groups(
        keep=studyID arm: numSubjectsAffected numSubjects 
        %if &seriousAE eq Y %then numDeathsAllCauses numDeathsAdverseEvents;
        rename=(numSubjectsAffected=&numSubjectsEvents numSubjects=&numSubjects)
        );
      by armID;
      where summarylevel eq 1;
    run;

    proc sort
      data=&prefix.xmlmap
      out=&prefix.results(
        keep=studyID arm: organSystemName aeTerm tt_pct999 numSubjectsAffected numSubjects numEvents
        %if &seriousAE eq Y %then numEventsRelated numFatalities numFatalitiesRelated;
        );
      by descending tt_pct999 aeTerm armID;
      where summarylevel eq 2;
    run;

    data &prefix.results (drop=tt_pct999);
      set &prefix.results;
      by descending tt_pct999 aeTerm armID;
      retain eventID 0;
      if first.aeTerm then
        eventID=eventID+1;
    run;

  %end;

  %else
  %do;

    /*
    / When there are no events to report get the number of subjects
    / affected from the population dataset.
    / Temporarily overwrite g_subset in case it contains variables
    / not in &g_popdata
    /--------------------------------------------------------------------*/

    %local l_subset;
    %let l_subset=&g_subset;
    %let g_subset=;

    %tu_freq(
       dsetinnumer=&g_popdata,
       dsetindenom=&g_popdata,
       dsetout=&prefix.trtout,
       completetypesvars=,
       groupbyvarsnumer=&acrossVar &acrossVarDecode,
       display=N,
       resultstyle=NUMER
       );

    %let g_subset=&l_subset;

    data &prefix.groups (keep = studyID arm: &numSubjectsevents &numSubjects 
      %if &seriousAE eq Y %then numDeaths:;);
      set &prefix.trtout (rename=(&acrossVar=armID &acrossVarDecode=armTitle tt_numercnt=&numsubjects));
      length armDescription $2000;
      retain studyID "&vctrstudyid"; /* AJC001: Use VCTR study identifier */

      %if %length(&vctrTrtDescrFmt) gt 0 %then
      %do;
        armDescription=put(armID,&vctrTrtDescrFmt.);
      %end;
      %else 
      %do;
        armDescription=' ';
      %end;
      &numsubjectsevents=0;
      %if &seriousAE eq Y %then
      %do;
        numDeathsAllCauses=.;
        numDeathsAdverseEvents=.;
      %end;
    run;

    data &prefix.results;
      set &prefix.groups (keep=studyID arm: &numsubjects rename=(&numsubjects=numSubjects));
      organsystemname='Missing';
      aeterm='Missing';
      numsubjectsaffected=0;
      numevents=0;
      %if &seriousAE eq Y %then
      %do;
        numEventsRelated=0;
        numFatalities=0;
        numFatalitiesRelated=0;
      %end;
      eventID=1;
      delete;
    run;
        
  %end;

  %if &g_debug ge 5 %then
  %do;

    %if &seriousAE eq N %then
    %do;
      title "&sysmacroname.: Adverse Events Frequency Threshold dataset for XML utility macro";
      proc print data=&aefrequencydset width=min;
      run;
    %end;

    title "&sysmacroname.: Adverse Events Reporting Groups dataset for XML utility macro";
    proc print data=&prefix.groups width=min;
    run;

    title "&sysmacroname.: Adverse Events Results dataset for XML utility macro";
    proc print data=&prefix.results width=min;
    run;

  %end;

  /*
  / Create data display if requested
  /----------------------------------------------------------------------*/

  %if &display=Y %then
  %do;

    %if %tu_nobs(&prefix.final) eq 0 %then
      %let columns=_all_;

    %tu_list(
         break1 = &break1,
         break2 = &break2,
         break3 = &break3,
         break4 = &break4,
         break5 = &break5,
         byvars = &byvars,
         centrevars = &centrevars,
         colspacing = &colspacing,
         columns = &columns,
         computebeforepagelines = &computebeforepagelines,
         computebeforepagevars = &computebeforepagevars,
         dddatasetlabel = &dddatasetlabel,
         defaultwidths = &defaultwidths,
         descending = &descending,
         display = &display,
         dsetin = &prefix.final,
         flowvars = &flowvars,
         formats = &formats,
         getdatayn =N,
         idvars = &idvars,
         labels = &labels,
         labelvarsyn =Y,
         leftvars = &leftvars,
         linevars = &linevars,
         noprintvars = &noprintvars,
         nowidowvar = &nowidowvar,
         orderdata = &orderdata,
         orderformatted = &orderformatted,
         orderfreq = &orderfreq,
         ordervars = &ordervars,
         overallsummary =&overallsummary,         
         pagevars = &pagevars,
         proptions = &proptions,
         rightvars = &rightvars,
         sharecolvars = &sharecolvars,
         sharecolvarsindent = &sharecolvarsindent,
         skipvars = &skipvars,
         splitchar =&splitchar,
         stackvar1 = , 
         stackvar2 = , 
         stackvar3 = , 
         stackvar4 = , 
         stackvar5 = , 
         stackvar6 = , 
         stackvar7 = , 
         stackvar8 = , 
         stackvar9 = , 
         stackvar10 = , 
         stackvar11 = , 
         stackvar12 = , 
         stackvar13 = , 
         stackvar14 = , 
         stackvar15 = , 
         varlabelstyle = SHORT,
         varspacing = &varspacing,
         widths = &widths
         );

  %end;

  /*
  / Create XML output datasets if requested
  /-----------------------------------------------------------------------*/

  %if %length(&vctrfrequencydsetout) gt 0 and %length(&aefrequencydset) gt 0 %then
  %do;
    data &vctrfrequencydsetout (label="XML Frequency Reporting Threshold dataset created by &sysmacroname.");
      set &aefrequencydset;
    run;
  %end;

  %if %length(&vctrgroupsdsetout) gt 0 %then %do;
    data &vctrgroupsdsetout (label="XML Reporting Groups dataset created by &sysmacroname.");
      set &prefix.groups;
    run;
  %end;
  
  %if %length(&vctrresultsdsetout) gt 0 %then %do;
    data &vctrresultsdsetout (label="XML Adverse Event Results dataset created by &sysmacroname.");
      set &prefix.results;
    run;
  %end;
  
  /*
  / Call utility to validate datasets and create XML files
  /-----------------------------------------------------------------------*/

  %if &vctrcr8usxmlyn = Y or &vctrcr8euxmlyn=Y %then %do;

    %tu_cr8xml4vctr(
      usage=CREATE,
      datatype=&datatype,
      vctrstudyid=&vctrstudyid,
      cr8usxmlyn=&vctrcr8usxmlyn,
      cr8euxmlyn=&vctrcr8euxmlyn,
      aefreqdset=&aefrequencydset,
      aegroupsdset=&prefix.groups,
      aedatadset=&prefix.results
      ); /* AJC001: Pass VCTR study ID to utility macro */

  %end;

  /*
  / Delete temporary datasets used in this macro.
  /----------------------------------------------------------------------------*/

  %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend td_ae4vctr;

