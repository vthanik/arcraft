/*******************************************************************************
|
| Macro Name:      td_lb7
|
| Macro Version:   1 build 5
|
| SAS Version:     8.2
|                                                             
| Created By:      Bob Newman (Amadeus) 
|
| Date:            20 November 2006
|
| Macro Purpose:   To generate an LB7 plot
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
|  XaxisLabel       Label for X-axis                                 OPT      Baseline
|  YaxisLabel       Label for Y-axis                                 OPT      Maximum
|  RefLines         Values for reference lines                       OPT      [BLANK] 
|  PlotsPerPage     Number of profiles per page - 1, 2, 3 or 4       REQ      4
|  LogBase          Log base for y-axis - 2, 10 or 0 (=linear)       OPT      [BLANK]
|                   or 1 (=linear in integers)
|
| Global macro variables created: 
|   NONE
| 
| Macros called: 
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_cr8gheadfoots
| (@) tu_cr8proghead
| (@) tu_order
| (@) tu_orderlog
| (@) tu_nobs
| (@) tu_putglobals
| (@) tu_tidyup
| (@) tu_valparms
|
| Example:
| %td_lb7(InputDataset=myplot
|   , InputUsage=D
|  );
|
|******************************************************************************
| Change Log
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     20-Nov-06
| New version/draft number: 01.001
| Modification ID:          RCN.01.001
| Reason For Modification:  Original version
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     15-Dec-06
| New version/draft number: 01.002
| Modification ID:          RCN.01.002
| Reason For Modification:  Correct default axis labels.
|                           Altered Y-axis definitions to allow for possibility of blank label.
|                           Eliminate check for duplicates at LM1.1.
|                           At NP7, reverted to standard code for InputUsage=U (had inherited non-standard code from LB11!).
|                           Extra step at end of LM1.2 to exclude data for unplotted lab params from axis range calculations.
|                           Altered meaning of HALFGAP - we now have a "double half-gap" at each end of the composite axis.
|                           (This reduces the chances of "blurred" numbers on the y-axis due to overlaid plots not coinciding
|                           properly when the x-axis numbers run to several figures.)
|                           Introduced SCALE (undocumented parameter), to permit tweaking when too many headers/footnotes.
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     22-Jan-07
| New version/draft number: 01.003
| Modification ID:          RCN.01.003
| Reason For Modification:  Standardise on 2 user-defined titles and 2 user-defined footnotes.
|                           Altered values of certain macro variables accordingly.
|
| Modified By:              Ian Barretto
| Date of Modification:     25-Jan-07
| New version/draft number: 01.004
| Modification ID:          n/a
| Reason For Modification:  Removed hanging comma from macro call after Logbase parameter
|
| Modified By:              Ian Barretto
| Date of Modification:     15-Feb-07
| New version/draft number: 01.005
| Modification ID:          n/a
| Reason For Modification:  Removed tu_chkdups from header and added tu_nobs
*******************************************************************************/
  
%macro td_lb7
      (
       InputDataset=                               /* type:ID Input dataset */,
       InputFile=                                  /* Name of file if InputUsage=C or U */,
       InputUsage=D                                /* Style of input data D=dataset C=create template U=use template */,
       OptionsFile=                                /* Name of file if OptionsFileUsage=C or U */,
       OptionsFileUsage=                           /* Style of options file C=create U=use blank=use default settings */,
       XAxisLabel=Baseline                         /* Horizontal axis label */,
       YAxisLabel=Maximum                          /* Vertical axis label */,
       RefLines=                                   /* Position of reference lines (data values) */,
       PlotsPerPage=4                              /* Plots per page (1, 2, 3 or 4) */,
       LogBase=1                                   /* Log base for y-axis (2 or 10, or 1 for a linear axis in integers) */);

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
  %let XaxisLabel=%nrbquote(&XaxisLabel);
  %let YaxisLabel=%nrbquote(&YaxisLabel);
  %let InputFile=%nrbquote(&InputFile);
  %let InputUsage=%upcase(&InputUsage);
  %let InputUsage=%nrbquote(&InputUsage);
  %let OptionsFile=%nrbquote(&OptionsFile);
  %let OptionsFileUsage=%upcase(&OptionsFileUsage);
  %let OptionsFileUsage=%nrbquote(&OptionsFileUsage);
  %let RefLines=%nrbquote(&RefLines);
  %let Reflines=%nrbquote(%sysfunc(tranwrd(&RefLines,%str(/),%str(/ ))));
  %let PlotsPerPage=%nrbquote(&PlotsPerPage);
  %let LogBase=%nrbquote(&LogBase);
    
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
  /* NB Must be specified when InputUsage=U - this is different from most plot macros, because of treatment DS */
  
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
    
  /*--PV6 - REFLINES: check any values specified are numeric */
  /* Scientific notation is acceptable here (since PROC GPLOT is not going to see these values) */
  /* While we valid it, we create the REF dataset */
          data &prefix._ref;
          length xnum 8 ref $120;
  %local slashless slashcount i thisval thisvalOK;
  %if %length(%sysfunc(compbl(&RefLines))) > 0
  %then
    %do;
      /* Count number of slashes in string */
      %let slashless=%nrbquote(%sysfunc(compress(&RefLines,%str(/))));
      %let slashcount=%eval(%length(&RefLines) - %length(&slashless));
      %local HRefErr;
      %let HRefErr=0;
      %if &slashcount < 2
      %then
        %do;
          %put %str(RTE)RROR: &macroname: RefLines specifications must be delimited using '/' character;
          %let pv_abort = 1;
          %let HRefErr=1;          
        %end;
      %if %quote(%substr(&RefLines,1,1)) ne %str(/)
        %then
          %do;
            %put %str(RTE)RROR: &macroname: RefLines specification must begin with a '/' character;
            %let pv_abort = 1;
            %let HRefErr=1;          
          %end;
        %if %quote(%substr(&RefLines,%length(%qtrim(&RefLines)),1)) ne %str(/)
        %then
          %do;
            %put %str(RTE)RROR: &macroname: RefLines specification must end with a '/' character;
            %let pv_abort = 1;
            %let HRefErr=1;          
          %end;
      %if &HRefErr=0
      %then
        %do;
          %do i=1 %to %eval(&slashcount-1);
            %let thisval=%nrbquote(%sysfunc(compbl(%qscan(&RefLines,&i,%str(/)))));
            /* THISVAL should be a space-separated list of numbers */          
            %if %length (&thisval) > 0 
            %then
              %do;
                %let thisvalOK=Y;
                %if %length(%nrbquote(%sysfunc(compbl(&RefLines)))) > 0
                %then
                  %do;
                    %let j=1;
                    %do %while (%length(%qscan(&thisval,&j,%str( ))) > 0);
                    /* Space is the only delimiter we recognise here */
                      %let thisnum=%qscan(&thisval,&j,%str( ));
                      %if %datatyp(&thisnum) ne NUMERIC
                      %then
                        %do;
                          %put %str(RTE)RROR: &macroname: RefLines value &thisnum is not numeric;   
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
                    ref="&thisval";
                    output;
                  %end;
              %end;
          %end;
        %end;
    %end;
          run;
          
  /*--PV7 - PLOTS PER PAGE: check it is 1, 2, 3 or 4 */
  %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = PlotsPerPage, valuelist = 1 2 3 4, abortyn = N);

  /*--PV8 - LOGBASE: check it is 0 or 2 or 10 */
   %if %length(%nrbquote(%sysfunc(compbl(&logbase)))) = 0
   %then
     %do;
       %let logbase=0;
       %put %str(RTN)OTE: &macroname: LogBase not specified - setting to 0 and using linear x-axis;
     %end;
   %else
     %do;
       %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = LogBase, valuelist = 0 1 2 10, abortyn = N);
     %end;
 
 /*----------------------------------------------------------------------*/
  /*- complete parameter validation */
  %if %eval(&g_abort. + &pv_abort.) gt 0 %then %do;
    %put %str(RTE)RROR: &macroname: Macro has failed parameter validation check for reasons stated with %str(RTE)RRORs above;
    %tu_abort(option=force);
  %end;
  
  %if %length(%sysfunc(compbl(&RefLines))) > 0
  %then
    %do;
      %if %tu_nobs(&prefix._ref) > &PlotsPerPage
      %then
        %do;
          %put %str(RTN)OTE: &macroname: More sets of reference lines specified than plots;
        %end;
      %if %tu_nobs(&prefix._ref) < &PlotsPerPage
      %then
        %do;
          %put %str(RTN)OTE: &macroname: Fewer sets of reference lines specified than plots;
        %end;
    %end;
  /*----------------------------------------------------------------------*/

  /*----------------------------------------------------------------------*/ 
  /*-- LM1 - Define local macro LB7_Input_Dataset */
  
  /*  Processes user-supplied input dataset */
  /* (Validation and any necessary manipulation) */
  /* We create a dataset PLOT for use in the actual graphics. */

