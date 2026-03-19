/*
/
/ Macro Name: td_ae3
/
/ Macro Version: 2
/
/ SAS Version: 8
/
/ Created By: John Henry King
/
/ Date: O2OCT2003
/
/ Macro Purpose: A macro to create Adverse Event Display AE3.
/
/ Macro Design: Procedure style.
/
/ Input Parameters:
/
/ Name               Description                                Default
-------------------- ------------------------------------------ -----------
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
/CENTREVARS          Variables to be displayed as centre        (Blank)
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
/CODEDECODEVARPAIRS  Specifies code and decode variable pairs.  (Blank)
/                    Those variables should be in parameter
/                    GROUPBYVARSNUMER. One variable in the
/                    pair will contain the code and the other
/                    will contain decode.
/                    Valid values:  Blank or a list of SAS
/                    variable names in pairs that are given in
/                    GROUPBYVARSNUMER
/
/COLSPACING          The value of the between-column spacing    2
/                    Valid values: positive integer
/
/COLUMNS             A PROC REPORT column statement             summaryLevel
/                    specification.  Including spanning         tt_pct999
/                    titles and variable names                  aept
/                    Valid values: one or more variable names   tt_ac:
/                    from DSETIN plus other elements of valid
/                    PROC REPORT COLUMN statement syntax
/
/COMPUTEBEFOREPAGE   See Unit Specification for HARP            (Blank)
/LINES               Reporting Tools TU_LIST for complete
/                    details
/
/COMPUTEBEFOREPAGE   See Unit Specification for HARP            (Blank)
/VARS                Reporting Tools TU_LIST for complete
/                    details
/
/COUNTDISTINCTWHATV  Variable(s) that contain values to be      &g_centid
/AR                  counted uniquely within any output         &g_subjid
/                    grouping.
/                    Valid values:
/                    Blank
/                    Name of one or more SAS variables that
/                    exists in DSETINNUMER
/
/ COMPLETETYPESVARS   Passed to %tu_statswithtotal. Specify a list of   _ALL_             
/                     variables which are in GROUPBYVARSANALY and the                     
/                     COMPLETETYPES given by PSOPTIONS should be                          
/                     applied to. If it equals _ALL_, all variables in                    
/                     GROUPBYVARSANALY will be included.                                  
/                     Valid values:                                                       
/                     _ALL_                                                               
/                     A list of variable names which are in                               
/                     GROUPBYVARSANALY                                                    
/                                                                                         
/DDDATASETLABEL      Specifies the label to be applied to the   DD dataset
/                    DD dataset                                 for AE3
/                    Valid values: a non-blank text string      table
/
/DEFAULTWIDTHS       Specifies column widths for all            aept 30
/                    variables not listed in the WIDTHS
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
/DESCENDING          List of ORDERVARS that are given the       tt_pct999
/                    PROC REPORT define statement attribute
/                    DESCENDING
/                    Valid values: one or more variable names
/                    from DSETIN that are also defined with
/                    ORDERVARS
/
/DSETINDENOM         Input dataset containing data to be        &g_popdata
/                    counted to obtain the denominator. This
/                    may or may not be the same as the dataset
/                    specified to DSETINNUMER.
/                    Valid values:
/                    &g_popdata
/                    any other valid SAS dataset reference
/
/DSETINNUMER         Input dataset containing data to be        ardata.ae
/                    counted to obtain the numerator.
/
/                    Valid Values: Valid sas dataset name
/
/FLOWVARS            Variables to be defined with the flow      aept
/                    option
/                    Valid values: one or more variable names
/                    from DSETIN that are also defined with
/                    COLUMNS
/                    Flow variables should be given a width
/                    through the WIDTHS.  If a flow variable
/                    does not have a width specified, the
/                    column width will be determined by
/                    MIN(variable?s format width,
/                    width of  column header)
/
/FORMATS             Variables and their format for display.    (Blank)
/                    For use where format for display differs
/                    to the format on the DSETIN.
/                    Valid values: values of column names and
/                    formats such as form valid syntax for a
/                    SAS FORMAT statement
/
/GROUPBYVARPOP       Specifies a list of variables to group by  &g_trtcd
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
/GROUPBYVARSDENOM    Variables in DSETINDENOM to group the      &g_trtcd
/                    data by when counting to obtain the
/                    denominator.
/                    Valid values:
/                    Blank, _NONE_ (to request an overall
/                    total for the whole dataset)
/                    Name of a SAS variable that exists in
/                    DSETINDENOM
/
/GROUPBYVARSNUMER    Variables in DSETINNUMER to group the      &g_trtcd
/                    data by, along with ACROSSVAR, when        (aept='Any Event')
/                    counting to obtain the numerator.          aept
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
/IDVARS              Variables to appear on each page if the    aept
/                    report is wider than 1 page. If no value
/                    is supplied to this parameter then all
/                    displayable order variables will be
/                    defined as IDVARS
/                    Valid values: one or more variable names
/                    from DSETIN that are also defined with
/                    COLUMNS
/LABELS              Variables and their label for display.     (Blank)
/                    For use where label for display differs
/                    to the label on the DSETIN
/                    Valid values: pairs of variable names
/                    and labels
/
/LEFTVARS            Variables to be displayed as left          (Blank)
/                    justified
/                    Valid values: one or more variable names
/                    from DSETIN that are also defined with
/                    COLUMNS
/
/LINEVARS            List of order variables that are printed   (Blank)
/                    with LINE statements in PROC REPORT
/                    Valid values: one or more variable names
/                    from DSETIN that are also defined with
/                    ORDERVARS
/                    These values shall be written with a
/                    BREAK BEFORE when the value of one of
/                    the variables changes. The variables
/                    will automatically be defined as NOPRINT
/
/NOPRINTVARS         Variables listed in the COLUMN parameter   tt_ac999
/                    that are given the PROC REPORT define      summaryLevel
/                    statement attribute noprint                tt_pct999
/                    Valid values: one or more variable names
/                    from DSETIN that are also defined with
/                    COLUMNS
/                    These variables are ORDERVARS used to
/                    control the order of the rows in the
/                    display
/
/NOWIDOWVAR          Variable whose values must be kept         (Blank)
/                    together on a page
/                    Valid values: names of one or more
/                    variables specified in COLUMNS
/
/ORDERDATA           Variables listed in the ORDERVARS          (Blank)
/                    parameter that are given the PROC REPORT
/                    define statement attribute order=data
/                    Valid values: one or more variable names
/                    from DSETIN that are also defined with
/                    ORDERVARS
/                    Variables not listed in ORDERFORMATTED,
/                    ORDERFREQ, or ORDERDATA are given the
/                    define attribute order=internal
/
/ORDERFORMATTED      Variables listed in the ORDERVARS          (Blank)
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
/ORDERFREQ           Variables listed in the ORDERVARS          (Blank)
/                    parameter that are given the PROC REPORT
/                    define statement attribute order=freq
/                    Valid values: one or more variable names
/                    from DSETIN that are also defined with
/                    ORDERVARS
/                    Variables not listed in ORDERFORMATTED,
/                    ORDERFREQ, or ORDERDATA are given the
/                    define attribute order=internal
/
/ORDERVARS           List of variables that will receive the    summaryLevel
/                    PROC REPORT define statement attribute     tt_pct999
/                    ORDER                                      aept
/                    Valid values: one or more variable names
/                    from DSETIN that are also defined with
/                    COLUMNS
/
/PAGEVARS            Variables whose change in value causes     (Blank)
/                    the display to continue on a new page
/                    Valid values: one or more variable names
/                    from DSETIN that are also defined with
/                    COLUMNS
/
/POSTSUBSET          SAS expression to be applied to data        if round(tt_pct999) GT 1
/                    immediately prior to creation of the
/                    permanent presentation dataset. Used for
/                    subsetting records required for
/                    computation but not for display.
/                    Valid values:
/                    Blank
/                    A complete, syntactically valid SAS where
/                    or if statement for use in a data step
/
/PROPTIONS           PROC REPORT statement options to be used    Headline
/                    in addition to MISSING
/                    Valid values: proc report options
/                    The option ?Missing? can not be
/                    overridden
/
/PSOPTIONS           PROC SUMMARY Options to use. MISSING        COMPLETETYPES MISSING NWAY
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
/PSCLASSOPTIONS      PROC SUMMARY Class Statement Options.       PRELOADFMT
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
/PSFORMAT            Passed to the PROC SUMMARY FORMAT .         &g_trtcd &g_trtfmt
/                    statement
/                    Valid values:
/                    Blank
/                    Valid PROC SUMMARY FORMAT statement part.
/
/RESULTPCTDPS        The reporting precision for percentages    0
/                    Valid values:
/                    0 or any positive integer
/
/RESULTSTYLE         The appearance style of the result         NUMERPCT
/                    columns that will be displayed in the
/                    report. The chosen style will be placed
/                    in variable &RESULTVARNAME.
/                    Valid values:
/                    As documented for tu_percent in [6]. In
/                    typical usage, NUMERPCT.
/
/RIGHTVARS           Variables to be displayed as right         (Blank)
/                    justified
/                    Valid values: one or more variable names
/                    from DSETIN that are also defined with
/                    COLUMNS
/
/SHARECOLVARS        List of variables that will share print    (Blank)
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
/SHARECOLVARSINDEN   Indentation factor for ShareColVars.       2
/T                   Stacked values shall be progressively
/                    indented by multiples of
/                    ShareColVarsIndent
/                    Valid values: positive integer
/
/SKIPVARS            Variables whose change in value causes     SummaryLevel
/                    the display to skip a line
/                    Valid values: one or more variable names
/                    from DSETIN that are also defined with
/                    COLUMNS
/
/SPLITCHAR           The split character used in column         ~
/                    labels. Used in the creation of the label
/                    for the result columns, and in
/                    %tu_stackvar, %tu_display (PROC REPORT).
/                    Usually ~
/                    Valid values:
/                    Valid SAS split character.
/
/SPSORTGROUPBYVARSD  Special sort: variables in DSETINDENOM to  (Blank)
/ENOM                group the data by when counting to obtain
/                    the denominator.
/                    Valid values:
/                    Blank if SPSORTRESULTVARNAME is blank
/                    Otherwise,
/                    Blank
/                    _NONE_
/                    Name of a SAS variable that exists in
/                    DSETINDENOM
/
/SPSORTGROUPBYVARSN  Special sort: variables in DSETINNUMER to  (Blank)
/UMER                group the data by when counting to obtain
/                    the numerator.
/                    Valid values:
/                    Blank if SPSORTRESULTVARNAME is blank
/                    Otherwise,
/                    Name of one or more SAS variables that
/                    exist in DSETINNUMER
/
/SPSORTRESULTSTYLE   Special sort: the appearance style of the  (Blank)
/                    result data that will be used to sequence
/                    the report. The chosen style will be
/                    placed in variable SPSORTRESULTVARNAME
/                    Valid values:
/                    Blank if SPSORTRESULTVARNAME is blank
/                    Otherwise, as documented for tu_percent.
/                    In typical usage, NUMERPCT.
/
/TOTALDECODE         Label for the total result column.         Total
/                    Usually the text Total
/                    Valid values:
/                    Blank
/                    SAS data step expression resolving to a
/                    character.
/
/TOTALFORVAR         Variable for which total is required       &g_trtcd
/                    within all other grouped classvars
/                    (usually trtcd). If not specified, no
/                    total will be produced
/                    Valid values: Blank if TOTALID is blank,
/                    else the name of a variable that exists
/                    in DSETIN.
/
/TOTALID             Value used to populate the variable        999
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
/VARSPACING          Spacing for individual columns             (Blank)
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
/WIDTHS              Variables and width to display             (Blank)
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
/-----------------------------------------------------------------------
/
/ Output: Printed output.
/
/ Global macro variables created: NONE
/
/
/ Macros called:
/
/(@) tr_putlocals
/(@) tu_putglobals
/(@) tu_freq
/
/ Example:
/    %td_ae3()
/
/*******************************************************************************
/ Change Log
/
/ Modified By:              Yongwei Wang
/ Date of Modification:     24-Mar-2005
/ New version number:       2/1
/ Modification ID:          YW001
/ Reason For Modification:  Make PSOPTIONS, PSFORMAT and PSCLASSOPTIONS available to be 
/                           editable by the user and passed through to tu_freq. 
/                           Set default value for psformat to be &g_trtcd &g_trtfmt
/                           And default for PSCLASSOPTIONS to be preloadfmt
/                           Removed parameter RESULTVARNAME.
/                           Added new parameter COMPLETETYPESVARS. 
/                           Added GROUPMINMAXVAR and STACKVARn parameters in
/                           call to tu_freq macro.
/
/ Modified By :             Yongwei Wang
/ Date of Modification :    16-Aug-2004
/ New Version Number :      2/2
/ Modification ID :         yw002
/ Reason For Modification : Added RESULTVARNAME back because backward compatibility 
/                           concern.
/
/ Modified By :             Yongwei Wang
/ Date of Modification :    25-Aug-2004
/ New Version Number :      2/3
/ Modification ID :         N/A 
/ Reason For Modification : Added  ',' in parameter psformat after roll back
/*******************************************************************************
/ Modified By:
/ Date of Modification:
/ New version number:
/ Modification ID:
/ Reason For Modification:
/
/************************************************************************************************/
%macro td_ae3 (
         acrossVar               =  &g_trtcd,         /* Variable to transpose the data across to make columns of results. This is passed to the proc transpose ID statement */
         acrossVarDecode         =  &g_trtgrp,        /* Decode Variable or FORMAT for the across variable */
         break1                  =  ,                 /* Break statements. */
         break2                  =  ,                 /* Break statements. */
         break3                  =  ,                 /* Break statements. */
         break4                  =  ,                 /* Break statements. */
         break5                  =  ,                 /* Break statements. */
         byvars                  =  ,                 /* By variables */
         centrevars              =  ,                 /* Centre justify variables */
         codeDecodeVarPairs      =  ,                 /* Code and Decode variables in pairs */
         colspacing              =  2,                /* Overall spacing value. */
         columns                 =  summaryLevel tt_pct999 aept tt_ac:, /* Column parameter */
         computebeforepagelines  =  ,                 /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt colon labelvar) */
         computebeforepagevars   =  ,                 /* Names of variables that shall define the sort order for Compute Before Page lines */
         countDistinctWhatVar    =  &g_centid &g_subjid,     /* Variable(s) that contain values to be counted uniquely within any output grouping. Eg &g_subjid */
         completetypesvars       =  _all_,             /* Variables which COMPLETETYPES should be applied to */ 
         dddatasetlabel          =  DD dataset for AE3 table,/* Label to be applied to the DD dataset */
         defaultwidths           =  aept 30,          /* List of default column widths */
         descending              =  tt_pct999,        /* Descending ORDERVARS */
         dsetinDenom             =  &g_popdata,       /* Input dataset containing data to be counted to obtain the denominator. */
         dsetinNumer             =  ardata.ae,        /* Input dataset containing data to be counted to obtain the numerator. */
         flowvars                =  aept,             /* Variables with flow option */
         formats                 =  ,                 /* Format specification */
         groupByVarPop           =  &g_trtcd,         /* Variables to group by when counting big N  */
         groupByVarsDenom        =  &g_trtcd,         /* Variables in DSETINDENOM to group the data by when counting to obtain the denominator. */
         groupByVarsNumer        =  &g_trtcd (aept='Any event') aept, /* Variables in DSETINNUMER to group the data by when counting to obtain the numerator. */
         idvars                  =  aept,             /* ID variables */
         labels                  =  ,                 /* Label definitions. */
         leftvars                =  ,                 /* Left justify variables */
         linevars                =  ,                 /* Order variable printed with line statements. */
         noprintVars             =  tt_ac999 summaryLevel tt_pct999, /* No print vars (usually used to order the display) */
         nowidowvar              =  ,                 /* Not in version 1 */
         orderdata               =  ,                 /* ORDER=DATA variables */
         orderformatted          =  ,                 /* ORDER=FORMATTED variables */
         orderfreq               =  ,                 /* ORDER=FREQ variables */
         ordervars               =  summaryLevel tt_pct999 aept, /* Order variables */
         pagevars                =  ,                 /* Break after <var> / page */
         postSubset              =  if round(tt_pct999) GT 1,   /* SAS IF statement to apply to data immediately prior to creation of the permanent presentation dataset */
         proptions               =  headline,         /* PROC REPORT statement options */
         psOptions               =  COMPLETETYPES NWAY MISSING, /* PROC SUMMARY options to use */
         psclassoptions          =  PRELOADFMT,       /* PROC SUMMARY CLASS Statement Options */
         psformat                =  &g_trtcd &g_trtfmt, /* Passed to the PROC SUMMARY FORMAT statement. */
         resultPctDps            =  0,                /* The reporting precision for percentages */
         resultStyle             =  NUMERPCT,         /* The appearance style of the result columns that will be displayed in the report. */
         resultVarName           =  tt_result,        /* Name of the variable to hold the result of the frequency count */
         rightVars               =  ,                 /* Right justify variables */
         sharecolvars            =  ,                 /* Order variables that share print space. */
         sharecolvarsindent      =  2,                /* Indentation factor */
         skipvars                =  summaryLevel,     /* Break after <var> / skip */
         splitChar               =  ~,                /* The split character used in column labels. */
         spSortGroupByVarsDenom  =  ,                 /* Special sort: variables in DSETINDENOM to group the data by when counting to obtain the denominator. */
         spSortGroupByVarsNumer  =  ,                 /* Special sort: variables in DSETINNUMER to group the data by when counting to obtain the numerator. */
         spSortResultStyle       =  ,                 /* Special sort: the appearance style of the result data that will be used to sequence the report. */
         totalDecode             =  Total,            /* Label for the total result column. */
         totalForVar             =  &g_trtcd,         /* Variables in DSETINDENOM to group the data by when counting to obtain the denominator. */
         totalID                 =  999,              /* Value used to populate the variable specified in ACROSSVAR on data that represents the overall total for the ACROSSVAR variable. */
         varspacing              =  ,                 /* Spacing for individual variables. */
         widths                  =                    /* Column widths */
      );

   %LOCAL MacroVersion;
   %LET MacroVersion = 2;

   %INCLUDE "&g_refdata/tr_putlocals.sas";
   %tu_putglobals()

   %tu_freq
      (
         acrossColListName       =  acrossColList,
         acrossColVarPrefix      =  tt_ac,
         acrossVar               =  &acrossVar,
         acrossVarDecode         =  &acrossVarDecode,
         addBigNYN               =  Y,
         BigNVarName             =  tt_bnnm,
         break1                  =  &break1,
         break2                  =  &break2,
         break3                  =  &break3,
         break4                  =  &break4,
         break5                  =  &break5,
         byvars                  =  &byVars,
         centrevars              =  &centreVars,
         codeDecodeVarPairs      =  &codeDecodeVarPairs,
         colspacing              =  &colSpacing,
         columns                 =  &columns,
         completetypesvars       =  &completetypesvars,
         computebeforepagelines  =  &computeBeforePageLines,
         computebeforepagevars   =  &computeBeforePageVars,
         countDistinctWhatVar    =  &countDistinctWhatVar,
         dddatasetlabel          =  &dddatasetlabel,
         defaultwidths           =  &defaultWidths,
         denormYN                =  Y,
         descending              =  &descending,
         display                 =  Y,
         dsetinDenom             =  &dsetinDenom,
         dsetinNumer             =  &dsetinNumer,
         dsetout                 =  ,
         flowvars                =  &flowVars,
         formats                 =  &formats,
         groupByVarPop           =  &groupByVarPop,
         groupByVarsDenom        =  &groupByVarsDenom,
         groupByVarsNumer        =  &groupByVarsNumer,
         groupminmaxvar          =  ,
         idvars                  =  &idVars,
         labels                  =  &labels,
         labelvarsyn             =  Y,
         leftvars                =  &leftVars,
         linevars                =  &linevars,
         noprintVars             =  &noPrintVars,
         nowidowvar              =  &nowidowvar,
         orderdata               =  &orderdata,
         orderformatted          =  &orderformatted,
         orderfreq               =  &orderfreq,
         ordervars               =  &ordervars,
         overallsummary          =  N,
         pagevars                =  &pageVars,
         postSubset              =  &postSubset,
         proptions               =  &proptions,
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
         rightVars               =  &rightVars,
         rowLabelVarName         =  ,
         sharecolvars            =  &sharecolvars,
         sharecolvarsindent      =  &sharecolvarsindent,
         skipvars                =  &skipVars,
         splitChar               =  &splitChar,
         spsort2groupbyvarsdenom =  ,                   
         spsort2groupbyvarsnumer =  ,                   
         spsort2resultstyle      =  ,                   
         spsort2resultvarname    =  ,                   
         spSortGroupByVarsDenom  =  &spSortGroupByVarsDenom,
         spSortGroupByVarsNumer  =  &spSortGroupByVarsNumer,
         spSortResultStyle       =  &spSortResultStyle,
         spSortResultVarName     =  ,
         stackvar1               =  ,                   
         stackvar10              =  ,                   
         stackvar11              =  ,                   
         stackvar12              =  ,                   
         stackvar13              =  ,                   
         stackvar14              =  ,                   
         stackvar15              =  ,                   
         stackvar2               =  ,                   
         stackvar3               =  ,                   
         stackvar4               =  ,                   
         stackvar5               =  ,                   
         stackvar6               =  ,                   
         stackvar7               =  ,                   
         stackvar8               =  ,                   
         stackvar9               =  ,                   
         summaryLevelVarName     =  summaryLevel,
         totalDecode             =  &totalDecode,
         totalForVar             =  &totalForVar,
         totalID                 =  &totalID,
         varlabelstyle           =  SHORT,
         varspacing              =  &varSpacing,
         varsToDenorm            =  tt_result tt_pct,
         widths                  =  &widths
      )
%mend td_ae3;

