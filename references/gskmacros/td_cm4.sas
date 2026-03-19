/*----------------------------------------------------------------------------------------
|
| Macro name:         td_cm4.sas
|                     
| Macro version:      2
|                     
| SAS version:        8.2
|                     
| Created by:         Alfred Montalvo Jr, Yongwei Wang (YW62951)
|                     
| Date:               05sep2003
|                     
| Macro purpose:      display macro to generate IDSL cm4 listing
|                     
| Macro design:       procedure style 
|                     
|-----------------------------------------------------------------------------------------
| Input parameters:
|
| Name                Description                                       Default           
| ----------------------------------------------------------------------------------------
| BREAK1 BREAK2       For input of user-specified break statements      No default        
| BREAK3 BREAK4       Valid values: valid PROC REPORT BREAK statements                    
| BREAK5              (without "break")                                                   
|                     The value of these parameters are passed                            
|                     directly to PROC REPORT as:                                         
|                     BREAK &break1;                                                      
|                                                                                         
| BYVARS              By variables. The variables listed here are       No default        
|                     processed as standard SAS by variables                              
|                     Valid values: one or more variable names from                       
|                     DSETIN                                                              
|                     No formatting of the display for these variables                    
|                     is performed by %tu_display.  The user has the                      
|                     option of the standard SAS BY line, or using                        
|                     OPTIONS NOBYLINE and #BYVAL #BYVAR directives in                    
|                     title statements.                                                   
|                                                                                         
| CENTREVARS          Variables to be displayed as centre justified     No default        
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with COLUMNS                           
|                     Variables not appearing in any of the parameters                    
|                     CENTREVARS, LEFTVARS, or RIGHTVARS will be                          
|                     displayed using the PROC REPORT default.                            
|                     Character variables are left justified while                        
|                     numeric variables are right justified.                              
|                                                                                         
| COLSPACING          The value of the between-column spacing           2                 
|                     Valid values: positive integer                                      
|                                                                                         
| COLUMNS             A PROC REPORT column statement specification.     &g_centid         
|                     Including spanning titles and variable names      &g_subjid         
|                     Valid values: one or more variable names from     st_cm_cst4 pernum 
|                     DSETIN plus other elements of valid PROC REPORT   st_cm_pp4 cmstdt
|                     COLUMN statement syntax                           st_cm_adt4        
|                                                                       st_cm_sap4 cmend_ 
|                                                                       cmongo  cmreas    
|                                                                                         
| COMPUTEBEFOREPAGEL  See Unit Specification for HARP Reporting Tools   No default        
| INES                TU_LIST[4] for complete details.                                    
|                                                                                         
| COMPUTEBEFOREPAGEV  See Unit Specification for HARP Reporting Tools   No default        
| ARS                 TU_LIST[4] for complete details.                                    
|                                                                                         
| DDDATASETLABEL      Specifies the label to be applied to the DD       DD dataset for    
|                     dataset                                           CM4 listing       
|                     Valid values: a non-blank text string                               
|                                                                                         
| DEFAULTWIDTHS       Specifies column widths for all variables not     ST_CM_CST4 7      
|                     listed in the WIDTHS parameter                    ST_CM_PP4 10      
|                     Valid values: values of column names and numeric  ST_CM_ADT4 24     
|                     widths                                            ST_CM_SAP4 11     
|                     For variables that are not given widths through   cmend_ 9 cmongo 7 
|                     either the WIDTHS or DEFAULTWIDTHS parameter      cmreas 10                  
|                     will be width optimised using:                                      
|                     MAX (variables format width,                                       
|                     width of  column header)                                            
|                                                                                         
| DESCENDING          List of ORDERVARS that are given the PROC REPORT  No default        
|                     define statement attribute DESCENDING                               
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with ORDERVARS                         
|                                                                                         
| DSETIN              The concomitant medications data set to act as    ardata.cmanal     
|                     the subject of the report.                        (where=(display1  
|                     Valid values: name of a data set meeting the      eq 1))            
|                     IDSL dataset specification for concomitant                          
|                     medications data                                                    
|                                                                                         
| FLOWVARS            Variables to be defined with the flow option      _ALL_             
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with COLUMNS                           
|                     Flow variables should be given a width through                      
|                     the WIDTHS.  If a flow variable does not have a                     
|                     width specified the column width will be                            
|                     determined by                                                       
|                     MIN(variables format width,                                        
|                     width of  column header)                                            
|                                                                                         
| FORMATS             Variables and their format for display. For use   cmongo $yesno.    
|                     where format for display differs to the format                      
|                     on the DSETIN.                                                      
|                     Valid values: values of column names and formats                    
|                     such as form valid syntax for a SAS FORMAT                          
|                     statement                                                           
|                                                                                         
| IDVARS              Variables to appear on each page should the       No default        
|                     report be wider than 1 page. If no value is                         
|                     supplied to this parameter then all displayable                     
|                     order variables will be defined as idvars                           
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with COLUMNS                           
|                                                                                         
| LABELS              Variables and their label for display. For use    No default        
|                     where label for display differs to the label on                     
|                     the DSETIN                                                          
|                     Valid values: pairs of variable names and labels                    
|                                                                                         
| LEFTVARS            Variables to be displayed as left justified       No default        
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with COLUMNS                           
|                                                                                         
| LINEVARS            List of order variables that are printed with     No default        
|                     LINE statements in PROC REPORT                                      
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with ORDERVARS                         
|                     These values shall be written with a BREAK                          
|                     BEFORE when the value of one of the variables                       
|                     change. The variables will automatically be                         
|                     defined as NOPRINT                                                  
|                                                                                         
| NOPRINTVARS         Variables listed in the COLUMN parameter that     &g_centid         
|                     are given the PROC REPORT define statement        &g_subjid pernum  
|                     attribute noprint.                                cmstdt
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with COLUMNS                           
|                     These variables are ORDERVARS used to control                       
|                     the order of the rows in the display.                               
|                                                                                         
| NOWIDOWVAR          Variable whose values must be kept together on a  No default        
|                     page                                                                
|                     Valid values: names of one or more variables                        
|                     specified in COLUMNS                                                
|                                                                                         
| ORDERDATA           Variables listed in the ORDERVARS parameter that  No default        
|                     are given the PROC REPORT define statement                          
|                     attribute order=data.                                               
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with ORDERVARS                         
|                     Variables not listed in ORDERFORMATTED,                             
|                     ORDERFREQ, or ORDERDATA are given the define                        
|                     attribute order=internal                                            
|                                                                                         
| ORDERFORMATTED      Variables listed in the ORDERVARS parameter that  No default        
|                     are given the PROC REPORT define statement                          
|                     attribute order=formatted.                                          
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with ORDERVARS                         
|                     Variables not listed in ORDERFORMATTED,                             
|                     ORDERFREQ, or ORDERDATA are given the define                        
|                     attribute order=internal                                            
|                                                                                         
| ORDERFREQ           Variables listed in the ORDERVARS parameter that  No default        
|                     are given the PROC REPORT define statement                          
|                     attribute order=freq.                                               
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with ORDERVARS                         
|                     Variables not listed in ORDERFORMATTED,                             
|                     ORDERFREQ, or ORDERDATA are given the define                        
|                     attribute order=internal                                            
|                                                                                         
| ORDERVARS           List of variables that will receive the PROC      &g_centid         
|                     REPORT define statement attribute ORDER           &g_subjid         
|                     Valid values: one or more variable names from     st_cm_cst4 pernum 
|                     DSETIN that are also defined with COLUMNS         st_cm_pp4 cmstdt
|                                                                       st_cm_adt4        
|                                                                       st_cm_sap4 cmend_ 
|                                                                       cmongo cmreas     
|                                                                                         
| PAGEVARS            Variables whose change in value causes the        No default        
|                     display to continue on a new page                                   
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with COLUMNS                           
|                                                                                         
| PROPTIONS           PROC REPORT statement options to be used in       Headline          
|                     addition to MISSING.                                                
|                     Valid values: proc report options                                   
|                     The option Missing can not be overridden.                         
|                                                                                         
| RIGHTVARS           Variables to be displayed as right justified      No default        
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with COLUMNS                           
|                                                                                         
| SHARECOLVARS        List of variables that will share print space.    No default        
|                     The attributes of the last variable in the list                     
|                     define the column width and flow options                            
|                     Valid values: one or more variable names from                       
|                     DSETIN                                                              
|                     AE5 shows an example of this style of output                        
|                     The formatted values of the variables shall be                      
|                     written above each other in one column.                             
|                                                                                         
| SHARECOLVARSINDENT  Indentation factor for ShareColVars. Stacked      2                 
|                     values shall be progressively indented by                           
|                     multiples of ShareColVarsIndent                                     
|                     Valid values: positive integer                                      
|                                                                                         
| SKIPVARS            Variables whose change in value causes the        ST_CM_ADT4        
|                     display to skip a line                                              
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with COLUMNS                           
|                                                                                         
| SPLITCHAR           Specifies the split character to be passed to     ~                 
|                     %tu_display                                                         
|                     Valid values: one single character                                  
|                                                                                         
| STACKVAR1           Specifies any variables that should be stacked    %str( varsin =    
|                     together.  See Unit Specification for HARP        &g_centid         
|                     Reporting Tools TU_STACKVAR[5] for more detail    &g_subjid         
|                     regarding macro parameters that can be used in    &g_trtgrp, varout 
|                     the macro call.  Note that the DSETIN parameter   = ST_CM_CST4,     
|                     will be passed by %tu_list and should not be      sepc = / )        
|                     provided here.                                                      
|                                                                                         
| STACKVAR2           Additional stacked variables (ref: stackvar1)     %str( varsin =    
|                                                                       &g_ptrtgrp        
|                                                                       period, varout =  
|                                                                       ST_CM_PP4, sepc = 
|                                                                       / )               
|                                                                                         
| STACKVAR3           Additional stacked variables (ref: stackvar1)     %str( varsin =    
|                                                                       cmatc1 cmcomp     
|                                                                       cmterm,   varout  
|                                                                       = ST_CM_ADT4,     
|                                                                       sepc = / )        
|                                                                                         
| STACKVAR4           Additional stacked variables (ref: stackvar1)     %str( varsin =    
|                                                                       cmstd_ cmactsdy  
|                                                                       cmpersdy, varout  
|                                                                       = ST_CM_SAP4,     
|                                                                       sepc = / )        
|                                                                                         
| STACKVAR5-          Specifies any variables that should be stacked    No default        
| STACKVAR15          together.  See Unit Specification for HARP                          
|                     Reporting Tools TU_STACKVAR[5] for more detail                      
|                     regarding macro parameters that can be used in                      
|                     the macro call.  Note that the DSETIN parameter                     
|                     will be passed by %tu_list and should not be                        
|                     provided here.                                                      
|                                                                                         
| VARLABELSTYLE       Specifies the style of labels to be applied by    SHORT             
|                     the %tu_labelvars macro                                             
|                     Valid values: as specified by %tu_labelvars,                        
|                     i.e. SHORT or STD                                                   
|                                                                                         
| VARSPACING          Spacing for individual columns                    No default        
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
| WIDTHS              Variables and width to display                    No default        
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
|-----------------------------------------------------------------------------------------
| Output:
|-----------------------------------------------------------------------------------------
| Global macro variables created:
|-----------------------------------------------------------------------------------------
| Macros called:
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_list
| (@) tu_nobs
| (@) tu_putglobals
| (@) tu_tidyup
|
|-----------------------------------------------------------------------------------------
| Change Log
|
| Modified by:              Yongwei Wang
| Date of modification:     03-Jun-2004
| New version number:       1/2 
| Modification ID:          YW001 
| Reason for modification:  -Changed default value of STACKVAR3, DSETIN and ORDERVARS
|-----------------------------------------------------------------------------------------
| Modified by:              Yongwei Wang (YW62951)
| Date of modification:     19-May-2005
| New version number:       2/1
| Modification ID:          yw002
| Reason for modification:  The ingredient for multi-ingredient drugs are not 
|                           displayed correctly. Following changes on the default
|                           parameter values have been made:
|                           1.Changed default DSETIN to ardata.cmanal(where=(display1 eq 1))
|                           2.Changed all cmatc1_1 to cmatc1.
|                           3.Changed all cmdecod to cmcomp
|                           4.Added data set to save &dsetin to a temporary dataset and
|                             to apply the &format.
|                           5.Added call of %tu_nobs and %tu_tidyup
|                           6.Changed all CMSTDT to CMSTD_
|-----------------------------------------------------------------------------------------
| Modified by:              Yongwei Wang (YW62951)
| Date of modification:     07-Sep-2005
| New version number:       2/2
| Modification ID:          yw002
| Reason for modification:  Changed CMSTDT_ to CMSTDT in COLUMNS, ORDERVARS and NOPRINTVARS 
|-----------------------------------------------------------------------------------------
| Modified by:
| Date of modification:
| New version number:
| Modification ID:
| Reason for modification:
|
|---------------------------------------------------------------------------------------*/

