/*******************************************************************************
|
| Macro Name:      td_pkcf2
|
| Macro Version:   1
|
| SAS Version:     9
|                                                             
| Created By:      Warwick Benger
|
| Date:            28-Nov-2009
|
| Macro Purpose:   To create standard: Mean [Analyte] [Matrix] Concentration-Time Plots (Linear and Semi-log)
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME             DESCRIPTION                                       DEFAULT
| --------------   -----------------------------------               --------------
| dsetin           Passed as %tu_pktfig parameter of the same name   ardata.PKCNC
| figtype          Passed as %tu_pktfig parameter of the same name   LINEAR LOG
| style            Passed as %tu_pktfig parameter of the same name   MEAN
| bars             Passed as %tu_pktfig parameter of the same name   NONE
| postsubset       Passed as %tu_pktfig parameter of the same name   [blank]
|
| xvar             Passed as %tu_pktfig parameter of the same name   eltmstn eltmstu
| xmin             Passed as %tu_pktfig parameter of the same name   0
| xmax             Passed as %tu_pktfig parameter of the same name   [blank]
| xint             Passed as %tu_pktfig parameter of the same name   [blank]
| xrange           Passed as %tu_pktfig parameter of the same name   ALL
| xlabel           Passed as %tu_pktfig parameter of the same name   Planned Relative Time (units)
| xref             Passed as %tu_pktfig parameter HREF               [blank]
|
| yvar             Passed as %tu_pktfig parameter of the same name   pcstimpn pcstresu
| ymin             Passed as %tu_pktfig parameter of the same name   0
| ymax             Passed as %tu_pktfig parameter of the same name   [blank]
| yint             Passed as %tu_pktfig parameter of the same name   [blank]
| yrange           Passed as %tu_pktfig parameter of the same name   ALL
| ylabel           Passed as %tu_pktfig parameter of the same name   Concentration (units)
| yref             Passed as %tu_pktfig parameter VREF               [blank]
| ylogminbasis     Passed as %tu_pktfig parameter of the same name   LLQ
|
| byvars           Passed as %tu_pktfig parameter of the same name   [blank]
| zvar             Passed as %tu_pktfig parameter of the same name   &g_trtgrp=&g_trtcd
| zrepeatvar       Passed as %tu_pktfig parameter of the same name   [blank]
| legendyn         Passed as %tu_pktfig parameter of the same name   Y
| legendlabel      Passed as %tu_pktfig parameter of the same name   Y
| frameAxes        Passed as %tu_pktfig parameter of the same name   Y
| llqline          Passed as %tu_pktfig parameter of the same name   Y
| formats          Passed as %tu_pktfig parameter of the same name   eltmstn pcstimpn best6.
|
| topy             Passed as %tu_pktfig parameter of the same name   95
| boty             Passed as %tu_pktfig parameter of the same name   5
| ptsize           Passed as %tu_pktfig parameter of the same name   10
|
| symbolColor      Passed as %tu_pktfig parameter of the same name   black
| symbolValue      Passed as %tu_pktfig parameter of the same name   diamond plus square X triangle star - hash _ dot circle : A B C D E F G H
| symbolLine       Passed as %tu_pktfig parameter of the same name   1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24
| symbolInterpol   Passed as %tu_pktfig parameter of the same name   join
|
| Output: Graphics file containing conc vs time graphs
|
| Global macro variables created: NONE
|
| Macros called:
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_pktfig
|
*******************************************************************************/

