/******************************************************************************* 
|
| Macro Name:      tc_nonmemx.sas
|
| Macro Version:   1.0
|
| SAS Version:     8.2
|
| Created By:      Andrew Ratcliffe, RTSL, www.ratcliffe.co.uk
|
| Date:            19-Jun-2005
|
| Macro Purpose:   To create NONMEM files for cross-over studies.
|
| Macro Design:    PROCEDURE STYLE MACRO
| 
| Input Parameters:
|
| NAME              DESCRIPTION                         DEFAULT 
| COLORDER          Specifies columns to be placed at   &g_subjid &outdate &outtime (Opt)
|                   the left side of the output file
|
| CV                Specifies covariates to be added    [blank] (Opt)
|
| DCDSEP            Specifies the character to be used  ! (Req)
|                   to separate decode values in the 
|                   output file(s)
|
| DERVVARS          Specifies derived variables to be   seq (Opt)
|                   added as additional columns  
|
| DOSETIMES         Specifies time constants for        [blank] (Opt)
|                   dosing times for specific dosing 
|                   frequencies
|
| DSETINEXP         Specifies the name of the input     ardata.exposure (Req)
|                   A&R EXPOSURE dataset
|
| DSETOUT           Specifies the name of the output    work._nonmem (Req)
|                   dataset
|
| DV                Specifies the dependant variable(s) [blank] (Req)
|                   to be added to the exposure/dosing 
|                   information. 
|
| DVILEAVEBY        Specifies the variable(s) by which  &g_subjid pernum visitnum (Req)
|                   the dependant variable(s) shall be 
|                   interleaved
|
| DVSORTBY          Specifies the variables to be used  &dvileaveby &outdate &outtime (Req)
|                   to sort the result of the 
|                   interleaving of the dependant variable(s)
|
| EXENTM            Specifies the name of the end-      exentm (Req)
|                   time column in the DSETINEXP 
|                   dataset. Can alternatively be specified as a time constant
|
| EXPAFTER          Specifies the relative position     0 (Req)
|                   of exposure/dosing information in 
|                   the event of matching DV date/time values
|
| EXPCMT            Specifies the CMT value to be       [blank] (Req)
|                   assigned to exposure/dosing rows in 
|                   the output file
|
| EXSTTM            Specifies the name of the start-    exsttm (Req)
|                   time column in the DSETINEXP 
|                   dataset. Can alternatively be specified as a time constant
|
| FILEDROP          Specifies variables that shall not  doseunit doseucd (Opt)
|                   be included in the output file(s)
|
| FILEOUTDIR        Specifies the directory into which  &g_pkdata (Req)
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
| JOINMSG           Specifies the type of XCP messages  error (Req)
|                   to be produced in case of 
|                   mismatches in joins
|
| OUTDATE           Specifies the name to be used for   dat2 (Req) 
|                   the (formatted) date column in the 
|                   output file
|
| OUTTIME           Specifies the name to be used for   time (Req) 
|                   the (formatted) time column in the 
|                   output file
|
| PERIODRESET       Specifies whether evid=3 records    N (Req)
|                   should be inserted at the 
|                   commencement of each new period in the data. If evid=3 records 
|                   are inserted, the relative time shall be reset to zero too
|
| PLACEBO           Specifies a where-clause to         &g_trtgrp eq: 'Pl' (Req)
|                   identify placebo rows
|
| POSTHOCBY         Specifies the sort order to be      [blank] (opt)
|                   applied to the posthoc dataset
|
| POSTHOCDSET       Specifies the name of the posthoc   [blank] (opt)
|                   dataset
|
| POSTHOCDIR        Specifies the name of the dir-      &g_dmdata (opt)
|                   ectory in which the post-hoc files 
|                   shall be found
|
| POSTHOCMASK       Operating System-specific mask      [blank] (opt)
|                   specifies the names of the NONMEM 
|                   post-hoc files to be read
|
| PREDTIME          Specifies how to handle relative    allzero (Req)
|                   times for pre-dose values
|
| SPLITMODE         Specifies the method for splitting  NONE (Req)
|                   the NONMEM data into multiple 
|                   output files
|
| SPLITPROP         Specifies (when SPLITMODE=PROP is   [blank] (Opt)
|                   chosen) what proportion of 
|                   randomly selected subjects shall be placed into the first of the two output files
|
| SPLITVARS         Specifies the variable(s) by which  [blank] (Opt)
|                   the NONMEM data shall be split 
|                   into multiple output files
|
| TIMEVAR           Specifies the name to be used for   reltime (Req)
|                   the relative time column in the 
|                   output file
|
| UNITPAIRS         Specifies units variables           [blank] (Opt)
|
| XCPFILE           Specifies the value to be passed    &g_pkdata/&g_fnc._recon (Req)
|                   to tu_xcpinits OUTFILE parameter
|
| XCPODSDEST        Specifies the ODS destination       html (Req)
|                   which the XCP shall be written
|
| XCPOUTFILESFX     Specifies the suffix of the name    &xcpodsdest (Req)
|                   of the XCP file
|
| Output: This macro produces a set of NONMEM-ready files.
|
| Global macro variables created:  None
|
| Macros called:
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_xcpinit
| (@) tu_nmexpoexpand
| (@) tu_nmdv
| (@) tu_getnmposthoc
| (@) tu_nmcv
| (@) tu_nmderv
| (@) tu_nmtimeshift
| (@) tu_cr8nm
| (@) tu_xcpterm
| (@) tu_tidyup
| (@) tu_abort
|
| Example:
|
| %tc_nonmemx(dsetinexp = ardata.exposure 
|            ,expcmt = 0
|            ,dv = ardata.pkcnc  pcwnln  pcstdt pcsttm pcan 1
|                  ardata.pkcnc  pcllqn  pcstdt pcsttm 'bp' 2
|            ,cv = WORK.demo [age ageu] [subjid]
|            ,exentm = '00:00't
|            ,dervvars = bsa [!!ardata.demo!agecatcd] [bodser]
|            ,splitmode=none
|            ,predtime=allzero
|            ,unitpairs = amt=doseunit age=ageu
|            ,colorder = subjid pernum visitnum date tim2
|            );
|
|******************************************************************************* 
| Change Log 
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     05-Jul-2005
| New version number:       1/2
| Modification ID:          
| Reason For Modification:  Add SEQ as default for DERVVARS.
|                           Add &G_CENTID and PERNUM to default for DVILEAVEBY.
|                           Change default for SPLITMODE from var to VARS.
|                           Chance EXPEVID to EXPCMT.
|                           Add code for handling of post-hoc files.
|                           Pass extra parms to tu_nmderv.
|                           Add FILEDROP parm (for %tu_cr8nm).
|                           Finish-off the list of sub-macros.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     29-Jul-2005
| New version number:       1/3
| Modification ID:          
| Reason For Modification:  Pass PERIODRESET to tu_nmtimeshift, not tu_nmdv.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     05-Sep-2005
| New version number:       1/4
| Modification ID:          
| Reason For Modification:  Do not pass EXSTTM/EXENTM to nmdv.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     12-Sep-2005
| New version number:       1/5
| Modification ID:          
| Reason For Modification:  Change defaults for OUTDATE, OUTTIME, and TIMEVAR.
|                           From date, time2, time to dat2, time, reltime.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     20-Sep-2005
| New version number:       1/6
| Modification ID:          
| Reason For Modification:  Change default for DVILEAVEBY and FILEDROP by 
|                           removing g_centid.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     22-Sep-2005
| New version number:       1/7
| Modification ID:          
| Reason For Modification:  Change default for UNITPAIRS to blank.
|                           Add DOSEUNIT and DOSEUCD to FILEDROP.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     18-Oct-2005
| New version number:       1/8
| Modification ID:          
| Reason For Modification:  Perform the change documented as 1/5: it appears it 
|                           was only made to the header comments, not the actual 
|                           defaults in the %macro statement.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     19-Oct-2005
| New version number:       1/9
| Modification ID:          AR9
| Reason For Modification:  Fix: Add SORTBY to %tu_nmcv call.
|                           Set COLORDER default to &g_subjid &outdate &outtime.
|                           Set SPLITMODE=NONE and SPLITPROP=[blank].
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     25-Oct-2005
| New version number:       1/10
| Modification ID:          
| Reason For Modification:  Remove type:id from dsetinexp (HARP prevents use of 
|                           dataset options such as WHERE).
|
| Modified By:              
| Date of Modification:     
| New version number:       
| Modification ID:          
| Reason For Modification:  
|
********************************************************************************/ 

