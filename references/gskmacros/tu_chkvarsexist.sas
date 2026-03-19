/*******************************************************************************
|
| Macro Name:       tu_chkvarsexist
|
| Macro Version:    2.0
|
| SAS Version:      8
|
| Created By:       Todd Palmer
|
| Date:             30May2003
|
| Macro Purpose:    To check whether one or more variable names exist in a named dataset
|
| Macro Design:     Function Style.
|
| Input Parameters:
|
| NAME              DESCRIPTION                                                 DEFAULT
| DSETIN            Dataset to be checked                                       No default
| VARSIN            Variable list                                               No default
| RETURNEXISTVARS   Specify if existing variables should be returned.           No default
|                   Valid Values:
|                   (Blank) - return non-existing variables
|                   Y       - return existing variables
|                   N       - return non-existing variables 
|
| Output: If all variables exist in the dataset then this function macro will return an empty string.
|         Else a list of the names of 1 or more variables not existing.
|         OR
|         -1 if a processing step results in the macro being unable to fulfill its purpose.
|
|
| Global macro variables created: none
|
|
| Macros called:
| (@) tu_putglobals
| (@) tu_chknames
|
| Example:
|    %if %tu_chkvarsexist(myDset, myVar1 myVar2) ne %then %do;
|       Processing relating to handling of missing variables;
|    %end;
|
|
|*******************************************************************************
| Change Log
|
| Modified By: Todd Palmer
| Date of Modification: 27 Jun 2003
| New version number: 1/2
| Modification ID: DN01
| Reason For Modification: SCR comments: Amended header and uncommented tu_chknames call
|
| Modified by:              Yongwei Wang
| Date of modification:     02Apr2008
| New version number:       2/1
| Modification ID:          YW001
| Reason for modification:  Based on change request HRT0193
|                           1.Echo macro name and version and local/global macro                                            
|                             variables to the log when g_debug > 0    
|                           2.Output value of thisVarin to the log when g_debug > 0                                         
|                           3.Remove RTNOTE which states that variable is not found in                                      
|                             the input dataset calling macro shall be responsible for                                    
|                             outputting messages when appropriate.                                                         
|                           4.Output Exiting macro message to the log when g_debug > 0                                      
|                           5.Add functionality to return list of variables that exist in the                               
|                             dataset via new parameter. Default should be to return list of                                
|                             variables that do not exist for backwards compatibility. 
|
|********************************************************************************/

