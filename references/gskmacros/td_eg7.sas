/*******************************************************************************
|
| Macro Name:      td_eg7
|
| Macro Version:   1 build 4
|
| SAS Version:     8.2
|                                                             
| Created By:      Bob Newman (Amadeus) 
|
| Date:            02 October 2006
|
| Macro Purpose:   To generate an EG7 plot
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME             DESCRIPTION                                  REQ/OPT  DEFAULT
| --------------   -----------------------------------          -------  --------------
|  InputDataset     Name of data set to be plotted                   OPT      NONE
|  XaxisLabel       Label for X-axis                                 REQ      NONE
|  YaxisLabel       Label for Y-axis                                 OPT      Cumulative percent
|  InputFile        Name of SAS source file to generate data set     OPT      NONE
|  InputUsage       D (use dataset), U (use file) or C (create file) REQ      D
|  OptionsFile      Name of SAS source file of graphics options      OPT      NONE
|  OptionsFileUsage C (create), U (use) or blank (neither)           OPT      [BLANK]
|  HRefLines        Values for horizontal reference lines            OPT      0 10 20 30 40 50 60 70 80 90 100 
|  VRefLines        Values for vertical reference lines              OPT      NONE 
|  LogBase          Log base for x-axis - 2, 10 or 0 (=linear)       OPT      [BLANK]
|  Interpolation    Interpolation method - STEPLJ or SPLINE          REQ      STEPLJ 
|
| Global macro variables created: 
|   NONE
| 
| Macros called: 
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_chkdups
| (@) tu_cr8gheadfoots
| (@) tu_cr8proghead
| (@) tu_getgstatements
| (@) tu_nobs
| (@) tu_order
| (@) tu_orderlog
| (@) tu_putglobals
| (@) tu_tidyup
| (@) tu_valparms
|
| Example:
| %td_eg7(InputDataset=myplot
|   , InputUsage=D
|   , XAxisLabel=Change in QTc msec  
|  );
|
|******************************************************************************
| Change Log
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     02-Oct-06
| New version/draft number: 01.001
| Modification ID:          RCN.01.001
| Reason For Modification:  Original version
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     02-Oct-06
| New version/draft number: 01.002
| Modification ID:          RCN.01.002
| Reason For Modification:  Apply LOGBASE parameter to X-axis (rather than Y-axis).
|                           Replace REFSTYLE parameter by HREFSTYLE and VREFSTYLE
|                           (since horizontal lines are meant to be fainter).
|
| Modified By:              Ian Barretto
| Date of Modification:     10-Jan-07
| New version/draft number: 01.003
| Modification ID:          n/a
| Reason For Modification:  Add tu_getgstatements to Macros Called list
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     19-Feb-07
| New version/draft number: 01.004
| Modification ID:          n/a
| Reason For Modification:  Ignore data with missing TRTCD (at LM1.2).
|
*******************************************************************************/
  
