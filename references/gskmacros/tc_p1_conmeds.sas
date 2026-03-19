/*******************************************************************************
|
| Macro Name:      tc_p1_conmeds
|
| SAS Version:     9.1
|
| Created By:      Suzanne Johnes
|
| Date:            9th May 2008
|
| Macro Purpose:   Create A&R CONMEDS dataset (ARDATA.CONMEDS)
|                  (PG & XO studies)
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| ------------------------------------------------------------------
| ------------------------------------------------------------------
|                 FOR INPUT PARAMETERS, REFER TO
|                 DOCUMENTATION FOR TC_P1_CONMEDS
| ------------------------------------------------------------------
| ------------------------------------------------------------------
|
| Global macro variables created: NONE
|
| Macros called:
|(@) tr_putlocals
|(@) tu_putglobals
|(@) tu_abort
|(@) tc_conmeds
|(@) tu_p1_calctpernum
|(@) tu_calctpernum
|(@) tu_rantrt
|(@) tu_p1_periodday 
|(@) tu_p1_acttrt_pg
|(@) tu_p1_acttrt_xo
|(@) tu_attrib
|(@) tu_misschk
|(@) tu_tidyup
|(@) tu_valparms
|
|******************************************************************************
| Change Log
|
| Modified By:              Khilit Shah (kys41925)
| Date of Modification:     14-Oct-2008
| New version/draft number: 2
| Modification ID:          n/a
| Reason For Modification:  Changes 1-3 are based on the updated to TC_CONMEDS macro
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
|                           5  Within code of setting ATRTGRP=TPATRTGP, include setting 
|                              of PERIOD = TPERIOD as this does not occur with TU_RANTRT
|                           6  Included EXPOSUREDSET and TMSLICEDSET to be passed 
|                               on as macro parameters to TU_P1_ACTTRT and TU_P1_PERIODDAY
|                           7  Included valid value check for 
|                               treatvarsyn attributes misschkyn xovarsforpgyn
|
|*******************************************************************************
| Modified By:
| Date of Modification:
| New version/draft number:
| Modification ID:
| Reason For Modification:
|
*******************************************************************************/

