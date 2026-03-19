/****************************************************************************************************
|
| Macro Name:      tu_p1_mean
|
| SAS Version:     9.1.3
|
| Created By:      Andy Miskell
|
| Date:            March 11, 2009
|
| Macro Purpose:   To mean observations for replicate values
|
| Macro Design:    Procedure Style
|
| ------------------------------------------------------------------
| ------------------------------------------------------------------
|                 FOR MORE DETAILS ABOUT INPUT PARAMETERS, REFER TO
|                 DOCUMENTATION FOR TU_P1_MEAN
| ------------------------------------------------------------------
| ------------------------------------------------------------------
|
| meangrp1 (as well as meangrp2)     syntax - for each group of variables to mean, state the values
|   of what to mean in where-clause syntax (i.e. ptmnum=xxx and visitnum=xxx).  
| 
|  meangrpval1 (as well as meangrpval2)       syntax - put the new values that the mean observation should have
|   in SAS statement syntax (i.e. ptmnum=xxx; visitnum=xxx;).
|
| Notes:
|
| 1) If you call tu_p1_mean before the tc_xxx macro and your mean observations have 
|    different visitnum/ptmnum/tptrefn, then those will not be merged with timeslicing 
|    if timeslicingyn=Y.
| 2) This macro will create extra observations for each mean of a replicate set of observations.
|    A new variable (atype) will be created.  For observations that hold the original data,
|    atype='Listing';.  For observations that hold the means of the original data,
|    atype='Summary';.  For observations that hold other data not being meaned and not
|    holding the mean, atype='Both';.  This variable can be subsetted on in the displays.
|
| Global macro variables created: NONE
|
| Macros called:
|
|(@) tu_chkvarsexist
|(@) tu_putglobals
|(@) tu_valparms
|(@) tu_tidyup
|(@) tu_abort
|
| Example
|
|      %tu_p1_mean(dsetin=tempecg1,
|      dsetout=tempecg2,
|      meanbyvars=visitnum,
|      meangrp1 =ptmnum in (10, 20),
|      meangrpval1=ptmnum=15; ptm='New Screening';,
|      meangrp2=ptmnum in (80, 90) and visitnum=110,
|      meangrpval2=ptmnum=85; ptm='New Pre-dose';,
|      varstomean=eghr pr qrs qtc qt,
|      varstomiss=egacttm egintpcd egleadcd);
|
|****************************************************************************************************
| Change Log 
|
| Modified By: 
| Date of Modification: 
| New Version/Build Number:
| Modification ID: 
| Reason For Modification: 
|
****************************************************************************************************/

