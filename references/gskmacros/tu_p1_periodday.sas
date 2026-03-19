/*******************************************************************************
|
| Macro Name:      tu_p1_periodday
|
| SAS Version:     9.1
|
| Created By:      Barry Ashby
|
| Date:            25 Feb 2008
|
| Macro Purpose:   Creates Period Day variable
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                            REQ/OPT  DEFAULT
| -----------------  -------------------------------------  -------  ----------
| DSETIN             Specifies the input dataset.           REQ      <blank>
|                    Valid Values: An existing SAS dataset
|
| DSETOUT            Specifies the output dataset.          REQ      <blank>
|                    Valid Values: A valid SAS dataset name
|
| REFDATE            Specifies the Reference date variable  REQ      <blank>
|                    on the input dataset.
|                    Valid Values: A variable on the input
|                    dataset.
|
| EVENTTYPE          Specifies whether the event is planned REQ      <blank>
|                    or spontaneous. 
|                    Valid Values: Either SP or PL
|
| VAROUT             Specifies the variable name given to   REQ      <blank>
|                    the period day variable created, which
|                    is the Treatment Period Day.
|
| EXPOSUREDSET       Specifies the variable name given to   REQ      DMDATA.EXPOSURE
|                    the study EXPOSURE dataset             
|
| TMSLICEDSET        Specifies the variable name given to   REQ      DMDATA.TMSLICE
|                    the study TMSLICE dataset             
|
| The macro references the following datasets :-
| ------------------  -------  ------------------------------------------------
| Name                Req/Opt  Description
| ------------------  -------  ------------------------------------------------
| &DSETIN             Req      Parameter sepcified input dataset
|
| Output:
|
| The macro outputs the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETOUT           Req      Parameter specified output dataset
| -----------------  -------  -------------------------------------------------
|
| Global macro variables created: NONE
|
| Macros called:
|(@) tu_abort
|(@) tu_chkvarsexist
|(@) tu_nobs
|(@) tr_putlocals
|(@) tu_putglobals
|(@) tu_tidyup
|
| Example: %tu_p1_periodday(dsetin    = ae,   
|                           dsetout   = ardata.ae,    
|                           refdate   = aestdt,    
|                           eventtype = SP,    
|                           varout    = tperdy,
|                           exposuredset   = dmdata.exposure
|                           tmslicedset    = dmdata.tmslice);
|
|******************************************************************************
| Change Log
|
| Modified By:              Khilit Shah (kys41925)
| Date of Modification:     20-Oct-2008
| New version/draft number: 2
| Modification ID:          n/a
| Reason For Modification:  1  Pass DMDATA.EXPOSURE and DMDATA.TMSLICE as macro
|                                parameters instead of this being hardcoded
|                           2  Include in the merge statements, a conditional 
|                                merge with variable TPTREFN/PTMNUM if it exists. 
|
| Modified By:              
| Date of Modification:     
| New version/draft number: 
| Modification ID:          
| Reason For Modification:  
*******************************************************************************/

