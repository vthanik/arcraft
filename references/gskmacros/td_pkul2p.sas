/*--------------------------------------------------------------------------------------------------
| Macro name:     td_pkul2p.sas
|
| Macro version:  01-002
|
| SAS version:    8.2
|
| Created by:     Yongwei Wang / David Sankey
|
| Date:           15-Jun-2005
|
| Macro purpose:  Display macro to create IDSL PKOne table PKUL2P for Parallel Group Studies
|
| Macro design:   Procedure style 
|
| Input parameters:
|
| NAME            DESCRIPTION                                          DEFAULT
|---------------------------------------------------------------------------------------------------
|
| BREAK1          Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| BREAK2          Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| BREAK3          Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| BREAK4          Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| BREAK5          Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| BYVARS          Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| CENTERVARS      Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| COLSPACING      Passed as %tu_list parameter of the same name.       2 (Req)
|
| COLUMNS         Passed as %tu_list parameter of the same name.       &g_centid &g_subjid st_cs visitnum visit 
|                                                                      ptmnum ptm pcstdt pcsttm pcendt pcentm pcallcol (Req)
|
| COMPUTEBEFORE-  Passed as %tu_list parameter of the same name.       TRTMNT $local. : &g_trtgrp (Req)
| PAGELINES      
|
| COMPUTEBEFORE-  Passed as %tu_list parameter of the same name.       &g_trtcd (Req)            
| PAGEVARS
| 
| DDDATASETLABEL  Passed as %tu_list parameter of the same name.       DD Listing for a listing PKUL2P (Req)
|
| DEFAULTWIDTHS   Passed as %tu_list parameter of the same name.       st_cs 8 visit 9 ptm 8 pcstdt 9 pcsttm 6 
|                                                                      pcendt 9 pcentm 6 pcallcol 10  (Req) 
|
| DESCENDING      Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| DISPLAY         Passed as %tu_list parameter of the same name.       Y (Req)
|
| DSETIN          The PK Parameter dataset meeting IDSL dataset        ardata.pkcnc (Req)
|                 specification for PKCNC data
|
| FLOWVARS        Passed as %tu_list parameter of the same name.       st_cs visit ptm (Req)
|
| FORMATS         Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| GETDATAYN       Passed as %tu_list parameter of the same name.       Y  (Req)
|
| IDVARS          Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| LABELS          Passed as %tu_list parameter of the same name.       st_cs="Inv./~Subj."  (Req)
|
| LABELVARSYN     Passed as %tu_list parameter of the same name.       Y  (Req)
|
| LEFTVARS        Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| LINEVARS        Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| NOPRINTVARS     Passed as %tu_list parameter of the same name.       visitnum ptmnum &g_centid &g_subjid (Req)
|
| NOWIDOWVAR      Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| ORDERDATA       Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| ORDERFORMATTED  Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| ORDERFREQ       Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| ORDERVARS       Passed as %tu_list parameter of the same name.       &g_centid &g_subjid st_cs visitnum visit 
|                                                                      ptmnum ptm pcstdt pcsttm (Req)
|
| OVERALLSUMMARY  Passed as %tu_list parameter of the same name.       N (Req)
|
| PAGEVARS        Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| PROPTIONS       Passed as %tu_list parameter of the same name.       HEADLINE (Req)
|
| RIGHTVARS       Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| SHARECOLVARS    Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| SHARECOLVARS-   Passed as %tu_list parameter of the same name.       2 (Req)
| INDENT
|
| SKIPVARS        Passed as %tu_list parameter of the same name.       visitnum (Req)
|
| SPLITCHAR       Passed as %tu_list parameter of the same name.       ~ (Req)
|
| STACKVAR1       Passed as %tu_list parameter of the same name.       %str(varsin=&g_centid &g_subjid, varout=st_cs, sepc=/) (Req)
|
| STACKVAR2       Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| STACKVAR3       Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| STACKVAR4       Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| STACKVAR5       Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| STACKVAR6       Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| STACKVAR7       Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| STACKVAR8       Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| STACKVAR9       Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| STACKVAR10      Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| STACKVAR11      Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| STACKVAR12      Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| STACKVAR13      Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| STACKVAR14      Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| STACKVAR15      Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| VARLABELSTYLE   Passed as %tu_list parameter of the same name.       SHORT (Req)
|
| VARSPACING      Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| WIDTHS          Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| Output:
|
| Global macro variables created: None
|
| Macros called:
|
| (@) tr_putlocals
| (@) tu_list
| (@) tu_putglobals
|
|
|-----------------------------------------------------------------------------------
| Change Log
|
| Modified by:
| Date of modification:
| New version number:
| Modification ID:
| Reason for modification:
|
|-----------------------------------------------------------------------------------
| Change Log
|
| Modified by:             David Sankey
| Date of modification:    03-Aug-05
| New version number:      01-002
| Modification ID:         DIS.01.002
| Reason for modification: DIS.01.002.a: Modifications to header based on feedback 
|                                        from SCR
|
+----------------------------------------------------------------------------------*/


