/*******************************************************************************
|
| Macro Name:      tu_adappend
|
| Macro Version:   1 build 1
|
| SAS Version:     9.3
|
| Created By:      Anthony J Cooper
|
| Date:            12-Nov-2014
|
| Macro Purpose:   To set together a number of input datasets. This macro
|                  determines the maximum length of character variables
|                  across datasets to avoid truncation.
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                            REQ/OPT  DEFAULT
| -----------------  -------------------------------------  -------  ----------
| DSETINLIST         Specifies the names of the input       REQ      (Blank)
|                    datasets which will be set together.
|                    Dataset options are allowed in which
|                    case the DELIM parameter should be 
|                    used to specify a suitable value so
|                    that the macro can determine the
|                    individual input dataset names.
|                    Valid values: valid dataset names.
|
| DSETOUT            Specifies the name of the output       REQ      (Blank)
|                    dataset to be created.
|                    Valid values: valid dataset name.
|
| DELIM              Specifies the delimeter used to        REQ      %str( )
|                    parse the input dataset names from
|                    DSETINLIST. If the datasets in 
|                    DSETINLIST contain dataset options
|                    then use a suitable value of DELIM,
|                    e.g. # instead of space character.
|
| -----------------  -------------------------------------  -------  ----------
|
| The macro references the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETINLIST        Req      Parameter specified list of datasets
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
|(@) tu_words
|(@) tu_maxvarlen
|(@) tu_nobs
|(@) tu_tidyup
|
| Examples:
|
|    %tu_adappend(
|         dsetinlist  = sdtmdata.suppce sdtmdata.suppqs sdtmdata.xi,
|         dsetout     = allsupp,
|         );
|
|    %tu_adappend(
|         dsetinlist  = ce (where=(qscat='LIVER EVENT')) # qs (where=(qscat='RUCAM')) # xi,
|         dsetout     = alldomain,
|         delim       = #
|         );
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
*******************************************************************************/

