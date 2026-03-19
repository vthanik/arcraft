/******************************************************************************* 
|
| Macro Name:      tu_unitpairs.sas
|
| Macro Version:   1.0
|
| SAS Version:     8.2
|
| Created By:      Andrew Ratcliffe, RTSL, www.ratcliffe.co.uk
|
| Date:            19-Jun-2005
|
| Macro Purpose:   To rename variables based upon their associated units. 
|                  Variables shall be renamed thus: varname_(unit), where unit 
|                  is the value of the associated units variable.
|                  It shall be the caller's responsibility to set appropriate SAS 
|                  options to permit such variable names, i.e. OPTIONS VALIDVARNAME=ANY.
|
| Macro Design:    PROCEDURE STYLE MACRO
| 
| Input Parameters:
|
| NAME              DESCRIPTION                         DEFAULT 
| COLORDER          Specifies the order in which        [blank] (Opt)
|                   columns shall be placed in the 
|                   output dataset. All variables in the input dataset are copied 
|                   to the output dataset, except the units variables. Variables 
|                   not included in COLORDER will be placed at the right-hand 
|                   end of the dataset 
|
| DSETIN            Specifies the name of the input     [blank] (Req)
|                   dataset
|
| DSETOUT           Specifies the name of the output    [blank] (Req)
|                   dataset
|
| UNITPAIRS         Specifies the variables and their   [blank] (Opt)
|                   associated units variables. Each 
|                   pair shall be mated by an equals sign, 
|                   e.g UNITPAIRS = age=ageu pcstresn=pcstresu
|
| Output: This macro produces a copy of the input dataset, with renamed variables. 
|         Units variables are dropped
|
| Global macro variables created:  None
|
| Macros called:
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_chknames
| (@) tu_chkvarsexist
| (@) tu_chkvartype
| (@) tu_tidyup
| (@) tu_abort
|
| Example:
|
| %tu_unitpairs(colorder = subjid visitnum date tim2
|              ,dsetin = work.une
|              ,dsetout = deux
|              ,unitpairs = amt=doseunit age=ageu
|              );
|
|******************************************************************************* 
| Change Log 
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     05-Jul-2005
| New version number:       1/2
| Modification ID:          
| Reason For Modification:  Finish-off the list of sub-macros.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     29-Jul-2005
| New version number:       1/3
| Modification ID:          AR3
| Reason For Modification:  Enhance text for Purpose, and add check for options validvarname=any.
|                           Ensure the vars in COLORDER are simple (up to 32 chars) not 'var'n style.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     02-Sep-2005
| New version number:       1/4
| Modification ID:          AR4
| Reason For Modification:  Fix: Set default vaue for DSETOUT correctly in header.
|
| Modified By:              
| Date of Modification:     
| New version number:       
| Modification ID:          
| Reason For Modification:  
|
********************************************************************************/ 

