/*******************************************************************************
|
| Macro Name:      tu_rantrt
|
| Macro Version:   3
|
| SAS Version:     8.2
|
| Created By:      Mark Luff / Eric Simms
|
| Date:            14-May-2004
|
| Macro Purpose:   Add treatment variables to a dataset.
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME              DESCRIPTION                             REQ/OPT  DEFAULT
| ----------------  --------------------------------------  -------  ----------
| DSETIN            Specifies the dataset for which the      REQ     (Blank) 
|                   new variable containing the period day 
|                   is to be added.  
|                   Valid values: valid dataset name                     
|
| DSETOUT           Specifies the name of the output         REQ     (Blank) 
|                   to be created.                  
|                   Valid values: valid dataset name
|
| PTRTCDINF         Informat to derive PTRTCD from PTRTGRP   OPT     (Blank)
|
| RANDALLDSET	    Specifies the RandAll SI dataset which   REQ     dmdata.randall
|                   will be used along with the &RANDDSET 
|                   datasets to add treatment information 
|                   to input data set
|                   Valid values: valid dataset name
| 
| RANDDSET          Specifies the Rand SI dataset which will REQ     dmdata.rand
|                   be used along with the &RANDALLDSET 
|                   datasets to add treatment information to 
|                   input data set
|                   Valid values: valid dataset name
|
| TRTCDINF          Informat to derive TRTCD from TRTGRP     OPT     (Blank)
| 
| ----------------  --------------------------------------  -------  ----------
|
| The macro references the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETIN            Req      Parameter specified dataset
|
| DMDATA.RAND        Opt      SI dataset containing Randomisation Reference Panel data
| DMDATA.RANDALL     Opt      SI dataset containing Data extracted from the RandAll system
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
|(@) tu_abort
|(@) tu_chkvarsexist
|(@) tr_putlocals
|(@) tu_putglobals
|(@) tu_tidyup
|
| Example:
|    %tu_rantrt(
|         dsetin    = _ae1,
|         dsetout   = _ae2,
|         ptrtcdinf = ptrtfmt
|         );
|
|    where ptrtfmt was previously defined as an informat, e.g.
|
|         proc format;
|            invalue ptrtfmt
|               'A' = 3
|               'B' = 1
|               'C' = 2;
|         run;
|
|    which would result in records with PTRTGRP of A or B or C being assigned 
|    a PTRTCD of 3,1,2 respectively (if PTRTCD was not already present on the 
|    input dataset). Since TRTCDINF has not been defined, the TRTCD field will
|    be assigned values of 1,2,3,... in the alphabetical order of TRTGRP (if
|    TRTCD was not already present on the input dataset).
|
|******************************************************************************
| Change Log
|
| Modified By: Eric Simms
| Date of Modification: 02Dec04
| New version/draft number: 1/2
| Modification ID: ems001
| Reason For Modification: When merging RAND and RANDALL, keep only matches and
|                          write warning messages for non-matches.
|
| Modified By: Eric Simms
| Date of Modification: 02Dec04
| New version/draft number: 1/2
| Modification ID: ems002
| Reason For Modification: Test DMDATA.RANDALL.TRTGRP for missing values. If   
|                          found, write error message and abort. Do the same
|                          for DMDATA.RANDALL.PTRTGRP.
|
| Modified By: Eric Simms
| Date of Modification: 02Dec04
| New version/draft number: 1/2
| Modification ID: ems003
| Reason For Modification: Assign a missing value to TRTCD if the SUBJID in 
|                          &DSETIN did not have a match in (DMDATA.RAND inner
|                          join DMDATA.RANDALL on RANDNUM). Also, if PERNUM
|                          exists on the input dataset, assign a missing value
|                          to PTRTCD if the SUBJID in &DSETIN did not have a
|                          match in (DMDATA.RAND inner join DMDATA.RANDALL on
|                          RANDNUM).
|                          NOTE: a lot of this was modified due to 
|                                Modification ID ems005.
|
| Modified By: Eric Simms
| Date of Modification: 09Dec04
| New version/draft number: 1/2
| Modification ID: ems004
| Reason For Modification: Use nodupkey in RANDALL and RAND sort. Keep PERNUM and 
|                          PTRTGRP from RANDALL only if PERNUM is on the DSETIN
|                          dataset.
|
| Modified By: Eric Simms
| Date of Modification: 14Dec04
| New version/draft number: 1/3
| Modification ID: ems005
| Reason For Modification: Re-written in order to assign TRTCD and PTRTCD based on
|                          TRTGRP and PTRTGRP found in DMDATA.RANDALL regardless
|                          if these TRTGRP/PTRTGRP will appear in output dataset.
|
| Modified By: Eric Simms
| Date of Modification: 15Dec04
| New version/draft number: 1/4
| Modification ID: ems006
| Reason For Modification: Added test to determine if PERNUM needs to exist on the
|                          input dataset. 
|
| Modified By:              Yongwei Wang
| Date of Modification:     12Jan2005
| New version/draft number: 1/5
| Modification ID:          YW001
| Reason For Modification:  1.If only one value of PERNUM in RANDALL, PERNUM 
|                             should not be used in merge.
|                           2.If PERNUM is not in input data set and has multiple 
|                             values, the TRTCD and TRTGRP also need to be merged 
|                             to &DSETIN because TRTCD and TRTGRP do not depend 
|                             on PERNUM. 
|                           3.Removed the changes of ems006.
|
| Modified By:              Yongwei Wang
| Date of Modification:     18Jan2005
| New version/draft number: 1/6
| Modification ID:          YW002
| Reason For Modification:  1.Removed RTWARNING message for subjid in RANDALL
|                             but not in RAND.
|                           2.Add TRTGRP and TRTCD to &dsetin the same way 
|                             no matter PERNUM exist or not.
|
| Modified By:              Yongwei Wang
| Date of Modification:     21Sep2005
| New version/draft number: 2/1
| Modification ID:          YW003
| Reason For Modification:  Requested by request form HRT0090
|                           1.Added two new parameters: RANDDSET/RANDDALLDSET.
|                           2.Modified normal process to merge TPTRTCD/TPTRTGRP 
|                             and TPATRTCD/TPATRTGRP. They will be merged the 
|                             same way as PTRTCD/PTRTGRP and PATRTCD/PATRTGRP,
|                             but by PERNUM=TPERNUM in &dsetin when merge.
|
| Modified By:              Yongwei Wang
| Date of Modification:     08Oct2005
| New version/draft number: 2/2
| Modification ID:          YW004
| Reason For Modification:  Changed all TPATRTGRP to TPATRTGP after UAT
|
| Modified By:              Shan Lee
| Date of Modification:     06Nov2007
| New version/draft number: 3/1
| Modification ID:          SL001
| Reason For Modification:  Allow dataset options to be specified with dataset
|                           names - HRT0184.
|                           Remove unnecessary RTW ARNINGs, and write RTN OTE if
|                           treatment code is assigned by alphabetical ordering
|                           of TRTGRP - HRT0173.
|                           Also suppress RTW ARNINGs when the period number
|                           corresponds to screening or follow-up, as there 
|                           would not be any treatment information corresponding
|                           to these periods.
|                           If RANDALLDSET is blank, then assume that the study
|                           is open label.
|
*******************************************************************************/

