/*******************************************************************************
|
| Macro Name:      tc_p1_ae_pg
|
| SAS Version:     9.1
|
| Created By:      Khilit Shah
|
| Date:            8 December 2006
|
| Macro Purpose:   Create A&R AE dataset (ARDATA.AE)
|                    - To be used for Parallel Group Study Design
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| ------------------------------------------------------------------
| ------------------------------------------------------------------
|                 FOR INPUT PARAMETERS, REFER TO
|                    DOCUMENTATION FOR TC_P1_AE
| ------------------------------------------------------------------
| ------------------------------------------------------------------
|
| Global macro variables created: NONE
|
| Macros called:
|(@) tc_ae
|(@) tr_putlocals
|(@) tu_abort
|(@) tu_attrib
|(@) tu_calctpernum
|(@) tu_chkvarsexist
|(@) tu_misschk
|(@) tu_p1_acttrt_pg
|(@) tu_p1_calctpernum
|(@) tu_putglobals
|(@) tu_rantrt
|(@) tu_tidyup
|(@) tu_times
|(@) tu_valparms
|
|
|******************************************************************************
| Change Log
|
| Modified By:              Khilit Shah (kys41925)
| Date of Modification:     14-Oct-2008
| New version/draft number: v2 Build 01
| Modification ID:          n/a
| Reason For Modification:  Changes 1-4 are based on the updated to TC_AE macro
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
|                           4. Added parameter DURATIONUNITS, which will be 
|                              passed to %tu_derive
|                           5  Change &treatvarsyn in TC_ call to 'N' as this 
|                              parameter shall be referenced further on during 
|                              the call to tu_rantrt
|                           6  Correct bug in SI.EXPOSURE dset condition from
|                              WHERE=((exstdt NE . AND exsttm NE .) OR (visitnum ne 811))
|                               to
|                              WHERE=((exstdt NE . AND exsttm NE .) AND (visitnum ne 811))
|                           7  Within code of setting ATRTGRP=TPATRTGP, include setting 
|                              of PERIOD = TPERIOD as this does not occur with TU_RANTRT
|                           8  If EXSTTM is not included in exposuredset, then  
|                              create a dummy variable setting the values to missing 
|                           9  Include in the merge statements, a conditional 
|                              merge with variable TPTREFN/PTMNUM if it exists. 
|                           10 Included EXPOSUREDSET to be passed 
|                               on as macro parameters to TU_P1_ACTTRT
|                           11 Included valid value check for 
|                               treatvarsyn attributes misschkyn xovarsforpgyn
|                           
|*******************************************************************************
| Modified By:              Khilit Shah
| Date of Modification:     30-Apr-09
| New version/draft number: v2 Build 02
| Modification ID:          012
| Reason For Modification:     If AESTTM & AEENTM does not exist in &DSETIN_AE then create
|                              the variables and initialise with a value set as missing.
|                           013
|                              Assign the value of AESTTM to a temp time variable, AESTMTMP.
|                              Before the call to TU_TIMES, reset the value of AESTTM from 
|                              AESTMTMP. 
|                              This change is required to address the issue that 
|                              should time be missing, you can correctly assign the value 
|                              for TPERNUM based of a imputed time. 
|                              But when the calculation for time since first/last/period dose
|                              is derived, the orig. missing time value is then to be used
|                              such that the results are calculated in days only and not use 
|                              the imputed time value which would then provided the results in 
|                              DHM which is incorrect. 
|                           014
|                              IF &exposuredset does not contain time (exsttm) then
|                              initialise EXSTTM and set the values to missing
|                           015
|                              If the start time for AE (aesttm) or Exposure (EXSTTM) is missing,
|                              then calculate time relative to last/first/period dose in DAYs 
|                              
|*******************************************************************************
| Modified By:              
| Date of Modification:     
| New version/draft number: 
| Modification ID:          
| Reason For Modification:  
|
*******************************************************************************/

