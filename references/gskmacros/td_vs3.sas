/*
|
| Macro Name:    td_vs3
|
| Macro Version: 2
|
| SAS Version:   8
|
| Created By:    John Henry King
|
| Date:          24Nov2003
|
| Macro Purpose: A macro to produce vital signs data summary vs3.
|
| Macro Design:  Procedure style.
|
| Input Parameters:
|
|
| Name                Description                                       Default
| ----------------------------------------------------------------------------------------
| ACROSSVAR           Variable to transpose the data across to make     &g_trtcd
|                     columns of results. This is passed to the proc
|                     transpose ID statement hence the values of this
|                     variable will be used to name the new columns.
|                     Typically this will be the code variable
|                     containing treatment.
|                     Valid Values:
|                     Blank
|                     Name of a SAS variable that exists in
|                     DSETINNUMER
|
| ACROSSVARDECODE     A variable or format used in the construction of  &g_trtgrp
|                     labels for the result columns.
|                     Valid values:
|                     If DENORMYN is not Y, blank
|                     Otherwise:
|                     Blank
|                     Name of a SAS variable that exists in
|                     DSETINNUMER
|                     An available SAS format
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
|                     Valid values: one or more SAS variable names
|                     No formatting of the display for these variables
|                     is performed by %tu_display.  The user has the
|                     option of the standard SAS BY line, or using
|                     OPTIONS NOBYLINE and #BYVAL #BYVAR directives in
|                     title statements
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
| COLSPACING          The value of the between-column spacing           2
|                     Valid values: positive integer
|
| COUNTDISTINCTWHATV  Variable(s) that contain values to be counted     &g_centid
| AR                  uniquely within any output grouping.              &g_subjid
|                     Valid values:
|                     Blank
|                     Name of one or more SAS variables that exists in
|                     DSETINNUMER
|
| COMPLETETYPESVARS   Passed to %tu_statswithtotal. Specify a list of   _ALL_             
|                     variables which are in GROUPBYVARSANALY and the                     
|                     COMPLETETYPES given by PSOPTIONS should be                          
|                     applied to. If it equals _ALL_, all variables in                    
|                     GROUPBYVARSANALY will be included.                                  
|                     Valid values:                                                       
|                     _ALL_                                                               
|                     A list of variable names which are in                               
|                     GROUPBYVARSANALY                                                    
|                                                                                         
| DESCENDING          List of ORDERVARS that are given the PROC REPORT  (blank)
|                     define statement attribute DESCENDING
|                     Valid values: one or more variable names that
|                     are also defined with ORDERVARS
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
| IDVARS              Variables to appear on each page if the report    (Blank)
|                     is wider than 1 page. If no value is supplied to
|                     this parameter then all displayable order
|                     variables will be defined as IDVARS
|                     Valid values: one or more variable names that
|                     are also defined with COLUMNS
|
| LABELS              Variables and their label for display. For use
|                     where label for display differs to the label the
|                     display dataset.
|                     Valid values: pairs of variable names and labels
|
| LEFTVARS            Variables to be displayed as left justified       (Blank)
|                     Valid values: one or more variable names that
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
| NOWIDOWVAR          Variable whose values must be kept together on a  (Blank)
|                     page
|                     Valid values: names of one or more variables
|                     specified in COLUMNS
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
| PAGEVARS            Variables whose change in value causes the        (Blank)
|                     display to continue on a new page
|                     Valid values: one or more variable names that
|                     are also defined with COLUMNS
|
| PROPTIONS           PROC REPORT statement options to be used in       Headline
|                     addition to MISSING
|                     Valid values: proc report options
|                     The option Missing can not be overridden
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
| PSFORMAT            Passed to the PROC SUMMARY FORMAT statement.      &g_trtcd &g_trtfmt
|                     Valid Values:
|                     Blank
|                     Valid PROC SUMMARY FORMAT statement part.
|
| PSCLASSOPTIONS      PROC SUMMARY Class Statement Options.             preloadfmt
|                     Valid Values:
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
| SHARECOLVARSINDENT  Indentation factor for ShareColVars. Stacked      2
|                     values shall be progressively indented by
|                     multiples of ShareColVarsIndent
|                     Valid values: positive integer
|
| SPLITCHAR           The split character used in column labels. Used   ~
|                     in the creation of the label for the result
|                     columns, and in %tu_stackvar, %tu_display (PROC
|                     REPORT). Usually
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
| TOTALDECODE         Label for the total result column. Usually the    (Blank)
|                     text Total
|                     Valid values:
|                     Blank
|                     SAS data step expression resolving to a
|                     character.
|
| TOTALFORVAR         Variable for which total is required within all   (Blank)
|                     other grouped classvars (usually trtcd). If not
|                     specified, no total will be produced
|                     Valid values: Blank if TOTALID is blank.
|
| TOTALID             Value used to populate the variable specified in  (Blank)
|                     ACROSSVAR on data that represents the overall
|                     total for the ACROSSVAR variable.
|                     If no value is specified to this parameter then
|                     no overall total of the ACROSSVAR variable will
|                     be generated.
|                     Valid values
|                     Blank
|                     A value that can be entered into &ACROSSVAR
|                     without SAS error or truncation
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
| VSPREFIX            List of VS variable name prefix values.  This     Sys dia hr
|                     parameter selects the vital signs variable sets
|                     to analyze.  See the IDSL meta data for the most
|                     current list of prefixes.
|
| CCCD                Specifies the suffix for the indicator code       cccd
|                     variables.
|
| CCHI                Specifies the suffix for the high range           Cchi
|                     variables.
|
| CCIND               Specifies the suffix for the indicator text       Ccind
|                     variables.
|
| CCLO                Specifies the suffix for the low range            Cclo
|                     variables.
|
| STDBL               Specifies the suffix for the baseline             Stdbl
|
| CHANGECATEGORYFORM  Specifies a format to use to format the vaues of  $vs3fmt.
| AT                  the change categories.
|
| CHANGECATEGORYINFO  Specifies a informat to use to group the change   $vs3inf.
| RMAT                indicator codes.  HH, LL, NN etc.
|
| CODEDECODEVARPAIRS  Specifies code and decode variable pairs. Those   &g_trtcd
|                     variables should be in parameter                  &g_trtgrp
|                     GROUPBYVARSNUMER. One variable in the pair will   vstestcd vstest
|                     contain the code and the other will contain       visitnum visit
|                     decode.
|                     Valid values:  Blank or a list of SAS variable
|                     names in pairs that are given in
|                     GROUPBYVARSNUMER
|
| COLUMNS             A PROC REPORT column statement specification.     Vstestcd vstest
|                     Including spanning titles and variable names      summaryLevel
|                     Valid values: one or more variable names plus     _change_category
|                     other elements of valid PROC REPORT COLUMN        tt_ac:
|                     statement syntax
|
| COMPUTEBEFOREPAGEL  See Unit Specification for HARP Reporting Tools   VISIT $local. :
| INES                TU_LIST[5] for complete details                   visit
|
| COMPUTEBEFOREPAGEV  See Unit Specification for HARP Reporting Tools   Visitnum
| ARS                 TU_LIST[5] for complete details
|
| DDDATASETLABEL      Specifies the label to be applied to the DD       DD dataset for
|                     dataset                                           VS3 table
|                     Valid values: a non-blank text string
|
| DEFAULTWIDTHS       Specifies column widths for all variables not     _change_category
|                     listed in the WIDTHS parameter                    45
|                     Valid values: values of column names and numeric
|                     widths such as form valid syntax for a SAS
|                     LENGTH statement
|                     For variables that are not given widths through
|                     either the WIDTHS or DEFAULTWIDTHS parameter
|                     will be width optimised using:
|                     MAX (variables format width,
|                     width of  column header)
|
| DSETIN              Specifies the input SAS data set.                 ardata.vitals
|
| FLOWVARS            Variables to be defined with the flow option      Vstest
|                     Valid values: one or more variable names that     _change_category
|                     are also defined with COLUMNS
|                     Flow variables should be given a width through
|                     the WIDTHS.  If a flow variable does not have a
|                     width specified, the column width will be
|                     determined by
|                     MIN(variables format width,
|                     width of  column header)
|
| FORMATS             Variables and their format for display.           _change_category
|                     Valid values: values of column names and formats  $vs3fmt.
|                     such as form valid syntax for a SAS FORMAT
|                     statement
|
| GROUPBYVARSDENOM    Variables in DSETINDENOM to group the data by     &g_trtcd vstestcd
|                     when counting to obtain the denominator.          visitnum visit
|                     Valid values:
|                     Blank, _NONE_ (to request an overall total for
|                     the whole dataset)
|                     Name of a SAS variable that exists in
|                     DSETINDENOM
|
| GROUPBYVARSNUMER    Variables in DSETINNUMER to group the data by,    %nrstr (&g_trtcd
|                     along with ACROSSVAR, when counting to obtain     &g_trtgrp
|                     the numerator. Additionally a set of brackets     vstestcd vstest
|                     may be inserted within the variables to generate  visitnum visit
|                     records containing summary counts grouped by      (_change_category=
|                     variables specified to the left of the brackets.  'n')
|                     Summary records created may be populated with     _change_category)
|                     values in the grouping variables by specifying
|                     variable value pairs within brackets, seperated
|                     by semi colons. Eg aesoccd aesoc(aeptcd=0;
|                     aept='Any Event';) aeptcd aept.
|                     Valid values:
|                     Blank
|                     Name of one or more SAS variables that exist in
|                     DSETINNUMER
|                     SAS assignment statements within brackets
|
| NOPRINTVARS         Variables listed in the COLUMN parameter that     Vstestcd visitnum
|                     are given the PROC REPORT define statement        summaryLevel
|                     attribute noprint
|                     Valid values: one or more variable names that
|                     are also defined with COLUMNS
|                     These variables are ORDERVARS used to control
|                     the order of the rows in the display
|
| ORDERDATA           Variables listed in the ORDERVARS parameter that  _change_category
|                     are given the PROC REPORT define statement        vstestcd
|                     attribute order=data
|                     Valid values: one or more variable names that
|                     are also defined with ORDERVARS
|                     Variables not listed in ORDERFORMATTED,
|                     ORDERFREQ, or ORDERDATA are given the define
|                     attribute order=internal
|
| ORDERVARS           List of variables that will receive the PROC      SummaryLevel
|                     REPORT define statement attribute ORDER
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
| SHARECOLVARS        List of variables that will share print space.    Vstest
|                     The attributes of the last variable in the list   _change_category
|                     define the column width and flow options
|                     Valid values: one or more SAS variable names
|                     AE5 shows an example of this style of output
|                     The formatted values of the variables shall be
|                     written above each other in one column
|
| SKIPVARS            Variables whose change in value causes the        Vstest
|                     display to skip a line
|                     Valid values: one or more variable names that
|                     are also defined with COLUMNS
|
|----------------------------------------------------------------------------------------
|
| Output: Printed output.
|
| Global macro variables created: NONE
|
|
| Macros called:
|
|(@) tr_putlocals
|(@) tu_putglobals
|(@) tu_freq
|(@) tu_tidyup
|(@) tu_abort
|(@) tu_chkvarsexist
|(@) tu_quotelst
|
| Example:
|    %td_vs3()
|
|----------------------------------------------------------------------------------------
| Change Log
|
| Modified By:             Yongwei Wang
| Date of Modification:    26-May-2004
| New version number:      1/2
| Modification ID:         YW001
| Reason For Modification: Added the modification of POSTSUBSETBACK because the
|                          new version of TU_FREQ is on hold
|
|----------------------------------------------------------------------------------------
| Modified By:             Yongwei Wang
| Date of Modification:    26-May-2004
| New version number:      1/3
| Modification ID:         YW002
| Reason For Modification: -Changed 'visit' to 'VISIT' in &COMPUTEBEFOREPAGELINES
|                          -Removed duplicate FORMATS and ORDERDATA in parameters.
|
|----------------------------------------------------------------------------------------
| Modified By:              Yongwei Wang
| Date of Modification:     24-Mar-2005
| New version number:       2/1
| Modification ID:          YW001
| Reason For Modification:  Make PSFORMAT and PSCLASSOPTIONS available to be editable by 
|                           the user and passed through to tu_freq. Set default value for 
|                           PSFORMAT to be &g_trtcd &g_trtfmt And default for PSCLASSOPTIONS
|                           TO BE PRELOADFMT. Required by Change Request HRT0056.
|                           Added new parameter COMPLETETYPESVARS.
|----------------------------------------------------------------------------------------
| Modified By:
| Date of Modification:
| New version number:
| Modification ID:
| Reason For Modification:
|
|----------------------------------------------------------------------------------------*/

