/*******************************************************************************
|
| Macro Name:      tu_conv
|
| Macro Version:   4
|
| SAS Version:     8.2
|
| Created By:      Mark Luff
|
| Date:            27-May-2004
|
| Macro Purpose:   Lab value and normal range conversion to SI units
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME            DESCRIPTION                          REQ/OPT  DEFAULT
| --------------  -----------------------------------  -------  ---------------
| DSETIN          Specifies the dataset for which SI   REQ      (Blank)
|                 conversion needs to be done.
|                 Valid values: valid dataset name     
|
| DSETOUT         Specifies the name of the output     REQ      (Blank)
|                 dataset to be created.
|                 Valid values: valid dataset name     
|
| CONVDSET        Specifies the SI dataset which       OPT      dmdata.conv
|                 contains the conversion factors.     
| --------------  -----------------------------------  -------  ---------------
|
| The macro references the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETIN            Req      Parameter specified dataset
| &CONVDSET          Opt      Parameter specified dataset
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
|(@) tr_putlocals
|(@) tu_putglobals
|(@) tu_abort
|(@) tu_chkvarsexist
|(@) tu_nobs
|(@) tu_tidyup
|
| Example:
|    %tu_conv(
|         dsetin  = _lab1,
|         dsetout = _lab2
|         );
|
|******************************************************************************
| Change Log
|
| Modified By: Eric Simms
| Date of Modification: 10Nov04
| New version/draft number: 1/2
| Modification ID: ems001
| Reason For Modification: The put statement for the RTWARNING was in the form
|                             put "%str(RTW)ARNING ...";
|                          which would resolve in the log to
|                             put "RTWARNING ...";
|                          which would then show up in a scan for warnings.
|                          It has been changed to
|                             put "RTW" "ARNING...";
|                          which will only show up in a scan in the log if it
|                          is actually executed.
|                          Also changed last character in message
|                          from ":" to ".." .
|******************************************************************************
| Modified By: Eric Simms
| Date of Modification: 17Nov04
| New version/draft number: 1/3
| Modification ID: ems002
| Reason For Modification: LBACTTM variable is optional on the SI dataset. We 
|                          must test for its existence on the dataset before  
|                          using it.
|******************************************************************************
| Modified By:              Yongwei Wang
| Date of Modification:     12Jan2005
| New version/draft number: 1/4
| Modification ID:          YW001
| Reason For Modification:  1. Added SUBJID= and LBDT= to RTWARNING message so 
|                              that it is easier for user to check.
|                           2. Added a check on if LBREFCD exists when LBCNVFCT
|                              has value -1. 
|                              
| Modified By:              Yongwei Wang
| Date of Modification:     11May2007
| New version/draft number: 2/1
| Modification ID:          YW002
| Reason For Modification:  1. Added CYCLE and VISITNUM to SQL merge based on 
|                              change request HRT0160
|                              
| Modified By:              Yongwei Wang
| Date of Modification:     08Jan2008
| New version/draft number: 3/1
| Modification ID:          YW002
| Reason For Modification:  Added "output &prefix._convert;" when lbrefcd does not 
|                           exist, based on change request HRT0191
|******************************************************************************
| Modified By: Ian Barretto
| Date of Modification: 02Mar10
| New version/draft number: 4/1
| Modification ID: ib001
| Reason For Modification: Added extra join criteria for differentials collected 
|                          in %. Based on Change Request HRT0242
*******************************************************************************/
%macro tu_conv (
     dsetin   = ,              /* Input dataset name */
     dsetout  = ,              /* Output dataset name */
     convdset = DMDATA.CONV    /* Conversion dataset name */
        );

 /*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion;
 %let MacroVersion = 4 build 1;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals()

 /*
 / PARAMETER VALIDATION
 /----------------------------------------------------------------------------*/

 %let dsetin   = %nrbquote(&dsetin);
 %let dsetout  = %nrbquote(&dsetout);
 %let convdset = %nrbquote(&convdset);

 /*
 / Check for required parameters.
 /----------------------------------------------------------------------------*/

 %if &dsetin eq %then
 %do;
    %put %str(RTE)RROR: TU_CONV: The parameter DSETIN is required.;
    %let g_abort=1;
 %end;

 %if &dsetout eq %then
 %do;
    %put %str(RTE)RROR: TU_CONV: The parameter DSETOUT is required.;
    %let g_abort=1;
 %end;

 /*
 / Check for existing datasets.
 /----------------------------------------------------------------------------*/

 %if %sysfunc(exist(&dsetin)) eq 0 %then
 %do;
    %put %str(RTE)RROR: TU_CONV: The dataset &dsetin does not exist.;
    %let g_abort=1;
 %end;

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;

 /*
 / If the input dataset name is the same as the output dataset name,
 / write a note to the log.
 /----------------------------------------------------------------------------*/

 %if &dsetin eq &dsetout %then
 %do;
    %put %str(RTN)OTE: TU_CONV: The input dataset name (&dsetin) is the same as the output dataset name (&dsetout).;
 %end;

 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/

 %local prefix lbrefcd_exist;
 %let prefix = _conv;   /* Root name for temporary work datasets */
 %let lbrefcd_exist=0;  /* YW001: if lbrefcd exist in &convdset */

 %if &convdset ne %then
 %do;
    /* CONV dataset parameter passed */

    %if %sysfunc(exist(&convdset)) %then
    %do;
       /* CONV dataset exists */

       /* Determine which lab records LBTESTCD/LBORUNIT do not have conversion */
       /* information in the conversion dataset.                               */

       proc sort data=&dsetin out=&prefix._labdata nodupkey;
         by lbtestcd lborunit;
       run;

       proc sort data=&convdset out=&prefix._convdata nodupkey;
         by lbtestcd lborunit;
       run;

       data _null_;
         merge &prefix._labdata(in=A) &prefix._convdata(in=B);
          by lbtestcd lborunit;

          if A and not B then
          do;
             put "RTW" "ARNING: TU_CONV: Values of LBTESTCD/LBORUNIT found in &dsetin but not in &convdset.."; /* ems001 */
             put LBTESTCD= LBORUNIT=;
          end;
       run;
       
       /* YW001: Added check of existence of LBREFCD */
       
       %if %tu_chkvarsexist(&convdset, LBREFCD) eq %then %let lbrefcd_exist=1;       
       
       /* Get conversion information. */

       proc sql;
            create table &prefix._labconv as
            select a.*, b.lbstunit as _stunit, b.lbcnvfct %if &lbrefcd_exist %then , b.lbrefcd;
            from &dsetin as a
                 left join &convdset as b
            on  a.lbtestcd = b.lbtestcd and
                a.lborunit = b.lborunit ;
       quit;

       /*
       / Categorise lab records into those converted by factor multiplication
       / and those requiring conversion as a percent or ratio of a reference
       / lab parameter value.
       /----------------------------------------------------------------------*/

       data &prefix._convert &prefix._percent;
            set &prefix._labconv;
            drop unmatch_unit unmatch_value;
        
            /* YW001: Added condition to put RTWARNING message if LBREFCD does not exist */

            if lbcnvfct eq -1 then 
            do;
               %if &lbrefcd_exist %then 
               %do;            
                  output &prefix._percent;
               %end;
               %else %do;               
                  put "RTW" "ARNING: TU_CONV: LBCNVFCT=-1, but LBREFCD does not exist in CONVDSET (=&convdset): " subjid= lbdt= lbtestcd= lbcnvfct= ; /* YW001:*/
                  if 0 then output &prefix._percent;
                  output &prefix._convert;
               %end;
            end; /* end if on lbcnvfct eq -1 */

            else
            do;

               /*
               / Conversion by factor multiplication.
               /--------------------------------------------------------------*/

               if lbcnvfct ne . then
               do;
                  if lborresn ne . then _stresn  = round( (lborresn * lbcnvfct), .00000001);
                  if lbornrhi ne . then lbstnrhi = round( (lbornrhi * lbcnvfct), .00000001);
                  if lbornrlo ne . then lbstnrlo = round( (lbornrlo * lbcnvfct), .00000001);
               end;

               if lbstunit ne ' ' and lbstunit ne _stunit then
               do;
                  if unmatch_unit lt 20 then
                  do;
                    put "RTW" "ARNING: TU_CONV: Lab converted unit does not match: " subjid= lbdt= lbtestcd= lbstunit= _stunit= ; /* YW001:*/
                    unmatch_unit+1;
                  end;
                  else if unmatch_unit eq 20 then
                  do;
                    put "RTW" "ARNING: TU_CONV: Lab converted unit does not match - no further notes of this kind will be printed.";
                    unmatch_unit=999;
                  end;
               end;

               if lbstresn ne . and round(lbstresn, .0000001) ne _stresn then
               do;
                  if unmatch_value lt 20 then
                  do;
                    put "RTW" "ARNING: TU_CONV: Lab converted value does not match: " subjid= lbdt= lbtestcd= lbstresn= _stresn= ; /* YW001:*/
                    unmatch_value+1;
                  end;
                  else if unmatch_value eq 20 then
                  do;
                    put "RTW" "ARNING: TU_CONV: Lab converted value does not match - no further notes of this kind will be printed.";
                    unmatch_value=999;
                  end;
               end;

               lbstunit = _stunit;
               lbstresn = _stresn;

               output &prefix._convert;
            end;  /* end-else on conversion by factor multiplication. */
       run;

       /*
       / Conversion as a percent or ratio of a reference lab parameter value.
       /----------------------------------------------------------------------*/
      
       %if %tu_nobs(&prefix._percent) ge 1 %then
       %do;
          
          /* Lab records requiring percent or ratio conversion exist */

          /*
          / modification ems002.
          / Determine if LBACTTM variable exists on these datasets (they are
          / created from the same dataset, so a single test is sufficient) and,
          / if so, use it as one of the merge keys.
          /----------------------------------------------------------------------*/

          %local exist_lbacttm exist_cycle exist_visitnum;
          %let exist_lbacttm=%tu_chkvarsexist(&prefix._percent,lbacttm);
          %let exist_cycle=%tu_chkvarsexist(&prefix._percent,cycle);
          %let exist_visitnum=%tu_chkvarsexist(&prefix._percent,visitnum);

          proc sql;
               create table &prefix._refpcnt as
               select a.*, b.lbstresn as _ref, b._stunit
               from &prefix._percent (drop = _stunit) as a
                    left join &prefix._convert as b
               on  a.studyid = b.studyid and
                   a.subjid  = b.subjid and
                   a.lbdt    = b.lbdt and

                   /* ib001: Added extra join criterion to include LBIDCD */

                   a.lbidcd  = b.lbidcd and

                   %if &exist_lbacttm eq  %then
                   %do; 
                      a.lbacttm = b.lbacttm and
                   %end;
                   
                   %if &exist_cycle eq  %then
                   %do; 
                      a.cycle = b.cycle and
                   %end;                                     

                   %if &exist_visitnum eq  %then
                   %do; 
                      a.visitnum = b.visitnum and
                   %end;                                     

                   a.lbrefcd = b.lbtestcd;
          quit;

          data &prefix._convpcnt;
               set &prefix._refpcnt;
               drop unmatch_unit unmatch_value;

               if lborresn ne . and _ref ne . then
               do;
                  select (lborunit);
                     when('%')     _stresn = round( (lborresn * _ref / 100), .00000001);
                     when('RATIO') _stresn = round( (lborresn * _ref), .00000001);
                     otherwise ;
                  end;
               end;

               if lbstunit ne ' ' and lbstunit ne _stunit then
               do;
                  if unmatch_unit lt 20 then
                  do;
                    put "RTW" "ARNING: TU_CONV: Lab converted unit does not match: " subjid= lbdt= lbtestcd= lbstunit= _stunit=; /*YW001:*/
                    unmatch_unit+1;
                  end;
                  else if unmatch_unit eq 20 then
                  do;
                    put "RTW" "ARNING: TU_CONV: Lab converted unit does not match - no further notes of this kind will be printed.";                     unmatch_unit=999;
                  end;
               end;

               if lbstresn ne . and round(lbstresn, .0000001) ne _stresn then
               do;
                  if unmatch_value lt 20 then
                  do;
                    put "RTW" "ARNING: TU_CONV: Lab converted value does not match: " subjid= lbdt= lbtestcd= lbstresn= _stresn=; /*YW001:*/
                    unmatch_value+1;
                  end;
                  else if unmatch_value eq 20 then
                  do;
                    put "RTW" "ARNING: TU_CONV: Lab converted value does not match - no further notes of this kind will be printed.";
                    unmatch_value=999;
                  end;
               end;

              lbstunit = _stunit;
              lbstresn = _stresn;
          run;

          data &dsetout;
               set &prefix._convert &prefix._convpcnt;
               drop _stunit _stresn lbrefcd lbcnvfct _ref;
          run;

       %end;  /* end-if on lab records requiring percent or ratio conversion exist */

       %else
       %do;
          /* Lab records requiring percent or ratio conversion do not exist */

          data &dsetout;
               set &prefix._convert;
               drop _stunit _stresn lbcnvfct %if &lbrefcd_exist %then lbrefcd; ;
          run;
       %end;

    %end;  /* end-if on CONV dataset exists */

    %else
    %do;
       /* CONV dataset does not exist */

       data &dsetout;
            set &dsetin;
       run;

       %put %str(RTW)ARNING: TU_CONV: CONV dataset does not exist - conversions not done.;
    %end;

 %end; /* end-if on CONV dataset parameter passed */

 %else
 %do;
    /* CONV dataset parameter not passed */

    data &dsetout;
         set &dsetin;
    run;

    %put %str(RTW)ARNING: TU_CONV: CONV dataset parameter not passed - conversions not done.;
 %end;


 /*
 / Delete temporary datasets used in this macro.
 /----------------------------------------------------------------------------*/

 %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tu_conv;
