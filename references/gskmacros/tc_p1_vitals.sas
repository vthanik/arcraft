/****************************************************************************************************
|
| Macro Name:      tc_p1_vitals
|
| SAS Version:     9.1.3
|
| Created By:      Andy Miskell
|
| Date:            March 18, 2009
|
| Macro Purpose:   Create VITALS A&R data set for Phase 1 requirements
|                  (PG & XO studies)
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| ------------------------------------------------------------------
| ------------------------------------------------------------------
|                 FOR INPUT PARAMETERS, REFER TO
|                 DOCUMENTATION FOR TC_P1_VITALS
| ------------------------------------------------------------------
| ------------------------------------------------------------------
|
| Global macro variables created: NONE
|
| Macros called:
|(@) tc_vitals
|(@) tr_putlocals
|(@) tu_abort
|(@) tu_valparms
|(@) tu_putglobals
|(@) tu_p1_acttrt_PG
|(@) tu_p1_acttrt_XO
|(@) tu_p1_studyday
|(@) tu_times
|(@) tu_p1_periodday
|(@) tu_attrib
|(@) tu_misschk
|(@) tu_tidyup
|
|****************************************************************************************************
| Change Log 
|
| Modified By: 
| Date of Modification: 
| New Version/Build Number:
| Modification ID: 
| Reason For Modification: 
|
****************************************************************************************************/

