/*******************************************************************************
|
| Macro Name:      tu_visitdt
|
| Macro Version:   2 build 1
|
| SAS Version:     8.2
|
| Created By:      Eric Simms
|
| Date:            11-Jun-2004
|
| Macro Purpose:   Add VISIT DATE to a dataset.
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME              DESCRIPTION                             REQ/OPT  DEFAULT
| ----------------  --------------------------------------  -------  ----------
| DSETIN            Specifies the dataset for which the     REQ      (Blank)
|                   newly calculated VARNAME variable 
|                   (containing the visit date) is to be 
|                   added. 
|                   Valid value: valid dataset name
|
| DSETOUT           Specifies the name of the output        REQ      (Blank)
|                   dataset to be created.
|                   Valid value: valid dataset name
|
| VISITDSET         Specifies the dataset containing visit  OPT      DMDATA.VISIT
|                   data.
|
| VARNAME           Visit date variable added to the input  REQ      (Blank)
|                   dataset &DSETIN to create &DSETOUT.
| ----------------  --------------------------------------  -------  ----------
|
| The macro references the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETIN            Req      Parameter specified dataset
|
| &VISITDSET         Opt      SI dataset containing visit data   
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
|(@) tu_abort
|(@) tu_chkvarsexist
|(@) tr_putlocals
|(@) tu_putglobals
|(@) tu_tidyup
|
| Example:
|    %tu_visitdt(
|               dsetin  = _blind1,
|               dsetout = _blind2,
|               varname = visit_date
|               );
|
|******************************************************************************
| Change Log
|
| Modified By: Eric Simms
| Date of Modification: 10Nov04
| New version/draft number: 1/2
| Modification ID: ems001
| Reason For Modification: changed from 
|                            %put "RTW" "ARNING: ... ";
|                          to
|                            %put %str(RTW)ARNING: ... ;
|                          as in all other code when a %put is used to
|                          output an RTWARNING message.
|
| Modified By:              Shan Lee 
| Date of Modification:     19-Sep-2007 
| New version/draft number: 2 build 1
| Modification ID:          SL001
| Reason For Modification:  Surface VISIT dataset as a parameter, and enable
|                           dataset options to be specified for input and
|                           output datasets - HRT0184. 
*******************************************************************************/
%macro tu_visitdt (
           dsetin      = ,      /* Input dataset   */
           dsetout     = ,      /* Output dataset  */
           varname     = ,      /* Variable to contain the visit date */
           visitdset   =DMDATA.VISIT  /* SI dataset containing visit data */
              );

 /*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion;
 %let MacroVersion = 2 build 1;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals() 

 %local prefix;
 %let prefix = _visitdt;   /* Root name for temporary work datasets */

 /*
 / PARAMETER VALIDATION
 /----------------------------------------------------------------------------*/

 %let dsetin  = %nrbquote(&dsetin);
 %let dsetout = %nrbquote(&dsetout);

 %if &dsetin eq %then
 %do;
    %put %str(RTE)RROR: TU_VISITDT: The parameter DSETIN is required.;
    %let g_abort=1;
 %end;  /* end-if Required parameter DSETIN is not specified.  */

 %if &dsetout eq %then
 %do;
    %put %str(RTE)RROR: TU_VISITDT: The parameter DSETOUT is required.;
    %let g_abort=1;
 %end;  /* end-if Required parameter VISITDT is not specified.  */

 %if &varname eq %then
 %do;
    %put %str(RTE)RROR: TU_VISITDT: The parameter VARNAME is required.;
    %let g_abort=1;
 %end;  /* end-if Required parameter VARNAME is not specified.  */

 /*
 / Check that required dataset exists. 
 /----------------------------------------------------------------------------*/

 %if %sysfunc(exist(%qscan(&dsetin, 1, %str(%()))) eq 0 %then
 %do;
    %put %str(RTE)RROR: TU_VISITDT: The dataset DSETIN(=&dsetin) does not exist.;
    %let g_abort=1;
 %end;  /* end-if  Specified DSETIN parameter does not exist. */
 
 %if &g_abort eq 1 %then
 %do;
    %tu_abort;   
 %end;

 /*
 / Check that variable VISITNUM exists on the input dataset.
 /----------------------------------------------------------------------------*/
 
 %local exist_visitnum;

 data &prefix._dsetinexist;
    if 0 then set %unquote(&dsetin);
 run;
 
 %let exist_visitnum=%tu_chkvarsexist(&prefix._dsetinexist, visitnum);

 %if &exist_visitnum ne  %then
 %do;
    %put %str(RTE)RROR: TU_VISITDT: The input dataset DSETIN(=&dsetin) does not contain the variable VISITNUM.;
    %let g_abort=1;
 %end;  /* end-if Variable VISITNUM does not exist in user-specified DSETIN parameter. */

 /*
 / Check that variable VARNAME does not exist on the input dataset.
 /----------------------------------------------------------------------------*/
 
 %local exist_varname;

 %let exist_varname=%tu_chkvarsexist(&prefix._dsetinexist, &varname);

 %if &exist_varname eq  %then
 %do;
    %put %str(RTE)RROR: TU_VISITDT: The input dataset DSETIN(=&dsetin) already contains the variable &varname.;
    %let g_abort=1;
 %end;

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;   
 %end;

 /*
 / If the input dataset name is the same as the output dataset name,
 / write a note to the log.
 / Enable input and output dataset names to include dataset options - SL001
 /----------------------------------------------------------------------------*/

 %if %upcase(%qscan(&dsetin, 1, %str(%())) eq %upcase(%qscan(&dsetout, 1, %str(%())) %then
 %do;
    %put %str(RTN)OTE: TU_VISITDT: The input dataset name (&dsetin) is the same as the output dataset name (&dsetout).;
 %end;  /* end-if User-specified DSETIN and DSETOUT parameters are the same.  */

 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/

 /*
 / If the SI dataset &VISITDSET does not exist, write a warning
 / message and set the output dataset to the input dataset as is. Otherwise,
 / add the visit date to the input dataset to create the output dataset.
 /----------------------------------------------------------------------------*/

 %if %nrbquote(&visitdset) eq or %sysfunc(exist(%qscan(&visitdset, 1, %str(%()))) eq 0 %then 
 %do;
    %put %str(RTW)ARNING: TU_VISITDT: VISITDSET(=&visitdset) dataset is not given or does not exist - visit date not added. ; /* ems001 */

    data %unquote(&dsetout);
      set %unquote(&dsetin);
    run;
 %end;  /* end-if Dataset &visitdset does not exist. */
 %else
 %do;
    /*
    / If cycle is available on both the &VISITDSET and &DSETIN datasets,
    / make use of it in the merge.
    /----------------------------------------------------------------------------*/
    data &prefix._visitexist;
       if 0 then set %unquote(&visitdset);
    run;
   
    %local exist_visit_cycle exist_dsetin_cycle use_cycle;
    %let exist_visit_cycle=%tu_chkvarsexist(&prefix._visitexist, cycle);
    %let exist_dsetin_cycle=%tu_chkvarsexist(&prefix._dsetinexist, cycle);
    %if &exist_visit_cycle=  and &exist_dsetin_cycle=  %then %let use_cycle=YES;

    /*
    / Get earliest non-missing VISITDT per CYCLE/VISIT.
    / Apply the keep option to the output dataset, rather than the input dataset,
    / in order to allow dataset options to be specified with the input dataset.
    /  - SL001
    /----------------------------------------------------------------------------*/
  
    %if &use_cycle=YES %then
    %do; 
       proc sort data = %unquote(&visitdset)
                 out=&prefix._visit1
                 (keep=studyid subjid cycle visitnum visitdt)
                 ;
            by studyid subjid cycle visitnum visitdt;
            where visitdt ne .;
       run;

       data &prefix._visit2;
         set &prefix._visit1(rename=(visitdt=&varname));
         by studyid subjid cycle visitnum;
         if first.visitnum;
       run;

       proc sort data=%unquote(&dsetin) out=&prefix._dsetin;
         by studyid subjid cycle visitnum;
       run;

       data %unquote(&dsetout);
        merge &prefix._dsetin(in=A) &prefix._visit2;
        by studyid subjid cycle visitnum;
        if A;
       run;
    %end;  /* end-if Variable CYCLE exists in both datasets: &VISITDSET and &DSETIN.  */ 
    %else
    %do; 
       proc sort data = %unquote(&visitdset)
                 out=&prefix._visit1
                 (keep=studyid subjid visitnum visitdt) 
                 ;
            by studyid subjid visitnum visitdt;
            where visitdt ne .; 
       run;

       data &prefix._visit2;
         set &prefix._visit1(rename=(visitdt=&varname));
         by studyid subjid visitnum;
         if first.visitnum;
       run;

       proc sort data=%unquote(&dsetin) out=&prefix._dsetin;
         by studyid subjid visitnum;
       run;

       data %unquote(&dsetout);
        merge &prefix._dsetin(in=A) &prefix._visit2;
        by studyid subjid visitnum;
        if A;
       run;
    %end;  /* end-if Variable CYCLE does not exist in both &VISITDSET and &DSETIN datasets.  */
 %end; /* end-if  Dataset &VISITDSET exists. */
   
 /*
 / Delete temporary datasets used in this macro.      
 /----------------------------------------------------------------------------*/
   
 %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tu_visitdt;

