/*******************************************************************************
|
| Macro Name:      tu_getformatnames
|
| Macro Version:   2
|
| SAS Version:     8.2
|
| Created By:      Mark Luff / Eric Simms
|
| Date:            10-May-2004
|
| Macro Purpose:   Get dataset of variable names associated to format names
|                  from HARP Application metadata
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME               DESCRIPTION                                         REQ/OPT      DEFAULT
| -----------------  -------------------------------------------------  ----------   ----------
| DSPLAN             Specifies the path and file name of the HARP A&R    Req         (None)
|                    metadata. This will define the format to use to     
|                    decode a variable.
|                  
|
| FORMATNAMESDSET    Specifies the name to give to the dataset           Req         (None) 
|                    containing the variables and associated formats  
|                    created.      
| -----------------  -------------------------------------------------  -----------   ----------
|
| Output:
|
| The macro outputs the following datasets :-
| ------------------------------------------------------------------
| Name                        Description
| ------------------------  -------------------------------------------------
| &FORMATNAMESDSET           Output dataset with variables:
|
|                              NAME       DESCRIPTION
|                              ---------  -------------------------------------
|                              VAR_NM     Variable name   (CD suffix)
|                              FORMAT_NM  SAS format name ($ prefix, S suffix)
| ------------------------  -------------------------------------------------
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
|    %tu_getformatnames(
|         dsplan          = &R_ARDATA/ae_spec.txt,
|         formatnamesdset = _formats
|         );
|
|******************************************************************************
| Change Log
|
| Modified By:              Anthony J Cooper
| Date of Modification:     19-Aug-2014
| New version/draft number: 2
| Modification ID:          AJC001
| Reason For Modification:  HRT0301
|                           Increase length of decodeformat to handle
|                           32 character Controlled Term names.
|
*******************************************************************************/
%macro tu_getformatnames (
     dsplan          = ,  /* Path and filename of tab-delimited file containing HARP A&R dataset plan */
     formatnamesdset =    /* Format names output dataset name */
        );

 /*
 / Echo parameter values and global macro variables to the log.
 /----------------------------------------------------------------------------*/

 %local MacroVersion;
 %let MacroVersion = 2;
 %include "&g_refdata/tr_putlocals.sas";
 %tu_putglobals() 

 /*
 / PARAMETER VALIDATION
 /----------------------------------------------------------------------------*/

 %let dsplan          = %nrbquote(&dsplan);
 %let formatnamesdset = %nrbquote(&formatnamesdset);

 /*
 / Check for required parameters.
 /----------------------------------------------------------------------------*/

 %if &dsplan eq %then
 %do;
    %put %str(RTE)RROR: TU_GETFORMATNAMES: The parameter DSPLAN is required.;
    %let g_abort=1;
 %end;
 %else
 %do;
    %if %sysfunc(fileexist("&dsplan")) eq 0 %then
    %do;
       %put %str(RTE)RROR: TU_GETFORMATNAMES: The DSPLAN file "&DSPLAN" does not exist.;
       %let g_abort=1;
    %end;
 %end;

 %if &formatnamesdset eq %then
 %do;
    %put %str(RTE)RROR: TU_GETFORMATNAMES: The parameter FORMATNAMESDSET is required.;
    %let g_abort=1;
 %end;

 %if &g_abort eq 1 %then
 %do;
    %tu_abort;
 %end;

 /*
 / NORMAL PROCESSING
 /----------------------------------------------------------------------------*/

 %local prefix;
 %let prefix = _getformatnames;   /* Root name for temporary work datasets */

 /*
 / Retrieve all variable names with associated decode formats.
 /----------------------------------------------------------------------------*/

 data &formatnamesdset(keep= varname decodeformat rename=(varname=var_nm decodeformat=format_nm) where=(format_nm ne '')); 
   infile "&dsplan" 
          delimiter='09'x missover dsd 
          lrecl=32767 
          firstobs=5 ;

   /* AJC001: Increased length of decodeformat from $10 to $33 */
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
           decodeformat length=$33 ;
           
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
 run;

 /*
 / Delete temporary datasets used in this macro.
 /----------------------------------------------------------------------------*/

 %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

%mend tu_getformatnames;
