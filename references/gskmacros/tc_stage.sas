/*******************************************************************************
|
| Macro Name:        tc_stage
|                   
| Macro Version:     1
|                   
| SAS Version:       8.2
|                   
| Created By:        Yongwei Wang
|                   
| Date:              16-Feb-2005
|                   
| Macro Purpose:     STAGE wrapper macro
|                   
| Macro Design:      Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                            REQ/OPT  DEFAULT
| -----------------  -------------------------------------  -------  ----------
| EXPOSUREDSET       Specifies the EXPOSURE SI dataset      OPT      DMDATA.EXPOSURE
|                    which will be used along with the
|                    TMSLICEDSET and VISITDSET datasets
|                    to produce a STAGE A&R dataset.
|                    Valid values: valid dataset name.
|
| TMSLICEDSET        Specifies the TMSLICEDSET SI dataset   REQ      DMDATA.TMSLICE 
|                    which will be used along with the
|                    EXPOSUREDSET and VISITDSET datasets
|                    to produce a STAGE A&R dataset.
|                    Valid values: valid dataset name.
|
| VISITDSET          Specifies the VISIT SI dataset         REQ      DMDATA.VISIT   
|                    which will be used along with the
|                    EXPOSUREDSET and TMSLICEDSET datasets
|                    to produce a STAGE A&R dataset.
|                    Valid values: valid dataset name.
|
| DSETOUT            Specifies the name of the output       REQ      ARDATA.STAGE
|                    dataset to be created.
|                    Valid values: valid dataset name.
|
| COMMONVARSYN       Call %tu_common to add common          REQ      Y
|                    variables?                       
|                    Valid values: Y, N.              
|
| DATETIMEYN         Call %tu_datetime to derive            REQ      Y
|                    datetime variables?              
|                    Valid values: Y, N.              
|
| DERIVATIONYN       Call %tu_derive to perform specific    REQ      Y
|                    for this domain code (PR)?       
|                    Valid values: Y, N.              
|
| ATTRIBUTESYN       Call %tu_attrib to assign the          REQ      Y
|                    A&R-defined attribute to the output
|                    dataset.
|                    Valid values: Y, N.              
|
| MISSCHKYN          Call %tu_misschk to print RTWARNING    REQ      Y
|                    messages for each variable in 
|                    &DSETOUT which has missing values
|                    on all records.                    
|                    Valid values: Y, N.              
|
| DSPLAN             Specifies the path and file name of    OPT      &G_DSPLANFILE
|                    the HARP A&R dataset metadata. This 
|                    will define the attributes to use to 
|                    define the A&R dataset.
|                    NOTE: If DSPLAN is not specified (i.e.
|                          left to its default value) or
|                          is specified as anything other
|                          than blank, then both 
|                          DSETTEMPLATE and SORTORDER must
|                          not be specified as anything
|                          non-blank. If DSETTEMPLATE and 
|                          SORTORDER are specified as 
|                          anything non-blank, then DSPLAN
|                          must be specified as blank 
|                          (DSPLAN=,).
|
| DSETTEMPLATE       Specifies the name to give to the      OPT      (Blank)
|                    empty dataset containing the variables 
|                    and attributes desired for the A&R 
|                    dataset.
|                    NOTE: If DSETTEMPLATE is specified as
|                          anything non-blank, then DSPLAN
|                          must be specified as blank
|                          (DSPLAN=,).
|
| SORTORDER          Specifies the sort order desired for   OPT      (Blank)
|                    the A&R dataset.
|                    NOTE: If SORTORDER is specified as
|                          anything non-blank, then DSPLAN
|                          must be specified as blank
|                          (DSPLAN=,).
|
| NODERIVEVARS       List of domain-specific variables not  OPT      (Blank)
|                    to derive when %tu_derive is called.
| -----------------  -------------------------------------  -------  ----------
|
| The macro references the following datasets :-
| ------------------  -------  ------------------------------------------------
| Name                Req/Opt  Description
| ------------------  -------  ------------------------------------------------
| &EXPOSUREDSET       Opt      Parameter specified dataset
| &TMSLICEDSET        Req      Parameter specified dataset
| &VISITDSET          Req      Parameter specified dataset
| &DSETTEMPLATE       Opt      Parameter specified dataset
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
|(@) tu_attrib
|(@) tu_chkvarsexist
|(@) tu_common
|(@) tu_datetm
|(@) tu_derive
|(@) tu_misschk
|(@) tu_pernum
|(@) tu_putglobals
|(@) tu_tidyup
|
| Example:
|    %tc_stage(
|         dsplan = &g_dsplanfile
|         );
|
|******************************************************************************
| Change Log
|
| Modified By:              Yongwei Wang
| Date of Modification:     22-Apr-2005
| New version/draft number: 1/2
| Modification ID:          YW001
| Reason For Modification:  Changed default value of COMMONVARSYN to Y
|
| Modified By:              Yongwei Wang
| Date of Modification:     04-May-2005
| New version/draft number: 1/3
| Modification ID:          YW002
| Reason For Modification:  1. Removed EXPOSUREDSET from parameter checks which
|                              check if EXPOSUREDSET is blank.
|                           2. Changed RTWARNING message to RTERROR when
|                              data set &EXPOSUREDSET does not exist.
|                           
*******************************************************************************/

