/*--------------------------------------------------------------------------+
| Macro Name    : tu_footer.sas
|
| Macro Version : 2
|
| SAS version   : SAS v8.2
|
| Created By    : Shan Lee
|
| Date          : 22-May-2003
|
| Macro Purpose : To generate the footnote statements required to produce a
|                 footer for the data display, and to generate a dataset
|                 storing information regarding which variables numbered
|                 footnotes refer to.
|
| Macro Design  : Procedure style
|
| Input Parameters :
|
| NAME           DESCRIPTION                              REQ/OPT   DEFAULT
|
| DSETOUT        Name of dataset that will be generated   Req
|                by this macro to store information
|                required to link variables in the data
|                display dataset with footnote references.
|
| CELLINDX       Specify whether footnotes need to be     Req       N
|                generated for table/listing, or for cell
|                index.
|
|
|
| Output:
|
| The unit shall generate the SAS footnote statements required to create the
| footer. A dataset will also be generated, so that %TU_DISPLAY will be able
| to link variables in the data display dataset with numbered footnote
| references. If there are no numbered footnote references, then this dataset
| will have zero observations.
|
| Global macro variables created: G_FOOTER0
|
|
| Macros called :
|  (@)tr_putlocals
|  (@)tu_putglobals
|  (@)tu_abort
|  (@)tu_chknames
|
|
| Example:
| %tu_footer(cellindx = Y)
|
|
| **************************************************************************
| Change Log :
|
| Modified By :             Shan Lee
| Date of Modification :    01 Aug 2003
| New Version Number :      1/2
| Modification ID :         SL001
| Reason For Modification : Incorporate comments from first iteration of
|                           unit testing - format of date in last footer line
|                           was amended.
|
| Modified By :             Andrew Ratcliffe
| Date of Modification :    06 Aug 2003
| New Version Number :      1.0 / 003
| Modification ID :         ABR01
| Reason For Modification : Use automatic macro variable SYSUSERID to get
|                            userid instead of using sysget of USERID.
|
| Modified By :             Shan Lee
| Date of Modification :    08 Oct 2003
| New Version Number :      1/4
| Modification ID :         SL002
| Reason For Modification : Use G_USERID to obtain user name, rather than
|                           obtaining the UNIX user name.
|
| Modified By :             Shan Lee
| Date of Modification :    17 Oct 2003
| New Version Number :      1/5
| Modification ID :         SL003
| Reason For Modification : Previously, formatting was applied to footnote
|                           text whilst the footnote statement was being
|                           generated, in order to implement left
|                           justification of footnote. Now, this formatting
|                           is applied within the datastep, so that the
|                           formatted value is written directly to a macro
|                           variable which can later be quoted using %superq, to
|                           prevent the macro processor from ever attempting
|                           to resolve the formatted value (if it did attempt
|                           to resolve the formatted value, then there would
|                           be a warning if the footnote included ampersands
|                           that did not correspond to macro variable
|                           references.
|                           Note that this modification also fixes a problem
|                           detected during UAT, when a comma is specified as
|                           part of a footnote. It also means that any user-
|                           specified ampersand or percentage sign in a
|                           footnote will always be displayed literally, and
|                           will have no meaning to the macro processor.
|
| Modified By :             John King
| Date of Modification :    02 Nov 2004
| New Version Number :      2/1
| Modification ID :         JK001
| Reason For Modification :
| Reason For Modification : Incorporate amendments specified in change
|                           control form HRT0052 - use SAS/GRAPH footnote
|                           statement options to LEFT justify all footnotes 
|                           when G_DSPLYTYP=F.
|
+----------------------------------------------------------------------------*/
%MACRO tu_footer(
  dsetout = ,  /* Name of dataset to link variables with footnote references */
  cellindx = N  /* Footer generated for cell index? */
      );
/*
/ Echo parameter values and global macro variables to the log.
/----------------------------------------------------------------------------*/
%local MacroVersion;
%let MacroVersion = 2;
%include "&g_refdata/tr_putlocals.sas";
%tu_putglobals(varsin=g_foot1 g_foot2 g_foot3 g_foot4 g_foot5 g_foot6
                      g_foot7 g_foot8 g_foot9 g_pgmpth g_ls);
