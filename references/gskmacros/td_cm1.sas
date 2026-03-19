/*----------------------------------------------------------------------------------------
|
| Macro Name:         td_cm1
|                    
| Macro Version:      2
|                    
| SAS Version:        8
|                    
| Created By:         John Henry King
|                    
| Date:               01OCT2003
|
| Macro Purpose:      A macro to create Concomidant Medication Summary CM1.
|
| Macro Design:       Procedure style.
|
| Input Parameters:
|
| Name                Description                                       Default           
| ----------------------------------------------------------------------------------------
| ACROSSVAR           Variable to transpose the data across to make     &g_trtcd          
|                     columns of results. This is passed to the proc                      
|                     transpose ID statement hence the values of this                     
|                     variable will be used to name the new columns.                      
|                     Typically this will be the code variable                            
|                     containing treatment.                                               
|                     Valid Values:                                                       
|                     Blank                                                               
|                     Name of a SAS variable that exists in                               
|                     DSETINNUMER                                                         
|                                                                                         
| ACROSSVARDECODE     A variable or format used in the construction of  &g_trtgrp         
|                     labels for the result columns.                                      
|                     Valid values:                                                       
|                     If DENORMYN is not Y, blank                                         
|                     Otherwise:                                                          
|                     Blank                                                               
|                     Name of a SAS variable that exists in                               
|                     DSETINNUMER                                                         
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
|                     processed as standard SAS by variables                              
|                     Valid values: one or more SAS variable names                        
|                     No formatting of the display for these variables                    
|                     is performed by %tu_display.  The user has the                      
|                     option of the standard SAS BY line, or using                        
|                     OPTIONS NOBYLINE and #BYVAL #BYVAR directives in                    
|                     title statements                                                    
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
| CODEDECODEVARPAIRS  Specifies code and decode variable pairs. Those   (Blank)           
|                     variables should be in parameter                                    
|                     GROUPBYVARSNUMER. One variable in the pair will                     
|                     contain the code and the other will contain                         
|                     decode.                                                             
|                     Valid values:  Blank or a list of SAS variable                      
|                     names in pairs that are given in                                    
|                     GROUPBYVARSNUMER                                                    
|                                                                                         
| COLSPACING          The value of the between-column spacing           2                 
|                     Valid values: positive integer                                      
|                                                                                         
| COLUMNS             A PROC REPORT column statement specification.     tt_spsort cmatc1  
|                     Including spanning titles and variable names      summaryLevel      
|                     Valid values: one or more variable names plus     tt_pct999 cmcomp  
|                     other elements of valid PROC REPORT COLUMN        tt_ac:            
|                     statement syntax                                                    
|                                                                                         
| COMPLETETYPESVARS   Specify a list of variables which are in          &g_trtcd          
|                     GROUPBYVARSNUMER and the COMPLETETYPES given by                     
|                     PSOPTIONS should be applied to. If it equals                        
|                     _ALL_, all variables in GROUPBYVARSNUMER will be                    
|                     included.                                                           
|                     Valid Values:                                                       
|                     _ALL_                                                               
|                     A list of variable names which are in                               
|                     GROUPBYVARSNUMER                                                    
|                                                                                         
| COMPUTEBEFOREPAGEL  See Unit Specification for HARP Reporting Tools   (Blank)           
| INES                TU_LIST[5] for complete details                                     
|                                                                                         
| COMPUTEBEFOREPAGEV  See Unit Specification for HARP Reporting Tools   (Blank)           
| ARS                 TU_LIST[5] for complete details                                     
|                                                                                         
| COUNTDISTINCTWHATV  Variable(s) that contain values to be counted     &g_centid         
| AR                  uniquely within any output grouping.              &g_subjid         
|                     Valid values:                                                       
|                     Blank                                                               
|                     Name of one or more SAS variables that exists in                    
|                     DSETINNUMER                                                         
|                                                                                         
| DDDATASETLABEL      Specifies the label to be applied to the DD       DD dataset for    
|                     dataset                                           CM1 table         
|                     Valid values: a non-blank text string                               
|                                                                                         
| DEFAULTWIDTHS       Specifies column widths for all variables not     cmatc1 40 cmcomp  
|                     listed in the WIDTHS parameter                    40 tt_ac: 12      
|                     Valid values: values of column names and numeric                    
|                     widths such as form valid syntax for a SAS                          
|                     LENGTH statement                                                    
|                     For variables that are not given widths through                     
|                     either the WIDTHS or DEFAULTWIDTHS parameter                        
|                     will be width optimised using:                                      
|                     MAX (variables format width,                                       
|                     width of  column header)                                            
|                                                                                         
| DESCENDING          List of ORDERVARS that are given the PROC REPORT  tt_spsort         
|                     define statement attribute DESCENDING             tt_pct999         
|                     Valid values: one or more variable names that                       
|                     are also defined with ORDERVARS                                     
|                                                                                         
| DSETINDENOM         Input dataset containing data to be counted to    &g_popdata        
|                     obtain the denominator. This may or may not be                      
|                     the same as the dataset specified to                                
|                     DSETINNUMER.                                                        
|                     Valid values:                                                       
|                     &g_popdata                                                          
|                     any other valid SAS dataset reference                               
|                                                                                         
| DSETINNUMER         Input dataset containing data to be counted to    ardata.cmanal(wher
|                     obtain the numerator.                             e=(display1 eq 1))
|                                                                                         
|                     Valid Values:                                                       
|                                                                                         
|                     Valid sas dataset name                                              
|                                                                                         
| FLOWVARS            Variables to be defined with the flow option      cmcomp cmatc1 
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
|                     %tu_addbignvar. See Unit Specification for HARP                     
|                     Reporting Tools TU_ADDBIGNVAR[7]                                    
|                     Required if ADDBIGNYN =Y                                            
|                     Valid values:                                                       
|                     Blank if ADDBIGNYN=N                                                
|                     Otherwise, a list of valid SAS variable names                       
|                     that exist in population dataset created by                         
|                     %tu_freq's calling %tu_getdata                                      
|                                                                                         
| GROUPBYVARSDENOM    Variables in DSETINDENOM to group the data by     &g_trtcd          
|                     when counting to obtain the denominator.                            
|                     Valid values:                                                       
|                     Blank, _NONE_ (to request an overall total for                      
|                     the whole dataset)                                                  
|                     Name of a SAS variable that exists in                               
|                     DSETINDENOM                                                         
|                                                                                         
| GROUPBYVARSNUMER    Variables in DSETINNUMER to group the data by,    &g_trtcd          
|                     along with ACROSSVAR, when counting to obtain     (cmatc1='DUMMY'   
|                     the numerator. Additionally a set of brackets     %nrstr(&sc)       
|                     may be inserted within the variables to generate  cmcomp= 'Any      
|                     records containing summary counts grouped by      medication')      
|                     variables specified to the left of the brackets.  cmatc1 (cmcomp=   
|                     Summary records created may be populated with     'Any medication') 
|                     values in the grouping variables by specifying    cmcomp            
|                     variable value pairs within brackets, seperated                     
|                     by semi colons. eg aesoccd aesoc(aeptcd=0;                          
|                     aept="Any Event";) aeptcd aept.                                     
|                     Valid values:                                                       
|                     Blank                                                               
|                     Name of one or more SAS variables that exist in                     
|                     DSETINNUMER                                                         
|                     SAS assignment statements within brackets                           
|                                                                                         
| IDVARS              Variables to appear on each page if the report                      
|                     is wider than 1 page. If no value is supplied to                    
|                     this parameter then all displayable order                           
|                     variables will be defined as IDVARS                                 
|                     Valid values: one or more variable names that                       
|                     are also defined with COLUMNS                                       
|                                                                                         
| LABELS              Variables and their label for display. For use    cmcomp='ATC Level 
|                     where label for display differs to the label the  1~   Ingredient    
|                     display dataset.                                  Term'             
|                     Valid values: pairs of variable names and labels                    
|                                                                                         
| LEFTVARS            Variables to be displayed as left justified       (Blank)           
|                     Valid values: one or more variable names that                       
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
| NOPRINTVARS         Variables listed in the COLUMN parameter that     tt_spsort         
|                     are given the PROC REPORT define statement        tt_ac999          
|                     attribute noprint                                 summaryLevel      
|                     Valid values: one or more variable names that     tt_pct999         
|                     are also defined with COLUMNS                                       
|                     These variables are ORDERVARS used to control                       
|                     the order of the rows in the display                                
|                                                                                         
| NOWIDOWVAR          Variable whose values must be kept together on a  (Blank)           
|                     page                                                                
|                     Valid values: names of one or more variables                        
|                     specified in COLUMNS                                                
|                                                                                         
| ORDERDATA           Variables listed in the ORDERVARS parameter that  (Blank)           
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
|                     Valid values: one or more variable names  that                      
|                     are also defined with ORDERVARS                                     
|                     Variables not listed in ORDERFORMATTED,                             
|                     ORDERFREQ, or ORDERDATA are given the define                        
|                     attribute order=internal                                            
|                                                                                         
| ORDERVARS           List of variables that will receive the PROC      tt_spsort cmatc1  
|                     REPORT define statement attribute ORDER           summaryLevel      
|                     Valid values: one or more variable names that     tt_pct999 cmcomp  
|                     are also defined with COLUMNS                                       
|                                                                                         
| PAGEVARS            Variables whose change in value causes the        (Blank)           
|                     display to continue on a new page                                   
|                     Valid values: one or more variable names that                       
|                     are also defined with COLUMNS                                       
|                                                                                         
| POSTSUBSET          SAS expression to be applied to data immediately  if tt_pct999 gt 0 
|                     prior to creation of the permanent presentation                     
|                     dataset. Used for subsetting records required                       
|                     for computation but not for display.                                
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
| PSFORMAT            Passed to the PROC SUMMARY FORMAT statement.      &g_trtcd &g_trtfmt
|                     Valid Values:                                                       
|                     Blank                                                               
|                     Valid PROC SUMMARY FORMAT statement part                            
|                                                                                         
| PSOPTIONS           PROC SUMMARY Options to use. MISSING ensures      COMPLETETYPES     
|                     that class variables with missing values are      MISSING NWAY      
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
|                     Valid values: one or more variable names that                       
|                     are also defined with COLUMNS                                       
|                                                                                         
| SHARECOLVARS        List of variables that will share print space.    cmatc1 cmcomp     
|                     The attributes of the last variable in the list                     
|                     define the column width and flow options                            
|                     Valid values: one or more SAS variable names                        
|                     AE5 shows an example of this style of output                        
|                     The formatted values of the variables shall be                      
|                     written above each other in one column                              
|                                                                                         
| SHARECOLVARSINDENT  Indentation factor for ShareColVars. Stacked      2                 
|                     values shall be progressively indented by                           
|                     multiples of ShareColVarsIndent                                     
|                     Valid values: positive integer                                      
|                                                                                         
| SKIPVARS            Variables whose change in value causes the        cmatc1            
|                     display to skip a line                                              
|                     Valid values: one or more variable names that                       
|                     are also defined with COLUMNS                                       
|                                                                                         
| SPLITCHAR           The split character used in column labels. Used   ~                 
|                     in the creation of the label for the result                         
|                     columns, and in %tu_stackvar, %tu_display (PROC                     
|                     REPORT). Usually ~                                                  
|                     Valid values:                                                       
|                     Valid SAS split character.                                          
|                                                                                         
| SPSORTGROUPBYVARSD  Special sort: variables in DSETINDENOM to group   (Blank)              
| ENOM                the data by when counting to obtain the                             
|                     denominator.                                                        
|                     Valid values:                                                       
|                     Blank if SPSORTRESULTVARNAME is blank                               
|                     Otherwise,                                                          
|                     Blank                                                               
|                     _NONE_                                                              
|                     Name of a SAS variable that exists in                               
|                     DSETINDENOM                                                         
|                                                                                         
| SPSORTGROUPBYVARSN  Special sort: variables in DSETINNUMER to group   cmatc1            
| UMER                the data by when counting to obtain the                             
|                     numerator.                                                          
|                     Valid values:                                                       
|                     Blank if SPSORTRESULTVARNAME is blank                               
|                     Otherwise,                                                          
|                     Name of one or more SAS variables that exist in                     
|                     DSETINNUMER                                                         
|                                                                                         
| SPSORTRESULTSTYLE   Special sort: the appearance style of the result  PCT               
|                     data that will be used to sequence the report.                      
|                     The chosen style will be placed in variable                         
|                     SPSORTRESULTVARNAME                                                 
|                     Valid values:                                                       
|                     As documented for tu_percent in [6]. In typical                     
|                     usage, NUMERPCT.                                                    
|                                                                                         
| TOTALDECODE         Label for the total result column. Usually the    Total             
|                     text Total                                                          
|                     Valid values:                                                       
|                     Blank                                                               
|                     SAS data step expression resolving to a                             
|                     character.                                                          
|                                                                                         
| TOTALFORVAR         Variable for which total is required within all   &g_trtcd          
|                     other grouped classvars (usually trtcd). If not                     
|                     specified, no total will be produced                                
|                     Valid values: Blank if TOTALID is blank.                            
|                                                                                         
| TOTALID             Value used to populate the variable specified in  999               
|                     ACROSSVAR on data that represents the overall                       
|                     total for the ACROSSVAR variable.                                   
|                     If no value is specified to this parameter then                     
|                     no overall total of the ACROSSVAR variable will                     
|                     be generated.                                                       
|                     Valid values                                                        
|                     Blank                                                               
|                     A value that can be entered into &ACROSSVAR                         
|                     without SAS error or truncation                                     
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
| WIDTHS              Variables and width to display                    (Blank)           
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
|-----------------------------------------------------------------------------------------
| Output: Printed output.
|
| Global macro variables created: NONE
|
|-----------------------------------------------------------------------------------------
| Macros called:
|
|(@) tr_putlocals
|(@) tu_putglobals
|(@) tu_freq
|-----------------------------------------------------------------------------------------
| Example:
|    %td_cm1()
|
|-----------------------------------------------------------------------------------------
| Change Log
| Modified by:             Yongwei Wang (YW62951)
| Date of modification:    19-May-2005
| New version number:      02/001
| Modification ID:         yw001
| Reason for modification: The ingredient for multi-ingredient drugs are not 
|                          displayed correctly. Following changes on the default
|                          parameter values have been made:
|                          1.Changed default DSETIN to ardata.cmanal.
|                          2.Changed all cmatc1_1 to cmatc1.
|                          3.Make PSFORMAT and PSCLASSOPTIONS available to be 
|                            editable by the user and passed through to tu_freq. 
|                            Set default value for psformat to be &g_trtcd &g_trtfmt  
|                            And default for PSCLASSOPTIONS to be preloadfmt
|                          4.Added parameter COMPLETETYPESVARS
|                          5.Changed all CMDECOD to CMCOMP
|                          6.Added DEFAULTWIDTHS TT_AC: 12
|                          7.Added CMATC1 to FLOWVARS
|                          8.Deleted code which resolve &sc in some parameter valuses
|                            because HARP can deal with ';' in parameter values now.
|
|-----------------------------------------------------------------------------------------
| Modified By:
| Date of Modification:
| New version number:
| Modification ID:
| Reason For Modification:
|---------------------------------------------------------------------------------------*/

