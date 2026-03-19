/*******************************************************************************
|
| Macro Name:     tu_byid.sas
|
| Macro Version:  2
|
| SAS Version:    8.2
|
| Created By:     Trevor Welby
|
| Date:           15th December 2004
|
| Macro Purpose:  This macro creates an output string of variable names complete
|                 with their values for the current observation from a list of
|                 variables used in a BY statement
|               
|                 For example, the input variable list
|                 VAR1 VAR2 VAR3 .. etc 
|                 will produce an output string in the form 
|                 VAR1=value var1, VAR2=value var2, VAR3=value var3 .. etc.
|
|                 It is intended that this macro shall be used by the 
|                 %tu_xcpinit macro to provide an exception message 
|                 with a record identifier.
|
| Macro Design:   Statement style
|
| Input Parameters:
|
| NAME            DESCRIPTION                                    DEFAULT
| DSETIN          Specifies the name of the input dataset        [none] (Req)                                                     
|
| INVARS          Specifies the input list of variable names     [none] (Req)
|                 separated by a blank character. These 
|                 variables must appear in the dataset 
|                 specified by the DSETIN parameter
|
| OUTVAR          Name of the variable containing the            __msg (Req)          
|                 output list. The output list consists 
|                 of a list variable names along with 
|                 their values from the current iteration 
|                 of the datastep
|
|                 The value is formatted according to the 
|                 variables data type i.e. for character  
|                 variables the length shall be used, for
|                 numeric variables the 'BEST.' format shall 
|                 best used
|
|                 It shall be the callers responsibility 
|                 to drop this variable from the output 
|                 dataset 
|
| OUTVARLENGTH    Specifies the length of the variable          256 (Req)
|                 specified by OUTVAR parameter 
|
| Output:         Generates a string of the form:
|
|                 VAR1=value var1, VAR2=value var2, VAR3=value var3 .. etc.
|
|                 from an input string of: VAR1 VAR2 VAR3 .. etc.
|
| Global macro variables created: none 
|
| Macros called:
|(@) tu_chknames
|(@) tu_chkvarsexist
|(@) tu_chkvartype
|(@) tu_maclist
|(@) tu_putglobals
|(@) tu_varattr
|(@) tu_words
|
| Example:
|
|   data outdata;
|     set indata;
|     %tu_byid(dsetin=indata,invars=pcsmpid pcan subjid,outvar=message);
|     put "Record Identifier(s) : " message;
|   run;
|
|*******************************************************************************
| Change Log
|
| Modified By: Ian Barretto
| Date of Modification: 15th December 2004
| New version/draft number: 01-002
| Modification ID: IB10254.01-001
| Reason For Modification: Changed the tu_chkvarexist to tu_chkvarsexist in 
|                          the macro header. 
|*******************************************************************************
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     10-Mar-05
| New version/draft number: 01-003
| Modification ID:          
| Reason For Modification:  Remove tu_abort (this is a stmt style macro).
|                           Add check for blank DSETIN.
|
|*******************************************************************************
|
| Modified By:              Trevor Welby
| Date of Modification:     15-Mar-05
| New version/draft number: 01-004
| Modification ID:          TQW9753.01-004
| Reason For Modification:  The normal processing section is now executed
|                           conditionally (G_ABORT EQ 0) on there not being
|                           any errors in the parameter validation section
|                           
|************************** *****************************************************
| Modified by:              Yongwei Wang
| Date of modification:     02Apr2008
| New version number:       2/1
| Modification ID:          YW001
| Reason for modification:  Based on change request HRT0193
|                           1.Echo macro name and version and local/global macro                                            
|                             variables to the log when g_debug > 0    
|                           2.Replaced %inc tr_putlocal.sas with %put statements
|*******************************************************************************
| Modified By:              
| Date of Modification:     
| New version/draft number: 
| Modification ID:          
| Reason For Modification:  
|                           
********************************************************************************/