%macro lb7_input_dataset(dsname);

/* Lists of variable names, by data type, and all required */
%local charvars numvars mustvars byvars;
%let charvars=trtgrp param;
%let numvars=trtcd paramcd subjid xvar yvar; 
%let mustvars=&charvars &numvars;
  
  /*----------------------------------------------------------------------*/ 
  /*-- LM1.1 - Validation of dataset */
  
%local pv_abort; 
%let pv_abort=0;

/* Check existence of datasets */
%tu_valparms(
  abortyn=Y,
  macroname=lb7_input_dataset,
  chktype=dsetExists,
  pv_dsetin=dsname
  );
/* Check presence of variables */
%tu_valparms(
  abortyn=N,
  macroname=lb7_input_dataset,
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
        macroname=lb7_input_dataset,
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
        macroname=lb7_input_dataset,
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
  /*-- LM1.2 - Generate plot datasets */

  /* Create a table of the PARAM/PARAMCD pairs */
  %local pairct paramct pcdct;  
  proc sql noprint;
    create table &prefix._params as
      select param, paramcd, count(*) as freq
        from &dsname
        group by param, paramcd
        order by paramcd;
    select count(*) into :pairct from &prefix._params;
    select count(distinct param) into :paramct from &prefix._params;
    select count(distinct paramcd) into :pcdct from &prefix._params;
  quit;
  
  %if &pairct ne &paramct or &pairct ne &pcdct
  %then
    %do;
      %put %str(RTE)RROR: &macroname: Inconsistent PARAM/PARAMCD pairings;
      %tu_abort(option=force);
    %end;

  %if &paramct > 4 
  %then
    %do;
      %put %str(RTE)RROR: &macroname: Data found for more than 4 laboratory parameters;
      %tu_abort(option=force);
    %end;

  %if &paramct < &PlotsPerPage 
  %then
    %do;
      %put %str(RTW)ARNING: &macroname: Not enough laboratory parameters for number of plots requested. Some will be blank.;
    %end;

  %if &paramct > &PlotsPerPage 
  %then
    %do;
      %put %str(RTN)OTE: &macroname: Plot excludes one or more laboratory parameters for which data exists;
    %end;

  /* Create a table of the TRTGRP/TRTCD pairs */
  %local tpairct trtct trtcdct;  
  proc sql noprint;
    create table &prefix._trts as
      select trtgrp, trtcd, count(*) as freq
        from &dsname
        group by trtgrp, trtcd
        order by trtcd;
    select count(*) into :tpairct from &prefix._trts;
    select count(distinct trtgrp) into :trtct from &prefix._trts;
    select count(distinct trtcd) into :trtcdct from &prefix._trts;
  quit;
  
  %if &tpairct ne &trtct or &tpairct ne &trtcdct
  %then
    %do;
      %put %str(RTE)RROR: &macroname: Inconsistent TRTGRP/TRTCD pairings;
      %tu_abort(option=force);
    %end;

  /* Create a table of all combinations of parameter and treatment group */   
  proc sql noprint;
    create table &prefix._cartesian as
      select param, paramcd, trtgrp, trtcd
        from &prefix._params, &prefix._trts;
  quit;
  
  /* Create a dummy record for each possible combination of subject and lab parameter */
  data &prefix._gimmick;
    set &prefix._cartesian;
    xvar=.;
    yvar=.;
  run;
  
  /* Append this to the main dataset and sort.
     This will ensure use of symbols is consistent even for lab params where not all treatment groups have data */
  data &prefix._full;
    set &dsname &prefix._gimmick;
  run;
  
  proc sort data=&prefix._full out=&prefix._sorted;
    by paramcd trtcd;
  run;    

/* Create dataset with ordinals for both parameter and treatment codes */ 
  
  data &prefix._ord;
    set &prefix._sorted;
    by paramcd trtcd;    
    retain paramord 0;
    retain trtord 0;
    if first.paramcd
    then
      do;
        paramord+1;
        trtord=0;
      end;
    if FIRST.trtcd
    then
      do;
        trtord+1;
      end;  
  run;

/* Exclude data that we wont be plotting, so that it is not involved in calculating axis ranges */  
  data &prefix._plot;
    set &prefix._ord(where=(paramord le &PlotsPerPage));
  run;
  
  /*----------------------------------------------------------------------*/ 
  /*-- LM1.3 - Derive some useful data-dependent macro variables */

%global numtrts;	* Number of different treatments;
%global numparms;	* Number of different parameters;
%global x_order;    * ORDER statement for inclusion in an AXIS statement for X-axis;
%global y_order;    * ORDER statement for inclusion in an AXIS statement for Y-axis;
%local trouble trtlist;
%global parmlist;

  %let numtrts=&trtct;
  %let numparms=&paramct;
  proc sql noprint;
	select count(*) into :trouble from &prefix._trts
	  where trtgrp like "%|%";
	select count(*) into :ptrouble from &prefix._params
	  where param like "%|%";
	select trtgrp into :trtlist separated by "|" from &prefix._trts;
    select param into :parmlist separated by "|" from &prefix._params;
  quit;

%if &trouble > 0
%then
  %do;
    %put %str(RTW)ARNING: &macroname: "|" character found in treatment labels - check legend;
  %end;

%if &ptrouble > 0
%then
  %do;
    %put %str(RTW)ARNING: &macroname: "|" character found in parameter labels - check titles;
  %end;

  /*----------------------------------------------------------------------*/ 
  /*-- LM1.4 Derive macro variables containing LEGEND strings */

%local legvalue i thistrt;
%let legvalue=;
%do i=1 %to &numtrts;
  /* Have one LEGVAL var per parameter - one big string might get too long*/
  %let thistrt=%scan(&trtlist,&i,|);
  /* We truncate each treatment label at 60. A few more characters are possible, but not many. */
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

%if &logbase=0 
%then
  %do;
    %tu_order(macrovar=xy_order
             ,dsetin=&prefix._plot
             ,varlist=xvar yvar
             );
   %end;
%else %if &logbase=1
%then
  %do;
    %local xmin ymin xymin xmax ymax xymax;
    %global xy_order;
    proc sql noprint;
      select floor(min(xvar)) into :xmin from &prefix._plot;
      select ceil(max(xvar)) into :xmax from &prefix._plot;                                                   
      select floor(min(yvar)) into :ymin from &prefix._plot;
      select ceil(max(yvar)) into :ymax from &prefix._plot;
    quit;
    %let xymin=%sysfunc(min(&xmin,&ymin));
    %let xymax=%sysfunc(max(&xmax,&ymax));
    %let xy_order=order=(&xymin to &xymax by 1);
  %end;
%else
  %do;
    %tu_orderlog(macrovar=xy_order
                ,dsetin=&prefix._plot
                ,varlist=xvar yvar
                ,logbase=&logbase
                );
   %end;
  /*----------------------------------------------------------------------*/ 
  /*-- LM1.6 - Parse ORDER clauses to extract axis limits */
  /* This step would be unnecessary if TU_ORDER etc were modified to return the values we need
     (when annotating with plot-specific reference lines) but administrative procedures
     prevent this from being done. */
  
  %global axismin axismax;
  %local orderstr orderpos;
  /* First get rid of the pesky brackets */
  %let orderstr=%upcase(%sysfunc(compress(&xy_order,%nrstr(%(%)))));   
  /* NB Macro function %index is no use to us here */
  %let orderpos=%sysfunc(index(&orderstr,ORDER));
  %let orderstr=%substr(&orderstr, %eval(&orderpos+6));
  %let axismin=%scan(&orderstr,1,%str( ));
  %if &logbase > 1
  %then
    %do;
      /* Logarithmic axis - we want the last word in the string */
      %let orderstr=%sysfunc(reverse(&orderstr));
      %let axismax=%scan(&orderstr,1,%str( ));
      %let axismax=%sysfunc(reverse(&axismax));
    %end;
  %else
    %do;
      /* Linear axis - we want the third word in the string */
      %let axismax=%scan(&orderstr,3,%str( ));
    %end;
 
%mend lb7_input_dataset;

  /*----------------------------------------------------------------------*/ 
  /*-- LM2 - Define local macro LB7_Write_template */
 
   /* Provides user with a SAS code template for the required input dataset */

%macro lb7_write_template(fnam);

/* NB All quotes to be generated must be preceded by "%", whether matched or not. */

data _null_;
  file &fnam;

%tu_cr8proghead(macname=create_lb7_example_dataset, macdesign=SAS_datastep_not_a_macro);
* Second param above is not validated but cannot be more than one word, apparently;

put " ";
put "%nrstr(data work.lb7_example_dataset;)";
put "%nrstr(* Data set must include at least these 7 variables;)";
put "%nrstr(  attrib)";
put "%nrstr(    trtgrp   length=$120 label=%"Treatment group label to appear in the legend%")";
put "%nrstr(    trtcd    length=8    label=%"Treatment code to order the legend%")";
put "%nrstr(    param    length=$120 label=%"Laboratory parameter label to appear in the title%")";
put "%nrstr(    paramcd  length=8    label=%"Laboratory parameter code to order the plots%")";
put "%nrstr(    subjid   length=8    label=%"Subject number%")";
put "%nrstr(    xvar     length=8    label=%"Variable to be plotted against X-axis e.g. Maximum (/ULN)%")";
put "%nrstr(    yvar     length=8    label=%"Variable to be plotted against Y-axis e.g. LFT value%")";
put "%nrstr(  ;)"; 
put "%nrstr(run;)";

run;

%mend lb7_write_template;

  /*----------------------------------------------------------------------*/ 
  /*-- LM3 - Define local macro LB7_Use_template */

  /* Uses an input template for the input dataset */

%macro lb7_use_template(filespec);

  %global tmp_dset;

  %include "&filespec";

  %let tmp_dset=&syslast;       * Save name of dataset just created;

%mend lb7_use_template;

  /*----------------------------------------------------------------------*/ 
  /*-- LM4 - Define local macro LB7_Write_Options */

   /* Provides user with source code for standard graphics options  */
   /* (data dependent) */

%macro lb7_write_options(fnam);

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

%tu_cr8proghead(macname=lb7_graphics_options, macdesign=SAS_code_not_a_macro);
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

%let titlesize=4 pct;    /* For PlotsPerPage=1 or 2 */
%if &PlotsPerPage=3 %then %let titlesize=6 pct;
%if &PlotsPerPage=4 %then %let titlesize=8 pct;
  
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
put "%nrstr(  htitle  = )" "&titlesize";
put "%nrstr(;)";
put " ";

  /*----------------------------------------------------------------------*/ 
  /*-- LM4.4 - Generate LEGEND statement */

put "/" "%nrstr(* Specify the legend *)" "/";
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

  /*----------------------------------------------------------------------*/ 
  /*-- LM4.5 - Generate AXIS statements */
  /* Same ORDER clause is used for both X and Y axes */
  
%let yfontsize=18pt;
%if &PlotsPerPage=3 %then %let yfontsize=24pt;
%if &PlotsPerPage=4 %then %let yfontsize=32pt;

%let figsize=12pt;
%if &PlotsPerPage=3 %then %let figsize=20pt;
%if &PlotsPerPage=4 %then %let figsize=24pt;

  /*----------------------------------------------------------------------*/ 
  /*-- LM4.5.1 - Generate AXIS statements for 4-plot case */
%if &PlotsPerPage=4
%then
  %do;

%local fontsize_4 figsize_4;

%let fontsize_4=12pt;       * Size of font for axis label (parameter name);
%let figsize_4=6pt;         * Size of font for tickmark figures;

%let length_4=%sysevalf(4*&axissize_4 + 10*&halfgap_4);
%let length_4y=%sysevalf(&axissize_4 + 4*&halfgap_4);

%let offset_4y=length=&length_4y in offset=(%sysevalf(2*&halfgap_4) in, %sysevalf(2*&halfgap_4) in);
%let offset_41=length=&length_4 in offset=(%sysevalf(2*&halfgap_4) in,%sysevalf(3*&axissize_4+8*&halfgap_4) in);
%let offset_42=length=&length_4 in offset=(%sysevalf(&axissize_4+4*&halfgap_4) in, %sysevalf(2*&axissize_4+6*&halfgap_4) in);
%let offset_43=length=&length_4 in offset=(%sysevalf(2*&axissize_4+6*&halfgap_4) in, %sysevalf(&axissize_4+4*&halfgap_4) in);
%let offset_44=length=&length_4 in offset=(%sysevalf(3*&axissize_4+8*&halfgap_4) in, %sysevalf(2*&halfgap_4) in);

put "/" "%nrstr(* Set the axis details *)" "/";
put "/" "%nrstr(* AXIS1 is the Y axis, AXIS4 AXIS5 AXIS6 AXIS7 are X axes. *)" "/";
put "/" "%nrstr(* All X-axes have blank labels here - the labels are inserted automatically using ANNOTATE *)" "/";
put "/" "%nrstr(* The finished plot consists of 4 separate plots, all overlaid. *)" "/";
put "/" "%nrstr(* It is essential to keep all the definitions consistent and mutually compatible. *)" "/";
put "/" "%nrstr(* You should not normally need to alter the LENGTH or OFFSET clauses. *)" "/";

/* Axis definitions for 4-parameter case */
/* We need 1 vertical axis */
put "%nrstr(axis1 c=black width=)" "5" "%nrstr( minor=none)"
    " &offset_4y &xy_order "
    "%nrstr(label=%(angle=90 h=)" "&fontsize_4" "%nrstr( j=left %")" 
