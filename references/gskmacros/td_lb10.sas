/*******************************************************************************
|
| Macro Name:      td_lb10
|
| Macro Version:   2 build 1
|
| SAS Version:     8.2
|                                                             
| Created By:      Bob Newman (Amadeus) 
|
| Date:            01 November 2006
|
| Macro Purpose:   To generate an LB10 plot
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
|  XaxisLabel       Label for X-axis                                 OPT      Liver Function Test
|  YaxisLabel       Label for Y-axis                                 OPT      [BLANK]
|  HReflines        Positions for horizontal reference lines         OPT      [BLANK] 
|  BoxOffset        Offset between error bars for each treatment     OPT      0.2
|  OutThreshold     Value for YVAR beyond which upper margin reqd    OPT      [BLANK] 
|  ShowBarEnd       Bars at ends of whiskers (Y/N)                   REQ      Y 
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
| (@) tu_putglobals
| (@) tu_tidyup
| (@) tu_valparms
|
| Example:
| %td_lb10(InputDataset=myplot
|   , InputUsage=D
|  );
|
|******************************************************************************
| Change Log
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     01-Nov-06
| New version/draft number: 01.001
| Modification ID:          RCN.01.001
| Reason For Modification:  Original version
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     27-Nov-06
| New version/draft number: 01.002
| Modification ID:          RCN.01.002
| Reason For Modification:  Altered validation of ShowBarEnd.
|                           Eliminated EG8 references.
|                           Use TRTORD rather than TRTCD - changes at LM1.2, 1.3, 5.4, 5.9. 
|                           Changes to handling of THRESH dataset al LM1.2, including extra validation.
|                           Enhanced validation of HREFLINES and OUTTHRESHOLD parameters.
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     28-Nov-06
| New version/draft number: 01.003
| Modification ID:          RCN.01.003
| Reason For Modification:  Altered check for null OutThreshold spec at LM1.2. 
|                           Altered check for null HRefLines spec at LM1.2.
|                           Create HREF dataset even when HREFLINES not specified (PV7).
|                           Even more careful quoting at PV7.
|                           Altered error message at PV8.
|                           At LM1.2 changed separator from '|' to ' | ' to handle null labels better.
|
| Modified By:              Shan Lee
| Date of Modification:     23-Mar-07
| New version/draft number: 02.001
| Modification ID:          SL001
| Reason For Modification:  Issue discovered after release of V1 that macro does not create
|                           an appropriate and full legend if boxplots do not contain outliers.
|                           Macro modified to add extra rows to plotting dataset containing 
|                           all TRTORD values so that GPLOT can use to construct legend.  
|                           Also, modified the data _null_ step where the subjfmt macro variable
|                           is created, so that the program will not crash if there are no outliers.
*******************************************************************************/
  
