/*******************************************************************************
|
| Macro Name:     tc_wnlexcl.sas
|
| Macro Version:  1
|
| SAS Version:    8.2
|
| Created By:     Trevor Welby
|
| Date:           13th December 2004
|
| Macro Purpose:  This macro shall be a part of the creation suite of macros to
|                 merge post-WNL exclusions onto the specified input dataset.
|
| Macro Design:   Procedure style
|
| Input Parameters:
|
| NAME            DESCRIPTION                                    DEFAULT
| BY              Specifies the variables by which the merge     pcsmpid pcan (Req)
|                 shall be performed
|
| DSETIN          Specifies the name of the input dataset to     ardata.pkcnc (Req)
|                 which the exclusions are to be added
|
| DSETOUT         Specifies the name of the output dataset       ardata.pkcnc (Req)
|
| EXCLFILEMASK    Specifies a mask for exclusion files to        [blank] (Opt) [TQW9753.01-008]
|                 be read.  The character "*" shall be used
|                 as the wild card, representing any number
|                 of characters.
|
|                 For example: CSVFILE*PARAMS.CSV
|
|                 Exclusion files are read from the input
|                 directory specified by &g_dmdata.
|
|                 At least one exclusion file must be present
|                 in the directory
|
| EXCLVAR         Specifies the name of the dsetin datasets      pcprox (Req)
|                 exclusion flag variable whose values are
|                 to be replaced
|
|
| XCPFILE         Specifies the value to be passed to            &g_pkdata/&g_fnc._recon (Opt)
|                 %tu_xcpinit's outfile parameter
|
| JOINMSG         Specifies whether unmatched PK concentration   %str(ERRO)R (Opt) [TQW9753.01-008]
|                 records and post WNL exclusion records should
|                 be treated as %str(WARN)INGS, %str(ERRO)RS or
|                 %str(NOT)ES
|
|                 Valid values: %str(WARN)ING, %str(ERRO)R
|                               %str(NOT)E
|
| Output:         The macro shall create the dataset specified
|                 by the DSETOUT parameter.   The variable
|                 specified by the EXCLVAR parameter will be
|                 re-populated to indicate excluded records
|                 (if any)
|
| Global macro variables created: none
|
| Macros called:
|(@) tr_putlocals
|(@) tu_putglobals
|(@) tu_abort
|(@) tu_byid
|(@) tu_getmaskedfiles
|(@) tu_xcpinit
|(@) tu_xcpsectioninit
|(@) tu_xcpput
|(@) tu_xcpsectionterm
|(@) tu_xcpterm
|(@) tu_chknames
|(@) tu_chkvarsexist
|(@) tu_words
|(@) tu_varattr
|(@) tu_maclist
|(@) tu_dsetattr
|(@) tu_tidyup
|
| Example: %tc_wnlexcl(by=pcsmpid pcan
|                     ,dsetin=ardata.pkcnc
|                     ,dsetout=ardata.pkcnc
|                     ,exclfilemask=GSK000*
|                     ,exclvar=pcprox
|                     ,xcpfile=&g_pkdata/&g_fnc._recon
|                     ,joinmsg=%str(ERRO)R
|                     );
|
|*******************************************************************************
| Change Log
|
| Modified By:  Trevor Welby
| Date of Modification: 15-Dec-2004
| New version/draft number: 01-002
| Modification ID: TQW9753.01-002
| Reason For Modification: Add a call to %tu_abort at the end of the macro call
|
|*******************************************************************************
| Change Log
|
| Modified By:  Trevor Welby
| Date of Modification: 15-Dec-2004
| New version/draft number: 01-003
| Modification ID: TQW9753.01-003
| Reason For Modification: Modify the call to %tidyup so that only work datasets
|                          prefixed with &prefix: are deleted
|
|*******************************************************************************
| Change Log
|
| Modified By:  Trevor Welby
| Date of Modification: 15-Dec-2004
| New version/draft number: 01-004
| Modification ID: TQW9753.01-004
| Reason For Modification: Take the temporary dataset created by PROC IMPORT and
|                          reset the lengths of the variables specified by the
|                          BY parameter to match those of the dataset plan
|
|*******************************************************************************
| Change Log
|
| Modified By:  Trevor Welby
| Date of Modification: 20-Dec-2004
| New version/draft number: 01-005
| Modification ID: TQW9753.01-005
| Reason For Modification:  The call to %tu_abort, immediately following the datastep
|                           that performs the merge, now specifies option=force.
|                           No output dataset will be produced when exception
|                           message(s) of type ERR!!OR are written
|
|                           The merge now outputs only those records in the
|                           PK Concentrations dataset
|
|                           The temporary variable __msg is now dropped
|
|*******************************************************************************
| Change Log
|
| Modified By:  Trevor Welby
| Date of Modification: 21-Dec-2004
| New version/draft number: 01-006
| Modification ID: TQW9753.01-006
| Reason For Modification: Change the name of the dataset created by
|                          %tu_readdsplan from work.dsplan to work.&prefix._dsplan
|                          so that the dataset is deleted by %tu_tidyup.
|
|*******************************************************************************
| Change Log
|
| Modified By:  Trevor Welby
| Date of Modification: 12-Jan-05
| New version/draft number: 01-007
| Modification ID: TQW9753.01-007
| Reason For Modification:  The macro was not returning an error message when no
|                           masked files were identified. The MINFILES=1 option
|                           is set on the call to the %tu_getmaskedfiles call to
|                           solve this issue.
|
|*******************************************************************************
| Change Log
|
| Modified By:  Trevor Welby
| Date of Modification: 07-Feb-05
| New version/draft number: 01-008
| Modification ID: TQW9753.01-008
| Reason For Modification:  Change the JOINMSG parameter to optional in the
|                           program header
|
|                           Add a the validation previously left out from the
|                           erro!!r processing section i.e. Verify that the
|                           input file column header contains the BY variables
|
|                           The parameter EXCLFILEMASK is now an optional
|
|                           Retrieve the attributes of the BY variables from
|                           the dataset specified by the DSETIN parameter.
|                           i.e. removed calls to tu_readdsplan and
|                           tu_isvarindsplan added call to tu_varattr
|
|*******************************************************************************
| Change Log
|
| Modified By: Trevor Welby
| Date of Modification: 18-Feb-05
| New version/draft number: 01-009
| Modification ID: TQW9753.01-009
| Reason For Modification:  
|
|                           The macro previously used PROC IMPORT to read the 
|                           Exception Files. This caused problems with conflicting 
|                           data types for variables in the prevailing Exclusions 
|                           and DSETIN Datasets. PROC IMPORT has been removed.
|
|                           The macro now strips the record delimiter from the 
|                           Exclusion Files i.e. the HEX Character '0d'x. 
|                           Previously, this has been known to cause a problem 
|                           on the UNIX platform.
|
|                           Pass XCPFILE to tu_xcpinit
|
|                           Only create an Output Dataset when G_ABORT EQ 0
|
|                           Add Validation:
| 
|                           Verify that the variables specified by the BY 
|                           parameter uniquely identify each record in DSETIN.
|                           This is conditional on the existence of BY variables 
|                           in DSETIN.
|
|                           Verify that the variables specified by the BY 
|                           parameter uniquely identify each record in each
|                           Exclusion File
|
|*******************************************************************************
| Change Log
|
| Modified By: Trevor Welby
| Date of Modification: 25-Feb-05
| New version/draft number: 01-010
| Modification ID: TQW9753.01-010
| Reason For Modification: 
|                          Remove tab characters from the source code and corrected
|                          indentation
|
|                          The test of DSETIN existence was augmented by a 
|                          check to see that it is not blank
|
|                          _EFIERR_ macro variable now removed
|
|                          Warning message now removed when an input file does not 
|                          have data rows
|
|                          The macro was incorrectly passing the wrong dataset
|                          to the %tu_byid macro. This is now corrected
|
|*******************************************************************************
| Change Log
|
| Modified By:
| Date of Modification:
| New version/draft number:
| Modification ID:
| Reason For Modification:
|
********************************************************************************/