%if %length(&yaxislabel) > 0
%then
  %do;
    "&yaxislabel"
  %end; 
    "%nrstr(%" %) value=%(h=)" "&figsize_4" "%nrstr(%);)";
/* And 4 horizontal axes, similarly */
put "%nrstr(axis4 c=black width=)" "5" "%nrstr( minor=none)" 
    " &offset_41 &xy_order "              
    "%nrstr(label=%(h=)" "&fontsize_4" "%nrstr( j=left %" %" %) value=%(h=)" "&figsize_4" "%nrstr(%);)";   
put "%nrstr(axis5 c=black width=)" "5" "%nrstr( minor=none)"
    " &offset_42 &xy_order "
    "%nrstr(label=%(h=)" "&fontsize_4" "%nrstr( j=center %" %" %) value=%(h=)" "&figsize_4" "%nrstr(%);)";
put "%nrstr(axis6 c=black width=)" "5" "%nrstr( minor=none)"
    " &offset_43 &xy_order "
    "%nrstr(label=%(h=)" "&fontsize_4" "%nrstr( j=right %" %" %) value=%(h=)" "&figsize_4" "%nrstr(%);)";
put "%nrstr(axis7 c=black width=)" "5" "%nrstr( minor=none)"
    " &offset_44 &xy_order "
    "%nrstr(label=%(h=)" "&fontsize_4" "%nrstr( j=right %" %" %) value=%(h=)" "&figsize_4" "%nrstr(%);)";
    
