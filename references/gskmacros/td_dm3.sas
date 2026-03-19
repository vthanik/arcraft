/*----------------------------------------------------------------------------+
| Macro Name    : td_dm3.sas
|
| Macro Version : 3
|
| SAS version   : SAS v8.2
|
| Created By    : Lee Seymour
|
| Date          : Oct 2003
|
| Macro Purpose : display macro to generate IDSL dm3 listing
|
| Macro Design  : PROCEDURE STYLE
|
| Input Parameters :
|
| NAME         DESCRIPTION                                 DEFAULT
|
| SEGMENT1     Each segment shall contain a call to       %str(analysisVars=age)
|              either parameters for tu_freq or
|              parameters required for tu_sumstatsinrows
|              The following style shall be used:
|              segment1 = %str(parm1=value1, parm2=value2)
|              Where parm1 and parm2 are both parameters of
|              tu_freq or tu_sumstatsinrows.
|              Note: for tu_freq at a minimum a value must
|              be assigned to analysisvars, and for
|              tu_sumstatsinrows, at a minimum values must
|              be assigned to groupbyvarsnumer and dsetout.
|
| SEGMENT2     Each segment shall contain a call to        %str(groupByVarsNumer=&g_trtcd &g_trtgrp
|              either parameters for tu_freq or            (Sex='n')sexcd sex,dsetout=segment2_out(rename=(sex=tt_decode1 sexcd=tt_code1)),
|              parameters required for tu_sumstatsinrows   codedecodevarpairs=&g_trtcd &g_trtgrp sexcd sex)
|              The following style shall be used:
|              segment1 = %str(parm1=value1, parm2=value2
|              Where parm1 and parm2 are both parameters of
|              tu_freq or tu_sumstatsinrows.
|              Note: for tu_freq at a minimum a value must
|              be assigned to analysisvars, and for
|              tu_sumstatsinrows, at a minimum values must
|              be assigned to groupbyvarsnumer and dsetout.
|
| SEGMENT3     Each segment shall contain a call to        %str(groupByVarsNumer=&g_trtcd &g_trtgrp
|              either parameters for tu_freq or            (ethnic='n')ethniccd ethnic,dsetout=segment3_out(rename=(ethnic=tt_decode1 ethniccd=tt_code1)),
|              parameters required for tu_sumstatsinrows   codedecodevarpairs=&g_trtcd &g_trtgrp ethniccd ethnic)
|              The following style shall be used:
|              segment1 = %str(parm1=value1, parm2=value2
|              Where parm1 and parm2 are both parameters of
|              tu_freq or tu_sumstatsinrows.
|              Note: for tu_freq at a minimum a value must
|              be assigned to analysisvars, and for
|              tu_sumstatsinrows, at a minimum values must
|              be assigned to groupbyvarsnumer and dsetout.
|
| SEGMENT4-20  Each segment shall contain a call to
|              either parameters for tu_freq or
|              parameters required for tu_sumstatsinrows
|              The following style shall be used:
|              segment1 = %str(parm1=value1, parm2=value2
|              Where parm1 and parm2 are both parameters of
|              tu_freq or tu_sumstatsinrows.
|              Note: for tu_freq at a minimum a value must
|              be assigned to analysisvars, and for
|              tu_sumstatsinrows, at a minimum values must
|              be assigned to groupbyvarsnumer and dsetout.
|
| ACROSSCOLVARPREFIX    Passed directly to tu_denorm in tu_multisegments.
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
| ACROSSVAR    Specifies a variable that has multiple levels    &g_trtcd
|              and will be transposed by %tu_denorm to multiple
|              columns.
|              Valid values: blank, or a SAS variable that
|              exists in each of the segments' output datasets.
|              Required only if DENORMYN=Y. This parameter
|              must have the same value as ACROSSVAR in each
|              of the segment macro calls.
|
| ACROSSVAR    Specifies the name of a variable that contains  &g_trtgrp
| DECODE       decoded values of ACROSSVAR
|              Valid values: blank, or a SAS variable that
|              exists in each of the segments' output datasets.
|              Required only if DENORMYN=Y and ADDBIGNYN=Y.
|
| ACROSSVARLISTNAME     Specifies the name of the macro variable that %TU_DENORM   none
|                       will update with the names of the variables created by
|                       the transpose of the first variable that is specified in
|                       VARSTODENORM. In most cases the macro variable is LOCAL
|                       to the program that called %tu_DENORM.
|                       Valid values: SAS macro variable name.
|
| ADDBIGNYN    Append the population N (N=nn) to the label of the         Y
|              transposed columns containing the results - Y/N?
|              Valid Values: Y, N
|
| ALIGNYN      Execute tu_align macro : Yes or No                         Y
|
| DENORMYN     Transpose result variables from rows to columns            Y
|              across the ACROSSVAR = Y/N?.
|              Valid values: Y or N
|
| DSETIN       Name of dataset that will override input dataset names
|              specified in XML defaults file, but will not override
|              any input datasets specified via segment<n> parameters.
|
| DSETOUT      Specifies the name of the output summary
|              dataset.
|              Valid values: Blank, or a valid SAS dataset
|              name.
|
| VARSTODENORM Specifies the name of the variable to be transposed.       tt_result
|              Valid values: a SAS variable that exists in the stacked 
|              output dataset.In a %tu_freq segment this value must be 
|              the same as ACROSSCOLVARPREFIX. In a %tu_sumstatsinrows 
|              segment this value must be the same as RESULTVARNAME.
|
| XMLDEFAULTS  Full directory path and filename of dm3.xml     &g_refdata\tr_dm3_defaults.xml
|              file which contains segment defaults
|
| YNDECODEFMT  Blank, or a SAS format that maps the Yes/No variables    $yndecod.
|              to decode text (i.e. Yes, No etc) that will be
|              printed on the data display. 
|
| YNORDERFMT   Blank, or a SAS format that maps the Yes/No variables to  $ynorder.
|              numbers stored as text (i.e. 1, 2, 3 etc, rather 
|              than 1, 2, 3 etc), which will be used for sorting the 
|              output on the data display.
|
| YNVARS       Blank, or list of Yes/No variables                        
|
|---------------------------------------------------------------------------------------------------
| Parameters, with default values, that pass to macro TU_LIST
|     BREAK1-BREAK5=(Blank), BYVARS=(Blank), CENTREVARS=(Blank), COLSPACING=2,
|     COLUMNS=tt_segorder tt_grplabel tt_code1  tt_decode1 tt_result:,
|     COMPUTEBEFOREPAGELINES=(Blank), COMPUTEBEFOREPAGEVARS=(Blank),
|     DDDATASETLABEL=DD dataset for td_dm3 display, DEFAULTWIDTHS=(Blank), DESCENDING=(Blank),
|     DISPLAY=Y, FLOWVARS=_All_, FORMATS=(Blank), IDVARS=(Blank), LABELS=(Blank), LABELVARSYN= Y,
|     LEFTVARS=(Blank), LINEVARS=(Blank), NOPRINTVARS=tt_segorder tt_code1, NOWIDOWVAR=(Blank),
|     ORDERDATA=(Blank), ORDERFORMATTED=(Blank), ORDERFREQ=(Blank),
|     ORDERVARS=tt_segorder  tt_grplabel tt_code1,
|     OVERALLSUMMARY=N, PAGEVARS=(Blank), PROPTIONS=Headline, RIGHTVARS=(Blank),
|     SHARECOLVARS=(Blank), SHARECOLVARSINDENT=2, SKIPVARS=tt_segorder, SPLITCHAR=~,
|     STACKVAR1-STACKVAR15=(Blank),VARLABELSTYLE=short VARSPACING=(Blank),
|     WIDTHS=tt_grplabel 8  tt_decode1 17 tt_result1-tt_result9999 13
|---------------------------------------------------------------------------------------------------
|
| Output:   1. an output file in plain ASCII text format containing a summary in columns data
|              display matching the requirements specified as input parameters.
|           2. SAS data set that forms the foundation of the data display (the "DD dataset").
|
| Global macro variables created: None
|
|
| Macros called :
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_multisegments
| (@) tu_abort
|
| **************************************************************************
| Change Log :
|
| Modified By :             Shan Lee
| Date of Modification :    15-Oct-2003
| New Version Number :      1/2
| Modification ID :         None - modifications are to flyover text that is
|                           parsed by the HARP application - we must avoid
|                           including modification IDs in this text.
| Reason For Modification : The HARP Application assumes that the first
|                           semi-colon after the macro header indicates the
|                           end of the initial MACRO statement. Therefore,
|                           if a semi-colon appears either in the default
|                           value for a parameter, or as part of the flyover
|                           text for a parameter, then the HARP Application
|                           will not recognise any of the parameters specified
|                           after this semi-colon. The macro has been amended so
|                           that there are no longer semi-colons in the
|                           flyover text for the PAGEVARS and SKIPVARS
|                           parameters.
|
| Modified By :             Lee Seymour
| Date of Modification :    20-Oct-2003
| New Version Number :      1/3
| Modification ID :
| Reason For Modification : Changed %nrstr to %str
|
| Modified By :             Yongwei Wang
| Date of Modification :    15-Dec-2004
| New Version Number :      2/1
| Modification ID :         yw001
| Reason For Modification : 1. Changed 'race' to 'ethnic' required by change request HRT0061
|                           2. Passed parameter acrossvardecode, computebeforepagelines,
|                              splitchar, overallsummary and stackvar3-15 to %tu_list  
|                              required by change request HRT0021
|                           3. Removed parameter LABELVARSYN and VARLABELSTYLE
|                           4. Removed fly-over text for &SEGMENT3 because the length of 
|                              the line exceeds 255.
|
| Modified By :             Yongwei Wang
| Date of Modification :    16-Aug-2004
| New Version Number :      2/2
| Modification ID :         yw002
| Reason For Modification : Added LABELVARSYN and VARLABELSTYLE back because backward  
|                           compatibility concern.
|                       
| Modified By :             Shan Lee
| Date of Modification :    26-May-06
| New Version Number :      3/1
| Modification ID :         
| Reason For Modification : As requested in HRT0104:
|                           Moved pre-processing that used to occur prior to the call to the
|                           tu_multisegments macro: this pre-processing has now been 
|                           incorporated into the multisegments macro itself. Added new parameters,
|                           corresponding to new parameters in tu_multisegments, and also removed
|                           hard-coding of addbignyn, alignyn, denormyn and varstodenorm in the
|                           call to tu_multisegments, so that values for these parameters may
|                           instead be passed in via corresponding parameters in the wrapper.
|                           Included parameters acrossColVarPrefix and acrossVarListName, whose
|                           values will be passed directly to %tu_multisegments.
|
| Modified By :
| Date of Modification :
| New Version Number :
| Modification ID :
| Reason For Modification :
|
+----------------------------------------------------------------------------*/


