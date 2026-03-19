/*
| Macro Name:         td_liver2
|
| Macro Version:      1
|
| SAS Version:        8
|
| Created By:         Yongwei Wang
|
| Date:               18May2007
|
| Macro Purpose:      A macro to create table with a summary statistics for the time
|                     from the start of study treatment to the liver event and the
|                     time from the most recent study treatment to the liver event.
|
| Macro Design:       Procedure style.
|
| Input Parameters:
|
| Name                Description                                  Default
| -----------------------------------------------------------------------------------
| SEGMENT1            Each segment shall contain a call to either  %str(dsetindenom=&
|                     tu_freq or tu_sumstatsinrows and             g_popdata,groupByV
|                     appropriate parameters for              the  arsNumer=&g_trtcd,
|                     macro to create an output dataset. The       POSTSUBSET=tt_sego
|                     percentage sign shall not be used as a       rder=1;tt_grplabel
|                     prefix to the macro name, and the            ='';tt_code1='1';t
|                     parameters shall not be surrounded by        t_decode1='Subject
|                     brackets, i.e. the following style shall     s reporting at
|                     be used:  segment1=MacroName                 least one liver
|                     parm1=value1, parm2=value2                   event')
|                     Valid values: A complete call to tu_freq or
|                     ru_sumstatsinrows
|
| SEGMENT2            Same as SEGMENT1                             %str(dsetindenom=&
|                                                                  g_popdata,groupByV
|                                                                  arsNumer=&g_trtcd
|                                                                  rustrtpt,POSTSUBSE
|                                                                  T=tt_segorder=1;tt
|                                                                  _grplabel='';tt_co
|                                                                  de1='2';tt_decode1
|                                                                  =rustrtpt;if
|                                                                  rustrtpt='AFTER'
|                                                                  then
|                                                                  tt_code1='3',PSFOR
|                                                                  MAT=&g_trtcd
|                                                                  &g_trtfmt
|                                                                  rustrtpt
|                                                                  $rustrpt.)
|
| SEGMENT3            Same as SEGMENT1                             %str(dsetin=ardata
|                                                                  .rucam(where=(rute
|                                                                  stcd eq
|                                                                  'AGE55')),analy
|                                                                  sisvars=rutrt1st,
|                                                                  DSETOUT=segment3_o
|                                                                  ut,groupByVarsanal
|                                                                  y=&g_trtcd)
|
| SEGMENT4            Same as SEGMENT1                             %str(dsetin=ardata
|                                                                  .rucam(where=(rute
|                                                                  stcd eq
|                                                                  'AGE55')),analy
|                                                                  sisvars=rutrtst,
|                                                                  DSETOUT=segment4_o
|                                                                  ut,groupByVarsanal
|                                                                  y=&g_trtcd)
|
| SEGMENT5-SEGMENT20  Same as SEGMENT1                             (Blank)
|
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
| ALIGNYN             Execute %tu_align macro: Yes or No           Y
|                     Valid values: Y or N
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
| COLSPACING          The value of the between-column spacing.     2
|                     Valid values: positive integer
|
| COLUMNS             A PROC REPORT column statement               tt_segorder
|                     specification.  Including spanning titles    tt_grplabel
|                     and variable names                           tt_code1
|                     Valid values: one or more variable names     tt_decode1 tt_ac:
|                     from DSETIN plus other elements of valid
|                     PROC REPORT COLUMN statement syntax, but
|                     not including report_item=alias syntax
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
|                     &G_TRTGRP
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
| DDDATASETLABEL      Specifies the label to be applied to the DD  DD dataset for
|                     dataset                                      LIVER2 table
|                     Valid values: a non-blank text string
|
| DEFAULTWIDTHS       This is a list of default widths for ALL     tt_decode1 62
|                     columns and will usually be defined by the   tt_grplabel 62
|                     DD macro.  This parameter specifies column   tt_ac: 20
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
| DSETIN              Specifies the name of the input dataset      (Blank)
|                     Valid values: name of an existing dataset,
|                     pre-sorted by BYVARS
|
| DSETOUT             Name of output dataset                       (Blank)
|                     Valid values: Blank or A valid SAS dataset
|                     name
|
| DISPLAY             Specifies whether the report should be       Y
|                     created.
|                     Valid values: Y or N
|
| FLOWVARS            Variables to be defined with the flow        tt_decode1
|                     option.                                      tt_grplabel
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
| FORMATS             Variables and their format for display. For  tt_decode1
|                     use where format for display differs to the  $rustrpt.
|                     format on the DSETIN.
|                     Valid values: values of column names and
|                     formats such as form valid syntax for a SAS
|                     FORMAT statement
|
| IDVARS              Variables to appear on each page should the  tt_code1
|                     report be wider than 1 page. If no value is  tt_decode1
|                     supplied to this parameter then all          tt_segorder
|                     displayable order variables will be defined  tt_grplabel
|                     as idvars
|                     Valid values: one or more variable names
|                     from DSETIN that are also defined with
|                     COLUMNS
|
| LABELS              Variables and their label for display. For   tt_decode1='~'
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
| NOPRINTVARS         Variables listed in the COLUMN parameter     tt_segorder
|                     that are given the PROC REPORT define        tt_code1
|                     statement attribute noprint.
|                     Valid values: one or more variable names
|                     from DSETIN that are also defined with
|                     COLUMNS
|                     These variables are usually ORDERVARS used
|                     to control the order of the rows in the
|                     display.
|
| NOWIDOWVAR          Variable whose values must be kept together  tt_grplabel
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
| ORDERVARS           List of variables that will receive the      tt_segorder
|                     PROC REPORT define statement attribute       tt_grplabel
|                     ORDER                                        tt_code1
|                     Valid values: one or more variable names     tt_decode1
|                     from DSETIN that are also defined with
|                     COLUMNS
|
| OVERALLSUMMARY      Causes the macro to produce an overall       Y
|                     summaryline. Use with ShareColVars.
|                     Valid values: Y or N
|                     The values are not alculated - they must be
|                     supplied in a special record in the ataset.
|                     The special record is identified by the
|                     fact that the value for all of the order
|                     variables must be the same for the
|                     permutation with the lowest sort order (as
|                     resulting from COLUMN and ORDER), i.e. the
|                     first report row
|
| PAGEVARS            Variables whose change in value causes the   (Blank)
|                     display to continue on a new page
|                     Valid values: one or more variable names
|                     from DSETIN that are also defined with
|                     COLUMNS
|
| POSTSUBSET          SAS expression to be applied to data         %str(if tt_segorder  
|                     immediately prior to creation of the         eq 4 then tt_grplabel
|                     permanent presentation dataset. Used for     =trim(tt_grplabel)||
|                     subsetting records required for computation  '#';if tt_segorder  
|                     but not for display.                         gt 2 then tt_decode1=
|                     Valid values: Blank or a complete,           '  '||tt_decode1)
|                     syntactically valid SAS where or if
|                     statement for use in a data step
|
| PROPTIONS           PROC REPORT statement options to be used in  headline
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
| SHARECOLVARS        List of variables that will share print      tt_grplabel
|                     space. The attributes of the last variable   tt_decode1
|                     in the list define the column width and
|                     flow options
|                     Valid values: one or more variable names
|                     from DSETIN
|                     AE5 shows an example of this style of
|                     output
|                     The formatted values of the variables shall
|                     be written above each other in one column.
|
| SHARECOLVARSINDENT  Indentation factor for ShareColVars.         0
|                     Stacked values shall be progressively
|                     indented by multiples of
|                     ShareColVarsIndent.
|                     REQUIRED when SHARECOLVARS is specified
|                     Valid values: positive integer
|
| SKIPVARS            Variables whose change in value causes the   tt_grplabel
|                     display to skip a line
|                     Valid values: one or more variable names
|                     from DSETIN that are also defined with
|                     COLUMNS
|
| SPLITCHAR           Specifies the split character to be passed   ~
|                     to %tu_display
|                     Valid values: one single character
|
| VARLABELSTYLE       Specifies the style of labels to be applied  STD
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
|
| XMLDEFAULTS         Specifies a XML file which defined           &g_refdata./tr_liv
|                     parameter values of %tu_freq or              er2_defaults.xml
|                     %tu_sumstatsinrows for each segments or all
|                     segments
|                     Valid values: Blank or an existing XML file
|                     with LIVER2 table.
|-------------------------------------------------------------------------------
| Output:
|   1. Summary table output
|   2. Display dataset (DD dataset) used as the foundation of the frequency
|      table output.
|   3. Data set before creating table output
|-------------------------------------------------------------------------------
| Global macro variables created: NONE
|-------------------------------------------------------------------------------
| Macros called:
|(@) tr_putlocals
|(@) tu_abort
|(@) tu_chkvarsexist
|(@) tu_multisegments
|(@) tu_nobs
|(@) tu_putglobals
|(@) tu_tidyup
|-------------------------------------------------------------------------------
| Example:
|    %td_liver2()
|-------------------------------------------------------------------------------
| Change Log
|
| Modified By:
| Date of Modification:
| New version number:
| Modification ID:
| Reason For Modification:
|-----------------------------------------------------------------------------*/

