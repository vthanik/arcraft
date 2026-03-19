/*----------------------------------------------------------------------------------------
|
| Macro name:         td_ae2.sas
|                    
| Macro version:      2
|                    
| SAS version:        8.2
|                    
| Created by:         Alfred Montalvo Jr
|                    
| Date:               04aug2003
|                    
| Macro purpose:      display macro to generate IDSL ae2 listingd
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
| COLSPACING          The value of the between-column spacing.          1                 
|                     Valid values: positive integer                                      
|                                                                                         
| COLUMNS             A PROC REPORT column statement specification.     aesoc aept aeterm 
|                     Including spanning titles and variable names                        
|                     Valid values: one or more variable names from                       
|                     DSETIN plus other elements of valid PROC REPORT                     
|                     COLUMN statement syntax                                             
|                                                                                         
| COMPUTEBEFOREPAGEL  See Unit Specification for HARP Reporting Tools   No default        
| INES                TU_LIST[4] for complete details.                                    
|                                                                                         
| COMPUTEBEFOREPAGEV  See Unit Specification for HARP Reporting Tools   No default        
| ARS                 TU_LIST[4] for complete details.                                    
|                                                                                         
| DDDATASETLABEL      Specifies the label to be applied to the DD       DD dataset for    
|                     dataset                                           AE2 listing       
|                     Valid values: a non-blank text string                               
|                                                                                         
| DEFAULTWIDTHS       This parameter specifies default column widths    aesoc 28 aept 30  
|                     for all variables not listed in the WIDTHS        aeterm 30         
|                     parameter.                                                          
|                     Valid values: values of column names and numeric                    
|                     widths, a list of variables followed by a                           
|                     positive integer, e.g.                                              
|                                                                                         
|                     defaultwidths = a b 10 c 12 d1-d4 6                                 
|                     Numbered range lists are supported in this                          
|                     parameter however name range lists, name prefix                     
|                     lists, and special SAS name lists are not.                          
|                                                                                         
| DESCENDING          List of ORDERVARS that are given the PROC REPORT  No default        
|                     define statement attribute DESCENDING                               
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with ORDERVARS                         
|                                                                                         
| DSETIN              The adverse event data set to act as the subject  ardata.ae         
|                     of the report.                                                      
|                     Valid values: name of a data set meeting the                        
|                     IDSL dataset specification for AE data                              
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
| FORMATS             Variables and their format for display. For use   No default        
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
| NAME                Description                                       Default           
|                                                                                         
| NOPRINTVARS         Variables listed in the COLUMN parameter that     No default        
|                     are given the PROC REPORT define statement                          
|                     attribute noprint.                                                  
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
| ORDERVARS           List of variables that will receive the PROC      aesoc aept aeterm 
|                     REPORT define statement attribute ORDER                             
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with COLUMNS                           
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
| SKIPVARS            Variables whose change in value causes the        aesoc             
|                     display to skip a line                                              
|                     Valid values: one or more variable names from                       
|                     DSETIN that are also defined with COLUMNS                           
|                                                                                         
| SPLITCHAR           Specifies the split character to be passed to     ~                 
|                     %tu_display                                                         
|                     Valid values: one single character                                  
|                                                                                         
| STACKVAR1-          Specifies any variables that should be stacked    No default        
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
|-----------------------------------------------------------------------------------------
|-----------------------------------------------------------------------------------------
| Output:
|-----------------------------------------------------------------------------------------
| Global macro variables created:
|
|-----------------------------------------------------------------------------------------
| Macros called:
| (@) tr_putlocals   
| (@) tu_abort       
| (@) tu_chkvarsexist
| (@) tu_getdata     
| (@) tu_list        
| (@) tu_nobs        
| (@) tu_putglobals  
| (@) tu_tidyup      
|-----------------------------------------------------------------------------------------
| Change Log
|
| Modified by:              Yongwei Wang (YW62951)
| Date of modification:     19-Aug-2005
| New version number:       2/1
| Modification ID:          yw001
| Reason for modification:  1.Added call of %tu_nobs to check if &dsetin exist
|                           2.Added check if &dsetin is exist
|                           3.Added check if &columns exist in &dsetin
|                           4.Added call of %tu_getdata before calling %tu_list
|                           5.Re-arranged the order of parameters to alphabetic
|                           6.Re-formated the header
|                           7.Passed 'n' to GETDATAYN parameter of %tu_list, instead of 'y'
|
|-----------------------------------------------------------------------------------------
| Modified by:
| Date of modification:
| New version number:
| Modification ID:
| Reason for modification:
|
|---------------------------------------------------------------------------------------*/

