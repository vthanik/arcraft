/*
|
| Macro Name:     td_ae4.sas
|
| Macro Version:  1
|
| SAS Version:    8
|
| Created By:     Yongwei Wang (YW62951)
|
| Date:           21Jan2004
|
| Macro Purpose:  A macro to create Adverse Events Display AE4.
|
| Macro Design:   Procedure style.
|
| Input Parameters:     
| Name                Description                                       Default           
| ----------------------------------------------------------------------------------------
| ACROSSVAR           Specifies a variable that has multiple levels     &g_trtcd          
|                     and will be transposed by %tu_denorm to multiple                    
|                     columns.                                                            
|                     Valid values: blank, or a SAS variable that                         
|                     exists in each of the segments' output datasets.                    
|                     Required only if DENORMYN=Y. This parameter must                    
|                     have the same value as ACROSSVAR in each of the                     
|                     segment macro calls.                                                
|                                                                                         
| ACROSSVARDECODE     Specifies the name of a variable that contains    &g_trtgrp         
|                     decoded values of ACROSSVAR                                         
|                     Valid values: Blank, or a SAS variable that                         
|                     exists in each of the segments' output datasets.                    
|                     Required only if DENORMYN=Y and ADDBIGNYN=Y.                        
|                                                                                         
| BREAK1 BREAK2       5 parameters for input of user specified break    (Blank)           
| BREAK3 BREAK4       statements.                                                         
| BREAK5              Valid values: valid PROC REPORT BREAK statements                    
|                     (without "break")                                                   
|                     The value of these parameters are passed                            
|                     directly to PROC REPORT as:                                         
|                     BREAK &break1;                                                      
|                                                                                         
| BYVARS              By variables. The variables listed here are       (Blank)           
|                     processed as standard SAS BY variables.                             
|                     Valid values: one or more variable names from                       
|                     DSETIN                                                              
|                     It is the caller's responsibility to provide a                      
|                     sorted dataset as DSETIN; TU_DISPLAY will not                       
|                     sort the dataset.                                                   
|                     No formatting of the display for these variables                    
|                     is performed by %tu_DISPLAY.  The user has the                      
|                     option of the standard SAS BY line, or using                        
|                     OPTIONS NOBYLINE and #BYVAL #BYVAR directives in                    
|                     title statements.                                                   
|                                                                                         
| CENTREVARS          Variables to be displayed as centre justified.    (Blank)           
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with COLUMNS                           
|                     Variables not appearing in any of the parameters                    
|                     CENTREVARS, LEFTVARS, or RIGHTVARS will be                          
|                     displayed using the PROC REPORT default.                            
|                     Character variables are left justified while                        
|                     numeric variables are right justified.                              
|                                                                                         
| COLSPACING          The value of the between-column spacing.          2                 
|                     Valid values: positive integer                                      
|                                                                                         
| COLUMNS             A PROC REPORT column statement specification.     tt_segorder       
|                     Including spanning titles and variable names      tt_grplabel       
|                     Valid values: one or more variable names from     tt_code1          
|                     DSETIN plus other elements of valid PROC REPORT   tt_decode1        
|                     COLUMN statement syntax, but not including        tt_result:        
|                     report_item=alias syntax                                            
|                                                                                         
| COMPUTEBEFOREPAGEL  Specifies the labels that shall precede the       (Blank)           
| INES                ComputeBeforePageVar value. For each variable                       
|                     specified for COMPUTEBEFOREPAGEVARS, four values                    
|                     shall be specified for COMPUTEBEFOREPAGELINES.                      
|                     The four values shall be:                                           
|                     * A localisation key for the fixed labelling                        
|                     text                                                                
|                     * The name of the localisation format ($local.)                     
|                     * The character(s) to be used between the                           
|                     labelling text and the values of the fourth                         
|                     parameter                                                           
|                     * Name of a variable whose values are to be used                    
|                     in the Computer Before Page line                                    
|                     Valid values: A multiple of four words separated                    
|                     by blanks. The multiple shall be equal to the                       
|                     number of variables specified for                                   
|                     COMPUTEBEFOREPAGEVARS                                               
|                     For example:                                                        
|                     GRP $local. : xValue TRTMNT $local. : trtgrp                        
|                     US/RT/TU_LIST-014                                                   
|                                                                                         
| COMPUTEBEFOREPAGEV  Variables listed in this parameter are printed    (Blank)           
| ARS                 between the SAS title lines and the column                          
|                     headers for the report.                                             
|                     Valid values: one or more variable names from                       
|                     DSETIN                                                              
|                     PROC REPORT code resulting from this parameter:                     
|                                                                                         
|                     define VAR1   / order noprint;                                      
|                     define VAR2   / order noprint;                                      
|                        ...                                                              
|                     define VARn   / order noprint;                                      
|                     break before VARn / page;                                           
|                     compute before _page_ / left;                                       
|                     line VAR1 $char&g_ls..;                                             
|                     line VAR2 $char&g_ls..;                                             
|                           ...                                                           
|                     line VARn $char&g_ls..;                                             
|                           endcomp;                                                      
|                     The value of each ComputeBeforePageVar is                           
|                     printed as is with no additional formatting.  Do                    
|                     NOT include these variables in the COLUMNS                          
|                     parameter they will be added by the macro.  It                      
|                     is not necessary to list these variables in the                     
|                     ORDERVARS or NOPRINTVARS parameters.  The ORDER=                    
|                     option for these variables is control using                         
|                     ORDERVARSFORMATTED,                                                 
|                     ORDERVARSFREQ, or                                                   
|                     ORDERVARSDATA parameters.                                           
|                                                                                         
| DDDATASETLABEL      Specifies the label to be applied to the DD       DD dataset for    
|                     dataset                                           AE4 table         
|                     Valid values: a non-blank text string                               
|                                                                                         
| DEFAULTWIDTHS       This is a list of default widths for ALL columns  tt_grplabel 20    
|                     and will usually be defined by the DD macro.      tt_decode1 20     
|                     This parameter specifies column widths for all                      
|                     variables not listed in the WIDTHS parameter.                       
|                     Valid values: values of column names and numeric                    
|                     widths, a list of variables followed by a                           
|                     positive integer, e.g.                                              
|                                                                                         
|                     defaultwidths = a b 10 c 12 d1-d4 6                                 
|                     Numbered range lists are supported in this                          
|                     parameter however name range lists, name prefix                     
|                     lists, and special SAS name lists are not.                          
|                     Variables that are not given widths through                         
|                     either the WIDTHS or DEFAULTWIDTHS parameter                        
|                     will be width optimised using:                                      
|                     MAX (variable's format width,                                       
|                     width of column header) for variables that are                      
|                     NOT flowed or                                                       
|                     MIN(variable's format width,                                        
|                     width of column header) for variable that ARE                       
|                     flowed.                                                             
|                                                                                         
| DESCENDING          List of ORDERVARS that are given the PROC REPORT  (Blank)           
|                     define statement attribute DESCENDING                               
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with ORDERVARS                         
|                                                                                         
| DSETIN              Specifies the name of the input dataset           ardata.ae         
|                     Valid values: name of an existing dataset,                          
|                     pre-sorted by BYVARS                                                
|                                                                                         
| DSETINDENOM         Input dataset containing data to be counted to    ardata.demo       
|                     obtain the denominator. This may or may not be                      
|                     the same as the dataset specified to                                
|                     DSETINNUMER.                                                        
|                     Valid values: &g_popdata or any other valid SAS                     
|                     dataset reference                                                   
|                                                                                         
| DSETOUT             Specifies the name of the output summary          (Blank)           
|                     dataset.                                                            
|                     Valid values: Blank, or a valid SAS dataset name                    
|                                                                                         
| FLOWVARS            Variables to be defined with the flow option.     _ALL_             
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with COLUMNS                           
|                     Flow variables should be given a width through                      
|                     the WIDTHS.  If a flow variable does not have a                     
|                     width specified the column width will be                            
|                     determined by                                                       
|                     MIN(variable's format width,                                        
|                     width of  column header)                                            
|                                                                                         
| FORMATS             Variables and their format for display. For use   (Blank)           
|                     where format for display differs to the format                      
|                     on the DSETIN.                                                      
|                     Valid values: values of column names and formats                    
|                     such as form valid syntax for a SAS FORMAT                          
|                     statement                                                           
|                                                                                         
| IDVARS              Variables to appear on each page should the       (Blank)           
|                     report be wider than 1 page. If no value is                         
|                     supplied to this parameter then all displayable                     
|                     order variables will be defined as idvars                           
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with COLUMNS                           
|                                                                                         
| LABELS              Variables and their label for display. For use    (Blank)           
|                     where label for display differs to the label on                     
|                     the DSETIN                                                          
|                     Valid values: pairs of variable names and labels                    
|                     with equals signs between them                                      
|                                                                                         
| LEFTVARS            Variables to be displayed as left justified       (Blank)           
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with COLUMNS                           
|                                                                                         
| LINEVARS            List of order variables that are printed with     (Blank)           
|                     LINE statements in PROC REPORT                                      
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with ORDERVARS                         
|                     These values shall be written with a BREAK                          
|                     BEFORE when the value of one of the variables                       
|                     change. The variables will automatically be                         
|                     defined as NOPRINT                                                  
|                                                                                         
| NOPRINTVARS         Variables listed in the COLUMN parameter that     (Blank)           
|                     are given the PROC REPORT define statement                          
|                     attribute noprint.                                                  
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with COLUMNS                           
|                     These variables are usually ORDERVARS used to                       
|                     control the order of the rows in the display.                       
|                                                                                         
| NOWIDOWVAR          Variable whose values must be kept together on a  tt_segorder       
|                     page                                              tt_code1          
|                     Valid values: names of one or more variables                        
|                     specified in COLUMNS                                                
|                                                                                         
| ORDERDATA           Variables listed in the ORDERVARS parameter that  (Blank)           
|                     are given the PROC REPORT define statement                          
|                     attribute order=data.                                               
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with ORDERVARS                         
|                     Variables not listed in ORDERFORMATTED,                             
|                     ORDERFREQ, or ORDERDATA are given the define                        
|                     attribute order=internal                                            
|                                                                                         
| ORDERFORMATTED      Variables listed in the ORDERVARS parameter that  (Blank)           
|                     are given the PROC REPORT define statement                          
|                     attribute order=formatted.                                          
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with ORDERVARS                         
|                     Variables not listed in ORDERFORMATTED,                             
|                     ORDERFREQ, or ORDERDATA are given the define                        
|                     attribute order=internal                                            
|                                                                                         
| ORDERFREQ           Variables listed in the ORDERVARS parameter that  (Blank)           
|                     are given the PROC REPORT define statement                          
|                     attribute order=freq.                                               
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with ORDERVARS                         
|                     Variables not listed in ORDERFORMATTED,                             
|                     ORDERFREQ, or ORDERDATA are given the define                        
|                     attribute order=internal                                            
|                                                                                         
| ORDERVARS           List of variables that will receive the PROC      (Blank)           
|                     REPORT define statement attribute ORDER                             
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with COLUMNS                           
|                                                                                         
| OVERALLSUMMARY      Causes the macro to produce an overall summary    N                 
|                     line. Use with ShareColVars.                                        
|                     Valid values: Y or Yes.  Any other values are                       
|                     treated as NO.                                                      
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
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with COLUMNS                           
|                                                                                         
| PROPTIONS           PROC REPORT statement options to be used in       Headline          
|                     addition to MISSING.                                                
|                     Valid values: proc report options                                   
|                     The option 'Missing' can not be overridden.                         
|                                                                                         
| RIGHTVARS           Variables to be displayed as right justified      (Blank)           
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with COLUMNS                           
|                                                                                         
| SEGMENT1            Each segment shall contain a call to either       (See list below  
|                     %tu_freq or %tu_sumstatsinrows and appropriate    descriptions)       
|                     parameters for the macro to create an output                        
|                     dataset.                                                            
|                     The percentage sign shall not be used as a                          
|                     prefix to the macro name, and the parameters                        
|                     shall not be surrounded by brackets, i.e. the                       
|                     following style shall be used: segment1 =                           
|                     MacroName parm1=value1 parm2=value2"                                
|                     Valid Values: A complete call to %tu_freq or                        
|                     %tu_sumstatsinrows. The value of this parameter                     
|                     must commence with either "%nrstr(tu_freq " or                      
|                     "%nrstr(tu_sumstatsinrows " and must end with a                     
|                     ")" for the nrstr              
|
|                     Default: 
|                     %nrstr(codedecodevarpairs=&g_trtcd &g_trtgrp,
|                     dsetout=segment1_out,groupByVarsNumer=&g_trtcd &g_trtgrp studyid,
|                     (tt_grplabel='DUMMY' %str(&sc) tt_decode1='ANY EVENT') 
|                     postsubset=IF tt_grplabel EQ 'DUMMY')
|                
|                                                                                         
| SEGMENT2            (Same as SEGMENT1)                                (See list below 
|                     Valid Values: Blank, or (Same as SEGMENT1)        descriptions)   
|
|                     Default: 
|                     %nrstr(codedecodevarpairs=&g_trtcd &g_trtgrp, dsetout=segment2_out
|                     (rename=(sex=tt_code1)),groupByVarsDenom=sex, groupByVarsNumer=
|                     &g_trtcd &g_trtgrp sex,postsubset=tt_decode1=put(sex, $sex.))
|
|
| SEGMENT3            (Same as SEGMENT1)                                (See list below 
|                     Valid Values: Blank, or (Same as SEGMENT1)        descriptions)   
|
|                     Default: 
|                     %nrstr(codedecodevarpairs=&g_trtcd &g_trtgrp racecd race,
|                     dsetout=segment3_out(rename=(race=tt_decode1 racecd=tt_code1)),
|                     groupByVarsDenom=racecd,groupByVarsNumer=&g_trtcd &g_trtgrp race 
|                     racecd,psformat=racecd $racedef.)
|
| SEGMENT4 TO         (Same as SEGMENT1)                                (Blank) 
| SEGMENT 20          Valid Values: Blank, or (Same as SEGMENT1)           
|                                                                                         
| SHARECOLVARS        List of variables that will share print space.    tt_grplabel       
|                     The attributes of the last variable in the list   tt_decode1        
|                     define the column width and flow options                            
|                     Valid values: one or more variable names from                       
|                     DSETIN                                                              
|                     AE5 shows an example of this style of output                        
|                     The formatted values of the variables shall be                      
|                     written above each other in one column.                             
|                                                                                         
| SHARECOLVARSINDENT  Indentation factor for ShareColVars. Stacked      2                 
|                     values shall be progressively indented by                           
|                     multiples of ShareColVarsIndent.                                    
|                     REQUIRED when SHARECOLVARS is specified                             
|                     Valid values: positive integer                                      
|                                                                                         
| SKIPVARS            Variables whose change in value causes the        tt_grplabel       
|                     display to skip a line                                              
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with COLUMNS                           
|                                                                                         
| SPLITCHAR           PROC REPORT split character.                      ~
|                                                                                         
|                     Valid values: split characters allowed by proc                      
|                     report.                                                             
|                                                                                         
| STACKVAR1-STACKVAR  Specifies parameters to pass to %tu_stackvar in   (Blank)           
| 15                  order to stack variables together.  See Unit                        
|                     Specification for HARP Reporting Tools                              
|                     %TU_STACKVAR[4] for more detail regarding macro                     
|                     parameters that can be used in the macro call.                      
|                     DSETIN should not be specified - this will be                       
|                     generated internally by TU_LIST.                                    
|                                                                                         
| VARSPACING          Spacing for individual columns.                   (Blank)           
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
| WIDTHS              Variables and width to display.                   (Blank)           
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
|                     default to be overridden.                                           
|                                                                                         
| XMLDEFAULTS         Full directory path and filename of ae4.xml file  &g_refdata/tr_ae4_
|                     which contains segment defaults                   defaults.xml      
|                                                  
|                                                                            
|-----------------------------------------------------------------------------------------                                                                         
| Output:   1. an output file in plain ASCII text format containing a summary in
|              columns data display matching the requirements specified as input 
|              parameters. 
|           2. SAS data set that forms the foundation of the data display (the 
|              "DD dataset").
|
|-----------------------------------------------------------------------------------------                                                                            
| Global macro variables created: none                                          
|-----------------------------------------------------------------------------------------                                                                            
|                                                                            
| Macros called:
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_chknames
| (@) tu_putglobals
| (@) tu_multisegments
| ----------------------------------------------------------------------------------------
| Change Log
|
| Modified By:              Yongwei Wang
| Date of Modification:     06-Oct-2004
| New version number:       1/2
| Modification ID:          N/A
| Reason For Modification:  Changed \ to / in the value of XMLDEFAULTS
|----------------------------------------------------------------------------------------
| Modified By:              Yongwei Wang
| Date of Modification:     06-Oct-2004
| New version number:       1/3
| Modification ID:          YW001
| Reason For Modification:  Merged the period treatment to the deom data set.
|----------------------------------------------------------------------------------------
| Modified By:
| Date of Modification:
| New version number:
| Modification ID:
| Reason For Modification:
|--------------------------------------------------------------------------------------*/
%MACRO td_ae4(
   ACROSSVAR           =&g_trtcd,          /* Variable that will be transposed to columns */                                                                                                                                                                 
   ACROSSVARDECODE     =&g_trtgrp,         /* The name of a decode variable for ACROSSVAR. */                                                                                                                                                                
   BREAK1              =,                  /* Break statements. */                                                                                                                                                                                           
   BREAK2              =,                  /* Break statements. */                                                                                                                                                                                           
   BREAK3              =,                  /* Break statements. */                                                                                                                                                                                           
   BREAK4              =,                  /* Break statements. */                                                                                                                                                                                           
   BREAK5              =,                  /* Break statements. */                                                                                                                                                                                           
   BYVARS              =,                  /* By variables */                                                                                                                                                                                                
   CENTREVARS          =,                  /* Centre justify variables */                                                                                                                                                                                    
   COLSPACING          =2,                 /* Overall spacing value. */                                                                                                                                                                                      
   COLUMNS             =tt_segorder tt_grplabel tt_code1 tt_decode1 tt_result:, /* Column parameter */                                                                                                                                                                
                            
   COMPUTEBEFOREPAGEVARS=,                 /* Computed by variables. */ 
   COMPUTEBEFOREPAGELINES=,                /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt colon labelvar) */
   DDDATASETLABEL      =DD dataset for AE4 table, /* Label to be applied to the DD dataset */                                                                                                                                                                
   DEFAULTWIDTHS       =tt_grplabel 20 tt_decode1 20, /* List of default column widths */                                                                                                                                                                    
   DESCENDING          =,                  /* Descending ORDERVARS */                                                                                                                                                                                        
   DSETIN              =ardata.ae,         /* Input dataset */                                                                                                                                                                                               
   DSETINDENOM         =ardata.demo,       /* Input dataset containing data to be counted to obtain the denominator. */
   DSETOUT             =,                  /* Output summary dataset */                                                                                                                                                                                      
   FLOWVARS            =tt_grplabel tt_decode1, /* Variables with flow option */                                                                                                                                                                                  
   FORMATS             =,                  /* Format specification */                                                                                                                                                                                        
   IDVARS              =,                  /*   */                                                                                                                                                                                                           
   LABELS              =,                  /* Label definitions. */                                                                                                                                                                                          
   LEFTVARS            =,                  /* Left justify variables */                                                                                                                                                                                      
   LINEVARS            =,                  /* Order variable printed with line statements. */                                                                                                                                                                
   NOPRINTVARS         =tt_segorder tt_code1, /* No print vars (usually used to order the display) */                                                                                                                                                           
   NOWIDOWVAR          =,                  /*   */                                                                                                                                                                                                           
   ORDERDATA           =,                  /* ORDER=DATA variables */                                                                                                                                                                                        
   ORDERFORMATTED      =,                  /* ORDER=FORMATTED variables */                                                                                                                                                                                   
   ORDERFREQ           =,                  /* ORDER=FREQ variables */                                                                                                                                                                                        
   ORDERVARS           =,                  /* Order variables */                                                                                                                                                                                             
   OVERALLSUMMARY      =N,                 /* Overall summary line at top of tables */                                                                                                                                                                       
   PAGEVARS            =,                  /* Break after <var> / page; */                                                                                                                                                                                   
   PROPTIONS           =Headline,          /* PROC REPORT statement options */                                                                                                                                                                               
   RIGHTVARS           =,                  /* Right justify variables */                                                                                                                                                                                     
   SEGMENT1=%nrstr(codedecodevarpairs=&g_trtcd &g_trtgrp,dsetout=segment1_out,groupByVarsNumer=&g_trtcd &g_trtgrp (tt_grplabel='DUMMY' %str(&sc) tt_decode1='ANY EVENT') studyid,postsubset=IF tt_grplabel EQ 'DUMMY'), /* (Same as SEGMENT10) */ 
   SEGMENT2=%nrstr(codedecodevarpairs=&g_trtcd &g_trtgrp,dsetout=segment2_out(rename=(sex=tt_code1)),groupByVarsDenom=sex,groupByVarsNumer=&g_trtcd &g_trtgrp sex,postsubset=tt_decode1=put(sex, $sex.)), /* (Same as SEGMENT10) */
   SEGMENT3=%nrstr(codedecodevarpairs=&g_trtcd &g_trtgrp racecd race,dsetout=segment3_out(rename=(race=tt_decode1 racecd=tt_code1)),groupByVarsDenom=racecd,groupByVarsNumer=&g_trtcd &g_trtgrp race racecd,psformat=racecd $racedef.), /*(Same as SEGMENT10)*/
   SEGMENT4            =,                  /* (Same as SEGMENT10) */                                                                                                                                                                             
   SEGMENT5            =,                  /* (Same as SEGMENT10) */                                                                                                                                                                             
   SEGMENT6            =,                  /* (Same as SEGMENT10) */                                                                                                                                                                             
   SEGMENT7            =,                  /* (Same as SEGMENT10) */                                                                                                                                                                             
   SEGMENT8            =,                  /* (Same as SEGMENT10) */                                                                                                                                                                             
   SEGMENT9            =,                  /* (Same as SEGMENT10) */                                                                                                                                                                             
   SEGMENT10           =,                  /* Call to %tu_freq or %tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   SEGMENT11           =,                  /* (Same as SEGMENT10) */                                                                                                                                                                             
   SEGMENT12           =,                  /* (Same as SEGMENT10) */                                                                                                                                                                             
   SEGMENT13           =,                  /* (Same as SEGMENT10) */                                                                                                                                                                             
   SEGMENT14           =,                  /* (Same as SEGMENT10) */                                                                                                                                                                             
   SEGMENT15           =,                  /* (Same as SEGMENT10) */                                                                                                                                                                             
   SEGMENT16           =,                  /* (Same as SEGMENT10) */                                                                                                                                                                             
   SEGMENT17           =,                  /* (Same as SEGMENT10) */                                                                                                                                                                             
   SEGMENT18           =,                  /* (Same as SEGMENT10) */                                                                                                                                                                               
   SEGMENT19           =,                  /* (Same as SEGMENT10) */  
   SEGMENT20           =,                  /* (Same as SEGMENT10) */  
   SHARECOLVARS        =tt_grplabel tt_decode1, /* Order variables that share print space. */                                                                                                                                                                     
   SHARECOLVARSINDENT  =2,                 /* Indentation factor */                                                                                                                                                                                          
   SKIPVARS            =tt_grplabel,       /* Break after <var> / skip; */                                                                                                                                                                                   
   SPLITCHAR           =~,                 /* PROC REPORT split character */                                                                                                                                                                                 
   STACKVAR1           =,                  /* Create Stacked variables (e.g. stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
   STACKVAR2           =,                  /* (Same as STACKVAR1) */
   STACKVAR3           =,                  /* (Same as STACKVAR1) */
   STACKVAR4           =,                  /* (Same as STACKVAR1) */
   STACKVAR5           =,                  /* (Same as STACKVAR1) */
   STACKVAR6           =,                  /* (Same as STACKVAR1) */
   STACKVAR7           =,                  /* (Same as STACKVAR1) */
   STACKVAR8           =,                  /* (Same as STACKVAR1) */
   STACKVAR9           =,                  /* (Same as STACKVAR1) */
   STACKVAR10          =,                  /* (Same as STACKVAR1) */
   STACKVAR11          =,                  /* (Same as STACKVAR1) */
   STACKVAR12          =,                  /* (Same as STACKVAR1) */
   STACKVAR13          =,                  /* (Same as STACKVAR1) */
   STACKVAR14          =,                  /* (Same as STACKVAR1) */
   STACKVAR15          =,                  /* (Same as STACKVAR1) */
   VARSPACING          =,                  /* Spacing for individual variables. */                                                                                                                                                                           
   WIDTHS              =,                  /* Column widths */                                                                                                                                                                                               
   XMLDEFAULTS         =&g_refdata/tr_ae4_defaults.xml /* Location and name of XML defaults file for td macro */          
   );
   /*
   / Echo the macro name and version to the log. Also echo the parameter values
   / and values of global macro variables used by this macro.
   /--------------------------------------------------------------------------*/
   %LOCAL MacroVersion;
   %LET MacroVersion = 1;
   %INCLUDE "&g_refdata/tr_putlocals.sas";
   
   %tu_putglobals(varsin=g_dddatasetname g_subset g_analy_disp)
   
   %LOCAL l_i l_rc sc l_prefix;
   %LET sc=%str(;);
   %LET l_prefix=_tdae4;
   
   /*
   / Check if DSETIN and DSETINDENOM are valid SAS name.  
   /--------------------------------------------------------------------------*/
   
   %IF %nrbquote(&dsetin) NE %THEN %DO;
      %IF %nrbquote(%tu_chknames(&dsetin, DATA)) NE %THEN %GOTO endmac;
   %END;
   %IF %nrbquote(&dsetindenom) NE %THEN %DO;
      %IF %nrbquote(%tu_chknames(&dsetindenom, DATA)) NE %THEN %GOTO endmac;
   %END;   
   
   /*
   / Check if the default value XML file exist.  
   /--------------------------------------------------------------------------*/
  
   %IF ( %nrbquote(&xmldefaults) NE ) %THEN %DO;
               
      LIBNAME &l_prefix.x xml "&xmldefaults";    
      
      %IF %sysfunc(fexist(&l_prefix.x)) %THEN %DO;
         %PUT %str(RTE)RROR: &sysmacroname: XMLDEFAULTS is given, but the file does not exist;
         %GOTO macerr;
      %END;
      
      %LET l_rc=0;
      
      DATA _NULL_;
         IF 0 THEN DO;
            SET  &l_prefix.x.AE4 nobs=&l_prefix.nobs;
         END;
         CALL SYMPUT('l_rc', &l_prefix.nobs);
         STOP;
      RUN;
      %IF &l_rc EQ 0 %THEN %DO;
         %PUT %str(RTE)RROR: &sysmacroname: XMLDEFAULTS is given, but the AE4 data is not in it;
         %GOTO macerr;
      %END;
      
   %END; /* End If */
   
   /*
   / YW001: Merge TRT data to &dsetindenom.
   /--------------------------------------------------------------------------*/  
   %IF ( %qupcase(%nrbquote(&g_stype)) EQ XO ) AND ( %nrbquote(&dsetindenom) NE ) %THEN %DO;   
       %LOCAL l_trtdata;
        
       /* get data libname from &g_popdata. the code should be removed after the 
          l_trtdata be changed to global macro variable */      
       %IF %index(&g_popdata, . ) GT 1 %THEN %DO;
          %LET l_trtdata=%qsubstr(&g_popdata, 1, %index(&g_popdata, . ) - 1);
          %LET l_trtdata=&l_trtdata..TRT;
       %END;  
       %ELSE %LET l_trtdata=TRT;
       
       PROC SORT DATA=&dsetindenom OUT=&l_prefix._denom;
          BY &g_centid &g_subjid;
       RUN;
       PROC SORT DATA=&l_trtdata OUT=&l_prefix._trtdata;
          BY &g_centid &g_subjid;
       RUN;
       DATA &l_prefix._denom2;
          MERGE &l_prefix._denom(IN=__IN__)
                &l_prefix._trtdata;
          BY &g_centid &g_subjid;
          IF __IN__;
       RUN; 
       
       %LET dsetindenom=&l_prefix._denom2;           
   %END; 
  
   /*
   / Check if parameters, needed for default td_ae4, are in the segment 
   / parameters, if not, add them in.                         
   /--------------------------------------------------------------------------*/  
   
   %LET l_rc=0;                                                                                          
   %DO l_i=1 %TO 20;
      %IF %nrbquote(&&segment&l_i.) NE %THEN %DO;
         DATA _NULL_;
            LENGTH segment comptxt $32761 name $40;         
            segment=symget("segment&l_i.");
            comptxt=lowcase(compress(segment));
            
            IF ( index(comptxt, "tu_freq,") EQ 1 ) 
            THEN 
               name='tu_freq';
            ELSE IF ( index(comptxt, "tu_sumstatsinrows,") EQ 1 ) 
            THEN
               name='tu_sumstatsinrow';
            ELSE DO;
               IF ( index(comptxt, "groupbyvarsnumer=") EQ 1 ) OR ( index(comptxt, ",groupbyvarsnumer") GT 0 )  
               THEN  DO;
                  name='tu_freq';
                  segment="tu_freq,"||trim(segment);
                  comptxt="tu_freq,"||trim(comptxt);                 
               END;
               ELSE IF ( index(comptxt, "analysisvars=") EQ 1 ) OR ( index(comptxt, ",analysisvars=") GT 0 )  
               THEN DO;
                   name='tu_sumstatsinrow';
                   segment="tu_sumstatsinrow,"||trim(segment);
                   comptxt="tu_sumstatsinrow,"||trim(comptxt);
               END;
               ELSE DO;
                  PUT "RTE" "RROR: &sysmacroname: segment&l_i - Can not figure out which macro it is for, TU_FREQ or TU_SUMSTATSINROWS";
                  CALL SYMPUT('l_rc', '-1');
                  STOP;
               END;               
            END;
                     
            IF ( index(comptxt, "dsetin=") NE 1 ) AND ( index(comptxt, ",dsetin=") EQ 0 )  
            THEN DO;
               IF name EQ "tu_freq" THEN  segment=trim(segment)||",dsetinnumer=&dsetin";
               ELSE segment=trim(segment)||",dsetin=&dsetin";               
            END;                                  
            IF ( index(comptxt, "dsetindenom=") NE 1 ) AND ( index(comptxt, ",dsetindenom=") EQ 0 )  
               AND ( name EQ 'tu_freq' )
            THEN DO;
               segment=trim(segment)||",dsetindenom=&dsetindenom";
            END;           
                                                        
            CALL SYMPUT("segment&l_i.", trim(segment));             
         RUN;
         
         %IF &l_rc NE 0 %THEN %GOTO macerr;
                     
      %END; /* End IF */                       
      %IF ( %nrbquote(&xmldefaults) NE ) AND ( %nrbquote(&&segment&l_i.) NE ) %THEN %DO;                                           
                                                                                                                                                  
         DATA _NULL_;
            SET &l_prefix.x.AE4 end=&l_prefix.end;
            WHERE upcase(compress(tdmacro)) EQ "TD_AE4";
            LENGTH &l_prefix.segment &l_prefix.comptxt $32761 &l_prefix.name $40;               
            RETAIN &l_prefix.segment &l_prefix.comptxt &l_prefix.name;
            
            IF _N_ EQ 1 THEN DO;
               &l_prefix.segment=symget("segment&l_i.");
               &l_prefix.comptxt=lowcase(compress(&l_prefix.segment));
               IF ( index(&l_prefix.comptxt, "tu_freq") EQ 1 )  
               THEN &l_prefix.name='tu_freq';
               ELSE &l_prefix.name='tu_sumstatsinrow';                             
            END;
            
            IF compress(lowcase(type)) EQ &l_prefix.name THEN DO;
               IF ( index(&l_prefix.comptxt, compress(lowcase(name))||"=") NE 1 ) AND 
                  ( index(&l_prefix.comptxt, ","||compress(lowcase(name))||"=") EQ 0 )  
               THEN DO;
                  &l_prefix.segment=trim(&l_prefix.segment)||","||compress(lowcase(name))||"="||trim(left(value));
                  &l_prefix.comptxt=trim(&l_prefix.comptxt)||","||compress(lowcase(name))||"="||trim(left(value));
               END;                         
            END;
            
            IF  &l_prefix.end THEN DO;
               CALL SYMPUT("segment&l_i.", trim(&l_prefix.segment));
               put &l_prefix.segment=;
            END;
         RUN;   
      %END;   /* End IF */
   %END; /* End Do-Loop */                            
   
   /* Call tu_mutltisegemnts */
     
   %tu_multisegments(
       acrossvar              =&acrossvar    
      %DO l_i=1 %TO 20;
      ,segment&l_i.           =%superq(segment&l_i.)
      %END;                              
      ,acrossvardecode        =&acrossvardecode       
      ,addbignyn              =Y                   
      ,alignyn                =Y                      
      ,break1                 =&break1                        
      ,break2                 =&break2                        
      ,break3                 =&break3                        
      ,break4                 =&break4                        
      ,break5                 =&break5                        
      ,byvars                 =&byvars                        
      ,centrevars             =&centrevars                    
      ,colspacing             =&colspacing                   
      ,columns                =&columns                       
      ,computebeforepagelines =&computebeforepagelines        
      ,computebeforepagevars  =&computebeforepagevars         
      ,dddatasetlabel         =&dddatasetlabel        
      ,defaultwidths          =&defaultwidths                 
      ,denormyn               =Y                     
      ,descending             =&descending                    
      ,display                =Y                      
      ,dsetout                =&dsetout                       
      ,flowvars               =&flowvars                 
      ,formats                =&formats                       
      ,idvars                 =&idvars                        
      ,labels                 =&labels                        
      ,labelvarsyn            =Y                  
      ,leftvars               =&leftvars                      
      ,linevars               =&linevars                      
      ,noprintvars            =&noprintvars                   
      ,nowidowvar             =&nowidowvar                    
      ,orderdata              =&orderdata                     
      ,orderformatted         =&orderformatted                
      ,orderfreq              =&orderfreq                     
      ,ordervars              =&ordervars                     
      ,overallsummary         =Y               
      ,pagevars               =&pagevars                      
      ,proptions              =&proptions             
      ,rightvars              =&rightvars                     
      ,sharecolvars           =&sharecolvars                  
      ,sharecolvarsindent     =&sharecolvarsindent           
      ,skipvars               =&skipvars                      
      ,splitchar              =&splitchar                    
      ,stackvar1              =&stackvar1                               
      ,stackvar2              =&stackvar2                     
      ,stackvar3              =&stackvar3                     
      ,stackvar4              =&stackvar4                     
      ,stackvar5              =&stackvar5                     
      ,stackvar6              =&stackvar6                     
      ,stackvar7              =&stackvar7                     
      ,stackvar8              =&stackvar8                     
      ,stackvar9              =&stackvar9                     
      ,stackvar10             =&stackvar10                    
      ,stackvar11             =&stackvar11                    
      ,stackvar12             =&stackvar12                    
      ,stackvar13             =&stackvar13                    
      ,stackvar14             =&stackvar14                    
      ,stackvar15             =&stackvar15          
      ,varlabelstyle          =SHORT            
      ,varspacing             =&varspacing                    
      ,varstodenorm           =tt_result          
      ,widths                 =&widths                         
      );
   %GOTO endmac;
  
%MACERR:
   %PUT %str(RTE)RROR: &sysmacroname: Ending with error(s);
   %LET g_abort = 1;
   %tu_abort()
%ENDMAC:
   LIBNAME &l_prefix.x xml ""; 
   %PUT %str(RTN)OTE: &sysmacroname: ending execution.;
      
%MEND td_ae4;
