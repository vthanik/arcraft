/*******************************************************************************
|
| Macro Name:      tu_adbaseln
|
| Macro Version:   2 build 1
|
| SAS Version:     9.1.3
|
| Created By:      Anthony Cooper
|
| Date:            27-May-2014
|
| Macro Purpose:   Calculation of change from baseline
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME            DESCRIPTION                          REQ/OPT  DEFAULT
| --------------  -----------------------------------  -------  ---------------
| DSETIN          Specifies the dataset for which the  REQ      (Blank)
|                 change from baseline variables are 
|                 to be added.
|                 Valid values: valid dataset name
|
| DSETOUT         Specifies the name of the output     REQ      (Blank)
|                 dataset to be created.
|                 Valid values: valid dataset name
|
| REDERIVE        Specifies whether the baseline will  REQ      N
| BASELINEYN      be re-derived according to
|                 BASELINEOPTION and BASELINETYPE or
|                 the SDTM baseline flag will be used
|                 to identify the baseline value.
|                 Valid values:
|                 Y or N
|
| DOMAINCODE      Specifies the SDTM domain code which REQ      (Blank)
|                 is used to identify the baseline
|                 flag variable on the input dataset
|                 and identify qualifier variables.
|                 Valid values:
|                 2 letter SDTM domain code
|
| BASELINEOPTION  Specifies the option which is used   OPT      DATE
|                 to identify the set of observations
|                 from which the baseline will be
|                 determined.
|                 Required if REDERIVEBASELINEYN is Y
|                   
|                 Valid values:
|
|                 DATE   - Select baseline records based on analysis date
|                          (ADT) compared to treatment start date
|                          (TRTSDT). Note that when TRTSDT is the same as
|                          ADT it is regarded as pre-therapy.
|
|                 TIME   - Select baseline records based on analysis date
|                          (ADT) and time (ATM) compared to treatment start
|                          date (TRTSDT) and time (TRTSTM).
|
|                 RELDAY - Select baseline records by number of relative days 
|                          specified in RELDAYS parameter. 
|
|                 VISIT  - Select baseline records specified by VISITNUM values
|                          passed in by the parameters STARTVISNUM and
|                          ENDVISNUM.
|
|                 TPT    - Select baseline records specified by ATPTN values
|                          passed in by the parameters STARTVISNUM and
|                          ENDVISNUM. 
|
|                 VISITTPT-Select baseline records specified by VISITNUM and ATPTN
|                          values passed in by the parameters STARTVISNUM and
|                          ENDVISNUM. The first number in STARTVISNUM/ENDVISITNUM 
|                          will be for start/end VISITNUM and the second for 
|                          start/end ATPTN
|
|                 If By-variables are needed, then after BASELINEOPTION parameter
|                 add the word 'by' and follow that with by-variables that are
|                 desired for the study.
|                 (i.e. BASELINEOPTION=VISITTPT by visitnum visit,)
|                 This option is not valid if BASELINEOPTION is DATE or TIME
|
| RELDAYS         Specifies the number of days prior 
|                 to treatment start date, used to     OPT      (Blank)
|                 identify records to be considered
|                 as baseline. Required if
|                 BASELINEOPTION is RELDAY.
|                 Valid values: a positive number 
|
| STARTVISNUM     Specifies the start VISITNUM and/or  OPT      (Blank)
|                 ATPTN value(s) to be used to
|                 identify records to be considered
|                 as baseline. 
|                 Required if BASELINEOPTION is
|                 VISIT/TPT/VISITTPT. If  
|                 BASELINEOPTION is VISITTPT, it should 
|                 include two words: first is for 
|                 VISITNUM and second for ATPTN.
|
| ENDVISNUM       Specifies the end VISITNUM and/or    OPT      (Blank)
|                 ATPTN value(s) to be used to
|                 identify records to be considered
|                 as baseline. 
|                 Required if BASELINEOPTION is
|                 VISIT/TPT/VISITTPT. If  
|                 BASELINEOPTION is VISITTPT, it should 
|                 include two words: first is for 
|                 VISITNUM and second for ATPTN.
|
| BASELINETYPE    Calculation of baseline option       OPT      LAST
|                 when there are multiple records
|                 following into baseline range.
|                 Required if REDERIVEBASELINEYN is Y
|                 Valid values:
|                 FIRST  - First non-missing baseline record is used and 
|                          marked as  baseline when data is sorted by 
|                          chronical order. Others are marked as pre-therapy
|
|                 LAST   - Last non-missing baseline record is used and 
|                          marked as  baseline when data is sorted by 
|                          chronical order. Others are marked as pre-therapy
|
|                 MEAN   - Mean value of baseline records is used as baseline.  
|                          All baseline records are marked as baseline
|
|                 MEDIAN - Median value of baseline records is used as baseline.  
|                          All baseline records are marked as baseline
|                 If unscheduleds need to be excluded from baseline calculation,
|                 then second word of parameter call should be NOUNS.
|                 Otherwise this parameter call should only have one word.                 
|
| DERIVEDBASE     Specifies user-defined SAS           OPT     (Blank)
| LINEROWINFO     statement(s) which can be used to
|                 populate analysis visit/timepoint 
|                 variables (e.g. AVISIT, AVISITN,
|                 ATPT, ATPTN) on derived baseline
|                 observations when BASELINETYPE
|                 is MEAN or MEDIAN.
|                 e.g. %str(avisitn=888; avisit=
|                 'Baseline')
|
| DSETINADSL      Specifies the name of the ADSL or    OPT     (Blank)
|                 ADTRT dataset which will be used to
|                 populate subject level and 
|                 treatment variables on derived
|                 baseline observations when 
|                 BASELINETYPE is MEAN or MEDIAN
|
| ADSLVARS        Specifies the list of variables      OPT      (Blank)
|                 from the ADSL or ADTRT dataset
|                 which will be used to populate
|                 subject level variables on
|                 derived baseline observations
|                 when BASELINETYPE is MEAN or
|                 MEDIAN
|
| ADGETTRT        Specifies the by variables which     OPT      (Blank)
| MERGEVARS       will be used to merge treatment
|                 variables from the ADSL or ADTRT
|                 dataset onto derived baseline
|                 from ADSL/ADTRT dataset onto
|                 derived baseline observations when
|                 BASELINETYPE is MEAN or MEDIAN
|
| ADGETTRTVARS    Specifies the list of variables      OPT      (Blank)
|                 from the ADSL or ADTRT dataset
|                 which will be used to populate
|                 treatment variables on derived
|                 baseline observations when 
|                 BASELINETYPE is MEAN or MEDIAN
|
| --------------  -----------------------------------  -------  ---------------
|
| The macro references the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETIN            Req      Parameter specified dataset
| &DSETINADSL        Opt      Parameter specified dataset
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
|(@) tu_chkvarsexist
|(@) tu_putglobals
|(@) tu_nobs
|(@) tu_tidyup
|(@) tu_adgetadslvars
|(@) tu_adgettrt
|
| Examples:
|    %tu_adbaseln(
|         dsetin             = _lab1,
|         dsetout            = _lab2,
|         rederivebaselineyn = N,
|         domaincode         = LB
|         );
|
|    %tu_adbaseln(
|         dsetin             = _lab1,
|         dsetout            = _lab2,
|         rederivebaselineyn = Y,
|         domaincode         = LB,
|         baselineoption     = VISIT,
|         startvisnum        = 10,
|         endvisnum          = 20
|         );
|
|******************************************************************************
| Change Log
|
| Modified By:              Anthony J Cooper
| Date of Modification:     17-Oct-2014
| New version/draft number: 1 build 2
| Modification ID:          AJC001
| Reason For Modification:  1) Parameter validation - check that DOMAINCODE is
|                           two characters.
|                           2) If a single baseline (mean or median) is derived
|                           for a XO study then APERIOD/APERIODC will be in
|                           ADGETTRTMERGEVARS but not in the BASELINEOPTION by
|                           variables. This causes an RTERROR when tu_adgettrt
|                           is called. The code has been updated to attempt to
|                           populate any variables in ADGETTRTMERGEVARS that
|                           do not exist on the derived baseline row dataset
|                           using the values in the dataset which went into
|                           PROC SUMMARY. If the values cannot be worked out
|                           an RTWARNING is issued and tu_adgettrt skipped.
|
| Modified By:              Anthony J Cooper
| Date of Modification:     23-Oct-2014
| New version/draft number: 1 build 3
| Modification ID:          AJC002
| Reason For Modification:  1) Check for existence of PARAMLBL and use as a
|                           by variable if found.
|                           2) Check for existence of qualifier variables and
|                           use as by variables if found: xxPOS, xxSPEC, 
|                           xxMETHOD, xxLOC, and xxTESTCD where xx is the
|                           DOMAINCODE.
|                           3) Parameter validation - DOMAINCODE is now a
|                           required variable rather than being conditional on
|                           the value of REDERIVEBASELINEYN.
|
| Modified By:              Anthony J Cooper
| Date of Modification:     22-Jan-2015
| New version/draft number: 2 build 1
| Modification ID:          AJC003
| Reason For Modification:  HRT0307 - When creating derived rows (BASELINETYPE
|                           is MEAN or MEDIAN) AVALC and BASEC are no longer
|                           populated to be consistent with the domain macros 
|                           (AVALC is generally missing for numeric results)
|
*******************************************************************************/

