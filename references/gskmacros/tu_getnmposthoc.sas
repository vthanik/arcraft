/******************************************************************************* 
|
| Macro Name:      tu_getnmposthoc.sas
|
| Macro Version:   1.0
|
| SAS Version:     8.2
|
| Created By:      Andrew Ratcliffe, RTSL, www.ratcliffe.co.uk
|
| Date:            05-Jul-2005
|
| Macro Purpose:   Make NONMEM post-hoc data available to caller by converting 
|                  one or more text files into a single SAS dataset.
|                  NONMEM post-hoc files are CSV files (one per analyte). Column 
|                  names (but no units) are contained in row 1.
|
| Macro Design:    PROCEDURE STYLE MACRO
| 
| Input Parameters:
|
| NAME              DESCRIPTION                         DEFAULT 
| BY                Specifies the sort order to be      [blank] (opt)
|                   applied to the output dataset
|
| DSETOUT           Specifies the name of the output    [blank] (req)
|                   dataset
|
| INFILEDIR         Specifies the name of the dir-      &g_dmdata (req)
|                   ectory in which the files shall be 
|                   found
|
| INFILEMASK        Operating System-specific mask      [blank] (req)
|                   specifies the names of the NONMEM 
|                   post-hoc files to be read, e.g. "nonmem_parm_*_posthoc.csv". 
|                   Asterisk (*) shall be used as the mask character. 
|                   INFILEDIR shall be searched for the files

|
| Output: This macro produces a dataset containing the combined contents of the 
|         specified NONMEM post-hoc files
|
| Global macro variables created:  None
|
| Macros called:
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_chknames
| (@) tu_getmaskedfiles
| (@) tu_chkvarsexist
| (@) tu_tidyup
| (@) tu_abort
|
| Example:
|
| %tu_getnmposthoc(by = subjid
|                 ,infilemask = nonmem_parm_*_posthoc.csv
|                 ,dsetout = work.posthoc
|                 );
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
| Modified By:              
| Date of Modification:     
| New version number:       
| Modification ID:          
| Reason For Modification:  
|
********************************************************************************/ 

%macro tu_getnmposthoc(by         =           /* Sort order for DSETOUT */
                      ,dsetout    =           /* Output dataset */
                      ,infiledir  = &g_dmdata /* Name of input directory */
                      ,infilemask =           /* Name(s) of input file(s) */
                      );

  /*
  / Echo parameter values and global macro variables to the log.
  /----------------------------------------------------------------------------*/

  %local MacroVersion;
  %let MacroVersion=1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=);

  %local prefix;
  %let prefix=%substr(&sysmacroname,3); 

  /* PARAMETER VALIDATION */

  /* Validate - BY - done in Normal Processing */

  /* Validate - DSETOUT */
  %if %length(%tu_chknames(&dsetout,DATA)) gt 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname.: The value supplied for DSETOUT (&dsetout) is not a valid dataset name;
    %let g_abort=1;
  %end;

  /* Validate - INFILEDIR */
  data _null_;
    length DirExist $8;
    DirExist='';
    rc=filename(DirExist,"&infiledir");
    sysmsg=sysmsg();
    if rc ne 0 then
    do;  /* FILENAME failed */
      put 'RTE' "RROR: &sysmacroname: INFILEDIR: " sysmsg;
      call symput('g_abort','1');
    end; /* FILENAME failed */
    else
    do;  /* FILENAME was ok */
     did=dopen(DirExist);
     if did=0 then
     do;  /* DOPEN failed */
       put 'RTE' "RROR: &sysmacroname.: Directory INFILEDIR (&infiledir) does not exist";  
       call symput('g_abort','1');
     end;  /* DOPEN failed */
     else
     do;  /* DOPEN ok */
       rc=dclose(did);
     end;  /* DOPEN ok */
     rc=filename(DirExist);
    end;  /* FILENAME was ok */
  run;

  /* Validate - INFILEMASK - passed to tu_getmaskedfiles */


  %tu_abort;

  /* NORMAL PROCESSING */

  %local n_files FilePtr;

  /*
  / PLAN OF ACTION
  / 1. Get list of files matching mask
  / 2. Put names of the phoc files into macros vars    
  / 3. For each phocfile, read in the data             
  / 4. Append all the phoc data together                
  / 5. Optionally sort the data                        
  /---------------------------------------------------------------------------*/

  /* 1. Get list of files matching mask */
  %tu_getmaskedfiles(inmask=&infiledir/&infilemask
                    ,dsetout=work.&prefix._phocfilelist
                    ,nummvar = n_files
                    );
  %if &g_debug ge 1 %then 
    %put RTD%str(EBUG): &sysmacroname: N_FILES=&n_files;



  /* 2. Put names of the phoc files into macros vars */
  %do i = 1 %to &n_files;
    %local phocfile&i;
  %end;
  data _null_;
    set &prefix._phocfilelist end=last;
    call symput(compress('phocfile'!!put(_n_,3.))
               ,trim(fullName)
               );
  run;
  
  %if &g_debug ge 1 %then %do;
    %put RTD%str(EBUG): &sysmacroname: Processing &n_files post-hoc file(s):;
    %do FilePtr = 1 %to &n_files.;
      %put &&phocfile&FilePtr;  
    %end;   
  %end; 
    
  /* 3. For each phocfile, read in the data */
  %do FilePtr = 1 %to &n_files.;

    proc import datafile="&&phocfile&FilePtr" dbms=csv
                out=work.&prefix._import&FilePtr;
    run;
 
  %end; /* do over n_files */  
  
  /* 4. Append all the phoc data together */
  
  data work.&prefix._all;
    set %do filePtr = 1 %to &n_files.;
          work.&prefix._import&FilePtr
        %end;;
  run;

  /* 5. Optionally sort the data */
  %if %length(&by) eq 0 %then
  %do;
    data &dsetout;
      set work.&prefix._all;
    run;
  %end;
  %else
  %do;

    /* Validate - BY */
    %if %length(%tu_chkvarsexist(work.&prefix._all,&by)) ne 0 %then
    %do;
      %put RTE%str(RROR): &sysmacroname: One or more of the BY variables (&by) does not exist in the imported file(s);
      %tu_abort(option=force);
    %end;

    /* Do the sort */
    proc sort data=work.&prefix._all out=&dsetout;
      by &by;
    run;

  %end;
 
  /* Finish-off */
  %tu_tidyup(rmdset=&prefix:
            ,glbmac=NONE
            );
  quit;

  %tu_abort;

%mend tu_getnmposthoc;
