/******************************************************************************* 
|
| Macro Name:      tu_cr8dmpk.sas
|
| Macro Version:   1.0
|
| SAS Version:     8.2
|
| Created By:      Andrew Ratcliffe
|
| Date:            09-Dec-2004
|
| Macro Purpose:   This macro shall create the equivalent of a DM PK dataset 
|                  from an SI/SPECTRE PK dataset, i.e. create equivalent of 
|                  ET-Tool output. 
|
| Macro Design:    PROCEDURE STYLE MACRO
| 
| Input Parameters:
|
| NAME              DESCRIPTION                              OPT/REQ   DEFAULT 
| DSETIN            Specifies the name of the input SI PK    Req       [blank]
|                   dataset 
|
| DSETOUT           Specifies the name of the DM PK output   Req       [blank]
|                   dataset to be created 
|
| REFDATEOPTION     Passed as %tu_common's parameter of      Opt       Treat
|                   the same name 
|
| REFDATEVISITNUM   Passed as %tu_common's parameter of      Opt       [blank]
|                   the same name 
|
| REFDATESOURCEDSET Passed as %tu_common's parameter of      Opt       [blank]
|                   the same name 
|
| REFDATESOURCEVAR  Passed as %tu_common's parameter of      Opt       [blank]
|                   the same name 
|
| REFDATEDSETSUBSET Passed as %tu_common's parameter of      Opt       [blank]
|                   the same name 
|
| TRTCDINF          Passed as %tu_rantrt's parameter of      Opt       [blank]
|                   the same name 
|
| PTRTCDINF         Passed as %tu_rantrt's parameter of      Opt       [blank]
|                   the same name 
| 
| Output: A DM PK dataset
|
| Global macro variables created:  None
|
| Macros called:
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_chknames
| (@) tu_chkvarsexist
| (@) tu_readdsplan
| (@) tu_common
| (@) tu_decode
| (@) tu_rantrt
| (@) tu_timslc
| (@) tu_isvarindsplan
| (@) tu_tidyup
| (@) tu_abort
|
| Examples:
|
|   %tu_cr8dmpk(DSETIN= sipk
|              ,DSETOUT= work.dmpk
|              );
|
|******************************************************************************* 
| Change Log 
|
| Modified By: Andrew Ratcliffe
| Date of Modification: 09-Dec-2004
| New version number: 1/2
| Modification ID: 
| Reason For Modification: Response to formal SCR:
|                          1) Change various styles of comment to a single style
|                          2) Add comments to specified do-end pairs
|                          3) Add parentheses to specified IF condition
|                          4) Change macro creation date
|
| Modified By: Andrew Ratcliffe
| Date of Modification: 25-Jan-2005
| New version number: 1/3
| Modification ID: 
| Reason For Modification: Handle situation whereby dsplan has no sort vars.
|                          Cannot create attypecd if no pctyp in the dataset.
|                          Derive ATTYPE.
|
| Modified By:             Andrew Ratcliffe
| Date of Modification:    04-Feb-2005
| New version number:      1/4
| Modification ID:         
| Reason For Modification: Reverse the order of calls to %tu_timslc and %tu_rantrt
|                           so that timslc is called before rantrt so that pernum
|                           can be added to dataset passed to rantrt and thus rantrt
|                           can derive ptrt vars.
|
| Modified By:              
| Date of Modification:     
| New version number:       
| Modification ID: 
| Reason For Modification:  
|
********************************************************************************/ 

