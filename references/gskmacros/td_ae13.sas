/*
| Macro Name:         td_ae13
|                    
| Macro Version:      1
|                    
| SAS Version:        9
|                    
| Created By:         Yongwei Wang
|                    
| Date:               10Feb2010
|                    
| Macro Purpose:      The unit shall create the IDSL standard data display AE13 
|                     identified in the IDSL Data Display Standards
|                    
| Macro Design:       Procedure style.
|                    
| Input Parameters:
| 
| Name                Description                                  Default           
| -----------------------------------------------------------------------------------
| CATGROUP1           If-statement and label which are used to     %nrstr(if=(aeser  
|                     subset the DSETINNUMER and assigned the      in ( 'N' 'Y' ))   
|                     label to the subset. The label will be       label='Any AE')   
|                     saved in variable tt_avnm and the order  of                    
|                     the parameter will be assigned to  tt_avid.                    
|                     Valid values: Blank or a text in format:                       
|                     if=(expression) label="label"                                  
|                                                                                    
| CATGROUP2           Same as CATGROUP1                            %nrstr(if=(aeser  
|                                                                  in ( 'N' 'Y' )    
|                                                                  and aerel eq 'Y') 
|                                                                  label='  AEs      
|                                                                  related to study  
|                                                                  treatment')       
|                                                                                    
| CATGROUP3           Same as CATGROUP1                            %nrstr(if=(aeser  
|                                                                  in ( 'N' 'Y' )    
|                                                                  and aeactrcd eq   
|                                                                  '1') label='  AEs 
|                                                                  leading to        
|                                                                  permanent~        
|                                                                  discontinuation   
|                                                                  of study          
|                                                                  treatment')       
|                                                                                    
| CATGROUP4           Same as CATGROUP1                            %nrstr(if=(aeser  
|                                                                  in ( 'N' 'Y' )    
|                                                                  and aeactrcd eq   
|                                                                  '2') label='  AEs 
|                                                                  leading to dose   
|                                                                  reduction')       
|                                                                                    
| CATGROUP5           Same as CATGROUP1                            %nrstr(if=(aeser  
|                                                                  in ( 'N' 'Y' )    
|                                                                  and aeactrcd eq   
|                                                                  '5') label='  AEs 
|                                                                  leading to dose   
|                                                                  interruption/delay
|                                                                  ')                
|                                                                                    
| CATGROUP6           Same as CATGROUP1                            %nrstr(if=(aeser  
|                                                                  eq 'Y')           
|                                                                  label='Any SAE')  
|                                                                                    
| CATGROUP7           Same as CATGROUP1                            %nrstr(if=(aeser  
|                                                                  eq 'Y' and aerel  
|                                                                  eq 'Y') label='   
|                                                                  SAEs related to   
|                                                                  study treatment') 
|                                                                                    
| CATGROUP8           Same as CATGROUP1                            %nrstr(if=(aeser  
|                                                                  eq 'Y' and        
|                                                                  aeoutcd='5')      
|                                                                  label='  Fatal    
|                                                                  SAEs')            
|                                                                                    
| CATGROUP9           Same as CATGROUP1                            %nrstr(if=(aeser  
|                                                                  eq 'Y' and        
|                                                                  aeoutcd='5' and   
|                                                                  aerel eq 'Y')     
|                                                                  label='  Fatal    
|                                                                  SAEs related to   
|                                                                  study treatment') 
|                                                                                    
| CATGROUP10-CAGROUT  Same as CATGROUP1                            (Blank)           
| P20                                                                                
|                                                                                    
| PRESUBSET           Specifies a SAS data step statement which    (Blank)           
|                     will be applied to DSETINNUMER before                          
|                     passing to %TU_FREQ                                            
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
| CODEDECODEVARPAIRS  Specifies code and decode variable pairs.    &g_trtcd          
|                     Those variables should be in parameter       &g_trtgrp tt_avid 
|                     GROUPBYVARSNUMER. One variable in the pair   tt_avnm           
|                     will contain the code and the other will                       
|                     contain decode.                                                
|                     Valid values:  Blank or a list of SAS                          
|                     variable names in pairs that are given in                      
|                     GROUPBYVARSNUMER                                               
|                                                                                    
| COLSPACING          The value of the between-column spacing.     2                 
|                     Valid values: positive integer                                 
|                                                                                    
| COLUMNS             A PROC REPORT column statement               tt_grpcd tt_avid  
|                     specification.  Including spanning titles    tt_avnm tt_ac:    
|                     and variable names                                             
|                     Valid values: one or more variable names                       
|                     from DSETIN plus other elements of valid                       
|                     PROC REPORT COLUMN statement syntax, but                       
|                     not including report_item=alias syntax                         
|                                                                                    
| COMPLETETYPESVARS   Passed to %tu_statswithtotal. Specify a      _ALL_             
|                     list of variables which are in                                 
|                     GROUPBYVARSANALY and the COMPLETETYPES                         
|                     given by PSOPTIONS should be applied to. If                    
|                     it equals _ALL_, all variables in                              
|                     GROUPBYVARSANALY will be included.                             
|                     Valid values:                                                  
|                     _ALL_                                                          
|                     A list of variable names which are in                          
|                     GROUPBYVARSANALY                                               
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
|                     trtgrp                                                         
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
|                     dataset                                      new AE13 table    
|                     Valid values: a non-blank text string                          
|                                                                                    
| DEFAULTWIDTHS       This is a list of default widths for ALL     tt_avnm 40 tt_ac: 
|                     columns and will usually be defined by the   15                
|                     DD macro.  This parameter specifies column                     
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
| DSETINNUMER         Specifies the input nominator SAS data set.  ardata.ae         
|                                                                                    
| DSETINDENOM         Specifies the input denominator SAS data     &g_popdata        
|                     set.                                                           
|                                                                                    
| DSETOUT             Name of output dataset                       (Blank)           
|                     Valid values: Blank or A valid SAS dataset                     
|                     name                                                           
|                                                                                    
| DISPLAY             Specifies whether the report should be       Y                 
|                     created.                                                       
|                     Valid values: Y or N                                           
|                                                                                    
| FLOWVARS            Variables to be defined with the flow        tt_avnm           
|                     option.                                                        
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
| FORMATS             Variables and their format for display. For  (Blank)           
|                     use where format for display differs to the                    
|                     format on the DSETIN.                                          
|                     Valid values: values of column names and                       
|                     formats such as form valid syntax for a SAS                    
|                     FORMAT statement                                               
|                                                                                    
| GROUPBYVARPOP       Specifies a list of variables to group by    &g_trtcd          
|                     when counting big N using %tu_addbignvar.                      
|                     Usually one variable &g_trtcd.                                 
|                     It will be passed to GROUPBYVARS of                            
|                     %tu_addbignvar. See Unit Specification for                     
|                     HARP Reporting Tools TU_ADDBIGNVAR[7]                          
|                     Required if ADDBIGNYN =Y                                       
|                     Valid values:                                                  
|                     Blank if ADDBIGNYN=N                                           
|                     Otherwise, a list of valid SAS variable                        
|                     names that exist in population dataset                         
|                     created by %tu_freq's calling %tu_getdata                      
|                                                                                    
| GROUPMINMAXVAR      Specify if frequency of each group should    (Blank)           
|                     be get from minimum or maximum value of                        
|                     variable(s) in format MIN(variables). The                      
|                     first or last value of the variable(s) in                      
|                     each subgroup of ROUPBYVARSANALY for                           
|                     &COUNTDISTINCWHATVAR will be created before                    
|                     calculating the frequency.                                     
|                     Valid values:                                                  
|                     Blank                                                          
|                     MIN({variable(s)})                                             
|                     MAX({variable(s)})                                             
|                     NOTE: {variables} means a list of valid SAS                    
|                     variable that exists in DSETIN                                 
|                                                                                    
| GROUPBYVARSDENOM    Variables in DSETINDENOM to group the data   &g_trtcd          
|                     by when counting to obtain the denominator.                    
|                     Valid values:                                                  
|                     Blank, _NONE_ (to request an overall total                     
|                     for the whole dataset)                                         
|                     Name of a SAS variable that exists in                          
|                     DSETINDENOM                                                    
|                                                                                    
| GROUPBYVARSNUMER    Variables in DSETINNUMER to group the data   &g_trtcd          
|                     by, along with ACROSSVAR, when counting to   &g_trtgrp tt_avid 
|                     obtain the numerator. Additionally a set of  tt_avnm           
|                     brackets may be inserted within the                            
|                     variables to generate records containing                       
|                     summary counts grouped by variables                            
|                     specified to the left of the brackets.                         
|                     Summary records created may be populated                       
|                     with values in the grouping variables by                       
|                     specifying variable value pairs within                         
|                     brackets, seperated by semi colons. eg                         
|                     aesoccd aesoc(aeptcd=0; aept="Any Event";)                     
|                     aeptcd aept.                                                   
|                     Valid values:                                                  
|                     Blank                                                          
|                     Name of one or more SAS variables that                         
|                     exist in DSETINNUMER                                           
|                     SAS assignment statements within brackets                      
|                                                                                    
| IDVARS              Variables to appear on each page should the  tt_avid tt_avnm   
|                     report be wider than 1 page. If no value is                    
|                     supplied to this parameter then all                            
|                     displayable order variables will be defined                    
|                     as idvars                                                      
|                     Valid values: one or more variable names                       
|                     from DSETIN that are also defined with                         
|                     COLUMNS                                                        
|                                                                                    
| LABELS              Variables and their label for display. For   (Blank)           
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
| NOPRINTVARS         Variables listed in the COLUMN parameter     tt_avid tt_grpcd  
|                     that are given the PROC REPORT define                          
|                     statement attribute noprint.                                   
|                     Valid values: one or more variable names                       
|                     from DSETIN that are also defined with                         
|                     COLUMNS                                                        
|                     These variables are usually ORDERVARS used                     
|                     to control the order of the rows in the                        
|                     display.                                                       
|                                                                                    
| NOWIDOWVAR          Variable whose values must be kept together  dsrscd            
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
| ORDERVARS           List of variables that will receive the      tt_grpcd tt_avid  
|                     PROC REPORT define statement attribute       tt_avnm           
|                     ORDER                                                          
|                     Valid values: one or more variable names                       
|                     from DSETIN that are also defined with                         
|                     COLUMNS                                                        
|                                                                                    
| PAGEVARS            Variables whose change in value causes the   (Blank)           
|                     display to continue on a new page                              
|                     Valid values: one or more variable names                       
|                     from DSETIN that are also defined with                         
|                     COLUMNS                                                        
|                                                                                    
| POSTSUBSET          SAS expression to be applied to data         %nrstr(if tt_avid 
|                     immediately prior to creation of the         le 5 then         
|                     permanent presentation dataset. Used for     tt_grpcd=1; else  
|                     subsetting records required for computation  tt_grpcd=2)       
|                     but not for display.                                           
|                     Valid values: Blank or a complete,                             
|                     syntactically valid SAS where or if                            
|                     statement for use in a data step                               
|                                                                                    
| PROPTIONS           PROC REPORT statement options to be used in  Headline          
|                     addition to MISSING.                                           
|                     Valid values: proc report options                              
|                     The option Missing can not be overridden.                    
|                                                                                    
| PSCLASSOPTIONS      PROC SUMMARY Class Statement Options.        PRELOADFMT        
|                     Valid Values:                                                  
|                     Blank                                                          
|                     Valid PROC SUMMARY CLASS Options (without                      
|                     the leading '/')                                               
|                     Eg: PRELOADFMT  which can be used in                           
|                     conjunction with PSFORMAT and COMPLETETYPES                    
|                     (default in PSOPTIONS) to create records                       
|                     for                                                            
|                     possible categories that are specified in a                    
|                     format but which may not exist in data                         
|                     being summarised.                                              
|                                                                                    
| PSFORMAT            Passed to the PROC SUMMARY FORMAT            &g_trtcd          
|                     statement.                                   &g_trtfmt tt_avid 
|                     Valid Values:                                _avfmt.           
|                     Blank                                                          
|                     Valid PROC SUMMARY FORMAT statement part                       
|                                                                                    
| PSOPTIONS           PROC SUMMARY Options to use. MISSING         COMPLETETYPES     
|                     ensures that class variables with missing    MISSING NWAY      
|                     values are treated as a valid grouping.                        
|                     COMPLETETYPES adds records showing a freq                      
|                     or n of 0 to ensure a cartesian product of                     
|                     all class variables exists in the output.                      
|                     NWAY writes output for the lowest level                        
|                     combinations of CLASS variables,                               
|                     suppressing all higher level totals.                           
|                     Valid values:                                                  
|                     Blank                                                          
|                     One or more valid PROC SUMMARY options                         
|                                                                                    
| RESULTPCTDPS        The reporting precision for percentages      0                 
|                     Valid values:                                                  
|                     0 or any positive integer                                      
|                                                                                    
| RESULTSTYLE         The appearance style of the result columns   NUMERPCT          
|                     that will be displayed in the report. The                      
|                     chosen style will be placed in variable                        
|                     &RESULTVARNAME.                                                
|                     Valid values:                                                  
|                     As documented for tu_percent in [6]. In                        
|                     typical usage, NUMERPCT.                                       
|                                                                                    
| RIGHTVARS           Variables to be displayed as right           (Blank)           
|                     justified                                                      
|                     Valid values: one or more variable names                       
|                     from DSETIN that are also defined with                         
|                     COLUMNS                                                        
|                                                                                    
| SHARECOLVARS        List of variables that will share print      (Blank)           
|                     space. The attributes of the last variable                     
|                     in the list define the column width and                        
|                     flow options                                                   
|                     Valid values: one or more variable names                       
|                     from DSETIN                                                    
|                     AE5 shows an example of this style of                          
|                     output                                                         
|                     The formatted values of the variables shall                    
|                     be written above each other in one column.                     
|                                                                                    
| SHARECOLVARSINDENT  Indentation factor for ShareColVars.         2                 
|                     Stacked values shall be progressively                          
|                     indented by multiples of                                       
|                     ShareColVarsIndent.                                            
|                     REQUIRED when SHARECOLVARS is specified                        
|                     Valid values: positive integer                                 
|                                                                                    
| SKIPVARS            Variables whose change in value causes the   tt_grpcd          
|                     display to skip a line                                         
|                     Valid values: one or more variable names                       
|                     from DSETIN that are also defined with                         
|                     COLUMNS                                                        
|                                                                                    
| SPLITCHAR           Specifies the split character to be passed   ~                 
|                     to %tu_display                                                 
|                     Valid values: one single character                             
|                                                                                    
| SPSORTGROUPBYVARSD  Special sort: variables in DSETINDENOM to    (Blank)           
| ENOM                group the data by when counting to obtain                      
|                     the denominator.                                               
|                     Valid values:                                                  
|                     Blank if SPSORTRESULTVARNAME is blank                          
|                     Otherwise,                                                     
|                     Blank                                                          
|                     _NONE_                                                         
|                     Name of a SAS variable that exists in                          
|                     DSETINDENOM                                                    
|                                                                                    
| SPSORTGROUPBYVARSN  Special sort: variables in DSETINNUMER to    (Blank)           
| UMER                group the data by when counting to obtain                      
|                     the numerator.                                                 
|                     Valid values:                                                  
|                     Blank if SPSORTRESULTVARNAME is blank                          
|                     Otherwise,                                                     
|                     Name of one or more SAS variables that                         
|                     exist in DSETINNUMER                                           
|                                                                                    
| SPSORTRESULTVARNAM  Special sort: the name of a variable to be   (Blank)           
| E                   created to hold the spSortResultStyle data                     
|                     when merging the special sort sequence                         
|                     records with the presentation data records.                    
|                     Valid values:                                                  
|                     Blank                                                          
|                     A valid SAS variable name.                                     
|                     eg. tt_spSort.                                                 
|                     This variable is likely to be included in                      
|                     the columns and noprint parameters passed                      
|                     to tu_list.                                                    
|                                                                                    
| TOTALDECODE         Label for the total result column. Usually   (Blank)           
|                     the text Total                                                 
|                     Valid values:                                                  
|                     Blank                                                          
|                     SAS data step expression resolving to a                        
|                     character.                                                     
|                                                                                    
| TOTALFORVAR         Variable for which total is required within  (Blank)           
|                     all other grouped classvars (usually                           
|                     trtcd). If not specified, no total will be                     
|                     produced                                                       
|                     Valid values: Blank if TOTALID is blank.                       
|                                                                                    
| TOTALID             Value used to populate the variable          (Blank)           
|                     specified in ACROSSVAR on data that                            
|                     represents the overall total for the                           
|                     ACROSSVAR variable.                                            
|                     If no value is specified to this parameter                     
|                     then no overall total of the ACROSSVAR                         
|                     variable will be generated.                                    
|                     Valid values                                                   
|                     Blank                                                          
|                     A value that can be entered into &ACROSSVAR                    
|                     without SAS error or truncation                                
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
|----------------------------------------------------------------------------------------
| Output: 
|  1. The unit shall optionally produce an output file in plain ASCII  text format 
|     containing a report matching the requirements specified as input parameters
|  2. The unit shall optionally store the dataset that forms the foundation of the data 
|     display
|  3. The unit shall optionally produce an output data set
|----------------------------------------------------------------------------------------
| Global macro variables created: NONE
|----------------------------------------------------------------------------------------
| Macros called:
| (@) tr_putlocals
| (@) tu_nobs
| (@) tu_freq
| (@) tu_getdata
| (@) tu_abort
| (@) tu_tidyup
| (@) tu_putglobals
|----------------------------------------------------------------------------------------
| Example:
|    %td_ae13()
|----------------------------------------------------------------------------------------
| Change Log
|
| Modified By:
| Date of Modification:
| New version number:
| Modification ID:
| Reason For Modification:
|----------------------------------------------------------------------------------------*/

