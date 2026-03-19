/*******************************************************************************
|
| Macro Name:     tu_cv.sas
|
| Macro Version:  1
|
| SAS Version:    8.2
|
| Created By:     Trevor Welby
|
| Date:           10th December 2004
|
| Macro Purpose:  The purpose of this unit is to merge covariates 
|                 onto the A&R dataset specified by the DSETIN parameter.
|
|                 The merge produces a left join between the DSETIN dataset
|                 and the covariate dataset(s)
|
|                 The input string specified by the macros CV parameter
|                 contains the covariate(s) information.
|
| Macro Design:   Procedure style
|
| Input Parameters:
|
| NAME            DESCRIPTION                                    DEFAULT
|
| DSETIN          Specifies the name of the input A&R            [blank] (Req)
|                 dataset
|
| DSETOUT         Specifies the name of the output A&R           [blank] (Req)
|                 dataset
|
| CV              Specifies covariate data to be added to the    [blank] (Opt) 
|                 output file
|
|                 Valid values: For each variable to be added, 
|                 the following three or four attributes shall 
|                 be specified:
|                 	Mandatory. Dataset name
|                 	Mandatory. Variable name(s) 
|                       Surrounded in Square brackets
|                   Mandatory. Variables by which the CV 
|                   variable shall be merged with the DSETIN 
|                   data. Surrounded by square brackets
|                 	Optional. A where clause to be applied 
|                   to the CV dataset during the merge. 
|                   Surrounded by square brackets.  
|
|                   For example, 
|
|                   CV=ardata.demo [age race] [subjid] 
|                      ardata.vitals [weight] [subjid] 
|                      [visitnum eq 1]
|
| JOINMSG         Specifies whether unmatched PK concentration    [blank] (Opt)
|                 and covariate records should be treated as 
|                 %str(warn)ings, %str(erro)rs and %str(Not)e
|
|                 Valid values: %str(WARN)ING, %str(ERRO)R, 
|                               and %str(NOT)E
|
| ISVARINDSPLAN   Optionally perform a parameter validation to    N   (Req)
|                 verify that the covariate(s) specified (CV
|                 parameter) is/are in the dataset plan
|
|                 Valid values: Y, N
|
| Output:         The unit shall overwrite the dataset specified 
|                 by the DSETIN parameter 
|
| Global macro variables created: [none]
|
| Macros called:
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_chkvarsexist
| (@) tu_chknames
| (@) tu_xcpsectioninit
| (@) tu_xcpput
| (@) tu_xcpsectionterm
| (@) tu_isvarindsplan
| (@) tu_readdsplan
| (@) tu_abort
| (@) tu_tidyup
| (@) tu_byid
|
| Example: 
|
| %tu_cv(dsetin=ardata.pkcnc
|       ,dsetout=pkcnc
|       ,cv=ardata.demo [age race] [subjid] ardata.vitals [weight] [invid subjid] [visitnum=1]
|       )
|
|*******************************************************************************
| Change Log
|
| Modified By: Trevor Welby
| Date of Modification: 10-Dec-04
| New version/draft number: 01-002
| Modification ID: TQW9753.01-002
| Reason For Modification: Add comments to explain implementation of normal
|                          processing section of the unit specification
|
********************************************************************************
| Change Log
|
| Modified By: Trevor Welby
| Date of Modification: 11-Jan-05
| New version/draft number: 01-003
| Modification ID: TQW9753.01-003
| Reason For Modification: The parameter validation was modified to trap
|                          a blank value for ISVARINDSPLAN.  Parameter now 
|                          specified as required above.
********************************************************************************
| Change Log
|
| Modified By: Trevor Welby
| Date of Modification: 03-Feb-05
| New version/draft number: 01-004
| Modification ID: TQW9753.01-004
| Reason For Modification: Fixup the code so that the summary record is displayed
|                          in the situation where the last record of the merge comes 
|                          from the covariate dataset.
|
********************************************************************************/