%macro tu_cr8dmpk(DSETIN =              /* type:ID Name of input SI PK dataset */
                 ,DSETOUT =             /* Output dataset */
                 ,REFDATEOPTION = Treat /* Passed as %tu_common's parameter of the same name */
                 ,REFDATEVISITNUM =     /* Passed as %tu_common's parameter of the same name */
                 ,REFDATESOURCEDSET =   /* Passed as %tu_common's parameter of the same name */
                 ,REFDATESOURCEVAR =    /* Passed as %tu_common's parameter of the same name */
                 ,REFDATEDSETSUBSET =   /* Passed as %tu_common's parameter of the same name */
                 ,TRTCDINF =            /* Passed as %tu_rantrt's parameter of the same name */
                 ,PTRTCDINF =           /* Passed as %tu_rantrt's parameter of the same name */
                 );

  /* Echo values of parameters and global macro variables to the log */
  %local MacroVersion;
  %let MacroVersion = 1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_dsplanfile) 

  %local prefix;
  %let prefix = _cr8dmpk;

  %local __debug_obs;
  %if &g_debug ge 3 %then %let __debug_obs=obs=max;
  %else                   %let __debug_obs=obs=100;

  /* Begin with parameter validation */

  /* Check that DSETIN exists */
  %if not %sysfunc(exist(&dsetin)) %then
  %do;
    %put RTE%str(RROR): &sysmacroname: DSETIN (&dsetin) does not exist;
    %let g_abort = 1;
  %end;

  /* Check that DSETOUT is a valid dataset name (%tu_chknames) */
  %if %length(%tu_chknames(&dsetout,DATA)) %then
  %do;
    %put RTE%str(RROR): &sysmacroname: DSETOUT (&dsetout) is not a valid dataset name;
    %let g_abort = 1;
  %end;

  /* Abort if there were any problems */
  %tu_abort;

  /* Now do normal processing */

  /*
  / Plan of attack:                                                
  / 1. Load HARP dataset plan file into a dataset for subsequent   
  /    use (%tu_readdsplan)                                        
  / 2. Add common variables (%tu_common)                           
  / 3. Add decodes that are in the dataset plan (%tu_decode)       
  / 4. If one or more of (ptm, pernum, period, stagenum, stage)    
  /    are in the dataset plan, add time-slicing variables         
  /    (%tu_timslc)                                                
  / 5. If one or more of (trtgrp, trtcd, atrtgrp, atrtcd, ptrtgrp, 
  /    ptrtcd, patrtgrp, patrtcd) are in the dataset plan, add     
  /    treatment variables (%tu_rantrt)                            
  / 6. If they are in the dataset plan, calculate ATTYPECD and ATTYPE
  / 7. Re-order the variables in the dataset as per dataset plan   
  /    (VARORDER variable)                                         
  / 8. Sort the dataset as per dataset plan (SORTORDER variable)   
  / 9. Remove any temporary datasets (%tu_tidyup)                  
  / 10. Call %tu_abort()                                           
  /------------------------------------------------------*/

  /*
  / Begin by defining a local macro variable to keep track of
  / the latest and greatest dataset
  /------------------------------------------------------*/
  %local currentDataset;
  %let currentDataset = &dsetin;

  /*
  / 1. Load HARP dataset plan file into a dataset for subsequent   
  /    use (%tu_readdsplan)                                        
  /------------------------------------------------------*/
  %tu_readdsplan(dsetout=work.&prefix._dsplan);

  /*
  / 2. Add common variables (%tu_common)                           
  /
  / 2.1 Pass AGEMONTHSYN, AGEWEEKSYN, AGEDAYSYN, REFDATEOPTION, 
  /     REFDATEVISITNUM, REFDATESOURCEDSET, REFDATESOURCEVAR, and 
  /     REFDATEDSETSUBSET parameters
  / 2.1.1 AGEMONTHSYN is dependant upon the existence of AGEMO in 
  /       the dataset plan. Pass Y if AGEMO is in the dataset plan 
  / 2.1.2 AGEWEEKSYN is dependant upon the existence of AGEWK in 
  /       the dataset plan. Pass Y if AGEWK is in the dataset plan
  / 2.1.3 AGEDAYSYN is dependant upon the existence of AGEDY in the 
  /       dataset plan. Pass Y if AGEDY is in the dataset plan
  / 2.2 Pass %tu_cr8dmpk's DSETIN as DSETIN
  /------------------------------------------------------*/
  %local agemonthsyn ageweeksyn agedaysyn;
  %let AGEMONTHSYN = N;
  %let AGEWEEKSYN = N;
  %let AGEDAYSYN = N;
   
  data _null_;
    set &prefix._dsplan;
    select (varname);
      when ('AGEMO') call symput('AGEMONTHSYN','Y');
      when ('AGEWK') call symput('AGEWEEKSYN','Y');
      when ('AGEDY') call symput('AGEDAYSYN','Y');
      otherwise;
    end;
  run;

  %tu_common(dsetin            = &currentDataset
            ,dsetout           = work.&prefix._commonout
            ,AGEMONTHSYN       = &AGEMONTHSYN
            ,AGEWEEKSYN        = &AGEWEEKSYN
            ,AGEDAYSYN         = &AGEDAYSYN
            ,REFDATEOPTION     = &REFDATEOPTION
            ,REFDATEVISITNUM   = &REFDATEVISITNUM
            ,REFDATESOURCEDSET = &REFDATESOURCEDSET
            ,REFDATESOURCEVAR  = &REFDATESOURCEVAR
            ,REFDATEDSETSUBSET = &REFDATEDSETSUBSET
            );

  %let currentDataset = work.&prefix._commonout;

  %if &g_debug ge 1 %then
  %do;
    title "RTD" "EBUG: &sysmacroname: Output dataset (&currentDataset) "
          'from %TU_COMMON';
    proc contents data=&currentDataset;
    run;
  %end;
  %if &g_debug ge 2 %then
  %do;
    title "RTD" "EBUG: &sysmacroname: Output dataset (&currentDataset, &__debug_obs) "
          'from %TU_COMMON';
    proc print data=&currentDataset (&__debug_obs);
    run;
  %end;

  /*
  / 3. Add decodes that are in the dataset plan (%tu_decode)       
  /
  / 3.0 Rename PK vars to PC vars so that they are found in Plan
  / 3.1 Pass the name and location of the dataset plan 
  /     (&g_dsplanfile) to %tu_decode's DSPLAN parameter
  / 3.2 There shall be no need to use %tu_decode's FORMATNAMESDSET 
  /     and DECODERENAME parameters
  / 3.3 Re-rename the PC vars back to PK
  /------------------------------------------------------*/

  /*
  / 3.0 Rename PK vars to PC vars so that they are found in Plan 
  / Prepare renames 
  /------------------------------------------------------*/
  %if not %index(&currentDataset,.) %then
  %do;
    %let currentDataset = work.&currentDataset;
  %end;

  %local renames renamesback;
  data _null_;
    set sashelp.vcolumn;
    where libname eq "%upcase(%scan(&currentdataset,1,.))"
          and memname eq "%upcase(%scan(&currentdataset,2,.))"
          ;
    length pcname $32
           renames renamesback $400;
    retain renames renamesback;
    drop pcname;

    if "PK" eq: upcase(name) then
    do;
      pcname = name;
      substr(pcname,1,2) = 'PC';
      renames     = trim(renames)     !! " " !! trim(name) !! "=" !! pcname;
      renamesback = trim(renamesback) !! " " !! trim(pcname) !! "=" !! name;
    end;

    call symput('RENAMES',renames);
    call symput('RENAMESBACK',renamesback);
  run;
  %if &g_debug ge 1 %then
  %do;
    %put RT%str(DEB)UG: &sysmacroname: RENAMES=&renames;
    %put RT%str(DEB)UG: &sysmacroname: RENAMESBACK=&renamesback;
  %end;

  proc datasets lib=%scan(&currentdataset,1,.) nolist;
    modify %scan(&currentdataset,2,.);
    rename &renames;
  quit;
  
  /*
  / 3.1 Pass the name and location of the dataset plan 
  /     (&g_dsplanfile) to %tu_decode's DSPLAN parameter
  / 3.2 There shall be no need to use %tu_decode's FORMATNAMESDSET 
  /     and DECODERENAME parameters
  /------------------------------------------------------*/
  %tu_decode(dsetin=&currentDataset
            ,dsetout=work.&prefix._decodeout
            ,dsplan=&g_dsplanfile
            );

  %if &g_debug ge 1 %then
  %do;
    title "RTD" "EBUG: &sysmacroname: Output dataset (work.&prefix._decodeout)"
          'from %TU_DECODE';
    proc contents data=work.&prefix._decodeout;
    run;
  %end;
  %if &g_debug ge 2 %then
  %do;
    title "RTD" "EBUG: &sysmacroname: Output dataset (work.&prefix._decodeout, &__debug_obs) "
          'from %TU_DECODE';
    proc print data=work.&prefix._decodeout(&__debug_obs);
    run;
  %end;

  /* 3.3 Re-rename the PC vars back to PK */
  proc datasets lib=work nolist;
    modify &prefix._decodeout;
    rename &renamesback;
  quit;
  
  %let currentDataset = work.&prefix._decodeout;
 
  %if &g_debug ge 1 %then
  %do;
    title "RTD" "EBUG: &sysmacroname: Final output dataset (&currentDataset) "
          'from %TU_DECODE';
    proc contents data=&currentDataset;
    run;
  %end;

  %if &g_debug ge 2 %then
  %do;
    title "RTD" "EBUG: &sysmacroname: Final Output dataset (&currentDataset, &__debug_obs) "
          'from %TU_DECODE';
    proc print data=&currentDataset (&__debug_obs);
    run;
  %end;

  /*
  / 4. If one or more of (ptm, pernum, period, stagenum, stage)    
  /     are in the dataset plan, add time-slicing variables        
  /     (%tu_timslc)                                               
  /
  / 4.1 Pass DSETOUT from previous macro to DSETIN
  /------------------------------------------------------*/
  %local WantSlice;
  %let WantSlice=N;
  data _null_;
    set work.&prefix._dsplan;
    where varname in ('PTM', 'PERNUM', 'PERIOD', 'STAGENUM', 
                      'STAGE'
                     );
    call symput('WANTSLICE','Y');
  run;

  %if &WantSlice eq Y %then
  %do;  /* Need to add timeslice vars */
    %tu_timslc(dsetin=&currentDataset
              ,dsetout=work.&prefix._timslcout
              );
    %let currentDataset = work.&prefix._timslcout;

    %if &g_debug ge 1 %then
    %do;
      title "RTD" "EBUG: &sysmacroname: Output dataset (&currentDataset) "
            'from %TU_TIMSLC';
      proc contents data=&currentDataset;
      run;
    %end;
    %if &g_debug ge 2 %then
    %do;
      title "RTD" "EBUG: &sysmacroname: Output dataset (&currentDataset, &__debug_obs) "
            'from %TU_TIMSLC';
      proc print data=&currentDataset (&__debug_obs);
      run;
    %end;
  %end; /* Need to add timeslice vars */

  /*
  / 5. If one or more of (trtgrp, trtcd, atrtgrp, atrtcd, ptrtgrp, 
  /    ptrtcd, patrtgrp, patrtcd) are in the dataset plan, add     
  /    treatment variables (%tu_rantrt)                            
  /
  / 5.1 Pass TRTCDINF and PTRTCDINF parameters
  / 5.2 Pass DSETOUT from previous macro to DSETIN
  /------------------------------------------------------*/
  %local WantTrt;
  %let WantTrt=N;
  data _null_;
    set work.&prefix._dsplan;
    where varname in ('TRTGRP', 'TRTCD', 'ATRTGRP', 'ATRTCD', 
                      'PTRTGRP', 'PTRTCD', 'PATRTGRP', 'PATRTCD'
                     );
    call symput('WANTTRT','Y');
  run;

  %if &WantTrt eq Y %then
  %do;  /* Need to add trt vars */
    %tu_rantrt(dsetin=&currentDataset
              ,dsetout=work.&prefix._rantrtout
              ,trtcdinf=&trtcdinf
              ,ptrtcdinf=&ptrtcdinf
              );
    %let currentDataset = work.&prefix._rantrtout;

    %if &g_debug ge 1 %then
    %do;
      title "RTD" "EBUG: &sysmacroname: Output dataset (&currentDataset) "
            'from %TU_RANTRT';
      proc contents data=&currentDataset;
      run;
    %end;

    %if &g_debug ge 2 %then
    %do;
      title "RTD" "EBUG: &sysmacroname: Output dataset (&currentDataset, &__debug_obs) "
            'from %TU_RANTRT';
      proc print data=&currentDataset (&__debug_obs);
      run;
    %end;

  %end; /* Need to add trt vars */

  /* 6. If they are in the dataset plan, calculate ATTYPECD and ATTYPE */

  /* Is ATTYPECD in the dsplan? */
  %local thisVar reqdVars varAttrib missingVars;
  %let thisVar = ATTYPECD;
  %let reqdVars = PTM PCTYP;
  %if Y eq %tu_isvarindsplan(dsetin=&prefix._dsplan,var=&thisVar,attribmvar=varAttrib) %then
  %do;  /* Var is in plan */
    %let missingVars = %tu_chkvarsexist(&currentDataset,&reqdVars);
    %if %length(&missingVars) gt 0 %then
    %do;
      %put RTE%str(RROR): &sysmacroname: Cannot derive &thisVar (as required by Dataset Plan) because source variables are missing: &missingVars;
      %tu_abort(option=force);
    %end;
    %else
    %do;  /* We have requisite var(s) too */

      data work.&prefix._attypecd10;
        set &currentDataset;
        attrib &thisVar &varAttrib;

        if upcase(pctyp) ne 'URINE' then
        do;  /* not URINE */

            /*
            / If PTM is "SCREENING" then set attypecd to 10 
            / Else if PTM is "PRE-DOSE" then set attypecd to 20 
            / Else if PTM is "FOLLOW-UP" then set attypecd to 70 
            /------------------------------------------------------*/

          select ;
            when (index(upcase(ptm),'SCREENING')) attypecd=10;
            when (index(upcase(ptm),'PRE'))  attypecd=20;
            when (index(upcase(ptm),'FOLLOW'))  attypecd=70;
            otherwise attypecd=50;
          end; /* select PTM */

        end; /* not URINE */
        else
        do;  /* URINE */

          /* If PTM contains the wording 'PRE-DOSE'  , attypecd=20. */
          if indexw(upcase(ptm),'PRE-DOSE') then
            attypecd=20;

          else
          do;  /* not pre-dose */

            /*
            / If visit has a negative day,  
            / i.e. visit='Day -1'  or 'Day -2'  
            / We will need to code attypecd=20.
            /------------------------------------------------------*/
            drop word2 word1;
            word2 = upcase(scan(ptm,-2));
            word1 = input(scan(ptm,-1),??best.);
            if (word2 eq 'DAY') and (. < word1 < 0) then
              attypecd=20;

            else
              /* On treatment, because it is usually collected during a day of treatment */
              attypecd=50;

          end; /* not pre-dose */

        end; /* URINE */
      run;

      %let currentDataset = work.&prefix._attypecd10;

    %end; /* We have requisite var(s) too */
  %end; /* Var is in plan */

  /* Is ATTYPE in the dsplan? */
  %local thisVar reqdVars varAttrib missingVars;
  %let thisVar = ATTYPE;
  %let reqdVars = ATTYPECD;
  %if Y eq %tu_isvarindsplan(dsetin=&prefix._dsplan,var=&thisVar,attribmvar=varAttrib) %then
  %do;  /* Var is in plan */
    %let missingVars = %tu_chkvarsexist(&currentDataset,&reqdVars);
    %if %length(&missingVars) gt 0 %then
    %do;
      %put RTE%str(RROR): &sysmacroname: Cannot derive &thisVar (as required by Dataset Plan) because source variables are missing: &missingVars;
      %tu_abort(option=force);
    %end;
    %else
    %do;  /* We have requisite var(s) too */

      data work.&prefix._attype10;
        set &currentDataset;
        attrib &thisVar &varAttrib;
        select (attypecd);
          when(10) attype="PRE-STUDY";
          when(20) attype="PRE-TREATMENT";
          when(50) attype="TREATMENT";
          when(70) attype="FOLLOW-UP";
        end;
      run;

      %let currentDataset = work.&prefix._attype10;

    %end; /* We have requisite var(s) too */
  %end; /* Var is in plan */

  /*
  / 7. Re-order the variables in the dataset as per dataset plan   
  /     (VARORDER variable)                                        
  /------------------------------------------------------*/
  %local varorder;
  proc contents data=&currentDataset 
                out=work.&prefix._vocont 
                noprint;
  run;

  proc sql noprint;
               /* Trim-down the Plan so that it only has DM variables in it */
    create view work.&prefix._dsplanDMvo as
      select dsplan.*
      from work.&prefix._vocont vocont 
           left join 
           work.&prefix._dsplan dsplan
      on upcase(vocont.name) eq upcase(dsplan.varname)
      ;
               /* Make a numeric sortable variable, and sort dataset accordingly */
    create view work.&prefix._dsplanbyvarorder10 as
      select varname,
             inputn(varorder,'BEST.') as varordern
      from work.&prefix._dsplanDMvo
      where varorder ne ''
      order by varordern
      ;
               /* Create macro var with var names in correct order */
    select varname into : varorder separated by ' '
      from work.&prefix._dsplanbyvarorder10
      ;
  quit;
  %if &g_debug ge 1 %then
    %put RT%str(DEB)UG: &sysmacroname: Variable order for dataset shall be: &varorder;

                    /*
                    / Use retain statement to re-order the variables. This is 
                    / favoured because it does not require the specification  
                    / of any variable attributes. It does not retain any      
                    / value.                                                  
                    / Ref: SAS Usage Note SN-008395                           
                    /------------------------------------------------------*/

  data work.&prefix._varorder10;
    retain &varorder;
    set &currentDataset;
  run;
  %let currentDataset = work.&prefix._varorder10;

  /* 8. Sort the dataset as per dataset plan (SORTORDER variable) */
  %local sortorder;
  proc contents data=&currentDataset 
                out=work.&prefix._socont 
                noprint;
  run;

  proc sql noprint;
               /* Trim-down the Plan so that it only has DM variables in it */
    create view work.&prefix._dsplanDMso as
      select dsplan.*
      from work.&prefix._socont socont 
           left join 
           work.&prefix._dsplan dsplan
      on upcase(socont.name) eq upcase(dsplan.varname)
      ;
               /* Make a numeric sortable variable, and sort dataset accordingly */
    create view work.&prefix._dsplanbysortorder10 as
      select varname, 
             inputn(sortorder,'BEST.') as sortordern
      from work.&prefix._dsplanDMso
      where sortorder ne ''
      order by sortordern
      ;
               /* Create macro var with var names in correct order */
    select varname into : sortorder separated by ' '
      from work.&prefix._dsplanbysortorder10
      ;
  quit;
  %if &g_debug ge 1 %then
    %put RT%str(DEB)UG: &sysmacroname: Sort order for dataset shall be: &sortorder;

  %if %length(&sortorder) gt 0 %then
  %do;  /* Do the sort */
    proc sort data=&currentDataset out=&dsetout;
      by &sortorder;
    run;
  %end; /* Do the sort */
  %else
  %do;  /* No sort */
    data &dsetout;
      set &currentDataset;
    run;
  %end; /* No sort */

  %if &g_debug ge 1 %then
  %do;
    title RTDEBUG: Dataset Output from CR8DMPK;
    proc contents data=&dsetout;
    run;
  %end;

  /* 9. Remove any temporary datasets (%tu_tidyup) */
  %tu_tidyup(rmdset=&prefix:
            ,glbmac=NONE
            );
  quit;

  /* 10.Call %tu_abort() */
  %tu_abort;

%mend tu_cr8dmpk;   
