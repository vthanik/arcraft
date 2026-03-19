/*----------------------------------------------------------------------------------------
|
| Macro Name:    td_ae6
|
| Macro Version: 1
|
| SAS Version:   8
|
| Created By:    Yongwei Wang
|
| Date:          09-Jan-2004
|
| Macro Purpose: A macro to create Adverse Event Display AE6.
|
| Macro Design:  Procedure style.
|
| Input Parameters:
| Name                Description                                       Default
| ----------------------------------------------------------------------------------------
| ACROSSVAR           Variable to transpose the data across to make     tt_intcd
|                     columns of results. This is passed to the proc
|                     transpose ID statement hhence the values of this 
|                     variable will be used to name the new columns. 
|                     Typically this will be the code variable 
|                     containing treatment.
|                     Valid Values:
|                     Name of a SAS variable that exists in
|                     DSETINNUMER
|
| ACROSSVARDECODE     A variable or format used in the construction of  tt_int
|                     labels for the result columns.
|                     Valid values:
|                     If DENORMYN is not Y, blank
|                     Otherwise:
|                     Blank
|                     Name of a SAS variable that exists in
|                     DSETINNUMER
|                     An available SAS format
|
| AESTDTVAR           Specify a variable name for AE start date         aestdt
|                     Valid Values:
|                     Name of a SAS variable that exists in &DSETIN
|
| AESTTMVAR           Specify a variable name for AE start time         (Blank)
|                     Valid Values:
|                     Blank or
|                     Name of a SAS variable that exists in &DSETIN
|
| BREAK1 BREAK2       For input of user-specified break statements      (Blank)
| BREAK3 BREAK4       Valid values: valid PROC REPORT BREAK statements
| BREAK5              (without "break")
|                     The value of these parameters are passed
|                     directly to PROC REPORT as:
|                     BREAK &break1;
|
| BYVARS              By variables. The variables listed here are       (Blank)
|                     processed as standard SAS by variables
|                     Valid values: Blank or one or more SAS variable names
|                     No formatting of the display for these variables
|                     is performed by %tu_display.  The user has the
|                     option of the standard SAS BY line, or using
|                     OPTIONS NOBYLINE and #BYVAL #BYVAR directives in
|                     title statements
|
| CENTREVARS          Variables to be displayed as centre justified     (Blank)
|                     Valid values: Blank or one or more variable names
|                     that are also defined with COLUMNS
|                     Variables not appearing in any of the parameters
|                     CENTREVARS, LEFTVARS, or RIGHTVARS will be
|                     displayed using the PROC REPORT default.
|                     Character variables are left justified while
|                     numeric variables are right justified
|
| CODEDECODEVARPAIRS  Specifies code and decode variable pairs. Those   &g_trtcd &g_trtgrp
|                     variables should be in parameter
|                     GROUPBYVARSNUMER. One variable in the pair will
|                     contain the code and the other will contain
|                     decode
|                     Valid values:  Blank or a list of SAS variable
|                     names in pairs that are given in
|                     GROUPBYVARSNUMER
|
| COLSPACING          The value of the between-column spacing           2
|                     Valid values: positive integer
|
| COLUMNS             A PROC REPORT column statement specification.     tt_spsort aesoc
|                     Including spanning titles and variable names.     summaryLevel
|                     Valid values: one or more variable names plus     tt_pct999 aept
|                     other elements of valid PROC REPORT COLUMN        ("_Time Since
|                     statement syntax                                  Start of Study
|                                                                       Medication_"
|                                                                       tt_ac:)
|
| COMPLETETYPESVARS   Specify a list of variables which are in          &g_trtcd tt_intcd
|                     GROUPBYVARSANALY and the COMPLETETYPES given by 
|                     PSOPTIONS should be applied to. If it equals 
|                     _ALL_, all variables in GROUPBYVARSANALY will be 
|                     included.
|                     Valid values: _ALL_, Blank, A list of variable 
|                     names which are in GROUPBYVARSANALY
|
| COMPUTEBEFOREPAGEL  See Unit Specification for HARP Reporting Tools   TRTMNT $local. :
| INES                TU_LIST[5] for complete details                   &g_trtgrp
|
| COMPUTEBEFOREPAGEV  See Unit Specification for HARP Reporting Tools   &g_trtcd
| ARS                 TU_LIST[5] for complete details
|
| COUNTDISTINCTWHATV  Variable(s) that contain values to be counted     &g_centid
| AR                  uniquely within any output grouping.              &g_subjid
|                     Valid values:
|                     Blank
|                     Name of one or more SAS variables that exists in
|                     DSETINNUMER
|
| DDDATASETLABEL      Specifies the label to be applied to the DD       DD dataset for
|                     dataset                                           AE6 table
|                     Valid values: a non-blank text string
|
| DEFAULTWIDTHS       Specifies column widths for all variables not     aesoc 30 aept 30
|                     listed in the WIDTHS parameter
|                     Valid values: Blank or values of column names 
|                     and numeric widths such as form valid syntax for 
|                     a SAS LENGTH statement
|                     For variables that are not given widths through
|                     either the WIDTHS or DEFAULTWIDTHS parameter
|                     will be width optimised using:
|                     MAX (variable's format width,
|                     width of  column header)
|
| DESCENDING          List of ORDERVARS that are given the PROC REPORT  tt_spsort
|                     define statement attribute DESCENDING             tt_pct999
|                     Valid values: one or more variable names that
|                     are also defined with ORDERVARS
|
| DSETINDENOM         Input dataset containing data to be counted to    &g_popdata
|                     obtain the denominator. This may or may not be
|                     the same as the dataset specified to
|                     DSETINNUMER.
|                     Valid values:
|                     &g_popdata
|                     any other valid SAS dataset reference
|
| DSETINMSTONE        Input dataset containing data to be counted to    ardata.mstone
|                     obtain the denominator. This may or may not be 
|                     the same as the dataset specified to DSETINNUMER.
|                     Valid values: Blaink or a valid SAS dataset.
|
| DSETINNUMER         Input dataset containing data to be counted to    ardata.ae
|                     obtain the numerator.
|                     Valid Values:
|                     Valid sas dataset name
|
| FLOWVARS            Variables to be defined with the flow option      aesoc aept
|                     Valid values: Blank or one or more variable 
|                     names that are also defined with COLUMNS
|                     Flow variables should be given a width through
|                     the WIDTHS.  If a flow variable does not have a
|                     width specified, the column width will be
|                     determined by
|                     MIN(variable's format width,
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
|                     %tu_addbignvar. See Unit Specification for HARP
|                     Reporting Tools TU_ADDBIGNVAR[7]
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
| GROUPBYVARSNUMER    Variables in DSETINNUMER to group the data by,    &g_trtcd
|                     along with ACROS                                  &g_trtgrp
|                     Valid values:                                     tt_intcd
|                     Blank                                             (aesoc='DUMMY'
|                     Name of one or more SAS variables that exist in   %nrstr(&sc)
|                     DSETINNUMER                                       aept='ANY EVENT')
|                     SAS assignment statements within brackets         aesoc (aept='Any
|                                                                       event') aept
|
| GROUPMINMAXVAR      Specify if frequency of each group should be get  min(aestdt)
|                     from minimum or maximum value of variable(s) in 
|                     format MIN(variables). The first or last value 
|                     of the variable(s) in each subgroup of 
|                     &GROUPBYVARSANALY for &COUNTDISTINCWHATVAR will 
|                     be created before calculating the frequency.
|                     Valid values: Blank, MIN({variable(s)}), 
|                     MAX({variable(s)})
|                     NOTE: {variables} means a list of valid SAS 
|                     variable that exists in DSETIN
|
| IDVARS              Variables to appear on each page if the report    &g_trtcd
|                     is wider than 1 page. If no value is supplied to  tt_spsort aesoc
|                     this parameter then all displayable order         summarylevel
|                     variables will be defined as IDVARS               tt_pct999 aept
|                     Valid values: Blank or one or more variable names 
|                     that are also defined with COLUMNS
|
| LABELS              Variables and their label for display. For use    aept='System
|                     where label for display differs to the label the  Organ Class~
|                     display dataset.                                  Preferred Term'
|                     Valid values: pairs of variable names and labels
|
| LEFTVARS            Variables to be displayed as left justified       (Blank)
|                     Valid values: one or more variable names that
|                     are also defined with COLUMNS
|
| LINEVARS            List of order variables that are printed with     (Blank)
|                     LINE statements in PROC REPORT
|                     Valid values: Blank or one or more variable names 
|                     that are also defined with ORDERVARS
|                     These values shall be written with a BREAK
|                     BEFORE when the value of one of the variables
|                     changes. The variables will automatically be
|                     defined as NOPRINT
|
| NOPRINTVARS         Variables listed in the COLUMN parameter that     tt_spsort
|                     are given the PROC REPORT define statement        summaryLevel
|                     attribute noprint                                 tt_pct999
|                     Valid values: Blank or one or more variable       
|                     names that are also defined with COLUMNS          
|                     These variables are ORDERVARS used to control
|                     the order of the rows in the display
|
| NOWIDOWVAR          Variable whose values must be kept together on a  (Blank)
|                     page
|                     Valid values: Blank or names of one or more 
|                     variables specified in COLUMNS
|
| NUMOFTIMEINTERVALS  Specify number of time spans to be divided.       12
|                     See TIMEINTERVAL for detail.
|                     Valid Values: Blank or a numeric value.
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
|                     Valid values: one or more variable names  that
|                     are also defined with ORDERVARS
|                     Variables not listed in ORDERFORMATTED,
|                     ORDERFREQ, or ORDERDATA are given the define
|                     attribute order=internal
|
| ORDERVARS           List of variables that will receive the PROC      &g_trtcd tt_spsort
|                     REPORT define statement attribute ORDER           aesoc summaryLevel
|                     Valid values: one or more variable names that     tt_pct999 aept
|                     are also defined with COLUMNS
|
| PAGEVARS            Variables whose change in value causes the        (Blank)
|                     display to continue on a new page
|                     Valid values: one or more variable names that
|                     are also defined with COLUMNS
|
| POSTSUBSET          SAS expression to be applied to data immediately  if tt_pct999 GT 0
|                     prior to creation of the perm                     %nrstr(&sc)
|                     Valid values:
|                     Blank
|                     A complete, syntactically valid SAS where or if
|                     statement for use in a data step
|
| PROPTIONS           PROC REPORT statement options to be used in       Headline
|                     addition to MISSING
|                     Valid values: proc report options
|                     The option 'Missing' can not be overridden
|
| PSCLASSOPTIONS      PROC SUMMARY Class Statement Options.             (Blank)
|                     Valid values: Blank, Valid PROC SUMMARY CLASS 
|                     Options (without the leading '/')
|                     Eg: PRELOADFMT - which can be used in conjunction 
|                     with PSFORMAT and COMPLETETYPES (default in 
|                     PSOPTIONS) to create records for possible 
|                     categories that are specified in a format but 
|                     which may not exist in data being summarised.
|
| PSFORMAT            Passed to the PROC SUMMARY FORMAT statement.      (Blank)
|                     Valid values: Blank. Valid PROC SUMMARY FORMAT 
|                     statement part.
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
|                     Valid values: one or more variable names that
|                     are also defined with COLUMNS
|
| SHARECOLVARS        List of variables that will share print space.    aesoc aept
|                     The attributes of the last variable in the list
|                     define the column width and flow options
|                     Valid values: one or more SAS variable names
|                     AE5 shows an example of this style of output
|                     The formatted values of the variables shall be
|                     written above each other in one column
|
| SHARECOLVARSINDENT  Indentation factor for ShareColVars. Stacked      2
|                     values shall be progressively indented by
|                     multiples of ShareColVarsIndent
|                     Valid values: positive integer
|
| SKIPVARS            Variables whose change in value causes the        aesoc
|                     display to skip a line
|                     Valid values: one or more variable names that
|                     are also defined with COLUMNS
|
| SPLITCHAR           The split character used in column labels. Used   ~
|                     in the creation of the label for the result
|                     columns, and in %tu_stackvar, %tu_display (PROC
|                     REPORT). Usually ~
|
|                     Valid values:
|                     Valid SAS split character.
|
| SPSORTGROUPBYVARSD  Special sort: variables in DSETINDENOM to group   (Blank)
| ENOM                the data by when counting to obtain the
|                     denominator.
|                     Valid values:
|                     Blank if SPSORTRESULTVARNAME is blank
|                     Otherwise,
|                     Blank
|                     _NONE_
|                     Name of a SAS variable that exists in
|                     DSETINDENOM
|
| SPSORTGROUPBYVARSN  Special sort: variables in DSETINNUMER to group   aesoc
| UMER                the data by when counting to obtain the
|                     numerator.
|                     Valid values:
|                     Blank if SPSORTRESULTVARNAME is blank
|                     Otherwise,
|                     Name of one or more SAS variables that exist in
|                     DSETINNUMER
|
| SPSORTRESULTSTYLE   Special sort: the appearance style of the result  pct
|                     data that will be used to sequence the report.
|                     The chosen style will be placed in variable
|                     SPSORTRESULTVARNAME
|                     Valid values:
|                     As documented for tu_percent in [6]. In typical
|                     usage, NUMERPCT.
|
| TIMEINTERVAL        Specify a time span or a list of time span of an  2
|                     interval. If &NUMOFTIMEINTERVALS is not blank 
|                     and only one value are given by &TIMEINTERVAL, a 
|                     list of time spans with &NUMOFTIMEINTERVALS 
|                     numbers with step &TIMEINTERVAL will be created. 
|                     For example, & NUMOFTIMEINTERVALS=4, 
|                     &TIMEINTERVAL=2, the time span will be 2 4 6 8. 
|                     The start point of the time interval is given by 
|                     &TRTSTDT and &TRTSTTM. Any AE event before the 
|                     &TRTSTDT and &TRTSTTM will be deleted 
|                     Valid values: A list of numeric values
|
| TIMEUNIT            Specify a time unit for the time interval         WEEK
|                     Valid:
|                     Minute
|                     Hour
|                     Day
|                     Week
|                     Month
|                     Year
|
| TRTSTDTVAR          Specify a variable name for AE start date         mststdt
|                     Valid Values:
|                     Blank or
|                     Name of a SAS variable that exists in
|                     &DSETINDENOM
|
| TRTSTTMVAR          Specify a variable name for AE start time         (Blank)
|                     Valid Values:
|                     Blank or
|                     Name of a SAS variable that exists in
|                     &DSETINDENOM
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
| WIDTHS              Variables and width to display                    (Blank)
|                     Valid values: values of column names and numeric
|                     widths, a list of variables followed by a
|                     positive integer, e.g.
|
|                     widths = a b 10 c 12 d1-d4 6
|                     Numbered range lists are supported in this
|                     parameter however name range lists, name prefix
|                     lists, and special SAS name lists are not.
|                     Display layout will be optimised by default,
|                     however any specified widths will cause the
|                     default to be overridden
|
|-----------------------------------------------------------------------------------------
| Output: Printed output.
|-----------------------------------------------------------------------------------------
| Global macro variables created: NONE
|
| Macros called:
|(@) tr_putlocals
|(@) tu_abort
|(@) tu_chkvarsexist
|(@) tu_chkvartype
|(@) tu_freq
|(@) tu_nobs
|(@) tu_putglobals
|(@) tu_tidyup
|
|-----------------------------------------------------------------------------------------
| Example:
|    %td_ae6()
|
|-----------------------------------------------------------------------------------------
| Change Log
|
| Modified By:
| Date of Modification:
| New version number:
| Modification ID:
| Reason For Modification:
|
|---------------------------------------------------------------------------------------*/
%MACRO td_ae6(
   ACROSSVAR           =tt_intcd,    /* Variable to transpose the data across to make columns of results. This is passed to the proc transpose ID statement */
   ACROSSVARDECODE     =tt_int,      /* A variable or format used in the construction of labels for the result columns. Usually &g_trtgrp */
   AESTDTVAR           =aestdt,      /* Variable name for AE start date */
   AESTTMVAR           =,            /* Variable name for AE start time */
   BREAK1              =,            /* Break statements */
   BREAK2              =,            /* Break statements */
   BREAK3              =,            /* Break statements */
   BREAK4              =,            /* Break statements */
   BREAK5              =,            /* Break statements */
   BYVARS              =,            /* By variables */
   CENTREVARS          =,            /* Centre justify variables */
   CODEDECODEVARPAIRS  =&g_trtcd &g_trtgrp, /* Code and Decode variables in pairs */
   COLSPACING          =2,           /* Value for between-column spacing */
   COLUMNS             =tt_spsort aesoc summaryLevel tt_pct999 aept ("_Time Since Start of Study Medication_" tt_ac:), /* Columns to be included in the listing (plus spanned headers) */ 
   COMPLETETYPESVARS   =tt_intcd &g_trtcd, /* Variables which COMPLETETYPES should be applied to. */
   COMPUTEBEFOREPAGELINES=TRTMNT $local. : &g_trtgrp, /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt : labelvar) */
   COMPUTEBEFOREPAGEVARS=&g_trtcd, /* Names of variables that define the sort order for  Compute Before Page lines */
   COUNTDISTINCTWHATVAR=&g_centid &g_subjid, /* Variable(s) that contain values to be counted uniquely within any output grouping. Eg &g_subjid */
   DDDATASETLABEL      =DD dataset for AE6 table, /* Label to be applied to the DD dataset */
   DEFAULTWIDTHS       =aesoc 30 aept 30, /* List of default column widths */
   DESCENDING          =tt_spsort tt_pct999, /* Descending ORDERVARS */
   DSETINDENOM         =&g_popdata,  /* Input dataset containing data to be counted to obtain the denominator. */
   DSETINMSTONE        =ardata.mstone, /* Mile stone data set with &TRTSTDTVAR/&TRTSTTMVAR */
   DSETINNUMER         =ardata.ae,   /* Input dataset containing AE data to be counted to obtain the numerator. */
   FLOWVARS            =aesoc aept,  /* Variables with flow option */
   FORMATS             =,            /* Format specification (valid SAS syntax) */
   GROUPBYVARPOP       =&g_trtcd,    /* Variables to group by when counting big N */
   GROUPBYVARSDENOM    =&g_trtcd,    /* Variables in DSETINDENOM to group the data by when counting to obtain the denominator. */
   GROUPBYVARSNUMER    =&g_trtcd &g_trtgrp tt_intcd (aesoc='DUMMY' %nrstr(&sc) aept='ANY EVENT') aesoc (aept='Any event') aept, /* Variables in DSETINNUMER to group the data by when counting to obtain the numerator. */
   GROUPMINMAXVAR      =min(aestdt), /* Specify if frequency of each group should be get from first or last value of a variable in format MIN(variables) */
   IDVARS              =&g_trtcd tt_spsort aesoc summarylevel tt_pct999 aept, /* Variables to appear on each page of the report */
   LABELS              =aept='System Organ Class~   Preferred Term', /* Label definitions (var="var label") */
   LEFTVARS            =,            /* Left justify variables */
   LINEVARS            =,            /* Order variables printed with LINE statements */
   NOPRINTVARS         =tt_spsort summaryLevel tt_pct999, /* No print variables, used to order the display */
   NOWIDOWVAR          =,            /* List of variables whose values must be kept together on a page */
   NUMOFTIMEINTERVALS  =12,          /* Number of time intervals */
   ORDERDATA           =,            /* ORDER=DATA variables */
   ORDERFORMATTED      =,            /* ORDER=FORMATTED variables */
   ORDERFREQ           =,            /* ORDER=FREQ variables */
   ORDERVARS           =&g_trtcd tt_spsort aesoc summaryLevel tt_pct999 aept, /* Order variables */
   PAGEVARS            =,            /* Variables whose change in value causes the display to continue on a new page */
   POSTSUBSET          =%nrstr(if tt_pct999 GT 0 &sc), /* SAS expression to be applied to data immediately prior to creation of the permanent presentation dataset */
   PROPTIONS           =Headline,    /* PROC REPORT statement options */
   PSCLASSOPTIONS      =,            /* PROC SUMMARY CLASS Statement Options */
   PSFORMAT            =,            /* Passed to the PROC SUMMARY FORMAT statement. */
   PSOPTIONS           =COMPLETETYPES MISSING NWAY, /* PROC SUMMARY Options to use */
   RESULTPCTDPS        =0,           /* The reporting precision for percentages Valid values: 0 or any positive integer */
   RESULTSTYLE         =NUMERPCT,    /* The appearance style of the result columns that will be displayed in the report: */
   RIGHTVARS           =,            /* Right justify variables */
   SHARECOLVARS        =aesoc aept,  /* Order variables that share print space */
   SHARECOLVARSINDENT  =2,           /* Indentation factor */
   SKIPVARS            =aesoc,       /* Variables whose change in value causes the display to skip a line */
   SPLITCHAR           =~,           /* The split character used in column labels. */
   SPSORTGROUPBYVARSDENOM=,          /* Special sort: variables in DSETINDENOM to group the data by when counting to obtain the denominator. */
   SPSORTGROUPBYVARSNUMER=aesoc,     /* Special sort: variables in DSETINNUMER to group the data by when counting to obtain the numerator. */
   SPSORTRESULTSTYLE   =pct,         /* Special sort: the appearance style of the result data that will be used to sequence the report. */
   TIMEINTERVAL        =2,           /* Time span of an interval */
   TIMEUNIT            =WEEK,        /* Unit of the time interval */
   TRTSTDTVAR          =mststdt,     /* Variable name for treatment start date */
   TRTSTTMVAR          =,            /* Variable name for treatment start time */
   VARSPACING          =,            /* Column spacing for individual variables */
   WIDTHS              =             /* Column widths */
   );
   %LOCAL MacroVersion;
   %LET MacroVersion = 1;
   %INCLUDE "&g_refdata/tr_putlocals.sas";
   %tu_putglobals()
   %LOCAL 
      l_dataset 
      l_datasets 
      l_dsetindenorm
      l_numofint
      l_i 
      l_i1 
      l_intmax 
      l_j 
      l_j1 
      l_prefix 
      l_rc 
      l_tmp 
      ;
   %LET l_prefix=_tdae6;
   %LET timeunit=%qupcase(&timeunit);
   /*
   / In release 1.0, the HARP Application always assumes that a semicolon in
   / the %macro statement denotes the end of the statement. Therefore, the
   / local macro variable SC has been created to enable the value of the
   / parameter GROUPBYVARSNUMER to include semicolons.
   /--------------------------------------------------------------------------*/
   %LOCAL sc;
   %LET sc = %str(;);
   /*
   / The following assignment statement ensures that if GROUPBYVARSNUMER
   / contains a reference to the macro variable SC, then SC will be resolved
   / *before* tu_freq begins execution. The purpose of this is to ensure that
   / if a local macro variable *or* a parameter of tu_freq is also called
   / SC, then it will not over-ride the macro variable SC that has been defined
   / in this macro (td_ae6).
   /--------------------------------------------------------------------------*/
   %LET groupbyvarsnumer = %unquote(&groupbyvarsnumer);
   %LET postsubset       = %unquote(&postsubset);
   %LET l_dsetinnumer    = &dsetinnumer;
   %IF %nrbquote(&G_ANALY_DISP) EQ D %THEN %GOTO DISPLAYIT;
   
   /*
   / If multiple words in &timeinterval, ignore &numoftimeintervals.
   /--------------------------------------------------------------------------*/
   
   %IF %nrbquote(&timeinterval) ne %THEN %DO;
      %LET l_numofint=%tu_words(&timeinterval);
      
      %IF &l_rc gt 1 %THEN %DO;
         %PUT %str(RTN)OTE: &sysmacroname: Multiple words are found in TIMEINTERVAL. NUMOFTIMEINTERVALS is reset to &l_rc;
         %LET numoftimeintervals=&l_numofint;
      %END;
   %END;
   /*
   / Check if any required parameter is blank.
   /--------------------------------------------------------------------------*/
   %LET l_i=1;
   %LET l_tmp=aestdtvar numoftimeintervals timeinterval timeunit trtstdtvar countdistinctwhatvar;
   %LET l_i1=%scan(&l_tmp, &l_i);
   %DO %WHILE ( %nrbquote(&l_i1) NE );
      %IF %nrbquote(&&&l_i1) EQ  %THEN %DO;
         %PUT %str(RTERR)OR: &sysmacroname: value of parameter &l_i1 is blank.;
         %GOTO macerr;
      %END;
      %LET l_i=%eval(&l_i + 1);
      %LET l_i1=%scan(&l_tmp, &l_i);
   %END;
   /*
   / Check if &TIMEUNIT is valid.
   /--------------------------------------------------------------------------*/
   %IF NOT (( &timeunit EQ YEAR ) OR ( &timeunit EQ MONTH ) OR
            ( &timeunit EQ WEEK ) OR ( &timeunit EQ DAY )   OR
            ( &timeunit EQ HOUR ) OR ( &timeunit EQ MINUTE ) )%THEN %DO;
      %PUT %str(RTERR)OR: &sysmacroname: Value of parameter TIMEUNIT is invalid. The valid value is year, month, week, day, hour, or minute;
      %GOTO macerr;
   %END;
   /*
   / Check if TIMEINTERVAL and NUMOFTIMEINTERVALS is a number.
   /--------------------------------------------------------------------------*/
   %LET l_tmp=numoftimeintervals timeinterval;
   %LET l_rc=0;
   DATA _NULL_;
      LENGTH numvar numvars message $500;
      numvar=resolve(symget("numoftimeintervals"));
      message="Value of NUMOFTIMEINTERVALS";
      LINK check;
      
      message="One value of TIMEINTERVALS";
      numvars=resolve(symget("timeinterval"));
      
      DO i=1 TO &l_numofint;
         numvar=scan(numvars, i, ' ');
         LINK check;
      END;
      
      RETURN;
      
      
   CHECK:  
      IF verify(numvar, '0123456789. ',  '00'x) GT 0 THEN
         numtime=.;
      ELSE
         numtime=input(numvar, best12.3);
      
      IF numtime LE . THEN DO;
         message="RTE"||"RROR: &sysmacroname: "||trim(left(message))||" is not a number." ;
         PUT message;
         CALL SYMPUT('l_rc', '1');
         STOP;
      END;
      ELSE IF numtime LE 0 THEN DO;
         message= "RTE"||"RROR: &sysmacroname: "||trim(left(message))||" is less than or equal to 0." ;
         PUT message;
         CALL SYMPUT('l_rc', '1');
         STOP;
      END;
      RETURN;
  
   RUN;
  
   %IF &l_rc NE 0 %THEN %GOTO macerr;
   
   /*
   / If only one words in &timeinterval, create a list of time intervals
   / based on the value of &numoftimeintervals
   /--------------------------------------------------------------------------*/
   
   %IF &l_numofint eq 1 %THEN %DO;
      %LET l_tmp=;     
      %DO l_i=1 %TO &numoftimeintervals;
         %LET l_tmp=&l_tmp %eval(&timeinterval * &l_i) ;
      %END;
            
      %LET l_numofint=&numoftimeintervals;
      %LET timeinterval=&l_tmp;
   %END;
   /*
   / 1. Check if DSETINNUMER and DSETINMSTONE exist and if they are empty.
   / 2. Check if variabales &countdistinctwhatvar, &aestdtvar and &aesttmvar are
   /    in &DSETINNUMER, and if &aestdtvar and &aesttmvar are numeric variables.
   / 3. If &DSETINMSTONE is blank, check if &trtstdtvar and &trtsttmvar are in
   /    &DSETINNUMER and are are numeric variables.
   / 4. If &DSETINMSTONE is not blank, check if &countdistinctwhatvar, &trtstdtvar
   /    and &trtsttmvar are in it and if &trtstdtvar and &trtsttmvar and are numeric
   /    variables.
   /--------------------------------------------------------------------------*/
   %LET l_i=1;
   
   %IF  %nrbquote(&DSETINMSTONE) eq %THEN %DO;
      %LET l_j1=1;
   %END;
   %ELSE %DO;
      %LET l_j1=2;
   %END;
   %LET l_datasets=&DSETINNUMER &DSETINMSTONE ;
   %DO l_j=1 %TO &l_j1;
   
      %LET l_dataset=%scan(&l_datasets, &l_j, %str( ));                         
      %LET l_rc=%tu_nobs(&l_dataset);
      %IF &g_abort EQ 1 %THEN %GOTO macerr;
      %IF &l_rc EQ -1 %THEN %DO;
         %PUT %str(RTERR)OR: &sysmacroname: input data set "&l_dataset" does not exist;
         %GOTO macerr;
      %END;
      %IF &l_j eq 1 %THEN %DO;
         %LET l_tmp=&aestdtvar &aesttmvar ;
         %IF  %nrbquote(&DSETINMSTONE) eq %THEN %DO;
            %LET l_tmp=&l_tmp &trtstdtvar &trtsttmvar;
         %END;
      %END;
      %ELSE %DO;
         %LET l_tmp=&trtstdtvar &trtsttmvar;
      %END;  /* End-if on L_j is 1 -*/
      %LET l_i1=%scan(&l_tmp, &l_i);
      %DO %WHILE ( %nrbquote(&l_i1) NE );
         %LET l_rc=%tu_chkvarsexist(&l_dataset, &l_i1);
         %IF &g_abort EQ 1 %THEN %GOTO macerr;
         %IF %str(X&l_rc) NE X %THEN %DO;
            %PUT %str(RTERR)OR: &sysmacroname: variables &l_i1 is not in &l_dataset dataset;
            %GOTO macerr;
         %END;
         %IF %tu_chkvartype(&l_dataset, &l_i1) ne N %THEN %DO;
            %PUT %str(RTERR)OR: &sysmacroname: variables &l_i1 in &l_dataset is not a numeric variable;
            %GOTO macerr;
         %END;
         %LET l_i=%eval(&l_i + 1);
         %LET l_i1=%scan(&l_tmp, &l_i);
      %END; /* End of DO-WHILE loop -*/
      %LET l_tmp=&countdistinctwhatvar;
      %LET l_i1=%scan(&l_tmp, &l_i);
      %DO %WHILE ( %nrbquote(&l_i1) NE );
         %LET l_rc=%tu_chkvarsexist(&l_dataset, &l_i1);
         %IF &g_abort EQ 1 %THEN %GOTO macerr;
         %IF %str(X&l_rc) NE X %THEN %DO;
            %PUT %str(RTERR)OR: &sysmacroname: variables &l_i1 given in COUNTDISTINCTWHATVAR is not in &l_dataset dataset;
            %GOTO macerr;
         %END;
         %LET l_i=%eval(&l_i + 1);
         %LET l_i1=%scan(&l_tmp, &l_i);
      %END;  /* End of DO-WHILE on countdistinctwhatvar -*/
   %END; /* End of DO-TO loop on l_j -*/
   /*
   /  Merge &trtstdtvar and &trtsttmvar from &DSETINMSTONE into &DSETINNUMER
   /--------------------------------------------------------------------------*/
   %IF %nrbquote(&DSETINMSTONE) ne %THEN %DO;
      PROC SORT DATA=&DSETINMSTONE OUT=&l_prefix.mstone
           (KEEP=&countDistinctWhatVar &trtstdtvar &trtsttmvar ) NODUPKEY;
         BY &countDistinctWhatVar;
      RUN;
      PROC SORT DATA=&L_DSETINNUMER OUT=&l_prefix.analym;
        BY &countDistinctWhatVar &aestdtvar &aesttmvar;
      RUN;
      DATA &l_prefix.antime;
         MERGE &l_prefix.analym (in=tt_in1)
               &l_prefix.mstone ;
         BY &countDistinctWhatVar;
         IF tt_in1;
      RUN;
      %LET l_dsetinnumer=&l_prefix.antime;
   %END; /*end-if on DSETINMSTONE is not blank -*/
   /*
   / Add interval variables into &DSETINNUMER.
   /--------------------------------------------------------------------------*/
   %LET l_intmax=0;
        
   DATA &l_prefix.antime;  
      LENGTH tt_int $40 tt_intcd 8;
      SET &l_dsetinnumer end=tt_end;
      DROP tt_intst tt_intmax;
      RETAIN tt_intmax 0;
      
      IF missing(&aestdtvar) THEN DO;
         PUT "RTN" "OTE: &sysmacroname: missing &aestdtvar for COUNTDISTINCTVARWHAT=&COUNTDISTINCTWHATVAR.";
         PUT "RTN" "OTE: &sysmacroname: record will be removed";
         tt_inst=-1;
      END;
      ELSE IF missing(&trtstdtvar) THEN DO;
         PUT "RTN" "OTE: &sysmacroname: missing &trtstdtvar for COUNTDISTINCTWHATVAR=&COUNTDISTINCTWHATVAR.";
         PUT "RTN" "OTE: &sysmacroname: record will be removed";     
         tt_inst=-1;
      END;            
      ELSE DO;            
         %IF &timeunit EQ YEAR %THEN %DO;
            tt_intst=yrdif(&trtstdtvar, &aestdtvar);
         %END;
         %ELSE %DO;
            tt_intst=datdif(&trtstdtvar, &aestdtvar, 'act/act');
        
            tt_intst=tt_intst * 24;
            %IF ( %nrbquote(&aesttmvar) NE ) AND ( %nrbquote(&trtsttmvar) NE ) %THEN %DO;
               IF not missing( &aesttmvar) AND not missing( &trtsttmvar ) THEN DO;
                  tt_intst=(&aesttmvar - &trtsttmvar)/3600 + tt_intst;
               END;
            %END;
         %END;
        
         tt_intst=tt_intst ;
        
         %IF &timeunit EQ MONTH %THEN %DO;
            tt_intst=tt_intst / ( 30 * 24 );
         %END;
         %IF &timeunit EQ WEEK %THEN %DO;
            tt_intst=tt_intst / ( 7 * 24 );
         %END;
         %IF &timeunit EQ MINUTE %THEN %DO;
            tt_intst=tt_intst * 60;
         %END;
      END; /* end-if on missing AESTDTVAR */
      IF tt_intst GE 0 THEN DO;
          %DO l_i = 1 %TO %eval(&numoftimeintervals - 1);
             IF tt_intst LT %scan(&timeinterval, &l_i, %str( )) THEN DO;
                tt_intcd=&l_i;
                tt_int="<"||"%scan(&timeinterval, &l_i, %str( )) "||"&timeunit";            
                output;
             END;
          %END;                   
          
          IF tt_intst GE %scan(&timeinterval, &numoftimeintervals, %str( )) THEN
             tt_intcd=&numoftimeintervals;
             
          tt_intmax=max(tt_intmax, tt_intcd);            
          
          tt_intcd=999;
          tt_int=">="||"%scan(&timeinterval, &numoftimeintervals, %str( )) "||"&timeunit";
          output;
                           
      END;
      IF tt_end THEN
         CALL SYMPUT('l_intmax', trim(left(put(tt_intmax, best12.3))));
   RUN;
   %LET L_DSETINNUMER=&l_prefix.antime;
   
   %IF (&l_intmax LT %scan(&timeinterval, &numoftimeintervals, %str( ))) %THEN %DO;
      DATA &l_prefix.vtime;
         SET &l_dsetinnumer;
         IF tt_intcd EQ &l_intmax THEN DELETE;         
         IF tt_intcd EQ 999 THEN 
         %IF &l_intmax GT 1 %THEN %DO;
            tt_int=">="||"%scan(&timeinterval, %eval(&l_intmax - 1), %str( )) "||"&timeunit";         
         %END;
         %ELSE %DO;
            tt_int="<="||"%scan(&timeinterval, 1, %str( )) "||"&timeunit"; 
         %END;         
      RUN;
      %LET l_dsetinnumer=&l_prefix.vtime;
   %END;
   /*
   / Call tu_freq to create display.
   /--------------------------------------------------------------------------*/
