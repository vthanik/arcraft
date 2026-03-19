/*----------------------------------------------------------------------------------------
| Macro Name        : TU_DRAWNUMOFSUBJS
|
| Macro Version     : 3 build 1
|                     (Note: version 1 build 6 is the re-write of the macro. It is not 
|                      based on version 1 build 5)
|
| SAS version       : SAS v8.2
|
| Created By        : Yongwei Wang
|
| Date              : 06-Apr-2006
|
| Macro Purpose     : This unit shall create an annotate dataset to be used to annotate a
|                     graph with the number of subjects at each time point, for different
|                     groups. The annotate dataset created by this macro would be used to
|                     add the portion show in white in the example that follows.
|                     Adjustments are made in the size main graphic to allow the space for
|                     this annotation
|
| Macro Design      : PROCEDURE STYLE
|
| Input Parameters  :
|
| Name                Description                                       Default
| ----------------------------------------------------------------------------------------
| COLORLIST           Specifies a list of colours for each level of     (Blank)
|                     &COMPAREVAR.
|                     Valid Value:
|                     Blank or a list of colours which are valid
|                     colours for SAS graph.
|
| COMPAREVAR          Specifies the name of a variable which exists in  (Blank)
|                     &DSETIN and will be used on the vertical axis.
|                     Valid Values:
|                     A variable which exists in &DSETIN.
|
| COMPAREVARDECODE    Specifies a name of a variable which is the       (Blank)
|                     decode of &COMPAREVAR.
|                     Valid Values:
|                     Blank or a name of variable which exists in
|                     &DSETIN.
|
| DSETIN              Specifies the input dataset.                      (Blank)
|                     Valid Values:
|                     An existing SAS dataset.
|
| DSETOUTANNO         Specifies the name of output annotate dataset.    _subjsanno_
|                     Valid Value:
|                     A valid SAS dataset name.
|
| FORMATS             Specifies a definition of formats that can be     (Blank)
|                     used in a SAS format statement.
|                     Valid Values:
|                     Blank or a definition of formats which can be
|                     used in a SAS format statement.
|
| FRAMEOPTION         Specifies the properties of the frame line in     (Blank)
|                     the format {property} = {value}. The properties
|                     are COLOR, SIZE and TYPE. The values are the
|                     same as the properties of other SAS graph frame.
|                     Valid Values:
|                     Blank or a list of line properties.
|
| FRAMEYN             Specifies if a frame should be drawn around the   N
|                     graphic that is drawn by this macro.
|                     Valid Values: Y or N
|
| HAXISDSET           Specifies the name of the horizontal AXIS         (Blank)
|                     property dataset previously created by the
|                     %tu_axis macro.
|                     Valid Name:
|                     A valid SAS dataset name.
|
| HAXISNAME           Specifies the name of the horizontal axis         (Blank)
|                     defined by the AXIS1-99 statement.
|                     Valid Values: AXIS1-99
|
| HVAR                Specifies the name of a variable which exists in  (Blank)
|                     &DSETIN and will be used on the horizontal axis.
|                     Valid Values:
|                     A variable which exists in &DSETIN.
|
| LABELS              Specifies a definition of labels which can be     (Blank)
|                     used in a SAS label statement.
|                     Valid Values:
|                     Blank or a definition of labels which can be
|                     used in SAS label statement.
|
| ROWSPACE            Specifies a space between row graphs.             0.2
|                     Valid Values: a number
|
| SUBJCOUNTVAR        Specifies a variable which contains the number    (Blank)
|                     of subjects at each point.
|                     Valid Values:
|                     A variable that exists in &DSETIN.
|
| TEXTOPTION          Specifies properties of the label text in format  (Blank)
|                     {property} = {value}. The properties are COLOR,
|                     FONT, HEIGHT and JUSTIFY. The values are the
|                     same as the properties of other SAS graph text
|                     Valid Values:
|                     Blank or a list of text properties.
|
| VAXISYN             Specifies if a vertical axis should be drawn in   Y
|                     the annotation.
|                     Valid Values: Y or N
|
|-----------------------------------------------------------------------------------------
| Output: This unit will create an annotate dataset that will be used for annotating a
|         graph with the number of subjects at each time point
|-----------------------------------------------------------------------------------------
|Global macro variables created: None
|-----------------------------------------------------------------------------------------
| Macros called :
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_chknames
| (@) tu_chkvarsexist
| (@) tu_getgstatements
| (@) tu_getproperty
| (@) tu_labelvars
| (@) tu_nobs
| (@) tu_putglobals
| (@) tu_tidyup
| (@) tu_words
|-----------------------------------------------------------------------------------------
| Example:
|    %tu_drawnumofsubjs (
|          COLORLIST        = red green
|        , COMPAREVAR       = group
|        , COMPAREVARDECODE = groupdecode
|        , DSETIN           = lib.dsin
|        , DSETOUTANNO      = lib.dsout
|        , FORMATS          = 
|        , FRAMEOPTION      = 
|        , FRAMEYN          = Y
|        , HAXISDSET        = lib.axis
|        , HAXISNAME        = axis1
|        , HVAR             = week
|        , LABELS           = VALUE=Value
|        , ROWSPACE         = 0.2
|        , SUBJCOUNTVAR     = value
|        , TEXTOPTION       = color=red height=2
|        , VAXISYN          = Y
|        , UNDERLINEYN      = Y
|        );
|-----------------------------------------------------------------------------------------
| Change Log :
|
| Modified By :           Bob Newman
| Date of Modification :  12th Sep 2006
| New Version Number :    2 Build 1
| Modification ID :       001
| Reason For Modification :  New parameter UNDERLINEYN
|
| Modified By :           Shan Lee
| Date of Modification :  29th Sep 2006
| New Version Number :    2 Build 2
| Modification ID :       SL001
| Reason For Modification :  Made HAXISNAME and HAXISDSET optional parameters.
|
| Modified By :           Shan Lee
| Date of Modification :  17 Jun 2008
| New Version Number :    3 Build 1
| Modification ID :       SL002
| Reason For Modification :  HRT0203 - Use the GASK function instead of GETOPTION to
|                                      retrieve the value of the VPOS option.
|                                      This change is necessary to enable the macro to
|                                      work with SAS version 9.
+---------------------------------------------------------------------------------------*/

