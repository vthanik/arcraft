/******************************************************************************* 
|
| Macro Name:      tu_nmexpoexpand.sas
|
| Macro Version:   1.0
|
| SAS Version:     8.2
|
| Created By:      Andrew Ratcliffe, RTSL, www.ratcliffe.co.uk
|
| Date:            19-Jun-2005
|
| Macro Purpose:   Expand rows in the exposure dataset that contain dose 
|                  frequency codes, such that each row in the output dataset 
|                  represents one single dose event.
|                  For non-placebo rows where the dose is missing, a record 
|                  shall be written to the reconciliation report.
|
| Macro Design:    PROCEDURE STYLE MACRO
| 
| Input Parameters:
|
| NAME              DESCRIPTION                         DEFAULT 
| BY                Specifies variables that uniquely   [blank] (Req)
|                   identify the rows (used in XCP)
|
| DOSETIMES         Specifies time constants for        [blank] (Opt)
|                   dosing times for specific dosing 
|                   frequencies
|
| DSETIN            Specifies the name of the input     [blank] (Req)
|                   A&R EXPOSURE dataset
|
| DSETOUT           Specifies the name of the output    [blank] (Req)
|                   dataset to be created
|
| EXENTM            Specifies the name of the end-      exentm (Req)
|                   time column in the DSETIN
|                   dataset. Can alternatively be specified as a time constant
|
| EXSTTM            Specifies the name of the start-    exsttm (Req)
|                   time column in the DSETIN 
|                   dataset. Can alternatively be specified as a time constant
|
| PLACEBO           Specifies a where-clause to         &g_trtgrp eq: 'Pl' (Req)
|                   identify placebo rows
|
| Output: This macro produces a copy of the input dataset, with additional 
|         columns and rows
|
| Global macro variables created:  None
|
| Macros called:
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_chknames
| (@) tu_chkvarsexist
| (@) tu_chkvartype
| (@) tu_xcpsectioninit
| (@) tu_xcpput
| (@) tu_xcpsectionterm
| (@) tu_byid
| (@) tu_tidyup
| (@) tu_abort
|
| Example:
|
| %tu_nmexpoexpand(by = &g_subjid visitnum
|                 ,dosetimes = [bid '11:00't '18:00't]
|                 ,dsetin = ardata.exposure 
|                 ,dsetout = work.expanded
|                 );
|
|******************************************************************************* 
| Change Log 
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     05-Jul-2005
| New version number:       1/2
| Modification ID:          AR2
| Reason For Modification:  Make correction to header comment information for DSETOUT.
|                           Drop end date/time variables.
|                           Add DAYINTERVAL value to where clauses where it had been missing.
|                           Finish-off the list of sub-macros.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     11-Aug-2005
| New version number:       1/3
| Modification ID:          AR3
| Reason For Modification:  Increase use of quoting functions when validating 
|                           EXSTTM/EXENTM.
|                           Fix: Make PRN invalid in DOSETIMES.
|                           Fix: allow fourth time for QID.
|                           Add validation to be sure sufficient time values 
|                           are supplied for each DOSETIMES code.
|                           Fix: Replace "call symput g_abort" with "tu_abort option=force".
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     31-Aug-2005
| New version number:       1/4
| Modification ID:          AR4
| Reason For Modification:  Fix: Use correct start-time values for all days in range for
|                           whole date range.
|                           Add validation of times within DOSETIMES.
|                           Enhance validation of EXSTTM/EXENTM to check that var is numeric.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     15-Sep-2005
| New version number:       1/5
| Modification ID:          
| Reason For Modification:  Fix: Indentation in code, and a spelling mistake in a message.
|                           EXENTM only required when exposure data contains frequency codes.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     22-Sep-2005
| New version number:       1/6
| Modification ID:          AR6
| Reason For Modification:  Fix: Do not create/use exentm/dt/dm when exposure 
|                           data does not contain frequency codes.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     22-Sep-2005
| New version number:       1/7
| Modification ID:          AR7
| Reason For Modification:  Keep DOSEUNIT and DOSEUCD if either/both exist in DSETIN.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     27-Sep-2005
| New version number:       1/8
| Modification ID:          AR8
| Reason For Modification:  Add extra validation for EXSTDT/TM and EXENDT/TM for 
|                           missing values.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     26-Oct-2005
| New version number:       1/9
| Modification ID:          AR9
| Reason For Modification:  Fix: Add necessary do/end statements around 
|                           debugging code.
|
| Modified By:              
| Date of Modification:     
| New version number:       
| Modification ID:          
| Reason For Modification:  
|
********************************************************************************/ 

