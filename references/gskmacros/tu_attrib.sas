/*******************************************************************************
|
| Macro Name:      tu_attrib
|
| Macro Version:   5 
|
| SAS Version:     8.2
|
| Created By:      Mark Luff / Eric Simms
|
| Date:            07-May-2004
|
| Macro Purpose:   Apply attributes to A&R dataset based on planned A&R dataset
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                            REQ/OPT  DEFAULT
| -----------------  -------------------------------------  -------  ----------
| DSETIN             Specifies the dataset for which the    REQ      (Blank)
|                    attributes must be assigned.
|                    Valid values: valid dataset name.
|
| DSETOUT            Specifies the name of the output A&R   REQ      (Blank)
|                    dataset to be created.
|                    Valid values: valid dataset name.
|
| DSETTEMPLATE       Specifies a user-supplied template     OPT      (Blank)
|                    (empty SAS dataset) which has the 
|                    same attributes as desired on the
|                    A&R dataset.  If this is specified,
|                    the DSETTEMPLATE dataset metadata will
|                    be used to determine the attributes
|                    to assign to the output dataset.
|                    NOTE: If DSETTEMPLATE is specified,
|                    then DSPLAN should be left blank.
|
| DSPLAN             Specifies the path and file name of    OPT      (Blank)
|                    HARP A&R dataset metadata.  This will
|                    define the metadata desired.  If this
|                    is specified, the HARP A&R dataset 
|                    plan will be used to determine the
|                    attributes to use in the &DSETOUT.
|                    NOTE: If DSPLAN is specified, then
|                    FORMATNAMESDSET and SORTORDER should
|                    be left blank.
|
| SORTORDER          Specifies a user-supplied sort order    OPT      (Blank)
|                    desired for the A&R dataset.  If this
|                    is specified, the SORTORDER value 
|                    will be used to sort the output 
|                    dataset. 
|                    NOTE: If SORTORDER is specified, then
|                    DSPLAN should be left blank.
| -----------------  -------------------------------------  -------  ----------
|
| The macro references the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETIN            Req      Parameter specified dataset
| &DSETTEMPLATE      Opt      Parameter specified dataset
| -----------------  -------  -------------------------------------------------
|
| Output:
|
| The macro outputs the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETOUT           Req      Parameter specified dataset
| -----------------  -------  -------------------------------------------------
|
| Global macro variables created: NONE
|
|
| Macros called:
|(@) tr_putlocals
|(@) tu_putglobals
|(@) tu_abort
|(@) tu_chkvarsexist
|(@) tu_getplanneddset
|(@) tu_sqlnlist
|(@) tu_getsortorder
|(@) tu_maxvarlen
|(@) tu_tidyup
|(@) tu_quotelst
|
| Example:
|    %tu_attrib(
|         dsetin          = _ae1,
|         dsetout         = _ae2,
|         dsplan          = &R_ARDATA/ae-spec.txt,
|         dsettemplate    = planned_ae
|         );
|
|******************************************************************************
| Change Log
|
| Modified By: Eric Simms
| Date of Modification: 14Dec04
| New version/draft number: 1/2
| Modification ID: ems001
| Reason For Modification: Change to some RTERROR messages.
|
| Change Log
|
| Modified By: Lee Seymour
| Date of Modification: 19Feb13
| New version/draft number: 2/1
| Modification ID: ljs001
| Reason For Modification: Updated for CDISC functionality. If study type is CDISC.
|                          then length attribute is ignored and is based on maximum
|                          length of the variables in the dataset
|
| Modified By: Lee Seymour
| Date of Modification: 02May13
| New version/draft number: 3/1
| Modification ID: ljs002
| Reason For Modification: Bug fix. Uppercasing character variable names 
|                          for g_datatype=CDISC
|
| Modified By:              Anthony J Cooper
| Date of Modification:     25-MAR-2015
| New version/draft number: 4/1
| Modification ID:          AJC001
| Reason For Modification:  When g_datatype=CDISC, only create attrib statements
|                           for variables in the planned dataset to avoid
|                           un-initialised variable messages in the log.
|
| Modified By:              Anthony J Cooper
| Date of Modification:     16-APR-2015
| New version/draft number: 5/1
| Modification ID:          AJC002
| Reason For Modification:  Add tu_quotelst to the macros called section of the
|                           header block so the HARP App copies it down.
*******************************************************************************/
%macro tu_attrib (
     dsetin          = ,       /* Input dataset name */
     dsetout         = ,       /* Output dataset name */
     dsplan          = ,       /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
     dsettemplate    = ,       /* Planned A&R dataset template name */
     sortorder       =         /* Planned A&R dataset sort order */
        );

 /*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion;
 %let MacroVersion = 5 build 1;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals() 

 /*
 / PARAMETER VALIDATION
 /----------------------------------------------------------------------------*/

 %let dsetin          = %nrbquote(&dsetin);
 %let dsetout         = %nrbquote(&dsetout);
 %let dsplan          = %nrbquote(&dsplan);
 %let dsettemplate    = %nrbquote(&dsettemplate);
 %let sortorder       = %nrbquote(&sortorder);

 /*
 / Check for required parameters.
 /----------------------------------------------------------------------------*/

 %if &dsetin eq %then
 %do;
    %put %str(RTE)RROR: TU_ATTRIB: The parameter DSETIN is required.;
    %let g_abort=1;
 %end;  /* end-if Required parameter DSETIN is not specified.  */

 %if &dsetout eq %then
 %do;
    %put %str(RTE)RROR: TU_ATTRIB: The parameter DSETOUT is required.;
    %let g_abort=1;
 %end;  /* end-if Required parameter DSETOUT is not specified.  */

 %if &dsettemplate ne  and &dsplan ne  %then
 %do;
    %put %str(RTE)RROR: TU_ATTRIB: Only one of DSETTEMPLATE or DSPLAN should be specified.;
    %let g_abort=1;
 %end;  /* end-if Both parameters, DSETTEMPLATE and DSPLAN are specified.   */

 %if &dsettemplate eq  and &dsplan eq  %then
 %do;
    %put %str(RTE)RROR: TU_ATTRIB: One of DSETTEMPLATE or DSPLAN should be specified.;
    %let g_abort=1;
 %end;  /* end-if Both parameters, DSETTEMPLATE and DSPLAN are not specified. */
 

 %if &sortorder ne  and &dsplan ne  %then
 %do;
    %put %str(RTE)RROR: TU_ATTRIB: Only one of SORTORDER or DSPLAN should be specified.;
    %let g_abort=1;
 %end;  /* end-if Both parameters, SORTORDER and DSPLAN are specified.  */

 %if &sortorder eq  and &dsplan eq  %then
 %do;
    %put %str(RTE)RROR: TU_ATTRIB: One of SORTORDER or DSPLAN should be specified.;
    %let g_abort=1;
 %end;  /* end-if Both parameters SORTORDER and DSPLAN are not specified.  */

 /*
 / Check for existing datasets.
 /----------------------------------------------------------------------------*/

 %if %sysfunc(exist(&dsetin)) eq 0 %then
 %do;
    %put %str(RTE)RROR: TU_ATTRIB: The dataset DSETIN (&dsetin) does not exist.; /* ems001 */
    %let g_abort=1;
 %end;  /* end-if  Specified dataset DSETIN does not exist.  */

 %if &dsettemplate ne and %sysfunc(exist(&dsettemplate)) eq 0 %then
 %do;
    %put %str(RTE)RROR: TU_ATTRIB: The dataset DSETTEMPLATE (&dsettemplate) does not exist.; /* ems001 */
    %let g_abort=1;
 %end;  /* end-if  Specified dataset DSETTEMPLATE does not exist.  */ 

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;

 /*
 / If the input dataset name is the same as the output dataset name,
 / write a note to the log.
 /----------------------------------------------------------------------------*/

 %if &dsetin eq &dsetout %then
 %do;
    %put %str(RTN)OTE: TU_ATTRIB: The input dataset name (&dsetin) is the same as the output dataset name (&dsetout).;
 %end;  /* end-if Specified values for parameters DSETIN and DSETOUT are the same.  */

 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/

 %local prefix;
 %let prefix = _attrib;   /* Root name for temporary work datasets */

 /*
 / Get planned dataset template.
 / Either the user specified a dataset template, or the user specified
 / the HARP dataset plan for the A&R dataset which will be used to build
 / a dataset template.
 /----------------------------------------------------------------------------*/

 %local l_template;

 %if &dsettemplate ne %then
 %do;
    %let l_template = &dsettemplate;
 %end;  /* end-if Parameter DSETTEMPLATE was specified.  */
 %else
 %do;
    %let l_template = &prefix._template;

    %tu_getplanneddset (
         dsettemplate    = &l_template,
         dsplan          = &dsplan 
    );



 %end;  /* end-if Parameter DSETTEMPLATE was not specified.  */



 /*
 / Split input dataset name into libname and member name parts.
 /----------------------------------------------------------------------------*/

 %local lib mem;

 %let lib = %scan(%upcase(&dsetin), -2, .);
 %let mem = %scan(%upcase(&dsetin), -1, .);

 %if &lib eq %then
 %do;
  %let lib = WORK;
 %end;

 /*
 / Obtain variable names of input dataset.
 /----------------------------------------------------------------------------*/

 proc sql noprint;
      create table &prefix._varnames as
      select upcase(name) as name
      from dictionary.columns
      where libname eq "&lib"
      and   memname eq "&mem"
      order by upcase(name);
 quit;

 /*
 / Obtain variable names of planned A&R dataset.
 /----------------------------------------------------------------------------*/

 proc sql noprint;
      create table &prefix._plannedvarnames as
      select upcase(name) as name
      from dictionary.columns
      where libname eq 'WORK'
      and   memname eq "%upcase(&l_template)"
      order by upcase(name);
 quit;


 /*
 / Report to the log those variables which are not on both the input dataset
 / and the planned A&R dataset.
 / NOTE: Variables which are on the planned A&R dataset but not on the input dataset:
 /          Write a note to the log. The variables will not be added to the output
 /          dataset. There is a HARP utility which will communicate this to
 /          the user.
 /       Variables which are on the input dataset but not on the planned A&R dataset:
 /          Write a note to the log. The variables will be dropped from the output
 /          dataset.
 /----------------------------------------------------------------------------*/

 data &prefix._keepvars(keep=name);
      merge &prefix._varnames (in=a) &prefix._plannedvarnames (in=b);
      by name;

      if a and b then
      do;
         output;
      end; /* end-if Variable NAME is on both the input dataset and the planned A&R dataset.  */
      else if b and not a then
      do;
         put "RTN" "OTE: TU_ATTRIB: Variable " name 'is on the planned A&R dataset but not on the input dataset.';
         output;
      end;  /* end-if Variable NAME is in &PREFIX._PLANNEDVARNAMES and is not in &PREFIX._VARNAMES.  */
      else if a and not b then
      do;
         put "RTN" "OTE: TU_ATTRIB: Variable " name 'is on the input dataset but not on the planned A&R dataset. It will be dropped.';
      end;  /* end-if Variable NAME is in &PREFIX._VARNAMES and is not in &PREFIX._PLANNEDVARNAMES.  */
 run;

 /*
 / Initialise macro variable to blank.
 /----------------------------------------------------------------------------*/

 %local keep;
 %let keep=;

 /*
 / Create macro variable to hold var names of input dataset, less those
 / not found on the planned A&R dataset.
 /----------------------------------------------------------------------------*/

 proc sql noprint;
      select distinct name into :keep separated by ' '
      from &prefix._keepvars;
 quit;

 /*
 / Deassign dataset formats.
 /----------------------------------------------------------------------------*/

 data &prefix._unformatted;
      set &dsetin;
      %if %str(&keep) ne %str() %then
      %do;
         format   &keep;
         informat &keep;
      %end;
 run;

 /*
 / Get planned dataset label.
 /----------------------------------------------------------------------------*/

 %local l_label;

 %let l_label=;

 proc sql noprint;
      select memlabel into :l_label
      from dictionary.tables
      where libname eq 'WORK' and memname eq "%upcase(&l_template)";
 quit;

 %let l_label=%nrbquote(%trim(&l_label));   /* Get rid of trailing blanks */


