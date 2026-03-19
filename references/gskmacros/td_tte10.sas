/*******************************************************************************
|
| Macro Name:      td_tte10
|
| Macro Version:   1 build 4
|
| SAS Version:     8.2
|                                                             
| Created By:      Bob Newman (Amadeus) 
|
| Date:            12 December 2006
|
| Macro Purpose:   To generate a TTE10 plot
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME             DESCRIPTION                                  REQ/OPT  DEFAULT
| --------------   -----------------------------------          -------  --------------
|  InputDataset     Name of data set to be plotted                   OPT      NONE
|  InputFile        Name of SAS source file to generate data set     OPT      NONE
|  InputUsage       D (use dataset), U (use file) or C (create file) REQ      D
|  OptionsFile      Name of SAS source file of graphics options      OPT      NONE
|  OptionsFileUsage C (create), U (use) or blank (neither)           OPT      [BLANK]
|  XaxisLabel       Label for X-axis                                 OPT      Time since randomization
|  YaxisLabel       Label for Y-axis                                 OPT      Estimated survival function
|  LowPlotHeader    Title for "Number of Subjects" table             REQ      Average number of subjects at 
|                                                                             risk during the interval
|  BarsOrBands      Show error bars, confidance bands, or neither    OPT      BANDS
|  Offset           Offset between error bars for each treatment     OPT      [BLANK]
|
| Global macro variables created: 
|   NONE
| 
| Macros called: 
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_cr8gheadfoots
| (@) tu_cr8proghead
| (@) tu_drawbar
| (@) tu_drawnumofsubjs
| (@) tu_getgstatements
| (@) tu_nobs
| (@) tu_order
| (@) tu_putglobals
| (@) tu_tidyup
| (@) tu_valparms
|
| Example:
| %td_tte10(InputDataset=myplot
|   , InputUsage=D
|   , LowPlotHeader=Numbers of subjects  
|  );
|
|******************************************************************************
| Change Log
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     12-Dec-06
| New version/draft number: 01.001
| Modification ID:          RCN.01.001
| Reason For Modification:  Original version
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     08-Jan-07
| New version/draft number: 01.002
| Modification ID:          RCN.01.002
| Reason For Modification:  INTERPOL=STEPJ on all symbols (not just first two! )
|                           Deleted check for duplicates.
|                           For BARSORBANDS = BANDS, use solid lines for main plot. (4.6)
|                           No longer clip legends with blank frame for BANDS. (5.6)
|
| Modified By:              Ian Barretto
| Date of Modification:     22-Feb-07
| New version/draft number: 01.003
| Modification ID:          n/a
| Reason For Modification:  Removed tu_chkdups from header info
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     23-Feb-07
| New version/draft number: 01.004
| Modification ID:          RCN.01.004
|                           For BANDS, use different line styles for main plot,
|                           with bands lines distinguished only by being thinner.   
|                           Affects symbol definitions at LM4.6,
|                           parsing of AXIS statements at LM5.3,
|                           modifications to symbols at LM5.6.width
|
|*******************************************************************************/
  