%end;    
  /*----------------------------------------------------------------------*/ 
  /*-- LM4.5.2 - Generate AXIS statements for 3-plot case */
%if &PlotsPerPage=3
%then
  %do;
%local fontsize_3 figsize_3;

%let fontsize_3=12pt;       * Size of font for axis label (parameter name);
%let figsize_3=10pt;         * Size of font for tickmark figures;

%let length_3=%sysevalf(3*&axissize_3 + 8*&halfgap_3);
%let length_3y=%sysevalf(&axissize_3 + 4*&halfgap_3);

%let offset_3y=length=&length_3y in offset=(%sysevalf(2*&halfgap_3) in, %sysevalf(2*&halfgap_3) in);
%let offset_31=length=&length_3 in offset=(%sysevalf(2*&halfgap_3) in,%sysevalf(2*&axissize_3+6*&halfgap_3) in);
%let offset_32=length=&length_3 in offset=(%sysevalf(&axissize_3+4*&halfgap_3) in, %sysevalf(&axissize_3+4*&halfgap_3) in);
%let offset_33=length=&length_3 in offset=(%sysevalf(2*&axissize_3+6*&halfgap_3) in, %sysevalf(2*&halfgap_3) in);

put "/" "%nrstr(* Set the axis details *)" "/";
put "/" "%nrstr(* AXIS1 is the Y axis, AXIS4 AXIS5 AXIS6 are X axes. *)" "/";
put "/" "%nrstr(* All X-axes have blank labels here - the labels are inserted automatically using ANNOTATE *)" "/";
put "/" "%nrstr(* The finished plot consists of 3 separate plots, all overlaid. *)" "/";
put "/" "%nrstr(* It is essential to keep all the axis definitions consistent and mutually compatible. *)" "/";
put "/" "%nrstr(* You should not normally need to alter the LENGTH or OFFSET clauses. *)" "/";

