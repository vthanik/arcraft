/*--------------------------------------------------------------------------+
| Macro Name    : tu_denorm.sas
|
| Macro Version : 3
|
| SAS version   : SAS v8.2
|
| Created By    : Todd Palmer
|
| Date          : 21-May-2003
|
| Macro Purpose : Perform 1 or more transposes of data, primarily for the purpose
|                 of creating table display across columns and columns used for
|                 sorting table displays.
|
| Macro Design  : Procedure Style.
|
| Input Parameters :
|
| NAME                  DESCRIPTION                                                DEFAULT
|
| DSETIN                Specifies the input data set to be transposed.             none
|
|                       Valid values
|
|                       Name of a SAS dataset, with no duplicate values of the
|                       variables specified in GROUPBYVARS and ACROSSVARS.
|
| DSETOUT               Specifies the output data set.                             none
|
|                       Valid values
|
|                       SAS dataset name
|
| GROUPBYVARS           Specifies a list of optional BY variables.                 none
|
|                       Valid values
|
|                       Blank, or name(s) of one or more variables on dataset
|                       DSETIN.
|
| VARSTODENORM          List of variables to be denormalised / transposed.         none
|                       Passed one at a time to the PROC TRANSPOSE VAR statement
|
|                       Valid values
|
|                       Name(s) of one or more variables on dataset DSETIN.
|
| ACROSSVAR             Specifies the PROC TRANSPOSE ID variable.  The values of   none
|                       this variable are used to name the new variables.
|
|                       Valid values
|
|                       Name of one variable on dataset DSETIN.
|
| ACROSSVARLABEL        Specifies a variable to use to create the labels for the   none
|                       transpose variables.
|
|                       Valid values
|
|                       Blank, or name of one variable on dataset DSETIN.
|
| ACROSSCOLVARPREFIX    Specifies the prefix(es) used in forming the names of      none
|                       variables created by PROC TRANSPOSE. Any list of prefixes
|                       will be associated with the corresponding variable in
|                       VARSTODENORM. If nothing is specified to
|                       ACROSSCOLVARPREFIX or a prefix corresponding to a variable
|                       in VARSTODENORM does not exist then the name of the
|                       variable in VARSTODENORM is used as a prefix. The
|                       following example may make this clearer:  Multiple
|                       variables in VARSTODENORM cause multiple calls to
|                       PROC TRANSPOSE. Each call to proc transpose results in a
|                       different variable being passed to the PROC TRANSPOSE
|                       PREFIX statement. If there are 2 variables specified in
|                       VARSTODENORM then on the second call to PROC TRANSPOSE
|                       the second variable listed in ACROSSCOLVARPREFIX will be
|                       passed to the PROC TRANSPOSE PREFIX statement. If no
|                       second variable is specified to ACROSSCOLVARPREFIX then
|                       the name of the second variable in VARSTODENORM will be
|                       passed to the PROC TRANSPOSE PREFIX statement. In this
|                       case if a third variable is specified to
|                       ACROSSCOLVARPREFIX, it will have no effect.
|                       Note on use of prefix in Reporting Tools: PROC REPORT
|                       COLUMNS statement accepts a variable prefix in the form eg
|                       myCol: to display all columns whose name commences with the
|                       prefix.
|
|                       Valid values
|
|                       Blank, or one or more words, each word comprising of
|                       characters permitted in the first section of a SAS
|                       variable name.
|                       Total number of words should be less than or equal to the
|                       number of variables specified in VARSTODENORM.
|
| ACROSSVARLISTNAME     Specifies the name of the macro variable that %TU_DENORM   none
|                       will update with the names of the variables created by
|                       the transpose of the first variable that is specified in
|                       VARSTODENORM. In most cases the macro variable is LOCAL
|                       to the program that called %tu_DENORM.
|
|                       Valid values
|
|                       SAS macro variable name.
|
|
|
| Output: Dataset containing denormalised (transposed) data
|         A Global macro variable containing the names of the first sequence of normalised columns created
|
|
| Macros called :
|     (@) tr_putlocals
|     (@) tu_nobs
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
|     %tu_DENORM(
|      dsetin=myDataIn
|    , varsToDenorm=tt_result tt_pct
|    , groupByVars=aeptcd aept
|    , acrossVar=trtcd
|    , acrossVarLabel=
|    , acrossColVarPrefix=tt_result tt_pct
|    , acrossVarListName= acrossColList
|    , dsetout=myDataOut
|    );
|
|
| **************************************************************************
| Change Log :
|
| Modified By :             Yongwei Wang
| Date of Modification :    02-Jun-2004
| New Version Number :      2/1
| Modification ID :         YW001
| Reason For Modification : To make it work for multiple across variables
+----------------------------------------------------------------------------
| Modified By :             Shivam Kumar
| Date of Modification :    21-OCT-2013
| New Version Number :      3/1
| Modification ID :
| Reason For Modification : To remove repeated %then 
|
+----------------------------------------------------------------------------*/
%macro  tu_DENORM(
      dsetin=         /* Input data set    */
    , varsToDenorm=   /* List of variables to be denormalised/transposed. Passed one at a time to the PROC TRANSPOSE VAR statement.   */
    , groupByVars=    /* List of BY variables passed to PROC TRANSPOSE BY statement.  */
    , acrossVar=      /* Variable used in the PROC TRANSPOSE ID statement.  */
    , acrossVarLabel= /* Variable used in the PROC TRANSPOSE IDLABEL statement. */
    , acrossColVarPrefix= /* Text passed to the PROC TRANSPOSE PREFIX statement. */
    , acrossVarListName=  /* Macro variable name to contain the list of columns created by the transpose of the first variable in VARSTODENORM.*/
    , dsetout=        /* Output data set  */
    );
    /*---------------------------------------------------------------------------
    / Write details of macro start to log
    / ---------------------------------------------------------------------------
    */
    %local MacroVersion;
    %let MacroVersion = 3;
    %include "&g_refdata/tr_putlocals.sas";
    %tu_putglobals(varsin=)
    /*--------------------------------------------------------------------------
    / Set up macro variables for use in this macro
    / --------------------------------------------------------------------------
    */
    %local
        wordList  /* list of required macro parameters             */
        rc             /* return code from process steps                */
        dsetIn_dset    /* the dsetin with any dataset options removed   */
        dsetOut_dset   /* the dsetOut with any dataset options removed  */
        workroot       /* value of work data set name root              */
        work0          /* work data set name                            */
        work1          /* work data set name                            */
        work2          /* work data set name                            */
        work3          /* work data set name                            */
        work4          /* work data set name                            */
        work5          /* work data set name                            */
        work6          /* work data set name                            */
        workdups       /* data set of found duplicates                  */
        mergelist      /* list of data sets                             */
        coln           /* the number of across columns made at each transpose  */
        prefix         /* for i ge 2 this is the denorm var + prefix    */
        i              /* counter                                       */
        j              /* counter                                       */
        w              /* word                                          */
        trtlist        /* list of names created by PT                   */
        dupflag        /* 1=has dups 0=does not                         */
        unresolvedlist /* holds the variable names list                 */
        thisPrefix     /* one prefix from prefix list                   */
        prefixlength   /* YW001: max length of prefixes                 */
        acrossvarsnum  /* YW001: number of across variables             */
        varprefix      /* YW001: prefix for temporary variables         */
        ;
    %let dupflag   = 0;
    %let workroot  = _DENORM;
    %let work0     = work.&workroot.work0;
    %let work1     = work.&workroot.work1;
    %let work2     = work.&workroot.work2;
    %let work3     = work.&workroot.work3;    
    %let work4     = work.&workroot.work4;    /* YW001 */
    %let work5     = work.&workroot.work5;    /* YW001 */
    %let work6     = work.&workroot.work6;    /* YW001 */
    %let workdups  = work.&workroot.dups;
    %let varprefix = __tmp_var_prefix_;       /* YW001 */
    /*--------------------------------------------------------------------------
    / Parameter Validation
    / --------------------------------------------------------------------------
    */
    /* Make sure macro parameters have something specified
    /  ---------------------------------------------------
    */
    %let wordList = dsetin varsToDeNorm acrossVar dsetout;
        %do i = 1 %to %tu_words(&wordList);
        %let thisWord = %scan(&wordList, &i);
        %if "&&&thisWord" eq "" %then %do;
            %put RTE%str(RROR:) &sysmacroname.: Macro Parameter %upcase(&thisWord) requires a value: %upcase(&thisWord)=&&&thisWord ;
            %let rc = -1;
        %end;
    %end;
    
    %let acrossvarsnum=%tu_words(&acrossvar); /* YW001 */   
    %do i=1 %to &acrossvarsnum;
       %local acrossvarfmt&i;
    %end;
    
    /* Make sure not more than 1 variable exists in parms
    /  that accept just one variable
    /  YW001: removed ACROSSVAR and ACROSSVARLABEL from the list
    /  --------------------------------------------------------------
    */
    %let wordList = acrossVarListName;
        %do i = 1 %to %tu_words(&wordList);
        %let thisWord = %scan(&wordList, &i);
        %if %tu_words(&&&thisWord) gt 1 %then %do;
            %put RTE%str(RROR:) &sysmacroname.: Macro Parameter %upcase(&thisWord) must contain just ONE variable %upcase(&thisWord)=&&&thisWord ;
            %let rc = -1;
            %goto macerr;
        %end;
    %end;
    /* Check name of dsetout is valid
    /  -----------------------------------
    */
    %if "&dsetOut" ne "" %then %do;
        /* remove any dataset options from the dsetout */
        %let dsOptStart = %index(&dsetout, %str(%() ) ;
        %if &dsOptStart gt 0 %then %do;
            %let dsetOut_dset = %substr(&dsetout, 1, &dsOptStart - 1 );
        %end;
        %else %do;
            %let dsetOut_dset = &dsetout;
        %end;
        %if &g_debug gt 0 %then %put Created Macro Var dsetOut_dset=&dsetOut_dset.. from dsetOut=&dsetOut..;
        /* calling tu_chknames */
        %if %length(%tu_chknames(&dsetOut_dset, DATA )) ne 0 %then %do;
            %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETOUT refers to dataset &dsetOut_dset which is not a valid dataset name;
            %let rc = -1;
        %end;
    %end;   /* of %if "&dsetOut" ne "" %then %do; */
    /* Check name of acrossVarListName
    /  -----------------------------------
    */
    %if %nrbquote(&acrossVarListName) ne %then %do;
        /* calling tu_chknames */
        %if %length(%tu_chknames(&acrossVarListName, VARIABLE )) ne 0 %then %do;
            %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ACROSSVARLISTNAME=&acrossVarListName specifies an invalid macro variable name;
            %let rc = -1;
        %end;
    %end;   /* of %if "&acrossVarListName" ne "" %then %do; */
    /* Check names in acrossColVarPrefix
    /  ----------------------------------
    */
    %if %nrbquote(&acrossColVarPrefix) ne %then %do;
        /* calling tu_chknames */
        %if %length(%tu_chknames(&acrossColVarPrefix, VARIABLE )) ne 0 %then %do;
            %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ACROSSCOLVARPREFIX=&acrossColVarPrefix specifies an invalid variable prefix;
            %let rc = -1;
        %end;
    %end;   /* of %if "&acrossVarListName" ne "" %then %do; */
    /* Check existence of input dataset
    /  --------------------------------
    */
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
        /* write meesage if dsetin does not exist */
        %if %sysfunc(exist(&dsetIn_dset)) eq 0 %then %do;
            %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETIN refers to dataset &dsetIn_dset which does not exist;
            %let g_abort = 1;
            %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
            %let rc = -1;
            %goto MACERR;
        %end;
        /* Make sure variables mentioned exist
        /  -----------------------------------
        */
        /* create temp dataset first, applying the dataset options */
        data &work0;
            set &dsetin;
            if _n_ eq 1;
        run;
        /*** Check VARSTODENORM ***/
        %if "&varsToDenorm" ne "" %then %do;
            /* calling tu_chkVarsExist */
            %let varsNoExist = %tu_chkVarsExist(&work0, &varsToDenorm );
            %if "&varsNoExist" ne "" %then %do;
                %put RTE%str(RROR:) &sysmacroname.: Macro Parameter VARSTODENORM lists variables not existing in &dsetIn: &varsNoExist.;
                %let rc = -1;
            %end;
        %end;
        /*** Check GROUPBYVARS ***/
        %if "&groupByVars" ne "" %then %do;
            /* calling tu_chkVarsExist */
            %let varsNoExist = %tu_chkVarsExist(&work0, &groupByVars );
            %if "&varsNoExist" ne "" %then %do;
                %put RTE%str(RROR:) &sysmacroname.: Macro Parameter GROUPBYVARS lists variables not existing in &dsetIn: &varsNoExist.;
                %let rc = -1;
            %end;
        %end;
        /*** Check ACROSSVAR ***/
        %if "&acrossVar" ne "" %then %do;
            /* calling tu_chkVarsExist */
            %let varsNoExist = %tu_chkVarsExist(&work0, &acrossVar );
            %if "&varsNoExist" ne "" %then %do;
                %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ACROSSVAR lists variables not existing in &dsetIn: &varsNoExist.;
                %let rc = -1;
            %end;
        %end;
        /*** Check ACROSSVARLABEL ***/
        /*** YW001: Added do-to loop to loopover ACROSSVARLABEL ***/
        %if %nrbquote(&acrossVarLabel) ne %then %do;
           %do i=1 %to %tu_words(&acrossvarlabel);
              /* calling tu_chkVarsExist */   
              %if  %qupcase(%qscan(&acrossVarLabel, &i, %str( ))) ne _NULL_ %then %do;        
                 %let varsNoExist = %tu_chkVarsExist(&work0, %qscan(&acrossVarLabel, &i, %str( )) );
                 %if "&varsNoExist" ne "" %then %do;
                     %put RTE%str(RROR:) &sysmacroname.: Macro Parameter ACROSSVARLABEL lists variables not existing in &dsetIn: &varsNoExist.;
                     %let rc = -1;
                 %end;
              %end;              
           %end;
        %end;
    %end;  /* of %if "&dsetin" ne "" %then %do; */
    /*** goto MACERR if error so far ***/
    %if &rc eq -1 %then %goto MACERR;
    /*-------------------------------------------------------------------------
    / Check for dups
    / Give error message and exit program if dups found
    / YW001: Modified for multiple across variables
    /--------------------------------------------------------------------------
    */
    proc sort data=&dsetin out=&work1;
        by &groupByVars &acrossVar;
    run;
    data &workdups;
        retain __dupflag__ 0;
        drop   __dupflag__;
        set &work1 end=eof;
        by &groupByVars &acrossVar;
        if NOT(first.%scan(&acrossVar, &acrossvarsnum, %str( )) AND 
                last.%scan(&acrossVar, &acrossvarsnum, %str( )) ) then do;  /* YW001: */
            __dupflag__ = 1;
            output &workdups;
        end;
        if eof then do;
            call symput('dupflag',put(__dupflag__,f1.));
        end;
    run;
    %if &dupflag %then %do;
        /* need to call tu_abort */
        proc print data=work.&workroot.DUPS;
        run;
        %put RTE%str(RROR:) &sysmacroname.: Duplicates within any groupbyvars exist in dataset to be transposed: Dataset=&dsetin, groupByvars=&groupByVars;
        %put RTN%str(OTE:) &sysmacroname.: Duplicate records have been printed to output;
        %goto MACERR;
    %end;
    /*------------------------------------------------------------------------
    / Find out how many values in the acrossVar so we can built a list of
    / the names that PROC TRANSPOSE will be creating
    / YW001: Modified the old process to make it work for multiple 
    /        across variables.
    /------------------------------------------------------------------------
    */
    
    proc sort data=&dsetin out=&work3(keep=&acrossVar &acrossvarlabel) nodupkey;
        by &acrossVar;
    run;
    
    proc sort data=&dsetin out=&work4;
        by &acrossVar;
    run;  
    
    /*------------------------------------------------------------------------
    / YW001: If any across variable is numeric, create a format for it
    / so that the leading '0' can be added when using the variable value
    / as the across variable name. 
    /------------------------------------------------------------------------
    */
    
    data _null_;
       set &work3 (keep=&acrossVar) end=&varprefix.end;
       array &varprefix.array {&acrossvarsnum} _TEMPORARY_ ;
       %do i=1 %to &acrossvarsnum;
          if vtype(%scan(&acrossvar, &i, %str( ))) eq 'N' then 
             &varprefix.array{&i}=max(1, length(compress(put(%scan(&acrossvar, &i, %str( )), 12.0))), &varprefix.array{&i});
          else
             &varprefix.array{&i}=max(1, length(%scan(&acrossvar, &i, %str( ))), &varprefix.array{&i});
       %end;          
         
       if &varprefix.end then do;
          %do i=1 %to &acrossvarsnum;
             if vtype(%scan(&acrossvar, &i, %str( ))) eq 'N' then
                call symput('acrossvarfmt'||left(put(&i, 6.0)), compress('Z'||put(&varprefix.array{&i}, 6.0)||'.'));
             else               
                call symput('acrossvarfmt'||left(put(&i, 6.0)), compress('$'||put(&varprefix.array{&i}, 6.0)||'.'));
          %end;  
       end;
    run;
  
    %let prefixlength=0;
    
    %do i=1 %to %tu_words(&acrossColVarPrefix);
       %let thisVar=%scan(&acrossColVarPrefix, &i, %str( ));
       %let prefixlength=%sysfunc(max(&prefixlength, %length(&thisVar))); 
    %end;
    
    /*------------------------------------------------------------------------
    / YW001: Combine multiple across variables together so that it can be
    / used as ID variables in PROC TRANSPOSE. Also combine the labels of 
    / across variables. The across variables and their labels will be put
    / into one macros variable and this macro variable can be used in the 
    / COLUMN statement of PROC REPORT.
    /------------------------------------------------------------------------
    */    
   
    data &work5;
       set &work3 end=eof;
       by &acrossVar;
       keep &acrossVar &varprefix.id &varprefix.label;
       length &varprefix.id $32 &varprefix.columns $32761 &varprefix.label $200;
       retain &varprefix._n_ 0 &varprefix.columns "";
       
       /* combine the across variables to form a new variable */                
       %if  %nrbquote(&acrossvarfmt1) ne %then %do;
          &varprefix.id=compress(translate(trim(left(compbl(put(%scan(&acrossVar, 1, %str( )), &acrossvarfmt1)))), '_', ' '));      
       %end;
                   
       %do i=2 %to &acrossvarsnum;           
          %if ( %qscan(&acrossVarLabel, %eval(&i - 1), %str( )) ne ) and 
              ( %qscan(&acrossVarLabel, %eval(&i - 1), %str( )) ne  %str(.))
          %then %do;          
             %let thisVar=%scan(&acrossVarLabel, %eval(&i - 1), %str( ));                
          %end;
          %else %do;
             %let thisVar=%scan(&acrossVar, %eval(&i - 1), %str( ));
          %end; 
                
          if first.%scan(&acrossVar, %eval(&i - 1), %str( )) and 
             not last.%scan(&acrossVar, %eval(&i - 1), %str( )) then do;
             &thisVar=translate(&thisvar, '"', "'");
             &varprefix.columns=trim(left(&varprefix.columns))||" (%str('_"||trim(left(&thisVar))||"_')";
          end;  
             
          if not missing(%scan(&acrossVar, &i, %str( ))) then do;
             %if %nrbquote(&&acrossvarfmt&i) ne %then %do;
               &varprefix.id=compress(&varprefix.id)||'_'||
                             compress(translate(trim(left(compbl(put(%scan(&acrossVar, &i, %str( )), &&acrossvarfmt&i)))), '_', ' '));                                                                             
             %end;
          end;
       %end;   /* end of DO-TO look on &i */
        
       /* If the new variable name is too long, truncate it and add a number to it */     
       if length(&varprefix.id) gt 25 - &prefixlength then do;
          &varprefix.id=compress(substr(&varprefix.id, 1, 25 - &prefixlength))||left(put(&varprefix._n_, Z2.0));
          &varprefix._n_=&varprefix._n_ + 1;
       end;    
       
       /* Form the value of &acrossvarlistname. It is the combination of the variable name and label */ 
       &varprefix.columns=trim(left(&varprefix.columns))||" "||compress("%qscan(&acrossColVarPrefix, 1, %str( ))"||&varprefix.id);
       
       %do i=2 %to &acrossvarsnum;
           if last.%scan(&acrossVar, %eval(&acrossvarsnum - &i + 1), %str( )) and
              not first.%scan(&acrossVar, %eval(&acrossvarsnum - &i + 1), %str( )) then do;
              &varprefix.columns=trim(left(&varprefix.columns))||')';
           end;        
       %end;      
                           
       %if %nrbquote(&acrossVarListName) ne %then %do; 
          if eof then do;
             call symput("&acrossVarListName", trim(left(&varprefix.columns)));
                                        
             %if %nrbquote(&acrossColVarPrefix) ne %then %do;                           
                %do i=2 %to %tu_words(&acrossColVarPrefix);
                   call symput("&acrossVarListName&i.", trim(left(translate(&varprefix.columns, 
                      "%scan(&acrossColVarPrefix, &i, %str( ))",
                      "%scan(&acrossColVarPrefix, 1, %str( ))"
                      ))));                
                %end;
             %end;
          end;                                                               
       %end;  /* end-if on &acrossVarListName is not blank */
       
       /* Put the label of the across variable to a new variable */                     
       %do i=1 %to &acrossvarsnum;          
          %let thisvar=%qscan(&acrossVarLabel, &i, %str( ));
          %if (&thisvar ne ) and (%qupcase(&thisvar) ne _NULL_) %then %do;
              if first.%scan(&acrossvar, &i, %str( )) and last.%scan(&acrossvar, &i, %str( )) then do;
                 if vtype(&thisvar) eq 'C' then do;
                    &varprefix.label=putc(&thisvar, vformat(&thisvar));
                 end;
                 else do;
                    &varprefix.label=putn(&thisvar, vformat(&thisvar));
                 end;
              end;   
              else 
          %end;
          %else %do;
               %let thisvar=%scan(&acrossvar, &i, %str( ));
               if first.&thisvar and last.&thisvar then do;
                 if vtype(&thisvar) eq 'C' then do;
                    &varprefix.label=putc(&thisvar, vformat(&thisvar));
                 end;
                 else do;
                    &varprefix.label=putn(&thisvar, vformat(&thisvar));
                 end;
              end;   
              else 
          %end;
      %end; /* end of do-loop on &i */
      &varprefix.label="";
                                                                                                                 
    run;    
    
    /*------------------------------------------------------------------------
    / YW001: Add the new created ID and Label variable in.
    /------------------------------------------------------------------------
    */
   
    data &work6;
       merge &work4 &work5;
       by &acrossvar;
    run;
    %let acrossVar=&varprefix.id;
    %let acrossVarLabel=&varprefix.label;
    
    %if %nrbquote(&groupByVars) NE %then %do;          
       proc sort data=&work6;
          by &groupByVars &acrossvar;
       run;
    %end;
    
    /*------------------------------------------------------------------------
    / Do the Transpose for each variable to be transposed
    /------------------------------------------------------------------------
    */
    %let i = 1;
    %let w = %scan(&varsToDenorm,&i,%str( ));
    %do %while(%quote(&w) NE);
        /* determine the prefix, dependent on the transpose iteration */
        %if %scan(&acrossColVarPrefix, &i) eq %then %let thisPrefix = %scan(&varsToDenorm, &i);
        %else %let thisPrefix = %scan(&acrossColVarPrefix, &i);
        proc transpose
            data     =  &work6                   /* YW001: changed 1 to 6 */
            out      =  &work2._&i
            prefix   =  &thisPrefix
            ;
            %if %quote(&groupByVars) NE %then %do;
                by &groupByVars;
            %end;
            var &w;
            id &acrossVar;
            %if %quote(&acrossVarLabel) NE %then %do;
                idlabel &acrossVarLabel;
            %end;
        run;
        %let mergelist = &mergelist &work2._&i;
        %let i = %eval(&i + 1);
        %let w = %scan(&varsToDenorm,&i,%str( ));
    %end;
    /* ---------------------------------------------------
    /  If zero records came in ensure zero records go out
    /  YW001: Combine two data sets together.
    /  ---------------------------------------------------
    */    
    %let rc=%tu_nobs(&work1);
    data &dsetout;
        merge &mergelist;
        %if %quote(&groupByVars) NE %then %do;
            by &groupByVars;
        %end;
        %if &rc eq 0 %then %do;
          delete;
          %put RTN%str(OTE:) &sysmacroname.: Macro Parameter DSETIN results in a dataset with no observations;
        %end;        
    run;
    
    /*-----------------------------------------------------------------
    / Tidy up and leave
    / -----------------------------------------------------------------
    */
    %tu_tidyup(rmdset=&workroot:, glbmac=NONE)
    %goto EXIT;
  %MACERR:
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort has been set to &g_abort;
    %put RTN%str(OTE:) &sysmacroname.: This macro will now abort;
  %EXIT:
      /* run tu_abort always in case of global macro var g_abort has been set to 1 by any procedure */
    %tu_abort()
    %if &g_debug gt 0 %then %put Exiting &sysmacroname;
%mend tu_DENORM;
