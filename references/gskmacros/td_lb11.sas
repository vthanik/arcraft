/*******************************************************************************
|
| Macro Name:      td_lb11
|
| Macro Version:   1 build 4
|
| SAS Version:     8.2
|                                                             
| Created By:      Bob Newman (Amadeus) 
|
| Date:            06 November 2006
|
| Macro Purpose:   To generate an LB11 plot
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
|  XaxisLabel       Label for X-axis                                 OPT      Week
|  YaxisLabel       Label for Y-axis                                 OPT      [BLANK]
|  HRefLines        Values for horizontal reference lines            OPT      [BLANK] 
|  TreatmentDataset Name of treatment data set                       OPT      [BLANK]
|  ProfilesPerPage  Number of profiles per page - 1, 2 or 4          REQ      4
|  LogBase          Log base for y-axis - 2, 10 or 0 (=linear)       OPT      [BLANK]
|  AxisRange        COMMON if same axes for all subjects,
|                   SUBJECT if subject-dependent                     REQ      COMMON
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
| (@) tu_order
| (@) tu_orderlog
| (@) tu_putglobals
| (@) tu_tidyup
| (@) tu_valparms
|
| Example:
| %td_lb11(InputDataset=myplot
|   , InputUsage=D
|   , XAxisLabel=Change in QTc msec  
|  );
|
|******************************************************************************
| Change Log
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     06-Nov-06
| New version/draft number: 01.001
| Modification ID:          RCN.01.001
| Reason For Modification:  Original version
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     07-Dec-06
| New version/draft number: 01.002
| Modification ID:          RCN.01.002
| Reason For Modification:  Change warning message when unnecessary treatment dataset supplied.  
|                           RTERROR when missing values in treatment dataset.
|                           Check for existence of treatment dataset (PV3).
|                           Check for creation of datasets by user-supplied template code (LM4).
|                           Fixed logic for case where PPP=2 or 4 and a single plot appears on the final page.
|                           (Where RANGE=SUBJECT and the last subject in the file is one for which
|                           no plot is generated, we had been plotting that empty plot rather than the
|                           non-empty one that was reqd. Now we get header and order all over again.)
|                           Modify SUBJECTS dataset so that header no longer includes SUBJID. (LM1.2).
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     12-Dec-06
| New version/draft number: 01.003
| Modification ID:          RCN.01.003
| Reason For Modification:  Only check for creation of treatment dataset by user-supplied template code when  
|                           a treatment dataset is in fact supposed to be created.
|                           At LM1.2, ensure variables STARTTRT and ENDTRT always present in main dataset,
|                           even when no treatment dataset supplied.
|                           At NP7, validate treatment dataset before input dataset. This is essential in order
|                           to detect some pathological conditions involving SUBJID.
|
| Modified By:              Bob Newman (Amadeus)
| Date of Modification:     19-Feb-07
| New version/draft number: 01.004
| Modification ID:          RCN.01.004
| Reason For Modification:  Modify layout, allowing more space for legend (LEGY=18 - was 12; TOPY=82 - was 85).  
|                           Output warning if more than 4 lab parameters.
|
                           More robust handling of PARAM strings from dataset - use %NRBQUOTE, %QSCAN, %QSUBSTR.
|
                           Also use double quotes when constructing 'TICK=' string.
|
| Modified By:
| Date of Modification:
| New version/draft number:
| Modification ID:
| Reason For Modification:
|
*******************************************************************************/
  
%macro td_lb11
      (
       InputDataset=                               /* type:ID Input dataset */,
       InputFile=                                  /* Name of file if InputUsage=C or U */,
       InputUsage=D                                /* Style of input data D=dataset C=create template U=use template */,
       OptionsFile=                                /* Name of file if OptionsFileUsage=C or U */,
       OptionsFileUsage=                           /* Style of options file C=create U=use blank=use default settings */,
       XAxisLabel=Week                             /* Horizontal axis label */,
       YAxisLabel=                                 /* Vertical axis label */,
       HRefLines=                                  /* Position of horizontal reference lines (data values) */,
       TreatmentDataset=                           /* type:ID Treatment dataset */,
       ProfilesPerPage=4                           /* Profiles per page (1, 2 or 4) */,
       LogBase=                                    /* Log base for y-axis (2 or 10, or 0 for a linear axis) */,
       AxisRange=COMMON                            /* COMMON if same axes for all subjects, SUBJECT if subject-dependent */
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
  %let XaxisLabel=%nrbquote(&XaxisLabel);
  %let YaxisLabel=%nrbquote(&YaxisLabel);
  %let InputFile=%nrbquote(&InputFile);
  %let InputUsage=%upcase(&InputUsage);
  %let InputUsage=%nrbquote(&InputUsage);
  %let OptionsFile=%nrbquote(&OptionsFile);
  %let OptionsFileUsage=%upcase(&OptionsFileUsage);
  %let OptionsFileUsage=%nrbquote(&OptionsFileUsage);
  %let HRefLines=%nrbquote(&HRefLines);
  %let TreatmentDataset=%nrbquote(&TreatmentDataset);
  %let ProfilesPerPage=%nrbquote(&ProfilesPerPage);
  %let LogBase=%nrbquote(&LogBase);
  %let AxisRange=%upcase(&AxisRange);
  %let AxisRange=%nrbquote(&AxisRange);
    
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
    
  %if &InputUsage=U and %length(%sysfunc(compbl(&InputDataset))) = 0
  %then
    %do;
       %put %str(RTE)RROR: &macroname: InputUsage=U but no InputDataset specified;
       %let pv_abort = 1;
       /* Dataset need not already exist - will be created by user-supplied SAS code */
    %end;
    
  %if &InputUsage=C
  %then
    %do;
      %if %length(&InputDataset) > 0
      %then
        %do;
          %put %str(RTW)ARNING: &macroname: InputDataset specified when InputUsage does not require it;
        %end;
    %end;      

  /*--PV3 - TREATMENT DATASET: check not specified when not needed */
  /* (Its use is always optional) */ 
  %if %length(&TreatmentDataset) > 0
  %then
    %do;
      /* If InputUsage=U, need not exist - will be created by user-supplied SAS code */
      %if &InputUsage=D
      %then
        %do;
          %tu_valparms(macroname = &macroname., chktype=dsetExists, pv_dsetin = TreatmentDataset, abortyn = N); 
        %end;
    
      %if &InputUsage=C
      %then
        %do;
          %put %str(RTW)ARNING: &macroname: TreatmentDataset specified when InputUsage does not require it;
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
    
  /*--PV8 - PROFILES PER PAGE: check it is 1, 2 or 4 */
  %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = ProfilesPerPage, valuelist = 1 2 4, abortyn = N);

  /*--PV9 - AXISRANGE: check it is COMMON or SUBJECT */
  %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = AxisRange, valuelist = COMMON SUBJECT, abortyn = N);

  /*--PV10 - LOGBASE: check it is 0 or 2 or 10 */
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
  /*-- LM1 - Define local macro LB11_Input_Dataset */
  
  /*  Processes user-supplied input dataset */
  /* (Validation and any necessary manipulation) */
  /* We create a dataset PLOT for use in the actual graphics. */

