/*******************************************************************************
|
| Macro Name: tu_varattr
|
| Macro Version:  2
|
| SAS Version: 8
|
| Created By: Todd Palmer    
|
| Date: 30May2003
|
| Macro Purpose: Determine and return a specific variable attribute for a named dataset
|
| Macro Design: Function Style.
|
| Input Parameters:
|
| NAME              DESCRIPTION                         DEFAULT
|
| DSETIN            Dataset containing variable         No default 
| VARIN             Variable with attribute of interest No default
| ATTRIB            Attribute of interest               No default
|
|Valid Values for attrib parameter are the var attribute functions eg:
|            VARTYPE, VARLEN,
|            VARLABEL, VARFMT and VARINFMT.
|
| Output: the value of the requested attribute for the specified variable
|         within the specified dataset. 
|         POSSIBLE 
|         OR 
|         -1 if the number of observations is not available. 
|
| Global macro variables created: NONE
|
|
| Macros called: 
|    (@) tu_chknames
|    (@) tu_putglobals
|
| Example:
|    %local myvartype;
|    %let myvartype = %tu_varattr(myDataset, myvariable, vartype);
|
|
|*******************************************************************************
| Change Log
|
| Modified By: Todd Palmer
| Date of Modification: 27Jun03
| New version number: 1/2
| Modification ID: DN01
| Reason For Modification: Source Code Review.
|
| Modified by:             Yongwei Wang
| Date of modification:    02Apr2008
| New version number:      2/1
| Modification ID:         YW001
| Reason for modification: Based on change request HRT0193
|                          1. Echo macro name and version and local/global macro                                            
|                             variables to the log when g_debug > 0    
|                          2. Write debugging messages to the log when g_debug > 0                                          
|                          3. Output Exiting macro message to the log when g_debug > 0  
********************************************************************************/