%macro tu_cv(dsetin=            /* type:ID Input Dataset Name */
            ,dsetout=           /* Name of output dataset */
            ,cv=                /* Covariate data to be added   */
            ,joinmsg=           /* Specifies how unmatched records are treated */
            ,isvarindsplan=N    /* Verify that covariate(s) are specified in the dataset plan */
            );

  /*
  / Echo values of parameters and global macro variables to the log.
  /------------------------------------------------------------------------------*/
  %local MacroVersion;
  %let MacroVersion=1;
  %include "&g_refdata./tr_putlocals.sas";
  %tu_putglobals(varsin=g_dsplanfile);

  /*
  / Perform parameter validation
  /------------------------------------------------------------------------------*/

  /*
  / Verify that the dataset DSETIN exists
  /------------------------------------------------------------------------------*/
  %if not %sysfunc(exist(&dsetin)) %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: Macro Parameter DSETIN (dsetin=&dsetin) dataset does not exist;
    %let g_abort=1;
  %end;

  /*
  / Verify that DSETOUT is not blank
  /------------------------------------------------------------------------------*/
  %if %length(&dsetout) eq 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: Macro Parameter DSETOUT must not be blank;
    %let g_abort=1;
  %end;
  %else
  %do;
    /*
    / Verify that DSETOUT is a valid dataset name
    /------------------------------------------------------------------------------*/
    %if %length(%tu_chknames(&dsetout,DATA)) ne 0 %then
    %do;
      %put RTE%str(RROR): &sysmacroname.: Value specified for DSETOUT (&dsetout) is invalid;
      %let g_abort=1;
    %end;
  %end;

  /*
  / Verify JOINMSG parameter has valid values
  /------------------------------------------------------------------------------*/
  %if not (%upcase(&joinmsg)=%STR(ERRO)R or %upcase(&joinmsg)=%str(WARN)ING or %upcase(&joinmsg)=%str(NOT)E ) %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: Macro Parameter JOINMSG (joinmsg=&joinmsg) is invalid. Valid values are: %STR(ERRO)R, %str(WARN)ING or %str(NOT)E;
    %let g_abort=1;
  %end;

  /*
  / Verify ISVARINDSPLAN parameter has valid values (i.e. Y,N) (if specified) [TQW9753.01-003]
  /------------------------------------------------------------------------------*/
    %if not ( %upcase(&isvarindsplan)=Y or %upcase(&isvarindsplan)=N ) %then
    %do;
      %put RTE%str(RROR): &sysmacroname.: Macro Parameter ISVARINDSPLAN (isvarindsplan=&isvarindsplan) has an invalid value (valid values: Y N);
      %let g_abort=1;
    %end; 

  %tu_abort;

  /*
  / Perform Normal Processing
  /------------------------------------------------------------------------------*/

  /*
  / Create a local variable defining the prefix for all the temporary work 
  / datasets that will be created during normal processing
  /------------------------------------------------------------------------------*/
  %local prefix;
  %let prefix = %substr(&sysmacroname,3); 

  /*
  /	If the CV parameter is blank then issue the following note and perform no 
  /  further processing - Macro Parameter CV (cv=&cv) has not been specified - 
  /  this is optional.  Note the use of the CV parameter is optional if this 
  /  macro is called.
  /------------------------------------------------------------------------------*/
  %if %length(&cv) eq 0 %then
  %do;
    %put RT%str(NOT)E: &sysmacroname.: Macro Parameter CV has not been specified - this is optional;
  %end;
  %else 
  %do; /* Beginning of CV parameter processing */

    /*
    / If CV is non blank and parameter isvarindsplanfile=Y then read the 
    / dsplanfile (%tu_readdsplan)
    /------------------------------------------------------------------------------*/
    %if &isvarindsplan=Y %then
    %do;
      %tu_readdsplan(infile=&g_dsplanfile,dsetout=work.&prefix._dsplan);
    %end;

    /*
    / Parse the CV parameter and put the constituent parts into macro variable 
    / arrays
    /------------------------------------------------------------------------------*/
    %local remainingString counter cvdset0;

    %let remainingString=%sysfunc(left(%sysfunc(trim(&cv))));
    %let counter = 1;

    %do %while (&remainingString ne %str( ));

      %local cvdset&counter cvvar&counter cvby&counter cvwhere&counter; 

      /* Index dataset length */
      %let ptr=%index(&remainingString,%str( ));

      %if &g_debug gt 1 %then
      %do;  /* Display length of the first word */
        %put DATASET LENGTH: PTR &ptr;
      %end; /* Display length of the first word */

      /* Bite off the first word i.e the covariate DATASET name */
      %let cvdset&counter=%substr(&remainingString,1,%eval(&ptr-1));

      %if &g_debug gt 1 %then
      %do;  /* Display the covariate dataset name */
        %put DATASET: cvdset&counter &&cvdset&counter;
      %end; /* Display the covariate dataset name */

      /* Remainder after first bite */
      %let remainingString=%sysfunc(left(%sysfunc(trim(%substr(&remainingString,&ptr)))));

      %if &g_debug gt 1 %then
      %do;  /* Display remainingString after taking first bite */ 
        %put DATASET: remainingString &remainingString;
      %end; /* Display remainingString after taking first bite */

      /*
      / Verify that the dataset specified in the CV parameter exists
      /------------------------------------------------------------------------------*/
      %if not %sysfunc(exist(&&cvdset&counter)) %then
      %do;  /* Verify that the dataset is valid */
        %put RTE%str(RROR): &sysmacroname.: Macro Parameter CV - Dataset (dataset=&&cvdset&counter) does not exist;
        %tu_abort(option=force);
      %end; /* Verify that the dataset is valid */

      /*
      / Prepare to bite off the second word i.e the list of COVARIATE(S) 
      / but first check that the word begins with a bracket i.e [ and abort if not
      /------------------------------------------------------------------------------*/
      %if %substr(&remainingString,1,1) ne [ %then 
      %do;  /* Validate that the string begins with a bracket and abort of not */ 
        %put RTE%str(RROR): &sysmacroname.: Macro Parameter CV (cv=&cv) covariate list not specified correctly;
        %tu_abort(option=force);
      %end; /* Validate that the string begins with a bracket and abort of not */ 
      %else
      %do; /* Begin processing the covariate string */
        /* 
        /  Find the length of the second word
        /------------------------------------------------------------------------------*/
        %let ptr=%index(&remainingString,]);

        %if &g_debug gt 1 %then
        %do;  /* Display the length of the second word */
          %put COVARIATE(S) - LENGTH OF WORD : PTR &ptr;
        %end; /* Display the length of the second word */

        %let cvvar&counter=%substr(&remainingString,2,%eval(&ptr-2));

        %if &g_debug gt 1 %then
        %do;  /* Display covariate list */
          %put COVARIATE(S) - DISPLAY COVARIATE LIST : cvvar&counter &&cvvar&counter;
        %end; /* Display covariate list */
 
        %if %eval(&ptr+1) lt %length(&remainingString) %then 
        %do;  /* Set the remaining string */
          %let remainingString=%sysfunc(left(%sysfunc(trim(%substr(&remainingString,%eval(&ptr+1))))));

           %if &g_debug gt 1 %then
           %do;  /* Display the remaining string */
             %put COVARIATE(S): remainingString &remainingString;
           %end; /* Display the remaining string */

        %end;  /* Set the remaining string */
        %else 
        %do; /* Set the remaining string to blank */
          %let remainingString=%str( );
        %end;  /* Set the remaining string to blank */
      %end; /* End processing the covariate string */

      /*
      / Verify that the COVARIATE(S) exists in the covariate dataset
      /------------------------------------------------------------------------------*/
      %if %length(%tu_chkvarsexist(&&cvdset&counter,&&cvvar&counter)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname.: Macro Parameter CV - Covariate (variable=&&cvvar&counter) does not exist in dataset %upcase(&&cvdset&counter);
        %tu_abort(option=force);
      %end;
      
      /*
      / Verify that the COVARIATE(S) does not exist in the DSETIN dataset
      /------------------------------------------------------------------------------*/
      %if %length(%tu_chkvarsexist(&dsetin,&&cvvar&counter)) eq 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname.: Macro Parameter CV - Covariate (variable=&&cvvar&counter) already exists in DSETIN (dsetin=&dsetin);
        %tu_abort(option=force);
      %end;

      /*
      / Verify that the COVARIATE(S) exists on the dataset plan dataset and put
      / out a war!!ning message if it does not
      /------------------------------------------------------------------------------*/
      %if %upcase(&isvarindsplan)=Y %then
      %do;
        %if %tu_isvarindsplan(dsetin=work.&prefix._dsplan,var=&&cvvar&counter) ne Y %then
        %do;
          %put RTW%str(ARNING): &sysmacroname.: Macro Parameter CV (cv=&cv) The Covariate named: &&cvvar&counter does not exist on the dataset plan dataset;
        %end;
      %end;
 
      /*
      / Prepare to bite off the third word i.e the list of BY variable(s) 
      / but first check that the word begins with a bracket i.e [ and abort if not
      /------------------------------------------------------------------------------*/
      %if %substr(&remainingString,1,1) ne [ %then 
      %do; 
        %put RTE%str(RROR): &sysmacroname.: Macro Parameter CV (cv=&cv) BY list is not specified correctly;
        %tu_abort(option=force);
      %end;
      %else
      %do;
        /* 
        /  Find the length of the third word
        /------------------------------------------------------------------------------*/
        %let ptr=%index(&remainingString,]);

        %if &g_debug gt 1 %then
        %do; /* Display the length of the third word */
          %put BYVARS: PTR &ptr;
        %end;  /* Display the length of the third word */

        /* Extract the BY variables(s) for the MERGE */
        %let cvby&counter=%substr(&remainingString,2,%eval(&ptr-2));

        %if &g_debug gt 1 %then
        %do;  /* Display the BY variable(s) */
          %put BYVARS: cvby&counter &&cvby&counter;
        %end;  /* Display the BY variable(s) */

        %if %eval(&ptr+1) lt %length(&remainingString) %then %do;
          %let remainingString=%sysfunc(left(%sysfunc(trim(%substr(&remainingString,%eval(&ptr+1))))));

          %if &g_debug gt 1 %then
          %do;
            %put BYVARS: remainingString &remainingString;
          %end;

        %end;
        %else %do;
          %let remainingString=%str( );
        %end;

        /*
        / Verify that the BY variable(s) exist in the COVARIATE dataset
        /------------------------------------------------------------------------------*/
        %if %length(%tu_chkvarsexist(&&cvdset&counter,&&cvby&counter)) ne 0 %then
        %do;
          %put RTE%str(RROR): &sysmacroname.: Macro Parameter CV - MERGE by variable(s) (variable=&&cvby&counter) do not exist in CV dataset %upcase(&&cvdset&counter);
          %tu_abort(option=force);
        %end;

        /*
        / Verify that the BY variable(s) exist in DSETIN dataset
        /------------------------------------------------------------------------------*/
        %if %length(%tu_chkvarsexist(&dsetin,&&cvby&counter)) ne 0 %then
        %do;
          %put RTE%str(RROR): &sysmacroname.: Macro Parameter CV - MERGE by variable(s) (variable=&&cvby&counter) do not exist in DSETIN dataset %upcase(&dsetin);
          %tu_abort(option=force);
        %end;

      %end;
   
      /* Extract the optional WHERE clause */
      %if %substr(&remainingString,1,1) eq [ %then 
      %do;
        %let ptr=%index(&remainingString,]);

        %if &g_debug ge 1 %then
        %do;
          %put RTDEBUG: &sysmacroname: OPTIONAL WHERE: PTR &ptr;
        %end;

        %let cvwhere&counter=%substr(&remainingString,2,%eval(&ptr-2));

        %if &g_debug ge 1 %then
        %do;
          %put RTDEBUG: &sysmacroname: OPTIONAL WHERE: cvwhere&counter &&cvwhere&counter;
        %end;

        %if %eval(&ptr+1) lt %length(&remainingString) %then
        %do;
          %let remainingString=%sysfunc(left(%sysfunc(trim(%substr(&remainingString,%eval(&ptr+1))))));

          %if &g_debug ge 1 %then
          %do;
            %put RTDEBUG: &sysmacroname: OPTIONAL WHERE: remainingString &remainingString;
          %end;

        %end;
        %else 
          %let remainingString=%str( );
      %end;

      %let counter=%eval(&counter+1);

    %end; /* do while (remainingString ne blank) */

    %let cvdset0=%eval(&counter-1);

    %local CurrentDataset ;
    %let CurrentDataSet     = &dsetin;

    /*
    / MERGE covariate(s) onto DSETIN dataset and create an exception report
    /------------------------------------------------------------------------------*/
    %local cvPtr;
    %do cvPtr=1 %to &cvdset0;  /* Beginning Merge Covariate Loop */

      proc sort data=&CurrentDataSet 
                out=&prefix._currentSorted&cvPtr; 
        by &&cvby&cvPtr; 
      run;

      proc sort data = &&cvdset&cvPtr 
                out  = &prefix._cv&cvPtr (keep = &&cvby&cvPtr &&cvvar&cvPtr); 
        by &&cvby&cvPtr; 
        %if &&cvwhere&cvPtr ne %then 
        %do;
          where (&&cvwhere&cvPtr);
        %end;   
      run;

      data work.&prefix._CurrentWorkDataset&cvPtr;
        merge &prefix._currentSorted&cvPtr (in=DSETIN)
              &prefix._cv&cvPtr            (in=CV) 
              end=DataEnd
              ;
        by &&cvby&cvPtr;

        drop __msg;

        /*
	      / Initialise exception report section
	      /------------------------------------------------------------------------------*/
	      %tu_xcpsectioninit(header=Exception Message(s) for Merge of Covariate Variable: %upcase(&&cvvar&cvPtr.))

	      /*
	      /  Write the exception messages (if applicable)
	      /------------------------------------------------------------------------------*/
	      if (DSETIN and NOT CV) then
	      do;  
	        %tu_byid(dsetin=&prefix._currentSorted&cvPtr
	                ,invars=&&cvby&cvPtr
	                ,outvar=__msg);
	        %tu_xcpput("No covariate value (CV=%upcase(&&cvvar&cvPtr)) identified : "!!__msg,&joinmsg);
        end;	

				if DSETIN then output; *[TQW9753.01-004];

        /*
        /  Terminate the section
        /------------------------------------------------------------------------------*/
        %tu_xcpsectionterm(end=DataEnd);

      run;

      %tu_abort;

      %let CurrentDataSet=&prefix._CurrentWorkDataSet&cvPtr;
  
    %end; /* End Merge Covariate Loop */

    data &dsetout; /* Return a dataset with the correct name */
      set &CurrentDataSet;
    run;
  
  %end;  /* End of CV parameter processing */ 

  %tu_tidyup(rmdset=&prefix:
            ,glbmac=NONE
            );

  %tu_abort;

%mend tu_cv;
