/****************************************************************************************************
|
| Macro Name:      tc_p1_genpro
|
| SAS Version:     9.1
|
| Created By:      Suzanne Johnes
|
| Date:            21 May 2008
|
| Macro Purpose:   Create GENPRO A&R data set for Phase1 requirements
|                  (PG & XO studies)
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| ------------------------------------------------------------------
| ------------------------------------------------------------------
|                 FOR INPUT PARAMETERS, REFER TO
|                 DOCUMENTATION FOR TC_P1_GENPRO
| ------------------------------------------------------------------
| ------------------------------------------------------------------
|
| Global macro variables created: NONE
|
| Macros called:
|(@) tu_putglobals
|(@) tr_putlocals
|(@) tu_abort
|(@) tc_genpro
|(@) tu_attrib
|(@) tu_misschk
|(@) tu_p1_acttrt_pg
|(@) tu_rantrt
|(@) tu_tidyup
|(@) tu_valparms
|
|****************************************************************************************************
| Change Log
|
| Modified By:              Khilit Shah (kys41925)
| Date of Modification:     14-Oct-2008
| New version/draft number: 2
| Modification ID:          n/a
| Reason For Modification:  Changes 1-3 are based on the updated to TC_GENPRO macro
|                             and require P1 macro to surface these parameters
|                           1. Added data set parameters, which will be passed 
|                              to new version of TU macros: demodset, enroldset,
|                              exposuredset, investigdset, racedset, randalldset, 
|                              randdset, tmslicedset, visitdset       
|                           2. Added 5 new DYREF* parameters, which will be passed 
|                              %tu_derive REF* parameters: dyrefdateoption, 
|                              dyrefdatedsetsubset, dyrefdatesourcedset
|                              dyrefdatesourcevar, dyrefdatevisitnum  
|                           3. Added parameter DECODEPAIRS, which will be 
|                              passed to %tu_decode
|                           4  Change &treatvarsyn in TC_ call to 'N' as this 
|                              parameter shall be referenced further on during 
|                              the call to tu_rantrt
|                           5  Included EXPOSUREDSET to be passed 
|                               on as macro parameters to TU_P1_ACTTRT
|                           6  Included valid value check for 
|                               treatvarsyn attributes misschkyn trt_dev_exists
|
|*******************************************************************************
| Modified By:              
| Date of Modification:     
| New version/draft number: 
| Modification ID:          
| Reason For Modification:  
|
*******************************************************************************/