%macro lb11_input_dataset(dsname);

/* Lists of variable names, by data type, and all required */
%local charvars numvars mustvars byvars;
%let charvars=param cov1 cov2 cov3 cov4 cov5;
%let numvars=paramcd subjid xvar yvar; 
%let mustvars=&charvars &numvars;
/* List of variables which must be a unique n-tuple for each record */
%let byvars=paramcd subjid xvar;
%global dupvar;		* Variable to receive number of duplicates found;
  
  /*----------------------------------------------------------------------*/ 
  /*-- LM1.1 - Validation of dataset */
  
%local pv_abort; 
%let pv_abort=0;

/* Check existence of datasets */
%tu_valparms(
  abortyn=Y,
  macroname=lb11_input_dataset,
  chktype=dsetExists,
  pv_dsetin=dsname
  );
/* Check presence of variables */
%tu_valparms(
  abortyn=N,
  macroname=lb11_input_dataset,
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
        macroname=lb11_input_dataset,
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
        macroname=lb11_input_dataset,
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
  
  /* If there is a treatment dataset, append it. This will yield records with YVAR=. and PARAMCD=.,
     but ensure that the x-axis can accommodate the full range used by the treatment data
     - which might be wider than that used by the main dataset */
  data &prefix._treated;
    length starttrt endtrt 8;
    set &dsname
    %if %length(&TreatmentDataset) > 0
    %then
      %do;
        &TreatmentDataset;
      %end;
      ;
  run;
  
  proc sort data=&prefix._treated out=&prefix._sort1;
    by subjid paramcd xvar;
  run;

  /* Create a table of the meaningful PARAM/PARAMCD pairs */  
  proc sql noprint;
    create table &prefix._params as
      select param, paramcd, count(*) as freq
        from &prefix._sort1(where=(yvar ne .))
        group by param, paramcd
        order by paramcd;
  quit;

  /* Create a table of the SUBJID values and related covariates */   
  proc sql noprint;
    create table &prefix._subjraw as
      select subjid, cov1, cov2, cov3, cov4, cov5, count(*) as freq
        from &prefix._sort1(where=(paramcd ne .))
        group by subjid, cov1, cov2, cov3, cov4, cov5
        order by subjid;
    * Now a cartesian product of subjects and parameters;    
    create table &prefix._cartesian as
      select param, paramcd, subjid 
        from &prefix._params, &prefix._subjraw;
  quit;
  
  /* Create a dummy record for each possible combination of subject and lab parameter */
  data &prefix._gimmick;
    set &prefix._cartesian;
    xvar=.;
    yvar=.;
  run;
  
  /* Append this to the main dataset and re-sort.
     This will ensure use of symbols is consistent even for subjects where not all lab params have data */
  data &prefix._full;
    set &prefix._sort1 &prefix._gimmick;
  run;
  
  proc sort data=&prefix._full out=&prefix._sorted;
    by subjid paramcd xvar;
  run;    

  /* Create a subjects table containing the headers we need for the individual plots */   
  data &prefix._subjects;
    length subjhead $120;
    set &prefix._subjraw;
    subjord=_N_;
 ***   subjhead=trim(left(put(subjid,best12.))) || ' ' || trim(cov1) || ' ' || trim(cov2) 
                        || ' ' || trim(cov3) || ' ' || trim(cov4) || ' ' || trim(cov5);
    subjhead=trim(cov1) || ' ' || trim(cov2) 
                        || ' ' || trim(cov3) || ' ' || trim(cov4) || ' ' || trim(cov5);
    keep subjord subjid subjhead;
  run;
  
  data &prefix._paramqt;
    length paramqt $122;
    set &prefix._params;
    paramqt="'" || trim(param) || "'";
  run;
  
  %global parmlist;   * Needed for tu_cr8glegend;
  proc sql noprint;
    select paramqt into :parmlist separated by ' ' from &prefix._paramqt;
  quit;

/* Subsequent code must be careful about using PLOT or NONULLS dataset.
  PLOT should be used for determining axis limits, NONULLS for actual plotting */ 
  
  data &prefix._plot;
    set &prefix._sorted;
    by subjid paramcd;    
  run;
  
  data &prefix._nonulls;
    set &prefix._sorted(where=(paramcd ne .));
    by subjid paramcd;
  run;

  /*----------------------------------------------------------------------*/ 
  /*-- LM1.3 - Derive some useful data-dependent macro variables */

%global numparms;	* Number of different treatments;
%global x_order;    * ORDER statement for inclusion in an AXIS statement for X-axis;
%global y_order;    * ORDER statement for inclusion in an AXIS statement for Y-axis;
%local trouble parmlist;

  proc sql noprint;
    select count(distinct paramcd) into :numparms from &prefix._plot;
	create table &prefix._parmtab as
	  select distinct param,paramcd from &prefix._plot order by paramcd;
	select count(*) into :trouble from &prefix._parmtab
	  where param like "%|%";
	select param into :parmlist separated by "|" from &prefix._parmtab;
  quit;

%let parmlist=%nrbquote(&parmlist);

%if &trouble > 0
%then
  %do;
    %put %str(RTW)ARNING: &macroname: "|" character found in parameter labels - check legend;
  %end;

%if &numparms > 4
%then
  %do;
    %put %str(RTW)ARNING: &macroname: More than 4 lab parameters - plot may overlap legend. Increase LEGY if necessary.;
  %end;

  /*----------------------------------------------------------------------*/ 
  /*-- LM1.4 Derive macro variables containing LEGEND strings */

%local legvalue i thisparm;
%let legvalue=;
%do i=1 %to &numparms;
  /* Have one LEGVAL var per parameter - one big string might get too long*/
  %let thisparm=%qscan(&parmlist,&i,|);
  /* We truncate each parameter label at 60. A few more characters are possible, but not many. */
  /*  With 70-odd, the text will not fit and you get no legend at all.*/
  /* There is a technique to get multi-line values in a legend. The users can do this */
  /* if they feel strongly about it. We will include a comment telling them how. */
  /* (Also possible for us to truncate more intelligently, but that would be a frill) */
  %if %length(&thisparm) > 60
  %then
    %do;
      %let thisparm=%qsubstr(&thisparm,1,60);
      %put %str(RTW)ARNING: &macroname: A long treatment name has been truncated in the legend; 
    %end; 
    /* "tick=" option is unnecessary but harmless and  */
    /* helpful if users want to modify options file to use multi-line text in their legend */
  %global legval&i;	* Treatment name, in a format
                      suitable for inclusion in a LEGEND statement;
  %let legval&i=%str( )tick=&i %str(%")&thisparm.%str(%" ) ;
%end;
  
  /*----------------------------------------------------------------------*/ 
  /*-- LM1.5 - Derive macro variables containing axis ORDER clauses */

%tu_order(macrovar=x_order
         ,dsetin=&prefix._plot
         ,varlist=xvar starttrt endtrt
         );
         
%if &logbase=0 
%then
  %do;
    %tu_order(macrovar=y_order
             ,dsetin=&prefix._plot
             ,varlist=yvar
             );
   %end;
%else
  %do;
    %tu_orderlog(macrovar=y_order
                ,dsetin=&prefix._plot
                ,varlist=yvar
                ,logbase=&logbase
                );
   %end;
 
%mend lb11_input_dataset;

  /*----------------------------------------------------------------------*/ 
  /*-- LM2 - Define local macro LB11_Treatment_Dataset */
  
%macro lb11_treatment_dataset(dsname);

/* Lists of variable names, by data type, and all required */
%local charvars numvars mustvars;
%let charvars=;
%let numvars=subjid starttrt endtrt; 
%let mustvars=&charvars &numvars;
  
  /*----------------------------------------------------------------------*/ 
  /*-- LM2.1 - Validation of dataset */
  
%local pv_abort; 
%let pv_abort=0;

/* Check existence of datasets */
%tu_valparms(
  abortyn=Y,
  macroname=lb11_treatment_dataset,
  chktype=dsetExists,
  pv_dsetin=dsname
  );
/* Check presence of variables */
%tu_valparms(
  abortyn=N,
  macroname=lb11_treatment_dataset,
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
        macroname=lb11_treatment_dataset,
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
        macroname=lb11_treatment_dataset,
        chktype=isNum,
        pv_dsetin=dsname,
        pv_varsin=thisvar
        );
      %let i=%eval(&i+1);
    %end;
  %end;

%if %eval(&g_abort + &pv_abort) = 0
%then
  %do;
    %local nullct;
    proc sql noprint;
      select count(*) into :nullct from &dsname
        where (starttrt=. and endtrt ne .)
           or (endtrt=. and starttrt ne .);
    quit;
    %if &nullct > 0
    %then
      %do;
        %put %str(RTE)RROR: &macroname: Treatment dataset contains null values;
        %let pv_abort=1;
      %end;
  %end;
  
/*----------------------------------------------------------------------*/
  /*- complete dataset validation */
  %if %eval(&g_abort. + &pv_abort.) gt 0 %then %do;
    %put %str(RTE)RROR: &macroname: Macro has failed treatment dataset validation check for reasons stated with %str(RTE)RRORs above;
    %tu_abort(option=force);
  %end;
  /*----------------------------------------------------------------------*/

%mend lb11_treatment_dataset;  
  
  
  /*----------------------------------------------------------------------*/ 
  /*-- LM3 - Define local macro LB11_Write_template */
 
   /* Provides user with a SAS code template for the required input dataset */

%macro lb11_write_template(fnam);

/* NB All quotes to be generated must be preceded by "%", whether matched or not. */

data _null_;
  file &fnam;

%tu_cr8proghead(macname=create_lb11_example_datasets, macdesign=SAS_datastep_not_a_macro);
* Second param above is not validated but cannot be more than one word, apparently;

put " ";
put "%nrstr(data work.lb11_example_dataset;)";
put "%nrstr(* Data set must include at least these 10 variables;)";
put "%nrstr(  attrib)";
put "%nrstr(    param    length=$120 label=%"Laboratory parameter label to appear in the legend%")";
put "%nrstr(    paramcd  length=8    label=%"Laboratory parameter code to order the legend%")";
put "%nrstr(    subjid   length=8    label=%"Subject number%")";
put "%nrstr(    xvar     length=8    label=%"Variable to be plotted against X-axis e.g. day on study%")";
put "%nrstr(    yvar     length=8    label=%"Variable to be plotted against Y-axis e.g. LFT value%")";
put "%nrstr(    cov1     length=$120 label=%"First profile label for header e.g. Study number%")";
put "%nrstr(    cov2     length=$120 label=%"Second profile label for header e.g. Treatment%")";
put "%nrstr(    cov3     length=$120 label=%"Third profile label for header e.g. Race%")";
put "%nrstr(    cov4     length=$120 label=%"Fourth profile label for header e.g. Sex%")";
put "%nrstr(    cov5     length=$120 label=%"Fifth profile label for header e.g. Age = nn%")";
put "%nrstr(  ;)"; 
put "%nrstr(run;)";

put " ";
put "%nrstr(data work.lb11_treatment_dataset;)";
put "%nrstr(* Data set is optional. If used, must include at least these 3 variables;)";
put "%nrstr(  attrib)";
put "%nrstr(    subjid   length=8    label=%"Subject number%")";
put "%nrstr(    starttrt length=8    label=%"Numeric variable for X-axis e.g. start day for treatment period%")";
put "%nrstr(    endtrt   length=8    label=%"Numeric variable for X-axis e.g. end day for treatment period%")";
put "%nrstr(  ;)"; 
put "%nrstr(run;)";

run;

%mend lb11_write_template;

  /*----------------------------------------------------------------------*/ 
  /*-- LM4 - Define local macro LB11_Use_template */

  /* Uses an input template for the input dataset */

%macro lb11_use_template(filespec);

  %global tmp_dset;

  %include "&filespec";

* Check required datasets have been created;
  %tu_valparms(macroname = &macroname., chktype=dsetExists, pv_dsetin = InputDataset, abortyn = N); 
  %if %length(%sysfunc(compbl(&TreatmentDataset))) > 0
  %then
    %do;
      %tu_valparms(macroname = &macroname., chktype=dsetExists, pv_dsetin = TreatmentDataset, abortyn = N);
    %end; 

  %if &pv_abort > 0
  %then
    %do;
     %put %str(RTE)RROR: &macroname: User-supplied template code failed to create specified datasets - see %str(RTE)RRORs above;
     %tu_abort(option=force);
  %end;

%mend lb11_use_template;

  /*----------------------------------------------------------------------*/ 
  /*-- LM5 - Define local macro LB11_Write_Options */

   /* Provides user with source code for standard graphics options  */
   /* (data dependent) */

%macro lb11_write_options(fnam);

  /*----------------------------------------------------------------------*/ 
  /*-- LM5.1 - Determine whether we are generating PS-to-PDF output */
  
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
  /*-- LM5.2 - Generate preamble in graphics options file */
  
data _null_;
  file &fnam;

%tu_cr8proghead(macname=lb11_graphics_options, macdesign=SAS_code_not_a_macro);
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
  /*-- LM5.3 - Generate GOPTIONS statement */
  
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
put "%nrstr(  htitle  = 4 pct)";
put "%nrstr(;)";
put " ";

  /*----------------------------------------------------------------------*/ 
  /*-- LM5.4 - Generate LEGEND statement */

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
%do i=1 %to &numparms; 
    "&&&legval&i" 
%end;
"%nrstr(%);)";
put " ";

  /*----------------------------------------------------------------------*/ 
  /*-- LM5.5 - Generate AXIS statements */

%local offset;
%let offset=;  
%if %length(&TreatmentDataset) > 0
%then
  %do;
    %let offset=offset=(10 PCT,2 PCT);
  %end;
  
put "/" "%nrstr(* Set the axis details *)" "/";
put "/" "%nrstr(* WIDTH option here determines thickness of frame around plot area *)" "/";
put "/" "%nrstr(* OFFSET option reserves space at bottom of y-axis for plotting treatment data %(if used%). *)" "/";
put "/" "%nrstr(* You may alter the OFFSET but the units must always be explicitly PCT. *)" "/";
put "/" "%nrstr(* AXIS3 and AXIS4 have blank labels and are used as appropriate when ProfilesPerPage=2 or 4. *)" "/";
put "/" "%nrstr(* OFFSET values in AXIS1 and AXIS3 should correspond. *)" "/";
put "/" "%nrstr(* When AxisRange=SUBJECT, axis definitions include %"&x_order%" and %"&y_order%" so that. *)" "/";
put "/" "%nrstr(* data-dependent values are substituted in for each plot. *)" "/";
put "%nrstr(axis1 c=black width=5)" " &offset " 
%if &AxisRange=COMMON
%then
  %do;
    " &y_order "
  %end;
%else
  %do;
    "%nrstr( &y_order )"
  %end; 
"%nrstr(label=%(angle=90 h=18pt %")"
%if %length(%nrbquote(%sysfunc(compbl(&YAxisLabel)))) > 0
%then
  %do; 
    "&YAxisLabel"
  %end; 
