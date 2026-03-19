/*--------------------------------------------------------------------------------------------------
| Macro Name       : tu_sumstatsinrows.sas
|
| Macro Version    : 2
|
| SAS version      : SAS v8
|
| Created By       : Yongwei Wang (YW62951)
|
| Date             : 28-Jul-03
|
| Macro Purpose    : This unit shall be a utility to satisfy the summary-table-in-rows
|                    requirements of IDSL standard data displays identified in the IDSL Data
|                    Display Standards. To satisfy any individual summary table data display, this
|                    utility shall be called by a "wrapper" macro that passes the appropriate
|                    parameter values to this macro. The layout of the report shall consist of the
|                    standard header and footer combined with an output number, a title, and the
|                    body of the report. Standard header and footer are described in IDSL
|                    Statistical Reporting Displays.
|
|                    Note on creating summaries with the GroupByVarsAnaly parameter:
|                    GroupByVarsAnaly specifies the variables whose values define the subgroup
|                    combinations for the analysis. The variables can be divided by statements
|                    inside of '(' and ')' to represent different levels of subgroup. The
|                    statement(s) between the brackets are used to assign values to the variables
|                    following the closed bracket so that the output of different levels can be
|                    combined together. For example, value VARIABLE1 VARIABLE2 (STATEMENTS)
|                    VARIABLE3 VARIABLE4 means the first level subgroup variables are VARIABLE1
|                    and VARIABLE2, and the second level of subgroup variables are VARIABLE1,
|                    VARIABLE2, VARIABLE3 and VARIABLE4. The statements inside the brackets are
|                    used to assign values to VARIABLE3 and/or VARIABLE4. Summary records will be
|                    created and populated according to the specification of variable=value pairs
|                    within brackets. For example, trtcd trtgrp (visitnum=999; visit="All Visits";)
|                    visitnum visit. %tu_stats will be called for each level of subgroup. The
|                    subgroup variables for each level will be passed to parameter CLASSVARS of
|                    %tu_stats (and they will be used as CLASS variables in PROC SUMMARY called by
|                    %tu_stats).
|
| Macro Design     : PROCEDURE STYLE
|
| Input Parameters :
|
| Name                Description                                       Default           
| ----------------------------------------------------------------------------------------
| ACROSSCOLLISTNAME   Specifies the name of the macro variable that     acrosscollistname_
|                     %TU_DENORM will update with the names of the                        
|                     variables created by the transpose(s).  In most                     
|                     cases this is a variable that is LOCAL to the                       
|                     program that called %tu_DENORM.                                     
|                     Valid values:                                                       
|                     SAS macro variable name                                             
|                                                                                         
| ACROSSCOLVARPREFIX  Specifies a string that will be the prefix of     tt_p              
|                     new transposed variable names                                       
|                     Valid values: a valid SAS variable name string                      
|                                                                                         
| ACROSSVAR           Specifies a variable that has multiple levels     &g_trtcd         
|                     and will be transposed to multiple columns                          
|                     Valid values: a SAS variable that exists in                         
|                     DSETIN . The variable must also be specified in                     
|                     GROUPBYVARSANALY                                                    
|                                                                                         
| ACROSSVARDECODE     Specifies the name of a variable that contains    &g_trtgrp          
|                     decoded values of ACROSSVAR, or the name of a                       
|                     SAS format                                                          
|                     Valid values: Blank, or a SAS variable that                         
|                     exists in DSETIN, or a SAS format                                   
|                                                                                         
| ADDBIGNYN           Add big N to the value of ACROSSVAR: Yes or No    Y                 
|                     Valid values: Y, N                                                  
|                                                                                         
| ALIGNYN             Execute %tu_align macro: Yes or No                Y                 
|                     Valid values: Y, N                                                  
|                                                                                         
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
|                     variable1 = Number-of-decimal-places <                             
|                     variable2 = Number-of-decimal-places ...>
|                             
|                     The variable1, variable2, must be the                             
|                     variables given as ANALYSISVARS                                     
|                                                                                         
| ANALYSISVARNAME     Specifies the name of variable to be used to      tt_avnm           
|                     save (in the DSETOUT) the variable labels or                        
|                     names given by ANALYSISVARS                                         
|                     Valid values: a valid SAS variable name. DSETIN                     
|                     must not contain a variable with this name                          
|                                                                                         
| ANALYSISVARORDERVA  Specifies the name of a variable to be used to    tt_avid           
| RNAME               save (in the DSETOUT) the variable order given                      
|                     by ANALYSISVARS.                                                    
|                     The order will be expressed as sequential                           
|                     integers                                                            
|                     Valid values: a valid SAS variable name. DSETIN                     
|                     must not contain a variable with this name                          
|                                                                                         
| ANALYSISVARS        The variables to be analysed.                     (Blank)           
|                     Valid values: a list of SAS variables that exist                    
|                     in DSETIN                                                           
|                                                                                         
| BIGNINROWYN         Specify If bigN should be displayed in rows,      N                 
|                     other than in column Label                                          
|                     Valid values: Y or N                                                
|                                                                                         
| CODEDDECODEVARPAIR  Specifies code and decode variable pairs. These   (Blank)           
| S                   variables should be in parameter                                    
|                     GROUPBYVARSANALY. The first variable in the pair                    
|                     shall contain the code and the second shall                         
|                     contain the decode.                                                 
|                     Valid values: Blank or a list of SAS variable                       
|                     names in pairs that are also specified in                           
|                     GROUPBYVARSANALY.                                                   
|                     The decode variables, i.e. the even-numbered                        
|                     variables, must not be specified in PSFORMAT                        
|                                                                                         
| COUNTDISTINCTWHATV  A list of variables containing the value of what  &g_centid         
| ARPOP               is being counted. Will be passed to               &g_subjid         
|                     COUNTDISTINCTWHATVAR of %tu_addbignvar.                             
|                     COUNTDISTINCTWHATVARPOP is required if ADDBIGNYN                    
|                     equals Y                                                            
|                     Valid values: Blank or as defined in                                
|                     %tu_addbignvar                                                      
|                                                                                         
| DENORMYN            Transpose result variables from rows to columns   Y                 
|                     across the ACROSSVAR  Y/N?                                         
|                     Valid Values: Y  or  N                                              
|                                                                                         
| DSETIN              Specifies the analysis dataset                    (Blank)           
|                     Valid values: name of an existing dataset                           
|                     meeting an IDSL dataset specification                               
|                     US/RT/TU_SUMSTATSINROWS-013                                         
|                                                                                         
| DSETOUT             Specifies the name of the output summary dataset  (Blank)           
|                     Valid values: Blank, or a valid SAS dataset name                    
|                                                                                         
| GROUPBYVARPOP       Specifies a list of variables to group by when    &g_trtcd          
|                     counting big N using %tu_addbignvar. Usually one                    
|                     variable &g_trtcd.                                                  
|                     It will be passed to GROUPBYVARS of                                 
|                     %tu_addbignvar.                                                     
|                     It is required if ADDBIGNYN equals Y                                
|                     Valid values: Blank, or a list of valid SAS                         
|                     variable names that exist in the population                         
|                     dataset created by %tu_sumstatsinrows calling                       
|                     %tu_getdata                                                         
|                                                                                         
| GROUPBYVARSANALY    Specifies the variables whose values define the   (Blank)           
|                     subgroup combinations for the analysis. The                         
|                     variables can be divided by statements inside of                    
|                     ( and ) to represent different levels of                        
|                     subgroup.                                                           
|                     See Purpose for details.                                            
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
| LABELVARSYN         Execute %tu_labelvars macro : Yes or No           Y                 
|                     Valid values: Y, N                                                  
|                                                                                         
| POSTSUBSET          Specifies a SAS IF condition (without "IF" in     (Blank)           
|                     it), which will be applied to the dataset                           
|                     immediately prior to creation of the DD dataset                     
|                     Valid values: Blank, or a valid SAS if-condition                    
|                     that can be applied to the dataset prior to                         
|                     creation of the DD dataset                                          
|                                                                                         
| RESULTVARNAME       Specifies the result variables to be retained     tt_result         
|                     (if the data is not to be denormalised, i.e.                        
|                     transposed from rows to columns across the                          
|                     ACROSSVAR)                                                          
|                     Valid values: one or more valid SAS variable                        
|                     names. DSETIN must not contain variables with                       
|                     these names                                                         
|                                                                                         
| SPLITCHAR           Specifies the split character to be passed to     ~                 
|                     %tu_list                                                            
|                     Valid values: one single character                                  
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
|                     3. Variable1 = statsdps  < variable2 = statdps                      
|                     
|                     The variable1, variable2, should be the
|                     variables specified for ANALYSISVARS                                
|                     Statdps is the same as STATSDPS parameter                           
|                     defined in %tu_statsfmt. XMLINFMT and STATSDPS                      
|                     are mutually-exclusive                                              
|                                                                                         
| STATSINROWSYN       Specify if convert summary statistical results    Y                 
|                     to rows. The result of each statistics is saved                     
|                     in a variable. If set to Y, all statistics will                     
|                     be saved in a single variable (&RESULTVARNAME)                      
|                     and the label of the statistics variables will                      
|                     be saved in another variable (&STATSLISTVARNAME)                    
|                     Valid values: Y or N      
|                                                                                         
| STATSLIST           Specifies a list of summary statistics to be      (Blank)           
|                     produced.                                                           
|                     If different summary statistics are required for                    
|                     the different ANALYSISVARS, the parameter may be                    
|                     a list of:                                                          
|                     variable name = summary statistics                                  
|                     The summary statistics part will be saved in a                      
|                     temporary variable and the variable name will be                    
|                     passed to the STATSLIST parameter of %tu_stats.                     
|                     Valid values: Can be one of following three:                        
|                     1. summary-statistics                                               
|                     2. variable1 = summary-statistics  < variable2 =                    
|                     summary-statistics ... >                                              
|
|                     The variable1, variable2, must be the variables 
|                     given as ANALYSISVARS                                     
|                     Note: the "N=N Mean=Mean SD=SD" format, which is                    
|                     allowed in %tu_stats, is not allowed for this                       
|                     macro                                                               
|                                                                                         
| STATSLABELS         Specify a label statement which will be used to   (Blank)           
|                     defined labels for summary statistical result                       
|                     variables defined in parameter STATSLIST                            
|                     Valid values: Blank or a valid SAS label                            
|                     statement contents                                                  
|                                                                                         
| STATSLISTVARNAME    Specifies the name of the variable that saves     tt_svnm           
|                     (in the DSETOUT) summary statistic variable                         
|                     names. Those variables are created by %tu_stats                     
|                     Valid values: a valid SAS variable name. DSETIN                     
|                     must not contain a variable with this name                          
|                                                                                         
| STATSLISTVARORDERV  Specifies the name of the variable that saves     tt_svid           
| ARNAME              (in the DSETOUT) summary statistic variable                         
|                     order. Those variables are created by %tu_stats                     
|                     Valid values: a valid SAS variable name. DSETIN                     
|                     must not contain a variable with this name                          
|                                                                                         
| VARLABELSTYLE       Specifies the style of labels to be applied by    SHORT             
|                     the %tu_labelvars macro                                             
|                     Valid values: as specified by %tu_labelvars                         
|                                                                                         
| XMLINFMT            Specifies a file name, with full path, which      (Blank)           
|                     specifies the format of the summary statistic                       
|                     and analysis variables as specified in macro                        
|                     %tu_statsfmt.                                                       
|                     If there are multiple variables given by                            
|                     &analysisvars, it can also be in the format:                        
|                     variable = file-name                                                
|                     Valid values: Can be one of following three                         
|                     1. Blank                                                            
|                     2. A file name                                                      
|                     3. variable1 = filename1, < variable2 =                             
|                     filename2                                                           
|                     The variable1, variable2, should be the
|                     variables specified for ANALYSISVARS    
|                     The valid format of the file given by the file                      
|                     name is the same as specified in %tu_statsfmt.                      
|                     XMLINFMT and STATSDPS are mutually-exclusive                        
|                                                                                         
| XMLMERGEVAR         Variable to merge input data and XML format       (Blank)           
|                     data. This variable must exist in both datasets.                    
|                     Required if XMLINFMT is not blank. It can also                      
|                     be in the format of several analysis-variable =                    
|                     merge-variable if there are multiple variables                     
|                     given by &analysisvars                                              
|                     Valid values: Can be one of following three                         
|                     1. Blank                                                            
|                     2. A file name                                                      
|                     3. Analysis-variable1 = merge-variable1 <                           
|                     analysis-variable2 = merge-variable2 ...> 
|                           
|                     The analysis-variable1, analysis-variable2, etc.                    
|                     should be the variables specified for                               
|                     ANALYSISVARS                                                        
|                     The valid values for merge variables are the                        
|                     same as specified in %tu_statsfmt    
|
|---------------------------------------------------------------------------------------------------
| Plus, some parameters supported by %tu_list (as defined in Unit Specification for HARP Reporting 
| Tools TU_LIST[4] ) Those parameters (and their defaults in %tu_sumstatsinrows) are as follows:
|   BREAK1-BREAK5=(Blank), BYVARS=(Blank), CENTREVARS=(Blank), COLSPACING=2, COLUMNS=(Blank), 
|   COMPUTEBEFOREPAGELINES=(Blank), COMPUTEBEFOREPAGEVARS=(Blank), DDDATASETLABEL=DD dataset for 
|   a table, DEFAULTWIDTHS=(Blank), DESCENDING=(Blank), DISPLAY=Y, FLOWVARS=_All_, FORMATS=(Blank), 
|   IDVARS=(Blank), LABELS=(Blank), LEFTVARS=(Blank), LINEVARS=(Blank), NOPRINTVARS=(Blank), 
|   NOWIDOWVAR=(Blank), ORDERDATA=(Blank), ORDERFREQ=(Blank), ORDERVARS=(Blank), 
|   ORDERFORMATTED=(Blank), OVERALLSUMMARY=N, PAGEVARS=(Blank), PROPTIONS=Headline, RIGHTVARS=(Blank), 
|   SHARECOLVARS=(Blank), SHARECOLVARSINDENT=2, SKIPVARS=(Blank), STACKVAR1-STACKVAR15=(Blank), 
|   VARSPACING=(Blank), WIDTHS=(Blank)
|---------------------------------------------------------------------------------------------------
| Plus, some parameters supported by %tu_statswithtotal (as defined in Unit Specification for HARP 
| Reporting Tools TU_STATSWITHTOTAL). Those parameters (and their defaults in %tu_sumstatsinrows) 
| are as follows:
|   BIGNVARNAME=tt_bnnm, COMPLETETYPESVARS=_all_, PSBYVARS=(Blank), PSCLASS=(Blank),  
|   PSCLASSOPTIONS=(Blank), PSFORMAT=(Blank), PSFREQ=(Blank),  PSOPTIONS=Missing NWAY, 
|   PSOUTPUT=(Blank), PSOUTPUTOPTIONS=NOINHERIT, PSID=(Blank), PSTYPES=(Blank), PSWAYS=(Blank), 
|   PSWEIGHT=(Blank), TOTALDECODE=(Blank), TOTALFORVAR=(Blank), TOTALID=(Blank)
|---------------------------------------------------------------------------------------------------
| Output:   1. an output file in plain ASCII text format containing a summary in columns data
|              display matching the requirements specified as input parameters.
|           2. SAS data set that forms the foundation of the data display (the "DD dataset").
|---------------------------------------------------------------------------------------------------
| Global macro variables created: &ACROSSCOLLISTNAME
|
| Macros called :
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_align
| (@) tu_chknames
| (@) tu_chkvarsexist
| (@) tu_denorm
| (@) tu_getdata
| (@) tu_labelvars
| (@) tu_list
| (@) tu_nobs
| (@) tu_pagenum
| (@) tu_putglobals
| (@) tu_statsfmt
| (@) tu_statswithtotal
| (@) tu_tidyup
| (@) tu_words
|
| Example:
|    The following example is used to create part of IDSL standard demographic summary table dm1.
|    The input data set should be consistence with IDSL ECG data set standard. The %ts_setup macros
|    should be called before calling the example.
|
|    %tu_sumstatsinrows(
|       acrossColVarPrefix     =_colvar,
|       acrossVar              =&g_trtcd,
|       acrossvardecode        =&g_trtgrp,
|       analysisvarname        =TT_AVNM,
|       analysisvarordervarname=TT_AVID,
|       analysisVars           =age height weight,
|       dsetin                 =ardata.demo,
|       dsetout                =work.demo,
|       groupByVarsAnaly       =,
|       statsdps               =MEDIAN +1 MEAN +1 STD +2,
|       statslist              =N MEAN STD MEDIAN MIN MAX,
|       statsListVarName       =TT_SVNM,
|       );
|
|---------------------------------------------------------------------------------------------------
|
| Change Log :
|
| Modified By :             Yongwei Wang (YW62951)
| Date of Modification :    25Sep2003
| New Version Number :      1/2
| Modification ID :         YW001
| Reason For Modification : 1. DD data set is passed to tu_list and should not be.
|                           2. DD data set should be always created, not only when DSETOUT is blank.
|---------------------------------------------------------------------------------------------------
| Modified By :             Yongwei Wang (YW62951)
| Date of Modification :    17Oct2003
| New Version Number :      1/3
| Modification ID :         YW002
| Reason For Modification : Change the parameters of the second tu_labelvars.
|---------------------------------------------------------------------------------------------------
| Modified By :              Tamsin Corfield (tsc30073)
| Date of Modification :     21Oct03
| New Version Number :       1/4
| Modification ID :          None
| Reason For Modification :  Removed ; form pagevars and skipvars comments 
|                            in order that the macro could be checked into 
|                            the application
|
|---------------------------------------------------------------------------------------------------
| Modified By :               Tamsin Corfield
| Date of Modification :      28Oct03
| New Version Number :        1/5
| Modification ID :           None
| Reason For Modification :   Added tu_list to list of macros called
|
|---------------------------------------------------------------------------------------------------
| Modified By :               Yongwei Wang
| Date of Modification :      26Apr05
| New Version Number :        2/1
| Modification ID :           None
| Reason For Modification :   1. Changed call of tu_stats to call %tu_statswithtoal
|                             2. Added following parameters:
|                                  ACROSSCOLLISTNAME STATSLABELS STATSINROWSYN BIGNINROWYN              
|                                  BIGNVARNAME COMPLETETYPESVARS TOTALDECODE TOTALFORVAR              
|                                  TOTALID 
|                             3. Added algorithm to calculate following LOG statistics:
|                                  CLM         - Confident limits in format (LCLM, UCLM)
|                                  CLMLOG      - confident limits for log variable in format (LCLMLOG, UCLMLOG)
|                                  CVB         - CV based on STD
|                                  CVBLOG      - CV based on STD for log variable
|                                  GEOMEAN     - Geometry Mean
|                                  GEOMEANCLM  - Geometry Mean with confident limits
|                                  LCLMLOG     - lower confident limits for log variable
|                                  MEANCLM     - Mean and confident limits in format MEAN (LCLM, UCLM)
|                                  STDERRLOG   - STDERR for log variable
|                                  STDLOG      - STD for log variable
|                                  UCLMLOG     - upper confident limits for log variable
|---------------------------------------------------------------------------------------------------
| Modified By :               Yongwei Wang
| Date of Modification :      25Jul05
| New Version Number :        2/2
| Modification ID :           YW001
| Reason For Modification     Limited the LOG algorithm to the logs listed in last change log above
|                             Set DENORMYN to N, if &STATSINROWSYN equals N.
|---------------------------------------------------------------------------------------------------
| New Version Number :        2/3
| Date of Modification :      10Aug05
| Modification ID :           YW002
| Reason For Modification     Added line "(indexw(statskeywords, 'MEANCLM') EQ 0) AND" to 
|                             keep the ALPHA in &PSOPTIONS
|-------------------------------------------------------------------------------------------------*/

