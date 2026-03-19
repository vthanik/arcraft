/*----------------------------------------------------------------------------+
| Macro Name    : tu_statsfmt.sas
|
| Macro Version : 3 build 1
|
| SAS version   : SAS v8.2
|
| Created By    : Lee Seymour
|
| Date          : Aug 2003
|
| Macro Purpose : Formats summary statistics
|
| Macro Design  : Procedure style macro
|
|  Formatting can be specified by two specified methods. For single analysis
|  variables (i.e. age, height etc.) . For analysis variables which require
|  different formats (i.e. laboratory values), the XML file format method
|  can be used.
|
|
| Input Parameters :
|
| NAME               DESCRIPTION                                     DEFAULT
|
| dsetin             Name of input dataset                           none
|
| xmlinfmt           XML file name and location                      none
|
| xmlmergevar        Variable to merge input data and XML format     none
|                    data. This variable must exist in both datasets.
|                    Required if XMLinFMT is specified.
|
| analysisvardpsvar  Represents the precision (number of decimal     none
|                    places) to which the raw data contained in the
|                    analysis variable was captured. Used when
|                    formatting of statistics with relative decimal
|                    placing is requested. If no format on the input
|                    dataset then user will be warned that 0 decimal
|                    places is being arbitrarily assumed when
|                    constructing relative decimal places.
|
| statsdps           Number of decimal places for each statistic     none
|                    (specified consistently with a relative style or
|                    an absolute style).
|                    Relative style shall be expressed with a +n or
|                    -n, where n is an integer. +0 is valid, -0 is
|                    not valid.
|                    Absolute style shall be expressed as SAS formats
|                    (from which only the number of DPs shall be used).
|
| dsetout            Name of output dataset                          none
|
|
| Output:
|
| Output dataset containing numeric version of the original data plus
| formatted character versions.
|
| Global macro variables created:  None
|
|
| Macros called :
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_words
| (@) tu_chkvarsexist
| (@) tu_abort
| (@) tu_tidyup
| (@) tu_varattr
| (@) tu_chknames
|
| **************************************************************************
| Change Log :
|
| Modified By : Lee Seymour
| Date of Modification : 07SEP2003
| New Version Number :  1/2
| Modification ID :  LJS01
| Reason For Modification :  Deassign XML libname after use.
|
| Modified By : Lee Seymour
| Date of Modification : 09SEP2003
| New Version Number :  1/3
| Modification ID :  LJS01
| Reason For Modification :  Fixed error checking if analysisvardps variable
|                            contains one or blank missing values.
|                            Variable created when analysisvardpsvar not
|                            specified and relative formatting required,
|                            is now dropped from output dataset.
|
| Modified By :             Yongwei Wang 
| Date of Modification :    14Jul2005 
| New Version Number :      2/1 
| Modification ID :         YW001 
| Reason For Modification : Changed length of STATSDPS from $100 to $500 
|                           and  _STAT_ from $200 to $500 
|
| Modified By :             Shan Lee 
| Date of Modification :    16Jul2008 
| New Version Number :      3/1 
| Modification ID :         SL001 
| Reason For Modification : Implement changes specified in HRT0209 -
|                           Change the logic for creating the dataset &PREFIX,
|                           in order to avoid generating a long datastep which
|                           sometimes causes out-of-memory issues.
|                           The local macro variable XMLFMTLIST is no longer
|                           created, as it is not required using the new method
|                           for applying the formats.
+----------------------------------------------------------------------------*/

