/*******************************************************************************
|
| Macro Name:       tc_randall
|
| Macro Version:    1 build 1
|
| SAS Version:      9.4
|
| Created By:       Anthony J Cooper (ac12403)
|
| Date:             16-Aug-2017
|
| Macro Purpose:    To create the RANDALL SI dataset from  the RANDALL1
|                   dataset extracted from RandAll NG via the CDISC treatment
|                   macros.
|
| Macro Design:     Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                            REQ/OPT  DEFAULT
| -----------------  -------------------------------------  -------  ----------
| DSETIN             Specifies the name of the input        REQ      rmftdir.
|                    RANDALL1 SI dataset                             randall1
|                    Valid values: Valid dataset name
|
| DSETOUT            Specifies the name of the output       REQ      dmdata.
|                    RANDALL SI dataset                              randall
|                    Valid values: Valid dataset name
| -----------------  -------------------------------------  -------  ----------

| Output:   1. DMDATA.RANDALL
|
| Global macro variables created:  None
|
| Macros called :
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_chknames
| (@) tu_abort
| (@) tu_tidyup
|
| Example:  
|   %tc_randall;
|
|-------------------------------------------------------------------------------
| Change Log :
|
| Modified By :             
| Date of Modification :    
| New Version Number :      
| Modification ID :         
| Reason For Modification : 
|
*******************************************************************************/


%macro tc_randall(
  dsetin  = rfmtdir.randall1,   /* Input dataset name */
  dsetout = dmdata.randall      /* Output dataset name */
  );

  /*
  / Echo parameter values and global macro variables to the log.
  /----------------------------------------------------------------------------*/

  %local MacroVersion;
  %let MacroVersion = 1 build 1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_refdata g_abort g_dmdata);

  /*
  /  Set up local macro variables
  / ---------------------------------------------------------------------------*/

  %local
    prefix       /* used for uniquely identifying temporary datasets created by this program */
    ;

  %let prefix = _randall;

  /*
  / PARAMETER VALIDATION
  /----------------------------------------------------------------------------*/

  %let dsetin     = %qupcase(%nrbquote(&dsetin.));
  %let dsetout    = %qupcase(%nrbquote(&dsetout.));

  /*
  / Check that DSETIN is specified, has a valid SAS dataset name and exists.
  /----------------------------------------------------------------------------*/

  %if &dsetin. eq %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro parameter DSETIN is a required parameter, please provide a dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
  %else %if %tu_chknames(%scan(&dsetin., 1, %str(%() ), DATA ) ne %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro parameter DSETIN refers to dataset &dsetin., which is not a valid dataset name;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
  %else %if %sysfunc(exist(%scan(&dsetin., 1, %str(%() ))) eq 0 %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: The Input dataset DSETIN(=&dsetin.) does not exist.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /*
  / Check that DSETOUT is specified, has a valid SAS dataset name and is not
  / equal to DSETIN.
  /----------------------------------------------------------------------------*/

  %if &dsetout. eq %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro parameter DSETOUT is a required parameter, please provide a dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
  %else %if %tu_chknames(&dsetout., DATA ) ne %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro parameter DSETOUT refers to dataset &dsetout., which is not a valid dataset name;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
  %else %if &dsetin. ne %str() and &dsetout. eq %scan(&dsetin., 1, %str(%() ) %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: The Output dataset name specified in DSETOUT is the same as the Input dataset name specified in DSETIN.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;

  /*
  / NORMAL PROCESSING
  /----------------------------------------------------------------------------*/

  /*
  / Temporarily re-assign the DMDATA libname so the macro has write access
  / since ts_setup creates it as readonly.
  /----------------------------------------------------------------------------*/

  libname dmdata "&g_dmdata";

  /*
  / Take the input RANDALL1 dataset and derive the RANDALL SI dataset according
  / to the dataset specification.
  /----------------------------------------------------------------------------*/

  proc sql;
    create table &prefix._rand_map as
    select
      RANDNUM              length=6   label="Randomisation number"                     format=6.
     ,TRTD     as TRTDESC  length=200 label="Randomized treatment description"         format=$200.
     ,STRATUM              length=200 label="Randomization stratum"                    format=$200.
     ,TRTGRPD  as TRTGRP   length=120 label="Randomized treatment group"               format=$120.
     ,TRTC     as PTRTGRP  length=120 label="Period randomized treatment group"        format=$120.
     ,PERNUM               length=6   label="Period number"                            format=6.2
     ,SCHEDNUM             length=6   label="Schedule number"                          format=6.
     ,SCHEDTX              length=200 label="Schedule description"                     format=$200.
    from &dsetin
    order by randnum, pernum
    ;
  quit;

  data &dsetout. (label="Randomisation information");
    set &prefix._rand_map;
    by randnum pernum;
    informat _all_;
  run;

  /*
  / Set the DMDATA libname back to readonly.
  /----------------------------------------------------------------------------*/

  libname dmdata "&g_dmdata" access=readonly;

  /*
  / Delete temporary datasets used in this macro.
  /---------------------------------------------------------------------------*/

  %tu_tidyup(rmdset=&prefix.:, glbmac=none);

%mend tc_randall;
