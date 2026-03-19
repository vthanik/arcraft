/*******************************************************************************
|
| Macro Name:      td_eg8
|
| Macro Version:   2 build 1
|
| SAS Version:     8.2
|                                                             
| Created By:      Bob Newman (Amadeus) 
|
| Date:            05 October 2006
|
| Macro Purpose:   To generate an EG8 plot
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME             DESCRIPTION                                  REQ/OPT  DEFAULT
| --------------   -----------------------------------          -------  --------------
|  InputDataset     Name of data set to be plotted                   OPT      NONE
|  XaxisLabel       Label for X-axis                                 OPT      Week
|  YaxisLabel       Label for Y-axis                                 OPT      [BLANK]
|  BoxOffset        Offset between error bars for each treatment     OPT      NONE
|  InputFile        Name of SAS source file to generate data set     OPT      NONE
|  InputUsage       D (use dataset), U (use file) or C (create file) REQ      D
|  OptionsFile      Name of SAS source file of graphics options      OPT      NONE
|  OptionsFileUsage C (create), U (use) or blank (neither)           OPT      [BLANK]
|  LowPlotHeader    Title for "Number of Subjects" table             REQ      [BLANK]
|  HReflines        Positions for horizontal reference lines         OPT      [BLANK] 
|  OutThreshold     Value for YVAR beyond which upper margin reqd    OPT      999999
|  MarginThreshold  Value for XVAR beyond which right margin reqd    OPT      [BLANK]
|
| Global macro variables created: 
|   NONE
| 
| Macros called: 
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_cr8gheadfoots
| (@) tu_cr8proghead
| (@) tu_drawnumofsubjs
| (@) tu_getgstatements
| (@) tu_nobs
| (@) tu_order
| (@) tu_putglobals
| (@) tu_tidyup
| (@) tu_valparms
|
| Example:
| %td_eg8(InputDataset=myplot
|   , InputUsage=D
|   , LowPlotHeader=Numbers of subjects  
|  );
|
|******************************************************************************
| Change Log
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     27-Sep-06
| New version/draft number: 01.001
| Modification ID:          RCN.01.001
| Reason For Modification:  Original version
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     16-Nov-06
| New version/draft number: 01.002
| Modification ID:          RCN.01.002
| Reason For Modification:  Eliminate reference to MARGFLAG (LM1)
|                           MarginThreshold defaults to blank (not 9999999)
|                           Use BARDATA dataset and BARBOT, BARTOP vars (LM5.6)
|                           so whiskers correct in all cases.
|                           Use TRTORD rather than TRTCD (passim) to handle correctly the case 
|                           where treatment codes not numbered consecutively from 1.
|                           Use DIF (not LAG!) to calculate differences.
|
| Modified By:              Elaine Liu
| Date of Modification:     10-Jan-07
| New version/draft number: 01.003
| Modification ID:          RCN.01.003
| Reason For Modification:  Horizontal reference lines are too faint
|                           (faint in PDF file and invisible in CGM file)
|                           Changed reference line style(lvref) from 34 to 20 (LM5.9)   
|
| Modified By:              Ian Barretto
| Date of Modification:     22-Mar-07
| New version/draft number: 02.001
| Modification ID:          IB.02.001
| Reason For Modification:  Issue discovered after release of V1 that macro does not create
|                           an appropriate and full legend if boxplots do not contain outliers.
|                           Macro modified to add extra rows to plotting dataset containing 
|                           all TRTCD values so that GPLOT can use to construct legend.  
*******************************************************************************/
  
