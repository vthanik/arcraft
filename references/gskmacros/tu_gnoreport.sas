/*******************************************************************************
|
| Macro Name:     tu_gnoreport.sas
|
| Macro Version:  2
|
| SAS Version:    8.2
|
| Created By:     Andrew Ratcliffe
|
| Date:           13-Dec-2004
|
| Macro Purpose:  This macro produces graphics output stating "No data to
|                 report" (the localised version of the MESSAGEKEY parameter).
|
| Macro Design:   Procedure style
|
| Input Parameters (all required):
|
| NAME            DESCRIPTION                                    DEFAULT
| OUTFILE         The name of the output file                    &g_outfile..&g_textfilesfx
|
| MESSAGEKEY      Specifies the localisation key of the message  NODATA
|                 to be written to the output page
|
|
| Output:         A graphics file containing the "No data to report" slide
|
| Global macro variables created: none
|
| Macros called:
|(@) tr_putlocals
|(@) tu_abort
|(@) tu_header
|(@) tu_footer
|(@) tu_nobs
|(@) tu_putglobals
|(@) tu_tidyup
|
| Example:
|
|   %tu_gnoreport(outfile=/arenv/arprod/c/s/r/output/fnc);
|
|*******************************************************************************
| Change Log
|
| Modified By:              Trevor Welby
| Date of Modification:     19-May-05
| New version/draft number: 01.002
| Modification ID:          TQW9753.01.002
| Reason For Modification:
|                           Quote macro parameters using %NRBQUOTE
|
|                           Augment validation of the OUTFILE parameter
|                           - Verify that the parameter is not blank
|                           - Verify that a directory is specified
|                           - Verify that the directory exists
|
|*******************************************************************************
|
| Modified By:              Shivam Kumar
| Date of Modification:     21-OCT-2013
| New version/draft number: 02.001
| Modification ID:
| Reason For Modification: Replace local macro variable sysmsg with l_sysmsg  
|
********************************************************************************/
%macro tu_gnoreport(outfile   =&g_outfile..&g_textfilesfx /* Output file name             */
                   ,messagekey=NODATA                     /* Key of message to be written */
                   );

  /* Echo values of parameters and global macro variables to the log */
  %local MacroVersion;
  %let MacroVersion=2;
  %include "&g_refdata./tr_putlocals.sas";
  %tu_putglobals();

  %local prefix;
  %let prefix=%substr(&sysmacroname,3);

  %let outfile=%nrbquote(&outfile.);
  %let messagekey=%nrbquote(&messagekey.);

  /* Perform parameter validation */
  %if %length(&outfile.) eq 0 %then
  %do;  /* OUTFILE is blank */
    %put RTE%str(RROR): &sysmacroname.: The OUTFILE parameter cannot be blank;
    %let g_abort=1;
  %end;  /* OUTFILE is blank */
  %else
  %do;  /* OUTFILE is not blank */
    /* check OUTFILE contains a directory */
    %local OutSearch Dirlen;
    %let OutSearch=%scan(&outfile.,-1,/\);
    %if &g_debug. ge 1 %then
      %put RTD%str(EBUG) : &sysmacroname. : OutSearch: &OutSearch;
    %let Dirlen=%length(&outfile.)-%length(&OutSearch.);
    %if &g_debug. ge 1 %then
      %put  RTD%str(EBUG) : &sysmacroname. : Dirlen: &Dirlen.;
    %if &Dirlen. eq 0 %then
    %do;  /* No Directory */
      %put RTE%str(RROR): &sysmacroname.: OUTFILE (&outfile.) does not include a directory name;
      %let g_abort=1;
    %end;  /* No Directory */
    %else
    %do;  /* Directory found */
      /* check that the directory exists */
      %local directory filelen;
      %let filelen=%length(%scan(&outfile.,-1,/\));
      %if &g_debug. ge 1 %then
        %put  RTD%str(EBUG) : &sysmacroname. : Filelen: &filelen.;
      %let directory=%substr(&outfile.,1,%length(&outfile.)-&filelen.-1);
      %if &g_debug. ge 1 %then
        %put  RTD%str(EBUG) : &sysmacroname. : Directory: &directory.;
      %local fileref rc;
      %let fileref=fileref;
      %let rc=%sysfunc(filename(&fileref.,&directory.));
      %if &g_debug. ge 1 %then
        %put  RTD%str(EBUG) : &sysmacroname. : Assigned fileref RC: &rc.;
      %if &rc. ne 0 %then
      %do;  /* Fileref invalid */
        %local l_sysmsg;
        %let l_sysmsg=%sysfunc(sysmsg());
        %put RTE%str(RROR): &sysmacroname.: &l_sysmsg.;
        %let g_abort=1;
      %end;  /* Fileref invalid */
      %else
      %do;  /* Fileref valid */
        %local dirid;
        %let dirid=%sysfunc(dopen(&fileref.));
        %if &g_debug. ge 1 %then
          %put  RTD%str(EBUG) : &sysmacroname. : DIRID: &dirid.;
        %if &dirid. eq 0 %then
        %do;  /* Directory does not exist */
          %put RTE%str(RROR): &sysmacroname.: The directory specified by the OUTFILE (&outfile.) parameter does not exist;
          %let g_abort=1;
        %end; /* Directory does not exist */
        %else
        %do;  /* Directory exists */
          /* tidy-up */
          %let rc=%sysfunc(dclose(&dirid.));
          %if &g_debug. ge 1 %then
            %put  RTD%str(EBUG) : &sysmacroname. : Close directory RC: &rc.;
          %let rc=%sysfunc(filename(&fileref.));
          %if &g_debug. ge 1 %then
            %put  RTD%str(EBUG) : &sysmacroname. : Deassign fileref RC: &rc.;
        %end; /* Directory exists */
      %end;  /* Fileref valid */
    %end; /* Directory found */
  %end; /* OUTFILE is not blank */

  /* Check that MESSAGEKEY is not blank */

  %if %length(&messagekey.) eq 0 %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: The MESSAGEKEY parameter cannot be blank;
    %let g_abort=1;
  %end;

  %tu_abort;

  /* Perform Normal Processing */
  /* Create headers and footers */
  %tu_header;
  %tu_footer(dsetout=work.&prefix._footerout);  /* dataset not used, see below */

  %if %tu_nobs(work.&prefix._footerout) ne 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: Footer(s) contain illegal column references.;
    %let g_abort=1;
  %end;

  %tu_abort;

  /* Resolve the message text */
  %local nodatamsg;
  %let nodatamsg=%sysfunc(putc(&messageKey,$local.));

  /* Resolve the "page 1 of 1" */

  /*
  / We will achieve right-aligned text by rotating it
  / all backwards, so must reverse our message!
  /------------------------------------------------------*/
  %local pagemsg localOf localPage;
  %let localOf=%sysfunc(putc(OF,$local.));
  %let localPage=%sysfunc(putc(PAGE,$local.));
  %let pagemsg=1 %sysfunc(reverse(&localOf)) 1 %sysfunc(reverse(&localPage));

  /* Direct output to output file */
  goptions gaccess=gsasfile;
  filename gsasfile "&outfile";

  /* Produce the output */
  %local i;
  proc gslide;
    note angle=180 rotate=180 move=(100pct,98pct) "&pagemsg";
    %do i=1 %to 10;
      note ' ';
    %end;
    note justify=center box=1 "&nodatamsg";
  run; quit;

  /* Tidy-up */
  filename gsasfile clear;

  %tu_tidyup(rmdset=&prefix:
            ,glbmac=NONE);

  %tu_abort;

%mend tu_gnoreport;
