/*---------------------------------------------------------------------------------------+ 
| Macro Name    : td_eg1.sas                                             
|
| Macro Version : 1
|                                                                            
| SAS version   : SAS v8.2                                                   
|                                                                            
| Created By    : Yongwei Wang                                                          
|                                                                         
| Date          : Apr 2004                                                           
|                                                                            
| Macro Purpose : Create IDSL standard EG1 display - Summary of ECG Findings 
|                                                                            
| Macro Design  : PROCEDURE STYLE                                                           
|                                                                            
| Input Parameters :                              
| Name                Description                                       Default           
| ----------------------------------------------------------------------------------------
| ACROSSVAR           Variable to transpose the data across to make     &g_trtcd         
|                     columns of results. This is passed to the proc                      
|                     transpose ID statement hence the values of this                     
|                     variable will be used to name the new columns.                      
|                                                                                         
|                     Valid Values:                                                       
|                     The name of a SAS variable that exists in                           
|                     &DSETIN. In typical usage, this will be the                         
|                     variable containing treatment.                                      
|                                                                                         
| ACROSSVARDECODE     A variable or format used in the construction of  &g_trtgrp          
|                     labels for the result columns.                                      
|                                                                                         
|                     Valid values:                                                       
|                     Blank                                                               
|                     Name of a SAS variable that exists in &DSETIN                       
|                     An available SAS format                                             
|                                                                                         
| BREAK1 BREAK2       For input of user-specified break statements      (Blank)           
| BREAK3 BREAK4       Valid values: valid PROC REPORT BREAK statements                    
| BREAK5              (without "break")                                                   
|                     The value of these parameters are passed                            
|                     directly to PROC REPORT as:                                         
|                     BREAK &break1;                                                      
|                                                                                         
| BYVARS              By variables. The variables listed here are       (Blank)        
|                     processed as standard SAS by variables.                             
|                     Valid values: one or more variable names from                       
|                     DSETIN                                                              
|                     No formatting of the display for these variables                    
|                     is performed by %tu_DISPLAY.  The user has the                      
|                     option of the standard SAS BY line, or using                        
|                     OPTIONS NOBYLINE and #BYVAL #BYVAR directives in                    
|                     title statements.                                                   
|                                                                                         
| CENTREVARS          Variables to be displayed as centre justified     (Blank)           
|                     Valid values: one or more variable names that                       
|                     are also defined with COLUMNS                                       
|                     Variables not appearing in any of the parameters                    
|                     CENTREVARS, LEFTVARS, or RIGHTVARS will be                          
|                     displayed using the PROC REPORT default.                            
|                     Character variables are left justified while                        
|                     numeric variables are right justified                               
|                                                                                         
| CODEDECODEVARPAIRS  Specifies code and decode variable pairs. Those   VISITNUM VISIT    
|                     variables should be in parameter                                    
|                     GROUPBYVARSNUMER. One variable in the pair will                     
|                     contain the code, which is used in counting and                     
|                     ordering, and the other will contain decode,                        
|                     which is used for presentation.                                     
|                     See section 6.1.1 of Appendix.                                      
|                                                                                         
|                     Valid values:  Blank or a list of SAS variable                      
|                     names in pairs that are given in                                    
|                     GROUPBYVARSNUMER,                                                   
|                     e.g.ttcd trtgrp                                                     
|                                                                                         
| COLSPACING          The value of the between-column spacing           2 
|                     Valid values: positive integer                                      
|                                                                                         
| COLUMNS             A PROC REPORT column statement specification.     Visitnum visit    
|                     Including spanning titles and variable names      tt_icat           
|                     Valid values: one or more variable names from     summarylevel      
|                     the DSETOUT dataset, plus other elements of       tt_intp tt_ac:    
|                     valid PROC REPORT COLUMN statement syntax                           
|                                                                                         
| COMPUTEBEFOREPAGEL  See Unit Specification for HARP Reporting Tools   (Blank)           
| INES                TU_LIST[4] for complete details                                     
|                                                                                         
| COMPUTEBEFOREPAGEV  See Unit Specification for HARP Reporting Tools   (Blank)           
| ARS                 TU_LIST[4] for complete details                                    
|                                                                                         
| COUNTDISTINCTWHATV  Variable(s) that contain values to be counted     &g_centid         
| AR                  uniquely within any output grouping               &g_subjid         
|                                                                                         
|                     Valid values:                                                       
|                     Blank                                                               
|                     Name of one or more SAS variables that exists in                    
|                     &DSETIN                                                             
|                                                                                         
| DDDATASETLABEL      Specifies the label to be applied to the DD       DD dataset for    
|                     dataset                                           EG1 table         
|                     Valid values: a non-blank text string                               
|                                                                                         
| DEFAULTWIDTHS       Specifies column widths for all variables not     tt_intp 45        
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
| DESCENDING          List of ORDERVARS that are given the PROC REPORT  (Blank)           
|                     define statement attribute DESCENDING                               
|                     Valid values: one or more variable names that                       
|                     are also defined with ORDERVARS                                     
|                                                                                         
| DISPLAY             Specifies whether the report should be created.   Y                 
|                     Valid values: Y or N                                                
|                     If &g_analy_disp is D, DISPLAY shall be ignored                     
|                                                                                         
| DSETIN              Input dataset containing study ecg data.          ardata.ecg   
|
| DSETINDENOM         Input dataset containing data to be counted to    &g_popdata
|                     obtain the denominator. This may or may not be 
|                     the same as the dataset specified to DSETINNUMER. 
|                     Valid values: 
|                     Any valid SAS dataset reference; dataset options 
|                     are supported.  In typical usage, specifies 
|                     &G_POPDATA     
|                                                                                         
| EGBASELINETIMECD    Specify a baseline value of time variable         1                 
|                     &EGTIMECDVAR                                                          
|                     Valid values: Blank or a numeric value                              
|                                                                                         
| EGCHBLFMT          Specify a format name for variable &EGCHBLVAR    $egchbl.         
|                     Valid values: Blank or a valid existing format                      
|                                                                                         
| EGCHBLVAR          Specify a variable name for Clinical significant  egchbl           
|                     change from baseline                                                
|                     Valid values: Blank or a valid SAS variable,                        
|                     which exists in &DSETIN                                             
|                                                                                         
| EGINTPCDFMT         Specify a format name for variable &EGINTPCDVAR   egintpcd.         
|                     Valid values: Blank or a valid existing format                      
|                                                                                         
| EGINTPCDVAR         Specify a variable name for ECG results code      egintpcd          
|                     Valid values: Blank or a valid SAS variable,                        
|                     which exists in &DSETIN                                             
|                                                                                         
| EGINTPVAR           Specify a variable name for ECG results           egintp            
|                     Valid values: Blank or a valid SAS variable,                        
|                     which exists in &DSETIN                                             
|                                                                                         
| EGPOSTBASELINETIME  Specify a pose-baseline value for &TIMECDVAR      999               
| CD                  Valid values: Blank or a numeric value                              
|                                                                                         
| EGPOSTBASELINETIME  Specify a decode for &EGPOSTBASELINETIMECD. It    Any visit         
| DECODE              is required if &EGPOSTBASELINETIMECD is not       post-baseline     
|                     blank                                                               
|                     Valid values: Blank or a character value                            
|                                                                                         
| EGTIMECDVAR         Specify a Variable name representing time         visitnum          
|                     period. It is code of &EGTIMEVAR. It is required                    
|                     if &EGPOSTBASELINETIMECD is not blank                               
|                     Valid values: Blank or a valid SAS numeric                          
|                     variable, which exists in &DSETIN                                   
|                                                                                         
| EGTIMEVAR           Specify a Variable name representing time         visit             
|                     period. It is the decode of &EGTIMECDVAR. It is                     
|                     required if &EGPOSTBASELINETIMECD is not blank                      
|                     Valid values: Blank or a valid SAS variable,                        
|                     which exists in &DSETIN                                             
|                                                                                         
| FLOWVARS            Variables to be defined with the flow option      visit tt_intp     
|                     Valid values: one or more variable names that                       
|                     are also defined with COLUMNS                                       
|                     Flow variables should be given a width through                      
|                     the WIDTHS.  If a flow variable does not have a                     
|                     width specified, the column width will be                           
|                     determined by                                                       
|                     MIN(variables format width,                                        
|                     width of  column header)                                            
|                                                                                         
| FORMATS             Variables and their format for display.           (Blank)           
|                     Valid values: values of column names and formats                    
|                     such as form valid syntax for a SAS FORMAT                          
|                     statement                                                           
|                                                                                         
| GROUPBYVARPOP       Specifies a list of variables to group by when    &g_trtcd          
|                     counting big N using %tu_addbignvar. Usually one                    
|                     variable &g_trtcd.                                                  
|                     It will be passed to GROUPBYVARS of                                 
|                     %tu_addbignvar.                                                     
|                     Required if ADDBIGNYN =Y                                            
|                     Valid values:                                                       
|                     Blank if ADDBIGNYN=N                                                
|                     Otherwise, a list of valid SAS variable names                       
|                     that exist in population dataset created by                         
|                     %tu_freq's calling %tu_getdata                                      
|                                                                                         
| GROUPBYVARSDENOM    Variables in DSETINDENOM to group the data by     &g_trtcd          
|                     when counting to obtain the denominator.                            
|                                                                                         
|                     Valid values:                                                       
|                     Blank, _NONE_ (to request an overall total for                      
|                     the whole dataset)                                                  
|                     Name of a SAS variable that exists in                               
|                     DSETINDENOM                                                         
|                                                                                         
| GROUPBYVARSNUMER    Variables in DSETINNUMER to group the data by     &g_trtcd visitnum 
|                     when counting to obtain the numerator.            tt_icat           
|                     Additionally a set of brackets may be inserted    (tt_intp='n')     
|                     within the variables to generate records          visit tt_intp     
|                     containing summary counts grouped by variables                      
|                     specified to the left of the brackets. Summary                      
|                     records created may be populated with values in                     
|                     the grouping variables by specifying variable                       
|                     value pairs within brackets, separated by                           
|                     semicolons. eg aesoccd aesoc(aeptcd=0; aept="Any                    
|                     Event";) aeptcd aept.                                               
|                                                                                         
|                     Valid values:                                                       
|                     Blank, _NONE_ (to request an overall total for                      
|                     the whole dataset)                                                  
|                     Name of one or more SAS variables that exist in                     
|                     DSETINNUMER                                                         
|                     SAS assignment statements within brackets                           
|                                                                                         
| IDVARS              Variables to appear on each page if the report    visit tt_intp     
|                     is wider than 1 page. If no value is supplied to                    
|                     this parameter then all displayable order                           
|                     variables will be defined as IDVARS                                 
|                     Valid values: one or more variable names that                       
|                     are also defined with COLUMNS                                       
|                                                                                         
| LABELS              Variables and their label for display.            (Blank)           
|                     Valid values: pairs of variable names and labels                    
|                                                                                         
| LEFTVARS            Variables to be displayed as left justified       (Blank)           
|                     Valid values: one or more variable names  that                      
|                     are also defined with COLUMNS                                       
|                                                                                         
| LINEVARS            List of order variables that are printed with     (Blank)           
|                     LINE statements in PROC REPORT                                      
|                     Valid values: one or more variable names that                       
|                     are also defined with ORDERVARS                                     
|                     These values shall be written with a BREAK                          
|                     BEFORE when the value of one of the variables                       
|                     changes. The variables will automatically be                        
|                     defined as NOPRINT                                                  
|                                                                                         
| NOPRINTVARS         Variables listed in the COLUMN parameter that     visitnum tt_icat       
|                     are given the PROC REPORT define statement        summarylevel        
|                     attribute noprint                                           
|                     Valid values: one or more variable names that                       
|                     are also defined with COLUMNS                                       
|                     These variables are ORDERVARS used to control                       
|                     the order of the rows in the display                                
|                                                                                         
| NOWIDOWVAR          Variable whose values must be kept together on a  (Blank)  
|                     page                                                
|                     Valid values: names of one or more variables                        
|                     specified in COLUMNS                                                
|                                                                                         
| ORDERDATA           Variables listed in the ORDERVARS parameter that  tt_intp           
|                     are given the PROC REPORT define statement                          
|                     attribute order=data                                                
|                     Valid values: one or more variable names that                       
|                     are also defined with ORDERVARS                                     
|                     Variables not listed in ORDERFORMATTED,                             
|                     ORDERFREQ, or ORDERDATA are given the define                        
|                     attribute order=internal                                            
|                                                                                         
| ORDERFORMATTED      Variables listed in the ORDERVARS parameter that  (Blank)           
|                     are given the PROC REPORT define statement                          
|                     attribute order=formatted                                           
|                     Valid values: one or more variable names that                       
|                     are also defined with ORDERVARS                                     
|                     Variables not listed in ORDERFORMATTED,                             
|                     ORDERFREQ, or ORDERDATA are given the define                        
|                     attribute order=internal                                            
|                                                                                         
| ORDERFREQ           Variables listed in the ORDERVARS parameter that  (Blank)           
|                     are given the PROC REPORT define statement                          
|                     attribute order=freq                                                
|                     Valid values: one or more variable names that                       
|                     are also defined with ORDERVARS                                     
|                     Variables not listed in ORDERFORMATTED,                             
|                     ORDERFREQ, or ORDERDATA are given the define                        
|                     attribute order=internal                                            
|                                                                                         
| ORDERVARS           List of variables that will receive the PROC      visitnum tt_icat       
|                     REPORT define statement attribute ORDER           summarylevel           
|                     Valid values: one or more variable names that     tt_icat          
|                     are also defined with COLUMNS                                       
|                                                                                         
| OVERALLSUMMARY      Causes the macro to produce an overall summary    N                 
|                     line. Use with ShareColVars.                                        
|                     Valid values: Y or N                                                
|                     The values are not calculated - they must be                        
|                     supplied in a special record in the dataset. The                    
|                     special record is identified by the fact that                       
|                     the value for all of the order variables must be                    
|                     the same for the permutation with the lowest                        
|                     sort order (as resulting from COLUMN and ORDER),                    
|                     i.e. the first report row                                           
|                                                                                         
| PAGEVARS            Variables whose change in value causes the        (Blank)           
|                     display to continue on a new page                                   
|                     Valid values: one or more variable names that                       
|                     are also defined with COLUMNS                                       
|                                                                                         
| POSTSUBSET          SAS expression to be applied to data immediately  %nrstr(if  not      
|                     prior to creation of the permanent presentation   (visitnum eq      
|                     dataset. Used for subsetting records required     &egbaselinetimecd.
|                     for computation but not for display.              and tt_icat eq    
|                                                                       'B') )            
|                     Valid values:                                                       
|                     Blank                                                               
|                     A complete, syntactically valid SAS where or if                     
|                     statement for use in a data step                                    
|                                                                                         
| PROPTIONS           PROC REPORT statement options to be used in       Headline          
|                     addition to MISSING                                                 
|                     Valid values: proc report options                                   
|                     The option Missing can not be overridden                          
|                                                                                         
| PSCLASSOPTIONS      PROC SUMMARY Class Statement Options.             preloadfmt        
|                     Valid values:                                                       
|                     Blank                                                               
|                     Valid PROC SUMMARY CLASS Options (without the                       
|                     leading '/')                                                        
|                     Eg: PRELOADFMT  which can be used in                               
|                     conjunction with PSFORMAT and COMPLETETYPES                         
|                     (default in PSOPTIONS) to create records for                        
|                     possible categories that are specified in a                         
|                     format but which may not exist in data being                        
|                     summarised.                                                         
|                                                                                         
| PSFORMAT            Passed to the PROC SUMMARY FORMAT statement.      (Blank)           
|                     Valid values:                                                       
|                     Blank                                                               
|                     Valid PROC SUMMARY FORMAT statement part.                           
|                                                                                         
| PSOPTIONS           PROC SUMMARY Options to use. MISSING ensures      COMPLETETYPES NWAY
|                     that class variables with missing values are                        
|                     treated as a valid grouping. COMPLETETYPES adds                     
|                     records showing a freq or n of 0 to ensure a                        
|                     cartesian product of all class variables exists                     
|                     in the output. NWAY writes output for the lowest                    
|                     level  combinations of CLASS variables,                             
|                     suppressing all higher level totals.                                
|                     Valid values:                                                       
|                     Blank                                                               
|                     One or more valid PROC SUMMARY options                              
|                                                                                         
| RESULTPCTDPS        The reporting precision for percentages           0                 
|                     Valid values:                                                       
|                     0 or any positive integer                                           
|                                                                                         
| RESULTSTYLE         The appearance style of the result columns that   NUMERPCT          
|                     will be displayed in the report. The chosen                         
|                     style will be placed in variable &RESULTVARNAME.                    
|                     Valid values:                                                       
|                     As documented for tu_percent in [6]. In typical                     
|                     usage, NUMERPCT.                                                    
|                                                                                         
| RIGHTVARS           Variables to be displayed as right justified      (Blank)           
|                     Valid values: one or more variable names  that                      
|                     are also defined with COLUMNS                                       
|                                                                                         
| SHARECOLVARS        List of variables that will share print space.    visit tt_intp     
|                     The attributes of the last variable in the list                     
|                     define the column width and flow options                            
|                     Valid values: one or more sas variable names                        
|                     AE5 shows an example of this style of output                        
|                     The formatted values of the variables shall be                      
|                     written above each other in one column                              
|                                                                                         
| SHARECOLVARSINDENT  Indentation factor for ShareColVars. Stacked      2                 
|                     values shall be progressively indented by                           
|                     multiples of ShareColVarsIndent                                     
|                     Valid values: positive integer                                      
|                                                                                         
| SKIPVARS            Variables whose change in value causes the        tt_icat           
|                     display to skip a line                                              
|                     Valid values: one or more variable names that                       
|                     are also defined with COLUMNS                                       
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
|                     provided here                                                       
|                                                                                         
| TOTALDECODE         Label for the total result column. Usually the    Total             
|                     text Total                                                          
|                     Valid values:                                                       
|                     Blank                                                               
|                     SAS data step expression resolving to a                             
|                     character.                                                          
|                                                                                         
| TOTALFORVAR         Variable for which total is required within all   (blank)           
|                     other grouped classvars (usually trtcd). If not                     
|                     specified, no total will be produced                                
|                     Valid values: Blank if TOTALID is blank.                            
|                                                                                         
| TOTALID             Value used to populate the variable specified in  (blank)           
|                     TOTALFORVAR on data that represents the overall                     
|                     total for the TOTALFORVAR variable.                                 
|                     If no value is specified to this parameter then                     
|                     no overall total of the TOTALFORVAR variable                        
|                     will be generated.                                                  
|                     Valid values                                                        
|                     Blank                                                               
|                     A value that can be entered into &TOTALFORVAR                       
|                     without SAS error or truncation                                     
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
| WIDTHS              Variables and width to display                                      
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
|                     default to be overridden                                            
|                                                                            
|---------------------------------------------------------------------------------------------------
|
| Output:   1. an output file in plain ASCII text format containing a summary in columns data
|              display matching the requirements specified as input parameters.
|           2. SAS data set that forms the foundation of the data display (the "DD dataset").
|
| Global macro variables created: None                                            
|                                                                                                                                                     
| Macros called : 
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_chkvarsexist
| (@) tu_freq
| (@) tu_nobs
| (@) tu_putglobals
| (@) tu_tidyup
| (@) tu_varattr
|-----------------------------------------------------------------------------------------------                                                                             
| Modified By :              Yongwei Wang                                                
| Date of Modification :     28-May-2004                                                
| New Version Number :       1/2                                                
| Modification ID :          YW001                                                
| Reason For Modification :  -Changed %str to %nrstr in POSTSUBSET.                                                
|                            -Unquoted the POSTSUBSET.
|-----------------------------------------------------------------------------------------------                                                                            
| Change Log :                                                               
|                                                                            
| Modified By :                                                              
| Date of Modification :                                                     
| New Version Number :                                                       
| Modification ID :                                                          
| Reason For Modification :                                                  
|
+---------------------------------------------------------------------------------------------*/ 
   