/* Axis definitions for 3-plot case */
/* We need 1 vertical axis */
put "%nrstr(axis1 c=black width=)" "5" "%nrstr( minor=none)"
    " &offset_3y &xy_order "
    "%nrstr(label=%(angle=90 h=)" "&fontsize_3" "%nrstr( j=left %")"
%if %length(&yaxislabel) > 0
%then
  %do;
    "&yaxislabel"
  %end; 
    "%nrstr(%" %) value=%(h=)" "&figsize_3" "%nrstr(%);)";
 /* And 3 horizontal axes, similarly */
put "%nrstr(axis4 c=black width=)" "5" "%nrstr( minor=none)" 
    " &offset_31 &xy_order "              
    "%nrstr(label=%(h=)" "&fontsize_3" "%nrstr( j=left %" %" %) value=%(h=)" "&figsize_3" "%nrstr(%);)";   
put "%nrstr(axis5 c=black width=)" "5" "%nrstr( minor=none)"
    " &offset_32 &xy_order "
    "%nrstr(label=%(h=)" "&fontsize_3" "%nrstr( j=center %" %" %) value=%(h=)" "&figsize_3" "%nrstr(%);)";
put "%nrstr(axis6 c=black width=)" "5" "%nrstr( minor=none)"
    " &offset_33 &xy_order "
    "%nrstr(label=%(h=)" "&fontsize_3" "%nrstr( j=right %" %" %) value=%(h=)" "&figsize_3" "%nrstr(%);)";
    
%end;    
  /*----------------------------------------------------------------------*/ 
  /*-- LM4.5.3 - Generate AXIS statements for 2-plot case */

%if &PlotsPerPage = 2
%then
  %do;
%local axissize_2 halfgap_2 fontsize_2 figsize_2;
%let fontsize_2=12pt;       * Size of font for axis label (parameter name);
%let figsize_2=8pt;         * Size of font for tickmark figures;
%let axissize_2=3.1;        * Units are IN, but we want to do arithmetic with this;
%let halfgap_2=0.1;

%let length_2=%sysevalf(2*&axissize_2 + 6*&halfgap_2);
%let length_2y=%sysevalf(&axissize_2 + 4*&halfgap_2);

%let offset_2y=length=&length_2y in offset=(%sysevalf(2*&halfgap_2) in, %sysevalf(2*&halfgap_2) in);
%let offset_21=length=&length_2 in offset=(%sysevalf(2*&halfgap_2) in, %sysevalf(&axissize_2+4*&halfgap_2) in);
%let offset_22=length=&length_2 in offset=(%sysevalf(&axissize_2+4*&halfgap_2) in, %sysevalf(2*&halfgap_2) in);
/**** Text below to be revised */

put "/" "%nrstr(* Set the axis details *)" "/";
put "/" "%nrstr(* AXIS1 is the Y axis, AXIS4 AXIS5 are X axes. *)" "/";
put "/" "%nrstr(* Both X axes have blank labels here - the labels are inserted automatically using ANNOTATE *)" "/";
put "/" "%nrstr(* The finished plot consists of 2 separate plots overlaid. *)" "/";
put "/" "%nrstr(* It is essential to keep the axis definitions consistent and mutually compatible. *)" "/";
put "/" "%nrstr(* You should not normally need to alter the LENGTH or OFFSET clauses. *)" "/";

/* Axis definitions for 2-plot case */

/* We need 1 vertical axis */
put "%nrstr(axis1 c=black width=)" "5" "%nrstr( minor=none)"
    " &offset_2y &xy_order "
    "%nrstr(label=%(angle=90 h=)" "&fontsize_2" "%nrstr( j=left %")" 
%if %length(&yaxislabel) > 0
%then
  %do;
    "&yaxislabel"
  %end; 
    "%nrstr(%" %) value=%(h=)" "&figsize_2" "%nrstr(%);)";
/* And 2 horizontal axes, similarly */
put "%nrstr(axis4 c=black width=)" "5" "%nrstr( minor=none)" 
    " &offset_21 &xy_order "              
    "%nrstr(label=%(h=)" "&fontsize_2" "%nrstr( j=left %" %" %) value=%(h=)" "&figsize_2" "%nrstr(%);)";   
put "%nrstr(axis5 c=black width=)" "5" "%nrstr( minor=none)"
    " &offset_22 &xy_order "
    "%nrstr(label=%(h=)" "&fontsize_2" "%nrstr( j=center %" %" %) value=%(h=)" "&figsize_2" "%nrstr(%);)";
%end;    
  /*----------------------------------------------------------------------*/ 
  /*-- LM4.5.4 - Generate AXIS statements for 1-plot case */
%if &PlotsPerPage = 1
%then
  %do;
