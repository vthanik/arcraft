/*---------------------------------------------------------------------------------------
| Macro Name       : td_es1.sas
|
| Macro Version    : 2
|
| SAS version      : SAS v8.2
|
| Created By       : Yongwei Wang
|
| Date             : Oct 2004
|
| Macro Purpose    : Display macro to produce IDSL ES1 data display
|
| Macro Design     : PROCEDURE STYLE
|
| Input Parameters :
|
| Name                Description                                       Default
| ----------------------------------------------------------------------------------------
| ACROSSVAR           Variable to transpose the data across to make     &g_trtcd
|                     columns of results. This is passed to the proc
|                     transpose ID statement hence the values of this
|                     variable will be used to name the new columns.
|                     Valid Values:
|                     The name of a SAS variable that exists in DSETIN
|                     In typical usage, this will be the variable
|                     containing treatment.
|
| ACROSSVARDECODE     A variable or format used in the construction of  &g_trtgrp
|                     labels for the result columns.
|                     Valid values:
|                     Name of a SAS variable that exists in DSETIN
|
| BREAK1 BREAK2       For input of user-specified break statements      (Blank)
| BREAK3 BREAK4       Valid values: valid PROC REPORT BREAK statements
| BREAK5              (without "break")
|                     The value of these parameters are passed
|                     directly to PROC REPORT as:
|                     BREAK &break1;
|
| BYVARS              By variables. The variables listed here are       (Blank)
|                     processed as standard SAS by variables.
|                     Valid values: one or more variable names from
|                     DSETIN
|                     No formatting of the display for these variables
|                     is performed by %tu_DISPLAY.  The user has the
|                     option of the standard SAS BY line, or using
|                     OPTIONS NOBYLINE and #BYVAL #BYVAR directives in
|                     title statements.
|
| CENTREVARS          Variables to be displayed as centre justified     (Blank)
|                     Valid values: one or more variable names that
|                     are also defined with COLUMNS
|                     Variables not appearing in any of the parameters
|                     CENTREVARS, LEFTVARS, or RIGHTVARS will be
|                     displayed using the PROC REPORT default.
|                     Character variables are left justified while
|                     numeric variables are right justified
|
| CODEDECODEVARPAIRS  Specifies code and decode variable pairs. Those   &g_trtcd &g_trtgrp
|                     variables should be in parameter
|                     GROUPBYVARSNUMER. One variable in the pair will
|                     contain the code, which is used in counting and
|                     ordering, and the other will contain decode,
|                     which is used for presentation.
|                     See section 6.1.1 of Appendix.
|                     Valid values:
|                     Blank or a list of SAS variable names in pairs
|                     that are given in GROUPBYVARSNUMER,
|                     e.g.ttcd trtgrp
|
| COLSPACING          The value of the between-column spacing           2
|                     Valid values: positive integer
|
| COLUMNS             A PROC REPORT column statement specification.     tt_segorder
|                     Including spanning titles and variable names      tt_grplabel
|                     Valid values: one or more variable names from     tt_code1
|                     the DSETOUT dataset, plus other elements of       tt_decode1
|                     valid PROC REPORT COLUMN statement syntax         tt_result:
|
| COMPUTEBEFOREPAGEL  See Unit Specification for HARP Reporting Tools   (Blank)
| INES                TU_LIST[4] for complete details
|
| COMPUTEBEFOREPAGEV  See Unit Specification for HARP Reporting Tools   (Blank)
| ARS                 TU_LIST[4] for complete details
|
| COUNTDISTINCTWHATV  Variable(s) that contain values to be counted     &g_centid
| AR                  uniquely within any output grouping.              &g_subjid
|                     Valid values:
|                     Blank
|                     Name of one or more SAS variables that exists in
|                     DSETINNUMER
|
| DDDATASETLABEL      Specifies the label to be applied to the DD       DD dataset for
|                     dataset                                           ES1 table
|                     Valid values: a non-blank text string
|
| DEFAULTWIDTHS       Specifies column widths for all variables not     (Blank)
|                     listed in the WIDTHS parameter
|                     Valid values: values of column names and numeric
|                     widths such as form valid syntax for a SAS
|                     LENGTH statement
|                     For variables that are not given widths through
|                     either the WIDTHS or DEFAULTWIDTHS parameter
|                     will be width optimised using:
|                     MAX (variables format width,
|                     width of  column header)
|
| DESCENDING          List of ORDERVARS that are given the PROC REPORT  (Blank)
|                     define statement attribute DESCENDING
|                     Valid values: one or more variable names that
|                     are also defined with ORDERVARS
|
| DISPLAY             Specifies whether the report should be created.   Y
|                     Valid values: Y or N
|                     If &g_analy_disp is D, DISPLAY shall be ignored
|
| DSETIN              Input dataset containing data on investigational  ardata.disposit
|                     drug discontinuation.
|
| DSETINDENOM         Input dataset containing data to be counted to    &g_popdata
|                     obtain the denominator. This may or may not be
|                     the same as the dataset specified to
|                     DSETINNUMER.
|                     Valid values:
|                     &g_popdata
|                     Any valid SAS dataset reference; dataset options
|                     are supported.  In typical usage, specifies
|                     &G_POPDATA
|
| DSREASCDLBL         Specify a label for category of Reason for        Primary reason
|                     Discontinuation                                   for withdrawal
|                     Valid values:
|                     An unquoted string
|
| DSREASCDVAR         Specify a variable name of code that specified    dsreascd
|                     why investigational product was stopped. Will be
|                     added to &GROUPBYVARSNUMER of %TU_FREQ
|                     Valid values:
|                     A valid SAS variable name that exists in &DSETIN
|
| DSREASVAR           A variable name that specifies why                dsreas
|                     investigational product was stopped. It is
|                     decode of &DSREASCDVAR. Will be added, with
|                     &DSREASCDVAR, to &CODEDECODEVARPAIRS and
|                     &GROUPBYVARSNUMER of %TU_FREQ
|                     Valid values:
|                     A valid SAS variable name that exists in &DSETIN
|
| DSWDLBL             Specify a Label for category of Complete Status   Completion Status
|                     Valid values:
|                     An unquoted string
|
| DSWDVAR             A variable name to specify if drug stopped. Will  dswd
|                     be added to &GROUPBYVARSNUMER of %TU_FREQ
|                     Valid values:
|                     A valid SAS variable name that exists in &DSETIN
|
| FLOWVARS            Variables to be defined with the flow option      _ALL_
|                     Valid values: one or more variable names that
|                     are also defined with COLUMNS
|                     Flow variables should be given a width through
|                     the WIDTHS.  If a flow variable does not have a
|                     width specified, the column width will be
|                     determined by
|                     MIN(variables format width,
|                     width of  column header)
|
| FORMATS             Variables and their format for display.           (Blank)
|                     Valid values: values of column names and formats
|                     such as form valid syntax for a SAS FORMAT
|                     statement
|
| GROUPBYVARPOP       Specifies a list of variables to group by when    &g_trtcd
|                     counting big N using %tu_addbignvar. Usually one
|                     variable &g_trtcd.
|                     It will be passed to GROUPBYVARS of
|                     %tu_addbignvar.
|                     Required if ADDBIGNYN =Y
|                     Valid values:
|                     Blank if ADDBIGNYN=N
|                     Otherwise, a list of valid SAS variable names
|                     that exist in population dataset created by
|                     %tu_freq's calling %tu_getdata
|
| GROUPBYVARSDENOM    Variables in DSETINDENOM to group the data by     &g_trtcd
|                     when counting to obtain the denominator.
|                     Valid values:
|                     Blank, _NONE_ (to request an overall total for
|                     the whole dataset)
|                     Name of a SAS variable that exists in
|                     DSETINDENOM
|
| GROUPBYVARSNUMER    Variables in DSETINNUMER to group the data by     &g_trtcd &g_trtgrp
|                     when counting to obtain the numerator.
|                     Additionally a set of brackets may be inserted
|                     within the variables to generate records
|                     containing summary counts grouped by variables
|                     specified to the left of the brackets. Summary
|                     records created may be populated with values in
|                     the grouping variables by specifying variable
|                     value pairs within brackets, separated by
|                     semicolons. eg aesoccd aesoc(aeptcd=0; aept="Any
|                     Event";) aeptcd aept.
|                     Valid values:
|                     Blank, _NONE_ (to request an overall total for
|                     the whole dataset)
|                     Name of one or more SAS variables that exist in
|                     DSETINNUMER
|                     SAS assignment statements within brackets
|
| IDVARS              Variables to appear on each page if the report    (Blank)
|                     is wider than 1 page. If no value is supplied to
|                     this parameter then all displayable order
|                     variables will be defined as IDVARS
|                     Valid values: one or more variable names that
|                     are also defined with COLUMNS
|
| LABELS              Variables and their label for display.            (Blank)
|                     Valid values: pairs of variable names and labels
|
| LEFTVARS            Variables to be displayed as left justified       (Blank)
|                     Valid values: one or more variable names  that
|                     are also defined with COLUMNS
|
| LINEVARS            List of order variables that are printed with     (Blank)
|                     LINE statements in PROC REPORT
|                     Valid values: one or more variable names that
|                     are also defined with ORDERVARS
|                     These values shall be written with a BREAK
|                     BEFORE when the value of one of the variables
|                     changes. The variables will automatically be
|                     defined as NOPRINT
|
| NOPRINTVARS         Variables listed in the COLUMN parameter that     tt_segorder
|                     are given the PROC REPORT define statement        tt_code1
|                     attribute noprint
|                     Valid values: one or more variable names that
|                     are also defined with COLUMNS
|                     These variables are ORDERVARS used to control
|                     the order of the rows in the display
|
| NOWIDOWVAR          Variable whose values must be kept together on a  (Blank)
|                     page
|                     Valid values: names of one or more variables
|                     specified in COLUMNS
|
| ORDERDATA           Variables listed in the ORDERVARS parameter that  (Blank)
|                     are given the PROC REPORT define statement
|                     attribute order=data
|                     Valid values: one or more variable names that
|                     are also defined with ORDERVARS
|                     Variables not listed in ORDERFORMATTED,
|                     ORDERFREQ, or ORDERDATA are given the define
|                     attribute order=internal
|
| ORDERFORMATTED      Variables listed in the ORDERVARS parameter that  (Blank)
|                     are given the PROC REPORT define statement
|                     attribute order=formatted
|                     Valid values: one or more variable names that
|                     are also defined with ORDERVARS
|                     Variables not listed in ORDERFORMATTED,
|                     ORDERFREQ, or ORDERDATA are given the define
|                     attribute order=internal
|
| ORDERFREQ           Variables listed in the ORDERVARS parameter that  (Blank)
|                     are given the PROC REPORT define statement
|                     attribute order=freq
|                     Valid values: one or more variable names that
|                     are also defined with ORDERVARS
|                     Variables not listed in ORDERFORMATTED,
|                     ORDERFREQ, or ORDERDATA are given the define
|                     attribute order=internal
|
| ORDERVARS           List of variables that will receive the PROC      tt_segorder
|                     REPORT define statement attribute ORDER           tt_grplabel
|                     Valid values: one or more variable names that     tt_code1
|                     are also defined with COLUMNS
|
| OVERALLSUMMARY      Causes the macro to produce an overall summary    N
|                     line. Use with ShareColVars.
|                     Valid values: Y or N
|                     The values are not calculated - they must be
|                     supplied in a special record in the dataset. The
|                     special record is identified by the fact that
|                     the value for all of the order variables must be
|                     the same for the permutation with the lowest
|                     sort order (as resulting from COLUMN and ORDER),
|                     i.e. the first report row
|
| PAGEVARS            Variables whose change in value causes the        (Blank)
|                     display to continue on a new page
|                     Valid values: one or more variable names that
|                     are also defined with COLUMNS
|
| POSTSUBSET          SAS expression to be applied to data immediately  (Blank)
|                     prior to creation of the permanent presentation
|                     dataset. Used for subsetting records required
|                     for computation but not for display.
|                     Valid values:
|                     Blank
|                     A complete, syntactically valid SAS where or if
|                     statement for use in a data step
|
| PROPTIONS           PROC REPORT statement options to be used in       Headline
|                     addition to MISSING
|                     Valid values: proc report options
|                     The option Missing can not be overridden
|
| PSCLASSOPTIONS      PROC SUMMARY Class Statement Options.             PRELOADFMT
|                     Valid values:
|                     Blank
|                     Valid PROC SUMMARY CLASS Options (without the
|                     leading '/')
|                     Eg: PRELOADFMT  which can be used in
|                     conjunction with PSFORMAT and COMPLETETYPES
|                     (default in PSOPTIONS) to create records for
|                     possible categories that are specified in a
|                     format but which may not exist in data being
|                     summarised.
|
| PSFORMAT            Passed to the PROC SUMMARY FORMAT statement.      (Blank)
|                     Valid values:
|                     Blank
|                     Valid PROC SUMMARY FORMAT statement part.
|
| PSOPTIONS           PROC SUMMARY Options to use. MISSING ensures      COMPLETETYPES
|                     that class variables with missing values are      MISSING NWAY
|                     treated as a valid grouping. COMPLETETYPES adds
|                     records showing a freq or n of 0 to ensure a
|                     cartesian product of all class variables exists
|                     in the output. NWAY writes output for the lowest
|                     level  combinations of CLASS variables,
|                     suppressing all higher level totals.
|                     Valid values:
|                     Blank
|                     One or more valid PROC SUMMARY options
|
| RESULTPCTDPS        The reporting precision for percentages           0
|                     Valid values:
|                     0 or any positive integer
|
| RESULTSTYLE         The appearance style of the result columns that   NUMERPCT
|                     will be displayed in the report. The chosen
|                     style will be placed in variable &RESULTVARNAME.
|                     Valid values:
|                     As documented for tu_percent in [6]. In typical
|                     usage, NUMERPCT.
|
| RIGHTVARS           Variables to be displayed as right justified      (Blank)
|                     Valid values: one or more variable names  that
|                     are also defined with COLUMNS
|
| SEG1FORMAT          Specify a format for variable &DSWD. Will be      $wdstat
|                     added, with &DSREASCD, to parameter PSFORMAT of
|                     %TU_FREQ
|                     Valid values:
|                     A valid SAS variable format variable name in the
|                     format search path
|
| SEG2FORMAT          Specify a format for variable &DSREASCD. Will be  $wdreas.
|                     added, with &DSREASCD, to parameter PSFORMAT of
|                     %TU_FREQ
|                     Valid values:
|                     Blank
|                     A valid SAS variable format variable name in the
|                     format search path
|
| SHARECOLVARS        List of variables that will share print space.    tt_grplabel
|                     The attributes of the last variable in the list   tt_decode1
|                     define the column width and flow options
|                     Valid values: one or more sas variable names
|                     AE5 shows an example of this style of output
|                     The formatted values of the variables shall be
|                     written above each other in one column
|
| SHARECOLVARSINDENT  Indentation factor for ShareColVars. Stacked      2
|                     values shall be progressively indented by
|                     multiples of ShareColVarsIndent
|                     Valid values: positive integer
|
| SKIPVARS            Variables whose change in value causes the        tt_segorder
|                     display to skip a line
|                     Valid values: one or more variable names that
|                     are also defined with COLUMNS
|
| SPLITCHAR           Specifies the split character to be passed to     ~
|                     %tu_display
|                     Valid values: one single character
|
| SPSORTRESULTSTYLE   Special sort: the appearance style of the result  NUMERPCT
|                     data that will be used to sequence the report.
|                     The chosen style will be placed in variable
|                     SPSORTRESULTVARNAME
|                     Valid values:
|                     Blank if SPSORTRESULTVARNAME is blank
|                     Otherwise, as documented for tu_percent in [6].
|                     In typical usage, NUMERPCT.
|
| STACKVAR1-          Specifies any variables that should be stacked    (Blank)
| STACKVAR15          together.  See Unit Specification for HARP
|                     Reporting Tools TU_STACKVAR[5] for more detail
|                     regarding macro parameters that can be used in
|                     the macro call.  Note that the DSETIN parameter
|                     will be passed by %tu_list and should not be
|                     provided here
|
| TOTALDECODE         Label for the total result column. Usually the    Total
|                     text Total
|                     Valid values:
|                     Blank
|                     SAS data step expression resolving to a
|                     character.
|
| TOTALFORVAR         Variable for which total is required within all   &g_trtcd
|                     other grouped classvars (usually trtcd). If not
|                     specified, no total will be produced
|                     Valid values: Blank if TOTALID is blank.
|
| TOTALID             Value used to populate the variable specified in  9999
|                     TOTALFORVAR on data that represents the overall
|                     total for the TOTALFORVAR variable.
|                     If no value is specified to this parameter then
|                     no overall total of the TOTALFORVAR variable
|                     will be generated.
|                     Valid values
|                     Blank
|                     A value that can be entered into &TOTALFORVAR
|                     without SAS error or truncation
|
| VARLABELSTYLE       Specifies the style of labels to be applied by    SHORT
|                     the %tu_labelvars macro
|                     Valid values: as specified by %tu_labelvars,
|                     i.e. SHORT or STD
|
| VARSPACING          Spacing for individual columns                    (Blank)
|                     Valid values: variable name followed by a
|                     spacing value, e.g.
|                     Varspacing=a 1 b 2 c 0
|                     This parameter does NOT allow SAS variable
|                     lists.
|                     These values will override the overall
|                     COLSPACING parameter.
|                     VARSPACING defines the number of blank
|                     characters to leave between the column being
|                     defined and the column immediately to its left
|
| WIDTHS              Variables and width to display                    tt_grplabel 10
|                     Valid values: values of column names and numeric  tt_decode1 30
|                     widths, a list of variables followed by a         tt_result0001-tt_r
|                     positive integer, e.g.                            esult9999 13
|
|                     widths = a b 10 c 12 d1-d4 6
|                     Numbered range lists are supported in this
|                     parameter however name range lists, name prefix
|                     lists, and special SAS name lists are not.
|                     Display layout will be optimised by default,
|                     however any specified widths will cause the
|                     default to be overridden
|
| XMLFORMATS          Full directory path and filename of xml file      &g_refdata/tr_es1_
|                     which contains format information for completion  formats.xml
|                     status and reason for withdrawal.
|                     Valid values: Blank or an existing XML file name
|                     which read into SAS data set and the data set
|                     can be used as CNTLIN in PROC FORMAT
|
|---------------------------------------------------------------------------------------------------
|
| Output:   1. an output file in plain ASCII text format containing a summary in columns data
|              display matching the requirements specified as input parameters.
|           2. SAS data set that forms the foundation of the data display (the "DD dataset").
|
| Global macro variables created: None
|
| Macros called :
|
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_align
| (@) tu_chkvarsexist
| (@) tu_expvarlist
| (@) tu_freq
| (@) tu_list
| (@) tu_nobs
| (@) tu_pagenum
| (@) tu_putglobals
| (@) tu_tidyup
|
| ----------------------------------------------------------------------------
| Change Log :
|
| Modified By :              Yongwei Wang
| Date of Modification :     01-Nov-2004
| New Version Number :       2/2
| Modification ID :          N/A
| Reason For Modification :  Required by change request form HRT0023, the
|                            modification has been modified based on macro
|                            %td_sd1 version 2. The default parameter values
|                            and added variable names have been modified to be
|                            compatible with the old version of td_sd1, which
|                            was developed by Lee Seymour.
+----------------------------------------------------------------------------*/
%macro td_es1(
   ACROSSVAR           =&g_trtcd,          /* Variable to transpose the data across to make columns of results. This is passed to the proc transpose ID statement */
   ACROSSVARDECODE     =&g_trtgrp,         /* A variable or format used in the construction of labels for the result columns. Usually &g_trtgrp */
   BREAK1              =,                  /* Break statements */
   BREAK2              =,                  /* Break statements */
   BREAK3              =,                  /* Break statements */
   BREAK4              =,                  /* Break statements */
   BREAK5              =,                  /* Break statements */
   BYVARS              =,                  /* By variables */
   CENTREVARS          =,                  /* Centre justify variables */
   CODEDECODEVARPAIRS  =&g_trtcd &g_trtgrp, /* Code and Decode variables in pairs */
   COLSPACING          =2,                 /* Value for between-column spacing */
   COLUMNS             =tt_segorder tt_grplabel tt_code1 tt_decode1 tt_result:, /* Columns to be included in the display (plus spanned headers) */
   COMPUTEBEFOREPAGELINES=,                /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt : labelvar) */
   COMPUTEBEFOREPAGEVARS=,                 /* Names of variables that define the sort order for  Compute Before Page lines */
   COUNTDISTINCTWHATVAR=&g_centid &g_subjid, /* Variable(s) that contain values to be counted uniquely within any output grouping. Eg &g_subjid */
   DDDATASETLABEL      =DD dataset for ES1 table, /* Label to be applied to the DD dataset */
   DEFAULTWIDTHS       =,                  /* List of default column widths */
   DESCENDING          =,                  /* Descending ORDERVARS */
   DISPLAY             =Y,                 /* Specifies whether the report should be created */
   DSETIN              =ardata.disposit,   /* Input dataset */
   DSETINDENOM         =&g_popdata,        /* Input dataset containing data to be counted to obtain the denominator. */
   DSREASCDLBL         =Primary reason for withdrawal, /* Label for category of Reason for Discontinuation */
   DSREASCDVAR         =dsreascd,          /* Variable name for reason code of drug stopped */
   DSREASVAR           =dsreas,            /* Variable name for reason of drug stopped */
   DSWDLBL             =Completion Status, /* Label for category of Complete Status */
   DSWDVAR             =dswd,              /* A variable name to specify if drug stopped */
   FLOWVARS            =_ALL_,             /* Variables with flow option */
   FORMATS             =,                  /* Format specification (valid SAS syntax) */
   GROUPBYVARPOP       =&g_trtcd,          /* Variables to group by when counting big N */
   GROUPBYVARSDENOM    =&g_trtcd,          /* Variables in DSETINDENOM to group the data by when counting to obtain the denominator. */
   GROUPBYVARSNUMER    =&g_trtcd &g_trtgrp, /* Variables in DSETINNUMER to group the data by when counting to obtain the numerator. */
   IDVARS              =,                  /* Variables to appear on each page of the report */
   LABELS              =,                  /* Label definitions (var=var label) */
   LEFTVARS            =,                  /* Left justify variables */
   LINEVARS            =,                  /* Order variables printed with LINE statements */
   NOPRINTVARS         =tt_segorder tt_code1, /* No print variables, used to order the display */
   NOWIDOWVAR          =,                  /* List of variables whose values must be kept together on a page */
   ORDERDATA           =,                  /* ORDER=DATA variables */
   ORDERFORMATTED      =,                  /* ORDER=FORMATTED variables */
   ORDERFREQ           =,                  /* ORDER=FREQ variables */
   ORDERVARS           =tt_segorder tt_grplabel tt_code1, /* Order variables */
   OVERALLSUMMARY      =N,                 /* Overall summary line at top of tables */
   PAGEVARS            =,                  /* Variables whose change in value causes the display to continue on a new page */
   POSTSUBSET          =,                  /* SAS expression to be applied to data immediately prior to creation of the permanent presentation dataset */
   PROPTIONS           =Headline,          /* PROC REPORT statement options */
   PSCLASSOPTIONS      =PRELOADFMT,        /* PROC SUMMARY CLASS Statement Options */
   PSFORMAT            =,                  /* Passed to the PROC SUMMARY FORMAT statement. */
   PSOPTIONS           =COMPLETETYPES MISSING NWAY, /* PROC SUMMARY Options to use */
   RESULTPCTDPS        =0,                 /* The reporting precision for percentages */
   RESULTSTYLE         =NUMERPCT,          /* The appearance style of the result columns that will be displayed in the report: */
   RIGHTVARS           =,                  /* Right justify variables */
   SEG1FORMAT          =$wdstat,           /* Format of &DSWDVAR */
   SEG2FORMAT          =$wdreas.,          /* Format of variable &DSREASCD */
   SHARECOLVARS        =tt_grplabel tt_decode1, /* Order variables that share print space */
   SHARECOLVARSINDENT  =2,                 /* Indentation factor */
   SKIPVARS            =tt_segorder,       /* Variables whose change in value causes the display to skip a line */
   SPLITCHAR           =~,                 /* Split character */
   SPSORTRESULTSTYLE   =NUMERPCT,          /* Special sort: the appearance style of the result data that will be used to sequence the report. */
   STACKVAR1           =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc=~) ) */
   STACKVAR2           =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc=~) ) */
   STACKVAR3           =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc=~) ) */
   STACKVAR4           =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc=~) ) */
   STACKVAR5           =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc=~) ) */
   STACKVAR6           =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc=~) ) */
   STACKVAR7           =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc=~) ) */
   STACKVAR8           =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc=~) ) */
   STACKVAR9           =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc=~) ) */
   STACKVAR10          =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc=~) ) */
   STACKVAR11          =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc=~) ) */
   STACKVAR12          =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc=~) ) */
   STACKVAR13          =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc=~) ) */
   STACKVAR14          =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc=~) ) */
   STACKVAR15          =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc=~) ) */
   TOTALDECODE         =Total,             /* Label for the total result column. Usually the text Total */
   TOTALFORVAR         =&g_trtcd,          /* Variable for which a total is required, usually trtcd */
   TOTALID             =9999,              /* Value used to populate the variable specified in TOTALFORVARVAR on data that represents the overall total for the TOTALFORVAR variable. */
   VARLABELSTYLE       =SHORT,             /* Specifies the label style for variables (SHORT or STD) */
   VARSPACING          =,                  /* Column spacing for individual variables */
   WIDTHS              =tt_grplabel 10 tt_decode1 30 tt_result0001-tt_result9999 13, /* Column widths */
   XMLFORMATS          =&g_refdata/tr_es1_formats.xml /* Location and name of XML format file */
   );
   %local MacroVersion;
   %let MacroVersion = 2;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals(varsin=g_dddatasetname g_analy_disp)
   /*
   / Initialise local macro variables created within macro
   /-------------------------------------------------------------*/
   %local
      l_charvars
      l_devar
      l_devars
      l_groupbyvarsnumer
      l_i
      l_j
      l_length
      l_numcharvars
      l_prefix
      l_psformat
      l_missingvars
      l_var
      l_varlents
      l_vars
      l_workdata
      l_dsreascdflag
      l_dswdflag
      l_totallabel
      ;
   /* Assign prefix for work datasets */
   %let l_prefix = _es1;
   /*
   / Parameter validation: required parameter
   / 1. DSREASCDVAR SEG2FORMAT DSWDVAR DSWDLBL and DSREASCDLBL must not
   /    be blank.
   / 2. SEG1FORMAT and DSREASVAR must not be all blank
   /----------------------------------------------------------------------*/
   %let l_vars=DSREASCDVAR SEG1FORMAT DSWDVAR DSWDLBL DSREASCDLBL;
   %do l_i=1 %to 5;
      %let l_var=%scan(&l_vars, &l_i, %str( ));
      %if %nrbquote(&&&l_var) eq %then
      %do;
         %put %str(RTERR)OR: &sysmacroname: Required parameter &l_var. is blank;
         %let g_abort=1;
      %end;
   %end;  /* end of do-loop in &l_i */
   %if (%nrbquote(&SEG2FORMAT) eq ) and (%nrbquote(&dsreasvar) eq ) %then
   %do;
      %put %str(RTERR)OR: &sysmacroname: Parameter SEG2FORMAT and DSREASVAR are blank. At least one should be given;
      %let g_abort=1;
   %end;
   
   %if &g_abort eq 1 %then %goto macerr;
    /*
    /  Read in XML file containing default format for reason for withdrawal.
    /----------------------------------------------------------------------*/
    %if %nrbquote(&xmlformats) ne %then
    %do;
       %if %sysfunc(fileexist(&xmlformats)) = 0 %then
       %do;
          %put %str(RTE)RROR: &sysmacroname : XML File &XMLformats does not exist the macro will now exit;
          %goto MacErr;
       %end;
       libname xmlfmt xml "&xmlformats";
       data &l_prefix.fmt;
          set xmlfmt.es1;
       run;
       /* Check XML format file contains appropriate variables */
       %if %length(%tu_chkvarsexist(dsetin=&l_prefix.fmt,varsin=fmtname start label type)) ne 0 %then
       %do;
          %put %str(RTE)RROR : &sysmacroname : One or more variables (fmtname start label type) do not exist in the XML file;
          %goto macerr;
       %end;
       proc format cntlin=xmlfmt.es1;
       run;
   %end; /* end-if on %nrbquote(&xmlformats) ne */
   /*
   /  Delete any currently existing display file
   /----------------------------------------------------------------------*/
   %tu_pagenum(usage=DELETE)
   %if %nrbquote(&g_abort) eq 1 %then %goto macerr;
   /*
   /  IF GD_ANALY_DISPLAY is D, goto display.
   /----------------------------------------------------------------------*/
   %if %nrbquote(&G_ANALY_DISP) = D %then %goto DISPLAYIT;
   %let l_workdata=&dsetin;
   /*
   /  More parameter validation.
   /----------------------------------------------------------------------*/
   %if ( %nrbquote(&dsetin) eq ) %then
   %do;
      %put %str(RTE)RROR : &sysmacroname : Value of parameter DSETIN is blank and it is required.;
      %goto macerr;   
   %end;
   
   %if ( %tu_nobs(&dsetin) lt 0 )  %then 
   %do;
      %put %str(RTE)RROR : &sysmacroname : Dataset DSETIN=&dsetin does not exist.;
      %goto macerr; 
   %end;   
   
   %let l_i=%tu_chkvarsexist(dsetin=&l_workdata, varsin=&dswdvar &dsreascdvar &dsreasvar);    
   %if %nrbquote(&l_i) ne %then
   %do;
      %put %str(RTE)RROR : &sysmacroname : Variable (&l_i) given by DSWDVAR, DSREASCDVAR or/and DSREASVAR does not exist in DSETIN=&DSETIN.;
      %goto macerr;       
   %end;  
    
   /*
   /  Change the value of &DSWDVAR to be compatible with version 1.
   /----------------------------------------------------------------------*/
   
   data &l_prefix.dsetin;
      set &l_workdata;
      if &dswdvar eq 'N' then &dswdvar='1';
      else if &dswdvar eq 'Y' then &dswdvar='2';
      else if missing(&dswdvar) then &dswdvar='3';
   run;
   
   %let l_workdata=&l_prefix.dsetin;
   %let l_dswdflag=0;
   %if %nrbquote(&dsreasvar) ne %then
   %do;
      %let l_dsreascdflag=1;
   %end;
   %else %do;
      %let l_dsreascdflag=0;
   %end;
   /*
   / Put &dswdvar and &dsreascdvar to an analysis variable list.
   / Loop over the list
   /---------------------------------------------------------------------*/
   %let l_vars=wd reascd;
   %let l_devars=wd reas;
   %do l_i=1 %to 2;
   /*
   / Set GROUPBYVARSNUMER and PSFORMAT parameter of tu_freq for current
   / loop. Call tu_freq to create output data set for current variable
   /--------------------------------------------------------------------*/
      %let l_var=%scan(&l_vars, &l_i, %str( ));
      %let l_devar=%scan(&l_devars, &l_i, %str( ));
      %if %nrbquote(&&seg&l_i.format) ne %then
      %do;
         %if %index(&&seg&l_i.format.., ..) eq 0 %then %let seg&l_i.format=&&seg&l_i.format..;
         %let l_psFormat=&psformat &&ds&l_var.var &&seg&l_i.format ;
      %end;
      %else %do;
         %let l_psFormat=&psformat;
      %end;
      %if &&l_ds&l_var.flag eq 1 %then
      %do;
         %let l_codedecodevarpairs=&&ds&l_var.var &&ds&l_devar.var &codedecodevarpairs;
         %let l_groupByVarsNumer=&groupByVarsNumer &&ds&l_var.var &&ds&l_devar.var;
      %end;
      %else %do;
         %let l_codedecodevarpairs=&codedecodevarpairs;
         %let l_groupByVarsNumer=&groupByVarsNumer &&ds&l_var.var;
      %end;
      %tu_freq (
         acrossColListName       =acrossColList,
         acrossColVarPrefix      =tt_result,
         acrossVar               =&acrossVar,
         acrossVarDecode         =&acrossVarDecode,
         addBigNYN               =Y,
         BigNVarName             =tt_bnnm,
         codeDecodeVarPairs      =&l_codeDecodeVarPairs,
         countDistinctWhatVar    =&countDistinctWhatVar,
         denormYN                =Y,
         display                 =N,
         dsetinDenom             =&dsetinDenom,
         dsetinNumer             =&l_workdata,
         dsetout                 =&l_prefix.ou&l_i,
         labelvarsyn             =Y,
         groupByVarPop           =&groupByVarPop,
         groupByVarsDenom        =&groupByVarsDenom,
         groupByVarsNumer        =&l_groupByVarsNumer,
         postSubset              =,
         psByvars                =,
         psClass                 =,
         psClassOptions          =&psclassoptions,
         psFormat                =&l_psformat,
         psFreq                  =,
         psid                    =,
         psOptions               =&psoptions,
         psOutput                =,
         psOutputOptions         =,
         psTypes                 =,
         psWays                  =,
         psWeight                =,
         remSummaryPctYN         =N,
         resultPctDps            =&resultPctDps,
         resultStyle             =&resultStyle,
         resultVarName           =tt_result,
         rowLabelVarName         =,
         spSortGroupByVarsDenom  =,
         spSortGroupByVarsNumer  =,
         spSortResultStyle       =,
         spSortResultVarName     =,
         totalDecode             =,
         totalForVar             =&totalForVar,
         totalID                 =&totalID,
         varsToDenorm            =tt_result tt_pct
         ) ;
      %if %nrbquote(&g_abort) eq 1 %then %goto macerr;
   /*
   / Add tt_decode1, tt_code1 tt_segorder tt_grplabel to the
   / output data set from tu_freq. The tt_decode1 is the format value
   / of the current analysis variable. The tt_code1 is the value of
   / the current analysis variable. The tt_grplabel is the lable of
   / the current analysis variable. The tt_segorder is the order of the
   / the analysis variables. Clear the format of the analysis variable
   /--------------------------------------------------------------------*/
      %let l_length=%sysfunc(length(&&ds&l_var.lbl));
      data &l_prefix.out&l_i;
         set &l_prefix.ou&l_i;
         length tt_grplabel $&l_length;
         drop &&ds&l_var.var;
         label tt_code1='Decode of value of each category'
               tt_decode1=' '
               tt_grplabel='~'
               tt_segorder='Order of category labels'
               ;
         /*
         /  Modify the label to add the &TOTALDECODE.
         /------------------------------------------------------*/
         %if ( %nrbquote(&totalforvar) ne ) and ( %nrbquote(&totaldecode) ne ) and
             ( %nrbquote(&totalid ) ne ) and ( &l_i eq 1 ) %then
         %do;
            if _n_ eq 1 then call symput('l_totallabel', trim(left(symget('totaldecode')))||trim(left(vlabel(tt_result&totalid.))));
         %end;
         /* get the format value if decode is not given */
         %if &&l_ds&l_var.flag eq 1 %then
         %do;
            tt_decode1=&&ds&l_devar.var;
         %end;
         %else %do;
            tt_decode1=put(&&ds&l_var.var, &&seg&l_i.format);
         %end;
         /* right align numeric values */
         if verify(trim(left(&&ds&l_var.var)), '1234567890') eq 0 then
            tt_code1=' '||right(&&ds&l_var.var);
         else
            tt_code1=&&ds&l_var.var;
         %if &l_var eq wd %then
         %do;
            if ( compress(tt_code1) eq '3' ) and ( compress(tt_decode1) eq '3' ) then tt_decode1='Missing';
         %end;
         /* re-define code and decode of the missing value */
         if missing(&&ds&l_var.var) then
         do;
            tt_code1='zzzzzzzzzz';
            tt_decode1='Missing';
         end;
         tt_grplabel=symget("ds&l_var.lbl");
         tt_segorder=&l_i;
      run;
   /*
   / Get number of variables, name and length of the character variables
   / and get the maximum length of the variables in the output data set
   / of each loop
   /----------------------------------------------------------------------*/
      %if &l_i eq 1 %then
      %do;
         data _null_;
            if 0 then set &l_prefix.out&l_i ;
            array tt_array_vars{*} _CHARACTER_;
            length tt_all_variables tt_var_length $32761;
            tt_all_variables='';
            tt_var_length='';
            do i=1 to dim(tt_array_vars);
               tt_all_variables=trim(left(tt_all_variables))||' '||trim(left(vname(tt_array_vars(i))));
               tt_var_length=trim(left(tt_var_length))||' '||trim(left(vlength(tt_array_vars(i))));
            end;
            call symput('l_charvars', trim(left(tt_all_variables)));
            call symput('l_varlens', trim(left(tt_var_length)));
            call symput('l_numcharvars', compress(dim(tt_array_vars)));
            stop;
         run;
         /*
         /  Keep only discontinuated records.
         /---------------------------------------------------------*/
         data &l_prefix.dsetin2;
            set &l_workdata ;
            if upcase(substr(left(&dswdvar), 1, 1)) eq '2';
         run;
         %let l_workdata=&l_prefix.dsetin2;
      %end;
      %else %do;
         data _null_;
            length tt_var_length $32761 ;
            if 0 then set &l_prefix.out&l_i ;
            %do l_j=1 %to &l_numcharvars;
               tt_max_length=max(vlength(%scan(&l_charvars, &l_j, %str( ))), %scan(&l_varlens, &l_j, %str( )));
               tt_var_length=trim(left(tt_var_length))||' '||trim(left(tt_max_length));
            %end;
            call symput('l_varlens', trim(left(tt_var_length)));
         run;
      %end; /* end-if on L_I */
   %end; /* end of do-loop on l_i */
   /*
   /  Call %tu_expvarlist to expand variable name
   /----------------------------------------------------------*/
   %tu_expvarlist(
      dsetin=&l_prefix.out1,
      varsin=tt_result:,
      varout=l_vars
      );
   %let l_missingvars=%tu_chkvarsexist(&l_prefix.out2, &l_vars);
   /*
   / Combine the output data sets from tu_freq together. Re-define the
   / length of the character variables. Filled '0's if there
   / is no discontinuation under one or more treatment groups.
   /----------------------------------------------------------------------*/
   data &l_prefix.out;
      length
      %do l_j=1 %to &l_numcharvars;
         %scan(&l_charvars, &l_j, %str( )) $%scan(&l_varlens, &l_j, %str( ))
      %end;
      ;
      set &l_prefix.out1
          &l_prefix.out2 (in=tt_ac_dataset_in);
      %if %nrbquote(&l_missingvars) ne %then
      %do;
         array tt_actemporary_array {*} &l_missingvars;
         drop tt_actemporary_array_i;
         if tt_ac_dataset_in and missing(tt_code1) then delete;
         if tt_ac_dataset_in then
         do tt_actemporary_array_i=1 to dim(tt_actemporary_array);
            tt_actemporary_array{tt_actemporary_array_i}='0';
         end;
      %end;
      /*
      /  Apply the label for TOTAL column.
      /------------------------------------------------------*/
      %if ( %nrbquote(&totalforvar) ne ) and ( %nrbquote(&totaldecode) ne ) and
          ( %nrbquote(&totalid ) ne ) %then
      %do;
         label tt_result&totalid="%nrbquote(&l_totallabel)";
      %end;
      /* apply POSTSUBSET */
      %unquote(&POSTSUBSET) ;
   run;
   %let l_workdata=&l_prefix.out;
   %if %tu_nobs(&l_workdata) eq 0 %then %goto displayit;
   /*
   / Run tu_align to align columns across all analysis variables
   /--------------------------------------------------------------------*/
   %tu_align(
      dsetin        =&l_workdata,
      varsin        =&l_vars,
      alignment     =R,
      compresschryn =N,
      dp            =.,
      dsetout       =&l_prefix.final,
      ncspaces      =1
      );
    %let l_workdata=&l_prefix.final;
   /*
   / Call tu_list to create final output.
   /----------------------------------------------------------------------*/
