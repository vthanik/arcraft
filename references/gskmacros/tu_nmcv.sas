/******************************************************************************* 
|
| Macro Name:      tu_nmcv.sas
|
| Macro Version:   1.0
|
| SAS Version:     8.2
|
| Created By:      Andrew Ratcliffe, RTSL, www.ratcliffe.co.uk
|
| Date:            19-Jun-2005
|
| Macro Purpose:   Adds covariates (CVs) to input dataset.
|                  The utility macro %TU_CV shall be used to left join the 
|                  covariate data to the output dataset.
|                  No covariate values shall be missing. The %tu_nmimpcv 
|                  macro shall be used to impute values for covariate 
|                  variables with missing values.

|
| Macro Design:    PROCEDURE STYLE MACRO
| 
| Input Parameters:
|
| NAME              DESCRIPTION                         DEFAULT 
| CV                Specifies covariates to be added    [blank] (Opt)
|
| DSETIN            Specifies the name of the input     [blank] (Req)
|                   dataset
|
| DSETOUT           Specifies the name of the output    [blank] (Req)
|                   dataset
|
| JOINMSG           Specifies the type of XCP messages  error   (Req)
|                   to be produced in case of 
|                   mismatches in joins
| SORTBY            Specifies the variables by which    [blank] (Opt)
|                   the input data shall be sorted 
|                   before searching for earlier/later values 
|
|
| Output: This macro produces a copy of the input dataset, with additional CV columns
|
| Global macro variables created:  None
|
| Macros called:
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_chknames
| (@) tu_cv
| (@) tu_nmimpcv
| (@) tu_tidyup
| (@) tu_abort
|
| Example:
|
| %tu_nmcv(dsetin = work.interleave
|         ,dsetout = work.cv
|         ,cv = WORK.demo [age ageu] [subjid]
|         );
|
|******************************************************************************* 
| Change Log 
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     05-Jul-2005
| New version number:       1/2
| Modification ID:          
| Reason For Modification:  Finish-off the list of sub-macros.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     11-Aug-2005
| New version number:       1/3
| Modification ID:          AR3
| Reason For Modification:  Fix: Skip all normal processing if no CV parm. Just
|                           copy dsetin to dsetout.
|                           Fix: Add sortby parm, so we can pass it to nmimpcv.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     28-Sep-2005
| New version number:       1/4
| Modification ID:          AR4
| Reason For Modification:  Fix: Add g_subjid to call to putglobals.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     26-Oct-2005
| New version number:       1/5
| Modification ID:          AR5
| Reason For Modification:  Fix: Add necessary do/end statements around 
|                           debugging code.
|
| Modified By:              
| Date of Modification:     
| New version number:       
| Modification ID:          
| Reason For Modification:  
|
********************************************************************************/ 