%macro td_ae2(
   break1         =,          /* Break statements */
   break2         =,          /* Break statements */
   break3         =,          /* Break statements */
   break4         =,          /* Break statements */
   break5         =,          /* Break statements */
   byvars         =,          /* By variables */
   centrevars     =,          /* Centre justify variables */
   colspacing     =1,         /* Value for between-column spacing */ 
   columns        =aesoc aept aeterm, /* Columns to be included in the listing (plus spanned headers) */
   computebeforepagelines=,   /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt : labelvar) */
   computebeforepagevars=,    /* Names of variables that define the sort order for  Compute Before Page lines */
   dddatasetlabel =DD dataset for AE2 listing,  /* Label to be applied to the DD dataset                        */ 
   defaultwidths  =aesoc 28 aept 30 aeterm 30,   /* List of default column widths */
   descending     =,          /* Descending ORDERVARS */
   dsetin         =ardata.ae, /* Input adverse event dataset */
   flowvars       =_all_,     /* Variables with flow option */
   formats        =,          /* Format specification (valid SAS syntax) */
   idvars         =,          /* Variables to appear on each page of the report */
   labels         =,          /* Label definitions (var="var label")     */
   leftvars       =,          /* Left justify variables   */ 
   linevars       =,          /* Order variables printed with LINE statemen  */
   noprintvars    =,          /* No print variables, used to order the display */
   nowidowvar     =,          /* List of variables whose values must be kept together on a page */
   orderdata      =,          /* ORDER=DATA variables */
   orderformatted =,          /* ORDER=FORMATTED variables */
   orderfreq      =,          /* ORDER=FREQ variables */
   ordervars      =aesoc aept aeterm, /* Order variables               */
   pagevars       =,          /* Variables whose change in value causes the display to continue on a new page */
   proptions      =headline,  /* PROC REPORT statement options                 */
   rightvars      =,          /* Right justify variables  */
   sharecolvars   =,          /* Order variables that share print space */
   sharecolvarsindent=2,      /* Indentation factor */
   skipvars       =aesoc,     /* Variables whose change in value causes the display to skip a line  */
   splitchar      =~,         /* Split character */
   stackvar1      =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar2      =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar3      =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar4      =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar5      =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar6      =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar7      =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar8      =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar9      =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar10     =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar11     =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar12     =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar13     =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar14     =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   stackvar15     =,          /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~))       */
   varlabelstyle  =SHORT,     /* Specifies the label style for variables (SHORT or STD)  */
   varspacing     =,          /* Column spacing for individual variables */
   widths         =           /* Column widths */
   );

   /* echo macro parameters to log file below */  
   %local MacroVersion;
   %let MacroVersion = 2;
   
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals() 
  
   %local l_prefix;
   %let l_prefix=_td_ae2_;
   
   %if %nrbquote(&dsetin) eq %then 
   %do;
       %put RT%str(ERR)OR: &sysmacroname: Paramater DSETIN is blank;
       %goto macerr;     
   %end;
   
     /* yw001: Added call of %tu_nobs to check if &dsetin exist  */
   %if %tu_nobs(&dsetin) lt 0 %then 
   %do;
       %put RT%str(ERR)OR: &sysmacroname: Data set DSETIN(=&dsetin) does not exist;       
       %goto macerr;     
   %end;
   
   %if %nrbquote(&columns) eq %then %goto displayit;   
   
   /* yw001: Check if variables given by &columns exist in &dsetin */
   %let l_rc=%tu_chkvarsexist(&dsetin, &columns);
   
   %if %nrbquote(&l_rc) eq -1 %then 
   %do;
       %put RT%str(ERR)OR: &sysmacroname: Illegal characters are found in COLUMNS(=&columns);
       %goto macerr;   
   %end;
   %else %if %nrbquote(&l_rc) ne %then 
   %do;
       %put RT%str(ERR)OR: &sysmacroname: Variable &l_rc, which are given by COLUMNS(=&columns), do not exist in DSETIN(=&dsetin);
       %goto macerr;
   %end; 
   
   /* YW001: call %tu_getdata to subset input data set */
   data &l_prefix.subset;
      set &dsetin;
   run;
     /* YW001: Added call of %tu_getdata before calling %tu_list */

   %tu_getdata(
      DSETIN=&l_prefix.subset, 
      DSETOUT1=&l_prefix.getdata,
      DSETOUT2=
      );        
    
   /* remove duplicate observations below  */
   proc sort data=&l_prefix.getdata out=&l_prefix.dsetin nodupkey;
        by &columns;
   run;
        
   %let dsetin=&l_prefix.dsetin;   
   
%DISPLAYIT:

   /*  call tu_list below */ 
   
   /* YW001: .Passed 'n' to GETDATAYN parameter of %tu_list, instead of 'y' */ 
   
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
      computebeforepagevars  =&computebeforepagevars ,
      dddatasetlabel         =&dddatasetlabel,
      defaultwidths          =&defaultwidths,
      descending             =&descending,         
      display                =y,
      dsetin                 =&dsetin,
      flowvars               =&flowvars,    
      formats                =&formats,          
      getdatayn              =n,
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
      stackvar2              =&stackvar2 ,
      stackvar3              =&stackvar3  ,
      stackvar4              =&stackvar4 ,        
      stackvar5              =&stackvar5  ,         
      stackvar6              =&stackvar6  ,        
      stackvar7              =&stackvar7  ,        
      stackvar8              =&stackvar8  ,         
      stackvar9              =&stackvar9  ,         
      stackvar10             =&stackvar10 ,        
      stackvar11             =&stackvar11 ,        
      stackvar12             =&stackvar12 ,         
      stackvar13             =&stackvar13 ,         
      stackvar14             =&stackvar14 ,        
      stackvar15             =&stackvar15 ,        
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
      rmdset=&l_prefix.:,
      glbmac=NONE
      );    
         
%mend td_ae2;  
