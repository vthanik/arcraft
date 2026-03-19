/*--------------------------------------------------------------------------------------------------
| Macro Name        : td_ex2.sas
|                  
| Macro Version     : 2
|                  
| SAS version       : SAS v8
|                  
| Created By        : Yongwei Wang (YW62951)
|                  
| Date              : 28-Jul-03
|                  
| Macro Purpose     : This unit shall create a table "Summary of Exposure to Study Drug"  
|                     defined in IDSL standard data displays identified in the IDSL Data 
|                     Display Standards. 
|                  
| Macro Design      : PROCEDURE STYLE
|                  
| Input Parameters  :
|                  
| Name                Description                                       Default           
| ----------------------------------------------------------------------------------------
| ANALYSISVARDPS      Specifies the number of decimal places to which   (Blank)           
|                     data was captured. If not supplied, the format                      
|                     on the variables in DSETIN will be used (if they                    
|                     exist).                                                             
|                     If different numbers of DPs are required for the                    
|                     different ANALYSISVARS, the parameter may be a                      
|                     list of:                                                            
|                     variable name = number of DPs                                       
|                     The decimal places part will be saved in a                          
|                     temporary variable and the variable name will be                    
|                     passed to the ANALYSISVARDPSVAR parameter of                        
|                     %tu_statsfmt.                                                       
|                     If XMLINFMT is not blank, ANALYSISVARDPS will be                    
|                     ignored.                                                            
|                     If both XMLINFMT and ANALYSISVARDPS are blank,                      
|                     the value of parameter ANALYSISVARFORMATDNAME of                    
|                     %tu_stats will be passed to ANALYSISVARDPSVAR of                    
|                     %tu_statsfmt                                                        
|                     Valid values: Can be one of following three:                        
|                     1. Blank                                                            
|                     2. Number-of-decimal-places                                         
|                     3. variable1 = Number-of-decimal-places  <                          
|                     variable2 = Number-of-decimal-places 
|>                             
|                     The variable1, variable2, 
| must be the                             
|                     variables given as ANALYSISVARS                                     
|                     See Unit Specification for HARP Reporting Tools                     
|                     TU_STATSFMT[9]                                                      
|                                                                                         
| ANALYSISVARS        The variables to be analysed                      Dose              
|                     Valid values: a list of valid SAS variable names                    
|                                                                                         
| BREAK1 BREAK2       For input of user-specified break statements      (blank)           
| BREAK3 BREAK4       Valid values: valid PROC REPORT BREAK statements                    
| BREAK5              (without "break")                                                   
|                     The value of these parameters are passed                            
|                     directly to PROC REPORT as:                                         
|                     BREAK &break1;                                                      
|                                                                                         
| BYVARS              By variables. The variables listed here are       (blank)           
|                     processed as standard SAS by variables                              
|                     Valid values: one or more variable names from                       
|                     DSETIN                                                              
|                     No formatting of the display for these variables                    
|                     is performed by %tu_display.  The user has the                      
|                     option of the standard SAS BY line, or using                        
|                     OPTIONS NOBYLINE and #BYVAL #BYVAR directives in                    
|                     title statements                                                    
|                                                                                         
| CENTREVARS          Variables to be displayed as centre justified     (blank)           
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with COLUMNS                           
|                     Variables not appearing in any of the parameters                    
|                     CENTREVARS, LEFTVARS, or RIGHTVARS will be                          
|                     displayed using the PROC REPORT default.                            
|                     Character variables are left justified while                        
|                     numeric variables are right justified                               
|                                                                                         
| CODEDECODEVARPAIRS  Specifies code and decode variable pairs. These   &g_trtcd          
|                     variables should be in parameter                  &g_trtgrp exdurcd 
|                     GROUPBYVARSANALY. The first variable in the pair  exdurc            
|                     shall contain the code and the second shall                         
|                     contain the decode.                                                 
|                                                                                         
|                     Valid values: Blank or a list of SAS variable                       
|                     names in pairs that are also specified in                           
|                     GROUPBYVARSANALY.                                                   
|                     The decode variables, i.e. the even-numbered                        
|                     variables, must not be specified in PSFORMAT                        
|                                                                                         
| COLSPACING          The value of the between-column spacing           2                 
|                     Valid values: positive integer                                      
|                                                                                         
| COLUMNS             A PROC REPORT column statement specification.     &g_trtcd          
|                     Including spanning titles and variable names      &g_trtgrp tt_bnnm 
|                     Valid values: one or more variable names from     exdurcd exdurc (  
|                     DSETIN plus other elements of valid PROC REPORT   _Daily Dose_ N  
|                     COLUMN statement syntax                           MEAN STD MEDIAN   
|                                                                       MIN MAX )         
|                                                                                         
| COMPLETETYPESVARS   Specify a list of variables which are in          _ALL_             
|                     GROUPBYVARSANALY and the COMPLETETYPES given by                     
|                     PSOPTIONS should be applied to. If it equals                        
|                     _ALL_, all variables in GROUPBYVARSANALY will be                    
|                     included.                                                           
|                     Valid Values:                                                       
|                     _ALL_                                                               
|                     A list of variable names which are in                               
|                     GROUPBYVARSANALY                                                    
|                                                                                         
| COMPUTEBEFOREPAGEL  See Unit Specification for HARP Reporting Tools   (blank)           
| INES                TU_LIST[5] for complete details                                     
|                                                                                         
| COMPUTEBEFOREPAGEV  See Unit Specification for HARP Reporting Tools   No default        
| ARS                 TU_LIST[5] for complete details                                     
|                                                                                         
| COUNTDISTINCTWHATV  Name of the variable(s) whose distinct values     &g_centid         
| ARPOP               are counted when computing big N. Will be passed  &g_subjid         
|                     to COUNTDISTINCTWHATVAR of %tu_addbignvar.                          
|                     Parameter is required if BIGNVARNAME is given                       
|                     Valid values: As defined in Unit Specification                      
|                     for HARP Reporting Tools TU_ADDBIGNVAR[8]                           
|                                                                                         
| DDDATASETLABEL      Specifies the label to be applied to the DD       DD dataset for    
|                     dataset                                           EX2 table         
|                     Valid values: a non-blank text string                               
|                                                                                         
| DEFAULTWIDTHS       Specifies column widths for all variables not     (blank)           
|                     listed in the WIDTHS parameter                                      
|                     Valid values: values of column names and numeric                    
|                     widths such as form valid syntax for a SAS                          
|                     LENGTH statement                                                    
|                     For variables that are not given widths through                     
|                     either the WIDTHS or DEFAULTWIDTHS parameter                        
|                     will be width optimised using:                                      
|                     MAX (variables format width,                                       
|                     width of  column header)                                            
|                                                                                         
| DESCENDING          List of ORDERVARS that are given the PROC REPORT  (blank)           
|                     define statement attribute DESCENDING                               
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with ORDERVARS                         
|                                                                                         
| DSETIN              The investigational product data set to act as    Ardata.exposure   
|                     the subject of the report                                           
|                     Valid values: name of a data set meeting the                        
|                     IDSL dataset specification for investigational                      
|                     product data                                                        
|                                                                                         
| FLOWVARS            Variables to be defined with the flow option in   (Blank)           
|                     PROC REPORT                                                         
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with COLUMNS                           
|                     Flow variables should be given a width through                      
|                     the WIDTHS parameter.  If a flow variable does                      
|                     not have a width specified, the column width                        
|                     will be determined by                                               
|                     MIN(variables format width,                                        
|                     width of column header)                                             
|                                                                                         
| FORMATS             Variables and their format for display. For use   (blank)           
|                     where format for display differs to the format                      
|                     on the DSETIN.                                                      
|                     Valid values: values of column names and formats                    
|                     such as form valid syntax for a SAS FORMAT                          
|                     statement                                                           
|                                                                                         
| GROUPBYVARPOP       Specifies a list of variables to group by when    &g_trtcd          
|                     counting big N using %tu_addbignvar. Usually one                    
|                     variable &g_trtcd.                                                  
|                     It will be passed to GROUPBYVARS of                                 
|                     %tu_addbignvar.                                                     
|                     It is required if BIGNVARNAME is given                              
|                     Valid values: Blank, or a list of valid SAS                         
|                     variable names that exist in population dataset                     
|                     created by %tu_sumstatsinrows calling                               
|                     %tu_getdata                                                         
|                                                                                         
| GROUPBYVARSANALY    Specifies the variables whose values define the   %str(&g_trtcd     
|                     subgroup combinations for the analysis. The       &g_trtgrp         
|                     variables can be divided by statements inside of  (exdurc=Combined
|                     ( and ) to represent different levels of      ; exdurcd=999;)   
|                     subgroup.                                         exdurcd exdurc)   
|                     Valid values: A list of valid SAS variable names                    
|                     with (optionally) valid SAS statements in                           
|                     bracket. The first and last words in the values                     
|                     must be variable names. The variable names must                     
|                     exist in DSETIN.                                                    
|                     The SAS statements must be in the format                            
|                     (variable = value;). Variable must also appear                      
|                     after the closed bracket. Value must be the same                    
|                     type as variable.                                                   
|                                                                                         
| IDVARS              Variables to appear on each page if the report    &g_trtcd          
|                     is wider than 1 page. If no value is supplied to  &g_trtgrp tt_bnnm 
|                     this parameter then all displayable order         exdurcd exdurc    
|                     variables will be defined as IDVARS                                 
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with COLUMNS                           
|                                                                                         
| LABELS              Variables and their label for display. For use    (blank)           
|                     where label for display differs to the label on                     
|                     the DSETIN                                                          
|                     Valid values: pairs of variable names and labels                    
|                                                                                         
| LEFTVARS            Variables to be displayed as left justified       (blank)           
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with COLUMNS                           
|                                                                                         
| LINEVARS            List of order variables that are printed with     (blank)           
|                     LINE statements in PROC REPORT                                      
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with ORDERVARS                         
|                     These values shall be written with a BREAK                          
|                     BEFORE when the value of one of the variables                       
|                     changes. The variables will automatically be                        
|                     defined as NOPRINT                                                  
|                                                                                         
| NOPRINTVARS         Variables listed in the COLUMN parameter that     &g_trtcd exdurcd  
|                     are given the PROC REPORT define statement                          
|                     attribute noprint                                                   
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with COLUMNS                           
|                     These variables are ORDERVARS used to control                       
|                     the order of the rows in the display.                               
|                                                                                         
| NOWIDOWVAR          Variable whose values must be kept together on a  (blank)           
|                     page                                                                
|                     Valid values: names of one or more variables                        
|                     specified in COLUMNS                                                
|                                                                                         
| ORDERDATA           Variables listed in the ORDERVARS parameter that  (blank)           
|                     are given the PROC REPORT define statement                          
|                     attribute order=data                                                
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with ORDERVARS                         
|                     Variables not listed in ORDERFORMATTED,                             
|                     ORDERFREQ, or ORDERDATA are given the define                        
|                     attribute order=internal                                            
|                                                                                         
| ORDERFORMATTED      Variables listed in the ORDERVARS parameter that  (blank)           
|                     are given the PROC REPORT define statement                          
|                     attribute order=formatted                                           
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with ORDERVARS                         
|                     Variables not listed in ORDERFORMATTED,                             
|                     ORDERFREQ, or ORDERDATA are given the define                        
|                     attribute order=internal                                            
|                                                                                         
| ORDERFREQ           Variables listed in the ORDERVARS parameter that  (blank)           
|                     are given the PROC REPORT define statement                          
|                     attribute order=freq                                                
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with ORDERVARS                         
|                     Variables not listed in ORDERFORMATTED,                             
|                     ORDERFREQ, or ORDERDATA are given the define                        
|                     attribute order=internal                                            
|                                                                                         
| ORDERVARS           List of variables that will receive the PROC      &g_trtcd          
|                     REPORT define statement attribute ORDER           &g_trtgrp tt_bnnm 
|                     Valid values: one or more variable names from     exdurcd exdurc    
|                     DSETIN that are also defined with COLUMNS                           
|                                                                                         
| OVERALLSUMMARY      Causes the macro to produce an overall summary    N                 
|                     line. Use with SHARECOLVARS                                         
|                     Valid values: Y or Yes.  Any other values are                       
|                     treated as NO                                                       
|                                                                                         
| PAGEVARS            Variables whose change in value causes the        (blank)           
|                     display to continue on a new page                                   
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with COLUMNS                           
|                                                                                         
| POSTSUBSET          Specifies a SAS IF condition (without "IF" in     (Blank)           
|                     it), which will be applied to the dataset                           
|                     immediately prior to creation of the DD dataset.                    
|                     Valid values: Blank, or a valid SAS statement                       
|                     that can be applied to the dataset prior to                         
|                     creation of the DD dataset.                                         
|                                                                                         
| PROPTIONS           PROC REPORT statement options to be used in       Headline          
|                     addition to MISSING                                                 
|                     Valid values: proc report options                                   
|                     The option Missing can not be overridden                          
|                                                                                         
| PSCLASSOPTIONS      PROC SUMMARY Class Statement Options.             PRELOADFMT        
|                     Valid Values:                                                       
|                     Blank                                                               
|                     Valid PROC SUMMARY CLASS Options (without the                       
|                     leading '/')                                                        
|                     Eg: PRELOADFMT  which can be used in conjunction                    
|                     with PSFORMAT and COMPLETETYPES  (default in                        
|                     PSOPTIONS) to create records for                                    
|                     possible categories that are specified in a                         
|                     format but which may not exist in data being                        
|                     summarised.                                                         
|                                                                                         
| PSFORMAT            Passed to the PROC SUMMARY FORMAT statement.      (Blank)           
|                     Valid Values:                                                       
|                     Blank                                                               
|                     Valid PROC SUMMARY FORMAT statement part                            
|                                                                                         
| PSOPTIONS           Passed to %tu_stats and will be used in PROC      MISSING NWAY      
|                     SUMMARYs options to use. MISSING ensures that                      
|                     class variables with missing values are treated                     
|                     as a valid grouping. COMPLETETYPES adds records                     
|                     showing a freq or n of 0 to ensure a cartesian                      
|                     product of all class variables exists in the                        
|                     output. NWAY writes output for the lowest level                     
|                     combinations of CLASS variables, suppressing all                    
|                     higher level totals.                                                
|                     Valid values:                                                       
|                     Blank                                                               
|                     One or more valid PROC SUMMARY options                              
|                                                                                         
| RIGHTVARS           Variables to be displayed as right justified      (blank)           
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with COLUMNS                           
|                                                                                         
| SHARECOLVARS        List of variables that will share print space.    (blank)           
|                     The attributes of the last variable in the list                     
|                     define the column width and flow options                            
|                     Valid values: one or more variable names from                       
|                     DSETIN                                                              
|                     AE5 shows an example of this style of output                        
|                     The formatted values of the variables shall be                      
|                     written above each other in one column                              
|                                                                                         
| SHARECOLVARSINDENT  Indentation factor for ShareColVars. Stacked      2                 
|                     values shall be progressively indented by                           
|                     multiples of ShareColVarsIndent                                     
|                     Valid values: positive integer                                      
|                                                                                         
| SKIPVARS            Variables whose change in value causes the        &g_trtgrp         
|                     display to skip a line                                              
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with COLUMNS                           
|                                                                                         
| SPLITCHAR           Specifies the split character to be passed to     ~                 
|                     %tu_display                                                         
|                     Valid values: one single character                                  
|                                                                                         
| STACKVAR1-          Specifies any variables that should be stacked    (blank)           
| STACKVAR15          together.  See Unit Specification for HARP                          
|                     Reporting Tools TU_STACKVAR[6] for more detail                      
|                     regarding macro parameters that can be used in                      
|                     the macro call.  Note that the DSETIN parameter                     
|                     will be passed by %tu_list and should not be                        
|                     provided here                                                       
|                                                                                         
| STATSDPS            Specifies decimal places of statistical results   (blank)           
|                     of analysis variables.                                              
|                     If the decimal positions for all variables given                    
|                     by ANALYSISVARS are the same, it should be a                        
|                     list of summary statistic variable name, + and                    
|                     an integer number. For example, Mean +1 STD +2.                     
|                     The integer number means number of decimal                          
|                     places.                                                             
|                     If any statistic variable in STATSLIST is not in                    
|                     STATSDPS, the variable name and +0 will be                          
|                     automatically added to STATSDPS.                                    
|                     If the decimal positions for all variables are                      
|                     not the same, it should be a list of:                               
|                     analysis-var = list-described-above                                 
|                     For example, heart=Mean +1 STD +2 resp=Mean +2                      
|                     STD +2                                                              
|                     The decimal places without the variable name and                    
|                     equals-sign will be passed to %tu_statsfmt.                         
|                     Valid values: Can be one of following three:                        
|                     1. Blank                                                            
|                     2. Statsdps                                                         
|                     3. Variable1 = statsdps  < variable2 = statdps > 
|                     The variable1, variable2, should be the                           
|                     variables specified for ANALYSISVARS.                               
|                     Statdps is the same as STATSDPS parameter                           
|                     defined in %tu_statsfmt. XMLINFMT and STATSDPS                      
|                     are mutually-exclusive. See Unit Specification                      
|                     for HARP Reporting Tools TU_STATSFMT[9]                             
|                                                                                         
| STATSLIST           Specifies a list of summary statistics to         (Blank)           
|                     produce. May also specify correct PROC SUMMARY                      
|                     syntax to rename output variable (N=number                          
|                     MEAN=average)                                                       
|                     Valid values: As defined for the STATSLIST                          
|                     parameter of %tu_stats. See Unit Specification                      
|                     for HARP Reporting Tools TU_STATS[7]                                
|                                                                                         
| VARLABELSTYLE       Specifies the style of labels to be applied by    SHORT             
|                     the %tu_labelvars macro                                             
|                     Valid values: as specified by %tu_labelvars                         
|                                                                                         
| VARSPACING          Spacing for individual columns                    (blank)           
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
| WIDTHS              Variables and width to display                    &g_trtgrp 15      
|                     Valid values: values of column names and numeric  exdurc 10 tt_bnnm 
|                     widths, a list of variables followed by a         3                 
|                     positive integer, e.g.                                              
|                                                                                         
|                     widths = a b 10 c 12 d1-d4 6                                        
|                     Numbered range lists are supported in this                          
|                     parameter however name range lists, name prefix                     
|                     lists, and special SAS name lists are not.                          
|                     Display layout will be optimised by default,                        
|                     however any specified widths will cause the                         
|                     default to be overridden. 
|---------------------------------------------------------------------------------------------------
| Output:   1. output file in plain ASCII text format containing a summary in columns data display 
|              matching the requirements specified as input parameters
|           2. SAS data set that forms the foundation of the data display (the "DD dataset").
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
|           %td_ex2();
|    
|---------------------------------------------------------------------------------------------------
| Change Log :
|
| Modified By :             Yongwei Wang        
| Date of Modification:     20-Aug-2005
| New version number:       2/1
| Modification ID:          YW001
| Reason For Modification:  1.Made PSFORMAT and PSCLASSOPTIONS available to be 
|                             editable by the user and passed through to tu_sumstatsinrows. 
|                             and default for PSCLASSOPTIONS to be preloadfmt.
|                           2.Changed call of %tu_sumstatsincols to %tu_sumstatsinrows.
|                           3.Made parameter PSOPTIONS, CODEDECODEVARPAIRS and COMPLETETYPESVARS
|                             editable by the user
|                           4.For parameter WIDTHS, added tt_bnnm 3 
|---------------------------------------------------------------------------------------------------
| Modified By :
| Date of Modification :
| New Version Number :
| Modification ID :
| Reason For Modification :
|
+-------------------------------------------------------------------------------------------------*/
 

