/*--------------------------------------------------------------------------------------------------
| Macro Name       : td_pkpt2p
|
| Macro Version    : 01-003
|
| SAS version      : SAS v8
|
| Created By       : David Sankey / Greg Weber
|
| Date             : 01-June-05
|
| Macro Purpose    : This macro shall create the Summary Statistics of Derived Pharmacokinetic Parameters
|                    Table (PKPT2P) as defined in the ISDL Standard Data Displays document.
|                    This macro is designed to report data from Parallel studies.
|                    This macro passes parameters directly to %tu_sumstatsinrows to generate the table listing.
|
| Macro Design     : Procedure Style Macro
|
| Input Parameters :
|
|----------------------------------------------------------------------------------------------------
| ACROSSVAR                Passed as %tu_sumstatsinrows parameter of the same name.  &g_trtcd (Req)
|
| ACROSSVARDECODE          Passed as %tu_sumstatsinrows parameter of the same name.  &g_trtgrp  (Req)
|
| ADDBIGNYN                Passed as %tu_sumstatsinrows parameter of the same name.  N (Req)
|
| ALIGNYN                  Passed as %tu_sumstatsinrows parameter of the same name.  Y (Req)
|
| ANALYSISVARDPS           Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| ANALYSISVARNAME          Passed as %tu_sumstatsinrows parameter of the same name.  tt_avnm (Req)
|
| ANALYSISVARORDERVARNAME  Passed as %tu_sumstatsinrows parameter of the same name.  tt_avid (Req)
|
| ANALYSISVARS             Passed as %tu_sumstatsinrows parameter of the same name.  pporresn (Req)
|
| BIGNINROWYN              Passed as %tu_sumstatsinrows parameter of the same name.  Y (Req)
|
| BIGNVARNAME              Passed as %tu_sumstatsinrows parameter of the same name.  tt_bnnm (Req)
|
| BREAK1                   Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| BREAK2                   Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| BREAK3                   Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| BREAK4                   Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| BREAK5                   Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| BYVARS                   Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| CENTREVARS               Passed as %tu_sumstatsinrows parameter of the same name.  visit (Req)
|
| CODEDECODEVARPAIRS       Passed as %tu_sumstatsinrows parameter of the same name.  &g_trtcd &g_trtgrp visitnum visit (Req)
|
| COLSPACING               Passed as %tu_sumstatsinrows parameter of the same name.  2 (Req)
|
| COLUMNS                  Passed as %tu_sumstatsinrows parameter of the same name.  pppar visitnum visit tt_svid tt_svnm tt_p:
|
| COMPUTEBEFOREPAGELINES   Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| COMPUTEBEFOREPAGEVARS    Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| COUNTDISTINCTWHATVARPOP  Passed as %tu_sumstatsinrows parameter of the same name.  &g_centid &g_subjid (Req)
|
| COMPLETETYPESVARS        Passed as %tu_sumstatsinrows parameter of the same name.  &g_trtcd &g_trtgrp  (Req)
|
| DDDATASETLABEL           Passed as %tu_sumstatsinrows parameter of the same name.  DD Dataset for Table PKPT2P (Req)
|
| DEFAULTWIDTHS            Passed as %tu_sumstatsinrows parameter of the same name.  pppar 12 tt_svnm 10 visit 15 tt_p: 20
|
| DENORMYN                 Passed as %tu_sumstatsinrows parameter of the same name.  Y (Req)
|
| DESCENDING               Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| DISPLAY                  Passed as %tu_sumstatsinrows parameter of the same name.  Y (Req)
|
| DSETIN                   Passed as %tu_sumstatsinrows parameter of the same name.  ardata.pkpar (Req)
|
| DSETOUT                  Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| FLOWVARS                 Passed as %tu_sumstatsinrows parameter of the same name.  _ALL_ (Req)
|
| FORMATS                  Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| GROUPBYVARPOP            Passed as %tu_sumstatsinrows parameter of the same name.  &g_trtcd (Req)
|
| GROUPBYVARSANALY         Passed as %tu_sumstatsinrows parameter of the same name.  pppar &g_trtcd &g_trtgrp visitnum visit (Req)
|
| IDVARS                   Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| LABELS                   Passed as %tu_sumstatsinrows parameter of the same name.  pppar='Parameter'
|
| LABELVARSYN              Passed as %tu_sumstatsinrows parameter of the same name.   Y (Req)
|
| LEFTVARS                 Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| LINEVARS                 Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| NOPRINTVARS              Passed as %tu_sumstatsinrows parameter of the same name.  tt_svid visitnum (Req)
|
| NOWIDOWVAR               Passed as %tu_sumstatsinrows parameter of the same name.  visit (Opt)
|
| ORDERDATA                Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| ORDERFORMATTED           Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| ORDERFREQ                Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| ORDERVARS                Passed as %tu_sumstatsinrows parameter of the same name.  pppar tt_svid tt_svnm
|                                                                                    visitnum visit (Req)
|
| OVERALLSUMMARY           Passed as %tu_sumstatsinrows parameter of the same name.  N  (Req)
|
| PAGEVARS                 Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| POSTSUBSET               Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| PROPTIONS                Passed as %tu_sumstatsinrows parameter of the same name.  headline (Req)
|
| PSBYVARS                 Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| PSCLASS                  Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| PSCLASSOPTIONS           Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| PSFORMAT                 Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| PSFREQ                   Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| PSID                     Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| PSOPTIONS                Passed as %tu_sumstatsinrows parameter of the same name.  MISSING NWAY ALPHA=.05 (Req)
|
| PSOUTPUT                 Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| PSOUTPUTOPTIONS          Passed as %tu_sumstatsinrows parameter of the same name.  NOINHERIT (Req)
|
| PSTYPES                  Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| PSWAYS                   Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| PSWEIGHT                 Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| RIGHTVARS                Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| SHARECOLVARS             Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| SHARECOLVARSINDENT       Passed as %tu_sumstatsinrows parameter of the same name.  2 (Req)
|
| SKIPVARS                 Passed as %tu_sumstatsinrows parameter of the same name.  pppar visitnum (Req)
|
| SPLITCHAR                Passed as %tu_sumstatsinrows parameter of the same name.  ~   (Req)
|
| STACKVAR1                Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| STACKVAR2                Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| STACKVAR3                Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| STACKVAR4                Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| STACKVAR5                Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| STACKVAR6                Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| STACKVAR7                Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| STACKVAR8                Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| STACKVAR9                Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| STACKVAR10               Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| STACKVAR11               Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| STACKVAR12               Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| STACKVAR13               Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| STACKVAR14               Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| STACKVAR15               Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| STATSDPS                 Passed as %tu_sumstatsinrows parameter of the same name.  meanclm +1 geomeanclm +1 std +2 median +1   (Req)
|
| STATSINROWSYN            Passed as %tu_sumstatsinrows parameter of the same name.  Y (Req)
|
| STATSLABELS              Passed as %tu_sumstatsinrows parameter of the same name.  %nrstr(meanclm="Arith. Mean~  95% CI"geomeanclm="Geom. Mean~  95% CI" ) (Req)
|
| STATSLIST                Passed as %tu_sumstatsinrows parameter of the same name.  n meanclm geomeanclm std median
|                                                                                     min max  (Req)
|
| STATSLISTVARNAME         Passed as %tu_sumstatsinrows parameter of the same name.  tt_svnm (Req)
|
| STATSLISTVARORDERVARNAME Passed as %tu_sumstatsinrows parameter of the same name.  tt_svid (Req)
|
| TOTALDECODE              Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| TOTALFORVAR              Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| TOTALID                  Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| VARLABELSTYLE            Passed as %tu_sumstatsinrows parameter of the same name.  SHORT (Req)
|
| VARSPACING               Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| WIDTHS                   Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| XMLINFMT                 Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
| XMLMERGEVAR              Passed as %tu_sumstatsinrows parameter of the same name.  (blank) (Opt)
|
|---------------------------------------------------------------------------------------------------
|
| Output:   1. an output file in plain ASCII text format containing a summary in columns data
|              display matching the requirements specified as input parameters.
|           2. SAS data set that forms the foundation of the data display (the "DD dataset").
|
|
| Global macro variables created:  None
|
| Macros called :
|
| (@) tr_putlocals
| (@) tu_getdata
| (@) tu_nobs 
| (@) tu_putglobals
| (@) tu_sumstatsinrows
| (@) tu_tidyup
| (@) tu_valparms
|
| Example:
|
|    %td_pkpt2p;
|
|---------------------------------------------------------------------------------------------------
|
| Change Log :
|
| Modified By :              I. D. Sankey
| Date of Modification :     05-Aug-05
| New Version Number :       01-002
| Modification ID :          DIS.01.002
| Reason For Modification :  DIS.01.002.a: Modifications to SC Header
|                            DIS.01.002.b: Add calls %tu_getdata and %tu_nobs
|                                          to allow subsetting
|
| Modified By :              Greg Weber
| Date of Modification :     06-Aug-05
| New Version Number :       01-003
| Modification ID :          GTW.01.003
| Reason For Modification :  GTW.01.003.a: Add support for use of XML file to set decimal
|                                          precision
|
| Modified By :
| Date of Modification :
| New Version Number :
| Modification ID :
| Reason For Modification :
|
/-------------------------------------------------------------------------------------------------*/

