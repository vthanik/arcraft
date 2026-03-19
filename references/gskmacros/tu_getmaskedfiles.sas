/*******************************************************************************
|
| Macro Name:     tu_getmaskedfiles.sas
|
| Macro Version:  1
|
| SAS Version:    8.2
|
| Created By:     Andrew Ratcliffe, RTSL
|
| Date:           13 December 2004
|
| Macro Purpose:  This macro shall return a dataset that lists the files
|                 meeting the given file mask. The file mask shall specify
|                 a directory name and a masked file name where "*" is used
|                 as a masking character to represent a variable number of
|                 any characters/digits.
|
|                 Optionally, the macro shall issue an abort if insufficient
|                 files meet the naming criteria.
|
| Macro Design:   Procedure style
|
| Input Parameters:
|
| NAME            DESCRIPTION                                   DEFAULT
|   REQUIRED
| INMASK          Specifies the file mask. Directory name and   [blank]
|                 masked file name shall be supplied.        
|
| DSETOUT         Specifies the name of the dataset to be       [blank]                
|                 created, containing the names of the files
|                 meeting the mask criteria.             
|
| NUMMVAR         Specifies the name of a macro variable into   [blank]      
|                 which the number of matching files shall be
|                 stored. The macro variable must have been 
|                 previously declared as either local or global.
|   OPTIONAL
| MINFILES        Optionally specifies the minimum acceptable   0
|                 number of file names that must match the 
|                 mask. If the minimum number is not met, the
|                 macro shall abort.
|                                
| Output:         Dataset containing list of files in two variables. The first
|                 variable shall be named FULLNAME and shall contain the full
|                 directory and file name; the second shall be named MEMNAME,
|                 it shall contain just the file name.
|
| Global macro variables created: None
|
| Macros called:
| (@) tu_putglobals
| (@) tr_putlocals
| (@) tu_chknames
| (@) tu_nobs
| (@) tu_tidyup
| (@) tu_abort
|
| Example:
|
|   %local n_parmfiles;
|   %tu_getMaskedFiles(inmask   = &parmfilemask
|                     ,dsetout  = work.&prefix._parmfiles
|                     ,nummvar  = n_parmfiles
|                     ,minfiles = 1
|                     );
|
|*******************************************************************************
| Change Log
|
| Modified By:
| Date of Modification:
| New version/draft number:
| Modification ID:
| Reason For Modification:
|
********************************************************************************/