%macro td_cm1(
   ACROSSVAR           =&g_trtcd,          /* Variable to transpose the data across to make columns of results. This is passed to the proc transpose ID statement */                                                                                         
   ACROSSVARDECODE     =&g_trtgrp,         /* A variable or format used in the construction of labels for the result columns. Usually &g_trtgrp */                                                                                                           
   BREAK1              =,                  /* Break statements */                                                                                                                                                                                            
   BREAK2              =,                  /* Break statements */                                                                                                                                                                                            
   BREAK3              =,                  /* Break statements */                                                                                                                                                                                            
   BREAK4              =,                  /* Break statements */                                                                                                                                                                                            
   BREAK5              =,                  /* Break statements */                                                                                                                                                                                            
   BYVARS              =,                  /* By variables */                                                                                                                                                                                                
   CENTREVARS          =,                  /* Centre justify variables */                                                                                                                                                                                    
   CODEDECODEVARPAIRS  =,                  /* Code and Decode variables in pairs */                                                                                                                                                                          
   COLSPACING          =2,                 /* Value for between-column spacing */                                                                                                                                                                            
   COLUMNS             =tt_spsort cmatc1 summaryLevel tt_pct999 cmcomp tt_ac:, /* Columns to be included in the listing (plus spanned headers) */                                                                                                           
   COMPLETETYPESVARS   =&g_trtcd,          /* Variables which COMPLETETYPES should be applied to */                                                                                                                                                          
   COMPUTEBEFOREPAGELINES=,                /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt : labelvar) */                                                                                                          
   COMPUTEBEFOREPAGEVARS=,                 /* Names of variables that define the sort order for  Compute Before Page lines */                                                                                                                                
   COUNTDISTINCTWHATVAR=&g_centid &g_subjid, /* Variable(s) that contain values to be counted uniquely within any output grouping. Eg &g_subjid */                                                                                                           
   DDDATASETLABEL      =DD dataset for CM1 table, /* Label to be applied to the DD dataset */                                                                                                                                                                