"%nrstr(%"%) value=%(h=12pt%);)";
put "%nrstr(axis2 c=black width=5)"
%if &AxisRange=COMMON
%then
  %do; 
    " &x_order "
  %end;
%else
  %do; 
    "%nrstr( &x_order )"
  %end; 
"%nrstr(minor=none label=%(h=18pt %")" 
%if %length(%nrbquote(%sysfunc(compbl(&XAxisLabel)))) > 0
%then
  %do; 
    "&XAxisLabel"
  %end; 
"%nrstr(%"%) value=%(h=12pt%);)";
* Axes 3 and 4 have blank label;
put "%nrstr(axis3 c=black width=5)" " &offset " 
%if &AxisRange=COMMON
%then
  %do;
    " &y_order "
  %end;
%else
  %do;
    "%nrstr( &y_order )"
  %end; 
"%nrstr(label=%(angle=90 h=18pt %" %"%) value=%(h=12pt%);)";
put "%nrstr(axis4 c=black width=5)"
%if &AxisRange=COMMON
%then
  %do; 
    " &x_order "
  %end;
%else
  %do; 
    "%nrstr( &x_order )"
  %end; 
"%nrstr(minor=none label=%(h=18pt %" %"%) value=%(h=12pt%);)";
put " ";

  /*----------------------------------------------------------------------*/ 
  /*-- LM5.6 - Generate SYMBOL statements */
  