%DISPLAYIT:
   %let columns=%unquote(&columns);
   %tu_freq(
      acrossColListName       =acrossColList,
      acrossColVarPrefix      =tt_ac,
      acrossVar               =&acrossVar,
      acrossVarDecode         =&acrossVarDecode,
      addBigNYN               =Y,
      groupminmaxvar          =&groupminmaxvar,
      BigNVarName             =tt_bnnm,
      break1                  =&break1,
      break2                  =&break2,
      break3                  =&break3,
      break4                  =&break4,
      break5                  =&break5,
      byvars                  =&byVars,
      centrevars              =&centreVars,
      codeDecodeVarPairs      =&codeDecodeVarPairs,
      colspacing              =&colSpacing,
      columns                 =&columns,
      completetypesvars       =&completetypesvars,
      computebeforepagelines  =&computeBeforePageLines,
      computebeforepagevars   =&computeBeforePageVars,
      countDistinctWhatVar    =&countDistinctWhatVar,
      dddatasetlabel          =&dddatasetlabel,
      defaultwidths           =&defaultWidths,
      denormYN                =Y,
      descending              =&descending,
      display                 =Y,
      dsetinDenom             =&dsetindenom,
      dsetinNumer             =&l_dsetinNumer,
      dsetout                 =,
      flowvars                =&flowVars,
      formats                 =&formats,
      groupByVarPop           =&groupByVarPop,
      groupByVarsDenom        =&groupByVarsDenom,
      groupByVarsNumer        =&groupByVarsNumer,
      idvars                  =&idVars,
      labels                  =&labels,
      labelvarsyn             =Y,
      leftvars                =&leftVars,
      linevars                =&linevars,
      noprintVars             =&noPrintVars,
      nowidowvar              =&nowidowvar,
      orderdata               =&orderdata,
      orderformatted          =&orderformatted,
      orderfreq               =&orderfreq,
      ordervars               =&ordervars,
      overallsummary          =Y,
      pagevars                =&pageVars,
      postSubset              =&postSubset,
      proptions               =&proptions,
      psByvars                =,
      psClass                 =,
      psClassOptions          =&psclassoptions,
      psFormat                =&psformat,
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
      rightVars               =&rightVars,
      rowLabelVarName         =,
      sharecolvars            =&sharecolvars,
      sharecolvarsindent      =&sharecolvarsindent,
      skipvars                =&skipVars,
      splitChar               =&splitChar,
      spSortGroupByVarsDenom  =&spSortGroupByVarsDenom,
      spSortGroupByVarsNumer  =&spSortGroupByVarsNumer,
      spSortResultStyle       =&spSortResultStyle,
      spSortResultVarName     =tt_spsort,
      stackvar1               =,
      stackvar2               =,
      stackvar3               =,
      stackvar4               =,
      stackvar5               =,
      stackvar6               =,
      stackvar7               =,
      stackvar8               =,
      stackvar9               =,
      stackvar10              =,
      stackvar11              =,
      stackvar12              =,
      stackvar13              =,
      stackvar14              =,
      stackvar15              =,
      summaryLevelVarName     =summaryLevel,
      totalDecode             =,
      totalForVar             =,
      totalID                 =,
      varlabelstyle           =SHORT,
      varspacing              =&varSpacing,
      varsToDenorm            =tt_result tt_pct,
      widths                  =&widths
      )
   %GOTO endmac;
%MACERR:
   %LET g_abort=1;
   %PUT;
   %PUT %str(RTNO)TE: --------------------------------------------------------;
   %PUT %str(RTNO)TE: &sysmacroname completed with error(s);
   %PUT %str(RTNO)TE: --------------------------------------------------------;
   %PUT;
   %IF &g_debug NE 0 %THEN %GOTO ENDMAC;
   %tu_abort(OPTION=FORCE)
%ENDMAC:
   /*
   / Call tu_tideup to clear temporary data set and fiels.
   /--------------------------------------------------------------------------*/
   %tu_tidyup(
      RMDSET =&L_PREFIX:,
      GLBMAC =NONE
      )
%MEND td_ae6;