%macro tc_p1_vitals(
     trt_dev_exists     = N,               /* Do Treatment Deviations exists for your study? */                                                                                                                                                  
     preprocess         = ,                /* Any processing required after reading in the input dataset */                                                                                                                                      
     postprocess        = ,                /* Any processing required before writing out to final output dataset */                                                                                                                              
     dsetin_vitals      = dmdata.vitals,   /* Input dataset name */
     dsetout            = ardata.vitals,   /* Output dataset name */     
     demodset           = dmdata.demo,     /* Name of DEMO dataset to use */        
     enroldset          = dmdata.enrol,    /* Name of ENROL dataset to use */       
     exposuredset       = dmdata.exposure, /* Name of EXPOSURE dataset to use */    
     investigdset       = dmdata.investig, /* Name of INVESTIG dataset to use */        
     racedset           = dmdata.race,     /* Name of RACE dataset to use */        
     randalldset        = dmdata.randall,  /* Name of RANDALL dataset to use */     
     randdset           = dmdata.rand,     /* Name of RAND dataset to use */        
     tmslicedset        = dmdata.tmslice,  /* Name of TMSLICE dataset to use */      
     visitdset          = dmdata.visit,    /* Name of VISIT dataset to use */       
     commonvarsyn       = Y,               /* Add common variables */
     timeslicingyn      = Y,               /* Add timeslicing variables */
     treatvarsyn        = Y,               /* Add treatment variables */
     datetimeyn         = Y,               /* Derive datetime variables */
     decodeyn           = Y,               /* Decode coded variables */
     derivationyn       = Y,               /* Dataset specific derivations */
     attributesyn       = Y,               /* Reconcile A&R dataset with planned A&R dataset */
     misschkyn          = Y,               /* Print warning message for variables in &DSETOUT with missing values on all records */ 
     xovarsforpgyn      = N,               /* If derive crossover stydy specific variables for parallel study */
     agemonthsyn        = N,               /* Calculation of age in months */
     ageweeksyn         = N,               /* Calculation of age in weeks */
     agedaysyn          = N,               /* Calculation of age in days */
     refdat             = vsdt,            /* Reference data variable name for calculating treatment period */
     reftim             = vsacttm,         /* Reference time variable name for calculating treatment period */
     refdateoption      = TREAT,           /* Reference date source option */
     refdatevisitnum    = ,                /* Reference date visit number */
     refdatesourcedset  = ,                /* Reference date source dataset */
     refdatesourcevar   = ,                /* Reference date source variable */
     refdatedsetsubset  = ,                /* WHERE clause applied to source dataset */
     dyrefdateoption    = ,                /* Reference date source option for the calculation of Study Day values in tu_derive Reference date source option for tu_derive.*/                                  
     dyrefdatedsetsubset= ,                /* WHERE clause applied to source dataset for tu_derive. */            
     dyrefdatesourcedset= ,                /* Reference date source dataset for tu_derive. */                                            
     dyrefdatesourcevar = ,                /* Reference date source variable for tu_derive. */                                           
     dyrefdatevisitnum  = ,                /* Specific visit number at which reference date is to be taken for tu_derive. */         
     trtcdinf           = ,                /* Informat to derive TRTCD from TRTGRP */
     ptrtcdinf          = ,                /* Informat to derive PTRTCD from PTRTGRP */
     dsplan             = &g_dsplanfile,   /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
     dsettemplate       = ,                /* Planned A&R dataset template name */
     sortorder          = ,                /* Planned A&R dataset sort order */
     decodepairs        = ,                /* code and decode variables in pair */
     formatnamesdset    = ,                /* Format names dataset name */
     noderivevars       =                  /* List of variables not to derive */
);

  /*
  / Echo parameter values and global macro variables to the log
  /----------------------------------------------------------------------------*/
  %local MacroVersion MacroName postprocessdset preprocessdset;
  %let MacroName=&sysmacroname.;
  %let MacroVersion=1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals();

  /*
  / Check for valid parameter values
  /   set up a macro variable to hold the pv_abort flag
  /----------------------------------------------------------------------------*/
  %local loopi listvars thisvar
         prefix pv_abort 
         exp_dset exp_varlist tslice_dset tslice_varlist abortyn;
  %let pv_abort = 0 ;


  %let prefix=_tc_p1_vitals;   /* Root name for temporary work datasets */


  /*
  / PARAMETER VALIDATION
  /----------------------------------------------------------------------------*/ 

  %let dsetin_vitals     = %nrbquote(&dsetin_vitals.);               
  %let dsetout           = %nrbquote(&dsetout.);
  %let preprocess        = %nrbquote(&preprocess.);
  %let postprocess       = %nrbquote(&postprocess.);
  %let treatvarsyn       = %nrbquote(%upcase(&treatvarsyn));
  %let attributesyn      = %nrbquote(%upcase(&attributesyn));
  %let misschkyn         = %nrbquote(%upcase(&misschkyn));

  /*
  / Check for required parameters.
  /----------------------------------------------------------------------------*/
  
  %let listvars=dsetin_vitals dsetout attributesyn misschkyn treatvarsyn;
 
  %do loopi=1 %to 5;
    %let thisvar=%scan(&listvars, &loopi, %str( ));
    %let &thisvar=%nrbquote(&&&thisvar);
    
    %if &&&thisvar eq %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: The parameter &thisvar cannot be blank.;
       %let pv_abort=1;
    %end;    
  %end;  /* end of do-to loop */

  /*
  / If the input dataset name is the same as the output dataset name,
  / write an error to the log.
  /----------------------------------------------------------------------------*/

  %if %qscan(&dsetin_vitals, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
  %do;
    %put %str(RTE)RROR: &sysmacroname: The input dataset name dsetin_vitals(=&dsetin_vitals) is the same as the output dataset name DSETOUT(=&dsetout).;
    %let pv_abort=1;
  %end;
 
  /*
  / Check for existing datasets and valid values
  /----------------------------------------------------------------------------*/

  %tu_valparms(
      macroname   =tc_p1_vitals,
      chktype     =dsetExists,
      pv_dsetin   =dsetin_vitals
     );

  %tu_valparms(
    macroname   = tc_p1_vitals,
    chktype     = isOneOf,
    pv_varsin   = treatvarsyn attributesyn misschkyn,
    valuelist   = Y N,
    abortyn     = N
   );

  %if %eval(&g_abort. + &pv_abort.) gt 0 %then %do;
    %put %str(RTE)RROR: &macroname: Macro has failed parameter validation check for reasons stated with %str(RTE)RRORs above;
    %tu_abort(option=force);
  %end;


  /*
  / NORMAL PROCESSING
  /----------------------------------------------------------------------------*/


  /*
  / Pre-processing of input dataset
  /   This step allows for the user to pre-process the input dataset in way of
  /   using simple SAS code.
  /   e.g. in the driver call, the user could include information such as
  /   preprocess = if 1 LE SUBJID LE 5 then studypart='A' else studypart = 'B' ;
  /----------------------------------------------------------------------------*/
  %let preprocessdset = &dsetin_vitals ;

  %if %nrbquote(&preprocess) ne %then %do;
    data &prefix._preprocess;
      set &dsetin_vitals ;
      %unquote(&preprocess);;
    run;
    %let preprocessdset = &prefix._preprocess;
  %end;

  /*
  / Call DAMA macro tc_vitals
  /----------------------------------------------------------------------------*/

  %tc_vitals(
dsetin             =&preprocessdset    ,
/* Input dataset name */
dsetout            =&prefix._vitals2   ,
/* Output dataset name */
demodset           =&demodset          ,
/* Name of DEMO dataset to use */
enroldset          =&enroldset         ,
/* Name of ENROL dataset to use */
exposuredset       =&exposuredset      ,
/* Name of EXPOSURE dataset to use */
investigdset       =&investigdset      ,
/* Name of INVESTIG dataset to use */
racedset           =&racedset          ,
/* Name of RACE dataset to use */
randalldset        =&randalldset       ,
/* Name of RANDALL dataset to use */
randdset           =&randdset          ,
/* Name of RAND dataset to use */
tmslicedset        =&tmslicedset       ,
/* Name of TMSLICE dataset to use */
visitdset          =&visitdset         ,
/* Name of VISIT dataset to use */
commonvarsyn       =&commonvarsyn      ,
/* Add common variables */
timeslicingyn      =&timeslicingyn     ,
/* Add timeslicing variables */
treatvarsyn        =&treatvarsyn       ,
/* Add treatment variables */
datetimeyn         =&datetimeyn        ,
/* Derive datetime variables */
decodeyn           =&decodeyn          ,
/* Decode coded variables */
derivationyn       =&derivationyn      ,
/* Dataset specific derivations */
attributesyn       =N,
/* Reconcile A&R dataset with planned A&R dataset */
misschkyn          =N,
/* Print warning message for variables in &DSETOUT with missing values on all records */
xovarsforpgyn      =&xovarsforpgyn     ,
/* If derive crossover stydy specific variables for parallel study */
agemonthsyn        =&agemonthsyn       ,
/* Calculation of age in months */
ageweeksyn         =&ageweeksyn        ,
/* Calculation of age in weeks */
agedaysyn          =&agedaysyn         ,
/* Calculation of age in days */
refdat             =&refdat            ,
/* Reference data variable name for calculating treatment period */
reftim             =&reftim            ,
/* Reference time variable name for calculating treatment period */
refdateoption      =&refdateoption     ,
/* Reference date source option */
refdatevisitnum    =&refdatevisitnum   ,
/* Reference date visit number */
refdatesourcedset  =&refdatesourcedset ,
/* Reference date source dataset */
refdatesourcevar   =&refdatesourcevar  ,
/* Reference date source variable */
refdatedsetsubset  =&refdatedsetsubset ,
/* WHERE clause applied to source dataset */
dyrefdateoption    =&dyrefdateoption    ,
/* Reference date source option for the calculation of Study Day values in tu_derive Reference date source option for tu_derive.*/
dyrefdatedsetsubset=&dyrefdatedsetsubset,
/* WHERE clause applied to source dataset for tu_derive. */
dyrefdatesourcedset=&dyrefdatesourcedset,
/* Reference date source dataset for tu_derive. */
dyrefdatesourcevar =&dyrefdatesourcevar ,
/* Reference date source variable for tu_derive. */
dyrefdatevisitnum  =&dyrefdatevisitnum,
/* Specific visit number at which reference date is to be taken for tu_derive. */
trtcdinf           =&trtcdinf         ,
/* Informat to derive TRTCD from TRTGRP */
ptrtcdinf          =&ptrtcdinf        ,
/* Informat to derive PTRTCD from PTRTGRP */
dsplan             =&dsplan           ,
/* Path and filename of tab-delimited file containing HARP A&R dataset plan */
dsettemplate       =&dsettemplate     ,
/* Planned A&R dataset template name */
sortorder          =&sortorder        ,
/* Planned A&R dataset sort order */
decodepairs        =&decodepairs      ,
/* code and decode variables in pair */
formatnamesdset    =&formatnamesdset  ,
/* Format names dataset name */
noderivevars       =&noderivevars               /* List of variables not to derive */

     );

  %let postprocessdset = &prefix._vitals2;

  /*
  / Call tu_p1_acttrt to add the correct Treatment and Actual Treatment
  /---------------------------------------------------------------------------*/

  %if &g_stype=PG and &treatvarsyn=Y %then %do;

    %tu_p1_acttrt_PG(dsetin  = &postprocessdset,
             dsetout         = &prefix._vitals3,
             trt_dev_exists  = &trt_dev_exists,
             exposuredset    = &exposuredset
             );

    %let postprocessdset = &prefix._vitals3;

  %end;
  %if &g_stype=XO and &treatvarsyn=Y %then %do;

    %tu_p1_acttrt_XO(dsetin  = &postprocessdset,
             dsetout         = &prefix._vitals3,
             trt_dev_exists  = &trt_dev_exists,
             exposuredset    = &exposuredset,
             tmslicedset     = &tmslicedset
             );

    %let postprocessdset = &prefix._vitals3;

  %end;

  /*
  / Call tu_p1_studyday to create the VSACTDY variable
  /---------------------------------------------------------------------------*/

  %tu_p1_studyday (dsetin   = &postprocessdset,
            dsetout         = &prefix._vitals4,
            refdate         = vsdt,
            varout          = vsactdy
              );

  %let postprocessdset = &prefix._vitals4;

  %if &g_stype=XO %then %do;
    /*
    / Call tu_p1_periodday to create the XPERDY variable
    /---------------------------------------------------------------------------*/

    %tu_p1_periodday (dsetin  = &postprocessdset,
              dsetout         = &prefix._vitals5,
              refdate         = vsdt,
              eventtype       = PL,
              varout          = xperdy
              );

    %let postprocessdset = &prefix._vitals5;

  %end;

  /*
  / Post-processing of input dataset
  /   This step allows for the user to post-process the dataset in way of
  /     using simple SAS code. This post-process step is invoked before
  /     calling of the tu_attrib and tu_misschk macros
  /   e.g. in the driver call, the user could include information such as
  /     postprocess = where studypart = 'B' ;
  /----------------------------------------------------------------------------*/
  %if %nrbquote(&postprocess) ne %then %do;
    data &prefix._postprocess;
      set &postprocessdset ;
      %unquote(&postprocess);;
    run;
    %let postprocessdset=&prefix._postprocess;
  %end;

  /*
  / Reconcile A&R dataset with planned A&R dataset.
  /----------------------------------------------------------------------------*/
  %if &attributesyn eq Y %then
  %do;
    %tu_attrib(dsetin     = &postprocessdset,
             dsetout      = &dsetout,
             dsplan       = &g_dsplanfile,
             dsettemplate = &dsettemplate, 
             sortorder    = &sortorder             
             );
  %end;
  %else %do;
    data &dsetout;
      set &postprocessdset;
    run;
  %end;

  /*
  / Call tu_misschk macro in order to identify any variables in the output
  / dataset which have missing values on all records.
  /----------------------------------------------------------------------------*/
  %if &misschkyn eq Y %then %do;
    %tu_misschk(
         dsetin        = &dsetout
         );
  %end;

  /*
  / Delete temporary datasets used in this macro.
  /----------------------------------------------------------------------------*/

  %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tc_p1_vitals;