put "/" "%nrstr(* Set Symbols. *)" "/";
put "/" "%nrstr(* Use of any other INTERPOL option would change the essence of the plot *)" "/";
put "%nrstr(symbol1 color=red                value=dot    height=1.5  width=5 line=1  interpol=join;)";
put "%nrstr(symbol2 color=blue   font=marker value= %'U%' height=1    width=5 line=3  interpol=join;)";
%if &numparms > 2
%then
  %do;
put "%nrstr(symbol3 color=green  font=marker value= %'C%' height=1    width=8 line=8  interpol=join;)";
  %end;
%if &numparms > 3
%then
  %do;
put "%nrstr(symbol4 color=black  font=marker value= %'V%' height=1    width=5 line=33  interpol=join;)";
  %end;
%if &numparms > 4
%then
  %do;
put "%nrstr(symbol5 color=cyan   font=marker value= %'P%' height=1    width=5 line=30 interpol=join;)";
  %end;
%if &numparms > 5
%then
  %do;
put "%nrstr(symbol6 color=violet font=marker value= %'D%' height=1    width=5 line=2 interpol=join;)";
  %end;
%if &numparms > 6
%then
  %do;
put "%nrstr(symbol7 color=orange font=marker value= %'M%' height=1    width=5 line=14 interpol=join;)";
  %end;
%if &numparms > 7
%then
  %do;
put "%nrstr(symbol8 color=steel  font=marker value= %'N%' height=1    width=5 line=43 interpol=join;)";
  %end;
%if &numparms > 8
%then
  %do;
put "/" "%nrstr(* Only 8 symbols for plots are defined automatically - *)" "/" ;
put "/" "%nrstr(* please define SYMBOL9 etc as required by your data *)" "/" ; 
  %end;

