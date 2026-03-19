/*******************************************************************************
|
| Macro Name: tu_addbignvar
|
| Macro Version:  1
|
| SAS Version: 8
|
| Created By: Todd Palmer
|
| Date: 30May2003
|
| Macro Purpose: A macro to add the big N value to a dataset for display
|
| Macro Design: Procedure Style.
|
| Input Parameters:
|
| NAME                  DESCRIPTION                                       DEFAULT
|
| DSETINTOADDBIGN       The name of the input dataset to which the Big N  No default
|                       Big N variable will be added
|
|                       Valid values: data set name 
|                       (1 or 2 part names accepted)
|
| DSETINTOCOUNT         The name of the input dataset containing data     No default 
|                       to be counted for BIG N counts.
|                       Normally this will be the population dataset that 
|                       has come out of %tu_getdata.
|
|                       Valid values: data set name 
|                       (1 or 2 part names accepted)
|
| COUNTDISTINCTWHATVAR  Name of the variable containing the value that    No default
|                       is being counted. Generally this is the variable
|                       holding the subjects id.
|
| GROUPBYVARS           Variables to group data by when counting.         No default
|                       Usually one variable, trtcd.                
|
| TOTALID               Value of the GROUPBYVARS variable in              No default
|                       DSETINTOADDBIGN which appears on records 
|                       representing totals over the other values of 
|                       the GROUPBYVARS. Specifying TOTALID will 
|                       generate a count that includes the total over 
|                       the GROUPBYVARS variable.
| 
| BIGNVARNAME           Name of column containing Big N info.             bigN   
| 
| DSETOUT               Output Dataset.                                   No default 
|
|
| Output: The output from this program is the contents of the dataset passed
|         in plus an additional variable containing the population counts. The
|         additional variable is named according to the value of parameter
|         &bigNvarname.
|         
|
| Global macro variables created: NONE
|
|
| Macros called:  
|    (@) tr_putlocals
|    (@) tu_putglobals
|    (@) tu_chkVarsExist
|    (@) tu_chkNames
|    (@) tu_stats
|    (@) tu_words
|    (@) tu_nobs
|    (@) tu_tidyup
|    (@) tu_abort
|
|
| Example:
| %tu_addBigNVar(
|      dsetinToAddBigN=testDataStats
|    , dsetInToCount=testDataPop
|    , groupByVars=trtcd
|    , totalID=9999
|    , countDistinctWhatVar=subjid
|    , dsetout=testOut
|    , bigNVarName=bigN
|    )
|
|
| **************************************************************************
| Change Log :
|
| Modified By : Todd Palmer
| Date of Modification : 17Sep2003
| New Version Number : 1/2 
| Modification ID : 001
| Reason For Modification : SCR comments
|
| Modified By :
| Date of Modification :
| New Version Number :
| Modification ID :
| Reason For Modification :
|
+----------------------------------------------------------------------------*/



