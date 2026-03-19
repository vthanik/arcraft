/*******************************************************************************
|
| Macro Name:      tc_pkcnc
|
| Macro Version:   2.1
|
| SAS Version:     9.1
|
| Created By:      James McGiffen/Andrew Ratcliffe (RTSL)
|
| Date:            08-Dec-2004
|
| Macro Purpose:   The purpose of this dataset creation macro is to create
|                  an A&R PKCNC dataset (from either an SI/SPECTRE dataset 
|                  or a DM/ET-Tool dataset) 
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME              DESCRIPTION                         REQ/OPT  DEFAULT
| --------------  -----------------------------------   -------  ---------------
|
| DSETIN            Specifies the name of the input        REQ   [blank]
|                   PK dataset (DM or SI)      
|                                                                
| DSETOUT           Specifies the name of the output       REQ   ardata.pkcnc  
|                   A&R PKCNC dataset
|
| XCPFILE           Specifies the value to be passed       REQ   &g_pkdata/&g_fnc._recon
|                   to %tu_xcpinit's outfile parameter
|
| ELTMSTDUNIT       Passed as %tu_cr8arpk's parameter of   OPT   HRS  
|                   the same name. Specifies the units to 
|                   which ELTMNUM values shall be 
|                   standardised
|
|                   Valid values: SEC, MIN, HRS, DAY
|
| DVTMSTDUNIT       Passed as %tu_cr8arpk's parameter of   OPT   HRS
|                   the same name. Specifies the units to 
|                   which derived durations shall be 
|                   standardised
|
|                   Valid values: SEC, MIN, HRS, DAY
|
| DSETINPERIOD      Passed as %tu_cr8arpk's parameter      OPT   [blank]
|                   of the same name. . Allows user to 
|                   specify period dataset for use in 
|                   creation of PCPERSDY and PCPEREDY
|
| REFDATEDSETSUBSET Passed as %tu_cr8dmpk's parameter      OPT   [blank]
|                   of the same name. 
|
| REFDATEOPTION     Passed as %tu_cr8dmpk's parameter      OPT   Treat
|                   of the same name.         
|
| REFDATESOURCEDSET Passed as %tu_cr8dmpk's parameter      OPT   [blank]
|                   of the same name. 
|
| REFDATESOURCEVAR  Passed as %tu_cr8dmpk's parameter      OPT   [blank]  
|                   of the same name.         
|
| REFDATEVISITNUM   Passed as %tu_cr8dmpk's parameter      OPT   [blank]
|                   of the same name.         
|
| PTRTCDINF         Passed as %tu_cr8dmpk's parameter      OPT   [blank] 
|                   of the same name. 
|                   
| TRTCDINF          Passed as %tu_cr8dmpk's parameter      OPT   [blank]    
|                   of the same name. 
|                     
| PCWTU             Passed as %tu_cr8arpk's parameter      OPT   g
|                   of the same name. 
|
| SMSFILE           Passed as %tu_cr8arpk's parameter      OPT   [blank]
|                   of the same name           
|                                                                
| SMSKEEP           Passed as %tu_cr8arpk's parameter      OPT   PCSMPID PCSPEC PCAN PCLLQC 
|                   of the same name                             PCORRES PCORRESU subjid2000
|
| SMSRENAME         Passed as %tu_cr8arpk's parameter      OPT   [blank]
|                   of the same name
|
| SMSDELIM          Passed as %tu_cr8arpk's parameter      OPT   |
|                   of the same name
|
| JOINMSG           Passed as %tu_cr8arpk's JOINMSG        OPT   WARNING
|                   parameter   
|
| XCPODSDEST        Optionally specifies the type of       OPT   HTML
|                   exception reporting file 
|
| XCPOUTFILESFX     Optionally specifies the suffix        OPT   HTML
|                   type used in the exception reporting 
|                   file
| 
| DSETINEXP         Passed as %tu_cr8arpk's parameter      OPT   ardata.exposure
|                   of the same name                        
|
| EXPJOINBYVARS     Passed as %tu_cr8arpk's parameter      OPT   &g_centid &g_subjid pernum period visitnum visit
|                   of the same name                        
|
| IMPUTEBY          Specifies the variables by which the   OPT   &g_centid &g_subjid pctypcd pcan pernum  
|                   imputation shall be done. The dataset        visitnum pcrfstdm ptmnum (Opt)
|                   is sorted prior to imputation using 
|                   any vars in IMPUTEBY which are found 
|                   in the dataset. Imputation is then 
|                   performed, restarting whenever any   
|                   IMPUTEBY variable other than the  
|                   last one changes.              
| 
| IMPUTETYPE        Specifies either standard (S) or       OPT  S
|                   alternative (A) imputation.
| 
| MERGEINCSUBJ      Option to include SUBJID in PK merge.  OPT  N 
|                   If Y, merge on SUBJID PCSMPID, if N, 
|                   merge on PCSMPID 
| 
| DELETEMISMERGES   Option to delete miserged records.     OPT  Y
|                   records which exist in both DM dataset 
|                   and SMS will be retained.
| 
| Output:           This macro produces an A&R PKCNC 
|                   dataset and creates an exception 
|                   report.
|
| Global macro variables created: NONE
|
| Macros called:
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_chknames
| (@) tu_cr8dmpk
| (@) tu_cr8arpk
| (@) tu_attrib
| (@) tu_misschk
| (@) tu_xcpinit
| (@) tu_xcpterm
| (@) tu_tidyup
| (@) tu_abort
|
| Example:
|    %tc_pkcnc(
|         ,dsetin       = dmdata.pk
|         ,dsetintype   = si
|         ,dsetinperiod = dmdata.period
|         ,dsetout      = ardata.pkcnc
|         ,smsfile      = /arenv/arwork/harptestcpd3/phase1pg/wnl/dmdata/sms2000.dat
|         ,joinmsg      = warning
|         );
|
|******************************************************************************
| Change Log
|
| Modified By: Andrew Ratcliffe, RTSL
| Date of Modification: 08-Dec-2004
| New version/draft number: 1/2
| Modification ID:
| Reason For Modification: Remove comments from calls to sub-macros.
|                          Add matching do-end comments to nested do-ends.
|                          Split message prefixes into two parts.
|                          Change creation date in header.
|
| Modified By: Andrew Ratcliffe, RTSL
| Date of Modification: 13-Jan-2005
| New version/draft number: 1/3
| Modification ID:
| Reason For Modification: Pass the correct value for the REFDATEVISITNUM parameter
|                          of tu_cr8dmpk
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     09-Feb-2005
| New version/draft number: 1/4
| Modification ID:
| Reason For Modification: Add parms EXPJOINBYVARS and DSETINEXP. Pass them
|                           to tu_cr8arpk.
|                          Pass XCPFILE to tu_xcpinit as OUTFILE.
|
| Modified By:              Warwick Benger
| Date of Modification:     3-Oct-2008
| New version number:       02-001
| Modification ID:          WJB1
| Reason For Modification:  1. New macro parameter IMPUTETYPE to specify Standard or Alternative
|                               (passed to tu_pkcncderv via tu_cr8arpk)
|                           2. New macro parameter MERGEINCSUBJ
|                               (passed to tu_cr8arpk)
|                           3. New macro parameter DELETEMISMERGES
|                               (passed to tu_cr8arpk)
|                           4. Surfacing tu_pkcncderv parameter IMPUTEBY, change of defaults
|                           5. Remove dsetintype parameter, assume SI dataset input
|                           6. Add ELTMSTDUNIT parameter to pass to tu_cr8arpk 
|                           7. Add DVTMSTDUNIT parameter to pass to tu_cr8arpk 
|                           8. Remove randomfile parameter and PV 
|                           9. Changed DSETINPERIOD default to blank 
|
*******************************************************************************/