%macro tu_varAttr(
      dsetin    /* the incoming dataset  */
    , varin     /* the name of the variable on the incoming dataset */
    , attrib    /* the variable attribute required  */
    );


    /*------------------------------------------------------------------------
    / Write details of macro start to log 
    / ------------------------------------------------------------------------
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

    /*---------------------------------------------------------------------------
    /  Set up local macro variables 
    / ---------------------------------------------------------------------------
    */
    %local 
        i             /* counter */ 
	thisDsetin    /* holds the name of dsetin after removing dataset options */
        dsOptStart    /* used for getting position in string of start of dset options */
        dsid          /* dataset id result of open function */
        dsRc          /* return code from dataset functions  */
        rc            /* return code set by processes  */
        fnrc          /* return code from sysfunc(&attrib   */
        varnum        /* variable number within dataset */
        ;

    /*---------------------------------------------------------------------------
    / Parameter Validation 
    / ---------------------------------------------------------------------------
    */

     /*** Make sure dsetin parameter is not empty ***/
    %if "&dsetin" eq "" %then %do;
        /* dsetin is empty - do log messages and set return to -1 */
        %put RTE%str(RROR:) &sysmacroname.: The first parameter is empty: DSETIN=%bquote(&dsetin).;
        %let g_abort = 1;
        %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
        %let rc = -1;        
        %put RTN%str(OTE:) &sysmacroname.: This macro will return the value &rc;
    %end;

    /*** Make sure varin parameter is not empty and is valid variable names ***/
    %if "&varin" eq "" %then %do;
        /* varin is empty - do log messages and set return to -1 */
        %put RTE%str(RROR:) &sysmacroname.: The 2nd parameter is empty: varin=%bquote(&varin).;
        %let g_abort = 1;
        %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
        %let rc = -1;        
        %put RTN%str(OTE:) &sysmacroname.: This macro will return the value &rc;
    %end;
    %else %do;
        /* calling tu_chknames */
        %if %tu_chknames(&varin, VARIABLE) ne %then %do;
            %put RTE%str(RROR:) &sysmacroname.: Variable list improperly specified: varin=%bquote(&varin).;
            %let g_abort = 1;
            %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
            %let rc = -1;        
            %put RTN%str(OTE:) &sysmacroname.: This macro will return the value &rc;
        %end;
    %end;

    /*** exit if error so far ***/
    %if &rc eq -1 %then %goto EXIT;

    /* all parameters ok so keep going */ 

    /*** Check dsetin dset exists ***/
    /* note this fulfills parameter checking of the dsetin parameter, 
    /  no determination of valid chars are required
    */

    /*** Check existence of named dset ***/
    /* remove any dataset options from the dsetin */
    %let dsOptStart = %index(&dsetin, %str(%() ) ;
    %if &g_debug gt 0 %then %put Created macrovar dsOptStart=&dsOptStart;
    %if &dsOptStart gt 0 %then %do;
        %let thisDsetin = %substr(&dsetin, 1, &dsOptStart - 1 );
    %end;
    %else %do;
        %let thisDsetin = &dsetin;
    %end;
    %if &g_debug gt 0 %then %put Created macrovar thisDsetin=&thisDsetin;

    /* check existence */
    %let dsRC = %sysfunc(exist(&thisDsetin));
    %if &g_debug gt 0 %then %put Created macrovar dsRC=&dsRC;

    /* If dataset name does not exist - do log messages and set return to -1 */
    %if &dsRC = 0 %then %do;
        %put RTE%str(RROR:) &sysmacroname.: Dataset name determined as &thisDsetin and does not exist:;
        %let g_abort = 1;
        %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
        %let rc = -1;        
        %put RTN%str(OTE:) &sysmacroname.: This macro will return the value &rc;
    %end;

    %if &rc eq -1 %then %goto EXIT;

    /* all parameters ok so keep going */ 

    /*-----------------------------------------------------------------------
    / Open the Dataset 
    / -----------------------------------------------------------------------
    */

    %let dsid=%sysfunc(open(&thisDsetin,is));
    %if &g_debug gt 0 %then %put Created macrovar dsid=&dsid;
    %if &dsid EQ 0 %then %do;
        %put RTN%str(OTE:) &sysmacroname.: Dataset &thisDsetin unable to be opened;
        %let g_abort = 1;
        %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
        %let rc = -1;
        %put RTN%str(OTE:) &sysmacroname.: This macro will return the value &rc;
        /* no further processing will be done */
        %goto EXIT;
    %end;
    %else %do;
        /*------------------------------------------------------------------------
        / Open is successful now check variable exists in the dataset  
        / ------------------------------------------------------------------------
        */
        %let varnum=%sysfunc(varnum(&dsid, &varin));
        %if &g_debug gt 0 %then %put Created macrovar varnum=&varnum;
        %if &varnum lt 1 %then %do; 
            %put RTERROR: &sysmacroname.: Variable &varin not in dataset &dsetin;
            %let g_abort = 1;
            %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
            %let rc = -1;
            %put RTN%str(OTE:) &sysmacroname.: This macro will return the value &rc;
        %end;
        %else %do;
            %if %index( "VARTYPE" "VARLEN" "VARLABEL" "VARFMT" "VARINFMT" 
                    , "%upcase(&attrib)") le 0 %then %do;
                /*------------------------------------------------------------------------
                / Check the value of the attrib is valid if variable exists
                / ------------------------------------------------------------------------
                */
                %put RTE%str(RROR:) &sysmacroname.: The attrib value &attrib is not in the list of valid values; 
                %let g_abort = 1;
                %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort; 
                %let rc = -1;
                %put RTN%str(OTE:) &sysmacroname.: This macro will return the value &rc;
            %end;
            %else %do;
                /*------------------------------------------------------------------------
                / No problems so execute the attrib function
                / ------------------------------------------------------------------------
                */
                %let fnrc = %sysfunc(&attrib(&dsid, &varnum));
                %if &g_debug gt 0 %then %put Created macrovar fnrc=&fnrc;
            %end;
        %end;
    %end;

    /*------------------------------------------------------------------------
    / Close the opened dataset
    / ------------------------------------------------------------------------
    */
    %let dsRc=%sysfunc(close(&dsid));
    %if &g_debug gt 0 %then %put Created macrovar dsRc=&dsRc;

    /** Capture any problem in closing the dataset **/
    /** Else everything worked fine so return the function result **/
    %if &dsRc ne 0 %then %do;
        %put RTN%str(OTE:) &sysmacroname.: Unable to close &dsetin.;
        %let g_abort = 1;
        %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
        %let rc = -1;        
        %put RTN%str(OTE:) &sysmacroname.: This macro will return the value &rc;
    %end;

    /*------------------------------------------------------------------------
    / Return a value from the macro
    / ------------------------------------------------------------------------
    */
  %EXIT:
    %if &rc eq -1 %then %do;
        &rc
    %end;
    %else %do;
        &fnrc
    %end;

    %if &g_debug gt 0 %then %do;
        %put Exiting macro &sysmacroname;
    %end;

%mend;
