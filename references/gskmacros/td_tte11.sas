/*******************************************************************************
|
| Macro Name:      td_tte11
|
| Macro Version:   1 build 4
|
| SAS Version:     8.2
|                                                             
| Created By:      Bob Newman (Amadeus) 
|
| Date:            26 October 2006
|
| Macro Purpose:   To generate a TTE11 plot
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
|  XaxisLabel       Label for X-axis                                 OPT      Hazard Ratio
|  XaxisLabelLeft   Label for LHS of X-axis                          OPT      [BLANK]
|  XaxisLabelRight  Label for RHS of X-axis                          OPT      [BLANK]
|  VRefLines        Vertical Reference Lines                         OPT      [BLANK]
|  ShowStatistic    Display actual data values on plot (Y/N)         REQ      Y 
|  ShowBarEnd       Mark ends of range bars (Y/N)                    REQ      Y
|  LogBase          Base for logarithmic x-axis (blank or 0 = linear)OPT      [BLANK]
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
| %td_tte11(InputDataset=myplot
|   , InputUsage=D
|  );
|
|******************************************************************************
| Change Log
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     26-Oct-06
| New version/draft number: 01.001
| Modification ID:          RCN.01.001
| Reason For Modification:  Original version
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     22-Nov-06
| New version/draft number: 01.002
| Modification ID:          RCN.01.002
| Reason For Modification:  Change default logbase to blank.
|                           Use ' | ' rather than '|' as separator at LM1.2, so that 
|                           blank labels are displayed as such. This also needed changes
|                           to the code at LM4.4.
|                           Use YNUM rather than YORDER at LM1.2, LM5.4, LM5.5.
|                           Alter handling of missing values at LM1.2 and LM5.8.
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     28-Nov-06
| New version/draft number: 01.003
| Modification ID:          RCN.01.003
| Reason For Modification:  Exclude observations with YORDER=. at LM1.2.
|                           A leftover PROC PRINT removed.
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     05-Dec-06
| New version/draft number: 01.004
| Modification ID:          RCN.01.004
| Reason For Modification:  Exclude observations with YORDER=. from validation.
|
| Modified By:              Ian Barretto
| Date of Modification:     06-Dec-06
| New version/draft number: 01.005
| Modification ID:          01.005
| Reason For Modification:  Remove OFFSET from header and add VREFLINES.
|
*******************************************************************************/
  
%macro td_tte11
      (
       InputDataset=                           /* type:ID Input dataset */,
       InputFile=                              /* Name of file if InputUsage=C or U */,
       InputUsage=D                            /* Style of input data D=dataset C=create template U=use template */,
       OptionsFile=                            /* Name of file if OptionsFileUsage=C or U */,
       OptionsFileUsage=                       /* Style of options file C=create U=use blank=use default settings */,
       XAxisLabel=Hazard Ratio                 /* Horizontal axis label */,
       XAxisLabelLeft=                         /* Label for LHS of horizontal axis */,
       XAxisLabelRight=                        /* Label for RHS of horizontal axis */,
       ShowStatistic=Y                         /* Display data values on plot (Y/N) */,
       ShowBarEnd=Y                            /* Mark ends of range bars (Y/N) */,
       VRefLines=                              /* Position of vertical reference line(s) */,
       LogBase=                                /* Base of logarithms for x-axis (2 or 10; 0 for linear axis) */ );

  /**---------------------------------------------------------------------*/
  /*--Normal Processing (NP1) -  Echo parameter values and global macro variables to the log */
  %local MacroVersion prefix currentDataset i macroname;
  %let macroname = &sysmacroname.;
  %let MacroVersion = 1 build 5;
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
  %let XaxisLabelLeft=%nrbquote(&XaxisLabelLeft);
  %let XaxisLabelRight=%nrbquote(&XaxisLabelRight);
  %let ShowStatistic=%upcase(&ShowStatistic);
  %let ShowStatistic=%nrbquote(&ShowStatistic);
  %let ShowBarEnd=%upcase(&ShowBarEnd);
  %let ShowBarEnd=%nrbquote(&ShowBarEnd);
  %let VRefLines=%nrbquote(&VRefLines);
  %let LogBase=%nrbquote(&Logbase);
  
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
   
  /*--PV6 - VREFLINES: check any values specified are numeric and not in scientific notation */ 
 
  %local i thisval;
  %if %length(%nrbquote(%sysfunc(compbl(&VRefLines)))) > 0
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
 
   /*--PV7 - SHOWSTATISTIC: check it is Y or N */
  %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = ShowStatistic, valuelist = Y N, abortyn = N);

   /*--PV8 - SHOWBAREND: check it is Y or N */
  %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = ShowBarEnd, valuelist = Y N, abortyn = N);
  
    /*--PV9 - LOGBASE: check it is 0 or 2 or 10 */
   %if %length(%nrbquote(%sysfunc(compbl(&logbase)))) = 0
   %then
     %do;
       %let logbase=0;
       %put %str(RTN)OTE: &macroname: LogBase not specified - setting to 0 and using linear x-axis;
     %end;
   %else
     %do;
       %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = LogBase, valuelist = 0 2 10, abortyn = N);
     %end;
   