%macro tu_p1_mean (
  dsetin=,           /* Input dataset name */  
  dsetout=,          /* Output dataset name */ 
  meanbyvars=,       /* By variables e.g. visitnum visit ;  exclude SUBJID from list */                                                                                                                                   
  meangrp1=,         /* Values of first group of observations to mean using where-clause syntax */                                                                                                                        
  meangrpval1=,      /* Assignment statements to identify the new observation holding the mean value created from meangrp1 e.g. ptmnum=25; ptm='Mean Pre-dose'; */                                                        
  meangrp2=,         /* Values of second group of observations to mean in where-clause syntax */                                                                                                                          
  meangrpval2=,      /* Assignment statements to identify the new observation holding the mean value created from meangrp2 e.g. ptmnum=15; ptm='Mean Screening'; */                                                       
  varstomean=,       /* Variables to calculate means e.g. eghr pr qrs */                                                                                                                                                  
  varstomiss=        /* Variables to set to missing for the mean observation e.g. egacttm egintpcd egleadcd */                                                                                                            
   );
   
  /*
  / Echo parameter values and global macro variables to the log
  /----------------------------------------------------------------------------*/
  %local MacroVersion MacroName;
  %let MacroName=&sysmacroname.;
  %let MacroVersion=1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals();

  /*
  / Parameter validation
  /----------------------------------------------------------------------------*/
  %let dsetin              = %nrbquote(&dsetin.);
  %let dsetout             = %nrbquote(&dsetout.);
  %let meanbyvars          = %nrbquote(&meanbyvars.);
  %let meangrp1            = %nrbquote(&meangrp1.);
  %let meangrpval1         = %nrbquote(&meangrpval1.);
  %let meangrp2            = %nrbquote(&meangrp2.);
  %let meangrpval2         = %nrbquote(&meangrpval2.);
  %let varstomean          = %nrbquote(&varstomean.);
  %let varstomiss          = %nrbquote(&varstomiss.);


  /*
  / Check for valid parameter values
  /   set up a macro variable to hold the pv_abort flag
  /----------------------------------------------------------------------------*/
  %local loopi listvars thisvar
         prefix pv_abort abortyn chkdata;
  %let prefix = _tu_p1_mean ;   /* Root name for temporary work datasets */
  %let pv_abort = 0 ;

  /*
  / Check for required parameters.
  /----------------------------------------------------------------------------*/
  %let listvars=dsetin dsetout meangrp1 meangrpval1 varstomean;

  %do loopi=1 %to 5;
    %let thisvar=%scan(&listvars, &loopi, %str( ));
    %let &thisvar=%nrbquote(&&&thisvar);
    
    %if &&&thisvar eq %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: The parameter &thisvar cannot be blank.;
       %let pv_abort=1;
    %end;    
  %end;  /* end of do-to loop */

  /*
  / Validation of dataset
  /   Check existence of datasets and variables
  /----------------------------------------------------------------------------*/
  /* dsetin exists? ;*/
  %tu_valparms(
     macroname = tu_p1_mean,
     chktype   = dsetExists,
     pv_dsetin = dsetin
     );

  %if %length(%tu_chkvarsexist(&dsetin, subjid)) gt 0 %then 
  %do;
    %put RTE%str(RROR): &sysmacroname.: &dsetin dataset does not contain the variable SUBJID;
    %let pv_abort=1;
  %end;

  %if &meanbyvars^= %then %do;

    %if %length(%tu_chkvarsexist(&dsetin, &meanbyvars)) gt 0 %then 
    %do;
      %put RTE%str(RROR): &sysmacroname.: &dsetin dataset does not contain a variable specified in meanbyvars parameter call;
      %let pv_abort=1;
    %end;
  %end;

  %if %length(%tu_chkvarsexist(&dsetin, &varstomean &varstomiss)) gt 0 %then 
  %do;
    %put RTE%str(RROR): &sysmacroname.: &dsetin dataset does not contain a variable specified in varstomean or varstomiss parameter calls;
    %let pv_abort=1;
  %end;


  %if &meangrp2^= %then %do;
    %if &meangrpval2= %then %do;
      %put RTE%str(RROR): &sysmacroname.: If meangrp2 is populated, then meangrpval2 must be populated in tu_p1_mean call;
      %let pv_abort=1;
    %end;
  %end;
  %if &meangrpval2^= %then %do;
    %if &meangrp2= %then %do;
      %put RTE%str(RROR): &sysmacroname.: If meangrpval2 is populated, then meangrp2 must be populated in tu_p1_mean call;
      %let pv_abort=1;
    %end;
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

  data &prefix._origdset;
    set &dsetin;
  run;

  %local macone mactwo;

  /*
  / Call macro meanit separately for group 1 observations and group 2 observations
  /----------------------------------------------------------------------------*/

  %macro meanit(whichobs=);

    /*
    /  Determine if this call is for first or second group of observations 
    /----------------------------------------------------------------------------*/

    %if &whichobs=first %then %do;
      %let macone=&meangrp1;
      %let mactwo=&meangrpval1;
    %end;
    %if &whichobs=second %then %do;
      %let macone=&meangrp2;
      %let mactwo=&meangrpval2;
    %end;

    %let macone          = %nrbquote(&macone.);
    %let mactwo          = %nrbquote(&mactwo.);

    /*
    / Separate input dataset into observations that will be meaned and observations that will not be meaned
    /----------------------------------------------------------------------------*/

    data &prefix._tempdset &prefix._origdset;
      set &prefix._origdset;
      if %unquote(&macone) then output &prefix._tempdset;
      else output &prefix._origdset;
    run;

    /*
    / Check to ensure that subsetting grabbed at least one observation 
    /----------------------------------------------------------------------------*/

    proc contents data=&prefix._tempdset out=&prefix._tempdsetcont noprint;
    run;

    %let chkdata=N;

    data &prefix._tempdsetcont;
      set &prefix._tempdsetcont;
      if _n_=1 and nobs=0 then do;
        call symput('chkdata', 'Y');
      end;
    run;

    %if &chkdata=Y %then %do;
        %put RTE%str(RROR): &MacroName.: If populated, meangrp1 and meangrp2 must contain a valid subset of the dataset;
        %tu_abort(option=force);
    %end;

    /* 
    / Sort and average group of observations
    /----------------------------------------------------------------------------*/

    proc sort data=&prefix._tempdset;
      by subjid &meanbyvars;
    run;

    proc univariate data=&prefix._tempdset noprint;
      by subjid &meanbyvars;
      var &varstomean;
      output out=&prefix._tempdset1 mean=&varstomean;
    run;

    /* 
    / Merge averaged observations with all other variables on the dataset
    / TEMPVARZ variable created so that it can be dropped in the next data step.
    / If VARSTOMISS is not populated, then a variable will be needed in the drop
    / statement to prevent an SAS log er(ror) from occuring.
    /----------------------------------------------------------------------------*/

    proc sort data=&prefix._tempdset out=&prefix._dumdset (drop=&varstomean) nodupkey;
      by subjid &meanbyvars;
    run;

    data &prefix._tempdset2;
      merge &prefix._tempdset1 &prefix._dumdset;
      by subjid &meanbyvars;
      tempvarz=.;
    run;

    /*
    / Set ATYPE variable for averaged observations and original observations from before averaging 
    / Also drop varstomiss from averaged observations so when they are set with the rest of the dataset 
    /* those variables will be missing 
    /----------------------------------------------------------------------------*/

    data &prefix._tempdset2 (drop=tempvarz &varstomiss);
      set &prefix._tempdset2;
      length atype $ 7;
      atype = 'Summary';
      %unquote(&mactwo);
    run;

    data &prefix._tempdset;
      set &prefix._tempdset;
      length atype $ 7;
      atype='Listing';
    run;

    /*
    / Set pre-averaged and post-averaged observations together
    /----------------------------------------------------------------------------*/

    data &prefix._tempdset3;
      set &prefix._tempdset2 &prefix._tempdset;
    run;

    /*
    / Set the observations that were not meaned at all with observations that were meaned and their averaged observations
    /----------------------------------------------------------------------------*/

    data &prefix._origdset;
      set &prefix._tempdset3 &prefix._origdset;
    run;

  %mend meanit;

  /*
  / Call meanit macro for each group of observations to be meaned
  /----------------------------------------------------------------------------*/

  %if &meangrp1^= %then %do;
    %meanit(whichobs=first);
  %end;
  %if &meangrp2^= %then %do;
    %meanit(whichobs=second);
  %end;

  %put chkdata=  &chkdata ;

  /*
  / Set ATYPE for observations that were not meaned at all
  /----------------------------------------------------------------------------*/

  data &dsetout;
    set &prefix._origdset;
    if atype='' then atype = 'Both';
  run;

  /*
  / Delete temporary datasets used in this macro.
  /----------------------------------------------------------------------------*/

  %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tu_p1_mean;

