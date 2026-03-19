/*------------------------------------------------------------------------------
| Macro Name       : tc_p1_randall_xo.sas
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
|                     - XO study. Re-labels ptrtgrp and adds SCR & FUP records
|
| Macro Design     : PROCEDURE STYLE
|
| Input Parameters : None
|
|-------------------------------------------------------------------------------
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
|           %tc_p1_randall_xo();
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
|
+-----------------------------------------------------------------------------*/
%macro tc_p1_randall_xo();

   /*
   / Echo parameter values and global macro variables to the log.
   /----------------------------------------------------------------------------*/
   %local MacroVersion;
   %let MacroVersion = 2 build 1;
   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals();
  
   %local prefix macroname;

   %let macroname = &sysmacroname.;
   %let prefix = _tc_p1_randall_xo;   /* Root name for temporary work datasets */
  
   /*
   / Verify the dataset rfmtdir.randall exists
   /------------------------------------------------------------------------------*/
   %if %sysfunc(exist(rfmtdir.randall)) eq 0 %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: The rfmtdir.RANDALL dataset does not exist.;
      %let g_abort=1;
   %end;

   /*
   / Verify the catalog rfmtdir.formats exists.  
   /-------------------------------------------------------------------------*/
   %if %sysfunc(cexist(rfmtdir.formats)) eq 0 %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: The rfmtdir.FORMATS catalog does not exist.;
      %let g_abort=1;
   %end;
   /*
   / rfmtdir.formats exists, check if format ptrt exists in this catalog  
   /-------------------------------------------------------------------------*/
   %else %if %sysfunc(cexist(rfmtdir.formats.ptrt.formatc)) eq 0 %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: The PTRT format does not exist in rfmtdir.formats.;
      %let g_abort=1;
   %end;

   %if &g_abort eq 1 %then
   %do;
      %tu_abort;
   %end;   
   
   /*
   / NORMAL PROCESSING
   /----------------------------------------------------------------------------*/
  
   /*
   / Read in randall from the refdata directory
   /----------------------------------------------------------------------------*/
   proc sort data=rfmtdir.randall out=&prefix._ds1;
      by randnum pernum;
   run;

   /*
   / Add Screening and Follow-up obs to RANDALL dataset
   /----------------------------------------------------------------------------*/
   data &prefix._ds2;
      set &prefix._ds1;
      by randnum;
      output;
      if last.randnum then do;
         pernum=0;
         ptrtgrp='0'; *This is the number zero*;
         output;
         pernum=999;
         ptrtgrp='Z';
         output;
      end;
   run;

   /*
   / Write to dmdata re-setting PTRTGRP & TRTDESC using $ptrt
   /----------------------------------------------------------------------------*/
   data &prefix._ds3;
      set &prefix._ds2;
 /** Note: The $ptrt format should be created as specified in DTUG0 section 3 **/;
 /**       and should include '0'=... & 'Z'=... for SCR and FUP respectively  **/;
      ptrtgrp=put(ptrtgrp,$ptrt.);
      if pernum in(0,999) then trtdesc=put(ptrtgrp,$ptrt.);
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
            from &prefix._ds3
            order by randnum, pernum;
   quit;

   /*
   / Delete temporary datasets used in this macro.
   /----------------------------------------------------------------------------*/
   %tu_tidyup(
      rmdset = &prefix:, 
      glbmac = NONE
      );

%mend tc_p1_randall_xo;