%macro td_tte10
      (
       InputDataset=                           /* type:ID Input dataset */,
       InputFile=                              /* Name of file if InputUsage=C or U */,
       InputUsage=D                            /* Style of input data D=dataset C=create template U=use template */,
       OptionsFile=                            /* Name of file if OptionsFileUsage=C or U */,
       OptionsFileUsage=                       /* Style of options file C=create U=use blank=use default settings */,
       XAxisLabel=Time since randomization     /* Horizontal axis label */,
       YAxisLabel=Estimated survival function  /* Vertical axis label */,
       LowPlotHeader=Average number of subjects at risk during the interval /* Title for lower plot */,
       BarsOrBands=BANDS                       /* Error bars, confidence bands, or neither */,
       Offset=                                 /* Offset between error bars (if used) */
      );
   
  /**---------------------------------------------------------------------*/
  /*--Normal Processing (NP1) -  Echo parameter values and global macro variables to the log */
  %local MacroVersion prefix currentDataset i macroname;
  %let macroname = &sysmacroname.;
  %let MacroVersion = 1 build 4;
  %let prefix = %substr(&sysmacroname,3); 
  %let currentDataset=&InputDataset;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_analy_disp);

  /*----------------------------------------------------------------------*/ 
  /*-- NP2 - Parameter cleanup */
  %let InputDataset=%nrbquote(&InputDataset);
  %let InputFile=%nrbquote(&InputFile);
  %let InputUsage=%upcase(&InputUsage);
  %let InputUsage=%nrbquote(&InputUsage);
  %let OptionsFile=%nrbquote(&OptionsFile);
  %let OptionsFileUsage=%upcase(&OptionsFileUsage);
  %let OptionsFileUsage=%nrbquote(&OptionsFileUsage);
  %let XaxisLabel=%nrbquote(&XaxisLabel);
  %let YaxisLabel=%nrbquote(&YaxisLabel);
  %let LowPlotHeader=%nrbquote(&LowPlotHeader);
  %let BarsOrBands=%upcase(&BarsOrBands);
  %let BarsOrBands=%nrbquote(&BarsOrBands);
  %let Offset=%nrbquote(&Offset);
  
  /*----------------------------------------------------------------------*/ 
  /*-- NP3 - Perform primary parameter validation*/
  /*-- set up a macro variable to hold the pv_abort flag*/
  %local pv_abort;
  %let pv_abort = 0;

  /*--PV0 - Delete any existing plot file */
  /* NB we do this even if this call would not create a new one */
  %let G_FONTSIZE=%upcase(&G_FONTSIZE);
  %local plotfile;

  %if %substr(&G_FONTSIZE,1,2)=PS
  %then
    %do;
      %let plotfile=&G_OUTFILE..PDF;
    %end;
  %else
    %do;
      %let plotfile=&G_OUTFILE..&G_TEXTFILESFX;
    %end;
    
  %local rc pltfref;
  %if %sysfunc(fileexist(&plotfile)) = 1
  %then
    %do;
      /* Have to assign a fileref before we can use the FDELETE function */
      %let plotfref=oldplot;
      %let rc=%sysfunc(filename(plotfref,&plotfile));
      %if &rc ne 0
      %then
        %do;
          %put %str(RTE)RROR: &macroname: Failed to assign fileref for plot file - return code &rc; 
          %let pv_abort = 1;
        %end;
      %else
        %do;
          %let rc=%sysfunc(fdelete(&plotfref));
          /* Do not understand why ampersand needed here but not for FILENAME call */
          /* - but if it aint broke, dont fix it */
          %if &rc ne 0
          %then
            %do;
              %put %str(RTE)RROR: &macroname: Failed to delete existing plot file - return code &rc;
            %let pv_abort = 1;
        %end;
        %end;
    %end;
    
  /*--PV1 - INPUT USAGE: check it is D, C or U */
  %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = InputUsage, valuelist = C D U, abortyn = N);

  /*--PV2 - INPUT DATASET: check specified when and only when needed */
  %if &InputUsage=D
  %then
    %do;
      %tu_valparms(macroname = &macroname., chktype=dsetExists, pv_dsetin = InputDataset, abortyn = N); 
    %end;
  
  %if &InputUsage=C or &InputUsage=U
  %then
    %do;
      %if %length(&InputDataset) > 0
      %then
        %do;
          %put %str(RTW)ARNING: &macroname: InputDataset specified when InputUsage does not require it;
        %end;
    %end;      

  /*--PV3 - INPUT FILE: check correctly specified when and only when needed */ 
  %if &InputUsage=D
  %then
    %do;
      %if %length(&InputFile) > 0
      %then
        %do;
          %put %str(RTW)ARNING: &macroname: InputFile specified when InputUsage does not require it; 
        %end;
    %end;
  
  %if &InputUsage=C 
  %then
    %do;
      %if %length(%sysfunc(compbl(&InputFile))) = 0
      %then
        %do;
          %put %str(RTE)RROR: &macroname: No InputFile specified; 
          %let pv_abort = 1;
        %end;
      %else
        %do;
          %if %sysfunc(fileexist(&InputFile)) = 1
          %then
            %do;
              %put %str(RTE)RROR: &macroname: InputFile to be created already exists; 
              %let pv_abort = 1;
            %end;
        %end;
    %end;      

  %if &InputUsage=U
  %then
    %do;
      %if %length(%sysfunc(compbl(&InputFile))) = 0
      %then
        %do;
          %put %str(RTE)RROR: &macroname: No InputFile specified; 
          %let pv_abort = 1;
        %end;
      %else
        %do;
          %if %sysfunc(fileexist(&InputFile)) = 0
          %then
            %do;
              %put %str(RTE)RROR: &macroname: InputFile to be used does not exist;
              %let pv_abort = 1;
            %end;
        %end;
    %end;      

   /*--PV4 - OPTIONS FILE USAGE: check it is C, U or blank */
   /* NB blank is valid */
  %if %length(%sysfunc(compbl(&OptionsfileUsage))) > 0
  %then
    %do;
      %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = OptionsFileUsage, valuelist = C U, abortyn = N);
    %end;     

   /*--PV5 - OPTIONS FILE: check correctly specified when and only when needed */ 
  %if &OptionsFileUsage=
  %then
    %do;
      %if %length(&OptionsFile) > 0
      %then
        %do;
          %put %str(RTW)ARNING: &macroname: OptionsFile specified when OptionsFileUsage does not require it; 
        %end;
    %end;
  
  %if &OptionsFileUsage=C 
  %then
    %do;
      %if %length(%sysfunc(compbl(&OptionsFile))) = 0
      %then
        %do;
          %put %str(RTE)RROR: &macroname: No OptionsFile specified; 
          %let pv_abort = 1;
        %end;
      %else
        %do;
          %if %sysfunc(fileexist(&OptionsFile)) = 1
          %then
            %do;
              %put %str(RTE)RROR: &macroname: OptionsFile to be created already exists; 
              %let pv_abort = 1;
            %end;
        %end;
    %end;      

  %if &OptionsFileUsage=U
  %then
    %do;
      %if %length(%sysfunc(compbl(&OptionsFile))) = 0
      %then
        %do;
          %put %str(RTE)RROR: &macroname: No OptionsFile specified; 
          %let pv_abort = 1;
        %end;
      %else
        %do;
          %if %sysfunc(fileexist(&OptionsFile)) = 0
          %then
            %do;
              %put %str(RTE)RROR: &macroname: OptionsFile to be used does not exist;
              %let pv_abort = 1;
            %end;
        %end;
    %end;      
   
  /*--PV6 - LOWPLOTHEADER: check it is not null */
  %if %length(%nrbquote(%sysfunc(compbl(&LowPlotHeader))))=0
  %then
    %do;
        %put %str(RTE)RROR: &macroname: LowPlotHeader cannot be blank;
        %let pv_abort = 1;
    %end;
 
  /*--PV7 - BARSORBANDS: check it is BARS or BANDS or blank */
    
  %if %length(%sysfunc(compbl(&BarsOrBands))) > 0
  %then
    %do;
      %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = BarsOrBands, valuelist = BARS BANDS, abortyn = N);
    %end;     
       
  /*--PV8 - OFFSET: check specified and numeric and not negative */
  %if %length(%sysfunc(compbl(&offset))) = 0
  %then
    %do;
      %put %str(RTN)OTE: &macroname: Offset blank - treated as zero;
      %let offset=0;
    %end;
  %else
    %do;
      %if %datatyp(&offset) ne NUMERIC
      %then
        %do;
          %put %str(RTE)RROR: &macroname: Specified offset is not numeric;
          %let pv_abort = 1;
        %end;
      %else
        %do;
          %if %sysevalf(&offset < 0)
          %then
            %do;
              %put %str(RTE)RROR: &macroname: Offset cannot be negative; 
              %let pv_abort = 1;
              /* Actually it is only tu_drawbar that would object */           
            %end;
        %end;
    %end;
      
 /*----------------------------------------------------------------------*/ 
 /*- complete parameter validation */
  %if %eval(&g_abort. + &pv_abort.) gt 0 %then %do;
    %put %str(RTE)RROR: &macroname: Macro has failed parameter validation check for reasons stated with %str(RTE)RRORs above;
    %tu_abort(option=force);
  %end;
  /*----------------------------------------------------------------------*/


  /*----------------------------------------------------------------------*/ 
  /*-- LM1 - Define local macro TTE10_Input_Dataset */
  
  /*  Processes user-supplied input dataset */
  /* (Validation and any necessary manipulation) */
  /* We create a dataset PLOT for use in the actual graphics. */