%macro td_eg7
      (
       InputDataset=                               /* type:ID Input dataset */,
       XAxisLabel=                                 /* Horizontal axis label */,
       YAxisLabel=Cumulative percent               /* Vertical axis label */,
       InputFile=                                  /* Name of file if InputUsage=C or U */,
       InputUsage=D                                /* Style of input data D=dataset C=create template U=use template */,
       OptionsFile=                                /* Name of file if OptionsFileUsage=C or U */,
       OptionsFileUsage=                           /* Style of options file C=create U=use blank=use default settings */,
       HRefLines=0 10 20 30 40 50 60 70 80 90 100  /* Position of horizontal reference lines (data values) */,
       VRefLines=                                  /* Position of vertical reference lines (data values) */,     
       LogBase=                                    /* Log base for x-axis (2 or 10, or 0 for a linear axis) */,
       Interpolation=STEPLJ                        /* Interpolation method (STEPLJ or SPLINE) */
      );
      
  /**---------------------------------------------------------------------*/
  /*--Normal Processing (NP1) -  Echo parameter values and global macro variables to the log */
  %local MacroVersion prefix currentDataset i macroname;
  %let macroname = &sysmacroname.;
  %let MacroVersion = 1 build 3;
  %let prefix = %substr(&sysmacroname,3); 
  %let currentDataset=&InputDataset;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_analy_disp);

  /*----------------------------------------------------------------------*/ 
  /*-- NP2 - Parameter cleanup */
  %let InputDataset=%nrbquote(&InputDataset);
  %let XaxisLabel=%nrbquote(&XaxisLabel);
  %let YaxisLabel=%nrbquote(&YaxisLabel);
  %let InputFile=%nrbquote(&InputFile);
  %let InputUsage=%upcase(&InputUsage);
  %let InputUsage=%nrbquote(&InputUsage);
  %let OptionsFile=%nrbquote(&OptionsFile);
  %let OptionsFileUsage=%upcase(&OptionsFileUsage);
  %let OptionsFileUsage=%nrbquote(&OptionsFileUsage);
  %let HRefLines=%nrbquote(&HRefLines);
  %let VRefLines=%nrbquote(&VRefLines);
  %let LogBase=%nrbquote(&LogBase);
  %let Interpolation=%upcase(&interpolation);
  %let Interpolation=%nrbquote(&interpolation);
  
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
    
  /*--PV6 - HREFLINES: check any values specified are numeric and not in scientific notation */
  %local i thisval;
  %if %length(%nrbquote(%sysfunc(compbl(&HRefLines)))) > 0
  %then
    %do;
      %let i=1;
      %do %while (%length(%qscan(&HRefLines,&i,%str( ))) > 0);
      /* Space is the only delimiter we recognise here */
        %let thisval=%qscan(&HRefLines,&i,%str( ));
        %if %datatyp(&thisval) ne NUMERIC
        %then
          %do;
            %put %str(RTE)RROR: &macroname: HRefLines value &thisval is not numeric; 
            %let pv_abort = 1;          
          %end;
        %else
          %do;
            %if %sysfunc(indexc(&thisval,DEde)) > 0
            %then
              %do;
                %put %str(RTE)RROR: &macroname: HRefLines values cannot use scientific notation;
                /* %datatyp will be happy but PROC GPLOT would not be */ 
                %let pv_abort = 1;          
              %end;
          %end;
        %let i=%eval(&i+1);
      %end;
    %end;      
    
  /*--PV7 - VREFLINES: check any values specified are numeric and not in scientific notation */
  %if %length(%sysfunc(compbl(&VRefLines))) > 0
  %then
    %do;
      %let i=1;
      %do %while (%length(%qscan(&VRefLines,&i,%str( ))) > 0);
      /* Space is the only delimiter we recognise here */
        %let thisval=%qscan(&VRefLines,&i,%str( ));
        %if %datatyp(&thisval) ne NUMERIC
        %then
          %do;
            %put %str(RTE)RROR: &macroname: VRefLines value &thisval is not numeric; 
            %let pv_abort = 1;          
          %end;
        %else
          %do;
            %if %sysfunc(indexc(&thisval,DEde)) > 0
            %then
              %do;
                %put %str(RTE)RROR: &macroname: VRefLines values cannot use scientific notation;
                /* %datatyp will be happy but PROC GPLOT would not be */ 
                %let pv_abort = 1;          
              %end;
          %end;
        %let i=%eval(&i+1);
      %end;
    %end;
          
  /*--PV8 - XAXISLABEL - check not blank */  
  %if %length(%nrbquote(%sysfunc(compbl(&XAxisLabel)))) = 0
  %then
    %do;
      %put %str(RTE)RROR: &macroname: XAxisLabel cannot be blank;
      %let pv_abort = 1;               
    %end;
   
  /*--PV9 - LOGBASE: check it is 0 or 2 or 10 */
   %if %length(%nrbquote(%sysfunc(compbl(&logbase )))) = 0
   %then
     %do;
       %let logbase=0;
       %put %str(RTN)OTE: &macroname: LogBase not specified - setting to 0 and using linear x-axis;
     %end;
   %else
     %do;
       %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = LogBase, valuelist = 0 2 10, abortyn = N);
     %end;
   
  /*--PV10 - INTERPOLATION: check it STEPLJ or SPLINE */
   %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = Interpolation, valuelist = STEPLJ SPLINE, abortyn = N);
   
