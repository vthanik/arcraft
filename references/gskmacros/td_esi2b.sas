/*----------------------------------------------------------------------------------
/ Macro Name    : td_esi2b.sas
/
/ Macro Version : 1 build 5
/
/ SAS version   : SAS v8.2
/
/ Created By    : Joe Novotny
/
/ Date          : 21DEC2006
/
/ Macro Purpose : Display macro to generate IDSL ESI2b table.  This macro creates the 
/                 report using a call to tu_multisegments which performs a series of
/                 calls to the tu_freq and tu_sumstatsinrows macros. The user can  
/                 produce the default table by using the default values of the segment1-5
/                 parameters as described below. If modifications/additions are required,
/                 the user must pass the required call(s) to tu_freq/tu_sumstatsinrows
/                 via one of the segments. If the user does not require particular segments, 
/                 then setting those segments equal to missing (e.g., segment2=, segment3=) 
/                 when calling this macro will prevent them from being produced (the macro 
/                 will bump the remaining segments up to produce the rest of the table).
/
/ Usage Notes   : 1)  Default segments two and four require two numeric formats (e.g.,
/                     onsetfmt. and durfmt.) for use with the preloadfmt option of tu_freq. 
/                     If users wish to produce the default table, nothing is required - simply 
/                     call the macro and these formats will be created and used by td_esi2b. 
/                     If users wish to use non-standard formats, they may either: A) Create 
/                     them in the WORK library OR B) Create them in a permanent format catalog 
/                     available to this program when ts_setup processes formats from the 
/                     R_GFMTDIR, R_CFMTDIR, R_SFMTDIR and R_RFMTDIR directories. Details of 
/                     the default formats used in td_esi2b are:
/
/                    Segment<n>   Format       Origin         Value required for standard table
/                    ----------   ----------   ----------     -----------------------------------
/                    segment2     onsetfmt.    Created by     1-<15   = ' 1-14'
/                                              td_esi2b or    15-<29  = '15-28'
/                                              user           29-high = ' >28'
/
/                    segment4     durfmt.      Created by     1-<6    = ' 1-5'
/                                              td_esi2b or    6-<11   = '6-10'
/                                              user           11-high = ' >10'
/
/                 2)  PRE-PROCESSING - Default segments two through five (segment2-segment5)
/                     require pre-processing of the standard A&R IDSL AE dataset prior to
/                     being used by tu_freq and tu_sumstatsinrows to produce the table. 
/                     This macro performs the following pre-processing of the data
/                     prior to passing it to the call to tu_multisegments:
/                      a) Sorts input dataset, keeps records where &aeonsetvar ne .
/                      b) Assigns label of 'Time of onset of first occurrence, days' 
/                         to esi2b_onset and &aeonsetvar.
/                      c) Assigns label of 'Duration of first occurrence, days' to 
/                         esi2b_dur and &aedurvar.
/                      d) Keeps records containing the first occurrence of events.
/                      e) Derives esi2b_onset variable from &aeonsetvar and onsetfmt. 
/                         format and outputs to esi2b_onset dataset.
/                      f) Derives esi2b_dur variable from &aedurvar and durfmt. format 
/                         file and outputs to esi2b_dur dataset for records where 
/                         &aedurvar is not missing. 
/                         
/                 3)  The user is free to overwrite the default values of the segment
/                     parameters, but keep in mind that if the two datasets referenced
/                     above are not passed as input to tu_freq and tu_sumstatsinrows, 
/                     the user assumes responsibility for any required pre-processing 
/                     of the data for reporting purposes. The macro assumes any other 
/                     subsetting of the standard A&R AE dataset takes place prior to 
/                     calling td_esi2b (e.g., selecting only on-therapy events, etc.).
/
/                 4)  Many default parameters passed to tu_freq and tu_sumstatsinrows
/                     are populated using the xml file passed as &xmldefaults.
/
/ Macro Design  : PROCEDURE STYLE
/
/ Input Parameters :
/
/ NAME                    DESCRIPTION                                 DEFAULT
/---------------------------------------------------------------------------------------
/ ACROSSCOLVARPREFIX      Passed directly to tu_multisegments.        tt_result
/
/ ACROSSVAR               Passed directly to tu_multisegments.        &g_trtcd    
/
/ ACROSSVARDECODE         Passed directly to tu_multisegments.        &g_trtgrp
/
/ ACROSSVARLISTNAME       Passed directly to tu_multisegments.        <blank>   
/
/ ADDBIGNYN               Passed directly to tu_multisegments.        Y   
/
/ AEONSETFMT              Numeric format to be used for displaying    onsetfmt.
/                         the Time of onset of first occurrence 
/                         segment of the table. Value passed must 
/                         contain the full format (e.g., onsetfmt.
/                         including the .)
/
/ AEONSETVAR              Name of numeric variable containing the     aeactsdy
/                         day of onset of the AE of interest. It
/                         will be used with the format passed via
/                         &aeonsetfmt to display the Time of onset
/                         of first occurrence segment of the table.
/
/ AEDURFMT                Numeric format to be used for displaying    durfmt.
/                         the Duration of first occurrence segment 
/                         of the table. Value passed must contain 
/                         the full format (e.g., durfmt. including 
/                         the .)
/
/ AEDURVAR                Name of numeric variable containing the     aedur
/                         duration of the AE of interest. It will 
/                         be used with the format passed via
/                         &aedurfmt to display the Duration of 
/                         first occurrence segment of the table.
/
/ ALIGNYN                 Passed directly to tu_multisegments.        Y
/
/ BREAK1-BREAK5           Passed directly to tu_multisegments.        <all are blank>
/
/ BYVARS                  Passed directly to tu_multisegments.        <blank>     
/
/ CENTREVARS              Passed directly to tu_multisegments.        <blank>     
/
/ COLSPACING              Passed directly to tu_multisegments.        2     
/
/ COLUMNS                 Passed directly to tu_multisegments.        tt_grplabel tt_segorder tt_summarylevel
/                                                                       tt_code1 tt_decode1 tt_result:
/
/ COMPUTEBEFOREPAGELINES  Passed directly to tu_multisegments.        <blank>
/
/ COMPUTEBEFOREPAGEVARS   Passed directly to tu_multisegments.        <blank>
/
/ DDDATASETLABEL          Passed directly to tu_multisegments.        DD dataset for a table
/
/ DDNAME                  Passed directly to tu_multisegments.        esi2b
/
/ DEFAULTWIDTHS           Passed directly to tu_multisegments.        <blank>
/
/ DENORMYN                Passed directly to tu_multisegments.        Y  
/
/ DESCENDING              Passed directly to tu_multisegments.        <blank>
/
/ DISPLAY                 Passed directly to tu_multisegments.        Y  
/
/ DSETIN                  Passed directly to tu_multisegments.        ardata.ae
/
/ DSETOUT                 Passed directly to tu_multisegments.        <blank>
/
/ FLOWVARS                Passed directly to tu_multisegments.        _ALL_
/
/ FORMATS                 Passed directly to tu_multisegments.        <blank>
/
/ IDVARS                  Passed directly to tu_multisegments.        <blank>
/
/ LABELS                  Passed directly to tu_multisegments.        <blank>
/
/ LABELVARSYN             Passed directly to tu_multisegments.        Y
/
/ LEFTVARS                Passed directly to tu_multisegments.        <blank>
/
/ LINEVARS                Passed directly to tu_multisegments.        <blank>
/
/ NOPRINTVARS             Passed directly to tu_multisegments.        tt_segorder tt_summarylevel tt_code1
/
/ NOWIDOWVAR              Passed directly to tu_multisegments.        <blank>
/
/ ORDERDATA               Passed directly to tu_multisegments.        tt_grplabel
/
/ ORDERFORMATTED          Passed directly to tu_multisegments.        <blank>
/
/ ORDERFREQ               Passed directly to tu_multisegments.        <blank>
/
/ ORDERVARS               Passed directly to tu_multisegments.        tt_segorder tt_grplabel tt_code1 tt_summarylevel
/
/ OVERALLSUMMARY          Passed directly to tu_multisegments.        Y
/
/ PAGEVARS                Passed directly to tu_multisegments.        <blank>
/
/ POSTSUBSET              Passed directly to tu_multisegments.        <blank>
/
/ PROPTIONS               Passed directly to tu_multisegments.        headline
/
/ RIGHTVARS               Passed directly to tu_multisegments.        <blank>
/
/ SEGMENT1-SEGMENT5       Complete calls to tu_freq and               <see macro definition for
/                         tu_multisegments enclosed in %nrstr(),       default values for these params>
/                         used to produce one of the segments 
/                         in esi2b.  Note that the file referenced
/                         in &xmldefaults keyword parameter is used 
/                         to populate some of the parameters in the 
/                         calls to tu_freq and tu_sumstatsinrows 
/                         when producing the standard table.  By 
/                         default, these segments produce the 
/                         following sections of the table:   
/
/                           segment1=Number of Subjects Experiencing
/                           segment2=Time of onset of first occurrence, days <day ranges>
/                           segment3=Time of onset of first occurrence, days <stats>
/                           segment4=Duration of first occurrence, days <day ranges>
/                           segment5=Duration of first occurrence, days <stats>
/
/ SEGMENT6-SEGMENT20      Can be used to add additional segments to   <blank>
/                         the default table.
/
/ SHARECOLVARS            Passed directly to tu_multisegments.        tt_grplabel tt_decode1
/
/ SHARECOLVARSINDENT      Passed directly to tu_multisegments.        2
/
/ SKIPVARS                Passed directly to tu_multisegments.        tt_grplabel
/
/ SPLITCHAR               Passed directly to tu_multisegments.        ~
/
/ STACKVAR1-STACKVAR15    Passed directly to tu_multisegments.        <all are blank>
/
/ VARLABELSTYLE           Passed directly to tu_multisegments.        SHORT 
/
/ VARSPACING              Passed directly to tu_multisegments.        <blank> 
/
/ VARSTODENORM            Passed directly to tu_multisegments.        tt_result 
/
/ WIDTHS                  Passed directly to tu_multisegments.        tt_grplabel 25 tt_decode1 40 tt_result: 10
/
/ XMLDEFAULTS             Passed directly to tu_multisegments.        &g_refdata./tr_esi2b_defaults.xml
/
/ YNDECODEFMT             Passed directly to tu_multisegments.        $yndecod.
/
/ YNORDERFMT              Passed directly to tu_multisegments.        $ynorder.
/
/ YNVARS                  Passed directly to tu_multisegments.        <blank>
/
/---------------------------------------------------------------------------------------
/ Output:               1. Output file in plain ASCII text format containing Summary of
/                          Onset and Duration of the First Occurrence of <event>
/                       2. SAS data set specified in DDNAME in the location specified 
/                          in ts_setup.
/
/ Global macro variables created: None
/
/ Macros called :
/ (@) tr_putlocals
/ (@) tu_putglobals
/ (@) tu_chkvarsexist
/ (@) tu_nobs
/ (@) tu_getdata
/ (@) tu_abort
/ (@) tu_multisegments
/ (@) tu_tidyup
/
/---------------------------------------------------------------------------------------
/ Change Log :
/
/ Modified By             : Shan Lee   
/ Date of Modification    : 20 February 2007  
/ New Version Number      : version 1, build 2   
/ Modification ID         : n/a - the only change is the addition of comments in the 
/                           first line of the macro definition - do not want a 
/                           modification ID to appear in the flyover text.
/ Reason For Modification : The need to add comments (corresponding to flyover text) was
/                           identified during source code review. As this change only
/                           involves the addition of comments to the code, unit testing
/                           will not be repeated.
/
/ Modified By             : Shan Lee   
/ Date of Modification    : 28 February 2007  
/ New Version Number      : version 1, build 3   
/ Modification ID         : SL001
/ Reason For Modification : Create new parameters: segment1a, segment1b, segment1c, 
/                           segment1d, segment2a, segment2b... segment5a, segment5b,
/                           segment5c, segment5d.
/                           Remove old parameters: segment1... segment5.
/                           At the start of parameter validation, segment1a-segment1d will
/                           be concatenated to form the "parameter" segment1, and
/                           segment1 will be validated and used throughout the rest of
/                           the macro etc.
/                           The reason for splitting each segment over multiple
/                           parameters is as follows: in order to check a macro into the
/                           HARP Application, each parameter in the %macro statement must
/                           appear on a separate line. However, the default values for
/                           the old parameters, segment1-segment5, were greater than 255
/                           characters, and SAS only reads the first 255 characters of each 
/                           line in a SAS program.
/
/ Modified By             : Shan Lee   
/ Date of Modification    : 03 May 2007
/ New Version Number      : 1 build 4   
/ Modification ID         : SL002
/ Reason For Modification : Revert back to one parameter per segment: now, each segment 
/                           parameter refers to a table wtihin the XML defaults file.
/                           Each of these tables specifies all the parameters that need 
/                           to be specified for the call to tu_freq or tu_sumstatsinrows
/                           for the given segment.
/
/ Modified By             : Shan Lee   
/ Date of Modification    : 14 May 2007
/ New Version Number      : 1 build 5   
/ Modification ID         : N/a - do not want to insert modification id in flyover text.
/ Reason For Modification : Change the default value of the COLUMNS parameter to refer
/                           directly to tt_result, instead of referring to it via the
/                           macro variable reference &acrosscolvarprefix, which causes
/                           a W-ARNING message to be generated in the log when the default
/                           value is explicitly stated when the macro is called. This 
/                           problem was detected during iteration 1 of user acceptance
/                           testing: please see tracking number 204 on TestDirector for
/                           further details. 
/---------------------------------------------------------------------------------------*/
%macro td_esi2b(acrosscolvarprefix=tt_result, /* Text passed to the PROC TRANSPOSE PREFIX statement in tu_denorm. */
                acrossvar=&g_trtcd, /* Variable(s) that will be transposed to columns   */
                acrossvardecode=&g_trtgrp, /* The name of the decode variable(s) for ACROSSVAR */
                acrossvarlistname=, /* Macro variable name to contain the list of columns created by the transpose of the first variable in VARSTODENORM.*/
                addbignyn=Y, /* Append the population N (N=nn) to the label of the transposed columns containg the results - Y/N */
                aeonsetfmt=onsetfmt., /* Format for creating categories of time of onset of first occurrence */
                aeonsetvar=aeactsdy, /* Name of variable storing time of onset in days */
                aedurfmt=durfmt., /* Format for creating categories of duration */
                aedurvar=aedur, /* Name of variable storing duration in days */
                alignyn=Y, /* Control execution of tu_align */
                break1=, /* Break statements. */
                break2=, /* Break statements. */
                break3=, /* Break statements. */
                break4=, /* Break statements. */
                break5=, /* Break statements. */
                byvars=, /* By variables */
                centrevars=, /* Centre justify variables */
                colspacing=2, /* Overall spacing value. */
                columns=tt_grplabel tt_segorder tt_summarylevel tt_code1 tt_decode1 tt_result:, /* Column parameter */
                computebeforepagelines=, /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt colon labelvar)*/
                computebeforepagevars=, /* Names of variables that shall define the sort order for  Compute Before Page lines */
                dddatasetlabel=DD dataset for a table, /* Label to be applied to the DD dataset */
                defaultwidths=, /* List of default column widths */
                denormyn=Y, /* Transpose result variables from rows to columns across the ACROSSVAR - Y/N? */
                descending=, /* Descending ORDERVARS */
                display=Y, /* Specifies whether the report should be created Valid Values Y or N. If &g_analy_disp is D, DISPLAY shall be ignored*/
                dsetin=ardata.ae, /* DSETIN for all segments.*/
                dsetout=, /* Output summary dataset */
                flowvars=_ALL_, /* Variables with flow option */
                formats=, /* Format specification */
                idvars=, /* ID variables    */
                labels=, /* Label definitions. */
                labelvarsyn=Y, /* Control execution of tu_labelvars */
                leftvars=, /* Left justify variables */
                linevars=, /* Order variable printed with line statements. */
                noprintvars=tt_segorder tt_summarylevel tt_code1, /* No print vars (usually used to order the display) */
                nowidowvar=, /* Variable whose values must be kept together on a page */
                orderdata=tt_grplabel, /* ORDER=DATA variables */
                orderformatted=, /* ORDER=FORMATTED variables */
                orderfreq=, /* ORDER=FREQ variables */
                ordervars=tt_segorder tt_grplabel tt_code1 tt_summarylevel, /* Order variables */
                overallsummary=Y, /* Overall summary line at top of tables */
                pagevars=, /* Break after <var> / page */
                postsubset=, /* SAS expression to be applied to data immediately prior to creation of the permanent presentation dataset */
                proptions=headline, /* PROC REPORT statement options */
                rightvars=, /* Right justify variables */
                segment1 = SUBJECTS, /* Name of table in XML defaults file */
                segment2 = ONSET_PERCENT, /* Name of table in XML defaults file */
                segment3 = ONSET_STATS, /* Name of table in XML defaults file */
                segment4 = DURATION_PERCENT, /* Name of table in XML defaults file */
                segment5 = DURATION_STATS, /* Name of table in XML defaults file */
                segment6 = , /* Name of table in XML defaults file */
                segment7 = , /* Name of table in XML defaults file */
                segment8 = , /* Name of table in XML defaults file */
                segment9 = , /* Name of table in XML defaults file */
                segment10 = , /* Name of table in XML defaults file */
                segment11 = , /* Name of table in XML defaults file */
                segment12 = , /* Name of table in XML defaults file */
                segment13 = , /* Name of table in XML defaults file */
                segment14 = , /* Name of table in XML defaults file */
                segment15 = , /* Name of table in XML defaults file */
                segment16 = , /* Name of table in XML defaults file */
                segment17 = , /* Name of table in XML defaults file */
                segment18 = , /* Name of table in XML defaults file */
                segment19 = , /* Name of table in XML defaults file */
                segment20 = , /* Name of table in XML defaults file */
                sharecolvars=tt_grplabel tt_decode1, /* Order variables that share print space. */
                sharecolvarsindent=2, /* Indentation factor */
                skipvars=tt_grplabel, /* Break after <var> / skip */
                splitchar=~, /* Split character */
                stackvar1=, /* Create Stacked variables (e.g. stackvar1=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
                stackvar2=, /* Create Stacked variables (e.g. stackvar2=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
                stackvar3=, /* Create Stacked variables (e.g. stackvar3=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
                stackvar4=, /* Create Stacked variables (e.g. stackvar4=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
                stackvar5=, /* Create Stacked variables (e.g. stackvar5=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
                stackvar6=, /* Create Stacked variables (e.g. stackvar6=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
                stackvar7=, /* Create Stacked variables (e.g. stackvar7=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
                stackvar8=, /* Create Stacked variables (e.g. stackvar8=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
                stackvar9=, /* Create Stacked variables (e.g. stackvar9=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
                stackvar10=, /* Create Stacked variables (e.g. stackvar10=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
                stackvar11=, /* Create Stacked variables (e.g. stackvar11=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
                stackvar12=, /* Create Stacked variables (e.g. stackvar12=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
                stackvar13=, /* Create Stacked variables (e.g. stackvar13=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
                stackvar14=, /* Create Stacked variables (e.g. stackvar14=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
                stackvar15=, /* Create Stacked variables (e.g. stackvar15=%str(varsin=invid subjid, varout=st_inv_subj,sepc=/,splitc=~)) */
                varlabelstyle=SHORT, /* Specifies the label style for variables (SHORT or STD) */
                varspacing=, /* Spacing for individual variables. */
                varstodenorm=tt_result, /* Variable to be transposed */
                widths=tt_grplabel 25 tt_decode1 40 tt_result: 10, /* Column widths */
                xmldefaults=&g_refdata./tr_esi2b_defaults.xml, /* Location and name of XML defaults file for td macro*/
                yndecodefmt=$yndecod., /* Format for creating decode variables corresponding to YNVARS */
                ynorderfmt=$ynorder., /* Format for creating order variables corresponding to YNVARS */
                ynvars=, /* List of Yes/No variables that require codes and decodes */
               );

  /*
  / Write details of macro start to log
  /---------------------------------------*/
  %local macroversion;
  %let macroversion=1 build 5;

  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=G_TRTCD G_TRTGRP G_POPDATA G_REFDATA G_SUBSET G_CENTID G_SUBJID);

  /*
  / SL002
  /
  / If a segment parameter is non-blank, then check that it is a valid SAS dataset name. 
  /-------------------------------------------------------------------------------------*/

  %local p s ns;
  
  %do p = 1 %to 20;
    %if %length(&&segment&p) gt 0 %then
    %do;
      %if %length(%tu_chknames(&&segment&p, nametype = DATA)) ne 0 %then
      %do;
        %put %str(RTE)RROR: &sysmacroname: SEGMENT&p is not a valid SAS dataset name;
        %put SEGMENT&p = &&segment&p;
        %let g_abort = 1; 
        %tu_abort
      %end;
    %end; /* %if %length(&&segment&p) gt 0 %then */
  %end; /* %do p = 1 %to 20 */

  /*
  / Parameter Validation.
  /----------------------------*/
  %if &aeonsetvar eq %str( ) %then 
     %do;
        %let g_abort=1;
        %tu_abort;
     %end;
  %else %if &aeonsetvar ne %str( ) %then
     %do;
        %if %tu_chkvarsexist(&dsetin.,&aeonsetvar) ne %str( ) %then 
           %do;
              %put %str(RTE)RROR: &sysmacroname: %upcase(&aeonsetvar) does not exist on input dataset %upcase(&dsetin);
              %let g_abort=1;
              %tu_abort;
           %end;
     %end;

  %if &aedurvar eq %str( ) %then
     %do;
        %let g_abort=1;
        %tu_abort;
     %end;
  %else %if &aedurvar ne %str( ) %then
     %do;
        %if %tu_chkvarsexist(&dsetin.,&aedurvar) ne %str( ) %then 
           %do;
              %put %str(RTE)RROR: &sysmacroname: %upcase(&aedurvar) does not exist on input dataset %upcase(&dsetin);
              %let g_abort=1;
              %tu_abort;
           %end;
     %end;


  /*
  / Create onsetfmt if needed.
  /----------------------------*/
  %if &aeonsetfmt eq %str( ) %then
     %do;
       %put %str(RTE)RROR: &sysmacroname: Keyword parameter %nrstr(&aeonsetfmt) must not be blank.;
       %let g_abort=1;
       %tu_abort;
     %end;
  %else
     %do;
           /*
           / Determine format libraries to search.
           /----------------------------------------*/
           %let gfd=1;
           %let fmt_libs=%upcase(WORK %scan( %sysfunc(getoption(fmtsearch)),1,%str(%(%)) ));

           %do %while(%scan(&fmt_libs, &gfd, %str( )) ne %str( ));
              %if &gfd=1 %then
                 %do;
                    %let get_fmt_dir="%trim(%left(%scan(&fmt_libs,&gfd,%str( ))))";
                 %end;
              %else
                 %do;
                    %let get_fmt_dir=&get_fmt_dir,"%trim(%left(%scan(&fmt_libs,&gfd,%str( ))))";
                 %end;
              %let gfd=%eval(&gfd+1);
           %end;


           /*
           / Create macro variable containing just the name of the required format.
           /--------------------------------------------------------------------------*/
           %let _esi2b_onsetfmtname=%upcase(%scan(&aeonsetfmt,1,'.'));


           /*
           / Create working dataset from the SASHELP catalog and
           / if the format does not exist, create it.
           /--------------------------------------------------------*/
           proc append base=work._esi2b_onset_fmt
                       data=SASHELP.VCATALG(where=(index(upcase(objtype),'FORMAT') and
                                                   upcase(libname) in(&get_fmt_dir) and
                                                   upcase(objname) eq "&_esi2b_onsetfmtname"));
           run;

           %if %tu_nobs(work._esi2b_onset_fmt) eq 0 %then
              %do;
                  proc format lib=WORK;
                    value &_esi2b_onsetfmtname
                          1-<15  =' 1-14'
                          15-<29 ='15-28'
                          29-high=' >28'
                    ;
                  run;
              %end;
     %end;

  /*
  / Create durfmt if needed.
  /--------------------------*/
  %if &aedurfmt eq %str( ) %then
     %do;
       %put %str(RTE)RROR: &sysmacroname: Keyword parameter %nrstr(&aedurfmt) must not be blank.;
       %let g_abort=1;
       %tu_abort;
     %end;
  %else
     %do;
           /*
           / Determine format libraries to search.
           /----------------------------------------*/
           %let gfd=1;
           %let fmt_libs=%upcase(WORK %scan( %sysfunc(getoption(fmtsearch)),1,%str(%(%)) ));

           %do %while(%scan(&fmt_libs, &gfd, %str( )) ne %str( ));
              %if &gfd=1 %then
                 %do;
                    %let get_fmt_dir="%trim(%left(%scan(&fmt_libs,&gfd,%str( ))))";
                 %end;
              %else
                 %do;
                    %let get_fmt_dir=&get_fmt_dir,"%trim(%left(%scan(&fmt_libs,&gfd,%str( ))))";
                 %end;
              %let gfd=%eval(&gfd+1);
           %end;

           /*
           / Create macro variable containing just the name of the required format.
           /--------------------------------------------------------------------------*/
           %let _esi2b_durfmtname=%upcase(%scan(&aedurfmt,1,'.'));


           /*
           / Create working dataset from the SASHELP catalog and
           / if the format does not exist, create it.
           /--------------------------------------------------------*/
           proc append base=work._esi2b_dur_fmt
                       data=SASHELP.VCATALG(where=(index(upcase(objtype),'FORMAT') and
                                                   upcase(libname) in(&get_fmt_dir) and
                                                   upcase(objname) eq "&_esi2b_durfmtname"));
           run;

           %if %tu_nobs(work._esi2b_dur_fmt) eq 0 %then
              %do;
                  proc format lib=WORK;
                    value &_esi2b_durfmtname
                          1-<6   =' 1-5'
                          6-<11  ='6-10'
                          11-high=' >10'
                    ;
                  run;
              %end;
     %end;

  /*
  / SL002
  /
  / If the segment parameters are not numbered sequentially, then renumber them: i.e. if
  / segment1 and segment3 are populated, but segment2 is blank, then renumber segment3 to
  / segment2.  
  / Reassign the values of the segment parameters, so that the (XML) dataset name is 
  / replaced by a list of parameters for tu_freq/tu_sumstatsinrows. 
  /-------------------------------------------------------------------------------------*/
  
  libname xmldef xml "&xmldefaults" access=readonly;

  %let s = 0;

  %do p = 1 %to 20;
    %if %length(&&segment&p) gt 0 %then
    %do;

      %let s = %eval(&s + 1);

      %if &s ne &p %then %put %str(RTN)OTE: &sysmacroname: segment&p will be renumbered to segment&s;

      data _null_;
        length name $200 value $500 segment $10000;
        set xmldef.&&segment&p end = eof;
        retain segment;
        name=upcase(name);
        if _n_ eq 1 then segment = trim(upcase(type)) || ' ' || trim(name) || "=" || value;
        else segment = trim(segment) || "," || trim(name) || "=" || value;
        if eof then call symput("segment&s", trim(segment));
      run;

      %let aepts = %nrstr(&aepts);
      %let segment&s = %nrbquote(&&segment&s);
      %put %str(RTN)OTE: &sysmacroname: value of segment&s has been re-assigned to: &&segment&s;

    %end; /* %if %length(&&segment&p) gt 0 %then */
  %end; /* %do p = 1 %to 20 */

  %let ns = &s;

  /*
  / Pre-process data for the time of onset and duration sections of the table. Code
  / takes the first occurrence of the event (e.g., first.dot processing below). Note:
  / if two records are identical with respect to &aeonsetvar, then the event with the 
  / longest duration (e.g., descending &aedurvar) will be selected as the "first 
  / occurrences of the event. The esi2b_onset variable is created as a text version 
  / of &aeonsetvar, formatted with &aeonsetfmt. The esi2b_dur variable is created as 
  / a text version of &aedurvar, formatted with &aedurfmt. Note that only nonmissing 
  / &aeonsetvar values are kept. Additionally, for the duration dataset, only
  / nonmissing &aedurvar values are kept.
  /----------------------------------------------------------------------------------*/
  %tu_getdata(dsetin=&dsetin,dsetout1=_esi2b_ae);

  proc sort data=_esi2b_ae(where=(&aeonsetvar ne .)) out=_esi2b_aesorted;
    by &g_subjid &g_centid &g_trtcd &g_trtgrp &aeonsetvar descending &aedurvar;
  run;

  %if %tu_nobs(work._esi2b_ae) ne %tu_nobs(work._esi2b_aesorted) %then
    %do;
      %put %str(RTE)RROR: &sysmacroname: Missing values of %upcase(&aeonsetvar) exist on input dataset %upcase(&dsetin).  &sysmacroname will terminate.;
      %let g_abort=1;
      %tu_abort;
    %end;

  data _esi2b_onset _esi2b_dur;
        attrib esi2b_onset &aeonsetvar label='Time of onset of first occurrence, days'
               esi2b_dur   &aedurvar   label='Duration of first occurrence, days';
    set _esi2b_aesorted;
        by &g_subjid &g_centid &g_trtcd &g_trtgrp &aeonsetvar descending &aedurvar;
        if first.&g_subjid;
        esi2b_onset=put(&aeonsetvar.,&aeonsetfmt.);
    output _esi2b_onset;
        if &aedurvar ne .;
        esi2b_dur=put(&aedurvar.,&aedurfmt.);
    output _esi2b_dur;
  run;

  /*
  / Place list of AEPTs for use in table label into &aepts macro variable.
  /--------------------------------------------------------------------------*/
  proc sql noprint;
    select distinct trim(left(aept)) into :aepts separated by ' or '
       from _esi2b_aesorted;
  quit;

  %if %length(&aepts) gt 159 %then %do;
    %put %str(RTW)ARNING: &sysmacroname: list of preferred terms corresponding to events of;
    %put interest will be stored in the variable tt_decode1, if the default macro parameter;
    %put values are used. The list of preferred terms has become long, and might be truncated;
    %put in the data display.;
  %end;

  %if %length(&aepts) gt 328 %then %do;
    %put %str(RTW)ARNING: &sysmacroname: list of preferred terms corresponding to events of;
    %put interest will be stored in the variable tt_decode1, if the default macro parameter;
    %put values are used. The list of preferred terms has become very long, and might cause;
    %put a problem for tu_multisegments.;
  %end;

  /*
  / Call tu_multisegments with segment parameters populated by the reordered macro segments.
  /-------------------------------------------------------------------------------------------*/
  %tu_multisegments(
                    acrosscolvarprefix=&acrosscolvarprefix,
                    acrossvar=&acrossvar,
                    acrossvardecode=&acrossvardecode,
                    acrossvarlistname=&acrossvarlistname,
                    addbignyn=&addbignyn, 
                    alignyn=&alignyn,
                    %do b=1 %to 5;
                       break&b=&&break&b,
                    %end;
                    byvars=&byvars,
                    centrevars=&centrevars,
                    colspacing=&colspacing,
                    columns=&columns, 
                    computebeforepagelines=&computebeforepagelines,
                    computebeforepagevars=&computebeforepagevars,
                    dddatasetlabel=&dddatasetlabel,
                    ddname=,
                    defaultwidths=&defaultwidths,
                    denormyn=&denormyn,
                    descending=&descending,
                    display=&display,
                    dsetin=&dsetin,
                    dsetout=&dsetout,
                    flowvars=&flowvars,
                    formats=&formats,
                    idvars=&idvars,
                    labels=&labels,
                    labelvarsyn=&labelvarsyn,
                    leftvars=&leftvars,
                    linevars=&linevars,
                    noprintvars=&noprintvars,
                    nowidowvar=&nowidowvar,
                    orderdata=&orderdata,
                    orderformatted=&orderformatted,
                    orderfreq=&orderfreq,
                    ordervars=&ordervars,
                    overallsummary=&overallsummary,
                    pagevars=&pagevars,
                    postsubset=&postsubset,
                    proptions=&proptions,
                    rightvars=&rightvars,
                    %do j=1 %to &ns;
                       segment&j=&&segment&j,
                    %end;
                    sharecolvars=&sharecolvars,
                    sharecolvarsindent=&sharecolvarsindent, 
                    skipvars=&skipvars,
                    splitchar=&splitchar,
                    %do st=1 %to 15;
                       stackvar&st=&&stackvar&st,
                    %end;
                    varlabelstyle=&varlabelstyle,
                    varspacing=&varspacing,
                    varstodenorm=&varstodenorm,
                    widths=&widths,
                    xmldefaults=,
                    yndecodefmt=&yndecodefmt,
                    ynorderfmt=&ynorderfmt,
                    ynvars=&ynvars
                   );

  /*
  / Call tu_tidyup to clear temporary data set and fields.
  /---------------------------------------------------------*/
  %tu_tidyup(rmdset=_esi2b:,
             glbmac=none);
 
%mend td_esi2b;
