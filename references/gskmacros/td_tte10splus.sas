/*******************************************************************************
|
| Macro Name    : td_tte10splus.sas
|
| Macro Version : 1 build 4
|
| SAS Version   : SAS v8.2
|
| Created By    : Elaine Liu   
|
| Date          : 17-Jan-2007
|
| Macro Purpose : To call SPlus plotkm.sas to create the TTE10 display
|
| Macro Design  : Procedure style
|
| Input Parameters:
|
| NAME                DESCRIPTION                                 REQ/OPT  DEFAULT
|
|
|
| Output: Either PDF or HTML graph.
|
| Global macro variables created: None
|
| Macros Called:
| (@) tr_putlocals
| (@) tu_putglobals 
| (@) tu_splusenv 
| (@) tu_cr8proghead
| (@) tu_valparms
|*******************************************************************************
| Change Log
|
| Modified By: Ian Barretto
| Date of Modification: 04APR07
| Modification ID:
| Reason For Modification: Added tu_valparms to Header of dependent macros
|
| Modified By: Ian Barretto
| Date of Modification: 17APR07
| Modification ID:
| Reason For Modification: Changed angled brackets to curly bracket in fly-over
|                          text.
|
| Modified By: Shan Lee
| Date of Modification: 25APR07
| Modification ID: SL001
| Reason For Modification: Following first round of UAT, included parameter
|                          validation to ensure that STRATA parameter is not
|                          blank.
|
********************************************************************************/