%macro tte10_input_dataset(dsname,subjlabel);

/* Lists of variable names, by data type, and all required */
%local charvars numvars mustvars byvars;
%let charvars=trtgrp;
%let numvars=trtcd esttime estimate uplimit lowlimit numsubjs subjtime; 
%let mustvars=&charvars &numvars;
/* List of variables which must be a unique n-tuple for each record */
/* Not currently doing any worthwhile check - do not think any is actually required */
%let byvars=trtcd esttime subjtime uplimit lowlimit;
%global dupvar;		* Variable to receive number of duplicates found;
  
  /*----------------------------------------------------------------------*/ 
  /*-- LM1.1 - Validation of dataset */
  
%local pv_abort; 
%let pv_abort=0;    * tu_valparms requires this to exist;

/* Check existence of datasets */
%tu_valparms(
  abortyn=Y,
  macroname=tte10_input_dataset,
  chktype=dsetExists,
  pv_dsetin=dsname
  );
/* Check presence of variables */
%tu_valparms(
  abortyn=N,
  macroname=tte10_input_dataset,
  chktype=varExists,
  pv_dsetin=dsname,
  pv_varsin=mustvars
  );
/* Check variable types */
/* We have to do this once per variable since tu_valparms gives at most one error */
%local i thisvar;
%if %length(&charvars) > 0
%then
  %do;
    %let i=1;
    %do %while (%length(%scan(&charvars,&i)) > 0);
      %let thisvar=%scan(&charvars,&i);
      %tu_valparms(
        abortyn=N,
        macroname=tte10_input_dataset,
        chktype=isChar,
        pv_dsetin=dsname,
        pv_varsin=thisvar
        );
      %let i=%eval(&i+1);
    %end;
  %end;
%if %length(&numvars) > 0
%then
  %do;
    %let i=1;
    %do %while (%length(%scan(&numvars,&i)) > 0);
      %let thisvar=%scan(&numvars,&i);
      %tu_valparms(
        abortyn=N,
        macroname=tte10_input_dataset,
        chktype=isNum,
        pv_dsetin=dsname,
        pv_varsin=thisvar
        );
      %let i=%eval(&i+1);
    %end;
  %end;

/*----------------------------------------------------------------------*/
  /*- complete dataset validation */
  %if %eval(&g_abort. + &pv_abort.) gt 0 %then %do;
    %put %str(RTE)RROR: &macroname: Macro has failed dataset validation check for reasons stated with %str(RTE)RRORs above;
    %tu_abort(option=force);
  %end;
  /*----------------------------------------------------------------------*/

  /*----------------------------------------------------------------------*/ 
  /*-- LM1.2 - Generate PLOT dataset */
  
  proc sort data=&dsname out=&prefix._sorted;
    by trtcd esttime;
  run;

  data &prefix._plot;
    set &prefix._sorted;
    by trtcd;
    * Set up ordinal values for treatments;
    retain trtord 0;
    if first.trtcd then trtord+1;
    * Set label for NUMSUBJS variable ;
    * This is required by TU_DRAWNUMOFSUBJS utility macro ;  
	label numsubjs="&subjlabel";
  run;
  
  /* Separate dataset for use with TU_DRAWNUMOFSUBJS */
  
  data &prefix._subj;
    set &prefix._plot(where=(subjtime ne . and numsubjs ne .));
  run;
  
  /* Separate datasets for use with TU_DRAWBAR */
  data &prefix._bars;
    set &prefix._plot(where=(subjtime ne . and estimate ne .));
  run;
    
  /*----------------------------------------------------------------------*/ 
  /*-- LM1.3 - Derive some useful data-dependent macro variables */

%global numtrts;	* Number of different treatments;
%global x_order;    * ORDER statement for inclusion in an AXIS statement for X-axis;
%global y_order;    * ORDER statement for inclusion in an AXIS statement for Y-axis;
%local trouble trtlist;

  proc sql noprint;
    select count(distinct trtgrp) into :numtrts from &prefix._plot;
	create table &prefix._trttab as
	  select distinct trtgrp,trtcd from &prefix._plot order by trtcd;
	select count(*) into :trouble from &prefix._trttab
	  where trtgrp like "%|%";
	select trtgrp into :trtlist separated by "|" from &prefix._trttab;
  quit;

%if &trouble > 0
%then
  %do;
    %put %str(RTW)ARNING: &macroname: "|" character found in treatment names - check legend;
  %end;

  /*----------------------------------------------------------------------*/ 
  /*-- LM1.4 Derive macro variables containing LEGEND strings */
