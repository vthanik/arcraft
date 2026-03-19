/*******************************************************************************
|
| Macro Name:        tc_race
|                   
| Macro Version:     2
|                   
| SAS Version:       8.2
|                   
| Created By:        Barry Ashby (Bra13711)
|                   
| Date:              19-Sep-2006
|                   
| Macro Purpose:     General wrapper macro to create A&R data set
|                   
| Macro Design:      Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                            REQ/OPT  DEFAULT
| -----------------  -------------------------------------- -------  ----------
| DSETIN             Specifies the SI dataset which needs   REQ      dmdata.race 
|                    to be transformed into an A&R 
|                    dataset.
|                    Valid values: valid dataset name 
|
| DSETOUT            Specifies the name of the output       REQ      ardata.race
|                    dataset to be created.
|                    Valid values: valid dataset name
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
| ATTRIBUTESYN       Call %tu_attrib to reconcile the       REQ      Y
|                    A&R-defined attributes to the planned 
|                    A&R dataset?
|                    Valid values: Y, N
|
| COMMONVARSYN       Call %tu_common to add common          REQ      Y
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
| DECODERENAME      By default, a coded variable named        OPT    (Blank)
|                   ZZZcd will produce a decoded variable
|                   ZZZ.  This can be changed by using 
|                   this parameter, i.e. 
|                   decoderename=zzz=abc_text  will create
|                   the decode of ZZZcd in a variable 
|                   named ABC_TEXT.
|
| DSETTEMPLATE       Specifies the name of the empty        OPT      (Blank)
|                    dataset containing the variables
|                    and attributes desired for the A&R
|                    dataset.
|                    NOTE: If DSETTEMPLATE is specified
|                          as anything non-blank, then
|                          DSPLAN must be specified as
|                          blank (DSPLAN=,).
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
| FORMATNAMESDSET    Specifies the name of a dataset which  OPT      (Blank)
|                    contains VAR_NM (a variable name of a
|                    code) and format_nm (the name of a
|                    format to produce the decode).
|                    NOTE: If FORMATNAMESDSET is specified
|                          as anything non-blank, then
|                          DSPLAN must be specified as
|                          blank (DSPLAN=,).
|
| MISSCHKYN          Call %tu_misschk to print RTWARNING    REQ      Y
|                    messages for each variable in 
|                    &DSETOUT which has missing values
|                    on all records.                    
|                    Valid values: Y, N.              
|
| PTRTCDINF          Name of pre-existing informat to       OPT      (Blank)
|                    derive PTRTCD from PTRTGRP.
|
| REFDATEDSETSUBSET  Where clause applied to source         OPT      (Blank)
|                    dataset. May be used regardless of the 
|                    value of REFDATEOPTION in order to 
|                    better select the reference date.
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
| REFDATESOURCEDSET  Required if REFDATEOPTION is OTHER.    OPT      (Blank)
|                    Use the variable REFDATESOURCEVAR 
|                    from the REFDATESOURCEDSET.
|
| REFDATESOURCEVAR   Required if REFDATEOPTION is OTHER.    OPT      (Blank)
|                    Use the variable REFDATESOURCEVAR 
|                    from the REFDATESOURCEDSET.
|
| REFDATEVISITNUM    Specific visit number at which         OPT      (Blank)
|                    reference date is to be taken.  
|                    Required if REFDATEOPTION is VISIT.
|
| SORTORDER          Specifies the sort order desired for   OPT      (Blank)
|                    the A&R dataset.
|                    NOTE: If SORTORDER is specified
|                          as anything non-blank, then
|                          DSPLAN must be specified as
|                          blank (DSPLAN=,).
|
| TREATVARSYN        Call %tu_rantrt to add treatment       REQ      Y
|                    variables?
|                    Valid values: Y, N
|
| TRTCDINF           Name of pre-existing informat to       OPT      (Blank)
|                    derive TRTCD from TRTGRP.
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
| RANDALLDSET        Specifies an SI-format RANDALL dataset to       dmdata.randall
|                    use for various derivations.                    
|                    Note: This parameter is not used in the         
|                    current version. It should be passed to         
|                    %tu_acttrt in a future release.                 
|                                                                    
| RANDDSET           Specifies an SI-format RAND dataset to use      dmdata.rand
|                    for various derivations.                        
|                                                                    
| VISITDSET          Specifies an SI-format VISIT dataset to use     dmdata.visit
|                    for various derivations.                        
|                                                                    
| DECODEPAIRS        Specifies code and decode variables in          (Blank)
|                    pair. The decode variables will be created      
|                    and populated with format value of the code     
|                    variable. The format is defined in &DSPLAN      
|                    file.                                           
| -----------------    -------------------------------------  -------  ----------
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
|(@) tu_common
|(@) tu_datetm
|(@) tu_decode
|(@) tu_misschk
|(@) tu_nobs
|(@) tu_putglobals
|(@) tu_rantrt
|(@) tu_tidyup
|
| Example:
|    %tc_race(
|                  refdateoption   = visit,
|                  refdatevisitnum = 10,
|                  dsplan          = &g_dsplanfile
|                  );
|
|******************************************************************************
| Change Log
|
| Modified By:              Yongwei Wang
| Date of Modification:     17-Sep-07
| New version/draft number: 2/1
| Modification ID:          YW001
| Reason For Modification:  Based on change request HRT0184 and HRT0172:
|                           1. Added data set parameters, which will be passed 
|                              to new version of TU macros: demodset, enroldset,
|                              exposuredset, investigdset, randalldset, 
|                              randdset, visitdset       
|                           2. Added call of %tu_nobs to check if data set exist
|                           3. Added parameter DECODEPAIRS, which will be 
|                              passed to %tu_decode
|
| Modified By:
| Date of Modification:
| New version/draft number:
| Modification ID:
| Reason For Modification:
|
*******************************************************************************/

