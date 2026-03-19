/*******************************************************************************
|
| Macro Name:      tu_recalcvisit
|
| Macro Version:   2 build 1
|
| SAS Version:     8.2
|
| Created By:      Mark Luff / Eric Simms
|
| Date:            09-Jun-2004
|
| Macro Purpose:   Recalculate visit based on a specified date.
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME              DESCRIPTION                             REQ/OPT  DEFAULT
| ----------------  --------------------------------------  -------  ----------
| DSETIN            Specifies the dataset for which the     REQ      (Blank)
|                   newly calculated VISITNUM, VISIT and
|                   CYCLE variables is to be added.
|                   Valid values: valid dataset name
|
| DSETOUT           Specifies the name of the output        REQ      (Blank)
|                   dataset to be created.
|                   Valid values: valid dataset name.
|
| REFDAT            Date variable on the input dataset      REQ      (Blank)
|                   &DSETIN containing the date desired
|                   for the recalculation of the visit
|                   information.
|
| REFTIM            Time variable on the input dataset      OPT      (Blank)
|                   &DSETIN containing the time desired
|                   (in conjunction with the date variable
|                   specified by REFDAT) for the
|                   recalculation of the visit
|                   information.
|
| VISITDSET         Specifies the dataset containing visit  OPT      (Blank)
|                   data.
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
|(@) tr_putlocals
|(@) tu_abort
|(@) tu_chkvarsexist
|(@) tu_putglobals
|(@) tu_tidyup
|
| Example:
|    %tu_recalcvisit(
|               dsetin  = _ae1,
|               dsetout = _ae2,
|               refdat  = aestdt,
|               reftim  = aesttm
|               );
|
|******************************************************************************
| Change Log
|
| Modified By:              Yongwei Wang
| Date of Modification:     22-Feb-2005
| New version/draft number: 1/2
| Modification ID:          YW001
| Reason For Modification:  Added a condition to check if date/time is missing
|                           before using input function to input date/time 
|
| Modified By:              Shan Lee 
| Date of Modification:     18-Sep-2007 
| New version/draft number: 2 build 1
| Modification ID:          SL001
| Reason For Modification:  Surface dataset names - HRT0171 HRT0184. 
|
*******************************************************************************/
%macro tu_recalcvisit (
           dsetin      = ,      /* Input dataset name */
           dsetout     = ,      /* Output dataset name */
           refdat      = ,      /* Reference date */
           reftim      = ,      /* Reference time */
           visitdset   = DMDATA.VISIT  /* Visit dataset name */
              );

 /*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion;
 %let MacroVersion = 2 build 1;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals()

 %local prefix;
 %let prefix = _recalc;   /* Root name for temporary work datasets */

 /*
 / PARAMETER VALIDATION
 /----------------------------------------------------------------------------*/

 %let dsetin  = %nrbquote(&dsetin);
 %let dsetout = %nrbquote(&dsetout);
 %let refdat  = %nrbquote(&refdat);
 %let reftim  = %nrbquote(&reftim);
 %let visitdset  = %nrbquote(&visitdset);


 %if &dsetin eq %then
 %do;
    %put %str(RTE)RROR: TU_RECALCVISIT: The parameter DSETIN is required.;
    %let g_abort=1;
 %end;  /* end-if Required parameter DSETIN is not specified.  */

 %if &dsetout eq %then
 %do;
    %put %str(RTE)RROR: TU_RECALCVISIT: The parameter DSETOUT is required.;
    %let g_abort=1;
 %end;  /* end-if Required parameter DSETOUT is not specified.  */

 %if &refdat eq %then
 %do;
    %put %str(RTE)RROR: TU_RECALCVISIT: The parameter REFDAT is required.;
    %let g_abort=1;
 %end;  /* end-if Required parameter REFDAT is not specified.  */

 /*
 / Check that required dataset exists. 
 /----------------------------------------------------------------------------*/

 %if %sysfunc(exist(%qscan(&dsetin, 1, %str(%()))) eq 0 %then
 %do;
    %put %str(RTE)RROR: TU_RECALCVISIT: The dataset DSETIN (&dsetin) does not exist.;
    %let g_abort=1;
 %end;

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;

 /*
 / Check that variable REFDAT exists on the input dataset.
 /----------------------------------------------------------------------------*/
 
 %local exist_refdat;
 
 data &prefix._dsetinexist;
    if 0 then set %unquote(&dsetin);
 run;
 
 %if %sysfunc(exist(%qscan(&visitdset, 1, %str(%()))) gt 0 %then 
 %do;
    data &prefix._visitexist;
       if 0 then set %unquote(&visitdset);
    run;
 %end;
 %else %let reftim=;

 %let exist_refdat=%tu_chkvarsexist(&prefix._dsetinexist, &refdat);

 %if &exist_refdat ne  %then
 %do;
    %put %str(RTE)RROR: TU_RECALCVISIT: The dataset DSETIN (&dsetin) does not contain the variable REFDAT (&refdat).;
    %let g_abort=1;
 %end;  /* end-if  Variable REFDAT does not exist in the user-specified dataset DSETIN.  */

 /*
 / If parameter REFTIM has been specified, check that it exists on the
 / input dataset.
 /----------------------------------------------------------------------------*/

 %if &reftim ne  %then
 %do;
    %if %tu_chkvarsexist(&prefix._dsetinexist, &reftim) ne  %then
    %do;
      %put %str(RTE)RROR: TU_RECALCVISIT: The dataset DSETIN (&dsetin) does not contain the variable REFTIM (&reftim).;
      %let g_abort=1;
    %end;  /* end-if  Variable REFTIM does not exist in the user-specified dataset DSETIN.  */
 %end;  /* end-if  Parameter REFTIM specified in the invocation of TU_RECALCVISIT.  */

 /*
 / If parameter REFTIM has been specified, check that variable VISITTM is
 / present on the SI VISIT dataset.
 /----------------------------------------------------------------------------*/

 %if &reftim ne  %then
 %do;
    %if %tu_chkvarsexist(&prefix._visitexist, visittm) ne  %then
    %do;
      %put %str(RTW)ARNING: TU_RECALCVISIT: The REFTIM parameter was specified (&reftim), but the &visitdset;
      %put %str(RTW)ARNING: TU_RECALCVISIT: dataset does not contain the VISITTM variable.;
    %end;  /* end-if  &visitdset dataset does not contain the VISITTM variable.  */
 %end;  /* end-if  Parameter REFTIM specified in the invocation of TU_RECALCVISIT.  */


 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;

 /*
 / If the input dataset name is the same as the output dataset name,
 / write a note to the log.
 / Enable dataset options to be specified for input and output datasets SL001.
 /----------------------------------------------------------------------------*/

 %if %upcase(%qscan(&dsetin, 1, %str(%())) eq %upcase(%qscan(&dsetout, 1, %str(%())) %then
 %do;
    %put %str(RTN)OTE: TU_RECALCVISIT: The input dataset name (&dsetin) is the same as the output dataset name (&dsetout).;
 %end;  /* end-if User-specified DSETIN and DSETOUT dataset names are the same.  */

 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/
   
 /*
 / If the SI dataset &visitdset does not exist, write an informational 
 / message and set the output dataset to the input dataset as is. Otherwise,
 / set the visit information (VISITNUM, VISIT, CYCLE(if available)) as per
 / the &visitdset dataset.
 /----------------------------------------------------------------------------*/

 %if %sysfunc(exist(%qscan(&visitdset, 1, %str(%()))) eq 0 %then 
 %do;
    %put %str(RTW)ARNING: TU_RECALCVISIT: VISITDSET(=&visitdset) dataset does not exist - visit information not recalculated.; 

    data %unquote(&dsetout);
      set %unquote(&dsetin);
    run;
 %end;  /* end-if Dataset &visitdset does not exist. */
 %else
 %do;
    /*
    / We will need to drop the variables VISITNUM, VISIT, CYCLE from the input
    / dataset (&DSETIN), if they exist on that dataset. Build a DROP statement
    / based on which variables exist on the input dataset, which will be used 
    / later on.
    /----------------------------------------------------------------------------*/
   
    %local drop_vars;
    %if %tu_chkvarsexist(&prefix._dsetinexist, visitnum) eq  %then %let drop_vars=visitnum;
    %if %tu_chkvarsexist(&prefix._dsetinexist, visit) eq  %then %let drop_vars=&drop_vars visit;
    %if %tu_chkvarsexist(&prefix._dsetinexist, cycle) eq  %then %let drop_vars=&drop_vars cycle;
    %if %str(&drop_vars) ne %str() %then %let drop_vars=( drop = &drop_vars );

    /*
    / Check for multiples of visitnum per visit date for each subject.
    / When only one visitnum exists for each visit date, slotting will be based
    / exclusively on date.
    /----------------------------------------------------------------------------*/

    %local multi_visit;
    proc sql noprint;
         select count(distinct visitnum)
         from %unquote(&visitdset) 
         group by studyid, subjid, visitdt
         having count(distinct visitnum) gt 1;

         %let multi_visit= %eval(&sqlobs gt 0);

    quit;

    /*
    / Determine if slotting should be according to date only or date and time.
    /----------------------------------------------------------------------------*/

    %if &reftim eq %str( ) or %tu_chkvarsexist(&prefix._visitexist, visittm) ne  or &multi_visit eq 0 %then
    %do;  /* slotting on date only */
       %put %str(RTN)OTE: TU_RECALCVISIT: Dataset DSETIN (&dsetin) will be slotted according to REFDAT (&refdat).;

        /*
        / Take the lowest visitnum value per visit date. 
        /----------------------------------------------------------------------------*/
        proc sql noprint;
             create table &prefix._visit0 as
             select distinct *
             from %unquote(&visitdset) 
             where not missing(visitdt)
             group by studyid, subjid, visitdt
             having (visitnum) eq min(visitnum);
        quit;

        /*
        / Order visit data by reverse visit date.
        /----------------------------------------------------------------------------*/
        proc sort data=&prefix._visit0 out=&prefix._visit1;
             by studyid subjid descending visitdt;
        run;
       
        /*
        / Obtain visit date from last record.
        /----------------------------------------------------------------------------*/
       
        data &prefix._visit2;
             set &prefix._visit1;
             by studyid subjid;
             _endt = lag(visitdt);
        run;
   
        /*
        / For last visit of each subject, date set to 10000 days after start of visit.
        /----------------------------------------------------------------------------*/
       
        data &prefix._visit3;
             set &prefix._visit2;
             by studyid subjid;
             if first.subjid then _endt = visitdt + 10000;
        run;
  
        /*
        / CYCLE is an optional variable on the VISIT dataset; keep it if it exists.
        / Find visit associated with reference date.
        / Create temporary version of DSETIN, to enable user-specified dataset options
        / to be applied before &drop_vars. SL001
        /----------------------------------------------------------------------------*/
   
        %local bcycle; 
        %if %tu_chkvarsexist(&prefix._visit3, cycle) eq  %then %let bcycle=%str(, b.cycle);
        %else %let bcycle=;

        proc sql noprint;
             create table &prefix._dsetintemp as
             select *
             from %unquote(&dsetin)
             ;
             create table %unquote(&dsetout) as
             select a.*, b.visitnum, b.visit &bcycle
             from &prefix._dsetintemp &drop_vars as a
                  left join &prefix._visit3 as b
             on  a.studyid eq b.studyid
             and a.subjid  eq b.subjid
             and a.&refdat ge b.visitdt
             and a.&refdat lt b._endt
             ;
        quit;
    %end;  /* end-if slotting on date only */
    %else
    %do;  /* slotting with date and time */
        %put %str(RTN)OTE: TU_RECALCVISIT: Dataset DSETIN (&dsetin) will be slotted according to both;
        %put %str(RTN)OTE: TU_RECALCVISIT: REFDAT (&refdat) and REFTIM (&reftim).;

        /*
        / Derive temporary variable to hold the visit datetime.
        / Do not hard-code the name of the VISIT dataset. SL001
        /----------------------------------------------------------------------------*/
   
        data &prefix._visit0;
             set %unquote(&visitdset);
             if not missing(visitdt);

             /*
             / If visit time is not missing, derive a datetime value.
             / If the time is missing, set the time to be 00:00 when deriving datetime.
             /--------------------------------------------------------------------------*/
  
             if (not missing(visittm)) then
                _visitdm= input(put(visitdt,date9.) || ":" || put(visittm,time5.), datetime15.);
             else
                _visitdm= input(put(visitdt,date9.) || ":00:00", datetime15.);
        run;

        /*
        / Order visit data by reverse visit datetime.
        /----------------------------------------------------------------------------*/
        proc sort data=&prefix._visit0 out=&prefix._visit1;
             by studyid subjid descending _visitdm;
        run;
       
        /*
        / Obtain visit date from last record.
        /----------------------------------------------------------------------------*/
       
        data &prefix._visit2;
             set &prefix._visit1;
             by studyid subjid;
             _endm = lag(_visitdm);
        run;
   
        /*
        / For last visit of each subject, date set to 10000 days after start of visit.
        / YW001: Added if (not missing(visittm)).
        /----------------------------------------------------------------------------*/
       
        data &prefix._visit3;
             set &prefix._visit2;
             by studyid subjid;
             if first.subjid then do;
                if (not missing(visittm)) then
                   _endm = input(put(visitdt+10000,date9.)|| ":" || put(visittm,time5.), datetime15.);
                else
                   _endm = input(put(visitdt+10000,date9.)|| ":00:00", datetime15.);
             end;
        run;
   
        /*
        / Create a datetime variable on the input dataset for slotting purposes.
        /----------------------------------------------------------------------------*/
       
        data &prefix._dsetin;
             set %unquote(&dsetin);
             if &refdat ne . and &reftim ne . then _refdm=
                input(put(&refdat,date9.)||":"||put(&reftim,time5.),datetime15.);
             else if &refdat ne . and &reftim eq . then _refdm=
                input(put(&refdat,date9.) || ":00:00", datetime15.);
             else _refdm=.;
        run;
  
        /*
        / CYCLE is an optional variable on the VISIT dataset; keep it if it exists.
        / Find visit associated with reference datetime.
        / Create temporary version of DSETOUT, so that (drop=_refdm) can be applied
        / before any user-specified dataset options associated with DSETOUT. SL001
        /----------------------------------------------------------------------------*/
   
        %local bcycle; 
        %if %tu_chkvarsexist(&prefix._visit3, cycle) eq  %then %let bcycle=%str(, b.cycle);
        %else %let bcycle=;

        proc sql noprint;
             create table &prefix._dsetouttemp(drop=_refdm) as
             select a.*, b.visitnum, b.visit &bcycle
             from &prefix._dsetin &drop_vars as a
                  left join &prefix._visit3 as b
             on  a.studyid eq b.studyid
             and a.subjid  eq b.subjid
             and a._refdm ge b._visitdm
             and a._refdm lt b._endm
             ;
             create table %unquote(&dsetout) as
             select *
             from &prefix._dsetouttemp
             ;
        quit;
    %end;  /* end-if slotting with date and time */

 %end; /* end-if  Dataset &visitdset exists. */
   
 /*
 / Delete temporary datasets used in this macro.      
 /----------------------------------------------------------------------------*/
   
 %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tu_recalcvisit;
