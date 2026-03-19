/*
|
| Macro Name:       td_lb4
|
| Macro Version:    2
|
| SAS Version:      8
|
| Created By:       John Henry King
|
| Date:             20Nov2003
|
| Macro Purpose:    A macro to produce lab data summary lb4.
|
| Macro Design: Procedure style.
|
| Input Parameters:
|
|
| Name                Description                                       Default 
| ----------------------------------------------------------------------------------------
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
| DESCENDING          List of ORDERVARS that are given the PROC REPORT  (blank) 
|                     define statement attribute DESCENDING 
|                     Valid values: one or more variable names that 
|                     are also defined with ORDERVARS 
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
| LABELS              Variables and their label for display. For use    (Blank)
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
| TOTALFORVAR         Variable for which total is required within all   (Blank)
|                     other grouped classvars (usually trtcd). If not 
|                     specified, no total will be produced
|                     Valid values: Blank if TOTALID is blank.
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
| ACROSSVAR           Variable to transpose the data across to make     lbnrcd
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
| ACROSSVARDECODE     A variable or format used in the construction of  lbnrind 
|                     labels for the result columns.
|                     Valid values: 
|                     If DENORMYN is not Y, blank 
|                     Otherwise:
|                     Blank 
|                     Name of a SAS variable that exists in 
|                     DSETINNUMER 
|                     An available SAS format 
| 
| CODEDECODEVARPAIRS  Specifies code and decode variable pairs. Those   &g_trtcd
|                     variables should be in parameter                  &g_trtgrp 
|                     GROUPBYVARSNUMER. One variable in the pair will   lbtestcd lbtest 
|                     contain the code and the other will contain       visitnum visit
|                     decode.                                           _baseline_cd
|                     Valid values:  Blank or a list of SAS variable    _baseline_ind 
|                     names in pairs that are given in                  lbnrcd lbnrind
|                     GROUPBYVARSNUMER
| 
| COLUMNS             A PROC REPORT column statement specification.     visitnum visit
|                     Including spanning titles and variable names      tt_denomcnt1
|                     Valid values: one or more variable names plus     _baseline_cd
|                     other elements of valid PROC REPORT COLUMN        _baseline_ind 
|                     statement syntax                                  ('Time Period 
|                                                                       Normal Range
|                                                                       Value' '--' 
|                                                                       tt_ac:) 
| 
| COMPUTEBEFOREPAGEL  See Unit Specification for HARP Reporting Tools   %unquote(LBTEST 
| INES                TU_LIST[5] for complete details                   $local. : lbtest
|                                                                       TRTMNT $local. :
|                                                                       &g_trtgrp)
| 
| COMPUTEBEFOREPAGEV  See Unit Specification for HARP Reporting Tools   %unquote(lbtestcd 
| ARS                 TU_LIST[5] for complete details                   &g_trtcd) 
| 
| DDDATASETLABEL      Specifies the label to be applied to the DD       DD dataset for
|                     dataset                                           LB4 table 
|                     Valid values: a non-blank text string 
| 
| DEFAULTWIDTHS       Specifies column widths for all variables not     visit 10
|                     listed in the WIDTHS parameter                    _baseline_ind 8 
|                     Valid values: values of column names and numeric  tt_denomcnt1 4
|                     widths such as form valid syntax for a SAS
|                     LENGTH statement
|                     For variables that are not given widths through 
|                     either the WIDTHS or DEFAULTWIDTHS parameter
|                     will be width optimised using:
|                     MAX (variables format width, 
|                     width of  column header)
| 
| DSETIN              Specifies the input SAS data set.                 ardata.lab 
| 
| FLOWVARS            Variables to be defined with the flow option      visit 
|                     Valid values: one or more variable names that     _baseline_ind 
|                     are also defined with COLUMNS                     
|                     Flow variables should be given a width through
|                     the WIDTHS.  If a flow variable does not have a 
|                     width specified, the column width will be 
|                     determined by 
|                     MIN(variables format width,
|                     width of  column header)
| 
| GROUPBYVARSDENOM    Variables in DSETINDENOM to group the data by     Lbtestcd &g_trtcd 
|                     when counting to obtain the denominator.          visitnum
|                     Valid values: 
|                     Blank, _NONE_ (to request an overall total for
|                     the whole dataset)
|                     Name of a SAS variable that exists in 
|                     DSETINDENOM 
| 
| GROUPBYVARSNUMER    Variables in DSETINNUMER to group the data by,    lbtestcd lbtest 
|                     along with ACROSSVAR, when counting to obtain     &g_trtcd
|                     the numerator. Additionally a set of brackets     &g_trtgrp 
|                     may be inserted within the variables to generate  visitnum visit
|                     records containing summary counts grouped by      _baseline_cd
|                     variables specified to the left of the brackets.  _baseline_ind 
|                     Summary records created may be populated with     lbnrcd lbnrind
|                     values in the grouping variables by specifying
|                     variable value pairs within brackets, seperated 
|                     by semi colons. eg aesoccd aesoc(aeptcd=0;
|                     aept="Any Event";) aeptcd aept. 
|                     Valid values: 
|                     Blank 
|                     Name of one or more SAS variables that exist in 
|                     DSETINNUMER 
|                     SAS assignment statements within brackets 
| 
| IDVARS              Variables to appear on each page if the report    visit 
|                     is wider than 1 page. If no value is supplied to  _baseline_ind 
|                     this parameter then all displayable order         tt_denomcnt1
|                     variables will be defined as IDVARS 
|                     Valid values: one or more variable names that 
|                     are also defined with COLUMNS 
| 
| LBRANGEHIGHVARNAME  Specifies the name of the LAB range high value.   Lbstnrhi
| 
| LBRANGEINDCODEINFO  Specifies the name of the LAB indicator ordering  $LB4ord.
| RMAT                informat. 
| 
| LBRANGEINDCODEVARN  Specifies the name of the LAB indicator code.     Lbnrcd
| AME 
| 
| LBRANGEINDVARNAME   Specifies the name of the LAB indicator text.     Lbnrind 
| 
| LBRANGELOWVARNAME   Specifies the name of the LAB range low value.    Lbstnrlo
| 
| LBSTDBLVARNAME      Specifies the name of the baseline value          Lbstdbl 
|                     associated with a lab test.  Used to compute
|                     baseline flag.
| 
| LBTESTCDVARNAME     Specifies the name of the LAB  test variable.     LbTestCD
| 
| NOPRINTVARS         Variables listed in the COLUMN parameter that     visitnum
|                     are given the PROC REPORT define statement        _baseline_cd
|                     attribute noprint 
|                     Valid values: one or more variable names that 
|                     are also defined with COLUMNS 
|                     These variables are ORDERVARS used to control 
|                     the order of the rows in the display
| 
| ORDERVARS           List of variables that will receive the PROC      visitnum visit
|                     REPORT define statement attribute ORDER           tt_denomcnt1
|                     Valid values: one or more variable names that     _baseline_cd
|                     are also defined with COLUMNS 
| 
| POSTSUBSET          SAS expression to be applied to data immediately  if
|                     prior to creation of the permanent presentation   missing(tt_denomcn
|                     dataset. Used for subsetting records required     t1) then
|                     for computation but not for display.              tt_denomcnt1=0
|                     Valid values: 
|                     Blank 
|                     A complete, syntactically valid SAS where or if 
|                     statement for use in a data step
| 
| SHARECOLVARS        List of variables that will share print space.    (Blank) 
|                     The attributes of the last variable in the list 
|                     define the column width and flow options
|                     Valid values: one or more SAS variable names
|                     AE5 shows an example of this style of output
|                     The formatted values of the variables shall be
|                     written above each other in one column
| 
| SKIPVARS            Variables whose change in value causes the        visit 
|                     display to skip a line
|                     Valid values: one or more variable names that 
|                     are also defined with COLUMNS 
| 
| TOTALDECODE         Label for the total result column. Usually the    Total 
|                     text Total
|                     Valid values: 
|                     Blank 
|                     SAS data step expression resolving to a 
|                     character.
| 
| TOTALID             Value used to populate the variable specified in  999 
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
|(@) tu_createfmt
|
| Example:
|    %td_lb4()
|
|----------------------------------------------------------------------------------------
|
| Modified By:              Yongwei Wang
| Date of Modification:     28-May-2004
| New version number:       1/2
| Modification ID:          YW001
| Reason For Modification:  Removed tt_denomcnt1 from &FLOWVARS because of the change
|                           of tu_pva.
|
|----------------------------------------------------------------------------------------
| Modified By:             Paul Jarrett
| Date of Modification:    13-Jun-2004
| New version number:      2/1
| Modification ID:         pbj001
| Reason For Modification: Remove duplicate IDVARS in macro declaration as specified
|                          in HRT0026.
|----------------------------------------------------------------------------------------
| Modified By:
| Date of Modification:
| New version number:
| Modification ID:
| Reason For Modification:
|
|----------------------------------------------------------------------------------------*/

