/*******************************************************************************
|
| Macro Name:      tu_p1_acttrt_xo
|
| SAS Version:     9.1
|
| Created By:      Khilit Shah
|
| Date:            13 March 2008
|
| Macro Purpose:   Add actual treatment variables to A&R datasets.
|                     - XO study.
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME            DESCRIPTION                          REQ/OPT  DEFAULT
| --------------  -----------------------------------  -------  ---------------
| DSETIN          Specifies the name of the input      REQ      [blank]
|                 dataset to apply actual treatment
|                 to
|
| DSETOUT         Specifies the name of the output     REQ      [blank]
|                 dataset that has the actual
|                 treatment applied to
|
| TRT_DEV_EXIST   Does treatment deviation exist       REQ      N
|
| EXPOSUREDSET    Specifies the variable name given    REQ      DMDATA.EXPOSURE
|                 to the study EXPOSURE dataset             
|
| TMSLICEDSET     Specifies the variable name given    REQ      DMDATA.TMSLICE
|                 to the study TMSLICE dataset             
|
|
| The macro references the following datasets :-
| ------------------  -------  ------------------------------------------------
| Name                Req/Opt  Description
| ------------------  -------  ------------------------------------------------
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
| Macros called:
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_chkvarsexist
| (@) tu_abort
| (@) tu_tidyup
| (@) tu_valparms
|
| Example:
|
|******************************************************************************
| Change Log
|
| Modified By:               Khilit Shah
| Date of Modification:      29-04-2008
| New version/draft number:  2
| Modification ID:           NA
| Reason For Modification:   Removed DROP statement for DSETOUT as this was
|                            dropping required variables
|                            Included PERNUM in the sortorder step when 
/                            referencing the EXPOSURE dataset with in the
/                            PROC SQL step.
|
|*******************************************************************************
| Modified By:              Khilit Shah
| Date of Modification:     31-Oct-08
| New version/draft number: 3
| Modification ID:          KS-003
| Reason For Modification:  1  Passed on the g_debug option value to this macro inline
|                              with parameters set by TS_SETUP. 
|                           2  Passed the values for DMDATA.EXPOSURE and DMDATA.TMSLICE 
|                              as macro parameters instead of having this hardcoded.
|                           3  Allow conditional processing of EXSTTM and PTMNUM
|                              variables in the EXPOSURE dataset if it exists. 
|
|
|*******************************************************************************
| Modified By:              Suzanne Johnes           
| Date of Modification:     10-Dec-08   
| New version/draft number: 4 
| Modification ID:          NA     
| Reason For Modification:  Added validation for EXPOSUREDSET and TMSLICEDSET
|                           parameters which cannot be passed missing values
|
|*******************************************************************************
| Modified By:              Khilit Shah (KS)
| Date of Modification:     30-Apr-09
| New version/draft number: 5
| Modification ID:          001  
| Reason For Modification:  Include TPTREFN as the optional BY variable
|                           between the merge with TMSLICE and EXPOSURE datasets
|
*******************************************************************************/