/*----------------------------------------------------------------------*/
  /*- complete parameter validation */
  %if %eval(&g_abort. + &pv_abort.) gt 0 %then %do;
    %put %str(RTE)RROR: &macroname: Macro has failed parameter validation check for reasons stated with %str(RTE)RRORs above;
    %tu_abort(option=force);
  %end;
  /*----------------------------------------------------------------------*/

  /*----------------------------------------------------------------------*/ 
  /*-- LM1 - Define local macro EG7_Input_Dataset */
  
  /*  Processes user-supplied input dataset */
  /* (Validation and any necessary manipulation) */
  /* We create a dataset PLOT for use in the actual graphics. */

%macro eg7_input_dataset(dsname);

/* Lists of variable names, by data type, and all required */
%local charvars numvars mustvars byvars;
%let charvars=trtgrp;
%let numvars=trtcd xvar yvar; 
%let mustvars=&charvars &numvars;
/* List of variables which must be a unique n-tuple for each record */
%let byvars=trtcd xvar;
%global dupvar;         * Variable to receive number of duplicates found;
  
  /*----------------------------------------------------------------------*/ 
  /*-- LM1.1 - Validation of dataset */
  
%local pv_abort; 
%let pv_abort=0;

/* Check existence of datasets */
%tu_valparms(
  abortyn=Y,
  macroname=eg7_input_dataset,
  chktype=dsetExists,
  pv_dsetin=dsname
  );
/* Check presence of variables */
%tu_valparms(
  abortyn=N,
  macroname=eg7_input_dataset,
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
        macroname=eg7_input_dataset,
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
        macroname=eg7_input_dataset,
        chktype=isNum,
        pv_dsetin=dsname,
        pv_varsin=thisvar
        );
      %let i=%eval(&i+1);
    %end;
  %end;
/* Check no duplicate rows */
%tu_chkdups(
  dsetin = &dsname,
  byvars = &byvars,
  retvar = dupvar,
  dsetout = work.dups
);
%if &dupvar > 0
%then
  %do;
    %put %str(RTE)RROR: &macroname: Dataset has multiple rows for same &byvars combination; 
    %let pv_abort = 1;    
  %end;

/* Check that YVAR values increase monotonically for each treatment? - No, not reqd */
/* Check that range is 0 to 1 (or 0 to 100?) for each treatment? - No, not reqd */

/*----------------------------------------------------------------------*/
  /*- complete dataset validation */
  %if %eval(&g_abort. + &pv_abort.) gt 0 %then %do;
    %put %str(RTE)RROR: &macroname: Macro has failed dataset validation check for reasons stated with %str(RTE)RRORs above;
    %tu_abort(option=force);
  %end;
  /*----------------------------------------------------------------------*/

  /*----------------------------------------------------------------------*/ 
  /*-- LM1.2 - Generate PLOT dataset */
  
  %local nullct;
  proc sql noprint;
    select count(*) into :nullct from &dsname(where=(trtcd=.));
  quit;
  %if &nullct > 0
  %then
    %do;
      %put %str(RTW)ARNING: &macroname: Data with TRTCD value missing will be ignored;
    %end;
  
  proc sort data=&dsname(where=(trtcd ne .)) out=&prefix._sorted;
    by trtcd xvar;
  run;
  
  data &prefix._plot;
    set &prefix._sorted;
    by trtcd;    
    *No processing needed here at present;
  run;
 
  /*----------------------------------------------------------------------*/ 
  /*-- LM1.3 - Derive some useful data-dependent macro variables */

