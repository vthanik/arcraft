/*******************************************************************************
|
| Macro Name:      tc_pkpar
|
| Macro Version:   2.2
|
| SAS Version:     9.1
|
| Created By:      James McGiffen / Andrew Ratcliffe (RTSL)
|
| Date:            17-Dec-2004
|
| Macro Purpose:   The purpose of this dataset creation macro is to create an A&R
|                  PKPAR dataset using the dataset plan, parameter files, optional
|                  covariate variables, and an exception report
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME            DESCRIPTION                           REQ/OPT  DEFAULT
| --------------  -----------------------------------   -------  ---------------
|
| CV              Specifies covariate data to be added  Opt      [blank]
|                 to the output file
|
|                 Valid values: For each variable to be
|                 added, the following three or four
|                 attributes shall be specified:
|                 - Mandatory. Dataset name
|                 - Mandatory. Variable name(s).
|                   Surrounded by square brackets
|                 - Mandatory. Variables by which the CV
|                   variable shall be merged with the
|                   DSETINEXP data. Surrounded by square
|                   brackets
|                 - Optional. A where clause to be applied
|                   to the CV dataset during the merge.
|                   Surrounded by square brackets
|                 For example, CV=ardata.demo [age]
|                                 [subjid] ardata.vitals
|                                 [weight] [subjid]
|                                 [visitnum eq 1]
|
| DSETINEXP       Specifies the name of the input         Req   ardata.exposure
|                 exposure dataset
|
| DSETINPKCNC     Specifies the name of the input         Req   ardata.pkcnc
|                 PKCNC dataset
|
| DSETOUT         Specifies the name of the output        Req   ardata.pkpar
|                 A&R PKPAR dataset
|
| PPORRERCSF      Number of significant figures for the   Req   3
|                 calculation of PPORRERC. The lowest 
|                 order (decimal order of the lowest 
|                 value) of PPORRESN will be identified 
|                 for each parameter. All values for that 
|                 parameter will then be rounded to a 
|                 number of decimal places which is 
|                 consistent with 3 significant figures 
|                 for that order.     
|
| PARMFILEMASK    Specifies a mask for parameter files    Req   [blank]
|                 to be read.   The character "*" shall
|                 be used as the wild card, representing
|                 any number of characters.
|
| PRTLFILEMASK    Specifies a mask for partial files to   Opt   [blank]
|                 be read.  The character "*" shall be
|                 used as the wild card, representing
|                 any number of characters.
|
| XCPFILE         Specifies the value to be passed to     Req   &g_pkdata/&g_fnc._recon
|                 %tu_xcpinit's outfile parameter
|
| XCPODSDEST      Specifies the type of exception         Opt   html
|                 reporting file
|
| XCPOUTFILESFX   Specifies the suffix type used in the   Opt   html
|                 exception reporting file
|
| Output:         This macro produces an A&R PKPAR dataset
|                 and creates an exception report.
|
| Global macro variables created: none
|
| Macros called:
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_chkvarsexist
| (@) tu_chknames
| (@) tu_getmaskedfiles
| (@) tu_abort
| (@) tu_xcpinit
| (@) tu_xcpsectioninit
| (@) tu_xcpput
| (@) tu_xcpsectionterm
| (@) tu_xcpterm
| (@) tu_readdsplan
| (@) tu_words
| (@) tu_isvarindsplan
| (@) tu_byid
| (@) tu_cv
| (@) tu_attrib
| (@) tu_tidyup
|
| Example:
|
|     %tc_pkpar(CV=
|              ,DSETOUT      = ardata.pkpar&sysdate
|              ,PARMFILEMASK = &root/arwork/c/s/r/dmdata/csvf*_params.csv
|              ,PRTLFILEMASK = &root/arwork/c/s/r/dmdata/csvf*_partials.CSV
|              ,XCPODSDEST   = phtml
|              );
|
|******************************************************************************
| Change Log
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     09-Feb-05
| New version/draft number: 01-002
| Modification ID:
| Reason For Modification:  Set minfiles=1 in call to tu_getmaskedfiles for
|                            the partial files. If user has specified a mask
|                            then we expect it to match at least one file.
|                           Add validation of DSETOUT.
|                           Add outfile=&xcpfile to call to tu_xcpinit.
|                           Change default for xcpoutfilesfx to &xcpodsdest.
|                           Remove (DOS) carriage return chars from end of lines
|                            of parm files and prtl files, if present.
|                           Add an OUTPUT statement to merge between PK conc data
|                            and the parm/prtl files to make it a "right join".
|                           Issue rterror message of 1st file does not contain a
|                            Parameter column.
|                           Enhance error messages for columns not found in parameter
|                            and partial files to make them more explicit.
|                           Add call to tu_abort at end of macro.
|                           Check that prtl file#1 has same by vars as parm files.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     22-Feb-05
| New version/draft number: 01-003
| Modification ID:          AR3
| Reason For Modification:  Apply upcase when looking for column names.
|                           Correct errors in header.
|
| Modified By:              Trevor Welby
| Date of Modification:     06-Apr-05
| New version/draft number: 01-004
| Modification ID:          TQW9753.01-004
| Reason For Modification:  The macro produces a SAS ERROR when DSETOUT
|                           has an invalid value.  Solution: The value of
|                           G_ABORT is checked before calling TU_GETMASKEDFILES
|                           in the parameter validation section
|
| Modified By:              Trevor Welby
| Date of Modification:     07-Apr-05
| New version/draft number: 01-005
| Modification ID:          TQW9753.01-005
| Reason For Modification:  Remove ctnl M charcaters from the end of record
|
| Modified By:              Warwick Benger
| Date of Modification:     3-Oct-2008
| New version number:       02-001
| Modification ID:          WJB1
| Reason For Modification:  1. New macro parameter PPORRERCSF to specify minimum SFs for PPORRERC
|                           2. Calculation of new variable PPORRERC
|                           3. Refinement to allow varied variable order
|
| Modified By:              Ian Barretto
| Date of Modification:     11-Mar-2009
| New version number:       02-002
| Modification ID:          IB001
| Reason For Modification:  Removed typographical mistakes in RTE RROR message for partial 
|                           parameter files not containing correct message 
*******************************************************************************/
%macro tc_pkpar(CV            =                          /* Optional covariate variables */
               ,DSETINEXP     = ardata.exposure          /* type:ID Exposure Dataset */
               ,DSETINPKCNC   = ardata.pkcnc             /* type:ID PKCNC dataset */
               ,DSETOUT       = ardata.pkpar             /* Output dataset */
               ,PPORRERCSF    = 3                        /* Minimum SFs for PPORRERC */
               ,PARMFILEMASK  =                          /* Mask field for parameter Files */
               ,PRTLFILEMASK  =                          /* Mask field for partials Files */
               ,XCPFILE       = &g_pkdata./&g_fnc._recon /* Name and location of Exception Report */
               ,XCPODSDEST    = html                     /* Ods destination for Exception Report files */
               ,XCPOUTFILESFX = html                     /* Suffix of Exception Report files */
               );

  /*
  / Echo parameter values and global macro variables to the log.
  /----------------------------------------------------------------------------*/
  %local MacroVersion /* Carries macro version number */
         prefix;      /* Carries file prefix for work files */
         
  %let MacroVersion = 2 build 2;
  %let prefix = %substr(&sysmacroname,3);

  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_dsplanfile);

  %local i thisVar;

  /*
  / PARAMETER VALIDATION
  /----------------------------------------------------------------------------*/
  %let dsetinexp=%nrbquote(&dsetinexp.);
  %let dsetinpkcnc=%nrbquote(&dsetinpkcnc.);
  %let dsetout=%nrbquote(&dsetout.);
  %let pporrercsf=%nrbquote(&pporrercsf.);
  %let parmfilemask=%nrbquote(&parmfilemask.);
  %let prtlfilemask=%nrbquote(&prtlfilemask.);
  %let xcpfile=%nrbquote(&xcpfile.);

  /*
  / Check for required parameters.
  /----------------------------------------------------------------------------*/

  /* Check that, if provided dsetinexp exists, and contains DOSE and DOSEUNIT */;
  %if %length(&dsetinexp) ne 0 %then
  %do;
    %if not %sysfunc(exist(&dsetinexp., data)) %then
    %do;
      %put %str(RTE)RROR: &sysmacroname.: The dataset identified by DSETINEXP (&dsetinexp.) does not exist.;
      %let g_abort=1;
    %end;
    %else
    %do;
      %if %length(%tu_chkvarsexist(&dsetinexp,dose doseunit)) gt 0  %then
      %do;
        %put %str(RTE)RROR: &sysmacroname.: DOSE and/or DOSEUNIT are not on the dataset defined by DSETINEXP (&dsetinexp);
        %let g_abort = 1;
      %end;
    %end;
  %end;

  /* Check that dsetinpkcnc exists */
  %if %length(&dsetinpkcnc) eq 0 %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: DSETINPKCNC must not be blank.;
    %let g_abort=1;
  %end;
  %else %if not %sysfunc(exist(&dsetinpkcnc., data)) %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: The dataset identified by DSETINPKCNC (&dsetinpkcnc.) does not exist.;
    %let g_abort=1;
  %end;

  /* Check that pporrercsf exists and is numeric [WJB1] */
  %if %length(&pporrercsf) eq 0 %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: PPORRERCSF must not be blank.;
    %let g_abort=1;
  %end;
  %else %if %datatyp(&pporrercsf)=CHAR %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: The value of PPORRERCSF (&pporrercsf.) is not a number.;
    %let g_abort=1;
  %end;
  %else %if %sysfunc(int(&pporrercsf)) ne &pporrercsf %then 
  %do;
    %put %str(RTE)RROR: &sysmacroname.: The value of PPORRERCSF (&pporrercsf.) is not an integer.;
    %let g_abort=1;
  %end;
  %else %if &pporrercsf lt 1 %then 
  %do;
    %put %str(RTE)RROR: &sysmacroname.: The value of PPORRERCSF (&pporrercsf.) is not greater than 0.;
    %let g_abort=1;
  %end;

  /* Check that dsetout is valid */
  %if %length(&dsetout) eq 0 %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: DSETOUT must not be blank.;
    %let g_abort=1;
  %end;
  %else %if %length(%tu_chknames(&dsetout,data)) ge 1 %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: The value specified for DSETOUT (&dsetout) is not a valid dataset name;
    %let g_abort=1;
  %end;

  %if &G_ABORT EQ 0 %then
  %do;  /* G_ABORT=0 [TQW9753.01-004] */

    /* Check that PARMFILEMASK refers to at least one file. Also, check that it includes
    /  a directory name, with no wildcard in the directory name. 
    /---------------------------------------------------------------------------------   */
    %local n_parmfiles;

    %tu_getMaskedFiles(inmask   = &parmfilemask
                      ,dsetout  = &prefix._parmfiles
                      ,nummvar  = n_parmfiles
                      ,minfiles = 1
                      );

    /* If provided, check that PRTLFILEMASK refers to at least one file. Also, check that 
    /  it includes a directory name, with no wildcard in the directory name. 
    /---------------------------------------------------------------------------------   */
    %local n_prtlfiles;

    %if %length(&prtlfilemask) eq 0 %then
    %do;
      %let n_prtlfiles = 0;
    %end;
    %else
    %do;
      %tu_getMaskedFiles(inmask   = &prtlfilemask
                        ,dsetout  = &prefix._prtlfiles
                        ,nummvar  = n_prtlfiles
                        ,minfiles = 1
                        );
    %end;

  %end;  /* G_ABORT=0 [TQW9753.01-004] */

  /* Check that xcpfile is not blank*/
  %if &xcpfile. eq %then %do;
    %put %str(RTE)RROR: &sysmacroname.: The parameter XCPFILE is required.;
    %let g_abort=1;
  %end;

  /* Abort if g_abort=1  */
  %tu_abort;


  /*
  / NORMAL PROCESSING
  /----------------------------------------------------------------------------*/
  %local currentDataset;

  /********************************************************/
  /* Plan of attack:                                      */
  /*                                                      */
  /* 1. Open the exception reporting                      */
  /* 2. Get a copy of the dataset plan for subsequent use */
  /* 3. Begin with parameter files                        */
  /* 4. Then do partial files                             */
  /* 5. Tidy-up with a sort                               */
  /* 6. Prepare and merge PKCNC                           */
  /* 7. Go get DOSE and DOSEUNIT from exposure dataset    */
  /* 8. Merge-in the covariate data                       */
  /* 9. Set correct attributes and variable/sort order    */
  /* 10. Close the exception reporting                    */
  /* 11. Tidy-up/delete temporary datasets                */
  /********************************************************/

  /* 1. Open the exception reporting  */
  %tu_xcpinit(header =%str(&sysmacroname. run on &sysdate at &systime.)
             ,odsdest=&xcpodsdest
             ,outfilesfx=&xcpoutfilesfx
             ,outfile=&xcpfile
             );

  /* 2. Get a copy of the dataset plan for subsequent use */
  %tu_readdsplan(dsetout = &prefix._dsplan);

 
  /* 3.  PARAMETER FILES                        
  /  3a. Put names of the parm files into macros vars 
  /  3b. For each parmfile, read in the data 
  /  3c. Append all the parm data together 
  /------------------------------------------------------ */

  
  /* 3a. Put names of the parm files into macros vars */  
  %do i = 1 %to &n_parmfiles;
    %local parmfile&i;
  %end;
  data _null_;
    set &prefix._parmfiles end=last;
    call symput(compress('parmfile'!!put(_n_,3.))
               ,trim(fullName)
               );
  run;

  %if &g_debug ge 1 %then %do;
    /* Output to the log what files we are processing */
    %put RTD%str(EBUG): &sysmacroname: Processing &n_parmfiles parameter file(s) These are:;
    %do I = 1 %to &n_parmfiles.;
      %put &&parmfile&i.;
    %end;
  %end;

  %local z varlist byPtr;

  /* 3b. For each parmfile, read in the data */
  %do fileNo = 1 %to &n_parmfiles.;
    %local by&fileNo rvarlist&fileNo covar&fileNo numBys&fileNo;

    /* 3b.1. Get list of variable names from first record of CSV file */
    data _null_;
      infile "&&parmfile&fileNo" lrecl=32767 obs=1;
      input;
      call symput('varlist',upcase(translate(_infile_,' ',',')));
      STOP;
    run;

    %if &g_debug ge 1 %then 
      %put RTD%str(EBUG): &sysmacroname: The variables read in from %scan(&&parmfile&fileNo,-1,'/') are &varlist;

    %let byPtr = %sysfunc(indexw(&varlist,PARAMETER)); /*AR3*/

    /* Make sure column PARAMETER exists and BY vars are present */
    %if &byPtr eq 0 %then         
    %do;     /* No Parameter var */
      %put RTE%str(RROR): &sysmacroname: Parameter file %scan(&&parmfile&fileNo,-1,'/') contains no "Parameter" column;
      %let g_abort = 1;
    %end;    /* No Parameter var */
    %else %if &byPtr eq 1 %then      
    %do;     /* No BY vars */
      %put RTE%str(RROR): &sysmacroname: Parameter file %scan(&&parmfile&fileNo,-1,'/') contains no BY columns to the left of "Parameter";
      %let g_abort = 1;
    %end;    /* No BY vars */
    %else
    %do;     /* Get BY vars and covars (parameter data vars) and number of by vars */
      %let by&fileNo = %substr(&varlist,1,&byPtr-1);
      %let rvarlist&fileNo = %substr(&varlist,&byPtr+10);
      %let covar&fileNo = %scan(&&rvarlist&fileNo,1) %scan(&&rvarlist&fileNo,2) %scan(&&rvarlist&fileNo,3);
      %let numBys&fileNo = %tu_words(&&by&fileNo);
      %if &g_debug ge 1 %then 
      %do;
        %put RTD%str(EBUG): &sysmacroname: %scan(&&parmfile&fileNo,-1,'/') byVars = &&by&fileNo;
        %put RTD%str(EBUG): &sysmacroname: %scan(&&parmfile&fileNo,-1,'/') parameterVars = &&covar&fileNo; 
      %end;
    %end;    /* Get BY vars and covars (parameter data vars) and number of by vars */

  %end; /* do over n_parmfiles */

  %tu_abort;

  %do fileNo = 1 %to &n_parmfiles.;

    %if &g_debug ge 1 %then 
      %put RTD%str(EBUG): &sysmacroname: Checking column content of file %scan(&&parmfile&fileNo,-1,'/');

    /* Check covars (parameter data vars) are valid */
    %if %sysfunc(indexw(&&covar&fileNo,UNITS)) eq 0 
     or %sysfunc(indexw(&&covar&fileNo,ESTIMATE)) eq 0 
     or %sysfunc(indexw(&&covar&fileNo,PCAN)) eq 0 %then
    %do;  /* Columns UNITS ESTIMATE PCAN not 3 vars which immediately follow PARAMETER */
      %if %sysfunc(indexw(&&rvarlist&fileNo,UNITS)) eq 0 
       or %sysfunc(indexw(&&rvarlist&fileNo,ESTIMATE)) eq 0 
       or %sysfunc(indexw(&&rvarlist&fileNo,PCAN)) eq 0 %then
      %do;  /* One or more of columns UNITS ESTIMATE PCAN do not follow PARAMETER at all */
        %put RTE%str(RROR): &sysmacroname: One or more of the columns "Units", "Estimate" and "PCAN" are not present in parameter file %scan(&&parmfile&fileNo,-1,'/') after the "Parameter" column;
        %let g_abort = 1;
      %end; /* One or more of columns UNITS ESTIMATE PCAN do not follow PARAMETER at all */
      %else 
      %do;  /* UNITS ESTIMATE PCAN follow PARAMETER but not in next 3 vars */
        %put RTE%str(RROR): &sysmacroname: The columns "Units", "Estimate" and "PCAN" are not immediately to the right of the column "Parameter" in parameter file %scan(&&parmfile&fileNo,-1,'/');
        %let g_abort = 1;
      %end; /* UNITS ESTIMATE PCAN follow PARAMETER but not in next 3 vars */
    %end; /* Columns UNITS ESTIMATE PCAN not 3 vars which immediately follow PARAMETER */
    %else %if "%scan(&&rvarlist&fileNo,4)" ne "" %then
    %do;  /* Columns UNITS ESTIMATE PCAN follow PARAMETER but other variables follow */
        %put RTW%str(ARNING): &sysmacroname: The column %scan(&&rvarlist&fileNo,4) and those that follow it in parameter file %scan(&&parmfile&fileNo,-1,'/') will be dropped;
    %end; /* Columns UNITS ESTIMATE PCAN follow PARAMETER but other variables follow */
    
    /* 3b.3. If first file, check vars against plan and create attributes */
    %if &fileNo eq 1 %then
    %do;  /* First file */

      /* 3b.4. Establish attributes */
      %local inPlan attrlist;

      %do z = 1 %to &numBys1;  /* Verify that BY variable(s) are in the Dataset Plan */
        %let vartemp = %scan(&by1,&z);
        %local &vartemp.byAttr;
        
        %let inPlan = %tu_isVarInDsplan(dsetin = &prefix._dsplan
                                       ,var = &vartemp
                                       ,attribmvar = &vartemp.byAttr);
        %if &inPlan eq N %then
        %do;  /* BY variable(s) not in Dataset Plan */
          %put RTE%str(RROR): &sysmacroname: Column in parameter file (&vartemp) not in Dataset Plan;
          %let g_abort = 1;
        %end; /* BY variable(s) not in Dataset Plan */
        %else
        %do;
          %let attrlist = &attrlist &vartemp &&&vartemp.byAttr;
        %end;
      %end;                    /* Verify that BY variable(s) are in the Dataset Plan */

      %local attrvars vartemp;
      %let attrvars=PPPAR PPORRESU PPORRESC PPORRESN PPAN;
      %do z = 1 %to 5;  /* Verify that parameter data variables are in the Dataset Plan */

        %let vartemp = %scan(&attrvars,&z);
        %local &vartemp.Attr;
        %let inPlan = %tu_isVarInDsplan(dsetin = &prefix._dsplan
                                       ,var = &vartemp
                                       ,attribmvar = &vartemp.Attr);
        %if &inPlan eq N %then
        %do;  /* Parameter data variables not in Dataset Plan */
          %put RTE%str(RROR): &sysmacroname: &vartemp not in Dataset Plan;
          %let g_abort = 1;
        %end; /* Parameter data variables not in Dataset Plan */
      %end;             /* Verify that parameter data variables are in the Dataset Plan */

    %end; /* First file */                         
    %else
    %do;  /* Not the first file */

      %if &&numBys&fileNo ne &numBys1 %then   /* Compare number of by vars */
      %do;
        %put RTE%str(RROR): &sysmacroname: Number of BY vars in Parameter file %scan(&&parmfile&fileNo,-1,'/') does not match number of BY vars in Parameter file %scan(&parmfile1,-1,'/');
        %let g_abort = 1;
      %end;                                   /* Compare number of by vars */

      %do z = 1 %to &numBys1;  /* Compare by vars */
        %if %sysfunc(indexw(&&by&fileNo,%sysfunc(scan(&by1,&z))))=0 %then
        %do;
          %put RTE%str(RROR): &sysmacroname: Parameter file %scan(&&parmfile&fileNo,-1,'/') does not contain BY column %sysfunc(scan(&by1,&z)) found in first parameter file %scan(&parmfile1,-1,'/');
          %let g_abort = 1;
        %end;
        %if %sysfunc(indexw(&by1,%sysfunc(scan(&&by&fileNo,&z))))=0 %then
        %do;
          %put RTE%str(RROR): &sysmacroname: Parameter file %scan(&&parmfile&fileNo,-1,'/') contains BY column %sysfunc(scan(&&by&fileNo,&z)) not found in first parameter file %scan(&parmfile1,-1,'/');
          %let g_abort = 1;
        %end;
      %end;                    /* Compare by vars */

    %end; /* Not the first file */                         
    
  %end; /* do over n_parmfiles */

  %tu_abort;

  %do fileNo = 1 %to &n_parmfiles.;

    /* Rename covariates to AR dataset var names */
    %let covar&fileNo = %sysfunc(tranwrd(%sysfunc(tranwrd(%sysfunc(tranwrd(&&covar&fileNo,UNITS,pporresu)),ESTIMATE,pporresc)),PCAN,ppan));

    /* 3b.5. Read in the data */
    data &prefix._parmfile_raw&fileNo;
      attrib &attrlist
        pppar &ppparAttr
        pporresu &pporresuAttr
        pporresc &pporrescAttr
        pporresn &pporresnAttr
        ppan &ppanAttr
        ;
      infile "&&parmfile&fileNo." dsd dlm = ',' firstobs = 2 lrecl=5000;
      input &&by&fileNo pppar &&covar&fileNo;
      pporresn = input(pporresc,??best.);
      ppseq = .;
      ppspec = '';
      ppcom = '';
      ppprec = '';
      ppreas = '';
      ppadjf = '';

      /* Remove (DOS) carriage return chars from end of line, if present */
      if substr(reverse(trim(ppan)),1,1) eq '0d'x then
        ppan = substr(ppan,1,length(ppan)-1);
    run;

  %end; /* do over n_parmfiles */

  /* 3c. Append all the parm data together                */
  data &prefix._all_parms0;
    set %do fileNo = 1 %to &n_parmfiles.;
          &prefix._parmfile_raw&fileNo
        %end;;
  run;

  proc sort data=&prefix._all_parms0 out=&prefix._all_parms;
    by &by1 ppan;
  run;

  %let currentDataset = &prefix._all_parms;


  /* 4. PARTIAL FILES                             */
  %if &n_prtlfiles gt 0 %then
  %do;  /* We have some partial files to handle */

    /* Get the names of the partial csv files we are going to read in */
    %do i = 1 %to &n_prtlfiles;
      %local prtlfile&i;
    %end;
    data _null_;
      set &prefix._prtlfiles end=last;
      call symput(compress('prtlfile'!!put(_n_,3.))
                 ,trim(fullName)
                 );
    run;

    %if &g_debug ge 1 %then %do;
      /*-- output to the log what files we are processing */
      %put RTD%str(EBUG): &sysmacroname: Processing &n_prtlfiles Partial file(s) These are:;
      %do i = 1 %to &n_prtlfiles.;
        %put &&prtlfile&i.;
      %end;
    %end;

    /* For each prtlfile, read in the data */
    %do fileNo = 1 %to &n_prtlfiles.;
      %local byPrtl&fileNo rvarlistPrtl&fileNo covarPrtl&fileNo numBysPrtl&fileNo;

      /* Get list of variable names from first record of first CSV file */
      data _null_;
        infile "&&prtlfile&fileNo" lrecl=5000 obs=1;
        input;
        call symput('varlist',upcase(translate(_infile_,' ',',')));
        STOP;
      run;

      %if &g_debug ge 1 %then
        %put RTD%str(EBUG): &sysmacroname: The variables read in from %scan(&&prtlfile&fileNo,-1,'/') are &varlist;

      %let byPtr = %sysfunc(indexw(&varlist,PARTIAL_AREA));
      %if &byPtr eq 0 %then
      %do;   /* No Partial_Area var */
        %put RTE%str(RROR): &sysmacroname: Partial file %scan(&&prtlfile&fileNo,-1,'/') contains no "Partial_Area" column;
        %let g_abort = 1;
      %end;  /* No Partial_Area var */
      %else %if &byPtr eq 1 %then
      %do;   /* No BY vars */
        %put RTE%str(RROR): &sysmacroname: Partial file %scan(&&prtlfile&fileNo,-1,'/') contains no BY columns to the left of "Partial_Area";
        %let g_abort = 1;
      %end;  /* No BY vars */
      %else 
      %do;   /* Get BY vars and covars (parameter data vars) and number of by vars */
        %let byPrtl&fileNo = %substr(&varlist,1,&byPtr-1);
        %let rvarlistPrtl&fileNo = %substr(&varlist,&byPtr+13);
        %let covarPrtl&fileNo = %scan(&&rvarlistPrtl&fileNo,1) %scan(&&rvarlistPrtl&fileNo,2) %scan(&&rvarlistPrtl&fileNo,3);
        %let numBysPrtl&fileNo = %tu_words(&&byPrtl&fileNo);
        %if &g_debug ge 1 %then 
        %do;
          %put RTD%str(EBUG): &sysmacroname: %scan(&&prtlfile&fileNo,-1,'/') byVars = &&byPrtl&fileNo;
          %put RTD%str(EBUG): &sysmacroname: %scan(&&prtlfile&fileNo,-1,'/') parameterVars = &&covarPrtl&fileNo; 
        %end;
      %end;  /* Get BY vars and covars (parameter data vars) and number of by vars */

    %end; /* do over n_prtlfiles */

    %tu_abort;
      
    %do fileNo = 1 %to &n_prtlfiles.;
      /* IB001 
      /  a) Changed scan function to display prtlfile instead of parmfile
      /  b) All occurance of Parameter File changed to Partial Parameter file in RTE%str(RROR)s       
      /  c) All occurance of Parameter column changed to Partial_Area column in RTE%str(RROR)s       
      /------------------------------------------------------ */

      %if &g_debug ge 1 %then 
        %put RTD%str(EBUG): &sysmacroname: Checking column content of file %scan(&&prtlfile&fileNo,-1,'/');

      /* Check that covariates are valid */        
      %if %sysfunc(indexw(&&covarPrtl&fileNo,UNITS)) eq 0 
       or %sysfunc(indexw(&&covarPrtl&fileNo,VALUE)) eq 0 
       or %sysfunc(indexw(&&covarPrtl&fileNo,PCAN)) eq 0 %then
      %do;  /* Columns UNITS VALUE PCAN not 3 vars which immediately follow PARTIAL_AREA */
        %if %sysfunc(indexw(&&rvarlistPrtl&fileNo,UNITS)) eq 0 
         or %sysfunc(indexw(&&rvarlistPrtl&fileNo,VALUE)) eq 0 
         or %sysfunc(indexw(&&rvarlistPrtl&fileNo,PCAN)) eq 0 %then
        %do;  /* One or more of columns UNITS VALUE PCAN do not follow PARTIAL_AREA at all */
          %put RTE%str(RROR): &sysmacroname: One or more of the columns "Units", "Value" and "PCAN" are not present in partial parameter file %scan(&&prtlfile&fileNo,-1,'/') after the "Parameter" column;
          %let g_abort = 1;
        %end; /* One or more of columns UNITS VALUE PCAN do not follow PARTIAL_AREA at all */
        %else 
        %do;  /* UNITS VALUE PCAN follow PARTIAL_AREA but not in next 3 vars */
          %put RTE%str(RROR): &sysmacroname: The columns "Units", "Value" and "PCAN" are not immediately to the right of the column "Partial_Area" in partial parameter file %scan(&&prtlfile&fileNo,-1,'/');
          %let g_abort = 1;
        %end; /* UNITS VALUE PCAN follow PARTIAL_AREA but not in next 3 vars */
      %end; /* Columns UNITS VALUE PCAN not 3 vars which immediately follow PARTIAL_AREA */
      %else %if "%scan(&&rvarlistPrtl&fileNo,4)" ne "" %then
      %do;  /* Columns UNITS VALUE PCAN follow PARTIAL_AREA but other variables follow */
          %put RTW%str(ARNING): &sysmacroname: The column %scan(&&rvarlistPrtl&fileNo,4) and those that follow it in partial parameter file %scan(&&prtlfile&fileNo,-1,'/') will be dropped;
      %end; /* Columns UNITS VALUE PCAN follow PARTIAL_AREA but other variables follow */

      /* Check that BY vars are same as in parm file */        
      %if &numBys1 ne &&numBysPrtl&fileNo %then
      %do;
        %put RTE%str(RROR): &sysmacroname: Number of BY vars in Partial file do not match number of BY vars in Parameter file;
          %let g_abort = 1;
      %end;

      %do z = 1 %to &numBys1;
        %if %sysfunc(indexw(&&byPrtl&fileNo,%sysfunc(scan(&by1,&z))))=0 %then
        %do;
          %put RTE%str(RROR): &sysmacroname: Partial file %scan(&&prtlfile&fileNo,-1,'/') does not contain BY column %sysfunc(scan(&by1,&z)) found in first parameter file %scan(&parmfile1,-1,'/');
          %let g_abort = 1;
        %end;
        %if %sysfunc(indexw(&by1,%sysfunc(scan(&&byPrtl&fileNo,&z))))=0 %then
        %do;
          %put RTE%str(RROR): &sysmacroname: Partial file %scan(&&prtlfile&fileNo,-1,'/') contains BY column %sysfunc(scan(&&byPrtl&fileNo,&z)) not found in first parameter file %scan(&parmfile1,-1,'/');
          %let g_abort = 1;
        %end;
      %end;
    %end; /* do over n_prtlfiles */

    %tu_abort;
      
    %do fileNo = 1 %to &n_prtlfiles.;
 
    /* Rename covariates to AR dataset var names */
    %let covarPrtl&fileNo = %sysfunc(tranwrd(%sysfunc(tranwrd(%sysfunc(tranwrd(&&covarPrtl&fileNo,UNITS,pporresu)),VALUE,pporresc)),PCAN,ppan));

     /* Read in the data (use attributes from parmfiles) */
      data &prefix._prtlfile_raw&fileNo;
        attrib &attrlist
          pppar &ppparAttr
          pporresu &pporresuAttr
          pporresc &pporrescAttr
          pporresn &pporresnAttr
          ppan &ppanAttr
          ;
        infile "&&prtlfile&fileNo." dsd dlm = ',' firstobs = 2 lrecl=5000;
        input &&byPrtl&fileNo pppar &&covarPrtl&fileNo;
        pporresn = input(pporresc,??best.);
        ppseq = .;
        ppspec = '';
        ppcom = '';
        ppprec = '';
        ppreas = '';
        ppadjf = '';
        /* Remove (DOS) carriage return chars from end of line, if present */
        if substr(reverse(trim(ppan)),1,1) eq '0d'x then
          ppan = substr(ppan,1,length(ppan)-1);
      run;

    %end; /* do over n_prtlfiles */

    /* Append all the partial data together */

    data &prefix._all_prtls;
      set %do fileNo = 1 %to &n_prtlfiles.;
            &prefix._prtlfile_raw&fileNo
          %end;;
    run;

    /* Append the partial data to the parm data */
    data &prefix._all_files0;
      set &currentDataset
          &prefix._all_prtls;
    run;

    %let currentDataset = &prefix._all_files0;

  %end; /* We have some partial files to handle */


  /* [WJB5671.01-010]  WJB1
  /* Calculate PPORRERC 
  /---------------------------------------  */
  
  proc sort data=&currentDataset out=&prefix._pporrerc1;
      by pppar pporresn;
  run;