%macro tc_stage (
     exposuredset      = DMDATA.EXPOSURE, /* EXPOSURE dataset name */
     tmslicedset       = DMDATA.TMSLICE,  /* TMSLICE dataset name */
     visitdset         = DMDATA.VISIT,    /* VISIT dataset name */
     dsetout           = ARDATA.STAGE,    /* Output dataset name */

     commonvarsyn      = Y,       /* Add common variables */
     datetimeyn        = Y,       /* Derive datetime variables */
     derivationyn      = Y,       /* Dataset specific derivations */
     attributesyn      = Y,       /* Reconcile A&R dataset with planned A&R dataset */
     misschkyn         = Y,       /* Print warning message for variables in &DSETOUT with missing values on all records */ 
     dsplan            = &g_dsplanfile, /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
     dsettemplate      = ,        /* Planned A&R dataset template name */
     noderivevars      = ,        /* List of variables not to derive */
     sortorder         =          /* Planned A&R dataset sort order */
     );

   /*
   / Echo parameter values and global macro variables to the log.
   /----------------------------------------------------------------------------*/
  
   %local MacroVersion;
   %let MacroVersion = 1;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals() 
     
   /*
   / Initialise counter for appending to temporary dataset names for the
   / purpose of tracking datasets through a number of optional sequential
   / data processing steps.
   /----------------------------------------------------------------------------*/
   
   %local listvars thisvar loopi i prefix;   
   %let i = 1;   
   %let prefix = _tc_stage;   /* Root name for temporary work datasets */
   
   /*
   / PARAMETER VALIDATION
   /----------------------------------------------------------------------------*/
  
   %let listvars=DSETOUT TMSLICEDSET VISITDSET ATTRIBUTESYN 
                 COMMONVARSYN DATETIMEYN DERIVATIONYN MISSCHKYN  
                 ;
  
   %do loopi=1 %to 8;
      %let thisvar=%scan(&listvars, &loopi, %str( ));
      %let &thisvar=%nrbquote(&&&thisvar);
      
      %if &&&thisvar eq %then
      %do;
         %put %str(RTE)RROR: &sysmacroname: The parameter &thisvar is required.;
         %let g_abort=1;
      %end;    
   %end;  /* end of do-to loop */
   
   /*
   / Check for Y/N parameter values.
   /----------------------------------------------------------------------------*/
   
   %let listvars=ATTRIBUTESYN COMMONVARSYN DATETIMEYN DERIVATIONYN MISSCHKYN  
                 ;  
  
   %do loopi=1 %to 5;
      %let thisvar=%scan(&listvars, &loopi, %str( ));
      %let &thisvar=%qupcase(%substr(&&&thisvar, 1, 1));
      
      %if (&&&thisvar ne Y) and (&&&thisvar ne N) %then
      %do;
         %put %str(RTE)RROR: &sysmacroname: &thisvar should be either Y or N.;
         %let g_abort=1;
      %end;    
   %end;  /* end of do-to loop */
   
   /*
   / Check any data set given, by EXPOSUREDSET TMSLICEDSET VISITDSET, exists and
   / has different name as DSETOUT.
   /----------------------------------------------------------------------------*/
   
   %let listvars=EXPOSUREDSET TMSLICEDSET VISITDSET ;
   
   %do loopi=1 %to 3;
      %let thisvar=%scan(&listvars, &loopi, %str( ));
      
      %if %nrbquote(&&&thisvar) ne  %then
      %do;
         %if %sysfunc(exist(&&&thisvar)) eq 0 %then
         %do;      
            %put %str(RTE)RROR: &sysmacroname: The &thisvar dataset &&&thisvar does not exist.;
            %let g_abort=1;            
         %end;
         
         %if &&&thisvar eq &dsetout %then
         %do;
            %put %str(RTE)RROR: &sysmacroname: The &thisvar name (&&&thisvar) is the same as the DSETOUT name (&dsetout).;
            %let g_abort=1;        
         %end;
      %end; /* end-if on &&&thisvar ne */      
   %end;  /* end of do-to loop */
      
   /*
   / If variables STAGENUM and STAGE are not on the TMSLICEDSET dataset, then we  
   / cannot process anything. Give an error message and abort.
   /----------------------------------------------------------------------------*/
  
   %let thisvar=%tu_chkvarsexist(&tmslicedset, stagenum stage);
   
   %if &thisvar ne %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: The variable &thisvar must be on the &TMSLICEDSET dataset: &tmslicedset;
      %let g_abort=1;
   %end;
  
   %if &g_abort eq 1 %then
   %do;
      %tu_abort;
   %end;

   /*
   / NORMAL PROCESSING
   /----------------------------------------------------------------------------*/
   
   /*
   / Rename STAGENUM to PERNUM, STAGE to PERIOD in &TMSLICEDSET data set
   /----------------------------------------------------------------------------*/
   
   %let listvars=;                                                                             
   %if %tu_chkvarsexist(&tmslicedset, period) eq %then %let listvars=period;;
   %if %tu_chkvarsexist(&tmslicedset, pernum) eq %then %let listvars=&listvars pernum;;
   
   data &prefix.tmslice;
      set &tmslicedset
          %if %nrbquote(&listvars) ne %then
          %do;
             (drop=&listvars)
          %end;
          ;
      rename stage=period
             stagenum=pernum;
   run;
   
   %let tmslicedset=&prefix.tmslice;    
   
   /*
   / Call %tu_pernum to create a data set which contains variable PERENDT, 
   / PERENTM, PERIOD, PERNUM, PERSTDT, PERSTTM, PERTENDT, PERTENTM, PERTSTDT, 
   / PERTSTTM, STUDYID and SUBJID
   /----------------------------------------------------------------------------*/
   
   %tu_pernum (
      dsetout      = &prefix._ds&i,   
      exposuredset = &exposuredset, 
      tmslicedset  = &tmslicedset,  
      visitdset    = &visitdset     
      ); 
      
   /*
   / Rename PERIOD date/time related variables to STAGE variables; Rename 
   / PERNUM to STAGENUM; Rename PERIOD to STAGE
   /----------------------------------------------------------------------------*/
   
   %let listvars=%tu_chkvarsexist(&prefix._ds&i, PERENDT PERENTM PERSTDT PERSTTM
                           PERTENDT PERTENTM PERTSTDT PERTSTTM PERTENDM PERTSTDM);
   %let listvars=%upcase(&listvars);
   
   data &prefix._ds%eval(&i + 1);
      set &prefix._ds&i;
      rename PERIOD=STAGE PERNUM=STAGENUM
      %if %index(&listvars, PERENDT) eq 0 %then
      %do;
         PERENDT=STGENDT
      %end;
      %if %index(&listvars, PERENTM) eq 0 %then
      %do;
         PERENTM=STGENTM
      %end;
      %if %index(&listvars, PERSTDT) eq 0 %then
      %do;
         PERSTDT=STGSTDT
      %end;      
      %if %index(&listvars, PERSTTM) eq 0 %then
      %do;
         PERSTTM=STGSTTM
      %end;      
      %if %index(&listvars, PERTENDT) eq 0 %then
      %do;
         PERTENDT=STGTENDT
      %end;
      %if %index(&listvars, PERTENTM) eq 0 %then
      %do;
         PERTENTM=STGTENTM
      %end;
      %if %index(&listvars, PERTSTDT) eq 0 %then
      %do;
         PERTSTDT=STGTSTDT
      %end;      
      %if %index(&listvars, PERTSTTM) eq 0 %then
      %do;
         PERTSTTM=STGTSTTM
      %end;     
      ;
      %if %index(&listvars, PERTENDM) eq 0 %then
      %do;
         drop PERTENDM;
      %end; 
      %if %index(&listvars, PERTSTDM) eq 0 %then
      %do;
         drop PERTSTDM;
      %end;       
   run;
   
   %let i = %eval(&i + 1);
   
   /*
   / Derive common variables.
   /----------------------------------------------------------------------------*/
   
   %if &commonvarsyn eq Y %then
   %do;
      %tu_common (
         dsetin  = &prefix._ds&i,
         dsetout = &prefix._ds%eval(&i+1)
         );
   
      %let i = %eval(&i + 1);
   %end;
   
   /*
   / Dataset specific derivations.
   /----------------------------------------------------------------------------*/
   
   %if &derivationyn eq Y %then
   %do;
      %tu_derive (
         dsetin            = &prefix._ds&i,
         dsetout           = &prefix._ds%eval(&i+1),
         domaincode        = pr,                     
         noderivevars      = &noderivevars           
         );
   
      %let i = %eval(&i + 1);
   %end;
   
   /*
   / Derive datetime variables.
   /----------------------------------------------------------------------------*/
   
   %if &datetimeyn eq Y %then
   %do;
      %tu_datetm (
         dsetin  = &prefix._ds&i,
         dsetout = &prefix._ds%eval(&i+1)
         );
   
      %let i = %eval(&i + 1);
   %end;
   
   /*
   / Reconcile A&R dataset with planned A&R dataset.
   /----------------------------------------------------------------------------*/
   
   %if &attributesyn eq Y %then
   %do;
      %tu_attrib(
         dsetin        = &prefix._ds&i,
         dsetout       = &dsetout,
         dsplan        = &dsplan,
         dsettemplate  = &dsettemplate,
         sortorder     = &sortorder
         );
   %end;  
   %else %do;
      data &dsetout;
         set &prefix._ds&i;
      run;
   %end;
   
   /*
   / Call tu_misschk macro in order to identify any variables in the 
   / &DSETOUT dataset which have missing values on all records.
   /----------------------------------------------------------------------------*/
   
   %if &misschkyn eq Y %then
   %do;
      %tu_misschk(
         dsetin        = &dsetout
         );
   %end;
   
   /*
   / Delete temporary datasets used in this macro.
   /----------------------------------------------------------------------------*/
   
   %tu_tidyup(
      rmdset=&prefix:, 
      glbmac=NONE
      );

%mend tc_stage;
 