%macro td_ex2(
   ANALYSISVARDPS          =,      /*Number of decimal places  to which data was captured*/
   ANALYSISVARS            =Dose,  /*Summary statistics analysis variables*/
   BREAK1                  =,      /*Break statements*/
   BREAK2                  =,      /*Break statements*/
   BREAK3                  =,      /*Break statements*/
   BREAK4                  =,      /*Break statements*/
   BREAK5                  =,      /*Break statements*/
   BYVARS                  =,      /*By variables*/
   CENTREVARS              =,      /*Centre justify variables*/
   CODEDECODEVARPAIRS      =&g_trtcd &g_trtgrp exdurcd exdurc, /* Code and Decode variables in pairs */
   COLSPACING              =2,     /*Value for between-column spacing*/
   COLUMNS                 =&g_trtcd &g_trtgrp tt_bnnm exdurcd exdurc ("_Daily Dose_" N MEAN STD MEDIAN MIN MAX), /*Columns to be included in the listing (plus spanned headers)*/
   COMPLETETYPESVARS       =_all_, /* Variables which COMPLETETYPES should be applied to */   
   COMPUTEBEFOREPAGELINES  =,      /*Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt : labelvar)*/
   COMPUTEBEFOREPAGEVARS   =,      /*Names of variables that define the sort order for  Compute Before Page lines*/
   COUNTDISTINCTWHATVARPOP =&g_centid &g_subjid, /*Variables whose distinct values are counted when computing big N*/
   DDDATASETLABEL          =DD dataset for EX2 table, /*DD dataset for a table	Label to be applied to the DD dataset*/
   DEFAULTWIDTHS           =,	   /*List of default column widths*/
   DESCENDING              =,	   /*Descending ORDERVARS*/
   DSETIN                  =ardata.exposure, /*Input analysis dataset*/
   FLOWVARS                =,      /*Variables with flow option*/
   FORMATS                 =,      /*Format specification (valid SAS syntax)*/
   GROUPBYVARPOP           =&g_trtcd, /*Variables to group by when counting big N */
   GROUPBYVARSANALY        =%nrstr(&g_trtcd &g_trtgrp (exdurc="Combined"; exdurcd=999) exdurcd exdurc), /*The variables whose values define the subgroup combinations for the analysis*/
   IDVARS                  =&g_trtcd &g_trtgrp tt_bnnm exdurcd exdurc, /*Variables to appear on each page of the report*/
   LABELS                  =,      /*Label definitions (var="var label")*/
   LEFTVARS                =,      /*Left justify variables*/
   LINEVARS                =,      /*Order variables printed with LINE statements*/
   NOPRINTVARS             =&g_trtcd exdurcd, /*No print variables, used to order the display*/
   NOWIDOWVAR              =,      /*List of variables whose values must be kept together on a page*/
   ORDERDATA               =,      /*ORDER=DATA variables*/
   ORDERFORMATTED          =,      /*ORDER=FORMATTED variables*/
   ORDERFREQ               =,      /*ORDER=FREQ variables*/
   ORDERVARS               =&g_trtcd &g_trtgrp tt_bnnm exdurcd exdurc, /*Order variables*/
   OVERALLSUMMARY          =N,     /*Overall summary line at top of tables*/
   PAGEVARS                =,      /*Variables whose change in value causes the display to continue on a new page*/
   POSTSUBSET              =,      /*SAS "IF" condition that applies to the presentation dataset.*/
   PROPTIONS               =Headline, /*PROC REPORT statement options*/
   PSCLASSOPTIONS          =PRELOADFMT, /* PROC SUMMARY CLASS Statement Options */
   PSFORMAT                =,      /* Passed to the PROC SUMMARY FORMAT statement. */
   PSOPTIONS               =NWAY MISSING, /* PROC SUMMARY Options to use */
   RIGHTVARS               =,      /*Right justify variables*/
   SHARECOLVARS            =,      /*Order variables that share print space*/
   SHARECOLVARSINDENT      =2,     /*Indentation factor*/
   SKIPVARS                =&g_trtgrp, /*Variables whose change in value causes the display to skip a line */
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
   STATSLIST               =N MIN MAX MEDIAN STD MEAN, /*List of required summary statistics, e.g. N Mean Median. (or N=number MIN=minimum)*/
   VARLABELSTYLE           =SHORT, /*Specifies the label style for variables*/  
   VARSPACING              =,      /*Column spacing for individual variables*/
   WIDTHS                  =&g_trtgrp 15 exdurc 10 tt_bnnm 3 /*Column widths*/                     
   );         

   /*
   / Write details of macro call to log                               
   /----------------------------------------------------------------------*/
   
   %LOCAL MacroVersion;
   %LET MacroVersion = 2;
 
   %INCLUDE "&g_refdata/tr_putlocals.sas";
   %tu_putglobals() 
   
   /*
   / unquote GROUPBUVARSANALY so that sc can be resolved.             
   /-----------------------------------------------------------------------*/
   
   %LOCAL sc;
   %LET sc=%str(;);
   %LET GROUPBYVARSANALY=%unquote(&GROUPBYVARSANALY);

   /*
   / Pass everything to tu_sumstatsinrows                      
   /-----------------------------------------------------------------------*/
       
   %tu_sumstatsinrows(
      ACROSSCOLLISTNAME        =acrosscollistname_,   
      ACROSSCOLVARPREFIX       =tt_p,                 
      ACROSSVAR                =,             
      ACROSSVARDECODE          =,                  
      ADDBIGNYN                =N,
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
      DENORMYN                 =N,                          
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
      OVERALLSUMMARY           =&OVERALLSUMMARY,
      PAGEVARS                 =&PAGEVARS,
      POSTSUBSET               =&POSTSUBSET,
      PROPTIONS                =&PROPTIONS,
      PSBYVARS                 =,
      PSCLASS                  =,
      PSCLASSOPTIONS           =&PSCLASSOPTIONS,
      PSFORMAT                 =&PSFORMAT,
      PSFREQ                   =,
      PSID                     =,
      PSOPTIONS                =&PSOPTIONS,     
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
      STACKVAR2                =&STACKVAR2,
      STACKVAR3                =&STACKVAR3,
      STACKVAR4                =&STACKVAR4,
      STACKVAR5                =&STACKVAR5,
      STACKVAR6                =&STACKVAR6,
      STACKVAR7                =&STACKVAR7,
      STACKVAR8                =&STACKVAR8,
      STACKVAR9                =&STACKVAR9,
      STACKVAR10               =&STACKVAR10,
      STACKVAR11               =&STACKVAR11,
      STACKVAR12               =&STACKVAR12,
      STACKVAR13               =&STACKVAR13,
      STACKVAR14               =&STACKVAR14,
      STACKVAR15               =&STACKVAR15,
      STATSDPS                 =&STATSDPS,
      STATSINROWSYN            =N,
      STATSLABELS              =,                          
      STATSLIST                =&STATSLIST,
      STATSLISTVARNAME         =tt_svnm,              
      STATSLISTVARORDERVARNAME =tt_svid,  
      TOTALDECODE              =,                     
      TOTALFORVAR              =,                     
      TOTALID                  =,
      VARLABELSTYLE            =&VARLABELSTYLE,
      VARSPACING               =&VARSPACING,
      WIDTHS                   =&WIDTHS,
      XMLINFMT                 =,
      XMLMERGEVAR              =
      )          
                    
   %tu_abort()
                                     
%mend td_ex2;  