put "/" "%nrstr(* SYMBOL99 is relevant only when a treatment dataset is in use. *)" "/" ;
put "/" "%nrstr(* The TD_LB11 macro uses its COLOR, WIDTH and LINE attributes when plotting the treatment profile. *)" "/" ;
put "/" "%nrstr(* No other attributes specified for SYMBOL99 will have any effect. *)" "/" ; 
put "/" "%nrstr(* Colour CXE0E0E0 is the RGB spec of a very light grey. *)" "/" ; 
put "/" "%nrstr(* The lightest grey SAS has a name for is LTGRAY %(=CXC0C0C0%). CXFFFFFF is white. *)" "/" ; 
put "%nrstr(symbol99 color=LTGRAY width=80 line=1;)";

run;

%mend lb11_write_options;



  /*----------------------------------------------------------------------*/ 
  /*-- LM6 - Define local macro LB11_OnePlot */
  /* Called only from LB11_Graphics (which follows) */
  /* Generates plot for a single subject */
  
%macro lb11_OnePlot(id, header, cat, entry, xaxis=, yaxis=);

/* No legend used here - we use a separate graphics entry for that */

/* First generate annotate dataset for treatment line, if reqd */

%local annostr;
%let annostr=;
%if %length(&TreatmentDataset) > 0
%then
  %do;
    %if %tu_nobs(&prefix._thistrt) > 0
    %then
      %do;
        %let annostr=annotate=&prefix._trtanno;
        %annomac;
        data &prefix._trtanno;
          %dclanno;
          length text $120;
          set &prefix._thistrt;
          %system(1,1,4);     * X, Y: %data area;
          %move(0,0);
          %system(2,1,4);     * X: data values, Y: %data area;
          %move(0,&trt_ypos);
          %move(starttrt,&trt_ypos);
          x=endtrt;
          color="&trt_col";
          style=&trt_line;
          size=&trt_width;
          function="DRAW";
          output;
          %system(1,1,4);     * X, Y: %data area;
          %label(0,&trt_ypos," &trt_txt",black,.,.,.,&ourfont,6);
        run;
      %end;
    %end;

title1 "&header";

proc gplot data=work.&prefix._thisplot &annostr gout=&cat;
     plot yvar * xvar=paramcd
    / haxis=&xaxis vaxis=&yaxis nolegend name="&entry" &reflines;
run;
quit;

title1;

%mend lb11_OnePlot;  
  
  /*----------------------------------------------------------------------*/ 
  /*-- LM7 - Define local macro LB11_Graphics */

  /* Generates graphics, using the specified graphics options file */


%macro lb11_graphics(filespec);

/* Do not use RESET=ALL - incompatible with ts_setup */
  GOPTIONS reset=goptions;

  /*----------------------------------------------------------------------*/ 
  /*-- LM7.0 - Define macro variables for PROC GREPLAY template */
  
   /* NB template is fixed at the moment */
   /* Extra headers and footers are liable to overlay main plot */ 
   /* With macro vars declared here, user can override them in options file */
   /* TOPY and BOTY have different defaults from other plot macros, due to presence of legend */
   /* LEGY reserves space for the legend. */
%local topy boty legy;   
%let topy=82;
%let boty=0;
%let legy=18;

  /*-- Define macro variables for treatment plot */
%local trt_ymul;        /* This is the position of the line, as a proportion of the axis offset */
%global trt_txt;         /* Text to display to the left of the treatment line */
%let trt_ymul=0.5;
%let trt_txt=Treatment period;

  /* Define macro variables for reference lines */
%local refcolor refstyle;
%let refcolor=green;
%let refstyle=1;

  /* Save value of HTITLE option before adopting user-specified value.
     User-specified value will apply to titles above each individual plot.
     We restore to original value before generating header/footer with tu_cr8gheadfoots */
%local titsize;
%let titsize=%sysfunc(getoption(htitle));
    
  /*----------------------------------------------------------------------*/ 
  /*-- LM7.1 - Read options file */
  
/* This could be a user-supplied one, or it could be */
/* one we have just written out for ourselves */

/* If AxisRange=COMMON, this is the only time we read it */
 
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
  /*-- LM7.2 - Determine extension for plot file, and specify plot file name */
  
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
  /*-- LM7.3 - Generate options string for reference lines */

  /* Beware possible confusion here! */
  /* This macros parameter HRefLines refers to reference lines that run horizontally */
  /* But GPLOT options HREF, CHREF, LHREF relate to lines PERPENDICULAR TO horizontal axis */
  /* Similarly with "vertical" parameter and options */
  %local reflines;
  %let reflines=;
  %if %length(%nrbquote(%sysfunc(compbl(&HRefLines)))) > 0
  %then
    %do;
      %let reflines=&reflines cvref=&refcolor lvref=&refstyle vref=&HRefLines ;
      /* Oddly, some line styles do not come out as advertised. 35 is recommended here */
      /* 34 was better for other plot macros. Very mysterious. */ 
    %end;
    
  /*----------------------------------------------------------------------*/ 
  /*-- LM7.4 - Get global parameters for treatment annotations */

%global trt_ypos trt_col trt_line trt_width;
%local trt_yval;        /* Value from AXIS OFFSET. TRT_YPOS is a proportion of this */
                        /* Proportion is TRT_YMUL, which can be set by the user in the options file */

%if %length(&TreatmentDataset) > 0
%then
  %do;
    /* Default values which we expect always to override */
    %let trt_ypos=3.5;
    %let trt_col=ltgray;
    %let trt_line=1;
    %let trt_width=80;

* Extract values from axis statements and symbol statements;
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
            bktpos=index(offsetstr,"%nrstr(%()");  * Locate '(';
            offsetstr=substr(offsetstr,bktpos+1);
            offunit=scan(offsetstr,2);         * The units it is expressed in ;
            if offunit ne 'PCT'
            then
              offmsg='Axis OFFSET units must be explicitly PCT';
            else
              do;
                trt_yval=scan(offsetstr,1);      * The number we need ;
                if trt_yval <= 0 or trt_yval >= 100
                  then
                    offmsg='Axis OFFSET must be between 0 and 100';
                  else
                    call symput('trt_yval',trt_yval);    
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
        
      %let trt_ypos=%sysevalf(&trt_ymul*&trt_yval);   * Position treatment line in middle of y-axis offset;