%macro tu_unitpairs(colorder  = /* Column order of output dataset */
                   ,dsetin    = /* type:ID Name of input dataset */
                   ,dsetout   = /* Output dataset */
                   ,unitpairs = /* Variables and associated units variables */
                   );

  /* Echo parameter values and global macro variables to the log */
 
  %local MacroVersion;
  %let MacroVersion = 1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals();

  %local prefix;
  %let prefix = %substr(&sysmacroname,3); 

  /* PARAMETER VALIDATION */

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

  /* Verify that UNITPAIRS variables exist in the DSETIN dataset */
  %if %length(&unitpairs) ne 0 %then
  %do;
    %if %length(%tu_chkvarsexist(&dsetin,%sysfunc(translate(&unitpairs,' ','=')))) ne 0 %then
    %do;
      %put RTE%str(RROR): &sysmacroname.: For UNITPAIRS (&unitpairs), one or more variables do not exist in DSETIN (&dsetin);
      %let g_abort=1;
    %end;
  %end;

  /* Verify that COLORDER variables exist in the DSETIN dataset */
  %if %length(&colorder) ne 0 %then
  %do;
    %if %index(&colorder,%str(%')) gt 0 or %index(&colorder,%str(%")) gt 0 %then  /*AR3*/
    %do;
      %put RTE%str(RROR): &sysmacroname.: COLORDER (&colorder) must not contain quotes, i.e. 'var'n is not permitted;
      %let g_abort=1;
    %end;
    %else %if %length(%tu_chkvarsexist(&dsetin,&colorder)) ne 0 %then
    %do;
      %put RTE%str(RROR): &sysmacroname.: For COLORDER (&colorder), one or more variables do not exist in DSETIN (&dsetin);
      %let g_abort=1;
    %end;
  %end;

  /* Check that options validvarname=any is set */  /*AR3*/
  data _null_;
    set sashelp.voption;
    where optname eq 'VALIDVARNAME';
    if setting ne 'ANY' then
    do;
      put "RTE" "RROR: &sysmacroname.: OPTIONS VALIDVARNAME=ANY must be set, but is currently: " setting;
      call symput('G_ABORT','1');
    end;
  run;

  %tu_abort;

  /* NORMAL PROCESSING */

  /*
  / PLAN OF ACTION
  / 1. If we have any unitpairs, process them:
  / 1.1. Create temporary dataset for us to manipulate
  / 1.2. Get the first pair of units 
  / 1.3. Loop over the units pairs:
  / 1.3.1. Verify the syntax of a UNITPAIR (must include an equals sign) 
  / 1.3.2. Establish var and associated varunit 
  / 1.3.3. Make sure the unit var is character 
  / 1.3.4. Establish unit value (check it is consistent) 
  / 1.3.5. Verify that the units are non missing 
  / 1.3.6. Verify that the units are consistent, but ignore blank 
  / 1.3.7. Change name of variable 
  / 1.3.8. Prepare for next iteration 
  / 1.4. Produce the output dataset (drop units variables)
  / 2. If no unitpairs, just copy input dataset to output
  /------------------------------------------------------*/


  %if %length(&unitpairs) ne 0 %then
  %do;  /* We do have some unitpairs to process */

    /* 1.1. Create temporary dataset for us to manipulate */
    data work.&prefix;
      retain &colorder;  /*AR4*/
      set &dsetin;
    run;

    /* 1.2. Get the first pair of units */
    %local pair_ptr pair units unitvalues;
    %let pair_ptr = 1;
    %let pair = %scan(&unitpairs,&pair_ptr);

    %local var varunit;

    /* 1.3. Loop over the units pairs */
    %do %while(%length(&pair) gt 0);

      /* 1.3.1. Verify the syntax of a UNITPAIR (must include an equals sign) */
      %if %index(&pair,=) eq 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: The unitpair (&pair) is not specified correctly in UNITPAIRS (&unitpairs);
        %tu_abort(option=force);
      %end;

      /* 1.3.2. Establish var and associated varunit */
      %let var = %upcase(%scan(&pair,1,=));
      %let varunit = %scan(&pair,2,=);

      /* 1.3.3. Make sure the unit var is character */
      %if %tu_chkvartype(work.&prefix,&varunit) ne C %then
      %do;
        %put RTE%str(RROR): &sysmacroname: The unit variable (&varunit) specified in UNITPAIRS (&unitpairs) is not Character;
        %tu_abort(option=force);
      %end;
      %tu_abort;  /* Capture any parm errors in chkvartype (function style macro) */

      /* 1.3.4. Establish unit value (check it is consistent) */
      proc sql noprint;
       select distinct &varunit into: unitvalues separated by ','
         from work.&prefix
         ;
      quit;

      /* 1.3.5. Verify that the units are non missing */
      %if %length(&unitvalues) eq 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: The &var variable (specified in UNITPAIRS) has missing units (&varunit);
        %tu_abort(option=force);
      %end;

      /* 1.3.6. Verify that the units are consistent, but ignore blank */
      proc sql noprint;
       select distinct &varunit into: unitvalues separated by ','
         from work.&prefix
         where &varunit ne ''
         ;
      quit;

      %if %index(%nrbquote(&unitvalues.),%nrbquote(,)) ne 0 %then
      %do;
        %put RTE%str(RROR): &sysmacroname: The &var variable (specified in UNITPAIRS) has inconsistent units (&varunit): &unitvalues;
        %tu_abort(option=force);
      %end;

      /* 1.3.7. Change name of variable */
      proc datasets lib=work nolist;
        modify &prefix;
        rename &var="&var._(&unitvalues)"n;
      quit;

      /* 1.3.8. Prepare for next iteration */
      %let pair_ptr = %eval(&pair_ptr + 1);
      %let pair = %scan(&unitpairs,&pair_ptr);
      %let units = &units &varunit;

    %end; /* End of WHILE loop for each UNITPAIR */

    /* 1.4. Produce the output dataset (drop units variables) */
    data &dsetout;
      set work.&prefix;
      drop &units;
    run;

  %end;  /* We do have some unitpairs to process */

  /* 2. If no unitpairs, just copy input dataset to output */
  %else
  %do;  /* No unitpairs to process */
    data &dsetout;
      retain &colorder;
      set &dsetin;
    run;
  %end; /* No unitpairs to process */

  /* Finish-off */
  %tu_tidyup(rmdset=&prefix:
            ,glbmac=NONE
            );
  quit;

  %tu_abort;

%mend tu_unitpairs;
