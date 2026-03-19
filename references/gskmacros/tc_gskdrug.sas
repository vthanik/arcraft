/*******************************************************************************
|
| Macro Name:      tc_gskdrug
|
| Macro Version:   3
|
| SAS Version:     9.1
|
| Created By:      Eric Simms
|
| Date:            30-Jun-2004
|
| Macro Purpose:   GSKDrug wrapper macro
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                            REQ/OPT  DEFAULT
| -----------------  -------------------------------------  -------  ----------
| CONMEDSDSET        Specifies the CONMEDS-format SI        REQ      DMDATA.CONMEDS
|                    dataset which contains the CMDRGCOL 
|                    values which will be used to extract 
|                    those GSKDRUG records of interest to 
|                    this study.
|                    Valid values: valid dataset name
|
| GSKDRUGDSET        Specifies the GSKDrug dictionary SAS   REQ      DICTION.GSKDRUG 
|                    dataset.
|                    Valid values: valid dataset name
|
| DSETOUT            Specifies the name of the output       REQ      ARDATA.GSKDRUG
|                    dataset to be created.
|                    Valid values: valid dataset name
|
| DERIVATIONYN       Call %tu_derive to perform specific    REQ      Y
|                    derivations for this domain code (DG)?
|                    Valid values: Y, N
|
| ATTRIBUTESYN       Call %tu_attrib to assign the          REQ      Y
|                    A&R-defined attributes to the output 
|                    dataset?
|                    Valid values: Y, N
|
| MISSCHKYN          Call %tu_misschk to print RTWARNING    REQ      Y
|                    messages for each variable in 
|                    &DSETOUT which has missing values
|                    on all records.                    
|                    Valid values: Y, N.              
|
| DSPLAN             Specifies the path and file name of    OPT      &g_dsplanfile
|                    the HARP A&R dataset metadata. This
|                    will define the attributes to use to
|                    define the A&R dataset.
|                    NOTE: If DSPLAN is not specified
|                          i.e. left to its default value,
|                          or is specified as anything
|                          other than blank, then
|                          DSETTEMPLATE and SORTORDER 
|                          must not be specified as anything 
|                          non-blank. If DSETTEMPLATE and
|                          SORTORDER are specified as anything
|                          non-blank, then DSPLAN must be 
|                          specified as blank (DSPLAN=,).
|
| DSETTEMPLATE       Specifies the name of the empty        OPT      (Blank)
|                    dataset containing the variables
|                    and attributes desired for the A&R
|                    dataset.
|                    NOTE: If DSETTEMPLATE is specified
|                          as anything non-blank, then
|                          DSPLAN must be specified as
|                          blank (DSPLAN=,).
|
| SORTORDER          Specifies the sort order desired for   OPT      (Blank)
|                    the A&R dataset.
|                    NOTE: If SORTORDER is specified
|                          as anything non-blank, then
|                          DSPLAN must be specified as
|                          blank (DSPLAN=,).
|
| NODERIVEVARS       List of domain-specific variables not  OPT      (Blank)
|                    to derive when %tu_derive is called. 
| -----------------  -------------------------------------  -------  ----------
|
| The macro references the following datasets :-
| ------------------  -------  ------------------------------------------------
| Name                Req/Opt  Description
| ------------------  -------  ------------------------------------------------
| &CONMEDS            Req      Parameter specified dataset
| &DSETTEMPLATE       Opt      Parameter specified dataset
|
| ------------------  -------  ------------------------------------------------
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
|(@) tu_abort
|(@) tu_attrib
|(@) tu_derive
|(@) tu_misschk
|(@) tu_nobs
|(@) tu_putglobals
|(@) tu_tidyup
|
| Examples:
|    %tc_gskdrug(
|         dsplan = &g_dsplanfile
|         );
|
|    %tc_gskdrug(
|         dsplan          = ,
|         dsettemplate    = attrib_data,
|         sortorder       = studyid visitnum
|         );
|
|******************************************************************************
| Change Log
|
| Modified By:              Yongwei Wang
| Date of Modification:     31-Mar-2005
| New version/draft number: 1/2
| Modification ID:          YW001
| Reason For Modification:  Removed FORMATNAMESDSET
|******************************************************************************
| Modified By:              Yongwei Wang
| Date of Modification:     17-Sep-07
| New version/draft number: 2/1
| Modification ID:          YW002
| Reason For Modification:  Based on change request HRT0184 and HRT0172:  
|                           1. Added call of %tu_nobs and make data set options
|                              work for input data sets
|******************************************************************************
| Modified By:             Khilit Shah
| Date of Modification:    28Sep09
| New version/draft number:3/1
| Modification ID:         KS001
| Reason For Modification: Based on Change Request HRT0229
|                          Two additional base variables to be derived
|                            1) CMBASECD =  first 6 characters of the CMCOMPCD
|                            2) CMBASE = CMBASED || 01  then linked with CMCOMP
|                          and added to the the A&R GSKDrug dataset if they do
|                          not exist.
|******************************************************************************
| Modified By:
| Date of Modification:
| New version/draft number:
| Modification ID:
| Reason For Modification:
|
*******************************************************************************/
%macro tc_gskdrug (
     conmedsdset       = DMDATA.CONMEDS,  /* CONMEDS dataset name */
     gskdrugdset       = DICTION.GSKDRUG, /* GSKDRUG dataset name */
     dsetout           = ARDATA.GSKDRUG,  /* Output dataset name  */

     derivationyn      = Y,       /* Dataset specific derivations */   
     attributesyn      = Y,       /* Reconcile A&R dataset with planned A&R dataset */
     misschkyn         = Y,       /* Print warning message for variables in &DSETOUT with missing values on all records */ 
     dsplan            = &g_dsplanfile, /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
     dsettemplate      = ,        /* Planned A&R dataset template name */
     sortorder         = ,        /* Planned A&R dataset sort order */
     noderivevars      =          /* List of variables not to derive */
        );

 /*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion;
 %let MacroVersion = 3;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals() 

 /*
 / PARAMETER VALIDATION
 /----------------------------------------------------------------------------*/

 %let conmedsdset       = %nrbquote(&conmedsdset);
 %let gskdrugdset       = %nrbquote(&gskdrugdset);
 %let dsetout           = %nrbquote(&dsetout);

 %let derivationyn      = %nrbquote(%upcase(%substr(&derivationyn, 1, 1)));
 %let attributesyn      = %nrbquote(%upcase(%substr(&attributesyn, 1, 1)));
 %let misschkyn         = %nrbquote(%upcase(%substr(&misschkyn, 1, 1)));

 /*
 / Check for required parameters.
 /----------------------------------------------------------------------------*/

 %if &conmedsdset eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter CONMEDSDSET is required.;
    %let g_abort=1;
 %end;

 %if &gskdrugdset eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter GSKDRUGDSET is required.;
    %let g_abort=1;
 %end;

 %if &dsetout eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter DSETOUT is required.;
    %let g_abort=1;
 %end;

 %if &derivationyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter DERIVATIONYN is required.;
    %let g_abort=1;
 %end;

 %if &attributesyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter ATTRIBUTESYN is required.;
    %let g_abort=1;
 %end;

 %if &misschkyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter MISSCHKYN is required.;
    %let g_abort=1;
 %end;

 /*
 / Check for valid parameter values.
 /----------------------------------------------------------------------------*/

 %if &derivationyn ne Y and &derivationyn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: DERIVATIONYN should be either Y or N.;
    %let g_abort=1;
 %end;

 %if &attributesyn ne Y and &attributesyn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: ATTRIBUTESYN should be either Y or N.;
    %let g_abort=1;
 %end;

 %if &misschkyn ne Y and &misschkyn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: MISSCHKYN should be either Y or N.;
    %let g_abort=1;
 %end;

 /*
 / If one of the input dataset names is the same as the output dataset name,
 / write an error to the log.
 /----------------------------------------------------------------------------*/

 %if %qscan(&conmedsdset, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The conmeds dataset name CONMEDSDSET(=&conmedsdset) is the same as the output dataset name DSETOUT(=&dsetout).;
    %let g_abort=1;
 %end;

 %if %qscan(&gskdrugdset, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The gskdrug dataset name GSKDRUGDSET(=&gskdrugdset) is the same as the output dataset name DSETOUT(=&dsetout).;
    %let g_abort=1;
 %end;
 
 /*
 / Check for existance of input data sets.
 /----------------------------------------------------------------------------*/

 %if &conmedsdset ne %then
    %if %tu_nobs(&conmedsdset) lt 0 %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: Data set CONMEDSDSET(=&conmedsdset) does not exist.;
       %let g_abort=1;
    %end;

 %if &gskdrugdset ne %then
    %if %tu_nobs(&gskdrugdset) lt 0 %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: Data set GSKDRUGDSET(=&gskdrugdset) does not exist.;
       %let g_abort=1;
    %end;

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;

 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/

 %local prefix;
 %let prefix = _tc_gskdrug;   /* Root name for temporary work datasets */

 /*
 / Initialise counter for appending to temporary dataset names for the
 / purpose of tracking datasets through a number of optional sequential
 / data processing steps.
 /----------------------------------------------------------------------------*/

 %local i;
 %let i = 1;

 /*
 / KS001 
 / For all of the CMDRGCOL codes found in the CONMEDS dataset, get the corresponding
 / records from the GSKDrug dictionary.
 /----------------------------------------------------------------------------*/

 proc sql noprint;
      create table &prefix._ds&i as
      select a.*, substr(cmcompcd,1,6) as CMBASECD
      from %unquote(&gskdrugdset) as a
      where cmdrgcol in (select distinct cmdrgcol from %unquote(&conmedsdset)
                         union
                         select distinct cmcompcd as cmdrgcol
                         from %unquote(&gskdrugdset)
                         where cmdrgcol in (select distinct cmdrgcol from &conmedsdset)
                         
                        )
                        order by cmbasecd ;

     /* KS001 */
     /* Create a subset of diction.gskdrug by only keeping those CMCOMPCD ending with 01  */
     create table &prefix._base as
            select *, substr(cmcompcd,1,6) as CMBASECD, cmcomp as CMBASE
            from diction.gskdrug
            where  index((LEFT(TRIM(reverse(cmcompcd)))),'10') = 1
            order by cmdrgcol ;
 quit;

 /* KS001                                                                              */
 /* Create a lookup dataset to identify those records in raw dataset that do not have  */
 /*   the CMCOMPCD ending with 01                                                      */

 data &prefix._lookup1 (keep=cmdrgcol);
   set &prefix._ds&i ;
   cmdrgcol = compress(left(trim(cmbasecd)) !! '01') ;
 proc sort nodupkey;
   by cmdrgcol;
 run;

 data &prefix._lookup2;
   merge &prefix._lookup1 (IN=a)_tc_gskdrug_base (IN=b)   ;
   by cmdrgcol;
   IF a AND b;
 proc sort ;
   by cmbasecd ;
 run;

 %let i = %eval(&i + 1);

 DATA &prefix._ds&i (drop=cm_tmpbase);
   set &prefix._lookup2 (RENAME=(cmbase=cm_tmpbase) IN=a ) &prefix._ds%eval(&i-1) (IN=b) ;
   by cmbasecd ;
   retain cmbase ;
    IF first.cmbasecd and cm_tmpbase = '' then cmbase = cm_tmpbase ;
    if cm_tmpbase ne '' then cmbase = cm_tmpbase ;
    IF cmbase  = '' then cmbase = 'NO BASE SPECIFIED' ;
 proc sort ;
   BY cmcompcd ;
 run;


 data _null_;
      set %unquote(&conmedsdset);
      call symput('studyid',trim(studyid));
      stop;
 run;

 data &prefix._ds%eval(&i+1);
      set &prefix._ds&i;
      studyid="&studyid";
 proc sort NODUPKEY;
   by _ALL_ ;
 run;

 %let i = %eval(&i + 1);

 /*
 / Dataset specific derivations.
 /----------------------------------------------------------------------------*/

 %if &derivationyn eq Y %then
 %do;
    %tu_derive (
         dsetin            = &prefix._ds&i,
         dsetout           = &prefix._ds%eval(&i+1),
         domaincode        = dg,                     /* Domain Code - type of dataset */
         noderivevars      = &noderivevars           /* List of variables not to derive */
    );

    %let i = %eval(&i + 1);
 %end;

 /*
 / Reconcile A&R dataset with planned A&R dataset.
 /----------------------------------------------------------------------------*/

 %if &attributesyn eq Y %then
 %do;
    %tu_attrib(
         dsetin          = &prefix._ds&i,
         dsetout         = &dsetout,
         dsplan          = &dsplan,
         dsettemplate    = &dsettemplate,
         sortorder       = &sortorder
    );
 %end;
 %else
 %do;
    data %unquote(&dsetout);
         set &prefix._ds&i;
    run;
 %end;

 /*
 / Call tu_misschk macro in order to identify any variables in the 
 / &DSETOUT dataset which have missing values on all records.
 /----------------------------------------------------------------------------*/

 %if &misschkyn eq Y %then
 %do;
    %tu_misschk(
         dsetin        = &dsetout
    );
 %end;

 /*
 / Delete temporary datasets used in this macro.
 /----------------------------------------------------------------------------*/

 %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tc_gskdrug;
