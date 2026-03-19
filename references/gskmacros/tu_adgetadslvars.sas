/*******************************************************************************
| Macro Name: 	        tu_adgetadslvars.sas
|
| Macro Version: 	    2 build 1
|
| SAS Version: 	        SAS v9.1
|
| Created By:           Gaurav Gupta (gg158110)
|
| Date:                 20-Aug-2012
|
| Macro Purpose:	    To merge selected variables from ADSL dataset to input dataset.
|
| Macro Design:	        Procedure Style
|
| Input Parameters:
|
| NAME                DESCRIPTION                            	     DEFAULT
| -----------------  -----------------------------------------  	----------
| ADSLDSET            Specifies the name of the ADSL dataset.        None
|
| ADSLVARS            Space separated list of variables to be 	     studyid invid siteid
|			          fetched from ADSL dataset.			         usubjid age ageu sex race
|
| DSETIN              Specifies the dataset in which ADSL 		     None
|			          variables need to be merged.
|
| DSETOUT             Specifies the name of the output dataset	     None
|			          to be created.
|-----------------  ------------------------------------------	    ----------
|
| Output: 		      Output dataset passed by user against DSETOUT parameter and will consist
|                     data from input dataset and the additional variable from ADSL dataset.
|
| Global macro variables created: None
|
| Macros called :
|  (@) tr_putlocals
|  (@) tu_putglobals
|  (@) tu_abort
|  (@) tu_chknames
|  (@) tu_chkvarsexist
|  (@) tu_expvarlist
|  (@) tu_tidyup
|
| Example:
|    %tu_adgetadslvars (dsetin  = dmdata.ae,
|                       adsldset = adsl,
|                       adslvars = sex age,
|                       dsetout = temp );
|
|*******************************************************************************
| Change Log
|
| Modified By:              Anthony J Cooper
| Date of Modification:     13-May-2014
| New version/draft number: 2 build 1
| Modification ID:          AJC001
| Reason For Modification:  1) add nodupkey to proc sort of adsldset to cater
|                              for XO studies where ADTRT may be supplied
|                           2) delete global macro variable EXPVARS via tidyup
|
********************************************************************************/

%macro tu_adgetadslvars (
       dsetin= ,    /* Name of the input dataset */
       adsldset = , /* Name of the ADSL dataset */
       adslvars = studyid invid siteid usubjid age ageu sex race, /* List of variables to be fetched from ADSL dataset */
       dsetout =    /* Name of the Output dataset */
                        );

  /*
  / Write details of macro start to log
  /---------------------------------------------------------------------------*/

  %local MacroVersion;
  %let MacroVersion = 2 build 1;

  %include "&g_refdata/tr_putlocals.sas";

  %tu_putglobals()

  /*
  /  Set up local macro variables
  /---------------------------------------------------------------------------*/

  %local prefix    /* used for uniquely identifying datasets created by this program */
         varexst   /* List of variables which does not exist in dataset */
         dinexst   /* Returns the value by checking existence of studyid and usubjid in input dataset. */
         adslexst; /* Returns the value by checking existence of studyid and usubjid in ADSL dataset. */

  %let prefix = adgetadslvars_;

  /*
  / Parameter Validation
  / ---------------------------------------------------------------------------*/

  /* Validating DSETIN parameter */
  %if &dsetin. ne %str() %then
  %do;
    %if %sysfunc(exist(&dsetin.)) eq 0 %then
    %do;
      %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETIN refers to dataset %upcase("&dsetin.") which does not exist.;
      %let g_abort = 1;
      %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
    %end;
  %end;
  %else
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETIN is a desired parameter, provide a dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Validating ADSLDSET parameter */
  %if &adsldset. ne %str() %then
  %do;
    %if %sysfunc(exist(&adsldset.)) eq 0 %then
    %do;
      %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ADSLDSET refers to dataset %upcase("&adsldset.") which does not exist.;
      %let g_abort = 1;
      %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
    %end;
  %end;
  %else
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ADSLDSET is a desired parameter, provide a dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Validating ADSLVARS parameter */
  %if &adslvars. eq %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ADSLVARS is a desired parameter, provide an ADSL variable.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Calling tu_chknames to validate DSETOUT parameter */
  %if &dsetout. ne %str() %then
  %do;
    %if %tu_chknames(&dsetout., DATA) ne %then
    %do;
      %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETOUT refers to dataset %nrbquote(%upcase("&dsetout.")) which is not a valid dataset name.;
      %let g_abort = 1;
      %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
    %end;
  %end;
  %else
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETOUT is a desired parameter, provide a dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Aborting the execution, if any of the parameter validation fails. */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;

  /* Checking for the existence of STUDYID and USUBJID in input and ADSL datasets. */
  %let dinexst = %tu_chkvarsexist(&dsetin.,studyid usubjid);

  %if &dinexst ne %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Variable &dinexst does not exist in input dataset %upcase(&dsetin.).;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %let adslexst = %tu_chkvarsexist(&adsldset.,studyid usubjid);

  %if &adslexst ne %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Variable &adslexst does not exist in input dataset %upcase(&adsldset.).;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Aborting the execution, if any of the parameter validation fails. */

  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;

  /* Calling tu_chkvarsexist to validate ADSLVARS parameters name and existence */

  %if &adslvars. ne %str() %then
  %do;
    %tu_expvarlist(dsetin = &adsldset., varsin = &adslvars., scope = global, varout = expvars)

    %let varexst = %tu_chkvarsexist(&adsldset.,&expvars.);

    %if &varexst eq -1 %then
    %do;
      %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ADSLVARS %upcase("&expvars.") has invalid variable name.;
      %let g_abort = 1;
      %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
    %end;
    %else %if &varexst ne %str() %then
    %do;
      %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ADSLVARS refers to variable %upcase("&varexst.") which does not exist in dataset %upcase("&expvars.").;
      %let g_abort = 1;
      %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
    %end;

  %end;

  /* Aborting the execution, if error so far */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;

  /*
  / Check to ensure that required merge variables are being kept in adslvars
  / if not add them
  / ---------------------------------------------------------------------------*/

  %if %index(%upcase(&adslvars.),%upcase(STUDYID))=0 %then
  %do;
    %let adslvars=&adslvars. studyid;
  %end;

  %if %index(%upcase(&adslvars.),%upcase(USUBJID))=0 %then
  %do;
    %let adslvars=&adslvars. usubjid;
  %end;

  /* pull in specified vars from ADSL dataset - AJC001 added nodupkey */
  proc sort data = &adsldset. (keep = &adslvars.) out = &prefix.adsl nodupkey;
    by studyid usubjid;
  run;

  proc sort data = &dsetin out = &prefix.%scan(&dsetin.,2,'.');
    by studyid usubjid;
  run;

  /* Merging the input dataset with ADSL to populate ADSL variables in the output dataset */
  data &dsetout.;
    merge &prefix.%scan(&dsetin.,2,'.') (in = inc) &prefix.adsl;
    by studyid usubjid;
    if inc;
  run;

  /*
  / Tidy up and leave
  / AJC001: added delete of EXPVARS global macro variable
  / -----------------------------------------------------------------*/

  %tu_tidyup(rmdset=&prefix.:, glbmac=expvars)

%mend tu_adgetadslvars;
