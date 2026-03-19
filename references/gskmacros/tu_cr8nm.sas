/******************************************************************************* 
|
| Macro Name:      tu_cr8nm.sas
|
| Macro Version:   1.0
|
| SAS Version:     8.2
|
| Created By:      Andrew Ratcliffe, RTSL, www.ratcliffe.co.uk
|
| Date:            19-Jun-2005
|
| Macro Purpose:   To take a given dataset of NONMEM information and produce 
|                  one or more NONMEM-ready CSV files (optionally split by 
|                  proportion or upon values of specified "split variables")
|
|                  The user shall have the option to specify a suffix and 
|                  prefix for the filename, plus the qualifier. If the file(s) 
|                  have been split by proportion, the prefix and suffix shall 
|                  have "_prop1" and "_prop2" between them; if the file(s) are 
|                  to be split by one or more variables, the prefix and suffix 
|                  shall be separated by values of the variables (prefixed with 
|                  underscore); and if no splitting shall be done, no text 
|                  shall be inserted between prefix and suffix.
|
| Macro Design:    PROCEDURE STYLE MACRO
| 
| Input Parameters:
|
| NAME              DESCRIPTION                         DEFAULT 
| COLORDER          Specifies columns to be placed at   [blank] (Opt)
|                   the left side of the output file
|
| DCDSEP            Specifies the character to be used  ! (Req)
|                   to separate decode values in the 
|                   output file(s)
|
| DROP              Specifies variables that shall not  [blank] (Opt)
|                   be included in the output file(s)
|
| DSETIN            Specifies the name of the input     [blank] (Req)
|                   "NONMEM" dataset
|
| FILEOUTDIR        Specifies the directory into which  [blank] (Req)
|                   the output file(s) shall be written
|
| FILEOUTPFX        Specifies an optional prefix for    nonmem (Opt)
|                   the names of all output files
|
| FILEOUTQFR        Specifies the qualifier to be       csv (Req)
|                   applied to the names of all output
|                   files
|
| FILEOUTSFX        Specifies an optional suffix for    [blank] (Opt)
|                   the names of all output files
|
| OUTDATE           Specifies the name to be used for   date (Req) 
|                   the (formatted) date column in the 
|                   output file
|
| OUTTIME           Specifies the name to be used for   tim2 (Req) 
|                   the (formatted) time column in the 
|                   output file
|
| SORTBY            Specifies the variables to be       &g_subjid visitnum (Req)
|                   used to sort the output file(s)
|
| SPLITMODE         Specifies the method for splitting  VARS (Req)
|                   the NONMEM data into multiple 
|                   output files
|
| SPLITPROP         Specifies (when SPLITMODE=PROP is   1/3 (Opt)
|                   chosen) what proportion of 
|                   randomly selected subjects shall be placed into the first of the two output files
|
| SPLITVARS         Specifies the variable(s) by which  [blank] (Opt)
|                   the NONMEM data shall be split 
|                   into multiple output files
|
| TIMEVAR           Specifies the name to be used for   time (Req)
|                   the relative time column in the 
|                   output file
|
| UNITPAIRS         Specifies units variables           amt=doseunit (Opt)
|
|
| Output: This macro produces a set of NONMEM-ready files
|
| Global macro variables created:  None
|
| Macros called:
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_chkvarsexist
| (@) tu_chkvartype
| (@) tu_words
| (@) tu_nobs
| (@) tu_unitpairs
| (@) tu_sqlnlist
| (@) tu_tidyup
| (@) tu_abort
|
| Example:
|
| %tu_cr8nm(dsetin = work.nonmem
|          ,fileoutdir = /arenv/arprod/c/s/r/pkdata
|          );
|
|******************************************************************************* 
| Change Log 
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     05-Jul-2005
| New version number:       1/2
| Modification ID:          AR1
| Reason For Modification:  Make correction to %IF statement for validation of SPLITVARS.
|                           Do not validate COLORDER when blank (it is optional).
|                           Correct the default values for OUTDATE/OUTTIME in comment header.
|                           Allow dataset options on DSETIN.
|                           Add DROP parameter. 
|                           Finish-off the list of sub-macros.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     29-Jul-2005
| New version number:       1/3
| Modification ID:          AR3
| Reason For Modification:  Add extra validation for OUTDATE, OUTTIME, and TIMEVAR (must
|                           be numeric).
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     07-Sep-2005
| New version number:       1/4
| Modification ID:          AR4
| Reason For Modification:  Fix: Remove extraneous bracket.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     20-Sep-2005
| New version number:       1/5
| Modification ID:          AR5
| Reason For Modification:  Prohibit use of percent and ampersand as DCDSEP.
|                           Modify generated code dependant upon whether each
|                           SPLITVARS variable is num or char.
|                           When SPLITMODE is NONE, place no text between prefix 
|                           and suffix.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     22-Sep-2005
| New version number:       1/6
| Modification ID:          AR6
| Reason For Modification:  Use slashes between parts of date instead of hyphens.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     22-Sep-2005
| New version number:       1/7
| Modification ID:          AR7
| Reason For Modification:  Fix: *Randomly* assign subjects when splitmode=prop.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     22-Sep-2005
| New version number:       1/8
| Modification ID:          AR8
| Reason For Modification:  Do not issue message(s) if any DROP variables are 
|                           not present in DSETIN.
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

%macro tu_cr8nm(
                colorder   =        /* Column order */
               ,dcdsep     = !      /* Decode separator */
               ,drop       =        /* Variables that shall not be in output file(s) */
               ,dsetin     =        /* type:ID Name of input "NONMEM" dataset */
               ,fileoutdir =        /* Directory for output file(s) */
               ,fileoutpfx = nonmem /* Optional prefix for all output files */
               ,fileoutqfr = csv    /* Qualifier for all output files */
               ,fileoutsfx =        /* Optional suffix for all output files */
               ,outdate    = date   /* Name of date column in output file */
               ,outtime    = tim2   /* Name of time column in output file */
               ,sortby     = &g_subjid visitnum /* Variable(s) by which the file(s) shall be sorted */
               ,splitmode  = VARS   /* Method for splitting the data into multiple output files */
               ,splitprop  = 1/3    /* Proportion of split to be placed into 1st file */
               ,splitvars  =        /* Variable(s) by which output shall be split */
               ,timevar    = time   /* Name of relative time column in output file */
               ,unitpairs  = amt=doseunit /* Pairs of variables and units variables to be used as headers in output files, e.g. age=ageu height=heightu */
               );

  /* Echo parameter values and global macro variables to the log */
 
  %local MacroVersion;
  %let MacroVersion = 1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_subjid);

  %local prefix;
  %let prefix = %substr(&sysmacroname,3); 

  %let splitmode = %upcase(&splitmode);
  %let outtime = %upcase(&outtime);
  %let outdate = %upcase(&outdate);

  /* PARAMETER VALIDATION */

  /* Validate - DROP - none required */  /*AR8*/

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
  %end;

  /* Validate - FILEOUTDIR */
  data _null_;
    length DirExist $8;
    DirExist='';
    rc=filename(DirExist,"&fileoutdir.");
    sysmsg=sysmsg();
    if rc ne 0 then
    do;  /* FILENAME failed */
      put 'RTE' "RROR: &sysmacroname: " sysmsg;
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

  /* Validate - FILEOUTPFX - no validation required (optional character string) */

  /* Validate - FILEOUTSFX - no validation required (optional character string) */

  /* Validate - FILEOUTQFR */
  %if %length(&fileoutqfr) eq 0 %then  /*AR3*/
  %do;
    %put RTE%str(RROR): &sysmacroname.: FILEOUTQFR must not be blank;
    %let g_abort=1;
  %end;

  /* Validate - SPLITMODE */
  %if &splitmode ne VARS and &splitmode ne PROP and &splitmode ne NONE %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: The SPLITMODE value (&splitmode) is invalid. Valid values are: VARS, PROP, and NONE;
    %let g_abort=1;
  %end;

  /* Validate - SPLITPROP - cannot conveniently check that it resolves to a (probably non-integer) numeric value*/
  %if &splitmode eq PROP %then
  %do;
    %if %length(&splitprop) eq 0 %then
    %do;
      %put RTE%str(RROR): &sysmacroname.: When SPLITMODE is PROP, a value for SPLITPROP must be supplied;
      %let g_abort=1;
    %end;
  %end;

  /* Validate - SPLITVARS */  
  %if &splitmode eq VARS %then  /*AR1*/
  %do;
    %if %length(&splitvars) eq 0 %then
    %do;
      %put RTE%str(RROR): &sysmacroname.: SPLITMODE is VARS, SPLITVARS must not be blank;
      %let g_abort=1;
    %end;
    %else %if %length(%tu_chkvarsexist(&dsetin,&splitvars)) ne 0 %then  /*AR4*/
    %do;
      %put RTE%str(RROR): &sysmacroname.: SPLITMODE is VARS, but one or more of the variable(s) supplied for SPLITVARS (&splitvars) do not exist in DSETIN (&dsetin);
      %let g_abort=1;
    %end;
  %end;

  /* Validate - SORTBY */
  %if %length(&sortby) eq 0 or %length(%tu_chkvarsexist(&dsetin,&sortby)) ne 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: One or more of the variable(s) specified for SORTBY (&sortby) do not exist in DSETIN (&dsetin);
    %let g_abort=1;
  %end;

  /* Validate - DCDSEP */
  %let dcdsep = %nrbquote(&dcdsep);
  %if %length(&dcdsep) ne 1 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: DCDSEP (&dcdsep) is invalid, it must be a single character;
    %let g_abort=1;
  %end;

  %else  /*AR5*/
  %do;
    %if &dcdsep eq %nrbquote(%) or
        &dcdsep eq %nrbquote(&) 
        %then
    %do;
      %put RTE%str(RROR): &sysmacroname.: The value specified for DCDSEP (&dcdsep) is invalid;
      %let g_abort=1;
    %end;
  %end;

  /* Validate - UNITPAIRS - validated by %tu_unitpairs */

  /* Validate - OUTDATE */
  %if %length(&outdate) eq 0 or %length(%tu_chkvarsexist(&dsetin,&outdate)) ne 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: The variable specified for OUTDATE (&outdate) do not exist in DSETIN (&dsetin);
    %let g_abort=1;
  %end;
  %else %if %tu_chkvartype(&dsetin,&outdate) ne N %then    /*AR3*/
  %do;
    %put RTE%str(RROR): &sysmacroname.: The variable specified for OUTDATE (&outdate) must be numeric;
    %let g_abort=1;
  %end;

  /* Validate - OUTTIME */
  %if %length(&outtime) eq 0 or %length(%tu_chkvarsexist(&dsetin,&outtime)) ne 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: The variable specified for OUTTIME (&outtime) do not exist in DSETIN (&dsetin);
    %let g_abort=1;
  %end;
  %else %if %tu_chkvartype(&dsetin,&outtime) ne N %then    /*AR3*/
  %do;
    %put RTE%str(RROR): &sysmacroname.: The variable specified for OUTTIME (&outtime) must be numeric;
    %let g_abort=1;
  %end;

  /* Validate - TIMEVAR */
  %if %length(&timevar) eq 0 or %length(%tu_chkvarsexist(&dsetin,&timevar)) ne 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: The variable specified for TIMEVAR (&timevar) do not exist in DSETIN (&dsetin);
    %let g_abort=1;
  %end;
  %else %if %tu_chkvartype(&dsetin,&timevar) ne N %then    /*AR3*/
  %do;
    %put RTE%str(RROR): &sysmacroname.: The variable specified for TIMEVAR (&timevar) must be numeric;
    %let g_abort=1;
  %end;

  /* Validate - COLORDER */
  %if %length(&colorder) gt 0 %then   /*AR1*/
  %do;
    %if %length(%tu_chkvarsexist(&dsetin,&colorder)) ne 0 %then
    %do;
      %put RTE%str(RROR): &sysmacroname.: One or more of the variables specified for COLORDER (&colorder) does not exist in DSETIN (&dsetin);
      %let g_abort=1;
    %end;
  %end;

  %tu_abort;

  /* NORMAL PROCESSING */

  /*
  / PLAN OF ACTION:
  / Regardless of the splitmode we will build datasets and
  /  a macro array in order to specify to the last step
  /  what datasets to write. For example:
  /
  /  outFile0 = 3
  /  outFile1 = _alyte1, outDset1=split1
  /  outFile1 = _alyte2, outDset1=split2
  /  outFile1 = _alyte3, outDset1=split3
  /
  / 1. If VARS, produce datasets split by VARS, and update macro array
  / 2. If PROP, produce datasets split by PROP, and update macro array
  / 3. If NONE, simply update the macro array
  / 4. Rename vars with units
  / 5. For each split dataset, write the file
  /------------------------------------------------------*/

  %local currentDataset;
  %let currentDataset = &dsetin;

  %local outFile0 ptr;

  /* 1. If VARS, produce datasets split by VARS, and update macro array */
  %if &splitmode eq VARS %then
  %do;  /* splitmode=vars */

    /* What combinations do we have? */
    proc summary data=&currentDataset nway;
      class &splitvars;
      output out=work.&prefix._splitvar10;
    run;

    %let splitv0 = %tu_words(&splitvars);
    %do ptr = 1 %to &splitv0;
      %local splitv&ptr splitvType&ptr;
      %let splitv&ptr = %scan(&splitvars,&ptr);
      %let splitvType&ptr = %tu_chkvartype(&dsetin,&&splitv&ptr);  /*AR5*/
    %end;

    %if &g_debug ge 1 %then  /*AR5*/
    %do;
      %put RTD%str(EBUG): &sysmacroname: SPLITV0=&splitv0;
      %do ptr= 1 %to &splitv0;
        %put RTD%str(EBUG): &sysmacroname: SPLITV&ptr=&&splitv&ptr, SPLITVTYPE&ptr=&&splitvtype&ptr;
      %end;
    %end;

    data _null_;
      call symput('OUTFILE0',putn(nobs,'BEST.'));
      set work.&prefix._splitvar10 nobs=nobs;
      length filename condition $256;
      call symput('OUTDSET'!!compress(putn(_n_,'BEST.'))
                 ,"&prefix._SPLIT"!!compress(putn(_n_,'BEST.')));
      %do ptr = 1 %to &splitv0;
        %if &ptr eq 1 %then
        %do;  /* ptr is 1 */
          %if &&splitvtype&ptr eq C %then  /*AR5*/
          %do;
            filename = '_' !! trim(left(&&splitv&ptr));  /*AR5*/
            condition = "&&splitv&ptr eq " !! quote(trim(left(&&splitv&ptr)));
          %end;
          %else
          %do;
            filename = '_' !! compress(putn(&&splitv&ptr,'BEST.'));  /*AR5*/
            condition = "&&splitv&ptr eq " !! compress(putn(&&splitv&ptr,'BEST.'));
          %end;
        %end; /* ptr is 1 */
        %else
        %do;  /* ptr is not 1 */
          %if &&splitvtype&ptr eq C %then  /*AR5*/
          %do;
            filename = trim(filename) !! '_' !! trim(left(&&splitv&ptr));
            condition = trim(condition) !! " and &&splitv&ptr eq " !! quote(trim(left(&&splitv&ptr)));
          %end;
          %else
          %do;
            filename = trim(filename) !! '_' !! compress(putn(&&splitv&ptr,'BEST.'));
            condition = trim(condition) !! " and &&splitv&ptr eq " !! compress(putn(&&splitv&ptr,'BEST.'));
          %end;
        %end; /* ptr is not 1 */
      %end;
      call symput('OUTFILE'!!compress(putn(_n_,'BEST.'))
                 ,trim(filename));
      call symput('OUTCOND'!!compress(putn(_n_,'BEST.'))
                 ,trim(condition));
    run;
    %if &g_debug ge 1 %then
    %do;
      %put RTD%str(EBUG): &sysmacroname: OUTFILE0=&outfile0;
      %do ptr= 1 %to &outfile0;
        %put RTD%str(EBUG): &sysmacroname: OUTFILE&ptr=&&outfile&ptr, OUTDSET&ptr=&&outdset&ptr, OUTCOND&ptr=&&outcond&ptr;
      %end;
    %end;

    data %do ptr = 1 %to &outfile0;
           &&outdset&ptr
         %end;
         ;
      set &currentDataset;
      select;
        %do ptr = 1 %to &outfile0;
          when (&&outcond&ptr) OUTPUT &&outdset&ptr;
        %end;
      end; /* select */
    run;

  %end; /* splitmode=vars */

  /* 2. If PROP, produce datasets split by PROP, and update macro array */
  %else %if &splitmode eq PROP %then
  %do;  /* splitmode=prop */
    %let outFile0 = 2;
    %let outFile1 = _prop1; %let outDset1 = &prefix._prop1;  /*AR5*/
    %let outFile2 = _prop2; %let outDset2 = &prefix._prop2;  /*AR5*/

    /* Deduce the number of subjects */
    %local numSubj;

    proc freq data=&currentDataset;
      table &g_subjid / noprint out=work.&prefix._freq;
    run;

    %let numSubj = %tu_nobs(work.&prefix._freq);

    /* Deduce number of subjects in first part */
    %local numSubjPart1;

    data _null_;  /* Use DATA step for non-integer arithmetic */
      partOne = &numSubj * &splitprop;
      /* Round-up to nearest integer */
      numSubjPart1 = ceil(partOne);
      call symput('NUMSUBJPART1',compress(putn(numSubjPart1,'BEST.')));
    run;
    %if &g_debug ge 1 %then
      %put RTD%str(EBUG): &sysmacroname: NUMSUBJ=&numSubj, SPLITPROP=&splitprop, NUMSUBJPART1=&numSubjPart1;

    /* Randomly assign subjects to parts */  /*AR7*/
    data work.&prefix._assign;
      set work.&prefix._freq (keep=subjid);
      keep part subjid;
      array choice (&numsubjpart1) _temporary_;
      if _n_ eq 1 then
      do;  /* generate random array of subjids to be assigned to part1 */
        do i = 1 to &numsubjpart1;
          newChoiceMade = 0;
          do until(newChoiceMade);
            possibleChoice = int(&numsubj * ranuni(0)) + 1;
            /* Is possibleChoice already in the choice array? */
            choiceIsBad = 0;
            do j = 1 to i-1 until(choiceIsBad);
              if possibleChoice eq choice(j) then choiceIsBad = 1;
            end;
            /* Use the choice if not already used */
            if not choiceIsBad then 
            do;
              newChoiceMade = 1;
              choice(i) = possibleChoice;
            end;
          end;
        end;
      end; /* generate array of subjids in part1 */
      /* Now handle/assign each subject row */
      part = 2;
      do ptr = 1 to &numsubjpart1;
        if choice(ptr) eq _n_ then 
        do;
          part = 1;
          LEAVE;
        end;
      end;
    run;

    /* Split into two parts */
    proc sort data=&currentDataset out=work.&prefix._sort;
      by &g_subjid;
    run;

    data &outDset1 &outDset2;
      merge work.&prefix._sort
            work.&prefix._assign
            ;
      by &g_subjid;
      drop part;
      select (part);
        when (1) OUTPUT &outDset1;
        when (2) OUTPUT &outDset2;
      end;
    run;

  %end; /* splitmode=prop */

  /* 3. If NONE, simply update the macro array */
  %else %if &splitmode eq NONE %then
  %do;  /* splitmode=none */

    %let outFile0 = 1;
    %let outFile1 = ;   /*AR5*/
    %let outDset1 = &currentDataset;

  %end; /* splitmode=none */

  /* 4. Rename vars with units */

  /* Save Option VALIDVARNAME to restore later */
  %local validvarnameOption;
  %let validvarnameOption=%sysfunc(getoption(VALIDVARNAME));
  options validvarname=any;

  %do ptr = 1 %to &outFile0;

    %tu_unitpairs(dsetin          = &&outDset&ptr
                 ,dsetout         = work.&prefix._unitpairs&ptr
                 ,unitpairs       = &unitpairs
                 ,colorder        = &colorder
                 );
    %let outDset&ptr = &prefix._unitpairs&ptr;

  %end; /* do over outfile0 */

  /* 5. For each split dataset, write the file */
  %do ptr = 1 %to &outFile0;

    %local idx;

    /* Get PROC CONTENTS information about variables */
    proc contents data=&&outDset&ptr  /*AR8*/
                  out=work.&prefix._cont&ptr 
                  noprint;
    run;

    proc sort data=work.&prefix._cont&ptr out=work.&prefix._contS&ptr;
      by varnum;
    run;

    /* Build a macro array of the Contents, i.e. name, type */  
    %local contname0;
    data _null_;
      set work.&prefix._contS&ptr end=finish;
      retain counter 0;
      /* Do not proceed if this var is in DROP */  /*AR8*/
      dropper = 0;
      do i = 1 to %tu_words(&drop) while(not dropper);
        if upcase(scan("&drop",i)) eq upcase(name) then
        do;  /* We found a dropper */
          %if &g_debug ge 1 %then
          %do;
            put "RTD" "EBUG: &sysmacroname: Dropping " name;
          %end;
          dropper = 1;;
        end; /* We found a dropper */
      end;

      if not dropper then
      do;
        /* We do need to write this variable to the file */
        counter = counter + 1;
        call symput('CONTNAME'!!compress(putn(counter,'BEST.'))
                   ,upcase(name)
                   );
        call symput('CONTTYPE'!!compress(putn(counter,'BEST.'))
                   ,compress(putn(type,'BEST.'))
                   );
      end;

      if finish then
        call symput('CONTNAME0'
                   ,compress(putn(counter,'BEST.'))
                   );
    run;
    %if &g_debug ge 1 %then  /*AR9*/
    %do;
      %put RTD%str(EBUG): &sysmacroname: CONTNAME0=&contname0;
      %do idx=1 %to &contname0;
        %put RTD%str(EBUG): &sysmacroname: CONTNAME&idx=&&contname&idx, CONTTYPE&idx=&&conttype&idx;
      %end;
    %end;  /*AR9*/

    /* Build decodes (for chars, i.e. type==2) */
    %let currentDataset = &&outDset&ptr;
    %local thisVar;
    %do idx=1 %to &contname0;

      %let thisVar = &&contname&idx;

      %if &&conttype&idx eq 1 %then
      %do;  /* Numeric: probably no decode reqd */

        %if "&thisVar" eq "&outdate" %then
          %let contdecode&idx = YYYY/MM/DD;  /*AR6*/
        %else %if "&thisVar" eq "&outtime" %then
          %let contdecode&idx = HH:MM;
        %else
          %let contdecode&idx = ;

      %end; /* Numeric: probably no decode reqd */
      %else
      %do;  /* Character: must create decode */

        proc freq data=&&outDset&ptr;
          table &thisVar / noprint out=work.&prefix._&ptr._dcda&idx;
        run;

        /* Join _CR8NM_units2 with _cr8nmx_2_dcd12 */
        /*   on unit2.ind == dcd12.ind             */
        /* Replace unit2.ind with dcd12.ind._N_    */

        data work.&prefix._&ptr._dcdb&idx;
          set work.&prefix._&ptr._dcda&idx;
          where &thisVar ne '';
          keep &thisVar decode_&thisVar;
          decode_&thisVar = _n_;
        run;

        proc sql noprint;
          create table work.&prefix._&ptr._dcdc&idx as 
            select a.*
                   , b.decode_&thisVar
            from &currentDataset a 
                 left join 
                 work.&prefix._&ptr._dcdb&idx b
            on a.&thisVar eq b.&thisVar
            order %tu_sqlnlist(&sortby)
            ;
        quit;
        %let currentDataset = work.&prefix._&ptr._dcdc&idx;

        data _null_;
          set work.&prefix._&ptr._dcdb&idx end=finish;
          length string $2048;
          retain string;
          if _n_ ne 1 then
            string = trim(string) !! "&dcdsep";
          string = trim(string)
                   !! trim(&thisVar)
                   !! '='
                   !! compress(putn(decode_&thisVar,'BEST.'))
                   ;
          if finish then
          do;
            %if &g_debug ge 1 %then  /*AR9*/
            %do;
              put "RTD" "EBUG: &sysmacroname: STRING set to: " string;
            %end;  /*AR9*/
            call symput("CONTDECODE&idx",string);
          end;
        run;

      %end; /* Character: must create decode */

    %end; /* Do over contname0 */

    %if &g_debug ge 1 %then
    %do;
      %do idx=1 %to &contname0;
        %put RTD%str(EBUG): &sysmacroname: CONTNAME&idx=%trim(&&contname&idx), CONTDECODE&idx=&&contdecode&idx;
      %end;
    %end;

    /* Write the data */
    data _null_;
      set &currentDataset;
      file "&fileoutdir/&fileoutpfx.&&outFile&ptr..&fileoutsfx..&fileoutqfr" 
           dsd delimiter=',';
      format &outdate yymmdds10.  /*AR6*/
             &outtime time5.
             &timevar 8.2;
      if _n_ eq 1 then
      do;
        /* Header (column names) */
        put '#'
            %do idx=1 %to &contname0;
              "%trim(&&contname&idx)"
              %if &idx lt &contname0 %then ",";
            %end;
            ;
        /* Row#2 (decodes) */
        put '#'
            %do idx=1 %to &contname0;
              "%trim(%nrbquote(&&contdecode&idx)) "  /* Space reqd in case null */
              %if &idx lt &contname0 %then ",";
            %end;
            ;
      end;
      put %do idx=1 %to &contname0;

            %if &&conttype&idx eq 1 %then
              "%trim(&&contname&idx)"n;
            %else
              "decode_%trim(&&contname&idx)"n;

          %end;
          ;
    run;

  %end; /* do over outfile0 */

  /* Restore Option VALIDVARNAME */
  options validvarname=&validvarnameOption;

  /* Finish-off */
  %tu_tidyup(rmdset=&prefix:
            ,glbmac=NONE
            );
  quit;

  %tu_abort;

%mend tu_cr8nm;
