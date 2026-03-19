/*******************************************************************************
|
| Macro Name: tu_chkvartype
|
| Macro Version:  2
|
| SAS Version: 8
|
| Created By: Todd Palmer
|
| Date: 30May2003
|
| Macro Purpose: A macro to provide the data type of a variable in a dataset
|
| Macro Design: Function Style.
|
| Input Parameters:
|
| NAME              DESCRIPTION                         DEFAULT
|
| DSETIN            Dataset to be counted               No default
| VARIN             The name of the variable            No default
|
|
| Output: a character, N or C, representing the data type Numeric or Character
|
|
| Global macro variables created: NONE
|
|
| Macros called:
| (@) TU_VARATTR
| (@) TU_PUTGLOBALS
|
| Example:
|    %if %tu_chkvartype = C %then %do;
|       Processing for each record in myDataset
|    %end;
|
|
|*******************************************************************************
| Change Log
|
| Modified by:              Yongwei Wang
| Date of modification:     02Apr2008
| New version number:       2/1
| Modification ID:          YW001
| Reason for modification:  Based on change request HRT0193
|                           1.Echo macro name and version and local/global macro                                            
|                             variables to the log when g_debug > 0    
|
| Modified By:
| Date of Modification:
| New version number:
| Modification ID:
| Reason For Modification:
|
********************************************************************************/

%macro tu_chkvartype(
          dsetin     /* dataset on which var exists  */
        , varin      /* name of var to check data type for   */
        );

    /*---------------------------------------------------------------------------
    / Write details of macro start to log
    / ---------------------------------------------------------------------------
    */
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


   %tu_varAttr(&dsetin, &varin, vartype)

%mend;