%macro td_dm3(
   segment1=%str(analysisVars=age),/*Parameters for freq/sumstatsinrows*/
   segment2=%str(groupByVarsNumer=&g_trtcd &g_trtgrp (Sex='n') sexcd sex,dsetout=segment2_out(rename=(sex=tt_decode1 sexcd=tt_code1)),codedecodevarpairs=&g_trtcd &g_trtgrp sexcd sex),/*Parameters for freq/sumstatsinrows*/
   segment3=%str(groupByVarsNumer=&g_trtcd &g_trtgrp (ethnic='n') ethniccd ethnic,dsetout=segment3_out(rename=(ethnic=tt_decode1 ethniccd=tt_code1)),codedecodevarpairs=&g_trtcd &g_trtgrp ethniccd ethnic,psformat=ethniccd $ethnic.),
   segment4= ,      /*Parameters for freq/sumstatsinrows*/
   segment5= ,      /*Parameters for freq/sumstatsinrows*/
   segment6= ,      /*Parameters for freq/sumstatsinrows*/
   segment7= ,      /*Parameters for freq/sumstatsinrows*/
   segment8= ,      /*Parameters for freq/sumstatsinrows*/
   segment9 =   ,   /*Parameters for freq/sumstatsinrows*/
   segment10 =  ,   /*Parameters for freq/sumstatsinrows*/
   segment11 =   ,  /*Parameters for freq/sumstatsinrows*/
   segment12 =   ,  /*Parameters for freq/sumstatsinrows*/
   segment13 =   ,  /*Parameters for freq/sumstatsinrows*/
   segment14 =   ,  /*Parameters for freq/sumstatsinrows*/
   segment15 =   ,  /*Parameters for freq/sumstatsinrows*/
   segment16 =  ,   /*Parameters for freq/sumstatsinrows*/
   segment17 =   ,  /*Parameters for freq/sumstatsinrows*/
   segment18 =   ,  /*Parameters for freq/sumstatsinrows*/
   segment19 =   ,  /*Parameters for freq/sumstatsinrows*/
   segment20 =  ,   /*Parameters for freq/sumstatsinrows*/
   acrossColVarPrefix       = tt_result, /* Text passed to the PROC TRANSPOSE PREFIX statement in tu_denorm. */
   acrossvar=&g_trtcd, /* Variable that will be transposed to columns */
   acrossvardecode=&g_trtgrp, /* The name of a decode variable for ACROSSVAR */
   acrossVarListName        =,         /* Macro variable name to contain the list of columns created by the transpose of the first variable in VARSTODENORM.*/
   addbignyn                =Y,        /* Append the population N (N=nn) to the label of the transposed columns containg the results - Y/N */
   alignyn                  =Y,        /* Control execution of tu_align */
   denormyn                 =Y,        /* Transpose result variables from rows to columns across the ACROSSVAR - Y/N? */
   dsetin = ,       /* DSETIN for all segments.*/
   dsetout=,        /* Output summary dataset */
   break1                   =,         /* Break statements. */
   break2                   =,         /* Break statements. */
   break3                   =,         /* Break statements. */
   break4                   =,         /* Break statements. */
   break5                   =,         /* Break statements. */
   byvars                   =,         /* By variables */
   centrevars               =,         /* Centre justify variables */
   colspacing               =2,        /* Overall spacing value. */
   columns                  = tt_segorder tt_grplabel tt_code1  tt_decode1 tt_result9999 , /* Column parameter */
   computebeforepagelines   =,         /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt colon labelvar)*/
   computebeforepagevars    =,         /* Names of variables that shall define the sort order for  Compute Before Page lines */
   dddatasetlabel           = DD dataset for td_dm3 display,         /* Label to be applied to the DD dataset */
   defaultwidths            =,         /* List of default column widths */
   descending               =,         /* Descending ORDERVARS */
   display                  =Y,        /* Specifies whether the report should be created */
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
   proptions                =headline, /* PROC REPORT statement options */
   rightvars                =,         /* Right justify variables */
   sharecolvars             =,         /* Order variables that share print space. */
   sharecolvarsindent       =2,        /* Indentation factor */
   skipvars                 =tt_segorder, /* Break after <var> / skip */
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
   widths                   =tt_grplabel 15  tt_decode1 25  tt_result9999 13,  /* Column widths */
   xmldefaults = &g_refdata/tr_dm3_defaults.xml, /*   Location and name of XML defaults file for td macro*/
   ynvars                   =,         /* List of Yes/No variables that require codes and decodes */
   ynorderfmt               =,         /* List of informats for creating numeric order variables corresponding to YNVARS */
   yndecodefmt              =          /* List of formats for creating decode variables corresponding to YNVARS */
);

   %local MacroVersion;
   %let MacroVersion = 3;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals()

   %local ddname; /* Name of dataset specified in XML defaults file. */
   %let ddname = DM3;


   /* Build the call to tu_multisegments */


   %tu_multisegments(segment1 = &segment1,
                     segment2 = &segment2,
                     segment3 = &segment3,
                     segment4 = &segment4,
                     segment5 = &segment5,
                     segment6 = &segment6,
                     segment7 = &segment7,
                     segment8 = &segment8,
                     segment9 = &segment9,
                     segment10 = &segment10,
                     segment11 = &segment11,
                     segment12 = &segment12,
                     segment13 = &segment13,
                     segment14 = &segment14,
                     segment15 = &segment15,
                     segment16 = &segment16,
                     segment17 = &segment17,
                     segment18 = &segment18,
                     segment19 = &segment19,
                     segment20 = &segment20,
                     display= &display,
                     acrossColVarPrefix = &acrossColVarPrefix,
                     acrossvar=&acrossvar,
                     acrossvardecode=&acrossvardecode,
                     acrossVarListName = &acrossVarListName,
                     addbignyn = &addbignyn,
                     alignyn = &alignyn,
                     denormyn = &denormyn,
                     varstodenorm = &varstodenorm,
                     labelvarsyn = &labelvarsyn  ,
                     varlabelstyle = &varlabelstyle,
                     stackvar1 = &stackvar1,
                     stackvar2 = &stackvar2,
                     stackvar3 = &stackvar3,
                     stackvar4 = &stackvar4,
                     stackvar5 = &stackvar5,
                     stackvar6 = &stackvar6,                     
                     stackvar7 = &stackvar7,
                     stackvar8 = &stackvar8,
                     stackvar9 = &stackvar9,
                     stackvar10 = &stackvar10,
                     stackvar11 = &stackvar11,
                     stackvar12 = &stackvar12,
                     stackvar13 = &stackvar13,
                     stackvar14 = &stackvar14,                     
                     stackvar15 = &stackvar15,                                           
                     dddatasetlabel = &dddatasetlabel,
                     ddname = &ddname,
                     dsetin = &dsetin,
                     dsetout = &dsetout,
                     computebeforepagelines = &computebeforepagelines,
                     computebeforepagevars = &computebeforepagevars,
                     columns = &columns,
                     ordervars = &ordervars,
                     sharecolvars = &sharecolvars,
                     sharecolvarsindent = &sharecolvarsindent,
                     overallsummary = &overallsummary,
                     linevars = &linevars,
                     descending = &descending,
                     orderformatted = &orderformatted,
                     orderfreq = &orderfreq,
                     orderdata = &orderdata,
                     noprintvars = &noprintvars,
                     byvars = &byvars,
                     flowvars = &flowvars,
                     widths = &widths,
                     defaultwidths = &defaultwidths,
                     skipvars = &skipvars,
                     pagevars = &pagevars,
                     idvars = &idvars,
                     centrevars = &centrevars,
                     leftvars = &leftvars,
                     rightvars = &rightvars,
                     colspacing = &colspacing,
                     varspacing = &varspacing,
                     formats = &formats,
                     labels = &labels,
                     break1 = &break1,
                     break2 = &break2,
                     break3 = &break3,
                     break4 = &break4,
                     break5 = &break5,
                     proptions = &proptions,
                     nowidowvar = &nowidowvar,
                     splitchar = &splitchar,
                     xmldefaults = &xmldefaults,
                     ynvars = &ynvars,
                     ynorderfmt = &ynorderfmt,
                     yndecodefmt = &yndecodefmt



   ) ;

     %tu_abort;

%mend td_dm3;
