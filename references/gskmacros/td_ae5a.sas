/*
| Macro Name:        td_ae5a
|
| Macro Version:     1
|
| SAS Version:       8
|
| Created By:        Yongwei Wang
|
| Date:              17May2004
|
| Macro Purpose:     A macro to create Adverse Event Display 5.
|
| Macro Design:      Procedure style.
|
| Input Parameters:
|
| Name                Description                                       Default
| ----------------------------------------------------------------------------------------
| ACROSSVAR           Variable to transpose the data across to make     &g_trtcd aesevcd  
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
| ACROSSVARDECODE     A variable or format used in the construction of  &g_trtgrp aesev 
|                     labels for the result columns.                       
|                     Valid Values:                                        
|                     If DENORMYN is not Y, blank                                         
|                     Otherwise:                                                          
|                     Blank                                                               
|                     Name of a SAS variable that exists in                               
|                     DSETINNUMER                                                         
|                     An available SAS format                           
|
| AESEVCDVARNAME      Specifies the name of Adverse Event intensity     AESEVCD
|                     code variable. Normally it is either AESEVCD  
|                     or AETOXCD. If it is not AESEVCD, all AESEVCD 
|                     in the default values of the parameters should  
|                     be changed.
|                     Valid Values: A valid variable name which exists 
|                     in &DSETINNUMER
|      
| BREAK1 BREAK2       For input of user-specified break statements      (Blank)           
| BREAK3 BREAK4       Valid Values: valid PROC REPORT BREAK statements                    
| BREAK5              (without "break")                                                   
|                     The value of these parameters are passed                            
|                     directly to PROC REPORT as:                                         
|                     BREAK &break1;                                                      
|                                                                                         
| BYVARS              By variables. The variables listed here are       (Blank)           
|                     processed as standard SAS by variables                              
|                     Valid Values: one or more SAS variable names                        
|                     No formatting of the display for these variables                    
|                     is performed by %tu_display.  The user has the                      
|                     option of the standard SAS BY line, or using                        
|                     OPTIONS NOBYLINE and #BYVAL #BYVAR directives in                    
|                     title statements                                                    
|                                                                                         
| CENTREVARS          Variables to be displayed as centre justified     (Blank)           
|                     Valid Values: one or more variable names that                       
|                     are also defined with COLUMNS                                       
|                     Variables not appearing in any of the parameters                    
|                     CENTREVARS, LEFTVARS, or RIGHTVARS will be                          
|                     displayed using the PROC REPORT default.                            
|                     Character variables are left justified while                        
|                     numeric variables are right justified                               
|                                                                                         
| CODEDECODEVARPAIRS  Specifies code and decode variable pairs. Those   &g_trtcd          
|                     variables should be in parameter                  &g_trtgrp aesevcd 
|                     GROUPBYVARSNUMER. One variable in the pair will   aesev             
|                     contain the code and the other will contain                         
|                     decode.                                                             
|                     Valid Values:  Blank or a list of SAS variable                      
|                     names in pairs that are given in                                    
|                     GROUPBYVARSNUMER                                                    
|                                                                                         
| COLSPACING          The value of the between-column spacing           1   
|                     Valid Values: positive integer                     
|                                                                                         
| COLUMNS             A PROC REPORT column statement specification.     tt_spsort aesoc   
|                     Including spanning titles and variable names      summaryLevel      
|                     Valid Values: one or more variable names plus     tt_pct999 aept    
|                     other elements of valid PROC REPORT COLUMN        %nrstr(&acrosscollist) 
|                     statement syntax                                    
|                                                                         
|                                                                         
|                                                                                         
| COMPLETETYPESVARS   Specify a list of variables which are in          &g_trtcd aesevcd  
|                     GROUPBYVARSANALY and the COMPLETETYPES given by                     
|                     PSOPTIONS should be applied to. If it equals                        
|                     _ALL_, all variables in GROUPBYVARSANALY will be                    
|                     included.                                                           
|                     Valid Values:                                                       
|                     _ALL_                                                               
|                     A list of variable names which are in                               
|                     GROUPBYVARSANALY                                                    
|                                                                                         
| COMPUTEBEFOREPAGEL  See Unit Specification for HARP Reporting Tools   (Blank)  
| INES                TU_LIST[5] for complete details                                                                                         
|                                                                                         
| COMPUTEBEFOREPAGEV  See Unit Specification for HARP Reporting Tools   (Blank)  
| ARS                 TU_LIST[5] for complete details                        
|                                                                                         
| COUNTDISTINCTWHATV  Variable(s) that contain values to be counted     &g_centid         
| AR                  uniquely within any output grouping.              &g_subjid         
|                     Valid Values:                                                       
|                     Blank                                                               
|                     Name of one or more SAS variables that exists in                    
|                     DSETINNUMER                                                         
|                                                                                         
| DDDATASETLABEL      Specifies the label to be applied to the DD       DD dataset for    
|                     dataset                                           AE5 table         
|                     Valid Values: a non-blank text string                               
|                                                                                         
| DEFAULTWIDTHS       Specifies column widths for all variables not     aesoc 24 aept 24  
|                     listed in the WIDTHS parameter                    tt_ac: 10  
|                     Valid Values: values of column names and numeric     
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
|                     Valid Values: one or more variable names that      
|                     are also defined with ORDERVARS                    
|                                                                        
| DSETINDENOM         Input dataset containing data to be counted to    &g_popdata        
|                     obtain the denominator. This may or may not be                      
|                     the same as the dataset specified to                                
|                     DSETINNUMER.                                                        
|                     Valid Values:                                                       
|                     &g_popdata                                                          
|                     any other valid SAS dataset reference                               
|                                                                                         
| DSETINNUMER         Input dataset containing data to be counted to    ardata.ae         
|                     obtain the numerator.                                               
|                     Valid Values:                                                       
|                     Valid sas dataset name                                              
|                                                                                         
| FLOWVARS            Variables to be defined with the flow option      aesoc aept        
|                     Valid Values: one or more variable names that                       
|                     are also defined with COLUMNS                                       
|                     Flow variables should be given a width through                      
|                     the WIDTHS.  If a flow variable does not have a                     
|                     width specified, the column width will be                           
|                     determined by                                                       
|                     MIN(variables format width,                                        
|                     width of  column header)                                            
|                                                                                         
| FORMATS             Variables and their format for display.           (Blank)           
|                     Valid Values: values of column names and formats                    
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
|                     Valid Values:                                                       
|                     Blank if ADDBIGNYN=N                                                
|                     Otherwise, a list of valid SAS variable names                       
|                     that exist in population dataset created by                         
|                     %tu_freq's calling %tu_getdata                                      
|                                                                                         
| GROUPBYVARSDENOM    Variables in DSETINDENOM to group the data by     &g_trtcd          
|                     when counting to obtain the denominator.                            
|                     Valid Values:                                                       
|                     Blank, _NONE_ (to request an overall total for                      
|                     the whole dataset)                                                  
|                     Name of a SAS variable that exists in                               
|                     DSETINDENOM                                                         
|                                                                                         
| GROUPBYVARSNUMER    Variables in DSETINNUMER to group the data by,    &g_trtcd          
|                     along with ACROSSVAR, when counting to obtain     &g_trtgrp aesevcd 
|                     the numerator. Additionally a set of brackets     (aesoc='DUMMY';   
|                     may be inserted within the variables to generate  aept='ANY EVENT') 
|                     records containing summary counts grouped by      aesoc (aept='Any  
|                     variables specified to the left of the brackets.  Event') aept      
|                     Summary records created may be populated with                       
|                     values in the grouping variables by specifying                      
|                     variable value pairs within brackets, seperated                     
|                     by semi colons. eg aesoccd aesoc(aeptcd=0;                          
|                     aept="Any Event";) aeptcd aept.                                     
|                     Valid Values:                                                       
|                     Blank                                                               
|                     Name of one or more SAS variables that exist in                     
|                     DSETINNUMER                                                         
|                     SAS assignment statements within brackets                           
|                                                                                         
| GROUPMINMAXVAR      Specify if frequency of each group should be get  MAX(AESEVCD)       
|                     from minimum or maximum value of variable(s) in                     
|                     format MIN(variables). The first or last value                      
|                     of the variable(s) in each subgroup of                              
|                     &GROUPBYVARSANALY for &COUNTDISTINCWHATVAR will                     
|                     be created before calculating the frequency.                        
|                     Valid Values:                                                       
|                     Blank                                                               
|                     MIN({variable(s)})                                                  
|                     MAX({variable(s)})                                                  
|                     NOTE: {variables} means a list of valid SAS                         
|                     variable that exists in DSETIN                                      
|                                                                                         
| IDVARS              Variables to appear on each page if the report    tt_spSort aesoc   
|                     is wider than 1 page. If no value is supplied to  summaryLevel      
|                     this parameter then all displayable order         tt_pct999 aept    
|                     variables will be defined as IDVARS                
|                     Valid Values: one or more variable names that      
|                     are also defined with COLUMNS                      
|                                                                                         
| LABELS              Variables and their label for display. For use    Aept=System      
|                     where label for display differs to the label the  Organ Class~      
|                     display dataset.                                  Preferred Term   
|                     Valid Values: pairs of variable names and labels                    
|                                                                                         
| LEFTVARS            Variables to be displayed as left justified       (Blank)           
|                     Valid Values: one or more variable names that                       
|                     are also defined with COLUMNS                                       
|                                                                                         
| LINEVARS            List of order variables that are printed with     (Blank)           
|                     LINE statements in PROC REPORT                                      
|                     Valid Values: one or more variable names that                       
|                     are also defined with ORDERVARS                                     
|                     These values shall be written with a BREAK                          
|                     BEFORE when the value of one of the variables                       
|                     changes. The variables will automatically be                        
|                     defined as NOPRINT      
|                                            
| MISSINGAESEVCD      Specifies a value to replace the missing value    3
|                     of &AESEVCDVARNAME. By default, GROUPMINMAXVAR  
|                     equals max(&AESEVCDVARNAME), by reassigning the  
|                     value of missing &AESEVCDVARNAME, the missing   
|                     value can be assigned to different AE intensity 
|                     categories
|                     Valid Values: Any value that can be assigned to 
|                     &AESEVCDVARNAME. Note: The value is not checked.  
|                     The value should not be quoted 
|
| NOTAPPLICABLEAESEV  Specifies a value to replace the &AESEVCDVARNAME  0
| CD                  ='X'. By default, GROUPMINMAXVAR equals 
|                     max(&AESEVCDVARNAME), by reassigning the value
|                     of &AESEVCDVARNAME ='X', the not applicable 
|                     &AESEVCDVARNAME can be assigned to different AE 
|                     intensity categories 
|                     Valid Values: Any value that can be 
|                     assigned to &AESEVCDVARNAME. Note: The value is 
|                     not checked. The value should not be quoted                   
|                                                                                                                                                                          
| NOPRINTVARS         Variables listed in the COLUMN parameter that     tt_spsort         
|                     are given the PROC REPORT define statement        tt_ac999          
|                     attribute noprint                                 summaryLevel      
|                     Valid Values: one or more variable names that     tt_pct999  
|                     are also defined with COLUMNS                       
|                     These variables are ORDERVARS used to control       
|                     the order of the rows in the display                
|                                                                                         
| NOWIDOWVAR          Variable whose values must be kept together on a  (Blank)           
|                     page                                                                
|                     Valid Values: names of one or more variables                        
|                     specified in COLUMNS                                                
|                                                                                         
| ORDERDATA           Variables listed in the ORDERVARS parameter that  (Blank)           
|                     are given the PROC REPORT define statement                          
|                     attribute order=data                                                
|                     Valid Values: one or more variable names that                       
|                     are also defined with ORDERVARS                                     
|                     Variables not listed in ORDERFORMATTED,                             
|                     ORDERFREQ, or ORDERDATA are given the define                        
|                     attribute order=internal                                            
|                                                                                         
| ORDERFORMATTED      Variables listed in the ORDERVARS parameter that  (Blank)           
|                     are given the PROC REPORT define statement                          
|                     attribute order=formatted                                           
|                     Valid Values: one or more variable names that                       
|                     are also defined with ORDERVARS                                     
|                     Variables not listed in ORDERFORMATTED,                             
|                     ORDERFREQ, or ORDERDATA are given the define                        
|                     attribute order=internal                                            
|                                                                                         
| ORDERFREQ           Variables listed in the ORDERVARS parameter that  (Blank)           
|                     are given the PROC REPORT define statement                          
|                     attribute order=freq                                                
|                     Valid Values: one or more variable names  that                      
|                     are also defined with ORDERVARS                                     
|                     Variables not listed in ORDERFORMATTED,                             
|                     ORDERFREQ, or ORDERDATA are given the define                        
|                     attribute order=internal                                            
|                                                                                         
| ORDERVARS           List of variables that will receive the PROC      tt_spsort aesoc   
|                     REPORT define statement attribute ORDER           summaryLevel      
|                     Valid Values: one or more variable names that     tt_pct999 aept    
|                     are also defined with COLUMNS                       
|                                                                                         
| PAGEVARS            Variables whose change in value causes the        (Blank)           
|                     display to continue on a new page                                   
|                     Valid Values: one or more variable names that                       
|                     are also defined with COLUMNS                                       
|                                                                                         
| POSTSUBSET          SAS expression to be applied to data immediately  if tt_pct999 gt 0 
|                     prior to creation of the permanent presentation    
|                     dataset. Used for subsetting records required      
|                     for computation but not for display.               
|                     Valid Values:                                                       
|                     Blank                                                               
|                     A complete, syntactically valid SAS where or if                     
|                     statement for use in a data step                                    
|                                                                                         
| PROPTIONS           PROC REPORT statement options to be used in       Headline          
|                     addition to MISSING                                                 
|                     Valid Values: proc report options                                   
|                     The option Missing can not be overridden                          
|                                                                                         
| PSCLASSOPTIONS      PROC SUMMARY Class Statement Options.             preloadfmt        
|                     Valid Values:                                                       
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
|                     Valid Values:                                                       
|                     Blank                                                               
|                     Valid PROC SUMMARY FORMAT statement part.                           
|                                                                                         
| PSOPTIONS           PROC SUMMARY Options to use. MISSING ensures      COMPLETETYPES     
|                     that class variables with missing values are      MISSING NWAY      
|                     treated as a valid grouping. COMPLETETYPES adds     
|                     records showing a freq or n of 0 to ensure a         
|                     cartesian product of all class variables exists      
|                     in the output. NWAY writes output for the lowest     
|                     level  combinations of CLASS variables,                             
|                     suppressing all higher level totals.                                
|                     Valid Values:                                                       
|                     Blank                                                               
|                     One or more valid PROC SUMMARY options                              
|                                                                                         
| RESULTPCTDPS        The reporting precision for percentages           0                 
|                     Valid Values:                                                       
|                     0 or any positive integer                                           
|                                                                                         
| RESULTSTYLE         The appearance style of the result columns that   NUMERPCT          
|                     will be displayed in the report. The chosen                         
|                     style will be placed in variable &RESULTVARNAME.                    
|                     Valid Values:                                                       
|                     As documented for tu_percent in [6]. In typical                     
|                     usage, NUMERPCT.                                                    
|                                                                                         
| RIGHTVARS           Variables to be displayed as right justified      (Blank)           
|                     Valid Values: one or more variable names that                       
|                     are also defined with COLUMNS                                       
|                                                                                         
| SHARECOLVARS        List of variables that will share print space.    aesoc aept        
|                     The attributes of the last variable in the list                     
|                     define the column width and flow options                            
|                     Valid Values: one or more SAS variable names                        
|                     AE5 shows an example of this style of output                        
|                     The formatted values of the variables shall be                      
|                     written above each other in one column                              
|                                                                                         
| SHARECOLVARSINDENT  Indentation factor for ShareColVars. Stacked      2                 
|                     values shall be progressively indented by                           
|                     multiples of ShareColVarsIndent                                     
|                     Valid Values: positive integer                                      
|                                                                                         
| SKIPVARS            Variables whose change in value causes the        aesoc             
|                     display to skip a line                                              
|                     Valid Values: one or more variable names that                       
|                     are also defined with COLUMNS                                       
|                                                                                         
| SPLITCHAR           The split character used in column labels. Used   ~                 
|                     in the creation of the label for the result                         
|                     columns, and in %tu_stackvar, %tu_display (PROC                     
|                     REPORT). Usually ~                                                  
|                     Valid Values: Valid SAS split character.                            
|                                                                                         
| SPSORTGROUPBYVARSD  Special sort: variables in DSETINDENOM to group   (Blank)           
| ENOM                the data by when counting to obtain the                             
|                     denominator.                                                        
|                     Valid Values:                                                       
|                     Blank if SPSORTRESULTVARNAME is blank                               
|                     Otherwise,                                                          
|                     Blank                                                               
|                     _NONE_                                                              
|                     Name of a SAS variable that exists in                               
|                     DSETINDENOM                                                         
|                                                                                         
| SPSORTGROUPBYVARSN  Special sort: variables in DSETINNUMER to group   aesoc             
| UMER                the data by when counting to obtain the                             
|                     numerator.                                                          
|                     Valid Values:                                                       
|                     Blank if SPSORTRESULTVARNAME is blank                               
|                     Otherwise,                                                          
|                     Name of one or more SAS variables that exist in                     
|                     DSETINNUMER                                                         
|                                                                                         
| SPSORTRESULTSTYLE   Special sort: the appearance style of the result  PCT               
|                     data that will be used to sequence the report.                      
|                     The chosen style will be placed in variable                         
|                     SPSORTRESULTVARNAME                                                 
|                     Valid Values:                                                       
|                     As documented for tu_percent in [6]. In typical                     
|                     usage, NUMERPCT.                                                    
|                                                                                         
| TOTALFORVAR         Passed to %tu_statswithtotal. Variable for which  &g_trtcd*aesevcd  
|                     overall totals are required within all other        
|                     grouped class variables. If not specified, no       
|                     total will be produced. Can be one or a list of                     
|                     followings:                                                         
|                     1. Blank                                                            
|                     2. Name of a variable                                               
|                     3. Variable with sub group of values inside of                      
|                     ( and ). In this case, the total is for                         
|                     subgroup of the values listed inside of ( and                     
|                     )                                                                 
|                     4. A list of 2 or 3 separated by *. In this                       
|                     case, the overall total is based on more than                       
|                     one variable                                                        
|                     Valid Values:                                                       
|                     Can be one or a list of followings:                                 
|                     1. Blank                                                            
|                     2. Name of a variable                                               
|                     3. Variable with sub group of values inside of                      
|                     ( and )                                                         
|                     4. A list of 2 or 3 separated by *                                
|                                                                                         
| TOTALDECODE         Label for the total result column. Usually the    Total             
|                     text Total                                                          
|                     Valid Values:                                                       
|                     Blank                                                               
|                     SAS data step expression resolving to a                             
|                     character.                                                          
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
|                     Valid Values: variable name followed by a                           
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
|                     Valid Values: values of column names and numeric                    
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
|---------------------------------------------------------------------------------------
| Output: Printed output.
|
| Global macro variables created: NONE
|
|---------------------------------------------------------------------------------------
| Macros called:
|
|(@) tr_putlocals
|(@) tu_abort
|(@) tu_chkvarsexist
|(@) tu_freq
|(@) tu_getdata
|(@) tu_nobs
|(@) tu_putglobals
|(@) tu_tidyup
|
| Example:
|    %td_ae5a()
|
|---------------------------------------------------------------------------------------
| Modified By:              Yongwei Wang
| Date of Modification:     11-Oct-04
| New version number:       1/2
| Modification ID:          N/A
| Reason For Modification:  Changed default value of groupminmaxvar to max(aesevcd).
|---------------------------------------------------------------------------------------
| Modified By:              Yongwei Wang
| Date of Modification:     20-Oct-04
| New version number:       1/3
| Modification ID:          YW001
| Reason For Modification:  1. Added three parameters AESEVCDVARNAME MISSINGAESEVCD and 
|                              NOTAPPLICABLEAESEVCD
|                           2. Modified value of AESEVCD when AESEVCD equals X or missing in
|                              &dsetinnumer
|                           3. Added a format $tt_aesv. to PSFORMAT for AESEVCD if AESEVCD 
|                              is not in &PSFORMAT. The format can not be defined in 
|                              %tr_lang_BRENG.xml because the Missing can not be added.
|                           4. Added call to %tu_nobs, %tu_chkvarsexist, %tu_tidyup
|                              and %tu_getdata
|                           5. Removed about &sc in parameters and %unquote parameters.
|                           6. Added the check on AESEVCDVARNAME.
|                           7. Changed default value of PSFORMAT to blank.
|---------------------------------------------------------------------------------------
| Modified By:              
| Date of Modification:     
| New version number:       
| Modification ID:          
| Reason For Modification:  
|
|---------------------------------------------------------------------------------------*/
%macro td_ae5a(
   ACROSSVAR           =&g_trtcd aesevcd,  /* Variable to transpose the data across to make columns of results. This is passed to the proc transpose ID statement */                                                                 
   ACROSSVARDECODE     =&g_trtgrp aesev,   /* A variable or format used in the construction of labels for the result columns. Usually &g_trtgrp */                                                                                    
   AESEVCDVARNAME      =aesevcd,           /* AE Intensity code variable name */
   BREAK1              =,                  /* Break statements */                                                                                                                                                                                            
   BREAK2              =,                  /* Break statements */                                                                                                                                                                                            
   BREAK3              =,                  /* Break statements */                                                                                                                                                                                            
   BREAK4              =,                  /* Break statements */                                                                                                                                                                                            
   BREAK5              =,                  /* Break statements */                                                                                                                                                                                            
   BYVARS              =,                  /* By variables */                                                                                                                                                                                                
   CENTREVARS          =,                  /* Centre justify variables */                                                                                                                                                                                    
   CODEDECODEVARPAIRS  =&g_trtcd &g_trtgrp aesevcd aesev, /* Code and Decode variables in pairs */                                                                                                                                                           
   COLSPACING          =1,                 /* Value for between-column spacing */                                                                                                                                                       
   COLUMNS             =tt_spsort aesoc summaryLevel tt_pct999 aept %nrstr(&acrosscollist), /* Columns to be included in the listing (plus spanned headers) */                                                              
   COMPLETETYPESVARS   =&g_trtcd aesevcd,  /* Variables which COMPLETETYPES should be applied to */                                                                                                                                                          
   COMPUTEBEFOREPAGELINES=,                /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt : labelvar) */                                                     
   COMPUTEBEFOREPAGEVARS=,                 /* Names of variables that define the sort order for  Compute Before Page lines */                                                                                              
   COUNTDISTINCTWHATVAR=&g_centid &g_subjid, /* Variable(s) that contain values to be counted uniquely within any output grouping. Eg &g_subjid */                                                                                                           
   DDDATASETLABEL      =DD dataset for AE5 table, /* Label to be applied to the DD dataset */                                                                                                                                                                
   DEFAULTWIDTHS       =aesoc 24 aept 24 tt_ac: 10, /* List of default column widths */                                                                                                                          
   DESCENDING          =tt_spsort tt_pct999, /* Descending ORDERVARS */                                                                                                                                         
   DSETINDENOM         =&g_popdata,        /* Input dataset containing data to be counted to obtain the denominator. */                                                                                                                                     
   DSETINNUMER         =ardata.ae,         /* Input dataset containing AE data to be counted to obtain the numerator. */                                                                                                                                     
   FLOWVARS            =aesoc aept,        /* Variables with flow option */                                                                                                                                                                                  
   FORMATS             =,                  /* Format specification (valid SAS syntax) */                                                                                                                                                                     
   GROUPBYVARPOP       =&g_trtcd,          /* Variables to group by when counting big N */                                                                                                                                                                   
   GROUPBYVARSDENOM    =&g_trtcd,          /* Variables in DSETINDENOM to group the data by when counting to obtain the denominator. */                                                                                                                      
   GROUPBYVARSNUMER    =&g_trtcd &g_trtgrp aesevcd (aesoc='DUMMY'; aept='ANY EVENT') aesoc (aept='Any Event') aept, /* Variables in DSETINNUMER to group the data by when counting to obtain the numerator. */                                               
   GROUPMINMAXVAR      =MAX(aesevcd),      /* Specify if frequency of each group should be get from first or last value of a variable in format MIN(variables) */                                                                                             
   IDVARS              =tt_spSort aesoc summaryLevel tt_pct999 aept, /* Variables to appear on each page of the report */                                                                                       
   LABELS              =Aept=System Organ Class~   Preferred Term, /* Label definitions (var=var label) */                                                                                                                                               
   LEFTVARS            =,                  /* Left justify variables */                                                                                                                                                                                      
   LINEVARS            =,                  /* Order variables printed with LINE statements */                                                                                                                                                                
   MISSINGAESEVCD      =3,                 /* New value for missing &AESEVCDVARNAME */
   NOTAPPLICABLEAESEVCD=0,                 /* New value for &AESEVCDVARNAME='X' */
   NOPRINTVARS         =tt_spsort tt_ac999 summaryLevel tt_pct999, /* No print variables, used to order the display */                                                                                          
   NOWIDOWVAR          =,                  /* List of variables whose values must be kept together on a page */                                                                                                                                              
   ORDERDATA           =,                  /* ORDER=DATA variables */                                                                                                                                                                                        
   ORDERFORMATTED      =,                  /* ORDER=FORMATTED variables */                                                                                                                                                                                   
   ORDERFREQ           =,                  /* ORDER=FREQ variables */                                                                                                                                                                                        
   ORDERVARS           =tt_spsort aesoc summaryLevel tt_pct999 aept, /* Order variables */                                                                                                                      
   PAGEVARS            =,                  /* Variables whose change in value causes the display to continue on a new page */                                                                                                                                
   POSTSUBSET          =if tt_pct999 gt 0, /* SAS expression to be applied to data immediately prior to creation of the permanent presentation dataset */                                                       
   PROPTIONS           =Headline,          /* PROC REPORT statement options */                                                                                                                                                                               
   PSCLASSOPTIONS      =preloadfmt,        /* PROC SUMMARY CLASS Statement Options */                                                                                                                                                                        
   PSFORMAT            =,                  /* Passed to the PROC SUMMARY FORMAT statement. */                                                                                                                                                                
   PSOPTIONS           =COMPLETETYPES MISSING NWAY, /* PROC SUMMARY Options to use */                                                                                                             
   RESULTPCTDPS        =0,                 /* The reporting precision for percentages Valid Values: 0 or any positive integer */                                                                                                                             
   RESULTSTYLE         =NUMERPCT,          /* The appearance style of the result columns that will be displayed in the report: */                                                                                                                            
   RIGHTVARS           =,                  /* Right justify variables */                                                                                                                                                                                     
   SHARECOLVARS        =aesoc aept,        /* Order variables that share print space */                                                                                                                                                                      
   SHARECOLVARSINDENT  =2,                 /* Indentation factor */                                                                                                                                                                                          
   SKIPVARS            =aesoc,             /* Variables whose change in value causes the display to skip a line */                                                                                                                                           
   SPLITCHAR           =~,                 /* The split character used in column labels. */                                                                                                                                                                  
   SPSORTGROUPBYVARSDENOM=,                /* Special sort: variables in DSETINDENOM to group the data by when counting to obtain the denominator. */                                                                                                        
   SPSORTGROUPBYVARSNUMER=aesoc,           /* Special sort: variables in DSETINNUMER to group the data by when counting to obtain the numerator. */                                                                                                          
   SPSORTRESULTSTYLE   =PCT,               /* Special sort: the appearance style of the result data that will be used to sequence the report. */                                                                                                             
   TOTALFORVAR         =&g_trtcd*aesevcd,  /* Variable(s) for which a overall total is required */                                                                                                                                   
   TOTALDECODE         =Total,             /* Label for the total result column. Usually the text Total */                                                                                                                                                   
   TOTALID             =999,               /* Value used to populate the variable specified in ACROSSVAR on data that represents the overall total for the ACROSSVAR variable. */                                                                       
   VARSPACING          =,                  /* Column spacing for individual variables */                                                                                                                                                                     
   WIDTHS              =                   /* Column widths */   
   );
   
   %LOCAL MacroVersion;
   %LET MacroVersion = 1;
   
   %INCLUDE "&g_refdata/tr_putlocals.sas";
   %tu_putglobals()
   
   
   %local l_prefix l_hasna l_hasmissing;
   
   %let l_prefix=_tdae5a;    
   %let l_hasmissing=0;
   %let l_hasna=0;
   %let aesevcdvarname=%qupcase(&aesevcdvarname);
   
   /*
   /  Parameter validation.
   /----------------------------------------------------------------------------*/
   
   %if %nrbquote(&aesevcdvarname) EQ %then 
   %do;
      %put RTE%str(RROR): &sysmacroname: Value of parameter AESEVCDVARNAME is blank and it is required;
      %let g_abort=1;
      %goto macerr;
   %end;   
     
   /*
   /  YW001: Modify value of &AESEVCDVARNAME when &AESEVCDVARNAME equals 'X' 
   /  or missing. Create a format for &AESEVCDVARNAME and add the format to 
   /  PSFORMAT for &AESEVCDVARNAME, if &AESEVCDVARNAME is not in &PSFORMAT. Add 
   /  a format to PSFORMAT for &aesevcdvarname if &aesevcdvarname is not in 
   /  &PSFORMAT.
   /----------------------------------------------------------------------------*/
   
   %if ( %nrbquote(&dsetinnumer) ne ) %then 
   %do;        
      %if %tu_nobs(&dsetinnumer) ge 0 %then 
      %do;
         %if %nrquote(%tu_chkvarsexist(&dsetinnumer, &aesevcdvarname)) eq %then 
         %do;
          
            /* call tu_getdata to subset the &dsetinnumer */
            %tu_getdata(
               dsetin=&dsetinnumer,
               dsetout1=&l_prefix.getdata,
               dsetout2=
               )
                
            /* re-value &aesevcdvarname */               
            data &l_prefix.dsetin;
               set &l_prefix.getdata;                              
                                                       
               %if ( %nrbquote(&missingaesevcd) ne 1 ) and ( %nrbquote(&missingaesevcd) ne 2 ) and
                   ( %nrbquote(&missingaesevcd) ne 3 ) and ( %qupcase(&missingaesevcd) ne %qupcase(&notapplicableaesevcd) ) %then
               %do;
                  if missing(&aesevcdvarname) then call symput('l_hasmissing', '1');
               %end;
               
               %if ( %nrbquote(&missingaesevcd) ne 1 ) and ( %nrbquote(&missingaesevcd) ne 2 ) and
                   ( %nrbquote(&missingaesevcd) ne 3 ) and ( %qupcase(&missingaesevcd) eq %qupcase(&notapplicableaesevcd) ) %then 
               %do;
                   %if %nrbquote(&missingaesevcd) ne %then
                   %do;
                      if missing(&aesevcdvarname) or ( upcase(&aesevcdvarname) eq 'X' ) then call symput('l_hasna', '1');
                   %end;
                   %else %do;
                      if missing(&aesevcdvarname) or ( upcase(&aesevcdvarname) eq 'X' ) then call symput('l_hasmissing', '1');
                   %end;
               %end; /* end-if on %nrbquote(&missingaesevcd) not in 1 2 3 */
                                             
               %if ( %nrbquote(&notapplicableaesevcd) ne 1 ) and ( %nrbquote(&notapplicableaesevcd) ne 2 ) and
                   ( %nrbquote(&notapplicableaesevcd) ne 3 ) and ( %qupcase(&missingaesevcd) ne %qupcase(&notapplicableaesevcd) ) %then
               %do;
                  if upcase(&aesevcdvarname) eq 'X' then call symput('l_hasna', '1');   
               %end;
               
               if missing(&aesevcdvarname) then &aesevcdvarname=left(symget('missingaesevcd'));                             
               else if upcase(&aesevcdvarname) eq 'X' then &aesevcdvarname=left(symget('notapplicableaesevcd'));                
                     
            run;
            
            %let dsetinnumer=&l_prefix.dsetin;
              
            /* create and add format */            
            %if %sysfunc(indexw(%qupcase(&psformat), &aesevcdvarname)) lt 1 %then                  
            %do;
               proc format;
                  value $tt_aesv
                  '1'='Mild'
                  '2'='Moderate'
                  '3'='Severe'
                  %if &l_hasmissing eq 1 %then
                  %do;
                     %if %nrbquote(&missingaesevcd) ne %then 
                     %do;
                        "&missingaesevcd"='Missing'
                     %end;
                     %else %do;
                        ' '='Missing'
                     %end;
                  %end; /* end-if on &l_hasmissing eq 1 */
                  %if &l_hasna eq 1 %then
                  %do;
                     %if %nrbquote(&notapplicableaesevcd) ne %then 
                     %do;
                        "&notapplicableaesevcd"='Not Applicable'
                     %end;
                     %else %do;
                        ' '='Missing'
                     %end;         
                  %end; /* end-if on &l_hasna eq 1 */           
                  ;
               run;   
               %let psformat=&psformat. &aesevcdvarname $tt_aesv.;
               
            %end;  /* end-if on %sysfunc(indexw(%qupcase(&psformat), &aesevcdvarname) lt 1 */                                   
            
         %end; /* end-if on %nrquote(%tu_chkvarsexist(&dsetinnumer, &aesevcdvarname)) eq */
         %else %do;
            %put RTE%str(RROR): &sysmacroname: Variable AESEVCDVARNAME=&AESEVCDVARNAME does not exist in DSETINNUMER=&DSETINNUMER;
            %let g_abort=1;
            %goto macerr;        
         %end;
         
      %end; /* end-if on %tu_nobs(&dsetinnumer) gt 0 */
   %end; /* end-if on %nrbquote(&dsetinnumer) ne */
        
   /*
   / Call tu_freq to create output.
   /------------------------------------------------------------*/                                         
   %tu_freq(
      groupminmaxvar          =&groupminmaxvar,
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
      spSortGroupByVarsDenom  =&spSortGroupByVarsDenom,
      spSortGroupByVarsNumer  =&spSortGroupByVarsNumer,
      spSortResultStyle       =&spSortResultStyle,
      spSortResultVarName     =tt_spsort,
      stackvar1               =,
      stackvar2               =,
      stackvar3               =,
      stackvar4               =,
      stackvar5               =,
      stackvar6               =,
      stackvar7               =,
      stackvar8               =,
      stackvar9               =,
      stackvar10              =,
      stackvar11              =,
      stackvar12              =,
      stackvar13              =,
      stackvar14              =,
      stackvar15              =,
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
      %tu_abort()
%ENDMAC: 
   %tu_tidyup(
      RMDSET =&L_PREFIX:,
      GLBMAC =NONE
      ) 
               
%mend td_ae5a;
