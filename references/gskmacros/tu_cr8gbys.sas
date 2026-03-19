/*******************************************************************************
|
| Macro Name:      tu_cr8gbys
|
| Macro Version:   1
|
| SAS Version:     8.2
|                                                             
| Created By:      James McGiffen / Andrew Ratcliffe, RTSL
|
| Date:            13-Dec-2004
|
| Macro Purpose:   To Create BY-line slides for subsequent use as an overlay (for
|                  example, by %tu_templates. One slide per by-group in the input
|                  dataset shall be created. The by-variables and values shall be
|                  written to just one line on the slide. The vertical position 
|                  of the by-line shall be such that the by-line follows the 
|                  heading lines (ref: %tu_header). Various styles of by-line
|                  shall be supported.
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME            DESCRIPTION                           REQ/OPT  DEFAULT
| --------------  -----------------------------------   -------  ---------------
|
| dsetin          Input dataset                           REQ    [blank] 
|
| gout            Specifies the output graphic catalog    REQ    [blank]
|                                                                
| KILL            Specifies if this macro should empty    REQ    Y      
|                 the GOUT catalog, if it exists
|
| BYVARS          Variables forming the by groups         REQ    [blank]
|                  Optionally includes ordering vars,
|                  e.g. byvars = trtgrp=trtcd
|
| STYLE           Specifies the style of by line          REQ    label-equals-comma
| --------------  -----------------------------------   -------  ---------------
|
| Output: Series of GSEG catalog entries in specified catalog. GSEGs contain
|         BY-lines for subsequent overlay with other slides/graphs.
|
| Global macro variables created: NONE
|
| Macros called:
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_chkvarsexist
| (@) tu_abort
| (@) tu_header
| (@) tu_words
| (@) tu_tidyup
|
| Example:
|      goptions nodisplay;
|      %tu_cr8gbys(gout=work.pktfig_by
|              ,kill=y
|              ,dsetin=sortedPkcnc
|              ,byvars=trtgrp pcan
|              ,style=label-equals-space
|              );
|      goptions display;
|
|******************************************************************************
| Change Log
|
| Modified By:              Trevor Welby
| Date of Modification:     20-Apr-05
| New version/draft number: 01-002
| Modification ID:          TQW9753.01-002
| Reason For Modification: 
|                           Define macro array variables as local variables
|                           i.e. &byval1...&&byval&byval0
|
|                           Define macro variable &bystring as local
|
|                           Provide comments at the beginning and end
|                           of do/end blocks to improve readability
|
|                           Remove redundant parenthesis from RTERROR message
|                           reporting an inconsistent legend style
|
|                           Remove triple ampersand from all macro variables
|                           and express as a double ampersand
|
|******************************************************************************
| Change Log
|
| Modified By:             James McGiffen
| Date of Modification:    20-May-05
| New version/draft number: 01-003
| Modification ID:          JMcG-01.003
| Reason For Modification:  To remove warnings when macro chars % and & are ]
|                           in the data - tech issue 130;
*******************************************************************************
|
| Change Log
|
| Modified By: James McGiffen
| Date of Modification: 01-004 
| New version/draft number: 01-004
| Modification ID:    JMcG-01.004
| Reason For Modification: To reorginise code so that multiple by vars could be used
|                          Remove redundent test code
|
*******************************************************************************
|
| Change Log
|
| Modified By:
| Date of Modification:
| New version/draft number:
| Modification ID:
| Reason For Modification:
|
*******************************************************************************/

