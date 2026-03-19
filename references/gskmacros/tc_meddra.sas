/*******************************************************************************
|
| Macro Name:      tc_meddra
|
| Macro Version:   2
|
| SAS Version:     8.2
|
| Created By:      Eric Simms
|
| Date:            26-Jun-2004
|
| Macro Purpose:   Meddra wrapper macro
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                            REQ/OPT  DEFAULT
| -----------------  -------------------------------------  -------  ----------
| AEDSET             Specifies the AE-format SI dataset     OPT      DMDATA.AE
|                    which contains the AELLTCD values 
|                    which will be used to extract those 
|                    MedDRA records of interest to this 
|                    study.
|                    Valid values: valid dataset name.
|                    NOTE: If the AE SI dataset does not
|                          exist, the default will need to
|                          be over-written with a blank,
|                          i.e. specify AEDSET=.
|
| MEDHISTDSET        Specifies the MEDHIST-format SI        OPT      DMDATA.MEDHIST
|                    dataset which contains the MHLLTCD 
|                    values which will be used to extract 
|                    those MedDRA records of interest to 
|                    this study.
|                    Valid values: valid dataset name.
|                    NOTE: If the MEDHIST SI dataset does not
|                          exist, the default will need to
|                          be over-written with a blank,
|                          i.e. specify MEDHISTDSET=.
|
| SURGERYDSET        Specifies the SURGERY-format SI        OPT      DMDATA.SURGERY
|                    dataset which contains the SPLLTCD 
|                    values which will be used to extract 
|                    those MedDRA records of interest to 
|                    this study.
|                    Valid values: valid dataset name.
|                    NOTE: If the SURGERY SI dataset does not
|                          exist, the default will need to
|                          be over-written with a blank,
|                          i.e. specify SURGERYDSET=.
|
| MEDDRADSET         Specifies the MedDRA dictionary SAS    REQ      DICTION.MEDDRA
|                    dataset.
|                    Valid values: valid dataset name 
|
| DSETOUT            Specifies the name of the output       REQ      ARDATA.MEDDRA
|                    dataset to be created.          
|                    Valid values: valid dataset name
|
| DERIVATIONYN       Call %tu_derive to perform specific    REQ      Y
|                    derivations for this domain code (AE)?
|                    Valid values: Y, N
|
| ATTRIBUTESYN       Call %tu_attrib to reconcile the       REQ      Y
|                    A&R-defined attributes to the planned 
|                    A&R dataset?
|                    Valid values: Y, N
|
| MISSCHKYN          Call %tu_misschk to print RTWARNING    REQ      Y
|                    messages for each variable in 
|                    &DSETOUT which has missing values
|                    on all records.                    
|                    Valid values: Y, N.  
|
| DSPLAN             Specifies the path and file name of    OPT      &g_dsplanfile 
|                    the HARP A&R dataset metadata. This 
|                    will define the attributes to use to 
|                    define the A&R dataset.
|                    NOTE: If DSPLAN is not specified
|                          i.e. left to its default value,
|                          or is specified as anything 
|                          other than blank, then 
|                          DSETTEMPLATE and SORTORDER 
|                          must not be specified as anything 
|                          non-blank. If DSETTEMPLATE and
|                          SORTORDER are specified as anything
|                          non-blank, then DSPLAN must be 
|                          specified as blank (DSPLAN=,).
|
| DSETTEMPLATE       Specifies the name to give to the      OPT      (Blank)
|                    empty dataset containing the variables 
|                    and attributes desired for the A&R 
|                    dataset.
|                    NOTE: If DSETTEMPLATE is specified
|                          as anything non-blank, then 
|                          DSPLAN must be specified as
|                          blank (DSPLAN=,).
|
| SORTORDER          Specifies the sort order desired for   OPT      (Blank)
|                    the A&R dataset.
|                    NOTE: If SORTORDER is specified
|                          as anything non-blank, then 
|                          DSPLAN must be specified as
|                          blank (DSPLAN=,).
|
| NODERIVEVARS       List of domain-specific variables not  OPT      (Blank)
|                    to derive when %tu_derive is called.
| -----------------  -------------------------------------  -------  ----------
|
| The macro references the following datasets :-
| ------------------  -------  ------------------------------------------------
| Name                Req/Opt  Description
| ------------------  -------  ------------------------------------------------
| &AEDSET             Opt      Parameter specified dataset
| &MEDHISTDSET        Opt      Parameter specified dataset
| &SURGERYDSET        Opt      Parameter specified dataset
| &DSETTEMPLATE       Opt      Parameter specified dataset
|
| ------------------  -------  ------------------------------------------------
|
| Output:
|
| The macro outputs the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETOUT           Req      Parameter specified dataset
| -----------------  -------  -------------------------------------------------
|
| Global macro variables created: NONE
|
|
| Macros called:
|(@) tr_putlocals
|(@) tu_abort
|(@) tu_attrib
|(@) tu_chkvarsexist
|(@) tu_derive
|(@) tu_putglobals
|(@) tu_misschk
|(@) tu_nobs
|(@) tu_tidyup
|
| Example:
|    %tc_meddra(
|         dsplan          = &g_dsplanfile
|         );
|
|******************************************************************************
| Change Log
|
| Modified By:              Yongwei Wang
| Date of Modification:     31-Mar-2005
| New version/draft number: 1/2
| Modification ID:          YW001
| Reason For Modification:  Removed FORMATNAMESDSET
|
|*******************************************************************************|
| Modified By:              Yongwei Wang
| Date of Modification:     17-Sep-07
| New version/draft number: 2/1
| Modification ID:          YW002
| Reason For Modification:  Based on change request HRT0184 and HRT0172:
|                           1. Added call of %tu_nobs to check if data set exist
|*******************************************************************************
| Modified By:           
| Date of Modification:   
| New version/draft number:
| Modification ID:          
| Reason For Modification: 
|
*******************************************************************************/
%macro tc_meddra (
     aedset            = DMDATA.AE,      /* AE dataset name */
     medhistdset       = DMDATA.MEDHIST, /* MEDHIST dataset name */
     surgerydset       = DMDATA.SURGERY, /* SURGERY dataset name */
     meddradset        = DICTION.MEDDRA, /* MEDDRA dataset name */
     dsetout           = ARDATA.MEDDRA,  /* Output dataset name */
     
     derivationyn      = Y,              /* Dataset specific derivations */
     attributesyn      = Y,              /* Reconcile A&R dataset with planned A&R dataset */
     misschkyn         = Y,              /* Print warning message for variables in &DSETOUT with missing values on all records */
     dsplan            = &g_dsplanfile,  /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
     dsettemplate      = ,               /* Planned A&R dataset template name */
     sortorder         = ,               /* Planned A&R dataset sort order */
     noderivevars      =                 /* List of variables not to derive */
        );

 /*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion;
 %let MacroVersion = 2;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals() 

 /*
 / PARAMETER VALIDATION
 /----------------------------------------------------------------------------*/

 %let aedset            = %nrbquote(&aedset);
 %let meddradset       = %nrbquote(&meddradset);
 %let medhistdset       = %nrbquote(&medhistdset);
 %let surgerydset       = %nrbquote(&surgerydset);
 %let dsetout           = %nrbquote(&dsetout);

 %let derivationyn      = %nrbquote(%upcase(%substr(&derivationyn, 1, 1)));
 %let attributesyn      = %nrbquote(%upcase(%substr(&attributesyn, 1, 1)));
 %let misschkyn         = %nrbquote(%upcase(%substr(&misschkyn, 1, 1)));

 /*
 / Check for required parameters.
 /----------------------------------------------------------------------------*/

 %if &aedset eq %then
 %do;
    %put %str(RTN)OTE: &sysmacroname: The parameter AEDSET is blank.;
 %end;

 %if &medhistdset eq %then
 %do;
    %put %str(RTN)OTE: &sysmacroname: The parameter MEDHISTDSET is blank.;
 %end;

 %if &surgerydset eq %then
 %do;
    %put %str(RTN)OTE: &sysmacroname: The parameter SURGERYDSET is blank.;
 %end;

 %if &aedset eq  and &medhistdset eq  and &surgerydset eq  %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameters AEDSET, MEDHISTDSET, SURGERYDSET are all blank.;
    %let g_abort=1;
 %end;

 %if &meddradset eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter MEDDRADSET is required.;
    %let g_abort=1;
 %end;

 %if &dsetout eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter DSETOUT is required.;
    %let g_abort=1;
 %end;

 %if &derivationyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter DERIVATIONYN is required.;
    %let g_abort=1;
 %end;

 %if &attributesyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter ATTRIBUTESYN is required.;
    %let g_abort=1;
 %end;
 
 %if &misschkyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter MISSCHKYN is required.;
    %let g_abort=1;
 %end;

 /*
 / Check for valid parameter values.
 /----------------------------------------------------------------------------*/

 %if &derivationyn ne Y and &derivationyn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: DERIVATIONYN should be either Y or N.;
    %let g_abort=1;
 %end;

 %if &attributesyn ne Y and &attributesyn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: ATTRIBUTESYN should be either Y or N.;
    %let g_abort=1;
 %end;
 
 %if &misschkyn ne Y and &misschkyn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: MISSCHKYN should be either Y or N.;
    %let g_abort=1;
 %end; 

 /*
 / If one of the input dataset names is the same as the output dataset name,
 / write an error to the log.
 /----------------------------------------------------------------------------*/

 %if %qscan(&aedset, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The ae dataset name AEDSET(=&aedset) is the same as the output dataset name DSETOUT(=&dsetout).;
    %let g_abort=1;
 %end;

 %if %qscan(&medhistdset, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The medhist dataset name MEDHISTDSET(=&medhistdset) is the same as the output dataset name DSETOUT(=&dsetout).;
    %let g_abort=1;
 %end;

 %if %qscan(&surgerydset, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The surgery dataset name SURGERYDSET(=&surgerydset) is the same as the output dataset name DSETOUT(=&dsetout).;
    %let g_abort=1;
 %end;

 %if %qscan(&meddradset, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The meddra dataset name MEDDRADSET(=&meddradset) is the same as the output dataset name DSETOUT(=&dsetout).;
    %let g_abort=1;
 %end;
 
 /*
 / Check for existance of input data set.
 /----------------------------------------------------------------------------*/

 %if &aedset ne  %then
    %if %tu_nobs(&aedset) lt 0 %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: Data set AEDSET(=&aedset) does not exist.;
       %let g_abort=1;
    %end;

 %if &medhistdset ne %then
    %if %tu_nobs(&medhistdset) lt 0 %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: Data set MEDHISTDSET(=&medhistdset) does not exist.;
       %let g_abort=1;
    %end;

 %if &surgerydset ne  %then
    %if %tu_nobs(&surgerydset) eq 0 %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: Data set SURGERYDSET(=&surgerydset) does not exist.;
       %let g_abort=1;
    %end;

 %if &meddradset ne %then                  
    %if %tu_nobs(&meddradset) eq 0 %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: Data set MEDDRADSET(=&meddradset) does not exist.;
       %let g_abort=1;
    %end;

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;

 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/

 %local prefix;
 %let prefix = _tc_meddra;   /* Root name for temporary work datasets */

 /*
 / Initialise counter for appending to temporary dataset names for the
 / purpose of tracking datasets through a number of optional sequential
 / data processing steps.
 /----------------------------------------------------------------------------*/

 %local i;
 %let i = 1;

 /*
 / For all of the AELLTCD codes found in the AE dataset, MHLLTCD codes found
 / in the MEDHIST dataset, SPLLTCD codes found in the SURGERY dataset, get the 
 / corresponding records from the MedDRA dictionary.
 /----------------------------------------------------------------------------*/

 %local ae_records;
 %local medhist_records;
 %local surgery_records;

 %if &aedset ne  %then
 %do;
     data &prefix._ae;
        set %unquote(&aedset);
     run;
     
     %if %tu_chkvarsexist(&prefix._ae, aelltcd) eq  %then
     %do;
         %let ae_records = &prefix._ae;

         data &prefix._ae;
           set &prefix._ae(keep=aelltcd studyid);
           if aelltcd ne .;
         run;
     %end;
     %else
     %do;
        %put %str(RTN)OTE: &sysmacroname: The AE dataset (&aedset) does not contain the AELLTCD variable.;
        %put %str(RTN)OTE: &sysmacroname: Records not extracted from the MEDDRA dataset (&meddradset) for AE.;
     %end;
 %end;

 %if &medhistdset ne  %then
 %do;
     data &prefix.medhis;
        set %unquote(&medhistdset);
     run;
      
     %if %tu_chkvarsexist(&prefix.medhis, mhlltcd) eq  %then
     %do;
         %let medhist_records = &prefix._medhist;

         data &prefix._medhist(rename=(mhlltcd=aelltcd));
           set &prefix.medhis(keep=mhlltcd studyid);
           if mhlltcd ne .;
         run;
     %end;
     %else
     %do;
        %put %str(RTN)OTE: &sysmacroname: The MEDHIST dataset (&medhistdset) does not contain the MHLLTCD variable.;
        %put %str(RTN)OTE: &sysmacroname: Records not extracted from the MEDDRA dataset (&meddradset) for MEDHIST.;
     %end;
 %end;

 %if &surgerydset ne  %then
 %do;
     data &prefix.surgery;
        set %unquote(&surgerydset);
     run;
     
     %if %tu_chkvarsexist(&prefix.surgery, splltcd) eq  %then
     %do;
         %let surgery_records = &prefix._surgery;

         data &prefix._surgery(rename=(splltcd=aelltcd));
           set &prefix.surgery(keep=splltcd studyid);
           if splltcd ne .;
         run;
     %end;
     %else
     %do;
        %put %str(RTN)OTE: &sysmacroname: The SURGERY dataset (&surgerydset) does not contain the SPLLTCD variable.;
        %put %str(RTN)OTE: &sysmacroname: Records not extracted from the MEDDRA dataset (&meddradset) for SURGERY.;
     %end;
 %end;

 %if &ae_records eq  and &medhist_records eq  and &surgery_records eq  %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: No records found in any of the named datasets (&aedset &medhistdset &surgerydset);
    %put %str(RTE)RROR: &sysmacroname: to extract related records from MEDDRA.;
    %let g_abort=1;
    %tu_abort;
 %end;

 %local studyid;

 data &prefix._allrecs;
   set &ae_records &medhist_records &surgery_records;
      if _n_=1 then call symput('studyid',trim(studyid));
 run;

 proc sql noprint;
      create table &prefix._ds&i as
      select *
      from %unquote(&meddradset)
      where aelltcd in (select distinct aelltcd from &prefix._allrecs)
      and   aepathcd = '1'
      and   aenc = 'C';
 quit;

 data &prefix._ds%eval(&i+1);
      set &prefix._ds&i(rename=(aemagcd = _magcd));

      studyid="&studyid";

      aemagcd = input(_magcd, 8.);
      drop _magcd;
 run;

 %let i = %eval(&i + 1);
 
 /*
 / Dataset specific derivations.
 /----------------------------------------------------------------------------*/

 %if &derivationyn eq Y %then
 %do;
    %tu_derive (
         dsetin            = &prefix._ds&i,
         dsetout           = &prefix._ds%eval(&i+1),
         domaincode        = md,                     /* Domain Code - type of dataset */
         noderivevars      = &noderivevars           /* List of variables not to derive */
    );

    %let i = %eval(&i + 1);
 %end;

 /*
 / Reconcile A&R dataset with planned A&R dataset.
 /----------------------------------------------------------------------------*/

 %if &attributesyn eq Y %then
 %do;
    %tu_attrib(
         dsetin          = &prefix._ds&i,
         dsetout         = &dsetout,
         dsplan          = &dsplan,
         dsettemplate    = &dsettemplate,
         sortorder       = &sortorder
    );
 %end;
 %else
 %do;
    data %unquote(&dsetout);
         set &prefix._ds&i;
    run;
 %end;
 
 /*
 / Call tu_misschk macro in order to identify any variables in the 
 / &DSETOUT dataset which have missing values on all records.
 /----------------------------------------------------------------------------*/

 %if &misschkyn eq Y %then
 %do;
    %tu_misschk(
         dsetin        = &dsetout
    );
 %end;

 /*
 / Delete temporary datasets used in this macro.
 /----------------------------------------------------------------------------*/

 %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tc_meddra;
