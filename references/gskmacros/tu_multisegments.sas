/*----------------------------------------------------------------------------+ 
| Macro Name    : tu_multisegments.sas                                             
|
| Macro Version : 4
|                                                                            
| SAS version   : SAS v8.2                                                   
|                                                                            
| Created By    : Lee Seymour                                                          
|                                                                         
| Date          : Aug 2003                                                           
|                                                                            
| Macro Purpose : 
|
| This unit shall create a data display containing a mixture of frequency 
| counts, percentages and summary statistics.Each segment of the display/output 
| dataset shall be produced from output datasets from tu_sumstatsinrows and 
| tu_freq .
| It may also be used to produce data displays where the input dataset for each 
| segment is different.
| The order of the analysis variables in the data display will be based on the 
| order for each of the segments
|
|                                                                            
| Macro Design  :  Procedure style macro                                                          
|                                                                            
| Input Parameters :                                                         
|                                                                            
| NAME         DESCRIPTION                                            DEFAULT                           
|------------------------------------------------------------------------------
|                                                                            
| SEGMENT1    Each segment shall contain a call to either tu_freq 
|             or tu_sumstatsinrows and appropriate parameters for 
|             the macro to create an output dataset. 
|             The percentage sign shall not be used as a prefix
|             to the macro name, and the parameters shall not be 
|             surrounded by brackets, i.e. the following style shall
|             be used:  segment1=MacroName parm1=value1, parm2=value2
|
|             Valid values: 
|             A complete call to tu_freq or ru_sumstatsinrows 
|
| SEGMENT2-20 As above
|
| ALIGNYN     Execute tu_align macro : Yes or No                         Y
|
| ACROSSCOLVARPREFIX    Passed directly to tu_denorm.
|                       Specifies the prefix(es) used in forming the names of      tt_result
|                       variables created by PROC TRANSPOSE. Any list of prefixes
|                       will be associated with the corresponding variable in
|                       VARSTODENORM. If nothing is specified to
|                       ACROSSCOLVARPREFIX or a prefix corresponding to a variable
|                       in VARSTODENORM does not exist then the name of the
|                       variable in VARSTODENORM is used as a prefix. The
|                       following example may make this clearer:  Multiple
|                       variables in VARSTODENORM cause multiple calls to
|                       PROC TRANSPOSE. Each call to proc transpose results in a
|                       different variable being passed to the PROC TRANSPOSE
|                       PREFIX statement. If there are 2 variables specified in
|                       VARSTODENORM then on the second call to PROC TRANSPOSE
|                       the second variable listed in ACROSSCOLVARPREFIX will be
|                       passed to the PROC TRANSPOSE PREFIX statement. If no
|                       second variable is specified to ACROSSCOLVARPREFIX then
|                       the name of the second variable in VARSTODENORM will be
|                       passed to the PROC TRANSPOSE PREFIX statement. In this
|                       case if a third variable is specified to
|                       ACROSSCOLVARPREFIX, it will have no effect.
|                       Note on use of prefix in Reporting Tools: PROC REPORT
|                       COLUMNS statement accepts a variable prefix in the form eg
|                       myCol: to display all columns whose name commences with the
|                       prefix.
|                       Valid values:
|                       Blank, or one or more words, each word comprising of
|                       characters permitted in the first section of a SAS
|                       variable name.
|                       Total number of words should be less than or equal to the
|                       number of variables specified in VARSTODENORM.
|
|
| ACROSSVAR   Specifies a variable that has multiple levels and will   &g_trtcd
|             be transposed to multiple columns. 
|             Valid values: a SAS variable that exists in the stacked 
|             output dataset. Required if DENORMYN=Y. This parameter 
|             must have the same value as ACROSSVAR in each of the 
|             segment macro calls.
|
| ACROSSVAR   Specifies the name of a variable that contains decoded   &g_trtgrp
| DECODE      values of ACROSSVAR 
|             Valid values: Blank, or a SAS variable that 
|             exists in DSETIN
|
| ACROSSVARLISTNAME     Specifies the name of the macro variable that %TU_DENORM   none
|                       will update with the names of the variables created by
|                       the transpose of the first variable that is specified in
|                       VARSTODENORM. In most cases the macro variable is LOCAL
|                       to the program that called %tu_DENORM.
|                       Valid values: SAS macro variable name.
|
| ADDBIGNYN   Append the population N (N=nn) to the label of the         Y
|             transposed columns containing the results - Y/N?
|             Valid Values: Y, N
|
| DENORMYN    Transpose result variables from rows to columns            Y
|             across the ACROSSVAR = Y/N?.
|             Valid values: Y or N
|
| DDNAME      Name of dataset storing default values in the XML
|             defaults file.
|
| DISPLAY     Specifies whether the report should be created.
|             Valid Values: Y or N. If &g_analy_disp is D, DISPLAY 
|             shall be ignored
|
| DSETIN      Name of dataset that will override input dataset names
|             specified in XML defaults file, but will not override
|             any input datasets specified via segment<n> parameters.
|
| DSETOUT     Specifies the name of the output summary dataset.
|             Valid values: Blank, or a valid SAS dataset name
|
| VARSTODENORM  Specifies the name of the variable to be transposed.   tt_result
|             Valid values: a SAS variable that exists in the stacked 
|             output dataset.In a %tu_freq segment this value must be 
|             the same as ACROSSCOLVARPREFIX. In a %tu_sumstatsinrows 
|             segment this value must be the same as RESULTVARNAME.
|
| XMLDEFAULTS Text string equivalent to pathname of the XML file
|             storing default parameter values for each of the 
|             segments.
|
| YNDECODEFMT Blank, or a SAS format that maps the Yes/No variables    $yndecod.
|             to decode text (i.e. Yes, No etc) that will be
|             printed on the data display. 
|
| YNORDERFMT Blank, or a SAS format that maps the Yes/No variables to  $ynorder.
|            numbers stored as text (i.e. 1, 2, 3 etc, rather 
|            than 1, 2, 3 etc), which will be used for sorting the 
|            output on the data display.
|
| YNVARS     Blank, or list of Yes/No variables                        
|
|------------------------------------------------------------------------------
| Parameters, with defaul values, that pass to macro TU_LIST
|     BREAK1-BREAK5=(Blank), BYVARS=(Blank), CENTREVARS=(Blank), COLSPACING=2, 
|     COLUMNS=(Blank),COMPUTEBEFOREPAGELINES=(Blank), 
|     COMPUTEBEFOREPAGEVARS=(Blank),DDDATASETLABEL=DD dataset for a table, 
|     DEFAULTWIDTHS=(Blank), DESCENDING=(Blank),DISPLAY=Y, FLOWVARS=_All_, 
|     FORMATS=(Blank), IDVARS=(Blank), LABELS=(Blank),LEFTVARS=(Blank), 
|     LINEVARS=(Blank), NOPRINTVARS=(Blank), NOWIDOWVAR=(Blank),  
|     ORDERDATA=(Blank), ORDERFREQ=(Blank), ORDERVARS=(Blank), 
|     ORDERFORMATTED=(Blank),OVERALLSUMMARY=N, PAGEVARS=(Blank), 
|     PROPTIONS=Headline, RIGHTVARS=(Blank),SHARECOLVARS=(Blank), 
|     SHARECOLVARSINDENT=2, SKIPVARS=(Blank), SPLITCHAR=~, 
|     STACKVAR1-STACKVAR15=(Blank), VARSPACING=(Blank), WIDTHS=(Blank)   
|------------------------------------------------------------------------------
|   
|                                                                            
| Output:   1. an output file in plain ASCII text format containing a summary in
|              columns data display matching the requirements specified as input 
|              parameters. 
|           2. SAS data set that forms the foundation of the data display (the 
|              "DD dataset").
|
|                                                                            
| Global macro variables created: none                                          
|                                                                            
|                                                                            
| Macros called : 
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_pagenum
| (@) tu_chknames
| (@) tu_chkvarsexist
| (@) tu_freq
| (@) tu_sumstatsinrows
| (@) tu_varattr
| (@) tu_nobs
| (@) tu_words
| (@) tu_list
| (@) tu_denorm
| (@) tu_align
| (@) tu_abort
| (@) tu_tidyup
|                                                                            
| ************************************************************************** 
| Change Log :                                                               
|                                                                            
| Modified By : Lee Seymour                                                            
| Date of Modification : 07OCT2003                                                    
| New Version Number : 1/2                                                      
| Modification ID :                                                          
| Reason For Modification : Source code review amendments
|
|***************************************************************************
|                                                                            
| Modified By : Lee Seymour                                                              
| Date of Modification :13OCT2003                                                     
| New Version Number : 1/3                                                      
| Modification ID :                                                          
| Reason For Modification : Moved local macro variable declarations. 
|                           Changed varsin=&varstodenorm to varsin=tt_result 
|                           in  tu_align call.                                                 
|
|***************************************************************************
|                                                                            
| Modified By : Tamsin Corfield                                                            
| Date of Modification :21OCT2003                                                     
| New Version Number : 1/4                                                      
| Modification ID :     None                                                    
| Reason For Modification : Removed ; from comment of pagevars and 
|                           skipvars in order that the macro could be 
|                           checked into the application.
|
|***************************************************************************
|                                                                            
| Modified By :              Yongwei Wang                                                            
| Date of Modification :     24Sep2004                                                     
| New Version Number :       2/1                                                      
| Modification ID :          YW001
| Reason For Modification :  Changed 'alignment=L' to 'alignment=R' in
|                            the call of tu_align. Changed '&GOTO' to '%GOTO'
|
|***************************************************************************
|                                                                            
| Modified By :              Shan Lee                                                            
| Date of Modification :     11Apr2006                                                     
| New Version Number :       3/1                                                      
| Modification ID :          
| Reason For Modification :  Incorporate code that is equivalent to the 
|                            pre-processing that previously appeared in td_dm1
|                            and td_dm3 just before the call to 
|                            tu_multisegments, and incorporate other enhancements
|                            specified in HRT0104.
|***************************************************************************
|                                                                            
| Modified By :              Shivam Kumar                                                            
| Date of Modification :     23Oct2013                                                     
| New Version Number :       4/1                                                      
| Modification ID :          
| Reason For Modification :  To Remove repeated %then  
+----------------------------------------------------------------------------*/
%macro tu_multiSegments(
   segment1 =  ,   /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   segment2 =  ,   /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   segment3 =  ,   /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   segment4 =  ,   /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   segment5 =  ,   /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   segment6 =  ,   /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   segment7 =  ,   /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   segment8 =  ,   /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   segment9 =  ,   /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   segment10 =  ,  /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   segment11 =  ,  /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   segment12 =  ,  /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   segment13 =  ,  /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   segment14 =  ,  /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   segment15 =  ,  /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   segment16 =  ,  /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   segment17 =  ,  /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   segment18 =  ,  /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   segment19 =  ,  /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   segment20 =  ,  /* Call to tu_freq or tu_sumstatsinrows and appropriate parameters, contained within %nrstr() */
   acrossColVarPrefix       = tt_result, /* Text passed to the PROC TRANSPOSE PREFIX statement in tu_denorm. */
   acrossvar                = &g_trtcd,  /* Variable(s) that will be transposed to columns   */
   acrossvardecode          = &g_trtgrp, /* The name of the decode variable(s) for ACROSSVAR */
   acrossVarListName        =,         /* Macro variable name to contain the list of columns created by the transpose of the first variable in VARSTODENORM.*/
   addbignyn                = Y ,      /* Append the population N (N=nn) to the label of the transposed columns containg the results - Y/N */
   alignyn                  = Y,       /* Control execution of tu_align */
   break1                   =,         /* Break statements. */
   break2                   =,         /* Break statements. */
   break3                   =,         /* Break statements. */
   break4                   =,         /* Break statements. */
   break5                   =,         /* Break statements. */
   byvars                   =,         /* By variables */
   centrevars               =,         /* Centre justify variables */
   colspacing               =2,        /* Overall spacing value. */
   columns                  =tt_segorder tt_grplabel tt_code1 tt_decode1 tt_result:, /* Column parameter */
   computebeforepagelines   =,         /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt colon labelvar)*/
   computebeforepagevars    =,         /* Names of variables that shall define the sort order for  Compute Before Page lines */
   dddatasetlabel           =DD dataset for a table, /* Label to be applied to the DD dataset */
   ddname                   =MSEG,     /* Name of data display macro without td_ prefix */
   defaultwidths            =,         /* List of default column widths */
   denormyn                 =Y,        /* Transpose result variables from rows to columns across the ACROSSVAR - Y/N? */
   descending               =,         /* Descending ORDERVARS */
   display                  =Y,        /* Specifies whether the report should be created Valid Values Y or N. If &g_analy_disp is D, DISPLAY shall be ignored*/
   dsetin                   =,         /* DSETIN for all segments.*/
   dsetout                  =,         /* Output summary dataset */          
   flowvars                 =_ALL_,    /* Variables with flow option */
   formats                  =,         /* Format specification */
   idvars                   =,         /* ID variables    */
   labels                   =,         /* Label definitions. */
   labelvarsyn              =Y,        /* Control execution of tu_labelvars */
   leftvars                 =,         /* Left justify variables */
   linevars                 =,         /* Order variable printed with line statements. */
   noprintvars              =tt_segorder tt_code1, /* No print vars (usually used to order the display) */
   nowidowvar               =,         /* Not in Version 1 */
   orderdata                =,         /* ORDER=DATA variables */ 
   orderformatted           =,         /* ORDER=FORMATTED variables */ 
   orderfreq                =,         /* ORDER=FREQ variables */ 
   ordervars                =tt_segorder  tt_grplabel tt_code1 , /* Order variables */ 
   overallsummary           =N,        /* Overall summary line at top of tables */
   pagevars                 =,         /* Break after <var> / page */ 
   postsubset               =,         /* SAS expression to be applied to data immediately prior to creation of the permanent presentation dataset */
   proptions                =headline, /* PROC REPORT statement options */ 
   rightvars                =,         /* Right justify variables */
   sharecolvars             =,         /* Order variables that share print space. */
   sharecolvarsindent       =2,        /* Indentation factor */
   skipvars                 =tt_segorder , /* Break after <var> / skip */ 
   splitchar                =~,        /* Split character */ 
   stackvar1                =,         /* Create Stacked variables (e.g. stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */ 
   stackvar2                =,         /* Create Stacked variables (e.g. stackvar2=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */ 
   stackvar3                =,         /* Create Stacked variables (e.g. stackvar3=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */ 
   stackvar4                =,         /* Create Stacked variables (e.g. stackvar4=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */ 
   stackvar5                =,         /* Create Stacked variables (e.g. stackvar5=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */ 
   stackvar6                =,         /* Create Stacked variables (e.g. stackvar6=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */ 
   stackvar7                =,         /* Create Stacked variables (e.g. stackvar7=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */ 
   stackvar8                =,         /* Create Stacked variables (e.g. stackvar8=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */ 
   stackvar9                =,         /* Create Stacked variables (e.g. stackvar9=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */  
   stackvar10               =,         /* Create Stacked variables (e.g. stackvar10=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */ 
   stackvar11               =,         /* Create Stacked variables (e.g. stackvar11=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */ 
   stackvar12               =,         /* Create Stacked variables (e.g. stackvar12=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */ 
   stackvar13               =,         /* Create Stacked variables (e.g. stackvar13=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */ 
   stackvar14               =,         /* Create Stacked variables (e.g. stackvar14=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */ 
   stackvar15               =,         /* Create Stacked variables (e.g. stackvar15=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */ 
   varlabelstyle            =SHORT,    /* Specifies the label style for variables (SHORT or STD) */  
   varspacing               =,         /* Spacing for individual variables. */  
   varstodenorm             =tt_result, /* Variable to be transposed */
   widths                   =tt_grplabel 9  tt_decode1 19 tt_result0001-tt_result9999 13, /* Column widths */   
   xmldefaults              =,         /* Location and name of XML defaults file for td macro*/
   yndecodefmt              =$yndecod.,/* Format for creating decode variables corresponding to YNVARS */
   ynorderfmt               =$ynorder.,/* Format for creating order variables corresponding to YNVARS */
   ynvars                   =          /* List of Yes/No variables that require codes and decodes */
);
   
   %local MacroVersion;
   %let MacroVersion = 4;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals(varsin=g_dddatasetname g_analy_disp)

   /*
   / Initialise local macro variables created within macro
   /-------------------------------------------------------------*/

   %local
      prefix           /* root name for temp data sets                         */
      ns               /* Total Number of populated segments in macro call     */
      s                /* Segment number                                       */
      w                /* Segment number                                       */
      segtype          /* Macro for the segment TU_FREQ or TU_SUMSTATSINROWS   */
      setlength        /* Length statement to ensure that each variable has same length from all segment output datasets */
      sexseg           /* Flag for segment containing frequency count of SEX, required to create decode */
      firstAcrossvar   /* First acrossvar variable (usually, there is only one) */
      stratifiedVars0  /* Stratification variables */
      newStratifiedVars /* Used to re-build stratifiedVars&s without acrossvars or variables not in dataset prior to denorm */   
      mixtype          /* List of variable wih datatype mismatches across segments*/
      rc               /* Return code from call to tu_nobs */
      newAcrossvardecode /* Used to re-build acrossvardecode with names of newly created variables in place of formats. */
      numAcrossvar       /* Number of ACROSSVAR variables. */
      originalAcrossvardecode /* Value of acrossvardecode specified by user. */
      lastGroupbyvarpop  /* Last GROUPBYVARPOP variable specified for segment 1 */
      groupbyvarpop      /* All GROUPBYVARPOP variables specified for segment 1 */
      m                  /* Counter used for %do ... %while processing. */
      n                  /* Counter used for %do ... %while processing. */
      currentWord        /* Stores current word when processing a list in a %do ... %while loop. */
      tt_bnnm            /* Stores name of "big N" variable, if needed in call to tu_denorm, otherwise set to missing. */
      groupbyvarsName    /* Name of 'groupbyvars' parameter for current segment. */
      dsetinName         /* Name of input dataset parameter for current segment. */
      groupbyvarsValue   /* Value of 'groupbyvars' for current segment. */
      dsetinValue        /* Input dataset name for current segment. */
      ynvar              /* Yes/No variable that exists in 'groupbyvars' for the current segment. */
      ynvarList          /* List of all Yes/No variables that exists in 'groupbyvars' for the current segment. */
      openParen          /* Open parenthesis position in the macro variables stratifiedVars(s) */
      closeParen         /* Close parenthesis position in the macro variables stratifiedVars(s) */
      lastDset           /* Stores a dataset's name of interest */
      notExistVars       /* Flag indicating if the stratifiedVar variables exist in a dataset */
      ;

   /* 
   /  Delete any currently existing display file 
   /----------------------------------------------------------------------*/
				
   %tu_pagenum(usage=DELETE)  
   %IF %nrbquote(&g_abort) EQ 1 %THEN
   %do;
	%tu_abort(option=force);
   %end; 
       
   /*
   /  IF GD_ANALY_DISPLAY is D, goto display.
   /----------------------------------------------------------------------*/
   
   %IF %nrbquote(&G_ANALY_DISP) = D %THEN %DO;
   %***- check if data set G_DDDATASETNAME exist and is not empty -***;
   %LET rc=%tu_nobs(&G_DDDATASETNAME);
   %IF &g_abort EQ 1 %THEN %GOTO MAcerr;  /* YW001 */
   
   %IF &rc EQ -1 %THEN %DO;
       %PUT RTE%str(RROR:) &sysmacroname: input data set G_DDDATASETNAME=&G_DDDATASETNAME does not exist;
       %GOTO MacErr;
   %END;
   %LET lastDset=&G_DDDATASETNAME;
   %GOTO DISPLAYIT;
   %END;
	
   /*--------------------------------------------------------------------------
   / --------------------------------------------------------------------------
   / Delete G_DDDATASETNAME dataset.
   / --------------------------------------------------------------------------
   / --------------------------------------------------------------------------
   */
   %IF %nrbquote(&DSETOUT) EQ %THEN %DO;        
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
   %END;    

   /*
   / Parameter validation 
   /------------------------------------------------*/
    
   %if %upcase(&denormyn) eq Y  %then
   %do;

      %if %tu_chknames(&varstodenorm,VARIABLE) ne %then
      %do;
         %put %str(RTE)RROR: &sysmacroname : Value for VARSTODENORM is not a valid SAS name. Macro will abort.; 
         %let g_abort=1;
      %end;
      %if &varstodenorm eq %then
      %do;
         %put %str(RTE)RROR: &sysmacroname : DENORMYN is Y but VARSTODENORM is missing. Macro will abort;
         %let g_abort=1;
      %end;

      %if %length(&acrossvar) eq 0 %then
      %do;
         %put %str(RTE)RROR: &sysmacroname : DENORMYN is Y but ACROSSVAR is missing. Macro will abort.; 
         %let g_abort=1;
      %end;
      %if %length(%tu_chknames(&acrossvar,VARIABLE)) ne 0 %then
      %do;
         %put %str(RTE)RROR: &sysmacroname : Value for ACROSSVAR is not one or more valid SAS names. Macro will abort.; 
         %let g_abort=1;
      %end;

      %if %qupcase(&addbignyn) eq Y %then
      %do n = 1 %to %tu_words(&acrossvardecode);
        %let currentWord = %scan(&acrossvardecode, &n, %str( ));
        %if %index(&currentWord, .) eq 0 %then
        %do;
          %if %length(%tu_chknames(&currentWord, VARIABLE)) ne 0 %then
          %do;
            %put %str(RTE)RROR : &sysmacroname : ACROSSVARDECODE(&ACROSSVARDECODE) contains a word that is neither a format nor a valid SAS variable name;
            %let g_abort = 1;
          %end;
        %end;     
      %end;

      %if %length(&addbignyn) eq 0 %then
      %do;
        %put %str(RTE)RROR: &sysmacroname: denormalisation has been requested, but ADDBIGNYN has not been specified; 
        %let g_abort=1;
      %end;

   %end; /* %if %upcase(&denormyn) eq Y  %then */

   /*
   / If ADDBIGNYN is non-blank, then it must be either Y or N.
   /------------------------------------------------------------------------------*/ 

   %if %length(&addbignyn) gt 0 %then
   %do;
      %if %upcase(&addbignyn) ne Y and %upcase(&addbignyn) ne N %then
      %do;
        %put %str(RTE)RROR: &sysmacroname : Value for ADDBIGNYN must be Y or N.  macro will abort;
        %let g_abort=1;
      %end; 
   %end;

   /*
   / If both ACROSSVAR and ACROSSVARDECODE are non-blank, then the number of words
   / in each of these parameters should be the same.
   /------------------------------------------------------------------------------*/ 

   %if %length(&acrossvar) ne 0 and %length(&acrossvardecode) ne 0 %then
   %do;
     %if %tu_words(&acrossvar) ne %tu_words(&acrossvardecode) %then 
     %do;
       %put %str(RTE)RROR: &sysmacroname: number of words in ACROSSVAR (&acrossvar) is ;
       %put not equal to number of words in ACROSSVARDECODE (&acrossvardecode);
       %let g_abort=1;
     %end;
   %end;

   /*
   / Check that varstodenorm is valid and only contain one word
   /------------------------------------------------------------------------------*/ 
        
   %let wordList = varstodenorm;
   %do i = 1 %to %tu_words(&wordList);
         %let thisWord = %scan(&wordList, &i);
         %if %tu_words(&&&thisWord) gt 1 %then %do;
             %put RTE%str(RROR:) &sysmacroname.: Macro Parameter %upcase(&thisWord) must contain just ONE variable %upcase(&thisWord)=&&&thisWord ;
             %let g_abort=1;
         %end;      
   %end; 

   /*
   / If XMLDEFAULTS is not blank, then check that DDNAME is not blank and 
   / corresponds to a valid SAS name.
   /----------------------------------------------------------------------------*/

   %if %length(&xmldefaults) gt 0 %then
   %do;
      %if %length(&ddname) eq 0 %then
      %do;
        %put %str(RTE)RROR: &sysmacroname: XML defaults file specified, so DDNAME should also be specified;
        %let g_abort = 1;
      %end;
      %else %if %tu_chknames(&ddname, DATA) ne %then
      %do;
        %put %str(RTE)RROR: &sysmacroname: XML defaults file specified, so DDNAME should correspond to a valid SAS dataset name;
        %let g_abort=1;
      %end; 
   %end;

   /*
   / If DSETIN is non-blank, then check that it corresponds to a valid SAS dataset
   / name, and check that this dataset exists.
   /----------------------------------------------------------------------------*/
   
   %if %length(&dsetin) gt 0 %then
   %do;
      %if %tu_chknames(&dsetin, DATA) ne %then
      %do;
        %put %str(RTE)RROR: &sysmacroname : DSETIN parameter should correspond to a valid SAS dataset name, macro will abort;
        %let g_abort=1;
      %end; 
      %else %if %sysfunc(exist(&dsetin)) eq 0 %then 
      %do;
        %put %str(RTE)RROR: &sysmacroname : DSETIN parameter corresponds to a dataset that does not exist;
        %let g_abort = 1;
      %end;
   %end;

   /*
   / Check that DSETOUT corresponds to a valid SAS name.
   /----------------------------------------------------------------------------*/

   %if &dsetout ne %then
   %do;
      %if %tu_chknames(&dsetout, DATA) ne %then
      %do;
        %put %str(RTE)RROR: &sysmacroname : DSETOUT parameter should correspond to a valid SAS dataset name, macro will abort;
        %let g_abort=1;
      %end; 
   %end;

   /*
   / If DSETOUT is not given, then DISPLAY should not be N.
   /----------------------------------------------------------------------------*/

   %if %length(&dsetout) eq 0 %then
   %do;
      %if &display eq N %then 
      %do;
        %put %str(RTE)RROR: &sysmacroname : DSETOUT is not specified, so DISPLAY should not be N;
        %let g_abort=1;
      %end; 
   %end;
   
   /*
   / Value for alignyn must be y or n
   /----------------------------------------------------------------------------*/
   
   %if %upcase(&alignyn) ne Y and %upcase(&alignyn) ne N %then
   %do;
        %put %str(RTE)RROR: &sysmacroname : Value for ALIGNYN must be a y or n.  macro will abort;
   %let g_abort=1;
   %end; 

   /*
   / Value for denormyn must be y or n
   /----------------------------------------------------------------------------*/
   
   %if %upcase(&denormyn) ne Y and %upcase(&denormyn) ne N %then
   %do;
        %put %str(RTE)RROR: &sysmacroname : Value for DENORMYN must be a y or n.  macro will abort;
   %let g_abort=1;
   %end;    
    
   /*
   / Value for display must be y or n
   /----------------------------------------------------------------------------*/
   
   %if %upcase(&display) ne Y and %upcase(&display) ne N %then
   %do;
        %put %str(RTE)RROR: &sysmacroname : Value for DISPLAY must be a y or n.  macro will abort;
   %let g_abort=1;
   %end;     
     
   /* 
   / Identify number of populated segments
   /----------------------------------------------------------------------------*/

   %let ns = 0;
   %do s = 1 %to 20;
     %local segment&s;
     %if %nrbquote(&&segment&s) ne  %then %let ns = %eval(&ns + 1);
   %end;
    
   /*
   / If no segments populated then abort
   /------------------------------------*/
    
   %if &ns eq 0 %then
   %do;
        %put %str(RTE)RROR : &sysmacroname : No segments populated. macro will abort;
        %let g_abort=1;
   %end;
    
   /*
   / If segment1 is not populated
   /------------------------------------*/
    
   %if %length(&segment1) eq 0 %then
   %do;
        %put %str(RTE)RROR : &sysmacroname : Segment1 is not populated. macro will abort;
        %let g_abort=1;
   %end;
    
   /*
   / If YNVARS is non-blank, then:
   /   YNVARS must be a list of valid SAS variable names.
   /   YNORDERFMT must be non-blank - if a list is specified, then only first word
   /   shall be considered.
   /   YNDECODEFMT must be non-blank - if a list is specified, then only first word
   /   shall be considered.
   /----------------------------------------------------------------------------*/

   %if %length(&ynvars) gt 0 %then
   %do;

     %if %length(%tu_chknames(&ynvars, VARIABLE)) ne 0 %then
     %do;
       %put %str(RTE)RROR: &sysmacroname: YNVARS (&YNVARS) must be blank or list of one or more variables;
       %let g_abort = 1;
     %end;

     %if %length(&ynorderfmt) eq 0 %then 
     %do;
       %put %str(RTE)RROR: &sysmacroname: YNVARS is non-blank, so YNORDERFMT must be non-blank;
       %let g_abort = 1;
     %end;
     %else %if %tu_words(&ynorderfmt) ne 1 %then
     %do;
       %put %str(RTW)ARNING: &sysmacroname: YNORDERFMT should specify just one format - only the first format will be considered;
       %let ynorderfmt = %scan(&ynorderfmt, 1, %str( ));
     %end;
     
     %if %length(&yndecodefmt) eq 0 %then 
     %do;
       %put %str(RTE)RROR: &sysmacroname: YNVARS is non-blank, so YNDECODEFMT must be non-blank;
       %let g_abort = 1;
     %end;
     %else %if %tu_words(&yndecodefmt) ne 1 %then
     %do;
       %put %str(RTW)ARNING: &sysmacroname: YNDECODEFMT should specify just one format - only the first format will be considered;
       %let yndecodefmt = %scan(&yndecodefmt, 1, %str( ));
     %end;

   %end; /* %if %length(&ynvars) gt 0 %then */

   /*
   / If XMLDEFAULTS is a non-blank text string, then it must correspond to the pathname of a file
   / that exists.
   /-----------------------------------------------------------------------------------------------*/

   %if %length(&xmldefaults) gt 0 %then
   %do;
     %if %sysfunc(fileexist(&xmldefaults)) eq 0 %then
     %do;
       %put %str(RTE)RROR: &sysmacroname: XMLDEFAULTS (&xmldefaults) specifies the pathname of a file that does not exist;
       %let g_abort = 1;
     %end;
   %end;

   /*
   /  Call tu_abort to pick up initial errors in parameter
   /  validation.
   /--------------------------------------------------------*/
   
   %if &g_abort eq 1 %then
   %do;
      %tu_abort(option=force);
      %GOTO MacErr;
   %end;
   

   /*
   / Normal processing. 
   /--------------------------------------------------------*/
      

   /* Assign prefix for work datasets */

   %let prefix = _multisegments;

   /* XML libname for segment defaults */

   %if %length(&xmldefaults) gt 0 %then
   %do;
     libname xmldef xml "&xmldefaults";
   %end;

   /* Identify the first acrossvar variable (usually, there is only one). */

   %let firstAcrossvar = %upcase(%scan(&acrossvar, 1));  

   /*
   / Store original value of acrossvardecode parameter.
   /------------------------------------------------------------*/

   %let originalAcrossvardecode = &acrossvardecode;   


   /* Process each segment.
   /     Identify segment type (segtype), either a frequency
   /     call or a summary statistics call
   /
   /     Overide segment dsetins if required
   /
   /     Read in XML defaults file
   /
   /     Build dataset containing parameter name and value
   /
   /     Create segment macro call from parameter dataset
   /
   /---------------------------------------------------------------*/

   %do s = 1 %to &ns;

      /*
      / Identify what segment is to be called based on parameters
      /--------------------------------------------------------------*/

      %if %index(%bquote(%upcase(&&segment&s)),ANALYSISVARS) ne 0 %then %let segtype=TU_SUMSTATSINROWS;
      %else %let segtype=TU_FREQ;

      /*
      / Previous versions of tu_multisegments required the value of
      / each segment parameter to begin with TU_FREQ or TU_SUMSTATSINROWS.
      / This is no longer a requirement, but to ensure backwards compatibility,
      / this text should be removed if it does appear.
      /--------------------------------------------------------------------------*/

      %if %qupcase(%scan(&&segment&s, 1)) eq &segtype %then
      %do;
        %let segment&s = %substr(&&segment&s, %length(&segtype) + 1);
        %let segment&s = %nrbquote(&&segment&s);
      %end;

      /*
      / Read in data display defaults from XML file, if a defaults XML file has been specified.
      /---------------------------------------------------------------------------------------*/

      %if %length(&xmldefaults) gt 0 %then
      %do;

        data &prefix._defaults;
          length name $200 value $500;
          set xmldef.&ddname;
          where upcase(type)="&segtype";
          name=upcase(name);
        run;

        proc sort data=&prefix._defaults;
          by type name;
        run;

      %end;

      /* If dsetin is populated then this will not over-ride
      /  the dsetin parameters within each segment, but 
      /  will override any datasets specified in the XML
      /  defaults file.
      /  Note that the dataset created below will
      /  already be sorted by TYPE NAME.
      /--------------------------------------------------*/

      %if "&dsetin" ne "" %then
      %do;
        data &prefix.dsetin;
        length name $200 value $500;
        type="&segtype";
        %if "&segtype"="TU_SUMSTATSINROWS" %then
        %do;
           name="DSETIN";
           value="&dsetin";
        %end;
        %else %if "&segtype"="TU_FREQ" %then
        %do;
           name='DSETINDENOM';
           value="&DSETIN";
           output;
           name='DSETINNUMER';
           value="&DSETIN";
           output;
        %end;
        run;
      %end;

      /*
      /  Dataset containing parameter and value for each
      /  parameter specified within the segment
      /--------------------------------------------------*/

      data &prefix.segment&s;
        length name $200 value $500;
        type="&segtype";
        /* Loop through each paramer/parameter value within the segment */
        %do w=1 %to %tu_words(%qsysfunc(trim(%str(&&segment&s))) , delim=%str(,));
          %local part&w;
          %let part&w=%scan(&&segment&s,&w,%str(,));
          pos=index("&&part&w",'=');
          if pos gt 0 then 
          do;
            name= upcase(substr("&&part&w",1,  pos-1  ));
            if length("&&part&w") gt pos then value= substr("&&part&w",pos+1);
            else value = "";
            output;
          end;
        %end;
      run;

      proc sort data=&prefix.segment&s;
        by type name;
      run;

      /* Final dataset contains the parameters and values for either
      /  tu_freq or tu_sumstatsinrows.
      /  Anything specfied in each segment within the macro call  (in dataset segment&s)
      /  will over-ride any parameter in the XML defaults.
      /  If dsetin is specified, this will over-ride the XML default
      /---------------------------------------------------------------------------------*/

      data &prefix.segment&s.parms;
        length name $200 value $500;
        merge %if %length(&xmldefaults) gt 0 %then &prefix._defaults;
              %if "&dsetin" ne "" %then &prefix.dsetin;
              &prefix.segment&s  
              ;
        by type name;

        /*
        / For the first segment only: 
        / Determine what is the last GROUPBYVARPOP variable - note that 
        / GROUPBYVARPOP should have the same value for all segments.      
        /-------------------------------------------------------------------------------*/

        %if &s eq 1 %then
        %do;

          %let lastGroupbyvarpop = ;
          %let groupbyvarpop = ;

          if name eq "GROUPBYVARPOP" then 
          do;
            call symput('lastGroupbyvarpop', scan(value, -1, ' '));  
            call symput('groupbyvarpop', trim(left(value)));
          end;
         
        %end; /* %if &s eq 1 %then */

        /*
        / Create macro variables to store the names of the 'groupbyvars' and 'dsetin' 
        / parameters for the current segment, so we can refer to these macro variables,
        / instead of continually having to generate different code depending on whether
        / the current code is for TU_FREQ or TU_SUMSTATSINROWS.
        /-------------------------------------------------------------------------------*/

        %if &segtype eq TU_FREQ %then 
        %do;
          %let groupbyvarsName = GROUPBYVARSNUMER;
          %let dsetinName = DSETINNUMER;
        %end;
        %else %if &segtype eq TU_SUMSTATSINROWS %then 
        %do;
          %let groupbyvarsName = GROUPBYVARSANALY;
          %let dsetinName = DSETIN;
        %end;

        %let groupbyvarsValue = ;
        %let dsetinValue = ;

        /*
        / For all segments: 
        / Determine what are the 'groupbyvars' variables and determine the name of the 
        / 'dsetin' dataset. Also, create a local macro variable, stratifiedVars&s, equal
        / to groupbyvarsnumer, if it is a call to tu_freq, or groupbyvarsanaly, if it is 
        / a call to tu_sumstatsinrows.
        /-------------------------------------------------------------------------------*/

        %local stratifiedVars&s;  
        %let stratifiedVars&s = ;

        if compress(name) eq "&groupbyvarsName" then 
        do;
          call symput("groupbyvarsValue", upcase(trim(left(value))));
          call symput("stratifiedVars&s", trim(left(value)));
        end;

        if compress(name) eq "&dsetinName" then call symput("dsetinValue", upcase(trim(left(value))));       

      run;

      /*
      / Determine whether SEX or any of the Yes/No variables have been specified as
      / 'groupbyvars'. If they have been, then check that they also exist in the input
      / dataset.
      /-------------------------------------------------------------------------------*/

      %let sexseg = 0;
      %let ynvarList = ;

      %if %sysfunc(indexw(&groupbyvarsValue, SEX)) %then 
      %do;
        %let sexseg = 1;
        %if %length(%tu_chkvarsexist(&dsetinValue, SEX)) ne 0 %then %let g_abort = 1;
      %end;

      %do n = 1 %to %tu_words(&ynvars);
        %if %sysfunc(indexw(&groupbyvarsValue, %upcase(%scan(&ynvars, &n)))) %then
          %let ynvarList = &ynvarList %upcase(%scan(&ynvars, &n));
      %end;

      %if %length(&ynvarList) gt 0 %then
      %do;
        %if %length(%tu_chkvarsexist(&dsetinValue, &ynvarList)) ne 0 %then %let g_abort = 1;
      %end;

      %if g_abort eq 1 %then %goto MacErr;

      /*
      / If code/decode variables are required, then create temporary dataset, similar to
      / input dataset, but with the addition of these variables.
      /---------------------------------------------------------------------------------*/

      %if &sexseg or %length(&ynvarList) ne 0 %then
      %do;

        data &prefix.tempDsetin;
          set &dsetinValue;

          /*
          / If sexseg=1 then create sex code/decode
          /-----------------------------------------*/

          %if &sexseg %then
          %do;
            length sexcd $1;
            sexcd = sex;
            drop sex;
            sex_tmp=put(sexcd, $sex.);
            rename sex_tmp=sex;
            attrib sex_tmp label='Sex';
          %end;

          /* 
          / Create code/decode for yes/no variables in this segment.
          / Note that the length of ___tempYnvar, and therefore the length of the decoded Yes/No 
          / variable in the output dataset, will be the maximum length of the format specified in
          / &yndecodefmt. This may be longer than the length of the original Yes/No variable in
          / the input dataset - this is why ___tempYnvar is created, rather than simply
          / over-writing the value of the original Yes/No variable.
          /-------------------------------------------------------------------------------------*/
          
          length ___tempYnvarlabel $32761;
          drop ___tempYnvarlabel ;
          ___tempYnvarlabel='' ;

          %if %length(&ynvarList) gt 0 %then 
          %do n = 1 %to %tu_words(&ynvarList);

            %let ynvar = %scan(&ynvarList, &n);

            &ynvar.cd = put(&ynvar, &ynorderfmt);
            ___tempYnvar&n = put(&ynvar, &yndecodefmt);
            drop &ynvar;
            rename ___tempYnvar&n = &ynvar;
           ___tempYnvarlabel=trim(left(___tempYnvarlabel))||' '||compress("&ynvar")||'="'||trim(vlabel(&ynvar))||'"';
         %end;
         call symput('m', trim(___tempYnvarlabel));

          %if g_abort eq 1 %then %goto MacErr;

        run;

        %if %nrbquote(&m) ne %then
        %do;
          data &prefix.tempDsetin;
             set &prefix.tempDsetin;
             label &m;
          run;
        %end;

        data &prefix.segment&s.parms;
          set  &prefix.segment&s.parms;
          if compress(name) eq "&dsetinName" then value = "&prefix.tempDsetin";
        run;

      %end; /* %if &sexseg or %length(&ynvar) ne 0 %then */


      data &prefix.segment&s.parms2 (keep = macvar);
        set &prefix.segment&s.parms;
        length macvar $403;
        macvar = compress(name) || ' = ' || trim(left(value));
      run;

      proc sql noprint;
        select distinct trim(left(macvar)) into : paramlist&s
        separated by ','
        from &prefix.segment&s.parms2;
      quit;

      %&segtype(&&paramlist&s)    
                 
      /*
      / Check that required variables exist in each segment output dataset 
      /---------------------------------------------------------------------*/
   
      %if %qupcase(&denormyn) eq Y %then 
      %do;

        %if %length(%tu_chkvarsexist(dsetin=segment&s._out,varsin=&VARSTODENORM &ACROSSVAR)) ne 0 %then        
        %do;
          %put %str(RTE)RROR : &sysmacroname : One or more variables (&VARSTODENORM &ACROSSVAR) do not exist in the segment output dataset ( Segment &s);
          %let g_abort = 1;
        %end;

        %if %qupcase(&addbignyn) eq Y %then
        %do n = 1 %to %tu_words(&acrossvardecode);
          %let currentWord = %scan(&acrossvardecode, &n, %str( ));
          %if %index(&currentWord, .) eq 0 %then
          %do;
            %if  %length(%tu_chkvarsexist(dsetin=segment&s._out,varsin=&currentWord)) ne 0 %then
            %do;
              %put %str(RTE)RROR : &sysmacroname : ACROSSVARDECODE(&ACROSSVARDECODE) contains a word that is neither a format nor a variable that exists in the segment output dataset ( Segment &s);
              %let g_abort = 1;
            %end;
          %end;
        %end;  

      %end; /* %if &denormyn eq Y %then */

      %if g_abort eq 1 %then %goto MacErr;
    
      /*  
      / Determine character field widths from each
      / segment dataset
      /---------------------------------------------*/
    
      proc contents data = segment&s._out 
                    out = &prefix._clen&s
                    (keep = name type length )
                    noprint
                    ;
      run;
                             
      data &prefix._clen&s;
        retain seq &s;
        length ucname $ 32;
        set &prefix._clen&s;
        ucname=upcase(name);
      run;  
 
      proc append base = &prefix._clenall
                  data = &prefix._clen&s
                  ;
      run;

      /*
      / Set order variable for each segment
      /---------------------------------------------------------------*/
         
      data &prefix.segment&s._out;
        set segment&s._out;
        retain tt_segorder &s;
      run;
           
   %end;  /* End of segment looping  */

   /* Deassign the XML libname for the defaults */

   %if %length(&xmldefaults) gt 0 %then
   %do;
     libname xmldef "";
   %end;
                                                                                    
   /* sort ready to get first form of variable name 
   /---------------------------------------------------*/
    
   proc sort data = &prefix._clenall
             out = &prefix._clenallmismatch
             nodupkey;
    by ucname type;
   run;
 
    
   /* highlight conflict here
   /------------------------------*/
    
   data &prefix.mismatch;
     set &prefix._clenallmismatch;
     by ucname;
     if first.ucname and not last.ucname;
   run;

   proc sql noprint;
     select distinct ucname into : mixtype 
     separated by ''
     from &prefix.mismatch
     ;
   quit;

   /* Ensure data types are consistent across each segment dataset. 
   /  If a variable is numeric in some segments, but character in others,
   /  then convert the numerics to character variables. However, only
   /  attempt to do this if the variable exists for a particular segment, 
   /  so that we avoid unwanted (RTE)RRORs when tu_varattr is called. A
   /  variable might legitimately not exist in one segment: when using
   /  stratification variables, we may wish to create segment 1 without
   /  tt_code1 or tt_decode1, in order to display the denominator for a 
   /  particular stratification group - if tt_code1 is a mixed type, then 
   /  we do not want the code to fall over when tu_varattr is called for
   /  segment 1.
   /---------------------------------------------------------------------*/

   %do var = 1 %to %tu_words(&mixtype);
     %do s = 1 %to &ns;
       %if %length(%tu_chkvarsexist(segment&s._out,%scan(&mixtype,&var))) eq 0 %then
       %do;
         %if %tu_varattr(segment&s._out,%scan(&mixtype,&var),VARTYPE) eq N %then
         %do;
	     data &prefix.segment&s._out;
	       set &prefix.segment&s._out;
	       %scan(&mixtype,&var)_tmp = put(%scan(&mixtype,&var), 8. );
	       drop %scan(&mixtype,&var);
	       rename %scan(&mixtype,&var)_tmp = %scan(&mixtype,&var);
	     run;
         %end;
       %end;
     %end;
   %end;
        
   /* we only want the one with the longest length where there is a clash */

   data &prefix._clenall;
     set &prefix._clenall;
     if type eq 1 then length = 8;
   run;
    
   proc sort data = &prefix._clenall
             nodupkey
             ;
    by ucname descending length;
   run;
                    
   data &prefix._clenall;
     set &prefix._clenall;
     by ucname;
     if first.ucname and not last.ucname;
   run;
            
   %if %tu_nobs(&prefix._clenall) %then 
   %do;
      /* generate the length statement and output to local macro variable */;
      data _null_;
        length str $ 32767;
        retain str 'length';
        set &prefix._clenall end = last;
        str = trim(str)||' '||trim(ucname)||' $ '||compress(put(length,5.));
        if last then call symput("setlength",trim(str));
      run;
   %end;
            
                                         
   /*
   / Combine segment output datasets 
   /----------------------------------*/
         
   data &prefix._comb;
     &setlength ;
     set   
     %do s = 1 %to &ns;
       &prefix.segment&s._out
     %end;
     ;
     format tt_decode1 tt_code1;

     /*
     / Reset acrossvardecode so that format names are replaced by names of variables that
     / will be generated in the current datastep.
     /---------------------------------------------------------------------------------*/

     %let newAcrossvardecode = ;

     %do n = 1 %to %tu_words(&acrossvardecode);

       %let currentWord = %scan(&acrossvardecode, &n, %str( ));

       %if %index(&currentWord, .) %then
       %do;
         length ___tempAcrossvardecode&n $200;
         ___tempAcrossvardecode&n = put(%scan(&acrossvar, &n), &currentWord);
         %let newAcrossvardecode = &newAcrossvardecode ___tempAcrossvardecode&n;
       %end;
       %else 
       %do;
         %let newAcrossvardecode = &newAcrossvardecode &currentWord;
       %end;

     %end; /* %do n = 1 %to %tu_words(&acrossvardecode); */

     %let acrossvardecode = &newAcrossvardecode;

   run;

   %let lastDset=&prefix._comb;  
      

   /* If no data in combined segment data then jump 
   /  straight to tu_list 
   /-------------------------------------------------------*/
   
   %if %tu_nobs(&lastDset) eq 0 %then 
   %do;
      %goto displayit;
   %end;
      
     
   %if %qupcase(&addbignyn) eq Y  %then
   %do;
 
       /*
       /  If addbignyn is Y then take the ACROSSVARDECODE
       /  variable that corresponds to the ACROSSVAR that is equal
       /  to the last GROUPBYVARPOP, and replace it with another
       /  variable formed by concatenating its value to bign - 
       /  if this variable corresponds to the last ACROSSVAR, then
       /  include a split character to separate the decode text 
       /  from the big N  value; otherwise, do not include the split
       /  character, because the text will be used to form the macro
       /  variable created by tu_denorm (via its acrossVarListName 
       /  parameter), which in turn may be passed to a PROC REPORT
       /  columns statement, and it looks neater if text in a spanning
       /  header appears on the same line: the "---" on each side of
       /  such text looks wrong when it is split over more than one line.
       /----------------------------------------------------------------------*/

       data &prefix._addbign;
         set &LastDset;

         %let numAcrossvar = %tu_words(&acrossvar);
         %let newAcrossvardecode = ;

         %do n = 1 %to &numAcrossvar;

           %if %scan(&acrossvar, &n) eq &lastGroupbyvarpop %then
           %do;
             acrossvarbign = trim(left(%scan(&ACROSSVARDECODE, &n))) %if &n eq &numAcrossvar %then || "&SPLITCHAR";
                             || "(N=" || trim(left(tt_bnnm)) || ")"; 
             %let newAcrossvardecode = &newAcrossvardecode acrossvarbign;
           %end;
           %else
           %do;
             %let newAcrossvardecode = &newAcrossvardecode %scan(&acrossvardecode, &n);
           %end;

         %end;

         %let acrossvardecode = &newAcrossvardecode;

       run;   
 
       %let lastDset = &prefix._addbign; 
 
   %end;
   %if %qupcase(&addbignyn) eq N  %then
   %do;

     /*
     / If ADDBIGNYN=N, DENORMYN=Y, and none of the variables(s) specified in GROUPBYVARPOP
     / exist in ACROSSVAR, then append the variable storing the �big N� value to the end
     / of the list of variables passed to the GROUPBYVARS parameter of TU_DENORM.
     / The macro variable TT_BNNM will store the name of this variable, if it needs to be 
     / appended, otherwise it will be set to blank.
     /------------------------------------------------------------------------------------*/

     %if %qupcase(&denormyn) eq Y %then
     %do;
 
       %let tt_bnnm = tt_bnnm;

       %do m = 1 %to %tu_words(&groupbyvarpop);
         %let currentWord = %scan(&groupbyvarpop, &m);
         %do n = 1 %to %tu_words(&acrossvar);
           %if &currentWord eq %scan(&acrossvar, &n) %then %let tt_bnnm = ;
         %end;
       %end;

     %end;

   %end;

   /* Run denorm macro if required.  
   /  If stratification variables have been specified, then data is first grouped
   /  by these variables.
   /  If "big N" variable needs to be included in GROUPBYVARS, then &tt_bnnm would
   /  already have been set to the name of this variable, otherwise it would 
   /  have been set to missing.
   /-----------------------------------------------------------------------------*/
           
   %if %upcase(&denormyn) eq Y %then
   %do;

     %let stratifiedVars0 = ;


     %do s = 1 %to &ns; 

       /*
       / Remove parentheses from stratifiedVars&s.
       /-----------------------------------------------------------------------------*/
    
       %let openParen = %index(&&stratifiedVars&s, %str(%());
    
       %do %while (&openParen gt 0);
    
	 %let closeParen = %index(&&stratifiedVars&s, %str(%)));
    
	 %if &closeParen le &openParen %then 
	 %do;
	     %put %str(RTE)RROR: &sysmacroname: 'groupbyvars' for first segment contains unmatched parentheses;
	     %let g_abort = 1;
	     %goto MacErr;
	 %end;
	 %else %if &openParen eq 1 %then
	 %do;
	     %let stratifiedVars&s = %substr(&&stratifiedVars&s, &closeParen + 1);
	 %end;
	 %else %if &closeParen eq %length(&&stratifiedVars&s) %then 
	 %do;
	     %let stratifiedVars&s = %substr(&&stratifiedVars&s, 1, &openParen - 1);
	 %end;
	 %else
	 %do;
	     %let stratifiedVars&s = %substr(&&stratifiedVars&s, 1, &openParen - 1) %substr(&&stratifiedVars&s, &closeParen + 1);
	 %end;
    
	 %let openParen = %index(&&stratifiedVars&s, %str(%());
	
       %end; /* %do %while (&openParen gt 0); */
	
       /*
       / Remove acrossvar or acrossvardecode variables from stratifiedVars&s.
       / &originalAcrossvardecode is used, because &acrossvardecode may have been 
       / altered to include the name of a variable that incorporates the "big N" value,
       / instead of a variable that might have been included in 'groupbyvars'.
       /-----------------------------------------------------------------------------*/
    
       %if %length(&acrossVar) gt 0 %then 
       %do;
  
	 %let newStratifiedVars = ;
    
	 %do m = 1 %to %tu_words(&&stratifiedVars&s);
    
	   %let currentWord = %scan(&&stratifiedVars&s, &m);
    
	   %if %sysfunc(indexw(&acrossVar &originalAcrossvardecode, &currentWord)) eq 0 %then
	     %let newStratifiedVars = &newStratifiedVars &currentWord;
     
	 %end; /* %do m = 1 %to %tu_words(&&stratifiedVars&s); */
     
	 %let stratifiedVars&s = &newStratifiedVars;
  
       %end; /* %if %length(&acrossVar) gt 0 %then */
  
       /*
       / Remove all variables from stratifiedVars&s that do not also exist in &lastDset
       /  - the remaining value of stratifiedVars&s is a list of all variables that must
       /    be inserted to the left of tt_segorder in the call to %tu_denorm.
       /-----------------------------------------------------------------------------*/
    
       %if %length(&&stratifiedVars&s) gt 0 %then
       %do;
  
	 %let notExistVars = %upcase(%tu_chkvarsexist(&lastDset, &&stratifiedVars&s));
  
	 %if notExistVars eq -1 %then
	 %do;
	   %put %str(RTE)RROR: &sysmacroname: unable to determine if possilble stratification variables;
	   %put exist in dataset to be denormalised;
	   %goto MacErr;
	 %end;
	 %else 
	 %do;
	 
	   %let newStratifiedVars = ;
    
	   %do m = 1 %to %tu_words(&&stratifiedVars&s);
    
	     %let currentWord = %upcase(%scan(&&stratifiedVars&s, &m));
    
	     %if %sysfunc(indexw(&notExistVars, &currentWord)) eq 0 %then
	       %let newStratifiedVars = &newStratifiedVars &currentWord;
     
	   %end; /* %do m = 1 %to %tu_words(&&stratifiedVars&s); */
     
	   %let stratifiedVars&s = &newStratifiedVars;
  
	 %end;
  
       %end; /* %if %length(&&stratifiedVars&s) gt 0 %then */

       %let stratifiedVars0 = &stratifiedVars0 &&stratifiedVars&s;

     %end; /* %do s = 1 %to &ns; */

     /*
     / Usually, if BY variables are used in a data display, the same BY variables will be
     / used for all segments, so the "stratification variables" will be the same for all
     / segments. Since stratifiedVars0 is the concatenation of the stratification variables
     / for all segments, variables might have been listed multiple times.
     /-------------------------------------------------------------------------------------*/

     %if %length(&stratifiedVars0) gt 0 %then 
     %do;
       %let stratifiedVars0 = %tu_unduplst(&stratifiedVars0);
     %end;

     /*
     / The dataset &prefix.Multilevel will have one observation corresponding to each
     / permutation of &stratifiedVars0 tt_segorder tt_grplabel tt_code1 tt_decode1 &tt_bnnm, 
     / where there is more than one corresponding value of tt_summarylevel.
     /-------------------------------------------------------------------------------------*/

     proc sort data = &lastDset
               (keep = &stratifiedVars0 tt_segorder tt_grplabel tt_code1 tt_decode1 &tt_bnnm tt_summarylevel)
               out = &prefix.Multilevel
               (drop = tt_summarylevel)
               nodupkey
               ;
       by &stratifiedVars0 tt_segorder tt_grplabel tt_code1 tt_decode1 &tt_bnnm tt_summarylevel;
     run;

     data &prefix.Multilevel;

       set &prefix.Multilevel;
       by &stratifiedVars0 tt_segorder tt_grplabel tt_code1 tt_decode1 &tt_bnnm;
       
       %if %length(&tt_bnnm) gt 0 %then
       %do;
         if last.&tt_bnnm and not first.&tt_bnnm;
       %end;
       %else
       %do;
         if last.tt_decode1 and not first.tt_decode1;
       %end;

     run;

     /*
     / When there is more than one value of tt_summarylevel for a given permutation of
     / &stratifiedVars0 tt_segorder tt_grplabel tt_code1 tt_decode1 &tt_bnnm, the value of 
     / tt_summarylevel will be reset to '0': this is to prevent problems from occurring 
     / during denormalisation.
     /-------------------------------------------------------------------------------------*/

     proc sort data = &lastDset
               out = &prefix.sorted
               ;
       by &stratifiedVars0 tt_segorder tt_grplabel tt_code1 tt_decode1 &tt_bnnm;
     run;

     %let lastDset = &prefix.sorted;

     data &prefix.resetsl;
       merge &prefix.Multilevel (in = inmult) &lastDset;
       by &stratifiedVars0 tt_segorder tt_grplabel tt_code1 tt_decode1 &tt_bnnm;
       if inmult then tt_summarylevel = 0;
     run;

     %let lastDset = &prefix.resetsl;

     /*
     / If tu_multisegments is called with display = N, then the macro variable 
     / whose name is given by acrossVarListName may need to be referenced outside 
     / the scope of tu_multisegments, in order to build a column statement.
     /-----------------------------------------------------------------------------*/

     %if %length(&acrossVarListName) gt 0 %then %global &acrossVarListName;

     %tu_DENORM(
	    dsetin=&lastDset,         
	    varsToDenorm= &varstodenorm,   
	    groupByVars = &stratifiedVars0 tt_segorder tt_grplabel tt_code1 tt_decode1 &tt_bnnm tt_summarylevel,
	    acrossVar= &acrossvar ,     
	    acrossVarLabel= &acrossvardecode,
	    acrossColVarPrefix= &acrossColVarPrefix,
	    acrossVarListName = &acrossVarListName, 
	    dsetout=&prefix.combDenorm  
	    );
	     
     %let lastDset=&prefix.combDenorm;

   %end; /* %if %upcase(&denormyn) eq Y %then */

   /*
   / Run tu_align to align columns across all segments
   /--------------------------------------------------*/
          
   %if %upcase(&alignyn) eq Y %then
   %do;
      %tu_align( dsetin = &lastDset,
                 varsin = %if %upcase(&denormyn) eq Y %then 
                          %do;
                            %if %length(&acrossColVarPrefix) ne 0 %then &acrossColVarPrefix:;
                            %else &varstodenorm:;
                          %end;
                          %else tt_result;
                          ,
                 alignment=R,                   /* YW001: */
                 compresschryn=N,
                 dp=.,
                 dsetout=&prefix._combAlign,
                 ncspaces=1
               );          
       %let lastDset=&prefix._combAlign;
   %end;
   
   /*
   / Apply postsubset, if specified.
   /--------------------------------------------------------------------------*/    
   %if %length(&postSubset) ne 0 %then %do;
      data &prefix._postsubset;
         set &lastDset;
         %unquote(&postSubset);
      run;
      %let lastdset=&prefix._postsubset;
   %end;
   
   /*
   /  Create output dataset if required
   /--------------------------------------------------------------------------*/    
     
   %if %length(&dsetout) ne 0 %then %do;

     /*
     /  Call %tu_labelvars to label the variables.
     /--------------------------------------------------------------------------*/    

     %if &LABELVARSYN eq Y %then %do;   
       %tu_labelvars(dsetin   = &lastdset,  
                     dsetout  = &prefix.labelout,  
                     style    = &varlabelstyle    
                    )                      
       %let lastdset = &prefix.labelout;             
     %end;
   
     data &dsetout ;
       set &lastDset (label='MULTISEGMENTS OUTPUT DATASET');
     run;
    
   %end; /* %if %length(&dsetout) ne 0 %then %do; */

   
   %DISPLAYIT:
   
   %if %upcase(&display) ne N %then
   %do;

     /*
     / Create display if required
     /----------------------------------*/
    
          %tu_list(
             dsetin=&lastDset.,
             getdatayn= N,
             break1 = &break1,
             break2 = &break2,
             break3 = &break3,
             break4 = &break4,
             break5 = &break5,
             byvars = &byvars,
             centrevars = &centrevars,
             colspacing = &colspacing,
             columns = %unquote(&columns),
             computebeforepagelines = &computebeforepagelines ,
             computebeforepagevars = &computebeforepagevars,
             stackvar1 = &stackvar1,
             stackvar2 = &stackvar2,
             dddatasetlabel = &dddatasetlabel,
             ordervars = &ordervars,
             sharecolvars = &sharecolvars,
             sharecolvarsindent = &sharecolvarsindent,
             overallsummary = &overallsummary,
             labelvarsyn = &labelvarsyn,
             linevars = &linevars,
             descending = &descending,
             display=&display  ,
             orderformatted = &orderformatted,
             orderfreq = &orderfreq,
             orderdata = &orderdata,
             noprintvars = &noprintvars,
             flowvars = &flowvars,
             widths = &widths,
             defaultwidths = &defaultwidths,
             skipvars = &skipvars,
             pagevars = &pagevars,
             idvars = &idvars,
             leftvars = &leftvars,
             rightvars = &rightvars,
             varspacing = &varspacing,
             varlabelstyle = &varlabelstyle,
             formats = &formats,
             labels = &labels,
             proptions = &proptions,
             nowidowvar = &nowidowvar            
             );
           
   %end;
 
     
   %tu_tidyup(rmdset=&prefix:, glbmac=NONE);
   
   
   %MacErr:
   
      %tu_abort;
   
         
   %Exit:
         
%mend tu_multiSegments;