%macro td_ae13 (
   CATGROUP1             =%nrstr(if=(aeser in ( 'N' 'Y' )) label='Any AE'), /* Same as CATGROUP20 */    
   CATGROUP2             =%nrstr(if=(aeser in ( 'N' 'Y' ) and aerel eq 'Y') label='  AEs related to study treatment'), /* Same as CATGROUP20 */
   CATGROUP3             =%nrstr(if=(aeser in ( 'N' 'Y' ) and aeactrcd eq '1') label='  AEs leading to permanent~  discontinuation of study treatment'), /* Same as CATGROUP20 */
   CATGROUP4             =%nrstr(if=(aeser in ( 'N' 'Y' ) and aeactrcd eq '2') label='  AEs leading to dose reduction'), /* Same as CATGROUP20 */
   CATGROUP5             =%nrstr(if=(aeser in ( 'N' 'Y' ) and aeactrcd eq '5') label='  AEs leading to dose interruption/delay'), /* Same as CATGROUP20 */
   CATGROUP6             =%nrstr(if=(aeser eq 'Y') label='Any SAE'), /* Same as CATGROUP20 */
   CATGROUP7             =%nrstr(if=(aeser eq 'Y' and aerel eq 'Y') label='  SAEs related to study treatment'), /* Same as CATGROUP20 */
   CATGROUP8             =%nrstr(if=(aeser eq 'Y' and aeoutcd='5') label='  Fatal SAEs'), /* Same as CATGROUP20 */
   CATGROUP9             =%nrstr(if=(aeser eq 'Y' and aeoutcd='5' and aerel eq 'Y') label='  Fatal SAEs related to study treatment'), /* Same as CATGROUP20 */
   CATGROUP10            =,          /* If-statement (if=(expression)) and label (label='label') which are used to subset the DSETINNUMER and assign label to the subset. */                             
   CATGROUP11            =,          /* If-statement (if=(expression)) and label (label='label') which are used to subset the DSETINNUMER and assign label to the subset. */                             
   CATGROUP12            =,          /* If-statement (if=(expression)) and label (label='label') which are used to subset the DSETINNUMER and assign label to the subset. */                             
   CATGROUP13            =,          /* If-statement (if=(expression)) and label (label='label') which are used to subset the DSETINNUMER and assign label to the subset. */                             
   CATGROUP14            =,          /* If-statement (if=(expression)) and label (label='label') which are used to subset the DSETINNUMER and assign label to the subset. */                             
   CATGROUP15            =,          /* If-statement (if=(expression)) and label (label='label') which are used to subset the DSETINNUMER and assign label to the subset. */      
   CATGROUP16            =,          /* If-statement (if=(expression)) and label (label='label') which are used to subset the DSETINNUMER and assign label to the subset. */      
   CATGROUP17            =,          /* If-statement (if=(expression)) and label (label='label') which are used to subset the DSETINNUMER and assign label to the subset. */       
   CATGROUP18            =,          /* If-statement (if=(expression)) and label (label='label') which are used to subset the DSETINNUMER and assign label to the subset. */      
   CATGROUP19            =,          /* If-statement (if=(expression)) and label (label='label') which are used to subset the DSETINNUMER and assign label to the subset. */
   CATGROUP20            =,          /* If-statement (if=(expression)) and label (label='label') which are used to subset the DSETINNUMER and assign label to the subset. */
   PRESUBSET             =,          /* SAS data step statement applied to DSETINNUMER before passing to %TU_FREQ */
   ACROSSVAR             =&g_trtcd,  /* Variable to transpose the data across to make columns of results. This is passed to the proc transpose ID statement */
   ACROSSVARDECODE       =&g_trtgrp, /* A variable or format used in the construction of labels for the result columns. Usually &g_trtgrp */
   BREAK1                =,          /* Break statements */
   BREAK2                =,          /* Break statements */
   BREAK3                =,          /* Break statements */
   BREAK4                =,          /* Break statements */
   BREAK5                =,          /* Break statements */
   BYVARS                =,          /* By variables */
   CENTREVARS            =,          /* Centre justify variables */
   CODEDECODEVARPAIRS    =&g_trtcd &g_trtgrp tt_avid tt_avnm, /* Code and Decode variables in pairs */
   COLSPACING            =2,         /* Value for between-column spacing */
   COLUMNS               =tt_grpcd tt_avid tt_avnm tt_ac:, /* Columns to be included in the listing (plus spanned headers) */
   COMPLETETYPESVARS     =_all_,     /* Variables which COMPLETETYPES should be applied to */ 
   COMPUTEBEFOREPAGELINES=,          /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt : labelvar) */
   COMPUTEBEFOREPAGEVARS =,          /* Names of variables that define the sort order for  Compute Before Page lines */
   COUNTDISTINCTWHATVAR  =&g_centid &g_subjid,/* Variable(s) that contain values to be counted uniquely within any output grouping. Eg &g_subjid */
   DDDATASETLABEL        =DD dataset for AE13 table, /* Label to be applied to the DD dataset */
   DEFAULTWIDTHS         =tt_avnm 40 tt_ac: 15, /* List of default column widths */
   DESCENDING            =,          /* Descending ORDERVARS */
   DISPLAY               =Y,         /* Specifies whether the report should be created */
   DSETINNUMER           =ardata.ae, /* Input AE Data */
   DSETINDENOM           =&g_popdata,/* Denominator data set */
   DSETOUT               =,          /* Name of output dataset */
   FLOWVARS              =tt_avnm,   /* Variables with flow option */
   FORMATS               =,          /* Format specification (valid SAS syntax) */
   GROUPBYVARPOP         =&g_trtcd,  /* Variables to group by when counting big N */
   GROUPBYVARSDENOM      =&g_trtcd,  /* Variables in DSETINDENOM to group the data by when counting to obtain the denominator. */
   GROUPBYVARSNUMER      =&g_trtcd &g_trtgrp tt_avid tt_avnm, /* Variables in DSETINNUMER to group the data by when counting to obtain the numerator. */
   GROUPMINMAXVAR        =,          /* Specify if frequency of each group should be from first or last value of a variable in format MIN(variables) */  
   IDVARS                =tt_avid tt_avnm, /* Variables to appear on each page of the report */
   LABELS                =,          /* Label definitions (var=var label) */
   LEFTVARS              =,          /* Left justify variables */
   LINEVARS              =,          /* Order variables printed with LINE statements */
   NOPRINTVARS           =tt_avid tt_grpcd, /* No print variables, used to order the display */
   NOWIDOWVAR            =,          /* List of variables whose values must be kept together on a page */
   ORDERDATA             =,          /* ORDER=DATA variables */
   ORDERFORMATTED        =,          /* ORDER=FORMATTED variables */
   ORDERFREQ             =,          /* ORDER=FREQ variables */
   ORDERVARS             =tt_grpcd tt_avid tt_avnm,   /* Order variables */
   PAGEVARS              =,          /* Variables whose change in value causes the display to continue on a new page */
   POSTSUBSET            =%nrstr(if tt_avid le 5 then tt_grpcd=1; else tt_grpcd=2), /* First SAS expression to be applied to data immediately prior to creation of the permanent presentation dataset */
   PROPTIONS             =Headline,  /* PROC REPORT statement options */
   PSCLASSOPTIONS        =preloadfmt,/* PROC SUMMARY CLASS Statement Options */
   PSFORMAT              =&g_trtcd &g_trtfmt tt_avid _avfmt., /* Passed to the PROC SUMMARY FORMAT statement. */
   PSOPTIONS             =COMPLETETYPES MISSING NWAY, /* PROC SUMMARY Options to use */
   RESULTPCTDPS          =0,         /* The reporting precision for percentages Valid values: 0 or any positive integer */
   RESULTSTYLE           =NUMERPCT,  /* The appearance style of the result columns that will be displayed in the report: */
   RIGHTVARS             =,          /* Right justify variables */
   SHARECOLVARS          =,          /* Order variables that share print space */
   SHARECOLVARSINDENT    =2,         /* Indentation factor */
   SKIPVARS              =tt_grpcd,  /* Variables whose change in value causes the display to skip a line */
   SPLITCHAR             =~,         /* The split character used in column labels. */
   SPSORTGROUPBYVARSDENOM=,          /* Special sort: variables in DSETINDENOM to group the data by when counting to obtain the denominator. */                                                                                                        
   SPSORTGROUPBYVARSNUMER=,          /* pecial sort: variables in DSETINNUMER to group the data by when counting to obtain the numerator */                                                                                                            
   SPSORTRESULTVARNAME   =,          /* Special sort: the name of a variable to be created to hold the spSortResultStyle data when merging the special sort sequence records with the presentation data records.*/     
   TOTALDECODE           =,          /* Label for the total result column. Usually the text Total */
   TOTALFORVAR           =,          /* Variable for which a total is required, usually trtcd */
   TOTALID               =,          /* Value used to populate the variable specified in ACROSSVAR on data that represents the overall total for the ACROSSVAR variable. */
   VARSPACING            =,          /* Column spacing for individual variables */
   WIDTHS                =           /* Column widths */
   );                   
                        
   /*                   
   / Echo the macro nam e and version to the log. Also echo the parameter values
   / and values of glob al macro variables used by this macro.
   /------------------- --------------------------------------------------------*/
                        
   %local MacroVersion;
   %let MacroVersion = 1;

   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals(); 

   /*
   / Define local macro variables
   /---------------------------------------------------------------------------*/

   %local prefix l_i if_statement decode_label l_flag rx1 rx2 rx3 rx4 pos len l_tmp;
   %let prefix=_tdae13;
   %let l_flag=0;

   /*
   / Parameter validation
   /---------------------------------------------------------------------------*/

   %if %nrbquote(&dsetinnumer) eq %then
   %do;   
      %put %str(RTER)ROR: &sysmacroname: Required parameter DSETINNUMER is blank.;
      %let g_abort=1;
   %end;
   %else %do;
      %if %tu_nobs(&dsetinnumer) lt 0 %then
      %do;
         %put %str(RTER)ROR: &sysmacroname: DSETINNUMER(=&dsetinnumer) does not exist.;
         %let g_abort=1;      
      %end;      
   %end;  

   %if &g_abort gt 0 %then %goto macerr;

   /*
   / Call tu_getdata to subset dsetinNumer
   /---------------------------------------------------------------------------*/

   data &prefix.dsetin;
      set &dsetinnumer;
   run;

   %tu_getdata(
      dsetin=&prefix.dsetin,
      dsetout1=&prefix.dsetin
      );

   /*
   / 1.Loop over CATGROUP# to get 'if' statement for the subset group and label for 
   /   for the group by searching 'if=(*)'  and label='*'.
   / 2.for each subset, assign the label for the group to variable tt_avnm and
   /   assign # to tt_avid
   / 3.Create a format based on tt_avid (start) and tt_avnm (label). Name it
   /   _avfmt. The format can be used in PSFORMAT. 
   /---------------------------------------------------------------------------*/

   %do l_i=1 %to 20;
      %let if_statement=;
      %let decode_label=;
      %if %nrbquote(&&catgroup&l_i) ne %then
      %do;
         %let rx1=%sysfunc(rxparse($p "IF" $w* "=" $w* [ $(10) ]));
         %let rx2=%sysfunc(rxparse($p "LABEL" $w* "=" $w* [ $q ]));
         %let rx3=%sysfunc(rxparse($q));
         %let rx4=%sysfunc(rxparse($(10)));

         %let pos=0;
         %let len=0;
         %let l_tmp=%upcase(&&catgroup&l_i);
         %syscall rxsubstr(rx1, l_tmp, pos, len);
         %syscall rxfree(rx1);
         %if &pos gt 0 and &len gt 0 %then
         %do; 
            %let if_statement=%substr(%nrbquote(&&catgroup&l_i), &pos, &len);
            %let pos=0;
            %let len=0;           
            %syscall rxsubstr(rx4, if_statement, pos, len);
            %syscall rxfree(rx4);
            %if &pos gt 0 and &len gt 0 %then
            %do; 
               %let if_statement=%substr(%nrbquote(&if_statement), &pos, &len);
            %end;
            %else %do;
               %let if_statement=;
            %end;
         %end; /* %if &pos gt 0 and &len gt 0 */

         %let pos=0;
         %let len=0;
         %syscall rxsubstr(rx2, l_tmp, pos, len);
         %syscall rxfree(rx2);
         %if &pos gt 0 and &len gt 0 %then
         %do;
            %let decode_label=%substr(%nrbquote(&&catgroup&l_i), &pos, &len);
            %let pos=0;
            %let len=0;           
            %syscall rxsubstr(rx3, decode_label, pos, len);
            %syscall rxfree(rx3);
            %if &pos gt 0 and &len gt 0 %then
            %do; 
               %let decode_label=%substr(%nrbquote(&decode_label), &pos, &len);
            %end;
            %else %do;
               %let decode_label=;
            %end;
         %end; /* %if &pos gt 0 and &len gt 0 */

         data &prefix.ae1;
            set &prefix.dsetin;
            %if %nrbquote(&if_statement) ne %then
            %do;
               if %unquote(&if_statement);
            %end;
            tt_avid=&l_i;
         run;

         %if &syserr GT 0 %then 
         %do;
            %put %str(RT)ERROR: Error occurred when applying if-statment of CATGROUP&l_i.;
            %goto macerr;
         %end;

         data &prefix.fmt1;
            length label $200;
            fmtname='_avfmt';
            type='N';
            start=&l_i;
            %if %nrbquote(&decode_label) ne %then 
            %do;               
               label=&decode_label;
            %end;
            %else %do;
               label='';
            %end;
         run;

         %if &syserr GT 0 %then 
         %do;
            %put %str(RT)ERROR: Error occurred when assigning label of CATGROUP&l_i.;
            %goto macerr;
         %end;

         %if &l_flag eq 0 %then
         %do;
            data &prefix.ae;
               set &prefix.ae1;
            run;

            data &prefix.fmt;
               set &prefix.fmt1;
            run;
         %end;
         %else %do;
            data &prefix.ae;
               set &prefix.ae &prefix.ae1;
            run;
 
            data &prefix.fmt;
               set &prefix.fmt &prefix.fmt1;
            run;
         %end; /* %if &l_flag eq 0 */           
         %let l_flag=1;
      %end; /* %if %nrbquote(&&catgroup&l_i) ne */
   %end; /* %do l_i=1 %to 20 */

   /*
   / If DSEINDENOM is the same as DESETINNUMER, assign the derived dataset to
   / DSETINDENOM. Assign the derived dataset to DESETINNUMER.
   /---------------------------------------------------------------------------*/

   %if &l_flag gt 0 %then
   %do;
      proc format cntlin=&prefix.fmt;
      run;
      
      data &prefix.ae;
         set &prefix.ae;
         length tt_avnm $200; 
         tt_avnm=put(tt_avid, _avfmt.);
         %unquote(&presubset);
      run;
      
      %if %qupcase(&dsetinnumer) eq %qupcase(&dsetindenom) %then %let dsetindenom=&prefix.ae;   
      %let dsetinnumer=&prefix.ae;
   %end; /* %if &l_flag gt 0 */

   /*
   / Call %tu_freq to create output;
   /---------------------------------------------------------------------------*/     

   %tu_freq(
      acrossColListName       = acrosscollist,
      acrossColVarPrefix      = tt_ac,
      ACROSSVAR               = &acrossvar,
      ACROSSVARDECODE         = &acrossvardecode,
      addbignyn               = Y,
      bignvarname             = tt_bnnm,
      break1                  = &break1,
      break2                  = &break2,
      break3                  = &break3,
      break4                  = &break4,
      break5                  = &break5,
      byvars                  = &byvars,
      centrevars              = &centrevars,
      codeDecodeVarPairs      = &codeDecodeVarPairs,
      colspacing              = &colspacing,
      columns                 = &columns,
      completetypesvars       = &completetypesvars,
      computebeforepagelines  = &computebeforepagelines,
      computebeforepagevars   = &computebeforepagevars,
      countDistinctWhatVar    = &countDistinctWhatVar,
      dddatasetlabel          = &dddatasetlabel,
      defaultwidths           = &defaultwidths,
      denormYN                = Y,
      descending              = &descending,
      display                 = &display,
      dsetinDenom             = &dsetindenom,
      dsetinNumer             = &dsetinnumer,
      dsetout                 = &dsetout,
      flowvars                = &flowvars,
      formats                 = &formats,
      groupByVarPop           = &groupByVarPop,
      groupByVarsDenom        = &groupByVarsDenom,
      groupByVarsNumer        = &groupByVarsNumer,
      groupminmaxvar          = &groupminmaxvar,
      idvars                  = &idvars,
      labels                  = &labels,
      labelvarsyn             = Y,
      leftvars                = &leftvars,
      linevars                = &linevars,
      noprintvars             = &noprintvars,
      nowidowvar              = &nowidowvar,
      orderdata               = &orderdata,
      orderformatted          = &orderformatted,
      orderfreq               = &orderfreq,
      ordervars               = &ordervars,
      overallsummary          = N,
      pagevars                = &pagevars,
      postSubset              = &postsubset,
      proptions               = &proptions,
      psByvars                = ,
      psClass                 = ,
      psClassOptions          = &psClassOptions,
      psFormat                = &psFormat,
      psFreq                  = ,
      psid                    = ,
      psOptions               = &psoptions,
      psOutput                = ,
      psOutputOptions         = noinherit,
      psTypes                 = ,
      psWays                  = ,
      psWeight                = ,
      remSummaryPctYN         = N,
      resultPctDps            = &resultPctDps,
      resultStyle             = &resultStyle,
      resultVarName           = tt_result,
      rightvars               = &rightvars,
      rowLabelVarName         = ,
      sharecolvars            = &sharecolvars,
      sharecolvarsindent      = &sharecolvarsindent,
      skipvars                = &skipvars,
      splitchar               = &splitchar,
      spsort2groupbyvarsdenom = ,
      spsort2groupbyvarsnumer = ,
      spsort2resultstyle      = ,
      spsort2resultvarname    = ,
      spSortGroupByVarsDenom  = &spSortGroupByVarsDenom,
      spSortGroupByVarsNumer  = &spSortGroupByVarsNumer,
      spSortResultStyle       = %if %nrbquote(&spSortResultVarName) ne %then PCT;,
      spSortResultVarName     = &spSortResultVarName,
      stackvar1               = ,                   
      stackvar10              = ,                   
      stackvar11              = ,                   
      stackvar12              = ,                   
      stackvar13              = ,                   
      stackvar14              = ,                   
      stackvar15              = ,                   
      stackvar2               = ,                   
      stackvar3               = ,                   
      stackvar4               = ,                   
      stackvar5               = ,                   
      stackvar6               = ,                   
      stackvar7               = ,                   
      stackvar8               = ,                   
      stackvar9               = ,                   
      summaryLevelVarName     = summaryLevel,
      totalDecode             = &totalDecode,
      totalForVar             = &totalForVar,
      totalID                 = &totalID,
      varlabelstyle           = SHORT,
      varspacing              = &varspacing,
      varstodenorm            = tt_result tt_pct,
      widths                  = &widths
      );

   %goto macend;

%macerr:

   %put %str(RTE)RROR: &sysmacroname: Ending with error(s);
   %let g_abort = 1;
   %tu_abort();

%macend:
   
   %tu_tidyup(
      rmdset=&prefix:,
      glbmac=NONE
      );

%mend td_ae13;


