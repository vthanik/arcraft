/******************************************************************************* 
|
| Macro Name:      tu_timeshift.sas
|
| Macro Version:   1.0
|
| SAS Version:     8.2
|
| Created By:      Andrew Ratcliffe, RTSL, www.ratcliffe.co.uk
|
| Date:            19-Jun-2005
|
| Macro Purpose:   To add a relative time column to the input dataset.
|                  EVID=3 shall optionally be used for cross-over studies 
|                  (and shall not be used for parallel group studies). For 
|                  cross-over studies where the PERIODRESET option is chosen, 
|                  an EVID=3 record shall be inserted as the first row for 
|                  each new period. It shall be followed by that period's 
|                  data, with time reset back to zero. For the EVID=3 row, 
|                  time shall be set to zero; the other variables in the row 
|                  shall be filled by using the same rules as for missing 
|                  values. 
|
| Macro Design:    PROCEDURE STYLE MACRO
| 
| Input Parameters:
|
| NAME              DESCRIPTION                         DEFAULT 
| DATE              Specifies the name of the SAS       [blank] (Req)
|                   date column in the input dataset
|
| DSETIN            Specifies the name of the input     [blank] (Req)
|                   dataset
|
| DSETOUT           Specifies the name of the output    [blank] (Req)
|                   dataset
|
| PERIODRESET       Specifies that the relative time    N (req)
|                   should be reset to zero at each 
|                   new value of PERNUM (as opposed to subject ID). If PERIODRESET 
|                   is set to Y, evid=3 records shall also be inserted at each 
|                   new PERNUM value
|
| PREDTIME          Specifies how to handle relative    allzero (Req)
|                   times for pre-dose values
|
| SORTBY            Specifies the sort order of the     [blank] (req)
|                   output dataset
|
| TIME              Specifies the name of the SAS       [blank] (Req)
|                   time column in the input dataset
|
| TIMEVAR           Specifies the name to be used for   time (Req)
|                   the relative time column in the 
|                   output file
|
| Output: This macro produces a copy of the input dataset, with the 
|         addition of the relative time column
|
| Global macro variables created:  None
|
| Macros called:
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_chknames
| (@) tu_chkvarsexist
| (@) tu_tidyup
| (@) tu_abort
|
| Example:
|
| %tu_nmtimeshift(date = date
|                ,dsetin = work.alpha
|                ,dsetout = work.beta
|                ,predtime = onezero
|                ,time = tim2
|                ,timevar = time
|                );
|
|******************************************************************************* 
| Change Log 
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     05-Jul-2005
| New version number:       1/2
| Modification ID:          
| Reason For Modification:  Add provision for PERIODRESET (new parms: SORTBY and PERIODRESET).
|                           Finish-off the list of sub-macros.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     29-Jul-2005
| New version number:       1/3
| Modification ID:          
| Reason For Modification:  Add text re: PERIODRESET to Purpose.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     07-Sep-2005
| New version number:       1/4
| Modification ID:          AR4
| Reason For Modification:  Fix: Use upper case when validating RESETON/SORTBY.
|                           Fix: Typo in PERIODRESET validation message.
|                           Fix: Reduce the scope of ISPREDOSE and GOTFIRSTDOSE.
|
| Modified By:              
| Date of Modification:     
| New version number:       
| Modification ID:          
| Reason For Modification:  
|
********************************************************************************/ 

