/*******************************************************************************
|
| Macro Name:      tu_labfg
|
| Macro Version:   3
|
| SAS Version:     8.2
|
| Created By:      Mark Luff / Eric Simms
|
| Date:            25-Jun-2004
|
| Macro Purpose:   Lab flagging and lab value conversion
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME            DESCRIPTION                          REQ/OPT  DEFAULT
| --------------  -----------------------------------  -------  ---------------
| DSETIN          Specifies the dataset for which SI   REQ      (Blank)
|                 conversion and lab flagging needs 
|                 to be done.
|                 Valid values: valid dataset name
|
| DSETOUT         Specifies the name of the output     REQ      (Blank)
|                 dataset to be created.
|                 Valid values: valid dataset name
|
| BASELINETYPE    Calculation of baseline option       REQ      LAST		** GK001 **
|                 when there are multiple records
|                 following into baseline range.
|                 Valid values:
|                 FIRST-  First non-missing baseline
|                         record is used and marked 
|                         as baseline when data are 
|                         sorted in chronical order.
|                         Others are marked as 
|                         pre-therapy.
|
|                 LAST-   Last non-missing baseline 
|                         record is used and marked 
|                         as baseline when data are
|                         sorted in chronical order. 
|                         Others are marked as 
|                         pre-therapy.
|
|                 MEAN-   Mean value of baseline 
|                         records is used as baseline.  
|                         All baseline records are 
|                         marked as baseline.
|
|                 MEDIAN- Median value of baseline 
|                         records is used as baseline.  
|                         All baseline records are 
|                         marked as baseline.
|
| NRFGYN          Y/N - perform Normal Range flagging? REQ      Y
|
| BSFGYN          Y/N - perform Change from Baseline   REQ      Y
|                 flagging?
|
| CCFGYN          Y/N - perform Clinical Concern       REQ      Y
|                 flagging?
|
| CONVERTYN       Y/N - perform Laboratory value and   REQ      Y
|                 normal range conversion to standard
|                 units?
|
| BASELINEYN      Y/N - perform calculation of         REQ      Y
|                 baseline?
|
| LABCRITDSET     Specifies the SI dataset which       OPT      dmdata.labcrit
|                 contains the lab flagging criteria.
|                 Required if BSFGYN=Y or CCFGYN=Y.
|
| NRDSET          Specifies the SI dataset which       OPT      dmdata.nr
|                 contains the normal range 
|                 information.
|
| DEMODSET        SI Demography dataset name.          OPT      dmdata.demo
|
| STMEDDSET       SI Study medication dataset name.    OPT      dmdata.exposure
|
| STMEDDSETSUBSET Where clause to be applied to        OPT      (Blank)
|                 study medication dataset.
|
| CONVDSET        Specifies the SI dataset which       OPT      dmdata.conv
|                 contains the conversion factors.
|
| FLAGGINGSUBSET  Specifies which records should have  OPT      %str(lbcat in
|                 lab flagging done.                             ('CHEM','HAEM'))
|
| BASELINEOPTION  Calculation of baseline option.      OPT      DATE
|                    Valid values:
|
|                    DATE   - Select baseline records based on lab collection
|                             date (LBDT) and visit number (VISITNUM) compared
|                             to study medication start date (EXSTDT) and
|                             visit number (VISITNUM). Note that when start
|                             date and visit of medication is the same as lab
|                             date and visit, it is regarded as post-baseline.
|
|                    RELDAY - Select baseline records by relative days. The
|                             parameter RELDAYS must contain a positive number.
|
|                    VISIT  - Select baseline records specified by VISITNUM codes
|                             passed in the parameters STARTVISNUM and
|                             ENDVISNUM.
|
|                    TIME   - Select baseline records based on lab collection
|                             date (LBDT) and time (LBACTTM) compared to study
|                             medication start date (EXSTDT) and time (EXSTTM).
|
| RELDAYS         Number of days prior to start of     OPT      (Blank)
|                 study medication, used to identify
|                 records to be considered as
|                 baseline. Required if
|                 BASELINEOPTION is RELDAY.
|
| STARTVISNUM     VISITNUM value for start of range    OPT      (Blank)
|                 to identify records to be
|                 considered as baseline. Required if
|                 BASELINEOPTION is VISIT.
|
| ENDVISNUM       VISITNUM value for end of range to   OPT      (Blank)
|                 identify records to be considered
|                 as baseline. Required if
|                 BASELINEOPTION is VISIT.
|
| DGCD            LABCRIT compound identifier.  Used   OPT      (Blank)
|                 to select compound specific criteria.
|
| STUDYID         LABCRIT study identifier. Used to    OPT      (Blank)
|                 select study specific criteria.
| --------------  -----------------------------------  -------  ---------------
|
| The macro references the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETIN            Req      Parameter specified dataset
| &LABCRITDSET       Opt      Parameter specified dataset
| -----------------  -------  -------------------------------------------------
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
|(@) tu_baseln
|(@) tu_bsfg
|(@) tu_ccfg
|(@) tu_conv
|(@) tu_chkvarsexist
|(@) tu_nrfg
|(@) tu_putglobals
|(@) tu_tidyup
|
| Example:
|    %tu_labfg(
|         dsetin          = _lab1,
|         dsetout         = _lab2,
|         ccfgyn          = N,
|         dgcd            = cxa,
|         studyid         = 20005 
|         );
|
|******************************************************************************
| Change Log
| Modified By :             Yongwei Wang
| Date of Modification :    07-Nov-05
| New Version Number :      02-001
| Modification ID :         YW001
| Reason For Modification : Required by change request HRT0097. if &NRDSET is 
|                           given when &NRFGYN is Y, a RTNOTE will be written
|                           to log, instead of RTERROR.
|-------------------------------------------------------------------------------
| Modified By:              Shan Lee
| Date of Modification:     28-Sep-07
| New version/draft number: 2/2
| Modification ID:          SL001
| Reason For Modification:  Enable dataset options to be specified with input
|                           and output dataset names. HRT0184
|-------------------------------------------------------------------------------
| Modified By:				Gail Knowlton
| Date of Modification:		23-Jul-2008
| New version/draft number:	3/1
| Modification ID:			GK001
| Reason For Modification: Surfaced 'BASELINETYPE' - a new parameter for tu_baseln
*******************************************************************************/
%macro tu_labfg (
     dsetin          = ,                /* Input dataset name */
     dsetout         = ,                /* Output dataset name */
     baselinetype    = LAST,            /* Select method of calculating baseline, when there are multiple baseline obs. */			
     nrfgyn          = Y,               /* F1 Normal Range flagging */
     bsfgyn          = Y,               /* F2 Change from Baseline flagging */
     ccfgyn          = Y,               /* F3 Clinical Concern flagging */
     convertyn       = Y,               /* Laboratory value and normal range conversion */
     baselineyn      = Y,               /* Calculation of baseline */
     labcritdset     = DMDATA.LABCRIT,  /* Lab flagging criteria dataset name */
     nrdset          = DMDATA.NR,       /* Normal range dataset name */
     demodset        = DMDATA.DEMO,     /* Demography dataset name */
     stmeddset       = DMDATA.EXPOSURE, /* Study medication dataset name */
     stmeddsetsubset = ,                /* Where clause to be applied to study medication dataset */
     convdset        = DMDATA.CONV,     /* Conversion dataset name */
     flaggingsubset  = %STR(LBCAT IN ('CHEM','HAEM')), /* IF clause to identify records to be flagged */
     baselineoption  = DATE,            /* Calculation of baseline option */
     reldays         = ,                /* Number of days prior to start of study medication */
     startvisnum     = ,                /* VISITNUM value for start of baseline range */
     endvisnum       = ,                /* VISITNUM value for end of baseline range */
     dgcd            = ,                /* LABCRIT compound identifier */
     studyid         =                  /* LABCRIT study identifier */
        );

 /*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion;
 %let MacroVersion = 3;  	/* GK001 */
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals() 

 /*
 / PARAMETER VALIDATION
 /----------------------------------------------------------------------------*/

 %let dsetin          = %nrbquote(&dsetin);
 %let dsetout         = %nrbquote(&dsetout);
 %let nrfgyn          = %nrbquote(%upcase(%substr(&nrfgyn, 1, 1)));
 %let bsfgyn          = %nrbquote(%upcase(%substr(&bsfgyn, 1, 1)));
 %let ccfgyn          = %nrbquote(%upcase(%substr(&ccfgyn, 1, 1)));
 %let convertyn       = %nrbquote(%upcase(%substr(&convertyn, 1, 1)));
 %let baselineyn      = %nrbquote(%upcase(%substr(&baselineyn, 1, 1)));
 %let labcritdset     = %nrbquote(&labcritdset);
 %let stmeddsetsubset = %nrbquote(&stmeddsetsubset);
 %let flaggingsubset  = %nrbquote(&flaggingsubset);

 /*
 / Check for required parameters.
 /----------------------------------------------------------------------------*/

 %if &dsetin eq %then
 %do;
    %put %str(RTE)RROR: TU_LABFG: The parameter DSETIN is required.;
    %let g_abort=1;
 %end;

 %if &dsetout eq %then
 %do;
    %put %str(RTE)RROR: TU_LABFG: The parameter DSETOUT is required.;
    %let g_abort=1;
 %end;

 %if &nrfgyn eq %then
 %do;
    %put %str(RTE)RROR: TU_LABFG: The parameter NRFGYN is required.;
    %let g_abort=1;
 %end;

 %if &bsfgyn eq %then
 %do;
    %put %str(RTE)RROR: TU_LABFG: The parameter BSFGYN is required.;
    %let g_abort=1;
 %end;

 %if &ccfgyn eq %then
 %do;
    %put %str(RTE)RROR: TU_LABFG: The parameter CCFGYN is required.;
    %let g_abort=1;
 %end;

 %if &convertyn eq %then
 %do;
    %put %str(RTE)RROR: TU_LABFG: The parameter CONVERTYN is required.;
    %let g_abort=1;
 %end;

 %if &baselineyn eq %then
 %do;
    %put %str(RTE)RROR: TU_LABFG: The parameter BASELINEYN is required.;
    %let g_abort=1;
 %end;

 %if (&bsfgyn eq Y or &ccfgyn eq Y) and &labcritdset eq %then
 %do;
    %put %str(RTE)RROR: TU_LABFG: The parameter LABCRITDSET is required when BSFGYN=Y or CCFGYN=Y.;
    %let g_abort=1;
 %end;

 /* YW001: Changed RTERROR to RTNOTE */
 %if &nrfgyn eq Y and %nrbquote(&nrdset) eq %then
 %do;
    %put %str(RTN)OTE: TU_LABFG: The parameter NRDSET is not specified when NRFGYN=Y.;
 %end;

 /*
 / Check for valid parameter values.
 /----------------------------------------------------------------------------*/

 %if &nrfgyn ne Y and &nrfgyn ne N %then
 %do;
    %put %str(RTE)RROR: TU_LABFG: NRFGYN should be either Y or N.;
    %let g_abort=1;
 %end;

 %if &bsfgyn ne Y and &bsfgyn ne N %then
 %do;
    %put %str(RTE)RROR: TU_LABFG: BSFGYN should be either Y or N.;
    %let g_abort=1;
 %end;

 %if &ccfgyn ne Y and &ccfgyn ne N %then
 %do;
    %put %str(RTE)RROR: TU_LABFG: CCFGYN should be either Y or N.;
    %let g_abort=1;
 %end;

 %if &convertyn ne Y and &convertyn ne N %then
 %do;
    %put %str(RTE)RROR: TU_LABFG: CONVERTYN should be either Y or N.;
    %let g_abort=1;
 %end;

 %if &baselineyn ne Y and &baselineyn ne N %then
 %do;
    %put %str(RTE)RROR: TU_LABFG: BASELINEYN should be either Y or N.;
    %let g_abort=1;
 %end;

 /*
 / Check for existing datasets.
 / Allow dataset options to be specified with DSETIN. SL001
 /----------------------------------------------------------------------------*/

 %if %sysfunc(exist(%qscan(&dsetin, 1, %str(%()))) eq 0 %then
 %do;
    %put %str(RTE)RROR: TU_LABFG: The dataset &dsetin does not exist.;
    %let g_abort=1;
 %end;

 %if (&ccfgyn eq Y or &bsfgyn eq Y) and %sysfunc(exist(%qscan(&labcritdset, 1, %str(%()))) eq 0 %then
 %do;
    %put %str(RTE)RROR: TU_LABFG: The dataset &labcritdset does not exist.;
    %let g_abort=1;
 %end;

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;

 /*
 / If the input dataset name is the same as the output dataset name,
 / write a note to the log.
 / When comparing dataset names, ignore dataset options. SL001
 /----------------------------------------------------------------------------*/

 %if %upcase(%qscan(&dsetin, 1, %str(%())) eq %upcase(%qscan(&dsetout, 1, %str(%())) %then
 %do;
    %put %str(RTN)OTE: TU_LABFG: The input dataset name (&dsetin) is the same as the output dataset name (&dsetout).;
 %end;

 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/

 %local prefix;
 %let prefix = _labfg;   /* Root name for temporary work datasets */

 /*
 / Split data according to &FLAGGINGSUBSET into data to be processed and
 / data to be left as is.               
 /----------------------------------------------------------------------------*/

 data &prefix._lab1 &prefix._labu;
      set %unquote(&dsetin);

      %if &flaggingsubset ne %then
      %do;
         if %unquote(&flaggingsubset) then
            output &prefix._lab1;
         else
            output &prefix._labu;
      %end;

      %else
      %do;
         output &prefix._lab1;
      %end;
 run;

 /*
 / Initialise counter for appending to temporary dataset names for the
 / purpose of tracking datasets through a number of optional sequential
 / data processing steps.
 /----------------------------------------------------------------------------*/

 %local i;
 %let i = 1;

 /*
 / Normal range flagging.
 /----------------------------------------------------------------------------*/

 %if &nrfgyn eq Y %then
 %do;
    %tu_nrfg (
         dsetin   = &prefix._lab&i,
         dsetout  = &prefix._lab%eval(&i+1),
         nrdset   = &nrdset,
         demodset = &demodset
    );

    %let i = %eval(&i + 1);
 %end;

 /*
 / Lab value and normal range conversion to SI units.
 /----------------------------------------------------------------------------*/

 %if &convertyn eq Y %then
 %do;
    %tu_conv (
         dsetin   = &prefix._lab&i,
         dsetout  = &prefix._lab%eval(&i+1),
         convdset = &convdset
    );

    %let i = %eval(&i + 1);
 %end;

 /*
 / Calculation of baseline.
 /----------------------------------------------------------------------------*/

 %if &baselineyn eq Y %then
 %do;
    %tu_baseln (
         dsetin          = &prefix._lab&i,
         dsetout         = &prefix._lab%eval(&i+1),
         baselinetype    = &baselinetype,		/* GK001 */
         baselineoption  = &baselineoption,
         stmeddset       = &stmeddset,
         stmeddsetsubset = &stmeddsetsubset,
         reldays         = &reldays,
         startvisnum     = &startvisnum,
         endvisnum       = &endvisnum
    );

    %let i = %eval(&i + 1);
 %end;

 /*
 / Identify F2 and F3 lab flagging criteria.
 /----------------------------------------------------------------------------*/

 %if &bsfgyn eq Y or &ccfgyn eq Y %then
 %do;

    /*
    / Combine study specific, compound specific (if available) and generic
    / criteria. Keep only F2 and F3 criteria.
    /-------------------------------------------------------------------------*/
    
    data &prefix._labcritexist;
       if 0 then set %unquote(&labcritdset);
    run;

    %if %tu_chkvarsexist(&prefix._labcritexist, dgcd) eq  %then
    %do;
       proc sql;
            create table &prefix._labcrit as
            select * from (
               /* Obtain study specific lab flagging criteria data */
               select *, 1 as _ord
               from %unquote(&labcritdset)
               where dgcd eq upcase("&dgcd") and
                  studyid eq upcase("&studyid")
   
               union
   
               /* Obtain compound specific lab flagging criteria data */
               select *, 2 as _ord
               from %unquote(&labcritdset)
               where dgcd eq upcase("&dgcd") and
                     studyid is null
   
               union
   
               /* Obtain generic lab flagging criteria data */
               select *, 3 as _ord
               from %unquote(&labcritdset)
               where dgcd is null and
                     studyid is null
            )
            where fgtyp in ('F2','F3')
            order by fgtyp, lbtestcd, _ord;
       quit;
    %end; /* DGCD variable is on the &LABCRITDSET dataset. */
    %else
    %do;
       proc sql;
            create table &prefix._labcrit as
            select * from (
               /* Obtain study specific lab flagging criteria data */
               select *, 1 as _ord
               from %unquote(&labcritdset)
               where studyid eq upcase("&studyid")
   
               union
   
               /* Obtain generic lab flagging criteria data */
               select *, 2 as _ord
               from %unquote(&labcritdset)
               where studyid is null
            )
            where fgtyp in ('F2','F3')
            order by fgtyp, lbtestcd, _ord;
       quit;
    %end; /* DGCD variable is not on the &LABCRITDSET dataset. */

    /*
    / For each lab test, select only one set of lab flagging criteria from
    / study specific, compound specific or generic criteria, in that order
    / of preference.
    /-------------------------------------------------------------------------*/

    data &prefix._xlabcrit (drop = _scg _ord);
         set &prefix._labcrit;
         by fgtyp lbtestcd _ord;
         retain _scg;

         /* Determine criteria origin from first record for each lab test */
         if first.lbtestcd then _scg = _ord;

         /* Keep only selected criteria */
         if _scg eq _ord;
    run;

 %end;  /* end-if on &bsfgyn eq Y or &ccfgyn eq Y */

 /*
 / Change from baseline flagging.
 /----------------------------------------------------------------------------*/

 %if &bsfgyn eq Y %then
 %do;
    %tu_bsfg (
         dsetin      = &prefix._lab&i,
         dsetout     = &prefix._lab%eval(&i+1),
         labcritdset = &prefix._xlabcrit,
         demodset    = &demodset
    );

    %let i = %eval(&i + 1);
 %end;

 /*
 / Clinical concern flagging.
 /----------------------------------------------------------------------------*/

 %if &ccfgyn eq Y %then
 %do;
    %tu_ccfg (
         dsetin      = &prefix._lab&i,
         dsetout     = &prefix._lab%eval(&i+1),
         labcritdset = &prefix._xlabcrit,
         demodset    = &demodset
    );

    %let i = %eval(&i + 1);
 %end;

 /*
 / Add non-processed data back into processed data. These records were
 / split above based on the &FLAGGINGSUBSET parameter.
 /----------------------------------------------------------------------------*/

 data %unquote(&dsetout);
      set &prefix._lab&i &prefix._labu;
 run;

 /*
 / Delete temporary datasets used in this macro.
 /----------------------------------------------------------------------------*/

 %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tu_labfg;