%macro tu_chkvarsexist(
      dsetin          /* Dataset containing variables to be checked for existence       */
    , varsin          /* Variables to be checked for existence                          */
    , returnexistvars /* Y: return existing variables, N: return non-existing variables */
    );

    /*---------------------------------------------------------------------------
    / Write details of macro start to log
    / ---------------------------------------------------------------------------
    */
    %local MacroVersion;  
    %let MacroVersion = 2.0;
    
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

    /*---------------------------------------------------------------------------
    /  Set up local macro variables
    / ---------------------------------------------------------------------------
    */
    %local
        i             /* counter */
        dsid          /* dataset id result of open function */
        thisVarin     /* for holding 1 variable at a time in sequence */
        thisDsetIn    /* dataset in with dataset options stripped off */
        dsOptStart    /* used for getting position in string of start of dset options */
        varsNotFound  /* for accumulating names of variables not found */
        varsFound     /* for accumulating names of variables found */
        dsRc          /* return code from dataset functions  */
        rc            /* return code set by processes  */
        ;


    /*---------------------------------------------------------------------------
    / Parameter Validation
    / ---------------------------------------------------------------------------
    */
    
    %if %nrbquote(&returnexistvars) eq %then %let returnexistvars=N;

     /*** Make sure dsetin is not empty ***/
    %if "&dsetin" = "" %then 
    %do;
        /* dsetin is empty - do log messages and set return to -1 */
        %put RTE%str(RROR:) &sysmacroname.: The first parameter is empty: DSETIN=%bquote(&dsetin).;
        %let g_abort = 1;
        %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
        %let rc = -1;
        %put RTN%str(OTE:) &sysmacroname.: This macro will return the value &rc;
    %end;

    /*** Make sure varsin is not empty and are valid variable names ***/
    %if "&varsin" = "" %then 
    %do;
        /* varsin is empty - do log messages and set return to -1 */
        %put RTE%str(RROR:) &sysmacroname.: The 2nd parameter is empty: VARSIN=%bquote(&varsin).;
        %let g_abort = 1;
        %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
        %let rc = -1;
        %put RTN%str(OTE:) &sysmacroname.: This macro will return the value &rc;
    %end;
    %else %do;
        /* calling tu_chknames */
        %if %tu_chknames(&varsin, VARIABLE ) ne %then %do;
            %put RTE%str(RROR:) &sysmacroname.: Variable list improperly specified: VARSIN=%bquote(&varsin).;
            %let g_abort = 1;
            %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
            %let rc = -1;
            %put RTN%str(OTE:) &sysmacroname.: This macro will return the value &rc;
        %end;
    %end;
    
    %if ( %nrbquote(&returnexistvars) ne Y ) and ( %nrbquote(&returnexistvars) ne N ) %then
    %do;
        %put RTE%str(RROR:) &sysmacroname.: Value of RETURNEXISTVARS(=&returnexistvars) is invalid. Valid value should be Y, N or blank;
        %let rc = -1;
    %end;
    
    /*** exit if error so far ***/
    %if &rc = -1 %then %goto EXIT;

    /* all parameters ok so keep going */

    /*** Check dsetin dset exists ***/
    /* note this fulfills parameter checking of the dsetin parameter,
    /  no determination of valid chars are required
    */

    /*** Check existence of named dset ***/
    /* remove any dataset options from the dsetin */
    %let dsOptStart = %index(&dsetin, %str(%() ) ;
    %if &dsOptStart > 0 %then %do;
        %let thisDsetin = %substr(&dsetin, 1, &dsOptStart - 1 );
    %end;
    %else %do;
        %let thisDsetin = &dsetin;
    %end;

    /* check existence */
    %let dsRC = %sysfunc(exist(&thisDsetin));

    /* If dataset name does not exist - do log messages and set return to -1 */
    %if &dsRC = 0 %then %do;
        %put RTE%str(RROR:) &sysmacroname.: Dataset name determined as &thisDsetin and does not exist:;
        %let g_abort = 1;
        %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
        %let rc = -1;
        %put RTN%str(OTE:) &sysmacroname.: This macro will return the value &rc;
    %end;

    %if &rc = -1 %then %goto EXIT;

    /* all parameters ok so keep going */

    /*-----------------------------------------------------------------------
    / Open the Dataset
    / -----------------------------------------------------------------------
    */
    %let dsid=%sysfunc(open(&thisDsetin,is));
    %if &dsid EQ 0 %then %do;
        /* Unable to open dataset - do log messages and set return to -1 */
        %put RTE%str(RROR:) &sysmacroname.: Unable to open dataset &thisDsetin.;
        %let g_abort = 1;
        %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
        %let rc = -1;
        %put RTN%str(OTE:) &sysmacroname.: This macro will return the value &rc;
        /* no further processing will be done */
        %goto EXIT;
    %end;
    %else %do;
        /*-------------------------------------------------------------------
        / If open is successful then execute the varnum function to check var
        / existence
        / -------------------------------------------------------------------
        */

        %let varsNotFound = ;
        %let varsFound = ;

        /* loop through each of the varsin and try and find each var in the dset */
        %do i = 1 %to %tu_words(&varsin);
            %let thisVarin = %upcase(%qsysfunc(compbl(%qscan(&varsin, &i))));
            
            %if &g_debug GT 0 %then
            %do;
                %put thisVarin = &thisVarin;
            %end;

            %if %sysfunc(varnum(&dsid, &thisVarin)) <= 0 %then %do;
                %let varsNotFound = &varsNotFound &thisVarin;
            %end;            
            %else %do;
                %let varsFound = &varsFound &thisVarin;
            %end;
        %end;
    %end;

    /*-----------------------------------------------------------------------
    / Close the opened dataset
    / -----------------------------------------------------------------------
    */
    %let dsRc=%sysfunc(close(&dsid));
    /* Capture any problem in closing the dataset  */
    %if &dsRc ne 0 %then %do;
        %put RTN%str(OTE:) &sysmacroname.: Unable to close &dsetin.;
        %let g_abort = 1;
        %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
        %let rc = -1;
        %put RTN%str(OTE:) &sysmacroname.: This macro will return the value &rc;
    %end;

    /*---------------------------------------------------------------------------
    /* Return a value from the macro
    / ---------------------------------------------------------------------------
    */
  %EXIT:
    %if &rc = -1 %then %do;
        &rc
    %end;
    %else %if %upcase(&returnexistvars) eq Y %then
    %do;
        &varsFound
    %end;
    %else %do;
        &varsNotFound
    %end;
    
    %if &g_debug GT 0 %then 
    %do;
        %put Exiting macro &sysmacroname;
    %end;

%mend tu_chkvarsexist;