%DISPLAYIT:
   %tu_list(
      break1                =&break1,
      break2                =&break2,
      break3                =&break3,
      break4                =&break4,
      break5                =&break5,
      byvars                =&byvars,
      centrevars            =&centrevars,
      colspacing            =&colspacing,
      columns               =&columns,
      computebeforepagelines=&computebeforepagelines,
      computebeforepagevars =&computebeforepagevars,
      dddatasetlabel        =&dddatasetlabel,
      defaultwidths         =&defaultwidths,
      dsetin                =&l_workdata,
      descending            =&descending,
      display               =&display,
      flowvars              =&flowvars,
      formats               =&formats,
      getdatayn             =N,
      idvars                =&idvars,
      labels                =&labels,
      labelvarsyn           =Y,
      leftvars              =&leftvars,
      linevars              =&linevars,
      noprintvars           =&noprintvars,
      nowidowvar            =&nowidowvar,
      orderdata             =&orderdata,
      orderformatted        =&orderformatted,
      orderfreq             =&orderfreq,
      ordervars             =&ordervars,
      overallsummary        =&overallsummary,
      pagevars              =&pagevars,
      proptions             =&proptions,
      rightvars             =&rightvars,
      sharecolvars          =&sharecolvars,
      sharecolvarsindent    =&sharecolvarsindent,
      skipvars              =&skipvars,
      splitchar             =&splitchar,
      stackvar1             =&stackvar1,
      stackvar2             =&stackvar2,
      stackvar3             =&stackvar3,
      stackvar4             =&stackvar4,
      stackvar5             =&stackvar5,
      stackvar6             =&stackvar6,
      stackvar7             =&stackvar7,
      stackvar8             =&stackvar8,
      stackvar9             =&stackvar9,
      stackvar10            =&stackvar10,
      stackvar11            =&stackvar11,
      stackvar12            =&stackvar12,
      stackvar13            =&stackvar13,
      stackvar14            =&stackvar14,
      stackvar15            =&stackvar15,
      varlabelstyle         =&varlabelstyle,
      varspacing            =&varspacing,
      widths                =&widths
      );
   %goto endmac;
%MACERR:
   %let g_abort=1;
   %tu_abort();
%ENDMAC:
   %tu_tidyup(rmdset=&l_prefix:, glbmac=none);
%mend td_es1;