%macro td_vs3 (
   ACROSSVAR           =&g_trtcd,          /* Variable to transpose the data across to make columns of results. This is passed to the proc transpose ID statement */
   ACROSSVARDECODE     =&g_trtgrp,         /* A variable or format used in the construction of labels for the result columns. Usually &g_trtgrp */
   BREAK1              =,                  /* Break statements */
   BREAK2              =,                  /* Break statements */
   BREAK3              =,                  /* Break statements */
   BREAK4              =,                  /* Break statements */
   BREAK5              =,                  /* Break statements */
   BYVARS              =,                  /* By variables */
   CCCD                =cccd,              /* Suffix name of indicator code */
   CCHI                =Cchi,              /* Suffix name for high range */
   CCIND               =Ccind,             /* Suffix name of indicator text */
   CCLO                =Cclo,              /* Suffix name for low range */
   CENTREVARS          =,                  /* Centre justify variables */
   CHANGECATEGORYFORMAT=$vs3fmt.,          /* Name of change category format */
   CHANGECATEGORYINFORMAT=$vs3inf.,        /* Name of change category informat */
   CODEDECODEVARPAIRS  =&g_trtcd &g_trtgrp vstestcd vstest visitnum visit, /* Code and Decode variables in pairs */
   COLSPACING          =2,                 /* Value for between-column spacing */
   COLUMNS             =Vstestcd vstest summaryLevel _change_category tt_ac:, /* Columns to be included in the listing (plus spanned headers) */
   COMPLETETYPESVARS   =_all_,             /* Variables which COMPLETETYPES should be applied to */ 
   COMPUTEBEFOREPAGELINES=VISIT $local. : visit, /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt : labelvar) */
   COMPUTEBEFOREPAGEVARS=Visitnum,         /* Names of variables that define the sort order for  Compute Before Page lines */
   COUNTDISTINCTWHATVAR=&g_centid &g_subjid, /* Variable(s) that contain values to be counted uniquely within any output grouping. Eg &g_subjid */
   DDDATASETLABEL      =DD dataset for VS3 table, /* Label to be applied to the DD dataset */
   DEFAULTWIDTHS       =_change_category 45, /* List of default column widths */
   DESCENDING          =,                  /* Descending ORDERVARS */
   DSETIN              =ardata.vitals,     /* Input Lab Data */
   FLOWVARS            =Vstest _change_category, /* Variables with flow option */
   FORMATS             =_change_category $vs3fmt., /* Format specification (valid SAS syntax) */
   GROUPBYVARPOP       =&g_trtcd,          /* Variables to group by when counting big N */
   GROUPBYVARSDENOM    =&g_trtcd vstestcd visitnum visit, /* Variables in DSETINDENOM to group the data by when counting to obtain the denominator. */
   GROUPBYVARSNUMER    =%nrstr (&g_trtcd &g_trtgrp vstestcd vstest visitnum visit (_change_category='n') _change_category), /* Variables in DSETINNUMER to group the data by when counting to obtain the numerator. */
   IDVARS              =,                  /* Variables to appear on each page of the report */
   LABELS              =,                  /* Label definitions (var=var label) */
   LEFTVARS            =,                  /* Left justify variables */
   LINEVARS            =,                  /* Order variables printed with LINE statements */
   NOPRINTVARS         =Vstestcd visitnum summaryLevel, /* No print variables, used to order the display */
   NOWIDOWVAR          =,                  /* List of variables whose values must be kept together on a page */
   ORDERDATA           =_change_category vstestcd, /* ORDER=DATA variables */
   ORDERFORMATTED      =,                  /* ORDER=FORMATTED variables */
   ORDERFREQ           =,                  /* ORDER=FREQ variables */
   ORDERVARS           =SummaryLevel,      /* Order variables */
   PAGEVARS            =,                  /* Variables whose change in value causes the display to continue on a new page */
   POSTSUBSET          =,                  /* SAS expression to be applied to data immediately prior to creation of the permanent presentation dataset */
   PROPTIONS           =Headline,          /* PROC REPORT statement options */
   PSCLASSOPTIONS      =preloadfmt,        /* PROC SUMMARY CLASS Statement Options */
   PSFORMAT            =&g_trtcd &g_trtfmt,/* Passed to the PROC SUMMARY FORMAT statement. */
   PSOPTIONS           =COMPLETETYPES MISSING NWAY, /* PROC SUMMARY Options to use */
   RESULTPCTDPS        =0,                 /* The reporting precision for percentages Valid values: 0 or any positive integer */
   RESULTSTYLE         =NUMERPCT,          /* The appearance style of the result columns that will be displayed in the report */
   RIGHTVARS           =,                  /* Right justify variables */
   SHARECOLVARS        =Vstest _change_category, /* Order variables that share print space */
   SHARECOLVARSINDENT  =2,                 /* Indentation factor */
   SKIPVARS            =Vstest,            /* Variables whose change in value causes the display to skip a line */
   SPLITCHAR           =~,                 /* The split character used in column labels. */
   SPSORTGROUPBYVARSDENOM=,                /* Special sort: variables in DSETINDENOM to group the data by when counting to obtain the denominator. */
   STDBL               =Stdbl,             /* Suffix name for baseline value */
   TOTALDECODE         =,                  /* Label for the total result column. Usually the text Total */
   TOTALFORVAR         =,                  /* Variable for which a total is required, usually trtcd */
   TOTALID             =,                  /* Value used to populate the variable specified in ACROSSVAR on data that represents the overall total for the ACROSSVAR variable. */
   VARSPACING          =,                  /* Column spacing for individual variables */
   VSPREFIX            =Sys dia hr,        /* List of VS prefix values */
   WIDTHS              =                   /* Column widths */
   );

   /*
   / Echo the macro name and version to the log. Also echo the parameter values
   / and values of global macro variables used by this macro.
   /---------------------------------------------------------------------------*/

   %local MacroVersion;
   %let MacroVersion = 2;

   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals(varsin=g_subset)

   %local l_prefix sc l_vlen;
   %let l_vlen=0;
   %let l_prefix=_vs3;

   /*
   / formats are defaults so create them
   /-----------------------------------------*/
   proc format;
      invalue $vs3inf(just upcase)
         'HL','NL' = '1'
         'NN','HN','LN','LL','HH' = '2'
         'NH','LH' = '3'
         other = .
         ;
      value $vs3fmt
         '1' = 'To Low'
         '2' = 'To Normal or No Change'
         '3' = 'To High'
         ;
      run;

   /*
   /  IF GD_ANALY_DISPLAY is D, goto display.
   /--------------------------------------------------------*/

   %if %nrbquote(&G_ANALY_DISP) = D %then %goto DISPLAYIT;

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
   / Check range variables are not blank
   /---------------------------------------------*/
   %if    %nrbquote(&cccd)  EQ
       OR %nrbquote(&cclo)  EQ
       OR %nrbquote(&cchi)  EQ
       OR %nrbquote(&stdbl) EQ
       OR %nrbquote(&ccind) EQ %then
   %do;
      %let g_abort = 1;
      %put %str(RTER)ROR: &sysmacroname: At Least one of the parameters VSPREFIX, CCCD, CCLO, CCHI, CCIND, STDBL is blank.;
      %put %str(RTER)ROR: &sysmacroname: vsprefix=&vsprefix;
      %put %str(RTER)ROR: &sysmacroname: cccd=&cccd;
      %put %str(RTER)ROR: &sysmacroname: cclo=&cclo;
      %put %str(RTER)ROR: &sysmacroname: cchi=&cchi;
      %put %str(RTER)ROR: &sysmacroname: ccind=&ccind;
      %put %str(RTER)ROR: &sysmacroname: stdbl=&stdbl;
   %end;


   /*
   / Create variable name lists from vsprefix
   /----------------------------------------------------------------------------*/
   %local
      cccd_list  /* */
      ccind_list /* */
      cclo_list  /* */
      cchi_list  /* */
      stdbl_list /* */
      i          /* */
      w          /* */
      vsRangeHighVarname                    /* Variable name of High Range Values */
      vsRangeIndCodeVarname                 /* Variable name of VS Indicator Code Values */
      vsRangeIndVarname                     /* Variable name of VS Indicator Text Values */
      vsRangeLowVarname                     /* Variable name of Low Range Values */
      vsBaslineVarname                      /* Variable name of Baseline Values */

      vsTestCDVarName                       /* Variable name of VS Test Code */
      vsTestVarname                         /* Variable name of VS Test (long text) */
      vsSTDBLvarname                        /* Variable name of Baseline value */
      ;

   %let vsRangeHighVarname       = vsccHI;              /* Variable name of High Range Values */
   %let vsRangeIndCodeVarname    = vsccCD;              /* Variable name of VS Indicator Code Values */
   %let vsRangeIndVarname        = vsccIND;             /* Variable name of VS Indicator Text Values */
   %let vsRangeLowVarname        = vsccLO;              /* Variable name of Low Range Values */
   %let vsBaslineVarname         = vsstdBL;             /* Variable name of Baseline Values */
   %let vsTestCDVarName          = vsTestCD;            /* Variable name of VS Test Code */
   %let vsTestVarname            = vstest;              /* Variable name of VS Test (long text) */
   %let vsSTDBLvarname           = vsstdbl;             /* Variable name of Baseline value */


   %let i = 1;
   %let w = %scan(&vsprefix,&i,%str( ));
   %do %while(%quote(&w) NE );
      %if %quote(&cccd)  NE %then %let cccd_list  = &cccd_list &w.&cccd;
      %if %quote(&ccind) NE %then %let ccind_list = &ccind_list &w.&ccind;
      %if %quote(&cclo)  NE %then %let cclo_list  = &cclo_list &w.&cclo;
      %if %quote(&cchi)  NE %then %let cchi_list  = &cchi_list &w.&cchi;
      %if %quote(&stdbl) NE %then %let stdbl_list = &stdbl_list &w.stdbl;
      %let i = %eval(&i+1);
      %let w = %scan(&vsprefix,&i,%str( ));
      %end;

   /*
   / Check range variables exist in input data
   /------------------------------------------------------*/
   %local allvars donotexist;
   %let allvars    = &cccd_List &cclo_list &cchi_list &ccind_list &stdbl_list;
   %let donotexist = %tu_chkvarsexist(&dsetin,&allvars);
   %if %nrbquote(&donotexist) NE %then
   %do;
      %let g_abort = 1;
      %put %str(RTER)ROR: &sysmacroname: Variable(s) "&donotexist" not found in input data &dsetin;
   %end;

   %if &g_abort EQ 1 %then %goto macerr;

   %let sc = %str(;);
   %let groupByVarsNumer   = %unquote(&groupByVarsNumer);
   %let postSubset         = %unquote(&postSubset);

   /*
   / Create work data set with extra visit for any visit post baselin
   /-------------------------------------------------------------------*/
   data work.&l_prefix._visit1;
      set
         &dsetin
         ;
      if not missing(visit);
      array _name[*]  $8 &vsprefix(%tu_quotelst(&vsprefix));
      array _cccd[*]  &cccd_list;
      array _ccind[*] &ccind_list;
      array _cclo[*]  &cclo_list;
      array _cchi[*]  &cchi_list;
      array _stdbl[*] &stdbl_list;
      drop _i_ &cccd_list &ccind_list &cclo_list &cchi_list &stdbl_list &vsprefix;

      length &vsTestCDVarname $32 &vstestvarname $90;
      do _i_ = 1 to dim(_name);
         /*
         / Use variable names from &VSprefix to create ID variables for the
         / vital signs variables.
         /--------------------------------------------------------------------*/
         &vstestVarname          = tranwrd(vlabel(_cccd[_i_]),'Flag',' ');
         &vsTestCDVarname        = _i_;

         /*
         / Assign Range related variables
         /-------------------------------------------------*/
         &vsRangeIndCodeVarname  = _cccd[_i_];
         &vsRangeIndVarname      = _ccind[_i_];
         &vsRangeLowVarname      = _cclo[_i_];
         &vsRangeHighVarname     = _cchi[_i_];
         &vsBaslineVarname       = _stdbl[_i_];
         output;
      end;
   run;

   /*
   / Create work data set with extra visit for any visit post baselin
   /-------------------------------------------------------------------*/
   data work.&l_prefix._visit2;
      set work.&l_prefix._visit1;
      %if %nrbquote(&g_subset) NE %then
      %do;
         where %unquote(&g_subset);
      %end;

      array _c[*] _character_;
      do _i_ = 1 to dim(_c);
         _c[_i_] = left(_c[_i_]);
         end;
      drop _i_;

      if missing(&vsstdblvarname) then delete;

      if not missing(&vsstdblvarname) then
      do;
         if      &vsstdblvarname LT &vsRangeLowVarname  then _baseline_cccd = 'L';
         else if &vsstdblvarname GT &vsRangeHighVarname then _baseline_cccd = 'H';
         else                                                _baseline_cccd = 'N';
      end;

      length _change_cccd $2;
      if not missing(vscccd) & not missing(_baseline_cccd)
         then _change_cccd = substr(_baseline_cccd,1,1)||substr(vscccd,1,1);

      _change_category = input(_change_cccd,&changeCategoryInformat);

      label
         _change_category = 'Change Category'
         _change_cccd     = 'Range indicator with baseline'
         _baseline_cccd   = 'Baseline range indicator'
         ;
      format _change_category &changecategoryformat;
      run;

   %if &syserr GT 0 %then
   %do;
      %put %str(RTER)ROR: &sysmacroname: DATA STEP ended with a non-zero return code.;
      %goto macerr;
   %end;


   /*
   / The following steps determine if the ranges have missing ends.
   / Typically some parameters have a value above which is of
   / clinical concern but do not have a low value of clinical concern.
   / These conditions are determined by examination of the range values,
   / and removed from the display using POSTSUBSET.
   /---------------------------------------------------------------------*/

   proc summary data=work.&l_prefix._visit2 nway missing;
      class &vsTestVarName;
      var &vsRangeLowVarname &vsRangeHighVarname;
      output out = work.&l_prefix._unique
             max = ;
      run;
   %if &syserr GT 0 %then
   %do;
      %put %str(RTER)ROR: &sysmacroname: PROC SUMMARY ended with a non-zero return code.;
      %goto macerr;
   %end;

   data _null_;
      set work.&l_prefix._unique end=eof;
      length string $10000 text text1 text2 $500 postsubset $10000;
      retain string;
      retain firstflag 1;

      if &vsRangeLowVarname  LE 0 then text1 = "(&vsTestVarName='"||trim(&vsTestVarName)||"' and _change_category='1')";
      if &vsRangeHighVarname LE 0 then text2 = "(&vsTestVarName='"||trim(&vsTestVarName)||"' and _change_category='3')";

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

   /*
   / More post subset code:  Remove extra records create by COMPLETETYPE that I
   / dont really want.  I need to learn how to get these from TU_FREQ without the
   / extra records.
   / Also remove summary level one percent signs.
   / YW001: Added back
   /-------------------------------------------------------------------------------*/
   %local morePostSubset;
   %let morePostSubset = %nrstr(if  summaryLevel eq 1 and sum(of tt_pct:) LE 0 then delete;);
   %let morePostSubset = &morePostSubset.%nrstr(array _x[*] tt_ac:;drop _i_;);
   %let morePostSubset = &morePostSubset.%nrstr(if summaryLevel eq 1 then do _i_ = 1 to dim(_x););
   %let morePostSubset = &morePostSubset.%nrstr(if indexc(_x[_i_],'(') then substr(_x[_i_],indexc(_x[_i_],'(')) = '          ';);
   %let morePostSubset = &morePostSubset.%nrstr(end;);
   %let postsubset = %unquote(&postsubset &morepostsubset);

   %put %str(RTN)OTE: &sysmacroname: Macro parameter POSTSUSBET has been modified;
   %put %str(RTN)OTE: &sysmacroname: POSTSUBSET=%nrbquote(&postsubset);

%DISPLAYIT:

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
         dsetinDenom             = work.&l_prefix._visit2,
         dsetinNumer             = work.&l_prefix._visit2,
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
         spSortGroupByVarsDenom  = &spSortGroupByVarsDenom,
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
      );

 %goto exit;

 %macerr:
   %put %str(RTE)RROR: &sysmacroname: Ending with error(s);
   %let g_abort = 1;
   %tu_abort()

 %exit:
   %tu_tidyup(rmdset=&l_prefix.:,glbmac=NONE);
   %put %str(RTN)OTE: &sysmacroname: ending execution.;

%mend td_vs3;
