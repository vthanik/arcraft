/*******************************************************************************
|
| Macro Name:      tu_p1_calctpernum
|
| SAS Version:     9.1
|
| Created By:      Ian Barretto
|                  Khilit Shah
|
| Date:            04 April 2008
|
| Macro Purpose:   Derive TPERNUM and TPERIOD
|
|                  NB If the time is missing for any event where the date is 
|                     on the first day of any dosing period then a message is 
|                     output and it is assumed that the event occurred AFTER dosing.  
|                     However this MUST be checked.
|
|                     Any event where the date is missing will also output a message, 
|                     and it is assumed that the event is Pre-Treatment.  
|                     Again this MUST be checked.
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                                        DEFAULT
| -----------------  -------------------------------------------------  ----------
| DSETIN              Specifies the dataset for which the derivations   (None)
|                     are to be done.
|                     Valid values: valid dataset name
|
| DSETOUT             Specifies the name of the output dataset to be    (None)
|                     created.
|                     Valid values: valid dataset name
|
| DATADOMAIN          This signifies the type of dataset passed in and  (None)
|                     therefore the derivations to be performed.
|                     Expected values are:
|                       MULTIOBS:
|                           AE   adverse events
|                           CM   conmeds
|                           CM   cmanal
|                       SINGLEOBS:
|                           BL   blind
|                           DS   disposit
|                           DS2  ds
|                           IP   ipdisc  
|                           SD   stopdrug
|
| REFDAT             The name of the variable which                    (None)
|                    contains the reference date.
|
| REFTIM             The name of the variable which                     (None)
|                    contains the reference time.
|
| EXPOSUREDSET       Dataset name that contains your                    DMDATA.EXPOSURE
|                    exposure/dosing data
|
| TMSLICEDSET        Dataset name that contains your                    DMDATA.TMSLICE
|                    time slicing information
|
|
|
| Global macro variables created: NONE
|
| Macros called:
|(@) tr_putlocals
|(@) tu_chkvarsexist
|(@) tu_abort
|(@) tu_putglobals
|(@) tu_valparms
|
| Example:
|       %tu_p1_calctpernum (
|           DSETIN              = dmdata.conmeds,
|           DSETOUT             = ardata.conmeds,
|           DATADOMAIN          = CM,
|           EXPOSUREDSET        = dmdata.exposure,
|           REFDAT              = cmstdt,
|           REFTIM              = cmsttm,
|           TMSLICEDSET         = dmdata.tmslice
|           );
|
|******************************************************************************
| Change Log
|
| Modified By:              Suzanne Johnes (SEJ66932)
| Date of Modification:     03-Sep-08
| New version/draft number: 2.1
| Modification ID:          NA
| Reason For Modification:  To include IP data domain to allow the passing an  
|                             IPDISC dataset to the macro.
|*******************************************************************************
| Modified By:              Khilit Shah (kys41925)
| Date of Modification:     14-Oct-2008
| New version/draft number: 2.2
| Modification ID:          n/a
| Reason For Modification:  
|                           1 To allow optional merge by PTMNUM if this variable
|                              exists in the input datasets
|                           2 Allow macro to handle data where &refdat is not 
|                              contained within the input dataset (dsetin) e.g. 
|                              for IPDISC, ACTDT is optional variable
|                           3 Validation check included to generate RTERROR if 
|                              SI.TMSLICE dataset does not contain PERNUM/PERIOD 
|                           4 Include in the merge statements, a conditional 
|                             merge with variable TPTREFN/PTMNUM if it exists. 
|                           5 If EXSTTM is not included in exposuredset, then  
|                             create a dummy variable setting the values to missing 
|                           6 Validation check included to prevent output dataset 
|                             not be the same as the input dataset 
|*******************************************************************************
| Modified By:              
| Date of Modification:     
| New version/draft number: 
| Modification ID:          
| Reason For Modification:  
*******************************************************************************/

