/*------------------------------------------------------------------------------
| Macro Name       : tc_p1_randall_pg.sas
|
| Macro Version    : 2
|
| SAS version      : SAS v9.1
|
| Created By       : Barry Ashby
|
| Date             : 20-Feb-2008
|
| Macro Purpose    : Re-creates DMDATA.RANDALL
|                     - Simple PG study. Just re-labels TRTGRP.
|
| Macro Design     : PROCEDURE STYLE
|
| Input Parameters : 
| Name                Description                                       Default           
| ------------------------------------------------------------------------------
| TRT_CODEVAR        Holds the variable name used to decode TRTGRP      <blank>
|                    variable in the randall dataset. The variable 
|                    value will be either TRTGRP or PTRTGRP. 
|
|-------------------------------------------------------------------------------
| Output:   1. Re-creates DMDATA.RANDALL
|
| Global macro variables created:  None
|
| Macros called :
|(@) tr_putlocals
|(@) tu_abort
|(@) tu_putglobals
|(@) tu_tidyup
|
| Example:  %ts_setup();
|           %tc_p1_randall_pg();
|
|-------------------------------------------------------------------------------
|
| Change Log :
|
| Modified By :             Khilit Shah (kys41925)
| Date of Modification :    12-Mar-10
| New Version Number :      v2 Build 1
| Modification ID :         001
| Reason For Modification :   Include SCHEDNUM and SCHEDTX variables when writing
|							  to output dataset
|-------------------------------------------------------------------------------
| Modified By :             
| Date of Modification :    
| New Version Number :      
| Modification ID :         
| Reason For Modification : 
+-----------------------------------------------------------------------------*/

%macro tc_p1_randall_pg (
   trt_codevar           =        /* Contains variable used to decode TRTGRP with $TRT  */
   );

   /*
   / Echo parameter values and global macro variables to the log.
   /----------------------------------------------------------------------------*/
   %local MacroVersion;
   %let MacroVersion = 2 build 1;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals();
  
   %local prefix macroname;

   %let macroname = &sysmacroname.;
   %let prefix = _tc_p1_randall_pg;   /* Root name for temporary work datasets */
  
   /*
   / PARAMETER VALIDATION
   /----------------------------------------------------------------------------*/
   
   /*
   / Check for required parameter.
   /----------------------------------------------------------------------------*/
   %if &trt_codevar = %then %do;
      %put %str(RTE)RROR: &sysmacroname: The parameter (trt_codevar) cannot be missing. Valid values: TRTGRP or PTRTGRP.;
      %let g_abort=1;
   %end;
   %else %if (%upcase(&trt_codevar) ne TRTGRP) and (%upcase(&trt_codevar) ne PTRTGRP) %then %do;
      %put %str(RTE)RROR: &SYSMACRONAME.: Value of TRT_CODEVAR(=&trt_codevar) is invalid. Valid values: TRTGRP or PTRTGRP.;       
      %let g_abort=1;    
   %end;

   /*
   / Verify the dataset rfmtdir.randall exists
   /------------------------------------------------------------------------------*/
   %if %sysfunc(exist(rfmtdir.randall)) eq 0 %then %do;
      %put %str(RTE)RROR: &sysmacroname: The rfmtdir.RANDALL dataset does not exist.;
      %let g_abort=1;
   %end;

   /*
   / Verify the catalog rfmtdir.formats exists.  
   /-------------------------------------------------------------------------*/
   %if %sysfunc(cexist(rfmtdir.formats)) eq 0 %then %do;
      %put %str(RTE)RROR: &sysmacroname: The rfmtdir.FORMATS catalog does not exist.;
      %let g_abort=1;
   %end;
   /*
   / rfmtdir.formats exists, check if format trt exists in this catalog  
   /-------------------------------------------------------------------------*/
   %else %if %sysfunc(cexist(rfmtdir.formats.trt.formatc)) eq 0 %then %do;
      %put %str(RTE)RROR: &sysmacroname: The TRT format does not exist in rfmtdir.formats.;
      %let g_abort=1;
   %end;

   %if &g_abort eq 1 %then %do;
      %tu_abort;
   %end;   
   
   /*
   / NORMAL PROCESSING
   /----------------------------------------------------------------------------*/
  
   /*
   / Decode TRTGRP using parameter TRT_CODEVAR value with format $trt
   /----------------------------------------------------------------------------*/
   data &prefix._ds1;
      set rfmtdir.randall;
  /** Note: the $trt format should be created as specified in DTUG0 section 3 **/
      trtgrp=put(&trt_codevar,$trt.);
   run;

   /*
   /  Re-assign dmdata libname without the read-only option otherwise
   /  next step fails because current libref dmdata is read-only access
   /----------------------------------------------------------------------------*/
   data _null_;
      set sashelp.vslib(where=(libname='DMDATA'));
     call execute('libname dmdata "' || trim(path) || '";');
   run;

   /*
   / Output randall to dmdata, order dataset variables and sort dataset output
   /----------------------------------------------------------------------------*/
   /*
   / KS - v2 Build 1 - 001
   / Include SCHEDNUM and SCHEDTX variables
   /---------------------------------------------------------------------------*/
   proc sql noprint;
      create table dmdata.randall as
         select RANDNUM, STRATUM, TRTGRP, PTRTGRP, TRTDESC, PERNUM, SCHEDNUM, SCHEDTX
            from &prefix._ds1
            order by randnum, pernum;
   quit;

   /*
   / Delete temporary datasets used in this macro.
   /----------------------------------------------------------------------------*/
   %tu_tidyup(
      rmdset = &prefix:, 
      glbmac = NONE
      );

%mend tc_p1_randall_pg;