%macro tu_rantrt (
     dsetin      = ,      /* Input dataset name */
     dsetout     = ,      /* Output dataset name */
     ptrtcdinf   = ,      /* Informat to derive PTRTCD from PTRTGRP */
     randalldset = dmdata.randall, /* RAND data set name */
     randdset    = dmdata.rand, /* RANDALL data set name */
     trtcdinf    =        /* Informat to derive TRTCD from TRTGRP */
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
 
 %local listvars loopi thisvar;
 
 /*
 / Check that none of required parameters is blank. 
 / RANDALLDSET is no longer a required parameter: if it is blank, then we will
 / assume that the study is open label, so we do not need to obtain treatment
 / information from RANDALLDSET. SL001
 /----------------------------------------------------------------------------*/
 
 %let listvars=DSETIN DSETOUT RANDDSET; 
  
 %do loopi=1 %to 3;
    %let thisvar=%scan(&listvars, &loopi, %str( ));
    %let &thisvar=%nrbquote(&&&thisvar);
    
    %if &&&thisvar eq %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: Parameter &thisvar is blank.;
       %let g_abort=1;
    %end;    
 %end;  /* end of do-to loop */

 /*
 / Check that dataset &DSETIN exists.
 / Allow dataset options to be specified - SL001. 
 /----------------------------------------------------------------------------*/

 %if &dsetin ne %then
 %do;
    %if %sysfunc(exist(%qscan(&dsetin, 1, %str(%()))) eq 0 %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: Dataset DSETIN(=&dsetin) does not exist.;
       %let g_abort=1;
    %end;  
 %end; /* &dsetin ne */

 /*
 / Check that any specified trtcdinf/ptrtcdinf informats exist.
 /----------------------------------------------------------------------------*/

 %let trtcdinf  = %nrbquote(&trtcdinf);
 %let ptrtcdinf = %nrbquote(&ptrtcdinf);

 %if &trtcdinf ne  %then
 %do;
    proc sql noprint;
      select * from dictionary.catalogs
      where upcase(objname) eq "%upcase(&trtcdinf)" and objtype eq "INFMT";
    quit;

    %if &sqlobs eq 0 %then
    %do;
      %put %str(RTE)RROR: TU_RANTRT: The informat TRTCDINF(=&trtcdinf) does not exist.;
    %let g_abort=1;
    %end;  /* end-if  specified informat TRTCDINF does not exist.  */
 %end;     /* end-if  informat TRTCDINF was specified.     */  

 %if &ptrtcdinf ne  %then
 %do;
    proc sql noprint;
      select * from dictionary.catalogs
      where upcase(objname) eq "%upcase(&ptrtcdinf)" and objtype eq "INFMT";
    quit;

    %if &sqlobs eq 0 %then
    %do;
      %put %str(RTE)RROR: TU_RANTRT: The informat PTRTCDINF(=&ptrtcdinf) does not exist.;
    %let g_abort=1;
    %end;  /* end-if  specified informat PTRTCDINF does not exist.  */
 %end;     /* end-if  informat PTRTCDINF was specified.  */

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;

 /*
 / If the input dataset name is the same as the output dataset name,
 / write a note to the log.
 / When comparing dataset names, ignore dataset options - SL001.
 /----------------------------------------------------------------------------*/

 %if %qscan(%upcase(&dsetin), 1, %str(%()) eq %qscan(%upcase(&dsetout), 1, %str(%()) %then
 %do;
    %put %str(RTN)OTE: TU_RANTRT: The input dataset name (&dsetin) is the same as the output dataset name (&dsetout).;
 %end;  /* end-if parameters values of DSETIN and DSETOUT  are the same.  */

 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/
   
 %local prefix;
 %let prefix = _rantrt;   /* Root name for temporary work datasets */
 
 data &prefix._dsetinexist;
    if 0 then set %unquote(&dsetin);
 run;

 /*
 / If the SI datasets DMDATA.RAND or DMDATA.RANDALL do not exist, write informational 
 / messages and set the output dataset to the input dataset as is. Otherwise,
 / add the treatment information (TRTGRP, PTRTGRP)) as per the DMDATA.RAND and 
 / DMDATA.RANDALL datasets.
 /
 / SL001 
 /
 / Allow dataset options to be specified.
 / If the parameter RANDALLDSET is blank, then it will be assumed that the
 / study is open label: TRTCD will be set to 1, but no other treatment 
 / information will be added in this case.
 /----------------------------------------------------------------------------*/

 %if %sysfunc(exist(%qscan(&randdset, 1, %str(%()))) eq 0 %then 
 %do;
    %put %str(RTW)ARNING: TU_RANTRT: Dataset RANDDSET(=&randdset) does not exist - treatment information not added.;

    data %unquote(&dsetout);
      set %unquote(&dsetin);
    run;
 %end;  /*  end-if  dataset DMDATA.RAND does not exist.  */

 %else %if %nrbquote(&randalldset) eq %then
 %do; 
    %put %str(RTN)OTE: TU_RANTRT: Parameter RANDALLDSET is blank, so assume open label - TRTCD set to 1, no other treatment information added.;

    data %unquote(&dsetout);
      length TRTGRP ATRTGRP $120;
      set %unquote(&dsetin);
      ATRTCD=1;
      TRTCD=1;
      TRTGRP="Treatment";
      ATRTGRP="Treatment";
      %if %tu_chkvarsexist(&prefix._dsetinexist, atrtgrp) ne %then
      %do;
          atrtgrp=trtgrp;
          atrtcd =trtcd;
      %end;  
    run;
 %end; /* end-if &randalldset is blank */
 
 %else %if %sysfunc(exist(%qscan(&randalldset, 1, %str(%()))) eq 0 %then 
 %do;
    %put %str(RTW)ARNING: TU_RANTRT: Dataset RANDALLDSET(=&randalldset) does not exist - treatment information not added.;
  
    data %unquote(&dsetout);
      set %unquote(&dsetin);
    run; 
 %end;  /* end-if  dataset DMDATA.RANDALL does not exist.  */ 
 
 %else
 %do;   /* DMDATA.RAND and DMDATA.RANDALL both exist */

    /*
    / YW001: get value level of PERNUM. If gt 1 and PERNUM is in &dsetin,  it is 
    /        a crossover study and PTRTGRP needs to be added.
    /----------------------------------------------------------------------------*/                  
    %let num_pernum=0; 
    proc sql noprint;
       select count(unique(pernum)) into :num_pernum
       from %unquote(&randalldset);
    quit;

    /*
    / EMS004: Check for use of pernum variable on input dataset.
    / YW003: Added EXIST_TPERNUM
    /----------------------------------------------------------------------------*/
                            
    %local exist_pernum exist_tpernum tptrtgrp;
    
    %if &num_pernum gt 1 %then 
    %do;
       %let exist_pernum=%tu_chkvarsexist(&prefix._dsetinexist, pernum);
    %end;
    %else %do;
       %let exist_pernum=PERNUM;
       %let exist_tpernum=TPERNUM;
       data _null_;
          set %unquote(&randalldset);
          if _n_ eq 1 then call symput('tptrtgrp', ptrtgrp);
          stop;
       run;       
    %end;
    
    %let exist_tpernum=%tu_chkvarsexist(&prefix._dsetinexist, tpernum);
   
    /*
    / Obtain RandAll data.
    / Note that we do not test for the existence of PERNUM on the RANDALL dataset.
    / It is a required variable and will always be there.
    / Allow dataset options to be specified - SL001.
    /----------------------------------------------------------------------------*/
  
    %if &exist_pernum eq  %then
    %do; 
       /* PERNUM variable exists on input dataset */
       proc sort data = %unquote(&randalldset) 
                 out  = &prefix._randall (keep=randnum pernum trtgrp ptrtgrp) nodupkey;
            by randnum pernum;
       run;
    %end; /* end-if PERNUM variable is on the input dataset */
    %else 
    %do; 
       /* PERNUM variable does not exist on input dataset */
       proc sort data = %unquote(&randalldset) 
                 out  = &prefix._randall (keep=randnum trtgrp) nodupkey;
            by randnum;
       run;
    %end; /* end-if PERNUM variable is not on the input dataset */
   
    /*
    / EMS002: 
    / Check that TRTGRP is non-blank. Otherwise write error messages and stop.
    / If PERNUM is on the input dataset, check that PTRTGRP is non-blank. Otherwise
    / write error messages and stop. (If PERNUM is not on the input dataset,
    / then PTRTGRP will not be used and it does not matter if it is blank or not.)
    /----------------------------------------------------------------------------*/

    data _null_;
      set &prefix._randall end=EOF;
      retain error_flag 0;

      if trtgrp eq '' then
      do;
         put "RTE" "RROR: TU_RANTRT: RANDALLDSET(=&randalldset) has blank TRTGRP for RANDNUM=" randnum;
         error_flag=1;
      end; /* end-if TRTGRP is missing. */
      %if &exist_pernum eq  %then
      %do;
         if ptrtgrp eq '' then
         do;
            put "RTE" "RROR: TU_RANTRT: RANDALLDSET(=&randalldset) has blank PTRTGRP for RANDNUM=" randnum "PERNUM=" pernum;
            error_flag=1;
         end; /* end-if PTRTGRP is missing. */
      %end; /* end-if PERNUM variable exists on input dataset. */

      if EOF then
      do;
         if error_flag then call symput('g_abort',1);
      end; /* end-if EOF */
    run;

    %if &g_abort eq 1 %then
    %do;
       %tu_abort;
    %end; /* end-if &g_abort eq 1 */

    /*
    / Assign TRTCD as defined by the informat passed in by parameter trtcdinf. If
    / an informat was not specified, then assign 1,2,3... based on ascending    
    / values of TRTGRP.
    / EMS005: Assign a missing value to TRTCD if TRTGRP is a missing
    / value (i.e. blank).
    / EMS005: This whole block of logic used to be done (v1b2) after everything
    / was merged onto the input dataset.
    / SL001: Include RTN-OTE when TRTCD is assigned by alphabetic ordering of
    / TRTGRP.
    /----------------------------------------------------------------------------*/
   
    %if &trtcdinf eq  %then
    %do;

       %put %str(RTN)OTE: &sysmacroname: TRTCDINF not specified, so TRTCD will be assigned according to alphabetic ordering of TRTGRP;

       proc sort data=&prefix._randall out=&prefix._cd1;
         by trtgrp;
       run;

       data &prefix._cd2(drop=trtcd_count);
         set &prefix._cd1;
         by trtgrp;
         retain trtcd_count 0;

         if trtgrp eq '' then 
         do;
            trtcd=.;
         end; /* end-if TRTGRP is missing. */
         else
         do;
            if first.trtgrp then trtcd_count+1;
            trtcd=trtcd_count;
         end; /* end-if TRTGRP not missing. */
       run;
    %end;  /* end-if  informat TRTCDINF not specified.  */
    %else
    %do;
       data &prefix._cd2;
         set &prefix._randall;
         trtcd=input(trtgrp, %upcase(&trtcdinf..));
       run;
    %end;  /* end-if  informat TRTCDINF was specified.  */

    /*
    / If PERNUM exists on the input dataset then assign PTRTCD as defined by the 
    / informat passed in by parameter PTRTCDINF. If an informat was not specified, 
    / then assign 1,2,3... based on ascending values of PTRTGRP.
    / EMS005: Assign a missing value to PTRTCD if PTRTGRP is a missing
    / value (i.e. blank).
    / EMS005: This whole block of logic used to be done (v1b2) after everything
    / was merged onto the input dataset.
    /
    / If PERNUM does not exist on the input dataset, then get the same temporary
    / dataset name as if it did exist in order to simplify later processing.
    /----------------------------------------------------------------------------*/
   
    %if &exist_pernum eq  %then
    %do; 
       %if &ptrtcdinf eq  %then
       %do;
          proc sort data=&prefix._cd2; 
            by ptrtgrp;
          run;
   
          data &prefix._cd3(drop=ptrtcd_count);
            set &prefix._cd2; 
            by ptrtgrp;
            retain ptrtcd_count 0;

            if ptrtgrp eq '' then 
            do;
               ptrtcd=.;
            end; /* end-if PTRTGRP is missing. */
            else
            do;
               if first.ptrtgrp then ptrtcd_count+1;
               ptrtcd=ptrtcd_count;
            end; /* end-if PTRTGRP is not missing. */
          run;
       %end;  /* end-if variable PERNUM exists but informat PTRTCDINF was not specified. */
       %else
       %do;
          data &prefix._cd3;
            set &prefix._cd2; 
            ptrtcd=input(ptrtgrp, %upcase(&ptrtcdinf..));
          run;
       %end; /* end-if variable PERNUM exists and informat PTRTCDINF was specified. */ 
    %end;   /* end-if  variable PERNUM exists.  */
    %else
    %do; 
          data &prefix._cd3;
            set &prefix._cd2;
          run;
    %end;  /* end-if  variable PERNUM does not exist.  */
   
    /*
    / Prepare for merge with dmdata.rand.
    / Note that we do not test for the existence of PERNUM on the RANDALL dataset.
    / It is a required variable and will always be there.
    /----------------------------------------------------------------------------*/
  
    %if &exist_pernum eq  %then
    %do; 
       /* PERNUM variable exists on input dataset */
       proc sort data = &prefix._cd3
                 out  = &prefix._randall2;
            by randnum pernum;
       run;
    %end; /* end-if PERNUM variable is on the input dataset */
    %else 
    %do; 
       /* PERNUM variable does not exist on input dataset */
       proc sort data = &prefix._cd3
                 out  = &prefix._randall2;
            by randnum;
       run;
    %end; /* end-if PERNUM variable is not on the input dataset */

    /*
    / Obtain randomisation reference panel data.
    / Allow dataset options - SL001.
    /----------------------------------------------------------------------------*/
   
    proc sort data = %unquote(&randdset) 
              out  = &prefix._rand (keep=studyid subjid randnum) nodupkey;
         by randnum;
    run;

    /*
    / Obtain Study ID and Subject ID.
    / EMS001: Only keep matches and put out warning messages for non-matches.
    / YW002:  Removed RTWARNING of if A and not B.
    /----------------------------------------------------------------------------*/

    data &prefix._rand_and_randall;
         merge &prefix._rand(in=A) &prefix._randall2(in=B);
         by randnum;
         if A and B then output;
         else if A then put "RTW" "ARNING: TU_RANTRT: RANDNUM=" randnum "on %upcase(&randdset) but not on " "RANDALLDSET(=&randalldset)";
    run;
        
    /*
    / If the PERNUM variable exists on the input dataset, then get TRTGRP, TRTCD,
    / PTRTGRP, PTRTCD from the merged RAND and RANDALL datasets. If the PERNUM variable
    / does not exist on the input dataset, then get just the TRTGRP, TRTCD variables
    / from the merged RAND and RANDALL datasets.
    / YW002: Changed to merge PTRTGRP and PTRTCD only.
    /----------------------------------------------------------------------------*/

    %if &exist_pernum eq  %then
    %do; 
         /* PERNUM variable exists on input dataset */
          
         proc sort data=&prefix._rand_and_randall out=&prefix._randall_sort2 
              (keep=studyid subjid ptrtgrp ptrtcd pernum) nodupkey;
               by studyid subjid pernum;
         run;
         
         proc sort data=%unquote(&dsetin) out=&prefix._dsetmerge; 
               by studyid subjid pernum;
         run;

         data &prefix._merged2;
             merge &prefix._dsetmerge(in=A) 
                   &prefix._randall_sort2(in=B);
             by studyid subjid pernum;

             /*
             / SL001
             /
             / Only necessary to generate one message per period, for periods where
             / treatment information is expected (i.e. not screening or follow-up).
             /--------------------------------------------------------------------*/

             if A and not B and first.pernum and not(pernum in (0 999)) then
             do;
               put "RTW" "ARNING: TU_RANTRT: STUDYID=" studyid "SUBJID=" subjid "PERNUM=" pernum "on DSETIN (=&dsetin)";
               put "RTW" "ARNING: TU_RANTRT: but not on (RANDDSET(=&randdset) " "inner join RANDALLDSET(=&randalldset) by RANDNUM).";
             end;
             
             IF A;
         run;
         
         /* 
         / YW003: If PERNUM and TPERNUM exist, rename PERNUM to TPERNUM, merge the 
         / treatment data set created above, into the modified input data set to add 
         / TPTRTCD=PTRTCD and TPTRTGRP=PTRTGRP, by STUDYID, SUBJID and TPERNUM, into 
         / the input data set. If TPERNUM equals 0, set TPTRTCD to 0 and set TPTRTGRP 
         / to 'Pre-Treatment' 
         /-----------------------------------------------------------------------------*/
         
         %if &exist_tpernum eq %then
         %do;
            proc sort data=&prefix._merged2 out=&prefix._dsetmerge; 
               by studyid subjid tpernum;
            run;
            
            data &prefix._merged2;
               merge &prefix._dsetmerge(in=A) 
                     &prefix._randall_sort2(in=B rename=(pernum=tpernum ptrtcd=tptrtcd ptrtgrp=tptrtgrp));
               by studyid subjid tpernum;               
               IF A;
               if tpernum eq 0 then 
               do;
                  tptrtcd=0;
                  tptrtgrp='Pre-Treatment';
               end;
            run;                           
         %end; /* &exist_tpernum eq */

    %end; /* &exist_pernum eq */
    %else %do;
         proc sort data=%unquote(&dsetin) out=&prefix._merged2;
            by studyid subjid;
         run;
         
         /*
         / YW003:
         / For PG study, set TPTRTGRP to 'Pre-Treatment' if tpernum equals 0;
         / to period treatment group, if tpernum is great then 0;
         / to missing if tpernum is missing
         /-------------------------------------------------------------------*/  
         %if &exist_tpernum eq %then
         %do;
            data &prefix._merged2;
               length tptrtgrp $200;
               set &prefix._merged2;
               if missing(tpernum) then
               do;
                  tptrtcd=.;
                  tptrtgrp='';
               end;
               else if tpernum eq 0 then
               do;
                  tptrtcd=0;
                  tptrtgrp='Pre-Treatment';                
               end;
               else do;
                  tptrtcd=1;
                  tptrtgrp=symget('tptrtgrp');
               end;
            run;
         %end;
         
    %end; /* end-if PERNUM variable exists on input dataset */
    
    /* 
    /  YW002: merge TRTCD in no matter PERNUM variable exists or not
    /----------------------------------------------------------------------------*/

    proc sort data=&prefix._rand_and_randall(keep=studyid subjid trtgrp trtcd) 
          out=&prefix._randall_sort nodupkey;
         by studyid subjid ;
    run;
    
 /*
 / Assign ATRTGRP (regardless of existance of PERNUM) and PATRTGRP (if PERNUM 
 / exists on input dataset). Note that if ATRTGRP already exists on the input
 / dataset then it is not over-written, and if PATRTGRP already exists on the
 / input dataset then it is not over-written.
 /----------------------------------------------------------------------------*/
   
    data %unquote(&dsetout);
         merge &prefix._merged2 (in=A)
               &prefix._randall_sort (in=B);
         by studyid subjid;

         /*
         / SL001
         /
         / Only necessary to generate one message per subject.
         /--------------------------------------------------------------------*/

         if A and ( not B ) and first.subjid then
         do;
           put "RTW" "ARNING: TU_RANTRT: STUDYID=" studyid "SUBJID=" subjid "on DSETIN (&dsetin)";
           put "RTW" "ARNING: TU_RANTRT: but not on (RANDDSET(=&randdset) " "inner join RANDALLDSET(=&randalldset) by RANDNUM).";
         end;
         
         if A;

         /* ATRTGRP defaulted as a copy of TRTGRP if it is not already present on the dataset. */
         /* In addition, if ATRTGRP is set to TRTGRP, then ATRTCD is set to TRTCD.             */
         %if %tu_chkvarsexist(&prefix._dsetinexist, atrtgrp) ne %then 
         %do;
             atrtgrp=trtgrp;
             atrtcd =trtcd;
         %end;  
        
         %if &exist_pernum eq  %then
         %do; 
            /* PATRTGRP defaulted as a copy of PTRTGRP if it is not already present on the dataset.*/
            /* In addition, if PATRTGRP is set to PTRTGRP, then PATRTCD is set to PTRTCD.          */
            %if %tu_chkvarsexist(&prefix._dsetinexist, patrtgrp) ne %then  
            %do;
                patrtgrp=ptrtgrp;
                patrtcd =ptrtcd;
            %end;  
         %end;  /* end-if variable PERNUM exists in dataset DSETIN.  */
         
         /*  
         / YW003: If TPERNUM is on the input dataset &DSETIN, then do the following: If 
         / TPATRTGP does not already exist on the input dataset &DSETIN, set it to the 
         / value of TPTRTGRP, and set TPATRTCD to the value of TPTRTCD
         /------------------------------------------------------------------------------*/
         
         %if &exist_tpernum eq  %then
         %do; 
            /* TPATRTGP defaulted as a copy of TPTRTGRP if it is not already present on the dataset.*/
            /* In addition, if TPATRTGP is set to TPTRTGRP, then TPATRTCD is set to TPTRTCD.          */
            %if %tu_chkvarsexist(&prefix._dsetinexist, tpatrtgp) ne %then
            %do;
                tpatrtgp =tptrtgrp;
                tpatrtcd =tptrtcd;
            %end;  
         %end;  /* end-if variable PERNUM exists in dataset DSETIN.  */                           
    run;

 %end; /*end-if  DMDATA.RAND and DMDATA.RANDALL both exist */
   
 /*
 / Delete temporary datasets used in this macro.      
 /----------------------------------------------------------------------------*/
 
 %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tu_rantrt;