%macro td_lb10
      (
       InputDataset=           /* type:ID Input dataset */,
       InputFile=              /* Name of file if InputUsage=C or U */,
       InputUsage=D            /* Style of input data D=dataset C=create template U=use template */,
       OptionsFile=            /* Name of file if OptionsFileUsage=C or U */,
       OptionsFileUsage=       /* Style of options file C=create U=use blank=use default settings */,
       XAxisLabel=Liver Function Test /* Horizontal axis label */,
       YAxisLabel=             /* Vertical axis label */,
       HRefLines=              /* Positions for horizontal reference lines */,
       BoxOffset=0.2           /* Offset between treatment groups, in data units */,
       OutThreshold=           /* Threshold for upper margin */,
       ShowBarEnd=Y            /* Crossbars at end of whiskers (Y/N) */
      );
   
  /**---------------------------------------------------------------------*/
  /*--Normal Processing (NP1) -  Echo parameter values and global macro variables to the log */
  %local MacroVersion prefix currentDataset i macroname;
  %let macroname = &sysmacroname.;
  %let MacroVersion = 2 build 1;
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
  %let BoxOffset=%nrbquote(&BoxOffset);
  /* Slash-separated lists need a space inserting after each slash */
  /* SAS treats consecutive delimiters as a single delimiter; we do not want to */
  %let HRefLines=%nrbquote(&HRefLines);
  %let Hreflines=%nrbquote(%sysfunc(tranwrd(&HRefLines,%str(/),%str(/ ))));
  %let OutThreshold=%nrbquote(&OutThreshold);
  %let OutThreshold=%nrbquote(%sysfunc(tranwrd(&OutThreshold,%str(/),%str(/ ))));
  %let ShowBarEnd=%upcase(&ShowBarEnd);
  %let ShowBarend=%nrbquote(&ShowBarEnd);
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

  /*--PV1 - BOXOFFSET: check numeric and < 100 */
  %if %length(%sysfunc(compbl(&boxoffset))) = 0
  %then
    %do;
      %put %str(RTE)RROR: &macroname: BoxOffset blank - positive value required;
      %let pv_abort = 1;
    %end;
  %else
    %do;
      %if %datatyp(&boxoffset) ne NUMERIC
      %then
        %do;
          %put %str(RTE)RROR: &macroname: Specified BoxOffset is not numeric;
          %let pv_abort = 1;
        %end;
      %else
        %do;
          %if %sysevalf(&boxoffset <= 0)
          %then
            %do;
              %put %str(RTE)RROR: &macroname: BoxOffset must be positive; 
              %let pv_abort = 1;
            %end;
        %end;
    %end;
      
  /*--PV2 - INPUT USAGE: check it is D, C or U */
  %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = InputUsage, valuelist = C D U, abortyn = N);
    
  /*--PV3 - INPUT DATASET: check specified when and only when needed */
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

  /*--PV4 - INPUT FILE: check correctly specified when and only when needed */ 
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

   /*--PV5 - OPTIONS FILE USAGE: check it is C, U or blank */
   /* NB blank is valid */
  %if %length(%sysfunc(compbl(&OptionsfileUsage))) > 0
  %then
    %do;
      %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = OptionsFileUsage, valuelist = C U, abortyn = N);
    %end;     

   /*--PV6 - OPTIONS FILE: check correctly specified when and only when needed */ 
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
    
  /*--PV7 - HREFLINES: check any values specified are numeric */
  /* Scientific notation is acceptable here (since PROC GPLOT is not going to see these values) */
  /* While we valid it, we create the HREF dataset */
          data &prefix._href;
          length href $120;
  %local slashless slashcount i thisval thisvalOK;
  %if %length(%sysfunc(compbl(&HRefLines))) > 0
  %then
    %do;
      /* Count number of slashes in string */
      %let slashless=%nrbquote(%sysfunc(compress(&HRefLines,%str(/))));
      %let slashcount=%eval(%length(&HRefLines) - %length(&slashless));
      %local HRefErr;
      %let HRefErr=0;
      %if &slashcount < 2
      %then
        %do;
          %put %str(RTE)RROR: &macroname: HRefLines specifications must be delimited using '/' character;
          %let pv_abort = 1;
          %let HRefErr=1;          
        %end;
      %if %quote(%substr(&HRefLines,1,1)) ne %str(/)
        %then
          %do;
            %put %str(RTE)RROR: &macroname: HRefLines specification must begin with a '/' character;
            %let pv_abort = 1;
            %let HRefErr=1;          
          %end;
      /* Subtract 1 from length here because '/' changed to '/ ' in parameter cleanup above */    
      %if %quote(%substr(&HRefLines,%eval(%length(&HRefLines)-1),1)) ne %str(/)
        %then
          %do;
            %put %str(RTE)RROR: &macroname: HRefLines specification must end with a '/' character;
            %let pv_abort = 1;
            %let HRefErr=1;          
          %end;
      %if &HRefErr=0
      %then
        %do;
          %do i=1 %to %eval(&slashcount-1);
            %let thisval=%nrbquote(%sysfunc(compbl(%qscan(&HRefLines,&i,%str(/)))));
            /* THISVAL should be a space-separated list of numbers */          
            %if %length (&thisval) > 0 
            %then
              %do;
                %let thisvalOK=Y;
                %if %length(%nrbquote(%sysfunc(compbl(&HRefLines)))) > 0
                %then
                  %do;
                    %let j=1;
                    %do %while (%length(%qscan(&thisval,&j,%str( ))) > 0);
                    /* Space is the only delimiter we recognise here */
                      %let thisnum=%qscan(&thisval,&j,%str( ));
                      %if %datatyp(&thisnum) ne NUMERIC
                      %then
                        %do;
                          %put %str(RTE)RROR: &macroname: HRefLines value &thisnum is not numeric;   
                          %let pv_abort = 1;
                          %let thisvalOK=N;          
                        %end;
                      %let j=%eval(&j+1);
                    %end;
                  %end; 
                %if &thisvalOK=Y
                %then
                  %do;
                    xnum=&i;
                    href="&thisval";
                    output;
                  %end;
              %end;
          %end;
        %end;
    %end;
          run;
   
  /*--PV8 - OUTTHRESHOLD: check numeric if specified */
  /* While we validate it, we create the THRESH dataset (even if OUTTHRESHOLD not specified */ 
          data &prefix._thresh;
            length xnum thresh 8.;
  %if %length(%sysfunc(compbl(&OutThreshold))) > 0
  %then
    %do;
      /* Count number of slashes in string */
      %local slashless slashcount i thisval ThreshErr;
      %let slashless=%nrbquote(%sysfunc(compress(&OutThreshold,%str(/))));
      %let ThreshErr=0;
      %let slashcount=%eval(%length(&OutThreshold) - %length(&slashless));
      %if &slashcount < 2
      %then
        %do;
          %put %str(RTE)RROR: &macroname: OutThreshold values must be delimited using '/' character;
          %let pv_abort = 1;
          %let ThreshErr=1;          
        %end;
      %if %quote(%substr(&OutThreshold,1,1)) ne %str(/)
        %then
          %do;
            %put %str(RTE)RROR: &macroname: OutThreshold specification must begin with a '/' character;
            %let pv_abort = 1;
            %let ThreshErr=1;          
          %end;
      /* Subtract 1 from length here because '/' changed to '/ ' in parameter cleanup above */    
      %if %quote(%substr(&OutThreshold,%eval(%length(&OutThreshold)-1),1)) ne %str(/)
        %then
          %do;
            %put %str(RTE)RROR: &macroname: OutThreshold specification must end with a '/' character;
            %let pv_abort = 1;
            %let ThreshErr=1;          
          %end;
      %if &ThreshErr=0
      %then
        %do;
          %do i=1 %to %eval(&slashcount-1);
            %let thisval=%left(%trim(%qscan(&OutThreshold,&i,%str(/))));          
            %if %length (&thisval) > 0 
            %then
              %do;
                %if %datatyp(&thisval) ne NUMERIC
                %then
                  %do;
            /*     %put %str(RTE)RROR: &macroname: OutThreshold value &thisval is not numeric;   */
                    %put %str(RTE)RROR: &macroname: OutThreshold value &thisval is not in valid format; 
                    %let pv_abort = 1;          
                  %end;
                %else
                  %do;
                    xnum=&i;
                    thresh=&thisval;
                    output;
                  %end;
              %end;
          %end;
        %end;
    %end;
          run;
    
  /*--PV9 - SHOWBAREND : check it is Y or N */
  
  /****
  %if %length(%sysfunc(compbl(&ShowBarEnd))) = 0
  %then
    %do;   
      %let ShowBarEnd=Y;
    %end;
  %else
    %do;
    *****/
      %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = ShowBarEnd, valuelist = Y N, abortyn = N);
   /**** 
    %end;       
   ****/          