%macro tu_byid(dsetin=               /* Input dataset                */
              ,invars=               /* List of input variables      */
              ,outvar=__MSG          /* Output string                */
              ,outvarlength=256      /* Output variable length       */
              );

  %let invars = %upcase(&invars);

  /*
  / Echo values of parameters and global macro variables to the log
  /------------------------------------------------------------------------------*/
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
     
     %tu_putglobals();
     
  %end;

  /*
  / Perform parameter validation
  /------------------------------------------------------------------------------*/

  /*
  / Verify that the dataset DSETIN exists
  /------------------------------------------------------------------------------*/
  %if %length(&dsetin) eq 0 or not %sysfunc(exist(&dsetin)) %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: Macro Parameter DSETIN (dsetin=&dsetin) dataset does not exist;
    %let g_abort=1;
  %end;

  /*
  / Verify INVARS exist on the DSETIN dataset
  /------------------------------------------------------------------------------*/
  %local nonexistvars;
  %let nonexistvars=%tu_chkvarsexist(&dsetin,&invars);
  %if %length(&nonexistvars) %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: Macro Parameter INVARS (invars=&invars) one or more variables do not exist in &dsetin;
    %put RTE%str(RROR): &sysmacroname.: The non-existant variable(s) are: &nonexistvars;
    %let g_abort=1;
  %end;
  
  /*
  / Verify OUTVAR is a valid variable name
  /------------------------------------------------------------------------------*/
  %if %nrbquote(%tu_chknames(&outvar,variable)) ne %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: Macro Parameter OUTVAR (outvar=&outvar) is not a valid variable name;
    %let g_abort=1;
  %end;

  /*
  / verify OUTVARLENGTH parameter is not missing
  /------------------------------------------------------------------------------*/
  %if %bquote(&outvarlength) eq %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: Macro parameter OUTVARLENGTH (outvarlength=&outvarlength) is missing;
    %let g_abort=1;
  %end;
  %else %if %datatyp(&outvarlength) ne NUMERIC %then
  %do;  /* Verify that OUTVARLENGTH is a valid numeric value */
    %put RTE%str(RROR): &sysmacroname.: Macro Parameter OUTVARLENGTH (outvarlength=&outvarlength) is not a valid numeric value;
    %let g_abort=1;
  %end; /* Verify that OUTVARLENGTH is a valid numeric value */

  %if &G_ABORT eq 0 %then
  %do;  /* G_ABORT EQ 0 [TQW9753.01-004] */

    /*
    / Perform Normal Processing
    /------------------------------------------------------------------------------*/
    
    %local i              /* Do loop counter  */ 
           __msg          /* Message string   */
           fmt            /* Variable format  */
           NumberOfWords  /* Number of words  */
           RedundantVariableNotUsed /* Artifact of HARP RT Macro design */
           ;

    /*
    / Number of words in INVARS parameter
    /------------------------------------------------------------------------------*/
    %let NumberOfWords=%tu_words(&invars);

    %do i=1 %to &NumberOfWords;
      %local var&i;
    %end;

    %tu_maclist(cntname = RedundantVariableNotUsed
               ,delim   = %str( )
               ,prefix  = var
               ,scope   = local
               ,string  = &invars
               );

    %let __msg=;

    %do i = 1 %to &NumberOfWords;

      /*
      / Assign a format to the value based on the variables datatype
      /------------------------------------------------------------------------------*/
      %if %tu_chkvartype(&dsetin,&&var&i) eq C %then
      %do; /* Assign character format */
        %let fmt = $%sysfunc(left(%tu_varattr(&dsetin,&&var&i,varlen).));
      %end; /* Assign character format */
      %else %if %tu_chkvartype(&dsetin,&&var&i) eq N %then
      %do; /* Assign numeric format */
        %let fmt = BEST.;
      %end; /* Assign numeric format */

      /*
      / Build the output message string and assign to the OUTVAR parameter
      /------------------------------------------------------------------------------*/
      %if &i eq 1 %then %do;
        %let __msg = trim("&&var&i="!! left(put(&&var&i.,&fmt.)));
      %end;
      %else %do;
        %let __msg = &__msg !!', '!! trim("&&var&i="!! left(put(&&var&i.,&fmt.)));
      %end;

    %end;

    length &outvar $&outvarlength.;
    &outvar = &__msg;

  %end;  /* G_ABORT EQ 0 [TQW9753.01-004] */

%mend tu_byid;
