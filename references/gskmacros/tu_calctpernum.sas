/*---------------------------------------------------------------------------------------+ 
| Macro Name    : tu_calctpernum.sas                                             
|
| Macro Version : 2 build 1
|                                                                            
| SAS version   : SAS v8.2                                                   
|                                                                            
| Created By    : Yongwei Wang                                                          
|                                                                         
| Date          : Sep 2005
|                                                                            
| Macro Purpose : This macro, for a specified input dataset, shall derive:Treatment period 
|                 (TPERIOD) and treatment period number (TPERNUM). It derives TPERIOD and 
|                 TPERNUM for time point of interest by comparing the date and time of the 
|                 time point with period treatment start date and time in derived period 
|                 data set
|                                                                            
| Macro Design  : PROCEDURE STYLE   
|   
| Name                Description                                       Default           
| ----------------------------------------------------------------------------------------
| DSETIN              Specifies the dataset for which the new           (Blank)           
|                     variables containing treatment period are to be                     
|                     added.                                                              
|                     Valid values: valid dataset name                                    
|                                                                                         
| DSETOUT             Specifies the name of the output dataset to be    (Blank)            
|                     created.                                                            
|                     Valid values: valid dataset name                                    
|                                                                                         
| EXPOSUREDSET        Specifies the EXPOSURE SI dataset which will be   dmdata.exposure   
|                     passed to %tu_pernum along with the TMSLICEDSET                     
|                     and VISITDSET datasets to produce a PERIOD A&R                      
|                     dataset.                                                            
|                     Valid values: valid dataset name                                    
|                                                                                         
| REFDAT              Variable containing the date of interest. Will    (Blank)           
|                     be used along with REFTIM to compare with the                       
|                     treatment start date to get the treatment period                    
|                     Valid values: Name of a SAS variable that exists                    
|                     in &DSETIN                                                          
|                                                                                         
| REFTIM              Variable containing the time of interest. Will    (Blank)           
|                     be used along with REFDAT to compare with the                       
|                     treatment start time to get the treatment period                    
|                     Valid values: Blank or Name of a SAS variable                       
|                     that exists in &DSETIN                                              
|                                                                                         
| TMSLICEDSET         Specifies the TMSLICE SI dataset which will be    dmdata.tmslice    
|                     passed to %tu_pernum along with the EXPOSUREDSET                    
|                     and VISITDSET datasets to produce a PERIOD A&R                      
|                     dataset.                                                            
|                     Valid values: valid dataset name                                    
|                                                                                         
| VISITDSET           Specifies the VISIT SI dataset which will be      dmdata.visit      
|                     passed to %tu_pernum along with the EXPOSUREDSET                    
|                     and TMSLICEDSET datasets to produce a PERIOD A&R                    
|                     dataset.                                                            
|                     Valid values: valid dataset name                                    
|-----------------------------------------------------------------------------------------
|
| Output:   The unit shall create an output dataset with added variables TPERNUM 
|           ("Treatment Period Number"), TPERIOD ("Treatment Period") 
|
| Global macro variables created: None                                            
|                                                                                                                                                     
| Macros called : 
| (@) tr_putlocals
| (@) tu_abort       
| (@) tu_chkvarsexist
| (@) tu_pernum      
| (@) tu_putglobals  
| (@) tu_tidyup      
|----------------------------------------------------------------------------------------
| Change Log :                                                               
|
| Modified By :             Shan Lee                     
| Date of Modification :    09 Feb 2006                    
| New Version Number :      1/2            
| Modification ID :         n/a              
| Reason For Modification : In the "Macros called", specified above, remove the ".sas" 
|                           at the end of "tr_putlocals.sas" and remove the "%" signs
|                           that prefix the macro names: these cause a problem when
|                           attempting to check the macro into the HARP Application.                
|
| Modified By :             Shan Lee                     
| Date of Modification :    17 Sep 2007
| New Version Number :      2 build 1
| Modification ID :         SL001
| Reason For Modification : Allow dataset options to be specified for input and output
|                           datasets - HRT0184
|---------------------------------------------------------------------------------------*/

