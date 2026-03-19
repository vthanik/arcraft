/*
|
| Macro Name:         td_es4
|
| Macro Version:      1
|
| SAS Version:        8
|
| Created By:         Yongwei Wang
|
| Date:               18Jun2007
|
| Macro Purpose:      A macro to produce an overall summary of the number and
|                     percentage of subjects who entered, withdrew from and completed
|                     each phase/period/segment of the study (ES4).
|
| Macro Design:       Procedure style.
|
| Input Parameters:
| Name                Description                                  Default
| -----------------------------------------------------------------------------------
| ACROSSVAR           Specifies a variable that has multiple       &g_trtcd
|                     levels and will be transposed to multiple
|                     columns
|                     Valid values: Blank or a SAS variable that
|                     exists in combined output data set of
|                     segments
|
| ACROSSVARDECODE     Specifies the name of a variable that        &g_trtgrp
|                     contains  decoded values of ACROSSVAR, or
|                     the name of a  SAS format
|                     Valid values: Blank, or a SAS variable that
|                     exists in combined output data set of
|                     segments, or a SAS format
|
| BREAK1 BREAK2       5 parameters for input of user specified     (Blank)
| BREAK3 BREAK4       break statements.
| BREAK5              Valid values: valid PROC REPORT BREAK
|                     statements (without "break")
|                     The value of these parameters are passed
|                     directly to PROC REPORT as:
|                     BREAK &break1;
|
| BYVARS              By variables. The variables listed here are  (Blank)
|                     processed as standard SAS BY variables.
|                     Valid values: one or more variable names
|                     from DSETIN
|                     It is the caller's responsibility to
|                     provide a sorted dataset as DSETIN;
|                     TU_DISPLAY will not sort the dataset.
|                     No formatting of the display for these
|                     variables is performed by %tu_DISPLAY.  The
|                     user has the option of the standard SAS BY
|                     line, or using OPTIONS NOBYLINE and #BYVAL
|                     #BYVAR directives in title statements.
|
| CENTREVARS          Variables to be displayed as centre          (Blank)
|                     justified.
|                     Valid values: one or more variable names
|                     from DSETIN that are also defined with
|                     COLUMNS
|                     Variables not appearing in any of the
|                     parameters CENTREVARS, LEFTVARS, or
|                     RIGHTVARS will be displayed using the PROC
|                     REPORT default. Character variables are
|                     left justified while numeric variables are
|                     right justified.
|
| CODEDECODEVARPAIRS  Specifies code and decode variable pairs.    visitnum visit
|                     Those variables should be in parameter       &g_trtcd &g_trtgrp
|                     GROUPBYVARSNUMER. One variable in the pair
|                     will contain the code, which is used in
|                     counting and ordering, and the other will
|                     contain decode, which is used for
|                     presentation.
|                     See section 6.1.1 of Appendix.
|                     Valid values:  Blank or a list of SAS
|                     variable names in pairs that are given in
|                     GROUPBYVARSNUMER,
|                     e.g.ttcd trtgrp
|
| COLSPACING          The value of the between-column spacing.     2
|                     Valid values: positive integer
|
| COLUMNS             A PROC REPORT column statement               visitnum visit
|                     specification.  Including spanning titles    summaryLevel
|                     and variable names                           dsfail tt_ac:
|                     Valid values: one or more variable names
|                     from DSETIN plus other elements of valid
|                     PROC REPORT COLUMN statement syntax, but
|                     not including report_item=alias syntax
|
| COMPLETETYPESVARS   Specify a list of variables which are in     _ALL_
|                     GROUPBYVARSANALY and the COMPLETETYPES
|                     given by PSOPTIONS should be applied to. If
|                     it equals _ALL_, all variables in
|                     GROUPBYVARSANALY will be included.
|                     Valid Values:
|                     _ALL_
|                     A list of variable names which are in
|                     GROUPBYVARSANALY
|
| COMPUTEBEFOREPAGEL  Specifies the labels that shall precede the  (Blank)
| INES                ComputeBeforePageVar value. For each
|                     variable specified for
|                     COMPUTEBEFOREPAGEVARS, four values shall be
|                     specified for COMPUTEBEFOREPAGELINES. The
|                     four values shall be:
|                     * A localisation key for the fixed
|                     labelling text
|                     * The name of the localisation format
|                     ($local.)
|                     * The character(s) to be used between the
|                     labelling text and the values of the fourth
|                     parameter
|                     * Name of a variable whose values are to be
|                     used in the Computer Before Page line
|                     Valid values: A multiple of four words
|                     separated by blanks. The multiple shall be
|                     equal to the number of variables specified
|                     for COMPUTEBEFOREPAGEVARS
|                     For example:
|                     GRP $local. : xValue TRTMNT $local. :
|                     trtgrp
|
| COMPUTEBEFOREPAGEV  Variables listed in this parameter are       (Blank)
| ARS                 printed between the SAS title lines and the
|                     column headers for the report.
|                     Valid values: one or more variable names
|                     from DSETIN
|                     PROC REPORT code resulting from this
|                     parameter:
|
|                     define VAR1   / order noprint;
|                     define VAR2   / order noprint;
|
|
|                     define VARn   / order noprint;
|                     break before VARn / page;
|                     compute before _page_ / left;
|                     line VAR1 $char&g_ls..;
|                     line VAR2 $char&g_ls..;
|
|
|                     line VARn $char&g_ls..;
|                     endcomp;
|                     The value of each ComputeBeforePageVar is
|                     printed as is with no additional
|                     formatting.  Do NOT include these variables
|                     in the COLUMNS parameter they will be added
|                     by the macro.  It is not necessary to list
|                     these variables in the ORDERVARS or
|                     NOPRINTVARS parameters.  The ORDER= option
|                     for these variables is control using
|                     ORDERVARSFORMATTED,
|                     ORDERVARSFREQ, or
|                     ORDERVARSDATA parameters.
|
| COUNTDISTINCTWHATV  Variable(s) that contain values to be        &g_centid
| AR                  counted uniquely within any output           &g_subjid
|                     grouping.
|                     Valid values:
|                     Blank
|                     Name of one or more SAS variables that
|                     exists in DSETINNUMER
|
| DDDATASETLABEL      Specifies the label to be applied to the DD  DD dataset for
|                     dataset                                      new ES4 table
|                     Valid values: a non-blank text string
|
| DEFAULTWIDTHS       This is a list of default widths for ALL     visit 20 dsfail
|                     columns and will usually be defined by the   12 tt_ac: 18
|                     DD macro.  This parameter specifies column
|                     widths for all variables not listed in the
|                     WIDTHS parameter.
|                     Valid values: values of column names and
|                     numeric widths, a list of variables
|                     followed by a positive integer, e.g.
|
|                     defaultwidths = a b 10 c 12 d1-d4 6
|                     Numbered range lists are supported in this
|                     parameter however name range lists, name
|                     prefix lists, and special SAS name lists
|                     are not.
|                     Variables that are not given widths through
|                     either the WIDTHS or DEFAULTWIDTHS
|                     parameter will be width optimised using:
|                     MAX (variables format width,
|                     width of column header) for variables that
|                     are NOT flowed or
|                     MIN(variables format width,
|                     width of column header) for variable that
|                     ARE flowed.
|
| DESCENDING          List of ORDERVARS that are given the PROC    (Blank)
|                     REPORT define statement attribute
|                     DESCENDING
|                     Valid values: one or more variable names
|                     from DSETIN that are also defined with
|                     ORDERVARS
|
| DISPLAY             Specifies whether the report should be       Y
|                     created.
|                     Valid values: Y or N
|
| DSETINDENOM         Input dataset containing data to be counted  &g_popdata
|                     to obtain the denominator. This may or may
|                     not be the same as the dataset specified to
|                     DSETINNUMER.
|                     Valid values:
|                     &g_popdata
|                     Any valid SAS dataset reference; dataset
|                     options are supported.  In typical usage,
|                     specifies &G_POPDATA
|
| DSETINNUMER         Input dataset containing data to be counted  ardata.ds
|                     to obtain the numerator.
|                     Valid Values:
|                     Any valid SAS dataset reference; dataset
|                     options are supported.
|
| DSETOUT             Name of output dataset                       (Blank)
|                     Valid values: Blank or A valid SAS dataset
|                     name
|
| FLOWVARS            Variables to be defined with the flow        visit
|                     option.
|                     Valid values: one or more variable names
|                     from DSETIN that are also defined with
|                     COLUMNS
|                     Flow variables should be given a width
|                     through the WIDTHS.  If a flow variable
|                     does not have a width specified the column
|                     width will be determined by
|                     MIN(variables format width,
|                     width of  column header)
|
| FORMATS             Variables and their format for display. For  dsfail $dsfaile.
|                     use where format for display differs to the
|                     format on the DSETIN.
|                     Valid values: values of column names and
|                     formats such as form valid syntax for a SAS
|                     FORMAT statement
|
| GROUPBYVARPOP       Specifies a list of variables to group by    &g_trtcd
|                     when counting big N using %tu_addbignvar.
|                     Usually one variable &g_trtcd.
|                     It will be passed to GROUPBYVARS of
|                     %tu_addbignvar.
|                     Required if ADDBIGNYN =Y
|                     Valid values:
|                     Blank if ADDBIGNYN=N
|                     Otherwise, a list of valid SAS variable
|                     names that exist in population dataset
|                     created by %tu_freq's calling %tu_getdata
|
| GROUPBYVARSDENOM    Variables in DSETINDENOM to group the data   &g_trtcd
|                     by when counting to obtain the denominator.
|                     Valid values:
|                     Blank, _NONE_ (to request an overall total
|                     for the whole dataset)
|                     Name of a SAS variable that exists in
|                     DSETINDENOM
|
| GROUPBYVARSNUMER    Variables in DSETINNUMER to group the data   &g_trtcd visitnum
|                     by when counting to obtain the numerator.    visit dsfail
|                     Additionally a set of brackets may be
|                     inserted within the variables to generate
|                     records containing summary counts grouped
|                     by variables specified to the left of the
|                     brackets. Summary records created may be
|                     populated with values in the grouping
|                     variables by specifying variable value
|                     pairs within brackets, separated by
|                     semicolons. eg aesoccd aesoc(aeptcd=0;
|                     aept="Any Event";) aeptcd aept.
|                     Valid values:
|                     Blank, _NONE_ (to request an overall total
|                     for the whole dataset)
|                     Name of one or more SAS variables that
|                     exist in DSETINNUMER
|                     SAS assignment statements within brackets
|
| IDVARS              Variables to appear on each page should the  (Blank)
|                     report be wider than 1 page. If no value is
|                     supplied to this parameter then all
|                     displayable order variables will be defined
|                     as idvars
|                     Valid values: one or more variable names
|                     from DSETIN that are also defined with
|                     COLUMNS
|
| LABELS              Variables and their label for display. For   dsfail="~"
|                     use where label for display differs to the
|                     label on the DSETIN
|                     Valid values: pairs of variable names and
|                     labels with equals signs between them
|
| LEFTVARS            Variables to be displayed as left justified  (Blank)
|                     Valid values: one or more variable names
|                     from DSETIN that are also defined with
|                     COLUMNS
|
| LINEVARS            List of order variables that are printed     (Blank)
|                     with LINE statements in PROC REPORT
|                     Valid values: one or more variable names
|                     from DSETIN that are also defined with
|                     ORDERVARS
|                     These values shall be written with a BREAK
|                     BEFORE when the value of one of the
|                     variables change. The variables will
|                     automatically be defined as NOPRINT
|
| NOPRINTVARS         Variables listed in the COLUMN parameter     visitnum
|                     that are given the PROC REPORT define        summaryLevel
|                     statement attribute noprint.
|                     Valid values: one or more variable names
|                     from DSETIN that are also defined with
|                     COLUMNS
|                     These variables are usually ORDERVARS used
|                     to control the order of the rows in the
|                     display.
|
| NOWIDOWVAR          Variable whose values must be kept together  (Blank)
|                     on a page
|                     Valid values: names of one or more
|                     variables specified in COLUMNS
|
| ORDERDATA           Variables listed in the ORDERVARS parameter  (Blank)
|                     that are given the PROC REPORT define
|                     statement attribute order=data.
|                     Valid values: one or more variable names
|                     from DSETIN that are also defined with
|                     ORDERVARS
|                     Variables not listed in ORDERFORMATTED,
|                     ORDERFREQ, or ORDERDATA are given the
|                     define attribute order=internal
|
| ORDERFORMATTED      Variables listed in the ORDERVARS parameter  (Blank)
|                     that are given the PROC REPORT define
|                     statement attribute order=formatted.
|                     Valid values: one or more variable names
|                     from DSETIN that are also defined with
|                     ORDERVARS
|                     Variables not listed in ORDERFORMATTED,
|                     ORDERFREQ, or ORDERDATA are given the
|                     define attribute order=internal
|
| ORDERFREQ           Variables listed in the ORDERVARS parameter  (Blank)
|                     that are given the PROC REPORT define
|                     statement attribute order=freq.
|                     Valid values: one or more variable names
|                     from DSETIN that are also defined with
|                     ORDERVARS
|                     Variables not listed in ORDERFORMATTED,
|                     ORDERFREQ, or ORDERDATA are given the
|                     define attribute order=internal
|
| ORDERVARS           List of variables that will receive the      visitnum visit
|                     PROC REPORT define statement attribute       dsfail
|                     ORDER
|                     Valid values: one or more variable names
|                     from DSETIN that are also defined with
|                     COLUMNS
|
| PAGEVARS            Variables whose change in value causes the   (Blank)
|                     display to continue on a new page
|                     Valid values: one or more variable names
|                     from DSETIN that are also defined with
|                     COLUMNS
|
| POSTSUBSET          SAS expression to be applied to data         (Blank)
|                     immediately prior to creation of the
|                     permanent presentation dataset. Used for
|                     subsetting records required for computation
|                     but not for display.
|                     Valid values: Blank or a complete,
|                     syntactically valid SAS where or if
|                     statement for use in a data step
|
| PROPTIONS           PROC REPORT statement options to be used in  Headline
|                     addition to MISSING.
|                     Valid values: proc report options
|                     The option Missing can not be overridden.
|
| PSBYVARS            Passed to %tu_stats and will be used in the  (Blank)
|                     PROC SUMMARY BY statement in %tu_stats.
|                     This will cause the data to be sorted
|                     first.
|                     Valid values: Blank, or the name of one or
|                     more variables that exist in DSETIN. DSETIN
|                     need not be sorted by &psbyvars
|
| PSCLASSOPTIONS      Passed to %tu_stats and will be used in the  PRELOADFMT
|                     PROC SUMMARY CLASS statement options.
|                     Valid values:
|                     Valid PROC SUMMARY Class options (without
|                     the leading '/')
|                     E.g.: PRELOADFMT  which can be used in
|                     conjunction with PSFORMAT and COMPLETETYPES
|                     (default in PSOPTIONS) to create records
|                     for possible categories that are specified
|                     in a format but which may not exist in data
|                     being summarised.
|
| PSFORMAT            Passed to the PROC SUMMARY FORMAT            &g_trtcd &g_trtfmt
|                     statement.                                   dsfail $dsfail.
|                     Valid values:
|                     Blank
|                     Valid PROC SUMMARY FORMAT statement part
|                     Note: The macro will not check if the
|                     format is valid. If a given variable in
|                     &PSFORMAT is not in &GROUPBVARSANALY, the
|                     variable and its format in &PSFORMAT will
|                     not be passed to %tu_stats
|
| PSOPTIONS           PROC SUMMARY Options to use. MISSING         COMPLETETYPES
|                     ensures that class variables with missing    MISSING NWAY
|                     values are treated as a valid grouping.
|                     COMPLETETYPES adds records showing a freq
|                     or n of 0 to ensure a cartesian product of
|                     all class variables exists in the output.
|                     NWAY writes output for the lowest level
|                     combinations of CLASS variables,
|                     suppressing all higher level totals.
|                     Valid values:
|                     Blank
|                     One or more valid PROC SUMMARY options
|
| REMSUMMARYPCTYN     Remove summary level percentage Y/N.         N
|                     Setting to Y keeps only the first character
|                     string of the field requested by the
|                     RESULTSTYLE parameter. It is only used when
|                     STATSLIST is blank
|                     Valid values:
|                     Y, N
|                     In typical usage, in conjunction with
|                     RESULSTYLE=NUMERPCT, this shows the n count
|                     for a group without the percentage, where
|                     the count shows the denominator used within
|                     a group.
|
| RESULTPCTDPS        The reporting precision for percentages. It  0
|                     is required and only used when STATSLIST is
|                     blank
|                     Valid values:
|                     As documented for tu_percent in [6]
|
| RESULTSTYLE         The appearance style of the result columns   NUMERPCT
|                     that will be displayed in the report. The
|                     chosen style will be placed in variable
|                     &RESULTVARNAME. It is only used when
|                     STATSLIST is blank.
|                     Valid values:
|                     As documented for tu_percent in [6]. In
|                     typical usage, NUMERPCT.
|
| RIGHTVARS           Variables to be displayed as right           (Blank)
|                     justified
|                     Valid values: one or more variable names
|                     from DSETIN that are also defined with
|                     COLUMNS
|
| SHARECOLVARS        List of variables that will share print      (Blank)
|                     space. The attributes of the last variable
|                     in the list define the column width and
|                     flow options
|                     Valid values: one or more variable names
|                     from DSETIN
|                     AE5 shows an example of this style of
|                     output
|                     The formatted values of the variables shall
|                     be written above each other in one column.
|
| SHARECOLVARSINDENT  Indentation factor for ShareColVars.         2
|                     Stacked values shall be progressively
|                     indented by multiples of
|                     ShareColVarsIndent.
|                     REQUIRED when SHARECOLVARS is specified
|                     Valid values: positive integer
|
| SKIPVARS            Variables whose change in value causes the   visit
|                     display to skip a line
|                     Valid values: one or more variable names
|                     from DSETIN that are also defined with
|                     COLUMNS
|
| SPLITCHAR           Specifies the split character to be passed   ~
|                     to %tu_display
|                     Valid values: one single character
|
| SPSORTGROUPBYVARSD  Special sort: variables in DSETINDENOM to    (Blank)
| ENOM                group the data by when counting to obtain
|                     the denominator.
|                     Valid values:
|                     Blank if SPSORTRESULTVARNAME is blank
|                     Otherwise,
|                     Blank
|                     _NONE_
|                     Name of a SAS variable that exists in
|                     DSETINDENOM
|
| SPSORTGROUPBYVARSN  Special sort: variables in DSETINNUMER to    (Blank)
| UMER                group the data by when counting to obtain
|                     the numerator.
|                     Valid values:
|                     Blank if SPSORTRESULTVARNAME is blank
|                     Otherwise,
|                     Name of one or more SAS variables that
|                     exist in DSETINNUMER
|
| SPSORTRESULTSTYLE   Special sort: the appearance style of the    (Blank)
|                     result data that will be used to sequence
|                     the report. The chosen style will be placed
|                     in variable SPSORTRESULTVARNAME
|                     Valid values:
|                     Blank if SPSORTRESULTVARNAME is blank
|                     Otherwise, as documented for tu_percent in
|                     [6]. In typical usage, NUMERPCT.
|
| SPSORTRESULTVARNAM  Special sort: the name of a variable to be   (Blank)
| E                   created to hold the spSortResultStyle data
|                     when merging the special sort sequence
|                     records with the presentation data records.
|                     Valid values:
|                     Blank
|                     A valid SAS variable name.
|                     Eg tt_spSort.
|                     This variable is likely to be included in
|                     the columns and noprint parameters passed
|                     to tu_list.
|
| TOTALDECODE         Value(s) used to populate the variable(s)    Entered
|                     of the decode variable(s) of the
|                     TOTALFORVAR. If a value has more than one
|                     word, the value should be quoted with
|                     single or double quote
|                     Valid values
|                     Blank
|                     A list of values that can be entered into
|                     the decode of the TOTALFORVAR variable(s)
|                     Note: If a value is longer than the length
|                     of the decode variable, the value will be
|                     truncated
|
| TOTALFORVAR         Variable for which overall totals are        dsfail
|                     required within all other grouped class
|                     variables. If not specified, no total will
|                     be produced. Can be one or a list of
|                     followings:
|                     1. Blank
|                     2. Name of a variable
|                     3. Variable with sub group of values inside
|                     of ( and ). In this case, the total is
|                     for subgroup of the values listed inside of
|                     ( and )
|                     4. A list of 2 or 3 separated by *. In
|                     this case, the overall total is based on
|                     more than one variable
|                     Valid values:
|                     Can be one or a list of followings:
|                     1. Blank
|                     2. Name of a variable
|                     3. Variable with sub group of values inside
|                     of ( and )
|                     4. A list of 2 or 3 separated by *
|
| TOTALID             Value(s) used to populate the variable(s)    E
|                     specified in TOTALFORVAR.
|                     Valid values
|                     Blank
|                     A list of values that can be entered into
|                     &TOTALFORVAR
|                     Note: If a value is longer than the length
|                     of the TOTALFORVAR variable, the value will
|                     be truncated
|
| VARLABELSTYLE       Specifies the style of labels to be applied  SHORT
|                     by the %tu_labelvars macro
|                     Valid values: as specified by
|                     %tu_labelvars, i.e. SHORT or STD
|
| VARSPACING          Spacing for individual columns.              (Blank)
|                     Valid values: variable name followed by a
|                     spacing value, e.g.
|                     Varspacing=a 1 b 2 c 0
|                     This parameter does NOT allow SAS variable
|                     lists.
|                     These values will override the overall
|                     COLSPACING parameter.
|                     VARSPACING defines the number of blank
|                     characters to leave between the column
|                     being defined and the column immediately to
|                     its left
|
| WIDTHS              Variables and width to display.              (Blank)
|                     Valid values: values of column names and
|                     numeric widths, a list of variables
|                     followed by a positive integer, e.g.
|
|                     widths = a b 10 c 12 d1-d4 6
|                     Numbered range lists are supported in this
|                     parameter however name range lists, name
|                     prefix lists, and special SAS name lists
|                     are not.
|                     Display layout will be optimised by
|                     default, however any specified widths will
|                     cause the default to be overridden.
|-------------------------------------------------------------------------------
| Output: 1. Printed output 2. Optional output data set 3. DD Data set
|-------------------------------------------------------------------------------
| Global macro variables created: NONE
|-------------------------------------------------------------------------------
| Macros called:
|(@) tr_putlocals
|(@) tu_freq
|(@) tu_putglobals
|-------------------------------------------------------------------------------
| Example:
|    %td_es4()
|
|-------------------------------------------------------------------------------
| Change Log
|
| Modified By:
| Date of Modification:
| New version number:
| Modification ID:
| Reason For Modification:
|-----------------------------------------------------------------------------*/