%macro td_lb4 (
   BREAK1              =,                  /* Break statements */
   BREAK2              =,                  /* Break statements */
   BREAK3              =,                  /* Break statements */
   BREAK4              =,                  /* Break statements */
   BREAK5              =,                  /* Break statements */
   BYVARS              =,                  /* By variables */
   CENTREVARS          =,                  /* Centre justify variables */
   COLSPACING          =2,                 /* Value for between-column spacing */
   COUNTDISTINCTWHATVAR=&g_centid &g_subjid, /* Variable(s) that contain values to be counted uniquely within any output grouping. Eg &g_subjid */
   DESCENDING          =,                  /* Descending ORDERVARS */
   FORMATS             =,                  /* Format specification (valid SAS syntax) */
   GROUPBYVARPOP       =&g_trtcd,          /* Variables to group by when counting big N */
   LABELS              =,                  /* Label definitions (var=var label) */
   LEFTVARS            =,                  /* Left justify variables */
   LINEVARS            =,                  /* Order variables printed with LINE statements */
   NOWIDOWVAR          =,                  /* List of variables whose values must be kept together on a page */
   ORDERDATA           =,                  /* ORDER=DATA variables */
   ORDERFORMATTED      =,                  /* ORDER=FORMATTED variables */
   ORDERFREQ           =,                  /* ORDER=FREQ variables */
   PAGEVARS            =,                  /* Variables whose change in value causes the display to continue on a new page */
   PROPTIONS           =Headline,          /* PROC REPORT statement options */
   PSOPTIONS           =COMPLETETYPES MISSING NWAY, /* PROC SUMMARY Options to use */
   RESULTPCTDPS        =0,                 /* The reporting precision for percentages Valid values: 0 or any positive integer */
   RESULTSTYLE         =NUMERPCT,          /* The appearance style of the result columns that will be displayed in the report: */
   RIGHTVARS           =,                  /* Right justify variables */
   SHARECOLVARSINDENT  =2,                 /* Indentation factor */
   SPLITCHAR           =~,                 /* The split character used in column labels. */
   SPSORTGROUPBYVARSDENOM=,                /* Special sort: variables in DSETINDENOM to group the data by when counting to obtain the denominator. */
   TOTALFORVAR         = ,                 /* Variable for which a total is required, usually trtcd */
   VARSPACING          =,                  /* Column spacing for individual variables */
   WIDTHS              =,                  /* Column widths */
   ACROSSVAR           =lbnrcd,            /* Variable to transpose the data across to make columns of results. This is passed to the proc transpose ID statement */
   ACROSSVARDECODE     =lbnrind,           /* A variable or format used in the construction of labels for the result columns. Usually &g_trtgrp */
   CODEDECODEVARPAIRS  =&g_trtcd &g_trtgrp lbtestcd lbtest visitnum visit _baseline_cd _baseline_ind lbnrcd lbnrind, /* Code and Decode variables in pairs */
   COLUMNS             =visitnum visit tt_denomcnt1 _baseline_cd _baseline_ind ('Time Period Normal Range Value' '--' tt_ac:), /* Columns to be included in the listing (plus spanned headers) */
   COMPUTEBEFOREPAGELINES =%unquote(LBTEST $local. : lbtest TRTMNT $local. : &g_trtgrp), /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt : labelvar) */
   COMPUTEBEFOREPAGEVARS=%unquote(lbtestcd &g_trtcd), /* Names of variables that define the sort order for  Compute Before Page lines */
   DDDATASETLABEL      =DD dataset for LB4 table, /* Label to be applied to the DD dataset */
   DEFAULTWIDTHS       =visit 10 _baseline_ind 8 tt_denomcnt1 4, /* List of default column widths */
   DSETIN              =ardata.lab,        /* Input Lab Data */
   FLOWVARS            =visit _baseline_ind, /* Variables with flow option */
   GROUPBYVARSDENOM    =Lbtestcd &g_trtcd visitnum, /* Variables in DSETINDENOM to group the data by when counting to obtain the denominator. */
   GROUPBYVARSNUMER    =lbtestcd lbtest &g_trtcd &g_trtgrp visitnum visit _baseline_cd _baseline_ind lbnrcd lbnrind, /* Variables in DSETINNUMER to group the data by when counting to obtain the numerator. */
   IDVARS              =visit _baseline_ind tt_denomcnt1, /* Variables to appear on each page of the report */
   LBRANGEHIGHVARNAME  =Lbstnrhi,          /* Variable name of High Range Values */
   LBRANGEINDCODEINFORMAT=$LB4ord.,        /* Indicator code ordering informat */
   LBRANGEINDCODEVARNAME=Lbnrcd,           /* Variable name of LAB Indicator Code Values */
   LBRANGEINDVARNAME   =Lbnrind,           /* Variable name of Lab Indicator Text */
   LBRANGELOWVARNAME   =Lbstnrlo,          /* Variable name of Low Range Values */
   LBSTDBLVARNAME      =Lbstdbl,           /* Variable of Baseline value. */
   LBTESTCDVARNAME     =LbTestCD,          /* Variable name of LAB test code */
   NOPRINTVARS         =visitnum _baseline_cd, /* No print variables, used to order the display */
   ORDERVARS           =visitnum visit tt_denomcnt1 _baseline_cd, /* Order variables */
   POSTSUBSET          =if missing(tt_denomcnt1) then tt_denomcnt1=0, /* SAS expression to be applied to data immediately prior to creation of the permanent presentation dataset */
   SHARECOLVARS        =,                  /* Order variables that share print space */
   SKIPVARS            =visit,             /* Variables whose change in value causes the display to skip a line */
   TOTALDECODE         =Total,             /* Label for the total result column. Usually the text Total */
   TOTALID             =999                /* Value used to populate the variable specified in ACROSSVAR on data that represents the overall total for the ACROSSVAR variable. */
   ); /*END-MACRO-DEFINE*/


   /*
   / Echo the macro name and version to the log. Also echo the parameter values
   / and values of global macro variables used by this macro.
   /---------------------------------------------------------------------------*/

   %local macroversion;
   %let macroversion = 2;
   %inc "&g_refdata/tr_putlocals.sas";
   %tu_putglobals(varsin=g_SUBSET)

   %local workroot sc l_vlen;
   %let l_vlen=0;
   %let workroot = %substr(&sysmacroname,3);

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
      %goto MacERR;
   %end;

   %if %sysfunc(exist(&dsetin)) EQ 0 %then
   %do;
      %let g_abort = 1;
      %put %str(RTER)ROR: &sysmacroname: DSETIN=&dsetin does not exist. ;
      %goto MacERR;
   %end;


   /*
   / Check lab range variables are not blank
   /---------------------------------------------*/
   %if    %nrbquote(&lbtestCDVarName)       EQ
       OR %nrbquote(&lbRangeLowVarName)     EQ
       OR %nrbquote(&lbRangeHighVarName)    EQ
       OR %nrbquote(&lbRangeIndVarName)     EQ
       OR %nrbquote(&lbSTDBLvarname)        EQ
       OR %nrbquote(&lbRangeIndCodeVarName) EQ %then
   %do;
      %let g_abort = 1;
      %put %str(RTER)ROR: &sysmacroname: At Least one of the parameters lbtestCDVarName, lbRangeLowVarName, lbRangeHighVarName, lbRangeIndCodeVarName,;
      %put %str(RTER)ROR: &sysmacroname: lbRangeIndVarName, lbSTDBLvarname: is blank.;
      %put %str(RTER)ROR: &sysmacroname: lbtestCDVarName=&lbtestCDVarName;
      %put %str(RTER)ROR: &sysmacroname: lbRangeLowVarName=&lbRangeLowVarName;
      %put %str(RTER)ROR: &sysmacroname: lbRangeHighVarName=&lbRangeHighVarName;
      %put %str(RTER)ROR: &sysmacroname: lbRangeIndCodeVarName=&lbRangeIndCodeVarName;
      %put %str(RTER)ROR: &sysmacroname: lbRangeIndVarName=&lbRangeIndVarName;
      %put %str(RTER)ROR: &sysmacroname: lbSTDBLvarname=&lbSTDBLvarname;
   %end;

   /*
   / Check lab range variables exist in input data
   /------------------------------------------------------*/
   %local allvars donotexist;
   %let allvars    = &lbtestCDVarName &lbRangeLowVarName &lbRangeHighVarName &lbRangeIndCodeVarName &lbRangeIndVarName &lbSTDBLvarname;
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

   %let sc = %str(;);
   %let groupByVarsNumer   = %unquote(&groupByVarsNumer);
   %let postSubset         = %unquote(&postSubset);

   /*
   / Determine if LBTEST and LBSTUNIT are in &DSETIN.  If so, determine 
   / variable length needed for LBTEST when LBSTUNIT is appended
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
   / create format and informat
   /-----------------------------------------*/
   %tu_createfmt
    (
       dsetin = &dsetin,
       varsin = &lbRangeIndVarname=&lbRangeIndCodeVarname
    ) ;

   proc format ;
      invalue $lb4ord
         'H' = '1'
         'I' = '2'
         'L' = '3'
         other = '4'
         ;
      run;

   /*
   / Create work data set with extra visit for any visit post baseline
   /-------------------------------------------------------------------*/
   data work.&workroot._visit1;
      length _baseline_cd &lbRangeIndCodeVarname $1;

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

      %if %sysfunc(indexw(%qupcase(&psoptions), MISSING)) le 0 %then %do;
         if missing(&lbstdblvarname) then delete;
      %end;

      /*
      /  if the test result is not missing and at least one of boundaries is not missing,
      /  assign a value to the baseline test flag.
      /----------------------------------------------------------------------------------*/
      if ( not missing(&lbstdblvarname) ) and
         ( (not missing(&lbRangeHighVarname)) or (not missing(&lbRangeLowVarname)) )
      then do;
          if (not missing(&lbRangeLowVarname)) and (&lbstdblvarname LT &lbRangeLowVarname) then
             _baseline_cd = 'L';
          else if (not missing(&lbRangeHighVarname)) and ( &lbstdblvarname GT &lbRangeHighVarname ) then
             _baseline_cd = 'H';
          else
             _baseline_cd = 'I';
          _baseline_ind = put(_baseline_cd,%unquote($&lbRangeIndVarname%str(.)));
      end;
      else do;
          _baseline_ind = 'Missing';
      end;

      _baseline_cd = input(_baseline_cd, &lbRangeIndCodeInformat);

      if not ( upcase(&lbRangeIndCodeVarname) in ('L', 'H', 'I') ) then do;
         &lbRangeIndVarname='Missing';
      end;

      &lbRangeIndCodeVarname = input(&lbRangeIndCodeVarname,&lbRangeIndCodeInformat);

      %if %sysfunc(indexw(%qupcase(&psoptions), MISSING)) le 0 %then %do;
         if ( _baseline_ind ne 'Missing' ) and ( &lbRangeIndVarname ne 'Missing' ) then output;
      %end;

      label
         _baseline_cd  = 'Baseline~Normal~Range'
         _baseline_ind = 'Baseline~Normal~Range'
         ;
   run;

   /*
   / Create total ROW
   /-----------------------------------------------*/
   data work.&workroot._visit2;
      set work.&workroot._visit1;
      output;
      _baseline_cd  = "&totalid";
      _baseline_ind = "&totaldecode";
      output;
   run;

   /*
   / Create total COLUMN
   /-----------------------------------------------*/
   data work.&workroot._visit3;
      set work.&workroot._visit2;
      output;
      &lbRangeIndCodeVarname  = "&totalid";
      &lbRangeIndVarname      = "&totaldecode";
      output;
   run;

   %let totaldecode = ;
   %let totalid = ;

   %if &syserr GT 0 %then
   %do;
      %put %str(RTER)ROR: &sysmacroname: DATA STEP ended with a non-zero return code.;
      %goto macerr;
   %end;

