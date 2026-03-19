/********************************************************************************************
|
| Macro Name:      td_lb7tscg
|
| Macro Version    1
|
| SAS Version:     9.1.3
|
| Created By:      Andy Miskell
|
| Date:            April 6, 2011
|
| Macro Purpose:   Create LB7 display using TIBCO Spotfire Clinical Graphics (TSCG)
|
| Macro Design:    Procedure Style
|
| Input Parameters : 
|
| NAME                DESCRIPTION                                          REQ/OPT  DEFAULT         
| ------------------------------------------------------------------------------------------
| INPUTUSAGE         Style of input data: C=Create Pre-processing         Req      <blank>
|                    program, D=Use existing dataset as input for 
|                    template, P=Call pre-processing file to create 
|                    dataset only, U=Call pre-processing file to
|                    create dataset as input for template 
|                    
| INPUTFILE          Name of pre-processing program located in refdata    Req      <blank>
|                    folder to either create or read in.
|
| DATASET            Name of input dataset for igd file.                  Req      <blank>
|                    Note this will be the name of the processed  
|                    dataset after calling pre-processing program
|
| IGDFILE            Name of IGD file to call                             Req      <blank>
|
| KEEPSSCRIPT        Logical flag indicating if the script to generate    Req      1
|                    the graph should be retained
|
| GETDATAYN          Execute tu_getdata macro: Yes or No                  Req      Y
|                    Valid values: Y, N
|
| NRTYPE              =NR if Upper limit of Normal Range will be used.    Req      NR
|                     =CC if Upper limit of PCI range will be used. 
|
| KEEPVAR            Variables to keep in dataset to group by and sort    Opt      <blank>
|                    by.  Will be used as by-variables in calculation
|                    of maximum values.
|
| XAXIS              Specifies the x-axis range. An expression            Opt      <blank>
|                    of the form: a to b by c
|
| XAXISLABEL         X-axis label                                         Opt      <blank>
|
| XAXISLABELSIZE     Point size for x-axis and tick mark labels           Req      10
|
| YAXIS              Specifies the y-axis range. An expression            Opt      <blank>
|                    of the form: a to b by c
|
| YAXISLABEL         Y-axis label                                         Opt      <blank>
|
| YAXISLABELSIZE     Point size for y-axis and tick mark labels           Req      10
|
| POINTSIZE          Point size for headers, titles and footnotes         Req      10
|
| -------------------------------------------------------------------------------------------
|
| Global macro variables created: NONE
|
| Macros called:
| (@) tr_putlocals
| (@) tu_putglobals 
| (@) tu_getdata
| (@) tu_valparms
| (@) tu_cr8proghead
| (@) tu_tscgenv
| (@) tu_tidyup
| (@) tu_abort
|
|***********************************************************************************************
| Change Log 
|
| Modified By: 
| Date of Modification: 
| New Version/Build Number:
| Modification ID: 
| Reason For Modification: 
|
************************************************************************************************/
%macro td_lb7tscg(InputUsage        = ,                   /* Style of input data: C=Create pre-processing program, D=Use existing dataset as input for template, P=Call pre-processing program, U=Use template */
                  InputFile         = ,                   /* Name of pre-processing program located in refdata folder to either create or read in. No folder path is required - only the file name - e.g. example.sas  */
                  dataset           = ,                   /* Name of input dataset for igd file. Note this will be the name of the processed dataset after calling pre-processing program.  2-level name required - e.g. ardata.lab */
                  igdFile           = ,                   /* Name of IGD file to call located in refdata folder.  No folder path is required - only the file name - e.g. example.igd  */
                  keepSScript       = 1,                  /* Logical flag indicating if the script to generate the graph should be retained (=1, keep Script; =0, delete Script) */
                  getdatayn         = Y,                  /* Control execution of tu_getdata (Y/N) */
                  nrtype            = NR,                 /* =NR if Upper limit of Normal Range will be used.  =CC if Upper limit of PCI range will be used */
                  keepvar           = ,                   /* Variables to keep in dataset to group by not including &g_subjid, &g_trtcd, &g_trtcd, lab tests, units,and results variables. Will be used as by-vars in calculation of maximum values. */ 
                  xAxis             = ,                   /* Specifies the x-axis range. An expression of the form: a to b by c */
                  xAxisLabel        = ,                   /* X-axis label */      
                  xAxisLabelSize    = 10,                 /* Point size for x-axis and tick mark labels */                 
                  yAxis             = ,                   /* Specifies the y-axis range. An expression of the form: a to b by c  */
                  yAxisLabel        = ,                   /* Y-axis label */ 
                  yAxisLabelSize    = 10,                 /* Point size for y-axis and tick mark labels */                    
                  pointSize         = 10                  /* Point size for headers, titles and footnotes */                                             
                  );

  %local MacroVersion MacroName;
  %let MacroVersion = 1;
  %let MacroName = &sysmacroname;

  * Echo values of local and global macro variables to the log;                                
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals();

  * Define some local macro variables;
  %local pv_abort;
  %let pv_abort = 0;

  * Parameter cleanup;
  %let InputUsage  = %upcase(&InputUsage);
  %let InputUsage  = %nrbquote(&InputUsage);
  %let InputFile   = %nrbquote(&inputFile);  
  %let dataset     = %nrbquote(&dataset);
  %let igdFile     = %nrbquote(&igdFile);
  %let keepSScript = %nrbquote(&keepSScript);
  %let getdatayn   = %nrbquote(&getdatayn);
  %let keepvar     = %nrbquote(&keepvar);

  /*-----------------------------------------------------------------------*/
  /* Parameter Validation */
  
  /*--PV - INPUT USAGE: check it is C, D, P, or U */
  %if %length(&InputUsage) = 0 %then %do; 
    %put %str(RTE)RROR: &macroname: Macro parameter (InputUsage) cannot be blank; 
    %let pv_abort = 1;
  %end;
  %else 
    %tu_valparms(macroname = &macroname., chktype = isOneOf, pv_varsin = InputUsage, valuelist = C D P U, abortyn = N);

  /*--PV - Check parameters that are dependent upon InputUsage are correctly specified */

  /* If InputUsage=D then Dataset shall not be blank */
  %if &InputUsage=D %then %do;
    %if %sysevalf(%length(&dataset)) = 0 %then %do;
      %put %str(RTE)RROR: &macroname: Macro parameter (dataset) cannot be blank when InputUsage=D; 
      %let pv_abort = 1;
    %end;
  %end;

  /* If InputUsage=D then getdatayn shall not be blank and shall have a value of Y or N */
  %if &InputUsage=D %then %do;
    %if %bquote(%upcase(&getdatayn)) eq %then %do;
      %put %str(RTW)ARNING: &macroname: Macro parameter GETDATAYN (getdatayn=&getdatayn) is missing and will be set to Y; 
      %let getdatayn=Y;
    %end;
    %else %do;
      %tu_valparms(macroname = &macroname., chktype = isOneOf, pv_varsin = getdatayn, valuelist = Y N, abortyn = N);
    %end;
  %end;

  /* If InputUsage=D then Dataset shall specify a SAS dataset that exists */
  %if &InputUsage=D %then %do;
    %tu_valparms(macroname = &macroname., chktype = dsetExists, pv_dsetin = dataset , abortyn = N); 
  %end;

  /* If InputUsage=C, P, or U then inputFile shall not be blank */
  %if &InputUsage=C or &InputUsage=P or &InputUsage=U  %then %do;
    %if %sysevalf(%length(&inputFile)) = 0 %then %do;
      %put %str(RTE)RROR: &macroname: Macro parameter (inputFile) cannot be blank when InputUsage=C P or U; 
      %let pv_abort = 1;
    %end;
  %end;

  /* If InputUsage=C then inputFile shall specify the name of a file in the reporting effort refdata folder that does not already exist */
  %if &InputUsage=C %then %do;
    %if %sysfunc(fileexist(&g_rfmtdir./&inputFile)) = 1 %then %do;
      %if %sysevalf(%length(&inputFile)) ne 0 %then %put %str(RTE)RROR: &inputFile : Pre-processing program to be created already exists; 
      %let pv_abort = 1;
    %end;
  %end;

  /* If InputUsage=U or P then inputFile shall specify the name of a file in the reporting effort refdata folder that already exists */
  %if &InputUsage=P or &InputUsage=U  %then %do;
    %if %sysfunc(fileexist(&g_rfmtdir./&inputFile)) = 0 %then %do;      
    %put %str(RTE)RROR: &inputFile : Pre-processing program does not exist; 
      %let pv_abort = 1;
    %end;
  %end;

  /* If InputUsage=D or U then igdFile shall not be blank */
  %if &InputUsage=D or &InputUsage=U %then %do;
    %if %length(&igdFile) = 0 %then %do; 
      %put %str(RTE)RROR: &macroname: Macro parameter (igdFile) cannot be blank when InputUsage=D or U; 
      %let pv_abort = 1;
    %end;
  %end;

  /* If InputUsage=U and dataset parameter is blank then issue a warning to let user know the last dataset created in input file*/
  /* will be used as the input to the IGD file. */
  %if &InputUsage=U %then %do;
    %if %sysevalf(%length(&dataset)) = 0 %then %do;
      %put %str(RTW)ARNING: &macroname: The dataset parameter is blank so the last dataset generated in the &inputfile program; 
      %put %str(RTW)ARNING: &macroname: will be used as the input to the IGD file; 
    %end;
  %end;

  /* If InputUsage=D or U then igdFile shall specify the name of a file in the reporting effort refdata folder that already exists */
  %if &InputUsage=D or &InputUsage=U %then %do;
    %if %sysfunc(fileexist(&g_rfmtdir./&igdFile)) = 0 %then %do;
      %put %str(RTE)RROR: &igdFile : IGD file to render graph does not exist; 
      %let pv_abort = 1;
    %end;
  %end;
  
  /*--PV - keepSScript: check it's 0 or 1 */
  %if &InputUsage=D or &InputUsage=U %then %do;
    %if %length(&keepSScript) = 0 %then %do;
      %put %str(RTW)ARNING: &macroname: Macro parameter keepSScript is not specified. It will be set to 1; 
      %let keepSScript = 1;
    %end;
    %else %do;
      %tu_valparms(macroname = &macroname., chktype = isOneOf, pv_varsin = keepSScript, valuelist = 0 1, abortyn = N);
    %end;
  %end;

  /*--PV - nrtype: check it's NR or CC */
  %if &InputUsage=C %then %do;
      %tu_valparms(macroname = &macroname., chktype = isOneOf, pv_varsin = nrtype, valuelist = CC NR, abortyn = N);
  %end;

  /*--PV - Delete any existing plot file */
  /* Note: we do this even if this call would not create a new one */
  %local plotfile;
  %let plotfile=&G_OUTFILE..&G_TEXTFILESFX;

  %local rc pltfref;
  %if %sysfunc(fileexist(&plotfile)) = 1 %then %do;

    /* Have to assign a fileref before we can use the FDELETE function */
    %let plotfref=oldplot;
    %let rc=%sysfunc(filename(plotfref,&plotfile));
    %if &rc ne 0 %then %do;
      %put %str(RTE)RROR: &macroname: Failed to assign fileref for plot file - return code &rc;
      %let pv_abort = 1;
    %end;
    %else %do;
      %let rc=%sysfunc(fdelete(&plotfref));
      %if &rc ne 0 %then %do;
        %put %str(RTE)RROR: &macroname: Failed to assign fileref for plot file - return code &rc;
        %let pv_abort = 1;
      %end;
    %end;
  %end;

  %if %eval(&g_abort. + &pv_abort.)>0 %then %do;
    %put %str(RTE)RROR: &macroname: Macro has failed parameter validation check for reasons stated with %str(RTE)RRORs above;
    %tu_abort(option=force);
  %end;

  /*----------------------------------------------------------------------*/
  /* Normal Processing */
  /*----------------------------------------------------------------------*/

  %macro splusPlot_write_template(fname);
      
      data _null_; 
        file "&g_rfmtdir./&InputFile";
        %tu_cr8proghead(macname=&InputFile, macdesign=SAS_datastep_not_a_macro);
         
        put " ";
        put "%nrstr(%macro td_lb7tscg_preprocess;)";
        put " ";
        put "%nrstr(%tu_getdata%(dsetin=ardata.lab,)";
        put "%nrstr(            dsetout1=_lb7tscg_1%) )";
        put " ";
        put "%nrstr(data _lb7tscg_2 %(keep=) &g_subjid &g_centid %nrstr(basevar normlvar lbtestcd lbtest lbstunit) &g_trtcd &g_trtgrp &keepvar%nrstr(%);)";
        put "%nrstr(  set _lb7tscg_1; )";
        put "%nrstr(  %if %upcase%(%")&nrtype%nrstr(%"%)=%"NR%" %then %do; )";
        put "%nrstr(    if lbstnrhi ne . then basevar=lbstdbl/lbstnrhi; )";
        put "%nrstr(    if lbstnrhi ne . then normlvar=lbstresn/lbstnrhi; )";
        put "%nrstr(  %end; )";
        put "%nrstr(  %if %upcase%(%")&nrtype%nrstr(%"%)=%"CC%" %then %do; )";
        put "%nrstr(    if lbstcchi ne . then basevar=lbstdbl/lbstcchi; )";
        put "%nrstr(    if lbstcchi ne . then normlvar=lbstresn/lbstcchi; )";
        put "%nrstr(  %end; )";
        put "%nrstr(  if basevar ne . and normlvar ne .; )";
        put "%nrstr(run; )";
        put "%nrstr( )";
        put "%nrstr(proc sort data=_lb7tscg_2 out=_lb7tscg_2;)";
        put "%nrstr(  by) &g_centid &g_subjid &g_trtcd &g_trtgrp &keepvar %nrstr(lbtestcd lbtest lbstunit normlvar; )";
        put "%nrstr(run; )";
        put "%nrstr( )";
        put "%nrstr(data _lb7tscg_3;)";
        put "%nrstr(  set _lb7tscg_2; )";
        put "%nrstr(  by) &g_centid &g_subjid &g_trtcd &g_trtgrp &keepvar %nrstr(lbtestcd lbtest lbstunit normlvar; )";
        put "%nrstr(  if last.lbstunit; )";
        put "%nrstr(run; )";
        put "%nrstr( )";
        put "%nrstr(data _lb7tscg_4;)";
        put "%nrstr(  set _lb7tscg_3; )";
        put "%nrstr(  attrib)";
        put "%nrstr(    basevar length=8  label=%"Baseline Variable%")";
        put "%nrstr(    normlvar  length=8  label=%"Normalized Variable%")";
        put "%nrstr(    ;)";
        put "%nrstr(  retain) &g_centid &g_subjid &g_trtcd &g_trtgrp &keepvar %nrstr(lbtestcd lbtest lbstunit basevar normlvar; )";
        put "%nrstr(run;)";
        put " ";         
        %if "&dataset"^="" %then %do;
          put "%nrstr(data) &dataset%nrstr(;)";
          put "%nrstr(  set _lb7tscg_4; )";
          put "%nrstr(run; )";
          put "%nrstr( )";
        %end;
        put "%nrstr(%mend; )";
        put "%nrstr( )";
        put "%nrstr(%td_lb7tscg_preprocess; )";
        put "%nrstr( )";
      run;    

  %mend splusPlot_write_template;

  %if &InputUsage=C %then %do;
  
    /*----------------------------------------------------------------------*/ 
    /*-- Write template file if wanted */

    %put %str(RTN)OTE: Creating template code file for input dataset; 
    %put %str(RTN)OTE: No graph will be generated;       
    %splusPlot_write_template(usr_prof);

  %end;
  %if &InputUsage=P %then %do;

    %put %str(RTN)OTE: Running template code file for input dataset; 
    %put %str(RTN)OTE: No graph will be generated;       
    %include "&g_rfmtdir./&inputFile";

  %end;
  %if &InputUsage=U or &InputUsage=D %then %do;
    %if &InputUsage=U %then %do;
  
      %include "&g_rfmtdir./&inputFile";

      %if %sysevalf(%length(&dataset)) = 0 %then %do;

        /* If Dataset Parameter is missing then get the last created dataset from the Inputfile to send to the IGD file */
        data work.tscgdata;
          set &syslast;
        run;

        %let dataset=work.tscgdata;

      %end;
      %else %if "%substr(%upcase(&dataset),1,4)"="WORK" or "%index(&dataset,'.')"="0" %then %do;
        /* If a work dataset is specified in the parameter dataset (either with the libname work or with no libname, */
        /* then rename to work.tscgdata so tu_tscgenv will accept dataset name */
        data work.tscgdata;
          set &dataset;
        run;

        %let dataset=work.tscgdata;

      %end;

    %end;
    %if &InputUsage=D %then %do;

      /*
      /   If &getdatayn eq Y then use %tu_getdata to subset the dataset parameter value
      /   Else if &getdatayn ne Y then use the dataset parameter value without subsetting
      /*----------------------------------------------------------------------------------*/ 

      %if %upcase(&getdatayn) eq Y %then %do;
        %tu_getdata(dsetin=&dataset,
                    dsetout1=tscgdata);
        %let dataset=work.tscgdata;
      %end;

    %end;

    /*-- Set up TSCG environment --*/
    %tu_tscgenv(xAxis             = &xAxis,               /* Specifies the x-axis range. An expression of the form: a to b by c */       
                xAxisLabel        = &xAxisLabel,          /* X-axis label */                                                             
                xAxisLabelSize    = &xAxisLabelSize,      /* Point size for x-axis and tick mark labels */                               
                yAxis             = &yAxis,               /* Specifies the y-axis range. An expression of the form: a to b by c  */      
                yAxisLabel        = &yAxisLabel,          /* Y-axis label */                                                             
                yAxisLabelSize    = &yAxisLabelSize,      /* Point size for y-axis and tick mark labels */                               
                pointSize         = &pointSize);          /* Titles and footnotes point size */                                 

    /* Create TSCG plot using the indicated IGD file as a source and writing the output to the named target */
    %tscg_CreateGraph(outputFile  = &g_outfile,           /* Path and name of output file to be created */
                      graphType   = &g_textfilesfx,       /* Graph file format for output */
                      graphDoc    = &g_rfmtdir./&igdfile, /* Path and name of graph document (IGD file) to be used as the basis of the graph */
                      keepSScript = &keepSScript);        /* Logical flag indicating if the script to generate the graph should be retained */       
  %end;
  
  /*----------------------------------------------------------------------*/
  
  %tu_tidyup(glbmac=NONE);
  %tu_abort;
                                                     
%mend td_lb7tscg;
