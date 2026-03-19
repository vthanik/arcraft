/*                                      
| Macro Name:         td_vs3a
|
| Macro Version:      1
|
| SAS Version:        8
|
| Created By:         Yongwei Wang
|
| Date:               31Aug2006
|
| Macro Purpose:      The unit shall create the IDSL standard data display VS3
|                     identified in the IDSL Data Display Standards.
|
| Macro Design:       Procedure style.
|
| Input Parameters:
|
| Name                Description                                  Default
| -----------------------------------------------------------------------------------
| ACROSSVAR           Variable to transpose the data across to     &g_trtcd
|                     make columns of results. This is passed to
|                     the proc transpose ID statement hence the
|                     values of this variable will be used to
|                     name the new columns. Typically this will
|                     be the code variable containing treatment.
|                     Valid Values:
|                     Blank
|                     Name of a SAS variable that exists in
|                     DSETINNUMER
|
| ACROSSVARDECODE     A variable or format used in the             &g_trtgrp
|                     construction of labels for the result
|                     columns.
|                     Valid values:
|                     If DENORMYN is not Y, blank
|                     Otherwise:
|                     Blank
|                     Name of a SAS variable that exists in
|                     DSETINNUMER
|                     An available SAS format
|
| BASELINE            Specifies an expression that will be used    vschcd eq 'R'
|                     for the Baseline visit
|
| BREAK1 BREAK2       For input of user-specified break            (Blank)
| BREAK3 BREAK4       statements
| BREAK5              Valid values: valid PROC REPORT BREAK
|                     statements (without "break")
|                     The value of these parameters are passed
|                     directly to PROC REPORT as:
|                     BREAK &break1;
|
| BYVARS              By variables. The variables listed here are  (Blank)
|                     processed as standard SAS by variables
|                     Valid values: one or more SAS variable
|                     names
|                     No formatting of the display for these
|                     variables is performed by %tu_display.  The
|                     user has the option of the standard SAS BY
|                     line, or using OPTIONS NOBYLINE and #BYVAL
|                     #BYVAR directives in title statements
|
| CENTREVARS          Variables to be displayed as centre          (Blank)
|                     justified
|                     Valid values: one or more variable names
|                     that are also defined with COLUMNS
|                     Variables not appearing in any of the
|                     parameters CENTREVARS, LEFTVARS, or
|                     RIGHTVARS will be displayed using the PROC
|                     REPORT default. Character variables are
|                     left justified while numeric variables are
|                     right justified
|
| CHANGECATEGORYFORM  Specifies a format to use to format the      $vs3fmt.
| AT                  vaues of the change categories.
|
| CHANGECATEGORYINFO  Specifies a informat to use to group the     $vs3inf.
| RMAT                change indicator codes.  HH, LL, II etc.
|
| CODEDECODEVARPAIRS  Specifies code and decode variable pairs.    &g_trtcd
|                     Those variables should be in parameter       &g_trtgrp
|                     GROUPBYVARSNUMER. One variable in the pair   vstestcd vstest
|                     will contain the code and the other will     visitnum visit
|                     contain decode.                              tt_chgcatcd
|                     Valid values:  Blank or a list of SAS        tt_chgcat
|                     variable names in pairs that are given in
|                     GROUPBYVARSNUMER
|
| COLSPACING          The value of the between-column spacing      2
|                     Valid values: positive integer
|
| COLUMNS             A PROC REPORT column statement               Vstestcd vstest
|                     specification.  Including spanning titles    summaryLevel
|                     and variable names                           tt_chgcatcd
|                     Valid values: one or more variable names     tt_chgcat tt_ac:
|                     plus other elements of valid PROC REPORT
|                     COLUMN statement syntax
|
| COMPUTEBEFOREPAGEL  See Unit Specification for HARP Reporting    VISIT $local. :
| INES                Tools TU_LIST[5] for complete details        visit
|
| COMPUTEBEFOREPAGEV  See Unit Specification for HARP Reporting    Visitnum
| ARS                 Tools TU_LIST[5] for complete details
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
|                     dataset                                      VS3 table
|                     Valid values: a non-blank text string
|
| DEFAULTWIDTHS       Specifies column widths for all variables    tt_chgcat 45
|                     not listed in the WIDTHS parameter
|                     Valid values: values of column names and
|                     numeric widths such as form valid syntax
|                     for a SAS LENGTH statement
|                     For variables that are not given widths
|                     through either the WIDTHS or DEFAULTWIDTHS
|                     parameter will be width optimised using:
|                     MAX (variables format width,
|                     width of  column header)
|
| DESCENDING          List of ORDERVARS that are given the PROC    (blank)
|                     REPORT define statement attribute
|                     DESCENDING
|                     Valid values: one or more variable names
|                     that are also defined with ORDERVARS
|
| DISPLAY             Specifies whether the report should be       Y
|                     created.
|                     Valid values:
|                     Y, N
|                     If &g_analy_disp is D, DISPLAY shall be
|                     ignored
|
| DSETIN              Specifies the input SAS data set.            ardata.vsanal
|
| DSETOUT             Name of output dataset                       (blank)
|                     Valid values:
|                     Blank or a valid SAS dataset name
|
| FLOWVARS            Variables to be defined with the flow        vstest tt_chgcat
|                     option
|                     Valid values: one or more variable names
|                     that are also defined with COLUMNS
|                     Flow variables should be given a width
|                     through the WIDTHS.  If a flow variable
|                     does not have a width specified, the column
|                     width will be determined by
|                     MIN(variables format width,
|                     width of  column header)
|
| FORMATS             Variables and their format for display.      (Blank)
|                     Valid values: values of column names and
|                     formats such as form valid syntax for a SAS
|                     FORMAT statement
|
| GROUPBYVARPOP       Specifies a list of variables to group by    &g_trtcd
|                     when counting big N using %tu_addbignvar.
|                     Usually one variable &g_trtcd.
|                     It will be passed to GROUPBYVARS of
|                     %tu_addbignvar. See Unit Specification for
|                     HARP Reporting Tools TU_ADDBIGNVAR[7]
|                     Required if ADDBIGNYN =Y
|                     Valid values:
|                     Blank if ADDBIGNYN=N
|                     Otherwise, a list of valid SAS variable
|                     names that exist in population dataset
|                     created by %tu_freq's calling %tu_getdata
|
| GROUPBYVARSDENOM    Variables in DSETINDENOM to group the data   &g_trtcd vstestcd
|                     by when counting to obtain the denominator.  visitnum
|                     Valid values:
|                     Blank, _NONE_ (to request an overall total
|                     for the whole dataset)
|                     Name of a SAS variable that exists in
|                     DSETINDENOM
|
| GROUPBYVARSNUMER    Variables in DSETINNUMER to group the data   &g_trtcd
|                     by, along with ACROSSVAR, when counting to   &g_trtgrp
|                     obtain the numerator. Additionally a set of  vstestcd vstest
|                     brackets may be inserted within the          visitnum visit
|                     variables to generate records containing     (tt_chgcatcd='0'
|                     summary counts grouped by variables          %nrstr(;)
|                     specified to the left of the brackets.       tt_chgcat='n')
|                     Summary records created may be populated     tt_chgcatcd
|                     with values in the grouping variables by     tt_chgcat
|                     specifying variable value pairs within
|                     brackets, seperated by semi colons. eg
|                     aesoccd aesoc(aeptcd=0; aept="Any Event";)
|                     aeptcd aept.
|                     Valid values:
|                     Blank
|                     Name of one or more SAS variables that
|                     exist in DSETINNUMER
|                     SAS assignment statements within brackets
|
| IDVARS              Variables to appear on each page if the      (Blank)
|                     report is wider than 1 page. If no value is
|                     supplied to this parameter then all
|                     displayable order variables will be defined
|                     as IDVARS
|                     Valid values: one or more variable names
|                     that are also defined with COLUMNS
|
| LABELS              Variables and their label for display. For   (Blank)
|                     use where label for display differs to the
|                     label the display dataset.
|                     Valid values: pairs of variable names and
|                     labels
|
| LEFTVARS            Variables to be displayed as left justified  (Blank)
|                     Valid values: one or more variable names
|                     that are also defined with COLUMNS
|
| LINEVARS            List of order variables that are printed     (Blank)
|                     with LINE statements in PROC REPORT
|                     Valid values: one or more variable names
|                     that are also defined with ORDERVARS
|                     These values shall be written with a BREAK
|                     BEFORE when the value of one of the
|                     variables changes. The variables will
|                     automatically be defined as NOPRINT
|
| NOPRINTVARS         Variables listed in the COLUMN parameter     visitnum
|                     that are given the PROC REPORT define        summaryLevel
|                     statement attribute noprint                  tt_chgcat vstestcd
|                     Valid values: one or more variable names
|                     that are also defined with COLUMNS
|                     These variables are ORDERVARS used to
|                     control the order of the rows in the
|                     display
|
| NOWIDOWVAR          Variable whose values must be kept together  tt_chgcat
|                     on a page
|                     Valid values: names of one or more
|                     variables specified in COLUMNS
|
| ORDERDATA           Variables listed in the ORDERVARS parameter  (Blank)
|                     that are given the PROC REPORT define
|                     statement attribute order=data
|                     Valid values: one or more variable names
|                     that are also defined with ORDERVARS
|                     Variables not listed in ORDERFORMATTED,
|                     ORDERFREQ, or ORDERDATA are given the
|                     define attribute order=internal
|
| ORDERFORMATTED      Variables listed in the ORDERVARS parameter  (Blank)
|                     that are given the PROC REPORT define
|                     statement attribute order=formatted
|                     Valid values: one or more variable names
|                     that are also defined with ORDERVARS
|                     Variables not listed in ORDERFORMATTED,
|                     ORDERFREQ, or ORDERDATA are given the
|                     define attribute order=internal
|
| ORDERFREQ           Variables listed in the ORDERVARS parameter  (Blank)
|                     that are given the PROC REPORT define
|                     statement attribute order=freq
|                     Valid values: one or more variable names
|                     that are also defined with ORDERVARS
|                     Variables not listed in ORDERFORMATTED,
|                     ORDERFREQ, or ORDERDATA are given the
|                     define attribute order=internal
|
| ORDERVARS           List of variables that will receive the      vstestcd vstest
|                     PROC REPORT define statement attribute       visitnum visit
|                     ORDER                                        visitnum
|                     Valid values: one or more variable names     summaryLevel
|                     that are also defined with COLUMNS           tt_chgcatcd
|                                                                  tt_chgcat
|
| PAGEVARS            Variables whose change in value causes the   (Blank)
|                     display to continue on a new page
|                     Valid values: one or more variable names
|                     that are also defined with COLUMNS
|
| POSTSUBSET          SAS expression to be applied to data         if not missing
|                     immediately prior to creation of the         (tt_chgcatcd)
|                     permanent presentation dataset. Used for
|                     subsetting records required for computation
|                     but not for display.
|                     Valid values:
|                     Blank
|                     A complete, syntactically valid SAS where
|                     or if statement for use in a data step
|
| PROPTIONS           PROC REPORT statement options to be used in  Headline
|                     addition to MISSING
|                     Valid values: proc report options
|                     The option Missing can not be overridden
|
| PSCLASSOPTIONS      PROC SUMMARY Class Statement Options.        PRELOADFMT
|                     Valid Values:
|                     Blank
|                     Valid PROC SUMMARY CLASS Options (without
|                     the leading '/')
|                     Eg: PRELOADFMT  which can be used in
|                     conjunction with PSFORMAT and COMPLETETYPES
|                     (default in PSOPTIONS) to create records
|                     for
|                     possible categories that are specified in a
|                     format but which may not exist in data
|                     being summarised.
|
| PSFORMAT            Passed to the PROC SUMMARY FORMAT            &g_trtcd
|                     statement.                                   &g_trtfmt
|                     Valid Values:                                tt_chgcatcd
|                     Blank                                        $vs3fmt.
|                     Valid PROC SUMMARY FORMAT statement part
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
| RESULTPCTDPS        The reporting precision for percentages      0
|                     Valid values:
|                     0 or any positive integer
|
| RESULTSTYLE         The appearance style of the result columns   NUMERPCT
|                     that will be displayed in the report. The
|                     chosen style will be placed in variable
|                     &RESULTVARNAME.
|                     Valid values:
|                     As documented for tu_percent in [6]. In
|                     typical usage, NUMERPCT.
|
| RIGHTVARS           Variables to be displayed as right           (Blank)
|                     justified
|                     Valid values: one or more variable names
|                     that are also defined with COLUMNS
|
| SHARECOLVARS        List of variables that will share print      Vstest tt_chgcat
|                     space. The attributes of the last variable
|                     in the list define the column width and
|                     flow options
|                     Valid values: one or more SAS variable
|                     names
|                     AE5 shows an example of this style of
|                     output
|                     The formatted values of the variables shall
|                     be written above each other in one column
|
| SHARECOLVARSINDENT  Indentation factor for ShareColVars.         2
|                     Stacked values shall be progressively
|                     indented by multiples of ShareColVarsIndent
|                     Valid values: positive integer
|
| SKIPVARS            Variables whose change in value causes the   vstest
|                     display to skip a line
|                     Valid values: one or more variable names
|                     that are also defined with COLUMNS
|
| SPLITCHAR           The split character used in column labels.   ~
|                     Used in the creation of the label for the
|                     result columns, and in %tu_stackvar,
|                     %tu_display (PROC REPORT). Usually ~
|                     Valid values:
|                     Valid SAS split character.
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
| SPSORTRESULTVARNAM  Special sort: the name of a variable to be   (Blank)
| E                   created to hold the spSortResultStyle data
|                     when merging the special sort sequence
|                     records with the presentation data records.
|                     Valid values:
|                     Blank
|                     A valid SAS variable name.
|                     eg. tt_spSort.
|                     This variable is likely to be included in
|                     the columns and noprint parameters passed
|                     to tu_list.
|
| TOTALDECODE         Label for the total result column. Usually   (Blank)
|                     the text Total
|                     Valid values:
|                     Blank
|                     SAS data step expression resolving to a
|                     character.
|
| TOTALFORVAR         Variable for which total is required within  (Blank)
|                     all other grouped classvars (usually
|                     trtcd). If not specified, no total will be
|                     produced
|                     Valid values: Blank if TOTALID is blank.
|
| TOTALID             Value used to populate the variable          (Blank)
|                     specified in ACROSSVAR on data that
|                     represents the overall total for the
|                     ACROSSVAR variable.
|                     If no value is specified to this parameter
|                     then no overall total of the ACROSSVAR
|                     variable will be generated.
|                     Valid values
|                     Blank
|                     A value that can be entered into &ACROSSVAR
|                     without SAS error or truncation
|
| VARSPACING          Spacing for individual columns               (Blank)
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
| VSCCCDVAR           Specifies a variable which represents        VSCCCD
|                     clinical concern range indicator code
|                     Valid values:
|                     A variable name which exists in &DSETIN
|
| VSTESTCDVAR         Specifies a variable which represents vital  VSTESTCD
|                     sign test code
|                     Valid values:
|                     A variable name which exists in &DSETIN
|
| WIDTHS              Variables and width to display               (Blank)
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
|                     cause the default to be overridden
|
|----------------------------------------------------------------------------------------
| Output:
|  1. The unit shall optionally produce an output file in plain ASCII  text format
|     containing a report matching the requirements specified as input parameters
|  2. The unit shall optionally store the dataset that forms the foundation of the data
|     display
|  3. The unit shall optionally produce an output data set
|----------------------------------------------------------------------------------------
| Global macro variables created: NONE
|----------------------------------------------------------------------------------------
| Macros called:
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_chkvarsexist
| (@) tu_freq
| (@) tu_getdata
| (@) tu_nobs
| (@) tu_putglobals
| (@) tu_tidyup
|----------------------------------------------------------------------------------------
| Example:
|    %td_vs3a()
|----------------------------------------------------------------------------------------
| Change Log
|
| Modified By:
| Date of Modification:
| New version number:
| Modification ID:
| Reason For Modification:
|----------------------------------------------------------------------------------------*/

