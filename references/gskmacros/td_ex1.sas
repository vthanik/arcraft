/*--------------------------------------------------------------------------------------------------
| Macro Name       : td_ex1.sas
|                 
| Macro Version    : 2
|                 
| SAS version      : SAS v8
|                 
| Created By       : Yongwei Wang (YW62951)
|                 
| Date             : 20-Aug-03
|                 
| Macro Purpose    : This unit shall create a table "Summary of Exposure to Study Drug" defined in 
|                    IDSL standard data displays identified in the IDSL Data Display Standards. 
|
| Macro Design     : PROCEDURE STYLE
|                 
| Input Parameters :
|
| NAME              DESCRIPTION                                                 DEFAULT
|--------------------------------------------------------------------------------------------------- 
| ACROSSVAR         Specifies a variable that has multiple levels and will be   &g_trtcd
|                   transposed to multiple columns 
|                   Valid values: a SAS variable that exists in DSETIN . The 
|                   variable must also be specified in GROUPBYVARSANALY
|
| ANALYSISVARS	    The variables to be analysed.                               dosetot dosecum exdur 
|                   Valid values: a list of SAS variables that exist in DSETIN  
|                                                                                                  
| COLUMNS           A PROC REPORT column statement specification. Including     tt_avid tt_avnm 
|                   spanning titles and variable names                          tt_svid tt_svnm tt_p: 
|                   Valid values: one or more variable names from DSETIN plus   
|                   other elements of valid PROC REPORT COLUMN statement syntax  
|                                                                               
| DDDATASETLABEL	Specifies the label to be applied to the DD dataset         DD dataset for      
|                   Valid values: a non-blank text string                       EX1 table
|
| DSETIN        	Specifies the analysis dataset                                 ardata.exposure
|                   Valid values: name of an existing dataset meeting an IDSL 
|                   dataset specification .
|
| GROUPBYVARSANALY	Specifies the variables whose values define the subgroup    &g_trtcd &g_trtgrp 
|                   combinations for the analysis. The variables can be         
|                   divided by statements inside of '(' and ')' to represent    
|                   different levels of subgroup. See Purpose of Unit           
|                   Specification for HARP Reporting Tools TU_SUMSTATSINCOLS
|                   for details.
|                   Valid values: A list of valid SAS variable names with 
|                   (optionally) valid SAS statements in bracket. The first 
|                   and last words in the values must be variable names. The 
|                   variable names must exist in DSETIN. The SAS statements 
|                   must be in the format (variable = value;). Variable must 
|                   also appear after the closed bracket. Value must be the 
|                   same type as variable.  To add a total column, the syntax 
|                   would be %str((&g_trtcd=999; &g_trtgrp='Total';)) 
|                   &g_trtcd &g_trtgrp
|
| SPLITCHAR         Specifies the split character to be passed to %tu_display   ~
|                   Valid values: one single character
|
| STATSLIST         Specifies a list of summary statistics to be produced. If   N MEAN STD MEDIAN 
|                   different summary statistics are required for the different MIN MAX
|                   ANALYSISVARS, the parameter may be a list of:               
|                   variable-name = summary-statistics. The summary-statistics 
|                   part will be saved in a temporary variable and the variable 
|                   name will be passed to the STATSLIST parameter of %tu_stats. 
|                   Valid values: Can be one of following three:
|                   1. summary-statistics
|                   2. variable1 = summary-statistics  < variable2 = 
|                      summary-statistics >   
|                      The variable1, variable2, ? must be the variables given 
|                      as ANALYSISVARS
|                   Note: the "N=N Mean=Mean SD=SD" format, which is allowed in 
|                   %tu_stats, is not allowed for this macro
|
| VARLABELSTYLE     Specifies the style of labels to be applied by the          SHORT
|                   %tu_labelvars macro.  Valid values:  as specified by 
|                   %tu_labelvars.
|
| ACROSSVARDECODE   Specifies the name of a variable that contains decoded      &g_trtgrp
|                   values of ACROSSVAR, or the name of a SAS format 
|                   Valid values: Blank, or a SAS variable that exists in 
|                   DSETIN, or a SAS format
|
| ANALYSISVARDPS	Specifies the number of decimal places to which data was    (Blank)
|                   captured. If not supplied, the format on the variables in
|                   DSETIN will be used (if they exist). If different numbers 
|                   of DPs are required for the different ANALYSISVARS, the 
|                   parameter may be a list of: variable name = number of DPs
|                   The decimal places part will be saved in a temporary 
|                   variable and the variable name will be passed to the 
|                   ANALYSISVARDPSVAR parameter of %tu_statsfmt. 
|                   If ANALYSISVARDPS is blank, the value of parameter 
|                   ANALYSISVARFORMATDNAME of %tu_stats will be passed to 
|                   ANALYSISVARDPSVAR of %tu_statsfmt 
|                   Valid values: Can be one of following three:
|                   1. Blank
|                   2. Number-of-decimal-places
|                   3. variable1 = Number-of-decimal-places  < variable2 = 
|                      Number-of-decimal-places ?>   
|                      The variable1, variable2, ? must be the variables given 
|                      as ANALYSISVARS. See Unit Specification for HARP 
|                      Reporting Tools TU_STATSFMT
|
| BREAK1-5 	        For input of user-specified break statements                (Blank)
|                   Valid values: valid PROC REPORT BREAK statements (without 
|                   "break"). The value of these parameters are passed 
|                   directly to PROC REPORT as: BREAK &break1;
|
| BYVARS	        By variables. The variables listed here are processed as    (Blank)
|                   standard SAS by variables  
|                   Valid values: one or more variable names from DSETIN 
|                   No formatting of the display for these variables is 
|                   performed by %tu_display.  The user has the option of the 
|                   standard SAS BY line, or using OPTIONS NOBYLINE and #BYVAL 
|                   #BYVAR directives in title statements
|
| CENTREVARS	    Variables to be displayed as centre justified               (Blank)
|                   Valid values: one or more variable names from DSETIN that 
|                   are also defined with COLUMNS Variables not appearing in 
|                   any of the parameters CENTREVARS, LEFTVARS, or RIGHTVARS 
|                   will be displayed using the PROC REPORT default. Character
|                   variables are left justified while numeric variables are 
|                   right justified
|
| CODEDECODEVAR     Specifies code and decode variable pairs. These variables   &g_trtcd &g_trtgrp
| PAIRS             should be in parameter GROUPBYVARSANALY. The first variable 
|                   in the pair shall contain the code and the second shall 
|                   contain the decode.
|                   Valid values: Blank or a list of SAS variable names in 
|                   pairs that are also specified in GROUPBYVARSANALY.The 
|                   decode variables, i.e. the even-numbered variables, must 
|                   not be specified in PSFORMAT
|
| COMPLETETYPESVARS Passed to %tu_statswithtotal. Specify a list of variables  _ALL_
|                   which are in GROUPBYVARSANALY and the COMPLETETYPES given
|                   by PSOPTIONS should be applied to. If it equals _ALL_,
|                   all variables in GROUPBYVARSANALY will be included
|                   Valid values:
|                   _ALL_
|                   A list of variable names which are in  GROUPBYVARSANALY
|
| COLSPACING	    The value of the between-column spacing                     2
|                   Valid values: positive integer
|
|
| COMPUTEBEFOREPA	See Unit Specification for HARP Reporting Tools TU_LIST for (Blank)
| GELINES           complete details
|
| COMPUTEBEFOREPA	See Unit Specification for HARP Reporting Tools TU_LIST for (Blank)
| EVARS             complete details
|
| COUNTDISTINCTWH	Name of the variable(s) whose distinct values are counted   &g_centid &g_subjid
| ATVARPOP          when computing big N. Will be passed to 
|                   COUNTDISTINCTWHATVAR of %tu_addbignvar. Parameter is 
|                   required if BIGNVARNAME is given
|                   Valid values: As defined in Unit Specification for HARP 
|                   Reporting Tools TU_ADDBIGNVAR
|
| DEFAULTWIDTHS 	Specifies column widths for all variables not listed in the (Blank)
|                   WIDTHS parameter
|                   Valid values: values of column names and numeric widths 
|                   such as form valid syntax for a SAS LENGTH statement For 
|                   variables that are not given widths through either the 
|                   WIDTHS or DEFAULTWIDTHS parameter will be width optimised 
|                   using: 
|                   MAX (variable's format width, width of  column header)
|
| DESCENDING	    List of ORDERVARS that are given the PROC REPORT define     (Blank)
|                   statement attribute DESCENDING
|                   Valid values: one or more variable names from DSETIN that
|                   are also defined with ORDERVARS
|
| FLOWVARS       	Variables to be defined with the flow option                tt_avnm tt_svnm
|                   Valid values: one or more variable names from DSETIN that 
|                   are also defined with COLUMNS.  Flow variables should be 
|                   given a width through the WIDTHS.  If a flow variable does 
|                   not have a width specified, the column width will be 
|                   determined by MIN(variable's format width, width of  
|                   column header)
|
| FORMATS           Variables and their format for display. For use where       (Blank)
|                   format for display differs to the format on the DSETIN.
|                   Valid values: values of column names and formats such as 
|                   form valid syntax for a SAS FORMAT statement
|
| GROUPBYVARPOP	    Specifies a list of variables to group by when counting     &g_trtcd
|                   big N using %tu_addbignvar. Usually one variable &g_trtcd. 
|                   It will be passed to GROUPBYVARS of %tu_addbignvar. It is 
|                   required if ADDBIGNYN equals Y. 
|                   Valid values: Blank, or a list of valid SAS variable names 
|                   that exist in population dataset created by 
|                   %tu_sumstatsinrow's calling %tu_getdata.
| 
| IDVARS	        Variables to appear on each page if the report is wider     tt_avid tt_avnm
|                   than 1 page. If no value is supplied to this parameter      tt_svid tt_svnm
|                   then all displayable order variables will be defined as     
|                   IDVARS                                                      
|                   Valid values: one or more variable names from DSETIN that 
|                   are also defined with COLUMNS
|
| LABELS            Variables and their label for display. For use where label  (Blank)
|                   for display differs to the label on the DSETIN 
|                   Valid values: pairs of variable names and labels
|
| LEFTVARS          Variables to be displayed as left justified                 (Blank)
|                   Valid values: one or more variable names from DSETIN that
|                   are also defined with COLUMNS
|
| LINEVARS	        List of order variables that are printed with LINE          (Blank)
|                   statements in PROC REPORT
|                   Valid values: one or more variable names from DSETIN that 
|                   are also defined with ORDERVARS.  These values shall be 
|                   written with a BREAK BEFORE when the value of one of the 
|                   variables changes. The variables will automatically be 
|                   defined as NOPRINT
|
| NOPRINTVARS       Variables listed in the COLUMN parameter that are given the tt_avid tt_svid
|                   PROC REPORT define statement attribute noprint              
|                   Valid values: one or more variable names from DSETIN that 
|                   are also defined with COLUMNS These variables are ORDERVARS 
|                   used to control the order of the rows in the display
|
| NOWIDOWVAR        Variable whose values must be kept together on a page       (Blank)
|                   Valid values: names of one or more variables specified in 
|                   COLUMNS 
|
| ORDERDATA         Variables listed in the ORDERVARS parameter that are given  (Blank)
|                   the PROC REPORT define statement attribute order=data
|                   Valid values: one or more variable names from DSETIN that 
|                   are also defined with ORDERVARS Variables not listed in 
|                   ORDERFORMATTED, ORDERFREQ, or ORDERDATA are given the 
|                   define attribute order=internal
|
| ORDERFORMATTED    Variables listed in the ORDERVARS parameter that are given  (Blank)
|                   the PROC REPORT define statement attribute order=formatted
|                   Valid values: one or more variable names from DSETIN that 
|                   are also defined with ORDERVARS Variables not listed in 
|                   ORDERFORMATTED, ORDERFREQ, or ORDERDATA are given the 
|                   define attribute order=internal
|
| ORDERFREQ         Variables listed in the ORDERVARS parameter that are given  (Blank)
|                   the PROC REPORT define statement attribute order=freq
|                   Valid values: one or more variable names from DSETIN that 
|                   are also defined with ORDERVARS Variables not listed in 
|                   ORDERFORMATTED, ORDERFREQ, or ORDERDATA are given the 
|                   define attribute order=internal
|
| ORDERVARS         List of variables that will receive the PROC REPORT define  tt_avid tt_avnm
|                   statement attribute ORDER                                   tt_svid tt_svnm
|                   Valid values: one or more variable names from DSETIN that   
|                   are also defined with COLUMNS                               
|
| PAGEVARS          Variables whose change in value causes the display to       (Blank)
|                   continue on a new page
|                   Valid values: one or more variable names from DSETIN that 
|                   are also defined with COLUMNS
|
| PROPTIONS         PROC REPORT statement options tyo be used in addition to    Headline
|                   MISSING.  Valid values:  proc report options.  The option
|                   'Missing' can not be overridden.
|
| PSFORMAT          Passed to the PROC SUMMARY FORMAT statement.                &g_trtcd 
|                   Valid Values:                                               &g_trtfmt
|                   Blank
|                   Valid PROC SUMMARY FORMAT statement part.
|
| PSCLASSOPTIONS    PROC SUMMARY Class Statement Options.                       preloadfmt
|                   Valid Values:
|                   Blank
|                   Valid PROC SUMMARY CLASS Options (without the leading '/')
|                   Eg: PRELOADFMT  which can be used in conjunction with 
|                   PSFORMAT and COMPLETETYPES (default in PSOPTIONS) to
|                   create records for possible categories that are specified 
|                   in a format but which may not exist in data being 
|                   summarised.
|
| RIGHTVARS         Variables to be displayed as right justified                (Blank)
|                   Valid values: one or more variable names from DSETIN that 
|                   are also defined with COLUMNS
|
| SHARECOLVARS      List of variables that will share print space. The          (Blank)
|                   attributes of the last variable in the list define the 
|                   column width and flow options
|                   Valid values: one or more variable names from DSETIN AE5 
|                   shows an example of this style of output The formatted 
|                   values of the variables shall be written above each other 
|                   in one column
|
| SHARECOLVARSIN    Indentation factor for ShareColVars. Stacked values shall   2
| DENT              be progressively indented by multiples of 
|                   ShareColVarsIndent
|                   Valid values: positive integer
|
| SKIPVARS          Variables whose change in value causes the display to skip  tt_avnm
|                   a line
|                   Valid values: one or more variable names from DSETIN that
|                   are also defined with COLUMNS
|
| STACKVAR1         Specifies any variables that should be stacked together.    (Blank)
| STACKVAR15        See Unit Specification for HARP Reporting Tools 
|                   TU_STACKVAR for more detail regarding macro parameters that
|                   can be used in the macro call.  Note that the DSETIN 
|                   parameter will be passed by %tu_list and should not be 
|                   provided here
|
| STATSDPS          Specifies decimal places of statistical results of analysis MEDIAN +1 MEAN +1 STD +2
|                   variables.  If the decimal positions for all variables 
|                   given by ANALYSISVARS are the same, it should be a list of 
|                   summary statistic variable name, '+' and an integer number. 
|                   For example, Mean +1 STD +2. The integer number means 
|                   number of decimal places. If any statistic variable in 
|                   STATSLIST is not in STATSDPS, the variable name and +0 will
|                   be automatically added to STATSDPS.  If the decimal 
|                   positions for all variables are not the same, it should be 
|                   a list of: analysis-var = list-described-above. For 
|                   example, heart=Mean +1 STD +2 resp=Mean +2 STD +2 The 
|                   decimal places without the variable name and equals-sign 
|                   will be passed to %tu_statsfmt.
|                   
|                   Valid values: Can be one of following three:
|                   1. Blank
|                   2. Statsdps
|                   3. Variable1 = statsdps  < variable2 = statdps ?>
|                      The variable1, variable2, ? should be the variables 
|                      specified for ANALYSISVARS. 
|                   Statdps is the same as STATSDPS parameter defined in 
|                   %tu_statsfmt. XMLINFMT and STATSDPS are mutually-
|                   exclusive. See Unit Specification for HARP Reporting Tools 
|                   TU_STATSFMT
|
| VARSPACING        Spacing for individual columns                              (Blank)
|                   Valid values: variable name followed by a spacing value, 
|                   e.g. Varspacing=a 1 b 2 c 0. This parameter does NOT allow
|                   SAS variable lists. These values will override the overall 
|                   COLSPACING parameter. VARSPACING defines the number of 
|                   blank characters to leave between the column being defined 
|                   and the column immediately to its left
|
| WIDTHS            Variables and width to display
|                   Valid values: values of column names and numeric widths, a  tt_avnm 14 
|                   list of variables followed by a positive integer, e.g.      tt_svnm 8
|                   widths = a b 10 c 12 d1-d4 6. Numbered range lists are      
|                   supported in this parameter however name range lists, name 
|                   prefix lists, and special SAS name lists are not. Display 
|                   layout will be optimised by default, however any specified 
|                   widths will cause the default to be overridden
|---------------------------------------------------------------------------------------------------
|
|---------------------------------------------------------------------------------------------------
| Output:   1. output file in plain ASCII text format containing a summary in columns data display 
|              matching the requirements specified as input parameters
|           2. SAS data set that forms the foundation of the data display (the "DD dataset").
|           3. SAS data set, same as above, named by DSETOUT parameter if DSETOUT is not empty.
|
| Global macro variables created:  None
|
| Macros called : 
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_putglobals
| (@) tu_sumstatsinrows
|
| Example:  %ts_setup();
|           %td_ex1();
|    
|---------------------------------------------------------------------------------------------------
| Change Log :
|
| Modified By :               Tamsin Corfield
| Date of Modification :      October 16th 2003
| New Version Number :        1/002
| Modification ID :           None
| Reason For Modification :   The header block was edited to correct the 
|                             macros called. tu_sumstatsincols was 
|                             replaced with tu_sumstatsinrows
|------------------------- --------------------------------------------------------------------------
| Modified By:                Yongwei Wang
| Date of Modification:       20-Aug-2005
| New version number:         2/1
| Modification ID:            YW001
| Reason For Modification:    1.Make PSFORMAT and PSCLASSOPTIONS available to be 
|                               editable by the user and passed through to tu_sumstatsinrows. 
|                               Set default value for psformat to be &g_trtcd &g_trtfmt  
|                               and default for PSCLASSOPTIONS to be preloadfmt.
|                             2.Added new parameter COMPLETETYPESVARS.
|                             3.Re-arranged the order of parameters of %tu_sumstatsinrows
|                             4.Passed following parameters to %tu_sumstatsinrows: 
|                               ACROSSCOLLISTNAME(_acrosscolist) 
|                               STATSLABELS(=(blank)) STATSINROWSYN(=Y) BIGNINROWYN(=N)
|                               BIGNVARNAME(=tt_bnnm) TOTALDECODE(=Total) TOTALFORVAR(=(blank))
|                               TOTALID(=999)
|---------------------------------------------------------------------------------------------------
| Modified By :
| Date of Modification :
| New Version Number :
| Modification ID :
| Reason For Modification :
|
+-------------------------------------------------------------------------------------------------*/
 
