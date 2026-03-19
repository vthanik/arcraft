/*******************************************************************************
|
| Macro Name:      tu_getsortorder
|
| Macro Version:   1
|
| SAS Version:     8.2
|
| Created By:      Mark Luff / Eric Simms
|
| Date:            07-May-2004
|
| Macro Purpose:   Get planned dataset variable sort order from HARP
|                  Application metadata or directly from user.
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                            REQ/OPT  DEFAULT
| -----------------  -------------------------------------  -------  ----------
| DSPLAN             Specifies the path and file name of     REQ      (Blank)
|                    the HARP A&R dataset metadata. This
|                    will define the sort order desired.                  
|
| SORTORDERMVAR      Specifies the name of the macro         REQ      (Blank)
|                    variable which will contain the sort
|                    order variable names separated by 
|                    spaces.
| -----------------  -------------------------------------  -------  ----------
|
| Output:
|
| Global macro variables created: NONE
|
| Macro variable assigned:
|
| --------------  -------------------------------------------------------------
| Name            Description
| --------------  -------------------------------------------------------------
| &SORTORDERMVAR  Sort order of planned A&R dataset.
| --------------  -------------------------------------------------------------
|
|
| Macros called:
|(@) tr_putlocals
|(@) tu_putglobals
|(@) tu_abort
|(@) tu_tidyup
|
| Example:
|    %tu_getsortorder(
|         dsplan          = &R_ARDATA/ae_spec.txt,
|         sortordermvar   = ae_sortorder
|         );
|
|******************************************************************************
| Change Log
|
| Modified By:
| Date of Modification:
| New version/draft number:
| Modification ID:
| Reason For Modification:
|
*******************************************************************************/
%macro tu_getsortorder (
     dsplan          = ,   /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
     sortordermvar   =     /* Planned A&R dataset sort order macro variable */
        );

 /*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion;
 %let MacroVersion = 1;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals() 

 /*
 / PARAMETER VALIDATION
 /----------------------------------------------------------------------------*/

 %let dsplan          = %nrbquote(&dsplan);
 %let sortordermvar   = %nrbquote(&sortordermvar);

 /*
 / Check for required parameters.
 /----------------------------------------------------------------------------*/

 %if &dsplan eq %then
 %do;
    %put %str(RTE)RROR: TU_GETSORTORDER: The parameter DSPLAN is required.;
    %let g_abort=1;
 %end;     /* end-if for required DSPLAN parameter not specified.  */
 %else
 %do;
    %if %sysfunc(fileexist("&dsplan")) eq 0 %then
    %do;
       %put %str(RTE)RROR: TU_GETSORTORDER: The DSPLAN file "&DSPLAN" does not exist.;
       %let g_abort=1;
    %end;   /* end-if for required DSPLAN parameter specified, but does not exist. */
 %end;      /* end-if for required DSPLAN parameter specified and exists. */

 %if &sortordermvar eq %then
 %do;
    %put %str(RTE)RROR: TU_GETSORTORDER: The parameter SORTORDERMVAR is required.;
    %let g_abort=1;
 %end;      /* end-if for required SORTORDERMVAR parameter not specified.  */

 /*
 / Check that &SORTORDERMVAR has been pre-initialised.
 /----------------------------------------------------------------------------*/

 %local l_name;

 proc sql noprint;
      select name into :l_name
      from dictionary.macros
      where name="%upcase(&sortordermvar)";
 quit;

 %if &l_name eq %then 
 %do;
    %put %str(RTE)RROR: TU_GETSORTORDER: Macro variable referred to by SORTORDERMVAR parameter must be initialised prior to calling this macro.;
    %let g_abort=1;
 %end;  /* end-if variable specified for SORTORDERMVAR was not pre-initialized */ 

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;

 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/

 %local prefix;
 %let prefix = _getsortorder;   /* Root name for temporary work datasets */

 /*
 / Retrieve variable names to be used in the sort, and their sort order.
 /----------------------------------------------------------------------------*/

 data &prefix._attrib(keep= varname sortorder num_sortorder where=(sortorder ne ''));
   infile "&dsplan"
          delimiter='09'x missover dsd
          lrecl=32767
          firstobs=5 ;

   attrib  varname length=$52
           varlabel length=$40
           crtinclflag length=$1
           vartype length=$4
           length length=$5
           format length=$10
           derivation length=$200
           comments length=$200
           acrfpages length=$200
           varorder length=$4
           sortorder length=$4
           decodeformat length=$10 ;

   input varname $
         varlabel $
         crtinclflag $
         vartype $
         length $
         format $
         derivation $
         comments $
         acrfpages $
         varorder $
         sortorder $
         decodeformat $ ;

   if sortorder ne "" then num_sortorder=input(sortorder,8.);
 run;

 proc sql noprint;
      select varname into :%unquote(&sortordermvar) separated by ' ' 
      from &prefix._attrib 
      order by num_sortorder;
 quit;

 %if %unquote(&&&sortordermvar) ne %then 
 %do;
    %put %str(RTN)OTE: TU_GETSORTORDER: Sort order from &DSPLAN: %unquote(&&&sortordermvar..).;
 %end;   /* end-if  sort order obtained from SORTORDERMVAR  is valid  */
 %else 
 %do;
    %put %str(RTE)RROR: TU_GETSORTORDER: Sort order not found in &dsplan;
    %tu_abort(option = FORCE)
 %end;   /* end-if sort order obtained from SORTORDERMVAR not valid.  */

 /*
 / Delete temporary datasets used in this macro.
 /----------------------------------------------------------------------------*/

 %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tu_getsortorder;