%local legvalue i thistrt;
%let legvalue=;
%do i=1 %to &numtrts;
  /* Have one LEGVAL var per treatment - one big string might get too long*/
  %let thistrt=%scan(&trtlist,&i,|);
  /* We truncate each treatment code at 60. A few more characters are possible, but not many. */
  /*  With 70-odd, the text will not fit and you get no legend at all.*/
  /* There is a technique to get multi-line values in a legend. The users can do this */
  /* if they feel strongly about it. We will include a comment telling them how. */
  /* (Also possible for us to truncate more intelligently, but that would be a frill) */
  %if %length(&thistrt) > 60
  %then
    %do;
      %let thistrt=%substr(&thistrt,1,60);
      %put %str(RTW)ARNING: &macroname: A long treatment name has been truncated in the legend; 
    %end; 
    /* "tick=" option is unnecessary but harmless and  */
    /* helpful if users want to modify options file to use multi-line text in their legend */
  %global legval&i;	* Treatment name, in a format
                      suitable for inclusion in a LEGEND statement;
  %let legval&i=%str( )tick=&i %str(%')&thistrt.%str(%' ) ;
%end;

  /*----------------------------------------------------------------------*/ 
  /*-- LM1.5 - Derive macro variables containing axis ORDER clauses */

    %tu_order(macrovar=x_order
             ,dsetin=&prefix._plot
             ,varlist=esttime subjtime
             ,minvalue=
             ,maxvalue=
             );

   %tu_order(macrovar=y_order
             ,dsetin=&prefix._plot
             ,varlist=estimate uplimit lowlimit
             ,minvalue=
             ,maxvalue=
             );

%mend tte10_input_dataset;

  /*----------------------------------------------------------------------*/ 
  /*-- LM2 - Define local macro TTE10_Write_template */
 
   /* Provides user with a SAS code template for the required input dataset */

%macro tte10_write_template(fnam);

/* NB All quotes to be generated must be preceded by "%", whether matched or not. */

data _null_;
  file &fnam;

%tu_cr8proghead(macname=create_tte10_example_dataset, macdesign=SAS_datastep_not_a_macro);
* Second param above is not validated but cannot be more than one word, apparently;

put " ";
put "%nrstr(data work.tte10_example_dataset;)";
put "%nrstr(* Data set must include at least these 8 variables;)";
put "%nrstr(* Data set must have one record for each time interval to be displayed; )";
put "%nrstr(  attrib)";
put "%nrstr(    trtgrp   length=$120 label=%"Treatment label to appear in the legend%")";
put "%nrstr(    trtcd    length=8    label=%"Treatment code to order the legend%")";
put "%nrstr(    esttime  length=8    label=%"Timepoint from life-table analysis. To be used as X-axis.%")";
put "%nrstr(    estimate length=8    label=%"Estimated survival function. To be used as Y-axis%")";
put "%nrstr(    uplimit  length=8    label=%"Upper limit for error bars or confidence bands%")";
put "%nrstr(    lowlimit length=8    label=%"Lower limit for error bars or confidence bands%")";
put "%nrstr(    numsubjs length=8    label=%"Average number of subjects at risk%")";
put "%nrstr(    subjtime length=8    label=%"Time values below which to plot NUMSUBJ values%")"; 
put "%nrstr(  ;)"; 
put "%nrstr(run;)";

run;

%mend tte10_write_template;

  /*----------------------------------------------------------------------*/ 
  /*-- LM3 - Define local macro TTE10_Use_template */

  /* Uses an input template for the input dataset */

%macro tte10_use_template(filespec);

  %global tmp_dset;

  %include "&filespec";

  %let tmp_dset=&syslast;       * Save name of dataset just created;

%mend tte10_use_template;

  /*----------------------------------------------------------------------*/ 
  /*-- LM4 - Define local macro TTE10_Write_Options */

   /* Provides user with source code for standard graphics options  */
   /* (data dependent) */

%macro tte10_write_options(fnam);

  /*----------------------------------------------------------------------*/ 
  /*-- LM4.1 - Determine whether we are generating PS-to-PDF output */
  
%let G_FONTSIZE=%upcase(&G_FONTSIZE);
%local plot_ext;

%if &G_FONTSIZE=PDF or %substr(&G_FONTSIZE,1,2)=PS
%then
  %do;
    %let plot_ext=ps;
  %end;
%else
  %do;
    /* Here for other graphics formats eg CGM, GIF */
     %let plot_ext=&G_TEXTFILESFX;
  %end;

  /*----------------------------------------------------------------------*/ 
  /*-- LM4.2 - Generate preamble in graphics options file */
  
data _null_;
  file &fnam;

%tu_cr8proghead(macname=tte10_graphics_options, macdesign=SAS_code_not_a_macro);
* Second param above is not validated but cannot be more than one word, apparently;

put " ";
put "/" "%nrstr(* Graphics options file *)" "/" ;
put " ";
put "/" "%nrstr(* D_FONTSIZE value specified was )" "&G_FONTSIZE" "%nrstr( *)" "/" ;
put "/" "%nrstr(* Plot file extension will be )" "&plot_ext" "%nrstr( *)" "/" ; 
put " ";
%if &plot_ext=ps
%then
  %do;
put "/" "%nrstr(* Generating PDF output via PostScript. *)" "/";
put "/" "%nrstr(* device=ps600c and ftext=hwps1009 are recommended. *)" "/";
  %end;
%else
  %do;
put "/" "%nrstr(* Generating non-PostScript output. *)" "/";
put "/" "%nrstr(* Default HSIZE/VSIZE values may not be valid for this device. *)" "/";
* We cannot determine the maximum and minimum plot size easily. ;
* DSGI MAXDISP function is no help, since ts_setup has already zapped the current values ;
* Only option would be to run PROC GEVICE, read its output back in and analyse ; 
* We prefer to put the onus on the user ;
%end;
  
  /*----------------------------------------------------------------------*/ 
  /*-- LM4.3 - Generate GOPTIONS statement */
  
put "%nrstr(GOPTIONS)";
%if &G_FONTSIZE=PDF
%then
  %do;
