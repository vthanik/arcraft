/*******************************************************************************
|
| Macro Name:      tu_p1_studyday
|
| SAS Version:     9.1
|
| Created By:      Suzanne Johnes
|
| Date:            11 March 2008
|
| Macro Purpose:   Creates Study Day variable
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
| VAROUT             Specifies the variable name given to   REQ      <blank>
|                    the study day variable created
|
| EXPOSUREDSET       Specifies the variable name given to   REQ      DMDATA.EXPOSURE
|                    the study EXPOSURE dataset             
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
|(@) tr_putlocals
|(@) tu_putglobals
|(@) tu_valparms
|(@) tu_tidyup
|
| Example: %tu_p1_studyday (dsetin   = ecg,
|                           dsetout  = ecg2,
|                           refdate  = ecgdt,
|                           varout   = egactsdy,
|                           exposuredset   = dmdata.exposure );
|
|
|******************************************************************************
| Change Log
|
| Modified By:              Khilit Shah (kys41925)
| Date of Modification:     20-Oct-2008
| New version/draft number: 2
| Modification ID:          n/a
| Reason For Modification:  1  Pass DMDATA.EXPOSURE as macro
|                                parameters instead of this being hardcoded
|
| Modified By:              
| Date of Modification:     
| New version/draft number: 
| Modification ID:          
| Reason For Modification:  
*******************************************************************************/

%macro tu_p1_studyday (
   dsetin         =,                 /* Input dataset                             */
   dsetout        =,                 /* Output dataset                            */
   refdate        =,                 /* Reference date variable on input dataset  */
   varout         =,                 /* Name of Study Day variable created        */
   exposuredset   = dmdata.exposure  /* Name of EXPOSURE dataset to use */    
   );

   /*
   / Echo parameter values and global macro variables to the log.
   /----------------------------------------------------------------------------*/

   %local MacroVersion MacroName Prefix;
   %let MacroVersion = 2;
   %let MacroName=&sysmacroname.;
   %let Prefix = _tu_p1_studyday;   /* Root name for temporary work datasets */ 

   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals();

   %local pv_abort listvars thisvar i;
   %let pv_abort = 0 ;

   /*
   / Parameter validation
   /----------------------------------------------------------------------------*/

   %let dsetin    = %nrbquote(&dsetin.);
   %let dsetout   = %nrbquote(&dsetout.);
   %let refdate   = %nrbquote(&refdate.);
   %let varout    = %nrbquote(&varout.);

   /*
   / Check for required parameters.
   /----------------------------------------------------------------------------*/
   %let listvars=DSETIN DSETOUT REFDATE VAROUT;
  
   %let i=1;
   %let thisvar=%scan(&listvars, &i, %str( ));

   %do %while (%nrbquote(&thisvar) ne );
     %if %nrbquote(&&&thisvar) eq %then %do; 
       %put %str(RTE)RROR: &macroname: Macro parameter (&thisvar) cannot be blank; 
       %let pv_abort = 1;
   %end;
     %let i=%eval(&i + 1);
     %let thisvar=%scan(&listvars, &i, %str( ));
   %end;

   /*
   / Check for valid datasets & parameter values
   / Set up a macro variable to hold the pv_abort flag
   /----------------------------------------------------------------------------*/

   /*-- Check if &DSETIN is an existing dataset */
   %tu_valparms(
     macroname=tu_p1_studyday,
     chktype=dsetExists,
     pv_dsetin=dsetin
    );

    /*-- Verify the dataset DMDATA.EXPOSURE exists */
    %tu_valparms(
      macroname=tu_p1_studyday,
      chktype=dsetExists,
      pv_dsetin=exposuredset
    );

    /*-- Check if &REFDATE exists in &DSETIN dataset */
    %tu_valparms(
      macroname=tu_p1_studyday,
      chktype=varexists,
      pv_dsetin=dsetin,
      pv_varsin=refdate
     );

    /*- Complete parameter validation */
    %if %eval(&g_abort. + &pv_abort.) gt 0 %then %do;
      %put %str(RTE)RROR: &macroname: Macro has failed parameter validation check for reasons stated with %str(RTE)RRORs above;
      %tu_abort(option=force);
    %end;

    /*
    / NORMAL PROCESSING
    /----------------------------------------------------------------------------*/

    /*- Create exposure dataset with first exposure dosing date */ 
    proc sort data=&exposuredset (keep=subjid exstdt where=(exstdt ne .)) out=&prefix._expo1;
      by subjid exstdt;
    run;

    proc sort data=&prefix._expo1 out=&prefix._expo2(keep=subjid exstdt) nodupkey;
      by subjid;
    run;

    /*- Sort input dataset */
    proc sort data=&dsetin out=&prefix._dset1;
      by subjid;
    run;

    /*- Create Study Day variable */
    data &dsetout (drop=&prefix._exstdt);
      merge &prefix._dset1 (in=a) &prefix._expo2 (rename=(exstdt=&prefix._exstdt));
      by subjid;
      if a;
      &varout = &refdate - &prefix._exstdt;
      if &varout GE 0 then &varout + 1;
    run;

    /*
    / Delete temporary datasets used in this macro.
    /----------------------------------------------------------------------------*/

    %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tu_p1_studyday;