%local axissize_1 fontsize_1 figsize_1;
%let fontsize_1=12pt;       * Size of font for axis label (parameter name);
%let figsize_1=8pt;         * Size of font for tickmark figures;
%let axissize_1=3.5;        * Units are IN;

%let offset_1=length=&axissize_1 in;

%local offset;
put "/" "%nrstr(* Set the axis details *)" "/";
put "/" "%nrstr(* AXIS1  is the Y axis, AXIS4 the X axis. *)" "/";
put "/" "%nrstr(* The X axis has a blank label here - the label is inserted automatically using ANNOTATE *)" "/";

/* Axis definitions for 1-plot case */
/* We need a vertical axis */
put "%nrstr(axis1 c=black width=)" "5" "%nrstr( minor=none)"
    " &offset_1 &xy_order "
    "%nrstr(label=%(angle=90 h=)" "&fontsize_1" "%nrstr( j=left %")" 
%if %length(&yaxislabel) > 0
%then
  %do;
    "&yaxislabel"
  %end; 
    "%nrstr(%" %) value=%(h=)" "&figsize_1" "%nrstr(%);)";
/* And a horizontal axis */
put "%nrstr(axis4 c=black width=)" "5" "%nrstr( minor=none)"
    " &offset_1 &xy_order "
    "%nrstr(label=%(h=)" "&fontsize_1" "%nrstr( j=center %" %" %) value=%(h=)" "&figsize_1" "%nrstr(%);)";
%end;    

  /*----------------------------------------------------------------------*/ 
  /*-- LM4.6 - Generate SYMBOL statements */
  
put "/" "%nrstr(* Set Symbols. *)" "/";
put "/" "%nrstr(* Use of any INTERPOL option would change the essence of the plot *)" "/";
put "%nrstr(symbol1 color=blue  h=0.5 font=orfonte value='W';)";
put "%nrstr(symbol2 color=red   h=0.5 font=orfonte value='C';)";
%if &numtrts > 2
%then
  %do;
put "%nrstr(symbol3 color=green h=0.5 font=orfonte value='D';)";
  %end;
%if &numtrts > 3
%then
  %do;
put "%nrstr(symbol4 color=black h=0.5 font=orfonte value='E';)";
  %end;
%if &numtrts > 4
%then
  %do;
put "%nrstr(symbol5 color=cyan  h=0.5 font=orfonte value='d';)";
  %end;
%if &numtrts > 5
%then
  %do;
put "%nrstr(symbol6 color=violet h=0.5 font=orfonte value='K';)";
  %end;
%if &numtrts > 6
%then
  %do;
put "%nrstr(symbol7 color=orange h=0.5 font=orfonte value='G';)";
  %end;
%if &numtrts > 7
%then
  %do;
put "%nrstr(symbol8 color=steel  h=0.5 font=orfonte value='J';)";
  %end;
%if &numparms > 8
%then
  %do;
put "/" "%nrstr(* Only 8 symbols for plots are defined automatically - *)" "/" ;
put "/" "%nrstr(* please define SYMBOL9 etc as required by your data *)" "/" ; 
  %end;
  
run;

%mend lb7_write_options;

  /*----------------------------------------------------------------------*/ 
  /*-- LM5 - Define local macro LB7_OnePlot */
  /* Called only from LB7_Graphics (which follows) */
  /* Generates plot for a single parameter */
  
%macro lb7_OnePlot(paramval, header, cat, entry, xaxis=, yaxis=);

/* No legend used here - we use a separate graphics entry for that */

/* title1 "&header"; */
%local thistitle;
%let thistitle=%scan(&parmlist,&paramval,|);

%annomac;

/* Annotations for reference lines */
data &prefix._refanno;
  %dclanno;
  length text $12;
  set &prefix._ref(where=(xnum=&paramval));
  %system(1,1,4);
  i=1;
  do while (scan(ref,i,' ') ne ' ');
    thisval=scan(ref,i,' ');
    if &axismin <= thisval <= &axismax
    then
      do;
        %system(2,2,4);
        %move(thisval,&axismin);
        %draw(thisval,&axismax,&refcolor,&refstyle,&width);
        %move(&axismin,thisval);
        %draw(&axismax,thisval,&refcolor,&refstyle,&width);
      end;  
    i+1;  
  end;
run;

/* Annotations for titles, X-axis labels and divisions between plots */
data &prefix._titleanno;
  %dclanno;
  length text $60;
  %system(1,5,3);
  x=(100/&PlotsPerPage) * (&paramval-0.5);
  y=&hedy;
  function='label';
  style="&ourfont";
  position='5';
  size=&titlesize;
  text="&thistitle";
  color='black';
  angle=0;
  rotate=0;
  when='A';
  output;
  x=50;
  y=&laby;
  text="&xaxislabel";
  output;
  %local plotn;
  %if &PlotsPerPage > 1
  %then
    %do plotn=1 %to %eval(&PlotsPerPage-1);
      %system(1,1,4);
      xbase=&plotn*100/&PlotsPerPage;
      %if &PlotsPerPage=4
      %then
        %do;
          %if &plotn=1 
          %then 
            %do;
              xbase=100*(&axissize_4+3*&halfgap_4)/(4*&axissize_4+10*&halfgap_4);
            %end;
          %if &plotn=3 
          %then 
            %do;
              xbase=100*(3*&axissize_4+7*&halfgap_4)/(4*&axissize_4+10*&halfgap_4);
            %end;
        %end;
      %if &PlotsPerPage=3
      %then
        %do;
          %if &plotn=1 
          %then 
            %do;
              xbase=100*(&axissize_3+3*&halfgap_3)/(3*&axissize_3+8*&halfgap_3);
            %end;
          %if &plotn=2 
          %then 
            %do;
              xbase=100*(2*&axissize_3+5*&halfgap_3)/(3*&axissize_3+8*&halfgap_3);
            %end;
        %end;
      x=xbase-&spacing/2;
      y=-1;
      function='move';
      output;
      x=xbase+&spacing/2;
      y=101;
      color='white';
      line=0;
      style='S';
      function='bar';
      output;
      x=xbase-&spacing/2;
      y=0;
      function='move';
      output;
      y=100;
      color='black';
      size=&width;
      function='draw';
      output;
      x=xbase+&spacing/2;
      function='move';
      output;
      y=0;
      function='draw';
      output;
    %end;
