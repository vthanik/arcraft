/********************************************************************************************
|
| Macro Name:      td_lb11tscg
|
| Macro Version    1
|
| SAS Version:     9.1.3
|
| Created By:      Andy Miskell
|
| Date:            May 3, 2011
|
| Macro Purpose:   Create LB11 display using TIBCO Spotfire Clinical Graphics (TSCG)
|
| Macro Design:    Procedure Style
|
| Input Parameters : 
|
| Name               Description                                          Req/Opt  Default         
| ------------------------------------------------------------------------------------------
| INPUTUSAGE         Style of input data: C=Create Pre-processing         Req      <blank>
|                    program, D=Use existing dataset as input for 
|                    template, P=Call pre-processing file to create 
|                    dataset only, U=Call pre-processing file to
|                    create dataset as input for template 
|                    
| INPUTFILE          Name of pre-processing program located in refdata    Req      <blank>
|                    folder to either create or read in.
|
| DATASET            Name of input dataset for igd file.                  Req      <blank>
|                    Note this will be the name of the processed  
|                    dataset after calling pre-processing program
|
| IGDFILE            Name of IGD file to call                             Req      <blank>
|
| KEEPSSCRIPT        Logical flag indicating if the script to generate    Req      1
|                    the graph should be retained
|
| GETDATAYN          Execute tu_getdata macro: Yes or No                  Req      Y
|                    Valid values: Y, N
|
| NRTYPE             =NR if Upper limit of Normal Range will be used.     Req      NR
|                    =CC if Upper limit of PCI range will be used. 
|
| DOSEVARS           Variables used to determine dose.  Must have 2       Req      EXINVPCD EXINVP 
|                    variables - the first one must be in a format that
|                    is able to be converted to a numeric and the
|                    second one must be character.
|
| LABDAY             Lab Day variable for X-axis                          Req      LBACTDY
|
| DOSESTARTDAY       Dose Start Day variable for X-axis                   Req      EXACTSDY
|
| DOSEENDDAY         Dose End Day variable for X-axis                     Req      EXACTEDY
|
| XAXIS              Specifies the x-axis range. An expression            Opt      <blank>
|                    of the form: a to b by c
|
| XAXISLABEL         X-axis label                                         Opt      <blank>
|
| XAXISLABELSIZE     Point size for x-axis and tick mark labels           Req      10
|
| YAXIS              Specifies the y-axis range. An expression            Opt      <blank>
|                    of the form: a to b by c
|
| YAXISLABEL         Y-axis label                                         Opt      <blank>
|
| YAXISLABELSIZE     Point size for y-axis and tick mark labels           Req      10
|
| POINTSIZE          Point size for headers, titles and footnotes         Req      10
|
| -------------------------------------------------------------------------------------------
|
| Global macro variables created: NONE
|
| Macros called:
| (@) tr_putlocals
| (@) tu_putglobals 
| (@) tu_chkvarsexist
| (@) tu_getdata
| (@) tu_valparms
| (@) tu_cr8proghead
| (@) tu_tscgenv
| (@) tu_tidyup
| (@) tu_abort
|
|***********************************************************************************************
| Change Log 
|
| Modified By: 
| Date of Modification: 
| New Version/Build Number:
| Modification ID: 
| Reason For Modification: 
|
************************************************************************************************/
%macro td_lb11tscg(InputUsage        = ,                  /* Style of input data: C=Create pre-processing program, D=Use existing dataset as input for template, P=Call pre-processing program, U=Use template */
                   InputFile         = ,                  /* Name of pre-processing program located in refdata folder to either create or read in. No folder path is required - only the file name - e.g. example.sas  */
                   dataset           = ,                  /* Name of input dataset for igd file. Note this will be the name of the processed dataset after calling pre-processing program.  2-level name required - e.g. ardata.lab */
                   igdFile           = ,                  /* Name of IGD file to call located in refdata folder.  No folder path is required - only the file name - e.g. example.igd  */
                   keepSScript       = 1,                 /* Logical flag indicating if the script to generate the graph should be retained (=1, keep Script; =0, delete Script) */
                   getdatayn         = Y,                 /* Control execution of tu_getdata (Y/N) */
                   nrtype            = NR,                /* =NR if Upper limit of Normal Range will be used.  =CC if Upper limit of PCI range will be used */
                   dosevars          = exinvpcd exinvp,   /* Variables used to determine dose.  Must have 2 variables - the first one must be in a format that is able to be converted to a numeric and the second one must be character. */
                   labday            = lbactdy,           /* Lab day variable for X-axis */
                   dosestartday      = exactsdy,          /* Dose start day variable for X-axis */
                   doseendday        = exactedy,          /* Dose end day variable for X-axis */
                   xAxis             = ,                  /* Specifies the x-axis range. An expression of the form: a to b by c */
                   xAxisLabel        = ,                  /* X-axis label */      
                   xAxisLabelSize    = 10,                /* Point size for x-axis and tick mark labels */                 
                   yAxis             = ,                  /* Specifies the y-axis range. An expression of the form: a to b by c  */
                   yAxisLabel        = ,                  /* Y-axis label */ 
                   yAxisLabelSize    = 10,                /* Point size for y-axis and tick mark labels */                    
                   pointSize         = 10                 /* Point size for headers, titles and footnotes */                                             
                   );

  %local MacroVersion MacroName;
  %let MacroVersion = 1;
  %let MacroName = &sysmacroname;

  * Echo values of local and global macro variables to the log;                                
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals();

  * Define some local macro variables;
  %local pv_abort;
  %let pv_abort = 0;

  * Parameter cleanup;
  %let InputUsage   = %upcase(&InputUsage);
  %let InputUsage   = %nrbquote(&InputUsage);
  %let InputFile    = %nrbquote(&inputFile);  
  %let dataset      = %nrbquote(&dataset);
  %let igdFile      = %nrbquote(&igdFile);
  %let keepSScript  = %nrbquote(&keepSScript);
  %let getdatayn    = %nrbquote(&getdatayn);
  %let nrtype       = %upcase(&nrtype);
  %let nrtype       = %nrbquote(&nrtype);
  %let dosevars     = %nrbquote(&dosevars);
  %let labday       = %nrbquote(&labday);
  %let dosestartday = %nrbquote(&dosestartday);
  %let doseendday   = %nrbquote(&doseendday);

  /*-----------------------------------------------------------------------*/
  /* Parameter Validation */
  
  /*--PV - INPUT USAGE: check it is C, D, P, or U */
  %if %length(&InputUsage) = 0 %then %do; 
    %put %str(RTE)RROR: &macroname: Macro parameter (InputUsage) cannot be blank; 
    %let pv_abort = 1;
  %end;
  %else 
    %tu_valparms(macroname = &macroname., chktype = isOneOf, pv_varsin = InputUsage, valuelist = C D P U, abortyn = N);

  /*--PV - Check parameters that are dependent upon InputUsage are correctly specified */

  /* If InputUsage=D then Dataset shall not be blank */
  %if &InputUsage=D %then %do;
    %if %sysevalf(%length(&dataset)) = 0 %then %do;
      %put %str(RTE)RROR: &macroname: Macro parameter (dataset) cannot be blank when InputUsage=D; 
      %let pv_abort = 1;
    %end;
  %end;

  /* If InputUsage=D then getdatayn shall not be blank and shall have a value of Y or N */
  %if &InputUsage=D %then %do;
    %if %bquote(%upcase(&getdatayn)) eq %then %do;
      %put %str(RTW)ARNING: &macroname: Macro parameter GETDATAYN (getdatayn=&getdatayn) is missing and will be set to Y; 
      %let getdatayn=Y;
    %end;
    %else %do;
      %tu_valparms(macroname = &macroname., chktype = isOneOf, pv_varsin = getdatayn, valuelist = Y N, abortyn = N);
    %end;
  %end;

  /* If InputUsage=D then Dataset shall specify a SAS dataset that exists */
  %if &InputUsage=D %then %do;
    %tu_valparms(macroname = &macroname., chktype = dsetExists, pv_dsetin = dataset , abortyn = N); 
  %end;

  /* If InputUsage=C, P, or U then inputFile shall not be blank */
  %if &InputUsage=C or &InputUsage=P or &InputUsage=U  %then %do;
    %if %sysevalf(%length(&inputFile)) = 0 %then %do;
      %put %str(RTE)RROR: &macroname: Macro parameter (inputFile) cannot be blank when InputUsage=C P or U; 
      %let pv_abort = 1;
    %end;
  %end;

  /* If InputUsage=C then inputFile shall specify the name of a file in the reporting effort refdata folder that does not already exist */
  %if &InputUsage=C %then %do;
    %if %sysfunc(fileexist(&g_rfmtdir./&inputFile)) = 1 %then %do;
      %if %sysevalf(%length(&inputFile)) ne 0 %then %put %str(RTE)RROR: &inputFile : Pre-processing program to be created already exists; 
      %let pv_abort = 1;
    %end;
  %end;

  /* If InputUsage=U or P then inputFile shall specify the name of a file in the reporting effort refdata folder that already exists */
  %if &InputUsage=P or &InputUsage=U  %then %do;
    %if %sysfunc(fileexist(&g_rfmtdir./&inputFile)) = 0 %then %do;      
    %put %str(RTE)RROR: &inputFile : Pre-processing program does not exist; 
      %let pv_abort = 1;
    %end;
  %end;

  /* If InputUsage=D or U then igdFile shall not be blank */
  %if &InputUsage=D or &InputUsage=U %then %do;
    %if %length(&igdFile) = 0 %then %do; 
      %put %str(RTE)RROR: &macroname: Macro parameter (igdFile) cannot be blank when InputUsage=D or U; 
      %let pv_abort = 1;
    %end;
  %end;

  /* If InputUsage=U and dataset parameter is blank then issue a warning to let user know the last dataset created in input file*/
  /* will be used as the input to the IGD file. */
  %if &InputUsage=U %then %do;
    %if %sysevalf(%length(&dataset)) = 0 %then %do;
      %put %str(RTW)ARNING: &macroname: The dataset parameter is blank so the last dataset generated in the &inputfile program; 
      %put %str(RTW)ARNING: &macroname: will be used as the input to the IGD file; 
    %end;
  %end;

  /* If InputUsage=D or U then igdFile shall specify the name of a file in the reporting effort refdata folder that already exists */
  %if &InputUsage=D or &InputUsage=U %then %do;
    %if %sysfunc(fileexist(&g_rfmtdir./&igdFile)) = 0 %then %do;
      %put %str(RTE)RROR: &igdFile : IGD file to render graph does not exist; 
      %let pv_abort = 1;
    %end;
  %end;
  
   /*--PV - keepSScript: check it's 0 or 1 */
  %if &InputUsage=D or &InputUsage=U %then %do;
    %if %length(&keepSScript) = 0 %then %do;
      %put %str(RTW)ARNING: &macroname: Macro parameter keepSScript is not specified. It will be set to 1; 
      %let keepSScript = 1;
    %end;
    %else %do;
      %tu_valparms(macroname = &macroname., chktype = isOneOf, pv_varsin = keepSScript, valuelist = 0 1, abortyn = N);
    %end;
  %end;

  /*--PV - nrtype: If InputUsage=C then check nrtype is NR or CC */
  %if &InputUsage=C %then %do;
      %tu_valparms(macroname = &macroname., chktype = isOneOf, pv_varsin = nrtype, valuelist = CC NR, abortyn = N);
  %end;

  /*--PV - dosevars: If InputUsage=C then check dosevars contains variables that exist in ardata.exposure */
  %if &InputUsage=C %then %do;
      %if %length(%tu_chkvarsexist(ardata.exposure, &dosevars)) gt 0 %then %do;
        %put %str(RTE)RROR: &macroname: DOSEVARS parameter: ardata.exposure dataset does not contain one or both of the following variables: &dosevars; 
        %let pv_abort = 1;
      %end;
  %end;

  /*--PV - dosevars: If InputUsage=C then check dosevars has two and only two variable names */
  %if &InputUsage=C %then %do;
      %if %scan(&dosevars,2)= or  %scan(&dosevars,3)^= %then %do;
        %put %str(RTE)RROR: &macroname: DOSEVARS parameter must contain two and only two variable names.; 
        %let pv_abort = 1;
      %end;
  %end;

  /* If InputUsage=C then labday, dosestartday, and doseendday shall not be blank */
  %if &InputUsage=C %then %do;
    %let listvars=labday dosestartday doseendday;
    %do loopi=1 % to 3;
      %let thisvar=%scan(&listvars,&loopi,%str( ));
      %let &thisvar=%nrbquote(&&&thisvar);
      %if &&&thisvar eq %then %do;
        %put %str(RTE)RROR: &macroname: Macro parameter (&thisvar) cannot be blank when InputUsage=C; 
        %let pv_abort = 1;
      %end;
    %end;
  %end;

  /*--PV - labday: If InputUsage=C then check labday contains a variable that exists in ardata.lab */
  %if &InputUsage=C and &labday^= %then %do;
      %if %length(%tu_chkvarsexist(ardata.lab, &labday)) gt 0 %then %do;
        %put %str(RTE)RROR: &macroname: LABDAY parameter: ardata.lab dataset does not contain the following variable: &labday; 
        %let pv_abort = 1;
      %end;
  %end;

  /*--PV - dosestartday: If InputUsage=C then check dosestartday contains a variable that exists in ardata.exposure */
  %if &InputUsage=C and &dosestartday^= %then %do;
      %if %length(%tu_chkvarsexist(ardata.exposure, &dosestartday)) gt 0 %then %do;
        %put %str(RTE)RROR: &macroname: DOSESTARTDAY parameter: ardata.exposure dataset does not contain the following variable: &dosestartday; 
        %let pv_abort = 1;
      %end;
  %end;

  /*--PV - doseendday: If InputUsage=C then check doseendday contains a variable that exists in ardata.exposure */
  %if &InputUsage=C and &doseendday^= %then %do;
      %if %length(%tu_chkvarsexist(ardata.exposure, &doseendday)) gt 0 %then %do;
        %put %str(RTE)RROR: &macroname: DOSEENDDAY parameter: ardata.exposure dataset does not contain the following variable: &doseendday; 
        %let pv_abort = 1;
      %end;
  %end;

  /*--PV - Delete any existing plot file */
  /* Note: we do this even if this call would not create a new one */
  %local plotfile;
  %let plotfile=&G_OUTFILE..&G_TEXTFILESFX;

  %local rc pltfref;
  %if %sysfunc(fileexist(&plotfile)) = 1 %then %do;

    /* Have to assign a fileref before we can use the FDELETE function */
    %let plotfref=oldplot;
    %let rc=%sysfunc(filename(plotfref,&plotfile));
    %if &rc ne 0 %then %do;
      %put %str(RTE)RROR: &macroname: Failed to assign fileref for plot file - return code &rc;
      %let pv_abort = 1;
    %end;
    %else %do;
      %let rc=%sysfunc(fdelete(&plotfref));
      %if &rc ne 0 %then %do;
        %put %str(RTE)RROR: &macroname: Failed to assign fileref for plot file - return code &rc;
        %let pv_abort = 1;
      %end;
    %end;
  %end;

  %if %eval(&g_abort. + &pv_abort.)>0 %then %do;
    %put %str(RTE)RROR: &macroname: Macro has failed parameter validation check for reasons stated with %str(RTE)RRORs above;
    %tu_abort(option=force);
  %end;

  /*----------------------------------------------------------------------*/
  /* Normal Processing */
  /*----------------------------------------------------------------------*/

  /* Parse out DOSEVARS values */
  %local dosevar1 dosevar2;
  %let dosevar1=%scan(&dosevars,1);
  %let dosevar2=%scan(&dosevars,2);

  %macro splusPlot_write_template(fname);
      
      data _null_; 
        file "&g_rfmtdir./&InputFile";
        %tu_cr8proghead(macname=&InputFile, macdesign=SAS_datastep_not_a_macro);
         
        put " ";
        put "%nrstr(%macro td_lb11tscg_preprocess;)";
        put " ";
        put "%nrstr(%tu_getdata%(dsetin=ardata.lab,)";
        put "%nrstr(            dsetout1=_lb11tscg_1%) )";
        put " ";
        put "/* Calculate normalized value based on upper limit of Normal or PCI Range. */";
        put "%nrstr(data _lb11tscg_2; )";
        put "%nrstr(  set _lb11tscg_1; )";
        put "%nrstr(  length LABDOSE $ 4; )";
        put "%nrstr(  LABDOSE='LAB'; )";
        put "%nrstr(  %if %upcase%(%")&nrtype%nrstr(%"%)=%"NR%" %then %do; )";
        put "%nrstr(    if lbstnrhi ne . then lbstresn=lbstresn/lbstnrhi; )";
        put "%nrstr(  %end; )";
        put "%nrstr(  %if %upcase%(%")&nrtype%nrstr(%"%)=%"CC%" %then %do; )";
        put "%nrstr(    if lbstcchi ne . then lbstresn=lbstresn/lbstcchi; )";
        put "%nrstr(  %end; )";
        put "%nrstr(  if lbstresn ne .; )";
        put "  /* Concatenate lab test and units for variable labels */";
        put "%nrstr(  length TESTLBL $ 70; )";
        put "%nrstr(  if lbstunit ne '' then TESTLBL=trim%(left%(lbtest%)%)||' ('||trim%(left%(lbstunit%)%)||')'; )";
        put "%nrstr(  else TESTLBL=trim%(left%(lbtest%)%); )";
        put "%nrstr(  lbactdy=)&labday%nrstr(; )";
        put "%nrstr(run; )";
        put "%nrstr( )";
        put "/* Check Exposure data to see if End Dates vary from  Start Dates or if only Start Dates should be used. */";
        put "%nrstr(data _lb11tscg_exp1; )";
        put "%nrstr(  set ardata.exposure; )";
        put "%nrstr(  if exstdt ne . and exendt ne . and exstdt ne exendt then exflag=1; )";
        put "%nrstr(  else exflag=0; )";
        put "%nrstr(run; )";
        put "%nrstr( )";
        put "%nrstr(proc sort data=_lb11tscg_exp1; )";
        put "%nrstr(  by descending exflag; )";
        put "%nrstr(run; )";
        put "%nrstr( )";
        put "%nrstr(data _lb11tscg_exp2; )";
        put "%nrstr(   set _lb11tscg_exp1; )";
        put "%nrstr(   if _n_=1 then output; )";
        put "%nrstr(run; )";
        put "%nrstr( )";
        put "%nrstr(%local exflag; )";
        put "%nrstr( )";
        put "%nrstr(data _lb11tscg_exp2; )";
        put "%nrstr(  set _lb11tscg_exp2; )";
        put "%nrstr(  call symput%('exflag',put%(exflag,?? 1.%)%); )";
        put "%nrstr(run; )";
        put "%nrstr( )";
        put "/* If Start Dates are the same as End Dates ... */";
        put "%nrstr(%if %"&exflag%"=%"0%" %then %do; )";
        put "%nrstr( )";
        put "%nrstr(  data _lb11tscg_exp3 %(keep=)&g_centid &g_subjid &g_trtcd &g_trtgrp %nrstr(exactsdy age sex racecd race DOSE_EXP DOSECD LABDOSE%); )";
        put "%nrstr(    set ardata.exposure; )";
        put "%nrstr(    length DOSE_EXP $ 70 DOSECD $ 10 LABDOSE $ 4; )";
        put "%nrstr(    LABDOSE='DOSE'; )";
        put "%nrstr(    DOSECD='DRUG_'||left%(put%(input%()&dosevar1 %nrstr(,?? best.%),?? z3.%)%); )";
        put "%nrstr(    DOSE_EXP=)&dosevar2;";
        put "%nrstr(    if exstdt ne . then output;  )";
        put "%nrstr(  run; )";
        put "%nrstr( )";
        put "%nrstr(  proc sort data=_lb11tscg_exp3; )";
        put "%nrstr(    by) &g_centid &g_subjid &g_trtcd &g_trtgrp %nrstr(age sex racecd race DOSECD exactsdy DOSE_EXP; )";
        put "%nrstr(  run; )";
        put "%nrstr( )";
        put "%nrstr(  data _lb11tscg_exp4; )";
        put "%nrstr(    set _lb11tscg_exp3; )";
        put "%nrstr(    by ) &g_centid &g_subjid &g_trtcd &g_trtgrp %nrstr(age sex racecd race DOSECD exactsdy DOSE_EXP; )";
        put "%nrstr(    retain LBACTDY; )";
        put "%nrstr(    if first.DOSECD then LBACTDY=)&dosestartday%nrstr(; )";
        put "%nrstr(    if last.DOSECD then do; )";
        put "%nrstr(      END_DAY=)&dosestartday%nrstr(; )";
        put "%nrstr(      output; )";
        put "%nrstr(    end; )";
        put "%nrstr(  run; )";
        put "%nrstr( )";
        put "%nrstr(  proc sort data=_lb11tscg_2 out=_lb11tscg_temp %(keep=) &g_centid &g_subjid %nrstr(%) nodupkey;  )";
        put "%nrstr(    by) &g_centid &g_subjid ;";
        put "%nrstr(  run; )";
        put "%nrstr( )";
        put "%nrstr(  proc sort data=_lb11tscg_exp4; )";
        put "%nrstr(    by) &g_centid &g_subjid ;";
        put "%nrstr(  run; )";
        put "%nrstr( )";
        put " /* Merge Exposure with Lab subjects and only keep dosing records for subjects that appear in Lab dataset */";
        put "%nrstr(  data _lb11tscg_exp5; )";
        put "%nrstr(    merge _lb11tscg_temp %(in=a%) _lb11tscg_exp4 %(in=b%); )";
        put "%nrstr(    by) &g_centid &g_subjid ;";
        put "%nrstr(    if a and b; )";
        put "%nrstr(  run; )";
        put "%nrstr( )";
        put "%nrstr( %end; )";
        put "%nrstr( )";
        put "/* If Start Dates and End Dates are different ... */";
        put "%nrstr(%if %"&exflag%"=%"1%" %then %do; )";
        put "%nrstr( )";
        put "%nrstr(  data _lb11tscg_exp3 %(keep=) &g_centid &g_subjid &g_trtcd &g_trtgrp %nrstr(lbactdy END_DAY age sex racecd race DOSE_EXP DOSECD LABDOSE%); )";
        put "%nrstr(    set ardata.exposure; )";
        put "%nrstr(    length DOSE_EXP $ 70 DOSECD $ 10 LABDOSE $ 4; )";
        put "%nrstr(    LABDOSE='DOSE'; )";
        put "%nrstr(    DOSECD='DRUG_'||left%(put%(input%()&dosevar1 %nrstr(,?? best.%),?? z3.%)%); )";
        put "%nrstr(    DOSE_EXP=)&dosevar2;";
        put "%nrstr(    lbactdy=)&dosestartday %nrstr(; )";
        put "%nrstr(    END_DAY=)&doseendday%nrstr(; )";
        put "%nrstr(  run; )";
        put "%nrstr( )";
        put "%nrstr(  proc sort data=_lb11tscg_2 out=_lb11tscg_temp %(keep=) &g_centid &g_subjid %nrstr( %) nodupkey; )";
        put "%nrstr(    by) &g_centid &g_subjid ;";
        put "%nrstr(  run; )";
        put "%nrstr( )";
        put "%nrstr(  proc sort data=_lb11tscg_exp3; )";
        put "%nrstr(    by) &g_centid &g_subjid ;";
        put "%nrstr(  run; )";
        put "  /* Merge Exposure with Lab subjects and only keep dosing records for subjects that appear in Lab dataset */ ";
        put "%nrstr(  data _lb11tscg_exp5; )";
        put "%nrstr(    merge _lb11tscg_temp %(in=a%) _lb11tscg_exp3 %(in=b%); )";
        put "%nrstr(    if a and b; )";
        put "%nrstr(    by) &g_centid &g_subjid ;";
        put "%nrstr(  run; )";
        put "%nrstr( )";
        put "%nrstr(%end; )";
        put "%nrstr( )";
        put "/* Set Lab data together with dosing data. */";
        put "%nrstr( data _lb11tscg_3; )";
        put "%nrstr(   set _lb11tscg_exp5 _lb11tscg_2; )";
        put "%nrstr(   length SUBJ $ 90 GEND $ 10; )";
        put "%nrstr(   if sex='M' then GEND='Male'; )";
        put "%nrstr(   else if sex = 'F' then GEND='Female'; )";
        put "  /* Concatenate subject, gender, age, and treatment. */";
        put "%nrstr(   SUBJ='Subject: '||trim%(left%(put%()&g_subjid%nrstr(,?? best.%)%)%)||' '||trim%(left%(GEND%)%)||' Age: '||trim%(left%(put%(age,?? 3.%)%)%)||' Drug: '||trim%(left%()&g_trtgrp%nrstr(%)%); )";
        put "%nrstr( run; )";
        put "%nrstr( )";
        put "%nrstr( proc sort data=_lb11tscg_3 out=_lb11tscg_3; )";
        put "%nrstr(   by) &g_centid &g_subjid %nrstr(lbactdy TESTLBL; )";
        put "%nrstr( run; )";
        put "%nrstr( )";
        put "/* Assign labels to newly created variables. */";
        put "%nrstr(data _lb11tscg_4 %(keep=) &g_centid &g_subjid &g_trtcd &g_trtgrp %nrstr(age sex racecd race DOSE_EXP DOSECD LABDOSE lbactdy END_DAY lbtestcd lbtest TESTLBL lbstresn subj gend%);)";
        put "%nrstr(  set _lb11tscg_3; )";
        put "%nrstr(  attrib)";
        put "%nrstr(    TESTLBL  length=$70  label=%"Label of Lab Test with units%")";
        put "%nrstr(    SUBJ     length=$90  label=%"Combination of subject, gender, age, and treatment%")";
        put "%nrstr(    GEND     length=$10  label=%"Gender (non-abbreviated)%")";
        put "%nrstr(    DOSECD   length=$10  label=%"Dose code%")";
        put "%nrstr(    DOSE_EXP length=$70  label=%"Dose Label%")";
        put "%nrstr(    LABDOSE  length=$4   label=%"Lab or Dose Observation%")";
        put "%nrstr(    END_DAY  length=8    label=%"End Day of Dosing%")";
        put "%nrstr(    ;)";
        put "%nrstr(run;)";
        put " ";         
        %if "&dataset"^="" %then %do;
          put "%nrstr(data) &dataset%nrstr(;)";
          put "%nrstr(  set _lb11tscg_4; )";
          put "%nrstr(run; )";
          put "%nrstr( )";
        %end;
        put "%nrstr(%mend; )";
        put "%nrstr( )";
        put "%nrstr(%td_lb11tscg_preprocess; )";
        put "%nrstr( )";
      run;    

  %mend splusPlot_write_template;

  %if &InputUsage=C %then %do;
  
    /*----------------------------------------------------------------------*/ 
    /*-- Write template file if wanted */

    %put %str(RTN)OTE: Creating template code file for input dataset; 
    %put %str(RTN)OTE: No graph will be generated;       
    %splusPlot_write_template(usr_prof);

  %end;
  %if &InputUsage=P %then %do;

    %put %str(RTN)OTE: Running template code file for input dataset; 
    %put %str(RTN)OTE: No graph will be generated;       
    %include "&g_rfmtdir./&inputFile";

  %end;
  %if &InputUsage=U or &InputUsage=D %then %do;
    %if &InputUsage=U %then %do;
  
      %include "&g_rfmtdir./&inputFile";

      %if %sysevalf(%length(&dataset)) = 0 %then %do;

        /* If Dataset Parameter is missing then get the last created dataset from the Inputfile to send to the IGD file */
        data work.tscgdata;
          set &syslast;
        run;

        %let dataset=work.tscgdata;

      %end;
      %else %if "%substr(%upcase(&dataset),1,4)"="WORK" or "%index(&dataset,'.')"="0" %then %do;
        /* If a work dataset is specified in the parameter dataset (either with the libname work or with no libname, */
        /* then rename to work.tscgdata so tu_tscgenv will accept dataset name */
        data work.tscgdata;
          set &dataset;
        run;

        %let dataset=work.tscgdata;

      %end;

    %end;
    %if &InputUsage=D %then %do;

      /*
      /   If &getdatayn eq Y then use %tu_getdata to subset the dataset parameter value
      /   Else if &getdatayn ne Y then use the dataset parameter value without subsetting
      /*----------------------------------------------------------------------------------*/ 

      %if %upcase(&getdatayn) eq Y %then %do;
        %tu_getdata(dsetin=&dataset,
                    dsetout1=tscgdata);
        %let dataset=work.tscgdata;
      %end;

    %end;

    /*-- Set up TSCG environment --*/
    %tu_tscgenv(xAxis             = &xAxis,               /* Specifies the x-axis range. An expression of the form: a to b by c */       
                xAxisLabel        = &xAxisLabel,          /* X-axis label */                                                             
                xAxisLabelSize    = &xAxisLabelSize,      /* Point size for x-axis and tick mark labels */                               
                yAxis             = &yAxis,               /* Specifies the y-axis range. An expression of the form: a to b by c  */      
                yAxisLabel        = &yAxisLabel,          /* Y-axis label */                                                             
                yAxisLabelSize    = &yAxisLabelSize,      /* Point size for y-axis and tick mark labels */                               
                pointSize         = &pointSize);          /* Titles and footnotes point size */                                 

    /* Create TSCG plot using the indicated IGD file as a source and writing the output to the named target */
    %tscg_CreateGraph(outputFile  = &g_outfile,           /* Path and name of output file to be created */
                      graphType   = &g_textfilesfx,       /* Graph file format for output */
                      graphDoc    = &g_rfmtdir./&igdfile, /* Path and name of graph document (IGD file) to be used as the basis of the graph */
                      keepSScript = &keepSScript);        /* Logical flag indicating if the script to generate the graph should be retained */       
  %end;
  
  /*----------------------------------------------------------------------*/
  
  %tu_tidyup(glbmac=NONE);
  %tu_abort;
                                                     
%mend td_lb11tscg;
