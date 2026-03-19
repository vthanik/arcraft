/*******************************************************************************
|
| Macro Name:      td_lb8
|
| Macro Version:   1 build 3
|
| SAS Version:     8.2
|                                                             
| Created By:      Bob Newman (Amadeus) 
|
| Date:            27 November 2006
|
| Macro Purpose:   To generate an LB8 plot
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
|  RefLines         Values for horizontal reference lines            OPT      [BLANK]
|  LogBase          Log base for y-axis - 2, 10 or 0 (=linear)       OPT      [BLANK]
|                   or 1 (=linear marked in integers)
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
| (@) tu_order
| (@) tu_orderlog
| (@) tu_putglobals
| (@) tu_tidyup
| (@) tu_valparms
|
| Example:
| %td_lb8(InputDataset=myplot
|   , InputUsage=D
|  );
|
|******************************************************************************
| Change Log
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     27-Nov-06
| New version/draft number: 01.001
| Modification ID:          RCN.01.001
| Reason For Modification:  Original version
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     14-Dec-06
| New version/draft number: 01.002
| Modification ID:          RCN.01.002
| Reason For Modification:  Reverted to standard code at NP7, so InputUsage=U handled correctly.
|                           (Had inherited non-standard code from LB11!)
|                           Changed values of AXISSIZE_4, HALFGAP_4, AXISSIZE_3, HALFGAP_3
|                           Changed value of HALFGAP_4 
|                           Changed value of AXISSIZE_3
|                           Changed value of HALFGAP_3 
|                           Also altered the use of HALFGAP - we now have a "double halfgap" at each end of the axis.
|                           This required changes to the calculation of ONETHIRD and TWOTHIRD in the annotations at LM5.
|                           These changes to the axes overcame a problem in testing where the numbers on the bottom y-axis appeared
|                           blurred, due to overlaid plots not aligning perfectly.
|                           The cure for this is to increase the relevant HALFGAP value - but then AXISSIZE has to be reduced
|                           to compensate. Clearly we want AXISSIZE to be as large as possible.
|                           The problem arises when there are multiple digits in each axis annotation (so using LOGBASE=1
|                           always solves it.)
|                           Also moved AXISSIZE and HALFGAP declarations into main NP code (where they need to be if we are using 
|                           a user-supplied graphics options file.)
|                           Where 4 parameters (and 6 plots) reduced FIGSIZE_4 (size of numbers at axis tickmarks) to 5pt unless
|                           LogBase=1 (when we can get away with 6pt).
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     22-Jan-07
| New version/draft number: 01.003
| Modification ID:          RCN.01.003
| Reason For Modification:  New code to extract axis limits from ORDER clause (1.6)
|                           Corrected value of SLASHCOUNT at 1.2.
|
|
|
| Modified By:
| Date of Modification:
| New version/draft number:
| Modification ID:
| Reason For Modification:
*******************************************************************************/
  
%macro td_lb8
      (
       InputDataset=                               /* type:ID Input dataset */,
       InputFile=                                  /* Name of file if InputUsage=C or U */,
       InputUsage=D                                /* Style of input data D=dataset C=create template U=use template */,
       OptionsFile=                                /* Name of file if OptionsFileUsage=C or U */,
       OptionsFileUsage=                           /* Style of options file C=create U=use blank=use default settings */,
       RefLines=                                   /* Position of horizontal reference lines (data values) */,
       LogBase=1                                   /* Log base for y-axis (2 or 10, or 1 for a linear axis in integers) */ );

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
  %let InputFile=%nrbquote(&InputFile);
  %let InputUsage=%upcase(&InputUsage);
  %let InputUsage=%nrbquote(&InputUsage);
  %let OptionsFile=%nrbquote(&OptionsFile);
  %let OptionsFileUsage=%upcase(&OptionsFileUsage);
  %let OptionsFileUsage=%nrbquote(&OptionsFileUsage);
  %let RefLines=%nrbquote(&RefLines);
  %let Reflines=%nrbquote(%sysfunc(tranwrd(&RefLines,%str(/),%str(/ ))));
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
    
  /*--PV6 - RefLines: check any values specified are numeric and not in scientific notation */
  %local slashless i thisval thisnum thisvalOK;
  %global slashcount;    
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
                      %else
                        %do;
                          %if %sysfunc(indexc(&thisnum,DEde)) > 0
                          %then
                            %do;
                              %put %str(RTE)RROR: &macroname: RefLines values cannot use scientific notation;
                              * %datatyp will be happy but PROC GPLOT would not be;
                              %let pv_abort = 1;          
                            %end;
                        %end;
                      %let j=%eval(&j+1);
                    %end;
                  %end; 
             %end;
          %end;
        %end;
    %end;