%macro td_ex1(
   ACROSSVAR               =&g_trtcd, /*Variable that will be transposed to columns*/
   ACROSSVARDECODE         =&g_trtgrp, /*The name of a decode variable for ACROSSVAR, or the name of a format */
   ANALYSISVARDPS          =,      /*Number of decimal places  to which data was captured*/
   ANALYSISVARS            =dosetot dosecum exdur,  /*Summary statistics analysis variables*/
   BREAK1                  =,      /*Break statements*/
   BREAK2                  =,      /*Break statements*/
   BREAK3                  =,      /*Break statements*/
   BREAK4                  =,      /*Break statements*/
   BREAK5                  =,      /*Break statements*/
   BYVARS                  =,      /*By variables*/
   CENTREVARS              =,      /*Centre justify variables*/
   CODEDECODEVARPAIRS      =&g_trtcd &g_trtgrp, /*Code and Decode variables in pairs*/
   COMPLETETYPESVARS       =_all_, /* Variables which COMPLETETYPES should be applied to */ 
   COLSPACING              =2,     /*Value for between-column spacing*/
   COLUMNS                 =tt_avid tt_avnm tt_svid tt_svnm tt_p:, /*Columns to be included in the listing (plus spanned headers)*/
   COMPUTEBEFOREPAGELINES  =,      /*Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt : labelvar)*/
   COMPUTEBEFOREPAGEVARS   =,      /*Names of variables that define the sort order for  Compute Before Page lines*/
   COUNTDISTINCTWHATVARPOP =&g_centid &g_subjid, /*Variables whose distinct values are counted when computing big N*/
   DDDATASETLABEL          =DD dataset for EX1 table, /*Label to be applied to the DD dataset*/
   DEFAULTWIDTHS           =,	   /*List of default column widths*/
   DESCENDING              =,	   /*Descending ORDERVARS*/
   DSETIN                  =ardata.exposure, /*Input analysis dataset*/
   FLOWVARS                =tt_avnm tt_svnm, /*Variables with flow option*/
   FORMATS                 =,      /*Format specification (valid SAS syntax)*/
   GROUPBYVARPOP           =&g_trtcd, /*Variables to group by when counting big N*/
   GROUPBYVARSANALY        =&g_trtcd &g_trtgrp, /*The variables whose values define the subgroup combinations for the analysis*/
   IDVARS                  =tt_avid tt_avnm tt_svid tt_svnm, /*Variables to appear on each page of the report*/
   LABELS                  =,      /*Label definitions (var="var label")*/
   LEFTVARS                =,      /*Left justify variables*/
   LINEVARS                =,      /*Order variables printed with LINE statements*/
   NOPRINTVARS             =tt_avid tt_svid, /*No print variables, used to order the display*/
   NOWIDOWVAR              =,      /*List of variables whose values must be kept together on a page*/
   ORDERDATA               =,      /*ORDER=DATA variables*/
   ORDERFORMATTED          =,      /*ORDER=FORMATTED variables*/
   ORDERFREQ               =,      /*ORDER=FREQ variables*/
   ORDERVARS               =tt_avid tt_avnm tt_svid tt_svnm, /*Order variables*/
   PAGEVARS                =,      /*Variables whose change in value causes the display to continue on a new page*/
   PROPTIONS               =Headline, /*PROC REPORT statement options*/
   PSCLASSOPTIONS          =PRELOADFMT, /* PROC SUMMARY CLASS Statement Options */
   PSFORMAT                =&g_trtcd &g_trtfmt, /* Passed to the PROC SUMMARY FORMAT statement. */
   RIGHTVARS               =,      /*Right justify variables*/
   SHARECOLVARS            =,      /*Order variables that share print space*/
   SHARECOLVARSINDENT      =2,     /*Indentation factor*/
   SKIPVARS                =tt_avnm, /*Variables whose change in value causes the display to skip a line */
   SPLITCHAR               =~,     /*Split character*/
   STACKVAR1               =,      /*Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~))*/
   STACKVAR2               =,      /*Create stacked variables */
   STACKVAR3               =,      /*Create stacked variables */
   STACKVAR4               =,      /*Create stacked variables */
   STACKVAR5               =,      /*Create stacked variables */
   STACKVAR6               =,      /*Create stacked variables */
   STACKVAR7               =,      /*Create stacked variables */
   STACKVAR8               =,      /*Create stacked variables */
   STACKVAR9               =,      /*Create stacked variables */
   STACKVAR10              =,      /*Create stacked variables */
   STACKVAR11              =,      /*Create stacked variables */
   STACKVAR12              =,      /*Create stacked variables */
   STACKVAR13              =,      /*Create stacked variables */
   STACKVAR14              =,      /*Create stacked variables */
   STACKVAR15              =,      /*Create stacked variables */
   STATSDPS                =MEDIAN +1 MEAN +1 STD +2, /*Number of decimal places of summary statistical resultsI*/
   STATSLIST               =N MEAN STD MEDIAN MIN MAX, /*List of required summary statistics, e.g. N Mean Median. (or N=number MIN=minimum)*/
   VARLABELSTYLE           =SHORT, /*Specifies the label style for variables*/  
   VARSPACING              =,      /*Column spacing for individual variables*/
   WIDTHS                  =tt_avnm 14 tt_svnm 8 /*Column widths*/                     
   );                 

   /*
   / Write details of macro call to log                               
   /-------------------------------------------------------------------------*/
   
   %LOCAL MacroVersion;
   %LET MacroVersion = 2;
 
   %INCLUDE "&g_refdata/tr_putlocals.sas";
   %tu_putglobals() 
    
   /*                                                                      
   / Pass everything to tu_sumstatsinrows                             
   /-------------------------------------------------------------------------*/
 
   %tu_sumstatsinrows(
      ACROSSCOLLISTNAME        =acrosscollistname_,
      ACROSSCOLVARPREFIX       =tt_p,    
      ACROSSVAR                =&ACROSSVAR,        
      ACROSSVARDECODE          =&ACROSSVARDECODE,                             
      ADDBIGNYN                =Y,  
      ALIGNYN                  =Y,    
      ANALYSISVARDPS           =&ANALYSISVARDPS,            
      ANALYSISVARNAME          =tt_avnm,
      ANALYSISVARORDERVARNAME  =tt_avid,
      ANALYSISVARS             =&ANALYSISVARS,
      BIGNINROWYN              =N,        
      BIGNVARNAME              =tt_bnnm,
      BREAK1                   =&BREAK1,
      BREAK2                   =&BREAK2,
      BREAK3                   =&BREAK3,
      BREAK4                   =&BREAK4,
      BREAK5                   =&BREAK5,
      BYVARS                   =&BYVARS,
      CENTREVARS               =&CENTREVARS,
      CODEDECODEVARPAIRS       =&CODEDECODEVARPAIRS,
      COLSPACING               =&COLSPACING,
      COLUMNS                  =&COLUMNS,                      
      COMPLETETYPESVARS        =&COMPLETETYPESVARS,
      COMPUTEBEFOREPAGELINES   =&COMPUTEBEFOREPAGELINES,
      COMPUTEBEFOREPAGEVARS    =&COMPUTEBEFOREPAGEVARS,
      COUNTDISTINCTWHATVARPOP  =&COUNTDISTINCTWHATVARPOP,   
      DDDATASETLABEL           =&DDDATASETLABEL,
      DEFAULTWIDTHS            =&DEFAULTWIDTHS,
      DENORMYN                 =Y,       
      DESCENDING               =&DESCENDING,
      DISPLAY                  =Y,
      DSETIN                   =&DSETIN,
      DSETOUT                  =,    
      FLOWVARS                 =&FLOWVARS,
      FORMATS                  =&FORMATS,
      GROUPBYVARPOP            =&GROUPBYVARPOP,
      GROUPBYVARSANALY         =&GROUPBYVARSANALY,       
      IDVARS                   =&IDVARS, 
      LABELS                   =&LABELS,                      
      LABELVARSYN              =Y,     
      LEFTVARS                 =&LEFTVARS,
      LINEVARS                 =&LINEVARS,
      NOPRINTVARS              =&NOPRINTVARS,
      NOWIDOWVAR               =&NOWIDOWVAR,
      ORDERDATA                =&ORDERDATA,
      ORDERFORMATTED           =&ORDERFORMATTED,
      ORDERFREQ                =&ORDERFREQ,
      ORDERVARS                =&ORDERVARS,
      OVERALLSUMMARY           =N,
      PAGEVARS                 =&PAGEVARS,
      POSTSUBSET               =,
      PROPTIONS                =&PROPTIONS,
      PSBYVARS                 =,
      PSCLASS                  =,
      PSCLASSOPTIONS           =&PSCLASSOPTIONS,
      PSFORMAT                 =&PSFORMAT,
      PSFREQ                   =,
      PSID                     =,
      PSOPTIONS                =MISSING COMPLETETYPES NWAY,
      PSOUTPUT                 =,
      PSOUTPUTOPTIONS          =NOINHERIT,
      PSTYPES                  =,
      PSWAYS                   =,
      PSWEIGHT                 =,
      RESULTVARNAME            =tt_result, 
      RIGHTVARS                =&RIGHTVARS,
      SHARECOLVARS             =&SHARECOLVARS,                     
      SHARECOLVARSINDENT       =&SHARECOLVARSINDENT,   
      SKIPVARS                 =&SKIPVARS,
      SPLITCHAR                =&SPLITCHAR,
      STACKVAR1                =&STACKVAR1,
      STACKVAR10               =&STACKVAR10,
      STACKVAR11               =&STACKVAR11,
      STACKVAR12               =&STACKVAR12,
      STACKVAR13               =&STACKVAR13,
      STACKVAR14               =&STACKVAR14,
      STACKVAR15               =&STACKVAR15,
      STACKVAR2                =&STACKVAR2,
      STACKVAR3                =&STACKVAR3,
      STACKVAR4                =&STACKVAR4,
      STACKVAR5                =&STACKVAR5,
      STACKVAR6                =&STACKVAR6,
      STACKVAR7                =&STACKVAR7,
      STACKVAR8                =&STACKVAR8,
      STACKVAR9                =&STACKVAR9,
      STATSDPS                 =&STATSDPS,    
      STATSINROWSYN            =Y,
      STATSLABELS              =,
      STATSLIST                =&STATSLIST,  
      STATSLISTVARNAME         =tt_svnm, 
      STATSLISTVARORDERVARNAME =tt_svid,  
      TOTALDECODE              =Total,
      TOTALFORVAR              =,  
      TOTALID                  =999,
      VARLABELSTYLE            =&VARLABELSTYLE,
      VARSPACING               =&VARSPACING,
      WIDTHS                   =&WIDTHS,                   
      XMLINFMT                 =,
      XMLMERGEVAR              =
      )                        
      
   %tu_abort()
                                         
%mend td_ex1;  



