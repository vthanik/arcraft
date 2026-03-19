/********************************************************************************************
|
| Macro Name:      td_eg8tscg
|
| Macro Version    1
|
| SAS Version:     9.1.3
|
| Created By:      Suzanne Brass (SEJ66932)
|
| Date:            26-April-2011
|
| Macro Purpose:   Create EG8 display using TIBCO Spotfire Clinical Graphics (TSCG)
|
| Macro Design:    Procedure Style
|
| Input Parameters : 
|
| NAME             DESCRIPTION                                           REQ/OPT  DEFAULT         
| -------------------------------------------------------------------------------------------
| INPUTUSAGE       Style of input data: C=Create Pre-processing          Req      <blank>
|                  program, D=Use existing dataset as input for 
|                  template, P=Call pre-processing file to create 
|                  dataset only, U=Call pre-processing file to
|                  create dataset as input for template 
|
| INPUTFILE        Name of pre-processing program located in refdata     Req      <blank>
|                  folder to either create or read in.
|
| DATASET          Name of input dataset for IGD file.                   Req      <blank>
|                  Note this will be the name of the processed  
|                  dataset after calling pre-processing program
|
| IGDFILE          Name of IGD file to call                              Req      <blank>
|
| KEEPSSCRIPT      Logical flag indicating if the script to generate     Req      1
|                  the graph should be retained
|
| GETDATAYN        Execute tu_getdata macro: Yes or No                   Req      Y
|                  Valid values: Y, N
|
| DOMAINCODE       Specifies the type of data in the input dataset,      Req      <blank>
|                  and therefore the pre-processing that is to be 
|                  performed: EG = ECG, LB = LAB
|
| NRTYPE           =NR if Upper limit of Normal Range will be used.      Req      NR
|                  =CC if Upper limit of PCI range will be used. 
|
| XVAR             Name of time variable for x-axis (numeric)            Req      <blank>
|
| YVAR             Name of numeric variable for y-axis (numeric)         Req      <blank>
|
| KEEPVAR          Variables to keep in dataset to group by and sort by  Opt      <blank>
|
| XAXIS            Specifies the x-axis range. An expression             Opt      <blank>
|                  of the form: a to b by c
|
| XAXISLABEL       X-axis label                                          Opt      <blank>
|
| XAXISLABELSIZE   Point size for x-axis and tick mark labels            Req      10
|
| YAXIS            Specifies the y-axis range. An expression             Opt      <blank>
|                  of the form: a to b by c
|
| YAXISLABEL       Y-axis label                                          Opt      <blank>
| 
| YAXISLABELSIZE   Point size for y-axis and tick mark labels            Req      10
|
| POINTSIZE        Point size for headers, titles and footnotes          Req      10
|
| --------------------------------------------------------------------------------------------
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
|********************************************************************************************
| Change Log 
|
| Modified By: 
| Date of Modification: 
| New Version/Build Number:
| Modification ID: 
| Reason For Modification: 
|
********************************************************************************************/
%macro td_eg8tscg(InputUsage     = ,         /* Style of input data: C=Create pre-processing program, D=Use existing dataset as input for template, P=Call pre-processing program, U=Use template */
                  InputFile      = ,         /* Name of pre-processing program located in refdata folder to either create or read in. No folder path is required - only the file name - e.g. cr8_eg8tscg.sas  */
                  dataset        = ,         /* Name of input dataset for IGD file. Note this will be the name of the processed dataset after calling pre-processing program.  2-level name required - e.g. dddata.eg8tscg */
                  igdFile        = ,         /* Name of IGD file to call located in refdata folder. No folder path is required - only the file name - e.g. eg8tscg.igd  */
                  keepSScript    = 1,        /* Logical flag indicating if the script to generate the graph should be retained (=1, keep Script; =0, delete Script) */
                  getdatayn      = Y,        /* Control execution of tu_getdata (Y/N) */
                  domainCode     = ,         /* This specifies the type of data in the input dataset, and therefore the pre-processing that is to be performed. EG=ECG or LB=LAB */
                  nrtype         = NR,       /* =NR if Upper limit of Normal Range will be used. =CC if Upper limit of PCI range will be used */
                  xvar           = ,         /* Name of time variable for x-axis (numeric) */
                  yvar           = ,         /* Name of change in QTc variable for y-axis (numeric) */
                  keepVar        = ,         /* Variable(s) to keep on dataset to group by and sort by */
                  xAxis          = ,         /* Specifies the x-axis range. An expression of the form: a to b by c */
                  xAxisLabel     = ,         /* X-axis label */      
                  xAxisLabelSize = 10,       /* Point size for x-axis and tick mark labels */                 
                  yAxis          = ,         /* Specifies the y-axis range. An expression of the form: a to b by c  */
                  yAxisLabel     = ,         /* Y-axis label */ 
                  yAxisLabelSize = 10,       /* Point size for y-axis and tick mark labels */                    
                  pointSize      = 10        /* Point size for headers, titles and footnotes */ 
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
  %let InputFile   = %nrbquote(&InputFile); 
  %let dataset     = %nrbquote(&dataset);
  %let igdFile     = %nrbquote(&igdFile);
  %let keepSSCript = %nrbquote(&keepSScript);  
  %let getdatayn   = %nrbquote(&getdatayn);   
  %let domainCode  = %upcase(&domainCode);
  %let domainCode  = %nrbquote(&domainCode);
  %let nrtype      = %upcase(&nrtype);
  %let nrtype      = %nrbquote(&nrtype);
  %let xvar        = %nrbquote(&xvar);
  %let yvar        = %nrbquote(&yvar);
  %let keepVar     = %nrbquote(&keepVar);

  /*-----------------------------------------------------------------------*/
  /* Parameter Validation */
  
  /*--PV - InputUsage: check it is C, D, P, or U */
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
  %if &InputUsage=C or &InputUsage=P or &InputUsage=U %then %do;
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

  /* If InputUsage=P or U then inputFile shall specify the name of a file in the reporting effort refdata folder that already exists */
  %if &InputUsage=P or &InputUsage=U %then %do;
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

  /* If InputUsage=U and dataset parameter is blank then issue a warning to let user know the last dataset created in input file */
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
  
  /*--PV - If InputUsage=C, check domaincode=EG or LB. Cannot be supplied as missing */  
  %if &InputUsage=C %then %do;
    %if %length(&domaincode) = 0 %then %do;
      %put %str(RTE)RROR: &macroname: Macro parameter (domainCode) cannot be blank when InputUsage=C;
      %let pv_abort = 1;
    %end;
    %else %if (&domaincode NE EG) and (&domaincode NE LB) %then %do;
      %put %str(RTE)RROR: &macroname: Value of DOMAINCODE(=&domaincode) is invalid. Valid values are one of EG, LB;
      %let pv_abort=1;
    %end; 
  %end;
   
  /*--PV - If InputUsage=C then xvar and yvar shall not be blank */ 
  %if &InputUsage=C %then %do;  
    %let listvars=xvar yvar;
  
    %do loopi=1 %to 2;
      %let thisvar=%scan(&listvars, &loopi, %str( ));
      %let &thisvar=%nrbquote(&&&thisvar);    
      %if &&&thisvar eq %then %do;
        %put %str(RTE)RROR: &macroname: Macro parameter (&thisvar) cannot be blank when InputUsage=C;
        %let pv_abort=1;
      %end;    
    %end;  /* end of do-to loop */ 
  %end;
  
  /*--PV - If InputUsage=C and domaincode=LB, nrtype cannot be supplied as missing */
  %if &InputUsage=C  and &domainCode=LB %then %do;
    %if %length(&nrtype) = 0 %then %do;
      %put %str(RTE)RROR: &macroname: Macro parameter (nrtype) cannot be blank when InputUsage=C and domainCode=LB;
      %let pv_abort = 1;
    %end;
    %else %if (&nrtype NE NR) and (&nrtype NE CC) %then %do;
      %put %str(RTE)RROR: &macroname: Value of NRTYPE(=&nrtype) is invalid. Valid values are one of NR, CC;
      %let pv_abort=1;
    %end; 
  %end;  
 
  /*-----------------------------------------------------------------------*/
  /* Complete parameter validation */
  %if %eval(&g_abort. + &pv_abort.) gt 0 %then %do;
    %put %str(RTE)RROR: &macroname: Macro has failed parameter validation check for reasons stated with %str(RTE)RRORs above;
    %tu_abort(option=force);
  %end;
  /*----------------------------------------------------------------------*/
   
  /*----------------------------------------------------------------------*/
  /* Normal Processing */
  /*----------------------------------------------------------------------*/

  %macro splusPlot_write_template(fname);
      
    data _null_; 
      file "&g_rfmtdir./&InputFile";
      %tu_cr8proghead(macname=&InputFile, macdesign=SAS_datastep_not_a_macro);
        
      put " ";
      put "%nrstr(%macro td_eg8tscg_preprocess;)";     
      put " ";
      %if &domaincode=EG %then %do;
        put "%nrstr(%tu_getdata%(dsetin=ardata.eganal,)";
        put "%nrstr(             dsetout1=dset1%) )";
      %end;
      %if &domaincode=LB %then %do;
        put "%nrstr(%tu_getdata%(dsetin=ardata.lab,)";
        put "%nrstr(             dsetout1=dset1%) )";
      %end;        
      put " ";
      %if &domaincode=LB %then %do;       
        put "/* Normalise lab data results */"; 
        put "%nrstr(data dset2;)";
        put "%nrstr(  set dset1;)";       
        put "%nrstr(  %if) &nrtype=NR %then %do;";
        put "%nrstr(    if lbstnrhi ne . then lbstresn=lbstresn/lbstnrhi; )";
        put "%nrstr(  %end; )";
        put "%nrstr(  %else %if) &nrtype=CC %then %do;";
        put "%nrstr(    if lbstcchi ne . then lbstresn=lbstresn/lbstcchi; )";
        put "%nrstr(  %end; )"; 
        put "%nrstr(run; )";  
      %end;
      put "%nrstr(data dset3;)";
      %if &domaincode=LB %then %do;        
        put "%nrstr(  set dset2;)";
      %end;
      %else %if &domaincode=EG %then %do;
        put "%nrstr(  set dset1;)";     
      %end;  
      put "%nrstr(proc sort;)";
      put "%nrstr(  by) &g_centid &g_subjid &g_trtcd &g_trtgrp &keepvar &xvar;";
      put "%nrstr(run; )";
      put " ";  
      put "%nrstr(data final%(keep=)&g_centid &g_subjid &g_trtcd &g_trtgrp &domaincode.testcd &domaincode.test &keepvar &xvar &yvar);";
      put "%nrstr(  retain) &g_centid &g_subjid &g_trtcd &g_trtgrp &domaincode.testcd &domaincode.test &keepvar &xvar &yvar;";  
      put "%nrstr(    set dset3;)";	        
      put "%nrstr(run;)";
      put " "; 
      %if "&dataset"^="" %then %do;
        put "%nrstr(data) &dataset%nrstr(;)";
        put "%nrstr(  set final; )";
        put "%nrstr(run; )";
        put "%nrstr( )";
      %end;
      put "%nrstr(%mend; )";   
      put "%nrstr( )";
      put "%nrstr(%td_eg8tscg_preprocess; )";
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
  
    %put %str(RTN)OTE: Creating template code file for input dataset; 
    %put %str(RTN)OTE: No graph will be generated;       
    %include "&g_rfmtdir./&inputFile";
  
  %end;
  %if &InputUsage=D or &InputUsage=U %then %do;
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
        /* If a work dataset is specified in the parameter dataset (either with the libname work or with no libname) */
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
                                                                    
%mend td_eg8tscg;
