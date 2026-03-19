/*******************************************************************************
|
| Macro Name:      tc_trt
|
| Macro Version:   6
|
| SAS Version:     8.2
|
| Created By:      Mark Luff / Eric Simms
|
| Date:            30-Jun-2004
|
| Macro Purpose:   TRT wrapper macro
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                            REQ/OPT  DEFAULT
| -----------------  -------------------------------------  -------  ----------
| RANDDSET           Specifies the RAND-format SI dataset   REQ      DMDATA.RAND
|                    which will be used along with the 
|                    RANDALLDSET dataset and TIMESLICDSET 
|                    dataset to produce a TRT-format A&R 
|                    dataset.
|                    Valid values: valid dataset name 
|
| RANDALLDSET        Specifies the RANDALL-format SI        REQ      DMDATA.RANDALL
|                    dataset which will be used along with 
|                    the RANDDSET dataset and TIMESLICDSET 
|                    dataset to produce a TRT-format A&R 
|                    dataset.
|                    Valid values: valid dataset name 
|
| EXPOSUREDSET       Specifies the EXPOSURE-format SI       OPT      DMDATA.EXPOSURE
|                    dataset which will be used for
|                    crossover study to subset the output
|                    treatment data set to keep the only
|                    periods which exist in this data 
|                    set, for each subject. It is required
|                    for crossover study.
|                    Valid values: valid dataset name 
|
| TIMESLICDSET       Specifies the TMSLICE-format SI        OPT      DMDATA.TMSLICE
|                    dataset which will be used along with 
|                    the RANDDSET dataset and the 
|                    RANDALLDSET dataset to produce a 
|                    TRT-format A&R dataset.
|                    Valid values: valid dataset name
|
| DSETOUT            Specifies the name of the output       REQ      ARDATA.TRT
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
| EXRECALCVISITYN    Call %tu_recalcvisit to recalculate    REQ      N
|                    VISIT based for EXPOSURE data set 
|                    on the EXPOSURE date?
|                    Valid values: Y, N          
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
| EXREFDAT           Specify a reference date variable name OPT      EXSTDT
|                    to pass to %tu_recalcvisit to  
|                    calculate the visit for &EXPOSUREDSET,
|                    Will be checked in %tu_recalcvisit
|
| EXREFTIM           Specify a reference time variable name OPT      EXSTTM
|                    to pass to %tu_recalcvisit to  
|                    calculate the visit for &EXPOSUREDSET. 
|                    Will be checked in %tu_recalcvisit
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
| DSETTEMPLATE       Specifies the name of the empty        OPT      (Blank)
|                    dataset containing the variables
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
| EXPOSURE              Opt      Parameter specified dataset
| RAND                  Req      Parameter specified dataset
| RANDALL               Req      Parameter specified dataset
| TMSLICEDSET           Opt      Parameter specified dataset 
| TRT                   Req      Parameter specified dataset 
|
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
| Global macro variables created: None
|
|
| Macros called:
|(@) tr_putlocals
|(@) tu_abort
|(@) tu_attrib
|(@) tu_common
|(@) tu_chkvarsexist
|(@) tu_datetm
|(@) tu_decode
|(@) tu_derive
|(@) tu_misschk
|(@) tu_nobs
|(@) tu_putglobals
|(@) tu_rantrt
|(@) tu_recalcvisit
|(@) tu_tidyup
|(@) tu_timslc
|
| Example:
|    %tc_trt(
|         refdateoption   = visit,
|         refdatevisitnum = 10,
|         dsplan          = &g_dsplanfile
|         );
|
|******************************************************************************
| Change Log
|
| Modified By:              Yongwei Wang
| Date of Modification:     26-Aug-2005
| New version/draft number: 2/1
| Modification ID:          YW001
| Reason For Modification:  For crossover study, all treatments for a subject
|                           are in output treatment dataset, even the subject
|                           does not get all treatments.The following changes
|                           have been made based on request HRT0088
|                           1. Four parameters, EXPOSUREDSET, EXREFDAT, EXREFTIM
|                              EXRECALCVISITYN
|                           2. Parameter validations for new parameters
|                           3. Call %tu_recalvisit to add VISIT to &EXPOSUREDSET
|                           4. Call %tu_timslc to add PERIOD to &EXPOSUREDSET
|                           5. Merge &EXPOSURE data set with derived treatment
|                              data set by STUDYID CENTID SUBJID and PERIOD/PERNUM
|                              to keep only recodes which exist in &EXPOSUREDSET
|                           6. Moved call of %tu_datetm after call of %tu_derive
|
| Modified By:              Yongwei Wang
| Date of Modification:     31-Oct-2005
| New version/draft number: 3/1
| Modification ID:          YW002
| Reason For Modification:  Requested by change request HRT0090, added derivation
|                           of TERIOD/TPERNUM, TPTRTCD/TPTRTGRP and TPATRTCD/TPATRTGRP
|
| Modified By:              Yongwei Wang
| Date of Modification:     09-Feb-2006
| New version/draft number: 4/1
| Modification ID:          YW003
| Reason For Modification:  Removed one nodupkey in sort statement on &prefix._ds&i
|
| Modified By:              Yongwei Wang
| Date of Modification:     12-Sep-2006
| New version/draft number: 5/1
| Modification ID:          YW004
| Reason For Modification:  Changed TPATRTGRP to TPATRTGP 
|
| Modified By:              Yongwei Wang
| Date of Modification:     17-Sep-07
| New version/draft number: 6/1
| Modification ID:          YW005
| Reason For Modification:  Based on change request HRT0184 and HRT0172:
|                           1. Added data set parameters, which will be passed 
|                              to new version of TU macros: demodset, enroldset,
|                              investigdset, racedset, visitdset       
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
%macro tc_trt (
     dsetout           = ARDATA.TRT,       /* Output dataset name */     
     demodset          = dmdata.demo,     /* Name of DEMO dataset to use */        
     enroldset         = dmdata.enrol,    /* Name of ENROL dataset to use */       
     exposuredset      = dmdata.exposure, /* Name of EXPOSURE dataset to use */    
     investigdset      = dmdata.investig, /* Name of RACE dataset to use */        
     racedset          = dmdata.race,     /* Name of RACE dataset to use */        
     randalldset       = dmdata.randall,  /* Name of RANDALL dataset to use */     
     randdset          = dmdata.rand,     /* Name of RAND dataset to use */        
     timeslicdset      = dmdata.tmslice,  /* Name of TMSLICE dataset to use */      
     visitdset         = dmdata.visit,    /* Name of VISIT dataset to use */          

     commonvarsyn      = Y,       /* Add common variables */
     treatvarsyn       = Y,       /* Add treatment variables */
     datetimeyn        = Y,       /* Derive datetime variables */
     decodeyn          = Y,       /* Decode coded variables */
     derivationyn      = Y,       /* Dataset specific derivations */
     attributesyn      = Y,       /* Reconcile A&R dataset with planned A&R dataset */
     misschkyn         = Y,       /* Print warning message for variables in &DSETOUT with missing values on all records */ 
     exrecalcvisityn   = N,       /* Recalculate visit based on &REFDAT and &REFTIM for &EXPOSURE data set of crossover study */
     agemonthsyn       = N,       /* Calculation of age in months */
     ageweeksyn        = N,       /* Calculation of age in weeks */
     agedaysyn         = N,       /* Calculation of age in days */
     exrefdat          = exstdt,  /* Reference date variable name for recalculating visit for &EXPOSURE data set of crossover study */
     exreftim          = exsttm,  /* Reference time variable name for recalculating visit for &EXPOSURE data set of crossover study */
     refdateoption     = TREAT,   /* Reference date source option */
     refdatevisitnum   = ,        /* Specific visit number at which reference date is to be taken. */
     refdatesourcedset = ,        /* Reference date source dataset */
     refdatesourcevar  = ,        /* Reference date source variable */
     refdatedsetsubset = ,        /* Where clause applied to source dataset */
     trtcdinf          = ,        /* Informat to derive TRTCD from TRTGRP */
     ptrtcdinf         = ,        /* Informat to derive PTRTCD from PTRTGRP */
     dsplan            = &g_dsplanfile, /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
     dsettemplate      = ,        /* Planned A&R dataset template name */
     sortorder         = ,        /* Planned A&R dataset sort order */
     decodepairs       = ,
     formatnamesdset   = ,        /* Format names dataset name */
     noderivevars      =          /* List of variables not to derive */
        );

 /*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion;
 %let MacroVersion = 6;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals(varsin=G_CENTID G_SUBJID);
 
 %local tmslicedset;
 
 %let tmslicedset=&timeslicdset;
 

 /*
 / PARAMETER VALIDATION
 /----------------------------------------------------------------------------*/

 %let randdset          = %nrbquote(&randdset);
 %let randalldset       = %nrbquote(&randalldset);
 %let timeslicdset      = %nrbquote(&timeslicdset);
 %let dsetout           = %nrbquote(&dsetout);
 %let exposuredset      = %nrbquote(&exposuredset);

 %let commonvarsyn      = %nrbquote(%upcase(%substr(&commonvarsyn, 1, 1)));
 %let treatvarsyn       = %nrbquote(%upcase(%substr(&treatvarsyn, 1, 1)));
 %let datetimeyn        = %nrbquote(%upcase(%substr(&datetimeyn, 1, 1)));
 %let decodeyn          = %nrbquote(%upcase(%substr(&decodeyn, 1, 1)));
 %let derivationyn      = %nrbquote(%upcase(%substr(&derivationyn, 1, 1)));
 %let attributesyn      = %nrbquote(%upcase(%substr(&attributesyn, 1, 1)));
 %let misschkyn         = %nrbquote(%upcase(%substr(&misschkyn, 1, 1)));
 %let exrecalcvisityn   = %nrbquote(%upcase(%substr(&exrecalcvisityn, 1, 1)));
 
 /*
 / Check for required parameters.
 /----------------------------------------------------------------------------*/

 %if &randdset eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter RANDDSET is required.;
    %let g_abort=1;
 %end;

 %if &randalldset eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter RANDALLDSET is required.;
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
 
 %if &exrecalcvisityn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter EXRECALCVISITYN is required.;
    %let g_abort=1;
 %end;
 
 %if ( %qupcase(&g_stype) eq XO ) and ( &exposuredset eq ) %then
 %do; 
    %put %str(RTE)RROR: &sysmacroname: The parameter EXPOSUREDSET is required for crossover study.;
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
 
 %if &exrecalcvisityn ne Y and &exrecalcvisityn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: EXRECALCVISITYN should be either Y or N.;
    %let g_abort=1;
 %end;

 /*
 / If one of the input dataset names is the same as the output dataset name,
 / write an error to the log.
 /----------------------------------------------------------------------------*/

 %if %qscan(&randdset, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The rand dataset name RANDDSET(=&randdset) is the same as the output dataset name DSETOUT(=&dsetout).;
    %let g_abort=1;
 %end;

 %if %qscan(&randalldset, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The randall dataset name RANDALLDSET(=&randalldset) is the same as the output dataset name DSETOUT(=&dsetout).;
    %let g_abort=1;
 %end;

 %if %qscan(&timeslicdset, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The timeslic dataset name TIMESLICDSET(=&timeslicdset) is the same as the output dataset name DSETOUT(=&dsetout).;
    %let g_abort=1;
 %end;
 
 %if %qscan(&exposuredset, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The exposure dataset name EXPOSUREDSET(=&exposuredset) is the same as the output dataset name DSETOUT(=&dsetout).;
    %let g_abort=1;
 %end;

 /*
 / Check if all given data sets exist.
 /----------------------------------------------------------------------------*/
 
 %if &randdset ne  %then
 %do;
    %if %tu_nobs(&randdset) lt 0 %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: Data set RANDDSET(=&randdset) does not exist.;
       %let g_abort=1;
    %end;
 %end;
     
 %if &randalldset ne  %then
 %do;    
    %if %tu_nobs(&randalldset) lt 0 %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: Data set RANDALLDSET(=&randalldset) does not exist.;
       %let g_abort=1;
    %end;
 %end;
 
 %if &timeslicdset ne  %then
 %do;
    %if %tu_nobs(&timeslicdset) lt 0 %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: Data set TIMESLICDSET(=&timeslicdset) does not exist.;
    %let g_abort=1;
    %end;    
 %end;
 
 %if ( &timeslicdset ne ) and ( %qupcase(&g_stype) eq XO ) %then
 %do;
    %if %tu_nobs(&exposuredset) lt 0 %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: Data set EXPOSUREDSET(=&exposuredset) does not exist.;
       %let g_abort=1;
    %end;
 %end;

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;

 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/

 %local prefix i l_exmergevars l_periodvars exist_cycle cycle ;
 %let prefix = _tc_trt;   /* Root name for temporary work datasets */

 /*
 / Initialise counter for appending to temporary dataset names for the
 / purpose of tracking datasets through a number of optional sequential
 / data processing steps.
 /----------------------------------------------------------------------------*/

 %let i = 1;

 /*
 / Obtain period number, treatment description and stratum info from RandAll.
 /----------------------------------------------------------------------------*/
 /*  
 / If VISIT/VISITNUM is in RAND data set, the macro may not work because the 
 / PERNUM and STAGENUM should be added before merging with RANDALL data set. 
 / 
 / As a temporary solution and considing backward compatible, the VISIT/VISITNUM
 / will not be considered in this version.
 /----------------------------------------------------------------------------*/

 data &prefix.rand;
    set %unquote(&randdset);
 run;
 
 %let exist_cycle=%tu_chkvarsexist(&prefix.rand, cycle);
 %if &exist_cycle ne  %then %let cycle=;
 %else %let cycle=CYCLE;

 proc sql noprint;
  create table &prefix._ds&i(drop=randnum &cycle) as
  select a.*, b.pernum, b.trtdesc, b.stratum
  from &randdset as a left join &randalldset as b
  on a.randnum eq b.randnum;
 quit;

 /*
 / If timeslice dataset exists, add timeslicing info.
 / YW002: change the whole if block because the logic is not right. The code
 / will only merge-in PERIOD from TMSLICE data set. The other variables should
 / be merged when VISIT/VISITNUM in RAND data set is considered. 
 /----------------------------------------------------------------------------*/
       
 %if %tu_nobs(&timeslicdset) ge 0 %then
 %do;
    
    data &prefix.tmslice;
       set %unquote(&timeslicdset);
    run;
    
    %if %tu_chkvarsexist(&prefix.tmslice, PERNUM PERIOD) eq %then
    %do;     
       proc sort data=&prefix.tmslice(keep=pernum period) out=&prefix._timeslic nodupkey;
         by pernum;
       run;
       
       proc sort data=&prefix._ds&i out=&prefix._ds%eval(&i+1);
         by pernum;
       run;
       
       %let i = %eval(&i + 1);
       
       data &prefix._ds%eval(&i+1);
          merge &prefix._ds&i(in=__in1__)
                &prefix._timeslic;
          by pernum;
          if __in1__;
       run;      
     
       %let i = %eval(&i + 1);
    %end; /* %tu_chkvarsexist(&timeslicdset, PERNUM PERIOD) eq */
    
 %end; /* %sysfunc(exist(&timeslicdset)) gt 0 */

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
         
         domaincode        = tr,                     
         noderivevars      = &noderivevars,          
         refdateoption     = &refdateoption,         
         refdatevisitnum   = &refdatevisitnum,       
         refdatesourcedset = &refdatesourcedset,     
         refdatesourcevar  = &refdatesourcevar,      
         refdatedsetsubset = &refdatedsetsubset      
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
 / YW002: If TPERNUM exist, TPERIOD=PERIOD and TPERNUM=PERNUM       
 /----------------------------------------------------------------------------*/
 
 %if %tu_chkvarsexist(&prefix._ds&i, PERNUM) eq %then
 %do;    
    data &prefix._ds%eval(&i+1);
       set &prefix._ds&i;
       label tpernum='Treatment period number';       
       tpernum=pernum;       
       %if %tu_chkvarsexist(&prefix._ds&i, PERIOD) eq %then
       %do;       
          label tperiod='Treatment period';
          tperiod=period;       
       %end;
    run;
    
    %let i = %eval(&i + 1);
 %end;
 
 /*
 / YW002: If PTRTCD and PTRTGRP exist, TPTRTCD=PTRTCD and TPTRTGRP=PTRTGRP       
 /----------------------------------------------------------------------------*/
 
 %if %tu_chkvarsexist(&prefix._ds&i, PTRTCD PTRTGRP) eq %then
 %do;    
    data &prefix._ds%eval(&i+1);
       set &prefix._ds&i;
       label tptrtcd='Trt period randomized treatment code'
             tptrtgrp='Trt period randomized treatment group';
       tptrtcd=ptrtcd;
       tptrtgrp=ptrtgrp;
    run;
    
    %let i = %eval(&i + 1);
 %end;
 
 /*
 / YW002: If PATRTCD and PATRTGRP exist, TPATRTCD=PATRTCD and TPATRTGP=PATRTGP       
 / YW004: Changed TPATRTGRP to TPATRTGP
 /----------------------------------------------------------------------------*/
 
 %if %tu_chkvarsexist(&prefix._ds&i, PATRTCD PATRTGRP) eq %then
 %do;    
    data &prefix._ds%eval(&i+1);
       set &prefix._ds&i;
       label tpatrtcd='Trt period actual treatment code'
             tpatrtgp='Trt period actual treatment group';       
       tpatrtcd=patrtcd;
       tpatrtgp=patrtgrp;
    run;
    
    %let i = %eval(&i + 1);
 %end;
 
 /*
 / YW001: For crossover study, remove the period treatements for periods which 
 / the suject does not have the record in EXPOSURE data set, by merging the 
 / data set with EXPOSURE data set.The %tu_timslc needs to be called to merge
 / period to the EXPOSURE data set. The %tu_recalvisit may need to be called
 / to recalculate VISIT for EXPOSURE data set, so that the PERIOD can be merged
 / in based on new VISIT.
 /----------------------------------------------------------------------------*/
 
 %if %qupcase(&g_stype) eq XO %then
 %do;
    data &prefix.exposure;
       set %unquote(&exposuredset);
    run;
 
    /* Recalculate VISIT/VISITNUM */       
    %if ( &exrecalcvisityn eq Y ) %then
    %do;
       %if %nrbquote(&exreftim) ne %then 
       %do;
          %if %tu_chkvarsexist(&prefix.exposure, &exreftim) ne %then
          %do;
             %put %str(RTW)ARNING: &sysmacroname: Variable EXREFTIM(=&exreftim) does not exist in EXPOSUREDSET (=&exposuredset) and it will not be used to recalculate visit for exposure data set.;
             %let exreftim=;
          %end;
       %end; /* end-if &exrecalcvisityn eq Y */
    
       %tu_recalcvisit (
          dsetin    = &exposuredset,
          dsetout   = &prefix._dsex,
          visitdset = &visitdset,
          refdat    = &exrefdat,
          reftim    = &exreftim 
          );
              
       %let exposuredset = &prefix._dsex;
    %end; /* end-if &exrecalcvisityn eq Y */
    %else %let exposuredset=&prefix.exposure;
    
    /* Check if PERNUM and PERIOD exist in derived treatment data set */                                
    %let l_periodvars=;
    
    %if %nrbquote(%tu_chkvarsexist(&prefix._ds&i, PERNUM)) eq %then
       %let l_periodvars=PERNUM;
    %if %nrbquote(%tu_chkvarsexist(&prefix._ds&i, PERIOD)) eq %then
       %let l_periodvars=&l_periodvars PERIOD;
    
    %if %nrbquote(&l_periodvars) eq %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: This is a crossover study, but neither PERNUM nor PERIOD can be derived;
       %let g_abort=1;
       %tu_abort;
    %end;
    
    /* Check if PERNUM and/or PERIOD, which exist in treatment dataset, exist in EXPOSURE data set */
    %let l_exmergevars=%tu_chkvarsexist(&exposuredset, &l_periodvars);
    
    %if ( %qscan(%nrbquote(&l_exmergevars), 2, %str( )) ne ) or
        ( &l_exmergevars eq &l_periodvars ) %then 
    %do;
        %tu_timslc(
           dsetin         = &exposuredset,
           dsetout        = &prefix._dstm,       
           tmslicedset    = &timeslicdset,
           keepperstadyyn = N
           )
        
        %let exposuredset = &prefix._dstm;    
    %end;
    
    /* Check if PERNUM and/or PERIOD, exist in both derived EXPOSURE and treatment dataset */
    %let l_exmergevars=;
                                   
    %if ( %nrbquote(%tu_chkvarsexist(&exposuredset, PERNUM)) eq ) and
        ( %nrbquote(%tu_chkvarsexist(&prefix._ds&i, PERNUM)) eq )
    %then %let l_exmergevars=PERNUM &l_exmergevars;
    
    %if ( %nrbquote(%tu_chkvarsexist(&exposuredset, PERIOD)) eq ) and
        ( %nrbquote(%tu_chkvarsexist(&prefix._ds&i, PERIOD)) eq )
    %then %let l_exmergevars=PERIOD &l_exmergevars;
    
    %if %nrbquote(&l_exmergevars) eq %then
    %do;    
       %put %str(RTE)RROR: &sysmacroname: This is a crossover study, but neither PERNUM nor PERIOD can be found;
       %put %str(RTE)RROR: &sysmacroname: in data sets from exposuredset(=&exposuredset) and derived treatment data set;
       %let g_abort=1;
       %tu_abort;
    %end;       
   
    /* Build merge by-variables &g_subjid &g_centid STUDYID PERNUM and/or PERIOD, which exists in both EXPOSURE and treatment data set */ 
    %if ( %nrbquote(%tu_chkvarsexist(&exposuredset, &g_subjid)) eq ) and
        ( %nrbquote(%tu_chkvarsexist(&prefix._ds&i, &g_subjid)) eq )
    %then %let l_exmergevars=&g_subjid &l_exmergevars;
    
    %if %nrbquote(&g_centid) ne %then
    %do;     
       %if ( %nrbquote(%tu_chkvarsexist(&exposuredset, &g_centid)) eq ) and    
           ( %nrbquote(%tu_chkvarsexist(&prefix._ds&i, &g_centid)) eq )        
       %then %let l_exmergevars=&g_centid &l_exmergevars;
    %end;
    
    %if ( %nrbquote(%tu_chkvarsexist(&exposuredset, STUDYID)) eq ) and
        ( %nrbquote(%tu_chkvarsexist(&prefix._ds&i, STUDYID)) eq )        
    %then %let l_exmergevars=STUDYID &l_exmergevars;
     
    /* merge treatment and EXPOSURE data set to get records in both data set */                                                         
    proc sort data=&exposuredset out=&prefix._dsexsort(keep=&l_exmergevars) nodupkey;
       by &l_exmergevars;
    run;
    
    proc sort data=&prefix._ds&i out=&prefix._ds%eval(&i+1);
       by &l_exmergevars;
    run;
    
     %let i = %eval(&i + 1); 
    
    data &prefix._ds%eval(&i+1);
       merge &prefix._ds&i(in=__in2__) &prefix._dsexsort(in=__in1__);
       by &l_exmergevars;
       if __in1__ and __in2__;
    run;
    
    %let i = %eval(&i + 1);
 %end; /* end-if on %qupcase(&g_stype) eq XO */

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

%mend tc_trt;

