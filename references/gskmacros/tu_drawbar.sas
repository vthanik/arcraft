/*----------------------------------------------------------------------------------------
|
| Macro Name        : tu_drawbar
|
| Macro Version     : 1 build 2
|                     (Note: version 1 build 2 is the re-write of the macro. It is not
|                      based on version 1 build 1)
|                      This is actually a re-write of the code that came in from an outsource
|                      but since Build 001 was never approved and archived in our archive folder,
|                      this version must be considered Build 001.
|
| SAS Version       : 8.2
|
| Created By        : Yongwei Wang
|
| Date              : 28-Mar-2006
|
| Macro Purpose     : This macro allows the user to annotate a graph with a line (or bar),
|                     connecting two points. The bar may be drawn either horizontally or
|                     vertically, depending upon the value of the parameter BARHORIZONTALYN.
|                     This macro is intended to be used to draw confidence intervals or a
|                     range of values covering a value plus and minus a measure of
|                     variability - a standard error
|
| Macro Design      : Procedure Style
|
| Input Parameters  :
|
| NAME                DESCRIPTION                             REQ/OPT   DEFAULT
| -----------------  -------------------------------------    -------  --------------
| BARHORIZONTALYN     Specifies whether the line is drawn     RER       N
|                     horizontally or vertically.
|                     Valid Values: Y or N
|
| BARINTERVAL         Specifies a bar interval in format      OPT       0 to 120 by 30
|                     i to j by k to specify &HVAR or
|                     &VVAR position for displaying bars.
|                     Valid Value:
|                     Blank or i to j by k where i, j and k are
|                     numeric values
|
| BARLINESIZE         Specifies the thickness of the line     REQ       1
|                     Valid Values: A number
|
| BARRANGE            Specifies a pair of variables that      REQ       (Blank)
|                     defines the starting and ending point of
|                     the line to be drawn.
|                     Valid Values:
|                     Two variables which exist on &DSETIN.
|
| BARSYMBOLLIST       Specifies one or more symbol values to  OPT       (Blank)
|                     mark the ends of the bar.
|                     Also defines the colour of the symbols
|                     and the line.
|                     If the symbol type is not given, then
|                     macro will use | (for horizontal bars)
|                     and - ( for vertical bars).
|                     Valid Value:
|                     Blank, Null, or a list of symbol values
|                     which are valid for SAS graph.
|
| COMPAREVAR          Specifies the name of a variable         OPT      (Blank)
|                     in &DSETIN which will be used to
|                     define a comparison
|                     Valid Values:
|                     Blank or variable which exists in &DSETIN.
|
| DSETIN              Specifies the input dataset.             REQ      (Blank)
|                     Valid Values:
|                     An existing SAS dataset
|
| DSETOUTANNO         Specifies the name of output .           REQ       _ccanno_
|                     annotate dataset
|                     Valid Values:
|                     A valid SAS dataset name
|
| HVAR                Specifies the variable which determines  REQ *     (Blank)
|                     the horizontal axis coordinates of the
|                     line to be drawn.
|                     Valid Values:
|                     The name of a variable which exists on &DSETIN.
|                     If &BARHORIZONTALYN is N, this parameter is
|                     required.
|                     If &BARHORIZONTALYN is Y, providing this      *
|                     parameter causes an additional symbol to be
|                     plotted (generally at the origin of the
|                     interval).
|
| SHIFT               Specifies a value of &HVAR or &VVAR       REQ *     0.025
|                     to define the distance between the graphs
|                     of different level of &COMPAREVAR.
|                     Valid Values: Blank or a number
|                     Required if &COMPAREVAR is not blank. *
|
| SYMBOL              Specifies the definition of a symbol      OPT       (Blank)
|                     If it is given in format n:{Values},
|                     n means nth value of &COMPAREVAR and {Values}
|                     is the SYMBOL value. The macro will use this
|                     symbol to draw the origin of the interval.
|                     Valid Values:
|                     Definition of a symbol which can be used in
|                     SYMBOL1-99 statement.
|
| VVAR                Specifies the variable which determines   REQ *      (Blank)
|                     the vertical axis coordinates of the
|                     line to be drawn.
|                     Valid Values:
|                     The name of a variable which exists in &DSETIN.
|                     If &BARHORIZONTALYN is Y, this parameter                 *
|                     is required.
|                     If &BARHORIZONTALYN is N, providing this
|                     parameter causes a additional symbol to be
|                     plotted (generally at the origin of the
|                     interval).
|-----------------------------------------------------------------------------------------
| Output:  This macro creates an annotate dataset
|-----------------------------------------------------------------------------------------
| Global macro variables created: None.
|-----------------------------------------------------------------------------------------
| Macros called:
|(@) tr_putlocals
|(@) tu_abort
|(@) tu_axis
|(@) tu_chknames
|(@) tu_chkvarsexist
|(@) tu_getproperty
|(@) tu_nobs
|(@) tu_putglobals
|(@) tu_tidyup
|-----------------------------------------------------------------------------------------
| Example:
|    %macro tu_drawbar(
|       barhorizontalyn   = Y,
|       barlinesize       = 1,
|       barrange          = LOW HIGH,
|       barsymbollist     = STAR,
|       comparevar        = comparevar,
|       dsetin            = sri.sample,
|       dsetoutanno       = sri.vbar,
|       hvar              = hvar,
|       shift             = 0.025,
|       symbol            = DOT,
|       vvar              = vvar
|       );
|
|-----------------------------------------------------------------------------------------
| Change Log
|
| Modified By:
| Date of Modification:
| New version/draft number:
| Modification ID:
| Reason For Modification:
+---------------------------------------------------------------------------------------*/

