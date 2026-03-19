/*******************************************************************************
|
| Macro Name:      tu_templates
|
| Macro Version:   2
|
| SAS Version:     9.1
|
| Created By:      James McGiffen / Andrew Ratcliffe, RTSL
|
| Date:            13-Dec-2004
|
| Macro Purpose:   To create a graph output file by combining the input graphic
|                  segments with the input template
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME              DESCRIPTION                           REQ/OPT  DEFAULT
| --------------    -----------------------------------   -------  ---------------
| outfile=        Specifies the output graphic file          REQ   &g_outfile..&g_textfilesfx
|
| graphcats=      Name of the catalog containing the graphs  REQ   [blank]
|
| hfcat=          Header footer catalog                      REQ   [blank]
|
| layout=         Graphs per output page (1up, 2up)          REQ   [blank]
|
| topy=           Specifies the highest point of Y (%)       REQ   80
|
| boty=           Specifies the lowest point of Y (%)        REQ   20
|
| framepage=      Place frame around page?                   REQ   N
|
| frameplot=      Place frame around plot(s)?                REQ   N
|
| legend=         Legend catalog                             OPT   [blank]
|
| bycat=          By line catalog                            OPT   [blank]
| --------------  -----------------------------------     -------  ---------------
|
| Output: Graphics output file containing laid-out graphs
|
| Global macro variables created: NONE
|
| Macros called:
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_tidyup
| (@) tu_abort
| (@) tu_words
| (@) tu_cr8template1
| (@) tu_cr8template2
|
| Example:
|
|    %tu_templates(graphcats=work.pktfig_lingraffs work.pktfig_loggraffs
|                 ,hfcat=work.pktfig_hf
|                 ,layout=2
|                 ,topy=95
|                 ,boty=10
|                 ,outfile=/arenv/arprod/c/s/r/output/graffs.pdf
|                 ,framePage=N
|                 ,framePlot=N
|                 ,bycat=work.pktfig_by
|                 ,legend=work.pktfig_legend.legend.grseg
|                 );
|
|******************************************************************************
| Change Log
|
| Modified By:               Trevor Welby
| Date of Modification:      11-May-05
| New version/draft number:  01-002
| Modification ID:           TQW9753.01.002
| Reason For Modification:
|                            Correct typographic mistake in program header
|
|                            Declare the following local macro variables
|                            as local: INCAT, OUTPFX, TEMPCAT, DSID, OBJNAME_VN,
|                            RC, OBJNAME, NUMGSEGS, INENT, AND OUTENT
|
|******************************************************************************
|
| Modified By:               Trevor Welby
| Date of Modification:      16-May-05
| New version/draft number:  01-003
| Modification ID:           TQW9753.01.003
| Reason For Modification:
|                            Augment parameter validation to abort subsequent
|                            processing if a catalog contains zero entries.
|
|                            The following graphic catalogs specified by
|                            parameters: GRAPHCATS, HFCAT and BYCAT are checked.
|
|                            Note: The current validation for the LEGEND parameter
|                            traps the case of the zero entry successfully.
|
|                            Code edited to confirm to programming standards
|
|******************************************************************************
|
| Modified By:               Warwick Benger
| Date of Modification:      31-Jun-09
| New version/draft number:  01-004
| Modification ID:           WJB.1.04
| Reason For Modification:   Modify creation of _gseglist_g2 and _gseglist_g1 to 
|                            handle > 999 GPLOT entries (e.g. GPLO1000, GPLO1001 etc)
|                            Modify creation of _gseglist_hf and _gseglist_by to 
|                            handle > 99 GSLIDE entries (e.g. GSLID100, GSLID101 etc)
|                            (Use compress rather than substr)
|
|******************************************************************************
|
| Modified By:              Shivam Kumar
| Date of Modification:     21-Oct-2013
| New version/draft number: 02-001
| Modification ID:
| Reason For Modification: To Replace local macro variable sysmsg with l_sysmsg
|
*******************************************************************************/
%macro tu_templates(outfile=&g_outfile..&g_textfilesfx  /* Specifies the output graphic file */
                   ,graphcats=                          /* Name of the catalog(s) containing the graphs */
                   ,hfcat=                              /* Header footer catalog */
                   ,bycat=                              /* By line catalog */
                   ,legend=                             /* Legend catalog */
                   ,layout=                             /* Graphs per output page (1up, 2up) */
                   ,topy=80                             /* Specifies the highest point of Y (%) */
                   ,boty=20                             /* Specifies the lowest point of Y (%)  */
                   ,framePage=N                         /* Place frame around page? */
                   ,framePlot=N                         /* Place frame around plot(s)? */
                   );

  /* Echo parameter values and global macro variables to the log */

  %local MacroVersion;
  %let MacroVersion=2;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals();

  %local prefix;
  %let prefix=%substr(&sysmacroname,3);

  %local i;

  /* PARAMETER VALIDATION */
  %let outfile  =%nrbquote(&outfile.);
  %let graphcats=%nrbquote(&graphcats.);
  %let hfcat    =%nrbquote(&hfcat.);
  %let bycat    =%nrbquote(&bycat.);
  %let legend   =%nrbquote(&legend.);
  %let layout   =%nrbquote(%upcase(&layout.));
  %let topy     =%nrbquote(&topy.);
  %let boty     =%nrbquote(&boty.);
  %let framePage=%nrbquote(&framePage.);
  %let framePlot=%nrbquote(&framePlot.);

  /* Check for required parameters */

  /*--check that outfile has a value*/

  %if &outfile. eq %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: The OUTFILE parameter cannot be blank.;
    %let g_abort=1;
  %end;

  /*--check that the layout is 1UP or 2UP*/
  %if (&layout. ne 1UP and &layout. ne 2UP) %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: The parameter LAYOUT (&layout.) must be 1UP or 2UP;
    %let g_abort=1;
  %end;

  /*--FRAMEPAGE and FRAMEPLOT are validated by sub-macros*/

  /*--Test that the graphics cats exists */
  %local numGraphCats;
  %let numGraphCats=%tu_words(&graphcats.,delim=%str( ));

  %if %length(&graphcats.) eq 0 %then
  %do;  /* GRAPHCATS blank */
    %put %str(RTE)RROR: &sysmacroname.: The GRAPHCATS parameter must not be blank;
    %let g_abort=1;
  %end;  /* GRAPHCATS blank */
  %else
  %do;  /* GRAPHCATS not blank */

    %do i=1 %to &numGraphCats.;  /* Loop for each catalog */

      %local graphcat&i;
      %let graphcat&i=%scan(&graphcats.,&i,' ');

      %if %length(%scan(&&graphcat&i,2,.)) eq 0 %then
      %do; /* temporary catalog */
        %let graphcat&i=work.&&graphcat&i;
      %end; /* temporary catalog */

      %if %sysfunc(cexist(&&graphcat&i)) eq 0 %then
      %do;  /* Catalog does not exist */
        %put %str(RTE)RROR: &sysmacroname.: The catalog defined in GRAPHCATS (&&graphcat&I)) does not exist.;
        %let g_abort=1;
      %end;  /* Catalog does not exist */

    %end;  /* Loop for each catalog */

  %end;  /* GRAPHCATS not blank */

  %if (&layout. eq 1UP and &numGraphCats. ne 1) %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: With LAYOUT=1UP, one catalog must be specified with the GRAPHCATS parameter yet &numGraphCats were specified;
    %let g_abort=1;
  %end;
  %else %if (&layout. eq 2UP and &numGraphCats. ne 2) %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: With LAYOUT=2UP, two catalog must be specified with the GRAPHCATS parameter yet &numGraphCats were specified;
    %let g_abort=1;
  %end;

  /*--Test that the headfootcat cats exists*/
  %if %length(%scan(&hfcat,2,.)) eq 0 %then
  %do; /* temporary catalog */
    %let hfcat=work.&hfcat;
  %end; /* temporary catalog */

  %if %sysfunc(cexist(&hfcat.)) eq 0 %then
  %do;  /* HFCAT Catalog does not exist */
    %put %str(RTE)RROR: &sysmacroname.: The catalog defined in HFCAT (&hfcat.) does not exist.;
    %let g_abort=1;
  %end;  /* HFCAT Catalog does not exist */

  /*--Test that the by cat exists*/
  %if %length(&bycat) gt 0 %then
  %do;  /* BYCAT not blank */

    %if %length(%scan(&bycat,2,.)) eq 0 %then
    %do; /* temporary catalog */
      %let bycat=work.&bycat;
    %end; /* temporary catalog */

    %if %sysfunc(cexist(&bycat.)) eq 0 %then
    %do;  /* BYCAT Catalog does not exist */
      %put %str(RTE)RROR: &sysmacroname.: The catalog defined in BYCAT (&bycat.) does not exist.;
      %let g_abort=1;
    %end;  /* BYCAT Catalog does not exist */

  %end;  /* BYCAT not blank */

  /*--Test that the legend catalog entry exists*/
  %if %length(&legend) gt 0 %then
  %do;  /* LEGEND not blank */

    %if %length(%scan(&legend,4,.)) eq 0 %then
    %do;/* temporary catalog */
      %let legend=work.&legend;
    %end;/* temporary catalog */

    %if %sysfunc(cexist(&legend.)) eq 0 %then
    %do; /* LEGEND Catalog does not exist */
      %put %str(RTE)RROR: &sysmacroname.: The catalog defined in LEGEND (&legend.) does not exist.;
      %let g_abort=1;
    %end; /* LEGEND Catalog does not exist */

  %end;  /* LEGEND not blank */

  /*--TOPY and BOTY parameters are validated by sub-macros*/

  %tu_abort;

  /* NORMAL PROCESSING */

  %local numGraphs;
  %let numGraphs=%substr(&layout,1,1);

  %if %sysfunc(cexist(work.&prefix._cat4tplts)) %then
  %do;
    proc datasets lib=work nolist;
      delete &prefix._cat4tplts / mt=catalog;
    quit;run;
  %end;

  /*-- Create the template */
  %if &numGraphs eq 1 %then
  %do;  /* 1 graph */
    %tu_cr8template1(topy=&topy
                    ,boty=&boty
                    ,tc=work.&prefix._cat4tplts
                    ,template=reptools
                    ,framePage=&framePage
                    ,framePlot=&framePlot
                   );
  %end;  /* 1 graph */
  %else
  %do;  /* 2 graph */
    %tu_cr8template2(topy=&topy
                    ,boty=&boty
                    ,tc=work.&prefix._cat4tplts
                    ,template=reptools
                    ,framePage=&framePage
                    ,framePlot=&framePlot
                    );
  %end;  /* 2 graph */

  /*
  / Place all of the gsegs into one catalog (work.final), because
  / PROC GREPLAY only accepts inputs from one catalog.
  /------------------------------------------------------*/
  %if %sysfunc(cexist(work.&prefix._final)) %then
  %do;
    proc datasets lib=work nolist;
      delete &prefix._final / mt=catalog;
    run;
    quit;
  %end;

  /*
  / We will create GSEGs named HFnnn, G1nnn, G2nnn,
  / BYnnn, and LGnnn. The subsequent replay step
  / will use the items numbered x on page x.
  / We need an intermediate catlg (work.temp) so
  / that we can safely rename items.
  /------------------------------------------------------*/

  /* First, the HFs */
  %local incat outpfx tempcat; /* [TQW9753.01.002] */
  %let incat=&hfcat;
  %let outpfx=hf;
  %let tempcat=%upcase(temp);

  %if &g_debug. gt 2 %then
  %do;
    %put RTD%str(EBUG): Copying the Headers and Footers;
  %end;

  %if %sysfunc(cexist(&prefix._&tempcat)) %then
  %do;
    proc datasets lib=work nolist;
      delete &prefix._&tempcat / mt=catalog;
    run;
    quit;
  %end;

  proc catalog cat=&incat et=grseg;
    copy out=work.&prefix._&tempcat;
  run;
  quit;

  /*
  / Generate code of the form:
  /
  /   proc catalog cat=work.temp et=gseg;
  /     change gslide=hf001;
  /     change gslide1=hf002;
  /     change gslide2=hf003;
  /       :
  /     change gslide9=hf009;
  /     change gslide10=hf010;
  /   run;
  /   quit;
  /------------------------------------------------------*/

  %local nsegs;  /* [TQW9753.01.003] */

  proc sql noprint;
    create table &prefix._gseglist_hf as
      select  objname
             ,input(compress(objname,'GSLIDE'),best.) as sortvarn    /* [WJB.1.04] */
      from sashelp.vcatalg
      where upcase(libname) eq upcase("WORK")
        and upcase(memname) eq upcase("&prefix._&tempcat")
        and upcase(memtype) eq 'CATALOG'
        and upcase(objtype) eq 'GRSEG'
      order sortvarn
      ;
      %let nsegs=&sqlobs;  /* [TQW9753.01.003] */

  quit;

  %if &nsegs=0 %then
  %do; /* [TQW9753.01.003] */
    %put %str(RTE)RROR: &sysmacroname.: The catalog defined in HFCAT (&hfcat.) does not contain an entry.;
    %let nsegs=;
    %tu_abort(option=force);
  %end; /* [TQW9753.01.003] */

  %local dsid;  /* [TQW9753.01.002] */

  %let dsid=%sysfunc(open(work.&prefix._gseglist_hf));

  %if &g_debug. ge 1 %then
  %do;
    %put RTD%str(EBUG): &sysmacroname: DSID=&dsid;
  %end;

  %if &dsid le 0 %then
  %do;
    %local l_sysmsg;
    %let l_sysmsg=%sysfunc(sysmsg());
    %put RTE%str(RROR): &sysmacroname: &l_sysmsg;
    %tu_abort(option=force);
  %end;

  /*
  / Make a note of the number of gsegs that we
  / are dealing with. Used several times below.
  /------------------------------------------------------*/
  %local numgsegs;  /* [TQW9753.01.002] */
  %let numgsegs=%sysfunc(attrn(&dsid,nobs));

  %if &g_debug. ge 1 %then
  %do;
    %put RTD%str(EBUG): &sysmacroname: NUMGSEGS=&numgsegs;
  %end;

  proc catalog cat=work.&prefix._temp et=grseg;

    %local objname_vn objname rc; /* [TQW9753.01.002] */

    %let objname_vn=%sysfunc(varnum(&dsid,OBJNAME));

    %if &g_debug. ge 1 %then
    %do;
      %put RTD%str(EBUG): &sysmacroname: OBJNAME_VN=&objname_vn;
    %end;

    %do i=1 %to &numgsegs;
      %let rc=%sysfunc(fetch(&dsid));
      %if &g_debug. ge 1 %then
        %put RTD%str(EBUG): &sysmacroname: FETCHRC=&rc;
      %let objname=%sysfunc(getvarc(&dsid,&objname_vn));
      %if &g_debug. ge 1 %then
        %put RTD%str(EBUG): &sysmacroname: OBJNAME=&objname;

      change &objname=&outpfx%sysfunc(putn(&i,Z6.));

    %end;
    %let rc=%sysfunc(close(&dsid));
    %if &g_debug. ge 1 %then
      %put RTD%str(EBUG): &sysmacroname: CLOSERC=&rc;

  run;
  quit;

  proc datasets lib=work nolist;
    delete gseglist;
  run;
  quit;

  proc catalog cat=work.&prefix._&tempcat et=grseg;
    copy out=work.&prefix._final;
  run;
  quit;

  /* Now graph1 */

  %let incat=&graphcat1;
  %let outpfx=g1;
  %let tempcat=%upcase(temp);

  %if %sysfunc(cexist(work.&prefix._&tempcat)) %then
  %do;
    proc datasets lib=work nolist;
      delete &prefix._&tempcat / mt=catalog;
    quit;
  %end;

  proc catalog cat=&incat et=grseg;
    copy out=work.&prefix._&tempcat;
  run;
  quit;

  proc sql noprint;
    create table work.&prefix._gseglist_g1 as
      select objname
            ,input(compress(objname,'GPLOT'),best.) as sortvarn  /* [WJB.1.04] */
      from sashelp.vcatalg
      where upcase(libname) eq upcase("WORK")
        and upcase(memname) eq upcase("&prefix._&tempcat")
        and upcase(memtype) eq 'CATALOG'
        and upcase(objtype) eq 'GRSEG'
      order sortvarn
      ;
      %let nsegs=&sqlobs; /* [TQW9753.01.003] */
  quit;
  
  %if &nsegs=0 %then
  %do;  /* [TQW9753.01.003] */
    %put %str(RTE)RROR: &sysmacroname.: A catalog defined in GRAPHCAT (&graphcat1.) does not contain an entry.;
    %let nsegs=;
    %tu_abort(option=force);
  %end; /* [TQW9753.01.003] */

  proc catalog cat=work.&prefix._temp et=grseg;
    %let dsid=%sysfunc(open(work.&prefix._gseglist_g1));
    %if &g_debug. ge 1 %then
      %put RTD%str(EBUG): &sysmacroname: DSID=&dsid;
    %if &dsid le 0 %then
    %do;
      %local l_sysmsg;
      %let l_sysmsg=%sysfunc(sysmsg());
      %put RTE%str(RROR): &sysmacroname: &l_sysmsg;
      %tu_abort(option=force);
    %end;

    %let objname_vn=%sysfunc(varnum(&dsid,OBJNAME));
    %if &g_debug. ge 1 %then
      %put RTD%str(EBUG): &sysmacroname: OBJNAME_VN=&objname_vn;
    %do i=1 %to &numgsegs;
      %let rc=%sysfunc(fetch(&dsid));
      %if &g_debug. ge 1 %then
        %put RTD%str(EBUG): &sysmacroname: FETCHRC=&rc;
      %let objname=%sysfunc(getvarc(&dsid,&objname_vn));
      %if &g_debug. ge 1 %then
        %put RTD%str(EBUG): &sysmacroname: OBJNAME=&objname;
      change &objname=&outpfx%sysfunc(putn(&i,Z6.));
    %end;
    %let rc=%sysfunc(close(&dsid));
    %if &g_debug. ge 1 %then
      %put RTD%str(EBUG): &sysmacroname: CLOSERC=&rc;
  run;
  quit;

  proc catalog cat=work.&prefix._&tempcat et=grseg;
    copy out=work.&prefix._final;
  run;
  quit;

  /* Finally graph2 */
  %if &numGraphs ge 2 %then
  %do;  /* Second graph processing */
    %let incat=&graphcat2;
    %let outpfx=g2;
    %let tempcat=%upcase(temp);

    %if %sysfunc(cexist(work.&prefix._&tempcat)) %then
    %do;
      proc datasets lib=work nolist;
        delete &prefix._&tempcat / mt=catalog;
      quit;
    %end;

    proc catalog cat=&incat et=grseg;
      copy out=work.&prefix._&tempcat;
    run;
    quit;

    proc sql noprint;
      create table work.&prefix._gseglist_g2 as
        select  objname
               ,input(compress(objname,'GPLOT'),best.) as sortvarn    /* [WJB.1.04] */
        from sashelp.vcatalg
        where upcase(libname) eq upcase("WORK")
          and upcase(memname) eq upcase("&prefix._&tempcat")
          and upcase(memtype) eq 'CATALOG'
          and upcase(objtype) eq 'GRSEG'
        order sortvarn
        ;
        %let nsegs=&sqlobs; /* [TQW9753.01.003] */
    quit;

  %if &nsegs=0 %then
  %do;  /* [TQW9753.01.003] */
    %put %str(RTE)RROR: &sysmacroname.: A catalog defined in GRAPHCAT (&graphcat2.) does not contain an entry.;
    %let nsegs=;
    %tu_abort(option=force);
  %end; /* [TQW9753.01.003] */

    proc catalog cat=work.&prefix._temp et=grseg;
      %let dsid=%sysfunc(open(work.&prefix._gseglist_g2));
      %if &g_debug. ge 1 %then
        %put RTD%str(EBUG): &sysmacroname: DSID=&dsid;
      %if &dsid le 0 %then
      %do;
        %local l_sysmsg;
        %let l_sysmsg=%sysfunc(sysmsg());
        %put RTE%str(RROR): &sysmacroname: &l_sysmsg;
        %tu_abort(option=force);
      %end;

      %let objname_vn=%sysfunc(varnum(&dsid,OBJNAME));
      %if &g_debug. ge 1 %then
        %put RTD%str(EBUG): &sysmacroname: OBJNAME_VN=&objname_vn;
      %do i=1 %to &numgsegs;
        %let rc=%sysfunc(fetch(&dsid));
        %if &g_debug. ge 1 %then
          %put RTD%str(EBUG): &sysmacroname: FETCHRC=&rc;
        %let objname=%sysfunc(getvarc(&dsid,&objname_vn));
        %if &g_debug. ge 1 %then
          %put RTD%str(EBUG): &sysmacroname: OBJNAME=&objname;
        change &objname=&outpfx%sysfunc(putn(&i,Z6.));
      %end;
      %let rc=%sysfunc(close(&dsid));
      %if &g_debug. ge 1 %then
        %put RTD%str(EBUG): &sysmacroname: CLOSERC=&rc;
    run;
    quit;

    proc catalog cat=work.&prefix._&tempcat et=grseg;
      copy out=work.&prefix._final;
    run;
    quit;

  %end; /* Second graph processing */

       /* Finally, finally: BY */
  %if %length(&bycat) gt 0 %then
  %do;  /* BYCAT processing */
    %let incat=&bycat;
    %let outpfx=by;
    %let tempcat=%upcase(temp);

    %if %sysfunc(cexist(work.&prefix._&tempcat)) %then
    %do;
      proc datasets lib=work nolist;
        delete &prefix._&tempcat / mt=catalog;
      quit;
    %end;

    proc catalog cat=&incat et=grseg;
      copy out=work.&prefix._&tempcat;
    run;
    quit;

    proc sql noprint;
      create table work.&prefix._gseglist_by as
        select  objname
               ,input(compress(objname,'GSLIDE'),best.) as sortvarn   /* [WJB.1.04] */
        from sashelp.vcatalg
        where upcase(libname) eq upcase("WORK")
          and upcase(memname) eq upcase("&prefix._&tempcat")
          and upcase(memtype) eq 'CATALOG'
          and upcase(objtype) eq 'GRSEG'
        order sortvarn
        ;
        %let nsegs=&sqlobs; /* [TQW9753.01.003] */
    quit;

    %if &nsegs=0 %then
    %do;  /* [TQW9753.01.003] */
      %put %str(RTE)RROR: &sysmacroname.: A catalog defined in BYCAT (&bycat.) does not contain an entry.;
      %let nsegs=;
      %tu_abort(option=force);
    %end; /* [TQW9753.01.003] */

    proc catalog cat=work.&prefix._temp et=grseg;
    %let dsid=%sysfunc(open(work.&prefix._gseglist_by));
    %if &g_debug. ge 1 %then
      %put RTD%str(EBUG): &sysmacroname: DSID=&dsid;
    %if &dsid le 0 %then
    %do;
      %local l_sysmsg;
      %let l_sysmsg=%sysfunc(sysmsg());
      %put RTE%str(RROR): &sysmacroname: &l_sysmsg;
      %tu_abort(option=force);
    %end;

    %let objname_vn=%sysfunc(varnum(&dsid,OBJNAME));
    %if &g_debug. ge 1 %then
      %put RTD%str(EBUG): &sysmacroname: OBJNAME_VN=&objname_vn;
    %do i=1 %to &numgsegs;
      %let rc=%sysfunc(fetch(&dsid));
      %if &g_debug. ge 1 %then
        %put RTD%str(EBUG): &sysmacroname: FETCHRC=&rc;
      %let objname=%sysfunc(getvarc(&dsid,&objname_vn));
      %if &g_debug. ge 1 %then
        %put RTD%str(EBUG): &sysmacroname: OBJNAME=&objname;
      change &objname=&outpfx%sysfunc(putn(&i,Z6.));
    %end;
    %let rc=%sysfunc(close(&dsid));
    %if &g_debug. ge 1 %then
      %put RTD%str(EBUG): &sysmacroname: CLOSERC=&rc;
    run;
    quit;

    proc catalog cat=work.&prefix._&tempcat et=grseg;
      copy out=work.&prefix._final;
    run;
    quit;

  %end;   /* BYCAT processing */

       /* Really finally: legend */
  %local inent outent;  /* [TQW9753.01.002] */

  %if %length(&legend) gt 0 %then
  %do;  /* LEGEND processing */
    %let incat=%scan(&legend,1,.).%scan(&legend,2,.);
    %let inent=%scan(&legend,3,.);
    %let outent=legend;
    %let tempcat=%upcase(temp);

    %if %sysfunc(cexist(work.&prefix._&tempcat)) %then
    %do;
      proc datasets lib=work nolist;
        delete &prefix._&tempcat / mt=catalog;
      quit;
    %end;

    proc catalog cat=&incat et=grseg;
      copy out=work.&prefix._&tempcat;
        select &inent;
    run;
    quit;

    %if &inent ne &outent %then
    %do;
      proc catalog cat=work.&prefix._&tempcat et=grseg;
        change &inent=&outent;
      run;
      quit;
    %end;

    proc catalog cat=work.&prefix._&tempcat et=grseg;
      copy out=work.&prefix._final;
    run;
    quit;

  %end; /* LEGEND processing */

  /* Direct the output to the correct destination */
  goptions gaccess=gsasfile;

  filename gsasfile "&outfile";

  /* Replay the graphs through the template */
  proc greplay tc=work.&prefix._cat4tplts nofs 
               igout=work.&prefix._final
               gout=work.&prefix._repout 
               template=reptools
               ;

  %do i=1 %to &numgsegs;
    treplay %if %length(&legend) gt 0 %then
            %do;
              1:legend
            %end;

            2:hf%sysfunc(putn(&i,Z6.))

            %if %length(&bycat) gt 0 %then
            %do;
              3:by%sysfunc(putn(&i,Z6.))
            %end;

              4:g1%sysfunc(putn(&i,Z6.))

            %if &numGraphs ge 2 %then
            %do;
              5:g2%sysfunc(putn(&i,Z6.))
            %end;
            ;
  %end;
  run;
  quit;

  /* Tidy-up */
  filename gsasfile clear;

  %if &g_debug. le 8 %then
  %do;
    proc datasets lib=work nolist;
      delete &prefix: / mt=catalog;
    quit;
  %end;

  /* Delete temporary datasets used in this macro */
  %tu_tidyup(rmdset=&prefix:
            ,glbmac=NONE
            );

  %tu_abort;

%mend tu_templates;
