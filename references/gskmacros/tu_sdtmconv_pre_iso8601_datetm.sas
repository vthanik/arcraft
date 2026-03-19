/*******************************************************************************
|
| Macro Name:      tu_sdtmconv_pre_iso8601_datetm
|
| Macro Version:   4 Build 1
|
| SAS Version:     8.2
|
| Created By:      Richard Marshall (Accurate Systems Ltd)
|
| Date:            19-Mar-2007
|
| Macro Purpose:   Derive ISO8601 formatted variables from datetimes, dates,
|                  times and/or partial dates
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME              DESCRIPTION                             REQ/OPT  DEFAULT
| ----------------  --------------------------------------  -------  ----------
| DSETIN            Specifies the dataset for which         REQ      (Blank)
|                   DATETIME variables are to be added. 
|                   Valid values: valid dataset name
| DSETOUT           Specifies the name of the ouput         REQ      (Blank)
|                   dataset to be created.
|                   Valid values: valid dataset name
| DTCVARNAME        Specifies the name of the variable      REQ      (Blank)
|                   that will contain the ISO8601 value.
|                   Valid values: valid variable name
| DMVARNAME         Specifies the name of a datetime        OPT      (Blank)
|                   variable to be converted.
|                   Valid values: name of a datetime 
|                                 variable in DSETIN
| DTVARNAME         Specifies the name of a date            OPT      (Blank)
|                   variable to be converted.
|                   Valid values: name of a date variable 
|                                 in DSETIN
| TMVARNAME         Specifies the name of a time            OPT      (Blank)
|                   variable to be converted.
|                   Valid values: name of a time variable
|                                 in DSETIN
| PDVARNAME         Specifies the name of a partial         OPT      (Blank)
|                   date variable to be converted.
|                   Valid values: name of a partial date 
|                                 variable in DSETIN
| ----------------  --------------------------------------  -------  ----------
|
| The macro references the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETIN            Req      Parameter specified dataset
| -----------------  -------  -------------------------------------------------
|
| Output:
|
| The macro outputs the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETOUT           Req      Parameter specified dataset
| -----------------  -------  -------------------------------------------------
|
| Global macro variables created: NONE
|
|
| Macros called:
|(@) tu_abort
|(@) tu_chkvarsexist
|(@) tu_chknames
|(@) tu_varattr
|(@) tu_sdtmconv_pre_iso8601pd
|
| Example:
|    %tu_sdtmconv_pre_iso8601_datetm(
|         dsetin  = _ae1,
|         dsetout = _ae2,
|         dtcvarname = aestdtc,
|         dmvarname = aestdm
|         );
|
|******************************************************************************
| Change Log
|
| Modified By:              Richard Marshall
| Date of Modification:     22-Nov-2007
| New version/draft number: 1.01
| Modification ID:          RM01
| Reason For Modification:  Added code to create the ISO8601 variable if it
|                           doesn't exist in the input dataset.  If the variable 
|                           doesn't exist it will be created automatically with 
|                           a length that may be too small, or as a numeric
|                           variable (it needs to be character).
|
| Modified By:              Richard Marshall
| Date of Modification:     06-Jan-2010
| New version/draft number: 1.02
| Modification ID:          RM02
| Reason For Modification:  a. Change precedence of date/time variable
|                              processing so that any partial date is used
|                              first, if available.  Previously, datetime and
|                              date variables were used in preference, but it
|                              was found that these variables may be populated
|                              with imputed values.
|
|                           b. Allowed times to be appended to partial dates.
|                              When appending a time value to a partial date,
|                              added code to insert dashes for the missing date
|                              components.
|
|                           c. Replaced PUT function with PUTN because IS8601xx
|                              formats do not work reliably with PUT function.
|
| Modified By:		        Deepak Sriramulu
| Date of Modification:	    01-Feb-2011    
| New version/draft number: 1.03
| Modification ID:	        DSS001
| Reason For Modification:  Notify user when only TIME part is present, SDTM must always have date and time
|
| Modified By:		        Bruce Chambers
| Date of Modification:	    09-aug-2011    
| New version/draft number: 1.04
| Modification ID:	        BJC001
| Reason For Modification:  Upgrade from RTNOTE to RTWARNING where ISO date already exists
|
*******************************************************************************/
%macro tu_sdtmconv_pre_iso8601_datetm (
     dsetin      = ,      /* Input dataset  */
     dsetout     = ,      /* Output dataset */
     dtcvarname  = ,      /* IS08601 variable name */
     dmvarname   = ,      /* Datetime variable name */
     dtvarname   = ,      /* Date variable name */
     tmvarname   = ,      /* Time variable name */
     pdvarname   =        /* Partial date variable name */
        );

 /*
 / PARAMETER VALIDATION
 /----------------------------------------------------------------------------*/
 %let dsetin  = %nrbquote(&dsetin);
 %let dsetout = %nrbquote(&dsetout);
 %if &dsetin eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter DSETIN is required.;
    %let g_abort=1;
 %end;  /* end-if  Required DSETIN parameter not specified.  */
 %if &dsetout eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter DSETOUT is required.;
    %let g_abort=1;
 %end;  /* end-if  Required DSETOUT parameter not specified.  */
 %if &dtcvarname eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter DTCVARNAME is required.;
    %let g_abort=1;
 %end;  /* end-if  Required DTCVARNAME parameter not specified.  */
 %if (&dmvarname eq ) and (&dtvarname eq ) and (&tmvarname eq ) and 
     (&pdvarname eq ) %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: At least one of the DTCVARNAME/DTVARNAME/TMVARNAME/PDVARNAME parameters must be specified.;
    %let g_abort=1;
 %end;  /* end-if  No input variable name specified.  */
 /*
 / Check that required dataset exists.
 /----------------------------------------------------------------------------*/
 %if %sysfunc(exist(&dsetin)) eq 0 %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The dataset &dsetin does not exist.;
    %let g_abort=1;
 %end;  /* end-if  Specified DSETIN parameter does not exist.  */

 /*
 / Check that DSETOUT is a valid dataset name.
 /----------------------------------------------------------------------------*/

 %if %length(%tu_chknames(&dsetout, DATA)) ne 0 %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: DSETOUT (=&dsetout) is not a valid dataaset name.;
    %let g_abort=1;
 %end; 

 /*
 / Check that input variables exist.
 /----------------------------------------------------------------------------*/
 %local misvars;
 %let misvars = %tu_chkvarsexist(&dsetin,&dmvarname &dtvarname &tmvarname &pdvarname);
 %if &misvars ne %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: Specified input varable(s) (&misvars) not in input dataset (&dsetin).;
    %let g_abort=1;
 %end;  /* end-if  Specified input variables do not exist.  */
 /*
 / If DMVARNAME specified and exists, check it is the correct datatype.
 /----------------------------------------------------------------------------*/
 %local dmvfmt dmvexist;
 %let dmvexist = N;
 %if (&dmvarname ne ) and (%index(&misvars,%upcase(&dmvarname)) eq 0) %then
 %do;
    %let dmvfmt = %tu_varattr(&dsetin,&dmvarname,varfmt);
    %let dmvexist = Y;
    %if %sysfunc(compress(&dmvfmt,0123456789)) ne DATETIME. %then
    %do; 
       %put %str(RTE)RROR: &sysmacroname: The specified datetime input variable (&dmvarname) is not a datetime variable.;
       %let g_abort=1;
    %end;  /* end-if  DMVARNAME not a datetime variable.  */
 %end;  /* end-if  DMVARNAME parameter has been specified and the variable exists.  */
 /*
 / If DTVARNAME specified and exists, check it is the correct datatype.
 /----------------------------------------------------------------------------*/
 %local dtvfmt dtvexist;
 %let dtvexist = N;
 %if (&dtvarname ne ) and (%index(&misvars,%upcase(&dtvarname)) eq 0) %then
 %do;
    %let dtvfmt = %tu_varattr(&dsetin,&dtvarname,varfmt);
    %let dtvexist = Y;
    %if %sysfunc(compress(&dtvfmt,0123456789)) ne DATE. %then
    %do; 
       %put %str(RTE)RROR: &sysmacroname: The specified date input variable (&dtvarname) is not a date variable.;
       %let g_abort=1;
    %end;  /* end-if  DTVARNAME not a date variable.  */
 %end;  /* end-if  DTVARNAME parameter has been specified and the variable exists.  */
 /*
 / If TMVARNAME specified and exists, check it is the correct datatype.
 /----------------------------------------------------------------------------*/
 %local tmvfmt tmvflen tmvexist;
 %let tmvflen = 0;
 %let tmvexist = N;
 %if (&tmvarname ne ) and (%index(&misvars,%upcase(&tmvarname)) eq 0) %then
 %do;
    %let tmvfmt = %tu_varattr(&dsetin,&tmvarname,varfmt);
    %let tmvexist = Y;
    %if %sysfunc(compress(&tmvfmt,0123456789)) eq TIME. %then
       %let tmvflen = %sysfunc(compress(&tmvfmt,TIME.));
    %else 
    %do; 
       %put %str(RTE)RROR: &sysmacroname: The specified time input variable (&tmvarname) is not a time variable.;
       %let g_abort=1;
    %end;  /* end-else  TMVARNAME is a time variable.  */
 %end;  /* end-if  TMVARNAME parameter has been specified and the variable exists.  */
 /*
 / If PDVARNAME specified and exists, check it is the correct datatype.
 /----------------------------------------------------------------------------*/
 %local pdvexist;
 %let pdvexist = N;
 %if (&pdvarname ne ) and (%index(&misvars,%upcase(&pdvarname)) eq 0) %then
 %do;
    %let pdvexist = Y;
    %if %tu_varattr(&dsetin,&pdvarname,vartype) ne C %then
    %do; 
       %put %str(RTE)RROR: &sysmacroname: The specified partial date input variable (&pdvarname) is not a character variable.;
       %let g_abort=1;
    %end;  /* end-if  PDVARNAME is not a character variable.  */
 %end;  /* end-if  PDVARNAME parameter has been specified and the variable exists.  */
 /*
 / If the ISO8601 variable already exists in the input dataset,
 / write a warning to the log and check that it has correct attributes.
  BJC001: upgrade this from a NOTE to a WARNING
 /----------------------------------------------------------------------------*/
 %local dtcvexist minflen;  /* RM01 */
 %let dtcvexist = N;        /* RM01 */
 %let minflen = 0;
 %if %tu_chkvarsexist(&dsetin,&dtcvarname) eq %then 
 %do;
    %let dtcvexist = Y;     /* RM01 */
    %put %str(RTW)ARNING: &sysmacroname: The ISO8601 variable (&dtcvarname) already exists in the input dataset (&dsetin).;
    %if %tu_varattr(&dsetin,&dtcvarname,vartype) ne C %then
    %do;
       %put %str(RTE)RROR: &sysmacroname: The specified ISO8601 variable (&dtcvarname) is not a character variable.;
       %let g_abort=1;
    %end;  /* end-if  Partial date variable not character.  */
    %else
    %do;
       %if &dmvexist eq Y %then %let minflen = 19;
       %else 
       %do;
          %if (&dtvexist eq Y) or (&pdvexist eq Y) %then %let minflen = 10;
          %if &tmvexist eq Y %then %let minflen = %eval(&minflen + &tmvflen + 1);
       %end;  /* end-else  Datetime variable exists.  */
       %if %tu_varattr(&dsetin,&dtcvarname,varlen) lt &minflen %then
       %do;
          %put %str(RTE)RROR: &sysmacroname: The specified ISO8601 variable (&dtcvarname) is too small.;
          %let g_abort=1;
       %end;  /* end-if  Length of ISO8601 variable is too small.  */
    %end;  /* end-else  Partial variable not character.  */
 %end;  /* end-if  Specified ISO8601 variable already exists.  */
 /*
 / If any errors have been identified, abort.
 /----------------------------------------------------------------------------*/
 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;
 /*
 / If the input dataset name is the same as the output dataset name,
 / write a note to the log.
 /----------------------------------------------------------------------------*/
 %if &dsetin=&dsetout %then
 %do;
    %put %str(RTN)OTE: &sysmacroname: The input dataset name (&dsetin) is the same as the output dataset name (&dsetout).;
 %end;  /* end-if  Specified values for DSETIN and DSETOUT parameters are the same.  */
 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/
 %local prefix;
 %let prefix = _iso8601_datetm;   /* Root name for temporary work datasets */
 /*
 / Convert dates/times to ISO8601.     
 /----------------------------------------------------------------------------*/
 data &dsetout(drop =&tmvarname &dmvarname &dtvarname &pdvarname);
      set &dsetin;
 /* RM01: conditionally create ISO8601 variable */
 %if &dtcvexist eq N %then
 %do;
      length &dtcvarname $19;
 %end;  /* end-if  ISO8601 variable exists.  */
 /* RM01: end */

 /* RM02(a): use partial date first if it's available */
 %if &pdvexist eq Y %then
 %do;
      if &pdvarname ne '' then 
      do;
        &dtcvarname = left(resolve('%tu_sdtmconv_pre_iso8601pd('||&pdvarname||')'));
        /* Clear invalid partial date return values */
        if &dtcvarname = '-1' then &dtcvarname = '';
        goto donedate; /* RM02(b): allow times to be appended */
      end; 
 %end;  /* end-if  Partial date variable exists.  */
 /* RM02(a): end */
 
 %if &dmvexist eq Y %then
 %do;
      if &dmvarname ne . then 
      do;
        &dtcvarname = putn(&dmvarname,'is8601dt.'); /* RM02(c) */
        goto done;
      end;
 %end;  /* end-if  Datetime variable exists.  */

 %if &dtvexist eq Y %then
 %do;
      if &dtvarname ne . then 
      do;
        &dtcvarname = left(putn(&dtvarname,'is8601da.')); /* RM02(c) */
        /* RM02(a): removed goto - no need to skip partial date processing */
      end;

