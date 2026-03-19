/*******************************************************************************
|
| Macro Name:      tu_acttrt
|
| Macro Version:   3
|
| SAS Version:     8.2
|
| Created By:      Eric Simms / Yongwei Wang
|
| Date:            27-Jan-2005
|
| Macro Purpose:   This unit, for a specified input dataset, shall derive the 
|                  randomized (i.e. intended, not actual) treatment at a 
|                  specified date. It will produce a new dataset with the same 
|                  variables as on the input dataset plus the specified 
|                  variable containing the randomized treatment at the 
|                  specified date 
|
| Macro Design:    Procedure Style
|
|*******************************************************************************
| Input Parameters:
|
| NAME              DESCRIPTION                             REQ/OPT  DEFAULT
| ----------------  --------------------------------------  -------  ----------
| DSETIN            Specifies the dataset for which the     REQ      (Blank)
|                   new variable containing the treatment
|                   is to be added.
|                   Valid values: valid dataset name
|
| DSETOUT           Specifies the name of the output        REQ      (Blank)
|                   dataset to be created.
|                   Valid values: valid dataset name
|
| EXPOSUREDSET      Specifies the Exposure SI dataset which REQ      dmdata.exposure
|                   be used to add treatment information to
|                   the input dataset. For XO studies it 
|                   will be passed to and validated in 
|                   %TU_CALCTPERNUM to find the treatment
|                   period number.
|
| RANDALLDSET       Specifies the RandAll SI dataset which  REQ      dmdata.randall
|                   will be used along with the &RANDDSET 
|                   datasets to add treatment information 
|                   to input data set. It will be passed 
|                   to and validated in %TU_RANTRT
| 
| RANDDSET          Specifies the Rand SI dataset which     REQ      dmdata.rand
|                   will be used along with the  
|                   &RANDALLDSET datasets to add treatment 
|                   information to input data set. It will 
|                   be passed to and validated in 
|                   %TU_RANTRT.
|
| REFDAT            Variable containg the date of           REQ      (Blank)
|                   interest.
|                   Valid values: valid variable name exist 
|                   in &DSETIN
|
| REFTIM            Variable containg the time of           Opt      (Blank)
|                   interest.
|                   Valid values: Blank or valid variable  
|                   name exist in &DSETIN
|
| TMSLICEDSET       Specify the time slice data set name.   Opt      DMDATA.TMSLICE
|                   It is required for crossover study. It 
|                   will be passed to and validated in 
|                   %TU_TIMSLC.
|
| VARNAME           Name of the variable which will         REQ      (Blank)
|                   contain the treatment at that REFDAT.
|
| VISITDSET         Specify the visit data set name. Only   Opt      dmdata.visit
|                   used for XO studies to find the
|                   treatment period number. It will be
|                   passed to and validated in 
|                   %TU_CALCTERNUM.
|
|*******************************************************************************
| Output:
|
| The unit shall create an output dataset (&DSETOUT) from the input dataset 
| (&DSETIN) with an additional variable (&VARNAME) added. This variable will 
| contain the derived actual period treatment at the specified date and time 
| (&REFDAT and &REFTIM) for crossover study, actual treatment for parallel study. 
|
| The macro outputs the following datasets :
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETOUT           Req      Parameter specified dataset
| -----------------  -------  -------------------------------------------------
|
|*******************************************************************************
| Global macro variables created: NONE
|
| Macros called:
|(@) tr_putlocals
|(@) tu_abort        
|(@) tu_chkvarsexist 
|(@) tu_calctpernum 
|(@) tu_putglobals   
|(@) tu_rantrt
|(@) tu_tidyup   
|    
|*******************************************************************************
| Example:
|    %tu_acttrt(
|         dsetin  = _disposit1,
|         dsetout = _disposit2,
|         refdat  = dsdt,
|         reftim  = dswdtm,
|         varname = dsacttrt
|         );
|
|******************************************************************************
| Change Log
|
| Modified By:              Yongwei Wang
| Date of Modification:     27Sep2005
| New version/draft number: 2/1
| Modification ID:          YW001
| Reason For Modification:  Requested by change request HRT0090. Added two
|                           parameter RANDDSET and RANDALLDSET to pass to 
|                           %tu_rantrt
|
| Modified By:              Yongwei Wang
| Date of Modification:     01Mar2007
| New version/draft number: 3/1
| Modification ID:          YW003
| Reason For Modification:  Requested by change request HRT0130. Modified
|                           the process so that actual treatment is based
|                           on PERIOD treatment start time at EXPOSURE data 
|                           set. Previous version based on PERIOD derived from 
|                           time slicing data set
|
| Modified By:              Shan Lee
| Date of Modification:     02Oct2007
| New version/draft number: 3/2
| Modification ID:          SL001
| Reason For Modification:  Allow dataset options to be specified with dataset
|                           name parameters - HRT0184.
|
*******************************************************************************/

