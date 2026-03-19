/*--------------------------------------------------------------------------------------
|  Macro name:     td_ae7.sas
|
|  Macro version:  1
|
|  SAS version:    8.2
|
|  Created by:     Yongwei Wang (YW62951)
|
|  Date:           18Jan2004
|
|  Macro Purpose:  A macro to create Adverse Event Display 7.
|
|  Macro design:   Procedure Style
|
|------------------------------------------------------------------------------------------
|  Input parameters:
|
|  Name                Description                                       Default
|  ----------------------------------------------------------------------------------------
|  BREAK1-BREAK5       5 parameters for input of user specified break    (Blank)
|                      statements.
|                      Valid values: valid PROC REPORT BREAK statements
|                      (without "break")
|                      The value of these parameters are passed
|                      directly to PROC REPORT as:
|                      BREAK &break1;
|
|  BYVARS              By variables. The variables listed here are       (Blank)
|                      processed as standard SAS BY variables.
|                      Valid values: one or more variable names from
|                      DSETIN
|                      It is the caller's responsibility to provide a
|                      sorted dataset as DSETIN; TU_DISPLAY will not
|                      sort the dataset.
|                      No formatting of the display for these variables
|                      is performed by %tu_DISPLAY.  The user has the
|                      option of the standard SAS BY line, or using
|                      OPTIONS NOBYLINE and #BYVAL #BYVAR directives in
|                      title statements.
|
|  CENTREVARS          Variables to be displayed as centre justified.    (Blank)
|                      Valid values: one or more variable names from
|                      DSETIN that are also defined with COLUMNS
|                      Variables not appearing in any of the parameters
|                      CENTREVARS, LEFTVARS, or RIGHTVARS will be
|                      displayed using the PROC REPORT default.
|                      Character variables are left justified while
|                      numeric variables are right justified.
|
|  COLSPACING          The value of the between-column spacing.          2
|                      Valid values: positive integer
|
|  COLUMNS             A PROC REPORT column statement specification.     tt_order1 aesoc
|                      Including spanning titles and variable names      tt_order2 aept
|                      Valid values: one or more variable names from     &g_trtcd
|                      DSETIN plus other elements of valid PROC REPORT   &g_trtgrp
|                      COLUMN statement syntax, but not including        tt_aenum
|                      report_item=alias syntax                          tt_aesubjs
|
|  COMPUTEBEFOREPAGEL  Specifies the labels that shall precede the       (Blank)
|  INES                ComputeBeforePageVar value. For each variable
|                      specified for COMPUTEBEFOREP
|                      * A localisation key for the fixed labelling
|                      text
|                      * The name of the localisation format ($local.)
|                      * The character(s) to be used between the
|                      labelling text and the values of the fourth
|                      parameter
|                      * Name of a variable whose values are to be used
|                      in the Computer Before Page line
|                      Valid values: A multiple of four words separated
|                      by blanks. The multiple shall be equal to the
|                      number of variables specified for
|                      COMPUTEBEFOREPAGEVARS
|                      For example:
|                      GRP $local. : xValue TRTMNT $local. : trtgrp
|
|  COMPUTEBEFOREPAGEV  Specifies the value to be passed to               (Blank)
|  ARS                 %tu_display's ComputeBeforePageVars parameter.
|                      The variables specified here are directly
|                      associated wit
|                      Valid values: As defined for %tu_display
|                      For example:
|                      xCode trtcd
|
|  DDDATASETLABEL      Specifies the label to be applied to the DD       DD dataset for
|                      dataset                                           AE7 Listing
|                      Valid values: a non-blank text string
|
|  DEFAULTWIDTHS       This is a list of default widths for ALL columns  aesoc 27 aept 27
|                      and will usually be defined by the DD macro.      &g_trtgrp 17
|                      This parameter specifies column widths for all    tt_aenum 5
|                      variables not listed in                           tt_aesubjs 32
|                      Valid values: values of column names and numeric
|                      widths, a list of variables followed by a
|                      positive integer, e.g.
|
|                      defaultwidths = a b 10 c 12 d1-d4 6
|                      Numbered range lists are supported in this
|                      parameter however name range lists, name prefix
|                      lists, and special SAS name lists are not.
|                      Variables that are not given widths through
|                      either the WIDTHS or DEFAULTWIDTHS parameter
|                      will be width optimised using:
|                      MAX (variable's format width,
|                      width of column header) for variables that are
|                      NOT flowed or
|                      MIN(variable's format width,
|                      width of column header) for variable that ARE
|                      flowed.
|
|  DESCENDING          List of ORDERVARS that are given the PROC REPORT  tt_order1 tt_order2
|                      define statement attribute DESCENDING
|                      Valid values: one or more variable names from
|                      DSETIN that are also defined with ORDERVARS
|
|  DSETIN              The domain data set to act as the subject of the  ardata.ae
|                      report.
|                      Valid values: name of a data set meeting an IDSL
|                      domain-specific dataset specification
|
|  FLOWVARS            Variables to be defined with the flow option.     aesoc aept
|                      Valid values: one or more variable names from     tt_aesubjs
|                      DSETIN that are also defined with COLUMNS
|                      Flow variables should be given a width through
|                      the WIDTHS.  If a flow variable does not have a
|                      width specified the column width will be
|                      determined by
|                      MIN(variable's format width,
|                      width of  column header)
|
|  FORMATS             Variables and their format for display. For use   (Blank)
|                      where format for display differs to the format
|                      on the DSETIN.
|                      Valid values: values of column names and formats
|                      such as form valid syntax for a SAS FORMAT
|                      statement
|
|  GROUPBYVARS         Specifies the variables whose values define the   aesoc
|                      subgroup combinations for the analysis.           aept
|                      Valid values: A list of valid SAS variable names  &g_trtcd
|                      that exist in DSETIN.
|
|  IDVARS              Variables to appear on each page should the       aesoc aept
|                      report be wider than 1 page. If no value is
|                      supplied to this parameter then all displayable
|                      order variables will be defined as idvars
|                      Valid values: one or more variable names from
|                      DSETIN that are also defined with COLUMNS
|
|  LABELS              Variables and their label for display. For use    aept='System Organ
|                      where label for display differs to the label on   Class~   Preferred
|                      the DSETIN                                        Term'
|                      Valid values: pairs of variable names and labels
|                      with equals signs between them
|
|  LEFTVARS            Variables to be displayed as left justified       (Blank)
|                      Valid values: one or more variable names from
|                      DSETIN that are also defined with COLUMNS
|
|  LINEVARS            List of order variables that are printed with     (Blank)
|                      LINE statements in PROC REPORT
|                      Valid values: one or more variable names from
|                      DSETIN that are also defined with ORDERVARS
|                      These values shall be written with a BREAK
|                      BEFORE when the value of one of the variables
|                      change. The variables will automatically be
|                      defined as NOPRINT
|
|  NOPRINTVARS         Variables listed in the COLUMN parameter that     tt_order1 tt_order2
|                      are given the PROC REPORT define statement        &g_trtcd
|                      attribute noprint.
|                      Valid values: one or more variable names from
|                      DSETIN that are also defined with COLUMNS
|                      These variables are usually ORDERVARS used to
|                      control the order of the rows in the display.
|
|  NOWIDOWVAR          Variable whose values must be kept together on a  (Blank)
|                      page
|                      Valid values: names of one or more variables
|                      specified in COLUMNS
|
|  ORDERDATA           Variables listed in the ORDERVARS parameter that  (Blank)
|                      are given the PROC REPORT define statement
|                      attribute order=data.
|                      Valid values: one or more variable names from
|                      DSETIN that are also defined with ORDERVARS
|                      Variables not listed in ORDERFORMATTED,
|                      ORDERFREQ, or ORDERDATA are given the define
|                      attribute order=internal
|
|  ORDERFORMATTED      Variables listed in the ORDERVARS parameter that  (Blank)
|                      are given the PROC REPORT define statement
|                      attribute order=formatted.
|                      Valid values: one or more variable names from
|                      DSETIN that are also defined with ORDERVARS
|                      Variables not listed in ORDERFORMATTED,
|                      ORDERFREQ, or ORDERDATA are given the define
|                      attribute order=internal
|
|  ORDERFREQ           Variables listed in the ORDERVARS parameter that  (Blank)
|                      are given the PROC REPORT define statement
|                      attribute order=freq.
|                      Valid values: one or more variable names from
|                      DSETIN that are also defined with ORDERVARS
|                      Variables not listed in ORDERFORMATTED,
|                      ORDERFREQ, or ORDERDATA are given the define
|                      attribute order=internal
|
|  ORDERVARS           List of variables that will receive the PROC      tt_order1 aesoc
|                      REPORT define statement attribute ORDER           tt_order2 aept
|                      Valid values: one or more variable names from     &g_trtcd
|                      DSETIN that are also defined with COLUMNS
|
|  PAGEVARS            Variables whose change in value causes the        (Blank)
|                      display to continue on a new page
|                      Valid values: one or more variable names from
|                      DSETIN that are also defined with COLUMNS
|
|  POSTSUBSET          SAS expression to be applied to data immediately  (Blank)
|                      prior to creation of the permanent presentation
|                      dataset. Used for subsetting records required for
|                      computation but not for display.
|                      Valid values:
|                      Blank or A complete, syntactically valid SAS
|                      where or if statement for use in a data step
|
|  PROPTIONS           PROC REPORT statement options to be used in       Headline
|                      addition to MISSING.
|                      Valid values: proc report options
|                      The option 'Missing' can not be overridden.
|
|  RIGHTVARS           Variables to be displayed as right justified      (Blank)
|                      Valid values: one or more variable names from
|                      DSETIN that are also defined with COLUMNS
|
|  SHARECOLVARS        List of variables that will share print space.    aesoc aept
|                      The attributes of the last variable in the list
|                      define the column width and flow options
|                      Valid values: one or more variable names from
|                      DSETIN
|                      AE5 shows an example of this style of output
|                      The formatted values of the variables shall be
|                      written above each other in one column.
|
|  SHARECOLVARSINDENT  Indentation factor for ShareColVars. Stacked      2
|                      values shall be progressively indented by
|                      multiples of ShareColVarsIndent.
|                      REQUIRED when SHARECOLVARS is specified
|                      Valid values: positive integer
|
|  SKIPVARS            Variables whose change in value causes the        aept
|                      display to skip a line
|                      Valid values: one or more variable names from
|                      DSETIN that are also defined with COLUMNS
|
|  SPLITCHAR           Specifies the split character to be passed to     ~
|                      %tu_display
|                      Valid values: one single character
|
|  STACKVAR1           Specifies parameters to pass to %tu_stackvar in   (Blank)
|  STACKVAR15          order to stack variables together.  See Unit
|                      Specification for HARP Reporting Tools
|                      %TU_STACKVAR[4] for more detail regarding macro
|                      parameters that can be used in the macro call.
|                      DSETIN should not be specified
|
|  SUBJECTIDVARS       Variable(s) that contain subject IDs and/or       &g_subjid
|                      centre IDs. The centre ID should only be added
|                      when it needs to be displayed combining with the
|                      subject ID. The subject ID and centre can be
|                      given by the format 'subject ID' + {split
|                      character} + 'centre ID'. The split character
|                      will be used to separate the subject ID and
|                      centre ID in the display. If it is blank, the '/'
|                      will be used.
|                      Valid values:
|                      Name of one or more SAS variables that exists in
|                      &DSETIN
|
|  TRTCDVAR            Specify the name of the treatment code variable   &g_trtcd
|                      Valid values:
|                      Name of a SAS variables that exist in &DSETIN
|
|  TRTDECODEVAR        Specify the name of the treatment decode          &g_trtgrp
|                      variable. It is useful when &TRTFMT is blank,
|                      &TRTDECODEVAR should be displayed, and all
|                      treatments in the &DSETIN and/or POP data set
|                      should be displayed for each preferred term.
|                      Valid values:
|                      Blank or Name of a SAS variables that exist in
|                      &DSETIN
|
|  TRTFMT              Specify a format name for the treatment code      (Blank)
|                      variable &TRTCDVAR. If is useful when all
|                      treatments should be displayed in each preferred
|                      term, no matter there are subject(s) or not.
|                      Valid values:
|                      Blank or a SAS format name in the format
|                      searching path
|
|  VARLABELSTYLE       Specifies the style of labels to be applied by    SHORT
|                      the %tu_labelvars macro
|                      Valid values: as specified by %tu_labelvars,
|                      i.e. SHORT or STD
|
|  VARSPACING          Spacing for individual columns.                   (Blank)
|                      Valid values: variable name followed by a
|                      spacing value, e.g.
|                      Varspacing=a 1 b 2 c 0
|                      This parameter does NOT allow SAS variable
|                      lists.
|                      These values will override the overall
|                      COLSPACING parameter.
|                      VARSPACING defines the number of blank
|                      characters to leave between the column being
|                      defined and the column immediately to its left
|
|  WIDTHS              Variables and width to display.                   (Blank)
|                      Valid values: values of column names and numeric
|                      widths, a list of variables followed by a
|                      positive integer, e.g.
|
|                      widths = a b 10 c 12 d1-d4 6
|                      Numbered range lists are supported in this
|                      parameter however name range lists, name prefix
|                      lists, and special SAS name lists are not.
|                      Display layout will be optimised by default,
|                      however any specified widths will cause the
|                      default to be overridden.
|
|---------------------------------------------------------------------------------------
|  Output: 1. an output file in plain ASCII text format containing a report matching the
|             requirements specified as input parameters
|          2. the dataset that forms the foundation of the data display.
|---------------------------------------------------------------------------------------
|  Global macro variables created: None
|---------------------------------------------------------------------------------------
|  Macros called:
|
|  (@) tr_putlocals
|  (@) tu_abort
|  (@) tu_chkvarsexist
|  (@) tu_getdata
|  (@) tu_list
|  (@) tu_nobs
|  (@) tu_putglobals
|  (@) tu_tidyup
|---------------------------------------------------------------------------------------
| Change Log
|
| Modified by:             Yongwei Wang
| Date of modification:    26-May-2004
| New version number:      1/2
| Modification ID:         YW001
| Reason for modification: - Removed 'FORCE=' from the tu_abort call.
|                          - Added varsin=g_dddatasetname
|                          - Removed ';' from the fly-over text of PAGEVARS and SKIPVARS
|                          - Added fly-over text for NOWINDOWVARS
|---------------------------------------------------------------------------------------
| Change Log
|
| Modified by:             Yongwei Wang
| Date of modification:    27-May-2004
| New version number:      1/3
| Modification ID:         YW002
| Reason for modification: - Changed g_dddatasetname to g_analy_disp in tu_putglobals
|                          - Removed 'Utility' from the 'Design Stuyle' in the header.
|---------------------------------------------------------------------------------------
| Change Log
|
| Modified by:             Yongwei Wang
| Date of modification:    27-May-2004
| New version number:      1/4
| Modification ID:         YW003
| Reason for modification: - Changed &g_trtrcd and &g_trtgrp to &trtcdvar and 
|                            &trtdecodevar
|--------------------------------------------------------------------------------------*/

