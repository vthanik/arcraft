/************************************************************************************
*
*  Macro name: tu_list.sas
*
*  Macro version: 3 build 2
*
*  SAS version: 8.2
*
*
*  Created by: Alfred Montalvo Jr
*
*  Date: 27may2003
*
*
*  Macro purpose: utility macro to generate listings
*
*  Macro design: procedure style utility
*
*
*  Input parameters:
*
*   Name           Description                            default
*
*   dsetin         The domain data set to act as the
*                  subject of the report. Valid
*                  values: name of a data set meeting
*                  an IDSL domain-specific dataset
*                  specification                          no default/blank
*   columns        A PROC REPORT column statement
*                  specification. Including spanning
*                  titles and variable names Valid
*                  values: one or more variable names
*                  from DSETIN plus other elements of
*                  valid PROC REPORT COLUMN statement
*                  syntax                                 blank
*   display        Specifies whether the report should
*                  be created. Valid values: Y or N
*                  If &g_analy_disp is D, DISPLAY shall
*                  be ignored                             Y
*   proptions      User specifies options to be passed
*                  to %tu_display's proptions parameter.
*                  These are in addition to SPLIT=
*                  "&splitchar". Default value is
*                  HEADLINE.                              headline
*   byvars         By variables. The variables listed
*                  here are processed as standard SAS
*                  by variables.  Valid values: one or
*                  more variable names from DSETIN No
*                  formatting of the display for these
*                  variables is performed by %tu_DISPLAY.
*                  The user has the option of the
*                  standard SAS BY line, or using
*                  OPTIONS NOBYLINE and #BYVAL #BYVAR
*                  directives in title statements.        blank
*   computebefore-
*   pagevars       Specifies the value to be passed to
*                  %tu_display's ComputeBeforePageVars
*                  parameter. The variables specified
*                  here are directly associated with the
*                  quadruplets of values specified in
*                  COMPUTEBEFOREPAGELINES Valid values:
*                  As defined for %tu_display
*                  For example: xCode trtcd               blank
*   computebefore-
*   pagelines      Specifies the labels that shall
*                  precede the ComputeBeforePageVar
*                  value. For each variable specified
*                  for COMPUTEBEFOREPAGEVARS, four
*                  values shall be specified for
*                  COMPUTEBEFOREPAGELINES. The four
*                  values shall be:
*                  - A localisation key for the fixed
*                    labelling text
*                  - The name of the localisation
*                    format ($local.)
*                  - The character(s) to be used between
*                    the labelling text and the values of
*                    the fourth parameter
*                  - Name of a variable whose values are
*                    to be used in the Computer Before
*                    Page line Valid values: A multiple
*                    of four words separated by blanks.
*                    The multiple shall be equal to the
*                    number of variables specified for
*                    COMPUTEBEFOREPAGEVARS For example:
*                    GRP $local. : xValue TRTMNT
*                        $local. : trtgrp                 blank
*   getdatayn      Execute tu_getdata macro: Yes or No
*                  Valid values: Y, N                     Y
*   labelvarsyn    Execute tu_labelvars macro : Yes or
*                  No Valid values: Y, N                  Y
*   stackvar1      Specifies parameters to pass to
*                  %tu_stackvar in order to stack
*                  variables together.  See Unit
*                  Specification for HARP Reporting
*                  Tools %TU_STACKVAR[4] for more
*                  detail regarding macro parameters
*                  that can be used in the macro call.
*                  DSETIN should not be specified -
*                  this will be generated internally
*                  by TU_LIST.                            blank
*   stackvar2      Specifies parameters to pass to
*                  %tu_stackvar in order to stack
*                  variables together.  See Unit
*                  Specification for HARP Reporting
*                  Tools %TU_STACKVAR[4] for more
*                  detail regarding macro parameters
*                  that can be used in the macro call.
*                  DSETIN should not be specified -
*                  this will be generated internally
*                  by TU_LIST.                            blank
*   stackvar3      Specifies parameters to pass to
*                  %tu_stackvar in order to stack
*                  variables together.  See Unit
*                  Specification for HARP Reporting
*                  Tools %TU_STACKVAR[4] for more
*                  detail regarding macro parameters
*                  that can be used in the macro call.
*                  DSETIN should not be specified -
*                  this will be generated internally
*                  by TU_LIST.                            blank
*   stackvar4      Specifies parameters to pass to
*                  %tu_stackvar in order to stack
*                  variables together.  See Unit
*                  Specification for HARP Reporting
*                  Tools %TU_STACKVAR[4] for more
*                  detail regarding macro parameters
*                  that can be used in the macro call.
*                  DSETIN should not be specified -
*                  this will be generated internally
*                  by TU_LIST.                            blank
*   stackvar5      Specifies parameters to pass to
*                  %tu_stackvar in order to stack
*                  variables together.  See Unit
*                  Specification for HARP Reporting
*                  Tools %TU_STACKVAR[4] for more
*                  detail regarding macro parameters
*                  that can be used in the macro call.
*                  DSETIN should not be specified -
*                  this will be generated internally
*                  by TU_LIST.                            blank
*   stackvar6      Specifies parameters to pass to
*                  %tu_stackvar in order to stack
*                  variables together.  See Unit
*                  Specification for HARP Reporting
*                  Tools %TU_STACKVAR[4] for more
*                  detail regarding macro parameters
*                  that can be used in the macro call.
*                  DSETIN should not be specified -
*                  this will be generated internally
*                  by TU_LIST.                            blank
*   stackvar7      Specifies parameters to pass to
*                  %tu_stackvar in order to stack
*                  variables together.  See Unit
*                  Specification for HARP Reporting
*                  Tools %TU_STACKVAR[4] for more
*                  detail regarding macro parameters
*                  that can be used in the macro call.
*                  DSETIN should not be specified -
*                  this will be generated internally
*                  by TU_LIST.                            blank
*   stackvar8      Specifies parameters to pass to
*                  %tu_stackvar in order to stack
*                  variables together.  See Unit
*                  Specification for HARP Reporting
*                  Tools %TU_STACKVAR[4] for more
*                  detail regarding macro parameters
*                  that can be used in the macro call.
*                  DSETIN should not be specified -
*                  this will be generated internally
*                  by TU_LIST.                            blank
*   stackvar9      Specifies parameters to pass to
*                  %tu_stackvar in order to stack
*                  variables together.  See Unit
*                  Specification for HARP Reporting
*                  Tools %TU_STACKVAR[4] for more
*                  detail regarding macro parameters
*                  that can be used in the macro call.
*                  DSETIN should not be specified -
*                  this will be generated internally
*                  by TU_LIST.                            blank
*   stackvar10     Specifies parameters to pass to
*                  %tu_stackvar in order to stack
*                  variables together.  See Unit
*                  Specification for HARP Reporting
*                  Tools %TU_STACKVAR[4] for more
*                  detail regarding macro parameters
*                  that can be used in the macro call.
*                  DSETIN should not be specified -
*                  this will be generated internally
*                  by TU_LIST.                            blank
*   stackvar11     Specifies parameters to pass to
*                  %tu_stackvar in order to stack
*                  variables together.  See Unit
*                  Specification for HARP Reporting
*                  Tools %TU_STACKVAR[4] for more
*                  detail regarding macro parameters
*                  that can be used in the macro call.
*                  DSETIN should not be specified -
*                  this will be generated internally
*                  by TU_LIST.                            blank
*   stackvar12     Specifies parameters to pass to
*                  %tu_stackvar in order to stack
*                  variables together.  See Unit
*                  Specification for HARP Reporting
*                  Tools %TU_STACKVAR[4] for more
*                  detail regarding macro parameters
*                  that can be used in the macro call.
*                  DSETIN should not be specified -
*                  this will be generated internally
*                  by TU_LIST.                            blank
*   stackvar13     Specifies parameters to pass to
*                  %tu_stackvar in order to stack
*                  variables together.  See Unit
*                  Specification for HARP Reporting
*                  Tools %TU_STACKVAR[4] for more
*                  detail regarding macro parameters
*                  that can be used in the macro call.
*                  DSETIN should not be specified -
*                  this will be generated internally
*                  by TU_LIST.                            blank
*   stackvar14     Specifies parameters to pass to
*                  %tu_stackvar in order to stack
*                  variables together.  See Unit
*                  Specification for HARP Reporting
*                  Tools %TU_STACKVAR[4] for more
*                  detail regarding macro parameters
*                  that can be used in the macro call.
*                  DSETIN should not be specified -
*                  this will be generated internally
*                  by TU_LIST.                            blank
*   stackvar15     Specifies parameters to pass to
*                  %tu_stackvar in order to stack
*                  variables together.  See Unit
*                  Specification for HARP Reporting
*                  Tools %TU_STACKVAR[4] for more
*                  detail regarding macro parameters
*                  that can be used in the macro call.
*                  DSETIN should not be specified -
*                  this will be generated internally
*                  by TU_LIST.                            blank
*   varlabelstyle  Specifies the style of labels to be
*                  applied by the %tu_labelvars macro
*                  Valid values: as specified by
*                  %tu_labelvars, i.e. SHORT or STD       SHORT
*   dddatasetlabel Specifies the label to be applied
*                  to the DD dataset Valid values: a
*                  non-blank text string                  blank
*   defaultwidths  This is a list of default widths
*                  for ALL columns and will usually be
*                  defined by the DD macro.  This
*                  parameter specifies column widths
*                  for all variables not listed in the
*                  WIDTHS parameter.  Valid values:
*                  values of column names and numeric
*                  widths, a list of variables followed
*                  by a positive integer, e.g.
*                  defaultwidths = a b 10 c 12 d1-d4 6
*                  Numbered range lists are supported in
*                  this parameter however name range lists,
*                  name prefix lists, and special SAS name
*                  lists are not. For variables that are
*                  not given widths through either the
*                  WIDTHS or DEFAULTWIDTHS parameter will
*                  be width optimised using MAX (variable?s
*                  format width, width of  column header)
*                  for variables that are NOT flowed
*                  or MIN(variable?s format width, width
*                  of column header) for variable
*                  that ARE flowed.                       blank
*   ordervars      List of variables that will receive
*                  the PROC REPORT define statement
*                  attribute ORDER Valid values: one or
*                  more variable names from DSETIN that
*                  are also defined with COLUMNS          blank
*   descending     List of ORDERVARS that are given the
*                  PROC REPORT define statement attribute
*                  DESCENDING Valid values: one or more
*                  variable names from DSETIN that are
*                  also defined with ORDERVARS            blank
*   orderformatted Variables listed in the ORDERVARS
*                  parameter that are given the PROC
*                  REPORT define statement attribute
*                  order=formatted. Valid values: one or
*                  more variable names from DSETIN that
*                  are also defined with ORDERVARS
*                  Variables not listed in ORDERFORMATTED,
*                  ORDERFREQ, or ORDERDATA are given the
*                  define attribute order=internal        blank
*   orderfreq      Variables listed in the ORDERVARS
*                  parameter that are given the PROC
*                  REPORT define statement attribute
*                  order=freq. Valid values: one or more
*                  variable names from DSETIN that are
*                  also defined with ORDERVARS Variables
*                  not listed in ORDERFORMATTED,
*                  ORDERFREQ, or ORDERDATA are given
*                  the define attribute order=internal    blank
*   orderdata      Variables listed in the ORDERVARS
*                  parameter that are given the PROC
*                  REPORT define statement attribute
*                  order=data. Valid values: one or more
*                  variable names from DSETIN that are
*                  also defined with ORDERVARS Variables
*                  not listed in ORDERFORMATTED,
*                  ORDERFREQ, or ORDERDATA are given
*                  the define attribute order=internal    blank
*   noprintvars    Variables listed in the COLUMN
*                  parameter that are given the PROC
*                  REPORT define statement attribute
*                  noprint.  Valid values: one or more
*                  variable names from DSETIN that are
*                  also defined with COLUMNS These
*                  variables are usually ORDERVARS
*                  used to control the order of the rows
*                  in the display.                        blank
*   flowvars       Variables to defined with the flow
*                  option.  Valid values: one or more
*                  variable names from DSETIN that are
*                  also defined with COLUMNS Flow
*                  variables should be given a width
*                  through the WIDTHS.  If a flow variable
*                  does not have a width specified the
*                  column width will be determined by
*                  MIN(variable?s format width, width of
*                  column header)                         _all_
*   splitchar      Specifies the split character to be
*                  passed to %tu_display Valid values:
*                  one single character                   ~
*   widths         Variables and width to display. Valid
*                  values: values of column names and
*                  numeric widths, a list of variables
*                  followed by a positive integer, e.g.
*                  widths = a b 10 c 12 d1-d4 6
*                  Numbered range lists are supported in
*                  this parameter however name range
*                  lists, name prefix lists, and special
*                  SAS name lists are not. Display layout
*                  will be optimised by default, however
*                  any specified widths will cause the
*                  default to be overridden.              blank
*   skipvars       Variables whose change in value causes
*                  the display to skip a line Valid
*                  values: one or more variable names
*                  from DSETIN that are also defined
*                  with COLUMNS                           blank
*   pagevars       Variables whose change in value causes
*                  the display to continue on a new page
*                  Valid values: one or more variable
*                  names from DSETIN that are also
*                  defined with COLUMNS                   blank
*   idvars         Variables to appear on each page
*                  should the report be wider than 1 page.
*                  If no value is supplied to this
*                  parameter then all displayable order
*                  variables will be defined as idvars
*                  Valid values: one or more variable names
*                  from DSETIN that are also defined
*                  with COLUMNS                           blank
*   centervars     Variables to be displayed as centre
*                  justified. Valid values: one or more
*                  variable names from DSETIN that are
*                  also defined with COLUMNS Variables
*                  not appearing in any of the parameters
*                  CENTREVARS, LEFTVARS, or RIGHTVARS
*                  will be displayed using the PROC REPORT
*                  default. Character variables are left
*                  justified while numeric variables are
*                  right justified.                       blank
*   leftvars       Variables to be displayed as left
*                  justified Valid values: one or more
*                  variable names from DSETIN that are
*                  also defined with COLUMNS              blank
*   rightvars      Variables to be displayed as right
*                  justified Valid values: one or more
*                  variable names from DSETIN that are
*                  also defined with COLUMNS              blank
*   linevars       List of order variables that are
*                  printed with LINE statements in PROC
*                  REPORT Valid values: one or more
*                  variable names from DSETIN that are
*                  also defined with ORDERVARS These
*                  values shall be written with a BREAK
*                  BEFORE when the value of one of the
*                  variables change. The variables will
*                  automatically be defined as NOPRINT    blank
*   colspacing     The value of the between-column
*                  spacing.
*                  Valid values: positive integer         2
*   varspacing     Spacing for individual columns.
*                  Valid values: variable name
*                  followed by a spacing value, e.g.
*                  Varspacing=a 1 b 2 c 0
*                  This parameter does NOT allow SAS
*                  variable lists. These values will
*                  override the overall COLSPACING
*                  parameter. VARSPACING defines the
*                  number of blank characters to leave
*                  between the column being defined
*                  and the column immediately to
*                  its left                               blank
*   formats        Variables and their format for
*                  display. For use where format for
*                  display differs to the format on
*                  the DSETIN. Valid values: values of
*                  column names and formats such as
*                  form valid syntax for a SAS FORMAT
*                  statement                              blank
*   labels         Variables and their label for display.
*                  For use where label for display
*                  differs to the label on the dsetin
*                  Valid values: pairs of variable names
*                  and labels                             blank
*   sharecolvars   List of variables that will share
*                  print space. The attributes of the
*                  last variable in the list define the
*                  column width and flow options Valid
*                  values: one or more variable names
*                  from DSETIN AE5 shows an example of
*                  this style of output The formatted
*                  values of the variables shall be
*                  written above each other in one
*                  column.                                blank
*   sharecolvars-
*   indent         Indentation factor for ShareColVars.
*                  Stacked values shall be progressively
*                  indented by multiples of
*                  ShareColVarsIndent Valid values:
*                  positive integer                       2
*   overallsummary Causes the macro to produce an overall
*                  summary line. Use with ShareColVars.
*                  Valid values: Y or N
*                  The values are not calculated - they
*                  must be supplied in a special record
*                  in the dataset. The special record is
*                  identified by the fact that the value
*                  for all of the order variables must be
*                  the same for the permutation with the
*                  lowest sort order (as resulting from
*                  COLUMN and ORDER), i.e. the first
*                  report row                             N
*   break1         5 parameters for input of user
*                  specified break statements.
*                  Valid values: valid PROC REPORT BREAK
*                  statements (without "break")
*                  The value of these parameters are
*                  passed directly to PROC REPORT as:
*                  BREAK &break1;                         blank
*   break2         5 parameters for input of user
*                  specified break statements.
*                  Valid values: valid PROC REPORT BREAK
*                  statements (without "break")
*                  The value of these parameters are
*                  passed directly to PROC REPORT as:
*                  BREAK &break1;                         blank
*   break3         5 parameters for input of user
*                  specified break statements.
*                  Valid values: valid PROC REPORT BREAK
*                  statements (without "break")
*                  The value of these parameters are
*                  passed directly to PROC REPORT as:
*                  BREAK &break1;                         blank
*   break4         5 parameters for input of user
*                  specified break statements.
*                  Valid values: valid PROC REPORT BREAK
*                  statements (without "break")
*                  The value of these parameters are
*                  passed directly to PROC REPORT as:
*                  BREAK &break1;                         blank
*   break5         5 parameters for input of user
*                  specified break statements.
*                  Valid values: valid PROC REPORT BREAK
*                  statements (without "break")
*                  The value of these parameters are
*                  passed directly to PROC REPORT as:
*                  BREAK &break1;                         blank
*   nowidowvar     Variable whose values must be kept
*                  together on a page
*                  Valid values: names of one or more
*                  variables specified in COLUMNS         blank
*
*  Output:
*
*  Global macro variables created: None
*
*
*  Macros called:
*  (@) tu_abort
*  (@) tr_putlocals
*  (@) tu_putglobals
*  (@) tu_maclist
*  (@) tu_getdata
*  (@) tu_labelvars
*  (@) tu_stackvar
*  (@) tu_header
*  (@) tu_footer
*  (@) tu_pagenum
*  (@) tu_display
*  (@) tu_tidyup
*  (@) tu_expvarlist
*  (@) tu_words
*
*
*
*
************************************************************************************
* Change Log
*
* Modified by: Alfred Montalvo Jr
* Date of modification: 19aug03
* New version number: 1/2
* Modification ID: 01
* Reason for modification: Code was modifed by adding macro call to tu_expvarlist.
*                          Additional modifications were also made as requested via
*                          emails from Paul and Shan as a result of SCR.
*
*
*
************************************************************************************
* Change Log
*
* Modified by:             Shan Lee
* Date of modification:    29 August 2003
* New version number:      1/3
* Modification ID:         SL01
* Reason for modification: The G_DDDATASETNAME was unconditionally deleted -
*                          macro has been modified so that it is only deleted if
*                          it already exists.
*                          Unbalanced comment markers were corrected.
*
*
*
************************************************************************************
*
* Modified by:             John King
* Date of modification:    03 September 2003
* New version number:      1/4
* Modification ID:         jhk:1/4
* Reason for modification: Add a check for blank columns parameter. 
*
*
*
************************************************************************************
* Change Log
*
* Modified by:             Tamsin Corfield
* Date of modification:    21-Oct-03
* New version number:      1/5
* Modification ID:         None
* Reason for modification: Removed ; from comments on pagevars and 
*                          skipvars parameters so that tu_list could be 
*                          checked into the apllication successfully
************************************************************************************
* Change Log
*
* Modified by:             Shan Lee
* Date of modification:    20-Sep-07
* New version number:      2/1
* Modification ID:         SL02
* Reason for modification: Implement SAS to Word interim solution, which involves
*                          calling tu_display twice when table output is required:
*                          once to generate the data display as an RTF file, and 
*                          another time to generate the normal ASCII output.
*
* Modified by:             Shan Lee
* Date of modification:    25-Sep-07
* New version number:      2/2
* Modification ID:         SL03
* Reason for modification: Incorporate feedback from UAT: when RTF output is being
*                          created, define a style in the WORK library rather than
*                          the SASUSER library, to avoid conflict when multiple
*                          programs are executed simultaneously - i.e. avoid
*                          more than one program trying to access the same 
*                          permanent STORE at the same time.
*
* Modified by:             Shan Lee
* Date of modification:    27-Sep-07
* New version number:      2/3
* Modification ID:         SL04
* Reason for modification: After checking-in the previous build via the training
*                          instance of the HARP Application, e rror messages were
*                          still generated when multiple drivers were executed
*                          simultaneously. The definition of the ODS PATH will 
*                          now be moved to before the PROC TEMPLATE, to ensure that
*                          the defined style and all its inherited properties are
*                          written to the temporary store in the WORK library.
*
* Modified by:             Yongwei Wang
* Date of modification:    28-Feb-08
* New version number:      3/1
* Modification ID:         YW001
*                          1. Check if &g_rtfyn equals Y before creating RTF output,
*                             based on change request HRT0196
*
* Modified by:             Shan Lee
* Date of modification:    16-Jun-08
* New version number:      3/2
* Modification ID:         SL05
* Reason for modification: Remove section of code that deletes existing version of 
*                          the RTF file (this is now done in ts_setup).
*                          Generate the 'RTF' file as an HTML file, to enable output
*                          to be appended if tu_list is called multiple times by the
*                          same data display driver program.
************************************************************************************/


