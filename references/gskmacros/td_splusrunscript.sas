/*******************************************************************************
|
| Macro Name    : td_splusrunscript.sas
|
| Macro Version : 1 build 3
|
| SAS Version   : SAS v8.2
|
| Created By    : Elaine Liu   
|
| Date          : 17-Jan-2007
|
| Macro Purpose : To execute a SPlus script created in the GWE with HARP
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
********************************************************************************/

%MACRO td_splusrunscript (dataLibrary       = ,       /* Input Dataset Library */              
                          dataset           = ,       /* Input Dataset Name */  
                          InputUsage        = D,      /* Style of input data D=dataset C=create template U=use template */
                          InputFile         = ,       /* Name of file if InputUsage=C or U */
                          splusScript       = ,       /* Pathname of the user-defined S+ script */
                          xAxis             = ,       /* Specifies X-axis range in the form min to max */
                          yAxis             = ,       /* Specifies Y-axis range in the form min to max */
                          xAxisLabel        = ,       /* Specifies X-axis label */                                                                           
                          yAxisLabel        = ,       /* Specifies Y-axis label */ 
                          removeSPLUSScript = 0,      /* Controls whether or not to remove Splus script at end of execution*/
                          lineWidth         = 128,    /* Width (in characters) of an output page */                                              
                          pageLength        = 64,     /* Length (in lines) of an output page */                                                  
                          plotWidth         = 11,     /* Plot width in inches */                                                                 
                          plotHeight        = 8.5,    /* Plot height in inches */                                                                
                          plotMarginTop     = 1.25,   /* Plot top margin in inches */                                                            
                          plotMarginBottom  = 1.25,   /* Plot bottom margin in inches */                                                         
                          plotMarginLeft    = 1,      /* Plot left margin in inches */                                                           
                          plotMarginRight   = 1,      /* Plot right margin in inches */           
                          pointSize         = 10,     /* Title and Footnote point size */
                          xAxisLabelSize    = 10,     /* Point size for X axis and tick mark labels */
                          yAxisLabelSize    = 10,     /* Point size for Y axis and tick mark labels */
                          zAxisLabelSize    = 10,     /* Point size for Z axis and tick mark labels */
                          );                                                                                                                               
                               
  %local MacroVersion MacroName;
  %Let MacroVersion = 1 Build 3;
  %let MacroName = &sysmacroname;
  * Echo values of local and global macro variables to the log ;                                
  %INCLUDE "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=)
                      
  * Define some local macro variables;
  %local l_prefix l_paraDef l_nobs l_dsetin;
  %let l_dsetin=&dataLibrary..&dataset;
  %let l_nobs=0;
  %let l_prefix=%substr(&macroname,3);
  %local pv_abort;
  %let pv_abort = 0;
  
  * Parameter cleanup;
  %let InputUsage = %upcase(&InputUsage);
  %let xAxis      = %upcase(&xAxis);
  %let yAxis      = %upcase(&yAxis);
  %let dataLibrary= %nrbquote(&dataLibrary);
  %let dataset    = %nrbquote(&dataset);
  %let InputUsage = %nrbquote(&InputUsage);
  %let InputFile  = %nrbquote(&InputFile);
  %let splusScript= %nrbquote(&splusScript);
  %let xAxis      = %nrbquote(&xAxis);
  %let yAxis      = %nrbquote(&yAxis);
  %let xAxisLabel = %nrbquote(&xAxisLabel);
  %let yAxisLabel = %nrbquote(&yAxisLabel);
  %let xAxisLabelSize  = %nrbquote(&xAxisLabelSize);
  %let yAxisLabelSize  = %nrbquote(&yAxisLabelSize);
  
  
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
 
 /*--PV1 - INPUT USAGE: check it is D, C or U */
 %if %length(&InputUsage) = 0 %then
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
         
  
  /*--PV4 - splusScript: check correctly specified when and only when needed */ 

  %if &InputUsage ne C 
  %then
    %do;
      %if %length(&splusScript) = 0 
      %then
        %do;
          %put %str(RTE)RROR: &macroname: No SPLUS script file (splusScript) specified; 
          %let pv_abort = 1;
        %end;
      %else
        %do;
          %if %sysfunc(fileexist(&splusScript )) = 0 
          %then
            %do;
              %put %str(RTE)RROR: &macroname: SPLUS script file (splusScript) to be used does not exist; 
              %let pv_abort = 1;
            %end;
        %end;
    %end;
          
  
  /*-----------------------------------------------------------------------*/
  /*- complete parameter validation */
  %if %eval(&g_abort. + &pv_abort.) gt 0 %then 
   %do;
     %put %str(RTE)RROR: &macroname: Macro has failed parameter validation check for reasons stated with %str(RTE)RRORs above;
     %tu_abort(option=force);
   %end;
  /*----------------------------------------------------------------------*/
   
  
  
  /*----------------------------------------------------------------------*/
  /* Normal Processing */
  
  /* Define some local macros */
   
   %macro splusPlot_write_template(fname);
      
      data _null_; 
        file &fname;
        %tu_cr8proghead(macname=create_splusplot_example_dataset, macdesign=SAS_datastep_not_a_macro);
         
        put " ";
        put "%nrstr(data work.splusplot_dset;)";
        put "%nrstr(* comment 1;)";
        put "%nrstr(* commnnt 2;)";
        put "%nrstr(  attrib)";
        put " ";
        put "%nrstr(  ;)";
        put "%nrstr(run;)";
      run;    
 
   %mend splusPlot_write_template;
  
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
      %splusPlot_write_template(usr_prof);
      
      %if %length(&splusScript) > 0
      %then
        %do;
          %put %str(RTN)OTE: &macroname: splusScript specification will be ignored;
        %end;
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
        set %if &InputUsage=U %then 
              %do; 
                &syslast. 
              %end; 
            %if &InputUsage=D %then 
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
        
  
      /*----------------------------------------------------------------------*/ 
      /*-- NP8 - Set up SPLUS environment --*/
                   
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
                   yAxisLabelSize    = &yAxisLabelSize,   
                   zAxisLabelSize    = &zAxisLabelSize   
                   );


      /*----------------------------------------------------------------------*/ 
      /*-- NP9 - Use splusScript to generate graphics                     --*/
      
      /* Call to S-Plus WorkBench Script Macro */
          %runsscript(gweDatasetIn     = tmpdset.sas7bdat,
                      gweDataLibIn     = work,
                      outputFilePrefix = &g_graphfilename,
                      splusScript      = &splusScript,
                      xAxis            = &xAxis,                 
                      xAxisLabel       = &xAxisLabel,            
                      xAxisLabelSize   = &xAxisLabelSize,        
                      yAxis            = &yAxis,                 
                      yAxisLabel       = &yAxisLabel,            
                      yAxisLabelSize   = &yAxisLabelSize        
                      );
    
    
    %end;  /* %else <InputUsage=D or U> */

  
  /*----------------------------------------------------------------------*/
  
  %tu_tidyup(glbmac=NONE);
  %tu_abort;
                                                      
%MEND td_splusrunscript;