%macro tu_nmcv(cv      =        /* Covariate columns to be added: <Libname.Dataset> <[Var]> <[By Var]> <[Where Clause]> */
              ,dsetin  =        /* type:ID Name of input dataset */
              ,dsetout =        /* Output dataset */
              ,joinmsg = error  /* Type of XCP messages in case of mismatches in joins */
              ,sortby  =        /* Variables by which the input data shall be sorted before searching for earlier/later values */
              );

  /* Echo parameter values and global macro variables to the log */
 
  %local MacroVersion;
  %let MacroVersion = 1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_subjid);  /*AR4*/

  %local prefix;
  %let prefix = %substr(&sysmacroname,3); 

  /* PARAMETER VALIDATION */

  /* Validate - DSETIN */
  %if %length(&dsetin) eq 0 %then 
  %do;
    %put RTE%str(RROR): &sysmacroname.: A value must be supplied for DSETIN;
    %let g_abort=1;
  %end;
  %else
  %do;
    %if not %sysfunc(exist(&dsetin)) %then 
    %do;
      %put RTE%str(RROR): &sysmacroname.: The DSETIN dataset (&dsetin) does not exist;
      %let g_abort=1;
    %end;
  %end;

  /* Validate - DSETOUT */
  %if %length(%tu_chknames(&dsetout,DATA)) gt 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: The value supplied for DSETOUT (&dsetout) is not a valid dataset name;
    %let g_abort=1;
  %end;

  /* Validate - CV - done by %tu_cv */

  /* Validate - JOINMSG - done by %tu_cv */

  /* Validate - SORTBY - done by %tu_nmimpcv */

  %tu_abort;

  /* NORMAL PROCESSING */

  %if %length(&cv) eq 0 %then  /*AR3*/
  %do;  /* No CV parm */
    /* Just copy in to out */
    data &dsetout;
      set &dsetin;
    run;
  %end; /* No CV parm */

  %else
  %do;  /* We do have a CV parm */

    %local currentDataset;

    /*
    / PLAN OF ACTION:
    / 1. Make a note of vars currently in dset, so we can deduce which have been subsequently added as CVs
    / 2. Perform CV merge using TU_CV
    / 3. Deduce which vars have been added
    / 4. Impute missing CVs
    / 5. Create result dataset
    /------------------------------------------------------*/

    /* 1. Make a note of vars currently in dset, so we can deduce which have been subsequently added as CVs */
    proc contents data=&dsetin out=work.&prefix._contBefore noprint;
    run;

    /* 2. Perform CV merge using TU_CV */
    %tu_cv(dsetin  = &dsetin
          ,dsetout = work.&prefix._10
          ,cv      = &cv
          ,joinmsg = &joinmsg
          );
    %let currentDataset = work.&prefix._10;

    /* 3. Deduce which vars have been added */
    proc contents data=&currentDataset out=work.&prefix._contAfter noprint;
    run;

    proc sort data=work.&prefix._contBefore out=work.&prefix._contBeforeS;
      by name;
    run;

    proc sort data=work.&prefix._contAfter out=work.&prefix._contAfterS;
      by name;
    run;

    %let cvVar0 = 0;
    data _null_;
      merge work.&prefix._contBeforeS (in=fromBef)
            work.&prefix._contAfterS (in=fromAft)
            end=finish
            ;
      by name;
      retain cvVar0 0;
      select;
        when (not fromAft) 
        do;
          put 'RTE' "RROR: &sysmacroname: Variable unexpectedly dropped by tu_cv macro: " name;
          call symput('G_ABORT','1');
        end;
        when (not fromBef) 
        do;
          cvVar0 = cvVar0 + 1;
          call symput('CVVAR'!!compress(putn(cvVar0,'BEST.'))
                     ,name
                     );
        end;
        otherwise; /* from both */
      end;
      if finish then
        call symput('CVVAR0'
                   ,putn(cvVar0,'BEST.')
                   );
    run;
    %tu_abort;
    %if &g_debug ge 1 %then
    %do;  /*AR5*/
      %do idx = 0 %to &cvVar0;
        %put RTD%str(EBUG): &sysmacroname: CVVAR&idx=&&cvVar&idx;
      %end;  
    %end;  /*AR5*/
   
    /* 4. Impute missing CVs */
    %do idx = 1 %to &cvVar0;

      %tu_nmimpcv(dsetin   = &currentDataset
                 ,dsetout  = work.&prefix._imp&idx
                 ,cvvar    = &&cvVar&idx
                 ,bndryvar = &g_subjid
                 ,sortby   = &sortby  /*AR3*/
                 );
      %let currentdataset = work.&prefix._imp&idx;

    %end;

    /* 5. Create result dataset */
    data &dsetout;
      set &currentDataset;
    run;

  %end; /* We do have a CV parm */

  /* Finish-off */
  %tu_tidyup(rmdset=&prefix:
            ,glbmac=NONE
            );
  quit;

  %tu_abort;

%mend tu_nmcv;