%macro td_liver2 (
   SEGMENT1            =%str(dsetindenom=&g_popdata,groupByVarsNumer=&g_trtcd,POSTSUBSET=tt_segorder=1;tt_grplabel='';tt_code1='1';tt_decode1='Subjects reporting at least one liver event'), /* Same as SEGMENT12 */
   SEGMENT2            =%str(dsetindenom=&g_popdata,groupByVarsNumer=&g_trtcd rustrtpt,POSTSUBSET=tt_segorder=1;tt_grplabel='';tt_code1='2';tt_decode1=rustrtpt;if rustrtpt='AFTER' then tt_code1='3',PSFORMAT=&g_trtcd &g_trtfmt rustrtpt $rustrpt.),
   SEGMENT3            =%str(dsetin=ardata.rucam(where=(rutestcd eq 'AGE55')),analysisvars=rutrt1st, DSETOUT=segment3_out,groupByVarsanaly=&g_trtcd), /* Same as SEGMENT6 */
   SEGMENT4            =%str(dsetin=ardata.rucam(where=(rutestcd eq 'AGE55')),analysisvars=rutrtst, DSETOUT=segment4_out,groupByVarsanaly=&g_trtcd), /* Same as SEGMENT6 */
   SEGMENT5            =,                  /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   SEGMENT6            =,                  /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   SEGMENT7            =,                  /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   SEGMENT8            =,                  /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   SEGMENT9            =,                  /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   SEGMENT10           =,                  /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   SEGMENT11           =,                  /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   SEGMENT12           =,                  /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   SEGMENT13           =,                  /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   SEGMENT14           =,                  /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   SEGMENT15           =,                  /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   SEGMENT16           =,                  /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   SEGMENT17           =,                  /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   SEGMENT18           =,                  /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   SEGMENT19           =,                  /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   SEGMENT20           =,                  /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   ACROSSVAR           =&g_trtcd,          /* Variable(s) that will be transposed to columns */
   ACROSSVARDECODE     =&g_trtgrp,         /* The name of the decode variable(s) for ACROSSVAR */
   ALIGNYN             =Y,                 /* Control execution of tu_align */
   BREAK1              =,                  /* Break statements. */
   BREAK2              =,                  /* Break statements. */
   BREAK3              =,                  /* Break statements. */
   BREAK4              =,                  /* Break statements. */
   BREAK5              =,                  /* Break statements. */
   BYVARS              =,                  /* By variables */
   CENTREVARS          =,                  /* Centre justify variables */
   COLSPACING          =2,                 /* Overall spacing value. */
   COLUMNS             =tt_segorder tt_grplabel tt_code1 tt_decode1 tt_ac:, /* Column parameter */
   COMPUTEBEFOREPAGELINES=,                /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt colon labelvar) */
   COMPUTEBEFOREPAGEVARS=,                 /* Computed by variables. */
   DDDATASETLABEL      =DD dataset for LIVER2 table, /* Label to be applied to the DD dataset */
   DEFAULTWIDTHS       =tt_decode1 62 tt_grplabel 62 tt_ac: 20, /* List of default column widths */
   DESCENDING          =,                  /* Descending ORDERVARS */
   DSETIN              =,                  /* Input dataset */
   DSETOUT             =,                  /* Name of output dataset */
   DISPLAY             =Y,                 /* Specifies whether the report should be created */
   FLOWVARS            =tt_decode1 tt_grplabel, /* Variables with flow option */
   FORMATS             =tt_decode1 $rustrpt., /* Format specification */
   IDVARS              =tt_code1 tt_decode1 tt_segorder tt_grplabel, /* Variables to appear on each page should the report be wider than 1 page */
   LABELS              =tt_decode1='~',    /* Label definitions. */
   LEFTVARS            =,                  /* Left justify variables */
   LINEVARS            =,                  /* Order variable printed with line statements. */
   NOPRINTVARS         =tt_segorder tt_code1, /* No print vars (usually used to order the display) */
   NOWIDOWVAR          =tt_grplabel,       /* Variable whose values must be kept together on a page */
   ORDERDATA           =,                  /* ORDER=DATA variables */
   ORDERFORMATTED      =,                  /* ORDER=FORMATTED variables */
   ORDERFREQ           =,                  /* ORDER=FREQ variables */
   ORDERVARS           =tt_segorder tt_grplabel tt_code1 tt_decode1, /* Order variables */
   OVERALLSUMMARY      =Y,                 /* Overall summary line at top of tables */
   PAGEVARS            =,                  /* Break after <var> / page; */
   POSTSUBSET          =%str(if tt_segorder eq 4 then tt_grplabel=trim(tt_grplabel)||'#'; if tt_segorder gt 2 then tt_decode1='  '||tt_decode1), 
   PROPTIONS           =headline,          /* PROC REPORT statement options */
   RIGHTVARS           =,                  /* Right justify variables */
   SHARECOLVARS        =tt_grplabel tt_decode1, /* Order variables that share print space. */
   SHARECOLVARSINDENT  =0,                 /* Indentation factor */
   SKIPVARS            =tt_grplabel,       /* Break after <var> / skip; */
   SPLITCHAR           =~,                 /* Split character */
   VARLABELSTYLE       =STD,               /* Specifies the label style for variables (SHORT or STD) */   
   VARSPACING          =,                  /* Spacing for individual variables. */
   WIDTHS              =,                  /* Column widths */
   XMLDEFAULTS         =&g_refdata./tr_liver2_defaults.xml, /* Location and name of XML defaults file */
   );

   /*
   / Write details of macro call to log
   /----------------------------------------------------------------------*/

   %local MacroVersion;
   %let MacroVersion=1;

   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals()

   /*
   / Define local variables
   /----------------------------------------------------------------------*/

   %local l_prefix l_i l_segment l_flag;
   %let l_prefix=_tdliver2;
   %let l_flag=1;

   /*
   / Parameter validatoin
   --------------------------------------------------------------------------*/

   %if %nrbquote(&xmldefaults) ne %then
   %do;
      %if %sysfunc(fileexist(&xmldefaults)) eq 0 %then %let l_flag=0;
   %end;
   %else %let l_flag=0;

   %if &l_flag %then
   %do;
      libname _liver2 xml "&xmldefaults";
      proc sql noprint;
         select count(memname) into :l_flag
         from dictionary.tables
         where libname eq '_LIVER2' and memname eq 'LIVER2'
         ;
      quit;
      %if not &l_flag %then
      %do;
         libname _liver2 clear;
      %end;
   %end;

   %if &l_flag %then
   %do;
      data &l_prefix.xml;
         set _liver2.liver2;
      run;

      libname _liver2 clear;

      %if %tu_chkvarsexist(&l_prefix.xml, TYPE NAME VALUE) ne %then
      %do;
         %put %str(RTE)RROR: &sysmacroname: TYPE, NAME and VALUE are required variables in XMLDEFAULTS(=&xmldefaults).;
         %goto macerr;
      %end;
      data &l_prefix.xml;
         set &l_prefix.xml;
         where substr(upcase(type), 1, 7) = 'SEGMENT';
      run;
      %if %tu_nobs(&l_prefix.xml) le 0 %then %let l_flag=0;
   %end;

   /*
   / Normal Process
   --------------------------------------------------------------------------*/

   /*
   / Get paramter names for each segment from SEGMENT? parameters
   --------------------------------------------------------------------------*/

   %if &l_flag %then %do l_i = 1 %to 20;
      data &l_prefix.ds&l_i;
         length parm parm1 $32761 NAME $64;
         keep name;
         parm=resolve(symget("segment&l_i"));
         rx1=rxparse("',' $w* ($n$c* $w*) '='") ;
         rx2=rxparse("$(10) to ' '");

         call rxchange(rx2,999, parm, parm1);

         do while (parm1 ne '');
            call rxsubstr(rx1, parm1, pos, len);
            if pos gt 0 and len gt 0 then
            do;
               name=scan(substr(parm1, 1, pos), 1, '=');
               parm1=substr(parm1, pos + 1);
            end;
            else do;
               name=scan(parm1, 1, '=');
               parm1='';
            end;
            output;
         end;

         call rxfree(rx1);
         call rxfree(rx2);
      run;

   /*
   / Combine SEGMENT? parameters with parameters in XML file for a specific
   / segement to construct new SEGMENT? parameters
   --------------------------------------------------------------------------*/

      %let l_segment=;

      proc sql noprint;
         select compress(name) || ' = ' || trim(left(value)) into :l_segment
         separated by ","
         from &l_prefix.xml
         where (upcase(type) eq "SEGMENT&l_i")
         and ( upcase(name) notin (select upcase(name) from &l_prefix.ds&l_i))
         ;
      quit;

      %if %nrbquote(&l_segment) eq or %nrbquote(&&&segment&l_i) eq %then
         %let segment&l_i=%nrbquote(&&&segment&l_i..&l_segment);
      %else
         %let segment&l_i=%nrbquote(&&&segment&l_i..,&l_segment);
   %end;

   /*
   / Call %tu_multisegments to creat final output
   /-----------------------------------------------------------------------*/

   %tu_multisegments(
       acrossColVarPrefix     =tt_ac
      ,acrossvar              =&acrossvar
      ,acrossvardecode        =&acrossvardecode
      ,acrossVarListName      =_acrossVarList
      ,addbignyn              =Y
      ,alignyn                =&alignyn
      ,break1                 =&break1
      ,break2                 =&break2
      ,break3                 =&break3
      ,break4                 =&break4
      ,break5                 =&break5
      ,byvars                 =&byvars
      ,centrevars             =&centrevars
      ,colspacing             =&colspacing
      ,columns                =&columns
      ,computebeforepagelines =&computebeforepagelines
      ,computebeforepagevars  =&computebeforepagevars
      ,dddatasetlabel         =&dddatasetlabel
      ,ddname                 =liver2
      ,defaultwidths          =&defaultwidths
      ,denormyn               =Y
      ,descending             =&descending
      ,display                =&display
      ,dsetin                 =&dsetin
      ,dsetout                =&dsetout
      ,flowvars               =&flowvars
      ,formats                =&formats
      ,idvars                 =&idvars
      ,labels                 =&labels
      ,labelvarsyn            =Y
      ,leftvars               =&leftvars
      ,linevars               =&linevars
      ,noprintvars            =&noprintvars
      ,nowidowvar             =&nowidowvar
      ,orderdata              =&orderdata
      ,orderformatted         =&orderformatted
      ,orderfreq              =&orderfreq
      ,ordervars              =&ordervars
      ,overallsummary         =&overallsummary
      ,pagevars               =&pagevars
      ,postsubset             =&postsubset
      ,proptions              =&proptions
      ,rightvars              =&rightvars
      ,segment1               =&segment1
      ,segment2               =&segment2
      ,segment3               =&segment3
      ,segment4               =&segment4
      ,segment5               =&segment5
      ,segment6               =&segment6
      ,segment7               =&segment7
      ,segment8               =&segment8
      ,segment9               =&segment9
      ,segment10              =&segment10
      ,segment11              =&segment11
      ,segment12              =&segment12
      ,segment13              =&segment13
      ,segment14              =&segment14
      ,segment15              =&segment15
      ,segment16              =&segment16
      ,segment17              =&segment17
      ,segment18              =&segment18
      ,segment19              =&segment19
      ,segment20              =&segment20
      ,sharecolvars           =&sharecolvars
      ,sharecolvarsindent     =&sharecolvarsindent
      ,skipvars               =&skipvars
      ,splitchar              =&splitchar
      ,stackvar1              =
      ,stackvar2              =
      ,stackvar3              =
      ,stackvar4              =
      ,stackvar5              =
      ,stackvar6              =
      ,stackvar7              =
      ,stackvar8              =
      ,stackvar9              =
      ,stackvar10             =
      ,stackvar11             =
      ,stackvar12             =
      ,stackvar13             =
      ,stackvar14             =
      ,stackvar15             =
      ,varlabelstyle          =&varlabelstyle
      ,varspacing             =&varspacing
      ,varstodenorm           =tt_result
      ,widths                 =&widths
      ,xmldefaults            =&xmldefaults
      ,yndecodefmt            =$yndecod.
      ,ynorderfmt             =$ynorder.
      ,ynvars                 =
      );

   %goto endmac;

%MACERR:
   %let g_abort=1;
   %tu_abort()

%ENDMAC:
   %tu_tidyup(
      RMDSET =&L_PREFIX:,
      GLBMAC =NONE
      );

%mend td_liver2;