%macro td_eg8
      (
       InputDataset=           /* type:ID Input dataset */,
       XAxisLabel=Week         /* Horizontal axis label */,
       YAxisLabel=             /* Vertical axis label */,
       BoxOffset=              /* Offset between treatment groups, in data units */,
       InputFile=              /* Name of file if InputUsage=C or U */,
       InputUsage=D            /* Style of input data D=dataset C=create template U=use template */,
       OptionsFile=            /* Name of file if OptionsFileUsage=C or U */,
       OptionsFileUsage=       /* Style of options file C=create U=use blank=use default settings */,
       LowPlotHeader=          /* Title for lower plot */,
       HRefLines=              /* Positions for horizontal reference lines */,
       OutThreshold=999999     /* Threshold for upper margin */,
       MarginThreshold=        /* Threshold for right-hand margin */
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
  %let XaxisLabel=%nrbquote(&XaxisLabel);
  %let YaxisLabel=%nrbquote(&YaxisLabel);
  %let BoxOffset=%nrbquote(&BoxOffset);
  %let InputFile=%nrbquote(&InputFile);
  %let InputUsage=%upcase(&InputUsage);
  %let InputUsage=%nrbquote(&InputUsage);
  %let OptionsFile=%nrbquote(&OptionsFile);
  %let OptionsFileUsage=%upcase(&OptionsFileUsage);
  %let OptionsFileUsage=%nrbquote(&OptionsFileUsage);
  %let LowPlotHeader=%nrbquote(&LowPlotHeader);
  %let HRefLines=%nrbquote(&HRefLines);
  %let OutThreshold=%nrbquote(&OutThreshold);
  %let MarginThreshold=%nrbquote(&MarginThreshold);
  
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
    
  /*--PV7 - HREFLINES: check any values specified are numeric and not in scientific notation */
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
         
  /*--PV8 - OUTTHRESHOLD: check numeric if specified */
  %if %length(%sysfunc(compbl(&OutThreshold))) > 0
  %then
    %do;
      %if %datatyp(&OutThreshold) ne NUMERIC
      %then
        %do;
            %put %str(RTE)RROR: &macroname: OutThershold value &OutThreshold is not numeric; 
            %let pv_abort = 1;          
        %end;
    %end;

  /*--PV9 - MARGINTHRESHOLD: check numeric if specified */
  %if %length(%sysfunc(compbl(&MarginThreshold))) > 0
  %then
    %do;
      %if %datatyp(&MarginThreshold) ne NUMERIC
      %then
        %do;
            %put %str(RTE)RROR: &macroname: MarginThreshold value &MarginThreshold is not numeric; 
            %let pv_abort = 1;          
        %end;
    %end;
   
  /*--PV10 - LOWPLOTHEADER: check it is not null */
  %if %length(%nrbquote(%sysfunc(compbl(&LowPlotHeader))))=0
  %then
    %do;
        %put %str(RTE)RROR: &macroname: LowPlotHeader cannot be blank;
        %let pv_abort = 1;
    %end;     
    
/*----------------------------------------------------------------------*/
  /*- complete parameter validation */
  %if %eval(&g_abort. + &pv_abort.) gt 0 %then %do;
    %put %str(RTE)RROR: &macroname: Macro has failed parameter validation check for reasons stated with %str(RTE)RRORs above;
    %tu_abort(option=force);
  %end;
  /*----------------------------------------------------------------------*/


  /*----------------------------------------------------------------------*/ 
  /*-- LM1 - Define local macro EG8_Input_Dataset */
  
  /*  Processes user-supplied input dataset */
  /* (Validation and any necessary manipulation) */
  /* We create a dataset PLOT for use in the actual graphics. */

%macro eg8_input_dataset(dsname,subjlabel);

/* Lists of variable names, by data type, and all required */
%local charvars numvars mustvars byvars;
%let charvars=trtgrp xvarlbl;
%let numvars=trtcd xvar yvar numsubjs;
%let mustvars=&charvars &numvars;
  
  /*----------------------------------------------------------------------*/ 
  /*-- LM1.1 - Validation of dataset */
  
%local pv_abort; 
%let pv_abort=0;    * tu_valparms requires this to exist;

/* Check existence of datasets */
%tu_valparms(
  abortyn=Y,
  macroname=eg8_input_dataset,
  chktype=dsetExists,
  pv_dsetin=dsname
  );
/* Check presence of variables */
%tu_valparms(
  abortyn=N,
  macroname=eg8_input_dataset,
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
        macroname=eg8_input_dataset,
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
        macroname=eg8_input_dataset,
        chktype=isNum,
        pv_dsetin=dsname,
        pv_varsin=thisvar
        );
      %let i=%eval(&i+1);
    %end;
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
  
  %global minxdif numxvals;  
  
  /* Get all the XVAR values */
  proc sql noprint;
    select count(distinct xvar) into :numxvals from &prefix._sorted;
    create table &prefix._xvars as
      select distinct xvar from &prefix._sorted 
      order by xvar;
  quit;

  /* Get the XVAR differences */  
  data &prefix._diffs;
    set &prefix._xvars;
    difx=dif(xvar);
  run;

  /* Get the largest and smallest values, and the smallest difference */
  %local xmin xmax;
  proc sql noprint;
    select min(xvar) into :xmin from &prefix._xvars;
    select max(xvar) into :xmax from &prefix._xvars;    
    select min(difx) into :minxdif from &prefix._diffs;
  quit;
  
  /* Check whether the smallest difference is really the HCF (highest common factor */
  %local nummods minxmod;
  data &prefix._xmods;
    set &prefix._xvars;
    xmod=mod((xvar-&xmin),&minxdif);
  run;
  
  proc sql noprint;
    select count(distinct xmod) into :nummods from &prefix._xmods;
  quit;
  
  %if &nummods > 1
  %then
    /* We have not yet found the MINXDIF value we seek */
    %do;
      proc sql noprint;
        select min(xmod) into :minxmod from &prefix._xmods(where=(xmod ne 0));
      quit;
      %if %sysfunc(mod(&minxdif,&minxdif)) = 0
      %then
        /* We needed a factor of MINXDIF */
        %do;
          %let minxdif=&minxmod;
        %end;
      %else
        /* Even that would not be good enough. We try again. */
        %do;
          %let minxdif=%sysfunc(mod(&minxdif,&minxdif));
          /* Even this is not guaranteed to work. */
          /* If it does not, we will fall over elegantly later on */
        %end;
    %end;

  /* Fix up the XVAR values for boxoffset */ 
  data &prefix._alldata;
    set &prefix._sorted;
    by trtcd xvar;    
    retain trtord 0;       * Ordinal number for treatment code;
    if FIRST.trtcd 
    then 
      do;
        trtord+1;
       end;
    xvaroff=xvar+((trtord-1)*&boxoffset.); * Add boxoffset to xvar;    
    * Set label for NUMSUBJS variable;
    * This is required by TU_DRAWNUMOFSUBJS utility macro ;  
        label numsubjs="&subjlabel";
  run;

/* Get lists of XVAR values and labels, for use in AXIS statement */
%global xvalues xlabels;
proc sql noprint;
  select xvar into :xvalues separated by ' ' from &prefix._xpairs;
  select xvarlbl into :xlabels separated by '|' from &prefix._xpairs;
quit;

/* Add one more before and one more after, for cosmetic reasons */
/* And another arbitrary one after, to make logic easier later! */
%global xnewmin xnewmax;
%let xnewmin=%sysevalf(&xmin-&minxdif);
%let xnewmax=%sysevalf(&xmax+&minxdif);
%let xvalues=&xnewmin &xvalues &xnewmax 999999;
%let xlabels=%str( |)&xlabels.%str(| | );

  /*----------------------------------------------------------------------*/ 
  /*-- LM1.3 - Derive dataset for use in plotting whiskers */
  
  proc sort data=&prefix._alldata out=&prefix._sortoff;
    by trtcd xvaroff;
  run;
  
  proc univariate data=&prefix._sortoff noprint;
    by trtcd trtord xvaroff;
    var yvar;
    output out=&prefix._stats q1=lowerq q3=upperq qrange=iqr min=lowest max=highest mean=mean median=median;
  run;

  %local maxtop;  
  data &prefix._bardata;
    retain maxtop;
    set &prefix._stats;
    barbot=max(lowest,lowerq-1.5*iqr);
    bartop=min(highest,upperq+1.5*iqr);
    maxtop=max(maxtop,bartop);
    call symput('maxtop',maxtop);
  run;
  
  %if %length(&OutThreshold) > 0 and %sysevalf(&maxtop ge &OutThreshold)
  %then
    %do;
      %put %str(RTE)RROR: &macroname: OutThreshold value too low - upper margin would be entangled with whiskers;
      %tu_abort(option=force);
    %end;  
  
  /*----------------------------------------------------------------------*/ 
  /*-- LM1.4 - Derive outliers datasets */
  /* UPMARGIN contains points above upper margin (if specified) */
  /* OUTLIERS contains all other outliers */
  
  data &prefix._outliers &prefix._upmargin;
    merge &prefix._sortoff &prefix._bardata;
    by trtcd xvaroff;
    if yvar > bartop or yvar < barbot;
    %if %length(&OutThreshold) > 0
    %then
      %do;
        if yvar > &OutThreshold
        then output &prefix._upmargin;
        else output &prefix._outliers;
      %end;
    %else
      %do;
        output &prefix._outliers;
      %end;
  run;
  
  %if %length(&OutThreshold) > 0 and %tu_nobs(&prefix._upmargin) = 0
  %then
    %do;
      %put %str(RTN)OTE: &macroname: No data above the specified OutThreshold value;      
    %end;
  
  proc means data=&prefix._upmargin noprint;
    by trtcd trtord xvaroff;
    output out=&prefix._upfreq n=margct;
  run;
    
  /*----------------------------------------------------------------------*/ 
  /*-- LM1.5 - Derive some useful data-dependent macro variables */

%global numtrts;        * Number of different treatments;
%global numticks;       * Number of different X-axis values;
%global x_order;    * ORDER statement for inclusion in an AXIS statement for X-axis;
%global y_order;    * ORDER statement for inclusion in an AXIS statement for Y-axis;
%local trtlist trouble;

  proc sql noprint;
    select count(distinct trtgrp) into :numtrts from &prefix._alldata;
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

   /* y-axis is non-trivial */
   /* We have to worry about a possible OutMargin value */
   /* (Though what really matters is whether any data exceeded it) */
   /* We also set up Y_OFFSET */
   %global y_offset;
   %local default_upper_margin_offset;
   %let default_upper_margin_offset=12;   /* Percentage of plot area */
   %if %tu_nobs(&prefix._upmargin) > 0
   %then
     %do;
       data &prefix._upaxis;
         set &prefix._alldata(where=(yvar le &OutThreshold));
       run;
       %tu_order(macrovar=y_order
                ,dsetin=&prefix._upaxis
                ,varlist=yvar
                ,minvalue=
                ,maxvalue=&OutThreshold
                );
     %let y_offset=offset=(,&default_upper_margin_offset PCT);       
     %end;
   %else
     %do;
       %tu_order(macrovar=y_order
                ,dsetin=&prefix._alldata
                ,varlist=yvar
                ,minvalue=
                ,maxvalue=
                );
     %let y_offset=offset=(,0 PCT);
     %end;
             
    /* x-axis is more challenging. We include both the ORDER clause and the VALUE/TICK stuff */
    
    %let x_order=order=(&xnewmin to &xnewmax by &minxdif);
    %let x_order=%sysfunc(compbl(&x_order));
    
    %local thistick numvals nextval j;
    %let numticks=%sysevalf(1+((&xnewmax-&xnewmin)/&minxdif));
    %let numvals=%eval(&numxvals+2);       /* Since we added one fore and one aft */
    %let nextval=1;                        /* Next XVAL to be ticked */
    %let thistick=&xnewmin;                /* Value corresponding to current tick */
    %do j=1 %to &numticks;
      %global xtick&j tkyn&j;
      %if %sysevalf(%scan(&xvalues,&nextval,%str( )) = &thistick)
      %then
        %do;
          %let xtick&j=%str( )tick=&j %str(%')%trim(%scan(&xlabels,&nextval,%str(|)))%str(%');
          %let tkyn&j=Y;   /* We do want a tick mark here */
          %let nextval=%eval(&nextval+1);
        %end;
      %else
        %do;
          %let xtick&j=%str( )tick=&j %str(%'%');
          %let tkyn&j=N;   /* We do not want a tick mark here */
        %end;
      %let thistick=%sysevalf(&thistick+&minxdif);
    %end;
    
    %if &nextval < %eval(&numvals+1)
    %then
      %do;
        %put %str(RTW)ARNING: &macroname: XVAR values irregularly spaced, so could not all be labelled; 
      %end;
             
%mend eg8_input_dataset;

  /*----------------------------------------------------------------------*/ 
  /*-- LM2 - Define local macro EG8_Write_template */
 
   /* Provides user with a SAS code template for the required input dataset */

%macro eg8_write_template(fnam);

/* NB All quotes to be generated must be preceded by "%", whether matched or not. */

data _null_;
  file &fnam;

%tu_cr8proghead(macname=create_eg8_example_dataset, macdesign=SAS_datastep_not_a_macro);
* Second param above is not validated but cannot be more than one word, apparently;

put " ";
put "%nrstr(data work.eg8_example_dataset;)";
put "%nrstr(* Data set must include at least these 6 variables;)";
put "%nrstr(* Records with the same XVAR value must have the same XVARLBL value;)"; 
put "%nrstr(  attrib)";
put "%nrstr(    trtgrp   length=$120 label=%"Treatment label to appear in the legend%")";
put "%nrstr(    trtcd    length=8    label=%"Treatment code to order the legend%")";
put "%nrstr(    xvar     length=8    label=%"Variable to be plotted against X-axis%")";
put "%nrstr(    xvarlbl  length=$120 label=%"Text corresponding to XVAR value%")";
put "%nrstr(    yvar     length=8    label=%"Variable to be plotted against Y-axis%")";
put "%nrstr(    numsubjs length=8    label=%"Average number of subjects at risk%")";
put "%nrstr(  ;)"; 
put "%nrstr(run;)";

run;

%mend eg8_write_template;

  /*----------------------------------------------------------------------*/ 
  /*-- LM3 - Define local macro EG8_Use_template */

  /* Uses an input template for the input dataset */

%macro eg8_use_template(filespec);

  %global tmp_dset;

  %include "&filespec";

  %let tmp_dset=&syslast;       * Save name of dataset just created;

%mend eg8_use_template;

  /*----------------------------------------------------------------------*/ 
  /*-- LM4 - Define local macro EG8_Write_Options */

   /* Provides user with source code for standard graphics options  */
   /* (data dependent) */

%macro eg8_write_options(fnam);

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

%tu_cr8proghead(macname=eg8_graphics_options, macdesign=SAS_code_not_a_macro);
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
put "/" "%nrstr(* OFFSET option %(if present%) reserves space for the %"upper margin%", *)" "/";
put "/" "%nrstr(* which may be required when you specify the OUTTHRESHOLD parameter. *)" "/";
put "/" "%nrstr(* You may alter the OFFSET value, but the units must remain %"PCT%". *)" "/";
put "%nrstr(axis1 c=black width=2 )" " &y_offset &y_order " 
"%nrstr(label=%(angle=90 h=12pt %")"
%if %length(%nrbquote(%sysfunc(compbl(&YAxisLabel)))) > 0
%then
  %do; 
    "&YAxisLabel"
  %end; 