%macro tu_cr8gbys(
  dsetin=                          /* type:ID Input dataset */                    
 ,gout=                            /* Specifies the output graphic catalog*/ 
 ,KILL= Y                          /* Specifies if you empty pre-existing catalog */
 ,byvars=                          /* Variables forming the by groups */
 ,style=LABEL-EQUALS-COMMA         /* Style of the by line */                            
  );
  
  /* Echo parameter values and global macro variables to the log */

  %local MacroVersion;
  %let MacroVersion = 1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals();
  
  %local prefix;
  %let prefix = %substr(&sysmacroname,3); 

  %local i;

  /* PARAMETER VALIDATION */

  %let gout= %nrbquote(&gout.);
  %let dsetin= %nrbquote(&dsetin.);
  %let kill = %nrbquote(%upcase(%substr(&kill,1,1)));
  %let byvars = %nrbquote(&byvars.);
  %let style = %nrbquote(%upcase(&style.));
        
  /*-- Check for required parameters */

  /*-- check that gout has a value*/
  %if %length(&gout) eq 0 %then 
  %do;
    %put %str(RTE)RROR: &sysmacroname.: The GOUT variable cannot be blank.;
    %let g_abort=1;
  %end;
  
  /*-- check that dsetin exists */;
  %if %length(&dsetin) eq 0 or not %sysfunc(exist(&dsetin., data)) %then 
  %do;
    %put %str(RTE)RROR: &sysmacroname.: The dataset identified by DSETIN (&dsetin.) does not exist.;
    %let g_abort=1;
  %end;

  /*-- check that the by variables are in the dsetin dataset */

  /*
  / From BYVARS we will create...
  /   &byvars4sort - remove "=" and swap around the code/decode
  /                  pairs so that the code var leads the sort order
  /   &byvars4show - only includes the byvars to be shown in slides
  /------------------------------------------------------*/
  %local byvars4sort byvars4show wordptr word;
  %let wordptr=1;
  %let word = %scan(&byvars,&wordptr);
  %do %until (%length(&word) eq 0);

    %if %index(&word,=) %then
    %do;  /* We have a decode=code pair */
      %let byvars4sort = &byvars4sort %scan(&word,2,=) %scan(&word,1,=);
      %let byvars4show = &byvars4show %scan(&word,1,=);
    %end; /* We have a decode=code pair */
    %else
    %do;  /* We have a simple by var (not a pair) */
      %let byvars4sort = &byvars4sort &word;
      %let byvars4show = &byvars4show &word;
    %end; /* We have a simple by var (not a pair) */
    %if &g_debug ge 1 %then
      %put RTD%str(EBUG): &sysmacroname: WORDPTR=&wordptr, WORD=&word, BYVARS4SORT=&byvars4sort, BYVARS4SHOW=&byvars4show;

    %let wordptr=%eval(&wordptr+1);
    %let word = %scan(&byvars,&wordptr);

  %end;

  %if %length(%tu_chkvarsexist(&dsetin., &byvars4sort.)) gt 0  %then 
  %do; 
    %put %str(RTE)RROR: &sysmacroname.: The variable(s) %trim(%tu_chkvarsexist(&dsetin,&byvars4sort.)) identified by the BYVAR parameter is/are not in DSETIN(&DSETIN);
    %let g_abort = 1;
  %end;
 
  /*--checking that kill is y or n*/
  %if &kill ne Y and &kill ne N %then 
  %do;
    %put %str(RTE)RROR: &sysmacroname.: The value of parameter KILL (&KILL.) is not Y or N.;
    %let g_abort=1;
  %end;

  /*--check that the style is one of the proscribed ones*/
  %local ok_style_types ok_style_types_sq;
  %let ok_style_types    = "LABEL-EQUALS-COMMA", "LABEL-EQUALS-SPACE", "LABEL-COLON-COMMA", "LABEL-COLON-SPACE";
  %let ok_style_types_sq = 'LABEL-EQUALS-COMMA', 'LABEL-EQUALS-SPACE', 'LABEL-COLON-COMMA', 'LABEL-COLON-SPACE';
  
  data _null_;
    if upcase("&style") not in (&ok_style_types) then 
    do;
      put "RTE" "RROR: &sysmacroname.: The value of style (&style) is not one of " 
                        "&ok_style_types_sq"; *[TQW9753.01-002];
      call symput ('G_ABORT','1');
    end;
  run;
  
  /*-- abort at the end of the parameter validation if it has failed  */
  %tu_abort;
  
  /* NORMAL PROCESSING */

  /* Tidy-up first? */
  %if &kill eq Y and %sysfunc(exist(&gout,catalog)) %then 
  %do;
    proc catalog c=&gout kill;
    run; quit;
  %end;

  /* How many titles? (this sets g_header0) */
  %tu_header;                                      
  %if &g_debug ge 1 %then 
    %put RTDEBUG: &sysmacroname: G_HEADER0=&g_header0;
  %if &g_header0 ge 10 %then
  %do;
    %put %str(RTERR)OR: Too many titles, cannot add a byline;
    %tu_abort(option=force);
  %end;

  /* Remove existing titles/footnotes */
  title;
  footnote;

  /* Break-down the BY into separate macro vars */
  %local byvar0;
  %let byvar0 = %tu_words(&byvars4show);
  %do i = 1 %to &byvar0;
    %local byvar&i; 
    %let byvar&i = %scan(&byvars4show,&i);
    %if &g_debug ge 1 %then 
      %put RTDEBUG: &sysmacroname: BYVAR&i=&&byvar&i;
  %end;


  /* Get just the unique combos */
  proc sort data=&dsetin (keep=&byvars4sort) out=&prefix._sortedby nodupkey;
    by &byvars4sort;
  run;

  /*----------------------------------------------------------------------*/
  /*JMcG-01.003 modify any test variables so the start with %nrstr( and end with )  */
  /*JMcG-01.004 - this has to be moved before we open the dataset*/
  data work.&prefix._textadjusted;
    %do I = 1 %to &byvar0.;
      %if %tu_chkvartype(dsetin = &dsetin., varin=&&byvar&i.) = C %then length &&byvar&i. $2000;;
    %end;
    set &prefix._sortedby;
    %do I = 1 %to &byvar0.;
      %if %tu_chkvartype(dsetin = &dsetin., varin=&&byvar&i.) = C %then %do;
        &&byvar&i. = '%'||'nrstr('||trim(&&byvar&i)||')';
      %end;
    %end;
  run;

  /*----------------------------------------------------------------------*/
  %local dsid;
  %let dsid = %sysfunc(open(&prefix._textadjusted));              
  %if &g_debug ge 1 %then 
    %put RTDEBUG: &sysmacroname: DSID=&dsid;

  /* Build an array of varnums for BY vars */
  %do i = 1 %to &byvar0;
    %local vn_byvar&i type&i label&i;
    %let vn_byvar&i = %sysfunc(varnum(&dsid,&&byvar&i));      
    %let type&i = %sysfunc(vartype(&dsid,&&vn_byvar&i));
    %let label&i = %sysfunc(varlabel(&dsid,&&vn_byvar&i));
    %if %length(&&label&i) eq 0 %then %let label&i = %upcase(&&byvar&i);
    %if &g_debug ge 1 %then %put RTDEBUG: &sysmacroname: VN_BYVAR&i=&&vn_byvar&i  TYPE&i=&&type&i LABEL&i="&&label&i";
  %end;

  /* Now produce the slides */
  %local fetchrc;
  %let fetchrc = %sysfunc(fetch(&dsid)); 
  %if &g_debug ge 1 %then %put RTDEBUG: &sysmacroname: FETCHRC=&fetchrc;

  %do %while (&fetchrc eq 0);  /* do over permutations of by values [TQW9753.01-002] */

    /* Build the text that will be shown */
    %local thisBit by_ptr;
    %do by_ptr = 1 %to &byvar0; /* do over byvars [TQW9753.01-002] */

      %local byval&by_ptr; /*[TQW9753.01-002]*/

      %if &&type&by_ptr eq C %then %do;
        %let byval&by_ptr = %sysfunc(getvarc(&dsid.,&&vn_byvar&by_ptr)); 
      %end;
      %else %do;
        %let byval&by_ptr = %sysfunc(getvarn(&dsid.,&&vn_byvar&by_ptr)); 
      %end;

      %if &g_debug ge 1 %then 
        %put RTDEBUG: &sysmacroname: BYVAR&by_ptr=&&byvar&by_ptr BYVAL&by_ptr=&&byval&by_ptr;

      %if %scan(&style,2,-) eq EQUALS %then %do;  /* equals */
        %let thisBit = &&label&by_ptr=%nrbquote(&&byval&by_ptr);
      %end; /* equals */
      %else %do;  /* colon */
        %let thisBit = &&label&by_ptr:%nrbquote(&&byval&by_ptr);
      %end; /* colon */

      %local bystring;  /*[TQW9753.01-002]*/

      %if &by_ptr eq 1 %then %do;
        %let bystring=%nrbquote(&thisBit);
      %end;
      %else %do;  /* Not first, so add separator */
        %if %scan(&style,3,-) eq COMMA %then %do;  /* comma */
          %let bystring = &bystring, &thisBit.;
        %end; /* comma */
        %else %do;  /* space */
          %let bystring = &bystring &thisBit.;
        %end; /* space */
      %end; /* Not first, so add separator */

      %if &g_debug ge 1 %then %put RTDEBUG: &sysmacroname: jBYSTRING=%nrstr(&bystring);

    %end; /* do over byvars */

    proc gslide gout=&gout;
      %do i=1 %to &g_header0;
        title&i " ";
      %end;
      title%eval(&g_header0+1) j=c "&bystring";
    run; quit;

    /* Fetch data for the next slide */
    %let fetchrc = %sysfunc(fetch(&dsid)); 

    %if &g_debug ge 1 %then %put RTDEBUG: &sysmacroname: FETCHRC=&fetchrc;

  %end; /* do over permutations of by values */

  /* Finish off */
  %local closerc;
  %let closerc = %sysfunc(close(&dsid));                       
  %if &g_debug ge 1 %then %put RTDEBUG: &sysmacroname: CloseRC=&closerc;

  /* Delete temporary datasets used in this macro */
  %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

  %tu_abort;

%mend tu_cr8gbys;
