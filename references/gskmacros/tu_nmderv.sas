/******************************************************************************* 
|
| Macro Name:      tu_nmderv.sas
|
| Macro Version:   1.0
|
| SAS Version:     8.2
|
| Created By:      Andrew Ratcliffe, RTSL, www.ratcliffe.co.uk
|
| Date:            19-Jun-2005
|
| Macro Purpose:   Add derivations to input dataset, thereby creating a "NONMEM 
|                  dataset".
|                  Note: The derivations facility of the transformation macros
|                  does not support PK derivations, hence the need for this macro. 

|
| Macro Design:    PROCEDURE STYLE MACRO
| 
| Input Parameters:
|
| NAME              DESCRIPTION                         DEFAULT 
| DERVVARS          Specifies dependant variables to be [blank] (Opt)
|                   added. The general syntax for this 
|                   parameter shall be as follows:
|                   DERVVARS = type [parms] [varname]
|                   Where:
|                   - Type specifies the type of derivation 
|                   - Parms optionally provides type-specific parameters
|                   - Varname optionally specifies the name for the new 
|                     variable (it defaults to type)
|
| DSETIN            Specifies the name of the input     [blank] (Req)
|                   dataset
|
| DSETOUT           Specifies the name of the output    [blank] (Req)
|                   dataset
|
| OUTDATE           Specifies the name used for the     date (Req) 
|                   (formatted) date column in the 
|                   input dataset
|
| OUTTIME           Specifies the name used for the     tim2 (Req) 
|                   (formatted) time column in the 
|                   input dataset
|
| PARMSEP           Specifies the character to be used  ! (Req)
|                   to separate individual parameters
|                   for a fiven derived variable
|
| SORTBY            Specifies variables to be used for  [blank] (Req)
|                   sorting and merging
|
| Output: This macro produces a copy of the input dataset with additional columns
|
| Global macro variables created:  None
|
| Macros called:
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_byid
| (@) tu_chknames
| (@) tu_chkvarsexist
| (@) tu_putglobals
| (@) tu_sqlnlist
| (@) tu_tidyup
| (@) tu_words
| (@) tu_xcpput
| (@) tu_xcpsectioninit
| (@) tu_xcpsectionterm
|
| Example:
|
| %tu_nmderv(dsetin = work.leavecv
|           ,dsetout = work.dervvars
|           ,dervvars = bsa [!!ardata.demo!agecatcd] [bodser]
|           );
|
|******************************************************************************* 
| Change Log 
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     05-Jul-2005
| New version number:       1/2
| Modification ID:          
| Reason For Modification:  Fix derivation for BSA so that correct name given to 
|                           result var.
|                           Add derivationS for SEQ, BMI, DOSEKG, URINEAMT, CRT, 
|                           RTFD, RTLD, and RTLM.
|                           Finish-off the list of sub-macros.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     14-Sep-2005
| New version number:       1/3
| Modification ID:          AR3
| Reason For Modification:  Amend DOSEKG to use vitals.weight instead of 
|                           vitals.wt.
|                           Fix: Change use of PARM macro var to PARMS/BNDRYVAR.
|                           Amend CRT by specifying just &g_centid &g_subjid 
|                           visitnum as the default BY variables (dropping date 
|                           and time).
|                           Reposition where clauses in BMI, BSA, and DOSEKG 
|                           derivations so that they apply specifically to 
|                           secondary dataset only.
|                           For RTFD/RTLD, validate dataset to be sure that 
|                           EVID is present.
|                           Ensure correct operation when dervvars is blank.
|                           Change default parm value for SEQ derivation by 
|                           removing g_centid.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     21-Sep-2005
| New version number:       1/4
| Modification ID:          AR4
| Reason For Modification:  Fix: Where clauses introduced by AR3.
|                           Fix: Use left join for sql for BMI, BSA, URINEAMT, 
|                           CRT, DOSEKG.
|                           Add validation for donor datasets of left joins.
|                           Amend derivation of RTLD/RTLM so that "last" is 
|                           interpreted as "most recent."
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     26-Sep-2005
| New version number:       1/5
| Modification ID:          AR5
| Reason For Modification:  Fix: Use sortby for CRT, not crtby.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     27-Sep-2005
| New version number:       1/6
| Modification ID:          AR6
| Reason For Modification:  Fix: Reverse the subtraction for RTFD.
|                           Use upcase in compare for validation of rtfd/bndry.
|                           Fix: For rtfd, sort data by sortby, not bndryby.
|                           Fix: For urineamt, use sortby, not urby.
|                           Fix: replace hard-coded "!" with &parmsep.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     28-Sep-2005
| New version number:       1/7
| Modification ID:          AR7
| Reason For Modification:  Fix: Identify g_subjid with putglobals.
|                           Fix: Use where/lbtestcd/crt_plc in *all* appropriate 
|                           places for derivation of crt.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     28-Sep-2005
| New version number:       1/8
| Modification ID:          AR8
| Reason For Modification:  Add where/pctypcd/2 (urine) to URINEAMT.
|                           Add BY parm to URINEAMT and CRT.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     29-Sep-2005
| New version number:       1/9
| Modification ID:          AR9
| Reason For Modification:  Fix: "let %urHeader = ...".
|                           Fix: Use left join for BSA.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     30-Sep-2005
| New version number:       1/10
| Modification ID:          AR10
| Reason For Modification:  Negative RTFD values shall be set to zero.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     06-Oct-2005
| New version number:       1/11
| Modification ID:          AR11
| Reason For Modification:  For urineamt, set default BY to include date and 
|                           time. Take account of the fact that the vars in the 
|                           donor (pkcnc) dataset are not called "date" and 
|                           "time".
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     21-Oct-2005
| New version number:       1/12
| Modification ID:          AR12
| Reason For Modification:  Fix: Set g_abort to 1 after *all* parm validation 
|                           failures (specifically outdate, outtime, parmsep, 
|                           and sortby).
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     22-Oct-2005
| New version number:       1/13
| Modification ID:          AR13
| Reason For Modification:  Make final parm validation conditional for BSA, BMI, 
|                           CRT, DOSEKG, URINEAMT.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     26-Oct-2005
| New version number:       1/14
| Modification ID:          AR14
| Reason For Modification:  Fix: Insufficient use of upcase() in rtfd/rtld/rtlm.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     27-Oct-2005
| New version number:       1/15
| Modification ID:          AR15
| Reason For Modification:  Fix: Make defaults uppercase for rtfd/rtld/rtlm.
|
| Modified By:              
| Date of Modification:     
| New version number:       
| Modification ID:          
| Reason For Modification:  
|
********************************************************************************/ 

