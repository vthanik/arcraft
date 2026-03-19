/*******************************************************************************
|
| Macro Name:      tu_cr8gheadfoots
|
| Macro Version:   1
|
| SAS Version:     8.2
|                                                             
| Created By:      James McGiffen / Andrew Ratcliffe, RTSL
|
| Date:            13-Dec-2004
|
| Macro Purpose:   To create header/footer slides for subsequent use as an 
|                  overlay (for example, with %tu_templates). One slide per
|                  graph in the input catalog (PAGECAT) shall be produced, 
|                  each with a unique sequential page number in the style 
|                  "Page x of y".
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME            DESCRIPTION                           REQ/OPT  DEFAULT
| --------------  -----------------------------------   -------  ---------------
|
| gout            Specifies the output graphic catalog    REQ    [blank]
|                 
| KILL            Specifies if this macro should empty    REQ    Y      
|                 the GOUT catalog, if it exists
|
| pagecat         Specifies a catalog with grseg entries  REQ    [blank]
|
| font            Specifies font for "page x of y"        REQ    [blank]
|
| ptsize          Specifies point size of font            REQ    [blank]
| --------------  -----------------------------------  -------  ---------------
|
| Output: Series of GSEG catalog entries in specified catalog. GSEGs contain
|         headers/footers for subsequent overlay with other slides/graphs.
|
| Global macro variables created: NONE
|
| Macros called:
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_abort
| (@) tu_header
| (@) tu_footer
| (@) tu_nobs
| (@) tu_tidyup
| (@) tu_words
|
| Example:
|    goptions nodisplay;
|    %tu_cr8gheadfoots(gout    = work.pktfig_hf
|                     ,kill    = y
|                     ,pagecat = work.pktfig_lin
|                     ,font    = simplex
|                     ,ptsize  = 10
|                     );
|    goptions display;
|
|******************************************************************************
| Change Log
|
| Modified By:              Trevor Welby
| Date of Modification:     21-Apr-05
| New version/draft number: 01-002
| Modification ID:          TQW9753.01-002
| Reason For Modification:  Declare macro variable "NUMPAGES" 
|                           as a local variable
|
|******************************************************************************
|
| Modified By:              Trevor Welby
| Date of Modification:     17-May-05
| New version/draft number: 01-003
| Modification ID:          TQW9753.01.003
| Reason For Modification:  Modify the parameter validation section
|                           so that GOUT is now checked as a valid catalog
|                           name.  This requires the use of %tu_words 
|                           to check for blanks in the parameter specification.
|
|******************************************************************************
|
| Modified By:
| Date of Modification:
| New version/draft number:
| Modification ID:
| Reason For Modification:
|
*******************************************************************************/
%macro tu_cr8gheadfoots(
  gout=                            /* Specifies the output graphic catalog */ 
 ,kill= Y                          /* Specifies whether pre-existing catalog should be emptied */
 ,pagecat=                         /* Specifies the catalog with grseg entries */
 ,font=                            /* Specifies font for "PAGE X OF Y" */
 ,ptsize=                          /* Specifies point size of font */
  );
  
  /* Echo parameter values and global macro variables to the log */

  %local MacroVersion I;
  %let MacroVersion = 1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals();
  
  %local prefix;
  %let prefix = %substr(&sysmacroname,3);
  
  /* PARAMETER VALIDATION */

  %let gout= %nrbquote(&gout.);
  %let kill = %nrbquote(&kill.);
  %let pagecat = %nrbquote(&pagecat.);
   
  /* Check for required parameters */

  /*-- check that gout has a value and is a valid catalog name [TQW9753.01.003] */
  %if &gout. eq %then 
  %do;  /* GOUT is blank */
    %put %str(RTE)RROR: &sysmacroname.: The GOUT parameter must not be blank;
    %let g_abort=1;
  %end;  /* GOUT is blank */
  %else
  %do;  /* GOUT is not blank */
    %if %tu_words(&gout.,delim=%str( )) gt 1 or %length(%tu_chknames(&gout,DATA)) gt 0 %then 
    %do;  /* Invalid catalog name */
      %put %str(RTE)RROR: &sysmacroname.: The GOUT parameter (&gout.) does not specify a valid catalog name;
      %let g_abort=1;
    %end;  /* Invalid catalog name */
  %end;  /* GOUT is not blank */

  /*-- check that pagecat exists */
  %if %sysfunc(exist(&pagecat., catalog)) ne 1 %then 
  %do;
    %put %str(RTE)RROR: &sysmacroname.: The catalog identified by pagecat (&pagecat.) does not exist.;
    %let g_abort=1;
  %end;
 
  /*--checking that kill is y or n*/
  %if %upcase(&kill.) ne Y and %upcase(&kill.) ne N %then 
  %do;
    %put %str(RTE)RROR: &sysmacroname.: The value of parameter KILL (&KILL.) is not Y or N.;
    %let g_abort=1;
  %end;  
   
  /*--checking that font is not blank*/
  %if %length(&font) eq 0 %then 
  %do;
    %put %str(RTE)RROR: &sysmacroname.: The FONT parameter must not be blank;
    %let g_abort=1;
  %end;  
   
  /*--checking that ptsize is numeric*/
  %if %datatyp(&ptsize) ne NUMERIC %then 
  %do;
    %put %str(RTE)RROR: &sysmacroname.: The PTSIZE parameter (&ptsize) must be numeric;
    %let g_abort=1;
  %end;  
   
  /*-- abort at the end of the parameter validation is its failed  */
  %tu_abort;
  
  /* NORMAL PROCESSING */
 
  /* Tidy-up first? */
  %if %upcase(%substr(&kill,1,1)) eq Y and %sysfunc(exist(&gout,catalog)) %then 
  %do;
    proc catalog c=&gout kill;
    quit;
  %end;

   /* Count the number of gsegs in PAGECAT */
  %local pagecatlib pagecatmem;
  %if %length(%scan(&pagecat,2,.)) eq 0 %then
  %do;
    %let pagecatlib = WORK;
    %let pagecatmem = %upcase(&pagecat);
  %end;
  %else
  %do;
    %let pagecatlib = %upcase(%scan(&pagecat,1,.));
    %let pagecatmem = %upcase(%scan(&pagecat,2,.));
  %end;

  %local numpages; *[TQW9753.01-002];
  %let numpages=0;
  data _null_;
    set sashelp.vcatalg (where=(libname eq "&pagecatlib" and 
                                memname eq "&pagecatmem" and
                                memtype eq 'CATALOG' and 
                                objtype eq 'GRSEG'
                              )
                        );
    call symput('NUMPAGES',compress(putn(_n_,'BEST.')));
  run;
  %if &g_debug ge 1 %then
    %put RTDEBUG: CR8GHEADFOOTS: NUMPAGES=&numpages;

  /* Set the standard headers/footers */
  %tu_header;
  %tu_footer(dsetout=work.&prefix._footerout);  /* dataset not used, see below */

  %if %tu_nobs(work.&prefix._footerout) ne 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname: Footer(s) contain illegal column references.;
    %let g_abort = 1;
  %end;
  %tu_abort;

  /* Now do the work */
  %annomac;                                
  %do i = 1 %to &numpages;
    data work.&prefix._anno;
      %dclanno;
      length text $20;
      %system(3,3,4);
      page_text = trim(left(putc('PAGE','$local.')))
                  !! " &i "
                  !! trim(left(putc('OF','$local.')))
                  !! " &numpages"
                  ;
      %label(100,100         /* Position        */
            ,page_text       /* Text            */
            ,black           /* Colour          */
            ,0,0             /* Angle, rotation */
            ,&ptsize/7       /* Size            */
            ,&font           /* Font            */
            ,D);             /* Position        */
                   /*
                   / 7 is a "fudge-factor" that seems to 
                   / work when converting sizes.         
                   /------------------------------------------------------*/
      OUTPUT;
    run;

    proc gslide gout=&gout anno=work.&prefix._anno;
    run; quit;

  %end;

  /* Delete temporary datasets used in this macro */
  %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

  %tu_abort;
 
%mend tu_cr8gheadfoots;
