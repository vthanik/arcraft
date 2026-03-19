/*******************************************************************************
|
| Macro Name: tu_nvars
|
| Macro Version:  2
|
| SAS Version: 8
|
| Created By: Todd Palmer
|
| Date: 30May2003
|
| Macro Purpose: A macro to count the number of variables in a dataset
|
| Macro Design: Function Style.
|
| Input Parameters:
|
| NAME              DESCRIPTION                         DEFAULT
|
| DSETIN            Dataset containing variables        No default
|
|
| Output: Specifies the number of variables in the data set.
|         -1 if the number of variables is not available.
|
| Global macro variables created: NONE
|
|
| Macros called:
|    (@) TU_DSETATTR
|    (@) TU_PUTGLOBALS
|
| Example:
|    %local i;
|    %do i = 1 %to %tu_nvars(&DSETIN);
|       Processing for each record in dataset
|    %end;
|
|
|*******************************************************************************
| Change Log
|
| Modified by:             Yongwei Wang
| Date of modification:    02Apr2008
| New version number:      2/1
| Modification ID:         YW001
| Reason for modification: Based on change request HRT0193
|                          1. Echo macro name and version and local/global macro                                            
|                             variables to the log when g_debug > 0    
| Modified By:
| Date of Modification:
| New version number:
| Modification ID:
| Reason For Modification:
|
********************************************************************************/

%macro tu_nvars(
    dsetin     /* dataset on which variables exists  */
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

    %tu_dsetAttr(&dsetin, nvars)

%mend;