%DISPLAYIT:

   %tu_freq
      (
         acrossColListName       = acrosscollist,
         acrossColVarPrefix      = tt_ac,
         ACROSSVAR               = &acrossvar,
         ACROSSVARDECODE         = &acrossvardecode,
         addbignyn               = N,
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
         computebeforepagelines  = &computebeforepagelines,
         computebeforepagevars   = &computebeforepagevars,
         countDistinctWhatVar    = &countDistinctWhatVar,
         dddatasetlabel          = &dddatasetlabel,
         defaultwidths           = &defaultwidths,
         denormYN                = Y,
         descending              = &descending,
         display                 = Y,
         dsetinDenom             = work.&workroot._visit3,
         dsetinNumer             = work.&workroot._visit3,
         dsetout                 = ,
         flowvars                = &flowvars,
         formats                 = &formats,
         groupbyvarpop           = &groupbyvarpop,
         groupByVarsDenom        = &groupByVarsDenom,
         groupByVarsNumer        = &groupByVarsNumer,
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
         psClassOptions          = ,
         psFormat                = ,
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
         spSort2GroupByVarsDenom = ,
         spSort2GroupByVarsNumer = ,
         spSort2ResultStyle      = ,
         spSort2ResultVarName    = ,
         spSortGroupByVarsDenom  = &spSortGroupByVarsDenom,
         spSortGroupByVarsNumer  = ,
         spSortResultStyle       = ,
         spSortResultVarName     = ,
         summaryLevelVarName     = summaryLevel,
         totalDecode             = ,
         totalForVar             = ,
         totalID                 = ,
         varlabelstyle           = SHORT,
         varspacing              = &varspacing,
         varstodenorm            = tt_result tt_pct tt_denomcnt,
         widths                  = &widths
      )

 %goto exit;

 %macerr:
   %put %str(RTE)RROR: &sysmacroname: Ending with error(s);
   %let g_abort = 1;
   %tu_abort()

 %exit:
   %tu_tidyup(rmdset=&workroot.:,glbmac=NONE)
   %put %str(RTN)OTE: &sysmacroname: ending execution.;

%mend td_lb4;
