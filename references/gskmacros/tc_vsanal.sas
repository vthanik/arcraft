/*
| Macro Name:         tc_vsanal
|
| Macro Version:      2
|
| SAS Version:        9
|
| Created By:         Yongwei Wang
|
| Date:               31AUG2006
|
| Macro Purpose:      This unit shall call the utility macros necessary to create an
|                     A&R VSANAL dataset. 
|
|                     The unit shall respect (and shall not change the value of) the 
|                     prevailing values of any global macro variables
|
| Macro Design:       Procedure Style
|
| Input Parameters:
|
| Name                Description                                  Default
| -----------------------------------------------------------------------------------
| DSETIN              Specifies the VITALS-format SI dataset which    dmdata.vitals
|                     needs to be transformed into an VITALS-format
|                     A&R dataset.
|                     Valid values: valid dataset name
|
| DSETOUT             Specifies the name of the output dataset to     ardata.vsanal
|                     be created.
|                     Valid values: valid dataset name
|
| BASELINETYPE        Calculation of baseline option when there		  LAST		** GK001 **
|                     are multiple records in the baseline range.
|                     Valid values:
|                     FIRST  - First non-missing baseline record is
|                              used and marked as baseline when 
|                              data are sorted in chronical order.
|                              Others are marked as pre-therapy.
|
|                     LAST   - Last non-missing baseline record is 
|                              used and marked as baseline when data
|                              are sorted in chronical order.
|                              Others are marked as pre-therapy.
|
|                     MEAN   - Mean value of baseline records is used
|                              as baseline. All baseline records  
|                              are marked as baseline.
|
|                     MEDIAN - Median value of baseline records is
|                              used as baseline. All baseline records 
|                              are marked as baseline.
|
| AGEDAYSYN           Calculate age in days?                         N
|                     Valid values: Y, N
|
| AGEMONTHSYN         Calculate age in months?                       N
|                     Valid values: Y, N
|
| AGEWEEKSYN          Calculate age in weeks?                        N
|                     Valid values: Y, N
|
| ATTRIBUTESYN        Call %tu_attrib to reconcile the               Y
|                     A&R-defined attributes to the planned A&R
|                     dataset?
|                     Valid values: Y, N
|
| BASELINEOPTION      Calculation of baseline option                 DATE
|                     Valid values:
|                     DATE   - Select baseline records based on
|                     lab collection date (VSDT) and visit number
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
|                     lab collection date (VSDT) and time
|                     (VSACTTM) compared to study medication
|                     start date (EXSTDT) and time (EXSTTM).
|
| BASELINEYN          Perform calculation of baseline?               Y
|                     Valid values: Y, N
|
| BSFGYN              Perform Change from Baseline                   Y
|                     flagging?
|                     Valid values: Y, N
|
| CCFGYN              Perform Clinical Concern  flagging?            Y
|                     Valid values: Y, N
|
| COMMONVARSYN        Call %tu_common to add common variables?       Y
|                     Valid values: Y, N
|
| CPDSRNG             VSCRIT clinical pharamcolgy range              (Blank)
|                     identifier
|
| CRITDSET            Specifies the SI dataset which contains the    DMDATA.VSCRIT
|                     Vital Signs flagging criteria.
|                     Valid values: Blank or a valid dataset name
|
| DATETIMEYN          Call %tu_datetm to derive datetime             Y
|                     variables?
|                     Valid values: Y, N
|
| DECODEYN            Call %tu_decode to decode coded variables?     Y
|                     Valid values: Y, N
|
| DERIVATIONYN        Call %tu_derive to perform specific            Y
|                     derivations for this domain code (VS)?
|                     Valid values: Y, N
|
| DGCD                VSCRIT compound identifier                     (Blank)
|
| DSETTEMPLATE        Specifies the name to give to the empty        (None)
|                     dataset containing the variables and
|                     attributes desired for the A&R dataset.
|                     NOTE: If DSETTEMPLATE is specified as
|                     anything non-blank, then DSPLAN must be
|                     specified as blank (DSPLAN=,).
|
| DSPLAN              Specifies the path and file name of the        &G_DSPLANFILE
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
| ENDVISNUM           VISITNUM value for end of range to identify    (Blank)
|                     records to be considered as baseline.
|                     Required if BASELINEOPTION is VISIT.
|
| FLAGGINGSUBSET      IF clause to identify records to be flagged    (Blank)
|
| FORMATNAMESDSET     Specifies the name of a dataset which          (None)
|                     contains VAR_NM (a variable name of a code)
|                     and format_nm (the name of a format to
|                     produce the decode).  NOTE: If
|                     FORMATNAMESDSET is specified as anything
|                     non-blank, then DSPLAN must be specified as
|                     blank (DSPLAN=,).
|
| MISSCHKYN           Call %tu_misschk to print RTWARNING            Y
|                     messages for each variable in &DSETOUT
|                     which has missing values on all records.
|                     Valid values: Y, N
|
| NODERIVEVARS        List of domain-specific variables not to       (None)
|                     derive when %tu_derive is called.
|
| PTRTCDINF           Name of pre-existing informat to derive        (None)
|                     PTRTCD from PTRTGRP.
|
| RECALCVISITYN       Call %tu_recalcvisit to recalculate VISIT      N
|                     based on the AE start date?
|                     Valid values: Y, N
|
| REFDAT              Specify a reference date variable name to      vsdt
|                     pass to %tu_recalcvisit to calculate the
|                     visit. Will be checked in %tu_recalcvisit
|
| REFDATEDSETSUBSET   WHERE clause applied to source dataset.        (None)
|                     May be used regardless of the value of
|                     REFDATEOPTION in order to better select the
|                     reference date.
|
| REFDATEOPTION       The reference date will be used in the         TREAT
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
| REFDATESOURCEDSET   Use the variable REFDATESOURCEVAR from the     (None)
|                     REFDATESOURCEDSET.  Required if
|                     REFDATEOPTION is OTHER.
|
| REFDATESOURCEVAR    Use the variable REFDATESOURCEVAR from the     (None)
|                     REFDATESOURCEDSET.  Required if
|                     REFDATEOPTION is OTHER.
|
| REFDATEVISITNUM     Specific visit number at which reference       (None)
|                     date is to be taken.  Required if
|                     REFDATEOPTION is VISIT.
|
| REFTIM              Specify a reference time variable name to      vsacttm
|                     pass to %tu_recalcvisit to calculate the
|                     visit. Will be checked in %tu_recalcvisit
|
| RELDAYS             Number of days prior to start of study         (Blank)
|                     medication, used to identify records to be
|                     considered as baseline. Required if
|                     BASELINEOPTION is RELDAY.
|
| SORTORDER           Specifies the sort order desired for the      (None)
|                     A&R dataset.  NOTE: If SORTORDER is
|                     specified as anything non-blank, then
|                     DSPLAN must be specified as blank
|                     (DSPLAN=,).
|
| STARTVISNUM         value for start of range to identify          (Blank)
|                     records to be considered as baseline.
|                     Required if BASELINEOPTION is VISIT.
|
| STMEDDSET           SI Exposure dataset.                          DMDATA.EXPOSURE
|                     Valid values: valid dataset name
|
| STMEDDSETSUBSET     WHERE clause applied to study medication      (Blank)
|                     dataset.
|
| STUDYID             VSBCRIT study identifier                      (Blank)
|
| TIMESLICINGYN       Call %tu_timslc to add timeslicing            Y
|                     variables?
|                     Valid values: Y, N
|
| TREATVARSYN         Call %tu_rantrt to add treatment variables?   Y
|                     Valid values: Y, N
|
| TRTCDINF            Name of pre-existing informat to derive       (None)
|                     TRTCD from TRTGRP
|
| XOVARSFORPGYN       Specifies whether to derive crossover stydy   N
|                     specific variables for parallel study
|                     Valid values: Y, N.
|
| DYREFDATEOPTION    Specifies how to derive the reference date for (Blank)         
|                    the computation of actual study days, in                      
|                    tu_derive.                                                    
|                    TREAT -    Trt start date from DMDATA.EXPOSURE                
|                    VISIT -    Visit date from DMDATA.VISIT                       
|                    RAND  -    Randomization date from DMDATA.RAND                
|                    OTHER -    Date from the DYREFDATESOURCEVAR                   
|                               variable on the DYREFDATESOURCEDSET                
|                               Dataset                                            
|                    
| DYREFDATEVISITNUM  Specific visit number at which the              (Blank)
|                    reference date is to be taken for                
|                    tu_derive.                                      
|                    Used when DYREFDATEOPTION is VISIT.             
|                                                                    
| DYREFDATESOURCEDSE The dataset that contains the date used for     (Blank)
| T                  Study Day calculations in tu_derive.            
|                    Used when DYREFDATEOPTION is OTHER.             
|                                                                    
| DYREFDATESOURCEVAR The variable in DYREFDATESOURCEDSET that        (Blank)
|                    contains the reference date used for Study      
|                    Day calculations, in tu_derive.                 
|                    Used when DYREFDATEOPTION is OTHER.             
|                                                                    
| DYREFDATEDSETSUBSE WHERE clause applied to reference dataset       (Blank)
| T                  for tu_derive.                                  
|                    Used to specify a subset of the reference       
|                    dataset for tu_derive to better select the      
|                    reference date.                                 
|                    This may be used regardless of the value of     
|                    DYREFDATEOPTION.                                
|                                                                    
| DEMODSET           Specifies an SI-format DEMO dataset to use      dmdata.demo
|                    for various derivations.                        
|                                                                    
| ENROLDSET          Specifies an SI-format ENROL dataset to use     dmdata.enrol
|                    for various derivations.                        
|                                                                    
| EXPOSUREDSET       Specifies an SI-format EXPOSURE dataset to      dmdata.exposure
|                    use for various derivations.                    
|                                                                    
| INVESTIGDSET       Specifies an SI-format INVESTIG dataset to      dmdata.investig
|                    use for various derivations.                    
|                                                                    
| RACEDSET           Specifies an SI-format RACE dataset to use      dmdata.race
|                    for various derivations.                        
|                                                                    
| RANDALLDSET        Specifies an SI-format RANDALL dataset to       dmdata.randall
|                    use for various derivations.                    
|                    Note: This parameter is not used in the         
|                    current version. It should be passed to         
|                    %tu_acttrt in a future release.                 
|                                                                    
| RANDDSET           Specifies an SI-format RAND dataset to use      dmdata.rand
|                    for various derivations.                        
|                                                                    
| TMSLICEDSET        Specifies an SI-format TMSLICE dataset to       dmdata.tmslice
|                    use for various derivations.                    
|                                                                    
| VISITDSET          Specifies an SI-format VISIT dataset to use     dmdata.visit
|                    for various derivations.                        
|                                                                    
| DECODEPAIRS        Specifies code and decode variables in          (Blank)
|                    pair. The decode variables will be created      
|                    and populated with format value of the code     
|                    variable. The format is defined in &DSPLAN      
|                    file.                                           
|----------------------------------------------------------------------------------
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
|----------------------------------------------------------------------------------
| Output:
| The macro outputs the following datasets :-
|  
|   Name         Req/Opt  Description
|   ------------ -------  ----------------------------------------------------
|   &DSETOUT     Req      Parameter specified IDSL standard VSANAL A&R dataset
|----------------------------------------------------------------------------------
| Global macro variables created: NONE
|----------------------------------------------------------------------------------
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
| (@) tu_nobs
| (@) tu_putglobals
| (@) tu_rantrt
| (@) tu_recalcvisit
| (@) tu_tidyup
| (@) tu_timslc
|----------------------------------------------------------------------------------
| Example:
|    %tc_vsanal(
|         refdateoption   = visit,
|         refdatevisitnum = 10,
|         dsplan          = &g_dsplanfile
|         );
|----------------------------------------------------------------------------------
| Change Log
|
| Modified By:              Yongwei Wang
| Date of Modification:     17-Sep-07
| New version/draft number: 2/1
| Modification ID:          YW001
| Reason For Modification:  Based on change request HRT0184 and HRT0172:
|                           1. Added data set parameters, which will be passed 
|                              to new version of TU macros: demodset, enroldset,
|                              exposuredset, investigdset, racedset, randalldset, 
|                              randdset, tmslicedset, visitdset       
|                           2. Added call of %tu_nobs to check if data set exist
|                           3. Added 5 new DYREF* parameters, which will be passed 
|                              %tu_derive REF* parameters: dyrefdateoption, 
|                              dyrefdatedsetsubset, dyrefdatesourcedset
|                              dyrefdatesourcevar, dyrefdatevisitnum  
|                           4.	Added parameter DECODEPAIRS, which will be 
|                               passed to %tu_decode
|----------------------------------------------------------------------------------
| Modified By:				Gail Knowlton
| Date of Modification:		23-Jul-2008
| New version/draft number:	3/1
| Modification ID:			GK001
| Reason For Modification: Surfaced 'BASELINETYPE' - a new parameter for tu_baseln
|----------------------------------------------------------------------------------
| Modified By:              Barry Ashby
| Date of Modification:     01-Jun-2009
| New version/draft number: 3/2
| Modification ID:          BA001
| Reason For Modification:  1. Removed the parameter REDERIVERRQTCBFYN. (HRT0225)
|                           2. Changed the order of macro calls to properly
|                              derive certain vital signs and adjusted code
|                              to match this new calling order.  (HRT0225)
|----------------------------------------------------------------------------------
| Modified By:
| Date of Modification:
| New version/draft number:
| Modification ID:
| Reason For Modification:
+----------------------------------------------------------------------------------*/