put "%nrstr(  device  = ps600c)";
  %end;
%else
  %do;
put "%nrstr(  device  = )" "&G_FONTSIZE";
  %end;
put "%nrstr(  ftext   = hwpsl009)";
put "%nrstr(  vsize   = 6.0 in)";
put "%nrstr(  hsize   = 9.25 in)";
put "%nrstr(  horigin = 0.88 in)";
put "%nrstr(  vorigin = 1.25 in)";
put "%nrstr(  rotate  = landscape)";
put "%nrstr(  htext   = 12pt)";
put "%nrstr(  htitle  = 12pt)";
put "%nrstr(;)";
put " ";

  
   *----------------------------------------------------------------------;
   *-- LM4.4 - Generate LEGEND statement ;

%let ourfont=%sysfunc(getoption(ftext));
  
put "/" "%nrstr(* Specify the legend position *)" "/";
* Better not to specify legend MODE explicitly.; 
* Default varies sensibly according to whether POSITION is inside or ;
*  outside, and ensures that legend and rest of plot interact (or not) in the way we would wish ;
put "/" "%nrstr(* For multi-line text, specify e.g. %"tick=2 %'first line%' justify=left %'second line%'%". *)" "/";
* Across=1 removed 20060904;
put "%nrstr(legend1 position=(bottom center outside) frame cborder=gray label=none
/* NB for this plot only, we do NOT specify FONT=NONE in the VALUE clause below.
   Without FONT=NONE, we are vulnerable to problems with long text strings, which may stick out beyond the legend frame.
   (This is a SAS bug, apparently connected with the fact that we are using a hardware font.)
   But with FONT=NONE, we are liable to get SAS warning messages about font HWPSL001 not being available.
   (The hardware font we think we are using is HWPSL009, and FONT=NONE normally - i.e. in other plots - seems to result 
   in our using HWPSL009DEFAULT. Maybe HWPSL001 is the default hardware font for the PS600C device. SAS graphics option
   CHARTYPE is set to 1 throughout, whereas its default value is supposed to be 0, corresponding to the default hardware font.
   It seems likely that the phrase "default hardware font" means different things in different contexts. Why our context is
   significantly different, compared with the other plot macros, remains a mystery.)
   In short, I do not understand exactly how these messages arise, but they are related in some way to the blanking out of the
   legends for the confidence bands (which we do because we only want to see the legend for the main plot).
   One possible cure-all is to specify a SOFTWARE font here e.g. FONT=SWISS. Contrary to standards, of course.
*/
  value=%(h=11pt justify=left )" 
%do i=1 %to &numtrts; 
    "&&&legval&i" 
%end;
"%nrstr(%);)";
put " ";
  
   *----------------------------------------------------------------------;
   *-- LM4.5 - Generate AXIS statements ;
  
put "/" "%nrstr(* Set the axis details *)" "/";
put "/" "%nrstr(* WIDTH option here determines thickness of frame around plot area *)" "/";
put "%nrstr(axis1 c=black width=2)" " &y_order " "%nrstr(label=%(angle=90 
h=12pt %")"
%if %length(%sysfunc(compbl(&YAxisLabel))) > 0
%then
  %do; 
    "&YAxisLabel"
  %end; 
"%nrstr(%"%);)";
put "%nrstr(axis2 c=black width=2)" " &x_order " "%nrstr(minor=none label=%(h=12pt %")" 
%if %length(%sysfunc(compbl(&XAxisLabel))) > 0
%then
  %do; 
    "&XAxisLabel"
  %end; 
"%nrstr(%"%) value=%(h=12pt%);)";
put " ";

  *----------------------------------------------------------------------; 
  *-- LM4.6 - Generate SYMBOL statements ;
  
/* Line types originally chosen were   1,4, 9,15,23,29,30,31
   with corresponding values for bands 3,2,41,42,25,43,44,45 
   
   Present values suggested by Ian Barretto 14/12/2006 
   
   The more obviously faint line styles, such as 33, may not print properly. */
  
put "/" "%nrstr(* Set Symbols to draw steps, including vertical lines between steps (STEPJ) *)" "/";
put "/" "%nrstr(* Use of any other INTERPOL option would change the essence of the plot *)" "/";
put "/" "%nrstr(* SYMBOL51 defines the line style for confidence bands corresponding to SYMBOL1, etc. *)" "/";
put "/" "%nrstr(* For SYMBOL51 and above, WIDTH, LINE and COLOR are the only options that have any effect here, *)" "/";
put "/" "%nrstr(* and you should always specify a LINE style. *)" "/";
put "%nrstr(symbol1 color=red    width=20 line=1  interpol=stepj;)";
put "%nrstr(symbol51 color=papk width=20 line=1;)";
put "%nrstr(symbol2 color=blue   width=20 line=3  interpol=stepj;)";
put "%nrstr(symbol52 color=vlib width=20 line=3;)";
%if &numtrts > 2
%then
  %do;
    put "%nrstr(symbol3 color=green  width=20 line=4  interpol=stepj;)";
    put "%nrstr(symbol53 width=20 color=vlig line=4;)";
  %end;
%if &numtrts > 3
%then
  %do;
    put "%nrstr(symbol4 color=black  width=20 line=5  interpol=stepj;)";
    put "%nrstr(symbol54 width=20 color=gray line=5;)";
  %end;
%if &numtrts > 4
%then
  %do;
    put "%nrstr(symbol5 color=cyan   width=20 line=6 interpol=stepj;)";
    put "%nrstr(symbol55 width=20 color=vpab line=6;)";
  %end;
%if &numtrts > 5
%then
  %do;
    put "%nrstr(symbol6 color=violet width=20 line=7 interpol=stepj;)";
    put "%nrstr(symbol56 width=20 color=vpav line=7;)";
  %end;
