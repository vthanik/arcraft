/*******************************************************************************
|
| Macro Name:      tu_baseln_sdtmconv
|
| Macro Version:   2 build 1
|
| SAS Version:     9.1
|
| Created By:      Shan Lee
|
| Date:            25-Jan-2010
|
| Macro Purpose:   Calculation of change from baseline
|
|                  This macro is a modification of version 3, build 3, of the
|                  standard HARP Reporting Tool TU_BASELN.
|
|                  The original TU_BASELN macro has been modified to work with
|                  the SDTM Conversion Macros, and it now includes additional 
|                  functionality requested by users of the conversion macros.
|                  In particular, the algorithm for baseline flagging has been
|                  extended to meet the requirements of the Respiratory MDC, which
|                  will be the first group to use the SDTM Conversion Macros.
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
|
| BASELINETYPE    Calculation of baseline option       REQ      (Blank)
|                 when there are multiple records
|                 following into baseline range.
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
| BASELINEOPTION  Calculation of baseline option.      REQ      (Blank)
|                 When equals PTM or VISITPTM, baseline
|                 is derived for each period if PERNUM 
|                 exists in &DSETIN                 
|                   
|                 Valid values:
|
|                 DATE   - Select baseline records based on collection
|                          date (e.g. date component of LBDTC) and visit
|                          number (VISITNUM) compared to study medication start
|                          date (from EXSTDTC) and visit number (VISITNUM).
|                          Note that when start date and visit of medication is
|                          the same as Findings date and visit, it is regarded
|                          as post-baseline.
|
|                 RELDAY - Select baseline records by number of relative days 
|                          specified in RELDAYS parameter. 
|
|                 PTM    - Select baseline records specified by TPTNUM values
|                          passed in by the parameters STARTVISNUM and
|                          ENDVISNUM. 
|
|                 VISIT  - Select baseline records specified by VISITNUM values
|                          passed in by the parameters STARTVISNUM and
|                          ENDVISNUM.
|
|                 VISITPTM-Select baseline records specified by VISITNUM and TPTNUM
|                          values passed in by the parameters STARTVISNUM and
|                          ENDVISNUM. The first number in STARTVISNUM/ENDVISITNUM 
|                          will be for start/end VISITNUM and the second for 
|                          start/end TPTNUM
|
|                 TIME   - Select baseline records based on collection
|                          date and time (e.g. derived from LBDTC) compared to study
|                          medication start date and time (derived from EXSTDTC).
|
|                 If By-variables are needed, then after BASELINEOPTION parameter
|                 add the word 'by' and follow that with by-variables that are
|                 desired for the study.
|                 (i.e. BASELINEOPTION=VISITPTM by visitnum visit,)
|                 This option is not valid if BASELINEOPTION is DATE or TIME
|                 If a By-variable is specified, then PERNUM is no longer 
|                 an automatic by-variable and must be specified if desired
|
| STMEDDSET       Name of dataset containing study     OPT      (Blank)
|                 medication data - must be in the 
|                 EX SDTM dataset structure.
|                 Usually, mid_sdtm.ex_exposure
|
| STMEDDSETSUBSET Where clause to be applied to the    OPT      (Blank)
|                 &STMEDDSET specified dataset.
|                 Example: 
|                  stmeddsetdubset=exinvpcd eq 4
|
| RELDAYS         Number of days prior to start of     OPT      (Blank)
|                 study medication, used to identify
|                 records to be considered as
|                 baseline. Required if
|                 BASELINEOPTION is RELDAY.
|                 Valid values: a positive number 
|
| STARTVISNUM     VISITNUM and/or TPTNUM value for     OPT      (Blank)
|                 start of range to identify records 
|                 to be considered as baseline. 
|                 Required if BASELINEOPTION is
|                 VISIT/PTM/VISITPTM. If  
|                 BASELINEOPTION is VISITPTM, it should 
|                 include two words: first is for 
|                 VISITNUM and second for TPTNUM.
|
| ENDVISNUM       VISITNUM and/or TPTNUM value for end OPT      (Blank)
|                 of range to identify records to be 
|                 considered as baseline. Required if
|                 BASELINEOPTION is VISIT/PTM/VISITPTM.
|                 If BASELINEOPTION is VISITPTM, it 
|                 should include two words: first is
|                 for VISITNUM and second for TPTNUM
|
| DOMAINCODE      Specifies which test flagging should REQ       (Blank) 
|                 be derived: Lab (LB), ECG (EG) or 
|                 Vital Signs (VS) are most common although
|                 any 2 or more char values will work
| --------------  -----------------------------------  -------  ---------------
|
| The macro references the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETIN            Req      Parameter specified dataset
| &STMEDDSET         Opt      Parameter specified dataset
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
|(@) tu_chkvarsexist
|(@) tu_putglobals
|(@) tu_tidyup
|(@) tu_abort
|
| Example:
|    %tu_baseln_sdtmconv(
|         dsetin          = pre_sdtm.vs_vitals,
|         dsetout         = pre_sdtm.vs_vitals,
|         baselineoption  = TIME,
|         baselinetype    = LAST,
|         stmeddset       = mid_sdtm.ex_exposure,
|         startvisnum     = ,
|         endvisnum       = ,
|         domaincode      = VS
|         );
|
|******************************************************************************
| Change Log
|
| Modified By:              Shan Lee 
| Date of Modification:     25-Jan-2010
| New version/draft number: Version 1, build 1
| Modification ID:          SL002
| Reason For Modification:  If BASELINEOPTION equals DATE or TIME, then allow an
|                           optional keyword PRE to be appended to the end of 
|                           the BASELINETYPE parameter. 
|                           If PRE is specified, then any assessment taken on 
|                           the date of first dose of study medication will be
|                           considered to be pre-treatment, regardless of the 
|                           value of VISITNUM.
|                           An optional condition may also be specified after 
|                           the keyword PRE, to subset the observations that are
|                           considered pre-treatment - observations that do not
|                           meet this condition are considered on-treatment,
|                           regardless of the value of VISITNUM, if they fall
|                           on the study medication start date.
|
| Modified By:              Bruce Chambers 
| Date of Modification:     09Feb2011
| New version/draft number: Version 2, build 1
| Modification ID:          BJC001
| Reason For Modification:  Replace all SUBJIDs with USUBJIDs
|
*******************************************************************************/

