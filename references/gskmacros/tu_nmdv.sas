/******************************************************************************* 
|
| Macro Name:      tu_nmdv.sas
|
| Macro Version:   1.0
|
| SAS Version:     8.2
|
| Created By:      Andrew Ratcliffe, RTSL, www.ratcliffe.co.uk
|
| Date:            19-Jun-2005
|
| Macro Purpose:   Add dependant variables (DVs) to input dataset by interleaving 
|                  data sources.
|                  Prior to the interleaving, the exposure data shall have been 
|                  expanded to produce one row per dose.
|                  The interleaving shall be performed by &g_subjid and visitnum. 
|                  It shall be considered an error if there is dependant variable 
|                  data for a given subject's visit whilst there is no dosing data. 
|                  The order in which variables appear in the DV parameter shall 
|                  specify the order in which variables are interleaved when 
|                  there are matching values of subject/visit/time.
|                  The file shall always contain a column named EVID. This column 
|                  shall indicate whether the row contains dose information, 
|                  sampling information, or something else. "0" shall indicate 
|                  samples, "1" shall indicate doses. Other valid values are 2, 
|                  3, and 4. "3" shall indicate a change in period. "2" and 
|                  "4" shall not be used in this release of the Tools.
|                  For parallel group studies, EVID values of 0 and 1
|                  shall be used. 
|
| Macro Design:    PROCEDURE STYLE MACRO
| 
| Input Parameters:
|
| NAME              DESCRIPTION                         DEFAULT 
| DSETINEXP         Specifies the name of the input     ardata.exposure (Req)
|                   A&R EXPOSURE dataset
|
| DSETOUT           Specifies the name of the output    [blank] (Req)
|                   dataset to be created
|
| DV                Specifies the dependant variable(s) [blank] (Req)
|                   to be added to the exposure/dosing 
|                   information. 
|
| EXPAFTER          Specifies the relative position     0 (Req)
|                   of exposure/dosing information in 
|                   the event of matching DV date/time values
|
| EXPCMT            Specifies the CMT value to be       [blank] (Req)
|                   assigned to exposure/dosing rows in 
|                   the output file
|
| ILEAVEBY          Specifies the variable(s) by which  &g_subjid visitnum (Req)
|                   the dependant variable(s) shall be 
|                   interleaved
|
| OUTDATE           Specifies the name to be used for   date (Req) 
|                   the (formatted) date column in the 
|                   output file
|
| OUTTIME           Specifies the name to be used for   tim2 (Req) 
|                   the (formatted) time column in the 
|                   output file
|
| SORTBY            Specifies the variables to be       &ileaveby &outdate &outtime (Req)
|                   used to sort the result of the 
|                   interleaving of the dependant variable(s) 
|
| Output: This macro produces a copy of the input dataset, with additional columns
|         (for EVID, CMT, etc) and rows (for dependant variables)
|
| Global macro variables created:  None
|
| Macros called:
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_byid
| (@) tu_chknames
| (@) tu_chkvarsexist
| (@) tu_chkvartype
| (@) tu_putglobals
| (@) tu_tidyup
| (@) tu_words
| (@) tu_xcpput
| (@) tu_xcpsectioninit
| (@) tu_xcpsectionterm
|
| Example:
|
| %tu_nmdv(dsetinexp = ardata.exposure 
|         ,dsetout = work.dv  
|         ,dv = ardata.pkcnc  pcwnln  pcstdt pcsttm pcan 1
|               ardata.pkcnc  pcllqn  pcstdt pcsttm 'bp' 2
|         ,expcmt = 0
|         );
|
|******************************************************************************* 
| Change Log 
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     05-Jul-2005
| New version number:       1/2
| Modification ID:          AR2
| Reason For Modification:  Correctly rename exposure start date/time variables.
|                           Rename expevid to EXPCMT.
|                           Finish-off the list of sub-macros.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     29-Jul-2005
| New version number:       1/3
| Modification ID:          AR3
| Reason For Modification:  Remove references to PERIODRESET (moved to tu_nmtimeshift).
|                           Fix: Use where clauses in merge step.
|                           Fix: Set constant date/time values in merge step.
|                           Fix: Ensure validation of EXPCMT/EXPAFTER handles negatives.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     05-Sep-2005
| New version number:       1/4
| Modification ID:          AR4
| Reason For Modification:  Fix: Add conditional abort to end of step 5.
|                           Amend text of purpose to emphasise that exposure expanding 
|                           is done prior to this macro, not during.
|                           Remove redundant EXSTTM/EXENTM parameters.
|                           Fix: Make sure dvDset0 is set (to zero) when DV is blank.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     19-Sep-2005
| New version number:       1/5
| Modification ID:          AR5
| Reason For Modification:  Add validation for ILEAVEBY - report missing values to XCP.
|                           Sort all datasets before interleaving.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     20-Sep-2005
| New version number:       1/6
| Modification ID:          AR6
| Reason For Modification:  Check that DV datasets do not have missing values for 
|                           ILEAVEBY variables. Report missing values to XCP.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     21-Sep-2005
| New version number:       1/7
| Modification ID:          AR7
| Reason For Modification:  Add tu_words to list of sub-macros.
|                           Add text to header of xcp message for ileaveby/dsetinexp.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     21-Sep-2005
| New version number:       1/8
| Modification ID:          AR8
| Reason For Modification:  Fix: Use appropriate temporary name for sorted exposure data.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     23-Sep-2005
| New version number:       1/9
| Modification ID:          AR9
| Reason For Modification:  Fix: Check for missing DV when setting MDV for 
|                           DV records.
|
| Modified By:              
| Date of Modification:     
| New version number:       
| Modification ID:          
| Reason For Modification:  
|
********************************************************************************/ 