/*----------------------------------------------------------------------*/ 
 /*- complete parameter validation */
  %if %eval(&g_abort. + &pv_abort.) gt 0 %then %do;
    %put %str(RTE)RROR: &macroname: Macro has failed parameter validation check for reasons stated with %str(RTE)RRORs above;
    %tu_abort(option=force);
  %end;
  /*----------------------------------------------------------------------*/

  /*----------------------------------------------------------------------*/ 
  /*-- LM1 - Define local macro TTE11_Input_Dataset */
  
  /*  Processes user-supplied input dataset */
  /* (Validation and any necessary manipulation) */
  /* We create a dataset PLOT for use in the actual graphics. */

%macro tte11_input_dataset(dsname);

/* Lists of variable names, by data type, and all required */
%local charvars numvars mustvars byvars;
%let charvars=tick1l tick1r tick2l tick2r;
%let numvars=yorder xvar lowlimit uplimit; 
%let mustvars=&charvars &numvars;
/* List of variables which must be a unique n-tuple for each record */
%let byvars=yorder;
%global dupvar;		* Variable to receive number of duplicates found;
  
  /*----------------------------------------------------------------------*/ 
  /*-- LM1.1 - Validation of dataset */
  
%local pv_abort; 
%let pv_abort=0;    * tu_valparms requires this to exist;

/* Check existence of datasets */
%tu_valparms(
  abortyn=Y,
  macroname=tte11_input_dataset,
  chktype=dsetExists,
  pv_dsetin=dsname
  );
/* Check presence of variables */
%tu_valparms(
  abortyn=N,
  macroname=tte11_input_dataset,
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
        macroname=tte11_input_dataset,
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
        macroname=tte11_input_dataset,
        chktype=isNum,
        pv_dsetin=dsname,
        pv_varsin=thisvar
        );
      %let i=%eval(&i+1);
    %end;
  %end;
/* For remainder of processing we ignore all records with yorder=. */  
  proc sort data=&dsname(where=(yorder ne .)) out=&prefix._rawsort; 
    by yorder;
  run;
/* Check no duplicate rows */
%tu_chkdups(
  dsetin = &prefix._rawsort,
  byvars = &byvars,
  retvar = dupvar,
  dsetout = work.dups
);
%if &dupvar > 0
%then
  %do;
    %put %str(RTE)RROR: &macroname: Dataset has multiple rows for same &byvars value; 
    %let pv_abort = 1;    
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
  

/* Fix dataset up in case YORDER values not consecutive */  
  data &prefix._sorted;
    set &prefix._rawsort;
    ynum=_N_;
  run;

/* Create a new dataset with 3 times as many records */
  data &prefix._plot;
    set &prefix._sorted(where=(xvar ne .));
    by yorder;
    if lowlimit ne .
    then
      do;
        x=lowlimit;
        output;
      end;
    x=xvar;
    output;
    if uplimit ne .
    then
      do;
        x=uplimit;
        output;
      end;
  run;

  /* Get lists of tick mark labels, for use in AXIS statement */
%global numyvals lt1labs lt2labs rt1labs rt2labs;
%local yvals trub1l trub2l trub1r trub2r;