"%nrstr(%"%);)";
put "/" "%nrstr(* Do NOT alter the x-axis ORDER option, or %"major=none minor=none%". *)" "/";
put "/" "%nrstr(* Tick marks are generated as annotations, and their positions are determined by the data. *)" "/";
put "/" "%nrstr(* You may alter the axis label, tick mark labels, axis colour and line width, etc. *)" "/";
put "%nrstr(axis2 c=black width=2)" " &x_order " "%nrstr(major=none minor=none label=%(h=12pt %")" 
%if %length(%nrbquote(%sysfunc(compbl(&XAxisLabel)))) > 0
%then
  %do; 
    "&XAxisLabel"
  %end; 
"%nrstr(%"%) value=%(h=12pt )"
%do i=1 %to &numticks;
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

%mend eg8_write_options;

  /*----------------------------------------------------------------------*/ 
  /*-- LM5 - Define local macro EG8_Graphics */

  /* Generates graphics, using the specified graphics options file */


%macro eg8_graphics(filespec);

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
  
/* Macro variables for formatting of upper margin region */
  %local um_textsize um_numsize um_textlen;  
  %let um_textsize=1.8;    /* Size of text for UM axis labels */
  %let um_numsize=2;       /* Size of text for plotted numbers */
  %let um_textlen=14;      /* Maximum length of UM axis labels */

