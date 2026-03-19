/*----------------------------------------------------------------------------------------
| Macro Name    : tu_freq.sas
|
| Macro Version : 3
|
| SAS version   : SAS v8.2
|
| Created By    : Todd Palmer
|
| Date          : May-2003
|
| Macro Purpose : This unit shall be a utility to facilitate the production of IDSL
|                 standard data displays that present frequencies, as identified in
|                 the IDSL Data Display Standards[2].  To satisfy any individual data
|                 display, this utility shall be called by a "wrapper" macro that passes
|                 the appropriate parameter values to this macro.
|
| Macro Design  : Procedure Style
|
| Input Parameters :
|
| Name                Description                                       Default           
| ----------------------------------------------------------------------------------------
| ACROSSCOLLISTNAME   Name for a macro variable that will contain the   (Blank)           
|                     variable names of the result columns created.                       
|                     This will be defined as local to the calling                        
|                     macro, or as global.                                                
|                     Valid values:                                                       
|                     If DENORMYN=N, blank                                                
|                     Otherwise:                                                          
|                     Blank                                                               
|                     SAS macro variable name                                             
|                     In typical usage, this will be defined as local                     
|                     to the calling macro.                                               
|                                                                                         
| ACROSSCOLVARPREFIX  A variable name prefix for the displayable        tt_ac             
|                     columns created from the ACROSSVAR variable. The                    
|                     prefix chosen here can be used in the COLUMNS                       
|                     parameter with a colon appended to specify the                      
|                     display of all columns whose variable name                          
|                     begins with this prefix.                                            
|                     Valid values:                                                       
|                     If DENORMYN=N, blank                                                
|                     Otherwise, valid SAS variable name (prefix)                         
|                     In typical usage, tt_ac                                             
|                                                                                         
| ACROSSVAR           Variable to transpose the data across to make     (Blank)           
|                     columns of results. This is passed to the proc                      
|                     transpose ID statement hence the values of this                     
|                     variable will be used to name the new columns.                      
|                     Valid values:                                                       
|                     If DENORMYN=N, blank                                                
|                     Otherwise:                                                          
|                     Blank                                                               
|                     The name of a SAS variable that exists in                           
|                     DSETINNUMER                                                         
|                     In typical usage, this will be the variable                         
|                     containing treatment.                                               
|                                                                                         
| ACROSSVARDECODE     A variable or format used in the construction of  (Blank)           
|                     labels for the result columns.                                      
|                     Valid values:                                                       
|                     If DENORMYN=N, blank                                                
|                     Otherwise:                                                          
|                     Blank                                                               
|                     Name of a SAS variable that exists in                               
|                     DSETINNUMER                                                         
|                     An available SAS format                                             
|                                                                                         
| ADDBIGNYN           Passed to %tu_statswithtotal. Appended the        Y                 
|                     population N (N=nn) to decode, or the format if                     
|                     there is no decode, of the last variable of                         
|                     &GROUPBYVARSPOP.                                                    
|                     Valid values:                                                       
|                     Y, N                                                                
|                                                                                         
| BIGNVARNAME         Passed to %tu_statswithtotal. Specifies the name  tt_bnnm           
|                     of the variable that saves the big N values in                      
|                     the DD dataset. The variable will be created by                     
|                     %tu_freq calling %tu_addbignvar macro.                              
|                     If it is blank, the big N will not be added to                      
|                     the output                                                          
|                     Valid values:                                                       
|                     Blank if ADDBIGNYN=N                                                
|                     Otherwise, any valid SAS variable name that does                    
|                     not exist in the input dataset                                      
|                                                                                         
| CODEDECODEVARPAIRS  Passed to %tu_statswithtotal. Specifies code and  (Blank)           
|                     decode variable pairs. Those variables should be                    
|                     in parameter GROUPBYVARSNUMER. One variable in                      
|                     the pair will contain the code, which is used in                    
|                     counting and ordering, and the other will                           
|                     contain decode, which is used for presentation.                     
|                     Valid values:  Blank or a list of SAS variable                      
|                     names in pairs that are given in                                    
|                     GROUPBYVARSNUMER,                                                   
|                     e.g.ttcd trtgrp                                                     
|                                                                                         
| COMPLETETYPESVARS   Passed to %tu_statswithtotal. Specify a list of   _ALL_             
|                     variables which are in GROUPBYVARSANALY and the                     
|                     COMPLETETYPES given by PSOPTIONS should be                          
|                     applied to. If it equals _ALL_, all variables in                    
|                     GROUPBYVARSANALY will be included.                                  
|                     Valid values:                                                       
|                     _ALL_                                                               
|                     A list of variable names which are in                               
|                     GROUPBYVARSANALY                                                    
|                                                                                         
| COUNTDISTINCTWHATV  Variable(s) that contain values to be counted     &g_centid         
| AR                  uniquely within any output grouping.              &g_subjid         
|                     Valid values:                                                       
|                     Blank                                                               
|                     Name of one or more SAS variables that exists in                    
|                     DSETINNUMER                                                         
|                                                                                         
| DENORMYN            Transpose VARSTODENORM from rows to columns       N                 
|                     across the ACROSSVAR  Y/N                                          
|                     Valid values:                                                       
|                     Y, N                                                                
|                                                                                         
| DISPLAY             Specifies whether the report should be created.   Y                 
|                     Valid values:                                                       
|                     Y, N                                                                
|                     If &g_analy_disp is D, DISPLAY shall be ignored                     
|                                                                                         
| DSETINDENOM         Input dataset containing data to be counted to    (Blank)           
|                     obtain the denominator. This may or may not be                      
|                     the same as the dataset specified to                                
|                     DSETINNUMER.                                                        
|                     Valid values:                                                       
|                     &g_popdata                                                          
|                     Any valid SAS dataset reference; dataset options                    
|                     are supported.  In typical usage, specifies                         
|                     &G_POPDATA                                                          
|                                                                                         
| DSETINNUMER         Input dataset containing data to be counted to    (Blank)           
|                     obtain the numerator.                                               
|                     Valid values:                                                       
|                     Any valid SAS dataset reference; dataset options                    
|                     are supported.                                                      
|                                                                                         
| DSETOUT             Name of output dataset                            (Blank)           
|                     Valid values: Dataset name                                          
|                                                                                         
| GROUPBYVARPOP       Passed to GROUPBYVARSANALY of                     &g_trtcd          
|                     %tu_statswithtotal. Specifies a list of                             
|                     variables to group by when counting big N using                     
|                     %tu_addbignvar. Usually one variable &g_trtcd.                      
|                     It will be passed to GROUPBYVARS of                                 
|                     %tu_addbignvar.                                                     
|                     Required if ADDBIGNYN =Y                                            
|                     Valid values:                                                       
|                     Blank if ADDBIGNYN=N                                                
|                     Otherwise, a list of valid SAS variable names                       
|                     that exist in population dataset created by                         
|                     %tu_freq's calling %tu_getdata                                      
|                                                                                         
| GROUPBYVARSDENOM    Passed to %tu_statswithtotal. Variables in        (Blank)           
|                     DSETINDENOM to group the data by when counting                      
|                     to obtain the denominator.                                          
|                     Valid values:                                                       
|                     Blank, _NONE_ (to request an overall total for                      
|                     the whole dataset)                                                  
|                     Name of a SAS variable that exists in                               
|                     DSETINDENOM                                                         
|                                                                                         
| GROUPBYVARSNUMER    Passed to %tu_statswithtotal. Variables in        (Blank)           
|                     DSETINNUMER to group the data by when counting                      
|                     to obtain the numerator. Additionally a set of                      
|                     brackets may be inserted within the variables to                    
|                     generate records containing summary counts                          
|                     grouped by variables specified to the left of                       
|                     the brackets. Summary records created may be                        
|                     populated with values in the grouping variables                     
|                     by specifying variable value pairs within                           
|                     brackets, separated by semicolons. eg aesoccd                       
|                     aesoc(aeptcd=0; aept="Any Event";) aeptcd aept.                     
|                     Valid values:                                                       
|                     Blank, _NONE_ (to request an overall total for                      
|                     the whole dataset)                                                  
|                     Name of one or more SAS variables that exist in                     
|                     DSETINNUMER                                                         
|                     SAS assignment statements within brackets                           
|                                                                                         
| GROUPMINMAXVAR      Specify if frequency of each group should be get  (Blank)       
|                     from minimum or maximum value of variable(s) in                     
|                     format MIN(variables). The first or last value                      
|                     of the variable(s) in each subgroup of                              
|                     &GROUPBYVARSANALY for &COUNTDISTINCWHATVAR will                     
|                     be created before calculating the frequency.                        
|                     Valid values:                                                       
|                     Blank                                                               
|                     MIN({variable(s)})                                                  
|                     MAX({variable(s)})                                                  
|                     NOTE: {variables} means a list of valid SAS                         
|                     variable that exists in DSETIN                                      
|                                                                                         
| POSTSUBSET          SAS expression to be applied to data immediately  (Blank)           
|                     prior to creation of the permanent presentation                     
|                     dataset. Used for subsetting records required                       
|                     for computation but not for display.                                
|                     Valid values:                                                       
|                     Blank                                                               
|                     A complete, syntactically valid SAS where or if                     
|                     statement for use in a data step                                    
|                                                                                         
| PSCLASSOPTIONS      Passed to %tu_statswithtotal. PROC SUMMARY Class  (Blank)           
|                     Statement Options.                                                  
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
| PSOPTIONS           Passed to %tu_statswithtotal. PROC SUMMARY        COMPLETETYPES     
|                     Options to use. MISSING ensures that class        MISSING NWAY      
|                     variables with missing values are treated as a                      
|                     valid grouping. COMPLETETYPES adds records                          
|                     showing a freq or n of 0 to ensure a cartesian                      
|                     product of all class variables exists in the                        
|                     output. NWAY writes output for the lowest level                     
|                     combinations of CLASS variables, suppressing all                    
|                     higher level totals.                                                
|                     Valid values:                                                       
|                     Blank                                                               
|                     One or more valid PROC SUMMARY options                              
|                                                                                         
| REMSUMMARYPCTYN     Passed to %tu_statswithtotal. Remove summary      N                 
|                     level percentage Y/N. Setting to Y keeps only                       
|                     the first character string of the field                             
|                     requested by the RESULTSTYLE parameter. Valid                       
|                     values:                                                             
|                     Y, N                                                                
|                     In typical usage, in conjunction with                               
|                     RESULSTYLE=NUMERPCT, this shows the n count for                     
|                     a group without the percentage, where the count                     
|                     shows the denominator used within a group.                          
|                                                                                         
| RESULTPCTDPS        Passed to %tu_statswithtotal. The reporting       0                 
|                     precision for percentages                                           
|                     Valid values:                                                       
|                     As documented for tu_percent in [6]                                 
|                                                                                         
| RESULTSTYLE         Passed to %tu_statswithtotal. The appearance      NUMERPCT          
|                     style of the result columns that will be                            
|                     displayed in the report. The chosen style will                      
|                     be placed in variable &RESULTVARNAME.                               
|                     Valid values:                                                       
|                     As documented for tu_percent in [6]. In typical                     
|                     usage, NUMERPCT.                                                    
|                                                                                         
| RESULTVARNAME       Passed to %tu_statswithtotal. Name of the         tt_result         
|                     variable to hold the result of the frequency                        
|                     count                                                               
|                     Valid values:                                                       
|                     Valid SAS variable name                                             
|                     If DENORMYN=Y, variable listed in VARSTODENORM                      
|                                                                                         
| ROWLABELVARNAME     Passed to ANALYSISVARNAME of %tu_statswithtotal.  (Blank)           
|                     Name of variable to be created to hold the label                    
|                     of the last variable mentioned in                                   
|                     GROUPBYVARSNUMER. Eg tt_grpLabel                                    
|                     Valid values:                                                       
|                     Blank                                                               
|                     Valid SAS variable name                                             
|                     Valid SAS assignment statement eg                                   
|                     tt_grplabel=vlabel(sex)                                             
|                     Note any variables referred to using the                            
|                     assignment syntax must exist in                                     
|                     GROUPBYVARSNUMER.                                                   
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
| SPSORTGROUPBYVARSN  Special sort: variables in DSETINNUMER to group   (Blank)           
| UMER                the data by when counting to obtain the                             
|                     numerator.                                                          
|                     Valid values:                                                       
|                     Blank if SPSORTRESULTVARNAME is blank                               
|                     Otherwise,                                                          
|                     Name of one or more SAS variables that exist in                     
|                     DSETINNUMER                                                         
|                                                                                         
| SPSORTRESULTSTYLE   Special sort: the appearance style of the result  NUMERPCT          
|                     data that will be used to sequence the report.                      
|                     The chosen style will be placed in variable                         
|                     SPSORTRESULTVARNAME                                                 
|                     Valid values:                                                       
|                     Blank if SPSORTRESULTVARNAME is blank                               
|                     Otherwise, as documented for tu_percent in [6].                     
|                     In typical usage, NUMERPCT.                                         
|                                                                                         
| SPSORTRESULTVARNAM  Special sort: the name of a variable to be        (Blank)           
| E                   created to hold the spSortResultStyle data when                     
|                     merging the special sort sequence records with                      
|                     the presentation data records.                                      
|                     Valid values:                                                       
|                     Blank                                                               
|                     A valid SAS variable name.                                          
|                     Eg tt_spSort.                                                       
|                     This variable is likely to be included in the                       
|                     columns and noprint parameters passed to                            
|                     tu_list.                                                            
|                                                                                         
| SUMMARYLEVELVARNAM  Passed to %tu_statswithtotal. Name for variable   TT_SUMMARYLEVEL   
| E                   that will contain the iteration number of the                       
|                     summaries requested via the GROUPBYVARSNUMER                        
|                     parameter.                                                          
|                     Valid values:                                                       
|                     Blank                                                               
|                     A valid SAS variable name.                                          
|                                                                                         
| TOTALDECODE         Passed to %tu_statswithtotal. Value(s) used to    (Blank)           
|                     populate the variable(s) of the decode                              
|                     variable(s) of the TOTALFORVAR. If a value has                      
|                     more than one word, the value should be quoted                      
|                     with single or double quote                                         
|                     Valid values:                                                       
|                     Blank                                                               
|                     A list of values that can be entered into the                       
|                     decode of the TOTALFORVAR variable(s) without                       
|                     SAS error or truncation                                             
|                                                                                         
| TOTALFORVAR         Passed to %tu_statswithtotal. Variable for which  (Blank)           
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
|                     Valid values:                                                       
|                     Can be one or a list of followings:                                 
|                     1. Blank                                                            
|                     2. Name of a variable                                               
|                     3. Variable with sub group of values inside of                      
|                     ( and )                                                         
|                     4. A list of 2 or 3 separated by *                                
|                                                                                         
| TOTALID             Passed to %tu_statswithtotal. Value(s) used to    (Blank)           
|                     populate the variable(s) specified in                               
|                     TOTALFORVAR.                                                        
|                     Valid values:                                                       
|                     Blank                                                               
|                     A list of values that can be entered into                           
|                     &TOTALFORVAR without SAS error or truncation                        
|                                                                                         
| VARSTODENORM        Result variable(s) to be retained, and, if        (Blank)           
|                     DENORMYN=Y, also denormalised (i.e. transposed                      
|                     from rows to columns across the ACROSSVAR).                         
|                     Valid values:,                                                      
|                     If DENORMYN=N, blank                                                
|                     Otherwise: one or more of:                                          
|                     &RESULTVARNAME (the display variable, with                          
|                     appearance as specified by RESULTSTYLE)                             
|                     Other (non-display) variables created by                            
|                     tu_percent as documented in [6]; in typical                         
|                     usage, these are used for sequencing the data.  
|
| Parameters, with default values, that pass to macro TU_STATS
|     PSBYVARS=(Blank),  PSCLASS=(Blank),  PSCLASSOPTIONS=(Blank),  PSFORMAT=(Blank),  
|     PSFREQ=(Blank),  PSID=(Blank),  PSOPTIONS=Missing NWAY,  PSOUTPUT=(Blank),  
|     PSOUTPUTOPTIONS=(Blank),  PSTYPES=(Blank),  PSWAYS=(Blank),  PSWEIGHT=(Blank)
|
| Parameters, with default values, that pass to macro TU_LIST
|     BREAK1-BREAK5=(Blank),  BYVARS=(Blank),  CENTREVARS=(Blank),  COLSPACING=2,  
|     COLUMNS=(Blank), COMPUTEBEFOREPAGELINES=(Blank),  COMPUTEBEFOREPAGEVARS=(Blank),  
|     DDDATASETLABEL=(Blank), DEFAULTWIDTHS=(Blank),  DESCENDING=(Blank),  DISPLAY=Y,  
|     FLOWVARS=_All_,  FORMATS=(Blank), IDVARS=(Blank),  LABELS=(Blank),  LABELVARSYN=Y,  
|     LEFTVARS=(Blank),  LINEVARS=(Blank), NOPRINTVARS=(Blank),  NOWIDOWVAR=(Blank),  
|     ORDERDATA=(Blank),  ORDERFORMATTED=(Blank), ORDERFREQ=(Blank),  ORDERVARS=(Blank), 
|     OVERALLSUMMARY=N,  PAGEVARS=(Blank),  PROPTIONS=Headline, RIGHTVARS=(Blank),  
|     SHARECOLVARS=(Blank),  SHARECOLVARSINDENT=2,  SKIPVARS=(Blank),  SPLITCHAR=~,  
|     STACKVAR1-STACKVAR15=(Blank),  VARLABELSTYLE=SHORT,  VARSPACING=(Blank),  
|     WIDTHS=(Blank)
|
| ----------------------------------------------------------------------------------------
| Output:   1. an output file in plain ASCII text format containing a summary in columns data
|              display matching the requirements specified as input parameters.
|           2. SAS data set that forms the foundation of the data display (the "DD dataset").
|
| ----------------------------------------------------------------------------------------
| Global macro variables created:
|   none
|
| ----------------------------------------------------------------------------------------
| Macros called :
| (@) tr_putlocals
| (@) tu_abort         
| (@) tu_denorm        
| (@) tu_getdata       
| (@) tu_labelvars     
| (@) tu_list          
| (@) tu_nobs          
| (@) tu_pagenum       
| (@) tu_percent       
| (@) tu_putglobals    
| (@) tu_stats         
| (@) tu_statswithtotal
| (@) tu_tidyup        
|
| ----------------------------------------------------------------------------------------
| Example:
|
|   of DM1 type display segment
|
| %tu_freq(dsetinNumer = ardata.demo
|          ,dsetinDenom = ardata.demo
|          ,countDistinctWhatVar = &g_centid &g_subjid
|          ,groupByVarsNumer = &g_trtcd (sex="n") sex
|          ,groupByVarsDenom = &g_trtcd
|          ,totalforvar = &g_trtcd
|          ,totalid = 9999
|          ,remSummaryPctYN = Y
|          ,addbignyn = Y
|          ,bignvarname = tt_bignvarname
|          ,groupbyvarpop = &g_trtcd
|          ,denormYN = N
|          ,rowlabelvarname = tt_grplabel
|          ,summaryLevelVarName = tt_sumylvl
|          ,display = N
|          ,dsetout = freq_dsetOut
|          )
|
|
|   of AE1 type data gathering
|
|%tu_freq(
|      dsetinNumer          = ardata.ae
|    , countDistinctWhatVar = &g_centid &g_subjid
|    , groupByVarsNumer     = &g_trtcd (aesoc='DUMMY'; aept='ANY EVENT') aesoc (aept='Any event') aept
|    , dsetinDenom          = &g_popdata
|    , groupByVarsDenom     = &g_trtcd
|    , totalForVar          = &g_trtcd
|    , totalID              = 9999
|    , totalDecode          = Total
|    , resultStyle          = numerPct
|    , resultVarName        = mytt_result
|    , resultPctDps         = 0
|    , rowLabelVarName      =
|    , groupByVarPop        = &g_trtcd
|    , denormYN             = Y
|    , varsToDenorm         = mytt_result tt_pct
|    , acrossVar            = &g_trtcd
|    , acrossVarDecode      = &g_trtgrp
|    , acrossColVarPrefix   = tt_result tt_pct
|    , acrossColListName    = acrosscols
|    , addBigNYN            = Y
|    , bigNVarName          = myBigN
|    , spSortGroupByVarsNumer = aesoc
|    , spSortGroupByVarsDenom = _none_
|    , spSortResultStyle    = pct
|    , spSortResultVarName  = tt_spsort
|    , postSubset           = where tt_pct9999 gt 0
|    , display              = N
|    , splitChar            = ~
|    , psOptions            = completetypes missing nway
|    , psClassOptions       =
|    , psFormat             =
|    , psOutputOptions      =
|    , dsetout = freq_dsetOut
|    )
|
| ----------------------------------------------------------------------------------------
| Change Log :
|
| Modified By : Todd Palmer
| Date of Modification : 6Oct2003
| New Version Number : 1/2
| Modification ID : 001
| Reason For Modification : SCR comments
|
| ----------------------------------------------------------------------------------------
| Modified By : Dave Booth
| Date of Modification : 9Oct2003
| New Version Number : 1/3
| Modification ID : DB001
| Reason For Modification :  If no totalid reqd, skip the more
|                             complex code and do something simple.
|
| ----------------------------------------------------------------------------------------
| Modified By : Todd Palmer
| Date of Modification : 16Oct2003
| New Version Number : 1/4
| Modification ID : TP002
| Reason For Modification :  UTC testing:
|                            - parm validation;
|                            - reduced parms being passed to tu_stats for other than stats numerator data
|                            UAT testing:
|                            - moved validation of pop/denom vars to after tu_getdata
|                            Code Updates:
|                            - groupByVarsNumer array modified depending on value of psByVars
|                              and psByVars passed to tu_stats modified depending on groupByVarsNumer array.
|                            - spSort2 parms and processing added but usage suppressed
|                            - pass value of LABELVARSYN parameter to tu_list.
|
| ----------------------------------------------------------------------------------------
| Modified By : Tamsin Corfield
| Date of Modification : 21Oct2003
| New Version Number : 1/5
| Modification ID : None
| Reason For Modification :   Removed ; form comment associated with 
|                             pagevars and skipvars, in order to be able 
|                             to check the macro into the application. 
|
| ----------------------------------------------------------------------------------------
| Modified By :              Yongwei Wang
| Date of Modification :     12-Jul-2004
| New Version Number :       2/1
| Modification ID :          None
| Reason For Modification :  Modified to make %tu_freq to call new macro 
|                            %tu_statswithtotals. Many functions in old version of 
|                            %tu_freq, like adding big N, calculating percent, have been 
|                            moved to %tu_statswithtotals.  
| ----------------------------------------------------------------------------------------
| Modified By :              Yongwei Wang
| Date of Modification :     22-Sep-2004
| New Version Number :       2/2
| Modification ID :          YW001
| Reason For Modification :  1. Removed calling of %tu_getdata on denorminator data set.
|                            2. Changed one '&_thisword' to '&l_thisword'
| ----------------------------------------------------------------------------------------
| Modified By :              Yongwei Wang
| Date of Modification :     28-Sep-2004
| New Version Number :       2/3
| Modification ID :          YW002
| Reason For Modification :  Add a code to check if the dsetindenom equals &g_popdata.
|                            The version 2/2 removed the call of %tu_getdata, but the
|                            popdata can not be subseted. I think the %tu_getdata need
|                            to be modified in the future.
| ----------------------------------------------------------------------------------------
| Modified By :              Yongwei Wang
| Date of Modification :     01-Oct-2004
| New Version Number :       2/4
| Modification ID :          YW003
| Reason For Modification :  Add a code to do more parameter check. It includes:
|                            1. Check name of &ACROSSVARAdded, RESULTVARNAME of the special 
|                               sort, &dsetinnumer and &dsetindenom
|                            2. Check if TOTALFORVAR is not blank if TOTALID is not blank.
|                            3. Check if &RESULTSTYLE, &RESULTPCTDPS or &RESULTVARNAME is blank
|                            4. Add a check on ACROSSVARDECODE and ACROSSVAR should be blank 
|                               if DENORMYN equals N.
|
|                            Modified the code when the ACROSSVARDECODE is a format.
| ----------------------------------------------------------------------------------------
| Modified By :              Yongwei Wang
| Date of Modification :     06-Oct-2004
| New Version Number :       2/5
| Modification ID :          YW004
| Reason For Modification :  1. Changed the checking on DSETINNUMER and DSETINDENOM to remove
|                               the data set options before checking.
|                            2. Set parameter countdistinctwhatvar to &countdistinctwhatvar
|                               when calling tu_statswithtotal to calculate special sort.
| ----------------------------------------------------------------------------------------
| Modified By :              Yongwei Wang
| Date of Modification :     09-Oct-2004
| New Version Number :       2/6
| Modification ID :          YW005
| Reason For Modification :  1. Changed to calling of %tu_getdata, even though it may cause 
|                               SAS errors, but we need it.
|                            2. Added code to get min/max value before calculation special
|                               sort.
| ----------------------------------------------------------------------------------------
| Modified By :              Yongwei Wang
| Date of Modification :     08-Dec-2004
| New Version Number :       3/1
| Modification ID :          YW006
| Reason For Modification :  Added debugging code required by change request form
|                            HRT0066 
|----------------------------------------------------------------------------------------*/
%macro tu_freq(
      ACROSSCOLLISTNAME      =                     /* Name for a macro variable that will contain the variable names of the result columns created. */
    , ACROSSCOLVARPREFIX     =tt_ac                /* A variable name prefix for the displayable columns created from the ACROSSVAR variable. */
    , ACROSSVAR              =                     /* Variable to transpose the data across to make columns of results. This is passed to the proc transpose ID statement */
    , ACROSSVARDECODE        =                     /* A variable or format used in the construction of labels for the result columns. Usually &g_trtgrp */
    , ADDBIGNYN              =N                    /* Add the population N information - Y/N */
    , BIGNVARNAME            =tt_bnnm              /* Variable name that saves big N values in the DD dataset */
    , BREAK1                 =                     /* Break statements. */
    , BREAK2                 =                     /* Break statements. */
    , BREAK3                 =                     /* Break statements. */
    , BREAK4                 =                     /* Break statements. */
    , BREAK5                 =                     /* Break statements. */
    , BYVARS                 =                     /* By variables */
    , CENTREVARS             =                     /* Centre justify variables */
    , CODEDECODEVARPAIRS     =                     /* Code and Decode variables in pairs */
    , COLSPACING             =2                    /* Overall spacing value. */
    , COLUMNS                =                     /* Column parameter */
    , COMPLETETYPESVARS      =_all_                /* Variables which COMPLETETYPES should be applied to */ 
    , COMPUTEBEFOREPAGELINES =                     /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt colon labelvar) */
    , COMPUTEBEFOREPAGEVARS  =                     /* Names of variables that shall define the sort order for Compute Before Page lines */
    , COUNTDISTINCTWHATVAR   =&g_centid &g_subjid  /* Variable(s) that contain values to be counted uniquely within any output grouping. Eg &g_subjid */
    , DDDATASETLABEL         =DD dataset for a table /* Label to be applied to the DD dataset */
    , DEFAULTWIDTHS          =                     /* List of default column widths */
    , DENORMYN               =N                    /* Transpose VARSTODENORM from rows to columns across the ACROSSVAR - Y/N */
    , DESCENDING             =                     /* Descending ORDERVARS */
    , DISPLAY                =Y                    /* Specifies whether the report should be created */
    , DSETINDENOM            =                     /* Input dataset containing data to be counted to obtain the denominator. */
    , DSETINNUMER            =                     /* Input dataset containing data to be counted to obtain the numerator. */
    , DSETOUT                =                     /* Name of output dataset */
    , FLOWVARS               =_ALL_                /* Variables with flow option */
    , FORMATS                =                     /* Format specification */
    , GROUPBYVARPOP          =                     /* Variables to group by when counting big N  */
    , GROUPBYVARSDENOM       =                     /* Variables in DSETINDENOM to group the data by when counting to obtain the denominator. */
    , GROUPBYVARSNUMER       =                     /* Variables in DSETINNUMER to group the data by when counting to obtain the numerator. */
    , GROUPMINMAXVAR         =                     /* Specify if frequency of each group should be from first or last value of a variable in format MIN(variables) */ 
    , IDVARS                 =                     /* ID variables */
    , LABELS                 =                     /* Label definitions. */
    , LABELVARSYN            =Y                    /* Control execution of tu_labelvars */
    , LEFTVARS               =                     /* Left justify variables */
    , LINEVARS               =                     /* Order variable printed with line statements. */
    , NOPRINTVARS            =                     /* No print vars (usually used to order the display) */
    , NOWIDOWVAR             =                     /* Not in version 1 */
    , ORDERDATA              =                     /* ORDER=DATA variables */
    , ORDERFORMATTED         =                     /* ORDER=FORMATTED variables */
    , ORDERFREQ              =                     /* ORDER=FREQ variables */
    , ORDERVARS              =                     /* Order variables */
    , OVERALLSUMMARY         =N                    /* Overall summary line at top of tables */
    , PAGEVARS               =                     /* Break after <var> / page */
    , POSTSUBSET             =                     /* SAS expression to be applied to data immediately prior to creation of the permanent presentation dataset */
    , PROPTIONS              =headline             /* PROC REPORT statement options */
    , PSBYVARS               =                     /* Advanced Usage: Passed to the PROC SUMMARY By statement. This will cause the data to be sorted first. */
    , PSCLASS                =                     /* Advanced usage: Passed to the PROC SUMMARY CLASS Statement */
    , PSCLASSOPTIONS         =                     /* PROC SUMMARY Class statement options */
    , PSFORMAT               =                     /* Passed to the PROC SUMMARY FORMAT statement. */
    , PSFREQ                 =                     /* Advanced usage: Passed to the PROC SUMMARY Freq statement */
    , PSID                   =                     /* Advanced usage: Passed to the PROC SUMMARY Id Statement */
    , PSOPTIONS              =COMPLETETYPES MISSING NWAY /* PROC SUMMARY statement options to use */
    , PSOUTPUT               =                     /* Advanced usage: Passed to the PROC SUMMARY Output statement. */
    , PSOUTPUTOPTIONS        =noinherit            /* Passed to the PROC SUMMARY Output options statement part. */
    , PSTYPES                =                     /* Advanced Usage: Passed to the PROC SUMMARY Types statement */
    , PSWAYS                 =                     /* Advanced Usage: Passed to the PROC SUMMARY Ways statement. */
    , PSWEIGHT               =                     /* Advanced Usage: Passed to the PROC SUMMARY Weight statement. */
    , REMSUMMARYPCTYN        =N                    /* Remove summary level percentage Y/N */
    , RESULTPCTDPS           =0                    /* The reporting precision for percentages */
    , RESULTSTYLE            =NUMERPCT             /* The appearance style of the result columns that will be displayed in the report. */
    , RESULTVARNAME          =tt_result            /* Name of the variable to hold the result of the frequency count */
    , RIGHTVARS              =                     /* Right justify variables */
    , ROWLABELVARNAME        =                     /* Name of variable to be created to hold the label of the last variable mentioened in GROUPBYVARSNUMER. Eg tt_grpLabel */
    , SHARECOLVARS           =                     /* Order variables that share print space. */
    , SHARECOLVARSINDENT     =2                    /* Indentation factor */
    , SKIPVARS               =                     /* Break after <var> / skip */
    , SPLITCHAR              =~                    /* The split character used in column labels. */
    , SPSORT2GROUPBYVARSDENOM=                     /* Special sort2: variables in DSETINDENOM to group the data by when counting to obtain the denominator. */
    , SPSORT2GROUPBYVARSNUMER=                     /* Special sort2: variables in DSETINNUMER to group the data by when counting to obtain the numerator. */
    , SPSORT2RESULTSTYLE     =                     /* Special sort2: the appearance style of the result data that will be used to sequence the report. */
    , SPSORT2RESULTVARNAME   =                     /* Special sort2: the name of a variable to be created to hold the spSortResultStyle data when merging the special sort sequence records with the presentation data records.*/
    , SPSORTGROUPBYVARSDENOM =                     /* Special sort: variables in DSETINDENOM to group the data by when counting to obtain the denominator. */
    , SPSORTGROUPBYVARSNUMER =                     /* Special sort: variables in DSETINNUMER to group the data by when counting to obtain the numerator. */
    , SPSORTRESULTSTYLE      =                     /* Special sort: the appearance style of the result data that will be used to sequence the report. */
    , SPSORTRESULTVARNAME    =                     /* Special sort: the name of a variable to be created to hold the spSortResultStyle data when merging the special sort sequence records with the presentation data records. */
    , STACKVAR1              =                     /* Create Stacked variables (e.g. stackvar1=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
    , STACKVAR10             =                     /* Create Stacked variables (e.g. stackvar10=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~))*/
    , STACKVAR11             =                     /* Create Stacked variables (e.g. stackvar11=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~))*/
    , STACKVAR12             =                     /* Create Stacked variables (e.g. stackvar12=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~))*/
    , STACKVAR13             =                     /* Create Stacked variables (e.g. stackvar13=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~))*/
    , STACKVAR14             =                     /* Create Stacked variables (e.g. stackvar14=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~))*/
    , STACKVAR15             =                     /* Create Stacked variables (e.g. stackvar15=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~))*/
    , STACKVAR2              =                     /* Create Stacked variables (e.g. stackvar2=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
    , STACKVAR3              =                     /* Create Stacked variables (e.g. stackvar3=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
    , STACKVAR4              =                     /* Create Stacked variables (e.g. stackvar4=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
    , STACKVAR5              =                     /* Create Stacked variables (e.g. stackvar5=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
    , STACKVAR6              =                     /* Create Stacked variables (e.g. stackvar6=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
    , STACKVAR7              =                     /* Create Stacked variables (e.g. stackvar7=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
    , STACKVAR8              =                     /* Create Stacked variables (e.g. stackvar8=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
    , STACKVAR9              =                     /* Create Stacked variables (e.g. stackvar9=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
    , SUMMARYLEVELVARNAME    =tt_summaryLevel      /* Name for variable that will contain the iteration number of the summaries requested via the GROUPBYVARSNUMER parameter. */
    , TOTALDECODE            =                     /* Value(s) used to populate the variable(s) of the decode variable(s) of the TOTALFORVAR. */
    , TOTALFORVAR            =                     /* Variable for which a total is required */
    , TOTALID                =                     /* Value(s) used to populate the variable(s) specified in TOTALFORVAR. */
    , VARLABELSTYLE          =Short                /* Specifies the label style for variables (SHORT or STD) */
    , VARSPACING             =                     /* Spacing for individual variables. */
    , VARSTODENORM           =                     /* Result variable(s) required to be retained, and also denormalised if DENORMYN=Y. */
    , WIDTHS                 =                      /* Column widths */
    );
 
   /*
   / Write details of macro start to log
   /-------------------------------------------------------------------------*/  
   %local MacroVersion;
   %let MacroVersion = 3;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals(varsin=G_DDDATASETNAME G_POPDATA G_POP G_SUBPOP G_SUBSET G_CENTID G_SUBJID)
   
   %local l_splitchar l_acrossvardecode l_groupbyvarsnumer_byvars 
          l_adddecodestatements l_codedecodevarpairs l_prefix l_numervarname
          l_denomvarname l_rc l_thisword l_wordlist l_i l_j l_message l_rowlabelvarname_names
          l_lastdsetinnumer l_lastdsetindenom l_tmp l_varprefix l_lastdset l_dsetinspsort;
          
   %let l_prefix=_tufreq;
   %let l_numervarname=tt_numercnt;
   %let l_denomvarname=tt_denomcnt;
   %let l_rc=0;
   %let l_varprefix=tt0_;
   
   /* 
   /  Delete any currently existing display file     
   /-------------------------------------------------------------------------*/       
   %tu_pagenum(usage=DELETE)
   %if %nrbquote(&g_abort) gt 0 %then %goto macerr;
   /* 
   / If GD_ANALY_DISPLAY is yes, goto display.
   /-------------------------------------------------------------------------*/ 
   %if %nrbquote(&G_ANALY_DISP) eq D %then %do;
      /* check if data set G_DDDATASETNAME exist and is not empty */
      %let l_rc=%tu_nobs(&G_DDDATASETNAME);
      %if &g_abort EQ 1 %then %do;
         %let l_message=Error is found when calling TU_NOBS.;
         %goto macerr;
      %end;
     
      %if &l_rc eq -1 %then %do;
          %let l_message=Input data set G_DDDATASETNAME=&G_DDDATASETNAME does not exist;
          %goto macerr;
      %end;
     
      %if %nrbquote(&acrosscollistname) ne %then %do;
         %if %sysfunc(indexw(%qupcase(&columns), %nrstr(&)%qupcase(&acrosscollistname))) gt 0 %then %do;         
            %let l_message=G_ANALY_DISP equals D, but value of ACROSSCOLISTNAME is in the parameter COLUMN. The macro can not resolve it;
            %goto macerr;
         %end;      
      %end; /* end-if on &acrosscollistname is not blank */
       
      %let l_lastdset=&G_DDDATASETNAME;
      %goto DISPLAYIT;
   %end;  /* end-if on &G_ANALY_DISP eq D */ 
   
   /* if _NONE_ value supplied to any of the &groupByVars parameters then set
   /  them to nothing
   /----------------------------------------------------------------------------------*/
 
   %let l_wordList=groupByVarsNumer groupByVarsDenom spSortgroupByVarsNumer spSortgroupByVarsDenom spSort2groupByVarsNumer spSort2groupByVarsDenom groupByVarPop;
   %do i = 1 %to 7;
      %let l_thisWord = %scan(&l_wordlist, &i);
      %if %qupcase(&&&l_thisWord) eq _NONE_ %then %do;
         %put RTN%str(OTE): &sysmacroname: Macro parameter passed in as: %upcase(&l_thisWord)=&&&l_thisWord;
         %let &l_thisWord = ;
         %put RTN%str(OTE): &sysmacroname: Updated the value of macro parameter: %upcase(&l_thisWord)=&&&l_thisWord; /* YW001: */
      %end;
   %end; /* end of do-to loop */
       
   /*
   / Parameter validation:
   /
   / Check if &DSETINNUMER is blank.
   /-------------------------------------------------------------------------*/  
   %if %nrbquote(&dsetinnumer) eq %then %do;
      %let l_message=Value of parameter DSETINNUMER is blank, but it is required.;
      %goto macerr;   
   %end;
      
   /*
   / YW003: Check if &RESULTSTYLE, &RESULTPCTDPS or &RESULTVARNAME is blank.
   /-------------------------------------------------------------------------*/  
   %if %nrbquote(&resultstyle) eq %then %do;
      %let l_message=Value of parameter RESULTSTYLE is blank, but it is required.;
      %goto macerr;   
   %end;   
   %if %nrbquote(&resultvarname) eq %then %do;
      %let l_message=Value of parameter RESULTVARNAME is blank, but it is required.;
      %goto macerr;   
   %end;
   %if %nrbquote(&resultpctdps) eq %then %do;
      %let l_message=Value of parameter RESULTPCTDPS is blank, but it is required.;
      %goto macerr;   
   %end;
   /*
   / YW003: Check TOTALFORVAR
   /-------------------------------------------------------------------------*/  
   %if ( %nrbquote(&totalid) ne ) and ( %nrbquote(&totalforvar) eq ) %then %do;
      %let l_message=TOTALID is given and thus TOTAL is required, but TOTALFORVAR is blank. ;
      %goto macerr;
   %end;   
   
   /* 
   / YW003: Check &dsetinnumer and &dsetindenom 
   / YW004: Changed &dsetinnumer to %scan(&dsetinnumer, 1, %str(%() ) when
   /        calling %tu_chknames.
   /-------------------------------------------------------------------------*/
   %if %nrbquote(&dsetinnumer) eq %then %do;
      %let l_message=Macro Parameter DSETINNUMER is blank, but it is required.;
      %goto macerr;
   %end;
   %else %do;
      %if %tu_chknames(%scan(&dsetinnumer, 1, %str(%() ), DATA ) ne %then %do;
         %let l_message=Macro Parameter DSETINNUMER refers to dataset &dsetinnumer which is not a valid dataset name;
         %goto macerr;
      %end;
   %end;
   
   %if %nrbquote(&dsetindenom) eq %then %do;
      %let l_message=Macro Parameter DSETINDENOM is blank, but it is required.;
      %goto macerr;
   %end;
   %else %do;
      %if %tu_chknames(%scan(&dsetindenom, 1, %str(%() ), DATA ) ne %then %do;
         %let l_message=Macro Parameter DSETINDENOM refers to dataset &dsetindenom which is not a valid dataset name;
         %goto macerr;
      %end;
   %end;
            
   /*
   / If any YES/NO variable has valid value.
   /-------------------------------------------------------------------------*/       
   %let l_wordlist=DISPLAY DENORMYN LABELVARSYN OVERALLSUMMARY REMSUMMARYPCTYN;  
   %do l_i = 1 %to 5;
      %let l_thisword = %scan(&l_wordlist, &l_i);
      %if ( %qupcase(&&&l_thisword) ne Y ) and ( %qupcase(&&&l_thisword) ne N ) %then %do;
         %let l_message=Value of parameter &l_thisword is invalid. Valid value should be Y or N.;
         %goto macerr;
      %end;
   %end; /* end of do-to loop on l_i */ 
   
   /*
   / Check if any required special sort parameter is blank
   /-------------------------------------------------------------------------*/       
   %do l_i=1 %to 2; 
      %if &l_i eq 1 %then %let l_spsortnum=;
      %else %let l_spsortnum=&l_i;
            
      %if %nrbquote(&&spSort&l_spsortnum.ResultVarName) eq %then %do;
         %let l_wordlist=SPSORT&l_spsortnum.GROUPBYVARSNUMER SPSORT&l_spsortnum.GROUPBYVARSDENOM SPSORT&l_spsortnum.RESULTSTYLE;
         %do l_j = 1 %to 3;
            %let l_thisword = %scan(&l_wordlist, &l_j);
            %if %nrbquote(&&&l_thisword) ne %then %do;
               %let l_message=SPSORT&l_spsortnum.RESULTVARNAME is blank, but macro parameter &l_thisword is not blank ;
               %goto macerr;
            %end;
         %end; /* end of do-loop on l_j */          
      %end;
      %else %do;
         %if %nrbquote(SPSORT&l_spsortnum.RESULTSTYLE) eq %then %do;
            %let l_message=SPSORT&l_spsortnum.RESULTVARNAME is not blank and thus special sort is required, but macro parameter SPSORT&l_spsortnum.RESULTSTYLE is blank ;
            %goto macerr;
         %end;
         %if %nrbquote(SPSORT&l_spsortnum.GROUPBYVARSNUMER) eq %then %do;
            %let l_message=SPSORT&l_spsortnum.RESULTVARNAME is not blank and thus special sort is required, but macro parameter SPSORT&l_spsortnum.GROUPBYVARSNUMER is blank ;
            %goto macerr;
         %end;                  
         /* YW003: Added the check name of the RESULTVARNAME of the special sort */
         %if %tu_chknames(&&spSort&l_spsortnum.ResultVarName, VARIABLE) NE %then %do;
            %let l_message=SPSORT&l_spsortnum.RESULTVARNAME is not a valid SAS variable name ;
            %goto macerr;         
         %end;         
      %end; /* end-if on %nrbquote(spSort&l_spsortnum.ResultVarName) eq */
      
   %end; /* end of do-to look on l_i */
   
   /* 
   / Check variables needed for denorm are not blank
   /-------------------------------------------------------------------------*/  
   %if %qupcase(&denormYN) eq Y %then %do;
      %if (%nrbquote(&acrossVar) eq ) %then %do;
         %let l_message=DENORMYN equals Y, but the ACROSSVAR is blank;
         %goto macerr;
      %end;
      %if (%nrbquote(&varstodenorm) eq ) %then %do;
         %let l_message=DENORMYN equals Y, but the VARSTODENORM is blank;
         %goto macerr;
      %end;
   %end; /* end-if on &DENORMYN eq Y */
   
   %if %qupcase(&denormYN) eq N %then %do;
      %if %nrbquote(&ACROSSVARDECODE.&ACROSSVAR) ne %then %do;
         %let l_message=DENORMYN equals N, but not all of ACROSSVARDECODE and ACROSSVAR are blank.;
         %goto macerr;
      %end; 
   %end; /* end-if on &DENORMYN eq N */
   
   /* 
   / YW003: Added the check name of &ACROSSVAR 
   /-------------------------------------------------------------------------*/      
   %if %nrbquote(&acrossVar) ne %then %do;
      %if %tu_chknames(&acrossvar, VARIABLE) ne %then %do;
         %let l_message=Value of ACROSSVAR is not a valid SAS variable name.;
         %goto macerr;      
      %end;
   %end; /* end-if on &acrossVar is not blank */
   
   %if %nrbquote(&countdistinctwhatvar) ne %then %do;
      %if %tu_chknames(&countdistinctwhatvar, VARIABLE) ne %then %do;
         %let l_message=Invalid SAS variable name is found in COUNTDISTINCTWHATVAR (=&countdistinctwhatvar).;
         %goto macerr;      
      %end;
   %end; /* end-if on &countdistinctwhatvar is not blank */
   
   /* 
   / Check name of &dsetout.
   /-------------------------------------------------------------------------*/   
   %if %nrbquote(&dsetOut) ne %then %do;
      /* remove any dataset options from the dsetout */
      %let l_thisword=%qscan(&dsetout, 1, %str(%()) ;
      %if %nrbquote(&l_thisword) eq %then %do;      
          %let l_message=Macro Parameter DSETOUT refers to dataset &dsetout which is not a valid dataset name;
          %goto macerr;
      %end;
                
      /* calling tu_chknames to ensure name is valid  */
      %if %tu_chknames(&l_thisword, DATA ) ne %then %do;
          %let l_message=Macro Parameter DSETOUT refers to dataset &l_thisword which is not a valid dataset name;
          %goto macerr;
      %end;
      /* ensure that dsetout dataset is not the same name as the dddatasetname  */
      %if %upcase(&l_thisword) eq %upcase(&g_dddatasetname) %then %do;
          %%let l_message=Macro Parameter DSETOUT refers to dataset &l_thisword which is the same name as G_DDDATASETNAME=&g_ddDatasetName.;
          %put RTN%str(OTE:) &sysmacroname.: Any DSETOUT dataset created will not necessarily conform to the requirements of a DDDATASET so must not be named the same.;
          %goto macerr;
      %end;
   %end;   /* of %if "&dsetOut" ne "" %then %do; */     
 
   /*
   / Check if &DSETINNUMER and &DSETINDENOM exist.
   / Apply any dataset options on the incoming data
   /-------------------------------------------------------------------------*/ 
   %let l_lastdsetinnumer=&dsetinnumer;
   %let l_lastdsetindenom=&dsetindenom;
   %let l_wordList=DSETINNUMER DSETINDENOM;
   %do l_i=1 %to 2;
       %let l_thisWord=%scan(&l_wordList, &l_i, ' ');     
       %let l_j=%index(%nrbquote(&&l_last&l_thisWord), %nrstr(%() );
       
       %if &l_j gt 1 %then %do;  
          %let l_tmp=%substr(&&l_last&l_thisWord, 1, %eval(&l_j - 1));
       %end;
       %else %do;
          %let l_tmp=&&l_last&l_thisWord;
       %end;
       
       %if %nrbquote(&l_tmp) ne %then %do;                        
          %let l_rc=%tu_nobs(&l_tmp);
          %if &l_rc lt 0 %then %do;
             %let l_message=Data set, specified by &&l_last&l_thisWord, does not exist;
             %goto macerr;
          %end;
          
          %if &l_j gt 0 %then %do;                 
              data &l_prefix._&l_thisWord;
                  set &&l_last&l_thisWord;
              run;
              %let l_last&l_thisWord=&l_prefix._&l_thisWord;
          %end;
          
       %end; /* end-if on &l_tmp not blank */
       
   %end;
   
   /*
   / Call %tu_getdata to get data.
   /-------------------------------------------------------------------------*/  
   %tu_getdata(
      dsetin   =&l_lastdsetinnumer, 
      dsetout1 =&l_prefix._getNumer, 
      dsetout2 =&l_prefix._getpop
      )
   
   %if %nrbquote(&g_abort) gt 0 %then %goto macerr;
   %let l_lastdsetinnumer=&l_prefix._getNumer;
                                        
   %let l_rc=%tu_nobs(&l_lastdsetinnumer);   
   %if %nrbquote(&g_abort) lt 0 %then %goto macerr;
  
   %let l_lastdset=&l_lastdsetinnumer;
   
   /* 
   / If data set is empty, go to display directly. 
   / Some new variables need to be added because of the bug of tu_list. 
   /--------------------------------------------------------------------*/
   %if ( &l_rc eq 0 ) and ( %qupcase(&display) eq Y ) %then %do;
      
      data _null_;
         length parsecols columns $5000;         
         columns=resolve(symget('columns'));
         rx=rxparse("$q TO ' ', '(' TO ' ', ')' TO ' '");
         * parsecols=columns;
         call rxchange(rx, 999, columns, parsecols);
         call rxfree(rx);
         call symput('l_tmp', trim(left(parsecols)));
      run;
 
      data &l_prefix.disp;
         set &l_lastdset;         
         %if %nrbquote(&l_tmp) ne %then %do;
            retain &l_tmp;
            %if %nrbquote(&acrosscolvarprefix) ne %then %do;
               &acrosscolvarprefix=0;
            %end;
            %else %do;
               tt_ac=0;
            %end;
         %end;                         
         delete;
      run;
      
      %let l_lastdset=&l_prefix.disp;      
      %goto displayit;
   %end;        
    
   /*
   /  Call %tu_getdata to get the subset of the denorminator data set.
   /  YW001: Removed calling of %tu_getdata.
   /  YW002: Added the check if dsetindenom equals the &g_popdata;
   /  YW005: Changed to calling of %tu_getdata, even though it may cause SAS
   /         errors, but we need it.
   /--------------------------------------------------------------------------*/   
   
   %if %qupcase(&dsetindenom) eq %qupcase(&g_popdata) %then 
   %do;
      %let l_lastdsetindenom=;
   %end;
   %else %if %qupcase(&dsetindenom) eq %qupcase(&dsetinnumer) %then 
   %do;
      %let l_lastdsetindenom=&l_lastdsetinnumer;
   %end; 
   %else %do;
      %tu_getdata(
         dsetin   =&l_lastdsetindenom, 
         dsetout1 =&l_prefix._getDenom, 
         dsetout2 =
         )   
      
      %let l_lastdsetindenom=&l_prefix._getDenom;   
   %end;     
   
   %if %nrbquote(&l_lastdsetindenom) eq %then %do;
      %let l_lastdsetindenom=&l_prefix._getpop;
   %end;
   
   %if %nrbquote(&acrosscollistname) ne %then %do;
      %global &acrosscollistname;
   %end;
   
   /*
   /  Unquote the variables that called by symget.
   /--------------------------------------------------------------------------*/
   %let acrossvar          =%unquote(&acrossvar);
   %let acrossvardecode    =%unquote(&acrossvardecode);
   %let groupByVarPOP      =%unquote(&groupByVarPOP);
   %let splitchar          =%unquote(&splitchar);
   %let groupByVarsNumer   =%unquote(&groupByVarsNumer);                   
   %let codedecodevarpairs =%unquote(&codedecodevarpairs);
   %let psbyvars           =%unquote(&psbyvars);
   %let rowlabelvarname    =%unquote(&rowlabelvarname);
      
   /*
   / 1. Remove statement in &GROUPBYVARSNUMER to get a list of variables. 
   / 2. Remove &ACROSSVAR and &ACROSSVARDECODE from the variable list.
   / 3. Construct &GROUPBYVARS for %tu_denorm.
   / 4. If &ACROSSVARDECODE is a fromat list, build a statement to 
   /    convert the format to a variable.
   / 5  Add &ACROSSVAR and &ACROSSVARDECODE to &CODEDECODEVARPAIRS.
   /---------------------------------------------------------------------------*/         
   data _null_;
      length t_groupbyvarsnumer statements $500 groupByVarsNumer t_message 
             groupbyvarsnumer_byvars acrossvar acrossvardecode t_var  
             newacrossvardecode t_codevar rowlabelvarname rowlabelvarname_names
             t_decodevar t_popvar $200 t_splitchar $10;
                 
      acrossvar=upcase(symget("acrossvar"));
      
      %if &denormyn eq Y %then %do;
         acrossvardecode=symget("acrossvardecode");      
      %end;
      %else %do;
         acrossvardecode=''; 
      %end;
      
      link getgrp;     
      link rowlabel;     
      link rmarsgrp;
      link setspt;
      return;
                 
   /*
   / If population variable is not across variable, set splitchar to a blank
   / space
   /--------------------------------------------------------------------------*/           
   SETSPT:      
      t_popvar=upcase(scan(symget("groupByVarPOP"), -1, ' '));
      t_splitchar=symget("splitchar");             
      
      if (t_popvar ne '') and (indexw(scan(acrossvar, -1, ' '), t_popvar) eq 0) and
         (indexw(upcase(scan(newacrossvardecode, -1, ' ')), t_popvar) eq 0) 
      then do;
         t_splitchar='%str( )';
      end;
      
      call symput('l_splitchar',  trim(left(t_splitchar))); 
      return;
      
   /*    
   / Remove the statemetns from GROUPBYVARSNUMER.
   /--------------------------------------------------------------------------*/    
   GETGRP:        
      groupByVarsNumer=""; 
      t_groupbyvarsnumer=symget("groupByVarsNumer");                   
      t_rx=rxparse("$(10)");
      call rxsubstr(t_rx,t_groupbyvarsnumer, t_pos, t_len);
      
      do while(t_pos GT 0);
         if t_pos GT 1 then
            groupByVarsNumer=trim(left(groupByVarsNumer))||' '||left(upcase(substr(t_groupbyvarsnumer, 1, t_pos -1)));
         else 
            groupByVarsNumer="";
         t_groupbyvarsnumer=substr(t_groupbyvarsnumer, t_pos + t_len);               
         call rxsubstr(t_rx,t_groupbyvarsnumer, t_pos, t_len);
      end;  
      
      groupByVarsNumer=trim(left(groupByVarsNumer))||' '||upcase(trim(left(t_groupbyvarsnumer)));
                                            
      if t_rx gt 0 then call rxfree(t_rx);         
      return;
            
   /*
   / Remove ACROSSVARDECODE from GROUPBYVARSNUMER
   / Add ACROSSVAR and ACROSSVARDECODE to CODEDECODEVARPAIRS. Construct 
   / &GROUPBYVARS for %tu_denorm
   /-----------------------------------------------------------------------------*/           
   RMARSGRP:      
      codedecodevarpairs=upcase(symget("codedecodevarpairs"));
      psbyvars=upcase(symget("psbyvars"));     
      groupbyvarsnumer_byvars=trim(left(psbyvars))||' '||trim(left(groupbyvarsnumer));      
      
      t_i=1;
      newacrossvardecode='';
      statements='';      
      t_codevar=scan(acrossvar, t_i, ' ');
      t_decodevar=scan(acrossvardecode, t_i, ' ');      
      
      do while(t_codevar ne '');                
         /* Add ACROSSVAR and ACROSSVARDECODE to CODEDECODEVARPAIRS */
         if upcase(t_decodevar) eq '_NULL_' then         
            newacrossvardecode=trim(left(newacrossvardecode))||' '||upcase(compress(t_decodevar));
         else if t_decodevar ne '' then do;
            t_ind1=indexw(codedecodevarpairs, t_codevar);           
            t_ind2=indexw(codedecodevarpairs, upcase(t_decodevar));
            
            if (t_ind1 gt 0) and (t_ind2 gt 0) and (t_ind2 gt t_ind1) then do;
               t_var=substr(codedecodevarpairs, t_ind1, t_ind2 - t_ind1);
               if index(trim(left(t_var)), ' ') gt 0 then t_ind2=0;
            end;
            
            if (t_ind1 gt 0) and (t_ind2 eq 0) then do;           
               t_message="Variable "||compress(t_codevar)||" in ACROSSVAR has different decode in CODEDECODEVARPAIRS and ACROSSVARDECODE";
               link exit;
            end;         
            
            /* YW003: Modified the code to add the format correctly. */
            if index(t_decodevar, '.') eq 0 then do;
               newacrossvardecode=trim(left(newacrossvardecode))||' '||compress(upcase(t_decodevar));           
            end;
            else do;   
               if t_ind1 eq 0 then do;
                  t_var=compress("acrossvardecode_autovar"||put(t_i, 2.0));
                  newacrossvardecode=trim(left(newacrossvardecode))||' '||compress(t_var);
                  statements=trim(left(statements))||" "||compress(t_var)||
                             "=put("||compress(t_codevar)||","||compress(t_decodevar)||");";                             
                  t_decodevar=upcase(t_var);                          
               end;
            end;
 
            if ( t_ind1 eq 0 ) and ( t_codevar ne '' ) and ( t_decodevar ne '') then 
               codedecodevarpairs=trim(left(codedecodevarpairs))||" "||compress(t_codevar)||" "||compress(t_decodevar);             
         end;
         
         /* Remove ACROSSVAR and ACROSSVARDECODE from GROUPBYVARSNUMER */
         t_ind1=indexw(groupbyvarsnumer_byvars, t_codevar);         
         t_ind2=length(t_codevar);
         link substr;
         
         t_ind1=indexw(groupbyvarsnumer_byvars, upcase(t_decodevar));         
         t_ind2=length(t_decodevar);
         link substr;
       
         t_i=t_i + 1;         
         t_codevar=scan(acrossvar, t_i, ' ');
         t_decodevar=scan(acrossvardecode, t_i, ' ');        
      end;          
            
      call symput('l_acrossvardecode',         trim(left(newacrossvardecode     ))); 
      call symput('l_groupbyvarsnumer_byvars', trim(left(groupbyvarsnumer_byvars))); 
      call symput('l_adddecodestatements',     trim(left(statements             )));     
      call symput('l_codedecodevarpairs',      trim(left(codedecodevarpairs     )));     
      return;
      
   /*
   / Make macro var rowLabelVarName_names if needed, for carrying along into output dataset.
   / This is just getting the word left of the = sign if needed.
   / ------------------------------------------------------------------------------------*/
   ROWLABEL:      
      rowlabelvarname=left(symget("rowlabelvarname"));
      rowlabelvarname_names='';      
      int_rowlabel_ind=index(t_var, '=');
      
      if int_rowlabel_ind eq 0 then do;
         rowlabelvarname_names=rowlabelvarname;
      end;         
      else do while(int_rowlabel_ind gt 0);
         if int_rowlabel_ind eq 1 then do;
            t_message="Syntext error is found in ROWLABELVARNAME.";
            link exit;
         end;
         rowlabelvarname_names=trim(left(rowlabelvarname_names))||scan(substr(t_var, 1, int_rowlabel_ind -1), -1, ' ');
         rowlabelvarname=left(substr(rowlabelvarname, int_rowlabel_ind + 1));         
         int_rowlabel_ind=index(rowlabelvarname, '=');         
      end;
   
      call symput('l_rowlabelvarname_names', trim(left(rowlabelvarname_names)));
      return;
      
   SUBSTR:    
     if t_ind1 eq 1 then 
        groupbyvarsnumer_byvars=substr(groupbyvarsnumer_byvars, t_ind1 + t_ind2);
     else if t_ind1 gt 1 then do;
        groupbyvarsnumer_byvars=substr(groupbyvarsnumer_byvars, 1, t_ind1 - 1)||' '||
                                         left(substr(groupbyvarsnumer_byvars, t_ind1 + t_ind2 ));
     end;
     groupbyvarsnumer_byvars=left(groupbyvarsnumer_byvars);
     return;        
           
   EXIT:
      call symput('l_rc', '-1');
      call symput('l_message', trim(left(t_message)));
      if t_rx gt 0 then call rxfree(t_rx);       
      stop;      
      return;                 
   run;
  
   %if &l_rc eq -1 %then %goto macerr;
   /*
   /  Requote the variables that called by symget.
   /--------------------------------------------------------------------------*/
   %let acrossvar          =%nrbquote(&acrossvar);
   %let acrossvardecode    =%nrbquote(&acrossvardecode);
   %let groupByVarPOP      =%nrbquote(&groupByVarPOP);
   %let splitchar          =%nrbquote(&splitchar);
   %let groupByVarsNumer   =%nrbquote(&groupByVarsNumer);                   
   %let codedecodevarpairs =%nrbquote(&codedecodevarpairs);
   %let psbyvars           =%nrbquote(&psbyvars);
   %let rowlabelvarname    =%nrbquote(&rowlabelvarname);
   
   %if %nrbquote(&l_adddecodestatements) ne %then %do;
      data &l_prefix.dsetin;
         set &l_lastdsetinnumer;
         &l_adddecodestatements;
      run;
      
      %let l_lastdsetinnumer=&l_prefix.dsetin;
   %end;
   /* 
   /  This is for compatible with the old version.                           
   /--------------------------------------------------------------------------*/  
   %if ( %qupcase(&denormyn) eq N ) and ( %nrbquote(&display) eq N) %then %let addbignyn=N;
      
   /*
   / Call %tu_statswithtotal to create frequency data set
   /--------------------------------------------------------------------------*/  
   %tu_statswithtotal(
      addbignyn               =&addbignyn                ,
      analysisVar             =                          ,
      groupminmaxvar          =&groupminmaxvar           ,
      analysisvarformatdname  =                          ,
      analysisvarname         =&rowlabelvarname          ,
      bignlabelsplitchar      =&l_splitchar              ,
      bignvarname             =&bigNvarName              ,
      codedecodevarpairs      =&l_codeDecodeVarPairs     ,
      completetypesvars       =&completetypesvars        ,
      countdistinctwhatvar    =&countDistinctWhatVar     ,
      countvarname            =                          ,
      dsetinanaly             =&l_lastdsetinnumer        ,
      dsetindenom             =&l_lastdsetinDenom        ,
      dsetout                 =&l_prefix.dstatsout       ,
      dsetOutCi               =                          ,
      groupByVarPop           =&groupByVarPop            ,
      groupByVarsAnaly        =&groupByVarsNumer         ,
      groupByVarsDenom        =&groupByVarsDenom         ,
      psByvars                =&psByvars                 ,
      psClass                 =&psClass                  ,
      psClassOptions          =&psClassOptions           ,
      psFormat                =&psFormat                 ,
      psFreq                  =&psFreq                   ,
      psid                    =&psid                     ,
      psOptions               =&psOptions                ,
      psOutput                =&psOutput                 ,
      psOutputOptions         =&psOutputOptions          ,
      psTypes                 =&psTypes                  ,
      psWays                  =&psWays                   ,
      psWeight                =&psWeight                 ,
      remSummaryPctYN         =&remsummarypctyn          ,
      resultPctDPS            =&resultPctDPS             ,
      resultStyle             =&resultStyle              ,
      resultVarName           =&resultVarName            ,
      statsList               =                          ,
      summaryLevelVarName     =&summaryLevelVarName      ,
      totalDecode             =&totalDecode              ,
      totalForVar             =&totalForVar              ,
      totalID                 =&totalID                  ,
      varlabelstyle           =std            
      );    
                                                 
   %let l_lastdset=&l_prefix.dstatsout; 
   
   %if &g_debug ge 1 %then
   %do;
      proc print data=&l_lastdset;
         title 'TU_FREQ: Printout of Data Set Created by %tu_statswithtotal';
      run;
   %end;
   /*
   /  Add special sort variable to data.
   /  YW005: Added code to get min/max value before calculation special sort
   /--------------------------------------------------------------------------*/  
   %let l_dsetinspsort=;
   
   %do l_i=1 %to 2; 
      %if &l_i eq 1 %then %let l_spsortnum=;
      %else %let l_spsortnum=&l_i;
         
      %if %nrbquote(&&spSort&l_spsortnum.ResultVarName) ne %then %do;
 
         %if %nrbquote(&l_dsetinspsort) eq %then %do;
         
            %if %nrbquote(&groupminmaxvar) ne %then %do;
            
                proc sort data=&l_lastdsetinnumer out=&l_prefix.dsetinspsortorder;
                   by &&spSort&l_spsortnum.GroupByVarsNumer &countdistinctwhatvar %qscan(&groupminmaxvar, 2, %str(%(%)));
                run;
               
                data &l_prefix.dsetinspsort;
                   set &l_prefix.dsetinspsortorder;
                   by &&spSort&l_spsortnum.GroupByVarsNumer &countdistinctwhatvar %qscan(&groupminmaxvar, 2, %str(%(%)));
                   %if %qscan(&groupminmaxvar, 1, %str(%()) eq MIN %then 
                   %do;
                      if first.%scan(&&spSort&l_spsortnum.GroupByVarsNumer &countdistinctwhatvar, -1 , %str( ));
                   %end;
                   %else %do;
                      if last.%scan(&&spSort&l_spsortnum.GroupByVarsNumer &countdistinctwhatvar, -1 , %str( ));
                   %end;
                run;
                
                %let l_dsetinspsort=&l_prefix.dsetinspsort;
                 
            %end;  
            %else %let l_dsetinspsort=&l_lastdsetinnumer; /* end-if on %nrbquote(&groupminmaxvar) ne */
         
         %end;  /* end-if on %nrbquote(&l_dsetinspsort) eq  */
         
         /* get the numer counts   */
         %tu_stats(  
               analysisVar            =,                       
               analysisVarFormatDName =,
               analysisVarName        =,    
               classVars              =&&spSort&l_spsortnum.GroupByVarsNumer,          
               countDistinctWhatVar   =&countdistinctwhatvar,          /* YW004 */
               countVarName           =&l_numervarname,       
               dsetIn                 =&l_dsetinspsort,            
               dsetOut                =&l_prefix._spSortNumer&l_i,            
               dsetOutCi              =,          
               psByVars               =,              
               psClass                =,                             
               psClassOptions         =,
               psFormat               =,
               psFreq                 =,                              
               psid                   =,                                
               psOptions              =missing,
               psOutput               =,                           
               psOutputOptions        =,
               psTypes                =,                             
               psWays                 =,                              
               psWeight               =,                            
               statsList              =,          
               totalForVar            =,        
               totalid                =,            
               varlabelStyle          =                       
               )
               
         %if g_abort eq 1 %then %goto macerr;      
         
         %if &g_debug ge 1 %then
         %do;
            proc print data=&l_prefix._spSortNumer&l_i;
               title "TU_FREQ: Printout of Numerator Data Set for Special Sort &l_i";
            run;
         %end;
                    
         %let l_spsortout=&l_prefix._spSortNumer&l_i;
         
         %if ( %nrbquote(&dsetindenom) ne ) and ( %nrbquote(&&spSort&l_spsortnum.ResultStyle) ne ) 
         %then %do;
            /* get the denom counts */
            %tu_stats(  
               analysisVar            =,        
               analysisVarFormatDName =,
               analysisVarName        =,    
               classVars              =&&spSort&l_spsortnum.GroupByVarsDenom,          
               countDistinctWhatVar   =&countdistinctwhatvar,                    /* YW004 */
               countVarName           =&l_denomvarname,       
               dsetIn                 =&l_lastdsetindenom,            
               dsetOut                =&l_prefix._spSortDenom&l_i,            
               dsetOutCi              =,          
               psByVars               =,              
               psClass                =,                             
               psClassOptions         =,
               psFormat               =,
               psFreq                 =,                              
               psid                   =,                                
               psOptions              =missing,
               psOutput               =,                           
               psOutputOptions        =,
               psTypes                =,                             
               psWays                 =,                              
               psWeight               =,                            
               statsList              =,          
               totalForVar            =,        
               totalid                =,            
               varlabelStyle          =                       
               )
        
            %if g_abort eq 1 %then %goto macerr;
            
            %if &g_debug ge 1 %then
            %do;
               proc print data=&l_prefix._spSortDenom&l_i;
                  title "TU_FREQ: Printout of Denominator Data Set for Special Sort &l_i";
               run;
            %end;
            /* get the percent  */
            %tu_percent(  
               dsetinNumer   = &l_prefix._SpSortNumer&l_i,
               numerCntVar   = &l_numervarname,
               dsetinDenom   = &l_prefix._SpSortDenom&l_i,
               denomCntVar   = &l_denomvarname,
               mergeVars     = &&spSort&l_spsortnum.GroupByVarsDenom,
               resultStyle   = &&spSort&l_spsortnum.ResultStyle,
               dsetout       = &l_prefix._SpSortPercent&l_i(rename=(tt_result=&&spSort&l_spsortnum.ResultVarName))
               )
                
            %if g_abort eq 1 %then %goto macerr;
            %let l_spsortout=&l_prefix._SpSortPercent&l_i;
         %end; /* end-if on &dsetindenom is not blank */
           
         proc sort data=&l_spsortout nodupkey out=&l_prefix._merge&l_i
              (keep=&&spSort&l_spsortnum.GroupByVarsNumer  &&spSort&l_spsortnum.ResultVarName);
            by &&spSort&l_spsortnum.GroupByVarsNumer;
         run;  
         
         proc sort data=&l_lastdset  out=&l_prefix.mergemain;        
            by &&spSort&l_spsortnum.GroupByVarsNumer;
         run;  
         
         data &l_prefix.spmerge&l_i;
            merge &l_prefix.mergemain (in=&l_varprefix.__IN1__)
                  &l_prefix._merge&l_i(in=&l_varprefix.__IN2__);                 
            by &&spSort&l_spsortnum.GroupByVarsNumer;
            if &l_varprefix.__IN1__;
            if not &l_varprefix.__IN2__ then &&spSort&l_spsortnum.ResultVarName=999999;
         run;
       
         %let l_lastdset=&l_prefix.spmerge&l_i;    
         
      %end; /* end-if on &&spSort&l_spsortnum.ResultVarName is not blank */ 
      
   %end; /* end of do-to loop on l_i */  
     
   /*
   /  Call %tu_denom to denormalize data.
   /--------------------------------------------------------------------------*/      
   %if &denormyn eq Y %then %do;   
    
      %if &g_debug ge 1 %then
      %do;
         proc print data=&l_lastdset;
            title 'TU_FREQ: Printout of Data Set prior to call %tu_denorm';
         run;
      %end;
      
      %tu_denorm(
         acrossColVarPrefix =&acrossColVarPrefix, 
         acrossVar          =&acrossVar,  
         acrossVarLabel     =&l_acrossVarDecode,
         acrossVarListName  =&acrossColListName,  
         dsetin             =&l_lastdset,  
         dsetout            =&l_prefix.denormout(drop=_name_ _label_),  
         groupByVars        =&summaryLevelVarName &l_rowLabelVarName_names &l_groupbyvarsnumer_byvars
                             &spsortresultvarname &spsort2resultvarname,
         varsToDenorm       =&varstodenorm 
         );            
         
      %let l_lastdset=&l_prefix.denormout;    
         
      %if &g_debug ge 1 %then
      %do;
         proc print data=&l_lastdset;
            title 'TU_FREQ: Printout of Data Set Created by %tu_denorm';
         run;
      %end;
   %end; 
                  
   %if %nrbquote(&postSubset) ne %then %do;
      data &l_prefix._postsubset;
         set &l_lastDset;
         %unquote(&postSubset);
      run;
      %let l_lastdset=&l_prefix._postsubset;
   %end;
   
   /*
   /  Call %tu_labelvars to label the variables and create &DSETOUT.
   /--------------------------------------------------------------------------*/    
     
   %if %nrbquote(&dsetout) ne %then %do;
      %if &LABELVARSYN eq Y %then %do;   
         %tu_labelvars(
            dsetin   =&l_lastdset,  
            dsetout  =&l_prefix.labelout,  
            style    =&varlabelstyle    
            )
            
         %if &g_abort eq 1 %then %goto macerr;  
            
         %let l_lastdset=&l_prefix.labelout;             
      %end;
   
      data &dsetout ;
         set &l_lastDset (label='Output data set from %tu_freq');
      run;
    
      %if %qupcase(&display) ne Y %then %goto endmac;
   %end;
   
   %if ( %nrbquote(&acrosscollistname) ne ) and
      %sysfunc(indexw(%qupcase(&columns), %nrstr(&)%qupcase(&acrosscollistname))) gt 0 %then %do;         
     %let columns=%unquote(&columns);    
   %end;
    
%DISPLAYIT:   
   
   %if &g_debug ge 1 %then
   %do;
      proc print data=&l_lastdset;
         title 'TU_FREQ: Printout of Data Set Before Calling %tu_list';
      run;
   %end;
                                                                            
   %tu_list(
      COLUMNS                  =&COLUMNS,
      DSETIN                   =&l_lastdset,
      GETDATAYN                =N,
      LABELVARSYN              =&LABELVARSYN,
      BREAK1                   =&BREAK1,
      BREAK2                   =&BREAK2,
      BREAK3                   =&BREAK3,
      BREAK4                   =&BREAK4,
      BREAK5                   =&BREAK5,
      BYVARS                   =&BYVARS,
      CENTREVARS               =&CENTREVARS,
      COLSPACING               =&COLSPACING,
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
      ) ;
      %goto endmac;
%MACERR:
   %let g_abort = 1;
   %if %nrbquote(&l_message) ne %then %do;
      %put RTERR%str(OR:) &sysmacroname: &l_message;
   %end;
   %put RTN%str(OTE:) &sysmacroname: The value of G_ABORT=&G_ABORT. This macro will now abort;
   %tu_abort;
%ENDMAC:
   /*
   / Call tu_tidyup to clear temporary data set and fields.
   /--------------------------------------------------------------------------*/   
   %tu_tidyup(
      RMDSET =&L_PREFIX:,
      GLBMAC =NONE
      )   
%mend tu_freq;