%MACRO td_pkpt2p(
   ACROSSVAR                =&g_trtcd,             /* Variable that will be transposed to columns*/
   ACROSSVARDECODE          =&g_trtgrp,            /* The name of a decode variable for ACROSSVAR, or the name of a format*/
   ADDBIGNYN                =N,                    /* Control whether big N will be added to the values of ACROSSVAR*/
   ALIGNYN                  =Y,                    /* Control execution of %tu_align*/
   ANALYSISVARDPS           =,                     /* Number of decimal places  to which data was captured*/
   ANALYSISVARNAME          =tt_avnm,              /* Variable name that saves analysis variable labels or names in DSETOUT*/
   ANALYSISVARORDERVARNAME  =tt_avid,              /* Variable name that saves analysis variable order in DSETOUT*/
   ANALYSISVARS             =pporresn,             /* Summary statistics analysis variables*/
   BIGNINROWYN              =Y,                    /* If bigN should be displayed in rows, other than in column Label */
   BIGNVARNAME              =tt_bnnm,               /* Variable name that saves big N values in the DD dataset*/
   BREAK1                   =,                     /* Break statements. */
   BREAK2                   =,                     /* Break statements. */
   BREAK3                   =,                     /* Break statements. */
   BREAK4                   =,                     /* Break statements. */
   BREAK5                   =,                     /* Break statements. */
   BYVARS                   =,                     /* By variables */
   CENTREVARS               =visit,                     /* Centre justify variables */
   CODEDECODEVARPAIRS       =&g_trtcd &g_trtgrp visitnum visit,/* Code and Decode variables in pairs*/
   COLSPACING               =2,                    /* Overall spacing value. */
   COLUMNS                  =pppar visitnum visit tt_svid tt_svnm tt_p:,/* Column parameter */
   COMPUTEBEFOREPAGELINES   =,                     /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt colon labelvar) */
   COMPUTEBEFOREPAGEVARS    =,                     /* Names of variables that shall define the sort order for Compute Before Page lines */
   COUNTDISTINCTWHATVARPOP  =&g_centid &g_subjid,  /* What is being counted when counting big N*/
   COMPLETETYPESVARS        =&g_trtcd &g_trtgrp,   /* Variables which COMPLETETYPES should be applied to */
   DDDATASETLABEL           =DD dataset for PKPT2P, /* Label to be applied to the DD dataset */
   DEFAULTWIDTHS            =pppar 12 tt_svnm 10 visit 15 tt_p: 20, /* List of default column widths */
   DENORMYN                 =Y,                    /* Transpose result variables from rows to columns across the ACROSSVAR ? Y/N?*/
   DESCENDING               =,                     /* Descending ORDERVARS */
   DISPLAY                  =Y,                    /* Specifies whether the report should be created */
   DSETIN                   =ardata.pkpar,         /* type:ID Input analysis dataset*/
   DSETOUT                  =,                     /* Output summary dataset*/
   FLOWVARS                 =_ALL_,                /* Variables with flow option */
   FORMATS                  =,                     /* Format specification */
   GROUPBYVARPOP            =&g_trtcd,             /* Variables to group by when counting big N */
   GROUPBYVARSANALY         =pppar &g_trtcd &g_trtgrp visitnum visit, /* The variables whose values define the subgroup combinations for the analysis */
   IDVARS                   =,                     /* ID variables */
   LABELS                   =pppar="Parameter",    /* Label definitions. */
   LABELVARSYN              =Y,                    /* Control execution of %tu_labelvars*/
   LEFTVARS                 =,                     /* Left justify variables */
   LINEVARS                 =,                     /* Order variable printed with line statements. */
   NOPRINTVARS              =tt_svid visitnum,     /* No print vars (usually used to order the display) */
   NOWIDOWVAR               =visit,                /* Not in version 1 */
   ORDERDATA                =,                     /* ORDER=DATA variables */
   ORDERFORMATTED           =,                     /* ORDER=FORMATTED variables */
   ORDERFREQ                =,                     /* ORDER=FREQ variables */
   ORDERVARS                =pppar tt_svid tt_svnm visitnum visit, /* Order variables */
   OVERALLSUMMARY           =N,                    /* Overall summary line at top of tables */
   PAGEVARS                 =,                     /* Break after <var> / page */
   POSTSUBSET               =,                     /* SAS "IF" condition that applies to the presentation dataset.   */
   PROPTIONS                =headline,             /* PROC REPORT statement options */
   PSBYVARS                 =,                     /* Advanced Usage: Passed to the PROC SUMMARY by statement. This will cause the data to be sorted first.  */
   PSCLASS                  =,                     /* Advanced usage: Passed to the PROC SUMMARY class Statement */
   PSCLASSOPTIONS           =,                     /* PROC SUMMARY class statement options                   */
   PSFORMAT                 =,                     /* Passed to the PROC SUMMARY format statement.           */
   PSFREQ                   =,                     /* Advanced usage: Passed to the PROC SUMMARY freq Statement  */
   PSID                     =,                     /* Advanced usage: Passed to the PROC SUMMARY id Statement  */
   PSOPTIONS                =MISSING NWAY ALPHA=.05, /* PROC SUMMARY statement options to use           */
   PSOUTPUT                 =,                     /* Advanced usage: Passed to the PROC SUMMARY output statement */
   PSOUTPUTOPTIONS          =NOINHERIT,            /* Advanced usage: Passed to the PROC SUMMARY Output options Statement part. */
   PSTYPES                  =,                     /* Advanced Usage: Passed to the PROC SUMMARY types statement */
   PSWAYS                   =,                     /* Advanced Usage: Passed to the PROC SUMMARY ways statment.  */
   PSWEIGHT                 =,                     /* Advanced Usage: Passed to the PROC SUMMARY weight statement. */
   RIGHTVARS                =,                     /* Right justify variables */
   SHARECOLVARS             =,                     /* Order variables that share print space. */
   SHARECOLVARSINDENT       =2,                    /* Indentation factor */
   SKIPVARS                 =pppar visitnum,       /* Break after <var> / skip */
   SPLITCHAR                =~,                    /* Split character*/
   STACKVAR1                =,                     /* Create Stacked variables  */
   STACKVAR2                =,                     /* Create Stacked variables  */
   STACKVAR3                =,                     /* Create Stacked variables  */
   STACKVAR4                =,                     /* Create Stacked variables  */
   STACKVAR5                =,                     /* Create Stacked variables  */
   STACKVAR6                =,                     /* Create Stacked variables  */
   STACKVAR7                =,                     /* Create Stacked variables  */
   STACKVAR8                =,                     /* Create Stacked variables  */
   STACKVAR9                =,                     /* Create Stacked variables  */
   STACKVAR10               =,                     /* Create Stacked variables  */
   STACKVAR11               =,                     /* Create Stacked variables  */
   STACKVAR12               =,                     /* Create Stacked variables  */
   STACKVAR13               =,                     /* Create Stacked variables  */
   STACKVAR14               =,                     /* Create Stacked variables  */
   STACKVAR15               =,                     /* Create Stacked variables  */
   STATSDPS                 =meanclm +1 geomeanclm +1 std +2 median +1, /* Decimal precision for summary stats */
   STATSINROWSYN            =Y,                    /* Should summary statistics be displayed in rows or colums */
   STATSLIST                =n meanclm geomeanclm std median min max, /* List of required summary statistics, e.g. N Mean Median. */
   STATSLISTVARNAME         =tt_svnm,              /* Variable name that saves summary statistic variable names */
   STATSLABELS              =%nrstr(meanclm="Arith. Mean~  95% CI" geomeanclm="Geom. Mean~  95% CI" ), /* Label defination for summary statistical result variables. */
   STATSLISTVARORDERVARNAME =tt_svid,              /* Variable name that saves summary statistic variable order */
   TOTALDECODE              =,                     /* Label for the total result column. */
   TOTALFORVAR              =,                     /* Variable for which a total is required */
   TOTALID                  =,                     /* Value used to populate the variable specified in ACROSSVAR on data that represents the overall total for the ACROSSVAR variable. */
   VARLABELSTYLE            =SHORT,                /* Specifies the label style for variables */
   VARSPACING               =,                     /* Spacing for individual variables. */
   WIDTHS                   =,                     /* Column widths */
   XMLINFMT                 =,                     /* Path and name of XML file to set decimal precision */
   XMLMERGEVAR              =                      /* Variable (e.g. pppar) to merge input data with the XML file */
   );


   /*
   / Echo macro parameters to log
   /------------------------------------------------------------------------------*/

   %local MacroVersion;
   %let MacroVersion = 1;

   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals()

   %local l_prefix l_vlen;
   %let l_prefix=_td_pkpt2p;

   /*
   / Perform parameter validation
   / Macro-variables macroname and pv_abort required by tu_valparms macro.
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
   %let pv_checkvars = PPPAR PPORRESU;

   %tu_valparms(macroname=&macroname,
                chktype=varExists,
                pv_dsetin=dsetin,
                pv_varsin=pv_checkvars,
                abortyn=Y);

   /*
   / Normal Processing begins
   /------------------------------------------------------------------------------*/

   /*
   / Call tu_getdata to subset the CURRENTDATASET  - DIS.01.002.b
   / Use tu_nobs to check dataset
   / if there is a dataset with observations, set g_subset to empty   
   /------------------------------------------------------------------------------*/

   %local currentdataset;
   %let currentdataset=&dsetin;

   %tu_getdata(dsetin=&currentdataset.,
               dsetout1=&l_prefix._analydata,
               dsetout2=
                );

   %let currentdataset=&l_prefix._analydata;

   %if %tu_nobs(&currentdataset.) eq 0 %then 
   %do;
     %put %str(RTE)RROR: &sysmacroname: The dataset DSETIN (dsetin=&dsetin.) has zero observations after subsetting by G_SUBSET (g_subset=&g_subset.) global macro variable;
     %tu_abort(option=force);
   %end;
   %else
   %do;
     %let g_subset=; 
   %end;
   
   %let dsetin=&currentdataset;

   /* End: DIS.01.002.b   */

   /*
   / Combine PPPAR and PPORRESU together.  First calculate required length.
   / and store in l_vlen
   /------------------------------------------------------------------------------*/

   %local l_vlen;

   data _null_;
     length vlen $40;
     set &dsetin;
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

      data &l_prefix.dsetin (rename=(pppar_temp=pppar) drop=pppar);
        length pppar_temp $&l_vlen. ;
        set &dsetin;
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

       data &l_prefix.dsetin  (rename=(pppar_temp=pppar) drop=pppar);
          length pppar_temp $&l_vlen ;
          set &dsetin;
          if not missing(pporresu) then pppar_temp=trim(left(pppar))||"&splitchar("||trim(left(pporresu))||')';
          else pppar_temp=trim(left(pppar));
       run;

       %put %str(RTN)OTE: &sysmacroname: Format $PKPFMT not found. The values of PPPAR were used in the report labels.;

    %end;  /* End: RC is 0, the format is not available  */

   %let dsetin=&l_prefix.dsetin;

   /*
   / GTW.01.003.a
   / Create the XML file that will control the decimal precision only if the STATSDPS
   / parameter is blank and there is no existing XML file.
   / 1 - If XML files is specified then use it.  If the XML file already exists,
   /     then just use it.  If it does not exist, then create one and use it.
   / 2 - Get the list of stats.  For the CLM stats it is necessary to add the
   /     underlying keywords.
   / 3 - Get unique values of PPPAR and combine with statslist to create dataset
   /     with all combinations and that is compatible with XMLINFMT
   / 4 - Make final adjustments to formats and output XML file
   /------------------------------------------------------------------------------*/

   %local _idx _xmlfilename _xmlfilenameshort _dirname;
   %let xmlmergevar = %upcase(&xmlmergevar);

   /* 1 - Use XML file if it is specified */
   %if %length(&xmlinfmt) gt 0 %then %do; /* XML file is specified */
      /* If no directory is given, then add ./ so that the file is placed in the current execution directory */
      /* Create several macro variables from XMLINFMT for use in subsequent processing */
      %if %index(&xmlinfmt,/) eq 0 %then %let xmlinfmt = ./&xmlinfmt;
      %let _idx = %index(%sysfunc(reverse(&xmlinfmt)),/) ;
      %let _xmlfilename = %sysfunc(reverse(%substr(%sysfunc(reverse(%trim(%left(&xmlinfmt)))),1,%eval(&_idx-1))));
      %let _xmlfilenameshort = %substr(&_xmlfilename,1,%eval(%index(&_xmlfilename,.) -1 ));
      %let _dirname = %sysfunc(reverse(%substr(%sysfunc(reverse(%trim(%left(&xmlinfmt)))),&_idx)));

      %if not %sysfunc(fileexist(&_dirname)) %then %do;
         %put %str(RTE)RROR: &sysmacroname: The directory (&_dirname) does not exist;
         %tu_abort(option=force);
      %end;

      %if %sysfunc(fileexist(&xmlinfmt)) = 0  %then %do; /* XML file does not exist so create it */

         %put RTN%str(OTE): &sysmacroname: Creating new XML file to set decimal precision;

         /* 2 - Get the list of stats */
         data &l_prefix.statslist;
            length _stat_ $13;
            %if &statslist ne %then %do;
               %let i=1;
               %do %until(%scan(&statslist,&i) eq);
                  _stat_="%scan(&statslist,&i)";
                  output;
                  select (upcase(_stat_));
                     when ("CLM") do;
                       _stat_ = "__LCLM10__";output;
                       _stat_ = "__UCLM10__";output;
                     end;
                     when ("MEANCLM") do;
                       _stat_ = "__MEAN0__";output;
                       _stat_ = "__LCLM0__";output;
                       _stat_ = "__UCLM0__";output;
                     end;
                     when ("CLMLOG") do;
                       _stat_ = "__LCLMLOG10__";output;
                       _stat_ = "__UCLMLOG10__";output;
                     end;
                     when ("GEOMEANCLM") do;
                       _stat_ = "__GEOMEAN0__";output;
                       _stat_ = "__LCLMLOG0__";output;
                       _stat_ = "__UCLMLOG0__";output;
                     end;
                     otherwise;
                  end;
                  %let i=%eval(&i+1);
               %end;
            %end;
         run;

         /* 3 - Get unique values of PPPAR along with the format to be applied */

         /* If its an integer, then add a dot to the end to make sure that the SQL below calculates */
         /* integers as having zero decimal places. */

         data &l_prefix.dsetintemp;
            set &l_prefix.dsetin;
            if index(pporresc,".") eq 0 then pporresc=compress(pporresc||".");
         run;

         proc sql;
            create table &l_prefix.parmdec as
            select "&xmlmergevar" as mergevar, &xmlmergevar as value, _stat_, trim(left(put(max(length(trim(left(pporresc)))-index(trim(left(pporresc)),".")),8.))) as _fmtn_
            from &l_prefix.dsetintemp, &l_prefix.statslist
            group by &xmlmergevar, _stat_;
         quit;

         /* 4 - Do final adjustment to format and output to XML file. */

         libname _xmlout XML "&xmlinfmt";

         data _xmlout.&_xmlfilenameshort (drop=_fmtn_);
           set &l_prefix.parmdec;
           length _fmt_ $3;
           /* Need to delete these records or we get a warning from tu_statsfmt */
           /* They are not needed in the XML file                               */
           if upcase(_stat_) in("CLM","MEANCLM","CLMLOG","GEOMEANCLM") then delete;
           if (_fmtn_ * 1) gt 4 then do;
              _fmtn_ = "4";
               put "%str(RTN)OTE: &sysmacroname: Formats generated may result in truncated data values in the display";
           end;
           if upcase(_stat_) eq "N" then do;
              _fmt_ = "8.";
           end;
           else do;
              if upcase(_stat_) in("STD","STDLOG") then _fmtn_ = _fmtn_ + 2;
              if upcase(_stat_) in("MEAN","MEDIAN","GEOMEAN","__LCLM10__","__UCLM10__","__MEAN0__",
                                   "__LCLM0__","__UCLM0__","__GEOMEAN0__","__LCLMLOG0__","__UCLMLOG0__",
                                   "__LCLMLOG10__","__UCLMLOG10__") then _fmtn_ = _fmtn_ + 1;
              _fmt_ = "8." || trim(left(_fmtn_));
           end;
         run;

         libname _xmlout clear;

      %end;  /* End create XML file since it did not exist */
   %end;  /* End XML file is specified. */


   /*
   / Call %tu_sumstatsinrows to create final display
   /---------------------------------------------------------------------------------*/


   %tu_sumstatsinrows(
      ACROSSCOLLISTNAME        =acrosscollistname_        ,
      ACROSSCOLVARPREFIX       =tt_p                      ,
      ACROSSVAR                =&ACROSSVAR                ,
      ACROSSVARDECODE          =&ACROSSVARDECODE          ,
      ADDBIGNYN                =&ADDBIGNYN                ,
      ALIGNYN                  =&ALIGNYN                  ,
      ANALYSISVARDPS           =&ANALYSISVARDPS           ,
      ANALYSISVARNAME          =&ANALYSISVARNAME          ,
      ANALYSISVARORDERVARNAME  =&ANALYSISVARORDERVARNAME  ,
      ANALYSISVARS             =&ANALYSISVARS             ,
      BIGNINROWYN              =&BIGNINROWYN              ,
      BIGNVARNAME              =&BIGNVARNAME              ,
      BREAK1                   =&BREAK1                   ,
      BREAK2                   =&BREAK2                   ,
      BREAK3                   =&BREAK3                   ,
      BREAK4                   =&BREAK4                   ,
      BREAK5                   =&BREAK5                   ,
      BYVARS                   =&BYVARS                   ,
      CENTREVARS               =&CENTREVARS               ,
      CODEDECODEVARPAIRS       =&CODEDECODEVARPAIRS       ,
      COLSPACING               =&COLSPACING               ,
      COLUMNS                  =&COLUMNS                  ,
      COMPUTEBEFOREPAGELINES   =&COMPUTEBEFOREPAGELINES   ,
      COMPUTEBEFOREPAGEVARS    =&COMPUTEBEFOREPAGEVARS    ,
      COUNTDISTINCTWHATVARPOP  =&COUNTDISTINCTWHATVARPOP  ,
      COMPLETETYPESVARS        =&COMPLETETYPESVARS        ,
      DDDATASETLABEL           =&DDDATASETLABEL           ,
      DEFAULTWIDTHS            =&DEFAULTWIDTHS            ,
      DENORMYN                 =&DENORMYN                 ,
      DESCENDING               =&DESCENDING               ,
      DISPLAY                  =&DISPLAY                  ,
      DSETIN                   =&DSETIN                   ,
      DSETOUT                  =&DSETOUT                  ,
      FLOWVARS                 =&FLOWVARS                 ,
      FORMATS                  =&FORMATS                  ,
      GROUPBYVARPOP            =&GROUPBYVARPOP            ,
      GROUPBYVARSANALY         =&GROUPBYVARSANALY         ,
      IDVARS                   =&IDVARS                   ,
      LABELS                   =&LABELS                   ,
      LABELVARSYN              =&LABELVARSYN              ,
      LEFTVARS                 =&LEFTVARS                 ,
      LINEVARS                 =&LINEVARS                 ,
      NOPRINTVARS              =&NOPRINTVARS              ,
      NOWIDOWVAR               =&NOWIDOWVAR               ,
      ORDERDATA                =&ORDERDATA                ,
      ORDERFORMATTED           =&ORDERFORMATTED           ,
      ORDERFREQ                =&ORDERFREQ                ,
      ORDERVARS                =&ORDERVARS                ,
      OVERALLSUMMARY           =&OVERALLSUMMARY           ,
      PAGEVARS                 =&PAGEVARS                 ,
      POSTSUBSET               =&POSTSUBSET               ,
      PROPTIONS                =&PROPTIONS                ,
      PSBYVARS                 =&PSBYVARS                 ,
      PSCLASS                  =&PSCLASS                  ,
      PSCLASSOPTIONS           =&PSCLASSOPTIONS           ,
      PSFORMAT                 =&PSFORMAT                 ,
      PSFREQ                   =&PSFREQ                   ,
      PSID                     =&PSID                     ,
      PSOPTIONS                =&PSOPTIONS                ,
      PSOUTPUT                 =&PSOUTPUT                 ,
      PSOUTPUTOPTIONS          =&PSOUTPUTOPTIONS          ,
      PSTYPES                  =&PSTYPES                  ,
      PSWAYS                   =&PSWAYS                   ,
      PSWEIGHT                 =&PSWEIGHT                 ,
      RESULTVARNAME            =tt_result                 ,
      RIGHTVARS                =&RIGHTVARS                ,
      SHARECOLVARS             =&SHARECOLVARS             ,
      SHARECOLVARSINDENT       =&SHARECOLVARSINDENT       ,
      SKIPVARS                 =&SKIPVARS                 ,
      SPLITCHAR                =&SPLITCHAR                ,
      STACKVAR1                =&STACKVAR1                ,
      STACKVAR2                =&STACKVAR2                ,
      STACKVAR3                =&STACKVAR3                ,
      STACKVAR4                =&STACKVAR4                ,
      STACKVAR5                =&STACKVAR5                ,
      STACKVAR6                =&STACKVAR6                ,
      STACKVAR7                =&STACKVAR7                ,
      STACKVAR8                =&STACKVAR8                ,
      STACKVAR9                =&STACKVAR9                ,
      STACKVAR10               =&STACKVAR10               ,
      STACKVAR11               =&STACKVAR11               ,
      STACKVAR12               =&STACKVAR12               ,
      STACKVAR13               =&STACKVAR13               ,
      STACKVAR14               =&STACKVAR14               ,
      STACKVAR15               =&STACKVAR15               ,
      STATSDPS                 =&STATSDPS                 ,
      STATSINROWSYN            =&STATSINROWSYN            ,
      STATSLABELS              =&STATSLABELS              ,
      STATSLIST                =&STATSLIST                ,
      STATSLISTVARNAME         =&STATSLISTVARNAME         ,
      STATSLISTVARORDERVARNAME =&STATSLISTVARORDERVARNAME ,
      TOTALDECODE              =&TOTALDECODE              ,
      TOTALFORVAR              =&TOTALFORVAR              ,
      TOTALID                  =&TOTALID                  ,
      VARLABELSTYLE            =&VARLABELSTYLE            ,
      VARSPACING               =&VARSPACING               ,
      WIDTHS                   =&WIDTHS                   ,
      XMLINFMT                 =&XMLINFMT                 ,
      XMLMERGEVAR              =&XMLMERGEVAR
      );


   /*
   / Call tu_tidyup to clear temporary data set and fields.
   /--------------------------------------------------------------------------------*/

   %tu_tidyup(
      RMDSET =&L_PREFIX:,
      GLBMAC =NONE
      );


%MEND td_pkpt2p;