%if &numtrts > 6
%then
  %do;
    put "%nrstr(symbol7 color=orange width=20 line=8 interpol=stepj;)";
    put "%nrstr(symbol57 width=20 color=lio line=8;;)";
  %end;
%if &numtrts > 7
%then
  %do;
    put "%nrstr(symbol8 color=steel  width=20 line=9 interpol=stepj;)";
    put "%nrstr(symbol58 width=20 color=vlipb line=9;)";
  %end;
%if &numtrts > 8
%then
  %do;
put "/" "%nrstr(* Symbols are defined automatically for only 8 treatment groups - *)" "/" ;
put "/" "%nrstr(* please define SYMBOL9 etc as required by your data *)" "/" ; 
  %end;

run;

%mend tte10_write_options;

  /*----------------------------------------------------------------------*/ 
  /*-- LM5 - Define local macro TTE10_Graphics */

  /* Generates graphics, using the specified graphics options file */


%macro tte10_graphics(filespec);

/* Do not use RESET=ALL - incompatible with ts_setup */
  GOPTIONS reset=goptions;

  /*----------------------------------------------------------------------*/ 
  /*-- LM5.0 - Define macro variables for PROC GREPLAY template */
  
   /* NB template is fixed at the moment */
   /* Extra headers and footers are liable to overlay main plot */ 
   /* With BOTY=7 and TOPY=87 as at present, */
   /* the bottom 7% of the plot area is reserved for footnotes */
   /* and the top 13% for titles. */
   /* The remaining 80% is available for the main plot. */
   /* To alter this, modify (only) the two %let statements below. */
   /* See section 5.8 */
   /* With macro vars declared here, user can override them in options file */
%local topy boty;   
%let topy=87;
%let boty=7;
%let legbot=0;
%let legtop=30;

/*
%let legbot=10;
%let legtop=20;
*/    
  /*----------------------------------------------------------------------*/ 
  /*-- LM5.1 - Read options file */
  
/* This could be a user-supplied one, or it could be */
/* one we have just written out for ourselves */

%if &OptionsFileUsage=U
%then
  %do;
    %put %str(RTN)OTE: &macroname: Starting execution of user-supplied SAS code (graphics options);
  %end;
 
%include "&filespec";

%if &OptionsFileUsage=U
%then
  %do;
    %put %str(RTN)OTE: &macroname: Finished execution of user-supplied SAS code (graphics options);
  %end;
  
  /*----------------------------------------------------------------------*/ 
  /*-- LM5.2 - Determine extension for plot file, and specify plot file name */
  
%let G_FONTSIZE=%upcase(&G_FONTSIZE);
%local plot_ext;

%if &G_FONTSIZE=PDF or %substr(&G_FONTSIZE,1,2)=PS
%then
  %do;
    %let plot_ext=ps;
  %end;
%else
  %do;
    %let plot_ext=&G_TEXTFILESFX;
  %end;

/* Specify name of plot file */
  filename psname "&G_OUTFILE..&plot_ext";
 
/* We will create a new plot file */  
  GOPTIONS gsfname=psname
           gsfmode=replace;

  /*----------------------------------------------------------------------*/ 
  /*-- LM5.3 - Retrieve SYMBOL statements and derive colour lists */
  
  %tu_getgstatements(
     dsetout=&prefix._syminfo,
     statements=SYMBOL
     );

/* Generate a macro variable COLSTR containing a colour list */
/* And another called BARCOLS containing same info, differently formatted */ 
%local colstr barcols linetype linewid linecol;

data _null_;
  set &prefix._syminfo;
  length colstr $120 barcols $512 linewid $120 linetype $120 linecol $120;
  retain colstr ' ' barcols ' ' linewid ' ' linetype ' ' linecol ' ';
  if number < 50
  then
    do;
      cvpos=index(text,"CV=");
      ourtext=substr(text,cvpos+3);
      thiscol=scan(ourtext,1);
      colstr=left(trim(colstr)) || ' ' || left(trim(thiscol));
      * Each colour really is needed twice in BARCOLS;
      barcols=left(trim(barcols)) || ' (color=' || left(trim(thiscol)) || ')'; 
      barcols=left(trim(barcols)) || ' (color=' || left(trim(thiscol)) || ')'; 
      call symput('colstr',colstr);
      call symput('barcols',barcols);
    end;
  else
    do;
      /* Get line widths, colours and styles for confidence bands */
      widpos=index(text,"WIDTH=");
      if widpos > 0
      then
        do;
          ourtext=substr(text,widpos+6);
          thiswid=scan(ourtext,1);
          linewid=left(trim(linewid)) || ' ? ' || left(trim(thiswid));
          call symput('linewid',linewid);
        end;
      linepos=index(text,"LINE=");
      if linepos > 0
      then
        do;
          ourtext=substr(text,linepos+5);
          thistype=scan(ourtext,1);
          linetype=left(trim(linetype)) || ' ? ' || left(trim(thistype));
          call symput('linetype',linetype);
        end;
      else
        do;
          linetype=left(trim(linetype)) || ' ? 1';
          call symput('linetype',linetype);
        end;
      colpos=index(text,"CV=");
      if colpos > 0
      then
        do;
          ourtext=substr(text,colpos+3);
          thiscol=scan(ourtext,1);
          linecol=left(trim(linecol)) || ' ? ' || left(trim(thiscol));
          call symput('linecol',linecol);
        end;
    end;
run;
 
  /*----------------------------------------------------------------------*/ 
  /*-- LM5.4 - Create annotate dataset to draw error bars */

 %if &BarsOrBands=BARS
 %then
   %do;
 
 %tu_drawbar(
    BARHORIZONTALYN     = N
   ,BARINTERVAL         =
   ,BARLINESIZE         = 1
   ,BARRANGE            = lowlimit uplimit
   ,BARSYMBOLLIST       = &barcols
   ,COMPAREVAR          = trtcd
   ,DSETIN              = &prefix._bars
   ,DSETOUTANNO         = &prefix._baranno
   ,HVAR                = subjtime
   ,SHIFT               = &offset
   ,SYMBOL              =
   ,VVAR                =     );

   %end;

  /*----------------------------------------------------------------------*/ 
  /*-- LM5.4 - Create annotate dataset for Number of subjects table */
  