%macro td_vs3a (
   ACROSSVAR           =&g_trtcd,          /* Variable to transpose the data across to make columns of results. This is passed to the proc transpose ID statement */
   ACROSSVARDECODE     =&g_trtgrp,         /* A variable or format used in the construction of labels for the result columns. Usually &g_trtgrp */
   BASELINE            =vschcd eq 'R',     /* Expression used to identify Baseline visit */
   BREAK1              =,                  /* Break statements */
   BREAK2              =,                  /* Break statements */
   BREAK3              =,                  /* Break statements */
   BREAK4              =,                  /* Break statements */
   BREAK5              =,                  /* Break statements */
   BYVARS              =,                  /* By variables */
   CENTREVARS          =,                  /* Centre justify variables */
   CHANGECATEGORYINFORMAT=$vs3inf.,        /* Name of change category informat */
   CHANGECATEGORYFORMAT=$vs3fmt.,         /* Name of change category format */
   CODEDECODEVARPAIRS  =&g_trtcd &g_trtgrp vstestcd vstest visitnum visit tt_chgcatcd tt_chgcat, /* Code and Decode variables in pairs */
   COLSPACING          =2,                 /* Value for between-column spacing */
   COLUMNS             =Vstestcd vstest summaryLevel tt_chgcatcd tt_chgcat tt_ac:, /* Columns to be included in the listing (plus spanned headers) */
   COMPLETETYPESVARS   =_all_,             /* Variables which COMPLETETYPES should be applied to */
   COMPUTEBEFOREPAGELINES=VISIT $local. : visit, /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt : labelvar) */
   COMPUTEBEFOREPAGEVARS=Visitnum,         /* Names of variables that define the sort order for  Compute Before Page lines */
   COUNTDISTINCTWHATVAR=&g_centid &g_subjid, /* Variable(s) that contain values to be counted uniquely within any output grouping. Eg &g_subjid */
   DDDATASETLABEL      =DD dataset for VS3A table, /* Label to be applied to the DD dataset */
   DEFAULTWIDTHS       =tt_chgcat 45,      /* List of default column widths */
   DESCENDING          =,                  /* Descending ORDERVARS */
   DISPLAY             =Y,                 /* Specifies whether the report should be created */
   DSETIN              =ardata.vsanal(where=(vschcd ne 'P')), /* Input Lab Data */
   DSETOUT             =,                  /* Name of output dataset */
   FLOWVARS            =Vstest tt_chgcat, /* Variables with flow option */
   FORMATS             =,                  /* Format specification (valid SAS syntax) */
   GROUPBYVARPOP       =&g_trtcd,          /* Variables to group by when counting big N */
   GROUPBYVARSDENOM    =&g_trtcd vstestcd visitnum, /* Variables in DSETINDENOM to group the data by when counting to obtain the denominator. */
   GROUPBYVARSNUMER    =%nrstr (&g_trtcd &g_trtgrp vstestcd vstest visitnum visit (tt_chgcatcd='0';tt_chgcat='n') tt_chgcatcd tt_chgcat), /* Variables in DSETINNUMER to group the data by when counting to obtain the numerator. */
   IDVARS              =,                  /* Variables to appear on each page of the report */
   LABELS              =,                  /* Label definitions (var=var label) */
   LEFTVARS            =,                  /* Left justify variables */
   LINEVARS            =,                  /* Order variables printed with LINE statements */
   NOPRINTVARS         =Vstestcd visitnum summaryLevel tt_chgcatcd, /* No print variables, used to order the display */
   NOWIDOWVAR          =tt_chgcat,         /* List of variables whose values must be kept together on a page */
   ORDERDATA           =,                  /* ORDER=DATA variables */
   ORDERFORMATTED      =,                  /* ORDER=FORMATTED variables */
   ORDERFREQ           =,                  /* ORDER=FREQ variables */
   ORDERVARS           =Vstestcd vstest summaryLevel tt_chgcatcd,    		   /* Order variables */
   PAGEVARS            =, 		   /* Variables whose change in value causes the display to continue on a new page */
   POSTSUBSET          =if not missing(tt_chgcatcd), /* SAS expression to be applied to data immediately prior to creation of the permanent presentation dataset */
   PROPTIONS           =Headline,          /* PROC REPORT statement options */
   PSCLASSOPTIONS      =preloadfmt,        /* PROC SUMMARY CLASS Statement Options */
   PSFORMAT            =&g_trtcd &g_trtfmt tt_chgcatcd $vs3fmt.,/* Passed to the PROC SUMMARY FORMAT statement. */
   PSOPTIONS           =COMPLETETYPES MISSING NWAY, /* PROC SUMMARY Options to use */
   RESULTPCTDPS        =0,                 /* The reporting precision for percentages Valid values: 0 or any positive integer */
   RESULTSTYLE         =NUMERPCT,          /* The appearance style of the result columns that will be displayed in the report */
   RIGHTVARS           =,                  /* Right justify variables */
   SHARECOLVARS        =Vstest tt_chgcat,  /* Order variables that share print space */
   SHARECOLVARSINDENT  =2,                 /* Indentation factor */
   SKIPVARS            =Vstest,            /* Variables whose change in value causes the display to skip a line */
   SPLITCHAR           =~,                 /* The split character used in column labels. */
   SPSORTGROUPBYVARSDENOM=,                /* Special sort: variables in DSETINDENOM to group the data by when counting to obtain the denominator. */
   SPSORTGROUPBYVARSNUMER=,                /* pecial sort: variables in DSETINNUMER to group the data by when counting to obtain the numerator */
   SPSORTRESULTVARNAME =,                  /* Special sort: the name of a variable to be created to hold the spSortResultStyle data when merging the special sort sequence records with the presentation data records.*/
   TOTALDECODE         =,                  /* Label for the total result column. Usually the text Total */
   TOTALFORVAR         =,                  /* Variable for which a total is required, usually trtcd */
   TOTALID             =,                  /* Value used to populate the variable specified in ACROSSVAR on data that represents the overall total for the ACROSSVAR variable. */
   VARSPACING	       =,	               /* Column spacing for individual variables */
   VSCCCDVAR           =VSCCCD,            /* Clinical concern range indicator code variable */
   VSTESTCDVAR         =VSTESTCD,          /* Vital sign test code variable */
   WIDTHS              =                   /* Column widths */
   );

   /*
   / Echo the macro name and version to the log. Also echo the parameter values
   / and values of global macro variables used by this macro.
   /---------------------------------------------------------------------------*/

   %local MacroVersion;
   %let MacroVersion = 1;

   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals(varsin=g_subset)

   %local l_prefix sc l_vlen l_dsetin;
   %let l_vlen=0;
   %let l_prefix=_vs3a;

   /*
   / formats are defaults so create them
   /-----------------------------------------*/
   proc format;
      invalue $vs3inf(just upcase)
         'HL','IL' = '1'
         'II','HI','LI','LL','HH' = '2'
         'IH','LH' = '3'
         other = ' '
         ;
      value $vs3fmt
         '1' = 'To Low'
         '2' = 'To Normal or No Change'
         '3' = 'To High'
         ;
   run;
   quit;

   /*
   / Parameter validation
   /-------------------------------------------------------------------*/

   %if %nrbquote(&dsetin) eq %then
   %do;
      %put %str(RTER)ROR: &sysmacroname: Required parameter DSETIN is blank.;
      %let g_abort=1;
   %end;

   %if %nrbquote(&VSCCCDVAR) eq %then
   %do;
      %put %str(RTER)ROR: &sysmacroname: Required parameter VSCCCDVAR is blank.;
      %let g_abort=1;
   %end;

   %if %nrbquote(&VSTESTCDVAR) eq %then
   %do;
      %put %str(RTER)ROR: &sysmacroname: Required parameter VSTESTCDVAR is blank.;
      %let g_abort=1;
   %end;

   %if %nrbquote(&BASELINE) eq %then
   %do;
      %put %str(RTER)ROR: &sysmacroname: Required parameter BASELINE is blank.;
      %let g_abort=1;
   %end;

   %if %nrbquote(&g_abort) gt 0 %then %goto macerr;

   %let l_dsetin=&dsetin;

   %if %tu_nobs(&dsetin) lt 0 %then
   %do;
      %put %str(RTER)ROR: &sysmacroname: DSETIN(=&dsetin) does not exist.;
      %let g_abort=1;
   %end;
   %else %do;
      data &l_prefix.dsetin;
         set &dsetin;
      run;

      %let l_dsetin=&l_prefix.dsetin;
   %end;

   %if %tu_chkvarsexist(&l_dsetin, &VSCCCDVAR) ne %then
   %do;
      %put %str(RTER)ROR: &sysmacroname: Variable VSCCCDVAR(=&VSCCCDVAR) does not exist in DSETIN(=&dsetin).;
      %let g_abort=1;
   %end;

   %if %tu_chkvarsexist(&l_dsetin, &VSTESTCDVAR) ne %then
   %do;
      %put %str(RTER)ROR: &sysmacroname: Variable VSTESTCDVAR(=&VSTESTCDVAR) does not exist in DSETIN(=&dsetin).;
      %let g_abort=1;
   %end;

   %if %nrbquote(&g_abort) gt 0 %then %goto macerr;

   %if %nrbquote(&changeCategoryInformat) eq %then %let changeCategoryInformat=$vs3inf.;
   %if %nrbquote(&changeCategoryformat) eq %then %let changeCategoryInformat=$vs3fmt.;

   /*
   / Call %tu_getdata to subset data set
   /-------------------------------------------------------------------*/

   %tu_getdata(
      dsetin=&l_dsetin,
      dsetout1=&l_prefix.dsetin1,
      dsetout2=
      );

   %let l_dsetin=&l_prefix.dsetin1;

   /*
   / Split data to baseline and postbaseline
   /-------------------------------------------------------------------*/

   data &l_prefix.base (rename=(&vscccdvar=_baseline_cccd))
        &l_prefix.post;
      set &l_prefix.dsetin;

      if %unquote(&baseline) then
         output &l_prefix.base;
      else
         output &l_prefix.post ;
   run;

   %if &syserr GT 0 %then
   %do;
      %put %str(RTER)ROR: &sysmacroname: DATA STEP ended with a non-zero return code.;
      %goto macerr;
   %end;

   proc sort data=&l_prefix.base(keep=&g_centid &g_subjid &vstestcdvar _baseline_cccd) nodupkey;
      by &g_centid &g_subjid &vstestcdvar;
   run;

   proc sort data=&l_prefix.post;
      by &g_centid &g_subjid &vstestcdvar;
   run;

   data &l_prefix.post;
      merge &l_prefix.post (in=__in1__) &l_prefix.base;
      by &g_centid &g_subjid &vstestcdvar;
      drop _change_cccd _baseline_cccd;

      length tt_chgcatcd $2;

      if __in1__;
      if not missing(&vscccdvar) and not missing(_baseline_cccd) then
         _change_cccd = substr(_baseline_cccd,1,1)||substr(&vscccdvar,1,1);

      tt_chgcatcd = input(_change_cccd, &changeCategoryInformat);
      tt_chgcat   = put(_change_cccd, &changeCategoryformat);

      label
         tt_chgcatcd = 'Change Category Code'
         tt_chgcat   = 'Change Category'
         ;
   run;

   %if &syserr GT 0 %then
   %do;
      %put %str(RTER)ROR: &sysmacroname: DATA STEP ended with a non-zero return code.;
      %goto macerr;
   %end;

   %let l_dsetin=&l_prefix.post;

