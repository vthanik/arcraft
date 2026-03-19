/******************************************************************************* 
|
| Macro Name:      tu_readdsplan.sas
|
| Macro Version:   1.0
|
| SAS Version:     8.2
|
| Created By:      Andrew Ratcliffe
|
| Date:            14-Dec-2004
|
| Macro Purpose:   The purpose of this macro is to read the HARP Dataset Plan 
|                  and convert it into a single SAS dataset. 
|
|                  The HARP Dataset Plan is a single text file in a style 
|                  similar to PROC CONTENTS output. There will be one Dataset 
|                  Plan per A&R dataset.  
|
| Macro Design:    PROCEDURE STYLE MACRO
| 
| Input Parameters:
|
| NAME              DESCRIPTION                         DEFAULT 
| INFILE            Specifies the name and location     &g_dsplanfile (Req)
|                   of the file containing the A&R 
|                   Dataset Plan
|
| DSETOUT           Specifies the name of the output    [blank] (Req)
|                   dataset
|
| Output: A SAS dataset containing all rows from the input file, except 
|         the input file's header rows
|
| Global macro variables created:  None
|
| Macros called:
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_chknames
| (@) tu_tidyup
| (@) tu_abort
|
| Example:
|
| %tu_readdsplan(INFILE= /arenv/arprod/c/s/r/dsplan_ae_spec.txt
|               ,DSETOUT= work.dsplan
|               );
|
|******************************************************************************* 
| Change Log 
|
| Modified By:              Andrew Ratcliffe, RTSL
| Date of Modification:     25-Jan-05
| New version number:       01-002
| Modification ID:          AR2
| Reason For Modification:  Permit values of DATE, TIME, and DATETIME for
|                           vartype, in addition to CHAR and NUM.
|                           Check for "null" format - this is an indication 
|                           that HARP 1.1 was used and that no format was specified.
|
| Modified By:              
| Date of Modification:     
| New version number:       
| Modification ID: 
| Reason For Modification:  
|
********************************************************************************/ 

%macro tu_readdsplan(INFILE=&g_dsplanfile /* type: IF Dataset Plan filename */
                    ,DSETOUT= /* Output dataset */
                    );

  /* Standard beginning */
  %local MacroVersion;
  %let MacroVersion=1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals() 

  %local prefix;
  %let prefix=_readdsplan;

  /***********************************/
  /* Begin with parameter validation */
  /***********************************/

  /* Check that INFILE exists */
  %if %length(&infile) eq 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname: Invalid blank value specified for INFILE;
    %let g_abort = 1;
  %end;  
  %else
  %do;
    %if not %sysfunc(fileexist(&infile)) %then
    %do;
      %put RTE%str(RROR): &sysmacroname: INFILE (&infile) does not exist;
      %let g_abort = 1;
    %end;
  %end;

  /* Check that DSETOUT is a valid dataset name (%tu_chknames) */
  %if %length(%tu_chknames(&dsetout,DATA)) %then
  %do;
    %put RTE%str(RROR): &sysmacroname: DSETOUT (&dsetout) is not a valid dataset name;
    %let g_abort = 1;
  %end;

  /* Abort if there were any errors */
  %tu_abort;

  /****************************/
  /* Now do normal processing */
  /****************************/

  data &prefix._infile;
    infile "&infile" 
           delimiter='09'x MISSOVER DSD 
           lrecl=32767 
           firstobs=5 ;
    attrib  varname length=$52
            varlabel length=$33
            crtinclflag length=$1
            vartype length=$8   /*AR2*/
            length length=$5
            format length=$10
            derivation length=$200
            comments length=$200
            acrfpages length=$200
            varorder length=$4
            sortorder length=$4
            decodeformat length=$10
            ;
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
          decodeformat $
          ;
    if varname ne '' then OUTPUT;
  run;

  /* Perform the following validation and assignments */
  data &dsetout;
    set &prefix._infile;

    if upcase(vartype) not in ('NUM' 'CHAR' 'DATE' 'TIME' 'DATETIME') then  /*AR2*/
    do;  /* Verify that vartype is populated correctly */
      if vartype eq '' then
        put "RTE" "RROR: &sysmacroname: Invalid blank value specified for TYPE for " 
            varname $upcase.
            ;
      else
        put "RTE" "RROR: &sysmacroname: Invalid TYPE (" vartype +(-1)
            ") for " 
            varname $upcase. 
            ;
      put "RTE" "RROR: &sysmacroname: Type should be 'Char', 'Num', 'Date', 'Time', or 'Datetime'";  /*AR2*/
      call symput('G_ABORT','1');
      RETURN;
    end; /* Verify that vartype is populated correctly */

    if length eq '' then 
    do;  /* Missing length */
      put "RTW" "ARNING: &sysmacroname: Missing length for " 
          varname $upcase. ;
      select (upcase(vartype));  /* Make the following assignments if missing */   
        when ('CHAR')     length = '$200';
        when ('NUM')      length = '8';
        when ('DATE')     length = '8';   /*AR2*/
        when ('TIME')     length = '8';   /*AR2*/
        when ('DATETIME') length = '8';   /*AR2*/
      end; /* Make the following assignments if missing */
      put "RTW" "ARNING: &sysmacroname: The length will be set to " length;
    end; /* Missing length */

    if upcase(vartype) in ('NUM' 'DATE' 'TIME' 'DATETIME') then   /*AR2*/
    do;  /* Numeric */
      if input(length,best.) gt 8 then
      do;  /* Over-size numeric */
        put "RTW" "ARNING: &sysmacroname: Invalid length (" length +(-1) ") for " 
            varname $upcase. ;
        length = '8';
        put "RTW" "ARNING: &sysmacroname: Numeric lengths cannot exceed 8. Length has been set to " 
            length;
      end; /* Over-size numeric */
    end; /* Numeric */

    if upcase(format) eq "NULL" then    /*AR2*/
    do;  /* Null format */
      put "RTE" "RROR: &sysmacroname: Invalid 'null' value specified for FORMAT for " 
          varname $upcase. ;
      call symput('G_ABORT','1');
    end; /* Null format */

  run;
  %tu_abort;

  /* Finished... */
  %if &g_debug ge 1 %then
  %do;
    title "RTD" "EBUG: &sysmacroname: Output dataset (&dsetout)";
    proc contents data=&dsetout;
    run;
  %end;

  %if &g_debug ge 2 %then
  %do;
    title "RTD" "EBUG: &sysmacroname: Output dataset (&dsetout)";
    proc print data=&dsetout;
    run;
  %end;

  /******************************************************************/
  %tu_tidyup(rmdset=&prefix:, glbmac=NONE);
  %tu_abort;

%mend tu_readdsplan;
 