DEFAULTWIDTHS       =cmatc1 40 cmcomp 40 tt_ac: 12,
/* List of default column widths */
   DESCENDING          =tt_spsort tt_pct999, /* Descending ORDERVARS */                                                                                                                                                                                      
   DSETINDENOM         =&g_popdata,        /* Input dataset containing data to be counted to obtain the denominator. */                                                                                                                                      
DSETINNUMER         =ardata.cmanal(where=(display1 eq 1)),
/* Input dataset containing AE data to be counted to obtain the numerator. */
   FLOWVARS            =cmcomp cmatc1,     /* Variables with flow option */                                                                                                                                                                                  
   FORMATS             =,                  /* Format specification (valid SAS syntax) */                                                                                                                                                                     
   GROUPBYVARPOP       =&g_trtcd,          /* Variables to group by when counting big N */                                                                                                                                                                   
   GROUPBYVARSDENOM    =&g_trtcd,          /* Variables in DSETINDENOM to group the data by when counting to obtain the denominator. */                                                                                                                      
   GROUPBYVARSNUMER    =&g_trtcd (cmatc1='DUMMY' %nrstr(;) cmcomp= 'Any medication') cmatc1 (cmcomp= 'Any medication') cmcomp, /* Variables in DSETINNUMER to group the data by when counting to obtain the numerator.*/ 
   IDVARS              = ,                 /* Variables to appear on each page of the report */                                                                                                                                                              
   LABELS              =cmcomp='ATC Level 1~   Ingredient', /* Label definitions (var=var label) */                                                                                                                                                    
   LEFTVARS            =,                  /* Left justify variables */                                                                                                                                                                                      
   LINEVARS            =,                  /* Order variables printed with LINE statements */                                                                                                                                                                
   NOPRINTVARS         =tt_spsort tt_ac999 summaryLevel tt_pct999, /* No print variables, used to order the display */                                                                                                                                       
   NOWIDOWVAR          =,                  /* List of variables whose values must be kept together on a page */                                                                                                                                              
   ORDERDATA           =,                  /* ORDER=DATA variables */                                                                                                                                                                                        
   ORDERFORMATTED      =,                  /* ORDER=FORMATTED variables */                                                                                                                                                                                   
   ORDERFREQ           =,                  /* ORDER=FREQ variables */                                                                                                                                                                                        
   ORDERVARS           =tt_spsort cmatc1 summaryLevel tt_pct999 cmcomp, /* Order variables */                                                                                                                                                                
   PAGEVARS            =,                  /* Variables whose change in value causes the display to continue on a new page */                                                                                                                                
   POSTSUBSET          =if tt_pct999 gt 0, /* SAS expression to be applied to data immediately prior to creation of the permanent presentation dataset */                                                                                                    
   PROPTIONS           =Headline,          /* PROC REPORT statement options */                                                                                                                                                                               
   PSCLASSOPTIONS      =PRELOADFMT,        /* PROC SUMMARY CLASS Statement Options */                                                                                                                                                                        
   PSFORMAT            =&g_trtcd &g_trtfmt, /* Passed to the PROC SUMMARY FORMAT statement */                                                                                                                                                                
   PSOPTIONS           =COMPLETETYPES MISSING NWAY, /* PROC SUMMARY Options to use */                                                                                                                                                                        
   RESULTPCTDPS        =0,                 /* The reporting precision for percentages Valid values: 0 or any positive integer */                                                                                                                             
   RESULTSTYLE         =NUMERPCT,          /* The appearance style of the result columns that will be displayed in the report: */                                                                                                                            
   RIGHTVARS           =,                  /* Right justify variables */                                                                                                                                                                                     
   SHARECOLVARS        =cmatc1 cmcomp,     /* Order variables that share print space */                                                                                                                                                                      
   SHARECOLVARSINDENT  =2,                 /* Indentation factor */                                                                                                                                                                                          
   SKIPVARS            =cmatc1,            /* Variables whose change in value causes the display to skip a line */                                                                                                                                           
   SPLITCHAR           =~,                 /* The split character used in column labels. */                                                                                                                                                                  
   SPSORTGROUPBYVARSDENOM=,                /* Special sort: variables in DSETINDENOM to group the data by when counting to obtain the denominator. */                                                                                                        
   SPSORTGROUPBYVARSNUMER=cmatc1,          /* Special sort: variables in DSETINNUMER to group the data by when counting to obtain the numerator. */                                                                                                          
   SPSORTRESULTSTYLE   =PCT,               /* Special sort: the appearance style of the result data that will be used to sequence the report. */                                                                                                             
   TOTALDECODE         =Total,             /* Label for the total result column. Usually the text Total */                                                                                                                                                   
   TOTALFORVAR         =&g_trtcd,          /* Variable for which a total is required, usually trtcd */                                                                                                                                                       
   TOTALID             =999,               /* Value used to populate the variable specified in ACROSSVAR on data that represents the overall total for the ACROSSVAR variable. */                                                                            
   VARSPACING          =,                  /* Column spacing for individual variables */                                                                                                                                                                     
   WIDTHS              =                   /* Column widths */                                       
   );

   %LOCAL MacroVersion;
   %LET MacroVersion = 2;

   %INCLUDE "&g_refdata/tr_putlocals.sas";
   %tu_putglobals()

   %tu_freq(
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
      completetypesvars       =&completetypesvars,
      computebeforepagelines  =&computeBeforePageLines,
      computebeforepagevars   =&computeBeforePageVars,
      countDistinctWhatVar    =&countDistinctWhatVar,
      dddatasetlabel          =&dddatasetlabel,
      defaultwidths           =&defaultWidths,
      denormYN                =Y,
      descending              =&descending,
      display                 =Y,
      dsetinDenom             =&dsetinDenom,
      dsetinNumer             =&dsetinNumer,
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
      overallsummary          =Y,
      pagevars                =&pageVars,
      postSubset              =&postSubset,
      proptions               =&proptions,
      psByvars                =,
      psClass                 =,
      psClassOptions          =&psClassOptions,
      psFormat                =&psFormat,
      psFreq                  =,
      psid                    =,
      psOptions               =&psOptions,
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
      spSort2GroupByVarsDenom =,
      spSort2GroupByVarsNumer =,
      spSort2ResultStyle      =,
      spSort2ResultVarName    =,        
      spSortGroupByVarsDenom  =&spSortGroupByVarsDenom,
      spSortGroupByVarsNumer  =&spSortGroupByVarsNumer,
      spSortResultStyle       =&spSortResultStyle,
      spSortResultVarName     =tt_spsort,
      summaryLevelVarName     =summaryLevel,
      totalDecode             =&totalDecode,
      totalForVar             =&totalForVar,
      totalID                 =&totalID,
      varlabelstyle           =SHORT,
      varspacing              =&varSpacing,
      varsToDenorm            =tt_result tt_pct,
      widths                  =&widths
      )
      
%mend td_cm1;

