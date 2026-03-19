/***************************************************************************************************
| Macro Name       : td_pkct1p.sas
|                 
| Macro Version    : 1
|                 
| SAS version      : SAS v8.2
|                 
| Created By       : Trevor Welby
|                 
| Date             : 14th December 2004
|                 
| Macro Purpose    : This unit shall create a table of Summary Statistics of Pharmacokinetic 
|                    Concentration-Time Data [units] as defined in IDSL standard data displays 
|                    identified in the IDSL Data Display Standards. (Parallel Group Study)
| 
| Macro Design     : Procedure style
|                 
| Input Parameters :
|
| NAME              DESCRIPTION                                                DEFAULT
|--------------------------------------------------------------------------------------------------- 
|
| ANALYSISVARDPS    Passed as %tu_sumstatsincol's parameter of the same name   (blank) (Opt)
|
| ANALYSISVARS      Passed as %tu_sumstatsincol's parameter of the same name   pcstimpn (Req)
|                                                                                                  
| BREAK1-5          Passed as %tu_sumstatsincol's parameter of the same name   (blank) (Opt)
|
| BYVARS            Passed as %tu_sumstatsincol's parameter of the same name   (blank) (Opt)
|
| CENTREVARS        Passed as %tu_sumstatsincol's parameter of the same name   (blank) (Opt)
|
| COLSPACING        Passed as %tu_sumstatsincol's parameter of the same name   2 (Opt)
|
| COLUMNS           Passed as %tu_sumstatsincol's parameter of the same name   &g_trtcd &g_trtgrp 
|                                                                              tt_bnnm visitnum visit 
|                                                                              ptmnum ptm n no_imputed 
|                                                                              mean std median min max (Req)
|                                                                               
| COMPUTEBEFOREPA   Passed as %tu_sumstatsincol's parameter of the same name   (blank) (Opt)
| GELINES           
|
| COMPUTEBEFOREPA   Passed as %tu_sumstatsincol's parameter of the same name   (blank) (Opt)
| EVARS              
|
| COUNTDISTINCTWH   Passed as %tu_sumstatsincol's parameter of the same name   &g_centid &g_subjid (Req)
| ATVARPOP         
|
| DDDATASETLABEL    Passed as %tu_sumstatsincol's parameter of the same name   DD dataset for      
|                                                                              PKCT1P table (Req)
|
| DEFAULTWIDTHS     Passed as %tu_sumstatsincol's parameter of the same name   (blank) (Opt)
| 
| DESCENDING        Passed as %tu_sumstatsincol's parameter of the same name   (blank) (Opt)
|
| DSETIN            Passed as %tu_sumstatsincol's parameter of the same name   ardata.pkcnc (Req)
|
| FLOWVARS          Passed as %tu_sumstatsincol's parameter of the same name   (blank) (Opt)
|
| FORMATS           Passed as %tu_sumstatsincol's parameter of the same name   (blank) (Opt)
|
| GROUPBYVARPOP     Passed as %tu_sumstatsincol's parameter of the same name   &g_trtcd (Req)
| 
| GROUPBYVARSANALY  Passed as %tu_sumstatsincol's parameter of the same name   &g_trtcd &g_trtgrp visitnum visit
|                                                                               ptmnum ptm no_imputed (Req)

| IDVARS            Passed as %tu_sumstatsincol's parameter of the same name   &g_trtcd &g_trtgrp
|                                                                              tt_bnnm visitnum visit ptmnum ptm (Req)
|
| LABELS            Passed as %tu_sumstatsincol's parameter of the same name   no_imputed="No. ~Imputed" (Req)
|
| LEFTVARS          Passed as %tu_sumstatsincol's parameter of the same name   (blank) (Opt)
|
| LINEVARS          Passed as %tu_sumstatsincol's parameter of the same name   (blank) (Opt)
|
| NIMPUTEVARS       Specifies the levels of classification for calculating     &g_trtcd visitnum ptmnum (Req)
|                   the number of imputed values
|
| NOPRINTVARS       Passed as %tu_sumstatsincol's parameter of the same name   &g_trtcd visitnum ptmnum (Req)
|
| NOWIDOWVAR        Passed as %tu_sumstatsincol's parameter of the same name   (blank) (Opt)
|
| ORDERDATA         Passed as %tu_sumstatsincol's parameter of the same name   (blank) (Opt)
|
| ORDERFORMATTED    Passed as %tu_sumstatsincol's parameter of the same name   (blank) (Opt)
|
| ORDERFREQ         Passed as %tu_sumstatsincol's parameter of the same name   (blank) (Opt)
|
| ORDERVARS         Passed as %tu_sumstatsincol's parameter of the same name   &g_trtcd &g_trtgrp 
|                                                                              tt_bnnm visitnum visit ptmnum ptm (Req)
|
| OVERALLSUMMARY    Passed as %tu_sumstatsincol's parameter of the same name   N (Opt)
|
| PAGEVARS          Passed as %tu_sumstatsincol's parameter of the same name   (blank) (Opt)
|
| POSTSUBSET        Passed as %tu_sumstatsincol's parameter of the same name   no_imputed/n gt 0.3 then std=. (Opt)
|
| PROPTIONS         Passed as %tu_sumstatsincol's parameter of the same name   Headline (Opt)
|
| RIGHTVARS         Passed as %tu_sumstatsincol's parameter of the same name   (blank) (Opt)
|
| SHARECOLVARS      Passed as %tu_sumstatsincol's parameter of the same name   (blank) (Opt)
|
| SHARECOLVARSIN    Passed as %tu_sumstatsincol's parameter of the same name   2 (Opt)
| DENT              
|
| SKIPVARS          Passed as %tu_sumstatsincol's parameter of the same name   visitnum (Req)
|
| SPLITCHAR         Passed as %tu_sumstatsincol's parameter of the same name   ~ (Req)
|
| STACKVAR1         Passed as %tu_sumstatsincol's parameter of the same name   (blank) (Opt)
| STACKVAR15        
|
| STATSDPS          Passed as %tu_sumstatsincol's parameter of the same name   MEDIAN +1 MEAN +1 STD +2 (Req)
|
| STATSLIST         Passed as %tu_sumstatsincol's parameter of the same name   N MIN MAX MEDIAN STD
|                                                                              MEAN (Req)
|
| VARLABELSTYLE     Passed as %tu_sumstatsincol's parameter of the same name   SHORT (Req)
|
| VARSPACING        Passed as %tu_sumstatsincol's parameter of the same name   (blank) (Opt)
|
| WIDTHS            Passed as %tu_sumstatsincol's parameter of the same name   &g_trtgrp 15 visit 10
|                                                                              ptm 10 (Req) 
|
|---------------------------------------------------------------------------------------------------
|
|---------------------------------------------------------------------------------------------------
| Output:   1. Output file in plain ASCII text format containing the summary in 
|              a column data display matching the requirements of the  
|              input parameters
|
|           2. SAS data set that forms the foundation of the data display 
|              (the "DD dataset")
|
| Global macro variables created:  None
|
| Macros called : 
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_words
| (@) tu_chkvarsexist
| (@) tu_sumstatsincols
| (@) tu_tidyup
| (@) tu_abort
|
| Example:  %ts_setup;
|           %td_pkct1p;
|    
|---------------------------------------------------------------------------------------------------
| Change Log
|
| Modified By: Trevor Welby
| Date of Modification: 15-Dec-2004
| New version/draft number: 01-002
| Modification ID: TQW9753.01-002
| Reason For Modification: 
|                          Modify the call to %tu_tidyup so that only
|                          temporary datasets are deleted with a prefix of
|                          &PREFIX:
|
|---------------------------------------------------------------------------------------------------
| Change Log
|
| Modified By: Trevor Welby
| Date of Modification: 10-Mar-05
| New version/draft number: 01-003
| Modification ID: TQW9753.01-003
| Reason For Modification: 
|                          Remove the WHERE clause, macro now subsets the input 
|                          dataset (DSETIN) using the global macro variable: G_SUBSET
|
|                          The data display is now entirely produced using a call to
|                          %tu_sumstatsincols
|
|                          Modified to suppress the printing of the Standard Deviation 
|                          when the percentage of imputed values is greater than 30 
|                          percent.  This is now performed using the POSTSUBSET parameter
|
|                          Create a version for parallel group studies
|
|                          Add variable VISIT to the report
|
|                          Create new parameter NIMPUTEVARS, verify that the variables defined by 
|                          NIMPUTVARS exist in DSETIN
|
|                          Change the default of STATSDPS parameter
|
|                          After calculating the imputed number, if missing then this is 
|                          set to zero
|
|---------------------------------------------------------------------------------------------------
| Change Log :
|
| Modified By : Trevor Welby
| Date of Modification : 22-Mar-05
| New Version Number : 01-004
| Modification ID : TQW9753.01-004
| Reason For Modification : 
|                           Remove redundant code relating to 
|                           a local macro variable SC
|
|                           Use alphabetic versions of logical operators
|
|                           Remove DOS EOL characters CTRL-M
|
|---------------------------------------------------------------------------------------------------
| Change Log :
|
| Modified By : Trevor Welby
| Date of Modification : 08-Apr-05
| New Version Number : 01-005
| Modification ID : TQW9753.01-005
| Reason For Modification :
|                          Change the default for STATSDPS parameter to:
|                          median +1 mean +1 std +2 
|
|---------------------------------------------------------------------------------------------------
| Change Log :
|
| Modified By :
| Date of Modification :
| New Version Number :
| Modification ID :
| Reason For Modification :
|
+**************************************************************************************************/

