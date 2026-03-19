/******************************************************************************* 
|
| Macro Name:      tu_cr8macarray.sas
|
| Macro Version:   1
|
| SAS Version:     8.2
|
| Created By:      Andrew Ratcliffe, RTSL
|
| Date:            13-Dec-2004
|
| Macro Purpose:   To create an array of global or local macro variables with 
|                  the specified number of elements. The array shall contain 
|                  words from the specified input string. If there are 
|                  insufficient words in the input string to fill the array, 
|                  the macro shall repeat the last word as many times as are 
|                  necessary. However, if the specified end sign has been 
|                  supplied as a word, the remainder of the array shall be 
|                  populated with blank values. If too many words are supplied, 
|                  the extraneous words shall be ignored.
|
| Macro Design:    CALL ROUTINE
| 
| Input Parameters:
|
| NAME              DESCRIPTION                                     DEFAULT 
|   REQUIRED
| prefix            Prefix of names of output macro variables       [blank]
| numElements       Number of array elements to be created          [blank]
| delim             Word delimeter used in string                   %str( )
| endSign           End sign optionally used in string              [end]
| scope             Scope of array elements (local or global)       local
|   OPTIONAL
| string            Text to be split into words for array elements  [blank]
|
| Output: Array of macro variables
|
| Global macro variables created:  None (unless specified by user)
|
| Macros called:
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_chknames
| (@) tu_putglobals
| (@) tu_tidyup
| (@) tu_words
|
| Examples:
|    1) Repeat the last value to pad the array
|         string = red black                                  
|         prefix = symColor                                   
|         numElements = 4                                   
|       produces:                                               
|         symColor1 = red                                     
|         symColor2 = black                                   
|         symColor3 = black                                   
|         symColor4 = black                                   
|                                                            
|    2) Use the end sign to pad the array with blanks
|         string = red black black [end]                      
|         prefix = symColor                                   
|         numElements = 5                                   
|       produces:                                               
|         symColor1 = red                                     
|         symColor2 = black                                   
|         symColor3 = black                                   
|         symColor4 =                                         
|         symColor5 =           
|
|******************************************************************************* 
| Change Log 
|
| Modified By:             Trevor Welby                   
| Date of Modification:    27-Apr-05
| New version number:      01.002
| Modification ID:         TQW9753.01.002
| Reason For Modification: 
|                          Expand the validation section to include checks for 
|                          blank values of PREFIX and NUMELEMENTS parameters
|
|                          When scope=local or scope=global the code block is now 
|                          conditionally executed when PREFIX is non-blank
|
|                          When scope=local the code block is now conditionally 
|                          executed when NUMELEMENTS is non-blank
|
|                          The WHERE clause in the datasteps for scope=local or 
|                          scope=global has now been augmented to include 
|                          "upcase(name) ne upcase("&prefix")"
|
|                          The datastep in scope=local has been changed to  
|                          compute the correct value for variable named 
|                          "failedVars"
|
|******************************************************************************* 
|
| Modified By:             Trevor Welby            
| Date of Modification:    17-May-05
| New version number:      01.003
| Modification ID:         TQW9753.01.003
| Reason For Modification: PREFIX parameter validation enhancement  
|
|******************************************************************************* 
|
| Modified By:               
| Date of Modification:       
| New version number:        
| Modification ID:           
| Reason For Modification:   
|
********************************************************************************/ 
%macro tu_cr8macarray(string      =         /* Text to be split into words for array elements */
                     ,prefix      =         /* Prefix of names of output macro variables      */
                     ,numElements =         /* Number of array elements to be created         */
                     ,delim       = %str( ) /* Word delimeter used in string                  */
                     ,endSign     = [end]   /* End sign optionally used in string             */
                     ,scope       = local   /* Scope of array elements (local or global)      */
                     );

  /* Echo parameter values and global macro variables to the log */

  %local MacroVersion;
  %let MacroVersion = 1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals();

  %local tempdsPrefix;
  %let tempdsPrefix = %substr(&sysmacroname,3); 

  %let endSign = %upcase(&endSign);
  %let scope   = %upcase(&scope);

  /* PARAMETER VALIDATION */

  %if %length(&prefix.) eq 0 %then
  %do;  /* Prefix is blank [TQW9753.01-002] */
    %put RTE%str(RROR): &sysmacroname: The PREFIX parameter (&prefix) must not be blank;
    %let g_abort = 1;
  %end; /* Prefix is blank [TQW9753.01-002] */
  %else
  %do; /* Prefix is non-blank [TQW9753.01-002], [TQW9753.01.003] */
    %if %tu_words(&prefix.,delim=%str( )) GT 1 or %length(%tu_chknames(&prefix.,VARIABLE)) GT 0 %then
    %do;  /* Prefix is not a valid variable name */
      %put RTE%str(RROR): &sysmacroname: The PREFIX parameter (&prefix) is not a valid prefix for macro variable names;
      %let g_abort = 1;
    %end; /* Prefix is not a valid variable name */
  %end; /* Prefix is non-blank TQW9753.01-002] */

  %if %length(&numelements.) eq 0 %then
  %do;  /* numElements is blank [TQW9753.01-002] */
    %put RTE%str(RROR): &sysmacroname: The NUMELEMENTS parameter (&numelements.) must not be blank;
    %let g_abort = 1;
  %end; /* numElements is blank [TQW9753.01-002] */
  %else
  %do; /* numElements is non-blank [TQW9753.01-002] */
    %if %datatyp(&numElements) ne NUMERIC %then
    %do; /* is not numeric */
      %put RTE%str(RROR): &sysmacroname: The NUMELEMENTS parameter (&numElements) is not a valid numeric value;
      %let g_abort = 1;
    %end; /* is not numeric */
    %else
    %do;  /* is numeric */
      %if &numElements le 0 %then
      %do; /* is not a great than zero */
        %put RTE%str(RROR): &sysmacroname: The NUMELEMENTS parameter (&numElements) must be greater than zero;
        %let g_abort = 1;
      %end; /* is not a great than zero */
      %else
      %do;  /* is greater than zero */ 
        %if %sysfunc(int(&numElements)) ne &numElements %then
        %do;  /* is not an interger */
          %put RTE%str(RROR): &sysmacroname: The NUMELEMENTS parameter (&numElements) must be an integer;
          %let g_abort = 1;
        %end;  /* is not an interger */
      %end; /* is greater than zero */ 
    %end;  /* is numeric */
  %end;  /* numElements is non-blank [TQW9753.01-002] */

  %if %length(&delim) eq 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname: The DELIM parameter is required and must not be blank;
    %let g_abort = 1;
  %end;

  %if %length(&endSign) eq 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname: The ENDSIGN parameter is required and must not be blank;
    %let g_abort = 1;
  %end;

  %if &scope ne LOCAL and &scope ne GLOBAL %then
  %do;
    %put RTE%str(RROR): &sysmacroname: The SCOPE parameter value (&scope) is invalid - it must be LOCAL or GLOBAL;
    %let g_abort = 1;
  %end;

  %if %length(&prefix.) ne 0 %then
  %do;  /* Non blank PREFIX [TQW9753.01.002] */
    %if (&scope eq LOCAL) and %length(&numelements.) ne 0 %then
    %do;  /* scope=local */

      /*
      / If scope is local, all array elements must have been 
      / declared already, else they will just be local to    
      / this macro and will be destroyed when it terminates! 
      /------------------------------------------------------*/
   
      %local failed failedvars;
      %let failed = 1;
      %let failedvars = all;
      data _null_; *[TQW9753.01.002];
        set sashelp.vmacro (where=(scope ne 'AUTOMATIC' and
                                   upcase(name) eq: upcase("&prefix") and
                                   upcase(name) ne  upcase("&prefix") and
                                   upcase(name) ne  upcase("prefix") 
                                   ) *[TQW9753.01-002];
                           )
                           end=finish
                           ;

        array search(&numelements) $32 (
                                        %do i = 1 %to &numElements;
                                          "%upcase(&prefix.&i)"
                                        %end;
                                       );

        array found(&numelements) 8;

        length failedVars $400;

        retain search found;

        do i = 1 to dim(search);
          if upcase(name) eq search(i) then found(i) = 1;
        end;

        if finish then do;  /* EOF */
          if sum(of found1-found&numelements.) ne &numelements. then
          do; /* Variables not declared */
            do i = 1 to dim(search);  /* Build string of undeclared variables */
              if found(i) = . then failedVars = trim(failedVars) !! ' ' !! search(i);
            end;  /* Build string of undeclared variables */
            call symput('FAILED','1');
            call symput('FAILEDVARS',left(failedVars));
          end;  /* Variables not declared */
          else
          do; /* Variables declared */
            call symput('FAILED','0');
          end;  /* Variables declared */
        end;  /* EOF */

      run;

      %if &failed %then
      %do;
        %put RTE%str(RROR): &sysmacroname: The following macro variables have not been declared despite setting SCOPE=LOCAL:;
        %put RTE%str(RROR): &sysmacroname: Macro variable(s) not declared: &failedVars;
        %let g_abort=1;
      %end;

    %end; /* scope=local */

    %if (&scope eq GLOBAL) %then
    %do;  /* scope=global */

      /*
      / If scope is global, no array elements can have been 
      / declared as local already, else SAS will throw an error
      / when we declare it as global! 
      /------------------------------------------------------*/
      %local failed failedVars;
      %let failed = 0;
      data _null_;
        set sashelp.vmacro(where = (scope ne 'GLOBAL' and 
                                    upcase(name) eq: upcase("&prefix") and
                                    upcase(name) ne  upcase("&prefix") and
                                    upcase(name) ne  upcase("prefix")
                                    ) *[TQW9753.01-002];

                           )
                           end=finish
                           ;
        length failedVars $400;
        retain failedVars;
        failedVars = trim(failedVars) !! ' ' !! name;
        if finish then
        do;
          call symput('FAILED','1');
          call symput('FAILEDVARS',left(failedVars));
        end;
      run;

      %if &failed %then
      %do;
        %put RTE%str(RROR): &sysmacroname: The following macro variables have already been declared as local despite setting SCOPE=GLOBAL:;
        %put RTE%str(RROR): &sysmacroname: Macro variable(s) already declared: &failedVars;
        %let g_abort=1;
      %end;

    %end; /* scope=global */

  %end; /* Non blank PREFIX [TQW9753.01.002] */

  %tu_abort;

  /* NORMAL PROCESSING */

  %local i this lastNonBlank;

  %let lastNonBlank = ;
  %do i = 1 %to &numElements;
    %if &scope eq GLOBAL %then
    %do;
      %global &prefix&i;
    %end;
    %if %nrbquote(%upcase(&lastNonBlank)) eq &endsign %then
    %do;
      %let &prefix&i = ;
    %end;
    %else
    %do;  /* Have not seen end sign yet */
      %let this = %scan(&string,&i,&delim);
      %if %nrbquote(%upcase(&this)) eq &endsign %then
      %do;
        %let &prefix&i = ;
        %let lastNonBlank = &this;
      %end;
      %else
      %do;  /* Not end sign */
        %if %length(&this) eq 0 %then
        %do;
          %let &prefix&i = &lastNonBlank;
        %end;
        %else
        %do;
          %let &prefix&i = &this;
          %let lastNonBlank = &this;
        %end;
      %end; /* Not end sign */
    %end; /* Have not seen end sign yet */
  %end;     

  %if &g_debug ge 1 %then
  %do i = 1 %to &numElements;
    %put RTD%str(EBUG): &sysmacroname: %upcase(&prefix)&i=&&&prefix&i;
  %end;

  /* Finish */
  
  %tu_tidyup(rmdset=&tempdsPrefix:
            ,glbmac=NONE);
  quit;

  %tu_abort;

%mend tu_cr8macarray;