%global numtrts;        * Number of different treatments;
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
  %global legval&i;     * Treatment name, in a format
                      suitable for inclusion in a LEGEND statement;
  %let legval&i=%str( )tick=&i %str(%')&thistrt.%str(%' ) ;
%end;

  /*----------------------------------------------------------------------*/ 
  /*-- LM1.5 - Derive macro variables containing axis ORDER clauses */

%if &logbase=0 
%then
  %do;
    %tu_order(macrovar=x_order
             ,dsetin=&prefix._plot
             ,varlist=xvar
             );
   %end;
%else
  %do;
    %tu_orderlog(macrovar=x_order
                ,dsetin=&prefix._plot
                ,varlist=xvar
                ,logbase=&logbase
                );
   %end;

/* Y-axis always expected to be percentage (but we work it out anyway) */
%tu_order(macrovar=y_order
         ,dsetin=&prefix._plot
         ,varlist=yvar
         );
 
%mend eg7_input_dataset;

  /*----------------------------------------------------------------------*/ 
  /*-- LM2 - Define local macro EG7_Write_template */
 
   /* Provides user with a SAS code template for the required input dataset */

%macro eg7_write_template(fnam);

/* NB All quotes to be generated must be preceded by "%", whether matched or not. */

data _null_;
  file &fnam;

%tu_cr8proghead(macname=create_eg7_example_dataset, macdesign=SAS_datastep_not_a_macro);
* Second param above is not validated but cannot be more than one word, apparently;

put " ";
put "%nrstr(data work.eg7_example_dataset;)";
put "%nrstr(* Data set must include at least these 4 variables;)";
put "%nrstr(* Data set may need to specify other conditions; )";
put "%nrstr(  attrib)";
put "%nrstr(    trtgrp   length=$120 label=%"Treatment label to appear in the legend%")";
put "%nrstr(    trtcd    length=8    label=%"Treatment code to order the legend%")";
put "%nrstr(    xvar     length=8    label=%"Variable to be plotted against X-axis.%")";
put "%nrstr(    yvar     length=8    label=%"Variable to be plotted against Y-axis.%")";
put "%nrstr(  ;)"; 
put "%nrstr(run;)";

run;

%mend eg7_write_template;

  /*----------------------------------------------------------------------*/ 
  /*-- LM3 - Define local macro AE12_Use_template */

  /* Uses an input template for the input dataset */

%macro eg7_use_template(filespec);

  %global tmp_dset;

  %include "&filespec";

  %let tmp_dset=&syslast;       * Save name of dataset just created;

%mend eg7_use_template;

  /*----------------------------------------------------------------------*/ 
  /*-- LM4 - Define local macro AE12_Write_Options */

   /* Provides user with source code for standard graphics options  */
   /* (data dependent) */

%macro eg7_write_options(fnam);

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

%tu_cr8proghead(macname=eg7_graphics_options, macdesign=SAS_code_not_a_macro);
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
/* We cannot determine the maximum and minimum plot size easily. */
/* DSGI MAXDISP function is no help, since ts_setup has already zapped the current values */
/* Only option would be to run PROC GDEVICE, read its output back in and analyse */ 
/* We prefer to put the onus on the user */
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

  /*----------------------------------------------------------------------*/ 
  /*-- LM4.4 - Generate LEGEND statement */
  
put "/" "%nrstr(* Specify the legend position *)" "/";
* Better not to specify legend MODE explicitly.; 
* Default varies sensibly according to whether POSITION is inside or ;
*  outside, and ensures that legend and rest of plot interact (or not) in the way we would wish ;
put "/" "%nrstr(* %"font=none%" is important here. Without it, the frame may not be big enough to contain the legend. *)" "/";
put "/" "%nrstr(* When using ftext=hwpsl009, %"none%" overrides with hwpsl009default *)" "/";
put "/" "%nrstr(* For multi-line text, specify e.g. %"tick=2 %'first line%' justify=left %'second line%'%". *)" "/";
put "%nrstr(legend1 position=(bottom center outside) frame cborder=gray label=none 
     value=%(font=none h=11pt justify=left )" 
