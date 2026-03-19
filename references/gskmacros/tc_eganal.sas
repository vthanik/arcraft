/*
| Macro Name:         tc_eganal
|
| Macro Version:      2
|
| SAS Version:        8
|
| Created By:         Yongwei Wang
|
| Date:               31AUG2006
|
| Macro Purpose:      This unit shall call the utility macros necessary to create 
|                     an A&R EGANAL dataset. 
|
|                     The unit shall respect (and shall not change the value of) the 
|                     prevailing values of any global macro variables.
|
| Macro Design:       Procedure Style
|
| Input Parameters:
|
| Name                Description                                  Default
| -----------------------------------------------------------------------------------
| DSETIN              Specifies the ECG-format SI dataset which    dmdata.ecg
|                     needs to be transformed into an ECG-format
|                     A&R dataset.
|                     Valid values: valid dataset name
|
| DSETOUT             Specifies the name of the output dataset to  ardata.eganal
|                     be created.
|                     Valid values: valid dataset name
|
| AGEDAYSYN           Calculate age in days?                       N
|                     Valid values: Y, N
|
| AGEMONTHSYN         Calculate age in months?                     N
|                     Valid values: Y, N
|
| AGEWEEKSYN          Calculate age in weeks?                      N
|                     Valid values: Y, N
|
| ATTRIBUTESYN        Call %tu_attrib to reconcile the             Y
|                     A&R-defined attributes to the planned A&R
|                     dataset?
|                     Valid values: Y, N
|
| BASELINEOPTION      Calculation of baseline option               DATE
|                     Valid values:
|                     DATE   - Select baseline records based on
|                     lab collection date (EGDT) and visit number
|                     (VISITNUM) compared  to study medication
|                     start date (EXSTDT) and  visit number
|                     (VISITNUM). Note that when start   date and
|                     visit of medication is the same as lab date
|                     and visit, it is regarded as post-baseline.
|                     RELDAY - Select baseline records by
|                     relative days. The  parameter RELDAYS must
|                     contain a positive number.
|                     VISIT  - Select baseline records specified
|                     by VISITNUM codes         passed in the
|                     parameters STARTVISNUM and ENDVISNUM.
|                     TIME   - Select baseline records based on
|                     lab collection date (EGDT) and time
|                     (EGACTTM) compared to study medication
|                     start date (EXSTDT) and time (EXSTTM).
|
| BASELINEYN          Perform calculation of baseline?             Y
|                     Valid values: Y, N
|
| BSFGYN              Perform Change from Baseline                 Y
|                     flagging?
|                     Valid values: Y, N
|
| CCFGYN              Perform Clinical Concern  flagging?          Y
|                     Valid values: Y, N
|
| COMMONVARSYN        Call %tu_common to add common variables?     Y
|                     Valid values: Y, N
|
| CPDSRNG             EGCRIT clinical pharamcolgy range            (Blank)
|                     identifier
|
| CRITDSET            Specifies the SI dataset which contains the  DMDATA.EGCRIT
|                     ECG flagging criteria.
|                     Valid values: Blank or a valid dataset name
|
| DATETIMEYN          Call %tu_datetm to derive datetime           Y
|                     variables?
|                     Valid values: Y, N
|
| DECODEYN            Call %tu_decode to decode coded variables?   Y
|                     Valid values: Y, N
|
| DERIVATIONYN        Call %tu_derive to perform specific          Y
|                     derivations for this domain code (EG)?
|                     Valid values: Y, N
|
| DGCD                EGCRIT compound identifier                   (Blank)
|
| DSETTEMPLATE        Specifies the name to give to the empty      (None)
|                     dataset containing the variables and
|                     attributes desired for the A&R dataset.
|                     NOTE: If DSETTEMPLATE is specified as
|                     anything non-blank, then DSPLAN must be
|                     specified as blank (DSPLAN=,).
|
| DSPLAN              Specifies the path and file name of the      &G_DSPLANFILE
|                     HARP A&R dataset metadata. This will define
|                     the attributes to use to define the A&R
|                     dataset.  NOTE: If DSPLAN is not specified
|                     (i.e. left to its default value), or is
|                     specified as anything other than blank,
|                     then both DSETTEMPLATE, SORTORDER and
|                     FORMATNAMESDSET must not be specified as
|                     anything non-blank. If DSETTEMPLATE,
|                     SORTORDER and FORMATNAMESDSET are specified
|                     as anything non-blank, then DSPLAN must be
|                     specified as blank (DSPLAN=,).
|
| ENDVISNUM           VISITNUM value for end of range to identify  (Blank)
|                     records to be considered as baseline.
|                     Required if BASELINEOPTION is VISIT.
|
| FLAGGINGSUBSET      IF clause to identify records to be flagged  (Blank)
|
| FORMATNAMESDSET     Specifies the name of a dataset which        (None)
|                     contains VAR_NM (a variable name of a code)
|                     and format_nm (the name of a format to
|                     produce the decode).  NOTE: If
|                     FORMATNAMESDSET is specified as anything
|                     non-blank, then DSPLAN must be specified as
|                     blank (DSPLAN=,).
|
| MISSCHKYN           Call %tu_misschk to print RTWARNING          Y
|                     messages for each variable in &DSETOUT
|                     which has missing values on all records.
|                     Valid values: Y, N
|
| NODERIVEVARS        List of domain-specific variables not to     (None)
|                     derive when %tu_derive is called.
|
| PTRTCDINF           Name of pre-existing informat to derive      (None)
|                     PTRTCD from PTRTGRP.
|
| RECALCVISITYN       Call %tu_recalcvisit to recalculate VISIT    N
|                     based on the AE start date?
|                     Valid values: Y, N
|
| REDERIVERRQTCBFYN   Re-derive RR, QTCB and QTCF even if they     N
|                     already exist in &DSETIN?
|                     Valid values: Y, N
|
| REFDAT              Specify a reference date variable name to    egdt
|                     pass to %tu_recalcvisit to calculate the
|                     visit. Will be checked in %tu_recalcvisit
|
| REFDATEDSETSUBSET   WHERE clause applied to source dataset.      (None)
|                     May be used regardless of the value of
|                     REFDATEOPTION in order to better select the
|                     reference date.
|
| REFDATEOPTION       The reference date will be used in the       TREAT
|                     calculation of the age values.
|                     TREAT - Trt start date from
|                     DMDATA.EXPOSURE
|                     VISIT - Visit date from
|                     DMDATA.VISIT
|                     RAND  - Randomization date from
|                     DMDATA.RAND
|                     OTHER  Date from the
|                     REFDATESOURCEVAR variable on the
|                     REFDATESOURCEDSET Dataset
|
| REFDATESOURCEDSET   Use the variable REFDATESOURCEVAR from the   (None)
|                     REFDATESOURCEDSET.  Required if
|                     REFDATEOPTION is OTHER.
|
| REFDATESOURCEVAR    Use the variable REFDATESOURCEVAR from the   (None)
|                     REFDATESOURCEDSET.  Required if
|                     REFDATEOPTION is OTHER.
|
| REFDATEVISITNUM     Specific visit number at which reference     (None)
|                     date is to be taken.  Required if
|                     REFDATEOPTION is VISIT.
|
| REFTIM              Specify a reference time variable name to    egacttm
|                     pass to %tu_recalcvisit to calculate the
|                     visit. Will be checked in %tu_recalcvisit
|
| RELDAYS             Number of days prior to start of study       (Blank)
|                     medication, used to identify records to be
|                     considered as baseline. Required if
|                     BASELINEOPTION is RELDAY.
|
| SORTORDER           Specifies the sort order desired for the     (None)
|                     A&R dataset.  NOTE: If SORTORDER is
|                     specified as anything non-blank, then
|                     DSPLAN must be specified as blank
|                     (DSPLAN=,).
|
| STARTVISNUM         value for start of range to identify         (Blank)
|                     records to be considered as baseline.
|                     Required if BASELINEOPTION is VISIT.
|
| STMEDDSET           SI Exposure dataset.                         DMDATA.EXPOSURE
|                     Valid values: valid dataset name
|
| STMEDDSETSUBSET     WHERE clause applied to study medication     (Blank)
|                     dataset.
|
| STUDYID             EGBCRIT study identifier                     (Blank)
|
| TIMESLICINGYN       Call %tu_timslc to add timeslicing           Y
|                     variables?
|                     Valid values: Y, N
|
| TREATVARSYN         Call %tu_rantrt to add treatment variables?  Y
|                     Valid values: Y, N
|
| TRTCDINF            Name of pre-existing informat to derive      (None)
|                     TRTCD from TRTGRP
|
| XOVARSFORPGYN       Specifies whether to derive crossover stydy  N
|                     specific variables for parallel study
|                     Valid values: Y, N.
|
| -----------------------------------------------------------------------------------
| The macro references the following datasets :-
| ------------------  -------  ------------------------------------------------
| Name                Req/Opt  Description
| ------------------  -------  ------------------------------------------------
| &DSETIN             Req      Parameter specified dataset
| &REFDATESOURCEDSET  Opt      Parameter specified dataset
| &DSETTEMPLATE       Opt      Parameter specified dataset
|
| &FORMATNAMESDSET    Opt      Parameter specified dataset with variables:
|
|                              NAME       DESCRIPTION
|                              ---------  -------------------------------------
|                              VAR_NM     Variable name   (CD suffix)
|                              FORMAT_NM  SAS format name ($ prefix, e.g. $FMT)
|-----------------------------------------------------------------------------------
| Output:
|
| The macro outputs the following datasets :-
|
| Name           Req/Opt  Description
| -------------- -------  -------------------------------------------------------
| &DSETOUT       Req      Parameter specified IDSL standard EGANAL A&R data set
|-----------------------------------------------------------------------------------
| Global macro variables created: NONE
|-----------------------------------------------------------------------------------
| Macros called:
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_attrib
| (@) tu_baseln
| (@) tu_calctpernum
| (@) tu_chgccfg
| (@) tu_chkvarsexist
| (@) tu_common
| (@) tu_datetm
| (@) tu_decode
| (@) tu_derive
| (@) tu_misschk
| (@) tu_putglobals
| (@) tu_rantrt
| (@) tu_recalcvisit
| (@) tu_tidyup
| (@) tu_timslc
|-----------------------------------------------------------------------------------
| Example:
|    %tc_eganal(
|         refdateoption   = visit,
|         refdatevisitnum = 10,
|         dsplan          = &g_dsplanfile
|         );
|
|-----------------------------------------------------------------------------------
| Change Log
|
| Modified By:              Yongwei Wang
| Date of Modification:     14-Nov-2007
| New version/draft number: 2/1
| Modification ID:          YW001
| Reason For Modification:  Based on bug found by user after the release, changed 
|                           &dsetin to &prefix._ds&i in %tu_chkvarsexist when 
|                           transform test results.
|
| Modified By:
| Date of Modification:
| New version/draft number:
| Modification ID:
| Reason For Modification:
+----------------------------------------------------------------------------------*/