%macro tu_nmexpoexpand(by        =        /* Variables that identify the rows uniquely */
                      ,dosetimes =        /* Times to be used for each dose frequency code */
                      ,dsetin    =        /* type:ID Name of input A&R EXPOSURE dataset */
                      ,dsetout   =        /* Name of the output dataset */
                      ,exentm    = exentm /* Name of the end-time column in DSETIN (or a time constant) */
                      ,exsttm    = exsttm /* Name of the start-time column in DSETIN (or a time constant) */
                      ,placebo   = &g_trtgrp eq: 'Pl' /* Where clause to identify placebo */
                      );

  /* Echo parameter values and global macro variables to the log */
 
  %local MacroVersion;
  %let MacroVersion = 1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=);

  %local prefix;
  %let prefix = %substr(&sysmacroname,3); 

  /* PARAMETER VALIDATION */

  /* Validate - DSETIN */
  %local dsetinNoOptions;
  %if %length(&dsetin) eq 0 %then 
  %do;
    %put RTE%str(RROR): &sysmacroname.: A value must be supplied for DSETIN;
    %let g_abort=1;
  %end;
  %else
  %do;
    %if %index(&dsetin,%str(%()) eq 0 %then
      %let dsetinNoOptions = &dsetin;
    %else
      %let dsetinNoOptions =%substr(&dsetin,1,%index(&dsetin,%str(%())-1);
    %if &g_debug ge 1 %then
      %put RTD%str(EBUG): &sysmacroname: DSETINNOOPTIONS=&dsetinNoOptions;

    %if not %sysfunc(exist(&dsetinNoOptions)) %then 
    %do;
      %put RTE%str(RROR): &sysmacroname.: The DSETIN dataset (&dsetin) does not exist;
      %let g_abort=1;
    %end;
    %else
    %do;  /* Validate contents of DSETIN */  /*AR8*/

      /* Check that EXSTDT and EXENDT are present in the dataset */
      %if %length(%tu_chkvarsexist(&dsetinNoOptions,EXSTDT EXENDT)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname.: One or both of the start/end date variables (EXSTDT/EXENDT) does not exist in DSETIN;
        %let g_abort=1;
      %end;

      /* Check that EXSTDT has no missing values, and that EXENDT has no missing values in rows where DOSEFRCD is not blank */
      data _null_;
        set &dsetin;
        %tu_byid(dsetin=&dsetinNoOptions
                ,invars=&by
                ,outvar=__msg
                );
        if missing(exstdt) then
        do;
          put "RTE" "RROR: &sysmacroname.: A missing value was detected for EXSTDT in DSETIN: " __msg;
          call symput('G_ABORT','1');;
        end;
        if not missing(dosefrcd) and missing(exendt) then
        do;
          put "RTE" "RROR: &sysmacroname.: A missing value was detected for EXENDT in DSETIN in a row where DOSEFRCD was not blank: " __msg;
          call symput('G_ABORT','1');;
        end;
      run;
      %tu_abort;

    %end; /* Validate contents of DSETIN */
  %end;

  /* Validate - DSETOUT */
  %if %length(%tu_chknames(&dsetout,DATA)) gt 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: The value supplied for DSETOUT (&dsetout) is not a valid dataset name;
    %let g_abort=1;
  %end;

  /* Validate - BY */
  %if %length(&by) eq 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: A value for BY must be specified;
    %let g_abort=1;
  %end;
  %else 
  %do;
    %if %length(%tu_chkvarsexist(&dsetin,&by)) ne 0 %then
    %do;
      %put RTE%str(RROR): &sysmacroname.: One or more of the variables in BY (&by) does not exist in DSETIN;
      %let g_abort=1;
    %end;
  %end;

  /* Validate - EXSTTM */

  %if %length(&exsttm) eq 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: A value for EXSTTM must be specified;
    %let g_abort=1;
  %end;
  %else 
  %do;
    %if %index(&exsttm,%str(%')) or %index(&exsttm,%str(%")) %then
    %do;  /* Assume it is a time constant */
      %if %nrbquote(%upcase(%nrbquote(%substr(&exsttm,%length(&exsttm))))) ne T %then  /*AR3*/
      %do;
        %put RTE%str(RROR): &sysmacroname.: The value specified for EXSTTM (&exsttm) is not a variable name nor a time constant;
        %let g_abort=1;
      %end;
    %end; /* Assume it is a time constant */
    %else
    %do;  /* Assume it is a variable name */
      %if %tu_chkvartype(&dsetin,&exsttm) ne N %then  /*AR4*/
      %do;
        %put RTE%str(RROR): &sysmacroname.: The EXSTTM variable (&exsttm) does not exist as a numeric variable in DSETIN;  /*AR4*/
        %let g_abort=1;
      %end;
      %else  /*AR8*/
      %do;  
        /* Check that variable has no missing values */
        data _null_;
          set &dsetin;
          %tu_byid(dsetin=&dsetinNoOptions
                  ,invars=&by
                  ,outvar=__msg
                  );
          if missing(exsttm) then
          do;
            put "RTE" "RROR: &sysmacroname.: One or more missing values were detected for EXSTTM in DSETIN: " __msg;
            call symput('G_ABORT','1');;
          end;
        run;
        %tu_abort;
      %end;
    %end; /* Assume it is a variable name */
  %end;

  /* Validate - EXENTM (only if DOSEFRCD contains non-missing values) */  /*AR5*/
  %local codesFound;
  %let codesFound = 0;
      /* Must "resolve" dsetin first because it may have a WHERE clause */
  data &prefix._resolvedDsetin/view=&prefix._resolvedDsetin;
    set &dsetin;
  run;

  data _null_;
    set &prefix._resolvedDsetin;
    where dosefrcd ne '';
    call symput('CODESFOUND','1');
    STOP;
  run;
  %if &g_debug ge 1 %then
    %put RTD%str(EBUG): &sysmacroname: Considering validation of EXENTM: CODESFOUND=&codesFound;

  %if &codesFound %then
  %do;  /* Need to validate EXENTM */

    %if %length(&exentm) eq 0 %then
    %do;
      %put RTE%str(RROR): &sysmacroname.: A value for EXENTM must be specified;
      %let g_abort=1;
    %end;
    %else 
    %do;
      %if %index(&exentm,%str(%')) or %index(&exentm,%str(%")) %then
      %do;  /* Assume it is a time constant */
        %if %nrbquote(%upcase(%nrbquote(%substr(&exentm,%length(&exentm))))) ne T %then  /*AR3*/
        %do;
          %put RTE%str(RROR): &sysmacroname.: The value specified for EXENTM (&exsttm) is not a variable name nor a time constant;
          %let g_abort=1;
        %end;
      %end; /* Assume it is a time constant */
      %else
      %do;  /* Assume it is a variable name */
        %if %tu_chkvartype(&dsetin,&exentm) ne N %then  /*AR4*/
        %do;
          %put RTE%str(RROR): &sysmacroname.: The EXENTM variable (&exentm) does not exist as a numeric variable in DSETIN;  /*AR4*/
          %let g_abort=1;
        %end;
        %else  /*AR8*/
        %do;  
          /* Check that variable has no missing values where DOSEFRCD is not blank */
          data _null_;
            set &dsetin;
            %tu_byid(dsetin=&dsetinNoOptions
                    ,invars=&by
                    ,outvar=__msg
                    );
            if not missing(dosefrcd) and missing(exentm) then
            do;
              put "RTE" "RROR: &sysmacroname.: One or more missing values were detected for EXENTM in DSETIN where DOSEFRCD was not blank: "  __msg;
              call symput('G_ABORT','1');;
            end;
          run;
          %tu_abort;
        %end;
      %end; /* Assume it is a variable name */
    %end;

  %end; /* Need to validate EXENTM */

  /* Validate - DOSETIMES - done in normal processing */

  /* Validate - PLACEBO - cannot check the syntax */
  %if %length(&placebo) eq 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: PLACEBO must not be missing;
    %let g_abort=1;
  %end;

  %tu_abort;

  /* NORMAL PROCESSING */

  /*
  / PLAN OF ACTION
  / 1. Parse DOSETIMES
  / 2. Check for missing doses (non-placebo)
  / 3. What can we keep? (DOSEUNIT/DOSEUCD)  (AR7)
  / 4. Go do it
  /------------------------------------------------------*/
  %local ptr phrase len phraseType phraseTimes;

  /* 1. Parse DOSETIMES */
  %local time1xam time2xam timebid timehs timeod 
         timeqam timeqd timeqid timeqod timetid
         ;

  %if %index(&dosetimes,%str(%")) %then
  %do;
    %put RTE%str(RROR): &sysmacroname: Badly-formed DOSETIMES. Double-quotes are not permitted;
    %tu_abort(option=force);
  %end;

  %let ptr = 1;
  %let phrase = %scan(&dosetimes,&ptr,%str([));
  %let len = %length(&phrase);
  %do %while (&len gt 0);

    %if &g_debug ge 1 %then
      %put PHRASE=&phrase LEN=&len;

    /* Remove the close-bracket at the end */
    %if %substr(&phrase,%length(&phrase)) ne %str(]) %then
    %do;
      %put RTE%str(RROR): &sysmacroname: Badly-formed DOSETIMES. Not bracket on end of: &phrase;
      %tu_abort(option=force);
    %end;
    %let phrase = %substr(&phrase,1,%length(&phrase)-1);

    /* Process the phrase */
    %let phraseType = %upcase(%scan(&phrase,1));
    %let phraseTimes = %substr(&phrase%str( )
                              ,%length(&phraseType)+1);

    %local timeptr thistime;

    %if &phraseType eq 1XAM %then
    %do;  /* once in the morning */
      %let time1xam = &phraseTimes;
      %if %length(%scan(&phraseTimes,2)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: Too many time values coded in DOSETIMES: PHRASE=[&phrase];
        %tu_abort(option=force);  /*AR3*/
      %end;
      %else %if %length(%scan(&phraseTimes,1)) eq 0 %then  /*AR3*/
      %do;
        %put RTE%str(RROR): &sysmacroname: Insufficient time values coded in DOSETIMES: PHRASE=[&phrase];
        %tu_abort(option=force);
      %end;
  	  /* Make sure that the times are valid numeric vars or constants */  /*AR4*/
  	  %do timeptr = 1 %to 1; 
  	    %let thistime = %scan(&phrasetimes,&timeptr);
  	    %if %index(&thistime,%str(%')) or %index(&thistime,%str(%")) %then
  	    %do;  /* Assume it is a time constant */
  	      %if %nrbquote(%upcase(%nrbquote(%substr(&thistime,%length(&thistime))))) ne T %then  
  	      %do;
  	        %put RTE%str(RROR): &sysmacroname.: One of the values specified for DOSETIME/&phrasetype (&thistime) is not a variable name nor a time constant;
  	        %tu_abort(option=force);
  	      %end;
  	    %end; /* Assume it is a time constant */
  	    %else
  	    %do;  /* Assume it is a variable name */
  	      %if %tu_chkvartype(&dsetin,&thistime) ne N %then
  	      %do;
  	        %put RTE%str(RROR): &sysmacroname.: There is no numeric variable named "&thistime" in DSETIN (&dsetin), despite it being included in DOSETIME/&phrasetype;
  	        %tu_abort(option=force);
  	      %end;
  	    %end; /* Assume it is a variable name */
  	  %end; /* do over timeptr */ 
    %end; /* once in the morning */

    %else %if &phraseType eq 2XAM %then
    %do;  /* twice in the morning */
      %let time2xam = &phraseTimes;
      %if %length(%scan(&phraseTimes,3)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: Too many time values coded in DOSETIMES: PHRASE=[&phrase];
        %tu_abort(option=force);  /*AR3*/
      %end;
      %else %if %length(%scan(&phraseTimes,2)) eq 0 %then  /*AR3*/
      %do;
        %put RTE%str(RROR): &sysmacroname: Insufficient time values coded in DOSETIMES: PHRASE=[&phrase];
        %tu_abort(option=force);
      %end;
  	  /* Make sure that the times are valid numeric vars or constants */  /*AR4*/
  	  %do timeptr = 1 %to 2; 
  	    %let thistime = %scan(&phrasetimes,&timeptr);
  	    %if %index(&thistime,%str(%')) or %index(&thistime,%str(%")) %then
  	    %do;  /* Assume it is a time constant */
  	      %if %nrbquote(%upcase(%nrbquote(%substr(&thistime,%length(&thistime))))) ne T %then  
  	      %do;
  	        %put RTE%str(RROR): &sysmacroname.: One of the values specified for DOSETIME/&phrasetype (&thistime) is not a variable name nor a time constant;
  	        %tu_abort(option=force);
  	      %end;
  	    %end; /* Assume it is a time constant */
  	    %else
  	    %do;  /* Assume it is a variable name */
  	      %if %tu_chkvartype(&dsetin,&thistime) ne N %then
  	      %do;
  	        %put RTE%str(RROR): &sysmacroname.: There is no numeric variable named "&thistime" in DSETIN (&dsetin), despite it being included in DOSETIME/&phrasetype;
  	        %tu_abort(option=force);
  	      %end;
  	    %end; /* Assume it is a variable name */
  	  %end; /* do over timeptr */ 
    %end; /* twice in the morning */

    %else %if &phraseType eq BID %then
    %do;  /* 2 x daily */
      %let timebid = &phraseTimes;
      %if %length(%scan(&phraseTimes,3)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: Too many time values coded in DOSETIMES: PHRASE=[&phrase];
        %tu_abort(option=force);  /*AR3*/
      %end;
      %else %if %length(%scan(&phraseTimes,2)) eq 0 %then  /*AR3*/
      %do;
        %put RTE%str(RROR): &sysmacroname: Insufficient time values coded in DOSETIMES: PHRASE=[&phrase];
        %tu_abort(option=force);
      %end;
  	  /* Make sure that the times are valid numeric vars or constants */  /*AR4*/
  	  %do timeptr = 1 %to 2; 
  	    %let thistime = %scan(&phrasetimes,&timeptr);
  	    %if %index(&thistime,%str(%')) or %index(&thistime,%str(%")) %then
  	    %do;  /* Assume it is a time constant */
  	      %if %nrbquote(%upcase(%nrbquote(%substr(&thistime,%length(&thistime))))) ne T %then  
  	      %do;
  	        %put RTE%str(RROR): &sysmacroname.: One of the values specified for DOSETIME/&phrasetype (&thistime) is not a variable name nor a time constant;
  	        %tu_abort(option=force);
  	      %end;
  	    %end; /* Assume it is a time constant */
  	    %else
  	    %do;  /* Assume it is a variable name */
  	      %if %tu_chkvartype(&dsetin,&thistime) ne N %then
  	      %do;
  	        %put RTE%str(RROR): &sysmacroname.: There is no numeric variable named "&thistime" in DSETIN (&dsetin), despite it being included in DOSETIME/&phrasetype;
  	        %tu_abort(option=force);
  	      %end;
  	    %end; /* Assume it is a variable name */
  	  %end; /* do over timeptr */ 
    %end; /* 2 x daily */

    %else %if &phraseType eq HS %then
    %do;  /* at bedtime */
      %let timehs = &phraseTimes;
      %if %length(%scan(&phraseTimes,2)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: Too many time values coded in DOSETIMES: PHRASE=[&phrase];
        %tu_abort(option=force);  /*AR3*/
      %end;
      %else %if %length(%scan(&phraseTimes,1)) eq 0 %then  /*AR3*/
      %do;
        %put RTE%str(RROR): &sysmacroname: Insufficient time values coded in DOSETIMES: PHRASE=[&phrase];
        %tu_abort(option=force);
      %end;
  	  /* Make sure that the times are valid numeric vars or constants */  /*AR4*/
  	  %do timeptr = 1 %to 1; 
  	    %let thistime = %scan(&phrasetimes,&timeptr);
  	    %if %index(&thistime,%str(%')) or %index(&thistime,%str(%")) %then
  	    %do;  /* Assume it is a time constant */
  	      %if %nrbquote(%upcase(%nrbquote(%substr(&thistime,%length(&thistime))))) ne T %then  
  	      %do;
  	        %put RTE%str(RROR): &sysmacroname.: One of the values specified for DOSETIME/&phrasetype (&thistime) is not a variable name nor a time constant;
  	        %tu_abort(option=force);
  	      %end;
  	    %end; /* Assume it is a time constant */
  	    %else
  	    %do;  /* Assume it is a variable name */
  	      %if %tu_chkvartype(&dsetin,&thistime) ne N %then
  	      %do;
  	        %put RTE%str(RROR): &sysmacroname.: There is no numeric variable named "&thistime" in DSETIN (&dsetin), despite it being included in DOSETIME/&phrasetype;
  	        %tu_abort(option=force);
  	      %end;
  	    %end; /* Assume it is a variable name */
  	  %end; /* do over timeptr */ 
    %end; /* at bedtime */

    %else %if &phraseType eq OD %then
    %do;  /* 1 x daily */
      %let timeod = &phraseTimes;
      %if %length(%scan(&phraseTimes,2)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: Too many time values coded in DOSETIMES: PHRASE=[&phrase];
        %tu_abort(option=force);  /*AR3*/
      %end;
      %else %if %length(%scan(&phraseTimes,1)) eq 0 %then  /*AR3*/
      %do;
        %put RTE%str(RROR): &sysmacroname: Insufficient time values coded in DOSETIMES: PHRASE=[&phrase];
        %tu_abort(option=force);
      %end;
  	  /* Make sure that the times are valid numeric vars or constants */  /*AR4*/
  	  %do timeptr = 1 %to 1; 
  	    %let thistime = %scan(&phrasetimes,&timeptr);
  	    %if %index(&thistime,%str(%')) or %index(&thistime,%str(%")) %then
  	    %do;  /* Assume it is a time constant */
  	      %if %nrbquote(%upcase(%nrbquote(%substr(&thistime,%length(&thistime))))) ne T %then  
  	      %do;
  	        %put RTE%str(RROR): &sysmacroname.: One of the values specified for DOSETIME/&phrasetype (&thistime) is not a variable name nor a time constant;
  	        %tu_abort(option=force);
  	      %end;
  	    %end; /* Assume it is a time constant */
  	    %else
  	    %do;  /* Assume it is a variable name */
  	      %if %tu_chkvartype(&dsetin,&thistime) ne N %then
  	      %do;
  	        %put RTE%str(RROR): &sysmacroname.: There is no numeric variable named "&thistime" in DSETIN (&dsetin), despite it being included in DOSETIME/&phrasetype;
  	        %tu_abort(option=force);
  	      %end;
  	    %end; /* Assume it is a variable name */
  	  %end; /* do over timeptr */ 
    %end; /* 1 x daily */

    %else %if &phraseType eq QAM %then
    %do;  /* every morning */
      %let timeqam = &phraseTimes;
      %if %length(%scan(&phraseTimes,2)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: Too many time values coded in DOSETIMES: PHRASE=[&phrase];
        %tu_abort(option=force);  /*AR3*/
      %end;
      %else %if %length(%scan(&phraseTimes,1)) eq 0 %then  /*AR3*/
      %do;
        %put RTE%str(RROR): &sysmacroname: Insufficient time values coded in DOSETIMES: PHRASE=[&phrase];
        %tu_abort(option=force);
      %end;
  	  /* Make sure that the times are valid numeric vars or constants */  /*AR4*/
  	  %do timeptr = 1 %to 1; 
  	    %let thistime = %scan(&phrasetimes,&timeptr);
  	    %if %index(&thistime,%str(%')) or %index(&thistime,%str(%")) %then
  	    %do;  /* Assume it is a time constant */
  	      %if %nrbquote(%upcase(%nrbquote(%substr(&thistime,%length(&thistime))))) ne T %then  
  	      %do;
  	        %put RTE%str(RROR): &sysmacroname.: One of the values specified for DOSETIME/&phrasetype (&thistime) is not a variable name nor a time constant;
  	        %tu_abort(option=force);
  	      %end;
  	    %end; /* Assume it is a time constant */
  	    %else
  	    %do;  /* Assume it is a variable name */
  	      %if %tu_chkvartype(&dsetin,&thistime) ne N %then
  	      %do;
  	        %put RTE%str(RROR): &sysmacroname.: There is no numeric variable named "&thistime" in DSETIN (&dsetin), despite it being included in DOSETIME/&phrasetype;
  	        %tu_abort(option=force);
  	      %end;
  	    %end; /* Assume it is a variable name */
  	  %end; /* do over timeptr */ 
    %end; /* every morning */

    %else %if &phraseType eq QD %then
    %do;  /* every day */
      %let timeqd = &phraseTimes;
      %if %length(%scan(&phraseTimes,2)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: Too many time values coded in DOSETIMES: PHRASE=[&phrase];
        %tu_abort(option=force);  /*AR3*/
      %end;
      %else %if %length(%scan(&phraseTimes,1)) eq 0 %then  /*AR3*/
      %do;
        %put RTE%str(RROR): &sysmacroname: Insufficient time values coded in DOSETIMES: PHRASE=[&phrase];
        %tu_abort(option=force);
      %end;
  	  /* Make sure that the times are valid numeric vars or constants */  /*AR4*/
  	  %do timeptr = 1 %to 1; 
  	    %let thistime = %scan(&phrasetimes,&timeptr);
  	    %if %index(&thistime,%str(%')) or %index(&thistime,%str(%")) %then
  	    %do;  /* Assume it is a time constant */
  	      %if %nrbquote(%upcase(%nrbquote(%substr(&thistime,%length(&thistime))))) ne T %then  
  	      %do;
  	        %put RTE%str(RROR): &sysmacroname.: One of the values specified for DOSETIME/&phrasetype (&thistime) is not a variable name nor a time constant;
  	        %tu_abort(option=force);
  	      %end;
  	    %end; /* Assume it is a time constant */
  	    %else
  	    %do;  /* Assume it is a variable name */
  	      %if %tu_chkvartype(&dsetin,&thistime) ne N %then
  	      %do;
  	        %put RTE%str(RROR): &sysmacroname.: There is no numeric variable named "&thistime" in DSETIN (&dsetin), despite it being included in DOSETIME/&phrasetype;
  	        %tu_abort(option=force);
  	      %end;
  	    %end; /* Assume it is a variable name */
  	  %end; /* do over timeptr */ 
    %end; /* every day */

    %else %if &phraseType eq QID %then
    %do;  /* 4 x daily */
      %let timeqid = &phraseTimes;
      %if %length(%scan(&phraseTimes,5)) ne 0 %then  /*AR3*/
      %do;
        %put RTE%str(RROR): &sysmacroname: Too many time values coded in DOSETIMES: PHRASE=[&phrase];
        %tu_abort(option=force);  /*AR3*/
      %end;
      %else %if %length(%scan(&phraseTimes,4)) eq 0 %then  /*AR3*/
      %do;
        %put RTE%str(RROR): &sysmacroname: Insufficient time values coded in DOSETIMES: PHRASE=[&phrase];
        %tu_abort(option=force);
      %end;
  	  /* Make sure that the times are valid numeric vars or constants */  /*AR4*/
  	  %do timeptr = 1 %to 4; 
  	    %let thistime = %scan(&phrasetimes,&timeptr);
  	    %if %index(&thistime,%str(%')) or %index(&thistime,%str(%")) %then
  	    %do;  /* Assume it is a time constant */
  	      %if %nrbquote(%upcase(%nrbquote(%substr(&thistime,%length(&thistime))))) ne T %then  
  	      %do;
  	        %put RTE%str(RROR): &sysmacroname.: One of the values specified for DOSETIME/&phrasetype (&thistime) is not a variable name nor a time constant;
  	        %tu_abort(option=force);
  	      %end;
  	    %end; /* Assume it is a time constant */
  	    %else
  	    %do;  /* Assume it is a variable name */
  	      %if %tu_chkvartype(&dsetin,&thistime) ne N %then
  	      %do;
  	        %put RTE%str(RROR): &sysmacroname.: There is no numeric variable named "&thistime" in DSETIN (&dsetin), despite it being included in DOSETIME/&phrasetype;
  	        %tu_abort(option=force);
  	      %end;
  	    %end; /* Assume it is a variable name */
  	  %end; /* do over timeptr */ 
    %end; /* 4 x daily */

    %else %if &phraseType eq QOD %then
    %do;  /* every other day */
      %let timeqod = &phraseTimes;
      %if %length(%scan(&phraseTimes,2)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: Too many time values coded in DOSETIMES: PHRASE=[&phrase];
        %tu_abort(option=force);  /*AR3*/
      %end;
      %else %if %length(%scan(&phraseTimes,1)) eq 0 %then  /*AR3*/
      %do;
        %put RTE%str(RROR): &sysmacroname: Insufficient time values coded in DOSETIMES: PHRASE=[&phrase];
        %tu_abort(option=force);
      %end;
  	  /* Make sure that the times are valid numeric vars or constants */  /*AR4*/
  	  %do timeptr = 1 %to 1; 
  	    %let thistime = %scan(&phrasetimes,&timeptr);
  	    %if %index(&thistime,%str(%')) or %index(&thistime,%str(%")) %then
  	    %do;  /* Assume it is a time constant */
  	      %if %nrbquote(%upcase(%nrbquote(%substr(&thistime,%length(&thistime))))) ne T %then  
  	      %do;
  	        %put RTE%str(RROR): &sysmacroname.: One of the values specified for DOSETIME/&phrasetype (&thistime) is not a variable name nor a time constant;
  	        %tu_abort(option=force);
  	      %end;
  	    %end; /* Assume it is a time constant */
  	    %else
  	    %do;  /* Assume it is a variable name */
  	      %if %tu_chkvartype(&dsetin,&thistime) ne N %then
  	      %do;
  	        %put RTE%str(RROR): &sysmacroname.: There is no numeric variable named "&thistime" in DSETIN (&dsetin), despite it being included in DOSETIME/&phrasetype;
  	        %tu_abort(option=force);
  	      %end;
  	    %end; /* Assume it is a variable name */
  	  %end; /* do over timeptr */ 
    %end; /* every other day */

    %else %if &phraseType eq TID %then
    %do;  /* 3 x daily */
      %let timetid = &phraseTimes;
      %if %length(%scan(&phraseTimes,4)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: Too many time values coded in DOSETIMES: PHRASE=[&phrase];
        %tu_abort(option=force);  /*AR3*/
      %end;
      %else %if %length(%scan(&phraseTimes,3)) eq 0 %then  /*AR3*/
      %do;
        %put RTE%str(RROR): &sysmacroname: Insufficient time values coded in DOSETIMES: PHRASE=[&phrase];
        %tu_abort(option=force);
      %end;
  	  /* Make sure that the times are valid numeric vars or constants */  /*AR4*/
  	  %do timeptr = 1 %to 3; 
  	    %let thistime = %scan(&phrasetimes,&timeptr);
  	    %if %index(&thistime,%str(%')) or %index(&thistime,%str(%")) %then
  	    %do;  /* Assume it is a time constant */
  	      %if %nrbquote(%upcase(%nrbquote(%substr(&thistime,%length(&thistime))))) ne T %then  
  	      %do;
  	        %put RTE%str(RROR): &sysmacroname.: One of the values specified for DOSETIME/&phrasetype (&thistime) is not a variable name nor a time constant;
  	        %tu_abort(option=force);
  	      %end;
  	    %end; /* Assume it is a time constant */
  	    %else
  	    %do;  /* Assume it is a variable name */
  	      %if %tu_chkvartype(&dsetin,&thistime) ne N %then
  	      %do;
  	        %put RTE%str(RROR): &sysmacroname.: There is no numeric variable named "&thistime" in DSETIN (&dsetin), despite it being included in DOSETIME/&phrasetype;
  	        %tu_abort(option=force);
  	      %end;
  	    %end; /* Assume it is a variable name */
  	  %end; /* do over timeptr */ 
    %end; /* 3 x daily */

    %else %if &phraseType eq PRN %then  /*AR3*/
    %do;
      %put RTE%str(RROR): &sysmacroname: DOSETIMES includes values for PRN. These are not permitted;
      %tu_abort(option=force);
    %end;

    %else
    %do;
      %put RTE%str(RROR): &sysmacroname: DOSETIMES includes unknown code: &phraseType;
      %tu_abort(option=force);
    %end;

    /* Get next phrase */
    %let ptr = %eval(&ptr+1);
    %let phrase = %scan(&dosetimes,&ptr,%str([));
    %let len = %length(&phrase);

  %end;

  %if &g_debug ge 1 %then
  %do;  /*AR9*/
    %put RTD%str(EBUG): &sysmacroname: time1xam=&time1xam, time2xam=&time2xam, timebid=&timebid;
    %put RTD%str(EBUG): &sysmacroname: timehs=&timehs, timeod=&timeod, timeqam=&timeqam;
    %put RTD%str(EBUG): &sysmacroname: timeqd=&timeqd, timeqid=&timeqid, timeqod=&timeqod, timetid=&timetid;
  %end;  /*AR9*/

  /* 2. Check for missing doses (non-placebo) */
  data _null_;
    set &dsetin end=finish;
    %tu_xcpsectioninit(header=Check for missing doses for non-placebo);
    if not (&placebo) and dose eq . then
    do;
      %tu_byid(dsetin=&dsetinNoOptions
              ,invars=&by exstdt 
              ,outvar=__msg
              );
      %tu_xcpput('Missing DOSE for non-placebo row: ' !! __msg
                ,error
                );
    end;
    %tu_xcpsectionterm(end=finish)
  run;

  /* 3. What can we keep? (DOSEUNIT/DOSEUCD) */  /*AR7*/
  %local keep;
  proc contents data=&dsetin noprint out=work.&prefix._cont;
  run;

  data _null_;
    set work.&prefix._cont;
    where upcase(name) in ('DOSEUNIT' 'DOSEUCD');
    retain keep ;
    length keep $17;
    keep = compress(keep) !! ' ' !! name;
    call symput('KEEP',keep);
  run;
  %if &g_debug ge 1 %then
    %put RTD%str(EBUG): &sysmacroname: KEEP=&keep;

  /* 4. Go do it */
  data &dsetout;
    set &dsetin end=finish;
    keep &by exstdt exsttm dose &keep;  /*AR2*/  /*AR7*/
    format exstdm datetime.
           exsttm time.
           exstdt date.;
    %if %length(&exentm) ne 0 %then  /*AR6*/
    %do;
      format exendm datetime.
             exentm time.
             exendt date.;
    %end;

    %tu_byid(dsetin=&dsetinNoOptions
            ,invars=&by exstdt 
            ,outvar=__msg
            );

    skipRow = 0;
    %if %length(&exentm) ne 0 %then  /*AR6*/
    %do;
      if dosefrcd ne '' then
      do;  /* Make sure we have the end of our date range */
        if exendt eq . then
        do;
          put "RTE" "RROR: &sysmacroname: Missing end date value (EXENDT) for DOSEFRCD=" dosefrcd __msg;
          call symput('G_ABORT','1');
          skipRow = 1;
        end;
        if &exentm eq . then  /*AR6*/
        do;
          put "RTE" "RROR: &sysmacroname: Missing end time value (&exentm) for DOSEFRCD=" dosefrcd __msg;
          call symput('G_ABORT','1');
          skipRow = 1;
        end;
        exentm = &exentm;  /*AR6*/
        exendm = dhms(exendt,hour(exentm),minute(exentm),second(exentm));
      end; /* Make sure we have the end of our date range */
    %end;

    if not skipRow then
    do;  /* Row was validated cleanly */
      select (upcase(dosefrcd));

        when ('') 
        do;
          exsttm = &exsttm;
          exstdm = dhms(exstdt,hour(exsttm),minute(exsttm),second(exsttm));
          OUTPUT;
        end;

        %if %length(&time1xam) gt 0 %then
        %do;
          when ('1XAM')
          do;  /* once in the morning */
            dayInterval = 1;
            do until (exstdm gt exendm);
              exsttm = %scan(&time1xam,1);
              exstdm = dhms(exstdt,hour(exsttm),minute(exsttm),second(exsttm));
              OUTPUT;
              exstdt = intnx('DAY',exstdt,dayInterval);
              exstdm = intnx('dtSECOND',exstdm,dayInterval*24*60*60);
            end; /* do until start gt end */
          end; /* once in the morning */
        %end;

        %if %length(&time2xam) gt 0 %then
        %do;
          when ('2XAM')
          do;  /* twice in the morning */
            dayInterval = 1;
			      sttm1 = %scan(&time2xam,1);  /*AR4*/
			      sttm2 = %scan(&time2xam,2);  /*AR4*/
            do until (exstdm gt exendm);
              exsttm = sttm1;  /*AR4*/
              exstdm = dhms(exstdt,hour(exsttm),minute(exsttm),second(exsttm));
              OUTPUT;
              exsttm = sttm2;  /*AR4*/
              exstdm = dhms(exstdt,hour(exsttm),minute(exsttm),second(exsttm));
              OUTPUT;
              exstdt = intnx('DAY',exstdt,dayInterval);
              exstdm = intnx('dtSECOND',exstdm,dayInterval*24*60*60);
            end; /* do until start gt end */
          end; /* twice in the morning */
        %end;

        %if %length(&timebid) gt 0 %then
        %do;
          when ('BID')
          do;  /* 2 x daily */
            dayInterval = 1;
			      sttm1 = %scan(&timebid,1);  /*AR4*/
			      sttm2 = %scan(&timebid,2);  /*AR4*/
            do until (exstdm gt exendm);
              exsttm = sttm1;  /*AR4*/
              exstdm = dhms(exstdt,hour(exsttm),minute(exsttm),second(exsttm));
              OUTPUT;
              exsttm = sttm2;  /*AR4*/
              exstdm = dhms(exstdt,hour(exsttm),minute(exsttm),second(exsttm));
              OUTPUT;
              exstdt = intnx('DAY',exstdt,dayInterval);
              exstdm = intnx('dtSECOND',exstdm,dayInterval*24*60*60);
            end; /* do until start gt end */
          end; /* 2 x daily */
        %end;

        %if %length(&timehs) gt 0 %then
        %do;
          when ('HS')
          do;  /* at bedtime */
            dayInterval = 1;
            do until (exstdm gt exendm);
              exsttm = %scan(&timehs,1);
              exstdm = dhms(exstdt,hour(exsttm),minute(exsttm),second(exsttm));
              OUTPUT;
              exstdt = intnx('DAY',exstdt,dayInterval);
              exstdm = intnx('dtSECOND',exstdm,dayInterval*24*60*60);
            end; /* do until start gt end */
          end; /* at bedtime */
        %end;

        %if %length(&timeod) gt 0 %then
        %do;
          when ('OD')
          do;  /* 1 x daily */
            dayInterval = 1;
            do until (exstdm gt exendm);
              exsttm = %scan(&timeod,1);
              exstdm = dhms(exstdt,hour(exsttm),minute(exsttm),second(exsttm));
              OUTPUT;
              exstdt = intnx('DAY',exstdt,dayInterval);
              exstdm = intnx('dtSECOND',exstdm,dayInterval*24*60*60);
            end; /* do until start gt end */
          end; /* 1 x daily */
        %end;

        %if %length(&timeqam) gt 0 %then
        %do;
          when ('QAM')
          do;  /* Every morning */
            dayInterval = 1;
            do until (exstdm gt exendm);
              exsttm = %scan(&timeqam,1);
              exstdm = dhms(exstdt,hour(exsttm),minute(exsttm),second(exsttm));
              OUTPUT;
              exstdt = intnx('DAY',exstdt,dayInterval);
              exstdm = intnx('dtSECOND',exstdm,dayInterval*24*60*60);
            end; /* do until start gt end */
          end; /* Every morning */
        %end;

        %if %length(&timeqd) gt 0 %then
        %do;
          when ('QD')
          do;  /* every day */
            dayInterval = 1;
            do until (exstdm gt exendm);
              exsttm = %scan(&timeqd,1);
              exstdm = dhms(exstdt,hour(exsttm),minute(exsttm),second(exsttm));
              OUTPUT;
              exstdt = intnx('DAY',exstdt,dayInterval);
              exstdm = intnx('dtSECOND',exstdm,dayInterval*24*60*60);
            end; /* do until start gt end */
          end; /* every day */
        %end;

        %if %length(&timeqid) gt 0 %then
        %do;
          when ('QID')
          do;  /* 4 x daily */
            dayInterval = 1;
      			sttm1 = %scan(&timeqid,1);  /*AR4*/
			      sttm2 = %scan(&timeqid,2);  /*AR4*/
			      sttm3 = %scan(&timeqid,3);  /*AR4*/
			      sttm4 = %scan(&timeqid,4);  /*AR4*/
            do until (exstdm gt exendm);
              exsttm = sttm1;  /*AR4*/
              exstdm = dhms(exstdt,hour(exsttm),minute(exsttm),second(exsttm));
              OUTPUT;
              exsttm = sttm2;  /*AR4*/
              exstdm = dhms(exstdt,hour(exsttm),minute(exsttm),second(exsttm));
              OUTPUT;
              exsttm = sttm3;  /*AR4*/
              exstdm = dhms(exstdt,hour(exsttm),minute(exsttm),second(exsttm));
              OUTPUT;
              exsttm = sttm4;  /*AR4*/
              exstdm = dhms(exstdt,hour(exsttm),minute(exsttm),second(exsttm));
              OUTPUT;
              exstdt = intnx('DAY',exstdt,dayInterval);
              exstdm = intnx('dtSECOND',exstdm,dayInterval*24*60*60);
            end; /* do until start gt end */
          end; /* 4 x daily */
        %end;

        %if %length(&timeqod) gt 0 %then
        %do;
          when ('QOD')
          do;  /* every other day */
            dayInterval = 2;
            do until (exstdm gt exendm);
              exsttm = %scan(&timeqod,1);
              exstdm = dhms(exstdt,hour(exsttm),minute(exsttm),second(exsttm));
              OUTPUT;
              exstdt = intnx('DAY',exstdt,dayInterval);
              exstdm = intnx('dtSECOND',exstdm,dayInterval*24*60*60);
            end; /* do until start gt end */
          end; /* every other day */
        %end;

        %if %length(&timetid) gt 0 %then
        %do;
          when ('TID')
          do;  /* 3 x daily */
            dayInterval = 1;
            sttm1 = %scan(&timetid,1);  /*AR4*/
            sttm2 = %scan(&timetid,2);  /*AR4*/
            sttm3 = %scan(&timetid,3);  /*AR4*/
            do until (exstdm gt exendm);
              exsttm = sttm1;  /*AR4*/
              exstdm = dhms(exstdt,hour(exsttm),minute(exsttm),second(exsttm));
              OUTPUT;
              exsttm = sttm2;  /*AR4*/
              exstdm = dhms(exstdt,hour(exsttm),minute(exsttm),second(exsttm));
              OUTPUT;
              exsttm = sttm3;  /*AR4*/
              exstdm = dhms(exstdt,hour(exsttm),minute(exsttm),second(exsttm));
              OUTPUT;
              exstdt = intnx('DAY',exstdt,dayInterval);
              exstdm = intnx('dtSECOND',exstdm,dayInterval*24*60*60);
            end; /* do until start gt end */
          end; /* 3 x daily */
        %end;

        when ('PRN')
        do;  /* as required */
          put "RTE" "RROR: &sysmacroname: Dose code PRN ('as required') is not supported: " __msg;
          call symput('G_ABORT','1');
        end; /* as required */

        otherwise
        do;
          put "RTE" "RROR: &sysmacroname: Dose frequency code not listed in DOSETIMES parameter: " dosefrcd= __msg;
          call symput('G_ABORT','1');
        end;

      end; /* select dosefrcd */
    end; /* Row was validated cleanly */

  run;
  %tu_abort;

  /* Finish-off */
  %tu_tidyup(rmdset=&prefix:
            ,glbmac=NONE
            );
  quit;

  %tu_abort;

%mend tu_nmexpoexpand;
