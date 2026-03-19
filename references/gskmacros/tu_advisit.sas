/*******************************************************************************
|
| Macro Name:      tu_advisit
|
| Macro Version:   2 build 1
|
| SAS Version:     9.1
|
| Created By:      Megha Agarwal
|
| Date:            03-April-2014
|
| Macro Purpose:   Add visit variables to a dataset.
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME              DESCRIPTION                             REQ/OPT  DEFAULT
| ----------------  --------------------------------------  -------  ----------
| DSETIN            Specifies the input dataset containing   REQ     (Blank) 
|                   visitnum and visit                 
|                   Valid values: valid dataset name                     
|
| DSETOUT           Specifies the name of the output         REQ     (Blank) 
|                   to be created.                  
|                   Valid values: valid dataset name
|
| AVISITNF          Format to derive AVISITN from VISITNUM   OPT     (Blank)
|
| AVISITF           Format to derive AVISIT from VISIT       OPT     (Blank)
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
|(@) tr_putlocals
|(@) tu_putglobals
|(@) tu_tidyup
|
| Example:
|    %tu_advisit(
|         dsetin    = _ae1,
|         dsetout   = _ae2,
|         avisitnfmt = avisitnfmt
|         avisitfmt =  avisitfmt
|         );
|
|    where avisitnfmt and avisitfmt were previously defined as formats, e.g.
|
|         proc format;
|             value avisitnfmt
|               10 = 10
|               10.01 = 999
|               20 = 20;
|	      
|	      value $avisitfmt
|		"VISIT 1" = "VISIT 1"
|		"UNSCHEDULED-10.01" = "UNSCHEDULED"
|		"VISIT 2" = "VISIT 2"
|         run;
|
|
|******************************************************************************
| Change Log
|
| Modified By:              Anthony J Cooper
| Date of Modification:     13-APR-2015
| New version/draft number: 2/1
| Modification ID:          AJC001
| Reason For Modification:  Ensure AVISITN is created as a numeric variable
|                           when derived via format.
*******************************************************************************/
%macro tu_advisit		 (
     dsetin      = ,      /* Input dataset name */
     dsetout     = ,      /* Output dataset name */
     avisitnfmt  = ,      /* Name of the format to derive AVISITN (without the .) */
     avisitfmt   = ,      /* Name of the format to derive AVISIT (without the .)  */
        );
       
 /*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/
 %local MacroVersion;
 %let MacroVersion = 2 build 1;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals() 
 /*
 / PARAMETER VALIDATION
 /----------------------------------------------------------------------------*/			
 %let dsetin  = %nrbquote(&dsetin);
 %let dsetout = %nrbquote(&dsetout);
 %if &dsetin eq %then
 %do;
    %put %str(RTE)RROR: TU_ADVISIT: The parameter DSETIN is required.;
    %let g_abort=1;
 %end;  /* end-if  required parameter, DSETIN is not specified.  */
 %if &dsetout eq %then
 %do;
    %put %str(RTE)RROR: TU_ADVISIT: The parameter DSETOUT is required.;
    %let g_abort=1;
 %end;  /* end-if required parameter DSETOUT is not specified.  */
 /*
 / Check that required dataset exists. 
 /----------------------------------------------------------------------------*/
 %if %sysfunc(exist(&dsetin)) eq 0 %then
 %do;
    %put %str(RTE)RROR: TU_ADVISIT: The dataset &dsetin does not exist.;
    %let g_abort=1;
 %end;  /* end-if for required DSETIN parameter specified, but does not exist.  */  
 /*
 / Check that any specified avisitnfmt/avisitfmt formats exist.
 /----------------------------------------------------------------------------*/
 %let avisitnfmt  = %nrbquote(&avisitnfmt);
 %let avisitfmt = %nrbquote(&avisitfmt);
 %if &avisitnfmt ne  %then
 %do;
    proc sql noprint;
      select * from dictionary.catalogs
      where upcase(objname) eq "%upcase(&avisitnfmt)" and objtype eq "FORMAT";
    quit;
    %if &sqlobs eq 0 %then
    %do;
      %put %str(RTE)RROR: TU_ADVISIT: The format &avisitnfmt does not exist.;
    %let g_abort=1;
    %end;  /* end-if  specified format AVISITNFMT does not exist.  */
 %end;     /* end-if  format AVISITNFMT was specified.     */  
 %if &avisitfmt ne  %then
 %do;
    proc sql noprint;
      select * from  dictionary.catalogs
      where upcase(objname) eq "%upcase(%sysfunc(compress(&avisitfmt,'$')))" and objtype eq "FORMATC";
    quit;
    %if &sqlobs eq 0 %then
    %do;
      %put %str(RTE)RROR: TU_ADVISIT: The format &avisitfmt does not exist.;
    %let g_abort=1;
    %end;  /* end-if  specified format AVISITFMT does not exist.  */
 %end;     /* end-if  format AVISITFMT was specified.  */
 /* 
 / Check that required variable VISITNUM exists on the input dataset.
 /----------------------------------------------------------------------------*/
 %if %tu_chkvarsexist(&dsetin, visitnum) ne  %then
 %do; 
   /* VISITNUM variable does not exist on input dataset */
   %put %str(RTE)RROR: TU_ADVISIT: The dataset DSETIN (&dsetin) does not contain the variable VISITNUM.;
   %let g_abort=1;
 %end;
 /* 
 / Check that required variable VISIT exists on the input dataset.
 /----------------------------------------------------------------------------*/
 %if %tu_chkvarsexist(&dsetin, visit) ne  %then
 %do; 
   /* VISIT variable does not exist on input dataset */
   %put %str(RTE)RROR: TU_ADVISIT: The dataset DSETIN (&dsetin) does not contain the variable VISIT.;
   %let g_abort=1;
 %end;
 %if &g_abort eq 1 %then
 %do; 
    %tu_abort;
 %end;
 /*
 / If the input dataset name is the same as the output dataset name,
 / write a note to the log.
 /----------------------------------------------------------------------------*/
 %if &dsetin eq &dsetout %then
 %do;
    %put %str(RTN)OTE: TU_ADVISIT: The input dataset name (&dsetin) is the same as the output dataset name (&dsetout).;
 %end;  /* end-if parameters values of DSETIN and DSETOUT  are the same.  */
 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/
   
 %local prefix;
 %let prefix = _advisit;   /* Root name for temporary work datasets */
 
 /* If AVISITNFMT and AVISITFMT formats are specified then get AVISITN and AVISIT  by applying these formats on 
 /  VISITNUM and VISIT variables respectively.Otherwise, assign VISITN and VISIT variables to AVISITN and AVISIT
 /  respectively and make AVISIT as "UNSCHEDULED" and AVISITN as 999 for Unscheduled visits.
 / ----------------------------------------*/
   
 %if &avisitnfmt ne  and &avisitfmt ne  %then
 %do;
    data &dsetout;
      set &dsetin;
       avisitn=input(put(visitnum, %upcase(&avisitnfmt..)), best.); * AJC001 *;
       avisit=put(visit, %upcase(&avisitfmt..));
    run;
 %end;  /* end-if  formats AVISITNFMT and AVISITFMT were specified.  */
 %else
 %do;
    data &dsetout(drop=visitnum1);
    attrib avisit length=$200;
      set &dsetin;
      visitnum1=int(visitnum);
      if (visitnum1 ne visitnum) or index(visit,"UNSCHEDULED") ne 0 then
      do;
        avisitn = 999;
        avisit = "UNSCHEDULED";
      end;
      else
      do;
        avisitn = visitnum;
        avisit = visit;
      end;
    run;
 %end;  /* end-if  formats AVISITNFMT and AVISITFMT not specified.  */
   
 /*
 / Delete temporary datasets used in this macro.      
 /----------------------------------------------------------------------------*/
 
 %tu_tidyup(rmdset=&prefix:, glbmac=NONE);
%mend tu_advisit;

