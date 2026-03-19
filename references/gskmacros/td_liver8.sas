/*----------------------------------------------------------------------------------------
| Macro name:         td_liver8.sas
|
| Macro version:      1
|
| SAS version:        8.2
|
| Created by:         Yongwei Wang (YW62951)
|
| Date:               20Aug2007
|
| Macro purpose:      display macro to generate IDSL liver8 listing
|
| Macro design:       procedure style
|
| Input parameters:
|
| Name                Description                                  Default
| -----------------------------------------------------------------------------------
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
| COLSPACING          The value of the between-column spacing.     2
|                     Valid values: positive integer
|
| COLUMNS             A PROC REPORT column statement               &g_centid
|                     specification.  Including spanning titles    &g_subjid
|                     and variable names                           st_all_cs
|                     Valid values: one or more variable names     st_all_asr lidt
|                     from DSETIN plus other elements of valid     st_liver_dsd8
|                     PROC REPORT COLUMN statement syntax, but     limethcd limethod
|                     not including report_item=alias syntax       imgadqcd imgadq
|                                                                  litestcd litest
|                                                                  liorrscd liorres
|
| COMPUTEBEFOREPAGEL  Specifies the labels that shall precede the  TRTMNT $local. : 
| INES                ComputeBeforePageVar value. For each         &g_trtgrp
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
| COMPUTEBEFOREPAGEV  Variables listed in this parameter are       &g_trtcd
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
| DDDATASETLABEL      Specifies the label to be applied to the DD  DD dataset for
|                     dataset                                      new  listing
|                     Valid values: a non-blank text string        LIVER8
|
| DEFAULTWIDTHS       This is a list of default widths for ALL     st_all_cs 7
|                     columns and will usually be defined by the   st_all_asr 10
|                     DD macro.  This parameter specifies column   st_liver_dsd8 10
|                     widths for all variables not listed in the   limethod 14
|                     WIDTHS parameter.                            imgadq 14 litest
|                     Valid values: values of column names and     20 liorres 20
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
| DSETIN              Specifies the name of the input dataset      ardata.limaging
|                     Valid values: name of an existing dataset,
|                     pre-sorted by BYVARS
|
| FLOWVARS            Variables to be defined with the flow        _ALL_
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
| FORMATS             Variables and their format for display. For  (Blank)
|                     use where format for display differs to the
|                     format on the DSETIN.
|                     Valid values: values of column names and
|                     formats such as form valid syntax for a SAS
|                     FORMAT statement
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
| LABELS              Variables and their label for display. For   (Blank)
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
| NOPRINTVARS         Variables listed in the COLUMN parameter     &g_centid
|                     that are given the PROC REPORT define        &g_subjid lidt
|                     statement attribute noprint.                 limethcd imgadqcd
|                     Valid values: one or more variable names     litestcd liorrscd
|                     from DSETIN that are also defined with
|                     COLUMNS
|                     These variables are usually ORDERVARS used
|                     to control the order of the rows in the
|                     display.
|
| NOWIDOWVAR          Variable whose values must be kept together  st_all_cs
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
| ORDERVARS           List of variables that will receive the      &g_centid
|                     PROC REPORT define statement attribute       &g_subjid
|                     ORDER                                        st_all_cs
|                     Valid values: one or more variable names     st_all_asr lidt
|                     from DSETIN that are also defined with       st_liver_dsd8
|                     COLUMNS                                      limethcd limethod
|                                                                  imgadqcd imgadq
|                                                                  litestcd litest
|                                                                  liorrscd
|
| PAGEVARS            Variables whose change in value causes the   (Blank)
|                     display to continue on a new page
|                     Valid values: one or more variable names
|                     from DSETIN that are also defined with
|                     COLUMNS
|
| PROPTIONS           PROC REPORT statement options to be used in  Headline
|                     addition to MISSING.
|                     Valid values: proc report options
|                     The option Missing can not be overridden.
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
| SKIPVARS            Variables whose change in value causes the   litest
|                     display to skip a line
|                     Valid values: one or more variable names
|                     from DSETIN that are also defined with
|                     COLUMNS
|
| SPLITCHAR           Specifies the split character to be passed   ~
|                     to %tu_display
|                     Valid values: one single character
|
| STACKVAR1           Specifies parameters to pass to              str(varsin=&g_cent
|                     %tu_stackvar in order to stack variables     id &g_subjid,
|                     together.  See Unit Specification for HARP   varout=st_all_cs,
|                     Reporting Tools %TU_STACKVAR[4] for more     sepc=/)
|                     detail regarding macro parameters that can
|                     be used in the macro call.  DSETIN should
|                     not be specified  this will be generated
|                     internally by TU_LIST.
|
| STACKVAR2           Same as STACKVAR1                            %str(varsin=age
|                                                                  sex race,
|                                                                  varout=st_all_asr,
|                                                                  sepc=/)
|
| STACKVAR3           Same as STACKVAR1                            %str(varsin=lidt
|                                                                  actdy,
|                                                                  varout=st_liver_ds
|                                                                  d8, sepc=/)
|
| STACKVAR4-STACKVAR  Same as STACKVAR1                            (Blank)
| 15
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
|-----------------------------------------------------------------------------------------
| Output:
|   1. Listing output
|   2. Display dataset (DD dataset) used as the foundation of the listing output.
|-----------------------------------------------------------------------------------------
| Global macro variables created:
|   None
|-----------------------------------------------------------------------------------------
| Macros called:
| (@) tr_putlocals
| (@) tu_nobs
| (@) tu_putglobals
| (@) tu_list
| (@) tu_tidyup
| (@) tu_chkvarsexist
|-----------------------------------------------------------------------------------------
| Change Log
|
| Modified by:
| Date of modification:
| New version number:
| Modification ID:
| Reason for modification:
|---------------------------------------------------------------------------------------*/