%do i=1 %to &numtrts; 
    "&&&legval&i" 
%end;
"%nrstr(%);)";
put " ";

  /*----------------------------------------------------------------------*/ 
  /*-- LM4.5 - Generate AXIS statements */
  
put "/" "%nrstr(* Set the axis details *)" "/";
put "/" "%nrstr(* WIDTH option here determines thickness of frame around plot area *)" "/";
put "%nrstr(axis1 c=black width=2)" " &y_order " "%nrstr(label=%(angle=90 h=12pt %")"
%if %length(%nrbquote(%sysfunc(compbl(&YAxisLabel)))) > 0
%then
  %do; 
    "&YAxisLabel"
  %end; 
"%nrstr(%"%);)";
put "%nrstr(axis2 c=black width=2)" " &x_order " "%nrstr(minor=none label=%(h=12pt %")" 
%if %length(%nrbquote(%sysfunc(compbl(&XAxisLabel)))) > 0
%then
  %do; 
    "&XAxisLabel"
  %end; 
"%nrstr(%"%) value=%(h=12pt%);)";
put " ";

  /*----------------------------------------------------------------------*/ 
  /*-- LM4.6 - Generate SYMBOL statements */
  
put "/" "%nrstr(* Set Symbols. *)" "/";
put "/" "%nrstr(* INTERPOL option will normally be STEPLJ or SPLINE *)" "/";
put "%nrstr(symbol1 color=red    width=2 line=3  interpol=)" "&Interpolation" "%nrstr(;)";
put "%nrstr(symbol2 color=blue   width=2 line=1  interpol=)" "&Interpolation" "%nrstr(;)";
%if &numtrts > 2
%then
  %do;
put "%nrstr(symbol3 color=green  width=2 line=2  interpol=)" "&Interpolation" "%nrstr(;)";
  %end;
%if &numtrts > 3
%then
  %do;
put "%nrstr(symbol4 color=black  width=2 line=8  interpol=)" "&Interpolation" "%nrstr(;)";
  %end;
%if &numtrts > 4
%then
  %do;
put "%nrstr(symbol5 color=cyan   width=2 line=33 interpol=)" "&Interpolation" "%nrstr(;)";
  %end;
%if &numtrts > 5
%then
  %do;
put "%nrstr(symbol6 color=violet width=2 line=30 interpol=)" "&Interpolation" "%nrstr(;)";
  %end;
%if &numtrts > 6
%then
  %do;
put "%nrstr(symbol7 color=orange width=2 line=43 interpol=)" "&Interpolation" "%nrstr(;)";
  %end;
%if &numtrts > 7
%then
  %do;
put "%nrstr(symbol8 color=steel  width=2 line=14 interpol=)" "&Interpolation" "%nrstr(;)";
  %end;
%if &numtrts > 8
%then
  %do;
put "/" "%nrstr(* Only 8 symbols are defined automatically - *)" "/" ;
put "/" "%nrstr(* please define SYMBOL9 etc as required by your data *)" "/" ; 
  %end;

run;

%mend eg7_write_options;

  /*----------------------------------------------------------------------*/ 
  /*-- LM5 - Define local macro AE12_Graphics */

  /* Generates graphics, using the specified graphics options file */


%macro eg7_graphics(filespec);

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
    
   /* Macro variables for reference lines */