%macro tu_getMaskedFiles(inmask   =    /* The file mask */
                        ,dsetout  =    /* Output dataset name */
                        ,nummvar  =    /* Name of output macro variable */
                        ,minfiles = 0  /* Minimum number of files */
                        );

  /*
  / Echo parameter values and global macro variables to the log.
  /------------------------------------------------------*/

  %local MacroVersion;
  %let MacroVersion = 1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals();

  %local rc;

  %local prefix;
  %let prefix = %substr(&sysmacroname,3);

  /* PARAMETER VALIDATION */

  %if %length(&inmask) eq 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname: The blank value specified for INMASK is invalid;
    %let g_abort = 1;
  %end;

  %if %length(%tu_chknames(&dsetout,DATA)) gt 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname: The value specified for DSETOUT (&dsetout) is invalid;
    %let g_abort = 1;
  %end;

  /*
  / Check that NUMMVAR is specified and has already been 
  / declared as global or local, i.e. by caller 
  /------------------------------------------------------*/
  %if %length(&nummvar) eq 0 %then 
  %do;  /* nummvar not provided */
    %put RTE%str(RROR): &sysmacroname: The blank value specified for NUMMVAR is invalid;
    %let g_abort = 1;
  %end; /* nummvar not provided */
  %else
  %do;  /* nummvar is provided */

    /*
    / Make sure it has already been declared, else it will be 
    / local to THIS macro and will not be seen by our caller. 
    /------------------------------------------------------*/
    %local gotMv;
    %let gotMv = N;

    %local dsid ;
    %let dsid = %sysfunc(open(sashelp.vmacro(where=(scope ne 'AUTOMATIC'))));

    %local fetchrc name name_vn;
    %let name_vn = %sysfunc(varnum(&dsid,NAME));
    %let fetchrc = %sysfunc(fetch(&dsid)); 
    %do %while(&fetchrc eq 0 and &gotMv eq N);
      %let name = %sysfunc(getvarc(&dsid,&name_vn));
      %if &name eq %upcase(&nummvar) %then
        %let gotMv = Y; 
      %let fetchrc = %sysfunc(fetch(&dsid)); 
    %end;

    %let rc = %sysfunc(close(&dsid));

    %if &gotMv eq N %then
    %do;
      %put RTE%str(RROR): &sysmacroname: Value specified for NUMMVAR (&nummvar) is not a known macro variable. Declare it as 'local' beforehand;
      %let g_abort = 1;
    %end;
  %end; /* nummvar is provided */

  %if %length(%sysfunc(compress(&minfiles,0123456789))) ne 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname: The value specified for MINFILES (&minfiles) is invalid;
    %let g_abort = 1;
  %end;

  %tu_abort;

  /* NORMAL PROCESSING */

  /*
  / Check that mask includes a directory name, with  
  / no wildcard in the directory name.               
  /------------------------------------------------------*/

  %local maskMem dirlen maskDir ;
  %let maskMem = %scan(&inMask,-1,/\);
  %let dirlen = %length(&inMask)-%length(&maskMem);
  %if &dirlen eq 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname: INMASK (&inMask) does not include a directory name;
    %tu_abort(option=force);
  %end;
  %else
  %do;  /* Good, inMask includes a directory name */

    %let maskDir = %substr(&inMask
                              ,1
                              ,&dirlen
                              );
    %if &g_debug ge 1 %then %put RTD%str(EBUG): &sysmacroname: MASKDIR=&maskdir;

    %if %index(&maskDir,*) %then
    %do;
      %put RTE%str(RROR): &sysmacroname: INMASK (&inMask) include a wildcard (*) in the directory name;
      %tu_abort(option=force);
    %end;
    %else
    %do;  /* Great, inMask includes a decent directory name */

      /* Retrieve the filenames from the directory based upon the input mask */

          /*
          / Note. inMask uses asterisk as a wildcard. We will use the          
          / SAS "like" operator. He uses % as the wildcard (and _ for a single 
          / character). So we must translate asterisk to %.                    
          /------------------------------------------------------*/
      %local maskLike;
      data _null_;
        /* Replace asterisk with % */
        maskLike = translate("&inMask",'%','*');
        /* Need to add quotes to avoid macro resolution later */
        call symput('MASKLIKE'
                   ,"'" !! trim(maskLike) !! "'"
                   );
      run;
      %if &g_debug ge 1 %then 
        %put RTD%str(EBUG): &sysmacroname: MASKLIKE=&masklike;

      data &dsetout(keep=fullName memName
                    where=(fullName like &maskLike)
                   );

        attrib fullName length=$400. label='Full directory and file name'
               memName  length=$400. label='File name'
               ;

        /*
        / Check that the directory exists by assigning a filename, and 
        / if not, abort the macro with a system error message
        / Check that the directory can be opened, and if not, abort 
        / the macro with a system error message
        /------------------------------------------------------*/

               /*
               / Pass blank value of FILELIB to the FILENAME function so 
               / that it generates a unique fileref for us.              
               /------------------------------------------------------*/
        length filelib $8;
        filelib = '';
        rc = filename(filelib,"&maskDir");
        sysmsg = sysmsg();
        if rc ne 0 then
        do;  /* FILENAME failed */
          call symput('G_ABORT','1');
          put 'RTE' "RROR: &sysmacroname: " sysmsg;
        end; /* FILENAME failed */
        else
        do;  /* FILENAME was ok */
          did=dopen(filelib);
          sysmsg = sysmsg();
          if did eq 0 then
          do;  /* DOPEN failed */
            call symput('G_ABORT','1');
            put 'RTE' "RROR: &sysmacroname: " sysmsg;
          end; /* DOPEN failed */
          else
          do;  /* DOPEN was ok */

            /*
            / Read the member names of the directory using the input 
            / mask and determine if they are file names or directory 
            / names. Create a dataset with the name specified by the 
            / DSETOUT parameter and only output records that are files 
            / and not sub-directories. Create the variables FULLNAME 
            / and MEMNAME as specified in Section 2.2 of the Unit Spec
            /------------------------------------------------------*/

            do i=1 to dnum(did);

              memName = dread(did,i);

              /* Is this a file, or a sub-directory? */
              fullName = "&maskDir." !! memName;
              tmpfref = '        ';
              rc=filename(tmpfref,fullName);
              did2=dopen(tmpfref);
              if did2 gt 0 then
              do;  /* This is a sub-directory */
                rc=dclose(did2);
              end; /* This is a sub-directory */
              else
              do;  /* This is a file */
                OUTPUT;
              end; /* This is a file */
              rc=filename(tmpfref);

            end;
            rc=dclose(did);
          end; /* DOPEN was ok */
          rc = filename(filelib,'');
        end; /* FILENAME was ok */
      run;
      %tu_abort;

      %let &nummvar = %tu_nobs(&dsetout);
      %if &g_debug ge 1 %then
        %put RTD%str(EBUG): &sysmacroname: NUMMVAR=&nummvar=&&&nummvar MINFILES=&minfiles;
      %if &&&nummvar lt &minfiles %then 
      %do;
        %put %str(RTE)RROR: &sysmacroname.: Insufficient files (less than &minfiles) where identified by INMASK (&inMask.).;
        %tu_abort(option=force);
      %end;   

    %end; /* Great, inMask includes a decent directory name */

  %end; /* Good, inMask includes a directory name */

  %tu_tidyup(rmdset=&prefix:, glbmac=NONE);

  %tu_abort;

%mend tu_getMaskedFiles;