/*----------------------------------------------------------------------*/
  /*- complete parameter validation */
  %if %eval(&g_abort. + &pv_abort.) gt 0 %then %do;
    %put %str(RTE)RROR: &macroname: Macro has failed parameter validation check for reasons stated with %str(RTE)RRORs above;
    %tu_abort(option=force);
  %end;
  /*----------------------------------------------------------------------*/


  /*----------------------------------------------------------------------*/ 
  /*-- LM1 - Define local macro LB10_Input_Dataset */
  
  /*  Processes user-supplied input dataset */
  /* (Validation and any necessary manipulation) */
  /* We create a dataset PLOT for use in the actual graphics. */

%macro lb10_input_dataset(dsname);

/* Lists of variable names, by data type, and all required */
%local charvars numvars mustvars byvars;
%let charvars=trtgrp xvarlbl;
%let numvars=trtcd xvar yvar subjid;
%let mustvars=&charvars &numvars;
/* List of variables which must be a unique n-tuple for each record */
%let byvars=trtcd xvar subjid;
%global dupvar;		* Variable to receive number of duplicates found;
  
  /*----------------------------------------------------------------------*/ 
  /*-- LM1.1 - Validation of dataset */
  
%local pv_abort; 
%let pv_abort=0;    * tu_valparms requires this to exist;

/* Check existence of datasets */
%tu_valparms(
  abortyn=Y,
  macroname=lb10_input_dataset,
  chktype=dsetExists,
  pv_dsetin=dsname
  );