/*
/ PARAMETER VALIDATION
/----------------------------------------------------------------------------*/
%let dsetout = %nrbquote(&dsetout);
%let cellindx = %nrbquote(%upcase(%substr(&cellindx, 1, 1)));
/*
/ Check that CELLINDX is "Y" or "N".
/----------------------------------------------------------------------------*/
%if &cellindx ne Y and &cellindx ne N %then
%do;
  %put %str(RTE)RROR: TU_FOOTER: CELLINDX should be either Y or N;
  %tu_abort(option = FORCE)
%end;
/*
/ Check that DSETOUT is not blank.
/----------------------------------------------------------------------------*/
%if &dsetout eq %then
%do;
  %put %str(RTE)RROR: TU_FOOTER: DSETOUT parameter is required;
  %tu_abort(option = FORCE)
%end;
/*
/ Use %tu_chknames to check that DSETOUT corresponds to a valid SAS name.
/----------------------------------------------------------------------------*/
%if %tu_chknames(&dsetout, DATA) ne %then
%do;
  %put %str(RTE)RROR: TU_FOOTER: DSETOUT parameter should correspond to a valid SAS dataset name;
  %tu_abort(option = FORCE)
%end;
/*
/ Check that G_PGMPTH is not missing.
/----------------------------------------------------------------------------*/
%if %nrbquote(&g_pgmpth) eq %then
%do;
  %put %str(RTE)RROR: TU_FOOTER: G_PGMPTH should correspond to the name and path of the driver program;
  %tu_abort(option = FORCE)
%end;
/*
/ NORMAL PROCESSING
/----------------------------------------------------------------------------*/
/*
/ Declare local macro variables that are used in this macro (not including
/ parameter values.
/
/ The local macro variables L_FOOT1, L_FOOT2 etc will be equivalent to the
/ global macro variables G_FOOT1, G_FOOT2 etc, except, that if the footnote
/ begins with a reference number, then the dataset variable name will be
/ removed from L_FOOT1, L_FOOT2 etc.
/----------------------------------------------------------------------------*/
%local l_foot1 l_foot2 l_foot3 l_foot4 l_foot5 l_foot6 l_foot7 l_foot8 l_foot9
       lastfoot n j;