/* Macro variable for formatting of the box */
  %local radius;         /* Radius of circles at mean (in % of graphics area) */
  %let radius=0.2;
    
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
/* (BARCOLS probably not actually used by EG8) */
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
  /*-- LM5.4 - Create annotate dataset for Number of subjects table */
  
%tu_drawnumofsubjs(
   COLORLIST        = &colstr
  ,COMPAREVAR       = trtcd
  ,COMPAREVARDECODE = trtgrp
  ,DSETIN           = &prefix._alldata
  ,DSETOUTANNO      = &prefix._subjsanno
  ,FORMATS          =
  ,FRAMEOPTION      =
  ,FRAMEYN          = N
  ,HAXISDSET        = 
  ,HAXISNAME        = 
  ,HVAR             = xvar
  ,LABELS           = 
  ,ROWSPACE         = 0.2
  ,SUBJCOUNTVAR     = numsubjs
  ,TEXTOPTION       = 
  ,VAXISYN          = N
  ,UNDERLINEYN      = N
   );
   
  /*----------------------------------------------------------------------*/ 
  /*-- LM5.5 - Create annotate dataset for upper margin, if required */
  
  %local ourfont;
  %let ourfont=%sysfunc(getoption(ftext));

  %if %tu_nobs(&prefix._upmargin) > 0         /* If there is upper margin data to plot */
  %then
    %do;  
  /*----------------------------------------------------------------------*/ 
  /*-- LM5.5.1 - Get value of UMPCT - percentage of plot area available for upper margin */
  
      %tu_getgstatements(
         dsetout=&prefix._axisinfo,
         statements=AXIS
         );
  
      data _null_;
      * Not much validation here. SAS has already executed the AXIS statement, ;
      * so it must be syntactically valid);
        set &prefix._axisinfo(where=(name='AXIS1'));
        length offmsg $80;
        text=upcase(text);                         * Better safe than sorry ;
        offsetpos=index(text,'OFFSET');            * Locate 'OFFSET' ;
        if offsetpos = 0
        then offmsg='Axis statement specifies no OFFSET';
        else
          do;
            offsetstr=substr(text,offsetpos);
            bktpos=index(offsetstr,"%nrstr(%))");  * Locate ')';
            offsetstr=substr(offsetstr,1,bktpos);
            commapos=index(offsetstr,"%nrstr(,)"); * Locate comma ;
            if commapos = 0
            then offmsg='Axis OFFSET specification needs a comma';
            * Could be valid without - specifying offset at bottom of axis - ;
            * but this would be no use to us;
            else
              do;
                offsetstr=substr(offsetstr,commapos+1);
                offunit=scan(offsetstr,2);         * The units it is expressed in ;
                if offunit ne 'PCT'
                then
                  offmsg='Axis OFFSET units must be explicitly PCT';
                else
                  do;
                    umpct=scan(offsetstr,1);      * The number we need ;
                    if umpct <= 0 or umpct >= 100
                    then
                      offmsg='Axis OFFSET must be between 0 and 100';
                    else
                      call symput('umpct',umpct);
                  end;
              end;
          end;
          call symput('offmsg',offmsg);
      run;   
    
      %if %length(&offmsg) > 0
      %then
        %do;
          %put %str(RTE)RROR: &macroname: &offmsg;
          %tu_abort(option=force);
        %end;
      %else
        %do;
  /*----------------------------------------------------------------------*/ 
  /*-- LM5.5.2 - With UMPCT known, generate annotations for upper margin */
     
          %annomac;   /* Declare ANNOTATE macros */

          %if %tu_nobs(&prefix._upfreq) > 0
          %then
            %do;
              data &prefix._topanno;
                %dclanno;
                length text $&um_textlen;     * Length can be modified in user-supplied options file;
                length thiscol $16;
                set &prefix._upfreq;
                if _N_=1
                then
                  do;
                    * Draw lower boundary line of top margin area;
                    %system(1,1,4); * X and Y: % of data area (absolute);
                    %move(0,100-&umpct);
                    %draw(100,100-&umpct,BLACK,1,2);
                    * Draw tick marks and labels for top margin;
                    %do i=1 %to &numtrts;
                      %system(1,1,4); * X and Y: % of data area (absolute);
                      y=100 - &umpct.*((&i/(1+&numtrts.)));
                      %move(0,y);
                      %draw(-0.5,y,BLACK,1,2);
                      %system(5,1,3);
                      size=&um_textsize;      * Text size can be modified in user-supplied options file;
                      color='BLACK';
                      text= right(">&OutThreshold., &&&trtnam&i.");
                      position='6';
                      function='LABEL';
                      x=0;
                      output;
                    %end;
                  end;
                    * Now plot the numbers;
                %system(2,1,3);     * X: data values, Y: % of data area (absolute) ;
                * Curiously, "data area" is defined to include the axis offsets;
                x=xvaroff;
                y=100 - &umpct.*((trtord/(1+&numtrts.)));
                text=left(put(margct,best6.));