%MACRO td_ae7(
   BREAK1              =,            /* Break statements. */
   BREAK2              =,            /* Break statements. */
   BREAK3              =,            /* Break statements. */
   BREAK4              =,            /* Break statements. */
   BREAK5              =,            /* Break statements. */
   BYVARS              =,            /* By variables */
   CENTREVARS          =,            /* Centre justify variables */
   COLSPACING          =2,           /* Overall spacing value. */
   COLUMNS             =tt_order1 aesoc tt_order2 aept &g_trtcd &g_trtgrp tt_aenum tt_aesubjs, /* Column parameter */
   COMPUTEBEFOREPAGELINES=,          /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt colon labelvar) */
   COMPUTEBEFOREPAGEVARS=,           /* Names of variables that shall define the sort order for  Compute Before Page lines */
   DDDATASETLABEL      =DD dataset for AE7 Listing, /* Label to be applied to the DD dataset */
   DEFAULTWIDTHS       =aesoc 27 aept 27 &g_trtgrp 17 tt_aenum 5 tt_aesubjs 32, /* List of default column widths */
   DESCENDING          =tt_order1 tt_order2, /* Descending ORDERVARS */
   DSETIN              =ardata.ae,   /* Input domain dataset */
   FLOWVARS            =aesoc aept tt_aesubjs, /* Variables with flow option */
   FORMATS             =,            /* Format specification */
   GROUPBYVARS         =aesoc aept &g_trtcd, /* The variables whose values define the subgroup combinations for the analysis */
   IDVARS              =aesoc aept,  /* Variables to appear on each page */
   LABELS              =aept='System Organ Class~   Preferred Term', /* Label definitions. */
   LEFTVARS            =,            /* Left justify variables */
   LINEVARS            =,            /* Order variable printed with line statements. */
   NOPRINTVARS         =tt_order1 tt_order2 &g_trtcd, /* No print vars (usually used to order the display) */
   NOWIDOWVAR          =,            /* Variable whose values must be kept together on a page */
   ORDERDATA           =,            /* ORDER=DATA variables */
   ORDERFORMATTED      =,            /* ORDER=FORMATTED variables */
   ORDERFREQ           =,            /* ORDER=FREQ variables */
   ORDERVARS           =tt_order1 aesoc tt_order2 aept &g_trtcd, /* Order variables */
   PAGEVARS            =,            /* Break after <var> / page */
   POSTSUBSET          =,            /* SAS expression to be applied to data immediately prior to creation of the permanent presentation dataset */
   PROPTIONS           =Headline,    /* PROC REPORT statement options */
   RIGHTVARS           =,            /* Right justify variables */
   SHARECOLVARS        =aesoc aept,  /* Order variables that share print space. */
   SHARECOLVARSINDENT  =2,           /* Indentation factor */
   SKIPVARS            =aept,        /* Break after <var> / skip */
   SPLITCHAR           =~,           /* Split character */
   STACKVAR1           =,            /* Create Stacked variables (e.g. stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc= ) ) */
   STACKVAR10          =,            /* Create Stacked variables (e.g. stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc= ) ) */
   STACKVAR11          =,            /* Create Stacked variables (e.g. stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc= ) ) */
   STACKVAR12          =,            /* Create Stacked variables (e.g. stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc= ) ) */
   STACKVAR13          =,            /* Create Stacked variables (e.g. stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc= ) ) */
   STACKVAR14          =,            /* Create Stacked variables (e.g. stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc= ) ) */
   STACKVAR15          =,            /* Create Stacked variables (e.g. stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc= ) ) */
   STACKVAR2           =,            /* Create Stacked variables (e.g. stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc= ) ) */
   STACKVAR3           =,            /* Create Stacked variables (e.g. stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc= ) ) */
   STACKVAR4           =,            /* Create Stacked variables (e.g. stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc= ) ) */
   STACKVAR5           =,            /* Create Stacked variables (e.g. stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc= ) ) */
   STACKVAR6           =,            /* Create Stacked variables (e.g. stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc= ) ) */
   STACKVAR7           =,            /* Create Stacked variables (e.g. stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc= ) ) */
   STACKVAR8           =,            /* Create Stacked variables (e.g. stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc= ) ) */
   STACKVAR9           =,            /* Create Stacked variables (e.g. stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc= ) ) */
   SUBJECTIDVARS       =&g_subjid,   /* Variable(s) that contain subject IDs and/or centre IDs */
   TRTCDVAR            =&g_trtcd,    /* Name of the treatment code variable */
   TRTDECODEVAR        =&g_trtgrp,   /* Name of the treatment decode variable */
   TRTFMT              =,            /* Format of the variable &TRTCDVAR */
   VARLABELSTYLE       =SHORT,       /* Specifies the label style for variables (SHORT or STD) */
   VARSPACING          =,            /* Spacing for individual variables. */
   WIDTHS              =             /* Column widths */
   );

   /*
   / Print the version number, local and global macro variable to log.
   /--------------------------------------------------------------------*/

   %LOCAL MacroVersion;
   %LET MacroVersion=1;

   %INCLUDE "&g_refdata/tr_putlocals.sas";
   %tu_putglobals(varsin=G_ANALY_DISP)

   %LOCAL
      l_classnum
      l_classvars
      l_fmtdata
      l_fmtlib
      l_fmtsearch
      l_groupbyvars
      l_i
      l_len
      l_nobs
      l_prefix
      l_rc
      l_split
      l_subjfmts
      l_subjectidvars
      l_trtfmtfnd
      l_type
      l_var
      ;

   %LET l_prefix=_tdae7;

   %IF %NRBQUOTE(&G_ANALY_DISP) EQ D %THEN %GOTO DISPLAYIT;

   /*
   / Check if DSETIN, TRTCDVAR and GROUPBYVARS are blank
   /--------------------------------------------------------------------*/

   %IF %NRBQUOTE(&DSETIN) EQ %THEN %DO;
      %PUT %str(RTERR)OR: &sysmacroname: required parameter DSETIN is blank.;
      %GOTO macerr;
   %END;
   %IF %NRBQUOTE(&GROUPBYVARS) EQ %THEN %DO;
      %PUT %str(RTERR)OR: &sysmacroname: required parameter GROUPBYVARS is blank.;
      %GOTO macerr;
   %END;
   %IF %NRBQUOTE(&TRTCDVAR) EQ %THEN %DO;
      %PUT %str(RTERR)OR: &sysmacroname: required parameter TRTCDVAR is blank.;
      %GOTO macerr;
   %END;
   %IF %NRBQUOTE(&SUBJECTIDVARS) EQ %THEN %DO;
      %PUT %str(RTERR)OR: &sysmacroname: required parameter SUBJECTIDVARS is blank.;
      %GOTO macerr;
   %END;

   /*
   / Check if input data set exists
   /--------------------------------------------------------------------*/

   %LET l_nobs=%tu_nobs(&DSETIN);
   %IF &l_nobs LT 0 %THEN %DO;
      %PUT %str(RTERR)OR: &sysmacroname: input data set %str(&dsetin) does not exist.;
      %GOTO macerr;
   %END;

   /*
   / Check if variables given by GROUPBYVARS are in input data set
   /--------------------------------------------------------------------*/

   %LET l_rc=%tu_chkvarsexist(&DSETIN, &GROUPBYVARS);
   %IF &g_abort EQ 1 %THEN %GOTO macerr;

   %IF %NRBQUOTE(&l_rc) NE %THEN %DO;
      %PUT %str(RTERR)OR: &sysmacroname: variable &l_rc, given by GROUPBYVARS, is/are not in input dataset;
      %PUT %str(RTERR)OR: &sysmacroname: or value of the parameter is invalid. ;
      %GOTO macerr;
   %END;

   /*
   / Check if &SUBJECTIDVARS, &TRTCDVAR and &TRTDECODEVAR are in input 
   / data set
   / YW003: Changed &g_trtcd, &g_trtgrp to &trtcdvar and &trtdecodevar
   /--------------------------------------------------------------------*/

   %LET l_rc=%tu_chkvarsexist(&DSETIN, &trtcdvar &trtdecodevar );
   %IF &g_abort EQ 1 %THEN %GOTO macerr;

   %IF %NRBQUOTE(&l_rc) NE %THEN %DO;
      %PUT %str(RTERR)OR: &sysmacroname: treatment variable &l_rc is not in input dataset;
      %PUT %str(RTERR)OR: &sysmacroname: or value of the parameter is invalid. ;
      %GOTO macerr;
   %END;

   %LET l_i =1;
   %LET l_var=%scan(&SUBJECTIDVARS, &l_i);
   %DO %WHILE (%nrbquote(&l_var) NE);
      %LET l_rc=%tu_chkvarsexist(&DSETIN, &l_var);
      %IF &g_abort EQ 1 %THEN %GOTO macerr;

      %IF %NRBQUOTE(&l_rc) NE %THEN %DO;
         %PUT %str(RTERR)OR: &sysmacroname: Variable &l_rc given by parameter SUBJECTIDVARS is not in input dataset;
         %PUT %str(RTERR)OR: &sysmacroname: or value of the parameter is invalid. ;
         %GOTO macerr;
      %END;
      %LET l_i =%eval(&l_i + 1);
      %LET l_var=%scan(&SUBJECTIDVARS, &l_i);
   %END; %*** end of do-while loop ***;

   /*
   / Get the type of &TRTCDVAR and format of &SUBJECTIDVARS
   / Find split character between &SUBJECTIDVARS.
   /------------------------------------------------------------*/

   %LET l_split=;

   DATA _NULL_;
      IF 0 THEN SET &dsetin.;
      LENGTH tt_fmt $32761 tt_vars $32761 tt_splitchar $1;
      CALL SYMPUT('l_type', compress(upcase(vtype(&trtcdvar.))));

      %LET l_i=1;
      tt_fmt='';
      tt_vars='';
      tt_splitchar='-';
      %DO %WHILE(%scan(&SUBJECTIDVARS, &l_i) ne );
         IF vformat(%scan(&SUBJECTIDVARS, &l_i)) NE '' THEN
            tt_fmt=trim(left(tt_fmt))||' '||compress(vformat(%scan(&SUBJECTIDVARS, &l_i)));
         ELSE
            tt_fmt=trim(left(tt_fmt))||' '||'-';

         tt_vars=trim(left(tt_vars))||' '||trim(left("%scan(&SUBJECTIDVARS, &l_i)"));
         %LET l_i=%eval(&l_i + 1);
      %END;

      CALL SYMPUT('l_subjfmts', trim(left(tt_fmt)));
      CALL SYMPUT('l_subjectidvars', trim(left(tt_vars)));

      %IF %scan(&SUBJECTIDVARS, 2) NE %THEN %DO;

         tt_vars=trim(left(symget('SUBJECTIDVARS')));
         n=length(scan(tt_vars, 1));
         tt_splitchar=substr(tt_vars, n + 1, 1);
         IF tt_splitchar LE ' ' THEN tt_splitchar='/';

         CALL symput('l_split', tt_splitchar);

      %END; %*** end-if on second SUBJECTIDVARS is not blank ***;

      STOP;
   RUN;

   /*
   / Search format &trtfmt in the path given by SAS option
   / FMTSEARCH if &trtfmt is not blank
   /------------------------------------------------------------*/

   %LET l_trtfmtfnd=0;

   %IF %nrbquote(&trtfmt) NE %THEN %DO;
      %LET trtfmt=%scan(&trtfmt, 1, .);

      %*** get the format search path ***;
      %LET l_fmtsearch=%scan(%sysfunc(getoption(FMTSEARCH)), 1, %str(%(%)));
      %IF %sysfunc(indexw(%qupcase(&l_fmtsearch), LIBRARY)) EQ 0 %THEN
         %LET l_fmtsearch=LIBRARY &l_fmtsearch;
      %IF %sysfunc(indexw(%qupcase(&l_fmtsearch), WORK)) EQ 0 %THEN
         %LET l_fmtsearch=WORK &l_fmtsearch;

      %*** loop over the format search path to search TRTFMT ***;
      %LET l_i=1;
      %LET l_fmtlib=%scan(&l_fmtsearch, &l_i, %str(, ));

      %DO %WHILE (%nrbquote(&l_fmtlib) NE );
         %IF %index(&l_fmtlib, .) EQ 0 %THEN %LET l_fmtlib=&l_fmtlib..formats;
         %IF %sysfunc(exist(&l_fmtlib, CATALOG)) %THEN %DO;
            proc format library=&l_fmtlib cntlout=&l_prefix.fmt0(keep=start label type rename=(label=tt_trtfmt));
               select &TRTFMT ;
            run;
            %IF %tu_nobs(&l_prefix.fmt0) GT 0 %THEN %DO;
               %LET l_trtfmtfnd=1;
            %END;
         %END; %*** end of if on exist of l_fmtlib ***;

         %LET l_i=%eval(&l_i + 1);
         %LET l_fmtlib=%scan(&l_fmtsearch, &l_i, %str(, ));
      %END; %*** end do-while loop ***;

      %IF &l_trtfmtfnd EQ 0 %THEN %DO;
         %PUT %str(RTERR)OR: &sysmacroname: Can not find format &TRTFMT.. given by parameter TRTFMT ;
         %GOTO macerr;
      %END;

      %LET l_rc=0;

      DATA &l_prefix.fmt1;
         SET &l_prefix.fmt0;
         DROP type;

         IF upcase(type) NE "&l_type." THEN DO;
            CALL SYMPUT('l_rc', '1');
            STOP;
         END;

         %IF &l_type NE N %THEN %DO;
            RENAME start=&TRTCDVAR;
         %END;
         %ELSE %DO;
            &TRTCDVAR=start * 1;
         %END;

      RUN;

      %IF &l_rc EQ 1 %THEN %DO;
         %PUT %str(RTERR)OR: &sysmacroname: Format &trtfmt.. does not match the type of variable &TRTCDVAR given by TRTCDVAR;
         %GOTO macerr;
      %END;

   %END; %*** end if on TRTFMT is not blank ***;

   /*
   / Add &TRTCDVAR and &TRTDECODEVAR to GROUPBYVARS, if it is not in it
   /--------------------------------------------------------------------*/

   DATA _NULL_;
      LENGTH newgroupbyvars classvars $32761 var1 $32;
      groupbyvars=resolve(symget('groupbyvars'));
      newgroupbyvars=groupbyvars;

      IF indexw(upcase(groupbyvars), upcase("&trtcdvar.")) EQ 0 THEN DO;
         newgroupbyvars=trim(left(newgroupbyvars))||" "||left("&trtcdvar");
      END;
      IF indexw(upcase(groupbyvars), upcase("&trtdecodevar.")) EQ 0 THEN DO;
         newgroupbyvars=trim(left(newgroupbyvars))||" "||left("&trtdecodevar");
      END;

      i=1;
      classnum=0;
      var1=scan(groupbyvars, i, ' ');
      classvars='';

      DO WHILE (var1 NE '' );
         IF ( upcase(var1) NE upcase("&trtcdvar.")) AND ( upcase(var1) NE upcase("&trtdecodevar.")) THEN DO;
            classvars=trim(left(classvars))||" "||left(var1);
            classnum=classnum + 1;
         END;
         i=i+1;
         var1=scan(groupbyvars, i, ' ');
      END;

      CALL SYMPUT('l_groupbyvars', trim(left(newgroupbyvars)));
      CALL SYMPUT('l_classvars', trim(left(classvars)));
      CALL SYMPUT('l_classnum', trim(left(classnum)));

   RUN;

   /*
   / Call tu_getdata to subset the input data set and get population
   / data set
   /---------------------------------------------------------------------*/

   %tu_getdata(
      DSETIN=&dsetin,
      DSETOUT1=&l_prefix.analy,
      DSETOUT2=&l_prefix.pop
      )

   /*
   / If &TRTFMT is not find, try to create format from POP data set
   /--------------------------------------------------------------------*/

   %IF &l_trtfmtfnd EQ 0 %THEN %DO;

      %LET l_rc=%tu_chkvarsexist(&l_prefix.pop, &TRTCDVAR &TRTDECODEVAR);
      %IF &g_abort EQ 1 %THEN %GOTO macerr;

      %IF %nrbquote(&l_rc) EQ %THEN %DO;
         %LET l_trtfmtfnd=1;

         PROC FREQ DATA=&l_prefix.pop;
            TABLE &TRTCDVAR*&TRTDECODEVAR /list noprint
               out=&l_prefix.fmt1 (keep=&TRTCDVAR &TRTDECODEVAR
               %IF %nrbquote(&TRTDECODEVAR) ne %THEN %DO;
                  rename=(&TRTDECODEVAR=tt_trtfmt)
               %END;
               );
            WHERE &TRTCDVAR is not null;
         RUN;
      %END;
      %ELSE %DO;
         %PUT %str(RTNO)TE: &sysmacroname: Can not file &l_rc in POP data set. Treatment will be expended;
      %END;  %*** end-if on L_RC is blank ***;

   %END;  %*** end-if on L_TRTFMTFND=0 ***;

   /*
   / Get all categories of &TRTDCDVAR from input data set.
   /--------------------------------------------------------------------*/

   PROC SORT data=&dsetin nodupkey
      OUT=&l_prefix.fmt2(keep=&TRTCDVAR &TRTDECODEVAR) ;
      BY &TRTCDVAR &TRTDECODEVAR;
      WHERE &TRTCDVAR is not null;
   RUN;

   %LET l_fmtdata=&l_prefix.fmt2;

   /*
   / If &TRTFMT is find, merge all categroies
   /--------------------------------------------------------------------*/

   %IF &l_trtfmtfnd EQ 1 %THEN %DO;

      DATA &l_prefix.fmt;
         MERGE &l_prefix.fmt1 (in=a)
               &l_prefix.fmt2 (in=b);
         BY &TRTCDVAR;

         %IF %nrbquote(&TRTDECODEVAR) NE %THEN %DO;
            IF ( tt_trtfmt GT '' ) THEN DO;
               &TRTDECODEVAR=tt_trtfmt;
            END;
         %END;
      RUN;
      %LET l_fmtdata=&l_prefix.fmt;

   %END;  %*** end-if on L_TRTFMTFND=1 ***;

   /*
   / Remove duplicate &SUBJECTIDVARS.
   / Add subject count and subject list to data set
   /--------------------------------------------------------------------*/

   PROC SORT data=&l_prefix.analy OUT=&l_prefix.sort NODUPKEY;
      BY &l_groupbyvars &l_subjectidvars;
      WHERE %scan(&l_subjectidvars, -1) IS NOT NULL;
   RUN;

   DATA &l_prefix.change;
      SET &l_prefix.sort end=tt_end;
      BY &l_groupbyvars;
      LENGTH tt_aesubjs tt_tmp $32761 ;
      RETAIN tt_aelen tt_aenum tt_aesubjs;
      DROP tt_aelen tt_tmp;

      %LET l_i=1;
      %DO %WHILE(%scan(&l_subjectidvars, &l_i) ne );
         %*** Apply the format to the variables ***;
         %IF %scan(&l_subjfmts, &l_i, %str( )) NE %str(-) %THEN %DO;
            tt_tmp=put(%scan(&l_subjectidvars, &l_i),%scan(&l_subjfmts, &l_i, %str( )));
         %END;
         %ELSE %DO;
            tt_tmp=%scan(&l_subjectidvars, &l_i);
         %END;

         %*** Concatinate the subjectvars in each group together ***;
         %IF &l_i EQ 1 %THEN %DO;
            IF FIRST.%scan(&l_groupbyvars, -1) THEN DO;
               tt_aesubjs=trim(left(tt_tmp));
               tt_aenum=1;
            END;
            ELSE DO;
               tt_aesubjs=trim(left(tt_aesubjs))||", "||trim(left(tt_tmp));
               tt_aenum=tt_aenum + 1;
            END;
         %END;
         %ELSE %DO;
            tt_aesubjs=trim(left(tt_aesubjs))||"&l_split."||trim(left(tt_tmp));
         %END; %*** end-if on L_I=1 ***;

         %LET l_i=%eval(&l_i + 1);
      %END; %*** end of DO-WHILE over l_subjectidvars ***;

      tt_aelen=max(tt_aelen, length(trim(left(tt_aesubjs))));

      IF LAST.%scan(&l_groupbyvars, -1) THEN OUTPUT;

      IF tt_end THEN CALL SYMPUT('l_len', compress(tt_aelen));
   RUN;

   DATA &l_prefix.aerelen;
      LENGTH  tt_aesubjs $&l_len;
      SET &l_prefix.change ;
   RUN;

   /*
   / Combine &TRTCDVAR with &GROUPBYVARS
   /--------------------------------------------------------------------*/

   PROC SORT DATA=&l_fmtdata out=&l_prefix.merge1(KEEP=&trtcdvar &trtdecodevar) NODUPKEY;
      BY &trtcdvar &trtdecodevar;
   RUN;

   PROC SORT DATA=&l_prefix.aerelen out=&l_prefix.merge2(KEEP=&l_classvars) NODUPKEY;
      BY &l_classvars;
   RUN;

   PROC SQL;
      CREATE TABLE &l_prefix.merge3 AS
      SELECT &l_prefix.merge1.*, &l_prefix.merge2.*
      FROM &l_prefix.merge1, &l_prefix.merge2
      ;
   QUIT;

   /*
   / Merge all treatments into the data set.
   /--------------------------------------------------------------------*/

   PROC SORT DATA=&l_prefix.merge3;
      BY &l_groupbyvars;
   RUN;

   PROC SORT DATA=&l_prefix.aerelen out=&l_prefix.merge4;
      BY &l_groupbyvars;
   RUN;

   DATA &l_prefix.aerpt;
      MERGE &l_prefix.merge3 (in=in1)
            &l_prefix.merge4 (in=in2);
      BY &l_groupbyvars;

      %IF %nrbquote(&trtfmt) NE %THEN %DO;
         format &trtcdvar &trtfmt..;
      %END;

      IF in1 AND (NOT in2) THEN tt_aenum=0;

   RUN;

   /*
   / Add the total for each level in. The total variables will be used
   / as the order variable.
   /--------------------------------------------------------------------*/

   PROC summary DATA=&l_prefix.aerpt ;
      CLASS &l_classvars ;
      VAR tt_aenum;
      OUTPUT OUT=&l_prefix.sum(drop=_freq_) sum=sum ;
      TYPES
      %LET l_vars=;
      %DO l_i=1 %TO &l_classnum;
         %LET l_var=%scan(&l_classvars, &l_i, %str( ));
         %IF &l_i GT 1 %THEN %LET l_vars=&l_vars * &l_var;
         %ELSE %LET l_vars=&l_var;

         &l_vars
      %END;
      ;
   RUN;

   PROC SORT DATA=&l_prefix.sum OUT=&l_prefix.type(KEEP=_type_) NODUPKEY;
      BY _type_;
   RUN;

   DATA _NULL_;
      SET &l_prefix.type end=end;
      BY _type_;
      LENGTH tt_types $32761;
      RETAIN tt_types '';
      tt_types=trim(left(tt_types))||" "||trim(left(_type_));
      IF end THEN CALL SYMPUT('l_types',trim(left(tt_types)));
   RUN;

   %LET l_vars=;
   %DO l_i=1 %TO &l_classnum;
      %LET l_var=%scan(&l_classvars, &l_i, %str( ));
      %LET l_type=%scan(&l_types, &l_i, %str( ));
      %LET l_vars=&l_vars &l_var;

      DATA &l_prefix.aerpt;
         MERGE &l_prefix.aerpt
               &l_prefix.sum(where=(_type_=&l_type) keep=&l_vars sum _type_
                             rename=(sum=tt_order&l_i));
         drop _type_;
         BY &l_vars;

         IF tt_order&l_i GT 0;

      RUN;

   %END;

   /*
   / Apply the &postsubset to the final display data set.
   /--------------------------------------------------------------------*/

   DATA &l_prefix.subset;
      SET &l_prefix.aerpt;
      %unquote(&postsubset);
   RUN;

   /*
   / Call tu_list to create output.
   /--------------------------------------------------------------------*/