%macro td_pkct1p(
  ANALYSISVARDPS          =,  /* Number of decimal places to which data was captured */
  ANALYSISVARS            =pcstimpn,  /* Summary statistics analysis variables */
  BREAK1                  =,  /* Break statements */
  BREAK2                  =,  /* Break statements */  
  BREAK3                  =,  /* Break statements */  
  BREAK4                  =,  /* Break statements */  
  BREAK5                  =,  /* Break statements */  
  BYVARS                  =,  /* By variables */
  CENTREVARS              =,  /* Centre justify variables */
  COLSPACING              =2, /* Value for between-column spacing */
  COLUMNS                 =&g_trtcd &g_trtgrp tt_bnnm visitnum visit ptmnum ptm n no_imputed mean std median min max,  /* Columns to be included in the listing (plus spanned headers) */
  COMPUTEBEFOREPAGELINES  =,  /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt : labelvar) */  
  COMPUTEBEFOREPAGEVARS   =,  /* Names of variables that define the sort order for Compute Before Page lines */
  COUNTDISTINCTWHATVARPOP =&g_centid &g_subjid,  /* Variables whose distinct values are counted when computing big N */
  DDDATASETLABEL          =DD dataset for PK table,  /* DD dataset for a table Label to be applied to the DD dataset */ 
  DEFAULTWIDTHS           =,  /* List of default column widths */
  DESCENDING              =,  /* Descending ORDERVARS */
  DSETIN                  =ardata.pkcnc,  /* type:ID Name of input analysis dataset */
  FLOWVARS                =,  /* Variables with flow option */
  FORMATS                 =,  /* Format specification (valid SAS syntax) */
  GROUPBYVARPOP           =&g_trtcd,  /* Variables to group by when counting big N */
  GROUPBYVARSANALY        =%nrstr(&g_trtcd &g_trtgrp visitnum visit ptmnum ptm no_imputed),  /* The variables whose values define the subgroup combinations for the analysis */
  IDVARS                  =&g_trtcd &g_trtgrp tt_bnnm visitnum visit ptmnum ptm,  /* Variables to appear on each page of the report */
  LABELS                  =no_imputed="No.~Imputed",  /* Label definitions (var="var label") */
  LEFTVARS                =,  /* Left justify variables */
  LINEVARS                =,  /* Order variables printed with LINE statements */
  NIMPUTEVARS             =&g_trtcd visitnum ptmnum,  /* Class variables used to calculate the number imputed */
  NOPRINTVARS             =&g_trtcd visitnum ptmnum,  /* No print variables, used to order the display */
  NOWIDOWVAR              =,  /* List of variables whose values must be kept together on a page */
  ORDERDATA               =,  /* ORDER=DATA variables */
  ORDERFORMATTED          =,  /* ORDER=FORMATTED variables */
  ORDERFREQ               =,  /* ORDER=FREQ variables */
  ORDERVARS               =&g_trtcd &g_trtgrp tt_bnnm visitnum visit ptmnum ptm ,  /* Order variables */
  OVERALLSUMMARY          =n,  /* Overall summary line at top of tables */
  PAGEVARS                =,  /* Variables whose change in value causes the display to continue on a new page */
  POSTSUBSET              =no_imputed/n gt 0.3 then std=.,  /* SAS "IF" condition that applies to the presentation dataset */
  PROPTIONS               =Headline,  /* PROC REPORT statement options */
  RIGHTVARS               =,  /* Right justify variables */
  SHARECOLVARS            =,  /* Order variables that share print space */
  SHARECOLVARSINDENT      =2,  /* Indentation factor */
  SKIPVARS                =visitnum,  /* Variables whose change in value causes the display to skip a line */
  SPLITCHAR               =~,  /* Split character */
  STACKVAR1               =,  /* Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~)) */
  STACKVAR2               =,  /* Create stacked variables */
  STACKVAR3               =,  /* Create stacked variables */
  STACKVAR4               =,  /* Create stacked variables */
  STACKVAR5               =,  /* Create stacked variables */
  STACKVAR6               =,  /* Create stacked variables */
  STACKVAR7               =,  /* Create stacked variables */
  STACKVAR8               =,  /* Create stacked variables */
  STACKVAR9               =,  /* Create stacked variables */
  STACKVAR10              =,  /* Create stacked variables */
  STACKVAR11              =,  /* Create stacked variables */
  STACKVAR12              =,  /* Create stacked variables */
  STACKVAR13              =,  /* Create stacked variables */
  STACKVAR14              =,  /* Create stacked variables */
  STACKVAR15              =,  /* Create stacked variables */
  STATSDPS                =median +1 mean +1 std +2,  /* Number of decimal places of summary statistical results */
  STATSLIST               =n min max median std mean,  /* List of required summary statistics, e.g. N Mean Median. (or N=number MIN=minimum) */
  VARLABELSTYLE           =short, /* Specifies the label style for variables */
  VARSPACING              =,  /* Column spacing for individual variables */
  WIDTHS                  =&g_trtgrp 15 visit 10 ptm 10  /* Column widths */
  );         

  /* Echo values of parameters and global macro variables to the log */
  %local MacroVersion;
  %let MacroVersion = 1; 
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(); 

  /* unquote GROUPBYVARSANALY so that the variable sc can be resolved */
  %let GROUPBYVARSANALY=%unquote(&GROUPBYVARSANALY);

  /* Perform parameter validation */

  /* Verify the following required macro parameters are not missing */
 
  %local vars var k;

  %let vars=ANALYSISVARS COLUMNS COUNTDISTINCTWHATVARPOP DDDATASETLABEL DSETIN GROUPBYVARPOP GROUPBYVARSANALY IDVARS LABELS NIMPUTEVARS NOPRINTVARS ORDERVARS SKIPVARS SPLITCHAR STATSDPS STATSLIST VARLABELSTYLE WIDTHS;

  %let var=;

  %do k=1 %to %tu_words(&vars.);  /* Begin of k indexed loop */
    %let var=%scan(&vars,&k,%str( ));  /* Strip the kth word */
    %if %nrbquote(&&&var) eq %then
    %do;  /* Issue Message */
      %put %str(RTE)RROR: &sysmacroname: Macro Parameter %upcase(&var.) is missing;
      %let g_abort=1;
    %end;  /* Issue Message */
  %end;  /* End of k indexed loop */

  /* Verify that the dataset DSETIN exists */
  %if %length(&dsetin) eq 0 or not %sysfunc(exist(&dsetin)) %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: Macro Parameter DSETIN (dsetin=&dsetin) dataset does not exist;
    %let g_abort=1;
  %end;

  /*
  / Verify NIMPUTEVARS exist on the DSETIN dataset
  /------------------------------------------------------------------------------*/
  %local nonexistvars;
  %let nonexistvars=%tu_chkvarsexist(&dsetin,&nimputevars.);

  %if %length(&nonexistvars) %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: Macro Parameter NIMPUTEVARS (nimputevars=&nimputevars) one or more variables do not exist in &dsetin;
    %put RTE%str(RROR): &sysmacroname.: The non-existant variable(s) are: &nonexistvars;
    %let g_abort=1;
  %end;

  %tu_abort;

  /* Perform Normal Processing */


  /* Define PREFIX for the naming of temporary work datasets */    
  %local prefix;
  %let prefix=_pkct1p;

  /*
  / Calculate the number of imputed values for each level of treatment 
  / and planned relative time
  /------------------------------------------------------------------------------*/
  proc summary data=&dsetin (where=(pcresimp eq 'Y')) 
               nway 
               missing 
               completetypes
               ;
    class &nimputevars.;
    output out=work.&prefix.01 (rename=(_freq_=no_imputed));
  run;

  proc sort data=work.&prefix.01 (keep=&nimputevars. no_imputed) 
            out =work.&prefix.02;
    by &nimputevars.;
  run;

  proc sort data=&dsetin out=work.&prefix.03; 
    by &nimputevars.;
  run;

  /* Merge the number of imputed values back onto the PK Concentations dataset */
  data work.&prefix.04;
    merge work.&prefix.03 work.&prefix.02;
    by &nimputevars.;
    if (no_imputed eq .) then no_imputed=0;
  run;

  /* Call %tu_sumstatsincols to analyse and report data */
  %tu_sumstatsincols(ANALYSISVARDPS          =&ANALYSISVARDPS,
                     ANALYSISVARS            =&ANALYSISVARS,
                     BREAK1                  =&BREAK1,
                     BREAK2                  =&BREAK2,
                     BREAK3                  =&BREAK3,
                     BREAK4                  =&BREAK4,
                     BREAK5                  =&BREAK5,
                     BYVARS                  =&BYVARS,
                     CENTREVARS              =&CENTREVARS,
                     COLSPACING              =&COLSPACING,
                     COLUMNS                 =&COLUMNS,
                     COMPUTEBEFOREPAGELINES  =&COMPUTEBEFOREPAGELINES,
                     COMPUTEBEFOREPAGEVARS   =&COMPUTEBEFOREPAGEVARS,
                     COUNTDISTINCTWHATVARPOP =&COUNTDISTINCTWHATVARPOP,
                     DDDATASETLABEL          =&DDDATASETLABEL,
                     DEFAULTWIDTHS           =&DEFAULTWIDTHS,
                     DESCENDING              =&DESCENDING,
                     DSETIN                  =work.&prefix.04,
                     FLOWVARS                =&FLOWVARS,
                     FORMATS                 =&FORMATS,
                     GROUPBYVARPOP           =&GROUPBYVARPOP,
                     GROUPBYVARSANALY        =&GROUPBYVARSANALY,
                     IDVARS                  =&IDVARS,
                     LABELS                  =&LABELS,
                     LEFTVARS                =&LEFTVARS,
                     LINEVARS                =&LINEVARS,
                     NOPRINTVARS             =&NOPRINTVARS,
                     NOWIDOWVAR              =&NOWIDOWVAR,
                     ORDERDATA               =&ORDERDATA,
                     ORDERFORMATTED          =&ORDERFORMATTED,
                     ORDERFREQ               =&ORDERFREQ,
                     ORDERVARS               =&ORDERVARS,
                     OVERALLSUMMARY          =&OVERALLSUMMARY,
                     PAGEVARS                =&PAGEVARS,
                     POSTSUBSET              =&POSTSUBSET,
                     PROPTIONS               =&PROPTIONS,
                     RIGHTVARS               =&RIGHTVARS,
                     SHARECOLVARS            =&SHARECOLVARS,
                     SHARECOLVARSINDENT      =&SHARECOLVARSINDENT,
                     SKIPVARS                =&SKIPVARS,
                     SPLITCHAR               =&SPLITCHAR,
                     STACKVAR1               =&STACKVAR1,
                     STACKVAR2               =&STACKVAR2,
                     STACKVAR3               =&STACKVAR3,
                     STACKVAR4               =&STACKVAR4,
                     STACKVAR5               =&STACKVAR5,
                     STACKVAR6               =&STACKVAR6,
                     STACKVAR7               =&STACKVAR7,
                     STACKVAR8               =&STACKVAR8,
                     STACKVAR9               =&STACKVAR9,
                     STACKVAR10              =&STACKVAR10,
                     STACKVAR11              =&STACKVAR11,
                     STACKVAR12              =&STACKVAR12,
                     STACKVAR13              =&STACKVAR13,
                     STACKVAR14              =&STACKVAR14,
                     STACKVAR15              =&STACKVAR15,
                     STATSDPS                =&STATSDPS,
                     STATSLIST               =&STATSLIST,
                     VARLABELSTYLE           =&VARLABELSTYLE,
                     VARSPACING              =&VARSPACING,
                     WIDTHS                  =&WIDTHS,
                     ALIGNYN                 =Y,  
                     ANALYSISVARNAME         =TT_AVNM, 
                     DISPLAY                 =Y, 
                     LABELVARSYN             =Y,
                     ANALYSISVARORDERVARNAME =TT_AVID,
                     BIGNVARNAME             =TT_BNNM,
                     PSBYVARS                =,
                     PSCLASS                 =,
                     PSCLASSOPTIONS          =,
                     PSFORMAT                =,
                     PSFREQ                  =,
                     PSOPTIONS               =MISSING NWAY,
                     PSOUTPUT                =,
                     PSOUTPUTOPTIONS         =NOINHERIT,
                     PSID                    =,
                     PSTYPES                 =,
                     PSWAYS                  =,
                     PSWEIGHT                =,
                     XMLINFMT                =,
                     XMLMERGEVAR             =
                     );

  /* Tidyup the session */  

  %tu_tidyup(rmdset=&prefix.:
            ,glbmac=NONE
            );
  quit;

  %tu_abort;

%mend td_pkct1p;
