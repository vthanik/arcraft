/*----------------------------------------------------------------------------------
/ Macro Name    : td_esi1.sas
/
/ Macro Version : 1 build 5
/
/ SAS version   : SAS v8.2
/
/ Created By    : Joe Novotny
/
/ Date          : 19DEC2006
/
/ Macro Purpose : Display macro to generate IDSL ESI1 table.  This macro creates
/                 the report using a call to tu_multisegments which performs a
/                 series of calls to the tu_freq macro. The user can produce the 
/                 default esi1 table by using the default values of the segment1-9
/                 parameters as described below.  If modifications/additions are 
/                 required, the user must pass the required call(s) to tu_freq
/                 via one of the segments.  If the user does not require particular
/                 segments (e.g., if Frequency or Maximum Intensity data were not
/                 collected), then setting those segments equal to missing (e.g.,
/                 segment6=, segment7=) when calling this macro will prevent the 
/                 macro from producing them. The remaining segments will be bumped
/                 up to produce the rest of the table. Table sections are produced
/                 based on segment order when calling td_esi1.
/
/ Usage Notes   : 1) Several default segments require pre-processing of the standard
/                 A&R IDSL AE dataset before it is passed to tu_freq for reporting.
/                 This processing is done within td_esi1 as described below.
/
/                   a) segment3 - Event Characteristics:
/                                 To perform the pre-processing requried to
/                                 produce the Event Characteristics segment,
/                                 td_esi1 looks for the keyword _ESI1_EVENTCHAR
/                                 within the text passed as segments. If the user 
/                                 overwrites segment3, this keyword must still be
/                                 found for the macro to perform the pre-processing.
/                                 The pre-processing results in the following two 
/                                 working datasets being created for use in the 
/                                 call to tu_freq: _esi1_eventchar_numer and 
/                                 _esi1_eventchar_denom.
/
/                   b) segment4 - Number of Occurrences:
/                                 To perform the pre-processing required to
/                                 produce the Number of Occurrences segment,
/                                 td_esi1 looks for the keyword _ESI1_OCCURRENCES
/                                 within the text passed as segments. If the user 
/                                 overwrites segment4, this keyword must still be
/                                 found for the macro to perform the pre-processing. 
/                                 The pre-processing results in the following 
/                                 working dataset being created for use in the 
/                                 call to tu_freq: _esi1_occurrences.
/                 
/                   c) segment7, segment8, segment9:
/                                 To perform the pre-processing required to produce 
/                                 these segments, td_esi1 looks for the keywords 
/                                 in the below table within the text passed as 
/                                 segments. If the user overwrites these segments, 
/                                 these keywords must still be found for the macro 
/                                 to perform the pre-processing. The pre-processing 
/                                 ensures that "Not applicable" records are considered 
/                                 valid values only if no other code/decode values
/                                 are present for a given patient.
/                                 
/                                 segment      section              keyword
/                                 -------      -------              -------
/                                 segment7     Maximum Intensity    _ESI1_AESEVCD
/                                 segment8     Maximum Grade        _ESI1_AETOXCD
/                                 segment9     Action Taken         _ESI1_AEACTRCD
/
/                 2) Many of the default values used to populate the calls to tu_freq
/                    are stored in the xml file passed via the xmldefaults parameter.
/
/                 3) The default segments require several formats for use with the preloadfmt
/                    option of tu_freq. Required formats are described below. For using the 
/                    formats required in segment3 and segment4 (e.g., $evntchr. and noc.), the
/                    user has several options. If users wish to use the values created by
/                    the macro to produce the default table, nothing is required - simply call
/                    the macro and these formats will be created by td_esi1. If users wish to 
/                    use non-standard formats, they may do so in either of two ways: A) Create 
/                    them in the WORK library OR B) The user may create the format in a permanent 
/                    format catalog which will then be available for use with this program when 
/                    ts_setup processes formats from the R_GFMTDIR, R_CFMTDIR, R_SFMTDIR and 
/                    R_RFMTDIR directories (keep in mind - if you rename the formats, you must
/                    also repopulate the segment parameters which use them and the &evntchr 
/                    and/or &noc params as well. Details of the formats used in td_esi1 are: 
/
/                    Segment<n>   Format       Origin         Value required for standard table
/                    ----------   ----------   ----------     -----------------------------------
/                    segment3     $evntchar.   Created by     1=n, 2=Serious, 3=Drug-related, 
/                                              td_esi1 or     4=Leading to Withdrawal, 5=Severe,
/                                              user           6=Fatal
/                          
/                    segment4     noc.         Created by     1=One 
/                                              td_esi1 or     2=Two
/                                              user           3-99999999=Three or more
/
/                    segment5     $aeouts.     Standard       see IDSL standard
/                     
/                    segment6     $aefreqs.    Standard       see IDSL standard
/                    
/                    segment7     $aeints.     Standard       see IDSL standard
/                      
/                    segment8     $aetoxs.     Standard       see IDSL standard
/
/                    segment9     $aeactts.    Standard       see IDSL standard
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
/ COLUMNS                 Passed directly to tu_multisegments.        tt_segorder tt_grplabel tt_code1 
/
/ COMPUTEBEFOREPAGELINES  Passed directly to tu_multisegments.        <blank>
/
/ COMPUTEBEFOREPAGEVARS   Passed directly to tu_multisegments.        <blank>
/
/ DDDATASETLABEL          Passed directly to tu_multisegments.        DD dataset for a table
/
/ DDNAME                  Passed directly to tu_multisegments.        esi1
/
/ DEFAULTWIDTHS           Passed directly to tu_multisegments.        <blank>
/
/ DENORMYN                Passed directly to tu_multisegments.         Y  
/
/ DESCENDING              Passed directly to tu_multisegments.         <blank>
/
/ DISPLAY                 Passed directly to tu_multisegments.         Y  
/
/ DSETIN                  Passed directly to tu_multisegments.         ardata.ae
/
/ DSETOUT                 Passed directly to tu_multisegments.         <blank>
/
/ EVNTCHR                 Character format to be used for displaying   $evntchr.
/                         the event characteristics segment of 
/                         the table. Value passed must contain
/                         the full format (e.g., $evntchr. -
/                         including the $ and the .)
/
/ FLOWVARS                Passed directly to tu_multisegments.         _ALL_
/
/ FORMATS                 Passed directly to tu_multisegments.         <blank>
/
/ IDVARS                  Passed directly to tu_multisegments.         <blank>
/
/ LABELS                  Passed directly to tu_multisegments.         <blank>
/
/ LABELVARSYN             Passed directly to tu_multisegments.         Y
/
/ LEFTVARS                Passed directly to tu_multisegments.         <blank>
/
/ LINEVARS                Passed directly to tu_multisegments.         <blank>
/
/ NOC                     Numeric format to be used for displaying     noc.
/                         the number of occurrences segment of 
/                         the table. Value passed must contain
/                         the full format (e.g., noc. - including
/                         the .)
/
/ NOPRINTVARS             Passed directly to tu_multisegments.         tt_segorder tt_code1
/
/ NOWIDOWVAR              Passed directly to tu_multisegments.         <blank>
/
/ ORDERDATA               Passed directly to tu_multisegments.         <blank>
/
/ ORDERFORMATTED          Passed directly to tu_multisegments.         <blank>
/
/ ORDERFREQ               Passed directly to tu_multisegments.         <blank>
/
/ ORDERVARS               Passed directly to tu_multisegments.         tt_segorder tt_grplabel tt_code1
/
/ OVERALLSUMMARY          Passed directly to tu_multisegments.         Y
/
/ PAGEVARS                Passed directly to tu_multisegments.         <blank>
/
/ POSTSUBSET              Passed directly to tu_multisegments.         <blank>
/
/ PROPTIONS               Passed directly to tu_multisegments.         headline
/
/ RIGHTVARS               Passed directly to tu_multisegments.         <blank>
/
/ SEGMENT1-SEGMENT9       Complete calls to tu_freq, enclosed         <see macro definition for
/                         in %nrstr(), used to produce one of          default values for these params>
/                         the segments in esi1.  Note that the
/                         xml defaults file is used to populate
/                         some of the parameters in the calls to 
/                         tu_freq to produce the standard table. 
/                         By default, these segments produce the
/                         following sections of the table:   
/
/                            segment1=Number of Subjects with Events 
/                            segment2=Number of Events
/                            segment3=Event Characteristics
/                            segment4=Number of Occurrences
/                            segment5=Outcome
/                            segment6=Frequency
/                            segment7=Maximum Intensity
/                            segment8=Maximum Grade
/                            segment9=Action Taken
/
/ SEGMENT10-SEGMENT20     Can be used to add additional segments to   <blank>
/                         the default table.
/
/ SHARECOLVARS            Passed directly to tu_multisegments.         tt_grplabel tt_decode1
/
/ SHARECOLVARSINDENT      Passed directly to tu_multisegments.         2
/
/ SKIPVARS                Passed directly to tu_multisegments.         tt_grplabel
/
/ SPLITCHAR               Passed directly to tu_multisegments.         ~
/
/ STACKVAR1-STACKVAR15    Passed directly to tu_multisegments.         <all are blank>
/
/ VARLABELSTYLE           Passed directly to tu_multisegments.         SHORT 
/
/ VARSPACING              Passed directly to tu_multisegments.         <blank> 
/
/ VARSTODENORM            Passed directly to tu_multisegments.         tt_result 
/
/ WIDTHS                  Passed directly to tu_multisegments.         tt_grplabel 25 tt_decode1 40 tt_result: 10
/
/ XMLDEFAULTS             This file is used to pass several            &g_refdata./tr_esi1_defaults.xml
/                         default params to the segments.
/
/ YNDECODEFMT             Passed directly to tu_multisegments.         $yndecod.
/
/ YNORDERFMT              Passed directly to tu_multisegments.         $ynorder.
/
/ YNVARS                  Passed directly to tu_multisegments.         <blank>
/
/
/---------------------------------------------------------------------------------------
/ Output:               1. Output file in plain ASCII text format containing Events of 
/                          Special Interest summary
/                       2. SAS data set specified in DDNAME in the location specified 
/                          in ts_setup.
/
/ Global macro variables created: None
/
/ Macros called :
/ (@) tr_putlocals
/ (@) tu_putglobals
/ (@) tu_abort
/ (@) tu_nobs
/ (@) tu_getdata
/ (@) tu_chkvarsexist
/ (@) tu_multisegments
/ (@) tu_tidyup
/
/---------------------------------------------------------------------------------------
/ Change Log :
/
/ Modified By             : Shan Lee   
/ Date of Modification    : 21 February 2007  
/ New Version Number      : version 1, build 2   
/ Modification ID         : n/a - the only change is the addition of comments in the 
/                           first statement of the macro definition - do not want a 
/                           modification ID to appear in the flyover text.
/ Reason For Modification : Need to add comments corresponding to flyover text. As this
/                           change only involves the addition of comments to the code,
/                           unit testing will not be repeated.
/
/ Modified By             : Shan Lee   
/ Date of Modification    : 23 February 2007  
/ New Version Number      : version 1, build 3   
/ Modification ID         : SL001
/ Reason For Modification : Create new parameters: segment1a, segment1b, segment1c, 
/                           segment1d, segment2a, segment2b... segment9a, segment9b,
/                           segment9c, segment9d.
/                           Remove old parameters: segment1... segment9.
/                           At the start of parameter validation, segment1a-segment1d will
/                           be concatenated to form the "parameter" segment1, and
/                           segment1 will be validated and used throughout the rest of
/                           the macro etc.
/                           The reason for splitting each segment over multiple
/                           parameters is as follows: in order to check a macro into the
/                           HARP Application, each parameter in the %macro statement must
/                           appear on a separate line. However, the default values for
/                           the old parameters, segment1-segment9, were greater than 255
/                           characters, and SAS only reads the first 255 characters of each 
/                           line in a SAS program.
/
/ Modified By             : Shan Lee   
/ Date of Modification    : 02 May 2007  
/ New Version Number      : version 1, build 4
/ Modification ID         : SL002
/ Reason For Modification : Revert back to having one parameter per segment; however, the
/                           value of each segment parameter should now be the name of a 
/                           dataset that is defined in the XML defaults file - each
/                           dataset in the XML defaults file now defines a tu_freq or 
/                           tu_sumstatsinrows call. 
/
/ Modified By             : Shan Lee   
/ Date of Modification    : 09 May 2007  
/ New Version Number      : version 1, build 5
/ Modification ID         : SL003
/ Reason For Modification : Do not need to create a temporary dataset for the action taken
/                           segment, because the values of action taken are mutually 
/                           exclusive, therefore the overall DSETIN dataset can be read-in
/                           directly for this segment. This modification is a result of 
/                           feedback during round 1 of UAT.
/---------------------------------------------------------------------------------------*/
%macro td_esi1(acrosscolvarprefix=tt_result, /* Text passed to the PROC TRANSPOSE PREFIX statement in tu_denorm. */
               acrossvar=&g_trtcd, /* Variable(s) that will be transposed to columns   */
               acrossvardecode=&g_trtgrp, /* The name of the decode variable(s) for ACROSSVAR */
               acrossvarlistname=, /* Macro variable name to contain the list of columns created by the transpose of the first variable in VARSTODENORM.*/
               addbignyn=Y, /* Append the population N (N=nn) to the label of the transposed columns containg the results - Y/N */
               alignyn=Y, /* Control execution of tu_align */
               break1=, /* Break statements. */
               break2=, /* Break statements. */
               break3=, /* Break statements. */
               break4=, /* Break statements. */
               break5=, /* Break statements. */
               byvars=, /* By variables */
               centrevars=, /* Centre justify variables */
               colspacing=2, /* Overall spacing value. */
               columns=tt_segorder tt_grplabel tt_code1 tt_decode1 tt_result:, /* Column parameter */
               computebeforepagelines=, /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt colon labelvar)*/
               computebeforepagevars=, /* Names of variables that shall define the sort order for  Compute Before Page lines */
               dddatasetlabel=DD dataset for a table, /* Label to be applied to the DD dataset */
               defaultwidths=, /* List of default column widths */
               denormyn=Y, /* Transpose result variables from rows to columns across the ACROSSVAR - Y/N? */
               descending=, /* Descending ORDERVARS */
               display=Y, /* Specifies whether the report should be created Valid Values Y or N. If &g_analy_disp is D, DISPLAY shall be ignored*/
               dsetin=ardata.ae, /* DSETIN for all segments.*/
               dsetout=, /* Output summary dataset */
               evntchr=$evntchr., /* Format for categorising event characteristics */
               flowvars=_ALL_, /* Variables with flow option */
               formats=, /* Format specification */
               idvars=, /* ID variables    */
               labels=, /* Label definitions. */
               labelvarsyn=Y, /* Control execution of tu_labelvars */
               leftvars=, /* Left justify variables */
               linevars=, /* Order variable printed with line statements. */
               noc=noc., /* Format for categorising number of occurrences */
               noprintvars=tt_segorder tt_code1, /* No print vars (usually used to order the display) */
               nowidowvar=tt_grplabel, /* Variable whose values must be kept together on a page */
               orderdata=, /* ORDER=DATA variables */
               orderformatted=, /* ORDER=FORMATTED variables */
               orderfreq=, /* ORDER=FREQ variables */
               ordervars=tt_segorder tt_grplabel tt_code1, /* Order variables */
               overallsummary=Y, /* Overall summary line at top of tables */
               pagevars=, /* Break after <var> / page */
               postsubset=, /* SAS expression to be applied to data immediately prior to creation of the permanent presentation dataset */
               proptions=headline, /* PROC REPORT statement options */
               rightvars=, /* Right justify variables */
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
               xmldefaults=&g_refdata/tr_esi1_defaults.xml, /* Location and name of XML defaults file for td macro*/
               yndecodefmt=$yndecod., /* Format for creating decode variables corresponding to YNVARS */
               ynorderfmt=$ynorder., /* Format for creating order variables corresponding to YNVARS */
               ynvars=, /* List of Yes/No variables that require codes and decodes */
               segment1 = subjects,
               segment2 = events,
               segment3 = characteristics,
               segment4 = occurrences,
               segment5 = outcome,
               segment6 = frequency,
               segment7 = intensity,
               segment8 = grade,
               segment9 = action,
               segment10 =,
               segment11 =,
               segment12 =,
               segment13 =,
               segment14 =,
               segment15 =,
               segment16 =,
               segment17 =,
               segment18 =,
               segment19 =,
               segment20 =
              );

  /*
  / Write details of macro start to log
  /---------------------------------------------*/
  %local macroversion;
  %let macroversion=1 build 5;

  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=G_TRTCD G_TRTGRP G_POPDATA G_REFDATA G_SUBSET G_CENTID G_SUBJID);

  %local p s ns;

  /*
  / SL002
  /
  / If a segment parameter is non-blank, then check that it is a valid SAS dataset name. 
  /-------------------------------------------------------------------------------------*/
  
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

      %let segment&s = %nrbquote(&&segment&s);
      %put %str(RTN)OTE: &sysmacroname: value of segment&s has been re-assigned to: &&segment&s;


    %end; /* %if %length(&&segment&p) gt 0 %then */
  %end; /* %do p = 1 %to 20 */

  %let ns = &s;

  /*
  / Preprocessing for the Event Characteristics segment:
  / Perform parameter validation for &evntchr format param, determine 
  / if the required format exists and create if necessary. Perform
  / additional processing on input dataset, &dsetin.
  /-------------------------------------------------------------------*/
  %do e=1 %to 20;
     %if %index(%nrbquote(%upcase(&&segment&e)),_ESI1_EVENTCHAR) gt 0 %then 
        %do;
           %if &evntchr eq %str( ) %then 
              %do;
                %put %str(RTE)RROR: &sysmacroname: Keyword parameter %nrstr(&evntchr) has value " &evntchr. " and must not be blank. &sysmacroname will terminate.;
                %let g_abort=1;
                %tu_abort;
              %end;

           /*
           / Create &evntchr format if needed. First, determine libraries to search.
           /--------------------------------------------------------------------------*/
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
           / Strip $ and . off format passed in &evntchr
           /---------------------------------------------*/
           data _null_;
             call symput("_esi1_evntfmtname",upcase(compress("&evntchr.",'$.')));
           run;

           /*
           / Create working dataset from the SASHELP catalog and
           / if the format does not exist, create it.
           /--------------------------------------------------------*/
           proc append base=work._esi1_evntchr_fmt
                       data=SASHELP.VCATALG(where=(index(upcase(objtype),'FORMAT') and
                                                   upcase(libname) in(&get_fmt_dir) and 
                                                   upcase(objname) eq "&_esi1_evntfmtname"));
           run;

           %if %tu_nobs(work._esi1_evntchr_fmt) eq 0 %then 
              %do;
                  proc format lib=WORK;
                    value $&_esi1_evntfmtname 
                          '1'='n'
                          '2'='Serious'
                          '3'='Drug-related'
                          '4'='Leading to Withdrawal'
                          '5'='Severe'
                          '6'='Fatal'
                    ;
                  run;
              %end;


           /*
           / Pre-process data for Event Characteristics segment. The "n" row for 
           / Event Characteristics represents the number of subjects who had 
           / a) a serious event, b) a drug-related event, c) an event leading to
           / withdrawal, d) a severe event or e) a fatal event.  The code checks
           / checks to ensure the required variables actually exist on the input
           / dataset prior to coding the algorithm to derive Event Characteristics.
           /-------------------------------------------------------------------------*/
           %tu_getdata(dsetin=&dsetin,dsetout1=_esi1_eventchar);

           %local eventsortbyvars;
           %let eventsortbyvars=&g_subjid &g_centid &g_trtcd &g_trtgrp;

           proc sort data=_esi1_eventchar;
             by &eventsortbyvars;
           run;

           data _esi1_eventchar_denom _esi1_eventchar_numer;
             attrib eventchar length=$22 eventcharcd length=$1;
             set _esi1_eventchar(in=a);
             by &eventsortbyvars;
             if a then output _esi1_eventchar_denom;
             if first.&g_subjid then
               do;
                 eventcharcd='1';
                 eventchar='n';
                 output _esi1_eventchar_numer;
               end;
             %if %length(%tu_chkvarsexist(_esi1_eventchar,aeser)) lt 1 %then 
               %do;
                 if upcase(aeser)='Y' then 
                   do;
                     eventcharcd='2';
                     eventchar='Serious';
                     output _esi1_eventchar_numer;
                   end;
               %end;
             %if %length(%tu_chkvarsexist(_esi1_eventchar,aerel)) lt 1 %then 
               %do;
                 if upcase(aerel)='Y' then 
                   do;
                     eventcharcd='3';
                     eventchar='Drug-related';
                     output _esi1_eventchar_numer;
                   end;
               %end;
             %if %length(%tu_chkvarsexist(_esi1_eventchar,aewd)) lt 1 %then 
               %do;
                 if upcase(aewd)='Y' then 
                   do;
                     eventcharcd='4';
                     eventchar='Leading to Withdrawal';
                     output _esi1_eventchar_numer;
                   end;
               %end;
             %if %length(%tu_chkvarsexist(_esi1_eventchar,aesevcd)) lt 1 %then 
               %do;
                 if aesevcd='3' then 
                   do;
                     eventcharcd='5';
                     eventchar='Severe';
                     output _esi1_eventchar_numer;
                   end;
               %end;
             %if %length(%tu_chkvarsexist(_esi1_eventchar,aeoutcd)) lt 1 %then 
               %do;
                 if aeoutcd='5' then 
                   do;
                     eventcharcd='6';
                     eventchar='Fatal';
                     output _esi1_eventchar_numer;
                   end;
               %end;
           run;

           proc sort data=_esi1_eventchar_numer nodupkey;
             by &eventsortbyvars eventcharcd eventchar;
           run;   

        %end;   *** end processing on _ESI1_EVENTCHAR dataset;
  %end;   *** end e=1 to 20 looping;


  /*
  / Preprocessing for the Number of Occurrences segment:
  / Perform parameter validation for &noc format param, determine 
  / if the required format exists and create if necessary. Perform
  / additional processing on input dataset, &dsetin.
  /-------------------------------------------------------------------*/
  %do o=1 %to 20;
     %if %index(%nrbquote(%upcase(&&segment&o)),_ESI1_OCCURRENCES) gt 0 %then 
        %do;
           /*
           / Create &noc if it does not already exist.
           /-----------------------------------------------*/
           %if &noc eq %str( ) %then 
              %do;
                %put %str(RTE)RROR: &sysmacroname: Keyword parameter %nrstr(&noc) has value " &noc. " and must not be blank. &sysmacroname will terminate.;
                %let g_abort=1;
                %tu_abort;
              %end;

           /*
           / Create &noc format if needed. First, determine libraries to search.
           /--------------------------------------------------------------------------*/
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
           / Strip . off format passed in &noc
           /------------------------------------*/
           data _null_;
             call symput("_esi1_nocfmtname",upcase(compress("&noc.",'.')));
           run;


           /*
           / Create working dataset from the SASHELP catalog and
           / if the format does not exist, create it.
           /--------------------------------------------------------*/
           proc append base=work._esi1_noc_fmt
                       data=SASHELP.VCATALG(where=(index(upcase(objtype),'FORMAT') and
                                                   upcase(libname) in(&get_fmt_dir) and 
                                                   upcase(objname) eq "&_esi1_nocfmtname"));
           run;

           %if %tu_nobs(work._esi1_noc_fmt) eq 0 %then 
              %do;
                  proc format lib=WORK;
                    value &_esi1_nocfmtname 
                          1='One'
                          2='Two'
                          3-high='Three or more'
                    ;
                  run;
              %end;


           /*
           / Perform necessary pre-processing for Number of Occurrences segment:
           / Retrieve subject-level frequency count of subject events and join 
           / this information to subject records.
           /-----------------------------------------------------------------------*/
           %tu_getdata(dsetin=&dsetin,dsetout1=_esi1_occurrences);

           proc freq data=_esi1_occurrences noprint;
             tables &g_subjid / list missing out=_esi1_occ_freqs;
           run;

           proc sql noprint;
             create table _esi1_occurrences as 
               select distinct a.*,
                               b.count as countcd,
                               put(b.count,&noc.) as count length=14 label='Number of occurrences'
                  from _esi1_occurrences as a
                    left join
                       _esi1_occ_freqs as b
                    on a.&g_subjid=b.&g_subjid;
           quit;

        %end; *** end _ESI1_OCCURRENCES processing;
  %end; *** end o=1 to 20 looping;


  /*
  / Preprocess data for segments containing variables with codelists containing the
  / "X=Not applicable" combination. This ensures that subjects reporting only a single
  / event coded "X=Not applicable" are counted as such, but that subjects reporting 
  / more than a single event where at least one event has a valid code (e.g., not "Not 
  / applicable"), are reported using the most "applicable" information available (e.g., 
  / only using "Not applicable" records if they are the only records we have). 
  / 
  / SL003 - the code for action taken, aeactrcd, is mutually exclusive and therefore 
  /         should not be included in this list.
  /--------------------------------------------------------------------------------------*/
  %local nonappcodevars nonappsortby inonapp numnonapp;
  %let nonappcodevars=aesevcd aetoxcd;               *** variables with X=Not applicable in code list;
  %let nonappsortby=&g_subjid &g_centid &g_trtcd &g_trtgrp;   *** sort-by variable;

  %let inonapp=1;
  %do %while(%scan(&nonappcodevars,&inonapp,%str( )) ne %str( ));
     %let numnonapp=&inonapp;                                 *** numnonapp=number of vars in nonappcodevars;
     %let inonapp=%eval(&inonapp+1);
  %end;

  %do n=1 %to 20;
     %if %nrbquote(&&segment&n) ne %then 
        %do;
           %do i=1 %to &numnonapp;
              %let nonappcode&i=%upcase(%scan(&nonappcodevars,&i,%str( )));
 
              %if %index(%nrbquote(%upcase(&&segment&n)),_ESI1_&&nonappcode&i) gt 0 %then 
                 %do;
                    %tu_getdata(dsetin=&dsetin,dsetout1=_esi1_&&nonappcode&i);

                    /*
                    / Since the ASCII sort sequence places character representations of numbers
                    / before letters, and we want 'X' to have lower priority than '1' through '5', 
                    / recode variable values from 'X' to '-' so they sort before records whose
                    / variables contain character representations of numeric values.
                    /------------------------------------------------------------------------*/
                    data _esi1_&&nonappcode&i;
                      set _esi1_&&nonappcode&i;
                      changeflag='0';
                      if upcase(&&nonappcode&i)='X' then 
                        do;
                          &&nonappcode&i='-';
                          changeflag&i='1';
                        end;
                    run;

                    proc sort data=_esi1_&&nonappcode&i;
                      by &nonappsortby &&nonappcode&i;
                    run;

                    /*
                    / Take last.dot records and recode changed records back to X so
                    / they can use the standard code list for reporting.
                    /----------------------------------------------------------------*/
                    data _esi1_&&nonappcode&i(drop=changeflag&i);
                      set _esi1_&&nonappcode&i;
                      by &nonappsortby &&nonappcode&i;
                      if last.&g_subjid;
                      if &&nonappcode&i='-' and changeflag&i='1' then 
                        do;
                          &&nonappcode&i='X';
                        end;
                    run;

                 %end; *** end recode processing;
           %end; *** end i=1 to numnonapp;  
        %end; *** end if segment<n> ne missing processing;
  %end; *** end n=1 to 20;


  /*
  / Call tu_multisegments with segment parameters populated by the reordered macro segments.
  /--------------------------------------------------------------------------------------------*/
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
  /-----------------------------------------------------------*/
  %tu_tidyup(rmdset=_esi1:,
             glbmac=none);

%mend td_esi1;
