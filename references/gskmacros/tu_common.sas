/*******************************************************************************
|
| Macro Name:      tu_common
|
| Macro Version:   3 build 1
|
| SAS Version:     8.2
|
| Created By:      Mark Luff
|
| Date:            19-Apr-2004
|
| Macro Purpose:   Add Common Variables i.e. those common to all AR datasets
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                            REQ/OPT  DEFAULT
| -----------------  -------------------------------------  -------  ----------
| DSETIN             Specifies the dataset for which the    REQ      (Blank)
|                    common variable are to be added.
|                    Valid values: valid dataset name
|
| DSETOUT            Specifies the name of the output       REQ      (Blank)
|                    dataset to be created.
|                    Valid values: valid dataset name
|
| DEMODSET            Specifies an SI-format DEMO dataset to use   dmdata.demo
|                     for various derivations.
|
| ENROLDSET           Specifies an SI-format ENROL dataset to use  dmdata.enrol
|                     for various derivations.
|
| EXPOSUREDSET        Specifies an SI-format EXPOSURE dataset to   dmdata.exposure
|                     use for various derivations.
|
| INVESTIGDSET        Specifies an SI-format INVESTIG dataset to   dmdata.investig
|                     use for various derivations.
|
| RACEDSET            Specifies an SI-format RACE dataset to use   dmdata.race
|                     for various derivations.
|
| RANDDSET            Specifies an SI-format RAND dataset to use   dmdata.rand
|                     for various derivations.
|
| VISITDSET           Specifies an SI-format VISIT dataset to use  dmdata.visit
|                     for various derivations.
|
| AGEMONTHSYN        Calculate and add to output dataset    REQ      N
|                    the AGEMO variable.
|
| AGEWEEKSYN         Calculate and add to output dataset    REQ      N
|                    the AGEWK variable.
|
| AGEDAYSYN          Calculate and add to output dataset    REQ      N
|                    the AGEDY variable.
|
| REFDATEOPTION      The reference date will be used in     REQ      TREAT
|                    calculation of the age values.
|                    TREAT - Trt start date from DMDATA.
|                            EXPOSURE
|                    VISIT - Visit date from DMDATA.VISIT
|                    RAND  - Randomization date from 
|                            DMDATA.RAND
|                    OTHER - Date from the REFRESOUCEVAR
|                            variable on the 
|                            REFRESOURCEDSET Dataset.
|
| REFDATEVISITNUM    Specific visit number at which          OPT      (Blank)
|                    reference date is to be taken.                          
|                    Required if REFDATEOPTION is VISIT.
|
| REFDATESOURCEDSET  Required if REFDATEOPTION is OTHER.     OPT      (Blank)
|                    Use the variable REFDATESOURCEVAR 
|                    from the REFDATESOURCEDSET.
|
| REFDATESOURCEVAR   Required if REFDATEOPTION is OTHER.     OPT      (Blank)
|                    Use the variable REFDATESOURCEVAR 
|                    from the REFDATESOURCEDSET.
|
| REFDATEDSETSUBSET  May be used regardless of the value     OPT      (Blank)
|                    of REFDATEOPTION in order to better
|                    select the reference date.
| -----------------  -------------------------------------  -------  ----------
|
| The macro references the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| DMDATA.DEMO        Opt      SI Demography dataset
| DMDATA.ENROL       Opt      SI Subject Enrollment dataset
| DMDATA.RACE        Opt      SI Subject Collected Race
| &DSETIN            Req      Parameter specified dataset
| -----------------  -------  -------------------------------------------------
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
|
|(@) tr_putlocals
|(@) tu_abort
|(@) tu_chkvarsexist 
|(@) tu_putglobals
|(@) tu_refdat
|(@) tu_tidyup
|
| Example:
|    %tu_common(
|         dsetin  = _ae1,
|         dsetout = _ae2
|         );
|
|******************************************************************************
| Change Log
|
| Modified By:              Yongwei Wang
| Date of Modification:     16-Feb-2005
| New version/draft number: 1/2
| Modification ID:          YW001
| Reason For Modification:  If CENTREID and INVID exist on the SI INVESTIG 
|                           dataset, then take the information from there.
|                           Else, get the information from the SI ENROL 
|                           dataset. 
|
| Modified By:              Yongwei Wang
| Date of Modification:     07-Nov-2007
| New version/draft number: 2/1
| Modification ID:
| Reason For Modification:  1. Added new parameter DEMODSET, ENROLDSET, INVESTIGDSET, 
|                              RACEDSET, VISITDSET, RANDDSET, and EXPOSUREDSET, and make 
|                              data set options work for new parameters, &DSETIN and 
|                              &DSETOUT - HRT0184
|                           2. Overwrote CENTREID in input data set - HRT0168
|                           3. Derived age from DEMO data set. Write RTWARNING to log
|                              when age not in &DEMODSET and REFDATEOPTION is not given
|
| Modified By:              Shan Lee
| Date of Modification:     05-Mar-2009
| New version/draft number: 3/1
| Modification ID:          SL001
| Reason For Modification:  Implement changes requested in HRT0221:
|
|                           Ensure that CENTREID and INVID are assigned 
|                           correctly and appropriate messages generated for
|                           all possible scenarios - i.e. where CENTREID is
|                           present in DSETIN and missing in ENROL/INVESTIG,
|                           keep CENTREID from DSETIN etc, etc. 
|
*******************************************************************************/
%macro tu_common (
   dsetin           = ,                /* Input dataset name */
   dsetout          = ,                /* Output dataset name */
   demodset         = dmdata.demo,     /* Name of DEMO dataset to use */       
   enroldset        = dmdata.enrol,    /* Name of ENROL dataset to use */      
   exposuredset     = dmdata.exposure, /* Name of EXPOSURE dataset to use */   
   investigdset     = dmdata.investig, /* Name of INVESTIGDSET dataset to use */       
   racedset         = dmdata.race,     /* Name of RACE dataset to use */       
   randdset         = dmdata.rand,     /* Name of RAND dataset to use */       
   visitdset        = dmdata.visit,    /* Name of VISIT dataset to use */      
   agemonthsyn      = N,               /* Calculation of age in months Y/N */
   ageweeksyn       = N,               /* Calculation of age in weeks Y/N */
   agedaysyn        = N,               /* Calculation of age in days Y/N */
   refdateoption    = treat,           /* Reference date source option */
   refdatevisitnum  = ,                /* Specific visit number at which reference date is to be taken */
   refdatesourcedset= ,                /* Reference date source dataset */
   refdatesourcevar = ,                /* Reference date source variable */
   refdatedsetsubset=                  /* WHERE clause applied to source dataset */
   );

 /*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion;
 %let MacroVersion = 3 build 1;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals() 

 /*
 / PARAMETER VALIDATION
 /----------------------------------------------------------------------------*/

 %let dsetin        = %nrbquote(&dsetin);
 %let dsetout       = %nrbquote(&dsetout);
 %let refdateoption = %nrbquote(&refdateoption);
 %let agemonthsyn   = %nrbquote(%upcase(%substr(&agemonthsyn, 1, 1)));
 %let ageweeksyn    = %nrbquote(%upcase(%substr(&ageweeksyn, 1, 1)));
 %let agedaysyn     = %nrbquote(%upcase(%substr(&agedaysyn, 1, 1)));

 /*
 / Check for required parameters.
 /----------------------------------------------------------------------------*/

 %if &dsetin eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter DSETIN is required.;
    %let g_abort=1;
 %end; /* end-if Required parameter DSETIN is not specified.  */

 %if &dsetout eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter DSETOUT is required.;
    %let g_abort=1;
 %end;  /* end-if  Required parameter DSETOUT is not specified.  */

 %if &agemonthsyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter AGEMONTHSYN is required.;
    %let g_abort=1;
 %end;  /* end-if  Required parameter AGEMONTHSYN is not specified.  */

 %if &ageweeksyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter AGEWEEKSYN is required.;
    %let g_abort=1;
 %end;  /* end-if  Required parameter ADEWEEKSYN is not specified.  */

 %if &agedaysyn eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter AGEDAYSYN is required.;
    %let g_abort=1;
 %end;  /* end-if Required parameter AGEDAYSYN is not specified.  */

 /*
 / Check for valid parameter values.
 /----------------------------------------------------------------------------*/

 %if &agemonthsyn ne Y and &agemonthsyn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: AGEMONTHSYN should be either Y or N.;
    %let g_abort=1;
 %end;  /* end-if Parameter AGEMONTHSYN set to invalid values.  */

 %if &ageweeksyn ne Y and &ageweeksyn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: AGEWEEKSYN should be either Y or N.;
    %let g_abort=1;
 %end;  /* end-if  Parameter AGEWEEKSYN set to invalid values.  */

 %if &agedaysyn ne Y and &agedaysyn ne N %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: AGEDAYSYN should be either Y or N.;
    %let g_abort=1;
 %end;  /* end-if  Parameter AGEDAYSYN set to invalid values.  */

 /*
 / Check for existing datasets.
 /----------------------------------------------------------------------------*/

 %if %sysfunc(exist(%qscan(&dsetin, 1, %str(%()))) eq 0 %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The dataset DSETIN(=&dsetin) does not exist.;
    %let g_abort=1;
 %end;  /* end-if Specified DSETIN parameter does not exist.  */

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;

 /*
 / If the input dataset name is the same as the output dataset name,
 / write a note to the log.
 /----------------------------------------------------------------------------*/

 %if %qscan(&dsetin, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
 %do;
    %put %str(RTN)OTE: &sysmacroname: The input dataset name DSETIN(=&dsetin) is the same as the output dataset name DSETOUT(=&dsetout).;
 %end;  /* end-if  Parameters specified for DSETIN and DSETOUT are the same.  */

 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/

 %local prefix invdset keepvars exist_centid exist_invid;

 %let prefix = _common;   /* Root name for temporary work datasets */
 %let invdset=;           /* data set where INVID is derived */

 proc sort data=%unquote(&dsetin) out=&prefix._main1;
      by studyid subjid;
 run;

 /*
 / Obtain common variables for sex, race, and age.
 /----------------------------------------------------------------------------*/

 %if ( %nrbquote(&demodset) ne ) and %sysfunc(exist(%qscan(&demodset, 1, %str(%()))) %then
 %do;
    /* Demography dataset exists */
    data &prefix._demoexist;
       if 0 then set %unquote(&demodset);
    run;

    /*
    / Check that variable RACECD exists on the &demodset dataset.
    / If so, then keep it.
    /----------------------------------------------------------------------------*/

    %if %tu_chkvarsexist(&prefix._demoexist, racecd) eq  %then
    %do;
       %let racecd_var=RACECD;
    %end;  /*  Variable RACECD exists in dataset &demodset.  */
    %else
    %do;
       %let racecd_var= ;
    %end;  /*  Variable RACECD does not exist in dataset &demodset.  */
    
    %if %tu_chkvarsexist(&prefix._demoexist, SEX) ne %then
    %do;
       %put %str(RTW)ARNING: &sysmacroname: REFDATEOPTION is not given and variable SEX is not in DEMODSET(=&demodset).;
       %put %str(RTW)ARNING: &sysmacroname: Variable SEX will not be added to the output dataset.;
    %end;       
    %else %let racecd_var=&racecd_var SEX;
   
    %if ( %nrbquote(&refdateoption) ne ) and ( %tu_chkvarsexist(&prefix._demoexist, birthdt) ne ) %then
    %do;   
       %put %str(RTW)ARNING: &sysmacroname: REFDATEOPTION(=&refdateoption) is given, but variable BIRTHDT does not exist in DEMODSET(=&demodset).;
       %put %str(RTW)ARNING: &sysmacroname: Set REFDATEOPTION to blank and try to get AGE variables from DEMODSET(=&demodset).;
    %end;
    
    /*
    / If &refdateoption is not given, get AGE variables from &DEMODSET.
    /----------------------------------------------------------------------------*/
    
    %if %nrbquote(&refdateoption) eq %then
    %do;
       %if ( &agemonthsyn eq Y ) and ( %tu_chkvarsexist(&prefix._demoexist, agemo) ne ) %then
       %do;
          %put %str(RTW)ARNING: &sysmacroname: AGEMONTHSYN(=&agemonthsyn), but REFDATEOPTION is not given and variable AGEMO is not in DEMODSET(=&demodset).;
          %put %str(RTW)ARNING: &sysmacroname: Variable AGEMO will not be added to the output dataset.;
       %end;
       %else %if ( &agemonthsyn eq Y ) %then %let racecd_var=&racecd_var AGEMO;
       
       %if ( &ageweeksyn eq Y ) and ( %tu_chkvarsexist(&prefix._demoexist, agewk) ne ) %then
       %do;
          %put %str(RTW)ARNING: &sysmacroname: AGEWEEKSYN(=&ageweeksyn), but REFDATEOPTION is not given and variable AGEWK is not in DEMODSET(=&demodset).;
          %put %str(RTW)ARNING: &sysmacroname: Variable AGEWK will not be added to the output dataset.;
       %end;
       %else %if ( &ageweeksyn eq Y ) %then %let racecd_var=&racecd_var AGEWK;
       
       %if ( &agedaysyn eq Y ) and ( %tu_chkvarsexist(&prefix._demoexist, agedy) ne ) %then
       %do;
          %put %str(RTW)ARNING: &sysmacroname: AGEDAYSYN(=&agedaysyn), but REFDATEOPTION is not given and variable AGEDY is not in DEMODSET(=&demodset).;
          %put %str(RTW)ARNING: &sysmacroname: Variable AGEDY will not be added to the output dataset.;
       %end;       
       %else %if ( &agedaysyn eq Y ) %then %let racecd_var=&racecd_var AGEDY;
       
       %if %tu_chkvarsexist(&prefix._demoexist, AGE) ne %then
       %do;
          %put %str(RTW)ARNING: &sysmacroname: REFDATEOPTION is not given and variable AGE is not in DEMODSET(=&demodset).;
          %put %str(RTW)ARNING: &sysmacroname: variable AGE will not be added to the output dataset.;
       %end;       
       %else %let racecd_var=&racecd_var AGE;
       
       %if %nrbquote(&racecd_var) ne %then
       %do;
          proc sort data=%unquote(&demodset) out=&prefix._demo3(keep=studyid subjid &racecd_var) nodupkey;
             by studyid subjid;
          run;
          %put %str(RTN)OTE: &sysmacroname: variable &racecd_var will be added from DEMODSET(=&demodset) to the output dataset.;
       %end;       
    %end;  /* %if %nrbquote(&refdateoption) eq */
    
    /*
    / If &refdateoption is given, derive AGE variables from &DEMODSET and other
    / data sets.
    /----------------------------------------------------------------------------*/
    
    %else %do;
    
        /* Obtain sex, race and birth date variables */
        proc sort data = %unquote(&demodset) out = &prefix._demo1 
                 (keep=studyid subjid &racecd_var birthdt rename=(birthdt=_dob));
             by studyid subjid;
        run;
        
        /* Calculate reference date to use in age calculation */
        %tu_refdat(dsetin            = &prefix._demo1,
                   dsetout           = &prefix._demo2,
                   exposuredset      = &exposuredset,
                   randdset          = &randdset,
                   visitdset         = &visitdset,               
                   refdatevar        = dmrefdt,
                   refdateoption     = &refdateoption,
                   refdatevisitnum   = &refdatevisitnum,
                   refdatesourcedset = &refdatesourcedset,
                   refdatesourcevar  = &refdatesourcevar,
                   refdatedsetsubset = &refdatedsetsubset
                  );
        
        data &prefix._demo3;
             set &prefix._demo2;
        
             if dmrefdt ne . and _dob ne . then
             do;
                age=intck('year',_dob,dmrefdt) -
                     ( month(dmrefdt) lt month(_dob) or
                      (month(dmrefdt) eq month(_dob) and day(dmrefdt) lt day(_dob)) );
        
                %if &agemonthsyn eq Y %then
                %do;
                 agemo = (year(dmrefdt) - year(_dob)) * 12
                        + (month(dmrefdt)-month(_dob)-1)
                        + (day(dmrefdt) ge day(_dob));
                %end;  /* end-if  Parameter AGEMONTHSYN set to 'Y'.  */
        
                %if &ageweeksyn eq Y %then
                %do;
                 agewk = int((dmrefdt-_dob)/7);
                %end;  /* end-if Parameter AGEWEEKSYN set to 'Y'.  */
        
                %if &agedaysyn eq Y %then
                %do;
                 agedy = dmrefdt-_dob;
                %end;  /* end-if  Parameter AGEDAYSYN  set to 'Y'.  */
             end;  /* end-if Variables DMREFDT not eq . and DOB not eq ..  */
        
             drop _dob dmrefdt;
        run;
     %end; /* %if %nrbquote(&refdateoption) eq %else */       
 %end;  /* end-if  Dataset &demodset  exists.  */
 %else
 %do;
    %put %str(RTW)ARNING: &sysmacroname: The dataset DEMODSET(=&demodset) is not given or does not exist.;
    %put %str(RTW)ARNING: &sysmacroname: RACECD, SEX, and AGE variables will not be added to the output dataset.;
 %end;  /*  end-if  Dataset &demodset does not exist.  */

 /*
 / Obtain common variable for centre.
 / YW001: Mdoified the process which gets the INVID and CENTREID.
 / if CENTREID and INVID in &enroldset, get them from it. Otherwise try to
 / get them from both &enroldset and &investigdset
 /----------------------------------------------------------------------------*/
  
 %if %nrbquote(&enroldset) ne and %sysfunc(exist(%qscan(&enroldset, 1, %str(%()))) %then
 %do;
    data &prefix._enrolexist;
       if 0 then set %unquote(&enroldset);
    run;
   
    %let keepvars=%tu_chkvarsexist(&prefix._enrolexist, CENTREID INVID);
    
    %if %nrbquote(&keepvars) eq %then 
    %do;
       %let invdset=&enroldset;       
    %end;
    %else %if %nrbquote(&investigdset) ne and %sysfunc(exist(%qscan(&investigdset, 1, %str(%()))) %then
    %do;
    
       %if %qupcase(&keepvars) eq INVID %then
       %do;
          data &prefix._investigexist;
             if 0 then set %unquote(&investigdset);
          run;
          %if %tu_chkvarsexist(&prefix._investigexist, CENTREID) eq %then %let keepvars=CENTREID;
          %else %let keepvars=;
       %end;
       %else %let keepvars=;       
    
       proc sort data=%unquote(&investigdset) out=&prefix.invtig nodup;
          by studyid subjid &keepvars;
       run;
       
       proc sort data=%unquote(&enroldset) out=&prefix.enrol nodupkey;
          by studyid subjid &keepvars;
       run;
       
       data &prefix.inv;
          merge &prefix.enrol  
                &prefix.invtig;
          by studyid subjid &keepvars;
       run;
       
       %let invdset=&prefix.inv;    
    %end;
 %end;  /*  end-if  Dataset &enroldset exists.  */
 %else %do;
    %put %str(RTN)OTE: &sysmacroname: The dataset ENROLDSET(=&enroldset) is not given or does not exist.;
    %if %nrbquote(&investigdset) ne and %sysfunc(exist(%qscan(&investigdset, 1, %str(%()))) %then
    %do;
        %let invdset=&investigdset;
    %end;
    %else %do;
       %put %str(RTW)ARNING: &sysmacroname: The dataset INVESTIGDSET(=&investigdset) and ENROLDSET(=&enroldset) are not given or do not exist.;
       %put %str(RTW)ARNING: &sysmacroname: CENTREID and INVID will not be added to the output dataset.;     
    %end;    
 %end;
 
 %if %nrbquote(&invdset) ne %then
 %do;
    data &prefix._invdsetexist;
       if 0 then set %unquote(&invdset);
    run;
    %if %qupcase(&invdset) eq %nrbquote(&enroldset) %then %let keepvars=;
    %else %let keepvars=%tu_chkvarsexist(&prefix._invdsetexist, CENTREID INVID);
    
    %if %nrbquote(&keepvars) ne %then
    %do;
       %put %str(RTW)ARNING: &sysmacroname: Can not find &keepvars in &enroldset and/or &investigdset and will not add them to the output dataset.;   
    %end;
    
    %if %nrbquote(&keepvars) eq %then %let keepvars=invid centreid;
    %else %if %qupcase(&keepvars) eq INVID %then %let keepvars=centreid;
    %else %if %qupcase(&keepvars) eq CENTREID %then %let keepvars=invid;
    %else %let invdset=;    
    
    %if %nrbquote(&invdset) ne %then   
    %do;                          
        proc sort data = %unquote(&invdset)  nodupkey
                  out  = &prefix._enrol (keep=studyid subjid &keepvars);
           by studyid subjid &keepvars;
        run;
        
        %let invdset=&prefix._enrol;
     %end; /* end-if on second %nrbquote(&invdset) ne */    
 %end; /* end-if on first %nrbquote(&invdset) ne */

 /*
 / Obtain RACECCD (Collected race code) variable from RACE dataset if it exists.
 / If there is more than one value for RACECCD for a subject, then we will
 / set RACECD to '99', otherwise set RACECD to RACECCD.
 / This value of RACECD will over-ride any value of RACECD found on the DEMO 
 / dataset.
 /----------------------------------------------------------------------------*/

 %if ( %nrbquote(&racedset) ne ) and %sysfunc(exist(%qscan(&racedset, 1, %str(%()))) %then
 %do;
    /* Subject race dataset exists */

    /* Obtain RACECCD (Collected race code) variable */
    proc sort data = %unquote(&racedset) 
              out  = &prefix._race(keep=studyid subjid raceccd) nodupkey;
         by studyid subjid raceccd;
    run;

    data &prefix._race2(drop=raceccd);
     set &prefix._race;
       by studyid subjid;
       length racecd $2;

       if first.subjid and last.subjid then racecd=raceccd;
       else racecd='99';

       if last.subjid then output;
    run;
 %end;  /* end-if Dataset &racedset exists.  */
 %else
 %do;
    %put %str(RTW)ARNING: &sysmacroname: The dataset RACEDSET(=&racedset) is not given or does not exist.;
    %put %str(RTW)ARNING: &sysmacroname: The Collected Race Code (RACECCD) will not be used to derive the RACECD.;
 %end;  /* end-if  Dataset &racedset does not exist.  */

 /*
 / Merge common variables into input dataset to create final dataset.
 /----------------------------------------------------------------------------*/
 
 %if %nrbquote(&invdset) ne %then
 %do;
   %let exist_centid=CENTREID;
   %let exist_invid=INVID;
   
   data &prefix._invdsetexist;
      if 0 then set %unquote(&invdset);
   run;
   
   %if %tu_chkvarsexist(&prefix._main1, CENTREID) ne %then %let exist_centid=;
   %else %if %tu_chkvarsexist(&prefix._invdsetexist, CENTREID) ne %then %let exist_centid=;
   
   %if %tu_chkvarsexist(&prefix._main1, INVID) ne %then %let exist_invid=;
   %else %if %tu_chkvarsexist(&prefix._invdsetexist, INVID) ne %then %let exist_invid=;
 %end;
 
 data %unquote(&dsetout);
      merge &prefix._main1(in=a)
             %if %sysfunc(exist(&prefix._demo3)) %then
             %do;
                 &prefix._demo3
             %end;  /* end-if  Dataset &demodset exists.  */
             %if %sysfunc(exist(&prefix._race2)) %then
             %do;
                 &prefix._race2 
             %end;
             %if %nrbquote(&invdset) ne %then
             %do;
                 &invdset
                 %if %nrbquote(&exist_centid.&exist_invid) ne %then
                 %do;
                    (rename=(%if %nrbquote(&exist_centid) ne %then CENTREID=__centreid;
                             %if %nrbquote(&exist_invid) ne %then INVID=__invid; ));
                    drop %if %nrbquote(&exist_centid) ne %then __centreid;
                         %if %nrbquote(&exist_invid) ne %then __invid;                      
                 %end;
             %end;  /* end-if  Dataset &racedset exists.  */
      ;
      by studyid subjid;
      if a;

      /* Create Unique Subject ID as a concatenation of the Study ID */
      /* and the Subject ID padded with leading zeros.               */
      usubjid=trim(left(studyid))||'.'||put(subjid,z7.);
      
      /*
      / SL001:
      /
      / If DSETIN has multiple observations per subject, e.g. lab or vitals, 
      / then any (RTW)ARNING messages still should only be displayed once per
      / subject.
      / If CENTREID is present in DSETIN but missing in ENROL/INVESTIG, then
      / the value of CENTREID from DSETIN should be kept for all observations
      / for any given subject, not just the first observation for that subject.
      / For any other scenario where CENTREID from DSETIN does not match 
      / CENTREID from ENROL/INVESTIG, the value of CENTREID from ENROL/INVESTIG
      / takes precedence.
      / The above logic for CENTREID also applies to INVID.
      /-----------------------------------------------------------------------*/

      %if %nrbquote(&exist_centid) ne %then
      %do;
         if missing(__centreid) and (not missing(CENTREID)) then
         do;
           if first.subjid then
           do;
             put "RTW" "ARNING: &sysmacroname: " "CENTREID is missing in ENROLDSET(=&enroldset) " "or INVESTIGDSET(=&investigdset) ";
             put "RTW" "ARNING: &sysmacroname: " "but not missing in input data set " "for " subjid=". CENTREID in input data set will be kept.";
           end;
         end;
         else if __centreid ne CENTREID then
         do;
           if first.subjid then
           do;
             put "RTW" "ARNING: &sysmacroname: " "CENTREID in ENROLDSET(=&enroldset) or " "INVESTIGDSET(=&investigdset) ";
             put "RTW" "ARNING: &sysmacroname: " "does not match the one in input data set " "for " subjid=". CENTREID in input data set will be overwritten."; 
           end;
           CENTREID=__centreid;
         end;                  
      %end; /* %if %nrbquote(&exist_centid) ne */
      
      %if %nrbquote(&exist_invid) ne %then
      %do;
         if missing(__invid) and (not missing(INVID)) then
         do;
           if first.subjid then
           do;
             put "RTW" "ARNING: &sysmacroname: " "INVID is missing in ENROLDSET(=&enroldset) " "or INVESTIGDSET(=&investigdset) ";
             put "RTW" "ARNING: &sysmacroname: " "but not missing in input data set " "for " subjid=". INVID in input data set will be kept.";
           end;
         end;
         else if __invid ne INVID then
         do;
           if first.subjid then
           do;
             put "RTW" "ARNING: &sysmacroname: " "INVID in ENROLDSET(=&enroldset) or " "INVESTIGDSET(=&investigdset) ";
             put "RTW" "ARNING: &sysmacroname: " "does not match the one in input data set " "for " subjid=". INVID in input data set will be overwritten.";            
           end;
           INVID=__invid;
         end;                  
      %end; /* %if %nrbquote(&exist_invid) ne */
 run;

 /*
 / Delete temporary datasets used in this macro.
 /----------------------------------------------------------------------------*/

 %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tu_common;