%macro tu_list(
  dsetin         = ,         /* Input domain dataset */
  stackvar1      = ,         /* Create Stacked variables (e.g. stackvar1=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
  stackvar2      = ,         /* Create Stacked variables (e.g. stackvar2=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
  stackvar3      = ,         /* Create Stacked variables (e.g. stackvar3=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
  stackvar4      = ,         /* Create Stacked variables (e.g. stackvar4=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
  stackvar5      = ,         /* Create Stacked variables (e.g. stackvar5=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
  stackvar6      = ,         /* Create Stacked variables (e.g. stackvar6=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
  stackvar7      = ,         /* Create Stacked variables (e.g. stackvar7=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
  stackvar8      = ,         /* Create Stacked variables (e.g. stackvar8=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
  stackvar9      = ,         /* Create Stacked variables (e.g. stackvar9=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
  stackvar10     = ,         /* Create Stacked variables (e.g. stackvar10=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~))*/
  stackvar11     = ,         /* Create Stacked variables (e.g. stackvar11=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~))*/
  stackvar12     = ,         /* Create Stacked variables (e.g. stackvar12=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~))*/
  stackvar13     = ,         /* Create Stacked variables (e.g. stackvar13=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~))*/
  stackvar14     = ,         /* Create Stacked variables (e.g. stackvar14=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~))*/
  stackvar15     = ,         /* Create Stacked variables (e.g. stackvar15=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~))*/
  display        = Y,        /* Specifies whether the report should be created */
  varlabelstyle  = SHORT,    /* Specifies the label style for variables (SHORT or STD) */
  dddatasetlabel = DD dataset for a listing,  /* Label to be applied to the DD dataset */
  splitchar      =~,         /* Split character */
  getdatayn      =Y,         /* Control execution of tu_getdata */
  labelvarsyn    =Y,         /* Control execution of tu_labelvars */
  computebeforepagelines=,   /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt colon labelvar) */
  computebeforepagevars=,    /* Names of variables that shall define the sort order for Compute Before Page lines */
  columns        = ,         /* Column parameter */
  ordervars      =,          /* Order variables */
  descending     =,          /* Descending ORDERVARS */
  orderformatted=,           /* ORDER=FORMATTED variables */
  orderfreq      =,          /* ORDER=FREQ variables */
  orderdata      =,          /* ORDER=DATA variables */
  noprintvars    =,          /* No print vars (usually used to order the display) */
  byvars         = ,         /* By variables */
  flowvars       =_all_,     /* Variables with flow option */
  widths         =,          /* Column widths */
  defaultwidths  =,          /* List of default column widths */
  skipvars       =,          /* Break after <var> / skip */
  pagevars       =,          /* Break after <var> / page */
  idvars         =,          /* ID variables */
  linevars       =,          /* Order variable printed with line statements. */
  centrevars     =,          /* Centre justify variables */
  leftvars       =,          /* Left justify variables */
  rightvars      =,          /* Right justify variables */
  colspacing     =2,         /* Overall spacing value. */
  varspacing     =,          /* Spacing for individual variables. */
  formats        =,          /* Format specification */
  labels         =,          /* Label definitions. */
  break1         =,          /* Break statements. */
  break2         =,          /* Break statements. */
  break3         =,          /* Break statements. */
  break4         =,          /* Break statements. */
  break5         =,          /* Break statements. */
  nowidowvar     =,          /* Not in version 1 */
  sharecolvars   =,          /* Order variables that share print space. */
  sharecolvarsindent=2,      /* Indentation factor */
  overallsummary =n,         /* Overall summary line at top of tables */
  proptions      = HEADLINE, /* PROC REPORT statement options */
  );

  /*
  / Echo the macro name and version to the log. Also echo the parameter values
  / and values of global macro variables used by this macro.
  /---------------------------------------------------------------------------*/

  %local MacroVersion;
  %let MacroVersion = 3 build 2;

  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_dddatasetname g_analy_disp g_ls)


  /*
  / Perform parameter validation.
  /---------------------------------------------------------------------------*/
  
  /*
  / jhk:1/4 Check for blank columns parameter.
  /----------------------------------------------------------------------------*/
  %if %bquote(&columns) eq %then
  %do;

    %put %str(RTE)RROR: &sysmacroname: - Macro parameter COLUMNS is blank.;
    %put %str(RTE)RROR: &sysmacroname: calling tu_abort to stop executing program;

    %tu_abort(option=force)

  %end;

  /*
  / Check DSETIN
  /
  /  -> Check that the dataset exists.
  /
  /  -> No need to check to see if specified variables exist - that will be
  /     done by macros that used them, i.e. %tu_stackvar and %tu_display
  /---------------------------------------------------------------------------*/

  %if %bquote(&dsetin) eq %then
  %do;

    %put %str(RTE)RROR: TU_LIST: - Macro parameter DSETIN (&dsetin.) is missing. ;
    %put %str(RTE)RROR: TU_LIST: calling tu_abort to stop executing program;

    %tu_abort(option=force)

  %end;
  %else %if %bquote(&dsetin) ne %then
  %do;

    %if %sysfunc(exist(&dsetin)) %then
    %do;
         %put RTNOTE: TU_LIST: input data specified &dsetin exists.;
    %end;
    %else
    %do;

      %put %str(RTE)RROR: TU_LIST: - Macro parameter DSETIN (&dsetin) does not exist.;
      %put %str(RTE)RROR: TU_LIST: calling tu_abort to stop executing program;

      %tu_abort(option=force)

    %end;

  %end;


  /*
  / If &G_ANALY_DISP eq D, &g_dddatasetname must exist.
  /---------------------------------------------------------------------------*/

  %if %bquote(%upcase(&g_analy_disp)) eq D %then
  %do;

    %if %sysfunc(exist(&g_dddatasetname)) %then
    %do;
       %put RTNOTE: TU_LIST: input data specified &g_dddatasetname exists.;
    %end;
    %else
    %do;

      %put %str(RTE)RROR: TU_LIST: - Macro parameter G_DDDATASETNAME (&g_dddatasetname) does not exist.;
      %put %str(RTE)RROR: TU_LIST: calling tu_abort to stop executing program;

      %tu_abort(option=force)

    %end;

  %end;


  /*
  / Validate &G_ANALY_DISP and &DISPLAY thus:
  /
  /  -> If &G_ANALY_DISP is D then issue an (RTW)ARNING if &DISPLAY is
  /     neither blank nor Y. The message shall state that DISPLAY will be
  /     ignored if G_ANALY_DISP is D (and the display will be produced
  /     regardless)
  /
  /  -> If &G_ANALY_DISP is A then issue an (RTE)RROR if &DISPLAY is neither Y
  /     nor N. The message shall state that the value of DISPLAY is invalid
  /---------------------------------------------------------------------------*/

  %if %bquote(%upcase(&g_analy_disp)) eq D %then
  %do;

    %if %bquote(&display) eq %then
    %do;

      /*
      / OK if value for display is missing per unit spec
      /-----------------------------------------------------------------------*/

    %end; /* %if %bquote(&display) eq */
    %else %if %bquote(&display) ne %then
    %do;

      %if %bquote(%upcase(&display)) eq Y %then
      %do;

        /*
        / do nothing since value =y is OK per unit spec
        /---------------------------------------------------------------------*/

      %end;
      %else
      %do;

        /*
        / Issue (RTW)ARNING message
        /---------------------------------------------------------------------*/

        %put %str(RTW)ARNING: TU_LIST: - Macro parameter DISPLAY will be ignored because G_ANALY_DISP is D;
        %put %str(RTW)ARNING: TU_LIST: the display will be produced regardless;

      %end;

    %end; /* %else %if %bquote(&display) ne */

  %end; /* %if %bquote(%upcase(&g_analy_disp)) eq D */
  %else %if %bquote(%upcase(&g_analy_disp)) eq A %then
  %do;

    %if %bquote(&display) eq %then
    %do;

      /*
      / issue (RTE)RROR message if display is missing
      /-----------------------------------------------------------------------*/

      %put %str(RTE)RROR: TU_LIST: - Macro parameter DISPLAY (&display) is missing;
      %put %str(RTE)RROR: TU_LIST: calling tu_abort to stop executing program;

      %tu_abort(option=force)

    %end;
    %else %if %bquote(&display) ne %then
    %do;

      %if %bquote(%upcase(&display)) eq Y %then
      %do;

        /*
        / do nothing since value =y is OK
        /---------------------------------------------------------------------*/

      %end;
      %else %if %bquote(%upcase(&display)) eq N %then
      %do;

                                                                      /* SL01 */

        /*
        / do nothing since value =n is OK
        /---------------------------------------------------------------------*/

      %end;
      %else
      %do;

        /*
        / issue (RTE)RROR message if display is not equal to Y or N
        /---------------------------------------------------------------------*/

        %put %str(RTE)RROR: TU_LIST: - Macro parameter DISPLAY (display=&display) does not have a value of Y or N;
        %put %str(RTE)RROR: TU_LIST: calling tu_abort to stop executing program;

        %tu_abort(option=force)

      %end;

    %end; /* %else %if %bquote(&display) ne */

  %end; /* %else %if %bquote(%upcase(&g_analy_disp)) eq A */


  /*
  / VARLABELSTYLE must be SHORT or STD
  /---------------------------------------------------------------------------*/

  %if %bquote(%upcase(&varlabelstyle)) eq %then
  %do;

    %put %str(RTE)RROR: TU_LIST: - Macro parameter VARLABELSTYLE (varlabelstyle=&varlabelstyle)is missing;
    %put %str(RTE)RROR: TU_LIST: calling tu_abort to stop executing program;

    %tu_abort(option=force)

  %end;
  %else %if %bquote(%upcase(&varlabelstyle)) ne %then
  %do;

    %if %bquote(%upcase(&varlabelstyle)) eq STD %then
    %do;

    %end;
    %else %if %bquote(%upcase(&varlabelstyle)) eq SHORT %then
    %do;

    %end;
    %else
    %do;

      %put %str(RTE)RROR: TU_LIST: - Macro parameter VARLABELSTYLE (varlabelstyle=&varlabelstyle) does not have a value of SHORT or STD;
      %put %str(RTE)RROR: TU_LIST: calling tu_abort to stop executing program;

      %tu_abort(option=force)

    %end;

  %end; /* %if %bquote(%upcase(&varlabelstyle)) eq */


  /*
  / DDDATASETLABEL must not be blank
  /---------------------------------------------------------------------------*/

  %if %bquote(%upcase(&dddatasetlabel)) eq %then
  %do;

    %put %str(RTE)RROR: TU_LIST: - Macro parameter DDDataSETLABEL (dddatasetlabel=&dddatasetlabel) is missing;
    %put %str(RTE)RROR: TU_LIST: calling tu_abort to stop executing program;

    %tu_abort(option=force)

  %end;


  /*
  / SPLITCHAR may not be blank
  /---------------------------------------------------------------------------*/

   %if %bquote(%upcase(&splitchar)) eq %then
   %do;

     %put %str(RTE)RROR: TU_LIST: - Macro parameter SPLITCHAR (splitchar=&splitchar) is missing;
     %put %str(RTE)RROR: TU_LIST: calling tu_abort to stop executing program;

     %tu_abort(option=force)

   %end;


  /*
  / GETDATAYN may not be blank
  /---------------------------------------------------------------------------*/

  %if %bquote(%upcase(&getdatayn)) eq %then
  %do;

    %put %str(RTE)RROR: TU_LIST: - Macro parameter GETDATAYN (getdatayn=&getdatayn) is missing;
    %put %str(RTE)RROR: TU_LIST: calling tu_abort to stop executing program;

    %tu_abort(option=force)

  %end;


  /*
  / LABELVARSYN may not be blank
  /---------------------------------------------------------------------------*/

  %if %bquote(%upcase(&labelvarsyn)) eq %then
  %do;

    %put %str(RTE)RROR: TU_LIST: - Macro parameter LABELVARSYN (labelvarsyn=&labelvarsyn) is missing;
    %put %str(RTE)RROR: TU_LIST: calling tu_abort to stop executing program;

    %tu_abort(option=force)

  %end;


  /*
  / End of macro parameter validation
  /---------------------------------------------------------------------------*/


  /*
  / Declare all local macro variables
  /---------------------------------------------------------------------------*/

  %local prefix ii j zz num_words wordnum rx times parsecols keepvars initial_nowidowvar initial_flowvars m n rtf_outfile first_m;


  /*
  / Set the work dataset name prefix to _LIST
  /---------------------------------------------------------------------------*/

  %let prefix = _list;


  /*
  / If &getdatayn eq Y then use %tu_getdata(dsetin=&DSETIN, dsetout1&prefix.1)
  / to subset the population of the data domain dataset without "ballooning"
  /
  / Else if &getdatayn ne Y then copy dataset &DSETIN into &prefix.1 unchanged
  /---------------------------------------------------------------------------*/

  %if %upcase(&getdatayn) eq Y %then
  %do;

    %tu_getdata(dsetin=&dsetin, dsetout1=&prefix.1);

  %end;
  %else
  %do;

    data &prefix.1;
      set &dsetin;
    run;

  %end;


  /*
  / If COMPUTEBEFOREPAGEVARS was specified, create dataset &prefix.2
  /
  / Otherwise copy dataset &prefix.1 to &prefix.2
  /---------------------------------------------------------------------------*/

  %if %bquote(%upcase(&ComputeBeforePageVars)) ne %then
  %do;

    /*
    / Parse COMPUTEBEFOREPAGEVARS into an array of macro variables.
    /-------------------------------------------------------------------------*/

    %tu_maclist(string = &ComputeBeforePageVars,
                prefix = cbpVar,
                delim=%str( )
               )

    /*
    / Determine the number of words in COMPUTEBEFOREPAGELINES.
    /-------------------------------------------------------------------------*/

    %let num_words = 0;

    %do %while (%qscan(%nrbquote(&computebeforepagelines), &num_words + 1,
                       %str( )) ne );
       %let num_words = %eval(&num_words + 1);
    %end;


    /*
    / Issue an (RTE)RROR if the number of words in COMPUTEBEFOREPAGELINES is
    / not equal to the number of variables in COMPUTEBEFOREPAGEVARS multiplied
    / by four.
    /-------------------------------------------------------------------------*/

    %if &num_words ne (4 * &cbpVar0) %then
    %do;

      %put %str(RTE)RROR: TU_LIST: number of words in COMPUTEBEFOREPAGELINES must be 4 times number of variables in COMPUTEBEFOREPAGEVARS;

      %tu_abort(option=force)

    %end;


    /*
    / Parse COMPUTEBEFOREPAGELINES into macro arrays cbpKey, cbpFmt, cbpChr,
    / and cbpVal.
    / Create the variables (cbpVal1, cbpVal2 etc), with length &G_LS, using
    / the macro arrays (each of these variables corresponds to a compute before
    / page variable, but the value of the newly created variable also includes
    / the text that will be displayed immediately before it in the listing).
    /-------------------------------------------------------------------------*/

    data &prefix.2;

      set &prefix.1;
      length cbpVal1-cbpVal&cbpVar0 $&g_ls.;

      %do j = 1 %to &cbpvar0.;

        %let wordnum = %eval(&j*4 - 3);
        %local cbpKey&j cbpFmt&j cbpChr&j cbpVal&j;
        %let cbpKey&j = %qscan(&computebeforepagelines,&wordnum+0,%str( ));
        %let cbpFmt&j = %qscan(&computebeforepagelines,&wordnum+1,%str( ));
        %let cbpChr&j = %qscan(&computebeforepagelines,&wordnum+2,%str( ));
        %let cbpVal&j = %qscan(&computebeforepagelines,&wordnum+3,%str( ));

        cbpVal&j = trim(left(put("&&cbpKey&j", &&cbpFmt&j)))
                   !! "&&cbpChr&j "
                   !! &&cbpVal&j
                   ;

      %end; /* %do j = 1 %to &cbpvar0. */

    run;

  %end; /* %if %bquote(%upcase(&ComputeBeforePageVars)) ne */
  %else
  %do;

    data &prefix.2;
      set &prefix.1;
    run;

  %end;


  /*
  / Using %tu_pagenum(usage=delete), delete the listing file (even if &g_debug
  / is not zero)
  /---------------------------------------------------------------------------*/

  %tu_pagenum(usage=delete)


  /*
  / If &G_ANALY_DISP ne D then execute steps below, else if just doing a
  / refresh of titles/footnotes (i.e. &G_ANALY_DISP eq D), jump to "OUTPUT
  / stage begins here"
  /---------------------------------------------------------------------------*/

  %if &g_analy_disp eq D %then
  %do;
    %goto OUTPUT_STAGE;
  %end;


  /*
  / Delete &g_dddatasetname if it exists (even if &g_debug is not zero)
  / The value of &g_dddatasetname is assigned by %ts_setup as the *two* level
  / SAS name for the data display dataset.
  /---------------------------------------------------------------------------*/

  %if %sysfunc(exist(&g_dddatasetname)) %then
  %do;                                                                /* SL01 */

    proc datasets library = %scan(&g_dddatasetname, 1, .)
                  memtype = data
                  ;
      delete %scan(&g_dddatasetname, 2, .);
    run;
    quit;

  %end;


  /*
  / Use %tu_stackvar to achieve necessary joining of variables.
  / Execute tu_stackvar if any of the macro parameters STACKVAR1 - STACKVAR15
  / are specified.
  / Note that the name of the dataset that is generated by the following
  / datastep depends on whether or not labelling has been requested. This is to
  / ensure that regardless of whether tu_labelvars is subsequently called,
  / the work dataset resulting from any stacking and labelling will always
  / have the same name (ie &prefix.4).
  /---------------------------------------------------------------------------*/

  data %if %upcase(&labelvarsyn) eq Y %then
       %do;
         &prefix.3
       %end;
       %else
       %do;
         &prefix.4
       %end;
       ;

    set &prefix.2;

    %do ii=1 %to 15;

      %if %nrbquote(&&stackvar&ii) ne  %then
      %do;

        %put %str(RTN)OTE: TU_LIST: STACKVAR&ii parameter has the value %nrbquote(&&stackvar&ii).;
        %put %str(RTN)OTE: TU_LIST: This value is used to form the parameter specification in the following call to tu_stackvar.;
        %put %str(RTN)OTE: TU_LIST: If tu_stackvar fails to execute, then please check this value is valid.;

        %tu_stackvar(%unquote(&&stackvar&ii.), dsetin=&prefix.2)

      %end;

    %end; /* %do ii=1 %to 15 */

  run;


  /*
  / If &labelvarsyn eq Y then use %tu_labelvars(dsetin=&prefix.3, dsetout=
  / &prefix.4, style=&varlabelstyle).
  /---------------------------------------------------------------------------*/

  %if %upcase(&labelvarsyn) eq Y %then
  %do;

    %tu_labelvars(dsetin=&prefix.3,
                  dsetout=&prefix.4,
                  style=&varlabelstyle)

  %end;


  /*
  / Create the DD dataset (&g_dddatasetname) with label set as DDDATASETLABEL
  /
  /  -> Create a list of variables to keep on the DD dataset using BYVARS,
  /     COMPUTEBEFOREPAGEVARS and COLUMNS.
  /
  /  -> If BYVARS is specified, create DD dataset by sorting &prefix.4 by BYVARS
  /
  /  -> Otherwise use data step to create DD dataset from &prefix.4
  /
  / Regarding the last 2 bullet points above, please note that there is an
  / intermediate stage when &prefix.5 is created before the actual DD dataset.
  / This is necessary because a dataset label could not be applied during a
  / Proc Sort, so &prefix.5 is created first, and &g_dddatasetname is created
  / from &prefix.5 in a data step in which the dataset label is applied.
  /---------------------------------------------------------------------------*/


  /*
  / Assign value to local macro variable PARSECOLS, equivalent to the parameter
  / COLUMNS, except that only actual variable names are kept.
  /---------------------------------------------------------------------------*/

  %let rx     = %sysfunc(rxparse($q TO " " %str(,) "(" TO " " %str(,) ")" TO " "));
  %let times  = 999;
  %let parsecols = &columns;
  %syscall rxchange(rx,times,parsecols,parsecols);
  %syscall rxfree(rx);


  /*
  / Expand any lists and remove any duplicates.
  /---------------------------------------------------------------------------*/

  %if %bquote(%upcase(&ComputeBeforePageVars)) ne %then
  %do;

    %tu_expvarlist(dsetin =&prefix.4,
                   varsin =&parsecols &byVars &computeBeforePageVars %do zz=1 %to &cbpvar0;
                                                                         cbpval&zz
                                                                     %end; ,
                   varout =KEEPVARS)

  %end;
  %else
  %do;

    %tu_expvarlist(dsetin =&prefix.4,
                   varsin =&parsecols &byVars,
                   varout =KEEPVARS)

  %end;


  /*
  / Sort dataset only if byvars is not equal to missing
  /---------------------------------------------------------------------------*/

  %if %bquote(&byvars) ne %then
  %do;

    proc sort data = &prefix.4
              (keep = &keepvars)
              out = &prefix.5;
      by &byvars;
    run;

  %end;
  %else %if %bquote(&byvars) eq %then
  %do;

    data &prefix.5;
      set &prefix.4 (keep = &keepvars);
    run;

  %end;


  /*
  / Final datastep to creates &g_dddatasetname with label set as DDDATASETLABEL
  /---------------------------------------------------------------------------*/

  data &g_dddatasetname (label = &dddatasetlabel);
    set &prefix.5;
  run;


  /*
  / If DISPLAY is set to N, jump to "FINISH stage begins here"
  /---------------------------------------------------------------------------*/

  %if %upcase(&display) eq N %then
  %do;
    %goto FINISH_STAGE;
  %end;


  /*
  / OUTPUT stage begins here
  /---------------------------------------------------------------------------*/

  %OUTPUT_STAGE:


  /*
  / If just doing a refresh of titles/footnotes, i.e. &G_ANALY_DISP eq D, write
  / to the log a list of parameters and global macro variables whose values
  / have been specified but have been ignored.
  /---------------------------------------------------------------------------*/

  %if &g_analy_disp eq D %then
  %do;

    %put %str(RTN)OTE: TU_LIST: Just doing refresh of titles/footnotes. Values of analysis parameters may be ignored.;

    %if %bquote(&dsetin) ne %then
    %do;
      %put %str(RTN)OTE: TU_LIST: Parameter DSETIN, value &dsetin is ignored;
    %end;

    %if %bquote(&stackvar1) ne %then
    %do;
      %put %str(RTN)OTE: TU_LIST: Parameter STACKVAR1, value &stackvar1 is ignored;
    %end;

    %if %bquote(&stackvar2) ne %then
    %do;
      %put %str(RTN)OTE: TU_LIST: Parameter STACKVAR2, value &stackvar2 is ignored;
    %end;

    %if %bquote(&stackvar3) ne %then
    %do;
      %put %str(RTN)OTE: TU_LIST: Parameter STACKVAR3, value &stackvar3 is ignored;
    %end;

    %if %bquote(&stackvar4) ne %then
    %do;
      %put %str(RTN)OTE: TU_LIST: Parameter STACKVAR4, value &stackvar4 is ignored;
    %end;

    %if %bquote(&stackvar5) ne %then
    %do;
      %put %str(RTN)OTE: TU_LIST: Parameter STACKVAR5, value &stackvar5 is ignored;
    %end;

    %if %bquote(&stackvar6) ne %then
    %do;
      %put %str(RTN)OTE: TU_LIST: Parameter STACKVAR6, value &stackvar6 is ignored;
    %end;

    %if %bquote(&stackvar7) ne %then
    %do;
      %put %str(RTN)OTE: TU_LIST: Parameter STACKVAR7, value &stackvar7 is ignored;
    %end;

    %if %bquote(&stackvar8) ne %then
    %do;
      %put %str(RTN)OTE: TU_LIST: Parameter STACKVAR8, value &stackvar8 is ignored;
    %end;

    %if %bquote(&stackvar9) ne %then
    %do;
      %put %str(RTN)OTE: TU_LIST: Parameter STACKVAR9, value &stackvar9 is ignored;
    %end;

    %if %bquote(&stackvar10) ne %then
    %do;
      %put %str(RTN)OTE: TU_LIST: Parameter STACKVAR10, value &stackvar10 is ignored;
    %end;

    %if %bquote(&stackvar11) ne %then
    %do;
      %put %str(RTN)OTE: TU_LIST: Parameter STACKVAR11, value &stackvar11 is ignored;
    %end;

    %if %bquote(&stackvar12) ne %then
    %do;
      %put %str(RTN)OTE: TU_LIST: Parameter STACKVAR12, value &stackvar12 is ignored;
    %end;

    %if %bquote(&stackvar13) ne %then
    %do;
      %put %str(RTN)OTE: TU_LIST: Parameter STACKVAR13, value &stackvar13 is ignored;
    %end;

    %if %bquote(&stackvar14) ne %then
    %do;
      %put %str(RTN)OTE: TU_LIST: Parameter STACKVAR14, value &stackvar14 is ignored;
    %end;

    %if %bquote(&stackvar15) ne %then
    %do;
      %put %str(RTN)OTE: TU_LIST: Parameter STACKVAR15, value &stackvar15 is ignored;
    %end;

    %if %bquote(&display) ne %then
    %do;
      %put %str(RTN)OTE: TU_LIST: Parameter DISPLAY, value &display is ignored;
    %end;

    %if %bquote(&varlabelstyle) ne %then
    %do;
      %put %str(RTN)OTE: TU_LIST: Parameter VARLABELSTYLE, value &varlabelstyle is ignored;
    %end;

    %if %bquote(&dddatasetlabel) ne %then
    %do;
      %put %str(RTN)OTE: TU_LIST: Parameter DDDATASETLABEL, value &dddatasetlabel is ignored;
    %end;

    %if %bquote(&computebeforepagelines) ne %then
    %do;
      %put %str(RTN)OTE: TU_LIST: Parameter COMPUTEBEFOREPAGELINES, value &computebeforepagelines is ignored;
    %end;

    %if %bquote(&computebeforepagevars) ne %then
    %do;
      %put %str(RTN)OTE: TU_LIST: Parameter COMPUTEBEFOREPAGEVARS, value &computebeforepagevars is ignored;
    %end;

    %if %bquote(&getdatayn) ne %then
    %do;
      %put %str(RTN)OTE: TU_LIST: Parameter GETDATAYN, value &getdatayn is ignored;
    %end;

    %if %bquote(&labelvarsyn) ne %then
    %do;
      %put %str(RTN)OTE: TU_LIST: Parameter LABELVARSYN, value &labelvarsyn is ignored;
    %end;

  %end; /* %if &g_analy_disp eq D */


  /*
  / Define header using %tu_header()
  /---------------------------------------------------------------------------*/

  %tu_header()


  /*
  / Define footer using %tu_footer(dsetout=&prefix.foot)
  /---------------------------------------------------------------------------*/

  %tu_footer(dsetout=&prefix.foot)