%macro tu_nmderv(dervvars =      /* Dependant variable columns to be added */
                ,dsetin   =      /* type:ID Name of input dataset */
                ,dsetout  =      /* Output dataset */
                ,outdate  = date /* Name of date column in input dataset */
                ,outtime  = tim2 /* Name of time column in input dataset */
                ,parmsep  = !    /* Parameter separator */
                ,sortby   =      /* Variables for merging and sorting */
                );

  /* Echo parameter values and global macro variables to the log */
  %local MacroVersion;
  %let MacroVersion = 1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_subjid);  /*AR7*/

  %local prefix;
  %let prefix = %substr(&sysmacroname,3); 

  /* PARAMETER VALIDATION */

  %let sortby = %upcase(&sortby);  /*AR14*/

  /* Validate - DSETIN */
  %if %length(&dsetin) eq 0 %then 
  %do;
    %put RTE%str(RROR): &sysmacroname.: A value must be supplied for DSETIN;
    %let g_abort=1;
  %end;
  %else
  %do;
    %if not %sysfunc(exist(&dsetin)) %then 
    %do;
      %put RTE%str(RROR): &sysmacroname.: The DSETIN dataset (&dsetin) does not exist;
      %let g_abort=1;
    %end;
  %end;

  /* Validate - DSETOUT */
  %if %length(%tu_chknames(&dsetout,DATA)) gt 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: The value supplied for DSETOUT (&dsetout) is not a valid dataset name;
    %let g_abort=1;
  %end;

  /* Validate - DERVVARS - done in normal processing */

  /* Validate - OUTDATE */
  %if %length(&outdate) le 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname: A value must be specified for OUTDATE;
    %let g_abort=1;  /*AR12*/
  %end;
  %else %if %length(%tu_chkvarsexist(&dsetin,&outdate)) gt 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname: The variable specified for OUTDATE (&outdate) does not exist in DSETIN (&dsetin);
    %let g_abort=1;  /*AR12*/
  %end;

  /* Validate - OUTTIME */
  %if %length(&outtime) le 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname: A value must be specified for OUTTIME;
    %let g_abort=1;  /*AR12*/
  %end;
  %else %if %length(%tu_chkvarsexist(&dsetin,&outtime)) gt 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname: The variable specified for OUTTIME (&outtime) does not exist in DSETIN (&dsetin);
    %let g_abort=1;  /*AR12*/
  %end;

  /* Validate - PARMSEP */
  %if %length(&parmsep) ne 1 %then
  %do;
    %put RTE%str(RROR): &sysmacroname: Invalid parameter separator character (&parmsep);
    %let g_abort=1;  /*AR12*/
  %end;

  /* Validate - SORTBY */
  %if %length(&sortby) le 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname: A value must be specified for SORTBY;
    %let g_abort=1;  /*AR12*/
  %end;
  %else %if %length(%tu_chkvarsexist(&dsetin,&sortby)) gt 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname: One or more variables specified in SORTBY (&sortby) do not exist in DSETIN (&dsetin);
    %let g_abort=1;  /*AR12*/
  %end;

  %tu_abort;

  /* NORMAL PROCESSING */

  /*
  / PLAN OF ACTION:
  / 1. Parse dervvars parm into a macro array
  / 2. Validate the parsed dervvars
  / 3. Create the derived vars, one-by-one
  / 4. Create output dataset
  /------------------------------------------------------*/

  %local currentDataset;
  %let currentDataset = &dsetin;

  /* 1. Parse dervvars parm into a macro array */
  %local dvtype0;
  %local remainingString counter ptr;

  %let remainingString = &dervvars;
  %let counter = 0;
  %let dvtype0 = 0;  /*AR3*/

  %do %while (%length(&remainingString) gt 0);

    %let counter = %eval(&counter + 1);

    %local dvtype&counter dvparms&counter dvname&counter;

    %let dvtype0 = &counter;

    /* Get the type */
    %let ptr = %index(&remainingString%str( ),%str( ));
    %let dvtype&counter = %upcase(%substr(&remainingString,1,&ptr-1));

    %let remainingString = %left(%substr(&remainingString%str( ),&ptr));
    
    /* Set the default name */
    %let dvname&counter = &&dvtype&counter;

    /* Get the parms, if any supplied */
    %if %substr(&remainingString%str( ),1,1) eq [ %then
    %do;
      %let ptr = %index(&remainingString%str( ),]);
      %if &ptr gt 2 %then /* Watch-out for null value */
        %let dvparms&counter = %substr(&remainingString,2,&ptr-2);
      
      %let remainingString = %left(%substr(&remainingString%str(  ),&ptr+1));
    %end;

    /* Get the name, if any supplied */
    %if %substr(&remainingString%str( ),1,1) eq [ %then
    %do;
      %let ptr = %index(&remainingString%str( ),]);
      %let dvname&counter = %substr(&remainingString,2,&ptr-2);
      
      %let remainingString = %left(%substr(&remainingString%str(  ),&ptr+1));
    %end;

  %end; /* parse remainingString */

  %if &g_debug ge 1 %then
  %do;  /* Dump the parsed parm */
    %put RTD%str(EBUG): &sysmacroname: DVTYPE0=&dvtype0;
    %do counter = 1 %to &dvtype0;
      %put RTD%str(EBUG): &sysmacroname: DVTYPE&counter=&&dvtype&counter, DVPARMS&counter=&&dvparms&counter, DVNAME&counter=&&dvname&counter;
    %end;
  %end; /* Dump the parsed parm */

  /* 2. Validate the parsed dervvars */
  %do counter = 1 %to &dvtype0;

    /* Type validated in later processing */
    %if &&dvtype&counter ne RTFD and
        &&dvtype&counter ne RTLD and
        &&dvtype&counter ne RTLM and
        &&dvtype&counter ne SEQ and
        &&dvtype&counter ne BSA and
        &&dvtype&counter ne BMI and
        &&dvtype&counter ne CRT and
        &&dvtype&counter ne DOSEKG and
        &&dvtype&counter ne URINEAMT %then
    %do;
      %put RTE%str(RROR): &sysmacroname: Invalid derived variable type: &&dvtype&counter;
      %let g_abort = 1;
    %end;

    /* Parms validated in later processing */

    /* Name */
    %if %length(%tu_chknames(&&dvname&counter,VARIABLE)) gt 0 %then
    %do;
      %put RTE%str(RROR): &sysmacroname: Invalid derived variable name: &&dvname&counter;
      %let g_abort = 1;
    %end;

  %end; /* Do over parsed dervvars */

  /* Abort if any invalid aspects of dervvars were found */
  %tu_abort;

  /* 3. Create the derived vars, one-by-one */
  /* 
  / In each case we create an output dataset with the same 
  / name as the result variable. This is to allow for the
  / same type of variable to be created more than once
  / (without over-writing temporary datasets).
  /------------------------------------------------------*/
  %do counter = 1 %to &dvtype0;

    %if &&dvtype&counter eq RTFD %then
    %do;  /* RTFD */
      /* 
      / parms: 
      /        bndry    default=visitnum
      /------------------------------------------------------*/
      %local bndry;
      %let bndry = %upcase(&&dvParms&counter);  /*AR14*/

      %if %length(&bndry) eq 0 %then %let bndry = %upcase(visitnum);  /*AR15*/

      /* RTFD - Parameter Validation */

      /* Validate - input dataset */  /*AR3*/
      %if %length(%tu_chkvarsexist(&currentDataset,evid)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: RTFD: The EVID variable was not found in prevailing dataset (&currentDataset);
        %let g_abort = 1;
      %end;

      /* Validate - bndry */
      %if %length(%tu_chkvarsexist(&currentDataset,&bndry)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: RTFD: Specified boundary variable (&bndry) not found in prevailing dataset (&currentDataset);
        %let g_abort = 1;
      %end;

      %if %index(%upcase(&sortby),%upcase(&bndry)) eq 0 %then  /*AR6*/
      %do;
        %put RTE%str(RROR): &sysmacroname: RTFD: Specified boundary variable (&bndry) not found in SORTBY (&sortby);  /*AR3*/
        %let g_abort = 1;
      %end;

      %tu_abort;

      /* RTFD - Normal Processing */
      %local bndryBy;
      %let bndryBy = %substr(&sortby
                            ,1
                            ,%index(&sortby,&bndry)+%length(&bndry)-1
                            );

      proc sort data=&currentDataset 
                out=work.&prefix._rtfd_&&dvname&counter.._cdsort;
        by &sortBy;  /*AR6*/
      run;

      data work.&prefix._rtfd_&&dvname&counter.._doses;
        set work.&prefix._rtfd_&&dvname&counter.._cdsort;
        by &sortBy;  /*AR6*/
        where evid eq 1;
        keep &bndryBy firstDoseDt;
        format firstDoseDt datetime.;
        firstDosedt = dhms(&outdate,0,0,&outtime);
        if first.&bndry then OUTPUT;
      run;

      data work.&prefix._rtfd_&&dvname&counter;
        merge work.&prefix._rtfd_&&dvname&counter.._cdsort
              work.&prefix._rtfd_&&dvname&counter.._doses
              ;
        by &bndryBy;
        drop firstDoseDt;
        RTFD = (dhms(&outdate,0,0,&outtime) - firstDoseDt)/3600;  /*AR6*/
        if rtfd lt 0 then rtfd = 0; /* Includes missing values */  /*AR10*/
      run;
      %let currentDataset = work.&prefix._rtfd_&&dvname&counter;

    %end; /* RTFD */

    %else %if &&dvtype&counter eq RTLD %then
    %do;  /* RTLD */
      /* 
      / parms: 
      /        bndry    default=visitnum
      /------------------------------------------------------*/
      %local bndry;
      %let bndry = %upcase(&&dvParms&counter);  /*AR14*/

      %if %length(&bndry) eq 0 %then %let bndry = %upcase(visitnum);  /*AR15*/

      /* RTLD - Parameter Validation */

      /* Validate - input dataset */  /*AR3*/
      %if %length(%tu_chkvarsexist(&currentDataset,evid)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: RTLD: The EVID variable was not found in prevailing dataset (&currentDataset);
        %let g_abort = 1;
      %end;

      /* Validate - bndry */
      %if %length(%tu_chkvarsexist(&currentDataset,&bndry)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: RTLD: Specified boundary variable (&bndry) not found in prevailing dataset (&currentDataset);
        %let g_abort = 1;
      %end;

      %if %index(&sortby,&bndry) eq 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: RTLD: Specified boundary variable (&bndry) not found in SORTBY (&sortby);  /*AR3*/
        %let g_abort = 1;
      %end;

      %tu_abort;

      /* RTLD - Normal Processing */
      %local bndryBy;
      %let bndryBy = %substr(&sortby
                            ,1
                            ,%index(&sortby,&bndry)+%length(&bndry)-1
                            );

      proc sort data=&currentDataset out=work.&prefix._rtld_sort_&&dvname&counter;  /*AR4*/
        by &sortby;
      run;

      data work.&prefix._rtld_&&dvname&counter;  /*AR4*/
        set work.&prefix._rtld_sort_&&dvname&counter;
        retain PreviousDoseDatetime;
        drop PreviousDoseDatetime;
        by &bndryBy;
        if first.&bndry then PreviousDoseDatetime = .;
        if evid eq 1 then PreviousDoseDatetime = dhms(&outdate,0,0,&outtime);
        RTLD = (dhms(&outdate,0,0,&outtime)-PreviousDoseDatetime)/3600;
        if missing(rtld) then rtld = 0;
      run;
      %let currentDataset = work.&prefix._rtld_&&dvname&counter;

    %end; /* RTLD */

    %else %if &&dvtype&counter eq RTLM %then
    %do;  /* RTLM */
      /* 
      / parms: 
      /        mealDset   default=[blank]
      /        mealWhere  default=[blank]
      /        mealDate   default=[blank]
      /        mealTime   default=[blank]
      /        bndry      default=visitnum
      /------------------------------------------------------*/
      %local mealDset mealWhere mealDate mealTime bndry parms;

      /* 
      / Manipulate parms to add spaces before/after consecutive separators
      / so that the scan function finds them nicely.
      /------------------------------------------------------*/
      %let parms=%str( )%sysfunc(tranwrd(&&dvParms&counter,&parmsep,%str( &parmsep )));  /*AR6*/

      %let mealDset  = %scan(&parms,1,&parmsep);
      %let mealWhere = %scan(&parms,2,&parmsep);
      %let mealDate  = %scan(&parms,3,&parmsep);
      %let mealTime  = %scan(&parms,4,&parmsep);
      %let bndry     = %upcase(%scan(&parms,5,&parmsep));  /*AR14*/

      %if &g_debug ge 1 %then
      %do;
        %put RTD%str(EBUG): &sysmacroname: RTLM: MEALDSET=&mealDset, MEALWHERE=&mealWhere, MEALDATE=&mealDate, MEALTIME=&mealTime, BNDRY=&bndry;
      %end;

      %if %length(&bndry) eq 0 %then %let bndry = %upcase(visitnum);  /*AR15*/

      %if &g_debug ge 1 %then
      %do;
        %put RTD%str(EBUG): &sysmacroname: RTLM: MEALDSET=&mealDset, MEALWHERE=&mealWhere, MEALDATE=&mealDate, MEALTIME=&mealTime, BNDRY=&bndry;
      %end;

      /* RTLM - Parameter Validation */

      /* Validate - mealDset */
      %if %length(&mealDset) le 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: RTLM: A dataset must be specified;
        %let g_abort = 1;
      %end;
      %else %if not %sysfunc(exist(&mealDset)) %then
      %do;
        %put RTE%str(RROR): &sysmacroname: RTLM: Specified dataset (&mealDset) does not exist;
        %let g_abort = 1;
      %end;

      /* Validate - mealWhere - none */

      /* Validate - mealDate */
      %if %length(&mealDate) le 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: RTLM: A date variable must be specified;
        %let g_abort = 1;
      %end;
      %else %if %length(%tu_chkvarsexist(&mealDset,&mealDate)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: RTLM: Specified date variable (&mealDate) not found in dataset (&mealDset);
        %let g_abort = 1;
      %end;

      /* Validate - mealTime */
      %if %length(&mealTime) le 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: RTLM: A time variable must be specified;
        %let g_abort = 1;
      %end;
      %else %if %length(%tu_chkvarsexist(&mealDset,&mealTime)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: RTLM: Specified time variable (&mealTime) not found in dataset (&mealDset);
        %let g_abort = 1;
      %end;

      /* Validate - bndry */
      %if %length(%tu_chkvarsexist(&currentDataset,&bndry)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: RTLM: Specified boundary variable (&bndry) not found in prevailing dataset (&currentDataset);
        %let g_abort = 1;
      %end;

      %if %index(&sortby,&bndry) eq 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: RTLM: Specified boundary variable (&bndry) not found in SORTBY (&sortby);  /*AR3*/
        %let g_abort = 1;
      %end;

      %tu_abort;

      /* RTLM - Normal Processing */  /*AR4*/
      %local bndryBy;
      %let bndryBy = %substr(&sortby
                            ,1
                            ,%index(&sortby,&bndry)+%length(&bndry)-1
                            );

      proc sort data=&mealDset 
                     (rename=(&mealdate=&outdate &mealtime=&outtime))
                out=work.&prefix._rtlm_&&dvname&counter.._mealSort;
        by &bndryBy &outdate &outtime;
        %if %length(&mealWhere) gt 0 %then
        %do;
          where &mealWhere;
        %end;
      run;

      proc sort data=&currentDataset
                out=work.&prefix._rtlm_&&dvname&counter.._dataSort;
        by &bndryBy &outdate &outtime;
      run;

      data work.&prefix._rtlm_&&dvname&counter;
        set work.&prefix._rtlm_&&dvname&counter.._dataSort (in=fromData)
            work.&prefix._rtlm_&&dvname&counter.._mealSort (in=fromMeal)
            ;
        by &bndryBy &outdate &outtime;
        retain PreviousMealDatetime;
        drop PreviousMealDatetime;
        if first.&bndry then PreviousMealDatetime = .;
        if fromMeal then 
        do;
          PreviousMealDatetime = dhms(&outdate,0,0,&outtime);
          DELETE;
        end;
        else
        do;
          RTLM = (dhms(&outdate,0,0,&outtime)-PreviousMealDatetime)/3600;
          if missing(rtlm) then rtlm = 0;
        end;
      run;
      %let currentDataset = work.&prefix._rtlm_&&dvname&counter;

    %end; /* RTLM */

    %else %if &&dvtype&counter eq SEQ %then
    %do;  /* SEQ */
      /* 
      / parms: 
      /        vars     default=&g_subjid   (AR3)
      /------------------------------------------------------*/
      %local parms perms;
      %let parms = &&dvParms&counter;

      %if %length(&parms) eq 0 %then %let parms = &g_subjid;  /*AR3*/

      %let perms = %sysfunc(translate(&parms,*,%str( )));

      %if &g_debug ge 1 %then 
        %put RTD%str(EBUG): &sysmacroname: SEQ: PARMS=&parms, PERMS=&perms;

      /* SEQ - Parameter Validation */

      /* Validate - parms */
      %if %length(%tu_chkvarsexist(&currentDataset,&parms)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: SEQ: One or more of the specified variables (&parms) not found in prevailing dataset (&currentDataset);  /*AR3*/
        %let g_abort = 1;
      %end;

      %tu_abort;

      /* SEQ - Normal Processing */
      proc freq data=&currentDataset;
        table &perms / noprint out=work.&prefix._seqfreq;
      run;

      data work.&prefix._withseq;
        set work.&prefix._seqfreq;
        keep &parms seq;
        seq = _n_;
      run;

      proc sql;
        create table work.&prefix._seq_&&dvname&counter as
          select main.* 
                , withseq.seq as &&dvname&counter
          from &currentDataset main left join work.&prefix._withseq withseq
          on %tu_sqlnlist(&parms,main,withseq)
          ;
      quit;
      %let currentDataset = work.&prefix._seq_&&dvname&counter;

    %end; /* SEQ */

    %else %if &&dvtype&counter eq BSA %then
    %do;  /* BSA */
      /* 
      / parms: 
      /        where    default=[blank]
      /        variable default=vsbsa
      /        dataset  default=ardata.vitals
      /        by       default=&g_subjid
      /------------------------------------------------------*/
      %local bsaWhere bsaBy bsaDataset bsaVariable parms;

      /* 
      / Manipulate parms to add spaces before/after consecutive separators
      / so that the scan function finds them nicely.
      /------------------------------------------------------*/
      %let parms=%str( )%sysfunc(tranwrd(&&dvParms&counter,&parmsep,%str( &parmsep )));  /*AR6*/

      %let bsaWhere    = %scan(&parms,1,&parmsep);
      %let bsaVariable = %scan(&parms,2,&parmsep);
      %let bsaDataset  = %scan(&parms,3,&parmsep);
      %let bsaBy       = %scan(&parms,4,&parmsep);

      %if &g_debug ge 1 %then
      %do;
        %put RTD%str(EBUG): &sysmacroname: BSA: BSAWHERE=&bsaWhere, BSABY=&bsaBy, BSADATASET=&bsaDataset, BSAVARIABLE=&bsaVariable;
      %end;

      %if %length(&bsaBy) eq 0 %then %let bsaBy = &g_subjid;
      %if %length(&bsaDataset) eq 0 %then %let bsaDataset = ardata.vitals;
      %if %length(&bsaVariable) eq 0 %then %let bsaVariable = vsbsa;

      %if &g_debug ge 1 %then
      %do;
        %put RTD%str(EBUG): &sysmacroname: BSA: BSAWHERE=&bsaWhere, BSABY=&bsaBy, BSADATASET=&bsaDataset, BSAVARIABLE=&bsaVariable;
      %end;

      /* BSA - Parameter Validation */

      /* Validate - bsaWhere - none */

      /* Validate - bsaVariable & bsaDataset */
      %if %length(%tu_chkvarsexist(&bsaDataset,&bsaVariable)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: BSA: Specified variable (&bsaVariable) not found in specified dataset (&bsaDataset);
        %let g_abort = 1;
      %end;

      /* Validate - bsaBy */
      %if %length(%tu_chkvarsexist(&bsaDataset,&bsaBy)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: BSA: Specified BY variable(s) (&bsaBy) not found in specified dataset (&bsaDataset);
        %let g_abort = 1;
      %end;
      %if %length(%tu_chkvarsexist(&currentDataset,&bsaBy)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: BSA: Specified BY variable(s) (&bsaBy) not found in prevailing dataset (&currentDataset);
        %let g_abort = 1;
      %end;

      %tu_abort;  /*AR13 */

      /* Check for appropriate number of observations in donor dataset */  /*AR4*/
      proc freq data=&bsaDataset 
                     %if %length(&bsaWhere) gt 0 %then
                     %do;
                       (where=(&bsaWhere))
                     %end;
                ;
        table %sysfunc(translate(&bsaby,%str(*),%str( ))) 
              / 
              noprint 
              out=work.&prefix._bsa_chk_&&dvname&counter;
      run;

      data _null_;
        set work.&prefix._bsa_chk_&&dvname&counter end=finish;
        drop __msg;
        %tu_xcpsectioninit(header=Validate BSA donor dataset &bsaDataset
                                  %if %length(&bsaWhere) gt 0 %then
                                  %do;
                                    (where=(&bsaWhere))
                                  %end;
                          );
        if count ne 1 then
        do;
          %tu_byid(dsetin=work.&prefix._bsa_chk_&&dvname&counter
                  ,invars=&bsaby
                  ,outvar=__msg
                  );
          %tu_xcpput("Donor dataset contains multiple rows for " !! __msg
                    ,WARNING);
        end;
        %tu_xcpsectionterm(end=finish);
      run;

      %tu_abort;

      /* BSA - Normal Processing */

      proc sql noprint;
        create table work.&prefix._bsa_&&dvname&counter as
          select current.*
                 , vitals.&bsaVariable as &&dvname&counter
          from &currentDataset current
               left join  /*AR9*/
               &bsaDataset 
               %if %length(&bsaWhere) gt 0 %then
               %do;
                 (where=(&bsaWhere))  /*AR3*/  /*AR4*/
               %end;
               vitals
          on %tu_sqlnlist(&bsaBy,current,vitals)  /*AR9*/
          ;
      quit;
      %let currentDataset = &prefix._bsa_&&dvname&counter;

    %end; /* BSA */

    %else %if &&dvtype&counter eq BMI %then
    %do;  /* BMI */
      /* 
      / parms: 
      /        where    default=[blank]
      /        variable default=vsbmi
      /        dataset  default=ardata.vitals
      /        by       default=&g_subjid
      /------------------------------------------------------*/
      %local bmiWhere bmiBy bmiDataset bmiVariable parms;

      /* 
      / Manipulate parms to add spaces before/after consecutive separators
      / so that the scan function finds them nicely.
      /------------------------------------------------------*/
      %let parms=%str( )%sysfunc(tranwrd(&&dvParms&counter,&parmsep,%str( &parmsep )));  /*AR6*/

      %let bmiWhere    = %scan(&parms,1,&parmsep);
      %let bmiVariable = %scan(&parms,2,&parmsep);
      %let bmiDataset  = %scan(&parms,3,&parmsep);
      %let bmiBy       = %scan(&parms,4,&parmsep);

      %if &g_debug ge 1 %then
      %do;
        %put RTD%str(EBUG): &sysmacroname: BMI: BMIWHERE=&bmiWhere, BMIBY=&bmiBy, BMIDATASET=&bmiDataset, BMIVARIABLE=&bmiVariable;
      %end;

      %if %length(&bmiBy) eq 0 %then %let bmiBy = &g_subjid;
      %if %length(&bmiDataset) eq 0 %then %let bmiDataset = ardata.vitals;
      %if %length(&bmiVariable) eq 0 %then %let bmiVariable = vsbmi;

      %if &g_debug ge 1 %then
      %do;
        %put RTD%str(EBUG): &sysmacroname: BMI: BMIWHERE=&bmiWhere, BMIBY=&bmiBy, BMIDATASET=&bmiDataset, BMIVARIABLE=&bmiVariable;
      %end;

      /* BMI - Parameter Validation */

      /* Validate - bmiWhere - none */

      /* Validate - bmiVariable & bmiDataset */
      %if %length(%tu_chkvarsexist(&bmiDataset,&bmiVariable)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: BMI: Specified variable (&bmiVariable) not found in specified dataset (&bmiDataset);
        %let g_abort = 1;
      %end;

      /* Validate - bmiBy */
      %if %length(%tu_chkvarsexist(&bmiDataset,&bmiBy)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: BMI: Specified BY variable(s) (&bmiBy) not found in specified dataset (&bmiDataset);
        %let g_abort = 1;
      %end;
      %if %length(%tu_chkvarsexist(&currentDataset,&bmiBy)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: BMI: Specified BY variable(s) (&bmiBy) not found in prevailing dataset (&currentDataset);
        %let g_abort = 1;
      %end;

      %tu_abort;  /*AR13 */

      /* Check for appropriate number of observations in donor dataset */  /*AR4*/
      proc freq data=&bmiDataset 
                     %if %length(&bmiWhere) gt 0 %then
                     %do;
                       (where=(&bmiWhere))
                     %end;
                ;
        table %sysfunc(translate(&bmiby,%str(*),%str( ))) 
              / 
              noprint 
              out=work.&prefix._bmi_chk_&&dvname&counter;
      run;

      data _null_;
        set work.&prefix._bmi_chk_&&dvname&counter end=finish;
        drop __msg;
        %tu_xcpsectioninit(header=Validate BMI donor dataset &bmiDataset
                                  %if %length(&bmiWhere) gt 0 %then
                                  %do;
                                    (where=(&bmiWhere))
                                  %end;
                          );
        if count ne 1 then
        do;
          %tu_byid(dsetin=work.&prefix._bmi_chk_&&dvname&counter
                  ,invars=&bmiby
                  ,outvar=__msg
                  );
          %tu_xcpput("Donor dataset contains multiple rows for " !! __msg
                    ,WARNING);
        end;
        %tu_xcpsectionterm(end=finish);
      run;

      %tu_abort;

      /* BMI - Normal Processing */

      proc sql noprint;
        create table work.&prefix._bmi_&&dvname&counter as
          select current.*
                 , vitals.&bmiVariable as &&dvname&counter
          from &currentDataset current
               left join  /*AR4*/
               &bmiDataset 
               %if %length(&bmiWhere) gt 0 %then
               %do;
                 (where=(&bmiWhere))  /*AR3*/  /*AR4*/
               %end;
               vitals
          on %tu_sqlnlist(&bmiBy,current,vitals)  /*AR4*/
          ;
      quit;
      %let currentDataset = &prefix._bmi_&&dvname&counter;

    %end; /* BMI */

    %else %if &&dvtype&counter eq CRT %then
    %do;  /* CRT */
      /* 
      / parms: where      default=[blank]
      /        dataset    default=ardata.lab
      /        by         default=&g_subjid visitnum
      /------------------------------------------------------*/
      %local parms crtWhere crtDataset crtBy;  /*AR8*/

      /* 
      / Manipulate parms to add spaces before/after consecutive separators
      / so that the scan function finds them nicely.
      /------------------------------------------------------*/
      %let parms=%str( )%sysfunc(tranwrd(&&dvParms&counter,&parmsep,%str( &parmsep )));  /*AR6*/

      %let crtWhere    = %scan(&parms,1,&parmsep);
      %let crtDataset  = %scan(&parms,2,&parmsep);
      %let crtBy       = %scan(&parms,3,&parmsep);  /*AR8*/

      %if &g_debug ge 1 %then
      %do;
        %put RTD%str(EBUG): &sysmacroname: CRT: CRTWHERE=&crtWhere, CRTDATASET=&crtDataset, CRTBY=&crtBy;
      %end;

      %if %length(&crtDataset) eq 0  %then %let crtDataset = ardata.lab;
      %if %length(&crtBy)      eq 0  %then %let crtBy = &g_subjid visitnum;  /*AR8*/

      %if &g_debug ge 1 %then
      %do;
        %put RTD%str(EBUG): &sysmacroname: CRT: CRTWHERE=&crtWhere, CRTDATASET=&crtDataset, CRTBY=&crtBy;
      %end;

      /* CRT - Parameter Validation */

      /* Validate - crtWhere - none */

      /* Validate - crtDataset */
      %if not %sysfunc(exist(&crtDataset)) %then
      %do;
        %put RTE%str(RROR): &sysmacroname: CRT: Specified dataset (&crtDataset) not found;
        %let g_abort = 1;
      %end;

      /* Validate - crtBy */  /*AR8*/
      %if %length(%tu_chkvarsexist(&crtDataset,&crtBy)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: CRT: Specified BY variable(s) (&crtBy) not found in specified dataset (&crtDataset);
        %let g_abort = 1;
      %end;
      %if %length(%tu_chkvarsexist(&currentDataset,&crtBy)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: CRT: Specified BY variable(s) (&crtBy) not found in prevailing dataset (&currentDataset);
        %let g_abort = 1;
      %end;

      /* Validate - lab variables */
      %if %length(%tu_chkvarsexist(&crtDataset,LBSTRESN LBDT LBACTTM LBTESTCD LBSTUNIT)) gt 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: CRT: One or more required lab variables do not exist in specified dataset (&crtDataset);
      %end;

      %tu_abort;  /*AR13 */

      /* Validate - consistent units in LBSTUNIT */
      %local unitvalues;

      /* -- Establish unit value (check it is consistent) */
      proc sql noprint;
       select distinct LBSTUNIT into: unitvalues separated by ','
         from &crtDataset
         where LBTESTCD eq "CRT_PLC"
               %if %length(&crtWhere) gt 0 %then
               %do;
                 and &crtWhere
               %end;
         ;
      quit;
      %if &g_debug ge 1 %then  /*AR3*/
        %put RTD%str(EBUG): &sysmacroname: #1: UNITVALUES=&unitvalues;

      /* -- Verify that the units are non missing */
      %if %length(&unitvalues) eq 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: The LBSTUNIT variable (in &crtDataset) has missing units;
        %let g_abort = 1;
      %end;

      %else
      %do;  /* Units are not completely missing */

        /* -- Verify that the units are consistent, but ignore blank */
        proc sql noprint;
         select distinct LBSTUNIT into: unitvalues separated by ','
           from &crtDataset
           where LBSTUNIT ne ''
                 and LBTESTCD eq "CRT_PLC"
                 %if %length(&crtWhere) gt 0 %then
                 %do;
                   and &crtWhere
                 %end;
                 ;
        quit;
        %if &g_debug ge 1 %then  /*AR3*/
          %put RTD%str(EBUG): &sysmacroname: #2: UNITVALUES=&unitvalues;

        %if %index(%nrbquote(&unitvalues.),%nrbquote(,)) ne 0 %then
        %do;
          %put RTE%str(RROR): &sysmacroname: The LBSTUNIT variable (in &crtDataset) has inconsistent units: &unitvalues;
          %let g_abort = 1;
        %end;

      %end; /* Units are not completely missing */

      /* Check for appropriate number of observations in donor dataset */  /*AR4*/
      proc freq data=&crtDataset 
                     (where=(LBTESTCD eq "CRT_PLC"  /*AR7*/
                             %if %length(&crtWhere) gt 0 %then
                             %do;
                               and &crtWhere
                             %end;
                            )
                     )
                ;
        table %sysfunc(translate(&crtBy,%str(*),%str( )))  /*AR5*//*AR8*/
              / 
              noprint 
              out=work.&prefix._crt_chk_&&dvname&counter;
      run;

      %local crtHeader;
      %let crtHeader = Validate CRT donor dataset &crtDataset;  /*AR8*/
      %if %length(&crtWhere) gt 0 %then
      %do;
        %let crtHeader = &crtHeader (where=(&crtWhere));
      %end;

      data _null_;
        set work.&prefix._crt_chk_&&dvname&counter end=finish;
        drop __msg;
        %tu_xcpsectioninit(header=&crtHeader);  /*AR8*/
        if count ne 1 then
        do;
          %tu_byid(dsetin=work.&prefix._crt_chk_&&dvname&counter
                  ,invars=&crtBy  /*AR5*//*AR8*/
                  ,outvar=__msg
                  );
          %tu_xcpput("Donor dataset contains multiple rows for " !! __msg
                    ,WARNING);
        end;
        %tu_xcpsectionterm(end=finish);
      run;

      %tu_abort;

      /* CRT - Normal Processing */
 
      proc sql noprint;
        create table work.&prefix._crt_&&dvname&counter as
          select current.*
                 ,LBSTRESN as &&dvname&counter
          from &currentDataset current
               left join
               &crtDataset (rename=(LBDT=&outdate LBACTTM=&outtime)
                            where=(LBTESTCD eq "CRT_PLC"
                                   %if %length(&crtWhere) gt 0 %then
                                   %do;
                                     and &crtWhere
                                   %end;
                                  )
                           ) lab
          on %tu_sqlnlist(&crtBy,current,lab)  /*AR8*/
          ;
      quit;
      %let currentDataset = &prefix._crt_&&dvname&counter;

    %end; /* CRT */

    %else %if &&dvtype&counter eq DOSEKG %then
    %do;  /* DOSEKG */
      /* 
      / parms: where    default=[blank]
      /        variable default=weight  AR3
      /        dataset  default=ardata.vitals
      /        by       default=&g_subjid
      /        dosevar  default=amt
      /------------------------------------------------------*/
      %local parms kgWhere kgDataset kgVariable kgBy kgDosevar;

      /* 
      / Manipulate parms to add spaces before/after consecutive separators
      / so that the scan function finds them nicely.
      /------------------------------------------------------*/
      %let parms=%str( )%sysfunc(tranwrd(&&dvParms&counter,&parmsep,%str( &parmsep )));  /*AR6*/

      %let kgWhere    = %scan(&parms,1,&parmsep);
      %let kgVariable = %scan(&parms,2,&parmsep);
      %let kgDataset  = %scan(&parms,3,&parmsep);
      %let kgBy       = %scan(&parms,4,&parmsep);
      %let kgDosevar  = %scan(&parms,5,&parmsep);

      %if &g_debug ge 1 %then
      %do;
        %put RTD%str(EBUG): &sysmacroname: DOSEKG: KGWHERE=&kgWhere, KGVARIABLE=&kgVariable, KGDATASET=&kgDataset, KGBY=&kgBy, KGDOSEVAR=&kgDosevar;
      %end;

      %if %length(&kgVariable) eq 0 %then %let kgVariable = weight;  /*AR3*/
      %if %length(&kgDataset) eq 0  %then %let kgDataset = ardata.vitals;
      %if %length(&kgBy) eq 0       %then %let kgBy = &g_subjid;
      %if %length(&kgDosevar) eq 0  %then %let kgDosevar = amt;

      %if &g_debug ge 1 %then
      %do;
        %put RTD%str(EBUG): &sysmacroname: DOSEKG: KGWHERE=&kgWhere, KGVARIABLE=&kgVariable, KGDATASET=&kgDataset, KGBY=&kgBy, KGDOSEVAR=&kgDosevar;
      %end;

      /* DOSEKG - Parameter Validation */

      /* Validate - kgWhere - none */

      /* Validate - kgVariable & kgDataset */
      %if %length(%tu_chkvarsexist(&kgDataset,&kgVariable)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: DOSEKG: Specified variable (&kgVariable) not found in specified dataset (&kgDataset);
        %let g_abort = 1;
      %end;

      /* Validate - kgBy */
      %if %length(%tu_chkvarsexist(&kgDataset,&kgBy)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: DOSEKG: Specified BY variable(s) (&kgBy) not found in specified dataset (&kgDataset);
        %let g_abort = 1;
      %end;
      %if %length(%tu_chkvarsexist(&currentDataset,&kgBy)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: DOSEKG: Specified BY variable(s) (&kgBy) not found in prevailing dataset (&currentDataset);
        %let g_abort = 1;
      %end;

      /* Validate - kgDosevar */
      %if %length(%tu_chkvarsexist(&currentDataset,&kgDosevar)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: DOSEKG: Specified dose variable (&kgDosevar) not found in prevailing dataset (&currentDataset);
        %let g_abort = 1;
      %end;

      %tu_abort;  /*AR13 */

      /* Check for appropriate number of observations in donor dataset */  /*AR4*/
      proc freq data=&kgDataset 
                     %if %length(&kgWhere) gt 0 %then
                     %do;
                       (where=(&kgWhere))
                     %end;
                ;
        table %sysfunc(translate(&kgby,%str(*),%str( ))) 
              / 
              noprint 
              out=work.&prefix._kg_chk_&&dvname&counter;
      run;

      data _null_;
        set work.&prefix._kg_chk_&&dvname&counter end=finish;
        drop __msg;
        %tu_xcpsectioninit(header=Validate DOSEKG donor dataset &kgDataset
                                  %if %length(&kgWhere) gt 0 %then
                                  %do;
                                    (where=(&kgWhere))
                                  %end;
                          );
        if count ne 1 then
        do;
          %tu_byid(dsetin=work.&prefix._kg_chk_&&dvname&counter
                  ,invars=&kgby
                  ,outvar=__msg
                  );
          %tu_xcpput("Donor dataset contains multiple rows for " !! __msg
                    ,WARNING);
        end;
        %tu_xcpsectionterm(end=finish);
      run;

      %tu_abort;

      /* DOSEKG - Normal Processing */

      proc sql noprint;
        create table work.&prefix._dosekg_&&dvname&counter as
          select current.*
                 , &kgDosevar / vitals.&kgVariable as &&dvname&counter
          from &currentDataset current
               left join
               &kgDataset 
               %if %length(&kgWhere) gt 0 %then
               %do;
                 (where=(&kgWhere))  /*AR3*/  /*AR4*/
               %end;
               vitals
          on %tu_sqlnlist(&kgBy,current,vitals)
          ;
      quit;
      %let currentDataset = &prefix._dosekg_&&dvname&counter;

    %end; /* DOSEKG */

    %else %if &&dvtype&counter eq URINEAMT %then
    %do;  /* URINEAMT */
      /* 
      / parms: where      default=[blank]
      /        dataset    default=ardata.pkcnc
      /        by         default=&g_subjid visitnum
      /------------------------------------------------------*/
      %local parms urWhere urDataset urBy;  /*AR8*/

      /* 
      / Manipulate parms to add spaces before/after consecutive separators
      / so that the scan function finds them nicely.
      /------------------------------------------------------*/
      %let parms=%str( )%sysfunc(tranwrd(&&dvParms&counter,&parmsep,%str( &parmsep )));  /*AR6*/

      %let urWhere    = %scan(&parms,1,&parmsep);
      %let urDataset  = %scan(&parms,2,&parmsep);
      %let urBy       = %scan(&parms,3,&parmsep);  /*AR8*/

      %if &g_debug ge 1 %then
      %do;
        %put RTD%str(EBUG): &sysmacroname: URINEAMT: URWHERE=&urWhere, URDATASET=&urDataset, URBY=&urBy;
      %end;

      %if %length(&urDataset) eq 0  %then %let urDataset = ardata.pkcnc;
      %if %length(&urBy)      eq 0  %then %let urBy      = &g_subjid visitnum &outdate &outtime;  /*AR8*//*AR11*/

      %if &g_debug ge 1 %then
      %do;
        %put RTD%str(EBUG): &sysmacroname: URINEAMT: URWHERE=&urWhere, URDATASET=&urDataset, URBY=&urBy;
      %end;

      /* Allow for different var names in donor (pkcnc) dataset */  /*AR11*/
      %local urDonorBy;
      %let urDonorBy = %sysfunc(tranwrd(&urBy
                                       ,&outdate,pcstdt
                                       )
                               );
      %let urDonorBy = %sysfunc(tranwrd(&urDonorBy
                                       ,&outtime,pcsttm
                                       )
                               );

      %if &g_debug ge 1 %then  /*AR11*/
      %do;
        %put RTD%str(EBUG): &sysmacroname: URINEAMT: URDONORBY=&urDonorBy;
      %end;

      /* URINEAMT - Parameter Validation */

      /* Validate - urWhere - none */

      /* Validate - urDataset */
      %if not %sysfunc(exist(&urDataset)) %then
      %do;
        %put RTE%str(RROR): &sysmacroname: URINEAMT: Specified dataset (&urDataset) not found;
        %let g_abort = 1;
      %end;

      /* Validate - urBy */  /*AR8*/
      %if %length(%tu_chkvarsexist(&urDataset,&urDonorBy)) ne 0 %then  /*AR11*/
      %do;
        %put RTE%str(RROR): &sysmacroname: URINEAMT: Specified/implied BY variable(s) (&urDonorBy) not found in specified dataset (&urDataset);
        %let g_abort = 1;
      %end;
      %if %length(%tu_chkvarsexist(&currentDataset,&urBy)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: URINEAMT: Specified BY variable(s) (&urBy) not found in prevailing dataset (&currentDataset);
        %let g_abort = 1;
      %end;

      %tu_abort;  /*AR13 */

      /* Check for appropriate number of observations in donor dataset */  /*AR4*/
      proc freq data=&urDataset 
                     (where=(pctypcd eq '2'  /*AR8*/
                             %if %length(&urWhere) gt 0 %then
                             %do;
                               and &urWhere
                             %end;
                            )
                     );
        table %sysfunc(translate(&urDonorby,%str(*),%str( )))  /*AR6*//*AR8*/
              / 
              noprint 
              out=work.&prefix._ur_chk_&&dvname&counter;
      run;

      %local urHeader;
      %let urHeader = Validate URINEAMT donor dataset &urDataset where=[pctypcd eq '2';  /*AR8*/
      %if %length(&urWhere) gt 0 %then
      %do;
        %let urHeader = &urHeader and &urWhere;  /*AR9*/
      %end;
      %let urHeader = &urHeader];

      data _null_;
        set work.&prefix._ur_chk_&&dvname&counter end=finish;
        drop __msg;
        %tu_xcpsectioninit(header=&urHeader);  /*AR8*/
        if count ne 1 then
        do;
          %tu_byid(dsetin=work.&prefix._ur_chk_&&dvname&counter
                  ,invars=&urDonorBy  /*AR6*//*AR8*/
                  ,outvar=__msg
                  );
          %tu_xcpput("Donor dataset contains multiple rows for " !! __msg
                    ,WARNING);
        end;
        %tu_xcpsectionterm(end=finish);
      run;
      %tu_abort;

      /* URINEAMT - Normal Processing */
 
      proc sql noprint;
        create table work.&prefix._urineamt_&&dvname&counter as
          select current.*
                   /*
                   / if pcstresn eq . then urineamt = 0 
                   / else urineamt = pcstresn * pcvol 
                   /------------------------------------------------------*/
                 , case 
                     when pcstresn eq . then 0
                     else                    pcstresn * pcvol
                   end as &&dvname&counter
          from &currentDataset current
               left join
               &urDataset (rename=(pcstdt=&outdate pcsttm=&outtime)
                           where=(pctypcd eq '2'  /*AR8*/
                                  %if %length(&urWhere) gt 0 %then
                                  %do;
                                    and &urWhere
                                  %end;
                                 )
                          ) pkcnc
          on %tu_sqlnlist(&urBy,current,pkcnc)  /*AR8*/
          ;
      quit;
      %let currentDataset = &prefix._urineamt_&&dvname&counter;

    %end; /* URINEAMT */

    %else
    %do;
      %put RTE%str(RROR): &sysmacroname: Unexpected logical condition for derived variable type: &&dvtype&counter;
      %tu_abort(option=force);
    %end;


  %end; /* Create the derived vars, one-by-one */

  /* 4. Create output dataset */
  data &dsetout;
    set &currentDataset;
  run;

  /* Finish-off */
  %tu_tidyup(rmdset=&prefix:
            ,glbmac=NONE
            );
  quit;

  %tu_abort;

%mend tu_nmderv;
