/*---------------------------------------------------------------------------------------
| Macro Name       : tu_statswithtotal.sas
|
| Macro Version    : 2
|
| SAS version      : SAS v8.2
|
| Created By       : Yongwei Wang
|
| Date             : 12-July-2003
|
| Macro Purpose    : This unit shall be used to create summary statistics or frequency
|                    count/percentage with overall totals and subgroup totals
|
| Macro Design     : Procedure Style.
|
| Input Parameters :
|
| Name                Description                                       Default           
| ----------------------------------------------------------------------------------------
| ADDBIGNYN           Appended the population N (N=nn) to decode, or    Y                 
|                     the format if there is no decode, of the last                       
|                     variable of &GROUPBYVARPOP.                                        
|                     Valid values:                                                       
|                     Y, N                                                                
|                                                                                         
| ANALYSISVAR         Specify Analysis variable which will be passed    (Blank)           
|                     to the PROC SUMMARY Var statement, if STATSLIST                     
|                     is not blank. If STATSLIST is blank, it will be                     
|                     added to each subgroup of GROUPBYVARSANALY if it                    
|                     is not already in GROUPBYVARSANALY. It is                           
|                     required if &STATSLIST is not blank.                                
|                     The choice between production of summary                            
|                     statistics or frequency counts shall be                             
|                     determined by the presence of a value for the                       
|                     STATSLIST parameter. A blank value shall                            
|                     indicate that frequency counts are to be                            
|                     produced; a non-blank value shall indicate that                     
|                     summary statistics are to be produced.                              
|                     Valid values:                                                       
|                     Blank                                                               
|                     a valid SAS variable that exists in DSETIN                          
|                                                                                         
| ANALYSISVARFORMATD  Name of variable created to hold the formatd      (Blank)           
| NAME                (decimal places) of the analysis variable. It is                    
|                     for summary statistics only                                         
|                     Valid values:                                                       
|                     SAS variable name                                                   
|                                                                                         
| ANALYSISVARNAME     For summary statistics, name of variable to be    tt_avnm           
|                     created to hold the label of the analysis                           
|                     variable (%tu_labelvars will be run prior to                        
|                     storing the label),                                                 
|                     OR,                                                                 
|                     (for frequency counts or summary statistics) a                      
|                     SAS assignment statement to create a variable to                    
|                     hold the name of the analysis variable and for                      
|                     assigning the value to it. If ANALYSISVAR is                        
|                     blank, decode of the last code variable in                          
|                     GROUPBYVARSANALY will be used.                                      
|                     Valid values:                                                       
|                     Blank                                                               
|                     OR                                                                  
|                     Valid SAS variable name, e.g. tt_analy                              
|                     OR                                                                  
|                     Valid SAS assignment statement, e.g. tt_analy =                     
|                     "Age (yrs)"                                                         
|                                                                                         
| BIGNLABELSPLITCHAR  Specify the split character which should be       ~                 
|                     added before the big N.                                             
|                     Valid values:                                                       
|                     Blank or a valid SAS split character.                               
|                                                                                         
| BIGNVARNAME         Specifies the name of the variable that saves     tt_bnnm           
|                     the big N values in the DD dataset. The variable                    
|                     will be created by %tu_statswithtotal calling                       
|                     %tu_addbignvar macro.                                               
|                     If it is blank, the big N will not be added to                      
|                     the output                                                          
|                     Valid values:                                                       
|                     Blank if ADDBIGNYN=N                                                
|                     Any valid SAS variable name that does not exist                     
|                     in the input dataset                                                
|                                                                                         
| CODEDECODEVARPAIRS  Specifies code and decode variable pairs. The     (Blank)           
|                     first variable in each pair will contain the                        
|                     code, which is used in counting and ordering,                       
|                     and the other will contain decode, which is used                    
|                     for presentation. If the decode variables will                      
|                     be removed from the GROUPBYVARSANALY,                               
|                     GROUPBYVARSDENOM and GROUPBYVARPOP before                          
|                     analysis and will be added back after analysis.                     
|                     See Appendix about Further Processing When                         
|                     &CODEDECODEVARPAIRS are specified                                  
|                     Valid values:                                                       
|                     Blank                                                               
|                     a list of SAS variable names, which exist in                        
|                     &DSETINNUMER, in pairs                                              
|                                                                                         
| COMPLETETYPESVARS   Specify a list of variables which are in          _ALL_             
|                     GROUPBYVARSANALY and the COMPLETETYPES given by                     
|                     PSOPTIONS should be applied to. If it equals                        
|                     _ALL_, all variables in GROUPBYVARSANALY will be                    
|                     included.                                                           
|                     Valid values:                                                       
|                     _ALL_                                                               
|                     A list of variable names which are in                               
|                     GROUPBYVARSANALY                                                    
|                                                                                         
| COUNTDISTINCTWHATV  Variable(s) that contain values to be counted     &g_centid         
| AR                  uniquely within any output grouping.              &g_subjid         
|                     Valid values:                                                       
|                     Blank                                                               
|                     A list of SAS variables that exists in                              
|                     DSETINANALY                                                         
|                                                                                         
| COUNTVARNAME        The name to rename the PROC SUMMARY variable      (Blank)           
|                     _freq_ to when doing counts. If not specified,                      
|                     the _freq_ variable will not be renamed                             
|                     Valid values: Blank, or a valid SAS variable                        
|                     name                                                                
|                                                                                         
| DSETINANALY         Input dataset containing data which frequency or  (Blank)           
|                     summary statistics should be obtained                               
|                     Valid values:                                                       
|                     Any valid SAS dataset reference; dataset options                    
|                     are supported.                                                      
|                                                                                         
| DSETINDENOM         Input dataset containing data to be counted to    (Blank)           
|                     obtain the denominator. This may or may not be                      
|                     the same as the dataset specified to                                
|                     DSETINANALY. If blank, the population data set                      
|                     created by %tu_getdata will be used. It is only                     
|                     used when STATSLIST is blank.                                       
|                     Valid values:                                                       
|                     Blank                                                               
|                     Any valid SAS dataset reference; dataset options                    
|                     are supported.                                                      
|                                                                                         
| DSETOUT             Name of output dataset                            (Blank)           
|                     Valid values:                                                       
|                     Dataset name                                                        
|                                                                                         
| DSETOUTCI           Name of cell index output dataset. If not         (Blank)           
|                     specified, no cell index output dataset will be                     
|                     created                                                             
|                     Valid values:                                                       
|                     Dataset name                                                        
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
|                     %tu_statswithtotal's calling %tu_getdata                            
|                                                                                         
| GROUPBYVARSANALY    Variables in DSETINANALY to group the data by     (Blank)           
|                     when obtaining the summary statistics of the                        
|                     numerator of the frequency. Additionally a set                      
|                     of brackets may be inserted within the variables                    
|                     to generate records containing summary counts                       
|                     grouped by variables specified to the left of                       
|                     the brackets. Summary records created may be                        
|                     populated with values in the grouping variables                     
|                     by specifying variable value pairs within                           
|                     brackets, separated by semicolons. eg aesoccd                       
|                     aesoc(aeptcd=0; aept="Any Event";) aeptcd aept.                     
|                     See Appendix about Parsing of                                      
|                     &GROUPBYVARSANALY                                                  
|                     Valid values:                                                       
|                     Blank, _NONE_ (to request an overall total for                      
|                     the whole dataset)                                                  
|                     Name of one or more SAS variables that exist in                     
|                     DSETINANALY                                                         
|                     SAS assignment statements within brackets                           
|                                                                                         
| GROUPBYVARSDENOM    Variables in DSETINDENOM to group the data by     (Blank)           
|                     when counting to obtain the denominator. It is                      
|                     only used when STATSLIST is blank.                                  
|                     Valid values:                                                       
|                     Blank, _NONE_ (to request an overall total for                      
|                     the whole dataset)                                                  
|                     Name of a SAS variable that exists in                               
|                     DSETINDENOM                                                         
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
| PSBYVARS            Passed to %tu_stats and will be used in the PROC  (Blank)           
|                     SUMMARY BY statement in %tu_stats. This will                      
|                     cause the data to be sorted first.                                  
|                     Valid values: Blank, or the name of one or more                     
|                     variables that exist in DSETIN. DSETIN need not                     
|                     be sorted by &psbyvars                                              
|                                                                                         
| PSCLASS             Passed to %tu_stats and will be used in the PROC  (Blank)           
|                     SUMMARY CLASS statement in %tu_stats,                             
|                     including Class options. Use of this parameter                      
|                     along with &CLASSVARS and/or &PSCLASSOPTIONS is                     
|                     invalid                                                             
|                     Valid values: Blank, or a valid PROC SUMMARY                        
|                     Class statement, including any required options,                    
|                     followed by 1 or more complete class statements.                    
|                     e.g.                                                                
|                     PSCLASS=%str(var1 var2/preloadfmt; class                            
|                     var3/mlf order=fmt; class var4/mlf;). The                           
|                     leading "class" must be omitted                                     
|                                                                                         
| PSCLASSOPTIONS      Passed to %tu_stats and will be used in the PROC  (Blank)           
|                     SUMMARY CLASS statement options.                                  
|                     Valid values:                                                       
|                     Valid PROC SUMMARY Class options (without the                       
|                     leading '/')                                                        
|                     E.g.: PRELOADFMT  which can be used in                             
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
| PSFREQ              Passed to %tu_stats and will be used in the PROC  (Blank)           
|                     SUMMARY FREQ statement                                            
|                     Valid values: Blank, or a valid PROC SUMMARY                        
|                     Freq statement part.                                                
|                                                                                         
| PSID                Passed to %tu_stats and will be used in the PROC  (Blank)           
|                     SUMMARY ID statement                                              
|                     Valid values: Blank, or a valid PROC SUMMARY Id                     
|                     statement part.                                                     
|                                                                                         
| PSOPTIONS           Passed to %tu_stats and will be used in PROC      COMPLETETYPES     
|                     SUMMARYs options to use. MISSING ensures that    MISSING NWAY      
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
| PSOUTPUT            Passed to %tu_stats and will be used in the PROC  (Blank)           
|                     SUMMARY OUTPUT statement, including Output                        
|                     options, but excluding any OUT= part.  Note use                     
|                     of this parameter along with &STATSLIST and/or                      
|                     &PSOUTPUTOPTIONS is invalid                                         
|                     Valid values: Blank, or a valid PROC SUMMARY                        
|                     Output statement part, except for OUT=.                             
|                     Note: OUT= will be ignored, with warning from                       
|                     SAS.                                                                
|                                                                                         
| PSOUTPUTOPTIONS     Passed to %tu_stats and will be used in the PROC  NOINHERIT         
|                     SUMMARY Output options statement part.                              
|                     Valid values:                                                       
|                     If PSOUTPUT is specified: blank Else: blank, or                     
|                     valid PROC SUMMARY Output options (without the                      
|                     leading '/')                                                        
|                                                                                         
| PSTYPES             Passed to %tu_stats and will be used in the PROC  (Blank)           
|                     SUMMARY TYPES statement.                                          
|                     Valid values: Blank, or a valid PROC SUMMARY                        
|                     Types statement part.                                               
|                                                                                         
| PSWAYS              Passed to %tu_stats and will be used in the PROC  (Blank)           
|                     SUMMARY WAYS statement.                                           
|                     Valid values: Blank, or a valid PROC SUMMARY                        
|                     WAYS statement part.                                                
|                                                                                         
| PSWEIGHT            Passed to %tu_stats and will be used in the PROC  (Blank)           
|                     SUMMARY Weight statement.                                           
|                     Valid values: Blank, or a valid PROC SUMMARY                        
|                     Weight statement part.                                              
|                                                                                         
| REMSUMMARYPCTYN     Remove summary level percentage Y/N. Setting to   N                 
|                     Y keeps only the first character string of the                      
|                     field requested by the RESULTSTYLE parameter. It                    
|                     is only used when STATSLIST is blank                                
|                     Valid values:                                                       
|                     Y, N                                                                
|                     In typical usage, in conjunction with                               
|                     RESULSTYLE=NUMERPCT, this shows the n count for                     
|                     a group without the percentage, where the count                     
|                     shows the denominator used within a group.                          
|                                                                                         
| RESULTPCTDPS        The reporting precision for percentages. It is    0                 
|                     required and only used when STATSLIST is blank                      
|                     Valid values:                                                       
|                     As documented for tu_percent in [6]                                 
|                                                                                         
| RESULTSTYLE         The appearance style of the result columns that   NUMERPCT          
|                     will be displayed in the report. The chosen                         
|                     style will be placed in variable &RESULTVARNAME.                    
|                     It is only used when STATSLIST is blank.                            
|                     Valid values:                                                       
|                     As documented for tu_percent in [6]. In typical                     
|                     usage, NUMERPCT.                                                    
|                                                                                         
| RESULTVARNAME       Name of the variable to hold the result of the    tt_result         
|                     frequency count. It is only used when STATSLIST                     
|                     is blank.                                                           
|                     Valid values:                                                       
|                     Blank, if STATSLIST is not blank                                    
|                     Valid SAS variable name                                             
|                     If DENORMYN=Y, variable listed in VARSTODENORM                      
|                                                                                         
| STATSLIST           List of summary statistics to produce. May also   (Blank)           
|                     specify correct PROC SUMMARY syntax to rename                       
|                     output variable (N=N MEAN=MEAN)                                     
|                     If blank, frequency will be produced.                               
|                     Valid values:                                                       
|                     Blank, if frequency is required                                     
|                     A list of statistics to be created by PROC                          
|                     SUMMARY, or pairs of values where the pair is                       
|                     comprised a) a PROC SUMMARY statistic, b) an                        
|                     equals sign, and c) a valid SAS variable name                       
|                                                                                         
| SUMMARYLEVELVARNAM  Name for variable that will contain the           TT_SUMMARYLEVEL   
| E                   iteration number of the summaries requested via                     
|                     the GROUPBYVARSANALY parameter.                                     
|                     Valid values:                                                       
|                     Blank                                                               
|                     A valid SAS variable name.                                          
|                                                                                         
| TOTALDECODE         Value(s) used to populate the variable(s) of the  (Blank)           
|                     decode variable(s) of the TOTALFORVAR. If a                         
|                     value has more than one word, the value should                      
|                     be quoted with single or double quote                               
|                     Valid values                                                        
|                     Blank                                                               
|                     A list of values that can be entered into the                       
|                     decode of the TOTALFORVAR variable(s) without                       
|                     SAS error or truncation                                             
|                                                                                         
| TOTALFORVAR         Variable for which overall totals are required    (Blank)           
|                     within all other grouped class variables. If not                    
|                     specified, no total will be produced. Can be one                    
|                     or a list of followings:                                            
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
| TOTALID             Value(s) used to populate the variable(s)         (Blank)           
|                     specified in TOTALFORVAR.                                           
|                     Valid values                                                        
|                     Blank                                                               
|                     A list of values that can be entered into                           
|                     &TOTALFORVAR without SAS error or truncation                        
|                                                                                         
| VARLABELSTYLE       Style of labels to be applied.                    SHORT             
|                     Valid values: As defined by %tu_labelvars                           
|                                                                                         
| ----------------------------------------------------------------------------------------
| Output:  The unit shall produce a output dataset (&dsetout) containing variables
|          specified in &PSBYVARS, &GROUPBYVARSANALY and variable &SUMMARYLEVELVARNAME
|          &COUNTVARNAME/TT_NUMERCNT, &ANALYSISVARNAME, &ANALYSISVARFORMATDNAME,
|          TT_DENOMCNT and/or &RESULTARNAME
| ----------------------------------------------------------------------------------------
| Global macro variables created:  None
| ----------------------------------------------------------------------------------------
| Macros called :
| (@)tr_putlocals
| (@)tu_abort
| (@)tu_addBigNVar
| (@)tu_chknames
| (@)tu_chkvarsexist
| (@)tu_getdata
| (@)tu_nobs
| (@)tu_percent
| (@)tu_putglobals
| (@)tu_stats
| (@)tu_tidyup
| (@)tu_words
|
| ----------------------------------------------------------------------------------------
| Example:
|     %tu_statswithtotal(
|        addbignyn=Y,
|        analysisvar=,
|        codedecodevarpairs=&g_trtcd &g_trtgrp,
|        dsetinanaly=ardata.ae,
|        groupbyvarsanaly=trtcd (aesoc="DUMMY" ; aept="Any Event") aesoc (aept="Any Event") aept,
|        groupbyvarsdenom=&g_trtcd,
|        groupbyvarpop=&g_trtcd,
|        statslist=,
|        totaldecode="Total",
|        totalforvar=&g_trtcd,
|        totalid=999
|        );
|
| ----------------------------------------------------------------------------------------
| Change Log :
|
| Modified By :               Yongwei Wang(YW62951)
| Date of Modification :      21-Sep-2004
| New Version Number :        1/2
| Modification ID :           YW001
| Reason For Modification :   Modified after SCR. Added call to tu_putglobals. Changed
|                             mouse-over text of GROUPMINMAXVARS. 
| ----------------------------------------------------------------------------------------
| Modified By :               Yongwei Wang(YW62951)
| Date of Modification :      22-Sep-2004
| New Version Number :        1/3
| Modification ID :           YW002
| Reason For Modification :   Modified after UTC so that it works when SUMMARYLEVELVARNAME
|                             is blank and COMPLETETYPESVAR equals '_ALL_' 
| ----------------------------------------------------------------------------------------
| Modified By :               Yongwei Wang(YW62951)
| Date of Modification :      27-Sep-2004
| New Version Number :        1/4
| Modification ID :           YW003
| Reason For Modification :   Moved the place where set the l_nototalflag, added
|                             &ANALYSISVARNAME to the group variables when fill 0 to fix 
|                             the bug found during the user test. 
| ----------------------------------------------------------------------------------------
| Modified By :               Yongwei Wang(YW62951)
| Date of Modification :      15-Oct-2004
| New Version Number :        1/5
| Modification ID :           YW004
| Reason For Modification :   - Added %qupcase to &ADDBIGNYN when checking parameters.
|                             - Changed REMSUMMARYPCT to REMSUMMARYPCTYN in RTERROR
|                               messages.    
| ----------------------------------------------------------------------------------------
| Modified By :               Yongwei Wang(YW62951)
| Date of Modification :      10-Nov-2004
| New Version Number :        1/6
| Modification ID :           YW005
| Reason For Modification :   - Add a condition to the check of variable existance in
|                               POP data set so that if addbigNYN equals N and 
|                               &groupbyvarpop or &countdistinctwhatvar does not exist
|                               in POP dataset, don't call %tu_addbignyn.  
|                             - Changed "&l_numericvarlist" to symget('l_numericvarlist')
| ----------------------------------------------------------------------------------------
| Modified By :               Yongwei Wang(YW62951)
| Date of Modification :      09-Nov-2005
| New Version Number :        2/1
| Modification ID :           YW006
| Reason For Modification :   Requested by change request HRT0092
|                             1.Redefined length for decode variable before assign 
|                               formatted code value to decode
|                             2.Passed blank to COUNTDISTINCTWHATVAR to %tu_stats when
|                               summary stats are required
|                             3.Modified the process of calculating bigN, when there
|                               are more than one totals are required or subset is used
|                               in total    
|                             4.Added a temporary variable to output data sets from 
|                               %tu_stats to save the number of totals so that the total
|                               statements can be applied more accurate
|                             5.Modified fill zero process
| ----------------------------------------------------------------------------------------
| Modified By :               Yongwei Wang(YW62951)
| Date of Modification :      09-Feb-2006
| New Version Number :        2/2
| Modification ID :           YW006
| Reason For Modification :   Modify condition when calling %tu_addbignvar so that
|                             if TOTALFORVAR is not blank and it is not the last variable
|                             in GROUPBYVARPOP, %tu_addbignvar will not be called and
|                             bigN will be added in the second way.  
| ----------------------------------------------------------------------------------------
| Modified By :
| Date of Modification :
| New Version Number :
| Modification ID :
| Reason For Modification :
|
|---------------------------------------------------------------------------------------*/
%macro tu_statswithtotal(
   ADDBIGNYN           =Y,                 /* Add the population N information - Y/N */
   ANALYSISVAR         =,                  /* Analysis variable which will be passed to the PROC SUMMARY Var statement, if STATSLIST is not blank, or which frequency will be calculated */
   ANALYSISVARFORMATDNAME=,                /* Name of variable created to hold the formatd (decimal places) of the analysis variable. */
   ANALYSISVARNAME     =tt_avnm,           /* Name of variable to be created to hold the label of the analysis variable or, if ANALYSISVAR is blank, the last decode variable of GROUPBYVARSANALY.*/
   BIGNLABELSPLITCHAR  =~,                 /* The split character added before the big N */
   BIGNVARNAME         =tt_bnnm,           /* Variable name that saves big N values in the DD dataset */
   CODEDECODEVARPAIRS  =,                  /* Code and Decode variables in pairs */
   COMPLETETYPESVARS   =_ALL_,             /* Variables which COMPLETETYPES should be applied to */
   COUNTDISTINCTWHATVAR=&g_centid &g_subjid, /* Variable(s) that contain values to be counted uniquely within any output grouping. Eg &g_subjid */
   COUNTVARNAME        =,                  /* The name to rename the PROC SUMMARY variable _freq_ to when doing counts. */
   DSETINANALY         =,                  /* Input dataset containing data which frequency or summary statistics should be obtained */
   DSETINDENOM         =,                  /* Input dataset containing data to be counted to obtain the denominator. It is only used when STATSLIST is blank */
   DSETOUT             =,                  /* Name of output dataset */
   DSETOUTCI           =,                  /* Name of output dataset for cell index */   
   GROUPBYVARPOP       =&g_trtcd,          /* Variables to group by when counting big N */
   GROUPBYVARSANALY    =,                  /* Variables in DSETINANALY to group the data by when obtaining the summary statistics of the numerator of the frequency. */
   GROUPBYVARSDENOM    =,                  /* Variables in DSETINDENOM to group the data by when counting to obtain the denominator. */
   GROUPMINMAXVAR      =,                  /* Specify if frequency of each group should be got from first or last value of a variable in format MIN(variables) */
   PSBYVARS            =,                  /* Advanced Usage: Passed to the PROC SUMMARY By statement. This will cause the data to be sorted first. */
   PSCLASS             =,                  /* Advanced usage: Passed to the PROC SUMMARY CLASS Statement */
   PSCLASSOPTIONS      =,                  /* PROC SUMMARY Class statement options */
   PSFORMAT            =,                  /* Passed to the PROC SUMMARY FORMAT statement. */
   PSFREQ              =,                  /* Advanced usage: Passed to the PROC SUMMARY Freq statement */
   PSID                =,                  /* Advanced usage: Passed to the PROC SUMMARY Id Statement */
   PSOPTIONS           =COMPLETETYPES MISSING NWAY, /* PROC SUMMARY Options to use */
   PSOUTPUT            =,                  /* Advanced usage: Passed to the PROC SUMMARY Output statement. */
   PSOUTPUTOPTIONS     =NOINHERIT,         /* Passed to the PROC SUMMARY Output options statement part. */
   PSTYPES             =,                  /* Advanced Usage: Passed to the PROC SUMMARY Types statement */
   PSWAYS              =,                  /* Advanced Usage: Passed to the PROC SUMMARY Ways statement. */
   PSWEIGHT            =,                  /* Advanced Usage: Passed to the PROC SUMMARY Weight statement. */
   REMSUMMARYPCTYN     =N,                 /* Remove summary level percentage Y/N */
   RESULTPCTDPS        =0,                 /* The reporting precision for percentages */
   RESULTSTYLE         =NUMERPCT,          /* The appearance style of the result columns that will be displayed in the report: */
   RESULTVARNAME       =tt_result,         /* Name of the variable to hold the result of the frequency count */
   STATSLIST           =,                  /* List of required summary statistics. e.g. N Mean Median. (Or N=BPN MIN=BPMIN) */
   SUMMARYLEVELVARNAME =TT_SUMMARYLEVEL,   /* Name for variable that will contain the iteration number of the summaries requested via the GROUPBYVARSANALY parameter. */
   TOTALDECODE         =,                  /* Value(s) used to populate the variable(s) of the decode variable(s) of the TOTALFORVAR. */
   TOTALFORVAR         =,                  /* Variable(s) for which a overall total is required */
   TOTALID             =,                  /* Value(s) used to populate the variable(s) specified in TOTALFORVAR. */
   VARLABELSTYLE       =SHORT              /* Style of labels to be applied */
   );
   /*
   /  Write details of macro start to log
   /---------------------------------------------------------------------------*/
   %local MacroVersion;
   %let MacroVersion = 2;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals();
   
   %local
      l_analysisvarname      l_bigntotalid          l_bigntovar            l_totaldsetin
      l_bigntovardecodevar   l_classvars            l_codeinpsformat       l_codelist
      l_debug                l_decodelist           l_denomout             l_denomvarname
      l_dsetin               l_dsetinpop            l_flag                 l_fmtprefix
      l_format_statements    l_groupbyvarpop        l_groupbyvarsanaly     l_groupbyvarsdenom
      l_grouppstypes         l_groupstypes          l_i                    l_j
      l_k                    l_l                    l_lastdset             l_message1
      l_message2             l_ndcdlen              l_noncompletetypesvars l_numericvarlist
      l_numervarname         l_numof_byvars         l_numof_codes          l_numof_fmtvars
      l_numof_noncmpvars     l_numof_totals         l_prefix               l_psformat
      l_psformatdenom        l_rc                   l_statsout             l_statsouttype
      l_thisdata             l_thisword             l_totalpstypes         l_varstats
      l_wordlist             l_bigndsetin           l_bigndsetout          l_groupbyvarsnototal
      l_n                    l_totalforvars         l_varprefix            l_totalbignyn
      l_filltotal0yn         l_analysisvarnamevar   l_length               l_countdistinctwhatvar
      l_psformatbign         
      ;
   %do l_i=0 %to 20;
      %local l_groupbyvarsanaly&l_i l_groupstatements&l_i l_groupsummarytype&l_i
             l_groupbyvarsminmax&l_i l_groupsummarytypecode&l_i l_codelist&l_i l_psformat&l_i;
      %do l_j=0 %to 20;
          %local l_totalsummarytype&l_j._&l_i l_totalsummarytypecode&l_j._&l_i ;
      %end;
   %end; /* end of %do-%to loop */
   %do l_i=0 %to 20;
      %local l_totalstatements&l_i l_totaldenomyn&l_i l_ifstatements l_totalbignyn&l_i
             l_denomsummarytype&l_i l_denomsummarytypecode&l_i l_bignsummarytype&l_i 
             l_bignsummarytypecode&l_i;
   %end;
   %do l_i=0 %to 20;
      %local l_totalfmtvar&l_i l_totalid&l_i l_totaldecode&l_i;
   %end;
   %let l_codeinpsformat=0;
   %let l_debug=0;
   %let l_denomvarname=tt_denomcnt;
   %let l_fmtprefix=_fmt;
   %let l_message2=;
   %let l_numervarname=tt_numercnt;
   %let l_numof_byvars=0;
   %let l_numof_codes=0;
   %let l_numof_fmtvars=0;
   %let l_numof_totals=0;
   %let l_numof_noncmpvars=0;
   %let l_prefix=_tstats_;
   %let l_rc=0;
   %let l_filltotal0yn=0;
   %let l_varprefix=tt0_;
   %let l_countdistinctwhatvar=&countdistinctwhatvar;
   
   /*
   / Unquoted the variable that will be get with symget function.
   /-----------------------------------------------------------------*/   
   %let analysisVar         =%unquote(&analysisVar);
   %let codedecodevarpairs  =%unquote(&codedecodevarpairs);
   %let psclassoptions      =%unquote(&psclassoptions);
   %let psformat            =%unquote(&psformat);
   %let groupbyvarsanaly    =%unquote(&groupbyvarsanaly);
   %let groupminmaxvar      =%unquote(&groupminmaxvar);
   %let totalforvar         =%unquote(&totalforvar);
   %let groupbyvarsanaly    =%unquote(&groupbyvarsanaly);
   %let groupbyvarpop       =%unquote(&groupbyvarpop);
   %let totalid             =%unquote(&totalid);
   %let totaldecode         =%unquote(&totaldecode);
   %let totalforvar         =%unquote(&totalforvar);
   %let groupbyvarsdenom    =%unquote(&groupbyvarsdenom);
   %let analysisvarname     =%unquote(&analysisvarname);
   %let completetypesvars   =%unquote(&completetypesvars);
   %let psoptions           =%unquote(&psoptions);   
   /*
   / Parameter validation:
   /
   / Check if any required parameters is blank
   /---------------------------------------------------------------------------*/
   %let l_wordlist=ADDBIGNYN DSETINANALY REMSUMMARYPCTYN DSETOUT VARLABELSTYLE;
   %do l_i = 1 %to 5;
      %let l_thisword=%scan(&l_wordlist, &l_i);
      %if %nrbquote(&&&l_thisword) eq %then 
      %do;
         %let l_message1=Required parameter &l_thisword is blank;
         %goto macerr;
      %end;
   %end; /* end of do-to loop on &l_i;
   /*
   / Check if any given variable names is a valid SAS variable name
   /---------------------------------------------------------------------------*/
   %let l_wordlist=BIGNVARNAME COUNTVARNAME RESULTVARNAME ANALYSISVARFORMATDNAME SUMMARYLEVELVARNAME;
   %do l_i = 1 %to 5;
      %let l_thisword=%scan(&l_wordlist, &l_i);
      %if %nrbquote(&&&l_thisword) ne %then 
      %do;
         %if %nrbquote(%tu_chknames(&&&l_thisword, VARIABLE)) ne %then 
         %do;
            %let l_message1=Given value of parameter &l_thisword is not a valid SAS variable name: &l_thisword=&&&l_thisword ;
            %goto macerr;
         %end;
      %end; /* end-if on &&&l_thisword is not blank */
   %end; /* end of do-to loop on &l_i */
   
   /*
   / Check if BIGNLABELSPLITCHAR is valid
   /---------------------------------------------------------------------------*/
   %if %length(&bignlabelsplitchar) gt 2 %then 
   %do;
       %let l_message1=Given value of parameter BIGNLABELSPLITCHAR (=&bignlabelsplitchar) is invalid. It should be a single character.;
       %goto macerr;   
   %end;     
   /*
   /  Check if any of &ADDBIGNYN, &BIGNVARNAME and &REMSUMMARYPCTYN is valid
   /  If &ADDBIGNYN equals Y, check if any of &BIGNVARNAME and &GROUPBYVARPOP
   /  is blank
   /---------------------------------------------------------------------------*/
   %let l_wordlist=ADDBIGNYN REMSUMMARYPCTYN;
   %do l_i = 1 %to 2;
      %let l_thisword=%scan(&l_wordlist, &l_i);
      %if (%qupcase(&&&l_thisword) ne Y) and (%qupcase(&&&l_thisword) ne N) %then 
      %do;
          %let l_message1=Given value of parameter &l_thisword is invalid. The valid should be Y or N;
          %goto macerr;
      %end;
   %end; /* end of do-to loop on &l_i */
   %if ( %upcase(&addbignyn) eq Y ) and ( %nrbquote(&bignvarname) eq ) %then 
   %do;
      %let l_message1=ADDBIGNYN equals Y, but BIGNVARNAME is blank. Please specify a BIGNVARNAME;
      %goto macerr;
   %end;
   %if ( %upcase(&addbignyn) eq Y ) and ( %nrbquote(&groupbyvarpop) eq ) and (%nrbquote(&totalforvar) eq ) %then 
   %do;
      %let l_message1=ADDBIGNYN equals Y, but GROUPBYVARPOP is blank. Please specify GROUPBYVARPOP;
      %goto macerr;
   %end;
   %if %nrbquote(&totalforvar) eq %then 
   %do;
      %let totalid=;
      %let totaldecode=;
   %end;
                                                                                
   /*
   /  Check if &DSETINANALY exists and if there records in it.
   /---------------------------------------------------------------------------*/
   %let l_rc=%tu_nobs(&dsetinanaly);
   %if &g_abort ne 0 %then %goto macerr;
   %if &l_rc lt 0 %then %goto macerr;
                
   /*
   /  Check if &DSETOUT is a valid SAS data set name
   /---------------------------------------------------------------------------*/
   %let l_thisword=%qscan(&dsetout, 1, %str(%());
   %if %nrbquote(&l_thisword) ne %then 
   %do;
      %if %tu_chknames(&l_thisword, DATA ) ne %then 
      %do;
          %let l_message1=Macro Parameter DSETOUT refers to dataset &l_thisword which is not a valid dataset name;
          %goto macerr;
      %end;
   %end; /* end -if on &l_thisword is not blank */
   %if %nrbquote(&summarylevelvarname) eq  %then   /* YW002: */
   %do;
      %let summaryLevelVarName=tt_summaryLevel_autoname;
      %put RTN%str(OTE:) &sysmacroname: Updated macro parameter SUMMARYLEVELVARNAME=&summaryLevelVarName;
   %end;
   /*
   / Check if codedecodevarpairs is in pair.
   /---------------------------------------------------------------------------*/
   %if %nrbquote(&codedecodevarpairs) ne %then 
   %do;
      %let l_rc=%tu_words(&codedecodevarpairs);
      %let l_numof_codes=%eval(&l_rc / 2);
      %if %sysfunc(mod(&l_rc, 2)) ne 0 %then 
      %do;
         %let l_message1=Variables given by CODEDECODEVARPAIRS are not in pair;
         %goto macerr;
      %end;
   %end;  /* end-if on &codedecodevarpairs is not blank */
   /*
   / Get numeric variable list from &dsetinanaly
   /---------------------------------------------------------------------------*/
   data _null_;
      length &l_varprefix.numeric_var_list $2000;
      if 0 then set &dsetinanaly;
      array &l_varprefix.numeric_var_array{*} _NUMERIC_;
      &l_varprefix.numeric_var_list='';
      do &l_varprefix.int_numeric_var_array_loop=1 to dim(&l_varprefix.numeric_var_array);
         &l_varprefix.numeric_var_list=trim(left(&l_varprefix.numeric_var_list))||' '||left(vname(&l_varprefix.numeric_var_array{&l_varprefix.int_numeric_var_array_loop}));
      end;
      call symput('l_numericvarlist', trim(left(upcase(&l_varprefix.numeric_var_list))));
   run;
   /*
   / Call %tu_getdata to get POP data.
   /-------------------------------------------------------------------------*/
   %tu_getdata(
      dsetin   =&dsetinanaly,
      dsetout1 =&l_prefix._getNumer,
      dsetout2 =&l_prefix._getPop
      )
   %if %nrbquote(&g_abort) gt 0 %then %goto macerr;
   %let l_dsetinpop=&l_prefix._getPop;
   /*
   /  data _null_ step to make following processings:
   /  1. Extract statements surrounded by () from &groupbyvarsanaly and split
   /     &groupbyvarsanaly to several summary level groups.
   /  2. Get &PSFORMAT for each summary level groups
   /  3. Split codedecodevarpairs into code and decode.
   /  4. Get CODE and DECODE list for each summary level groups.
   /  5. Remove decode from &groupbyvarsanaly, &GROUPBYVARPOP and &GROUPBYVARSDENOM
   /  6. If MIN or MAX is in &ANALYSISVAR in the format MIN({variable name}),
   /     Remove MIN or MAX and keep only variable name.
   /  7. Get &TOTALID and &TOTALDECODE for each total level given by &TOTALFORVAR
   /  8. Get &TOTALFORVAR for each summary level group and convert the total level
   /     in &TOTALFORVAR to relative numeric value. For example, if the total level
   /     is a*b in &TOTALFORVAR and &GROUPBYVARS=c a b d, then the value should be
   /     6 (0110).
   /  9. Get variables in &TOTALFORVAR which have no decode
   / 10. Get variables in &TOTALFORVAR which is also in &DSETINDENOM.
   / 11. Get the last variable in &GROUPBYVARPOP, which bigN will be added to and
   /     get the &TOTALID of it if it is also in &TOTALFORVAR
   /---------------------------------------------------------------------------*/
   data _NULL_;
      length totalstatements     $1000
             analysisvarname
             analysisvar
             bigntotalid
             bigntovar
             bigntovardecodevar
             codedecodevarpairs
             codelist
             completetypesvars
             noncompletetypesvars
             psoptions
             decodelist
             groupminmaxvar
             groupbyvarsnototal
             denomgroupnototal
             groupbyvarpop
             groupbyvars
             groupbyvarsdenom
             groupbyvarsanaly
             groupcodelist
             groupsource
             groupstatements
             ifstatements
             totalifstatements
             bignifstatements
             newpsformat
             newgroupbyvarsanaly
             parmvar
             psformat
             rmdcd_pairs
             summarytype
             t_message1
             t_message2
             totaldecode
             totaldecodelist
             totalforvar
             totalforvardecode
             totalforvars
             totalforvarlist
             totalonlyvars
             newtotalforvarlist
             totalgroup
             totaldenomgroup
             totalbigngroup
             totalid
             totalidlist
             totalsubset
             var
             var1
             var2
             subvar1
             subvar2
             varstats  $500
             ;
      array arrgroupbyvars{0 : 10} $200 _TEMPORARY_ ;
      rx1=rxparse("$n$c* $w* [ $(10) ] [ $w* '*' $w*  $n$c* $w* [ $(10) ] ]") ;
      rx2=rxparse("$n$c* [$w* $(10) ]") ;
      rx3=rxparse("$(10)") ;
      rx4=rxparse("$q | (~' ')*");
      analysisVar        = upcase(symget("analysisVar"));
      codedecodevarpairs = upcase(symget("codedecodevarpairs"));
      
      link spmmvar;      
      link spcddcd;
      link gettotal;
      link spgrpby;      
      link bignvar;
      link sptotal;
      link rowlabel;      
      link cmptyps;
      link freerx;
      
      /*
      / The following is for fixing the bugs in %tu_stats.
      /---------------------------------------------------------------------------*/
      call symput('psclassoptions', trim(upcase(symget("psclassoptions"))));
      return;
      
   /*
   /  Subroutins which are called only once from the main step are from here   
   /------------------------------------------------------------------------------
   /  Split CODE and DECODE from &CODEDECODEVARPAIRS.
   /------------------------------------------------------------------------------*/
   SPCDDCD:
      psformat=symget("psformat");
      /* a flag to decide if the decode should be overwrite after calling %tu_stats.
      /  If the code is in &psformat, the value is set to 1.
      /---------------------------------------------------------------------------*/
      int_codeinpsformat=0; 
      do int_spcddcd=1 to &l_numof_codes * 2 by 2;
         if indexw(upcase(psformat), scan(codedecodevarpairs, int_spcddcd, ' ')) gt 0 then
            int_codeinpsformat=1;
         codelist=left(trim(codelist)||' '||scan(codedecodevarpairs, int_spcddcd));
         decodelist=left(trim(decodelist)||' '||scan(codedecodevarpairs, int_spcddcd + 1));
      end; /* end of do-to loop */
      /*
      / Upcase the variable in PSFORMAT. It is for fixing the bugs in %tu_stats.
      /---------------------------------------------------------------------------*/
      int_spcddcd=1;
      var2='';
      var1=scan(psformat, int_spcddcd, ' ');
      do while (var1 ne '');
         if index(var1, '.$') eq 0 then var1=upcase(var1);
         var2=trim(left(var2))||' '||left(var1);
         int_spcddcd=int_spcddcd + 1;
         var1=scan(psformat, int_spcddcd, ' ');
      end; /* end of do-while loop */
      psformat=left(var2);
      call symput('l_codeinpsformat', put(int_codeinpsformat, 1.0));
      call symput('l_psformat0', trim(left(psformat)));
      call symput('l_codelist', trim(left(codelist)));
      call symput('l_decodelist', trim(left(decodelist)));
      return;
      
   /*
   / Split the &groupminmaxvar into varstats and groupminmaxvar.
   /---------------------------------------------------------------------------*/
   SPMMVAR:
      groupminmaxvar = upcase(symget("groupminmaxvar"));
    
      if scan(groupminmaxvar, 1, '()') ne '' then 
      do;
         varstats=scan(groupminmaxvar, 1, '()');
         groupminmaxvar=scan(groupminmaxvar, 2, '()');
      end;
      else do;
         varstats="";
         groupminmaxvar='';
      end;
      if (varstats ne '') and (varstats not in ('MIN' 'MAX') or groupminmaxvar eq '') then 
      do;
         t_message1="The syntax of GROUPMINMAXVAR is incorrect. It should be MIN({variable name}) or MAX({variable name})";
         link exit;
      end;
            
      call symput('l_varstats', trim(left(varstats)));
      call symput('groupminmaxvar', trim(left(groupminmaxvar)));
      return;      
   
   /*
   /  Remove mixmaxvar from groupbyvars
   /---------------------------------------------------------------------------*/         
   RMMMVAR:
      parmvar=groupminmaxvar;
      link getdcd;
      if groupminmaxvar eq parmvar then 
      do;
         link getcode;
      end;
      
      int_rmmvar=indexw(upcase(groupbyvars), upcase(parmvar));
      if int_rmmvar gt 0 then 
      do;
         substr(groupbyvars, int_rmmvar, length(parmvar))='';
         groupbyvars=compbl(groupbyvars);
      end;
      
      int_rmmvar=indexw(upcase(groupbyvars), upcase(groupminmaxvar));
      if int_rmmvar gt 0 then 
      do;
         substr(groupbyvars, int_rmmvar, length(groupminmaxvar))='';
         groupbyvars=compbl(groupbyvars);
      end;
      return;                              
   /*
   / Get a list of variables given in &totalforvar. The list will be saved in
   / variable newtotalforvarlist.
   /---------------------------------------------------------------------------*/
   GETTOTAL:  
      totalforvarlist    = symget("totalforvar");
      newtotalforvarlist = '';
      call rxsubstr(rx1, totalforvarlist, pos1, len1);
      do while ((pos1 eq 1) and (len1 gt 0));     
         var1=substr(totalforvarlist, pos1, len1);
         if length(totalforvarlist) gt len1 then
              totalforvarlist=trim(left(substr(totalforvarlist, pos1 + len1)));
         else totalforvarlist='';
         /* split variables separated by star sign */
         call rxsubstr(rx2, var1, pos2, len2);
         do while ((pos2 gt 0) and (len2 gt 0));
            var2=substr(var1, pos2, len2);
            if length(var1) gt len2 then
               var1=trim(left(substr(var1, pos2 + len2)));
            else var1='';
            %*** split () from var() ***;
            call rxsubstr(rx3, var2, pos3, len3);
            if (pos3 gt 1) and (len3 gt 0) then 
               totalforvar=upcase(substr(var2, 1, pos3 - 1));            
            else
               totalforvar=upcase(var2);
            
            parmvar=totalforvar;
            link getcode;
            totalforvar=parmvar;
            if indexw(newtotalforvarlist, totalforvar) eq 0 then                             
               newtotalforvarlist=trim(left(newtotalforvarlist))||' '||left(totalforvar);
            call rxsubstr(rx2, var1, pos2, len2);   
         end;
         call rxsubstr(rx1, totalforvarlist, pos1, len1);
      end;
      if (pos1 gt 1) or (totalforvarlist ne '') then 
      do;
         t_message1="Syntax error is found in TOTALFOVAR. The syntax should be the repeat of 'variable1 [(value11 value12 ...) [ * variable2 [ (value21 value22 ...)]]]'";
         link exit;
      end;                 
      return;
   /*
   /  Get groups given by groupbyvarsanaly
   /  int_numof_byvars: Number of groups in &groupbyvarsanaly separated by 
   /                    the statement in ().
   /  newgroupbyvars: All group variables in &groupbyvarsanaly.
   /---------------------------------------------------------------------------*/
   SPGRPBY:
      int_numof_byvars = 0;
      groupbyvarsanaly = symget("groupbyvarsanaly");
      if upcase(groupbyvarsanaly) eq '_NONE_' then groupbyvarsanaly='';
      newgroupbyvars   = '';
      call rxsubstr(rx3, groupbyvarsanaly, int_pos, int_len);
      do while((int_pos GT 0) and (int_len gt 0));
         if int_pos GT 1 then
            newgroupbyvarsanaly=trim(left(newgroupbyvarsanaly))||' '||left(upcase(substr(groupbyvarsanaly, 1, int_pos -1)));
         if int_len le 2 then 
         do;
            t_message1="The statement inside of () given by GROUPVYVARSNUMER is blank";
            link exit;
         end;
         groupstatements=trim(left(substr(groupbyvarsanaly, int_pos + 1, int_len - 2)));
         groupbyvarsanaly=substr(groupbyvarsanaly, int_pos + int_len);
         call rxsubstr(rx3, groupbyvarsanaly, int_pos, int_len);
         %if %nrbquote(&statslist) eq %then 
         %do;
            if ( analysisvar ne '' ) and (indexw(newgroupbyvarsanaly, analysisvar) eq 0) then
               newgroupbyvarsanaly=trim(left(newgroupbyvarsanaly))||' '||left(analysisvar);
         %end;
         int_numof_byvars=int_numof_byvars + 1;
         arrgroupbyvars{int_numof_byvars}=newgroupbyvarsanaly;
         call symput(compress('l_groupstatements'||put(int_numof_byvars, 1.0)), trim(left(groupstatements)));
      end; /* end of do-while loop */
      newgroupbyvarsanaly=trim(left(newgroupbyvarsanaly))||' '||upcase(trim(left(groupbyvarsanaly)));
      /* Add &analysisvar to &groupbyvarsanaly for FREQ */                     
      %if %nrbquote(&statslist) eq %then 
      %do;
         if ( analysisvar ne '' ) and (indexw(newgroupbyvarsanaly, analysisvar) eq 0) then
            newgroupbyvarsanaly=trim(left(newgroupbyvarsanaly))||' '||left(analysisvar);
      %end;
      arrgroupbyvars{0}=newgroupbyvarsanaly;
      
      /* get variables that in &totalforvars, but not in &groupbyvarsnumer */
      totalonlyvars='';      
      int_numof_totalonlyvars=0;      
      int_i=1;                                   
      var1=scan(newtotalforvarlist, int_i, ' ');
      do while (var1 ne '');      
        if indexw(newgroupbyvarsanaly, var1) eq 0 then 
        do;
           totalonlyvars=trim(left(totalonlyvars))||' '||left(var1);           
           int_numof_totalonlyvars=int_numof_totalonlyvars + 1;        
        end;
        int_i=int_i + 1;
        var1=scan(newtotalforvarlist, int_i, ' ');  
      end;
      
      groupsource="groupbyvarsanaly";
      do int_spgrpby_loop=0 to int_numof_byvars;     
         groupbyvars=arrgroupbyvars{int_spgrpby_loop};      
         link rmdcd;
         arrgroupbyvars{int_spgrpby_loop}=groupbyvars;
         
         /* Get the flag which decides if groupbyvars has the code-decode */             
         groupcodelist='';
         do t_i=1 to &l_numof_codes;
            if indexw(groupbyvars, scan(codelist, t_i, ' ')) gt 0 then
               groupcodelist=trim(left(groupcodelist))||' 1';
            else
               groupcodelist=trim(left(groupcodelist))||' 0';
         end;
           
         if int_numof_totalonlyvars gt 0 then 
            arrgroupbyvars{int_spgrpby_loop}=trim(left(totalonlyvars))||' '||left(arrgroupbyvars{int_spgrpby_loop});
            
         groupbyvars=arrgroupbyvars{int_spgrpby_loop};
         call symput(compress('l_groupbyvarsanaly'||put(int_spgrpby_loop, 1.0)), trim(left(groupbyvars)));
         arrgroupbyvars{int_spgrpby_loop}=groupbyvars;
         
         link rmmmvar;        
         call symput(compress('l_groupbyvarsminmax'||put(int_spgrpby_loop, 1.0)), trim(left(groupbyvars)));
         
         /* get &l_psformat and &l_codelist for current groupbyvars */                        
         groupbyvars=arrgroupbyvars{int_spgrpby_loop};
         link getpsfmt;
         
         call symput(compress('l_psformat'||put(int_spgrpby_loop, 1.0)), trim(left(newpsformat)));
         call symput(compress('l_codelist'||put(int_spgrpby_loop, 1.0)), trim(left(groupcodelist)));
         /* Get &PSTYPES and the code of the &PSTYPES for current groupbyvars */          
         if int_spgrpby_loop eq 0 then 
         do;
            newgroupbyvarsanaly=arrgroupbyvars{0};
         end;
         
         if int_numof_totalonlyvars gt 0 then 
         do;                                          
            call symput(compress('l_groupsummarytype'||put(int_spgrpby_loop, 1.0)), '');
            call symput(compress('l_groupsummarytypecode'||put(int_spgrpby_loop, 1.0)), '');
         end;     
         else do;
            groupbyvars=arrgroupbyvars{int_spgrpby_loop};
            parmvar=groupbyvars;            
            link gettype;            
            call symput(compress('l_groupsummarytype'||put(int_spgrpby_loop, 1.0)), trim(left(summarytype)));
            call symput(compress('l_groupsummarytypecode'||put(int_spgrpby_loop, 1.0)), left(put(summarytypecode, best12.)));
         end;
         
      end; /* end of do-to loop on int_spgrpby_loop */
      call symput(compress('l_numof_byvars'), compress(put(int_numof_byvars, 1.0)));
      return;
      
   /*
   /  Remove DECODE from GROUPBYVARPOP. Take the last variable in GROUPBYVARPOP
   /  as the variable to add big N to.
   /------------------------------------------------------------------------------*/
   BIGNVAR:
      groupbyvarpop=upcase(symget("groupbyvarpop"));
      groupsource="GROUPBYVARPOP";
      
      /* this is only for being compatible with old version of %tu_freq */                                        
      if (groupbyvarpop eq '_NONE_') or (groupbyvarpop eq '') then 
      do;
         groupbyvarpop=totalonlyvars;
      end;
      if groupbyvarpop ne '' then 
      do;
         groupbyvars=groupbyvarpop;
         link rmdcd;
         groupbyvarpop=groupbyvars;
         link getpsfmt;
         call symput('l_psformatbign', trim(left(newpsformat)));

         bigntovar=scan(groupbyvarpop, -1, ' ');
         parmvar=bigntovar;
         link getdcd;
         if parmvar ne bigntovar then bigntovardecodevar=parmvar;
         
         parmvar=groupbyvarpop;
         groupbyvars=groupbyvarpop;
         link gettype;
      
         int_totalbignyn=1;
      end;
      else do;
         summarytype='';
         summarytypecode=0;
         int_totalbignyn=0;
      end; /* end-if on groupbyvarpop ne '' */                 
      call symput('l_totalbignyn0', put(int_totalbignyn, 1.0));      
      call symput('l_bignsummarytype0', trim(left(summarytype)));      
      call symput('l_bignsummarytypecode0', compress(put(summarytypecode,best12.)));
      call symput('l_groupbyvarpop', trim(left(groupbyvarpop)));
      call symput('l_bigntovar', trim(left(bigntovar)));
      call symput('l_bigntovardecodevar', trim(left(bigntovardecodevar)));
      return;
   /*
   / Get &TOTALID and &TOTALDECODE for each total level given by &TOTALFORVAR
   / Get &TOTALFORVAR for each summary level group and convert the total level
   / in &TOTALFORVAR to relative numeric value. For example, if the total level
   / is a*b in &TOTALFORVAR and &GROUPBYVARS=c a b d, then the value should be
   / 6 (0110).
   / Get variables in &TOTALFORVAR which have no decode
   /---------------------------------------------------------------------------*/
   SPTOTAL:
      totalidlist        = symget("totalid");
      totaldecodelist    = symget("totaldecode");
      totalforvarlist    = symget("totalforvar");
      groupbyvarsdenom   = symget("groupbyvarsdenom");
      groupbyvarsnototal = arrgroupbyvars{0};
      totalforvars       = '';
      
      /* this is only for being compatible with old version of %tu_freq */                                        
      if (groupbyvarsdenom eq '') or (upcase(groupbyvarsdenom) eq '_NONE_') then 
      do;
         groupbyvarsdenom=totalonlyvars;
      end;
      
      int_numof_totals   = 0;
      int_numof_fmtvars  = 0;
      call symput('l_groupbyvarsdenom', trim(left(groupbyvarsdenom)));
      groupsource="GROUPBYVARSDENOM";
      groupbyvars=upcase(groupbyvarsdenom);
      link rmdcd;
      groupbyvarsdenom=groupbyvars;
      link getpsfmt;
      denomgroupnototal=groupbyvarsdenom;
      
      call symput('l_psformatdenom', trim(left(newpsformat)));
      call symput('l_groupbyvarsdenom', trim(left(groupbyvarsdenom)));
      if groupbyvars ne '' then 
      do;
         parmvar=groupbyvarsdenom;
         groupbyvars=groupbyvarsdenom;
         link gettype;
         int_totaldenomyn=1;
      end;
      else do;
         summarytype='';
         summarytypecode=0;
         int_totaldenomyn=0;
      end;
      call symput('l_totaldenomyn0', put(int_totaldenomyn, 1.0));
      call symput('l_ifstatements0', '');
      call symput('l_denomsummarytype0', trim(left(summarytype)));      
      call symput('l_denomsummarytypecode0', compress(put(summarytypecode,best12.)));     
      /* loop over the TOTALFORVARLIST to get each total group */;
      call rxsubstr(rx1, totalforvarlist, pos1, len1);
      
      do while ((pos1 eq 1) and (len1 gt 0));
         totalgroup="";
         totaldenomgroup="";
         totalbigngroup="";
         ifstatements="";
         totalstatements="";
         totalifstatements="";
         bignifstatements="";
         var1=substr(totalforvarlist, pos1, len1);
         if length(totalforvarlist) gt len1 then
              totalforvarlist=trim(left(substr(totalforvarlist, pos1 + len1)));
         else totalforvarlist='';
         /* split variables separated by star sign */
         call rxsubstr(rx2, var1, pos2, len2);
         do while ((pos2 gt 0) and (len2 gt 0));
            var2=substr(var1, pos2, len2);
            if length(var1) gt len2 then
               var1=trim(left(substr(var1, pos2 + len2)));
            else var1='';
            %*** split () from var() ***;
            call rxsubstr(rx3, var2, pos3, len3);
            if (pos3 gt 1) and (len3 gt 0) then 
            do;
               totalforvar=upcase(substr(var2, 1, pos3 - 1));
               parmvar=totalforvar;
               link getcode;
               totalforvar=parmvar;
               totalsubset=substr(var2, pos3, len3);
               if ifstatements ne '' then ifstatements=trim(left(ifstatements))||' and';
               ifstatements=trim(left(ifstatements))||' '||compress(totalforvar)||' in '||trim(left(totalsubset));
            end;
            else do;
               totalforvar=upcase(var2);
               parmvar=totalforvar;
               link getcode;
               totalforvar=parmvar;
               totalsubset='';
            end;
            
            /* remove totalforvar from groupbyvarsanaly to get groupbyvarsnototal */
            parmvar=groupbyvarsnototal;
            groupbyvars=totalforvar;
            link gettgp;
            groupbyvarsnototal=parmvar;
            
            /* Get a list of total for variables */   
            parmvar=totalforvar;
            link getdcd;
            var=parmvar;            
         
            if totalforvars ne '' then 
            do;                                
               groupbyvars=trim(left(totalforvar))||" "||trim(left(var));
               parmvar=totalforvars;
               link gettgp;
               totalforvars=parmvar;
            end;
            
            if var eq totalforvar then var=' ';
            totalforvars=trim(left(totalforvars))||' '||trim(left(totalforvar))||' '||trim(left(var));           
            /* get code and decode of the totalforvar */
            call rxsubstr(rx4, totalidlist, postotalidlist, lentotalidlist);
            if ( postotalidlist eq 1 ) and (lentotalidlist gt 0) then 
            do;
                totalid=substr(totalidlist, postotalidlist, lentotalidlist);
                /* YW005 */
                if (indexw(symget("l_numericvarlist"), totalforvar) gt 0) and  
                   (( verify(trim(left(totalid)), '0123456789.') gt 0 ) or (scan(totalid, 2, ' ') ne '')) then 
                do;
                   t_message1="TOTALFORVAR "||trim(left(totalforvar))||
                              " is a numeric variable, but given TOTALID is not a numeric value. TOTALID="||
                              left(totalid);
                   link exit;
                end; /* end-if on (indexw("&l_numericvarlist", totalforvar) gt 0) */
                
                /* YW005 */
                if ( substr(totalid, 1, 1) not in ('"', "'") ) and (indexw(symget("l_numericvarlist"), totalforvar) eq 0)
                then totalid='"'||compress(totalid)||'"';
                if length(totalidlist) gt lentotalidlist then
                   totalidlist=left(substr(totalidlist, postotalidlist + lentotalidlist));
                else totalidlist='';
                totalstatements=trim(left(totalstatements))||' '||compress(totalforvar)||'='||trim(left(totalid))||';';
            end; /* end if on ( postotalidlist eq 1 ) and (lentotalidlist gt 0) */
            call rxsubstr(rx4, totaldecodelist, postotalidlist, lentotalidlist);
            if ( postotalidlist eq 1 ) and (lentotalidlist gt 0) then 
            do;
                totaldecode=substr(totaldecodelist, postotalidlist, lentotalidlist);
                if indexc(totaldecode, '"', "'") eq 0 then totaldecode='"'||compress(totaldecode)||'"';
                if length(totaldecodelist) gt lentotalidlist then
                   totaldecodelist=left(substr(totaldecodelist, postotalidlist + lentotalidlist));
                else totaldecodelist='';
                parmvar=totalforvar;
                link getdcd;
                totalforvardecode=parmvar;
                if parmvar ne totalforvar then 
                do;
                    totalstatements=trim(left(totalstatements))||' '||compress(parmvar)||'='||trim(left(totaldecode))||';';
                end;
                else do;
                   int_numof_fmtvars=int_numof_fmtvars + 1;
                   call symput(compress('l_totalfmtvar'||put(int_numof_fmtvars, 1.0)), trim(left(totalforvar)));
                   call symput(compress('l_totalid'||put(int_numof_fmtvars, 1.0)), trim(left(totalid)));
                   call symput(compress('l_totaldecode'||put(int_numof_fmtvars, 1.0)), trim(left(totaldecode)));
                end;
            end;
            else totaldecode=""; /* end-if on  ( postotalidlist eq 1 ) and (lentotalidlist gt 0) */
            /* Added total variable to bigN calculation */                                                                                                            
            if totalforvar eq bigntovar then 
            do;
               bigntotalid=totalid;
            end;
            else if totalforvardecode eq bigntovar then 
            do;
               bigntotalid=totaldecode;
            end;
            /* Added total variable to denominator calculation */                                            
            if indexw(groupbyvarsdenom, totalforvar) gt 0 then 
            do;
               totaldenomgroup=left(trim(left(totaldenomgroup))||' '||left(totalforvar));
               if totalsubset ne '' then 
               do;
                  if totalifstatements ne '' then totalifstatements=trim(left(totalifstatements))||' and';
                  totalifstatements=trim(left(totalifstatements))||' '||compress(totalforvar)||' in '||trim(left(totalsubset));
               end;
            end;           
            if indexw(groupbyvarpop, totalforvar) gt 0 then 
            do;
               totalbigngroup=left(trim(left(totalbigngroup))||' '||left(totalforvar));
               if totalsubset ne '' then 
               do;
                  if bignifstatements ne '' then bignifstatements=trim(left(bignifstatements))||' and';
                  bignifstatements=trim(left(bignifstatements))||' '||compress(totalforvar)||' in '||trim(left(totalsubset));
               end;              
            end;                      
            totalgroup=left(trim(left(totalgroup))||' '||left(totalforvar));
            call rxsubstr(rx2, var1, pos2, len2);
         end; /* end of do-while loop on ((pos2 gt 0) and (len2 gt 0)) */
         int_numof_totals=int_numof_totals + 1;
         do int_sptotal_i=0 to int_numof_byvars;
            parmvar=arrgroupbyvars{int_sptotal_i};
            groupbyvars=totalgroup;          
            link gettgp;
            groupbyvars=parmvar;            
            parmvar=arrgroupbyvars{int_sptotal_i};           
            link gettype;         
            call symput('l_totalsummarytype'||put(int_numof_totals, 1.0)||'_'||put(int_sptotal_i, 1.0), trim(left(summarytype)));
            call symput('l_totalsummarytypecode'||put(int_numof_totals, 1.0)||'_'||put(int_sptotal_i, 1.0), compress(put(summarytypecode,best12.)));
         end;
         call symput(compress('l_ifstatements'||put(int_numof_totals, 1.0)), trim(left(ifstatements)));
         call symput(compress('l_totalstatements'||put(int_numof_totals, 1.0)), trim(left(totalstatements)));
         if ( totaldenomgroup ne '' ) and ( groupbyvarsdenom ne '' ) then 
         do;
            groupbyvars=totaldenomgroup;
            parmvar=groupbyvarsdenom;
            link gettgp;
            groupbyvars=parmvar;
            parmvar=groupbyvarsdenom;
            link gettype;
            if totalifstatements eq '' then totalifstatements='1';
         end;
         else do;
            summarytype='';
            summarytypecode=0;
            totalifstatements='0';
         end;
         call symput('l_bigntotalid', trim(left(bigntotalid)));         
         call symput(compress('l_denomsummarytype'||put(int_numof_totals, 1.0)), trim(left(summarytype)));
         call symput(compress('l_denomsummarytypecode'||put(int_numof_totals, 1.0)), put(summarytypecode,best12.));
         call symput(compress('l_totaldenomyn'||put(int_numof_totals, 1.0)), trim(left(totalifstatements)));       
         if ( totalbigngroup ne '' ) and ( groupbyvarpop ne '' ) then 
         do;
            groupbyvars=totalbigngroup;
            parmvar=groupbyvarpop;
            link gettgp;
            groupbyvars=parmvar;
            parmvar=groupbyvarpop;
            link gettype;
            if bignifstatements eq '' then bignifstatements='1';           
         end;
         else do;
            summarytype='';
            summarytypecode=0;
            bignifstatements='0';
         end;                                 
         call symput(compress('l_bignsummarytype'||put(int_numof_totals, 1.0)), trim(left(summarytype)));
         call symput(compress('l_bignsummarytypecode'||put(int_numof_totals, 1.0)), put(summarytypecode,best12.));
         call symput(compress('l_totalbignyn'||put(int_numof_totals, 1.0)), trim(left(bignifstatements)));
         call rxsubstr(rx1, totalforvarlist, pos1, len1);
      end; /* end of do-while loop on ((pos1 eq 1) and (len1 gt 0)) */      
      call symput(compress('l_numof_totals'), put(int_numof_totals, 1.0));
      call symput(compress('l_numof_fmtvars'), put(int_numof_fmtvars, 1.0));
      call symput('l_groupbyvarsnototal', trim(left(groupbyvarsnototal)));     
      call symput('l_totalforvars', trim(left(totalforvars)));
      
      if (pos1 gt 1) or (totalforvarlist ne '') then 
      do;
         t_message1="Syntax error is found in TOTALFOVAR. The syntax should be the repeat of 'variable1 [(value11 value12 ...) [ * variable2 [ (value21 value22 ...)]]]'";
         link exit;
      end;
      return;
      
   /*
   / Construct ANALYSISVARNAME if no '=' in it.
   / YW003: Get variable name from the &ANALYSISVARNAME
   / ------------------------------------------------------------------------------------*/
   ROWLABEL:
      analysisvarname=left(symget("analysisvarname"));
      int_rowlabel_ind=index(analysisvarname, '=');
      var1='';
      if analysisvarname ne '' then
      do;
         if int_rowlabel_ind gt 1 then
            var1=substr(analysisvarname, 1, int_rowlabel_ind - 1);
         else
            var1=analysisvarname;
      end;  /* end-if on analysisvarname ne '' */   
      
      call symput('l_analysisvarnamevar', trim(left(var1)));
            
      if ( int_rowlabel_ind eq 0 ) and ( analysisvarname ne '' ) then 
      do;
         %if %nrbquote(&statslist) ne %then 
         %do;
            analysisvarname=trim(left(analysisvarname))||'=vlabel('||trim(left(analysisvar))||')';
         %end;
         %else %do;
            parmvar=scan(arrgroupbyvars{0}, -1, ' ');
            link getdcd;
            analysisvarname=trim(left(analysisvarname))||'=vlabel('||trim(left(parmvar))||')';
         %end;
      end; /* end if on ( int_rowlabel_ind eq 0 ) and ( analysisvarname ne '' ) */
      
      call symput('l_analysisvarname', trim(left(analysisvarname)));
      return;
   CMPTYPS:
   /*
   /  Remove &COMPLETETYPESVARS from &groupbyvarsanaly to get a list of
   /  NON-COMPLETETYPESVARS.
   /------------------------------------------------------------------------------*/
      completetypesvars=upcase(symget("completetypesvars"));
      psoptions=symget("psoptions");
      int_cmptyps_ind=indexw(upcase(psoptions), 'COMPLETETYPES');
      int_gmptyps_i=0;
      if (int_cmptyps_ind gt 0) and (completetypesvars ne '_ALL_') then 
      do;
         groupbyvars=completetypesvars;
         link rmdcd;
         completetypesvars=groupbyvars;
         if completetypesvars eq '' then 
         do;
            if int_cmptyps_ind gt 1 then var1=substr(psoptions, 1, int_cmptyps_ind - 1);
            else var1='';
            psoptions=trim(left(var1))||' '||substr(psoptions, int_cmptyps_ind + 13);
            noncompletetypesvars='';
            call symput('psoptions', trim(left(psoptions)));
         end;
         else do;
            groupbyvars=completetypesvars;
            parmvar=arrgroupbyvars{0};
            link gettgp;
            noncompletetypesvars=parmvar;
         end; /* end-if on completetypesvars eq '' */
      end;
      else do;  
         noncompletetypesvars='';
      end; /* end-if on (int_cmptyps_ind gt 0) and (completetypesvars ne '_ALL_') */
      
      if (completetypesvars not in ('', '_ALL_')) then  /* YW002: */
      do;
         int_gmptyps_i=1;
         var1=scan(completetypesvars, int_gmptyps_i, ' ');
         do while (var1 ne '');
            if (indexw(arrgroupbyvars{0}, var1) gt 0) or (indexw(decodelist, var1) gt 0) then 
            do;
               int_gmptyps_i=int_gmptyps_i + 1;
               var1=scan(completetypesvars, int_gmptyps_i, ' ');
            end;
            else do;
               t_message1="Variable "||trim(left(var1))||" in COMPLETETYPESVARS is either not a valid SAS variable or not in GROUPBYVARSANALY";
               link exit;
               leave;
            end;
         end; /* end of do-while loop on (var1 ne '') */
      end; /* end-if on (completetypesvars ne '') */
      
      int_gmptyps_i=0;
      do while (scan(noncompletetypesvars, int_gmptyps_i + 1, ' ') ne '');
         int_gmptyps_i=int_gmptyps_i + 1;
      end;
      
      call symput('l_numof_noncmpvars', put(int_gmptyps_i, 2.0));
      call symput(compress('l_noncompletetypesvars'), trim(left(noncompletetypesvars)));
      return;
           
   /*
   /  Subroutins which are called from other subrotines or called more than once
   /  are from here   
   /------------------------------------------------------------------------------
   /*
   /  Get CODE of variable PARMVAR
   /------------------------------------------------------------------------------*/
   GETCODE:
      do index_code=1 to &l_numof_codes;
         if parmvar eq scan(decodelist, index_code, ' ') then 
         do;
            parmvar=scan(codelist, index_code, ' ');
            leave;
         end;
      end;
      return;
   /*
   /  Get DECODE of variable PARMVAR
   /------------------------------------------------------------------------------*/
   GETDCD:
      do index_code=1 to &l_numof_codes;
         if parmvar eq scan(codelist, index_code, ' ') then 
         do;
            parmvar=scan(decodelist, index_code, ' ');
            leave;
         end;
      end;
      return;
   /*
   / Remove DECODE from GROUPBYVARS.
   /------------------------------------------------------------------------------*/
   RMDCD:
      do int_rmdcd_i=1 to &l_numof_codes ;
         int_ind_rmdcd_1=indexw(groupByVars, scan(codelist, int_rmdcd_i));
         int_ind_rmdcd_2=indexw(groupByVars, scan(decodelist, int_rmdcd_i));
         if (int_ind_rmdcd_1 GT 0) and (int_ind_rmdcd_2 GT 0) then 
         do;
            int_rmdcd_vlen=length(scan(decodelist, int_rmdcd_i));
            if int_ind_rmdcd_2 GT 1 then rmdcd_pairs=substr(groupByVars, 1, int_ind_rmdcd_2 - 1);
            else rmdcd_pairs="";
            groupByVars=trim(left(rmdcd_pairs))||" "||trim(substr(groupByVars, int_ind_rmdcd_2 + int_rmdcd_vlen + 1));
         end;
         else if (int_ind_rmdcd_1 eq 0) and (int_ind_rmdcd_2 gt 0) and (groupsource eq "groupbyvarsanaly" ) then 
         do;
            t_message1="DECODE '"||scan(decodelist, int_rmdcd_i)||"' is in "||trim(left(groupsource))||", but the CODE is not or not in right position.";
            t_message2="Please replace the DECODE with the CODE.";
            link exit;
         end; /* end if on (int_ind_rmdcd_1 GT 0) and (int_ind_rmdcd_2 GT 0) */
      end; /* end of do-to loop */
      groupbyvars=left(groupbyvars);
      return;
   /*
   / Remove variabes, which are in GROUPBVARS, from PARMVAR.
   /------------------------------------------------------------------------------*/
   GETTGP:
      int_gettgp_loop=1;
      subvar2='';
      subvar1=scan(parmvar, int_gettgp_loop, ' ');
      do while (subvar1 ne '');
         if indexw(groupbyvars, subvar1) eq 0 then
            subvar2=trim(left(subvar2))||' '||trim(left(subvar1));
         int_gettgp_loop=int_gettgp_loop + 1;
         subvar1=scan(parmvar, int_gettgp_loop, ' ');
      end; /* end of do-while loop */
      parmvar=left(subvar2);
      return;
   /*
   / Find PSFORMAT from the variables in GROUPBYVARS..
   /------------------------------------------------------------------------------*/
   GETPSFMT:
      newpsformat='';
      int_psfmt_loop=1;
      subvar1=scan(groupbyvars, int_psfmt_loop, ' ');
      do while (subvar1 ne '');
         int_psfmt_ind=indexw(upcase(psformat), subvar1);
         if int_psfmt_ind gt 0 then 
         do;
            subvar2=scan(substr(psformat, int_psfmt_ind), 2, ' ');
            if index(subvar2, '.') le 1 then subvar2='';
            newpsformat=trim(left(newpsformat))||' '||compress(subvar1)||' '||compress(subvar2);
         end; /* end-if on int_psfmt_ind gt 0 */
         int_psfmt_loop=int_psfmt_loop + 1;
         subvar1=scan(groupbyvars, int_psfmt_loop, ' ');
      end; /* end of do-while loop */
      newpsformat=left(newpsformat);
      return;      
   /*
   / Find type and type value of GROUPBYVARS for class PARMVAR
   /------------------------------------------------------------------------------*/
   GETTYPE:
      summarytype='';
      summarytypecode=0;
      int_gettype_loop=-1;
      if compress(parmvar) eq '' then return;
      subvar1=scan(parmvar, int_gettype_loop, ' ');
      do while (subvar1 ne '');
         if indexw(groupbyvars, subvar1) gt 0 then 
         do;
            summarytypecode=summarytypecode + 2**(int_gettype_loop * (-1) - 1);
            if summarytype eq '' then summarytype=subvar1;
            else summarytype=trim(left(subvar1))||'*'||trim(left(summarytype));
         end; /* end-if on indexw(groupbyvars, subvar1) gt 0 */
         int_gettype_loop=int_gettype_loop - 1;
         subvar1=scan(parmvar, int_gettype_loop, ' ');
      end; /* end of do-while loop */
      if compress(summarytype) eq '' then 
      do;
         summarytype='()';
         summarytypecode=0;
      end;
      return;
   EXIT:
      call symput('l_rc', '-1');
      call symput('l_message1', trim(left(t_message1)));
      call symput('l_message2', trim(left(t_message2)));
      link freerx;
      stop;
      return;
   FREERX:
      if rx1 gt 0 then call rxfree(rx1);
      if rx2 gt 0 then call rxfree(rx2);
      if rx3 gt 0 then call rxfree(rx3);
      if rx4 gt 0 then call rxfree(rx4);
      return;
   run;
   %if &l_rc lt 0 %then %goto macerr;
   
   /*
   / Requoted the variable that just be unquoted above.
   /-----------------------------------------------------------------*/   
   %let psclassoptions      =%nrquote(&psclassoptions);
   %let psformat            =%nrquote(&psformat);
   %let psoptions           =%nrquote(&psoptions);
   
   /*
   /  Display new defined local macro variables for debuging.
   /---------------------------------------------------------------------------*/

   %if &l_debug eq 1 %then 
   %do;
      %put l_numof_totals=&l_numof_totals;
      %put l_numof_byvars=&l_numof_byvars;
      %put l_groupbyvarsdenom=&l_groupbyvarsdenom;
      %put l_totalforvars=&l_totalforvars;
      %put l_groupbyvarsnototal=&l_groupbyvarsnototal;
      %put l_denomsummarytype0=&l_denomsummarytype0;      
      %put l_denomsummarytypecode0=&l_denomsummarytypecode0;
      %put l_bignsummarytype0=&l_bignsummarytype0;      
      %put l_bignsummarytypecode0=&l_bignsummarytypecode0;      
      %put l_varstats=&l_varstats;
      %put l_codelist=&l_codelist;
      %put l_decodelist=&l_decodelist;
      %do l_i=0 %to &l_numof_byvars;
         %put l_groupbyvarsanaly&l_i=&&l_groupbyvarsanaly&l_i;
         %put l_groupstatements&l_i=&&l_groupstatements&l_i;
         %put l_groupsummarytype&l_i=&&l_groupsummarytype&l_i;
         %put l_groupsummarytypecode&l_i=&&l_groupsummarytypecode&l_i;
         %put l_codelist&l_i=&&l_codelist&l_i;
         %put l_psformat&l_i=&&l_psformat&l_i;
         %do l_j=1 %to &l_numof_totals;
            %put l_totalsummarytype&l_j._&l_i=&&l_totalsummarytype&l_j._&l_i;
            %put l_totalsummarytypecode&l_j._&l_i=&&l_totalsummarytypecode&l_j._&l_i;
         %end;
      %end;
      %do l_i=1 %to &l_numof_totals;
         %put l_denomsummarytype&l_i=&&l_denomsummarytype&l_i;
         %put l_denomsummarytypecode&l_i=&&l_denomsummarytypecode&l_i;
         %put l_bignsummarytype&l_i=&&l_bignsummarytype&l_i;
         %put l_bignsummarytypecode&l_i=&&l_bignsummarytypecode&l_i;         
         %put l_ifstatements&l_i=&&l_ifstatements&l_i;
         %put l_totaldenomyn&l_i=&&l_totaldenomyn&l_i;
         %put l_totalbignyn&l_i=&&l_totalbignyn&l_i;
         %put l_totalstatements&l_i=&&l_totalstatements&l_i;
      %end;
      %do l_i=1 %to &l_numof_fmtvars;
         %put l_totaldecode&l_i=&&l_totaldecode&l_i;
         %put l_totalfmtvar&l_i=&&l_totalfmtvar&l_i;
         %put l_totalid&l_i=&&l_totalid&l_i;
      %end;
   %end; /* end-if on l_debug eq 1 */

   /*
   /  Set parameters for Frequency and Summary
   /---------------------------------------------------------------------------*/
   %if %nrbquote(&statslist) eq %then 
   %do;
      %let analysisvar=;
      %let analysisvarformatdname=;
      %if %nrbquote(countvarname) ne %then 
      %do;
         %let countvarname=&l_numervarname;
      %end;
   %end;
   %else %do;
      %let resultstyle=;
      %let dsetindenom=;
      %let l_countdistinctwhatvar=; /* YW006 */
   %end; /* end-if on %nrbquote(&statslist) eq */
   
   /*
   / Further parameter validation:
   /
   / Check if &ANALYSISVAR is blank
   / Check if &COUNTDISTINCTWHATVAR, &ANALYSISVAR, &CODEDECODEVARPAIRS and
   / &groupbyvarsanaly are in &DSETINANALY
   /---------------------------------------------------------------------------*/
   %if ( %nrbquote(&statslist) ne ) and ( %nrbquote(&analysisvar) eq ) %then 
   %do;
      %let l_message1="STATSLIST is not blank, but no variable is given in ANALYSISVAR";
      %goto exit;
   %end;
   
   %let l_wordlist=COUNTDISTINCTWHATVAR L_TOTALFORVARS L_groupbyvarsanaly0 ANALYSISVAR CODEDECODEVARPAIRS GROUPMINMAXVAR;
   
   /* YW006: Modified message to make it more detail */
   %do l_i = 1 %to 6;
      %let l_thisword=%scan(&l_wordlist, &l_i);
      %if %nrbquote(&&&l_thisword) ne %then 
      %do;
         %let l_rc=%tu_chkvarsexist(&dsetinanaly,  &&&l_thisword);
         %if %nrbquote(&g_abort) ne 0 %then %goto macerr;
         %if %nrbquote(&l_rc) eq -1 %then %goto macerr;
         %if %nrbquote(&l_rc) ne %then 
         %do;
            %if &l_thisword eq L_TOTALFORVARS %then %let l_thisword=TOTALFORVAR;
            %if &l_thisword eq L_ %then %let l_thisword=GROUPBYVARSANALY;
            %let l_message1=Variable(s), &l_rc, given by &l_thisword (=&&&l_thisword) are not in data set DSETINANALY(=&dsetinanaly);
            %goto macerr; 
         %end;
      %end;
   %end; /* end of do-to loop on &l_i;*/

   /*
   /  Create CODE and DECODE data set.
   /---------------------------------------------------------------------------*/
   %do l_i=1 %to &l_numof_codes;
      proc sort data=&dsetinanaly (keep=%scan(&l_codelist, &l_i, %str( )) %scan(&l_decodelist, &l_i, %str( )))
           out=&l_prefix.codedcdlist&l_i nodupkey;
         by %scan(&l_codelist, &l_i, %str( ));
      run;
   %end; /* end of do-to loop */
   /*
   /  Create non-completetypes data set.
   /---------------------------------------------------------------------------*/
   %if &l_numof_noncmpvars gt 1 %then 
   %do;
      proc sort data=&dsetinanaly out=&l_prefix.comp1 
           (keep=&l_noncompletetypesvars) nodupkey;
         by &l_noncompletetypesvars;
      run;
   
      proc summary data=&l_prefix.comp1 nway missing completetypes;
         class &l_noncompletetypesvars /missing;
         ways &l_numof_noncmpvars;
         output out=&l_prefix.comp2(keep=&l_noncompletetypesvars);
      run;
           
      data &l_prefix.noncomp;
         merge &l_prefix.comp1(in=&l_varprefix.__IN1__)
               &l_prefix.comp2(in=&l_varprefix.__IN2__);
         by &l_noncompletetypesvars ;
         if &l_varprefix.__IN1__ and &l_varprefix.__IN2__ then delete;
      run;
   %end; /* end-if on &l_numof_noncmpvars gt 1 */
   
   /*
   / Check if &COUNTDISTINCTWHATVAR and &GROUPBYVARPOP are in POP data
   / YW005: Add a condition to the check of variable existance in POP data set 
   / so that if addbigNYN equals N and &groupbyvarpop or &countdistinctwhatvar 
   / does not exist in POP dataset, don't call %tu_addbignyn.
   /---------------------------------------------------------------------------*/
   %if  (%nrbquote(&bignvarname) ne ) and (%nrbquote(&l_bigntovar) ne) and
       (( %nrbquote(&COUNTDISTINCTWHATVAR) ne ) or ( %nrbquote(&GROUPBYVARPOP) ne )) %then 
   %do;
      %let l_rc=%tu_chkvarsexist(&l_dsetinpop, &COUNTDISTINCTWHATVAR &GROUPBYVARPOP);
      %if %nrbquote(&g_abort) ne 0 %then %goto macerr;
      %if %nrbquote(&l_rc) eq -1 %then %goto macerr;
      %if ( %nrbquote(&l_rc) ne ) and (%upcase(&addbignyn) eq Y) %then 
      %do;
         %let l_message1=Following variables in COUNTDISTINCTWHATVAR or GROUPBYVARPOP are not in population data set: &l_rc;
         %goto macerr;
      %end;
      %else %if %nrbquote(&l_rc) ne %then
      %do;
         %let bignvarname=;
         %let l_bigntovar=;
      %end;
   %end;  /* end-if on (%nrbquote(&bignvarname) ne ) and (%nrbquote(&l_bigntovar) ne) */
   %if %nrbquote(&statslist) eq %then 
   %do;
      %if %nrbquote(&dsetindenom) eq %then 
      %do;
         %let dsetindenom=&l_dsetinpop;
      %end;
      %else %do;
         /*
         / &DSETINDENOM must exist and can not be empty.
         /---------------------------------------------------------------------*/
         %let l_rc=%tu_nobs(&dsetindenom);
         %if &g_abort ne 0 %then %goto macerr;
         %if &l_rc lt 0 %then %goto macerr;
         %if &l_rc eq 0 %then 
         %do;
            %let l_message1=No record is found in DSETINDENOM data set &dsetindenom.;
            %goto macerr;
         %end;
      %end;   /* end-if on &dsetindenom is blank */
      /*
      / Check if &COUNTDISTINCTWHATVAR and &GROUPBYVARSDENOM are in &DSETINDENOM
      /------------------------------------------------------------------------*/
      %if ( %nrbquote(&COUNTDISTINCTWHATVAR) ne)  or (  %nrbquote(&GROUPBYVARSDENOM) ne) %then 
      %do;
         %let l_rc=%tu_chkvarsexist(&dsetindenom, &COUNTDISTINCTWHATVAR &GROUPBYVARSDENOM);
         %if %nrbquote(&g_abort) ne 0 %then %goto macerr;
         %if %nrbquote(&l_rc) eq -1 %then %goto macerr;
        
         %if %nrbquote(&l_rc) ne %then 
         %do;
            %let l_message1=Following variables in COUNTDISTINCTWHATVAR or GROUPBYVARSDENOM are not in data set &dsetindenom given by DSETINDENOM: &l_rc;
            %goto macerr;
         %end;
      %end;
      /*
      / RESULTVARNAME should not be blank
      /------------------------------------------------------------------------*/
      %if %nrbquote(&resultVarName) eq  %then 
      %do;
         %let resultVarName=tt_result_autoname;
      %end;
      %if ( %qupcase(&remSummaryPctYN) ne Y ) and ( %qupcase(&remSummaryPctYN) ne N ) %then 
      %do;
         %let l_message1=Value of parameter REMSUMMARYPCTYN is invalid. The valid value is Y or N.;
         %goto macerr;
      %end;
      /*
      / If remSummaryPctYN then &RESULTSTYLE must also have: NUMER NUMERPCT NUMERDENOM
      / NUMERDENOMPCT;
      /------------------------------------------------------------------------*/
      %if %qupcase(&remSummaryPctYN) eq Y %then 
      %do;
         %let l_wordlist=NUMER NUMERPCT NUMERDENOM NUMERDENOMPCT;
         %if %sysfunc(indexw(&l_wordlist, %upcase(&resultstyle)) ) le 0 %then 
         %do;
            %let l_message1=Macro parameter REMSUMMARYPCTYN=&remSummaryPctYN: therefore parameter RESULTSTYLE must be one of the following: &l_wordlist;
            %goto macerr;
         %end;
      %end;  /* end-if on &remSummaryPctYN equals Y */
   %end; /* end-if on &statslist is blank */
   %do l_i=0 %to &l_numof_byvars;
      %do l_j=1 %to %to &l_numof_totals;
         %if ( %nrbquote(&&l_totalsummarytype&l_j._&l_i) eq %nrbquote(&&l_groupsummarytype&l_i) ) and
             ( %nrbquote(&&l_groupsummarytype&l_i) ne ) %then 
         %do;
            %let l_message1=Summary level given in groupbyvarsanaly is conflict with the summary given by TOTALFORVAR for group &&l_groupbyvarsanaly&l_i;
            %goto macerr;
         %end;
      %end; /* end of do-to loop on &l_j */
   %end; /* end of do-to loop on &l_i */
   
   /*
   /  Loop over &groupbyvarsanaly to call %tu_stats..
   /---------------------------------------------------------------------------*/
   %let l_grouppstypes=;
   %let l_totalpstypes=;
   %do l_i=0 %to &l_numof_byvars;
      %let l_k=0;
      %let l_statsout=;
      /*
      /  Keep only MAX or MIN &ANALYSISVAR in the data set if MIN or MAX is in
      /  &ANALYSISVAR
      /------------------------------------------------------------------------*/
      %if %nrbquote(&l_varstats) ne %then 
      %do;
         proc sort data=&dsetinanaly out=&l_prefix.minmaxorder&l_i;
            by &&l_groupbyvarsminmax&l_i &countdistinctwhatvar &groupminmaxvar ;
         run;
         data &l_prefix.minmax&l_i;
            set &l_prefix.minmaxorder&l_i;
            by &&l_groupbyvarsminmax&l_i &countdistinctwhatvar &groupminmaxvar ;
            %if &l_varstats eq MIN %then 
            %do;
               if first.%scan(&&l_groupbyvarsminmax&l_i &countdistinctwhatvar, -1 , %str( ));
            %end;
            %else %do;
               if last.%scan(&&l_groupbyvarsminmax&l_i &countdistinctwhatvar, -1 , %str( ));
            %end;
         run;
         %let l_dsetin=&l_prefix.minmax&l_i;
         %let l_classvars=&&l_groupbyvarsanaly&l_i ;
      %end;
      %else %do;
         %let l_dsetin=&dsetinanaly;
         %let l_classvars=&&l_groupbyvarsanaly&l_i ;
      %end; /* end-if on %nrbquote(&l_varstats) ne */
      %if &l_i eq 0 %then
         %let l_groupstypes=&pstypes &&l_groupsummarytype&l_i;
      %else
         %let l_groupstypes=&&l_groupsummarytype&l_i;
         
      /*
      /  Create data set which has required subtotals.
      /------------------------------------------------------------------------*/   
      %do l_j=0 %to &l_numof_totals;
         %let l_l=%eval(&l_numof_totals - &l_j);
         %let l_totaldsetin=&l_dsetin;     
         %let l_flag=0;    
         %if %nrbquote(&&l_ifstatements&l_l) ne %then 
         %do;
            data &l_prefix.subtotal&l_l;
               set &l_dsetin;
               if %unquote(&&l_ifstatements&l_l);
            run;
            %let l_flag=1;
            %let l_filltotal0yn=1;
            %let l_totaldsetin=&l_prefix.subtotal&l_l;            
         %end; /* %if %nrbquote(&&l_ifstatements&l_l) ne */
         %if &l_j lt %eval(&l_numof_totals -1) %then
         %do;
            %if %nrbquote(&&l_ifstatements%eval(&l_l - 1)) ne %then %let l_flag=1;
         %end;
         
         %let l_totalpstypes=&l_totalpstypes &&l_totalsummarytype&l_l._&l_i;
         
         %if ( &l_flag eq 1 ) or ( &l_j eq &l_numof_totals ) 
         %then %do;
         
            %if &l_j eq &l_numof_totals %then %let l_totalpstypes=&l_groupstypes &l_totalpstypes; 
            
            %do l_n=1 %to 2;
        
               %tu_stats(
                  analysisVar            =&analysisVar,
                  analysisVarFormatDName =&analysisVarFormatDName,
                  analysisVarName        =&l_analysisVarName,
                  classVars              =&l_classvars,
                  countDistinctWhatVar   =&l_countDistinctWhatVar,
                  countVarName           =&countvarname,
                  dsetIn                 =&l_totaldsetin,
                  dsetOut                =&l_prefix.statsout&l_i._&l_k._&l_n,
                  dsetOutCi              =&dsetoutci,
                  psByVars               =&psByVars,
                  psClass                =&psClass,
                  psClassOptions         =&psClassOptions,
                  psFormat               =&&l_psformat&l_i,
                  psFreq                 =&psFreq,
                  psid                   =&psid,
                  psOptions              =&psOptions,
                  psOutput               =&psOutput,
                  psOutputOptions        =&psOutputOptions,
                  psTypes                =&l_totalpstypes,
                  psWays                 =&psWays,
                  psWeight               =&psWeight,
                  statsList              =&statsList,
                  totalForVar            =,
                  totalid                =,
                  varlabelStyle          =&varlabelStyle
                  );
                                   
               %if g_abort eq 1 %then %goto macerr;  
               
               /* YW006: fill missing if no record for total calculation */
               %if %nrbquote(&&l_ifstatements&l_l) ne %then 
               %do;
                  %if &l_n eq 1 %then %let l_totaldsetin=&l_dsetin;
                  %else %do;
                      proc sort data=&l_prefix.statsout&l_i._&l_k._1;
                         by &psByVars &l_classvars _type_;
                      run;
                      
                      proc sort data=&l_prefix.statsout&l_i._&l_k._2(keep=_type_ &l_classvars);
                         by &psByVars &l_classvars _type_;
                      run;
                      
                      data &l_prefix.statsout&l_i._&l_k._1;
                         merge &l_prefix.statsout&l_i._&l_k._1
                               &l_prefix.statsout&l_i._&l_k._2;
                         by &psByVars &l_classvars _type_;
                      run;
                      
                  %end; /*  %if &l_n eq 1 %then */              
               %end; /* %if %nrbquote(&&l_ifstatements&l_l) ne */
               %else %let l_n=2; 
               
               %if %sysfunc(indexw(%qupcase(&psOptions), COMPLETETYPES)) eq 0 %then %let l_n=2;
            %end; /* %do l_n=1 %to 2 */     
                                    
            data &l_prefix.statsloopout&l_i._&l_k;
               set &l_statsout &l_prefix.statsout&l_i._&l_k._1 (in=__temp__total__in__);           
               if __temp__total__in__ then __temp__total__=&l_l;
            run;
           
            %let l_statsout=&l_prefix.statsloopout&l_i._&l_k;
            %let l_totalpstypes=;
            %let l_k=%eval(&l_k + 1);
         %end; /* end-if on ( %nrbquote(&&l_ifstatements&l_j) ne ) or ( &l_j eq &l_numof_totals ) */
      %end; /* end of do-loop on &l_j */    
            
      /*
      /  Add decode in;
      /------------------------------------------------------------------------*/
      %let l_thisdata=&l_statsout;
      %do l_j=1 %to &l_numof_codes;
         %if %scan(&&l_codelist&l_i, &l_j, %str( )) eq 1 %then 
         %do;
             proc sort data=&l_thisdata out=&l_prefix.sortout&l_j;
                by %scan(&l_codelist, &l_j, %str( ));
             run;
             data &l_prefix.dcd&l_j;
                merge &l_prefix.sortout&l_j(in=&l_varprefix.__IN1__)
                      &l_prefix.codedcdlist&l_j;
                by %scan(&l_codelist, &l_j, %str( ));
                if &l_varprefix.__IN1__;
             run;
             %let l_thisdata=&l_prefix.dcd&l_j;
         %end; /* end-if on %scan(&&l_codelist&l_i, &l_j, %str( )) eq 1 */
      %end; /* end of do-to loop */
      
      /*
      / YW006: Build length statement for decode variable to the longer one of 
      / length of the variable and format length of code variable.      
      /---------------------------------------------------------------------------*/     
      %let l_length=;
      data _null_;
         length __decode_length_statement $32761;
         if 0 then set &l_thisdata;
         __max_decode_len=0;
         __decode_length_statement='';
         %do l_l=1 %to &l_numof_codes;
            %if %scan(&&l_codelist&l_i, &l_l, %str( )) eq 1 %then 
            %do;
               if vtype(%scan(&l_decodelist, &l_l, %str( ))) eq "C" then 
               do;
                  __max_decode_len=max(vlength(%scan(&l_decodelist, &l_l, %str( ))),
                                       vformatw(%scan(&l_codelist, &l_l, %str( ))), 1);
                  __decode_length_statement=trim(left( __decode_length_statement))||' '||
                                            trim(left("%scan(&l_decodelist, &l_l, %str( ))"))||' $'||
                                            left(put(__max_decode_len, best12.));
               end; /* vtype(%scan(&l_decodelist, &l_l, %str( ))) eq "C" */           
               __max_decode_len=0;
            %end; /* if %scan(&&l_codelist&l_i, &l_l, %str( )) eq 1 */
         %end; /* %do l_l=1 %to &l_numof_codes; */
         if length(__decode_length_statement) gt 0 then
            __decode_length_statement="length "||trim(left( __decode_length_statement))||';';
         call symput('l_length', trim(left( __decode_length_statement)));
      run;
       
      /*
      / Add total statement and group statement in.
      / Overwrite DECODE with the formatted value if the CODE is in PSFORMAT.
      /---------------------------------------------------------------------------*/     
      data &l_prefix.statsoutcd&l_i;
         &l_length
         set &l_thisdata;
         label &summaryLevelVarName="Summary Level Variable Added by &sysmacroname";
         if &l_i eq 0 then &summaryLevelVarName=&l_numof_byvars + 1;
         else &summaryLevelVarName=&l_i;
         %if &l_codeinpsformat eq 1 %then 
         %do;
            %do l_l=1 %to &l_numof_codes;
               %if %scan(&&l_codelist&l_i, &l_l, %str( )) eq 1 %then 
               %do;
                  if indexw(upcase("&psformat"), compress("%scan(&l_codelist, &l_l, %str( ))")) gt 0 then 
                  do;
                     if vtype(%scan(&l_codelist, &l_l, %str( ))) eq "N" then 
                     do;
                        %scan(&l_decodelist, &l_l, %str( ))=putn(%scan(&l_codelist, &l_l, %str( )), vformat(%scan(&l_codelist, &l_l, %str( ))));
                     end;
                     else do;
                        %scan(&l_decodelist, &l_l, %str( ))=putc(%scan(&l_codelist, &l_l, %str( )), vformat(%scan(&l_codelist, &l_l, %str( ))));
                     end;
                  end; /* end-if on indexw(upcase("&psformat"), compress("%scan(&l_codelist, &l_l, %str( ))")) gt 0 */
               %end; /* end-if on %scan(&&l_codelist&l_i, &l_l, %str( )) eq 1 */
            %end; /* end of do-to loop */
         %end; /* end-if on &l_codeinpsformat eq 1 */
         %if %nrbquote(&&l_groupsummarytypecode&l_i) ne %then 
         %do;
            if ( _TYPE_ eq &&l_groupsummarytypecode&l_i ) then 
            do;
               %if %nrbquote(&&l_groupstatements&l_i) ne %then 
               %do;
                  %unquote(&&l_groupstatements&l_i);
               %end;
            end; /* end-if on ( _TYPE_ eq &&l_groupsummarytypecode&l_i ) */
         %end; /* end-if on %nrbquote(&&l_groupsummarytypecode&l_i) ne */
         %let l_l=0;
         %do l_j=1 %to &l_numof_totals;
            %if %nrbquote(&&l_totalstatements&l_j) ne %then 
            %do;
               %if &l_l gt 0 %then else;
               if (_TYPE_ eq &&l_totalsummarytypecode&l_j._&l_i) and
                  (__temp__total__ le &l_j) then do;
                  %unquote(&&l_totalstatements&l_j);
                  %if %nrbquote(&&l_groupstatements&l_i) ne %then 
                  %do;
                     %unquote(&&l_groupstatements&l_i);
                  %end;
               end; /* end-if on %if %nrbquote(&&l_totalstatements&l_j) ne */
               %let l_l=1;
            %end; /* end-if on %nrbquote(&&l_totalstatements&l_j) ne */
         %end; /* end of do-to loop */
         drop __temp__total__;
      run;
   
      %if (&l_i eq 0) %then %let l_statsouttype=&l_prefix.statsoutcd&l_i;
      %else %do;
         data &l_prefix.statsouttype&l_i;
            set &l_statsouttype &l_prefix.statsoutcd&l_i;
         run;
         %let l_statsouttype=&l_prefix.statsouttype&l_i;
      %end; /* end-if on (&l_i eq 0) */      
   %end; /* end of do-loop on &l_i */
   %let l_lastdset=&l_statsouttype;
      
   /*
   / Remove records created because of COMPLETETYPES.
   /---------------------------------------------------------------------------*/
   %if &l_numof_noncmpvars gt 1 %then 
   %do;
      proc sort data=&l_lastdset out=&l_prefix.componly1;
         by &l_noncompletetypesvars;
      run;
      data &l_prefix.componly2;
         merge &l_prefix.componly1
               &l_prefix.noncomp(in=&l_varprefix.__IN1__);
         by &l_noncompletetypesvars;
         if &l_varprefix.__IN1__ then delete;
      run;
      %let l_lastdset=&l_prefix.componly2;
      
      %if &l_numof_byvars gt 0 %then  
      %do;
         proc sort data=&l_prefix.componly2 out=&l_prefix.componly3;
            by &l_groupbyvarsanaly0 &summaryLevelVarName;
         run;
         
         data &l_prefix.componly4;
            set &l_prefix.componly3;
            by &l_groupbyvarsanaly0 &summaryLevelVarName;
            
            %do l_i=1 %to &l_numof_byvars;
               %if (%nrbquote(&&l_groupbyvarsanaly&l_i) ne ) %then 
               %do;
                  if ( &summaryLevelVarName eq &l_i ) and 
                     ( first.%scan(&&l_groupbyvarsanaly&l_i, -1, %str( )) ) and
                     ( last.%scan(&&l_groupbyvarsanaly&l_i, -1, %str( )) )                      
                  then delete;
               %end; /* end-if on &&l_groupbyvarsanaly&l_i is not blank */
            %end; /* end of do-to loop */
         run;
         
         %let l_lastdset=&l_prefix.componly4;
      %end;
         
   %end; /* end-if on &l_numof_noncmpvars gt 1 */
     
   /*
   /  Fill zero for the total sub groups.
   /------------------------------------------------------------------------*/              
   %if ( &l_filltotal0yn eq 1 ) %then 
   %do; 
      %if %nrbquote(&countvarname) eq %then %let countvarname=_freq_;
      
      /*
      / YW006:
      / Get a list of vairables which are not summaries created by %tu_stats.
      /------------------------------------------------------------------------*/                  
            
      data _null_;  
         length groupbyvars $5000; 
         %do l_i=1 %to &l_numof_codes;
            %if %scan(&l_codelist0, &l_i, %str( )) eq 1 %then 
            %do;
               groupbyvars=trim(left(groupbyvars))||' '||"%scan(&l_decodelist, &l_i, %str( ))";
            %end;
         %end;
         groupbyvars="&psbyvars &l_groupbyvarsanaly0 _type_ &summarylevelvarname "||left(groupbyvars);
         groupbyvars=upcase(compbl(groupbyvars));
         
         /* YW003: Added variable of &ANALYSISVARNAME in */                                                       
         %if (%nrbquote(&l_analysisvarnamevar) ne ) %then
         %do;
            groupbyvars=trim(left(groupbyvars))||" &l_analysisvarnamevar";
         %end;
     
         call symput('l_groupbyvarsnototal', trim(left(groupbyvars)));
      run;
      
      /* 
      / YW006: Split data set by if &countvarname is missing      
      /------------------------------------------------------------------------*/      
      data &l_prefix.forvars1;
         set &l_lastdset;
         keep &l_groupbyvarsnototal &countvarname;
         if missing(&countvarname);
         &countvarname=0;
      run;
      
      data &l_prefix.forvars2;
         set &l_lastdset;
         drop &l_groupbyvarsnototal;
         if not missing(&countvarname) and (&countvarname eq 0) then
         do;
            output;
            stop;
         end;
      run;
      
      /* 
      / YW006: Merge the summary statistics which has 0 count to data set with
      / missing &countvarname      
      /------------------------------------------------------------------------*/            
      proc sort data=&l_prefix.forvars1;
         by &countvarname;
      run;
      
      proc sort data=&l_prefix.forvars2;
         by &countvarname;
      run;
      
      data &l_prefix.filltotal1;
         merge &l_prefix.forvars1 (in=__temp__total__in__)
               &l_prefix.forvars2;
         by &countvarname;
         if __temp__total__in__;
      run;
      
      data &l_prefix.filltotal;
         set &l_lastdset (where=(not missing(&countvarname)))
             &l_prefix.filltotal1;
      run;
     
      %let l_lastdset=&l_prefix.filltotal;
   %end;
     
   /*
   / Call %tu_stats to get DENOM data set.
   /---------------------------------------------------------------------------*/  
   %if ( %nrbquote(&dsetindenom) ne ) and ( %nrbquote(&resultstyle) ne ) %then 
   %do;
      %let l_totalpstypes=;
      %let l_dsetin=&dsetindenom;
      %let l_denomout=;
      %let l_k=0;
      %do l_j=0 %to &l_numof_totals;
         %let l_flag=0;
         %let l_l=%eval(&l_numof_totals - &l_j);
         %if %nrbquote(&&l_totaldenomyn&l_l) ne 0 %then 
         %do;
            %let l_totaldsetin=&l_dsetin;          
            %if %nrbquote(&&l_totaldenomyn&l_l) ne 1 %then 
            %do;
               data &l_prefix.subtotal&l_j;
                  set &l_dsetin;
                  if %unquote(&&l_totaldenomyn&l_l);
               run;
               %let l_totaldsetin=&l_prefix.subtotal&l_j;
               %let l_flag=1;
            %end;  /* end-if on &&l_ifstatements&l_j is not blank */
            %else %if &l_j lt %eval(&l_numof_totals -1) %then
            %do;
               %let l_length=%eval(&l_l - 1);
               %if (%nrbquote(&&l_totaldenomyn&l_length) ne 0) and 
                   (%nrbquote(&&l_totaldenomyn&l_length) ne 1) %then %let l_flag=1;
            %end; /*  %if &l_j lt %eval(&l_numof_totals -1) */
            
            %let l_totalpstypes=&l_totalpstypes &&l_denomsummarytype&l_l;            
         %end; /* end-if on &&l_totaldenomyn&l_j ne 0 */
         %if ( &l_flag gt 0 ) or ( &l_j eq &l_numof_totals ) %then 
         %do;
            %tu_stats(
               analysisVar            =,
               analysisVarFormatDName =,
               analysisVarName        =,
               classVars              =&l_groupbyvarsdenom,
               countDistinctWhatVar   =&countDistinctWhatVar,
               countVarName           =&l_denomvarname,
               dsetIn                 =&l_totaldsetin,
               dsetOut                =&l_prefix.denom&l_k,
               dsetOutCi              =,
               psByVars               =,
               psClass                =,
               psClassOptions         =&psClassOptions,
               psFormat               =&l_psformatdenom,
               psFreq                 =,
               psid                   =,
               psOptions              =&psOptions,
               psOutput               =,
               psOutputOptions        =,
               psTypes                =&l_totalpstypes,
               psWays                 =,
               psWeight               =,
               statsList              =,
               totalForVar            =,
               totalid                =,
               varlabelStyle          =&varlabelStyle
               );
            %if g_abort eq 1 %then %goto macerr;
            data &l_prefix.denomloopout&l_k;
               set &l_denomout &l_prefix.denom&l_k(in=__temp__total__in__);
               if __temp__total__in__ then __temp__total__=&l_l;              
            run;               
            %let l_denomout=&l_prefix.denomloopout&l_k;            
            %let l_k=%eval(&l_k + 1);
            %let l_totalpstypes=;
         %end; /* end-if on ( &l_flag gt 0 ) or ( &l_j eq &l_numof_totals ) */
      %end; /* end of do-loop on &l_j */      

      data &l_prefix.denomtype;
         set &l_denomout;
         keep &l_groupbyvarsdenom &l_denomvarname;
         %let l_l=0;
         %do l_i=1 %to &l_numof_totals;
            %if ( %nrbquote(&&l_totalstatements&l_i) ne ) and
                ( %nrbquote(&&l_totaldenomyn&l_i)    ne 0 ) %then 
            %do;
               %if &l_l gt 0 %then else;
               if (_TYPE_=&&l_denomsummarytypecode&l_i) and 
                  (__temp__total__ le &l_i) then do;
                  %unquote(&&l_totalstatements&l_i);
               end;
               %let l_l=1;
            %end; /* end if on ( %nrbquote(&&l_totalstatements&l_i) ne ) */
         %end; /* end of do-to loop */
         drop __temp__total__;
      run;
      
      %let l_denomout=&l_prefix.denomtype;
      
      /*
      / Call %tu_percent to combine norminator and denorminator
      /------------------------------------------------------------------------*/
      %tu_percent(
         dsetinNumer   =&l_lastdset,
         numerCntVar   =&l_numervarname,
         dsetinDenom   =&l_denomout,
         denomCntVar   =&l_denomvarname,
         mergeVars     =&l_groupbyvarsdenom,
         pctDps        =&resultpctdps,
         resultStyle   =&resultstyle,
         dsetout       =&l_prefix.pct(rename=(tt_result=&resultVarName))
         );
      %if g_abort eq 1 %then %goto macerr;
      %let l_lastdset=&l_prefix.pct;
      %if %qupcase(&remSummaryPctYN) eq Y %then 
      %do;
         %if &l_numof_byvars eq 0 %then 
         %do;
             %let l_message1=Requested removal of percentage from summary records (REMSUMMARYPCTYN=&remSummaryPctYN) however no summary records were created (groupbyvarsanaly=&groupbyvarsanaly);
             %let l_message2=Summary level records are generated by including brackets sections in parameter groupbyvarsanaly eg groupbyvarsanaly=(sex="n") sex;
             %goto macerr;
         %end;
         /* keep the first part only of the result variable if not the last summary */
         data &l_prefix._littlen;
             set &l_lastDset;
             if &summaryLevelVarName ne &l_numof_byvars + 1 then 
             do;
                 if scan(&resultVarName, 1, ' ') eq '' then &resultVarName='';
                 else substr(&resultVarName, indexw(&resultVarName, scan(&resultVarName, 1, ' ')) + length(scan(&resultVarName, 1, ' ')))="";
             end;
         run;
         
         %let l_lastdset=&l_prefix._littlen;        
      %end; /* end-if on &remSummaryPctYN equals Y */
   %end;  /* end-if on &dsetindenom is not blank */   
   
   %let l_rc=%tu_nobs(&l_lastdset);
   %if &g_abort ne 0 %then %goto macerr;
   %if &l_rc lt 0 %then %goto macerr;
   %if &l_rc eq 0 %then %goto outputit;
   
   /*
   /  Call %tu_Addbignvar to add bigN.
   /---------------------------------------------------------------------------*/
   %if (%nrbquote(&bignvarname) ne ) and (%nrbquote(&l_bigntovar) ne) %then 
   %do;            
      /* Add bigN if no subset in totalid */
      %if ( &l_numof_totals le 1 ) and (%nrbquote(&&l_ifstatements&l_numof_totals) eq ) and
          ( ( &l_numof_totals lt 1) or ( %nrbquote(&l_bigntotalid) ne ) ) %then 
      %do;           
         %tu_addBigNVar(
            dsetinToAddBigN      =&l_lastdset,
            dsetinToCount        =&l_dsetinpop,
            countDistinctWhatVar =&countDistinctWhatVar,
            groupByVars          =&l_groupbyvarpop,
            totalID              =&l_bigntotalid,
            bigNVarName          =&bigNVarName,
            dsetOut              =&l_prefix.bignout
            )
      %end;
   /*
   / YW006: Calculate bigN the same as calculating STATS and DENORM. The step    
   / which calls %tu_addbignvar can be deleted. To keep backward compatible, it 
   / is kept.
   /---------------------------------------------------------------------------*/      
      %else %do;            
         %let l_totalpstypes=;
         %let l_dsetin=&l_dsetinpop;
         %let l_denomout=;
         %let l_k=0;
         %do l_j=0 %to &l_numof_totals;
            %let l_flag=0;
            %let l_l=%eval(&l_numof_totals - &l_j);
            %if %nrbquote(&&l_totalbignyn&l_l) ne '0' %then 
            %do;
               %let l_totaldsetin=&l_dsetin;
               %if %nrbquote(&&l_totalbignyn&l_l) ne '1' %then 
               %do;
                  data &l_prefix.subtotal&l_j;
                     set &l_dsetin;
                     if %unquote(&&l_totalbignyn&l_l);
                  run;
                  %let l_totaldsetin=&l_prefix.subtotal&l_j;
                  %let l_flag=1;
               %end;  /* end-if on &&l_ifstatements&l_j is not blank */
               %else %if &l_j lt %eval(&l_numof_totals -1) %then
               %do;
                  %if (%nrbquote(&&l_totalbignyn%eval(&l_l - 1)) ne 0) and 
                      (%nrbquote(&&l_totalbignyn%eval(&l_l - 1)) ne 1) %then %let l_flag=1;
               %end;
              
               %let l_totalpstypes=&l_totalpstypes &&l_bignsummarytype&l_l;
            %end; /* end-if on &&l_totalbignyn&l_j gt 0 */
            %if ( &l_flag gt 0 ) or ( &l_j eq &l_numof_totals ) %then 
            %do;
               %tu_stats(
                  analysisVar            =,
                  analysisVarFormatDName =,
                  analysisVarName        =,
                  classVars              =&l_groupbyvarpop,
                  countDistinctWhatVar   =&countDistinctWhatVar,
                  countVarName           =&bignvarname,
                  dsetIn                 =&l_totaldsetin,
                  dsetOut                =&l_prefix.bignloop&l_k,
                  dsetOutCi              =,
                  psByVars               =,
                  psClass                =,
                  psClassOptions         =&psClassOptions,
                  psFormat               =&l_psformatbign,
                  psFreq                 =,
                  psid                   =,
                  psOptions              =&psOptions,
                  psOutput               =,
                  psOutputOptions        =,
                  psTypes                =&l_totalpstypes,
                  psWays                 =,
                  psWeight               =,
                  statsList              =,
                  totalForVar            =,
                  totalid                =,
                  varlabelStyle          =&varlabelStyle
                  );
               %if g_abort eq 1 %then %goto macerr;
               data &l_prefix.bignloopout&l_k;
                  set &l_denomout &l_prefix.bignloop&l_k(in=__temp__total__in__);
                  if __temp__total__in__ then __temp__total__=&l_l;              
               run;               
               %let l_denomout=&l_prefix.bignloopout&l_k;            
               %let l_k=%eval(&l_k + 1);
               %let l_totalpstypes=;
            %end; /* end-if on ( &l_flag gt 0 ) or ( &l_j eq &l_numof_totals ) */
         %end; /* end of do-loop on &l_j */       
         data &l_prefix.bignloopout;
            set &l_denomout;
            keep &l_groupbyvarpop &bignvarname;
            label &bignvarname="Population Big N";
            %let l_l=0;
            %do l_i=1 %to &l_numof_totals;
               %if ( %nrbquote(&&l_totalstatements&l_i) ne ) and
                   ( %nrbquote(&&l_totalbignyn&l_i)     ne 0 ) %then 
               %do;
                  %if &l_l gt 0 %then else;
                  if (_TYPE_=&&l_bignsummarytypecode&l_i) and 
                     (__temp__total__ le &l_i) then do;
                     %unquote(&&l_totalstatements&l_i);
                  end;
                  %let l_l=1;
               %end; /* end if on ( %nrbquote(&&l_totalstatements&l_i) ne ) */
            %end; /* end of do-to loop */
            drop __temp__total__;
         run;         
         proc sort data=&l_prefix.bignloopout out=&l_prefix.bignsort nodupkey;
            by &l_groupbyvarpop &bignvarname;
         run;         
         proc sort data=&l_lastdset out=&l_prefix.beforebign;
            by &l_groupbyvarpop;
         run;         
         data &l_prefix.bignout;
            merge &l_prefix.beforebign(in=__temp_add_bign_in1__)
                  &l_prefix.bignsort(in=__temp_add_bign_in2__) ;
            by &l_groupbyvarpop;
            if __temp_add_bign_in1__;
            if not __temp_add_bign_in2__ then &bignvarname=0;
         run;                               
      %end; /* end-if on ( &l_numof_totals le 1 ) and (%nrbquote(&&ifstatements&l_numof_totals) ne ) */
      %let l_lastdset=&l_prefix.bignout;            
      %if (%upcase(&addbignyn) eq Y) and (( &l_numof_fmtvars eq 0 ) or ( %nrbquote(&l_bigntovardecodevar) ne ) 
          or ( &l_totalbignyn eq 0 ))
      %then %do;          
          %if (%nrbquote(&l_bigntovardecodevar) eq ) %then %let l_bigntovardecodevar=&l_bigntovar;
          
          data _null_;
             if 0 then set &l_lastdset(keep=&l_bigntovardecodevar);
             call symput('l_ndcdlen', left(put(max(vlength(&l_bigntovardecodevar) + 20, vformatw(&l_bigntovardecodevar) + 20 ), best12.0)));
          run;
          data &l_prefix.withbign (rename=(&l_varprefix.__IN1__=&l_bigntovardecodevar));
             length &l_varprefix.__IN1__ $&l_ndcdlen.;
             set &l_lastdset  ;
             drop &l_bigntovardecodevar;
             if vtype(&l_bigntovardecodevar) eq 'C' then
                &l_varprefix.__IN1__=putc(&l_bigntovardecodevar, vformat(&l_bigntovardecodevar));
             else
                &l_varprefix.__IN1__=putn(&l_bigntovardecodevar, vformat(&l_bigntovardecodevar));
             &l_varprefix.__IN1__=trim(left(&l_varprefix.__IN1__))||"&bignlabelsplitchar.(N="||trim(left(put(&bignvarname, best12.0)))||")";
          run;
          %let l_lastdset=&l_prefix.withbign ;
      %end; /* end-if on %nrbquote(&l_bigntovardecodevar) ne */            
   %end; /* end-if on  %nrbquote(&l_bigntovar) ne */    
   
   /*
   / Create formats for the &TOTALFORVAR which have no DECODE and add decode of
   / the &TOTALFORVAR to the format
   /---------------------------------------------------------------------------*/
   %if ( &l_numof_fmtvars gt 0 ) %then 
   %do;
      data &l_prefix.fmtdcd(rename=(&l_varprefix.start_var_name=start &l_varprefix.label_var_name=label
                                    &l_varprefix.fmtname_var_name=fmtname &l_varprefix.type_var_name=type)
                            keep=&l_varprefix.start_var_name &l_varprefix.label_var_name &l_varprefix.fmtname_var_name &l_varprefix.type_var_name);
         length &l_varprefix.start_var_name &l_varprefix.label_var_name &l_varprefix.fmtname_var_name  $20
                &l_varprefix.type_var_name $10 &l_varprefix.format_statements $1000;
         set &l_lastdset(keep=&bignvarname &l_bigntovar
            %do l_i=1 %to &l_numof_fmtvars;
                &&l_totalfmtvar&l_i
            %end;
            );
         %do l_i=1 %to &l_numof_fmtvars;
            &l_varprefix.start_var_name=&&l_totalfmtvar&l_i;
            if vtype(&&l_totalfmtvar&l_i) eq "N" then 
            do;
               &l_varprefix.label_var_name=putn(&&l_totalfmtvar&l_i, vformat(&&l_totalfmtvar&l_i));
               &l_varprefix.fmtname_var_name="&l_fmtprefix.&l_i._";
               &l_varprefix.type_var_name='N';
            end;
            else do;
               &l_varprefix.label_var_name=putc(&&l_totalfmtvar&l_i, vformat(&&l_totalfmtvar&l_i));
               &l_varprefix.fmtname_var_name="$&l_fmtprefix.&l_i._";
               &l_varprefix.type_var_name='C';
            end;
            
            %if %nrbquote(&&l_totaldecode&l_i) ne %then 
            %do;
               if (&&l_totalfmtvar&l_i eq &&l_totalid&l_i) then
                  &l_varprefix.label_var_name=&&l_totaldecode&l_i;
            %end;
            %if (&&l_totalfmtvar&l_i eq %nrbquote(&l_bigntovar)) and (%upcase(&addbignyn) eq Y) %then %do;
               &l_varprefix.label_var_name=trim(left(&l_varprefix.label_var_name))||"&bignlabelsplitchar.(N="||trim(left(put(&bignvarname, best12.0)))||")";
               %let l_bigntovardecodevar=&l_bigntovar;
            %end;
            
            &l_varprefix.format_statements=trim(left(&l_varprefix.format_statements))||' '||compress("&&l_totalfmtvar&l_i")||' '||
                                 compress(&l_varprefix.fmtname_var_name)||'.';
            output;
         %end; /* end of do-to loop on &l_i */
         
         %if ( %nrbquote(&l_bigntovardecodevar) eq  ) and (%nrbquote(&l_bigntovar) ne ) and (%upcase(&addbignyn) eq Y) 
             and ( &l_totalbignyn eq 1 ) %then 
         %do;
            &l_varprefix.start_var_name=&&l_bigntovar;
            if vtype(&l_bigntovar) eq "N" then 
            do;
               &l_varprefix.label_var_name=putn(&l_bigntovar, vformat(&l_bigntovar));
               &l_varprefix.fmtname_var_name="&l_fmtprefix.bn";
               &l_varprefix.type_var_name='N';
            end;
            else do;
               &l_varprefix.label_var_name=putc(&l_bigntovar, vformat(&l_bigntovar));
               &l_varprefix.fmtname_var_name="$&l_fmtprefix.bn";
               &l_varprefix.type_var_name='C';
            end;
       
            &l_varprefix.label_var_name=trim(left(&l_varprefix.label_var_name))||"&bignlabelsplitchar.(N="||trim(left(put(&bignvarname, best12.0)))||")";
            &l_varprefix.format_statements=trim(left(&l_varprefix.format_statements))||' '||compress("&&l_bigntovar")||' '||
                                 compress(&l_varprefix.fmtname_var_name)||'.';                
            output;                                   
         %end; /* end-if on ( %nrbquote(&l_bigntovardecodevar) ne  ) and (%nrbquote(&l_bigntovar) ne ) */
         call symput('l_format_statements', trim(left(&l_varprefix.format_statements)));
      run;
      
      proc sort data=&l_prefix.fmtdcd out=&l_prefix.fmtdcd2 nodupkey;
         by fmtname start;
      run;
      proc format cntlin=&l_prefix.fmtdcd2 lib=work;
      run;
   %end; /* end-if on &l_numof_fmtvars gt 0 */
   
   /*
   / Add format in and create output data set
   /---------------------------------------------------------------------------*/
   
%OUTPUTIT:
   
   data &dsetout;
      set &l_lastdset(label="output data set created by macro &sysmacroname");
      %if %nrbquote(&l_format_statements) ne %then 
      %do;
         format &l_format_statements;
      %end;
   run;
   
   %if &l_debug eq 1 %then 
   %do;
      proc contents;
         title "output data set";
      run;
   %end;
   %goto endmac;
%MACERR:
   %put %str(RTE)RROR: &sysmacroname: &l_message1;
   %if %nrbquote(&l_message2) ne %then 
   %do;
      %put %str(RTE)RROR: &sysmacroname: &l_message2;
   %end;
   %let g_abort=1;
   %tu_abort()
%ENDMAC:
   /*
   / Call tu_tideup to clear temporary data set and fiels.
   /--------------------------------------------------------------------------*/
   %tu_tidyup(
      RMDSET =&L_PREFIX:,
      GLBMAC =NONE
      )
%mend tu_statswithtotal;
