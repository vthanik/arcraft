/*******************************************************************************
|
| Macro Name:      tc_lab
|
| Macro Version:   6 build 1
|
| SAS Version:     8.2
|
| Created By:      Mark Luff/Eric Simms
|
| Date:            17-May-2004
|
| Macro Purpose:   Laboratory data wrapper macro
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                            REQ/OPT  DEFAULT
| -----------------  -------------------------------------  -------  ----------
| DSETIN             Specifies the LAB-format SI dataset    REQ      DMDATA.LAB
|                    which needs to be transformed into a 
|                    LAB-format A&R dataset.
|                    Valid values: valid dataset name
|
| DSETOUT            Specifies the name of the output       REQ      ARDATA.LAB
|                    dataset to be created.
|                    Valid values: valid dataset name
|
| BASELINETYPE       Calculation of baseline option         REQ      LAST		** GK001 **
|                    when there are multiple records
|                    following into baseline range.
|                    Valid values:
|                    FIRST-  First non-missing baseline
|                            record is used and marked as
|                            baseline when data are sorted 
|                            in chronical order. Others are
|                            marked as pre-therapy
|
|                    LAST-   Last non-missing baseline
|                            record is used and marked as 
|                            baseline when data are sorted
|                            in chronical order. Others are
|                            marked as pre-therapy.
|                            
|
|                    MEAN-   Mean value of baseline records
|                            is used as baseline. All 
|                            baseline records are marked as
|                            baseline.
|
|                    MEDIAN- Median value of baseline 
|                            records is used as baseline. 
|                            All baseline  records are
|                            marked as baseline.
|
| COMMONVARSYN       Call %tu_common to add common          REQ      Y
|                    variables?
|                    Valid values: Y, N
|
| TREATVARSYN        Call %tu_rantrt to add treatment       REQ      Y
|                    variables?
|                    Valid values: Y, N
|
| TIMESLICINGYN      Call %tu_timslc to add timeslicing     REQ      Y
|                    variables?
|                    Valid values: Y, N
|
| DATETIMEYN         Call %tu_datetm to derive datetime     REQ      Y
|                    variables?
|                    Valid values: Y, N
|
| DECODEYN           Call %tu_decode to decode coded        REQ      Y
|                    variables?
|                    Valid values: Y, N
|
| LABFLAGGINGYN      Call %tu_labfg to perform lab          REQ      Y
|                    flagging and lab value conversion?
|                    Valid values: Y, N
|
| LBGRDYN            Call %tu_lbgrd to assign National      REQ      N
|                    Cancer Institute Common Terminology 
|                    Criteria (Toxicity) Grade (NCI-CTC) 
|                    Lab flagging and lab value 
|                    conversion?
|                    Valid values: Y, N
|
| DERIVATIONYN       Call %tu_derive to perform specific    REQ      Y
|                    derivations for this domain code (AE)?
|                    Valid values: Y, N
|
| ATTRIBUTESYN       Call %tu_attrib to reconcile the       REQ      Y
|                    A&R-defined attributes to the planned 
|                    A&R dataset?
|                    Valid values: Y, N
|
| MISSCHKYN          Call %tu_misschk to print RTWARNING    REQ      Y
|                    messages for each variable in 
|                    &DSETOUT which has missing values
|                    on all records.                    
|                    Valid values: Y, N.  
|
| RECALCVISITYN      Call %tu_recalcvisit to recalculate    REQ      N
|                    VISIT based on the AE start date?
|                    Valid values: Y, N
|
| XOVARSFORPGYN      Specifies whether to derive crossover stydy     N
|                    specific variables for parallel study                 
|                    Valid values: Y, N.                   
|
| AGEMONTHSYN        Calculate age in months?               OPT      N
|                    Valid values: Y, N
|
| AGEWEEKSYN         Calculate age in weeks?                OPT      N
|                    Valid values: Y, N
|
| AGEDAYSYN          Calculate age in days?                 OPT      N
|                    Valid values: Y, N
|
| CTCDSET            Specifies the SI dataset which         OPT      dmdata.lbgrade
|                    contains the CTCAE range information
|
| CTCVER             Version of CTCAE to use                OPT      CTCAE03.00
|
| REFDAT             Specify a reference date variable name OPT      LBDT
|                    to pass to %tu_recalcvisit to  
|                    calculate the visit. Will be checked  
|                    in %tu_recalcvisit
|
| REFTIM             Specify a reference time variable name OPT      LBACTTM
|                    to pass to %tu_recalcvisit to  
|                    calculate the visit. Will be checked  
|                    in %tu_recalcvisit
|
| REFDATEOPTION      The reference date will be used in     OPT      TREAT
|                    the calculation of the age values.
|                    Valid values:
|                    TREAT - Trt start date from 
|                            DMDATA.EXPOSURE
|                    VISIT - Visit date from 
|                            DMDATA.VISIT
|                    RAND  - Randomization date from 
|                            DMDATA.RAND
|                    OTHER - Date from the 
|                            REFDATESOURCEVAR variable on
|                            the REFDATESOURCEDSET dataset
|
| REFDATEVISITNUM    Specific visit number at which         OPT      (Blank)
|                    reference date is to be taken.  
|                    Required if REFDATEOPTION is VISIT.
|
| REFDATESOURCEDSET  Required if REFDATEOPTION is OTHER.    OPT      (Blank)
|                    Use the variable REFDATESOURCEVAR 
|                    from the REFDATESOURCEDSET.
|
| REFDATESOURCEVAR   Required if REFDATEOPTION is OTHER.    OPT      (Blank)
|                    Use the variable REFDATESOURCEVAR 
|                    from the REFDATESOURCEDSET.
|
| REFDATEDSETSUBSET  Where clause applied to source         OPT      (Blank)
|                    dataset. May be used regardless of the 
|                    value of REFDATEOPTION in order to 
|                    better select the reference date.
|
| TRTCDINF           Name of pre-existing informat to       OPT      (Blank)
|                    derive TRTCD from TRTGRP.
|
| PTRTCDINF          Name of pre-existing informat to       OPT      (Blank)
|                    derive PTRTCD from PTRTGRP.
|
| DSPLAN             Specifies the path and file name of    OPT      &g_dsplanfile 
|                    the HARP A&R dataset metadata. This 
|                    will define the attributes to use 
|                    to define the A&R dataset.
|
| DSETTEMPLATE       Specifies the name to give to the      OPT      (Blank)
|                    empty dataset containing the variables 
|                    and attributes desired for the A&R 
|                    dataset.
|
| SORTORDER          Specifies the sort order desired for   OPT      (Blank)
|                    the A&R dataset.
|
| FORMATNAMESDSET    Specifies the name of a dataset which  OPT      (Blank)
|                    contains VAR_NM (a variable name of a 
|                    code) and format_nm (the name of a 
|                    format to produce the decode).
|
| NRFGYN             Perform Normal Range flagging?         OPT      Y
|                    Valid values: Y, N
|
| BSFGYN             Perform Change from Baseline           OPT      Y
|                    flagging?
|                    Valid values: Y, N
|
| CCFGYN             Perform Clinical Concern  flagging?    OPT      Y
|                    Valid values: Y, N
|
| CONVERTYN          Perform Laboratory value and normal    OPT      Y
|                    range conversion to standard units?
|                    Valid values: Y, N
|
| BASELINEYN         Perform calculation of baseline?       OPT      Y
|                    Valid values: Y, N 
|
| LABCRITDSET        Specifies the SI dataset which         OPT      dmdata.labcrit
|                    contains the lab flagging criteria.
|                    Valid values: valid dataset name
|
| LBTESTCDDSET       Specifies the SI dataset which         OPT      dmdata.lbtestcd
|                    contains the lab test code 
|                    Valid values: valid dataset name
|
| NRDSET             Specifies the SI dataset which         OPT      dmdata.nr
|                    contains the normal range information.
|                    Valid values: valid dataset name
|
| DEMODSET           SI Demography dataset.                 OPT      dmdata.demo
|                    Valid values: valid dataset name
|
| STMEDDSET          SI Exposure dataset.                   OPT      dmdata.exposure
|                    Valid values: valid dataset name
|
| STMEDDSETSUBSET    WHERE clause applied to study          OPT      (Blank)
|                    medication dataset.
|
| CONVDSET           Specifies the SI dataset which         OPT      dmdata.conv
|                    contains the conversion factors.
|                    Valid values: valid dataset name
|
| BASELINEOPTION     Calculation of baseline option.      OPT      DATE
|                       Valid values:
|                    
|                       DATE   - Select baseline records based on lab collection
|                                date (LBDT) and visit number (VISITNUM) compared
|                                to study medication start date (EXSTDT) and
|                                visit number (VISITNUM). Note that when start
|                                date and visit of medication is the same as lab
|                                date and visit, it is regarded as post-baseline.
|                    
|                       RELDAY - Select baseline records by relative days. The
|                                parameter RELDAYS must contain a positive number.
|                    
|                       VISIT  - Select baseline records specified by VISITNUM codes
|                                passed in the parameters STARTVISNUM and
|                                ENDVISNUM.
|                    
|                       TIME   - Select baseline records based on lab collection
|                                date (LBDT) and time (LBACTTM) compared to study
|                                medication start date (EXSTDT) and time (EXSTTM).
|                    
| RELDAYS            Number of days prior to start of     OPT      (Blank)
|                    study medication, used to identify
|                    records to be considered as
|                    baseline. Required if
|                    BASELINEOPTION is RELDAY.
|                    
| STARTVISNUM        VISITNUM value for start of range    OPT      (Blank)
|                    to identify records to be
|                    considered as baseline. Required if
|                    BASELINEOPTION is VISIT.
|                    
| ENDVISNUM          VISITNUM value for end of range to   OPT      (Blank)
|                    identify records to be considered
|                    as baseline. Required if
|                    BASELINEOPTION is VISIT.
|
| FLAGGINGSUBSET     IF clause to identify records to be    OPT      %str(lbcat in
|                    flagged.                                        ('CHEM','HAEM'))
|
| DGCD               LABCRIT compound identifier.           OPT      (Blank)
|
| STUDYID            LABCRIT study identifier.              OPT      (Blank)
|
| NODERIVEVARS       List of variables not to derive.       OPT      (Blank)
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
| -----------------  -------------------------------------  -------  ----------
|
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
|(@) tu_calctpernum
|(@) tu_chkvarsexist
|(@) tu_common
|(@) tu_datetm
|(@) tu_decode
|(@) tu_derive
|(@) tu_labfg
|(@) tu_lbgrd
|(@) tu_misschk
|(@) tu_nobs
|(@) tu_putglobals
|(@) tu_rantrt
|(@) tu_recalcvisit
|(@) tu_tidyup
|(@) tu_timslc
|
| Example:
|    %tc_lab(
|         refdateoption   = visit,
|         refdatevisitnum = 10,
|         dsplan          = &g_dsplanfile 
|         );
|
|******************************************************************************
| Change Log
|
| Modified By:              Yongwei Wang
| Date of Modification:     27-Apr-2005 
| New version/draft number: 1/2
| Modification ID:          YW001
| Reason For Modification:  Changed the RTERROR message while &RECALCVISITYN is
|                           not Y or N
|   
| Modified By:              Yongwei Wang
| Date of Modification:     05-May-2005
| New version/draft number: 1/3
| Modification ID:          YW003
| Reason For Modification:  Passed 4 parameters BASELINEOPTION, ENDVISNUM
|                           STARTVISNUM and RELDAY to %tu_labfg
|
| Modified By:              Yongwei Wang
| Date of Modification:     18-Oct-05
| New version/draft number: 2/1
| Modification ID:          YW002
| Reason For Modification:  1. Added new parameter XOVARSFORPGYN. It is 
|                              validated and passed to %tu_derive
|                           2. Added call of %tu_calctpernum
|
| Modified By:              Yongwei Wang
| Date of Modification:     27-Feb-07
| New version/draft number: 3/1
| Modification ID:          YW003
| Reason For Modification:  Based on change request HRT0154
|                           1. Added call of %tu_lbgrd
|                           2. Added paremater LBGRDYN to decide if %tu_lbgrd
|                              should be called
|                           3. Added parameter CTCDSET and CTCVER to pass to
|                              %tu_lbgrd
|
| Modified By:              Yongwei Wang
| Date of Modification:     17-Sep-07
| New version/draft number: 4/1
| Modification ID:          YW004
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
|
| Modified By:              Gail Knowlton
| Date of Modification:     23-Jul-08
| New version/draft number: 5/1
| Modification ID:			 GK001          
| Reason For Modification:  Surfaced 'BASELINETYPE' - a new parameter for tu_baseln
|								 (Passed to tu_labfg)
|
| Modified By:              Shan Lee
| Date of Modification:     01-May-09
| New version/draft number: 6/1
| Modification ID:          SL001
| Reason For Modification:  HRT0219 - call TU_DERIVE before calling TU_LABFG.
*******************************************************************************/
%macro tc_lab (
     dsetin            = DMDATA.LAB,      /* Input dataset name */
     dsetout           = ARDATA.LAB,      /* Output dataset name */
     convdset          = DMDATA.CONV,     /* Conversion dataset name */     
     labcritdset       = DMDATA.LABCRIT,  /* Lab flagging criteria dataset name */
     lbtestcddset      = DMDATA.LBTESTCD, /* Lab test code dataset name */
     nrdset            = DMDATA.NR,       /* Normal range dataset name */
     demodset          = dmdata.demo,     /* Name of DEMO dataset to use */        
     enroldset         = dmdata.enrol,    /* Name of ENROL dataset to use */       
     exposuredset      = dmdata.exposure, /* Name of EXPOSURE dataset to use */    
     investigdset      = dmdata.investig, /* Name of RACE dataset to use */        
     racedset          = dmdata.race,     /* Name of RACE dataset to use */        
     randalldset       = dmdata.randall,  /* Name of RANDALL dataset to use */     
     randdset          = dmdata.rand,     /* Name of RAND dataset to use */        
     tmslicedset       = dmdata.tmslice,  /* Name of TMSLICE dataset to use */      
     visitdset         = dmdata.visit,    /* Name of VISIT dataset to use */       
     baselinetype      = LAST,            /* Select method of calculating baseline, when there are multiple baseline obs. */		
     commonvarsyn      = Y,               /* Add common variables */
     treatvarsyn       = Y,               /* Add treatment variables */
     timeslicingyn     = Y,               /* Add timeslicing variables */
     datetimeyn        = Y,               /* Derive datetime variables */
     decodeyn          = Y,               /* Decode coded variables */
     labflaggingyn     = Y,               /* Lab flagging and lab value conversion */
     lbgrdyn           = N,               /* assign National Cancer Institute Common Terminology Criteria (Toxicity) Grade */
     derivationyn      = Y,               /* Dataset specific derivations */
     attributesyn      = Y,               /* Reconcile A&R dataset with planned A&R dataset */
     misschkyn         = Y,               /* Print warning message for variables in &DSETOUT with missing values on all records */
     xovarsforpgyn     = N,               /* If derive crossover stydy specific variables for parallel study */
     recalcvisityn     = N,               /* Recalculate VISIT */
     agemonthsyn       = N,               /* Calculation of age in months */
     ageweeksyn        = N,               /* Calculation of age in weeks */
     agedaysyn         = N,               /* Calculation of age in days */
     ctcdset           = DMDATA.LBGRADE,  /* CTCAE Normal range dataset name */
     ctcver            = CTCAE03.00,      /* CTCAE version */     
     refdat            = lbdt,            /* Reference data variable name for recalculating visit and calculating treatment period */
     reftim            = lbacttm,         /* Reference data variable name for recalculating visit and calculating treatment period */
     refdateoption     = TREAT,           /* Reference date source option */
     refdatevisitnum   = ,                /* Reference date visit number */
     refdatesourcedset = ,                /* Reference date source dataset */
     refdatesourcevar  = ,                /* Reference date source variable */
     refdatedsetsubset = ,                /* Where clause applied to source dataset */     
     dyrefdateoption    = ,               /* Reference date source option for the calculation of Study Day values in tu_derive Reference date source option for tu_derive.*/                                  
     dyrefdatedsetsubset= ,               /* WHERE clause applied to source dataset for tu_derive. */            
     dyrefdatesourcedset= ,               /* Reference date source dataset for tu_derive. */                                            
     dyrefdatesourcevar = ,               /* Reference date source variable for tu_derive. */                                           
     dyrefdatevisitnum  = ,               /* Specific visit number at which reference date is to be taken for tu_derive. */         
     trtcdinf          = ,                /* Informat to derive TRTCD from TRTGRP */
     ptrtcdinf         = ,                /* Informat to derive PTRTCD from PTRTGRP */
     dsplan            = &g_dsplanfile,   /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
     dsettemplate      = ,                /* Planned A&R dataset template name */
     sortorder         = ,                /* Planned A&R dataset sort order */
     decodepairs       = ,                /* code and decode variables in pair */
     formatnamesdset   = ,                /* Format names dataset name */
     nrfgyn            = Y,               /* F1 Normal Range flagging */
     bsfgyn            = Y,               /* F2 Change from Baseline flagging */
     ccfgyn            = Y,               /* F3 Clinical Concern flagging */
     convertyn         = Y,               /* Laboratory value and normal range conversion */
     baselineyn        = Y,               /* Calculation of baseline */
     stmeddset         = DMDATA.EXPOSURE, /* Study medication dataset name */
     stmeddsetsubset   = ,                /* Where clause applied to study medication dataset */
     flaggingsubset    = %STR(LBCAT IN ('CHEM','HAEM')), /* IF clause to identify records to be flagged */
     baselineoption    = DATE,            /* Calculation of baseline option */
     reldays           = ,                /* Number of days prior to start of study medication */
     startvisnum       = ,                /* VISITNUM value for start of baseline range */
     endvisnum         = ,                /* VISITNUM value for end of baseline range */
     dgcd              = ,                /* LABCRIT compound identifier */
     studyid           = ,                /* LABCRIT study identifier */
     noderivevars      =                  /* List of variables not to derive */
        );

 /*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion;
 %let MacroVersion = 6 build 1;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals() 

 %local prefix;
 %let prefix = _tc_lab;   /* Root name for temporary work datasets */

 /*
 / PARAMETER VALIDATION
 /----------------------------------------------------------------------------*/

 %let dsetin            = %nrbquote(&dsetin);
 %let dsetout           = %nrbquote(&dsetout);

 %let commonvarsyn      = %nrbquote(%upcase(%substr(&commonvarsyn, 1, 1)));
 %let treatvarsyn       = %nrbquote(%upcase(%substr(&treatvarsyn, 1, 1)));
 %let timeslicingyn     = %nrbquote(%upcase(%substr(&timeslicingyn, 1, 1)));
 %let datetimeyn        = %nrbquote(%upcase(%substr(&datetimeyn, 1, 1)));
 %let decodeyn          = %nrbquote(%upcase(%substr(&decodeyn, 1, 1)));
 %let labflaggingyn     = %nrbquote(%upcase(%substr(&labflaggingyn, 1, 1)));
 %let lbgrdyn           = %nrbquote(%upcase(%substr(&lbgrdyn, 1, 1)));
 %let derivationyn      = %nrbquote(%upcase(%substr(&derivationyn, 1, 1)));
 %let attributesyn      = %nrbquote(%upcase(%substr(&attributesyn, 1, 1)));
 %let misschkyn         = %nrbquote(%upcase(%substr(&misschkyn, 1, 1))); 
 %let recalcvisityn     = %nrbquote(%upcase(%substr(&recalcvisityn, 1, 1)));
 %let xovarsforpgyn     = %nrbquote(%upcase(%substr(&xovarsforpgyn, 1, 1)));
 
 /*
 / Check for required parameters.
 /----------------------------------------------------------------------------*/

 %if &dsetin eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter DSETIN is required.;
    %let g_abort=1;
 %end;

 %if &dsetout eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter DSETOUT is required.;
    %let g_abort=1;
 %end;

 %if &commonvarsyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter COMMONVARSYN is required.;
    %let g_abort=1;
 %end;

 %if &treatvarsyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter TREATVARSYN is required.;
    %let g_abort=1;
 %end;

 %if &timeslicingyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter TIMESLICINGYN is required.;
    %let g_abort=1;
 %end;

 %if &datetimeyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter DATETIMEYN is required.;
    %let g_abort=1;
 %end;

 %if &decodeyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter DECODEYN is required.;
    %let g_abort=1;
 %end;

 %if &labflaggingyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter LABFLAGGINGYN is required.;
    %let g_abort=1;
 %end;

 %if &derivationyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter DERIVATIONYN is required.;
    %let g_abort=1;
 %end;

 %if &attributesyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter ATTRIBUTESYN is required.;
    %let g_abort=1;
 %end;
 
 %if &misschkyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter MISSCHKYN is required.;
    %let g_abort=1;
 %end;
 
 %if &recalcvisityn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter RECALCVISITYN is required.;
    %let g_abort=1;
 %end;
 
 %if &xovarsforpgyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter XOVARSFORPGYN is required.;
    %let g_abort=1;
 %end;

 %if &lbgrdyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter LBGRDYN is required.;
    %let g_abort=1;
 %end;
 
 /*
 / Check for valid parameter values.
 /----------------------------------------------------------------------------*/

 %if &commonvarsyn ne Y and &commonvarsyn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: COMMONVARSYN should be either Y or N.;
    %let g_abort=1;
 %end;

 %if &treatvarsyn ne Y and &treatvarsyn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: TREATVARSYN should be either Y or N.;
    %let g_abort=1;
 %end;

 %if &timeslicingyn ne Y and &timeslicingyn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: TIMESLICINGYN should be either Y or N.;
    %let g_abort=1;
 %end;

 %if &datetimeyn ne Y and &datetimeyn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: DATETIMEYN should be either Y or N.;
    %let g_abort=1;
 %end;

 %if &decodeyn ne Y and &decodeyn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: DECODEYN should be either Y or N.;
    %let g_abort=1;
 %end;

 %if &labflaggingyn ne Y and &labflaggingyn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: LABFLAGGINGYN should be either Y or N.;
    %let g_abort=1;
 %end;

 %if &derivationyn ne Y and &derivationyn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: DERIVATIONYN should be either Y or N.;
    %let g_abort=1;
 %end;

 %if &attributesyn ne Y and &attributesyn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: ATTRIBUTESYN should be either Y or N.;
    %let g_abort=1;
 %end;
 
 %if &misschkyn ne Y and &misschkyn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: MISSCHKYN should be either Y or N.;
    %let g_abort=1;
 %end; 
 
 %if &recalcvisityn ne Y and &recalcvisityn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: RECALCVISITYN should be either Y or N.;
    %let g_abort=1;
 %end;
 
 %if &xovarsforpgyn ne Y and &xovarsforpgyn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: XOVARSFORPGYN should be either Y or N.;
    %let g_abort=1;
 %end;

 %if &lbgrdyn ne Y and &lbgrdyn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: LBGRDYN should be either Y or N.;
    %let g_abort=1;
 %end;
 
 %if %qupcase(&g_stype) eq XO %then %let XOVARSFORPGYN=Y;

 /*
 / Check for existing datasets.
 /----------------------------------------------------------------------------*/

 %let lbcat_exist=0;
 
 %if %nrbquote(&dsetin) ne %then
 %do;  
    %if %tu_nobs(&dsetin) lt 0 %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: The dataset DSETIN(=&dsetin) does not exist.;
       %let g_abort=1;
    %end;
    %else %do;
       data &prefix._ds1;
            set %unquote(&dsetin);
       run;
       %if %tu_chkvarsexist(&prefix._ds1, LBCAT) eq %then %let lbcat_exist=1;
    %end;
 %end;
 
 /*
 / YW001: Check where the LBCAT should come from.
 / If it does not exist in &dsetin, check that &lbtestcddset should not be blank
 / and LBCAT should exist in &lbtestcddset.
 /----------------------------------------------------------------------------*/
         
 %if &lbcat_exist %then 
 %do;
    proc sql noprint;
       select count(lbcat) into :lbcat_exist
       from &dsetin
       where lbcat is not null;
    quit;
 %end;
 
 %if not &lbcat_exist %then 
 %do;        
    %if %nrbquote(&lbtestcddset) ne %then
    %do;
       %if %tu_nobs(&lbtestcddset) lt 0 %then
       %do;
          %put %str(RTE)RROR: &sysmacroname: The dataset LBTESTCDDSET(=&lbtestcddset) does not exist.;
          %let g_abort=1;
       %end;                 
    %end;
    %else %do;
       %put %str(RTE)RROR: &sysmacroname: Value of parameter LBTESTCDDSET is blank. It is required if LBCAT does not exist in DSETIN(=&dsetin).;
       %let g_abort=1;      
    %end;    
 %end;

 /*
 / If the input dataset name is the same as the output dataset name,
 / write an error to the log.
 /----------------------------------------------------------------------------*/

 %if %qscan(&dsetin, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
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
 / and &REFTIM is not blank, check if &REFTIM exists in &DSETIN. If not, write 
 / a RTWARNING message to the log and set &REFTIM to blank, but do not abort
 /----------------------------------------------------------------------------*/
 
 %if ( (&recalcvisityn eq Y) or (&xovarsforpgyn eq Y) ) and (%nrbquote(&reftim) ne) %then
 %do;
    %if %tu_chkvarsexist(&prefix._ds1, &reftim) ne %then
    %do;
       %put %str(RTW)ARNING: &sysmacroname: Variable REFTIM(=&reftim) does not exist in DSETIN (=&dsetin) and it will not be used to recalculate visit.;
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
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/

 /*
 / Initialise counter for appending to temporary dataset names for the
 / purpose of tracking datasets through a number of optional sequential
 / data processing steps.
 /----------------------------------------------------------------------------*/

 %local i;
 %let i = 1;

 /*
 / UNSCHEDULED LAB SAMPLES.
 /----------------------------------------------------------------------------*/

 %local visitnum ptmnum lbacttm;
 
 %let visitnum=;
 %let ptmnum=;
 %let lbacttm=;
 
 %if %tu_chkvarsexist(&prefix._ds1, visitnum) eq  %then %let visitnum=visitnum;
 %if %tu_chkvarsexist(&prefix._ds1, ptmnum)   eq  %then %let ptmnum=ptmnum;
 %if %tu_chkvarsexist(&prefix._ds1, lbacttm)  eq  %then %let lbacttm=lbacttm;

 /*
 / Process unscheduled visits and ptmnum
 / YW001: Modified the process of processing unscheduled visits and unscheduled
 / time point. The two process are similar. The processes are as follows:
 / 1. If &VISITDSET exists, concatinate the VISITNUM and PTMNUM in it with
 /    the input data set; Rename VISITDT/VISITTM to LBDT/LBACTTM; Add a new
 /    variable __flag__ to mark the source of the record.
 / 2. Sort the data set by lbdate and lbacttm for each subjid
 / 3. For each subjid, keep the first unmissing scheduled visit/ptmnum
 / 4. If unscheduled is found and the visit/ptmnum has not been modified
 /    for the same date/time, set it to previous visit/ptmnum plus one;
 /    if it is already been modified, set to previous visit/ptmnum.
 / 5. If scheduled visit/ptmnum is found, keep it.
 /----------------------------------------------------------------------------*/
 
 %if ( %nrbquote(&visitnum) ne ) and ( %nrbquote(&visitdset) ne ) %then
 %do;
    %if %sysfunc(exist(%qscan(&visitdset, 1, %str(%()))) %then
    %do;
       data &prefix.visit;
          set %unquote(&visitdset);
       run;
    
       %if ( %nrbquote(&lbacttm) ne ) and ( %tu_chkvarsexist(&prefix.visit, visittm) eq ) 
       %then %let visittm=visittm;
       %else %let visittm=;
              
       data &prefix._ds%eval(&i + 1);
          set &prefix._ds&i (in=__in__)
             &prefix.visit (rename=(visitdt=lbdt %if %nrbquote(&visittm) ne %then &visittm=&lbacttm;)
             keep=studyid subjid visitnum visitdt &visittm);
          if __in__ then __flag__=0;
          else do;
             __flag__=1;   
             if missing(visitnum) then delete;
             if missing(lbdt) then delete;
          end;
       run;      
                                 
       %let i = %eval(&i + 1);
    
    %end;
    %else %do;    
       %put %str(RTN)OTE: &sysmacroname: VISITDSET(=&visitdset) does not exist and it will not be used to solve unscheduled visit.;
    %end;
 %end; /* %if ( %nrbquote(&visitnum) ne ) and ( %nrbquote(&visitdset) ne ) */

 %if %nrbquote(&visitnum.&ptmnum) ne %then
 %do;
           
    proc sort data=&prefix._ds&i out=&prefix._ds%eval(&i + 1);
       by studyid subjid lbdt &lbacttm &visitnum &ptmnum;
    run;
    
    %let i = %eval(&i + 1);

    data &prefix._ds%eval(&i + 1);
       set &prefix._ds&i;
       by studyid subjid lbdt &lbacttm &visitnum &ptmnum;                 
       retain __prevnum__ __prepnum__;
       drop   __prevnum__ __prepnum__ __flag__;
        
       if first.subjid then
       do; 
          __prevnum__=0.00;    
          __prepnum__=0.00;      
       end;
          
       if (__flag__ eq 1) and (_N_ eq 1) then __flag__=1;
                 
       /* Modify unschedule PTNUUM values */
       %if %nrbquote(&ptmnum) ne %then
       %do;                                            
          %if %nrbquote(&visitnum) ne %then
          %do;
             if first.visitnum and ( visitnum ne 999) then __prepnum__=0.00;
          %end;
         
          if __flag__ eq 1 then ;
          else if ptmnum ne 999 then __prepnum__=ptmnum;
          else do;          
             if 
                %if %nrbquote(&lbacttm) ne %then first.lbacttm;
                %else first.lbdt;               
             then ptmnum=__prepnum__ + .01;
             else ptmnum=__prepnum__;
             
             __prepnum__=ptmnum;  
          end;            
  
       %end;
       
       /* Modify unschedule VISITNUM values */ 
       %if %nrbquote(&visitnum) ne %then
       %do;                
          if visitnum ne 999 then __prevnum__=visitnum;
          else do;
             if 
                %if %nrbquote(&lbacttm) ne %then first.lbacttm;
                %else first.lbdt;               
             then visitnum=__prevnum__ + .01;
             else visitnum=__prevnum__;
             
             __prevnum__=visitnum;  
          end;
          
          if __flag__ eq 1 then delete;          
       %end;                                    

    run;    
    
    %let i = %eval(&i + 1);

 %end;  /* end-if on %nrbquote(&visitnum.&ptmnum) ne */
  
 /*
 / YW001: Merge LBCAT in.
 /----------------------------------------------------------------------------*/
 
 %if not &lbcat_exist %then
 %do;
    proc sort data=&prefix._ds&i out=&prefix._ds%eval(&i+1);
       by lbtestcd;
    run;
    
    %let i=%eval(&i + 1);
    
    proc sort data=&lbtestcddset out=&prefix._testcd;
      by lbtestcd;            
    run;
    
    data &prefix._ds%eval(&i+1);
       merge &prefix._ds&i  (in=__in__)
             &prefix._testcd;
       by lbtestcd;
       if __in__;
    run;
    
    %let i=%eval(&i + 1);    
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
 / Dataset specific derivations.
 / 
 / SL001 - TU_DERIVE should be called before TU_LABFG, because macros called
 / by TU_LABFG (TU_NRFG, TU_BSFG and TU_CCFG) assume that the following
 / variables already exist: LBAGE, LBAGEMO, LBAGEWK and LBAGEDY. However,
 / these variables are not SI variables, but are created when TU_DERIVE is 
 / invoked.
 /----------------------------------------------------------------------------*/

 %if &derivationyn eq Y %then
 %do;
    %tu_derive (
         dsetin            = &prefix._ds&i,
         dsetout           = &prefix._ds%eval(&i+1),
         
         demodset          = &demodset,              /* Demography dataset */
         exposuredset      = &exposuredset,  
         randalldset       = &randalldset,   
         randdset          = &randdset,      
         tmslicedset       = &tmslicedset,   
         visitdset         = &visitdset,     
                            
         domaincode        = lb,                     /* Domain Code - type of dataset */
         noderivevars      = &noderivevars,          /* List of variables not to derive */
         refdateoption     = &dyrefdateoption,         /* Reference date source option */
         refdatevisitnum   = &dyrefdatevisitnum,       /* Reference date visit number */
         refdatesourcedset = &dyrefdatesourcedset,     /* Reference date source dataset */
         refdatesourcevar  = &dyrefdatesourcevar,      /* Reference date source variable */
         refdatedsetsubset = &dyrefdatedsetsubset,     /* Where clause applied to source dataset */
         xovarsforpgyn     = &xovarsforpgyn     
    );

    %let i = %eval(&i + 1);
 %end;

 /*
 / Lab flagging and lab value conversion.
 /----------------------------------------------------------------------------*/

 %if &labflaggingyn eq Y %then
 %do;
    %tu_labfg (
         dsetin          = &prefix._ds&i,
         dsetout         = &prefix._ds%eval(&i+1),
 		  baselinetype    = &baselinetype,		/* GK001 */	
         nrfgyn          = &nrfgyn,
         bsfgyn          = &bsfgyn,
         ccfgyn          = &ccfgyn,
         convertyn       = &convertyn,
         baselineyn      = &baselineyn,
         labcritdset     = &labcritdset,
         nrdset          = &nrdset,
         demodset        = &demodset,
         stmeddset       = &stmeddset,
         stmeddsetsubset = &stmeddsetsubset,
         convdset        = &convdset,
         flaggingsubset  = &flaggingsubset,
         dgcd            = &dgcd,
         baselineoption  = &baselineoption, 
         reldays         = &reldays,     
         startvisnum     = &startvisnum,     
         endvisnum       = &endvisnum,              
         studyid         = &studyid
    );

    %let i = %eval(&i + 1);
 %end;
 
 /*
 / Call %tu_lbgrd to assign National Cancer Institute Common Terminology 
 / Criteria (Toxicity) Grade (NCI-CTC) Lab flagging and lab value conversion
 /----------------------------------------------------------------------------*/

 %if &lbgrdyn eq Y %then
 %do;
    %tu_lbgrd (
       dsetin          = &prefix._ds&i,                  
       dsetout         = &prefix._ds%eval(&i+1),                   
       ctcdset         = &ctcdset,    
       ctcver          = &ctcver,        
       dsplan          = &dsplan,                 
       formatnamesdset = &formatnamesdset            
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
         dsetin          = &prefix._ds&i,
         dsetout         = &dsetout,
         dsplan          = &dsplan,
         dsettemplate    = &dsettemplate,
         sortorder       = &sortorder
    );
 %end;

 %else
 %do;
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
         dsetin        = &dsetout
    );
 %end;

 /*
 / Delete temporary datasets used in this macro.
 /----------------------------------------------------------------------------*/

 %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tc_lab;