/*
/ SL02
/
/ If a table is being generated in /arprod, then tu_display will be called
/ twice: firstly, to generate the table as an RTF file; secondly, to generate
/ the table as an ASCII file. When the ASCII file is generated, tu_pagenum is
/ called and it resets titles and footnotes when its USAGE parameter is set to 
/ AFTER. Therefore, the RTF file is generated before the ASCII file, so that
/ both files will include the titles and footnotes that were created by 
/ tu_header and tu_footer.
/ 
/ If a table is not being generated in /arprod, then tu_display will only be 
/ called once, to generate the output as an ASCII file.
/
/ SL05
/
/ The global macro variable g_rtf_outfile, created by ts_setup, will be blank
/ if no RTF file is required, otherwise it will resolve to the pathname of the
/ required RTF file.
/-----------------------------------------------------------------------------*/

%if %length(&g_rtf_outfile) gt 0 %then %let first_m = 1;
%else %let first_m = 2;

%do m = &first_m %to 2;

  %if &m eq 1 %then
  %do;

    options orientation = landscape;

    /*
    / The nowidwovar option does not work when we call tu_display with the RTF
    / destination open, because all of the output sent to the second temporary
    / file in tu_display would also be sent to the RTF file.
    /-------------------------------------------------------------------------*/

    %let initial_nowidowvar = &nowidowvar;
    %let nowidowvar = ;

    /* 
    / Set flowvars to blank whilst generating the RTF file, so that the split
    / character will not appear in the data display.
    /-------------------------------------------------------------------------*/

    %let initial_flowvars = &flowvars;
    %let flowvars =;

    /*
    / SL05
    /
    / If an HTML file has the suffix '.rtf', then MS Word would still be able
    / to read it. The 'RTF' file will be created as an HTML document, because
    / with ODS HTML it is possible to append to a file after it has already 
    / been closed. This is useful if we wish to generate an 'RTF' file which
    / captures the output from calling tu_list multiple times.
    / The 'rtf' style that is supplied with the SAS system will be used rather
    / than a customized sytle created by PROC TEMPLATE, because the exact style
    / used in a clinical study report will vary - i.e. the file will in any case
    / be manually formatted by the CSR author. 
    /-------------------------------------------------------------------------*/

    %if %sysfunc(fileexist(&g_rtf_outfile..rtf)) eq 0 %then
    %do;
      filename _list0 "&g_rtf_outfile..rtf";
      ods html body = _list0 (no_bottom_matter) style = rtf;
    %end;
    %else
    %do;
      filename _list0 "&g_rtf_outfile..rtf" mod;
      ods html file = _list0 (no_top_matter no_bottom_matter) anchor = 'end' style = rtf; 
    %end;

    /*
    / Close ODS Listing destination.
    /-------------------------------------------------------------------------*/

    ods listing close;

  %end; /* %if &m eq 1 %then */

  %else %if &m eq 2 %then
  %do;

    /*
    / Allocate output destination with %tu_pagenum(usage=before, ref=tu_list)
    /-------------------------------------------------------------------------*/

    %tu_pagenum(usage=before,
		ref=tu_list
	       )
  %end; /* %else %if &m eq 2 %then */


  /*
  / Use %tu_display to list the output.
  /
  / Tu_display will be called with the following values related to
  / ComputeBeforePage:
  /
  / ComputeBeforePageVars - the derived variables whose values have been created
  / from our own ComputeBeforePageLines value. These values are preceded by our
  / ComputeBeforePageVars value in order to get the correct sort sequence for
  / the output (xref: noprintvars)
  /
  / OrderVars - Nothing specified because our ComputeBeforePageVars value is
  / passed to tu_display as ComputeBeforePageVars and thus they will
  / automatically be defined as ordervars
  /
  / Columns - Nothing specified because our ComputeBeforePageVars value is
  / passed to tu_display as ComputeBeforePageVars and thus they will
  / automatically be defined as columns
  /
  / NoPrintVars - Specifies our ComputeBeforePageVars to ensure no LINE
  / statement is generated for them (despite them being ComputeBeforePageVars).
  / Thus they will head-up the columns statement and will head-up the ordering,
  / but will not appear in the printed output
  /---------------------------------------------------------------------------*/

  %tu_display(dsetin         = &g_dddatasetname,

          %if %bquote(&ComputeBeforePageVars) ne %then
          %do;
              ComputeBeforePageVars =&computebeforepagevars. %do zz=1 %to &cbpvar0;
                                                                  cbpval&zz
                                                             %end; ,
          %end;

              columns        = &columns,
              ordervars      = &ordervars,
              descending     = &descending,
              orderformatted = &orderformatted,
              orderfreq      = &orderfreq,
              orderdata      = &orderdata,
              noprintvars    = &computebeforepagevars &noprintvars,
              byvars         = &byvars,
              flowvars       = &flowvars,
              widths         = &widths,
              defaultwidths  = &defaultwidths,
              skipvars       = &skipvars,
              pagevars       = &pagevars,
              idvars         = &idvars,
              linevars       = &linevars,
              centrevars     = &centrevars,
              leftvars       = &leftvars,
              rightvars      = &rightvars,
              colspacing     = &colspacing,
              varspacing     = &varspacing,
              formats        = &formats,
              labels         = &labels,
              break1         = &break1,
              break2         = &break2,
              break3         = &break3,
              break4         = &break4,
              break5         = &break5,
              nowidowvar     = &nowidowvar,
              sharecolvars   = &sharecolvars,
              sharecolvarsindent = &sharecolvarsindent,
              overallsummary = &overallsummary,
              proptions      = split="&splitchar" &proptions,
              footrefdset    = &prefix.foot
             )

  %if &m eq 1 %then
  %do;

    /*
    / Close the RTF destination.
    / 
    / SL05
    /
    / The 'RTF' file has been created as an HTML file, so it is actually the
    / HTML destination that needs to be closed.
    /-------------------------------------------------------------------------*/

    ods html close;

    /*
    / SL011
    / De-assign fileref that was assigned for creating the 'RTF' output.
    /-------------------------------------------------------------------------*/
    
    filename _list0 clear;

    /*
    / Re-open ODS Listing destination.
    /-------------------------------------------------------------------------*/

    ods listing;

    /*
    / NOWIDOWVAR was set to blank, because it can not be used when generating
    / the RTF version of the data display. Now reset it to its original value
    / so that it can be applied when tu_display is called a second time to 
    / generate the ASCII version of the data display. 
    /-------------------------------------------------------------------------*/

    %let nowidowvar = &initial_nowidowvar;  
 
    /*
    / FLOWVARS was set to blank, in order to prevent the split character from
    / appearing in the RTF file. Now reset it to its initial value, so that it
    / can be applied when tu_display is called to generate the ASCII file, so
    / the text in the columns will not be truncated.
    /-------------------------------------------------------------------------*/

    %let flowvars = &initial_flowvars;

  %end;
  %else %if &m eq 2 %then
  %do;

    /*
    / Finalise the output with %tu_pagenum(usage=after, ref=tu_list)
    /-------------------------------------------------------------------------*/

    %tu_pagenum(usage=after,
		ref=tu_list
	       )

  %end;

%end; /* %do m = &first_m %to 2 */

  /* FINISH stage begins here
  /---------------------------------------------------------------------------*/

  %FINISH_STAGE:


  /*
  / Restore/tidy-up the environment by calling the tu_tidyup macro.
  / Delete all work datasets whose name begins with our
  / work dataset name prefix, and, if necessary, any global macro variables
  / created by tu_maclist.
  /---------------------------------------------------------------------------*/

  %tu_tidyup(glbmac=
  %if %bquote(&ComputeBeforePageVars) eq %str() %then none;
  %else %do j = 0 %to &cbpvar0.;
  cbpvar&j
  %end;  /* %do j = 0 %to &cbpvar0 */

             ,rmdset=&prefix.:
            )

  /*
  / Call %tu_abort()
  /---------------------------------------------------------------------------*/

  %tu_abort()


%mend tu_list;
