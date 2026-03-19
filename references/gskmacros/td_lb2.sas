/*
/
/ Macro Name: td_lb2
/
/ Macro Version: 2
/
/ SAS Version: 8
/
/ Created By: John Henry King
/
/ Date: 24OCT2003
/
/ Macro Purpose: A macro to create Lab Data Display LB2.
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
/CODEDECODEVARPAIRS  Specifies code and decode variable pairs.  &g_trtcd &g_trtgrp
/                    Those variables should be in parameter     lbtestcd lbtest
/                    GROUPBYVARSNUMER. One variable in the      visitnum visit
/                    pair will contain the code and the other   lbcccd lbccind
/                    will contain decode.
/                    Valid values:  Blank or a list of SAS
/                    variable names in pairs that are given in
/                    GROUPBYVARSNUMER
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
/COLSPACING          The value of the between-column spacing    2
/                    Valid values: positive integer
/
/COLUMNS             A PROC REPORT column statement             visitnum visit
/                    specification.  Including spanning         summaryLevel
/                    titles and variable names                  lbcccd lbccind
/                    Valid values: one or more variable names   tt_ac:
/                    from DSETIN plus other elements of valid
/                    PROC REPORT COLUMN statement syntax
/
/COMPUTEBEFOREPAGE   See Unit Specification for HARP            LBTEST $local. : lbtest
/LINES               Reporting Tools TU_LIST for complete
/                    details
/
/COMPUTEBEFOREPAGE   See Unit Specification for HARP            lbtest
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
/DDDATASETLABEL      Specifies the label to be applied to the   DD dataset
/                    DD dataset                                 for LB2
/                    Valid values: a non-blank text string      table
/
/DEFAULTWIDTHS       Specifies column widths for all            lbtest 90 visit 20 lbccind 20 
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
/DESCENDING          List of ORDERVARS that are given the       (Blank)
/                    PROC REPORT define statement attribute
/                    DESCENDING
/                    Valid values: one or more variable names
/                    from DSETIN that are also defined with
/                    ORDERVARS
/
/DSETIN              Specifies the input SAS data set.          ardata.lab
/
/FLOWVARS            Variables to be defined with the flow      visit lbccind 
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
/GROUPBYVARSDENOM    Variables in DSETINDENOM to group the      &g_trtcd lbtestcd visitnum
/                    data by when counting to obtain the
/                    denominator.
/                    Valid values:
/                    Blank, _NONE_ (to request an overall
/                    total for the whole dataset)
/                    Name of a SAS variable that exists in
/                    DSETINDENOM
/
/GROUPBYVARSNUMER    Variables in DSETINNUMER to group the      &g_trtcd &g_trtgrp lbtestcd lbtest
/                    data by, along with ACROSSVAR, when        visitnum visit
/                    counting to obtain the numerator.          (lbcccd='n'; lbccind='n') lbcccd lbccind
/                    Additionally a set of brackets may be
/                    inserted within the variables to generate
/                    records containing summary counts grouped
/                    by variables specified to the left of the
/                    brackets. Summary records created may be
/                    populated with values in the grouping
/                    variables by specifying variable value
/                    pairs within brackets, separated by semi
/                    colons. eg aesoccd aesoc(aeptcd=0;
/                    aept="Any Event";) aeptcd aept.
/                    Valid values:
/                    Blank
/                    Name of one or more SAS variables that
/                    exist in DSETINNUMER
/                    SAS assignment statements within brackets
/
/IDVARS              Variables to appear on each page if the    (Blank)
/                    report is wider than 1 page. If no value
/                    is supplied to this parameter then all
/                    displayable order variables will be
/                    defined as IDVARS
/                    Valid values: one or more variable names
/                    from DSETIN that are also defined with
/                    COLUMNS
/
/LABELS              Variables and their label for display.     (Blank)
/                    For use where label for display differs    
/                    to the label on the DSETIN
/                    Valid values: pairs of variable names
/                    and labels
/
/lbRangeHighVarname  Specifies the name of the LAB range high   lbstcchi
/                    value.  Used to determine which lab
/                    tests have missing range ends.
/
/lbRangeIndCodeVarname                                          lbcccd
/                    Specifies the name of the LAB indicator
/                    code. Used to determine which lab tests
/                    have missing range ends.
/
/lbRangeLowVarname   Specifies the name of the LAB range low    lbstcclo
/                    value. Used to determine which lab
/                    tests have missing range ends.
/
/lbTestCDVarName     Specifies the name of the LAB test         lbtestcd
/                    identifier.  Used to determine which
/                    lab tests have missing range ends.
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
/NOPRINTVARS         Variables listed in the COLUMN parameter   visitnum
/                    that are given the PROC REPORT define      summaryLevel
/                    statement attribute noprint                lbcccd
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
/ORDERVARS           List of variables that will receive the    visitnum visit
/                    PROC REPORT define statement attribute     summaryLevel
/                    ORDER                                      lbcccd lbccind
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
/POSTSUBSET          SAS expression to be applied to data       (Blank)
/                    immediately prior to creation of the
/                    permanent presentation dataset. Used for
/                    subsetting records required for
/                    computation but not for display.
/                    Valid values:
/                    Blank
/                    A complete, syntactically valid SAS where
/                    or if statement for use in a data step
/
/POSTBASELINE        Specifies an expression that will be used 
/                    in an IF statement to create records for
/                    the "Any Visit Post Baseline" special
/                    visit category.  To exclude the special
/                    category leave this parameter blank.
/
/POSTBASELINERECODE  Specifies assignment statement(s) to      %nrstr(Visitnum=999;
/                    create the special visit catetory          visit='Any Visit Post Baseline';)
/                    "Any Visit Post Baseline"
/
/PROPTIONS           PROC REPORT statement options to be used   Headline
/                    in addition to MISSING
/                    Valid values: proc report options
/                    The option ?Missing? can not be
/                    overridden
/
/PSOPTIONS           PROC SUMMARY Options to use.               COMPLETETYPES MISSING NWAY
/                    MISSING ensures that class variables with 
/                    missing values are treated as a valid 
/                    grouping. COMPLETETYPES adds records
/                    showing a freq or n of 0 to ensure a 
/                    cartesian product of all class variables 
/                    exists in the output. NWAY writes output 
/                    for the lowest level combinations of CLASS 
/                    variables, suppressing all higher level 
/                    totals. 
/
/PSCLASSOPTIONS      PROC SUMMARY Class Statement Options.      PRELOADFMT
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
/PSFORMAT            Passed to the PROC SUMMARY FORMAT .        &g_trtcd &g_trtfmt
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
/SKIPVARS            Variables whose change in value causes     visit
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
/TOTALDECODE         Label for the total result column.         (Blank)
/                    Usually the text Total
/                    Valid values:
/                    Blank
/                    SAS data step expression resolving to a
/                    character.
/
/TOTALFORVAR         Variable for which total is required       (Blank)
/                    within all other grouped classvars
/                    (usually trtcd). If not specified, no
/                    total will be produced
/                    Valid values: Blank if TOTALID is blank,
/                    else the name of a variable that exists
/                    in DSETIN.
/
/TOTALID             Value used to populate the variable        (Blank)
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
/(@) tu_tidyup
/(@) tu_abort
/(@) tu_chkvarsexist
/(@) tu_chkvartype
/
/ Example:
/    %td_lb2()
/
/*******************************************************************************
/ Change Log
/
/ Modified By:             Paul Jarrett
/ Date of Modification:    21NOV03
/ New version number:      1/2
/ Modification ID:         
/ Reason For Modification: Replace Lab with lbtest and change $3. to $local.
/                          in the value assigned to COMPUTEBEFOREPAGELINES.
/*******************************************************************************
/ Modified By:              Yongwei Wang
/ Date of Modification:     24-Mar-2005
/ New version number:       2/1
/ Modification ID:          YW001
/ Reason For Modification:  Make PSFORMAT and PSCLASSOPTIONS available to be 
/                           editable by the user and passed through to tu_freq. 
/                           Set default value for psformat to be &g_trtcd &g_trtfmt  
/                           And default for PSCLASSOPTIONS to be preloadfmt.
/                           Added new parameter COMPLETETYPESVARS.
/*******************************************************************************
/ Modified By:
/ Date of Modification:
/ New version number:
/ Modification ID:
/ Reason For Modification:
/
/************************************************************************************************/