/* Now analyse SYMBOL99 to get colour, line style and width */
 
      %tu_getgstatements(
         dsetout=&prefix._syminfo,
         statements=SYMBOL
         );
  
      data _null_;
        set &prefix._syminfo(where=(name='SYMBOL99'));
        colpos=index(text,'CI');   * We see CI etc here even though options file may say "COLOR=";   
        if colpos > 0 
        then
          do;
            colstr=substr(text,colpos+2);
            trt_col=scan(colstr,1,' =');
            if length(trt_col) > 0
            then
              call symput('trt_col',trt_col);
          end;
        * Apparently when LINE=1 is specified in options file, this is omitted from the AXIS statement returned
        * by TU_GETGSTATEMENTS - presumably because it is the default; 
        linpos=index(text,'LINE');   
        if linpos > 0 
        then
          do;
            linstr=substr(text,linpos+4);
            trt_line=scan(linstr,1,' =');
            if length(trt_line) > 0
            then
              call symput('trt_line',trt_line);
          end;
        widpos=index(text,'WIDTH'); 
        if widpos > 0 
        then
          do;
            widstr=substr(text,widpos+5);
            trt_width=scan(widstr,1,' =');
            if length(trt_width) > 0
            then
              call symput('trt_width',trt_width);
          end;
      run;

 %end; 
 
  /*----------------------------------------------------------------------*/ 
  /*-- LM7.5 - Minor macros used in generating the main plot */

  /*----------------------------------------------------------------------*/ 
  /*-- LM7.5.1 - Macro LB11_GETHEADER to get title for this subject */

%global header subjid;  
%macro lb11_GetHeader(num);
  data _null_;
    set &prefix._subjects(where=(subjord=&num));
    call symput('header',subjhead);
    call symput('subjid',subjid);
  run;
%mend lb11_GetHeader;

  /*----------------------------------------------------------------------*/ 
  /*-- LM7.5.2 - Macro LB11_GETORDERS to generate plot dataset and get ORDER definitions for this subject */

%macro lb11_GetOrders(num,sid);
  %global orders_ok;
  %let orders_ok=Y;
  data &prefix._thislot;
    set &prefix._plot(where=(subjid=&sid));
  run;
  
  data &prefix._thisplot;
    set &prefix._thislot(where=(paramcd ne .));
  run;
  
  %if %length(&TreatmentDataset) > 0
  %then
    %do;
      data &prefix._thistrt;
        set &TreatmentDataset(where=(subjid=&sid));
      run;
    %end;
  /* If AxisRange is SUBJECT, this macro has no effect on axis ORDER specs */
  %if &AxisRange=SUBJECT
  %then
    %do;
      %local numx numy;
      proc sql noprint;
        select count(distinct xvar) into :numx from &prefix._thislot;
        select count(distinct yvar) into :numy from &prefix._thislot;
      quit;  
      %if &numx > 1 and &numy > 1
      %then
        %do;   
          %tu_order(macrovar=x_order
             ,dsetin=&prefix._thislot
             ,varlist=xvar starttrt endtrt
          );
          %if &logbase=0
          %then
            %do;
              %tu_order(macrovar=y_order
                 ,dsetin=&prefix._thislot
                 ,varlist=yvar
              );
            %end;
          %else
            %do;
              %tu_orderlog(macrovar=y_order
                    ,dsetin=&prefix._thislot
                    ,varlist=yvar
                    ,logbase=&logbase
              );            
            %end;
          /* Now re-read options file, substituting new ORDERs into the AXIS statements */
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
        %end;
      %else
        %do;
          %put %str(RTW)ARNING: Insufficient data for subject &sid to determine axis range(s) - no plot generated;
          %let orders_ok=N;          
        %end; 
    %end;  
%mend lb11_GetOrders;

  /*----------------------------------------------------------------------*/ 
  /*-- LM7.6 - Generate the main plot */

%local x13right x24left y1bot y2top;
%let x13right=50;
%let x24left=50;
%let y1bot=50;
%let y2top=50;

%local s;         /* Subject number (ordinal) */
%local sfmt;      /* Same, as 6 digits with leading zeroes */
%local p;         /* Subject number (ordinal) */
%local pfmt;      /* Same, as 6 digits with leading zeroes */
%local plotname;
%local xaxis yaxis;
%local last1 last2 last3 last4;

%let n_in_page=1; /* Number of plot within current page - can only ever be 1, 2, 3 or 4 */
%local firstcat;  /* Catalogue into which we initially write the plots */
%if &ProfilesPerPage=1
%then
  %do;
    %let firstcat=graph_cat;
    %let xaxis=axis2;
    %let yaxis=axis1;
  %end;
%if &ProfilesPerPage=2
%then
  %do;
    %let firstcat=temp_cat;
    %let xaxis=axis4;
    %let yaxis=axis1;
  %end;
%if &ProfilesPerPage=4
%then
  %do;
    %let firstcat=temp_cat;
    %let xaxis=axis4;
    %let yaxis=axis1;
  %end;

%let p=1;         /* First page */

/* Main loop executed once per subject */
                  
%do s=1 %to %tu_nobs(&prefix._subjects);

  %let sfmt=%sysfunc(putn(&p,z6.));
  %lb11_GetHeader(&s);
  %lb11_GetOrders(&s,&subjid);
  %if &orders_ok=Y
  %then
    %do;
      %if &ProfilesPerPage=1
      %then
        %do;
          %let plotname=p&sfmt;
        %end;
      %else
        %do;
          %let plotname=p&n_in_page.p;
        %end;
      %let last&n_in_page=&s;         * Save subject number in case incomplete last page;
/* Plot this subject */
      %lb11_OnePlot(&subjid,&header,&firstcat,&plotname,xaxis=&xaxis,yaxis=&yaxis);
/* Prepare to plot next subject */      
      %let n_in_page=%eval(&n_in_page+1);
      %if &ProfilesPerPage=2
      %then
        %do;
          %if &n_in_page=2
          %then
            %do;
              %let xaxis=axis2;
            %end;
          %else
            %do;
              %let xaxis=axis4;
            %end;
        %end;
      %if &ProfilesPerPage=4
      %then
        %do;
          %if &n_in_page=3 or &n_in_page=4
          %then
            %do;
              %let xaxis=axis2;
            %end;
          %else
            %do;
              %let xaxis=axis4;
            %end;
          %if &n_in_page=2 or &n_in_page=4
          %then
            %do;
              %let yaxis=axis3;
            %end;
          %else
            %do;
              %let yaxis=axis1;
            %end;
        %end;
      %if &n_in_page > &ProfilesPerPage
        %then
          %do;
