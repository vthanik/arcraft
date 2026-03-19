/******************************************************************************* 
|
| Macro Name:      tu_nmimpcv.sas
|
| Macro Version:   1.0
|
| SAS Version:     8.2
|
| Created By:      Andrew Ratcliffe, RTSL, www.ratcliffe.co.uk
|
| Date:            19-Jun-2005
|
| Macro Purpose:   To impute missing values for a specified covariate variable. If 
|                  a covariate value is missing in the input data, this macro 
|                  shall impute a value using the following rules: to replace a 
|                  missing value: 
|                  - scan backwards through the subject's data to find the most 
|                    recent nonmissing value
|                  - if no previous non-missing value can be found, scan 
|                    forwards through the subject's data to find the soonest 
|                    non-missing value
|                  - if all values for the subject are missing, take the mean 
|                    of the mean of all subjects
|                  In each case where a value is substituted for a missing value, 
|                  a warning shall be written to the reconciliation report.
|
| Macro Design:    PROCEDURE STYLE MACRO
| 
| Input Parameters:
|
| NAME              DESCRIPTION                         DEFAULT 
| BNDRYVAR          Specifies the scope of imputations, &g_subjid (Req)
|                   i.e. over what range the macro will 
|                   look for earlier/later non-missing values
|
| CVVAR             Specifies the name of the variable  [blank] (Req)
|                   whose missing values are to be 
|                   imputed
|
| DSETIN            Specifies the name of the input     [blank] (Req)
|                   dataset
|
| DSETOUT           Specifies the name of the output    [blank] (Req)
|                   dataset to be created
|
| SORTBY            Specifies the variables by which    [blank] (Req)
|                   the input data shall be sorted 
|                   before searching for earlier/later values 
|
| Output: This macro replaces missing values (for the specified variable) with imputed values.
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
| (@) tu_sqlnlist
| (@) tu_tidyup
| (@) tu_words
| (@) tu_xcpsectioninit
| (@) tu_xcpput
| (@) tu_xcpsectionterm
|
| Example:
|
| %tu_nmimpcv(cvvar = pcorresn
|            ,dsetin = work.cv
|            ,dsetout = work.cvimp 
|            ,sortby = &g_subjid visitnum date tim2
|            );
|
|******************************************************************************* 
| Change Log 
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     05-Jul-2005
| New version number:       1/2
| Modification ID:          AR1
| Reason For Modification:  Make corrections to sort orders for 1st and 2nd phases.
|                           Finish-off the list of sub-macros.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     11-Aug-2005
| New version number:       1/3
| Modification ID:          AR3
| Reason For Modification:  Add extra BNDRYVAR validation: must be just one word.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     20-Sep-2005
| New version number:       1/4
| Modification ID:          AR4
| Reason For Modification:  Add LOCAL for macro variable I.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     21-Sep-2005
| New version number:       1/5
| Modification ID:          AR5
| Reason For Modification:  Add LOCAL for macro variables SORTBYn. This includes
|                           replacing tu_maclist with tu_words.
|                           Fix: Mean-of-mean of subjects, not boundary var.
|
| Modified By:              
| Date of Modification:     
| New version number:       
| Modification ID:          
| Reason For Modification:  
|
********************************************************************************/ 