%macro tu_acttrt (
    dsetin      = ,      /* Input dataset name */
    dsetout     = ,      /* Output dataset name */
    exposuredset= dmdata.exposure, /* EXPOSURE data set name */
    randalldset = dmdata.randall,  /* RANDALL data set name */
    randdset    = dmdata.rand,     /* RAND data set name */
    refdat      = ,      /* Reference date */
    reftim      = ,      /* Reference time */     
    tmslicedset = dmdata.tmslice, /* time slice data set name */
    varname     = ,      /* Variable name for actual day within period */
    visitdset   = dmdata.visit  /* VISIT data set name */
    );

   /*
   / Echo parameter values and global macro variables to the log.
   /----------------------------------------------------------------------------*/
   
   %local MacroVersion;
   %let MacroVersion = 3 build 2;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals(varsin=g_stype);
   
   /*
   / PARAMETER VALIDATION
   /----------------------------------------------------------------------------*/
   
   %local prefix i listvars loopi thisvar trtvar timevar;
   %let prefix = _acttrt;   /* Root name for temporary work datasets */
   
   /*
   / Initialise counter for appending to temporary dataset names for the
   / purpose of tracking datasets through a number of optional sequential
   / data processing steps.
   /----------------------------------------------------------------------------*/
   
   %let i = 1;
   
   /*
   / Check for required parameters.
   /----------------------------------------------------------------------------*/
  
   %let listvars=DSETIN DSETOUT REFDAT VARNAME EXPOSUREDSET; 
  
   %do loopi=1 %to 5;
      %let thisvar=%scan(&listvars, &loopi, %str( ));
      %let &thisvar=%nrbquote(&&&thisvar);
      
      %if &&&thisvar eq %then
      %do;
         %put %str(RTE)RROR: &sysmacroname: The parameter &thisvar is required.;
         %let g_abort=1;
      %end;    
   %end;  /* end of do-to loop */
   
   /*
   / Check that required dataset exists.
   / Allow dataset options to be specified - SL001.
   /----------------------------------------------------------------------------*/
   
   %if &dsetin ne %then
   %do; 
      %if %sysfunc(exist(%qscan(&dsetin, 1, %str(%()))) eq 0 %then
      %do;
         %put %str(RTE)RROR: &sysmacroname: The dataset(=&dsetin) does not exist.;
         %let g_abort=1;
      %end;  
      %else %do;
         data &prefix._dsetinexist;
            if 0 then set %unquote(&dsetin);
         run;
      %end;
   %end; /* end-if on &dsetin ne */
   
   %if &exposuredset ne %then
   %do; 
      %if %sysfunc(exist(%qscan(&exposuredset, 1, %str(%()))) eq 0 %then
      %do;
         %put %str(RTE)RROR: &sysmacroname: The exposuredset(=&exposuredset) does not exist.;
         %let g_abort=1;
      %end;  
      %else %do;
         data &prefix._exposureexist;
            if 0 then set %unquote(&exposuredset);
         run;
         %if %tu_chkvarsexist(&prefix._exposureexist, subjid) ne %then
         %do;
            %put %str(RTE)RROR: &sysmacroname: SUBJID does not exist in exposuredset(=&exposuredset).;
            %let g_abort=1;
         %end;        
         %if %tu_chkvarsexist(&prefix._exposureexist, STUDYID) ne %then
         %do;
            %put %str(RTE)RROR: &sysmacroname: STUDYID does not exist in exposuredset(=&exposuredset).;
            %let g_abort=1;
         %end;  
         %if %tu_chkvarsexist(&prefix._exposureexist, exstdt) ne %then
         %do;
            %put %str(RTE)RROR: &sysmacroname: EXSTDT does not exist in exposuredset(=&exposuredset).;
            %let g_abort=1;
         %end;     
      %end; /* %if %sysfunc(exist(&exposuredset)) eq 0 */   
   %end; /* end-if on &exposuredset ne */
   
   /*
   / Check that variable REFDAT exists on the input dataset.
   /----------------------------------------------------------------------------*/
   
   %if ( &dsetin ne ) and ( &refdat ne ) %then
   %do;
      %if %tu_chkvarsexist(&prefix._dsetinexist, &refdat) ne %then
      %do;
         %put %str(RTE)RROR: &sysmacroname: Data set DSETIN (=&dsetin) does not contain the variable REFDAT(=&refdat).;
         %let g_abort=1;
      %end;  
   %end; /* end-if on ( &dsetin ne ) and ( &refdat ne ) */
   
   /*
   / Check that variable REFTIM exists on the input dataset.
   /----------------------------------------------------------------------------*/
   
   %if ( &dsetin ne ) and ( &reftim ne ) %then
   %do;    
      %if %tu_chkvarsexist(&prefix._dsetinexist, &reftim) ne %then
      %do;
         %put %str(RTE)RROR: &sysmacroname: Data set DSETIN (=&dsetin) does not contain the variable REFTIM(=&reftim).;
         %let g_abort=1;
      %end;  
   %end; /* end-if on ( &dsetin ne ) and ( &reftim ne ) */
      
   /*
   / Check that new variable to be created does not already exist on the input
   / dataset.
   /----------------------------------------------------------------------------*/
    
   %if ( &dsetin ne ) and ( &varname ne ) %then
   %do;  
      %if %tu_chkvarsexist(&prefix._dsetinexist, &varname) eq %then 
      %do;
         %put %str(RTE)RROR: &sysmacroname: Data set DSETIN (=&dsetin) already has a variable named VARNAME(=&varname).;
         %let g_abort=1;
      %end;  
   %end; /* end-if on ( &dsetin ne ) and ( &varname ne ) */ 
            
   /*
   / If the input dataset name is the same as the output dataset name,
   / write a note to the log.
   / Ignore dataset options when comparing dataset names - SL001.
   /----------------------------------------------------------------------------*/
   
   %if %upcase(%qscan(&dsetin, 1, %str(%())) eq %upcase(%qscan(&dsetout, 1, %str(%())) %then
   %do;
      %put %str(RTN)OTE: TU_ACTTRT: The input dataset name (&dsetin) is the same as the output dataset name (&dsetout).;
   %end;  /* end-if Specified datasets for DSETIN and DSETOUT have same names.  */ 
   
   %if &g_abort eq 1 %then
   %do;
      %tu_abort;
   %end;
   
   /*
   / NORMAL PROCESSING
   /----------------------------------------------------------------------------*/
   
   /*
   / Create a data set with only STUDYID SUBJID &REFDAT &REFTIM from &DSETIN
   /----------------------------------------------------------------------------*/   
   
   proc sort data=%unquote(&dsetin) out=&prefix._ds&i (keep=studyid subjid &refdat &reftim) nodupkey;
      by studyid subjid &refdat &reftim;
   run;          
   
   /*
   / YW003: For crossover study (&G_STYPE=XO), call %tu_calctpernum to get 
   /        treatment period number (period based on treatment in &EXPOSUREDSET
   /----------------------------------------------------------------------------*/
  
   %if %qupcase(&g_stype) eq XO %then
   %do;
      %tu_calctpernum (
         DSETIN              =&prefix._ds&i,
         DSETOUT             =&prefix._ds%eval(&i + 1),
         EXPOSUREDSET        =&exposuredset,
         REFDAT              =&refdat,
         REFTIM              =&reftim,
         TMSLICEDSET         =&tmslicedset,
         VISITDSET           =&visitdset
         );   
         
      %let i=%eval(&i + 1);
      
      data &prefix._ds%eval(&i + 1);
         set &prefix._ds&i (keep = studyid subjid &refdat. &reftim. tpernum);
         rename tpernum=pernum;
      run;         
      
      %let i=%eval(&i + 1);         
   %end; /* end-if on &g_stype eq XO */
  
   /*
   / Call %TU_RANTRT to add treatment variables to data set created above
   /----------------------------------------------------------------------------*/
         
   %tu_rantrt (
      dsetin      = &prefix._ds&i,
      dsetout     = &prefix._ds%eval(&i+1) ,     
      randalldset = &randalldset, 
      randdset    = &randdset,  
      trtcdinf    = ,
      ptrtcdinf   = 
      );
      
   %let i = %eval(&i + 1);
 
   %if %qupcase(&g_stype) eq XO %then
   %do;
      %let trtvar=PATRTGRP;
   %end;
   %else %do;
      %let trtvar=ATRTGRP;
   %end;
   
   /*
   / If PATRTGRP (for crossover study) or ATRTGRP is not added by %TU_RTNTRT, 
   / write a RTWARNING to the log and go to last step
   /----------------------------------------------------------------------------*/
   %if %tu_chkvarsexist(&prefix._ds&i, &trtvar) ne %then
   %do;    
      %put %str(RTW)ARNING: &sysmacroname: TU_RANTRT did not add &trtvar in. Variable &VARNAME can not be added.;
      
      data %unquote(&dsetout);
         set %unquote(&dsetin);
      run; 
   %end;
   %else %do;
   
   /*
   / YW003: For parallel study, if &refdat/&reftim is before treatment, set    
   / &trtvar to missing. 
   /----------------------------------------------------------------------------*/
   
      %if %qupcase(&g_stype) ne XO %then
      %do;
         %if %tu_chkvarsexist(&prefix._exposureexist, exsttm) ne %then %let timevar=;
         %else %let timevar=exsttm;
         %if %nrbquote(&reftim) eq %then %let timevar=;

         /*
         / Apply keep option to output dataset, to avoid conflict if dataset
         / options have been specified for EXPOSUREDSET. SL001
         /----------------------------------------------------------------------*/
         
         proc sort data=%unquote(&exposuredset) out=&prefix._expo (keep=studyid subjid exstdt &timevar) nodupkey;
            by studyid subjid exstdt &timevar;
            where not missing(exstdt);
         run;   
         
         data &prefix._expo;
            set &prefix._expo;
            by studyid subjid exstdt &timevar;
            if first.subjid;
         run;
         
         proc sql noprint;
            create table &prefix._ds%eval(&i + 1) as (
            select a.*, b.exstdt,
               case 
                  when missing(b.exstdt) or
                  %if %nrbquote(&timevar) ne %then
                  %do;
                     (( a.&refdat lt b.exstdt ) or (( a.&refdat eq b.exstdt ) and ( a.&reftim lt b.exsttm )) )
                  %end;
                  %else %do;
                     (a.&refdat lt b.exstdt)
                  %end;
                     then ''
                     else a.trtgrp
               end
               as newatrtgrp
            from &prefix._ds&i as a left join &prefix._expo as b
            on   a.studyid=b.studyid
            and  a.subjid=b.subjid
            );
         quit;

         %let trtvar=newatrtgrp;
         %let i = %eval(&i + 1);    
              
      %end; /* %if %qupcase(&g_stype) ne XO */
       
   /* 
   / Rename PATRTGRP for crossover study or ATRTGRP for parallel study to &VARNAME
   /  Merge &VARNAME into &DSETIN by STUDYID SUBJID &REFDAT &REFTIM
   /----------------------------------------------------------------------------*/
      
      proc sort data=&prefix._ds&i(keep=studyid subjid &refdat &reftim &trtvar)
                out=&prefix._ds%eval(&i+1) (rename=(&trtvar=&varname)) nodupkey;
         by studyid subjid &refdat &reftim;
      run;
      
      %let i = %eval(&i + 1);
      
      proc sort data=%unquote(&dsetin) out=&prefix._dsin;
         by studyid subjid &refdat &reftim;
      run;
         
      data %unquote(&dsetout);
         merge &prefix._dsin (in=__in__)
               &prefix._ds&i;
         by studyid subjid &refdat &reftim;
         if __in__;
      run;
      
   %end; /* end-if on &trtvar does not exist */
      
   /*
   /  Call %tu_tidyup to delete local data sets.
   /----------------------------------------------------------------------------*/
         
   %tu_tidyup(
      rmdset=&prefix:, 
      glbmac=NONE
      );

%mend tu_acttrt;