%macro td_pkcf2(
   dsetin=ardata.PKCNC                          /* type:ID Input dataset                  */
  ,figtype = LINEAR LOG                         /* Plot Type (Linear, log, Linear log)    */
  ,style = MEAN                                 /* Graph type (individual/mean/median/spaghetti) */    
  ,bars = NONE                                  /* Bars to be applied to graph            */
  ,postsubset =                                 /* Subset data prior to plotting?         */
  ,xvar=eltmstn eltmstu                         /* X-axis and (optional) units            */
  ,xmin = 0                                     /* X-axis lower limit (blank = auto)      */
  ,xmax =                                       /* X-axis upper limit (blank = auto)      */
  ,xint =                                       /* X-axis interval (blank = auto)         */
  ,xrange = ALL                                 /* X-axis automatic ranging same for all pages (ALL) or per BYVAR (BY) */
  ,xlabel = Planned Relative Time (units)       /* X-axis label                           */
  ,xref =                                       /* X-axis reference line                  */
  ,yvar=pcstimpn pcstresu                       /* Y-axis and (optional) units            */
  ,ymin = 0                                     /* Y-axis lower limit (blank = auto)      */
  ,ymax =                                       /* Y-axis upper limit (blank = auto)      */
  ,yint =                                       /* Y-axis interval (blank = auto)         */
  ,yrange = ALL                                 /* Y-axis automatic ranging same for all pages (ALL) or per BYVAR (BY) */
  ,ylogminbasis = LLQ                           /* Y-axis log minimum basis if ymin is missing or <= 0 */
  ,ylabel = Concentration (units)               /* Y-axis Label                           */
  ,yref =                                       /* Y-axis reference line                  */
  ,byvars =                                     /* By variables (i.e. page)               */
  ,zvar = &g_trtgrp=&g_trtcd                    /* 3rd Classification var (i.e. line)     */
  ,zrepeatvar =                                 /* Vars across which to repeat ZVAR       */
  ,legendyn = Y                                 /* Switch On/off Legend (Y/N)             */
  ,legendlabel = Y                              /* Switch On/off Legend label (Y/N)       */
  ,frameAxes = Y                                /* Include right and top axis lines?      */
  ,llqline = Y                                  /* LLQ line required? (Y/N/L/C/R)         */
  ,formats = eltmstn pcstimpn best6.            /* Formats to be applied to plot axes     */
  ,topy = 95                                    /* Specifies % plot area for top          */
  ,boty = 5                                     /* Specifies % plot area for bottom       */
  ,ptsize = 10                                  /* Point size for titles/footnotes        */
  ,symbolColor = black                          /* Colours for symbol statements          */
  ,symbolValue = diamond plus square X triangle star - hash _ dot circle : A B C D E F G H /* Symbols for symbol stmts */
  ,symbolLine = 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20 21 22 23 24 /* Lines for symbol stmts                 */
  ,symbolInterpol = join                        /* Interpolations for symbol stmts        */
  );

  /* Echo parameter values and global macro variables to the log */
 
  %local MacroVersion;
  %let MacroVersion = 1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals();

  /* Call the package macro */
                   
  %tu_pktfig(
   dsetin = &dsetin
  ,figtype = &figtype
  ,style = &style
  ,bars = &bars
  ,postsubset=&postsubset

  ,xvar = &xvar
  ,xmin = &xmin
  ,xmax = &xmax
  ,xint = &xint
  ,xrange = &xrange
  ,xlabel = &xlabel
  ,href = &xref

  ,yvar = &yvar
  ,ylabel = &ylabel
  ,ymin = &ymin
  ,ymax = &ymax
  ,yint = &yint
  ,yrange = &yrange
  ,ylogminbasis = &ylogminbasis
  ,vref = &yref

  ,byvars = &byvars
  ,zvar = &zvar
  ,zrepeatvar = &zrepeatvar
  ,legendyn = &legendyn
  ,legendlabel = &legendlabel
  ,frameAxes = &frameAxes
  ,llqline = &llqline
  ,formats = &formats

  ,topy = &topy
  ,boty = &boty
  ,ptsize = &ptsize
  ,gptsize = 

  ,symbolColor = &symbolcolor
  ,symbolValue = &symbolvalue
  ,symbolLine = &symbolline
  ,symbolInterpol = &symbolinterpol
  ,symbolOther = 
  ,symbolOtherDelim = /

  ,varlabelstyle = STD
  ,bystyle = label-equals-comma
  ,ylogbase = 10
  ,ylogstyle = EXPAND
  );
                 
%mend td_pkcf2;