%DISPLAYIT:

   %tu_freq(
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
      completetypesvars       = &completetypesvars,
      computebeforepagelines  = &computebeforepagelines,
      computebeforepagevars   = &computebeforepagevars,
      countDistinctWhatVar    = &countDistinctWhatVar,
      dddatasetlabel          = &dddatasetlabel,
      defaultwidths           = &defaultwidths,
      denormYN                = Y,
      descending              = &descending,
      display                 = &display,
      dsetinDenom             = &l_dsetin,
      dsetinNumer             = &l_dsetin,
      dsetout                 = &dsetout,
      flowvars                = &flowvars,
      formats                 = &formats,
      groupbyvarpop           = &groupbyvarpop,
      groupByVarsDenom        = &groupByVarsDenom,
      groupByVarsNumer        = &groupByVarsNumer,
      groupminmaxvar          = ,
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
      remSummaryPctYN         = Y,
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
      spSortGroupByVarsDenom  = &spSortGroupByVarsDenom,
      spSortGroupByVarsNumer  = &spSortGroupByVarsNumer,
      spSortResultStyle       = %if %nrbquote(&spSortResultVarName) ne %then PCT;,
      spSortResultVarName     = &spSortResultVarName,
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
      );

   %goto macend;

%macerr:
   %put %str(RTE)RROR: &sysmacroname: Ending with error(s);
   %let g_abort = 1;
   %tu_abort()

%macend:
   %tu_tidyup(
      rmdset=&l_prefix.:,
      glbmac=NONE
      );

   %put %str(RTN)OTE: &sysmacroname: ending execution.;

%mend td_vs3a;