%local justify; /* JK001 */       
/*
/ Declare global macro variables that are created by this macro.
/
/ The final value of G_FOOTER0, when this macro has finished executing will be
/ the position of the last non-missing footnote number.
/ Until the end of this macro, G_FOOTER0, will be used to store the position
/ of the next available footnote, ie the number of the footnote after the last
/ non-missing footnote statement that has so far been generated during macro
/ excution.
/ At the end of this macro, the footnote indicating the program name and
/ location etc will be generated at this position.
/----------------------------------------------------------------------------*/
%global g_footer0;
%let g_footer0 = 1;
/*
/ Begin datastep with statement: DATA &DSETOUT (KEEP = REFNUM NAME);
/
/ The dataset &DSETOUT will always be generated by this macro. If there are
/ no numbered footnote references, then the dataset will have zero
/ observations. Note that if this macro is being called for a cell index,
/ then only the footnote indicating the program name and path will be
/ generated, so there will be no numbered footnote references, and the output
/ dataset will therefore have zero observations.
/----------------------------------------------------------------------------*/
data &dsetout (keep = refnum name);
  /*
  / Declare all variables used in the datastep with a length statement, and
  / follow the length statement with assignment statements that initialise all
  / the variables to missing. The purpose of doing this is to prevent
  / "uninitialised variables" messages appearing in the log if the output
  / dataset has zero observations.
  /
  / The dataset variables NAME and REFNUM will be created for the output
  / dataset that is generated by this macro. Other variables will be used
  / during the datastep, but will not appear in the output dataset.
  /--------------------------------------------------------------------------*/
  length name $32 refnum $5 l_foot1-l_foot9 first_word $&g_ls;
  name = '';
  refnum = '';
  l_foot1 = '';
  l_foot2 = '';
  l_foot3 = '';
  l_foot4 = '';
  l_foot5 = '';
  l_foot6 = '';
  l_foot7 = '';
  l_foot8 = '';
  l_foot9 = '';
  first_word = '';
  %if &cellindx eq N %then %do;
    /*
    / If this macro is not being called for a cell index, then -
    /
    / Loop through each of the global macro variable G_FOOT1 to G_FOOT9 in
    / ascending order. If the global macro variable has a non-missing value,
    / then do the following:
    /
    /  Store the value of the footnote text in the corresponding L_FOOT<n>
    /  local macro variable.
    /
    /  If the value of the global macro variable begins with a number in
    /  square brackets, then do not include the dataset variable name in the
    /  footnote text, but instead generate additional datastep code to
    /  store this variable name and footnote reference number in NAME and
    /  REFNUM respectively. Please note that the values assigned to NAME
    /  should be in uppercase. Please also note that the square brackets, as
    /  well as the actual reference number, should be included in the text
    /  that is written to REFNUM, so REFNUM will take the values "[1]", "[2]",
    /  "[3]" etc.
    /
    / If a particular footnote has not been specified by the user, then
    / do not need to determine whether or not the footnote refers to a
    / specific column in the data display.
    /------------------------------------------------------------------------*/
    %do n = 1 %to 9;
      %if %nrbquote(&&g_foot&n) ne %then
      %do;
        /*
        / Examine first word of footnote&n.
        /--------------------------------------------------------------------*/
        first_word = left(scan("&&g_foot&n", 1, " "));
        word_length = length(first_word);
        /*
        / Start off by asserting that the footnote starts with a reference
        / number, and then attempt to disprove this assertion.
        /--------------------------------------------------------------------*/
        is_refnum = 1;
        if substr(first_word, 1, 1) ne "[" then is_refnum = 0;
        if word_length lt 3 then is_refnum = 0;
        do j = 2 to (word_length - 1);
          if indexc(substr(first_word, j, 1), "0123456789") eq 0 then is_refnum = 0;
        end;
        if substr(first_word, word_length, 1) ne "]" then is_refnum = 0;
        if is_refnum then
        do;
          /*
          / Footnote does start with a reference number, therefore need to
          / generate an observation to indicate link between reference number
          / and variable. Also, need to remove name of variable that footnote
          / refers to from the text of the actual footnote.
          / Formatting is applied during CALL SYMPUT, to implement left
          / justification.
          /------------------------------------------------------------------*/
          refnum = first_word;
          name = scan("&&g_foot&n", 2, " ");
          start_rest = indexw("&&g_foot&n", trim(left(name))) + length(name);
          l_foot&n = trim(left(refnum)) || substr("&&g_foot&n", start_rest);
          
         /*
         / JK001
         / If G_DSPLYTYP is F (figure) then do not pad footnote with blanks
         /------------------------------------------------------------------*/                                       
          %if %quote(&g_dsplytyp) eq F %then 
          %do;
            call symput("l_foot&n", trim(l_foot&n));
          %end;
          
          %else /* JHK001 This else do is the original code */
          %do;
            call symput("l_foot&n", put(trim(l_foot&n), $&g_ls..));   /* SL003 */
          %end;  
          name = upcase(name);
          output;
        end; /* if is_refnum then */
        else
        do;
          /*
          / Footnote does not start with a reference number, therefore do not
          / need to generate an observation to indicate link between reference
          / number and variable. Also, text for footnote is exactly the same
          / as the text specified by the user.
          / Formatting is applied during CALL SYMPUT, to implement left
          / justification.
          /------------------------------------------------------------------*/
         
         /*
         / JK001
         / If G_DSPLYTYP is F (figure) then do not pad footnote with blanks
         /------------------------------------------------------------------*/                                       
          %if %quote(&g_dsplytyp) eq F %then 
          %do;
            call symput("l_foot&n", trim("&&g_foot&n"));
          %end;
          
          %else /* JHK001 This else do is the original code */
          %do;
             call symput("l_foot&n", put(trim(left("&&g_foot&n")), $&g_ls..)); /* SL003 */
          %end;  
        end; /* else */
      %end; /* %if %nrbquote(&&g_foot&n) ne %then */
      %else
      %do;
        /*
        / Footnote currently under consideration has not been specified by the
        / user, so do not need to determine whether or not the footnote refers
        / to a specific column in the data display.
        /--------------------------------------------------------------------*/
        %let l_foot&n = ;
      %end; /* %else */
    %end; /* %do n = 1 %to 9 */
  %end; /* %if &cellindx eq N %then %do; */
  /*
  / The current datastep does not have an input dataset. Therefore, need the
  / stop statement to prevent the datastep from looping.
  /--------------------------------------------------------------------------*/
  stop;
