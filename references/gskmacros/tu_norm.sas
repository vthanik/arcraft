/*--------------------------------------------------------------------------+
| Macro Name    : tu_norm.sas
|
| Macro Version : 1
|
| SAS version   : SAS v8.2
|
| Created By: Todd Palmer
|
| Date: 30May2003
|
|
| Macro Purpose : Normalise data by performing a reverse transpose of one or more
|                 specified columns of data into rows
|                 Rows created from all columns of data being normalised shall be appended
|                 together to form the output dataset.
|
| Macro Design: Procedure Style.
|
|
| Input Parameters :
|
| NAME         DESCRIPTION                               DEFAULT
| DSETIN       Dataset to normalise                      none
| VARSTONORM   columns to be turned into rows            none
| FMTKEEPYN    Store the format of variable being normed    Y
| DSETOUT      normalised dataset out                    none
|
|
| Output: An output dataset formed by transposing one or more specified columns of data into
|         rows. Rows created from all columns of data being normalised shall be appended together
|         to form the output dataset. The output dataset shall contain the variables not being normalised, plus
|         additional variables:
|             tt_normVal = holds the name of the variable normalised
|             tt_normVar = the value of variable normalised
|             and additionally if parameter FMTKEEPYN = Y :
|             tt_normFmt = the format of the variable normalised.
|
|         The output dataset will contain records and variables according to the following formulas:
|             Output records = dsetin_obs * varsToNorm_n
|             Output variables = dsetin_vars � varsToNorm_n + vars_created
|         Where:
|             dsetin_obs = number of observations(rows) on dsetin
|             varsToNorm = number of variables to be converted to rows (normalised)
|             vars_created = 2 (tt_normVar, tt_normVal), plus 1 (tt_normFmt) if fmtKeepYN = Y
|
|
| Global macro variables created: none
|
|
| Macros called :
|     (@) tr_putlocals
|     (@) tu_putglobals
|     (@) tu_chknames
|     (@) tu_chkvarsexist
|     (@) tu_words
|     (@) tu_chkvartype
|     (@) tu_abort
|     (@) tu_tidyup
|
|
| Example:
|     %tu_norm(
|            dsetin=statsInCols
|          , varsToNorm=n mean median min max sd missing
|          , fmtKeepYN=Y
|          , dsetout=statsInRows
|          );
|
| **************************************************************************
| Change Log :
|
| Modified By : Todd Palmer
| Date of Modification : 11 Jul 03
| New Version Number : 1/2
| Modification ID : DN01
| Reason For Modification : SCR comments
| **************************************************************************
| Modified By :
| Date of Modification :
| New Version Number :
| Modification ID :
| Reason For Modification :
|
+----------------------------------------------------------------------------*/


