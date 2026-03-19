/*******************************************************************************
|
| Macro Name:      tu_pernum
|
| Macro Version:   3 build 2
|
| SAS Version:     8.2
|
| Created By:      Eric Simms / Yongwei Wang
|
| Date:            27-Jan-2005
|
| Macro Purpose:   Create an output data set with derived period related information: 
|                  PERNUM, PERIOD, PERSTDT, PERENDT, PERTSDT and PERTENDT, by merging 
|                  SI datasets EXPOSURE, TMSLICE and VISIT             
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                            REQ/OPT  DEFAULT
| -----------------  -------------------------------------  -------  ----------
| DSETOUT            Specifies the name of the output       REQ      ARDATA.PERIOD
|                    dataset to be created.
|                    Valid values: valid dataset name.
|
| EXPOSUREDSET       Specifies the EXPOSURE SI dataset      OPT      DMDATA.EXPOSURE
|                    which will be used along with the
|                    TMSLICEDSET and VISITDSET datasets
|                    to produce a PERIOD A&R dataset.
|                    Valid values: valid dataset name.
|
| TMSLICEDSET        Specifies the TMSLICEDSET SI dataset   REQ      DMDATA.TMSLICE 
|                    which will be used along with the
|                    EXPOSUREDSET and VISITDSET datasets
|                    to produce a PERIOD A&R dataset.
|                    Valid values: valid dataset name.
|
| VISITDSET          Specifies the VISIT SI dataset         REQ      DMDATA.VISIT   
|                    which will be used along with the
|                    EXPOSUREDSET and TMSLICEDSET datasets
|                    to produce a PERIOD A&R dataset.
|                    Valid values: valid dataset name.
|
| -----------------  -------------------------------------  -------  ----------
|
| The macro references the following datasets :-
| ------------------  -------  ------------------------------------------------
| Name                Req/Opt  Description
| ------------------  -------  ------------------------------------------------
| &EXPOSUREDSET       Opt      Parameter specified dataset
| &TMSLICEDSET        Req      Parameter specified dataset
| &VISITDSET          Req      Parameter specified dataset
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
|(@) tu_chkvarsexist
|(@) tu_putglobals
|(@) tu_tidyup
|
| Example:
|    %tc_pernum(dsetout=temp1)
|
|******************************************************************************
| Change Log
|
| Modified By:               Yongwei Wang
| Date of Modification:      21-Feb-2005
| New version/draft number:  1/2
| Modification ID:           YW001
| Reason For Modification:   1. Set the PERTSTDT to missing if the result from 
|                               SQL statement has PERTSTDT gt PERENDT.
|                            2. Added check if &TMSLICEDET exist before checking 
|                               the existance of PERNUM PERIOD.
|
| Modified By:               Yongwei Wang
| Date of Modification:      17-Mar-2005
| New version/draft number:  1/3
| Modification ID:           YW002
| Reason For Modification:   Fixed a typo in RTWARNING message
|
| Modified By:               Yongwei Wang
| Date of Modification:      22-Sep-2005
| New version/draft number:  2/1
| Modification ID:           YW003
| Reason For Modification:   Requested by change request HRT0090
|                            1. Added TPERNUM=PERNUM and TPERIOD=PERIOD to input dataset
|                            2. Modified the step ( &VISITTM eq ) or ( &EXSTTM eq ) to 
|                               three steps, so that when &VISITTM is missing, the PERTSTDT 
|                               can be calculated based on the first &EXSTTM in the period 
|                               and the PERTENDT can be calculated based on the last &EXENTM 
|                               in the period
|                            3. Changed perentm=persttm - 1 to perentm=perentm -1
|                            4. Added label for perstdt, perendt, persttm, perentm,
|                               tpernum, priod, pertstdt, pertsttm, pertendt and pertentm
|
| Modified By:               Shan Lee
| Date of Modification:      01-Oct-2007
| New version/draft number:  3/1
| Modification ID:           SL001
| Reason For Modification:   Allow dataset options to be specified with dataset name 
|                            parameters. HRT0184
|                            Also, create new parameters PERSTDTVAR and PERTSTDTVAR,
|                            to avoid hard-coding of variables perstdt and pertstdt.
|
| Modified By:               Shan Lee
| Date of Modification:      04-Oct-2007
| New version/draft number:  3/2
| Modification ID:           n/a
| Reason For Modification:   Remove parameters PERSTDTVAR and PERTSTDTVAR - The original
|                            reasoning for creating these parameters was to allow 
|                            tu_perstd to rename the variables PERSTDT and PERTSTDT,
|                            which are created by calling tu_pernum. However, tu_perstd
|                            can rename the variables created by tu_pernum, even if the
|                            variable names are not parameters of tu_pernum, so there is
|                            no need to introduce additional parameters to tu_pernum.
*****************************************************************************************/

