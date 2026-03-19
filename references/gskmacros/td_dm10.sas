/*
|
| Macro Name:       td_dm10
|
| Macro Version:    1
|
| SAS Version:      8
|
| Created By:       Yongwei Wang
|
| Date:             10DEC2004
|
| Macro Purpose:    A macro to create IDSL standard display DM10
|
| Macro Design:     Procedure style.
|
| Input Parameters:
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
|                     Valid values: one or more variable names from
|                     DSETIN
|                     No formatting of the display for these variables
|                     is performed by %tu_display.  The user has the
|                     option of the standard SAS BY line, or using
|                     OPTIONS NOBYLINE and #BYVAL #BYVAR directives in
|                     title statements.
|
| CENTREVARS          Variables to be displayed as centre justified     (Blank)
|                     Valid values: one or more variable names from
|                     DSETIN that are also defined with COLUMNS
|                     Variables not appearing in any of the parameters
|                     CENTREVARS, LEFTVARS, or RIGHTVARS will be
|                     displayed using the PROC REPORT default.
|                     Character variables are left justified while
|                     numeric variables are right justified.
|
| COLSPACING          The value of the between-column spacing           2
|                     Valid values: positive integer
|
| COLUMNS             A PROC REPORT column statement specification.     &g_centid 
|                     Including spanning titles and variable names      &g_subjid 
|                     Valid values: one or more variable names from     &g_trtcd 
|                     DSETIN plus other elements of valid PROC REPORT   &g_trtgrp  raceccd
|                     COLUMN statement syntax                           racec
|
| COMPUTEBEFOREPAGEL  See Unit Specification for HARP Reporting Tools   (Blank)
| INES                TU_LIST[4] for complete details.
|
| COMPUTEBEFOREPAGEV  See Unit Specification for HARP Reporting Tools   (Blank)
| ARS                 TU_LIST[4] for complete details.
|
| DDDATASETLABEL      Specifies the label to be applied to the DD       DD dataset
|                     dataset                                           for listing
|                     Valid values: a non-blank text string             DM10
|
| DEFAULTWIDTHS       This parameter specifies default column widths    &g_trtgrp 20
|                     for all variables not listed in the WIDTHS        &g_centid 8
|                     parameter.                                        &g_subjid 10
|                     Valid values: values of column names and numeric  racec 40
|                     widths, a list of variables followed by a
|                     positive integer, e.g.
|
|                     defaultwidths = a b 10 c 12 d1-d4 6
|                     Numbered range lists are supported in this
|                     parameter however name range lists, name prefix
|                     lists, and special SAS name lists are not.
|                     Variables that are not given widths through
|                     either the WIDTHS or DEFAULTWIDTHS parameter
|                     will be width optimised using:
|                     MAX (variables format width,
|                     width of column header) for variables that are
|                     NOT flowed or
|                     MIN(variables format width,
|                     width of column header) for variable that ARE
|                     flowed.
|
| DESCENDING          List of ORDERVARS that are given the PROC REPORT  (Blank)
|                     define statement attribute DESCENDING
|                     Valid values: one or more variable names from
|                     DSETIN that are also defined with ORDERVARS
|
| DSETIN              The domain data set to act as the subject of the  Ardata.race
|                     report
|                     Valid values: name of a data set meeting an IDSL
|                     domain-specific dataset specification
|
| FLOWVARS            Variables to be defined with the flow option      &g_trtgrp racec
|                     Valid values: one or more variable names from
|                     DSETIN that are also defined with COLUMNS
|                     Flow variables should be given a width through
|                     the WIDTHS.  If a flow variable does not have a
|                     width specified the column width will be
|                     determined by
|                     MIN(variables format width,
|                     width of  column header)
|
| FORMATS             Variables and their format for display. For use   (Blank)
|                     where format for display differs to the format
|                     on the DSETIN.
|                     Valid values: values of column names and formats
|                     such as form valid syntax for a SAS FORMAT
|                     statement
|
| IDVARS              Variables to appear on each page should the       (Blank)
|                     report be wider than 1 page. If no value is
|                     supplied to this parameter then all displayable
|                     order variables will be defined as idvars
|                     Valid values: one or more variable names from
|                     DSETIN that are also defined with COLUMNS
|
| LABELS              Variables and their label for display. For use    (Blank)
|                     where label for display differs to the label on
|                     the DSETIN
|                     Valid values: pairs of variable names and labels
|
| LEFTVARS            Variables to be displayed as left justified       (Blank)
|                     Valid values: one or more variable names from
|                     DSETIN that are also defined with COLUMNS
|
| LINEVARS            List of order variables that are printed with     (Blank)
|                     LINE statements in PROC REPORT
|                     Valid values: one or more variable names from
|                     DSETIN that are also defined with ORDERVARS
|                     These values shall be written with a BREAK
|                     BEFORE when the value of one of the variables
|                     change. The variables will automatically be
|                     defined as NOPRINT
|
| NOPRINTVARS         Variables listed in the COLUMN parameter that     &g_trtcd raceccd
|                     are given the PROC REPORT define statement
|                     attribute noprint.
|                     Valid values: one or more variable names from
|                     DSETIN that are also defined with COLUMNS
|                     These variables are ORDERVARS used to control
|                     the order of the rows in the display.
|
| NOWIDOWVAR          Variable whose values must be kept together on a  (Blank)
|                     page
|                     Valid values: names of one or more variables
|                     specified in COLUMNS
|
| ORDERDATA           Variables listed in the ORDERVARS parameter that  (Blank)
|                     are given the PROC REPORT define statement
|                     attribute order=data.
|                     Valid values: one or more variable names from
|                     DSETIN that are also defined with ORDERVARS
|                     Variables not listed in ORDERFORMATTED,
|                     ORDERFREQ, or ORDERDATA are given the define
|                     attribute order=internal
|
| ORDERFORMATTED      Variables listed in the ORDERVARS parameter that  (Blank)
|                     are given the PROC REPORT define statement
|                     attribute order=formatted.
|                     Valid values: one or more variable names from
|                     DSETIN that are also defined with ORDERVARS
|                     Variables not listed in ORDERFORMATTED,
|                     ORDERFREQ, or ORDERDATA are given the define
|                     attribute order=internal
|
| ORDERFREQ           Variables listed in the ORDERVARS parameter that  (Blank)
|                     are given the PROC REPORT define statement
|                     attribute order=freq.
|                     Valid values: one or more variable names from
|                     DSETIN that are also defined with ORDERVARS
|                     Variables not listed in ORDERFORMATTED,
|                     ORDERFREQ, or ORDERDATA are given the define
|                     attribute order=internal
|
| ORDERVARS           List of variables that will receive the PROC      &g_centid
|                     REPORT define statement attribute ORDER           &g_subjid
|                     Valid values: one or more variable names from     &g_trtcd
|                     DSETIN that are also defined with COLUMNS         &g_trtgrp raceccd
|
| PAGEVARS            Variables whose change in value causes the        (Blank)
|                     display to continue on a new page
|                     Valid values: one or more variable names from
|                     DSETIN that are also defined with COLUMNS
|
| PROPTIONS           PROC REPORT statement options to be used in       Headline
|                     addition to MISSING.
|                     Valid values: proc report options
|                     The option Missing can not be overridden.
|
| RIGHTVARS           Variables to be displayed as right justified      (Blank)
|                     Valid values: one or more variable names from
|                     DSETIN that are also defined with COLUMNS
|
| SHARECOLVARS        List of variables that will share print space.    (Blank)
|                     The attributes of the last variable in the list
|                     define the column width and flow options
|                     Valid values: one or more variable names from
|                     DSETIN
|                     AE5 shows an example of this style of output
|                     The formatted values of the variables shall be
|                     written above each other in one column.
|
| SHARECOLVARSINDENT  Indentation factor for ShareColVars. Stacked      2
|                     values shall be progressively indented by
|                     multiples of ShareColVarsIndent
|                     Valid values: positive integer
|
| SKIPVARS            Variables whose change in value causes the        &g_subjid
|                     display to skip a line
|                     Valid values: one or more variable names from
|                     DSETIN that are also defined with COLUMNS
|
| SPLITCHAR           Specifies the split character to be passed to     ~
|                     %tu_display
|                     Valid values: one single character
|
| STACKVAR1-          Specifies any variables that should be stacked    (Blank)
| STACKVAR15          together.  See Unit Specification for HARP
|                     Reporting Tools TU_STACKVAR[5] for more detail
|                     regarding macro parameters that can be used in
|                     the macro call.  Note that the DSETIN parameter
|                     will be passed by %tu_list and should not be
|                     provided here.
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
|                     default to be overridden.
|
|-------------------------------------------------------------------------------
|
| Output: Printed output.
|
| Global macro variables created: NONE
|
|
| Macros called:
|
|(@) tr_putlocals
|(@) tu_list
|(@) tu_putglobals
|
| Example:
|    %td_dm10()
|
|-------------------------------------------------------------------------------
| Change Log
|
| Modified By:
| Date of Modification:
| New version number:
| Modification ID:
| Reason For Modification:
|
|-------------------------------------------------------------------------------*/