%macro tc_eganal (
   DSETIN              =dmdata.ecg,        /* Input dataset name */
   DSETOUT             =ardata.eganal,     /* Output dataset name */

   AGEDAYSYN           =N,                 /* Calculation of age in days. */
   AGEMONTHSYN         =N,                 /* Calculation of age in months. */
   AGEWEEKSYN          =N,                 /* Calculation of age in weeks. */
   ATTRIBUTESYN        =Y,                 /* Reconcile A&R dataset with planned A&R dataset */
   BASELINEOPTION      =DATE,              /* alculation of baseline option */
   BASELINEYN          =Y,                 /* Calculation of baseline */
   BSFGYN              =Y,                 /* F2 Change from Baseline flagging */
   CCFGYN              =Y,                 /* F3 Clinical Concern flagging */
   COMMONVARSYN        =Y,                 /* Add common variables. */
   CPDSRNG             =,                  /* EGCRIT clinical pharamcolgy range identifier */
   CRITDSET            =DMDATA.EGCRIT,     /* ECG flagging criteria dataset name */
   DATETIMEYN          =Y,                 /* Derive datetime variables */
   DECODEYN            =Y,                 /* Decode coded variables */
   DERIVATIONYN        =Y,                 /* Dataset specific derivations */
   DGCD                =,                  /* EGCRIT compound identifier */
   DSETTEMPLATE        =,                  /* Output dataset template name. */
   DSPLAN              =&G_DSPLANFILE,     /* Path and filename of tab-delimited file containing HARP A&R dataset plan. */
   ENDVISNUM           =,                  /* VISITNUM value for end of baseline range */
   FLAGGINGSUBSET      =,                  /* IF clause to identify records to be flagged */
   FORMATNAMESDSET     =,                  /* Format names dataset name. */
   MISSCHKYN           =Y,                 /* Print warning message for variables in &DSETOUT with missing values on all records */
   NODERIVEVARS        =,                  /* List of variables not to derive. */
   PTRTCDINF           =,                  /* Informat to derive PTRTCD from PTRTGRP. */
   RECALCVISITYN       =N,                 /* Recalculate VISIT based on the AE start date */
   REDERIVERRQTCBFYN   =N,                 /* Re-derive RR, QTCB and QTCF even if they already exist in &DSETIN */
   REFDAT              =egdt,              /* Reference date variable name for recalculating visit */
   REFDATEDSETSUBSET   =,                  /* WHERE clause applied to source dataset */
   REFDATEOPTION       =TREAT,             /* Reference date source option. */
   REFDATESOURCEDSET   =,                  /* Reference date source dataset. */
   REFDATESOURCEVAR    =,                  /* Reference date source variable. */
   REFDATEVISITNUM     =,                  /* Specific visit number at which reference date is to be taken. */
   REFTIM              =egacttm,           /* Reference time variable name for recalculating visit */
   RELDAYS             =,                  /* Number of days prior to start of study medication */
   SORTORDER           =,                  /* Planned A&R dataset sort order. */
   STARTVISNUM         =,                  /* VISITNUM value for start of baseline range */
   STMEDDSET           =DMDATA.EXPOSURE,   /* Study medication dataset name */
   STMEDDSETSUBSET     =,                  /* Where clause applied to study medication dataset */
   STUDYID             =,                  /* EGCRIT study identifier */
   TIMESLICINGYN       =Y,                 /* Add timeslicing variables */
   TREATVARSYN         =Y,                 /* Add treatment variables. */
   TRTCDINF            =,                  /* Informat to derive TRTCD from TRTGRP. */
   XOVARSFORPGYN       =N                  /* If Y derive crossover stydy specific variables for parallel study */
   );

   /*
   / Echo parameter values and global macro variables to the log.
   /----------------------------------------------------------------------------*/
  
   %local MacroVersion;
   %let MacroVersion = 2;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals(); 
  
   /*
   / PARAMETER VALIDATION
   /----------------------------------------------------------------------------*/
   
   %local listvars loopi thisvar prefix i testvarcount listtestvars listunits 
          listtestunits addrryn addqtcbyn addqtcfyn notexistvars demodset;   
   %let prefix = _tc_eganal;   /* Root name for temporary work datasets */
   %let demodset=dmdata.demo; /* Shold add to parameter when all DMDATA.DEMO is in parameter of utility macros */
   
   /*
   / Check for required parameters.
   /----------------------------------------------------------------------------*/
     
   %let listvars=DSETIN DSETOUT COMMONVARSYN TREATVARSYN TIMESLICINGYN DATETIMEYN
                 DECODEYN BSFGYN CCFGYN BASELINEYN DERIVATIONYN ATTRIBUTESYN
                 MISSCHKYN RECALCVISITYN XOVARSFORPGYN REDERIVERRQTCBFYN;
  
   %do loopi=1 %to 16;
      %let thisvar=%scan(&listvars, &loopi, %str( ));
      %let &thisvar=%nrbquote(&&&thisvar);
      
      %if &&&thisvar eq %then
      %do;
         %put %str(RTE)RROR: &sysmacroname: The parameter &thisvar is required.;
         %let g_abort=1;
      %end;    
   %end;  /* end of do-to loop */
  
   /*
   / Check for valid parameter values.
   /----------------------------------------------------------------------------*/
        
   %let listvars=COMMONVARSYN TREATVARSYN TIMESLICINGYN DATETIMEYN DECODEYN 
                 BSFGYN CCFGYN BASELINEYN DERIVATIONYN ATTRIBUTESYN MISSCHKYN 
                 RECALCVISITYN XOVARSFORPGYN REDERIVERRQTCBFYN;
  
   %do loopi=1 %to 14;
      %let thisvar=%scan(&listvars, &loopi, %str( ));
      %if %nrbquote(&&&thisvar) ne %then
         %let &thisvar=%qupcase(%substr(&&&thisvar, 1, 1));
      
      %if (%nrbquote(&&&thisvar) ne Y) and (%nrbquote(&&&thisvar) ne N) %then
      %do;
         %put %str(RTE)RROR: &sysmacroname: &thisvar should be either Y or N.;
         %let g_abort=1;
      %end;    
   %end;  /* end of do-to loop */
     
   %if %qupcase(&g_stype) eq XO %then %let XOVARSFORPGYN=Y;
  
   /*
   / Check for existing datasets.
   /----------------------------------------------------------------------------*/
       
   %if &dsetin ne %then
   %do;    
      %if %sysfunc(exist(&dsetin)) eq 0 %then
      %do;
         %put %str(RTE)RROR: &sysmacroname: The dataset DSETIN(=&dsetin) does not exist.;
         %let g_abort=1;
      %end;
   %end; /* %if &dsetin ne */
   
   /*
   / If the input dataset name is the same as the output dataset name,
   / write an error to the log.
   /----------------------------------------------------------------------------*/
  
   %if &dsetin eq &dsetout %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: The input dataset name DSETIN(=&dsetin) is the same as the output dataset name DSETOUT(=&dsetout).;
      %let g_abort=1;
   %end;
  
   %if &g_abort eq 1 %then
   %do;
      %tu_abort;
   %end;
   
   /*
   / If &RECALCVISITYN equals Y or &XOVARSFORPGYN equals Y or &G_STYPE equals XO, 
   / ( Note: &XOVARSFORPGYN has been set to Y when &G_STYPE equals XO )
   / and &REFTIM is not blank, check if &REFTIM exists in &DSETIN. If not, write 
   / a RTWARNING message to the log and set &REFTIM to blank, but do not abort
   /----------------------------------------------------------------------------*/
   
   %if ( (&recalcvisityn eq Y) or (&xovarsforpgyn eq Y) ) and (%nrbquote(&reftim) ne) %then
   %do;
      %if %tu_chkvarsexist(&dsetin, &reftim) ne %then
      %do;
         %put %str(RTW)ARNING: Variable REFTIM(=&reftim) does not exist in DSETIN (=&dsetin) and it will not be used to recalculate visit.;
         %let reftim=;
      %end;
   %end; 
  
   /*
   / NORMAL PROCESSING
   /----------------------------------------------------------------------------*/

   /*
   / Initialise counter for appending to temporary dataset names for the
   / purpose of tracking datasets through a number of optional sequential
   / data processing steps.
   /----------------------------------------------------------------------------*/
  
   %let i=1;
   
   /*
   / Derived variables: QTCB QTCF RR
   /----------------------------------------------------------------------------*/
 
   %let addrryn=Y;
   %let addqtcbyn=Y;
   %let addqtcfyn=Y;

   %let notexistvars=%upcase(%tu_chkvarsexist(&dsetin, eghr qt rr qtcb qtcf));
   
   /*
   / If any of RR, QTCB and QTCF is in &NODERIVEVARS,do not derive it
   /----------------------------------------------------------------------------*/
   
   %if %sysfunc(indexw(&noderivevars, RR))   gt 0 %then %let addrryn=N;
   %if %sysfunc(indexw(&noderivevars, QTCB)) gt 0 %then %let addqtcbyn=N;
   %if %sysfunc(indexw(&noderivevars, QTCF)) gt 0 %then %let addqtcfyn=N;
   
   /*
   / If any of RR, QTCB and QTCF, which is used for derivation, is not in &dsetin and will
   / not be derived, do not derive it
   /----------------------------------------------------------------------------*/
   
   %if ( %sysfunc(indexw(&notexistvars, EGHR)) gt 0 ) %then %let addrryn=N;
   %if ( %sysfunc(indexw(&notexistvars, QT))   gt 0 ) or ( &addrryn eq N ) %then
   %do;
      %let addqtcfyn=N;
      %let addqtcbyn=N;
   %end;
  
   /*
   / If any of RR, QTCB and QTCF already exists, and no rederivation is
   / required, do not derive it
   /----------------------------------------------------------------------------*/
   
   %if &rederiverrqtcbfyn eq N %then
   %do;
      %if %sysfunc(indexw(&notexistvars, RR))   eq 0  %then %let addrryn=N;
      %if %sysfunc(indexw(&notexistvars, QTCB)) eq 0  %then %let addqtcbyn=N;
      %if %sysfunc(indexw(&notexistvars, QTCF)) eq 0  %then %let addqtcfyn=N;
   %end;
   
   /*
   / Remove RR, QTCB and QTCF from &noderivevars
   /----------------------------------------------------------------------------*/
   
   %if %nrbquote(&noderivevars) ne %then
   %do;
      %let noderivevars=%qsysfunc(tranwrd(&noderivevars, RR , %str()));
      %let noderivevars=%qsysfunc(tranwrd(&noderivevars, QTCB , %str()));
      %let noderivevars=%qsysfunc(tranwrd(&noderivevars, QTCF , %str()));
   %end;
              
   data &prefix._ds1;
      set &dsetin;
   
      %if &addrryn eq Y %then
      %do;
          rr=1/((eghr/60)/1000);
      %end;
   
      %if &addqtcbyn eq Y %then
      %do;   
          qtcb=qt/((rr/1000) ** (1/2));
      %end;
   
      %if &addqtcfyn eq Y %then
      %do;
         qtcf=qt/((rr/1000) ** (1/3));
      %end;
   run;   

   /*
   / Transform ECG test results/units from column variables to row variables.
   /----------------------------------------------------------------------------*/
   
   %let listvars= EGATRHR EGHR PR   QRS  QRSAXIS QT   QTC  QTCB QTCF RR; * QTCI;
   %let listunits=NONE    BPM  MSEC MSEC NONE    MSEC MSEC MSEC MSEC MSEC;
   
   %let testvarcount=0;
   %let listtestvars=;
   %let listtestunits=;
   %do loopi=1 %to 10;
      %let thisvar=%scan(&listvars, &loopi);
      /* YW001: changed &dsetin to &prefix._ds&i */
      %if %tu_chkvarsexist(&prefix._ds&i, &thisvar) eq %then
      %do;
         %let listtestvars=&listtestvars &thisvar;
         %let listtestunits=&listtestunits %scan(&listunits, &loopi);
         %let testvarcount=%eval(&testvarcount + 1);
      %end;
   %end; /* %do loopi=1 %to 10 */
   
   data &prefix._ds%eval(&i+1);
      length EGTESTCD $8 EGORRESU $20 EGSTRESU $20 ;
      format egorresn 10.2 egstresn 10.2;
      set &prefix._ds&i;      
      %do loopi=1 %to &testvarcount;
         drop %scan(&listtestvars, &loopi);
         egtestcd=compress("%scan(&listtestvars, &loopi)");
         egorresn=%scan(&listtestvars, &loopi);
         egstresn=egorresn;            
         egorresu=left("%scan(&listtestunits, &loopi)");
         if egorresu eq 'NONE' then egorresu='';
         egstresu=egorresu;
         output;                                 
      %end;
   run;

   %let i = %eval(&i + 1);
   
   /*
   / Add common variables.
   /----------------------------------------------------------------------------*/
  
   %if &commonvarsyn eq Y %then
   %do;
      %tu_common (
         dsetin            = &prefix._ds&i,
         dsetout           = &prefix._ds%eval(&i+1),
         agemonthsyn       = &agemonthsyn,           
         ageweeksyn        = &ageweeksyn,            
         agedaysyn         = &agedaysyn,             
         refdateoption     = &refdateoption,         
         refdatevisitnum   = &refdatevisitnum,       
         refdatesourcedset = &refdatesourcedset,     
         refdatesourcevar  = &refdatesourcevar,      
         refdatedsetsubset = &refdatedsetsubset      
         );
  
      %let i = %eval(&i + 1);
   %end;
  
   /*
   / Recalculate visit based on date of surgical procedure.
   /----------------------------------------------------------------------------*/
   
   %if &recalcvisityn eq Y %then
   %do;
      %tu_recalcvisit (
         dsetin  = &prefix._ds&i,
         dsetout = &prefix._ds%eval(&i+1),
         refdat  = &refdat,
         reftim  = &reftim
         );
  
      %let i = %eval(&i + 1);
   %end;
  
   /*
   / Add timeslicing variables.
   /----------------------------------------------------------------------------*/
  
   %if &timeslicingyn eq Y %then
   %do;
      %tu_timslc (
         dsetin  = &prefix._ds&i,
         dsetout = &prefix._ds%eval(&i+1)
         );
  
      %let i = %eval(&i + 1);
   %end;
   
   /*
   / If &G_STYPE equals XO or &XOVARSFORPGYN equals Y, call %tu_calctpernum
   / to add TPERIOD/TPERNUM.
   /----------------------------------------------------------------------------*/
   
   %if &XOVARSFORPGYN eq Y %then 
   %do;  
      %tu_calctpernum (
         dsetin      = &prefix._ds&i,                
         dsetout     = &prefix._ds%eval(&i+1),                
         exposuredset= dmdata.exposure, 
         refdat      = &refdat,                
         reftim      = &reftim,                
         tmslicedset = dmdata.tmslice,  
         visitdset   = dmdata.visit     
         );
      
      %let i = %eval(&i + 1);
   %end;
  
   /*
   / Add treatment variables.
   /----------------------------------------------------------------------------*/
  
   %if &treatvarsyn eq Y %then
   %do;
      %tu_rantrt (
         dsetin    = &prefix._ds&i,
         dsetout   = &prefix._ds%eval(&i+1),
         trtcdinf  = &trtcdinf,
         ptrtcdinf = &ptrtcdinf
         );
  
      %let i = %eval(&i + 1);
   %end;
  
   /*
   / If ECG tests flagging is required, split data set using &flaggingsubset
   /----------------------------------------------------------------------------*/
   
   %if ( &baselineyn eq Y ) or ( &ccfgyn eq Y ) or ( &bsfgyn eq Y ) %then
   %do;      
      %if %nrbquote(&flaggingsubset) eq %then %let flaggingsubset=1;
      
      data &prefix._ds&i &prefix.subset;
         set &prefix._ds&i;
         if %unquote(&flaggingsubset) then output &prefix._ds&i;
         else output &prefix.subset;
      run;
   %end;
  
   /*
   / Calculate baseline and change from baseline standard results.
   /----------------------------------------------------------------------------*/
  
   %if &baselineyn eq Y %then
   %do;        
      %tu_baseln(       
         baselineoption  = &baselineoption,                   
         domaincode      = EG,                                                  
         dsetin          = &prefix._ds&i,          
         dsetout         = &prefix._ds%eval(&i+1),                           
         endvisnum       = &endvisnum,                             
         reldays         = &reldays,              
         startvisnum     = &startvisnum,     
         stmeddset       = &stmeddset,
         stmeddsetsubset = &stmeddsetsubset
         );
           
      %let i = %eval(&i + 1);        
   %end;
   
   /*
   / Clnical concern flagging.
   /----------------------------------------------------------------------------*/
  
   %if &ccfgyn eq Y %then
   %do;
      %tu_chgccfg (
         chgorcc       = CC,               
         cpdsrng       = &cpdsrng, 
         critdset      = &critdset,   
         demodset      = &demodset,      
         dgcd          = &dgcd,
         domaincode    = EG,
         dsetin        = &prefix._ds&i,                 
         dsetout       = &prefix._ds%eval(&i+1),                 
         studyid       = &studyid
         );
         
      %let i = %eval(&i + 1);        
   %end;
   
   /*
   / Change from baseline flagging.
   /----------------------------------------------------------------------------*/
   
   %if &bsfgyn eq Y %then
   %do;
      %tu_chgccfg (
         chgorcc       = CH,               
         cpdsrng       = &cpdsrng, 
         critdset      = &critdset,   
         demodset      = &demodset,      
         dgcd          = &dgcd,
         domaincode    = EG,
         dsetin        = &prefix._ds&i,                 
         dsetout       = &prefix._ds%eval(&i+1),                 
         studyid       = &studyid
         );
         
       %let i = %eval(&i + 1);        
   %end;           
    
   /*
   / If ECG tests flagging is required, combine data sets which are splitted 
   / by &flaggingsubset
   /----------------------------------------------------------------------------*/
   
   %if ( &baselineyn eq Y ) or ( &ccfgyn eq Y ) or ( &bsfgyn eq Y ) %then
   %do;      
      data &prefix._ds&i ;
         set &prefix._ds&i &prefix.subset;
      run;
   %end;
   
   /*
   / Dataset specific derivations.
   /----------------------------------------------------------------------------*/
  
   %if &derivationyn eq Y %then
   %do;
      %tu_derive (
         dsetin            = &prefix._ds&i,
         dsetout           = &prefix._ds%eval(&i+1),
         domaincode        = EG,                     
         demodset          = &demodset,              
         noderivevars      = &noderivevars,          
         refdatedsetsubset = &refdatedsetsubset,     
         refdateoption     = &refdateoption,         
         refdatesourcedset = &refdatesourcedset,     
         refdatesourcevar  = &refdatesourcevar,      
         refdatevisitnum   = &refdatevisitnum,       
         xovarsforpgyn     = &xovarsforpgyn     
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
   / Decode coded variables.
   /----------------------------------------------------------------------------*/
  
   %if &decodeyn eq Y %then
   %do;
      %tu_decode (
         dsetin          = &prefix._ds&i,
         dsetout         = &prefix._ds%eval(&i+1),
         dsplan          = &dsplan,
         formatnamesdset = &formatnamesdset
         );
  
      %let i = %eval(&i + 1);
   %end;
   
   /*
   / Reconcile A&R dataset with planned A&R dataset.
   /----------------------------------------------------------------------------*/
  
   %if &attributesyn eq Y %then
   %do;
      %tu_attrib(
         dsetin       = &prefix._ds&i,
         dsetout      = &dsetout,
         dsplan       = &dsplan,
         dsettemplate = &dsettemplate,
         sortorder    = &sortorder
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
         dsetin = &dsetout
         );
   %end;
  
   /*
   / Delete temporary datasets used in this macro.
   /----------------------------------------------------------------------------*/
  
   %tu_tidyup(
      rmdset=&prefix:, 
      glbmac=NONE
      );
  
%mend tc_eganal;


