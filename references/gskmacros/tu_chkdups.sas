/*******************************************************************************
|
| Macro Name:      %tu_chkdups
|
| Macro Version:   3
|
| SAS Version:     8.2
|
| Created By:      David Ward
|
| Date:            09-June-2003
|
| Macro Purpose:   This unit shall check for repeats of BY values in a dataset.
|
| Macro Design:    PROCEDURE STYLE MACRO
|                  Define macro version, and output parameters, and global macro variables to log
|                  Parameter validation
|                  Create copy of input data set with counter variable, and sort
|                  Obtain last by variable from list
|                  Output any duplicates to data set specified in dsetout
|                  Call tu_tidyup
|
| Input Parameters:
|
| NAME         DESCRIPTION                                                DEFAULT
|
| DSETIN       The name of the input dataset containing the variable(s)   None
|              to be checked.
| BYVARS       The names of the variable(s) to be checked for repeats     None
| RETVAR       The name of the macro variable that will contain           None
|              information on repeats. This variable shall be declared
|              local prior to calling tu_chkdups.
| DSETOUT      Name of dataset to contain non-unique BY values.                        
|
| Output:     The primary output from this macro is the update of a macro variable
|             specified in the RETVAR parameter. This macro shall have been declared
|             as a local macro variable in the environment in which the call to
|             tu_chkdups is made. The macro variable whose name is specified in the
|             RETVAR parameter will be updated with one of the following values:
|             1. The number of records that do not have unique by variables. ie. a
|                value of 0 indicates no duplicates. A positive integer indicates
|                duplicates exist.
|             2. A message to the log stating the name of the dataset that contains
|                records that do not have unique by variables.
|             3. -1 if parameters failed checks or any other programmatically captured
|                error occurs
|
| Global macro variables created: None
|
| Macros called:
|(@) tu_putglobals
|(@) tu_abort
|(@) tu_chkvarsexist
|(@) tu_nobs
|(@) tu_tidyup
|
| Example:
|
| * Prior to the macro call ;
| %local aerpt ;
|
| * Macro call ;
| %tu_chkdups(dsetin=ae,
|             byvars=subjid aestdt aesttm aeterm,
|             retvar=aerpt
|            );
|
| * After macro call ;
| %if &aerpt = 'value of interest to calling program' %then
| %do ;
|   * whatever you want to do ;
| %end ;
|
|*******************************************************************************
| Change Log
|
| Modified By:              Stephen Griffiths
| Date of Modification:     16-Jul-03
| New version number:       1/2
| Modification ID:
| Reason For Modification:  Comments arising from SCR incorporated
|
|*******************************************************************************
|
| Modified By:              Stephen Griffiths
| Date of Modification:     17-Jul-03
| New version number:       1/3
| Modification ID:
| Reason For Modification:  Comments arising from testing incorporated
|
|*******************************************************************************
|
| Modified By:              Stephen Griffiths
| Date of Modification:     18-Jul-03
| New version number:       1/4
| Modification ID:
| Reason For Modification:  Additional comment arising from testing incorporated
|
|*******************************************************************************
|
| Modified By:              Stephen Griffiths
| Date of Modification:     23-Jul-03
| New version number:       1/5
| Modification ID:
| Reason For Modification:  Added check for DSETIN, and moved check for RETVAR
|                           since this needs to be present for subsequent checks
|
|*******************************************************************************
|
| Modified By:              Shan Lee
| Date of Modification:     14-Jul-04
| New version number:       2/1
| Modification ID:	    SL001
| Reason For Modification:  Amend misleading (RTERR)OR messages, as requested in
|                           change control form HRT0030.
|
|*******************************************************************************
|
| Modified by:              Yongwei Wang
| Date of modification:     02Apr2008
| New version number:       3/1
| Modification ID:          YW001
| Reason for modification:  Based on change request HRT0193
|                           1.Echo macro name and version and local/global macro                                            
|                             variables to the log when g_debug > 0    
/                           2.Replaced %inc tr_putlocal.sas with %put statements
|
********************************************************************************/
%MACRO tu_chkdups(
  dsetin= ,              /* Input dataset containing the variables to be checked  */
  byvars= ,              /* Variables to be checked for repeats                   */
  retvar= ,              /* Name of the macro variable containing info on repeats */
  dsetout =              /* Name of dataset to contain non-unique BY values       */
  );
  /*
  / Define macro version, and output parameters, and global macro variables to log
  /-------------------------------------------------------------------------------*/
  %local MacroVersion ;
  %let MacroVersion = 3;
  
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
  
  /*
  / Parameter validation
  /-------------------------------------------------------------------------------*/
  %if %length(&retvar) eq 0 %then
  %do;
    %put %str(RTERR)%str(OR):TU_CHKDUPS: RETVAR is a required parameter and should not be blank;  /* SL001 */
     %let g_abort=1;
  %end;
  %tu_abort();
  %if %length(&dsetin) eq 0 %then
  %do;
    %put %str(RTERR)%str(OR): TU_CHKDUPS: DSETIN is a required parameter and should not be blank;  /* SL001 */
    %let g_abort=1;
    %let &retvar= -1;
  %end;
  %tu_abort();
  %if %sysfunc(exist(&dsetin)) eq 0 %then
  %do ;
    %put %str(RTERR)%str(OR): TU_CHKDUPS: Input dataset does not exist, or has an invalid name.;
    %let g_abort=1;
    %let &retvar = -1;
  %end;
  %tu_abort();
  %if %index(%nrbquote(&byvars),%str(%")%str(%')%str(,)) gt 0 %then
  %do;
    %put %str(RTERR)%str(OR): TU_CHKDUPS: By-variable list contains quotes and/or commas;
    %let g_abort=1;
    %let &retvar = -1;
  %end;
  %tu_abort();
  /*
  / This small section of error trapping is slightly different than anticipated.
  / It is necessary to check for the existance of byvars BEFORE the call to
  / tu_chkvarsexist, in order to get a meaningful error message.
  / In addition, if variables do not exist, then we need to produce a message
  / from TU_CHKDUPS, as well as the note from tu_chkvarsexist.
  /-----------------------------------------------------------------------------*/
  %if %length(&byvars) eq 0 %then 
  %do;
    %put %str(RTERR)%str(OR):TU_CHKDUPS: BYVARS is a required parameter and should not be blank;  /* SL001 */
    %let g_abort=1;
    %let &retvar=-1;
  %end;
  %else 
  %if %tu_chkvarsexist(dsetin=&dsetin, varsin=&byvars) ne %then
  %do;
    %put %str(RTERR)%str(OR):TU_CHKDUPS: One or more of the variables in BYVARS does not exist;
    %let g_abort=1;
    %let &retvar = -1;
  %end;
  %tu_abort();
  %if %length(&dsetout) eq 0 %then
  %do;
    %put %str(RTERR)%str(OR):TU_CHKDUPS: DSETOUT is a required parameter and should not be blank;  /* SL001 */
    %let g_abort=1;
    %let &retvar = -1;
  %end;
  %tu_abort();
  /*
  / Define local vars
  /-------------------------------------------------------------------------------*/
  %local prefix lastbyvar;
  %let prefix=_chkdups;
  /*
  / Create copy of input data set with counter variable, and sort
  /-----------------------------------------------------------------------*/
  data &prefix._chkdups1;
    set &dsetin;
    obs_number=_n_;
  run;
  proc sort data=&prefix._chkdups1 out=&prefix._chkdups2;
    by &byvars;
  run;
  /*
  / Obtain last by variable from list
  /-----------------------------------------------------------------------*/
  %let lastByVar = %SCAN(&byvars, -1) ;
  /*
  / Output all duplicates to data set specified in dsetout
  /-----------------------------------------------------------------------*/
  data &dsetout;
    set &prefix._chkdups2;
    by &byvars;
    if not first.&lastbyvar or not last.&lastbyvar then output &dsetout;
  run;
  %let &retvar = %tu_nobs(dsetin=&dsetout);
  %if &&&retvar gt 0 %then
    %put %str(RTNO)%str(TE):TU_CHKDUPS: &&&retvar duplicates have been found, and are stored in the &DSETOUT data set;
  %tu_tidyup(rmdset=&prefix.:,
             glbmac=none);
%MEND tu_chkdups ;