*                color=scan("&colstr",trtcd);
                color=scan("&colstr",trtord);
                function='LABEL';
                style="&ourfont";
                size=&um_numsize;             * Text size can be modified in user-supplied options file;
                output;
              run;
            %end;
        %end;
    %end;
    
  /*----------------------------------------------------------------------*/ 
  /*-- LM5.6 - Generate Annotate dataset for the boxes and whiskers */
    %local halfbox;        /* Width of boxes will be two-thirds of BoxOffSet */
    %let halfbox=%sysevalf(&BoxOffset/3);
     
    %annomac;   /* Declare ANNOTATE macros */

    data &prefix._boxanno;
      %dclanno;
      length text $8;
*      set &prefix._stats;
      set &prefix._bardata;
      %system(2,2,4);     * X and Y: data values ;
      colourlist=compbl("&colstr");
*      color=scan(colourlist,trtcd);
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
*      y=upperq+1.5*iqr;
      y=bartop;
      function='DRAW';
      output;
      %move(xvaroff,lowerq);
*      y=lowerq-1.5*iqr;
      y=barbot;
      function='DRAW';
      output;
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
  /*-- LM5.7 - Generate Annotate dataset for x-axis tickmarks  */
  
  /* AXIS statement deliberately specifies no ticks (major=none minor=none) */
  /* The only tickmarks that appear on this axis are those generated here */  
    data &prefix._tickanno;
      %dclanno;
      length text $8;
      %local thistick numvals nextval j;
      %let numticks=%sysevalf(1+((&xnewmax-&xnewmin)/&minxdif));
      %let numvals=%eval(&numxvals+2);       /* Since we added one fore and one aft */
      %let nextval=1;                        /* Next XVAL to be ticked */
      %let thistick=%sysevalf(&xnewmin + &minxdif); /* Value corresponding to current tick */
      %do j=2 %to %eval(&numticks-1);        /* Omit beginning and end of axis */
        %if &&&tkyn&j = Y                    /* If this tickmark wanted */
        %then
          %do;
            %system(2,1,4);     * X: data values, Y: %data area;
            %move(&thistick,0);
            ysys=9;   /* % graphics area, relative */
            y=-1;
            color="BLACK";
            size=2;
            style=1;
            when='A';                        /* Must overwrite existing tickmark */
            function="DRAW";        
            output;
          %end;
        %let thistick=%sysevalf(&thistick+&minxdif);
      %end;
    run;
    
  /*----------------------------------------------------------------------*/ 
  /*-- LM5.8 - Concatenate all annotations */
  