%tu_drawnumofsubjs(
   COLORLIST        = &colstr
  ,COMPAREVAR       = trtcd
  ,COMPAREVARDECODE = trtgrp
  ,DSETIN           = &prefix._subj
  ,DSETOUTANNO      = &prefix._subjsanno
  ,FORMATS          =
  ,FRAMEOPTION      =
  ,FRAMEYN          = N
  ,HAXISDSET        = 
  ,HAXISNAME        = 
  ,HVAR             = subjtime
  ,LABELS           = 
  ,ROWSPACE         = 0.2
  ,SUBJCOUNTVAR     = numsubjs
  ,TEXTOPTION       = 
  ,VAXISYN          = N
  ,UNDERLINEYN      = N
   );
   
  /*----------------------------------------------------------------------*/ 
  /*-- LM5.5 - Concatenate all annotations */
  
data &prefix._allanno;
  set
    %if &BarsOrBands=BARS
    %then
      %do; 
        &prefix._baranno
      %end;
       
      &prefix._subjsanno;
run;

  /*----------------------------------------------------------------------*/ 
  /*-- LM5.6 - Generate the main plot */
  
/* Draw the hazard lines, and include the annotate dataset to add the bars*/

%if &BarsOrBands=BANDS
%then
  %do;
    %let thiscat=temp_cat;
    %let thisname=main;
  %end;
%else
  %do;
    %let thiscat=graph_cat;
    %let thisname=template;
  %end;  

proc gplot data=work.&prefix._plot annotate=&prefix._allanno gout=&thiscat; 
      plot estimate * esttime=trtord
    / haxis=axis2 vaxis=axis1 legend=legend1 name="&thisname";
run;
quit; 

/* Name of TEMPLATE is chosen here because for BANDS the graphics entry
   produced by GREPLAY will be called TEMPLATE whether we like it or not */ 
  
  /*----------------------------------------------------------------------*/ 
  /*-- LM5.6 - If confidence bands required, generate 2 more plots. */
  
%if &BarsOrBands=BANDS
%then
  %do;
    /* Revise SYMBOL statements, specifying new line widths */
    /* All other aspects of the symbols are unaffected */ 

    %do i=1 %to &numtrts;
      symbol&i width=%scan(&linewid,&i,?) line=%scan(&linetype,&i,?) color=%scan(&linecol,&i,?);
    %end;
    
     /* Plot upper band */
    proc gplot data=work.&prefix._plot /* annotate=&prefix._allanno */ gout=band_cat; 
      plot uplimit * esttime=trtord
      / haxis=axis2 vaxis=axis1 legend=legend1 name="upper";
    run;
    /* Plot lower band */
    proc gplot data=work.&prefix._plot /* annotate=&prefix._allanno */ gout=band_cat; 
      plot lowlimit * esttime=trtord
      / haxis=axis2 vaxis=axis1 legend=legend1 name="lower";
    run;    
    quit;

     /* Generate a blank frame */
     /* We use this to prevent the legend for the main plot from being 
        overwritten by those for the two "band" plots */
    proc gslide 
      gout=band_cat name='blank' frame cframe=white; 
    run;
    
/* We do our composition of the plots in easy stages, as we were having problems with it.
   (See note about FONT=NONE in the code to create the graphics options file).
   First overlay the two "band" plots, masking out the legends. */    
   
/* Modified 22/01/2007 not to use the BLANK frame any more.
   We allow the legends to overwrite the legend for the main plot.
   This is not a problem now that main plot uses solid lines */    
    
     proc greplay igout = band_cat gout = temp_cat tc = tempcat nofs;
      tdef overlay3

        1 / llx = 0  lly = 0    lrx = 100  lry = 0
            ulx = 0  uly = 100  urx = 100  ury = 100

        2 / llx = 0  lly = 0    lrx = 100  lry = 0
            ulx = 0  uly = 100  urx = 100  ury = 100;
  
      template overlay3;
      treplay 1:upper 2:lower;
      run;
    quit;
    
    proc catalog catalog=band_cat kill;
    run;
  
    /* Now overlay the main plot */
   
    proc greplay igout = temp_cat gout = graph_cat tc = tempcat nofs;
      tdef overlay2

        1 / llx = 0  lly = 0    lrx = 100  lry = 0
            ulx = 0  uly = 100  urx = 100  ury = 100

        2 / llx = 0  lly = 0    lrx = 100  lry = 0
            ulx = 0  uly = 100  urx = 100  ury = 100;
  
      template overlay2;
      treplay 1:template 2:main;
      run;
    quit;

/*
      treplay 1:main 2:template;
*/    
    proc catalog catalog=temp_cat kill;
  
  %end;  
    
  /*----------------------------------------------------------------------*/ 
  /*-- LM5.7 - Generate plot header and footer as GSLIDE graphics */

%local ourfont;
%let ourfont=%sysfunc(getoption(ftext));

%tu_cr8gheadfoots(gout    = graph_cat_hf,
                  kill    = y,
                  pagecat = graph_cat,
                  font    = &ourfont,
                  ptsize  = 8);

  /*----------------------------------------------------------------------*/ 
  /*-- LM5.8 - Put it all together - main plot plus GSLIDE */

  %tu_getgstatements(
     dsetout=&prefix._titinfo,
     statements=TITLE
     );
  %if %tu_nobs(&prefix._titinfo) > 6
  %then
    %do;
      %put %str(RTN)OTE: &macroname: More than 3 extra titles - plot may not fit. Adjust TOPY, BOTY; 
    %end;   

  %tu_getgstatements(
     dsetout=&prefix._footinfo,
     statements=FOOTNOTE
     );
  %if %tu_nobs(&prefix._footinfo) > 2
  %then
    %do;
      %put %str(RTN)OTE: &macroname: More than 1 extra footnote - plot may not fit. Adjust TOPY, BOTY; 
    %end;   

