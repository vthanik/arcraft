/*--------------------------------------------------------------------------------------------------
| Macro name:     td_pkpl1p.sas
|
| Macro version:  01-002
|
| SAS version:    8.2
|
| Created by:     Yongwei Wang / Greg Weber
|
| Date:           07Mar2005
|
| Macro purpose:  Display macro to create IDSL PKOne table PKPL1P
|
| Macro design:   procedure style utility
|
| Input parameters:
|
| NAME            DESCRIPTION                                          DEFAULT
|---------------------------------------------------------------------------------------------------
| ALIGNYN         Execute tu_align macro: Yes or No Valid values: Y|N  Y (Opt)
|
| ACROSSCOLVAR-   Passed as %tu_denorm parameter of the same name.     tt_p (Req)
| PREFIX
|
| ACROSSVAR       Passed as %tu_denorm parameter of the same name.     pppar (Req)
|
| ACROSSVARLABEL  Passed as %tu_denorm parameter of the same name.     (blank) (Opt)
|
| ACROSSCOLLIST-  Passed as %tu_denorm parameter of the same name.     _acrossvarlistname (Req)
| NAME   
|
| GROUPBYVARS-    Passed as %tu_denorm parameter GROUPBYVARS           &g_trtcd &g_trtgrp &g_centid &g_subjid visitnum
| DENORM                                                               visit   (Req)
|
| VARSTODENORM    Passed as %tu_denorm parameter of the same name.     pporresn (Req)
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
| COLUMNS         Passed as %tu_list parameter of the same name.       &g_centid &g_subjid st_cs 
|                                                                      visitnum visit tt_p (Req)
|
| COLSPACING      Passed as %tu_list parameter of the same name.       2 (Req)
|
| COMPUTEBEFORE-  Passed as %tu_list parameter of the same name.       TRTMNT $local. : &g_trtgrp (Req)
| PAGELINES      
|
| COMPUTEBEFORE-  Passed as %tu_list parameter of the same name.       &g_trtcd (Opt)            
| PAGEVARS
| 
| DDDATASETLABEL  Passed as %tu_list parameter of the same name.       DD Listing for listing PKPL1P (Req)
|
| DEFAULTWIDTHS   Passed as %tu_list parameter of the same name.       st_cs 6 visit 9 ptm 8 pcstresc 8 tt_p: 11 (Req) 
|
| DESCENDING      Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| DISPLAY         Passed as %tu_list parameter of the same name.       Y (Req)
|
| DSETIN          The PK Parameter dataset meeting IDSL dataset        ardata.pkpar (Req)
|                 specification for PKPAR data
|
| FLOWVARS        Passed as %tu_list parameter of the same name.       st_cs visit (Req)
|
| FORMATS         Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| IDVARS          Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| LABELS          Passed as %tu_list parameter of the same name.       st_cs="Inv./~Subj."
|
| LABELVARSYN     Passed as %tu_list parameter of the same name.       Y  (Req)
|
| LEFTVARS        Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| LINEVARS        Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| NOPRINTVARS     Passed as %tu_list parameter of the same name.       &g_centid &g_subjid visitnum (Req)
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
|
| OVERALLSUMMARY  Passed as %tu_list parameter of the same name.       N (Req)
|
| PAGEVARS        Passed as %tu_list parameter of the same name.       (blank) (Opt)
|
| PROPTIONS       Passed as %tu_list parameter of the same name.       headline (Req)
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
| VARLABELSTYLE   Passed as %tu_list parameter of the same name.       short (Req)
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
| (@) tr_putlocals
| (@) tu_align
| (@) tu_denorm
| (@) tu_getdata
| (@) tu_list
| (@) tu_nobs
| (@) tu_putglobals
| (@) tu_tidyup
| (@) tu_valparms
|
|-----------------------------------------------------------------------------------
| Change Log
|
| Modified by:              Greg Weber 
| Date of modification:     02-Aug-05
| New version/draft number: 01-002
| Modification ID:          GTW1.0
| Reason for modification:  Add call to getdata macro.
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
+----------------------------------------------------------------------------------*/

