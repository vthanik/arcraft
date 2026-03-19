/*******************************************************************************
|
| Macro Name:      tu_timslc
|
| Macro Version:   2 build 2
|
| SAS Version:     8.2
|
| Created By:      Mark Luff / Eric Simms
|
| Date:            14-May-2004
|
| Macro Purpose:   Add Time Slicing variables from the Time Slicing database
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME              DESCRIPTION                             REQ/OPT  DEFAULT
| ----------------  --------------------------------------  -------  ----------
| DSETIN            Specifies the dataset for which the      REQ     (Blank)
|                   time slicing variables are to be   
|                   added.
|                   Valid values: valid dataset name
|
| TMSLICEDSET       Specifies the dataset which contains     REQ      DMDATA.TMSLICE
|                   time slicing information.
|                   Valid values: valid dataset name
|
| DSETOUT           Specifies the name of the output         REQ      (Blank)
|                   dataset to be created.
|                   Valid values: valid dataset name
|
| KEEPPERSTADYYN    Specify if PERSTADY should be kept in    REQ       Y
|                   output data set if it is in TMSLICE data 
|                   set
|                   Valid values: Y or N
|
| ----------------  --------------------------------------  -------  ----------
|
| The macro references the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETIN            Req      Parameter specified dataset
|
| &TMSLICEDSET       Opt      Data extracted from the Time Slicing database
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
|    %tu_timslc(
|         dsetin  = _ae1,
|         dsetout = _ae2
|         );
|
|******************************************************************************
| Change Log
|
| Modified By: Eric Simms
| Date of Modification: 01Dec04
| New version/draft number: 1/2
| Modification ID: ems001
| Reason For Modification: Need to limit the number of variables taken from
|                          the DMDATA.TMSLICE dataset to merge with the input
|                          dataset. Also, clarified logic and did testing of
|                          existance of merge variables before attempting
|                          the merge. Also added TMSLICEDSET parameter instead
|                          of hard-coded DMDATA.TMSLICE.
|
| Modified By: Eric Simms
| Date of Modification: 08Dec04
| New version/draft number: 1/3
| Modification ID: ems002
| Reason For Modification: Change to the logic used to determine which variables
|                          to keep from the TMSLICEDSET to merge onto the    
|                          DSETIN dataset. Previously, if VISITNUM, VISIT,  
|                          PTMNUM, PTM, CYCLE were on the TMSLICEDSET they
|                          were kept (in addition to STAGENUM, STAGE, PERNUM, 
|                          PERIOD if they were on TMSLICEDSET). This has been 
|                          modified to keep VISITNUM if it is on both TMSLICEDSET
|                          and DSETIN, VISIT if it is on TMSLICEDSET and if 
|                          VISITNUM is on both TMSLICEDSET and DSETIN, PTMNUM if 
|                          it is on both TMSLICEDSET and DSETIN, PTM if it is on 
|                          TMSLICEDSET and if PTMNUM is on both TMSLICEDSET and 
|                          DSETIN, CYCLE if it is on both TMSLICEDSET and DSETIN,
|                          and STAGENUM, STAGE, PERNUM, PERIOD if they are on
|                          TMSLICEDSET.
|
| Modified By: Eric Simms
| Date of Modification: 08Dec04
| New version/draft number: 1/3
| Modification ID: ems003
| Reason For Modification: Change to the logic used to determine if VISIT and
|                          PTM should be dropped from DSETIN before the      
|                          merge with TMSLICEDSET. Previously, VISIT and PTM
|                          were dropped if they existed on DSETIN. Now, they are
|                          dropped only if they will be replaced by VISIT and PTM  
|                          from TMSLICEDSET.
|
| Modified By:              Yongwei Wang
| Date of Modification:     30Mar05
| New version/draft number: 1/4
| Modification ID:          YW001
| Reason For Modification:  1.Added a new parameter KEEPPERSTADYYN to decide if 
|                             PERSTADY variable should be kept in the output  
|                             dataset. It is for keeping this variable for 
|                             PKCNC and PKPAR
|
| Modified By: Eric Simms
| Date of Modification: 26Oct06
| New version/draft number: 2/1
| Modification ID: ems004
| Reason For Modification: This macro replaces the values of VISIT and PTM on DSETIN
|                          with the values of VISIT and PTM on the TMSLICEDSET. This
|                          causes a problem with unscheduled records which have been
|                          previously slotted in that the value assigned during the 
|                          slotting (e.g. "Unscheduled") is being replaced with the 
|                          value of VISIT/PTM found on TMSLICEDSET for the integer
|                          value of VISITNUM/PTMNUM (e.g. "VISIT 20"). The modification
|                          keeps non-integer VISITNUM/PTMNUM records from having the
|                          VISIT/PTM value replaced.
|
| Modified By:              Shan Lee
| Date of Modification:     28-Sep-07
| New version/draft number: 2/2
| Modification ID:          SL001
| Reason For Modification:  1. Enable dataset options to be specified with input
|                              and output dataset names - HRT0184.
|                           2. Add  TPTREFN, TPTREF, ELTMNUM, ELTMUNIT PTTYPNUM 
|                              and PTTYPE to output data set if they exists
|                              in &tmslicedset, but not &dsetin
|                           3. Change default value of KEEPPERSTADYYN to Y.
*******************************************************************************/
%macro tu_timslc (
     dsetin         = ,  /* Input dataset name */
     tmslicedset    = DMDATA.TMSLICE,  /* Time slicing dataset name */
     dsetout        = ,  /* Output dataset name */
     keepperstadyyn = Y  /* If PERSTADY should be kept in output data set */
     );

 /*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion;
 %let MacroVersion = 2 build 2;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals() 

 /*
 / PARAMETER VALIDATION
 /----------------------------------------------------------------------------*/

 %let dsetin = %nrbquote(&dsetin);
 %let tmslicedset = %nrbquote(&tmslicedset);
 %let dsetout = %nrbquote(&dsetout);
 %let keepperstadyyn = %qupcase(&keepperstadyyn);

 %if &dsetin eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter DSETIN is required.;
    %let g_abort=1;
 %end;  /* end-if  required parameter DSETIN was not specified.  */

 %if &tmslicedset eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter TMSLICEDSET is blank.;
    %let g_abort=1;
 %end;  /* end-if  parameter TMSLICEDSET was specified as blank.  */

 %if &dsetout eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter DSETOUT is required.;
    %let g_abort=1;
 %end;  /* end-if  required parameter DSETOUT was not specified.  */
 
 /* YW001: Added check of new parameter */
 %if ( &keepperstadyyn ne Y ) and ( &keepperstadyyn ne N ) %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The value of parameter KEEPPERSTADYYN (=&keepperstadyyn) is invalid. The valid value should be Y or N.;
    %let g_abort=1;
 %end;  /* end-if  parameter TMSLICEDSET was specified as blank.  */

 /*
 / Check that required dataset exists. 
 / Allow dataset options to be specified with dataset name - SL001.
 /----------------------------------------------------------------------------*/

 %if %sysfunc(exist(%qscan(&dsetin, 1, %str(%()))) eq 0 %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The dataset DSETIN(=&dsetin) does not exist.;
    %let g_abort=1;
 %end;  /* end-if  specified dataset DSETIN  does not exist.  */  

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;

 /*
 / If the input dataset name is the same as the output dataset name,
 / write a note to the log.
 / Ignore dataset options when comparing dataset names - SL001.
 /----------------------------------------------------------------------------*/

 %if %upcase(%qscan(&dsetin, 1, %str(%())) eq %upcase(%qscan(&dsetout, 1, %str(%())) %then
 %do;
    %put %str(RTN)OTE: &sysmacroname: The input dataset name (&dsetin) is the same as the output dataset name (&dsetout).;
 %end;  /* end-if  parameter values for DSETIN AND DSETOUT are the same.  */

 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/
   
 %local prefix;
 %let prefix = _timslc;   /* Root name for temporary work datasets */
 
 data &prefix._dsetinexist;
    if 0 then set %unquote(&dsetin);
 run;
 
 /*
 / If the SI dataset &TMSLICEDSET does not exist, write a warning
 / message and set the output dataset to the input dataset as is. Otherwise,
 / add the timeslicing information from the &TMSLICEDSET dataset.
 /----------------------------------------------------------------------------*/

 %if %sysfunc(exist(%qscan(&TMSLICEDSET, 1, %str(%()))) eq 0 %then 
 %do;
    %put %str(RTW)ARNING: &sysmacroname: TMSLICEDSET (&tmslicedset) dataset does not exist - timeslicing information not added.;

    data %unquote(&dsetout);
      set %unquote(&dsetin);
    run; /* end-if  dataset &TMSLICEDSET does not exist. */
 %end;
 %else
 %do;
    data &prefix._tmsliceexist;
       if 0 then set %unquote(&tmslicedset);
    run; 

    /*
    / Determine which merge variables are available on &TMSLICEDSET and the
    / &DSETIN datasets.
    /----------------------------------------------------------------------------*/

    %local dsetin_visitnum dsetin_ptmnum dsetin_cycle;
    %if %tu_chkvarsexist(&prefix._dsetinexist, visitnum) eq  %then %let dsetin_visitnum=visitnum;
    %if %tu_chkvarsexist(&prefix._dsetinexist, ptmnum) eq  %then %let dsetin_ptmnum=ptmnum;
    %if %tu_chkvarsexist(&prefix._dsetinexist, cycle) eq  %then %let dsetin_cycle=cycle;

    %local tmslice_visitnum tmslice_ptmnum tmslice_cycle;
    %if %tu_chkvarsexist(&prefix._tmsliceexist, visitnum) eq  %then %let tmslice_visitnum=visitnum;
    %if %tu_chkvarsexist(&prefix._tmsliceexist, ptmnum) eq  %then %let tmslice_ptmnum=ptmnum;
    %if %tu_chkvarsexist(&prefix._tmsliceexist, cycle) eq  %then %let tmslice_cycle=cycle;

    /*
    / Create a list of variables to merge on based on the merge variables
    / which are available in both datasets. If no common merge variables
    / exist, then put an error message and halt.
    /----------------------------------------------------------------------------*/

    %local _mrgvars;

    %if &dsetin_visitnum ne  and &tmslice_visitnum ne  %then %let _mrgvars = visitnum;
    %if &dsetin_ptmnum ne  and &tmslice_ptmnum ne  %then %let _mrgvars = &_mrgvars ptmnum;
    %if &dsetin_cycle ne  and &tmslice_cycle ne  %then %let _mrgvars = &_mrgvars cycle;
    %if %tu_chkvarsexist(&prefix._tmsliceexist, tptrefn ) eq and %tu_chkvarsexist(&prefix._dsetinexist, tptrefn ) eq  
    %then %let  _mrgvars =  &_mrgvars tptrefn ;
    

    %if &_mrgvars eq  %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: There are no common merge variables (VISITNUM, PTMNUM, CYCLE) on the;
       %put %str(RTE)RROR: &sysmacroname: TMSLICEDSET dataset (&TMSLICEDSET) and the DSETIN dataset (&DSETIN).;
       %let g_abort=1;
       %tu_abort;
    %end; /* end-if  No common merge variables found. */
    %else
    %do;
       %put %str(RTN)OTE: &sysmacroname: The common merge variables (out of VISITNUM, PTMNUM, CYCLE) found on the;
       %put %str(RTN)OTE: &sysmacroname: DSETIN dataset (&DSETIN) and the TMSLICEDSET dataset (&TMSLICEDSET) are:;
       %put %str(RTN)OTE: &sysmacroname: &_mrgvars.;
    %end; /* end-if  Common merge variables found. */
   
    /*
    / ems003
    / Determine if VISIT and PTM are on the input dataset. If they are, they will
    / be dropped before the merge if they will be replaced by VISIT and PTM from
    / the TMSLICEDSET dataset.
    /----------------------------------------------------------------------------*/

    %local dsetin_visit dsetin_ptm tmslice_visit tmslice_ptm;
    %if %tu_chkvarsexist(&prefix._dsetinexist, visit) eq  %then %let dsetin_visit=visit;
    %if %tu_chkvarsexist(&prefix._dsetinexist, ptm) eq  %then %let dsetin_ptm=ptm;
    %if %tu_chkvarsexist(&prefix._tmsliceexist, visit) eq  %then %let tmslice_visit=visit;
    %if %tu_chkvarsexist(&prefix._tmsliceexist, ptm) eq  %then %let tmslice_ptm=ptm;
       
    /*
    / Determine which variables to keep from the &TMSLICEDSET dataset based on   
    / what is available.             
    / ems002
    /----------------------------------------------------------------------------*/

    %local tmslice_keep dsetin_dropvars;
    %let tmslice_keep = studyid;
    %let dsetin_dropvars = ;

    %if &dsetin_visitnum ne  and &tmslice_visitnum ne  %then 
    %do;
        %let tmslice_keep = &tmslice_keep visitnum;
        %if &tmslice_visit ne  %then %let tmslice_keep = &tmslice_keep visit;
    %end;

    %if &dsetin_ptmnum ne  and &tmslice_ptmnum ne  %then 
    %do;
        %let tmslice_keep = &tmslice_keep ptmnum;
        %if &tmslice_ptm ne  %then %let tmslice_keep = &tmslice_keep ptm;
    %end;

    %if &dsetin_cycle ne  and &tmslice_cycle ne  %then %let tmslice_keep = &tmslice_keep cycle;

    %if %tu_chkvarsexist(&prefix._tmsliceexist, pernum  ) eq %then %let tmslice_keep = &tmslice_keep pernum;
    %if %tu_chkvarsexist(&prefix._tmsliceexist, period  ) eq %then %let tmslice_keep = &tmslice_keep period;
    %if %tu_chkvarsexist(&prefix._tmsliceexist, stagenum) eq %then %let tmslice_keep = &tmslice_keep stagenum;
    %if %tu_chkvarsexist(&prefix._tmsliceexist, stage   ) eq %then %let tmslice_keep = &tmslice_keep stage;
    
    %if %tu_chkvarsexist(&prefix._tmsliceexist, tptrefn ) eq %then %let tmslice_keep = &tmslice_keep tptrefn ;
    %if %tu_chkvarsexist(&prefix._tmsliceexist, tptref  ) eq %then %let tmslice_keep = &tmslice_keep tptref  ;
    %if %tu_chkvarsexist(&prefix._tmsliceexist, eltmnum ) eq %then %let tmslice_keep = &tmslice_keep eltmnum ;
    %if %tu_chkvarsexist(&prefix._tmsliceexist, eltmunit) eq %then %let tmslice_keep = &tmslice_keep eltmunit;
    %if %tu_chkvarsexist(&prefix._tmsliceexist, pttypnum) eq %then %let tmslice_keep = &tmslice_keep pttypnum;
    %if %tu_chkvarsexist(&prefix._tmsliceexist, pttype  ) eq %then %let tmslice_keep = &tmslice_keep pttype  ;
    
    %if %tu_chkvarsexist(&prefix._tmsliceexist, tptref  ) eq and %tu_chkvarsexist(&prefix._dsetinexist, tptref  ) eq  %then %let dsetin_dropvars = &dsetin_dropvars tptref  ;
    %if %tu_chkvarsexist(&prefix._tmsliceexist, eltmnum ) eq and %tu_chkvarsexist(&prefix._dsetinexist, eltmnum ) eq  %then %let dsetin_dropvars = &dsetin_dropvars eltmnum ;
    %if %tu_chkvarsexist(&prefix._tmsliceexist, eltmunit) eq and %tu_chkvarsexist(&prefix._dsetinexist, eltmunit) eq  %then %let dsetin_dropvars = &dsetin_dropvars eltmunit;
    %if %tu_chkvarsexist(&prefix._tmsliceexist, pttypnum) eq and %tu_chkvarsexist(&prefix._dsetinexist, pttypnum) eq  %then %let dsetin_dropvars = &dsetin_dropvars pttypnum;
    %if %tu_chkvarsexist(&prefix._tmsliceexist, pttype  ) eq and %tu_chkvarsexist(&prefix._dsetinexist, pttype  ) eq  %then %let dsetin_dropvars = &dsetin_dropvars pttype  ;    
            
    /* YW001: keep perstady */ 
    %if &keepperstadyyn eq Y %then 
    %do;
       %if %tu_chkvarsexist(&prefix._tmsliceexist, perstady) eq  %then %let tmslice_keep=&tmslice_keep perstady;
       %if %tu_chkvarsexist(&prefix._tmsliceexist, perstady) eq and %tu_chkvarsexist(&prefix._dsetinexist, perstady) eq  %then %let dsetin_dropvars = &dsetin_dropvars perstady;    
    %end;

    %put %str(RTN)OTE: &sysmacroname: The variables taken from the TMSLICEDSET dataset (&TMSLICEDSET) to merge;
    %put %str(RTN)OTE: &sysmacroname: with the DSETIN dataset (&DSETIN) are:;
    %put %str(RTN)OTE: &sysmacroname: &tmslice_keep.;
   
    /*
    / Handle unscheduled visitnums and ptmnums - keep the integer portion.
    /
    / ems003:
    / Drop VISIT and PTM (if they exist) from input dataset before merging if 
    / they will be replaced by VISIT and PTM from the TMSLICEDSET dataset.
    /
    / ems004:
    / For unscheduled records which have been slotted (i.e. non-integer VISITNUM
    / or PTMNUM) do not replace the values of VISIT/PTM. This is done by keeping
    / track of what VISIT/PTM was set to and re-setting it later.
    /----------------------------------------------------------------------------*/

    data &prefix._pre_merge;
         set %unquote(&dsetin);

         %if &dsetin_visitnum ne  %then
         %do;
            *** Temporarily assign visitnum to integer value ***;
            if visitnum ne . then
            do;
               _vnum = visitnum;
               visitnum = int(visitnum);
            end;  /* end-if variable VISITNUM is not missing. */ 
         %end;   /* end-if variable VISITNUM exists on the input dataset. */

         %if &dsetin_ptmnum ne  %then %do;
            *** Temporarily assign ptmnum to integer value ***;
            if ptmnum ne . then
            do;
               _tnum = ptmnum;
               ptmnum = int(ptmnum);
            end;  /* end-if  variable PTMNUM is not missing.  */
         %end;   /* end-if  variable PTMNUM exists on the input dataset. */

         /* ems003 */
         %if &dsetin_visitnum ne  and &tmslice_visitnum ne  and 
             &dsetin_visit ne  and &tmslice_visit ne  %then %str(rename visit=_v;); /* ems004 */
         %if &dsetin_ptmnum ne  and &tmslice_ptmnum ne  and 
             &dsetin_ptm ne  and &tmslice_ptm ne  %then %str(rename ptm=_t;);       /* ems004 */
             
    run;
   
    /*
    / Merge input data and timeslicing data. 
    / Apply the KEEP option to the output dataset, rather than the input dataset,
    / in the following PROC SORT, so that a KEEP dataset option may also be 
    / specified with the TMSLICEDSET parameter. SL001
    /----------------------------------------------------------------------------*/

    proc sort data= %unquote(&tmslicedset) out=&prefix._tmslice (keep=&tmslice_keep) nodupkey;
         by &_mrgvars;
    run;

    proc sort data=&prefix._pre_merge %if %nrbquote(&dsetin_dropvars) ne %then (drop=&dsetin_dropvars);;
         by &_mrgvars;
    run;
    
    data &prefix._post_merge;
         merge &prefix._pre_merge(in=a) &prefix._tmslice;
         by &_mrgvars;
         if a;
    run;
  
    /*
    / Retrieve original visitnums and ptmnums.
    / ems004:
    / For unscheduled records which have been slotted (i.e. non-integer VISITNUM
    / or PTMNUM) we need to reset the value of VISIT/PTM to what it was in DSETIN.
    /----------------------------------------------------------------------------*/

    data %unquote(&dsetout);
         set &prefix._post_merge;
         %if &dsetin_visitnum ne  and &tmslice_visitnum ne  and 
             &dsetin_visit ne  and &tmslice_visit ne  %then 
         %do;         
            if visitnum ne _vnum then visit=_v; /* ems004 */
            drop _v;                            /* ems004 */
         %end;             
         %if &dsetin_visitnum ne  %then 
         %do;
            visitnum = _vnum;
            drop _vnum;
         %end;
         %if &dsetin_ptmnum ne  and &tmslice_ptmnum ne  and 
             &dsetin_ptm ne  and &tmslice_ptm ne  %then 
         %do;
            if ptmnum ne _tnum then ptm=_t;    /* ems004 */
            drop _t;                           /* ems004 */
         %end;           
         %if &dsetin_ptmnum ne  %then
         %do;
            ptmnum = _tnum;
            drop _tnum;
         %end;                
    run;
 %end; /* end-if dataset &TMSLICEDSET exists */

 /*
 / Delete temporary datasets used in this macro.      
 /----------------------------------------------------------------------------*/
   
 %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tu_timslc;

