/*
| Macro Name:         tc_limaging
|
| Macro Version:      2
|
| SAS Version:        8
|
| Created By:         Yongwei Wang
|
| Date:               16AUG2007
|
| Macro Purpose:      This unit shall call the utility macros necessary to create an
|                     A&R LIMAGING dataset.
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
| DSETIN              Specifies the LIMAGING-format SI dataset     dmdata.limaging
|                     which needs to be transformed into a
|                     LIMAGING-format A&R dataset.
|                     Valid values: valid dataset name
|
| DSETOUT             Specifies the name of the output dataset to  ardata.limaging
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
| COMMONVARSYN        Call %tu_common to add common variables?     Y
|                     Valid values: Y, N
|
| DATETIMEYN          Call %tu_datetm to derive datetime           Y
|                     variables?
|                     Valid values: Y, N
|
| DECODERENAME        DECODERENAME      By default, a coded        limeth=limethod
|                     variable named  ZZZcd will produce a         liorrs=liorres
|                     decoded variable ZZZ.  This can be changed
|                     by using                  this parameter,
|                     i.e.            decoderename=zzz=abc_text
|                     will create the decode of ZZZcd in a
|                     variable named ABC_TEXT.
|
| DECODEYN            Call %tu_decode to decode coded variables?   Y
|                     Valid values: Y, N
|
| DERIVATIONYN        Call %tu_derive to perform specific          Y
|                     derivations for this domain code (LB)?
|                     Valid values: Y, N
|
| DSETTEMPLATE        Specifies the name of the empty dataset      (Blank)
|                     containing the variables and attributes
|                     desired for the A&R dataset.
|                     NOTE: If DSETTEMPLATE is specified as
|                     anything non-blank, then DSPLAN must be
|                     specified as blank (DSPLAN=,).
|
| DSPLAN              Specifies the path and file name of the      &g_dsplanfile
|                     tab-delimited HARP A&R dataset metadata.
|                     This will define the attributes to use to
|                     define the A&R dataset.
|                     NOTE: If DSPLAN is not specified (i.e. left
|                     to its default value), or is specified as
|                     anything other than blank, then both
|                     DSETTEMPLATE and SORTORDER must be blank.
|                     If DSETTEMPLATE and SORTORDER are specified
|                     as anything non-blank, then DSPLAN must be
|                     specified as blank (DSPLAN=,).
|
| FORMATNAMESDSET     Specifies the name of a dataset which        (Blank)
|                     contains VAR_NM (a variable name of a code)
|                     and format_nm (the name of a format to
|                     produce the decode).
|
| MISSCHKYN           Call %tu_misschk to print RTWARNING          Y
|                     messages for each variable in &DSETOUT
|                     which has missing values on all records.
|                     Valid values: Y, N
|
| NODERIVEVARS        List of domain-specific variables not to     (Blank)
|                     derive when %tu_derive is called.
|
| PTRTCDINF           Name of pre-existing informat to derive      (Blank)
|                     PTRTCD from PTRTGRP.
|
| RECALCVISITYN       Call %tu_recalcvisit to recalculate          Y
|                     VISITNUM based on the liver imaging start 
|                     date?
|                     Valid values: Y, N
|
| REFDAT              Specify a reference date variable name to    lidt
|                     pass to %tu_recalcvisit to calculate the
|                     visit. Will be checked in %tu_recalcvisit
|
| REFDATEDSETSUBSET   WHERE clause applied to source dataset.      (Blank)
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
|                     REFDATESOURCEDSET dataset
|
| REFDATESOURCEDSET   Required if REFDATEOPTION is OTHER. Use the  (Blank)
|                     variable REFDATESOURCEVAR from the
|                     REFDATESOURCEDSET.
|
| REFDATESOURCEVAR    Required if REFDATEOPTION is OTHER. Use the  (Blank)
|                     variable REFDATESOURCEVAR from the
|                     REFDATESOURCEDSET.
|
| REFDATEVISITNUM     Specific visit number at which reference     (Blank)
|                     date is to be taken.  Required if
|                     REFDATEOPTION is VISIT.
|
| REFTIM              Specify a reference time variable name to    (Blank)
|                     pass to %tu_recalcvisit to calculate the
|                     visit. Will be checked in %tu_recalcvisit
|
| SORTORDER           Specifies the sort order desired for the     (Blank)
|                     A&R dataset.
|                     NOTE: If SORTORDER is specified as anything
|                     non-blank, then DSPLAN must be specified as
|                     blank (DSPLAN=,).
|
| TIMESLICINGYN       Call %tu_timslc to add timeslicing           Y
|                     variables?
|                     Valid values: Y, N
|
| TREATVARSYN         Call %tu_rantrt to add treatment variables?  Y
|                     Valid values: Y, N
|
| TRTCDINF            Name of pre-existing informat to derive      (Blank)
|                     TRTCD from TRTGRP
|
| XOVARSFORPGYN       Specifies whether to derive crossover study  N
|                     specific variables for parallel study
|                     Valid values: Y, N.
|
| DYREFDATEOPTION    Specifies how to derive the reference date for  (Blank)         
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
| RANDALLDSET        Specifies an SI-format RANDALL dataset to       dmdata.randall
|                    use for various derivations.                    
|                    Note: This parameter is not used in the         
|                    current version. It should be passed to         
|                    %tu_acttrt in a future release.                 
|                                                                    
| RANDDSET           Specifies an SI-format RAND dataset to use      dmdata.rand
|                    for various derivations.                        
|                                                                    
| EXPOSUREDSET       Specifies an SI-format EXPOSURE dataset to      dmdata.exposure
|                    use for various derivations.                    
|                                                                    
| TMSLICEDSET        Specifies an SI-format TMSLICE dataset to       dmdata.tmslice
|                    use for various derivations.                    
|                                                                    
| VISITDSET          Specifies an SI-format VISIT dataset to use     dmdata.visit
|                    for various derivations.                        
|                                                                    
| DEMODSET           Specifies an SI-format DEMO dataset to use      dmdata.demo
|                    for various derivations.                        
|                                                                    
| RACEDSET           Specifies an SI-format RACE dataset to use      dmdata.race
|                    for various derivations.                        
|                                                                    
| ENROLDSET          Specifies an SI-format ENROL dataset to use     dmdata.enrol
|                    for various derivations.                        
|                                                                    
| INVESTIGDSET       Specifies an SI-format INVESTIG dataset to      dmdata.investig
|                    use for various derivations.                    
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
|   &DSETOUT     Req      Parameter specified IDSL standard LIMAGING A&R dataset
|----------------------------------------------------------------------------------
| Global macro variables created: NONE
|----------------------------------------------------------------------------------
| Macros called:
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_attrib
| (@) tu_calctpernum
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
|    %tc_limaging(
|         refdateoption   = visit,
|         refdatevisitnum = 10,
|         dsplan          = &g_dsplanfile
|         );
|----------------------------------------------------------------------------------
| Change Log
|
| Modified By:              Barry Ashby	
| Date of Modification:     10-Oct-08
| New version/draft number: 2
| Modification ID:          BA001
| Reason For Modification:  Based on change request HRT0211:
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
|
| Modified By:
| Date of Modification:
| New version/draft number:
| Modification ID:
| Reason For Modification:
+----------------------------------------------------------------------------------*/