%macro td_es4 (
   ACROSSVAR           =&g_trtcd,          /* Variable(s) that will be transposed to columns */
   ACROSSVARDECODE     =&g_trtgrp,         /* The name of the decode variable(s) for ACROSSVAR */
   BREAK1              =,                  /* Break statements. */
   BREAK2              =,                  /* Break statements. */
   BREAK3              =,                  /* Break statements. */
   BREAK4              =,                  /* Break statements. */
   BREAK5              =,                  /* Break statements. */
   BYVARS              =,                  /* By variables */
   CENTREVARS          =,                  /* Centre justify variables */
   CODEDECODEVARPAIRS  =visitnum visit &g_trtcd &g_trtgrp, /* Code and Decode variables in pairs */
   COLSPACING          =2,                 /* Overall spacing value. */
   COLUMNS             =visitnum visit summaryLevel dsfail tt_ac:, /* Column parameter */
   COMPLETETYPESVARS   =_ALL_,             /* Variables which COMPLETETYPES should be applied to */
   COMPUTEBEFOREPAGELINES=,                /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt colon labelvar) */
   COMPUTEBEFOREPAGEVARS=,                 /* Computed by variables. */
   COUNTDISTINCTWHATVAR=&g_centid &g_subjid, /* Variable(s) that contain values to be counted uniquely within any output grouping. Eg &g_subjid */
   DDDATASETLABEL      =DD dataset for new ES4 table, /* Label to be applied to the DD dataset */
   DEFAULTWIDTHS       =visit 20 dsfail 12 tt_ac: 18, /* List of default column widths */
   DESCENDING          =,                  /* Descending ORDERVARS */
   DISPLAY             =Y,                 /* Specifies whether the report should be created */
   DSETINDENOM         =&g_popdata,        /* Input dataset containing data to be counted to obtain the denominator. */
   DSETINNUMER         =ardata.ds,         /* Input dataset containing data to be counted to obtain the numerator. */
   DSETOUT             =,                  /* Name of output dataset */
   FLOWVARS            =visit,             /* Variables with flow option */
   FORMATS             =dsfail $dsfaile.,  /* Format specification */
   GROUPBYVARPOP       =&g_trtcd,          /* Variables to group by when counting big N */
   GROUPBYVARSDENOM    =&g_trtcd,          /* Variables in DSETINDENOM to group the data by when counting to obtain the denominator. */
   GROUPBYVARSNUMER    =&g_trtcd visitnum visit dsfail, /* Variables in DSETINNUMER to group the data by when counting to obtain the numerator. */
   IDVARS              =,                  /* Variables to appear on each page should the report be wider than 1 page */
   LABELS              =dsfail="~",        /* Label definitions. */
   LEFTVARS            =,                  /* Left justify variables */
   LINEVARS            =,                  /* Order variable printed with line statements. */
   NOPRINTVARS         =visitnum summaryLevel, /* No print vars (usually used to order the display) */
   NOWIDOWVAR          =,                  /* Variable whose values must be kept together on a page */
   ORDERDATA           =,                  /* ORDER=DATA variables */
   ORDERFORMATTED      =,                  /* ORDER=FORMATTED variables */
   ORDERFREQ           =,                  /* ORDER=FREQ variables */
   ORDERVARS           =visitnum visit dsfail, /* Order variables */
   PAGEVARS            =,                  /* Break after <var> / page; */
   POSTSUBSET          =,                  /* SAS expression to be applied to data immediately prior to creation of the permanent presentation dataset */
   PROPTIONS           =Headline,          /* PROC REPORT statement options */
   PSBYVARS            =,                  /* Advanced Usage: Passed to the PROC SUMMARY By statement. This will cause the data to be sorted first. */
   PSCLASSOPTIONS      =PRELOADFMT,        /* PROC SUMMARY Class statement options */
   PSFORMAT            =&g_trtcd &g_trtfmt dsfail $dsfail., /* Passed to the PROC SUMMARY FORMAT statement. */
   PSOPTIONS           =COMPLETETYPES MISSING NWAY, /* PROC SUMMARY Options to use */
   REMSUMMARYPCTYN     =N,                 /* Remove summary level percentage Y/N */
   RESULTPCTDPS        =0,                 /* The reporting precision for percentages */
   RESULTSTYLE         =NUMERPCT,          /* The appearance style of the result columns that will be displayed in the report: */
   RIGHTVARS           =,                  /* Right justify variables */
   SHARECOLVARS        =,                  /* Order variables that share print space. */
   SHARECOLVARSINDENT  =2,                 /* Indentation factor */
   SKIPVARS            =visit,             /* Break after <var> / skip; */
   SPLITCHAR           =~,                 /* Split character */
   SPSORTGROUPBYVARSDENOM=,                /* Special sort: variables in DSETINDENOM to group the data by when counting to obtain the denominator. */
   SPSORTGROUPBYVARSNUMER=,                /* Special sort: variables in DSETINNUMER to group the data by when counting to obtain the numerator. */
   SPSORTRESULTSTYLE   =,                  /* Special sort: the appearance style of the result data that will be used to sequence the report. */
   SPSORTRESULTVARNAME =,                  /* Special sort: the name of a variable to be created to hold the spSortResultStyle data when merging the special sort sequence records with the presentation data records. */
   TOTALDECODE         =Entered,           /* Value(s) used to populate the variable(s) of the decode variable(s) of the TOTALFORVAR. */
   TOTALFORVAR         =dsfail,            /* Variable(s) for which a overall total is required */
   TOTALID             =E,                 /* Value(s) used to populate the variable(s) specified in TOTALFORVAR. */
   VARLABELSTYLE       =SHORT,             /* Specifies the label style for variables (SHORT or STD) */
   VARSPACING          =,                  /* Spacing for individual variables. */
   WIDTHS              =                   /* Column widths */
   );

   /*
   / Write details of macro call to log
   /----------------------------------------------------------------------*/

   %local MacroVersion;
   %let MacroVersion=1;

   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals()

   /*
   / Call %tu_freq to creat final output
   /-----------------------------------------------------------------------*/

   %tu_freq(
      ACROSSCOLLISTNAME      =acrossColList,
      ACROSSCOLVARPREFIX     =tt_ac,
      ACROSSVAR              =&ACROSSVAR,
      ACROSSVARDECODE        =&ACROSSVARDECODE,
      ADDBIGNYN              =Y,
      BIGNVARNAME            =tt_bnnm,
      BREAK1                 =&BREAK1,
      BREAK2                 =&BREAK2,
      BREAK3                 =&BREAK3,
      BREAK4                 =&BREAK4,
      BREAK5                 =&BREAK5,
      BYVARS                 =&BYVARS,
      CENTREVARS             =&CENTREVARS,
      CODEDECODEVARPAIRS     =&CODEDECODEVARPAIRS,
      COLSPACING             =&COLSPACING,
      COLUMNS                =&COLUMNS,
      COMPLETETYPESVARS      =&COMPLETETYPESVARS,
      COMPUTEBEFOREPAGELINES =&COMPUTEBEFOREPAGELINES,
      COMPUTEBEFOREPAGEVARS  =&COMPUTEBEFOREPAGEVARS,
      COUNTDISTINCTWHATVAR   =&COUNTDISTINCTWHATVAR,
      DDDATASETLABEL         =&DDDATASETLABEL,
      DEFAULTWIDTHS          =&DEFAULTWIDTHS,
      DENORMYN               =Y,
      DESCENDING             =&DESCENDING,
      DISPLAY                =&DISPLAY,
      DSETINDENOM            =&DSETINDENOM,
      DSETINNUMER            =&DSETINNUMER,
      DSETOUT                =&DSETOUT,
      FLOWVARS               =&FLOWVARS,
      FORMATS                =&FORMATS,
      GROUPBYVARPOP          =&GROUPBYVARPOP,
      GROUPBYVARSDENOM       =&GROUPBYVARSDENOM,
      GROUPBYVARSNUMER       =&GROUPBYVARSNUMER,
      GROUPMINMAXVAR         =,
      IDVARS                 =&IDVARS,
      LABELS                 =&LABELS,
      LABELVARSYN            =Y,
      LEFTVARS               =&LEFTVARS,
      LINEVARS               =&LINEVARS,
      NOPRINTVARS            =&NOPRINTVARS,
      NOWIDOWVAR             =&NOWIDOWVAR,
      ORDERDATA              =&ORDERDATA,
      ORDERFORMATTED         =&ORDERFORMATTED,
      ORDERFREQ              =&ORDERFREQ,
      ORDERVARS              =&ORDERVARS,
      OVERALLSUMMARY         =N,
      PAGEVARS               =&PAGEVARS,
      POSTSUBSET             =&POSTSUBSET,
      PROPTIONS              =&PROPTIONS,
      PSBYVARS               =&PSBYVARS,
      PSCLASS                =,
      PSCLASSOPTIONS         =&PSCLASSOPTIONS,
      PSFORMAT               =&PSFORMAT,
      PSFREQ                 =,
      PSID                   =,
      PSOPTIONS              =&PSOPTIONS,
      PSOUTPUT               =,
      PSOUTPUTOPTIONS        =,
      PSTYPES                =,
      PSWAYS                 =,
      PSWEIGHT               =,
      REMSUMMARYPCTYN        =&REMSUMMARYPCTYN,
      RESULTPCTDPS           =&RESULTPCTDPS,
      RESULTSTYLE            =&RESULTSTYLE,
      RESULTVARNAME          =tt_result,
      RIGHTVARS              =&RIGHTVARS,
      ROWLABELVARNAME        =,
      SHARECOLVARS           =&SHARECOLVARS,
      SHARECOLVARSINDENT     =&SHARECOLVARSINDENT,
      SKIPVARS               =&SKIPVARS,
      SPLITCHAR              =&SPLITCHAR,
      SPSORT2GROUPBYVARSDENOM=,
      SPSORT2GROUPBYVARSNUMER=,
      SPSORT2RESULTSTYLE     =,
      SPSORT2RESULTVARNAME   =,
      SPSORTGROUPBYVARSDENOM =&SPSORTGROUPBYVARSDENOM,
      SPSORTGROUPBYVARSNUMER =&SPSORTGROUPBYVARSNUMER,
      SPSORTRESULTSTYLE      =&SPSORTRESULTSTYLE,
      SPSORTRESULTVARNAME    =&SPSORTRESULTVARNAME,
      STACKVAR1              =,
      STACKVAR10             =,
      STACKVAR11             =,
      STACKVAR12             =,
      STACKVAR13             =,
      STACKVAR14             =,
      STACKVAR15             =,
      STACKVAR2              =,
      STACKVAR3              =,
      STACKVAR4              =,
      STACKVAR5              =,
      STACKVAR6              =,
      STACKVAR7              =,
      STACKVAR8              =,
      STACKVAR9              =,
      SUMMARYLEVELVARNAME    =summaryLevel,
      TOTALDECODE            =&TOTALDECODE,
      TOTALFORVAR            =&TOTALFORVAR,
      TOTALID                =&TOTALID,
      VARLABELSTYLE          =SHORT,
      VARSPACING             =&VARSPACING,
      VARSTODENORM           =tt_result tt_pct,
      WIDTHS                 =&WIDTHS
      );

%mend td_es4;