/* Check presence of variables */
%tu_valparms(
  abortyn=N,
  macroname=lb10_input_dataset,
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
        macroname=lb10_input_dataset,
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
        macroname=lb10_input_dataset,
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

/* Check one-to-one corresp btwn XVAR and XVARLBL */
%local xvarct pairct;
proc sql noprint;
  select count(distinct xvar) into :xvarct from &dsname;
  create table &prefix._xpairs as 
    select xvar,xvarlbl,count(*) as freq from &dsname
    group by xvar,xvarlbl order by xvar;    
  select count(*) into :pairct from &prefix._xpairs;
quit;

%if &xvarct ne &pairct
%then
  %do;
    %put %str(RTE)RROR: &macroname: Inconsistent XVAR/XVARLBL pairings in dataset;
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
  /*-- LM1.2 - Generate datasets for plotting */
  
  /* Sort data */ 
  proc sort data=&dsname 
       out=&prefix._sorted; 
       by trtcd xvar;
  run;
  
  proc sort data=&dsname 
       out=&prefix._xsorted; 
       by xvar;
  run;
  
  data &prefix._xorder;
    set &prefix._xsorted;
    by xvar;
    retain xnum 0;
    if FIRST.xvar then xnum+1;
  run;

/* NB Careful! If no thresholds specified, THRESH dataset will still have 1 observation containing missing values */

%local tobs;
proc sql noprint;
  select count(*) into :tobs from &prefix._thresh(where=(xnum ne .));
quit;

%if &tobs > 0
%then
  %do;  
    data &prefix._splice;
      merge &prefix._xorder &prefix._thresh;
      by xnum;
    run;
  %end;
%else
  %do;
    data &prefix._splice;
      set &prefix._xorder;
      thresh=.;
    run;
  %end;
  
  proc sort data=&prefix._splice
       out=&prefix._sorted; 
       by trtcd xvar;
  run;
  
  /* Get the number of XVAR values and their labels */
  %global numxvals xvalues xlabels numtrts hobs;
  proc sql noprint;
    select count(distinct trtcd) into :numtrts from &prefix._sorted;
    select count(distinct xvar) into :numxvals from &prefix._sorted;
    select distinct xnum into :xvalues separated by ' ' from &prefix._sorted;
    select xvarlbl into :xlabels separated by ' | ' from &prefix._xpairs;
    select count(*) into :hobs from &prefix._href(where=(href ne ""));  
  quit;

  %local meantrt;
  %let meantrt=%sysevalf((&numtrts+1)/2);
  
  /* Now we know NUMXVALS, do a little spoon-feeding */
 /* %if %length(%sysfunc(compbl(&HRefLines))) > 0  */
  %if &hobs > 0
  %then
    %do;
      %local maxhref;
      proc sql noprint;
        select max(xnum) into :maxhref from &prefix._href;
      quit;
      %if &maxhref > &numxvals
      %then
        %do;
          %put %str(RTW)ARNING: &macroname: Number of HRefLines specifications exceeds number of tests; 
        %end;
      %if &maxhref < &numxvals
      %then
        %do;
          %put %str(RTN)OTE: &macroname: Number of HRefLines specifications is less than number of tests; 
        %end;
    %end;
  /* %if %length(%sysfunc(compbl(&OutThreshold))) > 0 */
  %if &tobs > 0
  %then
    %do;
      %local maxthresh;
      proc sql noprint;
        select max(xnum) into :maxthresh from &prefix._thresh;
      quit;
      %if &maxthresh > &numxvals
      %then
        %do;
          %put %str(RTE)RROR: &macroname: Number of OutThreshold specifications exceeds number of tests; 
          %tu_abort(option=force);
        %end;
      %if &maxthresh < &numxvals
      %then
        %do;
          %put %str(RTN)OTE: &macroname: Number of OutThreshold specifications is less than number of tests; 
        %end;
    %end;

  /* Fix up the XVAR values for boxoffset */
  /* For this plot they are centred about the tickmarks */ 
  data &prefix._alldata;
    set &prefix._sorted;
    by trtcd xvar;    
    retain trtord 0;       * Ordinal number for treatment code;
    if FIRST.trtcd 
    then 
      do;
        trtord+1;
       end;
    xvaroff=xnum+((trtord-&meantrt)*&boxoffset.); * Add offset to xvar; 
  run; 
  
  /*----------------------------------------------------------------------*/ 
  /*-- LM1.3 - Derive dataset for use in plotting whiskers */
  
  proc sort data=&prefix._alldata out=&prefix._sortoff;
    by trtcd xvaroff;
  run;
  
  proc univariate data=&prefix._sortoff noprint;
    by trtcd trtord xvaroff thresh;
    var yvar;
    output out=&prefix._stats q1=lowerq q3=upperq qrange=iqr min=lowest max=highest mean=mean median=median;
  run;

  %local maxtop whisk_err;
  %let whisk_err=N;  
  data &prefix._bardata;
    retain maxtop;
    set &prefix._stats;
    barbot=max(lowest,lowerq-1.5*iqr);
    bartop=min(highest,upperq+1.5*iqr);
    maxtop=max(maxtop,bartop);
    call symput('maxtop',maxtop);
    if thresh ne . and bartop > thresh
    then
      call symput('whisk_err',thresh);
  run;
  
  %if &whisk_err ne N
  %then
    %do;
      %put %str(RTE)RROR: &macroname: One or more OutThreshold values (including %left(&whisk_err)) too low - must be above corresponding whisker.;
      %tu_abort(option=force);
    %end;  
 
  /*----------------------------------------------------------------------*/ 
  /*-- LM1.4 - Derive outliers datasets */
  
  data &prefix._outliers;
    merge &prefix._sortoff &prefix._bardata;
    by trtcd xvaroff;
    if yvar > bartop or yvar < barbot;
  run;
  
  /*----------------------------------------------------------------------*/ 
  /*-- LM1.5 - Derive some useful data-dependent macro variables */

%global numticks;       * Number of different X-axis values;
%global x_order;    * ORDER statement for inclusion in an AXIS statement for X-axis;
%global y_order;    * ORDER statement for inclusion in an AXIS statement for Y-axis;
%local trtlist trouble;

  proc sql noprint;
        create table &prefix._trttab as
          select distinct trtgrp,trtcd from &prefix._alldata order by trtcd;
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
  /*-- LM1.6 Derive macro variables containing LEGEND strings */
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
  %global trtnam&i;
  %let trtnam&i=&thistrt;
%end;

  /*----------------------------------------------------------------------*/ 
  /*-- LM1.7 - Derive macro variables containing axis ORDER clauses */
  /*           Also some relating to tick marks */

   %global y_order;
   %tu_order(macrovar=y_order
            ,dsetin=&prefix._bardata
            ,varlist=lowest highest barbot bartop
            ,minvalue=
            ,maxvalue=
             );

   /* x-axis is more challenging. We include both the ORDER clause and the VALUE/TICK stuff */
    
    %let x_order=order=(0 &xvalues %eval(&numxvals+1));
    %let x_order=%sysfunc(compbl(&x_order));
    
    %local j;
    %do j=1 %to &numxvals;
      %global xtick&j;
      %let xtick&j=%str( )tick=%eval(&j+1) %str(%')%trim(%scan(&xlabels,&j,%str(|)))%str(%');
    %end;

/* Null ticks fore and aft */    
    %global xtick0 xtick%eval(&numxvals+1);
    %let xtick0=%str( tick=1 ' ');
    %let xtick%eval(&numxvals+1)=%str( tick=)%eval(&numxvals+2)%str( ' ');
    
%mend lb10_input_dataset;

  /*----------------------------------------------------------------------*/ 
  /*-- LM2 - Define local macro LB10_Write_template */
 
   /* Provides user with a SAS code template for the required input dataset */

%macro lb10_write_template(fnam);

/* NB All quotes to be generated must be preceded by "%", whether matched or not. */

data _null_;
  file &fnam;

%tu_cr8proghead(macname=create_lb10_example_dataset, 
macdesign=SAS_datastep_not_a_macro);
* Second param above is not validated but cannot be more than one word, apparently;

put " ";
put "%nrstr(data work.lb10_example_dataset;)";
put "%nrstr(* Data set must include at least these 6 variables;)";
put "%nrstr(* Records with the same XVAR value must have the same XVARLBL value;)"; 
put "%nrstr(  attrib)";
put "%nrstr(    trtgrp   length=$120 label=%"Treatment label to appear in the legend%")";
put "%nrstr(    trtcd    length=8    label=%"Treatment code to order the legend%")";
put "%nrstr(    subjid   length=8    label=%"Subject number to use as outlier label%")";
put "%nrstr(    xvar     length=8    label=%"Variable to be plotted against X-axis%")";
put "%nrstr(    xvarlbl  length=$120 label=%"Text corresponding to XVAR value%")";
put "%nrstr(    yvar     length=8    label=%"Maximum liver function test. To be plotted against Y-axis%")";
put "%nrstr(  ;)"; 
put "%nrstr(run;)";

run;

%mend lb10_write_template;

  /*----------------------------------------------------------------------*/ 
  /*-- LM3 - Define local macro LB10_Use_template */

  /* Uses an input template for the input dataset */

%macro lb10_use_template(filespec);

  %global tmp_dset;

  %include "&filespec";

  %let tmp_dset=&syslast;       * Save name of dataset just created;

%mend lb10_use_template;

  /*----------------------------------------------------------------------*/ 
  /*-- LM4 - Define local macro LB10_Write_Options */

   /* Provides user with source code for standard graphics options  */
   /* (data dependent) */

%macro lb10_write_options(fnam);

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

%tu_cr8proghead(macname=lb10_graphics_options, 
macdesign=SAS_code_not_a_macro);
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
  
put "/" "%nrstr(* Specify the legend position *)" "/";
* Better not to specify legend MODE explicitly.; 
* Default varies sensibly according to whether POSITION is inside or ;
*  outside, and ensures that legend and rest of plot interact (or not) in the way we would wish ;
put "/" "%nrstr(* %"font=none%" is important here. Without it, the frame may not be big enough to contain the legend. *)" "/";
put "/" "%nrstr(* When using ftext=hwpsl009, %"none%" overrides with hwpsl009default *)" "/";
put "/" "%nrstr(* For multi-line text, specify e.g. %"tick=2 %'first line%' justify=left %'second line%'%". *)" "/";
* Across=1 removed 20060904;
put "%nrstr(legend1 position=(bottom center outside) frame cborder=gray label=none
 value=%(font=none h=11pt justify=left )"
%do i=1 %to &numtrts; 
    "&&&legval&i" 
%end;
"%nrstr(%);)";
put " ";

  
   *----------------------------------------------------------------------;
   *-- LM4.5 - Generate AXIS statements ;
  
put "/" "%nrstr(* Set the axis details *)" "/";
put "/" "%nrstr(* WIDTH option here determines thickness of frame around plot area *)" "/";
put "/" "%nrstr(* The small offset here is in case annotated outliers occur right at the top. *)" "/";
put "%nrstr(axis1 c=black width=2 offset=(,5 pct) )" " &y_order " 
"%nrstr(label=%(angle=90 h=12pt %")"
%if %length(%nrbquote(%sysfunc(compbl(&YAxisLabel)))) > 0
%then
  %do; 
    "&YAxisLabel"
  %end; 