%macro tu_calctpernum (
   DSETIN              =,                  /* Input dataset name */                                                                                                                                                                                          
   DSETOUT             =,                  /* Output dataset name */                                                                                                                                                                                         
   EXPOSUREDSET        =dmdata.exposure,   /* Exposure dataset name */                                                                                                                                                                                       
   REFDAT              =,                  /* Variable name for reference date */                                                                                                                                                                            
   REFTIM              =,                  /* Variable name for reference time */                                                                                                                                                                            
   TMSLICEDSET         =dmdata.tmslice,    /* Time slice dataset name */                                                                                                                                                                                     
   VISITDSET           =dmdata.visit       /* Visit dataset name */    
   );

   /*
   / Echo parameter values and global macro variables to the log.
   /----------------------------------------------------------------------------*/
  
   %local MacroVersion;
   %let MacroVersion = 2 build 1;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals() 

   /*
   / PARAMETER VALIDATION
   /----------------------------------------------------------------------------*/
   
   %local period pernum pertstdt pertsttm tpernum tperiod dset prefix i thisvar listvars;   
   
   %let prefix = _calctpernum;   /* Root name for temporary work datasets */   
   
   /*
   / Initialise counter for appending to temporary dataset names for the
   / purpose of tracking datasets through a number of optional sequential
   / data processing steps.
   /----------------------------------------------------------------------------*/
   
   %let i = 1;   

   %let dset=%unquote(&dsetin);
   
   /*
   / Check for required parameters.
   /----------------------------------------------------------------------------*/
  
   %let listvars=DSETIN DSETOUT REFDAT EXPOSUREDSET VISITDSET TMSLICEDSET;
  
   %do loopi=1 %to 6;
      %let thisvar=%scan(&listvars, &loopi, %str( ));
      %let &thisvar=%nrbquote(&&&thisvar);
      
      %if &&&thisvar eq %then
      %do;
         %put %str(RTE)RROR: &sysmacroname: Parameter &thisvar is blank.;
         %let g_abort=1;
      %end;    
   %end;  /* end of do-to loop */
   
   /*
   / Check that required datasets exist.
   / Allow dataset names to include dataset options. SL001
   /----------------------------------------------------------------------------*/
   
   %let listvars=DSETIN EXPOSUREDSET VISITDSET TMSLICEDSET;
  
   %do loopi=1 %to 4;
      %let thisvar=%scan(&listvars, &loopi, %str( ));
      
      %if &&&thisvar ne %then
      %do;
         %if %sysfunc(exist(%qscan(&&&thisvar, 1, %str(%()))) eq 0 %then
         %do;
            %put %str(RTE)RROR: &sysmacroname: Dataset &thisvar(=&&&thisvar) does not exist.;
            %let g_abort=1;
         %end;  
      %end; /* &&&thisvar ne */
   %end;  /* end of do-to loop */
   
   %if &g_abort eq 1 %then
   %do;
      %tu_abort;
   %end;    
   
   /*
   / Check that variable &REFDAT, and &REFTIM if specified, exists on the input 
   / dataset.
   /----------------------------------------------------------------------------*/
   
   %if %length(&dsetin) gt 0 %then
   %do;
      data &prefix._dsetinexist;
         if 0 then set %unquote(&dsetin);
      run;
      %if ( &refdat ne ) %then 
      %do;
         %if %tu_chkvarsexist(&prefix._dsetinexist, &refdat) ne %then
         %do;
            %put %str(RTE)RROR: &sysmacroname: Variable REFDAT(=&refdat) does not exist in DSETIN=(&dsetin).;
            %let g_abort=1;
         %end;  
      %end; /* ( &refdat ne ) */
      
      %if ( &reftim ne ) %then 
      %do;
         %if %tu_chkvarsexist(&prefix._dsetinexist, &reftim) ne %then
         %do;
            %put %str(RTE)RROR: &sysmacroname: Variable REFTIM(=&reftim) does not exist in DSETIN=(&dsetin).;
            %let g_abort=1;
         %end;  
      %end; /* ( &reftim ne ) */           
   %end; /* ( %length(&dsetin) gt 0 ) */
         
   /*
   / If the input dataset name is the same as the output dataset name,
   / write a note to the log.
   / Ignore dataset options when comparing DSETIN and DSETOUT. SL001
   /----------------------------------------------------------------------------*/

   %if %upcase(%qscan(&dsetin, 1, %str(%())) eq %upcase(%qscan(&dsetout, 1, %str(%())) %then
   %do;
     %put %str(RTN)OTE: &sysmacroname: The input dataset name (&dsetin) is the same as the output dataset name (&dsetout).;
   %end;

   %if &g_abort eq 1 %then
   %do;
      %tu_abort;
   %end;   
   
   /*
   / NORMAL PROCESSING
   /----------------------------------------------------------------------------*/
   
   /*
   / Call %tu_pernum to create period data set to get period treatment start 
   / date and time for each period
   /----------------------------------------------------------------------------*/
   
   %tu_pernum (
      dsetout       = &prefix._ds&i,
      exposuredset  = %unquote(&exposuredset),
      tmslicedset   = %unquote(&tmslicedset),
      visitdset     = %unquote(&visitdset)
      );
      
   /*
   / If PERIOD data was not created, write a warning message to the log,
   / set &dsetin to &dsetout and exit
   /----------------------------------------------------------------------------*/
                
   %if %sysfunc(exist(&prefix._ds&i)) eq 0 %then 
   %do;   
      %put %str(RTW)ARNING: &sysmacroname: Period information was not added by %nrstr(%TU_PERNUM). TPERNUM/TPERIOD can not be added;      
      data %unquote(&dsetout);
         set %unquote(&dsetin);
      run;
      %goto endmac;  
   %end;
   
   /*
   / Call %tu_chkvarsexist to check if PERIOD, PERNUM, PERTSTDT and PERTSTTM
   / are in derived PERIOD data set. If PERNUM/PERIOD or PERTSTDT is not in 
   / derived PERIOD data set, write a warning message to the log, set &dsetin 
   / to &dsetout and exit
   /----------------------------------------------------------------------------*/
    
   %if %tu_chkvarsexist(&prefix._ds&i, period)   eq %then 
   %do;
      %let period=period;
      %let tperiod=tperiod;
   %end;
   %if %tu_chkvarsexist(&prefix._ds&i, pernum)   eq %then 
   %do;
      %let pernum=pernum;
      %let tpernum=tpernum;
   %end;
   %if %tu_chkvarsexist(&prefix._ds&i, pertstdt) eq %then %let pertstdt=pertstdt;
   %if %tu_chkvarsexist(&prefix._ds&i, pertsttm) eq %then %let pertsttm=pertsttm;   
   
   %if ( %nrbquote(&period.&pernum) eq ) %then
   %do;
      %put %str(RTW)ARNING: &sysmacroname: Neither PERNUM nor PERIOD is derived by %nrstr(%tu_pernum). TPERNUM/TPERIOD can not be added;
      data %unquote(&dsetout);
         set %unquote(&dsetin);
      run;
      %goto endmac;
   %end;
   
    %if ( %nrbquote(&pertstdt) eq ) %then
   %do;
      %put %str(RTW)ARNING: &sysmacroname: PERTSTDT is not derived by %nrstr(%tu_pernum). TPERNUM/TPERIOD can not be added;
      data %unquote(&dsetout);
         set %unquote(&dsetin);
      run;
      %goto endmac;
   %end;  
   
   /*
   / Sort period data set by studyid subjid period pernum pertstdt pertsttm;
   / Rename pernum to tpernum, period to tperiod; Remove records with missing
   / pertstdt.
   /----------------------------------------------------------------------------*/
  
   proc sort data=&prefix._ds&i nodupkey
        out=&prefix._ds%eval(&i + 1) (keep=studyid subjid &period &pernum &pertstdt &pertsttm
        rename=(
           %if %nrbquote(&pernum) ne %then &pernum=&tpernum;
           %if %nrbquote(&period) ne %then &period=&tperiod; )
        );
      by studyid subjid descending &pertstdt %if %nrbquote(&pertsttm) ne %then descending &pertsttm; ;
      where not missing(&pertstdt);
   run; 
   
   %let i=%eval(&i + 1);
     
   /*
   / For each subject, add pertstdt and pertsttm for next period and name them 
   / as _hidt and _hitm; for last period, Add 10000 to currert &pertstdt; for 
   / date before first period, set _hidt and _hitm to current pertstdt and 
   / pertstm, set _hitm and _hidt to missing, set tpernum to 0, and set tperiod
   / to 'Pre-Treatment
   /----------------------------------------------------------------------------*/
  
   data &prefix._ds%eval(&i + 1);
      set &prefix._ds&i;
      by studyid subjid descending &pertstdt %if %nrbquote(&pertsttm) ne %then descending &pertsttm; ;      
      _hitm=.;
      _hidt=lag(&pertstdt);
      %if %nrbquote(&pertsttm) ne %then _hitm=lag(&pertsttm); ;
      
      if first.subjid then
      do;
         _hidt=&pertstdt +100000;
      end;

      output;
      
      if last.subjid then 
      do;
         _hidt=&pertstdt;
         &pertstdt=.;
         
         %if %nrbquote(&pertsttm) ne %then 
         %do;
            _hitm=&pertsttm;
            &pertsttm=.;
         %end;
         
         %if %nrbquote(&tpernum) ne %then
         %do;
            &tpernum=0;        
         %end;
         %if %nrbquote(&tperiod) ne %then
         %do;
            &tperiod="Pre-Treatment";        
         %end;     
         output;    
      end; /* last.subject */           
   run;
   
   %let i=%eval(&i + 1);
  
   /*
   / If &REFTIM is not blank and &PTRTSTTM exists in period dataset, and if 
   / &REFTIM is missing in &DSETIN, set it to the nearest &PERTSTTM with 
   / &REFTIM=PERTSTDT, which is in period dataset, for each subject
   /----------------------------------------------------------------------------*/
     
   %if ( %nrbquote(&reftim) ne ) and ( %nrbquote(&pertsttm) ne ) %then
   %do;
      proc sort data=&prefix._ds&i out=&prefix._dsprd(keep=studyid subjid &pertstdt &pertsttm) nodupkey;
         by studyid subjid &pertstdt;
      run;
      
      proc sort data=&dset out=&prefix._tim (keep=studyid subjid &refdat &reftim) nodupkey;
         by studyid subjid &refdat;
         where missing(&reftim);
      run;
      
      proc sql noprint;
         create table &prefix._tim2 as
         select a.*, b.&pertsttm as _reftm
         from &prefix._tim as a, &prefix._dsprd as b 
         where a.studyid=b.studyid
           and a.subjid=b.subjid
           and a.&refdat=b.&pertstdt
         order by studyid, subjid, &refdat, &reftim
         ;                  
      quit;
      
      proc sort data=&dset out=&prefix._dset1;
         by studyid subjid &refdat &reftim;
      run;
      
      data &prefix._dset2;
         merge &prefix._dset1(in=__in1__)
               &prefix._tim2(in=__in2__);
         by studyid subjid &refdat &reftim;
         if __in1__;
         if not missing(&reftim) then _reftm=&reftim;
      run;
      
      %let reftim=_reftm;
      %let dset=&prefix._dset2;
   %end; /* ( %nrbquote(&reftim) ne ) and ( %nrbquote(&pertsttm) ne ) */
   
   /*
   / Create output data set by merging TPERNUM/TPERIOD in PERIOD data set into 
   / input data set where &REFDAT/&REFTIM is between PERTSTDT/PERTSTTM of current 
   / period and of next period, for each subject
   /----------------------------------------------------------------------------*/
   
   proc sql noprint;
      create table &prefix._ds%eval(&i + 1)  
         %if &reftim eq _reftm %then (drop=_reftm);
      as
      select a.* 
             %if %nrbquote(&tpernum) ne %then ,b.&tpernum ;
             %if %nrbquote(&tperiod) ne %then ,b.&tperiod ;
      from   &dset as a left join &prefix._ds&i as b
      on     a.studyid eq b.studyid
      and    a.subjid  eq b.subjid

      %if ( %nrbquote(&reftim) eq ) or ( %nrbquote(&pertsttm) eq ) %then
      %do;
         and a.&refdat lt b._hidt
         and a.&refdat ge b.pertstdt 
      %end; 

      %else %do;
         and ( (a.&refdat lt b._hidt)     or (a.&refdat eq b._hidt     and a.&reftim lt b._hitm) )
         and ( (a.&refdat gt b.&pertstdt) or (a.&refdat eq b.&pertstdt and a.&reftim ge b.&pertsttm) )
      %end; 
      ;
   quit;     
   
   %let i=%eval(&i + 1);
        
   data %unquote(&dsetout);
      set &prefix._ds&i;
      if missing(&refdat) then
      do;
         %if %nrbquote(&tpernum) ne %then
         %do;
            &tpernum=.;        
         %end;
         %if %nrbquote(&tperiod) ne %then
         %do;
            &tperiod="";        
         %end; 
      end;      
   run;
                                
%ENDMAC: 

   /*
   / Delete temporary datasets used in this macro.      
   /----------------------------------------------------------------------------*/
   %tu_tidyup(
      rmdset=&prefix:, 
      glbmac=NONE
      );

%mend tu_calctpernum;