%macro tc_pkcnc(
   dsetin=                            /* type:ID Input name of dataset */
  ,dsetout=ardata.pkcnc               /* Output dataset */
  ,xcpfile=&g_pkdata./&g_fnc._recon   /* Name and location of exception report */
  ,dsetinperiod=                      /* type:ID Name of input SI PERIOD dataset */
  ,refdatedsetsubset=                 /* WHERE clause applied to reference date source dataset */
  ,refdateoption=Treat                /* Reference date source option */
  ,refdatesourcedset=                 /* type:ID Reference date source dataset */ 
  ,refdatesourcevar=                  /* Reference date source variable */
  ,refdatevisitnum=                   /* Specific visit date at which reference date is to be taken */  
  ,ptrtcdinf=                         /* Informat to derive PTRTCD from PTRTGRP */
  ,trtcdinf=                          /* Informat to derive TRTCD from TRTGRP */ 
  ,pcwtu=g                            /* Value to be placed into PCWTU variable */
  ,eltmstdunit=HRS                    /* Units to which ELTMSTN values shall be standardised */
  ,dvtmstdunit=HRS                    /* Units to which derived durations shall be standardised */
  ,smsfile=                           /* type:IF Name of input SMS2000 file */
  ,smskeep=PCSMPID PCSPEC PCAN PCLLQC PCORRES PCORRESU subjid2000 /* Variables to be kept on temporary SMS2000 dataset */
  ,smsrename=                         /* Optional renames of SMS2000 temporary datasets variables */
  ,smsdelim=|                         /* Delimiter character of the SMS2000 file */
  ,joinmsg=WARNING                    /* Type of messages to be issued from join with SMS2000 (error or warning) */   
  ,xcpodsdest=html                    /* Type of Exception Report file */
  ,xcpoutfilesfx=html                 /* Suffix for Exception Report file */
  ,dsetinexp=ardata.exposure          /* type:ID Name of exposure dataset */
  ,expjoinbyvars=&g_centid &g_subjid pernum period visitnum visit /* By vars for join with Exposure dataset */
  ,imputeby=&g_centid &g_subjid pctypcd pcan pernum visitnum pcrfdsdm ptmnum /* Variables to impute by */
  ,imputetype=S                       /* Imputation type. Specifies either standard (S) or alternative (A) imputation */
  ,mergeincsubj=N                     /* Option to include SUBJID in PK merge. If Y, merge on SUBJID PCSMPID, if N, merge on PCSMPID  */
  ,deletemismerges=Y                  /* Option to delete miserged records. If Y, only records which exist in both DM dataset and SMS will be retained. */
  );

  /*
  / Echo parameter values and global macro variables to the log.
  /----------------------------------------------------------------------------*/
  %local MacroVersion /* Carries macro version number */
         prefix;      /* Carries file prefix for work files */
         
  %let MacroVersion = 2;
  %let prefix = %substr(&sysmacroname,3);

  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_dsplanfile);
  
  /*
  / PARAMETER VALIDATION
  /----------------------------------------------------------------------------*/
  %let dsetin=%nrbquote(&dsetin.);
  %let dsetout=%nrbquote(&dsetout.);
  %let xcpfile=%nrbquote(&xcpfile.); 

  /*
  / Check for required parameters.
  /----------------------------------------------------------------------------*/
  /* Check the dsetin variable*/
  %if &dsetin. eq %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: The parameter DSETIN is required.;
    %let g_abort=1;
  %end;
  %else
  %do;  /* we have a DSETIN value */
    %if %sysfunc(exist(&dsetin., data)) ne 1 %then 
    %do;  /* Dataset does not exist */
      %put %str(RTE)RROR: &sysmacroname.: The dataset identified by DSETIN (&dsetin.) does not exist.;
      %let g_abort=1;
    %end; 
  %end; /* we have a DSETIN value */
  
  /* Check that dsetout is valid */
  %if &dsetout. eq %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: The parameter DSETOUT is required.;
    %let g_abort=1;
  %end;
  %else
  %do;  /* we have a DSETOUT value */
    %if %nrbquote(%tu_chknames(&dsetout., data)) ne %then
    %do;  /* Dataset does not exist */
      %put %str(RTE)RROR: &sysmacroname.: The parameter DSETOUT (&dsetout.) is not a valid sas dataset name.;
      %let g_abort=1;
    %end; 
  %end; /* we have a DSETOUT value */
  
  /* Check that xcpfile is not blank*/      
  %if &xcpfile. eq %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: The parameter XCPFILE is required.;
    %let g_abort=1;
  %end;
  
  /* Abort at the end of the parameter validation if G_ABORT is set to 1*/
  %tu_abort;
  
  /*
  / NORMAL PROCESSING
  /----------------------------------------------------------------------------*/

  /* Open the exception reporting */
  %tu_xcpinit(header     = TC_PKCNC
             ,odsdest    = &xcpodsdest
             ,outfilesfx = &xcpoutfilesfx
             ,outfile    = &xcpfile
      	       );

  %local currentDataset;
  %let currentDataset=&dsetin;

  /* Perform SI conversion of DM dataset using the tu_cr8dmpk macro */
  %tu_cr8dmpk(DSETIN =&currentDataset                 
             ,DSETOUT = &prefix._simodified           
             ,REFDATEOPTION = &refdateoption
             ,REFDATEVISITNUM = &refdatevisitnum  
             ,REFDATESOURCEDSET = &refdatesourcedset
             ,REFDATESOURCEVAR = &refdatesourcevar
             ,REFDATEDSETSUBSET = &refdatedsetsubset
             ,TRTCDINF = &trtcdinf
             ,PTRTCDINF = &ptrtcdinf
             );
  %let currentDataset=&prefix._simodified;

  /* Create an output dataset using the tu_cr8arpk macro */
  %tu_cr8arpk(dsetin=&currentDataset
             ,dsetout=&prefix._arpkcnc
             ,DSETINPERIOD = &dsetinperiod
             ,smsfile=&smsfile
             ,smskeep=&smskeep
             ,joinmsg=&joinmsg
             ,smsrename=&smsrename
             ,smsdelim=&smsdelim
             ,PCWTU = &pcwtu
             ,eltmstdunit=&eltmstdunit
             ,dvtmstdunit=&dvtmstdunit
             ,dsetinexp=&dsetinexp 
             ,expjoinbyvars=&expjoinbyvars
             ,imputeby=&imputeby                /* WJB1  */
             ,imputetype=&imputetype            /* WJB1  */
             ,mergeincsubj=&mergeincsubj        /* WJB1  */
             ,deletemismerges=&deletemismerges  /* WJB1  */
             );
  %let currentDataset=&prefix._arpkcnc;
  
  /* Create output file */
  %tu_attrib(dsetin=&currentDataset
            ,dsetout=&dsetout
            ,dsplan=&g_dsplanfile
            );
                
  /* Call tu_misschk */
  %tu_misschk(dsetin=&dsetout);

  /* Close the exception reporting */
  %tu_xcpterm;  

  /* Delete temporary datasets used in this macro. */
  %tu_tidyup(rmdset=&prefix: 
            ,glbmac=NONE
            );

  %tu_abort;

%mend tc_pkcnc;