%macro tu_nmtimeshift(date        =         /* Name of date column */
                     ,dsetin      =         /* type:ID Name of input dataset */
                     ,dsetout     =         /* Output dataset */
                     ,predtime    = allzero /* How to handle relative times for pre-dose values */
                     ,time        =         /* Name of time column */
                     ,timevar     = time    /* Name of relative time column in output file */
                     ,sortby      =         /* Sort order of data */
                     ,periodreset = N       /* Should relative time be reset upon PERNUM */
                     );

  /* Echo parameter values and global macro variables to the log */
 
  %local MacroVersion;
  %let MacroVersion = 1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=);

  %local prefix;
  %let prefix = %substr(&sysmacroname,3); 

  %let predtime = %upcase(&predtime);

  /* PARAMETER VALIDATION */
  %let sortby = %upcase(&sortby);
  %let periodreset = %upcase(&periodreset);

  /* Validate - DSETIN */
  %if %length(&dsetin) eq 0 %then 
  %do;
    %put RTE%str(RROR): &sysmacroname.: A value must be supplied for DSETIN;
    %let g_abort=1;
  %end;
  %else
  %do;
    %if not %sysfunc(exist(&dsetin)) %then 
    %do;
      %put RTE%str(RROR): &sysmacroname.: The DSETIN dataset (&dsetin) does not exist;
      %let g_abort=1;
    %end;
  %end;

  /* Validate - DSETOUT */
  %if %length(%tu_chknames(&dsetout,DATA)) gt 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: The value supplied for DSETOUT (&dsetout) is not a valid dataset name;
    %let g_abort=1;
  %end;

  /* Validate - DATE */
  %if %length(&date) eq 0 or %length(%tu_chkvarsexist(&dsetin,&date)) ne 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: The variable supplied for DATE (&date) does not exist in DSETIN (&dsetin);
    %let g_abort=1;
  %end;

  /* Validate - TIME */
  %if %length(&time) eq 0 or %length(%tu_chkvarsexist(&dsetin,&time)) ne 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: The variable supplied for TIME (&time) does not exist in DSETIN (&dsetin);
    %let g_abort=1;
  %end;

  /* Validate - TIMEVAR */
  %if %length(%tu_chknames(&timevar,VARIABLE)) gt 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: The value supplied for TIMEVAR (&timevar) is not a valid variable name;
    %let g_abort=1;
  %end;

  /* Validate - PREDTIME */
  %if &predtime ne ALLZERO and &predtime ne ONEZERO %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: Invalid value supplied for PREDTIME (&predtime). It must be ONEZERO or ALLZERO;
    %let g_abort=1;
  %end;

  /* Validate - SORTBY */
  %if %length(&sortby) eq 0 %then 
  %do;
    %put RTE%str(RROR): &sysmacroname.: SORTBY must not be blank;
    %let g_abort=1;
  %end;
  %else %if %length(%tu_chkvarsexist(&dsetin,&sortby)) gt 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: One or more of the specified SORTBY variables do not exist in DSETIN (&dsetin);
    %let g_abort=1;
  %end;

  /* Validate - PERIODRESET */
  %if %str(&periodReset) ne Y and %str(&periodReset) ne N %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: Invalid value supplied for PERIODRESET (&periodreset). It must be Y or N;  /*AR4*/
    %let g_abort=1;
  %end;

  %tu_abort;

  /* NORMAL PROCESSING */

  %local currentDataset;
  %let currentDataset = &dsetin;

  %local resetOn;
  %if &periodReset eq N %then
    %let resetOn = %upcase(&g_subjid);  /*AR4*/
  %else
    %let resetOn = PERNUM;  /*AR4*/

  %local sortReset pos;
  %let pos = %index(&sortby,&resetOn);
  %if &pos eq 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname: Unexpected logic error: could not find RESETON (&resetOn) within SORTBY (&sortby);
    %tu_abort(option=force);
  %end;
  %let sortReset = %substr(&sortby,1,&pos+%length(&resetOn)-1);
  %if &g_debug ge 1 %then
    %put RTD%str(EBUG): &sysmacroname: SORTRESET=&sortReset;

  proc sort data=&currentDataset out=work.&prefix._sort;
    by &sortby;
  run;

  data work.&prefix._shifted;
    set work.&prefix._sort;
    by &sortReset;
    retain DatetimeZero;  /*AR4*/
    drop DatetimeZero;  /*AR4*/

    %if &predtime eq ALLZERO %then
    %do;  /* allzero */

      retain IsPredose GotFirstDose;  /*AR4*/
      drop IsPredose GotFirstDose;  /*AR4*/

      if first.&resetOn then 
      do;
        IsPredose = 1;
        GotFirstDose = 0;
      end;

      if evid eq 1 and not GotFirstDose then
      do;
        IsPredose = 0;
        DatetimeZero = dhms(&date,0,0,&time);
        GotFirstDose = 1;
      end;
      
      if IsPredose then 
        &timevar = 0;
      else 
        &timevar = (dhms(&date,0,0,&time) - DatetimeZero) / 3600;

    %end; /* allzero */

    %else
    %do;  /* onezero */

      if first.&resetOn then DatetimeZero = dhms(&date,0,0,&time);
     
      &timevar = (dhms(&date,0,0,&time) - DatetimeZero) / 3600;

    %end; /* onezero */

  run;

  %if &periodReset eq N %then
  %do;  /* Do not add evid=3 */
    data &dsetout;
      set work.&prefix._shifted;
    run;
  %end; /* Do not add evid=3 */

  %else
  %do;  /* Add evid=3 at each new pernum */
    proc summary data=work.&prefix._shifted nway;
      class &sortReset;
      output out=work.&prefix._evid3a (drop=_type_ _freq_);
    run;

    data work.&prefix._evid3b;
      set work.&prefix._evid3a;
      evid=3;
    run;

    data &dsetout;
      set work.&prefix._evid3b
            work.&prefix._shifted
            ;
      by &sortReset;
    run;
  %end; /* Add evid=3 at each new pernum */

  /* Finish-off */
  %tu_tidyup(rmdset=&prefix:
            ,glbmac=NONE
            );
  quit;

  %tu_abort;

%mend tu_nmtimeshift;
