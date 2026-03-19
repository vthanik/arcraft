/*---------------------------------------------------------------------------------+
| Macro Name    : tu_tscgenv.sas
|
| Macro Version : 2
|
| SAS version   : 9.1.3
|
| Created By    : Suzanne Brass (SEJ66932)
|
| Date          : 12-Apr-2011
|
| Macro Purpose : Set up TSCG environment and pass in HARP headers and footers
|
| Macro Design  : Procedure style
|
| Input Parameters :
|
| NAME              DESCRIPTION                                   REQ/OPT  DEFAULT
| ---------------------------------------------------------------------------------
| XAXIS             Specifies the x-axis range. An expression     Opt      <blank>
|                   of the form: a to b by c
|
| XAXISLABEL        X-axis label                                  Opt      <blank>
|
| XAXISLABELSIZE    Point size for x-axis and tick mark labels    Req      10
|
| YAXIS             Specifies the y-axis range. An expression     Opt      <blank>
|                   of the form: a to b by c
|
| YAXISLABEL        Y-axis label                                  Opt      <blank>
|
| YAXISLABELSIZE    Point size for y-axis and tick mark labels    Req      10
|
| POINTSIZE         Point size for headers, titles and footnotes  Req      10
|
| Output: None
|
| Global macro variables created: l_title1 l_title2 l_title3 l_title4 l_title5
|                                 l_title6 l_title7 l_foot1  l_foot2  l_foot3   
|                                 l_foot4  l_foot5  l_foot6  l_foot7  l_foot8  
|                                 l_foot9  
|
| Macros called :
| (@) tr_putlocals
| (@) tu_putglobals 
| (@) tu_valparms
| (@) tu_header
| (@) tu_footer
| (@) tu_abort
|
| **********************************************************************************
| Change Log :
|
| Modified By :             Suzanne Brass (SEJ66932)          
| Date of Modification :    21-Sept-2011 
| New Version Number :      2     
| Modification ID :         SEB001      
| Reason For Modification : 1. Removed code to set up paths and libnames for TSCG files 
|                           copied to reporting effort code directory as no longer
|                           required.
|                           2. Added code to replace special characters (&,<,>,',") found 
|                           in headers,titles or footnotes with pre-defined XML escape 
|                           sequences to prevent errors in S-plus log
|
| Modified By :          
| Date of Modification :  
| New Version Number :     
| Modification ID :     
| Reason For Modification : 
|
|+--------------------------------------------------------------------------------*/
%macro tu_tscgenv(xAxis             = ,     /* Specifies the x-axis range. An expression of the form: a to b by c */
                  xAxisLabel        = ,     /* X-axis label */      
                  xAxisLabelSize    = 10,   /* Point size for x-axis and tick mark labels */                 
                  yAxis             = ,     /* Specifies the y-axis range. An expression of the form: a to b by c  */
                  yAxisLabel        = ,     /* Y-axis label */ 
                  yAxisLabelSize    = 10,   /* Point size for y-axis and tick mark labels */                    
                  pointSize         = 10    /* Point size for headers, titles and footnotes */                                             
                  );                                  

  %global l_title1 l_title2 l_title3 l_title4 l_title5 l_title6 l_title7  
          l_foot1  l_foot2  l_foot3  l_foot4  l_foot5  l_foot6  l_foot7  l_foot8 l_foot9;  
          
  %local MacroVersion MacroName;
  %let MacroVersion = 2;
  %let MacroName = &sysmacroname;

  * Echo values of local and global macro variables to the log;  
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals();

  * Define some local macro variables;
  %local pv_abort;
  %let pv_abort = 0;
       
  /*-----------------------------------------------------------------------*/
  /* Parameter Validation */
  
  /* PV - Check parameters are not <blank> and are NUMERIC */
  %local l_list l_i l_thisvar;
  %let l_list = xAxisLabelSize yAxisLabelSize pointSize;
  
  %let l_i=1;
  %do %while (%length(%scan(&l_list, &l_i, %str( ))) > 0);
    %let l_thisvar=%scan(&l_list, &l_i, %str( ));
    %if %length(&&&l_thisvar) = 0 %then %do;
      %put %str(RTE)RROR: &macroname: Macro parameter(&l_thisvar) cannot be blank; 
      %let pv_abort = 1;          
    %end;
    %else %do;
      %if %datatyp(&&&l_thisvar) ne NUMERIC %then %do;
        %put %str(RTE)RROR: &macroname: Macro parameter(&l_thisvar) value (&&&l_thisvar) is not NUMERIC;
        %let pv_abort = 1;
      %end;
      %else %if &&&l_thisvar le 0 %then %do; 
        %put %str(RTE)RROR: &macroname: Macro parameter(&l_thisvar) value (&&&l_thisvar) should be positive; 
        %let pv_abort = 1;
      %end; 
    %end;
    %let l_i=%eval(&l_i+1);
  %end; 
  
  /* PV - Check that the output file format is a valid HARP and TSCG file extension i.e. JPG or PDF */
  %let g_textfilesfx = %upcase(&g_textfilesfx);
  %tu_valparms(macroname = &macroname., chktype = isOneOf, pv_varsin = g_textfilesfx, valuelist = JPG PDF, 
               abortyn   = N);

  /*- complete parameter validation */
  %if %eval(&g_abort. + &pv_abort.) gt 0 %then %do;
    %put %str(RTE)RROR: &macroname: Macro has failed parameter validation check for reasons stated with %str(RTE)RRORs above;
    %tu_abort(option=force);
  %end;
 
  /*----------------------------------------------------------------------*/
  /* Normal Processing */
  /*----------------------------------------------------------------------*/
  
  %local prefix;
  %let prefix = _tu_tscgenv;   /* Root name for temporary work datasets */
        
  /* Run tscg_Configuration */
  %tscg_Configuration(splusProjectPath=&g_rfmtdir);
     
  /* Set debug level for TSCG according to value of global macro variable g_debug */
  %let tscg_debug = &g_debug;

  /* Run tscg_addGraphParm according to value of InputUsage */
  %if &InputUsage=U %then %do;

    %if %upcase("&dataset")="WORK.TSCGDATA" %then %do;

      %tscg_addGraphParm(name  = DataSource,                                  /* Name of run-time parameter value */
                         value = %sysfunc(pathname(work))/tscgdata.sas7bdat); /* Run-time parameter value */ 
    %end;
    %else %do;
       
      /* Define path of DD dataset used as the input dataset for the plot */
      %let ppath=%lowcase(%scan(&dataset,1))/%scan(&dataset,2).sas7bdat;  
      
      %tscg_addGraphParm(name  = DataSource,    /* Name of run-time parameter value */
                         value = &&g_&ppath);   /* Run-time parameter value */  
    %end;

  %end;
  %else %if &InputUsage=D %then %do;

    %if %upcase(&getdatayn) eq Y %then %do;

      %tscg_addGraphParm(name  = DataSource,                                  /* Name of run-time parameter value */
                         value = %sysfunc(pathname(work))/tscgdata.sas7bdat); /* Run-time parameter value */ 
    %end;
    %else %do;
    
      /* Define path of DD dataset used as the input dataset for the plot */
      %let ppath=%lowcase(%scan(&dataset,1))/%scan(&dataset,2).sas7bdat;     

      %tscg_addGraphParm(name  = DataSource,    /* Name of run-time parameter value */
                         value = &&g_&ppath);   /* Run-time parameter value */  
    %end;
  %end; 
  
  /* Call tu_header and creation of macro variables for titles */ 
  %tu_header;
   
  data &prefix._title;
    set sashelp.vtitle(where=(type='T'));
    l_title="l_title"||trim(left(_N_));
    call symput(l_title,trim(text));
    text=""; 
  run;
  
  /* Call tu_footer and creation of macro variables for footnotes */
  %tu_footer(dsetout=temp);
     
  data &prefix._foot;
    set sashelp.vtitle(where=(type='F'));
    l_foot="l_foot"||trim(left(_N_));
    call symput(l_foot,trim(text));
    text="";
  run;
 
  /* SEB001: If any of the following characters exist in the headers, titles or footnotes,
  / replace with corresponding pre-defined escape sequences for XML to prevent errors     
  / relating to XML in the S-plus log: &, <, > ', "  
  /---------------------------------------------------------------------------------------*/
  %do i=1 %to %eval(&g_header0);
    %let l_title&i=%superq(l_title&i);
    %if %qsysfunc(indexc(&&l_title&i,"&"))>0 %then %let l_title&i = %qsysfunc(tranwrd(&&l_title&i,%str(&),%nrstr(&amp;)));
    %if %qsysfunc(indexc(&&l_title&i,"<"))>0 %then %let l_title&i = %qsysfunc(tranwrd(&&l_title&i,%str(<),%nrstr(&lt;)));  
    %if %qsysfunc(indexc(&&l_title&i,">"))>0 %then %let l_title&i = %qsysfunc(tranwrd(&&l_title&i,%str(>),%nrstr(&gt;)));    
    %if %qsysfunc(indexc(&&l_title&i,"'"))>0 %then %let l_title&i = %qsysfunc(tranwrd(&&l_title&i,%str(%'),%nrstr(&apos;)));      
    %if %qsysfunc(indexc(&&l_title&i,'"'))>0 %then %let l_title&i = %qsysfunc(tranwrd(&&l_title&i,%str(%"),%nrstr(&quot;)));
  %end;
  %do i=1 %to %eval(&g_footer0);
    %let l_foot&i=%superq(l_foot&i);
    %if %qsysfunc(indexc(&&l_foot&i,"&"))>0 %then %let l_foot&i = %qsysfunc(tranwrd(&&l_foot&i,%str(&),%nrstr(&amp;)));  
    %if %qsysfunc(indexc(&&l_foot&i,"<"))>0 %then %let l_foot&i = %qsysfunc(tranwrd(&&l_foot&i,%str(<),%nrstr(&lt;)));  
    %if %qsysfunc(indexc(&&l_foot&i,">"))>0 %then %let l_foot&i = %qsysfunc(tranwrd(&&l_foot&i,%str(>),%nrstr(&gt;)));     
    %if %qsysfunc(indexc(&&l_foot&i,"'"))>0 %then %let l_foot&i = %qsysfunc(tranwrd(&&l_foot&i,%str(%'),%nrstr(&apos;)));   
    %if %qsysfunc(indexc(&&l_foot&i,'"'))>0 %then %let l_foot&i = %qsysfunc(tranwrd(&&l_foot&i,%str(%"),%nrstr(&quot;)));  
  %end;

  /* Add headers and footers */ 
  %tscg_Titles(%do i=1 %to 2;
                 header&i = &&l_title&i,         /* Text string to use for the plot header(s) */
               %end;  
               %do i=3 %to %eval(&g_header0);
                 title%eval(&i-2) = &&l_title&i, /* Text string to use for the plot title(s) */
               %end;
               %do i=1 %to %eval(&g_footer0);
                 footer&i = &&l_foot&i,          /* Text string to use for the plot footer(s) */
               %end;
               subTitle1 =); 
     
  /* X-axis label and range */
  %tscg_Axis(name              = X,                     /* Character string containing name of X or Y axis */
             labelEnabled      = True,                  /* TRUE to print the axis label, otherwise FALSE */
             label             = &xAxisLabel,           /* X-axis label */
             from              = %scan(&xAxis,1," "),   /* Numeric value for the minimum of the X-axis */
             to                = %scan(&xAxis,3," "),   /* Numeric value for the maximum of the X-axis */
             by                = %scan(&xAxis,5," "));  /* Numeric value for the intervals between major tick marks */
 
  /* Point size for x-axis and tick mark labels */
  %tscg_InsertGraphParm(action = Replace,               /* Action to be applied, either update (add/replace) or delete */
                        name   = XScale.FontSize,       /* The name of the run-time parameter value */
                        value  = &xAxisLabelSize);      /* The run-time parameter value */ 
                        
  %tscg_InsertGraphParm(action = Replace,               /* Action to be applied, either update (add/replace) or delete */
			name   = XAxisLabel.FontSize,   /* The name of the run-time parameter value */
			value  = &xAxisLabelSize);      /* The run-time parameter value */                 				                                                 
  
  /* Y-axis label and range */
  %tscg_Axis(name              = Y,                     /* Character string containing name of X or Y axis */
             labelEnabled      = True,                  /* TRUE to print the axis label, otherwise FALSE */
             label             = &yAxisLabel,           /* Y-axis label */
             from              = %scan(&yAxis,1," "),   /* Numeric value for the minimum of the Y-axis */
             to                = %scan(&yAxis,3," "),   /* Numeric value for the maximum of the Y-axis */
             by                = %scan(&yAxis,5," "));  /* Numeric value for the intervals between major tick marks */
 
  /* Point size for y-axis and tick mark labels */
  %tscg_InsertGraphParm(action = Replace,               /* Action to be applied, either update (add/replace) or delete */
                        name   = YScale.FontSize,       /* The name of the run-time parameter value */
                        value  = &yAxisLabelSize);      /* The run-time parameter value */ 
                       
  %tscg_InsertGraphParm(action = Replace,               /* Action to be applied, either update (add/replace) or delete */
			name   = YAxisLabel.FontSize,   /* The name of the run-time parameter value */
                        value  = &yAxisLabelSize);      /* The run-time parameter value */ 
 
  /* Page setup - set to standard IDSL sizes */
  %tscg_Page(units             = in,                    /* The units for page measurements */
             width             = 11,                    /* Page width in inches */
             height            = 8.5,                   /* Page height in inches */
             outerMarginTop    = 1.25,                  /* Page top margin in inches */
             outerMarginBottom = 1.25,                  /* Page bottom margin in inches */
             outerMarginLeft   = 1,                     /* Page left margin in inches */
             outerMarginRight  = 1);                    /* Page right margin in inches */            
   
  /* Header, title and footnote point size */
  %tscg_InsertGraphParm(action = Replace,               /* Action to be applied, either update (add/replace) or delete */
                        name   = Header.FontSize,       /* The name of the run-time parameter value */
                        value  = &pointSize);           /* The run-time parameter value */    
                         
  %tscg_InsertGraphParm(action = Replace,               /* Action to be applied, either update (add/replace) or delete */
                        name   = MainTitle.FontSize,    /* The name of the run-time parameter value */
                        value  = &pointSize);           /* The run-time parameter value */                        
                        
  %tscg_InsertGraphParm(action = Replace,               /* Action to be applied, either update (add/replace) or delete */
                        name   = Footer.FontSize,       /* The name of the run-time parameter value */
                        value  = &pointSize);           /* The run-time parameter value */   
        
  /*----------------------------------------------------------------------*/  
  
%mend tu_tscgenv;
