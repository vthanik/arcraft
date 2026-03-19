/*******************************************************************************
|
| Macro Name    : td_splusplot.sas
|
| Macro Version : 1 build 7
|
| SAS Version   : SAS v8.2
|
| Created By    : Elaine Liu   
|
| Date          : 17-Jan-2007
|
| Macro Purpose : To call splusenv and Clinpack macro selected and pass
|                 the appropriate parameters for the Clinpack macro.
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
| Global macro variables created: G_GRAPHFILENAME
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
| Date of Modification: 06MAR07
| Modification ID:
| Reason For Modification: Remove TU_GETDATA
|                          Use G_SUBSET if populated
|
| Modified By: Ian Barretto
| Date of Modification: 08MAR07
| Modification ID:
| Reason For Modification: Add parameters for SOURCESCODE and LOADSPLUSLIBARY
|                          passed to TU_SPLUSENV.
|                          Check existance of temporary dataset and variables.
|
| Modified By: Ian Barretto
| Date of Modification: 23MAR07
| Modification ID:
| Reason For Modification: Remove parameters USEODS and ODSFILEFORMAT
|
| Modified By: Ian Barretto
| Date of Modification: 04APR07
| Modification ID:
| Reason For Modification: Added tu_valparms to Header of dependent macros
|
| Modified By: Ian Barretto
| Date of Modification: 17APR07
| Modification ID:
| Reason For Modification: Removed plot specific fly-over text for xyaxislimits. 
|                          Changed angled brackets to curly bracket in fly-over
|                          text.
|
********************************************************************************/