%macro tc_p1_ae_pg(
     trt_dev_exists    = N ,        /* Do Treatment Deviations exists for your study? */
     dsetin_ae         = dmdata.ae, /* Input  dataset name */
     dsetout           = ardata.ae, /* Output dataset name */
     preprocess        = ,          /* Any processing required after reading in the input dataset */
     postprocess       = ,          /* Any processing required before writing out to final output dataset */
     dsetin_vitals     = dmdata.vitals,       /* Input VITALS dataset name */
     vitals_subset     = WHERE weight NE . ,  /* Subset VITALs dataset for selective observations that contain weight info */
     calctpernum_version = TU_P1_CALCTPERNUM, /* If yes, then call TU_P1_CALCTPERNUM else call TU_CALCTPERNUM to assign treatment */
     demodset          = dmdata.demo,       /* Name of DEMO dataset to use */        
     enroldset         = dmdata.enrol,      /* Name of ENROL dataset to use */       
     exposuredset      = dmdata.exposure,   /* Name of EXPOSURE dataset to use */    
     investigdset      = dmdata.investig,   /* Name of INVESTIG dataset to use */        
     racedset          = dmdata.race,       /* Name of RACE dataset to use */        
     randalldset       = dmdata.randall,    /* Name of RANDALL dataset to use */     
     randdset          = dmdata.rand,       /* Name of RAND dataset to use */        
     tmslicedset       = dmdata.tmslice,    /* Name of TMSLICE dataset to use */      
     visitdset         = dmdata.visit,      /* Name of VISIT dataset to use */       
     commonvarsyn      = Y,       /* Add common variables */
     treatvarsyn       = Y,       /* Add treatment variables */
     recalcvisityn     = Y,       /* Recalculate visit based on the AE start date */
     timeslicingyn     = Y,       /* Add timeslicing variables */
     datetimeyn        = Y,       /* Derive datetime variables */
     decodeyn          = Y,       /* Decode coded variables */
     dictdecodeyn      = Y,       /* Dictionary decoding */
     derivationyn      = Y,       /* Dataset specific derivations */
     attributesyn      = Y,       /* Reconcile A&R dataset with planned A&R dataset */
     misschkyn         = Y,       /* Print warning message for variables in &DSETOUT with missing values on all records */
     xovarsforpgyn     = Y,       /* If derive crossover study specific variables for parallel study */
     agemonthsyn       = N,       /* Calculation of age in months */
     ageweeksyn        = N,       /* Calculation of age in weeks */
     agedaysyn         = N,       /* Calculation of age in days */
     refdat            = aestdt,  /* Reference data variable name for recalculating visit and calculating treatment period */
     reftim            = aesttm,  /* Reference data variable name for recalculating visit and calculating treatment period */
     refdateoption     = TREAT,   /* Reference date source option */
     refdatedsetsubset = ,        /* Where clause applied to source dataset */     
     refdatesourcedset = ,        /* Reference date source dataset */
     refdatesourcevar  = ,        /* Reference date source variable */
     refdatevisitnum   = ,        /* Reference date visit number */
     dyrefdateoption    = ,       /* Reference date source option for the calculation of Study Day values in tu_derive Reference date source option for tu_derive.*/                                  
     dyrefdatedsetsubset= ,       /* WHERE clause applied to source dataset for tu_derive. */            
     dyrefdatesourcedset= ,       /* Reference date source dataset for tu_derive. */                                            
     dyrefdatesourcevar = ,       /* Reference date source variable for tu_derive. */                                           
     dyrefdatevisitnum  = ,       /* Specific visit number at which reference date is to be taken for tu_derive. */         
     durationunits     = Days,    /* Units to use for duration */
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
  %let MacroVersion=2 Build 2;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals();

  /*
  / Parameter validation
  /----------------------------------------------------------------------------*/
  %let trt_dev_exists      = %nrbquote(%upcase(&trt_dev_exists));
  %let dsetin_ae           = %nrbquote(&dsetin_ae.);
  %let dsetout             = %nrbquote(&dsetout.);
  %let dsetin_vitals       = %nrbquote(&dsetin_vitals.);
  %let vitals_subset       = %nrbquote(&vitals_subset.);
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
  
  %let listvars=DSETIN_AE DSETOUT DSETIN_VITALS EXPOSUREDSET ;

  %do loopi=1 %to 4;
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
  %if %qscan(&dsetin_ae, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
  %do;
    %put %str(RTE)RROR: &sysmacroname: The input dataset name DSETIN(=&dsetin_ae) is the same as output data set name DSETOUT(=&dsetout).;
    %let pv_abort=1;
  %end;

  /*
  / Validation of dataset
  /   Check existence of datasets and variables
  /----------------------------------------------------------------------------*/
  * DMDATA.AE exists? ;
  %if not %sysfunc(exist(&dsetin_ae)) %then 
  %do;
    %put RTE%str(RROR): &sysmacroname.: dsetin_ae(=&dsetin_ae) does not exist;
    %let pv_abort = 1;
  %end;

  * DMDATA.VITALS exists? ;
  %if not %sysfunc(exist(&dsetin_vitals)) %then 
  %do;
    %put RTE%str(RROR): &sysmacroname.: dsetin_vitals(=&dsetin_vitals) does not exist;
    %let pv_abort = 1;
  %end;

  * DMDATA.EXPOSURE exists and variable check ;
  %if not %sysfunc(exist(&exposuredset)) %then 
  %do;
    %put RTE%str(RROR): &sysmacroname.: exposuredset(=&exposuredset) does not exist;
    %let pv_abort = 1;
  %end;
  %else
  %do;
    %if %length(%tu_chkvarsexist(&exposuredset, EXSTDT)) gt 0 %then 
    %do;
      %put RTE%str(RROR): &sysmacroname.: exposuredset(=&exposuredset) dataset does not contain EXSTDT variable;
      %let pv_abort=1;
    %end;
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
  %local prefix preprocessdset postprocessdset vitalsSubsetdset bylist ;
  %let prefix = _tc_p1_ae_pg ;   /* Root name for temporary work datasets */


  * Check if WEIGHT exists in VITALs                    ;
  *   If it does not then processing continues with a   ;
  *   RTWARNING issued to the log notifying the user    ;
  * Check for duplicate WEIGHT records in VITALs        ;
  *   If it contains duplicates then an RTERROR         ;
  *   message is issued to the log                      ;
  %IF &pv_abort ne 1 %THEN
  %DO ;

      %IF %tu_chkvarsexist(&dsetin_vitals,weight) EQ  %THEN
      %DO;

        %LET vitalsSubsetdset = &dsetin_vitals;

        %IF %nrbquote(&vitals_subset) ne %THEN
        %DO;
           DATA &prefix._vitalsSubset;
              SET &dsetin_vitals;
              %UNQUOTE(&vitals_subset);
           RUN;
           %LET vitalsSubsetdset = &prefix._vitalsSubset;
        %END;

        PROC SORT DATA = &vitalsSubsetdset
                   OUT = &prefix._vitals_dm1 NODUPKEY ;;
          BY subjid weight;
        RUN;

        DATA &prefix._vitals_dm2 ;
          SET &prefix._vitals_dm1 ;
          BY subjid weight;
          IF FIRST.subjid + LAST.subjid < 2 THEN
          DO ;
            PUT "RTE" "RROR: &macroname Duplicate weight records in vitals: " subjid= weight= ;
            CALL SYMPUT('pv_abort', 1);
          END;
        RUN;

      %END ;
      %ELSE %DO ;
        %PUT %str(RTW)ARNING: &macroname: Variable WEIGHT is not included the VITALS dataset (&dsetin_vitals).;
      %END ;
  %END ;

  %IF &xovarsforpgyn = Y %THEN %DO;
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

    * Check if TMSLICE dataset exists and TMSLICE.PERNUM exists ;
    %if not %sysfunc(exist(&tmslicedset)) %then 
    %do;
      %put RTE%str(RROR): &sysmacroname.: tmslicedset(=&tmslicedset) does not exist;
      %let pv_abort = 1;
    %end;
    %else
    %do;
      %if %length(%tu_chkvarsexist(&tmslicedset, PERNUM)) gt 0 %then 
      %do;
        %put RTE%str(RROR): &sysmacroname.: tmslicedset(=&tmslicedset) dataset does not contain PERNUM variable;
        %let pv_abort=1;
      %end;
    %end;

  %END;

  /*
  / Complete parameter validation
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

  data &prefix._aetime;
    set &dsetin_ae ;

    * KS - Mod ID v2 Build 02 - 012 & 013 ;
    * IF &dsetin_ae does not contain                     ;
    *   Start Time (aesttm) and End Time (AEENTM) then   ;
    *   initialise AESTTM and set the values to missing  ;
    *   initialise AEENTM and set the values to missing  ;
    %if %tu_chkvarsexist(&dsetin_ae, aesttm) ne  %then %do ;
      aesttm = . ;
    %end ;
    %if %tu_chkvarsexist(&dsetin_ae, aeentm) ne  %then %do ;
      aeentm = . ;
    %end ;

    * Set the value for AESTMTMP (temp.AE start time) with the value of the AE Start time (AESTTM) ;
    *   This will ensure that should a user change the AE start time as a pre-process step, the    ;
    *   default value of the start time (AESTTM) will be retained and used during the calculation  ;
    *   of Period/First/Last dose.                                                                 ;
    aestmtmp = aesttm ;

  run;

  /*
  / Pre-processing of input dataset
  /   This step allows for the user to pre-process the input dataset in way of
  /   using simple SAS code.
  /   e.g. in the driver call, the user could include information such as
  /   preprocess = if 1 LE SUBJID LE 5 then studypart='A' else studypart = 'B' ;
  /----------------------------------------------------------------------------*/
  %let preprocessdset = &prefix._aetime ;

  %if %nrbquote(&preprocess) ne %then %do;
     data &prefix._preprocess;
        set &prefix._aetime ;
        %unquote(&preprocess);;
     run;
     %let preprocessdset = &prefix._preprocess;
  %end;

 /*
 / Call DAMA macro tc_ae
 /----------------------------------------------------------------------------*/
  %tc_ae ( dsetin            = &preprocessdset /* Input dataset name */
          ,dsetout           = &prefix._ae1    /* Output dataset name */
          ,demodset          = &demodset       /* Name of DEMO dataset to use */        
          ,enroldset         = &enroldset      /* Name of ENROL dataset to use */       
          ,exposuredset      = &exposuredset   /* Name of EXPOSURE dataset to use */    
          ,investigdset      = &investigdset   /* Name of INVESTIG dataset to use */        
          ,racedset          = &racedset       /* Name of RACE dataset to use */        
          ,randalldset       = &randalldset    /* Name of RANDALL dataset to use */     
          ,randdset          = &randdset       /* Name of RAND dataset to use */        
          ,tmslicedset       = &tmslicedset    /* Name of TMSLICE dataset to use */      
          ,visitdset         = &visitdset      /* Name of VISIT dataset to use */       
          ,commonvarsyn      = &commonvarsyn   /* Add common variables */
          ,treatvarsyn       = N               /* Add treatment variables */
          ,recalcvisityn     = &recalcvisityn  /* Recalculate visit based on the AE start date */
          ,timeslicingyn     = &timeslicingyn  /* Add timeslicing variables */
          ,datetimeyn        = &datetimeyn     /* Derive datetime variables */
          ,decodeyn          = &decodeyn       /* Decode coded variables */
          ,dictdecodeyn      = &dictdecodeyn   /* Dictionary decoding */
          ,derivationyn      = &derivationyn   /* Dataset specific derivations */
          ,attributesyn      = N       /* Reconcile A&R dataset with planned A&R dataset */
          ,misschkyn         = N       /* Print warning message for variables in &DSETOUT with missing values on all records */
          ,xovarsforpgyn     = N               /* If derive crossover study specific variables for parallel study */
          ,agemonthsyn       = &agemonthsyn    /* Calculation of age in months */
          ,ageweeksyn        = &ageweeksyn     /* Calculation of age in weeks */
          ,agedaysyn         = &agedaysyn      /* Calculation of age in days */
          ,refdat            = &refdat         /* Reference data variable name for recalculating visit and calculating trt period */
          ,reftim            = &reftim         /* Reference data variable name for recalculating visit and calculating trt period */
          ,refdateoption     = &refdateoption     /* Reference date source option */
          ,refdatedsetsubset = &refdatedsetsubset    /* Where clause applied to source dataset */     
          ,refdatesourcedset = &refdatesourcedset    /* Reference date source dataset */
          ,refdatesourcevar  = &refdatesourcevar     /* Reference date source variable */
          ,refdatevisitnum   = &refdatevisitnum      /* Reference date visit number */
          ,dyrefdateoption    = &dyrefdateoption     /* Reference date source option for the calculation of Study Day values in tu_derive Reference date source option for tu_derive.*/                                  
          ,dyrefdatedsetsubset= &dyrefdatedsetsubset /* WHERE clause applied to source dataset for tu_derive. */            
          ,dyrefdatesourcedset= &dyrefdatesourcedset /* Reference date source dataset for tu_derive. */                                            
          ,dyrefdatesourcevar = &dyrefdatesourcevar  /* Reference date source variable for tu_derive. */                                           
          ,dyrefdatevisitnum  = &dyrefdatevisitnum   /* Specific visit number at which reference date is to be taken for tu_derive. */         
          ,durationunits     = &durationunits     /* Units to use for duration */
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
  %let postprocessdset = &prefix._ae1;

  %IF (&xovarsforpgyn = Y) %THEN 
  %DO;

    %if "&calctpernum_version"="TU_P1_CALCTPERNUM" %then
    %do;

      /*
      / Set TPERNUM to null prior to call to tu_p1_calctpernum.
      /----------------------------------------------------------------------------*/
      data &prefix._ae1;
        set &prefix._ae1;
        * set oldtpernum to tpernum for debug ;
        oldtpernum = tpernum ;
        * reset value of tpernum ;
        tpernum=.;
      run;

      /*
      / Call macro tu_p1_calctpernum to add the correct TPERNUM & TPERIOD
      /----------------------------------------------------------------------------*/
      %tu_p1_calctpernum ( dsetin       = &prefix._ae1    /* Input dataset name */
                          ,dsetout      = &prefix._ae2    /* Output dataset name */
                          ,datadomain   = AE              /* Data Domain - One of (AE,BL,CM,DS,DS2,SD,IP) */
                          ,refdat       = &refdat         /* Reference date variable name */
                          ,reftim       = &reftim         /* Reference time variable name */
                          ,exposuredset = &exposuredset   /* Exposure dataset name */
                          ,tmslicedset  = &tmslicedset  /* Time Slicing dataset name*/
                          );

    %end; /* EndOf IF tu_p1_calctpernum */
    %else %if "&calctpernum_version"="TU_CALCTPERNUM" %then
    %do ;
      %tu_calctpernum ( DSETIN              =&prefix._ae1      /* Input dataset name */
                       ,DSETOUT             =&prefix._ae2      /* Output dataset name */
                       ,EXPOSUREDSET        =&exposuredset     /* Exposure dataset name */
                       ,REFDAT              =&refdat           /* Variable name for reference date */
                       ,REFTIM              =&reftim           /* Variable name for reference time */
                       ,TMSLICEDSET         =&tmslicedset      /* Time slice dataset name */
                       ,VISITDSET           =&visitdset        /* Visit dataset name */
                       );

      * set pernum = tpernum as the call to %tu_rantrt requires pernum ;
      *  to be present in the input dataset                            ;
      DATA &prefix._ae2;
        SET &prefix._ae2  ;
        %IF %tu_chkvarsexist(&prefix._ae2, tpernum)= %THEN 
        %DO ;
          pernum = tpernum ; 
        %END;
      RUN;

    %end ; /* EndOf IF tu_calctpernum */

    * Set a temporary macro variable containing dataset reference ;
    %let postprocessdset = &prefix._ae2;

  %END ; /* EndOf  IF (&XOVARSFORPGYN = Y) */

  /*
  / Treatment.assignment
  /----------------------------------------------------------------------------*/
  %if (&treatvarsyn eq Y) %then
  %do;

    /*
    / Add treatment variables to dataset
    /---------------------------------------------------------------------------*/
    %tu_rantrt ( dsetin      = &postprocessdset  /* Input dataset name */
                ,dsetout     = &prefix._ae3      /* Output dataset name */
                ,ptrtcdinf   = &ptrtcdinf        /* Informat to derive PTRTCD from PTRTGRP */
                ,randalldset = &randalldset      /* RANDALL data set name */
                ,randdset    = &randdset         /* RAND data set name */
                ,trtcdinf    = &trtcdinf         /* Informat to derive TRTCD from TRTGRP */
               );

    /*
    / Assign any AEs that started prior to dosing to Pre-treatment
    /----------------------------------------------------------------------------*/
    data &prefix._ae4;
      set &prefix._ae3;
      if tpatrtcd=0 then
      do;
        atrtgrp = tpatrtgp;
        atrtcd  = tpatrtcd;
        %if %tu_chkvarsexist(&prefix._ae3, period) eq  %then %do ;
          period = tperiod ;
        %end ;
      end;
    run;

    /*
    / Call _p1_acttrt to cater for any treatment deviations
    /---------------------------------------------------------------------------*/
    %tu_p1_acttrt_pg ( dsetin         = &prefix._ae4    /* Name of input dataset */
                      ,dsetout        = &prefix._ae5    /* Name of output dataset */
                      ,trt_dev_exists = &trt_dev_exists /* Do treatment deviations exist in your study? */
                      ,exposuredset   = &exposuredset   /* Name of EXPOSURE dataset to use */ 
                      );

    * Set a temporary macro variable containing dataset reference ;
    %let postprocessdset = &prefix._ae5;

  %end; /*EndOf if treatvarsyn = Y)

  /*
  / KS - Mod ID v2 Build 02 - 013
  / Reset the value of AE Start Time (AESTTM) with the original start time 
  /   value that was collected in the &dsetin_ae dataset. The original start
  /   time value was stored in the temp AE start time variable (AESTMTMP)
  /---------------------------------------------------------------------------*/
  data &postprocessdset ;
    set &postprocessdset ;
    if aesttm NE aestmtmp then 
    do ;
      aesttm = aestmtmp ;
      aestdm = dhms(aestdt, 0, 0, aesttm) ;
    end;
  run;

  /*
  / Get unique dosing timepoint from EXPOSURE
  /---------------------------------------------------------------------------*/
  data &prefix._expo1 ;
    set &exposuredset ;
      * KS - Mod ID v2 Build 02 - 014 ;
      * IF &exposuredset does not contain time (exsttm) then ;
      *   initialise EXSTTM and set the values to missing    ;
      %if %tu_chkvarsexist(&exposuredset, exsttm) ne  %then %do ;
        exsttm = . ;
      %end ;
  run;

  /*
  / Generate a BYLIST value to hold the variables that shall be used for the 
  /   variables to keep from EXPOSURE dset 
  / As PTMNUM and TPTREFN are optional variables in DataSetManager, these    
  /     variables shall be used as the 'BY' variables conditionally.
  /----------------------------------------------------------------------------*/
  data _null_ ;
    %let bylist = visitnum ;
    %if %tu_chkvarsexist(&exposuredset, tptrefn) eq %then %let bylist = &bylist tptrefn;
    %if %tu_chkvarsexist(&exposuredset, ptmnum)  eq %then %let bylist = &bylist ptmnum;
  run;

  /*
  / NB: Any missing date is excluded as this indicates that the subject
  /    was not dosed for that particular visit
  / Exclude any Liver Events records in the exposure dataset (visitnum=811)
  /----------------------------------------------------------------------------*/
  proc sort data = &prefix._expo1  (keep=subjid &bylist exstdt exsttm
                                    where=(((exstdt ne .) and not (exstdt = . and exsttm =  .)) and (visitnum ne 811))
                                   )
             out = &prefix._expo2;
    by &bylist;
  run;

  * Create TEMPDAT variable to handle missing times             ;
  *   In this case, if exposure time is missing, then set       ;
  *   TEMPDAT = 0 , such that when sorted by subject, date, the ;
  *   misisng time would appear as the record followed by the   ;
  *   observation containing time for the same subject, date    ;

  data &prefix._expo3 (keep=subjid exstdm exstdt tempdat);
    set &prefix._expo2 ;

    exstdm = dhms(exstdt, 0, 0, exsttm);

    if exsttm = . then tempdat=0;
    else tempdat = 500;
  run;

  proc sort data = &prefix._expo3
             out = &prefix._expo4 nodupkey;
    by subjid exstdt tempdat exstdm;
  run;

    * KS - Mod ID v2 Build 02 - 012 & 013 ;
    * IF &dsetin_ae does not contain                     ;
    *   Start Time (aesttm) and End Time (AEENTM) then   ;
    *   initialise AESTTM and set the values to missing  ;
    *   initialise AEENTM and set the values to missing  ;



  /*
  / slot the AE and EXPO datasets to derive the
  /   - Time from First Dose (AETRT1ST / AETRT1SC)
  /   - Time from Last Dose  (AETRTST  / AETRTSC )
  /   - Duration             (AEDUR    / AEDURC  )
  / KS - Mod ID v2 Build 02 - 015
  |     If the start time for AE (aesttm) or Exposure (EXSTTM) is missing,
  |     then calculate time relative to last/first/period dose in DAYs 
  /---------------------------------------------------------------------------*/
  data &prefix._ae6;
    set &postprocessdset;
    if aesttm = . then tempdat = 999;
    else tempdat=500;
  run;

  proc sort data=&prefix._ae6;
    by subjid aestdt tempdat aestdm;
  run;

  DATA &prefix._ae7 ;
    SET &prefix._expo4 (IN=expo RENAME=(exstdt=aestdt exstdm=aestdm))
        &prefix._ae6   (IN=ae);
    BY subjid aestdt tempdat aestdm;
    FORMAT first_dose_m last_dose_m datetime20.
           first_dose_d last_dose_d date9.       ;
    RETAIN first_dose_m last_dose_m
           first_dose_d last_dose_d ;

    IF FIRST.subjid THEN DO;
      first_dose_m=.; first_dose_d = . ;
      last_dose_m=. ; last_dose_d  = . ;
    END;

    IF expo then do;
      IF first_dose_m  = . THEN first_dose_m  = aestdm;
      IF first_dose_d  = . THEN first_dose_d  = aestdt;

      last_dose_m   = aestdm ;
      last_dose_d   = aestdt ;
    END;

    IF ae THEN OUTPUT ;

  RUN ;

  DATA &prefix._ae8;
    SET &prefix._ae7 ;
    IF aesttm NE . THEN
    DO ;
      * Calculate Time since First Dose ;
      if first_dose_m NE . then 
      do;
        %tu_times(unit=m, start=first_dose_m,  end=aestdm, output=aetrt1st, outputc=aetrt1sc);
      end;
      else
      do; 
        %tu_times(unit=d, start=first_dose_d,  end=aestdt, output=aetrt1st, outputc=aetrt1sc);
      end;

      * Calculate Time since Last Dose ;
      if last_dose_m NE . then do;
        %tu_times(unit=m, start=last_dose_m,   end=aestdm, output=aetrtst,  outputc=aetrtstc);
      end;
      else do;
        %tu_times(unit=d, start=last_dose_d,   end=aestdt, output=aetrtst,  outputc=aetrtstc);
      end;
    END;

    ELSE
    DO ; 
      * Calculate Time since First Dose ;
      %tu_times(unit=d, start=first_dose_d,  end=aestdt, output=aetrt1st, outputc=aetrt1sc);

      * Calculate Time since Last Dose ;
      %tu_times(unit=d, start=last_dose_d,   end=aestdt, output=aetrtst,  outputc=aetrtstc);
    END ;

    * Calculate Duration ;
    IF aesttm NE . AND aeentm NE . THEN
    DO ;
      aeduru = 'm' ;
      %tu_times(unit=m, start=aestdm,        end=aeendm, output=aedur,    outputc=aedurc);
    END;
    ELSE
    DO ;
      aeduru = 'd' ;
      %tu_times(unit=d, start=aestdt,        end=aeendt, output=aedur,    outputc=aedurc);
    END;

  RUN ;

  %let postprocessdset = &prefix._ae8;

  /*
  / Merge on Weight (as required for Phase1 IDSL displays)
  / An optional macro parameter is available such that the user can subset the
  /   dataset containing this information with any user supplied SAS code
  / e.g. in the driver call, the user could include information such as
  /     vitals_subset = WHERE weight NE . ;
  /
  / NOTE: If variables are read in from the VITALs dataset. Ensure you only keep
  /       those variables you require by specifying this in the AE DSPLAN
  /
  /----------------------------------------------------------------------------*/

  * Check if &vitalsSubsetdset contains a value or not   ;
  * If not, then create a dummy value to be assigned to  ;
  *   the macro variable that shall then be passed on to ;
  *   check whether to include vitals processing or not  ;
  %if %length(&vitalsSubsetdset) = 0 %then 
  %do ;
    data _null_  ;
      call symput ('vitalsSubsetdset', 'DUMMY') ;
    run;
  %end ;

  %if %sysfunc(exist(&vitalsSubsetdset)) > 0 and %upcase("&vitalsSubsetdset") NE "DUMMY" %then
  %do ;
    proc sort data=&vitalsSubsetdset;
      by subjid;
    run;

    data &prefix._ae9;
      merge &prefix._ae8(in=a)
            &vitalsSubsetdset;
      by subjid;
      if a;
    run;

    %let postprocessdset = &prefix._ae9 ;

  %end ; 

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
    %tu_misschk(
         dsetin        = &dsetout
    );
   %end;

  /*
  / Delete temporary datasets used in this macro.
  /----------------------------------------------------------------------------*/
  %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tc_p1_ae_pg ;