data &prefix._allanno;
  set &prefix._subjsanno
      &prefix._boxanno 
    %if %tu_nobs(&prefix._upmargin) > 0
    %then
      %do;
      &prefix._topanno
      %end; 
      &prefix._tickanno;
run;

  /*----------------------------------------------------------------------*/ 
  /*-- LM5.9 - Generate options string for reference lines */

  /* Beware possible confusion here! */
  /* This macros parameter HRefLines refers to reference lines that run horizontally */
  /* But GPLOT options HREF, CHREF, LHREF relate to lines PERPENDICULAR TO horizontal axis */
  /* Similarly with "vertical" parameter and options */
  %local reflines;
  %let reflines=;
  %if %length(%nrbquote(%sysfunc(compbl(&HRefLines)))) > 0
  %then
    %do;
      %let reflines=cvref=green lvref=20 vref=&HRefLines ;
      /* Oddly, some line styles do not come out as advertised. 34 is recommended here */ 
    %end;
  %if %length(&MarginThreshold) > 0
  %then
    %do;
      %let reflines=&reflines chref=black lhref=1 href=&MarginThreshold ;
    %end;  


  /*----------------------------------------------------------------------*/ 
  /*-- ib.02.001 - Append scatterplot (outliers) dataset with all possible TRTCDs */
  /*--             so that the legend is created containing all treatments */

