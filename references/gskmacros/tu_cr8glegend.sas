/*******************************************************************************
|
| Macro Name:      tu_cr8glegend
|
| Macro Version:   1
|
| SAS Version:     8.2
|                                                             
| Created By:      James McGiffen / Andrew Ratcliffe, RTSL
|
| Date:            13-Dec-2004
|
| Macro Purpose:   To create a graphical legend for subsequent use as an 
|                  overlay (for example, with %tu_templates).
|                  Note. The symbols used to produce the graphs must still 
|                        be in action at this point, else the legend will  
|                        not match the graphs.                             
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME            DESCRIPTION                           REQ/OPT  DEFAULT
| --------------  -----------------------------------   -------  ---------------
| gout            Specifies the output graphic catalog    REQ    [blank]
|                                                                
| goutent         Specifies the name of the output grseg  REQ    [blank]
|
| dsetin          Input dataset                           REQ    [blank] 
|
| XVAR            X variable                              REQ    [blank]                       
|
| YVAR            Y variable                              REQ    [blank] 
|
| ZVAR            Z variable                              REQ    [blank]
|
| KILL            Specifies if empty pre-existing catalog REQ    Y       
|
| LEGENDLABEL     Should the legend include a label       REQ    N
|
| ORDERMVAR       Specifies a value for the ORDER parm    OPT    [blank]
|                  of the LEGEND statement
|
| Output: One GRSEG entry containing a legend
|
| Global macro variables created: NONE
|
| Macros called:
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_chknames
| (@) tu_chkvarsexist
| (@) tu_footer
| (@) tu_header
| (@) tu_nobs
| (@) tu_putglobals
| (@) tu_words
| (@) tu_tidyup
|
| Example:
|      goptions nodisplay;
|      %tu_cr8glegend(gout=work.pktfig_legend
|                 ,goutent=legend
|                 ,kill=y
|                 ,legendlabel=N
|                 ,dsetin=sortedPkcnc
|                 ,xvar=eltmstn
|                 ,yvar=pcstimpn
|                 ,zvar=trtgrp
|                 );
|      goptions display;
|
|******************************************************************************
| Change Log
|
| Modified By:              Trevor Welby
| Date of Modification:     21-Apr-05
| New version/draft number: 01-002
| Modification ID:          TQW9753.01-002
| Reason For Modification:  
|                           %local i removed
|                           Call to PROC CATALOG: QUIT now replaces RUN
|                           Update %str(RT)ERROR to %str(RTE) RROR
|
|*******************************************************************************
|
| Modified By:              Trevor Welby
| Date of Modification:     04-May-05
| New version/draft number: 01-003
| Modification ID:          TQW9753.01-003
| Reason For Modification:  
|                           Removed the use of %substr function on KILL and 
|                           LEGENDLABEL parameters in the parameter validation 
|                           section
|
|                           Validation of parameters: GOUT, GOUTENT and DSETIN
|                           enhanced
|
|*******************************************************************************
|
| Modified By:              James McGiffen
| Date of Modification:     19-May-05
| New version/draft number: 01-004 
| Modification ID:          JMcG-01.004
| Reason For Modification:  Data needs to handle Character data - Tech issue 129
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

%macro tu_cr8glegend(
  gout=                            /* Specifies the output graphic catalog*/ 
 ,goutent=                         /* Specifies the name of the output grseg */
 ,dsetin=                          /* Input dataset */                    
 ,XVAR=                            /* X variable for the graph  */
 ,YVAR=                            /* Y variable for the graph */
 ,ZVAR=                            /* Z variable for the graph  */
 ,KILL= Y                          /* Specifies if we should empty pre-existing catalog */
 ,LEGENDLABEL=N                    /* Should the legend include a label */
 ,ORDERMVAR=                       /* Specifies value for ORDER part of LEGEND stmt */
  );
  
  /* Echo parameter values and global macro variables to the log */

  %local MacroVersion;
  %let MacroVersion = 1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals();
  
  %local prefix;
  %let prefix = %substr(&sysmacroname,3); 
  
  /* PARAMETER VALIDATION */

  %let gout= %nrbquote(&gout.);
  %let goutent= %nrbquote(&goutent.);
  %let dsetin= %nrbquote(&dsetin.);
  %let XVAR = %nrbquote(&XVAR.);
  %let YVAR = %nrbquote(&yVAR.);
  %let ZVAR = %nrbquote(&ZVAR.); 
  %let kill = %nrbquote(%upcase(&kill.)); *[TQW9753.01.003];
  %let legendlabel = %nrbquote(%upcase(&legendlabel.)); *[TQW9753.01.003];
  %let orderMvar = %upcase(&ordermvar);
  
  /* Check for required parameters */

  /*-- check that gout has a valid value TQW9753.01-003*/
  %if %length(&gout.) eq 0 %then 
  %do;  /* GOUT is blank */
    %put %str(RTE)RROR: &sysmacroname.: The GOUT parameter must not be blank.;
    %let g_abort=1;
  %end;  /* GOUT is blank */
  %else
  %do;  /* GOUT is not blank */
    %if %tu_words(&gout.,delim=%str( )) GT 1 %then
    %do;  /* GOUT has multiple words */
      %put %str(RTE)RROR: &sysmacroname.: The value specified as GOUT (&gout.) has multiple words and is not a valid catalog name;
      %let g_abort=1;
    %end;  /* GOUT has multiple words */
    %else
    %do;  /* GOUT is a word */
      %if %length(%tu_chknames(&gout.,DATA)) ne 0 %then
      %do;  /* Invalid catalog name */
        %put %str(RTE)RROR: &sysmacroname.: The value specified as GOUT (&gout.) is not a valid catalog name;
        %let g_abort=1;
      %end;  /* Invalid catalog name */
    %end;  /* GOUT is a word */
  %end; /* GOUT is not blank */

  /*-- check that goutent has a valid value TQW9753.01-003*/
  %if %length(&goutent.) eq 0 %then 
  %do;  /* GOUTENT is blank */
    %put %str(RTE)RROR: &sysmacroname.: The GOUTENT parameter must not be blank.;
    %let g_abort=1;
  %end;  /* GOUTENT is blank */
  %else
  %do;  /* GOUTENT is not blank */
    %if %tu_words(&goutent.,delim=%str( )) GT 1 %then
    %do;  /* GOUTENT has multiple words */
      %put %str(RTE)RROR: &sysmacroname.: The value specified as GOUTENT (&goutent.) has multiple words and is not a valid catalog name;
      %let g_abort=1;
    %end;  /* GOUTENT has multiple words */
    %else
    %do;  /* GOUTENT is a word */
      %if %index(&goutent.,.) %then
      %do;  /* Period found */
        %put %str(RTE)RROR: &sysmacroname.: The value specified as GOUTENT (&goutent.) is a multi-level name and is not a valid catalog name;
        %let g_abort=1;
      %end;  /* Period found */
      %else
      %do;  /* Period NOT found */
        %if %length(%tu_chknames(&goutent.,DATA)) ne 0 %then
        %do;  /* Invalid catalog name */
          %put %str(RTE)RROR: &sysmacroname.: The value specified as GOUTENT (&goutent.) is not a valid catalog name;
          %let g_abort=1;
        %end;  /* Invalid catalog name */
      %end;  /* Period NOT found */
    %end;  /* GOUTENT is a word */
  %end; /* GOUTENT is not blank */  
  
  /*-- check that dsetin is not blank and exists [TQW9753.01-003] */;
  %if %length(&dsetin.) eq 0 %then
  %do;  /* dsetin is blank */
    %put %str(RTE)RROR: &sysmacroname.: The DSETIN parameter must not be blank.;
    %let g_abort=1;
  %end;  /* dsetin is blank */ 
  %else
  %do;  /* dsetin is not blank */
    %if not %sysfunc(exist(&dsetin., data)) %then 
    %do;  /* dsetin does not exist */
      %put %str(RTE)RROR: &sysmacroname.: The dataset identified by DSETIN (&dsetin.) does not exist.;
      %let g_abort=1;
    %end;  /* dsetin does not exist */
    %else 
    %do; /* dsetin does exist */
      %if %length(%tu_chkvarsexist(&dsetin., &XVAR. &YVAR. &ZVAR.)) gt 0  %then 
      %do;  /*-- check that X, Y and Z are on the dataset [TQW9753.01-002] */
        %put %str(RTE)RROR: &sysmacroname.: The plot/legend variable(s) %trim(%tu_chkvarsexist(&dsetin,&XVAR. &YVAR. &ZVAR.)) do not exist in DSETIN (&DSETIN);
        %let g_abort = 1;
      %end; /*-- check that X, Y and Z are on the dataset [TQW9753.01-002] */
    %end; /* dsetin does exist */
  %end;  /* dsetin is not blank */
   
  /*--checking that kill is y or n*/
  %if &kill ne Y and &kill ne N %then 
  %do;
    %put %str(RTE)RROR: &sysmacroname.: The value of parameter KILL (&kill.) is not Y or N.;
    %let g_abort=1;
  %end;  

  /*--checking that legendlabel is y or n*/
  %if &legendlabel ne Y and &legendlabel ne N %then 
  %do;
    %put %str(RTE)RROR: &sysmacroname.: The value of parameter LEGENDLABEL (&legendlabel.) is not Y or N.;
    %let g_abort=1;
  %end; 
  
  /*--checking that ordermvar is known*/
  %if %length(&ordermvar) gt 0 %then 
  %do;
    %local foundord;
    data _null_;
      call symput('FOUNDORD','N');
      set sashelp.vmacro (where=(scope ne 'AUTOMATIC' and name eq "&ordermvar"));
      call symput('FOUNDORD','Y');
      STOP;
    run;

    %if &foundord ne Y %then
    %do;
      %put %str(RTE)RROR: &sysmacroname: The specified ORDERMVAR (&ordermvar) is not a known macro variable. Declare it as 'local' beforehand;
      %let g_abort=1;
    %end;
  %end; 
   
  /*-- abort at the end of the parameter validation section if a failure has occurred */
  %tu_abort;
  
  /* NORMAL PROCESSING */
 
   /* Tidy-up first? */
  %if &kill eq Y and %sysfunc(exist(&gout,catalog)) %then 
  %do;
    proc catalog c=&gout kill;
    quit; *[TQW9753.01-002];
  %end;

  %tu_header;

  %tu_footer(dsetout=work.&prefix._footerout); /* dataset not used, see below */

  %if %tu_nobs(work.&prefix._footerout) ne 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname: Footer(s) contain illegal column references.;
    %tu_abort(option=force);
  %end;

  goptions ctitle=white cby=white;

  /*----------------------------------------------------------------------*/
  /*JMcG-01.004 The axis statement is variable type dependant*/
    axis1 
      %if %tu_chkvartype(dsetin = &dsetin, varin=&xvar.) = N %then %do;
        order=(-999 to -998 by 1) /* Avoid any plot points showing */
      %end;
      %else %if %tu_chkvartype(dsetin = &dsetin, varin=&xvar.) = C %then %do;
        order=('DAY' )
      %end;
    color=white;            /* Make the axis white */

    axis2 
      %if %tu_chkvartype(dsetin = &dsetin, varin=&yvar.) = N %then %do;
        order=(-999 to -998 by 1) /* Avoid any plot points showing */
      %end;
      %else %if %tu_chkvartype(dsetin = &dsetin, varin=&yvar.) = C %then %do;
        order=('DAY' )
      %end;
    color=white;            /* Make the axis white */

  /*----------------------------------------------------------------------*/

  legend1 frame
          %if &legendLabel eq N %then %do;
            label=none
          %end;
          %if %length(&orderMvar) gt 0 %then %do;
            order=(&&&orderMvar)
          %end;
          ;

  /*JMcG-01.004 Need to have two different types of axis in case one is */
  /*            numeric and the other character */
  proc gplot data=&dsetin gout=&gout;
    plot &yvar * &xvar = &zvar 
         / 
         legend=legend1 name="&goutent" vaxis=axis2 haxis=axis1;
  run;

  /* Delete temporary datasets used in this macro */
  %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

  %tu_abort;

%mend tu_cr8glegend;