%MACRO td_splusplot (dataLibrary       = ,     /* Input Dataset Library */
                     dataset           = ,     /* Input Dataset Name */
                     InputUsage        = D,    /* Style of input data D=dataset C=create template U=use template */
                     InputFile         = ,     /* Name of file if InputUsage=C or U */
                     graphType         = ,     /* Name of S+ macro to be called */
                     x                 = ,     /* X-Axis variable that exists in {dataset} */
                     y                 = ,     /* Y-Axis variable that exists in {dataset} */
                     z                 = ,     /* Z-Axis variable that exists in {dataset} */
                     condition         = ,     /* Conditioning variable list (space delimited) that exists in {dataset} */
                     groups            = ,     /* Grouping variable that exists in {dataset} */
                     xAxisLabel        = ,     /* Label to use for X-Axis */
                     yAxisLabel        = ,     /* Label to use for Y-Axis */
                     zAxisLabel        = ,     /* Label to use for Z-Axis */
                     xAxisLimits       = ,     /* Range of X-Axis. Format of parameter is dependent on {graphtype} chosen */
                     yAxisLimits       = ,     /* Range of Y-Axis. Format of parameter is dependent on {graphtype} chosen */
                     aspect            = ,     /* Aspect ratio, either a numeric value, fill, xy or blank */
                     layout            = ,     /* Layout of plot in format {Number of columns},{Number of rows},{Number of pages}*/
                     skipPanel         = ,     /* Panel usage in page in terms of 0s and 1s (top left to bottom right) */
                     tableLayout       = ,     /* Table layout (T) or Graph layout (G) to be used */
                     panel             = ,     /* SPlus panel function */
                     prepanel          = ,     /* SPlus panel function */
                     strip             = ,     /* SPlus strip function */
                     contour           = ,     /* Draw the contour lines (F,T) for GraphType=CONTOURPLOTTRELLIS or LEVELPLOT */
                     cuts              = ,     /* Number of contour cut levels for GraphType=CONTOURPLOTTRELLIS or LEVELPLOT */
                     region            = ,     /* Shade area between contour lines (F,T) for GraphType=CONTOURPLOTTRELLIS or LEVELPLOT */
                     distribution      = ,     /* SPlus quantile function for GraphType=QQMATHTRELLIS*/
                     jitter            = ,     /* Points to be jittered (F,T) in a vertical direction for GraphType=STRIPPLOTTRELLIS*/
                     slicedata         = ,     /* Data variable that exists in {dataset} for GraphType=PIECHARTTRELLIS*/
                     slicelabels       = ,     /* Label variable that exists in {dataset} for GraphType=PIECHARTTRELLIS*/                     
                     removeSPLUSScript = 0,    /* Controls whether or not to remove Splus script at end of execution*/
                     lineWidth         = 128,  /* Width (in characters) of an output page */
                     pageLength        = 64,   /* Length (in lines) of an output page */
                     plotWidth         = 11,   /* Plot width in inches */
                     plotHeight        = 8.5,  /* Plot height in inches */
                     plotMarginTop     = 1.25, /* Plot top margin in inches */
                     plotMarginBottom  = 1.25, /* Plot bottom margin in inches */
                     plotMarginLeft    = 1,    /* Plot left margin in inches */
                     plotMarginRight   = 1,    /* Plot right margin in inches */
                     pointSize         = 10,   /* Title and Footnote point size */
                     xAxisLabelSize    = 10,   /* Point size for X axis and tick mark labels */
                     yAxisLabelSize    = 10,   /* Point size for Y axis and tick mark labels */
                     zAxisLabelSize    = 10,   /* Point size for Z axis and tick mark labels */
                     sourceName        = ,     /* SPlus PANEL function filename passed to sourcecode.sas */
                     sourceLocation    = ,     /* SPlus PANEL function file location path passed to sourcecode.sas */
                     libraryName       = ,     /* SPlus library passed to loadspluslibrary.sas */
                     libraryLocation   = ,     /* SPlus library path passed to loadspluslibrary.sas */
                     loadFirst         =       /* Specifies if top of SPlus library search first passed to loadspluslibrary.sas */
                    );                                                                                                                               
                               
  %local MacroVersion MacroName;
  %Let MacroVersion = 1 Build 7;
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
  %let graphType=%upcase(&graphType);
  %let InputUsage=%upcase(&InputUsage);
  %let InputUsage=%nrbquote(&InputUsage);
  %let InputFile=%nrbquote(&InputFile);
  %let dataLibrary=%nrbquote(&dataLibrary);
  %let dataset=%nrbquote(&dataset);
  %let x=%nrbquote(&x);
  %let y=%nrbquote(&y);
  %let z=%nrbquote(&z);
  %let condition=%nrbquote(&condition);
  %let groups=%nrbquote(&groups);
  %let slicedata=%nrbquote(&slicedata);
  %let slicelabels=%nrbquote(&slicelabels);

 /*-----------------------------------------------------------------------*/
 /* Define local macro to check valid CLINPACK macros list */ 
   
  %macro chkgraphType();
 
    /*Convert the XML Table(s) into dataset(s)*/
    %if %sysfunc(fileexist(&g_refdata./tr_splusmacros.xml)) eq 0 %then
    %do;
      %put %str(RTERR)%str(OR): &macroname: S-Plus ClinPack macro checking XML file does not exist within &g_refdata;
      %let g_abort=1;
    %end;

    libname spmacs xml "&g_refdata./tr_splusmacros.xml";

    data &l_prefix._findMac; set spmacs.splusmacros;
      macroname=upcase(scan(macroname,1,'.'));
      if macroname="&graphType";
      call symput('l_nobs',put(_n_,8.));
    run;
    
    %if &l_nobs=0 %then 
      %do; 
         %put %str(RTE)RROR: &macroname: S-Plus macro (&graphType) not found in the macro list; 
         %let pv_abort = 1;
      %end;
  
  %mend chkgraphType; 

  
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
      %put %str(RTE)RROR: &macroname: Macro parameter (InputUsage) cannot be blank; 
      %let pv_abort = 1;
  %end;
  %else 
    %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = InputUsage, valuelist = C D U, abortyn = N);

  /*--PV2 - INPUT DATASET: check valid dataset specified when and only when needed */
  %if &InputUsage=D
    %then
    %do;
      %if %sysevalf(%length(&dataset)) = 0 or %sysevalf(%length(&dataLibrary)) = 0
        %then 
        %do;
          %put %str(RTE)RROR: &macroname: Macro variables dataLibrary and dataset cannot be blank when InputUsage=D; 
          %let pv_abort = 1;
      %end;
      %else %if %eval(%sysfunc(indexw(ARDATA DMDATA DDDATA REFDATA, %upcase(&dataLibrary)))) = 0 
        %then
        %do;  
          %put %str(RTE)RROR: &macroname: dataLibrary(&dataLibrary) is not one of (ARDATA DMDATA DDDATA or REFDATA); 
          %let pv_abort = 1;
      %end;  
      %else
        %tu_valparms(macroname = &macroname., chktype=dsetExists, pv_dsetin = l_dsetin , abortyn = N); 
  %end;
        
  /*--PV2b - INPUT DATASET: warn that dataset will not be used when not needed */
  %if &InputUsage=C or &InputUsage=U
    %then
    %do;
      %if %sysevalf(%length(&dataLibrary)+%length(&dataset)) > 0
        %then
        %do;
          %put %str(RTW)ARNING: &macroname: dataLibrary and/or dataset specified when InputUsage does not require it; 
      %end;
  %end;      

  /*--PV3 - INPUTFILE: warn that input file will not be used when not needed */
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

  /*--PV4 - GRAPHTYPE: check correctly specified when and only when needed */ 
  %if &InputUsage=C
    %then
    %do;
      %if %length(&graphType) > 0
        %then
        %do;
          %put %str(RTW)ARNING: &macroname: graphType specified when not required; 
      %end;
  %end;    
  %else
    %do;
      %if %length(&graphType) = 0
        %then
        %do;
          %put %str(RTE)RROR: &macroname: No graphType specified when required; 
          %let pv_abort = 1;
      %end;
      %else
        %do;
          %chkgraphType;
      %end;
  %end;
    
  /*--PV5 - CONTOUR: check for valid values F or T or blank */ 
  %if %length(&contour) > 0
    %then
    %do;
      %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = contour, valuelist = F T, abortyn = N);
  %end;

  /*--PV6 - REGION: check for valid values F or T or blank */ 
  %if %length(&region) > 0
    %then
    %do;
      %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = region, valuelist = F T, abortyn = N);
  %end;

  /*--PV7 - JITTER: check for valid values F or T or blank */ 
  %if %length(&jitter) > 0
    %then
    %do;
      %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = jitter, valuelist = F T, abortyn = N);
  %end;

  /*--PV8 - TABLELAYOUT: check for valid values F or T or blank */ 
  %if %length(&tablelayout) > 0
    %then
    %do;
      %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = tablelayout, valuelist = F T, abortyn = N);
  %end;
  
  /*--PV9 - CUTS: check for valid values of numeric or blank */ 
  %if %length(&cuts) > 0
    %then
    %do;
     %if %datatyp(&cuts) ne NUMERIC
       %then
       %do;
         %put %str(RTE)RROR: &macroname: Specified parameter value CUTS is not numeric;
         %let pv_abort = 1;
    %end;
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

  
  /*----------------------------------------------------------------------*/
  /* Normal Processing */
  
  /* Define local macro to call ClinPack macro with appropriate parameters */
  %macro splus_graphics(dsname=, dslib=, macname=);
    
    proc transpose data=&l_prefix._findMac
      out=&l_prefix._param(drop=_label_ rename=(_name_=paramName col1=isNeeded)); 
      var x--jitter; 
    run;
  
    data &l_prefix._param(drop=isneeded); 
      set &l_prefix._param(where=(isNeeded ne ' '));
      paradef=compbl(paramName||'='||symget(paramName));
    run;

    proc sql noprint;
      select paradef into :l_paraDef separated by ','
      from &l_prefix._param;
    quit;
    
    /* Call to S-Plus ClinPack Macro */
    %&macname.(
              dataLibrary       = &dslib,        
              dataSet           = &dsname,            
              outputFilePrefix  = &g_graphfilename,   
              outputDataLibrary = work,
              &l_paraDef.
              );
                 
   %mend splus_graphics;
   
  /* Define local macro to call ClinPack macro with appropriate parameters */               
  %macro splusPlot_write_template(fname);
    
    %local l_i;
    
    data _null_; 
      file &fname;
      %tu_cr8proghead(macname=create_splusplot_example_dataset, macdesign=SAS_datastep_not_a_macro);

      put " ";
      put "%nrstr(* Use this program to create the Input Dataset for the ClinPack macro.;)";
      put "%nrstr(* Ensure all the required variables match the values in parameters.;)";
      put "%nrstr(* The last data set created will be used as the Input Dataset.;)";
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


  /*----------------------------------------------------------------------*/ 
  /* Now we can actually start doing things... */

  %if &InputUsage=C
    %then
    %do;
    /*----------------------------------------------------------------------*/ 
    /*-- NP6 - Write template file if wanted */
      %put %str(RTN)OTE: &macroname: Creating template code file for input dataset; 
      %put %str(RTN)OTE: &macroname: No graph will be generated;       
      %splusPlot_write_template(usr_prof);
  %end;
  %else
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
      %end;
       
      /*-- Create macro variable to contain TMPDSET for later checking by TU_VALPARMS --*/
      %local tmpdset;
      %let tmpdset=tmpdset;
                                                          
      data &tmpdset; 
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
      
      /*-- Check for variables in X, Y, Z, CONDITION, GROUPS, SLICEDATA, SLICELABEL in above dataset --*/
      %let spvarlist=;
      
      %if %length(&x)>0 %then %do;
        %let spvarlist=&x;
      %end;
      %if %length(&y)>0 %then %do;
        %let spvarlist=&spvarlist &y;
      %end;
      %if %length(&z)>0 %then %do;
        %let spvarlist=&spvarlist &z;
      %end;
      %if %length(&condition)>0 %then %do;
        %let spvarlist=&spvarlist &condition;
      %end;
      %if %length(&groups)>0 %then %do;
        %let spvarlist=&spvarlist &groups;
      %end;
      %if %length(&slicedata)>0 %then %do;
        %let spvarlist=&spvarlist &slicedata;
      %end;
      %if %length(&slicelabels)>0 %then %do;
        %let spvarlist=&spvarlist &slicelabels;
      %end;
      
      %tu_valparms(abortyn=Y
                  ,macroname=&macroname
                  ,chktype=varExists
                  ,pv_dsetin=tmpdset 
                  ,pv_varsin=spvarlist
                   );
        
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
                   zAxisLabelSize    = &zAxisLabelSize,
                   sourceName        = &sourceName ,
                   sourceLocation    = &sourceLocation ,
                   libraryName       = &libraryName ,
                   libraryLocation   = &libraryLocation ,
                   loadFirst         = &loadFirst
                   );

      /* Use G_SUBSET to subset data if populated */
      DATA tmpdset;
        SET tmpdset 
         %IF %LENGTH(%UNQUOTE(&g_subset)) NE 0 
           %THEN 
           (WHERE=(%UNQUOTE(&g_subset))); 
         ; 
      RUN;
        
      /*----------------------------------------------------------------------*/ 
      /*-- NP9 - Use Splus Macros to generate graphics     --*/
      
      %splus_graphics(dsname=tmpdset, dslib=work, macname=&graphType);  
  %end;
  
  /*----------------------------------------------------------------------*/
  
  %tu_tidyup(glbmac=NONE);
  %tu_abort;
                                                      
%MEND td_splusplot;