"%nrstr(%"%);)";
put "/" "%nrstr(* X-axis.%". *)" "/";
put "%nrstr(axis2 c=black width=2 )" " &x_order " "%nrstr(major=none minor=none label=%(h=12pt %")" 
%if %length(%nrbquote(%sysfunc(compbl(&XAxisLabel)))) > 0
%then
  %do; 
    "&XAxisLabel"
  %end; 
"%nrstr(%"%) value=%(h=12pt )"
%do i=0 %to %eval(&numxvals+1);
    "&&&xtick&i"
%end;
"%nrstr(%);)";
put " ";

  *----------------------------------------------------------------------; 
  *-- LM4.6 - Generate SYMBOL statements ;
  
put "/" "%nrstr(* Set Symbols. *)" "/";
put "/" "%nrstr(* Use of any INTERPOL option would change the essence of the plot *)" "/";
put "%nrstr(symbol1 color=red    value=circle    height=1;)";
put "%nrstr(symbol2 color=blue   value=x         height=1;)";
%if &numtrts > 2
%then
  %do;
put "%nrstr(symbol3 color=green  value=triangle  height=1;)";
  %end;
%if &numtrts > 3
%then
  %do;
put "%nrstr(symbol4 color=black  value=%':%'     height=1;)";
  %end;