/* All plots for current page have been generated. For 2 or 4 per page, must now put them together */
            %let n_in_page=1;        /* Reset ready for next page */
            %let pfmt=%sysfunc(putn(&p,z6.));
            %let p=%eval(&p+1);      /* Number of next page (if any) */
            %if &ProfilesPerPage=2
            %then
              %do;
                /* Have to narrow plot a bit otherwise numbers and tickmarks on x-axis interfere when SAS squeezes */
                /* Could make x2_min an "undocumented parameter" */
                %local x2_min x2_max;
                %let x2_min=20;
                %let x2_max=%sysevalf(100-&x2_min);
                proc greplay igout = temp_cat gout = graph_cat tc = tempcat nofs;
                  tdef pageof2

                1 / llx = &x2_min  lly = &y1bot   lrx = &x2_max  lry = &y1bot
                    ulx = &x2_min  uly = 100      urx = &x2_max  ury = 100

                2 / llx = &x2_min  lly = 0        lrx = &x2_max  lry = 0
                    ulx = &x2_min  uly = &y2top   urx = &x2_max  ury = &y2top;

                  template pageof2;
                  treplay 1:p1p 2:p2p;
                  run;
                quit;
                /* Empty temporary catalogue ready for next page */
                proc catalog catalog=temp_cat kill;
                run;
                /* Contents for debugging only */
                proc catalog catalog=graph_cat entrytype=grseg;
                  change template=t&pfmt;
                run;
              %end;
            %if &ProfilesPerPage=4
            %then
              %do;
                proc greplay igout = temp_cat gout = graph_cat tc = tempcat nofs;
                  tdef pageof4

                1 / llx = 0         lly = &y1bot   lrx = &x13right  lry = &y1bot
                    ulx = 0         uly = 100      urx = &x13right  ury = 100

                2 / llx = &x24left  lly = &y1bot   lrx = 100        lry = &y1bot
                    ulx = &x24left  uly = 100      urx = 100        ury = 100

                3 / llx = 0         lly = 0        lrx = &x13right  lry = 0
                    ulx = 0         uly = &y2top   urx = &x13right  ury = &y2top

                4 / llx = &x24left  lly = 0        lrx = 100        lry = 0
                    ulx = &x24left  uly = &y2top   urx = 100        ury = &y2top;

                  template pageof4;
                  treplay 1:p1p 2:p2p 3:p3p 4:p4p;
                  run;
                quit;
                /* Empty temporary catalogue ready for next page */
                proc catalog catalog=temp_cat kill;
                run;
                /* Contents for debugging only */
                proc catalog catalog=graph_cat entrytype=grseg;
                  change template=t&pfmt;
                run;
              %end;
        %end;
    %end;
%end;
%if &n_in_page > 1
%then
  %do;
    /* Messy stuff for incomplete final page */
    %let pfmt=%sysfunc(putn(&p,z6.));
    %let p=%eval(&p+1);   * For compatibility with case where all pages are full;
    /* Empty temporary catalogue ready for re-runs */
    %if &ProfilesPerPage > 1
    %then
      %do;
        proc catalog catalog=temp_cat kill;
        run;
      %end;
    /* Deal with incomplete last page */
    /* All plots need to be rerun because choice of axes will have been wrong */
    /* Must Get_orders etc again in case RANGE=SUBJECT and there have been empty plots skipped */
 %if &ProfilesPerPage=2
    %then
      %do;
        %let s=&last1;
        %lb11_GetHeader(&s);
        %lb11_GetOrders(&s,&subjid);
        %let xaxis=axis2; 
        %let yaxis=axis1;
        %let plotname=p1p;
        %lb11_OnePlot(&subjid,&header,&firstcat,&plotname,xaxis=&xaxis,yaxis=&yaxis);        
        proc greplay igout = temp_cat gout = graph_cat tc = tempcat nofs;
          template pageof2;
          treplay 1:p1p 2:p2p;
          run;
        quit;
        /* Contents for debugging only */
        proc catalog catalog=graph_cat entrytype=grseg;
          change template=t&pfmt;
       run;
      %end;
    %if &ProfilesPerPage=4
    %then
      %do;
        %if &n_in_page = 2
        %then
          %do;
            /* Only 1 plot on final page */
            %let s=&last1;
            %lb11_GetHeader(&s);
            %lb11_GetOrders(&s,&subjid);
            %let xaxis=axis2; 
            %let yaxis=axis1;
            %let plotname=p1p;
            %lb11_OnePlot(&subjid,&header,&firstcat,&plotname,xaxis=&xaxis,yaxis=&yaxis);        
          %end;
        %if &n_in_page = 3
        %then
          %do;
            /* Only 2 plots on final page */
            %let s=&last1;
            %lb11_GetHeader(&s);
            %lb11_GetOrders(&s,&subjid);
            %let xaxis=axis2;
            %let yaxis=axis1;
            %let plotname=p1p;
            %lb11_OnePlot(&subjid,&header,&firstcat,&plotname,xaxis=&xaxis,yaxis=&yaxis);        
            %let s=&last2;
            %lb11_GetHeader(&s);
            %lb11_GetOrders(&s,&subjid);
            %let xaxis=axis2;
            %let yaxis=axis3;
            %let plotname=p2p;
            %lb11_OnePlot(&subjid,&header,&firstcat,&plotname,xaxis=&xaxis,yaxis=&yaxis);                   
          %end;
        %if &n_in_page = 4
        %then
          %do;
            /* Only 3 plots on final page */
            %let s=&last1;
            %lb11_GetHeader(&s);
            %lb11_GetOrders(&s,&subjid);
            %let xaxis=axis4;
            %let yaxis=axis1;
            %let plotname=p1p;
            %lb11_OnePlot(&subjid,&header,&firstcat,&plotname,xaxis=&xaxis,yaxis=&yaxis);        
            %let s=&last2;
            %lb11_GetHeader(&s);
            %lb11_GetOrders(&s,&subjid);
            %let xaxis=axis2;
            %let yaxis=axis3;
            %let plotname=p2p;
            %lb11_OnePlot(&subjid,&header,&firstcat,&plotname,xaxis=&xaxis,yaxis=&yaxis);                   
            %let s=&last3;
            %lb11_GetHeader(&s);
            %lb11_GetOrders(&s,&subjid);
            %let xaxis=axis2;
            %let yaxis=axis1;
            %let plotname=p3p;
            %lb11_OnePlot(&subjid,&header,&firstcat,&plotname,xaxis=&xaxis,yaxis=&yaxis);                               
          %end;
        proc greplay igout = temp_cat gout = graph_cat tc = tempcat nofs;
          template pageof4;
          treplay 1:p1p 2:p2p 3:p3p 4:p4p;
          run;
        quit;
        /* Contents for debugging only */
        proc catalog catalog=graph_cat entrytype=grseg;
          change template=t&pfmt;
        run;
      %end;
  %end;
  
  /*----------------------------------------------------------------------*/ 
  /*-- LM7.7 - Generate plot header and footer as GSLIDE graphics */
  