%macro td_liver8(
   BREAK1              =,                  /* Break statements. */
   BREAK2              =,                  /* Break statements. */
   BREAK3              =,                  /* Break statements. */
   BREAK4              =,                  /* Break statements. */
   BREAK5              =,                  /* Break statements. */
   BYVARS              =,                  /* By variables */
   CENTREVARS          =,                  /* Centre justify variables */
   COLSPACING          =2,                 /* Overall spacing value. */
   COLUMNS             =&g_centid &g_subjid st_all_cs st_all_asr lidt st_liver_dsd8 limethcd limethod imgadqcd imgadq litestcd litest liorrscd liorres, /* Column parameter */
   COMPUTEBEFOREPAGELINES=TRTMNT $local. : &g_trtgrp, /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt colon labelvar) */
   COMPUTEBEFOREPAGEVARS=&g_trtcd,         /* Computed by variables. */
   DDDATASETLABEL      =DD dataset for new  listing LIVER8, /* Label to be applied to the DD dataset */
   DEFAULTWIDTHS       =st_all_cs 7 st_all_asr 10 st_liver_dsd8 10 limethod 14 imgadq 14 litest 20 liorres 20, /* List of default column widths */
   DESCENDING          =,                  /* Descending ORDERVARS */
   DSETIN              =ardata.limaging,   /* Input dataset */
   FLOWVARS            =_ALL_,             /* Variables with flow option */
   FORMATS             =,                  /* Format specification */
   IDVARS              =,                  /* Variables to appear on each page should the report be wider than 1 page */
   LABELS              =,                  /* Label definitions. */
   LEFTVARS            =,                  /* Left justify variables */
   LINEVARS            =,                  /* Order variable printed with line statements. */
   NOPRINTVARS         =&g_centid &g_subjid lidt limethcd imgadqcd litestcd liorrscd, /* No print vars (usually used to order the display) */
   NOWIDOWVAR          =st_all_cs,         /* Variable whose values must be kept together on a page */
   ORDERDATA           =,                  /* ORDER=DATA variables */
   ORDERFORMATTED      =,                  /* ORDER=FORMATTED variables */
   ORDERFREQ           =,                  /* ORDER=FREQ variables */
   ORDERVARS           =&g_centid &g_subjid st_all_cs st_all_asr lidt st_liver_dsd8 limethcd limethod imgadqcd imgadq litestcd litest liorrscd, /* Order variables */
   PAGEVARS            =,                  /* Break after <var> / page; */
   PROPTIONS           =Headline,          /* PROC REPORT statement options */
   RIGHTVARS           =,                  /* Right justify variables */
   SHARECOLVARS        =,                  /* Order variables that share print space. */
   SHARECOLVARSINDENT  =2,                 /* Indentation factor */
   SKIPVARS            =litest,            /* Break after <var> / skip; */
   SPLITCHAR           =~,                 /* Split character */
   STACKVAR1           =%str(varsin=&g_centid &g_subjid, varout=st_all_cs, sepc=/), /* Create Stacked variables (e.g. stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc=~) ) */
   STACKVAR2           =%str(varsin=age sex race, varout=st_all_asr, sepc=/), /* Same as STACKVAR1 */
   STACKVAR3           =%str(varsin=lidt actdy, varout=st_liver_dsd8, sepc=/), /* Same as STACKVAR1 */
   STACKVAR4           =,                  /* Same as STACKVAR1 */
   STACKVAR5           =,                  /* Same as STACKVAR1 */
   STACKVAR6           =,                  /* Same as STACKVAR1 */
   STACKVAR7           =,                  /* Same as STACKVAR1 */
   STACKVAR8           =,                  /* Same as STACKVAR1 */
   STACKVAR9           =,                  /* Same as STACKVAR1 */
   STACKVAR10          =,                  /* Same as STACKVAR1 */
   STACKVAR11          =,                  /* Same as STACKVAR1 */
   STACKVAR12          =,                  /* Same as STACKVAR1 */
   STACKVAR13          =,                  /* Same as STACKVAR1 */
   STACKVAR14          =,                  /* Same as STACKVAR1 */
   STACKVAR15          =,                  /* Same as STACKVAR1 */
   VARLABELSTYLE       =SHORT,             /* Specifies the label style for variables (SHORT or STD) */
   VARSPACING          =,                  /* Spacing for individual variables. */
   WIDTHS              =                   /* Column widths */
   );

   /* echo macro parameters to log file below */

   %local MacroVersion;
   %let MacroVersion=1;

   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals()


   %local l_prefix;
   %let l_prefix=_liver8;

   %if %tu_nobs(&dsetin) gt 0 %then
   %do;
      /* Combine LIORRSSP with LIORRES */
      %if %tu_chkvarsexist(&dsetin, LIORRSCD LIORRES LIORRSSP) eq %then
      %do;
         data &l_prefix.dsetin;
            length LIORRES $300;
            set &dsetin;
            if substr(left(LIORRSCD), 2, 2) eq '99' then LIORRES='Other: ' || LIORRSSP;
         run;

         %let dsetin=&l_prefix.dsetin;
      %end;
      /* Combine LIMETHOD with LIMETHSP */
      %if %tu_chkvarsexist(&dsetin, LIMETHCD LIMETHOD LIMETHSP) eq %then
      %do;
         data &l_prefix.dsetin;
            length LIMETHOD $300;
            set &dsetin;
            if upcase(LIMETHCD) EQ 'OT' then LIMETHOD='Other: ' || LIMETHSP;
         run;

         %let dsetin=&l_prefix.dsetin;
      %end;
      /* Combine IMGADQ and IMGADQSP */
      %if %tu_chkvarsexist(&dsetin, IMGADQ IMGADQCD IMGADQSP ) eq %then
      %do;
         data &l_prefix.dsetin;
            length IMGADQ $300;
            set &dsetin;
            if upcase(IMGADQCD) EQ 'OT' then IMGADQ='Other: ' || IMGADQSP;
         run;

         %let dsetin=&l_prefix.dsetin;
      %end;
      
      %if %nrbquote(&dsetin) ne &l_prefix.dsetin %then
      %do;
         data &l_prefix.dsetin;
            set &dsetin;
         run;
            
         %let dsetin=&l_prefix.dsetin;
      %end;
   %end; /* %tu_nobs(&dsetin) gt 0 */


   /*  call tu_list below */

   %tu_list(
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
      computebeforepagevars   =&computebeforepagevars,
      dddatasetlabel          =&dddatasetlabel,
      defaultwidths           =&defaultwidths,
      descending              =&descending,
      display                 =y,
      dsetin                  =&dsetin,
      flowvars                =&flowvars,
      formats                 =&formats,
      getdatayn               =y,
      idvars                  =&idvars,
      labels                  =&labels,
      labelvarsyn             =y,
      leftvars                =&leftvars,
      linevars                =&linevars,
      noprintvars             =&noprintvars,
      nowidowvar              =&nowidowvar,
      orderdata               =&orderdata,
      orderformatted          =&orderformatted,
      orderfreq               =&orderfreq,
      ordervars               =&ordervars,
      overallsummary          =n,
      pagevars                =&pagevars,
      proptions               =&proptions,
      rightvars               =&rightvars,
      sharecolvars            =&sharecolvars,
      sharecolvarsindent      =&sharecolvarsindent,
      skipvars                =&skipvars,
      splitchar               =&splitchar,
      stackvar1               =&stackvar1,
      stackvar10              =&stackvar10,
      stackvar11              =&stackvar11,
      stackvar12              =&stackvar12,
      stackvar13              =&stackvar13,
      stackvar14              =&stackvar14,
      stackvar15              =&stackvar15,
      stackvar2               =&stackvar2,
      stackvar3               =&stackvar3,
      stackvar4               =&stackvar4,
      stackvar5               =&stackvar5,
      stackvar6               =&stackvar6,
      stackvar7               =&stackvar7,
      stackvar8               =&stackvar8,
      stackvar9               =&stackvar9,
      varlabelstyle           =&varlabelstyle,
      varspacing              =&varspacing,
      widths                  =&widths
      );

   %tu_tidyup(
      rmdset=&l_prefix:,
      glbmac=NONE
      );

%mend td_liver8;