/* DSS001: Create a flag if only date is present  */
       %if &dtcvarname eq  and &tmvarname ne %then %do;
         %let time_prob=Y;
       %end; 

 %end;  /* end-if  Date variable exists.  */

/* DSS001: Create a flag if only time is present */
 %if &dtvexist eq N and &tmvexist eq Y %then %do;
       %let time_prob=Y;
 %end;  /* End of DSS001 update */

 
 /* RM02(a): Moved partial date processing up to take precedence */

 %if &pdvexist eq Y %then donedate:; /* RM02(b): donedate label now referenced for partial date */
 %if &tmvexist eq Y %then
 %do;
      if &tmvarname ne . then
      /* RM02(b): if there's a partial date, add dashes for missing month and/or day */
      do;
        %if &pdvexist eq Y %then
        %do;
          if &pdvarname ne '' and length(&dtcvarname) in (4,7) then
            &dtcvarname = left(trim(&dtcvarname))||repeat('--',(7-length(&dtcvarname))/3);
        %end;
      /* RM02(b): end */
        &dtcvarname = left(trimn(&dtcvarname))||'T'||left(substr(putn(&tmvarname,'is8601tm.'),1,&tmvflen)); /* RM02(c) */
      end;
 %end;  /* end-if  Time variable exists.  */
 %if &dmvexist eq Y %then done:; /* RM02(b): done label now not referenced for partial date */
 
 run;

 /* DSS001: Notify user when only TIME part is present, SDTM must always have date and time */
%if %symexist(time_prob) %then %do;
   %put %str(RTW)ARNING: At least one row with time and no date information for &dtcvarname in &dsetin;
%end;  /* End of DSS001 update */

%mend tu_sdtmconv_pre_iso8601_datetm;
