/************************************************************************************
*
*  Macro name:    td_eg3.sas
*
*  Macro version: 1
*
*  SAS version:   8.2
*
*
*  Created by:    Alfred Montalvo Jr, Yongwei Wang (YW62951)
*
*  Date:          09sep2003
*
*
*  Macro purpose: display macro to generate IDSL eg3 listing
*
*  Macro design:  procedure style
*
*************************************************************************************
*  Input parameters:
*
*   Name           Description                                         default
*------------------------------------------------------------------------------------
*  dsetin          The ecg data set to act as the subject
*                  of the report. Valid values: name of a data set
*                  meeting the IDSL dataset specification for ecg
*                  data                                                ardata.ecg
*  stackvar1       Specifies any variables that should be stacked 
*                  together.  See Unit Specification for HARP 
*                  Reporting Tools TU_STACKVAR[5] for more detail 
*                  regarding macro parameters that can be used in 
*                  the macro call.  Note that the DSETIN parameter 
*                  will be passed by %tu_list and should not be 
*                  provided here.                                      %str(varsin=&g_centid &g_subjid, varout=st_eg_cs3, sepc=/) 
*  stackvar2       Additional stacked variable (ref: stackvar1)        %str(varsin=age sex race, varout=st_eg_asr3, sepc=/)
*  stackvar3       Additional stacked variable (ref: stackvar1)        Blank
*  stackvar4       Additional stacked variable (ref: stackvar1) 
*  - stackvar15                                                        blank
*  varlabelstyle   Specifies the style of labels to be applied by 
*                  the %tu_labelvars macro Valid values: as 
*                  specified by %tu_labelvars, i.e. SHORT or STD       short
*
*  dddatasetlabel  Specifies the label to be applied to the 
*                  DD dataset Valid values: a non-blank text 
*                  string                                              DD dataset for EG3 listing
*  splitchar       Specifies the split character to be passed to 
*                  %tu_display Valid values: one single character      ~
*  computebefore-
*  pagelines       See Unit Specification for HARP Reporting Tools
*                  TU_LIST[4] for complete details.                    TRTMNT $local. : &g_trtgrp
*  computebefore-
*  pagevars        See Unit Specification for HARP Reporting Tools 
*                  TU_LIST[4] for complete details.                    &g_trtcd  
*  columns         A PROC REPORT column statement specification.  
*                  Including spanning titles and variable names
*                  Valid values: one or more variable names from 
*                  DSETIN plus other elements of valid PROC REPORT 
*                  COLUMN statement syntax                             &g_trtcd &g_trtgrp &g_centid &g_subjid st_eg_cs3 st_eg_asr3 visitnum visit egdt egactdy eghr pr qrs qt qtcb qtcf
*  ordervars       List of variables that will receive the PROC 
*                  REPORT define statement attribute ORDER Valid 
*                  values: one or more variable names from DSETIN 
*                  that are also defined with COLUMNS                  &g_trtcd &g_trtgrp &g_centid &g_subjid st_eg_cs3 st_eg_asr3 visitnum visit egdt   
*  sharecolvars    List of variables that will share print space. 
*                  The attributes of the last variable in the list 
*                  define the column width and flow options Valid 
*                  values: one or more variable names from DSETIN
*                  AE5 shows an example of this style of output
*                  The formatted values of the variables shall be 
*                  written above each other in one column.             blank
*  sharecolvars-
*  indent          Indentation factor for ShareColVars. Stacked 
*                  values shall be progressively indented by 
*                  multiples of ShareColVarsIndent Valid values: 
*                  positive integer                                    2
*  linevars        List of order variables that are printed with 
*                  LINE statements in PROC REPORT Valid values: one
*                  or more variable names from DSETIN that are also 
*                  defined with ORDERVARS These values shall be 
*                  written with a BREAK BEFORE when the value of
*                  one of the variables change. The variables will 
*                  automatically be defined as NOPRINT                 blank
*  descending      List of ORDERVARS that are given the PROC 
*                  REPORT define statement attribute DESCENDING
*                  Valid values: one or more variable names from 
*                  DSETIN that are also defined with ORDERVARS         blank
*  orderformatted  Variables listed in the ORDERVARS parameter 
*                  that are given the PROC REPORT define statement 
*                  attribute order=formatted.  Valid values: one 
*                  or more variable names from DSETIN that are 
*                  also defined with ORDERVARS Variables not 
*                  listed in ORDERFORMATTED, ORDERFREQ, or 
*                  ORDERDATA are given the define attribute 
*                  order=internal                                      blank
*  orderfreq       Variables listed in the ORDERVARS parameter 
*                  that are given the PROC REPORT define statement
*                  attribute order=freq. Valid values: one or more 
*                  variable names from DSETIN that are also 
*                  defined with ORDERVARS Variables not listed in 
*                  ORDERFORMATTED, ORDERFREQ, or ORDERDATA are 
*                  given the define attribute order=internal           blank
*  orderdata       Variables listed in the ORDERVARS parameter 
*                  that are given the PROC REPORT define statement 
*                  attribute order=data. Valid values: one or more 
*                  variable names from DSETIN that are also defined 
*                  with ORDERVARS Variables not listed in 
*                  ORDERFORMATTED, ORDERFREQ, or ORDERDATA are 
*                  given the define attribute order=internal           blank
*  noprintvars     Variables listed in the COLUMN parameter that 
*                  are given the PROC REPORT define statement 
*                  attribute noprint. Valid values: one or more 
*                  variable names from DSETIN that are also 
*                  defined with COLUMNS These variables are 
*                  ORDERVARS used to control the order of the 
*                  rows in the display.                                &g_trtcd  &g_trtgrp visitnum &g_centid &g_subjid
*  byvars          By variables. The variables listed here are 
*                  processed as standard SAS by variables Valid 
*                  values: one or more variable names from DSETIN
*                  No formatting of the display for these variables
*                  is performed by %tu_display.  The user has the
*                  option of the standard SAS BY line, or using 
*                  OPTIONS NOBYLINE and #BYVAL #BYVAR directives 
*                  in title statements.                                blank
*  flowvars        Variables to be defined with the flow option
*                  Valid values: one or more variable names from 
*                  DSETIN that are also defined with COLUMNS
*                  Flow variables should be given a width through 
*                  the WIDTHS.  If a flow variable does not have 
*                  a width specified the column width will be 
*                  determined by MIN(variable?s format width,
*                  width of  column header)                            st_eg_cs3 visit st_eg_asr3 
*  widths          Variables and width to display Valid values: 
*                  values of column names and numeric widths, a 
*                  list of variables followed by a positive 
*                  integer, e.g. widths = a b 10 c 12 d1-d4 6
*                  Numbered range lists are supported in this 
*                  parameter however name range lists, name prefix
*                  lists, and special SAS name lists are not.
*                  Display layout will be optimised by default, 
*                  however any specified widths will cause the 
*                  default to be overridden.                           blank
*  defaultwidths   Specifies column widths for all variables not 
*                  listed in the WIDTHS parameter Valid values: 
*                  values of column names and numeric widths such 
*                  as form valid syntax for a SAS LENGTH statement
*                  For variables that are not given widths through 
*                  either the WIDTHS or DEFAULTWIDTHS parameter will 
*                  be width optimised using: MAX (variable's format
*                  width, width of column header)                      &g_trtgrp 90 st_eg_cs3 7 st_eg_asr3 10 visit 12 egdt 10 egactdy 5 eghr 6 pr 6 qrs 5 qt 6 qtcb 5 qtcf 7  
*  skipvars        Variables whose change in value causes the display 
*                  to skip a line Valid values: one or more variable 
*                  names from DSETIN that are also defined with 
*                  COLUMNS                                             blank
*  pagevars        Variables whose change in value causes the 
*                  display to continue on a new page Valid 
*                  values: one or more variable names from 
*                  DSETIN that are also defined with COLUMNS           blank
*  idvars          Variables to appear on each page should the 
*                  report be wider than 1 page. If no value is 
*                  supplied to this parameter then all 
*                  displayable order variables will be defined 
*                  as idvars Valid values: one or more variable
*                  names from DSETIN that are also defined with 
*                  COLUMNS                                             blank
*  centrevars      Variables to be displayed as centre justified
*                  Valid values: one or more variable names from 
*                  DSETIN that are also defined with COLUMNS 
*                  Variables not appearing in any of the 
*                  parameters CENTREVARS, LEFTVARS, or RIGHTVARS 
*                  will be displayed using the PROC REPORT default. 
*                  Character variables are left justified while 
*                  numeric variables are right justified.              blank
*  leftvars        Variables to be displayed as left justified
*                  Valid values: one or more variable names from
*                  DSETIN that are also defined with COLUMNS           blank
*  rightvars       Variables to be displayed as right justified
*                  Valid values: one or more variable names from 
*                  DSETIN that are also defined with COLUMNS           blank
*  colspacing      The value of the between-column spacing 
*                  Valid values: positive integer                      1
*  varspacing      Spacing for individual columns Valid values: 
*                  variable name followed by a spacing value, 
*                  e.g. Varspacing=a 1 b 2 c 0
*                  This parameter does NOT allow SAS variable 
*                  lists. These values will override the overall 
*                  COLSPACING parameter. VARSPACING defines the 
*                  number of blank characters to leave between the 
*                  column being defined and the column immediately 
*                  to its left                                         blank
*  formats         Variables and their format for display. For 
*                  use where format for display differs to the 
*                  format on the DSETIN. Valid values: values of 
*                  column names and formats such as form valid 
*                  syntax for a SAS FORMAT statement                   
*  labels          Variables and their label for display. For use
*                  where label for display differs to the label 
*                  on the DSETIN Valid values: pairs of variable 
*                  names and labels                                    blank
*  break1          For input of user-specified break statements 
*  - break5        Valid values: valid PROC REPORT BREAK
*                  statements (without "break") The value of 
*                  these parameters are passed directly to PROC
*                  REPORT as: BREAK &break1;                           blank
*  proptions       PROC REPORT statement options to be used in 
*                  addition to MISSING. Valid values: proc 
*                  report options. The option 'Missing' can
*                  not be overridden                                   headline 
*  nowidowvar      Variable whose values must be kept together
*                  on a page Valid values: names of one or more
*                  variables specified in COLUMNS                      blank
*
*************************************************************************************
*  Output:
*************************************************************************************
*  Global macro variables created:
*
*          
************************************************************************************
*  Macros called:
*  (@) tr_putlocals
*  (@) tu_putglobals
*  (@) tu_list
*
************************************************************************************
* Change Log
*
* Modified by:             Yongwei Wang
* Date of modification:    13-Map-2004
* New version number:      1/2
* Modification ID:         YW001
* Reason for modification: Removed EGACTTM from parameters.Changed STACKVAR3 to 
*                          blank.
************************************************************************************
* Change Log
*
* Modified by:
* Date of modification:
* New version number:
* Modification ID:
* Reason for modification:
*
************************************************************************************/

