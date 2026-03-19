/*******************************************************************************
|
| Macro Name:      tu_getplanneddset
|
| Macro Version:   1
|
| SAS Version:     8.2
|
| Created By:      Mark Luff / Eric Simms
|
| Date:            07-May-2004
|
| Macro Purpose:   Get planned dataset template from HARP
|                  Application metadata
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                            REQ/OPT  DEFAULT
| -----------------  -------------------------------------  -------  ----------
| DSPLAN             Specifies the path and file name of     REQ     (Blank)
|                    the HARP A&R dataset metadata.  This
|                    will define the attributes to use to
|                    define the A&R dataset.
|
| DSETTEMPLATE       Specifies the name to give to the       REQ      (Blank)
|                    empty dataset containing the 
|                    variables and attributes desired for
|                    the A&R dataset.          
| -----------------  -------------------------------------  -------  ----------
|
| Output:
|
| The macro outputs the following datasets :-
| -----------------  -------  -------------------------------------------------
| Name               Req/Opt  Description
| -----------------  -------  -------------------------------------------------
| &DSETTEMPLATE      Req      A SAS dataset named &dsettemplate which contains 
|                             the variables and their associated attributes as
|                             defined in the HARP A&R dataset plan.
| -----------------  -------  -------------------------------------------------
|
| Global macro variables created: NONE
|
|
| Macros called:
|(@) tr_putlocals
|(@) tu_putglobals
|(@) tu_abort
|(@) tu_tidyup
|
| Example:
|    %tu_getplanneddset(
|         dsplan          = &R_ARDATA/ae_spec.txt,
|         dsettemplate    = planned_ae
|         );
|
|******************************************************************************
| Change Log
|
| Modified By: Eric Simms
| Date of Modification: 12Jan2005
| New version/draft number: 1/2
| Modification ID: ems001
| Reason For Modification: 1) Need to allow for lack of dataset label on 
|                             the *_spec.txt tab-delimited input file.
|                          2) Added comments on %inc tmp1, tmp2, tmp3
|                             statements to improve clarity of logic.
|
| Modified By: Eric Simms
| Date of Modification: 13Jan2005
| New version/draft number: 1/3
| Modification ID: ems002
| Reason For Modification: 1) Need to remove tab when testing for dataset
|                             label being present. 
|                          2) Need to make use of %nrbquote function when
|                             testing if dataset label is blank.
|
| Modified By: Eric Simms
| Date of Modification: 26Jan2005
| New version/draft number: 1/4
| Modification ID: ems003
| Reason For Modification: 1) Numeric variables can have a maximum storage
|                             length of 8. 
|                          2) Needed to allow for a total of 11 characters
|                             to hold format instead of 10. This is due to
|                             overlooking the final period in the  DATETIME20. 
|                             format.
|
| Modified By:              Yongwei Wang 
| Date of Modification:     23Feb2005
| New version/draft number: 1/5
| Modification ID:          YW001
| Reason For Modification:  1) Quoted DSLABEL with %superq.
|                           2) Combined three data step to one when creating
|                              temporary file
|                           3) Added code to compress the NOTE: message about 
|                              unintializied variabels
|                           4) Set NULL in length and format to blank
*******************************************************************************/
%macro tu_getplanneddset (
     dsplan          = ,  /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
     dsettemplate    =    /* Output dataset template name */
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
 %let dsettemplate    = %nrbquote(&dsettemplate);

 /*
 / Check for required parameters.
 /----------------------------------------------------------------------------*/

 %if &dsplan eq %then
 %do;
    %put %str(RTE)RROR: TU_GETPLANNEDDSET: The parameter DSPLAN is required.;
    %let g_abort=1;
 %end;         /* end-if  required DSPLAN parameter is not specified.  */

 %else
 %do;
    %if %sysfunc(fileexist("&dsplan")) eq 0 %then
    %do;
       %put %str(RTE)RROR: TU_GETPLANNEDDSET: The DSPLAN file "&DSPLAN" does not exist.;
       %let g_abort=1;
    %end;      /* end-if required DSPLAN parameter is specified but does not exist.  */
 %end;         /* end-if required DSPLAN parameter is specified and exists. */

 %if &dsettemplate eq %then
 %do;
    %put %str(RTE)RROR: TU_GETPLANNEDDSET: The parameter DSETTEMPLATE is required.;
    %let g_abort=1;
 %end;    /* end-if required TU_GETPLANNEDDSET parameter is not specified. */

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;

 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/

 %local prefix;
 %let prefix = _getplanneddset;   /* Root name for temporary work datasets */

 /*
 / ems001
 / Retrieve the dataset label to be applied to the A&R dataset.
 /----------------------------------------------------------------------------*/

 %local dslabel;

 data _null_;
   infile "&dsplan" 
          lrecl=32767 
          firstobs=2;
   length dslabel $40;
   input;

   /* If the label was not defined, then the line will only be 14 */
   /* characters long ("Dataset Label:"), and we will not use the */
   /* LABEL statement for the dataset later on in this code.      */

   if length(compress(_infile_,'09'x)) gt 14 then
   do; /* ems002 */
      dslabel=left(substr(_infile_,16));
      call symput('dslabel',trim(dslabel)); /* YW001: added trim */
   end;
   else
   do;
      put "RTW" "ARNING: TU_GETPLANNEDDSET: Dataset label not found in DSPLAN (&dsplan).";
      put "RTW" "ARNING: TU_GETPLANNEDDSET: This will result in no dataset label being assigned.";
   end;
   stop;
 run;

 /*
 / Retrieve all variable names and their attributes.    
 /----------------------------------------------------------------------------*/

 data &prefix._attrib(keep= varname varlabel vartype length format varorder num_varorder);
   infile "&dsplan"
          delimiter='09'x missover dsd
          lrecl=32767
          firstobs=5 ;

   /* ems003 - changed length of format from $10 to $11. */
   attrib  varname length=$52
           varlabel length=$40
           crtinclflag length=$1
           vartype length=$4
           length length=$5
           format length=$11
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

   if varorder ne "" then num_varorder=input(varorder,8.);
   else num_varorder=99999;
 run;

 /*
 / Get the variables in desired column order.    
 /----------------------------------------------------------------------------*/

 proc sort data=&prefix._attrib out=&prefix._sort_attrib;
   by num_varorder;
 run;

 /*
 / Create program statements to produce dataset template.   
 / YW001: Combined three data steps to one.  
 /----------------------------------------------------------------------------*/

 filename tmp1 temp;    
 data _null_;
      set &prefix._sort_attrib;
      file tmp1; 
      
      /* YW001: set NULL to missing */
      
      if upcase(length) eq 'NULL' then length='';
      if upcase(format) eq 'NULL' then format='';
      
      /* Get variable length statements. */
      
      if length   ne "" then do;
         if index(length, '$') eq 0 then     /* YW001: */
         do;
            if upcase(vartype) eq "CHAR" then length='$' || length;
            else if input(length,8.) gt 8 then length='8';       
         end;
         put 'length ' varname ' ' length ';' ;
      end;
      
      /* Get variable label statements.  */

      if varlabel ne "" then 
         put 'label ' varname '="' varlabel +(-1) '";' ;

      /* Get variable format statements. */

      if format   ne "" then 
         put 'format ' varname ' ' format +(-1) ';' ;    
      
      /* YW001: Compress the NOTE: message about unintializied variabels */   
      if (format ne '') or (length ne '') then
      do;
         if ( index(length, '$') gt 0 ) or (index(format, '$') gt 0 ) then
            put 'retain ' varname ' "";' ;  
         else
            put 'retain ' varname ' .;';
      end;      
 run;

 /*
 / ems001
 / Assign dataset label if it was defined in *_spec.txt.
 / Execute statements within files.
 / YW001: quote dslabel with %superq.
 /----------------------------------------------------------------------------*/

 %if %superq(dslabel) eq  %then
 %do; /* ems002 */
    data &dsettemplate;
 %end;
 %else
 %do;
    data &dsettemplate(label="%superq(dslabel)");
 %end;
      %inc tmp1; 
      stop;
 run;

 /*
 / Delete temporary datasets used in this macro.
 /----------------------------------------------------------------------------*/

 %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tu_getplanneddset;