%macro tc_nonmemx(
                  colorder      = &g_subjid &outdate &outtime /* Column order */
                 ,cv            =                 /* Covariate columns to be added: <Libname.Dataset> <[Var]> <[By Var]> <[Where Clause]>  */
                 ,dcdsep        = !               /* Decode separator */
                 ,dervvars      = seq             /* Derived variable columns to be added */
                 ,dosetimes     =                 /* Dosing times for specific dose frequency codes */
                 ,dsetinexp     = ardata.exposure /* Name of input A&R EXPOSURE dataset */
                 ,dsetout       = work._nonmem    /* Name of intermediate dataset to be created */
                 ,dv            =                 /* Dependant variable(s) */
                 ,dvileaveby    = &g_subjid pernum visitnum /* Variable(s) by which dependant variable(s) shall be interleaved */
                 ,dvsortby      = &dvileaveby &outdate &outtime /* Variable(s) by which the interleaved DV data shall be sorted */
                 ,exentm        = exentm          /* Name of the end-time column in DSETINEXP (or a time constant) */
                 ,expafter      = 0               /* Relative position of exposure/dosing information in the event of matching DV date/time values */
                 ,expcmt        =                 /* Compartment ID for exposure/dosing */
                 ,exsttm        = exsttm          /* Name of the start-time column in DSETINEXP (or a time constant) */
                 ,filedrop      = doseunit doseucd /* Variables that shall not be in output file(s) */
                 ,fileoutdir    = &g_pkdata       /* Directory for output file(s) */
                 ,fileoutpfx    = nonmem          /* Optional prefix for all output files */
                 ,fileoutqfr    = csv             /* Qualifier for all output files */
                 ,fileoutsfx    =                 /* Optional suffix for all output files */
                 ,joinmsg       = error           /* Type of XCP messages in case of mismatches in joins */
                 ,outdate       = dat2            /* Name of date column in output file */
                 ,outtime       = time            /* Name of time column in output file */
                 ,periodreset   = N               /* Add evid=3 records and reset relative time at each new period */
                 ,placebo       = &g_trtgrp eq: 'Pl' /* Where clause to identify placebo */
                 ,posthocby     =                 /* Sort order for post-hoc dataset */
                 ,posthocdset   =                 /* Post-hoc output dataset */
                 ,posthocdir    = &g_dmdata       /* Name of post-hoc input directory */
                 ,posthocmask   =                 /* Name(s) of input post-hoc file(s) */
                 ,predtime      = allzero         /* How to handle relative times for pre-dose values */
                 ,splitmode     = NONE            /* Method for splitting the data into multiple output files */
                 ,splitprop     =                 /* Proportion of split to be placed into 1st file */
                 ,splitvars     =                 /* Variable(s) by which output shall be split */
                 ,timevar       = reltime         /* Name of relative time column in output file */
                 ,unitpairs     =                 /* Pairs of variables and units variables to be used as headers in output files, e.g. age=ageu height=heightu */
                 ,XCPFILE       = &g_pkdata./&g_fnc._recon /* Name and location of exception report */
                 ,XCPODSDEST    = html            /* ODS destination for XCP report */
                 ,XCPOUTFILESFX = &xcpodsdest     /* Suffix for name of XCP  */
                 );

  /* Echo parameter values and global macro variables to the log */
 
  %local MacroVersion;
  %let MacroVersion = 1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=);

  %local prefix;
  %let prefix = %substr(&sysmacroname,3); 

  %local currentDataset;

  /* PARAMETER VALIDATION */

  /* Validate - DSETINEXP - passed to %tu_nmexpoexpand */

  /* Validate - DSETOUT - passed to %tu_cr8nm */

  /* Validate - DV - passed to %tu_nmdv */

  /* Validate - DVILEAVEBY - passed to %tu_nmdv */

  /* Validate - DVSORTBY - passed to %tu_nmdv */

  /* Validate - FILEDROP - passed to %tu_cr8nm */

  /* Validate - OUTDATE - passed to %tu_cr8nm */

  /* Validate - OUTTIME - passed to %tu_cr8nm */

  /* Validate - TIMEVAR - passed to %tu_cr8nm */

  /* Validate - EXSTTM - passed to %tu_nmexpoexpand */

  /* Validate - EXENTM - passed to %tu_nmexpoexpand */

  /* Validate - EXPAFTER - passed to %tu_nmdv */

  /* Validate - CV - passed to %tu_nmcv */

  /* Validate - DERVVARS - passed to %tu_nmderv */

  /* Validate - SPLITMODE - passed to %tu_cr8nm */

  /* Validate - SPLITPROP - passed to %tu_cr8nm */

  /* Validate - SPLITVARS - passed to %tu_cr8nm */

  /* Validate - FILEOUTDIR - passed to %tu_cr8nm */

  /* Validate - FILEOUTSFX - passed to %tu_cr8nm */

  /* Validate - FILEOUTPFX - passed to %tu_cr8nm */

  /* Validate - FILEOUTQFR - passed to %tu_cr8nm */

  /* Validate - XCPFILE - passed to %tu_xcpinit */

  /* Validate - XCPODSDEST - passed to %tu_xcpinit */

  /* Validate - XCPOUTFILESFX - passed to %tu_xcpinit */

  /* Validate - JOINMSG - passed to %tu_nmcv */

  /* Validate - DCDSEP - passed to %tu_cr8nm */

  /* Validate - PREDTIME - passed to %tu_nmtimeshift */

  /* Validate - UNITPAIRS - passed to %tu_cr8nm */

  /* Validate - DOSETIMES - passed to %tu_nmexpoexpand */

  /* Validate - COLORDER - passed to %tu_cr8nm */

  /* Validate - EXPCMT - passed to %tu_nmdv */

  /* Validate - PERIODRESET - passed to %tu_nmtimeshift */

  /* Validate - PLACEBO - passed to %tu_nmexpoexpand */

  /* Validate - POSTHOCBY - passed to %tu_getnmposthoc */

  /* Validate - POSTHOCDSET - passed to %tu_getnmposthoc */

  /* Validate - POSTHOCDIR - passed to %tu_getnmposthoc */

  /* Validate - POSTHOCMASK - passed to %tu_getnmposthoc */

  %tu_abort;

  /* NORMAL PROCESSING */

  /*
  / PLAN OF ACTION:
  / 1. Initialise the XCP environment
  / 2. Expand the exposure dataset 
  / 3. Add dependant variable(s)
  / 4. Optionally handle NONMEM posthoc file(s) 
  / 5. Add covariate(s) 
  / 6. Add derived variable(s)
  / 7. Create relative time variable
  / 8. Create "NONMEM" dataset
  / 9. Write the file(s) 
  / 10. Terminate the XCP environment
  /------------------------------------------------------*/

  /* 1. Initialise the XCP environment */
  %local macname;
  %let macname = &sysmacroname; /* Make sure header contains name of *this* macro rather than xcpinit */
  %tu_xcpinit(header =%str(&macname run on &sysdate at &systime.)
             ,odsdest=&xcpodsdest
             ,outfilesfx=&xcpoutfilesfx
             ,outfile=&xcpfile
             );

  /* 2. Expand the exposure dataset */
  %tu_nmexpoexpand(dsetin    = &dsetinexp
                  ,dsetout   = work.&prefix._expand
                  ,by        = &dvileaveby
                  ,exsttm    = &exsttm
                  ,exentm    = &exentm
                  ,dosetimes = &dosetimes
                  ,placebo   = &placebo
                  );
  %let currentDataset = work.&prefix._expand;

  /* 3. Add dependant variable(s) */
  %tu_nmdv(dsetinexp   = &currentDataset
          ,dsetout     = work.&prefix._nmdv
          ,dv          = &dv
          ,sortby      = &dvsortby
          ,ileaveby    = &dvileaveby
          ,outdate     = &outdate
          ,outtime     = &outtime
          ,expafter    = &expafter
          ,expcmt      = &expcmt
          );
  %let currentDataset = work.&prefix._nmdv;

  /* 4. Optionally handle NONMEM posthoc file(s) */
  %if %length(&posthocdset) gt 0 %then
  %do;
    %tu_getnmposthoc(by         = &posthocby
                    ,dsetout    = &posthocdset
                    ,infiledir  = &posthocdir
                    ,infilemask = &posthocmask
                    );
  %end;

  /* 5. Add covariate(s) */
  %tu_nmcv(dsetin  = &currentDataset
          ,dsetout = work.&prefix._nmcv
          ,cv      = &cv
          ,joinmsg = &joinmsg
          ,sortby  = &dvsortby  /*AR9*/
          );
  %let currentDataset = work.&prefix._nmcv;

  /* 6. Add derived variable(s) */
  %tu_nmderv(dsetin   = &currentDataset
            ,dsetout  = work.&prefix._nmderv
            ,dervvars = &dervvars
            ,outdate  = &outdate
            ,outtime  = &outtime
            ,sortby   = &dvsortby
            );
  %let currentDataset = work.&prefix._nmderv;

  /* 7. Create relative time variable */
  %tu_nmtimeshift(dsetin   = &currentDataset
                 ,dsetout  = work.&prefix._timeshift
                 ,date     = &outdate
                 ,time     = &outtime
                 ,timevar  = &timevar
                 ,predtime = &predtime
                 ,sortby   = &dvsortby
                 ,periodreset = &periodReset
                 );
  %let currentDataset = work.&prefix._timeshift;

  /* 8. Create "NONMEM dataset" */
  data &dsetout;
    set &currentDataset;
  run;

  /* 9. Write the file(s) */
  %tu_cr8nm(dsetin     = &dsetout
           ,drop       = &filedrop
           ,fileoutdir = &fileoutdir
           ,fileoutpfx = &fileoutpfx
           ,fileoutsfx = &fileoutsfx
           ,fileoutqfr = &fileoutqfr
           ,splitmode  = &splitmode 
           ,splitprop  = &splitprop 
           ,splitvars  = &splitvars
           ,sortby     = &dvsortby
           ,dcdsep     = &dcdsep
           ,unitpairs  = &unitpairs
           ,outtime    = &outtime
           ,outdate    = &outdate
           ,timevar    = &timevar
           ,colorder   = &colorder
           );

  /* 10. Terminate the XCP environment */
  %tu_xcpterm;

  /* Finish-off */
  %tu_tidyup(rmdset=&prefix:
            ,glbmac=NONE
            );
  quit;

  %tu_abort;

%mend tc_nonmemx;
