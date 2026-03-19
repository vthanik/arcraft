/*******************************************************************************
|
| Macro Name: tu_dsetattr
|
| Macro Version:  2
|
| SAS Version: 8
|
| Created By: Todd Palmer    
|
| Date: 30May2003
|
| Macro Purpose: A macro to provide dataset attributes
|
| Macro Design: Function Style.
|
| Input Parameters:
|
| NAME              DESCRIPTION                               DEFAULT
|
| DSETIN            Dataset for which an attribute required   No default      
| ATTRIB            The attribute required                    No default      
|
|
| Output: A numeric or character value containing the value of the dataset
|         attribute requested.
|         -1 if the attribute is not available. 
|
| Global macro variables created: NONE
|
|
| Macros called: 
| (@) TU_PUTGLOBALS
|
| Example:
|    %local thisLabel;
|    %let thisLabel = %tu_dsetAttr(myDataset, label);
|
|
|*******************************************************************************
| Change Log
|
| Modified By: Todd Palmer
| Date of Modification: 27Jun03
| New version number: 1/2
| Modification ID: DN01
| Reason For Modification: Source Code Review
|
| Modified By: Todd Palmer
| Date of Modification: 30Jun03
| New version number: 1/3
| Modification ID: DN02
| Reason For Modification: Source Code Review 2
|
| Modified by:              Yongwei Wang
| Date of modification:     02Apr2008
| New version number:       2/1
| Modification ID:          YW001
| Reason for modification:  Based on change request HRT0193
|                           1.Echo macro name and version and local/global macro                                            
|                             variables to the log when g_debug > 0    
|                           2.Write debugging messages to the log when g_debug > 0                                          
|                           3.Output Exiting macro message to the log when g_debug > 0  
********************************************************************************/


