/*--------------------------------------------------------------------------------------------------
| Macro Name       : tu_sumstatsincols.sas
|                 
| Macro Version    : 2
|                 
| SAS version      : 9.3
|                 
| Created By       : Yongwei Wang (YW62951)
|                 
| Date             : 24-Jul-03
|                 
| Macro Purpose    : This unit shall be a utility to satisfy the summary-table-in-columns 
|                    requirements of IDSL standard data displays identified in the IDSL Data 
|                    Display Standards. To satisfy any individual summary table data display, this 
|                    utility shall be called by a "wrapper" macro that passes the appropriate 
|                    parameter values to this macro. The layout of the report shall consist of the 
|                    standard header and footer combined with an output number, a title, and the 
|                    body of the report. Standard header and footer are described in IDSL 
|                    Statistical Reporting Displays. 
|
|                    Note on creating summaries with the GroupByVarsAnaly parameter:
|                    GroupByVarsAnaly specifies the variables whose values define the subgroup 
|                    combinations for the analysis. The variables can be divided by statements 
|                    inside of '(' and ')' to represent different levels of subgroup. The 
|                    statement(s) between the brackets are used to assign values to the variables 
|                    following the closed bracket so that the output of different levels can be 
|                    combined together. For example, value VARIABLE1 VARIABLE2 (STATEMENTS) 
|                    VARIABLE3 VARIABLE4 means the first level subgroup variables are VARIABLE1 
|                    and VARIABLE2, and the second level of subgroup variables are VARIABLE1, 
|                    VARIABLE2, VARIABLE3 and VARIABLE4. The statements inside the brackets are 
|                    used to assign values to VARIABLE3 and/or VARIABLE4. Summary records will be 
|                    created and populated according to the specification of variable=value pairs 
|                    within brackets. For example, trtcd trtgrp (visitnum=999; visit="All Visits";) 
|                    visitnum visit. %tu_stats will be called for each level of subgroup. The 
|                    subgroup variables for each level will be passed to parameter CLASSVARS of 
|                    %tu_stats (and they will be used as CLASS variables in PROC SUMMARY called by 
|                    %tu_stats).
|
| Macro Design     : PROCEDURE STYLE
|                 
| Input Parameters :
|
| NAME              DESCRIPTION                                                DEFAULT
|---------------------------------------------------------------------------------------------------- 
| ALIGNYN	        Execute tu_align macro: Yes or No                          Y
|                   Valid values: Y, N	
|
| ANALYSISVARORDER  Specifies the name of a variable to be used to save (in    tt_avid
| VARNAME	        the DD dataset) the variable order given by ANALYSISVARS.
|                   The order will be expressed as sequential integers 
|                   Valid values: a valid SAS variable name. DSETIN must not   
|                   contain a variable with this name	
|
| ANALYSISVARNAME	Specifies the name of variable to be used to save (in the  tt_avnm
|                   DD dataset) the variable labels or names given by 
|                   ANALYSISVARS 
|                   Valid values: a valid SAS variable name. DSETIN must not 
|                   contain a variable with this name	
|
| ANALYSISVARS	    The variables to be analysed.                              (Blank)
|                   Valid values: a list of SAS variables that exist in DSETIN 
|
| DSETIN	        Specify an analysis dataset
|                   Valid values: name of an existing dataset meeting an IDSL  (Blank)
|                   dataset specification 	
|
| GROUPBYVARSANALY	Specifies the variables whose values define the subgroup   (Blank)
|                   combinations for the analysis. The variables can be  
|                   divided by statements inside of '(' and ')' to represent 
|                   different levels of subgroup. See Purpose for details.
|                   Valid values: A list of valid SAS variable names with 
|                   (optionally) valid SAS statements in bracket. The first 
|                   and last words in the values must be variable names. The 
|                   variable names must exist in DSETIN. The SAS statements  
|                   must be in the format (variable = value;). Variable must 
|                   also appear after the closed bracket. Value must be the 
|                   same type as variable.	
|
| LABELVARSYN	    Execute tu_labelvars macro : Yes or No                     Y
|                   Valid values: Y, N	
|
| STATSLIST	        Specifies a list of summary statistics to produce. May     (Blank)
|                   also specify correct PROC SUMMARY syntax to rename output 
|                   variable (N=number MEAN=average) 
|                   Valid values: As defined for the STATSLIST parameter of 
|                   %tu_stats	
|
| VARLABELSTYLE	    Specifies the style of labels to be applied by the         SHORT
|                   %tu_labelvars macro
|                   Valid values: as specified by %tu_labelvars	
|
| ANALYSISVARDPS	Specifies the number of decimal places to which data was   (Blank)
|                   captured. If not supplied, the format on the variables in 
|                   DSETIN will be used (if they exist). If different numbers 
|                   of DPs are required for the different ANALYSISVARS, the 
|                   parameter may be a list of: variable name = number of DPs
|                   The decimal places part will be saved in a temporary 
|                   variable and the variable name will be passed to the 
|                   ANALYSISVARDPSVAR parameter of %tu_statsfmt. If XMLINFMT 
|                   is not blank, ANALYSISVARDPS will be ignored. If both 
|                   XMLINFMT and ANALYSISVARDPS are blank, the value of 
|                   parameter ANALYSISVARFORMATDNAME of %tu_stats will be 
|                   passed to ANALYSISVARDPSVAR of %tu_statsfmt 
|                   Valid values: Can be one of following three:
|                   1. Blank
|                   2. Number-of-decimal-places
|                   3. variable1 = Number-of-decimal-places  < variable2 = 
|                      Number-of-decimal-places ?>   
|                      The variable1, variable2, ? must be the variables given 
|                      as ANALYSISVARS	
|
| BIGNVARNAME	    Specifies the name of the variable that saves the big N    tt_bnnm
|                   values in the DD dataset. The variable will be created by 
|                   %tu_sumstatsincols calling %tu_addbignvar macro. If it is 
|                   blank, the big N will not be added to the output 
|                   Valid values: Blank, or any valid SAS variable name that 
|                   does not exist in the input dataset	tt_bnnm
|
| COUNTDISTINCTWHA  A list of variables containing the value of what is being  &g_centid 
| TVARPOP	        counted. Will be passed to COUNTDISTINCTWHATVAR of         &g_subjid
|                   %tu_addbignvar. COUNTDISTINCTWHATVARPOP is required if 
|                   BIGNVARNAME is given
|                   Valid values: Blank or as defined in %tu_addbignvar	
|
| GROUPBYVARPOP	    Specifies a list of variables to group by when counting    %tu_getdata	
|                   big N using %tu_addbignvar. Usually one variable &g_trtcd. &g_trtcd
|                   It will be passed to GROUPBYVARS of %tu_addbignvar. It is 
|                   required if BIGNVARNAME is given 
|                   Valid values: Blank, or a list of valid SAS variable names 
|                   that exist in population dataset created by 
|                   %tu_sumstatsincols' calling 
|
| POSTSUBSET	    Specifies a SAS IF condition (without "IF" in it), which   (Blank)
|                   will be applied to the dataset immediately prior to 
|                   creation of the DD dataset.
|                   Valid values: Blank, or a valid SAS statement that can be 
|                   applied to the dataset prior to creation of the DD dataset.
|
| STATSDPS	        Specifies decimal places of statistical results of         (blank)
|                   analysi variables. If the decimal positions for all  
|                   variables given by ANALYSISVARS are the same, it should be  
|                   a list of summary statistic variable name, '+' and an  
|                   integer number. For example, Mean +1 STD +2. The integer  
|                   number means number of decimal places. If any statistic  
|                   variable in STATSLIST is not in STATSDPS, the variable  
|                   name and +0 will be automatically added to STATSDPS. If  
|                   the decimal positions for all variables are not the same,  
|                   it should be a list of: analysis-var=list-described-above  
|                   For example, heart=Mean +1 STD +2 resp=Mean +2 STD +2. The 
|                   decimal places without the variable name and equals-sign 
|                   will be passed to %tu_statsfmt.
|                   Valid values: Can be one of following three:
|                   1. Blank
|                   2. Statsdps
|                   3. Variable1 = statsdps  < variable2 = statdps ?>
|                   The variable1, variable2, ? should be the variables 
|                   specified for ANALYSISVARS. Statdps is the same as 
|                   STATSDPS parameter defined in %tu_statsfmt	(blank)
|
| XMLINFMT          Specifies a file name, with full path, which specifies the (Blank)
|                   format of the summary statistic and analysis variables as 
|                   specified in macro %tu_statsfmt. It can also be in the 
|                   format: variable = file-name if there are multiple 
|                   variables given by &analysisvars
|                   Valid values: Can be one of following three
|                   1. Blank
|                   2. A file name
|                   3. variable1 = filename1, < variable2 = filename2
|                   The variable1, variable2, ? should be the variables 
|                   specified for ANALYSISVARS The valid format of the file 
|                   given by the file name is the same as specified in 
|                   %tu_statsfmt	
|
| XMLMERGEVAR	    Variable to merge input data and XML format data. This     (Blank)
|                   variable must exist in both datasets. Required if XMLINFMT 
|                   is not blank. It can also be in the format of several 
|                   "analysis-variable = merge-variable" if there are multiple 
|                   variables given by &analysisvars 
|                   Valid values: Can be one of following three
|                   1. Blank
|                   2. A file name
|                   3. Analysis-variable1 = merge-variable1 < 
|                      analysis-variable2 = merge-variable2 ? >. 
|                      The analysis-variable1, analysis-variable2, etc. should 
|                      be the variables specified for ANALYSISVARS
|                   The valid values for merge variables are the same as 
|                   specified in %tu_statsfmt	
|
|---------------------------------------------------------------------------------------------------
| Parameters, with defaul values, that pass to macro TU_STATS
|     PSBYVARS=(Blank), PSCLASS=(Blank),  PSCLASSOPTIONS=(Blank), PSFORMAT=(Blank), PSFREQ=(Blank),  
|     PSOPTIONS=Missing NWAY, PSOUTPUT=(Blank), PSOUTPUTOPTIONS=NOINHERIT, PSID=(Blank), 
|     PSTYPES=(Blank), PSWAYS=(Blank), PSWEIGHT=(Blank) 
|---------------------------------------------------------------------------------------------------
| Parameters, with defaul values, that pass to macro TU_LIST
|     BREAK1-BREAK5=(Blank), BYVARS=(Blank), CENTREVARS=(Blank), COLSPACING=2, COLUMNS=(Blank),  
|     COMPUTEBEFOREPAGELINES=(Blank), COMPUTEBEFOREPAGEVARS=(Blank),  
|     DDDATASETLABEL=DD dataset for a table, DEFAULTWIDTHS=(Blank), DESCENDING=(Blank),  
|     DISPLAY=Y, FLOWVARS=_All_, FORMATS=(Blank), IDVARS=(Blank), LABELS=(Blank), 
|     LEFTVARS=(Blank), LINEVARS=(Blank), NOPRINTVARS=(Blank), NOWIDOWVAR=(Blank),  
|     ORDERDATA=(Blank), ORDERFREQ=(Blank), ORDERVARS=(Blank), ORDERFORMATTED=(Blank),  
|     OVERALLSUMMARY=N, PAGEVARS=(Blank), PROPTIONS=Headline, RIGHTVARS=(Blank),  
|     SHARECOLVARS=(Blank), SHARECOLVARSINDENT=2, SKIPVARS=(Blank), SPLITCHAR=~, 
|     STACKVAR1-STACKVAR15=(Blank), VARSPACING=(Blank), WIDTHS=(Blank)     
|---------------------------------------------------------------------------------------------------
| Output:   1. an output file in plain ASCII text format containing a summary in columns data 
|              display matching the requirements specified as input parameters. 
|           2. SAS data set that forms the foundation of the data display (the "DD dataset").
|
| Global macro variables created:  None
|
| Macros called : 
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_addbignvar
| (@) tu_align
| (@) tu_chkvarsexist
| (@) tu_chknames
| (@) tu_dsetattr
| (@) tu_getdata
| (@) tu_labelvars
| (@) tu_list
| (@) tu_nobs
| (@) tu_pagenum
| (@) tu_putglobals
| (@) tu_stats
| (@) tu_statsfmt
| (@) tu_tidyup
|
| Example:  
|    The following example is used to create IDSL standard ECG summary table EG2.The input data 
|    set should be consistence with IDSL ECG data set standard. The %ts_setup macros should be
|    called before calling the example.
|
|    %tu_sumstatsincols(
|       dsetin            =ardata.ecg,
|       analysisVars           =EGHR PR ,
|       groupByVarsAnaly       =&g_trtcd &g_trtgrp ptmnum ptm,
|       analysisVarDps         =, 
|       analysisvarordervarname=TT_AVID,
|       analysisVarName        =TT_AVNM,
|       bignvarname            =TT_BNNM,
|       countDistinctWhatVarPop=&g_centid &g_subjid,    
|       groupbyVarPop          =&g_trtgrp,
|       statsdps               =MEDIAN +1 MEAN +1 STD +2, 
|       statslist              =N MIN MAX MEDIAN STD MEAN, 
|       totalforvar            =&g_trtcd,    
|     
|       break1                 =%str(after &g_trtgrp /skip),
|       columns                =&analysisvarordervarname &analysisvarname &g_trtcd &g_trtgrp &bignvarname 
|                               ptmnum ptm N MEAN STD MEDIAN MIN MAX, 
|       flowvars               =&analysisvarname,   
|       idVars                 =&analysisvarordervarname &analysisvarname &g_trtcd &g_trtgrp &bignvarname 
|                               ptmnum ptmvisit,
|       labels                 =%str(&analysisvarname="%str(~)" &bignvarname="N" N="n" MIN="Min" 
|                               MAX="Max" MEDIAN="Median" STD="STD" MEAN="Mean"),
|       noprintVars            =&analysisvarordervarname &g_trtcd ptmnum,   
|       orderVars              =&analysisvarordervarname &analysisvarname &g_trtcd &g_trtgrp &bignvarname 
|                               ptmnum ptm,  
|       proptions              =headline missing split='~',   
|       skipVars               =&g_trtgrp,
|       widths                 =&analysisvarname 14 &g_trtgrp 11 ptm 9 mean 5 std 5
|       );
|---------------------------------------------------------------------------------------------------
|
| Change Log :
|
| Modified By :             Yongwei Wang
| Date of Modification :    18 Sep 2003
| New Version Number :      1.002
| Modification ID :
| Reason For Modification : Incorporate comments from 1st iteration of SCR
| 
| Modified By :             Lee Seymour
| Date of Modification :    22-Aug-2014
| New Version Number :      2
| Modification ID :         LS001
| Reason For Modification : HRT0302 - Enabling compiling and execution with SAS 9.3
| 
| Modified By :
| Date of Modification :
| New Version Number :
| Modification ID :
| Reason For Modification :
+-------------------------------------------------------------------------------------------------*/
 

