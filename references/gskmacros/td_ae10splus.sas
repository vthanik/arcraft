/*******************************************************************************
|
| Macro Name    : td_ae10splus.sas
|
| Macro Version : 1 build 5
|
| SAS Version   : SAS v8.2
|
| Created By    : Elaine Liu   
|
| Date          : 17-Jan-2007
|
| Macro Purpose : To call SPlus doubledotplot.sas to create the AE10 display
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
********************************************************************************/

%MACRO td_ae10splus (dataLibrary             = ,     /* Input Dataset Library       */
                     dataset                 = ,     /* Input Dataset Name          */  
                     InputFile               = ,     /* Name of file if InputUsage=C or U */
                     InputUsage              = D,    /* Style of input data D=dataset C=create template U=use template */
                     sortBy                  = ,     /* List of Variables to be used for sorting Y-Axis values*/
                     ascending               = ,     /* Variables in sortBy should be used in ascending order (F,T) */                    
                     groupNs                 = ,     /* Variable to be used for group N values */
                     percentLabel            = ,     /* Label for the left hand panel X-axis */
                     percentAxis             = ,     /* Range of the left hand panel X-axis in the form {min} to {max} by {int} */
                     percentTicks            = ,     /* List of major tick mark positions for left hand panel X-axis */
                     percentTickLabels       = ,     /* List of labels for the major tick marks defined in percentTicks */
                     percentSymbols          = ,     /* List of S-Plus symbol numbers for symbols in left hand panel */
                     percentColors           = ,     /* List of S-Plus colour numbers for symbols in the left hand panel */
                     statLabel               = ,     /* Label for the right hand panel X-axis */
                     statLogAxis             = ,     /* Log the X-axis for the right hand panel (F,T) */
                     statAxis                = ,     /* Range of the right hand panel X-axis in the form {min} to {max} by {int} */
                     statTicks               = ,     /* Numeric list of major tick mark positions for the right hand panel X-axis */
                     statTickLabels          = ,     /* List of labels for the major tick marks defined in statTicks */
                     statSymbols             = ,     /* S-Plus symbol number for symbols in right hand panel */
                     statColors              = ,     /* S-Plus colour number for symbols in the right hand panel */
                     statVref                = ,     /* Numeric values of vertical reference lines for the right hand panel */
                     yTickLabelSize          = ,     /* Font size for y-axis labels on left hand panel */
                     percentMinorTicks       = ,     /* Minor tick marks are drawn on the left hand panel X-axis (F,T) */
                     percentMinorTicksPer    = ,     /* Number of minor ticks per major tick for left hand panel X-axis */
                     percentMinorTickLength  = ,     /* Length of minor ticks for left hand panel X-axis */
                     statMinorTicks          = ,     /* Minor tick marks are drawn on the right hand panel X-axis (F,T) */
                     statMinorTicksPer       = ,     /* Number of minor ticks per major tick for right hand panel X-axis */
                     statMinorTickLength     = ,     /* Length of minor ticks for right hand panel X-axis */
                     legendLocation          = ,     /* Location for the legend within each panel (upper left, lower left, upper right, lower right) */ 
                     legendSize              = ,     /* Font size (points) for legend */        
                     legendBorder            = ,     /* Border is drawn around the legend (F,T) */      
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
  %LET MacroVersion = 1 Build 5;
  
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
  %let sortBy     = %nrbquote(&sortBy);
  %let groupNs    = %nrbquote(&groupNs);
  
  
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
  
  /*--PV4 - groupNs: check one and only one name is specified when needed */
  %local l_i;
  
  %if &InputUsage ne C and %length(%nrbquote(%sysfunc(compbl(&groupNs)))) > 0
    %then
    %do;
      %let l_i=1;
      %do %while (%length(%qscan(&groupNs,&l_i,%str( ))) > 0);
        %let l_i=%eval(&l_i+1);
      %end;
      %if &l_i gt 2 %then
        %do; 
          %put %str(RTE)RROR: &macroname: Parameter groupNs(&groupNs) should only specify ONE and ONLY ONE variable name; 
          %let pv_abort = 1;
      %end;
  %end;
 
  /*--PV5 - ASCENDING: check for valid values F or T or blank */ 
  %if %length(&ascending) > 0
    %then
    %do;
      %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = ascending, valuelist = F T, abortyn = N);
  %end;

   /*--PV6 - STATLOGAXIS: check for valid values F or T or blank */ 
  %if %length(&statlogaxis) > 0
    %then
    %do;
      %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = statlogaxis, valuelist = F T, abortyn = N);
  %end;

   /*--PV6 - PERCENTMINORTICKS: check for valid values F or T or blank */ 
  %if %length(&percentminorticks) > 0
    %then
    %do;
      %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = percentminorticks, valuelist = F T, abortyn = N);
  %end;

   /*--PV7 - STATMINORTICKS: check for valid values F or T or blank */ 
  %if %length(&statminorticks) > 0
    %then
    %do;
      %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = statminorticks, valuelist = F T, abortyn = N);
  %end;

   /*--PV8 - LEGENDLOCATION: check for valid values F or T or blank */ 
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
       
   /*--PV8 - LEGENDBORDER: check for valid values F or T or blank */ 
  %if %length(&legendborder) > 0
    %then
    %do;
      %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = legendborder, valuelist = F T, abortyn = N);
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
  %macro ae10splus_write_template(fname);
      
    data _null_; 
      file &fname;
      %tu_cr8proghead(macname=create_ae10splus_example_dataset, macdesign=SAS_datastep_not_a_macro);
      
      put " ";
      put "%nrstr(data work.ae10splus_dset;)";
      put "%nrstr(* Data set must include at least these 7 variables;)";
      put "%nrstr(* with one observation for each for each adverse event to be displayed;)"; 
      put "%nrstr(* The dataset shall contain one observation per treatment group per event;)"; 
      put "%nrstr(* The STAT,HI and LO variables shall have the same value for each event by-group;)"; 
      put "%nrstr(  attrib)";
      put "%nrstr(    trtgrp   length=$120 label=%"Treatment label to appear in the legend%")";
      put "%nrstr(    event    length=$120 label=%"The adverse event preferred term to be used as Y-axis%")";
      put "%nrstr(    percent  length=8    label=%"Percentage of subjects experiencing the AE for each TRTGRP.To be used as the left hand panel X-axis%")";
      put "%nrstr(    stat     length=8    label=%"This summary statistic to be used on the right hand panel X-axis.E.g.Relative Risk%")";
      put "%nrstr(    hi       length=8    label=%"This upper limit of the summary statistic on the right hand panel X-axis.E.g.Upper CI%")";
      put "%nrstr(    lo       length=8    label=%"This lower limit of the summary statistic on the right hand panel X-axis.E.g.Lower CI%")";
      put "%nrstr(  ;)";
      put "%nrstr(run;)";
    run;    
   
  %mend ae10splus_write_template;
  
   
  %macro ae10_dataset_validate(dsname);
      
    /* Lists of variable names, by data type, and all required */
    %local charvars numvars mustvars byvars;
    %let charvars=trtgrp event;
    %let numvars=percent stat hi lo;
    %let mustvars=&charvars &numvars;
    %let byvars= event trtgrp;
  
    /*----------------------------------------------------------------------*/ 
    /*-- LM1 - Dataset Validation + Parameter Validation */
  
    %local pv_abort;
    * tu_valparms requires this to exist; 
    %let pv_abort=0;    
   
    /* Check existence of datasets */
    %tu_valparms(
      abortyn=Y,
      macroname=ae10_dataset_validate,
      chktype=dsetExists,
      pv_dsetin=dsname
      );
    /* Check presence of variables */
    %tu_valparms(
      abortyn=N,
      macroname=ae10_dataset_validate,
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
            macroname=ae10_dataset_validate,
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
             macroname=ae10_dataset_validate,
             chktype=isNum,
             pv_dsetin=dsname,
             pv_varsin=thisvar
             );
           %let i=%eval(&i+1);
         %end;
    %end;
   
    /* Check the variables specified by parameter sortBy exist in the dataset */
    %if %length(&sortBy) > 0 
      %then
      %do;
        %local l_temp;
        %let l_temp=&sortBy;
        %local sortBy;
        %let sortBy=&l_temp;
        %tu_valparms(
           abortyn=N,
           macroname=ae10_dataset_validate,
           chktype=varExists,
           pv_dsetin=dsname,
           pv_varsin=sortBy
           );
    %end;     
   
    /* Check the variable specified by parameter groupNs exists in the dataset */
    %if %length(&groupNs) > 0 
      %then
      %do;
        %local l_temp;
        %let l_temp=&groupNs;
        %local groupNs;
        %let groupNs=&l_temp;
        %tu_valparms(
           abortyn=N,
           macroname=ae10_dataset_validate,
           chktype=varExists,
           pv_dsetin=dsname,
           pv_varsin=groupNs
           );
    %end;  
   
    /* Check no duplicate rows per TRTGRP per EVENT */
    %local dupvar;
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
    
    /* Check that the STAT, HI and LO variables have same value for each EVENT;
       and Missing is valid, but all 3 must be missing */
    %local l_numevent l_numnodup l_errmiss;
    
    proc sql noprint;
      select count(distinct event) into :l_numevent from &dsname;
    quit;
   
    proc sort data=&dsname out=&l_prefix._sorted nodupkey;
      by event lo hi stat;
    run;
   
    proc sql noprint;
      select count(*) into :l_numnodup from   &l_prefix._sorted;
      select count(*) into :l_errmiss from &l_prefix._sorted
        where not(missing(lo)and missing(hi)and missing(stat))
              and(missing(lo) or missing(hi) or missing(stat));
    quit;
   
    %if &l_numnodup > &l_numevent 
      %then
      %do;
        %put %str(RTE)RROR: &macroname: The STAT,HI and LO variables shall have the same value for each EVENT by-group;
        %let pv_abort=1;
    %end;
    %else %if &l_errmiss > 0 
      %then
      %do;
        %put %str(RTE)RROR: &macroname: The STAT,HI and LO variables shall all have MISSING values if one of them is missing;
        %let pv_abort=1;
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
   
  %mend ae10_dataset_validate;
  
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
      %ae10splus_write_template(usr_prof);
      
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
      %ae10_dataset_validate(tmpdset);
        
    
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

    %doubledotplot(
                 dataLibrary                 = work,                      
                 dataSet                     = tmpdset,                       
                 percent                     = percent,                    
                 adverseEvent                = event,                    
                 relativeRisk                = stat,                    
                 ciUpperBoundRR              = hi,                    
                 ciLowerBoundRR              = lo,                    
                 treatment                   = trtgrp,        
                 sortBy                      = &sortBy,
                 ascending                   = &ascending,                   
                 groupNs                     = &groupNs,                      
                 percentLabel                = &percentLabel,          
                 percentAxis                 = &percentAxis,    
                 percentTicks                = &percentTicks,                 
                 percentTickLabels           = &percentTickLabels,                
                 percentSymbols              = &percentSymbols,                
                 percentColors               = &percentColors,                
                 relativeRiskLabel           = &statLabel,   
                 relativeRiskLogAxis         = &statLogAxis,               
                 relativeRiskAxis            = &statAxis,                
                 relativeRiskTicks           = &statTicks,                
                 relativeRiskTickLabels      = &statTickLabels,                
                 relativeRiskSymbols         = &statSymbols,                        
                 relativeRiskColors          = &statColors,                         
                 relativeRiskVref            = &statVref,                           
                 adverseEventTickLabelSize   = &yTickLabelSize,                     
                 percentMinorTicks           = &percentMinorTicks,                           
                 percentMinorTicksPer        = &percentMinorTicksPer,                        
                 percentMinorTickLength      = &percentMinorTickLength,                      
                 relativeRiskMinorTicks      = &statMinorTicks,                      
                 relativeRiskMinorTicksPer   = &statMinorTicksPer,                     
                 relativeRiskMinorTickLength = &statMinorTickLength,                   
                 legendLocation              = &legendLocation,                                
                 legendSize                  = &legendSize,                                    
                 legendBorder                = &legendBorder,                                 
                 outputFilePrefix            = &g_graphfilename
                 );        
                                           
  %end;  /* %else <InputUsage=D or U> */

  
  /*----------------------------------------------------------------------*/
  
  %tu_tidyup(glbmac=NONE);
  %tu_abort;

%MEND td_ae10splus;