/* Get the maximum no of DPs to which each parameter is reported        */
  data &prefix._precisions1 (keep=pppar actDPs);
    set &prefix._pporrerc1;
    by pppar;
    retain actDPs;
    if first.pppar then actDPs = 0;
    if pporresn gt 0 then do;

    /* The second half of the while condition below is included to allow for anomalies caused by binary-decimal conversion */
      do while (((pporresn*(10**actDPs))-(int(pporresn*(10**actDPs))))*(((pporresn+100)*(10**actDPs))-(int((pporresn+100)*(10**actDPs)))) gt 0);
        actDPs = actDPs + 1;
      end;
    end;
    if last.pppar then output;
  run;
  
/* Get the lowest non-zero value for each parameter */
  proc summary data=&prefix._pporrerc1(where=(pporresn gt 0));
    var pporresn;
    by pppar;
    output out=&prefix._precisions2(keep=pppar min) min=min;
  run;
  
/* Identify no of dps consistent with pporrercsf sig figs for the lowest value, then take this or the max no of dps, whichever is lower */
  data &prefix._precisions3(keep=pppar pparfmt);
    merge &prefix._precisions1 &prefix._precisions2;
    by pppar;
    length numDPs 8;
    maxDPs = max(&pporrercsf-floor(log10(min))-1,0);
    numDPs = min(actDPs, maxDPs);
    pparfmt = "8."||left(numDPs);
  run;

