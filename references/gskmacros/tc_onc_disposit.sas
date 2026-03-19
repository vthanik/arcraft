/*******************************************************************************
|
| Macro Name:      tc_onc_disposit
|
| Macro Version:   1
|
| SAS Version:     8.2
|
| Created By:      Ian Barretto & Stephen Griffiths
|
| Date:            11-Jul-2007
|
| Macro Purpose:   Disposit Oncology wrapper macro to add Death Status variables
|
| Macro Design:    Procedure Style
|
| Global macro variables created: NONE
|
| Macros called:
|(@) tr_putlocals
|(@) tu_putglobals
|(@) tu_valparms
|(@) tc_disposit
|(@) tu_abort
|
|******************************************************************************
| Change Log
|
| Modified By:
| Date of Modification:
| New version/draft number:
| Modification ID:
| Reason For Modification:
|
*******************************************************************************/
%macro tc_onc_disposit (
     dsetin            = DMDATA.DISPOSIT,  /* Input dataset name */
     dsetout           = ARDATA.DISPOSIT,  /* Output dataset name */
     commonvarsyn      = Y,       /* Add common variables */
     treatvarsyn       = Y,       /* Add treatment variables */
     timeslicingyn     = Y,       /* Add timeslicing variables */
     datetimeyn        = Y,       /* Derive datetime variables */
     decodeyn          = Y,       /* Decode coded variables */
     derivationyn      = Y,       /* Dataset specific derivations */
     attributesyn      = Y,       /* Reconcile A&R dataset with planned A&R dataset */
     misschkyn         = Y,       /* Print warning message for variables in &DSETOUT with missing values on all records */
     recalcvisityn     = N,       /* Recalculate visit based on &REFDAT and &REFTIM */
     xovarsforpgyn     = N,       /* If derive crossover stydy specific variables for parallel study */
     agemonthsyn       = N,       /* Calculation of age in months */
     ageweeksyn        = N,       /* Calculation of age in weeks */
     agedaysyn         = N,       /* Calculation of age in days */
     refdat            = dsdt,    /* Reference date */
     reftim            = dswdtm,  /* Reference time */
     refdateoption     = TREAT,   /* Reference date source option */
     refdatevisitnum   = ,        /* Reference date visit number */
     refdatesourcedset = ,        /* Reference date source dataset */
     refdatesourcevar  = ,        /* Reference date source variable */
     refdatedsetsubset = ,        /* Where clause applied to source dataset */
     trtcdinf          = ,        /* Informat to derive TRTCD from TRTGRP */
     ptrtcdinf         = ,        /* Informat to derive PTRTCD from PTRTGRP */
     dsplan            = &g_dsplanfile, /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
     dsettemplate      = ,        /* Planned A&R dataset template name */
     sortorder         = ,        /* Planned A&R dataset sort order */
     formatnamesdset   = ,        /* Format names dataset name */
     noderivevars      = ,        /* List of variables not to derive */
     studyfollowup     = Y        /* Did study have follow up period? */
        );

 /*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion MacroName;
 %let MacroName = &sysmacroname;
 %let MacroVersion = 1;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals()

 /*
 / Define some local macro variables.
 /----------------------------------------------------------------------------*/

  %local prefix;
  %let prefix=%substr(&macroname,3);

  %local pv_abort;
  %let pv_abort = 0;

  %local demo_dsetin death_dsetin;
  %let demo_dsetin=DMDATA.DEMO;
  %let death_dsetin=DMDATA.DEATH;

 /*
 / Parameter Validation
 /----------------------------------------------------------------------------*/


 /*--PV01 - Check that required dataset DMDATA.DEMO exists */
 %tu_valparms(macroname = &macroname., chktype=dsetExists, pv_dsetin = demo_dsetin , abortyn = N);

 /*--PV02 - Check that required dataset DMDATA.DEATH exists */
 %tu_valparms(macroname = &macroname., chktype=dsetExists, pv_dsetin = death_dsetin , abortyn = N);

 /*--PV03 - STUDYFOLLOWUP: check for valid values Y or N */
 %tu_valparms(macroname = &macroname., chktype=isOneOf, pv_varsin = studyfollowup, valuelist = Y N, abortyn = N);

 /*
 / If the input dataset name is the same as the output dataset name,
 / write an error to the log.
 /----------------------------------------------------------------------------*/

 /*--PV04 - If the input dataset name is the same as the output dataset name,
 / write an error to the log. */
 %if &dsetin=&dsetout %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The input dataset name DSETIN(=&dsetin) is the same as the output dataset name DSETOUT(=&dsetout).;
    %let g_abort=1;
 %end;

 /*
 / Complete parameter validation.
 /----------------------------------------------------------------------------*/

 %if %eval(&g_abort. + &pv_abort.) gt 0
   %then
   %do;
     %put %str(RTE)RROR: &macroname: Macro has failed parameter validation check for reasons stated with %str(RTE)RRORs above;
     %tu_abort(option=force);
 %end;

 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/

 /*
 / If study does not have a follow-up period, obtain list of subjects from
 / DMDATA.DEMO and compare against those in DEATH. If no death, then set status
 / accordingly.
 /
 / If study does have a follow-up period, obtain list of subjects from
 / DMDATA.DEMO and DMDATA.DISPOSIT, and compare against DEATH. If no death then
 / check presence of record in DEPOSIT to see if follow-up ended.
 / If no DEATH record, but reason for study conclusion is DEATH (DSREASCD=25)
 / then code for death.
 */

 proc sort data=&dsetin out=&prefix._disposit;
   by studyid subjid;
 run;

 proc sort data=dmdata.demo out=&prefix._demo(keep=studyid subjid);
   by studyid subjid;
 run;

 proc sort data=dmdata.death out=&prefix._death(keep=studyid subjid);
   by studyid subjid;
 run;

 data &prefix._oncdisposit;
   merge &prefix._disposit(in=ds)
         &prefix._death(in=death)
         &prefix._demo(in=demo);
   by studyid subjid;

   length dthstcd $1;

   if death then dthstcd = '1';                             /* Subject died */

   %if &studyfollowup eq N %then
   %do;
      if demo and not death then dthstcd = '4';             /* No follow-up, and subject not reported dead */
   %end;
   %else %if &studyfollowup eq Y %then
   %do;
      if demo and ds and not death then dthstcd = '2';      /* Follow-up, with subject not reported dead and
                                                             follow-up ended, i.e. disposit record exists  */
      if demo and not ds and not death then dthstcd = '3';  /* Follow-up, with subject no reported dead and
                                                             follow-up ongoing, i.e. no disposit record    */
      if ds and not death and dsreascd='25' then do;
        dthstcd = ' ';
        put "RTW" "ARNING: &macroname: Subject exists in DISPOSIT but not DEATH and DSREASCD=25 /" SUBJID= ;
      end;
   %end;
 run;


 %tc_disposit (
      dsetin            = &prefix._oncdisposit
     ,dsetout           = &dsetout
     ,commonvarsyn      = &commonvarsyn
     ,treatvarsyn       = &treatvarsyn
     ,timeslicingyn     = &timeslicingyn
     ,datetimeyn        = &datetimeyn
     ,decodeyn          = &decodeyn
     ,derivationyn      = &derivationyn
     ,attributesyn      = &attributesyn
     ,misschkyn         = &misschkyn
     ,recalcvisityn     = &recalcvisityn
     ,xovarsforpgyn     = &xovarsforpgyn
     ,agemonthsyn       = &agemonthsyn
     ,ageweeksyn        = &ageweeksyn
     ,agedaysyn         = &agedaysyn
     ,refdat            = &refdat
     ,reftim            = &reftim
     ,refdateoption     = &refdateoption
     ,refdatevisitnum   = &refdatevisitnum
     ,refdatesourcedset = &refdatesourcedset
     ,refdatesourcevar  = &refdatesourcevar
     ,refdatedsetsubset = &refdatedsetsubset
     ,trtcdinf          = &trtcdinf
     ,ptrtcdinf         = &ptrtcdinf
     ,dsplan            = &dsplan
     ,dsettemplate      = &dsettemplate
     ,sortorder         = &sortorder
     ,formatnamesdset   = &formatnamesdset
     ,noderivevars      = &noderivevars);

 /*
 / Delete temporary datasets used in this macro.
 /----------------------------------------------------------------------------*/

 %tu_tidyup(rmdset=&prefix:, glbmac=NONE);
 %tu_abort;

%mend tc_onc_disposit;