/* ljs001 */
%if &g_datatype=CDISC %then 
%do;

    /* Identify maximum length of character variables in input dataset */
    %tu_maxvarlen(dsetin=&dsetin,
                  dsetout=&prefix._mxvarlen);


    
    /*Build new series of attrib statements */ 
    filename tmp1 temp;
    data _null_;
    file tmp1;
    set &prefix._mxvarlen
      %if %str(&keep) ne %str() %then
      %do;
          (where=(upcase(name) in (%tu_quotelst(&keep))))
      %end; /* AJC001 */
      ;
    name=upcase(name);    /* ljs002 */
    put 'attrib ' name 'length=$' mlen ';'                  ;
    run;

    /*Planned Variable order.*/
     proc sql noprint;
         select name into : varlist
          separated by ' ' 
          from dictionary.columns
          where libname eq 'WORK'
          and   memname eq "%upcase(&l_template)"
          ;
     quit;


    /***************************************************************
    *  Apply attrib statements to reset variable length attributes *
    ***************************************************************/

    data &prefix.&l_template;
    %inc tmp1;
    set &l_template;
    run;


    /*************************************************
    * Reset variable order to planned variable order *
    *************************************************/
    proc sql;
    create table &l_template as
    select %tu_sqlnlist(&varlist)
    from &prefix.&l_template
    ;
    quit;