%macro td_pkul2p(
   break1         =,          /* Break statements. */
   break2         =,          /* Break statements. */
   break3         =,          /* Break statements. */
   break4         =,          /* Break statements. */
   break5         =,          /* Break statements. */
   byvars         =,          /* By variables */
   centrevars     =,          /* Centre justify variables */
   colspacing     =2,         /* Overall spacing value. */
   columns        =&g_centid &g_subjid st_cs visitnum visit ptmnum ptm pcstdt pcsttm pcendt pcentm pcallcol, /* Column parameter */
   computebeforepagelines=TRTMNT $local. : &g_trtgrp, /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt colon labelvar) */
   computebeforepagevars=&g_trtcd, /* Names of variables that shall define the sort order for Compute Before Page lines */
   dddatasetlabel =DD dataset for a listing PKUL2P, /* Label to be applied to the DD dataset */
   defaultwidths  =st_cs 8 visit 9 ptm 8 pcstdt 9 pcsttm 6 pcendt 9 pcentm 6 pcallcol 10, /* List of default column widths */
   descending     =,          /* Descending ORDERVARS */
   display        =Y,         /* Specifies whether the report should be created */
   dsetin         =ardata.pkcnc, /* type:ID Name of input analysis dataset */
   flowvars       =st_cs visit ptm, /* Variables with flow option */
   formats        =,          /* Format specification */
   getdatayn      =Y,         /* Control execution of tu_getdata */
   idvars         =,          /* ID variables */
   labels         =st_cs="Inv./~Subj.", /* Label definitions. */
   labelvarsyn    =Y,         /* Control execution of tu_labelvars */
   leftvars       =,          /* Left justify variables */
   linevars       =,          /* Order variable printed with line statements. */
   noprintvars    =visitnum ptmnum &g_centid &g_subjid,/* No print vars (usually used to order the display) */
   nowidowvar     =,          /* Not in version 1 */
   orderdata      =,          /* ORDER=DATA variables */
   orderformatted =,          /* ORDER=FORMATTED variables */
   orderfreq      =,          /* ORDER=FREQ variables */
   ordervars      =&g_centid &g_subjid st_cs visitnum visit ptmnum ptm pcstdt pcsttm, /* Order variables */
   overallsummary =n,         /* Overall summary line at top of tables */
   pagevars       =,          /* Break after <var> / page */
   proptions      =HEADLINE,  /* PROC REPORT statement options */
   rightvars      =,          /* Right justify variables */
   sharecolvars   =,          /* Order variables that share print space. */
   sharecolvarsindent=2,      /* Indentation factor */
   skipvars       =visitnum,  /* Break after <var> / skip */
   splitchar      =~,         /* Split character */
   stackvar1      =%str(varsin=&g_centid &g_subjid, varout=st_cs, sepc=/), /* Create Stacked variables (e.g. stackvar1=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
   stackvar2      =,          /* Create Stacked variables (e.g. stackvar2=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
   stackvar3      =,          /* Create Stacked variables (e.g. stackvar3=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
   stackvar4      =,          /* Create Stacked variables (e.g. stackvar4=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
   stackvar5      =,          /* Create Stacked variables (e.g. stackvar5=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
   stackvar6      =,          /* Create Stacked variables (e.g. stackvar6=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
   stackvar7      =,          /* Create Stacked variables (e.g. stackvar7=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
   stackvar8      =,          /* Create Stacked variables (e.g. stackvar8=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
   stackvar9      =,          /* Create Stacked variables (e.g. stackvar9=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
   stackvar10     =,          /* Create Stacked variables (e.g. stackvar10=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~))*/
   stackvar11     =,          /* Create Stacked variables (e.g. stackvar11=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~))*/
   stackvar12     =,          /* Create Stacked variables (e.g. stackvar12=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~))*/
   stackvar13     =,          /* Create Stacked variables (e.g. stackvar13=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~))*/
   stackvar14     =,          /* Create Stacked variables (e.g. stackvar14=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~))*/
   stackvar15     =,          /* Create Stacked variables (e.g. stackvar15=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~))*/
   varlabelstyle  = SHORT,    /* Specifies the label style for variables (SHORT or STD) */
   varspacing     =,          /* Spacing for individual variables. */
   widths         =           /* Column widths */
   );

   /*
   / Echo the macro name and version to the log. Also echo the parameter values
   / and values of global macro variables used by this macro.
   /---------------------------------------------------------------------------*/
  
   %local MacroVersion;
   %let MacroVersion = 1;
  
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals(varsin=);

   /*
   / Parameter Validation: None
   / All validations performed by %tu_list
   /
   / Now call %tu_list to run report.
   /---------------------------------------------------------------------------*/

   %tu_list(
       break1                 =&break1                 ,
       break2                 =&break2                 ,
       break3                 =&break3                 ,
       break4                 =&break4                 ,
       break5                 =&break5                 ,
       byvars                 =&byvars                 ,
       centrevars             =&centrevars             ,
       colspacing             =&colspacing             ,
       columns                =&columns                ,
       computebeforepagelines =&computebeforepagelines ,
       computebeforepagevars  =&computebeforepagevars  ,
       dddatasetlabel         =&dddatasetlabel         ,
       defaultwidths          =&defaultwidths          ,
       descending             =&descending             ,
       display                =&display                ,
       dsetin                 =&dsetin                 ,
       flowvars               =&flowvars               ,
       formats                =&formats                ,
       getdatayn              =&getdatayn              ,
       idvars                 =&idvars                 ,
       labels                 =&labels                 ,
       labelvarsyn            =&labelvarsyn            ,
       leftvars               =&leftvars               ,
       linevars               =&linevars               ,
       noprintvars            =&noprintvars            ,
       nowidowvar             =&nowidowvar             ,
       orderdata              =&orderdata              ,
       orderformatted         =&orderformatted         ,
       orderfreq              =&orderfreq              ,
       ordervars              =&ordervars              ,
       overallsummary         =&overallsummary         ,
       pagevars               =&pagevars               ,
       proptions              =&proptions              ,
       rightvars              =&rightvars              ,
       sharecolvars           =&sharecolvars           ,
       sharecolvarsindent     =&sharecolvarsindent     ,
       skipvars               =&skipvars               ,
       splitchar              =&splitchar              ,
       stackvar1              =&stackvar1              ,
       stackvar2              =&stackvar2              ,
       stackvar3              =&stackvar3              ,
       stackvar4              =&stackvar4              ,
       stackvar5              =&stackvar5              ,
       stackvar6              =&stackvar6              ,
       stackvar7              =&stackvar7              ,
       stackvar8              =&stackvar8              ,
       stackvar9              =&stackvar9              ,
       stackvar10             =&stackvar10             ,
       stackvar11             =&stackvar11             ,
       stackvar12             =&stackvar12             ,
       stackvar13             =&stackvar13             ,
       stackvar14             =&stackvar14             ,
       stackvar15             =&stackvar15             ,       
       varlabelstyle          =&varlabelstyle          ,
       varspacing             =&varspacing             ,
       widths                 =&widths                 
       );


%mend td_pkul2p;