%macro tu_adappend(
  dsetinlist=,          /* List of input datasets to be appended */
  delim=%str( ),        /* Delimeter that separates input datasets in DSETINLIST */
  dsetout=              /* Output dataset to be created */
  );

  /*
  / Echo parameter values and global macro variables to the log.
  /----------------------------------------------------------------------------*/

  %local MacroVersion;
  %let MacroVersion = 1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals() 

  /*
  / PARAMETER VALIDATION
  /----------------------------------------------------------------------------*/

  %let dsetinlist      = %nrbquote(&dsetinlist);
  %let dsetout         = %nrbquote(&dsetout);

  /*
  / Check for required parameters.
  /----------------------------------------------------------------------------*/

  %if &dsetinlist eq %then
  %do;
     %put %str(RTE)RROR: &sysmacroname: The parameter DSETINLIST is required.;
     %let g_abort=1;
  %end;  /* end-if Required parameter DSETINLIST is not specified. */

  %if &dsetout eq %then
  %do;
     %put %str(RTE)RROR: &sysmacroname: The parameter DSETOUT is required.;
     %let g_abort=1;
  %end;  /* end-if Required parameter DSETOUT is not specified. */

  %if %length(&delim) eq 0 %then
  %do;
     %put %str(RTE)RROR: &sysmacroname: The parameter DELIM may not be blank.;
     %let g_abort=1;
  %end;  /* end-if Required parameter DELIM is not specified. */

  %if &g_abort eq 1 %then
  %do;
     %tu_abort;
  %end;

  /*
  / Check datasets specified in DSETINLIST.
  /----------------------------------------------------------------------------*/

  %local numdsetin loopi;
  %let numdsetin=%tu_words(string=&dsetinlist, delim=&delim);

  %do loopi=1 %to &numdsetin;

     %local l_dsetin&loopi;
     %let l_dsetin&loopi=%scan(&dsetinlist,&loopi,&delim);
     %put %str(RTN)OTE: &sysmacroname: Input dataset &loopi = &&l_dsetin&loopi.;

     %if %SYSFUNC(EXIST(%scan(&&&l_dsetin&loopi, 1, %str(%() ) )) NE 1 %then %do;
        %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETINLIST refers to a dataset %upcase("&&l_dsetin&loopi.") which does not exist.;
        %let g_abort = 1;
     %end;  /* end-if Dataset specified does not exist. */

  %end;

  %if &g_abort eq 1 %then
  %do;
     %tu_abort;
  %end;

  /*
  / NORMAL PROCESSING
  /----------------------------------------------------------------------------*/

  %local prefix;
  %let prefix=_adappend;

  %if &numdsetin eq 1 %then
  %do;

     %put %str(RTN)OTE: &sysmacroname: Only one input dataset specified. Setting DSETOUT to &dsetinlist..;

     data &dsetout;
       set %unquote(&dsetinlist);
     run;

  %end;  /* end-if One input dataset specified. */

  %else
  %do;

     /*
     / Check for conflicting variable types across the input datasets.
     /-------------------------------------------------------------------------*/

     %local lib mem thisdset;

     %do loopi=1 %to &numdsetin;

        %let thisdset=%scan(&&l_dsetin&loopi, 1, %str(%() );

        %if %index(&thisdset,.) %then 
        %do;
          %let lib = %scan(%upcase(&thisdset),-2, .);
          %let mem = %scan(%upcase(&thisdset),-1, .);
        %end; /* end-if libname specified */
        %else
        %do;
          %let lib = WORK;
          %let mem = %upcase(&thisdset);
        %end; /* end-if libname not specified */

        proc sql noprint;
          create table &prefix._vartype&loopi as select name, type
          from dictionary.columns
          where upcase(libname) eq "&lib" and upcase(memname) = "&mem";
        quit;

     %end;

     data &prefix._vartype_all;
       set
         %do loopi=1 %to &numdsetin;
            &prefix._vartype&loopi
         %end;
         ;
     run;

     proc sort data=&prefix._vartype_all nodupkey;
       by name type;
     run;

     data &prefix._vartype_error;
       set &prefix._vartype_all;
       by name type;
       if not(first.name and last.name);
     run;

     %if %tu_nobs(&prefix._vartype_error) gt 0 %then
     %do;

        %local l_vartype_error;
        proc sql noprint;
          select distinct upcase(trim(name)) into: l_vartype_error separated by ', ' from &prefix._vartype_error;
        quit;

        %put RTE%str(RROR:) &sysmacroname.: Variable(s) &l_vartype_error have been defined as both character and numeric.;
        %let g_abort = 1;
        %tu_abort;

     %end;

     /*
     / Find maximum character variable lengths for each input dataset.
     /-------------------------------------------------------------------------*/

     %do loopi=1 %to &numdsetin;
        %tu_maxvarlen(
           dsetin=%scan(&&l_dsetin&loopi, 1, %str(%() ),
           dsetout=&prefix._maxvarlen&loopi
           );
     %end;

     /*
     / Find maximum character variable lengths across all input datasets.
     /-------------------------------------------------------------------------*/

     data &prefix._maxvarlen_all;
       set
         %do loopi=1 %to &numdsetin;
            &prefix._maxvarlen&loopi
         %end;
         ;
     run;

     proc sort data=&prefix._maxvarlen_all;
       by name mlen;
     run;

     data &prefix._maxvarlen_final;
       set &prefix._maxvarlen_all;
       by name mlen;
       if last.name and not(first.name);
     run;

     /*
     / Build new series of attrib statements and create output dataset.
     / Where clause required to deal with scenario when all the input datasets
     / have 0 obs, in which case mlen will have a missing value.
     /-------------------------------------------------------------------------*/

     filename tmp_varl temp;

     data _null_;
       file tmp_varl;
       set &prefix._maxvarlen_final;
       where mlen >0;
       put 'attrib ' name 'length=$' mlen ';' ;
     run;

     data &dsetout;
       %inc tmp_varl;
       set
         %do loopi=1 %to &numdsetin;
            &&&l_dsetin&loopi
         %end;
         ;
     run;

     filename tmp_varl clear;

  %end;  /* end-if More than one input dataset specified. */

  %tu_tidyup(rmdset=&prefix.:, glbmac=none);

%mend tu_adappend;