%macro tu_p1_periodday (
   dsetin         =,                 /* Input dataset                                    */
   dsetout        =,                 /* Output dataset                                   */
   refdate        =,                 /* Reference date variable on input dataset         */
   eventtype      =,                 /* Specifies if the event is planned or spontaneous */
   varout         =,                 /* Name of Period Day variable created              */
   exposuredset   = dmdata.exposure, /* Name of EXPOSURE dataset to use */    
   tmslicedset    = dmdata.tmslice   /* Name of TMSLICE dataset to use  */    
   );

   /*
   / Echo parameter values and global macro variables to the log.
   /----------------------------------------------------------------------------*/
   %local MacroVersion;
   %let MacroVersion=2 ;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals();
  
   %local prefix macroname l_pernum bylist;

   %let macroname = &sysmacroname.;
   %let prefix = _tu_p1_periodday;         /* Root name for temporary work datasets */
  
   /*
   / PARAMETER VALIDATION
   /----------------------------------------------------------------------------*/
   
   /*
   / Check for required parameters.
   /----------------------------------------------------------------------------*/
  
   %let listvars=DSETIN DSETOUT REFDATE EVENTTYPE VAROUT EXPOSUREDSET TMSLICEDSET;
  
   %let i=1;
   %let thisvar=%scan(&listvars, &i, %str( ));

   %do %while (%nrbquote(&thisvar) ne ) ;
      %if %nrbquote(&&&thisvar) eq %then
      %do;
         %put %str(RTE)RROR: &sysmacroname: The parameter (&thisvar) is required.;
         %let g_abort=1;
      %end;    
      
      %let i=%eval(&i + 1);
      %let thisvar=%scan(&listvars, &i, %str( ));
   %end;  /* end of do-to loop */
  
   /*
   / Check if &DSETIN is an existing dataset.
   /----------------------------------------------------------------------------*/
     
   %let l_rc=%tu_nobs(&DSETIN);
   
   %if &l_rc LT 0 %then 
   %do;
      %put %str(RTERR)OR: &sysmacroname: Input data set DSETIN(=&dsetin) does not exist;
      %let g_abort=1;
   %end;
   %else %do; 
      /* 
      / Check if PERNUM exists in &DSETIN dataset when eventype = PL. 
      /----------------------------------------------------------------------------*/
      %if %upcase(&EVENTTYPE) = PL AND %nrbquote(%tu_chkvarsexist(&dsetin, PERNUM)) NE %then 
      %do;
         %put %str(RTERR)OR: &sysmacroname: Variable PERNUM does not exist in the input data set &dsetin.;
         %let g_abort=1;
      %end;
      /*
      / Check if TPERNUM exist in &DSETIN dataset when eventype = SP.
      /----------------------------------------------------------------------------*/
      %if %upcase(&EVENTTYPE) = SP AND %nrbquote(%tu_chkvarsexist(&dsetin, TPERNUM)) NE %then
      %do;
         %put %str(RTERR)OR: &sysmacroname: Variable TPERNUM does not exist in the input data set &dsetin.;
         %let g_abort=1;
      %end;
      /*
      / Check if &REFDATE exist in &DSETIN dataset.
      /----------------------------------------------------------------------------*/
      %if %nrbquote(%tu_chkvarsexist(&dsetin, &REFDATE)) NE %then 
      %do;
         %put %str(RTERR)OR: &sysmacroname: Variable REFDATE(=&REFDATE) does not exist in data set DSETIN(=&DSETIN).;
         %let g_abort=1;
      %end;
   %end;
   
   /*
   / Check parameter EVENTTYPE = SP or PL.
   /----------------------------------------------------------------------------*/
   %let EVENTTYPE = %upcase(&EVENTTYPE);
   %if (&EVENTTYPE ne SP) and (&EVENTTYPE ne PL) %then %do;
      %put %str(RTE)RROR: &SYSMACRONAME.: Value of parameter EVENTTYPE(=&EVENTTYPE) is invalid. Valid values: SP or PL.;       
      %let g_abort=1;    
   %end;

   /*
   / Verify the dataset dmdata.tmslice exists
   /------------------------------------------------------------------------------*/
   %if %sysfunc(exist(&tmslicedset)) eq 0 %then %do;
      %put %str(RTE)RROR: &sysmacroname: The TMSLICEDSET(=&tmslicedset) dataset does not exist.;
      %let g_abort=1;
   %end;
   %else %do; /* Check if PTMNUM & PERNUM exists in tmslice */
      %if %nrbquote(%tu_chkvarsexist(&tmslicedset, PTMNUM)) NE %then 
      %do;
         %put %str(RTN)OTE: &sysmacroname: Variable PTMNUM does not exist in data set &tmslicedset.;
      %end;
      %if %nrbquote(%tu_chkvarsexist(&tmslicedset, PERNUM)) NE %then 
      %do;
         %put %str(RTERR)OR: &sysmacroname: Variable PERNUM does not exist in data set &tmslicedset.;
         %let g_abort=1;
      %end;
   %end;

   /*
   / Verify the dataset dmdata.exposure exists
   /------------------------------------------------------------------------------*/
   %if %sysfunc(exist(&exposuredset)) eq 0 %then %do;
      %put %str(RTE)RROR: &sysmacroname: The EXPOSUREDSET(=&exposuredset) dataset does not exist.;
      %let g_abort=1;
   %end;
   %else %do; /* Check if PTMNUM exists in exposure */
      %if %nrbquote(%tu_chkvarsexist(&exposuredset, PTMNUM)) NE %then 
      %do;
         %put %str(RTN)OTE: &sysmacroname: Variable PTMNUM does not exist in data set &exposuredset ;
      %end;
   %end;

   %if &g_abort eq 1 %then %do;
      %tu_abort;
   %end;   
   
   /*
   / NORMAL PROCESSING
   /----------------------------------------------------------------------------*/

   /*
   / Set variable to work with either Planned or Spontaneous event
   /----------------------------------------------------------------------------*/
   %if &EVENTTYPE = SP %then 
      %let l_pernum = tpernum;  /* Spontaneous data */
   %else
      %let l_pernum = pernum;   /* Planned data */

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
   / Create exposure dataset with first exposure date per period
   /----------------------------------------------------------------------------*/
   proc sort data=&exposuredset (keep=subjid &bylist exstdt where=(exstdt ne .)) 
              out=&prefix._expo1;
      by &bylist;
   run;

   proc sort data=&tmslicedset (keep=&bylist pernum) 
              out=&prefix._tmslice1;
      by &bylist;
   run;

   data &prefix._expo2 (keep=subjid pernum exstdt rename=(pernum=&l_pernum));
      merge &prefix._expo1 (in=a) 
            &prefix._tmslice1;
      by &bylist;
      if a;
   run;

   proc sort data=&prefix._expo2 out=&prefix._expo3 nodupkey;
      by subjid &l_pernum exstdt;
   run;

   proc sort data=&prefix._expo3 out=&prefix._expo4 nodupkey;
      by subjid &l_pernum;
   run;

   /*
   / sort input dataset
   /----------------------------------------------------------------------------*/

   proc sort data=&dsetin out=&prefix._dset1;
      by subjid &l_pernum;
   run;

   /*
   / create the Period Start Day variable
   /----------------------------------------------------------------------------*/
   data &dsetout (drop=&prefix._exstdt);
      merge &prefix._dset1 (in=a) &prefix._expo4 (rename=(exstdt=&prefix._exstdt));
      by subjid &l_pernum;
      if a;
      &VAROUT = &REFDATE - &prefix._exstdt;
      if &VAROUT GE 0 then &VAROUT + 1;
   run;

   /*
   / Delete temporary datasets used in this macro.
   /----------------------------------------------------------------------------*/

   %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tu_p1_periodday;