%macro td_pkpl1p(
   alignyn        =Y,         /* Call %tu_align to align the across column variables */
   acrossColVarPrefix=tt_p,   /* Text passed to the PROC TRANSPOSE PREFIX statement. */
   acrossVar      =pppar,     /* Variable used in the PROC TRANSPOSE ID statement.  */
   acrossVarLabel =,          /* Variable used in the PROC TRANSPOSE IDLABEL statement. */
   acrossColListName=_acrossVarListName, /* Macro variable name to contain the list of columns created by the transpose of the first variable in VARSTOD ENORM.*/
   groupByVarsDenorm=&g_trtcd &g_trtgrp &g_centid &g_subjid visitnum visit, /* List of BY variables passed to PROC TRANSPOSE BY statement.*/
   varsToDenorm   =pporresn,  /* List of variables to be denormalised/transposed. Passed one at a time to the PROC TRANSPOSE VAR statement.*/
   break1         =,          /* Break statements. */
   break2         =,          /* Break statements. */
   break3         =,          /* Break statements. */
   break4         =,          /* Break statements. */
   break5         =,          /* Break statements. */
   byvars         =,          /* By variables */
   centrevars     =,          /* Centre justify variables */
   colspacing     =2,         /* Overall spacing value. */
   columns        =&g_centid &g_subjid st_cs visitnum visit tt_p:, /* Column parameter */
   computebeforepagelines=TRTMNT $local. : &g_trtgrp, /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt colon labelvar) */
   computebeforepagevars=&g_trtcd, /* Names of variables that shall define the sort order for Compute Before Page lines */
   dddatasetlabel = DD dataset for a listing PKPL1P, /* Label to be applied to the DD dataset */
   defaultwidths  =st_cs 6 visit 9 ptm 8 pcstresc 8 tt_p: 11, /*  List of default column widths */
   descending     =,          /* Descending ORDERVARS */
   display        =Y,         /* Specifies whether the report should be created */
   dsetin         =ardata.pkpar, /* Input domain dataset */
   flowvars       =st_cs visit, /* Variables with flow option */
   formats        =,          /* Format specification */
   idvars         =,          /* ID variables */
   labels         =st_cs="Inv./~Subj.", /* Label definitions. */
   labelvarsyn    =Y,         /* Control execution of tu_labelvars */
   leftvars       =,          /* Left justify variables */
   linevars       =,          /* Order variable printed with line statements. */
   noprintvars    =&g_centid &g_subjid visitnum, /* No print vars (usually used to order the display) */
   nowidowvar     =,          /* Not in version 1 */
   orderdata      =,          /* ORDER=DATA variables */
   orderformatted =,          /* ORDER=FORMATTED variables */
   orderfreq      =,          /* ORDER=FREQ variables */
   ordervars      =&g_centid &g_subjid st_cs visitnum visit, /* Order variables */
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
   /------------------------------------------------------------------------------*/
  
   %local MacroVersion;
   %let MacroVersion = 1;   
   %include "&g_refdata/tr_putlocals.sas";   
   %tu_putglobals(varsin=);
   
   %local l_prefix;
   %let l_prefix=_td_pkpl1p;
   
    
   /*
   / Perform parameter validation
   / Macro-variables macroname and pv_abort are required by tu_valparms macro.
   /------------------------------------------------------------------------------*/

   %local macroname pv_abort;
   %let macroname = &sysmacroname.;
   %let pv_abort = 0;

   /*
   / Verify that the dataset DSETIN exists
   /------------------------------------------------------------------------------*/

   %tu_valparms(macroname=&macroname,
                chktype=dsetExists,
                pv_dsetin=dsetin,
                abortyn=Y);

   /*
   / Verify that PPPAR and PPORRESU exist on DSETIN
   /------------------------------------------------------------------------------*/
   %local pv_checkvars;
   %let pv_checkvars = pppar pporresu;

   %tu_valparms(macroname=&macroname,
                chktype=varExists,
                pv_dsetin=dsetin,
                pv_varsin=pv_checkvars,
                abortyn=n);
   /*
   / Verify that ALIGNYN = Y or N          
   /------------------------------------------------------------------------------*/

   %tu_valparms(macroname=&macroname,
                chktype=isoneof,
                pv_varsin = alignyn,
                valuelist = Y N,
                abortyn=y);

   /* 
   / Perform Normal Processing
   /------------------------------------------------------------------------------*/   
   
   
   /*
   / Call tu_getdata to subset the CURRENTDATASET [GTW1.0]
   / Use tu_nobs to check dataset
   /------------------------------------------------------------------------------*/

   %local currentdataset;
   %let currentdataset=&dsetin;

   %tu_getdata(dsetin=&currentdataset.,
               dsetout1=&l_prefix._analydata,
               dsetout2=
                );

   %let currentdataset=&l_prefix._analydata;

   %if %tu_nobs(&currentdataset.) eq 0 %then %do;
     %put %str(RTE)RROR: &sysmacroname: The dataset DSETIN (dsetin=&dsetin.) has zero observations after subsetting by G_SUBSET (g_subset=&g_subset.) global macro variable;
     %tu_abort(option=force);
   %end;
   
   /* End: [GTW1.0]  */

   /*
   / Combine PPPAR and PPORRESU together.  First calculate required length.
   / and store in l_vlen
   /------------------------------------------------------------------------------*/
   
   %local l_vlen;

   data _null_;   
     length vlen $40;
     set &currentdataset.;
     vlen=put(vlength(PPPAR) + vlength(PPORRESU) + 3, best12.);
     call symput('l_vlen', compress(vlen));
   run;
   
   
   /*
   / Determine if Format $PKPFMT exists
   / Use System options to get a list of libnames to check for format
   /------------------------------------------------------------------------------*/
   %local fmt i liblst rc lib;
   
   %let liblst=%sysfunc(getoption(fmtsearch));
   %let liblst=%sysfunc( translate( &liblst, %str( ), %str(%(%) ) ) );
   %let liblst=%sysfunc(compbl( %trim( %left(&liblst) ) ) );
  
   %let fmt=PKPFMT;  
   %let i=1;  
   %let lib=%scan(&liblst,&i,%str(, )); 
   %let rc=0;
   
   %do %while ( &lib. ne %str( ) and &rc. eq 0);
  
      %if %index(&lib,.) eq 0 %then %let lib = &lib..formats ;
       
      %let rc=%eval(%sysfunc(cexist(&lib..&fmt..format)) +
                    %sysfunc(cexist(&lib..&fmt..formatc)));
                                 
      %let i=%eval(&i + 1);
      %let lib=%scan(&liblst,&i,%str(, ));    
   %end;
  
  
   %if &rc. eq 1 %then
   %do; 
             
      /*
      / RC is 1. $PKPFMT format is available 
      / Now apply the $PKPFMT to pppar and create a new variable
      / with pppar and pporresu to build a label with PPPAR and its Units                                
      /------------------------------------------------------------------------------*/             
   
      data &l_prefix.pkpfmt (rename=(pppar_temp=pppar) drop=pppar); 
        length pppar_temp $&l_vlen. ;                
        set &currentdataset.;     
        if not missing(pporresu) then pppar_temp=trim(left( put(pppar, &fmt..)))||"&splitchar("||trim(left(pporresu))||')';
        else pppar_temp=trim(left( put(pppar, &fmt..)));
      run;
      
    %end;  /* End: if RC is 1 then the format is available  */ 
    %else
    %do;  

      /*
      / RC is 0. $PKPFMT format is not available 
      / Use pppar and  pporresu to create a new variable
      / with PPPAR and its Units                                 
      /------------------------------------------------------------------------------*/             
    
       data &l_prefix.pkpfmt  (rename=(pppar_temp=pppar) drop=pppar);
          length pppar_temp $&l_vlen ;             
          set &currentdataset;
          if not missing(pporresu) then pppar_temp=trim(left(pppar))||"&splitchar("||trim(left(pporresu))||')';
          else pppar_temp=trim(left(pppar));
       run;
       
       %put %str(RTN)OTE: &sysmacroname: Format $PKPFMT not found. The values of PPPAR were used in the report labels.;
    
    %end;  /* End: RC is 0, the format is not available  */ 

   /*
   / Now use the dataset with the updated version of pppar
   / which contains the PK parameter plus its Units
   /------------------------------------------------------------------------------*/             
            
   %let currentdataset=&l_prefix.pkpfmt;     
  
   /*
   / Call %tu_denorm to convert PK results to columns   
   /------------------------------------------------------------------------------*/
   
   %tu_denorm(
      ACROSSCOLVARPREFIX =&ACROSSCOLVARPREFIX ,
      ACROSSVAR          =&ACROSSVAR          ,
      ACROSSVARLABEL     =&ACROSSVARLABEL     ,
      ACROSSVARLISTNAME  =&ACROSSCOLLISTNAME  ,
      DSETIN             =&CURRENTDATASET     ,
      DSETOUT            =&L_PREFIX.DENORM    ,
      GROUPBYVARS        =&GROUPBYVARSDENORM  ,
      VARSTODENORM       =&VARSTODENORM       
      );
      
   %let currentdataset=&L_PREFIX.DENORM;   

   /*
   / Call %tu_align to align columns   
   /-----------------------------------------------------------------------------*/
   
   %if %nrbquote(&alignyn) eq Y %then %do;                   
      %tu_align(
         DSETIN        =&CURRENTDATASET,
         VARSIN        =&ACROSSCOLVARPREFIX.:,
         ALIGNMENT     =R,
         COMPRESSCHRYN =Y,
         DP            =.,
         DSETOUT       =&l_prefix.aligndsetin,
         NCSPACES      =1,
         VARSOUT       =
         );
            
      %let currentdataset=&l_prefix.aligndsetin;                                          
   %end;
   
   %if ( %nrbquote(&acrosscollistname) NE ) and
      %sysfunc(indexw(%qupcase(&columns), %nrstr(&)%qupcase(&acrosscollistname))) GT 0 %then %do;         
      %let columns=%unquote(&columns);    
   %end;
     
   /*
   / Call %tu_list to create final listing   
   /-----------------------------------------------------------------------------*/

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
       dsetin                 =&currentdataset         ,
       flowvars               =&flowvars               ,
       formats                =&formats                ,
       getdatayn              =N                       ,
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
       stackvar10             =&stackvar10             ,
       stackvar11             =&stackvar11             ,
       stackvar12             =&stackvar12             ,
       stackvar13             =&stackvar13             ,
       stackvar14             =&stackvar14             ,
       stackvar15             =&stackvar15             ,
       stackvar2              =&stackvar2              ,
       stackvar3              =&stackvar3              ,
       stackvar4              =&stackvar4              ,
       stackvar5              =&stackvar5              ,
       stackvar6              =&stackvar6              ,
       stackvar7              =&stackvar7              ,
       stackvar8              =&stackvar8              ,
       stackvar9              =&stackvar9              ,
       varlabelstyle          =&varlabelstyle          ,
       varspacing             =&varspacing             ,
       widths                 =&widths                 
       );
       
   /*
   / Call %tu_tidyup to clean up the temporary data set.  
   /---------------------------------------------------------------------------*/
   
   %tu_tidyup(
      rmdset =&l_prefix:,
      glbmac =NONE
      );


%mend td_pkpl1p;