%MACRO tu_sumstatsincols(    
   ALIGNYN	                =Y,                    /*Control execution of tu_align*/
   ANALYSISVARDPS	        =,                     /*Number of decimal places  to which data was captured*/
   ANALYSISVARNAME	        =TT_AVNM,              /*Variable name that saves analysis variable labels or names in DD dataset*/
   ANALYSISVARORDERVARNAME	=TT_AVID,              /*Variable name that saves analysis variable order in DD dataset*/
   ANALYSISVARS	            =,                     /*Summary statistics analysis variables*/
   BIGNVARNAME	            =TT_BNNM,              /*Variable name that saves big N values in the DD dataset*/
   COUNTDISTINCTWHATVARPOP	=&G_CENTID &G_SUBJID,  /*What is being counted when counting big N*/
   DSETIN	                =,                     /*Input analysis dataset*/
   GROUPBYVARPOP	        =&G_TRTCD,             /*Variables to group by when counting big N*/
   GROUPBYVARSANALY	        =,                     /*The variables whose values define the subgroup combinations for the analysis*/
   LABELVARSYN	            =Y,                    /*Control execution of tu_labelvars*/
   POSTSUBSET	            =,                     /*SAS "IF" condition that applies to the presentation dataset.*/
   STATSDPS	                =,                     /*Number of decimal places of summary statistical results*/
   STATSLIST	            =,                     /*List of required summary statistics, e.g. N Mean Median. (or N=number MIN=minimum)*/
   VARLABELSTYLE	        =SHORT,                /*Specifies the label style for variables*/
   XMLINFMT	                =,                     /*Name and location of XML format file*/
   XMLMERGEVAR	            =,                     /*Variable to merge data and XML format data*/
   PSBYVARS                 =,                     /* See macro TU_STATS */
   PSCLASS                  =,                     /* See macro TU_STATS */
   PSCLASSOPTIONS           =,                     /* See macro TU_STATS */  
   PSFORMAT                 =,                     /* See macro TU_STATS */  
   PSFREQ                   =,                     /* See macro TU_STATS */  
   PSID                     =,                     /* See macro TU_STATS */  
   PSOPTIONS                =MISSING NWAY,         /* See macro TU_STATS */  
   PSOUTPUT                 =,                     /* See macro TU_STATS */  
   PSOUTPUTOPTIONS          =NOINHERIT,            /* See macro TU_STATS */
   PSTYPES                  =,                     /* See macro TU_STATS */  
   PSWAYS                   =,                     /* See macro TU_STATS */  
   PSWEIGHT                 =,                     /* See macro TU_STATS */  
   BREAK1                   =,                     /* See macro TU_LIST */
   BREAK2                   =,                     /* See macro TU_LIST */
   BREAK3                   =,                     /* See macro TU_LIST */
   BREAK4                   =,                     /* See macro TU_LIST */
   BREAK5                   =,                     /* See macro TU_LIST */
   BYVARS                   =,                     /* See macro TU_LIST */
   CENTREVARS               =,                     /* See macro TU_LIST */
   COLSPACING               =2,                    /* See macro TU_LIST */
   COLUMNS                  =,                     /* See macro TU_LIST */
   COMPUTEBEFOREPAGELINES   =,                     /* See macro TU_LIST */
   COMPUTEBEFOREPAGEVARS    =,                     /* See macro TU_LIST */
   DDDATASETLABEL           =DD dataset for a table,/* See macro TU_LIST */
   DEFAULTWIDTHS            =,                     /* See macro TU_LIST */
   DESCENDING               =,                     /* See macro TU_LIST */
   DISPLAY                  =Y,                    /* See macro TU_LIST */
   FLOWVARS                 =_ALL_,                /* See macro TU_LIST */
   FORMATS                  =,                     /* See macro TU_LIST */
   IDVARS                   =,                     /* See macro TU_LIST */
   LABELS                   =,                     /* See macro TU_LIST */
   LEFTVARS                 =,                     /* See macro TU_LIST */
   LINEVARS                 =,                     /* See macro TU_LIST */
   NOPRINTVARS              =,                     /* See macro TU_LIST */
   NOWIDOWVAR               =,                     /* See macro TU_LIST */
   ORDERDATA                =,                     /* See macro TU_LIST */ 
   ORDERFORMATTED           =,                     /* See macro TU_LIST */ 
   ORDERFREQ                =,                     /* See macro TU_LIST */ 
   ORDERVARS                =,                     /* See macro TU_LIST */ 
   OVERALLSUMMARY           =N,                    /* See macro TU_LIST */
   PAGEVARS                 =,                     /* See macro TU_LIST */ 
   PROPTIONS                =headline,             /* See macro TU_LIST */ 
   RIGHTVARS                =,                     /* See macro TU_LIST */
   SHARECOLVARS             =,                     /* See macro TU_LIST */
   SHARECOLVARSINDENT       =2,                    /* See macro TU_LIST */
   SKIPVARS                 =,                     /* See macro TU_LIST */ 
   SPLITCHAR                =~,                    /* See macro TU_LIST */ 
   STACKVAR1                =,                     /* See macro TU_LIST */ 
   STACKVAR10               =,                     /* See macro TU_LIST */ 
   STACKVAR11               =,                     /* See macro TU_LIST */ 
   STACKVAR12               =,                     /* See macro TU_LIST */ 
   STACKVAR13               =,                     /* See macro TU_LIST */  
   STACKVAR14               =,                     /* See macro TU_LIST */  
   STACKVAR15               =,                     /* See macro TU_LIST */  
   STACKVAR2                =,                     /* See macro TU_LIST */  
   STACKVAR3                =,                     /* See macro TU_LIST */  
   STACKVAR4                =,                     /* See macro TU_LIST */  
   STACKVAR5                =,                     /* See macro TU_LIST */  
   STACKVAR6                =,                     /* See macro TU_LIST */  
   STACKVAR7                =,                     /* See macro TU_LIST */  
   STACKVAR8                =,                     /* See macro TU_LIST */  
   STACKVAR9                =,                     /* See macro TU_LIST */  
   VARSPACING               =,                     /* See macro TU_LIST */  
   WIDTHS                   =                      /* See macro TU_LIST */
   );                                             
                                                  
   %***--------------------------------------------------------------------***;
   %***- Write details of macro call to log                               -***;
   %***--------------------------------------------------------------------***;

   %LOCAL MacroVersion;
   %LET MacroVersion = 1;

   %INCLUDE "&g_refdata/tr_putlocals.sas";
   %tu_putglobals(varsin=G_DDDATASETNAME  G_ANALY_DISP)

   %LOCAL l_analysisVar 
          l_analysisvardps 
          l_analydata
          l_cellindexyn 
          l_debug 
          l_formatd 
          l_groupbyvars 
          l_i l_i1 l_i2 l_in 
          l_prefix 
          l_publicvar
          l_rc 
          l_statsdps 
          l_statsvarlist 
          l_tmp 
          l_totalid
          l_totalidvar 
          l_workdata 
          l_workpath 
          l_xmlinfmt
          l_xmlmergevar 
          ;
          
   %LET l_prefix=_sumcol;   
   %LET l_debug=10;
   %LET l_cellindexyn=N;
   
   %***- define variable names that will be used in data processing -***;
   %LET l_formatd=tt_formatd;
   %LET l_publicvar=tt_publicvar;
      
   %***---------------------------------------------------------------------***;
   %***- Call tu_pagenum to delete output display file.                    -***;
   %***---------------------------------------------------------------------***;
                                 
   %tu_pagenum(usage=DELETE)  
   %IF %nrbquote(&g_abort) EQ 1 %THEN %GOTO macerr;   

   %***---------------------------------------------------------------------***;
   %***- IF GD_ANAYL_DISPLAY is yes, goto display.                         -***;
   %***---------------------------------------------------------------------***;
                    
   %IF %nrbquote(&G_ANALY_DISP) EQ D %THEN %DO;
      %***- check if data set G_DDDATASETNAME exist and it it is empty -***;
      %LET l_rc=%tu_nobs(&G_DDDATASETNAME);
      %IF &g_abort EQ 1 %THEN %GOTO macerr;
      
      %IF &l_rc EQ -1 %THEN %DO;
         %PUT %str(RTERR)OR: &sysmacroname: input data set "&dsetin" does not exist;
         %GOTO macerr;
      %END;
            
      %LET l_workdata=&G_DDDATASETNAME;
      
      %GOTO DISPLAYIT;
      
   %END;
   
   %***---------------------------------------------------------------------***;
   %***- Delete &G_DDDATASETNAME dataset if it exists                      -***;
   %***---------------------------------------------------------------------***;
   
   %IF %sysfunc(exist(&G_DDDATASETNAME)) %THEN %DO;
      PROC DATASETS MEMTYPE=(DATA VIEW) NOLIST NODETAILS
         %IF %INDEX(&G_DDDATASETNAME, %str(.)) %THEN %DO;
            LIBRARY=%scan(&G_DDDATASETNAME, 1, %str(.));
            DELETE %scan(&G_DDDATASETNAME, 2, %str(.));
         %END;
         %ELSE %DO;
            ;
            DELETE &G_DDDATASETNAME;
         %END;
      RUN;
      QUIT;
   %END;
  
   %***---------------------------------------------------------------------***;
   %***- Loop over all required parameters to check if any of required     -***;
   %***- parameters is blank.                                              -***;
   %***---------------------------------------------------------------------***;
   
   %LET l_i=1;
   %LET l_tmp=ALIGNYN ANALYSISVARORDERVARNAME ANALYSISVARNAME ANALYSISVARS DISPLAY 
              DSETIN GROUPBYVARSANALY LABELVARSYN STATSLIST; 
   %LET l_i1=%scan(&l_tmp, &l_i);
   %DO %WHILE ( %nrbquote(&l_i1) NE );
   
      %IF %nrbquote(&&&l_i1) EQ  %THEN %DO;
         %PUT %str(RTERR)OR: &sysmacroname: value of parameter &l_i1 is blank.;
         %GOTO macerr;
      %END;
      %LET l_i=%eval(&l_i + 1);
      %LET l_i1=%scan(&l_tmp, &l_i);
     
   %END;
   
   %***---------------------------------------------------------------------***;
   %***- Check if any of required parameters with Y, N value is valid.     -***;
   %***---------------------------------------------------------------------***;
   
   %LET l_i=1;
   %LET l_tmp=ALIGNYN LABELVARSYN DISPLAY;
   %LET l_i1=%scan(&l_tmp, &l_i);
   %DO %WHILE ( %nrbquote(&l_i1) NE );
                    
      %LET &l_i1=%qupcase(&&&l_i1);
      %IF ( %nrbquote(&&&l_i1) NE Y ) AND ( %nrbquote(&&&l_i1) NE N ) %THEN %DO;
         %PUT %str(RTERR)OR: &sysmacroname: value of parameter &l_i1 is invalid;
         %PUT %str(RTN)OTE:  &sysmacroname: valid values for &l_i1 are Y, N;
         %GOTO macerr;  
      %END;     
      %LET l_i=%eval(&l_i + 1);
      %LET l_i1=%scan(&l_tmp, &l_i);
     
   %END;
   
   %***---------------------------------------------------------------------***;
   %***- Check if any of parameters that depand on BIGNVARNAME is blank.   -***;
   %***---------------------------------------------------------------------***;
  
   %IF %nrbquote(&BIGNVARNAME) NE %THEN %DO;
  
      %IF %nrbquote(&COUNTDISTINCTWHATVARPOP) EQ  %THEN %DO;
         %PUT %str(RTERR)OR: &sysmacroname: value of parameter COUNTDISTINCTWHATVARPOP is blank.;
         %GOTO macerr;   
      %END;      
      %IF %nrbquote(&GROUPBYVARPOP) EQ  %THEN %DO;
         %PUT %str(RTERR)OR: &sysmacroname: value of parameter GROUPBYVARPOP is blank.;
         %GOTO macerr;
      %END;       
               
   %END;

   %***---------------------------------------------------------------------***;
   %***- Check if any given variable name is invalid.                      -***;
   %***---------------------------------------------------------------------***;
   
   %LET l_rc=%tu_chknames(&ANALYSISVARORDERVARNAME &ANALYSISVARNAME &BIGNVARNAME 
                          &GROUPBYVARPOP &COUNTDISTINCTWHATVARPOP &ANALYSISVARS, 
                          VARIABLE);
   %IF %nrbquote(&l_rc) EQ -1 %THEN %GOTO macerr;
   %IF %nrbquote(&l_rc) NE %THEN %DO;
      %PUT %str(RTERR)OR: &sysmacroname: variable name &l_rc given in the parameters is invalid.;
      %GOTO macerr;  
   %END;
     
   %***---------------------------------------------------------------------***;
   %***- Check input dataset.                                              -***;
   %***---------------------------------------------------------------------***;                                
   
   %***- If DSETIN exist -***; 
   %LET l_rc=%tu_nobs(&DSETIN);
   %IF &g_abort EQ 1 %THEN %GOTO macerr;
   
   %IF &l_rc EQ -1 %THEN %DO;
      %PUT %str(RTERR)OR: &sysmacroname: input data set "&dsetin" does not exist;
      %GOTO macerr;
   %END;
   
   %***- check if the input data set begin with value defined by l_prefix -***;    
   %IF %index(%upcase(&DSETIN), %upcase(&l_prefix)) EQ 1 %THEN %DO;
      %PUT %str(RTERR)OR: &sysmacroname: name of output data set &DSETIN has prefix &l_prefix and it is not allowed;
      %GOTO macerr;   
   %END;
   
   %***- Save input data set to a temporary data set so that the SAS data -***;
   %***- options can be applied -***;   
   DATA &l_prefix.dsetin;
      SET &DSETIN;
   RUN;
   
   %***- Capture the errors in DSETIN -***;
   %IF &SYSERR GT 0 %THEN %DO;
     %PUT %str(RTERR)OR: &sysmacroname: value of parameter DSETIN cause SAS error(s);                  
     %GOTO macerr;
   %END;
   
   %LET L_WORKDATA=&l_prefix.dsetin;
     
   %***---------------------------------------------------------------------***;
   %***- Check If ANALYSISVARS exists in the input data set                -***;
   %***---------------------------------------------------------------------***;         
             
   %LET l_rc=%tu_chkvarsexist(&L_WORKDATA, &ANALYSISVARS);
   %IF &g_abort EQ 1 %THEN %GOTO macerr;
   
   %IF %str(X&l_rc) NE X %THEN %DO;
      %PUT %str(RTERR)OR: &sysmacroname: not all variables given by ANALYSISVARS are in input dataset;
      %PUT %str(RTERR)OR: &sysmacroname: or value of the parameter is invalid.;
      %GOTO macerr;
   %END;
      
   %***---------------------------------------------------------------------***;
   %***- Check If ANALYSISVARORDERVARNAME, ANALYSISVARNAME and BIGNVARNAME -***;
   %***- exists in the input data set                                      -***;
   %***---------------------------------------------------------------------***;         
       
   %LET l_tmp=&ANALYSISVARORDERVARNAME &ANALYSISVARNAME &BIGNVARNAME;
   %LET l_rc=%tu_chkvarsexist(&L_WORKDATA, &l_tmp);
   %IF &g_abort EQ 1 %THEN %GOTO macerr;
   
   %LET l_i=1;              
   %LET l_i1=%SCAN(&l_tmp, &l_i, %str( ));
   %LET l_i2=%SCAN(&l_rc, &l_i, %str( ));
   %DO %WHILE(%nrbquote(&l_i1) NE );
      %IF %nrbquote(&l_i2) EQ %THEN %DO;
         %PUT %str(RTERR)OR: &sysmacroname: at least one of the variables given by ANALYSISVARORDERVARNAME, ;
         %PUT %str(RTERR)OR: &sysmacroname: ANALYSISVARNAME and BIGNVARNAME are already in input dataset ;
         %GOTO macerr;
      %END;
      
      %LET l_i=%EVAL(&l_i + 1);
      %LET l_i1=%SCAN(&l_tmp, &l_i, %str( ));
      %LET l_i2=%SCAN(&l_rc, &l_i, %str( ));
   %END;
   
   %***---------------------------------------------------------------------***;            
   %***- Separate GROUPBYVARSANALY to multiple groups based on total.      -***;
   %***- The GROUPBYVARSANALY can be in the format VAR1 VAR2               -***;
   %***- (SAS-statement) VAR3 VAR4. The following codes will split it into -***;
   %***- two group of group-by-vars: var1 var2 var3 var4, and var1 var2    -***;
   %***- and one SAS statement: the statement in ( and )                   -***;
   %***- The separated parts will be saved in macro variables and will be  -***;
   %***- be used when calling tu_stats                                     -***;
   %***---------------------------------------------------------------------***;
       
   DATA _NULL_;
      LENGTH vars group groups groupbyvars $32761;   
      vars="%nrbquote(&GROUPBYVARSANALY)";
      n=0;
      stats="";
      
      LINK scangrp;
      DO WHILE (group NE "");
         IF indexc(group, '()') GT 0 THEN DO;
            PUT "RTERR" "OR: &sysmacroname: unblanced ( and ) are found in GROUPBYVARSANALY.." ;
            CALL SYMPUT('L_RC', -1);   
            STOP;        
         END;
         IF incomb EQ 1 THEN DO;
            n=n+1;  
            CALL SYMPUT("l_stat"||left(n), trim(left(group)));
            CALL SYMPUT("l_group"||left(n), trim(left(groups)));
         END;
         ELSE DO;
            groups=trim(left(groups))||" "||trim(left(group));
            groupbyvars=trim(left(groupbyvars))||" "||trim(left(group));
         END;
         
         LINK scangrp;
      END;
           
      IF incomb EQ 0 THEN DO;
         n=n+1;
         groups=trim(left(groups))||" "||trim(left(group));
         groupbyvars=trim(left(groupbyvars))||" "||trim(left(group));
         CALL SYMPUT("l_group"||left(n), trim(left(groups)));
         CALL SYMPUT("l_stat"||left(n), "");      
      END;
      
      CALL SYMPUT( "l_in", n);     
      CALL SYMPUT( "l_groupbyvars", trim(left(groupbyvars)));

      RETURN;
 
      %***- A scan routine similar to SCAN fuction with delimeter ( and ). -***;
      %***- A flag will be given to indicate the current values is inside  -***;
      %***- ( and ) or outside                                             -***;

      SCANGRP:

      index=index(vars, '(');

      IF index GT 1 THEN DO;
         group=trim(substr(vars, 1, index -1));
         vars=left(substr(vars, index));
         incomb=0;
      END;
      ELSE IF index EQ 1 THEN DO;
         index=index(vars, ')');
         group=trim(left(substr(vars, 2, index - 2)));
         vars=left(substr(vars, index + 1));
         incomb=1;
      END;
      ELSE DO;
         group=trim(left(vars));
         vars="";
         incomb=0;
      END;

      RETURN;     
      
   RUN;
   
   %IF &L_RC EQ -1 %THEN %GOTO MACERR;
   
   %***---------------------------------------------------------------------***;
   %***- Localize new macro variables created above and check the existence-***
   %***- of the variables in GROUPBYVARSANALY                              -***;
   %***---------------------------------------------------------------------***;
 
   %DO l_i=1 %TO &l_in ;      
      %LOCAL l_stat&l_i l_group&l_i ;
   %END;
        
   %LET l_rc=%tu_chkvarsexist(&l_workdata, &l_groupbyvars);                   
   
   %IF &g_abort EQ 1 %THEN %GOTO macerr;
   %IF %nrbquote(&l_rc) NE %THEN %DO;
      %PUT %str(RTERR)OR: &sysmacroname: not all variable names given by GROUPBYVARSANALY is in input dataset;
      %PUT %str(RTERR)OR: &sysmacroname: or value of the parameter is invalid.;
      %GOTO macerr;
   %END;
    
   %***---------------------------------------------------------------------***;
   %***- Check if any paramters with format variable=values has the        -***;
   %***- variable in ANALYSISVARS                                          -***;
   %***---------------------------------------------------------------------***;
   
   %LET l_tmp=ANALYSISVARDPS XMLINFMT XMLMERGEVAR STATSDPS ;
   
   %LET l_i=1;
   %LET l_i1=%scan(&l_tmp, &l_i);
   %DO %WHILE(%nrbquote(&l_i1) NE );
      %LET l_rc=0;
      DATA _NULL_;
         LENGTH var varval $32761;
         group=upcase("&ANALYSISVARS");
         varval="%nrbquote(&&&l_i1)";
         
         index=index(varval, '=');
         DO WHILE (index GT 0);
            IF index=1 THEN DO;
               PUT "RTERR" "OR: &sysmacroname: Syntax error was found in input parameter &l_i1." ;
               CALL SYMPUT('L_RC', -1);   
               STOP;
            END;
            ELSE DO;
               var=substr(varval, 1, index - 1 );
               var=left(reverse(var));
               var=left(reverse(scan(var, 1, ' ')));
               var=upcase(var);
             
               IF indexw(group, var) EQ 0 THEN DO;
                  PUT "RTERR" "OR: &sysmacroname: variable " var " given by &l_i1 is not in parameter ANALYSISVARS" ;
                  CALL SYMPUT('L_RC', -1);   
                  STOP;            
               END;               
               
               varval=substr(varval, index + 1);
               index=index(varval, '=');
                              
            END;
         END; %***- End of Do-loop on index -***;
      RUN;   
      
      %IF &L_RC EQ -1 %THEN %GOTO MACERR;
      %LET l_i=%eval(&l_i + 1);
      %LET l_i1=%scan(&l_tmp, &l_i);           
   %END;
   
                      
   %***---------------------------------------------------------------------***;
   %***- Get new variable names in STATSLIST. Those new names will be added-***;
   %***- to data set by tu_stats                                           -***;
   %***---------------------------------------------------------------------***;     
   
   %LET l_rc=0;
       
   DATA _NULL_;
      LENGTH statslist varlist tmp $32761 var $32;
      
      statslist=trim(left("&STATSLIST"));   
      indexq=index(statslist, '=');
      varlist="";
      
      DO WHILE ( indexq GT 0 );
         IF indexq EQ 1 THEN DO;
            PUT "RTERR" "OR: &sysmacroname: Syntax error was found in input parameter STATSLIST for variable " ;
            CALL SYMPUT('L_RC', -1);   
            STOP;
         END;
     
         tmp=left(substr(statslist, 1, indexq - 1));               
         i=2;
         var=scan(tmp, i, ' ');
         DO WHILE (var NE '');
            varlist=trim(left(varlist))||" "||left(scan(tmp, i - 1, ' '));
            i=i+1;
            var=scan(tmp, i, ' ');
         END;
         statslist=trim(left(substr(statslist, indexq + 1)));
         varlist=trim(left(varlist))||" "||left(scan(statslist, 1, ' '));
         
         indexq=index(statslist, ' ');
         IF indexq GT 0 THEN statslist=left(substr(statslist, indexq + 1));
         indexq=index(statslist, '=');                 
      END;               
      
      varlist=trim(left(varlist))||" "||left(statslist);                      
      CALL SYMPUT('L_STATSVARLIST', trim(left(varlist)));      
 
   RUN;
   
   %IF &L_RC EQ -1 %THEN %GOTO MACERR;

   %***---------------------------------------------------------------------***;
   %***- Loop over variables that will be added to data set to see if any  -***;
   %***- of them is already in input data set.                             -***;
   %***---------------------------------------------------------------------***;      
  
   %LET l_rc=0;
         
   DATA _NULL_;
      LENGTH var1 var2 $32;
      varlist="&ANALYSISVARORDERVARNAME &ANALYSISVARNAME &BIGNVARNAME " ||
              "&L_STATSVARLIST &L_GROUPBYVARS &L_FORMATD &L_PUBLICVAR";
      
      i=1;
      var1=scan(varlist, i);
      DO WHILE (var1 NE "");
         j=i+1;
         var2=scan(varlist, j);
         DO WHILE (var2 NE "");
            IF var1 EQ var2 THEN DO;
               PUT "RTERR" "OR: &sysmacroname: variable name " var1 " is used more than once either as parameters";
               PUT "RTERR" "OR: &sysmacroname: or as internal variable name";
               CALL SYMPUT('l_rc', '-1');
               STOP;
            END;
            j=j+1;
            var2=scan(varlist, j);             
         END;  %***- End of do-loop on var2 -***;
         
         i=i+1;
         var1=scan(varlist, i);
      END; %***- End of do-loop on var1 -***;
   RUN;
   
   %IF &l_rc EQ -1 %THEN %GOTO macerr;   
        
   %***---------------------------------------------------------------------***;
   %***- Call tu_getdata to subset the input data set and get population   -***;
   %***- data set                                                          -***;
   %***---------------------------------------------------------------------***;
   
   %LET l_debug=%eval(&l_debug - 1);
   
   %tu_getdata(
      DSETIN=&L_WORKDATA, 
      DSETOUT1=&L_PREFIX.ANALY,
      DSETOUT2=&L_PREFIX.POP
      )
          
   %IF &g_abort EQ 1 %THEN %GOTO macerr;
   
   %LET l_workdata=&l_prefix.analy;
   
   %IF &g_debug GE &l_debug %THEN %DO ;
   
      %PUT ===============================================================;
      %PUT DEBUG: &sysmacroname: Debug information at level &l_debug;
      %PUT ===============================================================;

      PROC PRINT DATA=&l_workdata;
         TITLE "Output Analysis Data from TU_GETDATA: &L_WORKDATA";
      RUN;
      
      PROC PRINT DATA=&l_workdata;
         TITLE "Output Population Data from TU_GETDATA: &L_WORKDATA";
      RUN;
      
   %END;
      
   %IF %nrbquote(&BIGNVARNAME)  NE %THEN %DO;              
                                    
   %***---------------------------------------------------------------------***;
   %***- Check if variables given by COUNTDISTINCTWHATVARPOP and           -***;
   %***- GROUPBYVARPOP are in the population data set                      -***;
   %***---------------------------------------------------------------------***;   
   
      %***- COUNTDISTINCTWHATVARPOP -***;           
      %LET l_rc=%tu_chkvarsexist(&l_prefix.pop, &COUNTDISTINCTWHATVARPOP);    
      %IF %qupcase(&l_rc) NE %THEN %DO;
         %PUT %str(RTERR)OR: &sysmacroname: not all variables given by COUNTDISTINCTWHATVARPOP are in ;
         %PUT %str(RTERR)OR: &sysmacroname: population data set or value of the parameter is invalid. ;
         %GOTO macerr;
      %END;
     
      %***- GROUPBYVARPOP -***;           
      %LET l_rc=%tu_chkvarsexist(&l_prefix.pop, &GROUPBYVARPOP);    
      %IF %nrbquote(&l_rc) NE %THEN %DO;
         %PUT %str(RTERR)OR: &sysmacroname: variable name given by GROUPBYVARPOP is not in ;
         %PUT %str(RTERR)OR: &sysmacroname: population data set or value of the parameter is invalid.;
         %GOTO macerr;
      %END;
      
   %***---------------------------------------------------------------------***;
   %***- Get last variable in GROUPBYVARPOP as the variable that have      -***;
   %***- TOTALID defined in MACRO TU_ADDBIGNVAR                            -***;
   %***---------------------------------------------------------------------***;   
      
      DATA _NULL_;
         LENGTH tmp $32761;
         tmp=trim(left("&GROUPBYVARPOP"));     
         tmp=left(reverse(tmp));
         tmp=scan(tmp, 1, ' ');
         tmp=reverse(tmp);
         CALL SYMPUT('L_TOTALIDVAR', trim(left(tmp)));
         STOP;
      RUN;
      
   %END;  
   
   %***---------------------------------------------------------------------***;
   %***- Check if there is datum in the working data set. If the data set  -***;
   %***- is empty, add variables that will be added and go to display      -***;
   %***- directly                                                          -***;
   %***---------------------------------------------------------------------***;
   
   %LET l_rc=%tu_nobs(&L_WORKDATA);
   %IF &g_abort EQ 1 %THEN %GOTO macerr;
   
   %IF &l_rc EQ 0 %THEN %DO;   
      %***- add new variables in -***;
      DATA &l_prefix.nodata;
         SET &L_WORKDATA;
         %IF &BIGNVARNAME NE %THEN %DO;
            &BIGNVARNAME=.;
         %END;
         &ANALYSISVARNAME="";
         &ANALYSISVARORDERVARNAME=.;
         
         %LET l_i=1;
         %LET l_i2=%SCAN(&L_STATSVARLIST, &l_i);
         %DO %WHILE( %nrbquote(&l_i2) NE );  
            &l_i2="";
            %LET l_i=%eval(&l_i + 1);
            %LET l_i2=%SCAN(&L_STATSVARLIST, &l_i);
         %END;
         IF _N_ < 0;
      RUN;
       
      %LET L_WORKDATA=&l_prefix.nodata;  
           
      %GOTO DISPLAYIT;
   %END;
   
   %***- save the name of the data set before calling tu_stats -***;                                
   %let l_analydata=&L_WORKDATA;
  
   %***---------------------------------------------------------------------***;
   %***- Loop over ANALYSISVARS to call TU_STATS                           -***;
   %***- Loop over ANALYSISVARDPS AND STATSDPS to call TU_STATSFMT         -***;
   %***---------------------------------------------------------------------***;
   
   %LET l_debug=%eval(&l_debug - 1);
  
   %LET l_i=1;
   %LET l_i2=0;
   %LET l_analysisVar=%scan(&analysisVars, &l_i);                

   %DO %WHILE( %nrbquote(&l_analysisVar) NE );    
   
      %***------------------------------------------------------------------***;            
      %***- Get ANALYSISVARDPS, XMLINFMT, XMLMERGEVAR and STATSDPS of the  -***;
      %***- variable. Those parameters can be in format VAR=value. The     -***;
      %***- codes below search the current processing analysis variable    -***;
      %***- in them and find the specific values for this variable         -***;
      %***------------------------------------------------------------------***;
      
      %LET l_rc=0;
        
      DATA _NULL_;
         LENGTH adpss adps tmp $32761 var var1 $100 type $20;
         var=upcase(trim(left("&L_ANALYSISVAR")));                
         
         %***- ANALYSISVARDPS -***;
         adpss=trim(left("&ANALYSISVARDPS"));         
         type="ANALYSISVARDPS";                                 
         LINK GETDPS;
         
         IF ( adps GT "") THEN IF ( (length(adps) GT 2) AND verify(substr(adps, 2), '0123456789') ) OR
             verify(substr(adps, 1, 1), '0123456789') THEN DO;
            PUT "RTE" "RROR: &sysmacroname: ANALYSISVARDPS for variable " var " is invalid" ;
            CALL SYMPUT('l_rc', '-1');
            STOP;
         END;                               
         
         CALL SYMPUT('L_ANALYSISVARDPS', trim(left(adps)));
         
         %***- STATSDPS -***;
         adpss=trim(left("&STATSDPS")); 
         type="STATSDPS";              
         LINK GETDPS;                            
         CALL SYMPUT('L_STATSDPS', trim(left(adps)));
         
         %***-XMLINFMT -***;
         adpss=trim(left("&XMLINFMT")); 
         type="XMLINFMT";              
         LINK GETDPS;                            
         CALL SYMPUT('L_XMLINFMT', trim(left(adps)));
         
         %***-XMLMERGEVAR -***;
         adpss=trim(left("&XMLMERGEVAR")); 
         type="XMLINFMT";              
         LINK GETDPS;                            
         CALL SYMPUT('L_XMLMERGEVAR', trim(left(adps)));
        
         STOP;
         RETURN;
         
      %***- Sub-routine to get the string after the = -***;   
      GETDPS:   
      
         adps="";
         index=index(adpss, '=');   
         IF index EQ 0 THEN DO;
            adps=adpss;
         END;
         ELSE IF index EQ 1 THEN DO;
            PUT "RTERR" "OR: &sysmacroname: Syntax error is found in input parameter " type " for variable " var;
            CALL SYMPUT('l_rc', '-1');
            STOP;
         END;                     
         DO WHILE(index GT 1);
            tmp=substr(adpss, 1, index - 1) ;
            adpss=substr(adpss, index + 1);
            
            var1=scan(reverse(tmp), 1, ' ');
            var1=left(reverse(var1));
            
            index=index(adpss, '=');
            
            IF upcase(compress(var1)) EQ var THEN DO;
            
               IF index EQ 1 THEN DO;
                  PUT "RTE" "RROR: &sysmacroname: Syntax error is found in input parameter " type " for variable " var;
                  CALL SYMPUT('l_rc', '-1');
                  STOP;
               END;
               ELSE IF index GT 1 THEN DO;                    
                  adpss=substr(adpss, 1, index - 1);
                  adpss=left(reverse(adpss));
                  index=index(adpss, ' ');               
                
                  IF index LE 1 THEN DO;                          
                     PUT "RTERR" "OR: &sysmacroname: Syntax error is found in input parameter " type " for variable " var;
                     CALL SYMPUT('l_rc', '-1');
                     STOP;
                  END; 
                  ELSE adps=left(reverse(substr(adpss, index + 1)));
            
                  LEAVE; 
               END;
               ELSE adps=adpss;
            END;                 
         END;   %***- End of do-loop on index -***;
            
         RETURN;   
      RUN;
      
      %IF &l_rc EQ -1 %THEN %GOTO macerr;        
      
      %IF &g_debug GE &l_debug %THEN %DO ;
        
        %PUT ===============================================================;
        %PUT DEBUG: &sysmacroname: Debug information at level &l_debug;
        %PUT ===============================================================;
        
        %PUT L_ANALYSISVAR=&L_ANALYSISVAR ; 
        %PUT L_STATSDPS=&L_STATSDPS ;   
        %PUT L_ANALYSISVARDPS=&L_ANALYSISVARDPS;
        
      %END;
      
      %***------------------------------------------------------------------***;      
      %***- Check if L_STATSDPS variables are valid. If any variable in    -***;
      %***- STATSLIST, but not L_STATSDPS, add it in. L_STATSDPS is the    -***;
      %***- STATSDPS for the current analysis variable.                    -***;
      %***------------------------------------------------------------------***;
      
      %LET l_rc=0;    
      
      %IF %nrbquote(&XMLINFMT) EQ %THEN %DO;
         DATA _NULL_;
            LENGTH statslist statsdps newdps $32761 statsvar dpsvar dps $32;
            statslist=upcase(left("&l_statsvarlist"));
            statsdps=upcase(left("&l_statsdps"));
            newdps=statsdps;
            
            i=1;
            dpsvar=scan(statsdps, i, " ");
            
            DO WHILE(dpsvar NE "");
            
               %***- check if dpsvar is in statslist -***;
               IF indexw(statslist, dpsvar) EQ 0 THEN DO;
                  PUT "RTERR" "OR: &sysmacroname: value of parameter STATSDPS is invalid";
                  PUT "RTERR" "OR: &sysmacroname: " dpsvar "in STATSDPS is not in STATSLIST.";
                  CALL SYMPUT("l_rc", "-1");             
                  STOP;
               END;
               
               %***- check if dps is valid -***;
               dps=scan(statsdps, i + 1, " ");
               IF verify(substr(dps, 1, 1),"+-") THEN DO;
                  PUT "RTERR" "OR: &sysmacroname: value of parameter STATSDPS is invalid";
                  CALL SYMPUT("l_rc", "-1");            
                  STOP;
               END;
               
               IF verify(compress(substr(dps, 2)),"0123456789") THEN DO;            
                  PUT "RTERR" "OR: &sysmacroname: value of parameter STATSDPS is invalid";
                  CALL SYMPUT("l_rc", "-1"); 
                  STOP;
               END;            
               
               i=i+2;
               dpsvar=scan(statsdps, i, " ");
            END;
            
            %***- check if statvar in statsdps, if not add in -***;
            i=1;
            statsvar=scan(statslist, i, " ");
            DO WHILE(statsvar NE "");
               IF indexw(statsdps, statsvar) EQ 0 THEN DO;
                  newdps=trim(left(newdps))||" "||trim(left(statsvar))||" +0";
                  PUT "RTN" "OTE: &sysmacroname: " statsvar "+0 has been added to STATSDPS";
               END;
               i=i+1;
               statsvar=scan(statslist, i, " ");
            END;
            
            CALL SYMPUT("l_statsdps", trim(left(newdps)));
        
         RUN;
         
      %END;
      
      %IF &L_RC NE 0 %THEN %GOTO macerr;
   
      %***------------------------------------------------------------------***;            
      %***- Loop over groupBYVarsAnaly to get summary statistics of        -***;
      %***- different levels of the group.                                 -***;
      %***------------------------------------------------------------------***;
 
      %LET l_i2=0;

      %DO l_i1=&l_in %TO 1 %BY -1; 
         
         %***------------------------------------------------------------***;            
         %***- Call TU_STATS to get summary statistics.                 -***;
         %***------------------------------------------------------------***;
      
         %tu_stats(
            ANALYSISVAR            =&L_ANALYSISVAR, 
            ANALYSISVARFORMATDNAME =&L_FORMATD, 
            ANALYSISVARNAME        =&ANALYSISVARNAME, 
            CLASSVARS              =&&L_GROUP&l_i1, 
            COUNTDISTINCTWHATVAR   =, 
            COUNTVARNAME           =,
            DSETIN                 =&L_WORKDATA, 
            DSETOUT                =&L_PREFIX.SUMOUTLOOP,
            %IF %nrbquote(&l_cellindexyn) EQ Y %THEN %DO;
            DSETOUTCI              =&L_PREFIX.DDDATASETNAMECI,
            %END;
            %ELSE %DO;
            DSETOUTCI              =,
            %END;
            STATSLIST              =&STATSLIST, 
                                                          
            PSBYVARS               =&PSBYVARS,  
            PSCLASS                =&PSCLASS,  
            PSCLASSOPTIONS         =&PSCLASSOPTIONS,  
            PSFORMAT               =&PSFORMAT,  
            PSFREQ                 =&PSFREQ,  
            PSOPTIONS              =&PSOPTIONS,  
            PSOUTPUT               =&PSOUTPUT,  
            PSOUTPUTOPTIONS        =&PSOUTPUTOPTIONS,
            PSID                   =&PSID,  
            PSTYPES                =&PSTYPES,  
            PSWAYS                 =&PSWAYS,  
            PSWEIGHT               =&PSWEIGHT,
            TOTALID                =,
            TOTALFORVAR            =,
            VARLABELSTYLE          =std  
            )
                      
               
         %***- Add the statments between ( and ) in GROUPBYVARSANALY to data set -***;                          
         %IF %nrbquote(&&l_stat&l_i1) NE %THEN %DO;
         
            %IF &g_abort EQ 1 %THEN %GOTO macerr;
            
            DATA &l_prefix.sumoutloop;
               SET &l_prefix.sumoutloop;
               &&l_stat&l_i1 ;                                                     
            RUN;
                                             
            %***- Check if the above gives SAS errors -***;
            %IF &SYSERR GT 0 %THEN %DO;
              %PUT %str(RTERR)OR: &sysmacroname: value of parameter GROUPBYVARSANALY is invalid;   
              %PUT %str(RTERR)OR: &sysmacroname: it may caused by invalid statement(s) between ( and ).;                  
              %GOTO macerr;
            %END;
            
            %***- Cell index data set -***; 
            %IF %nrbquote(&l_cellindexyn) EQ Y %THEN %DO;
               DATA &L_PREFIX.DDDATASETNAMECI;
                  SET &L_PREFIX.DDDATASETNAMECI;
                  &&l_stat&l_i1 ;                                                     
               RUN;
            %END;
                         
            %LET l_tmp=;               
         %END;
         
         %***- Concatenate the data set together -***;
         %IF &l_i2 EQ 0 %THEN %DO;
            DATA &L_PREFIX.SUMOUT;
               SET &L_PREFIX.SUMOUTLOOP;
            RUN;
            
            %IF %nrbquote(&l_cellindexyn) EQ Y %THEN %DO;
               DATA &G_DDDATASETNAMECI;
                  SET &L_PREFIX.DDDATASETNAMECI;
               RUN;
            %END;
            
            %LET l_i2=1;         
         %END;         
         %ELSE %DO;          
                                       
            %***- Concatenate data set -***;
            %LET l_rc=%tu_dsetattr(&l_prefix.sumout, NVARS);
            DATA &l_prefix.sumout ;
               SET &l_prefix.sumout &l_prefix.sumoutloop;
            RUN;  
                            
            %***- Trap the SAS error caused by unmatched type -***;                                 
            %IF &SYSERR GT 0 %THEN %DO;
              %PUT %str(RTERR)OR: &sysmacroname: value of parameter GROUPBYVARSANALY is invalid;                     
              %PUT %str(RTERR)OR: &sysmacroname: it may caused by unmatched variable types.;
              %GOTO macerr;
            %END;                         
            
            %***- Check if there is new added variables -***;         
            %IF %tu_dsetattr(&l_prefix.sumout, NVARS) NE &l_rc %THEN %DO;                      
                %IF &g_abort EQ 1 %THEN %GOTO macerr;
                %PUT %str(RTE)RROR: &sysmacroname: value of parameter GROUPBYVARSANALY is invalid;                     
                %PUT %str(RTE)RROR: &sysmacroname: it may cause by unknown variable name(s) between ( and ).;
                %GOTO macerr; 
            %END;
            %IF &g_abort EQ 1 %THEN %GOTO macerr;
            
            %***- Concatenate cell index data set -***;
            %IF %nrbquote(&l_cellindexyn) EQ Y %THEN %DO;
               DATA &G_DDDATASETNAMECI;
                  SET &G_DDDATASETNAMECI &L_PREFIX.DDDATASETNAMECI;
               RUN; 
            %END;
            
            %***- Trap the SAS error caused by unmatched type -***;                                 
            %IF &SYSERR GT 0 %THEN %DO;
              %PUT %str(RTERR)OR: &sysmacroname: value of parameter GROUPBYVARSANALY is invalid;                     
              %PUT %str(RTERR)OR: &sysmacroname: it may caused by unmatched variable types.;
              %GOTO macerr;
            %END;              
                           
         %END;
         
      %END; %***- end of do-loop on l_i1 -***;     
      
      %***------------------------------------------------------------***;                  
      %***-  Add ANALYSISVARORDERVARNAME and L_FORMATD in            -***;  
      %***------------------------------------------------------------***; 
            
      DATA &l_prefix.sumout;
         SET &l_prefix.sumout;
         LABEL &analysisvarordervarname="Order of analysis variables";
         &analysisvarordervarname=&l_i;                            
         %IF %nrbquote(&L_ANALYSISVARDPS) NE %THEN %DO;
            &L_FORMATD=&L_ANALYSISVARDPS;
         %END;
      RUN;

      %IF %nrbquote(&l_cellindexyn) EQ Y %THEN %DO;
         DATA &G_DDDATASETNAMECI;
            SET &G_DDDATASETNAMECI;
            LABEL &analysisvarordervarname="Order of analysis variables";
            &analysisvarordervarname=&l_i; 
         RUN; 
      %END;      
                 
      %***------------------------------------------------------------------***;            
      %***- Call TU_STATSFMT to add format to summary statistics.          -***;
      %***------------------------------------------------------------------***;      
      
       %IF &g_debug GE &l_debug %THEN %DO ;
         
         %PUT ===============================================================;
         %PUT DEBUG: &sysmacroname: Debug information at level &l_debug;
         %PUT ===============================================================;
     
         PROC PRINT DATA=&L_PREFIX.SUMOUT;
            TITLE "Output from TU_SUMSTATS BEFORE TU_STATSFMT: &L_WORKDATA";
         RUN;
         
      %END;        
            
      %tu_statsfmt(
         DSETIN            =&L_PREFIX.SUMOUT,           
         DSETOUT           =&L_PREFIX.SUMOUT,             
         %IF %nrbquote(&XMLINFMT) EQ %THEN %DO;              
         STATSDPS          =&L_STATSDPS, 		     
         ANALYSISVARDPSVAR =&L_FORMATD,
         XMLINFMT          =,   
         XMLMERGEVAR       =        
         %END;
         %ELSE %DO;
         ANALYSISVARDPSVAR =,        
         STATSDPS          =,
         XMLINFMT          =&L_XMLINFMT,   
         XMLMERGEVAR       =&L_XMLMERGEVAR
         %END;
         )      
                 
      %IF &g_debug GE &l_debug %THEN %DO ;
         
         %PUT ===============================================================;
         %PUT DEBUG: &sysmacroname: Debug information at level &l_debug;
         %PUT ===============================================================;
     
         PROC PRINT DATA=&L_PREFIX.SUMOUT;
            TITLE "Output from TU_SUMSTATS AFTER TU_STATSFMT: &L_WORKDATA";
         RUN;
         
      %END;          
      
      %***- concatenate the data sets together -***; 
      %IF &l_i EQ 1 %THEN %DO;
         DATA &l_prefix.fmtout;
            SET &l_prefix.sumout;
         RUN;
      %END; 
      %ELSE %DO;
         DATA &l_prefix.fmtout;
            SET &l_prefix.fmtout &l_prefix.sumout;
         RUN;     
      %END;
      
      %LET l_i2=0;
      %LET l_i=%eval(&l_i + 1);
      %LET l_analysisVar=%scan(&analysisvars, &l_i);       

   %END;  %***- end of do-loop on l_analysisvar -***;         
   
   %LET l_workdata=&l_prefix.fmtout;
        
   %IF &g_debug GE &l_debug %THEN %DO ;
      
      %PUT ===============================================================;
      %PUT DEBUG: &sysmacroname: Debug information at level &l_debug;
      %PUT ===============================================================;
 
      %PUT L_TOTALID=&L_TOTALID ;   
      %PUT L_TOTALIDVAR=&L_TOTALIDVAR ;

      PROC PRINT DATA=&l_workdata;
         TITLE "Output from TU_SUMSTATS: &L_WORKDATA";
      RUN;
      
      %IF %nrbquote(&l_cellindexyn) EQ Y %THEN %DO;
         PROC PRINT DATA=&G_DDDATASETNAMECI;
            TITLE "Output from Cell Index Data &G_DDDATASETNAMECI";
         RUN;      
      %END;
      
   %END;                     
          
   %***---------------------------------------------------------------------***;
   %***- Call tu_addbign to add big N to data set.                         -***;
   %***---------------------------------------------------------------------***; 
   
   %LET l_debug=%eval(&l_debug - 1);

   %IF %nrbquote(&BIGNVARNAME) NE %THEN %DO;
   
      %***- Get total ID values from TOTALIDVAR. The total ID can only be -***; 
      %***- added from the statements in GROUPBYVARSANALY.                -***;
      %***- Get levels of TOTALIDVAR from the data set before and after   -***;
      %***- TU_STATS. If one level is added, take it as total ID          -***;
      PROC SORT DATA=&l_analydata OUT=&l_prefix.temp1(KEEP=&L_TOTALIDVAR) NODUPKEY;
         BY &L_TOTALIDVAR;
      RUN;
   
      PROC SORT DATA=&l_workdata OUT=&l_prefix.temp2(KEEP=&L_TOTALIDVAR) NODUPKEY;
         BY &L_TOTALIDVAR;
      RUN;
      
      %LET l_rc=0;
      %LET l_totalid=;
      
      DATA _NULL_;
         MERGE &l_prefix.temp1 (IN=&l_publicvar._IN1_)
               &l_prefix.temp2 (IN=&l_publicvar._IN2_) ;
         BY &L_TOTALIDVAR;
         
         IF ( NOT &l_publicvar._IN1_ ) AND &l_publicvar._IN2_ ;
         n=n+1;

         IF n GT 1 THEN DO;
            PUT "RTERR" "OR: &sysmacroname: value of parameter GROUPBYVARSANALY is invalid";                     
            PUT "RTERR" "OR: &sysmacroname: more than one levels of &L_TOTALIDVAR has been added from GROUPBYVARSANALY.";        
            CALL SYMPUT('l_rc', '-1');
            STOP;
         END;
         
         CALL SYMPUT('l_totalid', trim(left(&L_TOTALIDVAR)) );        
         
      RUN;
      
      %IF &l_rc NE 0 %THEN %GOTO macerr;
                  
      %tu_addbignvar(
         BIGNVARNAME          =&BIGNVARNAME,    
         COUNTDISTINCTWHATVAR =&COUNTDISTINCTWHATVARPOP,
         DSETINTOADDBIGN      =&L_WORKDATA,
         DSETINTOCOUNT        =&L_PREFIX.POP,
         DSETOUT              =&L_PREFIX.BIGNOUT, 
         GROUPBYVARS          =&GROUPBYVARPOP,
         TOTALID              =&L_TOTALID
         )
         
      %IF &g_abort EQ 1 %THEN %GOTO macerr;          
      
      %***- convert BIGNVARNAME to character because the function is removed form tu_align -***;      
      DATA &l_prefix.bignout;
         SET &l_prefix.bignout;
         LENGTH &L_PUBLICVAR $20;
         DROP &BIGNVARNAME;
         &L_PUBLICVAR=&BIGNVARNAME;
      RUN;
      
      DATA &l_prefix.bignout;
         SET &l_prefix.bignout;
         RENAME &L_PUBLICVAR=&BIGNVARNAME;
      RUN;
            
      %LET l_workdata=&l_prefix.bignout;  
            
      %IF &g_debug GE &l_debug %THEN %DO ;
      
         %PUT ===============================================================;
         %PUT DEBUG: &sysmacroname: Debug information at level &l_debug;
         %PUT ===============================================================;
      
         PROC PRINT DATA=&l_workdata;
            TITLE "Output from TU_ADDBIGNVAR: &L_WORKDATA";
         RUN;
         
         PROC CONTENTS DATA=&l_workdata;
            TITLE "Contents of Output from TU_ADDBIGNVAR: &L_WORKDATA";
         RUN;
      
      %END;    
   
   %END;
   
   %***---------------------------------------------------------------------***;
   %***- Call tu_labelvars to add label to data set.                       -***;
   %***---------------------------------------------------------------------***;

   %LET l_debug=%eval(&l_debug - 1);
                                          
   %IF &LABELVARSYN EQ Y %THEN %DO;
   
      %tu_labelvars(
         DSETIN   =&L_WORKDATA,  
         DSETOUT  =&L_PREFIX.LABELOUT,  
         STYLE    =&VARLABELSTYLE    
         )
         
      %IF &g_abort EQ 1 %THEN %GOTO macerr;  
         
      %LET l_workdata=&l_prefix.labelout;  
     
      %IF &g_debug GE &l_debug %THEN %DO ;
       
         %PUT ===============================================================;
         %PUT DEBUG: &sysmacroname: Debug information at level &l_debug;
         %PUT ===============================================================;
  
         PROC CONTENTS DATA=&l_workdata;
            TITLE "Output from TU_LABELVARS: &L_WORKDATA";
         RUN;
         
      %END; 
      
   %END;
      
   %***---------------------------------------------------------------------***;
   %***- Call tu_align to re-alignment the fields.                         -***;
   %***---------------------------------------------------------------------***;
   
   %LET l_debug=%eval(&l_debug - 1);
  
   %IF &ALIGNYN EQ Y %THEN %DO;
  
      %tu_align(
         DSETIN        =&L_WORKDATA,      
         VARSIN        =&BIGNVARNAME &L_STATSVARLIST,      
         ALIGNMENT     =R,
         COMPRESSCHRYN =Y,
         DP            =.,
         DSETOUT       =&L_PREFIX.ALIGNOUT,           
         NCSPACES      =1,
         VARSOUT       =
         )
                          
      %IF &g_abort EQ 1 %THEN %GOTO macerr;
      
      %LET l_workdata=&l_prefix.alignout;        
      
      %IF &g_debug GE &l_debug %THEN %DO ;   
         
         %PUT ===============================================================;
         %PUT DEBUG: &sysmacroname: Debug information at level &l_debug;
         %PUT ===============================================================;
          
         PROC PRINT DATA=&l_workdata;
            TITLE "Output from TU_ALIGN: &L_WORKDATA";
         RUN;
         
         PROC CONTENTS DATA=&l_workdata;
            TITLE "Contents of Output from TU_ALIGN: &L_WORKDATA";
         RUN;
         
      %END;
      
   %END; 
    
   %LET g_debug=0;
   
   %***---------------------------------------------------------------------***;
   %***- Optimize the length of new added character variables and create   -***;
   %***- output dataset.                                                   -***;
   %***---------------------------------------------------------------------***;
   
   DATA _NULL_;
      SET &l_workdata(KEEP=&ANALYSISVARNAME) end=end;
      RETAIN &analysisvarordervarname 0;
      
      &analysisvarordervarname=max(&analysisvarordervarname, length(&ANALYSISVARNAME));
      
      IF END THEN DO;
         CALL SYMPUT('l_i1', compress(&analysisvarordervarname));
      END;
                  
   RUN;
      
   %***- Apply the POSTSUBSET statement -***;
   %IF %nrbquote(&POSTSUBSET) NE %THEN %DO;         
      DATA &l_workdata;
         SET &l_workdata;
         IF &POSTSUBSET;                                             
      RUN; 
      
      %IF &SYSERR GT 0 %THEN %DO;
         %PUT %str(RTERR)OR: &sysmacroname: There are errors in the statements given by POSTSUBSET ;
         %GOTO macerr;
      %END;            
   %END;
   
   DATA &G_DDDATASETNAME(label="&DDDATASETLABEL");
      LENGTH &ANALYSISVARNAME $&l_i1.;
      SET &l_workdata;
   RUN;    
   
   %LET l_workdata=&G_DDDATASETNAME;
   
   %***---------------------------------------------------------------------***;
   %***- If no display required, exit the macro.                           -***;
   %***---------------------------------------------------------------------***;
   
   %IF %nrbquote(&display) NE Y %THEN %DO;
      %PUT ;
      %PUT %str(RTNO)TE: &sysmacroname: No display required. Macro Exits without creating a display.;
      %PUT;
      %GOTO endmac;
   %END;    
                         
   %***---------------------------------------------------------------------***;
   %***---------------------------------------------------------------------***;
   %DISPLAYIT:
   %***---------------------------------------------------------------------***;
   %***---------------------------------------------------------------------***;
                                           
   %***---------------------------------------------------------------------***;        
   %***- Call tu_list to create output. Parameters, except DSETIN and      -***;           
   %***- GETDATAYBN, are passed direcly from the parameters of this macro. -***;
   %***---------------------------------------------------------------------***;
                                  
   %tu_list(
      DSETIN                   =&l_workdata,  
      GETDATAYN                =N,  
      LABELVARSYN              =N, 
        
      BREAK1                   =&BREAK1,  
      BREAK2                   =&BREAK2,  
      BREAK3                   =&BREAK3,  
      BREAK4                   =&BREAK4,  
      BREAK5                   =&BREAK5,  
      BYVARS                   =&BYVARS,  
      CENTREVARS               =&CENTREVARS,  
      COLSPACING               =&COLSPACING,  
      COLUMNS                  =&COLUMNS,  
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
      PAGEVARS                 =&PAGEVARS,  
      PROPTIONS                =&PROPTIONS,  
      RIGHTVARS                =&RIGHTVARS,
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
      )
 
 
   %IF &g_abort EQ 1 %THEN %GOTO macerr;
   %GOTO endmac;
   
   %***---------------------------------------------------------------------***;  
   %***---------------------------------------------------------------------***;
   %MACERR:
   %***---------------------------------------------------------------------***;  
   %***---------------------------------------------------------------------***;
   %LET g_abort=1;
      
   %PUT;
   %PUT %str(RTNO)TE: --------------------------------------------------------;
   %PUT %str(RTNO)TE: &sysmacroname completed with error(s);
   %PUT %str(RTNO)TE: --------------------------------------------------------;
   %PUT;
   
   %IF &g_debug NE 0 %THEN %GOTO EXITMAC;
   
   %tu_abort(OPTION=FORCE)
   
   %***---------------------------------------------------------------------***;  
   %***---------------------------------------------------------------------***;
   %ENDMAC:
   %***---------------------------------------------------------------------***;  
   %***---------------------------------------------------------------------***;

   %***---------------------------------------------------------------------***;
   %***- Call tu_tideup to clear temporary data set and fiels.             -***;
   %***---------------------------------------------------------------------***;
   
   %IF &g_debug NE 0 %THEN %GOTO EXITMAC;
                                        
   %tu_tidyup(      
      RMDSET =&L_PREFIX:,
      GLBMAC =NONE
      )
      
   %***---------------------------------------------------------------------***;  
   %***---------------------------------------------------------------------***;
   %EXITMAC:
   %***---------------------------------------------------------------------***;  
   %***---------------------------------------------------------------------***;
     

%MEND tu_sumstatsincols;