%macro addtmtleg(dset=);

proc freq data=&InputDataset noprint;
  tables trtcd /out=_tmts(keep=trtcd);
run;

data  &dset;
set &dset _tmts;
run;

%mend addtmtleg;

%addtmtleg(dset=&prefix._outliers);

  /*----------------------------------------------------------------------*/ 
  /*-- LM5.10 - Generate scatter plot of outliers (with everything else as annotations) */
 
proc gplot data=work.&prefix._outliers annotate=&prefix._allanno gout=graph_cat;
      plot yvar * xvaroff=trtcd
    / haxis=axis2 vaxis=axis1 legend=legend1 &reflines name="outliers";
run;
quit;

  
    /*----------------------------------------------------------------------*/ 
  /*-- LM5.11 - Generate plot header and footer as GSLIDE graphics */

%tu_cr8gheadfoots(gout    = graph_cat_hf,
                  kill    = y,
                  pagecat = graph_cat,
                  font    = &ourfont,
                  ptsize  = 8);

  /*----------------------------------------------------------------------*/ 
  /*-- LM5.12 - Put it all together - main plot plus GSLIDE */

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
  /*-- LM5.13 -  Convert PostScript file to PDF using utility ps2pdf (if available) */
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

%mend eg8_graphics;

/************************************************************************/
/* Finally the rest of the main macro TD_EG8                           */
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
      %eg8_write_template(usr_prof);
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
        %eg8_use_template(&InputFile); 
        %put %str(RTN)OTE: &macroname: Finished execution of user-supplied SAS code (dataset creation);
        /* Dataset name returned in macrovar tmp_dset */ 
        %eg8_input_dataset(&tmp_dset,&LowPlotHeader);
      %end;
    %else 
      %do;
        %eg8_input_dataset(&InputDataset,&LowPlotHeader); 
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
        %eg8_write_options(&writopts);
      %end;

  /*----------------------------------------------------------------------*/ 
  /*-- NP9 - Read options file and generate graphics if we need to */
    %if %length(&readopts) > 0 
    %then
      %do;
        %eg8_graphics(&readopts);          
      %end;
%end;

  /*----------------------------------------------------------------------*/
  /*--NP10 - Tidy up and call tu_abort   */
  
  %tu_tidyup(rmdset=&prefix:, glbmac=NONE);
  %tu_abort;

%mend td_eg8;
