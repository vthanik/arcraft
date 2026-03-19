/*******************************************************************************
|
| Macro Name:      tu_refdat
|
| Macro Version:   2
|
| SAS Version:     8.2
|
| Created By:      Mark Luff
|
| Date:            04-May-2004
|
| Macro Purpose:   Calculate reference date
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                            REQ/OPT  DEFAULT
| -----------------  -------------------------------------  -------  ----------
| DSETIN             Specifies the dataset for which the    REQ      (Blank)
|                    new variable containing the reference 
|                    date day is to be added.
|                    Valid values: valid dataset name
|
| DSETOUT            Specifies the name of the output       REQ      (Blank)
|                    dataset to be created.
|                    Valid values: valid dataset name
|
| EXPOSUREDSET       EXPOSURE dataset name.                 OPT      DMDATA.EXPOSURE
|                    Required if REFDATEOPTION is TREAT
|
| RANDDSET           RAND dataset name.                     OPT      DMDATA.RAND
|                    Required if REFDATEOPTION is RAND
|
| REFDATEVAR         The name of the new variable which     REQ      DMREFDT
|                    will contain the reference date.
|
| REFTIMEVAR         The name of the new variable which     REQ      (Blank)
|                    will contain the reference time.
|
| REFDATEOPTION      Reference date source option. The      REQ      TREAT
|                    reference date will be used in the
|                    calculation of the age values.
|                    Valid values:
|                    TREAT - Trt start date from 
|                            DMDATA.EXPOSURE
|                    VISIT - Visit date from DMDATA.VISIT
|                    RAND  - Randomization date from 
|                            DMDATA.RAND
|                    OTHER - Date from the REFDATESOURCEVAR
|                            variable on the 
|                            REFDATESOURCEDSET dataset.
|
| REFDATEVISITNUM    Specific visit number at which          OPT      (Blank)
|                    reference date is to be taken.
|                    Required if REFDATEOPTION is VISIT.
|
| REFDATESOURCEDSET  Required if REFDATEOPTION is OTHER.     OPT      (Blank)
|                    Use the variable REFDATESOURCEVAR 
|                    from the REFDATESOURCEDSET.
|
| REFDATESOURCEVAR   Required if REFDATEOPTION is OTHER.     OPT      (Blank)
|                    Use the variable REFDATESOURCEVAR 
|                    from the REFDATESOURCEDSET.
|                     
| REFTIMESOURCEVAR   Optional if REFDATEOPTION is OTHER.     OPT      (Blank)
|                    Use the variable REFTIMESOURCEVAR 
|                    from the REFDATESOURCEDSET.
|                     
| REFDATEDSETSUBSET  May be used regardless of the value     OPT      (Blank)
|                    of REFDATEOPTION in order to better
|                    select the reference date.
|
| VISITDSET          VISIT dataset name                      OPT      DMDATA.VISIT
|                    Required if REFDATEOPTION is VISIT.
| -----------------  -------------------------------------  -------  ----------
|
| The macro references the following datasets :-
| ------------------  -------  ------------------------------------------------
| Name                Req/Opt  Description
| ------------------  -------  ------------------------------------------------
| &EXPOSUREDSET       Opt      SI Investigational Product dataset
| &VISITDSET          Opt      SI Visit Times dataset
| &DSETIN             Req      Parameter specified dataset
| &RANDDSET           Opt      SI Rand dataset
| &REFDATESOURCEDSET  Opt      Parameter specified dataset
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
|(@) tu_chkvarsexist
|(@) tu_nobs
|(@) tu_putglobals
|(@) tu_tidyup
|
| Example:
|    %tu_refdat(
|         dsetin            = _ae1,
|         dsetout           = _ae2,
|         refdateoption     = VISIT,
|         refdatevisitnum   = 20,
|         refdatedsetsubset = CYCLE=1
|         );
|
|******************************************************************************
| Change Log
|
| Modified By: Eric Simms
| Date of Modification: 29Nov04
| New version/draft number: 1/2
| Modification ID: ems001
| Reason For Modification: End of line comment for REFDATEVISITNUM in the %macro
|                          statement was split over two lines. This is not in 
|                          keeping with HARP standards; comment changed to a 
|                          single line.
|
| Modified By: Eric Simms
| Date of Modification: 30Nov04
| New version/draft number: 1/3
| Modification ID: ems002
| Reason For Modification: Added test to determine if RANDDT variable exists on 
|                          the DMDATA.RAND dataset if the user has specified  
|                          REFDATEOPTION=RAND. If not, then put out an error 
|                          message.     
|
| Modified By: Eric Simms
| Date of Modification: 30Nov04
| New version/draft number: 1/3
| Modification ID: ems003
| Reason For Modification: Added test to determine if no records were found with
|                          refdat for merge with input dataset.
|
| Modified By:              Yongwei Wang (YW62951)
| Date of Modification:     10-Jan-2005
| New version/draft number: 1/4
| Modification ID: ems003
| Reason For Modification:  Added two parameters: REFTIMEVAR and REFTIMESOURCEVAR
|
| Modified By:              Shan Lee
| Date of Modification:     06-Nov-2007
| New version/draft number: 2/1
| Modification ID:          SL001
| Reason For Modification:  Surface dataset names and allow dataset options to
|                           be specified - HRT0184 / HRT0168.
*******************************************************************************/
%macro tu_refdat (
     dsetin            = ,                /* Input dataset name */
     dsetout           = ,                /* Output dataset name */
     exposuredset      = dmdata.exposure, /* Exposure dataset name */
     randdset          = dmdata.rand,     /* Rand dataset name */
     refdatevar        = dmrefdt,         /* Reference date variable name */
     reftimevar        = ,                /* Reference time variable name */
     refdateoption     = TREAT,           /* Reference date source option */
     refdatevisitnum   = ,                /* Specific visit number at which reference date is to be taken. */
     refdatesourcedset = ,                /* Reference date source dataset */
     refdatesourcevar  = ,                /* Reference date source variable */
     reftimesourcevar  = ,                /* Reference time source variable */
     refdatedsetsubset = ,                /* WHERE clause applied to source dataset */
     visitdset         = dmdata.visit     /* Visit dataset name */
        );

 /*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion;
 %let MacroVersion = 2 build 1;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals() 

 %local prefix;
 %let prefix = _refdat;   /* Root name for temporary work datasets */

 /*
 / PARAMETER VALIDATION
 /----------------------------------------------------------------------------*/

 %let dsetin            = %nrbquote(&dsetin);
 %let dsetout           = %nrbquote(&dsetout);
 %let exposuredset      = %nrbquote(&exposuredset);
 %let randdset          = %nrbquote(&randdset);
 %let refdatevar        = %nrbquote(&refdatevar);
 %let reftimevar        = %nrbquote(&reftimevar);
 %let refdateoption     = %nrbquote(%upcase(&refdateoption));
 %let refdatevisitnum   = %nrbquote(&refdatevisitnum);
 %let refdatesourcedset = %nrbquote(&refdatesourcedset);
 %let refdatesourcevar  = %nrbquote(&refdatesourcevar);
 %let reftimesourcevar  = %nrbquote(&reftimesourcevar);
 %let refdatedsetsubset = %nrbquote(&refdatedsetsubset);
 %let visitdset         = %nrbquote(&visitdset);

 /*
 / Check for required parameters.
 /----------------------------------------------------------------------------*/

 %if &dsetin eq %then
 %do;
    %put %str(RTE)RROR: TU_REFDAT: The parameter DSETIN is required.;
    %let g_abort=1;
 %end;  /* end-if Parameter DSETIN is not specified.  */

 %if &dsetout eq %then
 %do;
    %put %str(RTE)RROR: TU_REFDAT: The parameter DSETOUT is required.;
    %let g_abort=1;
 %end;   /* end-if Parameter DSETOUT is not specified.  */

 %if &refdatevar eq %then
 %do;
    %put %str(RTE)RROR: TU_REFDAT: The parameter REFDATEVAR is required.;
    %let g_abort=1;
 %end;  /* end-if  Parameter REFDATEVAR is not specified.  */

 %if &refdateoption eq VISIT and &refdatevisitnum eq  %then
 %do;
    %put %str(RTE)RROR: TU_REFDAT: The parameter REFDATEVISITNUM is required when REFDATEOPTION is VISIT.;
    %let g_abort=1;
 %end;  /* end-if  Parameter REFDATEVISITNUM is not specified when value of REFDATEOPTION is same as VISIT. */

 %if &refdateoption eq OTHER and &refdatesourcedset eq  %then
 %do;
    %put %str(RTE)RROR: TU_REFDAT: The parameter REFDATESOURCEDSET is required when REFDATEOPTION is OTHER.;
    %let g_abort=1;
 %end;  /* end-if Parameter REFDATESOURCEDSET is not specified when REFDATEOPTION is OTHER. */

 %if &refdateoption eq OTHER and &refdatesourcevar eq  %then
 %do;
    %put %str(RTE)RROR: TU_REFDAT: The parameter REFDATESOURCEVAR is required when REFDATEOPTION is OTHER.;
    %let g_abort=1;
 %end;  /* end-if Parameter REFDATESOURCEVAR is not specified and REFDATEOPTION is OTHER. */


 /*
 / Check for valid parameter values.
 /----------------------------------------------------------------------------*/

 %if &refdateoption ne TREAT and &refdateoption ne VISIT and
     &refdateoption ne RAND and &refdateoption ne OTHER %then
 %do;
    %put %str(RTE)RROR: TU_REFDAT: REFDATEOPTION should be either TREAT, VISIT, RAND or OTHER.;
    %let g_abort=1;
 %end;  /* end-if Value of REFDATEOPTION is not equal to either TREAT, VISIT. RAND or OTHER. */

 /*
 / Check for existing datasets.
 / Surface dataset names and enable dataset options to be specified - SL001
 /----------------------------------------------------------------------------*/

 %if %sysfunc(exist(%qscan(&dsetin, 1, %str(%()))) eq 0 %then
 %do;
    %put %str(RTE)RROR: TU_REFDAT: The dataset DSETIN(=&dsetin) does not exist.;
    %let g_abort=1;
 %end;  /* end-if Specified DSETIN does not exist.  */

 %if &refdateoption eq TREAT %then 
 %do;
    %if %nrbquote(&exposuredset) eq %then
    %do;
       %put %str(RTE)RROR: TU_REFDAT: The dataset EXPOSUREDSET is not given. It is required when REFDATEOPTION=TREAT;
       %let g_abort=1;   
    %end;
    %else %if %sysfunc(exist(%qscan(&exposuredset, 1, %str(%()))) eq 0 %then
    %do;
       %put %str(RTE)RROR: TU_REFDAT: The dataset EXPOSUREDSET(=&exposuredset) does not exist. It is required when REFDATEOPTION=TREAT;
       %let g_abort=1;
    %end;
 %end;  /* end-if  &refdateoption eq TREAT */
 
 %if &refdateoption eq VISIT %then
 %do;
    %if %nrbquote(&visitdset) eq %then
    %do;
       %put %str(RTE)RROR: TU_REFDAT: The dataset VISITDSET is not given. It is required when REFDATEOPTION=VISIT;
       %let g_abort=1;
    %end; 
    %else %if %sysfunc(exist(%qscan(&visitdset, 1, %str(%()))) eq 0 %then
    %do;
       %put %str(RTE)RROR: TU_REFDAT: The dataset VISITDSET(=&visitdset) does not exist. It is required when REFDATEOPTION=VISIT;
       %let g_abort=1;
    %end;
 %end;  /* end-if &refdateoption eq VISIT */

 %if &refdateoption eq RAND %then
 %do;
    %if %nrbquote(&randdset) eq %then
    %do;
       %put %str(RTE)RROR: TU_REFDAT: The dataset RANDDSET is not given. It is required when REFDATEOPTION=RAND;
       %let g_abort=1;
    %end; 
    %else %if %sysfunc(exist(%qscan(&randdset, 1, %str(%()))) eq 0 %then
    %do;
       %put %str(RTE)RROR: TU_REFDAT: The dataset RANDDSET(=&randdset) does not exist. It is required when REFDATEOPTION=RAND;
       %let g_abort=1;
    %end;
 %end;  /* end-if  &refdateoption eq RAND */

 /* ems002
 /  Test to determine if RANDDT variable exists on the &RANDDSET 
 /  dataset if the user has specified REFDATEOPTION=RAND.   
 /  If not, then put out an error message.
 /----------------------------------------------------------------------------*/
 %if &refdateoption eq RAND and %nrbquote(&randdset) ne and %sysfunc(exist(%qscan(&randdset, 1, %str(%()))) ne 0 %then
 %do;
    data &prefix._randexist;
       if 0 then set %unquote(&randdset);
    run;
 
    %if %tu_chkvarsexist(&prefix._randexist, randdt) ne  %then
    %do;    
       %put %str(RTE)RROR: TU_REFDAT: The variable RANDDT does not exist on the RANDDSET(=&randdset) dataset.;
       %let g_abort=1;
    %end;  /* end-if Variable RANDDT does not exist on dataset &RANDDSET. */
 %end;  /* end-if &RANDDSET dataset exists */

 %if &refdateoption eq OTHER and %nrbquote(&refdatesourcedset) ne and %sysfunc(exist(%qscan(&refdatesourcedset, 1, %str(%()))) eq 0 %then
 %do;
    %put %str(RTE)RROR: TU_REFDAT: The dataset &refdatesourcedset does not exist.;
    %let g_abort=1;
 %end;  /* end-if Specified REFDATESOURCEDSET does not exist.  */

 %if &refdateoption eq OTHER and %sysfunc(exist(%qscan(&refdatesourcedset, 1, %str(%()))) ne 0 and
     &refdatesourcevar ne  %then
 %do;
    data &prefix._refdataexist;
       if 0 then set %unquote(&refdatesourcedset);
    run;

    %if %tu_chkvarsexist(&prefix._refdataexist, &refdatesourcevar) ne  %then
    %do;
       %put %str(RTE)RROR: TU_REFDAT: The REFDATESOURCEVAR variable (&REFDATESOURCEVAR) does not exist on the REFDATESOURCEDSET dataset (&REFDATESOURCEDSET).;
       %let g_abort=1;
    %end;  /* end-if Variable REFDATESOURCEVAR does not exist on dataset REFDATESOURCEDSET.  */
    
    /* YW001: added checks on &reftimesourcevar */      
    %if &reftimevar eq and &reftimesourcevar ne %then
    %do;
       %put %str(RTN)OTE: TU_REFDAT: REFTIMEVAR is blank. REFTIMESOURCEVAR (=&reftimesourcevar) will not be used.;
       %let reftimesourcevar=;    
    %end;
    
    %if &reftimesourcevar ne %then
    %do;    
       %if %tu_chkvarsexist(&prefix._refdataexist, &reftimesourcevar) ne  %then
       %do;
          %put %str(RTE)RROR: TU_REFDAT: The REFTIMESOURCEVAR variable (&REFTIMESOURCEVAR) does not exist on the REFDATESOURCEDSET dataset (&REFDATESOURCEDSET).;
          %let g_abort=1;
       %end;          
    %end;
 %end; /* end-if on &refdateoption eq OTHER */

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;

 /*
 / If the input dataset name is the same as the output dataset name,
 / write a note to the log.
 / Ignore dataset options when comparing dataset names. SL001
 /----------------------------------------------------------------------------*/

 %if %qscan(%upcase(&dsetin), 1, %str(%()) eq %qscan(%upcase(&dsetout), 1, %str(%()) %then
 %do;
    %put %str(RTN)OTE: TU_REFDAT: The input dataset name (&dsetin) is the same as the output dataset name (&dsetout).;
 %end;  /* end-if User-specified parameters DSETIN and DSETOUT are the same.  */

 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/

 /*
 / Set source dataset and variable for TREAT, VISIT and RAND options.
 / YW001: Added reftimesourcevar.
 /----------------------------------------------------------------------------*/

 %if &refdateoption eq TREAT %then
 %do;
    %let refdatesourcedset = &exposuredset;
    %let refdatesourcevar  = EXSTDT;
    %let reftimesourcevar  = EXSTTM;
 %end;  /* end-if User-specified REFDATEOPTION is TREAT.  */

 %if &refdateoption eq VISIT %then
 %do;
    %let refdatesourcedset = &visitdset;
    %let refdatesourcevar  = VISITDT;
    %let reftimesourcevar  = VISITTM;
 %end;  /* end-if User-specified REFDATEOPTION is VISIT.  */

 %if &refdateoption eq RAND %then
 %do;
    %let refdatesourcedset = &randdset;
    %let refdatesourcevar  = RANDDT;
    %let reftimesourcevar  = ;
 %end;  /* end-if  User-specified REFDATEOPTION is RAND.  */
 
 /* YW001: Added check on &reftimesourcevar */ 
 %if &reftimevar eq %then %let reftimesourcevar=;
 
 %if &reftimesourcevar ne %then
 %do;
    data &prefix._refdataexist;
       if 0 then set %unquote(&refdatesourcedset);
    run;
    %if %tu_chkvarsexist(&prefix._refdataexist, &reftimesourcevar) ne  %then
    %do;
       %put %str(RTN)OTE: TU_REFDAT: The time source variable (&REFTIMESOURCEVAR) does not exist on the REFDATESOURCEDSET dataset (&REFDATESOURCEDSET).;
       %put %str(RTN)OTE: TU_REFDAT: REFTIMEVAR (&REFTIMEVAR) will not be derived.;
       %let reftimesourcevar=;
    %end;   
 %end;

 /*
 / Subset source dataset by where clause and visit number.
 / Unquote source dataset name, to avoid problems that may occur if dataset
 / options have been specified - SL001.
 / Use IF statement for applying the REFDATEDSETSUBSET condition, rather than a
 / WHERE statement, so that user may specify a WHERE dataset option with 
 / &refdatesourcedset. SL001
 /----------------------------------------------------------------------------*/

 data &prefix._source(keep = studyid subjid &refdatesourcevar &reftimesourcevar);
      set %unquote(&refdatesourcedset);

      %if &refdatedsetsubset ne %then
      %do;
         if %unquote(&refdatedsetsubset);
      %end;  /* end-if Parameter REFDATEDSETSUBSET is specified.  */
      %if &refdatevisitnum ne %then
      %do;
         if visitnum = &refdatevisitnum;
      %end;  /* end-if Parameter REFDATEVISITNUM is specified.  */
 run;

 proc sort data = &prefix._source (keep  = studyid subjid &refdatesourcevar &reftimesourcevar
                                   where = (&refdatesourcevar ne .) )
           out  = &prefix._refsort;
      by studyid subjid &refdatesourcevar &reftimesourcevar;    /* YW001 */
 run;

 /* ems003 
 /  Test to determine if records were found with 
 /  refdat for merge with input dataset.
 /  YW001: Added code for &reftimesoucevar ne.
 /----------------------------------------------------------------------------*/
 %if %tu_nobs(&prefix._refsort) ge 1 %then
 %do;  /* Records containing the reference date found available for merge. */
     
    %if &reftimesourcevar ne %then 
    %do;
       proc sort data=&prefix._refsort out=&prefix._reftime;
            by studyid subjid &refdatesourcevar &reftimesourcevar;
            where not missing(&reftimesourcevar);
       run;
       
       proc sort data=&prefix._refsort out=&prefix._refdate1 (drop=&reftimesourcevar) nodupkey;
            by studyid subjid &refdatesourcevar;
       run;
           
       data &prefix._refdate;
            merge &prefix._refdate1 
                  &prefix._reftime;
            by studyid subjid &refdatesourcevar;                    
            if first.subjid;
            rename &refdatesourcevar = &refdatevar
                   &reftimesourcevar = &reftimevar;
       run;
    %end;
    %else %do;
       data &prefix._refdate;
            set &prefix._refsort;
            by studyid subjid &refdatesourcevar;    
            if first.subjid;
            rename &refdatesourcevar = &refdatevar;               
       run;    
    %end;  /* end-if on &reftimesourcevar ne */
       
    proc sort data=%unquote(&dsetin) out=&prefix._rdmain;
         by studyid subjid;
    run;
   
    data %unquote(&dsetout);
         merge &prefix._rdmain(in=a) &prefix._refdate;
         by studyid subjid;
         if a;
    run;
 %end; /* end-if records containing the reference date found available for merge. */
 
 %else
 %do;  /* Records containing the reference date not found. */
    %put %str(RTW)ARNING: TU_REFDAT: No reference date found. This may be due to the following: ;
    %put %str(RTW)ARNING: TU_REFDAT:   - no non-missing values found for the refdat;

    %if &refdatedsetsubset ne %then
    %do;
       %put %str(RTW)ARNING: TU_REFDAT:   - subset specified in REFDATEDSETSUBSET (&refdatedsetsubset) not finding any records;
    %end;  /* end-if Parameter REFDATEDSETSUBSET is specified.  */
    
    %if &refdatevisitnum ne %then
    %do;
       %put %str(RTW)ARNING: TU_REFDAT:   - no records found where &visitdset..VISITNUM=REFDATEVISITNUM (&refdatevisitnum);
    %end;  /* end-if Parameter REFDATEVISITNUM is specified.  */

    %put %str(RTW)ARNING: TU_REFDAT: Input dataset copied to output dataset with addition of &refdatevar set to missing.;

    data %unquote(&dsetout);
         set %unquote(&dsetin);
         &refdatevar=.;
         %if &reftimesourcevar ne %then 
         %do;
            &reftimesourcevar = .;
         %end;                  
    run;
 %end; /* end-if records containing the reference date not found. */

 /*
 / Delete temporary datasets used in this macro.
 /----------------------------------------------------------------------------*/

 %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tu_refdat;