%MACRO tu_sumstatsinrows(
   ACROSSCOLLISTNAME        =acrosscollistname_,   /* Name for a macro variable that will contain the variable names of the result columns created. */
   ACROSSCOLVARPREFIX       =tt_p,                 /* A string that will be the prefix of new transposed variable names*/
   ACROSSVAR                =&g_trtcd,             /* Variable that will be transposed to columns*/
   ACROSSVARDECODE          =&g_trtgrp,            /* The name of a decode variable for ACROSSVAR, or the name of a format*/
   ADDBIGNYN                =Y,                    /* Control whether big N will be added to the values of ACROSSVAR*/
   ALIGNYN                  =Y,                    /* Control execution of %tu_align*/
   ANALYSISVARDPS           =,                     /* Number of decimal places  to which data was captured*/
   ANALYSISVARNAME          =tt_avnm,              /* Variable name that saves analysis variable labels or names in DSETOUT*/
   ANALYSISVARORDERVARNAME  =tt_avid,              /* Variable name that saves analysis variable order in DSETOUT*/
   ANALYSISVARS             =,                     /* Summary statistics analysis variables*/   
   BIGNINROWYN              =N,                    /* If bigN should be displayed in rows, other than in column Label */
   BIGNVARNAME	            =tt_bnnm,              /* Variable name that saves big N values in the DD dataset*/
   BREAK1                   =,                     /* Break statements. */
   BREAK2                   =,                     /* Break statements. */
   BREAK3                   =,                     /* Break statements. */
   BREAK4                   =,                     /* Break statements. */
   BREAK5                   =,                     /* Break statements. */
   BYVARS                   =,                     /* By variables */
   CENTREVARS               =,                     /* Centre justify variables */
   CODEDECODEVARPAIRS       =,                     /* Code and Decode variables in pairs*/
   COLSPACING               =2,                    /* Overall spacing value. */
   COLUMNS                  =,                     /* Column parameter */
   COMPUTEBEFOREPAGELINES   =,                     /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt colon labelvar) */
   COMPUTEBEFOREPAGEVARS    =,                     /* Names of variables that shall define the sort order for Compute Before Page lines */
   COUNTDISTINCTWHATVARPOP  =&g_centid &g_subjid,  /* What is being counted when counting big N*/
   COMPLETETYPESVARS        =_all_,                /* Variables which COMPLETETYPES should be applied to */ 
   DDDATASETLABEL           =DD dataset for a table, /* Label to be applied to the DD dataset */
   DEFAULTWIDTHS            =,                     /* List of default column widths */
   DENORMYN                 =Y,                    /* Transpose result variables from rows to columns across the ACROSSVAR ? Y/N?*/
   DESCENDING               =,                     /* Descending ORDERVARS */
   DISPLAY                  =Y,                    /* Specifies whether the report should be created */
   DSETIN                   =,                     /* Input analysis dataset*/
   DSETOUT                  =,                     /* Output summary dataset*/
   FLOWVARS                 =_ALL_,                /* Variables with flow option */
   FORMATS                  =,                     /* Format specification */
   GROUPBYVARPOP            =&g_trtcd,             /* Variables to group by when counting big N */
   GROUPBYVARSANALY         =,                     /* The variables whose values define the subgroup combinations for the analysis */
   IDVARS                   =,                     /* ID variables */
   LABELS                   =,                     /* Label definitions. */
   LABELVARSYN              =Y,                    /* Control execution of %tu_labelvars*/
   LEFTVARS                 =,                     /* Left justify variables */
   LINEVARS                 =,                     /* Order variable printed with line statements. */
   NOPRINTVARS              =,                     /* No print vars (usually used to order the display) */
   NOWIDOWVAR               =,                     /* Not in version 1 */
   ORDERDATA                =,                     /* ORDER=DATA variables */
   ORDERFORMATTED           =,                     /* ORDER=FORMATTED variables */
   ORDERFREQ                =,                     /* ORDER=FREQ variables */
   ORDERVARS                =,                     /* Order variables */
   OVERALLSUMMARY           =N,                    /* Overall summary line at top of tables */
   PAGEVARS                 =,                     /* Break after <var> / page */
   POSTSUBSET               =,                     /* SAS "IF" condition that applies to the presentation dataset.   */
   PROPTIONS                =headline,             /* PROC REPORT statement options */
   PSBYVARS                 =,                     /* Advanced Usage: Passed to the PROC SUMMARY by statement. This will cause the data to be sorted first.  */
   PSCLASS                  =,                     /* Advanced usage: Passed to the PROC SUMMARY class Statement */
   PSCLASSOPTIONS           =,                     /* PROC SUMMARY class statement options                   */
   PSFORMAT                 =,                     /* Passed to the PROC SUMMARY format statement.           */
   PSFREQ                   =,                     /* Advanced usage: Passed to the PROC SUMMARY freq Statement  */
   PSID                     =,                     /* Advanced usage: Passed to the PROC SUMMARY id Statement  */
   PSOPTIONS                =MISSING NWAY,         /* PROC SUMMARY statement options to use           */
   PSOUTPUT                 =,                     /* Advanced usage: Passed to the PROC SUMMARY output statement */
   PSOUTPUTOPTIONS          =NOINHERIT,            /* Passed to the PROC SUMMARY Output options Statement part. */
   PSTYPES                  =,                     /* Advanced Usage: Passed to the PROC SUMMARY types statement */
   PSWAYS                   =,                     /* Advanced Usage: Passed to the PROC SUMMARY ways statment.  */
   PSWEIGHT                 =,                     /* Advanced Usage: Passed to the PROC SUMMARY weight statement. */
   RESULTVARNAME            =tt_result,            /* Result variables to be retained (if the data is not to be denormalised)*/
   RIGHTVARS                =,                     /* Right justify variables */
   SHARECOLVARS             =,                     /* Order variables that share print space. */
   SHARECOLVARSINDENT       =2,                    /* Indentation factor */
   SKIPVARS                 =,                     /* Break after <var> / skip */
   SPLITCHAR                =~,                    /* Split character*/
   STACKVAR1                =,                     /* Create Stacked variables (e.g. stackvar1=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
   STACKVAR10               =,                     /* Create Stacked variables (e.g. stackvar10=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~))*/
   STACKVAR11               =,                     /* Create Stacked variables (e.g. stackvar11=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~))*/
   STACKVAR12               =,                     /* Create Stacked variables (e.g. stackvar12=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~))*/
   STACKVAR13               =,                     /* Create Stacked variables (e.g. stackvar13=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~))*/
   STACKVAR14               =,                     /* Create Stacked variables (e.g. stackvar14=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~))*/
   STACKVAR15               =,                     /* Create Stacked variables (e.g. stackvar15=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~))*/
   STACKVAR2                =,                     /* Create Stacked variables (e.g. stackvar2=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
   STACKVAR3                =,                     /* Create Stacked variables (e.g. stackvar3=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
   STACKVAR4                =,                     /* Create Stacked variables (e.g. stackvar4=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
   STACKVAR5                =,                     /* Create Stacked variables (e.g. stackvar5=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
   STACKVAR6                =,                     /* Create Stacked variables (e.g. stackvar6=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
   STACKVAR7                =,                     /* Create Stacked variables (e.g. stackvar7=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
   STACKVAR8                =,                     /* Create Stacked variables (e.g. stackvar8=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
   STACKVAR9                =,                     /* Create Stacked variables (e.g. stackvar9=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
   STATSDPS                 =,                     /* Number of decimal places of summary statistical results*/
   STATSINROWSYN            =Y,                    /* Should summary statistics be displayed in rows or colums */
   STATSLIST                =,                     /* List of required summary statistics, e.g. N Mean Median. */
   STATSLABELS              =,                     /* Label defination for summary statistical result variables. */
   STATSLISTVARNAME         =tt_svnm,              /* Variable name that saves summary statistic variable names */
   STATSLISTVARORDERVARNAME =tt_svid,              /* Variable name that saves summary statistic variable order */
   TOTALDECODE              =,                     /* Label for the total result column. */
   TOTALFORVAR              =,                     /* Variable for which a total is required */
   TOTALID                  =,                     /* Value used to populate the variable specified in ACROSSVAR on data that represents the overall total for the ACROSSVAR variable. */
   VARLABELSTYLE            =SHORT,                /* Specifies the label style for variables */
   VARSPACING               =,                     /* Spacing for individual variables. */
   WIDTHS                   =,                     /* Column widths */
   XMLINFMT                 =,                     /* Name and location of XML format file*/
   XMLMERGEVAR              =                      /* Variable to merge data and XML format data*/
   );

   /*
   / Write details of macro call to log                              
   /---------------------------------------------------------------------*/

   %LOCAL MacroVersion;
   %LET MacroVersion = 2;

   %INCLUDE "&g_refdata./tr_putlocals.sas";
   %tu_putglobals(varsin=G_DDDATASETNAME  G_ANALY_DISP)

   %LOCAL l_acrossvar
          l_acrossvardecode
          l_acrossvarlist
          l_adddecodestatements   
          l_adecode
          l_analydata
          l_analysisVar
          l_bignvar
          l_bublicvar
          l_calcstatskeywords
          l_calcstatsvars
          l_clmvars
          l_clmvarstats
          l_codedecodevarpairs   
          l_groupbyvars
          l_groupbyvarsanaly_byvars
          l_i l_j l_i1 l_i2 l_i3  
          l_logstats   
          l_logstatslist
          l_loopdata
          l_nobs
          l_numof_analysisvars
          l_numofacrossvars
          l_numofcalcvars
          l_numofclmvars          
          l_prefix
          l_psoptions
          l_logpsoptions
          l_message
          l_rc
          l_resultnumvarname
          l_splitchar    
          l_statsdps
          l_bigntovardecodevar
          l_allstatslist
          l_newpopdata
          l_oldpopdata
          l_statsvars
          l_statskeywords
          l_stepdata
          l_summaryLevelVarName   
          l_tmp
          l_tmpstatslist   
          l_totalid
          l_totalidvar
          l_workdata
          l_workdata1
          l_workpath
          l_trtdata
          ;

   %LET l_logstats=GEOMEAN GEOMEANCLM CLMLOG CVBLOG LCLMLOG UCLMLOG STDLOG STDERRLOG;   /*YW001*/
   %LET l_prefix=_sumrow;
   
   /* Set default values of local macro variables */
   %LET l_resultnumvarname=&RESULTVARNAME.N;
   %LET l_formatd=tt_formatd;
   %LET l_summaryLevelVarName=tt_summaryLevel;
   %LET l_publicvar=tt___publicvar;
   %LET l_clmvars=;
   %LET l_numofclmvars=0;
   %LET l_numofcalcvars=0;
   %LET l_psoptions=&psoptions;
   %LET l_logpsoptions=&psoptions;
   %LET l_splitchar=&splitchar;

   /*
   / Call tu_pagenum to delete output display file.                   
   /----------------------------------------------------------------------*/

   %tu_pagenum(usage=DELETE)   
   %IF %nrbquote(&g_abort) EQ 1 %THEN %GOTO macerr;

   /*
   / IF &G_ANALY_DISP equals D, check if ACROSSCOLISTNAME is not in &COLUMN
   /--------------------------------------------------------------------------*/

   %IF %nrbquote(&G_ANALY_DISP) EQ D %THEN 
   %DO;
      
      %LET l_workdata=&G_DDDATASETNAME;
         
      %IF %sysfunc(indexw(%qupcase(&columns), %nrstr(&)%qupcase(&acrosscollistname))) gt 0 %THEN 
      %DO;         
         %PUT %str(RTE)RROR: &sysmacroname: G_ANALY_DISP equals D, but value of ACROSSCOLISTNAME is in the parameter COLUMN. The macro can not resolve it;
         %LET g_abort=1;
      %END; 
      
      %IF &g_abort EQ 1 %THEN %GOTO macerr;     

      %GOTO DISPLAYIT;

   %END; /* end-if on %nrbquote(&G_ANALY_DISP) EQ D */

   /*
   / If &DSETOUT is not blank, delete &G_DDDATASETNAME dataset if it exists                     
   /----------------------------------------------------------------------*/

   %IF %nrbquote(&DSETOUT) EQ %THEN 
   %DO;
      %IF %sysfunc(exist(&G_DDDATASETNAME)) %THEN 
      %DO;
         PROC DATASETS MEMTYPE=(DATA VIEW) NOLIST NODETAILS
            %IF %INDEX(&G_DDDATASETNAME, %str(.)) %THEN 
            %DO;
               LIBRARY=%scan(&G_DDDATASETNAME, 1, %str(.));
               DELETE %scan(&G_DDDATASETNAME, 2, %str(.));
            %END;
            %ELSE %DO;
               ;
               DELETE &G_DDDATASETNAME;
            %END;
         RUN;
         QUIT;
      %END; /* end-if on %sysfunc(exist(&G_DDDATASETNAME)) */
   %END;  /* end-if on %nrbquote(&DSETOUT) EQ */                                            

   /*
   / Loop over all required parameters to check if any of required    
   / parameters is blank.                                             
   /----------------------------------------------------------------------*/
   
   %LET l_i=1;
   %LET l_tmp=ADDBIGNYN ALIGNYN SPLITCHAR ANALYSISVARORDERVARNAME ANALYSISVARNAME 
              ANALYSISVARS DSETIN LABELVARSYN STATSLIST VARLABELSTYLE 
              DENORMYN STATSINROWSYN BIGNINROWYN;
              
   %IF %qupcase(&denormyn) EQ Y %THEN
   %DO;                  
      %LET l_tmp=&l_tmp ACROSSVAR ACROSSCOLVARPREFIX;
   %END;
   
   %IF %qupcase(&statsinrowsyn) EQ Y %THEN 
   %DO;                  
      %LET l_tmp=&l_tmp STATSLISTVARNAME STATSLISTVARORDERVARNAME RESULTVARNAME;
   %END;
   
   %LET l_i1=%scan(&l_tmp, &l_i);
   %DO %WHILE ( %nrbquote(&l_i1) NE );

      %IF %nrbquote(&&&l_i1) EQ  %THEN 
      %DO;
         %PUT %str(RTERR)OR: &sysmacroname: value of parameter &l_i1 is blank.;
         %LET g_abort=1;
      %END;
      %LET l_i=%eval(&l_i + 1);
      %LET l_i1=%scan(&l_tmp, &l_i);

   %END; /* end of do-while loop on %nrbquote(&l_i1) NE */ 

   /*
   / Check if any of required parameters with Y, N value is valid.    
   /----------------------------------------------------------------------*/

   %LET l_i=1;
   %LET l_tmp=ADDBIGNYN ALIGNYN LABELVARSYN DENORMYN DISPLAY STATSINROWSYN BIGNINROWYN;
   %LET l_i1=%scan(&l_tmp, &l_i);
   %DO %WHILE ( %nrbquote(&l_i1) NE );

      %LET &l_i1=%qupcase(&&&l_i1);
      %IF ( %nrbquote(&&&l_i1) NE Y ) AND ( %nrbquote(&&&l_i1) NE N ) %THEN 
      %DO;
         %PUT %str(RTERR)OR: &sysmacroname: value of parameter &l_i1 is invalid;
         %PUT %str(RTN)OTE:  &sysmacroname: valid values for &l_i1 are Y, N;
         %LET g_abort=1;
      %END;
      %LET &l_i1=%upcase(&&&l_i1);
      %LET l_i=%eval(&l_i + 1);
      %LET l_i1=%scan(&l_tmp, &l_i);

   %END; /* end of do-while loop on  %nrbquote(&l_i1) NE */
    
   /*
   / YW001: If &STATSINROWSYN equals N and &DENORMYN eq Y 
   /----------------------------------------------------------------------*/
   %IF ( &STATSINROWSYN EQ N ) AND (&DENORMYN eq Y ) %THEN
   %DO;
      %PUT %str(RTN)OTE: &sysmacroname: Set DENORMYN to N because STATSINROWSYN equals N.;
      %LET DENORMYN=N;
   %END;
     
   %IF ( &DENORMYN EQ Y ) AND ( %nrquote(&acrosscollistname) EQ ) %THEN 
   %DO;
      %LET acrosscollistname=__acrosscollistname;      
   %END;
   
   /*
   / Check parameters that depend on ADDBIGNYN     
   /----------------------------------------------------------------------*/

   %IF &ADDBIGNYN EQ Y %THEN 
   %DO;

      %IF %nrbquote(&COUNTDISTINCTWHATVARPOP) EQ  %THEN 
      %DO;
         %PUT %str(RTERR)OR: &sysmacroname: value of parameter COUNTDISTINCTWHATVARPOP is blank.;
         %LET g_abort=1;
      %END;
      %IF %nrbquote(&GROUPBYVARPOP) EQ  %THEN 
      %DO;
         %PUT %str(RTERR)OR: &sysmacroname: value of parameter GROUPBYVARPOP is blank.;
         %LET g_abort=1;
      %END;
      
   %END; /* end-if on &ADDBIGNYN EQ Y */  
   
   /*
   / Check parameters that depend on BIGNINROWYN    
   /----------------------------------------------------------------------*/   
   
   %IF &BIGNINROWYN EQ Y %THEN 
   %DO;
   
      %IF &STATSINROWSYN EQ N %THEN
      %DO;
         %PUT %str(RTN)OTE: &sysmacroname: Set BIGNINROWYN to N because STATSINROWSYN equals N.;
         %LET bigninrowyn=N;
      %END;
      
      %IF %nrbquote(&BIGNVARNAME) EQ %THEN 
      %DO;
         %PUT %str(RTERR)OR: &sysmacroname: BIGNINROWYN equals Y, but BIGNVARNAME is blank.;
         %LET g_abort=1;      
      %END;
      
      %IF &ADDBIGNYN EQ  Y %THEN 
      %DO;
         %LET ADDBIGNYN=N;  
      %END;
      
   %END; /* end-if on &BIGNINROWYN EQ Y */
       
   /*
   / Check if any variable names given by parameters are invalid.                   
   /----------------------------------------------------------------------*/

   %LET l_rc=%tu_chknames(&ANALYSISVARS &ANALYSISVARNAME &ANALYSISVARORDERVARNAME
                          &ACROSSVAR &STATSLISTVARNAME &STATSLISTVARORDERVARNAME
                          &GROUPBYVARPOP &COUNTDISTINCTWHATVARPOP &ACROSSCOLLISTNAME
                          &CODEDECODEVARPAIRS, VARIABLE);

   %IF %nrbquote(&l_rc) EQ -1 %THEN %LET g_abort=1;
   %IF %nrbquote(&l_rc) NE %THEN 
   %DO;
      %PUT %str(RTERR)OR: &sysmacroname: variable name &l_rc given in the parameters is invalid.;
      %LET g_abort=1;
   %END;

   /*
   / Check 
   / 1. if &SPLITCHAR has only one character 
   / 2. if &DSETOUT is a valid SAS data set name if it is not blank
   / 3. if &DSETOUT has prefix &l_prefix if it is not blank
   /----------------------------------------------------------------------*/

   /* SPLITCHAR */
   %IF %length(&SPLITCHAR) NE 1 %THEN 
   %DO;
      %PUT %str(RTERR)OR: &sysmacroname: input parameter SPLITCHAR is invalid. It should equal one character;
      %LET g_abort=1;
   %END;

   %IF %index(%qupcase(&DSETIN), %upcase(&l_prefix)) EQ 1 %THEN 
   %DO;
      %PUT %str(RTERR)OR: &sysmacroname: name of input data set &DSETIN has prefix &l_prefix and it is not allowed;
      %LET g_abort=1;
   %END;

   /* DSETOUT */
   %IF %nrbquote(&DSETOUT) NE %THEN 
   %DO;
      %LET l_rc=%tu_chknames(&DSETOUT, DATA);
      %IF %nrbquote(&l_rc) NE %THEN 
      %DO;
         %PUT %str(RTERR)OR: &sysmacroname: output data set name DSETOUT is invalid;
         %LET g_abort=1;
      %END;
      %ELSE %IF %nrbquote(&l_rc) EQ -1 %THEN %LET g_abort=1;

      %IF %index(%upcase(&DSETOUT), %upcase(&l_prefix)) EQ 1 %THEN 
      %DO;
         %PUT %str(RTERR)OR: &sysmacroname: name of output data set &DSETOUT has prefix &l_prefix and it is not allowed;
         %LET g_abort=1;
      %END;
   %END; /* end-if on %nrbquote(&DSETOUT) NE */
   
   /* 
   / Check if &DSETIN exist. If exist, save input data set to a temporary 
   / data set so that the SAS data set options can be applied and check 
   / if &ANALYSISVARS exist in &DSETIN
   /----------------------------------------------------------------------*/

   /* DSETIN */
   %LET l_rc=%tu_nobs(&DSETIN);

   %IF &l_rc EQ -1 %THEN 
   %DO;
      %PUT %str(RTERR)OR: &sysmacroname: input data set "&dsetin" does not exist;
      %LET g_abort=1;
   %END;
   %ELSE %DO;
   
      DATA &l_prefix.dsetin;
         SET &DSETIN;
      RUN;
     
      /* Check errors in DSETIN */
      %IF &SYSERR GT 0 %THEN 
      %DO;
        %PUT %str(RTERR)OR: &sysmacroname: value of parameter DSETIN cause SAS error(s);
        %GOTO macerr;
      %END;
     
      %LET L_WORKDATA=&l_prefix.dsetin;
     
      /* ANALYSISVARS */
      %LET ANALYSISVARS=%upcase(&ANALYSISVARS);
      %LET l_rc=%tu_chkvarsexist(&L_WORKDATA, &ANALYSISVARS);
     
      %IF %nrbquote(&l_rc) NE %THEN 
      %DO;
         %PUT %str(RTERR)OR: &sysmacroname: not all variables given by ANALYSISVARS are in input dataset;
         %PUT %str(RTERR)OR: &sysmacroname: or value of the parameter is invalid.;
         %LET g_abort=1;
      %END;
      
   %END; /* end-if on &l_rc EQ -1 */
      
   %IF &g_abort EQ 1 %THEN %GOTO macerr;    
        
   /*
   / Check If ANALYSISVARORDERVARNAME, ANALYSISVARNAME, RESULTVARNAME 
   / STATSLISTVARNAME and STATSLISTVARORDERVARNAME exist in the input    
   / data set                                                         
   /----------------------------------------------------------------------*/

   %LET l_tmp=&ANALYSISVARORDERVARNAME &ANALYSISVARNAME l_summaryLevelVarName
              &STATSLISTVARNAME &STATSLISTVARORDERVARNAME &RESULTVARNAME;
   %LET l_rc=%tu_chkvarsexist(&L_WORKDATA, &l_tmp);
   
   %LET l_i=1;
   %LET l_i1=%SCAN(&l_tmp, &l_i, %str( ));
   %LET l_i2=%SCAN(&l_rc, &l_i, %str( ));
   %DO %WHILE(%nrbquote(&l_i1) NE );
      %IF %nrbquote(&l_i2) EQ %THEN 
      %DO;
         %PUT %str(RTERR)OR: &sysmacroname: at least one of the variables given by ANALYSISVARORDERVARNAME, RESULTVARNAME, ;
         %PUT %str(RTERR)OR: &sysmacroname: ANALYSISVARNAME, STATSLISTVARNAME or STATSLISTVARORDERVARNAME, or &ANALYSISVARNAME already in input dataset ;
         %LET g_abort=1;
      %END;

      %LET l_i=%EVAL(&l_i + 1);
      %LET l_i1=%SCAN(&l_tmp, &l_i, %str( ));
      %LET l_i2=%SCAN(&l_rc, &l_i, %str( ));
   %END;

   /*
   / Check if any of new added variable is not in input data set.         
   /----------------------------------------------------------------------*/

   %LET l_rc=0;

   DATA _NULL_;
      LENGTH var1 var2 $32;
      varlist="&ANALYSISVARORDERVARNAME &ANALYSISVARNAME &STATSLISTVARORDERVARNAME &STATSLISTVARNAME "||
              "&L_GROUPBYVARS &BIGNVARNAME &RESULTVARNAME &l_RESULTNUMVARNAME &l_formatd &l_publicvar";

      i=1;
      var1=scan(varlist, i);
      DO WHILE (var1 NE "");
         j=i+1;
         var2=scan(varlist, j);
         DO WHILE (var2 NE "");
            IF var1 EQ var2 THEN
            DO;
               PUT "RTERR" "OR: &sysmacroname: variable name " var1 " is used more than once either as parameters";
               PUT "RTERR" "OR: &sysmacroname: or as internal variable name";
               CALL SYMPUT('l_rc', '-1');
               STOP;
            END;
            j=j+1;
            var2=scan(varlist, j);
         END;

         IF index(var1, compress("&ACROSSCOLVARPREFIX")) EQ 1 THEN 
         DO;
            PUT "RTERR" "OR: &sysmacroname: ACROSSCOLVARPREFIX &ACROSSCOLVARPREFIX is conflict with variable name " var1 ".";
            PUT "RTERR" "OR: &sysmacroname: Please change it.";
            CALL SYMPUT('l_rc', '-1');
            STOP;
         END;
         i=i+1;
         var1=scan(varlist, i);
      END;
   RUN;

   %IF &l_rc EQ -1 %THEN %LET g_abort=1;
   
   %IF &g_abort EQ 1 %THEN %GOTO macerr;
   
   /*
   / If &STATSINROWSYN equals Y, set STATSLISTVARNAME, STATLISTVARORDERVARNAME 
   / and RESULTVARNAME to blank                                                          
   /--------------------------------------------------------------------------*/
      
   %IF &statsinrowsyn NE Y %THEN 
   %DO;
      %LET statslistvarname=;
      %LET statlistvarordervarname=;
      %LET resultvarname=;      
   %END;   
   
   /*
   / Call tu_getdata to subset the input data set.                    
   /----------------------------------------------------------------------*/

   %tu_getdata(
      DSETIN=&L_WORKDATA,
      DSETOUT1=&L_PREFIX.ANALY,
      DSETOUT2=&L_PREFIX.popdata
      )

   %IF &g_abort EQ 1 %THEN %GOTO macerr;      

   %LET l_workdata=&l_prefix.analy;
   
   /* This is for fix the bug in tu_stats. The &countdistinctwhatvar should not
   /  be used in calculation of summary in tu_stats. The duplicated 
   /  &countdistinctwhatvar is removed here so that the &countdistinctwhatvarpop
   /  don't need to pass to %tu_statswithtotal
   /-------------------------------------------------------------------------*/
   
   %LET l_oldpopdata=&g_popdata;
   %LET l_newpopdata=&g_popdata;   
   %LET l_trtdata=;
   
   %IF %nrbquote(&COUNTDISTINCTWHATVARPOP) NE %THEN
   %DO;      
   
      %IF %tu_chkvarsexist(&L_PREFIX.popdata, &GROUPBYVARPOP &COUNTDISTINCTWHATVARPOP) NE %THEN 
      %DO;
         %PUT %str(RTERR)OR: &sysmacroname: Not all variables given by COUNTDISTINCTWHATVARPOP (=&COUNTDISTINCTWHATVARPOP) and GROUPBYVARPOP (=&GROUPBYVARPOP) are in POP data(=&g_popdata);      
         %LET g_abort=1;
         %GOTO macerr;
      %END;
      
      PROC SORT DATA=&L_PREFIX.popdata out=&L_PREFIX.pop nodupkey;
         BY &COUNTDISTINCTWHATVARPOP &GROUPBYVARPOP;
      RUN;
                            
      %LET l_newpopdata=&L_PREFIX.pop;
      
      /* 
      / Save the TRT data set, if exists. and create a new dummy TRT 
      / data set, which will be used by %tu_getdata for crossover study
      / for crossover study
      /----------------------------------------------------------------*/
      
      %IF %qupcase(%nrbquote(&g_stype)) EQ XO %THEN
      %DO;
         %IF %sysfunc(exist(trt)) %THEN
         %do;
            DATA &l_prefix.trt;
               SET trt;
            RUN;
            
            %LET l_trtdata=&l_prefix.trt;
         %END;
         %ELSE %LET l_trtdata=trt;
                  
         PROC SORT data=&L_PREFIX.pop out=trt(keep=&g_centid &g_subjid) nodupkey;
            BY &g_centid &g_subjid;
         RUN; 
         
      %END; /* end-if on %qupcase(%nrbquote(&g_stype)) EQ XO */
      
   %END; /* end-if on %nrbquote(&COUNTDISTINCTWHATVARPOP) NE */       
   
   %GLOBAL &acrosscollistname;   
      
   /* save the name of the data set before calling tu_stats */
   %let l_analydata=&L_WORKDATA;  
      
   /*
   / Get ANALYSISVARDPS, XMLINFMT, XMLMERGEVAR and STATSDPS of the 
   / variable. Those parameters can be in format VAR=value. The    
   / codes below search the current processing analysis variable   
   / in them and find the specific values for this variable        
   /-------------------------------------------------------------------*/

   %LET l_rc=0;
   %LET l_numof_analysisvars=%tu_words(&analysisvars);
   %LET l_numof_mvars=5;   
   %LET l_tmp=ANALYSISVARDPS XMLINFMT XMLMERGEVAR STATSDPS STATSLIST;       
   
   %DO l_i = 1 %TO &l_numof_analysisvars;
      %LOCAL L_ANALYSISVARDPS&L_I L_XMLINFMT&L_I L_XMLMERGEVAR&L_I L_STATSDPS&L_I L_STATSLIST&L_I;
   %END;   
     
   DATA _NULL_;
      ARRAY arr_org_vars {&l_numof_mvars} $500 _TEMPORARY_ ;   
      ARRAY arr_parm_name {&l_numof_mvars} $32 _TEMPORARY_ ;    
      LENGTH before after var analysisvars vars vals notvars avars prevars 
             var1 $500 parm $32;
      
      %DO l_i = 1 %TO &l_numof_mvars;
         arr_org_vars{&l_i}=left(symget("%scan(&l_tmp, &l_i, %str( ))"));
         arr_parm_name{&l_i}=compress("%scan(&l_tmp, &l_i, %str( ))");
      %END;
 
      analysisvars=left("&analysisvars");
      
      rx1=rxparse("($n$c* $w*)* '='") ;   
      rx2=rxparse("$q | $(10)") ;

      /* Loop over parameters to read values for each analysis variable */
      DO loop=1 TO &l_numof_mvars;
         before='';
         prevars='';
         parm=upcase(arr_parm_name{loop});
         after=arr_org_vars{loop};
         LINK readparm;
      END;    
     
      IF not missing(rx1) THEN CALL rxfree(rx1);
      IF not missing(rx2) THEN CALL rxfree(rx2);
     
      RETURN;
      
   /*
   / Get one parameter value for analysis vairables                
   /-------------------------------------------------------------------*/
      
   READPARM:
      
      CALL rxsubstr(rx1, after, pos, len);
    
      DO WHILE (len GT 0) ;
         vars='';
         notvars='';
    
         CALL rxsubstr(rx2, after, pos1, len1);
    
         IF ( len1 GT 0 ) AND (pos GT pos1) AND (pos LE pos1 + len1) THEN 
         DO;
            if before ne '' then 
               before=before||trim(substr(after, 1, pos1 + len1 - 1));
            else 
               before=trim(substr(after, 1, pos1 + len1 - 1));
               
            after=trim(substr(after, pos1 + len1));
         END;
         ELSE DO;
            avars=trim(substr(after, pos, len));
            avars=substr(avars, 1, index(avars, '=') - 1);
            i=-1;
            var=scan(avars, i);
            notvars=avars;
    
            DO WHILE (var ne '');
               IF indexw(analysisvars, upcase(var)) GT 0 THEN 
               DO;
                  vars=trim(left(var))||' '||left(vars);
                  IF length(notvars) eq length(var) THEN notvars='';
                  ELSE  notvars=substr(notvars, 1, length(notvars) - length(var));
               END;
               ELSE leave;
               i=i-1;
               var=scan(avars, i);
            END;
    
            IF vars eq '' THEN 
            DO;
               if before ne '' then before=trim(before)||trim(substr(after, 1, pos + len - 1));
               else before=trim(substr(after, 1, pos + len - 1));
            END;
            ELSE DO;           
               IF pos GT 1 THEN vals=trim(substr(after, 1, pos - 1))||notvars;
               ELSE vals=notvars;
               IF before ne '' THEN vals=trim(before)||vals;
               avars=prevars;
               LINK outvals;
               prevars=vars;
               before='';
            END;
            after=trim(substr(after, pos + len));
         END;
    
         CALL rxsubstr(rx1, after, pos, len);
      END;
           
      IF before ne '' THEN vals=trim(before)||' '||after;
      ELSE vals=after;
      avars=prevars;
      LINK outvals;
      
      RETURN;
      
   /*
   / Assign the value of a parameter for analysis variables to     
   / macro variables                                               
   /-------------------------------------------------------------------*/

   OUTVALS:
      
      IF compress(avars) eq '' THEN avars=analysisvars;
      ELSE DO;
         var1=trim(left(vals));
         IF (substr(var1, 1, 1) EQ '(') AND (substr(var1, length(var1), 1) EQ ')') THEN 
         DO;
            IF length(var1) LE 2 THEN vals='';
            ELSE vals=substr(var1, 2, length(var1) - 1);
         END;      
      END; /* end of if-then-else on compress(avars) eq '' */
      
      j=1;
      var1=scan(avars, j);
      DO WHILE (var1 ne '');
         DO k=1 TO &l_numof_analysisvars;
            IF scan(analysisvars, k) eq upcase(var1) THEN 
            DO;          
               CALL SYMPUT(compress('l_'||parm||put(k, 6.0)), trim(left(vals)));            
               IF indexw("ANALYSISVARDPS XMLINFMT XMLMERGEVAR STATSDPS", compress(parm)) GT 0 THEN
               DO;
                  indeq=index(vals, '=');
                  IF indeq GT 0 THEN
                  DO;
                     IF indeq EQ 1 THEN vals='';
                     ELSE DO;
                        vals=substr(vals, 1, indeq - 1);  
                        vals=upcase(scan(vals, -1));
                     END;
                     
                     PUT "RTE" "RROR: &sysmacroname: variable " vals " given by " parm " is not in parameter ANALYSISVARS";
                     CALL SYMPUT('l_rc', '-1');
                  END;
               END;
               leave;
            END;
         END; /* end of do-to loop */
         j=j+1;
         var1=scan(avars, j);
      END; /* end of do-while loop */
      
      RETURN;
   RUN;  
   
   %IF &l_rc EQ -1 %THEN %GOTO macerr;   
       
   /*
   / 1. Remove statement in &GROUPBYVARSANALY to get a list of         
   /    variables.                                                    
   / 2. Remove &ACROSSVAR and &ACROSSVARDECODE from the variable list.
   / 3. Construct &GROUPBYVARS of %tu_denorm.                        
   / 4. If &ACROSSVARDECODE is a format list, build a statement to    
   /    convert the format to a variable.                              
   / 5. Add &ACROSSVAR and &ACROSSVARDECODE to &CODEDECODEVARPAIRS.   
   /----------------------------------------------------------------------*/
   
   DATA _NULL_;
      LENGTH t_groupbyvarsanaly groupbyvarsanaly t_message 
             groupbyvarsanaly_byvars acrossvar acrossvardecode t_var  
             newacrossvardecode t_codevar codedecodevarpairs
             t_decodevar t_popvar statements $500 t_splitchar $10;
                 
      statements='';      
      acrossvar=upcase("&acrossvar");
      
      %IF &denormyn EQ Y %THEN 
      %DO;
         acrossvardecode="&acrossvardecode";      
      %END;
      %ELSE %DO;
         acrossvardecode='';
      %END;
      
      LINK getgrp;        
      LINK rmarsgrp;
      LINK setspt;
      RETURN;
                 
   /*
   / If population variable is not across variable, set splitchar to a
   / blank space                                                      
   /----------------------------------------------------------------------*/
   
   SETSPT:      
      t_popvar="&GROUPBYVARPOP";
      t_popvar=upcase(scan(t_popvar, -1, ' '));         
   
      IF (t_popvar ne '') AND (indexw(scan(acrossvar, -1, ' '), t_popvar) EQ 0) AND
         (indexw(upcase(scan(newacrossvardecode, -1, ' ')), t_popvar) EQ 0) 
      THEN DO;
         t_splitchar='%str( )';
         CALL SYMPUT('l_splitchar',  trim(left(t_splitchar)));
      END;        
       
      RETURN;
      
   /*
   / Remove the statements from GROUPBYVARSANALY.                     
   /----------------------------------------------------------------------*/
   
   GETGRP:        
      groupbyvarsanaly=""; 
      t_groupbyvarsanaly=symget("groupbyvarsanaly");                   
      t_rx=rxparse("$(10)");
      CALL rxsubstr(t_rx,t_groupbyvarsanaly, t_pos, t_len);
      
      DO WHILE(t_pos GT 0);
         IF t_pos GT 1 THEN
            groupbyvarsanaly=trim(left(groupbyvarsanaly))||' '||left(upcase(substr(t_groupbyvarsanaly, 1, t_pos -1)));
         ELSE 
            groupbyvarsanaly="";

         t_groupbyvarsanaly=substr(t_groupbyvarsanaly, t_pos + t_len);               
         CALL rxsubstr(t_rx,t_groupbyvarsanaly, t_pos, t_len);
      END;  
      
      groupbyvarsanaly=trim(left(groupbyvarsanaly))||' '||upcase(trim(left(t_groupbyvarsanaly)));
                                            
      IF t_rx GT 0 THEN CALL rxfree(t_rx);         
      RETURN;
            
   /*
   / Remove ACROSSVARDECODE from GROUPBYVARSANALY                     
   / Add ACROSSVAR and ACROSSVARDECODE to CODEDECODEVARPAIRS.         
   / Construct &GROUPBYVARS for %tu_denorm                            
   /----------------------------------------------------------------------*/
   
   RMARSGRP:      
      codedecodevarpairs=upcase("&codedecodevarpairs");
      psbyvars=upcase("&psbyvars");     
      groupbyvarsanaly_byvars=trim(left(psbyvars))||' '||trim(left(groupbyvarsanaly));      
      
      t_i=1;
      newacrossvardecode='';
      t_codevar=scan(acrossvar, t_i, ' ');
      t_decodevar=scan(acrossvardecode, t_i, ' ');      
      
      DO WHILE(t_codevar NE '');                
         /* Add ACROSSVAR and ACROSSVARDECODE to CODEDECODEVARPAIRS */
         IF upcase(t_decodevar) EQ '_NULL_' THEN
            newacrossvardecode=trim(left(newacrossvardecode))||' '||upcase(compress(t_decodevar));
         ELSE IF t_decodevar NE '' THEN 
         DO;     
            t_ind1=indexw(codedecodevarpairs, t_codevar);           
            t_ind2=indexw(codedecodevarpairs, upcase(t_decodevar));
            t_var='';
            
            IF (t_ind1 GT 0) AND (t_ind2 gt 0) AND (t_ind2 gt t_ind1) THEN 
            DO;
               t_var=substr(codedecodevarpairs, t_ind1, t_ind2 - t_ind1);
               IF index(trim(left(t_var)), ' ') gt 0 then t_ind2=0;
            end;
            
            IF (t_ind1 GT 0) AND (t_ind2 EQ 0) THEN 
            DO;           
               t_message="Variable "||compress(t_codevar)||" in ACROSSVAR has different decode in CODEDECODEVARPAIRS and ACROSSVARDECODE";
               LINK exit;
            END;
            
            IF index(t_decodevar, '.') EQ 0 THEN 
            DO;
               newacrossvardecode=trim(left(newacrossvardecode))||' '||compress(upcase(t_decodevar));           
            END;
            ELSE DO;   
               IF t_var EQ '' THEN
                  t_var=compress("acrossvardecode_autovar"||put(t_i, 2.0));
               newacrossvardecode=trim(left(newacrossvardecode))||' '||compress(t_var);
               statements=trim(left(statements))||" "||compress(t_var)||
                          "=put("||compress(t_codevar)||","||compress(t_decodevar)||");";
                          
               t_decodevar=upcase(t_var);                                       
            END;
            
            IF t_ind1 EQ 0 THEN codedecodevarpairs=trim(left(codedecodevarpairs))||" "||compress(t_codevar)||" "||compress(t_decodevar);               
              
         END; /* end of if-then-else on upcase(t_decodevar) EQ '_NULL_' */
         
         /* Remove ACROSSVAR and ACROSSVARDECODE from GROUPBYVARSANALY */
         t_ind1=indexw(groupbyvarsanaly_byvars, t_codevar);                  
         t_ind2=length(t_codevar);
         LINK substr;
         
         t_ind1=indexw(groupbyvarsanaly_byvars, upcase(t_decodevar));         
         t_ind2=length(t_decodevar);
         LINK substr;
       
         t_i=t_i + 1;         
         t_codevar=scan(acrossvar, t_i, ' ');
         t_decodevar=scan(acrossvardecode, t_i, ' ');        
      END; /* end DO-WHILE loop on (t_codevar NE '') */
            
      CALL SYMPUT('l_acrossvardecode',         trim(left(newacrossvardecode     ))); 
      CALL SYMPUT('l_groupbyvarsanaly_byvars', trim(left(groupbyvarsanaly_byvars))); 
      CALL SYMPUT('l_adddecodestatements',     trim(left(statements             )));     
      CALL SYMPUT('l_codedecodevarpairs',      trim(left(codedecodevarpairs     )));     
      RETURN;
      
   SUBSTR:    
     IF t_ind1 EQ 1 THEN 
        groupbyvarsanaly_byvars=substr(groupbyvarsanaly_byvars, t_ind1 + t_ind2);
     ELSE IF t_ind1 GT 1 THEN 
     DO;
        groupbyvarsanaly_byvars=substr(groupbyvarsanaly_byvars, 1, t_ind1 - 1)||' '||
                                left(substr(groupbyvarsanaly_byvars, t_ind1 + t_ind2 ));
     END;
     groupbyvarsanaly_byvars=left(groupbyvarsanaly_byvars);
     RETURN;        
           
   EXIT:
      CALL SYMPUT('l_rc', '-1');
      CALL SYMPUT('l_message', trim(left(t_message)));
      IF t_rx GT 0 THEN CALL rxfree(t_rx);       
      STOP;      
      RETURN;                 
   RUN;
  
   %IF &l_rc EQ -1 %THEN %GOTO macerr;
   
   /*
   / If any &ACROSSVARDECODE is a format, convert it to a variable.    
   /----------------------------------------------------------------------*/
   
   %IF %nrbquote(&l_adddecodestatements) NE %THEN 
   %DO;
      DATA &l_prefix.dsetin;
         SET &l_workdata;
         &l_adddecodestatements;
      RUN;
      
      %LET l_workdata=&l_prefix.dsetin;
   %END;

   %IF &l_rc EQ -1 %THEN %GOTO macerr;
       
   /*
   / Call tu_labelvars to add standard label to input data set so  
   / the standard labels can be used in row labels.                
   /-------------------------------------------------------------------*/
   
   %IF &LABELVARSYN EQ Y %THEN %DO;
      %tu_labelvars(
         DSETIN   =&l_workdata,
         DSETOUT  =&L_PREFIX.DSETINLABEL,
         STYLE    =STD
         );         
      
      %LET l_workdata=&L_PREFIX.DSETINLABEL;
   %END;
             
   /*
   / This is for compatibility with the old version.                     
   /----------------------------------------------------------------------*/
   
   %IF ( &denormyn EQ N ) and ( &display EQ N ) %THEN %LET addbignyn=N;

   /*
   / Loop over ANALYSISVARS to call TU_STATSWITHTOTAL and TU_STATSFMT        
   /----------------------------------------------------------------------*/

   %DO l_i=1 %TO &l_numof_analysisvars;
                                                                                                                                                                     
      %LET l_analysisVar=%scan(&analysisVars, &l_i);      
      
   /*
   / 1. Get a list of log statistical key words. Loop over the keyword
   /  a If CLM is not in the key word, remove the ALPHA= option from
   /    &PSOPTIONS
   /  b For derived statistics, create key words, which will be used 
   /    to derive them and associate temporary variables to the new 
   /    key words. The new keywords ard temporary variables are:
   /    a) For CLM, lclm=__lclm10__ and uclm=__uclm10__
   /    b) For CLMLOG, lclm=__lclmlog10__ and uclm=__uclmlog10__
   /    c) For CVB, std=__std10__ mean=__mean10__
   /    d) For CVBLOG, std=__stdlog0__ 
   /    e) For GEOMEAN, mean=__geomean__
   /    f) For GEOMEANCLM, mean=__geomean0__, lclm=__lclmlog0__ and uclm=__uclmlog0__
   /    g) For MEANCLM, mean=__mean0__, lclm=__lclm0__ and uclm=__uclm0__
   /--------------------------------------------------------------------------*/     
             
      DATA _NULL_;
         length tmpstatslist statslist logstatslist calcstatsvars statsvars 
                statskeywords calcstatskeywords clmvars clmvarstats $10000  
                psoptions logpsoptions var1 var2 $200;
                
         statslist=symget("l_statslist&l_i");
         psoptions="&psoptions";
         logpsoptions="&l_logpsoptions";
         numofcalcvars=0;
         numofclmvars=0;
       
         index=index(statslist, '=');
         
         /* Get the statistical key workd in &STATSLIST */
         IF index GT 0 THEN 
         DO;
            i=1;
            var1=scan(statslist, i, ' =');
            var1=trim(left(var1));
            
            DO WHILE (var1 NE '');
              var2=scan(statslist, i + 1, ' =');
            
              IF ( indexw("&l_logstats", upcase(var1)) GT 0) THEN
              DO;
                 LINK logstats;
              END;
              ELSE DO;
                 LINK clmvar;
              END;
                        
              i=i + 2;
              var1=scan(statslist, i, ' =');
            END;
         END;
         ELSE DO;
            i=1;
            var1=scan(statslist, i, ' ');    
            var1=trim(left(var1));      
         
            DO WHILE (var1 NE '');
               var2=var1;
               IF ( indexw("&l_logstats", upcase(var1)) GT 0 ) THEN DO;
                  LINK logstats;
               END;
               ELSE DO;
                  LINK clmvar;
               END;
                              
               i=i + 1;
               var1=scan(statslist, i);            
           END;      
         END; /* end-if on index gt 0 */
  
         /* 
         /  If only statistics N is required in non-log statistics
         /  put N and log statistics together
         /------------------------------------------------------------------*/
         
         IF ( compress(scan(tmpstatslist, 3, '=')) EQ ''  ) AND 
            ( compress(scan(tmpstatslist, 2, '=')) EQ 'N' ) AND
            ( logstatslist NE '' ) THEN
         DO;
            logstatslist=trim(logstatslist)||' '||left(tmpstatslist);
            tmpstatslist='';
         END;
         
         /*
         / Remove 'ALPHA=' from PSOPTIONS if CLM is not in KEYWORDS.
         /------------------------------------------------------------------*/
         
         rx1=rxparse("$w* 'ALPHA' $w* '=' $w* $f $w* ");  
         CALL rxsubstr(rx1, upcase(psoptions), pos, len);
         CALL rxfree(rx1);
         
         IF ( len gt 0 ) AND ( pos GT 0 ) THEN
         DO;
            IF (indexw(statskeywords, 'CLM')  EQ 0) AND
               (indexw(statskeywords, 'UCLM') EQ 0) AND
               (indexw(statskeywords, 'MEANCLM') EQ 0) AND    /*yw002*/
               (indexw(statskeywords, 'LCLM') EQ 0) THEN
            DO;
               substr(psoptions, pos, len)=' ';            
            END;
            
            IF (indexw(statskeywords, 'GEOMEANCLM')  EQ 0) AND
               (indexw(statskeywords, 'CLMLOG')      EQ 0) AND
               (indexw(statskeywords, 'UCLMLOG')     EQ 0) AND
               (indexw(statskeywords, 'LCLMLOG')     EQ 0) THEN
            DO;
               substr(logpsoptions, pos, len)=' ';            
            END;               
         END; /* end-if on ( len gt 0 ) AND ( pos GT 0 ) */
                  
         CALL symput('l_calcstatskeywords', trim(left(calcstatskeywords)));
         CALL symput('l_calcstatsvars',     trim(left(calcstatsvars)));
         CALL symput('l_clmvars',           trim(left(clmvars)));
         CALL symput('l_clmvarstats',       trim(left(clmvarstats)));
         CALL symput('l_logstatslist',      trim(left(logstatslist)));
         CALL symput('l_numofcalcvars',     trim(put(numofcalcvars, 6.0)));
         CALL symput('l_numofclmvars',      trim(put(numofclmvars, 6.0)));      
         CALL symput('l_tmpstatslist',      trim(left(tmpstatslist)));
         CALL symput('l_statskeywords',     trim(left(statskeywords)));
         CALL symput('l_statsvars',         trim(left(statsvars)));
         CALL symput('l_psoptions',         trim(left(psoptions)));
         CALL symput('l_logpsoptions',      trim(left(logpsoptions)));

         RETURN;
         
      CLMVAR:          
         var1=upcase(left(var1));
         var2=upcase(left(var2));
         statskeywords=trim(left(statskeywords))||' '||var1;
         statsvars=trim(left(statsvars))||' '||var2;   
         
         SELECT (var1);
            WHEN ('CLM') DO;
               clmvars=trim(left(clmvars))||' '||var2;
               clmvarstats=trim(left(clmvarstats))||' '||var1;
               numofclmvars=numofclmvars + 1;
               tmpstatslist=trim(tmpstatslist)||' lclm=__lclm10__';
               tmpstatslist=trim(tmpstatslist)||' uclm=__uclm10__'; 
            END;
            WHEN ('MEANCLM') DO;
               clmvars=trim(left(clmvars))||' '||var2;
               clmvarstats=trim(left(clmvarstats))||' '||var1;
               numofclmvars=numofclmvars + 1;
               tmpstatslist=trim(tmpstatslist)||' mean=__mean0__';
               tmpstatslist=trim(tmpstatslist)||' lclm=__lclm0__';
               tmpstatslist=trim(tmpstatslist)||' uclm=__uclm0__'; 
            END;
            WHEN ('CVB') DO;
               tmpstatslist=trim(tmpstatslist)||' std=__std10__';
               tmpstatslist=trim(tmpstatslist)||' mean=__mean10__'; 
               numofcalcvars=numofcalcvars + 1;
               calcstatskeywords=trim(left(calcstatskeywords))||' '||var1;
               calcstatsvars=trim(left(calcstatsvars))||' '||left(var2);                 
            END;            
            OTHERWISE DO;
               tmpstatslist=trim(tmpstatslist)||' '||trim(left(var1))||'='||left(var2);  
            END;
         END; /* end of SELECT on var1 */ 
    
         RETURN;
         
      LOGSTATS:
         /* build stats list for log stats */
         numofcalcvars=numofcalcvars + 1;
         var1=upcase(trim(left(var1)));
         var2=upcase(left(var2));
         calcstatskeywords=trim(left(calcstatskeywords))||' '||var1;
         calcstatsvars=trim(left(calcstatsvars))||' '||var2;         
         statskeywords=trim(left(statskeywords))||' '||var1;
         statsvars=trim(left(statsvars))||' '||var2;           
         
         IF ( var1 not in ('CLMLOG' 'CVBLOG') ) and ( substr(var1, length(var1) -2, 3) EQ 'LOG') THEN
         DO;
            logstatslist=trim(logstatslist)||' '||trim(substr(var1, 1, length(var1) - 3))||'=__'||trim(var1)||'__';
         END;
                
         SELECT (var1);
            WHEN ('GEOMEAN') DO;
                logstatslist=trim(logstatslist)||' mean=__geomean__';
            END;
            WHEN ('GEOMEANCLM') DO; 
                clmvars=trim(left(clmvars))||' '||var2;
                clmvarstats=trim(left(clmvarstats))||' '||var1;
                numofclmvars=numofclmvars + 1;
                logstatslist=trim(logstatslist)||' mean=__geomean0__';
                logstatslist=trim(logstatslist)||' lclm=__lclmlog0__';
                logstatslist=trim(logstatslist)||' uclm=__uclmlog0__';
            END;        
            WHEN ('CLMLOG') DO;
                clmvars=trim(left(clmvars))||' '||var2;
                clmvarstats=trim(left(clmvarstats))||' '||var1;
                numofclmvars=numofclmvars + 1;
                logstatslist=trim(logstatslist)||' lclm=__lclmlog10__';
                logstatslist=trim(logstatslist)||' uclm=__uclmlog10__';
            END;
            WHEN ('CVBLOG') DO;
                logstatslist=trim(logstatslist)||' std=__stdlog0__';
            END;        
            OTHERWISE ;
         END; /* end of SELECT on var1 */    
           
         RETURN;
                    
      RUN;            

      /*
      / Call %tu_statswithtotal to create summary data set. If LOG statistics 
      / exist, call %tu_statswithtotal twice. 
      / a. If it is for LOG statistics, apply LOG to current &ANALYSISVARS
      / b. If LOG statistics exist, merge the data sets, created by 
      /    %tu_statswithtotal, by variables in &ACROSSVAR, &ACROSSVARDECODE 
      /    and &GROUPBYVARSANALY
      /-----------------------------------------------------------------------*/
      
      %LET l_j=0;
         
      %IF %nrbquote(&l_tmpstatslist) EQ %THEN %LET l_tmpstatslist=&l_logstatslist;
      
      %DO %WHILE ( %nrbquote(&l_tmpstatslist) NE );
      
         %LET l_j=%eval(&l_j + 1);
         
         /* Apply log to value of analysis variable for log statistics */
         %IF %nrbquote(&l_tmpstatslist) EQ %nrbquote(&l_logstatslist) %THEN 
         %DO;          
            DATA &l_prefix._logd;
               SET &l_workdata;
               if &l_analysisvar gt 0 then
                  &l_analysisvar=log(&l_analysisvar);
               else 
                  &l_analysisvar=.;
            RUN;
            
            %LET l_workdata1=&l_prefix._logd;             
            %LET l_psoptions=&l_logpsoptions;
         %END;
         %ELSE %LET l_workdata1=&l_workdata;
         
         %LET g_popdata=&l_newpopdata;
      
         %tu_statswithtotal(
            addbignyn               =&addbignyn            ,
            analysisVar             =&l_analysisVar        ,
            groupminmaxvar          =                      ,
            analysisvarformatdname  =&l_formatd            ,
            analysisvarname         =&analysisvarname      ,
            bignlabelsplitchar      =&l_splitchar          ,
            bignvarname             =&bigNvarName          ,
            codedecodevarpairs      =&l_codeDecodeVarPairs ,
            completetypesvars       =&completetypesvars    ,
            countdistinctwhatvar    =                      ,
            countvarname            =                      ,
            dsetinanaly             =&l_workdata1          ,
            dsetindenom             =                      ,
            dsetout                 =&l_prefix.sumout&l_i&l_j,
            dsetOutCi               =                      ,
            groupByVarPop           =&groupByVarPop        ,
            groupByVarsAnaly        =&groupByVarsAnaly     ,
            groupByVarsDenom        =                      ,
            psByvars                =&psByvars             ,
            psClass                 =&psClass              ,
            psClassOptions          =&psClassOptions       ,
            psFormat                =&psFormat             ,
            psFreq                  =&psFreq               ,
            psid                    =&psid                 ,
            psOptions               =&l_psOptions          ,
            psOutput                =&psOutput             ,
            psOutputOptions         =&psOutputOptions      ,
            psTypes                 =&psTypes              ,
            psWays                  =&psWays               ,
            psWeight                =&psWeight             ,
            remSummaryPctYN         =N                     ,
            resultPctDPS            =                      ,
            resultStyle             =                      ,
            resultVarName           =&resultVarName        ,
            statsList               =&l_tmpstatslist       ,
            summaryLevelVarName     =&l_summaryLevelVarName,
            totalDecode             =&totalDecode          ,
            totalForVar             =&totalForVar          ,
            totalID                 =&totalID              ,
            varlabelstyle           =std            
            );    
                                                                               
         %LET g_popdata=&l_oldpopdata;
         
         %IF &g_abort EQ 1 %THEN %GOTO macerr;
         
         %LET l_stepdata=&l_prefix.sumout&l_i&l_j;
         
         %IF &l_j eq 2 %THEN
         %DO;
            PROC SORT data=&l_prefix.sumout&l_i.1 out=&l_prefix.sumsort&l_i.1;  
               BY &acrossvar &l_acrossvardecode &L_GROUPBYVARSANALY_BYVARS;
            RUN;
            
            PROC SORT data=&l_prefix.sumout&l_i.2 out=&l_prefix.sumsort&l_i.2;                                      
               BY &acrossvar &l_acrossvardecode &L_GROUPBYVARSANALY_BYVARS;
            RUN;
            
            DATA &l_prefix.sumout_&l_i;
               MERGE &l_prefix.sumsort&l_i.1
                     &l_prefix.sumsort&l_i.2;
               BY &acrossvar &l_acrossvardecode &L_GROUPBYVARSANALY_BYVARS;
            RUN;            
            
            %LET l_stepdata=&l_prefix.sumout_&l_i;                                              
         %END; /* end-if on &l_j eq 2 */                   
         
         %IF %nrbquote(&l_tmpstatslist) EQ %nrbquote(&l_logstatslist) %THEN %LET l_tmpstatslist=;
         %ELSE %LET l_tmpstatslist=&l_logstatslist;               
                  
      %END; /* end of do-while loop on %nrbquote(&l_tmpstatslist) NE */
      
            
      /*
      / 1. Check if &ANALYSISVARDPS for current &ANALYSISVARS is valid                       
      / 2. Loop over &STATSDPS for current &ANALYSISVARS to check: 
      /    a. If the variable is in &STATSLIST for current variable
      /    b. If the statistical key word is one with CLM, change the variable for the
      /       key word as follows:
      /       a) For CLM, change to __LCLM10__ and __UCLM10__
      /       b) For CLMLOG, change to __lclmlog10__and __uclmlog10__ 
      /       c) For GEOMEANCLM, change to __GEOMEAN0__, __lclmlog0__ and __uclmlog0__
      /       d) For MEANCLM, change to __MEAN0__, __LCLM0__ and __UCLM0__
      /    c. If a variable in &STATSLIST is not in &STATSDPS, add it in and set the
      /       decimal position to 0, +0 or BEST12. depending on the decimal positions 
      /       given in &STATSDPS for other variables
      /    d. Check if decimal positions given in &STATSDPS are valid
      /------------------------------------------------------------------------------*/

      %LET l_rc=0;
      DATA _NULL_;
         LENGTH statsvars statskeywords statsdps newdps allstatslist $500 
                statsvar statskeyword dpsvar dps $32 stddps $8.;
         
         /* ANALYSISVARDPS */
         newdps=trim(left("&&l_ANALYSISVARDPS&l_i"));

         IF ( newdps NE "") THEN IF ( (length(newdps) GT 2) AND verify(substr(newdps, 2), '0123456789') ) OR
             verify(substr(newdps, 1, 1), '0123456789') THEN 
         DO;
            PUT "RTE" "RROR: &sysmacroname: ANALYSISVARDPS(=&analysisvardps) for variable &l_analysisVar is invalid" ;
            CALL SYMPUT('l_rc', '-1');
            STOP;
         END;

         CALL SYMPUT('L_ANALYSISVARDPS', trim(left(newdps)));  
              
         statsvars=upcase(left("&l_statsvars"));   
         statskeywords=upcase(left("&l_statskeywords"));       
         allstatslist=upcase(left("&l_allstatslist"));
         
         /* Loop over STATSDPS */
         statsdps=upcase(left("&&l_statsdps&l_i"));
         newdps="";

         i=1;
         dpsvar=scan(statsdps, i, " ");
         IF indexc(statsdps, '+-') GT 0 THEN stddps="+0";
         ELSE IF index(statsdps, '.') GT 0 THEN stddps='best12.';
         ELSE stddps="+0";

         DO WHILE(dpsvar NE "");

            /* check if dps is valid */
            dps=scan(statsdps, i + 1, " ");
            dpserr=0;            
            
            IF substr(left(dps), 1, 1) in ('+' '-') THEN
            DO;
               stddps="+0";
               IF verify(compress(substr(dps, 2)),"0123456789") THEN dpserr=1;               
            END;
            ELSE IF ( scan(dps, 3, '.') NE '' ) or ( scan(dps, 2, '.') EQ '' ) THEN dpserr=1;
            ELSE IF verify(trim(left(scan(dps, 1, '.'))),"0123456789") THEN dpserr=1;
            ELSE IF verify(trim(left(scan(dps, 2, '.'))),"0123456789") THEN dpserr=1;          
            
            IF dpserr THEN 
            DO; 
               PUT "RTERR" "OR: &sysmacroname: value of parameter STATSDPS is invalid";
               CALL SYMPUT("l_rc", "-1");
               STOP;
            END;

            /* check if dpsvar is in statskeywords */
            inddps=indexw(statsvars, dpsvar);
            IF inddps EQ 0 THEN 
            DO;
               PUT "RTN" "OTE: &sysmacroname: variable " dpsvar " in STATSDPS is not in STATSLIST and has been removed.";
            END;
            ELSE DO;               
               IF inddps GT 1 THEN 
               DO; 
                  statskeyword=left(compbl(substr(statsvars, 1, inddps - 1)));
                  inddps=length(statskeyword) - length(compress(statskeyword)) + 2;
               END;
               ELSE inddps=1;
             
               statskeyword=scan(statskeywords, inddps, ' ');           
               
               SELECT (upcase(statskeyword));
               WHEN ('CLMLOG')
                  newdps=trim(left(newdps))||" __lclmlog10__ "||trim(left(dps))||" __uclmlog10__ "||trim(left(dps));                  
               WHEN ('CLM') 
                  newdps=trim(left(newdps))||" __LCLM10__ "   ||trim(left(dps))||" __UCLM10__ "   ||trim(left(dps));
               WHEN ('GEOMEANCLM')
                  newdps=trim(left(newdps))||" __GEOMEAN0__ " ||trim(left(dps))||" __lclmlog0__ " ||trim(left(dps))||" __uclmlog0__ "||trim(left(dps));
               WHEN ('MEANCLM')
                  newdps=trim(left(newdps))||" __MEAN0__ "    ||trim(left(dps))||" __LCLM0__ "    ||trim(left(dps))||" __UCLM0__ "||trim(left(dps));
               OTHERWISE               
                  newdps=trim(left(newdps))||" "||trim(left(dpsvar))||" "||trim(left(dps));
               END;
            END;  /* end-else on inddps NE 0 */

            i=i+2;
            dpsvar=scan(statsdps, i, " ");
         END;  /* end-if on DO WHILE(dpsvar NE "") */

         /* check if statvar in statsdps, if not add in */    
         i=1;
         statsvar=scan(statsvars, i, " ");
         statskeyword=scan(statskeywords, i, " ");
         DO WHILE(statsvar NE "");
            /* Get a list of variables need to be aligned, do not align CLM and CLMLOG */
            IF ( indexw(allstatslist, statsvar) EQ 0 ) AND ( statskeyword NOT IN ('CLMLOG' 'CLM') ) THEN 
            DO;
               allstatslist=trim(left(allstatslist))||' '||trim(left(statsvar));
            END;
            
            IF indexw(statsdps, statsvar) EQ 0 THEN 
            DO;
               PUT "RTN" "OTE: &sysmacroname: variable " statsvar " in STATSLIST is not in STATSDPS and has been added.";               
               SELECT (upcase(statskeyword));
               WHEN ('CLMLOG')
                  newdps=trim(left(newdps))||" __lclmlog10__ "||compress(stddps)||
                                             " __uclmlog10__ "||compress(stddps);                  
               WHEN ('CLM') 
                  newdps=trim(left(newdps))||" __LCLM10__ "   ||compress(stddps)||
                                             " __UCLM10__ "   ||compress(stddps);
               WHEN ('GEOMEANCLM')
                  newdps=trim(left(newdps))||" __GEOMEAN0__ " ||compress(stddps)||
                                             " __lclmlog0__ " ||compress(stddps)||
                                             " __uclmlog0__ " ||compress(stddps);
               WHEN ('MEANCLM')
                  newdps=trim(left(newdps))||" __MEAN0__ "    ||compress(stddps)||
                                             " __LCLM0__ "    ||compress(stddps)||
                                             " __UCLM0__ "    ||compress(stddps);
               WHEN ('N') DO;
                  IF statskeywords EQ 'N' THEN                  
                     newdps=trim(left(newdps))||" "||trim(left(statsvar))||" "||compress(stddps);
               END;
               OTHERWISE               
                  newdps=trim(left(newdps))||" "||trim(left(statsvar))||" "||compress(stddps);
               END;   
            END; /* end-if on indexw(statsdps, statsvar) EQ 0 */
          
            i=i+1;
            statsvar=scan(statsvars, i, " ");
            statskeyword=scan(statskeywords, i, " ");
         END; /* end of do-while loop on statsvar NE "" */                 

         CALL SYMPUT("l_statsdps", trim(left(newdps)));
         CALL SYMPUT("l_allstatslist", trim(left(allstatslist)));

      RUN;
 
      %IF &L_RC NE 0 %THEN %GOTO macerr;
      
      /*
      /  Add &ANALYSISVARORDERVARNAME and tt_formatd in. The tt_formatd
      /  is the variable to save the current &ANALYSISVARDPS
      /------------------------------------------------------------------*/

      DATA &l_prefix.sumdps&l_i;
         SET &l_stepdata;
         LABEL &analysisvarordervarname="Order of Analysis Variables";
         &analysisvarordervarname=&l_i;
         %IF %nrbquote(&&L_ANALYSISVARDPS&l_i) NE %THEN 
         %DO;
            &L_FORMATD=&&L_ANALYSISVARDPS&l_i;
         %END;
      RUN;
      
      %LET l_stepdata=&l_prefix.sumdps&l_i;
      
      /*
      / Convert statstics result back to normal value according to the statistics 
      / keyword in &STATSLIST. The algorithms for the keyword are as follows:
      / 1. For CLMLOG, convert __lclmlog10__ and __uclmlog10__.
      / 2. For CVBLOG, ((exp(__stdlog0__ ** 2) - 1) ** (1/2)) * 100
      / 3. For CVB, (__std10__ / __mean10__) * 100;
      / 4. For GEOMEAN, exponential of __geomean__.
      / 5. For GEOMEANCLM, exponential of __geomean0__, __lclmlog0__ and __uclmlog0__
      /--------------------------------------------------------------------------*/

      %IF %nrbquote(&l_calcstatsvars) NE %THEN
      %DO;           
         DATA &l_prefix.logfmt&l_i;
            SET &l_stepdata;
            
            %DO l_i2=1 %TO &l_numofcalcvars;                
               %LET l_tmp=%scan(&l_calcstatskeywords, &l_i2);
               
               %IF &l_tmp EQ CLMLOG %THEN
               %DO;
                  __lclmlog10__ =exp(__lclmlog10__);
                  __uclmlog10__ =exp(__uclmlog10__);
               %END;                   
               %ELSE %IF &l_tmp EQ GEOMEANCLM %THEN
               %DO;
                  __geomean0__ =exp(__geomean0__);  
                  __lclmlog0__ =exp(__lclmlog0__);
                  __uclmlog0__ =exp(__uclmlog0__);                  
               %END;                
               %ELSE %IF &l_tmp EQ GEOMEAN %THEN
               %DO;
                  DROP __geomean__;
                  %scan(&l_calcstatsvars, &l_i2)=exp(__geomean__);   
               %END;   
               %ELSE %IF &l_tmp EQ CVB %THEN
               %DO;
                  DROP __std10__ __mean10__;
                  %scan(&l_calcstatsvars, &l_i2)=(__std10__ / __mean10__) * 100;  
               %END;                              
               %ELSE %IF &l_tmp EQ CVBLOG %THEN
               %DO;
                  DROP __stdlog0__;
                  %scan(&l_calcstatsvars, &l_i2)=((exp(__stdlog0__ ** 2) - 1) ** (1/2)) * 100;  
               %END;        
               %ELSE %IF ( &l_tmp EQ STDLOG ) OR ( &l_tmp EQ STDERRLOG ) %THEN
               %DO;
                  DROP __&l_tmp.__;
                  %scan(&l_calcstatsvars, &l_i2)=__&l_tmp.__;  
               %END;                                        
               %ELSE %IF %qsubstr(&l_tmp, %eval(%length(&l_tmp) - 2), 3) EQ LOG  %THEN
               %DO;
                  DROP __&l_tmp.__;
                  %scan(&l_calcstatsvars, &l_i2)=exp(__&l_tmp.__);              
               %END; /* end of if-then-else begin with &l_tmp eq CLMLOG */
            %END; /* end of do-to loop on &l_i2 */            
         RUN;            
                            
         %LET l_stepdata=&l_prefix.logfmt&l_i;                         
         
      %END; /* end-if on %nrbquote(&l_calcstatsvars) NE */
      
      /*
      / Call TU_STATSFMT to add format to summary statistics.         
      /-------------------------------------------------------------------*/
      
      %LET l_nobs=%tu_nobs(&l_stepdata);
      %IF &g_abort EQ 1 %THEN %GOTO macerr;

      %tu_statsfmt(
         DSETIN            =&l_stepdata,
         DSETOUT           =&L_PREFIX.SUMFMT&L_I,
         %IF %nrbquote(&&L_XMLINFMT&l_i) EQ %THEN 
         %DO;
         ANALYSISVARDPSVAR =&L_FORMATD,
         STATSDPS          =&L_STATSDPS,
         XMLINFMT          =,
         XMLMERGEVAR       =
         %END;
         %ELSE %DO;
         ANALYSISVARDPSVAR =,
         STATSDPS          =,
         XMLINFMT          =&&L_XMLINFMT&l_i,
         XMLMERGEVAR       =&&L_XMLMERGEVAR&l_i
         %END;
         )
                  
      %IF &g_abort EQ 1 %THEN %GOTO macerr;
      %LET l_stepdata=&L_PREFIX.SUMFMT&L_I;
      
      /*
      / If data set is empty, remove the record added by %tu_statsfmt.
      /--------------------------------------------------------------------*/
                             
      %IF &l_nobs EQ 0 %THEN
      %DO;
         DATA &L_PREFIX.SUMFMT2&L_I;
            SET &l_stepdata;
            IF 0;
         RUN;
         
         %LET l_stepdata=&L_PREFIX.SUMFMT2&L_I;
      %END;
      
      /*
      / Combine Mean, Upper Limit and Low Limit together for statistics
      / CLM, CLMLOG, MEANCLM and GEOMEANCLM                           
      /-------------------------------------------------------------------*/
       
      %IF %nrbquote(&l_clmvars) NE %THEN
      %DO; 
         DATA &L_PREFIX.SUMFMT2&L_I;
            SET &l_stepdata;
            
            %DO l_i2=1 %TO &l_numofclmvars;                
               %LET l_tmp=%upcase(%scan(&l_clmvars, &l_i2));
             
               %IF %scan(&l_clmvarstats, &l_i2) EQ CLMLOG %THEN
               %DO;                           
                  LENGTH &l_tmp $60;
                  DROP __lclmlog10__ __uclmlog10__;
                  IF missing(__lclmlog10__) AND missing(__uclmlog10__) THEN
                     &l_tmp='';
                  ELSE 
                     &l_tmp=left("("||trim(left(__lclmlog10__))||","||trim(left(__uclmlog10__))||")");
               %END;
               %ELSE %IF %scan(&l_clmvarstats, &l_i2) EQ GEOMEANCLM %THEN
               %DO;                           
                  LENGTH &l_tmp $60;                  
                  DROP __lclmlog0__ __uclmlog0__ __geomean0__;
                  IF missing(__geomean0__) THEN
                     &l_tmp='';
                  ELSE 
                     &l_tmp=trim(left(__geomean0__))||' '||left("("||trim(left(__lclmlog0__))||","||trim(left(__uclmlog0__))||")");
               %END;               
               %ELSE %IF %scan(&l_clmvarstats, &l_i2) EQ CLM  %THEN
               %DO;                           
                  LENGTH &l_tmp $60;
                  DROP __lclm10__ __uclm10__;
                  IF missing(__lclm10__) AND missing(__uclm10__) THEN
                     &l_tmp='';
                  ELSE                   
                     &l_tmp=left("("||trim(left(__lclm10__))||","||trim(left(__uclm10__))||")");
               %END;                              
               %ELSE %IF %scan(&l_clmvarstats, &l_i2) EQ MEANCLM  %THEN
               %DO;                           
                  LENGTH &l_tmp $60;
                  DROP __lclm0__ __uclm0__ __mean0__;
                  IF missing(__mean0__) THEN
                     &l_tmp='';
                  ELSE                   
                     &l_tmp=trim(left(__mean0__))||' '||left("("||trim(left(__lclm0__))||","||trim(left(__uclm0__))||")");
               %END; /* end of if-then-else on %scan(&l_clmvarstats, &l_i2) */             
            %END; /* end of do-to loop on &l_i2 */  
                                
         RUN;
         
         %LET l_stepdata=&L_PREFIX.SUMFMT2&L_I;
      %END; /* end-if on %nrbquote(&l_clmvars) */
      
      /*
      / If &STATSINROWSYN equals Y, call tu_labelvars to add standard label to 
      / data set so the stardard labels for STATS can be used in row labels.                
      /-----------------------------------------------------------------------*/
      %IF ( &statsinrowsyn EQ Y ) %THEN 
      %DO;   
         %tu_labelvars(
            DSETIN   =&l_stepdata,
            DSETOUT  =&L_PREFIX.SUMLABEL&L_I,
            STYLE    =STD
            )         
         
         %IF &g_abort EQ 1 %THEN %GOTO macerr;
         %LET l_stepdata=&L_PREFIX.SUMLABEL&L_I;
      %END; /* end-if on &statsinrowsyn EQ Y */     
      
      /* 
      / If &STATSLABELS is not blank, add &statslabels to the data set
      /-------------------------------------------------------------------*/
            
      %IF ( %length(&statslabels) GT 0 ) %THEN 
      %DO;
         DATA &L_PREFIX.SUMLABEL_&L_I;
            SET &l_stepdata;  
            LABEL &statslabels;
         RUN;;
                
         %IF &syserr GT 0 %THEN
         %DO;
            %PUT %str(RTER)ROR: &sysmacroname: DATA step ended with a non-zero return code because of value of parameter STATSLABELS (=&statslabels);
            %GOTO macerr;
         %END;
       
         %LET l_stepdata=&L_PREFIX.SUMLABEL_&L_I;         
      %END; /* end-if on %length(&statslabels) GT 0 */            
 
      /*
      / If &STATSINROWSYN equals Y, transpose summary variables from column to 
      / row. Save the statistics key works to &STATSLISTVARNAME and save the 
      / order of the statistics to &STATSLISTVARORDERVARNAME              
      /-----------------------------------------------------------------------*/

      %IF &statsinrowsyn EQ Y %THEN 
      %DO;       
                  
          DATA &L_PREFIX.SUMLABEL&L_I;
             LENGTH &STATSLISTVARNAME $100 ;
             SET &l_stepdata;
             LABEL &STATSLISTVARNAME="Statistical List" &STATSLISTVARORDERVARNAME="Order of Statistical List";
             DROP &L_FORMATD;
             LENGTH &RESULTVARNAME $60;
           
             %IF &BIGNINROWYN eq Y %THEN
             %DO;
                DROP &bignvarname;
                
                IF vlabel(&bignvarname) NE "" THEN
                   &STATSLISTVARNAME=left(vlabel(&bignvarname));
                ELSE
                   &STATSLISTVARNAME=left(vname(&bignvarname));
        
                &RESULTVARNAME=left(put(&bignvarname, 12.0));
                &L_RESULTNUMVARNAME=&bignvarname;
                &STATSLISTVARORDERVARNAME=0;
                OUTPUT;
             %END;
             
             %LET l_i1=1;
             %LET l_tmp=%scan(&l_statsvars, &l_i1, %str( ,));

             %DO %WHILE( %nrbquote(&l_tmp) NE );
                DROP &l_tmp &l_tmp._num;
        
                IF vlabel(&l_tmp) NE "" THEN
                   &STATSLISTVARNAME=left(vlabel(&l_tmp));
                ELSE
                   &STATSLISTVARNAME=left(vname(&l_tmp));
                   
                &STATSLISTVARORDERVARNAME=&l_i1;   
        
                &RESULTVARNAME=&l_tmp;
                &L_RESULTNUMVARNAME=&l_tmp._num;
        
                OUTPUT;
                &l_tmp._num=0;

                %LET l_i1=%eval(&l_i1 + 1);
                %LET l_tmp=%scan(&l_statsvars, &l_i1, %str( ,));
             %END;
          RUN;     
          %LET l_stepdata=&L_PREFIX.SUMLABEL&L_I;     
      %END; /* end-if on &statsinrowsyn EQ Y */

      /*
      / Concatenate data set and loop to next variable.              
      /-------------------------------------------------------------------*/

      %IF &l_i EQ 1 %THEN %LET l_loopdata=&l_stepdata;
      %ELSE %DO;
         DATA &l_prefix.fmtout&l_i;
            SET &l_loopdata &l_stepdata;
         RUN;
         %LET l_loopdata=&l_prefix.fmtout&l_i;
      %END;

   %END;  /* end of %DO l_i=1 %TO &l_numof_analysisvars */

   %LET l_workdata=&l_loopdata;

   /*
   / If &TOTALFORVAR is blank, &BIGNVARNAME is not blank and '=' is in 
   / &GROUPBYVARSANALY, Add bigN for total group. This is for compatibility with 
   / old version. 
   /--------------------------------------------------------------------------*/
   
   %IF ( %nrbquote(&totalforvar) EQ ) and ( %nrbquote(&bignvarname) NE ) 
       AND ( %index(&groupbyvarsanaly, %str(=)) GT 0 ) AND 
       ( %nrbquote(&groupbyvarpop) NE ) %THEN
   %DO;
              
      %IF &addbignyn EQ Y %THEN
      %DO;
         %LET l_tmp=%upcase(%qscan(&groupbyvarpop, -1));
         %LET l_bigntovardecodevar=&l_tmp;
         %LET l_i=1;
         %LET l_i2=%upcase(%scan(&l_codedecodevarpairs, &l_i));
         %LET l_i3=%upcase(%scan(&l_codedecodevarpairs, %eval(&l_i+1)));
         
         %DO %WHILE( ( %nrbquote(&l_i2) NE ) AND ( %nrbquote(&l_i3) NE ) );
            %IF ( &l_tmp EQ &l_i2 ) OR ( &l_tmp EQ &l_i3 ) %THEN %LET l_bigntovardecodevar=&l_i3;         
            %LET l_i=%eval(&l_i + 1);            
            %LET l_i2=%upcase(%scan(&l_codedecodevarpairs, &l_i));
            %LET l_i3=%upcase(%scan(&l_codedecodevarpairs, %eval(&l_i+1)));             
         %END; /* end of %do-%while loop */
      %END; /* end-if on &addbignyn EQ Y */

      PROC SORT DATA=&l_workdata(KEEP=&groupbyvarpop &bignvarname &l_bigntovardecodevar &l_summaryLevelVarName) 
           out=&l_prefix.pop1 nodupkey;
          BY &groupbyvarpop descending &l_summaryLevelVarName &bignvarname;
      RUN;
      
      DATA &l_prefix.pop2;
         SET &l_prefix.pop1;
         BY &groupbyvarpop descending &l_summaryLevelVarName &bignvarname;
         RETAIN __b_i_g_n__ 0;
         DROP __b_i_g_n__ &l_summaryLevelVarName;
         
         %IF %qscan(&groupbyvarpop, -2) NE %THEN 
         %DO;
            IF first.%scan(&groupbyvarpop, -2) THEN __b_i_g_n__=0;
         %END;
                                                                     
         IF missing(&bignvarname) AND (__b_i_g_n__ NE 0) THEN 
         DO;
            &bignvarname=__b_i_g_n__;
            
            %IF &addbignyn EQ Y %THEN
            %DO;
               IF index(&l_bigntovardecodevar, "(N=") GT 0 THEN
               DO;
                  substr(&l_bigntovardecodevar, index(&l_bigntovardecodevar, "(N="))="(N="||trim(left(put(&bignvarname, best12.0)))||")";         
               END;            
            %END; /* end-if on &addbignyn EQ Y */
         END; /* end-if on missing(&bignvarname) AND (__b_i_g_n__ NE 0) */
         
         IF not missing(&bignvarname) THEN __b_i_g_n__=__b_i_g_n__ + &bignvarname;         
      RUN;
      
      PROC SORT DATA=&l_workdata out=&l_prefix.sort1 (DROP=&bignvarname &l_bigntovardecodevar);
          BY &groupbyvarpop;
      RUN;            
   
      DATA &l_prefix.sort2;
         MERGE &l_prefix.sort1 &l_prefix.pop2;
         BY &groupbyvarpop;
      RUN;
      
      %LET l_workdata= &l_prefix.sort2;
   %END; /* end-if on ( %nrbquote(&totalforvar) EQ ) and ( %nrbquote(&bignvarname) NE ) */
   
   /*
   / If &DENORMYN equals Y, all tu_denorm to convert &ACROSSVAR from row to 
   / column.                                       
   /--------------------------------------------------------------------------*/

   %IF &DENORMYN EQ Y %THEN 
   %DO;
      %tu_denorm(
         ACROSSCOLVARPREFIX =&ACROSSCOLVARPREFIX,
         ACROSSVAR          =&ACROSSVAR,
         ACROSSVARLABEL     =&L_ACROSSVARDECODE,
         ACROSSVARLISTNAME  =&ACROSSCOLLISTNAME,
         DSETIN             =&L_WORKDATA,
         DSETOUT            =&L_PREFIX.DENORM &L_PREFIX.NUM_DENORM,
         GROUPBYVARS        =&L_GROUPBYVARSANALY_BYVARS &ANALYSISVARORDERVARNAME &ANALYSISVARNAME &STATSLISTVARORDERVARNAME &STATSLISTVARNAME,
         VARSTODENORM       =&RESULTVARNAME 
         )

      %IF &g_abort EQ 1 %THEN %GOTO macerr;
      %LET L_WORKDATA=&L_PREFIX.DENORM;
      
      %IF %length(&&&ACROSSCOLLISTNAME) GT 0 %THEN 
      %DO;
         %LET l_tmp  = %sysfunc(rxparse($q TO " " %str(,) "(" TO " " %str(,) ")" TO " "));         
         %LET l_acrossvarlist = &&&ACROSSCOLLISTNAME;      
         %LET l_i1=999;
         %syscall rxchange(l_tmp, l_i1, l_acrossvarlist, l_acrossvarlist);
         %syscall rxfree(l_tmp);         
      %END;

   %END; /* End of IF on DENORMYN EQ Y */
   
   /* 
   / If &LABELVARSYN equals Y, call %tu_labelvars again to standardise variable 
   / labels in the working dataset. Use style=&VARLABELSTYLE
   /--------------------------------------------------------------------------*/

   %IF &LABELVARSYN EQ Y %THEN %DO;
      %tu_labelvars(
         DSETIN   =&L_WORKDATA,
         DSETOUT  =&L_PREFIX.LABELOUT,
         STYLE    =&VARLABELSTYLE
         )

      %LET L_WORKDATA=&L_PREFIX.labelout;
   %END;

   /*
   / If &ALIGNYN equals Y, call tu_align to align the statistical results at 
   / decimal
   /--------------------------------------------------------------------------*/

   %IF &ALIGNYN EQ Y %THEN 
   %DO;                                                                  
      %IF &DENORMYN EQ Y %THEN %LET L_TMP=&l_acrossvarlist;
      %ELSE %IF &STATSINROWSYN EQ N %THEN %LET L_TMP=&l_allstatslist;
      %ELSE  %LET L_TMP=&RESULTVARNAME;      

      %IF %nrbquote(&l_tmp) ne %THEN
      %DO;
         %tu_align(         
            ALIGNMENT     =R,
            COMPRESSCHRYN =Y,
            DP            =.,       
            DSETIN        =&L_WORKDATA,
            DSETOUT       =&L_PREFIX.ALIGNOUT,
            NCSPACES      =1,
            NDSPCHAR      =/,       
            VARSIN        =&L_TMP,
            VARSOUT       =         
            )
         %IF &g_abort EQ 1 %THEN %GOTO macerr;
         %LET l_workdata=&l_prefix.alignout;    
      %END;                 
   %END; /* end-if on &ALIGNYN EQ Y */ 

   /*
   / If &STATSINROWSYN equals Y, optimize the length of new added character 
   / variables                                                   
   /--------------------------------------------------------------------------*/

   %IF &statsinrowsyn EQ Y %THEN 
   %DO;
      %LET l_i1=1;
      %LET l_i2=1;
      
      DATA _NULL_;
         SET &l_workdata(KEEP=&ANALYSISVARNAME &STATSLISTVARNAME) end=end;
         RETAIN __temp__length_1__ &l_i1  __temp__length_2__ &l_i2;
         
         __temp__length_1__=max(__temp__length_1__, length(&analysisvarname));                              
         __temp__length_2__=max(__temp__length_2__, length(&STATSLISTVARNAME));
     
         IF END THEN 
         DO;
            CALL SYMPUT('l_i1', put(__temp__length_1__, 6.0));
            CALL SYMPUT('l_i2', put(__temp__length_2__, 6.0));
         END;
                                        
      RUN;
   %END; /* end-if on &statsinrowsyn EQ Y */
   
   /*
   / Apply the POSTSUBSET and crate final data set.                      
   /----------------------------------------------------------------------*/
   
   %LET l_nobs=%tu_nobs(&l_workdata);
   %IF &g_abort EQ 1 %THEN %GOTO macerr;
   
   DATA %IF %nrbquote(&DSETOUT) NE %THEN 
        %DO;
           &DSETOUT;
        %END;
        %ELSE %DO;                 
           &l_prefix.outdata;
        %END;
      
      %IF &statsinrowsyn EQ Y %THEN 
      %DO;  
         LENGTH &analysisvarname $&l_i1. &STATSLISTVARNAME $&l_i2. ;
      %END;

      SET &l_workdata(label="Output data set created by &sysmacroname");
      
      /*
      /  If data set is empty, add acrossprefix as a variable so that
      /  the error caused by %tu_list can be avoided. It can be removed
      /  after the modification of %tu_list.
      /----------------------------------------------------------------------*/
      
      %IF &l_nobs EQ 0 %THEN
      %DO;
         &acrosscolvarprefix=0;
      %END;
      
      %IF %nrbquote(&POSTSUBSET) NE %THEN 
      %DO;
         %IF %qscan(%qupcase(&POSTSUBSET), 1, %str( )) EQ %nrstr(IF) %THEN 
         %DO;
            %unquote(&POSTSUBSET);
         %END;
         %ELSE %DO;
            IF %unquote(&POSTSUBSET);
         %END;
      %END; /* end-if on %nrbquote(&POSTSUBSET) NE */ 
   RUN;
   
   %IF &SYSERR GT 0 %THEN 
   %DO;
      %PUT %str(RTERR)OR: &sysmacroname: There are errors in the statements given by POSTSUBSET ;
      %GOTO macerr;
   %END;
         
   %IF %nrbquote(&DSETOUT) NE %THEN 
   %DO;       
      %LET l_workdata=&dsetout;
      %IF %nrbquote(&display) eq N %THEN %GOTO endmac;
   %END;
   %ELSE %DO;     
      %LET l_workdata=&l_prefix.outdata;                        
   %END; 
   
   /*
   / If &ACROSSCOLLISTNAME is not blank and it is in &COLUMN, unquote the 
   / parameter COLUMN                                     
   /--------------------------------------------------------------------------*/
  
   %IF ( %nrbquote(&acrosscollistname) NE ) AND
      %sysfunc(indexw(%qupcase(&columns), %nrstr(&)%qupcase(&acrosscollistname))) GT 0 %THEN 
   %DO;         
     %LET columns=%unquote(&columns);    
   %END;

   /*-------------------------------------------------------------------------*/
   /*-------------------------------------------------------------------------*/
   %DISPLAYIT:
   /*-------------------------------------------------------------------------*/
   /*-------------------------------------------------------------------------*/

   /*
   / Call tu_list to create output. 
   / 1. Set DSETIN to current data set
   / 2. Set LABELVARSYN and GETDATAYN to N. 
   / 3. Pass other parameters directly from the parameters of this macro.
   /--------------------------------------------------------------------------*/

   %tu_list(
      DSETIN                   =&l_workdata,
      GETDATAYN                =N,      
      LABELVARSYN              =N,
      
      BREAK1                   =&BREAK1,
      BREAK2                   =&BREAK2,
      BREAK3                   =&BREAK3,
      BREAK4                   =&BREAK4,
      BREAK5                   =&BREAK5,
      BYVARS                   =&BYVARS,
      CENTREVARS               =&CENTREVARS,
      COLSPACING               =&COLSPACING,
      COLUMNS                  =&COLUMNS,
      COMPUTEBEFOREPAGELINES   =&COMPUTEBEFOREPAGELINES,
      COMPUTEBEFOREPAGEVARS    =&COMPUTEBEFOREPAGEVARS,
      DDDATASETLABEL           =&DDDATASETLABEL,
      DEFAULTWIDTHS            =&DEFAULTWIDTHS,
      DESCENDING               =&DESCENDING,
      DISPLAY                  =&DISPLAY,
      FLOWVARS                 =&FLOWVARS,
      FORMATS                  =&FORMATS,
      IDVARS                   =&IDVARS,
      LABELS                   =&LABELS,
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
      PROPTIONS                =&PROPTIONS,
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
      VARLABELSTYLE            =&VARLABELSTYLE,
      VARSPACING               =&VARSPACING,
      WIDTHS                   =&WIDTHS
      )
   
   %GOTO endmac;

   /*---------------------------------------------------------------------*/
   /*---------------------------------------------------------------------*/
   %MACERR:
   /*---------------------------------------------------------------------*/
   /*---------------------------------------------------------------------*/
   %LET g_abort=1;
   %IF %nrbquote(&l_message) NE %THEN
   %DO;
      %PUT %str(RTE)RROR: &sysmacroname: &l_message;
   %END;

   %PUT;
   %PUT %str(RTNO)TE: --------------------------------------------------------;
   %PUT %str(RTNO)TE: &sysmacroname completed with error(s);
   %PUT %str(RTNO)TE: --------------------------------------------------------;
   %PUT;
   
   %tu_abort();

   /*---------------------------------------------------------------------*/
   /*---------------------------------------------------------------------*/
   %ENDMAC:
   /*---------------------------------------------------------------------*/
   /*---------------------------------------------------------------------*/

   /*
   / Call tu_tidyup to clear temporary data set and fiels.            
   /----------------------------------------------------------------------*/
   
   %IF (%qupcase(&l_trtdata) NE TRT) and (%qupcase(&l_trtdata) NE ) %THEN
   %DO;
      DATA trt;
         SET &l_trtdata;
      RUN;
      
      %LET l_trtdata=;
   %END;

   %tu_tidyup(
      RMDSET =&L_PREFIX: &l_trtdata,
      GLBMAC =NONE
      );

%MEND tu_sumstatsinrows;