%if &numtrts > 4
%then
  %do;
put "%nrstr(symbol5 color=cyan   value=diamond   height=1;)";
  %end;
%if &numtrts > 5
%then
  %do;
put "%nrstr(symbol6 color=violet value=Y         height=1;)";
  %end;
%if &numtrts > 6
%then
  %do;
put "%nrstr(symbol7 color=orange value=square    height=1;)";
  %end;
%if &numtrts > 7
%then
  %do;
put "%nrstr(symbol8 color=steel  value=hash      height=1;)";
  %end;
%if &numtrts > 8
%then
  %do;
put "/" "%nrstr(* Only 8 symbols are defined automatically - *)" "/" ;
put "/" "%nrstr(* please define SYMBOL9 etc as required by your data *)" "/" ; 
  %end;

run;

%mend lb10_write_options;

  /*----------------------------------------------------------------------*/ 
  /*-- LM5 - Define local macro LB10_Graphics */

  /* Generates graphics, using the specified graphics options file */


%macro lb10_graphics(filespec);

/* Do not use RESET=ALL - incompatible with ts_setup */
  GOPTIONS reset=goptions;

  /*----------------------------------------------------------------------*/ 
  /*-- LM5.0 - Define user-modifiable macro variables */
  
/* Macro variables for PROC GREPLAY template */  
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
  
