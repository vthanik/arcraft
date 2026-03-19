/*******************************************************************************
|
| Macro Name:      tu_pktfig
|
| Macro Version:   4 Build 1
|
| SAS Version:     9.4
|                                                             
| Created By:      James McGiffen / Andrew Ratcliffe, RTSL
|
| Date:            13-Dec-2004
|
| Macro Purpose:   To create graphs of concentration data versus time values
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME             DESCRIPTION                           REQ/OPT  DEFAULT
| --------------   -----------------------------------   -------  --------------
| * INPUT/OUTPUT     *
| dsetin           Input dataset                           REQ    ardata.PKCNC
| figtype          Plot Type (Linear, log, Linear log)     REQ    Linear log
| style            Type of graph (mean, individual, etc)   REQ    MEAN
| bars             Bars for graph (SD, RANGE, NONE)        REQ    NONE
| llqline          LLQ line required?                      REQ    N
| postsubset       Subset in WHERE clause format           OPT    [blank]
| * AXIS             *
| xvar             X-Axis and optional Units               REQ    [blank]
| xmin             Minimum for X-axis                      OPT    [blank]
| xmax             Maximum for X-axis                      OPT    [blank]
| xint             Interval for X-axis                     OPT    [blank]
| xlabel           X-Axis Label                            OPT    [blank]
| xrange           X-Axis range by all (ALL) or byvar (BY) OPT    ALL
| href             X-Axis reference line                   OPT    [blank]
| yvar             Y-Var and optional Units                REQ    [blank]
| yint             Y-Order interval                        OPT    [blank]
| ymin             Lower Limit of Y-Axis                   OPT    [blank]
| ymax             Upper limit of Y-Axis                   OPT    [blank]
| ylabel           Y-Axis Label                            OPT    [blank]     
| yrange           X-Axis range by all (ALL) or byvar (BY) OPT    ALL
| vref             Y-Axis reference line                   OPT    [blank]
| ylogbase         Y-Axis Log base                         OPT    10
| ylogstyle        Axis Scale Log Style                    OPT    Expand
| ylogminbasis     Basis for setting log scale y minimum   OPT    MINVAL
| * GROUPING         *
| zvar             3rd Classification Variable.            OPT    [blank]
|                   Optionally includes an ordering var,
|                   e.g. zvar = trtgrp=trtcd
| zrepeatvar        Is trtmnt repeated over period?        OPT    [blank]
|                  - Combines with zvar to make new zvar 
|                    e.g. zvar= period zrepeatvar= visit
|                    will produce one line per 
|                    period/visit combination
|                  - Optionally includes an ordering var,
|                    e.g. zrepeatvar= visit=visitnum
| byvars           BY variables.                           OPT    [blank] 
|                  - Output is paged by BYVARS
|                  - Optionally includes ordering vars,
|                    e.g. byvars=trtgrp=trtcd
|                      or byvars=period=pernum trtgrp=trtcd
| bystyle          Style of BY-line                        OPT    label-equals-comma  
| legendyn         Add a legend (Y/N)                      REQ    N
| legendlabel      Add a legend label (Y/N)                OPT    N
| * DISPLAY OPTIONS *
| frameaxes        Add top and right axis lines?           REQ    Y
| ptsize           Point size of header/footer/by, etc     REQ    10
| gptsize          Relative size of graph text, etc        OPT    [blank]
| topy             Height of top of plot as % of           REQ    95
|                  available plot area             
| boty             Height of bottom of plot as % of        REQ    5
|                  available plot area             
| varlabelstyle    Style of labels for tu_labelvars        REQ    STD
| symbolColor      Colours for symbol statements           OPT    black
| symbolValue      Plot symbols for symbol statements      OPT    diamond plus square X triangle star - hash dot circle : A B C D E F G H
| symbolLine       Lines for symbol statements             OPT    1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
| symbolInterpol   Interpolations for symbol statements    OPT    join
| symbolOther      Other elements for symbol statements    OPT    [blank]
|                  any of: C=color H=height W=width 
|                          V=symbol F=font R=repeat L=line
| symbolOtherDelim Delimiter for SYMBOLOTHER               OPT    /       
| formats          Formats to be applied in the plot       OPT    [blank]
|
| Output: Graphics file containing conc vs time graphs
|
| Global macro variables created: NONE
|
| Macros called:
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_chkvartype
| (@) tu_cr8gbys
| (@) tu_cr8gheadfoots
| (@) tu_cr8glegend
| (@) tu_cr8macarray
| (@) tu_getdata
| (@) tu_gnoreport
| (@) tu_labelvars
| (@) tu_nobs
| (@) tu_putglobals
| (@) tu_sqlnlist
| (@) tu_templates
| (@) tu_tidyup
| (@) tu_valgparms
| (@) tu_words
|
| Example:
| %tu_pktfig(
|     dsetin     = ardata.pkcnc
|   , xvar       = pcwnlrt pcatmu
|   , yvar       = pcstimpn pcstresu
|   , zvar       = period=pernum
|   , zrepeatvar = visit=visitnum
|   , byvars     = subjid
|   , legendyn   = Y
|   , figtype    = linear log
|   , style      = individual
|   , bars       = range
|   , llqline    = Y
|   , ylabel     = Plasma Concentration (mg/mL)
|   , xlabel     = Actual Relative Time (hrs)
|  );
|
|******************************************************************************
| Change Log
|
| Modified By: James McGiffen
| Date of Modification: 16-May-05 
| New version/draft number: 01/002
| Modification ID: JMcG-1.xx
| Reason For Modification: 1.01 - Change the %nrbquote and substr - due to SCR
|                          1.02 - Defaulted in Vardecode if not to stop error - tech issue 108
|                          1.03 - Change SQL to remove warning statement - Initial Testing
|                          1.04 - Added type dependant order statement - Tech issue 108
|                          1.05 - LE replaced with LT - Due to SCR
|                          1.06 - Add format to data going into tu_cr8glegend - Tech Issue 108
|                          1.07 - Tidy up of rterror messages
|
| Modified By:  James McGiffen  
| Date of Modification:  25-May-05
| New version/draft number: 01/003
| Modification ID:JMcG 2.01
| Reason For Modification: 2.01 - Add and upcase to ylogstyle and varlabelstyle.
|
| Modified By:  James McGiffen
| Date of Modification: 9-Jun-05
| New version/draft number: 01/004
| Modification ID: 3.0x
| Reason For Modification: 3.01 - Allow program to run for log only grahs
|                          3.02 - add _ to data null
|                          3.03 - change yvar so default is blank
|
| Modified By:  James McGiffen
| Date of Modification: 15-Jun-05
| New version/draft number: 01/005
| Modification ID: 4.0x
| Reason For Modification: 4.01 - Add a check to ensure that if yllqn is Y then all values of
|                                 pcllqn are above 0
|
| Modified By:  James McGiffen  
| Date of Modification: 20-Jun-05
| New version/draft number: 01/006
| Modification ID: 5.0x
| Reason For Modification: 5.01 - Allow %tu_gnoreport to be called if no data after %tu_getdata
|
| Modified By:  James McGiffen
| Date of Modification: 29-Jun-05
| New version/draft number: 02-001
| Modification ID: jmcg6.0x
| Reason For Modification: JMcG 6.01 - In Response to failed UAT if median is below llq and incllq = N
|                                 then set the median to missing
|
| Modified By:              Warwick Benger
| Date of Modification:     30-Oct-09
| New version/draft number: 03-001
| Modification ID:          WJB.3.01
| Reason For Modification:  Multiple changes per Change Request HRT231, including;
|                           - removal of parameters YLLQ, INCLLQ, XYZERO, DEVICE, FONT, FRAMEPLOT, 
|                             FRAMEPAGE, LEGENDTYPE, LABELVARSYN, OUTFILE, LAYOUT, SYMBOLMAX
|                           - addition of parameters XMIN, XRANGE, YRANGE, YLOGMINBASIS, HREF, VREF, 
|                             POSTSUBSET, FRAMEAXES, LEGENDYN
|                           - correction of dummy row creation to ensure correct BYVAR/ZVAR labelling
|                           - automatic axis ranging by BYVAR or all data (set by XRANGE/YRANGE)
|                           - automatic setting of intervals according to data unit
|                           - change to production of PDF via PS (using PS2PDF)
|                           - correction to ordering of ZVARs, rename/reformat REPEATVAR as ZREPEATVAR
|                           - inclusion of +/-SD (bars=SDB) as well as existing +SD (bars=SD)
|                           - Add POSTSUBSET functionality
|                           - YLOGMINBASIS functionality now allows setting of YMIN=0
|
| Modified By:              Tony Cooper
| Date of Modification:     28-Jul-2016
| New version/draft number: 4 build 1
| Modification ID:          AJC001
| Reason For Modification:  Updated per Change Request HRT0315 following issue found in SAS 9.4
|                           of PS600C device driver being unavailable in SASHELP.DEVICES.
|                           Macro will now copy PS600C from the backup catalog SASHELP.DGDEVICE
|                           if not found in SASHELP.DEVICES.
|
| Modified By:  
| Date of Modification: 
| New version/draft number: 
| Modification ID: 
| Reason For Modification: 
|
*******************************************************************************/
%macro tu_pktfig(

  /* INPUT/OUTPUT     */
   dsetin = ardata.PKCNC         /* type:ID Input dataset                    */
  ,figtype = LINEAR LOG          /* Plot Type (Linear, Log, Linear log)      */
  ,style = MEAN                  /* Graph type (Individual/Mean/Median/Spaghetti)      */    
  ,bars = NONE                   /* Bars to be applied  (SD/SDB/RANGE)       */
  ,llqline = N                   /* LLQ line required? (Y/N/L/C/R)           */
  ,postsubset =                  /* 'Where' clause passed prior to plotting  */
  /* X AXIS           */
  ,xvar =                        /* X-axis (& optional units) variable       */
  ,xmin =                        /* X-axis lower limit                       */
  ,xmax =                        /* X-axis upper limit                       */
  ,xint =                        /* X-axis interval                          */
  ,xlabel =                      /* X-axis label                             */
  ,xrange = ALL                  /* X-axis ranged for all or byvar? (ALL/BY) */
  ,href =                        /* X-axis reference line                    */
  /* Y AXIS           */
  ,yvar=                         /* Y-axis (& optional units) variable       */
  ,ymin =                        /* Y-axis lower limit                       */
  ,ymax =                        /* Y-axis upper limit                       */
  ,yint =                        /* Y-axis interval                          */
  ,ylabel =                      /* Y-axis label                             */
  ,ylogbase = 10                 /* Y-axis log base                          */
  ,ylogstyle = Expand            /* Y-axis scale log style                   */
  ,ylogminbasis = MINVAL         /* Y-axis min extended to inc. LLQ if req?  */
  ,yrange = ALL                  /* Y-axis ranged for all or byvar? (ALL/BY) */
  ,vref =                        /* Y-axis reference line                    */
  /* GROUPING         */						     
  ,zvar =                        /* 3rd Classification Variable              */
  ,zrepeatvar =                  /* Variables to be repeated over zvar       */
  ,byvars =                      /* Variables for by vars                    */
  ,bystyle = label-equals-comma  /* Style of the by line                     */
  ,legendyn = N                  /* Switch On/off legend (Y/N)               */
  ,legendlabel = N               /* Switch On/off legend label (Y/N)         */
  /* DISPLAY OPTIONS  */						     
  ,ptsize = 10                   /* Specifies pt size for title/footer       */
  ,gptsize =                     /* Specifies rel. size for graph text       */
  ,formats =                     /* Formats to be applied in the plot        */
  ,frameAxes = Y                 /* Add top and right axis lines? (Y/N)      */
  ,topy = 95                     /* Specifies highest point of y (% of area) */
  ,boty = 5                      /* Specifies lowest point of y (% of area)  */
  ,varlabelstyle = STD           /* Label style (for tu_labelvars)           */
  ,symbolColor = black           /* Colours for symbol statements            */
  ,symbolInterpol = join         /* Symbol Interpol  (eg JOIN/HILOJC)        */
  ,symbolOther =                 /* Other elements for symbol statements     */
  ,symbolOtherDelim = /          /* Delimiter for SYMBOLOTHER                */
  ,symbolValue = diamond plus square X triangle star - hash dot circle : A B C D E F G H /* Symbols for symbol stmts */
  ,symbolLine = 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 /* Lines for symbol stmts */
  );

  /* Echo parameter values and global macro variables to the log */
 
  %local device MacroVersion prefix currentDataset outfile i;
  %let MacroVersion = 4 Build 1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_analy_disp);

  %let prefix = %substr(&sysmacroname,3); 
  %let macroname = &sysmacroname;
  %let currentDataset=&dsetin;
    
  /* we will not quote/upcase &postsubset */
  /* we will not quote &symbolcolor as it affects other macros */
  %let dsetin=%nrbquote(&dsetin);
  %let figtype=%nrbquote(%upcase(&figtype));
  %let style =%nrbquote(%upcase(&style));
  %let xvar=%nrbquote(&xvar);
  %let xlabel=%nrbquote(&xlabel);
  %let yvar=%nrbquote(&yvar);
  %let ylabel =%nrbquote(&ylabel);
  %let zvar =%nrbquote(&zvar);
  %let xmin =%nrbquote(&xmin);
  %let xmax =%nrbquote(&xmax);
  %let xint =%nrbquote(&xint);
  %let href =%nrbquote(&href);
  %let xrange =%nrbquote(%upcase(&xrange));
  %let ymin =%nrbquote(&ymin);
  %let ymax =%nrbquote(&ymax);
  %let yint =%nrbquote(&yint);
  %let yrange =%nrbquote(%upcase(&yrange));
  %let ylogbase=%nrbquote(&ylogbase);
  %let ylogstyle=%nrbquote(%upcase(&ylogstyle)); /* [JMcG.2.01] Add upcase to ylogstyle  */
  %let ylogminbasis=%nrbquote(%upcase(&ylogminbasis));
  %let vref =%nrbquote(&vref);
  %let legendlabel =%nrbquote(%upcase(&legendlabel));
  %let legendyn =%nrbquote(%upcase(&legendyn));
  %let frameaxes =%nrbquote(%upcase(&frameaxes));
  %let byvars =%nrbquote(&byvars);
  %let bystyle =%nrbquote(%upcase(&bystyle));
  %let topy =%nrbquote(&topy);
  %let boty =%nrbquote(&boty);
  %let ptsize =%nrbquote(&ptsize);
  %let gptsize =%nrbquote(&gptsize);
  %let bars =%nrbquote(%upcase(&bars));
  %let llqline =%nrbquote(%upcase(&llqline));
  %let zrepeatvar =%nrbquote(&zrepeatvar);
  %let symbolvalue =%nrbquote(&symbolvalue);
  %let symbolline =%nrbquote(&symbolLine);
  %let symbolinterpol =%nrbquote(&symbolinterpol);
  %let symbolother =%nrbquote(&symbolother);
  %let symbolotherDelim =%nrbquote(&symbolotherDelim);
  %let varlabelstyle =%nrbquote(%upcase(&varlabelstyle));  /* [JMcG.2.01] Add upcase to varlabelstyle  */
  %let formats =%nrbquote(&formats);  

  %if &g_debug gt 1 %then %put _local_;

  /* HANDLE USER SETTINGS [WJB.3.01] */
  %local addbars llqanno legendtype;

  /* Bars */
  %if &bars eq SD or &bars eq SDB or &bars eq RANGE %then %let addbars = Y;
  %else %let addbars = N;

  /* Summary type */
  %if &style eq MEAN or &style eq MEDIAN %then %let disptyp=SUMMARY;
  %else %let disptyp=NOSUMMARY;
  
  /* Annotation of LLQ line */
  %if &llqline eq L or &llqline eq C or &llqline eq R %then %do;
    %let llqanno = &llqline;
    %let llqline = Y;
  %end;
  %else %do;
    %let llqanno = N;
  %end;

  /* Layout / legend */
  %if &figtype eq LINEAR LOG %then %let layout=2UP;
  %else %let layout=1UP;
  %if &legendyn eq Y and &figtype eq LINEAR LOG %then %let legendtype=ACROSS;
  %else %if &legendyn eq Y %then %let legendtype=INLINE;
  %else %let legendtype=NONE;  

  /* Font size for graphs */
  %local annosize;
  %if %length(&gptsize) eq 0 %then %let gptsize = &ptsize;

  %if &layout eq 1UP and %length(&topy) ne 0 and %length(&boty) ne 0 %then %let annosize=%sysevalf(11/((&topy-&boty)**0.5));
  %else %let annosize=1.7;

  %local outdset actBYvarcode actBYvarname;
  %let outfile = &g_outfile..&g_textfilesfx;
  %let outdset=%scan(&g_outfile,-1,/);

  /* Handle fileref for output file, and removal of previous version of dd dataset */
  %if %sysfunc(exist(dddata.&outdset)) %then %do;
    %str(x rm &g_dddata./&outdset..sas7bdat);
  %end;
  
  data _null_;
    length fileref $8;
    fileref='';
    rc = filename(fileref,"&outfile");
    if rc ne 0 then
    do;
      sysmsg = sysmsg();
      put "RTE" "RROR: &sysmacroname: Attempt to allocate fileref to OUTFILE failed";
      put "RTE" "RROR: &sysmacroname: " sysmsg;
      call symput('G_ABORT','1');
    end;
    else
    do;
      if fexist(fileref) then
      do;  /* file exists, and should be deleted */
        rc = fdelete(fileref);
        if rc ne 0 then
        do;
          sysmsg = sysmsg();
          put "RTE" "RROR: &sysmacroname: Attempt to delete OUTFILE failed";
          put "RTE" "RROR: &sysmacroname: " sysmsg;
          call symput('G_ABORT','1');
        end;
      end; /* file exists, and should be deleted */
      rc = filename(fileref,"");
      if rc ne 0 then
      do;
        sysmsg = sysmsg();
        put "RTE" "RROR: &sysmacroname: Attempt to deallocate fileref for OUTFILE failed";
        put "RTE" "RROR: &sysmacroname: " sysmsg;
        call symput('G_ABORT','1');
      end;
    end;
  run;
  
  /* For PDF/PS outputs, ensure that PS600C driver is available [AJC001] */

  %if &g_textfilesfx=PDF or &g_textfilesfx=PS %then %do;

    %if %sysfunc(cexist(sashelp.devices.ps600c.dev)) %then %do;
      %put RTNOTE: The PS600C device driver exists in sashelp.devices.;
    %end;
    %else %if %sysfunc(cexist(sashelp.dgdevice.ps600c.dev)) %then %do;

      %put RTNOTE: The PS600C device driver exists in sashelp.dgdevice. Copying to work.gdevice0 catalog.;

      %local workdir;
      %let workdir=%trim(%sysfunc(pathname(work)));
     
      libname gdevice0 "&workdir";   
     
      proc catalog c=sashelp.dgdevice;
        copy out=gdevice0.devices;
        select PS600C / et=dev;
      run;
      quit;

    %end;
    %else %do;
      %put RTE%str(RROR): &sysmacroname: The PS600C device driver cannot be found.;
      %let g_abort = 1;
    %end;

  %end;

  /* GRAPHICS DRIVER SETTINGS [WJB.3.01] */
  %let rotate=landscape;
  %local pdfprod;
  %let pdfprod = N;
  %if &g_textfilesfx=PDF %then %do;
    %let pdfprod = Y;
    %let g_textfilesfx=PS;
    %let g_fontsize=PS;
    %let device=PS600C;
    %let font=HWPSL009;
    %let horigin=0.88 in;
    %let vorigin=0.75 in; 
    %let vsize=6.75 in; 
    %let hsize=9.25 in; 
  %end;  
  %else %do;
    %put RTW%str(ARNING): &sysmacroname: Use of output types other than PDF may produce unexpected results and may not support multiple pages.;
    %let horigin=0 in;
    %let vorigin=0 in;
    %if &g_textfilesfx=CGM %then %do;
      %let device=CGMOF97L;
      %let font=HWCGM001;
      %let rotate=portrait;
      %let vsize=6.5 in; 
      %let hsize=8.5 in;
      %let ptsize=%sysevalf(&ptsize/1.2);
      %let gptsize=%sysevalf(&gptsize/2);
      %if %length(&annosize) ne 0 %then %let annosize=%sysevalf(&annosize/3);
    %end;
    %else %if &g_textfilesfx=WMF %then %do;
      %let device=SASWMF;
      %let font=SWISSX;
      %let rotate=;
      %let vsize=6.0 in; 
      %let hsize=9.25 in; 
    %end;  
    %else %if &g_textfilesfx=TIF %then %do;
      %let g_fontsize=TIFFP;
      %let device=TIFFP;
      %let font=SWISS;
      %let vsize=5.5 in; 
      %let hsize=8.5 in; 
    %end;
    %else %if &g_textfilesfx=PNG %then %do;
      %let device=PNG;
      %let font=SIMPLEX;
      %let vsize=5.5 in; 
      %let hsize=8.5 in; 
    %end;
    %else %if &g_textfilesfx=PS %then %do;
      %let g_fontsize=PS;
      %let device=PS600C/*PSLEPSFC*/;
      %let font=HWPSL009;
      %let horigin=0.88 in;
      %let vorigin=0.75 in; 
      %let vsize=6.75 in; 
      %let hsize=9.25 in; 
      options orientation=landscape;
    %end;  
  %end;  
  %let outfile = &g_outfile..&g_textfilesfx;
  
  /* Do not issue tu_abort here. Allow validation to complete first */

  /* PARAMETER VALIDATION */
  %tu_valgparms(macroname = &macroname);
  
  /* (Secondary) PARAMETER VALIDATION */
  %if &g_analy_disp ne A %then %do;
    %put RTE%str(RROR): &sysmacroname: Refreshing of titles/footnotes is not permitted;
    %let g_abort = 1;
  %end;

  %if &layout eq 1UP %then %let gptsize=%sysevalf((&gptsize*11)/(&topy-&boty));
  %else %let gptsize=%sysevalf((&gptsize*2)/((&topy-&boty)**0.5));
  
  %if &style eq SPAGHETTI and %length(&zvar) eq 0 %then 
    %put RTW%str(ARNING): &sysmacroname: It is common to code a value for ZVAR with STYLE=SPAGHETTI, yet no value was specified for ZVAR;
  %else %if &style ne SPAGHETTI and %length(&zvar) ne 0 and &legendyn eq N %then  /* [WJB.3.01] */
    %put %str(RTW)ARNING: &macroname: You have provided a ZVAR variable and STYLE=&style., yet LEGENDYN is set to N.;
  %if &ylogminbasis eq LLQ and &llqline eq N %then
    %put %str(RTW)ARNING: &macroname: LLQLINE is N (no LLQ line) but YLOGMINBASIS is LLQ (the log axis will be ranged to include the LLQ line);
     
  %if &g_abort eq 1 %then %do;
    %put %str(RTE)RROR: &macroname: Macro has failed parameter validation check for reasons stated with %str(RTE)RRORs above;
    %tu_abort(option=force);
  %end;
    
  /* NORMAL PROCESSING */
  
  /* Remove titles and footnotes */
  title;
  footnote;
  
  /* Set goptions ([WJB.3.01] replaces tu_pagesetup) */
  goptions reset=goptions 
           ftitle=&font 
           ftext=&font 
           htitle=&ptsize.pt
           htext=&ptsize.pt
           device=&device
           vsize=&vsize 
           hsize=&hsize 
           horigin=&horigin 
           vorigin=&vorigin
           rotate=&rotate
           xmax=8.5 in 
           ymax=11 in  
           cback=white
           ctext=black
           gsfmode=replace 
           gsfname=output;
  %if &g_textfilesfx=TIF %then %do;
     goptions xpixels=1000 ypixels=800;  
  %end;
  filename output "&outfile";
  %let g_ls = 108;
  %let g_ps = 43;

  /* 
  / PLAN:
  /  1) Parse parameters
  /     1.1) Get xvar and yvar, acquire labels 
  /     1.2) Evaluate BYVARS/ZVARS/REPEATYN -> actualZvar/actualBYvar
  /     1.3) Apply user-specified formats to BYVARS and Zvars
  /     1.4) Create actualZvar as required
  /     1.5) Generate labels
  /  2) Sort data, handle BYVARS, handle LLQ-related values, add dummy rows
  /     2.1) Sort data and handle BYVARS
  /     2.2) Get LLQ value(s)
  /     2.3) Create annotation for LLQ line(s)
  /     2.4) If BYVARS & ZVARS, add dummy rows for missing BYVAR/ZVAR combinations
  /  3) Manipute input data
  /     3.1) Perform summary stats
  /     3.2) Handle POSTSUBSET
  /  4) Generate GPLOT statements
  /     4.1) SYMBOL statements
  /     4.2) AXIS statements
  /       4.2.1) X AXIS statement
  /       4.2.2) Y AXIS LINEAR statement
  /       4.2.3) X AXIS LOG statement
  /  5) Handle records out of axis range
  /     5.1) Handle rows where values or bars will be outside the plot area 
  /     5.2) Recreate dataset to create record of plotted values
  /  6) Transpose data if summary stats (to put yvar, min and max in same column)
  /  7) Produce graphics
  /     7.1) Create linear graph into catalogue WORK.LIN.
  /     7.2) Create log graph into catalogue WORK.LOG.
  /     7.3) Create head/foot slides into catlg WORK.HF
  /     7.4) Create BY slides into catlg WORK.BY
  /     7.5) Create legend slide as work.gseg.legend.gseg
  /     7.6) Call tu_templates macro to generate graphic
  /  8) Clean up
  /----------------------------------------------------- */
  
  /* 1) PARSE PARAMETERS                                 */
  /* 1.1) Get xvar and yvar, acquire labels              */

  /* Split out xvar to xvar_var and xvar_units       */
  %local xvar_var xvar_unit xvar_wrds;
  %let xvar_wrds = %tu_words(&xvar, delim=%str( ));
  %let xvar_var = %scan(&xvar,1);

  %if &xvar_wrds = 2 %then %let xvar_unit = %scan(&xvar,2);
  %else %let xvar_unit = ;

  /* Split out yvar to yvar_var and yvar_units */
  %local yvar_var yvar_unit yvar_wrds;
  %let yvar_wrds = %tu_words(&yvar, delim=%str( ));
  %let yvar_var = %scan(&yvar,1);

  %if &yvar_wrds = 2 %then %let yvar_unit = %scan(&yvar,2);
  %else %let yvar_unit = ;

  /* Get data for selected population, and drop records where y or x var is null */ 
  %tu_getdata(dsetin=&currentDataset
             ,dsetout1=&prefix._getdata);
  data &prefix._getdata;
    set &prefix._getdata;
    where &xvar_var ne . and &yvar_var ne .;
  run;
  %let currentDataset = &prefix._getdata;
  %if %tu_nobs(&currentDataset) le 0 %then %do; /* [JMcG.5.01] If no data, %tu_gnoreport and exit */
    %tu_gnoreport(outfile=&outfile);
    %goto exit;
  %end;

  /* Apply standard reporting labels */ 
  %tu_labelvars(dsetin=&currentDataset
               ,dsetout=&prefix._labelvars
               ,style=&varlabelstyle);
  %let currentDataset = &prefix._labelvars;

  /* 1.2) Evaluate BYVARS/ZVARS/REPEATYN -> actualZvar/actualBYvar */
  
  /* Remove "=", swap around the code/decode pairs so code first) */
  %local actualBYvars wordptr word;
  %let actualBYvars=;
  %let wordptr=1;
  %let word = %scan(&byvars,&wordptr);
  %do %until (%length(&word) eq 0);
    %if %index(&word,=) %then 
      %let actualBYvars = &actualBYvars %scan(&word,2,=) %scan(&word,1,=);
    %else 
      %let actualBYvars = &actualBYvars &word;
    %if &g_debug ge 1 %then
      %put RTD%str(EBUG): &sysmacroname: WORDPTR=&wordptr, WORD=&word, actualBYvars=&actualBYvars;
    %let wordptr=%eval(&wordptr+1);
    %let word = %scan(&byvars,&wordptr);
  %end;

  %if %length(&actualBYvars) ne 0 %then %do;
    %let actBYvarcode=%sysfunc(upcase(%scan(&actualBYvars,1)));
    %let actBYvarname=%sysfunc(upcase(%scan(&actualBYvars,-1)));
  %end;
  
  /* Split ZVAR into zvarDecode and zvarCode (if supplied).
  /  Later, will create a zvarLegendOrder (if zvarCode supplied). */
  %local zvarDecode zvarCode;
  %let zvarDecode = %scan(%sysfunc(compress(&zvar)),1,=);
  %let zvarCode   = %scan(%sysfunc(compress(&zvar)),2,=);

  /* [JMcG.1.02] If we do not have a code then set it to the decode value */
  %if %length(&zvarCode) = 0 %then %let zvarCode = &zvarDecode;

  /* 1.3) Apply formats provided by user to the actualBYvars and actualZvar variables */  
  /* (Have to use PUT as formats are not maintained in calls to tu_cr8gbys and tu_cr8legend) */  
  %local byzvariable byzformat formatswds newformats;
  %let formatswds=%tu_words(&formats);
  data &prefix._formattedDataset;
    set &currentDataset;

    %do i=1 %to %eval(&formatswds-1);
    %if %sysfunc(index(%scan(&formats,&i," "),.)) eq 0 %then
      %do j=&i+1 %to &formatswds;
        %if %sysfunc(index(%scan(&formats,&j," "),.)) %then %do;
          %let byzvariable=%scan(&formats,&i," ");
          %let byzformat=%scan(&formats,&j," ");
          %if %length(%tu_chkvarsexist(&currentDataset,&byzvariable)) eq 0
           and %sysfunc(index(%upcase(&actualBYvars) %upcase(&zvar) %upcase(&zrepeatvar),%upcase(&byzvariable))) 
           %then %do;
            &byzvariable = put(&byzvariable, &byzformat);
          %end;
          %else %if %sysfunc(index(%upcase(&xvar) %upcase(&yvar),%upcase(&byzvariable))) %then %do;
            %let newformats=&newformats &byzvariable &byzformat;
          %end;
          %let j=&formatswds;
        %end;
      %end;
    %end;

  run;
  %let formats=&newformats;
  %if %length(&formats) eq 0 %then 
    %put RTN%STR(OTE): &sysmacroname: Default format of BEST6. applied to X and Y axis.;
  %let currentDataset=&prefix._formattedDataset;

  /* 1.4) Create actualZvar as required (if ZREPEATVAR exists) */  
  %local actualZvarCode actualZvar zvarLabel ZREPEATVARLabel
         REPEATVARVarCode REPEATVARVar REPEATVARStmtCode REPEATVARStmt;
  
  %if %length(&zrepeatvar) eq 0 %then  /* [WJB.3.01] changed from "%scan(&zrepeatvar,1) ne ZVAR" */
  %do;  /* ZREPEATVAR=no */
    %let actualZvar = &zvarDecode;
    %if %length(&zvarCode) gt 0 %then
      %let actualZvarCode = &zvarCode;
    %else
      %let actualZvarCode = &zvar;
  %end; /* ZREPEATVAR=no */
  %else
  %do;  /* Need to create actualZvar using ZREPEATVAR */
    %let REPEATVARVar     = %scan(%sysfunc(compress(&zrepeatvar)),1,=); /* [WJB.3.01] changed from %scan(%scan(&zrepeatvar,2),1,=) */
    %let REPEATVARVarCode = %scan(%sysfunc(compress(&zrepeatvar)),2,=); /* [WJB.3.01] changed from %scan(%scan(&zrepeatvar,2),2,=) */
    %if %length(&REPEATVARVarCode) eq 0 %then
      %let REPEATVARVarCode = &REPEATVARVar;
    %let actualZvar = __zvarREPEATVAR;
    %let actualZvarCode = __zvarREPEATVARCode;
    data _null_;
      set &currentDataset;
      length stmt $256;
      select (vtype(&zvarDecode)!!vtype(&REPEATVARVar));
        when ('CC') stmt = "left(trim(&zvarDecode)) !! '--' !! left(trim(&REPEATVARVar))";
        when ('CN') stmt = "left(trim(&zvarDecode)) !! '--' !! compress(putn(&REPEATVARVar,'BEST.'))";
        when ('NC') stmt = "compress(putn(&zvarDecode,'BEST.')) !! '--' !! left(trim(&REPEATVARVar))";
        when ('NN') stmt = "compress(putn(&zvarDecode,'BEST.')) !! '--' !! compress(putn(&REPEATVARVar,'BEST.'))";
      end; /* select vtype */
      call symput('REPEATVARSTMT',stmt);
      select (vtype(&zvarCode)!!vtype(&REPEATVARVarCode));
        when ('CC') stmt = "left(trim(&zvarCode)) !! '--' !! left(trim(&REPEATVARVarCode))";
        when ('CN') stmt = "left(trim(&zvarCode)) !! '--' !! compress(putn(&REPEATVARVarCode,'BEST.'))";
        when ('NC') stmt = "compress(putn(&zvarCode,'BEST.')) !! '--' !! left(trim(&REPEATVARVarCode))";
        /* [WJB.3.01] If ZVAR and REPEATVAR both have numeric codes, produce a numeric code (so legend is in right order) */
        when ('NN') stmt = "input(compress(1000+input(&zvarCode,??BEST.)) !! compress(1000+input(&REPEATVARVarCode,??BEST.)),??BEST.)";
      end; /* select vtype */
      call symput('REPEATVARSTMTCODE',stmt);
      STOP;
    run;
    %if &g_debug ge 1 %then
      %put RTD%str(EBUG): &sysmacroname: REPEATVARSTMT=&REPEATVARStmt REPEATVARSTMTCODE=&REPEATVARStmtCode;
    data &prefix._ZREPEATVAR;
      set &currentDataset;
      length &actualZvar $33;
      retain issuedWrnng 0;
      if _n_ eq 1 then do;
        call symput('ZVARLABEL',vlabel(&zvarDecode));
        call symput('ZREPEATVARLABEL',vlabel(&REPEATVARVar));
      end;
      &actualZvar = &REPEATVARStmt;
      &actualZvarCode = &REPEATVARStmtCode;
      if length(&actualZvar) gt 32 and not issuedWrnng then do;
        put "RTW" "ARNING: &sysmacroname: One or more ZVAR/ZREPEATVAR values were longer than the "
            "SAS maximum of 32 characters. They will be truncated by PROC GPLOT. " &actualZvar=;
        issuedWrnng = 1;
      end;
    run;
    %if &g_debug ge 1 %then
      %put RTD%str(EBUG): &sysmacroname: ZVARLABEL="&zvarLabel" ZREPEATVARLABEL="&ZREPEATVARLabel";
      
    proc datasets lib=work nolist;
      modify &prefix._ZREPEATVAR;
        label &actualZvar = "&zvarLabel -- &ZREPEATVARLabel";
    quit;
    
    %let currentDataset = &prefix._ZREPEATVAR;
  %end; /* Need to create actualZvar using ZREPEATVAR */

 /* Create a zvarLegendOrder (if zvarCode was supplied) */
  %local zvarLegendOrder zvarCount;
  %if %length(&actualZvarCode) gt 0 %then
  %do;  /* Create a zvarLegendOrder */

    /* [JmcG.1.03] Made the select conditional to remove the sas w@rning message if
    /              actualzvar and actualzvarcode are same var */
    proc sql noprint;
      create table &prefix._distinctzvars as
        select distinct 
        %if &actualZvar = &actualZvarcode %then &actualZvar ;
        %else &actualZvar , &actualZvarCode ;
          from &currentDataset
          order &actualZvarCode
          ;
    quit;  /* [JMcG.1.03] */
    %if &g_debug ge 1 %then 
      %put RTD%str(EBUG): &sysmacroname: &actualzvar is of type %tu_chkvartype(&prefix._distinctzvars, &actualzvar);
 
    /* Get count of zvars for use in symbol statements */
    %let zvarCount = %tu_nobs(&prefix._distinctzvars);

    data _null_;
      set &prefix._distinctzvars end=finish;
      retain string;
      length string $4096;

      /*  [JMcG.1.04] If the variable is character then build a character sting */
      %if %tu_chkvartype(&prefix._distinctzvars, &actualzvar) = C %then %do;
        string = trim(string) !! ' ' !! quote(trim(&actualZvar));
      %end;
      %else %if %tu_chkvartype(&prefix._distinctzvars, &actualzvar) = N %then %do;
        string = trim(string) !! trim(put(&actualZvar,best.));
      %end;

      if finish then call symput("ZVARLEGENDORDER",left(trim(string)));
    run;
    %if &g_debug ge 1 %then %put RTD%str(EBUG): &sysmacroname: ZVARLEGENDORDER=&zvarLegendOrder;
  %end; /* Create a zvarLegendOrder */

  /* 1.5) Generate labels  */
  %local nobs;

  %if %length(&xlabel) eq 0 %then %do;  /* Create xlabel */
    data _null_;
      set &currentDataset;
      label = vlabel(&xvar_var);
      call symput('XLABEL',trim(label));
      STOP;
    run;
    %let xlabel=%nrbquote(&xlabel);

    %if %length(&xvar_unit) ne 0 %then
    %do;  /* Add units to label, if provided */
      proc sort data=&currentDataset
                out=&prefix._chkxunits
                nodupkey;
        by &xvar_unit;
      run;
      %let nobs = %tu_nobs(&prefix._chkxunits);
      %if &nobs eq 1 %then %do;   /* Append unit to label */
        %local xunits;
        data _null_;
          set &prefix._chkxunits;
          call symput('XUNITS',&xvar_unit);
        run;
        %if %length(&xunits) ne 0 %then %let xlabel = %trim(&xlabel) (%trim(&xunits));
      %end; /* Append unit to label */
    %end; /* Add units to label, if provided */
  %end;                                 /* Create xlabel */

  %if %length(&ylabel) eq 0 %then %do;  /* Create ylabel */
    data _null_;
      set &currentDataset;
      label = vlabel(&yvar_var);
      call symput('YLABEL',trim(label));
      STOP;
    run;
    %let ylabel=%nrbquote(&ylabel);

    /* Add units to label if provided */
    %if %length(&yvar_unit) ne 0 %then %do;  /* Add units to label */
      proc sort data=&currentDataset
                out=&prefix._chkyunits
                nodupkey;
        by &yvar_unit;
      run;
      %let nobs = %tu_nobs(&prefix._chkyunits);

      %if &nobs eq 1 %then %do; /* Append unit to label */
        %local yunits;
        data _null_;
          set &prefix._chkyunits;
          call symput('YUNITS',&yvar_unit);
        run;
        %if &g_debug ge 1 %then %put RTD%str(EBUG): &sysmacroname: YUNITS="&yunits";
        %if %length(&yunits) ne 0 %then %let ylabel = %trim(&ylabel) (%trim(&yunits));
      %end;                     /* Append unit to label */
    %end;                                    /* Add units to label */
  %end;                                 /* Create ylabel */
  
  %local yloglabel llqreq pcllqn_var;
  %if &ylogstyle eq POWER %then %let yloglabel = "&ylabel" j=c "(as exponent of &ylogbase)";
  %else %let yloglabel = "&ylabel";

  /* Assess if LLQ (pcllqn) is required, if so set LLQREQ to Y */    
  %if &llqline eq Y or &ymin eq LLQ 
   or ((&ymin le 0 or %length(&ymin) eq 0) and %sysfunc(indexw(&figtype,LOG)) and &ylogminbasis eq LLQ) %then 
   %do; /* include all scenarios where LLQ may be used [WJB.3.01] */
    %let llqreq=Y;
    %let pcllqn_var = pcllqn;
  %end;      
  %else %do;
    %let llqreq=N;
  %end;      
  
  /* 2) Sort data, handle BYVARS, handle LLQ-related values, add dummy rows  */
  /* 2.1) Sort data and handle BYVARS
  /  NOTE: PCLLQN is required for a number of parameter combinations later, so keep it just in case. */
  proc sort data=&currentDataset
            out=&prefix._sortedsubset(keep=&xvar &yvar &actualZvarCode &actualZvar &actualBYvars &pcllqn_var);
    by &actualBYvars &actualZvarCode &xvar_var &yvar_var;  /* zvar reqd later for uniform symbols */ /* [WJB.3.01] changed actualZvar to actualZvarCode */
  run;
  /* Add byVarIndex onto data */
  %if %length(&actualBYvars) gt 0 %then %do;
  /* Get distinct actualBYvar values into ds &prefix._templateByvars (or just PCLLQN if no byvars) */
    proc sql noprint;
      create table &prefix._templateByvars as
        select distinct %tu_sqlnlist(&actualBYvars)
        from &currentDataset 
        order by %tu_sqlnlist(&actualBYvars);
    quit;
    /* Add obs code, byVarIndex, to data, and record total no of BYVARS, byVarCount */
    data &prefix._templateByvars; 
      set &prefix._templateByvars; 
      retain byVarIndex 0;
      byVarIndex = byVarIndex + 1;
      call symput('byVarCount',byVarIndex);
    run;
    data &prefix._sortedsubset;
      merge &prefix._sortedsubset &prefix._templateByvars(keep=byVarIndex &actualBYvars);
      by &actualBYvars;
      proc sort; by &actualBYvars &actualZvarCode &actualZvar &xvar_var &yvar_var;
    run;
  %end;
  %else %do;
    data &prefix._sortedsubset(keep=byVarIndex &xvar &xvar_unit &yvar &yvar_unit &actualZvar &actualZvarCode &pcllqn_var);
      set &prefix._sortedsubset;
      byVarIndex = 1;
    run;
    data &prefix._templateByvars;
      byVarIndex = 1;
    run;
    %let byVarCount = 1;
  %end;
  %let currentDataset = &prefix._sortedSubset;
  
  /* 2.2) Get LLQ value(s) */
  %if &llqreq eq Y %then  
  %do;  /* Handle LLQ-related values */
    
    /* Get LLQ and minLLQ into mv's [macro variables] LLQ and minLLQ */
    %local llq minLLQ;
    proc sql noprint;
      select distinct &pcllqn_var into: llq separated by ' ' 
        from &currentdataset;
      select min(&pcllqn_var) into: minLLQ 
        from &currentdataset
        where &pcllqn_var ne .;
      create table &prefix._LLQByvars as
        select distinct %tu_sqlnlist(&actualBYvars &pcllqn_var)
        from &currentDataset 
        order by %tu_sqlnlist(&actualBYvars &pcllqn_var);
    quit;
    %if &g_debug ge 1 %then %put RTD%str(EBUG): &sysmacroname: LLQ=&llq..;
    %if &g_debug ge 1 %then %put RTD%str(EBUG): &sysmacroname: minLLQ=&minLLQ..;
  
    /* Get LLQ value per BYVAR into ds &prefix._llq_unq */
    proc sort data=&currentDataset (keep=byVarIndex &actualBYvars &actualZvar &pcllqn_var &yvar_unit)
              out=&prefix._llq_unq
              nodupkey;
      by &actualBYvars &pcllqn_var;
    run;

    /* Check that pcllqn is present and above zero [JMcG.4.01] */
    %if %length(&minllq) eq 0 %then %do;
      %put RTE%str(RROR): &sysmacroname: All values of PCLLQN are missing;
      %let g_abort=1;
    %end; 
    %else %if &minLLQ le 0 %then %do;
      %put RTE%STR(RROR): &sysmacroname: There are values of PCLLQN below zero (&minLLQ);
      %let g_abort=1;
    %end; 

    /* Check that there is only one LLQ value per BYVAR */
    %if %tu_nobs(&prefix._llq_unq) - %tu_nobs(&prefix._templateByvars) ne 0 %then %do;
      %if %length(&actualBYvars) ne 0 %then %do;
        %put RTE%STR(RROR): &sysmacroname: One or more BYVARS values have multiple values of LLQ.;
      %end;
      %else %do;
        %put RTE%STR(RROR): &sysmacroname: Multiple values of LLQ.;
      %end;
      %let g_abort=1;
    %end;
    %tu_abort;

    /* Add PCLLQN to ds &prefix._templateByvars */
    data &prefix._templateByvars;
      merge &prefix._templateByvars 
            &prefix._LLQByvars;
      %if %length(&actualBYvars) ne 0 %then by &actualBYvars;;
    run;

    /* 2.3) Create annotation for LLQ line(s)              */
    %if &llqline eq Y %then %do; 
      %local annostr;
      %if %length(&yvar_unit) ne 0 %then %let annostr=' LLQ='||compress(&pcllqn_var)||' '||compress(&yvar_unit)||' ';
      %else %let annostr=' LLQ='||compress(&pcllqn_var)||' ';
      %annomac;  /* Activate ANNOTATE macros */
      data &prefix._llqline_anno;
        %dclanno;  /* Set ANNOTATE variable lengths */
        set &prefix._llq_unq;
        %system(1,2,4);
        %line(0,&pcllqn_var,100,&pcllqn_var,black,21,1);
        %if &llqanno eq L %then %do;  /* Functionality to annotate LLQ line where user specifies LLQLINE=L or C or R [WJB.3.01] */
          %label(0,&pcllqn_var,&&annostr,black,0,0,&annosize,&font,3);
        %end;
        %else %if &llqanno eq C %then %do;
          %label(50,&pcllqn_var,&&annostr,black,0,0,&annosize,&font,2); 
        %end;
        %else %if &llqanno eq R %then %do;
          %label(100,&pcllqn_var,&&annostr,black,0,0,&annosize,&font,1);
        %end;
      run;
      %tu_abort;
    %end; /* end-if: &llqline eq Y */

  %end; /* Handle LLQ-related values */
  
  /* 2.4) If BYVARS & ZVARS, add dummy rows for missing BYVAR/ZVAR combinations */
  %if %length(&actualBYvars) gt 0 and %length(&actualZvar) gt 0 %then
  %do;  /* We have BYVARS+ZVAR - Add dummy data rows to ensure symbols are consistent */

    /* Get length and type of zvar into mv actualZVARtype, mv actualZVARlength */
    %local actualZvarLength actualZvarType;
    data _null_;
      set sashelp.vcolumn;
      where libname eq "WORK" and
            memname eq "%upcase(&prefix._sortedSubset)"
            and upcase(name) eq "%upcase(&actualZvar)";
      call symput('ACTUALZVARTYPE',type);
      select (type);
        when ('char') call symput('ACTUALZVARLENGTH','$'!!compress(putn(length,'BEST.')));
        when ('num')  call symput('ACTUALZVARLENGTH',compress(putn(length,'BEST.')));
      end;
    run;
    %if &g_debug ge 1 %then
      %put RTD%str(EBUG): &sysmacroname: ACTUALZVARLENGTH=&actualZvarLength ACTUALZVARTYPE=&actualzvartype;

    /* Get distinct actualZvar values into mv [macro variable] distinctZvarValues */
    %local lastbyvar distinctZvarValues;
    %let lastbyvar = %scan(&actualBYvars,-1);
    proc sql noprint;
      select distinct &actualZvar into: distinctZvarValues 
           separated by 
                   %if &actualZvarType eq char %then '" ,"';
                   %else ',';
        from &currentDataset;
    quit;
    %if &actualZvarType eq char %then %let distinctZvarValues = "&distinctZvarValues";
    %if &g_debug ge 1 %then %put RTD%str(EBUG): &sysmacroname: distinctZvarValues=&distinctZvarValues;

    /* Make the master template ds &prefix._templateMaster */
    data &prefix._templateMaster;
      set &prefix._templateByvars;
      by &actualBYvars;
      length &actualZvar &actualZvarLength;
      if first.&lastByvar then do;
        do &actualZvar = &distinctZvarValues;
          output;
        end;
      end;
      proc sort; by &actualBYvars &actualZvar;
    run;
    
    proc sort data=&currentDataset; 
      by &actualBYvars &actualZvar; 
    run;
   
    /* Merge the data back onto the master template -> ds &prefix._regularDsetin */
    data &prefix._regularDsetin;
      merge &currentDataset
            &prefix._templateMaster;
      by &actualBYvars &actualZvar;
    run;
    %let currentDataset = &prefix._regularDsetin;

  %end; /* We have BYVARS+ZVAR - Add dummy data rows to ensure symbols are consistent */

  proc sort data=&currentDataset; 
    by &actualBYvars &actualZvarCode &actualZvar &xvar_var &yvar_var;
  run;

  /* 3) Manipute input data                              */
  /* 3.1) Perform summary stats                          */
  %if &disptyp eq SUMMARY %then %do;  /* Calculate statistics (incl SD/range), if required */

    proc summary data=&currentDataset nway missing;   /* Add MISSING keyword to retain dummy obs [WJB.3.01] */
      class &actualBYvars &actualZvarCode &actualZvar &xvar_var;
      var &yvar_var;
      id &pcllqn_var &xvar_unit &yvar_unit byVarIndex;  /* WJB added byVarIndex */
      output out=&prefix._regularDsetin (drop=_type_ _freq_)
             &style=
             %if &bars eq SD or &bars eq SDB %then std=std;
             %else %if &bars eq RANGE %then min=min max=max;
       ;
    run;
    %let currentDataset = &prefix._regularDsetin;

    /* Calculate +/- SD. We want to use I=HILOCJ on the SYMBOL statement for the GPLOT.  That requires
    /  three Y values for each X. We only want mean+sd, unless the user specified both. */  
    %if &bars eq SD or &bars eq SDB %then %do;
      data &prefix._regularDsetin0;
        set &currentDataset;
        drop std;
        if "&bars" eq "SDB" and std ne . then min = &yvar_var - std;               /* [WJB.3.01] */
        else min = &yvar_var; 
        if std ne . then max = &yvar_var + std;
        else max = &yvar_var;
      run;
      %let currentDataset = &prefix._regularDsetin0;
    %end;         /* [WJB.3.01] Resetting bars off axis moved to just before proc gplot */
  %end; /* Perform summary stats */

  /* 3.2) Handle POSTSUBSET                              */
  /* [WJB.3.01] (Replaces INCLLQ). Must remove the rows, not set them to null, otherwise 
  /  if all values are below LLQ, values are plotted against the wrong by-var. 
  /------------------------------------------------------------------------------------- */
  %if %length(&postsubset) ne 0 %then %do;  
    %local delSubset;
    data &prefix._postSubset;
      set &currentDataset;
      where &postsubset;
    run;
    %let delSubset = %eval(%tu_nobs(&currentDataset) - %tu_nobs(&prefix._postSubset));
    %let currentDataset=&prefix._postSubset;
    %if %sysevalf(&delSubset) ne 0 %then 
      %put RTD%str(EBUG): &sysmacroname: &delSubset observations deleted per POSTSUBSET;
  %end; /* Handle POSTSUBSET */
  
  /* Check for zero observations - if so, report no output, tidy up and abort */
  %if %tu_nobs(&currentDataset) le 0 %then
  %do;
    %tu_gnoreport(outfile=&outfile);
    %tu_tidyup(rmdset=&prefix:, glbmac=NONE);
    %goto exit;
  %end;

  /* 4) Generate SYMBOL/AXIS statements                  */
  /* 4.1) GENERATE SYMBOL STATEMENTS                     */
  
  /* Warn the user if number of symbols in SYMBOLVALUE < number of ZVAR/ZREPEATVAR combinations */
  
  %if %length(&zvar) gt 0 and &legendyn eq Y %then %do;
    %local symbolCount;
    %let symbolCount = %tu_words(&symbolValue);
    %if %sysevalf(&symbolCount - &zvarCount lt 0) %then 
      %put RTW%str(ARNING): &sysmacroname: There are &zvarCount unique combinations of ZVAR/ZREPEATVAR but only &symbolCount symbols have been specified.;
  %end;  
  %if &zvarCount le 0 %then %let zvarCount = 1;

  /* Symbol: COLOR */
  %do i = 1 %to &zvarCount;
    %local symColor&i;
  %end;
  %tu_cr8macarray(string      = &symbolColor
                 ,prefix      = symColor
                 ,numElements = &zvarCount);
  %if &g_debug ge 1 %then %do i = 1 %to &zvarCount;
      %put RTD%str(EBUG): &sysmacroname: SYMCOLOR&i=&&symColor&i;
  %end;
  /* Symbol: VALUE */
  %do i = 1 %to &zvarCount;
    %local symValue&i;
  %end;
  %tu_cr8macarray(string      = &symbolValue
                 ,prefix      = symValue
                 ,numElements = &zvarCount);
  %if &g_debug ge 1 %then %do i = 1 %to &zvarCount;
      %put RTD%str(EBUG): &sysmacroname: SYMVALUE&i=&&symValue&i;
  %end;
  /* Symbol: LINE */
  %do i = 1 %to &zvarCount;
    %local symLine&i;
  %end;
  %tu_cr8macarray(string      = &symbolLine
                 ,prefix      = symLine
                 ,numElements = &zvarCount);
  %if &g_debug ge 1 %then %do i = 1 %to &zvarCount;
      %put RTD%str(EBUG): &sysmacroname: SYMLINE&i=&&symLine&i;
  %end;
  /* Symbol: INTERPOL */
  %if &disptyp eq SUMMARY 
      and &addbars = Y /*[WJB.3.01]*/ 
      and %upcase(&symbolInterpol) ne HILOCJ %then 
   %put RTW%str(ARNING): &sysmacroname: For STYLE=&style with BARS=&bars, the use of SYMBOLINTERPOL=HILOCJ is highly recommended. Current setting is &symbolInterpol;
  %do i = 1 %to &zvarCount;
    %local symInterpol&i;
  %end;
  %tu_cr8macarray(string      = &symbolInterpol
                 ,prefix      = symInterpol
                 ,numElements = &zvarCount);
  %if &g_debug ge 1 %then %do i = 1 %to &zvarCount;
      %put RTD%str(EBUG): &sysmacroname: SYMINTERPOL&i=&&symInterpol&i;
  %end;
  /* Symbol: OTHER */
  %do i = 1 %to &zvarCount;
    %local symOther&i;
  %end;
  %if %length(&symbolOther) ne 0 %then %do;
    %tu_cr8macarray(string      = &symbolOther
                   ,prefix      = symOther
                   ,numElements = &zvarCount
                   ,delim       = &symbolOtherDelim);
  %end;
  %if &g_debug ge 1 %then %do i = 1 %to &zvarCount;
      %put RTD%str(EBUG): &sysmacroname: SYMOTHER&i=&&symOther&i;
  %end;
  /* GENERATE SYMBOL STATEMENTS */
  %do i = 1 %to &zvarCount;
    SYMBOL&i 
      %if %length(&&symColor&i)    gt 0 %then COLOR=&&symColor&i;
      %if %length(&&symValue&i)    gt 0 %then VALUE=&&symValue&i;
      %if %length(&&symLine&i)     gt 0 %then LINE=&&symLine&i;
      %if %length(&&symInterpol&i) gt 0 %then INTERPOL=&&symInterpol&i;
      %if %length(&&symOther&i)    gt 0 %then &&symOther&i;
      ;
  %end;
  
  /* GET MINIMUM AND MAXIMUM DATA VALUES */ 
  %local xminValue0 xmaxValue0 xminValue xmaxValue minyvar maxyvar;
  %local ylogOrder ylinearOrder yminValue0 yminLogValue0 ymaxValue0; 
  %local yminLinValue ymaxLinValue yminLogValue ymaxLogValue;
  %local axisbypage;
  %let axisbypage=Y;

  %if &xrange eq ALL and &yrange eq ALL
   or %length(actualBYvars) eq 0
   or (%length(&xmin) ne 0 and %length(&xmax) ne 0 and %length(&ymin) ne 0 and %length(&ymax) ne 0)
   %then 
    %let axisbypage=N; /* Do not need to calculate min and max axis values by byvar */

  %if &addbars eq Y %then %do; /* if we have bars then min will hold the lowest value, and max will hold the highest */
    %let minyvar = min;
    %let maxyvar = max;
  %end;
  %else %do;  /* otherwise yvar will hold both the lowest and highest values */
    %let minyvar = &yvar_var;
    %let maxyvar = &yvar_var;
  %end;
  
  /* Get miminum and maximum values for axes, where they have not been supplied */ 
  /* Get y log minimum (lowest non-zero positive value of &yvar_var) anyway */ 
  proc summary data=&currentDataset;
    by byVarIndex;
    var &xvar_var;
    output out=&prefix._byvarxMinMax(drop=_TYPE_ _FREQ_) min=xminValue0 max=xmaxValue0;
  run;
  proc summary data=&currentDataset;
    by byVarIndex;
    var &maxyvar;
    output out=&prefix._byvaryMax(drop=_TYPE_ _FREQ_) max=ymaxValue0;
  run;
  proc summary data=&currentDataset /* (allow negatives) [WJB.3.01] */ ;
    by byVarIndex;
    var &minyvar;
    output out=&prefix._byvaryMin(drop=_TYPE_ _FREQ_) min=yminValue0;
  run;
  proc summary data=&currentDataset(where=(&minyvar gt 0));
    by byVarIndex;
    var &minyvar;
    output out=&prefix._byvaryLogMin(drop=_TYPE_ _FREQ_) min=yminLogValue0;
  run;
  
  /* If bars are being produced and all min bars are le 0, try yvar for log minimum */
  /* If log minimum are all le 0 as well, no log values can be plotted - set a default */
  %if %tu_nobs(&prefix._byvaryLogMin) eq 0 and &addbars eq Y %then %do;
    proc summary data=&currentDataset(where=(&yvar_var gt 0));
      by byVarIndex;
      var &yvar_var;
      output out=&prefix._byvaryLogMin(drop=_TYPE_ _FREQ_) min=yminLogValue0;
    run;
  %end;  
  %if %tu_nobs(&prefix._byvaryLogMin) eq 0 and %sysfunc(indexw(&figtype,LOG)) %then %do;
    %put RTW%str(ARNING): &sysmacroname: Semi-log scale is being produced but all values on one or more log scale(s) are less than or equal to zero.;
    %put RTW%str(ARNING): &sysmacroname: Default axis ranges will be set.;
  %end;
  
  /* Combine the BYVAR summary datasets together
  /   Include LLQ (line) in the calculation for the minimum, but only for log axis if ylogminbasis=LLQ. */
  data &prefix._byvarMinMax1;
    merge &prefix._byvaryLogMin
          &prefix._byvarxMinMax
          &prefix._byvaryMin
          &prefix._byvaryMax
          &prefix._templateBYVars;
    by byVarIndex;
    
    /* If LLQLINE=Y, extend yminValue0/ymaxValue0 to include LLQ */
    %if &llqline=Y %then %do;
      if &pcllqn_var eq . then &pcllqn_var=input(&minLLQ,??best.); /* Use minLLQ if no byvars */
      if yminValue0-&pcllqn_var gt 0 then yminValue0=&pcllqn_var; 
      if ymaxValue0-&pcllqn_var lt 0 then ymaxValue0=&pcllqn_var;
    %end;
    %if (%sysevalf(&ymin le 0) or %length(&ymin) eq 0) 
      and %sysfunc(indexw(&figtype,LOG)) 
      and &ylogminbasis eq LLQ %then %do;
        if yminLogValue0-&pcllqn_var gt 0 and &pcllqn_var gt 0 then yminLogValue0=&pcllqn_var;   /* only extend yminLogValue0 to include LLQ if ylogminbasis=LLQ */
    %end;
  run;
  
  /* Retrieve absolute xmax/ymax value */
  proc sql noprint;
    select max(xMaxValue0) 
    into :xmaxValue_all
    from &prefix._byvarMinMax1; 
    select max(yMaxValue0) 
    into :ymaxValue_all
    from &prefix._byvarMinMax1; 
  quit;
  
  /* Modify the data limits 
  /   Replace with user specified min/max where given. Only use user-specified ymin in log 
  /   scale if > 0, otherwise use ylogMinValue0 (lowest non-zero positive value of &yvar_var) */
  data &prefix._byvarMinMax;
    set &prefix._byvarMinMax1; 
    
    /* If only one value of XVAR, set xminValue0/xmaxValue0 equally either side */
    if xminValue0 eq xmaxValue0 then do;
      %if %length(&xmax) eq 0 or %length(&xmin) eq 0 %then %do;
        %if %length(&xmin) ne 0 %then %do;
          if xmaxValue0-&xmin ne 0 then do;
            xmaxValue0=(2*xmaxValue0)-&xmin;
          end;
          else
        %end;
        %else %if %length(&xmax) ne 0 %then %do;
          if xminValue-&xmax ne 0 then do;
            xminValue0=(2*xminValue0)-&xmax;
          end;
          else
        %end;
        do;
          if xminValue0 eq 0 then do;
            xminValue0=0;
            xmaxValue0=1;
          end;
          else do;
            xminValue0=xminValue0 - abs(xminValue0);
            xmaxValue0=xmaxValue0 + abs(xmaxValue0);
          end;
        end;
      %end;      
      
      /* Handle scenario where value would cause xmax to be unnecessarily extended on other plots */
      /* (If we have set this xmaxvalue to ge 1.3 * absolute max, reduce it until it is not) */
      if "&xrange"="ALL" and xmaxValue0/&xmaxValue_all ge 1.3 then do until (xmaxValue0/&xmaxValue_all lt 1.3);
        xmaxValue0 = xmaxValue0*0.8;
      end;
    end;

    /* If only one value of XVAR, set xminValue0/xmaxValue0 equally either side */
    if yminValue0 eq ymaxValue0 then do;
      %if %length(&ymax) eq 0 or %length(&ymin) eq 0 %then %do;
        %if %length(&ymin) ne 0 %then %do;
          if ymaxValue0-&ymin ne 0 then do;
            ymaxValue0=(2*ymaxValue0)-&ymin;
          end;
          else
        %end;
        %else %if %length(&ymax) ne 0 %then %do;
          if yminValue-&ymax ne 0 then do;
            yminValue0=(2*yminValue0)-&ymax;
          end;
          else
        %end;
        do;
          if yminValue0 eq 0 then do;
            yminValue0=0;
            ymaxValue0=1;
          end;
          else do;
            yminValue0=yminValue0 - abs(yminValue0);
            ymaxValue0=ymaxValue0 + abs(ymaxValue0);
          end;
        end;
      %end;      
      
      /* Handle scenario where value would cause ymax to be unnecessarily extended on other plots */
      /* (If we have set this ymaxvalue to ge 1.3 * absolute max, reduce it until it is not) */
      if "&yrange"="ALL" and ymaxValue0/&ymaxValue_all ge 1.3 then do until (ymaxValue0/&ymaxValue_all lt 1.3);
        ymaxValue0 = ymaxValue0*0.8;
      end;
    end;

    /* If XMIN,XMAX,YMIN, or YMAX specified, replace min/max values with those */
    %if %length(&xmin) ne 0 %then xminValue0=input(&xmin,??best.);;
    %if %length(&xmax) ne 0 %then xmaxValue0=input(&xmax,??best.);;
    %if %length(&ymax) ne 0 %then ymaxValue0=input(&ymax,??best.);;
    %if %length(&ymin) ne 0 %then %do;
      %if &ymin eq LLQ %then yminValue0=&pcllqn_var;
      %else yminValue0=input(&ymin,??best.);;
      if yminValue0 gt 0 then yminLogValue0 = yminValue0; /* only replace yminLogValue0 if ymin > 0 */
    %end;
    if yminLogValue0=. or yminLogValue0 ge ymaxValue0 then do;
      if ymaxValue0 gt 0 then yminLogValue0=ymaxValue0/10;
      else yminLogValue0=1;
    end;

  run;
  
  /* Retrieve absolute linear and absolute log min/max values including user-specified */
  proc sql noprint;
    select min(xMinValue0), max(xMaxValue0), min(yMinValue0), max(yMaxValue0), min(yminLogValue0)
      into :xminValue_all,  :xmaxValue_all,  :yminValue_all,  :ymaxValue_all,  :yminLogValue_all
      from &prefix._byvarMinMax;
  quit;
  
  /* Kill previously created gplot catalogues */
  %if %sysfunc(exist(&prefix._lin,catalog)) %then %do;
    proc catalog c=&prefix._lin kill;
    quit;
  %end;
  %if %sysfunc(exist(&prefix._log,catalog)) %then %do;
    proc catalog c=&prefix._log kill;
    quit;
  %end;
  
  /* CREATE FINAL DATASET */
  proc sort data=&currentDataset
             out=&prefix._&outdset;
    by &actualBYvars &actualZvarCode &actualZvar &xvar_var &yvar_var &yvar_unit;
  run;
  %let currentDataset = &prefix._&outdset;
  data dddata.&outdset(drop=byVarIndex);
    set &prefix._&outdset;
  run;

  /* If we are setting all axes the same, treat this as if we have only one value of BYVAR */
  %if &axisbypage eq N %then %let byVarCount = 1;
  
  %local dropBYs dropBYflag tickCount;
  %local LinDelCount LogDelCount byLinBarDelCount byLogBarDelCount LinBarDelCount LogBarDelCount;

  %let LinDelCount = 0;
  %let LogDelCount = 0;
  %let byLinBarDelCount = 0;
  %let byLogBarDelCount = 0;    
  %let LinBarDelCount = 0;
  %let LogBarDelCount = 0;    

  /* Perform axis ranging and GPLOT once per byvar. (If &axisbypage eq N, will perform 
  /  once and let GPLOT handle byvars) */  
  %do currentBYvar = 1 %to &byVarCount;

    /* Get subsetted dataset */
    data &prefix._subset;
      set &prefix._&outdset;
      %if &axisbypage eq Y %then %do;
        where byvarIndex=&currentBYvar;
      %end;
    run;
    %let currentDataset=&prefix._subset;
    
    %if %tu_nobs(&currentDataset) eq 0 %then %goto endloop;
    
    /* 4.2) AXIS statements                    */
    /* Retrieve minimum and maximum values for current byvar (or all if no byvar) */
    proc sql noprint;
      select
        %if &xrange eq ALL %then 
              &xMinValue_all, &xMaxValue_all, ; 
        %else xMinValue0,     xMaxValue0, ; 
        %if &yrange eq ALL %then 
              &yMinValue_all, &yMaxValue_all ;
        %else yMinValue0,     yMaxValue0 ;
        into  :xminValue0,    :xmaxValue0, 
              :yminValue0,    :ymaxValue0    
        from &prefix._byvarMinMax
        %if &axisbypage eq Y %then where byvarIndex=&currentBYvar;
      ;
      %if %length(&yminLogValue_all) ne 0 and (&yrange eq ALL or &ymin eq 0) %then %do;
        select &yminLogValue_all
      %end;
      %else %do;
        select yminLogValue0
      %end;
          into :yminLogValue0
          from &prefix._byvarMinMax
          %if &axisbypage eq Y %then where byvarIndex=&currentBYvar;
        ;

      /* Retrieve x unit */
      %local xmaxUnit;
      %if %length(&xvar_unit) ne 0 %then %do;
        select max(&xvar_unit)
          into   :xmaxUnit 
          from &currentDataset;
      %end;
    quit;
    
    /* Handle scenario where maximum evaluates to less than minimum */
    %if %sysevalf(&xminValue0 ge &xmaxValue0) %then %do;
      %put RTE%str(RROR): &sysmacroname: XMIN (%sysfunc(compress(&xminValue0))) resolved to equal to or greater than XMAX (%sysfunc(compress(&xmaxValue0))).;
      %str(x rm &g_dddata./&outdset..sas7bdat);
      %let g_abort=1;
    %end;
    %if %sysevalf(&yminValue0 ge &ymaxValue0) %then %do;
      %put RTE%str(RROR): &sysmacroname: YMIN (%sysfunc(compress(&yminValue0))) resolved to equal to or greater than YMAX (%sysfunc(compress(&ymaxValue0))).;
      %str(x rm &g_dddata./&outdset..sas7bdat);
      %let g_abort=1;
    %end;
    %tu_abort;

    /* 4.2.1) Prepare X-AXIS statement, if required */

    /* XINT specifies the numeric interval amount for the x axis.
    /  If xint is supplied, the min/max values (supplied or derived) for the      
    /  axis will be amended to make them a lower/higher "multiple" of xint.     
    /----------------------------------------------------------------------*/
    %let xint00=&xint;
    %if %length(&xint) ne 0 %then %do; 
      %let tickCount = %sysevalf(((&xmaxValue0-&xminValue0)/&xint) + 1);
      %if %sysevalf(&tickCount gt 13 or &tickCount lt 2) %then /* [WJB.3.01] Added code to warn user if interval not suitable */
        %put RTW%str(ARNING): &sysmacroname: Value of XINT=&xint is not suitable for one or more plots - XINT will be replaced in this case.;
    %end;
    
    /* If macro must provide interval (no user provided value or inappropriate user provided value), then start with interval appropriate to X unit, 
    /  and then search for best interval using values which are a log10 multiple of 1, 2, or 5 (below or above 1 except below)
    /  If no units, the interval should start with 10 
    /  For DAYS the interval should start with 1 
    /  For HRS the interval should start with 3 and use values produced from doubling up from 3 (if above 2)
    /  e.g. 0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1, 2, 3, 6, 12, 24 etc
    /  For MIN the interval should start with 5 and use values produced from doubling up from 30 (if above 20)
    /  e.g. 0.01, 0.02, 0.05, 0.1, 0.2, 0.5, 1, 2, 5, 10, 20, 30, 60, 120 etc */
    %if %length(&xint) eq 0 or &tickCount gt 13 or &tickCount lt 2 %then %do; /* [WJB.3.01] Added code to recreate interval if not suitable */
      %if %length(&xmaxunit) eq 0 %then %let xint00 = 10;
      %else %if %sysfunc(compress(&xmaxUnit)) eq DAY %then %let xint00 = 1;
      %else %if %sysfunc(compress(&xmaxUnit)) eq HRS %then %let xint00 = 3;
      %else %if %sysfunc(compress(&xmaxUnit)) eq MIN %then %let xint00 = 5;
      %else %let xint00 = 10;

      /* Search for the interval which provides a number of tickmarks as near to but no greater than 7 */
      data _null_;
        xint=&xint00;        
        
        /* If number of tickmarks gt 7, double interval until not */
        if (&xmaxValue0-&xminValue0)/xint gt 7 then do; 
          do until ((&xmaxValue0-&xminValue0)/xint le 7);
            xint = xint*2;
            if xint = 40 and "&xmaxUnit" eq "MIN" then xint=30; /* this makes the step from 20 to 30, for MINS */
            else if xint/(10**floor(log10(xint))) = 4 then xint=5*(10**floor(log10(xint)));  /* this makes the step from e.g. 2 to 5 */
          end;
        end;

        /* If number of tickmarks le 7, halve interval as much as possible without making gt 7 tickmarks */
        else do;
          do while ((&xmaxValue0-&xminValue0)/(xint/2) le 7);
            xintold = xint;
            xint = xint/2;
            if xint = 1.5 and "&xmaxUnit" eq "HRS" then xint=2; /* this makes the step from 3 to 2, for HRS */
            else if xint/(10**floor(log10(xint))) = 2.5 then xint=2*(10**floor(log10(xint))); /* this makes the step from e.g. 5 to 2 */
          end;
          if (&xmaxValue0-&xminValue0)/(xint) gt 7 then xint = xintold;
        end;
        call symput('xint00',compress(putn(xint,'BEST.')));
      run;
    %end;
    
    /* If xminValue0 or xmaxValue0 are not user-supplied, extend them to multiples of the interval */
    data _null_;     /* Added to data _null_ datastep [JmcG.3.02] */
      %if %length(&xmin) eq 0 %then xminValue = floor(&xminValue0/&xint00)*&xint00;
      %else xminValue = &xmin;
      ;
      %if %length(&xmax) eq 0 %then xmaxValue = ceil(&xmaxValue0/&xint00)*&xint00;
      %else xmaxValue = &xmax;
      ;
      call symput('XMINVALUE',compress(putn(xminValue,'BEST.')));
      call symput('XMAXVALUE',compress(putn(xmaxValue,'BEST.')));
    run;
    %if &g_debug ge 1 %then %do;
      %put RTD%str(EBUG): &sysmacroname: XMINVALUE0=&xminValue0 XMAXVALUE0=&xmaxValue0;
      %put RTD%str(EBUG): &sysmacroname: XMINVALUE=&xminValue XMAXVALUE=&xmaxValue;
    %end;
    
    /* Define AXIS ORDER statement for X-axis */
    %let xlinearorder= order=&xminValue to &xmaxValue;
    %if %sysevalf((&xmaxValue-&xminValue)/&xint00) eq %sysfunc(ceil(%sysevalf((&xmaxValue-&xminValue)/&xint00))) %then %do;
      %let xlinearOrder = &xlinearOrder by &xint00;
    %end;
    %else %do;
      %if %length(&xint) ne 0 %then %put RTW%str(ARNING): &sysmacroname: Value of XINT (&xint) cannot be used with XMIN=&xmin and XMAX=&xmax - XINT will be replaced;
      %let xlinearOrder = &xlinearOrder by %sysevalf((&xmaxValue-&xminValue)/5);
    %end;
    %if &g_debug ge 1 %then %put RTD%str(EBUG): &sysmacroname: XLINEARORDER=&xlinearOrder;

    /* Establish how near minimum/maximum plottable x values are to the axes.
    /  If min or max are nearer to the axis than 2% of the total axis length, add an offset */
    %local xOffset xminPlotted xmaxPlotted xminOffset xmaxOffset;
    proc sql noprint;
      select min(&xvar_var)
      into   :xminPlotted 
      from &currentDataset
      where &xvar_var ge &xminValue;
      
      select max(&xvar_var)
      into   :xmaxPlotted 
      from &currentDataset
      where &xvar_var le &xmaxValue;    
    quit;
    
    %let xminOffset = 0;
    %let xmaxOffset = 0;
    %if %length(&xminPlotted) ne 0 %then %do;
      %if %sysevalf((&xminPlotted - &xminValue)/(&xmaxValue - &xminValue) lt 0.02) %then %let xminOffset = 2;
    %end;
    %if %length(&xmaxPlotted) ne 0 %then %do;
      %if %sysevalf((&xmaxValue - &xmaxPlotted)/(&xmaxValue - &xminValue) lt 0.02) %then %let xmaxOffset = 2;
    %end;
    %if &xminOffset eq 2 or &xmaxOffset eq 2 %then %let xOffset=offset=(&xminOffset,&xmaxOffset)pct;
    
    /* 4.2.2) Prepare Y-AXIS - LINEAR, if required */
    %if &g_debug ge 1 %then %put RTD%str(EBUG): &sysmacroname: YMINVALUE0=&yminValue0 YMAXVALUE0=&ymaxValue0 YMINLOGVALUE0=&yminLogValue0;

    /* YINT specifies the numeric interval for the y axis (linear only).     
    /  If not user-supplied, will amend min/max vals (linear) to make a multiple of yint. For the log axis, 
    /  the interval (yint) is ignored, but the min/max are adjusted to the nearest (lower/higher) power of the log.
    /  yminvalue0 and ymaxvalue0 contain min/max data values, or ymin/ymax, if specified. 
    /---------------------------------------------------------------------------- */

    /* If macro must provide interval (no user provided value or inappropriate user provided value), start with 10, 
    /  and then search for best interval using values which are a log10 multiple of 1, 2, or 5 (below or above 1) */
    %if %sysfunc(indexw(&figtype,LINEAR)) %then %do;
      %let yint00=&yint;
      %let tickCount = ;
      %if %length(&yint) ne 0 %then %do;
        %let tickCount = %sysevalf(((&ymaxValue0-&yminValue0)/&yint) + 1);
        %if %sysevalf(&tickCount gt 13 or &tickCount lt 2) %then  /* [WJB.3.01] Added code to warn user if interval not suitable */
          %put RTW%str(ARNING): &sysmacroname: Value of YINT=&yint is not suitable for one or more plots - YINT will be replaced in this case.;
      %end;
      %if %length(&yint) eq 0 or &tickCount gt 13 or &tickCount lt 2 %then %do;
        data _null_;
          yint = 10;
         
          /* If number of tickmarks gt 7, double interval until not */
          if (&ymaxValue0-&yminValue0)/yint gt 7 then do until ((&ymaxValue0-&yminValue0)/yint le 7);
            yint = yint*2;
            if yint/(10**floor(log10(yint))) = 4 then yint=5*(10**floor(log10(yint))); /* this makes the step from e.g. 2 to 5 */
          end;

          /* If number of tickmarks le 7, halve interval as much as possible without making gt 7 tickmarks */
          else do while ((&ymaxValue0-&yminValue0)/(yint/2) le 7);
            yintold = yint;
            yint = yint/2;
            if yint/(10**floor(log10(yint))) = 2.5 then yint=2*(10**floor(log10(yint))); /* this makes the step from e.g. 5 to 2 */
          end;
          if (&ymaxValue0-&yminValue0)/(yint) gt 7 then yint = yintold;
          call symput('yint00',compress(putn(yint,'BEST.')));
        run;
      %end;

      /* If yminValue0 or ymaxValue0 are not user-supplied, extend them to multiples of the interval */
      data _null_;       /* Added to data _null_ datastep [JmcG.3.02] */
        yminLinValue = &yminValue0;
        ymaxLinValue = &ymaxValue0;
        %if %length(&ymin) eq 0 %then %do;
          yminLinValue = floor(&yminValue0/&yint00)*&yint00;
        %end;
        %else %do;
          %if &ymin eq LLQ %then yminLinValue = &minLLQ;
          %else yminLinValue = &ymin;;
        %end;
        %if %length(&ymax) eq 0 %then %do;
          ymaxLinValue = ceil(&ymaxValue0/&yint00)*&yint00;
        %end;
        %else %do;
          ymaxLinValue = &ymax;
        %end;
        call symput('yminLinValue',compress(putn(yminLinValue,'BEST.')));
        call symput('ymaxLinValue',compress(putn(ymaxLinValue,'BEST.')));
        call symput('yminValue',compress(putn(yminLinValue,'BEST.')));
        call symput('ymaxValue',compress(putn(ymaxLinValue,'BEST.')));
      run;

      /* Construct linear AXIS ORDER statement */
      %let ylinearOrder = order=&yminLinValue to &ymaxLinValue; 
      %if %sysevalf((&ymaxLinValue-&yminLinValue)/&yint00)=%sysfunc(ceil(%sysevalf((&ymaxLinValue-&yminLinValue)/&yint00))) %then %do;
        %let ylinearOrder = &ylinearOrder by &yint00;
      %end;
      %else %do;
        %if %length(&yint) ne 0 %then %put RTW%str(ARNING): &sysmacroname: Value of YINT (&yint) cannot be used with YMIN=&ymin and YMAX=&ymax - YINT will be replaced;
        %let ylinearOrder = &ylinearOrder by %sysevalf((&ymaxLinValue-&yminLinValue)/5);
      %end;
      %if &g_debug ge 1 %then %do;
        %put RTD%str(EBUG): &sysmacroname: YMINLINVALUE=&yminLinValue YMAXLINVALUE=&ymaxLinValue;
        %put RTD%str(EBUG): &sysmacroname: YLINEARORDER=&ylinearOrder;
      %end;
    %end;
    
    /* 4.2.3) Prepare Y-AXIS - LOG, if required */
    %if %sysfunc(indexw(&figtype,LOG)) %then %do;
      data _null_;
        /* Search for the closest power of logbase to be less than (or equal to) yminvalue0. */
        minPower=1;
        if &yminLogValue0 gt &ylogbase then do while (&yminLogValue0 ge &ylogbase**(minPower+1));
          minPower = minPower + 1;
        end;
        if &yminLogValue0 lt &ylogbase then do while (&yminLogValue0 le &ylogbase**minPower);
          minPower = minPower - 1;
        end;
        put "RTD" "EBUG: &sysmacroname: YLOGBASE=&ylogbase " minPower=;
  
        /* Deduce tickmarks, up to the first value that exceeds ymaxvalue0 */
        length tickMarks $256;
        tickMarks = '';
        yminLogValue = &ylogbase**minPower;

        /* Construct log AXIS ORDER statement */
        do until(value ge &ymaxValue0 and value gt yminLogValue);
          value = &ylogbase**minPower;
          %if &ylogstyle eq POWER %then %do;
            tickMarks = trim(tickMarks) !! ' ' !! compress(putn(minPower,'BEST.'));
          %end;
          %else %do;
            tickMarks = trim(tickMarks) !! ' ' !! compress(putn(&ylogbase**minPower,'BEST.'));
          %end;
          minPower = minPower + 1;
        end;
        ymaxLogValue = &ylogbase**(minPower-1);
        call symput('yminLogValue',compress(putn(yminLogValue,'BEST.')));
        call symput('ymaxLogValue',compress(putn(ymaxLogValue,'BEST.')));
        call symput('yminValue',compress(putn(yminLogValue,'BEST.')));
        call symput('ymaxValue',compress(putn(ymaxLogValue,'BEST.')));
        call symput('YLOGORDER','order='!!tickMarks);
      run;
      %if &g_debug ge 1 %then %do;
        %put RTD%str(EBUG): &sysmacroname: YMINLOGVALUE=&yminLogValue YMAXLOGVALUE=&ymaxLogValue;
        %put RTD%str(EBUG): &sysmacroname: YLOGORDER=&YLOGORDER;
      %end;
   %end;
    
    %if "&figtype" eq "LINEAR LOG" %then %do; 
      %let yminValue = %sysfunc(min(&yminLinValue, &yminLogValue));
      %let ymaxValue = %sysfunc(max(&ymaxLinValue, &ymaxLogValue));
    %end;
    
    /* 5) Handle records out of axis range     [WJB.3.01]  */
    /* Proc summary to get min/max xvar_val and yvar_val by byvar */
    proc summary data=&currentDataset nway; 
      by byVarIndex;
      var &xvar_var;
      output out=&prefix._minmaxXbyBYvar(drop=_type_ _freq_) min=minxval max=maxxval;
    run;
    proc summary data=&currentDataset nway; 
      by byVarIndex;
      var &yvar_var;
      output out=&prefix._minmaxYbyBYvar(drop=_type_ _freq_) min=minyval max=maxyval;
    run;

    /* Merge minyval/maxyval back, delete where whole BY group is out of axis range */
    %let dropBYflag = N;
    data &prefix._delOffAxis (drop=minxval maxxval minyval maxyval);    
      merge &currentDataset 
            &prefix._minmaxXbyBYvar(keep=byVarIndex minxval maxxval)
            &prefix._minmaxYbyBYvar(keep=byVarIndex minyval maxyval);
      by byVarIndex;
      if maxxval lt &xminValue or minxval gt &xmaxValue
       or maxyval lt &yminValue or minyval gt &ymaxValue then do; /* if min or max by BYVAR is out of axis range */
        %if %length(&actualBYvars) ne 0 and &axisbypage eq N %then %do;
          DELETE;
        %end;
        %else %do;
          call symput('dropBYflag','Y');
          stop;
        %end;
      end;
    run;
    
    %if &dropBYflag eq Y or %tu_nobs(&prefix._delOffAxis) eq 0 %then %goto endloop;
    %let currentDataset = &prefix._delOffAxis;
    
    /* 5.1) Handle rows where values or bars will be outside the plot area  [WJB.3.01]
    /  As there is still a chance that all values could be off axis, set them to null. 
    /  Get a count of those set to null/dropped so that they can be reported to the user.
    /------------------------------------------------------------------------------ */
    %if %sysfunc(indexw(&figtype,LINEAR)) %then %do;
      data &prefix._finalDsetLin;
        set &currentDataset;
        retain dropCount 0;
        if (&yvar_var ne . and &yvar_var lt &yminLinValue) or &yvar_var gt &ymaxLinValue then do;
          &yvar_var = .;
          dropCount = dropCount + 1;
        end;
        else if (&xvar_var ne . and &xvar_var lt &xminValue) or &xvar_var gt &xmaxValue then do;
          &xvar_var = .;
          dropCount = dropCount + 1;
        end;
        call symput('LinDelCount', &LinDelCount + dropCount);
      run;
      %if &g_debug gt 0 %then %put RTD%str(EBUG): LinDelCount=&LinDelCount;
    %end;
    %if %sysfunc(indexw(&figtype,LOG)) %then %do;
      data &prefix._finalDsetLog(drop=dropCount);
        set &currentDataset;
        retain dropCount 0;
        if (&yvar_var ne . and &yvar_var lt &yminLogValue) or &yvar_var gt &ymaxLogValue then do;
          &yvar_var = .;
          dropCount = dropCount + 1;
        end;
        else if (&xvar_var ne . and &xvar_var lt &xminValue) or &xvar_var gt &xmaxValue then do;
          &xvar_var = .;
          dropCount = dropCount + 1;
        end;
        call symput('LogDelCount',&LogDelCount + dropCount);
      run;
      %if &g_debug gt 0 %then %put RTD%str(EBUG): LogDelCount=&LogDelCount;
    %end;	
        
    /* 5.2) Recreate dataset to create record of plotted values */
    %if %sysfunc(indexw(&figtype,LINEAR)) %then %do;
      data &prefix._plottedLinData;
      set 
        %if %sysfunc(exist(&prefix._plottedLinData)) %then 
          &prefix._plottedLinData;
          &prefix._finalDsetLin(keep=&actualBYvars &actualZvar &yvar_var &xvar_var &pcllqn_var);
      run;
    %end;
    %if %sysfunc(indexw(&figtype,LOG)) %then %do;
      data &prefix._plottedLogData;
      set 
        %if %sysfunc(exist(&prefix._plottedLogData)) %then 
          &prefix._plottedLogData;
          &prefix._finalDsetLog(keep=&actualBYvars &actualZvar &yvar_var &xvar_var &pcllqn_var);
      run;
    %end;

   /* 6) Transpose data if summary stats (to get MIN, MAX and YVAR on separate rows)
    /------------------------------------------------------------------------------ */
    %if &disptyp=SUMMARY and &addbars eq Y %then /* [WJB.3.01] */
    %do;  /* summary with bars - transpose */

      /* If bar is out of axis range, set bar value equal to y value
      /  Then transpose the dataset to put min and max in same col as yvar_val but on separate rows.
      /  Do this once for Linear plot and once for Log plot as the min/max values will be different */
      %if %sysfunc(indexw(&figtype,LINEAR)) %then %do;

        /* Count how many obs have bars off axis (don't count those where yvar is null) */
        proc sql noprint;
          select count(*)
          into: byLinBarDelCount
          from &currentDataset
          where &yvar_var ne . and ((min ne . and min lt &yminLinValue) or max gt &ymaxLinValue);  
        quit;
        %let LinBarDelCount = %sysevalf(&LinBarDelCount + &byLinBarDelCount);
        data &prefix._modDsetLin;
          set &prefix._finalDsetLin;
          if &yvar_var eq . or min eq . or min lt &yminLinValue or min gt &ymaxLinValue then min=&yvar_var;
          if &yvar_var eq . or max eq . or max lt &yminLinValue or max gt &ymaxLinValue then max=&yvar_var;
        run;
        proc sort data=&prefix._modDsetLin;
          by &actualBYvars &xvar_var &actualZvar;
        run;
        proc transpose data=&prefix._modDsetLin
                       out=&prefix._finalDsetLin (rename=(col1=&yvar_var) drop=_name_ _label_);
          by &actualBYvars &xvar_var &actualZvar;
          %if %length(&pcllqn_var) ne 0 %then copy &pcllqn_var;;
          var &yvar_var min max;
        run;
      %end;
      %if %sysfunc(indexw(&figtype,LOG)) %then %do;

        /* Count how many obs have bars off axis (don't count those where yvar is null) */
        proc sql noprint;
          select count(*)
          into: byLogBarDelCount
          from &currentDataset
          where &yvar_var ne . and ((min ne . and min lt &yminLogValue) or max gt &ymaxLogValue);
        quit;
        %let LogBarDelCount = %sysevalf(&LogBarDelCount + &byLogBarDelCount);
        data &prefix._modDsetLog;
          set &prefix._finalDsetLog;
          if &yvar_var eq . or min eq . or min lt &yminLogValue or min gt &ymaxLogValue then min=&yvar_var;
          if &yvar_var eq . or max eq . or max lt &yminLogValue or max gt &ymaxLogValue then max=&yvar_var;
        run;
        proc sort data=&prefix._modDsetLog; 
          by &actualBYvars &xvar_var &actualZvar;
        run;
        proc transpose data=&prefix._modDsetLog
                       out=&prefix._finalDsetLog (rename=(col1=&yvar_var) drop=_name_ _label_);
          by &actualBYvars &xvar_var &actualZvar;
          %if %length(&pcllqn_var) ne 0 %then copy &pcllqn_var;;
          var &yvar_var min max;
        run;
      %end;
 
    %end; /* summary with bars - transpose */
    
    %if &llqline eq Y %then %do;
      data %if %sysfunc(indexw(&figtype,LINEAR)) %then 
             &prefix._llqline_anno_lin(where=(Y ge &yminLinValue and Y le &ymaxLinValue));
           %if %sysfunc(indexw(&figtype,LOG)) %then 
             &prefix._llqline_anno_log(where=(Y ge &yminLogValue and Y le &ymaxLogValue));
           ;
        set &prefix._llqline_anno;
      run;
    %end;
    
   /* 7) Generate graphics                                */
    /* 7.1) Create linear graphs into catalogue WORK.LIN.  */
    %if %sysfunc(indexw(&figtype,LINEAR)) %then 
    %do;  /* Create linear graphs */

      goptions nodisplay;
      options nobyline;

      %if "&figtype" eq "LINEAR LOG" %then title1 h=&gptsize "Linear Scale";;
      legend1 frame
              %if &legendLabel eq N %then label=none;
              %else label=(h=&gptsize);
              %if %length(&zvarLegendOrder) gt 0 %then order=(&zvarLegendOrder);
              value=(h=&gptsize);
      axis1 label=(angle=90 h=&gptsize "&ylabel") value=(h=&gptsize) &ylinearOrder;  /* Y-axis */
      axis2 label=(h=&gptsize "&xlabel") value=(h=&gptsize) &xlinearOrder &xoffset;  /* X-axis */
      
      proc gplot data=&prefix._finalDsetLin
                 gout=&prefix._lin;
        %if %length(&actualBYvars) gt 0 %then by &actualBYvars;;
        plot &yvar_var*&xvar_var %if &actualZvar ne  %then =&actualZvar;
             /   
             vaxis=axis1 haxis=axis2 
             %if &llqline eq Y and %sysfunc(exist(&prefix._llqline_anno_lin)) %then %do;
               %if %tu_nobs(&prefix._llqline_anno_lin) ne 0 %then anno=&prefix._llqline_anno_lin;
             %end;
             %if &frameaxes eq N %then noframe;
             %if &legendtype eq INLINE %then legend=legend1;
             %else nolegend;
             %if %length(&href) ne 0 %then href=&href;  /* [WJB.3.01] */
             %if %length(&vref) ne 0 %then vref=&vref;  /* [WJB.3.01] */
             ;
        %if %length(&formats) gt 0 %then %do;
          format &formats;
        %end;
        %else %do; /* Add default formatting for xvar and yvar if none supplied [WJB.3.01] */
          format &xvar_var &yvar_var best6.;
        %end;
      run; 
      quit;
      options byline;
      goptions display;

    %end; /* Create linear graphs */

    /* 7.2) Create log graphs into catalogue WORK.LOG.  */
    %if %sysfunc(indexw(&figtype,LOG)) %then 
    %do;  /* Create log graphs */

      %if %length(&vref) ne 0 and &ylogstyle eq POWER %then %do;
        data _null_;
          vref=log(&vref)/log(&ylogbase);
          call symput('vref',vref);
        run;
      %end;
      
      goptions nodisplay htext=&gptsize.pt;
      options nobyline;
      
      %if "&figtype" eq "LINEAR LOG" %then title1 h=&gptsize "Semi-Logarithmic Scale";;
      legend1 frame
              %if &legendLabel eq N %then label=none;
              %else label=(h=&gptsize);
              %if %length(&zvarLegendOrder) gt 0 %then order=(&zvarLegendOrder);
              value=(h=&gptsize);
      axis1 label=(angle=90 h=&gptsize &yloglabel) value=(h=&gptsize) 
            logbase=&ylogbase logstyle=&ylogstyle &ylogOrder;  /* Y-axis */
      axis2 label=(h=&gptsize "&xlabel") value=(h=&gptsize) 
            &xlinearOrder &xoffset;                            /* X-axis */

      proc gplot data=&prefix._finalDsetLog 
                 gout=&prefix._log;
        %if %length(&actualBYvars) gt 0 %then by &actualBYvars;;
        plot &yvar_var*&xvar_var %if &actualZvar ne %then =&actualZvar;
             / 
             vaxis=axis1 haxis=axis2
             %if &llqline eq Y and %sysfunc(exist(&prefix._llqline_anno_log)) %then %do;
               %if %tu_nobs(&prefix._llqline_anno_log) ne 0 %then anno=&prefix._llqline_anno_log;
             %end;
             %if &frameaxes eq N %then noframe;
             %if &legendtype eq INLINE %then legend=legend1;
             %else nolegend;
             %if %length(&href) ne 0 %then href=&href;  /* [WJB.3.01] */
             %if %length(&vref) ne 0 %then vref=&vref;  /* [WJB.3.01] */
             ;
        %if %length(&formats) gt 0 %then %do;
          format &formats;
        %end;
        %else %do; /* Add default formatting for xvar and yvar if none supplied [WJB.3.01] */
          format &xvar_var &yvar_var best6.;
        %end;
      run; 
      quit;
      options byline;
      goptions display;
    %end; /* Create log graphs */
    
    %endloop:
    
  %end; 
  
  /* Interrogate plotted data to identify data not plotted - may be all, whole by var, or single data points */
  %if %sysfunc(exist(&prefix._plottedLinData)) and %sysfunc(exist(&prefix._plottedLogData)) %then %do;
    proc sort data=&prefix._plottedLinData;
      by &actualBYvars &actualZvar &yvar_var &xvar_var &pcllqn_var;
    run;  
    proc sort data=&prefix._plottedLogData;
      by &actualBYvars &actualZvar &yvar_var &xvar_var &pcllqn_var;
    run;  
    data &prefix._plottedData &prefix._plottedLinOnly 
         &prefix._plottedLogOnly;
      merge &prefix._plottedLinData(in=a) &prefix._plottedLogData(in=b);
      by &actualBYvars &actualZvar &yvar_var &xvar_var &pcllqn_var;
      if a or b then output &prefix._plottedData;
      if a and not b and &yvar_var ne . and &xvar_var ne . then output &prefix._plottedLinOnly;
      else if b and not a and &yvar_var ne . and &xvar_var ne . then output &prefix._plottedLogOnly;
    run;
    %let currentDataset = &prefix._plottedData;
  %end;
  %else %if %sysfunc(exist(&prefix._plottedLinData)) %then %do;
    %let currentDataset = &prefix._plottedLinData;
  %end;
  %else %do;
    %let currentDataset = &prefix._plottedLogData;
  %end;
  
  /* Warn user where all data, or whole by var, has not been plotted */
  %if not %sysfunc(exist(&currentDataset)) %then %do; /* If no data was plotted, pass to gnoreport */
    %put RTW%str(ARNING): &sysmacroname: All values in the plotted dataset are out of axis range. No data will be reported.;
    %tu_gnoreport(outfile=&outfile);
    %goto exit;
  %end;
  %else %if %length(&actByvarname) ne 0 %then %do; /* Else check for by vars which were not plotted and inform the user */
    proc sql noprint;
      create table &prefix._plottedBYs as
      select distinct %tu_sqlnlist(&actualBYvars)
      from &currentDataset
      order by &actBYvarcode;

      create table &prefix._allBYs as
      select distinct %tu_sqlnlist(&actualBYvars)
      from &prefix._&outdset      
      order by &actBYvarcode;
    quit;
    data _null_;
      merge &prefix._plottedBYs(in=plotted) &prefix._allBYs;
      by &actBYvarcode;
      if not plotted then
        put "RTW" "ARNING: &sysmacroname: All values for &actBYvarname = " &actBYvarname " are outside of axis range and therefore will not be plotted";
    run;
  %end;

  /* Warn user about any "single" values which have not been plotted [WJB.3.01] */
  %local LinOnlyCount LogOnlyCount;
  %if %sysfunc(exist(&prefix._plottedLinOnly)) %then %let LinOnlyCount = %tu_nobs(&prefix._plottedLinOnly);
  %else %let LinOnlyCount = 0;
  %if %sysfunc(exist(&prefix._plottedLogOnly)) %then %let LogOnlyCount = %tu_nobs(&prefix._plottedLogOnly);
  %else %let LogOnlyCount = 0;
  %if %sysevalf(&LinDelCount gt 0) %then
    %put RTW%str(ARNING): &sysmacroname: %sysfunc(trim(&LinDelCount)) values are outside of axis range on the linear plot and will not be plotted;
  %if %sysevalf(&LogDelCount gt 0) %then
    %put RTW%str(ARNING): &sysmacroname: %sysfunc(trim(&LogDelCount)) values are outside of axis range on the log plot and will not be plotted;      
  %if %sysevalf(&LinBarDelCount gt 0) %then
    %put RTW%str(ARNING): &sysmacroname: %sysfunc(trim(&LinBarDelCount)) bars are outside of axis range on the linear plot and will not be plotted;
  %if %sysevalf(&LogBarDelCount gt 0) %then
    %put RTW%str(ARNING): &sysmacroname: %sysfunc(trim(&LogBarDelCount)) bars are outside of axis range on the log plot and will not be plotted;      
  %if %sysevalf(&LinOnlyCount gt 0) %then 
    %put RTW%str(ARNING): &sysmacroname: %sysfunc(trim(&LinOnlyCount)) values plotted on the linear scale but not the log scale. This may be handled using d_subset or POSTSUBSET;
  %if %sysevalf(&LogOnlyCount gt 0) %then 
    %put RTW%str(ARNING): &sysmacroname: %sysfunc(trim(&LogOnlyCount)) values plotted on the log scale but not the linear scale. This may be handled using d_subset or POSTSUBSET;

  goptions reset=goptions 
           ftitle=&font 
           ftext=&font 
           htitle=&ptsize.pt 
           htext=&ptsize.pt 
           device=&device
           vsize=&vsize 
           hsize=&hsize 
           horigin=&horigin 
           vorigin=&vorigin
           rotate=&rotate
           xmax=8.5 in 
           ymax=11 in  
           cback=white 
           ctext=black 
           gsfmode=replace 
           gsfname=output;
        
  /* 7.3) Create head/foot slides into catlg WORK.HF     
  /  Allow the graph to be run using only the log option [JmcG.3.01] */
  goptions nodisplay;
  %tu_cr8gheadfoots(gout    = &prefix._hf,
                    kill    = y,
                    %if %sysfunc(indexw(&figtype,LINEAR)) %then pagecat = &prefix._lin, ;
                    %else pagecat = &prefix._log, ;
                    font    = &font,
                    ptsize  = &ptsize
                   );
  goptions display;
  
  /* 7.4) Create BY slides into catlg WORK.BY            */
  %if %length(&actualBYvars) gt 0 %then
  %do;
    goptions nodisplay;
    %tu_cr8gbys(gout=&prefix._by
            ,kill=y
            ,dsetin=&currentDataset
            ,byvars=&byvars
            ,style=&bystyle);
    goptions display;
  %end;

  /* 7.5) Create legend slide as gseg.legend.gseg   */
  %if &legendtype eq ACROSS %then 
  %do;
    /*  NOTE: The symbols used to produce the graphs must still be in action at this point, 
    /         else the legend will not match the graphs. */
    goptions nodisplay;

    /* Apply any formats to to the legend dataset so that the formatted values appear in the legend [JMcG.1.06] */
    data &prefix._legdset;
      set &currentdataset;
      &yvar_var=.; /* set to null to avoid warning that values are out of axis range [WJB.3.01] */
      &xvar_var=.; /* set to null to avoid warning that values are out of axis range [WJB.3.01] */
    run;

    %tu_cr8glegend(dsetin=&prefix._legdset
                  ,gout=&prefix._legend
                  ,goutent=legend
                  ,kill=y
                  ,legendlabel=&legendLabel
                  ,xvar=&xvar_var
                  ,yvar=&yvar_var
                  ,zvar=&actualZvar
                  %if %length(&zvarLegendOrder) gt 0 %then ,ordermvar=zvarLegendOrder;);
    goptions display;
  %end;
  
  /* 7.6) Call tu_templates macro to generate graphic */
  /* Make sure we request graphs in the right order, i.e. linear/log or log/linear (latter is currently invalid) */
  %local graffcats thisType thisWordPtr;
  %let thisWordPtr = 1;
  %let thisType = %scan(&figtype,&thisWordPtr);
  %do %while (%length(&thisType) gt 0);
    %if &thisType eq LOG %then
      %let graffcats = &graffcats &prefix._log;
    %else %if &thisType eq LINEAR %then
      %let graffcats = &graffcats &prefix._lin;  /* [WJB.3.01] Else not required as any other combination will not make it through parameter validation */
    %let thisWordPtr = %eval(&thisWordPtr + 1);
    %let thisType = %scan(&figtype,&thisWordPtr);
  %end; /* loop over words in figtype */

  %tu_templates(graphcats=&graffcats
               ,hfcat=&prefix._hf
               ,layout=&layout
               ,topy=&topy
               ,boty=&boty
               ,outfile=&outfile
               ,framePage=N
               ,framePlot=N
               %if %length(&actualBYvars) gt 0 %then ,bycat=&prefix._by;
               %if &legendtype eq ACROSS %then ,legend=&prefix._legend.legend.grseg;
               );
  
  /* 8) Clean up                                         */
  /* [JMcG.5.01] Create exit block   */
  %exit:

  /* Handling for PDF creation via PS graphics driver [WJB.3.01] */
  %if &pdfprod eq Y %then %str(
   x ps2pdf &g_outfile..PS &g_outfile..PDF;
   x rm &g_outfile..PS;
  );

  /* Delete temporary data items used in this macro. */
  %if &g_debug le 8 %then %do;
    proc datasets lib=work nolist;
      delete &prefix: / mt=catalog;
    quit;
  %end;
  
  %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

  %tu_abort;
  
%mend tu_pktfig;
