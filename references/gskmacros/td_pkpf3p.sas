/* ******************************************************************************
|
| Macro Name:      td_pkpf3p
|
| Macro Version:   1
|
| SAS Version:     8.2
|
| Created By:      Trevor Welby
|
| Date:            21-Jun-2005
|
| Macro Purpose:   Wrapper to Create Graphs of: Comparative Plot for [Matrix] [Analyte] [Parameter]
|                  Linear and Semi-Logarithmic Axes [Parallel Group Study]
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME             DESCRIPTION                                       DEFAULT
| --------------   -----------------------------------               --------------
| bars             Passed as %tu_pkcfig parameter of the same name   NONE
| boty             Passed as %tu_pkcfig parameter of the same name   5
| bystyle          Passed as %tu_pkcfig parameter of the same name   label-equals-comma
| byvars           Passed as %tu_pkcfig parameter of the same name   [blank]
| device           Passed as %tu_pkcfig parameter of the same name   &g_textfilesfx
| dsetin           Passed as %tu_pkcfig parameter of the same name   ardata.pkpar
| figtype          Passed as %tu_pkcfig parameter of the same name   Linear log
| font             Passed as %tu_pkcfig parameter of the same name   SWISS
| formats          Passed as %tu_pkcfig parameter of the same name   [blank]
| framepage        Passed as %tu_pkcfig parameter of the same name   N
| frameplot        Passed as %tu_pkcfig parameter of the same name   N
| gmmeanyn         Passed as %tu_pkcfig parameter of the same name   N
| gptsize          Passed as %tu_pkcfig parameter of the same name   [blank]
| href             Passed as %tu_pkcfig parameter of the same name   [blank]
| layout           Passed as %tu_pkcfig parameter of the same name   2up
| legendlabel      Passed as %tu_pkcfig parameter of the same name   N
| legendtype       Passed as %tu_pkcfig parameter of the same name   NONE
| outfile          Passed as %tu_pkcfig parameter of the same name   &g_outfile..&g_textfilesfx
| ptsize           Passed as %tu_pkcfig parameter of the same name   10
| style            Passed as %tu_pkcfig parameter of the same name   INDIVIDUAL
| symbolColor      Passed as %tu_pkcfig parameter of the same name   black
| symbolInterpol   Passed as %tu_pkcfig parameter of the same name   join
| symbolLine       Passed as %tu_pkcfig parameter of the same name   1
| symbolMax        Passed as %tu_pkcfig parameter of the same name   24
| symbolOther      Passed as %tu_pkcfig parameter of the same name   [blank]
| symbolOtherDelim Passed as %tu_pkcfig parameter of the same name   /
| symbolValue      Passed as %tu_pkcfig parameter of the same name   dot
| topy             Passed as %tu_pkcfig parameter of the same name   95
| varlabelstyle    Passed as %tu_pkcfig parameter of the same name   STD
| vref             Passed as %tu_pkcfig parameter of the same name   [blank]
| xint             Passed as %tu_pkcfig parameter of the same name   [blank]
| xlabel           Passed as %tu_pkcfig parameter of the same name   NONE
| xmax             Passed as %tu_pkcfig parameter of the same name   [blank]
| xvar             Passed as %tu_pkcfig parameter of the same name   visit=visitnum
| xvarlogyn        Passed as %tu_pkcfig parameter of the same name   N
| xvarorder        Passed as %tu_pkcfig parameter of the same name   [blank]
| yint             Passed as %tu_pkcfig parameter of the same name   [blank]
| ylabel           Passed as %tu_pkcfig parameter of the same name   [blank]
| ylogbase         Passed as %tu_pkcfig parameter of the same name   10
| ylogstyle        Passed as %tu_pkcfig parameter of the same name   Expand
| ymax             Passed as %tu_pkcfig parameter of the same name   [blank]
| ymin             Passed as %tu_pkcfig parameter of the same name   [blank]
| yvar             Passed as %tu_pkcfig parameter of the same name   pporresn 
| zvar             Passed as %tu_pkcfig parameter of the same name   &g_subjid
|
| Output: Graphics file containing : PK Parameter Vs Dose
|
| Global macro variables created: NONE
|
| Macros called:
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_pkcfig
|
| Example:
|   %td_pkpf1p()
|
|******************************************************************************
| Change Log
|
| Modified By:
| Date of Modification:
| New version/draft number:
| Modification ID:
| Reason For Modification:
|
****************************************************************************** */
%macro td_pkpf3p(bars=none  /* Bars to be applied to graph */
                ,boty=5  /* Specifies the lowest point of y (%) */
                ,bystyle=label-equals-comma  /* Style of the by line */
                ,byvars=  /* Variables for by vars */
                ,device=&g_textfilesfx.  /* Goptions Device */
                ,dsetin=ardata.pkpar  /* type:ID Input dataset */
                ,figtype=Linear Log  /* Plot Type(Linear, log, Linear log) */
                ,font=swiss  /* Specifies the font for %tu_pagesetup */
                ,formats=  /* Formats to be applied in the plot */
                ,framePage=N  /* Place frame around page? */
                ,framePlot=N  /* Place frame around plot(s)? */
                ,gmmeanyn=N  /* Add Geometric Mean */
                ,gptsize=  /* Specifies the point size for graphs */
                ,href=  /* Horizontal reference line value */
                ,layout=2up  /* Plot Layout (2up or 1up) */
                ,legendlabel=N  /* Switch On/Off Legend label (Y/N) */
                ,legendtype=NONE  /* The type of legend (ACROSS, INLINE, NONE) */
                ,outfile=&g_outfile..&g_textfilesfx.  /* Name of output file */
                ,ptsize=10  /* Specifies the point size for %tu_pagesetup */
                ,style=individual  /* Type of graph (mean, individual, etc) */
                ,symbolColor=black  /* Colours for symbol statements */
                ,symbolInterpol=join  /* Interpolations for symbol statements */
                ,symbolLine=1  /* Lines for symbol statements */
                ,symbolMax=24 /* Number of SYMBOL statements */
                ,symbolOther=  /* Other elements for symbol statements */
                ,symbolOtherDelim=/  /* Delimiter for SYMBOLOTHER */
                ,symbolValue=dot /* Plot symbols for symbol statements */
                ,topy=95  /* Specifies the highest point of y (%) */
                ,varlabelstyle=STD  /* Style of labels to be applied by tu_labelvars */
                ,vref=  /* Vertical reference line value */
                ,xint=  /* X-Order interval */
                ,xlabel=none  /* X-Axis Label */
                ,xmax=  /* Upper limit of X-Axis */
                ,xvar=visit=visitnum /* X-Axis and Units */
                ,xvarlogyn=N  /* if log graph? log x axis Y/N */
                ,xvarorder=  /* X axis order by string */
                ,yint=  /* Y-Order interval */
                ,ylabel=  /* Y-Axis Label */
                ,ylogbase=10  /* Y-Axis Log base */
                ,ylogstyle=Expand  /* Axis Scale Log Style */
                ,ymax=  /* Upper limit of Y-Axis */
                ,ymin=  /* Lower Limit of Y-Axis */
                ,yvar=pporresn  /* Y-Var and Units */
                ,zvar=&g_subjid  /* 3rd Classification Variable */
                );

  /* Echo parameter values and global macro variables to the log */
  %local MacroVersion;
  %let MacroVersion=1;
  %include "&g_refdata./tr_putlocals.sas";
  %tu_putglobals();

  /* Normal Processing */

  /* Call the package macro */
  %tu_pkcfig(bars=&bars.
            ,boty=&boty.
            ,bystyle=&bystyle.
            ,byvars=&byvars.
            ,Device=&device.
            ,dsetin=&dsetin.
            ,figtype=&figtype.
            ,font=&font.
            ,formats=&formats.
            ,framePage=&framepage.
            ,framePlot=&frameplot.
            ,getdatayn=Y
            ,gmmeanyn=&gmmeanyn.
            ,gptsize=&gptsize.
            ,href=&href.
            ,labelvarsyn=Y
            ,layout=&layout.
            ,Legendlabel=&legendlabel.
            ,legendtype=&legendtype.
            ,outfile=&outfile.
            ,ptsize=&ptsize.
            ,style=&style.
            ,symbolColor=&symbolcolor.
            ,symbolInterpol=&symbolinterpol.
            ,symbolLine=&symbolline.
            ,symbolMax=&symbolmax.
            ,symbolOther=&symbolother.
            ,symbolOtherDelim=&symbolotherdelim.
            ,symbolValue=&symbolvalue.
            ,topy=&topy.
            ,varlabelstyle=&varlabelstyle.
            ,vref=&vref.
            ,xint=&xint.
            ,xlabel=&xlabel.
            ,xmax=&xmax.
            ,xvar=&xvar.
            ,xvarlogyn=&xvarlogyn.
            ,yint=&yint.
            ,ylabel=&ylabel.
            ,ylogbase=&ylogbase.
            ,ylogstyle=&ylogstyle.
            ,ymax=&ymax.
            ,ymin=&ymin.
            ,yvar=&yvar.
            ,zvar=&zvar.
            );

%mend td_pkpf3p;