/* restore HTITLE value saved long ago, and since overridden by the graphics options file */
goptions htitle=&titsize;

%tu_cr8gheadfoots(gout    = graph_cat_hf,
                  kill    = y,
                  pagecat = graph_cat,
                  font    = &ourfont,
                  ptsize  = 8);
                  
   /*----------------------------------------------------------------------*/ 
  /*-- LM7.8 -  Set file extension */

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
  /*-- LM7.9 - Generate LEGEND graphics entry */
  /* This uses the same technique as TU_CR8GLEGEND, but that "utility" macro is no use to us
     since it will not order the legend correctly in all cases */
  
 goptions ctitle=white cby=white;

 axis5 
        order=(-999 to -998 by 1) /* Avoid any plot points showing */
        color=white;              /* Make the axis white */

 axis6 
        order=(-999 to -998 by 1) /* Avoid any plot points showing */
        color=white;            /* Make the axis white */

 proc gplot data=&prefix._nonulls gout=leg_cat;
      plot yvar * xvar=paramcd
         / 
         legend=legend1 name="legend" vaxis=axis5 haxis=axis6;
 run;
  /*----------------------------------------------------------------------*/ 
  /*-- LM7.10 - Assemble complete plot file */
/***************************************************************************************** 
   Now we cannot use tu_templates because it gives us no control over the width of the plots displayed,
   and altering it is obviously impossible. So we have to replay stuff for ourselves.
    
   At this stage we have 
     entries T000001, T000002 etc in GRAPH_CAT, containing the main plots 
       (if in pairs or in fours), OR
     entries P000001, P000002 etc in GRAPH_CAT, containing the main plots 
       (if only 1 per page),       
     entry LEGEND in LEG_CAT containing a legend common to all plots, and
     entries GSLIDE, GSLIDE1, GSLIDE2 etc in GRAPH_CAT_HF containing headers and footers
       (the same number of entries as there are in GRAPH_CAT, but less conveniently named)

   Now we have a loop executed once per page which copies a suitable triplet into catalogue
   GRAPH_FINAL and replays them.       
*******************************************************************************************/

  %do i=1 %to %eval(&p-1);
  
    %let hfname=GSLIDE;
    %if &i > 1
    %then
      %do;
        GOPTIONS gsfmode=append;
        %let hfname=GSLIDE%eval(&i-1);
        %if &i > 100
        %then
          %do;
          /* First 100 entries all have names beginning with GSLIDE, but there is an 8 character limit.
             So 101st is called GSLID100, 1001st is GSLI1000, etc */
            %local ilen glen;
            %let ilen=%length(%eval(&i-1));
            %let glen=%eval(8-&ilen);
            %let hfname=%substr(GSLIDE,1,&glen)%eval(&i-1);
          %end;
      %end;
    %if &ProfilesPerPage=1
    %then
      %do;
        %let plname=P%sysfunc(putn(&i,z6.));
      %end;
    %else
      %do;
        %let plname=T%sysfunc(putn(&i,z6.));
      %end;      
     
    proc catalog cat=graph_cat_hf et=grseg;
      copy out=graph_final;
      select &hfname;
    run;

    proc catalog cat=graph_cat et=grseg;
      copy out=graph_final;
      select &plname;
    run;
    
    proc catalog cat=leg_cat et=grseg;
      copy out=graph_final;
    run;

    %let legtop=%sysevalf(&boty+&legy);
    
    proc greplay igout = graph_final gout = final_out tc = tempcat nofs;
      tdef temp3

      1 / llx = 5  lly = &legtop  lrx = 95  lry = &legtop
          ulx = 5  uly = &topy    urx = 95  ury = &topy    
          clip

      2 / llx = 5  lly = &boty    lrx = 95  lry = &boty
          ulx = 5  uly = &topy    urx = 95  ury = &topy

      3 / llx = 5  lly = 0        lrx = 95  lry = 0
          ulx = 5  uly = 100      urx = 95  ury = 100;

      template temp3;
      treplay 1:&plname 2:legend 3:&hfname;
      run;
    quit;
    
    proc catalog cat=graph_final kill;
    run;

  %end;   
    
  /*----------------------------------------------------------------------*/ 
  /*-- LM7.11 - Convert PS to PDF, if reqd */
  
%if &plot_ext=ps
%then
  %do;
x ps2pdf &G_OUTFILE..ps &G_OUTFILE..&pdf_ext;
x rm &G_OUTFILE..ps;
  %end;

%mend lb11_graphics;

/************************************************************************/
/* Finally the rest of the main macro TD_LB11                           */
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
      %lb11_write_template(usr_prof);
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
        %lb11_use_template(&InputFile); 
        %put %str(RTN)OTE: &macroname: Finished execution of user-supplied SAS code (dataset creation);
        /* User code will now have created InputDataset and maybe TreatmentDataset */
      %end;

      /* Must check treatment dataset before checking input dataset */      
      %if %length(&TreatmentDataset) > 0
      %then
        %do;
          %lb11_treatment_dataset(&TreatmentDataset);
        %end;
      %lb11_input_dataset(&InputDataset);

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
        %lb11_write_options(&writopts);
      %end;

  /*----------------------------------------------------------------------*/ 
  /*-- NP9 - Read options file and generate graphics if we need to */
    %if %length(&readopts) > 0 
    %then
      %do;
        %lb11_graphics(&readopts);
      %end;
%end;

  /*----------------------------------------------------------------------*/
  /*--NP10 - Tidy up and call tu_abort   */
  
  %tu_tidyup(rmdset=&prefix:, glbmac=NONE);
  %tu_abort;

%mend td_lb11;
