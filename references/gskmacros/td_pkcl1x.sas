/*-----------------------------------------------------------------------------------
|
|  Macro name:      td_pkcl1x.sas
|
|  Macro version:   1
|
|  SAS version:     8.2
|
|  Created by:      Trevor Welby
|
|  Date:            15th December 2004
|
|  Macro purpose:   Display macro to generate IDSL PKCL1X listing 
|                   (CROSS-OVER STUDY)
|
|  Macro design:    Procedure style
|
|
|  Input parameters:
|
|  Name             Description                                         Default
|
|  DSETIN           The PK Concentrations dataset meeting               ardata.pkcnc (Req)
|                   IDSL dataset specification for PKCNC data
|
|  STACKVAR1        Specifies any variables that should be stacked      (Opt)     
|  - STACKVAR15     together.  See Unit Specification for HARP                        
|                   Reporting Tools TU_STACKVAR[5] for more detail                    
|                   regarding macro parameters that can be used in                    
|                   the macro call.  Note that the DSETIN parameter                    
|                   will be passed by %tu_list and should not be
|                   provided here.
|
|  VARLABELSTYLE    Specifies the style of labels to be applied by      short (Req)
|                   the %tu_labelvars macro Valid values: as
|                   specified by %tu_labelvars, i.e. SHORT or STD
|
|  DDDATASETLABEL   Specifies the label to be applied to the            DD dataset for 
|                   DD dataset Valid values: a non-blank text           pkcl1x listing (Req)
|                   string
|
|  SPLITCHAR        Specifies the split character to be passed to       ~ (Req)
|                   %tu_display Valid values: one single character
|
|  COMPUTEBEFORE-
|  PAGELINES        See Unit Specification for HARP Reporting Tools     blank (Opt)
|                   TU_LIST[4] for complete details.
|
|  COMPUTEBEFORE-   See Unit Specification for HARP Reporting Tools     blank (Opt)
|  PAGEVARS         TU_LIST[4] for complete details.
|
|  COLUMNS          A PROC REPORT column statement specification.       &g_subjid   
|                   Including spanning titles and variable names        &g_ptrtcd &g_ptrtgrp [TQW9753.01-002] 
|                   Valid values: one or more variable names from       pernum period
|                   DSETIN plus other elements of valid PROC REPORT     pcstdt pcsttm ptm ptmnum
|                   COLUMN statement syntax                             pcsttmdv pcatmnum result (Req)
|
|  ORDERVARS        List of variables that will receive the PROC        &g_subjid pernum period
|                   REPORT define statement attribute ORDER Valid       &g_ptrtcd &g_ptrtgrp  [TQW9753.01-002] 
|                   values: one or more variable names from DSETIN      pcstdt ptmnum (Req)
|                   that are also defined with COLUMNS
|
|  SHARECOLVARS     List of variables that will share print space.      blank (Opt)
|                   The attributes of the last variable in the list
|                   define the column width and flow options Valid
|                   values: one or more variable names from DSETIN
|                   AE5 shows an example of this style of output
|                   The formatted values of the variables shall be
|                   written above each other in one column.
|  
|  SHARECOLVARS-    Indentation factor for ShareColVars. Stacked        2 (Req)
|  INDENT           values shall be progressively indented by
|                   multiples of ShareColVarsIndent Valid values:
|                   positive integer                                    
|
|  LINEVARS         List of order variables that are printed with       blank (Opt)
|                   LINE statements in PROC REPORT Valid values: one
|                   or more variable names from DSETIN that are also
|                   defined with ORDERVARS These values shall be
|                   written with a BREAK BEFORE when the value of
|                   one of the variables change. The variables will
|                   automatically be defined as NOPRINT
|
|  DESCENDING       List of ORDERVARS that are given the PROC           blank (Opt)
|                   REPORT define statement attribute DESCENDING
|                   Valid values: one or more variable names from
|                   DSETIN that are also defined with ORDERVARS
|
|  ORDERFORMATTED   Variables listed in the ORDERVARS parameter         blank (Opt)
|                   that are given the PROC REPORT define statement
|                   attribute order=formatted.  Valid values: one
|                   or more variable names from DSETIN that are
|                   also defined with ORDERVARS Variables not
|                   listed in ORDERFORMATTED, ORDERFREQ, or
|                   ORDERDATA are given the define attribute
|                   order=internal
|
|  ORDERFREQ        Variables listed in the ORDERVARS parameter         blank (Opt)
|                   that are given the PROC REPORT define statement
|                   attribute order=freq. Valid values: one or more
|                   variable names from DSETIN that are also
|                   defined with ORDERVARS Variables not listed in
|                   ORDERFORMATTED, ORDERFREQ, or ORDERDATA are
|                   given the define attribute order=internal
|
|  ORDERDATA        Variables listed in the ORDERVARS parameter         blank (Opt)
|                   that are given the PROC REPORT define statement
|                   attribute order=data. Valid values: one or more
|                   variable names from DSETIN that are also defined
|                   with ORDERVARS Variables not listed in
|                   ORDERFORMATTED, ORDERFREQ, or ORDERDATA are
|                   given the define attribute order=internal
|
|  NOPRINTVARS      Variables listed in the COLUMN parameter that        
|                   are given the PROC REPORT define statement          &g_ptrtcd ptmnum (Req) [TQW9753.01-002] 
|                   attribute noprint. Valid values: one or more
|                   variable names from DSETIN that are also
|                   defined with COLUMNS These variables are
|                   ORDERVARS used to control the order of the
|                   rows in the display.
|
|  BYVARS           By variables. The variables listed here are         blank (Opt)
|                   processed as standard SAS by variables Valid
|                   values: one or more variable names from DSETIN
|                   No formatting of the display for these variables
|                   is performed by %tu_display.  The user has the
|                   option of the standard SAS BY line, or using
|                   OPTIONS NOBYLINE and #BYVAL #BYVAR directives
|                   in title statements.
|
|  FLOWVARS         Variables to be defined with the flow option        blank (Opt)
|                   Valid values: one or more variable names from
|                   DSETIN that are also defined with COLUMNS
|                   Flow variables should be given a width through
|                   the WIDTHS.  If a flow variable does not have
|                   a width specified the column width will be
|                   determined by MIN (variable's format width,
|                   width of  column header).
|
|  WIDTHS           Variables and width to display Valid values:        &g_subjid 7 &g_ptrtgrp 15 [TQW9753.01-002] 
|                   values of column names and numeric widths, a        period 8 pcstdt 8 pcsttm 6
|                   list of variables followed by a positive            ptm 9 pcsttmdv 5
|                   integer, e.g. widths = a b 10 c 12 d1-d4 6          pcatmnum 9 result 15 (Req)
|                   Numbered range lists are supported in this
|                   parameter however name range lists, name prefix
|                   lists, and special SAS name lists are not.
|                   Display layout will be optimised by default,
|                   however any specified widths will cause the
|                   default to be overridden.
|
|  DEFAULTWIDTHS    Specifies column widths for all variables not       blank (Opt)
|                   listed in the WIDTHS parameter Valid values:
|                   values of column names and numeric widths such
|                   as form valid syntax for a SAS LENGTH statement
|                   For variables that are not given widths through
|                   either the WIDTHS or DEFAULTWIDTHS parameter will
|                   be width optimised using: MAX (variable?'s format
|                   width, width of column header)
|
|  SKIPVARS         Variables whose change in value causes the display  pcstdt 
|                   to skip a line Valid values: one or more variable   (Req)
|                   names from DSETIN that are also defined with
|                   COLUMNS
|
|  PAGEVARS         Variables whose change in value causes the          blank (Opt)
|                   display to continue on a new page Valid
|                   values: one or more variable names from
|                   DSETIN that are also defined with COLUMNS
|
|  IDVARS           Variables to appear on each page should the         blank (Opt)
|                   report be wider than 1 page. If no value is
|                   supplied to this parameter then all
|                   displayable order variables will be defined
|                   as idvars Valid values: one or more variable
|                   names from DSETIN that are also defined with
|                   COLUMNS
|
|  CENTREVARS       Variables to be displayed as centre justified       blank (Opt)
|                   Valid values: one or more variable names from
|                   DSETIN that are also defined with COLUMNS
|                   Variables not appearing in any of the
|                   parameters CENTREVARS, LEFTVARS, or RIGHTVARS
|                   will be displayed using the PROC REPORT default.
|                   Character variables are left justified while
|                   numeric variables are right justified.
|
|  LEFTVARS         Variables to be displayed as left justified.        blank (Opt)    
|                   Valid values: one or more variable names from
|                   DSETIN that are also defined with COLUMNS.
|                   Variables not appearing in any of the parameters
|                   CENTREVARS, LEFTVARS, or RIGHTVARS will be
|                   displayed using the PROC REPORT default.  
|                   Character variables are left justified while 
|                   numeric variables are right justified.
|
|  RIGHTVARS        Variables to be displayed as right justified.       blank (Opt)  
|                   Valid values: one or more variable names from 
|                   DSETIN that are also defined with COLUMNS.  
|                   Variables not appearing in any of the parameters 
|                   CENTREVARS, LEFTVARS, or RIGHTVARS will be
|                   displayed using the PROC REPORT default.  
|                   Character variables are left justified while 
|                   numeric variables are right justified.
|
|  COLSPACING       The value of the between-column spacing             2 (Req)
|                   Valid values: positive integer
|
|  VARSPACING       Spacing for individual columns Valid values:        blank (Opt)
|                   variable name followed by a spacing value,
|                   e.g. Varspacing=a 1 b 2 c 0
|                   This parameter does NOT allow SAS variable
|                   lists. These values will override the overall
|                   COLSPACING parameter. VARSPACING defines the
|                   number of blank characters to leave between the
|                   column being defined and the column immediately
|                   to its left
|
|  FORMATS          Variables and their format for display. For         blank (Opt)
|                   use where format for display differs to the
|                   format on the DSETIN. Valid values: values of
|                   column names and formats such as form valid
|                   syntax for a SAS FORMAT statement
|
|  LABELS           Variables and their label for display. For use      result="Conc. (units)" (Req)
|                   where label for display differs to the label
|                   on the DSETIN Valid values: pairs of variable
|                   names and labels
|
|  BREAK1           For input of user-specified break statements        blank (Opt)
|  - BREAK5         Valid values: valid PROC REPORT BREAK
|                   statements (without "break") The value of
|                   these parameters are passed directly to PROC
|                   REPORT as: BREAK &break1;
|
|  PROPTIONS        PROC REPORT statement options to be used in         headline (Req)
|                   addition to MISSING. Valid values: proc
|                   report options. The option 'Missing' can
|                   not be overridden
|
|  NOWIDOWVAR       Variable whose values must be kept together         blank (Opt)
|                   on a page Valid values: names of one or more
|                   variables specified in COLUMNS
|
|  Output:          1) An output file in plain ASCII text format 
|                      containing a data display matching the
|                      requirements specified by the input parameters
|
|                   2) SAS data set that forms the foundation of 
|                      the data display (the "DD dataset")
|
|  Global macro variables created: none
|
|------------------------------------------------------------------------------------
|  Macros called:
|  (@) tr_putlocals
|  (@) tu_putglobals
|  (@) tu_list
|  (@) tu_words
|  (@) tu_tidyup
|  (@) tu_abort
|
|------------------------------------------------------------------------------------
|  Change Log
|
|  Modified by: Trevor Welby
|  Date of modification: 17-Jan-05
|  New version number: 01-002
|  Modification ID: TQW9753.01-002
|  Reason for modification: 
|
|                           Change the call below so that prefixed work datasets are 
|                           deleted correctly  
|
|                           From
|
|                             %tu_tidyup(glbmac=none
|                                       ,rmdset=&prefix
|                                       );
|
|                           To
|
|                             %tu_tidyup(glbmac=none
|                                       ,rmdset=&prefix.:
|                                       );
|
|                           Change g_ptrtgrp and g_ptrtcd to g_ptrtgrp and g_ptrtcd 
|                           respecctively 
|
|                           Change the default FLOWVARS to _ALL_
|
|------------------------------------------------------------------------------------
|  Change Log
|
|  Modified by: Trevor Welby
|  Date of modification: 09-Mar-05
|  New version number: 01-003  
|  Modification ID: TQW9753.01-003
|  Reason for modification:
|                           Remove the WHERE parameter and change to
|                           subset the data using the G_SUBSET global
|                           macro variable defined by %ts_setup
|
|                           Change the default of FLOWVARS parameter 
|                           to blank
|
|                           Modify the paramater validation checking for
|                           the existence of DSETIN  
|
|                           Add a format so that values of "-0.00" are 
|                           displayed as "0.00" i.e FORMATS= pcsttmdv nonneg.
|
|                           Variables specified by the COLUMN parameter
|                           is changed 
|
|                           FROM:  &g_subjid &g_ptrtcd &g_ptrtgrp pernum period
|                                  pcstdt pcsttm ptm ptmnum pcsttmdv pcatmnum 
|                                  result
|
|                           TO:    &g_subjid pernum period &g_ptrtcd &g_ptrtgrp  
|                                  pcstdt ptmnum pcsttm ptm pcsttmdv pcatmnum 
|                                  result
|
|                           Order of variables specified by the ORDERVARS
|                           parameter is changed 
|
|                           FROM:  &g_subjid &g_ptrtgrp period pcstdt ptmnum
|
|                           TO:    &g_subjid pernum period &g_ptrtcd &g_ptrtgrp 
|                                  pcstdt ptmnum
|
|                           Change SKIPVARS default to PCSTDT
|------------------------------------------------------------------------------------
|  Change Log
|
|  Modified by: Trevor Welby
|  Date of modification: 15-Mar-05
|  New version number: 01-004
|  Modification ID: TQW9753.01-004
|  Reason for modification: 
|                           Update the description for LEFTVARS and  
|                           RIGHTVARS parameters.
|  
|                           Remove End Of Line Markers
|
|------------------------------------------------------------------------------------
|  Change Log
|
|  Modified by:
|  Date of modification:
|  New version number:
|  Modification ID:
|  Reason for modification:
|
|------------------------------------------------------------------------------------*/
%macro td_pkcl1x(dsetin                 =ardata.pkcnc /* Input PK Concentrations dataset */ 
                ,stackvar1              =          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
                ,stackvar2              =          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
                ,stackvar3              =          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
                ,stackvar4              =          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
                ,stackvar5              =          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
                ,stackvar6              =          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
                ,stackvar7              =          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
                ,stackvar8              =          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
                ,stackvar9              =          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
                ,stackvar10             =          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
                ,stackvar11             =          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
                ,stackvar12             =          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
                ,stackvar13             =          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
                ,stackvar14             =          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
                ,stackvar15             =          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
                ,varlabelstyle          =SHORT     /* Specifies the label style for variables (SHORT or STD) */
                ,dddatasetlabel         =DD dataset for pkcl1x listing  /* Label to be applied to the DD dataset */
                ,splitchar              =~         /* Split character */
                ,computebeforepagelines =          /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt : labelvar) */
                ,computebeforepagevars  =          /* Names of variables that define the sort order for  Compute Before Page lines */
                ,columns                =&g_subjid pernum period &g_ptrtcd &g_ptrtgrp pcstdt ptmnum pcsttm ptm pcsttmdv pcatmnum result /* Columns to be included in the listing (plus spanned headers) [TQW9753.01-002] */ 
                ,ordervars              =&g_subjid pernum period &g_ptrtcd &g_ptrtgrp pcstdt ptmnum /* Order variables [TQW9753.01-002] */
                ,sharecolvars           =          /* Order variables that share print space */
                ,sharecolvarsindent     =2         /* Indentation factor */
                ,linevars               =          /* Order variables printed with LINE statemen */
                ,descending             =          /* Descending ORDERVARS */
                ,orderformatted         =          /* ORDER=FORMATTED variables */
                ,orderfreq              =          /* ORDER=FREQ variables */
                ,orderdata              =          /* ORDER=DATA variables */
                ,noprintvars            =&g_ptrtcd pernum ptmnum /* No print variables, used to order the display [TQW9753.01-002] */
                ,byvars                 =          /* By variables */
                ,flowvars               =          /* Variables with flow option */
                ,widths                 =&g_subjid 7 &g_ptrtgrp 15 period 8 pcstdt 8 pcsttm 6 ptm 9 pcsttmdv 5 pcatmnum 9 result 15 /* Column widths [TQW9753.01-002] */
                ,defaultwidths          =          /* List of default column widths */
                ,skipvars               =pcstdt /* Variable(s) whose change in value causes the display to skip a line [TQW9753.01-002] */
                ,pagevars               =          /* Variables whose change in value causes the display to continue on a new page */
                ,idvars                 =          /* Variables to appear on each page of the report */
                ,centrevars             =          /* Centre justify variables */
                ,leftvars               =          /* Left justify variables   */
                ,rightvars              =          /* Right justify variables  */
                ,colspacing             =2         /* Value for between-column spacing */
                ,varspacing             =          /* Column spacing for individual variables */
                ,formats                =pcsttmdv nonneg. /* Format specification (valid SAS syntax) */
                ,labels                 =result="Conc. ~(units)" /* Label definitions (var="var label")     */
                ,break1                 =          /* Break statements */
                ,break2                 =          /* Break statements */
                ,break3                 =          /* Break statements */
                ,break4                 =          /* Break statements */
                ,break5                 =          /* Break statements */
                ,proptions              =headline  /* PROC REPORT statement options */
                ,nowidowvar             =          /* List of variables whose values must be kept together on a page */
                );

  /*
  / Echo values of parameters and global macro variables to the log.
  /------------------------------------------------------------------------------*/
  %local MacroVersion;
  %let MacroVersion=1;
  %include "&g_refdata./tr_putlocals.sas";
  %tu_putglobals();

  /*
  / Perform parameter validation
  /------------------------------------------------------------------------------*/
  
  /*
  / Verify the following required macro parameters are not missing. As defined by local
  / macro variable VARS
  /------------------------------------------------------------------------------*/
                                  
  %local vars var k;

  %let vars=DSETIN VARLABELSTYLE DDDATASETLABEL SPLITCHAR COLUMNS ORDERVARS SHARECOLVARSINDENT NOPRINTVARS WIDTHS SKIPVARS COLSPACING LABELS PROPTIONS;

  %let var=;

  %do k=1 %to %tu_words(&vars);  /* Begin of k indexed loop */
    %let var=%scan(&vars,&k,%str( ));
    %if %nrbquote(&&&var) eq %then
    %do;
      %put %str(RTERR)OR: &sysmacroname: Required Macro Parameter %upcase(&var) is blank;
      %let g_abort=1;
    %end;
  %end;  /* End of k indexed loop */

  /*
  / Verify that the dataset DSETIN exists
  /------------------------------------------------------------------------------*/
  %if %length(&dsetin) eq 0 or not %sysfunc(exist(&dsetin)) %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: Macro Parameter DSETIN (dsetin=&dsetin) dataset does not exist;
    %let g_abort=1;
  %end;

  %tu_abort; 

  /*
  / Perform Normal Processing
  /------------------------------------------------------------------------------*/

  /*
  / Prefix for temporary work datasets
  /------------------------------------------------------------------------------*/
  %local prefix;
  %let   prefix=_pkcl1x;

  /*
  / Create a display format so that values -0.00 are displayed as 0.00
  /------------------------------------------------------------------------------*/
  proc format;
    value nonneg -0.005-0=' 0.00'
                 other   =[5.2]
    ;
  run; 

  /*
  / Create a reporting dataset
  /------------------------------------------------------------------------------*/
  data work.&prefix.01;
    set &dsetin;

  attrib result length=$20 label='Conc.';

  if pcstresc eq 'NQ' then
  do; 
    result=trim(pcstresc)||' (<'||left(trim(pcllqc))||')';
  end;
  else do;
    result=pcstresc;
  end;

  if pcprox eq 'Y' then
  do;
    result=trim(result) || ' *';
  end;

  run;

  /*
  / Produce the data display
  /------------------------------------------------------------------------------*/
  %tu_list(dsetin                 =work.&prefix.01
          ,stackvar1              =&stackvar1
          ,stackvar2              =&stackvar2
          ,stackvar3              =&stackvar3
          ,stackvar4              =&stackvar4
          ,stackvar5              =&stackvar5
          ,stackvar6              =&stackvar6
          ,stackvar7              =&stackvar7  
          ,stackvar8              =&stackvar8  
          ,stackvar9              =&stackvar9  
          ,stackvar10             =&stackvar10 
          ,stackvar11             =&stackvar11 
          ,stackvar12             =&stackvar12 
          ,stackvar13             =&stackvar13 
          ,stackvar14             =&stackvar14 
          ,stackvar15             =&stackvar15 
          ,varlabelstyle          =&varlabelstyle
          ,dddatasetlabel         =&dddatasetlabel
          ,splitchar              =&splitchar
          ,computebeforepagelines =&computebeforepagelines
          ,computebeforepagevars  =&computebeforepagevars
          ,columns                =&columns
          ,ordervars              =&ordervars
          ,sharecolvars           =&sharecolvars
          ,sharecolvarsindent     =&sharecolvarsindent
          ,linevars               =&linevars
          ,descending             =&descending
          ,orderformatted         =&orderformatted
          ,orderfreq              =&orderfreq
          ,orderdata              =&orderdata
          ,noprintvars            =&noprintvars
          ,byvars                 =&byvars
          ,flowvars               =&flowvars
          ,widths                 =&widths
          ,defaultwidths          =&defaultwidths
          ,skipvars               =&skipvars
          ,pagevars               =&pagevars
          ,idvars                 =&idvars
          ,centrevars             =&centrevars
          ,leftvars               =&leftvars
          ,rightvars              =&rightvars
          ,colspacing             =&colspacing
          ,varspacing             =&varspacing
          ,formats                =&formats
          ,labels                 =&labels
          ,break1                 =&break1
          ,break2                 =&break2
          ,break3                 =&break3
          ,break4                 =&break4
          ,break5                 =&break5
          ,proptions              =&proptions
          ,nowidowvar             =&nowidowvar

          /* Caller does not have control over the following parameters */
          ,display                =y
          ,getdatayn              =y
          ,labelvarsyn            =y
          ,overallsummary         =n
          );
  
  %tu_tidyup(glbmac=NONE
            ,rmdset=&prefix.: /* [TQW9753.01-002] */
            );
  quit;

  %tu_abort()
    
%mend td_pkcl1x;