%MACRO td_tte10splus (dataLibrary = ,                 /* Input Dataset Library       */
                      dataSet = ,                     /* Input Dataset Name          */
                      InputFile = ,                   /* Name of file if InputUsage=C or U */
                      InputUsage = D,                 /* Style of input data D=dataset C=create template U=use template */
                      strata = ,                      /* Variable representing different groups */
                      condition = ,                   /* Space delimited list of variables used for conditioning the plot */
                      atRisk = T,                     /* Should numbers at risk be included? (0,1,F,T) */
                      lineColors = 2 3 4 5 6 7,       /* Space delimited SPlus list of colours */
                      censorValue = 0,                /* Value of EVENT variable which should be interpreted as censoring instead of event */
                      censorMarks = T,                /* Should censor marks be included? (0,1,F,T) */
                      censorMarksScale = 0.8,         /* Size of censor mark symbols in SPlus character expansion (cex) units */
                      ciBars = None,                  /* Style of confidence limits (None,Bars,Band) */
                      groupShift = 1,                 /* Value the bars shall be shifted horizontally so they do not overlap */
                      ciLevel = 0.95,                 /* Size of the confidence interval to be plotted */
                      ciType = log,                   /* Type of confidence interval to be plotted (ID,Log,Log-Log) */
                      cumIncidence = F,               /* Should curve be plotted as cumlative incidence instead of survival (0,1,F,T) */
                      truncate = F,                   /* Should plot be truncated at last observation or plotted for remaining censored observation (0,1,F,T) */
                      xAxisLabel = ,                  /* Label for the X-Axis */
                      xAxis = ,                       /* X-Axis limits in form {min} to {max} by {increment} */
                      yAxisLabel = ,                  /* Label for the Y-Axis */
                      yAxis = ,                       /* Y-Axis limits in form {min} to {max} by {increment} */
                      vrefLines = ,                   /* Space delimited list of values for vertical reference lines on X-Axis */
                      hrefLines =,                    /* Space delimited list of values for horizontal reference lines on Y-Axis */
                      aspect = Fill,                  /* Aspect ratio for each panel */
                      legend = T,                     /* Should lengend be plotted? (0,1,F,T) */
                      legendLocation = lower left,    /* Location for the legend within each panel (upper left, lower left, upper right, lower right) */
                      legendInside = T,               /* Should lengend be plotted inside or outside the axis? (0,1,F,T) */
                      removeSPLUSScript       = 0,    /* Controls whether or not to remove Splus script at end of execution*/
                      lineWidth               = 128,  /* Width (in characters) of an output page */                                              
                      pageLength              = 64,   /* Length (in lines) of an output page */                                                  
                      plotWidth               = 11,   /* Plot width in inches */                                                                 
                      plotHeight              = 8.5,  /* Plot height in inches */                                                                
                      plotMarginTop           = 1.25, /* Plot top margin in inches */                                                            
                      plotMarginBottom        = 1.25, /* Plot bottom margin in inches */                                                         
                      plotMarginLeft          = 1,    /* Plot left margin in inches */                                                           
                      plotMarginRight         = 1,    /* Plot right margin in inches */           
                      pointSize               = 10,   /* Title and Footnote point size */
                      xAxisLabelSize          = 10,   /* Point size for X axis and tick mark labels */
                      yAxisLabelSize          = 10    /* Point size for Y axis and tick mark labels */
                      );                                                                                               
  
                      
  %local MacroVersion MacroName;
  %let MacroName = &sysmacroname;
  %LET MacroVersion = 1 Build 4;
  
  * Echo values of local and global macro variables to the log ;                                
  %INCLUDE "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=)
  
  
  * Define some local macro variables;
  %local l_prefix l_dsetin;
  %let l_prefix=%substr(&macroname,3);
  %let l_dsetin=&dataLibrary..&dataset;
  %local pv_abort;
  %let pv_abort = 0;
  
  * Parameter cleanup;
  %let InputUsage = %upcase(&InputUsage);
  %let dataLibrary= %nrbquote(&dataLibrary);
  %let dataset    = %nrbquote(&dataset);
  %let InputUsage = %nrbquote(&InputUsage);
  %let InputFile  = %nrbquote(&InputFile);
  
  /*-----------------------------------------------------------------------*/
  /* Parameter Validation */
 
  /*--PV0 - Delete any existing plot file */
  /* NB we do this even if this call would not create a new one */
  %local plotfile;             
  %let plotfile=&G_OUTFILE..&G_TEXTFILESFX;
    
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
          %if &rc ne 0
            %then
            %do;
              %put %str(RTE)RROR: &macroname: Failed to delete existing plot file - return code &rc;
              %let pv_abort = 1;
          %end;
      %end;
  %end;
 
  /*--PV1 - INPUTUSAGE: check it is D, C or U */
  %if %length(&InputUsage) = 0 
    %then
    %do; 
      %put %str(RTE)RROR: &macroname: Macro parameter (InuptUsage) cannot be blank; 
      %let pv_abort = 1;
  %end;
  %else 
    %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = InputUsage, valuelist = C D U, abortyn = N);

  /*--PV2 - INPUT DATASET: check specified when and only when needed */

  %if &InputUsage=D
    %then
    %do;
      %if %sysevalf(%length(&dataset)) = 0 or %sysevalf(%length(&dataLibrary)) = 0
        %then 
        %do;
          %put %str(RTE)RROR: &macroname: Macro parameters (dataLibrary) and (dataset) cannot be blank when InputUsage=D; 
          %let pv_abort = 1;
      %end;
      %else
        %do;  
          %tu_valparms(macroname = &macroname., chktype=dsetExists, pv_dsetin = l_dsetin , abortyn = N); 
      %end;
  %end;
        
  %if &InputUsage=C or &InputUsage=U
    %then
    %do;
      %if %sysevalf(%length(&dataLibrary)+%length(&dataset)) > 0
        %then
        %do;
          %put %str(RTW)ARNING: &macroname: Macro parameters (dataLibrary) and/or (dataset) specified when InputUsage does not require it; 
      %end;
  %end;      

  /*--PV3 - INPUTFILE: check correctly specified when and only when needed */

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
      %if %length(&InputFile) = 0
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
      %if %length(&InputFile) = 0
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
  
 
  /*--PV4 - ATRISK: check for valid values F or T or blank */ 
  %if %length(&atrisk) > 0
    %then
    %do;
      %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = atrisk, valuelist = 0 1 F T, abortyn = N);
  %end;

   /*--PV5 - CENSORMARKS: check for valid values F or T or blank */ 
  %if %length(&censormarks) > 0
    %then
    %do;
      %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = censormarks, valuelist = 0 1 F T, abortyn = N);
  %end;

   /*--PV6 - CIBARS: check for valid values F or T or blank */ 
  %if %length(&cibars) > 0
    %then
    %do;
      %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = cibars, valuelist = None Bars Band, abortyn = N);
  %end;

  /*--PV7 - CITYPE: check for valid values F or T or blank */ 
  %if %length(&citype) > 0
    %then
    %do;
      %if %upcase("&citype") = "ID" %then %do;
      %end;
      %else %if %upcase("&citype") = "LOG" %then %do;
      %end;
      %else %if %upcase("&citype") = "LOG-LOG" %then %do;
      %end;
      %else %do;
         %put %str(RTE)RROR: &macroname: Parameter CITYPE (&citype) should be ID, LOG or LOG-LOG ; 
        %let pv_abort = 1;
     %end;
  %end;

   /*--PV8 - CUMINCIDENCE: check for valid values F or T or blank */ 
  %if %length(&cumincidence) > 0
    %then
    %do;
      %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = cumincidence, valuelist = 0 1 F T, abortyn = N);
  %end;

   /*--PV9 - TRUNCATE: check for valid values F or T or blank */ 
  %if %length(&truncate) > 0
    %then
    %do;
      %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = truncate, valuelist = 0 1 F T, abortyn = N);
  %end;


   /*--PV10 - LEGENDLOCATION: check for valid values F or T or blank */ 
  %if %length(&legendlocation) > 0
    %then
    %do;
      %if %upcase("&legendlocation") = "UPPER LEFT" %then %do;
      %end;
      %else %if %upcase("&legendlocation") = "LOWER LEFT" %then %do;
      %end;
      %else %if %upcase("&legendlocation") = "UPPER RIGHT" %then %do;
      %end;
      %else %if %upcase("&legendlocation") = "LOWER RIGHT" %then %do;
      %end;
      %else %do;
         %put %str(RTE)RROR: &macroname: Parameter LEGENDLOCATION(&legendlocation) should be UPPER LEFT, LOWER LEFT, UPPER RIGHT or LOWER RIGHT; 
        %let pv_abort = 1;
     %end;
  %end;
       
   /*--PV8 - LEGENDINSIDE: check for valid values F or T or blank */ 
  %if %length(&legendinside) > 0
    %then
    %do;
      %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = legendinside, valuelist = 0 1 F T, abortyn = N);
  %end;

     /*--PV - LEGEND: check for valid values F or T or blank */ 
  %if %length(&legend) > 0
    %then
    %do;
      %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = legend, valuelist = 0 1 F T, abortyn = N);
  %end;
 
     /*--PV - STRATA: check non-blank - SL001 */ 
  %if %length(&strata) eq 0 %then
  %do;
    %put %str(RTE)RROR: &sysmacroname: value must be specified for STRATA parameter;
    %let g_abort = 1;
  %end;

  /*-----------------------------------------------------------------------*/
  /*- complete parameter validation */
  %if %eval(&g_abort. + &pv_abort.) gt 0 
    %then 
    %do;
      %put %str(RTE)RROR: &macroname: Macro has failed parameter validation check for reasons stated with %str(RTE)RRORs above;
      %tu_abort(option=force);
  %end;
  /*----------------------------------------------------------------------*/
 
 
  /*-----------------------------------------------------------------------*/
  /* Normal Processing */

 
  /* Define some local macros */
  %macro tte10splus_write_template(fname);
      
    data _null_; 
      file &fname;
      %tu_cr8proghead(macname=create_tte10splus_example_dataset, macdesign=SAS_datastep_not_a_macro);
      
      put " ";
      put "%nrstr(data work.tte10splus_dset;)";
      put "%nrstr(* Data set must include at least these 2 variables;)";
      put "%nrstr(* with one observation for each for each time interval to be displayed for each treatment group;)"; 
      put "%nrstr(  attrib)";
      put "%nrstr(    time     length=8    label=%"Time to event or censoring%")";
      put "%nrstr(    event    length=8    label=%"Indicates whether and event occured or censored %")";
      put "%nrstr(  ;)";
      put "%nrstr(run;)";
    run;    
   
  %mend tte10splus_write_template;
  
   
  %macro tte10_dataset_validate(dsname);
      
    /* Lists of variable names, by data type, and all required */
    %local numvars mustvars;
    %let numvars=time event;
    %let mustvars=&numvars;
  
    /*----------------------------------------------------------------------*/ 
    /*-- LM1 - Dataset Validation + Parameter Validation */
  
    %local pv_abort;
    * tu_valparms requires this to exist; 
    %let pv_abort=0;    
   
    /* Check existence of datasets */
    %tu_valparms(
      abortyn=Y,
      macroname=tte10_dataset_validate,
      chktype=dsetExists,
      pv_dsetin=dsname
      );
    /* Check presence of variables */
    %tu_valparms(
      abortyn=N,
      macroname=tte10_dataset_validate,
      chktype=varExists,
      pv_dsetin=dsname,
      pv_varsin=mustvars
      );
    /* Check variable types */
    /* We have to do this once per variable since tu_valparms gives at most one error */
    %local i thisvar;
    %if %length(&numvars) > 0
      %then
      %do;
         %let i=1;
         %do %while (%length(%scan(&numvars,&i)) > 0);
           %let thisvar=%scan(&numvars,&i);
           %tu_valparms(
             abortyn=N,
             macroname=tte10_dataset_validate,
             chktype=isNum,
             pv_dsetin=dsname,
             pv_varsin=thisvar
             );
           %let i=%eval(&i+1);
         %end;
    %end;
   
    /* Check the variables specified by parameter STRATA exist in the dataset */
    %if %length(&strata) > 0 
      %then
      %do;
        %local l_temp;
        %let l_temp=&strata;
        %local strata;
        %let strata=&l_temp;
        %tu_valparms(
           abortyn=N,
           macroname=tte10_dataset_validate,
           chktype=varExists,
           pv_dsetin=dsname,
           pv_varsin=strata
           );
    %end;     
   
    /* Check the variables specified by parameter CONDITION exist in the dataset */
    %if %length(&condition) > 0 
      %then
      %do;
        %local l_temp;
        %let l_temp=&condition;
        %local condition;
        %let condition=&l_temp;
        %tu_valparms(
           abortyn=N,
           macroname=tte10_dataset_validate,
           chktype=varExists,
           pv_dsetin=dsname,
           pv_varsin=condition
           );
    %end;     
  
    /*----------------------------------------------------------------------*/
    /*- complete dataset validation */
    %if %eval(&g_abort. + &pv_abort.) gt 0 
      %then
      %do;
        %put %str(RTE)RROR: &macroname: Macro has failed dataset validation check for reasons stated with %str(RTE)RRORs above;
        %tu_abort(option=force);
    %end;
    /*----------------------------------------------------------------------*/
   
  %mend tte10_dataset_validate;
  
  /*----------------------------------------------------------------------*/ 
  /*-- NP4 - Specify FILENAMES */
  
  /* Specify filename for possible template file */

  %if %length(&InputFile) > 0
    %then
    %do;
      filename usr_prof "&InputFile";
  %end;


  /* Now we can actually start doing things... */

  %if &InputUsage=C
    %then
    %do;

      /*----------------------------------------------------------------------*/ 
      /*-- NP6 - Write template file if wanted */
  
      %put %str(RTN)OTE: &macroname: Creating template code file for input dataset; 
      %put %str(RTN)OTE: &macroname: No graph will be generated;       
      %tte10splus_write_template(usr_prof);
      
  %end;
  %else  /*InputUsage=D or U*/
    %do;
    
      %local l_tmpDset;
      /*----------------------------------------------------------------------*/ 
      /*-- NP7 - Use user-supplied template file, if any, else user-supplied dataset */
      %if &InputUsage=U
        %then
        %do;
          %put %str(RTN)OTE: &macroname: Starting execution of user-supplied SAS code (dataset creation);
          /* Execute user input file */
          %include usr_prof;
          
          %put %str(RTN)OTE: &macroname: Finished execution of user-supplied SAS code (dataset creation);
          /* Dataset name returned in macrovar l_tmpDset */ 
      %end;
      
      data tmpdset; 
        set %if &InputUsage=U 
              %then 
              %do; 
                &syslast. 
            %end; 
            %if &InputUsage=D 
              %then 
              %do; 
                &dataLibrary..&dataset. 
            %end;
            ;
      run;

     /* Use G_SUBSET to subset data if populated */
      DATA tmpdset;
        SET tmpdset 
         %IF %LENGTH(%UNQUOTE(&g_subset)) NE 0 
           %THEN 
           (WHERE=(%UNQUOTE(&g_subset))); 
         ; 
      RUN;
      
      /*-- NP8 - Dataset validation */
      %tte10_dataset_validate(tmpdset);
        
    
      /*-- NP9 - Call to cp_splusenv */
  
      %tu_splusenv(lineWidth         = &lineWidth,        
                   pageLength        = &pageLength,
                   removeSPLUSScript = &removeSPLUSScript,       
                   plotWidth         = &plotWidth,        
                   plotHeight        = &plotHeight,       
                   plotMarginTop     = &plotMarginTop,    
                   plotMarginBottom  = &plotMarginBottom, 
                   plotMarginLeft    = &plotMarginLeft,   
                   plotMarginRight   = &plotMarginRight,  
                   pointSize         = &pointSize, 
                   xAxisLabelSize    = &xAxisLabelSize,   
                   yAxisLabelSize    = &yAxisLabelSize   
                   );
  
  
    /*-- NP10 - Call to S-Plus Custom Macro */

   %PLOTKM(dataLibrary      = work,
           dataSet          = tmpdset,
           time             = time,
           event            = event,
           strata           = &strata,
           condition        = &condition,
           atRisk           = &atRisk,
           lineColors       = &lineColors,
           censorValue      = &censorValue,
           censorMarks      = &censorMarks,
           censorMarksScale = &censorMarksScale,
           ciBars           = &ciBars,
           groupShift       = &groupShift,
           ciLevel          = &ciLevel,
           ciType           = &ciType,
           cumIncidence     = &cumIncidence,
           truncate         = &truncate,
           xAxisLabel       = &xAxisLabel,
           xAxis            = &xAxis,
           yAxisLabel       = &yAxisLabel,
           yAxis            = &yAxis,   
           vrefLines        = &vrefLines,
           hrefLines        = &hrefLines,
           aspect           = &aspect,
           legend           = &legend,
           legendLocation   = &legendLocation,
           legendInside     = &legendInside,
           outputFilePrefix = &g_graphfilename
           );
                                           
  %end;  /* %else <InputUsage=D or U> */

  
  /*----------------------------------------------------------------------*/
  
  %tu_tidyup(glbmac=NONE);
  %tu_abort;

%MEND td_tte10splus;