%macro tu_statsfmt(
      dsetin=      ,   /* Name of input dataset */
      XMLInFmt=    ,   /* XML input file name and location */
      XMLMergeVar= ,   /* Variable to merge data and XML format data */
      analysisVarDpsVar =  , /* Name of variable containing the number of decimal places recorded in the analysis variable */
      statsDPS=     ,  /* Number of decimal places for each statistic (either VAR offset or VAR fmt) */
      dsetOut=         /* Name of output dataset */
);

   %local MacroVersion;
   %let MacroVersion=3 build 1;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals();

    /* Initialise local variables */

    %local
    prefix         /* Prefix for datasets  */
    nstatslist     /* List of variable names for required statistics */
    stat           /* Variable name for one of the required statistics from NSTATSLIST.   - SL001 */ 
    xmlerror       /* Flag for errors for no formatting details in XML file */
    fmterror       /* Flag for errors with combination of relative format derivation */
    analvarerror   /* Flag for errors with analysisvardpsvar */
    vardpslist     /* List of values contained in analysisvardpsvar variable */
    NoAnalysisVarDPSVar  /* Flag if no analaysisvardpsvar not specfied */
    fmtType        /* Flag for method of formatting, R=Relative, F=Fixed */

    ;

    %let prefix=%substr(&sysmacroname,3);


    /*
    / Parameter Validation
    /-------------------------------*/


    /* If parameters for dsetin and dsetout have not been specified
    /-----------------------------------------------------------------*/

    %let wordList = dsetin dsetOut  ;
    %do i = 1 %to %tu_words(&wordList);
        %let thisWord = %scan(&wordList, &i);
        %if "&&&thisWord" eq "" %then
            %do;
            %put RTE%str(RROR): &sysmacroname.: Macro Parameter %upcase(&thisWord) requires a value: %upcase(&thisWord)=&&&thisWord ;
            %goto MacErr;
        %end;
    %end;


     /*
     / Check that DSETOUT corresponds to a valid SAS name.
     /----------------------------------------------------------------------------*/

     %if %tu_chknames(&dsetout, DATA) ne %then
     %do;
       %put %str(RTE)RROR: &sysmacroname : DSETOUT parameter should correspond to a valid SAS dataset name, macro will abort;
       %goto MacErr;
     %end;



    /* If dsetin does not exist.
    /----------------------------------*/

     %if %sysfunc(exist(&dsetin)) EQ 0 %then
     %do;
       %put %str(RTER)ROR: &sysmacroname: DSETIN=&dsetin does not exist, macro will abort ;
       %goto MacErr;
     %end;



    /* If XMLinfmt and STATSDPS are both blank
    /------------------------------------------*/


     %if %length(&xmlinfmt) eq 0 and %length(&statsdps) eq 0 %then
     %do;
       %put %str(RTE)RROR : &sysmacroname : Both STATSDPS and XMLINFMT are missing macro will abort;
       %goto MacErr;
     %end;

    /* If XMLinfmt and STATSDPS are both populated
    /----------------------------------------------*/


     %if %length(&xmlinfmt) ne 0 and %length(&statsdps) ne 0 %then
     %do;
       %put %str(RTE)RROR : &sysmacroname : Both STATSDPS and XMLINFMT are specified macro will abort;
       %goto MacErr;
     %end;

    /*
    / Method 1: use xmlinfmt
    /------------------------------------------------------------------------*/

    %if "&XMLinfmt" ne "" %then
    %do;


        %if %sysfunc(fileexist(&XMLinfmt)) = 0 %then
        %do;
            %put %str(RTE)RROR: &sysmacroname : XML File &XMLinfmt does not exist the macro will now exit;
            %goto MacErr;
        %end;

        %let xmlfile=%scan(%scan(&xmlinfmt,-1,/),1 ,.);



        /* Assign XML Libname
        /----------------------*/

        libname fmtxml xml "&xmlinfmt";


        /*
        / Check XML file contains appropriate variables
        /-----------------------------------------------------*/


        %if %length(%tu_chkvarsexist(dsetin=fmtxml.&XMLfile,varsin=_STAT_ VALUE MERGEVAR _FMT_)) ne 0 %then
        %do;
            %put %str(RTE)RROR : &sysmacroname : One or more variables (_STAT_ VALUE MERGEVAR _FMT_) do not exist in the XML file;
            %goto MacErr;
        %end;


        /*
        / Check XMLMergeVar exists in dsetin and XML file
        /-------------------------------------------------------*/


         %if %length(%tu_chkvarsexist(dsetin=&dsetin,varsin=&xmlmergevar)) ne 0 %then
         %do;
            %put %str(RTE)RROR : &sysmacroname : &xmlmergevar does not exist in dataset &dsetin;
            %goto MacErr;
         %end;


        /*
        / Read in XML file to dataset, replace text with minus symbol
        /---------------------------------------------------------------------*/

        data &prefix.XML;
        set  fmtxml.&xmlfile(where=(mergevar="%upcase(&xmlmergevar)"));
        _fmt_=tranwrd(_fmt_,"hyphenWasHere",'-');
        run;

        %if %tu_nobs(&prefix.XML) le 0 %then
        %do;
           %put %str(RTE)RROR : &sysmacroname.: mergevar=&xmlmergevar results in a dataset with no observations;
           %goto MacErr;
        %end;



        /*
        / Identify variables in XML file
        /---------------------------------------------------------------------*/

        proc sql noprint;
        select trim(name)
            into :XMLlist separated by ' '
            from dictionary.columns
            where upcase(memname)= "&prefix.XML" and
            upcase(libname)= 'WORK'
            ;
        quit;


        proc sort data=&prefix.XML;
        by value;
        run;

        proc transpose data=&prefix.XML out=&prefix.XMLdenorm(drop=_name_) prefix=fmt;
        var _fmt_;
        by value;
        id _stat_;
        run;

        data &prefix.XMLdenorm;
        length &XMLMergeVar $%tu_varattr(&dsetin,&XMLMergeVar,varlen);
        set &prefix.XMLDenorm(rename=(value=&XMLMergevar));
        run;


        /*
        /  Merge input dataset and XML format information
        /  Identifying and parametes where no XML formatting
        /  specified
        /-------------------------------------------------*/

        proc sort data=&dsetin out=&prefix.&dsetin;
        by &xmlmergevar;
        run;

        data &prefix.join;
        merge &prefix.XMLDenorm(in=inxml) &prefix.&dsetin(in=indata);
        by &xmlmergevar;
        if not indata then delete;
        else if indata and not inxml then do;
          put "%str(RTE)RROR : &sysmacroname : No XML format details for &xmlmergevar = " &xmlmergevar;
          call symput('xmlerror','1');
        end;
        run;

        %if &xmlerror eq 1 %then
        %do;
           %goto MacErr;
        %end;


        /*
        /  Build Format statement
        /-------------------------------------------------*/

        /*
        /  Identify statistics in XML file
        /  Use the DISTINCT option so that each variable name for a statistic will be listed only once in NSTATSLIST. - SL001 
        /------------------------------------*/

        proc sql noprint;
        select distinct trim(_stat_)
            into :nstatslist separated by ' '
            from &prefix.XML
        ;
        quit;


        data &prefix(drop=_LABEL_ fmt:);

          set &prefix.join;

          /*
          / SL001
          /
          / For each statistic:
          /
          /   1. Create a numeric variable to store the statistic. 
          /   2. Create a variable to store the format for the statistic, FMTX<statistic name>, which will default to "best20."
          /      if no other format has been specified. 
          /   3. Create a character variable, <statistic name>CHAR, storing the formatted value of the statistic.
          /   4. Overwrite the original variable storing the statistic, with formatted values of the statistic.
          /---------------------------------------------------------------------------------------------------------*/

	  %do i=1 %to %tu_words(&nstatslist);

	    %let stat = %scan(&nstatslist, &i);

	    &stat._NUM = &stat;
 
            length fmtx&stat $50;

	    if fmt&stat eq . then
            do;
	      fmtx&stat = "best20.";
	    end;
	    else
	    do;
	      fmtx&stat = fmt&stat;
	    end;

	    &stat.char = putn(&stat, fmtx&stat);

	    drop &stat;
	    rename &stat.char = &stat;

	  %end;  /* End of looping across statistics */

        run;

        /*
        /  Deassign XML libname
        /---------------------------*/

        libname fmtxml "";


        %let lastDset=&prefix;


   %end; /* End of XML formatting method */




   /*
   / Method 2 - use statsdps and analysisvarDPS
   /---------------------------------------------*/

   %if %length(&statsdps) ne 0 %then
   %do;

        /*
        / Check to ensure statsdps uses only one format method */

        %if %sysfunc(indexc("&statsdps",+-)) and %sysfunc(indexc("&statsdps",.)) %then
        %do;
           %put %str(RTE)RROR : &sysmacroname : statsdps parameter must not contain a combination of fixed and relative formats ;
           %goto MacErr;
        %end;


        /*
        / Check that statsdps does not contain invalid format of -0
        /-----------------------------------------------------------*/

        %if %sysfunc(index("&statsdps",-0))  %then
        %do;
           %put %str(RTE)RROR : &sysmacroname : statsdps parameter must not contain -0;
           %goto MacErr;
        %end;


        /*
        / Parse the statsdps parameter relative or fixed
        /--------------------------------------------------------*/
        %let nstatslist=;
        %do i=1 %to %tu_words(&statsdps) %by 2;
           %let nstatslist=&nstatslist %scan(&statsdps,&i,' ');
        %end;

        /*
        / Checck statsdps variables exist in dsetin
        /--------------------------------------------------------*/

        %if %length(%tu_chkvarsexist(dsetin=&dsetin,varsin=&nstatslist)) ne 0 %then
        %do;
           %put %str(RTE)RROR : &sysmacroname : One or more of - &nstatslist - do not exist in dataset &dsetin;
           %goto MacErr;
        %end;

        /*
        / Check lengths of variables for statistics to be less than
        / or equal to 28, as when renamed to be suffixed with _num
        / will be greater than 32.
        /------------------------------------------------------------*/


        %do i=1 %to %tu_words(&nstatslist);
           %if %length(%scan(&nstatslist,&i)) gt 28 %then
           %do;
              %put %str(RTE)RROR : &sysmacroname : Length of variable %scan(&nstatslist,&i) is too long. Must be less than or equal to 28 chars;
              %goto MacErr;
           %end;
        %end;


        data &prefix._statsdps(keep=_stat_ _fmt_);
        length statsdps $500 _stat_ $500;   /* YW001 */
        statsdps="&statsdps";
        start=0;
        length=0;
        array statf[30] $30;
        pattern = "$p({'+'|'-'}$f)$s";
        rx = rxparse(trim(pattern));
        call rxsubstr(rx,statsdps,start,length);
        do i=1 by 1 while(start gt 0);
            length=start+length;
            statf[i]=substr(statsdps,1,length);
            statsdps=trim(left(substr(statsdps,length+1)));
            call rxsubstr(rx,statsdps,start,length);
            pos=index(statf[i],' ');
            _stat_=substr(statf[i],1,pos);
            _fmt_=trim(left(substr(statf[i],pos)));
            output;
        end;
        run;



        /*
        /  Create numeric values of stats results
        /--------------------------------------------------*/


        data &prefix._num;
        length _NAME_ $8;
        set &dsetin;
        %do nstat=1 %to %tu_words(&nstatslist);
             %scan(&nstatslist,&nstat)_NUM = %scan(&nstatslist,&nstat);
        %end;
        _NAME_="_fmt_";
        run;


        proc transpose data=&prefix._statsdps prefix=fmt out=&prefix._statsdenorm;
        var _fmt_;
        id _stat_;
        run;


        /*
        / Check statsdps to see if relative or fixed formats
        /-------------------------------------------------------------*/

        %if %sysfunc(indexc("&statsdps",+-)) %then %let fmtType='R';
        %else %let fmtType='F';
        %let fstats=%sysfunc(compress(&statsdps,'1234567890+-.'));


        %if %length(&analysisVarDPSVar) ne 0 %then
        %do;
            %if %length(%tu_chkvarsexist(dsetin=&dsetin,varsin=&AnalysisVarDPSVar)) ne 0 %then
            %do;
                %put %str(RTE)RROR : &sysmacroname : AnalysisVarDPSVAR - &AnalysisVarDPSVAR  - does not exist in dataset &dsetin;
                %goto MacErr;
            %end;
        %end;


        data &prefix.all;
        merge &prefix._num &prefix._statsdenorm;
        by _NAME_;

        %do i=1 %to %tu_words(&nstatslist);
            %if %length(&analysisvardpsvar) ne 0 %then
            %do;

               if &analysisvardpsvar eq . then
               do;
                  call symput("analvarerror",'1');
                  &analysisvardpsvar = 0;
               end;
               call symput("analfmtval&i", &analysisvardpsvar );
            %end;
          call symput("fmt%scan(&nstatslist,&i)",fmt%scan(&nstatslist,&i));
        %end;



        /* If relative formatting is required but no analysisdpvar is specified
        / then put message to the log and assume to be 0
        /-----------------------------------------------------------------------------*/


        %if &fmtType eq 'R' and %length(&analysisvardpsvar) eq 0 %then
        %do;
           %let analysisvardpsvar=analvardps;
           %let NoAnalysisVarDpsVAR =1;
           &analysisvardpsvar=0;
           %put "%str(RTW)ARNING: &sysmacroname : Relative formatting required, but analysisvardpsVar has not been specified, this has been assumed to be zero" ;
           %do i=1 %to %tu_words(&nstatslist);
              call symput("analfmtval&i", &analysisvardpsvar );
           %end;
        %end;

        run;

        %if &analvarerror eq 1 %then
        %do;
           %put "%str(RTW)ARNING: &sysmacroname : AnalysisvardpsVar &analysisvardpsvar has one or more blank rows, these have been assumed to be zero" ;
        %end;

        /*
        / Check to see if combination of analysisvardpsvar and statsdps resolves to be
        / a negative value
        /-----------------------------------------------------------------------------*/

        data _null_;
        set &prefix.all;

        %do i=1 %to %tu_words(&nstatslist);
            if (&analysisvarDPSVar + fmt%scan(&nstatslist,&i)) lt 0 then
            do;
                put "%str(RTE)RROR: &sysmacroname : Combination of statsdps and analysisvardpsvar resolves in an invalid format, &analysisvardpsvar = " &analysisvardpsvar "%scan(&nstatslist,&i) = " fmt%scan(&nstatslist,&i);
                call symput('fmterror',1);
            end;
        %end;
        run;

        %if &fmterror eq 1 %then
        %do;
           %goto MacErr;
        %end;


        /*
        / Set macro variable vardpslist to be a list of the distinct values
        / contained within the analysisvardpsvar parameter
        /-----------------------------------------------------------------------------*/

         %if &fmtType eq 'R' %then
         %do;

            proc sql noprint;
            select distinct(&analysisvardpsvar)
            into :vardpslist separated by ' '
            from &prefix.all
            ;
            quit;

         %end;


         /*
         / Construct format statements and create character variables
         /-----------------------------------------------------------------*/

         data &prefix.all2(drop=fmt: _NAME_);
         set &prefix.all;

           %do i=1 %to %tu_words(&nstatslist);

               %if &fmtType='R' %then
               %do;
                  %let stat=%scan(&nstatslist,&i);

                   %do j=1 %to %tu_words(&vardpslist);
                      if &analysisvardpsvar=%scan(&vardpslist,&j) then
                      do;
                         %let temp=%scan(&vardpslist,&j);
                         &stat.char=put(&stat,8.%eval(&&fmt&stat + &temp));
                      end;
                   %end;

               %end;   /* End of relative formtatting */

               %else
               %do;
                  %let fmtstat=fmt%scan(&nstatslist,&i);
                  %scan(&nstatslist,&i)char=put(%scan(&nstatslist,&i), &&&fmtstat );
               %end;

           %end;

          drop &nstatslist;
            %do i=1 %to %tu_words(&nstatslist);
          rename %scan(&nstatslist,&i)char = %scan(&nstatslist,&i);
          %end;

          %if &NoAnalysisVarDPSVar eq 1 %then
          %do;
             drop &analysisvardpsvar;
          %end;

          run;



          %let lastdset=&prefix.all2;
    %end;  /* End of code if statsdps exists */

     /*
     /  Output dataset
     /-----------------------*/

     data &dsetout(label='TU_STATSFMT output dataset');
        set &lastDset;
     run;

     %goto EXIT;


     %MacErr:
        %let g_abort=1;
        %tu_abort(option=force);


       %EXIT:


    %tu_tidyup(rmdset=&prefix:, glbmac=none);


    %put Exiting &sysmacroname;

%mend tu_statsfmt;