/*--PV7 - LOGBASE: check it is 0 or 2 or 10 */
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
  
  /*----------------------------------------------------------------------*/

  /*----------------------------------------------------------------------*/ 
  /*-- LM1 - Define local macro LB8_Input_Dataset */
  
  /*  Processes user-supplied input dataset */
  /* (Validation and any necessary manipulation) */
  /* We create a dataset PLOT for use in the actual graphics. */

%macro lb8_input_dataset(dsname);

/* Lists of variable names, by data type, and all required */
%local charvars numvars mustvars byvars;
%let charvars=trtgrp param;
%let numvars=trtcd paramcd subjid axisvar; 
%let mustvars=&charvars &numvars;
/* List of variables which must be a unique n-tuple for each record */
%let byvars=paramcd trtcd subjid;
%global dupvar;		* Variable to receive number of duplicates found;
  
  /*----------------------------------------------------------------------*/ 
  /*-- LM1.1 - Validation of dataset */
  
%local pv_abort; 
%let pv_abort=0;

/* Check existence of datasets */
%tu_valparms(
  abortyn=Y,
  macroname=lb8_input_dataset,
  chktype=dsetExists,
  pv_dsetin=dsname
  );
/* Check presence of variables */
%tu_valparms(
  abortyn=N,
  macroname=lb8_input_dataset,
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
        macroname=lb8_input_dataset,
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
        macroname=lb8_input_dataset,
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
  %if &paramct < 2 
  %then
    %do;
      %put %str(RTE)RROR: &macroname: Data is needed for at least 2 laboratory parameters;
      %tu_abort(option=force);
    %end;

  %if %length(%sysfunc(compbl(&RefLines))) > 0
  %then
    %do;
      %let slashcount=%eval(&slashcount-1);
      %if &slashcount > &paramct
      %then
        %do;
          %put %str(RTN)OTE: &macroname: More sets of reference lines specified than plot variables;
        %end;
      %if &slashcount < &paramct
      %then
        %do;
          %put %str(RTN)OTE: &macroname: Fewer sets of reference lines specified than plot variables;
        %end;
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

/* Create orddata dataset, with ordinals for both parameter and treatment codes */ 
  
  data &prefix._orddata;
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
  
  /*----------------------------------------------------------------------*/ 
  /*-- LM1.3 - Derive some useful data-dependent macro variables */

%global numtrts;	* Number of different treatments;
%global numparms;	* Number of different parameters;
%global xy_order;   * ORDER statement for inclusion in an AXIS statements for all axes;
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
             ,dsetin=&prefix._orddata
             ,varlist=axisvar
             );
   %end;
%else %if &logbase=1
%then
  %do;
    %local minval maxval;
    proc sql noprint;
      select floor(min(axisvar)) into :minval from &prefix._orddata;
      select ceil(max(axisvar)) into :maxval from &prefix._orddata;
    quit;
    %let xy_order=order=(&minval to &maxval by 1);
  %end;