%macro tu_pernum (
   dsetout      = ARDATA.PERIOD,   /* Output dataset name */
   exposuredset = DMDATA.EXPOSURE, /* Exposure dataset name */
   tmslicedset  = DMDATA.TMSLICE,  /* Time slice dataset name */
   visitdset    = DMDATA.VISIT    /* Visit dataset name */
   );

   /*
   / Echo parameter values and global macro variables to the log.
   /----------------------------------------------------------------------------*/
  
   %local MacroVersion;
   %let MacroVersion = 3 build 2;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals() 
     
   /*
   / Initialise counter for appending to temporary dataset names for the
   / purpose of tracking datasets through a number of optional sequential
   / data processing steps.
   /----------------------------------------------------------------------------*/
   
   %local prefix _tsttm _tsetm exsttm i visittm exentm loopi listvars thisvar exityn;

   %let prefix=_pernum;   /* Root name for temporary work datasets */
   %let i=1;
  
   /*
   / Check if required parameters TMSLICEDSET, VISITDSET, DSETOUT are blank
   /----------------------------------------------------------------------------*/
  
   %let listvars=TMSLICEDSET VISITDSET DSETOUT;
   
   %do loopi=1 %to 3;  
      %let thisvar=%scan(&listvars, &loopi, %str( ));
      %let &thisvar=%qupcase(&&&thisvar);      
      %if  &&&thisvar eq %then
      %do;
         %put %str(RTE)RROR: &sysmacroname: The parameter &thisvar is required.;
         %let g_abort=1;
      %end;
   %end;  /* end of do-to loop */
     
   %if &g_abort eq 1 %then
   %do;
      %tu_abort;
   %end;
   
   /*
   / Check if any of parameters is not valid.
   /----------------------------------------------------------------------------*/
   
   %let listvars=TMSLICEDSET VISITDSET EXPOSUREDSET;
   %let exityn=N;
   
   %do loopi=1 %to 3;
      %let thisvar=%scan(&listvars, &loopi, %str( ));
      %let &thisvar=%qupcase(&&&thisvar);      
      %if  &&&thisvar ne %then
      %do;
      
         /*
         / Data set &TMSLICEDSET &VISITDSET and &EXPOSUREDSET must exist, if given
         / Allow dataset options to be specified SL001.         
         /-----------------------------------------------------------------------*/
         
         %if %sysfunc(exist(%qscan(&&&thisvar, 1, %str(%()))) eq 0 %then
         %do;            
            %put %str(RTW)ARNING: &sysmacroname: dataset &thisvar(=&&&thisvar) does not exist. PERIOD information can not be derived;
            %let exityn=Y;
         %end;     

      %end; /* end-if on &&&thisvar ne */
   %end; /* end of do-to loop */
       
   /*
   / If variables PERNUM/PERIOD are not on the TMSLICEDSET dataset, then we cannot  
   / process anything. Give an error message and halt.
   / YW001: Added condition %if %sysfunc(exist(&tmslicedset)) gt 0
   / SL001: Allow dataset options to be specified.
   /----------------------------------------------------------------------------*/
   
   %if %sysfunc(exist(%qscan(&tmslicedset, 1, %str(%()))) gt 0 %then
   %do;
      data &prefix._tmslicexist;
         if 0 then set %unquote(&tmslicedset);
      run;
      %if %tu_chkvarsexist(&prefix._tmslicexist, PERNUM) ne  %then
      %do;
         %put %str(RTW)ARNING: &sysmacroname: The variable PERNUM does not exist in TMSLICEDSET(=&TMSLICEDSET) dataset. PERIOD information can not be derived;
         %let exityn=Y;
      %end;
      
      %if %tu_chkvarsexist(&prefix._tmslicexist, PERIOD) ne  %then
      %do;
         %put %str(RTW)ARNING: &sysmacroname: The variable PERIOD does not exist in TMSLICEDSET(=&TMSLICEDSET) dataset. PERIOD information can not be derived;
         %let exityn=Y;
      %end;
   %end; /* end-if on %sysfunc(exist(%qscan(&tmslicedset, 1, %str(%()))) gt 0 */
   
   %if &exityn eq Y %then %goto endmac;
   
   /*
   / NORMAL PROCESSING
   /----------------------------------------------------------------------------*/
  
   /*
   / Get period information from TMSLICE.
   / Allow dataset options to be specified - SL001.
   /----------------------------------------------------------------------------*/
     
   proc sort data=%unquote(&tmslicedset)
             out=&prefix._tmslice
             (keep=studyid visitnum pernum period) 
             nodupkey
             ;
      by studyid visitnum;
   run;
  
   /*
   / Check for use of visit times 
   /----------------------------------------------------------------------------*/
   data &prefix._visitexist;
      if 0 then set %unquote(&visitdset);
   run;
 
   %if %tu_chkvarsexist(&prefix._visitexist, VISITTM) eq  %then %let visittm=VISITTM;
   %else %let visittm=;
  
   /*
   / Get visit information from VISIT.
   / Allow dataset options to be specified - SL001.
   /----------------------------------------------------------------------------*/
  
   proc sort data=%unquote(&visitdset)
             out=&prefix._visit
             (keep=studyid subjid visitnum visitdt &visittm) 
             ;
      by studyid visitnum subjid visitdt &visittm ;
      where visitdt ne . ;
   run;
   
   data &prefix._visit2;
      set &prefix._visit;
      by studyid visitnum subjid visitdt &visittm ;
      if first.subjid;
   run;
  
   /*
   / Merge tmslice and visit data.
   /----------------------------------------------------------------------------*/
  
   data &prefix._ds&i;
      merge &prefix._tmslice(in=A) &prefix._visit2(in=B);
      by studyid visitnum;
      if A and B;
  
      format perstdt date9.;
      label perstdt="Period start date";
      perstdt=visitdt;
  
      %if &visittm ne  %then
      %do;
         format persttm time5.;
         label persttm="Period start time";
         persttm=visittm;
      %end;
   run;
  
   /*
   / Get first visit date/time within each period.
   /----------------------------------------------------------------------------*/
  
   proc sort data=&prefix._ds&i out=&prefix._ds%eval(&i+1);
      by studyid subjid pernum visitdt &visittm;
   run;
  
   %let i = %eval(&i + 1);
  
   data &prefix._ds%eval(&i+1)(drop=visitnum visitdt &visittm);
      set &prefix._ds&i;
      by studyid subjid pernum visitdt &visittm;
      if first.pernum;
   run;
  
   %let i = %eval(&i + 1);
  
   /*
   / Obtain period end date/time.
   /----------------------------------------------------------------------------*/
   
   /* Order by reverse period number */
   proc sort data=&prefix._ds&i out=&prefix._ds%eval(&i+1);
      by studyid subjid descending pernum;
   run;
   
   %let i = %eval(&i + 1);
   
   /* Obtain period date/time from last record */
   data &prefix._ds%eval(&i+1);
      set &prefix._ds&i;
      by studyid subjid;
     
      format perendt date9.; 
      label perendt="Period end date";
     
      %if &visittm eq  %then 
      %do;
          perendt = lag(perstdt) - 1;
      %end;
      %else
      %do;      
          format perentm time5.; 
          label perentm="Period end time";
          perentm = lag(persttm);   /* YW001: lag before compare */
          
          if perentm ne '00:00'T then perendt = lag(perstdt);
          else perendt = lag(perstdt) - 1;
          
          perentm = perentm - 1;   /* YW003: Changed persttm -1 to perentm -1 */
      %end;
   run;
   
   %let i = %eval(&i + 1);
   
   /*
   / For last period of each subject, date set to 10000 days   
   / after start of period, time to set to zero, if applicable.
   /----------------------------------------------------------------------------*/
   
   data &prefix._ds%eval(&i+1);
      set &prefix._ds&i;
      by studyid subjid;
      label tpernum="Treatment period number"
            tperiod="Treatment period";
   
      if first.subjid then perendt = perstdt + 10000;
   
      %if &visittm ne  %then
      %do;
          if first.subjid then perentm = 0;
      %end;
      
      /* YW003: Set TPERNUM=PERNUM and TPERIOD=PERIOD to input dataset */
      tpernum=pernum;
      tperiod=period;      
   run;
   
   %let i = %eval(&i + 1);
   
   %if &exposuredset ne  %then  /* EXPOSUREDSET has a non-blank value */
   %do;
      data &prefix._exposureexist;
         if 0 then set %unquote(&exposuredset);
      run;
      
      /*
      / Check for existence of start and end times of exposure.
      /----------------------------------------------------------------------------*/
     
      %if %tu_chkvarsexist(&prefix._exposureexist, EXSTTM) ne %then %let exsttm=;
      %else %let exsttm=EXSTTM;
     
      %if %tu_chkvarsexist(&prefix._exposureexist, EXENTM) ne %then %let exentm=;
      %else %let exentm=EXENTM;
      
      /*
      / YW003: Modified the step ( &VISITTM eq ) or ( &EXSTTM eq ) to three steps,
      / so that when &VISITTM is missing, the PERTSTDT can be calculated based on the
      / first &EXSTTM in the period and the PERTENDT can be calculated based on the
      / last &EXENTM in the period. The three steps are as follows:
      / 1.  ( &EXSTTM eq )
      / 2.  ( &VISITTM eq ) and ( &EXSTTM ne ) and (&EXENTM  ne )
      / 3.  ( &VISITTM eq ) and ( &EXSTTM ne ) and (&EXENTM  eq )
      /----------------------------------------------------------------------------*/
    
      proc sql noprint;
         create table &prefix._ds%eval(&i+1) as
      
         %if ( &exsttm eq ) %then
         %do;
             select a.*, b.exstdt as _tstdt, b.exendt as pertendt
             from &prefix._ds&i as a left join %unquote(&exposuredset) as b
             on  a.studyid eq b.studyid
             and a.subjid  eq b.subjid
             and a.perstdt le b.exstdt
             and a.perendt ge b.exendt
             and b.exstdt is not null;
         %end; /* end-if ( &visittm eq ) and ( &exsttm eq ) */
    
         %else %if ( &visittm eq ) and ( &exsttm ne ) and (&exentm  ne ) %then
         %do;
             select a.*, b.exstdt as _tstdt, b.exsttm as _tsttm,
                         b.exendt as pertendt, b.exentm as pertentm,
                         86400*b.exstdt+b.exsttm as _tstdm,
                         86400*b.exendt+b.exentm as pertendm
             from &prefix._ds&i as a left join %unquote(&exposuredset) as b
             on  a.studyid eq b.studyid
             and a.subjid  eq b.subjid
             and a.perstdt le b.exstdt
             and a.perendt ge b.exendt
             and b.exstdt is not null;
         %end; /* end-if ( &visittm eq ) and ( &exsttm ne ) and (&exentm  ne ) */
         
         %else %if ( &visittm eq ) and ( &exsttm ne ) %then
         %do;
             select a.*, b.exstdt as _tstdt, b.exsttm as _tsttm,
                         b.exendt as pertendt,
                         86400*b.exstdt+b.exsttm as _tstdm
             from &prefix._ds&i as a left join %unquote(&exposuredset) as b
             on  a.studyid eq b.studyid
             and a.subjid  eq b.subjid
             and a.perstdt le b.exstdt
             and a.perendt ge b.exendt
             and b.exstdt is not null;
         %end; /* end-if ( &visittm eq ) and ( &exsttm ne ) */         
                 
         %else %if ( &visittm ne ) and ( &exsttm  ne ) and (&exentm  ne ) %then 
         %do;
             select a.*, b.exstdt as _tstdt, b.exsttm as _tsttm,
                         b.exendt as pertendt, b.exentm as pertentm,
                         86400*b.exstdt+b.exsttm as _tstdm,
                         86400*b.exendt+b.exentm as pertendm
             from &prefix._ds&i as a left join %unquote(&exposuredset) as b
             on  a.studyid eq b.studyid
             and a.subjid  eq b.subjid
             and ( (a.perstdt lt b.exstdt) or (a.perstdt eq b.exstdt and a.persttm le b.exsttm) )
             and ( (a.perendt gt b.exendt) or (a.perendt eq b.exendt and a.perentm ge b.exentm) )
             and b.exstdt is not null;
         %end; /* end-if ( &visittm ne ) and ( &exsttm  ne ) and (&exentm  ne ) */
     
         %else %if ( &visittm ne ) and ( &exsttm ne )  %then 
         %do;
             select a.*, b.exstdt as _tstdt, b.exsttm as _tsttm,
                         86400*b.exstdt+b.exsttm as _tstdm,
                         b.exendt as pertendt
             from &prefix._ds&i as a left join %unquote(&exposuredset) as b
             on  a.studyid eq b.studyid
             and a.subjid  eq b.subjid
             and ( (a.perstdt lt b.exstdt) or (a.perstdt eq b.exstdt and a.persttm le b.exsttm) )
             and a.perendt gt b.exendt
             and b.exstdt is not null;
         %end; /* ( &visittm ne ) and ( &exsttm ne ) */
     
         %let i = %eval(&i + 1);
      quit;
     
      /* Check for existence of treatment start time */
     
      %if %tu_chkvarsexist(&prefix._ds&i, _TSTTM) ne %then %let _tsttm=;
      %else %let _tsttm=_TSTTM;
     
      %if %tu_chkvarsexist(&prefix._ds&i, PERTENTM) ne %then %let _tsetm=;
      %else %let _tsetm=PERTENTM;
      
      proc sort data=&prefix._ds&i;
         by studyid subjid pernum _tstdt &_tsttm;
      run;
     
      data &prefix._ds%eval(&i+1);
         set &prefix._ds&i;
         by studyid subjid pernum;
     
         drop _tstdt
                %if &_tsttm ne  %then 
                %do;
                    _tsttm _tstdm
                %end;
         ;
     
         retain pertstdt
                %if &_tsttm ne  %then 
                %do;
                    pertsttm pertstdm
                %end;
         ;
     
         format pertstdt pertendt date9.
                %if &_tsttm ne  %then 
                %do;
                    pertsttm time5. pertstdm datetime20.
                %end;
                %if &_tsetm ne  %then 
                %do;
                    pertentm time5. pertendm datetime20.
                %end;               
         ;
         
         label  pertstdt="Date of start of treatment in period"
                pertendt="Date of end of treatment in period"
                %if &_tsttm ne  %then 
                %do;
                    pertsttm="Time of start of treatment in period" 
                    pertstdm="Datetime of start of treatment in period"
                %end;
                %if &_tsetm ne  %then 
                %do;
                    pertentm="Time of end of treatment in period"
                    pertendm="Datetime of end of treatment in period"
                %end;               
         ;
        
     
         if first.pernum then
         do;
            pertstdt = _tstdt;
            %if &_tsttm ne  %then 
            %do;
                pertsttm = _tsttm;
                pertstdm = _tstdm;
            %end;
         end;
     
         if last.pernum then 
         do;
            /* YW001: Set the PERTSTDT to missing if the result from SQL statement has PERTSTDT gt PERENDT. */
            if not missing(pertstdt) then do;
               if %if ( &_tsttm ne ) and ( &visittm ne ) %then 
                  %do;
                   ( pertstdt gt perendt ) or ((pertstdt eq perendt ) and (pertsttm gt perentm))
                  %end;
                  %else %do;
                     pertstdt gt perendt
                  %end;
               then do;
                  pertstdt=.;  
                  pertendt=.;                                       
               end;
            end; /* end-if on pertstdt ne */
            output;
         end; /* end if on last.pernum */
      run;
     
      %let i = %eval(&i + 1);
     
   %end; /* end-if  EXPOSUREDSET parameter has a non-blank value */
   
   /* Create output data set */
   
   data %unquote(&dsetout);
      set &prefix._ds&i;
   run;  
    
   /*
   / Delete temporary datasets used in this macro.
   /----------------------------------------------------------------------------*/
  
%ENDMAC:          

   %tu_tidyup(
       rmdset=&prefix:, 
       glbmac=NONE
       );   

%mend tu_pernum;
 
