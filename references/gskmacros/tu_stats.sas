/*---------------------------------------------------------------------------+
| Macro Name    : tu_stats.sas
|
| Macro Version : 2
|
| SAS version   : SAS v8.2
|
| Created By    : Todd Palmer & Lee Seymour
|
| Date          : 18th June 2003
|
| Macro Purpose :
|   This macro is designed to produce counts or other summary stats
|   using proc summary.
|
|   Additionally this macro can create total
|   records for an overall value of a classvar in a specified manner.
|
|   This macros main claims to existence are:
|     -  to efficiently compute counts or statistics in one call,
|     -  optionally include the generation of counts or statistics for a total across the variable
|        named in &TOTALFORVAR (usually trtcd) (triggered by the specifying of a &TOTALID value
|     -  optionally to produce a dataset for use in creating the cell index.
|     -  to offer the fullest possible functionality of PROC SUMMARY within the framework of the
|        creation of output using high level reporting tools macros.
|
|   Note on creating records containing a total over the &TOTALFORVAR:
|     If &TOTALID and &TOTALFORVAR contain a value, and advanced options &PSCLASS or &PSWAYS or PSTYPES
|     have NOT been specified, then records containing totals across the &TOTALFORVAR will be
|     created and marked.
|
|     In such a situation the types statement is built within this program
|     to produce 2 crossings of data from proc summary: one for all the variables in the
|     class statement (the nth way), and one for all the variables in the class statement except the
|     &TOTALFORVAR - (nvars not totalForVar ) . ie these second type of records
|     represent a total across the &TOTALFORVAR (This ensures efficient use of PROC SUMMARY.)
|
|     The total records will be identified based on a value in the variable _TYPE_
|     which is created by proc summary to identify the type of crossing of class variables
|     involved in the creation of any PROC SUMMARY output records. This program determines what the
|     _TYPE_ value will be for total records and marks these records with the value of the
|     &TOTALID in variable &TOTALFORVAR
|
| Macro Design  : Procedure
|
|
| Input Parameters :
|
| NAME                   DESCRIPTION                                                                     DEFAULT
|
| DSETIN                 Specifies the dataset containing all variables to be analysed                   none
|
|                        Valid values: Name of an existing dataset
|
| DSETOUT                Name of output dataset                                                          none
|
|                        Valid values: Dataset name
|
| DSETOUTCI              Name of cell index output dataset. If not specified, no cell index output       none
|                        dataset will be created
|
|                        Valid values: Dataset name
|
| ANALYSISVAR            The variable to be statistically analysed. Passed to the PROC SUMMARY Var       none
|                        statement. The choice between production of summary statistics or frequency
|                        counts shall be determined by the presence of a value for the ANALYSISVAR
|                        parameter. A blank value shall indicate that frequency counts are to be
|                        produced; a non-blank value shall indicate that summary statistics are to be
|                        produced.
|
|                        Valid values: Blank, or the name of a variable that exists in DSETIN
|
| ANALYSISVARNAME        For summary statistics, name of variable to be created to hold the label of     none
|                        the analysis variable (%tu_labelvars will be run prior to storing the label),
|                        OR, (for frequency counts or summary statistics) a SAS assignment statement to
|                        create a variable to hold the name of the analysis variable and for assigning
|                        the value to it.
|
|                        Valid Values:
|                        Blank
|                        OR
|                        Valid SAS variable name, e.g. tt_analy
|                        OR
|                        Valid SAS assignment statement, e.g. tt_analy = "Age (yrs)"
|
| ANALYSISFORMATDNAME    Name of variable created to hold the formatd (decimal places) of the analysis   none
|                        variable.
|
|                        Valid Values: SAS variable name
|                        Only valid if ANALYSISVAR is not blank
|
| STATSLIST              List of summary statistics to produce. May also specify correct PROC SUMMARY    none
|                        syntax to rename output variable (N=N MEAN=MEAN)
|                        If blank, PROC SUMMARY's default statistics will be produced.
|
|                        Valid values:
|                        If ANALYSISVAR is blank, or PSOUTPUT is specified: blank
|                        Else: blank, or list of statistics to be created by PROC SUMMARY, or pairs of
|                        values where the pair is comprised a) a PROC SUMMARY statistic, b) an equals
|                        sign, and c) a valid SAS variable name
|
| COUTNDISTINCTWHATVAR   List of summary statistics to produce. May also specify correct PROC SUMMARY    none
|                        syntax to rename output variable (N=N MEAN=MEAN)
|                        If blank, PROC SUMMARY's default statistics will be produced.
|
|                        Valid values:
|                        If ANALYSISVAR is blank, or PSOUTPUT is specified: blank
|                        Else: blank, or list of statistics to be created by PROC SUMMARY, or pairs of
|                        values where the pair is comprised a) a PROC SUMMARY statistic, b) an equals
|                        sign, and c) a valid SAS variable name
|
| CLASSVAR               Passed to the PROC SUMMARY class statement. Computations will be performed     none
|                        for data grouped by these variables. In most cases it is more efficient to
|                        pass all grouping variables (including any across variable(s)) to this
|                        parameter (rather than BYVARS) to perform computations when the default
|                        PSOPTIONS include NWAY or when a value is passed to the PROC SUMMARY TYPES
|                        statement (constructed by default programmatically if the advanced usage
|                        PSTYPES and PSNWAY and PSCLASS are left blank)
|
|                        Valid values: Blank, or the name of one or more variables that exist in DSETIN
|
| COUNTVARNAME           The name to rename the PROC SUMMARY variable _freq_ to when doing counts. If   none
|                        not specified, the _freq_ variable will not be renamed
|
|                        Valid values: Blank, or a valid SAS variable name
|
| TOTALFORVAR            Variable for which total is required within all other grouped classvars        none
|                        (usually trtcd). If not specified, no total will be produced
|
|                        Valid values: Blank if TOTALID is blank, else the name of a variable that
|                        exists in DSETIN.
|
| TOTALID                Value used to populate the variable specified in TOTALFORVAR on data that      none
|                        represents the overall total for the TOTALFORVAR variable.
|                        If no value is specified to this parameter then no overall total of the
|                        TOTALFORVAR variable will be generated.
|
|                        Valid values: Blank if TOTALFORVAR is blank, else a value that can be entered
|                        into &TOTALFORVAR without SAS error or truncation
|
| PSOPTIONS              PROC SUMMARY statement options to use. MISSING ensures that class variables    MISSING COMPLETETYPES NWAY
|                        with missing values are treated as a valid grouping. COMPLETETYPES adds
|                        records showing a freq or n of 0 to ensure a Cartesian product of all class
|                        variables exists in the output.
|
|                        Valid values: Blank, or PROC SUMMARY statement options
|
| PSCLASSOPTIONS         PROC SUMMARY Class statement options.                                          none
|
|                        Valid values: Valid PROC SUMMARY Class options (without the leading '/')
|                        E.g.: PRELOADFMT - which can be used in conjunction with PSFORMAT and
|                        COMPLETETYPES (default in PSOPTIONS) to create records for possible categories
|                        that are specified in a format but which may not exist in data being summarised.
|
| PSOUTPUTOPTIONS        Passed to the PROC SUMMARY Output options statement part.                      NOINHERIT
|
|                        Valid values:
|                        If PSOUTPUT is specified: blank Else: blank, or valid PROC SUMMARY Output
|                        options (without the leading '/')
|
| PSFORMAT               Passed to the PROC SUMMARY FORMAT statement.                                   none
|
|                        Valid values: Blank, or a valid PROC SUMMARY FORMAT statement part.
|
| VARLABELSTYLE          Style of labels to be applied.                                                 SHORT
|
|                        Valid values: As defined by %tu_labelvars
|
| PSBYVARS               Passed to the PROC SUMMARY by statement. This will cause the data to be        none
|                        sorted first.
|
|                        Valid values: Blank, or the name of one or more variables that exist in DSETIN.
|                        DSETIN need not be sorted by &psbyvars
|
| PSCLASS                PROC SUMMARY Class statement, including Class options. Use of this parameter   none
|                        along with &CLASSVARS and/or &PSCLASSOPTIONS is invalid
|
|                        Valid values: Blank, or a valid PROC SUMMARY Class statement, including any
|                        required options, followed by 1 or more complete class statements. e.g.
|                        PSCLASS=%str(var1 var2/preloadfmt; class var3/mlf order=fmt; class var4/mlf;).
|                        The leading "class" must be omitted
|
| PSFREQ                 Passed to the PROC SUMMARY Freq statement                                      none
|
|                        Valid values: Blank, or a valid PROC SUMMARY Freq statement part.
|
| PSTYPES                Passed to the PROC SUMMARY Types statement.                                    none
|
|                        Valid values: Blank, or a valid PROC SUMMARY Types statement part.
|
| PSWAYS                 Passed to the PROC SUMMARY Ways statement.                                     none
|
|                        Valid values: Blank, or a valid PROC SUMMARY WAYS statement part.
|
| PSWEIGHT               Passed to the PROC SUMMARY Weight statement.                                   none
|
|                        Valid values: Blank, or a valid PROC SUMMARY Weight statement part.
|
| PSID                   Passed to the PROC SUMMARY Id statement                                        none
|
|                        Valid values: Blank, or a valid PROC SUMMARY Id statement part.
|
| PSOUTPUT               Passed to the PROC SUMMARY Output statement, including Output options, but     none
|                        excluding any OUT= part.  Note use of this parameter along with &STATSLIST
|                        and/or &PSOUTPUTOPTIONS is invalid
|
|                        Valid values: Blank, or a valid PROC SUMMARY Output statement part, except
|                        for OUT=.
|                        Note: OUT= will be ignored, with warning from SAS.
|
|
| Output:
|   The unit shall produce a PROC SUMMARY type output dataset (&dsetout) containing variables specified in
|   &psByVars and &classvars plus:
|   - frequency counts, if &analysisvar is empty - in variable _freq_  or &countVarName (a rename for _freq_)
|   - summary statistics, if &analysisvar is not empty - in variables indicated by &statslist if &statslist is not empty
|   The number of records can be affected by factors including the following:
|   - Whether creation of total records for the &TOTALFORVAR are requested
|   - &PSOPTIONS, esp use of COMPLETETYPES and NWAY
|   - &PSCLASSOPTIONS, esp use of PRELOADFMT
|   - use of the &STATSLIST parameter: specifying summary statistics names to statslist results in
|     denormalised output from tu_stats (1 column per statistic). However specifying an &ANALYSISVAR
|     without specifying anything to &STATSLIST results in default statistics being produced by PROC
|     summary in a normalised structure (1 statistic per row )
|
|   An optional additional dataset for use in producing cell indices can be produced, containing all
|   records from &dsetin and variables &psByVars and &classVars. If summary statistics are produced
|   for the output dataset then the cell index dataset will contain the N value. If the output of proc
|   summary is solely a frequency count then the output cell index dataset will contain the frequency count.
|
|
| Global macro variables created:
|
|
| Macros called :
| (@)tr_putlocals
| (@)tu_words
| (@)tu_nobs
| (@)tu_chknames
| (@)tu_chkVarsExist
| (@)tu_varAttr
| (@)tu_abort
| (@)tu_labelvars
| (@)tu_quotelst
| (@)tu_putglobals
| (@)tu_tidyup
|
| Example:
|
| Simple Count ;
| %tu_stats(
|     dsetin=statsData
|   , countDistinctWhatVar=subjid
|   , classVars=sex trtcd
|   , dsetout=testOut
|   )
|
| Sumstats, total on trtcd ;
| %tu_stats(
|     dsetin=statsData
|   , classVars=sex trtcd
|   , analysisVar=weight
|   , statslist=N MIN MAX MEDIAN NMISS STD MEAN
|   , totalID=9999
|   , totalforvar=trtcd
|   , dsetout=testOut
|   )
|
| Sumstats, total on trtcd, give names to stats output vars, create variable with label of analysis var:
| %tu_stats(
|     dsetin=statsData
|   , classVars=sex trtcd
|   , analysisVar=weight
|   , statslist= N=N MIN=Minimum MAX=Maximum MEDIAN=Median STD=SD MEAN=Mean
|   , totalID=9999
|   , totalforvar=trtcd
|   , analysisVarName=tt_analy
|   , analysisVarFormatDName=tt_analyFormatd
|   , dsetout=testOut
|   )
|
| Using preloadfmt to create records for categories in format when categories not always in the data:
| proc format; * this could be included in &precode program ;
|    value trtcdf
|        1=1
|        2=2
|        3=3
|        ;
| quit;
| %tu_stats(
|      dsetin=statsData
|    , classVars=sex trtcd;
     , psClassOptions=preloadfmt;
|    , psformat= trtcd trtcdf.
|    , analysisVar=weight
|    , statslist= N=N MIN=Minimum MAX=Maximum MEDIAN=Median STD=SD MEAN=Mean
|    , totalID=9999
|    , totalForVar=trtcd
|    , analysisVarName=tt_group = "Weight"
|    , dsetout=testOut
|    )
|
|
| Using preloadfmt(to create records for categories in format even if not in data )
| and multilabel formats (for making total records)
| proc format;
|    value $racefmt
|        'R'='Rare'
|        ;
|    value mltrtcd (multilabel)
|        1=1
|        2=2
|        3=3
|    1,2,3=9999;
| quit;
| %tu_stats(
|      dsetin=statsData
|    , countDistinctWhatVar=subjid
|    , psclass=sex race/preloadfmt; class trtcd/mlf
|    , psformat=race $racefmt. trtcd mltrtcd.
|    , analysisVarName=tt_group = "Race"
|    , dsetout=testOut
|    )
|
|
|
|
| **************************************************************************
| Change Log :
|
| Modified By :             Yongwei Wang
| Date of Modification :    13-Jul-2004
| New Version Number :      2/1
| Modification ID :         YW001
| Reason For Modification : According to change request HRT0015, if PRELOADFMT
|                           is not the only value in &PSCLASSOPTIONS, the 
|                           macro will create a SAS error. Also, the CLASSVARS
|                           can not have similar name i.e. tt_int and tt_intcd                         
+----------------------------------------------------------------------------
| Change Log :
|
| Modified By :
| Date of Modification :
| New Version Number :
| Modification ID :
| Reason For Modification :
|
+----------------------------------------------------------------------------*/
%macro tu_stats(
      dsetIn=                /* Name of input dataset                                  */
    , dsetOut=               /* Name of output dataset                                 */
    , dsetOutCi=             /* Name of output dataset for cell index                  */
    , analysisVar=           /* Summary statistics analysis variable.  Passed to the PROC SUMMARY Var statement. Blank value implies frequency counts are to be produced. */
    , analysisVarName=       /* Name of variable created to hold the label of the analysis variable. Note that %tu_labelvars is run prior to collecting the label. */
    , analysisVarFormatDName=/* Name of variable created to hold the formatd (decimal places) of the analysis variable.   */
    , statsList=             /* List of required summary statistics. eg N Mean Median. (Or N=BPN MIN=BPMIN)  */
    , countDistinctWhatVar=  /* Variable that contains values to be counted uniquely within any CLASSVARS, PSBYVARS, PSCLASS, and PSTYPES grouping. */
    , classVars=             /* Passed to the PROC SUMMARY class statement             */
    , countVarName=          /* The name to rename the PROC SUMMARY variable _freq_ to when doing counts. */
    , totalForVar=           /* Variable for which a total is required , usually trtcd */
    , totalid=               /* Identifier for total group contained in totalForVar    */
    , psOptions= MISSING COMPLETETYPES NWAY    /* PROC SUMMARY statement options to use           */
    , psClassOptions=        /* PROC SUMMARY class statement options                   */
    , psOutputOptions=NOINHERIT  /* Passed to the PROC SUMMARY Output options Statement part. */
    , psFormat=              /* Passed to the PROC SUMMARY format statement.           */
    , varlabelStyle=short    /* Style of labels to be applied                          */
    , psByVars=              /* Advanced Usage: Passed to the PROC SUMMARY by statement. This will cause the data to be sorted first.  */
    , psClass=               /* Advanced usage: Passed to the PROC SUMMARY class Statement */
    , psFreq=                /* Advanced usage: Passed to the PROC SUMMARY freq Statement  */
    , psTypes=               /* Advanced Usage: Passed to the PROC SUMMARY types statement */
    , psWays=                /* Advanced Usage: Passed to the PROC SUMMARY ways statment.  */
    , psWeight=              /* Advanced Usage: Passed to the PROC SUMMARY weight statement. */
    , psid=                  /* Advanced usage: Passed to the PROC SUMMARY id Statement  */
    , psOutput=              /* Advanced usage: Passed to the PROC SUMMARY output statement */
    );
    /*------------------------------------------------------------------------
    / Write details of macro start to log
    /------------------------------------------------------------------------
    */
    %local MacroVersion;
    %let MacroVersion=2;
    %include "&g_refdata/tr_putlocals.sas";
    %tu_putglobals(varsin = );
    /*--------------------------------------------------------------------------
    / --------------------------------------------------------------------------
    / Declaration and preliminary Set up of local macro variables for use in this macro
    / --------------------------------------------------------------------------
    / --------------------------------------------------------------------------
    */
    %local
        parmsRequired  /* list of required macro parameters             */
        rc             /* return code from process steps                */
        dsid           /* return code from data set open                */
        dsoptstart     /* position in string at which dataset options are specified */
        dsetNameOnly   /* the dset with any dataset options removed  */
        prefix         /* prefix to work data set names                 */
        lastDset       /* name of lastDset created as processing sections optional */
        i              /* counter                                       */
        wordList       /* word list                                     */
        thisWord       /* one word from the list                        */
        doneOne        /* track whether went into loop processing       */
        newWord        /* build tranwrd word                            */
        varsNoExist    /* result of tu_chkvarsexist                     */
        totalForVar_mod  /* adds quotes to totalForVar if char and needed */
        statsListOut   /* stats list statement placed in proc summary output statement */
        makeTotalRecs  /* flag, 1 if this macro will construct statements required
                          for creation of total recs for totals across totalForVar */
        psTypes_nway   /* Proc Summary types statement part for nth way  */
        psTypes_1      /* Proc Summary types statement part for nth way not including totalForVar  */
        varn           /* the number of classvars                         */
        vark           /* the position of the totalForVar in the classVars */
        total_type     /* the _type_ value that identifies the total records */
        psClass_Vars   /* variables within the psClass statement */
        classMod       /* rebuild classVars when simple preloadfmt requested */
        dsetinb4cnt    /* cell index use  */
        keepAnalysisVarName    /* store the variable name part of the &analysisVarName parameter  */
        stopLoop       /* controlling do loops */
        pairs_name     /* for analysing contents of statslist  */
        pairs_value    /* for analysing contents of statslist  */
        pairs_n        /* for analysing contents of statslist  */
        n_name         /* for analysing contents of statslist  */
        ;
    %let prefix=_stats;
    /*---------------------------------------------------------------------------
    / In current version of this macro generation of the below code to
    / generate a cell index dataset is not validated.
    / ---------------------------------------------------------------------------
    */
    %if "&dsetOutCi" ne "" %then %do;
        %put RTE%str(RROR:) &sysmacroname.: Creation of cell index dataset not available in this version of &sysmacroname. Parameter DSETOUTCI=&dsetOutCi, but needs to be blank;
        %put RTN%str(OTE:) &sysmacroname.: A non validated version of code for creating a cell index can be obtained by copying &sysmacroname. to user area and editing out this abort.;
        %goto macerr;
    %end;
    /*---------------------------------------------------------------------------
    / Extract any variables only from psClass, for use in selecting distinct records
    / within a set of variables
    / ---------------------------------------------------------------------------
    */
    %if %length(&psClass) gt 0 %then %do;
        data _null_;
            length pattern $200 psclass result $100;
            psClass = symget('psClass');
            %if &g_debug gt 1 %then %do;
                put 'NOTE: Before ' psclass = ;
            %end;
            length p1-p4 $50;
            /*
            / Match: slash followed by one or more characters that are NOT semicolon,
            /        followed by semicolon or end of string.
            / Change to: semicolon
            /--------------------------------------------------------------------------*/
            p1 = "'/' ~';'* (';'|@0) TO ';'";
            /*
            / Match: Begining of string or semicolon followed by zero or more blanks,
            /        followed by the word CLASS
            / Change to: blank.
            /------------------------------------------------------------------------------*/
            p2 = "(@1|';' ' '*) CLASS $s TO ' '";
            p3 = "';'  TO ' '";  /* Match: semicolon, Change to: blank, same as translate(string,' ',';')*/
            p4 = "' '+ TO ' '";  /* Match: one or more blanks, Change to: blank, same as compbl(sring) */
            do pattern = p1 , p2 , p3 , p4;
                rx = rxparse(trim(pattern));
                call rxchange(rx,9999,trim(psclass),result);
                call rxfree(rx);
                psclass = left(result);
            end;
            %if &g_debug gt 1 %then %do;
                put 'NOTE: AFTER ' psclass=;
            %end;
            call symput('psClass_Vars',psClass);
        run;
        %if &g_debug gt 1 %then %put &sysmacroname: Updated macro var psClass_Vars = &psClass_Vars;
    %end;
    /*--------------------------------------------------------------------------
    / --------------------------------------------------------------------------
    / Parameter Validation
    / --------------------------------------------------------------------------
    / --------------------------------------------------------------------------
    */
    /* Check parms required to have values
    /  --------------------------------------
    */
    %let wordList = dsetin dsetOut  ;
    %do i = 1 %to %tu_words(&wordList);
        %let thisWord = %scan(&wordList, &i);
        %if "&&&thisWord" eq "" %then %do;
            %put RTE%str(RROR:) &sysmacroname.: Macro Parameter %upcase(&thisWord) requires a value: %upcase(&thisWord)=&&&thisWord ;
            %let rc = -1;
        %end;
    %end;
    %if &rc eq -1 %then %goto macerr;
    /* Check names of dsetouts are valid
    /  -----------------------------------
    */
    %let wordList = dsetout dsetoutci;
    %do i = 1 %to %tu_words(&wordList);
        %let thisWord = %scan(&wordList, &i);
        %if "&&&thisWord" ne "" %then %do;
            /* remove any dataset options from the dsetout */
            %let dsOptStart = %index(&&&thisWord, %str(%() ) ;
            %if &dsOptStart gt 0 %then %do;
                %let dsetNameOnly = %substr(&&&thisWord, 1, &dsOptStart - 1 );
            %end;
            %else %do;
                %let dsetNameOnly = &&&thisWord;
            %end;
            %if &g_debug gt 0 %then %put &sysmacroname.: Created Macro Var dsetNameOnly=&dsetNameOnly.. from dsetOut=&dsetOut..;
            /* calling tu_chknames */
            %if %tu_chknames(&dsetNameOnly, DATA ) ne %then %do;
                %put RTE%str(RROR:) &sysmacroname.: Macro Parameter %upcase(&thisWord) refers to dataset &dsetNameOnly which is not a valid dataset name;
                %let rc = -1;
            %end;
        %end;  /* %if "&&&thisWord" ne "" %then %do; */
    %end; /* of checking dsetout and dsetoutci for valid names */
    %if &rc eq 1 %then %goto macerr;
    /* check dsetin exists, can be opened, does not have invalid dataset options
    /  -------------------------------------------------------------------------
    */
   %let dsid = %sysfunc(open(&dsetin, is));
   %if  ( &dsid le 0 ) %then %do;
        %put RTE%str(RROR:) &sysmacroname.: Attempted OPEN of Input dataset DSETIN=&dsetin resulted in: %sysfunc(sysmsg());
        %goto macerr;
    %end;
    %else %do;
        %let rc = %sysfunc(close(&dsid));
        %if ( &rc  ne 0 ) %then %do;
            %put RTE%str(RROR:) &sysmacroname.: Attempted CLOSE of Input dataset DSETIN=&dsetin resulted in: %sysfunc(sysmsg());
            %goto macerr;
        %end;
    %end;
    /* Check dsetin contains required variables
    /  ----------------------------------------
    */
    /* create temp dataset first, applying the dataset options */
    data &prefix._dsetin;
        set &dsetin;
        if _n_ eq 1;
    run;
    /* calling tu_chkVarsExist */
    %if %length(&classVars.&psByVars.&countDistinctWhatVar.&psClass_vars.&totalForVar.&analysisVar) ne 0 %then %do;
        %let varsNoExist = %tu_chkVarsExist(&prefix._dsetin, &classVars &psByVars &countDistinctWhatVar &psClass_vars &totalForVar &analysisVar );
        %if "&varsNoExist" ne "" %then %do;
            %put RTE%str(RROR:) &sysmacroname.: Macro Parameters lists variables not existing in &dsetIn: &varsNoExist.;
            %goto macerr;
        %end;
    %end;
    /* If &analysisVar is empty then a count rather than summary statistics
    /  is required so issue error if &statslist is not empty.
    /  --------------------------------------------------------------
    */
    %if "&statslist" ne "" and "&analysisVar" eq "" %then %do;
       %put RTE%str(RROR:) &sysmacroname.: Statistics have been requested (statslist=&statslist) but no analysisVar has been specified (analysisVar=&analysisVar);
       %goto macerr;
    %end;
    /* If totalForVar specified but not totalID specified then
    /  issue RTW-ARNING and default totalID to 9999
    /  --------------------------------------------------------
    */
    %if &totalForVar ne and &totalID eq %then %do;
      %put RTW%str(ARNING:) &sysmacroname.: TotalID not specified yet totals were requested via totalForVar..;
      %put RTN%str(OTE:) &sysmacroname.: TotalID defaulted to 9999;
      %let totalID=9999;
    %end;
    /* If totalID is specified then a totalForVar must be specified.
    /  --------------------------------------------------------------
    */
    %if "&totalID" ne "" and "&totalForVar" eq "" %then %do;
       %put RTE%str(RROR:) &sysmacroname.: Parameter TOTALFORVAR is empty yet TOTALID=&totalID is not empty indicating PROC SUMMARY totals across a variable are required.;
       %put RTN%str(OTE:) &sysmacroname.: Specify the TOTALFORVAR in which the TOTALID will be entered.;
       %goto macerr;
    %end;
    /* Check totalID value does not already exist in the totalForVar.
    /  Ensure this step follows default setting of totalID.
    /  -------------------------------------------------------------
    */
    /* find the datatype of the totalForVar  */
    %if "&totalID" ne "" %then %do;
        %let totalID_mod = &totalID;
        %if %index(&totalID, %str(%") ) eq 0 %then %do;
            %let totalForVarDataType = %tu_varAttr(&dsetin, &totalForVar, vartype);
            %if &totalForVarDataType eq C %then %let totalID_mod = "&totalID";
        %end;
        %if &g_debug gt 1 %then %put &sysmacroname Created macro variable TOTAL_ID_MOD=&totalID_mod;
        data &prefix._1;
            set &dsetin (where=(&totalForVar=&totalID_mod));
        run;
        %if %tu_nobs(&prefix._1) gt 0 %then %do;
            %put RTE%str(RROR:) &sysmacroname.: TOTALID=&totalid specifies a value already existing in &dsetin..&totalForVar ;
            %put RTN%str(OTE:) &sysmacroname.: The parameter TotalID specifies a value of the totalForVar used to identify Proc Summary output ... ;
            %put RTN%str(OTE:) ... records that are a total over the totalForVar, so the totalID value must not preexist;
            %goto macerr;
        %end;
    %end;
    /* Cannot specify psClass with classVars or psClassOptions
    /  -------------------------------------------------------
    */
    %if "&psClass" ne "" and ("&classVars" ne "" or "&psClassOptions" ne "" ) %then %do;
        %put RTE%str(RROR:) &sysmacroname.: When specifying values to PSCLASS then parameters CLASSVARS and PSCLASSOPTIONS must be blank (put everything into psClass);
        %put RTN%str(OTE:) &sysmacroname.: PSCLASS=&psClass  CLASSVARS=&classVars PSCLASSOPTIONS=&psClassOptions;
        %goto macerr;
    %end;
    /* Cannot specify psOutput with statslist or psOutputOptions
    /  ---------------------------------------------------------
    */
    %if "&psOutput" ne "" and ("&statslist" ne "" or "&psOutputOptions" ne "" ) %then %do;
        %put RTE%str(RROR:) &sysmacroname.: When specifying values to PSOUTPUT then parameters STATSLIST and PSOUTPUTOPTIONS must be blank (put everything into psOutput);
        %put RTN%str(OTE:) &sysmacroname.: PSOUTPUT=&psOutput STATSLIST=&statslist PSOUTPUTOPTIONS=&psOutputOptions;
        %goto macerr;
    %end;
    /* If &totalForVar is not missing and the variable specified in
    /  &totalForVar is not contained in &classvars then
    /  put RTW-ARNING to the log and append &totalForVar to &classVars
    /  -------------------------------------------------------------
    */
    %if "&classVars" ne "" and "&totalforVar" ne "" %then %do;
        %if %index(%tu_quotelst(&classvars), "&totalForVar") eq 0 %then %do;
            %put RTW%str(ARNING:) &sysmacroname.: Total records were requested via totalForVar but this variable was not specified as a classvar;
            %put RTN%str(OTE:) &sysmacroname.: &totalforVar has been added to macro parameter CLASSVARS: CLASSVARS=&classvars;
            %let classvars=&classvars &totalForVar ;
            %if &g_debug gt 1 %then %put &sysmacroname: Updated macro parameter: CLASSVARS=&classvars ;
        %end;
    %end;
    /* call tu_abort to exercise execution control if results from earlier function macro calls produced errors */
    %tu_abort();
    %if &g_debug gt 1 %then %put &sysmacroname: Completed Parameter validation section;
    /*--------------------------------------------------------------------------
    / --------------------------------------------------------------------------
    / Further Set up of macro variables required for use in this macro
    / --------------------------------------------------------------------------
    / --------------------------------------------------------------------------
    */
    /*---------------------------------------------------------------------------
    / Set a flag to indicate whether default creation of total records required
    / ---------------------------------------------------------------------------
    */
    %if ("&psClass" eq "") and ("&psTypes" eq "") and ("&psWays" eq "") and
        ("&totalForVar" ne "") and ("&totalID" ne "") and ("&classVars" ne "")
        %then %let makeTotalRecs = 1;
    %if &g_debug gt 1 %then %put &sysmacroname.: Macro var makeTotalRecs=&makeTotalRecs;
    /* if not able to do make total recs issue RTEr-ror if user specified a totalid */
    %if &makeTotalRecs ne 1 and "&totalID" ne "" %then %do;
        %put RTE%str(RROR:) &sysmacroname.: TOTALID=&TOTALID however total records cannot be created.;
        %put RTN%str(OTE:) &sysmacroname.: Total records cannot be created when advanced usage PROC SUMMARY parameters have beeen specified;
        %put RTN%str(OTE:) &sysmacroname.: PSCLASS=&psClass  CLASSVARS=&classVars PSCLASSOPTIONS=&psClassOptions;
        %goto macerr;
    %end;
    /*-------------------------------------------------------------------------------------------
    / Construct the TYPES statement if required/possible. And determine the _type_ value
    / that PROC SUMMARY will assign to output records for the total over the totalForVar.
    / This is done only if nothing is specified to the parameters psTypes and psWays
    / and totals are requested for a totalForVar and there is at least one classVar (which may be
    / the totalForVar)
    /-------------------------------------------------------------------------------------------
    */
    %if &makeTotalRecs eq 1 %then %do;
        /* construct types statement part for the nth way */
        %do i = 1 %to %tu_words(&classVars);
            %let thisClassVar = %scan(&classVars, &i);
            %if &i eq 1 %then %let psTypes_nway = &thisClassVar;
            %else %let psTypes_nway = &psTypes_nway.*&thisClassVar.;
        %end;
        %if &g_debug gt 1 %then %put &sysmacroname.: Macro Var created with value : psTypes_nway= &psTypes_nway;
        /* construct types statement part for the nth way for vars excluding the TOTALFORVAR */
        /* work out position of totalForVar in classVars and make a string of classVars not including totalForVar */
        %do j = 1 %to %tu_words(&classVars);
            %let thisClassVar=%scan(&classVars, &j);
            %if %upcase(&totalForVar) eq %upcase(&thisClassVar) %then %let vark = &j;
            %else %let psTypes_1 = &psTypes_1 &thisClassVar;
        %end;
        %if &g_debug gt 1 %then %put &sysmacroname.: Macro Var created : vark= &vark;
        %if &g_debug gt 1 %then %put &sysmacroname.: Macro Var created : psTypes_1= &psTypes_1;
        %let varn = %eval(&i-1);   /* hold the total number of class vars */
        %if &g_debug gt 1 %then %put &sysmacroname.: Macro Var created : varn= &varn;
        /* construct the types statement */
        %if "&psTypes_1" eq "" %then %let psTypes = &psTypes_nway ();
        %else %let psTypes = &psTypes_nway %sysfunc( tranwrd( &psTypes_1, %str( ), %str(*) ) );
        %if &g_debug gt 1 %then %put &sysmacroname.: Macro Parameter updated : psTypes= &psTypes;
        /*------------------------------------------------------------------------------
        / And Determine the _type_ variable value that will be produced by proc summary
        /------------------------------------------------------------------------------
        */
        %let total_type_ = 0;
        %do i = 1 %to &vark;
            %let total_type_ = %eval( &total_type_ + 2**(&varn - &i) );
        %end;
        %let total_type_ = %eval(&total_type_ - 1);
        %if &g_debug gt 1 %then %put &sysmacroname.: Macro Var created : total_type_= &total_type_;
    %end;  /* of  &makeTotalRecs eq 1 %then %do;  */
    /*---------------------------------------------------------------------------
    / If the list of statistics required does not conform to the syntax
    / required by proc summary, then create the Out StatsList for the
    / proc summary output statement N=N MEAN=MEAN etc...
    /----------------------------------------------------------------------------
    */
    %if %index("&statslist",%str(=)) eq 0 %then %do;
        %do i=1 %to %tu_words(&statslist);
            %let statsListOut = &statsListOut %scan(&statslist, &i)=%scan(&statslist, &i);
        %end;
    %end;
    %else %do;
        %let statslistOut = &statsList;
    %end;
    /*---------------------------------------------------------------------------
    / When user has specified &psClassOptions=preloadfmts then form the class
    / statement to avoid sas 8.2 warning.
    /  Whats needed is the breaking up of the class statement to append
    /  the /preloadfmts option after the variable
    /  being formatted.
    / YW001: Modify the code to make it work while &PSCLASSOPTIONS has other
    /        value(s) besides PRELOADFMT.
    /----------------------------------------------------------------------------
    */
    
    %let classmod=;   /* modified class statement */
     
    data _null_;
       length psclassoptions classmod psformat classvars str thisclass preloadoptions $1000;
       psclassoptions=symget('psclassoptions');
       psformat=symget('psformat');
       classvars=symget('classvars');
      
       /* If PRELOADFMT is not in the class options, then stop */
       ind=indexw(upcase(psclassoptions), 'PRELOADFMT');       
       if ( ind lt 1 ) or (classvars eq '') then stop;
      
       /* Remove all PRELOADFMT from PSCLASSOPTIONS */
       do while(ind gt 0);
          if ind gt 1 then str=substr(psclassoptions, 1, ind - 1);
          else str='';
          
          psclassoptions=trim(left(str))||substr(psclassoptions, ind + 10);          
          ind=indexw(upcase(psclassoptions), 'PRELOADFMT');       
       end; /* end of do-while loop */
       
       preloadoptions='/preloadfmt '||trim(left(psclassoptions));           
       if psclassoptions ne '' then psclassoptions='/'||left(psclassoptions);
      
       /* 
       /  loop over CLASSVARS to add class options. If a class variable is in the 
       /  PSFORMAT, set flag equals 1. Otherwise set to 2.
       /--------------------------------------------------------------------------*/ 
       i=1;
       flag=0;       
       thisclass='';       
       classmod='';     
       str=scan(classvars, i, ' ');
       do while (str ne '');                    
          if indexw(upcase(psformat), upcase(str)) gt 0 then do;
             if (flag eq 2) then do;
                link addopt;
             end;               
                         
             flag=1;
          end;
          else do;
             if (flag eq 1) then do;      
                link addopt;
             end;
                             
             flag=2;
          end; /* end-if on indexw(upcase(psformat), upcase(str)) gt 0  */
        
          thisclass=trim(left(thisclass))||' '||trim(left(str));
        
          i=i+1;
          str=scan(classvars, i, ' ');             
       end;  /* end of do-while loop */
       
 
       link addopt;        
       call symput('classmod', trim(left(classmod)));
       return;
       
    ADDOPT:
       /* If flag equals 1 add class options with PRELOADFMT */
       if (flag eq 2) then 
          thisclass=trim(left(thisclass))||trim(left(psclassoptions));    
       else if (flag eq 1) then 
          thisclass=trim(left(thisclass))||trim(left(preloadoptions));      
   
       if classmod ne '' then 
          classmod=trim(left(classmod))||"; class "||trim(left(thisclass));
       else
          classmod=trim(left(thisclass));
       
       thisclass='';             
       return;
    run;
    /*--------------------------------------------------------------------------
    / --------------------------------------------------------------------------
    / DO THE COUNTING/SUMSTATS;
    / --------------------------------------------------------------------------
    / --------------------------------------------------------------------------
    */
    /*
    / If countDistinctWhatVar contains variable(s) then select distinct records
    / within byVars and classVars
    / ----------------------------------------------------------------------------
    */
    %if "&countDistinctWhatVar" ne "" %then %do;
        proc sort data=&dsetin out=&prefix._distinct nodupkey;
                by &psByVars &classVars &psClass_Vars &countDistinctWhatVar; /* only one of &classVars and psClass_Vars can be populated */
        run;
        %let lastDset = &prefix._distinct;
    %end;
    %else %let lastDset = &dsetin;
    /* Sort the data if needed
    /  ---------------------------------------------------------------------------
    */
    %if "&psByVars" ne "" %then %do;
        proc sort data=&lastDset out=&prefix.dsetin_s;
            by &psByVars;
        run;
        %let lastDset = &prefix.dsetin_s;
    %end;
    /* Proc summary statement performs the counting / statistics calculations */
    proc summary data=&lastDset &psOptions;
        %if "&psByVars" ne "" %then %do;
            by &psByvars;
        %end;
        %if %length(&classMod) gt 0 %then %do;
            class &classMod;
        %end;
        %else %if %length(&psClass) gt 0 %then %do;
            class &psClass;            
        %end;
        %else %if "&classVars" ne "" %then %do;
            class &classVars / &psClassOptions ;
        %end;
        %if "&analysisVar" ne "" %then %do;
            var &analysisVar;
        %end;
        %if "&psTypes" ne "" %then %do;
            types &psTypes;
        %end;
        %if "&psWays" ne "" %then %do;
            ways &psWays;
        %end;
        %if "&psWeight" ne "" %then %do;
            weight &psWeight;
        %end;
        %if "&psFreq" ne "" %then %do;
            freq &psFreq;
        %end;
        %if "&psID" ne "" %then %do;
            id &psID;
        %end;
        %if &psFormat ne %then %do;
            format &psFormat;
        %end;
        /* not writing to &dsetout because it could have renames of variables on it - need
           raw names for making cell index */ ;
        output out=&prefix._summary %if "&psOutput" eq "" %then %do;
                                        &statslistOut /&psOutputOptions
                                    %end;
                                    %else %do;
                                        &psOutput
                                    %end;
                                    ;
    run;
    /** UPDATED : Next 20 lines have been added **/
    %if &syserr eq 0 %then %do;
      /* successful completion, no action necessary  */
    %end;
    %else %if &syserr eq 4 %then %do;
      %put RTW%str(ARNING:) &sysmacroname.: A warning was issued by PROC SUMMARY.;
      %put RTW%str(ARNING:) &sysmacroname.: Check the parameters passed to &sysmacroname.;
    %end;
    %else %if &syserr ge 8 %then %do;
      %put RTE%str(RROR:) &sysmacroname.: PROC SUMMARY ended with errors, output data set (&DSETOUT) was not created successfully.;
      %goto macerr;
    %end;
    %else %do;
      %put RTE%str(RROR:) &sysmacroname.: PROC SUMMARY ended with an undocumented return code (&syserr).;
      %put RTE%str(RROR:) &sysmacroname.: Contact SAS Institute technical support.;
      %goto macerr;
    %end;
    %let lastDset = &prefix._summary;
    /*----------------------------------------------------------------------------
    / Mark Total Records with &totalID in the &TOTALFORVAR if required;
    /----------------------------------------------------------------------------
    */
    %if &makeTotalRecs eq 1 %then %do;
        /* Cant do this if user specified chartype in the options as this puts a
           we are looking for a numeric value in the _type_ var
        */
        %if %index( %upcase(&psOptions, CHARTYPE) ) gt 0 %then %do;
            %put RTE%str(RROR:) Unable to update total records with TOTALID value as PSOPTIONS includes CHARDATA;
            %goto macerr;
        %end;
        data &prefix._total;
            set &lastDset;
             if _type_ in (&total_type_ ) then &totalForVar = &totalID_mod;
        run;
        %let lastDset = &prefix._total;
    %end;
    /*----------------------------------------------------------------------------------
    / ----------------------------------------------------------------------------------
    / If performing summary statistics then Add variables containing info on the analysis Var:
    /            - the name/description
    /            - the number of decimal places in the format (vformatd)
    /----------------------------------------------------------------------------------
    /----------------------------------------------------------------------------------
    */
    %if "&analysisVarName" ne "" or "&analysisVarFormatDName" ne "" %then %do;
        %if "&analysisVarName" ne "" %then %do;
            %if %index("&analysisVarName", %str(=)) eq 0 %then %do;
                %let varsNoExist = %tu_chkVarsExist(&lastDset, %scan(&analysisVarName,1) &analysisVarFormatDName );
                %if "&varsNoExist" eq "" %then %do;
                    %put RTW%str(ARNING:) &sysmacroname.: One or more of the following variable: %scan(&analysisVarName,1) &analysisVarFormatDName, from DSETIN=&dsetin, will be overwritten.;
                %end;
                %if "&varLabelStyle" eq "" %then %do;
                    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter VARLABELSTYLE requires a value: VARLABELSTYLE=&varLabelStyle;
                    %goto macerr;
                %end;
                %tu_labelvars(dsetin=&prefix._dsetin, style=&varLabelStyle, dsetout=&prefix._dsetin)
                %let keepAnalysisVarName = &analysisVarName;
            %end;
            %else %do;
                /* parm analysisVarName holds an assignment statements  */
                %let keepAnalysisVarName = %substr("&analysisVarName", 2, %index("&analysisVarName", %str(=)) -2);
                /* calling tu_chknames to ensure name specified is valid variable name */
                %if %tu_chknames(&keepAnalysisVarName, VARIABLE ) ne %then %do;
                    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ANALYSISVARNAME=&analysisVarName refers to an invalid variable name &keepAnalysisVarName.;
                    %goto macerr;
                %end;
            %end;
            %if &g_debug gt 1 %then %put &sysmacroname: Updated macro variable: keepAnalysisVarName=&keepAnalysisVarName ;
        %end;
        data &prefix._analysisVarInfo(keep=&keepAnalysisVarName &analysisVarFormatDName);
            set &prefix._dsetin;
            if _n_ = 1;
            %if "&analysisVarName" ne "" %then %do;
                %if %index("&analysisVarName", %str(=)) gt 0 %then %do;
                    &analysisVarName ;
                %end;
                %else %do;
                    &analysisVarName=vlabel(&analysisVar);
                %end;
            %end;
            %if "&analysisVarFormatDName" ne "" %then %do;
               attrib &analysisVarFormatDName format= 8.;
               &analysisVarFormatDName = vformatd(&analysisVar);
            %end;
        run;
        /* attach the analysisVarInfo to every record on summarised data  */
        proc sql;
            create table &prefix._withAnalyInfo as
            select *
            from &lastDset,
                 &prefix._analysisVarInfo
            ;
        quit;
        %let lastDset = &prefix._withAnalyInfo;
    %end; /* of "&analysisVarName" ne "" or "&analysisVarFormatD" ne "" %then %do; */
    
    /*----------------------------------------------------------------------------
    / Produce the cell index if requested
    / Note that in Version 1 of this macro the creation of a cell index dataset is not
    / validated or tested. 
    /----------------------------------------------------------------------------*/
    %if "&dsetOutCi" ne "" %then %do;
        %if "&psClass" ne "" %then %do;
            %put RTE%str(RROR:) &sysmacroname.: Unable to produce a cell index dataset when parameter PSCLASS is specified.;
            %put RTN%str(OTE:) &sysmacroname.: A cell index can still be produced by using stand alone functionality of %tu_cellindex.;
        %end;
        /* stack input data where total required */
        %if &totalID ne %then %do;
            data &prefix._ci_dsetinTot;
                set &dsetin;
                &totalforvar = "&totalID";
            run;
            data &prefix._ci_dsetinb4cnt;
                set &dsetin
                    &prefix._ci_dsetinTot;
            run;
            %let dsetinb4cnt = &prefix._ci_dsetinb4cnt;
        %end;
        %else %let dsetinb4cnt = &dsetin;
        %if "&classVars" ne "" or "&psByVars" ne "" %then %do;
            proc sort data=&dsetinb4cnt out=&prefix._ci_dsetinb4cnt_s;
                by &psByVars &classVars;
            run;
            %let dsetinb4cnt=&prefix._ci_dsetinb4cnt_s;
        %end;
        /*--------------------------------------------------------------------
        / Form the keep statement to keep vars required on summarised data
        / and check that n has been requested as a statistic if sumstats
        /-------------------------------------------------------------------*/
        %if "&analysisVar" ne "" %then %do;
            /* find out the name of n variable, which may have been renamed in &statslist as n=Bign etc */
            /* create macro array of name value pairs */
            %let stopLoop = 0;
            %let pairs_name=;
            %let pairs_value=;
            %let i=0;
            /* translate any '=' in the pairs to ' = '  */
            %let pairs_remainder = %qsysfunc( tranwrd(%nrbquote(&statslist), %str(=), %str( = ) ) );
            %if &g_debug gt 1 %then %put &sysmacroname.: my quoted pairs_remainder="&pairs_remainder";
            %do %until(&stopLoop=1);
                %let i = %eval(&i + 1);
                %if &g_debug gt 1 %then %put &sysmacroname.: i=&i;
    
                /* get the name part */
                %let pairs_name&i = %qscan( &pairs_remainder, 1 );
                %if &g_debug gt 1 %then %put &sysmacroname.: pairs_name&i=&&pairs_name&i; 
    
                /* strip of the name part before analysing the rest */
                %if %length(&pairs_remainder) gt %length( %scan(&pairs_remainder, 1) ) %then %let pairs_remainder = %substr(&pairs_remainder, %length( %scan(&pairs_remainder, 1) ) +1 );
                %else %let pairs_remainder=;
                %if &g_debug gt 1 %then %put &sysmacroname.: my quoted pairs_remainder="&pairs_remainder";
    
                /* if nothing left in the string then set no value for this name and stopLoop=1 */ 
                %if "&pairs_remainder" eq "" %then %do;
                    %let stopLoop = 1;
                    %let pairs_value&i =;
                    %if &g_debug gt 1 %then %put &sysmacroname.: pairs_value&i=&&pairs_value&i; 
                %end;
                %else %if "%scan( &pairs_remainder, 1 )" ne "=" %then %do;
                    /* else if the next word is not an = then must be no value for this name, must be start of new name */
                    %let pairs_value&i =;
                    %if &g_debug gt 1 %then %put &sysmacroname.: Blank value creation: pairs_value&i=&&pairs_value&i; 
                %end;
                %else %do;
                    /* the next word is an = so should be a following word to write to value part  */
    
                    /* remove the = */
                    %let pairs_remainder = %substr(&pairs_remainder, %length( %qscan(&pairs_remainder, 1) ) +1 );
                    %if &g_debug gt 1 %then %put &sysmacroname.: Non blank value creation: my quoted pairs_remainder="&pairs_remainder";
    
                    %if "&pairs_remainder" eq "" %then %do;
                        %let pairs_value&i =;
                        %if &g_debug gt 1 %then %put &sysmacroname.: Blank value creation after = sign: pairs_value&i=&&pairs_value&i; 
                    %end;
                    %else %do;
                        /* write the value part to macro var */
                        %let pairs_value&i = %scan(&pairs_remainder, 1) ;
                        %if &g_debug gt 1 %then %put &sysmacroname.: pairs_value&i=&&pairs_value&i;
    
                        /* remove the value part */
                        %if %length(&pairs_remainder) gt %length( %scan(&pairs_remainder, 1) ) %then %let pairs_remainder = %substr(&pairs_remainder, %length( %scan(&pairs_remainder, 1) ) +1 );
                        %else %let pairs_remainder=;
                        %if &g_debug gt 1 %then %put &sysmacroname.: my quoted pairs_remainder="&pairs_remainder";
    
                        /* if nothing left then set stopLoop */
                        %if "&pairs_remainder" eq "" %then %let stopLoop=1;
                    %end;  /*  of writing value part to macro var */
    
                %end;  /*  of dealing with = sign after name part  */
    
            %end;  /*  of %do %until(&stopLoop=1)    */
            %let pairs_n = &i;
            %if &g_debug gt 1 %then %put &sysmacroname.: pairs_n=&pairs_n;
            /* find any rename of the n */
            %do i = 1 %to &pairs_n;
                %if "%upcase(&&pairs_name&i)" eq "N" %then %do;
                    %if "&&pairs_value&i" ne "" %then %let n_name = &&pairs_value&i;
                    %else %let n_name = n;
                    %if &g_debug gt 1 %then %put &sysmacroname: Updated local macro variable: pairs_n=&pairs_n;
                %end;
            %end; 
            %if "&n_name" ne "" %then %do;
                %let keepci = &classVars &n_name;
                %if &g_debug gt 1 %then %put &sysmacroname: Updated value of local macro variable: keepci=&keepci;
            %end;
            %else %do;
                %put RTE%str(RROR): Cell index data requested for summary statistics output but N was not requested as a statistic ;
                %put RTN%str(OTE): No cell index data is able to be produced;
                %goto macerr;
            %end;
        
        %end;
        %else %do;
            %* must have been called to count;
            %let keepci =  &classVars _freq_;
        %end;
        %if "&classVars" ne "" or "&psByVars" ne "" %then %do;
            proc sort data=&lastDset(keep=&keepci) out=&prefix._statsForCel;
                by &psByVars &classVars;
            run;
        %end;
        %else %do;
            data &prefix._statsForCel;
                set &lastDset(keep=&keepci);
            run;
        %end;
        /*--------------------------------------------------------------------
        / Put the dsetin data together with count/stats
        /-------------------------------------------------------------------*/
        data &dsetOutci;
            %if "&classVars" ne "" or "&psByVars" ne "" %then %do;
                merge &dsetinb4cnt
                    &prefix._statsForCel;
                  by  &psByVars &classVars;
            %end;
            %else %do;
                set
                    %do i=1 %to %tu_nobs(&dsetinb4cnt);
                        &prefix._statsForCel
                    %end;
                    ;
                merge &dsetinb4cnt;
            %end;
        run;
    %end;
    /*---------------------------------------------------------------------------
    / ---------------------------------------------------------------------------
    / Create summary output dataset to name and options requested by user
    / --------------------------------------------------------------------------
    / ---------------------------------------------------------------------------
    */
    
    data &dsetout;
        set &lastDset
            %if "&countVarName" ne "" %then (rename=(_freq_=&countVarName));
        ;
    run;
    %if &syserr GT 0 %then %do;
      %put RTE%str(RROR:) &sysmacroname: Creation of dsetout=&dsetout caused an error.;
      %goto macerr;
    %end;
  %goto macend;
    /*---------------------------------------------------------------------------
    / Finish Up
    /--------------------------------------------------------------------------
    */
  %macerr:
    %let g_abort=1;
    %put RTN%str(OTE:) The value of g_abort=&g_abort. This macro will now abort;
    %tu_abort();
  %macend:
    %tu_tidyup(rmdset=&prefix.:, glbmac=none);
    %if &g_debug gt 1 %then %put Exiting &sysmacroname;
%mend tu_stats;
