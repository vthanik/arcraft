/*******************************************************************************
|
| Macro Name:      tc_mstone
|
| Macro Version:   2
|
| SAS Version:     8.2
|
| Created By:      Mark Luff / Eric Simms
|
| Date:            30-Jun-2004
|
| Macro Purpose:   MSTONE wrapper macro
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                            REQ/OPT  DEFAULT
| -----------------  -------------------------------------  -------  ----------
| EXPOSUREDSET       Specifies the EXPOSURE-format SI       REQ      DMDATA.EXPOSURE
|                    dataset which needs to be transformed 
|                    into an MSTONE-format A&R dataset.
|                    Valid values: valid dataset name 
|
| VISITDSET          Specifies the VISIT-format SI dataset  REQ      DMDATA.VISIT
|                    which will be used along with the 
|                    EXPOSUREDSET to produce an 
|                    MSTONE-format A&R dataset.
|                    Valid values: valid dataset name    
|
| DSETOUT            Specifies the name of the output       REQ      ARDATA.MSTONE
|                    dataset to be created.
|                    Valid values: valid dataset name 
|
| COMMONVARSYN       Call %tu_common to add common          REQ      Y
|                    variables?
|                    Valid values: Y, N
|
| TREATVARSYN        Call %tu_rantrt to add treatment       REQ      Y
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
| DERIVATIONYN       Call %tu_derive to perform specific    REQ      Y
|                    derivations for this domain code (MS)?
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
| AGEMONTHSYN        Calculate age in months?               OPT      N
|                    Valid values: Y, N
|
| AGEWEEKSYN         Calculate age in weeks?                OPT      N
|                    Valid values: Y, N
|
| AGEDAYSYN          Calculate age in days?                 OPT      N
|                    Valid values: Y, N
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
| REFDATESOURCEDSET  Use the variable REFDATESOURCEVAR      OPT      (Blank)
|                    from the REFDATESOURCEDSET.
|                    Required if REFDATEOPTION is OTHER. 
|
| REFDATESOURCEVAR   Use the variable REFDATESOURCEVAR      OPT      (Blank)
|                    from the REFDATESOURCEDSET.
|                    Required if REFDATEOPTION is OTHER.  
|
| REFDATEDSETSUBSET  WHERE clause applied to source         OPT      (Blank)
|                    dataset.  May be used regardless of 
|                    the value of REFDATEOPTION in order 
|                    to better select the reference date.
|
| TRTCDINF           Name of pre-existing informat to       OPT      (Blank)
|                    derive TRTCD from TRTGRP.
|
| PTRTCDINF          Name of pre-existing informat to       OPT      (Blank)
|                    derive PTRTCD from PTRTGRP.
|                    
| DSPLAN             Specifies the path and file name of    OPT      &g_dsplanfile 
|                    the HARP A&R dataset metadata. This 
|                    will define the attributes to use to 
|                    define the A&R dataset.
|                    NOTE: If DSPLAN is not specified
|                          i.e. left to its default value,
|                          or is specified as anything 
|                          other than blank, then 
|                          DSETTEMPLATE, SORTORDER and 
|                          FORMATNAMESDSET must not be
|                          specified as anything non-blank.
|                          If DSETTEMPLATE, SORTORDER and
|                          FORMATNAMESDSET are specified
|                          as anything non-blank, then
|                          DSPLAN must be specified as
|                          blank (DSPLAN=,).
|
| DSETTEMPLATE       Specifies the name to give to the      OPT      (Blank)
|                    empty dataset containing the variables 
|                    and attributes desired for the A&R 
|                    dataset.
|                    NOTE: If DSETTEMPLATE is specified
|                          as anything non-blank, then 
|                          DSPLAN must be specified as
|                          blank (DSPLAN=,).
|
| SORTORDER          Specifies the sort order desired for   OPT      (Blank)
|                    the A&R dataset.
|                    NOTE: If SORTORDER is specified
|                          as anything non-blank, then 
|                          DSPLAN must be specified as
|                          blank (DSPLAN=,).
|
| FORMATNAMESDSET    Specifies the name of a dataset which  OPT      (Blank)
|                    contains VAR_NM (a variable name of a 
|                    code) and format_nm (the name of a 
|                    format to produce the decode).
|                    NOTE: If FORMATNAMESDSET is specified
|                          as anything non-blank, then 
|                          DSPLAN must be specified as
|                          blank (DSPLAN=,).
|
| NODERIVEVARS       List of domain-specific variables not  OPT      (Blank)
|                    to derive when %tu_derive is called.
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
| &VISITDSET          Req      Parameter specified visit dataset
| &EXPOSUREDSET                Parameter specified exposure dataset
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
|(@) tu_common
|(@) tu_datetm
|(@) tu_decode
|(@) tu_derive
|(@) tu_misschk
|(@) tu_nobs
|(@) tu_putglobals
|(@) tu_rantrt
|(@) tu_tidyup
|
| Example:
|    %tc_mstone(
|         refdateoption   = visit,
|         refdatevisitnum = 10,
|         dsplan          = &g_dsplanfile
|         );
|
|******************************************************************************
| Change Log
|
| Modified By:               Yongwei Wang
| Date of Modification:      18-Apr-2005
| New version/draft number:  1/2
| Modification ID:           YW001
| Reason For Modification:   Changed &dsetin to &visitdset
|
| Modified By:              Yongwei Wang
| Date of Modification:     17-Sep-07
| New version/draft number: 2/1
| Modification ID:          YW002
| Reason For Modification:  Based on change request HRT0184 and HRT0172:
|                           1. Added data set parameters, which will be passed 
|                              to new version of TU macros: demodset, enroldset,
|                              investigdset, racedset, visitdset       
|                           2. Added call of %tu_nobs to check if data set exist
|                           3. Added 5 new DYREF* parameters, which will be passed 
|                              %tu_derive REF* parameters: dyrefdateoption, 
|                              dyrefdatedsetsubset, dyrefdatesourcedset
|                              dyrefdatesourcevar, dyrefdatevisitnum  
|                           4.	Added parameter DECODEPAIRS, which will be 
|                               passed to %tu_decode
|
| Modified By:              Gail Knowlton
| Date of Modification:     14-Oct-08
| New version/draft number: 2/2
| Reason For Modification:  Removed extra blank line in macro definition
|
| Modified By:              Gail Knowlton
| Date of Modification:     14-Oct-08
| New version/draft number: 2/3
| Reason For Modification:  Removed extra reference to DECODEPAIRS in macro definition
|
| Modified By:
| Date of Modification:
| New version/draft number:
| Modification ID:
| Reason For Modification:
|
*******************************************************************************/
%macro tc_mstone (
     dsetout           = ARDATA.MSTONE,   /* Output dataset name */
     demodset          = dmdata.demo,     /* Name of DEMO dataset to use */        
     enroldset         = dmdata.enrol,    /* Name of ENROL dataset to use */       
     exposuredset      = DMDATA.EXPOSURE, /* Exposure dataset name */
     investigdset      = dmdata.investig, /* Name of RACE dataset to use */        
     racedset          = dmdata.race,     /* Name of RACE dataset to use */        
     randalldset       = dmdata.randall,  /* Name of RANDALL dataset to use */     
     randdset          = dmdata.rand,     /* Name of RAND dataset to use */        
     visitdset         = DMDATA.VISIT,    /* Visit dataset name */
     attributesyn      = Y,          /* Reconcile A&R dataset with planned A&R dataset */
     commonvarsyn      = Y,          /* Add common variables */
     datetimeyn        = Y,          /* Derive datetime variables */
     decodeyn          = Y,          /* Decode coded variables */
     derivationyn      = Y,          /* Dataset specific derivations */
     misschkyn         = Y,          /* Print warning message for variables in &DSETOUT with missing values on all records */
     treatvarsyn       = Y,          /* Add treatment variables */
     agemonthsyn       = N,          /* Calculation of age in months */
     ageweeksyn        = N,          /* Calculation of age in weeks */
     agedaysyn         = N,          /* Calculation of age in days */
     refdateoption     = TREAT,      /* Reference date source option */
     refdatevisitnum   = ,           /* Reference date visit number */
     refdatesourcedset = ,           /* Reference date source dataset */
     refdatesourcevar  = ,           /* Reference date source variable */
     refdatedsetsubset = ,           /* Where clause applied to source dataset */
     dyrefdateoption    = ,          /* Reference date source option for the calculation of Study Day values in tu_derive Reference date source option for tu_derive.*/                                  
     dyrefdatedsetsubset= ,          /* WHERE clause applied to source dataset for tu_derive. */            
     dyrefdatesourcedset= ,          /* Reference date source dataset for tu_derive. */                                            
     dyrefdatesourcevar = ,          /* Reference date source variable for tu_derive. */                                           
     dyrefdatevisitnum  = ,          /* Specific visit number at which reference date is to be taken for tu_derive. */         
     decodepairs       = ,           /* code and decode variables in pair */
     trtcdinf          = ,           /* Informat to derive TRTCD from TRTGRP */
     ptrtcdinf         = ,           /* Informat to derive PTRTCD from PTRTGRP */
     dsplan            = &g_dsplanfile, /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
     dsettemplate      = ,           /* Planned A&R dataset template name */
     sortorder         = ,           /* Planned A&R dataset sort order */
     formatnamesdset   = ,           /* Format names dataset name */
     noderivevars      =             /* List of variables not to derive */
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

 %let exposuredset      = %nrbquote(&exposuredset);
 %let visitdset         = %nrbquote(&visitdset);
 %let dsetout           = %nrbquote(&dsetout);

 %let commonvarsyn      = %nrbquote(%upcase(%substr(&commonvarsyn, 1, 1)));
 %let treatvarsyn       = %nrbquote(%upcase(%substr(&treatvarsyn, 1, 1)));
 %let datetimeyn        = %nrbquote(%upcase(%substr(&datetimeyn, 1, 1)));
 %let decodeyn          = %nrbquote(%upcase(%substr(&decodeyn, 1, 1)));
 %let derivationyn      = %nrbquote(%upcase(%substr(&derivationyn, 1, 1)));
 %let attributesyn      = %nrbquote(%upcase(%substr(&attributesyn, 1, 1)));
 %let misschkyn         = %nrbquote(%upcase(%substr(&misschkyn, 1, 1)));
 
 /*
 / Check for required parameters.
 /----------------------------------------------------------------------------*/

 %if &exposuredset eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter EXPOSUREDSET is required.;
    %let g_abort=1;
 %end;

 %if &visitdset eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter VISITDSET is required.;
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

 /*
 / If one of the input dataset names is the same as the output dataset name,
 / write an error to the log.
 /----------------------------------------------------------------------------*/
 
 %if %qscan(&exposuredset, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The exposure dataset name EXPOSUREDSET(=&exposuredset) is the same as the output dataset name DSETOUT(=&dsetout).;
    %let g_abort=1;
 %end;

 %if %qscan(&visitdset, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The visit dataset name VISITDSET(=&visitdset) is the same as the output dataset name DSETOUT(=&dsetout).;
    %let g_abort=1;
 %end;
 
 /*
 / Check for existance of input data set
 /----------------------------------------------------------------------------*/

 %if &exposuredset ne %then 
 %do;
    %if %tu_nobs(&exposuredset) lt 0 %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: Data set EXPOSUREDSET(=&exposuredset) does not exist.;
       %let g_abort=1;
    %end;   
 %end;

 %if &visitdset ne %then 
 %do; 
    %if %tu_nobs(&visitdset) lt 0 %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: Data set VISITDSET(=&visitdset) does not exist.;
       %let g_abort=1;
    %end;
 %end;

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
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

 %local prefix;
 %let prefix = _tc_mstone;   /* Root name for temporary work datasets */

 /*
 / Initialise counter for appending to temporary dataset names for the
 / purpose of tracking datasets through a number of optional sequential
 / data processing steps.
 /----------------------------------------------------------------------------*/

 %local i;
 %let i = 1;
 
 data &prefix._ds&i;
      set %unquote(&visitdset);
 run;

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
 / We need to get the first study contact date (and time if available) as well
 / as the last study contact date (and time if available). 
 /----------------------------------------------------------------------------*/

 %local exist_visittm visittm;
 %let exist_visittm=%tu_chkvarsexist(&prefix._ds&i, visittm);
 %if &exist_visittm ne  %then %let visittm=;
 %else %let visittm=VISITTM;

 proc sort data=&prefix._ds&i;
    by studyid subjid visitdt &visittm;
 run;

 data &prefix._ds%eval(&i+1)(drop=visitdt &visittm);
      set &prefix._ds&i;
      by studyid subjid;
      retain msconsdt;

      %if &visittm ne  %then 
      %do;
          retain msconstm;
      %end;

      if first.subjid then 
      do;
         msconsdt=visitdt;

         %if &visittm ne  %then 
         %do;
             msconstm=visittm;
         %end;
      end;

      if last.subjid then 
      do;
         msconedt=visitdt;

         %if &visittm ne  %then 
         %do;
             msconetm=visittm;
         %end;

         output;
      end;
 run;

 %let i = %eval(&i + 1);

 /*
 / We need to get the first study treatment date (and time if available) as well
 / as the last study treatment date (and time if available). 
 /----------------------------------------------------------------------------*/
 
 data &prefix.exposure;
    set %unquote(&exposuredset);
 run;

 %local exist_exsttm exsttm;
 %let exist_exsttm=%tu_chkvarsexist(&prefix.exposure, exsttm);
 %if &exist_exsttm ne  %then %let exsttm=;
 %else %let exsttm=EXSTTM;

 %local exist_exentm exentm;
 %let exist_exentm=%tu_chkvarsexist(&prefix.exposure, exentm);
 %if &exist_exentm ne  %then %let exentm=;
 %else %let exentm=EXENTM;

 proc sort data = &prefix.exposure(where=(exstdt ne .))
           out  = &prefix._sort_exposure(keep=studyid subjid exstdt &EXSTTM exendt &EXENTM);
      by studyid subjid exstdt &exsttm;
 run;

 data &prefix._exposure (drop=exstdt &exsttm exendt &exentm);
      set &prefix._sort_exposure;
      by studyid subjid;
      retain mststdt;

      %if &exsttm ne  %then
      %do;
          retain mststtm;
      %end;

      if first.subjid then 
      do;
         mststdt=exstdt;

         %if &exsttm ne  %then
         %do;
             mststtm=exsttm;
         %end;
      end;

      if last.subjid then
      do;
         mstendt=exendt;

         %if &exentm ne  %then
         %do;
             mstentm=exentm;
         %end;

         output;
      end;
 run;

 /*
 / Combine exposure and visit information.
 /----------------------------------------------------------------------------*/

 data &prefix._ds%eval(&i+1);
      merge &prefix._ds&i &prefix._exposure;
      by studyid subjid;
 run;

 %let i = %eval(&i + 1);

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
 /----------------------------------------------------------------------------*/

 %if &derivationyn eq Y %then
 %do;
    %tu_derive (
         dsetin            = &prefix._ds&i,
         dsetout           = &prefix._ds%eval(&i+1),
         domaincode        = ms,                     

         demodset          = &demodset,
         exposuredset      = &exposuredset,
         randalldset       = &randalldset,
         randdset          = &randdset,
         visitdset         = &visitdset,

         noderivevars      = &noderivevars,
         refdateoption     = &dyrefdateoption,
         refdatevisitnum   = &dyrefdatevisitnum,
         refdatesourcedset = &dyrefdatesourcedset,
         refdatesourcevar  = &dyrefdatesourcevar,
         refdatedsetsubset = &dyrefdatedsetsubset,
         xovarsforpgyn     = N
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

%mend tc_mstone;
