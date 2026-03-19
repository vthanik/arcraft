/*******************************************************************************
|
| Macro Name:     tc_wnl.sas
|
| Macro Version:  3.1
|
| SAS Version:    9.1
|
| Created By:     Trevor Welby
|
| Date:           17th December 2004
|
| Macro Purpose:  A dataset creation macro to create WinNonLin-ready files from
|                 A&R PKCNC & EXPOSURE datasets 
|
| Macro Design:   Procedure style
|
| Input Parameters:
|
| NAME            DESCRIPTION                                    DEFAULT
|
| FILEOUTDIR      Specifies the value to be passed to            &G_PKDATA (Req)
|                 %tu_cr8wnlconcs and tu_cr8wnldoses
|                 FILEOUTDIR parameter
|
| FILEOUTPFX      Specifies the optional value                   &g_fnc (Opt)
|                 to be passed to %tu_cr8wnlconcs and 
|                 %tu_cr8wnldoses FILEOUTPFX parameter
|
| XCPFILE         Specifies the value to be passed to            &g_pkdata/&g_fnc._recon (Req)
|                 %tu_xcpinit OUTFILE parameter
|
| XCPODSDEST      Specifies the value to be passed to            html (Req)
|                 %tu_xcpinit ODSDEST parameter
|
| XCPOUTFILESFX   Specifies the value to be pass to              html (Req)
|                 %tu_xcpinit OUTFILESFX parameter
|
| CV              Specifies the value to be passed to            [blank] (Opt)
|                 %tu_cr8wnlconcs CV parameter
|
| DSETINCONCS     Specifies the value to be pass to              ardata.pkcnc (Req)
|                 %tu_cr8wnlconcs DSETIN parameter
|                 and to the %tu_cr8wnldoses DSETINCONCS
|                 parameter
|
| SPLITVARS       Specifies the value to be passed to            pctyp pcspec pcan (Req)
|                 %tu_cr8wnlconcs SPLITVARS parameter
|                 and to the %tu_cr8wnldoses SPLITVARS 
|                 parameter
|
| UNITPAIRS       Specifies the value to be passed to            [blank] (Opt)
|                 %tu_cr8wnlconcs UNITPAIRS parameter
|
| VARSOUTCONCS    Specifies the value to be passed to            studyid pctyp pcspec          
|                 %tu_cr8wnlconcs VARSOUT parameter              pcan &g_centid &g_subjid
|                                                                &g_trtgrp visit ptm
|                                                                pcstdt pcsttm pcatmnum
|                                                                pcorres pcorresu pcwnln 
|                                                                pcwnlrt pcllqc age sex 
|                                                                race pcsmpid (Req)
|
| DOSEFILES       Create WinNonLin-ready doses file(s)           N (Req)  [WJB1]
|     <<DOSEFILES (%tu_cr8wnldoses) DISABLED IN THIS VERSION>>
|
| DOSEINT         Specifies the value to be passed to            0 (Req)
|                 %tu_cr8wnldoses DOSEINT parameter
|     <<DISABLED IN THIS VERSION>>
|
| DOSEUNIT        Specifies the value to be passed to            doseunit (Opt)
|                 %tu_cr8wnldoses DOSEUNIT parameter
|     <<DISABLED IN THIS VERSION>>
|
| DSETINDOSES     Specifies the name of the input A&R            ardata.exposure (Opt)
|                 EXPOSURE dataset. To be passed to
|                 %tu_cr8wnldoses DSETINDOSES parameter
|     <<DISABLED IN THIS VERSION>>
|
| LENGTHINFUSION  Specifies the value to be passed to            [blank] (Opt)
|                 %tu_cr8wnldoses LENGTHINFUSION parameter
|     <<DISABLED IN THIS VERSION>>
|
| MERGEVARS       Specifies the value to be passed to            &g_subjid visitnum (Opt)
|                 %tu_cr8wnldoses MERGEVARS parameter
|     <<DISABLED IN THIS VERSION>>
|
| MODEL           Specifies the value to be passed to            [blank] (Opt)
|                 %tu_cr8wnldoses MODEL parameter
|     <<DISABLED IN THIS VERSION>>
|
| SORTCONCS       Specifies the value to be passed to            pctyp pcspec pcan &g_subjid         
|                 %tu_cr8wnlconcs SORT parameter                 &g_trtgrp pernum visitnum
|                                                                ptmnum (Req)
|
| SORTDOSES       Specifies the value to be passed to            pctyp pcspec pcan &g_subjid           
|                 %tu_cr8wnldoses SORTDOSES parameter            &g_trtgrp pernum visitnum (Opt)
|     <<DISABLED IN THIS VERSION>>
|
| STEADYSTATE     Specifies the value to be passed to            N (Opt)
|                 %tu_cr8wnldoses STEADYSTATE parameter
|     <<DISABLED IN THIS VERSION>>
|
| SUBSETCONCS     Specifies the value to be passed to            [blank] (Opt)
|                 %tu_cr8wnlconcs SUBSET parameter
|                 and to the %tu_cr8wnldoses SUBSETCONCS 
|                 parameter
|     <<%tu_cr8wnldoses DISABLED IN THIS VERSION>>
|
| TIMELASTDOSE    Specifies the value to be passed to            [blank] (Opt)
|                 %tu_cr8wnldoses TIMELASTDOSE parameter
|     <<DISABLED IN THIS VERSION>>
|
| Output:         This macro produces a set of WinNonlin
|                 -ready concentration files and an
|                 associated set of WinNonlin-ready doses
|                 files. 
|                 <<DOSEFILES disabled in current version >>
|
| Global macro variables created: none
|
| Macros called:
|(@) tr_putlocals
|(@) tu_abort
|(@) tu_cr8wnlconcs
|(@) tu_cr8wnldoses
|(@) tu_putglobals
|(@) tu_valparms
|(@) tu_xcpinit
|(@) tu_xcpterm
|(@) tu_xcpsectioninit
|(@) tu_xcpsectionterm
|
| Example: 
| 
| %tc_wnl(fileoutdir=&g_pkdata
|        ,fileoutpfx=wnl
|        ,xcpfile=&g_pkdata/&g_fnc._recon
|        ,xcpodsdest=html
|        ,xcpoutfilesfx=&xcpodsdest
|        ,cv=ardata.demo [height fvc] [subjid] ardata.vitals [weight] [visitnum=1]
|        ,dsetinconcs=ardata.pkcnc
|        ,sortconcs=pctyp pcspec pcan &g_subjid &g_trtgrp pernum visitnum ptmnum
|        ,sortdoses=pctyp pcspec pcan &g_subjid &g_trtgrp pernum visitnum
|        ,splitvars=pctyp pcan
|        ,unitpairs=pcatmen=pcatmu pcsttmdv=pctmdvu pcentmdv=pctmdvu pcorres=pcorresu
|        ,varsoutconcs=studyid pctyp pcspec pcan &g_centid &g_subjid &g_trtgrp visit ptm pcstdt pcsttm pcatmnum pcorres pcwnln pcwnlrt pcllqc age sex race pcsmpid
|        ,dosefiles=N
|        ,doseint=0
|        ,doseunit=doseunit
|        ,dsetindoses=ardata.exposure
|        ,lengthinfusion=0.25
|        ,mergevars=&g_subjid visitnum
|        ,model=200
|        ,steadystate=N
|        ,subsetconcs=(ptm ne: 'PRE-DOSE') and (le visitnum le 14)
|        ,timelastdose=0.5);
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
|                          &PREFIX:. Also create the local macro variable: PREFIX
|                          at the beginning of normal processing
|
|*******************************************************************************
|
| Modified By: Ian Barretto
| Date of Modification: 17th December 2004
| New version/draft number: 01-003
| Modification ID: ib10254.01-003
| Reason For Modification: Removed tu_cr8wnldoses from the macros called list
|                          to check-in to the HARP application.
|*******************************************************************************
|
| Modified By: Trevor Welby
| Date of Modification: 15-Feb-05
| New version/draft number: 01-004
| Modification ID: TQW9753.01-004
| Reason For Modification:
|                          Add FILEOUTDIR parameter
|
|                          The XCPFILE parameter is now passed to %tu_xcpinit
|                          OUTFILE parameter
|
|                          Add XCPODSDEST and XCPOUTFILESFX parameters
|
|                          Resolve inconsistencies between source code and unit
|                          specification in the header section and comments against
|                          macro parameters
|
|                          Remove redundant validation code handled by lower
|                          level macros
|
|*******************************************************************************
|
| Modified By: Andrew Ratcliffe
| Date of Modification: 28-Feb-05
| New version/draft number: 01-005
| Modification ID: AR5
| Reason For Modification: Amend comment in %macro statement for VARSOUTCONCS to meet US.
|                          Was calling tu_xcpinit with odsfilesfx=&xcpodsfilesfx. Corrected
|                          to outfilesfx=&xcpodsfilesfx.
|********************************************************************************
|
| Modified By:               Trevor Welby
| Date of Modification:      21-Jul-05
| New version/draft number:  02-001
| Modification ID:           TQW9753.02-001
| Reason For Modification:   Add functionality to create WinNonLin-ready doses
|                            files
|********************************************************************************
| Modified By:               Trevor Welby
| Date of Modification:      12-Sep-05
| New version/draft number:  02-002
| Modification ID:           TQW9753.02-002
| Reason For Modification:   Verify that a value for the 
|                            parameter STEADYSTATE is specified
|
|                            Remove call to %tu_tidyup and associated
|                            prefix macro variable   
|
|                            Modify the program header descriptions for: 
|                            DSETINCONCS, SPLITVARS, SUBSETCONS, 
|                            FILEOUTDIR and FILEOUTPFX 
|
|                            Modify the source code to perform validation using
|                            the %tu_valparms macro
|
|                            Mouseover text modified for SPLITVARS and SORTDOSES
|                            
|                            FILEOUTDIR, XCPODSDEST and XCPOUTFILESFX parameters 
|                            are now listed as required parameters and validated 
|                            accordingly
|
|                            LENGTHINFUSION parameter is now listed as optional
|
|                            MODEL parameter is now listed as required
|
|                            Macro Version, draft dropped
|
|                            Default specification of JOINMSG parameter now
|                            dropped from %tu_cr8wnldoses call      
|********************************************************************************
|
| Modified By:              Warwick Benger
| Date of Modification:     3-Dec-2008
| New version number:       03-001
| Modification ID:          WJB1
| Reason For Modification:  1. Disable DOSEFILES functionality for current release
|                              (disallowed in parameter validation but utility macro 
|                              still present in code)
|                           2. Add pcorresu to varsoutconcs
|                           3. Check if anything has been written to xcp file,
|                              if not write summary - 0 ERRORS, WARNINGS, NOTES
|                           4. Add validation of fileoutdir and xcpfile
|                           5. Changed default for fileoutpfx to &g_fnc
|********************************************************************************
| Modified By:              Ian Barretto
| Date of Modification:     20-Mar-2009
| New version number:       03-002
| Modification ID:          IB1
| Reason For Modification:  Removed double angled brackets from parameter 
|                           comments so that the macros could be checked into HARP    
|
********************************************************************************/
%macro tc_wnl(
    fileoutdir=&g_pkdata              /* Name of output directory path  */
   ,fileoutpfx=&g_fnc.                /* Optional prefix for data output files */
   ,xcpfile=&g_pkdata./&g_fnc._recon  /* Name and location of exception report */
   ,xcpodsdest=html                   /* ODS destination of reconciliation report */
   ,xcpoutfilesfx=html                /* Output file suffix */
   ,cv=                               /* Covariate data to be added in Libname.Dataset <[Var]> <[By Var]> <[Where Clause]> format  */
   ,dsetinconcs=ardata.pkcnc          /* type:ID Name of input A&R PKCNC dataset  */
   ,splitvars=pctyp pcspec pcan       /* Name of analyte variable to split the output files  */
   ,unitpairs=                        /* Pairs of variables and units variables to be used as headers in Concs ouput files, e.g. age=ageu height=heightu  */
   ,varsoutconcs=studyid pctyp pcspec pcan &g_centid &g_subjid &g_trtgrp visit ptm pcstdt pcsttm pcatmnum pcorres pcorresu pcwnln pcwnlrt pcllqc age sex race pcsmpid /* List of variables to be included in the output file(s) */
   ,dosefiles=N                       /* Create WinNonLin-ready doses file(s) - dosefiles=Y DISABLED IN THIS VERSION */
   ,doseint=0                         /* Dosing interval for steady-state - DISABLED IN THIS VERSION */
   ,doseunit=doseunit                 /* Specifies the dose unit variable to be used in the Doses file -DISABLED IN THIS VERSION */
   ,dsetindoses=ardata.exposure       /* type:ID Name of input A&R EXPOSURE dataset - DISABLED IN THIS VERSION */
   ,lengthinfusion=                   /* Length of infusion (hours) - DISABLED IN THIS VERSION */
   ,mergevars=&g_subjid visitnum      /* Variables for joining EXPOSURE and PKCNC datasets - DISABLED IN THIS VERSION */
   ,model=                            /* Specifies the PK model used to build the Doses file - DISABLED IN THIS VERSION */
   ,sortconcs=pctyp pcspec pcan &g_subjid &g_trtgrp pernum visitnum ptmnum /* Sort order of concentration output files  */
   ,sortdoses=pctyp pcspec pcan &g_subjid &g_trtgrp pernum visitnum /* Sort order of doses output files - DISABLED IN THIS VERSION */
   ,steadystate=N                     /* Is dosing regime steady state? - DISABLED IN THIS VERSION */
   ,subsetconcs=                      /* Optionally specify a WHERE clause to subset the A&R PKCNC dataset */
   ,timelastdose=                     /* Time of last dose (hours) - DISABLED IN THIS VERSION */
   );

  /*
  / Echo values of parameters and global macro variables to the log.
  /------------------------------------------------------------------------------*/
  %local MacroVersion /* Carries macro version number */
         macroname    /* Carries macro name */
         pv_abort     /* PV level abort flag */
         xcppop;      /* Flags whether exception file is populated */

  %let MacroVersion=3 build 2;
  %let macroname=&sysmacroname;
  %let pv_abort=0;
  %let dosefiles=%nrbquote(&dosefiles.);
  %let fileoutdir=%nrbquote(&fileoutdir.);
  %let xcpfile=%nrbquote(&xcpfile.);

  %tu_putglobals();
  %include "&g_refdata./tr_putlocals.sas";

  /*
  / Perform parameter validation
  /------------------------------------------------------------------------------*/

  %if &dosefiles. eq Y %then
  %do;  /* Validate parameters for tu_cr8wnldoses <<DISABLED IN CURRENT VERSION >> */ 

    /*
    / Verify that a value is specified for the following parameters:
    / DOSEINT DOSEUNIT DSETINDOSES MERGEVARS MODEL SORTDOSES STEADYSTATE 
    / TIMELASTDOSE
    /------------------------------------------------------------------------------*/
   /* WJB1: DOSEFILES FUNCTIONALITY DISABLED IN THIS VERSION
   %tu_valparms(macroname=&macroname.
                ,chktype=isnotblank
                ,pv_varsin=doseint doseunit dsetindoses mergevars model sortdoses steadystate timelastdose
                ,abortyn = Y
                );
   */
    %put %str(RTE)RROR: &macroname: DOSEFILES FUNCTIONALITY DISABLED IN THIS VERSION - DOSEFILES=Y IS NOT A VALID OPTION; /* WJB1 */
    %let pv_abort = 1;
  %end;  
  %else %if &dosefiles. ne N and &dosefiles. ne %then
  %do;
    %put %str(RTE)RROR: &macroname: DOSEFILES = &dosefiles IS NOT A VALID OPTION; /* WJB1 */
    %let pv_abort = 1;
  %end;  
  
  /* Verify that a value is specified for the following parameters:
  / DOSEFILES FILEOUTDIR XCPFILE XCPODSDEST XCPOUTFILESFX DSETINCONCS SORTCONCS VARSOUTCONCS SPLITVARS 
  /------------------------------------------------------------------------------*/
  %tu_valparms(macroname=&macroname.
              ,chktype=isnotblank
              ,pv_varsin=dosefiles fileoutdir xcpfile /* WJB1 */  xcpodsdest xcpoutfilesfx dsetinconcs sortconcs varsoutconcs splitvars
              ,abortyn=N
              );

  %if %eval(&g_abort. + &pv_abort.) gt 0 %then
  %do;
    %put %str(RTE)RROR: &macroname: Macro has failed parameter validation for reasons stated with %str(RTE)RRORs above;
    %tu_abort(option=force);
  %end;

  /*
  / Perform Normal Processing
  /------------------------------------------------------------------------------*/

  /* Initialise exception report */
  %tu_xcpinit(header=Creation of WNL Files
             ,outfile=&xcpfile
             ,odsdest=&xcpodsdest
             ,outfilesfx=&xcpoutfilesfx  /*AR5*/
             );

  /* Create the concentration files */
  %tu_cr8wnlconcs(dsetin=&dsetinconcs
                 ,fileoutdir=&fileoutdir
                 ,fileoutpfx=&fileoutpfx
                 ,sort=&sortconcs
                 ,splitvars=&splitvars
                 ,subset=&subsetconcs
                 ,unitpairs=&unitpairs
                 ,cv=&cv
                 ,varsout=&varsoutconcs
                 );

  /* Create Doses file(s), if applicable */ 
  /* DOSEFILES FUNCTIONALITY DISABLED IN THIS VERSION: WJB1 */
  %if &dosefiles. eq Y %then
  %do;   
    %tu_cr8wnldoses(fileoutdir=&fileoutdir
                   ,fileoutpfx=&fileoutpfx
                   ,doseint=&doseint
                   ,doseunit=&doseunit
                   ,dsetinconcs=&dsetinconcs
                   ,dsetindoses=&dsetindoses
                   ,lengthinfusion=&lengthinfusion
                   ,mergevars=&mergevars
                   ,model=&model
                   ,sortdoses=&sortdoses
                   ,splitvars=&splitvars
                   ,steadystate=&steadystate
                   ,subsetconcs=&subsetconcs
                   ,timelastdose=&timelastdose
                   );
   %end;  
 

  /*
  /  Establish if xcpfile contains any entries, if not write summary to xcpfile
  /------------------------------------------------------------------------------*/
  %let xcppop=N;
  data _null_; 
    length lineread $256.; 
    infile "&g_pkdata./&g_fnc._recon.&xcpoutfilesfx." missover delimiter="|"; 
    input lineread $;
    if substr(lineread,1,3)="<td" then call symput('xcppop',"Y");
  run; 

  %if "&xcppop."="N" %then %do;
    data _null_;
      %tu_xcpsectioninit(header= ---- Summary ---- );
      %tu_xcpsectionterm(end=1);
    run;
  %end;

  /*
  /  Terminate the exception report
  /------------------------------------------------------------------------------*/
  %tu_xcpterm;  

  %tu_abort();

%mend tc_wnl;