%macro tu_dsetAttr(
	  dsetin    /* name of incoming dataset   */
	, attrib    /* dataset attribute required */
	);

    %*------------------------------------------------------------------------;
    %* Write details of macro start to log ***;
    %*------------------------------------------------------------------------;
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
        
        %tu_putglobals(varsin = g_abort )
        
    %end;
    
    /*---------------------------------------------------------------------------
    /  Set up local macro variables 
    / ---------------------------------------------------------------------------
    */
    %local 
        dsOptStart    /* used for getting position in string of start of dset options */
		thisDsetin    /* name of dsetin after removal of dataset options              */
        dsid          /* holds the dataset id obtained from the open function         */ 
        dsRc          /* return code from dataset functions open and close            */
        rc            /* holds the return code set by processing steps                */
        fnrc          /* holds the result of the attrib function call                 */
        ; 


    /*---------------------------------------------------------------------------
    / Parameter Validation 
    / ---------------------------------------------------------------------------
    */
    /*** Make sure dsetin is not empty ***/
    %if "&dsetin" eq "" %then %do;
        /* dsetin is empty - do log messages and set return to -1 */
        %put RTE%str(RROR:) &sysmacroname.: The first parameter is empty: DSETIN=%bquote(&dsetin).;
        %let g_abort = 1;
        %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
        %let rc = -1;        
        %put RTN%str(OTE:) &sysmacroname.: This macro will return the value &rc;
    %end;

    /*** Make sure attrib a valid value ***/
    /* note this is more cleanly done in the execution step below */

    /*** exit if error so far ***/
    %if &rc eq -1 %then %goto EXIT;

    /* all parameters ok so keep going */ 

    /*** Check existence of named dset ***/
    /* remove any dataset options from the dsetin */
    %let dsOptStart = %index(&dsetin, %str(%() ) ;
    %if &g_debug gt 0 %then %put Created macrovar dsOptStart=&dsOptStart; 
    %if &dsOptStart gt 1 %then %do;
        %let thisDsetin = %substr(&dsetin, 1, &dsOptStart - 1 );
    %end;
    %else %do;
        %let thisDsetin = &dsetin;
    %end;
    %if &g_debug gt 0 %then %put Created macrovar thisDsetin=&thisDsetin; 

    /* check existence */
    %let dsRC = %sysfunc(exist(&thisDsetin));
    %if &g_debug gt 0 %then %put Created macrovar thisDsetin=&thisDsetin; 

    /* If dataset name does not exist - do log messages and set return to -1 */
    %if &dsRC eq 0 %then %do;
        %put RTE%str(RROR:) &sysmacroname.: Dataset name determined as &thisDsetin and does not exist:;
        %let g_abort = 1;
        %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
        %let rc = -1;        
        %put RTN%str(OTE:) &sysmacroname.: This macro will return the value &rc;
    %end;

    %if &rc eq -1 %then %goto EXIT;

    /* all parameters ok so keep going */ 

    /*------------------------------------------------------------------------
    / Open the Dataset
    / ------------------------------------------------------------------------
    */
    %let dsid=%sysfunc(open(&thisDsetIn, is));
    %if &g_debug gt 0 %then %put Created macrovar dsid=&dsid; 
    %if &dsid EQ 0 %then %do;
        %put RTE%str(RROR:) &sysmacroname.: Dataset &thisDsetIn unable to be opened.;
        %let g_abort = 1;
        %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
        %let rc = -1;        
        %put RTN%str(OTE:) &sysmacroname.: This macro will return the value &rc;
        /* no further processing will be done */
        %goto EXIT;
    %end;
    %else %do;
        /*------------------------------------------------------------------------
        / If open is successful then execute the attrn or attrc function based 
        / on the value of &attrib ;
        / ------------------------------------------------------------------------
        */

        /* Call the attrn function for numeric attributes  
        /  Else call the attrc function for character attributes 
        /  Else report invalid attrib parameter supplied 
        */
        %if %index(    "NVARS" "NOBS" "NLOBSF" "NLOBS" "ANY" "ALTERPW" "ANOBS" "ARAND" "ARWU" "CRDTE"
                    "GENMAX" "GENNEXT" "ICONST" "ISINDEX" "ISSUBSET" "LRECL" "LRID" "MODTE"
                    "NDEL" "NLOBS" "PW" "RADIX" "READPW" "TAPE" "WHSTMT" "WRITEPW"
                    , "%upcase(&attrib)") gt 0 %then %do;
            %let fnrc = %sysfunc(attrn(&dsid,&attrib));
            %if &g_debug gt 0 %then %put Created macrovar dsid=&dsid; 
        %end;
        %else %if %index("CHARSET" "ENCRYPT" "ENGINE" "LABEL" "LIB" "MEM" "MODE" "MTYPE" "SORTEDBY" 
                    "SORTLVL" "SORTSEQ" "TYPE"
                    , "%upcase(&attrib)") gt 0 %then %do;
            %let fnrc = %sysfunc(attrc(&dsid,&attrib));
            %if &g_debug gt 0 %then %put Created macrovar fnrc=&fnrc; 
        %end;
        %else %do;
            %put RTE%str(RROR:) &sysmacroname.: The Parameter ATTRIB has been supplied with the invalid value &attrib;  
            %let g_abort = 1;
            %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
            %let rc = -1;        
            %put RTN%str(OTE:) &sysmacroname.: This macro will return the value &rc;
        %end;

        /*------------------------------------------------------------------------
        / Close the opened dataset ;
        / ------------------------------------------------------------------------
        */
       %let dsRc=%sysfunc(close(&dsid));
       %if &g_debug gt 0 %then %put Created macrovar dsRc=&dsRc; 

        /* Capture and inform user of any problem in closing the dataset */
        %if &dsRc ne 0 %then %do;
            %put RTN%str(OTE:) &sysmacroname.: Unable to close &thisDsetIn.;
            %let g_abort = 1;
            %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
            %let rc = -1;        
            %put RTN%str(OTE:) &sysmacroname.: This macro will return the value &rc;
        %end;
    %end; /* of working with opened dataset */

    /*------------------------------------------------------------------------
    /  Return a value from the macro ;
    / ------------------------------------------------------------------------
    */

  %EXIT:

    %if &rc eq -1 %then 
    %do;
        &rc
    %end;
    %else %do;
        &fnrc
    %end;

    %if &g_debug gt 0 %then 
    %do;
        %put Exiting macro &sysmacroname;
    %end;
%mend tu_dsetAttr;