/* Create PPORRERC using PPORRESN rounded a/p above */ 
  data &prefix._pporrerc2(drop=pparfmt);
    merge &prefix._pporrerc1 &prefix._precisions3;
      by pppar;
      if pporresn ne . then pporrerc = left(putn(pporresn,pparfmt));
      else pporrerc = pporresc;
  run;

  %let currentDataset = &prefix._pporrerc2;

  /* 5. Tidy-up with a sort                               */
  proc sort data=&currentDataset out=&prefix._all_files;
    by &by1 ppan;
  run;

  %let currentDataset = &prefix._all_files;

  /* 6. Prepare and merge PKCNC                          
  /  6.1 Firstly, what vars do we want from PKCNC?  We   
  /      need to compare vars in PKCNC with vars in      
  /      DSPLAN (&planvars).                             
  /  6.2 Secondly we need to "reduce" PKCNC to one row   
  /      per PKPAR row                                    
  /  6.3 Join things together                         
  /--------------------------------------------------------- */

  /* 6.1 Firstly, compare vars in PKCNC with vars in      
  /      DSPLAN (&planvars).                             
  /--------------------------------------------------------- */

  %local planVars;
  proc sql noprint;
    select distinct varname into: planVars separated by ' '
    from &prefix._dsplan
  quit;

  %local pkcncVars;
  proc sql noprint;
    select distinct name into: pkcncVars separated by ' '
    from sashelp.vcolumn
    %if %length(%scan(&dsetinpkcnc,2)) gt 0 %then
    %do;
      where libname eq "%upcase(%scan(&dsetinpkcnc,1))" and
            memname eq "%upcase(%scan(&dsetinpkcnc,2))"
            ;
    %end;
    %else
    %do;
      where libname eq "WORK" and
            memname eq "%upcase(%scan(&dsetinpkcnc,1))"
            ;
    %end;
  quit;
  %if &g_debug ge 1 %then
  %do;
    %put RTD%str(EBUG): &sysmacroname: PKCNCVARS=&pkcncVars;
    %put RTD%str(EBUG): &sysmacroname: PLANVARS=&planVars;
  %end;

  %local isInPlan pkcncKeep;
  %do i = 1 %to %tu_words(&pkcncVars);

    %let thisvar = %scan(&pkcncVars,&i);

    %let isInPlan = %sysfunc(indexw(&planvars,&thisvar));

    %if &isInPlan %then
      %let pkcncKeep = &pkcncKeep &thisvar;

    %if &g_debug ge 1 %then
      %put RTD%str(EBUG): &sysmacroname: THISVAR=&thisvar ISINPLAN=&isInPlan;

  %end;

  /* 6.2 Secondly "reduce" PKCNC to one row per PKPAR row  */
  proc sort data=&dsetinpkcnc (keep=&by1 pcan &pkcncKeep rename=(pcan=ppan))
            out=&prefix._pkcnc_reduce
            nodupkey;
    by &by1 ppan;
  run;

  /* 6.3 Join things together                         */
  data &prefix._filesandpkcnc;
    merge &prefix._pkcnc_reduce (in=fromConc)
          &currentDataset (in=fromParm)
          end=finish
          ;
    by &by1 ppan;
    drop __msg;
    %tu_xcpsectioninit(header=Join parms with PKCNC);
    select;
      when (not fromParm)
      do;  /* not from parm files */
        %tu_byid(dsetin=&prefix._pkcnc_reduce
                ,invars=&by1 ppan
                ,outvar=__msg
                );
        %tu_xcpput("Data from PKCNC but not Parameter file(s): " !! __msg
                  ,WARNING);
      end; /* not from parm files */
      when (not fromConc)
      do;  /* not from PKCNC dataset */
        %tu_byid(dsetin=&currentDataset
                ,invars=&by1 ppan
                ,outvar=__msg
                );
        %tu_xcpput("Data from Parameter file(s) but not PKCNC: " !! __msg
                  ,WARNING);
      end; /* not from PKCNC dataset */
      otherwise; /* got rows from both input datasets */
    end; /* select */
    %tu_xcpsectionterm(end=finish);

    /* Make this the equivalent of pkconc right join parms/prtls */
    if fromParm then OUTPUT;

  run;
  %tu_abort;

  %let currentDataset = &prefix._filesandpkcnc;

  /* 7. If DSETINEXP provided, get DOSE and DOSEUNIT from exposure dataset    */
  %if %length(&dsetinexp) ne 0 %then
  %do;
    proc sort data=&currentDataset
              out=&prefix._mainsort;
      by &by1;
    run;

    proc sort data=&dsetinexp (keep=&by1 dose doseunit)
              out=&prefix._expsort;
      by &by1;
    run;

    /* Reduce the exposure down to one row per by-value */
    data &prefix._expcut;
      set &prefix._expsort;
      by &by1;
      if first.%scan(&by1,-1) then OUTPUT;
    run;

    data &prefix._withExp;
      merge &prefix._mainsort (in=fromMain)
            &prefix._expcut   (in=fromExp)
            end=finish
            ;
      by &by1;
      drop __msg;
      %tu_xcpsectionInit(header=Merge with Exposure);

      select;
        when (not fromMain)
        do;
          %tu_byid(dsetin = &prefix._expsort
                  ,invars = &by1
                  ,outvar = __msg
                  );
          %tu_xcpput("Exposure data with no matching PK data (dropped): " !! __msg
                    ,warning);
        end;
        when (not fromExp)
        do;
          %tu_byid(dsetin = &prefix._mainsort
                  ,invars = &by1
                  ,outvar = __msg
                  );
          %tu_xcpput("PK data with no matching exposure data: " !! __msg
                    ,warning);
        end;
        otherwise;
      end;

      if fromMain then OUTPUT;

      %tu_xcpsectionTerm(end=finish);
    run;
    %tu_abort;

  %let currentDataset = &prefix._withExp;
  %end;

  /* 8. Merge-in the covariate data                       */
  %if %length(&cv) gt 0 %then
  %do;
    %tu_cv(dsetin  = &currentDataset
          ,dsetout = &prefix._cv
          ,cv      = &cv
          ,Joinmsg = NOTE
          );
    %let currentDataset = &prefix._cv;
  %end;


  /* 9. Set correct attributes and variable/sort order    */
  %tu_attrib(dsetin=&currentDataset
            ,dsetout=&dsetout
            ,dsplan=&g_dsplanfile
            );

  /* 10. Close the exception reporting                    */
  %tu_xcpterm;

  /* 11. Tidy-up/delete temporary datasets                */
  %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

  %tu_abort;

%mend tc_pkpar;