%macro td_cm4(
   BREAK1              =,                  /* Break statements */                                                                                                                                                                                     
   BREAK2              =,                  /* Break statements */                                                                                                                                                                                     
   BREAK3              =,                  /* Break statements */                                                                                                                                                                                     
   BREAK4              =,                  /* Break statements */                                                                                                                                                                                     
   BREAK5              =,                  /* Break statements */                                                                                                                                                                                     
   BYVARS              =,                  /* By variables */                                                                                                                                                                                                
   CENTREVARS          =,                  /* Centre justify variables */                                                                                                                                                                                    
   COLSPACING          =2,                 /* Value for between-column spacing */                                                                                                                                                                            
   COLUMNS             =&g_centid &g_subjid st_cm_cst4 pernum st_cm_pp4 cmstdt st_cm_adt4 st_cm_sap4 cmend_ cmongo cmreas, /* Columns to be included in the listing (plus spanned headers) */                                                               
   COMPUTEBEFOREPAGELINES=,                /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt : labelvar) */                                                                                                          
   COMPUTEBEFOREPAGEVARS=,                 /* Names of variables that define the sort order for  Compute Before Page lines */                                                                                                                                
   DDDATASETLABEL      =DD dataset for CM4 listing, /* Label to be applied to the DD dataset */                                                                                                                                                              