%macro tu_p1_acttrt_xo(dsetin         =                 /* Name of input dataset */
                      ,dsetout        =                 /* Name of output dataset */
                      ,trt_dev_exists = N               /*Do treatment deviations exist in your study? */ 
                      ,exposuredset   = DMDATA.EXPOSURE /* Name of EXPOSURE dataset to use */
                      ,tmslicedset    = DMDATA.TMSLICE  /* Name of TMSLICE dataset to use */
                      );

  /*
  / Echo parameter values and global macro variables to the log
  /----------------------------------------------------------------------------*/
  %local MacroVersion macroname;
  %let MacroName=&sysmacroname.;
  %let MacroVersion=5;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals();

  /*
  / Parameter validation
  /----------------------------------------------------------------------------*/
  %let dsetin=%nrbquote(&dsetin.);
  %let dsetout=%nrbquote(&dsetout.);
  %let trt_dev_exists=%nrbquote(&trt_dev_exists.);


  /*
  / Check for valid parameter values
  /   set up a macro variable to hold the pv_abort flag
  /----------------------------------------------------------------------------*/
  %local pv_abort;
  %let pv_abort = 0 ;


  /*-- TRT deviation exist (Y,N) */
  %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = trt_dev_exists, valuelist = Y N, abortyn = N);

  %if &trt_dev_exists=Y %then %do;
    %if %sysfunc(fileexist(&g_rfmtdir/trt_deviation_file.sas)) ne 1 %then %do;
      %put %str(RTE)RROR: &sysmacroname.: The file &g_rfmtdir/trt_deviation_file.sas does not exist;
      %let pv_abort=1;
    %end;
  %end;

  /*-- Validation of dataset */
  /* Check existence of datasets and variables */

  * Output Dataset name is not missing ;
  %if %length(&dsetout) = 0 %then
    %do;
      %put %str(RTE)RROR: &macroname: Macro parameter (dsetout) cannot be blank;
      %let pv_abort = 1;
    %end;

  * Input dataset name is not missing and input dataset exists ;
  %if %length(&dsetin) = 0 %then
    %do;
      %put %str(RTE)RROR: &macroname: Macro parameter (dsetin) cannot be blank;
      %let pv_abort = 1;
    %end;
  %else
    %tu_valparms(
      macroname=tu_p1_acttrt_xo,
      chktype=dsetExists,
      pv_dsetin=dsetin
     );

  * Check for required variables in the input dataset ;
  %let acttrt_varlist=subjid pernum patrtcd patrtgrp;
  %tu_valparms(
    macroname=tu_p1_acttrt_xo,
    chktype=varexists,
    pv_dsetin=dsetin,
    pv_varsin=acttrt_varlist
   );

  * Check if DMDATA.TMSLICE exists in the study ;
  %if %length(&tmslicedset) = 0 %then
    %do;
      %put %str(RTE)RROR: &macroname: Macro parameter (tmslicedset) cannot be blank;
      %let pv_abort = 1;
    %end;
  %else
  %tu_valparms(
    macroname=tu_p1_acttrt_xo,
    chktype=dsetExists,
    pv_dsetin=tmslicedset
   );

  * Check if DMDATA.EXPOSURE exists in the study ;
  %if %length(&exposuredset) = 0 %then
    %do;
      %put %str(RTE)RROR: &macroname: Macro parameter (exposuredset) cannot be blank;
      %let pv_abort = 1;
    %end;
  %else
  %tu_valparms(
    macroname=tu_p1_acttrt_xo,
    chktype=dsetExists,
    pv_dsetin=exposuredset
   );

   /*- complete parameter validation */
  %if %eval(&g_abort. + &pv_abort.) gt 0 %then %do;
    %put %str(RTE)RROR: &macroname: Macro has failed parameter validation check for reasons stated with %str(RTE)RRORs above;
    %tu_abort(option=force);
  %end;


  /*
  / NORMAL PROCESSING
  /----------------------------------------------------------------------------*/
  %local prefix ;
  %let prefix = _tu_p1_acttrt_xo;   * Root name for temporary work datasets;

  /*
  / Merge EXPOSURE and TMSLICE dataset to get the PERNUM
  / As PTMNUM and TPTREFN are optional variables in DataSetManager, these    
  /     variables shall be conditionally checked if they exist in the datasets
  /----------------------------------------------------------------------------*/
  PROC SQL;
    CREATE TABLE &prefix._exp AS 
    SELECT a.subjid, a.visitnum, a.visit, 
           %if %tu_chkvarsexist(&exposuredset, tptrefn) eq  %then %do; a.tptrefn, a.tptref, %end ;
           %if %tu_chkvarsexist(&exposuredset, ptmnum)  eq  %then %do; a.ptmnum, a.ptm, %end ;
           a.exstdt as _exstdt, 
           %if %tu_chkvarsexist(&exposuredset, exsttm) eq  %then a.exsttm, ;
           b.pernum, b.period
    FROM &exposuredset a, 
         &tmslicedset  b
    WHERE a.visitnum=b.visitnum AND 
          %if ((%tu_chkvarsexist(&exposuredset, tptrefn) eq ) AND (%tu_chkvarsexist(&tmslicedset, tptrefn) eq )) %then a.tptrefn=b.tptrefn AND ;
          %if ((%tu_chkvarsexist(&exposuredset, ptmnum)  eq ) AND (%tu_chkvarsexist(&tmslicedset, ptmnum)  eq )) %then a.ptmnum =b.ptmnum  AND ;
          a.exstdt^=.

    ORDER BY a.subjid, b.pernum, a.visitnum 
        %if %tu_chkvarsexist(&exposuredset, tptrefn) eq  %then , a.tptrefn  ;
        %if %tu_chkvarsexist(&exposuredset, ptmnum)  eq  %then , a.ptmnum    ;
      ;
  QUIT;

  
  DATA &prefix._exp1(keep=subjid pernum);
    SET &prefix._exp;
    BY subjid pernum;
    IF FIRST.pernum;
  RUN;

  
  /** If PERNUM exists in dataset set patrtcd & patrtgrp **/
  /** to 'No trt' if the subject had no dose in period   **/
  PROC SORT DATA = &dsetin
             OUT = &prefix.1 ;
    BY subjid pernum;
  RUN;

  /*
  / Cater for treatment deviations that may exist for your study
  /   - PATRTGRP, PATRTCD, TPATRTCD, TPATRGGP should reflect actual treatment received 
  /   - If subject received no dose in a period then 
  /      PATRTCD/TPATRTCD = 888 and PATRTGRP/TPATRTGP = 'No Treatment'
  /------------------------------------------------------------------------------------*/
    DATA &prefix.2;
      MERGE &prefix.1 (in=a) &prefix._exp1(in=b);
      BY subjid pernum;
      IF a;                  * Not for SCR & FUP ;

      * Code for NO-Treatment information ;
      IF a and ^b AND pernum ^in(0,999) THEN DO;
        patrtcd=888;
        patrtgrp='No Treatment';

      END;

     %if "&trt_dev_exists"="Y"
     %then
       %do;
         OPTIONS MLOGIC MPRINT  ;
         %put %str(-----------------------------------------------------------------------------------------);
         %put %str(RTN)OTE: &macroname: Starting execution of user-supplied Treatment Deviation SAS code;
         %put %str(-----------------------------------------------------------------------------------------);

         * Code for Treatment Deviation information ;
         %INC "&g_rfmtdir./trt_deviation_file.sas" ;

         %put %str(-----------------------------------------------------------------------------------------);
         %put %str(RTN)OTE: &macroname: Finished execution of user-supplied Treatment Deviation SAS code;
         %put %str(-----------------------------------------------------------------------------------------);
         OPTIONS NOMLOGIC NOMPRINT  ;

        /*
        / Modification ID:          KS-003
        / Based on &g_debug to turn on debug level functionality
        /----------------------------------------------------------------------------*/
        
        %if &g_debug ge 2  %then 
        %do;
           %if %scan(&sysver, 1) ge 9 %then options mprint mprintnest;
           %else options mprint;
        %end;
        %if &g_debug ge 3 %then
        %do;
           %if %scan(&sysver, 1) ge 9 %then mlogic mlogicnest;
           %else mlogic;
        %end;
        %if &g_debug ge 4 %then symbolgen;
        %if &g_debug ge 6 %then msglevel=I;;
        
        %if &g_debug ge 9 %then
        %do;  
           %let LST_FILE = %sysfunc(getoption(print)); 
           
           %let n=%eval(%length(&LST_FILE) - %length(%scan(%nrbquote(&LST_FILE), -1, /\)));
           
           %if &n gt 0 %then %let LST_FILE=%substr(&LST_FILE, 1, &n);
           %else %let LST_FILE=;
           
           %if %nrbquote(&LST_FILE) ne %then
           %do;
              %let LST_FILE=%sysfunc(tranwrd(&LST_FILE, arprod, arwork));
           %end;
           
           %if %nrbquote(&G_FNC) eq %then
           %do;
              %if %sysfunc(fileexist(%nrbquote(&LST_FILE))) %then
                 filename mprint "&LST_FILE.driver_mfile.sas";   
              %else
                 filename mprint "driver_mfile.sas";;
              option mfile;
           %end;
           %else %do;
              %if %sysfunc(fileexist(%nrbquote(&LST_FILE))) %then
                 filename mprint "&LST_FILE.&G_FNC._mfile.sas";   
              %else
                 filename mprint "&G_FNC._mfile.sas";;
              option mfile;
           %end; /* %if %nrbquote(&G_FNC) eq %else */
           
        %end; /* %if &g_debug ge 9 */
      %end;

    RUN;

    %let outdset = &prefix.2 ;
  
  /** If TPERNUM exists in dataset set tpatrtcd & tpatrtgp **/
  /** to 'No trt' if the subject had no dose in period   **/
  %IF %tu_chkvarsexist(&dsetin,tpernum tpatrtcd tpatrtgp)= %THEN %DO;
  
    PROC SORT DATA=&prefix.2;
      BY subjid tpernum;
    RUN;

    DATA &prefix.3;
     MERGE &prefix.2 (in=a) &prefix._exp1(in=b rename=(pernum=tpernum));
     BY subjid tpernum;
     IF a;                  /** Not for SCR & FUP **/
     IF a and ^b AND tpernum ^in(0,999) THEN DO;
       tpatrtcd=888;
       tpatrtgp='No Treatment';
     END;

     %if "&trt_dev_exists"="Y"
     %then
       %do;
         OPTIONS MPRINT MLOGIC ;
         %put %str(-----------------------------------------------------------------------------------------);
         %put %str(RTN)OTE: &macroname: Starting execution of user-supplied Treatment Deviation SAS code;
         %put %str(-----------------------------------------------------------------------------------------);

      * Code for Treatment Deviation information ;
        %INC "&g_rfmtdir./trt_deviation_file.sas" ;

         %put %str(-----------------------------------------------------------------------------------------);
         %put %str(RTN)OTE: &macroname: Finished execution of user-supplied Treatment Deviation SAS code;
         %put %str(-----------------------------------------------------------------------------------------);
         OPTIONS NOMPRINT NOMLOGIC ;
        /*
        / Modification ID:          KS-003
        / Based on &g_debug to turn on debug level functionality
        /----------------------------------------------------------------------------*/
        
        %if &g_debug ge 2  %then 
        %do;
           %if %scan(&sysver, 1) ge 9 %then options mprint mprintnest;
           %else options mprint;
        %end;
        %if &g_debug ge 3 %then
        %do;
           %if %scan(&sysver, 1) ge 9 %then mlogic mlogicnest;
           %else mlogic;
        %end;
        %if &g_debug ge 4 %then symbolgen;
        %if &g_debug ge 6 %then msglevel=I;;
        
        %if &g_debug ge 9 %then
        %do;  
           %let LST_FILE = %sysfunc(getoption(print)); 
           
           %let n=%eval(%length(&LST_FILE) - %length(%scan(%nrbquote(&LST_FILE), -1, /\)));
           
           %if &n gt 0 %then %let LST_FILE=%substr(&LST_FILE, 1, &n);
           %else %let LST_FILE=;
           
           %if %nrbquote(&LST_FILE) ne %then
           %do;
              %let LST_FILE=%sysfunc(tranwrd(&LST_FILE, arprod, arwork));
           %end;
           
           %if %nrbquote(&G_FNC) eq %then
           %do;
              %if %sysfunc(fileexist(%nrbquote(&LST_FILE))) %then
                 filename mprint "&LST_FILE.driver_mfile.sas";   
              %else
                 filename mprint "driver_mfile.sas";;
              option mfile;
           %end;
           %else %do;
              %if %sysfunc(fileexist(%nrbquote(&LST_FILE))) %then
                 filename mprint "&LST_FILE.&G_FNC._mfile.sas";   
              %else
                 filename mprint "&G_FNC._mfile.sas";;
              option mfile;
           %end; /* %if %nrbquote(&G_FNC) eq %else */
           
        %end; /* %if &g_debug ge 9 */

       %end;

    RUN;

    %let outdset = &prefix.3 ;
  
  %END;

  /*----------------------------------------------------------------------*/
  /*--Output dataset */
  DATA &dsetout ; 
    SET &outdset ;
  RUN;

  /*----------------------------------------------------------------------*/
  /*--Tidy up and call tu_abort   */

  %tu_tidyup(rmdset=&prefix:, glbmac=NONE);
  %tu_abort;

%mend tu_p1_acttrt_xo;

