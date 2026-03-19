/******************************************************************************* 
|
| Program Name: tu_addatetime
|
| Program Version: 2
|
| HARP Compound/Study/Reporting Effort: 
|
| Program Purpose: Convert character date/datetime fields to numeric
|
| SAS Version: 
|
| Created By:      Lee J Seymour  (ljs21463)
| Date:            24-Nov-2010
|
|******************************************************************************* 
|
| Output: 
|
|
|
| Nested Macros: 
|
| (@) tu_words
| (@) tu_chkvarsexist
| (@) tu_abort
| (@) tu_putglobals
| (@) tr_putlocals
| (@) tu_tidyup
|
|******************************************************************************* 
| Change Log 
|
| Modified By:  Ashwin Venkat (va855193)
| Date of Modification:20May2012
|
| Modification ID: VA001
| Reason For Modification: 
|
| Modified By:              Anthony J Cooper
| Date of Modification:     16-APR-2015
| New version/draft number: 2/1
| Modification ID:          AJC001
| Reason For Modification:  1) Update macro to cater for additonal date variable
|                           name types, e.g. DTHDTC, BRTHDTC, RFXSTDTC as well
|                           as those of the format xxDTC, xxSTDTC, xxENDTC.
|                           2) Produce %str(RTW)ARNING messages for any date
|                           variable names that are not in the expected format.
|                           3) Ensure macro variables are localised where required.
|
| Modified By:              Anthony J Cooper
| Date of Modification:     29-APR-2015
| New version/draft number: 2/2
| Modification ID:          AJC002
| Reason For Modification:  Add call to tu_abort after checking whether required
|                           parameters have been specified.
|
********************************************************************************/ 
%macro tu_addatetime(dsetin=,
                  dsetout=,
                  datevars=
                  );

/*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion;
 %let MacroVersion = 2 build 2;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals() 

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


 %if &datevars eq %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The parameter DATEVARS is required.;
    %let g_abort=1;
 %end;  /* end-if  Required DATEVARS parameter not specified.  */

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end; /* AJC002 */

 /*
 / Check that required dataset exists.
 /----------------------------------------------------------------------------*/

 %if %sysfunc(exist(%qscan(&dsetin, 1, %str(%()))) eq 0 %then
 %do;
    %put %str(RTE)RROR: &sysmacroname: The dataset DSETIN(=&dsetin) does not exist.;
    %let g_abort=1;
 %end;  /* end-if  Specified DSETIN parameter does not exist.  */


/*
/ Check that variables specified in DATEVARS exist in DSETIN
/-------------------------------------------------------------------------------*/

 %if %length(%tu_chkvarsexist(&dsetin, &datevars)) gt 0 %THEN 
  %DO;
     %PUT RTE%str(RROR): &sysmacroname: Variable(s) %tu_chkvarsexist(&dsetin,&datevars)) does not exist in DSETIN(=&dsetin);       
     %LET g_abort=1;            
  %END;


 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;

 /*
 / If the input dataset name is the same as the output dataset name,
 / write a note to the log.
 /----------------------------------------------------------------------------*/

 %if %qscan(&dsetin, 1, %str(%()) eq %qscan(&dsetout, 1, %str(%()) %then
 %do;
    %put %str(RTN)OTE: &sysmacroname: The input dataset name (&dsetin) is the same as the output dataset name (&dsetout).;
 %end;  /* end-if  Specified values for DSETIN and DSETOUT parameters are the same.  */


 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/



/* xxSTDTC creates xxSDT xxSTM xxSDTM */
/* xxENDTC creates xxEDT xxETM xxEDTM */
/* xxDTC   creates xxDT  xxTM  xxDTM  */

 %local datevarcnt /* Number of date variables specified       */
        dvn        /* Count value for number of date variables */
        datevar    /* Current date variable being processed    */
        varstem    /* Prefix of date variable name             */
        mvl        /* Length of date variable name             */
        prefix     /* Root name for temporary work datasets    */
        ;

 %let prefix=_dates;
 %let datevarcnt=%tu_words(&datevars);

 /*
 / AJC001: Reworked the code to handle additional date variable name types
 / (e.g. xxxDTC, xxxSTDTC, xxxENDTC). Any unexpected date variable names are
 / not converted and reported to the user.
 /----------------------------------------------------------------------------*/

 data &dsetout;
    set &dsetin;
    %do dvn=1 %to &datevarcnt;

       %let datevar=%scan(&datevars,&dvn);
       %let mvl=%length(&datevar);
       %let varstem=;

       %if &mvl ge 5 %then
       %do;
          %if %upcase(%substr(%sysfunc(reverse(&datevar)),1,5))=CTDTS %then
             %let varstem=%substr(&datevar, 1, &mvl-3);
          %else %if %upcase(%substr(%sysfunc(reverse(&datevar)),1,5))=CTDNE %then
             %let varstem=%substr(&datevar, 1, &mvl-3);
          %else %if %upcase(%substr(%sysfunc(reverse(&datevar)),1,3))=CTD %then
             %let varstem=%substr(&datevar, 1, &mvl-3);
       %end;

       %if &varstem eq %str() %then
       %do;
          %put %str(RTW)ARNING: &sysmacroname: Character date variable name %upcase(&datevar) is not in the expected format (at least 5 characters and suffixed with DTC, STDTC or ENDTC). It will not be converted.;
       %end;
       %else
       %do;
          if not missing(&datevar) and length(&datevar) ge 10 then do;
             if index(&datevar,'T') gt 0 then do; 
                if length(&datevar) gt 16 then do;
                   &varstem.dtm = input(&datevar,is8601dt.);
                end;
                else do;
                   &varstem.dtm = input(compress(&datevar)||':00',is8601dt.);
                end;
                &varstem.dt = datepart(&varstem.dtm);
                &varstem.tm = timepart(&varstem.dtm);
             end;
             else &varstem.dt = input(&datevar,is8601da.);
          end;
          format &varstem.DT date9. &varstem.TM time8. &varstem.DTM datetime20.;
       %end;

    %end; /* end-if  Loop over each variable specified in DATEVARS */

 run;

 /*
 / Delete temporary datasets used in this macro.      
 /----------------------------------------------------------------------------*/

 %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend;