%macro td_eg3(
   dsetin         =ardata.ecg, /* Input ecg dataset */
   stackvar1      =%str(varsin=&g_centid &g_subjid, varout=st_eg_cs3, sepc=/), /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
   stackvar2      =%str(varsin=age sex race, varout=st_eg_asr3, sepc=/), /*Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))  */
   stackvar3      =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))  */
   stackvar4      =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar5      =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar6      =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar7      =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar8      =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar9      =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar10     =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar11     =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar12     =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar13     =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar14     =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar15     =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   varlabelstyle  =SHORT,     /* Specifies the label style for variables (SHORT or STD)  */
   dddatasetlabel =DD dataset for EG3 listing, /* Label to be applied to the DD dataset  */
   splitchar      =~,         /* Split character */
   computebeforepagelines=TRTMNT $local. : &g_trtgrp,   /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt : labelvar) */
   computebeforepagevars=&g_trtcd, /* Names of variables that define the sort order for  Compute Before Page lines */
   columns        =&g_trtcd &g_trtgrp &g_centid &g_subjid st_eg_cs3 st_eg_asr3 visitnum visit egdt egactdy eghr pr qrs qt qtcb qtcf, /* Columns to be included in the listing (plus spanned headers) */
   ordervars      =&g_trtcd &g_trtgrp &g_centid &g_subjid st_eg_cs3 st_eg_asr3 visitnum visit egdt, /* Order variables */
   sharecolvars   =,          /* Order variables that share print space */
   sharecolvarsindent=2,      /* Indentation factor */
   linevars       =,          /* Order variables printed with LINE statement  */
   descending     =,          /* Descending ORDERVARS */
   orderformatted =,          /* ORDER=FORMATTED variables */
   orderfreq      =,          /* ORDER=FREQ variables */
   orderdata      =,          /* ORDER=DATA variables */
   noprintvars    =&g_trtcd &g_trtgrp visitnum &g_centid &g_subjid, /* No print variables, used to order the display */
   byvars         =,          /* By variables */
   flowvars       =st_eg_cs3 visit st_eg_asr3, /* Variables with flow option */
   widths         =,          /* Column widths */
   defaultwidths  =&g_trtgrp 90 st_eg_cs3 7 st_eg_asr3 10 visit 12 egdt 10 egactdy 5 eghr 6 pr 6 qrs 5 qt 6 qtcb 5 qtcf 7, /* List of default column widths */
   skipvars       =,          /*  Variables whose change in value causes the display to skip a line */
   pagevars       =,          /* Variables whose change in value causes the display to continue on a new page */
   idvars         =,          /* Variables to appear on each page of the report */
   centrevars     =,          /* Centre justify variables */
   leftvars       =,          /* Left justify variables   */ 
   rightvars      =,          /* Right justify variables  */
   colspacing     =1,         /* Value for between-column spacing        */
   varspacing     =,          /* Column spacing for individual variables */
   formats        =,          /* Format specification (valid SAS syntax) */
   labels         =,          /* Label definitions (var="var label")     */
   break1         =,          /* Break statements */
   break2         =,          /* Break statements */
   break3         =,          /* Break statements */
   break4         =,          /* Break statements */
   break5         =,          /* Break statements */
   proptions      =headline,  /* PROC REPORT statement options                 */
   nowidowvar     =           /* List of variables whose values must be kept together on a page */
   );
    
 /* echo macro parameters to log file below */

 %local MacroVersion;
 %let MacroVersion = 1;

 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals() 

 /*  call tu_list below */

 %tu_list(
    dsetin         =&dsetin,
    stackvar1      =&stackvar1,
    stackvar2      =&stackvar2 ,
    stackvar3      =&stackvar3  ,
    stackvar4      =&stackvar4 ,        
    stackvar5      =&stackvar5  ,         
    stackvar6      =&stackvar6  ,        
    stackvar7      =&stackvar7  ,        
    stackvar8      =&stackvar8  ,         
    stackvar9      =&stackvar9  ,         
    stackvar10     =&stackvar10 ,        
    stackvar11     =&stackvar11 ,        
    stackvar12     =&stackvar12 ,         
    stackvar13     =&stackvar13 ,         
    stackvar14     =&stackvar14 ,        
    stackvar15     =&stackvar15 ,        
    varlabelstyle  =&varlabelstyle,   
    dddatasetlabel =&dddatasetlabel,
    splitchar      =&splitchar,         
    computebeforepagelines=&computebeforepagelines,
    computebeforepagevars=&computebeforepagevars ,
    columns        =&columns,
    ordervars      =&ordervars ,
    sharecolvars   =&sharecolvars,
    sharecolvarsindent=&sharecolvarsindent,
    linevars       =&linevars,         
    descending     =&descending,         
    orderformatted =&orderformatted,          
    orderfreq      =&orderfreq,         
    orderdata      =&orderdata,         
    noprintvars    =&noprintvars,
    byvars         =&byvars,          
    flowvars       =&flowvars,    
    widths         =&widths,         
    pagevars       =&pagevars,          
    idvars         =&idvars,          
    centrevars     =&centrevars,          
    leftvars       =&leftvars,         
    colspacing     =&colspacing,        
    rightvars      =&rightvars,         
    varspacing     =&varspacing,          
    formats        =&formats,          
    labels         =&labels,          
    defaultwidths  =&defaultwidths,
    skipvars       =&skipvars,
    break1         =&break1,          
    break2         =&break2,          
    break3         =&break3,          
    break4         =&break4,         
    break5         =&break5,          
    proptions      =&proptions ,                
    nowidowvar     =&nowidowvar,          
    display        =y,
    getdatayn      =y,
    labelvarsyn    =y,
    overallsummary =n       
    );             
         
%mend td_eg3;
  
