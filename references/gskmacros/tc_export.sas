/******************************************************************************* 
|
| Macro Name:      tc_export.sas
|
| Macro Version:   1.0
|
| SAS Version:     8.2
|
| Created By:      Andrew Ratcliffe, RTSL, www.ratcliffe.co.uk
|
| Date:            05-Jul-2005
|
| Macro Purpose:   This macro shall create a CSV file from the specified SAS 
|                  dataset. The output file shall be a simple "dump" of the 
|                  whole dataset, i.e. all variables and all rows.
|
| Macro Design:    PROCEDURE STYLE MACRO
| 
| Input Parameters:
|
| NAME              DESCRIPTION                         DEFAULT 
| DBMS              Specifies the type of data to       [blank] (opt)
|                   export. 
|                   It shall not be necessary to specify DBMS= if the filename 
|                   that is specified by OUTFILE= contains a recognised suffix. 
|                   For a comma-separated file, specify DBMS=CSV, or specify 
|                   a file suffix of ".csv". For a tab-delimited file, 
|                   specify DBMS=TAB, or specify a file suffix of ".txt".
|
| DSETIN            Specifies the name of the input     [blank] (Req)
|                   dataset
|
| OUTDIR            Specifies the name of the dir-      &g_pkdata (req)
|                   ectory in which the output file 
|                   shall be created
|
| OUTFILE           Specifies the name of the file to   [blank] (req)
|                   be created. See the description of 
|                   the DBMS parameter for details on the file suffix
|
| REPLACE           Specifies whether an existing       Y (req)
|                   output file shall be replaced
|
| Output: This macro produces a text file "copy" of the specified dataset
|
| Global macro variables created:  None
|
| Macros called:
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_tidyup
| (@) tu_abort
|
| Example:
|
| %tc_export(dsetin  = ardata.vitals
|           ,outfile = vitals.csv
|           );
|
|******************************************************************************* 
| Change Log 
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     05-Jul-2005
| New version number:       1/2
| Modification ID:          
| Reason For Modification:  Finish-off the list of sub-macros.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     02-Sep-2005
| New version number:       1/3
| Modification ID:          
| Reason For Modification:  Fix: Remove erroneous reference to predtime.
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     16-Sep-2005
| New version number:       1/4
| Modification ID:          
| Reason For Modification:  Change REPLACE default to Y.
|
| Modified By:              
| Date of Modification:     
| New version number:       
| Modification ID:          
| Reason For Modification:  
|
********************************************************************************/ 

%macro tc_export(dbms    =           /* Type of output file */
                ,dsetin  =           /* type:ID Name of input dataset */
                ,outdir  = &g_pkdata /* Name of the output directory */
                ,outfile =           /* Name of the output file */
                ,replace = Y         /* Replace existing output file? */
                );

  /* Echo parameter values and global macro variables to the log */
 
  %local MacroVersion;
  %let MacroVersion = 1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=);

  %local prefix;
  %let prefix = %substr(&sysmacroname,3); 

  /* PARAMETER VALIDATION */
  %let replace = %upcase(&replace);

  /* Validate - DBMS - no validation*/

  /* Validate - DSETIN */
  %if %length(&dsetin) eq 0 %then 
  %do;
    %put RTE%str(RROR): &sysmacroname.: A value must be supplied for DSETIN;
    %let g_abort=1;
  %end;
  %else
  %do;
    %if not %sysfunc(exist(&dsetin)) %then 
    %do;
      %put RTE%str(RROR): &sysmacroname.: The DSETIN dataset (&dsetin) does not exist;
      %let g_abort=1;
    %end;
  %end;

  /* Validate - OUTDIR */
  data _null_;
    length DirExist $8;
    DirExist='';
    rc=filename(DirExist,"&outdir");
    sysmsg=sysmsg();
    if rc ne 0 then
    do;  /* FILENAME failed */
      put 'RTE' "RROR: &sysmacroname: OUTDIR: " sysmsg;
      call symput('g_abort','1');
    end; /* FILENAME failed */
    else
    do;  /* FILENAME was ok */
     did=dopen(DirExist);
     if did=0 then
     do;  /* DOPEN failed */
       put 'RTE' "RROR: &sysmacroname.: Directory OUTDIR (&outdir) does not exist";  
       call symput('g_abort','1');
     end;  /* DOPEN failed */
     else
     do;  /* DOPEN ok */
       rc=dclose(did);
     end;  /* DOPEN ok */
     rc=filename(DirExist);
    end;  /* FILENAME was ok */
  run;

  /* Validate - OUTFILE */
  %if %length(&outfile) eq 0 %then 
  %do;
    %put RTE%str(RROR): &sysmacroname.: A value must be supplied for OUTFILE;
    %let g_abort=1;
  %end;

  /* Validate - REPLACE */
  %if %str(&replace) ne Y and %str(&replace) ne N %then 
  %do;
    %put RTE%str(RROR): &sysmacroname.: The value supplied for REPLACE (&replace) is invalid. Valid values are Y and N;
    %let g_abort=1;
  %end;

  %tu_abort;

  /* NORMAL PROCESSING */ 
  proc export data=&dsetin
              outfile = "&outdir/&outfile"
              %if %length(&dbms) gt 0 %then
              %do;
                dbms = &dbms
              %end;
              %if &replace eq Y %then
              %do;
                REPLACE
              %end;
              ;
  run;

  %if &syserr ne 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: PROC EXPORT returned a non-zero completion code. See preceding message(s);
    %tu_abort(option=force);
  %end;

  /* Finish-off */
  %tu_tidyup(rmdset=&prefix:
            ,glbmac=NONE
            );
  quit;

  %tu_abort;

%mend tc_export;