%macro tu_norm(
      dsetin=      /* The name of the input dataset   */
    , varsToNorm=n mean median min max sd missing    /*  Variables to be normalised */
    , fmtKeepYN=Y   /* Create variable tt_normfmt to hold the format of the vars to norm - Y/N?  */
    , dsetout=     /* Output dataset   */
    );

    /*---------------------------------------------------------------------------
    / Write details of macro start to log
    / ---------------------------------------------------------------------------
    */
    %local MacroVersion;
    %let MacroVersion = 1;

    %include "&g_refdata/tr_putlocals.sas";


    %tu_putglobals()

    /*---------------------------------------------------------------------------
    /  Set up local macro variables
    / ---------------------------------------------------------------------------
    */
    %local
        i              /* counter */
        rc             /* return code from procedure steps */
        prefix         /* used for uniquely identifying datasets created by this program */
        dsetIn_dset    /* the dsetin with any dataset options removed  */
        dsetOut_dset   /* the dsetOut with any dataset options removed  */
        thisWord        /* holds one of a list of words at a time */
        vtnDataTypes   /* holds the data Types of the norm vars */
        maxLen         /* holds the maximum length of character data in varsToNorm */
        chkVarsExist   /* captures output from tu_chkvarsexist */
        ;

    %let prefix = norm;

    /*---------------------------------------------------------------------------
    / Parameter Validation
    / ---------------------------------------------------------------------------
    */

    /*** Make sure macro parameters have something specified ***/
    %do i = 1 %to 3;
        %let thisWord = %scan(dsetin varsToNorm dsetout, &i);
        %if "&&&thisWord" eq "" %then %do;
            %put RTE%str(RROR:) &sysmacroname.: Macro Parameter %upcase(&thisWord) requires a value: %upcase(&thisWord)=&&&thisWord ;
            %let g_abort = 1;
            %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
            %let rc = -1;
        %end;
    %end;


    /*** Check existence of input dataset ***/
    %if "&dsetin" ne "" %then %do;
        /* remove any dataset options from the dsetin */
        %let dsOptStart = %index(&dsetin, %str(%() ) ;
        %if &dsOptStart gt 0 %then %do;
            %let dsetIn_dset = %substr(&dsetin, 1, &dsOptStart - 1 );
        %end;
        %else %do;
            %let dsetIn_dset = &dsetin;
        %end;
        %if &g_debug gt 0 %then %put Created Macro Var dsetIn_dset=&dsetIn_dset.. from dsetin=&dsetin..;
        /* write meesage if dset no existence */
        %if %sysfunc(exist(&dsetIn_dset)) eq 0 %then %do;
            %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETIN refers to dataset &dsetIn_dset which does not exist;
            %let g_abort = 1;
            %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
            %let rc = -1;
        %end;
        %else %if "&varsToNorm" ne "" %then %do;
            /*** Check variables to norm exist in input dataset ***/
            /* create temp dataset first, applying the dataset options */
            data &prefix._dsetin;
                set &dsetin;
                if _n_ eq 1;
            run;
            /* calling tu_chkVarsExist */
            %let chkVarsExist = %tu_chkVarsExist(&prefix._dsetIn, &varsToNorm );
            %if "&chkVarsExist" ne "" %then %do;
                %put RTE%str(RROR:) &sysmacroname.: Macro Parameter VARSTONORM lists variables not existing in &dsetIn: &chkVarsExist.;
                %let g_abort = 1;
                %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
                %let rc = -1;
            %end;
        %end;
    %end;  /* of %if "&dsetin" ne "" %then %do; */


    /*** Check name of dsetout is valid ***/
    %if "&dsetOut" ne "" %then %do;
        /* remove any dataset options from the dsetin */
        %let dsOptStart = %index(&dsetout, %str(%() ) ;
        %if &dsOptStart gt 0 %then %do;
            %let dsetOut_dset = %substr(&dsetout, 1, &dsOptStart - 1 );
        %end;
        %else %do;
            %let dsetOut_dset = &dsetout;
        %end;
        %if &g_debug gt 0 %then %put Created Macro Var dsetOut_dset=&dsetOut_dset.. from dsetOut=&dsetOut..;

        /* calling tu_chknames */
        %if %tu_chknames(&varsToNorm, DATA ) ne %then %do;
            %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETOUT refers to dataset &dsetOut_dset which is not a valid dataset name;
            %let g_abort = 1;
            %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
            %let rc = -1;
        %end;
    %end;   /* of %if "&dsetOut" ne "" %then %do; */

    /*** exit if error so far ***/
    %if &rc eq -1 %then %goto EXIT;


    /***  Give Er ror message if vars to norm are mixed data type ***/
    /* note user can call this macro repeatedly, grouping varsToNorm into same data types */
    %do i = 1 %to %tu_words(&varsToNorm);
        %let thisWordToNorm = %scan(&varsToNorm, &i);
        %let vtnDataTypes = &vtnDataTypes %tu_chkVarType(&dsetin, &thisWordToNorm);
    %end;
    %let vtnDataTypes = %sysfunc(compress(&vtnDataTypes));
    %if &g_debug gt 0 %then %put Created Macro Var vtnDataTypes=&vtnDataTypes;

    %if %eval(%index(&vtnDataTypes, N) gt 0) and (%index(&vtnDataTypes, C) gt 0) %then %do;
        /* Mixed data types so write error message to log and exit */
        %put RTE%str(RROR:) &sysmacroname.: Macro Parameter VARSTONORM contains variables of mixed data types: VARSTONORM=&varsToNorm.;
        %put RTN%str(OTE:) &sysmacroname.: Specifiy VARSTONORM of the same type in seperate calls to this macro;
        %let g_abort = 1;
        %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
        %let rc = -1;
        %put RTN%str(OTE:) &sysmacroname.: This macro will abort;
        %goto EXIT;
    %end;


    /*---------------------------------------------------------------------------
    /  Check variables that will be created by this program do not exist already;
    /  Write RTE RROR if variables exist already
    / ---------------------------------------------------------------------------
    */
    %do i = 1 %to 2;
        %let thisWord = %scan(tt_normVar tt_normVal, &i);
        %let chkVarsExist = %tu_chkVarsExist(&prefix._dsetIn, &thisWord );
        %if "&chkVarsExist" eq "" %then %do;
            %put RTE%str(RROR:) &sysmacroname.: Variable being created by this macro exists already in dsetin &dsetIn: &thisWord.;
            %let g_abort = 1;
            %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
            %let rc = -1;
        %end;
    %end;

    /* do check also for tt_normfmt if fmtKeepYN = Y  */
    %if %substr(%upcase("&fmtKeepYN"), 2, 1) eq Y %then %do;
        %if %tu_chkVarsExist(&prefix._dsetIn, tt_normFmt) eq %then %do;
            %put RTE%str(RROR:) &sysmacroname.: Variable being created by this macro exists already in dsetin &dsetIn: TT_NORMFMT.;
            %let g_abort = 1;
            %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
            %let rc = -1;
        %end;
    %end;
    /* exit if error found */
    %if &rc eq -1 %then %do;
        %put RTN%str(OTE:) &sysmacroname.: This macro will abort for reasons indicated in the RTE%str(RROR:) message(s) above. ;
        %goto EXIT;
    %end;


    /*---------------------------------------------------------------------------
    / Check for errors occuring in function macros, aborting program if g_abort is set to -1
    / ---------------------------------------------------------------------------
    */
    %tu_abort;


    /*---------------------------------------------------------------------------
    /  Work out maximum length of varsToNorm if one of them is character ;
    / ---------------------------------------------------------------------------
    */
    %if %index(&vtnDataTypes, C) gt 0 %then %do;

        proc sql noprint %if &g_debug gt 0 %then feedback; ;
            select max(maxLen) into: maxLen
            from (
                select
                    max(
                        %do i = 1 %to %tu_words(&varsToNorm);
                            %if &i ne 1 %then %str(,);
                            length(%scan(&varsToNorm, &i ) )
                        %end;
                        ) as maxLen
                from &dsetin
                )
            ;
        quit;
        %if %sysfunc(compress("&maxLen")) eq "." %then %let maxLen = 1;
        %if &g_debug gt 0 %then %put Created Macro Var maxlen=&maxlen;

    %end;

    /*---------------------------------------------------------------------------
    /  Do the normalisation;
    / ---------------------------------------------------------------------------
    */

    data &prefix._1(drop=i &varsToNorm);
        set &dsetin;
        length tt_normVar $32;
        %if %index(&vtnDataTypes, C) gt 0 %then %do;
            length tt_normVal $&maxLen;
        %end;
        array arrayVarsToNorm (%tu_words(&varsToNorm)) &varsToNorm;
        do i = 1 to dim(arrayVarsToNorm);
            call vname(arrayVarsToNorm(i), tt_normVar);

            tt_normVal = arrayVarsToNorm(i);

            %if %substr(%upcase("&fmtKeepYN"), 2, 1) eq Y %then %do;
                length tt_normFmt $32;   /* not done at top of datastep as conditional */
                tt_normFmt = vformatx(vname(arrayVarsToNorm(i)));
            %end;
            output;
        end;
    run;


    /*** create dset out ***/
    data &dsetOut;
        set &prefix._1;
    run;


    /*-----------------------------------------------------------------
    / Tidy up and leave
    / -----------------------------------------------------------------
    */
   %tu_tidyup(rmdset=&prefix.:, glbmac=NONE)


  %EXIT:
    %tu_abort()


    %if &g_debug gt 0 %then %put Exiting tu_norm;

%mend;