/* Macro variable for formatting of the box */
  %local radius;         /* Radius of circles at mean (in % of graphics area) */
  %let radius=0.2;
/* Macro variable for formatting of annotations */
  %local textsize;
  %let textsize=1.8;     /* Size of SUBJID text for outliers (% GA) */
/* Macro variables for reference lines */
  %local refcolor refstyle refwidth;
  %let refcolor=GREEN;
  %let refstyle=1;
  %let refwidth=2;
    
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
/* (BARCOLS probably not actually used by LB10) */
%local colstr barcols numcols;

data _null_;
  set &prefix._syminfo;
  length colstr $120 barcols $512;
  retain colstr ' ' barcols ' ';
  cvpos=index(text,"CV=");
  ourtext=substr(text,cvpos+3);
  thiscol=scan(ourtext,1);
  colstr=left(trim(colstr)) || ' ' || left(trim(thiscol));
  * Each colour really is needed twice in BARCOLS;
  barcols=left(trim(barcols)) || ' (color=' || left(trim(thiscol)) || ' value=square )'; 
  barcols=left(trim(barcols)) || ' (color=' || left(trim(thiscol)) || ' value=diamond )'; 
  call symput('colstr',colstr);
  call symput('barcols',barcols);
  call symput('numcols',_N_);
run;

    
  /*----------------------------------------------------------------------*/ 
  /*-- LM5.4 - Generate Annotate dataset for the boxes and whiskers */
    %local halfbox;        /* Width of boxes will be two-thirds of BoxOffSet */
    %let halfbox=%sysevalf(&BoxOffset/3);
    %let halfbar=%sysevalf(&halfbox * 0.4);
     
    %annomac;   /* Declare ANNOTATE macros */

    data &prefix._boxanno;
      %dclanno;
      length text $8;
      set &prefix._bardata; 
      %system(2,2,4);     * X and Y: data values ;
      colourlist=compbl("&colstr");
      color=scan(colourlist,trtord);   
      xlo=xvaroff-&halfbox;
      xhi=xvaroff+&halfbox;
      %move(xlo, upperq);
      /* Cannot use %draw because colour for that has to be specified as a literal */
      x=xhi;
      size=2;
      style=1;
      function='DRAW';
      output;
      y=lowerq;
      output;
      x=xlo;
      output;
      y=upperq;
      output;
      %move(xlo, median);
      color=scan(colourlist,trtord);   
      size=2;
      style=1;
      function='DRAW';
      x=xhi;      
      output;
      * Now do the whiskers - far easier than using tu_drawbar for them;
      %move(xvaroff,upperq);
      y=bartop;
      function='DRAW';
      output;
      %if &ShowBarEnd=Y
      %then
        %do;
          x=xvaroff-&halfbar;
          output;
          x=xvaroff+&halfbar;
          output;
        %end;
      %move(xvaroff,lowerq);
      y=barbot;
      function='DRAW';
      output;
      %if &ShowBarEnd=Y
      %then
        %do;
          x=xvaroff-&halfbar;
          output;
          x=xvaroff+&halfbar;
          output;
        %end;
      * Finally a filled circle to mark the mean;
      %move(xvaroff,mean);
      hsys=3;
      function='PIE';
      angle=0;
      rotate=360;
      line=0;
      size=&radius;  * Value can be modified in user-supplied options file;
      style='SOLID';
      output;      
    run;
    
  /*----------------------------------------------------------------------*/ 
  /*-- LM5.5 - Generate annotations for reference lines if reqd */


