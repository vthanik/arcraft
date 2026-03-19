/********************************************************************************************
|
| Macro Name:      td_ae10tscg
|
| Macro Version    1
|
| SAS Version:     9.1.3
|
| Created By:      Suzanne Brass (SEJ66932)
|
| Date:            06-May-2011
|
| Macro Purpose:   Create AE10 display using TIBCO Spotfire Clinical Graphics (TSCG)
|
| Macro Design:    Procedure Style
|
| Input Parameters :
|
| NAME               DESCRIPTION                                           REQ/OPT  DEFAULT         
| -------------------------------------------------------------------------------------------
| INPUTUSAGE         Style of input data: C=Create Pre-processing          Req      <blank>
|                    program, D=Use existing dataset as input for 
|                    template, P=Call pre-processing file to create 
|                    dataset only, U=Call pre-processing file to
|                    create dataset as input for template 
|
| INPUTFILE          Name of pre-processing program located in refdata     Req      <blank>
|                    folder to either create or read in
|
| DATASET            Name of input dataset for IGD file.                   Req      <blank>
|                    Note this will be the name of the processed  
|                    dataset after calling pre-processing program
|
| IGDFILE            Name of IGD file to call                              Req      <blank>
| 
| KEEPSSCRIPT        Logical flag indicating if the script to generate     Req      1
|                    the graph should be retained
|
| INCIDENCE_LEVEL    The AE Level at or above which will be displayed      Req      5
| 
| PLACEBO_CODE       Placebo Treatment Code                                Req      <blank>
| 
| ACTIVE_CODE        Active Treatment Code                                 Req      <blank>
|
| XAXIS              Specifies the x-axis range. An expression             Opt      <blank>
|                    of the form: a to b by c
|
| XAXISLABEL         X-axis label                                          Opt      <blank>
|
| XAXISLABELSIZE     Point size for x-axis and tick mark labels            Req      10
| 
| YAXIS              Specifies the y-axis range. An expression             Opt      <blank>
|                    of the form: a to b by c
|
| YAXISLABEL         Y-axis label                                          Opt      <blank>
|   
| YAXISLABELSIZE     Point size for y-axis and tick mark labels            Req      10
|
| POINTSIZE          Point size for headers, titles and footnotes          Req      10
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
| (@) tu_addbignvar
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
%macro td_ae10tscg(InputUsage      = ,        /* Style of input data: C=Create pre-processing program, D=Use existing dataset as input for template, P=Call pre-processing program, U=Use template */
                   InputFile       = ,        /* Name of pre-processing program located in refdata folder to either create or read in. No folder path is required - only the file name - e.g. cr8_ae10tscg.sas  */
                   dataset         = ,        /* Name of input dataset for IGD file. Note this will be the name of the processed dataset after calling pre-processing program.  2-level name required - e.g. dddata.ae10tscg */                 
                   igdFile         = ,        /* Name of IGD file to call located in refdata folder. No folder path is required - only the file name - e.g. ae10tscg.igd  */
                   keepSScript     = 1,       /* Logical flag indicating if the script to generate the graph should be retained (=1, keep Script; =0, delete Script) */
                   incidence_level = 5,       /* AE Level Incidence */
                   placebo_code    = ,        /* Placebo Treatment Code */
                   active_code     = ,        /* Active Treatment Code */                
                   xAxis           = ,        /* Specifies the x-axis range. An expression of the form: a to b by c */
                   xAxisLabel      = ,        /* X-axis label */      
                   xAxisLabelSize  = 10,      /* Point size for x-axis and tick mark labels */                 
                   yAxis           = ,        /* Specifies the y-axis range. An expression of the form: a to b by c  */
                   yAxisLabel      = ,        /* Y-axis label */ 
                   yAxisLabelSize  = 10,      /* Point size for y-axis and tick mark labels */                    
                   pointSize       = 10       /* Point size for headers, titles and footnotes */ 
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
  %let InputUsage      = %upcase(&InputUsage);
  %let InputUsage      = %nrbquote(&InputUsage);
  %let InputFile       = %nrbquote(&InputFile); 
  %let dataset         = %nrbquote(&dataset);
  %let igdFile         = %nrbquote(&igdFile);
  %let keepSScript     = %nrbquote(&keepSScript);
  %let incidence_level = %nrbquote(&incidence_level);
  %let placebo_code    = %nrbquote(&placebo_code);  
  %let active_code     = %nrbquote(&active_code);  
 
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
   
  /*--PV - If InputUsage=C, check incidence level is a number between 0 and 100 and is not blank */
  %if &InputUsage=C %then %do;
    %if %length(&incidence_level) = 0 %then %do;
      %put %str(RTW)ARNING: &macroname: Macro parameter incidence_level is not specified. It will be set to 5; 
      %let incidence_level = 5;
    %end;
    %else %if %datatyp(&incidence_level) = CHAR %then %do;
      %put RTE%STR(RROR): &macroname: incidence_level(&incidence_level.) is character and should be numeric.;
      %let pv_abort = 1;
    %end; 
    %else %if (0 gt &incidence_level.) or (&incidence_level. gt 100) %then %do;
      %put RTE%STR(RROR): &macroname: incidence_level(&incidence_level) is not between 0 and 100;
      %let pv_abort = 1; 
    %end;
  %end;
  
  /*--PV - If InputUsage=C then placebo_code and active_code shall not be blank */ 
  %if &InputUsage=C %then %do;
    %let listvars=placebo_code active_code;
    
    %do loopi=1 %to 2;
      %let thisvar=%scan(&listvars, &loopi, %str( ));
      %let &thisvar=%nrbquote(&&&thisvar);    
      %if &&&thisvar eq %then %do;
        %put %str(RTE)RROR: &macroname: Macro parameter (&thisvar) cannot be blank when InputUsage=C;
        %let pv_abort=1;
      %end;  
      %else %if %datatyp(&&&thisvar) = CHAR %then %do;
        %put RTE%STR(RROR): &macroname: Macro parameter (&thisvar) is character and should be numeric.;
        %let pv_abort = 1;
      %end;       
    %end;  /* end of do-to loop */ 
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
      put "%nrstr(%macro td_ae10tscg_preprocess;)";
      put " ";
      put "%nrstr(%tu_getdata%(dsetin=ardata.ae,)";
      put "%nrstr(             dsetout1=ae1,)";
      put "%nrstr(             dsetout2=popdata%) )";
      put " ";
      put "%nrstr(proc sort data=ae1 out=ae2 nodupkey;)"; 
      put "%nrstr(  where) &g_trtcd in (&placebo_code &active_code);";          
      put "%nrstr(  by) &g_trtcd &g_trtgrp &g_centid &g_subjid aept;";
      put "%nrstr(run; )";
      put " "; 
      put "/* Calculate number and % of subjects with each AE */";
      put "%nrstr(proc freq data=ae2 noprint;)";
      put "%nrstr(  table) &g_trtcd*&g_trtgrp*aept/out=ae3;";
      put "%nrstr(run; )";
      put "%nrstr(quit; )"; 
      put " "; 
      put "%nrstr(%tu_addbignvar%(dsetintoaddbign=ae3,)";  
      put "%nrstr(                dsetintocount=popdata,)";
      put "%nrstr(                countdistinctwhatvar=)&g_centid &g_subjid,";  
      put "%nrstr(                groupbyvars=)&g_trtcd,";
      put "%nrstr(                dsetout=ae4%) )";
      put " "; 
      put "%nrstr(proc sort data=ae4;)";
      put "%nrstr(  by aept;)";
      put "%nrstr(run; )";
      put " "; 
      put "/* Calculate relative risk and 95% confidence intervals */";
      put "%nrstr(proc transpose data=ae4 out=trans1 prefix=count;)";
      put "%nrstr(  var count;)";
      put "%nrstr(  by aept;)";
      put "%nrstr(  id) &g_trtcd;";
      put "%nrstr(run;)";
      put "%nrstr(quit;)";
      put " "; 
      put "%nrstr(proc transpose data=ae4 out=trans2 prefix=bigN;)";
      put "%nrstr(  var bigN;)";
      put "%nrstr(  by aept;)";
      put "%nrstr(  id) &g_trtcd;";
      put "%nrstr(run;)";
      put "%nrstr(quit;)";   
      put " "; 
      put "%nrstr(data ae5;)";
      put "%nrstr(  merge trans1%(drop=_name_ _label_%) trans2%(drop=_name_ _label_%);)";
      put "%nrstr(  by aept;)";
      put "    if count&placebo_code gt 0 and count&active_code gt 0 then do;";
      put "      rr = (count&active_code/bigN&active_code)/(count&placebo_code/bigN&placebo_code);";
      put "      se = sqrt(((bigN&placebo_code-count&placebo_code)/(count&placebo_code*bigN&placebo_code))";
      put "               +((bigN&active_code-count&active_code)/(count&active_code*bigN&active_code)));";
      put "      rrlower = exp(log(rr) + se*(-1.96));";
      put "      rrupper = exp(log(rr) + se*(1.96));";        
      put "      actpct = (count&active_code/bigN&active_code)*100;";
      put "      plcpct = (count&placebo_code/bigN&placebo_code)*100;";
      put "      /* Only keep the records with incidence level at or above the specified level */";
      put "%nrstr(      if round%(plcpct%) ge) &incidence_level or round(actpct) ge &incidence_level then output;"; 
      put "%nrstr(    end;)";       
      put "%nrstr(run;)";
      put " ";       
      put "%nrstr(proc transpose data=ae5 out=trans3%(rename=%(col1=denom%)%);)";
      put "  var count&placebo_code count&active_code;";
      put "%nrstr(  by aept;)";
      put "%nrstr(run;)";
      put "%nrstr(quit;)"; 
      put " "; 
      put "%nrstr(data ae6;)";        
      put "%nrstr(  set trans3;)";
      put "    &g_trtcd = scan(_name_, -1, 'count')*1;";
      put "%nrstr(proc sort;)";
      put "%nrstr(  by aept) &g_trtcd;";
      put "%nrstr(run;)";        
      put " "; 
      put "%nrstr(proc transpose data=ae5 out=trans4%(rename=%(col1=percent%)%);)";
      put "%nrstr(  var actpct plcpct;)";
      put "%nrstr(  by aept;)";
      put "%nrstr(run;)";
      put "%nrstr(quit;)";         
      put " "; 
      put "%nrstr(data ae7;)";
      put "%nrstr(  set trans4;)";
      put "%nrstr(    if _name_=%"plcpct%" then) &g_trtcd=&placebo_code;";
      put "%nrstr(    else if _name_=%"actpct%" then) &g_trtcd=&active_code;";
      put "%nrstr(proc sort;)";
      put "%nrstr(  by aept) &g_trtcd;";
      put "%nrstr(run;)";   
      put " "; 
      put "%nrstr(data ae8%(drop=_name_%);)";
      put "%nrstr(  merge ae6 ae7;)";
      put "%nrstr(  by aept) &g_trtcd;";
      put "%nrstr(proc sort;)";
      put "%nrstr(  by) &g_trtcd;";
      put "%nrstr(run;)";   
      put " "; 
      put "/* Create treatment group label */";        
      put "%nrstr(data trtlbl%(keep=) &g_trtcd trtgrp);";
      put "%nrstr(  set ae4;)";
      put "    trtgrp = trim(left(&g_trtgrp)) || %nrstr(%" %(N=%" || trim%(left%(bigN%)%) || %"%)%");";        
      put "%nrstr(proc sort nodupkey;)";
      put "%nrstr(  by) &g_trtcd;";
      put "%nrstr(run;)";
      put " "; 
      put "%nrstr(data ae9;)";
      put "%nrstr(  merge ae8 trtlbl;)";
      put "%nrstr(    by) &g_trtcd;";
      put "    trtcd = &g_trtcd;";
      put "%nrstr(proc sort;)";
      put "%nrstr(  by aept;)";
      put "%nrstr(run;)";        
      put " "; 
      put "%nrstr(data ae10;)";
      put "%nrstr(  merge ae9 ae5%(keep=aept rr rrlower rrupper%);)";
      put "%nrstr(    by aept;)";
      put "%nrstr(run;)"; 
      put " "; 
      put "%nrstr(data final %(keep=trtcd trtgrp aept percent rr rrlower rrupper%);)";
      put "  /* Data set must contain one observation for each adverse event to be displayed */";
      put "  /* The dataset shall contain one observation per treatment group per event */";
      put "  /* The RR, RRLOWER and RRUPPER variables shall have the same value for each event by-group */";       
      put "  /* AEPT is to be used as the y-axis */";
      put "  /* PERCENT is the percentage of subjects experiencing the AE for each TRTGRP.To be used as the left hand panel x-axis */";
      put "  /* RR is the relative risk summary statistic to be used on the right hand panel x-axis */";
      put "  /* RRLOWER is the lower CI limit of the relative risk on the right hand panel x-axis */";
      put "  /* RRUPPER is the upper CI limit of the relative risk on the right hand panel x-axis */";   
      put "%nrstr(  attrib)";
      put "%nrstr(trtcd    length=8    label=%"Treatment code%")";
      put "%nrstr(trtgrp   length=$120 label=%"Treatment label to appear in the legend%")";      
      put "%nrstr(aept     length=$120 label=%"Adverse event preferred term%")";
      put "%nrstr(percent  length=8    label=%"Percentage of subjects experiencing AE%")";
      put "%nrstr(rr       length=8    label=%"Relative risk summary statistic%")";
      put "%nrstr(rrlower  length=8    label=%"Lower CI limit of relative risk%")";
      put "%nrstr(rrupper  length=8    label=%"Upper CI limit of relative risk%")";
      put "%nrstr(  ;)";
      put "%nrstr(  set ae10;)";
      put "%nrstr(run;)";     
      put " ";         
      %if "&dataset"^="" %then %do;
        put "%nrstr(data) &dataset%nrstr(;)";
        put "%nrstr(  set final;)";
        put "%nrstr(run; )";
        put "%nrstr( )";
      %end;
      put "%nrstr(%mend; )";
      put "%nrstr( )";
      put "%nrstr(%td_ae10tscg_preprocess; )";
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
      
    /*  If InputUsage=D, set getdatayn = N to pass a value to tu_tscgenv macro */
    %if &InputUsage=D %then %do;      
      %let %upcase(getdatayn)=N;   
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
                                                                    
%mend td_ae10tscg;
