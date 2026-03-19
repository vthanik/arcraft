/*******************************************************************************
|
| Macro Name:      tu_valparms
|
| Macro Version:   02-001
|
| SAS Version:     9.1
|                                                             
| Created By:      James McGiffen
|
| Date:            14-Jun-2005
|
| Macro Purpose:   To validate the parameters passed to a macro. 
|                  Any failing parameters will result in an %str(RTE)RROR message 
|                  being written to the log and pv_abort being set to 1 and optionally 
|                  g_abort being set to 1 and tu_abort being called. 
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME            DESCRIPTION                                   REQ/OPT  DEFAULT
| --------------  -----------------------------------           -------  ---------------
|  abortYN        call tu_abort if fail                           REQ       N
|  allowblankYN   Allow the value to be blank                     OPT       N
|  chktype        The type of check required                      REQ    [blank]
|  macroname      Specifies the calling macro                     REQ    [blank]
|  pv_dsetin      The name of the input dataset                   OPT    [blank] 
|  pv_varsin      A list of macro variables                       OPT    [blank] 
|  pv_var1        A list of variables or values to compare        OPT    [blank] 
|  pv_var2        Another list of variables or values to compare  OPT    [blank] 
|  valuelist      A list of possible values                       OPT    [blank]   
| --------------  -----------------------------------      -------  ---------------
|
| Output: Issues RT messages to the log and sets g_abort
|
| Global macro variables created: NONE
|
| Macros called:
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_chkvarsexist
| (@) tu_chkvartype
| (@) tu_cr8macarray
| (@) tu_putglobals
| (@) tu_words
|
| Example:
|    %local pv_abort dsetin xvar;
|    %let dsetin = aedata.pkcnc;
|    %let xvar = subjid;
|    %let pv_abort = 0;
|    %tu_valparms(macroname=tu_pkcfig
|                ,chktype=varexist
|                ,pv_dsetin=dsetin
|                ,pv_varsin=xvar);
|
|******************************************************************************
| Change Log
|
| Modified By:              James McGiffen     
| Date of Modification:     22-Jun-05
| New version/draft number: 01-002
| Modification ID:          JMcG1.x
| Reason For Modification:  Response to SCR:
|                           JMcG1.1 - Update header info (no mod id comment)
|                           JMcG1.2 - Local errormess&i.
|                           JMcG1.3 - Inconsistant use of white space in flyover comment(no mod id due to harp)
|                           JMcG1.4 - Consistant use of .
|                           JMcG1.5 - Incorrect error message and tu_Abort
|                           JMcG1.6 - type and abort()  
|                           JMcG1.7 - Change notes to rtdebugs.
|
| Modified By:              James McGiffen
| Date of Modification:     03-Jul-05
| New version/draft number: 01-003
| Modification ID:          None  
| Reason For Modification:  Numerous small formatting changes in response to SCR - no logic changes
|
| Modified By:              James McGiffen
| Date of Modification:     13-Jul-05
| New version/draft number: 01-004
| Modification ID:          JMcG.01.004.1
| Reason For Modification:  JMcG.01.004.1 - add check for blank dsetin val
|
| Modified By:              James McGiffen
| Date of Modification:     19-Jul-05
| New version/draft number: 01-005
| Modification ID:          JMcG.01.005.1
| Reason For Modification:  JMcG.01.005.1 - change %eval's to %sysevalf for conditions that may contain
|                                           decimals
|			                      JMcG.01.005.2 - change the sysmacroname to macroname	
|                           JMcG.01.005.3 - changes to allow blank option for dsetin and varsin
|			
| Modified By:              Shan Lee 
| Date of Modification:     07-Apr-08
| New version/draft number: 02-001
| Modification ID:          SL001
| Reason For Modification:  The SCOPE variable in the SASHELP.VMACRO view was 9 characters in version
|                           8.2, so macro names were truncated to 9 characters before selecting the
|                           appropriate observations from this PROC SQL view. However, in SAS v 9.1,
|                           the SCOPE variable is not truncated to 9 characters, so, if macro names
|                           are truncated to 9 characters, then some observations will not
|                           be selected. The purpose of this modification is to enable this macro to
|                           run correctly in both SAS v8.2 and later versions of SAS.
|
| Modified By:           
| Date of Modification:
| New version/draft number:
| Modification ID:
| Reason For Modification:
*******************************************************************************/
%macro tu_valparms(
   abortyn = N      /*Call tu_abort if fail */
  ,allowblankYN = N /*Allow the value to be blank*/
  ,chktype=         /*The type of check required*/
  ,macroname =      /*Specifies the calling macro */  
  ,pv_dsetin =      /*The name of the input dataset*/
  ,pv_varsin=       /*A list of macro variables */
  ,pv_var1=         /*A list of variables or values to compare */
  ,pv_var2=         /*Another list of variables or values to compare */
  ,valuelist=       /*A list of possible values */
  );

  /*----------------------------------------------------------------------*/
  /*Normal Processing (NP) 1 - upcase required variables*/
  /*  JMcG1.4 - Consistant use of .*/
  %let chktype = %upcase(&chktype.);
  %let valuelist = %upcase(&valuelist.);
  %let abortyn = %upcase(&abortyn.);
  %let allowblankyn = %upcase(&allowblankyn.);
  %let macroname = %upcase(&macroname.);

  /*----------------------------------------------------------------------*/
  /*--NP2 -  Echo parameter values and global macro variables to the log */
  %local MacroVersion ;
  %let MacroVersion = 2;
  %if &g_debug. gt 0 %then %do;
    %include "&g_refdata/tr_putlocals.sas";
    %tu_putglobals();
  %end;

  %local prefix i err_cnt;
  %let prefix = %substr(&sysmacroname,3); 
  %let err_cnt = 0;

  /*----------------------------------------------------------------------*/
  /* NP3 - PARAMETER VALIDATION - PART1 - HAS TO BE DONE BEFORE WE DO ANYTHING ELSE */
  /*----------------------------------------------------------------------*/
  /*-- PV1 - Only allow multiple values in dsetin for certain checks*/
  %if %index("ISCHAR" "ISNUM", &chktype.) %then %do;
    %if %length(&pv_dsetin.) gt 0 and %tu_words(&pv_dsetin.) gt 1 %then %do;
      /*JMcG1.4 - Incorrect error message and tu_Abort*/
      %put %str(RTE)RROR: &sysmacroname.: Multiple values for dsetin (&pv_dsetin.) are not available for chktype &chktype;
      %let g_abort = 1;
      %tu_abort;
    %end;
  %end;

  /*----------------------------------------------------------------------*/
  /*-- PV2 - for certain checks check that pv_dsetin cannot be blank*/
  %if %index("DSETEXISTS" , &chktype.) %then %do;
    /*JMcG1.5 - type and abort()*/
    %if &pv_dsetin. eq  %then %do;
      %put %str(RTE)RROR: &sysmacroname.: Blank values for dsetin (&pv_dsetin.) are incorrect for chktype &chktype;
      %let g_abort = 1;
    %end;
  %end;

  /*----------------------------------------------------------------------*/
  /*-- PV3 - for certain checks pv_varsin should be blank */
  %if %index("DSETEXISTS" , &chktype.) %then %do;
    %if &pv_varsin. ne  %then %do;
      %put %str(RTW)ARNING: &sysmacroname.: Values for pv_varsin (&pv_varsin) are ignored for chktype &chktype;
    %end;
  %end;

  /*----------------------------------------------------------------------*/
  /*-- PV4 - for certain checks pv_varsin cannot be blank */
  %if %index("VAREXISTS" "VARNOTEXISTS" "ISONEOF" "ISNOTONEOF" "ISCHAR" "ISNUM" , &chktype.) and &pv_varsin. eq %then %do;
    %put %str(RTE)RROR: &sysmacroname.: Blank Values for pv_varsin (&pv_varsin) are incorrect for chktype &chktype;
    %let g_abort = 1;
  %end;

  /*----------------------------------------------------------------------*/
  /*-- PV5 - Check that the value of macro name is not blank or tu_valparms */
  %if %length(&macroname.) = 0 or &macroname. = TU_VALPARMS %then %do;
    %if %length(&macroname) eq 0 %then %put %str(RTE)RROR: &sysmacroname.: The value of macroname (&macroname.) cannot be blank;
    %else %put %str(RTE)RROR: &sysmacroname.: The value of macroname (&macroname.) cannot be &macroname.;
    %let g_abort= 1;  
    %tu_abort;
  %end;

  /*----------------------------------------------------------------------*/
  /*-- PV6 - for certain checks isblank and isnotblank should be blank */
  %if %index("ISBLANK" "ISNOTBLANK" , &chktype.) %then %do;
    /*--PV6.1 - allowblank should not be Y for this check*/
    %if &allowblankyn. = Y  %then %do;
      %put %str(RTW)ARNING: &sysmacroname.: AllowblankYN = &alloblankyn are ignored for chktype &chktype;
    %end;
    /*--PV6.1 - */
    %if &pv_dsetin. ne %then %do;
      %put %str(RTE)RROR: &sysmacroname.: For chktype (&chktype.) pv_dsetin cannot be blank;
      %let g_abort= 1;  
    %end;
  %end;
  
  /*----------------------------------------------------------------------*/
  /*--PV7 - check that the check that has asked to be done can be done*/
  
  /*----------------------------------------------------------------------*/
  /*The list of checks that this macro deals with*/
  /*1. dsetExists - That the dataset identified in dsetin exits*/
  /*2. varExists - That the variable(s) in varsin are in dsetin*/
  /*3. varNotExists - That the variable(s) in varsin are not in dsetin*/
  /*4. isOneOf - That the value of Varsin is in valuelist*/
  /*5. isNotOneof - That the value of Varsin is not in valuelist  */
  /*6. isChar - That the value in varsin is character*/
  /*7. ISNUM - That the value of varsin is numeric*/
  /*8. isBlank - That the value of varsin is blank*/
  /*9. isNotBlank - That the value of varsin is not blank*/
  /*10.isbetween - The value of varsin is between pv_val1 and pv_val2*/
  /**/
  %if %index("DSETEXISTS" "VAREXISTS" "VARNOTEXISTS" "ISONEOF"
             "ISNOTONEOF" "ISCHAR" "ISNUM" "ISBLANK" "ISNOTBLANK" 
             "ISBETWEEN" ,"&chktype") eq 0 %then %do;
    %put RTER%str(ROR): &sysmacroname: - The value of chktype (&chktype.) is not handled;
    %let g_abort = 1;
  %end;

  /*--PV8 - check that abortyn is one of Y or N*/
  %if %index("Y" "N" ,"&abortyn") eq 0 %then %do;
    %put RTER%str(ROR): &sysmacroname: - The value of abortyn (&abortyn.) should be Y or N;
    %let g_abort = 1;
  %end;

  /*--PV9 - check that allowblankyn is one of Y or N*/
  %if %index("Y" "N" ,"&allowblankyn") eq 0 %then %do;
    %put RTER%str(ROR): &sysmacroname: - The value of allowblankyn (&allowblankyn.) should be Y or N;
    %let g_abort = 1;
  %end;

  /*--PV10 - check that the pv_abort macro variable has been declared*/
  %local pv_abortyn;
  /* SL001: do not truncate MACRONAME if running versions of SAS greater than 8.2. */
  %if &sysver eq 8.2 %then 
  %do;
      proc sql noprint;
	select count(*) into :pv_abortyn 
	from sashelp.vmacro
	where scope = "%substr(%upcase(&macroname.),1,%sysfunc(min(%length(&macroname.),9)))"
	  and upcase(name) = 'PV_ABORT';
      quit;
  %end;
  %else %if &sysver gt 8.2 %then
  %do;
      proc sql noprint;
	select count(*) into :pv_abortyn 
	from sashelp.vmacro
	where scope = "%upcase(&macroname)"
	  and upcase(name) = 'PV_ABORT';
      quit;
  %end;

  %if &pv_abortyn ne 1 %then %do;
    %put RTER%str(ROR): &sysmacroname: - The macro variable pv_abort has not been declared in the calling macro;
    %let g_abort = 1;
  %end;

  
  /*conditionally call tu_abort*/
  %if &g_abort. gt 0 %then %do;
    %tu_abort;
  %end;

  /*End of paramter validation*/
  /*----------------------------------------------------------------------*/

  /*----------------------------------------------------------------------*/
  /*--NP4 -Create a series of macro variables called cm_* which will hold the name of */
  %local vmacroname numofobs i;
  /*JMCG1.7 - make the length of the substr to be dependand on the length of the macrovar*/
  /* SL001: do not truncate MACRONAME if running versions of SAS greater than 8.2. */
  %if &sysver eq 8.2 %then
  %do;
    %let vmacroname = %substr(%upcase(&macroname.),1,%sysfunc(min(%length(&macroname.),9)));
  %end;
  %else %if &sysver gt 8.2 %then
  %do;
    %let vmacroname = %upcase(&macroname);
  %end;

  /*----------------------------------------------------------------------*/
  /*-- NP4.1 create it for dsetin(s)*/
  %if &pv_dsetin. ne %then %do;
    /*for each dataset we have in varsin then get info*/
    %local dsetin0 thisone;
    %let dsetin0 = %tu_words(&pv_dsetin.); 
    %do I = 1 %to &dsetin0.;
      %local dsetin&i.;
    %end;
    %tu_cr8macarray(string = &pv_dsetin., prefix = dsetin, numelements= &dsetin0.);
    %do I = 1 %to &dsetin0.;
      %local cm_dsetin&i cm_dsetin_val&i.;
      %let cm_dsetin&i = &&dsetin&i.;
      /*-- need to check that that macro variable is a macro from above*/
      proc sql noprint;
        select count(*) into: numofobs
        from sashelp.vmacro
        where scope in ("GLOBAL", "&vmacroname."  )
        and upcase(compress(name)) = upcase("&&cm_dsetin&i.");
      quit;
      %if &numofobs. = 0 %then %do;
        %put %str(RTE)RROR: &sysmacroname.: The macro variable &&cm_dsetin&i. does not exist;
        %let g_abort = 1;
        %tu_abort;
      %end;
      %else %do;
        %let thisOne = %scan(&pv_dsetin.,&i);
        %let cm_dsetin_val&i = &&&thisone.;
        /*JMcG 1.8 - change occurancies of notes*/
        %if &g_debug. gt 0 %then 
        %put RTD%str(EBUG): The macro variable in &macroname. called &&cm_dsetin&i. = &&cm_dsetin_val&i.; 
      %end;
    %end; /*- end- do i = 1 to dsetin0*/
  %end; /*-end- dsetin ne */

  /*----------------------------------------------------------------------*/
  /*-- NP4.2 create it for varsin */
  %if &pv_varsin. ne %then %do;
    /*for each macro variable we have in varsin then get info*/
    %local varsin0 ;
    %let varsin0 = %tu_words(&pv_varsin.); 
    %do i = 1 %to &varsin0; %local varsin&i.; %end;
    %tu_cr8macarray(string = &pv_varsin., prefix = varsin, numelements= &varsin0.);
    %do I = 1 %to &varsin0.;
      %local cm_varsin&i. cm_varsin_val&i.;
      %let cm_varsin&i. = &&varsin&i.;
      /*-- need to check that that macro variable is a macro from above*/
      proc sql noprint;
        select count(*) into: numofobs
        from sashelp.vmacro
        where scope in ("GLOBAL", "&vmacroname."  )
        and upcase(compress(name)) = upcase("&&cm_varsin&i.");
      quit;
      %if &numofobs. = 0 %then %do;
        %put %str(RTER)ROR: &sysmacroname.: The macro variable &&cm_varsin&i. does not exist;
        %let g_abort = 1;
        %tu_abort;
      %end;
      %else %do;
        %let thisOne = %scan(&pv_varsin.,&i);
        %let cm_varsin_val&i = &&&thisone.;
        /*JMcG 1.7 - change notest to rtdebugs */
        %if &g_debug gt 0 %then %put RTD%str(EBUG):  The macro variable in &macroname. called &&cm_varsin&i. = &&cm_varsin_val&i.;      
      %end;
    %end; /*- end- do I = 1 to varsin */
  %end; /*-end- varsin ne */

  /*----------------------------------------------------------------------*/
  /*--NP5 - Process the checks*/

  /*----------------------------------------------------------------------*/
  /*NP 5.1 - Check type dsetExists  */
  %if &chktype. = DSETEXISTS %then %do;
    /*JMcG.01.005.03 - remove warning message*/
    %do I = 1 %to &dsetin0.;
      /*-- check that it dsetin is not missing*/
      %if &&dsetin&i. = %then %do;
        %put %str(RTE)RROR: &sysmacroname.: If chktype = &chktype then dsetin cannot be blank;
        %let g_abort =1;
      %end;
      %else %if &&cm_dsetin_val&i = and &allowblankyn = N %then %do;
        /*JMcG.01.004.1 - add check for blank dsetin val*/
        %put %str(RTE)RROR: &macroname: The dataset identified by macro variable %trim(&&cm_dsetin&i.) is blank;
        %let pv_abort = 1;
        %if &abortyn. = Y %then %let g_abort = 1;
      %end;
      %else %if not %sysfunc(exist(&&cm_dsetin_val&i.)) %then %do;
        %put %str(RTE)RROR: &macroname: The dataset identified by macro variable %trim(&&cm_dsetin&i.) (&&cm_dsetin_val&i.) does not exist;
        %let pv_abort = 1;
        %if &abortyn. = Y %then %let g_abort = 1;
      %end;
    %end; /*-end- do i to dsetino */
    %if &abortyn. = Y %then %do;
      %tu_abort;
    %end;
  %end; /*-End - chktype = DSETEXISTS*/


  /*----------------------------------------------------------------------*/
  /*-- NP5.2  - Check type varExists and varNotExists*/
  %if %index("VAREXISTS" "VARNOTEXISTS","&chktype.")  %then %do;
    /*-- issue an error if there is no dsetin - as it needs to be populated */
    %if &pv_dsetin. = %then %do;
      %put %str(RTE)RROR: &sysmacroname.: If chktype = &chktype. then dsetin cannot be blank;
      %let g_abort = 1;
      %tu_abort;
    %end;
    %else %if %sysfunc(exist(&cm_dsetin_val1.)) = 0 %then %do;
      /*--if the dataset that the variables are on does not exist then error  */
      %put %str(RTE)RROR: &sysmacroname.: The dataset in pv_dsetin (&cm_dsetin1 = &cm_dsetin_val1) does not exist;
      %let g_abort = 1;
      %tu_abort;
    %end;
    %else %if &pv_varsin. = %then %do;
      /*-- check that varsin is populated for this type of check */
      %put %str(RTE)RROR: &sysmacroname.: If chktype = &chktype. then varsin cannot be blank;
      %let g_abort =1;
      %tu_abort;
    %end;
    %else %do;
      /*--  For each variable we have check that it exists*/
      %do I = 1 %to &varsin0.;
        /*JMcG1.7 - change notest to debugs */
        %if &g_debug. gt 0 %then %put RTD%STR(EBUG): Checking that variable &&cm_varsin_val&i. (MV: &&cm_varsin&i.) is on &cm_dsetin_val1. (MV: &cm_dsetin1.);
        /*JMcG.01.005.3 - allowblankYN logic for varexists and varnotexists*/
        %if %length(&cm_varsin_val1) = 0 %then %do;
          %if &allowblankyn. = N %then %do;
            %let err_cnt = %eval(&err_cnt.+1);
            %local errormess&err_cnt.;
            %let errormess&err_cnt. = %str(RTE)RROR: &macroname: The variable(s) identified in macro variable %upcase(&&cm_varsin&i) (&&cm_varsin_val&i.) is blank and should not be;
            %let pv_abort = 1;
            %if &abortyn. = Y %then %let g_abort = 1;
          %end; /*-  allowblank = N*/
        %end;/* - length cm_varsin_val1 = 0 */
        %else %if &chktype. = VAREXISTS and %tu_chkvarsexist(&cm_dsetin_val1., &&cm_varsin_val&i.) ne  %then %do;
          /*-- error messsage for varexists check */
          %let err_cnt = %eval(&err_cnt.+1);
          /* JMcG1.2 - Local errormess&i.*/
          %local errormess&err_cnt.;
          %if %upcase(&&cm_varsin&i) ne PV_CHECKVARS %then %do;
            /*JMcG 1.8 - remove repeated word*/
            %let errormess&err_cnt. = %str(RTE)RROR: &macroname: The variable(s) identified in macro variable %upcase(&&cm_varsin&i) (%left(%tu_chkvarsexist(&cm_dsetin_val1., &&cm_varsin_val&i.))) do not exist in &cm_DSETIN1. (&cm_dsetin_val1.) ;
          %end;
          %else %do;
            %let errormess&err_cnt. = %str(RTE)RROR: &macroname: The required variable(s) %left(%tu_chkvarsexist(&cm_dsetin_val1., &&cm_varsin_val&i.)) do not not exist in &cm_DSETIN1. (&cm_dsetin_val1.);
          %end;
          %let pv_abort = 1;
          %if &abortyn. = Y %then %let g_abort = 1;
        %end;
        %if &chktype. = VARNOTEXISTS and %tu_chkvarsexist(&cm_dsetin_val1., &&cm_varsin_val&i.) eq  %then %do;
          /*--error message for varnotexists check */
          %let err_cnt = %eval(&err_cnt.+1);
          /* JMcG1.2 - Local errormess&i.*/
          %local errormess&err_cnt.;
          %if %upcase(&&cm_varsin&i) ne PV_CHECKVARS %then %do;
            %let errormess&err_cnt. = %str(RTE)RROR: &macroname: The variable(s) identified in macro variable %upcase(&&cm_varsin&i) (&&cm_varsin_val&i.) already exist in %upcase(&cm_DSETIN1.) (&cm_dsetin_val1.);
          %end;
          %else %do;
            %let errormess&err_cnt. = %str(RTE)RROR: &macroname: The variable(s) %left(%tu_chkvarsexist(&cm_dsetin_val1., &&cm_varsin_val&i.)) already exist in %upcase(&cm_DSETIN1.) (&cm_dsetin_val1.);
          %end;
          %let pv_abort = 1;
          %if &abortyn. = Y %then %let g_abort = 1;
        %end;
      %end; /*-end- of do I = 1 %to varsin */
    %end; /*-end- of else do */
    %if &abortyn. = Y %then %tu_abort;
  %end; /*-end - chktype = VAREXISTS*/

  /*----------------------------------------------------------------------*/
  /*--NP 5.3 \ 5.4 - Processing for checktype isOneOf and isNotOneOf*/
  %if %index("ISONEOF" "ISNOTONEOF" "ISBLANK" "ISNOTBLANK","&chktype.") %then %do;
    /*-- pv -if dsetin is populated then it is ignored */
    %if &pv_dsetin. ne %then %do;
      %put %str(RTWAR)NING: &sysmacroname.: If chktype = &chktype. then dsetin should be blank;
    %end;
    %if &pv_varsin. = %then %do;
      /*-- PV check that varsin is populated for this type of check */
      %put %str(RTE)RROR: &sysmacroname.: If chktype = &chktype. then varsin cannot be blank;
      %let g_abort =1;
      %tu_abort;
    %end;
    %if %index("ISONEOF" "ISNOTONEOF" ,"&chktype.") and &valuelist. = %then %do;
      /*-- PV XX - check that varsin is populated for this type of check */
      %put %str(RTE)RROR: &sysmacroname.: If chktype = &chktype. then valuelist cannot be blank;
      %let g_abort =1;
      %tu_abort;
    %end;
    %else %do;
      /*-- np XX - For each variable we have check that it either on or not on the list*/
      %do I = 1 %to &varsin0.;
        /*--PV  XX - For each macro variable resolution we want to check that there is only one word */
        %if %index("ISONEOF" "ISNOTONEOF" ,"&chktype.") and %tu_words(&&cm_varsin_val&i.) gt 1 %then %do;
          %put %str(RTE)RROR: &sysmacroname: For chktype &chktype Only one value can be passed in macro variable &&cm_varsin&i (&&cm_varsin_val&i);
          %let pv_abort = 1;
          %if &abortyn. = Y %then %let g_abort = 1;
          %tu_abort;        
        %end;
        /*np XX - if the value is blank and we have a blank then its ok*/
        %if %index("ISONEOF" "ISNOTONEOF" ,"&chktype.") gt 0 and &allowblankyn. = Y and %length(&&cm_varsin_val&i.) = 0 %then %do;
        %end;
        %else %if &chktype. = ISONEOF and %index(%upcase(&valuelist.), %upcase(&&cm_varsin_val&i.)) = 0  %then %do;
          /*-- error messsage for varexists check */
          %let err_cnt = %eval(&err_cnt.+1);
          /* JMcG1.2 - Local errormess&i.*/
          %local errormess&err_cnt.;
          %let errormess&err_cnt. = %str(RTE)RROR: &macroname: &&cm_varsin&i (&&cm_varsin_val&I.) is not one of &valuelist.;
          %if &abortyn. = Y %then %let g_abort = 1;
          %let pv_abort = 1;
        %end;
        %else %if &chktype. = ISNOTONEOF and %index(%upcase(&valuelist.), %upcase(&&cm_varsin_val&i.)) gt 0 %then %do;
          /*--error message for varnotexists check */
          %let err_cnt = %eval(&err_cnt.+1);
          /* JMcG1.2 - Local errormess&i.*/
          %local errormess&err_cnt.;
          %let errormess&err_cnt= %str(RTE)RROR: &macroname: &&cm_varsin&i (&&cm_varsin_val&I.) is one of &valuelist.;
          %if &abortyn. = Y %then %let g_abort = 1;
          %let pv_abort = 1;
        %end;
        /*--NPXX.X -Checks for isblank and isnotblank */
        %if &CHKTYPE. = ISBLANK and &&cm_varsin_val&i. ne  %then %do;
          %let err_cnt = %eval(&err_cnt.+1);
          /* JMcG1.2 - Local errormess&i.*/
          %local errormess&err_cnt.;
          %let errormess&err_cnt = %str(RTE)RROR: &macroname: &&cm_varsin&i (&&cm_varsin_val&I.) is not blank;
          %if &abortyn. = Y %then %let g_abort = 1;
          %let pv_abort = 1;
        %end;
        %if &CHKTYPE. = ISNOTBLANK and &&cm_varsin_val&i. =  %then %do;
          %let err_cnt = %eval(&err_cnt.+1);
          /* JMcG1.2 - Local errormess&i.*/
          %local errormess&err_cnt.;
          %let errormess&err_cnt. = %str(RTE)RROR: &macroname: &&cm_varsin&i (&&cm_varsin_val&I.) is blank;
          %if &abortyn. = Y %then %let g_abort = 1;
          %let pv_abort = 1;
        %end;/*-end - of chktype is isnotblank*/
      %end; /*-end- of do I = 1 %to varsin */
    %end; /*-end- of else do */
    %if &abortyn. = Y %then %tu_abort;
  %end; /*-end - chktype = isOneOf or isNotOneOf*/

  /*----------------------------------------------------------------------*/
  /*--NP 5.5 - Processing for checktype isChar or ISNUM*/
  %if %index("ISCHAR" "ISNUM","&chktype.") %then %do;

    /*-- if dsetin is populated then it only resolves to one dataset */
    %if &pv_dsetin. ne %then %do;
      %if %tu_words(&cm_dsetin_val1.) gt 1 %then %do;
        %put %str(RTER)RROR: &sysmacroname.: If chktype = &chktype. then pv_dsetin (&cm_dsetin_val1.) can only resolve to one dataset;
        %let g_abort = 1;
        %tu_abort;
      %end;
      /*-- if we have a value in pv_dsetin then the dataset must exist */
      %if &cm_dsetin_val1. ne %then %do;
        /*-- This check could possibly done by the macro calling itself but it becomes way to complex*/
        %if %sysfunc(exist(&cm_dsetin_val1.)) = 0 %then %do;
          %put %STR(RTE)RROR: &sysmacroname.: The dataset supplied by pv_dsetin (&cm_dsetin_val1.) does not exist;
          %let g_abort = 1;
          %tu_abort;
        %end; /*- end exist(cm_dsetin_val1) */
      %end; /*- end- cm_dsetin_val1 ne */
    %end; /*- End - pv_dsetin = blank */
    /*-- For each variable we have check that it either character or numeric*/
    %do I = 1 %to &varsin0.;
      /* For each value in each macro variable passed then test */
      %local x thisword thiswordtype;
      /*-- check that there are values for this macro variable */
      %if %tu_words(&&cm_varsin_val&i.) lt 1 %then %do;
        /*- there are no values for this macro varaiable*/;
        %if &allowblankyn. = N %then %do;
	        /* JmcG.1.005.2 change sysmacroname to macroname */		        
          %put %str(RTE)RROR: &macroname.: The macro variable &&cm_varsin&i. is blank;
          %let pv_abort = 1;
          %if &abortyn. = Y %then %do;
            %let g_abort = 1;
            %tu_abort;
          %end; /*-end- abortyn = Y*/
        %end; /*-end- allowbalnkyn = Y*/
      %end; /*-end- tu_words lt 1*/
      %else %do;
        %do x = 1 %to %tu_words(&&cm_varsin_val&i.);
        /*-- get the word we are dealing with */
          %let thisword = %scan(&&cm_varsin_val&i, &x.);
          /* if pv_dsetin has not been supplied then we want to check the type of macro variable*/
          %if &pv_dsetin. = %then %do;
            %Let thiswordtype = %substr(%datatyp(&&thisword.),1,1);
          %end;
          %else %do;
            /*if pv_dsetin is supplied then look for the value of the varaible */
            %if %tu_chkvartype(&cm_dsetin_val1., &thisword.) = -1 %then %do;  
              /*JMcG.01.005.2 */
              %put %str(RTE)RROR: &macroname.: Cannot determine the type of variable from &&cm_varsin&i. (&thisword.) from dataset supplied by pv_dsetin (&cm_dsetin_val1.);
              %let pv_abort = 1;
              %if &abortyn. = Y %then %do; 
                %let g_abort = 1;
                %tu_abort;
              %end;/*-end- abortyn = y */
            %end;/*-end- tu_chkvartype = -1*/
            %else %let thiswordtype = %tu_chkvartype(&cm_dsetin_val1., &thisword.);
          %end;/*-end of else do */
        %end;/*- end of - %tu_words else do */
        /* - if the value is blank and we have a blank then its ok*/
        %if &allowblankyn. = Y and &thisword. = %then %do;
          /*-- we have a blank value but and allowblank yn = Y */
        %end;
        %else %if &chktype. = ISCHAR and &thiswordtype. = N %then %do;
          /*-- error messsage for varexists check */
          %if %length(&pv_dsetin.) gt 0 %then %do;
            %let err_cnt = %eval(&err_cnt.+1);
            /* JMcG1.2 - Local errormess&i.*/
            %local errormess&err_cnt.;
            %let errormess&err_cnt. = %str(RTE)RROR: &macroname: The variable &thisword. supplied by &&cm_varsin&i on dataset &pv_dsetin. (&&cm_dsetin_val1.) is not character.;
            %if &abortyn. = Y %then %let g_abort = 1;
            %let pv_abort = 1;
          %end;
          %else %do;
            %let err_cnt = %EVAL(&err_cnt.+1);
            /* JMcG1.2 - Local errormess&i.*/
            %local errormess&err_cnt.;
            %let errormess&err_cnt. = %str(RTE)RROR: &macroname: The macro variable &&cm_varsin&i (value = &&thisword.) is not character.;
            %let pv_abort = 1;
            %if &abortyn. = Y %then %let g_abort = 1;
          %end;
        %end;
        %else %if &chktype. = ISNUM and &thiswordtype. = C %then %do;
          /*--error message for varnotexists check */
          %if %length(&pv_dsetin.) gt 0 %then %do;
            %let err_cnt = %eval(&err_cnt.+1);
            /* JMcG1.2 - Local errormess&i.*/
            %local errormess&err_cnt.;
            %let errormess&err_cnt. = %str(RTE)RROR: &macroname: The variable &thisword. supplied by &&cm_varsin&i on dataset &&pv_dsetin. (&&cm_dsetin_val1.) is not numeric.;
            %let pv_abort = 1;  
            %if &abortyn. = Y %then %let g_abort = 1;
          %end;
          %else %do;
            %let err_cnt = %eval(&err_cnt.+1);
            /* JMcG1.2 - Local errormess&i.*/
            %local errormess&err_cnt.;
            %let errormess&err_cnt. = %str(RTE)RROR: &macroname: The macro variable &&cm_varsin&i (value = &&thisword.) is not numeric.;
            %let pv_abort = 1;
            %if &abortyn. = Y %then %let g_abort = 1;
          %end;
        %end;
      %end; /*- end- of each word in cm_varsin_val */
    %end; /*-end- of do I = 1 %to varsin */
    %if &abortyn. = Y %then %tu_abort;
  %end; /*-end - chktype = ISNUM  or ischar*/

  /*----------------------------------------------------------------------*/
  /*--NP5.6 -processing for chktype isbetween */  
  %if %index("ISBETWEEN" ,"&chktype.") %then %do;
    /*-- first check that we have a dataset - if so we are checking vars*/
    %if %length(&pv_dsetin) = 0 %then %do;
      /*- no dataset - we are then using macro vars*/
      /*--for each macro variable passed we have  */
      %do I = 1 %to &varsin0.;
        /*-- we can only deal with one macro variable per varsin*/
        /*JMcG.01.005.1 - change %eval's to %sysevalf*/
        %if %sysevalf(&&cm_varsin_val&i. lt &pv_var1.) %then %do;
          %let err_cnt = %eval(&err_cnt.+1);
          /* JMcG1.2 - Local errormess&i.*/
          %local errormess&err_cnt.;
          %let errormess&err_cnt. = %str(RTE)RROR: &macroname: &&cm_varsin&i. (&&cm_varsin_val&i) should be between &pv_var1. and &pv_var2.;
          %let pv_abort = 1;
          %if &abortyn. = Y %then %let g_abort = 1;
        %end;
        /*JMcG.01.005.1 - change %eval's to %sysevalf*/
        %if %sysevalf(&&cm_varsin_val&i. gt &pv_var2.) %then %do;
          %let err_cnt = %eval(&err_cnt.+1);
          /* JMcG1.2 - Local errormess&i.*/
          %local errormess&err_cnt.;
          %let errormess&err_cnt = %str(RTE)RROR: &macroname: &&cm_varsin&i. (&&cm_varsin_val&i) should be between &pv_var1. and &pv_var2.;
          %let pv_abort = 1;
          %if &abortyn. = Y %then %let g_abort = 1;
        %end;
      %end;
      %if &abortyn. = Y %then %tu_abort;
    %end;
    %else %do;
      /*-- there is a dataset - we want to use actual vars*/
      %put %str(RTE)RROR: &sysmacroname: This macro does not currently support range checking for variables ;
    %end;
  %end; /*-end = isbetween is not in range*/

  /*----------------------------------------------------------------------*/
  /*--NP6 - output all the error messages */
  %if &err_cnt gt 0 %then %do;
    %put %str(RTE)RROR: &macroname: The following &err_cnt. error message(s) where produced;
    %do i = 1 %to &err_cnt.;
      %put &&errormess&i.;
    %end;
  %end;
  %if &g_debug. gt 0 %then
  %put %str(RTD)EBUG: &sysmacroname.: The value of pv_abort after chktype = &chktype, pv_varsin = &pv_varsin =  pv_abort = &pv_abort. g_abort = &g_abort.;

  /*----------------------------------------------------------------------*/
  /*--NP7 - tidy up and do not call abort - there is no tidy up required in this macro*/
%mend ;