%macro tc_race (
   dsetin            = dmdata.race,     /* Input dataset name */
   dsetout           = ardata.race,     /* Output dataset name */
   demodset          = dmdata.demo,     /* Name of DEMO dataset to use */        
   enroldset         = dmdata.enrol,    /* Name of ENROL dataset to use */       
   exposuredset      = dmdata.exposure, /* Name of EXPOSURE dataset to use */    
   investigdset      = dmdata.investig, /* Name of RACE dataset to use */        
   randdset          = dmdata.rand,     /* Name of RAND dataset to use */        
   randalldset       = dmdata.randall,  /* Name of RANDALL dataset to use */     
   visitdset         = dmdata.visit,    /* Name of VISIT dataset to use */       

   attributesyn      = Y,       /* Reconcile A&R dataset with planned A&R dataset */
   commonvarsyn      = Y,       /* Add common variables */
   datetimeyn        = Y,       /* Derive datetime variables */
   decodeyn          = Y,       /* Decode coded variables */
   misschkyn         = Y,       /* Print warning message for variables in &DSETOUT with missing values on all records */ 
   treatvarsyn       = Y,       /* Add treatment variables */
   agedaysyn         = N,       /* Calculation of age in days */
   agemonthsyn       = N,       /* Calculation of age in months */
   ageweeksyn        = N,       /* Calculation of age in weeks */
   refdateoption     = TREAT,   /* Reference date source option */
   refdatedsetsubset = ,        /* Where clause applied to source dataset */
   refdatesourcedset = ,        /* Reference date source dataset */
   refdatesourcevar  = ,        /* Reference date source variable */
   refdatevisitnum   = ,        /* Specific visit number at which reference date is to be taken. */
   dsettemplate      = ,        /* Planned A&R dataset template name */
   dsplan            = &g_dsplanfile, /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
   decoderename      = ,        /* List of renames for decoded variables */
   decodepairs       = ,        /* code and decode variables in pair */
   formatnamesdset   = ,        /* Format names dataset name */
   sortorder         = ,        /* Planned A&R dataset sort order */
   ptrtcdinf         = ,        /* Informat to derive PTRTCD from PTRTGRP */
   trtcdinf          =          /* Informat to derive TRTCD from TRTGRP */
   );

   /*
   / Echo parameter values and global macro variables to the log.
   /----------------------------------------------------------------------------*/
  
   %local MacroVersion;
   %let MacroVersion = 2;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals() 
  
   %local prefix thisvar listvars loopi i racedset;
   %let prefix = _tc_race;   /* Root name for temporary work datasets */
                                                                                                      
   /*
   / PARAMETER VALIDATION
   /----------------------------------------------------------------------------*/
   
   /*
   / Check for required parameters.
   /----------------------------------------------------------------------------*/
  
   %let listvars=DSETIN DSETOUT COMMONVARSYN TREATVARSYN DATETIMEYN 
                 DECODEYN ATTRIBUTESYN MISSCHKYN;
  
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
   / Check for Y/N parameter values.
   /----------------------------------------------------------------------------*/
   
   %let listvars=COMMONVARSYN TREATVARSYN DATETIMEYN DECODEYN ATTRIBUTESYN MISSCHKYN;

   %let i=1;   
   %let thisvar=%scan(&listvars, &i, %str( ));
   
   %do %while (%nrbquote(&thisvar) ne ) ;
      %if %nrbquote(&&&thisvar) ne %then 
      %do;
         %let &thisvar=%qupcase(%substr(&&&thisvar, 1, 1));
      %end;
      
      %if (%nrbquote(&&&thisvar) ne Y) and (%nrbquote(&&&thisvar) ne N) %then
      %do;
         %put %str(RTE)RROR: &sysmacroname: (&thisvar) should be either Y or N.;
         %let g_abort=1;
      %end;          
      
      %let i=%eval(&i + 1 );
      %let thisvar=%scan(&listvars, &i, %str( ));
   %end;  /* end of do-to loop */
  
   /*
   / Check for &DSETIN and &DSETOUT.
   /----------------------------------------------------------------------------*/
     
   %if %nrbquote(&dsetin) ne %then %do;
  
      /*
      / Check for existing datasets.
      /-------------------------------------------------------------------------*/
   
      %if %tu_nobs(&dsetin) lt 0 %then
      %do;
         %put %str(RTE)RROR: &sysmacroname: Data set DSETIN(=&dsetin) does not exist.;
         %let g_abort=1;
      %end;
  
      /*
      / If the input dataset name is the same as the output dataset name,
      / write an error to the log.
      /-------------------------------------------------------------------------*/
  
      %let dsetout=%nrbquote(&dsetout);
      %if %qscan(&dsetin, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
      %do;
         %put %str(RTE)RROR: &sysmacroname: The input dataset name DSETIN(=&dsetin) is the same as the output dataset name DSETOUT(=&dsetout).;
         %let g_abort=1;
      %end;
      
   %end; /* end-if on &dsetin ne */   
  
   /*
   / Check for parameter dependent parameters.
   /----------------------------------------------------------------------------*/  
   
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
   
   %let racedset=&dsetin;
   
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
      %tu_decode(
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
  
   %tu_tidyup(
      rmdset = &prefix:, 
      glbmac = NONE
      );
  
%mend tc_race;