%macro td_dm10(
   BREAK1              =,                  /* Break statements */
   BREAK2              =,                  /* Break statements */
   BREAK3              =,                  /* Break statements */
   BREAK4              =,                  /* Break statements */
   BREAK5              =,                  /* Break statements */
   BYVARS              =,                  /* By variables */
   CENTREVARS          =,                  /* Centre justify variables */
   COLSPACING          =2,                 /* Value for between-column spacing */
   COLUMNS             =&g_centid &g_subjid &g_trtcd &g_trtgrp raceccd racec, /* Columns to be included in the listing (plus spanned headers) */
   COMPUTEBEFOREPAGELINES=,                /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt : labelvar) */
   COMPUTEBEFOREPAGEVARS=,                 /* Names of variables that define the sort order for  Compute Before Page lines */
   DDDATASETLABEL      =DD dataset for listing DM10, /* Label to be applied to the DD dataset */
   DEFAULTWIDTHS       =&g_trtgrp 20 &g_centid 8 &g_subjid 10  racec 40, /* List of default column widths */
   DESCENDING          =,                  /* Descending ORDERVARS */
   DSETIN              =Ardata.race,       /* Input domain dataset */
   FLOWVARS            =&g_trtgrp racec,   /* Variables with flow option */
   FORMATS             =,                  /* Format specification (valid SAS syntax) */
   IDVARS              =,                  /* Variables to appear on each page of the report */
   LABELS              =,                  /* Label definitions (var=var label) */
   LEFTVARS            =,                  /* Left justify variables */
   LINEVARS            =,                  /* Order variables printed with LINE statements */
   NOPRINTVARS         =&g_trtcd raceccd,  /* No print variables, used to order the display */
   NOWIDOWVAR          =,                  /* List of variable whose values must be kept together on a page */
   ORDERDATA           =,                  /* ORDER=DATA variables */
   ORDERFORMATTED      =,                  /* ORDER=FORMATTED variables */
   ORDERFREQ           =,                  /* ORDER=FREQ variables */
   ORDERVARS           =&g_centid &g_subjid &g_trtcd &g_trtgrp raceccd, /* Order variables */
   PAGEVARS            =,                  /* Variables whose change in value causes the display to continue on a new page */
   PROPTIONS           =Headline,          /* PROC REPORT statement options */
   RIGHTVARS           =,                  /* Right justify variables */
   SHARECOLVARS        =,                  /* Order variables that share print space */
   SHARECOLVARSINDENT  =2,                 /* Indentation factor */
   SKIPVARS            =&g_subjid,         /* Variables whose change in value causes the display to skip a line */
   SPLITCHAR           =~,                 /* Split character */
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
   VARLABELSTYLE       =SHORT,             /* Specifies the label style for variables (SHORT or STD) */
   VARSPACING          =,                  /* Column spacing for individual variables */
   WIDTHS              =                   /* Column widths */
   );

   /* echo macro parameters to log file below */
  
   %local MacroVersion;
   %let MacroVersion = 1;
  
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals()
  
   /*  call tu_list below */
  
   %tu_list(
      display                 =Y,
      getdatayn               =Y,
      labelvarsyn             =Y,
      overallsummary          =N,
  
      break1                  =&break1,
      break2                  =&break2,
      break3                  =&break3,
      break4                  =&break4,
      break5                  =&break5,
      byvars                  =&byvars,
      centrevars              =&centrevars,
      colspacing              =&colspacing,
      columns                 =&columns,
      computebeforepagelines  =&computebeforepagelines,
      computebeforepagevars   =&computebeforepagevars ,
      dddatasetlabel          =&dddatasetlabel,
      defaultwidths           =&defaultwidths,
      descending              =&descending,
      dsetin                  =&dsetin,
      flowvars                =&flowvars,
      formats                 =&formats,
      idvars                  =&idvars,
      labels                  =&labels,
      leftvars                =&leftvars,
      linevars                =&linevars,
      noprintvars             =&noprintvars,
      nowidowvar              =&nowidowvar,
      orderdata               =&orderdata,
      orderformatted          =&orderformatted,
      orderfreq               =&orderfreq,
      ordervars               =&ordervars ,
      pagevars                =&pagevars,
      proptions               =&proptions ,
      rightvars               =&rightvars,
      sharecolvars            =&sharecolvars,
      sharecolvarsindent      =&sharecolvarsindent,
      skipvars                =&skipvars,
      splitchar               =&splitchar,
      stackvar1               =&stackvar1,
      stackvar10              =&stackvar10 ,
      stackvar11              =&stackvar11 ,
      stackvar12              =&stackvar12 ,
      stackvar13              =&stackvar13 ,
      stackvar14              =&stackvar14 ,
      stackvar15              =&stackvar15 ,
      stackvar2               =&stackvar2 ,
      stackvar3               =&stackvar3  ,
      stackvar4               =&stackvar4 ,
      stackvar5               =&stackvar5  ,
      stackvar6               =&stackvar6  ,
      stackvar7               =&stackvar7  ,
      stackvar8               =&stackvar8  ,
      stackvar9               =&stackvar9  ,
      varlabelstyle           =&varlabelstyle,
      varspacing              =&varspacing,
      widths                  =&widths
      );
  
%mend td_dm10;

