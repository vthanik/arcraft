/*******************************************************************************
|
| Macro Name: tu_sdtmconv_pre_iso8601pd
|
| Macro Version:  1
|
| SAS Version: 8.2
|
| Created By: Richard Marshall (Accurate Systems Ltd)    
|
| Date: 25May2006
|
| Macro Purpose: Convert a partial date to ISO 8601 format
|
| Macro Design: Function Style.
|
| Input Parameters:
|
| NAME              DESCRIPTION                         DEFAULT
|
| PARTIALDT         Partial date string                 No default
|
| Valid Values for partialdt parameter are any 7 or 9 character date in the format:
|         DDMONYY,   --MONYY,   -----YY,   -------,
|         DDMONYYYY, --MONYYYY, -----YYYY, ---------
|
| Output: the partial date represented in ISO 8601 format, 
|         with reduced precision appropriate to the input value. 
|         OR 
|         -1 if the input value is not valid. 
|         OR 
|         Nothing (empty string) if input partial date is missing
|
| Global macro variables created: NONE
|
|
| Macros called: 
|    None
|
| Example:
|    %local myvartype;
|    %let myvartype = %tu_sdtmconv_pre_iso8601pd(--MAY06);
|
|
|*******************************************************************************
| Change Log
|
| Modified By: 
| Date of Modification: 
| New version number:
| Modification ID: 
| Reason For Modification: 
|
********************************************************************************/

%macro tu_sdtmconv_pre_iso8601pd(
                    partialdt      /* Partial date ( DDMONYY[YY] / --MONYY[YY] / -----YY[YY] / -------[--] ) */
                    );

    /*---------------------------------------------------------------------------
    /  Set up local macro variables 
    / ---------------------------------------------------------------------------
    */

    %local
        _pdlen      /* Partial date length */
        _pdlstdsh   /* Position of last dash in partial date (-1 if no dashes) */
        _pdnumdsh   /* Number of dashes in partial date */
        _pddumdt    /* Dummy full date, using 01[JAN] for missing element[s] */
        _pddumis    /* Dummy full date in ISO 8601 format */
        rc          /* Return code */
        ;

    /*---------------------------------------------------------------------------
    / Parameter Validation 
    / ---------------------------------------------------------------------------
    */

     /*** Skip processing if partialdt parameter is empty ***/
    %if "&partialdt" eq "" %then %goto EXIT;

    /*** Make sure partialdt is either 7 or 9 characters ***/
    %let _pdlen = %length(&partialdt);
    %if (&_pdlen ne 7) and (&_pdlen ne 9)  %then 
    %do;
        /* partialdt not 7 or 9 characters - do log messages and set return to -1 */
        %put RTW%str(ARNING:) &sysmacroname.: Partial date is not 7 or 9 characters: PARTIALDT=%bquote(&partialdt).;
        %let rc = -1;        
        %put RTN%str(OTE:) &sysmacroname.: This macro will return the value &rc;
    %end;
    %else
    %do; 
         /*** Make sure partialdt has a valid format ***/
        %let _pdnumdsh = %eval(&_pdlen - %length(%sysfunc(compress(&partialdt,-))));
        %let _pdlstdsh = %eval(&_pdlen - %index(%sysfunc(reverse(&partialdt)),-) + 1);
        %if    (    (&_pdnumdsh ne 0) and (&_pdnumdsh ne 2) and (&_pdnumdsh ne 5) 
                and (&_pdnumdsh ne 7) and (&_pdnumdsh ne 9))                   /* Wrong number of dashes  */
            or ((&_pdlstdsh le &_pdlen) and (&_pdlstdsh ne &_pdnumdsh))        /* Dashes not all at start */
            %then 
        %do;
            /* partialdt has an invalid format - do log messages and set return to -1 */
            %put RTW%str(ARNING:) &sysmacroname.: Invalid partial date format: PARTIALDT=%bquote(&partialdt).;
            %let rc = -1;        
            %put RTN%str(OTE:) &sysmacroname.: This macro will return the value &rc;
        %end;
    %end; /* partialdt is 7 or 9 chars */

    /*** exit if error so far ***/
    %if &rc eq -1 %then %goto EXIT;
   
    %if &_pdnumdsh eq 0 %then 
        /* Partial date is actually a full date - convert to ISO 8601 */
        %let rc = %sysfunc(inputn(&partialdt,date.,&_pdlen),is8601da.);
    %else %if &_pdnumdsh eq &_pdlen %then
        %let rc = %str();
    %else
    %do;
        /*** Generate a dummy date, convert to ISO 8601 and use substring to reduce precision ***/
        %let _pddumdt = %substr(01JAN,1,&_pdnumdsh)%sysfunc(compress(&partialdt,-));
        /*** Convert to ISO 8601 ***/
        %let _pddumis = %sysfunc(inputn(&_pddumdt,date.,&_pdlen),is8601da.);
        /*** Use substring to reduce precision ***/
        %let rc = %substr(&_pddumis,1,%eval(9 - &_pdnumdsh));
    %end;

    /*------------------------------------------------------------------------
    / Return a value from the macro
    / ------------------------------------------------------------------------
    */

%EXIT:&rc    

    %if &g_debug gt 1 %then %do;
        %put Exiting macro &sysmacroname;
    %end;

%mend tu_sdtmconv_pre_iso8601pd;