%macro td_eg1( 
   ACROSSVAR           =&g_trtcd,          /* Variable to transpose the data across to make columns of results. This is passed to the proc transpose ID statement */    
   ACROSSVARDECODE     =&g_trtgrp,         /* A variable or format used in the construction of labels for the result columns. Usually &g_trtgrp */                      
   BREAK1              =,                  /* Break statements */                                                                                                       
   BREAK2              =,                  /* Break statements */                                                                                                         
   BREAK3              =,                  /* Break statements */                                                                                                       
   BREAK4              =,                  /* Break statements */                                                                                                       
   BREAK5              =,                  /* Break statements */                                                                                                       
   BYVARS              =,                  /* By variables */                                                                                                           
   CENTREVARS          =,                  /* Centre justify variables */                                                                                               
   CODEDECODEVARPAIRS  =VISITNUM VISIT,    /* Code and Decode variables in pairs */                                                                                     
   COLSPACING          =2,                 /* Value for between-column spacing */                                                                                      
   COLUMNS             =Visitnum visit tt_icat summarylevel tt_intp tt_ac:, /* Columns to be included in the display (plus spanned headers) */                          
   COMPUTEBEFOREPAGELINES=,                /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt : labelvar) */                   
   COMPUTEBEFOREPAGEVARS=,                 /* Names of variables that define the sort order for  Compute Before Page lines */                                          
   COUNTDISTINCTWHATVAR=&g_centid &g_subjid, /* Variable(s) that contain values to be counted uniquely within any output grouping. Eg &g_subjid */                      
   DDDATASETLABEL      =DD dataset for EG1 table, /* Label to be applied to the DD dataset */                                                                           
   DEFAULTWIDTHS       =tt_intp 45,        /* List of default column widths */                                                                                       
   DESCENDING          =,                  /* Descending ORDERVARS */                                                                                                   
   DISPLAY             =Y,                 /* Specifies whether the report should be created */                                                                         
   DSETIN              =ardata.ecg,        /* Input dataset */                                                                                                          
   DSETINDENOM         =&g_popdata,        /* Input dataset containing data to be counted to obtain the denominator. */
   EGBASELINETIMECD    =1,                 /* Baseline value of &EGTIMECDVAR */                                                                                           
   EGCHBLFMT           =$egchbl.,          /* Format of &EGCHBLVAR */                                                                                                  
   EGCHBLVAR           =egchbl,            /* Variable name for Clinical significant change from baseline */                                                            
   EGINTPCDFMT         =$egintpcd.,        /* Format of &EGINTPCDVAR */                                                                                                 
   EGINTPCDVAR         =egintpcd,          /* Variable name for ECG results code */                                                                                     
   EGINTPVAR           =egintp,            /* Variable name for ECG results */                                                                                          
   EGPOSTBASELINETIMECD=999,               /* A post-baseline value for &TIMECDVAR */                                                                                   
   EGPOSTBASELINETIMEDECODE=Any visit post-baseline, /* Decode for &EGPOSTBASELINETIMECD */                                                                             
   EGTIMECDVAR         =visitnum,          /* Variable name representing the coding of time period */                                                                  
   EGTIMEVAR           =visit,             /* Variable name representing time period */                                                                                
   FLOWVARS            =visit tt_intp,     /* Variables with flow option */                                                                                             
   FORMATS             =,                  /* Format specification (valid SAS syntax) */                                                                                
   GROUPBYVARPOP       =&g_trtcd,          /* Variables to group by when counting big N */                                                                              
   GROUPBYVARSDENOM    =&g_trtcd,          /* Variables in DSETINDENOM to group the data by when counting to obtain the denominator. */                                 
   GROUPBYVARSNUMER    =&g_trtcd visitnum tt_icat (tt_intp='n') visit tt_intp, /* Variables in DSETINNUMER to group the data by when counting to obtain the numerator. */ 
   IDVARS              =visit tt_intp,     /* Variables to appear on each page of the report */                                                                         
   LABELS              =,                  /* Label definitions (var=var label) */                                                                                    
   LEFTVARS            =,                  /* Left justify variables */                                                                                
   LINEVARS            =,                  /* Order variables printed with LINE statements */                                                                     
   NOPRINTVARS         =visitnum tt_icat summarylevel, /* No print variables, used to order the display */                                                        
   NOWIDOWVAR          =,                  /* List of variables whose values must be kept together on a page */                                         
   ORDERDATA           =tt_intp,           /* ORDER=DATA variables */                                                                                             
   ORDERFORMATTED      =,                  /* ORDER=FORMATTED variables */                                                                                        
   ORDERFREQ           =,                  /* ORDER=FREQ variables */                                                                                             
   ORDERVARS           =visitnum tt_icat summarylevel tt_intp, /* Order variables */                                                                                      
   OVERALLSUMMARY      =N,                 /* Overall summary line at top of tables */                                                                            
   PAGEVARS            =,                  /* Variables whose change in value causes the display to continue on a new page */                                     
   POSTSUBSET          =%nrstr(if  not (visitnum eq &egbaselinetimecd. and tt_icat eq 'B') ), /* SAS expression to be applied to presentation dataset */  
   PROPTIONS           =Headline,          /* PROC REPORT statement options */                                                                                     
   PSCLASSOPTIONS      =preloadfmt,        /* PROC SUMMARY CLASS Statement Options */                                                                           
   PSFORMAT            =,                  /* Passed to the PROC SUMMARY FORMAT statement. */                                                                   
   PSOPTIONS           =COMPLETETYPES NWAY, /* PROC SUMMARY Options to use */                                                                                   
   RESULTPCTDPS        =0,                 /* The reporting precision for percentages */                                                                        
   RESULTSTYLE         =NUMERPCT,          /* The appearance style of the result columns that will be displayed in the report: */                               
   RIGHTVARS           =,                  /* Right justify variables */                                                                                        
   SHARECOLVARS        =visit tt_intp,     /* Order variables that share print space */                                                                         
   SHARECOLVARSINDENT  =2,                 /* Indentation factor */                                                                                             
   SKIPVARS            =tt_icat,           /* Variables whose change in value causes the display to skip a line */                                              
   SPLITCHAR           =~,                 /* Split character */                                                                                                
   STACKVAR1           =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc= ) ) */  
   STACKVAR2           =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc= ) ) */  
   STACKVAR3           =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc= ) ) */  
   STACKVAR4           =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc= ) ) */  
   STACKVAR5           =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc= ) ) */  
   STACKVAR6           =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc= ) ) */  
   STACKVAR7           =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc= ) ) */  
   STACKVAR8           =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc= ) ) */  
   STACKVAR9           =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc= ) ) */  
   STACKVAR10          =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc= ) ) */  
   STACKVAR11          =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc= ) ) */  
   STACKVAR12          =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc= ) ) */  
   STACKVAR13          =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc= ) ) */  
   STACKVAR14          =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc= ) ) */  
   STACKVAR15          =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc= ) ) */  
   TOTALDECODE         =Total,             /* Label for the total result column. Usually the text Total */                                                      
   TOTALFORVAR         =,                  /* Variable for which a total is required, usually trtcd */                                                          
   TOTALID             =,                  /* Value used to populate the variable specified in TOTALFORVARVAR on data that represents the overall total for the TOTALFORVAR variable. */
   VARLABELSTYLE       =SHORT,             /* Specifies the label style for variables (SHORT or STD) */ 
   VARSPACING          =,                  /* Column spacing for individual variables */                
   WIDTHS              =                   /* Column widths */   
   );
     
   %local MacroVersion;
   %let MacroVersion = 1;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals(varsin=g_dddatasetname g_analy_disp)
   
   /*
   / Initialise local macro variables created within macro
   /-------------------------------------------------------------*/

   %local
      l_declen       /* length of decimal part of numeric valude */
      l_egchblfnd   /* if format &EGCHBLFMT has been found */
      l_egchbltyp   /* type of variable &EGCHBLVAR */
      l_egintpcdfnd  /* if format &INTPCDFMT has been found */
      l_egintpcdtyp  /* type of variable &EGINTPVAR */
      l_fmtlib       /* format libary */
      l_fmtsearch    /* format search path */
      l_hasmissing   /* if has MISSING in &PSOPTIONS */
      l_i            /* loop variable */
      l_intlen       /* length of interger part of numeric valude */
      l_lbllen       /* length of the label variable in  the format data set */
      l_egchblmiss  /* flag for missing values of &EGCHBLVAR */
      l_egintpcdmiss /* flag for missing values &EGINTPCDVAR */      
      l_nfmt         /* format of the numeric variables */
      l_nobs         /* number of observers in &dsetin */
      l_prefix       /* root name for temp data sets */ 
      l_rc           /* return code */
      l_var          /* variable of the loop */
      l_vars         /* list of variables */
      l_vlen         /* length of the new added variable */
      l_workdata     /* current working data set */
      ;      
       
   /* Assign prefix for work datasets */
   
   %let l_prefix = _eg1;      
   %let EGINTPCDFMT=%qscan(&egintpcdfmt., 1, .);
   %let EGCHBLFMT=%qscan(&egchblfmt., 1, .);
   %let l_vars=EGINTPCD EGCHBL;   
   %let l_declen=0;
   %let l_intlen=1;
   %let l_lbllen=1;
   %let l_charlen=1;  
   %let l_vlen=1;   
   %let l_egchblmiss=0;
   %let l_egintpcdmiss=0;   
   %let l_hasmissing=%sysfunc(indexw(%qupcase(&psoptions), MISSING));
         
   /*
   /  IF GD_ANALY_DISPLAY is D, goto display.
   /----------------------------------------------------------------------*/
   
   %IF %nrbquote(&G_ANALY_DISP) = D %THEN %GOTO DISPLAYIT;
            
   /*  
   / Parameter validation:
   / 1. &dsetin exists if not blank.
   / 2. Variable &EGCHBLVAR and &EGINTPCDVAR exist.
   /------------------------------------------------------------*/
   
   %if %nrbquote(&dsetin) eq %then 
   %do;
      %put %str(RTERR)OR: &sysmacroname: the required parameter DSETIN is blank.;
      %goto macerr;  
   %end;
   
   %let l_rc=%tu_nobs(&DSETIN);
   %if &g_abort GT 0 %then %goto macerr;
   
   %if &l_rc EQ -1 %then 
   %do;
      %put %str(RTERR)OR: &sysmacroname: input data set "&dsetin" does not exist;
      %goto macerr;
   %end;
   
   %if ( %nrbquote(&EGCHBLVAR) ne ) or ( %nrbquote(&EGINTPCDVAR) ne ) or ( %nrbquote(&EGINTPVAR) ne )
   %then 
   %do;
      %let l_rc=%tu_chkvarsexist(&dsetin, &EGCHBLVAR &EGINTPCDVAR &EGINTPVAR);
      %if &g_abort EQ 1 %then %goto macerr;
     
      %if %str(X&l_rc) NE X %then 
      %do;
         %put %str(RTERR)OR: &sysmacroname: Variable &l_rc, given by EGCHBLVAR, EGINTPVAR or/and EGINTPCDVAR, is/are not in data set &DSETIN.;
         %goto macerr;
      %end;                                   
   %end;  %*** end of if on EGCHBLVAR or EGINTPCDVAR or EGINTPVAR is not blank ***;      
   
   /*
   / If &egpostbaselinetimecd is given, the &egtimecdvar, &egtimevar
   / &egbaselinetimecd and &posebaselinetimedecode must not be
   / blank, and &egtimecdvar and &egtimevar must exist in the &dsetin.
   / &egtimecdvar must be a numeric variable.
   / &egbaselinetimecd and &posebaselinetimedecode must be a numer.
   / ------------------------------------------------------------*/
     
   %if %nrbquote(&egpostbaselinetimecd) ne %then 
   %do;
   
      %if %nrbquote(&egtimevar) eq %then 
      %do;
         %put %str(RTERR)OR: &sysmacroname: egpostbaselinetimecd is not blank and thus parameter egtimevar is required, but it is blank.;
         %goto macerr;  
      %end;
      %if %nrbquote(&egtimecdvar) eq %then 
      %do;
         %put %str(RTERR)OR: &sysmacroname: egpostbaselinetimecd is not blank and thus parameter egtimecdvar is required, but it is blank.;
         %goto macerr;  
      %end;     
      %if %nrbquote(&egpostbaselinetimedecode) eq %then 
      %do;
         %put %str(RTERR)OR: &sysmacroname: egpostbaselinetimecd is not blank and thus parameter egpostbaselinetimedecode is required, but it is blank.;
         %goto macerr;  
      %end;
      
      %let l_rc=%tu_chkvarsexist(&dsetin, &egtimevar &egtimecdvar);
      %if &g_abort EQ 1 %then %goto macerr;
     
      %if %str(X&l_rc) NE X %then 
      %do;
         %put %str(RTERR)OR: &sysmacroname: egpostbaselinetimecd is not blank, but variable &l_rc, given by egtimevar and/or egtimecdvar, is/are not in data set &DSETIN.;
         %goto macerr;
      %end;       
      
      %if %tu_varattr(&dsetin, &egtimecdvar, VARTYPE) NE N %then 
      %do;
         %PUT %str(RTERR)OR: &sysmacroname: egpostbaselinetimecd is not blank, but variable &egtimecdvar given by egtimecdvar must be a numeric variable.;
         %GOTO macerr;
      %end;
      
      %let l_rc=0;            
      
      %*** egpostbaselinetimecd and egbaselinetimecd must be number. ***;            
      data _null_;
         a=&egpostbaselinetimecd * 1;
         if a eq . then 
         do;      
             call symput('l_rc', '1');
             put "RTERR" "OR: &sysmacroname: egpostbaselinetimecd is not blank, but value of egpostbaselinetimecd is not a number and it is required";
             stop;
         end;
         a=&egbaselinetimecd * 1;
         if a eq . then 
         do;         
             call symput('l_rc', '1');
             put "RTERR" "OR: &sysmacroname: egpostbaselinetimecd is not blank, but value of egpostbaselinetimecd is not a number and it is required";
             stop;
         end;        
      run;   
         
      %if &l_rc eq 1 %then %goto macerr;  
       
   %end; %*** end-if on egpostbaselinetimecd is not blank ***;     
                                                                       
   /*
   / Search format &egchblfmt and &egintpcdfmt in the path given 
   / by SAS option FMTSEARCH
   /------------------------------------------------------------*/
   
   %if ((%nrbquote(&EGINTPCDVAR) ne) and (%nrbquote(&EGINTPCDFMT) ne)) or 
       ((%nrbquote(&EGCHBLVAR) ne) and (%nrbquote(&EGCHBLFMT) ne)) 
   %then 
   %do;
   
      %let l_egintpcdfnd=0;
      %let l_egchblfnd=0;      
      
      %*** get the format search path ***;            
      %let l_fmtsearch=%scan(%sysfunc(getoption(FMTSEARCH)), 1, %str(%(%)));
      %if %sysfunc(indexw(%qupcase(&l_fmtsearch), LIBRARY)) eq 0 %then
         %let l_fmtsearch=LIBRARY &l_fmtsearch;
      %if %sysfunc(indexw(%qupcase(&l_fmtsearch), WORK)) eq 0 %then
         %let l_fmtsearch=WORK &l_fmtsearch;      
      
      %let l_i=1;                                        
      %let l_fmtlib=%scan(&l_fmtsearch, &l_i, %str( ,));
     
      %do %while (%nrbquote(&l_fmtlib) ne );
         %if %index(&l_fmtlib, .) eq 0 %then %let l_fmtlib=&l_fmtlib..formats;
         
         %if %sysfunc(exist(&l_fmtlib, CATALOG)) %then 
         %do; 
         
            %if (%nrbquote(&EGINTPCDFMT) ne) and (&l_egintpcdfnd eq 0) 
                and (%nrbquote(&EGINTPCDVAR) ne) %then 
                %do;
               proc format library=&l_fmtlib cntlout=&l_prefix.fmt1 ;
                  select &EGINTPCDFMT;
               run;               
               %if %tu_nobs(&l_prefix.fmt1) gt 0 %then 
               %do;
                  %let l_egintpcdfnd=1;
               %end;
            %end; %*** end of if on EGINTPCDFMT ***;
            
            %if (%nrbquote(&EGCHBLFMT) ne) and (&l_egchblfnd eq 0)
                and (%nrbquote(&EGCHBLVAR) ne) %then 
                %do;
               proc format library=&l_fmtlib cntlout=&l_prefix.fmt2 ;
                  select &EGCHBLFMT;
               run;            
               %if %tu_nobs(&l_prefix.fmt2) gt 0 %then 
               %do;
                  %let l_egchblfnd=1;
               %end;
            %end; %*** end of if on EGCHBLFMT ***;
         %end; %*** end of if on exist of l_fmtlib ***;
         
         %let l_i=%eval(&l_i + 1);                                              
         %let l_fmtlib=%scan(&l_fmtsearch, &l_i, %str( ,));          
      %end; %*** end do-while loop ***;
   
   %end; %*** end if on EGINTPCDFMT and EGCHBLFMT not blank ***;
   
   /*
   /  Check if formats have been found.
   /-------------------------------------------------------------*/
                   
   %do l_i=1 %to 2;
      %let l_var=%scan(&l_vars, &l_i);
  
      %if (%nrbquote(&&&l_var.VAR) ne) and (%nrbquote(&&&l_var.FMT) ne) %then 
      %do;
         %if &&l_&l_var.fnd eq 0 %then 
         %do;
            %put RTERR%str(OR): &sysmacroname: Can not find format &&&l_var.FMT given by &l_var.FMT;   
            %goto macerr;
         %end;
         
         data _null_;
            set &l_prefix.fmt&l_i ;
            length tt_text $1000;
            retain tt_dec &l_declen tt_int &l_intlen;
            type=upcase(type);
            
            if _n_=1 then 
            do;
               call symput("l_&l_var.typ", trim(left(type)));               
               call symput('l_lbllen', compress(vlength(label)));
            end;
            
            if type ne 'N' then stop;
            
            tt_text=compress(start);
            tt_int=max(tt_int, length(scan(tt_text, 1, '.')));
            tt_dec=max(tt_dec, length(scan(tt_text, 2, '.')));
            if end then 
            do;
               call symput('l_declen', compress(tt_dec));
               call symput('l_intlen', compress(tt_int));
            end;
            
         run;
      %end; %*** end of if on l_var.VAR and l_var.FMT are not blank ***;
      
   %end; %*** end of do-to loop ***;
          
   /* 
   / Create a format to define the category to contain ECG finding 
   / (A) and change from baseline (B) and add the format to 
   / &PSFORMAT so that the category will display in all time 
   / periods.
   /-----------------------------------------------------------*/
     
   %if (%nrbquote(&EGINTPCDVAR) ne) and (%nrbquote(&EGCHBLVAR) ne) %then %do;
      proc format ;    
         value $tt_icat
         'A'='A'
         'B'='B'
         ;
      run; 
        
      %let PSFORMAT= tt_icat $tt_icat. &psformat;
   %end; %*** end of if on EGINTPCDVAR and EGCHBLVAR are not blank ***;
   
   %let l_workdata=&dsetin; 
   
   /*
   / If EGSEQ is in &DSETIN, keep only data with EGSEQ=1;
   /------------------------------------------------------------*/
   
   %IF %tu_chkvarsexist(&DSETIN, EGSEQ) EQ %THEN %DO;
      data &l_prefix.din;
         set &DSETIN;
         where egseq EQ 1;
      run;
      %let l_workdata=&l_prefix.din;
   %END;        
   
   /*
   /  Add post-baseline visit to the data set;            
   /------------------------------------------------------------*/
   
   %if %nrbquote(&egpostbaselinetimecd) ne %then 
   %do;
   
      data _null_;
         if 0 then set &l_workdata; 
         a=max(vlength(&egtimevar), length(symget('egpostbaselinetimedecode')));
         call symput('l_i', compress(a));
         stop;
      run;
         
      data &l_prefix.in;
         length &egtimevar $&l_i.;
         set &l_workdata;         
         output;
         
         if &egtimecdvar gt &egbaselinetimecd then 
         do;
            &egtimecdvar=symget('egpostbaselinetimecd');
            &egtimevar=symget('egpostbaselinetimedecode');
            output;
         end;
      run;
      
      %let l_workdata=&l_prefix.in;
   %end;  %*** end of if on &egpostbaselinetimecd is not blank ***;                                 
   
   %if (%nrbquote(&EGINTPCDVAR) ne ) or ( %nrbquote(&EGCHBLVAR) ne ) %then 
   %do;  
  
   /*
   / Check if the type of variable &EGCHINTPVAR and &EGCHBLVAR
   / match the type given by the format. If any of them is 
   / numeric variable, create a format so that the converted 
   / character value can keep the sorting order.
   /------------------------------------------------------------*/
   
      %let l_rc=0;   
      
      data _null_;
         set &l_workdata end=end;
         length tt_text $1000;
         retain tt_dec &l_declen tt_int &l_intlen tt_char &l_charlen ;
              
         %if  %nrbquote(&EGINTPVAR) ne %then 
         %do;
            if _n_ eq 1 then 
            do;
               call symput('l_lbllen', compress(max(vlength(&EGINTPVAR), &l_lbllen)));
            end;
         %end; 
                            
         %do l_i=1 %to 2;
            %let l_var=%scan(&l_vars, &l_i);
            
            %if %nrbquote(&&&l_var.var) ne %then 
            %do;
               if _n_ eq 1 then 
               do;              
                  if upcase(vtype(&&&l_var.var)) ne "&&l_&l_var.typ." then 
                  do;
                     call symput('l_rc', '1');
                     put "RTERR" "OR: &sysmacroname: format &&&l_var.FMT does not match the type of variable &&&l_var.VAR";
                     stop;
                  end;
               end;
               
               if vtype(&&&l_var.var) eq 'N' then 
               do;
                  tt_text=compress(&&&l_var.var);
                  tt_int=max(tt_int, length(scan(tt_text, 1,'.')));
                  tt_dec=max(tt_dec, length(scan(tt_text, 2,'.')));
                  tt_char=max(tt_char, vlength(&&&l_var.var));
               end;
               
            %end; %*** end of if on l_var is not blank ***;
            
         %end;  %*** end of do-to loop ***;                              
         
         if end then 
         do;
            tt_int=tt_int + tt_dec + 1;
            call symput('l_nfmt', compress("Z"||tt_int||"."||tt_dec));         
            tt_int=max(tt_char + 2, tt_int + 2);
            call symput('l_vlen', compress(tt_int));          
         end;
         
      run;
   
      %if &l_rc eq 1 %then %goto macerr;   
              
   /*
   / Transpose &EGCHBLVAR and &EGINTPCDVAR into character 
   / variable tt_intp, if not all of them are blank. The new 
   / variable tt_icat will be created to mark which variable does
   / the tt_intp come from.
   /------------------------------------------------------------*/
     
      data &l_prefix.eg1;
         length tt_intp $&l_vlen;      
         set &l_workdata end=end;
         label tt_intp="&splitchar";
                           
         %if %nrbquote(&EGINTPCDVAR) ne %then 
         %do;
                 
            %if &l_egintpcdtyp eq N %then 
            %do;
               if not missing(&EGINTPCDVAR) then 
                  tt_intp='A_'||left(put(&EGINTPCDVAR, &l_nfmt));
            %end;            
            %else 
            %do;
               if not missing(&EGINTPCDVAR) then 
                  tt_intp='A_'||left(&EGINTPCDVAR);
            %end;
            %if &l_hasmissing gt 0 %then 
            %do;
               else 
               do;               
                  tt_intp='Az';      
                  call symput('l_egintpcdmiss', '1');            
               end;
            %end;
                 
            tt_icat='A'; 
            %if &l_hasmissing le 0 %then 
            %do;
               if not missing(&EGINTPCDVAR) then
            %end;
            output;
            
         %end; %*** end-if on EGINTPCDVAR not blank ***;
         
         %if %nrbquote(&EGCHBLVAR) ne %then 
         %do;
              
            %if &l_egchbltyp eq N %then 
            %do;
               if not missing(&EGCHBLVAR) then 
                  tt_intp='B_'||left(put(&EGCHBLVAR, &l_nfmt));
            %end;
            %else 
            %do;
               if not missing(&EGCHBLVAR) then 
               do;
                  if upcase(&EGCHBLVAR) in ('X', 'N', 'NO') then 
                     &EGCHBLVAR=lowcase(&EGCHBLVAR);
                  if upcase(&EGCHBLVAR) in ('Y', 'YES') then 
                     &EGCHBLVAR=upcase(&EGCHBLVAR);
                     
                  tt_intp='B_'||left(&EGCHBLVAR);                    
               end;
            %end;
            %if  &l_hasmissing gt 0 %then 
            %do;
               else 
               do;
                  tt_intp='Bz';
                  call symput('l_egchblmiss', '1'); 
               end;
            %end;
                                              
            tt_icat='B';       
            %if &l_hasmissing le 0 %then 
            %do;
               if not missing(&EGCHBLVAR) then
            %end;           
            output;
            
         %end;  %*** end-if on EGCHBLVAR not blank ***;    
      run;           
      
      %if &l_rc eq 1 %then %goto macerr;  
   
   /*
   /  Add a if statement to the POSTSUBSET to remove the 
   /  categories created by the COMPLETETYPE in PSCLASSOPTIONS.
   /-------------------------------------------------------------*/   
   
      %let l_rc=0;
         
      data _null_;
         length groupbyvarsnumer $32761;
         groupbyvarsnumer=upcase(symget('groupbyvarsnumer'));
         if ( indexw(groupbyvarsnumer, 'TT_ICAT') gt 0 ) and
            ( indexw(groupbyvarsnumer, 'TT_INTP') gt 0 )
         then
            call symput('l_rc', '1');
      run;
         
      %if &l_rc eq 1 %then 
      %do;
         %let postsubset=&postsubset %str(; if (tt_icat ne 'B' or substr(tt_intp, 1, 1) ne 'A' ) and (tt_icat ne 'A' or substr(tt_intp, 1, 1) ne 'B' ) ) ; 
      %end;
      
      %let l_workdata=&l_prefix.eg1;       
      
   /*
   / If &EGINTPVAR is not blank create format from it and combine
   / it with format &egintcdfmt if &egintcdfmt is not blank.
   /-------------------------------------------------------------*/
   
      %if (%nrbquote(&EGINTPCDVAR) ne ) or ( %nrbquote(&EGINTPVAR) ne ) %then 
      %do;
         proc freq data=&l_workdata ;
            table &EGINTPCDVAR * &EGINTPVAR /list noprint 
               out=&l_prefix.fmt3(keep=&EGINTPCDVAR &EGINTPVAR);                           
         run;
         
         data &l_prefix.fmt4;
            set &l_prefix.fmt3;
            where &EGINTPCDVAR is not null and &EGINTPVAR is not null;
            length tt_egintpcd tt_egintp $100;  
            keep  tt_egintpcd tt_egintp;        
            tt_egintpcd=trim(left(&EGINTPCDVAR));
            tt_egintp=trim(left(&EGINTPVAR));
         run;

         %if &l_egintpcdfnd eq 1 %then 
         %do;
            proc sql;
               create table &l_prefix.fmt5 as
               select a.*, b.tt_egintpcd, b.tt_egintp
               from &l_prefix.fmt1 a full join &l_prefix.fmt4 b               
               on upcase(trim(left(a.start))) eq upcase(trim(left(b.tt_egintpcd)))
               ;
            quit;
            
            data &l_prefix.fmt1;
               length label $&l_lbllen.;
               set &l_prefix.fmt5;
               drop tt_egintpcd tt_egintp;
               if compress(start) eq '' then 
               do;
                  start=tt_egintpcd;
                  label=tt_egintp;
                  fmtname=compress(upcase("&EGINTPVAR"));
                  type=compress(upcase("&l_egintpcdtyp"));
               end;
            run;   
            
         %end; %*** end-if on &l_egintpcdfnd eq 1 ***;         
         
         %let l_egintpcdfnd=1;
          
      %end; %*** end-if on &EGINTPCDVAR and &EGINTPVAR not blank ***;
      
   %end; %*** end-if on &EGINTPCDVAR and &EGCHBLVAR not blank ***;
         
   /*
   / Combine the format of &EGCHBLFMT and &EGINTPCDFMT into one
   / format if not all of them are blank.
   /------------------------------------------------------------*/
   
   %if (&l_egintpcdfnd eq 1) or (&l_egchblfnd eq 1) %then 
   %do;
         
      data &l_prefix.fmt;
         length label $&l_lbllen. tt_pre $2 start $200;
         set 
            %if &l_egintpcdfnd eq 1 %then 
            %do;
               &l_prefix.fmt1(in=a)
            %end;
            %if &l_egchblfnd eq 1 %then 
            %do;
               &l_prefix.fmt2(in=b)
            %end;   
            end=tt_end;
            ;
         retain missflag1 missflag2 0;
         keep label start fmtname type;
         
         if a then
            tt_pre='A_';
         else 
            tt_pre='B_';
         
         fmtname='$tt_intp';       
         
         if compress(upcase(start)) ne '**OTHER**' then 
         do;                    
            if upcase(type) eq 'N' then 
            do;
               start1=start * 1;                 
               start=compress(tt_pre)||left(put(start1, &l_nfmt));                  
            end;
            else 
            do;
               if (not a) and (upcase(start) in ('X', 'N', 'NO')) then 
                  start=lowcase(start);
               if (not a) and (upcase(start) in ('Y', 'YES')) then 
                  start=upcase(start);
              
               start=compress(tt_pre)||left(start);
            end;
         end; 
         
         %if &l_hasmissing gt 0 %then 
         %do;         
            else 
            do;
               start=compress(substr(tt_pre, 1, 1))||'z';
               if a then missflag1=1;
               else missflag2=1;
            end; %*** end-if on start is missing ***;         
         %end;
         
         type='C';          
         output;       
         
         %if &l_egintpcdmiss eq 1 %then 
         %do;
            if  tt_end and (missflag1 eq 0) then 
            do;
               start='Az'; 
               label='Missing';
               type='C';
               output;
            end;
         %end;
         %if &l_egchblmiss eq 1 %then 
         %do;
            if tt_end and (missflag2 eq 0) then 
            do;
               start='Bz'; 
               label='MISSING';
               type='C';
               output;
            end;
         %end;                                   
                   
      run;
      
      proc format cntlin=&l_prefix.fmt;
      run;        
      
   /*
   / Add format $tt_intp. tt_intp and add the format to &PSFORMAT
   /------------------------------------------------------------*/     
         
      data &l_prefix.eg2;
         set &l_prefix.eg1;
         format tt_intp $tt_intp.;
      run;
            
      %let l_workdata=&l_prefix.eg2;
      %let PSFORMAT=tt_intp $tt_intp. &psformat;
   %end; %*** end of if on l_egintpcdfnd or l_egchblfnd equals 1 ***;
         
   %let postsubset=%unquote(&postsubset);   /* YW001 */
   
