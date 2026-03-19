/*--------------------------------------------------------------------------+
| Macro Name    : tu_chknames.sas
|
| Macro Version : 2
|
| SAS version   : SAS v8.2
|
| Created By    : Jenny Colthart
|
| Date          : 27-May-2003
|
| Macro Purpose : To provide information on whether names in an input
|                 string are valid SAS names
|
| Macro Design  : Function
|
| Input Parameters :
|
| NAME           DESCRIPTION                              REQ/OPT   DEFAULT
|
| NAMESIN    - list of names to be checked                REQ       none
|
| NAMETYPE   - type of name (data or variable)            REQ       none
|
|
|
| Output:
|
|   1. If an error is programmatically captured in parameter checking or
|      elsewhere then the function macro resolves to the value -1
|   2. If all names in the NAMESIN parameter are valid then the function
|      macro resolves to an empty string..
|   3. If one or more names in the NAMESIN parameter are not valid then
|      the function macro resolves to a list of invalid names.
|
| Global macro variables created: None
|
|
| Macros called :
|  (@)tu_putglobals
|
|
| Example:
| %tu_chknames(in.ds1 ds2 tmp1, data)
|
|
| **************************************************************************
| Change Log :
|
| Modified By :             Shan Lee
| Date of Modification :    24-Jun-2003
| New Version Number :      1/2
| Modification ID :         SL001
| Reason For Modification : Incorporate feedback from first iteration of SCR.
|
| Modified By :             Shan Lee
| Date of Modification :    03-Jul-2003
| New Version Number :      1/3
| Modification ID :         SL002
| Reason For Modification : Make amendments after first iteration of unit
|                           testing.
|
| Modified by:              Yongwei Wang
| Date of modification:     02Apr2008
| New version number:       2/1
| Modification ID:          YW001
| Reason for modification:  Based on change request HRT0193
|                           1.Echo macro name and version and local/global macro                                            
|                             variables to the log when g_debug > 0    
|                           2.Modified RTERROR messages to output details of 
|                             invalid names
+----------------------------------------------------------------------------*/