%macro tu_nmimpcv(bndryvar = &g_subjid /* Scope of imputations */
                 ,cvvar    =           /* Name of covariate variable */
                 ,dsetin   =           /* type:ID Name of input dataset */
                 ,dsetout  =           /* Name of the output dataset */
                 ,sortby   =           /* Variables by which the input data shall be sorted before searching for earlier/later values */
                 );

  /* Echo parameter values and global macro variables to the log */
  %local MacroVersion;
  %let MacroVersion = 1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals();

  /*
  / Add cvvar to macro name in prefix because macro is likely to be called several 
  / times and we would like to keep all dataset names unique (avoid overwriting 
  / datasets)
  ********************************************************************************/ 
  %local prefix;
  %let prefix = %substr(&sysmacroname,3)_&cvvar; 

  /* PARAMETER VALIDATION */

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

  /* Validate - CVVAR */
  %if %length(&cvvar) eq 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: A value for CVVAR must be specified;
    %let g_abort=1;
  %end;
  %else 
  %do;
    %if %length(%tu_chkvarsexist(&dsetin,&cvvar)) ne 0 %then
    %do;
      %put RTE%str(RROR): &sysmacroname.: The CVVAR variable (&cvvar) does not exist in DSETIN;
      %let g_abort=1;
    %end;
  %end;

  /* Validate - BNDRYVAR */
  %if %length(&bndryvar) eq 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: A value for BNDRYVAR must be specified;
    %let g_abort=1;
  %end;
  %else 
  %do;
    %if %length(%scan(&bndryvar,2)) gt 0 %then  /*AR3*/
    %do;
      %put RTE%str(RROR): &sysmacroname.: The BNDRYVAR variable (&bndryvar) must be one name only;
      %let g_abort=1;
    %end;
    %else
    %do;
      %if %length(%tu_chkvarsexist(&dsetin,&bndryvar)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname.: The BNDRYVAR variable (&bndryvar) does not exist in DSETIN;
        %let g_abort=1;
      %end;
    %end;
  %end;

  /* Validate - SORTBY */
  %if %length(&sortby) eq 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: A value for SORTBY must be specified;
    %let g_abort=1;
  %end;
  %else 
  %do;
    %if %length(%tu_chkvarsexist(&dsetin,&sortby)) ne 0 %then
    %do;
      %put RTE%str(RROR): &sysmacroname.: One or more of the variables in SORTBY (&sortby) does not exist in DSETIN;
      %let g_abort=1;
    %end;
  %end;

  %tu_abort;

  /* NORMAL PROCESSING */
  %local currentDataset idx;

  /* 
  / PLAN OF ACTION
  / 1. Establish what kind of missing value we are looking for (char or num, " " or .)
  / 2. Fill-in gaps by going back to most recent
  / 3. Fill-in remaining gaps by going forward to soonest 
  / 4. For those with nothing fwd or bkwd, use mean of mean (unless char)
  / 5. Create result dataset 
  / 6. Check the resulting dataset for remaining missings
  /------------------------------------------------------*/

  /* 1. Establish what kind of missing value we are looking for  (char or num, " " or .) */
  %local cvvarType cvvarMissingValue;
  %let cvvarType = %tu_chkvartype(&dsetin,&cvvar);
  %tu_abort;
  %if &cvvarType eq C %then
    %let cvvarMissingValue = '';
  %else
    %let cvvarMissingValue = .;

  /* 2. Fill-in gaps by going back to most recent */
  proc sort data=&dsetin out=work.&prefix._10s;  /*AR1*/
    by &sortby;
  run;

  data work.&prefix._10;
    set work.&prefix._10s end=finish;
    by &sortby;  /*AR1*/
    retain RecentForSubject;
    drop RecentForSubject __msg;
    %tu_xcpsectioninit(header=Backwards CV Imputations - %upcase(&cvvar));
    /* Get value in case we need it */
    if first.&bndryvar then 
    do;
      RecentForSubject=&cvvar;
    end;
    else
    do;
      if &cvvar ne &cvvarMissingValue then
        RecentForSubject=&cvvar;
    end;
    /* Use value if we need to */
    if &cvvar eq &cvvarMissingValue and RecentForSubject ne &cvvarMissingValue then
    do;
      &cvvar = RecentForSubject;
      %tu_byid(dsetin=work.&prefix._10s
              ,invars=&sortby ind &cvvar
              ,outvar=__msg
              );
      %tu_xcpput("Imputation done: " !! __msg
                ,warning
                );
    end;
    %tu_xcpsectionterm(end=finish);
  run;
  %tu_abort;
  %let currentdataset = work.&prefix._10;

  /* 3. Fill-in remaining gaps by going forward to soonest (so reverse the order of the dataset) */
  %local i sortby0;  /*AR4*/  /*AR5*/
  %let sortby0 = %tu_words(&sortby);
  %do i = 1 %to &sortby0;
    %local sortby&i;
    %let sortby&i = %scan(&sortby,&i);
  %end;

  proc sort data=&currentDataset out=work.&prefix._10RS;
    by %do i=1 %to &sortby0;
         DESCENDING &&sortby&i
       %end;
       ;
  run;

  data work.&prefix._20;
    set work.&prefix._10RS end=finish;
    by %do i=1 %to &sortby0;      /*AR1*/
         DESCENDING &&sortby&i
       %end;
       ;
    retain RecentForSubject;
    drop RecentForSubject __msg;
    %tu_xcpsectioninit(header=Forwards CV Imputations - %upcase(&cvvar));
    /* Get value in case we need it */
    if first.&bndryvar then 
    do;
      RecentForSubject=&cvvar;
    end;
    else
    do;
      if &cvvar ne &cvvarMissingValue then
        RecentForSubject=&cvvar;
    end;
    /* Use value if we need to */
    if &cvvar eq &cvvarMissingValue and RecentForSubject ne &cvvarMissingValue then
    do;
      &cvvar = RecentForSubject;
      %tu_byid(dsetin=work.&prefix._10RS
              ,invars=&sortby ind &cvvar
              ,outvar=__msg
              );
      %tu_xcpput("Imputation done: " !! __msg
                ,warning
                );
    end;
    %tu_xcpsectionterm(end=finish);
  run;
  %tu_abort;
  %let currentdataset = work.&prefix._20;

  /* 4. For those with nothing fwd or bkwd, use mean of mean of subjects (unless char) */
  %if &cvvarType eq N %then
  %do;  /* Use mean of mean for nums */
    proc summary data=&dsetin nway;
      class &g_subjid;  /*AR5*/
      var &cvvar;
      output out=work.&prefix._mean (drop=_type_ _freq_)
             mean=mean;
    run;

    proc summary data=work.&prefix._mean nway;
      class ;
      var mean;
      output out=work.&prefix._meanmean (drop=_type_ _freq_)
             mean=meanmean;
    run;

    proc sql noprint;
      create table work.&prefix._30 as
        select *
        from &currentDataset
             cross join 
             work.&prefix._meanmean
        order %tu_sqlnlist(&sortby)
        ;
    quit;

    data work.&prefix._40;
      set work.&prefix._30 end=finish;
      drop meanmean;
      drop __msg;
      %tu_xcpsectioninit(header=Mean of Mean CV Imputations - %upcase(&cvvar));
      if &cvvar eq &cvvarMissingValue then
      do;
        &cvvar = meanmean;
        %tu_byid(dsetin=work.&prefix._30
                ,invars=&sortby ind &cvvar
                ,outvar=__msg
                );
        %tu_xcpput("Imputation done: " !! __msg
                  ,warning
                  );
      end;
      %tu_xcpsectionterm(end=finish);
    run;
    %tu_abort;
    %let currentdataset = work.&prefix._40;
  %end; /* Use mean of mean for nums */

  /* 5. Create result dataset */
  data &dsetout;
    set &currentDataset;
  run;

  /* 6. Check the resulting dataset for remaining missings */
  data _null_;
    set &dsetout end=finish;
    if &cvvar eq &cvvarMissingValue then
    do;
      %tu_byid(dsetin=&dsetout
              ,invars=&sortby ind &cvvar
              ,outvar=__msg
              );
      put 'RTE' "RROR: &sysmacroname: Failed to perform imputation: " __msg;
      call symput('G_ABORT','1');
    end;
  run;
  %tu_abort;

  /* Finish-off */
  %tu_tidyup(rmdset=&prefix:
            ,glbmac=NONE
            );
  quit;

  %tu_abort;

%mend tu_nmimpcv;