%macro tc_limaging (
   DSETIN              = dmdata.limaging,  /* Input dataset name */
   DSETOUT             = ardata.limaging,  /* Output dataset name */
   DEMODSET            = dmdata.demo,      /* Name of DEMO dataset to use */        
   ENROLDSET           = dmdata.enrol,     /* Name of ENROL dataset to use */       
   EXPOSUREDSET        = dmdata.exposure,  /* Name of EXPOSURE dataset to use */    
   INVESTIGDSET        = dmdata.investig,  /* Name of RACE dataset to use */        
   RACEDSET            = dmdata.race,      /* Name of RACE dataset to use */        
   RANDALLDSET         = dmdata.randall,   /* Name of RANDALL dataset to use */     
   RANDDSET            = dmdata.rand,      /* Name of RAND dataset to use */        
   TMSLICEDSET         = dmdata.tmslice,   /* Name of TMSLICE dataset to use */      
   VISITDSET           = dmdata.visit,     /* Name of VISIT dataset to use */       

   AGEDAYSYN           =N,                 /* Calculation of age in days. */
   AGEMONTHSYN         =N,                 /* Calculation of age in months. */
   AGEWEEKSYN          =N,                 /* Calculation of age in weeks. */
   ATTRIBUTESYN        =Y,                 /* Reconcile A&R dataset with planned A&R dataset */
   COMMONVARSYN        =Y,                 /* Add common variables. */
   DATETIMEYN          =Y,                 /* Derive datetime variables */
   DECODEYN            =Y,                 /* Decode coded variables */
   DECODEPAIRS         = ,                 /* code and decode variables in pair */
   DECODERENAME        =limeth=limethod liorrs=liorres, /* List of renames for decoded variables */
   DERIVATIONYN        =Y,                 /* Dataset specific derivations */
   DSETTEMPLATE        =,                  /* Output dataset template name. */
   DSPLAN              =&G_DSPLANFILE,     /* Path and filename of tab-delimited file containing HARP A&R dataset plan. */
   FORMATNAMESDSET     =,                  /* Format names dataset name. */
   MISSCHKYN           =Y,                 /* Print warning message for variables in &DSETOUT with missing values on all records */
   NODERIVEVARS        =,                  /* List of variables not to derive. */
   PTRTCDINF           =,                  /* Informat to derive PTRTCD from PTRTGRP. */
   RECALCVISITYN       =Y,                 /* Recalculate VISIT based on the liver imaging start date */
   REFDAT              =lidt,              /* Reference date variable name for recalculating visit */
   REFDATEDSETSUBSET   =,                  /* WHERE clause applied to source dataset */
   REFDATEOPTION       =TREAT,             /* Reference date source option. */
   REFDATESOURCEDSET   =,                  /* Reference date source dataset. */
   REFDATESOURCEVAR    =,                  /* Reference date source variable. */
   REFDATEVISITNUM     =,                  /* Specific visit number at which reference date is to be taken. */
   REFTIM              =,                  /* Reference time variable name for recalculating visit */
   SORTORDER           =,                  /* Planned A&R dataset sort order. */
   TIMESLICINGYN       =Y,                 /* Add timeslicing variables */
   TREATVARSYN         =Y,                 /* Add treatment variables. */
   TRTCDINF            =,                  /* Informat to derive TRTCD from TRTGRP. */
   XOVARSFORPGYN       =N,                 /* If Y derive crossover stydy specific variables for parallel study */
   DYREFDATEOPTION     =,                  /* Reference date source option for the calculation of Study Day values in tu_derive Reference date source option for tu_derive.*/                                  
   DYREFDATEDSETSUBSET =,                  /* WHERE clause applied to source dataset for tu_derive. */            
   DYREFDATESOURCEDSET =,                  /* Reference date source dataset for tu_derive. */                                            
   DYREFDATESOURCEVAR  =,                  /* Reference date source variable for tu_derive. */                                           
   DYREFDATEVISITNUM   =                   /* Specific visit number at which reference date is to be taken for tu_derive. */         
   );

   /*
   / Echo parameter values and global macro variables to the log.
   /----------------------------------------------------------------------------*/

   %local MacroVersion;
   %let MacroVersion = 2;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals()

   /*
   / PARAMETER VALIDATION
   /----------------------------------------------------------------------------*/

   %local listvars loopi thisvar prefix i testvarcount listtestindexes listunits
          listtestcodes demodset;
   %let prefix = _tc_limaging;   /* Root name for temporary work datasets */

   /*
   / Check for required parameters.
   /----------------------------------------------------------------------------*/

   %let listvars=DSETIN DSETOUT COMMONVARSYN TREATVARSYN TIMESLICINGYN DATETIMEYN
                 DECODEYN DERIVATIONYN ATTRIBUTESYN
                 MISSCHKYN RECALCVISITYN XOVARSFORPGYN;

   %do loopi=1 %to 12;
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
                 DERIVATIONYN ATTRIBUTESYN MISSCHKYN
                 RECALCVISITYN XOVARSFORPGYN;

   %do loopi=1 %to 10;
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
      %if %tu_nobs(&dsetin) lt 0 %then
      %do;
         %put %str(RTE)RROR: &sysmacroname.: The dataset DSETIN(=&dsetin) does not exist.;
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
   / NORMAL PROCESSING
   /----------------------------------------------------------------------------*/

   /*
   / Initialise counter for appending to temporary dataset names for the
   / purpose of tracking datasets through a number of optional sequential
   / data processing steps.
   /----------------------------------------------------------------------------*/

   %let i = 1;

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
      %if %tu_chkvarsexist(&prefix._ds1, &reftim) ne %then
      %do;
         %put %str(RTW)ARNING: &sysmacroname : Variable REFTIM(=&reftim) does not exist in DSETIN (=&dsetin) and it will not be used to recalculate visit.;
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
         agemonthsyn       = &agemonthsyn,           /* Calculation of age in months */
         ageweeksyn        = &ageweeksyn,            /* Calculation of age in weeks */
         agedaysyn         = &agedaysyn,             /* Calculation of age in days */
         refdateoption     = &refdateoption,         /* Reference date source option */
         refdatevisitnum   = &refdatevisitnum,       /* Reference date visit number */
         refdatesourcedset = &refdatesourcedset,     /* Reference date source dataset */
         refdatesourcevar  = &refdatesourcevar,      /* Reference date source variable */
         refdatedsetsubset = &refdatedsetsubset      /* Where clause applied to source dataset */
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
         visitdset = &visitdset,
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
         dsetout = &prefix._ds%eval(&i+1),
         tmslicedset = &tmslicedset
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
         dsetin    = &prefix._ds&i,
         dsetout   = &prefix._ds%eval(&i+1),
         randalldset = &randalldset,
         randdset  = &randdset,
         trtcdinf  = &trtcdinf,
         ptrtcdinf = &ptrtcdinf
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

         demodset          = &demodset,              
         exposuredset      = &exposuredset,  
         randalldset       = &randalldset,   
         randdset          = &randdset,      
         tmslicedset       = &tmslicedset,   
         visitdset         = &visitdset,     

         domaincode        = LI,
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
         formatnamesdset = &formatnamesdset,
         decodepairs     = &decodepairs,
         decoderename    = &decoderename
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
      data  %unquote(&dsetout);
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

%mend tc_limaging;