%macro td_lb2 (
      acrossVar                = &g_trtcd,            /* Variable to transpose the data across to make columns of results. This is passed to the proc transpose ID statement */
      acrossVarDecode          = &g_trtgrp,           /* A variable or format used in the construction of labels for the result columns. Usually &g_trtgrp */
      BREAK1                   = ,                    /* Break statements. */
      BREAK2                   = ,                    /* Break statements. */
      BREAK3                   = ,                    /* Break statements. */
      BREAK4                   = ,                    /* Break statements. */
      BREAK5                   = ,                    /* Break statements. */
      BYVARS                   = ,                    /* By variables */
      CENTREVARS               = ,                    /* Centre justify variables */
      codeDecodeVarPairs       = &g_trtcd &g_trtgrp lbtestcd lbtest visitnum visit lbcccd lbccind, /* Code and Decode variables in pairs */
      COLSPACING               = 2,                   /* Overall spacing value. */
      COLUMNS                  = visitnum visit summaryLevel lbcccd lbccind tt_ac:,  /* Columns to be included in the listing (plus spanned headers) */
      COMPUTEBEFOREPAGELINES   = LBTEST $local. : lbtest,  /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt colon labelvar) */
      COMPUTEBEFOREPAGEVARS    = lbtest,            /* Names of variables that shall define the sort order for Compute Before Page lines */
      countDistinctWhatVar     = &g_centid &g_subjid, /* Variable(s) that contain values to be counted uniquely within any output grouping. Eg &g_subjid */
      completetypesvars        = _all_,               /* Variables which COMPLETETYPES should be applied to */ 
      DDDATASETLABEL           = DD dataset for LB2 table, /* Label to be applied to the DD dataset */
      DEFAULTWIDTHS            = lbtest 90 visit 20 lbccind 20, /* List of default column widths */
      DESCENDING               = ,                    /* Descending ORDERVARS */
      dsetin                   = ardata.lab,          /* Input laba data  */
      FLOWVARS                 = visit lbccind,       /* Variables with flow option */
      FORMATS                  = ,                    /* Format specification */
      groupByVarPop            = &g_trtcd,            /* Variables to group by when counting big N  */
      groupByVarsDenom         = &g_trtcd lbtestcd visitnum, /* Variables in DSETINDENOM to group the data by when counting to obtain the denominator. */
      groupByVarsNumer         = %nrstr(&g_trtcd &g_trtgrp lbtestcd lbtest visitnum visit (lbcccd='n'&sc lbccind='n') lbcccd lbccind), /* Variables in DSETINNUMER to group the data by when counting to obtain the numerator. */
      IDVARS                   = ,                    /* Variables to appear on each page of the report */
      LABELS                   = ,                    /* Label definitions. */
      lbTestCDVarName          = lbtestcd,            /* Variable name of Lab Test Code */
      lbRangeLowVarname        = lbstcclo,            /* Variable name of Low Range Values */
      lbRangeHighVarname       = lbstcchi,            /* Variable name of High Range Values */
      lbRangeIndCodeVarname    = lbcccd,              /* Variable name of Lab Indicator Code Values */
      LEFTVARS                 = ,                    /* Left justify variables */
      LINEVARS                 = ,                    /* Order variable printed with line statements. */
      NOPRINTVARS              = visitnum summaryLevel lbcccd,  /* No print vars (usually used to order the display) */
      NOWIDOWVAR               = ,                    /* Not in version 1 */
      ORDERDATA                = ,                    /* ORDER=DATA variables */
      ORDERFORMATTED           = ,                    /* ORDER=FORMATTED variables */
      ORDERFREQ                = ,                    /* ORDER=FREQ variables */
      ORDERVARS                = visitnum visit summaryLevel lbcccd lbccind,                   /* Order variables */
      PAGEVARS                 = ,                    /* Break after <var> / page */
      postBaseline             = ,                    /* Expression used to identify Any Visit Post Baseline */
      postBaselineRecode       = %nrstr(visitnum=999&sc visit='Any Visit Post Baseline'&sc),  /* Statements used to label Any Visit Post Baseline */
      postsubset               = ,                    /* SAS expression to be applied to data immediately prior to creation of the permanent presentation dataset */
      PROPTIONS                = headline,            /* PROC REPORT statement options */
      psOptions                = COMPLETETYPES MISSING NWAY, /* PROC SUMMARY statement options to use */
      psclassoptions           = PRELOADFMT,          /* PROC SUMMARY CLASS Statement Options */
      psformat                 = &g_trtcd &g_trtfmt,   /* Passed to the PROC SUMMARY FORMAT statement. */
      resultPctDps             = 0,                   /* The reporting precision for percentages */
      resultStyle              = NUMERPCT,            /* The appearance style of the result columns that will be displayed in the report. */
      RIGHTVARS                = ,                    /* Right justify variables */
      SHARECOLVARS             = ,                    /* Order variables that share print space. */
      SHARECOLVARSINDENT       = 2,                   /* Indentation factor */
      SKIPVARS                 = visit,               /* Break after <var> / skip */
      splitChar                = ~,                   /* The split character used in column labels. */
      totalDecode              = ,                    /* Label for the total result column. */
      totalForVar              = ,                    /* Variable for which a total is required */
      totalID                  = ,                    /* Value used to populate the variable specified in ACROSSVAR on data that represents the overall total for the ACROSSVAR variable. */
      VARSPACING               = ,                    /* Spacing for individual variables. */
      WIDTHS                   =                      /* Column widths */
   ); 


   /*
   / Echo the macro name and version to the log. Also echo the parameter values
   / and values of global macro variables used by this macro.
   /---------------------------------------------------------------------------*/

   %local MacroVersion;
   %let MacroVersion = 2;

   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals(varsin=g_dddatasetname g_analy_disp g_ls)

   %local macroversion;
   %let macroversion = 1;
   %inc "&g_refdata/tr_putlocals.sas";
   %tu_putglobals(varsin=g_SUBSET)


   /*
   / Check DSETIN
   /--------------------------------------------------------*/
   %if %bquote(&dsetin) EQ %then
   %do;
      %let g_abort = 1;
      %put %str(RTER)ROR: &sysmacroname: DSETIN must not be blank.;
      %goto MacERROR;
   %end;

   %if %sysfunc(exist(&dsetin)) EQ 0 %then
   %do;
      %let g_abort = 1;
      %put %str(RTER)ROR: &sysmacroname: DSETIN=&dsetin does not exist. ;
      %goto MacERROR;
   %end;

   /*
   / Check logical application of PostBaseline and PostBaseLineRecode
   /----------------------------------------------------------------------------*/
   %if %nrbquote(&postbaseline) NE AND %nrbquote(&postBaselineRecode) EQ %then
   %do;
      %let g_abort = 1;
      %put %str(RTER)ROR: &sysmacroname: POSTBASELINE=&postbaseline however POSTBASELINERECODE is blank.;
      %put %str(RTER)ROR: &sysmacroname: Resolve this inconsistency and resubmit.;
   %end;
  
   %if %nrbquote(&postBaseline) EQ %then
   %do;
      %put %str(RT)NOTE: &sysmacroname: POSTBASELINE is blank no special category will be summarized.;
   %end;
   
   /*
   / Check lab range variables are not blank
   /---------------------------------------------*/
   %if    %nrbquote(&lbtestCDVarName)       EQ
       OR %nrbquote(&lbRangeLowVarName)     EQ
       OR %nrbquote(&lbRangeHighVarName)    EQ
       OR %nrbquote(&lbRangeIndCodeVarName) EQ %then
   %do;
      %let g_abort = 1;
      %put %str(RTER)ROR: &sysmacroname: At Least one of the parameters lbtestCDVarName, lbRangeLowVarName, lbRangeHighVarName, lbRangeIndCodeVarName;
      %put %str(RTER)ROR: &sysmacroname: is blank.;
      %put %str(RTER)ROR: &sysmacroname: lbtestCDVarName=&lbtestCDVarName;
      %put %str(RTER)ROR: &sysmacroname: lbRangeLowVarName=&lbRangeLowVarName;
      %put %str(RTER)ROR: &sysmacroname: lbRangeHighVarName=&lbRangeHighVarName;
      %put %str(RTER)ROR: &sysmacroname: lbRangeIndCodeVarName=&lbRangeIndCodeVarName;
   %end;


   /*
   / Check lab range variables exist in input data
   /------------------------------------------------------*/
   %local allvars donotexist;
   %let allvars    = &lbtestCDVarName &lbRangeLowVarName &lbRangeHighVarName &lbRangeIndCodeVarName;
   %let donotexist = %tu_chkvarsexist(&dsetin,&allvars);
   %if %nrbquote(&donotexist) NE %then
   %do;
      %let g_abort = 1;
      %put %str(RTER)ROR: &sysmacroname: Variable(s) "&donotexist" not found in input data &dsetin;
   %end;

   %if %tu_chkvartype(&dsetin,&lbRangeLowVarName) NE N OR %tu_chkvartype(&dsetin,&lbRangeHighVarname) NE N %then
   %do;
      %let g_abort = 1;
      %put %str(RTER)ROR: &sysmacroname: Variables lbRangeLowVarName=&lbRangeLowVarName and lbRangeHighVarname=&lbRangeHighVarname must be type numeric.;
   %end;

   %if &g_abort = 1 %then %goto macerr;

   %local workroot sc l_vlen;
   %let l_vlen=0;
   %let workroot = %substr(&sysmacroname,3);

   %let sc = %str(;);
   %let groupByVarsNumer   = %unquote(&groupByVarsNumer);
   %let postSubset         = %unquote(&postSubset);
   %let postBaseLineRecode = %unquote(&postBaselineRecode);

   /*
   / determine if LBTEST and LBSTUNIT are in &DSETIN        
   /-------------------------------------------------------------------*/
   %if %nrbquote(&dsetin) ne %then 
   %do;            
      %if %tu_nobs(&dsetin) gt 0 %then 
      %do;
         %if %nrquote(%tu_chkvarsexist(&dsetin, lbtest lbstunit)) eq %then 
         %do;
             data _null_;   
                goto work;
                set &dsetin(keep=lbtest lbstunit obs=0);
                length _a_ 8;            
              work:
                _a_=vlength(lbtest) + vlength(lbstunit) +3;
                call symput('l_vlen', trim(left(put(_a_,best12.))));
                stop;
             run;
         %end;          
      %end;
   %end;   

   /*
   / Create work data set with extra visit for any visit post baselin
   /-------------------------------------------------------------------*/       
   data work.&workroot._visit;
      %if %quote(&l_vlen) GT 0 %then 
      %do;
         length lbtest $&l_vlen;
      %end;
         
      set &dsetin;
      %if %nrbquote(&g_subset) NE %then
      %do;
         where %unquote(&g_subset);
      %end;

      array _c[*] _character_;
      do _i_ = 1 to dim(_c);
         _c[_i_] = left(_c[_i_]);
         end;
      drop _i_;
      
      %if &l_vlen %then
      %do;   
          if not missing(lbstunit) then lbtest=trim(left(lbtest))||" ("||trim(left(lbstunit))||")";
      %end;
      

      output;

      %if %nrbquote(&postBaseline) NE %then
      %do;
         if &postBaseline then
         do;
            &postBaselineRecode;
            output;
         end;
      %end;
      run;

   %if &syserr GT 0 %then
   %do;
      %put %str(RTER)ROR: &sysmacroname: DATA STEP ended with a non-zero return code.;
      %goto macerr;
   %end;


   /*
   / The following steps determine if the ranges have missing ends.
   / Typically some lab parameters have a value above which is of
   / clinical concern but do not have a low value of clinical concern.
   / These conditions are determined by examination of the range values,
   / and removed from the display using POSTSUBSET.
   /---------------------------------------------------------------------*/

   proc summary data=work.&workroot._visit nway missing;
      class &lbTestCDVarName;
      var &lbRangeLowVarname &lbRangeHighVarname;
      output out = work.&workroot._unique
             max = ;
      run;
   %if &syserr GT 0 %then
   %do;
      %put %str(RTER)ROR: &sysmacroname: PROC SUMMARY ended with a non-zero return code.;
      %goto macerr;
   %end;

   data _null_;
      set work.&workroot._unique end=eof;
      length string $5000 text text1 text2 $100 postsubset $5000;
      retain string;
      retain firstflag 1;

      if &lbRangeLowVarname  LE 0 then text1 = "(&lbTestCDVarName='"||trim(&lbTestCDVarName)||"' and &lbRangeIndCodeVarName='L')";
      if &lbRangeHighVarname LE 0 then text2 = "(&lbTestCDVarName='"||trim(&lbTestCDVarName)||"' and &lbRangeIndCodeVarName='H')";

      if      text1 GT ' ' and text2 GT ' ' then text = trim(text1)||' OR '||trim(text2);
      else if text1 GT ' '                  then text = text1;
      else if text2 GT ' '                  then text = text2;

      if not missing(text) then
      do;
         if   firstflag then string = text;
         else                string = trimn(string)||' OR '||text;
         firstflag = 0;
      end;

      if eof and not missing(string) then
      do;
         string = 'if '||trim(string)||' then delete;';
         postsubset = symget('POSTSUBSET');
         call symput('POSTSUBSET',trim(postsubset)||' '||trim(string));
      end;
   run;
   %if &syserr GT 0 %then
   %do;
      %put %str(RTER)ROR: &sysmacroname: DATA STEP ended with a non-zero return code.;
      %goto macerr;
   %end;

   %put %str(RTN)OTE: &sysmacroname: Macro parameter POSTSUSBET has been modified;
   %put %str(RTN)OTE: &sysmacroname: POSTSUBSET=%nrbquote(&postsubset);

   /*
   / More post subset code:  Remove extra records create by COMPLETETYPE that I
   / dont really want.  I need to learn how to get these from TU_FREQ without the
   / extra records.
   / Also remove summary level one percent signs.
   /-------------------------------------------------------------------------------*/
   %local morePostSubset;
   %let morePostSubset = %nrstr(
if  summaryLevel eq 1 and sum(of tt_pct:) LE 0 then delete;
if summaryLevel eq 2 and &lbRangeIndCodeVarName in('N' ' ') then delete;
array _x[*] tt_ac:;
   if summaryLevel eq 1 then 
   do _i_ = 1 to dim(_x);
      if indexc(_x[_i_],'(') then substr(_x[_i_],indexc(_x[_i_],'(')) = '          ';
   end;
   drop _i_;
);

   %let postsubset = %unquote(&postsubset &morepostsubset);
   %put %str(RTN)OTE: &sysmacroname: Macro parameter POSTSUSBET has been modified;
   %put %str(RTN)OTE: &sysmacroname: POSTSUBSET=%nrbquote(&postsubset);


   %tu_freq
      (
         acrossColListName       = acrosscollist,
         acrossColVarPrefix      = tt_ac,
         ACROSSVAR               = &acrossvar,
         ACROSSVARDECODE         = &acrossvardecode,
         addbignyn               = Y,
         bignvarname             = tt_bnnm,
         break1                  = &break1,
         break2                  = &break2,
         break3                  = &break3,
         break4                  = &break4,
         break5                  = &break5,
         byvars                  = &byvars,
         centrevars              = &centrevars,
         codeDecodeVarPairs      = &codeDecodeVarPairs,
         colspacing              = &colspacing,
         columns                 = &columns,
         completetypesvars       =  &completetypesvars,
         computebeforepagelines  = &computebeforepagelines,
         computebeforepagevars   = &computebeforepagevars,
         countDistinctWhatVar    = &countDistinctWhatVar,
         dddatasetlabel          = &dddatasetlabel,
         defaultwidths           = &defaultwidths,
         denormYN                = Y,
         descending              = &descending,
         display                 = Y,
         dsetinDenom             = work.&workroot._visit,
         dsetinNumer             = work.&workroot._visit,
         dsetout                 = ,
         flowvars                = &flowvars,
         formats                 = &formats,
         groupbyvarpop           = &groupbyvarpop,
         groupByVarsDenom        = &groupByVarsDenom,
         groupByVarsNumer        = &groupByVarsNumer,
         groupminmaxvar          =  ,
         idvars                  = &idvars,
         labels                  = &labels,
         labelvarsyn             = Y,
         leftvars                = &leftvars,
         linevars                = &linevars,
         noprintvars             = &noprintvars,
         nowidowvar              = &nowidowvar,
         orderdata               = &orderdata,
         orderformatted          = &orderformatted,
         orderfreq               = &orderfreq,
         ordervars               = &ordervars,
         overallsummary          = N,
         pagevars                = &pagevars,
         postSubset              = &postSubset,
         proptions               = &proptions,
         psByvars                = ,
         psClass                 = ,
         psClassOptions          = &psClassOptions,
         psFormat                = &psFormat,
         psFreq                  = ,
         psid                    = ,
         psOptions               = &psoptions,
         psOutput                = ,
         psOutputOptions         = noinherit,
         psTypes                 = ,
         psWays                  = ,
         psWeight                = ,
         remSummaryPctYN         = N,
         resultPctDps            = &resultPctDps,
         resultStyle             = &resultStyle,
         resultVarName           = tt_result,
         rightvars               = &rightvars,
         rowLabelVarName         = ,
         sharecolvars            = &sharecolvars,
         sharecolvarsindent      = &sharecolvarsindent,
         skipvars                = &skipvars,
         splitchar               = &splitchar,
         spsort2groupbyvarsdenom =  ,
         spsort2groupbyvarsnumer =  ,
         spsort2resultstyle      =  ,
         spsort2resultvarname    =  ,
         spSortGroupByVarsDenom  = ,
         spSortGroupByVarsNumer  = ,
         spSortResultStyle       = ,
         spSortResultVarName     = ,
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
         summaryLevelVarName     = summaryLevel,
         totalDecode             = &totalDecode,
         totalForVar             = &totalForVar,
         totalID                 = &totalID,
         varlabelstyle           = SHORT,
         varspacing              = &varspacing,
         varstodenorm            = tt_result tt_pct,
         widths                  = &widths
      )

   %tu_tidyup(rmdset=&workroot.:,glbmac=NONE)

 %goto exit;

 %macerr:
   %put %str(RTE)RROR: &sysmacroname: Ending with error(s);
   %let g_abort = 1;
   %tu_abort()

 %exit:
   %put %str(RTN)OTE: &sysmacroname: ending execution.;

%mend td_lb2;