%local refcolor refstyle;
%let refcolor=green;
%let vrefstyle=1;
%let hrefstyle=20;         
            
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
  /*-- LM5.3 - Generate options string for reference lines */

  /* Beware possible confusion here! */
  /* This macros parameter HRefLines refers to reference lines that run horizontally */
  /* But GPLOT options HREF, CHREF, LHREF relate to lines PERPENDICULAR TO horizontal axis */
  /* Similarly with "vertical" parameter and options */
  %local reflines;
  %let reflines=;
  %if %length(%nrbquote(%sysfunc(compbl(&HRefLines)))) > 0
  %then
    %do;
      %let reflines=&reflines cvref=&refcolor lvref=&hrefstyle vref=&HRefLines ;
      /* Oddly, some line styles do not come out as advertised. 34 is recommended here */ 
    %end;
  %if %length(%nrbquote(%sysfunc(compbl(&VRefLines)))) > 0
  %then
    %do;
      %let reflines=&reflines chref=&refcolor lhref=&vrefstyle href=&VRefLines ; 
    %end;

  /*----------------------------------------------------------------------*/ 
  /*-- LM5.4 - Generate the main plot */
  
/* Draw the hazard lines, and include the annotate dataset to add the bars*/

proc gplot data=work.&prefix._plot gout=graph_cat;
     plot yvar * xvar=trtcd
    / haxis=axis2 vaxis=axis1 legend=legend1 name="hazard" &reflines;
run;
quit;

  /*----------------------------------------------------------------------*/ 
  /*-- LM5.5 - Generate plot header and footer as GSLIDE graphics */
  
%local ourfont;
%let ourfont=%sysfunc(getoption(ftext));

%tu_cr8gheadfoots(gout    = graph_cat_hf,
                  kill    = y,
                  pagecat = graph_cat,
                  font    = &ourfont,
                  ptsize  = 8);

  /*----------------------------------------------------------------------*/ 
  /*-- LM5.6 - Put it all together - main plot plus GSLIDE */

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

   /* NB template is fixed at the moment */
   /* Extra headers and footers are liable to overlay main plot */ 
    
proc greplay igout = graph_final gout = final_out tc = tempcat nofs;
  tdef newtemp

    1 / llx = 5  lly = &boty  lrx = 95  lry = &boty
        ulx = 5  uly = &topy  urx = 95  ury = &topy

    2 / llx = 5  lly = 0      lrx = 95  lry = 0
        ulx = 5  uly = 100    urx = 95  ury = 100;

  template newtemp;
    treplay 1:hazard 2:gslide;
run;
quit;

  /*----------------------------------------------------------------------*/ 
  /*-- LM5.7 -  Convert PostScript file to PDF using utility ps2pdf (if available) */
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

%mend eg7_graphics;

/************************************************************************/
/* Finally the rest of the main macro TD_AE12                           */
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
      /* We create our own options file, and then use it; */
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
      %eg7_write_template(usr_prof);
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
        %eg7_use_template(&InputFile); 
        %put %str(RTN)OTE: &macroname: Finished execution of user-supplied SAS code (dataset creation);
        * Dataset name returned in macrovar tmp_dset; 
        %eg7_input_dataset(&tmp_dset);
      %end;
    %else 
      %do;
        %eg7_input_dataset(&InputDataset);
      %end;

  /*----------------------------------------------------------------------*/ 
  /*-- NP8 - Write options file if we need to */
    %if %length(&writopts) > 0
    %then
      %do;
        * We also come here to write our own temporary options file which we will read back in;
        %if &OptionsFileUsage = C
        %then
          %do;
            %put %str(RTN)OTE: &macroname: Creating graphics options file; 
            %put %str(RTN)OTE: &macroname: No graph will be generated;
          %end;       
        %eg7_write_options(&writopts);
      %end;

  /*----------------------------------------------------------------------*/ 
  /*-- NP9 - Read options file and generate graphics if we need to */
    %if %length(&readopts) > 0 
    %then
      %do;
        %eg7_graphics(&readopts);
      %end;
%end;

  /*----------------------------------------------------------------------*/
  /*--NP10 - Tidy up and call tu_abort   */
  
  %tu_tidyup(rmdset=&prefix:, glbmac=NONE);
  %tu_abort;

%mend td_eg7;
