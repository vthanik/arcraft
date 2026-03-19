/*--------------------------------------------------------------------------+
/ Macro Name    : tu_expvarlist.sas
/
/ Macro Version:  2
/
/ SAS version   : SAS v8.2
/
/ Created By    : John Henry King
/
/ Date          : 22-May-2003
/
/ Macro Purpose : Expand SAS variable lists
/
/ Macro Design  : Call routine
/
/ Input Parameters :
/
/ NAME     DESCRIPTION                                                    DEFAULT
/-----------------------------------------------------------------------------------
/ DSETIN   Input data set Data set that the abbreviated list relates to.  no default
/          The variables in this data set are used to expand the list.
/
/ VARSIN   List of variables to be expanded.
/
/ VAROUT   Name of macro variable to receive the expanded list. Usually   _expvarlist
/          this variable should be local to the calling macro.
/
/ SCOPE   Directs the macro to make the variable named in VAROUT  NO
/                global or not.
/ SEPARATED_BY   Specifies the character(s) to use to separate the names
/                in the expanded list.
/
/ Output: Updates the value of the macro variable named in VAROUT.
/
/ Global macro variables created: The macro may create a global macro variable
/ if directed to do so by &GLOBALVAROUT.
/
/ Macros called :
/(@) tu_putglobals
/(@) tu_abort
/(@) tu_chknames
/(@) tu_tidyup
/
/
/ **************************************************************************
/ Change Log :
/
/ Modified By : John King
/ Date of Modification : 24Jul03
/ New Version Number : 1/2
/ Modification ID : JK001
/ Reason For Modification : Correct typo in error message.
/
/ Modified by:              Yongwei Wang
/ Date of modification:     02Apr2008
/ New version number:       2/1
/ Modification ID:          YW001
/ Reason for modification:  Based on change request HRT0193
/                           1.Echo macro name and version and local/global macro                                            
/                             variables to the log when g_debug > 0   
/                           2.Output Exiting macro message to the log when g_debug > 0 
/                           3. Replaced %inc tr_putlocal.sas with %put statements
/----------------------------------------------------------------------------*/

%macro tu_expvarlist(
         Dsetin         = ,             /* input data */
         VARSIN         = ,             /* SAS abbreviated VAR list */
         VAROUT         = _expvarlist,  /* Macro VAR to recieve expanded var list */
         SCOPE          = ,             /* Scope for VAROUT. May be GLOBAL or blank. */
         Separated_By   = ' '           /* Character string to place between names */
      );

   %local MacroVersion;
   %let MacroVersion = 2;
    
   %if &g_debug GT 0 %then
   %do;
   
      %put ************************************************************;
      %put * Macro name: &sysmacroname,  Macro Version: &macroVersion ;
      %put ************************************************************;
    
      %put * &sysmacroname has been called with the following parameters: ;
      %put * ;
      %put _local_;
      %put * ;
      %put ************************************************************;
      
      %tu_putglobals()
      
   %end;

   %local 
      workroot      /* work data names */
      globalvarout  /* flag for global varout */
      ;
   %let workroot = %substr(&sysmacroname,3);


   %if       %nrbquote(&Separated_By) EQ ' ' %then;
   %else %if %nrbquote(&Separated_By) EQ     %then
   %do;
      %let g_abort = 1;
      %put %str(RTER)ROR: &sysmacroname: Parameter SEPARATED_BY must not be blank.;      
   %end;
   %else %if %index(%nrstr(%'%"),%qsubstr(&Separated_By,1,1)) EQ 0
      %then %let Separated_by = %sysfunc(quote(&Separated_By));

   %if %upcase(&scope) EQ  GLOBAL
      %then %let GlobalVAROUT = 1;
      %else %let GlobalVAROUT = 0;

   %if %nrbquote(&VAROUT) EQ %then 
   %do;
      %let g_abort = 1;
      %put %str(RTER)ROR: &sysmacroname: Parameter VAROUT must not be blank.;
   %end;

   %if %nrbquote(&dsetin) EQ %then %do;
      %let g_abort = 1;
      %put %str(RTER)ROR: &sysmacroname: Parameter DSETIN must not be blank.;
   %end;

   %if %nrbquote(&VARSIN) EQ %then
   %do;
      %let g_abort = 1;
      %put %str(RTER)ROR: &sysmacroname: Parameter VARSIN must not be blank.;
   %end;

   %if %sysfunc(exist(&dsetin)) EQ 0 %then
   %do;
      %let g_abort = 1;
      %put %str(RTER)ROR: &sysmacroname: SAS Data Set &dsetin does not exist.;
   %end;
   
   /*
   / Check that &VAROUT is a valid SAS name
   /----------------------------------------------*/
   %if %bquote(%tu_chknames(%bquote(&VAROUT),VARIABLE)) EQ %then 
   %do;
      %if &GlobalVAROUT %then
      %do;
         %global &VAROUT;
      %end;  
      %let &VAROUT = ;
   %end;
   %else
   %do;
      %let g_abort = 1;
      %put %str(RTER)ROR: &sysmacroname: The name specified in %nrstr(&VAROUT) is not a valid SAS variable name.;
   %end;

   %if &g_abort = 1 %then %goto macerror; 

   /*
   / Create the view using a data step because there seems to be a bug
   / in proc SQL that prevents it from setting SQLRC or SYSERR
   / when the &VARSIN has a variable that does not exist.
   / Using the DATA step I can check SYSERR and set G_ABORT properly.
   /--------------------------------------------------------------------*/
   data work.&workroot / view=work.&workroot;
      set &dsetin(keep=&VARSIN); /* this is where SAS expands the list for us */
      run;
   %if &syserr GT 0 %then
   %do;
      %put %str(RTER)ROR: &sysmacroname: An error occurred creating the data step view WORK.&workroot;
      %put %str(RTN)OTE: &sysmacroname: Most likely a variable listed in %nrstr(&VARSIN) was not found on %nrstr(&DSETIN);
      %goto macerror;
   %end;

   Proc Sql NOprint;
      select name into :&VAROUT separated by &Separated_By
         from dictionary.columns
         where libname='WORK' AND memname = "&workroot" AND memtype='VIEW'
         ;
      quit;
      run;
      
   %tu_tidyup(rmdset=&workroot,glbmac=none)

   %if &g_debug GT 0 %then
   %do;         
      %put %str(RTN)OTE: ----------------------------------------------------------------------------------;
      %put %str(RTN)OTE: Macro &sysmacroname Created or Altered Macro Variable: %upcase(&VAROUT);
      %put %str(RTN)OTE: &VAROUT=&&&VAROUT;
      %put %str(RTN)OTE: ----------------------------------------------------------------------------------;
   %end;
   %goto exit;
   
 %macerror:
   %let g_abort = 1;
   %put %str(RTER)ROR: &sysmacroname: Ending with an error, setting G_ABORT=&g_abort, and calling %nrstr(%tu_abort).;
   %tu_abort()

%exit:
   %if &g_debug GT 0 %then
   %do;
     %put %str(RTN)OTE: &sysmacroname: Ending execution.;
   %end;
%mend tu_expvarlist;