%if %length(%sysfunc(compbl(&Hreflines))) > 0
%then
  %do;  
    data &prefix._hrefanno;
      %dclanno;
      length text $8;
      set &prefix._href;
      %system(2,2,4);     * X and Y: data values ;
      if length(trim(href)) > 0
      then
        do;
          i=1;
          do while (scan(href,i,' ') ne ' ');
            refval=scan(href,i,' ');
            put xnum= refval=;
            %move(xnum-0.5,refval);
            %draw(xnum+0.5,refval,&refcolor,&refstyle,&refwidth);
            i+1;
          end;
        end;
    run;
  %end;
  
  /*----------------------------------------------------------------------*/ 
  /*-- LM5.6 - Generate annotations for extreme outliers (above thresholds) */

  /*
  / SL001
  / Observations from the &prefix._outliers dataset are not read into the program data
  / vector, in order to avoid problems when the dataset has zero observations.
  /--------------------------------------------------------------------------------------*/   

  
  %local ourfont;
  %let ourfont=%sysfunc(getoption(ftext));

  %local subjfmt;        /* Default format for SUBJID */
  data _null_;
    if 0 then set &prefix._outliers;
    subjfmt=vformat(subjid);
    call symput('subjfmt',subjfmt);
    stop;
  run;

  data &prefix._highanno;
    %dclanno;
    length text $12;
    set &prefix._outliers(where=(thresh ne . and yvar > thresh));
    %system(2,2,3);     * X and Y: data values ;
    x=xvaroff;
    y=yvar;
    text=left(put(subjid,&subjfmt));
    style="&ourfont";
    size=&textsize;
    color='BLACK';
    position='3';
    function='LABEL';
    output;
  run;      
  
  /*----------------------------------------------------------------------*/ 
  /*-- LM5.7 - Generate X-axis tick marks as annotations */

   /* AXIS statement deliberately specifies no ticks (major=none minor=none) */
  /* The only tickmarks that appear on this axis are those generated here */  
    data &prefix._tickanno;
      %dclanno;
      length text $8;
      %do j=1 %to &numxvals;        /* Omit beginning and end of axis */
        %system(2,1,4);     * X: data values, Y: %data area;
        %move(&j,0);
        ysys=9;   /* % graphics area, relative */
        y=-1;
        color="BLACK";
        size=2;
        style=1;
        when='A';                 
        function="DRAW";        
        output;
      %end;
    run;
 
  /*----------------------------------------------------------------------*/ 
  /*-- LM5.8 - Concatenate all annotations */
  
data &prefix._allanno;
  set &prefix._boxanno
%if %length(%sysfunc(compbl(&Hreflines))) > 0
%then
  %do;  
      &prefix._hrefanno
  %end;
      &prefix._highanno
      &prefix._tickanno;
run;

  /*----------------------------------------------------------------------*/ 
  /*-- LM5.9 - Generate scatter plot of outliers (with everything else as annotations) */

  /*
  / SL001
  / Include at least one observation for each value of TRTORD, so that the classification
  / variable in the subsequent PROC GPLOT will use the correct symbol statement for 
  / each treatment. The additional observations will have missing values for all variables
  / except for TRTORD, so that they will not cause anything other than the outliers to be
  / printed.
  /--------------------------------------------------------------------------------------*/   

%macro _addtmt(dset=);

proc sort data = &prefix._alldata
          (keep = trtord)
          out = &prefix._tmts
          nodupkey
          ;
  by trtord;
run;

data  &dset;
  set &dset &prefix._tmts;
run;

%mend _addtmt;

%_addtmt(dset=&prefix._outliers);

proc gplot data=work.&prefix._outliers annotate=&prefix._allanno gout=graph_cat;
      plot yvar * xvaroff=trtord
    / haxis=axis2 vaxis=axis1 legend=legend1 name="outliers";
run;
quit;
  
    /*----------------------------------------------------------------------*/ 
  /*-- LM5.10 - Generate plot header and footer as GSLIDE graphics */

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

   /* NB template is fixed at the moment */
   /* Extra headers and footers are liable to overlay main plot */ 

proc greplay igout = graph_final gout = final_out tc = tempcat nofs;
  tdef newtemp

    1 / llx = 5  lly = &boty  lrx = 95  lry = &boty
        ulx = 5  uly = &topy  urx = 95  ury = &topy

    2 / llx = 5  lly = 0      lrx = 95  lry = 0
        ulx = 5  uly = 100    urx = 95  ury = 100;

  template newtemp;
    treplay 1:outliers 2:gslide;
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

%mend lb10_graphics;

/************************************************************************/
/* Finally the rest of the main macro TD_LB10                           */
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
      %lb10_write_template(usr_prof);
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
        %lb10_use_template(&InputFile); 
        %put %str(RTN)OTE: &macroname: Finished execution of user-supplied SAS code (dataset creation);
        /* Dataset name returned in macrovar tmp_dset */ 
        %lb10_input_dataset(&tmp_dset);
      %end;
    %else 
      %do;
        %lb10_input_dataset(&InputDataset); 
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
        %lb10_write_options(&writopts);
      %end;

  /*----------------------------------------------------------------------*/ 
  /*-- NP9 - Read options file and generate graphics if we need to */
    %if %length(&readopts) > 0 
    %then
      %do;
        %lb10_graphics(&readopts);          
      %end;
%end;

  /*----------------------------------------------------------------------*/
  /*--NP10 - Tidy up and call tu_abort   */
  
  %tu_tidyup(rmdset=&prefix:, glbmac=NONE);
  %tu_abort;

%mend td_lb10;