%macro tu_baseln_sdtmconv (
     dsetin          = ,   /* Input dataset name */
     dsetout         = ,   /* Output dataset name */
     baselineoption  = ,   /* Calculation of baseline option */
     stmeddset       = ,   /* Study medication dataset name, usually mid_sdtm.ex_exposure */
     stmeddsetsubset = ,   /* WHERE clause applied to study medication dataset */
     reldays         = ,   /* Number of days prior to start of study medication */
     startvisnum     = ,   /* VISITNUM and/or TPTNUM value for start of baseline range */
     endvisnum       = ,   /* VISITNUM and/or TPTNUM value for end of baseline range */
     domaincode      = ,   /* Can be any non-missing value used to access required variables from the input dataset */
     baselinetype    =     /* How to calculate baseline for multiple baseline records: first, last, mean or median */
     );

 /*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion;
 %let MacroVersion = 1 build 1;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals()

 /*
 / Define local variables
 / SL002: added local macro variables L_PRE and L_CONDITION.
 /----------------------------------------------------------------------------*/
 
 %local prefix stnumvar stnumstat chgorcc l_calcbaselineflag startptmnum endptmnum pernum byvar unschedule_flag l_pre l_condition; /* YW001: added stnumvar and stnumstat */
                                                                                                                 /* BA002: added byvar and unschedule_flag */
 %let prefix = _baseln;   /* Root name for temporary work datasets */ 
 %let l_calcbaselineflag=0;
 %let pernum=;
 %let byvar=;
 %let unschedule_flag = Y;
 
 /*
 / PARAMETER VALIDATION
 /----------------------------------------------------------------------------*/

 %let dsetin          = %nrbquote(&dsetin);
 %let dsetout         = %nrbquote(&dsetout);
 %let baselineoption  = %nrbquote(%upcase(&baselineoption));
 %let reldays         = %nrbquote(&reldays);
 %let startvisnum     = %nrbquote(&startvisnum);
 %let endvisnum       = %nrbquote(&endvisnum);
 %let stmeddset       = %nrbquote(&stmeddset);
 %let stmeddsetsubset = %nrbquote(&stmeddsetsubset);
 %let domaincode      = %qupcase(&domaincode);
 %let baselinetype    = %qupcase(&baselinetype);  

 /* BA002
 / Establish BY variable list OR set g_abort for an invalid "BY" list
 / 
 / SL002: for the SDTM conversion, BY variables may be specified for any of the
 / baseline options, including DATE and TIME.
 /----------------------------------------------------------------------------------*/
 %if (%qscan(&baselineoption, 2) = BY) %then
 %do;
   %if %eval(%index(&baselineoption, BY) + 3) > %length(&baselineoption) %then %do;
     %put %str(RTE)RROR: TU_BASELN_SDTMCONV: If BASELINEOPTION has %str(%")BY%str(%") in the parameter then by-variables must be specified.;
     %let g_abort=1;
   %end;
   %else %let byvar=%substr(&baselineoption,%eval(%index(&baselineoption, BY) + 3));
 %end;

 %if %qscan(&baselinetype, 2) = NOUNS %then %do;
   %let unschedule_flag = N;
 %end;

 %if &unschedule_flag = Y %then
    %put %str(RTN)OTE: TU_BASELN_SDTMCONV: Unscheduled observations may be included in the calculation of baseline.;
 %else %if &unschedule_flag = N %then
    %put %str(RTN)OTE: TU_BASELN_SDTMCONV: Unscheduled observations will not be included in the calculation of baseline.;

 /* End BA002 */

 /*
 / SL002
 / 
 / If, and only if, BASELINEOPTION is DATE or TIME, then BASELINETYPE may include
 / the keyword PRE.
 / If the keyword PRE is specified in BASELINETYPE, then a condition may optionally
 / be specified after this keyword. Only observations meeting this condition will be
 / considered pre-treatment, and observations that do not meet this condition will
 / be considered on-treatment, regardless of the value of VISITNUM.
 /----------------------------------------------------------------------------------*/

 %local rx l_pre l_condition;

 %let rx = %sysfunc(prxparse(/^(FIRST|LAST|MEDIAN|MEAN)(\s+NOUNS)?\s+PRE(\s+.*)?$/i));
 %let l_condition = ;

 %if %sysfunc(prxmatch(&rx, &baselinetype)) %then
 %do;
   %let l_pre = 1; 
   %if %qscan(&baselineoption, 1) ne DATE and %qscan(&baselineoption, 1) ne TIME %then
   %do;
     %put %str(RTE)RROR: &sysmacroname: BASELINETYPE=&baselinetype, but keyword PRE;
     %put %str(         )should only be specified when BASELINEOPTION is DATE or TIME.;
     %let g_abort = 1;
   %end;
   %else %if %sysfunc(prxparen(&rx)) eq 3 %then
   %do;
     %let l_condition = %sysfunc(prxposn(&rx, 3, &baselinetype));
   %end;
 %end;
 %else
 %do;
   %let l_pre = 0;
 %end;

 %syscall prxfree(rx);

 %let baselinetype=%qscan(&baselinetype, 1);

 /* End SL002 */

 %if %qscan(&baselineoption, 1) eq VISITPTM %then  /* BA002 added qscan to handle extra keyword in parameter */
 %do;
    %let startptmnum=%qscan(&startvisnum, 2);
    %let endptmnum=%qscan(&endvisnum, 2);
    %let startvisnum=%qscan(&startvisnum, 1);
    %let endvisnum=%qscan(&endvisnum, 1);
 %end;
 
 %if %qscan(&baselineoption, 1) eq PTM %then       /* BA002 added qscan to handle extra keyword in parameter */
 %do;
    %let startptmnum=%nrbquote(&startvisnum);
    %let endptmnum=%nrbquote(&endvisnum);
 %end;

 /*
 / Check for required parameters.
 /----------------------------------------------------------------------------*/

 %if &dsetin eq %then
 %do;
    %put %str(RTE)RROR: TU_BASELN_SDTMCONV: The parameter DSETIN is required.;
    %let g_abort=1;
 %end;

 %if &dsetout eq %then
 %do;
    %put %str(RTE)RROR: TU_BASELN_SDTMCONV: The parameter DSETOUT is required.;
    %let g_abort=1;
 %end;


 /* BA002
 / Check if dsetin contains date or actual time or SI numeric result variable
 /
 / SL001
 / Include %DO... %END around the calls to %tu_chkvarsexist, to correct the logic so
 / that the check will execute when &baselineoption is not equal to TIME. 
 / When &baselineoption is not equal to TIME, the (RTE)RROR message should not imply
 / that &domaincode.ACTTM is a required variable.
 /
 / SL002
 / In the SDTM findings domains, dates and times are stored in ISO 8601 format within
 / 'DTC' variables in SDTM.
 /----------------------------------------------------------------------------------*/

 %if %length(%tu_chkvarsexist(&dsetin, &domaincode.DTC &domaincode.TESTCD &domaincode.STRESN )) gt 0 %then
 %do;
    %put %str(RTE)RROR: &sysmacroname.: &dsetin dataset does not contain one of the following variables &domaincode.DTC &domaincode.TESTCD &domaincode.STRESN.;
    %let g_abort=1;
 %end;

 /* SL002 - baselineoption can include an additional keyword if TIME is specified,
 /  so we need to examine just the first word in BASELINEOPTION.
 /---------------------------------------------------------------------------------*/

 %if %qscan(&baselineoption, 1) eq TIME %then
 %do;

   data _null_;
     set &dsetin end = eof;
     retain is_time 0;
     if index(%unquote(&domaincode)dtc, 'T') then is_time = 1;
     if eof and not is_time then
     do;
       put 'RTE' "RROR: &sysmacroname: BASELINEOPTION = TIME, but"
           / "&domaincode.DTC does not contain any time values.";
       call symput('g_abort', '1'); 
     end;
   run;

 %end;

 /* BA002
 / Check if dsetin contains by-variables from BASELINEOPTION parameter value
 /----------------------------------------------------------------------------------*/
 %if &byvar NE %then %do;
    %if %tu_chkvarsexist(&dsetin, &byvar) NE %then %do;    
       %put %str(RTE)RROR: TU_BASELN_SDTMCONV: One of the By-variables in BASELINEOPTION does not exist in DSETIN(=&dsetin).;
       %let g_abort=1;
     %end;
  %end;
 %else %if %qscan(&baselineoption, 2) NE BY AND %qscan(&baselineoption, 2) NE %then %do;
    %put %str(RTE)RROR: TU_BASELN_SDTMCONV: BASELINEOPTION cannot be more than one word unless the second word is BY.;
    %let g_abort=1;
  %end;

 %let baselineoption=%qscan(&baselineoption, 1);

 /* End BA002 */

 %if &baselineoption eq %then
 %do;
    %put %str(RTE)RROR: TU_BASELN_SDTMCONV: The parameter BASELINEOPTION is required.;
    %let g_abort=1;
 %end;
 
 %if &baselinetype eq %then       
 %do;
    %put %str(RTE)RROR: TU_BASELN_SDTMCONV: The parameter BASELINETYPE is required.;
    %let g_abort=1;
 %end;

 %if ( &baselineoption eq RELDAY ) and ( &RELDAYS eq ) %then
 %do;
    %put %str(RTE)RROR: TU_BASELN_SDTMCONV: The parameter RELDAYS is required when BASELINEOPTION is RELDAY.;
    %let g_abort=1;
 %end;

 %if ( ( &baselineoption eq VISIT ) or ( &baselineoption eq PTM ) ) and ( ( &STARTVISNUM eq ) or ( &ENDVISNUM eq ) ) %then    
 %do;
    %put %str(RTE)RROR: TU_BASELN_SDTMCONV: The parameters STARTVISNUM and ENDVISNUM are required when BASELINEOPTION is &BASELINEOPTION..;
    %let g_abort=1;
 %end;
 
 %if ( &baselineoption eq VISITPTM ) and ( ( &STARTPTMNUM eq ) or ( &ENDPTMNUM eq ) ) %then   
 %do;
    %put %str(RTE)RROR: TU_BASELN_SDTMCONV: The parameters STARTVISNUM(=&STARTVISNUM) and ENDVISNUM(=&ENDVISNUM) should contain two numbers when BASELINEOPTION is &BASELINEOPTION..;
    %let g_abort=1;
 %end;
 
 %if ( ( &baselineoption eq DATE ) or ( &baselineoption eq TIME ) ) and 
     ( &baselinetype eq LAST ) and ( &ENDVISNUM ne ) %then   
 %do;
    %put %str(RTE)RROR: TU_BASELN_SDTMCONV: The parameter ENDVISNUM (=&ENDVISNUM) should be blank when BASELINEOPTION equals &BASELINEOPTION and BASELINETYPE equals &baselinetype;
    %let g_abort=1;
 %end;
 
 %if ( &baselineoption eq RELDAY ) and ( ( &STARTVISNUM ne ) or ( &ENDVISNUM ne ) ) %then
 %do;
    %put %str(RTE)RROR: TU_BASELN_SDTMCONV: The parameters STARTVISNUM (=&STARTVISNUM) and (ENDVISNUM=&ENDVISNUM) should be blank when BASELINEOPTION equals &BASELINEOPTION;
    %let g_abort=1;
 %end; 
 
 %if ( ( &baselineoption eq DATE ) or ( &baselineoption eq TIME ) ) and 
     ( &baselinetype ne LAST ) and ( &ENDVISNUM ne ) %then                       
 %do;
    %put %str(RTE)RROR: TU_BASELN_SDTMCONV: The parameters ENDVISNUM (=&ENDVISNUM) should be blank when BASELINEOPTION equals &BASELINEOPTION and BASELINETYPE equals &baselinetype;
    %let g_abort=1;
 %end; 

 /* ems002 */
 %if ( &STARTVISNUM ne ) and ( &ENDVISNUM ne ) %then
 %do;
    %if %eval(&STARTVISNUM le &ENDVISNUM) ne 1 %then
    %do;
       %put %str(RTE)RROR: TU_BASELN_SDTMCONV: The value of parameter STARTVISNUM (=&STARTVISNUM) must be less than or equal to the value of ENDVISNUM (=&ENDVISNUM).;
       %let g_abort=1;
    %end;
 %end; /* %if ( &STARTVISNUM ne ) and ( &ENDVISNUM ne ) */
 
 %if ( &STARTPTMNUM ne ) and ( &ENDPTMNUM ne ) %then
 %do;
    %if %eval(&STARTPTMNUM le &ENDPTMNUM) ne 1 %then
    %do;
       /*
       / SL001
       / The second values of the parameters STARTVISNUM and ENDVISNUM have already been assigned to the macro variables
       / STARTPTMNUM and ENDPTMNUM respectively, and STARTVISNUM and ENDVISNUM have already been re-assigned to store only
       / the first values specified by the user.
       /---------------------------------------------------------------------------------------------------------------*/
       %put %str(RTE)RROR: TU_BASELN_SDTMCONV: The second value of parameter STARTVISNUM (=&STARTPTMNUM) must be less than or equal to the second value of ENDVISNUM (=&ENDPTMNUM).;
       %let g_abort=1;
    %end;
 %end; /* %if ( &STARTPTMNUM ne ) and ( &ENDPTMNUM ne ) */
 
 /*
 / Check for valid parameter values.
 /----------------------------------------------------------------------------*/

 %if ( &baselineoption ne DATE )  and ( &baselineoption ne RELDAY ) and ( &baselineoption ne PTM ) and      
     ( &baselineoption ne VISIT ) and ( &baselineoption ne TIME )   and ( &baselineoption ne VISITPTM ) %then
 %do;
    %put %str(RTE)RROR: TU_BASELN_SDTMCONV: The first word of BASELINEOPTION should be either DATE, RELDAY, VISIT, VISITPTM, PTM or TIME.;
    %let g_abort=1;
 %end;

 %if ( &baselinetype ne FIRST  ) and ( &baselinetype ne LAST ) and 
     ( &baselinetype ne MEDIAN ) and ( &baselinetype ne MEAN ) %then
 %do;
    %put %str(RTE)RROR: TU_BASELN_SDTMCONV: The first word of BASELINETYPE should be either FIRST, LAST, MEDIAN, or MEAN. The second word - if any - must be NOUNS.;
    %let g_abort=1;
 %end;

 /* BA002
 / Check that DOMAINCODE can be any 2 characters in length.
 /----------------------------------------------------------------------------*/

  %if %length(&domaincode) LT 2 %then %do;
    %put %str(RTE)RROR: TU_BASELN_SDTMCONV: Value of DOMAINCODE(=&domaincode) is invalid. The first word in domaincde must be at least 2 characters in length.;
    %let g_abort=1;
  %end;

 %if %qscan(&baselinetype, 2) NE %then %do;
    %put %str(RTE)RROR: TU_BASELN_SDTMCONV: Value of BASELINETYPE(=&baselinetype) is invalid. The second word needs to be NOUNS or be missing.;
    %let g_abort=1;
  %end;

 /* End BA002 */

 /*
 / Check for existing datasets.
 /----------------------------------------------------------------------------*/

 %if %sysfunc(exist(&dsetin)) eq 0 %then
 %do;
    %put %str(RTE)RROR: TU_BASELN_SDTMCONV: The dataset DSETIN (=&dsetin) does not exist.;
    %let g_abort=1;
 %end;
                                      
 %if ( ( &baselineoption eq VISIT ) or ( &baselineoption eq VISITPTM ) ) or
     ( ( &baselinetype ne  LAST ) and ( &baselineoption eq RELDAY ) ) %then
 %do;
    %if %tu_chkvarsexist(&dsetin, VISITNUM) ne %then
    %do;    
       %put %str(RTE)RROR: TU_BASELN_SDTMCONV: VISITNUM does not exist in DSETIN(=&dsetin) when BASELINEOPTION is &BASELINEOPTION and BASELINETYPE is &BASELINETYPE;
       %let g_abort=1;
    %end;
 %end;
 
 %if ( ( &baselineoption eq PTM ) or ( &baselineoption eq VISITPTM ) ) %then 
 %do;
    %if %tu_chkvarsexist(&dsetin, &domaincode.TPTNUM) ne %then
    %do;    
       %put %str(RTE)RROR: TU_BASELN_SDTMCONV: &domaincode.TPTNUM does not exist in DSETIN(=&dsetin) when BASELINEOPTION is &BASELINEOPTION;
       %let g_abort=1;
    %end;
    
    %if %tu_chkvarsexist(&dsetin, PERNUM) ne %then
    %do;    
      %let pernum=;
    %end;        
    %else %do;
      %let pernum=pernum;
    %end;
    
 %end;
 
 %if &byvar NE %then %let pernum=;  /* BA002 */

 /*
 / If the input dataset name is the same as the output dataset name,
 / write a note to the log.
 /----------------------------------------------------------------------------*/

 %if &dsetin eq &dsetout %then
 %do;
    %put %str(RTN)OTE: TU_BASELN_SDTMCONV: The input dataset name DSETIN(=&dsetin) is the same as the output dataset name DSETOUT(=&dsetout).;
 %end;

 %if &g_abort eq 1 %then
 %do;
   %tu_abort
 %end; 

 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/
 
 /* Comment out for SDTM
 %if &domaincode eq LB %then %let chgorcc=CHG;
 %else 
 */
 
 %let chgorcc=CH;
 
 %let domaincode=%unquote(&domaincode);
 
 /*
 / SL002
 / When this macro is used for SDTM conversion, the input datasets specified
 / via the DSETIN and STMEDDSET parameters will be in SDTM format, not SI format
 / as was expected by the original version of this macro.
 / The following code creates separate date and time variables corresponding to
 / the variables &domaincode.dtc in &DSETIN and exdtc in &STMEDDSET. The
 / original code for baseline flagging can then be executed using these
 / variables. The original code assumes that there are already separate date 
 / and time variables in the input datasets, as these are standard in SI
 / datasets. 
 /----------------------------------------------------------------------------*/

 data &prefix._dsetin;
   set &dsetin;
   format &domaincode.dt date9.;
   &domaincode.dt = input(scan(&domaincode.dtc, 1, 'T'), yymmdd10.);
   
  
   %if &BASELINEOPTION eq TIME %then
   %do;
     format &domaincode.acttm time5.;
     &domaincode.acttm = input(scan(&domaincode.dtc, 2, 'T'), time5.);
   %end; 

 run;

 %if ( &baselineoption eq DATE ) or ( &baselineoption eq RELDAY ) or ( &baselineoption eq TIME ) %then
 %do;

    %if (&stmeddset eq ) or not(%sysfunc(exist(&stmeddset))) %then
    %do;
       /* Study medication dataset parameter not passed OR Study medication dataset does not exist */

       data &prefix._final;
            set &prefix._dsetin;
            length &domaincode.&chgorcc.IND $40;

            &domaincode.&chgorcc.CD  = 'P';
            &domaincode.&chgorcc.IND = 'Pre-therapy';
            &domaincode.STDBL  = .;
       run;

       %if not(%sysfunc(exist(&stmeddset))) %then 
          %put %str(RTW)ARNING: TU_BASELN_SDTMCONV: STMEDDSET dataset &stmeddset does not exist. All records marked as Pre-therapy.;
       %else
          %put %str(RTW)ARNING: TU_BASELN_SDTMCONV: STMEDDSET parameter is blank. All records marked as Pre-therapy.;
    %end; /* end-if on study medication dataset not passed or medicatin dataset does not exist */

    %else
    %do;
      /* Study medication dataset exists */
          
      %let l_calcbaselineflag=1;

      %if %tu_chkvarsexist(&stmeddset, exstdtc) ne %then
      %do;          
        %put %str(RTE)RROR: EXSTDTC does not exist in STMEDDSET (=&STMEDDSET) and it is required when BASELINEOPTION equals &BASELINEOPTION;
	 %let g_abort=1;
         %tu_abort
      %end;

      %if &baselineoption eq TIME %then
      %do;
        data _null_;
          set &stmeddset end = eof;
          retain is_time 0;
          if index(exstdtc, 'T') then is_time = 1;
          if eof and not is_time then
          do;
            put 'RTW' "ARNING: &sysmacroname: BASELINEOPTION equals TIME, but"
               / "EXSTDTC does not contain any time values. Set BASELINEOPTION to DATE;";
            call symput('BASELINEOPTION', 'DATE');
          end;
        run;
      %end;
          
      data &prefix._stmeddset;
        set &stmeddset;
        format exstdt date9.;
        exstdt = input(scan(exstdtc, 1, 'T'), yymmdd10.);
        
        %if &baselineoption eq TIME %then
        %do;
          format exsttm time5.;
          exsttm = input(scan(exstdtc, 2, 'T'), time5.);
        %end;

       run;

       /*
       / YW001: assign STNUMVAR and STNUMSTAT according to if VISITNUM is in
       /        &stmeddset          
       / SL002: If the keyword PRE has been specified in BASELINEOPTION,
       /        then assessments that are taken on the same date (and time)
       /        as the first dose of study medication will be considered
       /        pre-treatment, regardless of the values of VISITNUM, so long 
       /        as they meet any condition specified after the keyword PRE;
       /        if a condition has been specified but not met, then the
       /        assessment will be considered on-treatment regardless of the
       /        value of VISITNUM.
       /-------------------------------------------------------------------*/
       %if %length(%tu_chkvarsexist(&prefix._stmeddset, VISITNUM)) eq 0 and &l_pre eq 0 %then 
       %do;
          %let stnumvar = stnum;   
          %let stnumstat = and visitnum lt stnum; 
       %end;
       %else %do;
          %let stnumvar=;
          %if %length(&l_condition) ge 1 %then %let stnumstat = %nrbquote(and (&l_condition));
          %else %let stnumstat =;
       %end;

       /*
       / Subset study medication dataset by where clause.          
       /-------------------------------------------------------------------*/
        data &prefix._stmed_subset;
            set &prefix._stmeddset;
            %if &stmeddsetsubset ne %then
            %do;
               where %unquote(&stmeddsetsubset);
            %end;
       run;
          
       proc sort data = &prefix._stmed_subset
                          ( keep   = studyid usubjid exstdt
                                     %if &baselineoption eq TIME %then exsttm;
                                     %if %nrbquote(&stnumvar) ne %then visitnum;
                            %if %nrbquote(&stnumvar) ne %then  /* YW001: added condition */
                            %do;         
                               rename = (visitnum = stnum) 
                            %end; 
                          )
                 out  = &prefix._stmed_sort;
            where not missing(exstdt);
            by studyid usubjid exstdt
               %if &baselineoption eq TIME %then exsttm;
               &stnumvar ;
       run;

       data &prefix._stmed;
            set &prefix._stmed_sort;
            by studyid usubjid;
            if first.usubjid;
       run;

       /*
       / Add medication start date/time and visit to lab data in order to
       / determine baseline records and records prior to baseline.
       /-------------------------------------------------------------------*/

       proc sql;
            create table &prefix._lab_stmed as
            select a.*, b.exstdt
                   %if &baselineoption eq TIME %then , b.exsttm;
                   %if %nrbquote(&stnumvar) ne %then , b.stnum;
            from &prefix._dsetin as a
                 left join &prefix._stmed as b
            on  a.studyid eq b.studyid and
                a.usubjid  eq b.usubjid ;
       quit;
                   
       data &prefix._pre 

            /* ems001 */
            %if &baselineoption eq TIME %then 
            %do;
                &prefix._postdose (drop = exstdt exsttm &stnumvar);
            %end;
            %else
            %do;
                &prefix._postdose (drop = exstdt &stnumvar);
            %end;

            set &prefix._lab_stmed;

            %if ( &baselineoption eq DATE ) or ( &baselineoption eq RELDAY ) %then
            %do;
               /* YW002: changed condition from - &domaincode.dt le exstdt &stnumstat */
               if ( exstdt eq . ) or (&domaincode.DT lt exstdt) or ( ( &domaincode.DT eq exstdt ) %unquote(&stnumstat) ) 
               then output &prefix._pre;
               else output &prefix._postdose;
            %end;

            %if &baselineoption eq TIME %then
            %do;
               if ( exsttm eq . ) or ( &domaincode.ACTTM eq . ) or ( &domaincode.DT ne exstdt ) then
               do;
                  /* Calculate on date only; YW002: changed condition from - &domaincode.dt le exstdt &stnumstat */
                  if ( exstdt eq . ) or ( &domaincode.DT lt exstdt ) or ( ( &domaincode.DT eq exstdt ) %unquote(&stnumstat) ) 
                  then output &prefix._pre;
                  else output &prefix._postdose;
               end;

               else do;
                  /* Calculate on time (&domaincode.dt = exstdt)  */
                  if ( &domaincode.ACTTM lt exsttm ) or ( ( &domaincode.ACTTM eq exsttm ) %unquote(&stnumstat) ) 
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
            length &domaincode.&chgorcc.IND $40;

            &domaincode.&chgorcc.CD  = 'P';
            &domaincode.&chgorcc.IND = 'Pre-therapy';
               
            %if &baselineoption eq DATE or &baselineoption eq TIME %then
            %do;
               %if &startvisnum ne %then
               %do;
                  if visitnum lt &startvisnum then output &prefix._predose;
                  else               
               %end;              
               if missing(&domaincode.STRESN) and missing(&domaincode.STRESC) then output &prefix._predose;
             %if &unschedule_flag = N %then %do;                                          /* BA002 */
               else if visitnum ne floor(visitnum) then output &prefix._predose;
              %end;
               else output &prefix._baseline;
            %end;

            %else %if &baselineoption eq RELDAY %then
            %do;
               if ( exstdt ne . ) and (&domaincode.DT ge (exstdt - abs(&reldays))) then 
               do;
                  if missing(&domaincode.STRESN) and missing(&domaincode.STRESC) then output &prefix._predose;
                %if &unschedule_flag = N %then %do;                                      /* BA002 */
                  else if visitnum ne floor(visitnum) then output &prefix._predose;
                 %end;
                  else output &prefix._baseline;
               end;
               else output &prefix._predose;
            %end;

            /* ems001 */
            %if &baselineoption eq TIME %then 
            %do;
                drop exstdt exsttm &stnumvar;
            %end;
            %else
            %do;
                drop exstdt &stnumvar;
            %end;
       run;
                   
       proc sort data=&prefix._baseline out=&prefix._baseline_sort;
            by studyid usubjid &pernum &byvar &domaincode.TESTCD &domaincode.DT
               %if &baselineoption eq TIME %then &domaincode.ACTTM;
               visitnum ;
       run;
         
    %end;  /* end-if on study medication dataset exists */

 %end;  /* end-if on &baselineoption eq DATE or &baselineoption eq RELDAY or &baselineoption eq TIME */
 
 %else %do; /* &baselineoption eq VISIT */
   
    /*
    / Split data into three groups: known pre-dose, possible baseline (mix
    / of pre-dose and baseline) and known post-dose.
    /----------------------------------------------------------------------*/

    %let l_calcbaselineflag=1;
    
    data &prefix._pre1 &prefix._baseline &prefix._postdose;
         set &prefix._dsetin;         
         %if &baselineoption eq VISIT %then
         %do;
            if visitnum lt &startvisnum then output &prefix._pre1;
            else if visitnum gt &endvisnum then output &prefix._postdose;
          %if &unschedule_flag = N %then %do;                                          /* BA002 */
            else if visitnum ne floor(visitnum) then output &prefix._postdose;
           %end;
            else output &prefix._baseline;
         %end;
         %if &baselineoption eq VISITPTM %then
         %do;
            if visitnum lt &startvisnum then output &prefix._pre1;
            else if visitnum gt &endvisnum then output &prefix._postdose;
            else do;
               if &domaincode.TPTNUM lt &startptmnum then output &prefix._pre1;
               else if &domaincode.TPTNUM gt &endptmnum then output &prefix._postdose;            
             %if &unschedule_flag = N %then %do;                                       /* BA002 */
               else if &domaincode.TPTNUM NE floor(&domaincode.TPTNUM) then output &prefix._postdose;
              %end;
               else output &prefix._baseline;
            end;
         %end;
         %if &baselineoption eq PTM %then
         %do;
            if &domaincode.TPTNUM lt &startptmnum then output &prefix._pre1;
            else if &domaincode.TPTNUM gt &endptmnum then output &prefix._postdose;
          %if &unschedule_flag = N %then %do;                                          /* BA002 */
            else if &domaincode.TPTNUM NE floor(&domaincode.TPTNUM) then output &prefix._postdose;
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
         length &domaincode.&chgorcc.IND $40;
         
         &domaincode.&chgorcc.CD  = 'P';
         &domaincode.&chgorcc.IND = 'Pre-therapy';

       %if &unschedule_flag = Y %then %do;                                            /* BA002 */
         if not missing(&domaincode.STRESN) or not missing(&domaincode.STRESC) then output &prefix._baseline;
        %end;
       %else %do;
         if not missing(&domaincode.STRESN) or not missing(&domaincode.STRESC) and visitnum = floor(visitnum) then output &prefix._baseline;
        %end;
         else output &prefix._pre2;
    run;
    
    data &prefix._predose;
         length &domaincode.&chgorcc.IND $40;
         set &prefix._pre1 &prefix._pre2;
         &domaincode.&chgorcc.CD  = 'P';
         &domaincode.&chgorcc.IND = 'Pre-therapy';         
    run;
   
    /*
    / For the mix of pre-dose and baseline, determine which is which.
    /
    / SL001 - If the time variable exists, then include time in the sort, so
    / that the dataset will be correctly sorted for obtaining the FIRST or
    / LAST observation when there are multiple observations within the 
    / baseline VISIT/PTM.
    /----------------------------------------------------------------------*/

    proc sort data=&prefix._baseline out=&prefix._baseline_sort;
         by studyid usubjid &pernum &byvar &domaincode.TESTCD &domaincode.DT 
         %if %length(%tu_chkvarsexist(&prefix._baseline, &domaincode.ACTTM)) eq 0 %then &domaincode.ACTTM; 
         %if ( &baselineoption eq VISIT ) or ( &baselineoption eq VISITPTM ) %then visitnum; 
         %if ( &baselineoption eq PTM )   or ( &baselineoption eq VISITPTM ) %then &domaincode.TPTNUM;
         ;
    run;
   
 %end;  /* end-if on &baselineoption eq VISIT */
 
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
            &prefix._base (keep   = studyid usubjid &domaincode.TESTCD &pernum &byvar  ) ;
            set &prefix._baseline_sort;
            by studyid usubjid &pernum &byvar &domaincode.TESTCD;
       
          %if &unschedule_flag = Y %then %do;                                /* BA002 */
            if &baselinetype..&domaincode.TESTCD then do;
           %end;
          %else %do;
            if &baselinetype..&domaincode.TESTCD and visitnum = floor(visitnum) then do;
           %end;
               output &prefix._base;
               &domaincode.&chgorcc.CD  = 'R';
               &domaincode.&chgorcc.IND = 'Baseline';
            end;
       
            output &prefix._baseline_final;
       run;
    %end;
    %else %do;
       proc summary data=&prefix._baseline_sort missing nway;
           by studyid usubjid &pernum &byvar &domaincode.TESTCD;
           var &domaincode.STRESN;
           output out=&prefix._base(keep=studyid usubjid &domaincode.TESTCD &pernum &byvar &domaincode.STDBL)
                  &baselinetype=&domaincode.STDBL;
       run;
       quit;
       
       data &prefix._baseline_final;
           set &prefix._baseline_sort;
           &domaincode.&chgorcc.CD  = 'R';
           &domaincode.&chgorcc.IND = 'Baseline';
       run;
    %end;
 
    /*
    / Combine pre-baseline, baseline and post-baseline data together.
    /----------------------------------------------------------------------*/
    
    data &prefix._xlab;
       set &prefix._predose &prefix._baseline_final &prefix._postdose;
    run;
   
    /* BA002
    / Merge baseline values to input dataset.
    /----------------------------------------------------------------------*/
    proc sort data=&prefix._xlab out=&prefix._xlab;
      by studyid usubjid &pernum &byvar &domaincode.TESTCD;
    run;

    proc sort data=&prefix._base out=&prefix._base;
      by studyid usubjid &pernum &byvar &domaincode.TESTCD;
    run;

    data &prefix._final;
      merge &prefix._base &prefix._xlab (in=a);
      by studyid usubjid &pernum &byvar &domaincode.TESTCD;
      if a;
    run;

 %end; /* %if &l_calcbaselineflag eq 1 */
  
 /*
 / Derive change from baseline value.
 /----------------------------------------------------------------------*/

 data &dsetout; 
    set &prefix._final (drop = &domaincode.dt %if &baselineoption eq TIME %then &domaincode.acttm;);;    
    /*
    if &domaincode.STRESN ne . and &domaincode.STDBL ne . and 
       &domaincode.&chgorcc.CD not in ('P','R')
    then STDCHGBL = &domaincode.STRESN - &domaincode.STDBL;
    */
 run;

 %skip:

 /*
 / Delete temporary datasets used in this macro.
 /----------------------------------------------------------------------------*/

 %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tu_baseln_sdtmconv;