run;

data &prefix._allanno;
  set &prefix._titleanno &prefix._refanno ;
run;

proc gplot data=work.&prefix._plot(where=(paramord=&paramval)) annotate=&prefix._allanno gout=&cat;
     plot yvar * xvar=trtcd
    / haxis=&xaxis vaxis=&yaxis nolegend name="&entry";
run;
quit;

/* title1; */

%mend lb7_OnePlot;  
  
  /*----------------------------------------------------------------------*/ 
  /*-- LM6 - Define local macro LB7_Graphics */

  /* Generates graphics, using the specified graphics options file */


%macro lb7_graphics(filespec);

/* Do not use RESET=ALL - incompatible with ts_setup */
  GOPTIONS reset=goptions;

  /*----------------------------------------------------------------------*/ 
  /*-- LM6.0 - Define macro variables for PROC GREPLAY template */
  
   /* NB template is fixed at the moment */
   /* Extra headers and footers are liable to overlay main plot */ 
   /* With macro vars declared here, user can override them in options file */
   /* TOPY and BOTY have different defaults from other plot macros, due to presence of legend */
   /* LEGY reserves space for the legend AND PROBABLY THE X AXIS AS WELL. */
%local topy boty legy hedy titlesize width yup;   

%let lowpc=5;

%if &plotsPerPage=1
%then
  %do;
    %let boty=10;
    %let legy=15;
    %let hedy=88;
    %let laby=14;
    %let yup=2;
    %let titlesize=3;
    %let width=5;
  %end;
%if &plotsPerPage=2
%then
  %do;
    %let boty=10;
    %let legy=15;
    %let hedy=88;
    %let laby=14;
    %let titlesize=3;
    %let width=5;
    %let spacing=1.5;
    %let yup=0;
  %end;

%if &PlotsPerpage =3
%then
  %do;
    %let boty=5;
    %let legy=20;
    %let hedy=83;
    %let laby=19;
    %let titlesize=3;
    %let width=5;
    %let spacing=1;
    %let yup=5;
  %end;
%if &PlotsPerpage =4
%then
  %do;
    %let boty=5;
    %let legy=20;
    %let hedy=78;
    %let laby=24;
    %let titlesize=3;
    %let width=5;
    %let spacing=1;
    %let yup=5;
  %end;
  
  /* Macro variables for reference line properties */
  
  %let refcolor=GREEN;
  %let refstyle=20;

  /* Save value of HTITLE option before adopting user-specified value.
     User-specified value will apply to titles above each individual plot.
     We restore to original value before generating header/footer with tu_cr8gheadfoots */
     
%local txtsize;
%let txtsize=%sysfunc(getoption(htitle));

  /*----------------------------------------------------------------------*/ 
  /*-- LM6.1 - Read options file */
  
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

%global ourfont;
%let ourfont=%sysfunc(getoption(ftext));

/* Save XMAX and YMAX values. We may do stuff with these later, especially with 3 or 4 plots per page */
/* They were undefined until we read the options file */
/* Units of inches are assumed here */
%local defxmax defymax;
%let defxmax=%scan(%sysfunc(getoption(xmax)),1,' ');
%let defymax=%scan(%sysfunc(getoption(ymax)),1,' ');
%let defhsize=%scan(%sysfunc(getoption(hsize)),1,' ');
%let defvsize=%scan(%sysfunc(getoption(vsize)),1,' ');
/* Tried messing about with these values and restoring them later, but it did me no good */
    
  /*----------------------------------------------------------------------*/ 
  /*-- LM6.2 - Determine extension for plot file, and specify plot file name */
  
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
  /*-- LM6.4 - Generate the main plots */

%local plotname header;
%local xaxis yaxis;

  %do i=1 %to &PlotsPerPage;
    %let header=%scan(&parmlist,&i,"|");
    %let plotname=p&i;
    %lb7_OnePlot(&i,&header,temp_cat,&plotname,xaxis=axis%eval(3+&i),yaxis=axis1);
  %end;
  
  /*----------------------------------------------------------------------*/ 
  /*-- LM6.5 - Replay the main plots into a template */

           proc greplay igout = temp_cat gout = graph_cat tc = tempcat nofs;
                 tdef pageof4

                1 / llx = 0 lly = 0      lrx = 100  lry = 0 
                    ulx = 0 uly = 100    urx = 100  ury = 100
                2 / llx = 0 lly = 0      lrx = 100  lry = 0 
                    ulx = 0 uly = 100    urx = 100  ury = 100
                3 / llx = 0 lly = 0      lrx = 100  lry = 0 
                    ulx = 0 uly = 100    urx = 100  ury = 100
                4 / llx = 0 lly = 0      lrx = 100  lry = 0 
                    ulx = 0 uly = 100    urx = 100  ury = 100;

                  template pageof4;
                  treplay 1:p1 2:p2 3:p3 4:p4;
                  run;
                quit;
  
  /*----------------------------------------------------------------------*/ 
  /*-- LM6.6 - Generate plot header and footer as GSLIDE graphics */
  
/* restore HTITLE value saved long ago, and since maybe overridden by the graphics options file.*/
goptions htitle=&txtsize;
/* restore other values saved long ago, which we are unlikely to have overridden.*/
goptions xmax=&defxmax IN ymax=&defymax IN hsize=&defhsize IN vsize=&defvsize IN;

%tu_cr8gheadfoots(gout    = graph_cat_hf,
                  kill    = y,
                  pagecat = graph_cat,
                  font    = &ourfont,
                  ptsize  = 8);
                  
   /*----------------------------------------------------------------------*/ 
  /*-- LM6.7 -  Set file extension */

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
  
  /*----------------------------------------------------------------------*/ 
  /*-- LM6.8 - Generate LEGEND graphics entry */
  /* This uses the same technique as TU_CR8GLEGEND, but that "utility" macro is no use to us
     since it will not order the legend correctly in all cases */
  
        /* We want to see the X-axis label here, as well as the legend */
        /* Rest of this plot will be obscured by the "real" plot(s) */
 
 goptions ctitle=white cby=white;              * Do not want to see footnotes etc;
 goptions ftitle=&ourfont;
 
 proc gplot data=&prefix._plot gout=leg_cat;
      plot yvar * xvar=trtord
         / 
         legend=legend1 name="legend" vaxis=axis1 haxis=axis4;
 run;
  
  /*----------------------------------------------------------------------*/ 
  /*-- LM6.9 - Assemble complete plot file */