%DISPLAYIT:

   %tu_list(
      break1                  =&break1,
      break2                  =&break2,
      break3                  =&break3,
      break4                  =&break4,
      break5                  =&break5,
      byvars                  =&byVars,
      centrevars              =&centreVars,
      colspacing              =&colSpacing,
      columns                 =&columns,
      computebeforepagelines  =&computeBeforePageLines,
      computebeforepagevars   =&computeBeforePageVars,
      dddatasetlabel          =&dddatasetlabel,
      defaultwidths           =&defaultWidths,
      descending              =&descending,
      dsetin                  =&l_prefix.subset,
      display                 =Y,
      flowvars                =&flowVars,
      formats                 =&formats,
      getdatayn               =N,
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
      overallsummary          =N,
      pagevars                =&pageVars,
      proptions               =&proptions,
      rightVars               =&rightVars,
      sharecolvars            =&sharecolvars,
      sharecolvarsindent      =&sharecolvarsindent,
      skipvars                =&skipVars,
      splitChar               =&splitChar,
      stackvar1               =&stackvar1,
      stackvar10              =&stackvar1,
      stackvar11              =&stackvar1,
      stackvar12              =&stackvar1,
      stackvar13              =&stackvar1,
      stackvar14              =&stackvar1,
      stackvar15              =&stackvar1,
      stackvar2               =&stackvar2,
      stackvar3               =&stackvar3,
      stackvar4               =&stackvar4,
      stackvar5               =&stackvar5,
      stackvar6               =&stackvar6,
      stackvar7               =&stackvar7,
      stackvar8               =&stackvar8,
      stackvar9               =&stackvar9,
      varlabelstyle           =&varlabelstyle,
      varspacing              =&varSpacing,
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

   %IF &g_debug NE 0 %THEN %GOTO EXITMAC;

   %tu_abort()

%ENDMAC:

   /*
   / Call tu_tideup to clear temporary data set and files.
   /---------------------------------------------------------------------*/

   %tu_tidyup(
      RMDSET =&L_PREFIX:,
      GLBMAC=NONE
      )

%MEND td_ae7;