%macro tu_drawbar(
   BARHORIZONTALYN     =N,                 /* If the line drawn is horizontal */
   BARINTERVAL         =0 to 120 by 30,    /* &HVAR or &VVAR interval for displaying bars */
   BARLINESIZE         =1,                 /* Thickness of the line. */
   BARRANGE            =,                  /* A pair of variables that define the starting and ending place of the line to be drawn. */
   BARSYMBOLLIST       =,                  /* One or more symbol values to mark the ends of the bar. */
   COMPAREVAR          =,                  /* A variable that defines a comparison. This will generally be a variable defining treatment groups. */
   DSETIN              =,                  /* Input dataset */
   DSETOUTANNO         =_ccanno_,          /* Output annotate dataset name */
   HVAR                =,                  /* Variable name for H axis */
   SHIFT               =0.025,             /* Graphic shift between &COMPAREVARS in value of &HVAR or &VVAR */
   SYMBOL              =,                  /* Definition of a symbol to be used to plot the estimate at the origin of the interval. */
   VVAR                =                   /* Variable name for V axis */
   );

   /*
   / N1.Call %tr_putlocals to echo the macro name and version to the log.
   / N2.Call %tu_putglobals to echo the parameter values and values of global macro
   /    variables to the log.
   /----------------------------------------------------------------------------------*/

   %local MacroVersion;
   %let MacroVersion = 1;
   %put Macroname : &sysmacroname Macroversion : &MacroVersion ;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals();			

   /*
   / Define local macro variables used in the macro.                         	
   /----------------------------------------------------------------------------------*/

   %local l_symbol1 l_symbol2 l_symbol3 l_symbol4 l_symbol5 l_symbol6 l_symbol7
          l_symbol8 l_symbol9 l_symbol10
          l_barsym1 l_barsym2 l_barsym3 l_barsym4 l_barsym5  l_barsym6 l_barsym7
          l_barsym8 l_barsym9 l_barsym10
          l_barsym21 l_barsym22 l_barsym23 l_barsym24 l_barsym25  l_barsym26 l_barsym27
          l_barsym28 l_barsym29 l_barsym210
          l_compval1 l_compval2 l_compval3 l_compval4 l_compval5 l_compval6 l_compval7
          l_compval8 l_compval9 l_compval10;
   %local l_axis1 l_axis2 l_axisvar l_compcount l_complen l_defbarsym l_defbarsym
          l_defcolorlist l_defcolorlist l_defsymbollist l_defsymbollist l_high l_high
          l_i l_j l_k l_l l_low l_midvar l_prefix l_property l_propertylist l_rx
          l_step l_symbol l_tmp l_word l_tmp1 l_tmp2 l_defsize;

   /*
   / N3.Perform parameter validation. After all have been validated, if an error is found
   /    then call %tu_abort.
   /----------------------------------------------------------------------------------*/

   /* N4.Set work dataset prefix to _drawbar */

   %let l_prefix=_drawbar;	

   /*
   / PV01.Check that none of required parameters are blank.
   /----------------------------------------------------------------------------------*/

   %let l_tmp=BARHORIZONTALYN BARLINESIZE BARRANGE DSETIN DSETOUTANNO;
   /* change to do while so if list changes, don't have to modify number below  */

   %do l_i=1 %to 5;
      %let l_word=%scan(&l_tmp, &l_i);
      %if %nrbquote(&&&l_word) eq %then
      %do;
         %let g_abort=1;
         %put RTE%str(RROR): &sysmacroname: Parameter &l_word is blank and it is required.;
      %end;
   %end; /* %do l_i=1 to 5 */

   /*
   / PV02.Check that &DSETIN exists.
   /----------------------------------------------------------------------------------*/

   %let l_rx=0;
   %if %nrbquote(&dsetin) NE %then
   %do;
      %if %sysfunc(EXIST(&dsetin)) EQ 0 %then
      %do;
          %put %str(RTE)RROR: &sysmacroname: The dataset identified by macro variable DSETIN (&dsetin) does not exist.;
          %let g_abort=1;
      %end;
      %else %let l_rx=1;
   %end; /* %if &dsetin NE */

   /*
   / PV05.Check that &DSEOUTANNO is a valid SAS dataset name.
   /----------------------------------------------------------------------------------*/

   %if %nrbquote(&dsetoutanno) ne %then
   %do;
      %if %nrbquote(%tu_chknames(&dsetoutanno,DATA)) NE %then	
      %do;
         %put %str(RTE)RROR: &sysmacroname: The value provided for the macro variable DSETOUTANNO (&dsetoutanno) is not a valid dataset name.;
         %let g_abort=1;
      %end;
   %end; /* %if &dsetoutanno ne */

   /*
   / PV06.Check that &BARRANGE is a pair of variable names and that the  variables exist /
     in &DSETIN
   /----------------------------------------------------------------------------------*/

   %let l_low=%qscan(%nrbquote(&barrange), 1);
   %let l_high=%qscan(%nrbquote(&barrange), 2);

   %if ( &l_high eq ) OR ( %qscan(&barrange, 3) NE ) %then
   %do;
       %put %str(RTE)RROR: &sysmacroname: The value provided for the macrovariable BARRANGE (&barrange) is not a pair.;
       %let g_abort=1;
   %end;

   %if ( &l_rx ) AND ( &l_high ne ) AND ( %qupcase(&l_high) NE NULL ) %then %do;
      %if %tu_chkvarsexist(&dsetin,&l_high) NE  %then
      %do;
         %put %str(RTE)RROR: &sysmacroname: Variable &l_high given by BARRANGE (&barrange) does not exist in DSETIN (&dsetin);
         %let g_abort=1;
      %end;
   %end; /* %if ( &l_rx ) AND ( &l_high ne ) */

   %if ( &l_rx ) AND ( &l_low ne ) AND ( %qupcase(&l_low) NE NULL ) %then %do;
      %if %tu_chkvarsexist(&dsetin,&l_low) NE  %then
      %do;
         %put %str(RTE)RROR: &sysmacroname: Variable &l_low given by BARRANGE (&barrange) does not exist in DSETIN (&dsetin);
         %let g_abort=1;
      %end;
   %end; /* %if ( &l_rx ) AND ( &l_low ne ) */

   /*
   / PV07.Check that &COMPAREVAR is blank or is a variable that exists in &DSETIN.
   /----------------------------------------------------------------------------------*/

   %if ( &l_rx ) AND ( %nrbquote(&comparevar) ne ) %then
   %do;
      %if %tu_chkvarsexist(&dsetin,&comparevar) NE  %then
      %do;
         %put %str(RTE)RROR: &sysmacroname: The variable COMPAREVAR (&comparevar) does not exist in DSETIN (&dsetin);
         %let g_abort=1;
      %end;
   %end; /* %if ( &l_rx ) AND ( &comparevar ne ) */

   /*
   / PV08.If &COMPAREVAR is given,then check that &SHIFT is not blank
   /----------------------------------------------------------------------------------*/

   %if ( %nrbquote(&comparevar) NE ) AND ( %nrbquote(&shift) EQ ) %then		
   %do;
      %put %str(RTE)RROR: &sysmacroname: The value provided by the macro variable SHIFT (&shift) should not be blank when COMPAREVAR(=&COMPAREVAR) is not blank.;
      %let g_abort=1;
   %end;

   /*
   / PV09.Check that &BARHORIZONTALYN is either Y or N.
   /----------------------------------------------------------------------------------*/

   %let barhorizontalyn=%qupcase(&barhorizontalyn);
   %if ( &barhorizontalyn NE Y ) and (  &barhorizontalyn NE N ) %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: The required variable BARHORIZONTALYN (&barhorizontalyn) should be either Y or N ;
      %let g_abort=1;
   %end;

   /*
   / PV10.If &BARHORIZONTALYN is N , check that &HVAR is not blank.
   /----------------------------------------------------------------------------------*/

   %if ( &barhorizontalyn EQ N ) AND ( %nrbquote(&hvar) EQ ) %then		
   %do;
      %put %str(RTE)RROR: &sysmacroname: The value provided by the macro variable HVAR(=&hvar) should not be blank when BARHORIZONTALYN=N.;
      %let g_abort=1;
   %end;

   /*
   / PV11.If &BARHORIZONTALYN is Y , check that &VVAR is not blank.
   /----------------------------------------------------------------------------------*/

   %if ( &barhorizontalyn EQ Y ) AND ( %nrbquote(&vvar) EQ ) %then		
   %do;
      %put %str(RTE)RROR: &sysmacroname: The value provided by the macro variable VVAR(=&VVar) should not be blank when BARHORIZONTALYN=Y.;
      %let g_abort=1;
   %end;

   /*
   / PV12.Check that &HVAR and &VVAR exist in &DSETIN if given.
   /----------------------------------------------------------------------------------*/

   %if ( &l_rx ) AND ( %nrbquote(&hvar) ne ) %then
   %do;
       %if %tu_chkvarsexist(&dsetin,&hvar) ne  %then
       %do;
           %let g_abort=1;
           %put %str(RTE)RROR: &sysmacroname: the variable HVAR (&hvar)  does not exist in DSETIN (&dsetin);
       %end;
   %end; /* %if ( &l_rx ) AND ( &hvar ne ) */

   %if ( &l_rx ) AND ( %nrbquote(&vvar) ne ) %then
   %do;
       %if %tu_chkvarsexist(&dsetin,&vvar) ne  %then
       %do;
           %let g_abort=1;
           %put %str(RTE)RROR: &sysmacroname: the variable VVAR (&vvar)  does not exist in DSETIN (&dsetin);
       %end;
   %end; /* %if ( &l_rx ) AND ( &vvar ne ) */

   /*
   / PV13.Check that &BARLINESIZE is a number.
   /----------------------------------------------------------------------------------*/

   %if ( %nrbquote(&barlinesize) NE ) %then
   %do;
       %if %nrbquote(%verify(&barlinesize,'0123456789.')) GT 0 %then
       %do;
           %put %str(RTE)RROR: &sysmacroname: The value provided for the macro variable BARLINESIZE (&barlinesize) is not a number.;
           %let g_abort=1;
       %end;
    %end; /* %if ( &barlinesize NE ) */
	
   /*
   / PV14.Check that &SHIFT, if given, is a number.
   /----------------------------------------------------------------------------------*/

	
   %if ( %nrbquote(&shift) NE ) %then
   %do;
       %if %nrbquote(%verify(&shift,'0123456789.')) GT 0 %then
       %do;
           %put %str(RTE)RROR: &sysmacroname: The value provided for the macro variable SHIFT (&shift) is not a number.;
           %let g_abort=1;
       %end;
   %end; /* %if ( &shift NE ) */

   /*
   / End of N3.Perform parameter validation. If an error was found
   /    then call %tu_abort.
   /----------------------------------------------------------------------------------*/

   %if &g_abort GT 0 %then %goto macerr;

   /*  Normal Processing. */

   /*
   / N6 and N8 are almost identical. Create some local macro variables so that N6 and
   / N8 can share the code. N5 and N7 is used to switch the macro  variables
   /----------------------------------------------------------------------------------*/

   %if &barhorizontalyn. EQ Y %then
   %do;
      %let l_axis1=x;
      %let l_axis2=y;
      %let l_axisvar=&vvar;
      %let l_midvar=&hvar;
   %end;
   %else %do;
      %let l_axis1=y;
      %let l_axis2=x;
      %let l_axisvar=&hvar;
      %let l_midvar=&vvar;
   %end;

   %if %qupcase(&l_low) eq NULL %then
   %do;
      %let l_low=&l_midvar;
   %end;

   %if %qupcase(&l_high) eq NULL %then
   %do;
      %let l_high=&l_midvar;
   %end;

   /* Get level of &comparevar */
   %let l_compcount=1;
   %if %nrbquote(&comparevar) ne %then
   %do;
      proc sort data=&dsetin out=&l_prefix.comp (keep=&comparevar) nodupkey;
         by &comparevar;
      run;

      data _null_;
         set &l_prefix.comp end=end;
         if vtype( &comparevar ) eq 'C' then
            call symput(compress('l_compval'||put(_n_, 6.0)), '"'||trim(left(&comparevar))||'"');
         else
            call symput(compress('l_compval'||put(_n_,6.0)), trim(left(putn(&comparevar, "best."))));
         if end then
         do;
            call symput('l_compcount', put(_n_, 6.0));
            if vtype( &comparevar ) eq 'C' then
               call symput('l_complen', put(vlength( &comparevar ), 6.0));
         end;
      run;
   %end; /* %if %nrbquote(&comparevar) ne */

   /* Get symbol for each level of &comparevar */
   %do l_l=1 %to 2;
      %if &l_l eq 2 %then %let l_symbol=%nrbquote(&barsymbollist);
      %else %let l_symbol=%nrbquote(&symbol);
      %if &l_l eq 2 %then %let l_tmp1=%eval(&l_compcount * 2);
      %else %let l_tmp1=&l_compcount;
      %if %index( &l_symbol, %str(=)) %then
      %do;
         %let l_tmp=&l_symbol;
         %do l_i=1 %to &l_tmp1;
            %let l_j=1;
            %let l_k=%length(&l_tmp);
            %let l_tmp=%unquote(&l_tmp);
            %let l_rx=%sysfunc(rxparse($(10)));
            %syscall rxsubstr(l_rx, l_tmp, l_j, l_k);
            %syscall rxfree(l_rx);
            %if ( &l_j ge 1 ) and ( &l_k gt 0 ) %then
            %do;
               %if %eval(&l_k-2) gt 0 %then %let l_property=%qsubstr(&l_tmp, %eval(&l_j+1), %eval(&l_k-2));
               %else %let l_property=;
               %if %eval(&l_j + &l_k) ge %length(&l_tmp) %then %let l_tmp=;
               %else %let l_tmp=%qsubstr(&l_tmp, %eval(&l_j + &l_k));
            %end;
            %else %do;
               %let l_property=%nrbquote(&l_tmp);
            %end;
            %if &l_l eq 2 %then %do;
               %let l_tmp2=%sysfunc(mod(&l_i, 2));
               %if &l_tmp2 eq 1 %then
               %do;
                  %let l_tmp2=%sysfunc(sum((&l_i + 1)/ 2, 0));
                  %let l_barsym&l_tmp2=%nrbquote(&l_property);
               %end;
               %else %do;
                  %let l_tmp2=%sysfunc(sum(&l_i / 2, 0));
                  %let l_barsym2&l_tmp2=%nrbquote(&l_property);
               %end;
            %end; /*  %if &l_l eq 2 */
            %else %let l_symbol&l_i=%nrbquote(&l_property);
         %end; /* %do l_i=1 %to &l_compcount */
      %end; /* %if %index( &l_symbol, %str(=)) */
      %else %if %nrbquote(&l_symbol) ne %then
      %do;
         %let l_tmp=&l_symbol;
         %do l_i=1 %to &l_tmp1;
            %if %qscan(&l_symbol, &l_i, %str( )) eq %then
            %do;
               %let l_property=text="%qscan(&l_symbol, &l_i, %str( ))";
               %let l_tmp=&l_property;
            %end;
            %else %do;
               %let l_property=&l_tmp;
            %end;
            %if &l_l eq 2 %then %do;
               %let l_tmp2=%sysfunc(mod(&l_i, 2));
               %if &l_tmp2 eq 1 %then
               %do;
                  %let l_tmp2=%sysfunc(sum((&l_i + 1)/ 2, 0));
                  %let l_barsym&l_tmp2=%nrbquote(&l_property);
               %end;
               %else %do;
                  %let l_tmp2=%sysfunc(sum(&l_i / 2, 0));
                  %let l_barsym2&l_tmp2=%nrbquote(&l_property);
               %end;
            %end; /*  %if &l_l eq 2 */
            %else %let l_symbol&l_i=%nrbquote(&l_property);
         %end; /* %do l_i=1 %to &l_compcount */
      %end; /* %if %nrbquote(&l_symbol) ne */
   %end; /* %do l_l=1 %to 2 */

   /* Get symbol properties from &symbol and &barsymbollist */
   %let l_defcolorlist=red blue green yellow cyan gold pink olive brown purple ;
   %let l_defsymbollist=DOT CIRCLE PLUS X STAR SQUARE DIAMOND TRIANGLE HASH POINT;
   %if &barhorizontalyn. EQ N %then
      %let l_defbarsym=_ _;
   %else
      %let l_defbarsym=| |;
   %let l_defsize=1;

   /*
   / Get properties of symbol from SYMBOLS and/or &BARSYMBOLLIST. Those properties are
   / used are described N6 and N8.
   /----------------------------------------------------------------------------------*/

   %do l_j=1 %to 3;
      %do l_i=1 %to &l_compcount;
         %if &l_j eq 2 %then %let l_symbol=%nrbquote(&&l_barsym&l_i);
         %else %if &l_j eq 3 %then %let l_symbol=%nrbquote(&&l_barsym2&l_i);
         %else %let l_symbol=%nrbquote(&&l_symbol&l_i);
         /* color style size and text */
         %if %nrbquote(&l_symbol) ne %then
         %do;
            /* color */
            %let l_tmp=%tu_getproperty(equalsignyn=Y,keyword=color,propertylist=&l_symbol);
            %if %nrbquote(&l_tmp) eq %then %let l_tmp=%tu_getproperty(equalsignyn=Y,keyword=c,propertylist=&l_symbol);
            %if %nrbquote(&l_tmp) eq %then %let l_tmp=%tu_getproperty(equalsignyn=Y,keyword=cv,propertylist=&l_symbol);
            %if %nrbquote(&l_tmp) eq %then %let l_tmp=%tu_getproperty(equalsignyn=Y,keyword=ci,propertylist=&l_symbol);
            %if ( %nrbquote(&l_tmp) eq ) %then %let l_property=color="%scan(&l_defcolorlist, &l_i, %str( ))";
            %else %let l_property=color="&l_tmp";
            /* size */
            %let l_tmp=%tu_getproperty(equalsignyn=Y,keyword=size,propertylist=&l_symbol);
            %if ( %nrbquote(&l_tmp) eq ) %then %let l_property=size=&l_defsize %nrstr(;) %nrbquote(&l_property);
            %else %let l_property=size=&l_tmp %nrstr(;) %nrbquote(&l_property);
            /* symbol text */
            %let l_tmp=%tu_getproperty(equalsignyn=Y,keyword=text,propertylist=&l_symbol);
            %if ( %nrbquote(&l_tmp) eq ) %then %let l_tmp2=SWISS;
            %else %let l_tmp2=NONE;
            %if ( %nrbquote(&l_tmp) eq ) and ( &l_j eq 1 ) %then
               %let l_property=%nrbquote(text="%scan(&l_defsymbollist,&l_i,%str( ))") %nrstr(;) %nrbquote(&l_property);
            %else %if ( %nrbquote(&l_tmp) eq ) and ( &l_j eq 2 ) %then
               %let l_property=%nrbquote(text="%scan(&l_defbarsym, 1, %str( ))") %nrstr(;) %nrbquote(&l_property);
            %else %if ( %nrbquote(&l_tmp) eq ) %then
               %let l_property=%nrbquote(text="%scan(&l_defbarsym, 2, %str( ))") %nrstr(;) %nrbquote(&l_property);
            %else %if ( %qupcase(&l_tmp) eq NULL ) %then ;
            %else %let l_property=%nrbquote(text="&l_tmp") %nrstr(;) %nrbquote(&l_property);
            /* style */
            %let l_tmp=%tu_getproperty(equalsignyn=Y,keyword=style,propertylist=&l_symbol);
            %if ( %nrbquote(&l_tmp)) eq %then %let l_property=style="&l_tmp2" %nrstr(;) %nrbquote(&l_property);
            %else %let l_property=style="&l_tmp" %nrstr(;) %nrbquote(&l_property);
            /* Other properties */
            %let l_propertylist=cborder cbox group midpoint subgroup;
            %do l_k=1 %to 5;
               %let l_tmp=%tu_getproperty(equalsignyn=Y,keyword=%scan(&l_propertylist,&l_k),propertylist=&l_symbol);
               %if %nrbquote(&l_tmp) eq %then %let %scan(&l_propertylist,&l_k)=" " %nrstr(;) %nrbquote(&l_property);
               %else %let l_property=%scan(&l_propertylist,&l_k)=%nrbquote("&l_tmp") %nrstr(;) %nrbquote(&l_property);
            %end; /* %do l_k=1 %to 5 */
         %end;
         %else %do;
            %if &l_j eq 2 %then
            %do;
               %let l_property=style="SWISS" %nrstr(;) %nrbquote(text="%scan(&l_defbarsym, 1, %str( ))") %nrstr(;) color="%scan(&l_defcolorlist, &l_i, %str( ))" %nrstr(;) size=&l_defsize;
            %end;
            %else %if &l_j eq 3 %then
            %do;
               %let l_property=style="SWISS" %nrstr(;) %nrbquote(text="%scan(&l_defbarsym, 2, %str( ))") %nrstr(;) color="%scan(&l_defcolorlist, &l_i, %str( ))" %nrstr(;) size=&l_defsize;
            %end;
            %else %do;
               %let l_property=style="NONE" %nrstr(;) %nrbquote(text="%scan(&l_defsymbollist,&l_i,%str( ))") %nrstr(;) color="%scan(&l_defcolorlist, &l_i, %str( ))" %nrstr(;) size=&l_defsize;

            %end;
         %end; /* %if %nrbquote(&l_symbol) ne */
         %if &l_j eq 2 %then %let l_barsym&l_i=%nrbquote(&l_property);
         %else %if &l_j eq 3 %then %let l_barsym2&l_i=%nrbquote(&l_property);
         %else %let l_symbol&l_i=%nrbquote(&l_property);
      %end; /* %do l_i=1 %to &l_compcount */
   %end; /* %do l_j=1 %to 2 */

   /*
   / N5.1 If &BARINTERVAL is given,
   /    1. Call %tu_axis to convert value of &barinterval to interval point.
   /    2. Modify value of &HVAR in &DSETIN to make it match the value at interval
   /       point after it.
   /-----------------------------------------------------------------------------------*/

   %if %nrbquote(&barinterval) ne %then
   %do;
      %tu_axis(
         AXIS                =order=(&BARINTERVAL),
         AXISNAME            =AXIS1,
         AXISVAR             =&l_axisvar,
         AXISVARDECODE       =,
         DSETIN              =&dsetin,
         DSETOUT             =&l_prefix.axis,
         FORMATS             =,
         LABELS              =,
         LOWLIMIT            =,
         UPLIMIT             =
         );

      proc sort data=&l_prefix.axis out=&l_prefix.axis1(keep=ticknum varvalue);
         by ticknum varvalue;
      run;

      %let l_step=0;
      data &l_prefix.axis2;
         set &l_prefix.axis1 end=end;
         keep _varvalue &comparevar;
         retain _step;
         _varvalue=input(varvalue, best.);
         if _n_ eq 1 then _step=_varvalue;
         if _n_ eq 2 then
         do;
            _step=_varvalue - _step;
            call symput('l_step', put(_step, best.));
         end;
         %if %nrbquote(&comparevar) ne %then
         %do;
            %if %nrbquote(&l_complen) ne %then length &comparevar $&l_complen.;;
            %do l_i=1 %to &l_compcount;
               &comparevar=&&l_compval&l_i;
               output;
            %end;  /* %if %nrbquote(&comparevar) ne */
         %end; /* %do l_i=1 %to &l_compcount */
      run;

      data &l_prefix.data1;
         set &dsetin;
         where not missing(&l_axisvar);
         keep &l_axisvar _varvalue &comparevar;
         if vtype(&l_axisvar) eq 'C' then _varvalue=input(&l_axisvar, best.);
         else _varvalue=&l_axisvar;
      run;

      data &l_prefix.data2;
         set &l_prefix.data1  &l_prefix.axis2;
      run;

      %let l_tmp=;
      %if &l_step lt 0 %then %let l_tmp=descending;

      proc sort data=&l_prefix.data2;
         by &comparevar &l_tmp _varvalue;
      run;

      data &l_prefix.data3;
         set &l_prefix.data2 ;
         by &comparevar &l_tmp _varvalue;
         retain __temp__ ;
         drop __temp__;
         %if %nrbquote(&comparevar) ne %then
         %do;
            if first.&comparevar then __temp__=.;
         %end;
         if not missing(&l_axisvar) then __temp__=&l_axisvar;
         else do;
            &l_axisvar=__temp__;
            output;
         end;
      run;

      proc sort data=&l_prefix.data3;
         by &comparevar &l_axisvar;
      run;

      proc sort data=&dsetin out=&l_prefix.data4;
         by &comparevar &l_axisvar;
      run;
      
      data &l_prefix.data41;
         set &l_prefix.data4 end=end;
         by &comparevar &l_axisvar;
         keep &comparevar __max_value__;
         if %if %nrbquote(&comparevar) ne %then last.&comparevar;
            %else end; then __max_value__=&l_axisvar;
      run;
      
      data  &l_prefix.data5;
         merge &l_prefix.data3(in=_in_) &l_prefix.data4;
         by &comparevar &l_axisvar;
         drop _varvalue;
         if _in_;
         if vtype(&l_axisvar) eq 'C' then &l_axisvar=put(_varvalue, best.);
         else &l_axisvar=_varvalue;
      run;

      proc sql noprint;
         create table &l_prefix.data5 as
         select a.*
         from   &l_prefix.data5 as a, &l_prefix.data41 as b
         where  %if %nrbquote(&comparevar) ne %then a.&comparevar eq b.&comparevar and;
                a.&l_axisvar le b.__max_value__;
      quit;

      proc sort data=&l_prefix.data5 nodupkey;
         by &comparevar &l_axisvar;
         where ( not missing(&l_low) ) and ( not missing(&l_high) );
      run;

      %let dsetin=&l_prefix.data5;
   %end; /* %if %nrbquote(&barinterval) ne */

   /*
   / N6.& N8. Sort the dataset by &HVAR and &COMPAREVAR. and &L_AXISVAR
	 /-----------------------------------------------------------------------------------*/

   proc sort data=&dsetin nodupkey
        out=&l_prefix.dsetin(keep=&comparevar &l_midvar &l_low &l_high &l_axisvar);
      by &comparevar &l_axisvar;
      where ( not missing(&l_low) ) and ( not missing(&l_high) );
   run;

   /* Data set is empty. Nothing to draw */
   %if %tu_nobs(&l_prefix.dsetin) le 0 %then
   %do;
      data &dsetoutanno;
         set &l_prefix.dsetin;
      run;
      %goto macend;
   %end;

   /*
   / Create an annotate dataset for vertical or horizontal bars
   /-----------------------------------------------------------------------------------*/

   data &dsetoutanno;
      length function style color $8 text $200  x 8. y 8.;
      length cborder cbox $8 group subgroup $8;
      retain xsys ysys '2' hsys '4' when 'A';
      set &l_prefix.dsetin;
      by &comparevar &l_axisvar;
      drop tt_axis &l_low &l_high &comparevar /*&hvar &vvar*/;
      cborder='';
      cbox='';
      group='';
      subgroup='';

      %if %nrbquote(&comparevar) ne %then
      %do;
         select(&comparevar);
      %end;
      %else %do;
         %let l_compval1=1;
         %let shift=0;
         drop __comparevar;
         __comparevar=1;
         select(__comparevar);
      %end;
         %do l_i=1 %to &l_compcount;
            when(&&l_compval&l_i) do;
               tt_axis=sum(&l_axisvar, &shift.* %eval(&l_i - 1));
               %unquote(&&l_symbol&l_i);
               if missing(tt_axis) then tt_axis=&l_axisvar;
               function='move'; &l_axis1=&l_low; &l_axis2=tt_axis; output;
               /*
               / N6.c.Include statements to draw symbols at these two points that define
               /      the ends of the line.
               /    i.&BARSYMBOLLIST may define the colour and/or symbol to be used.
               /      If "Null" is given as the symbol, do not draw a symbol.
               /	ii.If a symbol is not defined by &BARSYMBOLLIST, use "|". The size of
               /      the end symbols should be adjusted according to &BARLINESIZE. The
               /      location of the symbol should be considered.
               /----------------------------------------------------------------------*/

               if &l_high ne &l_low then
               do;
                  %if %qupcase(&l_low) ne %qupcase(&l_midvar) %then
                  %do;
                     function='symbol'; %unquote(&&l_barsym&l_i) ; output;
                  %end;
               /*
               / N6.b.The X coordinate of the start and end of the line to be drawn are
               /      defined by &BARRANGE.
               /    i.Determine the thickness of the line from &BARLINESIZE. The line
               /      type should be 1.
               /   ii.Determine the colour of the line from &BARSYMBOLLIST, if given
               /  iii.Include a statement in the annotate dataset to draw this line
               /----------------------------------------------------------------------*/
                  function='draw'; &l_axis1=&l_high; &l_axis2=tt_axis; line=1; size=&barlinesize.; output;
                  %if %qupcase(&l_low) ne %qupcase(&l_midvar) %then
                  %do;
                     function='symbol'; %unquote(&&l_barsym2&l_i) ; output;
                  %end;
               end; /* if &l_high ne &l_low */

               /*
               / N6.d.If &HVAR is not blank include a statement to draw a symbol at the
               /      intersection of &HVAR and &VVAR.
               /    i.&SYMBOL may define the colour and/or symbol to be used.
               /----------------------------------------------------------------------*/
               %if %nrbquote(&l_midvar) NE  %then
               %do;
                  function='move'; &l_axis1=&l_midvar; &l_axis2=tt_axis; output;
                  function='symbol'; %unquote(&&l_symbol&l_i) ; output;
               %end;
            end; /* when(&&l_compvar&l_i)*/
         %end; /* %do l_i=1 %to &l_compcount */
         otherwise;
      end; /* select(&comparevar) */
   run;

   %goto macend;

%MACERR:

   %let g_abort=1;
   %tu_abort(
      option=force
      );

    /*
    / N10. Call tu_tidyup to delete temporary data sets
    /-----------------------------------------------------------------------------------*/

%MACEND:

     %tu_tidyup(
        rmdset=&l_prefix:,
        glbmac=none
        );

%mend tu_drawbar;


	