%macro tc_p1_conmeds (
     trt_dev_exists      = N ,                  /* Do Treatment Deviations exists for your study? */
     dsetin_conmeds      = DMDATA.CONMEDS,      /* Input  dataset name */
     dsetout             = ARDATA.CONMEDS,      /* Output dataset name */
     preprocess          = ,                    /* Any processing required after reading in the input dataset */
     postprocess         = ,                    /* Any processing required before writing out to final output dataset */
     prohibitmed_subset  = ,                    /* User supplied code to flag prohibited medications */
     calctpernum_version = TU_P1_CALCTPERNUM,   /* If yes, then call TU_P1_CALCTPERNUM else call TU_CALCTPERNUM to assign treatment */
     demodset          = dmdata.demo,     /* Name of DEMO dataset to use */        
     enroldset         = dmdata.enrol,    /* Name of ENROL dataset to use */       
     exposuredset      = dmdata.exposure, /* Name of EXPOSURE dataset to use */    
     investigdset      = dmdata.investig, /* Name of INVESTIG dataset to use */        
     racedset          = dmdata.race,     /* Name of RACE dataset to use */        
     randalldset       = dmdata.randall,  /* Name of RANDALL dataset to use */     
     randdset          = dmdata.rand,     /* Name of RAND dataset to use */        
     tmslicedset       = dmdata.tmslice,  /* Name of TMSLICE dataset to use */      
     visitdset         = dmdata.visit,    /* Name of VISIT dataset to use */       
     commonvarsyn      = Y,       /* Add common variables */
     treatvarsyn       = Y,       /* Add treatment variables */
     datetimeyn        = Y,       /* Derive datetime variables */
     decodeyn          = Y,       /* Decode coded variables */
     dictdecodeyn      = Y,       /* Dictionary decoding */
     derivationyn      = Y,       /* Dataset specific derivations */
     attributesyn      = Y,       /* Reconcile A&R dataset with planned A&R dataset */
     misschkyn         = Y,       /* Print warning message for variables in &DSETOUT with missing values on all records */ 
     recalcvisityn     = Y,       /* Recalculate visit based on the CONMEDS start date */
     timeslicingyn     = Y,       /* Add timeslicing variables */
     xovarsforpgyn     = Y,       /* If derive crossover stydy specific variables for parallel study */
     agemonthsyn       = N,       /* Calculation of age in months */
     ageweeksyn        = N,       /* Calculation of age in weeks */
     agedaysyn         = N,       /* Calculation of age in days */
     refdat            = cmstdt,  /* Reference data variable name for recalculating visit and calculating treatment period */
     reftim            = cmsttm,  /* Reference data variable name for recalculating visit and calculating treatment period */
     refdateoption     = TREAT,   /* Reference date source option */
     refdatevisitnum   = ,        /* Reference date visit number */
     refdatesourcedset = ,        /* Reference date source dataset */
     refdatesourcevar  = ,        /* Reference date source variable */
     refdatedsetsubset = ,        /* Where clause applied to source dataset */
     dyrefdateoption    = ,       /* Reference date source option for the calculation of Study Day values in tu_derive Reference date source option for tu_derive.*/                                  
     dyrefdatedsetsubset= ,       /* WHERE clause applied to source dataset for tu_derive. */            
     dyrefdatesourcedset= ,       /* Reference date source dataset for tu_derive. */                                            
     dyrefdatesourcevar = ,       /* Reference date source variable for tu_derive. */                                           
     dyrefdatevisitnum  = ,       /* Specific visit number at which reference date is to be taken for tu_derive. */         
     trtcdinf          = ,        /* Informat to derive TRTCD from TRTGRP */
     ptrtcdinf         = ,        /* Informat to derive PTRTCD from PTRTGRP */
     dsplan            = &g_dsplanfile, /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
     dsettemplate      = ,        /* Planned A&R dataset template name */
     sortorder         = ,        /* Planned A&R dataset sort order */
     decodepairs       = ,        /* code and decode variables in pair */
     formatnamesdset   = ,        /* Format names dataset name */
     noderivevars      =          /* List of variables not to derive */
     );

  /*
  / Echo parameter values and global macro variables to the log
  /----------------------------------------------------------------------------*/
  %local MacroVersion MacroName;
  %let MacroName=&sysmacroname.;
  %let MacroVersion=2;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals();

  /*
  / Parameter validation
  /----------------------------------------------------------------------------*/
  %let trt_dev_exists      = %nrbquote(%upcase(&trt_dev_exists));
  %let dsetin_conmeds      = %nrbquote(&dsetin_conmeds.);
  %let dsetout             = %nrbquote(&dsetout.);
  %let preprocess          = %nrbquote(&preprocess.);
  %let postprocess         = %nrbquote(&postprocess.);
  %let calctpernum_version = %nrbquote(%upcase(&calctpernum_version));

  %let treatvarsyn         = %nrbquote(%upcase(&treatvarsyn));
  %let attributesyn        = %nrbquote(%upcase(&attributesyn));
  %let misschkyn           = %nrbquote(%upcase(&misschkyn));
  %let xovarsforpgyn       = %nrbquote(%upcase(&xovarsforpgyn));

  /*
  / Check for valid parameter values
  /   set up a macro variable to hold the pv_abort flag
  /----------------------------------------------------------------------------*/
  %local pv_abort abortyn loopi listvars thisvar ;
  %let pv_abort = 0 ;

  /*
  / Check for required parameters.
  /----------------------------------------------------------------------------*/
  
  %let listvars=DSETIN_CONMEDS DSETOUT;

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
  %if %qscan(&dsetin_conmeds, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
  %do;
    %put %str(RTE)RROR: &sysmacroname: The input dataset name DSETIN(=&dsetin_conmeds) is the same as output data set name DSETOUT(=&dsetout).;
    %let pv_abort=1;
  %end;

  /*
  / Validation of dataset
  /   Check existence of datasets and variables
  /----------------------------------------------------------------------------*/
  * DMDATA.CONMEDS exists? ;
  %if not %sysfunc(exist(&dsetin_conmeds)) %then 
  %do;
    %put RTE%str(RROR): &sysmacroname.: &dsetin_conmeds does not exist;
    %let pv_abort = 1;
  %end;

  /* valid values check for : treatvarsyn attributes misschkyn xovarsforpgyn */
  %tu_valparms(
    macroname=&macroname., 
    chktype=isOneOf, 
    pv_varsin= treatvarsyn attributesyn misschkyn xovarsforpgyn trt_dev_exists,      
    valuelist = Y N, 
    abortyn = N
    );

  /*
  / Macro variable declaration
  /----------------------------------------------------------------------------*/
  %local prefix preprocessdset postprocessdset;
  %let prefix = _tc_p1_conmeds ;   /* Root name for temporary work datasets */

  %IF &G_STYPE = XO OR (&G_STYPE = PG AND &XOVARSFORPGYN = Y) %THEN %DO;
    /*-- Check if use tu_p1_calctpernum or tu_calctpernum macro */
    %if %length(&calctpernum_version) = 0 %then 
      %do;
        %put %str(RTE)RROR: &macroname: Macro parameter (calctpernum_version) cannot be blank;
        %let pv_abort = 1;
      %end;
    %else %if (&calctpernum_version ne TU_P1_CALCTPERNUM) and (&calctpernum_version ne TU_CALCTPERNUM) %then 
      %do;
        %put %str(RTE)ERROR: &macroname: Value of CALCTPERNUM_VERSION(=&calctpernum_version) is invalid. Valid values are TU_P1_CALCTPERNUM or TU_CALCTPERNUM.;
        %let pv_abort=1;
      %end;
  %END;

  /*
  / Complete parameter validation
  /----------------------------------------------------------------------------*/
  %if %eval(&g_abort. + &pv_abort.) gt 0 %then 
  %do;
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
  %let preprocessdset = &dsetin_conmeds ;

  %if %nrbquote(&preprocess) ne %then 
  %do;
    data &prefix._preprocess;
      set &dsetin_conmeds;
      %unquote(&preprocess);;
    run;
    %let preprocessdset = &prefix._preprocess;
  %end;

  /*
  / Call DAMA macro tc_conmeds
  /----------------------------------------------------------------------------*/
  %tc_conmeds (dsetin            = &preprocessdset    /* Input dataset name */
              ,dsetout           = &prefix._cm1       /* Output dataset name */
              ,demodset          = &demodset          /* Name of DEMO dataset to use */        
              ,enroldset         = &enroldset         /* Name of ENROL dataset to use */       
              ,exposuredset      = &exposuredset      /* Name of EXPOSURE dataset to use */    
              ,investigdset      = &investigdset      /* Name of INVESTIG dataset to use */        
              ,racedset          = &racedset          /* Name of RACE dataset to use */        
              ,randalldset       = &randalldset       /* Name of RANDALL dataset to use */     
              ,randdset          = &randdset          /* Name of RAND dataset to use */        
              ,tmslicedset       = &tmslicedset       /* Name of TMSLICE dataset to use */      
              ,visitdset         = &visitdset         /* Name of VISIT dataset to use */       
              ,commonvarsyn      = &commonvarsyn      /* Add common variables */
              ,treatvarsyn       = N                  /* Add treatment variables */
              ,datetimeyn        = &datetimeyn        /* Derive datetime variables */
              ,decodeyn          = &decodeyn          /* Decode coded variables */
              ,dictdecodeyn      = &dictdecodeyn      /* Dictionary decoding */
              ,derivationyn      = &derivationyn      /* Dataset specific derivations */
              ,attributesyn      = N                  /* Reconcile A&R dataset with planned A&R dataset */
              ,misschkyn         = N                  /* Print warning message for variables in &DSETOUT with missing values on all records */
              ,recalcvisityn     = &recalcvisityn     /* Recalculate visit based on the Conmeds start date */
              ,timeslicingyn     = &timeslicingyn     /* Add timeslicing variables */
              ,xovarsforpgyn     = N                  /* If derive crossover study specific variables for parallel study */
              ,agemonthsyn       = &agemonthsyn       /* Calculation of age in months */
              ,ageweeksyn        = &ageweeksyn        /* Calculation of age in weeks */
              ,agedaysyn         = &agedaysyn         /* Calculation of age in days */
              ,refdat            = &refdat            /* Reference data variable name for recalculating visit and calculating trt period */
              ,reftim            = &reftim            /* Reference data variable name for recalculating visit and calculating trt period */
              ,refdateoption     = &refdateoption     /* Reference date source option */
              ,refdatevisitnum   = &refdatevisitnum   /* Reference date visit number */
              ,refdatesourcedset = &refdatesourcedset /* Reference date source dataset */
              ,refdatesourcevar  = &refdatesourcevar  /* Reference date source variable */
              ,refdatedsetsubset = &refdatedsetsubset /* Where clause applied to source dataset */
              ,dyrefdateoption    = &dyrefdateoption     /* Reference date source option for the calculation of Study Day values in tu_derive Reference date source option for tu_derive.*/                                  
              ,dyrefdatedsetsubset= &dyrefdatedsetsubset /* WHERE clause applied to source dataset for tu_derive. */            
              ,dyrefdatesourcedset= &dyrefdatesourcedset /* Reference date source dataset for tu_derive. */                                            
              ,dyrefdatesourcevar = &dyrefdatesourcevar  /* Reference date source variable for tu_derive. */                                           
              ,dyrefdatevisitnum  = &dyrefdatevisitnum   /* Specific visit number at which reference date is to be taken for tu_derive. */         
              ,trtcdinf          = &trtcdinf          /* Informat to derive TRTCD from TRTGRP */
              ,ptrtcdinf         = &ptrtcdinf         /* Informat to derive PTRTCD from PTRTGRP */
              ,dsplan            = &g_dsplanfile      /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
              ,dsettemplate      = &dsettemplate      /* Planned A&R dataset template name */
              ,sortorder         = &sortorder         /* Planned A&R dataset sort order */
              ,decodepairs       = &decodepairs       /* code and decode variables in pair */
              ,formatnamesdset   = &formatnamesdset   /* Format names dataset name */
              ,noderivevars      = &noderivevars      /* List of variables not to derive */
              );

  * Set a temporary macro variable containing dataset reference ;
  %let postprocessdset = &prefix._cm1;

  %IF &G_STYPE = XO OR (&G_STYPE = PG AND &XOVARSFORPGYN = Y) %THEN %DO;

    %if "&calctpernum_version"="TU_P1_CALCTPERNUM" %then
    %do;

      /*
      / Set TPERNUM to null prior to call to tu_p1_calctpernum.
      /----------------------------------------------------------------------------*/
      data &prefix._cm1;
        set &prefix._cm1;
        * Set oldtpernum to tpernum for debug ;
        oldtpernum = tpernum ;
        * Reset value of tpernum ;
        tpernum=.;
      run;

      /*
      / Call macro tu_p1_calctpernum to add the correct TPERNUM & TPERIOD
      /----------------------------------------------------------------------------*/
      %tu_p1_calctpernum ( dsetin       = &prefix._cm1       /* Input dataset name */
                          ,dsetout      = &prefix._cm2       /* Output dataset name */
                          ,datadomain   = CM                 /* Data Domain - One of (AE,BL,CM,DS,DS2,SD,IP) */
                          ,refdat       = &refdat            /* Reference date variable name */
                          ,reftim       = &reftim            /* Reference time variable name */
                          ,exposuredset = &exposuredset      /* Exposure dataset name */
                          ,tmslicedset  = &tmslicedset       /* Time Slicing dataset name*/
                          );
    %end;
    %else %if "&calctpernum_version"="TU_CALCTPERNUM" %then
    %do;
      %if &g_stype=XO %then
      %do;
        data &prefix._cm1 (DROP=tpernum tperiod);
          set &prefix._cm1;
        run;
      %end;

      %tu_calctpernum ( dsetin       = &prefix._cm1       /* Input dataset name */
                       ,dsetout      = &prefix._cm2       /* Output dataset name */
                       ,exposuredset = &exposuredset      /* Exposure dataset name */
                       ,refdat       = &refdat            /* Variable name for reference date */
                       ,reftim       = &reftim            /* Variable name for reference time */
                       ,tmslicedset  = &tmslicedset       /* Time slice dataset name */
                       ,visitdset    = &visitdset         /* Visit dataset name */
                       );

      * Set pernum = tpernum as the call to %tu_rantrt requires pernum ;
      * to be present in the input dataset                             ;
      data &prefix._cm2;
        set &prefix._cm2;
        %if %tu_chkvarsexist(&prefix._cm2, tpernum)= %then 
        %do;
          pernum = tpernum ;
        %end;
      run;

    %end ;

    * Set a temporary macro variable containing dataset reference ;
    %let postprocessdset = &prefix._cm2;

  %END ; * End of Loop - &G_STYPE = XO OR (&G_STYPE = PG AND &XOVARSFORPGYN = Y) ;
  /*
  / Treatment.assignment
  /----------------------------------------------------------------------------*/
  %if &treatvarsyn eq Y %then
  %do;

    /*
    / Add treatment variables to dataset
    /---------------------------------------------------------------------------*/
    %tu_rantrt ( dsetin      = &postprocessdset /* Input dataset name */
                ,dsetout     = &prefix._cm3     /* Output dataset name */
                ,ptrtcdinf   = &ptrtcdinf       /* Informat to derive PTRTCD from PTRTGRP */
                ,randalldset = &randalldset     /* RANDALL data set name */
                ,randdset    = &randdset        /* RAND data set name */
                ,trtcdinf    = &trtcdinf        /* Informat to derive TRTCD from TRTGRP */
               );

    %if &g_stype=XO %then 
    %do;

      /*
      / Call tu_p1_acttrt to cater for any treatment deviations 
      /---------------------------------------------------------------------------*/
      %tu_p1_acttrt_xo ( dsetin         = &prefix._cm3      /* Name of input dataset */
                        ,dsetout        = &prefix._cm4      /* Name of output dataset */
                        ,trt_dev_exists = &trt_dev_exists   /* Do treatment deviations exist in your study? */
                        ,exposuredset   = &exposuredset     /* Name of EXPOSURE dataset to use */ 
                        ,tmslicedset    = &tmslicedset      /* Name of TMSLICE dataset to use */ 
                        );

      * Set a temporary macro variable containing dataset reference ;
      %let postprocessdset = &prefix._cm4;

    %end;
    %else %do; * i.e. if &g_stype = PG ;

      /*
      / Assign any Conmeds that started prior to dosing to Pre-treatment
      /----------------------------------------------------------------------------*/
      data &prefix._cm4;
        set &prefix._cm3;
        if tpatrtcd=0 then
        do;
          atrtgrp = tpatrtgp;
          atrtcd  = tpatrtcd;
          %if %tu_chkvarsexist(&prefix._cm3, period) eq  %then %do ;
            period = tperiod ;
          %end ;
        end;
      run;

      /*
      / Call tu_p1_acttrt to cater for any treatment deviations 
      /---------------------------------------------------------------------------*/
      %tu_p1_acttrt_pg ( dsetin         = &prefix._cm4      /* Name of input dataset */
                        ,dsetout        = &prefix._cm5      /* Name of output dataset */
                        ,trt_dev_exists = &trt_dev_exists   /* Do treatment deviations exist in your study? */
                        ,exposuredset   = &exposuredset     /* Name of EXPOSURE dataset to use */ 
                        );

      * Set a temporary macro variable containing dataset reference ;
      %let postprocessdset = &prefix._cm5;

    %end;

  %end; /*EndOf if treatvarsyn = Y */

  %if &g_stype=XO %then 
  %do;

    /*
    / Create Treatment Period Start Day
    /---------------------------------------------------------------------------*/
    %tu_p1_periodday ( dsetin         =&postprocessdset  /* Input dataset                                    */
                      ,dsetout        =&prefix._cm5      /* Output dataset                                   */
                      ,refdate        =cmstdt            /* Reference date variable on input dataset         */
                      ,eventtype      =SP                /* Specifies if the event is planned or spontaneous */
                      ,varout         =tpersdy           /* Name of Period Day variable created              */
                      ,exposuredset   = &exposuredset    /* Name of EXPOSURE dataset to use */ 
                      ,tmslicedset    = &tmslicedset     /* Name of TMSLICE dataset to use */ 
                      );

    /*
    / Create Treatment Period End Day
    /---------------------------------------------------------------------------*/
    %tu_p1_periodday ( dsetin         =&prefix._cm5   /* Input dataset                                    */
                      ,dsetout        =&prefix._cm6   /* Output dataset                                   */
                      ,refdate        =cmendt         /* Reference date variable on input dataset         */
                      ,eventtype      =SP             /* Specifies if the event is planned or spontaneous */
                      ,varout         =tperedy        /* Name of Period Day variable created              */
                      ,exposuredset   = &exposuredset /* Name of EXPOSURE dataset to use */ 
                      ,tmslicedset    = &tmslicedset  /* Name of TMSLICE dataset to use */ 
                     );

    * Set a temporary macro variable containing dataset reference ;
    %let postprocessdset = &prefix._cm6;

  %end; /*EndOf if g_stype = XO */

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

  %else %do;
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

%mend tc_p1_conmeds;
