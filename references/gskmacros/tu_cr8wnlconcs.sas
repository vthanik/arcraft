/*******************************************************************************
|
| Macro Name:     tu_cr8wnlconcs.sas
|
| Macro Version:  4 
|
| SAS Version:    8.2
|
| Created By:     Trevor Welby
|
| Date:           14th December 2004
|
| Macro Purpose:  The purpose of this macro is to create WinNonlin (WNL)
|                 concentration files from an A&R PKCNC dataset. The
|                 concentration files shall be created in the pkdata
|                 directory
|
| Macro Design:   Procedure style
|
| Input Parameters:
|
| NAME            DESCRIPTION                                    DEFAULT
|
| DSETIN          Specifies the name of the input A&R            ardata.pkcnc (Req)
|                 PKCNC dataset
|
| FILEOUTDIR      Specifies the name of the output directory     &G_PKDATA (Req)
|                 path
|
| FILEOUTPFX      Specifies text to be used as a prefix for      [blank] (Opt)
|                 names of all output files
|
| SPLITVARS       Specifies the name of the variable(s) to be    pctyp pcspec pcan (Req)
|                 used to split the PKCNC dataset. 
|
|                 Valid values: Character or Numeric 
|                 variables that exist in DSETIN.  Specify
|                 a list of variables delimited by blanks
|
| SUBSET          An optional WHERE clause to subset the         [blank] (Opt)
|                 A&R PKCNC dataset
|
| UNITPAIRS       Specifies those variables for whom units       [blank] (Opt)
|                 shall be included in row 1 of the output
|                 files. Valid values: pairs of variable
|                 names separated by an equals sign. The
|                 variable on the right-hand side of the
|                 equals sign shall be the variable that
|                 holds the units for the variable on the
|                 left-hand side of the equals sign. There
|                 shall be no spaces around the equals sign;
|                 each pair shall be separated by one or more
|                 spaces. The variables must all exist in the
|                 DSETIN dataset For example,
|                 UNITPAIRS=age=ageu height=heightu
|
| CV              Specifies covariate data to be added to the    [blank] (Opt)
|                 output file
|                 Valid values: For each variable to be added,
|                 the following three or four attributes shall
|                 be specified:
|                   Mandatory. Dataset name
|                   Mandatory. Variable name(s)
|                       Surrounded in brackets
|                   Mandatory. Variables by which the CV
|                   variable shall be merged with the DSETIN
|                   data. Surrounded by square brackets
|                   Optional. A where clause to be applied
|                   to the CV dataset during the merge.
|                   Surrounded by square brackets.
|
|                   For example,
|
|                   CV=ardata.demo [age] [subjid]
|                      ardata.vitals [weight] [subjid]
|                      [visitnum eq 1]
|
| SORT            Specifies the variables that define row         pctyp pcspec pcan &g_subjid
|                 order for the output file(s)                    &g_trtgrp pernum visitnum 
|                                                                 ptmnum (Req)
|                 Valid values:  Variables present in either     
|                 DSETIN or the CV datasets.  
|
| VARSOUT         Specifies a list of variables to be included    studyid pctyp pcspec 
|                 in the output file(s) in addition to those      pcan &g_centid &g_subjid
|                 specified by the CV parameter.  The columns     &g_trtgrp visit ptm
|                 on the output file(s) maintain the order        pcstdt pcsttm pcatmnum
|                 specified by this parameter.  Covariates are    pcorres pcwnln pcwnlrt
|                 appended in an alphabetical order following     pcllqc age sex race 
|                 these variables                                 pcsmpid (Req)
|
|                 Valid Values: Shall exist in DSETIN 
|
| JOINMSG         Specifies whether unmatched PK concentration    %str(not)es (Opt)
|                 and covariate records should be treated as
|                 %str(warn)ings, %str(err)ors or %str(not)es
|
|                 Valid values: %str(WARN)INGS, %str(ERRO)R
|                 or %str(NOT)E
|
| Output:         The unit shall create CSV files. In each file,
|                 the 1st row shall contain column names and units.
|                 The files shall contain the variables listed in
|                 VARSOUT plus any further covariates
|                 requested from other ardata datasets (e.g. height
|                 and weight). The units in the 1st row shall serve
|                 as visual aids for the WinNonlin user (WNL will
|                 not use them directly). The column headings shall
|                 constitute: SAS variable name + underscore +
|                 open-bracket + units + close-bracket, e.g. "HEIGHT_(CM)".
|                 The same structure of file is required, regardless
|                 of which model will be used in WinNonlin; and
|                 regardless of whether the study is steady-state
|                 or not. There shall be one file per analyte.
|                 The file shall be sorted by subject, treatment group,
|                 period, visit and planned time.
|
| Global macro variables created: none
|
| Macros called:
|(@) tr_putlocals
|(@) tu_putglobals
|(@) tu_chkvarsexist
|(@) tu_chkvartype
|(@) tu_cv
|(@) tu_words
|(@) tu_maclist
|(@) tu_tidyup
|(@) tu_abort
|
| Example:
|
| %tu_cr8wnlconcs(dsetin=ardata.pkcnc
|                ,unitpairs=pcatmen=pcatmu pcsttmdv=pctmdvu pcentmdv=pctmdvu
|                ,splitvars=pctyp pcspec pcan
|                ,subset=sex='F'
|                ,fileoutpfx=pkcnc
|                ,cv=ardata.demo [height] [subjid] ardata.vital [weight] [invid subjid] [visitnum=1]
|                ,sort=&g_subjid &g_trtgrp pernum visitnum ptmnum
|                );
|
|
|*******************************************************************************
| Change Log
|
| Modified By: Trevor Welby
| Date of Modification: 15-Dec-2004
| New version/draft number: 01-002
| Modification ID: TQW9753.01-002
| Reason For Modification: Modify the call to %tu_tidyup so that only
|                          temporary datasets are deleted with a prefix of
|                          &PREFIX:
|
|*******************************************************************************
|
| Modified By: Trevor Welby
| Date of Modification: 21-Dec-2004
| New version/draft number: 01-003
| Modification ID: TQW9753.01-003
| Reason For Modification: Correct issue to allow VARSOUT and UNITPAIRS
|                          parameters to be assigned blank
|
|*******************************************************************************
|
| Modified By: Trevor Welby
| Date of Modification: 22-Dec-2004
| New version/draft number: 01-004
| Modification ID: TQW9753.01-004
| Reason For Modification: VARSOUT now correctly outputs all variables
|
|                          The dataset specified by the DSETIN parameter
|                          is now sorted (by the SPLITVARS and SORT parameters) before
|                          keeping the variables specified by the VARSOUT and
|                          UNITPAIRS parameters
|
|*******************************************************************************
|
| Modified By: Trevor Welby
| Date of Modification: 10-Jan-2005
| New version/draft number: 01-005
| Modification ID: TQW9753.01-005
| Reason For Modification:
|                          Verify that a value for the SPLITVARS parameter is
|                          specified
|
|                          Automatically append SPLITVARS and SORT to VARSOUT
|
|                          Verify that a value for the SORT parameter is
|                          specified
|
|                          Verify SORT variable(s) exist in input dataset(s)
|
|                          Sort the current output dataset by variable(s)
|                          specified by the SORT parameter

|*******************************************************************************
|
| Modified By: Trevor Welby
| Date of Modification: 10-Feb-2005
| New version/draft number: 01-006
| Modification ID: TQW9753.01-006
| Reason For Modification:
|
|                          The macro now creates macro variables
|                          (UNITLIST, CV_VARS) that hold the values of the
|                          renamed units pairs and covariates respectively
|
|                          The following variables are now kept on the
|                          output files: SPLITVARS, SORT, VARSOUT, UNITLIST,
|                          and CV_VARS
|
|                          The columns of the output files are now ordered
|                          SPLITVARS, SORT and all other variables. The following
|                          utility macros were used: tu_words and tu_maclist
|
|                          Remove a redundant validation check from the normal
|                          processing section.  This validation verified that the
|                          variables specified by the UNITPAIRS parameter exist
|                          in DSETIN.  This is now checked in the parameter
|                          validation section.
|
|                          The validation of the existence of variables in DSETIN
|                          as specified by the VARSOUT parameter has been moved to
|                          from the normal processing section to the parameter
|                          validation section
|
|                          The test for the consistency of units failed when
|                          the column containing the units had at least a blank value.
|                          This has now been corrected
|
|                          Add FILEOUTDIR parameter.
|
|*******************************************************************************
|
| Modified By: Trevor Welby
| Date of Modification: 14-Feb-05
| New version/draft number: 01-007
| Modification ID: TQW9753.01-007
| Reason For Modification:
|
|                         Removed redundant validation checks. As these
|                         are also performed by checking that the value 
|                         of SPLITVARS is character
|
|                           Verify that a value for the SPLITVARS parameter 
|                           is specified [TQW9753.01-005]
|
|                           Verify SPLITVARS exists in the DSETIN dataset
|
|                        Add
|
|                         Verify that the FILEOUTDIR parameter is a valid 
|                         directory
|
|*******************************************************************************
|
| Modified By:              Trevor Welby
| Date of Modification:     03-May-05 
| New version/draft number: 01-008
| Modification ID:          TQW9753.01-008
| Reason For Modification: 
|                           Explicitly specify the delimiter in a string of words
|                           to be a blank character i.e.     
|
|                           %let splitvalue=%scan(&splitvalues,&k,' ');  
|
|*******************************************************************************
| Change Log                
|
| Modified By:              James McGiffen/ Trevor Welby
| Date of Modification:     24-Aug-05
| New version/draft number: 02-001
| Modification ID:          tqw9753.02.001
| Reason For Modification:  All changes are to deal with change request
|                           
|                           Remove macro references from %tu_putglobals 
|
|                           Change the delimiter from blank to # in the
|                           SPLITVALUE macro variable 
|                            
|                           Modify the code to produce output file(s)
|                           based upon multiple split variables.  Numeric
|                           and Character variables are accepted. 
|
|                           Validation of the UNITPAIRS parameter checks
|                           the units are consistent across the classification
|                           levels specified by the SPLITVARS parameters 
|
|                           Introduce SUBSET parameter to apply a WHERE
|                           clause to DSETIN
|
|                           Modify the definition of the VARSOUT parameter 
|                           so that variables specified by this parameter 
|                           are kept on the output files along with those 
|                           specified in CV.  The column order is now determined 
|                           by the order of those variables specified 
|                           in VARSOUT.  CV variables are appended alphabetically
|                           after VARSOUT variables.  Verify that VARSOUT is non-blank.
|                           
|                           Declare and assign the VARLIST and CV_VARS macro variables
|                           so that they are set unconditionally.  Previously
|                           their values were set when UNITPAIRS and CV
|                           were non blank.
|
|                           SUBSET parameter now supports upper and lower case
|                           data
|
|                           Modify the RTERROR message when the SUBSET parameter
|                           returns no observations from DSETIN.  This now references
|                           SYSMACRONAME      
|********************************************************************************
| Change Log                
|
| Modified By:              Trevor Welby
| Date of Modification:     24-Aug-05
| New version/draft number: 02-002
| Modification ID:          tqw9753.02.002
| Reason For Modification:  Provide a default value for the DSETIN parameter,
|                           also modified the validation of the parameter
|                           to check that the value is non-blank
|
********************************************************************************
|
| Modified By:              Shivam Kumar
| Date of Modification:     21-OCT-2013
| New version/draft number: 03-001
| Modification ID:
| Reason For Modification:  Replace local macro variable sysmsg with l_sysmsg
********************************************************************************
|
| Modified By:              Lee Seymour
| Date of Modification:     29-Jul-2014
| New version/draft number: 04-001
| Modification ID:          LJS001
| Reason For Modification:  Corrected  l_sysmsg=sysmsg()                                                                          
********************************************************************************/
%macro tu_cr8wnlconcs(dsetin= ardata.pkcnc  /* Name of input PKCNC dataset */
                     ,fileoutdir=&G_PKDATA  /* Name of output directory path */
                     ,fileoutpfx= /* Prefix names of output fles */
                     ,splitvars=PCTYP PCSPEC PCAN  /* List of subset split variable(s) */
                     ,subset=  /* Optionally specify a WHERE clause to subset the A&R PKCNC dataset */
                     ,varsout=STUDYID PCTYP PCSPEC PCAN &G_CENTID &G_SUBJID &G_TRTGRP VISIT PTM PCSTDT PCSTTM PCATMNUM PCORRES PCWNLN PCWNLRT PCLLQC AGE SEX RACE PCSMPID /* List of variables to be included in the output file(s) */
                     ,unitpairs=  /* Pairs of variables and units */
                     ,cv= /* Covariate data to be added */
                     ,sort=&G_SUBJID &G_TRTGRP PERNUM VISITNUM PTMNUM  /* Output file row order */
                     ,joinmsg=%str(NOT)E
                     );

  /*
  / Echo values of parameters and global macro variables to the log.
  /------------------------------------------------------------------------------*/

  /*----------------------------------------------------------------------*/
  /*-- upcase variables  */
  %let splitvars=%nrbquote(%upcase(&splitvars.));
  %let subset=%nrbquote(&subset.);
  %let varsout=%nrbquote(%upcase(&varsout.));
  %let unitpairs=%nrbquote(%upcase(&unitpairs.));
  %let sort=%nrbquote(%upcase(&sort.));
  %let cv=%nrbquote(%upcase(&cv.));
 
  %local MacroVersion;
  %let MacroVersion=4;
  %include "&g_refdata./tr_putlocals.sas";
  %tu_putglobals();

  /*
  / Perform parameter validation
  /------------------------------------------------------------------------------*/
  %local notfound;

  /*
  / Verify that the dataset specified by DSETIN is specified and exists
  /------------------------------------------------------------------------------*/
  %if %length(&dsetin) eq 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: Macro Parameter DSETIN - A value for the parameter must be specified;
    %let g_abort=1;
  %end;
  %else %if not %sysfunc(exist(&dsetin)) %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: Macro Parameter DSETIN (dsetin=&dsetin) dataset does not exist;
    %let g_abort=1;
  %end; 
  
  %tu_abort; 

  /*
  / Verify that the value for the FILEOUTDIR parameter is a valid directory [TQW9753.01-007]
  /------------------------------------------------------------------------------*/
  data _null_;
    length DirExist $8;
    DirExist='';
    rc=filename(DirExist,"&fileoutdir.");
    l_sysmsg=sysmsg();                     /* LJS001 */
    if rc ne 0 then
    do;  /* FILENAME failed */
      put 'RTE' "RROR: &sysmacroname: " l_sysmsg;
      call symput('g_abort','1');
    end; /* FILENAME failed */
    else
    do;  /* FILENAME was ok */
     did=dopen(DirExist);
     if did=0 then
     do;  /* DOPEN failed */
       put 'RTE' "RROR: &sysmacroname.: Macro Parameter FILEOUTDIR, Physical directory does not exist (FILEOUTDIR=&fileoutdir.)";  
       call symput('g_abort','1');
     end;  /* DOPEN failed */
     else
     do;  /* DOPEN ok */
       rc=dclose(did);
     end;  /* DOPEN ok */
     rc=filename(DirExist);
    end;  /* FILENAME was ok */
  run;

  /*
  / Verify that a value for the SPLITVARS parameter is specified [TQW9753.01-005]
  /------------------------------------------------------------------------------*/
  %if %length(&splitvars) eq 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: Macro Parameter SPLITVARS - A value for the parameter must be specified ;
    %let g_abort=1;
  %end;

  /*
  / Verify SPLITVARS exists in the DSETIN dataset
  /------------------------------------------------------------------------------*/
  %let notfound=%tu_chkvarsexist(&dsetin,&splitvars);
  %if %length(&notfound) ne 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: Macro Parameter SPLITVARS variable(s) (&notfound) do not exist on %upcase(&dsetin) dataset;
    %let g_abort=1;
  %end;

  %let notfound=;

  /* Verify that SUBSET is a valid WHERE clause */
  %if %length(&subset.) ne 0 %then
  %do;  /* Is Not Blank */
    %local dsid rc;
    %let dsid=%sysfunc(open(&dsetin.(where=(%unquote(&subset.)))));
    %if &dsid. eq 0 %then
    %do;  /* Open Failed */
      %local l_sysmsg;
      %let l_sysmsg=%sysfunc(sysmsg());
      %put RTE%str(RROR): &sysmacroname.: &l_sysmsg.;
      %let g_abort=1;
    %end;  /* Open Failed */
    %else
    %do;  /* Open Success */
      %local nobs;
      %let nobs=%sysfunc(attrn(&dsid.,nlobsf));
      %if &nobs. eq 0 %then
      %do;  /* No Observations */
        %put RTE%str(RROR): &sysmacroname.: The WHERE clause identifed by the SUBSET(&subset.) parameter selects 0 observations;
        %let g_abort=1;
      %end;  /* No Observations */
      %let rc=%sysfunc(close(&dsid));
      %if &rc. ne 0 %then
      %do;  /* Close failed */
        %let l_sysmsg=%sysfunc(sysmsg());
        %put RTE%str(RROR): &sysmacroname.: &l_sysmsg.;
        %let g_abort=1;
        %let rc=;
      %end;  /* Close failed */
    %end;  /* Open Success */
  %end;  /* Is Not Blank */

  /*
  / Verify that a value for the SORT parameter is specified [TQW9753.01-005]
  /------------------------------------------------------------------------------*/
  %if %length(&sort) eq 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: Macro Parameter SORT - A value for the parameter must be specified ;
    %let g_abort=1;
  %end;

  /*
  / Verify UNITPAIRS variable exist in the DSETIN dataset
  /------------------------------------------------------------------------------*/
  %if %length(&unitpairs) ne 0 %then
  %do;
    %if %length(%tu_chkvarsexist(&dsetin,%sysfunc(translate(&unitpairs,' ','=')))) ne 0 %then
    %do;
      %put RTE%str(RROR): &sysmacroname.: Macro Parameter UNITPAIRS (unitpairs=&unitpairs) one or more variables do not exist in %upcase(&dsetin);
      %let g_abort=1;
    %end;
  %end;

  /*
  / Verify VARSOUT is non-blank and that the variable(s) exist in 
  / DSETIN [TQW9753.01-005] [TQW9753.01-006]
  /------------------------------------------------------------------------------*/
  %if %length(&varsout.) eq 0 %then 
  %do; /* When VARSOUT is blank */
    %put RTE%str(RROR): &sysmacroname.: Macro Parameter VARSOUT - A value for the parameter must be specified ;
    %let g_abort=1;
  %end; /* When VARSOUT is blank */
  %else
  %do;  /* When VARSOUT is non-blank */
    /* Populate macro variable NOTFOUND with not found variables if applicable */
    %let notfound=%tu_chkvarsexist(&dsetin,&varsout);
    %if %length(&notfound) ne 0 %then
    %do;  /* Verify that the variables exist on CURRENTDATASET */
      %put RTE%str(RROR): &sysmacroname.: VARSOUT variable(s) (&notfound.) do not exist in dataset (DSETIN=&dsetin.);
      %let g_abort=1;
    %end;  /* Verify that the variables exist on CURRENTDATASET */
    %let notfound=;
  %end; /* When VARSOUT is non-blank */

  %tu_abort;

  /*
  / Perform Normal Processing
  /------------------------------------------------------------------------------*/

  /*
  / Create a working copy of DSETIN
  /------------------------------------------------------------------------------*/
  %local currentdataset;
  %local prefix;

  %let currentdataset=&dsetin;
  %let prefix=_cr8wnlconcs;

  /*
  / Set the MISSING OPTION for the duration of the macro and restore value later
  /------------------------------------------------------------------------------*/
  %local MissingValue;
  %let MissingValue=%sysfunc(getoption(missing));

  options missing='.';

  %local splitwords;
  %let splitwords=%tu_words(&splitvars.);
 
  %local z;

  %do z=1 %to &splitwords.;
    %local splitvar&z.;
  %end;

  %local not_used;

  %tu_maclist(string=&splitvars.
             ,delim=%str(' ')
             ,prefix=splitvar
             ,cntname=not_used
             ,scope=local
             );

  /*
  / Create a working copy of DSETIN
  /------------------------------------------------------------------------------*/
  data &prefix._workcopy;
    attrib key length=$512;
    set &currentdataset. %if %length(&subset.) ne 0 %then
                         %do;
                           (where=(%unquote(&subset.)))
                         %end;;
    key=%if &z gt 1 %then
        %do;
          %do z=1 %to %eval(&splitwords.-1);
            %if %tu_chkvartype(&currentdataset.,&&splitvar&z.) eq C %then
            %do;
              trim(&&splitvar&z.)
            %end;
            %else
            %do;
              trim(left(put(&&splitvar&z.,best22.)))
            %end;
             ||'_'||
          %end;
        %end;

        %if %tu_chkvartype(&currentdataset.,&&splitvar&splitwords.) eq C %then
        %do;
          trim(&&splitvar&splitwords.);
        %end;
        %else
        %do;
          trim(left(put(&&splitvar&splitwords.,best22.)));
        %end;

  key=left(key);

  run;

  %let currentdataset=&prefix._workcopy;

  /* Number of SPLITVARS values */
  %local numsplitvalues;
 
  /*
  / Create a string of SPLITVALUES and assign number to NUMSPLITVALUES
  /------------------------------------------------------------------------------*/
  proc sql noprint;
  select distinct key into: splitvalues separated by '#'
  from &currentdataset;
  %let numsplitvalues=&sqlobs;
  quit;

  /*
  / Create a macro variable named (CV_VARS) that optionally contains the names of  
  / the variables added by covariate processing
  /------------------------------------------------------------------------------*/
  %local cv_vars;
  %let cv_vars=;

  /*
  / Merge COVARIATES onto DSETIN dataset (if applicable)
  /------------------------------------------------------------------------------*/
  %if %length(&cv) ne 0 %then
  %do; /* Covariate Processing */

    proc contents data = &currentdataset
                  out  = &prefix._pre_tu_cv (keep=name)
                  noprint
                  ;
    run;

    proc sort data= &prefix._pre_tu_cv; by name; run;
   
    %tu_cv(dsetin=&currentdataset
          ,dsetout=&prefix._cvout
          ,cv=&cv
          ,joinmsg=&joinmsg
          );

    %let currentdataset=&prefix._cvout;

    proc contents data = &currentdataset
                  out  = &prefix._post_tu_cv (keep=name)
                  noprint
                  ;
    run;

    proc sort data=&prefix._post_tu_cv; by name; run;

    data &prefix._added_vars;
      merge &prefix._pre_tu_cv  (in=left)
            &prefix._post_tu_cv (in=right);
      by name;
      name=upcase(name);
      if right and not(left);
    run;

    proc sql noprint;
      select name into : cv_vars separated by ' '
      from &prefix._added_vars;
    quit;
  
  %end; /* Covariate Processing */

  /*
  / Verify SORT variable(s) exist across input dataset(s) [TQW9753.01-005]
  /------------------------------------------------------------------------------*/

  %let notfound=%tu_chkvarsexist(&currentdataset,&sort);
  %if %length(&notfound) ne 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: Macro Parameter SORT - The following variable(s) (&notfound.) do not exist across input dataset(s);
    %tu_abort(option=force);
  %end;
  %let notfound=;

  /*
  / Sort the input dataset by the SORT parameter
  /------------------------------------------------------------------------------*/
  proc sort data=&currentdataset
            out=&prefix._sorted
            ;
  by &sort.;
  run;

  %let currentdataset=&prefix._sorted;

  /********************************************************************************
  / Begin of processing for each value of SPLITVALUE
  ********************************************************************************/
  %local splitvalue;
  %let   splitvalue=;

  %local masterdataset;
  %let masterdataset=&currentdataset;

  %local k;

  /*
  / Save Option VALIDVARNAME to restore later
  /------------------------------------------------------------------------------*/
  %local validvarname;
  %let validvarname=%sysfunc(getoption(validvarname));
  options validvarname=any;

  %do k=1 %to &numsplitvalues;  /* Begin of output loop */

    %let splitvalue=%scan(&splitvalues,&k,'#');  /* [TQW9753.01-008], [TQW9753.02-001] */

    /*
    / Create a work dataset based on the current value of SPLITVARS
    /------------------------------------------------------------------------------*/
    proc sql noprint;
    create table &prefix._&k. as /* [TQW9753.01-008] */
    select *
    from &masterdataset
    where key="&splitvalue"
    ;
    quit;

    %let currentdataset=&prefix._&k; /* [TQW9753.01-008] */

    /********************************************************************************
    / Beginning of processing for UNITPAIRS parameter
    /
    / It is necessary to process the UNITPAIRS within the SPLITVALUE to permit
    / different units across analytes
    ********************************************************************************/
      
    %local varlist;
    %let varlist=&varsout;

    %if %length(&unitpairs) ne 0 %then
    %do;  /* Begin UNITPAIRS processing */
      /*
      / 1. Add units to variable names. Deal with unit pairs one-by-one
      /------------------------------------------------------------------------------*/

      /*
      / 1. Beginning of loop for each unitpair
      /------------------------------------------------------------------------------*/
      %let pair_ptr=1;
      %let pair=%scan(&unitpairs,&pair_ptr);
      %let units=; /* Used later to drop units from the dataset */
      %let unitvalues=;

      %do %while(%length(&pair) gt 0);
        /*
        /  Verify the syntax of a UNITPAIR (must include an equals sign)
        /------------------------------------------------------------------------------*/
        %if %index(&pair,=) eq 0 %then
        %do;
          %put RTE%str(RROR): &sysmacroname: The unitpair (&pair) is not specified correctly, UNITPAIRS (unitpairs=&unitpairs);
          %tu_abort(option=force);
        %end;

        /*
        /  1a. Establish var and associated varunit
        /------------------------------------------------------------------------------*/
        %let var=%upcase(%scan(&pair,1,=));
        %let varunit=%scan(&pair,2,=);
   
        /*
        /  1b. Establish unit value (check it is consistent) [TQW9753.01-006]
        /------------------------------------------------------------------------------*/
        proc sql noprint;
         select distinct &varunit into: unitvalues separated by ','
         from &currentdataset;
        quit;
  
        %if &g_debug gt 0 %then
          %put UNITVALUES: &unitvalues;

        /*
        /  Verify that the units are non missing
        /------------------------------------------------------------------------------*/
        %if %length(&unitvalues) eq 0 %then
        %do;
          %put RTE%str(RROR): &sysmacroname: The &var variable has missing units (&varunit): &unitvalues;
          %tu_abort(option=force);
        %end;

        /*
        /  Verify that the units are consistent
        /------------------------------------------------------------------------------*/
        %if %index(%nrbquote(&unitvalues.),%nrbquote(,)) ne 0 %then
        %do;
          %put RTE%str(RROR): &sysmacroname: The &var variable has inconsistent units (&varunit): &unitvalues;
          %tu_abort(option=force);
        %end;

        /*
        /  1c. Change name of variable
        /------------------------------------------------------------------------------*/
        proc datasets lib=work nolist;
        modify &currentdataset;
        rename &var="&var._(&unitvalues)"n;
        quit;

        %let varlist=%sysfunc(tranwrd(&varlist,&var,&var._(&unitvalues.)));

        /*
        /  1d. Prepare for next iteration
        /------------------------------------------------------------------------------*/
        %let pair_ptr=%eval(&pair_ptr + 1);
        %let pair=%scan(&unitpairs,&pair_ptr);
        %let units=&units &varunit;
        
      %end; /* End of WHILE loop for each UNITPAIR */

    %end;  /* End UNITPAIRS processing */

    
    /********************************************************************************
    / End of processing for UNITPAIRS parameter
    ********************************************************************************/
  
    %local nvars;
  
    %let nvars=%tu_words(&varlist. &cv_vars);

    %local i;

    %do i=1 %to &nvars;
      %local var&i;
    %end;

    %local not_used;

    %tu_maclist(string=&varlist. &cv_vars
               ,prefix=var
               ,delim=%str(' ')
               ,cntname=not_used
               ,scope=local
               );

    %do i=1 %to &nvars;
       %let var&i=%unquote(&&var&i);
    %end;

    data &prefix._final; /* [TQW9753.01-006] */
      set &currentdataset(keep=%do i=1 %to &nvars; "&&var&i"n %end;);
    run;

    %let currentdataset=&prefix._final;

    data _null_;
      set &currentdataset.;
      file "&fileoutdir./&fileoutpfx._&splitvalue._conc.csv"
           delimiter=','
           dropover
           lrecl=32767
      ; /* [TQW9753.01-006] */

    if _n_=1 then
    do;
      %do j=1 %to &nvars;       /* Beginning of loop for each variable - First Observation*/
        put "&&var&j"
            %if &j lt &nvars %then ',' @;
        ;
      %end;                     /* End of loop for each variable - First Observation */
    end;

    %do j=1 %to &nvars;         /* Beginning of loop for each variable */
      put "&&var&j"n
          %if &j lt &nvars %then @; 
      ;
    %end;                       /* End of loop for each variable */

    run;

    proc datasets library=work nolist;
    delete &currentdataset.; /* [TQW9753.01-008] */
    quit;

  %end;
  /********************************************************************************
  / End of processing for each value of SPLITVALUE
  ********************************************************************************/

  /*
  / Restore Option VALIDVARNAME
  /------------------------------------------------------------------------------*/
  options validvarname=&validvarname;

  /*
  / Tidyup the session
  /------------------------------------------------------------------------------*/
 %tu_tidyup(rmdset=&prefix:
            ,glbmac=NONE
            );
  quit;

  /*
  / Restore the MISSING OPTION
  /------------------------------------------------------------------------------*/
  options missing="&MissingValue";

  %tu_abort();

%mend tu_cr8wnlconcs;
