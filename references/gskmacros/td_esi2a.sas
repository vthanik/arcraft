/*----------------------------------------------------------------------------------
/ Macro Name    : td_esi2a.sas
/
/ Macro Version : 1 build 4
/
/ SAS version   : SAS v8.2
/
/ Created By    : Joe Novotny
/
/ Date          : 11OCT2006
/
/ Macro Purpose : Display macro to generate IDSL ESI2a table.  This macro creates
/                 the report using a call to tu_multisegments which performs a
/                 series of calls to the tu_freq and tu_sumstatsinrows macros. 
/                 The user can produce the default table by using the default values 
/                 of the segment1-4 parameters as described below.  If modifications/
/                 additions are required, the user must pass the required call(s) 
/                 to tu_freq/tu_sumstatsinrows via one of the segments.  If the 
/                 user does not require particular segments, then setting those
/                 segments equal to missing (e.g., segment2=, segment3=) when calling 
/                 this macro will prevent it from producing them (the macro will bump 
/                 the remaining segments up to produce the rest of the table).
/
/ Usage Notes   :     PLEASE NOTE: THE SEGMENT PARAMETERS REFERRED TO BELOW ARE NOW
/                     POINTERS TO TABLES WITHIN THE XML DEFAULTS FILE - CHANGES TO THE
/                     CALLS TO TU_FREQ AND TU_SUMSTATSINROWS MUST NOW BE MADE VIA THE
/                     XML DEFAULTS FILE, AND CANNOT BE MADE DIRECTLY BY CHANGING THE VALUE
/                     OF THE SEGMENT PARAMETER.
/ 
/                 1)  Formats passed via the aeonsetfmt and aedurfmt keyword parameters
/                     must be numeric and contain numeric ranges (e.g., 1-14, 15-28, 
/                     29-99999999, etc.). Passed values should include the period (.) 
/                     at the end of the format name (e.g., pass <onsetfmt.> NOT <onsetfmt>).  
/
/                 2)  Default segments two through four (segment2-segment4) require 
/                     additional processing of the standard A&R IDSL AE dataset prior 
/                     to being passed as input to tu_freq and tu_sumstatsinrows.  This 
/                     processing is done within this macro.  The following keywords 
/                     are expected to be found within these segments in order for the
/                     macro to recognize it needs to perform this processing:  
/                     
/                         segment           keyword
/                         --------          ------------------
/                         segment2          TD_ESI2A_ONSET
/                         segment3          TD_ESI2A_DUR
/                         segment4          TD_ESI2A_DUR
/
/                     The user is free to overwrite the default values of the segments,
/                     but keep in mind that these keywords must be found for the macro to 
/                     successfully preprocess the data prior to creating the display.
/
/                     All four segments select the first occurence of the event of interest.
/                     Additionally, the two segments containing _FREQ in their keyword also
/                     create a variable using the variable passed via keyword parameter 
/                     &aeonsetvar and the format passed via keyword parameter &aeonsetfmt.
/                     For example, using the default values for segment2 result in
/                     the variable ESI2A_ONSET being created by the code: 
/                     esi2a_onset=put(&aeonsetvar.,&aeonsetfmt..);
/
/                 3)  This macro assumes any other subsetting of the standard A&R AE 
/                     dataset takes place prior to calling this macro (e.g., selecting
/                     on-therapy events or events with positive onset times).
/
/                 4)  The riskSegs parameter should be set to a list of one or more numbers,
/                     corresponding to the segments for which numbers of subjects at risk 
/                     should be displayed. If this parameter is blank, then number of 
/                     subjects at risk will not be displayed in any of the segments.
/
/ Macro Design  : PROCEDURE STYLE
/
/---------------------------------------------------------------------------------------
/ Output:               1. Output file in plain ASCII text format containing Summary of
/                          Onset and Duration of the First Occurrence of <event>
/                       2. SAS data set in the location specified in ts_setup.
/
/ Global macro variables created: None
/
/ Macros called :
/ (@) tr_putlocals
/ (@) tu_putglobals
/ (@) tu_chknames
/ (@) tu_chkvarsexist
/ (@) tu_denorm
/ (@) tu_abort
/ (@) tu_getdata
/ (@) tu_nobs
/ (@) tu_multisegments
/ (@) tu_list
/ (@) tu_tidyup
/ (@) tu_words
/
/---------------------------------------------------------------------------------------
/ Change Log :
/
/ Modified By             : Shan Lee   
/ Date of Modification    : 05 April 2007  
/ New Version Number      : version 1, build 2
/ Modification ID         : SL001
/ Reason For Modification : Re-wrote code for calculating number of subjects at risk.
/                           Include (RTW)ARNING messages if list of preferred terms is 
/                           long and likely to cause problems.
/                           Reassign values for SEGMENT parameters, so that they now
/                           indicate the name of a table defined in the XML file,
/                           which now stores all the tu_freq/tu_sumstatsinrows parameter
/                           values for each segment, and modify the code to read in the 
/                           new XML defaults file.
/
/ Modified By             : Shan Lee   
/ Date of Modification    : 18 May 2007  
/ New Version Number      : version 1, build 3
/ Modification ID         : SL002
/ Reason For Modification : Following iteration 1 of unit testing, amended section of 
/                           code which creates decode variables for onset time and
/                           duration, so that the formats specified via the macro 
/                           parameters aeonsetfmt and aedurfmt are used, instead
/                           of referring to hard-coded names of the defaults for these
/                           formats - need to refer to &aeonsetfmt and &aedurfmt, because
/                           the user might create formats with different names.
/                      
/                           References to &acrosscolvarprefix in parameter defaults
/                           have been replaced with a direct reference to tt_result, so
/                           that a W-ARNING message re unresolved macro variable reference
/                           will not appear when the macro is called and the default values
/                           are explicitly stated in the macro invocation. 
/
/ Modified By             : Shan Lee   
/ Date of Modification    : 24 May 2007  
/ New Version Number      : version 1, build 4
/ Modification ID         : N/a - no code is being changed, only amendment is to macro header.
/ Reason For Modification : Following source code review, the list of macros called in
/                           this header is incorrect, so it needs to be corrected. As no
/                           actual code is being amended, unit testing will not be 
/                           repeated, but the change will be tested during user 
/                           acceptance testing.
/---------------------------------------------------------------------------------------*/
%macro td_esi2a(acrosscolvarprefix=tt_result, /* Text passed to the PROC TRANSPOSE PREFIX statement in tu_denorm. */
                acrossvar=&g_trtcd, /* Variable(s) that will be transposed to columns   */
                acrossvardecode=&g_trtgrp, /* The name of the decode variable(s) for ACROSSVAR */
                acrossvarlistname=acrossList, /* Macro variable name to contain the list of columns created by the transpose of the first variable in VARSTODENORM.*/
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
                ordervars=tt_grplabel tt_segorder tt_summarylevel tt_code1 , /* Order variables */
                overallsummary=Y, /* Overall summary line at top of tables */
                pagevars=, /* Break after <var> / page */
                postsubset=, /* SAS expression to be applied to data immediately prior to creation of the permanent presentation dataset */
                proptions=headline, /* PROC REPORT statement options */
                rightvars=, /* Right justify variables */
                riskSegs = 2, /* Segment(s) in which number of subjects at risk should be displayed */
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
                widths=tt_grplabel 25 tt_decode1 45 tt_result: 10, /* Column widths */
                xmldefaults=&g_refdata./tr_esi2a_defaults.xml, /* Location and name of XML defaults file for td macro*/
                yndecodefmt=$yndecod., /* Format for creating decode variables corresponding to YNVARS */
                ynorderfmt=$ynorder., /* Format for creating order variables corresponding to YNVARS */
                ynvars=, /* List of Yes/No variables that require codes and decodes */
                segment1= SUBJECTS, /* Table within XML defaults file containing parameters for call to tu_freq or tu_sumstatsinrows */
                segment2= ONSET, /* Table within XML defaults file containing parameters for call to tu_freq or tu_sumstatsinrows */
                segment3= DURATION_PERCENT, /* Table within XML defaults file containing parameters for call to tu_freq or tu_sumstatsinrows */
                segment4= DURATION_STATS, /* Table within XML defaults file containing parameters for call to tu_freq or tu_sumstatsinrows */
                segment5=, /* Table within XML defaults file containing parameters for call to tu_freq or tu_sumstatsinrows */
                segment6=, /* Table within XML defaults file containing parameters for call to tu_freq or tu_sumstatsinrows */
                segment7=, /* Table within XML defaults file containing parameters for call to tu_freq or tu_sumstatsinrows */
                segment8=, /* Table within XML defaults file containing parameters for call to tu_freq or tu_sumstatsinrows */
                segment9=, /* Table within XML defaults file containing parameters for call to tu_freq or tu_sumstatsinrows */
                segment10=, /* Table within XML defaults file containing parameters for call to tu_freq or tu_sumstatsinrows */
                segment11=, /* Table within XML defaults file containing parameters for call to tu_freq or tu_sumstatsinrows */
                segment12=, /* Table within XML defaults file containing parameters for call to tu_freq or tu_sumstatsinrows */
                segment13=, /* Table within XML defaults file containing parameters for call to tu_freq or tu_sumstatsinrows */
                segment14=, /* Table within XML defaults file containing parameters for call to tu_freq or tu_sumstatsinrows */
                segment15=, /* Table within XML defaults file containing parameters for call to tu_freq or tu_sumstatsinrows */
                segment16=, /* Table within XML defaults file containing parameters for call to tu_freq or tu_sumstatsinrows */
                segment17=, /* Table within XML defaults file containing parameters for call to tu_freq or tu_sumstatsinrows */
                segment18=, /* Table within XML defaults file containing parameters for call to tu_freq or tu_sumstatsinrows */
                segment19=, /* Table within XML defaults file containing parameters for call to tu_freq or tu_sumstatsinrows */
                segment20= /* Table within XML defaults file containing parameters for call to tu_freq or tu_sumstatsinrows */
               );

  /*
  / Write details of macro start to log
  /-------------------------------------------------------------------------*/
  %local macroversion;
  %let macroversion=1 build 4;

  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=G_TRTCD G_TRTGRP G_POPDATA G_REFDATA G_SUBSET G_CENTID G_SUBJID);

  %local s p ns j acrossListRisk resultvar gfd fmt_libs get_fmt_dir _esi2a_onsetfmtname _esi2a_durfmtname aepts renumRisks;

  /*
  / SL001
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
      %end;
    %end; /* %if %length(&&segment&p) gt 0 %then */
  %end; /* %do p = 1 %to 20 */

  /*
  / If required parameter is populated, verify that variable exists on input dataset.
  /-------------------------------------------------------------------------------------*/

  %if %length(&aeonsetvar) eq 0 %then
  %do;
    %put %str(RTE)RROR: &sysmacroname: Keyword parameter %nrstr(&aeonsetvar) must not be blank. &sysmacroname will terminate.;
    %let g_abort=1;
  %end;
  %else
  %do;
    %if %tu_chkvarsexist(&dsetin.,&aeonsetvar) ne %str( ) %then
    %do;
      %put %str(RTE)RROR: &sysmacroname: %upcase(&aeonsetvar) does not exist on input dataset %upcase(&dsetin). &sysmacroname will terminate.;
      %let g_abort=1;
    %end;
  %end;

  %if %length(&aeonsetfmt) eq 0 %then
  %do;
    %put %str(RTE)RROR: &sysmacroname: Keyword parameter %nrstr(&aeonsetfmt) has value " &aeonsetfmt. " and must not be blank. &sysmacroname will terminate.;
    %let g_abort=1;
  %end;

  %if %length(&aedurvar) eq 0 %then
  %do;
    %put %str(RTE)RROR: &sysmacroname: Keyword parameter %nrstr(&aedurvar) has must not be blank. &sysmacroname will terminate.;
    %let g_abort=1;
  %end;
  %else
  %do;
    %if %tu_chkvarsexist(&dsetin.,&aedurvar) ne %str( ) %then
    %do;
      %put %str(RTE)RROR: &sysmacroname: %upcase(&aedurvar) does not exist on input dataset %upcase(&dsetin). &sysmacroname will terminate.;
      %let g_abort=1;
    %end;
  %end;

  %if %length(&aedurfmt) eq 0 %then
  %do;
    %put %str(RTE)RROR: &sysmacroname: Keyword parameter %nrstr(&aedurfmt) has value " &aedurfmt. " and must not be blank. &sysmacroname will terminate.;
    %let g_abort=1;
  %end;

  /*
  / Place values associated w/ total from XML file into macro variables.
  /------------------------------------------------------------------------*/
  %if %sysfunc(fileexist(&xmldefaults)) eq 0 %then
  %do;
    %put %str(RTE)RROR: &sysmacroname : XML File &XMLdefaults does not exist.;
    %let g_abort = 1;
  %end;

  /*
  / If any parameter validation checks have failed, then terminate the macro
  /------------------------------------------------------------------------*/

  %tu_abort

  /* Create onsetfmt */

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

  %let _esi2a_onsetfmtname=%upcase(%scan(&aeonsetfmt,1,'.'));

  /*
  / Create working dataset from the SASHELP catalog and
  / if the format does not exist, create it.
  /--------------------------------------------------------*/

  proc append base=work.td_esi2a_onset_fmt
	      data=SASHELP.VCATALG(where=(index(upcase(objtype),'FORMAT') and
					  upcase(libname) in(&get_fmt_dir) and
					  upcase(objname) eq "&_esi2a_onsetfmtname"));
  run;

  %if %tu_nobs(work.td_esi2a_onset_fmt) eq 0 %then
  %do;
    proc format lib=WORK;
	   value &_esi2a_onsetfmtname
		 1-14   =' 1-14'
		 15-28  ='15-28'
		 29-high=' >28'
	   ;
    run;
  %end;

  /* create durfmt */

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

  %let _esi2a_durfmtname=%upcase(%scan(&aedurfmt,1,'.'));

  /*
  / Create working dataset from the SASHELP catalog and
  / if the format does not exist, create it.
  /--------------------------------------------------------*/
  proc append base=work.td_esi2a_dur_fmt
	      data=SASHELP.VCATALG(where=(index(upcase(objtype),'FORMAT') and
					  upcase(libname) in(&get_fmt_dir) and
					  upcase(objname) eq "&_esi2a_durfmtname"));
  run;

  %if %tu_nobs(work.td_esi2a_dur_fmt) eq 0 %then
  %do;
    proc format lib=WORK;
	   value &_esi2a_durfmtname
		  1-5   =' 1-5'
		  6-10  ='6-10'
		 11-high=' >10'
	   ;
    run;
  %end;

  /*
  / SL001
  /
  / If the segment parameters are not numbered sequentially, then renumber them: i.e. if
  / segment1 and segment3 are populated, but segment2 is blank, then renumber segment3 to
  / segment2.  
  / Reassign the values of the segment parameters, so that the (XML) dataset name is 
  / replaced by a list of parameters for tu_freq/tu_sumstatsinrows. 
  / Assign value to renumRisks - this will be the same as riskSegs, except that the
  / segment numbers will be renumbered as above. 
  /-------------------------------------------------------------------------------------*/
  
  libname xmldef xml "&xmldefaults" access=readonly;

  %let s = 0;
  %let renumRisks = ;

  %do p = 1 %to 20;
    %if %length(&&segment&p) gt 0 %then
    %do;

      %let s = %eval(&s + 1);

      %if &s eq 1 %then
      %do;
        proc sql noprint;
          select distinct value into: esi2atotalidcode from xmldef.&&segment&p(where=(upcase(name)='TOTALID'));
          select distinct value into: esi2atotaliddecode from xmldef.&&segment&p(where=(upcase(name)='TOTALDECODE'));
        quit;
      %end;

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

      %if %sysfunc(indexw(&riskSegs, &p)) %then %let renumRisks = &renumRisks &s;

    %end; /* %if %length(&&segment&p) gt 0 %then */
  %end; /* %do p = 1 %to 20 */

  %let ns = &s;

  /*
  / Pre-process data for the time of onset and duration sections of the table. Code
  / takes the first occurrence of the event (e.g., first.dot processing below). The
  / esi2a_onset variable is created as a text version of &aeonsetvar, formatted with
  / &aeonsetfmt. The esi2a_dur variable is created as a text version of &aedurvar,
  / formatted with &aedurfmt. Note that only nonmissing &aeonsetvar values are kept.
  / Additionally, for the duration dataset, only nonmissing &aedurvar values are kept.
  /
  / SL002 - ensure that the decode variables are created by applying the formats specifed
  / via macro parameters aeonsetfmt and aedurfmt, rather than referring directly to the
  / default values for these parameters, because the user might choose to create formats
  / with different names to the defaults.
  /------------------------------------------------------------------------------------*/

  %tu_getdata(dsetin=&dsetin,dsetout1=td_esi2a_ae,dsetout2=td_esi2a_pop);

  proc sort data=td_esi2a_ae(where=(&aeonsetvar ne .)) out=td_esi2a_aesorted;
    by &g_subjid &g_centid &g_trtcd &g_trtgrp &aeonsetvar descending &aedurvar;
  run;

  %if %tu_nobs(work.td_esi2a_ae) ne %tu_nobs(work.td_esi2a_aesorted) %then
  %do;
    %put %str(RTE)RROR: &sysmacroname: Missing values of %upcase(&aeonsetvar) exist on input dataset %upcase(&dsetin).  &sysmacroname will terminate.;
    %let g_abort=1;
    %tu_abort
  %end;

  data td_esi2a_onset td_esi2a_dur;
        attrib esi2a_onset label='Time of onset of first occurrence, days~    Subjects with event [subjects at risk]' length=$100
               &aeonsetvar label='Time of onset of first occurrence, days'
               esi2a_dur label='Duration of first occurrence, days' length=$40
               &aedurvar label='Duration of first occurrence, days';
    set td_esi2a_aesorted;
        by &g_subjid &g_centid &g_trtcd &g_trtgrp &aeonsetvar descending &aedurvar;
        if first.&g_subjid;
        esi2a_onset=put(&aeonsetvar,&aeonsetfmt);
    output td_esi2a_onset;
        if &aedurvar ne .;
        esi2a_dur=put(&aedurvar,&aedurfmt);
    output td_esi2a_dur;
  run;

  /*
  / Place list of AEPTs into &aepts macro variable for use in table label.
  /--------------------------------------------------------------------------*/
  proc sql noprint;
    select distinct trim(left(aept)) into :aepts separated by ' or '
       from td_esi2a_aesorted;
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
                    ddname= ,
                    defaultwidths=&defaultwidths,
                    denormyn=&denormyn,
                    descending=&descending,
                    display=N,
                    dsetin=&dsetin,
                    dsetout=td_esi2a_mseg_out,
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
                    xmldefaults= ,
                    yndecodefmt=&yndecodefmt,
                    ynorderfmt=&ynorderfmt,
                    ynvars=&ynvars
                   );
                  
  /*
  / SL001
  /-------------------------------------------------------------------------------------------*/  

  %if %length(&renumRisks) gt 0 %then
  %do;

    /*
    / Create a dataset containing one observation for each subject in the population who has a 
    / non-missing EXACTEDY - for each subject, the highest value of EXACTEDY will be stored in 
    / its observation.
    /-------------------------------------------------------------------------------------------*/

    proc sort data = ardata.exposure
	      (keep = &g_subjid exactedy)
	      out = td_esi2a_exposure
	      ;
      by &g_subjid exactedy;
      where exactedy ne .;
    run;

    proc sort data = td_esi2a_pop
	      (keep = &g_subjid &g_trtcd)
	      out = td_esi2a_pop
	      nodupkey
	      ;
      by &g_subjid;
    run;

    data td_esi2a_exposure;
      merge td_esi2a_pop (in = in1)
	    td_esi2a_exposure    (in = in2)
	    ;
      by &g_subjid;
      if in1 and in2;
      if last.&g_subjid;
    run;

    /*
    / Merge the previously created dataset with onset times for each subject, with the EXPOSURE
    / dataset created above; then determine the last day that each subject was at risk.
    /-------------------------------------------------------------------------------------------*/

    data td_esi2a_risk (keep = &g_trtcd &g_subjid tt_decode1 day);
      merge td_esi2a_exposure (in = in1)
	    td_esi2a_onset
	    ;
      by &g_subjid;

      length tt_decode1 $100;

      if in1;

      select;
	when (&aeonsetvar eq .) lastDay = exactedy;
	when (&aeonsetvar le exactedy) lastDay = &aeonsetvar;
	when (&aeonsetvar gt exactedy) lastDay = &aeonsetvar;
      end;

      do day = 1 to lastDay;
	tt_decode1 = put(day, &aeonsetfmt);
	output;
      end;

    run;

    proc sort data = td_esi2a_risk
	      nodupkey
	      ;
      by &g_subjid tt_decode1;
    run;

    proc summary data = td_esi2a_risk
		 chartype
		 ;
      class tt_decode1 &g_trtcd;
      var day;
      output out = td_esi2a_risk
	     (where = (_type_ in ('11' '10')))
	     n = numRisk
	     ;
    run;

    data td_esi2a_risk;
      set td_esi2a_risk;
      if _type_ eq '10' then &g_trtcd = &esi2atotalidcode;
    run;


    %tu_denorm(dsetin = td_esi2a_risk
	      ,dsetout = td_esi2a_risk
	      ,groupbyvars = tt_decode1
	      ,acrossvar = &g_trtcd
	      ,acrosscolvarprefix = &acrosscolvarprefix 
	      ,varstodenorm = numRisk
	      ,acrossvarlistname = acrossListRisk
	      )  

    proc sql;
      create table td_esi2a_mseg_out as
      select a.*
	     %do n = 1 %to %tu_words(&acrossList);
	       %if %sysfunc(indexw(&acrossListRisk, %scan(&acrossList, &n))) %then ,b.%scan(&acrossList, &n);
	       %else ,0;    
	       as %scan(&acrossList, &n)Risk
	     %end;
      from td_esi2a_mseg_out as a
	   left join td_esi2a_risk as b
      on a.tt_segorder in (&renumRisks) and
	 a.tt_decode1 eq b.tt_decode1 
      order by a.tt_segorder
      ;
    quit;

    data td_esi2a_mseg_out;
      set td_esi2a_mseg_out;
      if tt_segorder in (&renumRisks) then do;
	%do n = 1 %to %tu_words(&acrossList);
	  %let resultVar = %scan(&acrossList, &n);
	  if &resultVar.Risk ne . then &resultVar = trim(&resultVar) || ' [' || trim(left(&resultVar.Risk)) || ']';
	  else &resultVar = trim(&resultVar) || ' [0]';
	  drop &resultVar.Risk;
	%end;
      end;
    run;

  %end; /*  %if %length(&renumRisks) gt 0 %then */

  /*
  / Produce report with package macro.
  /-------------------------------------------*/
  %tu_list(columns=&columns,
           display=&display,
           dsetin=work.td_esi2a_mseg_out,
           flowvars=&flowvars,
           formats=&formats,
           getdatayn=N,
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
           proptions=&proptions,
           rightvars=&rightvars,
           sharecolvars=&sharecolvars,
           sharecolvarsindent=&sharecolvarsindent, 
           skipvars=&skipvars,
           splitchar=&splitchar,
           %do stl=1 %to 15;
              stackvar&stl=&&stackvar&stl,
           %end;
           varlabelstyle=&varlabelstyle,
           varspacing=&varspacing,
           widths=&widths);


  /*
  / Call tu_tidyup to clear temporary data set and fields.
  /---------------------------------------------------------*/
  %tu_tidyup(rmdset=td_esi2a:,
             glbmac=none);

%mend td_esi2a;