%macro tu_nmdv(dsetinexp   = ardata.exposure  /* type:ID Name of input A&R EXPOSURE dataset */
              ,dsetout     =                  /* Name of the output dataset */
              ,dv          =                  /* Dependant variable(s) */
              ,expafter    = 0                /* Relative position of exposure/dosing information in the event of matching DV date/time values */
              ,expcmt      =                  /* Compartment ID for exposure/dosing */
              ,ileaveby    = &g_subjid visitnum /* Variable(s) by which dependant variable(s) shall be interleaved */
              ,outdate     = date             /* Name of date column in output file */
              ,outtime     = tim2             /* Name of time column in output file */
              ,sortby      = &ileaveby &outdate &outtime /* Variable(s) by which the interleaved DV data shall be sorted */
              );

  /* Echo parameter values and global macro variables to the log */
 
  %local MacroVersion;
  %let MacroVersion = 1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=);

  %local prefix;
  %let prefix = %substr(&sysmacroname,3); 

  /* PARAMETER VALIDATION */

  /* Validate - DSETINEXP */
  %if %length(&dsetinexp) eq 0 %then 
  %do;
    %put RTE%str(RROR): &sysmacroname.: A value must be supplied for DSETINEXP;
    %let g_abort=1;
  %end;
  %else
  %do;
    %if not %sysfunc(exist(&dsetinexp)) %then 
    %do;
      %put RTE%str(RROR): &sysmacroname.: The DSETINEXP dataset (&dsetinexp) does not exist;
      %let g_abort=1;
    %end;
    %else
    %do;
      %if %length(%tu_chkvarsexist(&dsetinexp,EXSTTM)) gt 0 %then 
      %do;
        %put RTE%str(RROR): &sysmacroname.: The DSETINEXP dataset (&dsetinexp) does not contain an EXSTTM variable;
        %let g_abort=1;
      %end;
    %end;
  %end;

  /* Validate - DSETOUT */
  %if %length(%tu_chknames(&dsetout,DATA)) gt 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: The value supplied for DSETOUT (&dsetout) is not a valid dataset name;
    %let g_abort=1;
  %end;

  /* Validate - DV - done in normal processing */

  /* Validate - ILEAVEBY */
  %if %length(&ileaveby) eq 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: A value for ILEAVEBY must be specified;
    %let g_abort=1;
  %end;
  %else 
  %do;
    %if %length(%tu_chkvarsexist(&dsetinexp,&ileaveby)) ne 0 %then
    %do;
      %put RTE%str(RROR): &sysmacroname.: One or more of the variables in ILEAVEBY (&ileaveby) does not exist in DSETINEXP;
      %let g_abort=1;
    %end;
    %else
    %do;  /* Report any missing values to XCP */  /*AR5*/

      %local ptr;
      
      proc means data=&dsetinexp (keep=&ileaveby) nway missing noprint;
        class &ileaveby;
        output out=&prefix._ileave;
      run;

      data _null_;
        set &prefix._ileave end=finish;
        %tu_xcpsectioninit(header=Check for ILEAVEBY missing values in DSETINEXP);
        %do ptr = 1 %to %tu_words(&ileaveby);
          %let thisvar = %scan(&ileaveby,&ptr);
          if missing(&thisvar) then 
          do;
            %tu_xcpput("The %upcase(&thisvar) variable in ILEAVEBY has missing values in DSETINEXP"
                      ,WARNING);
          end;
        %end;
        %tu_xcpsectionterm(end=finish);
      run;

    %end;
  %end;

  /* Validate - SORTBY - done in normal processing */

  /* Validate - OUTDATE */
  %if %length(%tu_chknames(&outdate,VARIABLE)) gt 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: The value supplied for OUTDATE (&outdate) is not a valid variable name;
    %let g_abort=1;
  %end;

  /* Validate - OUTTIME */
  %if %length(%tu_chknames(&outtime,VARIABLE)) gt 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: The value supplied for OUTTIME (&outtime) is not a valid variable name;
    %let g_abort=1;
  %end;

  /* Validate - EXPAFTER */
  %if %length(&expafter) eq 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: EXPAFTER (&expafter) must not be blank;
    %let g_abort=1;
  %end;
  %else %if %datatyp(&expafter) ne NUMERIC %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: EXPAFTER (&expafter) must be numeric;
    %let g_abort=1;
  %end;
  %else %if %length(%sysfunc(compress(&expafter,0123456789))) gt 0 %then  /*AR3*/
  %do;
    %put RTE%str(RROR): &sysmacroname.: EXPAFTER (&expafter) must be a positive integer (or zero);
    %let g_abort=1;
  %end;

  /* Validate - EXPCMT */
  %if %length(&expcmt) eq 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: EXPCMT (&expcmt) must not be blank;
    %let g_abort=1;
  %end;
  %else %if %datatyp(&expcmt) ne NUMERIC %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: EXPCMT (&expcmt) must be numeric;
    %let g_abort=1;
  %end;
  %else %if %length(%sysfunc(compress(&expcmt,0123456789))) gt 0 %then  /*AR3*/
  %do;
    %put RTE%str(RROR): &sysmacroname.: EXPCMT (&expcmt) must be a positive integer (or zero);
    %let g_abort=1;
  %end;

  %tu_abort;

  /* NORMAL PROCESSING */

  /*
  / PLAN OF ACTION:
  / 1. Parse DV parameter into macro array(s)
  / 2. Verify that the DVs are numeric 
  / 3. Shuffle DVs around to insert exposure in right place, ref: EXPAFTER
  / 4. Now go and add (interleave) the DVs
  / 5. Validate - SORTBY 
  / 6. Sort into correct chronological order 
  / 7. Check for DV data with no dosing data (for given visit)
  /------------------------------------------------------*/

  /* 1. Parse DV parameter into macro array(s) */
  %local dvDset0; /* tells us how many array elements we have */  /* AR4*/

  %if %length(&dv) eq 0 %then
  %do;
    %put RT%str(NOT)E: &sysmacroname.: No dependant variables were specified. This is permitted, but unusual;
    %let dvDset0 = 0;  /* AR4*/
  %end;
  %else 
  %do; /* We have some DVs to parse */

    /*
    / Parse the DV parameter and put the constituent parts into macro variable 
    / arrays
    /------------------------------------------------------------------------------*/
    %local remainingString counter ptr;

    %let remainingString=%left(%trim(&dv));
    %let counter = 1;

    %do %while (%length(&remainingString) gt 0);

      %local dvDset&counter 
             dvVar&counter 
             dvDate&counter dvDateType&counter /* type=C or V, i.e. constant or variable */
             dvTime&counter dvTimeType&counter
             dvInd&counter  dvIndType&counter
             dvCompt&counter 
             dvWhere&counter; 

      /* Find end of dsname */
      %let ptr=%index(&remainingString,%str( ));

      %if &g_debug ge 2 %then
        %put RTD%str(EBUG): &sysmacroname: DATASET LENGTH: PTR=&ptr;

      %if &ptr eq 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname.: Parameter DV is incomplete. No variable to follow dataset name (&remainingString);
        %tu_abort(option=force);
      %end;

      /* Bite off the first word i.e the dv DATASET name */
      %let dvDset&counter=%substr(&remainingString,1,%eval(&ptr-1));

      %if &g_debug ge 2 %then
        %put RTD%str(EBUG): &sysmacroname: DATASET: dvDset&counter=&&dvDset&counter;

      /* Remainder after first bite */
      %let remainingString=%left(%trim(%substr(&remainingString,&ptr)));

      %if &g_debug ge 2 %then
        %put RTD%str(EBUG): &sysmacroname: DATASET: remainingString=&remainingString;

      /* Verify that the dataset specified in the DV parameter exists */
      %if not %sysfunc(exist(&&dvDset&counter)) %then
      %do; 
        %put RTE%str(RROR): &sysmacroname.: Parameter DV - Dataset (&&dvDset&counter) does not exist;
        %tu_abort(option=force);
      %end;

      /* Verify that the dataset contains the BY variables */
      %if %length(%tu_chkvarsexist(&&dvDset&counter,&ileaveby)) gt 0 %then
      %do; 
        %put RTE%str(RROR): &sysmacroname.: Parameter DV - Dataset (&&dvDset&counter) does not contain the BY variables (&ileaveby);
        %tu_abort(option=force);
      %end;

      /* Report any missing values to XCP */  /*AR6*/
      proc means data=&&dvDset&counter (keep=&ileaveby) nway missing noprint;
        class &ileaveby;
        output out=&prefix._ileave&counter;
      run;

      data _null_;
        set &prefix._ileave&counter end=finish;
        %tu_xcpsectioninit(header=Check for ILEAVEBY missing values in DV&counter (&&dvDset&counter));
        %do ptr = 1 %to %tu_words(&ileaveby);
          %let thisvar = %scan(&ileaveby,&ptr);
          if missing(&thisvar) then 
          do;
            %tu_xcpput("The %upcase(&thisvar) variable in ILEAVEBY has missing values in DV&counter dataset (&&dvDset&counter)"
                      ,WARNING);
          end;
        %end;
        %tu_xcpsectionterm(end=finish);
      run;

      /* Process the dep var */

      /* Find the end of the var name */
      %let ptr=%index(&remainingString,%str( ));

      %if &g_debug ge 2 %then
        %put RTD%str(EBUG): &sysmacroname: Dep var - LENGTH OF WORD2 : PTR=&ptr;

      %if &ptr eq 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname.: Parameter DV is incomplete. No date to follow dependant variable (&remainingString);
        %tu_abort(option=force);
      %end;

      %let dvVar&counter=%substr(&remainingString,1,&ptr);

      %if &g_debug ge 2 %then
        %put RTD%str(EBUG): &sysmacroname: Dep var : dvVar&counter=&&dvVar&counter;

      %let remainingString=%left(%trim(%substr(&remainingString,&ptr)));

      %if &g_debug ge 2 %then
        %put RTD%str(EBUG): &sysmacroname: Dep vars: remainingString=&remainingString;

      /* Verify that the dep var exists in the dv dataset */
      %if %length(%tu_chkvarsexist(&&dvDset&counter,&&dvVar&counter)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname.: Parameter DV - Variable (&&dvVar&counter) does not exist in dataset %upcase(&&dvDset&counter);
        %tu_abort(option=force);
      %end;
      
      /* Verify that the dep var does NOT exist in the DSETINEXP dataset */
      %if %length(%tu_chkvarsexist(&dsetinexp,&&dvVar&counter)) eq 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname.: Parameter DV - Variable (&&dvVar&counter) already exists in DSETINEXP (&dsetinexp);
        %tu_abort(option=force);
      %end;

      /* Prepare to bite off the third word i.e the date var/constant */
      %let ptr=%index(&remainingString,%str( ));

      %if &g_debug ge 2 %then
        %put RTD%str(EBUG): &sysmacroname: Dep var - LENGTH OF WORD3 : PTR=&ptr;

      %if &ptr eq 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname.: Parameter DV is incomplete. No time to follow date (&remainingString);
        %tu_abort(option=force);
      %end;

      /* Extract the DATE var/constant (word3) */
      %let dvDate&counter=%substr(&remainingString,1,&ptr);

      %if &g_debug ge 2 %then
        %put RTD%str(EBUG): &sysmacroname: DATE: dvDate&counter=&&dvDate&counter;

      %let remainingString=%left(%trim(%substr(&remainingString,&ptr)));

      %if &g_debug ge 2 %then
        %put RTD%str(EBUG): &sysmacroname: DATE: remainingString=&remainingString;

      /* Is it a var or a constant? Assume constant if it contains quotes */
      %if %sysfunc(indexc(&&dvDate&counter,%str(%")%str(%'))) ne 0 %then
        %let dvDateType&counter=C;
      %else
        %let dvDateType&counter=V;

      %if &g_debug ge 2 %then
        %put RTD%str(EBUG): &sysmacroname: DATE: dvDateType&counter=&&dvDateType&counter;

      /* Validate the date value */
      %if &&dvDateType&counter eq V %then
      %do;  /* Date is a var, not a constant */
        /* Verify that the DATE var exists in the DV dataset */
        %if %length(%tu_chkvarsexist(&&dvDset&counter,&&dvDate&counter)) ne 0 %then
        %do;
          %put RTE%str(RROR): &sysmacroname.: Parameter DV - DATE variable (&&dvDate&counter) does not exist in DV dataset (&&dvDset&counter);
          %tu_abort(option=force);
        %end;
      %end; /* Date is a var, not a constant */
      %else
      %do;  /* Date is a constant */
        /* Verify that it ends with d */
        %local r s;
        %let r=%sysfunc(reverse(&&dvDate&counter)); 
        %let s=%nrbquote(%substr(&r,1,1)); 
        %if %nrbquote(%upcase(&s)) ne D %then
        %do;
          %put RTE%str(RROR): &sysmacroname.: Parameter DV - DATE constant (&&dvDate&counter) is not a valid SAS date constant;
          %tu_abort(option=force);
        %end;
      %end; /* Date is a constant */

      /* Prepare to bite off the fourth word i.e the time var/constant */
      %let ptr=%index(&remainingString,%str( ));

      %if &g_debug ge 2 %then
        %put RTD%str(EBUG): &sysmacroname: Dep var - LENGTH OF WORD4 : PTR=&ptr;

      %if &ptr eq 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname.: Parameter DV is incomplete. No compartment to follow time (&remainingString);
        %tu_abort(option=force);
      %end;

      /* Extract the TIME var/constant (word4) */
      %let dvTime&counter=%substr(&remainingString,1,&ptr);

      %if &g_debug ge 2 %then
        %put RTD%str(EBUG): &sysmacroname: TIME: dvTime&counter=&&dvTime&counter;

      %let remainingString=%left(%trim(%substr(&remainingString,&ptr)));

      %if &g_debug ge 2 %then
        %put RTD%str(EBUG): &sysmacroname: TIME: remainingString=&remainingString;

      /* Is it a var or a constant? Assume constant if it contains quotes */
      %if %sysfunc(indexc(&&dvTime&counter,%str(%")%str(%'))) ne 0 %then
        %let dvTimeType&counter=C;
      %else
        %let dvTimeType&counter=V;

      %if &g_debug ge 2 %then
        %put RTD%str(EBUG): &sysmacroname: TIME: dvTimeType&counter=&&dvTimeType&counter;

      /* Validate the time value */
      %if &&dvTimeType&counter eq V %then
      %do;  /* Time is a var, not a constant */
        /* Verify that the TIME var exists in the DV dataset */
        %if %length(%tu_chkvarsexist(&&dvDset&counter,&&dvTime&counter)) ne 0 %then
        %do;
          %put RTE%str(RROR): &sysmacroname.: Parameter DV - TIME variable (&&dvTime&counter) does not exist in DV dataset (&&dvDset&counter);
          %tu_abort(option=force);
        %end;
      %end; /* Time is a var, not a constant */
      %else
      %do;  /* Time is a constant */
        /* Verify that it ends with t */
        %local r s;
        %let r=%sysfunc(reverse(&&dvTime&counter)); 
        %let s=%nrbquote(%substr(&r,1,1)); 
        %if %nrbquote(%upcase(&s)) ne T %then
        %do;
          %put RTE%str(RROR): &sysmacroname.: Parameter DV - TIME constant (&&dvTime&counter) is not a valid SAS time constant;
          %tu_abort(option=force);
        %end;
      %end; /* Time is a constant */

      /* Prepare to bite off the fifth word i.e the indicator */
      %let ptr=%index(&remainingString,%str( ));

      %if &g_debug ge 2 %then
        %put RTD%str(EBUG): &sysmacroname: Dep var - LENGTH OF WORD5 : PTR=&ptr;

      %if &ptr eq 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname.: Parameter DV is incomplete. No indicator to follow time (&remainingString);
        %tu_abort(option=force);
      %end;

      /* Extract the indicator (word5) */
      %let dvInd&counter=%substr(&remainingString,1,&ptr);

      %if &g_debug ge 2 %then
        %put RTD%str(EBUG): &sysmacroname: IND: dvInd&counter=&&dvInd&counter;

      %let remainingString=%left(%trim(%substr(&remainingString,&ptr)));

      %if &g_debug ge 2 %then
        %put RTD%str(EBUG): &sysmacroname: IND: remainingString=&remainingString;

      /* Is it a var or a constant? Assume constant if it contains quotes */
      %if %sysfunc(indexc(&&dvInd&counter,%str(%")%str(%'))) ne 0 %then
        %let dvIndType&counter=C;
      %else
        %let dvIndType&counter=V;

      %if &g_debug ge 2 %then
        %put RTD%str(EBUG): &sysmacroname: IND: dvIndType&counter=&&dvIndType&counter;

      /* Validate the ind value */
      %if &&dvIndType&counter eq V %then
      %do;  /* Ind is a var, not a constant */
        /* Verify that the IND var exists in the DV dataset */
        %if %length(%tu_chkvarsexist(&&dvDset&counter,&&dvInd&counter)) ne 0 %then
        %do;
          %put RTE%str(RROR): &sysmacroname.: Parameter DV - IND variable (&&dvInd&counter) does not exist in DV dataset (&&dvDset&counter);
          %tu_abort(option=force);
        %end;
      %end; /* Ind is a var, not a constant */
      %else
      %do;  /* Ind is a constant */
        /* No validation */
      %end; /* Ind is a constant */

      /* Prepare to bite off the sixth word i.e the compartment */
      %let ptr=%index(&remainingString%str( ),%str( ));

      %if &g_debug ge 2 %then
        %put RTD%str(EBUG): &sysmacroname: Dep var - LENGTH OF WORD5 : PTR=&ptr;

      /* Extract the compartment (word6) */
      %let dvCompt&counter=%substr(&remainingString%STR( ),1,&ptr);

      %if &g_debug ge 2 %then
        %put RTD%str(EBUG): &sysmacroname: COMPARTMENT: dvCompt&counter=&&dvCompt&counter;

      %let remainingString=%left(%trim(%substr(&remainingString%str( ),&ptr)));

      %if &g_debug ge 2 %then
        %put RTD%str(EBUG): &sysmacroname: COMPARTMENT: remainingString=&remainingString;

      %if %datatyp(&&dvCompt&counter) ne NUMERIC %then
      %do;
        %put RTE%str(RROR): &sysmacroname.: Parameter DV - COMPARTMENT value (&&dvCompt&counter) is not numeric;
        %tu_abort(option=force);
      %end;

      /* Extract the optional WHERE clause */
      %if %substr(&remainingString%STR( ),1,1) eq [ %then 
      %do;  /* We have a WHERE clause */

        %let ptr=%index(&remainingString,]);

        %if &ptr eq 0 %then
        %do;
          %put RTE%str(RROR): &sysmacroname.: Parameter DV - Unmatched square brackets around where clause: &remainingString;
          %tu_abort(option=force);
        %end;

        %if &g_debug ge 2 %then
        %do;
          %put RTD%str(EBUG): &sysmacroname: OPTIONAL WHERE: PTR=&ptr;
        %end;

        %let dvWhere&counter=%substr(&remainingString%str( ),2,%eval(&ptr-2));

        %if &g_debug ge 2 %then
        %do;
          %put RTD%str(EBUG): &sysmacroname: OPTIONAL WHERE: dvWhere&counter=&&dvWhere&counter;
        %end;

        %if %eval(&ptr+1) lt %length(&remainingString) %then
        %do;
          %let remainingString=%sysfunc(left(%sysfunc(trim(%substr(&remainingString,%eval(&ptr+1))))));

          %if &g_debug ge 2 %then
          %do;
            %put RTD%str(EBUG): &sysmacroname: OPTIONAL WHERE: remainingString=&remainingString;
          %end;

        %end;
        %else 
          %let remainingString=;
      %end; /* We have a WHERE clause */

      %let counter=%eval(&counter+1);

    %end; /* do while (remainingString ne blank) */

    %let dvDset0=%eval(&counter-1);

  %end; /* We have some DVs to parse */

  %if &g_debug ge 1 %then
  %do;  /* Dump the parsed DV parameter */
    %put RTD%str(EBUG): &sysmacroname: Parsing is complete: DVDSET0=&dvDset0;
    %do counter=1 %to &dvDset0;
      %put RTD%str(EBUG): &sysmacroname: dvDset&counter=&&dvDset&counter, dvVar&counter=&&dvVar&counter;
      %put RTD%str(EBUG): &sysmacroname: dvDate&counter=&&dvDate&counter, dvDateType&counter=&&dvDateType&counter;
      %put RTD%str(EBUG): &sysmacroname: dvTime&counter=&&dvTime&counter, dvTimeType&counter=&&dvTimeType&counter;
      %put RTD%str(EBUG): &sysmacroname: dvInd&counter=&&dvInd&counter, dvIndType&counter=&&dvIndType&counter;
      %put RTD%str(EBUG): &sysmacroname: dvCompt&counter=&&dvCompt&counter, dvWhere&counter=&&dvWhere&counter;
      %put RTD%str(EBUG): &sysmacroname: ;
    %end; /* loop over dvdset0 */
  %end; /* Dump the parsed DV parameter */

  /* 2. Verify that the DVs are numeric */
  %do counter = 1 %to &dvDset0;
    %if %tu_chkvartype(&&dvDset&counter,&&dvVar&counter) ne N %then
    %do;
      %put RTE%str(RROR): &sysmacroname: Dependant variable (&&dvDset&counter,&&dvVar&counter) is not numeric;
      %tu_abort(option=force);
    %end;
  %end;

  /*
  / 3. Shuffle DVs around to insert exposure in right place, ref: EXPAFTER.
  / In so doing, we increase dvdset0 by one.
  /------------------------------------------------------*/
  %local downCounter;
  %do counter = &dvDset0+1 %to 1 %by -1;

    %let downCounter = %eval(&counter - 1);

    %if &downCounter gt &expafter %then
    %do;  /* shuffle */
      %let dvDset&counter = &&dvDset&downCounter;
      %let dvVar&counter = &&dvVar&downCounter;
      %let dvDate&counter = &&dvDate&downCounter;
      %let dvDateType&counter = &&dvDateType&downCounter;
      %let dvTime&counter = &&dvTime&downCounter;
      %let dvTimeType&counter = &&dvTimeType&downCounter;
      %let dvInd&counter = &&dvInd&downCounter;
      %let dvIndType&counter = &&dvIndType&downCounter;
      %let dvCompt&counter = &&dvCompt&downCounter;
      %let dvWhere&counter = &&dvWhere&downCounter;
    %end; /* shuffle */
    %if &counter eq &expafter+1 %then
    %do;  /* Insert exp */
      %let dvDset&counter = EXPO..SURE;
      %let dvVar&counter = ;
      %let dvDate&counter = ;
      %let dvDateType&counter = ;
      %let dvTime&counter = ;
      %let dvTimeType&counter = ;
      %let dvInd&counter = ;
      %let dvIndType&counter = ;
      %let dvCompt&counter = ;
      %let dvWhere&counter = ;
    %end; /* Insert exp */

  %end; /* loop over dvdset0 backwards */
  %let dvDset0 = %eval(&dvDset0+1);

  /* 4a. Sort the input datasets (exposure, then DVs) */  /*AR5*/
  %local dsetinexpSorted;
  %let dsetinexpSorted = &prefix._dsetinexpSorted;
  proc sort data=&dsetinexp out=&dsetinexpSorted;
    by &ileaveby;
  run;

  /* */
  %do counter = 1 %to &dvDset0;
    %if &&dvDset&counter ne EXPO..SURE %then
    %do;
      proc sort data=&&dvDset&counter out=work.&prefix._expoSorted;  /*AR8*/
        by &ileaveby;
      run;
      %let dvDset&counter = work.&prefix._expoSorted;  /*AR8*/
    %end;
  %end;

  /* 4b. Now go and add (interleave) the DVs */

  %if &g_debug ge 1 %then
  %do;
    %do counter=1 %to &dvDset0;
      %put RTD%str(EBUG): &sysmacroname: Adding (interleaving) DV &counter:;
      %put RTD%str(EBUG): &sysmacroname: dvDset&counter=&&dvDset&counter, dvVar&counter=&&dvVar&counter;
      %put RTD%str(EBUG): &sysmacroname: dvDate&counter=&&dvDate&counter, dvDateType&counter=&&dvDateType&counter;
      %put RTD%str(EBUG): &sysmacroname: dvTime&counter=&&dvTime&counter, dvTimeType&counter=&&dvTimeType&counter;
      %put RTD%str(EBUG): &sysmacroname: dvInd&counter=&&dvInd&counter, dvIndType&counter=&&dvIndType&counter;
      %put RTD%str(EBUG): &sysmacroname: dvCompt&counter=&&dvCompt&counter, dvWhere&counter=&&dvWhere&counter;
      %put RTD%str(EBUG): &sysmacroname: ;
    %end;
  %end;

  data work.&prefix._leaved;
    set 
        %do counter=1 %to &dvDset0;

          %if &&dvDset&counter eq EXPO..SURE %then
          %do;  /* exposure */
            &dsetinexpSorted (in=fromExp 
                              rename=(dose=amt
                                      exstdt=&outdate  /*AR2*/
                                      exsttm=&outtime
                                     )
                             )
          %end; /* exposure */
          %else
          %do;  /* dv */
            &&dvDset&counter (in=fromDv&counter
                              keep=&ileaveby &&dvVar&counter
                                   %if &&dvDateType&counter eq V %then 
                                     &&dvDate&counter;
                                   %if &&dvTimeType&counter eq V %then 
                                     &&dvTime&counter;
                                   %if &&dvIndType&counter eq V %then 
                                     &&dvInd&counter;
			                        rename=(&&dvVar&counter=dv
                                      %if &&dvDateType&counter eq V %then 
                                        &&dvDate&counter=&outdate;
                                      %if &&dvTimeType&counter eq V %then 
                                        &&dvTime&counter=&outtime;
								                     )
                              %if %length(&&dvWhere&counter) gt 0 %then  /*AR3*/
                              %do;
                                where=(&&dvWhere&counter)
                              %end;
                             )
          %end; /* dv */

        %end; /* Loop over dvdset0 */
        end=finish
        ;
    by &ileaveby;
    attrib evid length=4
           ind  length=$32
           mdv  length=4
           cmt  length=4
           ;
    format &outdate date. 
           &outtime time.;
    %do counter=1 %to &dvDset0;
      %if &&dvIndType&counter eq V %then 
      %do;
        drop &&dvInd&counter;
      %end;
    %end;

	  if fromExp then 
    do;
      evid=1;
      ind="";
      cmt=&expcmt;
      mdv=1;
  	end;
  	else
  	do;
      evid=0;
      %do counter=1 %to &dvDset0;

        %if &&dvDset&counter ne EXPO..SURE %then
        %do;  /* dv */
    	    if fromDv&counter then
    		  do;
            cmt=&&dvCompt&counter;
            ind=&&dvInd&counter;
            if dv eq . then  /*AR9*/
              mdv = 1;
            else
              mdv=0;
            %if &&dvDateType&counter eq C %then  /*AR3*/
            %do;
              &outdate = &&dvDate&counter;
            %end;
            %if &&dvTimeType&counter eq C %then  /*AR3*/
            %do;
              &outtime = &&dvTime&counter;
            %end;
          end;
        %end; /* dv */

  	  %end; /* loop over dvdset0 */
  	end;

  run;

  /* 5. Validate - SORTBY */
  %if %length(&sortby) eq 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: A value for SORTBY must be specified;
    %let g_abort=1;
  %end;
  %else 
  %do;
    %if %length(%tu_chkvarsexist(work.&prefix._leaved,&sortby)) ne 0 %then
    %do;
      %put RTE%str(RROR): &sysmacroname.: One or more of the variables in SORTBY (&sortby) does not exist in DSETINEXP;
      %let g_abort=1;
    %end;
  %end;
  %tu_abort;  /*AR4*/

  /* 6. Sort into correct chronological order */
  proc sort data=work.&prefix._leaved out=&dsetout;
    by &sortby;
  run;

  /* 7. Check for DV data with no dosing data (for given visit) */
  %local lastBy;
  %let lastBy = %scan(&ileaveby,-1);

  data _null_;
    set &dsetout end=finish;
    by &ileaveby;
    retain GotDosing;
    drop __msg;
    %tu_xcpsectionInit(header=Check for DV Data With no Dosing Data);
    if first.&lastBy then
    do;
      GotDosing = 0;
    end;
    if evid eq 1 then
      GotDosing = 1;
    if last.&lastBy and not GotDosing then
    do;
      %tu_byid(dsetin=&dsetout
              ,invars=&ileaveby
              ,outvar=__msg
              );
      %tu_xcpput("Dependant variable data with no dosing data for given interleave-group: " !! __msg
                ,ERROR);
    end;
    %tu_xcpsectionTerm(end=finish);
  run;

  /* Finish-off */
  %tu_tidyup(rmdset=&prefix:
            ,glbmac=NONE
            );
  quit;

  %tu_abort;

%mend tu_nmdv;