%macro tu_p1_calctpernum (dsetin       = /* Input dataset name */
                         ,dsetout      = /* Output dataset name */
                         ,datadomain   = /* Data Domain - One of (AE,BL,CM,DS,DS2,SD,IP) */
                         ,refdat       = /* Reference date variable name */
                         ,reftim       = /* Reference time variable name */
                         ,exposuredset = dmdata.exposure /* Exposure dataset name */
                         ,tmslicedset  = dmdata.tmslice  /* Time Slicing dataset name*/
                         );


  /*
  / Echo parameter values and global macro variables to the log
  /----------------------------------------------------------------------------*/
  %local MacroVersion macroname ;
  %let MacroName=&sysmacroname.;
  %let MacroVersion=2;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals()

  /*
  / Parameter validation
  /----------------------------------------------------------------------------*/
  %let dsetin       = %nrbquote(&dsetin.);
  %let dsetout      = %nrbquote(&dsetout.);
  %let refdat       = %nrbquote(&refdat.);
  %let reftim       = %nrbquote(&reftim.);
  %let exposuredset = %nrbquote(&exposuredset.);
  %let tmslicedset  = %nrbquote(&tmslicedset.);

  %let datadomain   = %nrbquote(%upcase(&datadomain));

  /*
  / Check for valid parameter values
  /   set up a macro variable to hold the pv_abort flag
  /----------------------------------------------------------------------------*/
  %local pv_abort  ;
  %let pv_abort = 0 ;


  * Input dataset name is not missing and input dataset exists ;
  %if %length(&dsetin) = 0 %then
    %do;
      %put %str(RTE)RROR: &macroname: Macro parameter (DSETIN) cannot be blank;
      %let pv_abort = 1;
    %end;
  %else
  %tu_valparms(
     macroname  =&macroname.
    ,chktype    =dsetExists
    ,pv_dsetin  =dsetin
   );

  * Output dataset name is not missing ;
  %if %length(&dsetout) = 0 %then
    %do;
      %put %str(RTE)RROR: &macroname: Macro parameter (DSETOUT) cannot be blank;
      %let pv_abort = 1;
    %end;

  /*
  / If the input dataset name is the same as the output dataset name,
  / write an error to the log.
  /----------------------------------------------------------------------------*/
  %if %qscan(&dsetin, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
  %do;
    %put %str(RTE)RROR: &sysmacroname: The input dataset name DSETIN(=&dsetin) is the same as output data set name DSETOUT(=&dsetout).;
    %let pv_abort=1;
  %end;


  * Exposure dataset name is not missing and dataset exists ;
  %if %length(&exposuredset) = 0 %then
    %do;
      %put %str(RTE)RROR: &macroname: Macro parameter (EXPOSUREDSET) cannot be blank;
      %let pv_abort = 1;
    %end;
  %else
  %tu_valparms(
     macroname  =&macroname.
    ,chktype    =dsetExists
    ,pv_dsetin  =exposuredset
   );

  * DMDATA.EXPOSURE variable check ;
  %let exposure_varlist=exstdt;
  %tu_valparms(
     macroname =&macroname.
    ,chktype   =varexists
    ,pv_dsetin =exposuredset
    ,pv_varsin =exposure_varlist
   );

  * Time Slice dataset name is not missing and dataset exists ;
  %if %length(&tmslicedset) = 0 %then
    %do;
      %put %str(RTE)RROR: &macroname: Macro parameter (TMSLICEDSET) cannot be blank;
      %let pv_abort = 1;
    %end;
  %else
  %tu_valparms(
     macroname  =&macroname.
    ,chktype    =dsetExists
    ,pv_dsetin  =tmslicedset
   );

  * DMDATA.TMSLICE variable check ;
  %let tmslice_varlist=pernum period;
  %tu_valparms(
    macroname  =&macroname. ,
    chktype    =varexists,
    pv_dsetin  =tmslicedset,
    pv_varsin  =tmslice_varlist
   );


  * Reference DATE is not missing and variable exists ;
  %if %length(&refdat) = 0 %then
    %do;
      %put %str(RTE)RROR: &macroname: Macro parameter (REFDAT) cannot be blank;
      %let pv_abort = 1;
    %end;
  %else %if &datadomain NE IP %then %do;
    %tu_valparms(
       macroname=&macroname.
      ,chktype=varexists
      ,pv_dsetin=dsetin
      ,pv_varsin=refdat
     );
   %end;

 /*
 / If parameter REFTIM has been specified, check that it exists on the
 / input dataset.
 /----------------------------------------------------------------------------*/
  %if &reftim ne  %then
  %do;
    %if %tu_chkvarsexist(&dsetin, &reftim) ne  %then
    %do;
      %put %str(RTE)RROR: &macroname: The dataset DSETIN (&dsetin) does not contain the variable REFTIM (&reftim) ;
      %let g_abort=1;
    %end;  
  %end;  

  * Data Domain (e.g. DS, AE etc) cannot be supplied missing ;
  %if %length(&datadomain) = 0 %then
    %do;
      %put %str(RTE)RROR: &macroname: Macro parameter (DATADOMAIN) cannot be blank;
      %let pv_abort = 1;
    %end;
  %else %if (&datadomain NE AE) and (&datadomain NE CM) and (&datadomain NE BL) and
            (&datadomain NE DS) and (&datadomain NE DS2) and (&datadomain NE SD) and
            (&datadomain NE IP)
    %then 
    %do;
      %put %str(RTE)RROR: &macroname: Value of DATADOMAIN(=&datadomain) is invalid. Valid values are one of AE, CM, BL, DS, DS2, SD, IP;
      %let pv_abort=1;
    %end; 


  /*
  / Check if Exposure dset has Unscheduled records. If it has then abort with
  /   g_abort flag as user shall have to process the dataset to identify how to
  /   handle unscheduled data for dosing.
  /----------------------------------------------------------------------------*/

  %if %sysfunc(exist(&exposuredset)) ne 0 %then %do;
    data _NULL_ ;
      set &exposuredset ;
        %if %tu_chkvarsexist(&exposuredset,ptmnum) eq  %then %do ;
          IF INT(visitnum) NE visitnum OR INT(ptmnum) NE ptmnum THEN do ;
            put "RTE" "RROR: %UPCASE(&sysmacroname): %UPCASE(&exposuredset) contains UNSCHEDULED dosing records for " subjid= visitnum= ptmnum= ;
            call symput('pv_abort', 1) ;
          end;
        %end;
        %else %do;
          IF INT(visitnum) NE visitnum then do ;
            put "RTE" "RROR: %UPCASE(&sysmacroname): %UPCASE(&exposuredset) contains UNSCHEDULED dosing records for " subjid= visitnum=  ;
            call symput('pv_abort', 1) ;
          end;
        %end ;
    run;
  %end;

  /*
  / Complete parameter validation
  /----------------------------------------------------------------------------*/
  %if %eval(&g_abort. + &pv_abort.) gt 0 %then %do;
    %put %str(RTE)RROR: &macroname: Macro has failed parameter validation check for reasons stated with %str(RTE)RRORs above;
    %tu_abort(option=force);
  %end;


  /*
  / NORMAL PROCESSING
  /----------------------------------------------------------------------------*/

  /*
  / Initialise local macro variables
  /----------------------------------------------------------------------------*/
  %local prefix bylist  ;
  %let prefix = _tu_p1_calctpernum;   /* Root name for temporary work datasets */

  /*
  / MULTIOBS - This is applicable for AEs and CONMEDs data
  /           A subject can have several unscheduled events within a period.
  /           e.g. subject can take several CONMEDs during a single treatment
  /           period
  / SINGLEOBS - This is applicable for BL, DS, DS2, IP, DS data
  /           These events are still unplanned e.g. A subject drops out of a study
  /           however these events can occur only ONCE in any given period.
  /----------------------------------------------------------------------------*/
  %if &datadomain=AE or &datadomain=CM %then %let domaintype=MULTIOBS;
  %else %let domaintype=SINGLEOBS;


  /*
  / Any EVENTs with a missing start time that occurs on first day of dosing is
  / allocated to the dose taken that day, so if the REFTIM is missing then use
  / 23:59:59 to set the datetime.
  / NOTE1: A RTWARNING message shall also be printed to the log indicating a missing
  /        time happening on the day of dosing. The coding for this WARNING
  /        message appears further down.
  / NOTE2: The setting of the missing time to 23:59:59 is for the purposes of
  /        calculation only and shall not be retained in the output dataset.
  /----------------------------------------------------------------------------*/
  data &prefix._dset1;
    set &dsetin;
    if &refdat ne . then do;
      %if ( %nrbquote(&reftim) ne ) %then 
      %do ;
        if &reftim ne . then &prefix._datetime=dhms(&refdat, 0, 0, &reftim);
        else &prefix._datetime=dhms(&refdat, 23, 59, 59);
      %end ;
      %else %if ( %nrbquote(&reftim) = ) %then
      %do ;
        &prefix._datetime=dhms(&refdat, 23, 59, 59);
      %end ;
    end;

    * Drop TPERIOD variable if it exists in the input datasets     ;
    *   This variable shall be recreated by reading in the TMSLICE ;
    *   dataset and setting TPERIOD=PERIOD                        ;
    %if %tu_chkvarsexist(&dsetin, tperiod)= %then drop tperiod;;

    * If TPERNUM exists in the input dataset, then this variable  ;
    *    shall be dropped as the variable and its contect shall   ;
    *    be recreated in the process steps below                  ;
    %if &domaintype=SINGLEOBS %then %do;
      %if %tu_chkvarsexist(&dsetin, tpernum)= %then drop tpernum;;
    %end;

  run;

  proc sort data=&prefix._dset1 out=&prefix._dset2;
    by subjid &prefix._datetime;
  run;

  /*
  / Generate a BYLIST value to hold the variables that shall be used for the 
  /   merge with EXPOSURE and TMSLICE dataset. 
  / As PTMNUM and TPTREFN are optional variables in DataSetManager, these    
  /     variables shall be used as the 'BY' variables conditionally, i.e. if they
  /     exist in the EXPOSURE and TMSLICE datasets
  /----------------------------------------------------------------------------*/
  data _null_ ;
    %let bylist = visitnum ;
    %if ((%tu_chkvarsexist(&exposuredset, tptrefn) eq ) AND (%tu_chkvarsexist(&tmslicedset, tptrefn) eq )) %then %let bylist = &bylist tptrefn;
    %if ((%tu_chkvarsexist(&exposuredset, ptmnum)  eq ) AND (%tu_chkvarsexist(&tmslicedset, ptmnum)  eq )) %then %let bylist = &bylist ptmnum;
  run;

  /*
  / If the dosing time EXSTTM is missing then use 00:00:00 to set the datetime.
  / NB note that any missing date is excluded as this indicates that the subject
  /    was not dosed for that particular visit
  / Exclude any Liver Events records in the exposure dataset (visitnum=811)
  /----------------------------------------------------------------------------*/
  data &prefix._expo1a ;
    set &exposuredset ;
      * IF &exposuredset does not contain time (exsttm) then ;
      *   initialise EXSTTM and set the values to missing    ;
      %if %tu_chkvarsexist(&exposuredset, exsttm) ne  %then %do ;
        exsttm = . ;
      %end ;
  run;

  proc sort data = &prefix._expo1a (keep=subjid &bylist exstdt exsttm 
                                  where=(exstdt ne . and visitnum ne 811)
                                  )
             out = &prefix._expo1;
    by &bylist ;
  run;

  /*
  / Merge the EXPOSURE and TMSLICE dataset.
  / NB: For MultiOBS study, PERNUM from SI.TMSLICE shall be retained
  /     For SingleOBS study, PERNUM and PERIOD from SI.TMSLICE shall be retained
  /----------------------------------------------------------------------------*/
  proc sort data=&tmslicedset (keep = &bylist pernum %if &domaintype=SINGLEOBS %then period ; ) 
                               out  = &prefix._tmslice;
    by &bylist ;
  run;

  data &prefix._expo2 (drop  = &bylist 
                       rename=(
                         %if &domaintype=MULTIOBS %then %do;
                           pernum=&prefix._pernum
                         %end;
                         %else %if &domaintype=SINGLEOBS %then %do;
                           pernum=&prefix._tpernum
                           period=&prefix._tperiod
                         %end;
                       ));

    merge &prefix._expo1 (in=a) &prefix._tmslice;
    by &bylist ;
    if a;
    if exsttm ne . then &prefix._datetime=dhms(exstdt, 0, 0, exsttm);
    else &prefix._datetime=dhms(exstdt, 0, 0, 0);
  run;

  /*
  / Sort Exposure dataset by subject pernum/tpernum date and time
  /----------------------------------------------------------------------------*/
  proc sort data=&prefix._expo2 out=&prefix._expo3 nodupkey;
    by subjid
       %if &domaintype=MULTIOBS %then %do;
         &prefix._pernum
       %end;
       %else %if &domaintype=SINGLEOBS %then %do;
         &prefix._tpernum
       %end;
       exstdt exsttm;
  run;

  /*
  / Keep only the first pernum/tpernum record from the exposure dataset
  /----------------------------------------------------------------------------*/
  proc sort data=&prefix._expo3 out=&prefix._expo4 nodupkey;
    by subjid
       %if &domaintype=MULTIOBS %then %do;
         &prefix._pernum;
       %end;
       %else %if &domaintype=SINGLEOBS %then %do;
         &prefix._tpernum;
       %end;
  run;

  /* For AE and CM
  /----------------------------------------------------------------------------*/
  %if &domaintype=MULTIOBS %then %do;

     /*
     / Add the TPERNUM to the input dataset and set PERNUM 
     /    If PERNUM is not available in the output dataset and the next utility
     /    macro that is generally called within the wrapper macro shall be 
     /    tu_rantrt. 
     /    TU_RANTRT requires the presences of PERNUM else treatments shall not 
     /    get assigned
     / If the TPERNUM already has a non-null value then do not set, and set the
     /   TPERNUM_SET flag.
     /----------------------------------------------------------------------------*/
     data &prefix._dset3;
       set &prefix._expo4 (in=a keep=subjid &prefix._pernum &prefix._datetime)
           &prefix._dset2 (in=b);
       by subjid &prefix._datetime;
       retain &prefix._tpernum;
       if first.subjid then &prefix._tpernum=0;
       if a then &prefix._tpernum=&prefix._pernum;
       if b then do;
         if tpernum=. then tpernum=&prefix._tpernum;
         else &prefix._tpernum_set=1;
         pernum=tpernum;
         output;
       end;
     run;

     /*
     / Report any obs that have a missing start date or which start on the first
     / day of period dosing and having a missing start time or dosing time.
     /----------------------------------------------------------------------------*/
     data &prefix._expo5;
       set &prefix._expo4 (keep=subjid exstdt exsttm rename=(exsttm=&prefix._exsttm));
       by subjid;
       &prefix._first_flag=first.subjid;
     run;

     data &prefix._dset4 (drop=&prefix._:);
       merge &prefix._dset3 (in=a) &prefix._expo5 (rename=(exstdt=&refdat) in=b);
       by subjid &REFDAT;
       if a;
       if not &prefix._tpernum_set then do;
         if &refdat =. then put
           "RTW" "ARNING: &REFDAT is missing for " subjid= ", TPERIOD has been assigned to Pre-Treatment";
         * If REFTIM is not supplied, then exclude from RTWARNING messages ;
         %if ( %nrbquote(&reftim) ne ) %then 
         %do ;           
           else if b and &reftim = . then put
             "RTW" "ARNING: &REFTIM is missing for " subjid= &REFDAT= ", which occurs on first day of period " tpernum;
         %end ;
         else if b and &prefix._exsttm=. then put
           "RTW" "ARNING: EXSTTM is missing for " subjid= &REFDAT= ", which is the first dose of period " tpernum;
       end;
     run;

     /*
     / Use TMSLICE to add the TPERIOD
     /----------------------------------------------------------------------------*/
     proc sort data=&tmslicedset (keep=pernum period rename=(pernum=tpernum period=tperiod))
                out=&prefix._tmslice2 nodupkey;
       by tpernum tperiod;
     run;

     proc sort data=&prefix._dset4 out=&prefix._dset5;
       by tpernum;
     run;

     data &dsetout;
       format tperiod $120. ;
       merge &prefix._dset5 (in=a) 
             &prefix._tmslice2;
       by tpernum;
       if a;
       if tpernum=0 then tperiod='Pre-Treatment';
     run;

    /* END For AE and CM
    /----------------------------------------------------------------------------*/
 %end;

 /* For SingleObs - BL, DS, DS2, IP, SD
 / Add the TPERNUM & TPERIOD to the input dataset.
 / If REFDAT is missing then issue a warning message 
 /----------------------------------------------------------------------------*/
 %else %if &domaintype=SINGLEOBS %then %do;

     proc sort data = &prefix._expo4 ;
       by subjid &prefix._datetime ;
     run;
     proc sort data = &prefix._dset2 ;
       by subjid &prefix._datetime ;
     run;

     /*
     / Output observations with missing &refdat to a temp dataset .
     /----------------------------------------------------------------------------*/
     data &prefix._dset3_a ;
       set &prefix._dset2 (WHERE = (&refdat = . ) ) ;
     run;

     /*
     / Output observations with non-missing &refdat to a temp dataset .
     /----------------------------------------------------------------------------*/
     data &prefix._dset3_b ;
       set &prefix._dset2 (WHERE = (&refdat NE . ) ) ;
     run;

     /*
     / IF Missing &refdat from your SINGLEOBS input dataset.
     /  NOTE: _EXPO4 temp dataset is created by merging EXPOSURE and TMSLICE datasets
     /        that shall provide you the SUBJID, Date, Time and PERNUM/PERIOD information.
     /       - PERNUM in _expo4 is renamed to TPERNUM
     /       - PERIOD in _expo4 is renamed to TPERIOD
     / 
     / - Retain TPERNUM/TPERIOD from _expo4
     / 
     / - The TPERNUM/TPERIOD assigned to your SingleObs dataset, e.g. IPDISC that 
     /   contains missing &REFDAT will be the last TPERNUM/TPERIOD read in from 
     /   _expo4 dataset
     / 
     / - If _expo4 dataset does not contain the subjid referenced in your SingleObs 
     /   dataset E.G. Ipdisc, then the values for TPERNUM/TPERIOD shall be set to 
     /   0 / Pre-Treatment respectively. 
     /   A RTWARNING of the above shall be printed to your SAS log
     /----------------------------------------------------------------------------*/
     data &prefix._dset4_a;
       set &prefix._expo4   (in=a keep=subjid &prefix._tpernum &prefix._tperiod &prefix._datetime) 
           &prefix._dset3_a (in=b);
       by subjid ;
       format tperiod $120. ;
       retain tpernum tperiod;

       if a then do;
         tpernum=&prefix._tpernum;
         tperiod=&prefix._tperiod;
       end;
       if FIRST.subjid AND ^a then do ;
         tpernum=0;
         tperiod='Pre-Treatment';
       end;
       if b and &refdat =. then put
           "RTW" "ARNING: &REFDAT is missing for " subjid= ", TPERIOD has been assigned to " TPERIOD "and TPERNUM to " TPERNUM;
       if b then do; 
         pernum = tpernum ;
         output;
       end;
     run;


     /*
     / IF NOT Missing &refdat from your SINGLEOBS input dataset.
     /  NOTE: _EXPO4 temp dataset is created by merging EXPOSURE and TMSLICE datasets
     /        that shall provide you the SUBJID, Date, Time and PERNUM/PERIOD information.
     /       - PERNUM in _expo4 is renamed to TPERNUM
     /       - PERIOD in _expo4 is renamed to TPERIOD
     / 
     / - If &refdat is not missing from your DSET, then this record when SET with your
     /   _expo4 dataset. This record shall be interleaved based on date/time values
     / 
     / - Retain TPERNUM/TPERIOD from _expo4
     / 
     / - The TPERNUM/TPERIOD assigned to your SingleObs dataset, e.g. IPDISC  
     /   shall be based the TPERNUM/TPERIOD read in from _expo4 dataset
     / 
     / - IF your SingleObs dataset record is the first slotted record based on date/time
     /   then the values for TPERNUM/TPERIOD shall be set to 0 / Pre-Treatment 
     /   respectively. This is because the date/time value for your SingleObs record
     /   is happening before dosing. No warning's shall be included in the log for this.
     /----------------------------------------------------------------------------*/
     data &prefix._dset4_b;
       set &prefix._expo4   (in=a keep=subjid &prefix._tpernum &prefix._tperiod &prefix._datetime) 
           &prefix._dset3_b (in=b);
       by subjid &prefix._datetime;
       format tperiod $120. ;
       retain tpernum tperiod;
       if first.subjid then do;
         tpernum=0;
         tperiod='Pre-Treatment';
       end;
       if a then do;
         tpernum=&prefix._tpernum;
         tperiod=&prefix._tperiod;
       end;
       if b then do; 
         pernum = tpernum ;
         output;
       end;
     run;

     data &dsetout (drop=&prefix._:);
       set &prefix._dset4_a 
           &prefix._dset4_b;
     proc sort ;
       by subjid ;
     run;


 %end;
 /* For BL, DS, DS2, IP, SD
 /----------------------------------------------------------------------------*/

%mend tu_p1_calctpernum;