%macro tu_adbaseln(
     dsetin             = ,          /* Input dataset name */
     dsetout            = ,          /* Output dataset name */
     rederivebaselineyn = N,         /* Flag to indicate if baseline is to be re-derived, otherwise use SDTM baseline flag */
     baselineoption     = DATE,      /* Calculation of baseline option: date, time, relday, visit, tpt or visittpt */
     reldays            = ,          /* Number of days prior to start of study medication */
     startvisnum        = ,          /* VISITNUM and/or ATPTN value for start of baseline range */
     endvisnum          = ,          /* VISITNUM and/or ATPTN value for end of baseline range */
     domaincode         = ,          /* SDTM dataset domain code used to identify baseline flag: LB, VS etc. */
     baselinetype       = LAST,      /* How to calculate baseline for multiple baseline records: first, last, mean or median */
     derivedbaselinerowinfo = ,      /* SAS statement(s) to define visit/timepoint variables on derived baseline observations (baselinetype of mean or median) */
     dsetinadsl         = ,          /* Input ADSL or ADTRT dataset */
     adslvars           = ,          /* List of subject level variables to merge onto derived baseline observations */
     adgettrtmergevars  = ,          /* Variables used to merge treatment information onto derived baseline observations */
     adgettrtvars       =            /* List of treatment variables to merge onto derived baseline observations */
     );

 /*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion;
 %let MacroVersion = 2 build 1;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals()

 /*
 / Define local variables
 /----------------------------------------------------------------------------*/
 
 %local prefix l_calcbaselineflag startatptn endatptn l_byvar unschedule_flag l_parcat1 l_anrind 
        l_trtmergevarsnotexist l_calladgettrtflag l_paramlbl l_qualifiers;

 %let prefix = _adbaseln;   /* Root name for temporary work datasets */ 
 %let l_calcbaselineflag=0;
 %let l_byvar=;
 %let unschedule_flag = Y;
 %let l_parcat1=;
 %let l_calladgettrtflag=1;
 %let l_paramlbl=;
 
 /*
 / PARAMETER VALIDATION
 /----------------------------------------------------------------------------*/

 %let dsetin                 = %nrbquote(&dsetin);
 %let dsetout                = %nrbquote(&dsetout);
 %let rederivebaselineyn     = %qupcase(&rederivebaselineyn);  
 %let baselineoption         = %nrbquote(%upcase(&baselineoption));
 %let reldays                = %nrbquote(&reldays);
 %let startvisnum            = %nrbquote(&startvisnum);
 %let endvisnum              = %nrbquote(&endvisnum);
 %let domaincode             = %qupcase(&domaincode);
 %let baselinetype           = %qupcase(&baselinetype);  
 %let derivedbaselinerowinfo = %nrbquote(&derivedbaselinerowinfo);
 %let dsetinadsl             = %nrbquote(&dsetinadsl);
 %let adslvars               = %nrbquote(&adslvars);
 %let adgettrtmergevars      = %nrbquote(&adgettrtmergevars);
 %let adgettrtvars           = %nrbquote(&adgettrtvars);

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

 %if ( &rederivebaselineyn ne Y )  and ( &rederivebaselineyn ne N ) %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The value of parameter REDERIVEBASELINEYN should be either Y or N.;
    %let g_abort=1;
 %end;

 /* AJC002: DOMAINCODE is now a required parameter */
 %if ( &domaincode eq ) %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter DOMAINCODE is required.;
    %let g_abort=1;
 %end;
 %else %if ( %length(&domaincode) ne 2 ) %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter DOMAINCODE(=&domaincode) must be two characters long.;
    %let g_abort=1;
 %end; /* AJC001 */

 %if ( &rederivebaselineyn eq Y ) %then
 %do;

    %if &baselineoption eq %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: The parameter BASELINEOPTION is required when REDERIVEBASELINEYN is &rederivebaselineyn.;
       %let g_abort=1;
    %end;
    
    %if &baselinetype eq %then       
    %do;
       %put %str(RTE)RROR: &sysmacroname: The parameter BASELINETYPE is required when REDERIVEBASELINEYN is &rederivebaselineyn.;
       %let g_abort=1;
    %end;

 %end;

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;

 /*
 / Check for existing datasets.
 /----------------------------------------------------------------------------*/

 %if %sysfunc(exist(%qscan(&dsetin, 1, %str(%()))) eq 0 %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The dataset DSETIN (=&dsetin) does not exist.;
    %let g_abort=1;
 %end;

 /*
 / Check for correct parameter values.
 / Check for optional keywords on BASELINEOPTION and BASELINETYPE
 /----------------------------------------------------------------------------*/

 %if (%qscan(&baselineoption, 2) = BY) %then %do;

   %if (%qscan(&baselineoption, 1) = DATE) OR (%qscan(&baselineoption, 1) = TIME) %then %do;
      %put %str(RTE)RROR: &sysmacroname: If BASELINEOPTION is DATE or TIME then no by-variables may be specified.;
      %let g_abort=1;
   %end;
   %else %do;
      %if %eval(%index(&baselineoption, BY) + 3) > %length(&baselineoption) %then %do;
         %put %str(RTE)RROR: &sysmacroname: If BASELINEOPTION has %str(%")BY%str(%") in the parameter then by-variables must be specified.;
         %let g_abort=1;
      %end;
      %else
         %let l_byvar=%substr(&baselineoption,%eval(%index(&baselineoption, BY) + 3));
    %end;

 %end;
 %else %if %qscan(&baselineoption, 2) NE BY AND %qscan(&baselineoption, 2) NE %then %do;
    %put %str(RTE)RROR: &sysmacroname: BASELINEOPTION cannot be more than one word unless the second word is BY.;
    %let g_abort=1;
 %end;

 %let baselineoption=%qscan(&baselineoption, 1);

 %if ( &baselineoption ne DATE )  and ( &baselineoption ne RELDAY ) and ( &baselineoption ne TPT ) and      
     ( &baselineoption ne VISIT ) and ( &baselineoption ne TIME )   and ( &baselineoption ne VISITTPT ) %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The first word of BASELINEOPTION should be either DATE, RELDAY, VISIT, VISITTPT, TPT or TIME.;
    %let g_abort=1;
 %end;

 %if %qscan(&baselinetype, 2) = NOUNS %then %do;
   %let unschedule_flag = N;
   %let baselinetype=%qscan(&baselinetype, 1);
 %end;
 %else %if %qscan(&baselinetype, 2) NE %then %do;
    %put %str(RTE)RROR: &sysmacroname: Value of BASELINETYPE(=&baselinetype) is invalid. The second word should be NOUNS or missing.;
    %let g_abort=1;
 %end;

 %if ( &baselinetype ne FIRST  ) and ( &baselinetype ne LAST ) and 
     ( &baselinetype ne MEDIAN ) and ( &baselinetype ne MEAN ) %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The first word of BASELINETYPE should be either FIRST, LAST, MEDIAN, or MEAN..;
    %let g_abort=1;
 %end;

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;

 /*
 / Check for dependent parameter values.
 /----------------------------------------------------------------------------*/

 %if %qscan(&baselineoption, 1) eq VISITTPT %then
 %do;
    %let startatptn=%qscan(&startvisnum, 2);
    %let endatptn=%qscan(&endvisnum, 2);
    %let startvisnum=%qscan(&startvisnum, 1);
    %let endvisnum=%qscan(&endvisnum, 1);
 %end;
 
 %if %qscan(&baselineoption, 1) eq TPT %then
 %do;
    %let startatptn=%nrbquote(&startvisnum);
    %let endatptn=%nrbquote(&endvisnum);
 %end;

 %if ( &baselineoption eq RELDAY ) and ( &RELDAYS eq ) %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter RELDAYS is required when BASELINEOPTION is RELDAY.;
    %let g_abort=1;
 %end;

 %if ( ( &baselineoption eq VISIT ) or ( &baselineoption eq TPT ) ) and ( ( &STARTVISNUM eq ) or ( &ENDVISNUM eq ) ) %then    
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameters STARTVISNUM and ENDVISNUM are required when BASELINEOPTION is &BASELINEOPTION..;
    %let g_abort=1;
 %end;
 
 %if ( &baselineoption eq VISITTPT ) and ( ( &STARTATPTN eq ) or ( &ENDATPTN eq ) ) %then   
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameters STARTVISNUM(=&STARTVISNUM) and ENDVISNUM(=&ENDVISNUM) should contain two numbers when BASELINEOPTION is &BASELINEOPTION..;
    %let g_abort=1;
 %end;
 
 %if ( ( &baselineoption eq DATE ) or ( &baselineoption eq TIME ) ) and 
     ( &baselinetype eq LAST ) and ( &ENDVISNUM ne ) %then   
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter ENDVISNUM (=&ENDVISNUM) should be blank when BASELINEOPTION equals &BASELINEOPTION and BASELINETYPE equals &baselinetype;
    %let g_abort=1;
 %end;
 
 %if ( &baselineoption eq RELDAY ) and ( ( &STARTVISNUM ne ) or ( &ENDVISNUM ne ) ) %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameters STARTVISNUM (=&STARTVISNUM) and (ENDVISNUM=&ENDVISNUM) should be blank when BASELINEOPTION equals &BASELINEOPTION;
    %let g_abort=1;
 %end; 
 
 %if ( ( &baselineoption eq DATE ) or ( &baselineoption eq TIME ) ) and 
     ( &baselinetype ne LAST ) and ( &ENDVISNUM ne ) %then                       
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameters ENDVISNUM (=&ENDVISNUM) should be blank when BASELINEOPTION equals &BASELINEOPTION and BASELINETYPE equals &baselinetype;
    %let g_abort=1;
 %end; 

 %if ( &STARTVISNUM ne ) and ( &ENDVISNUM ne ) %then
 %do;
    %if %eval(&STARTVISNUM le &ENDVISNUM) ne 1 %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: The value of parameter STARTVISNUM (=&STARTVISNUM) must be less than or equal to the value of ENDVISNUM (=&ENDVISNUM).;
       %let g_abort=1;
    %end;
 %end; /* %if ( &STARTVISNUM ne ) and ( &ENDVISNUM ne ) */
 
 %if ( &STARTATPTN ne ) and ( &ENDATPTN ne ) %then
 %do;
    %if %eval(&STARTATPTN le &ENDATPTN) ne 1 %then
    %do;
       /*
       / The second values of the parameters STARTVISNUM and ENDVISNUM have already been assigned to the macro variables
       / STARTATPTN and ENDATPTN respectively, and STARTVISNUM and ENDVISNUM have already been re-assigned to store only
       / the first values specified by the user.
       /---------------------------------------------------------------------------------------------------------------*/
       %put %str(RTE)RROR: &sysmacroname: The second value of parameter STARTVISNUM (=&STARTATPTN) must be less than or equal to the second value of ENDVISNUM (=&ENDATPTN).;
       %let g_abort=1;
    %end;
 %end; /* %if ( &STARTATPTN ne ) and ( &ENDATPTN ne ) */

 %if ( &baselinetype eq MEDIAN ) or ( &baselinetype eq MEAN ) %then
 %do;

    %if ( &DERIVEDBASELINEROWINFO eq ) %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: The parameter DERIVEDBASELINEROWINFO is required when BASELINETYPE is &BASELINETYPE.;
       %let g_abort=1;
    %end;

    %if ( &DSETINADSL eq ) %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: The parameter DSETINADSL is required when BASELINETYPE is &BASELINETYPE.;
       %let g_abort=1;
    %end;

    %if ( &ADSLVARS eq ) %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: The parameter ADSLVARS is required when BASELINETYPE is &BASELINETYPE.;
       %let g_abort=1;
    %end;

    %if ( &ADGETTRTMERGEVARS eq ) %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: The parameter ADGETTRTMERGEVARS is required when BASELINETYPE is &BASELINETYPE.;
       %let g_abort=1;
    %end;

    %if ( &ADGETTRTVARS eq ) %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: The parameter ADGETTRTVARS is required when BASELINETYPE is &BASELINETYPE.;
       %let g_abort=1;
    %end;

 %end;

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;

 /*
 / Check for expected variables on DSETIN.
 /----------------------------------------------------------------------------*/

 %if &baselineoption eq TIME %then
 %do;
    %if %length(%tu_chkvarsexist(&dsetin, ADT ATM PARAMCD PARAM AVAL AVALC)) gt 0 %then
    %do;
       %put %str(RTE)RROR: &sysmacroname.: &dsetin dataset does not contain one of the following variables ADT ATM PARAMCD PARAM AVAL AVALC.;
       %let g_abort=1;
    %end;
 %end;
 %else
 %do;
    %if %length(%tu_chkvarsexist(&dsetin, ADT PARAMCD PARAM AVAL AVALC)) gt 0 %then
    %do;
       %put %str(RTE)RROR: &sysmacroname.: &dsetin dataset does not contain one of the following variables ADT PARAMCD PARAM AVAL AVALC.;
       %let g_abort=1;
    %end;
 %end;

 %if ( ( &baselineoption eq VISIT ) or ( &baselineoption eq VISITTPT ) ) or
     ( ( &baselinetype ne  LAST ) and ( &baselineoption eq RELDAY ) ) %then
 %do;
    %if %tu_chkvarsexist(&dsetin, VISITNUM) ne %then
    %do;    
       %put %str(RTE)RROR: &sysmacroname: VISITNUM does not exist in DSETIN(=&dsetin) when BASELINEOPTION is &BASELINEOPTION and BASELINETYPE is &BASELINETYPE;
       %let g_abort=1;
    %end;
 %end;
 
 %if ( ( &baselineoption eq TPT ) or ( &baselineoption eq VISITTPT ) ) %then 
 %do;
    %if %tu_chkvarsexist(&dsetin, ATPTN) ne %then
    %do;    
       %put %str(RTE)RROR: &sysmacroname: ATPTN does not exist in DSETIN(=&dsetin) when BASELINEOPTION is &BASELINEOPTION;
       %let g_abort=1;
    %end;    
 %end;

 %if &l_byvar NE %then %do;
    %if %tu_chkvarsexist(&dsetin, &l_byvar) NE %then %do;    
       %put %str(RTE)RROR: &sysmacroname: One of the by-variables in BASELINEOPTION(=&baselineoption BY &l_byvar) does not exist in DSETIN(=&dsetin).;
       %let g_abort=1;
     %end;
 %end;

 %if &rederivebaselineyn eq N %then
 %do;
    %if %tu_chkvarsexist(&dsetin, &domaincode.BLFL) ne %then
    %do;    
       %put %str(RTE)RROR: &sysmacroname: Variable &domaincode.BLFL does not exist in DSETIN(=&dsetin) when REDERIVEBASELINEYN is N.;
       %let g_abort=1;
    %end;    
 %end;

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;

 /*
 / If the input dataset name is the same as the output dataset name,
 / write a note to the log.
 /----------------------------------------------------------------------------*/
 
 %if %qscan(&dsetin, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
 %do;
    %put %str(RTN)OTE: &sysmacroname: The input dataset name DSETIN(=&dsetin) is the same as the output dataset name DSETOUT(=&dsetout).;
 %end;

 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/

 %let domaincode=%unquote(&domaincode);

 %if %tu_chkvarsexist(&dsetin, PARCAT1, Y) ne %then
    %let l_parcat1=PARCAT1;

 %if %tu_chkvarsexist(&dsetin, ANRIND, Y) ne %then
    %let l_anrind=ANRIND;

 /* AJC002: Set up additional by variables for PARAMLBL and qualifier variables */
 %if %tu_chkvarsexist(&dsetin, PARAMLBL, Y) ne %then
    %let l_paramlbl=PARAMLBL;

 %let l_qualifiers=&domaincode.TESTCD &domaincode.POS &domaincode.SPEC &domaincode.METHOD &domaincode.LOC;
 %let l_qualifiers=%tu_chkvarsexist(&dsetin, &l_qualifiers, Y);

 %if &rederivebaselineyn = N %then
    %put %str(RTN)OTE: &sysmacroname: Determining baseline values using SDTM baseline flag.;
 %else
 %do;
    %put %str(RTN)OTE: &sysmacroname: Determining baseline values using BASELINEOPTION(=&baselineoption) and BASELINETYPE(=&baselinetype)..;
    %if &unschedule_flag = Y %then
       %put %str(RTN)OTE: &sysmacroname: Unscheduled observations may be included in the calculation of baseline.;
    %else %if &unschedule_flag = N %then
       %put %str(RTN)OTE: &sysmacroname: Unscheduled observations will not be included in the calculation of baseline.;
 %end;

 /*
 / When REDERIVEBASELINEYN is N
 /----------------------------------------------------------------------------*/

 %if &rederivebaselineyn = N %then
 %do;

    /*
    / Identify baseline using SDTM baseline flag (&domaincode.BLFL='Y')
    /-------------------------------------------------------------------------*/

    proc sort data=&dsetin out=&prefix._dsetinsort;
       by studyid usubjid &l_parcat1 PARAMCD PARAM &l_paramlbl &l_qualifiers ADT 
          %if %length(%tu_chkvarsexist(&dsetin, ATM)) eq 0 %then ATM;;
    run;

    data 
       &prefix._xlab
       &prefix._base (keep   = studyid usubjid PARAMCD PARAM &l_paramlbl &l_qualifiers &l_parcat1 &l_byvar AVAL AVALC &l_anrind
                      rename = (AVAL = BASE AVALC = BASEC %if &l_anrind ne %then ANRIND = BNRIND; ))
       ;
       set &prefix._dsetinsort;
       by studyid usubjid &l_parcat1 PARAMCD PARAM &l_paramlbl &l_qualifiers ADT
          %if %length(%tu_chkvarsexist(&dsetin, ATM)) eq 0 %then ATM;;

       length A2IND $20;

       /*
       / Define a flag to track when the baseline is found within each
       / parameter. Records prior to baseline are set to pre-therapy.
       /----------------------------------------------------------------------*/

       retain blfl_found;

       if first.param then blfl_found='N';
       
       if blfl_found='N' then do;
          A2INDCD = 'P';
          A2IND = 'Pre-therapy';
       end;
       
       if &domaincode.blfl='Y' then do;
          output &prefix._base;
          A2INDCD = 'R';
          A2IND = 'Baseline';
          ABLFL='Y';
          blfl_found='Y';
       end;
       
       output &prefix._xlab;
       drop blfl_found;

    run;

    proc sort data=&prefix._base out=&prefix._base;
       by studyid usubjid &l_parcat1 PARAMCD PARAM &l_paramlbl &l_qualifiers;
    run;

    data &prefix._base_duprecs;
       set &prefix._base;
       by studyid usubjid &l_parcat1 PARAMCD PARAM &l_paramlbl &l_qualifiers;
       if not (first.PARAM and last.PARAM);
    run;

    %if %tu_nobs(&prefix._base_duprecs) gt 0 %then
       %put %str(RTW)ARNING: &sysmacroname: DSETIN(=&dsetin) contains duplicate baseline observations when REDERIVEBASELINEYN is &rederivebaselineyn..;

    data &prefix._final;
       merge &prefix._base &prefix._xlab (in=a);
       by studyid usubjid &l_parcat1 PARAMCD PARAM &l_paramlbl &l_qualifiers;
       if a;
    run;

 %end;  /* end-if on &rederivebaselineyn eq N */
 
 /*
 / When REDERIVEBASELINEYN is Y and BASELINEOPTION is DATE, TIME or RELDAY
 /----------------------------------------------------------------------------*/

 %else %if ( &baselineoption eq DATE ) or ( &baselineoption eq RELDAY ) or ( &baselineoption eq TIME ) %then
 %do;

    %if %tu_chkvarsexist(&dsetin, TRTSDT) ne %then
    %do;

       data &prefix._final;
            set &dsetin;
            length A2IND $20 BASEC $200;

            A2INDCD = 'P';
            A2IND = 'Pre-therapy';
            BASE = .;
            BASEC = ' ';
            ABLFL=' ';
            %if &l_anrind ne %then BNRIND = ' ';;

       run;

       %put %str(RTW)ARNING: &sysmacroname: Treatment start date variable TRTSDT does not exist in DSETIN(=&dsetin).;
       %put %str(RTW)ARNING: &sysmacroname: All records marked as Pre-therapy.;

    %end; /* treatment start date variable does not exist */

    %else
    %do;
          
      %let l_calcbaselineflag=1;
      %if &baselineoption eq TIME %then
      %do;
          %if %tu_chkvarsexist(&dsetin, TRTSTM) ne %then
          %do;
             %put %str(RTW)ARNING: &sysmacroname: BASELINEOPTION equals TIME, but TRTSTM does not exist in DSETIN(=&DSETIN).;
             %put %str(RTW)ARNING: &sysmacroname: Set BASELINEOPTION to DATE;
             %let BASELINEOPTION=DATE;
          %end;                    
      %end;

       /*
       / Determine baseline records and records prior to baseline.
       /-------------------------------------------------------------------*/

       data &prefix._pre &prefix._postdose;

            set &dsetin;

            %if ( &baselineoption eq DATE ) or ( &baselineoption eq RELDAY ) %then
            %do;
               if ( TRTSDT eq . ) or (ADT le TRTSDT)
               then output &prefix._pre;
               else output &prefix._postdose;
            %end;

            %if &baselineoption eq TIME %then
            %do;
               if ( TRTSTM eq . ) or ( ATM eq . ) or ( ADT ne TRTSDT ) then
               do;
                  if ( TRTSDT eq . ) or ( ADT lt TRTSDT )
                  then output &prefix._pre;
                  else output &prefix._postdose;
               end;

               else do;
                  /* Calculate on time (adt = exstdt)  */
                  if ( ATM le TRTSTM )
                  then output &prefix._pre;
                  else output &prefix._postdose;
               end;
            %end; /* %if &baselineoption eq TIME */
       run;        

       /*
       / Flag all records prior to start of medication as 'P' and
       / categorise into records for consideration for baseline.
       /-------------------------------------------------------------------*/
          
       data &prefix._predose &prefix._baseline;
            set &prefix._pre;
            length A2IND $20;

            A2INDCD = 'P';
            A2IND = 'Pre-therapy';
               
            %if &baselineoption eq DATE or &baselineoption eq TIME %then
            %do;
               %if &startvisnum ne %then
               %do;
                  if visitnum lt &startvisnum then output &prefix._predose;
                  else               
               %end;              
               if missing(AVAL) then output &prefix._predose;
             %if &unschedule_flag = N %then %do;
               else if visitnum ne floor(visitnum) then output &prefix._predose;
              %end;
               else output &prefix._baseline;
            %end;

            %else %if &baselineoption eq RELDAY %then
            %do;
               if ( TRTSDT ne . ) and (ADT ge (TRTSDT - abs(&reldays))) then 
               do;
                  if missing(AVAL) then output &prefix._predose;
                %if &unschedule_flag = N %then %do;
                  else if visitnum ne floor(visitnum) then output &prefix._predose;
                 %end;
                  else output &prefix._baseline;
               end;
               else output &prefix._predose;
            %end;

       run;
                   
       proc sort data=&prefix._baseline out=&prefix._baseline_sort;
            by studyid usubjid &l_parcat1 PARAMCD PARAM &l_paramlbl &l_qualifiers ADT
               %if &baselineoption eq TIME %then ATM;
               visitnum ;
       run;
         
    %end;  /* end-if on treatment start date variable does exist */

 %end;  /* end-if on &baselineoption eq DATE or &baselineoption eq RELDAY or &baselineoption eq TIME */
 
 /*
 / When REDERIVEBASELINEYN is Y and BASELINEOPTION is VISIT, TPT or VISITTPT
 /----------------------------------------------------------------------------*/

 %else %do;
   
    /*
    / Split data into three groups: known pre-dose, possible baseline (mix
    / of pre-dose and baseline) and known post-dose.
    /----------------------------------------------------------------------*/

    %let l_calcbaselineflag=1;
    
    data &prefix._pre1 &prefix._baseline &prefix._postdose;
         set &dsetin;         
         %if &baselineoption eq VISIT %then
         %do;
            if visitnum lt &startvisnum then output &prefix._pre1;
            else if visitnum gt &endvisnum then output &prefix._postdose;
          %if &unschedule_flag = N %then %do;
            else if visitnum ne floor(visitnum) then output &prefix._postdose;
           %end;
            else output &prefix._baseline;
         %end;
         %if &baselineoption eq VISITTPT %then
         %do;
            if visitnum lt &startvisnum then output &prefix._pre1;
            else if visitnum gt &endvisnum then output &prefix._postdose;
            else do;
               if atptn lt &startatptn then output &prefix._pre1;
               else if atptn gt &endatptn then output &prefix._postdose;            
             %if &unschedule_flag = N %then %do;
               else if atptn NE floor(atptn) then output &prefix._postdose;
              %end;
               else output &prefix._baseline;
            end;
         %end;
         %if &baselineoption eq TPT %then
         %do;
            if atptn lt &startatptn then output &prefix._pre1;
            else if atptn gt &endatptn then output &prefix._postdose;
          %if &unschedule_flag = N %then %do;
            else if atptn NE floor(atptn) then output &prefix._postdose;
           %end;
            else output &prefix._baseline;
         %end;         
    run;

    /*
    / Flag all pre-therapy records as 'P'.
    / categorise into records for consideration for baseline.
    /-------------------------------------------------------------------*/

    data &prefix._pre2 &prefix._baseline;
         set &prefix._baseline;     
         length A2IND $20;

         A2INDCD = 'P';
         A2IND = 'Pre-therapy';

       %if &unschedule_flag = Y %then %do;
         if not missing(AVAL) then output &prefix._baseline;
        %end;
       %else %do;
         if not missing(AVAL) and visitnum = floor(visitnum) then output &prefix._baseline;
        %end;
         else output &prefix._pre2;
    run;
    
    data &prefix._predose;
         length A2IND $20;
         set &prefix._pre1 &prefix._pre2;
         A2INDCD  = 'P';
         A2IND = 'Pre-therapy';         
    run;
   
    /*
    / For the mix of pre-dose and baseline, determine which is which.
    / If the time variable exists, then include time in the sort, so
    / that the dataset will be correctly sorted for obtaining the FIRST or
    / LAST observation when there are multiple observations within the 
    / baseline VISIT/TPT.
    /----------------------------------------------------------------------*/

    proc sort data=&prefix._baseline out=&prefix._baseline_sort;
         by studyid usubjid &l_byvar &l_parcat1 PARAMCD PARAM &l_paramlbl &l_qualifiers ADT 
         %if %length(%tu_chkvarsexist(&prefix._baseline, ATM)) eq 0 %then ATM; 
         %if ( &baselineoption eq VISIT ) or ( &baselineoption eq VISITTPT ) %then visitnum; 
         %if ( &baselineoption eq TPT )   or ( &baselineoption eq VISITTPT ) %then atptn;
         ;
    run;
   
 %end;  /* end-if on &baselineoption eq VISIT or &baselineoption eq TPT or &baselineoption eq VISITTPT */
 
 /* Split baseline records and calculate baseline value */
            
 %if &l_calcbaselineflag eq 1 %then
 %do;
    
    /*
    / Output baseline values to a separate dataset.
    / Flag baseline records on the lab dataset as 'R'.
    /----------------------------------------------------------------------*/
   
    %if ( &baselinetype eq FIRST ) or ( &baselinetype eq LAST ) %then
    %do;       
       data &prefix._baseline_final
            &prefix._base (keep   = studyid usubjid &l_parcat1 PARAMCD PARAM  &l_paramlbl &l_qualifiers 
                                    &l_byvar AVAL AVALC &l_anrind
                           rename = (AVAL = BASE AVALC = BASEC  %if &l_anrind ne %then ANRIND = BNRIND;) ) ;
            set &prefix._baseline_sort;
            by studyid usubjid &l_byvar &l_parcat1 PARAMCD PARAM &l_paramlbl &l_qualifiers;
       
          %if &unschedule_flag = Y %then %do;
            if &baselinetype..PARAM then do;
           %end;
          %else %do;
            if &baselinetype..PARAM and visitnum = floor(visitnum) then do;
           %end;
               output &prefix._base;
               A2INDCD  = 'R';
               A2IND = 'Baseline';
               ABLFL='Y';
            end;
       
            output &prefix._baseline_final;
       run;
    %end;
    %else %do;
       proc summary data=&prefix._baseline_sort missing nway;
           by studyid usubjid &l_byvar &l_parcat1 PARAMCD PARAM &l_paramlbl &l_qualifiers;
           var AVAL;
           output out=&prefix._base(keep=studyid usubjid &l_parcat1 PARAMCD PARAM  &l_paramlbl &l_qualifiers 
                                         &l_byvar BASE)
                  &baselinetype=BASE;
       run;
       
       data &prefix._baseline_final;
           set &prefix._baseline_sort;
           A2INDCD  = 'R';
           A2IND = 'Baseline';
       run;

       /*
       / When baseline value is mean/median, derive BASEC and BNRIND.
       / AJC003: Set BASEC to missing to be consistent with the domain
       / macros. This is carried through to AVALC when creating new rows
       / containing the derived baseline.
       /-------------------------------------------------------------------*/

       data &prefix._base;
          set &prefix._base;
          length basec $200;
          *basec=strip(put(base, best.));
          basec=' ';
       run;

       %if &l_anrind ne %then
       %do;

          data &prefix._baseline_nr (keep=studyid usubjid &l_parcat1 PARAMCD PARAM  &l_paramlbl &l_qualifiers
                                          &l_byvar ANRLO ANRHI);
             set &prefix._baseline_sort;
             by studyid usubjid &l_byvar &l_parcat1 PARAMCD PARAM &l_paramlbl &l_qualifiers ADT 
                %if %length(%tu_chkvarsexist(&prefix._baseline_sort, ATM)) eq 0 %then ATM;;
             if last.PARAM;
          run;

          data &prefix._base;
             merge &prefix._base (in=a) &prefix._baseline_nr (in=b);
             by studyid usubjid &l_byvar &l_parcat1 PARAMCD PARAM &l_paramlbl &l_qualifiers;
             if a;
             length bnrind $6;
             if anrlo eq . and anrhi eq . then;
             else if base eq . then;
             else if base lt anrlo and anrlo ne . then bnrind='LOW';
             else if base gt anrhi and anrhi ne . then bnrind='HIGH';
             else bnrind='NORMAL';
          run;
          
       %end;

       /*
       / Create new rows to add to the dataset containing derived baseline.
       /-------------------------------------------------------------------*/

       data &prefix._baseline_derived;
          set &prefix._base (in=b rename=(base=aval basec=avalc
             %if &l_anrind ne %then BNRIND = ANRIND;  ));
          length DTYPE $20;
          retain DTYPE
            %if &baselinetype eq MEAN %then 'AVERAGE';
            %else "&baselinetype";
            ;
          A2INDCD  = 'R';
          A2IND = 'Baseline';
          ABLFL='Y';
          %unquote(&derivedbaselinerowinfo);
       run;

       %tu_adgetadslvars(dsetin=&prefix._baseline_derived,
                         dsetout=&prefix._baseline_derived_adsl,
                         adsldset=&dsetinadsl,
                         adslvars=&adslvars
                         );

       /*
       / AJC001: If any ADGETTRTMERGEVARS do not exist on the derived
       / baseline row dataset, attempt to populate the variables from the
       / dataset which went into PROC SUMMARY, before calling tu_adgettrt.
       /-------------------------------------------------------------------*/

       %let l_trtmergevarsnotexist=%tu_chkvarsexist(&prefix._baseline_derived_adsl, &adgettrtmergevars);

       %if &l_trtmergevarsnotexist ne %then
       %do;

          %put %str(RTN)OTE: &sysmacroname: Variable(s) %upcase(&l_trtmergevarsnotexist) specified in ADGETTRTMERGEVARS do not exist in the derived baseline row dataset.;
          %put %str(RTN)OTE: &sysmacroname: Attempting to populate %upcase(&l_trtmergevarsnotexist) from the observations which contributed to the baseline derivation.;

          proc sort data=&prefix._baseline_sort 
             out=&prefix._trtmergevars (keep=studyid usubjid &l_byvar &l_parcat1 PARAMCD PARAM  &l_paramlbl &l_qualifiers &l_trtmergevarsnotexist) nodupkey;
             by studyid usubjid &l_byvar &l_parcat1 PARAMCD PARAM &l_paramlbl &l_qualifiers &l_trtmergevarsnotexist;
          run;

          data &prefix._trtmergevars_duprecs;
             set &prefix._trtmergevars;
             by studyid usubjid &l_byvar &l_parcat1 PARAMCD PARAM &l_paramlbl &l_qualifiers &l_trtmergevarsnotexist;
             if not(first.PARAM and last.PARAM);
          run;

          %if %tu_nobs(&prefix._trtmergevars_duprecs) gt 0 %then
          %do;
             %put %str(RTW)ARNING: &sysmacroname: Cannot populate variable(s) %upcase(&l_trtmergevarsnotexist) on the derived baseline row dataset;
             %put %str(RTW)ARNING: &sysmacroname: owing to multiple values in the observations which contributed to the baseline derivation.;
             %put %str(RTW)ARNING: &sysmacroname: Macro tu_adgettrt will not be called for the derived baseline rows.;
             %let l_calladgettrtflag=0;
          %end;
          %else
          %do;
             data &prefix._baseline_derived_adsl;
                merge &prefix._baseline_derived_adsl &prefix._trtmergevars;
                by studyid usubjid &l_byvar &l_parcat1 PARAMCD PARAM &l_paramlbl &l_qualifiers;
             run;
          %end;

       %end;

       %if &l_calladgettrtflag eq 1 %then
       %do;
          %tu_adgettrt(dsetin=&prefix._baseline_derived_adsl,
                       dsetout=&prefix._baseline_derived_trt,
                       dsetinadsl=&dsetinadsl,
                       mergevars=&adgettrtmergevars,
                       trtvars=&adgettrtvars
                       );
       %end;
       %else
       %do;
          data &prefix._baseline_derived_trt;
             set &prefix._baseline_derived_adsl;
          run;
       %end;

       data &prefix._baseline_final;
          set &prefix._baseline_final &prefix._baseline_derived_trt;
       run;

       %if &l_anrind ne %then
       %do;

          data &prefix._base;
             set &prefix._base;
             drop anrlo anrhi;
          run;

       %end;

    %end;
 
    /*
    / Combine pre-baseline, baseline and post-baseline data together.
    /----------------------------------------------------------------------*/

    data &prefix._xlab;
       set &prefix._predose &prefix._baseline_final &prefix._postdose;
    run;
   
    /* 
    / Merge baseline values to input dataset.
    /----------------------------------------------------------------------*/
    proc sort data=&prefix._xlab out=&prefix._xlab;
      by studyid usubjid &l_byvar &l_parcat1 PARAMCD PARAM &l_paramlbl &l_qualifiers;
    run;

    proc sort data=&prefix._base out=&prefix._base;
      by studyid usubjid &l_byvar &l_parcat1 PARAMCD PARAM &l_paramlbl &l_qualifiers;
    run;

    %local l_i l_numbyvar;

    %let l_numbyvar=%tu_words(&l_byvar);

    %do l_i=1 %to &l_numbyvar;
       %local l_byvartype&l_i;
       %let l_byvartype&l_i=%tu_chkvartype(&dsetin, %scan(&l_byvar, &l_i));
    %end;

    data &prefix._final;
      merge &prefix._base &prefix._xlab (in=a);
      by studyid usubjid &l_byvar &l_parcat1 PARAMCD PARAM &l_paramlbl &l_qualifiers;
      if a;

      /*
      / Create BASETYPE variable when there are by groups on BASELINEOPTION.
      /-------------------------------------------------------------------*/

      %if &l_byvar ne %then
      %do;
         length basetype $200;
         basetype='';
         %do l_i=1 %to &l_numbyvar;
            if not missing(%scan(&l_byvar,&l_i)) then do;
               %if &l_i gt 1 %then %do;
                  if ^missing(basetype) then
                     basetype=trim(basetype)||',';
               %end;
               %if &&l_byvartype&l_i eq C %then %do;
                  if missing(basetype) then
                     basetype="%scan(&l_byvar,&l_i)="||strip(%scan(&l_byvar,&l_i));
                  else 
                     basetype=trim(basetype)||' '||"%scan(&l_byvar,&l_i)="||strip(%scan(&l_byvar,&l_i));
               %end;
               %else %do;
                  if missing(basetype) then
                     basetype="%scan(&l_byvar,&l_i)="||strip(put(%scan(&l_byvar,&l_i),best.));
                  else 
                     basetype=trim(basetype)||' '||"%scan(&l_byvar,&l_i)="||strip(put(%scan(&l_byvar,&l_i),best.));
               %end;
            end;
         %end;
      %end;
    run;

 %end; /* %if &l_calcbaselineflag eq 1 */
  
 /*
 / Derive change from baseline value.
 /----------------------------------------------------------------------*/

 data &dsetout;
    set &prefix._final;    
    if AVAL ne . and BASE ne . and A2INDCD not in ('P','R') then
       CHG = AVAL - BASE;
 run;

 /*
 / Delete temporary datasets used in this macro.
 /----------------------------------------------------------------------------*/

 %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tu_adbaseln;