%macro tu_drawnumofsubjs(
   COLORLIST           =,                  /* List of colours for each level of &COMPAREVAR */
   COMPAREVAR          =,                  /* Variable name for the vertical axis of the annotation. This will generally be a variable defining treatment groups. */
   COMPAREVARDECODE    =,                  /* Decode for &COMPAREVAR */
   DSETIN              =,                  /* Input dataset */
   DSETOUTANNO         =_subjsanno_,       /* Output annotate dataset name */
   FORMATS             =,                  /* Format definition */
   FRAMEOPTION         =,                  /* Properties of frame including COLOR, SIZE and TYPE */
   FRAMEYN             =N,                 /* Whether or not frame should be drawn around the annotation */
   HAXISDSET           =,                  /* Name of the H AXIS property dataset */
   HAXISNAME           =,                  /* Name of the H AXIS */
   HVAR                =,                  /* Variable name for H axis */
   LABELS              =,                  /* Label definition */
   ROWSPACE            =0.2,               /* Space between row graphs */
   SUBJCOUNTVAR        =,                  /* Variable for number of subjects */
   TEXTOPTION          =,                  /* Properties of label text including COLOR, FONT, HEIGHT and JUSTIFY */
   VAXISYN             =Y,                 /* Whether or not a vertical axis should be drawn */
   UNDERLINEYN         =Y                  /* Whether or not the label should be underlined */ );

   /*
   / N1.Call %tr_putlocals to echo the macro name and version to the log.
   / N2.Call %tu_putglobals to echo the parameter values and values of global macro
   /    variables to the log.
   /------------------------------------------------------------------------------------*/

   %local MacroVersion;
   %let MacroVersion = 3 build 1;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals(varsin=g_dddatasetname g_analy_disp)

   /*
   / Define local macro variables used in the macro.                         	
   /------------------------------------------------------------------------------------*/

   %local
      l_color1 l_color2 l_color3 l_color4 l_color5 l_color6 l_color7 l_color8
      l_color9 l_color10  /* colors for different &comparevar */
      l_compval1 l_compval2 l_compval3 l_compval4 l_compval5 l_compval6 l_compval7
      l_compval8 l_compval9 l_compval10 /* Values of &comparevar */      
      l_footnote1 l_footnote2 l_footnote3 l_footnote4 l_footnote5 l_footnote6 
      l_footnote7 l_footnote8 l_footnote9 l_footnote10 /* footnote */
      l_svtype1 l_svtype2 l_svtype3 l_svtype4 l_svtype5 l_svtype6 l_svtype7 l_svtype8
      l_svtype9 l_svtype10 /* type of &subjcountvar */
      ;
      
   %local
      l_axiswidth      /* Holds the value for the axis width */
      l_compvartype    /* Variable type of &comparevar */
      l_complbllen     /* Length of label created from &COMPAREVAR */
      l_defcolorlist   /* Default color list */
      l_firstfoot      /* The first unblank footnote */
      l_font           /* Font of the text */
      l_footcount      /* number of footnotes */
      l_footfont       /* Font of the footnote */
      l_frameproperty  /* Property list of the frame */
      l_hvartype       /* Variable type of &hvar */
      l_maxcompval     /* Value of formated value of &COMPAREVAR with maximum length */
      l_offsetbegin    /* Holds the value for the offsetbegin */
      l_offsetend      /* Holds the value for the offsetend */
      l_position       /* Position of the text */
      l_position1      /* Position adjustment 1 of the text */
      l_position2      /* Position adjustment 2 of the text */
      l_prefix         /* root name for temp data sets */
      l_property       /* List of text property */
      l_propertylist   /* List of SAS graph text properties */
      l_rowspace       /* Spaces between rows in percentage of graph area */
      l_spaceunit      /* Unit for &l_rowspace before converting to percentage */
      l_subjsize       /* Vertical size for drawing area */
      l_subjvarcount   /* Number of variables in &subjcountvar */
      l_textsize       /* Size of the text */
      l_vinitpos       /* Initial vertical position of the drawing area */
      l_tmp l_tmp1 l_word l_i l_j l_rx
      ;

   %let l_complbllen=0;
   %let l_defcolorlist=red blue green cyan gold pink olive brown purple yellow;
   %let l_firstfoot=1;
   %let l_font=;
   %let l_footcount=0;
   %let l_footfont=;
   %let l_frameproperty=%nrstr(line=1; size=0.2);
   %let l_maxcompval=;
   %let l_position1=A;
   %let l_position2=C;
   %let l_position=B;
   %let l_property=;
   %let l_propertylist=angle cborder cbox color group midpoint subgroup position rotate size style line;
   %let l_rowspace=;
   %let l_spaceunit=;
   %let l_textsize=;
   %let l_vinitpos=0;
   /*
   / N3.Perform parameter validation. After all have been validated, if an error is found
   /    then call %tu_abort.
   /------------------------------------------------------------------------------------*/

   /*
   / C1. Check that none of required parameters are blank.
   /     HAXISNAME and HAXISDSET are optional parameters. SL001
   /-----------------------------------------------------------------------------------*/

   %let l_tmp=COMPAREVAR DSETIN DSETOUTANNO FRAMEYN HVAR ROWSPACE
              SUBJCOUNTVAR VAXISYN UNDERLINEYN;

   %do l_i=1 %to 10;
      %let l_word=%scan(&l_tmp, &l_i);
      %if %nrbquote(&&&l_word) eq %then
      %do;
         %let g_abort=1;
         %put RTE%str(RROR): &sysmacroname: Parameter &l_word is blank and it is required.;
      %end;
   %end; /* %do l_i=1 to 10 */

   /*
   / C2. Check that &DSETIN exists.
   /-----------------------------------------------------------------------------------*/

   %let l_rx=0;
   %if &dsetin NE %then
   %do;
      %if %sysfunc(EXIST(&dsetin)) EQ 0 %then
      %do;
          %put %str(RTE)RROR: &sysmacroname: Dataset DSETIN(=&dsetin) does not exist.;
          %let g_abort=1;
      %end;
      %else %let l_rx=1;
   %end; /* %if &dsetin NE */

   /*
   / C3. Check that &DSETOUTANNO is a valid SAS dataset name.
   /-----------------------------------------------------------------------------------*/

   %if %nrbquote(&dsetoutanno) NE %then
   %do;
      %if %tu_chknames(&dsetoutanno, data) ne  %then
      %do;
          %let g_abort=1;
          %put RTER%str(ROR): &sysmacroname: DSETOUTANNO(=&DSETOUTANNO) is not a valid dataset name;
      %end;
   %end; /* %if %nrbquote(&dsetoutanno) NE */

   /*
   / C4. Check that &FRAMEYN is Y or N. (N is the default).
   /-----------------------------------------------------------------------------------*/

   %let frameyn=%qupcase(&frameyn);
   %if ( &frameyn ne Y ) and ( &frameyn ne N ) %then
   %do;
       %let g_abort=1;
       %put RTER%str(ROR): &sysmacroname: Value of FRAMEYN(=&frameyn) should be either Y or N ;
   %end;

   /*
   / C5. Check that &VAXISYN is Y or N. (Y is the default).
   /-----------------------------------------------------------------------------------*/

   %let vaxisyn=%qupcase(&vaxisyn);
   %if ( &vaxisyn ne Y ) and ( &vaxisyn ne N ) %then
   %do;
       %let g_abort=1;
       %put RTER%str(ROR): &sysmacroname: Value of VAXISYN(=&vaxisyn) should be either Y or N ;
   %end;

   /*
   / C6. Check that &HAXISDSET is an existing SAS dataset.
   /-----------------------------------------------------------------------------------*/

   %if %nrbquote(&haxisdset) NE %then
   %do;
      %if %sysfunc(exist(&haxisdset)) eq 0 %then
      %do;
          %let g_abort=1;
          %put RTER%str(ROR): &sysmacroname: Dataset HAXISDSET(=&HAXISDSET) does not exist ;
      %end;
   %end; /* %if %nrbquote(&haxisdset) NE */

   /*
   / C7. Check that &HAXISNAME in one of AXIS1-AXIS99.
   /-----------------------------------------------------------------------------------*/

   %let haxisname=%qupcase(&haxisname);
   %if &haxisname NE %then
   %do;
      %let l_j=;
      %do l_i=1 %to 99;
           %let l_j=&l_j AXIS&l_i ;
      %end;
      %if %sysfunc(indexw(&l_j, &haxisname)) eq 0 %then
      %do;
           %put %str(RTE)RROR: &sysmacroname: The value HAXISNAME(=&haxisname) is not valid.;
           %let g_abort=1;
      %end;
   %end; /* %if %nrbquote(&haxisname) NE */

   /*
   / C8. Check that &HVAR and &COMPAREVAR exist on &DSETIN.
   /-----------------------------------------------------------------------------------*/

   %if ( %nrbquote(&comparevar) ne ) and &l_rx %then
   %do;
      %if %tu_chkvarsexist(&dsetin,&comparevar) ne  %then
      %do;
          %let g_abort=1;
          %put RTER%str(ROR): &sysmacroname: COMPAREVAR(=&COMPAREVAR) does not exist in DSETIN(=&dsetin);
      %end;
   %end; /* %nrbquote(&comparevar) and &l_rx */

   %if ( %nrbquote(&hvar) ne ) and &l_rx %then
   %do;
      %if %tu_chkvarsexist(&dsetin,&hvar) ne  %then
      %do;
          %let g_abort=1;
          %put RTER%str(ROR): &sysmacroname: HVAR(=&HVAR) does not exist in DSETIN(=&dsetin);
      %end;
   %end; /* %nrbquote(&comparevar) and &l_rx */

   /*
   / C9. If given, check that &COMPAREVARDECODE exists on &DSETIN.
   /-----------------------------------------------------------------------------------*/

   %if ( %nrbquote(&COMPAREVARDECODE) ne ) and &l_rx %then
   %do;
      %if %tu_chkvarsexist(&dsetin,&COMPAREVARDECODE) ne  %then
      %do;
          %let g_abort=1;
          %put RTER%str(ROR): &sysmacroname: COMPAREVARDECODE(=&COMPAREVARDECODE) does not exist in DSETIN(=&dsetin);
      %end;
   %end; /* %if %nrbquote(&COMPAREVARDECODE) ne */

   /*
   / C10. Check that &ROWSPACE is a number with a valid unit.
   /-----------------------------------------------------------------------------------*/

   %if ( &rowspace NE ) %then
   %do;
      %let l_i=%verify(&rowspace,'0123456789.');
      %if &l_i gt 1 %then %do;
         %let l_spaceunit=%substr(&rowspace, &l_i);
         %let l_rowspace=%substr(&rowspace, 1, %eval(&l_i - 1));

         %if ( %qupcase(&l_spaceunit) ne CELLS ) AND ( %qupcase(&l_spaceunit) ne IN )  AND
             ( %qupcase(&l_spaceunit) ne PCT )   AND ( %qupcase(&l_spaceunit) ne PCT ) AND
             ( %qupcase(&l_spaceunit) ne CM )  
         %then %let l_rowspace=;
      %end;
      %else %do;
         %let l_rowspace=&rowspace;
      %end;

      %if %nrbquote(&l_rowspace) eq %then
      %do;
          %put %str(RTE)RROR: &sysmacroname: Value of ROWSPACE (=&rowspace) is not a number with unit (CELLS, IN, CM, PT, or PCT).;
          %let g_abort=1;
      %end;
   %end; /* %if ( &rowspace NE ) */

   /*
   / C11. Check that &SUBJCOUNTVAR exists on &DSETIN.
   /-----------------------------------------------------------------------------------*/

   %if %nrbquote( &subjcountvar ) NE %then
   %do;
      %if %tu_chkvarsexist(&dsetin,&subjcountvar) ne  %then
      %do;
          %let g_abort=1;
          %put RTER%str(ROR): &sysmacroname: SUBJCOUNTVAR(=&SUBJCOUNTVAR) does not exist in DSETIN(=&dsetin);
      %end;
   %end;

   /*
   /  Check that &UNERLINEYN is Y or N. (Y is the default).
   /-----------------------------------------------------------------------------------*/

   %let underlineyn=%qupcase(&underlineyn);
   %if ( &underlineyn ne Y ) and ( &underlineyn ne N ) %then
   %do;
       %let g_abort=1;
       %put RTER%str(ROR): &sysmacroname: Value of UNDERLINEYN(=&underlineyn) should be either Y or N ; 
   %end;
   
   /*
   / C12. If errors are found, set g_abort and call %tu_abort.
   /-----------------------------------------------------------------------------------*/

   %if &g_abort gt 0 %then %goto macerr;

   /* NORMAL PROCESS */

   /*
   / N4.Set work dataset prefix to _drawnumofsubjs
   /-----------------------------------------------------------------------------------*/

   %let l_prefix = _drawnumofsubjs;
   %let l_subjvarcount=%tu_words(&subjcountvar);
   
   /*
   / N5. If &LABELS is not blank, apply it to the input dataset (&DSETIN).
   / N6. If &FORMATS is not blank, apply it to the input dataset (&DSETIN).
   /-----------------------------------------------------------------------------------*/

   %if %nrbquote(&labels.&formats) ne %then
   %do;
      data &l_prefix.dsetin;
         set &dsetin;
         %if %nrbquote(&formats) ne %then
         %do;
            format &formats ;
         %end;
         %if %nrbquote(&labels) ne %then
         %do;
            label &labels ;
         %end;
      run;
      %let dsetin=&l_prefix.dsetin;
   %end; /* %if %nrbquote(&labels.&formats) */

   /*
   / N7. Sort &DSETIN by &COMPAREVAR.
   /-----------------------------------------------------------------------------------*/

   proc sort data=&dsetin out=&l_prefix.dsetinsort;
      by &comparevar;
      where not missing(&comparevar);
   run;

   %let dsetin=&l_prefix.dsetinsort;

   /*
   / Finding out H positions. &HVAR is a numeric variable, the value of H axis MAJOR
   / may not match value with &HVAR in &dsetin. Adjust value of &HVAR to the nearest
   / value of H axix MAJOR which is great than or equal to the orignial &HVAR value
   /-----------------------------------------------------------------------------------*/

   data _null_;
      if 0 then set &dsetin;
      call symput('l_hvartype', vtype(&hvar));
      %do l_i=1 %to &l_subjvarcount;
         call symput("l_svtype&l_i", vtype(%scan(&subjcountvar, &l_i)));
      %end;
      call symput('l_compvartype', vtype(&comparevar));
   run;

   %if ( &l_hvartype eq N ) and ( %nrbquote(&haxisdset) ne ) %then
   %do;
      proc sort data=&haxisdset out=&l_prefix.hdset (keep=varvalue tickvalue) nodupkey;
         where upcase(name) eq "&haxisname" ;
         by varvalue;
      run;
      %if %tu_nobs(&l_prefix.hdset) le 0 %then %let haxisdset=;
   %end;   

   %if ( &l_hvartype eq N ) and ( %nrbquote(&haxisdset) ne ) %then
   %do;      
      data &l_prefix.hdsetrg;
         set &l_prefix.hdset;
         if not missing(tickvalue);
         newvarvalue=input(varvalue, best.);
         prevarvalue=lag(newvarvalue);
      run;

      proc sort data=&dsetin out=&l_prefix.comp(keep=&comparevar &comparevardecode) nodupkey;
         by &comparevar &comparevardecode;
      run;

      proc sql noprint;
         create table &l_prefix.hdsetrg1 as (
         select a.*, b.*
           from &l_prefix.hdsetrg as a, &l_prefix.comp as b )
           order by &comparevar, %if %nrbquote(&comparevardecode) ne %then &comparevardecode,; newvarvalue
           ;
         create table &l_prefix.dsetinvarvalue as (
         select a.*, b.newvarvalue as __varvalue__
           from &dsetin as a, &l_prefix.hdsetrg1 as b
          where ( a.&hvar gt b.prevarvalue )
            and ( a.&hvar le b.newvarvalue )
            and ( a.&comparevar eq b.&comparevar ))
          order by &comparevar, %if %nrbquote(&comparevardecode) ne %then &comparevardecode,; __varvalue__, &hvar
          ;
      quit;
      
      data &l_prefix.varvalue;
         set &l_prefix.dsetinvarvalue;
         by &comparevar &comparevardecode __varvalue__ &hvar;
         drop __varvalue__;
         &hvar=__varvalue__;
         if last.__varvalue__;
      run;
    
      data &l_prefix.varvalue;
         merge &l_prefix.varvalue &l_prefix.hdsetrg1(rename=(newvarvalue=&hvar));
         by &comparevar &comparevardecode &hvar;
         
         %do l_i=1 %to &l_subjvarcount;
            retain __temp__&l_i;
            drop __temp__&l_i;
            if first.%scan(&comparevar, 1) then __temp__&l_i=%scan(&subjcountvar, &l_i);
            else if not missing(%scan(&subjcountvar, &l_i)) then __temp__&l_i=%scan(&subjcountvar, &l_i);
            else %scan(&subjcountvar, &l_i)=__temp__&l_i;
         %end; /* %do l_i=1 */
      run;

      %let dsetin=&l_prefix.varvalue;
   %end; /*  %if ( &l_hvartype eq N ) and ( %nrbquote(&haxisdset) ne ) */ 
   
   /*
   / Get unique value of &subjcountvar per &comparevar &hvar from &DSETIN
   /-----------------------------------------------------------------------------------*/

   proc sort data=&dsetin out=&l_prefix.sort(keep=&hvar &comparevar &comparevardecode &subjcountvar) nodupkey;
      by &comparevar &hvar;
   run;

   %let dsetin=&l_prefix.sort;
   
   /* Data set is empty. Nothing to draw */
   %if %tu_nobs(&dsetin) le 0 %then 
   %do;
      data &dsetoutanno;
         set &dsetin;
      run;
      %goto macend;    
   %end;

   /*
   / N8. Get offset, length, and major tick positions of HAXIS from &HAXISDSET.  Locate
   /     observations in &HAXISDSET where the variable NAME is &HAXISNAME, and get the
   /     values of:
   /-----------------------------------------------------------------------------------*/

   %if %nrbquote(&haxisdset) ne %then
   %do; 
      proc sql noprint;
         select offsetbegin, offsetend, width
           into :l_offsetbegin, :l_offsetend, :l_axiswidth
           from &haxisdset
          where upcase(name) eq "&haxisname" ;
      quit;
   %end;

   /*
   / N9. Get the levels of &COMPAREVAR
   /----------------------------------------------------------------------*/

   %let l_compcount=1;
   %if %nrbquote(&comparevar) ne %then
   %do;
      proc sort data=&dsetin out=&l_prefix.comp (keep=&comparevar &comparevardecode) nodupkey;
         by &comparevar;
      run;

      data _null_;
         set &l_prefix.comp end=end;
         length  tt_maxlengthcomparevar tt_newmaxlengthcomparevar $400;
         retain  tt_maxlengthcomparevar "";
         %if &l_compvartype eq C %then
            call symput(compress('l_compval'||put(_n_, 6.0)), "'"||trim(left(&comparevar))||"'");
         %else
            call symput(compress('l_compval'||put(_n_, 6.0)), trim(left(put(&comparevar, best.))));;

         /* Get formated value of &comparevardecode or &comparevar with maximum length */
         %if %nrbquote(&comparevardecode) ne %then
         %do;
            tt_newmaxlengthcomparevar=left(putc(&comparevardecode, vformat(&comparevardecode)));
         %end;
         %else %do;
            %if &l_compvartype eq C %then
            %do;
               tt_newmaxlengthcomparevar=left(putc(&comparevar, vformat(&comparevar)));
            %end;
            %else %do;
               tt_newmaxlengthcomparevar=left(putn(&comparevar, vformat(&comparevar)));
            %end;
         %end; /* %if %nrbquote(&comparevardecode) ne */

         if length(tt_newmaxlengthcomparevar) gt length(tt_maxlengthcomparevar) then
            tt_maxlengthcomparevar=tt_newmaxlengthcomparevar;

         if end then
         do;
            call symput('l_compcount', put(_n_, 6.0));
            call symput('l_maxcompval', trim(left(tt_maxlengthcomparevar)));
         end;
      run;
   %end; /* %if %nrbquote(&comparevar) ne */

   /*   Setting the colors based on the levels   */
   %if %nrbquote(&colorlist) eq %then
   %do;
      %let colorlist=%sysfunc(getoption(CTEXT));
   %end;

   %if %nrbquote(&colorlist) eq %then
   %do;
      %let colorlist=&l_defcolorlist;
   %end;

   %let l_i=1;
   %let l_tmp=%scan(&colorlist, &l_i, %str( ));
   %do %while (%nrbquote(&l_tmp) ne );
      %let l_color&l_i=&l_tmp;
      %let l_i=%eval(&l_i + 1);
      %let l_tmp=%scan(&colorlist, &l_i, %str( ));
   %end;

   %let l_i=%eval(&l_i - 1);
   %do l_j=%eval(&l_i + 1) %to &l_compcount;
       %let l_color&l_j=&&l_color&l_i;
   %end;

   /*
   / N11.Get the text properties: Colour, Font and Height, from the Global
   /     Options. If any property is given in the global options, and is
   /     not in &TEXTOPTION, then add that property to &TEXTOPTION.
   /------------------------------------------------------------------------*/

   %if %nrbquote(&textoption) ne %then
   %do l_k=1 %to 12;
      %let l_word=%scan(&l_propertylist,&l_k);
      %let l_tmp=%tu_getproperty(equalsignyn=Y,keyword=&l_word,propertylist=&textoption);      
      %if %nrbquote(&l_tmp) ne %then
      %do;
         %if %upcase(&l_word) eq POSITION %then %let l_position=%upcase(&l_tmp);
         %if %upcase(&l_word) eq STYLE %then %let l_font=%upcase(&l_tmp);
         %if %upcase(&l_word) eq SIZE %then %let l_textsize=&l_tmp;
         %else %if %sysfunc(indexw(ROTATE ANGLE SIZE LINE, %upcase(&l_word))) %then
            %let l_property=&l_word=&l_tmp %nrstr(;) %nrbquote(&l_property);
         %else
            %let l_property=&l_word="&l_tmp" %nrstr(;) %nrbquote(&l_property);
      %end;
   %end; /* %do l_k=1 %to 12 */

   /* default style is NONE */
   %if %sysfunc(indexw(%qupcase(&l_property), STYLE)) lt 1 %then
   %do;
      %let l_tmp=%sysfunc(getoption(FTEXT));
      %let l_k=%index(%qupcase(&l_tmp), DEFAULT);          
      %if &l_k gt 1 %then %let l_tmp=%substr(&l_tmp, 1, %eval(&l_k - 1));      
      %if %nrbquote(&l_tmp) eq %then %let l_tmp=NONE;
      %let l_property=%nrbquote(&l_property) %nrstr(;) style="&l_tmp";
   %end; /* %if %sysfunc(indexw(%qupcase(&l_property), STYLE)) lt 1 */

   %if %sysfunc(indexw(%qupcase(&l_property), POSITION)) lt 1 %then
   %do;
      %let l_property=%nrbquote(&l_property) %nrstr(;) position="&l_position";
   %end; /* %if %sysfunc(indexw(%qupcase(&l_property), POSITION)) lt 1 */

   /* font for footnote */
   %let l_footfont=%sysfunc(getoption(FTEXT));
   %let l_k=%index(%qupcase(&l_footfont), DEFAULT);
   %if &l_k gt 1 %then %let l_footfont=%substr(&l_footfont, 1, %eval(&l_k - 1));
   %if %nrbquote(&l_footfont) eq %then %let l_footfont=SWISS;
   %if %nrbquote(&l_font) eq %then %let l_font=&l_footfont;

   /*
   /  Get the frame properties: line size from &FRAMEOPTION.
   /------------------------------------------------------------------------*/

   %if %nrbquote(&frameoption) ne %then
   %do l_k=1 %to 12;
      %let l_word=%scan(&l_propertylist,&l_k);
      %let l_tmp=%tu_getproperty(equalsignyn=Y,keyword=&l_word,propertylist=&frameoption);
      %if %nrbquote(&l_tmp) ne %then
      %do;
         %if %sysfunc(indexw(SIZE ROTATE ANGLE LINE, %upcase(&l_word))) %then
            %let l_frameproperty=&l_word=&l_tmp %nrstr(;) %nrbquote(&l_frameproperty);
         %else
            %let l_frameproperty=&l_word="&l_tmp" %nrstr(;) %nrbquote(&l_frameproperty);
      %end;
   %end; /* %do l_k=1 %to 12 */

   /* default size is 0.2 */
   %if %sysfunc(indexw(%qupcase(&l_frameproperty), SIZE)) lt 1 %then
   %do;
      %let l_frameproperty=%nrbquote(&l_frameproperty) %nrstr(;) size=0.2;
   %end;
   %if %sysfunc(indexw(%qupcase(&l_frameproperty), LINE)) lt 1 %then
   %do;
      %let l_frameproperty=%nrbquote(&l_frameproperty) %nrstr(;) line=1;
   %end;
   %if %sysfunc(indexw(%qupcase(&l_frameproperty), COLOR)) lt 1 %then
   %do;
      %let l_frameproperty=%nrbquote(&l_frameproperty) %nrstr(;) color=BLACK;
   %end;

   /* Get number of footnotes */
   proc sql noprint;
      select max(number) into :l_footcount
      from sashelp.vtitle
      where upcase(type) eq 'F';
      select min(number) into :l_firstfoot
      from sashelp.vtitle
      where ( upcase(type) eq 'F' ) and ( not missing(text)) ;
   quit;

   %if %nrbquote(&l_footcount) eq %then %let l_footcount=0;
   %if %nrbquote(&l_firstfoot) eq %then %let l_firstfoot=0;
   %if &l_firstfoot eq 0 %then %let l_firstfoot=%eval(&l_footcount + 1);
   
   /* read in footnote */
   %tu_getgstatements(
      dsetout=&l_prefix.axis,
      statements=FOOTNOTE
   );    

   data _null_;
      set &l_prefix.axis;
      where type eq 'F';
      call symput('l_'||compress(name), trim(text));
   run;      
   
   /*
   / Change the text size to percent of graph area. Default text size is 10 pt.
   / N10.Calculate the V positions for each level of &COMPAREVAR, from bottom up.
   /     The font size, &ROWSPACE, and the label should be taken into account.
   /---------------------------------------------------------------------------------*/
   
   data _null_;
      length unit gunit ornt tsize defunit pos1 pos2 lspace font $20
             property $500 vpos nvsize ntextsize 8;
      property=''; 
      font='';
      ornt=upcase(substr(getoption('orientation'), 1, 1));
      gunit=getoption('gunit');

      /*
      / SL002
      / Use GASK to retrieve the value of VPOS - in version 9, getoption will return
      / a blank value for VPOS whenever VPOS has not been explicitly assigned a value
      / via GOPTIONS. 
      /------------------------------------------------------------------------------*/
      rc = ginit();
      call gask('VPOS', vpos, rc);
      rc  = gterm();

      if missing(VPOS) then vpos=getoption('PCOLS');
      /* Convert VSIZE to percent of graph area */
      tsize=getoption('vsize');
      if missing(tsize) then tsize=getoption('YMAX') - getoption('BOTTOMMARGIN')- getoption('TOPMARGIN');
      link unitconv;
      nvsize=ntsize;

      /* Convert text size to percent of graph area */
      tsize=left(symget('l_textsize'));
      lspace=tsize;
      link unitconv;
      link topct;
      ntextsize=ntsize;
      call symput('l_textsize', put(ntextsize, best.));

      /* Maximum text extent of &comparevar */
      tsize=lspace;
      link unitconv;
      link todefu;
      x=0 ; y=0;
      rc = ginit();
      rc = gset('texheight', ntsize);      
      rc = gset('texfont',upcase("&l_font"));
      call gask('texextent', x, y,"&l_maxcompval.",xend,yend,x1,ntsize,x3,x4,y1,y2,y3,y4,rc);
      rc  = gterm();
      tsize=put(ntsize, best.)||left(defunit);
      link unitconv;
      link topct;
      ntsize=ntsize + 0.2;
      call symput('l_complbllen', put(ntsize, best.));

      /* Adjust &ROWSPACE to percent of graph area */
      tsize=trim(left(symget('l_rowspace')))||trim(left(symget('l_spaceunit')));
      link unitconv;
      link topct;

      call symput('l_rowspace', put(ntsize, best.));
      rowspace=ntsize;

      /* Calculation the initial position of the drawing area */
      vinit=0;
      select(upcase(symget('l_position')));
         when('1') do; pos0=1;    pos1='1'; pos2='3'; end;
         when('2') do; pos0=1;    pos1='1'; pos2='3'; end;
         when('3') do; pos0=1;    pos1='1'; pos2='3'; end;
         when('4') do; pos0=0;    pos1='4'; pos2='6'; end;
         when('5') do; pos0=0;    pos1='4'; pos2='6'; end;
         when('6') do; pos0=0;    pos1='4'; pos2='6'; end;
         when('7') do; pos0=-1;   pos1='7'; pos2='9'; end;
         when('8') do; pos0=-1;   pos1='7'; pos2='9'; end;
         when('9') do; pos0=-1;   pos1='7'; pos2='9'; end;
         when('A') do; pos0=0.5;  pos1='A'; pos2='C'; end;
         when('B') do; pos0=0.5;  pos1='A'; pos2='C'; end;
         when('C') do; pos0=0.5;  pos1='A'; pos2='C'; end;
         when('D') do; pos0=-0.5; pos1='D'; pos2='F'; end;
         when('E') do; pos0=-0.5; pos1='D'; pos2='F'; end;
         when('F') do; pos0=-0.5; pos1='D'; pos2='F'; end;
      end; /* select(upcase(symget('l_position'))) */

      call symput('l_position1', pos2);
      call symput('l_position2', pos1);

      vinit=(-1) * pos0;
      if vinit lt 0 then vinit=0;
      tsize=put(vinit, best.)||'CELLS';
      link unitconv;
      vinit=ntsize;
      /* Count the spaces for footnotes */      
      %do l_i=&l_firstfoot %to &l_footcount;
         %if %nrbquote(&&l_footnote&l_i) ne %then
         %do;
            tsize="%tu_getproperty(equalsignyn=Y,keyword=LSPACE,propertylist=&&l_footnote&l_i)";
            if missing(lspace) then
               tsize="%tu_getproperty(equalsignyn=Y,keyword=LS,propertylist=&&l_footnote&l_i)";
            property=symget("l_footnote&l_i");
            link addunit;
            lspace=tsize;
            tsize="%tu_getproperty(equalsignyn=Y,keyword=HEIGHT,propertylist=&&l_footnote&l_i)";
            if missing(tsize) then
               tsize="%tu_getproperty(equalsignyn=Y,keyword=H,propertylist=&&l_footnote&l_i)";
            property=symget("l_footnote&l_i");   
            link addunit;
            font="%tu_getproperty(equalsignyn=Y,keyword=FONT,propertylist=&&l_footnote&l_i)";
            if missing(font) then
               lspace="%tu_getproperty(equalsignyn=Y,keyword=F,propertylist=&&l_footnote&l_i)";
         %end; /* %if %nrbquote(&&l_footnote&l_i) ne */
         %else %do;
            tsize="";
         %end;
         if missing(tsize) then tsize=getoption('HTEXT');
         if missing(tsize) then tsize='1CELLS';
         if missing(lspace) then lspace='1CELLS';
         if missing(font) then font="&l_footfont";
         link unitconv;
         link todefu;
         x=0 ; y=0;
         rc = ginit();
         rc = gset('texheight', ntsize);
         font=trim(left(upcase(font)));
         rc = gset('texfont', font);         
         call gask('texextent', x, y,"This is a test QqWwVvJj",xend,yend,x1,x2,x3,x4,y1,y2,y3,ntsize,rc);
         rc  = gterm();
         tsize=put(ntsize, best.)||left(defunit);
         link unitconv;
         nlspace=ntsize;
         tsize=lspace;
         link unitconv;
         ntsize=ntsize + nlspace;
         link topct;
         vinit=vinit + ntsize;         
      %end; /* %do l_i=&l_firstfoot %to &l_footcount */
      /* Add one CELL space above the footer */
      tsize='1CELLS';
      link unitconv;
      link topct;
      /*
      vinit=vinit + ntsize;
      */
      /* Add one CELL for frame */
      %if &FRAMEYN eq Y %then
      %do;
         vinit=vinit + ntsize;
      %end;

      if vinit lt 0 then vinit=0;
      call symput('l_vinitpos', put(vinit, best.));
      vinit=( &l_compcount * &l_subjvarcount + 1) * ( ntextsize + rowspace) + 0.4;
      vinit=vinit * nvsize / 100;
      call symput('l_subjsize', compress(put(vinit, 12.2)));
      return;

   /* Add Unit to title and foot height */   
   ADDUNIT:     
      if indexw(upcase(property), 'PT')          then tsize=trim(tsize)||'PT';
      else if indexw(upcase(property), 'PCT')    then tsize=trim(tsize)||'PCT';
      else if indexw(upcase(property), 'CM')     then tsize=trim(tsize)||'CM';
      else if indexw(upcase(property), 'IN')     then tsize=trim(tsize)||'IN';
      else if indexw(upcase(property), 'INCHES') then tsize=trim(tsize)||'IN';
      else if indexw(upcase(property), 'CELLS')  then tsize=trim(tsize)||'CELLS';            
      return;
      
      /* Unit conversion. Convert to CM */
   UNITCONV:
      if missing(tsize) then tsize=getoption('htext');
      if missing(tsize) then tsize="10pt";
      tsize=left(tsize);
      tsize=left(scan(tsize, 1, '()'));
      ind=verify(tsize, '1234567890. ');
      ntsize=0;
      if ind gt 1 then
      do;
         unit=substr(tsize, ind);
         tsize=substr(tsize, 1, ind - 1);
         ntsize=input(tsize, best.);
      end;
      else do;
         ntsize=input(tsize, best.);
         unit=gunit;
         if missing(unit) then unit='CELLS';
      end;
      unit=upcase(left(unit));
      if      substr(unit, 1, 2) eq 'IN'    then ntsize=ntsize * 2.54;
      else if substr(unit, 1, 2) eq 'PT'    then ntsize=ntsize * 2.54 / 72;
      else if substr(unit, 1, 3) eq 'PCT'   then ntsize=ntsize * nvsize / 100;      
      else if unit               eq 'CELLS' then ntsize=ntsize * nvsize / vpos;
      return;

   /* Convert to def unit */
   TODEFU:
      if missing(defunit) then defunit=left(getoption('htext'));      
      ind=verify(defunit, '1234567890. ');
      if ind gt 1 then defunit=substr(defunit, ind);
      else defunit='';      
      if missing(defunit) then defunit=gunit;
      if missing(defunit) then defunit='CELLS';
      defunit=left(upcase(defunit));
      if      substr(defunit, 1, 2) eq 'IN'  then ntsize=ntsize / 2.54;
      else if substr(defunit, 1, 2) eq 'PT'  then ntsize=ntsize * 72 / 2.54;
      else if substr(defunit, 1, 3) eq 'PCT' then ntsize=ntsize * 100 / nvsize;
      else if defunit='CELLS' then ntsize=ntsize * vpos / nvsize;
      return;

   /* Convert to percent of graphic area */
   TOPCT:
      ntsize=ntsize * 100 / nvsize;
      if ntsize gt 100 then ntsize=100;
      return;
   run;

   %let l_property=&l_property %nrstr(;) size=%sysfunc(sum(0, &l_textsize));

   /*
   / N12.Create the annotate dataset.
   /------------------------------------------------------------------------------------*/
   
   data &l_prefix.anno;   
      length function $8 text $200  x 8. y 8.;
      length cborder cbox color group subgroup style $8 position $1;
      set &dsetin;
      by &comparevar;
      retain xsys '2' ysys '3' hsys '3';
      group='';
      subgroup='';
      cbox='';
      cborder='';

      /*
      / N12.d. Draw a label above the vertical axis. This label should be from the
      /        label of the variable &SUBJCOUNTVAR. The label should be left justified.
      /---------------------------------------------------------------------------------*/

      if _n_ eq 1 then
      do;
         /* draw axis label */
         function='label'; xsys='5'; ysys="3"; hsys='3'; x=0;
         y=&l_vinitpos + &l_compcount * &l_subjvarcount * ( &l_textsize + &l_rowspace ) + 0.4;
         %unquote(&l_property);
         color=getoption('CTEXT');
         if missing(color) then color='Black';
         position="&l_position1";

         /* draw underscore below the label if required */
         text=left(vlabel(%scan(&subjcountvar, 1)));
         if length(text) gt 0 and &underlineyn = Y 
         then text=repeat("5F"x, length(text)); 
         output;
         text=left(vlabel(%scan(&subjcountvar, 1)));
         output;
      end;

      %do l_i=1 %to &l_compcount;
         if upcase(left(&comparevar)) eq
            %if &l_compvartype eq C %then
            %do;
               &&l_compval&l_i
            %end;
            %else %do;
               upcase(left("&&l_compval&l_i"))
            %end; then
         do;
            color="&&l_color&l_i";

      /*
      / N12.a. Draw tick text for the vertical axis. The text values are the values
      /        of &COMPAREVAR. &TEXTOPTION should be applied.
      / N12.b. If &VAXISYN equals Y, include an annotate statement to draw a vertical
      /        axis.  (tick mark)
      /---------------------------------------------------------------------------------*/

            if first.&comparevar then
            do;
               function='label'; xsys='5'; ysys="3"; hsys='3'; x=0;
               %unquote(&l_property);
               y=&l_vinitpos + ( &l_compcount * &l_subjvarcount - %eval(&l_i - 1) * &l_subjvarcount - 1 ) * ( &l_textsize + &l_rowspace );
               %if %nrbquote(&comparevardecode) ne %then
               %do;                             
                  text=left(putc(&comparevardecode, vformat(&comparevardecode)));
               %end;
               %else %do;
                  %if &l_compvartype eq C %then
                  %do;
                     text=left(putc(&comparevar, vformat(&comparevar)));
                  %end;
                  %else %do;
                     text=left(putn(&comparevar, vformat(&comparevar)));
                  %end;
               %end; /* %if %nrbquote(&comparevardecode) ne */
               position="&l_position1";
               output;
               /* Draw tick mark */
               %if &VAXISYN eq Y %then
               %do;
                  y=y + &l_textsize / 2 ;
                  xsys='1'; ysys="3"; hsys='3';
                  function='move'; x=0;
                  output;
                  %unquote(&l_frameproperty);
                  xsys='5'; ysys="3"; hsys='3'; size=2;
                  function='draw'; x=&l_complbllen;
                  output;
               %end;
            end; /* if fist.&comparevar */

       /*
      / N12.c. Draw subject numbers. The values come from &SUBJCOUNTVAR and the
      /        positions are decided by &HVAR. &COLORLIST and &TEXTOPTION should be
      /        applied if they are provided.
      /---------------------------------------------------------------------------------*/
            color="&&l_color&l_i";
            function='label'; xsys='2'; ysys="3"; hsys='3'; 
            %if &l_hvartype eq N %then x=&hvar;
            %else xc=&hvar;;
            %unquote(&l_property);
            %do l_j=1 %to &l_subjvarcount;
               %if &&l_svtype&l_j eq C %then
               %do;
                  text=left(%scan(&subjcountvar, &l_j));
               %end;
               %else %do;
                  text=left(put(%scan(&subjcountvar, &l_j), best.));
               %end;
               y=&l_vinitpos + ( &l_compcount * &l_subjvarcount - %eval(&l_i - 1) * &l_subjvarcount - &l_j ) * ( &l_textsize + &l_rowspace ) ;
               output;
            %end; /* %do l_j=1 %to &l_subjvarcount */
         end;
      %end; /* %do l_i=1 %to &gl_compcount */


      /*
      / N12.e. If &FRAMEYN equals Y draw a frame around the annotation. &FRAMEOPTION
      /        should be applied.
      / N12.b. If &VAXISYN equals Y, include an annotate statement to draw a vertical
      /        axis. (Vertical line only)
      /---------------------------------------------------------------------------------*/

      %if ( &FRAMEYN eq Y ) or ( &VAXISYN eq Y ) %then
      %do;
         if _n_ eq 1 then
         do;
            xsys='1'; ysys="3"; hsys='3';
            function='move'; x=0;   y=&l_vinitpos;
            output;           
            size=2;
            %unquote(&l_frameproperty);
            function='draw'; x=0;   y=&l_vinitpos + &l_compcount * ( &l_textsize + &l_rowspace );
            output;
            %if &FRAMEYN eq Y %then
            %do;             
               function='draw'; x=100;
               output;
               function='draw'; x=100; y=&l_vinitpos - &l_rowspace / 2;
               output;
               function='draw'; x=0;
               output;
            %end;
         end; /* if _n_ eq 1 */
      %end;  /* %if ( &FRAMEYN eq Y ) or ( &VAXISYN eq Y ) */
   run;

   /* Call tu_labelvars to assign labels for the new variables in the dataset */

    %tu_labelvars(
       dsetin   =&l_prefix.anno,
       dsetout  =&l_prefix.annolabel,
       style    =STD
       );

   /* Setting  label to Annotate dataset */

   data &dsetoutanno(label="Output data set created by &sysmacroname");
       set &l_prefix.annolabel ;
   run; 

   /*
   / N13. Add a new footnote with blank string
   /------------------------------------------------------------------------------------*/
   
   %if &l_footcount eq 0 %then
   %do;
      footnote j=l h=&l_subjsize.CM " ";
   %end;
   %else %if &l_firstfoot eq 1 %then
   %do;
      footnote1 j=l h=&l_subjsize.CM " ";
      %do l_i=&l_firstfoot %to &l_footcount;
         %let l_j=%eval(&l_i + 1);
         %if %nrbquote(&&l_footnote&l_i) ne %then
         %do;
            footnote&l_j &&l_footnote&l_i;
         %end;
         %else %do;
            proc sql noprint;
               select text into :l_tmp
               from sashelp.vtitle
               where type='T' and number=&l_i;
            quit;
            footnote&l_j "&l_tmp";
         %end;
      %end; /* %do l_i=&l_firstfoot %to &l_footcount */
   %end; /* %else %if &l_firstfoot eq 1 */

   %goto macend;

%MACERR:

   %let g_abort=1;
   %tu_abort(
      option=force
      );

   /*
   / N14. Call %tu_tidyup to delete temporary datasets.
   /------------------------------------------------------------------------------------*/

%MACEND:

   %tu_tidyup(
       glbmac=none,
       rmdset=&l_prefix:
      );

%mend tu_drawnumofsubjs;