%macro tc_wnlexcl(by=pcsmpid pcan                   /* Merge by variables(s) */
                 ,dsetin=ardata.pkcnc               /* type:ID Input dataset */
                 ,dsetout=ardata.pkcnc              /* Output dataset */
                 ,exclfilemask=                     /* Input file mask */
                 ,exclvar=pcprox                    /* Name of exclusion flag variable */
                 ,xcpfile=&g_pkdata/&g_fnc._recon   /* Location/name of exception report */
                 ,joinmsg=%str(ERR)OR               /* Unmatched PKCNC and WNLEXCL records treated as warnings/ errors */
                 );

  /*
  / Echo values of parameters and global macro variables to the log.
  /------------------------------------------------------------------------------*/
  %local MacroVersion;
  %let MacroVersion=1;
  %include "&g_refdata./tr_putlocals.sas";
  %tu_putglobals(varsin=g_dmdata);

  /*
  / Prefix for temporary work datasets
  /------------------------------------------------------------------------------*/
  %local prefix;
  %let   prefix=_wnlexcl;

  /*
  / Perform parameter validation
  /------------------------------------------------------------------------------*/

  /*
  / verify BY parameter is not missing
  /------------------------------------------------------------------------------*/
  %if %bquote(&by) eq %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: Macro parameter BY (by=&by) is missing;
    %let g_abort=1;
  %end;

  /*
  / verify DSETOUT parameter is not missing
  /------------------------------------------------------------------------------*/
  %if %bquote(&dsetout) eq %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: Macro parameter DSETOUT (dsetout=&dsetout) is missing;
    %let g_abort=1;
  %end;

  /*
  / Verify EXCLFILEMASK is not missing
  /------------------------------------------------------------------------------*/
  %if %bquote(&exclfilemask) eq %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: Macro parameter EXCLFILEMASK (exclfilemask=&exclfilemask) is missing;
    %let g_abort=1;
  %end;

  /*
  / verify EXCLVAR parameter is not missing
  /------------------------------------------------------------------------------*/
  %if %bquote(&exclvar) eq %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: Macro parameter EXCLVAR (exclvar=&exclvar) is missing;
    %let g_abort=1;
  %end;

  /*
  / verify XCPFILE parameter is not missing
  /------------------------------------------------------------------------------*/
  %if %bquote(&xcpfile) eq %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: Macro parameter XCPFILE (xcpfile=&xcpfile) is missing;
    %let g_abort=1;
  %end;

  /*
  / Verify that the dataset DSETIN exists [TQW9753.01-010]
  /------------------------------------------------------------------------------*/
  %if %length(&dsetin) eq 0 or not %sysfunc(exist(&dsetin)) %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: Macro Parameter DSETIN (dsetin=&dsetin) dataset does not exist;
    %let g_abort=1;
  %end;

  /*
  / Verify DSETOUT is a valid dataset name
  /------------------------------------------------------------------------------*/
  %if %nrbquote(%tu_chknames(&dsetout,data)) ne %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: Macro Parameter DSETOUT (dsetout=&dsetout) is not a valid dataset name;
    %let g_abort=1;
  %end;

  /*
  / Verify BY exists in the DSETIN dataset
  /------------------------------------------------------------------------------*/
  %if %length(%tu_chkvarsexist(&dsetin,&by)) ne 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: Macro Parameter BY (by=&by) one or more variables do not exist in %upcase(&dsetin);
    %let g_abort=1;
  %end;
  %else
  %do;  /* Verify Uniqueness of BY variables */

    /*
    / Verify that the BY variables uniquely identify records in DSETIN
    /------------------------------------------------------------------------------*/
    proc freq data=&dsetin;
    table %sysfunc(translate(&by,'*',' '))/noprint 
                                           out=&prefix._BY_Unique (keep  = &by count 
                                                                   where = (count>1)
                                                                  );
    run;

    %local dsetnobs;
    %let dsetnobs=%tu_dsetattr(dsetin=_wnlexcl_BY_Unique,attrib=nobs);

    %if (&dsetnobs ne 0) %then
    %do;
      %put RTE%str(RROR): &sysmacroname.: Macro Parameter BY (by=&by) does not uniquely identify records in DSETIN;
      %let g_abort=1;
    %end;

  %end;  /* Verify Uniqueness of BY variables */

  /*
  / Verify EXCLVAR exists on the DSETIN dataset
  /------------------------------------------------------------------------------*/
  %if %length(%tu_chkvarsexist(&dsetin,&exclvar)) ne 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: Macro Parameter EXCLVAR (exclvar=&exclvar), variable does not exist on %upcase(&dsetin);
    %let g_abort=1;
  %end;

  %tu_abort;

  /*
  / Perform Normal Processing
  /------------------------------------------------------------------------------*/
  
  /*
  / Number of exclusion files
  /------------------------------------------------------------------------------*/
  %local number_of_files;

  /*
  / Create a dataset of exclusion file names base upon the parameter EXCLFILEMASK
  /------------------------------------------------------------------------------*/
  %tu_getMaskedFiles(inmask=&g_dmdata./&exclfilemask /* Input file mask          */
                    ,dsetout=work.&prefix._memNames  /* Temporary output dataset */
                    ,nummvar=number_of_files         /* Number of exclusion files*/
                    ,minfiles=1                      /* Minmium number of files  */
                    );

  /*
  / Assign each exclusion file name to a macro variable
  /------------------------------------------------------------------------------*/
  %local ptr;

  %do ptr=1 %to &number_of_files;
    %local exclfile&ptr.;
  %end;

  proc sql noprint;
    select distinct memName
    into : exclfile1 -: exclfile&number_of_files.
    from work.&prefix._memNames
    ;
  quit;

  /*
  / Initialise a temporary base dataset for appending exclusion datasets
  /------------------------------------------------------------------------------*/
  data work.&prefix._exclusions;
    set &dsetin (keep=&by);
    stop;
  run;

  /* Number of BY variables */
  %local num_of_by_vars;

  %let num_of_by_vars=%tu_words(&by);

  /*
  / Create a macro variable with the value of the BY variable name
  / to be used in the loop [TQW9753.01-008]
  /------------------------------------------------------------------------------*/
  %local i;

  %do i=1 %to &num_of_by_vars;
    %local byvar&i;
  %end;

  %local var_not_used;

  %tu_maclist(string=%upcase(&by)
             ,prefix=byvar
             ,delim=%str(' ')
             ,cntname=var_not_used
             ,scope=local
             );

  %do ptr=1 %to &number_of_files;  /* loop for each exclusion file */

    /*
    / Get a list of variable names from first record of the CSV file
    / and assign to the local macro variable HEADERROW [TQW9753.01-008]
    /------------------------------------------------------------------------------*/
    %local headerrow;

    data _null_;
      infile "&g_dmdata./&&exclfile&ptr." lrecl=32767 obs=1;
      input;

      /*
      /  When running the code in the UNIX environment
      /  this strips off the hex character '0d'x  
      /  used to indicate the end of record in DOS/Windows [TQW9753.01-009]
      /------------------------------------------------------------------------------*/
      if substr(reverse(trim(_infile_)),1,1) eq '0d'x then 
          _infile_=substr(_infile_,1,length(_infile_)-1);

      call symput('headerrow',translate(_infile_
                                          ,' ',','
                                          )
                 );
      stop;
    run;

    %let headerrow=%upcase(&headerrow);
   
    /* Assign column names to a macro variable */
    %local k;

    %local num_of_xvars;

    %let num_of_xvars=%tu_words(&headerrow);

    %do k=1 %to &num_of_xvars;
      %local xvar&k;
    %end;

    %local var_not_used;

    %tu_maclist(string=&headerrow
               ,prefix=xvar
               ,delim=%str(' ')
               ,cntname=var_not_used
               ,scope=local
               );

    /*
    / Verify that the column header contains the BY variables [TQW9753.01-008]
    /------------------------------------------------------------------------------*/
    %do l=1 %to &num_of_by_vars;
      %if %sysfunc(indexw(&headerrow.,&&byvar&l.))=0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname.: The following BY variable (&&byvar&l.) does not exist on input CSV file (&g_dmdata./&&exclfile&ptr);
        %let g_abort=1;
      %end;
    %end;

    %tu_abort;

    /*
    / Strip units from columns headers eg. "Age_(Years)" to give "Age"
    / (excluding quotes)
    /------------------------------------------------------------------------------*/
    %local srch;
    %local pos;

    %let srch=%str(_%();

    %do k=1 %to &num_of_xvars;
      %let pos=%index(&&xvar&k,&srch);
      %if &pos gt 0 %then
      %do;  /* Strip Units */
        %let xvar&k=%substr(&&xvar&k,1,&pos-1);
      %end;  /* Strip Units */
    %end;

    %local l;
  
    /*
    / If the current input file has data rows then process further
    /------------------------------------------------------------------------------*/
    %local fileHasDataRows;
    %let   fileHasDataRows=N;

    data _null_;
      infile "&g_dmdata./&&exclfile&ptr";
      input;
      if _n_ > 1 then do;
        call symput('fileHasDataRows','Y');
        stop;
      end;
    run;

    %if &fileHasDataRows=Y %then
    %do;  /* Process files with data */

      /* Generate a data step to read the exclusion data, retaining the attributes
      /  of the BY variable(s) from DSETIN and assigning all other variables
      /  a default of $256 bytes [TQW9753.01-009]     
      /---------------------------------------------------------------------------*/
      data &prefix._exclfile&ptr(keep=&by);
        infile "&g_dmdata./&&exclfile&ptr" 
               delimiter=',' 
               dsd 
               lrecl=32767 
               firstobs=2 
               missover
               ;

       input @;

      /*
      /  When running the code in the UNIX environment
      /  this strips off the hex character '0d'x  
      /  used to indicate the end of record in DOS/Windows [TQW9753.01-009]
      /---------------------------------------------------------------------------*/
      if substr(reverse(trim(_infile_)),1,1) eq '0d'x then 
          _infile_=substr(_infile_,1,length(_infile_)-1);

      %local m;

      /* LISTINPUT: Build a variable list for the INPUT statement */
      %local listinput;

      %let listinput=;

      %let by=%upcase(&by);

       %do m=1 %to &num_of_xvars;  /* Loop for each exclusion variable */

        %let xvar&m=%upcase(&&xvar&m);

         /*
         / Determine if the current variable is a BY variable 
         /---------------------------------------------------------------------------*/
         %if %sysfunc( indexw(&by,&&xvar&m) ) %then
         %do;  /* is a BY variable */

          %local vartype;
          %local varlen;

          %let vartype=%tu_varattr(attrib=vartype,dsetin=&dsetin,varin=&&xvar&m);
          %let varlen =%tu_varattr(attrib=varlen ,dsetin=&dsetin,varin=&&xvar&m);

          %if &&vartype=C %then
          %do;
            %let vartype=$;
          %end;
          %else
          %do;
            %let vartype=;
          %end;

           informat &&xvar&m &vartype.&varlen..;
           format &&xvar&m &vartype.&varlen..;
  
          %let listinput=&listinput &&xvar&m &vartype;

          %let vartype=;
          %let varlen=;

         %end;  /* is a BY variable */
         %else
         %do;  /* is Not a BY variable */
           informat &&xvar&m $265.;
          format &&xvar&m $265.;
           %let listinput=&listinput &&xvar&m $;
         %end;  /* is Not a BY variable */

       %end;  /* Loop for each exclusion variable */ 
       ;

      %local n;

      input &listinput.;

      run;

      /*
      / Verify that the BY variables uniquely identify records in the current 
      / Exclusion File
      /------------------------------------------------------------------------------*/
      proc freq data=&prefix._exclfile&ptr;
        table %sysfunc(translate(&by,'*',' '))/noprint 
                                               out=&prefix._BY_ExclUnique (keep  = &by count 
                                                                           where = (count>1)
                                                                           );
      run;

      %local xclnobs;

      %let xclnobs=%tu_dsetattr(dsetin=&prefix._BY_ExclUnique,attrib=nobs);

      %if (&xclnobs ne 0) %then
      %do;
        %put RTE%str(RROR): &sysmacroname.: Macro Parameter BY (by=&by) does not uniquely identify records in the current Exclusions File (&g_dmdata./&&exclfile&ptr);
        %tu_abort(option=force);
      %end;

      /*
      / Append the current exclusion file to build a master dataset
      /------------------------------------------------------------------------------*/
      proc datasets library=work mt=data nolist;
      append base=work.&prefix._exclusions data=&prefix._exclfile&ptr;
      run;
      quit;
    %end; /* Process files with data */

  %end;  /* loop for each exclusion file */

  /*
  /  Sort the DESTIN and the Exclusion datasets by the BY parameter
  /  in preparation for a merge
  /------------------------------------------------------------------------------*/
  proc sort data=work.&prefix._exclusions out=work.&prefix._exclusions;
    by &by;
  run;

  proc sort data=&dsetin out=work.&prefix._pkcnc;
    by &by;
  run;

  /* Initialise exception report  */
  %tu_xcpinit(header=Exception report for WinNonLin Exclusions
             ,outfile=&xcpfile
             );

  /*
  /  Merge the exclusions file onto the DSETIN dataset and output to a dataset
  /  specified by the DSETOUT parameter.  Create an exception report.
  /------------------------------------------------------------------------------*/
  data  work.&prefix._pkcnc_temporary;
    merge work.&prefix._pkcnc      (in=pkcnc  )
          work.&prefix._exclusions (in=wnlexcl)
          end=DataEnd
          ;
    by &by;

    drop __msg;

    /* Initialise exception report section  */
    %tu_xcpsectioninit(header=%str(Date/Time %sysfunc(datetime(),datetime16.)))

    /* Set exclusions for all records to "N" */
    &exclvar="N";

    /* Set exclusions from the master exclusions file to "Y" */
    if wnlexcl then &exclvar="Y";

    /*  Write the exception messages (if applicable) */
    if not pkcnc and wnlexcl then
    do;
      %tu_byid(dsetin=&prefix._exclusions,invars=&by,outvar=__msg); /* [TQW9753.01-010] */
      %tu_xcpput("Record not in PK concentrations file for analyte : "!!__msg,&joinmsg);
    end;

    /* Terminate the section */
    %tu_xcpsectionterm(end=DataEnd);

    /* Output records from the DSETIN dataset only */
    if pkcnc then output;

  run;

  %tu_abort();

  /* Create the Output Dataset (if no previous abort) */
  data &dsetout;
    set work.&prefix._pkcnc_temporary;
  run;

  /* Terminate the exception report */
  %tu_xcpterm;

  %tu_tidyup(rmdset=&prefix:
            ,glbmac=NONE
            );
  quit;

  %tu_abort;

%mend tc_wnlexcl;