proc catalog cat=graph_cat_hf et=grseg;
      copy out=graph_final;
run;

proc catalog cat=graph_cat et=grseg;
      copy out=graph_final;
run;

proc greplay igout = graph_final gout = final_out tc = tempcat nofs;
  tdef newtemp

    1 / llx = 5  lly = &boty  lrx = 95  lry = &boty
        ulx = 5  uly = &topy  urx = 95  ury = &topy

    2 / llx = 5  lly = 0      lrx = 95  lry = 0
        ulx = 5  uly = 100    urx = 95  ury = 100;

  template newtemp;
  treplay 1:template 2:gslide;
run;
quit;

  /*----------------------------------------------------------------------*/ 
  /*-- LM5.9 -  Convert PostScript file to PDF using utility ps2pdf (if available) */
  /* Then delete the PostScript file */
  /* This step skipped for non PS/PDF formats */
%local pdf_ext;
%if &G_FONTSIZE=PDF  /* Already converted to upper case */
%then
  %do;
    %let pdf_ext=&G_TEXTFILESFX;    /* Honour case from ts_setup */
  %end;
%else
  %do;
    %let pdf_ext=PDF;               /* For PS*, force upper case */
  %end;  
%if &plot_ext=ps
%then
  %do;
x ps2pdf &G_OUTFILE..ps &G_OUTFILE..&pdf_ext;
x rm &G_OUTFILE..ps;
  %end;

%mend tte10_graphics;

/************************************************************************/
/* Finally the rest of the main macro TD_TTE10                           */
/************************************************************************/

  /*----------------------------------------------------------------------*/ 
  /*-- NP4 - Specify FILENAMES */
  
/* Specify filename for possible template file */

%if %length(&InputFile) > 0
%then
  %do;
    filename usr_prof "&InputFile";
  %end;

/* Set filename for possible local options file in workspace */
proc sql noprint;
  select path into :workpath
    from dictionary.members where libname="WORK";
quit;

/* LOC_OPTS used when creating an options file */
filename loc_opts "%qtrim(&workpath)/optsfile";
/* LOC_FILE used when reading our own options file back in */
%local loc_file;
%let loc_file=%qtrim(&workpath)/optsfile;

/* Set filename for possible user-specified options file */
%if %length(&OptionsFile) > 0
%then
  %do;
    filename usr_opts "&OptionsFile";
  %end;

  /*----------------------------------------------------------------------*/ 
  /*-- NP5 - Set macro vars depending on OptionsFileUsage */

%local writopts readopts;

%if &OptionsFileUsage=C
%then
  %do;
     /* User wants options file creating. */
     /* We will not read it, and will not generate any graphics */
     %let writopts=usr_opts;
	 %let readopts=;
  %end;
%else 
  %if &OptionsFileUsage=U
  %then
    %do;
	  /* User options file provided, so we need not create one */
	  %let writopts=;
	  %let readopts=&OptionsFile;
    %end;
  %else
    %do;
	  /* Blank OptionsFileUsage, so normal operation. */
      /* We create our own options file, and then use it */
      %let writopts=loc_opts;
      %let readopts=&loc_file; 
    %end;

/* Now we can actually start doing things... */

%if &InputUsage=C
%then
  %do;

  /*----------------------------------------------------------------------*/ 
  /*-- NP6 - Write template file if wanted */
  
      %put %str(RTN)OTE: &macroname: Creating template code file for input dataset; 
      %put %str(RTN)OTE: &macroname: No graph will be generated;       
      %tte10_write_template(usr_prof);
      %if %length(&OptionsFile) > 0
      %then
        %do;
          %put %str(RTN)OTE: &macroname: OptionsFile specification will be ignored;
        %end;
  %end;
%else
  %do;

  /*----------------------------------------------------------------------*/ 
  /*-- NP7 - Use user-supplied template file, if any, else user-supplied dataset */
    %if &InputUsage=U
    %then
      %do;
        %put %str(RTN)OTE: &macroname: Starting execution of user-supplied SAS code (dataset creation);
        %tte10_use_template(&InputFile); 
        %put %str(RTN)OTE: &macroname: Finished execution of user-supplied SAS code (dataset creation);
        /* Dataset name returned in macrovar tmp_dset */ 
        %tte10_input_dataset(&tmp_dset,&LowPlotHeader);
      %end;
    %else 
      %do;
        %tte10_input_dataset(&InputDataset,&LowPlotHeader); 
      %end;

  /*----------------------------------------------------------------------*/ 
  /*-- NP8 - Write options file if we need to */
    %if %length(&writopts) > 0
    %then
      %do;
        /* We also come here to write our own temporary options file which we will read back in */
        %if &OptionsFileUsage = C
        %then
          %do;
            %put %str(RTN)OTE: &macroname: Creating graphics options file; 
            %put %str(RTN)OTE: &macroname: No graph will be generated;
          %end;       
        %tte10_write_options(&writopts);
      %end;

  /*----------------------------------------------------------------------*/ 
  /*-- NP9 - Read options file and generate graphics if we need to */
    %if %length(&readopts) > 0 
    %then
      %do;
        %tte10_graphics(&readopts);          
      %end;
%end;

  /*----------------------------------------------------------------------*/
  /*--NP10 - Tidy up and call tu_abort   */
  
  %tu_tidyup(rmdset=&prefix:, glbmac=NONE);
  %tu_abort;

%mend td_tte10;