%macro tc_vsanal (
   DSETIN              =dmdata.vitals,     /* Input dataset name */
   DSETOUT             =ardata.vsanal,     /* Output dataset name */   
   CRITDSET            =DMDATA.VSCRIT,     /* Vital Signs flagging criteria dataset name */
   DEMODSET            =dmdata.demo,       /* Name of DEMO dataset to use */
   ENROLDSET           =dmdata.enrol,      /* Name of ENROL dataset to use */
   EXPOSUREDSET        =dmdata.exposure,   /* Name of EXPOSURE dataset to use */
   INVESTIGDSET        =dmdata.investig,   /* Name of RACE dataset to use */
   RACEDSET            =dmdata.race,       /* Name of RACE dataset to use */
   RANDALLDSET         =dmdata.randall,    /* Name of RANDALL dataset to use */
   RANDDSET            =dmdata.rand,       /* Name of RAND dataset to use */
   TMSLICEDSET         =dmdata.tmslice,    /* Name of TMSLICE dataset to use */
   VISITDSET           =dmdata.visit,      /* Name of VISIT dataset to use */
   BASELINETYPE        =LAST,              /* Select method of calculating baseline, when there are multiple baseline obs. */			
   ATTRIBUTESYN        =Y,                 /* Reconcile A&R dataset with planned A&R dataset */
   BASELINEYN          =Y,                 /* Calculation of baseline */
   BSFGYN              =Y,                 /* F2 Change from Baseline flagging */
   CCFGYN              =Y,                 /* F3 Clinical Concern flagging */
   COMMONVARSYN        =Y,                 /* Add common variables. */
   DATETIMEYN          =Y,                 /* Derive datetime variables */
   DECODEYN            =Y,                 /* Decode coded variables */
   DERIVATIONYN        =Y,                 /* Dataset specific derivations */
   MISSCHKYN           =Y,                 /* Print warning message for variables in &DSETOUT with missing values on all records */
   RECALCVISITYN       =N,                 /* Recalculate VISIT based on the AE start date */
   TIMESLICINGYN       =Y,                 /* Add timeslicing variables */
   TREATVARSYN         =Y,                 /* Add treatment variables. */
   XOVARSFORPGYN       =N,                 /* If Y derive crossover stydy specific variables for parallel study */
   AGEDAYSYN           =N,                 /* Calculation of age in days. */
   AGEMONTHSYN         =N,                 /* Calculation of age in months. */
   AGEWEEKSYN          =N,                 /* Calculation of age in weeks. */
   REFDAT              =vsdt,              /* Reference date variable name for recalculating visit */
   REFTIM              =vsacttm,           /* Reference time variable name for recalculating visit */
   REFDATEDSETSUBSET   =,                  /* WHERE clause applied to source dataset */
   REFDATEOPTION       =TREAT,             /* Reference date source option. */
   REFDATESOURCEDSET   =,                  /* Reference date source dataset. */
   REFDATESOURCEVAR    =,                  /* Reference date source variable. */
   REFDATEVISITNUM     =,                  /* Specific visit number at which reference date is to be taken. */
   DYREFDATEOPTION     =,                  /* Reference date source option for the calculation of Study Day values in tu_derive Reference date source option for tu_derive.*/   
   DYREFDATEDSETSUBSET =,                  /* WHERE clause applied to source dataset for tu_derive. */
   DYREFDATESOURCEDSET =,                  /* Reference date source dataset for tu_derive. */
   DYREFDATESOURCEVAR  =,                  /* Reference date source variable for tu_derive. */
   DYREFDATEVISITNUM   =,                  /* Specific visit number at which reference date is to be taken for tu_derive. */
   DGCD                =,                  /* VSCRIT compound identifier */
   CPDSRNG             =,                  /* VSCRIT clinical pharamcolgy range identifier */
   STUDYID             =,                  /* VSCRIT study identifier */
   BASELINEOPTION      =DATE,              /* alculation of baseline option */
   RELDAYS             =,                  /* Number of days prior to start of study medication */
   STARTVISNUM         =,                  /* VISITNUM value for start of baseline range */
   ENDVISNUM           =,                  /* VISITNUM value for end of baseline range */
   FLAGGINGSUBSET      =,                  /* IF clause to identify records to be flagged */
   STMEDDSET           =DMDATA.EXPOSURE,   /* Study medication dataset name */
   STMEDDSETSUBSET     =,                  /* Where clause applied to study medication dataset */
   PTRTCDINF           =,                  /* Informat to derive PTRTCD from PTRTGRP. */
   TRTCDINF            =,                  /* Informat to derive TRTCD from TRTGRP. */
   SORTORDER           =,                  /* Planned A&R dataset sort order. */
   DSETTEMPLATE        =,                  /* Output dataset template name. */
   DSPLAN              =&G_DSPLANFILE,     /* Path and filename of tab-delimited file containing HARP A&R dataset plan. */
   DECODEPAIRS         =,                  /* code and decode variables in pair */
   FORMATNAMESDSET     =,                  /* Format names dataset name. */
   NODERIVEVARS        =                   /* List of variables not to derive. */
   );

   /*
   / Echo parameter values and global macro variables to the log.
   /----------------------------------------------------------------------------*/
  
   %local MacroVersion;
   %let MacroVersion = 3;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals() 
  
   /*
   / PARAMETER VALIDATION
   /----------------------------------------------------------------------------*/
   
   %local listvars loopi thisvar prefix i testvarcount listtestindexes listunits 
          listtestcodes ;   
   %let prefix = _tc_vsanal;   /* Root name for temporary work datasets */
   
   /*
   / Check for required parameters.
   /----------------------------------------------------------------------------*/
   
   
   %let listvars=DSETIN DSETOUT COMMONVARSYN TREATVARSYN TIMESLICINGYN DATETIMEYN
                 DECODEYN BSFGYN CCFGYN BASELINEYN DERIVATIONYN ATTRIBUTESYN
                 MISSCHKYN RECALCVISITYN XOVARSFORPGYN;
  
   %do loopi=1 %to 15;
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
                 RECALCVISITYN XOVARSFORPGYN;
  
   %do loopi=1 %to 13;
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
   / If the input dataset name is the same as the output dataset name,
   / write an error to the log.
   /----------------------------------------------------------------------------*/
  
   %if %qscan(&dsetin, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: The input dataset name DSETIN(=&dsetin) is the same as the output dataset name DSETOUT(=&dsetout).;
      %let g_abort=1;
   %end;
  
   /*
   / Check for existing datasets.
   /----------------------------------------------------------------------------*/
       
   %if &dsetin ne %then
   %do;    
      %if %tu_nobs(&dsetin) lt 0 %then
      %do;
         %put %str(RTE)RROR: &sysmacroname: The dataset DSETIN(=&dsetin) does not exist.;
         %let g_abort=1;
      %end;
   %end; /* %if &dsetin ne */
  
   %if &g_abort eq 1 %then
   %do;
      %tu_abort;
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
   
   data &prefix._ds&i;
      set %unquote(&dsetin);
   run;
  
   /*
   / If &RECALCVISITYN equals Y or &XOVARSFORPGYN equals Y or &G_STYPE equals XO, 
   / ( Note: &XOVARSFORPGYN has been set to Y when &G_STYPE equals XO )
   / and &REFTIM is not blank, check if &REFTIM exists in &DSETIN. If not, write 
   / a RTWARNING message to the log and set &REFTIM to blank, but do not abort
   /----------------------------------------------------------------------------*/
   
   %if ( (&recalcvisityn eq Y) or (&xovarsforpgyn eq Y) ) and (%nrbquote(&reftim) ne) %then
   %do;
      %if %tu_chkvarsexist(&prefix._ds&i, &reftim) ne %then
      %do;
         %put %str(RTW)ARNING: Variable REFTIM(=&reftim) does not exist in DSETIN (=&dsetin) and it will not be used to recalculate visit.;
         %let reftim=;
      %end;
   %end; 
     
   /* 
   / For backward compatible, if all REF date related parameters, which are
   / using derive the age, are missing, use REF date relate parameters, which 
   / will be passed to %tu_derive.
   /----------------------------------------------------------------------------*/
   
   %if %nrbquote(&dyrefdateoption.&dyrefdatevisitnum.&dyrefdatesourcedset.&dyrefdatesourcevar.&dyrefdatedsetsubset) eq %then
   %do;
      %let dyrefdateoption     =&refdateoption;     
      %let dyrefdatevisitnum   =&refdatevisitnum;
      %let dyrefdatesourcedset =&refdatesourcedset; 
      %let dyrefdatesourcevar  =&refdatesourcevar;   
      %let dyrefdatedsetsubset =&refdatedsetsubset; 
   %end; 
  
   /*
   / Add common variables.
   /----------------------------------------------------------------------------*/
  
   %if &commonvarsyn eq Y %then
   %do;
      %tu_common (
           dsetin            = &prefix._ds&i,
           dsetout           = &prefix._ds%eval(&i+1),
           demodset          = &demodset,
           enroldset         = &enroldset,   
           exposuredset      = &exposuredset,
           investigdset      = &investigdset,
           racedset          = &racedset,
           randdset          = &randdset,
           visitdset         = &visitdset,   
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
           dsetin    = &prefix._ds&i,
           dsetout   = &prefix._ds%eval(&i+1),
           visitdset = &visitdset,
           refdat    = &refdat,
           reftim    = &reftim
      );
  
      %let i = %eval(&i + 1);
   %end;
   
   /*
   / Add timeslicing variables.
   /----------------------------------------------------------------------------*/
   
   %if &timeslicingyn eq Y %then
   %do;
      %tu_timslc (
           dsetin      = &prefix._ds&i,
           dsetout     = &prefix._ds%eval(&i+1), 
           tmslicedset = &tmslicedset
      );
  
      %let i = %eval(&i + 1);
   %end;
  
   /*
   / If Vital Sign tests flagging is required, split data set using &flaggingsubset
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
  
   /* BA001 - New order for macro call
   / Dataset specific derivations.
   /----------------------------------------------------------------------------*/
  
   %if &derivationyn eq Y %then
   %do;
      %tu_derive (
           dsetin            = &prefix._ds&i,
           dsetout           = &prefix._ds%eval(&i+1),
           
           demodset          = &demodset,              
           exposuredset      = &exposuredset,  
           randalldset       = &randalldset,   
           randdset          = &randdset,      
           tmslicedset       = &tmslicedset,   
           visitdset         = &visitdset,     
                              
           domaincode        = vs,                     
           noderivevars      = &noderivevars,          
           refdateoption     = &dyrefdateoption,         
           refdatevisitnum   = &dyrefdatevisitnum,       
           refdatesourcedset = &dyrefdatesourcedset,     
           refdatesourcevar  = &dyrefdatesourcevar,      
           refdatedsetsubset = &dyrefdatedsetsubset,     
           xovarsforpgyn     = &xovarsforpgyn     
      );
  
      %let i = %eval(&i + 1);
   %end;

   /*
   / Transform vital sign test results/units from column variables to row variables.
   /----------------------------------------------------------------------------*/
   
   %let listvars=      DIABP    HEART    HEIGHT   SYSBP    TEMP     WEIGHT   RESP        VSBSA   
                       VSWSTCIR VSHDCIR  VSFACIR  VSFBCCIR VSGRTHIC VSLBM    VSLBMC      VSMAP 
                       VSNKCIR  VSPECSKN VSPO2BLD VSRWRSTD VSWCIRHZ VSWCIRMN VSBMI       VSHIPCIR; 
   %let listtestcodes= DIA      HEART    HEIGHT   SYS      TEMP     WEIGHT   RESP        VSBSA     
                       VSWSTCIR VSHDCIR  VSFACIR  VSFBCCIR VSGRTHIC VSLBM    VSLBMC      VSMAP 
                       VSNKCIR  VSPECSKN VSPO2BLD VSRWRSTD VSWCIRHZ VSWCIRMN VSBMI       VSHIPCIR; 
   %let listunits=     MMHG     BPM      CM       MMHG     C        KG       BREATHS/MIN M2            
                       CM       CM       CM       CM       CM       KG       KG          MMHG  
                       CM       MM       NONE     CM       CM       CM       KG/M2       CM;
   
   %let testvarcount=0;
   %let listtestindexes=;
   %do loopi=1 %to 24;
      %let thisvar=%scan(&listvars, &loopi);
      %if %tu_chkvarsexist(&prefix._ds&i, &thisvar) eq %then  /* BA001 - Adjusted code to match new macro order */
      %do;
         %let listtestindexes=&listtestindexes &loopi;
         %let testvarcount=%eval(&testvarcount + 1);
      %end;
   %end; /* %do loopi=1 %to 24 */
   
   data &prefix._ds%eval(&i + 1);
      length VSTESTCD $8 VSORRESU $20 VSSTRESU $20 ;
      format VSSTRESN 10.2 VSORRESN 10.2;
      set &prefix._ds&i;      
      %do loopi=1 %to &testvarcount;
         drop %scan(&listvars, %scan(&listtestindexes, &loopi));
         vstestcd=compress("%scan(&listtestcodes, %scan(&listtestindexes, &loopi))");
         vsorresn=%scan(&listvars, %scan(&listtestindexes, &loopi));
         vsstresn=vsorresn;            
         vsorresu=left("%scan(&listunits, %scan(&listtestindexes, &loopi), %str( ))");
         if vsorresu eq 'NONE' then vsorresu='';
         vsstresu=vsorresu;
         output;                                 
      %end;
   run;
   
   %let i=%eval(&i + 1);
   
   /* BA001 - New order for macro call
   / Calculate baseline and change from baseline standard results.
   /----------------------------------------------------------------------------*/
  
   %if &baselineyn eq Y %then
   %do;        
      %tu_baseln(
         baselinetype    = &baselinetype,		/* GK001 */                   
         baselineoption  = &baselineoption,                   
         domaincode      = VS,                                                  
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
         domaincode    = VS,
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
         domaincode    = VS,
         dsetin        = &prefix._ds&i,                 
         dsetout       = &prefix._ds%eval(&i+1),                 
         studyid       = &studyid
         );
         
       %let i = %eval(&i + 1);        
   %end;           
    
   /*
   / If Vital Signs tests flagging is required, combine data sets which are splitted 
   / by &flaggingsubset
   /----------------------------------------------------------------------------*/
   
   %if ( &baselineyn eq Y ) or ( &ccfgyn eq Y ) or ( &bsfgyn eq Y ) %then
   %do;      
      data &prefix._ds&i ;
         set &prefix._ds&i &prefix.subset;
      run;
   %end;
  
   /*
   / If &G_STYPE eqyaks XO or &XOVARSFORPGYN equals Y, call %tu_calctpernum
   / add TPERIOD/TPERNUM.
   /----------------------------------------------------------------------------*/
   
   %if &XOVARSFORPGYN eq Y %then 
   %do;  
      %tu_calctpernum (
        dsetin      = &prefix._ds&i,                
        dsetout     = &prefix._ds%eval(&i+1),                
        exposuredset= &exposuredset, 
        refdat      = &refdat,                
        reftim      = &reftim,                
        tmslicedset = &tmslicedset,  
        visitdset   = &visitdset     
        );
      
      %let i = %eval(&i + 1);
   %end;
  
   /*
   / Add treatment variables.
   /----------------------------------------------------------------------------*/
  
   %if &treatvarsyn eq Y %then
   %do;
      %tu_rantrt (
           dsetin      = &prefix._ds&i,
           dsetout     = &prefix._ds%eval(&i+1),
           randalldset = &randalldset,
           randdset    = &randdset,
           trtcdinf    = &trtcdinf,
           ptrtcdinf   = &ptrtcdinf
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
         decodepairs     = &decodepairs,
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
      data %unquote(&dsetout);
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
  
%mend tc_vsanal;