%macro tu_addBigNVar(
      dsetinToAddBigN= /* The name of the input dataset to which the Big N variable will be added */
    , dsetinToCount=   /* The name of the input dataset containing data to be counted for BIG N counts. */
    , countDistinctWhatVar= /* Name of the variable containing the value that is being counted. Generally this is the variable holding the subjects id. */
    , groupByVars=     /* Variables to group data by when counting */
    , totalID=         /* Value of the GROUPBYVARS variable in dsetinToAddBigN which appears on records representing totals over the other values of the groupByVars */
    , bigNVarName=bigN /* Name of variable created to hold the Big N count */
    , dsetOut=         /* Output dataset  */
    );


    /*---------------------------------------------------------------------------
    / Write details of macro start to log 
    / ---------------------------------------------------------------------------
    */
    %local MacroVersion;
    %let MacroVersion = 1;
    
    %include "&g_refdata/tr_putlocals.sas"; 
    
    %tu_putglobals()


    /*-------------------------------------------------------------------------
    /  Set up local macro variables 
    / ---------------------------------------------------------------------------
    */
    %local 
        i              /* counter */
        rc             /* return code from procedure steps */
        prefix         /* used for uniquely identifying datasets created by this program */
        dsoptstart     /* position in string at which dataset options are specified */
        dsetNameOnly   /* the dset with any dataset options removed  */
        wordList       /* holds a list of words                   */
        thisWord       /* holds one of a list of words at a time */
        chkVarsExist   /* captures output from tu_chkvarsexist */
        ;

    %let prefix = _addBigNVar;

    /*---------------------------------------------------------------------------
    / Parameter Validation 
    / ---------------------------------------------------------------------------
    */
    /* Check required parameters have something specified  
    /  --------------------------------------------------
    */
    %let wordList = dsetinToAddBigN dsetInToCount bigNVarName dsetOut;
    %do i = 1 %to %tu_words(&wordList);
        %let thisWord = %scan(&wordList, &i);
        %if "&&&thisWord" eq "" %then %do;
            %put RTE%str(RROR:) &sysmacroname.: Macro Parameter %upcase(&thisWord) requires a value: %upcase(&thisWord)=&&&thisWord ;
            %let rc = -1;        
        %end;
    %end;
    
    /* Check name of dsetout is valid 
    /  -----------------------------------
    */
    %if "&dsetOut" ne "" %then %do;
        /* remove any dataset options from the dsetout */
        %let dsOptStart = %index(&dsetout, %str(%() ) ;
        %if &dsOptStart gt 0 %then %do;
            %let dsetNameOnly = %substr(&dsetout, 1, &dsOptStart - 1 );
        %end;
        %else %do;
            %let dsetNameOnly = &dsetout;
        %end;
        %if &g_debug gt 0 %then %put Created Macro Var dsetNameOnly=&dsetNameOnly.. from dsetOut=&dsetOut..;

        /* calling tu_chknames */
        %if %tu_chknames(&dsetNameOnly, DATA ) ne %then %do;
            %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETOUT refers to dataset &dsetNameOnly which is not a valid dataset name;
            %let rc = -1;        
        %end;
    %end;   /* of %if "&dsetOut" ne "" %then %do; */


    /* Check existence of input datasets
    /  ---------------------------------
    */
    /* check dsetinToAddBigN */
    %let wordList = dsetinToAddBigN dsetInToCount;
    %do i = 1 %to %tu_words(&wordList);
        %let thisWord = %scan(&wordList, &i);
        %if "&&&thisWord" ne "" %then %do;
            /* remove any dataset options from the dsetin */
            %let dsOptStart = %index(&&&thisWord, %str(%() ) ;
            %if &dsOptStart gt 0 %then %do;
                %let dsetNameOnly = %substr(&&&thisWord, 1, &dsOptStart - 1 );
            %end;
            %else %do;
                %let dsetNameOnly = &&&thisWord;
            %end;
            %if &g_debug gt 0 %then %put Created Macro Var dsetNameOnly=&dsetNameOnly.. from &thisWord=&&&thisWord..;
            /* write meesage if dsetin does not exist */
            %if %sysfunc(exist(&dsetNameOnly)) eq 0 %then %do;
                %put RTE%str(RROR:) &sysmacroname.: Macro Parameter &thisWord refers to dataset &dsetNameOnly which does not exist;
                %let rc = -1;
            %end;
        %end;
    %end;        


    /* exit if problem with existence of dataset */
    %if &rc eq -1 %then %goto MACERR;


    /* Make sure variables mentioned exist with data
    /  ---------------------------------------------
    */
    %let wordList = dsetinToAddBigN dsetInToCount;
    %do i = 1 %to %tu_words(&wordList);
        %let thisWord = %scan(&wordList, &i);
        /* create temp dataset first, applying the dataset options */
        data &prefix._work0_&i;
            set &&&thisWord;
            if _n_ eq 1;
        run;


        /* Check input dataset has observations 
        /  ------------------------------------
        */
        %if %tu_nobs(&prefix._work0_&i) le 0 %then %do;
            %put RTE%str(RROR:) &sysmacroname.: Macro Parameter &thisWord results in a dataset with no observations;
            %let rc = -1;
        %end;

        /*** Check groupBYVARS ***/
        %if "&groupByVars" ne "" %then %do;
            /* calling tu_chkVarsExist */
            %let varsNoExist = %tu_chkVarsExist(&prefix._work0_&i, &groupByVars );
            %if "&varsNoExist" ne "" %then %do;
                %put RTE%str(RROR:) &sysmacroname.: Macro Parameter GROUPBYVARS lists variables not existing in &thisWord: &varsNoExist.;
                %let rc = -1;        
            %end;        
        %end;
    %end;  /* of i = 1 %to %tu_words(&wordList)  */


    /* check that sas name specified in BigN parm is valid variable name
    /  -----------------------------------------------------------------
    */
    %if %tu_chknames(&bigNVarName, VARIABLE ) ne %then %do;
	    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter BIGNVARNAME specifies an invalid SAS variable name: BIGNVARNAME=&bigNVarName.;
	    %let rc = -1;        
    %end;
    

    /* check that name of BigN variable to be created does not exist on
    /  dset already, give WARNING if so
    /  -----------------------------------------------------------------
    */
    %if "&dsetinToAddBigN" ne "" and "&bigNVarName" ne "" %then %do;
        %if %length( %tu_chkVarsExist(&dsetinToAddBigN, &bigNVarName ) ) eq 0 %then %do;
            %put RTW%str(ARNING:) &sysmacroname.: Macro Parameter BIGNVARNAME lists a variable already existing in &DSETINTOADDBIGN.;
            %put RTW%str(ARNING:) The value of the pre-existing variable &BIGNVARNAME will be overwritten.;
        %end;
    %end;


    /* exit if parameter checking has produced an error  */
    %if &rc eq -1 %then %goto MACERR;
 

    /* Act on any errors from called funtion macros */
    %tu_abort()
    

    /*------------------------------------------------------------------------
     * get the N count
     *------------------------------------------------------------------------*/
	/* note, only expecting the population count to be a count of one thing  */
    %tu_stats(
          dsetIn=&dsetInToCount
        , countDistinctWhatVar=&countDistinctWhatVar
        , classVars=&groupByVars
		%if &totalID ne %then %do;
	        , totalID=&totalID
			, totalForVar=%scan(&groupByVars, -1)
		%end;
		, dsetOut=&prefix._addN1
        );


    /*------------------------------------------------------------------------
     * Add the N count var to the dataset 
     *------------------------------------------------------------------------*/
    proc sql;
        create table &dsetOut as
        select dsetInToAddBigN.*
            , _addN1._freq_ as &bigNVarName label 'Population Big N'
        from &dsetInToAddBigN as dsetInToAddBigN
        %if &groupByVars ne %then %do;
            left join &prefix._addN1 as _addN1
     
                on dsetInToAddBigN.%scan(&groupByVars,1) = _addN1.%scan(&groupByVars,1)
                %do i=2 %to %tu_words(&groupByVars);
                    and dsetInToAddBigN.%scan(&groupByVars,&i) = _addN1.%scan(&groupByVars,&i)
                %end;
        %end;
        %else %do;  /* there must be just one count - attach to all recs */
            , &prefix._addN1  as _addN1
        %end;
        ;
        %if &sqlrc eq 0 %then %do;
          /* successful completion, no action necessary  */
        %end;

        %else %if &sqlrc eq 4 %then %do;
          %put RTW%str(ARNING:) &sysmacroname.: A warning was issued by PROC SQL.;
          %put RTW%str(ARNING:) &sysmacroname.: Check the parameters passed to &sysmacroname.;
        %end;

        %else %if &sqlrc ge 8 %then %do;
          %put RTE%str(RROR:) &sysmacroname.: PROC SQL ended with errors, output data set (&DSETOUT) was not created successfully.;
          %goto macerr;
        %end;

        %else %do;
          %put RTE%str(RROR:) &sysmacroname.: PROC SQL ended with an undocumented return code (&SQLRC).;
          %put RTE%str(RROR:) &sysmacroname.: Contact SAS Institute technical support.;
          %goto macerr;
        %end;
    quit;

    /*----------------------------------------------------------------- 
    / Tidy up and leave
    / -----------------------------------------------------------------
    */
    %tu_tidyup(rmdset=&prefix.:, glbmac=NONE)

    %goto EXIT;

  %MACERR: 
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort has been set to &g_abort;
    %put RTN%str(OTE:) &sysmacroname.: This macro will now abort;


  %EXIT:
      /* run tu_abort always in case of global macro var g_abort has been set to 1 by any procedure */
    %tu_abort()

    %if &g_debug gt 0 %then %put Exiting &sysmacroname;

%mend;