proc sql noprint;
  select distinct ynum into :yvals separated by ' ' from &prefix._sorted;
  select count(distinct ynum) into :numyvals from &prefix._sorted;
  select tick1l into :lt1labs separated by ' | ' from &prefix._sorted;
  select tick2l into :lt2labs separated by ' | ' from &prefix._sorted;
  select tick1r into :rt1labs separated by ' | ' from &prefix._sorted;
  select tick2r into :rt2labs separated by ' | ' from &prefix._sorted;
  select count(*) into :trub1l from &prefix._sorted where tick1l like "%|%";
  select count(*) into :trub2l from &prefix._sorted where tick2l like "%|%";
  select count(*) into :trub1r from &prefix._sorted where tick1r like "%|%";
  select count(*) into :trub2r from &prefix._sorted where tick2r like "%|%";
quit;

%let lt1labs=| &lt1labs |;
%let lt2labs=| &lt2labs |;
%let rt1labs=| &rt1labs |;
%let rt2labs=| &rt2labs |;

%if &trub1l > 0
%then
  %do;
    %put %str(RTW)ARNING: &macroname: "|" character found in tick1l values - check axis;
  %end;
%if &trub2l > 0
%then
  %do;
    %put %str(RTW)ARNING: &macroname: "|" character found in tick2l values - check axis;
  %end;
%if &trub1r > 0
%then
  %do;
    %put %str(RTW)ARNING: &macroname: "|" character found in tick1r values - check axis;
  %end;
%if &trub2r > 0
%then
  %do;
    %put %str(RTW)ARNING: &macroname: "|" character found in tick2r values - check axis;
  %end;

  /*----------------------------------------------------------------------*/ 
  /*-- LM1.3 - Derive some useful data-dependent macro variables */

%global x_order;    * ORDER statement for inclusion in an AXIS statement for X-axis;
%global y_order;    * ORDER statement for inclusion in an AXIS statement for Y-axis;

  /*----------------------------------------------------------------------*/ 
  /*-- LM1.4 - Derive macro variables containing axis ORDER clauses */

%let y_order=order=(&yvals.);
                 
%if &logbase > 0
%then
  %do; 
    %tu_orderlog(macrovar=x_order, 
                 dsetin=&prefix._plot,
                 varlist=x, 
                 logbase=&logbase);
  %end;
%else
  %do;
    %tu_order(macrovar=x_order, 
              dsetin=&prefix._plot,
              varlist=x);
  %end;
             
%mend tte11_input_dataset;

  /*----------------------------------------------------------------------*/ 
  /*-- LM2 - Define local macro TTE11_Write_template */
 
   /* Provides user with a SAS code template for the required input dataset */

%macro tte11_write_template(fnam);

/* NB All quotes to be generated must be preceded by "%", whether matched or not. */

data _null_;
  file &fnam;

%tu_cr8proghead(macname=create_tte11_example_dataset, macdesign=SAS_datastep_not_a_macro);
* Second param above is not validated but cannot be more than one word, apparently;

put " ";
put "%nrstr(data work.tte11_example_dataset;)";
put "%nrstr(* Data set must include at least these 8 variables;)";
put "%nrstr(* Data set must have one record per yorder value; )";
put "%nrstr(  attrib)";
put "%nrstr(    tick1l   length=$120 label=%"Upper tick mark label for left vertical axis%")";
put "%nrstr(    tick1r   length=$120 label=%"Upper tick mark label for right vertical axis%")";
put "%nrstr(    tick2l   length=$120 label=%"Lower tick mark label for left vertical axis%")";
put "%nrstr(    tick2r   length=$120 label=%"Lower tick mark label for right vertical axis%")";
put "%nrstr(    yorder   length=8    label=%"Order of plotting - lowest values nearest x-axis%")";
put "%nrstr(    xvar     length=8    label=%"Value to be plotted%")";
put "%nrstr(    uplimit  length=8    label=%"Upper limit for error bars%")";
put "%nrstr(    lowlimit length=8    label=%"Lower limit for error bars%")";
put "%nrstr(  ;)"; 
put "%nrstr(run;)";

run;

%mend tte11_write_template;

  /*----------------------------------------------------------------------*/ 
  /*-- LM3 - Define local macro TTE11_Use_template */

  /* Uses an input template for the input dataset */

%macro tte11_use_template(filespec);

  %global tmp_dset;

  %include "&filespec";

  %let tmp_dset=&syslast;       * Save name of dataset just created;

%mend tte11_use_template;

  /*----------------------------------------------------------------------*/ 
  /*-- LM4 - Define local macro TTE11_Write_Options */

   /* Provides user with source code for standard graphics options  */
   /* (data dependent) */

%macro tte11_write_options(fnam);

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