%macro tc_p1_genpro (
   trt_dev_exists    = N,             /* Do Treatment Deviations exists for your study? */
   dsetin_genpro     = dmdata.genpro, /* Input dataset name */
   dsetout           = ardata.genpro, /* Output dataset name */
   preprocess        = ,              /* Any processing required after reading in the input dataset */
   postprocess       = ,              /* Any processing required before writing out to final output dataset */
   demodset          = dmdata.demo,     /* Name of DEMO dataset to use */        
   enroldset         = dmdata.enrol,    /* Name of ENROL dataset to use */       
   exposuredset      = dmdata.exposure, /* Name of EXPOSURE dataset to use */    
   investigdset      = dmdata.investig, /* Name of INVESTIG dataset to use */        
   racedset          = dmdata.race,     /* Name of RACE dataset to use */        
   randalldset       = dmdata.randall,  /* Name of RANDALL dataset to use */     
   randdset          = dmdata.rand,     /* Name of RAND dataset to use */        
   tmslicedset       = dmdata.tmslice,  /* Name of TMSLICE dataset to use */      
   visitdset         = dmdata.visit,    /* Name of VISIT dataset to use */       
   commonvarsyn      = Y,             /* Add common variables */
   treatvarsyn       = Y,             /* Add treatment variables */
   timeslicingyn     = N,             /* Add timeslicing variables */
   datetimeyn        = Y,             /* Derive datetime variables */
   decodeyn          = Y,             /* Decode coded variables */
   derivationyn      = Y,             /* Dataset specific derivations */
   attributesyn      = Y,             /* Reconcile A&R dataset with planned A&R dataset */
   misschkyn         = Y,             /* Print warning message for variables in &DSETOUT with missing values on all records */
   agemonthsyn       = N,             /* Calculation of age in months */
   ageweeksyn        = N,             /* Calculation of age in weeks */
   agedaysyn         = N,             /* Calculation of age in days */
   refdateoption     = TREAT,         /* Reference date source option */
   refdatevisitnum   = ,              /* Reference date visit number */
   refdatesourcedset = ,              /* Reference date source dataset */
   refdatesourcevar  = ,              /* Reference date source variable */
   refdatedsetsubset = ,              /* Where clause applied to source dataset */
   dyrefdateoption    = ,             /* Reference date source option for the calculation of Study Day values in tu_derive Reference date source option for tu_derive.*/                                  
   dyrefdatedsetsubset= ,             /* WHERE clause applied to source dataset for tu_derive. */            
   dyrefdatesourcedset= ,             /* Reference date source dataset for tu_derive. */                                            
   dyrefdatesourcevar = ,             /* Reference date source variable for tu_derive. */                                           
   dyrefdatevisitnum  = ,             /* Specific visit number at which reference date is to be taken for tu_derive. */         
   trtcdinf          = ,              /* Informat to derive TRTCD from TRTGRP */
   ptrtcdinf         = ,              /* Informat to derive PTRTCD from PTRTGRP */
   dsplan            = &g_dsplanfile, /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
   dsettemplate      = ,              /* Planned A&R dataset template name */
   sortorder         = ,              /* Planned A&R dataset sort order */
   decodepairs       = ,              /* code and decode variables in pair */
   formatnamesdset   = ,              /* Format names dataset name */
   noderivevars      =                /* List of variables not to derive */
   );

   /*
   / Echo parameter values and global macro variables to the log
   /----------------------------------------------------------------------------*/
   %local MacroVersion macroname;
   %let MacroName=&sysmacroname.;
   %let MacroVersion=2;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals();

   /*
   / Parameter validation
   /----------------------------------------------------------------------------*/
   %let dsetin_genpro     = %nrbquote(&dsetin_genpro.);               
   %let dsetout           = %nrbquote(&dsetout.);
   %let preprocess        = %nrbquote(&preprocess.);
   %let postprocess       = %nrbquote(&postprocess.);
   %let trt_dev_exists    = %nrbquote(%upcase(&trt_dev_exists));

  %let treatvarsyn         = %nrbquote(%upcase(&treatvarsyn));
  %let attributesyn        = %nrbquote(%upcase(&attributesyn));
  %let misschkyn           = %nrbquote(%upcase(&misschkyn));

   /* Check for valid parameter values
   /  set up a macro variable to hold the pv_abort flag
   /----------------------------------------------------------------------------*/
   %local pv_abort prefix preprocessdset postprocessdset ;
   %let pv_abort = 0 ;
   %let prefix = _tc_p1_genpro;   /* Root name for temporary work datasets */


  /*
  / Check for required parameters.
  /----------------------------------------------------------------------------*/
  
  %let listvars=DSETIN_GENPRO DSETOUT ;

  %do loopi=1 %to 2;
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
  %if %qscan(&dsetin_genpro, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
  %do;
    %put %str(RTE)RROR: &sysmacroname: The input dataset name DSETIN(=&dsetin_genpro) is the same as output data set name DSETOUT(=&dsetout).;
    %let pv_abort=1;
  %end;


  /*
  / Validation of dataset
  /----------------------------------------------------------------------------*/
  * DMDATA.GENPRO exists? ;
  %if not %sysfunc(exist(&dsetin_genpro)) %then 
  %do;
    %put RTE%str(RROR): &sysmacroname.: DSETIN_GENPRO(=&dsetin_genpro) does not exist;
    %let pv_abort = 1;
  %end;


  /* valid values check for : trt_dev_exists treatvarsyn attributesyn misschkyn  */
  %tu_valparms(
    macroname=&macroname., 
    chktype=isOneOf, 
    pv_varsin= trt_dev_exists treatvarsyn attributesyn misschkyn,      
    valuelist = Y N, 
    abortyn = N
    );


  /*
  / Complete validation
  /----------------------------------------------------------------------------*/
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
  %let preprocessdset = &dsetin_genpro ;

  %if %nrbquote(&preprocess) ne %then %do;
     data &prefix._preprocess;
        set &dsetin_genpro;
        %unquote(&preprocess);;
     run;
     %let preprocessdset = &prefix._preprocess;
  %end;

  /*
  / Call DAMA macro tc_genpro
  /----------------------------------------------------------------------------*/
  %tc_genpro (
     dsetin            = &preprocessdset,    /* Input dataset name */
     dsetout           = &prefix._genpro1,   /* Output dataset name */
     demodset          = &demodset,          /* Name of DEMO dataset to use */        
     enroldset         = &enroldset,         /* Name of ENROL dataset to use */       
     exposuredset      = &exposuredset,      /* Name of EXPOSURE dataset to use */    
     investigdset      = &investigdset,      /* Name of INVESTIG dataset to use */        
     racedset          = &racedset,          /* Name of RACE dataset to use */        
     randalldset       = &randalldset,       /* Name of RANDALL dataset to use */     
     randdset          = &randdset,          /* Name of RAND dataset to use */        
     tmslicedset       = &tmslicedset,       /* Name of TMSLICE dataset to use */      
     visitdset         = &visitdset,         /* Name of VISIT dataset to use */       
     commonvarsyn      = &commonvarsyn,      /* Add common variables */
     treatvarsyn       = N,                  /* Add treatment variables */
     timeslicingyn     = &timeslicingyn,     /* Add timeslicing variables */
     datetimeyn        = &datetimeyn,        /* Derive datetime variables */
     decodeyn          = &decodeyn           /* Decode coded variables */
     derivationyn      = &derivationyn,      /* Dataset specific derivations */
     attributesyn      = N,                  /* Reconcile A&R dataset with planned A&R dataset */
     misschkyn         = N,                  /* Print warning message for variables in &DSETOUT with missing values on all records */
     agemonthsyn       = &agemonthsyn,       /* Calculation of age in months */
     ageweeksyn        = &ageweeksyn,        /* Calculation of age in weeks */
     agedaysyn         = &agedaysyn,         /* Calculation of age in days */
     refdateoption     = &refdateoption,     /* Reference date source option */
     refdatevisitnum   = &refdatevisitnum,   /* Reference date visit number */
     refdatesourcedset = &refdatesourcedset, /* Reference date source dataset */
     refdatesourcevar  = &refdatesourcevar,  /* Reference date source variable */
     refdatedsetsubset = &refdatedsetsubset, /* Where clause applied to source dataset */
     dyrefdateoption    = &dyrefdateoption,     /* Reference date source option for the calculation of Study Day values in tu_derive Reference date source option for tu_derive.*/                                  
     dyrefdatedsetsubset= &dyrefdatedsetsubset, /* WHERE clause applied to source dataset for tu_derive. */            
     dyrefdatesourcedset= &dyrefdatesourcedset, /* Reference date source dataset for tu_derive. */                                            
     dyrefdatesourcevar = &dyrefdatesourcevar,  /* Reference date source variable for tu_derive. */                                           
     dyrefdatevisitnum  = &dyrefdatevisitnum,   /* Specific visit number at which reference date is to be taken for tu_derive. */         
     trtcdinf          = &trtcdinf,          /* Informat to derive TRTCD from TRTGRP */
     ptrtcdinf         = &ptrtcdinf,         /* Informat to derive PTRTCD from PTRTGRP */
     dsplan            = &dsplan,            /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
     dsettemplate      = &dsettemplate ,     /* Planned A&R dataset template name */
     sortorder         = &sortorder,         /* Planned A&R dataset sort order */
     decodepairs       = &decodepairs,       /* code and decode variables in pair */
     formatnamesdset   = &formatnamesdset,   /* Format names dataset name */
     noderivevars      = &noderivevars       /* List of variables not to derive */
     );

  * Set a temporary macro variable containing dataset reference ;
  %let postprocessdset = &prefix._genpro1;

  /*
  / Treatment.assignment
  /----------------------------------------------------------------------------*/
  %if &treatvarsyn eq Y %then
  %do;

    /*
    / Add treatment variables to dataset
    /---------------------------------------------------------------------------*/
    %tu_rantrt ( dsetin      = &prefix._genpro1 /* Input dataset name */
                ,dsetout     = &prefix._genpro2 /* Output dataset name */
                ,ptrtcdinf   = &ptrtcdinf       /* Informat to derive PTRTCD from PTRTGRP */
                ,randalldset = &randalldset     /* RANDALL data set name */
                ,randdset    = &randdset        /* RAND data set name */
                ,trtcdinf    = &trtcdinf        /* Informat to derive TRTCD from TRTGRP */
               );

      /*
      / Call tu_p1_acttrt to cater for any treatment deviations
      /---------------------------------------------------------------------------*/
      %tu_p1_acttrt_pg ( dsetin         = &prefix._genpro2  /* Name of input dataset */
                        ,dsetout        = &prefix._genpro3  /* Name of output dataset */
                        ,trt_dev_exists = &trt_dev_exists   /* Do treatment deviations exist in your study? */
                        ,exposuredset   = &exposuredset     /* Name of EXPOSURE dataset to use */
                        );

      * Set a temporary macro variable containing dataset reference ;
      %let postprocessdset = &prefix._genpro3;
  
  %end; /*EndOf if treatvarsyn = Y */
 
  /*
  / Post-processing of input dataset
  /   This step allows for the user to post-process the dataset in way of
  /     using simple SAS code. This post-process step is invoked before
  /     calling of the tu_attrib and tu_misschk macros
  /   e.g. in the driver call, the user could include information such as
  /     postprocess = where studypart = 'B' ;
  /----------------------------------------------------------------------------*/
  %if %nrbquote(&postprocess) ne %then 
  %do;
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
    %tu_attrib( dsetin        =&postprocessdset
               ,dsetout       =&dsetout
               ,dsplan        =&g_dsplanfile
               ,dsettemplate  =&dsettemplate
               ,sortorder     =&sortorder
               );
  %end;
  %else
  %do;
    data &dsetout;
         set &postprocessdset;
    run;
 %end;

  /*
  / Call tu_misschk macro in order to identify any variables in the output
  / dataset which have missing values on all records.
  /----------------------------------------------------------------------------*/
  %if &misschkyn eq Y %then
  %do;
    %tu_misschk(dsetin = &dsetout);
  %end;

  /*
  / Delete temporary datasets used in this macro.
  /----------------------------------------------------------------------------*/
  %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tc_p1_genpro;