%end; /* End-if for g_datatype=CDISC*/



 /*
 / Force in the planned dataset properties.
 /----------------------------------------------------------------------------*/

 data &prefix._reconciled;
      if 0 then set &l_template;
      set &prefix._unformatted;
      %if %str(&keep) ne %str() %then
      %do;
          keep &keep;
      %end;
 run;

 /*
 / Get planned dataset variable sort order.
 /----------------------------------------------------------------------------*/

 %local l_sortorder;

 %if &sortorder ne %then
 %do;
    %let l_sortorder = &sortorder;
 %end;  /* end-if  Parameter SORTORDER was specified.  */
 %else
 %do;
    %tu_getsortorder (
         dsplan          = &dsplan,
         sortordermvar   = l_sortorder
    );
 %end;  /* end-if  Parameter SORTORDER was not specified.  */

 /*
 / Subset sort order on only those vars existing on both the input dataset and
 / the planned dataset.
 /----------------------------------------------------------------------------*/

 %local l_sortvar;
 %local l_sortlist;
 %local i;

 %let i = 1;
 %let l_sortvar = %upcase(%scan(&l_sortorder, 1, %str( )));

 %do %while(&l_sortvar ne );

    %if %tu_chkvarsexist(&prefix._reconciled,&l_sortvar) eq %then 
    %do;
       %let l_sortlist = &l_sortlist &l_sortvar;
    %end;  /* end-if  Variable  &L_SORTVAR is in dataset &PREFIX._UNRECONCILED.  */
    %else 
    %do;
       %put %str(RTN)OTE: TU_ATTRIB: Sort variable &l_sortvar not on the input dataset so will be dropped from sort order.;
    %end;  /* end-if  Variable  &L_SORTVAR does not exist in dataset &PREFIX._UNRECONCILED,  */ 

    %let i = %eval(&i + 1);
    %let l_sortvar = %upcase(%scan(&l_sortorder, &i, %str( )));
 %end;

 %put %str(RTN)OTE: TU_ATTRIB: Final sort order applied to output dataset: &l_sortlist..;


 /*
 / Sort and label dataset.
 /----------------------------------------------------------------------------*/

 %if %str(&l_label) eq %str() %then
 %do;
    proc sort data=&prefix._reconciled out=&dsetout;
 %end;  /* end-if  &L_LABEL  is not blank.  */
 %else 
 %do;
    proc sort data=&prefix._reconciled out=&dsetout (label="&l_label");
 %end;  /* end-if  &L_LABEL is blank.  */

      by &l_sortlist;
 run;

 /*
 / Delete temporary datasets used in this macro.
 /----------------------------------------------------------------------------*/

 %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tu_attrib;