%else
  %do;
    %tu_orderlog(macrovar=xy_order
                ,dsetin=&prefix._orddata
                ,varlist=axisvar
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
    
  /*----------------------------------------------------------------------*/ 
  /*-- LM1.7 - Create separate datasets for each PARAM value */
  
proc sort data=&prefix._orddata out=&prefix._ordsort;
  by subjid trtord;
run;

%do i=1 %to &numparms;
  data &prefix._param&i;
    set &prefix._ordsort(where=(paramord=&i));
    by subjid trtord;
    rename axisvar=param&i;
    drop param paramcd paramord;
  run;
%end;  

  /*----------------------------------------------------------------------*/ 
  /*-- LM1.8 - Merge them to make PLOT dataset */
  
data &prefix._plot;
  merge
    %do i=1 %to &numparms;
      &prefix._param&i
    %end;
    ;
  by subjid trtord;
run;

%mend lb8_input_dataset;

  /*----------------------------------------------------------------------*/ 
  /*-- LM2 - Define local macro LB8_Write_template */
 
   /* Provides user with a SAS code template for the required input dataset */

%macro lb8_write_template(fnam);

/* NB All quotes to be generated must be preceded by "%", whether matched or not. */

data _null_;
  file &fnam;

%tu_cr8proghead(macname=create_lb8_example_dataset, macdesign=SAS_datastep_not_a_macro);
* Second param above is not validated but cannot be more than one word, apparently;

put " ";
put "%nrstr(data work.lb8_example_dataset;)";
put "%nrstr(* Data set must include at least these 6 variables;)";
put "%nrstr(  attrib)";
put "%nrstr(    trtgrp   length=$120 label=%"Treatment group label to appear in the legend%")";
put "%nrstr(    trtcd    length=8    label=%"Treatment code to order the legend%")";
put "%nrstr(    param    length=$120 label=%"Laboratory parameter label to appear in the title%")";
put "%nrstr(    paramcd  length=8    label=%"Laboratory parameter code to order the plots%")";
put "%nrstr(    subjid   length=8    label=%"Subject number%")";
put "%nrstr(    axisvar  length=8    label=%"Value to be plotted%")";
put "%nrstr(  ;)"; 
put "%nrstr(run;)";

run;

%mend lb8_write_template;

  /*----------------------------------------------------------------------*/ 
  /*-- LM3 - Define local macro LB8_Use_template */

  /* Uses an input template for the input dataset */

%macro lb8_use_template(filespec);

  %global tmp_dset;

  %include "&filespec";

  %let tmp_dset=&syslast;       * Save name of dataset just created;

%mend lb8_use_template;

  /*----------------------------------------------------------------------*/ 
  /*-- LM4 - Define local macro LB8_Write_Options */

   /* Provides user with source code for standard graphics options  */
   /* (data dependent) */

%macro lb8_write_options(fnam);

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

%tu_cr8proghead(macname=lb8_graphics_options, macdesign=SAS_code_not_a_macro);
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

  /*----------------------------------------------------------------------*/ 
  /*-- LM4.5.1 - Generate AXIS statements for 4-parameter case */
%if &numparms=4
%then
  %do;

%local fontsize_4 figsize_4;
/* NBBBB Values chosen here are very sensitive! Do not alter the values below without taking care
   to record the old values, which you may subsequently wish to restore!
   Considerations include:
   * We want AXISSIZE as big as possible
   * HALFGAP needs to be above a certain threshold value (determinable only by trial and error) if all
     6 of the overlaid plots are to align properly.
   * FIGSIZE has to be small, so that even in the worst case, the numerical values on the X-axis are printed
     horizontally rather than vertically. Vertical printing would take up extra space so that the Y-axis did not fit.
   * The user is going to want to increase FIGSIZE in his options file (if he alters ORDER appropriately) so
     AXISSIZE and HALFGAP have to be small enough that there is enough room for the larger characters.
 NB Meaning of HALFGAP altered 15/12/2006 - we now have a "double halfgap" at the ends of the axes as well as between plots
****/  
%let fontsize_4=12pt;       * Size of font for axis label (parameter name);
%if &LogBase=1
%then
  %do;
    %let figsize_4=6pt;
  %end;
%else
  %do;
    %let figsize_4=5pt;         * Size of font for tickmark figures;
  %end;

%let length_4=%sysevalf(3*&axissize_4 + 8*&halfgap_4);

%let offset_41=length=&length_4 in offset=(%sysevalf(2*&halfgap_4) in,%sysevalf(2*&axissize_4+6*&halfgap_4) in);
%let offset_42=length=&length_4 in offset=(%sysevalf(&axissize_4+4*&halfgap_4) in, %sysevalf(&axissize_4+4*&halfgap_4) in);
%let offset_43=length=&length_4 in offset=(%sysevalf(2*&axissize_4+6*&halfgap_4) in, %sysevalf(2*&halfgap_4) in);
/* Should note that axis labels are blank here, and done elsewhere using annotate */

put "/" "%nrstr(* Set the axis details *)" "/";
put "/" "%nrstr(* AXIS1 AXIS2 AXIS3 are Y axes, AXIS4 AXIS5 AXIS6 are X axes. *)" "/";
put "/" "%nrstr(* All axes have blank labels here - the labels are inserted automatically using ANNOTATE *)" "/";
put "/" "%nrstr(* The finished plot consists of 6 separate plots, all overlaid. *)" "/";
put "/" "%nrstr(* It is essential to keep all 6 axis definitions consistent and mutually compatible. *)" "/";
put "/" "%nrstr(* You should not normally need to alter the LENGTH or OFFSET clauses. *)" "/";
put "/" "%nrstr(* To increase the font size for the numbers on the axes, alter H= within VALUE clause. *)" "/";
put "/" "%nrstr(* However NB there may not be enough space for the larger font unless you also alter the ORDER clauses. *)" "/";
put "/" "%nrstr(* Too large a font may result in SAS warnings that the axes will not fit, and an unsatisfactory plot. *)" "/";

/* Axis definitions for 4-parameter case */
/* We need 3 vertical axes, with different offsets */
%global xaxislabel yaxislabel;

put "%nrstr(axis1 c=black width=)" "5" "%nrstr( minor=none)"
    " &offset_41 &xy_order "
    "%nrstr(label=%(angle=90 h=)" "&fontsize_4" "%nrstr( j=left %" %" %) value=%(h=)" "&figsize_4" "%nrstr(%);)";
put "%nrstr(axis2 c=black width=)" "5" "%nrstr( minor=none)"
    " &offset_42 &xy_order "
    "%nrstr(label=%(angle=90 h=)" "&fontsize_4" "%nrstr( j=center %" %" %) value=%(h=)" "&figsize_4" "%nrstr(%);)";
put "%nrstr(axis3 c=black width=)" "5" "%nrstr( minor=none)"
    " &offset_43 &xy_order "
    "%nrstr(label=%(angle=90 h=)" "&fontsize_4" "%nrstr( j=right %" %" %) value=%(h=)" "&figsize_4" "%nrstr(%);)";
/* And 3 horizontal axes, similarly */
put "%nrstr(axis4 c=black width=)" "5" "%nrstr( minor=none)"
    " &offset_41 &xy_order "
    "%nrstr(label=%(h=)" "&fontsize_4" "%nrstr( j=left %" %" %) value=%(h=)" "&figsize_4" "%nrstr(%);)";
put "%nrstr(axis5 c=black width=)" "5" "%nrstr( minor=none)"
    " &offset_42 &xy_order "
    "%nrstr(label=%(h=)" "&fontsize_4" "%nrstr( j=center %" %" %) value=%(h=)" "&figsize_4" "%nrstr(%);)";
put "%nrstr(axis6 c=black width=)" "5" "%nrstr( minor=none)"
    " &offset_43 &xy_order "
    "%nrstr(label=%(h=)" "&fontsize_4" "%nrstr( j=right %" %" %) value=%(h=)" "&figsize_4" "%nrstr(%);)";
%end;    
  /*----------------------------------------------------------------------*/ 
  /*-- LM4.5.2 - Generate AXIS statements for 3-parameter case */
%if &numparms = 3
%then
  %do;
%local axissize_3 halfgap_3 fontsize_3 figsize_3;
%let fontsize_3=12pt;       * Size of font for axis label (parameter name);
%let figsize_3=8pt;         * Size of font for tickmark figures;
%let axissize_3=1.9;        * Units are IN, but we want to do arithmetic with this;
%let halfgap_3=0.12;

%let length_3=%sysevalf(2*&axissize_3 + 6*&halfgap_3);

%let offset_31=length=&length_3 in offset=(%sysevalf(2*&halfgap_3) in, %sysevalf(&axissize_3+4*&halfgap_3) in);
%let offset_32=length=&length_3 in offset=(%sysevalf(&axissize_3+4*&halfgap_3) in, %sysevalf(2*&halfgap_3) in);

%local offset;
put "/" "%nrstr(* Set the axis details *)" "/";
put "/" "%nrstr(* AXIS11 AXIS12 are Y axes, AXIS13 AXIS14 are X axes. *)" "/";
put "/" "%nrstr(* All axes have blank labels here - the labels are inserted automatically using ANNOTATE *)" "/";
put "/" "%nrstr(* The finished plot consists of 3 separate plots, all overlaid. *)" "/";
put "/" "%nrstr(* It is essential to keep all 4 axis definitions consistent and mutually compatible. *)" "/";
put "/" "%nrstr(* You should not normally need to alter the LENGTH or OFFSET clauses. *)" "/";
put "/" "%nrstr(* To increase the font size for the numbers on the axes, alter H= within VALUE clause. *)" "/";
put "/" "%nrstr(* However NB there may not be enough space for the larger font unless you also alter the ORDER clauses. *)" "/";
put "/" "%nrstr(* Too large a font may result in SAS warnings that the axes will not fit, and an unsatisfactory plot. *)" "/";

/* Axis definitions for 3-parameter case */
/* We need 2 vertical axes, with different offsets */
%global xaxislabel yaxislabel;

put "%nrstr(axis11 c=black width=)" "5" "%nrstr( minor=none)"
    " &offset_31 &xy_order "
    "%nrstr(label=%(angle=90 h=)" "&fontsize_3" "%nrstr( j=center %" %" %) value=%(h=)" "&figsize_3" "%nrstr(%);)";
put "%nrstr(axis12 c=black width=)" "5" "%nrstr( minor=none)"
    " &offset_32 &xy_order "
    "%nrstr(label=%(angle=90 h=)" "&fontsize_3" "%nrstr( j=center %" %" %) value=%(h=)" "&figsize_3" "%nrstr(%);)";
/* And 2 horizontal axes, similarly */
put "%nrstr(axis13 c=black width=)" "5" "%nrstr( minor=none)"
    " &offset_31 &xy_order "
    "%nrstr(label=%(h=)" "&fontsize_3" "%nrstr( j=center %" %" %) value=%(h=)" "&figsize_3" "%nrstr(%);)";
put "%nrstr(axis14 c=black width=)" "5" "%nrstr( minor=none)"
    " &offset_32 &xy_order "
    "%nrstr(label=%(h=)" "&fontsize_3" "%nrstr( j=center %" %" %) value=%(h=)" "&figsize_3" "%nrstr(%);)";
%end;    
  /*----------------------------------------------------------------------*/ 
  /*-- LM4.5.3 - Generate AXIS statements for 2-parameter case */
%if &numparms = 2
%then
  %do;
%local axissize_2 fontsize_2 figsize_2;
%let fontsize_2=12pt;       * Size of font for axis label (parameter name);
%let figsize_2=8pt;         * Size of font for tickmark figures;
%let axissize_2=4.5;        * Units are IN;

%let offset_2=length=&axissize_2 in;

/**** Text below to be revised */

%local offset;
put "/" "%nrstr(* Set the axis details *)" "/";
put "/" "%nrstr(* AXIS21  is the Y axis, AXIS22 the X axis. *)" "/";
put "/" "%nrstr(* All axes have blank labels here - the labels are inserted automatically using ANNOTATE *)" "/";

/* Axis definitions for 2-parameter case */
/* We need a vertical axis */
put "%nrstr(axis21 c=black width=)" "5" "%nrstr( minor=none)"
    " &offset_2 &xy_order "
    "%nrstr(label=%(angle=90 h=)" "&fontsize_2" "%nrstr( j=center %" %" %) value=%(h=)" "&figsize_2" "%nrstr(%);)";
/* And a horizontal axis */
put "%nrstr(axis22 c=black width=)" "5" "%nrstr( minor=none)"
    " &offset_2 &xy_order "
    "%nrstr(label=%(h=)" "&fontsize_2" "%nrstr( j=center %" %" %) value=%(h=)" "&figsize_2" "%nrstr(%);)";
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
/*******************************************
put "%nrstr(symbol1 color=blue  value=square ;)";
put "%nrstr(symbol2 color=red   value=circle;)";
%if &numtrts > 2
%then
  %do;
put "%nrstr(symbol3 color=green value=triangle;)";
  %end;
%if &numtrts > 3
%then
  %do;
put "%nrstr(symbol4 color=black value=diamond;)";
  %end;
%if &numtrts > 4
%then
  %do;
put "%nrstr(symbol5 color=cyan  value= %'+%';)";
  %end;
%if &numtrts > 5
%then
  %do;
put "%nrstr(symbol6 color=violet value=hash;)";
  %end;
%if &numtrts > 6
%then
  %do;
put "%nrstr(symbol7 color=orange value= %'=%';)";
  %end;
%if &numtrts > 7
%then
  %do;
put "%nrstr(symbol8 color=steel  value= %'&%';)";
  %end;
****/

%if &numtrts > 8
%then
  %do;
put "/" "%nrstr(* Only 8 symbols for plots are defined automatically - *)" "/" ;
put "/" "%nrstr(* please define SYMBOL9 etc as required by your data *)" "/" ; 
  %end;
  
run;

%mend lb8_write_options;

  /*----------------------------------------------------------------------*/ 
  /*-- LM5 - Define local macro LB8_OnePlot */
  /* Called only from LB7_Graphics (which follows) */
  /* Generates plot for a single parameter */
  
%macro lb8_OnePlot(cat, entry, optspec, n, x=, y=, xvar=, yvar=, xaxis=, yaxis=);

%global xaxislabel yaxislabel;
%let xaxislabel=%scan(&parmlist,&xvar,|);
%let yaxislabel=%scan(&parmlist,&yvar,|);


/* Specify reference lines. These depend on xvar and yvar. */
  
  %local refspec thisspec;
  %let refspec=;
  %if %length(%nrbquote(%sysfunc(compbl(&RefLines)))) > 0
  %then
    %do;
      %let thisspec=%qscan(&Reflines,&xvar,/); 
      %if %length(%sysfunc(compbl(&thisspec))) > 0
      %then
        %do;
          %let refspec=chref=&refcolor lhref=&refstyle href=&thisspec;
        %end;
      %let thisspec=%qscan(&Reflines,&yvar,/); 
      %if %length(%sysfunc(compbl(&thisspec))) > 0
      %then
        %do;
          %let refspec=&refspec. cvref=&refcolor lvref=&refstyle vref=&thisspec; 
        %end;
    %end;

/* Generate annotations */

%annomac;
data &prefix._frameanno;
  %dclanno;
  length text $24;
  when='A';
  %system(1,1,4);
  %if &n=3
  %then
    %do;
      %let onethird=%sysevalf(100*(&axissize_4+3*&halfgap_4)/(3*&axissize_4+8*&halfgap_4));
      %let twothird=%sysevalf(100*(2*&axissize_4+5*&halfgap_4)/(3*&axissize_4+8*&halfgap_4));
      /* Erase unwanted bits of axis frame, using a nice broad white line */
      color='white';
      style=1;
      size=20;
      x=&onethird;
      y=100;
      function='move';
      output;
      x=100;
      function='draw';
      output;
      x=100;
      y=&onethird;
      function='move';
      output;
      y=100;
      function='draw';
      output;
      /* Now draw our own trellis */
      color='black';
      style='1';
      size=&width;
      x=&onethird;
      y=0;
      function='move';
      output;
      y=100;
      function='draw';
      output;
      x=&twothird;
      y=0;
      function='move';
      output;
      y=&twothird;
      function='draw';
      output;
      x=0;
      y=&onethird;
      function='move';
      output;
      x=100;
      function='draw';
      output;
      y=&twothird;
      x=0;
      function='move';
      output;
      x=&twothird;
      function='draw';
      output;
      /* Blank out unused areas (where there may be unwanted reflines) */
      color='white';
      x=&onethird;
      y=&twothird;
      function='move';
      output;
      x=100;
      y=100;
      line=0;   * Draw all edges;
      style='SOLID';
      function='bar';
      output;
      x=&twothird;
      y=&onethird;
      function='move';
      output;
      x=100;
      y=&twothird;
      style='SOLID';
      function='bar';
      output;      
    %end;
  %if &n=2
  %then
    %do;
      %local half;
      %let half=100/2;
      /* Erase unwanted bits of axis frame, using a nice broad white line */
      color='white';
      style=1;
      size=20;
      x=&half;
      y=100;
      function='move';
      output;
      x=100;
      function='draw';
      output;
      x=100;
      y=&half;
      function='move';
      output;
      y=100;
      function='draw';
      output;
      /* Now draw our own trellis */
      color='black';
      style='1';
      size=&width;
      x=&half;
      y=0;
      function='move';
      output;
      y=100;
      function='draw';
      output;
      x=0;
      y=&half;
      function='move';
      output;
      x=100;
      function='draw';
      output;
      /* Blank out unused areas (where there may be unwanted reflines) */
      color='white';
      x=&half;
      y=&half;
      function='move';
      output;
      x=100;
      y=100;
      line=0;   * Draw all edges;
      style='SOLID';
      function='bar';
      output;
    %end;
  /* X-axis label */
  %system(1,3,3);
  %if &n=3
  %then
    %do;
      x=50+35*(&x-2);
      y=10;
    %end;    
  %if &n=2
  %then
    %do;
      x=50+50*(&x-1.5);
      y=10;
    %end; 
  %if &n=1
  %then
    %do;
      x=50;
      y=10;
    %end;   
  text="&xaxislabel";
  color='black';
  angle=0;
  rotate=0;
  size=3;
  style="&ourfont";
  position='5';
  function='label';
  when='A';
  output;
  /* Y-Axis label */
  %system(3,1,3);
  %if &n=3
  %then
    %do;
      x=23;
      y=50+35*(&y-2);
    %end;    
  %if &n=2
  %then
    %do;
      x=23;
      y=50+50*(&y-1.5);
    %end;    
  %if &n=1
  %then
    %do;
      x=23;
      y=50;
    %end;    
  text="&yaxislabel";
  color='black';
  angle=90;
  rotate=0;
  size=3;
  style="&ourfont";
  position='5';
  function='label';
  when='A';
  output;
run;

/* Re-read options file to substitute newly-evaluated axis labels */
/* Not sure what I had in mind here but no longer doing it! */
/****
%if &OptionsFileUsage=U
%then
  %do;
    %put %str(RTN)OTE: &macroname: Starting execution of user-supplied SAS code (graphics options);
    %label(50,50,&xaxislabel,magenta,0,0,4,&ourfont,5);
  %end;
 
 %include "&optspec"; 

%if &OptionsFileUsage=U
%then
  %do;
    %put %str(RTN)OTE: &macroname: Finished execution of user-supplied SAS code (graphics options);
  %end;
**************/

proc gplot data=work.&prefix._plot annotate=&prefix._frameanno gout=&cat;
     plot param&yvar * param&xvar=trtord
    / haxis=&xaxis vaxis=&yaxis legend=legend1 name="&entry" &refspec;
run;
quit;

%mend lb8_OnePlot;  
  
  /*----------------------------------------------------------------------*/ 
  /*-- LM6 - Define local macro LB7_Graphics */

  /* Generates graphics, using the specified graphics options file */


%macro lb8_graphics(filespec);

/* Do not use RESET=ALL - incompatible with ts_setup */
  GOPTIONS reset=goptions;

  /*----------------------------------------------------------------------*/ 
  /*-- LM6.0 - Define macro variables for PROC GREPLAY template */
  
   /* NB template is fixed at the moment */
   /* Extra headers and footers are liable to overlay main plot */ 
   /* With macro vars declared here, user can override them in options file */
%local topy boty;   
%let topy=87;
%let boty=7;

  /* Macro variables for reference line properties */

%local refcolor refstyle;  
%let refcolor=GREEN;
%let refstyle=1;

  /* Macro variables for lines dividing plots */
%global width;
%let width=5;

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
  /*-- LM6.3 - Generate the main plots */

%if &numparms=4
%then
  %do;
    %lb8_OnePlot(temp_cat,P1,&filespec,3,x=1,y=1,xvar=4,yvar=1,xaxis=axis4,yaxis=axis1);
    %lb8_OnePlot(temp_cat,P2,&filespec,3,x=2,y=1,xvar=3,yvar=1,xaxis=axis5,yaxis=axis1);
    %lb8_OnePlot(temp_cat,P3,&filespec,3,x=3,y=1,xvar=2,yvar=1,xaxis=axis6,yaxis=axis1);
    %lb8_OnePlot(temp_cat,P4,&filespec,3,x=1,y=2,xvar=4,yvar=2,xaxis=axis4,yaxis=axis2);
    %lb8_OnePlot(temp_cat,P5,&filespec,3,x=2,y=2,xvar=3,yvar=2,xaxis=axis5,yaxis=axis2);
    %lb8_OnePlot(temp_cat,P6,&filespec,3,x=1,y=3,xvar=4,yvar=3,xaxis=axis4,yaxis=axis3);   
  %end;
                    
%if &numparms=3
%then
  %do;
    %lb8_OnePlot(temp_cat,P1,&filespec,2,x=1,y=1,xvar=3,yvar=1,xaxis=axis13,yaxis=axis11);
    %lb8_OnePlot(temp_cat,P2,&filespec,2,x=2,y=1,xvar=2,yvar=1,xaxis=axis14,yaxis=axis11);
    %lb8_OnePlot(temp_cat,P3,&filespec,2,x=1,y=2,xvar=3,yvar=2,xaxis=axis13,yaxis=axis12);
  %end;
  
%if &numparms=2
%then
  %do;
    %lb8_OnePlot(temp_cat,P1,&filespec,1,x=1,y=1,xvar=2,yvar=1,xaxis=axis22,yaxis=axis21);
  %end;
                    
  /*----------------------------------------------------------------------*/ 
  /*-- LM6.4 - Replay the main plots into a template */

/* All plots have been generated. Must now put them together */
/* Even for PlotsPerPage=1, we replay to narrow the plot and make the logic easier later */
           proc greplay igout = temp_cat gout = graph_cat tc = tempcat nofs;
                 tdef overlay6

                1 / llx = 0 lly = 0      lrx = 100  lry = 0 
                    ulx = 0 uly = 100    urx = 100  ury = 100
                2 / llx = 0 lly = 0      lrx = 100  lry = 0 
                    ulx = 0 uly = 100    urx = 100  ury = 100
                3 / llx = 0 lly = 0      lrx = 100  lry = 0 
                    ulx = 0 uly = 100    urx = 100  ury = 100
                4 / llx = 0 lly = 0      lrx = 100  lry = 0 
                    ulx = 0 uly = 100    urx = 100  ury = 100
                5 / llx = 0 lly = 0      lrx = 100  lry = 0 
                    ulx = 0 uly = 100    urx = 100  ury = 100
                6 / llx = 0 lly = 0      lrx = 100  lry = 0 
                    ulx = 0 uly = 100    urx = 100  ury = 100;
 
                  template overlay6;
                  treplay 1:p1 2:p2 3:p3 4:p4 5:p5 6:p6;
                  run;
                quit;
          
                      
  /*----------------------------------------------------------------------*/ 
  /*-- LM6.5 - Generate plot header and footer as GSLIDE graphics */
  
/* restore HTITLE value saved long ago, and since maybe overridden by the graphics options file.*/
****goptions htitle=&titsize;
/* restore other values saved long ago, which we are unlikely to have overridden.*/
****goptions xmax=&defxmax IN ymax=&defymax IN hsize=&defhsize IN vsize=&defvsize IN;

%tu_cr8gheadfoots(gout    = graph_cat_hf,
                  kill    = y,
                  pagecat = graph_cat,
                  font    = &ourfont,
                  ptsize  = 8);
                  
   /*----------------------------------------------------------------------*/ 
  /*-- LM6.6 -  Set file extension */

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
  /*-- LM6.7 - Assemble complete plot file */
  
    proc catalog cat=graph_cat_hf et=grseg;
      copy out=graph_final;
      select GSLIDE;
    run;

    proc catalog cat=graph_cat et=grseg;
      copy out=graph_final;
      select TEMPLATE;
    run;

    /* Must scale main plot in X direction in order to keep it square */
    %local scale;
    %let scale=%sysevalf((&topy-&boty)/100);
        
        proc greplay igout = graph_final gout = final_out tc = tempcat nofs;
          tdef allofit
          1 / llx = 0  lly = &boty    lrx = 100  lry = &boty
              ulx = 0  uly = &topy    urx = 100  ury = &topy    
              scalex=&scale        
          
          2 / llx = 5  lly = 0        lrx = 95  lry = 0
              ulx = 5  uly = 100      urx = 95  ury = 100;

          template allofit;
          treplay 1:template 2:gslide;
          run;
        quit;
     
    proc catalog cat=graph_final kill;
    run; 
    
  /*----------------------------------------------------------------------*/ 
  /*-- LM6.8 - Convert PS to PDF, if reqd */
  
%if &plot_ext=ps
%then
  %do;
x ps2pdf &G_OUTFILE..ps &G_OUTFILE..&pdf_ext;
x rm &G_OUTFILE..ps;
  %end;

%mend lb8_graphics;

/************************************************************************/
/* Finally the rest of the main macro TD_LB8                            */
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
    
/* Declare some values used in axis construction - have to do this here as they are still
   required (for annotation purposes) even if we are using a user-supplied graphics options file */    
%global axissize_4 halfgap_4;   * Also used in annotations later;
%let axissize_4=1.33;       * Units are IN, but we want to do arithmetic with this;
%let halfgap_4=0.05;

/* Now we can actually start doing things... */

%if &InputUsage=C
%then
  %do;

  /*----------------------------------------------------------------------*/ 
  /*-- NP6 - Write template file if wanted */
  
      %put %str(RTN)OTE: &macroname: Creating template code file for input dataset; 
      %put %str(RTN)OTE: &macroname: No graph will be generated;       
      %lb8_write_template(usr_prof);
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
        %lb8_use_template(&InputFile); 
        %put %str(RTN)OTE: &macroname: Finished execution of user-supplied SAS code (dataset creation);
        %lb8_input_dataset(&tmp_dset);
      %end;
    %else
      %do;  
        %lb8_input_dataset(&InputDataset);
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
        %lb8_write_options(&writopts);
      %end;

  /*----------------------------------------------------------------------*/ 
  /*-- NP9 - Read options file and generate graphics if we need to */
    %if %length(&readopts) > 0 
    %then
      %do;
        %lb8_graphics(&readopts);
      %end;
%end;

  /*----------------------------------------------------------------------*/
  /*--NP10 - Tidy up and call tu_abort   */
  
  %tu_tidyup(rmdset=&prefix:, glbmac=NONE);
  %tu_abort;

%mend td_lb8;