/***************************************************************************************** 
   Now we cannot use tu_templates because it gives us no control over the width of the plots displayed,
   and altering it is obviously impossible. So we have to replay stuff for ourselves.
    
   At this stage we have 
     entry TEMPLATE in GRAPH_CAT, containing the main plot 
     entry LEGEND in LEG_CAT containing a legend common to all plots, and
     entry GSLIDE in GRAPH_CAT_HF containing headers and footers.
      
   Now we copy this triplet into catalogue GRAPH_FINAL and replay them.       
*******************************************************************************************/
    proc catalog cat=graph_cat_hf et=grseg;
      copy out=graph_final;
      select GSLIDE;
    run;

    proc catalog cat=graph_cat et=grseg;
      copy out=graph_final;
      select TEMPLATE;
    run;
    
 /* Generate a blank frame */
 
    %let legtop=%sysevalf(&boty+&legy);
    %if  &boty le 30
    %then
      %do;
        /* Choose legend proportions so that font of X-axis label looks right */
        %let toply=%sysevalf(&boty+70);
      %end;
    %else
      %do;
        /* If BOTY too big, at least make sure we have a valid TOPLY value */
        %let toply=100;
      %end;

 /* Generate a blank frame */
 
    proc gslide gout=leg_cat name='blank' frame cframe=white;
    run; 
                  
/* Use the blank frame to clip the legend frame */

/****************
    proc greplay igout = leg_cat gout = tl_cat tc = tempcat nofs;
          tdef temp_leg

          1 / llx = 0 lly = &legtop    lrx = 100  lry = &legtop
              ulx = 0 uly = 100        urx = 100  ury = 100
              clip
              
          2 / llx = 10 lly = &boty    lrx = 90  lry = &boty
              ulx = 10 uly = &toply   urx = 90  ury = &toply
              ;
            template temp_leg;
          treplay 1:blank 2:legend;
          run;
        quit;
*****************/

    proc greplay igout = leg_cat gout = tl_cat tc = tempcat nofs;
          tdef temp_leg

          1 / llx = 0  lly = &legy    lrx = 100  lry = &legy
              ulx = 0  uly = 100      urx = 100  ury = 100
              clip
              
          2 / llx = 10 lly = 10       lrx = 90   lry = 10
              ulx = 10 uly = 90       urx = 90   ury = 90
              xlatey=-&boty
              ;
            template temp_leg;
          treplay 1:blank 2:legend;
          run;
        quit;




    proc catalog catalog=tl_cat et=grseg;
      change template=leg_only;
    run;
    
    proc catalog cat=tl_cat et=grseg;
      copy out=graph_final;
      select leg_only;                             
    run;
    
  /* Scale image appropriately - this feature not currently in use */
        %local lowpc highpc;
        %let highpc=%sysevalf(100-&lowpc);
        %let scale=%sysevalf((&highpc-&lowpc)/100); 
              
        proc greplay igout = graph_final gout = final_out tc = tempcat nofs;
          tdef temp3_34

          
          1 / llx = 0  lly = &lowpc     lrx = 100  lry = &lowpc
              ulx = 0  uly = &highpc    urx = 100  ury = &highpc
              scalex=&scale
              xlatey=&yup

          2 / llx = 0 lly = 0         lrx = 100  lry = 0
              ulx = 0 uly = 100       urx = 100  ury = 100
          
          3 / llx = 5  lly = 0        lrx = 95  lry = 0
              ulx = 5  uly = 100      urx = 95  ury = 100
              ;

          template temp3_34;
          treplay 1:template 2:leg_only 3:gslide;
          run;
        quit;
 
    proc catalog cat=graph_final kill;
    run; 
    
  /*----------------------------------------------------------------------*/ 
  /*-- LM6.10 - Convert PS to PDF, if reqd */
  
%if &plot_ext=ps
%then
  %do;
x ps2pdf &G_OUTFILE..ps &G_OUTFILE..&pdf_ext;
x rm &G_OUTFILE..ps;
  %end;

%mend lb7_graphics;

/************************************************************************/
/* Finally the rest of the main macro TD_LB7                            */
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

/* Declare some global parameters related to axis dimensions. */
/* These need to be globals in case we are using a user-supplied graphics options file */

%global axissize_4 halfgap_4;   * Used later in annotations;
%let axissize_4=1.9;       * Units are IN, but we want to do arithmetic with this;
%let halfgap_4=0.1;
%global axissize_3 halfgap_3;    * Used later in annotations;
%let axissize_3=2.4;       * Units are IN, but we want to do arithmetic with this;
%let halfgap_3=0.15;

/* Now we can actually start doing things... */

%if &InputUsage=C
%then
  %do;

  /*----------------------------------------------------------------------*/ 
  /*-- NP6 - Write template file if wanted */
  
      %put %str(RTN)OTE: &macroname: Creating template code file for input dataset; 
      %put %str(RTN)OTE: &macroname: No graph will be generated;       
      %lb7_write_template(usr_prof);
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
        %lb7_use_template(&InputFile); 
        %put %str(RTN)OTE: &macroname: Finished execution of user-supplied SAS code (dataset creation);
        %lb7_input_dataset(&tmp_dset);
      %end;
    %else
      %do;  
        %lb7_input_dataset(&InputDataset);
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
        %lb7_write_options(&writopts);
      %end;

  /*----------------------------------------------------------------------*/ 
  /*-- NP9 - Read options file and generate graphics if we need to */
    %if %length(&readopts) > 0 
    %then
      %do;
        %lb7_graphics(&readopts);
      %end;
%end;

  /*----------------------------------------------------------------------*/
  /*--NP10 - Tidy up and call tu_abort   */

  %tu_tidyup(rmdset=&prefix:, glbmac=NONE);
  %tu_abort;

%mend td_lb7;