%tu_cr8proghead(macname=tte11_graphics_options, macdesign=SAS_code_not_a_macro);
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
   *-- LM4.4 - Generate AXIS statements ;
   
%local next;     
put "/" "%nrstr(* Set the axis details *)" "/";
put "/" "%nrstr(* WIDTH option here determines thickness of frame around plot area *)" "/";
put "/" "%nrstr(* AXIS1 is left vertical axis *)" "/";
put "%nrstr(axis1 c=black width=2 offset=%(4,8 PCT%))" " &y_order " "%nrstr(label=none minor=none value=%(angle=0 h=12pt j=right)"
%do i=1 %to &numyvals;
  " tick=&i "
/*********************  
  %let next=%scan(&lt1labs,&i,'|');
  %if %length(&next) > 0
  %then
    %do; 
  "%nrstr(%")" "&next" "%nrstr(%")"
    %end;
  %let next=%scan(&lt2labs,&i,'|');
  %if %length(&next) > 0
  %then
    %do;      
  "%nrstr( j=right %")" "&next" "%nrstr(%")"
    %end;
**********************/
  %let next=%str( )%scan(&lt1labs,&i,'|')%str( );
  "%nrstr(%")" "&next" "%nrstr(%")" 
  %let next=%str( )%scan(&lt2labs,&i,'|')%str( );
  "%nrstr( j=right %")" "&next" "%nrstr(%")"
%end;
"%nrstr(%);)";
put "/" "%nrstr(* AXIS2 is right vertical axis *)" "/";
put "%nrstr(axis2 c=black width=2 offset=%(4,8 PCT%))" " &y_order " "%nrstr(label=none minor=none value=%(angle=0 h=12pt j=left)"
%do i=1 %to &numyvals;
  " tick=&i " 
/**********************  
  %let next=%scan(&rt1labs,&i,'|');
  %if %length(&next) > 0
  %then
    %do; 
  "%nrstr(%")" "&next" "%nrstr(%")" 
    %end;
  %let next=%scan(&rt2labs,&i,'|');
  %if %length(&next) > 0
  %then
    %do;     
  "%nrstr( j=left %")" "&next" "%nrstr(%")"
    %end;
************************/

/* Have to right-justify here because of an apparent SAS bug. 
   If we left-justify and there are 2 non-empty lines of text, text may be positioned inside the axis */
  %let next=%str( )%scan(&rt1labs,&i,'|')%str( );
  "%nrstr( j=right %")" "&next" "%nrstr(%")" 
  %let next=%str( )%scan(&rt2labs,&i,'|')%str( );
  "%nrstr( j=right %")" "&next" "%nrstr(%")"
%end;
"%nrstr(%);)";
put "/" "%nrstr(* AXIS3 is horizontal axis *)" "/";
put "%nrstr(axis3 c=black width=2)" " &x_order " "%nrstr(minor=none label=%(h=12pt )"
%if %length(%nrbquote(%sysfunc(compbl(&XAxisLabel)))) > 0
%then
  %do; 
    "%nrstr(%")&XAxisLabel%nrstr(%")" 
  %end;
%local leftarrow rightarrow revertfont;

/*
%let revertfont=h=12pt font=HWPSL009DEFAULT;
%let leftarrow=%nrstr(font=marker h=18pt %"I  %") &revertfont; 
%let rightarrow=%nrstr(font=marker h=18pt %"  J %");
*/

%let leftarrow=%nrstr(%"<%") h=16pt %nrstr(%"-- %") h=12pt;
%let rightarrow=h=16pt %nrstr(%" --%") h=12pt %nrstr(%">%");
/* Would prefer to use nice arrow characters from Marker font but cannot find a way of reverting to usual font afterwards */ 
%if %length(&XaxisLabelLeft) > 0 and %length(&XaxisLabelRight) > 0
%then
  %do;
    " justify=left &leftarrow %nrstr(%")&XaxislabelLeft%nrstr(%") justify=right %nrstr(%")&XaxislabelRight%nrstr(%") &rightarrow"
  %end;
%else
  %if %length(&XaxisLabelLeft) > 0
  %then
    %do;
      " justify=left  &leftarrow %nrstr(%")&XaxislabelLeft%nrstr(%") "
    %end;
  %else %if %length(&XaxisLabelRight) > 0
  %then
    %do;
      " justify=right %nrstr(%")&XaxislabelRight%nrstr(%") &rightarrow"
    %end;    
"%nrstr(%);)";
  
  *----------------------------------------------------------------------; 
  *-- LM4.5 - Generate SYMBOL statement ;
  
put "/" "%nrstr(* Set Symbol. The same symbol will be used for all data *)" "/";
put "/" "%nrstr(* FONT=MARKER VALUE=%'U%' specifies a filled square. *)" "/";
put "/" "%nrstr(* NB No INTERPOL option specified here has any effect. *)" "/";
put "/" "%nrstr(* WIDTH affects the range bars %(and bar ends, if specified%). *)" "/";
put "%nrstr(symbol1 color=blue font=marker value= %'U%' height=1 width=5 line=1 interpol=join;)";
run;

%mend tte11_write_options;

  /*----------------------------------------------------------------------*/ 
  /*-- LM5 - Define local macro TTE11_Graphics */

  /* Generates graphics, using the specified graphics options file */


%macro tte11_graphics(filespec);

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


   /* Macro variables used in optional annotations */    
%let textsize=2;        /* Size of text when ShowStatitic = Y */
%let halfbar=0.1;       /* Size of bar ends when ShowBarEnd = Y */

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
  /*-- LM5.3 - Retrieve SYMBOL statement and extract colour, line width etc */
  
  %tu_getgstatements(
     dsetout=&prefix._syminfo,
     statements=SYMBOL
     );

data _null_;
  set &prefix._syminfo;
  length colstr $120 barcols $512;
  retain colstr ' ' barcols ' ';
  cvpos=index(text,"CV=");
  ourtext=substr(text,cvpos+3);
  thiscol=scan(ourtext,1);
  colstr=left(trim(colstr)) || ' ' || left(trim(thiscol));
  * Each colour really is needed twice in BARCOLS;
  barcols=left(trim(barcols)) || ' (color=' || left(trim(thiscol)) || ')'; 
  barcols=left(trim(barcols)) || ' (color=' || left(trim(thiscol)) || ')'; 
  call symput('colstr',colstr);
  call symput('barcols',barcols);
  * Also output width for later use;
  widthpos=index(text,"WIDTH=");
  ourtext=substr(text,widthpos+6);
  thiswid=scan(ourtext,1);
  call symput('width',thiswid);      
  * Also output all axis info as macro vars for later use;
  namenum='name' || left(trim(put(_N_,2.)));
  textnum='symtxt' || left(trim(put(_N_,2.)));
  call symput(namenum, name);
  call symput(textnum, text);
run;

/* Redefine symbol, making sure there are no interpolation lines */  
/* We need an identical second symbol, since we are going to do a PLOT2 */   
symbol1 &symtxt1 interpol=none;
symbol2 &symtxt1 interpol=none;

   /*----------------------------------------------------------------------*/ 
  /*-- LM5.4 - Annotations of data values, if required */

%let ourfont=%sysfunc(getoption(ftext));

%local xvarfmt;        /* Default format for XVAR */
data _null_;
  set &prefix._sorted(obs=1);
  xvarfmt=vformat(xvar);
  call symput('xvarfmt',xvarfmt);
run;

%if &ShowStatistic=Y
%then
  %do;
    %annomac;
    data &prefix._statanno;
      %dclanno;
      length text $12;
      set &prefix._sorted;
      %system(2,2,3);
      x=xvar;
      y=ynum;
      text=put(xvar,&xvarfmt);
      style="&ourfont";
      size=&textsize;
      color='BLACK';
      position='2';
      function='LABEL';
      output;
    run;
  %end;
       
   /*----------------------------------------------------------------------*/ 
  /*-- LM5.5 - Annotations for bar ends, if required */
  
%if &ShowBarEnd=Y
%then
  %do;
    %annomac;
    data &prefix._baranno;
      %dclanno;
      length text $12;
      set &prefix._plot(where=(x ne xvar));
      %system(2,2,4);
      %move(x,ynum-&halfbar);
      %draw(x,ynum+&halfbar,%scan(&colstr,1),1,&width);
    run;
  %end;
       
  /*----------------------------------------------------------------------*/ 
  /*-- LM5.6 - Concatenate all annotations */
  
data &prefix._allanno;
  %if &ShowStatistic=Y or &ShowBarEnd=Y
  %then
    %do;
      set
      %if &ShowStatistic=Y
      %then
        %do;
          &prefix._statanno
        %end;
      %if &ShowBarEnd=Y
      %then
        %do;
          &prefix._baranno
        %end;
      ;
    %end;  
run;

  /*----------------------------------------------------------------------*/ 
  /*-- LM5.7 - Generate options string for reference lines */

  /* Beware possible confusion here! */
  /* This macros parameter VRefLines refers to reference lines that run vertically */
  /* But GPLOT options VREF, CVREF, LVREF relate to lines PERPENDICULAR TO vertical axis */
  /* Similarly with "horizontal" parameter and options */
  
  %local reflines;
  %let reflines=;
  %if %length(%nrbquote(%sysfunc(compbl(&VRefLines)))) > 0   
    %then
    %do;
      %let reflines=chref=black lhref=1 href=&VRefLines ;
    %end;
  /*----------------------------------------------------------------------*/ 
  /*-- LM5.8 - Generate the main plot */
  /* We need a PLOT2 to get the right-hand axis */
  /* But the second plot we want to do has a different x-axis variable, so is incompatible */

  proc gplot data=work.&prefix._sorted(where=(xvar ne .)) annotate=&prefix._allanno gout=temp_cat; 
       plot ynum * xvar
     / haxis=axis3 vaxis=axis1 &reflines name="points";
       plot2 ynum * xvar
     / vaxis=axis2;
     run;
quit;

  /*----------------------------------------------------------------------*/ 
  /*-- LM5.9 - Generate a plot of the ranges */
  
/* Generate as many symbol statements as we need */
/* (Double what you might think, since we are using PLOT2) */
%do i=1 %to %eval(2*&numyvals);
  symbol&i &symtxt1 interpol=join value=none;
%end;

proc gplot data=work.&prefix._plot gout=temp_cat; 
       plot ynum * x=ynum
     / haxis=axis3 vaxis=axis1 &reflines nolegend name="ranges";
       plot2 ynum * x=ynum
     / vaxis=axis2 nolegend;
     run;
quit;

    /* Superimpose the two plots, yielding a new graphics entry called TEMPLATE */
    proc greplay igout = temp_cat gout = graph_cat tc = tempcat nofs;
      tdef splicem

        1 / llx = 0  lly = 0      lrx = 100  lry = 0
            ulx = 0  uly = 100    urx = 100  ury = 100

        2 / llx = 0  lly = 0      lrx = 100  lry = 0
            ulx = 0  uly = 100    urx = 100  ury = 100;

      template splicem;
        treplay 1:ranges 2:points;
    run;
    quit;    


  /*----------------------------------------------------------------------*/ 
  /*-- LM5.10 - Generate plot header and footer as GSLIDE graphics */

%local ourfont;
%let ourfont=%sysfunc(getoption(ftext));

%tu_cr8gheadfoots(gout    = graph_cat_hf,
                  kill    = y,
                  pagecat = graph_cat,
                  font    = &ourfont,
                  ptsize  = 8);

  /*----------------------------------------------------------------------*/ 
  /*-- LM5.11 - Put it all together - main plot plus GSLIDE */

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
* Main plot is called TEMPLATE;
  template newtemp;
    treplay 1:template 2:gslide;
run;
quit;

  /*----------------------------------------------------------------------*/ 
  /*-- LM5.12 -  Convert PostScript file to PDF using utility ps2pdf (if available) */ 
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

%mend tte11_graphics;

/************************************************************************/
/* Finally the rest of the main macro TD_TTE11                          */
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
      %tte11_write_template(usr_prof);
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
        %tte11_use_template(&InputFile); 
        %put %str(RTN)OTE: &macroname: Finished execution of user-supplied SAS code (dataset creation);
        /* Dataset name returned in macrovar tmp_dset */ 
        %tte11_input_dataset(&tmp_dset);
      %end;
    %else 
      %do;
        %tte11_input_dataset(&InputDataset); 
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
        %tte11_write_options(&writopts);
      %end;

  /*----------------------------------------------------------------------*/ 
  /*-- NP9 - Read options file and generate graphics if we need to */
    %if %length(&readopts) > 0 
    %then
      %do;
        %tte11_graphics(&readopts);          
      %end;
%end;

  /*----------------------------------------------------------------------*/
  /*--NP10 - Tidy up and call tu_abort   */
  
  %tu_tidyup(rmdset=&prefix:, glbmac=NONE);
  %tu_abort;

%mend td_tte11;