%macro tu_chknames
   (
   namesin,  /* List of names to be checked */
   nametype  /* Type of names (DATA or VARIABLE) */
   );


  /*
  / Echo values of parameters and global macro variables to the log.
  /--------------------------------------------------------------------------*/

  %local MacroVersion;
  %let MacroVersion = 2;
  
  %if &g_debug GT 0 %then
  %do;

    %put ************************************************************;
    %put * Macro name: &sysmacroname,  Macro Version: &macroVersion ;
    %put ************************************************************;
   
    %put * &sysmacroname has been called with the following parameters: ;
    %put * ;
    %put _local_;
    %put * ;
    %put ************************************************************;

     %tu_putglobals()
     
  %end;

  /*
  / Declare local macro variables that will be assigned during the execution
  / of this macro.
  /
  / RETURN     Value that will be returned by this function macro. This is
  /            set to missing at the start of the macro. If problems are
  /            detected during parameter validation, then it will be set to
  /            -1, and normal processing will be skipped. During normal
  /            processing, if there is a problem with a word in NAMESIN, then
  /            it will be appended to RETURN. So at the end of the execution
  /            of this macro, the value of RETURN will be equal to the value
  /            that needs to be returned.
  /
  / M          Variable for counting iterations during DO loop processing.
  /
  / N          Variable for counting iterations during DO loop processing.
  /
  / CURR_NAME  Name of current word in NAMESIN that is being inspected during
  /            normal processing. If NAMETYPE is DATA, then the libref will be
  /            removed at the start of normal processing.
  /
  / ANYLIB     If NAMETYPE is DATA, then ANYLIB will be set to the value of
  /            any libref that is part of the current word.
  /
  / IS_BAD     Boolean to indicate whether there is a problem with the current
  /            word. During normal processing, this variable will be set to 1
  /            if the current word fails any of the tests. Since a word may
  /            fail more than one test, IS_BAD may be set to 1 more than once,
  /            but the current word will only be appended to RETURN once if
  /            IS_BAD is 1, after all the tests have been executed for the
  /            current word.
  /
  / LEN        Will take numeric value indicating length of a given text
  /            string.
  /
  / NCHAR      Position of character within a given text string.
  /
  / DOT_POS    If NAMETYPE eq DATA, then DOT_POS is used to store the position
  /            of the first dot, ".", that appears in the current word from
  /            NAMESIN. If there is no dot in the current word, then DOT_POS
  /            will be set to zero.
  /--------------------------------------------------------------------------*/

  %local return m n curr_name anylib is_bad len nchar dot_pos;


  /*
  / PARAMETER VALIDATION
  /--------------------------------------------------------------------------*/

  %let return = ;
  %let namesin = %upcase(%nrbquote(&namesin));
  %let nametype = %upcase(%nrbquote(&nametype));


  /*
  / Check that NAMESIN is not blank.
  /--------------------------------------------------------------------------*/

  %if &namesin eq %then
  %do;
    %put %str(RTE)RROR: TU_CHKNAMES: NAMESIN is a required parameter;
    %let g_abort = 1;
    %let return = -1;
  %end;


  /*
  / Check NAMESIN does not contains single or double quotes or commas.
  /--------------------------------------------------------------------------*/

  %if %index(&namesin, %str(,)) or
      %index(&namesin, %str(%')) or
      %index(&namesin, %str(%")) %then
  %do;
    %put %str(RTE)RROR: TU_CHKNAMES: Invalid character (%str(, %' or %")) is found in NAMESIN(=&namesin);
    %let g_abort = 1;
    %let return = -1;
  %end;


  /*
  /  Check that the NAMETYPE value is in the list of valid values.
  /--------------------------------------------------------------------------*/

  %if &nametype ne DATA and &nametype ne VARIABLE %then
  %do;
    %put %str(RTE)RROR: TU_CHKNAMES: Value of NAMETYPE(=&nametype) is invalid. Valid values should be DATA or VARIABLE;
    %let g_abort = 1;
    %let return = -1;
  %end;


  /*
  / NORMAL PROCESSING
  /
  / If parameter validation is successful the following processing will occur:
  /--------------------------------------------------------------------------*/



  %if &return eq %then
  %do;

    /*
    / Extract each name in turn from NAMESIN
    /------------------------------------------------------------------------*/


    %let m = 1;
    %let curr_name = %nrbquote(%scan(&namesin, 1, %str( )));

    %do %while ( &curr_name ne );

      %let anylib = ;
      %let is_bad = 0;

      /*
      / If the NAMETYPE is data then separate any libref specified from the
      / dataset name specified.
      /----------------------------------------------------------------------*/

      %if &nametype eq DATA %then
      %do;

        %let dot_pos = %index(&curr_name, .);

        %if &dot_pos %then
        %do;
          %let anylib = %nrbquote(%substr(&curr_name, 1, &dot_pos - 1));
          %let curr_name = %nrbquote(%substr(&curr_name, &dot_pos + 1));
        %end;

      %end; /* %if &nametype eq DATA %then */


      /*
      / Check the following rules that apply to DATAset names (not including
      / any libref) and VARIABLE names:
      /----------------------------------------------------------------------*/

      /*
      / The length of the name is less than or equal to 32 chars.
      /  -> Note that this assumes we are not dealing with generation
      /     datasets (those with generation sequence identification)
      /----------------------------------------------------------------------*/

      %if %length(&curr_name) gt 32 %then
      %do;
        %put %str(RTE)RROR: TU_CHKNAMES: Length of name (%qupcase(&curr_name)) given in NAMESIN 
             is greater than 32 characters;
        %let g_abort = 1;
        %let is_bad = 1;
      %end;


      /*
      / The first character must be a letter (A, B, C, . . ., Z) or underscore
      / (_).
      /
      / Special characters, except for the underscore, must not exist
      /----------------------------------------------------------------------*/

      %let len = %length(&curr_name);
      %let n = 1;

      %do n = 1 %to &len;
        %let nchar = %nrbquote(%substr(&curr_name, &n, 1));
        %if not ((A le &nchar and &nchar le Z) or
                 (&nchar eq _) or
                 (0 le &nchar and &nchar le 9 and &n ne 1)) %then
        %do;
          %put %str(RTE)RROR: TU_CHKNAMES: special character (&nchar) found in name (&curr_name),
               which is given in NAMESIN;
          %let g_abort = 1;
          %let is_bad = 1;
        %end;
      %end; /* %do n = 1 %to &len; */


      /*
      / If the NAMETYPE is DATA, check the following rules:
      /  -> the name is not _NULL_, _DATA_, or _LAST_
      /----------------------------------------------------------------------*/

      %if &nametype eq DATA %then
      %do;
        %if &curr_name eq _NULL_ or
            &curr_name eq _DATA_ or
            &curr_name eq _LAST_ %then
        %do;
          %put %str(RTE)RROR: TU_CHKNAMES: Dataset name (&curr_name), which is given in NAMESIN, 
               is a reserved SAS data set name;
          %let g_abort = 1;
          %let is_bad = 1;
        %end;
      %end; /* %if &nametype eq DATA %then */


      /*
      / If the NAMETYPE is VARIABLE, check the following rules:
      /  -> the name is not a special SAS automatic variable (such as _N_
      /     and _ERROR_) or variable list names (such as _NUMERIC_,
      /     _CHARACTER_, and _ALL_)
      /----------------------------------------------------------------------*/

      %if &nametype eq VARIABLE %then
      %do;

        %if &curr_name eq _N_ or
            &curr_name eq _ERROR_ or
            &curr_name eq _ALL_ or
            &curr_name eq _NUMERIC_ or
            &curr_name eq _CHARACTER_ %then
        %do;
          %put %str(RTE)RROR: TU_CHKNAMES:  Variable name (%qupcase(&curr_name)) given 
               in NAMESIN is a SAS automatic variable or a variable list name.;
          %let g_abort = 1;
          %let is_bad = 1;
        %end;

      %end; /* %if &nametype eq VARIABLE %then */


      /*
      / If the NAMETYPE is DATA, check the following rules for each libref
      / identified in the earlier step:
      /  -> The length of the libref is less than or equal to 8 chars.
      /  -> The first character must be a letter (A, B, C, . . ., Z) or
      /     underscore (_).
      /  -> Special characters, except for the underscore, must not exist
      /----------------------------------------------------------------------*/

      %if &nametype eq DATA and &anylib ne %then
      %do;

        %let len = %length(&anylib);

        %if &len gt 8 %then
        %do;
          %put %str(RTE)RROR: TU_CHKNAMES: Length of libref (%qupcase(&anylib)) given 
               in NAMESIN is greater than 8 characters;
          %let g_abort = 1;
          %let is_bad = 1;
        %end;

        %let n = 1;

        %do n = 1 %to &len;
          %let nchar = %nrbquote(%substr(&anylib, &n, 1));
          %if not ((A le &nchar and &nchar le Z) or
                   (&nchar eq _) or
                   (0 le &nchar and &nchar le 9 and &n ne 1)) %then
          %do;
            %put %str(RTE)RROR: TU_CHKNAMES: Invalid character (%nrbquote(&nchar)) is found in libref (&anylib),
                 which is given in NAMESIN;
            %let g_abort = 1;
            %let is_bad = 1;
          %end;
        %end; /* %do n = 1 %to &len; */

      %end; /* %if &nametype eq DATA and &anylib ne %then */


      /*
      / If a name or libref does not comply with any of the above rules then
      / append the name to a list for outputting from the function.
      /----------------------------------------------------------------------*/

      %if &is_bad %then
      %do;

        %if &anylib eq %then
        %do;
          %let return = &return &curr_name;
        %end;
        %else
        %do;
          %let return = &return &anylib..&curr_name;
        %end;

      %end; /* %if &is_bad %then */


      /*
      / Find the next word specified in NAMESIN, and assign this value to
      / CURR_NAME.
      /----------------------------------------------------------------------*/

      %let m = %eval(&m + 1);
      %let curr_name = %nrbquote(%scan(&namesin, &m, %str( )));

    %end; /* %do %while ( &curr_name ne ); */

  %end; /* %if &return eq %then */


  /*
  / Return an empty string if all names are valid.
  / If a problem was detected during parameter validation, then the value of
  / RETURN would have been set to -1, and normal processing would not have
  / occurred.
  / If no problems were detected during normal processing, then the value of
  / RETURN would have been unaltered, ie still blank.
  / If an invalid name was detected during normal processing, then it would
  / have been appended to RETURN, so that by the end of normal processing,
  / the value of RETURN would be a list of all the variable names where a
  / problem was detected.
  /--------------------------------------------------------------------------*/

  &return


%mend tu_chknames;
