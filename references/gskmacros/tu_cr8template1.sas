/*******************************************************************************
|
| Macro Name:      tu_cr8template1
|
| Macro Version:   1
|
| SAS Version:     8.2
|                                                             
| Created By:      James McGiffen / Andrew Ratcliffe, RTSL
|
| Date:            13-Dec-2004
|
| Macro Purpose:   To create a template with panes suitable for 
|                  creating output with one plot on each page. Panes
|                  shall be provided for header/footer, by-line, legend,
|                  and plot. The first three shall be the full size of
|                  the display. The latter shall be sized to fit the 
|                  available/specified space.
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME            DESCRIPTION                           REQ/OPT  DEFAULT
| --------------  -----------------------------------   -------  ---------------
|
| TC              Specifies the output graphic catalog    REQ    [blank]
|                                                                
| TEMPLATE        Specifies the name of the template      REQ    [blank]
|
| TOPY            Specifies the highest point of Y (%)    REQ    80
|
| BOTY            Specifies the lowest point of Y (%)     REQ    20
|
| FRAMEPAGE       Place frame around page?                REQ    N
|
| FRAMEPLOT       Place frame around plot?                REQ    N
|
| --------------  -----------------------------------   -------  ---------------
|
| Output: A template catalog entry
|
| Global macro variables created: NONE
|
| Macros called:
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_chknames
| (@) tu_putglobals
| (@) tu_tidyup
| (@) tu_words
|
| Example:
|    %tu_cr8template1(topy=95
|                    ,boty=10
|                    ,tc=work.templates_cat4tplts
|                    ,template=reptools
|                    ,framePage=N
|                    ,framePlot=N
|                   );
|
|******************************************************************************
| Change Log
|
| Modified By:              Trevor Welby
| Date of Modification:     06-May-05
| New version/draft number: 01-002
| Modification ID:          TQW9753.01-002
| Reason For Modification:  
|                           Changed the code to comply with HARP RT Programming
|                           Standards
|
|                           %local i removed
|
|                           Removed the use of %substr function on framePage and 
|                           framePlot parameters in the parameter validation 
|                           section
|
|                           Added comments to validation section 
|
|                           Augmented the validation of TC and TEMPLATE parameters
|                           so that multiple catalog names/ entries are not accepted
|                           as valid input
|
*******************************************************************************
|
| Modified By:
| Date of Modification:
| New version/draft number:
| Modification ID:
| Reason For Modification:
|
*******************************************************************************/
%macro tu_cr8template1(TC=          /* Specifies the output graphic catalog */
                      ,TEMPLATE=    /* Specifies the name of the template   */
                      ,TOPY=80      /* Specifies the highest point of Y (%) */
                      ,BOTY=20      /* Specifies the lowest point of Y (%)  */
                      ,framePage=N  /* Place frame around page?             */
                      ,framePlot=N  /* Place frame around plot?             */
                      );

  /* Echo parameter values and global macro variables to the log */
  %local MacroVersion;
  %let MacroVersion=1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals();
  
  %local prefix;
  %let prefix=%substr(&sysmacroname.,3); 

  /* PARAMETER VALIDATION */

  %let TC=%nrbquote(&TC.);
  %let TEMPLATE=%nrbquote(&TEMPLATE.);
  %let TOPY=%nrbquote(&TOPY.);
  %let BOTY=%nrbquote(&BOTY.);
  %let framePage=%nrbquote(%upcase(&framePage.));
  %let framePlot=%nrbquote(%upcase(&framePlot.));
  
  /* Check for required parameters */

  /*-- check that tc has a value*/
  %if &tc. eq %then 
  %do;  /* TC is blank */
    %put %str(RTE)RROR: &sysmacroname.: The TC parameter must not be blank;
    %let g_abort=1;
  %end;  /* TC is blank */
  %else
  %do;  /* TC is not blank */
   /* Check that name is two-level */
    %if %length(%scan(&tc,2,.)) eq 0 or %length(%scan(&tc,3,.)) gt 0 %then
    %do;  /* TC is not a two-level */   
      %put %str(RTE)RROR: &sysmacroname.: The TC parameter (&TC) does not specify a two-level catalog name;
      %let g_abort=1;
    %end;  /* TC is not a two-level */
    %else
    %do;  /* TC is two-level */
      %if %tu_words(&tc.,delim=%str( )) gt 1 or %length(%tu_chknames(&tc,DATA)) gt 0 %then 
      %do;  /* Invalid catalog name */
        %put %str(RTE)RROR: &sysmacroname.: The TC parameter (&TC) does not specify a valid catalog name;
        %let g_abort=1;
      %end;  /* Invalid catalog name */
    %end;  /* TC is two-level */
  %end;  /* TC is not blank */

  /*--Check that template catalog entry is a valid name */
  %if &template. eq %then 
  %do;  /* TEMPLATE is blank */
    %put %str(RTE)RROR: &sysmacroname.: The TEMPLATE parameter must not be blank;
    %let g_abort=1;
  %end;  /* TEMPLATE is blank */
  %else 
  %do;  /* TEMPLATE is not blank */
    %if %length(%scan(&template,2,.)) ne 0 %then
    %do;  /* TEMPLATE is not one-level */
      %put %str(RTE)RROR: &sysmacroname.: The TEMPLATE parameter (&TEMPLATE) does not specify a one-level catalog entry name;
      %let g_abort=1;
    %end;  /* TEMPLATE is not one-level */
    %else
    %do;  /* TEMPLATE is one-level */
      %if %tu_words(&template.,delim=%str( )) gt 1 or %length(%tu_chknames(&template,DATA)) gt 0 %then 
      %do;/* TEMPLATE is an invalid catalog name */
        %put %str(RTE)RROR: &sysmacroname.: The TEMPLATE parameter (&template) does not specify a valid catalog entry name;
        %let g_abort=1;
      %end; /* TEMPLATE is an invalid catalog name */
    %end; /* TEMPLATE is one-level */
  %end; /* TEMPLATE is not blank */

  /*--Check that topy is numeric*/
  %if &topy. eq %then
  %do;  /* TOPY is blank */
    %put %str(RTE)RROR: &sysmacroname.: The TOPY parameter is blank;
    %let g_abort=1;
  %end;  /* TOPY is blank */
  %else
  %do;  /* TOPY is not blank */
    %if %datatyp(&topy) ne NUMERIC %then
    %do;  /* TOPY is not numeric */
      %put %str(RTE)RROR: &sysmacroname.: The TOPY parameter (&topy) is not numeric;
      %let g_abort=1;
    %end;  /* TOPY is not numeric */
    %else
    %do;  /* TOPY is numeric */ 
      %if (&topy. lt 0 or &topy. gt 100) %then
      %do;  /* TOPY not in range */
        %put %str(RTE)RROR: &sysmacroname.: The TOPY parameter (&topy) does not lie between 0 and 100;
        %let g_abort=1;
      %end;  /* TOPY not in range */
    %end;  /* TOPY is numeric */
  %end;  /* TOPY is not blank */

  /*--Check that boty is numeric*/
  %if &boty. eq %then
  %do;  /* BOTY is blank */
    %put %str(RTE)RROR: &sysmacroname.: The BOTY parameter must not be blank;
    %let g_abort=1;
  %end;  /* BOTY is blank */
  %else
  %do;  /* BOTY is not blank */
    %if %datatyp(&boty.) ne NUMERIC %then
    %do;  /* BOTY is not numeric */
      %put %str(RTE)RROR: &sysmacroname.: The BOTY parameter (&boty) must be numeric;
      %let g_abort=1;
    %end;  /* BOTY is not numeric */
    %else 
    %do;  /* BOTY is numeric */
      %if &boty. lt 0 or &boty. gt 100 %then
      %do;  /* BOTY not in range */
        %put %str(RTE)RROR: &sysmacroname.: The BOTY parameter (&topy) does not lie between 0 and 100;
        %let g_abort=1;
      %end;  /* BOTY not in range */
    %end;  /* BOTY is numeric */   
  %end;  /* BOTY is not blank */

  /*--Check that topy is greater then boty*/
  %if %eval(&boty. ge &topy.) %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: The TOPY parameter (&topy) is not greater than BOTY (&boty.);
    %let g_abort=1;
  %end;
      
  /*--Validate the FRAMEPAGE parameter*/
  %if (&framePage. ne Y and &framePage. ne N) %then
  %do;
    %put %str(RTE)RROR: &sysmacroname: The FRAMEPAGE parameter value (&framePage) is not Y or N;
    %let g_abort=1;
  %end;
  
  /*--Validate the FRAMEPLOT parameter*/
  %if (&framePlot. ne Y and &framePlot. ne N) %then
  %do;
    %put %str(RTE)RROR: &sysmacroname: The FRAMEPLOT parameter value (&framePlot) is not Y or N;
    %let g_abort=1;
  %end;
  
  %tu_abort;
 
  /* NORMAL PROCESSING */

  %local leftMargin rightMargin;

  %let leftMargin=0;  /* Percent of page to be left as white space at left  */
  %let rightMargin=0; /* Percent of page to be left as white space at right */

  /*
  / Firstly, we need to establish the coordinates 
  / for the graph pane. Need to do non-integer    
  / arithmetic, so use DATA step (macros cannot   
  / do non-integer arithmetic).                   
  /------------------------------------------------------*/

  %local Size LeftX RightX LowerY UpperY;

  data _null_;
    maxPlotWidth=(100-(&leftMargin.+&rightMargin.));
    maxvert=&topy.-&boty.;
    if (maxvert gt maxPlotWidth) then 
    do;
      /*
      / TOPY-BOTY exceeds maxPlotWidth, so the size of the graph 
      / panels shall be maxPlotWidth. The maxPlotWidth shall be  
      / centred between TOPY and BOTY.                           
      /------------------------------------------------------*/
      size=maxPlotWidth;
      leftx=&leftMargin.;
      lowery=&boty.+(maxvert-size)/2;
    end;
    else 
    do;  
      /*
      / TOPY-BOTY is less than or equal to maxPlotWidth, so 
      / the size of the graph panels shall be TOPY-BOTY.                        
      /------------------------------------------------------*/
      size=maxvert;
      leftx=&leftMargin.+(maxPlotWidth-size)/2;
      lowery=&boty.;
    end;

    call symput('Size',size);
    call symput('LeftX',leftx);
    call symput('RightX',leftx+size);
    call symput('LowerY',lowery);
    call symput('UpperY',lowery+size);

  run;

  %if &g_debug ge 1 %then
  %do;
    %put RTD%str(EBUG): &sysmacroname: SIZE=&size LEFTX=&leftx RIGHTX=&rightx LOWERY=&lowery UPPERY=&uppery;
  %end;

  /* Create the template */
  proc greplay tc=&tc nofs;
    tdef &template.
      1 / llx=0   lly=0                 /* Legend     */
          ulx=0   uly=100
          urx=100 ury=100
          lrx=100 lry=0
      2 / copy=1                        /* Head/foot  */
          %if &framePage. eq Y %then
          %do;
            color=black
          %end;
      3 / copy=1                        /* BY         */
      4 / llx=&LeftX.  lly=&LowerY.     /* Graph1     */
          ulx=&LeftX.  uly=&UpperY.
          urx=&RightX. ury=&UpperY.
          lrx=&RightX. lry=&LowerY.
          %if &framePlot. eq Y %then
          %do;
            color=black
          %end;
      ;
  run; 
  quit;
 
  /* Delete temporary datasets used in this macro */
  %tu_tidyup(rmdset=&prefix:
            ,glbmac=NONE);

  %tu_abort;

%mend tu_cr8template1;
