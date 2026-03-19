/*******************************************************************************
|
| Macro Name:      tu_pkcfig
|
| Macro Version:   1.003
|
| SAS Version:     8.2
|                                                             
| Created By:      James McGiffen 
|
| Date:            29-Jul-2005
|
| Macro Purpose:   To create graphs of concentration data versus Catagorical
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME             DESCRIPTION                                  REQ/OPT  DEFAULT
| --------------   -----------------------------------          -------  --------------
|  bars              Bars to be applied to graph                    REQ      NONE
|  boty              Specifies the lowest point of y (%)            REQ      5
|  bystyle           Style of the by line                           OPT      LABEL-EQUALS-COMMA
|  byvars            Variables for by vars                          OPT      [BLANK] 
|  device            Goptions Device                                REQ      &G_TEXTFILESFX            
|  dsetin            type:ID Input dataset                          REQ      [BLANK]
|  dsetout           Output dataset                                 OPT      [BLANK
|  figtype           Plot Type(Linear, log, Linear log)             REQ      LINEAR LOG   
|  font              Specifies the font for %tu_pagesetup           REQ      SWISS
|  formats           Formats to be applied in the plot              OPT      [BLANK]
|  framePage         Place frame around page?                       REQ      N
|  framePlot         Place frame around plot(s)?                    REQ      N
|  getdatayn         Execute tu_getdata macro?                      REQ      Y
|  gmmeanyn          Add Geometric mean                             REQ      N
|  gptsize           Specifies the point size for graphs            OPT      [BLANK]
|  href              Horizontal reference line value                OPT      [BLANK]
|  layout            Plot Layout (2up or 1up)                       REQ      2UP
|  labelvarsyn       Execute tu_labelvars macro?                    REQ      Y 
|  legendlabel       Switch On/off Legend label (Y/N)               REQ      Y
|  legendtype        The type of legend (ACROSS, INLINE, NONE)      REQ      ACROSS
|  outfile           Name of output file                            REQ      &G_OUTFILE..&G_TEXTFILESFX
|  ptsize            Specifies the point size for %tu_pagesetup     REQ      10
|  style             Type of graph (mean, individual, etc)          REQ      INDIVIDUAL
|  symbolColor       Colours for symbol statements                  REQ      BLACK
|  symbolInterpol    Interpolations for symbol statements           REQ      JOIN
|  symbolLine        Lines for symbol statements                    REQ      1 2 3 4 5 6 7 8 9 10 11 12 
|                                                                            13 14 15 16 17 18 19 20 21 22 23 24
|  symbolMax         Number of SYMBOL statements                    REQ      24
|  symbolOther       Other elements for symbol statements           OPT      [BLANK]
|  symbolOtherDelim  Delimiter for SYMBOLOTHER                      OPT      /
|  symbolValue       Plot symbols for symbol statements             REQ      DIAMOND PLUS SQUARE X TRIANGLE 
|                                                                            STAR - HASH  _ DOT CIRCLE  
|  topy              Specifies the highest point of y (%)           REQ      95
|  varlabelstyle     Style of labels to be applied by tu_labelvars  REQ      STD
|  vref              Vertical reference line value                  OPT      [BLANK]
|  xint              X-Order interval                               OPT      [BLANK]
|  xlabel            X-Axis Label                                   OPT      [BLANK]
|  xmax              Upper limit of X-Axis                          OPT      [BLANK]
|  xmin              Lower limit of X-Axis                          OPT      [BLANK]
|  xvar              X-Axis and Order var                           REQ      [BLANK]
|  xvarlogyn         if log graph? log x axis Y\N                   REQ      N
|  xvarorder         X axis order by string                         OPT      [BLANK]
|  yint              Y-Order interval                               OPT      [BLANK]
|  ylabel            Y-Axis Label                                   OPT      [BLANK]
|  ylogbase          Y-Axis Log base                                OPT      10
|  ylogstyle         The type of log (EXPAND or POWER)              OPT      EXPAND
|  ymax              Upper limit of Y-Axis                          OPT      [BLANK]
|  ymin              Lower Limit of Y-Axis                          OPT      [BLANK]
|  yvar              Y-Var                                          REQ      [BLANK]
|  zvar              3rd Classification Variable                    OPT      [BLANK]
|
| Output: Graphics file containing conc vs time graphs
|
| Global macro variables created: NONE
|
| Macros called:
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_chkvartype
| (@) tu_chknames
| (@) tu_cr8gbys
| (@) tu_cr8gheadfoots
| (@) tu_cr8glegend
| (@) tu_cr8macarray
| (@) tu_getdata
| (@) tu_gnoreport
| (@) tu_labelvars
| (@) tu_nobs
| (@) tu_pagesetup
| (@) tu_putglobals
| (@) tu_sqlnlist
| (@) tu_templates
| (@) tu_tidyup
| (@) tu_valparms
| (@) tu_words
|
| Example:
| %tu_pkcfig(dsetin=ardata.pkcnc
|   , xvar    = pcwnlrt
|   , yvar    = pcstimpn
|   , zvar    = 
|   , byvars  = trtgrp
|   , layout  = 2up
|   , legendtype = none
|   , figtype = linear log
|   , device  = pdf
|   , ptsize  = 10
|   , font    = simplex
|   , style   = individual
|   , bars    = range
|   , ylabel = Analysis in Std Units (NQ)
|  );
|
|******************************************************************************
| Change Log
|
| Modified By:              James McGiffen
| Date of Modification:     28-July-05
| New version/draft number: 01.002
| Modification ID:          JMcG.01.002
| Reason For Modification:  Small changes in response to SCR - Not marked in code
|
| Modified By:              James McGiffen  
| Date of Modification:     29-July-05
| New version/draft number: 01.003
| Modification ID:          JMcG.01.003
| Reason For Modification:  JMCG.01.003.01 - Add catch all label statement to all axis
|
| Modified By:
| Date of Modification:
| New version/draft number:
| Modification ID:
| Reason For Modification:
*******************************************************************************/
%macro tu_pkcfig(
   bars = none           /*Bars to be applied to graph */
  ,boty = 5              /*Specifies the lowest point of y (%) */
  ,bystyle = label-equals-comma  /*Style of the by line */
  ,byvars =              /*Variables for by vars */
  ,device = &g_textfilesfx   /*Goptions Device*/
  ,dsetin=               /*type:ID Input dataset*/
  ,dsetout=              /*Output dataset*/
  ,figtype=Linear log    /*Plot Type(Linear, log, Linear log)*/
  ,font = swiss          /*Specifies the font for %tu_pagesetup */
  ,formats =             /*Formats to be applied in the plot */
  ,framePage = N         /*Place frame around page? */
  ,framePlot = N         /*Place frame around plot(s)? */
  ,getdatayn = Y         /*Execute tu_getdata macro? */
  ,gmmeanyn = N          /*Add Geometric mean */
  ,gptsize =             /*Specifies the point size for graphs */
  ,href=                 /*Horizontal reference line value*/
  ,labelvarsyn = Y       /*Execute tu_labelvars macro? */
  ,layout= 2up           /*Plot Layout (2up or 1up)*/
  ,legendlabel =N        /*Switch On/off Legend label (Y/N)*/
  ,legendtype = ACROSS   /*The type of legend (ACROSS, INLINE, NONE) */
  ,outfile=&g_outfile..&g_textfilesfx /*Name of output file */
  ,ptsize = 10           /*Specifies the point size for %tu_pagesetup */
  ,style=individual      /*Type of graph (mean, individual, etc)*/    
  ,symbolColor = black   /*Colours for symbol statements */
  ,symbolInterpol = join /*Interpolations for symbol statements */
  ,symbolLine = 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 /*Lines for symbol statements */
  ,symbolMax = 24        /*Number of SYMBOL statements */
  ,symbolOther =         /*Other elements for symbol statements */
  ,symbolOtherDelim = /  /*Delimiter for SYMBOLOTHER */
  ,symbolValue = diamond plus square X triangle star - hash  _ dot circle : /*Plot symbols for symbol statements */
  ,topy = 95             /*Specifies the highest point of y (%) */
  ,varlabelstyle = STD   /*Style of labels to be applied by tu_labelvars */
  ,vref=                 /*Vertical reference line value*/ 
  ,xint =                /*X-Order interval*/
  ,xlabel=               /*X-Axis Label*/
  ,xmax =                /*Upper limit of X-Axis*/
  ,xmin =                /*Lower limit of X-Axis*/
  ,xvar=                 /*X-Axis and Ordervar*/
  ,xvarlogyn =N          /*if log graph? log x axis Y\N*/
  ,xvarorder =           /*X axis order by string */
  ,yint =                /*Y-Order interval*/
  ,ylabel =              /*Y-Axis Label*/
  ,ylogbase=10           /*Y-Axis Log base*/
  ,ylogstyle=Expand      /*The type of log (EXPAND or POWER)*/
  ,ymax =                /*Upper limit of Y-Axis*/
  ,ymin =                /*Lower Limit of Y-Axis*/
  ,yvar=                 /*Y-Var */
  ,zvar =                /*3rd Classification Variable*/
  );

  /**---------------------------------------------------------------------*/
  /*--Normal Processing (NP1) -  Echo parameter values and global macro variables to the log */
  %local MacroVersion prefix currentDataset i macroname;
  %let macroname = &sysmacroname.;
  %let MacroVersion = 1;
  %let prefix = %substr(&sysmacroname,3); 
  %let currentDataset=&dsetin;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_analy_disp);

  /**---------------------------------------------------------------------*/
  /*-- NP2 \ PV2 - Remove any pre-existing output */
  data _null_;
    length fileref $8;
    fileref='';
    rc = filename(fileref,"&outfile");
    if rc ne 0 then do;
      sysmsg = sysmsg();
      put "RTE" "RROR: &sysmacroname: Attempt to allocate fileref to OUTFILE failed";
      put "RTE" "RROR: &sysmacroname: " sysmsg;
      call symput('G_ABORT','1');
    end;
    else do;
      if fexist(fileref) then do;  /* file exists, and should be deleted */
        rc = fdelete(fileref);
        if rc ne 0 then do;
          sysmsg = sysmsg();
          put "RTE" "RROR: &sysmacroname: Attempt to delete OUTFILE failed";
          put "RTE" "RROR: &sysmacroname: " sysmsg;
          call symput('G_ABORT','1');
        end;
      end; /* file exists, and should be deleted */
      rc = filename(fileref,"");
      if rc ne 0 then do;
        sysmsg = sysmsg();
        put "RTE" "RROR: &sysmacroname: Attempt to deallocate fileref for OUTFILE failed";
        put "RTE" "RROR: &sysmacroname: " sysmsg;
        call symput('G_ABORT','1');
      end;
    end;
  run;
  /*----------------------------------------------------------------------*/
  /*--NP3 - Split out the variables to thier components */
  /*-- NP3.1 - Split out the Xvar to xvar_var and xvarordervar */
  %local xvar_var xvarordervar xvar_wrds;
  %let xvar =%nrbquote(&xvar);
  %let xvar_wrds = %tu_words(&xvar., delim=%str(=));
  %let xvar_var = %scan(&xvar.,1,=);
  %if &xvar_wrds. = 2 %then %let xvarordervar = %scan(&xvar.,2,%str(=));
  %else %let xvarordervar = ;

  /*-- NP3.2 - Split out the Zvar to Zvar_var and zvarordervar */
  %local zvar_var zvarordervar zvar_wrds;
  %let zvar =%nrbquote(&zvar);
  %let zvar_wrds = %tu_words(&zvar., delim=%str(=));
  %let zvar_var = %scan(&zvar.,1,=);
  %if &zvar_wrds. = 2 %then %let zvarordervar = %scan(&zvar.,2,%str(=));
  %else %let zvarordervar = ;

  /*----------------------------------------------------------------------*/
  /*--NP4 - Split out the Yvar into yvar var */
  %local yvar_var yvar_unit yvar_wrds;
  %let yvar_wrds = %tu_words(&yvar., delim=%str( ));
  %let yvar_var = %scan(&yvar.,1);
  %if &yvar_wrds. = 2 %then %do;
    %put %str(RTN)OTE: &sysmacroname: This graph macro does not support the format yvar unit, the unit variable will be ignored;
  %end;
  /*----------------------------------------------------------------------*/
  /*-- NP5 - Parameter cleanup */
  %let dsetin=%nrbquote(&dsetin);
  %let dsetout=%nrbquote(&dsetout);
  %let outfile = %nrbquote(&outfile);
  %let figtype=%nrbquote(%upcase(&figtype));
  %let layout=%nrbquote(%upcase(&layout));
  %let style =%nrbquote(%upcase(&style));
  %let xvar_var=%nrbquote(&xvar_var);
  %let xvarordervar=%nrbquote(&xvarordervar);
  %let xvarorder=%nrbquote(&xvarorder);
  %let xvarlogyn=%nrbquote(%upcase(&xvarlogyn));
  %let xlabel=%nrbquote(&xlabel);
  %let yvar_var=%nrbquote(&yvar_var);
  %let yvar_unit=%nrbquote(&yvar_unit);
  %let ylabel =%nrbquote(&ylabel);
  %let zvar_var =%nrbquote(&zvar_var);
  %let zvarordervar =%nrbquote(&zvarordervar);
  %let ymin =%nrbquote(&ymin);
  %let ymax =%nrbquote(&ymax);
  %let yint =%nrbquote(&yint);
  %let xmin =%nrbquote(&xmin);
  %let xmax =%nrbquote(&xmax);
  %let xint =%nrbquote(&xint);
  %let ylogbase=%nrbquote(&ylogbase);
  %let ylogstyle=%nrbquote(%upcase(&ylogstyle));
  %let legendLabel =%nrbquote(%upcase(&Legendlabel));
  %let legendtype =%nrbquote(%upcase(&legendtype));
  %let Device =%nrbquote(%upcase(&Device));
  %let byvars =%nrbquote(&byvars);
  %let bystyle =%nrbquote(%upcase(&bystyle));
  %let topy =%nrbquote(&topy);
  %let boty =%nrbquote(&boty);
  %let font =%nrbquote(&font);
  %let ptsize =%nrbquote(&ptsize);
  %let gptsize =%nrbquote(&gptsize);
  %let bars =%nrbquote(%upcase(&bars));
  %let gmmeanyn = %nrbquote(%upcase(&gmmeanyn.));
  /*we will not quote &symbolcolor as it affects other macros*/
  %let symbolvalue =%nrbquote(&symbolvalue);
  %let symbolline =%nrbquote(&symbolLine);
  %let symbolinterpol =%nrbquote(&symbolinterpol);
  %let symbolother =%nrbquote(&symbolother);
  %let symbolotherDelim =%nrbquote(&symbolotherDelim);
  /*we will not quote (&symbolmax) as it affects other macros*/
  %let framePage =%nrbquote(%upcase(&framePage));
  %let framePlot =%nrbquote(%upcase(&framePlot));
  %let getdatayn =%nrbquote(%upcase(&getdatayn));
  %let labelvarsyn =%nrbquote(%upcase(&labelvarsyn));
  %let varlabelstyle =%nrbquote(&varlabelstyle);  
  %let formats =%nrbquote(&formats);  
  %let href =%nrbquote(&href);  
  %let vref =%nrbquote(&vref);  


  /*----------------------------------------------------------------------*/
  /*-- NP6 - Perform Paramter validation*/
  /*-- set up a macro variable to hold the pv_abort flag*/
  %local pv_abort;
  %let pv_abort = 0;

  /*--PV1 - DSETIN: check that the dsetin exists*/
  %tu_valparms(macroname = &macroname., chktype=dsetExists, pv_dsetin = dsetin, abortyn = Y);
  /*--PV2 - OUTFILE: see the removal of prexisting output and also %tu_templates  */

  /*--PV3.1 - FIGTYPE: figtype is one of log, linear or linear log*/
  %if %index( "LOG" "LINEAR" "LINEAR LOG", "&figtype.") = 0 %then %do;
    %put %str(RTE)RROR: &macroname: The FIGTYPE (&figtype.) is not one of LOG, LINEAR or LINEAR LOG;
    %let pv_abort = 1;
  %end;
  %if %index( "LOG" "LINEAR LOG", "&figtype.") gt 0 %then %do;
    /*PV3.2 - FIGTYPE: if log then yvar is numeric*/
    %tu_valparms(macroname = &macroname., chktype = isNum, pv_dsetin = dsetin, pv_varsin = yvar_var);
    /*--PV3.3 - FIGTYPE: There are no negative values  validated after we check yvar*/
  %end;
  /*--PV4 - LAYOUT: is one of 1up or 2up*/
  %tu_valparms(macroname = &macroname., chktype = isOneOf, pv_varsin=layout,
               valuelist = 1up 2up);

  /*--PV5.1 STYLE: is one of mean , individual or spaghetti */
  %tu_valparms(macroname = &macroname., chktype = isOneOf, pv_varsin=style,
                valuelist = mean individual spaghetti);
  /*--PV5.2 STYLE: - warning for spaghetti*/
  %if &style eq SPAGHETTI and %length(&zvar.) eq 0 %then %do;
    %put RTW%str(ARNING): &macroname: It is common to code a value for ZVAR with STYLE=SPAGHETTI, yet no value was specified for ZVAR;
  %end;
  /*--PV5.3 - STYLE: - if  mean then zvar need to be populated*/
  %if &style. eq MEAN and %length(&zvar_var.) eq 0 %then %do;
    %put RTE%str(RROR): &macroname: If style = mean then zvar must be populated;
    %let pv_abort = 1;
  %end;

  /*--PV6.1 XVAR: should be a variable in dsetin */
  %tu_valparms(macroname=&macroname., chktype= isnotblank,pv_varsin = xvar_var,abortyn = Y);	
  %tu_valparms(macroname=&macroname., chktype=varExists, pv_dsetin=dsetin, 
                pv_varsin = xvar_var,abortyn = Y);
  /*--PV6.4 XVAR: should have at least 1 populated value */
  /*Handled in np 17.3   */

  
  /*--PV6.2 XVARORDERVAR should be on the dataset */
  %if %length(&xvarordervar.) gt 0 %then %do;
    %tu_valparms(macroname=&macroname., chktype=varExists, pv_dsetin=dsetin, pv_varsin = xvarordervar);
  %end;
  
  /*--PV6.3 - if there is an ordervar then xvarorder is blank*/
  %if %length(&xvarordervar.) gt 0 and %length(&xvarorder.) gt 0 %then %do;
    %put %str(RTE)RROR: &macroname: xvarorder (&xvarorder) must be blank if a variable for ordering xvar (&xvarordervar) is selected;
    %let pv_abort = 1;
  %end;
  /*--PV7 XLABEL: No validation at present */

  /*--PV8.1 - Xvarlogyn is y or n*/
  /*--PV17 - LEGENDLABEL: is y or n*/
  /*--PV34 - framepage is y or n*/
  /*--PV35 - frameplot is y or N*/
  /*--PV37.1 - gmmeanyn = Y or N*/
  /*--PV44 - getdatayn = y or N*/
  /*--PV45.1 -labelvarsyn = y or N */
  %tu_valparms(macroname = &macroname, chktype=isoneof, 
                pv_varsin = xvarlogyn framepage frameplot gmmeanyn legendlabel getdatayn labelvarsyn,  
                valuelist = Y N);
  /*--PV8.2 - if xvarlogyn = y then xvar is numeric*/
  %if &xvarlogyn. = Y %then %do;
    %tu_valparms(macroname = &macroname., chktype = isnum, pv_dsetin = dsetin, pv_varsin = xvar_var);
  %end;

  /*--PV9 - if xvarorder used then all the values xvar should be specified in the order */
  %if %length(&xvarorder.) gt 0 %then %do;
    /*-- get the distinct xvars*/
    proc sql noprint;
      create table &prefix._dist_xvar as
      select distinct &xvar_var.
      from &dsetin.;
    quit;
    /*-- create macro variables */
    data _null_;
      set &prefix._dist_xvar end=last;
      call symput(compress('d_xvar'||put(_n_,3.)), trim(&xvar_var.));
      if last then call symput ("d_xvar0",put(_n_,3.));
    run;

    %do I = 1 %to &d_xvar0.;
      /*-- if we have a value then everything is ok*/
      %if %index(&xvarorder., &&d_xvar&i.) eq 0 %then %do;
        %put %str(RTW)ARNING: &macroname.: Xvar (&xvar_var.) has a value %trim(%left(&&d_xvar&i.)) that is not on the xvarorder (&xvarorder.);
      %end;
    %end;
    /*--PV9.1 - Check that if xvarorder has been selected no xmin xmax or xint */
    %if %length(%cmpres(&xmin. &xmax. &xint.)) gt 0 %then %do;
      %put %str(RTE)RROR: &macroname: if xvarorder (&xvarorder.) is selected then you cannot have XMIN (&xmin.), XMAX (&xmax.) or XINT (&xint.) populated;
      %let pv_abort = 1;
    %end;
  %end;
  /*--PV10.1 -Yvar is a variable on dsetin */
  %tu_valparms(macroname=&macroname., chktype= isnotblank,pv_varsin = yvar_var, abortyn = Y);
  %tu_valparms(macroname=&macroname., chktype = varexists, pv_dsetin = dsetin
                ,pv_varsin = yvar_var ,abortyn = Y);

  %if %index( "LOG" "LINEAR LOG", "&figtype.") gt 0 %then %do;
    /*--PV3.3 - FIGTYPE: There are no negative values on yvar*/
    /* handled in normal processing point 19.5.1    */
  
    /*--PV15.1 - YLOGBASE: - is required */
    %if %length(&ylogbase.) = 0 %then %do;
      %put %str(RTE)RROR: &macroname: if FIGTYPE = &figtype. then YLOGBASE ( &ylogbase.) cannot be blank;
      %let pv_abort = 1;
    %end;
    /*--PV15.2 - YLOGBASE: - is numeric*/
    %if %datatyp(&ylogbase) ne NUMERIC %then %do;
      %put %str(RTE)RROR: &macroname: if FIGTYPE = &figtype. then YLOGBASE ( &ylogbase.) must be numeric;
      %let pv_abort = 1;
    %end;

    /*--PV16.1 \ 16.2 - ylogstyle must be expand or power */
    %tu_valparms(macroname = &macroname., chktype = isOneOf, pv_varsin = ylogstyle,
                  valuelist = EXPAND POWER);
  %end;

  /*--PV11 - YLABEL - No paramter validation at this time*/
  
  /*--PV12 - ZVAR: - is a variable on the dataset*/
  %if %length(&zvar.) gt 0 %then %do;
    %tu_valparms(macroname= &macroname., chktype = varExists, pv_dsetin = dsetin,
                  pv_varsin = zvar_var);
  %end;

  /*--pv13 - Vref between min and max yvar*/
  %if %length(&vref.) gt 0 and %tu_chkvartype(dsetin=&dsetin., varin= &yvar_var.) = N %then %do;
    %local min_yvar max_yvar;
    /*-- get the min an max xvar values */
    proc sql noprint;
      select min(&yvar_var.), max(&yvar_var.) into :min_yvar, :max_yvar
      from &dsetin.
      where &yvar_var ne . ;
    quit;
    %if &g_debug. gt 0 %then %put RTDEBUG: &macroname.: The min and max values of yvar are &min_yvar. and &max_yvar.;;
    %if %sysevalf(&vref. lt &min_yvar. ) %then %do;
      %put %str(RTW)ARNING: &macroname.: The value of VREF (&vref.) is below the minimum value (&min_yvar.) of the yvar (&yvar.);
    %end;
    %else %if %sysevalf(&vref. gt &max_yvar. ) %then %do;
      %put %str(RTW)ARNING: &macroname.: The value of VREF (&vref.) is above the maximum value (&max_yvar.) of the yvar (&yvar.);
    %end;
  %end;

  /*--pv14 - Href between min and max xvar*/
  %if (%length(&href.) gt 0) and (%tu_chkvartype(dsetin=&dsetin., varin= &xvar_var.) = N) %then %do;
    %local min_xvar max_xvar;
    /*-- get the min an max xvar values */
    proc sql noprint;
      select min(&xvar_var.), max(&xvar_var.) into :min_xvar, :max_xvar
      from &dsetin.
      where &xvar_var ne . ;
    quit;
    %if &g_debug. gt 0 %then %put RTDEBUG: &macroname.: The min and max values of xvar are &min_xvar. and &max_xvar.;;
    %if %sysevalf(&href. lt &min_xvar.) %then %do;
      %put %str(RTW)ARNING: &macroname.: The value of HREF (&href.) is below the minimum value (&min_xvar.) of the xvar (&xvar.); 
    %end;
    %else %if %sysevalf(&href. gt &max_xvar.) %then %do;
      %put %str(RTW)ARNING: &macroname.: The value of HREF (&href.) is above the maximum value (&max_xvar.) of the xvar (&xvar.); 
    %end;
  %end;

  /*--PV18 - LEGENDTYPE: Should be accross inline or none also validated by tu_cr8glegend*/
  %tu_valparms(macroname = &macroname., chktype = isOneOf, pv_varsin = legendtype,
               valuelist = ACROSS INLINE NONE);
  
  /*--PV18.1 - no zvar then no legendtype*/
  %if %length(&zvar.) eq 0 and &legendtype. ne NONE %then %do;
    %put %str(RTE)RROR: &macroname: If there is no ZVAR then LEGENDTYPE (&legendtype.) must be NONE;
    %let pv_abort = 1;
  %end;    
  /*--PV18.2 - if layout = 1up the legendtype must not be across */
  %if &layout. = 1UP and &legendtype. eq ACROSS %then %do;
    %put %str(RTE)RROR: &macroname: If layout = 1UP then LEGENDTYPE (&legendtype.) must not be ACROSS (consider INLINE);
    %let pv_abort = 1;
  %end;    


  /*--PV19 - is a device known to sas*/
  proc catalog c=sashelp.devices;
    contents out=work.&prefix._devices (where=(name eq "&device"));
  run; quit; 
  %if %tu_nobs(work.&prefix._devices) eq 0 %then %do;
    %put %str(RTE)RROR: &macroname: The value of the DEVICE (&device.) is not known to SAS as a graphics device;
    %let pv_abort = 1;
  %end;

  /*--PV20 - BYVARS: Are variables in dsetin*/
  %if %length(&byvars.) ne 0 %then %do;
    %tu_valparms(macroname = &macroname., chktype = varexists, 
                  pv_dsetin = dsetin, pv_varsin = byvars,
                  abortyn = Y);
  %end;
  /*--PV21 - BYSTYLE: Validated by %tu_cr8gbys*/
  /*--PV22 - TOPY : Validated by %tu_templates*/
  /*--PV23 - BOTY : Validated by %tu_templates*/
  /*--PV24 - FONT: validated by %tu_pagesetup*/
  /*--PV25 - PTSIZE: is numeric*/
  %tu_valparms(macroname= &macroname., chktype = isnum, pv_varsin = ptsize);

  /*--PV26 - GPTSIZE: should be numeric*/
  %tu_valparms(macroname= &macroname., chktype = isnum, 
                pv_varsin = gptsize, allowblankyn = Y);

  
  /*--PV27 - symbolcolor is character*/    
  /*--PV28 - symbolvalue is character*/    
  /*--PV30.1 - symbolinterpol character*/
  /*--PV32 - symbolotherdelim is character*/ 
  %tu_valparms(macroname= &macroname., chktype = ischar, 
   pv_varsin = symbolcolor symbolvalue symbolinterpol symbolotherdelim   );

  /*--PV29 - symbolline is between 1 and 46*/    
  %tu_valparms(macroname = &macroname. , chktype = isBetween,
                pv_varsin = symbolline, pv_var1 = 1 , pv_var2 = 46);

  /*--PV30.2 - warning if not hilocj - handled in np 13*/
  /*--PV31 - symbolother char - cannot use tu_valparms*/ 
  %if %datatyp(&symbolother) ne CHAR %then %do;
    %put RTE%STR(RROR): &macroname.: SYMBOLOTHER (&symbolother.) must be character;
    %let pv_abort = 1;
  %end;

  /*--PV33 - symbolmax between 1 and 100 */  
  %tu_valparms(macroname = &macroname. , chktype = isBetween,
                pv_varsin = symbolmax, pv_var1 = 1 , pv_var2 = 100);


  /*--PV36 - bars is one of sd range or none*/ 
  %tu_valparms(macroname = &macroname., chktype = isOneOf, pv_varsin = bars,
                valuelist = SD RANGE NONE);

  /*--PV37.2 - if gmmean = Y then yvar is numeric*/
  %if &gmmeanyn. = Y and %tu_chkvartype(dsetin = &dsetin., varin=&yvar_var.) = C %then %do;
    %put %str(RTE)RROR: &MACRONAME: if GMMEANYN = Y then YVAR (&yvar_var) must be numeric ;  
    %let pv_abort = 1;
  %end;

  /*--PV37.3 - if gmmean = Y and legendtype = across then error*/
  %if &gmmeanyn. = Y and &legendtype = ACROSS  %then %do;
    %put %str(RTE)RROR: &MACRONAME: if GMMEANYN = Y then LEGENDTYPE cannot be ACROSS - try INLINE or NONE ;  
    %let pv_abort = 1;
  %end;

  /*--PV37.4 - if gmmean = Y then zvar is populated*/
  %if &gmmeanyn. = Y and %length(&zvar_var.) = 0  %then %do;
    %put %str(RTE)RROR: &MACRONAME: if GMMEANYN = Y then ZVAR (&Zvar_var.) must populated ;  
    %let pv_abort = 1;
  %end;
 
  /*--PV38.1\2\3 - ymin if populated it is numeric and so is ymax and yint*/
  /*--PV39.1\2\3 - ymax if populated it is numeric and then so is ymin and yint */
  /*--PV40.1\2\3 - yint if populated it is numeric and then so is ymax and ymin */
  /*--PV41.1\2\3 - xmin if populated it is numeric and then so is xmax and xint */
  /*--PV42.1\2\3 - xmax if populated it is numeric and then so is xmin and xint */
  /*--PV43.\12\3 - xint if populated it is numeric and then so is xmax and xint */
  %if %cmpres(&ymin.\&ymax.\&yint.) ne \\ %then %do;
    /*check all are populated*/
    %local yflag; %let yflag = 0;
    %if %datatyp(&ymin.) = CHAR %then %let yflag = 1;
    %if %datatyp(&ymax.) = CHAR %then %let yflag = 1;
    %if %datatyp(&yint.) = CHAR %then %let yflag = 1;
    %if &yflag. = 1 %then %do;
      %put %str(RTE)RROR: &MACRONAME: If either one of ymin(&ymin.) , ymax(&ymax.) or yint(&yint.) is populated then all must be with a numeric value;  
      %let pv_abort = 1;
    %end;
    /*check that xvar is numeric if these macro vars have been populated*/
    %if %tu_chkvartype(dsetin = &dsetin., varin=&yvar_var.) ne N %then %do; 
      %put %str(RTE)RROR: &MACRONAME: If either one of ymin(&ymin.) , ymax(&ymax.) or yint(&yint.) is populated then the yvar (&yvar_var.) must be numeric ;  
      %let pv_abort = 1;
    %end;
  %end;
  %if %cmpres(&xmin.\&xmax.\&xint.) ne \\ %then %do;
    %local xflag; %let xflag = 0;
    %if %datatyp(&xmin.) = CHAR %then %let xflag = 1;
    %if %datatyp(&xmax.) = CHAR %then %let xflag = 1;
    %if %datatyp(&xint.) = CHAR %then %let xflag = 1;
    %if &xflag. = 1 %then %do;
      %put %str(RTE)RROR: &MACRONAME: If either one of xmin(&xmin.) , xmax(&xmax.) or xint(&xint.) is populated then all must be with a numeric value;  
      %let pv_abort = 1;
    %end;
    /*check that xvar is numeric if these macro vars have been populated*/
    %if %tu_chkvartype(dsetin = &dsetin., varin=&xvar_var.) ne N %then %do; 
      %put %str(RTE)RROR: &MACRONAME: If either one of xmin(&xmin.) , xmax(&xmax.) or xint(&xint.) is populated then the xvar (&xvar_var.) must be numeric ;  
      %let pv_abort = 1;
    %end;
  %end;

  /*--PV45.2 - if labelvarsyn=  Y and xlabel or ylabel is populated*/
  %if &labelvarsyn. = Y and %length(&xlabel.) gt 0  %then %do;
    %put RTW%str(ARNING): &macroname.: When labelvarsyn = Y and XLABEL is populated the value of XLABEL(&xlabel.) will prevail;
  %end;
  %if &labelvarsyn. = Y and %length(&ylabel.) gt 0  %then %do;
    %put RTW%str(ARNING): &macroname.: When labelvarsyn = Y and YLABEL is populated the value of YLABEL(&ylabel.) will prevail;
  %end;


  /*--PV46 - LABELSTYLE : IF LABELVARS = n THEN LABELSTYLE = [BLANK] */
  /*-- this has been removed as it should be handled by %tu_labelvars but comment remains*/
  /*   to keep numbering consistant*/

  /*--PV47 - FORMATS : none at present */
  /*--PV48 - Issue an error if trying to refresh footnotes */
   %if &g_analy_disp. ne A %then %do;
    %put RTE%str(RROR): &macroname: Refreshing of titles/footnotes is not permitted;
    %let pv_abort = 1;
  %end;
  /*--PV49 - Chack that dsetout is a valid sas name */
  %if %length(&dsetout.) gt 0 %then %do;
    %if %length(%tu_chknames(namesin=&dsetout., nametype=data)) gt 0 %then %do;
      %put RTE%str(RROR): &macroname: dsetout (&dsetout.) is not a valid sas name;
      %let pv_abort = 1;
    %end;
  %end;

  /*----------------------------------------------------------------------*/
  /*- complete parameter validation */
  %if %eval(&g_abort. + &pv_abort.) gt 0 %then %do;
    %put %str(RTE)RROR: &macroname: Macro has failed parameter validation check for reasons stated with %str(RTE)RRORs above;
    %tu_abort(option=force);
  %end;
  /*----------------------------------------------------------------------*/

  /*---------------------------------------------------------------------*/
  /*-- NP7 - Set default value for gptsize, if necessary */
  %if %length(&gptsize) eq 0 %then %do;
    %let gptsize = %eval(&ptsize*%substr(&layout,1,1));
  %end;
  
  /*----------------------------------------------------------------------*/
  /*-- NP8 - Call pagesetup to set basic goptions */
  %tu_pagesetup(mode   = secondary
               ,font   = &font
               ,ptsize = &ptsize
               ,device = &device
               );

  /*----------------------------------------------------------------------*/
  /*-- NP9 - Remove titles and footnotes */
  title;
  footnote;

  /*----------------------------------------------------------------------*/
  /*-- NP10 - Get data for selected population */ 
  %if &getdatayn eq Y %then %do;
    %tu_getdata(dsetin=&currentDataset
               ,dsetout1=work.&prefix._getdata
               );
    %let currentDataset = &prefix._getdata;
    %if %tu_nobs(&currentDataset.) le 0 %then %do;
      %tu_gnoreport(outfile=&outfile);
      %goto exit;
    %end;
  %end;

  /*----------------------------------------------------------------------*/
  /*--NP11 - Apply standard reporting labels */ 
  %if &labelvarsyn. eq Y %then %do;
    %tu_labelvars(dsetin=&currentDataset
                 ,dsetout=work.&prefix._labelvars
                 ,style=&varlabelstyle
                 );
    %let currentDataset = &prefix._labelvars;
  %end;

  /*----------------------------------------------------------------------*/
  /*--NP12 - remove any best22. formats inherited from dataset manager*/

  /* If format on Y var is best22, this is due to issue with 
  / IDSL/Dataset Manager, and it will result in much wasted 
  / space on graph, so set format to default.               
  /------------------------------------------------------*/
  %local chgfmt;
  data _null_;
    set &currentDataset;
    if upcase(vformat(&yvar_var)) eq: 'BEST22' then
    do;
      call symput('CHGFMT','Y');
    end;
    STOP;
  run;

  %if &chgfmt eq Y %then %do;
    %put RTN%str(OTE): &sysmacroname: Format of &yvar_var changed from IDSL/DSM default to SAS default;
     proc datasets lib=work nolist;
      modify &currentDataset;
          format &yvar_var ;
      quit;
  %end;

  /*----------------------------------------------------------------------*/
  /* NP 13 Generate SYMBOL statements */
    
  /*----------------------------------------------------------------------*/    
  /* NP 13.1 Begin with COLOR */
  %do i = 1 %to &symbolMax;
    %local symColor&i;
  %end;
  %tu_cr8macarray(string      = &symbolColor.
                 ,prefix      = symColor
                 ,numElements = &symbolMax.
                 );

  %if &g_debug ge 1 %then
    %do i = 1 %to &symbolMax;
      %put RTD%str(EBUG): &sysmacroname: SYMCOLOR&i=&&symColor&i;
    %end;

  /*----------------------------------------------------------------------*/
  /* NP 13.2 Now do VALUE */
  %do i = 1 %to &symbolMax;
    %local symValue&i;
  %end;
  %tu_cr8macarray(string      = &symbolValue
                 ,prefix      = symValue
                 ,numElements = &symbolMax
                 );

  %if &g_debug ge 1 %then
    %do i = 1 %to &symbolMax;
        %put RTD%str(EBUG): &sysmacroname: SYMVALUE&i=&&symValue&i;
      %end;

  /*----------------------------------------------------------------------*/
  /* np 13.3 Now do LINE */
  %do i = 1 %to &symbolMax;
    %local symLine&i;
  %end;
  %tu_cr8macarray(string      = &symbolLine
                 ,prefix      = symLine
                 ,numElements = &symbolMax
                 );

  %if &g_debug ge 1 %then
    %do i = 1 %to &symbolMax;
      %put RTD%str(EBUG): &sysmacroname: SYMLINE&i=&&symLine&i;
    %end;

  /*----------------------------------------------------------------------*/
  /* np 13.4 Now do INTERPOL */
  %if (&style eq MEAN) 
      and (&bars eq SD or &bars eq RANGE) 
      and %upcase(&symbolInterpol) ne HILOCJ %then %do;
    %put RTW%str(ARNING): &sysmacroname: For STYLE=&style with BARS=&bars, the use of SYMBOLINTERPOL=HILOCJ is highly recommended. Current setting is &symbolInterpol;
  %end;

  %do i = 1 %to &symbolMax;
    %local symInterpol&i;
  %end;
  %tu_cr8macarray(string      = &symbolInterpol
                 ,prefix      = symInterpol
                 ,numElements = &symbolMax
                 );

  %if &g_debug ge 1 %then
    %do i = 1 %to &symbolMax;
      %put RTD%str(EBUG): &sysmacroname: SYMINTERPOL&i=&&symInterpol&i;
    %end;

  /*----------------------------------------------------------------------*/
  /* NP 13.5 Finally, do OTHER */
  %do i = 1 %to &symbolMax;
    %local symOther&i;
  %end;
  %tu_cr8macarray(string      = &symbolOther
                 ,prefix      = symOther
                 ,numElements = &symbolMax
                 ,delim       = &symbolOtherDelim
                 );

  %if &g_debug ge 1 %then
    %do i = 1 %to &symbolMax;
      %put RTD%str(EBUG): &sysmacroname: SYMOTHER&i=&&symOther&i;
    %end;

  /*----------------------------------------------------------------------*/
  /* Finish by generating the symbol statements */
    %do i = 1 %to &symbolMax;
      SYMBOL&i 
        %if %length(&&symColor&i)    gt 0 %then COLOR=&&symColor&i;
        %if %length(&&symValue&i)    gt 0 %then VALUE=&&symValue&i;
        %if %length(&&symLine&i)     gt 0 %then LINE=&&symLine&i;
        %if %length(&&symInterpol&i) gt 0 %then INTERPOL=&&symInterpol&i;
        %if %length(&&symOther&i)    gt 0 %then &&symOther&i;
        ;
    %end;
  /*----------------------------------------------------------------------*/
  /*-- NP 14 - Sort data data by the byvars*/
  %if %length(&byvars.) gt 0 %then %do;
    proc sort data = &currentdataset out = work.&prefix._sorteddata;
      by &byvars.;
    run;
    %let currentdataset = work.&prefix._sorteddata;
  %end;

  /*----------------------------------------------------------------------*/
  /*--NP 15 - Calculate mean if we need it */
  %if &style eq MEAN %then %do;  
    proc summary data=&currentDataset nway;
      class &zvar_var &xvar_var &BYVARS. / missing;
      var &yvar_var;
      id  &zvarordervar &xvarordervar.;
      output out=work.&prefix._regularDsetin  %if &g_debug eq 0 %then %do;
                                                 (drop=_type_ _freq_)
                                               %end;
               &style=
               %if &bars eq SD %then %do;
                 std=std
               %end;
               %else %do;
                 %if &bars eq RANGE %then %do;
                   min=min max=max;
                 %end;
               %end;
               ;
    run;
    
    %let currentDataset = &prefix._regularDsetin;

    /*----------------------------------------------------------------------*/
    /*NP 15.1 - if the bars are standard deviation then calculate*/
    %if &bars eq SD %then %do;
      /*
      / We want to use I=HILOCJ on the SYMBOL statement for 
      / the GPLOT. That requires three Y values for each X. 
      / We want mean+sd, mean-sd,   
      / so we set min equal to mean.                        
      /------------------------------------------------------*/
      data work.&prefix._regularDsetin0;
        set &currentDataset;
        drop std;
        min = &yvar_var - std ; 
        max = &yvar_var + std;
      run;
      %let currentDataset = &prefix._regularDsetin0;
    %end; /* end- bars = sd*/
      
    /*----------------------------------------------------------------------*/
    /*NP 15.2 - if the bars are a range or the standard deviation then process*/
    %if &bars. eq RANGE or &bars. eq SD %then %do;  

      /* We will transpose the data to get MIN, MAX, and YVAR on 
      / separate rows. */
      proc sort data = &currentdataset. out = &prefix._dataToTranspose;
        by &byvars. &xvar_var. &zvar_var.;
      run;
      %let currentdataset = &prefix._dataToTranspose;

      proc transpose data=&currentdataset. 
       out=work.&prefix._regularDsetinx (rename=(col1=&yvar_var.) drop=_name_ _label_ );
        by &byvars. &xvar_var. &Zvar_var.;
        var &yvar_var. min max;
      run;
      %let currentDataset = &prefix._regularDsetinx;
      proc sort; by &byvars. &xvar_var. &zvarordervar. &zvar_var.; run;

    %end; /* bars or sd */
  %end; /* end - style is mean */

  /*----------------------------------------------------------------------*/
  /*-- NP 16 - calculate the geometric mean if required  */
  %if &gmmeanyn. = Y %then %do;
    %if &g_debug eq 0 %then %put RTDEBUG: &sysmacroname.: Calculating Geometric mean;

    /*-- need to get the minimum value of the zvar so that geometric mean is */
    /*   always first*/
    %local min_zvar;
    %if %tu_chkvartype(dsetin = &currentdataset.,varin = &zvar_var.) = N %then %do;
      /*if a numeric zvar_var then create a new one -100*/
      proc sql noprint;
        select min(&zvar_var.)-100 into :min_zvar
        from &currentdataset.
        where &zvar_var ne .;
      quit;
    %end;
    %else %if %tu_chkvartype(dsetin = &currentdataset.,varin = &zvar_var.) = C %then %do;
      /*- create a character var the same length as the original*/
      /*- the [blank] character has the lowest char sort order is first
          but we cannot use that due to other issues so need to use ! */
      %let min_zvar = "!";
      /*--Check that we do not already have blank values for &zvar_var*/
      %local num_blank_zvar_var;
      proc sql noprint;
        select count(*) into :num_blank_zvar_var
        from &currentdataset.
        where compress(&zvar_var.) in (&min_zvar., '');
      quit;
      %if &g_debug. gt 0 %then %do;
        %put RTD%str(EBUG): &sysmacroname.: The value of num_blank_zvar_var is &num_blank_zvar_var.;
      %end;

      %if &num_blank_zvar_var. gt 0 %then %do;
        %put RTE%str(RROR): &Sysmacroname.: The zvar (&zvar_var) contains &min_zvar. or blank values - geometric mean cannot be displayed on the graph, ensure all values of &zvar_var. are populated;
        %let g_abort = 1;
        %tu_abort;
      %end;
    %end;
    %if &g_debug gt 0 %then %do;
      %put RTD%str(EBUG): &sysmacroname.: The value of min_zvar is &min_zvar.;
    %end;

    proc sql noprint;
      create table &prefix._gmmean1 as
      select  &min_zvar. as &zvar_Var, 
              %if %length(&byvars.) gt 0 %then %tu_sqlnlist(&byvars.), ;
              %if %length(&xvarordervar.) gt 0 %then &xvarordervar., ;
              &xvar_var.,

              exp(mean(log(&yvar_var.))) as &yvar_var.
      from &currentdataset.
      group by %if %length(&byvars.) gt 0 %then %tu_sqlnlist(&byvars.), ;
               %if %length(&xvarordervar.) gt 0 %then &xvarordervar., ;
               &xvar_var.;
    quit;

    /*-- set the data back together so that we have the mean*/
    data &prefix._gmmean2;
      set &currentdataset. &prefix._gmmean1;
    run;
    proc sort; by &byvars. &xvar_var. &zvarordervar. &zvar_var.; run;

    %let currentdataset = &prefix._gmmean2;
  %end; /*-- end - gmmeanyn*/

  /*----------------------------------------------------------------------*/
  /*-- NP 17 - Deal with the xvar and zvar ordering */

  /*----------------------------------------------------------------------*/
  /*-- NP 17.1 - if there is a variable controlling the xvar order*/
  %if &xvarordervar. ne %then %do;
    %local xvaraxisorder;
    /*-- need to create a string of the distinct values of the variable*/
    /*   This is also dependant on the type of xvar variable */
     proc sql noprint;
       create table &prefix._distinctxvars as
       select distinct &xvar_var., &xvarordervar.
          from &currentDataset
          order &xvarordervar.;
     quit;

    /*-- create macro var holding the string */
    data _null_;
      set &prefix._distinctxvars end=finish;
      retain string;
      length string $4096;
      /* -- build the character or numeric string */
      %if %tu_chkvartype(&prefix._distinctxvars, &xvar_var.) = C %then %do;
        string = trim(string) !! ' ' !! quote(trim(&xvar_var.));
      %end;
      %else %if %tu_chkvartype(&prefix._distinctxvars, &xvar_var.) = N %then %do;
        string = trim(string) !! trim(put(&xvar_var.,best.));
      %end;
      if finish then
        call symput("XVARaxisORDER",left(trim(string)));
    run;
  %end; /*end- xvarordevar ne */
  /*-- NP 17.2 - if we have an xvarorder var then just use it*/
  %else %if %length(&xvarorder.) gt 0 %then %let xvaraxisorder = &xvarorder.;
  %else %let xvaraxisorder = ;
 
  /*----------------------------------------------------------------------*/
  /*--PV17.3 - Deal with the ordering of the zvar - this will become the legendorder*/
  %if &zvarordervar. ne %then %do;
    %local legendorder;
    /*-- need to create a string of the distinct values of the variable*/
    /*   This is also dependant on the type of zvar variable */
     proc sql noprint;
       create table &prefix._distinctzvars as
       select distinct &zvar_var., &zvarordervar.
          from &currentDataset
          order &zvarordervar.;
     quit;

    /*-- create macro var holding the string */
    data _null_;
      set &prefix._distinctzvars end=finish;
      retain string;
      length string $4096;
      /* -- build the character or numeric string */
      %if %tu_chkvartype(&prefix._distinctzvars, &zvar_var.) = C %then %do;
        string = trim(string) !! ' ' !! quote(trim(&zvar_var.));
      %end;
      %else %if %tu_chkvartype(&prefix._distinctzvars, &zvar_var.) = N %then %do;
        string = trim(string) !! trim(put(&zvar_var.,best.));
      %end;
      if finish then
        call symput("legendorder",left(trim(string)));
    run;
    %if g_debug gt 0 %then %put RTDEBUG: &sysmacroname.: The value of legendorder is &legendorder.;
  %end; /*end- zvarordevar ne */
  %else %let legendorder = ;

  /*--PV6.2 check that there is at least one non missing xvar */
  %local nonmissxvar;
  proc sql noprint;
    select count(*) into :nonmissxvar
    from &currentdataset.
    %if %tu_chkvartype(dsetin = &dsetin., varin = &xvar_var.) = N %then %do;
      where &xvar_var. ne . ;
    %end;
    %else %do;
      where compress(&xvar_var.) ne '' ;
    %end;
  quit;
  
  %if &nonmissxvar. = 0 %then %do;
    %put %str(RTE)RROR: &macroname: The XVAR (&xvar_var.) does not have any non missing values;
    %let g_abort = 1;
    %tu_abort;
  %end;

  /*----------------------------------------------------------------------*/
  /*-- NP 18 - create the axis */
  /*--axis 1 = vertical axis;  */
  /*set up y axis*/
  /*JMCG.01.003.01 - add catch all to axis statement*/
  axis1  
   %if %length(&ymin.) gt 0 %then order=(&ymin. to &ymax. by &yint.); 
    %if %nrbquote(%upcase(&ylabel.)) = NONE %then label=none ;
    %else %if &ylabel. ne  %then label=(angle = 90 "&ylabel.");
    %else %if &ylabel. = and &labelvarsyn. = Y %then label = (angle=90);
    %else label = (angle=0);
  ;
  /*y-axis for log graphs*/
  axis3 logbase=&ylogbase logstyle=&ylogstyle  
    %if %nrbquote(%upcase(&ylabel.)) = NONE %then LABEL = none;
    %else %if &ylabel. ne %then LABEL = (angle = 90 "&ylabel.");
    %else %if &ylabel. = and &labelvarsyn. = Y %then label = (angle=90);
    %else label = (angle=0);
  ;

  /*-- set up x axis for linear */
  %if &g_debug ge 1 %then %put RTD%str(EBUG): &sysmacroname: XVARaxisORDER=&xvaraxisOrder.;;
  axis2 
   %if %length(&xvaraxisorder.) gt 0 %then %do;
     order=( %unquote(&xvaraxisorder.))
   %end;
   %else %if %length(&xmin.) gt 0 %then order=(&xmin. to &xmax. by &xint.);
   %if %nrbquote(%upcase(&xlabel.)) = NONE  %then LABEL = none;
   %else %if &xlabel. ne  %then LABEL = (angle = 0  "&xlabel.");
   %else %if &xlabel. = and &labelvarsyn. = Y %then label = (angle=0); 
   %else label = (angle=0);
  ; 
  /*-- set up x axis for log */
  %if &g_debug ge 1 %then %put RTD%str(EBUG): &sysmacroname: XVARaxisORDER=&xvaraxisOrder.;;
  axis4 
   %if &xvarlogyn. = Y %then logbase=&ylogbase. logstyle=&ylogstyle.;  
   %else %if %length(&xvaraxisorder.) gt 0 %then %do;
     order=( %unquote(&xvaraxisorder.))
   %end;
   %else %if %length(&xmin.) gt 0 %then order=(&xmin. to &xmax. by &xint.);
   %if %nrbquote(%upcase(&xlabel.))= NONE  %then LABEL = none;
   %else %if &xlabel. ne  %then LABEL = (angle = 0  "&xlabel.");
   %else %if &xlabel. = and &labelvarsyn. = Y %then label = (angle=0); 
   %else label = (angle=0);
  ; 

  /*----------------------------------------------------------------------*/
  /*-- NP19 - create the graphs*/
  /*-- if dsetout has been selected the create an output dataset*/
  /*ensure the data is correctly sorted*/
  proc sort data = &currentdataset.;
    by &byvars. &xvar_var. &zvarordervar. &zvar_var.; 
  run;

  %if %length(&dsetout.) gt 0 %then %do;
    data &dsetout.;
      set &currentdataset.;
    run;
  %end;
  /*----------------------------------------------------------------------*/
  /*--NP19.1 check that we have data to graph - if not run %tu_gnoreport*/
  %if %tu_nobs(&currentdataset.) gt 0 %then %do;
    /*----------------------------------------------------------------------*/
    /*-- NP19.2 remove any existing linear graph catalogs*/
    /*  remove any existing catalog*/
    %if %sysfunc(exist(work.&prefix._lin,catalog)) %then %do;
      proc catalog c=work.&prefix._lin kill;
      quit;
    %end;
    /*----------------------------------------------------------------------*/
    /*  np19.3  Create linear graphs into catlg WORK.LIN. */
    %if %sysfunc(indexw(&figtype,LINEAR)) %then %do;  /* Create linear graphs */
    
      /*----------------------------------------------------------------------*/
      /*-- NP19.3.1 - setup graphics options and graphics*/
      goptions nodisplay htext=&gptsize.pt;
      options nobyline;
      title1 h=&gptsize.pt "Linear Scale";
      legend1 frame %if &legendLabel eq N %then label=none ;
                    %if &legendorder. ne %then order = (&legendorder.); 
                    %if &gmmeanyn = Y %then value=(tick=1 'Geo. Mean');
      ;
      
      /*----------------------------------------------------------------------*/
      /*--NP 19.3.2 - Now actually create the graphs*/
      proc gplot 
       data=&currentDataset 
       gout=work.&prefix._lin
       %if &style. eq INDIVIDUAL %then uniform;;
        %if %length(&byvars.) gt 0 %then by &byvars.;;
        plot &yvar_var*&xvar_var %if &Zvar. ne  %then =&Zvar_var;
               / vaxis = axis1 haxis = axis2               
               %if &legendtype eq INLINE %then %do;
                 legend=legend1
               %end;
               %else %do;
                 nolegend
               %end;
                %if %length(&vref.) gt 0 %then vref = &vref.;
                %if %length(&href.) gt 0 %then href = %unquote(&href.);
              ;
   
          %if %length(&formats) gt 0 %then
          %do;
            format &formats;
          %end;
        run;
      quit;
      options byline;
      goptions display;
      /*----------------------------------------------------------------------*/
    %end; /* end- Create linear graphs */

    /*----------------------------------------------------------------------*/   
    /*-- np 19.4 remove any existing graph log catalogs*/
    %if %sysfunc(exist(work.&prefix._log,catalog)) %then %do;
      proc catalog c=work.&prefix._log kill;
      quit;
    %end;

    /*----------------------------------------------------------------------*/  
    /* NP 19.5 - Create log graphs into catlg WORK.LOG. */
    %if %sysfunc(indexw(&figtype,LOG)) %then %do;  /* Create log graphs */

      /*----------------------------------------------------------------------*/
      /*-- nop 19.5.1 set up the graphics options for log graphs*/
      goptions nodisplay htext=&gptsize.pt;
      options nobyline;
      title1 h=&gptsize.pt %if &xvarlogyn. = N %then "Semi-Logarithmic Scale";
                           %else "Logarithmic Scale";;
      /*----------------------------------------------------------------------*/
      /*--PV3.3 - FIGTYPE: There are no negative values on yvar*/
      %local minyvar;
      proc sql noprint;
        select min(&yvar_var.) into :minyvar
        from &currentdataset.
        where &yvar_var. ne . ;
      quit;
      %if &g_debug. gt 0 %then %put RTDEBUG: &macroname.: The minimum value of yvar (&yvar_var.) is &minyvar.;
      %if %length(&minyvar.) = 0 %then %do;
        %put %str(RTE)RROR: &macroname: The YVAR does not have any non missing values;
        %let g_abort = 1;
        %tu_abort;
      %end;
      %else %if %sysevalf(&minyvar lt 0) %then %do;
        %put %str(RTE)RROR: &macroname: The YVAR (&yvar_var.) has values below zero;
        %let g_abort = 1;
        %tu_abort;
      %end;
 
      /*----------------------------------------------------------------------*/
      /*-- np 19.5.2 - plot the data*/
      proc gplot data=&currentdataset.
                 gout=work.&prefix._log
                 %if &style. eq INDIVIDUAL %then uniform;
                 ;
        %if %length(&byvars.) gt 0 %then by &byvars.;;
        plot &yvar_var*&xvar_var %if &Zvar. ne %then =&Zvar_var. ;
                / vaxis = axis3
                  haxis = axis4
                %if &legendtype eq INLINE %then %do;
                  legend=legend1
                %end;
                %else %do;
                  nolegend
                %end;
                %if %length(&vref.) gt 0 %then vref = &vref.;
                %if %length(&href.) gt 0 %then href = %unquote(&href.);
                ;
          %if %length(&formats) gt 0 %then
          %do;
            format &formats;
          %end;
        run;
      quit;
      options byline;
      goptions display;
      /*----------------------------------------------------------------------*/      
    %end; /*-- end- Create log graphs */

    /*----------------------------------------------------------------------*/
    /* NP 19.6 Reset any goptions that we've changed, e.g. font */
    %tu_pagesetup(mode=secondary ,font=&font,ptsize=&ptsize,device=&device);

    /*----------------------------------------------------------------------*/
    /* NP 19.7 Create head/foot slides into catlg WORK.HF */
    goptions nodisplay;
    %tu_cr8gheadfoots(gout    = work.&prefix._hf
                     ,kill    = y
                     %if %sysfunc(indexw(&figtype,LINEAR)) %then ,pagecat = work.&prefix._lin ;
                     %else ,pagecat = work.&prefix._log ;
                     ,font    = &font
                     ,ptsize  = &ptsize
                     );
    goptions display;

    /*----------------------------------------------------------------------*/
    /*--NP 19.8 Create BY slides into catlg WORK.BY */
    %if %length(&byvars) gt 0 %then %do;
      goptions nodisplay;
      %tu_cr8gbys(gout=work.&prefix._by
                 ,kill=y
                 ,dsetin=&currentDataset
                 ,byvars=&byvars
                 ,style=&bystyle
                );
      goptions display;
    %end;

    /*----------------------------------------------------------------------*/
    /*--NP 19.9 -  Create legend slide as work.gseg.legend.gseg */
    %if &legendtype eq ACROSS %then %do;
      /*
      / Note. The symbols used to produce the graphs must still 
      /       be in action at this point, else the legend will  
      /       not match the graphs.                             
      /------------------------------------------------------*/
      goptions nodisplay;

      /*-- Apply any formats to the legend dataset so that the formatted
      /    values appear in the legend */
      data work.&prefix._legdset;
        set &currentdataset.;
        %if %length(&formats) gt 0 %then %do;
          format &formats;
        %end;
      run;

      %tu_cr8glegend(gout=work.&prefix._legend
                    ,goutent=legend
                    ,kill=y
                    ,legendlabel=&legendLabel
                    ,dsetin=work.&prefix._legdset
                    ,xvar=&xvar_var
                    ,yvar=&yvar_var
                    %if %length(&zvar.) gt 0 %then ,zvar=&Zvar_var.;
                    %if &legendorder. ne %then   ,ordermvar = legendorder ;
                    );
      goptions display;
    %end;

    /*----------------------------------------------------------------------*/
    /*--NP 19.10 Call templates macro to put it all together */

    /*
    / Firstly, make sure we request graphs in the right 
    / order, i.e. log/linear or linear/log (though the  
    / latter is currently invalid).                     
    /------------------------------------------------------*/
    %local graffcats thisType thisWordPtr;
    %let thisWordPtr = 1;
    %let thisType = %scan(&figtype,&thisWordPtr);
    %do %while (%length(&thisType) gt 0);
      %if &thisType eq LOG %then %let graffcats = &graffcats work.&prefix._log;
      %else %if &thisType eq LINEAR %then %let graffcats = &graffcats work.&prefix._lin;
      %else %do;
        %put RTE%str(RROR): &sysmacroname: Invalid value for FIGTYPE parameter (&figtype);
        %let g_abort = 1;
      %end;
      %let thisWordPtr = %eval(&thisWordPtr + 1);
      %let thisType = %scan(&figtype,&thisWordPtr);
    %end; /* loop over words in figtype */

    %tu_templates(graphcats=&graffcats
                 ,hfcat=work.&prefix._hf
                 ,layout=&layout
                 ,topy=&topy
                 ,boty=&boty
                 ,outfile=&outfile
                 ,framePage=&framePage
                 ,framePlot=&framePlot
                 %if %length(&byvars.) gt 0 %then %do;
                   ,bycat=work.&prefix._by
                 %end;
                 %if &legendtype eq ACROSS %then %do;
                   ,legend=work.&prefix._legend.legend.grseg
                 %end;
                 );

    /*----------------------------------------------------------------------*/
    /* np 19.11 Delete temporary data items used in this macro. */
    %if &g_debug le 8 %then    %do;
      proc datasets lib=work nolist;
        delete &prefix: / mt=catalog;
      quit;
    %end;
  %end; /*-- end- %tu_nobs gt 0 */
  %else %do;
    /*----------------------------------------------------------------------*/
    /*-- NP 19.1 - if there is no data then produce a report*/
    %tu_gnoreport();
  %end;
  %exit:  
  /*----------------------------------------------------------------------*/
  /*--NP20 - Tidy up and call tu_abort   */
  %tu_tidyup(rmdset=&prefix:, glbmac=NONE);
  %tu_abort;

%mend;