%DISPLAYIT:    
   
   /*
   / Call tu_freq to create output.
   /------------------------------------------------------------*/
   
   %tu_freq (
      acrossColListName       =acrossColList,
      acrossColVarPrefix      =tt_ac,
      acrossVar               =&acrossVar,
      acrossVarDecode         =&acrossVarDecode,
      addBigNYN               =Y,
      BigNVarName             =tt_bnnm,
      break1                  =&break1,
      break2                  =&break2,
      break3                  =&break3,
      break4                  =&break4,
      break5                  =&break5,
      byvars                  =&byVars,
      centrevars              =&centreVars,
      codeDecodeVarPairs      =&codeDecodeVarPairs,
      colspacing              =&colSpacing,
      columns                 =&columns,
      computebeforepagelines  =&computeBeforePageLines,
      computebeforepagevars   =&computeBeforePageVars,
      countDistinctWhatVar    =&countDistinctWhatVar,
      dddatasetlabel          =&dddatasetlabel,
      defaultwidths           =&defaultWidths,
      denormYN                =Y,
      descending              =&descending,
      display                 =&display,
      dsetinDenom             =&dsetinDenom,
      dsetinNumer             =&l_workdata,
      dsetout                 =,
      flowvars                =&flowVars,
      formats                 =&formats,
      groupByVarPop           =&groupByVarPop,
      groupByVarsDenom        =&groupByVarsDenom,
      groupByVarsNumer        =&groupByVarsNumer,
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
      overallsummary          =&overallsummary,
      pagevars                =&pageVars,
      postSubset              =&postSubset,
      proptions               =&proptions,
      psByvars                =,
      psClass                 =,
      psClassOptions          =&psclassoptions,
      psFormat                =&psformat,
      psFreq                  =,
      psid                    =,
      psOptions               =&psoptions,
      psOutput                =,
      psOutputOptions         =,
      psTypes                 =,
      psWays                  =,
      psWeight                =,
      remSummaryPctYN         =N,
      resultPctDps            =&resultPctDps,
      resultStyle             =&resultStyle,
      resultVarName           =tt_result,
      rightVars               =&rightVars,
      rowLabelVarName         =,
      sharecolvars            =&sharecolvars,
      sharecolvarsindent      =&sharecolvarsindent,
      skipvars                =&skipVars,
      splitChar               =&splitChar,
      spSortGroupByVarsDenom  =,
      spSortGroupByVarsNumer  =,
      spSortResultStyle       =,
      spSortResultVarName     =,
      stackvar1               =&stackvar1,      
      stackvar2               =&stackvar2,
      stackvar3               =&stackvar3,
      stackvar4               =&stackvar4,
      stackvar5               =&stackvar5,
      stackvar6               =&stackvar6,
      stackvar7               =&stackvar7,
      stackvar8               =&stackvar8,
      stackvar9               =&stackvar9,
      stackvar10              =&stackvar10,
      stackvar11              =&stackvar11,
      stackvar12              =&stackvar12,
      stackvar13              =&stackvar13,     
      stackvar14              =&stackvar14,
      stackvar15              =&stackvar15,    
      summaryLevelVarName     =summaryLevel,
      totalDecode             =&totalDecode,
      totalForVar             =&totalForVar,
      totalID                 =&totalID,
      varlabelstyle           =SHORT,
      varspacing              =&varSpacing,
      varsToDenorm            =tt_result tt_pct,
      widths                  =&widths
      )              
      
   %goto endmac; 

%MACERR:
   /*
   / Error occured, call tu_abort and set g_abort.
   /------------------------------------------------------------*/
   
   %let g_abort=1;
   %tu_abort(option=force);
  
%ENDMAC:    
   /*
   / Call tu_tidyup to remove the temporary data sets.
   /------------------------------------------------------------*/
   
   %tu_tidyup(
      rmdset=&l_prefix:, 
      glbmac=none
      );
      
%mend td_eg1;  
   
         
                                                    