DEFAULTWIDTHS       =ST_CM_CST4 7 ST_CM_PP4 10 ST_CM_ADT4 24 ST_CM_SAP4 11 cmend_ 9 cmongo 7 cmreas 10,
/* List of default column widths */
   DESCENDING          =,                  /* Descending ORDERVARS */                                                                                                                                                                                        
   DSETIN              =ardata.cmanal (where=(display1 eq 1)), /* Input concomitant medications dataset */                                                                                                                                                   
   FLOWVARS            =_ALL_,             /* Variables with flow option */                                                                                                                                                                                  
   FORMATS             =cmongo $yesno.,    /* Format specification (valid SAS syntax) */                                                                                                                                                                     
   IDVARS              =,                  /* Variables to appear on each page of the report */                                                                                                                                                              
   LABELS              =,                  /* Label definitions (var=var label) */                                                                                                                                                                         
   LEFTVARS            =,                  /* Left justify variables */                                                                                                                                                                                      
   LINEVARS            =,                  /* Order variables printed with LINE statements */                                                                                                                                                                
   NOPRINTVARS         =&g_centid &g_subjid pernum cmstdt, /* No print vars, used to order the display */                                                                                                                                                    
   NOWIDOWVAR          =,                  /* List of variables whose values must be kept together on a page */                                                                                                                                              
   ORDERDATA           =,                  /* ORDER=DATA variables */                                                                                                                                                                                        
   ORDERFORMATTED      =,                  /* ORDER=FORMATTED variables */                                                                                                                                                                                   
   ORDERFREQ           =,                  /* ORDER=FREQ variables */                                                                                                                                                                                        
   ORDERVARS           =&g_centid &g_subjid st_cm_cst4 pernum st_cm_pp4 cmstdt st_cm_adt4 st_cm_sap4 cmend_ cmongo cmreas, /* Order variables */                                                                                                             
   PAGEVARS            =,                  /* Variables whose change in value causes the display to continue on a new page */                                                                                                                                
   PROPTIONS           =Headline,          /* PROC REPORT statement options */                                                                                                                                                                               
   RIGHTVARS           =,                  /* Right justify variables */                                                                                                                                                                                     
   SHARECOLVARS        =,                  /* Order variables that share print space */                                                                                                                                                                      
   SHARECOLVARSINDENT  =2,                 /* Indentation factor */                                                                                                                                                                                          
   SKIPVARS            =ST_CM_ADT4,        /* Variables whose change in value causes the display to skip a line */                                                                                                                                           
   SPLITCHAR           =~,                 /* Split character */                                                                                                                                                                                             
   STACKVAR1           =%str(varsin=&g_centid &g_subjid &g_trtgrp,varout=ST_CM_CST4,sepc=/), /* Create stacked variables */                                   
   STACKVAR2           =%str(varsin=&g_ptrtgrp period,varout=ST_CM_PP4,sepc=/), /* Create stacked variables */                                                
   STACKVAR3           =%str(varsin=cmatc1 cmcomp cmterm,varout=ST_CM_ADT4,sepc=/), /* Create stacked variables */                                          
   STACKVAR4           =%str(varsin=cmstd_ cmactsdy cmpersdy, varout=ST_CM_SAP4,sepc=/), /* Create stacked variables */ 
   STACKVAR5           =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc=~) ) */                                                                                               
   STACKVAR6           =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc=~) ) */                                                                                               
   STACKVAR7           =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc=~) ) */                                                                                               
   STACKVAR8           =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc=~) ) */                                                                                               
   STACKVAR9           =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc=~) ) */                                                                                               
   STACKVAR10          =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc=~) ) */                                                                                               
   STACKVAR11          =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc=~) ) */                                                                                               
   STACKVAR12          =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc=~) ) */                                                                                               
   STACKVAR13          =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc=~) ) */                                                                                               
   STACKVAR14          =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc=~) ) */                                                                                               
   STACKVAR15          =,                  /* Create stacked variables (e.g., stackvar1=%str(varsin= invid subjid, varout= st_inv_subj, sepc=/, splitc=~) ) */                                                                                               
   VARLABELSTYLE       =SHORT,             /* Specifies the label style for variables (SHORT or STD) */                                                                                                                                                      
   VARSPACING          =,                  /* Column spacing for individual variables */                                                                                                                                                                     
   WIDTHS              =                   /* Column widths */  
   );
   
   /* echo macro parameters to log file below */
   %local MacroVersion;
   %let MacroVersion = 2;
  
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals() 
   
   %if %nrbquote(&dsetin) eq %then 
   %do;
       %put RT%str(ERR)OR: &sysmacroname: Paramater DSETIN is blank;
       %goto macerr;     
   %end;
   
   %if %tu_nobs(&dsetin) lt 0 %then 
   %do;
       %put RT%str(ERR)OR: &sysmacroname: Data set DSETIN(=&dsetin) does not exist;       
       %goto macerr;     
   %end;
  
   data _td_cm4_dsetin;
      set &dsetin;    
      %if %nrbquote(&formats) ne %then
      %do;
         format &formats;
      %end;     
   run;
   
   %let dsetin=_td_cm4_dsetin;   
  
   /*  call tu_list below */       
   %tu_list(
      break1                 =&break1,          
      break2                 =&break2,          
      break3                 =&break3,          
      break4                 =&break4,         
      break5                 =&break5,          
      byvars                 =&byvars,          
      centrevars             =&centrevars,          
      colspacing             =&colspacing,
      columns                =&columns,
      computebeforepagelines =&computebeforepagelines,
      computebeforepagevars  =&computebeforepagevars,
      dddatasetlabel         =&dddatasetlabel,
      defaultwidths          =&defaultwidths,
      descending             =&descending,         
      display                =y,
      dsetin                 =&dsetin,
      flowvars               =&flowvars,    
      formats                =&formats,          
      getdatayn              =y,
      idvars                 =&idvars,          
      labels                 =&labels,          
      labelvarsyn            =y,
      leftvars               =&leftvars,         
      linevars               =&linevars,         
      noprintvars            =&noprintvars,
      nowidowvar             =&nowidowvar,          
      orderdata              =&orderdata,         
      orderformatted         =&orderformatted,          
      orderfreq              =&orderfreq,         
      ordervars              =&ordervars,
      overallsummary         =n,
      pagevars               =&pagevars,          
      proptions              =&proptions ,                
      rightvars              =&rightvars,         
      sharecolvars           =&sharecolvars,
      sharecolvarsindent     =&sharecolvarsindent,
      skipvars               =&skipvars,
      splitchar              =&splitchar,         
      stackvar1              =&stackvar1 ,
      stackvar10             =&stackvar10,        
      stackvar11             =&stackvar11,        
      stackvar12             =&stackvar12,         
      stackvar13             =&stackvar13,         
      stackvar14             =&stackvar14,        
      stackvar15             =&stackvar15,        
      stackvar2              =&stackvar2,
      stackvar3              =&stackvar3,
      stackvar4              =&stackvar4,        
      stackvar5              =&stackvar5,         
      stackvar6              =&stackvar6,        
      stackvar7              =&stackvar7,        
      stackvar8              =&stackvar8,         
      stackvar9              =&stackvar9,         
      varlabelstyle          =&varlabelstyle,   
      varspacing             =&varspacing,          
      widths                 =&widths         
      );     
                   
      %goto endmac;  
         
%MACERR:
   %let g_abort=1;      
   %tu_abort(option=force); 

%ENDMAC:           
   %tu_tidyup(
      rmdset=_td_cm4:,
      glbmac=NONE
      );   
                               
%mend td_cm4;               
                          