/*
/ End of datastep to generate output dataset.
/----------------------------------------------------------------------------*/
run; /* data &dsetout (keep = refnum name); */
/*
/ Issue a "footnote1" statement to clear any pre-existing footnotes.
/----------------------------------------------------------------------------*/
footnote1;
/*
/ Generate footnote statements for all footnotes prior to the footnote that
/ indicates the program name and path. Note that this section of code only
/ only needs to be executed if the macro is not being run for a cell index.
/----------------------------------------------------------------------------*/
%if &cellindx eq N %then %do;
  /*
  / The SUPERQ macro quoting function is used, so that if a footnote includes
  / ampersands or percentage signs, the macro processor will not attempt to
  / resolve macro variable references or execute macros, thus preventing
  / warning messages that would have appeared if "&" or "%" was used literally,
  / and NRBQUOTE was used instead of SUPERQ.
  / Note that this means that users cannot specify actual macros calls or
  / macro variables as part of footnotes.
  / The following code cannot be implemented in a macro DO ... WHILE loop,
  / because the argument to SUPERQ cannot be of the form "&&l_foot&n". SL003
  /--------------------------------------------------------------------------*/
   /*
   / JK001
   / If G_DSPLYTYP is F (figure) then assign local macro variable JUSTIFY
   /-----------------------------------------------------------------------------*/ 
   %if %quote(&g_dsplytyp) eq F %then %let justify = J=LEFT;
            
  %if %superq(l_foot1) ne %then
  %do;
    footnote1 &justify "%superq(l_foot1)";
    %let g_footer0 = 2;
  %end;
  %if %superq(l_foot2) ne %then
  %do;
    footnote2 &justify "%superq(l_foot2)";
    %let g_footer0 = 3;
  %end;
  %if %superq(l_foot3) ne %then
  %do;
    footnote3 &justify "%superq(l_foot3)";
    %let g_footer0 = 4;
  %end;
  %if %superq(l_foot4) ne %then
  %do;
    footnote4 &justify "%superq(l_foot4)";
    %let g_footer0 = 5;
  %end;
  %if %superq(l_foot5) ne %then
  %do;
    footnote5 &justify "%superq(l_foot5)";
    %let g_footer0 = 6;
  %end;
  %if %superq(l_foot6) ne %then
  %do;
    footnote6 &justify "%superq(l_foot6)";
    %let g_footer0 = 7;
  %end;
  %if %superq(l_foot7) ne %then
  %do;
    footnote7 &justify "%superq(l_foot7)";
    %let g_footer0 = 8;
  %end;
  %if %superq(l_foot8) ne %then
  %do;
    footnote8 &justify "%superq(l_foot8)";
    %let g_footer0 = 9;
  %end;
  %if %superq(l_foot9) ne %then
  %do;
    footnote9 &justify "%superq(l_foot9)";
    %let g_footer0 = 10;
  %end;
%end; /* %if &cellindx eq N %then %do; */
/*
/ Generate a footnote statement at the position given by &g_footer0, to
/ indicate the program name and path (obtained from &g_pgmpth) and
/ date/time (obtained from SAS automatic macro variables).
/----------------------------------------------------------------------------*/
%let lastfoot = %unquote(&g_userid): &g_pgmpth &sysdate9 &systime;  /* ABR01 */ /* SL002 */
/*
/ JK001
/ If G_DSPLYTYP is F (figure) then do not pad footnote with blanks
/------------------------------------------------------------------*/                                       
%if %quote(&g_dsplytyp) eq F %then 
%do;
   footnote&g_footer0 J=LEFT "&lastfoot";
%end;
%else /* JHK001 This else do is the original code */
%do;          
   footnote&g_footer0 "%sysfunc(putc(&lastfoot, $&g_ls..))";
%end;
/*
/ Call %tu_abort().
/----------------------------------------------------------------------------*/
%tu_abort
%MEND tu_footer;
