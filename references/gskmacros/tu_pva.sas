/*
/
/ Macro Name: tu_pva
/
/ Macro Version: 5
/
/ SAS Version: 8
/
/ Created By: John Henry King
/
/ Date: 05/20/2003
/
/ Macro Purpose: Macro to parse variable attribute parameters and create a
/                SAS data set.
/
/ Macro Design: Procedure style.
/
/ Input Parameters:
/
/ NAME                    DESCRIPTION                                          DEFAULT
/ ----------------------- ---------------------------------------------------- ----------
/ DSETIN                  Specifies the name of the input data set.            No default
/
/ DSETOUT                 Specifies the name of the output data set.           work.metadata
/
/ COLUMNS                 A PROC REPORT column statement specification.        No default
/                         Including spanning titles and variable names.
/
/ ORDERVARS               List of variables that will receive the PROC REPORT  No default
/                         define statement attribute ORDER.
/
/ SHARCOLVARS             List of variables that will share print space. The   No default
/                         attributes of the last variable in the list define
/                         the column width and flow options.
/
/ SHARCOLVARSINDENT       Indentation factor for SHARCOLVARS.                  2
/
/ OVERALLSUMMARY          Causes the macro to produce an overall summary line. NO
/                         Use with sharecolvars.
/
/ LINEVARS                List of order variables that are printed with LINE   No default
/                         statements in PROC REPORT.
/
/ DESCENDING              List of ORDERVARS that are given the PROC REPORT     No default
/                         define statement attribute DESCENDING.
/
/ ORDERVARSDISPLAY        Variables listed in the ORDERVARS parameter which    No default
/                         are to be given the PROC REPORT define statement
/                         attributes order and display. Normally ORDERVARS
/                         values are displayed once each time their value
/                         changes. To display an ORDERVARS value on each
/                         observation, list the variable in the
/                         ORDERVARSDISPLAY parameter.
/
/ ORDERFORMATTED          Variables listed in the ORDERVARS parameter that     No default
/                         are given the PROC REPORT define statement attribute
/                         order=formatted. Variables not listedin ORDERFORMATTED,
/                         ORDERFREQ, or ORDERDATA are given the define attribute
/                         order=internal.
/ ORDERFREQ               Variables listed in the ORDERVARS parameter that     No default
/                         are given the PROC REPORT define statement attribute
/                         order=freq. Variables not listed in ORDERFORMATTED,
/                         ORDERFREQ, or ORDERDATA are given the define
/                         attribute order=internal.
/
/ ORDERDATA               Variables listed in the ORDERVARS parameter that     No default
/                         are given the PROC REPORT define statement attribute
/                         order=data. Variables not listed in ORDERFORMATTED,
/                         ORDERFREQ, or ORDERDATA are given the define
/                         attribute order=internal.
/
/ NOPRINTVARS             Variables listed in the COLUMN parameter that are    No default
/                         given the PROC REPORT define statement attribute
/                         noprint.  These variables are usually ORDERVARS
/                         used to control the order of the rows in the display.
/
/ BYVARS                  The variables listed here are processed              No default
/                         as standard SAS by variables.  No formatting of the display
/                         for these varaibles is prerformed by %tu_DISPLAY.
/                         The user has the option of the standard SAS BY line, or
/                         using OPTIONS NOBYLINE and #BYVAL #BYVAR directives in title
/                         statements.
/
/ ----------------------- ---------------------------------------------------- ----------
/ ComputeBeforePageVars   Variables listed in this parameter are printed       No default
/                         between the SAS title lines and the column headers
/                         for the report.
/                         PROC REPORT code resulting from this parameter:
/
/                                define VAR1   / order noprint;
/                                define VAR2   / order noprint;
/                                .
/                                define VARn   / order noprint;
/                                break before VARn / page;
/                                compute before _page_ / left;
/                                   line VAR1 $char&g_ls..;
/                                   line VAR2 $char&g_ls..;
/                                   .
/                                   line VARn $char&g_ls..;
/                                   endcomp;
/
/                         The value of each ComputeBeforePageVar is printed
/                         as is with no additional formatting.  Do NOT
/                         include these variables in the COLUMNS parameter
/                         they will be added by the macro.  It is not nessary
/                         to list these  variables in the ORDERVARS or NOPRINTVARS
/                         parameters.  The ORDER= option for
/                         these variables is control using
/                         ORDERVARSFORMATTED, ORDERVARSFREQ, or ORDERVARSDATA
/                         parameters.
/
/ FLOWVARS                Variables to defined with the flow option.  Flow     _ALL_
/                         variables should be given a width through the WIDTHS.
/                         If a flow variable does not have a width specified
/                         the column witdth will be determined by
/                         MIN(variable's format width, width of  column header)
/
/ WIDTHS                  Variables and width to display. Display layout will  No default
/                         be optimised by default, however any specified widths
/                         will cause the default to be overridden.
/
/ DEFAULTWIDTHS           This is a list of default widths for ALL columns     No default
/                         and will usually be defined by the DD macro.
/                         This parameter specifies column widths for all variables
/                         not listed in the WIDTHS parameter.
/                         For variables that are not given widths through either
/                         the WIDTHS or DEFAULT_WIDTHS parameter will be width
/                         optimised using
/                         MAX (variable's format width, width of  column header)
/
/ SKIPVARS                Variables whose change in value causes the display   No default
/                         to skip a line.
/
/ PAGEVARS                Variables whose change in value causes the display   No default
/                         to continue on a new page.
/
/ IDVARS                  Variables to appear on each page should the report   No default
/                         be wider than 1 page. If no value is supplied to
/                         this parameter then all displayable order variables will
/                         be defined as idvars.
/
/ centreVARS              Variables to be displayed as centre justified.       No default
/                         Variables not appearing in any of the parameters CENTREVARS,
/                         LEFTVARS, or RIGHTVARS will be displayed using the
/                         PROC REPORT default. Character variables are left
/                         justified while numeric variables are right justified.
/
/ LEFTVARS                Variables to be displayed as left justified.         No default
/
/ RIGHTVARS               Variables to be displayed as right justified.        No default
/
/ COLSPACING              The value of the between column spacing.             2
/
/ VARSPACING              Spacing for individual columns. Specifies a list of  No default
/                         variables followed by a spacing value.  These values will
/                         override the overall COLSPACING parameter.
/                         VARSPACING defines the number of blank characters to
/                         leave between the column being defined and the column
/                         immediately to its left.
/
/ FORMATS                 Variables and their format for display. For use      No default
/                         where format for display differs to the format on
/                         the dsetin.
/
/ LABELS                  Variables and their label for display. For use where No default
/                         label for display differs to the label on the dsetin.
/
/ BREAK1                  Five parameters for input of user specified
/ BREAK2                  break statements.  The value of these
/ BREAK3                  paremeters are passed directly to
/ BREAK4                  PROC REPORT as:
/ BREAK5                     BREAK &break1;
/
/ PROPTIONS               Proc report statement options.  The option "Missing" No default
/                         can not be overridden.
/
/ SPLIT                   PROC REPORT split character.                         '~'
/
/ NOWIDOWVAR              Variable whose values must be kept together on       No default
/                         a page. Not in this version of the macro.
/
/
/ Output: A SAS data set that can be used to generate PROC REPORT statements.
/
/ Global macro variables created: NONE
/
/ Macros called:
/(@) tr_putlocals
/(@) tu_putglobals
/(@) tu_expvarlist
/(@) tu_unduplst
/(@) tu_chkvarsexist
/(@) tu_varattr
/(@) tu_chknames
/(@) tu_abort
/(@) tu_tidyup
/(@) tu_split
/
/
/ Example: In %tu_DISPLAY the macro is called by passing each parameter a
/          value from a %tu_DISPLAY parameter with the same name.
/
/          dsetin=&dsetin,
/          byvars=&byvars,
/          etc. etc.
/
/********************************************************************************
/ Change Log
/
/ Modified By:             John King
/ Date of Modification:    08Aug2003
/ New version number:      1/2
/ Modification ID:
/ Reason For Modification: Changes to fix 2 small problems noticed in testing.
/ -------------------------------------------------------------------------------
/ Modified By:            Paul Jarrett
/ Date of Modification:   22Oct2003
/ New version number:     1/3
/ Modification ID:        pbj:1/3
/ Reason For Modification: Remove semicolons from fly-over text.
/
/ ------------------------------------------------------------------------------
/ Modified By:             John King
/ Date of Modification:    15Jan2004
/ New version number:      2/1
/ Modification ID:         jhk:2
/ Reason For Modification:
/     1) Fix bug in sharecolvars and FLOW.  Version 1.3 dose not honor FLOWVARS
/        properly.
/        a) input variables in sharecolvars keep their FLOW value.
/           - tu_display will make these variables NOPRINT (NO)FLOW.
/           -
/        b) if last sharecolvar is FLOW=1 then __TEMP__ will get the FLOW
/           define statement attribute.
/     2) Make SHARECOLVARSindent=0 a valid indentation factor.
/     3) Make OVERALLSUMMARY function properly with COMPUTEBEFOREPAGEVARS.
/        By resetting flags when computebeforepagevars changes.
/
/ ------------------------------------------------------------------------------
/ Modified By:             John King
/ Date of Modification:    29Mar2004
/ New version number:      2/2
/ Modification ID:         jhk:2/2
/ Reason For Modification:
/     Fixed a bug, which added by last modification. Version 2.1 ignores the
/     value of parameter WIDTHS and DEFAULTWIDTHS while value of SHARECOLVARS
/     is blank.
/
/ ------------------------------------------------------------------------------
/ Modified By:             Yongwei Wang
/ Date of Modification:    30Apr2004
/ New version number:      2/3
/ Modification ID:         YW001
/ Reason For Modification:
/  1.The macro builds a rename command, stores it in a catalog file and %includes
/    it back into the program.  The command is wrapped at the default length of
/    132.  When a variable name straddles this position, an error occurs when the
/    statement executes.
/
/ ------------------------------------------------------------------------------
/ Modified By:             Yongwei Wang
/ Date of Modification:    19May2004
/ New version number:      2/4
/ Modification ID:         YW002
/ Reason For Modification:
/  1.Fixed a bug that make the macro could not order the variable correctly, if
/    the variable is in &ORDERVARS and &FLOWVARS, and hasing a format associate
/    with it.
/  2.Fixed a bug to pass all &varsin to &noleftalignvars when call %tu_split.
/
/ ------------------------------------------------------------------------------
/ Modified By:             Yongwei Wang
/ Date of Modification:    25May2004
/ New version number:      2/5
/ Modification ID:         YW003
/ Reason For Modification:
/  1.Apply &formats and &labels to &DSETIN
/  2.Passed to %tu_split only the variables which have multiple words formated  
/    values 
/  3.Added the new order variables to the COLUMNS, if a variable in &ORDERVARS
/    is passed to %tu_split. Set the variable to NOPRINT, ORDER variable
/  4.Set the &FORMATS and &LABELS passed to %tu_split to blank.
/  5.Pass only non-justified variables to &NOLEFTALIGNVARS of %tu_split.  
/ ------------------------------------------------------------------------------
/ Modified By:             Yongwei Wang
/ Date of Modification:    27May2004
/ New version number:      2/6
/ Modification ID:         YW004
/ Reason For Modification: -Changed 'AND' to 'OR' in applying formats and labels
/                          -Changed the position of RETAIN, KEEP, LENGTH, DROP
/                           in the data steps.
/
/ ------------------------------------------------------------------------------
/ Modified By:             Yongwei Wang
/ Date of Modification:    24May2005
/ New version number:      3/1
/ Modification ID:         N/A
/ Reason For Modification: -Changed '_np_' to '_NP_'. This is an urgent temporary
/                           change because the full bug fix version is not tested
/                           yet.
/ ------------------------------------------------------------------------------
/ Modified By:             Yongwei Wang
/ Date of Modification:    18Jul2005
/ New version number:      4/1
/ Modification ID:         YW005
/ Reason For Modification: 1. Modified &WIDTHS and &DEFAULTWIDTHS processing codes
/                             to make the naming wildcard work.
/                          2. Added the code to split the variable label.
/                          3. Changed the width for noprint variables to 1.
/ ------------------------------------------------------------------------------
/ Modified By:             Yongwei Wang
/ Date of Modification:    01Apr2008
/ New version number:      5/1
/ Modification ID:         YW006
/ Reason For Modification: Based on change request HRT0193
/                          1. Remove options msglevel=I statement.
/                          2. Remove code that writes proc contents and proc print
/                             output when g_debug ge 8. The output is being written 
|                             to the display output file rather than the .lst file.
/                          3. Bring tidyup code in line with debugging principles, . 
/                             (delete catalog when g_debug lt 5)
/ ------------------------------------------------------------------------------
/ Modified By:             
/ Date of Modification:    
/ New version number:      
/ Modification ID:         
/ Reason For Modification:
/
/********************************************************************************/

%macro tu_pva(
         dsetin                  = ,                  /* Input dataset */
         dsetout                 = work.metadata,     /* Output dataset */
         footrefdset             = work.footrefdset,  /* Footnote reference data set */
         byVars                  = ,                  /* BY Variables */
         computeBeforePageVars   = ,                  /* Computed BY variables */

         columns                 = ,                  /* Column parameter */
         formats                 = ,                  /* Format specification */
         widths                  = ,                  /* Column widths */
         defaultWidths           = ,                  /* List of default column widths */
         labels                  = ,                  /* Label definitions */

         orderVars               = ,                  /* Order variables */
         noprintVars             = ,                  /* No print vars, used to order the display */
         orderVarsDisplay        = ,                  /* ORDERVSARS, value displayed on every obs */

         shareColVars            = ,                  /* Order variable that share print space */
         shareCOlVarsIndent      = ,                  /* Indentation factor */
         overallSummary          = ,                  /* Overall summary line at top of tables */

         lineVars                = ,                  /* Order variable printed with line statements */

         flowvars                = _all_,             /* Variables with flow option */
         skipVars                = ,                  /* Break after <var> / skip */
         pageVars                = ,                  /* Break after <var> / page */
         idVars                  = ,                  /* ID variables */

         break1                  = ,                  /* Break statement */
         break2                  = ,                  /* Break statement */
         break3                  = ,                  /* Break statement */
         break4                  = ,                  /* Break statement */
         break5                  = ,                  /* Break statement */

         descending              = ,                  /* Descending ORDERVARS */
         centreVars              = ,                  /* centre justify variables */
         leftVars                = ,                  /* Left justify variables */
         rightVars               = ,                  /* Right justify variables */

         colSpacing              = 2,                 /* Overall spacing value */
         varSpacing              = ,                  /* Spacing for individual variables */

         orderFormatted          = ,                  /* ORDER=FORMATTED variables*/
         orderFreq               = ,                  /* ORDER=FREQ variables */
         orderData               = ,                  /* ORDER=DATA variables */

         proptions               = ,                  /* PROC REPORT statement options*/
         split                   = '~',               /* PROC REPORT split character */

         noWidowVar              =                    /* Specify a variable whose values must be kept together on a page */
      );

   %local macroversion;
   %let macroversion = 5;
   %inc "&g_refdata/tr_putlocals.sas";
   %tu_putglobals(varsin=g_ls g_ps)

   %let newcolumns=&columns; /* yw001 */

   /*
   / Check DSETIN
   /--------------------------------------------------------*/
   %if %bquote(&dsetin) EQ %then
   %do;
      %let g_abort = 1;
      %put %str(RTER)ROR: &sysmacroname: DSETIN must not be blank.;
      %goto MacERROR;
   %end;

   %if %sysfunc(exist(&dsetin)) EQ 0 %then
   %do;
      %let g_abort = 1;
      %put %str(RTER)ROR: &sysmacroname: DSETIN=&dsetin does not exist. ;
      %goto MacERROR;
   %end;

   %local
      workroot             /* root name of work data sets      */
      dsetoutLib           /* libname for &DSETOUT             */
      dsetoutMem           /* memname for &DESTOUT             */
      rx                   /* RXPARSE return code              */
      pos                  /* RXMATCH string match location    */
      i                    /* counter                          */
      w                    /* scanned word temp variables      */
      v                    /* scanned word temp variables      */
      times                /* replacement number for RXCHANGE  */
      expandParameters     /* List of macro parameters         */
      donotexist           /* Returned from %tu_chkvarsexist   */
      allvars              /* list of all variables passed     */
      tu_splitcalled       /* indicator                        */
      droplist             /* used if split is called          */
      renamelist           /* used if split is called          */
      addedordervars       /* YW002: adding new variables      */
      oldoldervars         /* YW002: old order variables       */
      modcolumns           /* YW003: column list with new ones */
      flowvarlist          /* YW003: list of flowvars          */
      formatlist           /* YW003: list of formats           */
      numofflowvars        /* YW003: number of flowvars        */
      newvarprefix         /* YW003: prefix for new variables  */
      ;
                      
   %let workroot = _tu_pva;
   %let tu_splitcalled = 0;
   
   /*
   / Remove the quoted strings from the COLUMNS parameter
   /---------------------------------------------------------------------*/
   %let rx     = %sysfunc(rxparse($q TO " " %str(,) "(" TO " " %str(,) ")" TO " "));
   %let times  = 999;
   %syscall rxchange(rx,times,columns,columns);
   %syscall rxfree(rx);
   %let modcolumns=&columns;
   
   /*
   / Search the parameters for abbreviated lists and expand if needed.
   /---------------------------------------------------------------------*/
   %let   expandParameters = columns byVars computeBeforePageVars orderVars noprintVars orderVarsDisplay shareColVars
                             lineVars flowvars skipVars pageVars idVars descending centreVars leftVars rightVars
                             orderFormatted orderFreq orderData nowidowvar;
         
                                   
   %let rx = %sysfunc(rxparse(_all_|_char_|_character_|_numeric_|-numeric-|-character-|'-'|'--'|':'));
   
   %let i = 1;
   %let w = %scan(&expandParameters,&i,%str( ));
   %do %while(%bquote(&w) NE);   
      %let pos = 0;      
      %if %bquote(&&&w) NE %then %let pos = %sysfunc(rxmatch(&rx,&&&w));
      %if &pos GT 0 %then
      %do;     
         %syscall rxfree(rx);
         %tu_expvarlist(Dsetin=&dsetin,varsin=&&&w,varout=&w);         
         %let rx = %sysfunc(rxparse(_all_|_char_|_character_|_numeric_|-numeric-|-character-|'-'|'--'|':'));
      %end; 
      %let allvars = &allvars &&&w;
      %let i = %eval(&i+1);
      %let w = %scan(&expandParameters,&i,%str( ));
   %end;
   
   %syscall rxfree(rx);   
   
   /*
   /  YW003: recover the order of &columns, which changed by tu_expanvarlist
   /-----------------------------------------------------------------------*/
   %if %nrbquote(&columns) ne %then 
   %do;
      data _null_;
         length __temp__var__ $32761;
         retain &columns " ";
         array __temp__array_0{*} &modcolumns;
         do __temp__=1 to dim(__temp__array_0);
            __temp__var__=trim(left(__temp__var__))||' '||trim(left(vname(__temp__array_0{__temp__})));
         end;
         call symput('columns', trim(left(__temp__var__)));
      run;   
   %end;
   
   %let modcolumns=;      

   /*
   / Check that all variables exist in &dsetin
   /------------------------------------------------------*/
   %let allvars    = %tu_unduplst(&allvars);
   %let donotexist = %tu_chkvarsexist(&dsetin,&allvars);
   %if %nrbquote(&donotexist) NE %then
   %do;
      %let g_abort = 1;
      %put %str(RTER)ROR: &sysmacroname: Variable(s) "&donotexist" not found in input data &dsetin;
   %end;
   
   /*
   / YW005: Check if more than one variables in &NOWIDOWVAR
   /--------------------------------------------------------*/   
   %if %qscan(&nowidowvar, 2) ne %then 
   %do;      
      %put %str(RTER)ROR: &sysmacroname: Multiple variables are found in NOWIDOWVAR=(nowidowvar), but only one is allowed;
      %goto MacERROR;
   %end; 

   /*
   / Validate &split.
   /--------------------------------------*/
   %let split = %sysfunc(dequote(&split.%str( )));
   %if %bquote(&Split) EQ %then
   %do;
      %let g_abort=1;
      %put %str(RTER)ROR: &sysmacroname: SPLIT may not be null or blank;
   %end;
   %else %let split = %sysfunc(quote(&Split));

   /*
   / Validate &ShareColVarsIndent and Overall Summary
   /----------------------------------------------------*/
   %if %bquote(&shareColVars) NE %then
   %do;
      %if %bquote(&sharecolvarsindent) EQ %then
      %do;
         %let g_abort=1;
         %put %str(RTER)ROR: &sysmacroname: ShareColVarsIndent may not be null or blank;
      %end;
      %else %if
            (%bquote(&sharecolVarsIndent) NE %sysfunc(abs(%sysfunc(int(&ShareColVarsIndent)))))
      %then
      %do;
         %let g_abort=1;
         %put %str(RTER)ROR: &sysmacroname: ShareColVarsIndent must be a positive integer;
      %end;
   %end;
   %else
   %do;
      %if %qsysfunc(indexw(1 YES Y,%qupcase(&overallsummary))) %then
      %do;
         %let g_abort=1;
         %put %str(RTER)ROR: &sysmacroname: An OverallSummary was requested but NO ShareColVars were listed.;
      %end;

   %end;

   /*
   / Validate &colSpacing
   /------------------------------------------*/
   %if %bquote(&colSpacing) EQ %then
   %do;
      %let g_abort=1;
      %put %str(RTER)ROR: &sysmacroname: colSpacing may not be null or blank;
   %end;
   %else %if
         (%bquote(&colSpacing) NE %sysfunc(abs(%sysfunc(int(&colSpacing)))))
      OR
         (%bquote(&colSpacing) EQ 0)
   %then
   %do;
      %let g_abort=1;
      %put %str(RTER)ROR: &sysmacroname: colSpacing must be a positive integer;
   %end;


   /*
   / Validate the variables in &FootRefDset
   /------------------------------------------*/
   %if %bquote(&FootRefDset) EQ %then
   %do;
      %put %str(RTNO)TE: &sysmacroname: No FootRefDset was specified.;
   %end;
   %else %if %sysfunc(exist(&FootRefDset)) EQ 0 %then
   %do;
      %let g_abort = 1;
      %put %str(RTER)ROR: &sysmacroname: FOOTREFDSET=&footrefdset does not exist. ;
   %end;
   %else /* FootRefDset does exist */
   %do;
      %let donotexist = %tu_chkvarsexist(&FootRefDset,name refnum);
      %if %bquote(&donotexist) NE %then
      %do;
         %let g_abort = 1;
         %put %str(RTER)ROR: &sysmacroname: Variable(s) "&donotexist" not found in FOOTREFDSET=&footrefdset;
      %end;
      %else /* variables do exist and need to check type and length */
      %do;
         %if %tu_varattr(&footrefdset,NAME,VARLEN) NE 32 %then
         %do;
            %let g_abort=1;
            %put %str(RTER)ROR: &sysmacroname: The variable NAME in FOOTREFDSET=&FOOTREFDSET does not have the correct attributes.;
         %end;
         %if %tu_varattr(&footrefdset,REFNUM,VARTYPE) NE C %then
         %do;
            %let g_abort=1;
            %put %str(RTER)ROR: &sysmacroname: The variable REFNUM in FOOTREFDSET=&FOOTREFDSET does not have the correct attributes.;
         %end;
      %end;
   %end;

   /*
   / Check &dsetout,
   / 1) libref exists.
   / 2) &dsetout is a valid data set name
   /-------------------------------------------*/
   %if %index(&dsetout,.) %then
   %do;
      %if %sysfunc(libref(%scan(&dsetout,1,.))) %then
      %do;
         %let g_abort=1;
         %put %str(RTER)ROR: &sysmacroname: Library reference for DSETOUT=&dsetout is not assigned.;
      %end;
   %end;

   %if %bquote(%tu_chknames(&dsetout,DATA)) NE %then
   %do;
      %let g_abort = 1;
      %put %str(RTER)ROR: &sysmacroname: DSETOUT=&dsetout is not a valid SAS data set name.;
   %end;


   %if %bquote(&g_abort) = 1 %then %goto macERROR;

   /*
   / Using &DSETOUT create &dsetoutLIB and &dsetoutMEM
   /--------------------------------------------------------*/
   %if %index(&dsetout,.) %then
   %do;
      %let dsetoutLib = %scan(&dsetout,1,%str(.));
      %let dsetoutMem = %scan(&dsetout,2,%str(.));
   %end;
   %else
   %do;
      %let dsetoutLib = work;
      %let dsetoutMem = &destout;
   %end;

   /*
   / Check FOOTREFDSET, if not blank it must also exist, and contain
   / variables "NAME and REFNUM".  NAME must be $32. , REFNUM must be character.
   /---------------------------------------------------------------------------*/
   %if %bquote(&footrefdset) NE %then
   %do;
      proc sort data=&FootRefDset(keep=name refnum);
         by name;
      run;
      %if &syserr GT 0 %then
      %do;
         %let g_abort=1;
         %put %str(RTER)ROR: &sysmacroname: The PROC SORT step ended with a non-zero return code.;
         %goto macERROR;
      %end;
   %end;
   
   /*  
   / YW003: Apply &formats ant &labels to &dsetin
   /-----------------------------------------------------------------------------*/
   
   %if (%nrbquote(&formats) NE ) or (%quote(&labels) NE ) %then %do;

      data &workroot.dsetin2;                                                  
         set &dsetin;
         %if %nrbquote(&formats) NE %then
         %do;
            format &formats;
         %end;
     
         %if %quote(&labels) NE %then
         %do;
            label &labels;
         %end;
         run;
                  
      %if &syserr GT 0 %then
      %do;
         %put %str(RTER)ROR: &sysmacroname: DATA step ended with a non-zero return code.;
         %goto macerror;
      %end;
      
      %let dsetin=&workroot.dsetin2;
      
   %end;   /* end-if on Formats and Labels are not blank */

   /*
   / Get the attributes from proc contents for each variable in the input data.
   / FMTLEN causes proc contents to load user defined formats that do NOT have a
   / width specification and determine the width.  e.g. $sex. is determined to
   / be $sex6. (very helpful)
   / YW003: Removed the format and label statement.
   /-----------------------------------------------------------------------------*/

   proc contents
      noprint
      fmtlen
      data = &dsetin
      out  = &workroot.contents0
         (
            keep = libname memname name type length label format formatl formatd just nobs sorted sortedby
         ) ;
   run;                    

   /*
   / This step:
   / 1) Parse values of &widths &defaultwidths and &varspacing.
   / 2) Create indicator variables for variables list parmaters.
   / 3) Create ordered lists for parameters:
   /     &byvars
   /     &computebeforepagevars
   /     &linevars
   /     &sharecolvars
   /     &columns
   / 4) Give variables with no format a default format.
   /    $ length for character variables.
   /    best8 for numeric variables.
   /--------------------------------------------------------------------------------*/
   data &workroot.contents1;
      set &workroot.contents0 end=eof;      
      length
         flowvarlist 
         formatlist          $2000  
         varprefix    
         newvarprefix        $50 /* YW003: */
         Widths 
         defaultWidths 
         varSpacing 
         result              $2000
         nowidowvars
         pattern  
         v7name              $200
         formatSpec          $32
         orderVars
         descendingvars
         orderVarsDisplay
         noPrintVars
         flowVars
         byVars
         computeBeforePageVars
         shareColVars
         linevars
         orderFormatted
         orderFreq
         orderData
         idVars
         pageVars
         skipVars
         centreVars
         rightVars
         leftVars            $500  
         newcolumns                  
         columns             $2000      
         splitChar           $1
         ;  

      drop          
         varprefix
         newvarprefix 
         flowvarlist 
         formatlist 
         numofflowvars /* YW003: */
         rx 
         widths 
         defaultwidths 
         varspacing 
         result 
         pattern 
         v7name      
         columns
         ordervars
         descendingvars
         ordervarsdisplay
         noprintvars
         flowvars
         byvars
         computebeforepagevars
         sharecolvars
         linevars
         orderformatted
         orderfreq
         orderdata
         idvars
         pagevars
         skipvars
         centrevars
         rightvars
         leftvars
         nowidowvars
         newcolumns
         ;
      
      retain 
         flowvarlist 
         formatlist 
         columns
         newcolumns
         ordervars
         descendingvars
         ordervarsdisplay
         noprintvars
         flowvars
         byvars
         computebeforepagevars
         sharecolvars
         linevars
         orderformatted
         orderfreq
         orderdata
         idvars
         pagevars
         skipvars
         centrevars
         rightvars
         leftvars
         splitchar
         nowidowvars    ''
         newvarprefix   '_NP_'
         varprefix      '__TMP__'
         numofflowvars 0  /* YW003: */                   
         ;
         
      oname = name;
      name = upcase(name);

      /*
      / Process WIDTHS, DEFAULTSWIDTHS and VARSPACING into SAS statements
      / that will be used in the steps to follow.
      /----------------------------------------------------------------------*/
      if _n_ EQ 1 then
      do;
         v7name = '($i'||repeat('{$c',30)||repeat('}',30)||')';

         widths        = symget('widths');
         defaultwidths = symget('defaultwidths');
         varspacing    = symget('varspacing');

         /*
         / Create data step variables from macro parameters. Use SYMGET as:
         / parameter_name = upcase(symget('parameter_name'));
         / where parameter name is one of the many variable list parameters.
         /-----------------------------------------------------------------*/         
         ordervars             = upcase(symget('ordervars'));
         descendingvars        = upcase(symget('descending'));
         ordervarsdisplay      = upcase(symget('ordervarsdisplay'));         
         noprintvars           = upcase(symget('noprintvars'));
         flowvars              = upcase(symget('flowvars'));
         byvars                = upcase(symget('byvars'));
         computebeforepagevars = upcase(symget('computebeforepagevars'));
         nowidowvars           = upcase(symget('nowidowvar'));
         
         /*
         / Concatenate &ComputeBeforePageVars to &columns.
         /-----------------------------------------------*/                  
         columns               = trim(left(upcase(symget('columns'))));
         newcolumns            = trim(left(symget('newcolumns')));
         sharecolvars          = upcase(symget('sharecolvars'));
         linevars              = upcase(symget('linevars'));
         orderformatted        = upcase(symget('orderformatted'));
         orderfreq             = upcase(symget('orderfreq'));
         orderdata             = upcase(symget('orderdata'));
         idvars                = upcase(symget('idvars'));
         pagevars              = upcase(symget('pagevars'));
         skipvars              = upcase(symget('skipvars'));
         centrevars            = upcase(symget('centrevars'));
         rightvars             = upcase(symget('rightvars'));
         leftvars              = upcase(symget('leftvars'));
         splitchar             = &split;
         overAllSummary        = input(symget('overallsummary'),best.);
          
         /*
         / change the floating point numbers following the SAS names to be prefixed with a
         / $ floating point number.
         /---------------------------------------------------------------------------------*/         
         do pattern = "$p <$f> $s TO '$' =_1";
            rx  = rxparse(trim(pattern));
            call rxchange(rx,999,trim(widths),result);
            call symput('widths',trim(result));
            call rxchange(rx,999,trim(defaultwidths),result);
            call symput('defaultwidths',trim(result));
            call rxfree(rx);
         end;    
              
         /*
         / Make the varspacing parameter into assignment statements.
         /-------------------------------------------------------------*/         
         do pattern = "$p<"||trim(v7name)||"> ' '+ <$f>$s TO =_1 '=' =_2 ';'";
            rx  = rxparse(Trim(pattern));
            call rxchange(rx,999,trim(upcase(varspacing)),result);
            call symput('varspacing',trim(result));
            call rxfree(rx);
         end;         
      end;  /* if _n_ EQ 1 */

      /* YW003: Move the calculation of COLUMN to the step below this data step */
       
      /*
      / For any variable that does not have a FORMAT assign one based on
      / variable type.  Numeric variables, best8.; character variables
      / $length.  Where length is the length of the character variable.
      /-----------------------------------------------------------------*/
      if formatl EQ 0 then do;
         if type EQ 1 then
         do;
            formatl = 8;
            format  = 'best';
         end;
         else
         do;
            formatl = length;
            format  = '$f';
         end;
      end;

      /*
      / Create FORMATSPEC by concatenating FORMAT FORMATL FORMATD.  This
      / variable will be handy but we also want the keep the three
      / variables used to create it.
      /-----------------------------------------------------------------*/
      if formatl GT 0 then do;
         formatspec = left(trim(format)||trim(left(put(formatl,best.)))||'.'||trim(left(put(formatd,best.))));
         end;

      /*
      / ORDER from &ORDERVARS. 0,1 if not in &ORDERVARS set default for DISPLAY 1.
      /--------------------------------------------------------------------------*/
      if indexw(ordervars,trim(name)) then
      do;
         order   = 1;
         display = 0;
      end;
      else
      do;
         order   = 0;
         display = 1;
      end;

      /*
      / DESCENDING from &DESCENDING. 0,1
      /---------------------------------*/
      if indexw(descendingvars,trim(name))
         then descending = 1;
         else descending = 0;

      /*
      / DISPLAY from &ORDERVARSDISPLAY 0,1.
      /-----------------------------------*/
      if indexw(ordervarsdisplay,trim(name)) then display = 1;

      /*
      / NOPRINT from &NOPRINTVARS. 0,1
      /-------------------------------*/
      if indexw(noprintvars,trim(name))
         then do;
              width = 1;      /* YW005: added width = 1 */
              noPrint = 1;
         end;
         else noPrint = 0;

      /*
      / FLOWVAR from &FLOWVARS. 0,1
      /----------------------------*/
      if indexw(flowvars,trim(name))
         then flowVar = 1;
         else flowVar = 0;
      
      /*      
      / YW005:NOWIDOWVAR from &NOWIDOWVAR. 0,1
      /---------------------------------------*/
      if indexw(nowidowvars,trim(name))
         then nowidowvar = 1;
         else nowidowvar = 0;

      /*
      / BYVAR from &BYVARS.  Use value returned by INDEXW to obtain position.
      /---------------------------------------------------------------------*/
      byVar = indexw(byvars,trim(name));
      if byvar EQ 0 then byvar = .;
      else
      do;
         order   = 0;
         display = 0;
      
         %if %nrbquote(&sharecolvars) ne %then %do;
            if indexw(columns, trim(name)) eq 0 then do;
               order   =1;
               noprint =1;
            end;
         %end;
      end;

      /*
      / ComputeBeforePageVar from &ComputeBeforePageVars. Use value
      / returned by INDEXW to obtain position in the variable list.
      / If also NOPRINT set NOLINE = 1, else NOLINE=0
      / SET: NOPRINT=1; ORDER=1; DISPLAY=0;
      /-------------------------------------------------------------*/   
      computeBeforePageVar = indexw(computeBeforePageVars,trim(name));
      if computeBeforePageVar EQ 0 then computeBeforePageVar = .;
      else
      do;
         if noprint
            then noLine = 1;
            else noLine = 0;
          
         if indexw(columns, trim(name)) GT 0 then
         do;
            result=translate(newcolumns, ' ', ',', ' ', '(', ' ', ')', ' ', '"', ' ', "'");       
            width=indexw(upcase(result), trim(name));        
            if width GT 0 then
               substr(newcolumns, width, length(trim(name)))=repeat(' ', length(trim(name)) - 1);                             
         end;   
            
         noprint = 1;
         order   = 1;
         display = 0;
         flowVar = 0;
         width   = 1;                         
      end;
      
      shareColVar = indexw(shareColVars,trim(name));
      if shareColVar EQ 0 then shareColVar = .;
      else
      do;
         noprint = 1;
         order   = 1;
         display = 0;
         shareColVarIndent = input(symget('sharecolvarsindent'),best.);
      end;

      /*
      / Line variables.
      /---------------------------------*/
      lineVar = indexw(lineVars,trim(name));
      if lineVar EQ 0 then lineVar = .;
      else
      do;
         order   = 1;
         display = 0;
         if noprint then noline = 1;
         else            noline = 0;
         noprint = 1;
         width = 1;   /* YW005: Added width = 1 */
         flowvar = 0;
      end;

      /*
      / ORDERMETHOD from &ORDERFORMATTED(FORMATTED), ORDERFREQ(FREQ),
      / ORDERDATA(DATA) or default (INTERNAL).
      /-----------------------------------------------------------------*/
      length orderMethod $9;
      if order then
      do;
         if      indexw(orderformatted,trim(name)) then ordermethod = 'Formatted';
         else if indexw(orderfreq     ,trim(name)) then ordermethod = 'Freq     ';
         else if indexw(orderdata     ,trim(name)) then ordermethod = 'Data     ';
         else                                           ordermethod = 'Internal ';
      end;

      /*
      / All order variables are also ID
      /-----------------------------------------*/
      if      missing(idvars) AND order   then idVar = 1;
      else if indexw(idvars,trim(name))   then idVar = 1;
      else                                     idVar = 0;

      /*
      / PAGEVAR from &PAGEVARS 0,1
      /---------------------------*/
      if indexw(pagevars,trim(name))
         then pageVar = 1;
         else pageVar = 0;

      /*
      / SKIPVAR from &SKIPVARS 0,1
      /---------------------------*/
      if indexw(skipvars,trim(name))
         then skipVar = 1;
         else skipVar = 0;

      /*
      / JUSTIFY from &CENTREVARS(CENTRE), &LEFTVARS(LEFT) and &RIGHTVARS(RIGHT).
      / If justify is not defined the value of justify will remain missing.
      /------------------------------------------------------------------------*/
      length justify $6;
      select;
         when(indexw(centrevars  ,trim(name))) justify = 'Center';
         when(indexw(rightvars   ,trim(name))) justify = 'Right ';
         when(indexw(leftvars    ,trim(name))) justify = 'Left  ';
         otherwise                             justify = '      ';
      end;
      
      /*
      /  YW003: Get possible split variables.
      /-------------------------------------------------------------------*/                          
      if sharecolvar and flowvar then split=1;     
      else split=0;  
             
      if flowvar and ( (not noprint) or sharecolvar ) then 
      do;  
         flowvarlist=trim(left(flowvarlist))||' '||trim(left(name));          
         numofflowvars=numofflowvars + 1;         
         formatlist=trim(left(formatlist))||' '||trim(left(formatSpec));                            
      end;  
      
      do while (substr(name, 1, length(newvarprefix)) eq newvarprefix);
         newvarprefix=compress(newvarprefix)||"_";
      end;    
      
      do while (substr(name, 1, length(varprefix)) eq varprefix);
         varprefix=compress(varprefix)||"_";
      end;      
      
      if eof then do;           
         columns=trim(left(computebeforepagevars))||' '||trim(left(columns));       
         call symput('flowvarlist',    trim(left(flowvarlist)));
         call symput('formatlist',     trim(left(formatlist)));
         call symput('numofflowvars',  put(numofflowvars, 6.0));   
         call symput('newvarprefix',   compress(newvarprefix));    
         call symput('varprefix',      compress(varprefix));    
         call symput('modcolumns',     compbl(columns));   
         call symput('newcolumns',     trim(left(newcolumns))); 
      end;      
      
   run;
   
   /*
   / Using the modified values of &WIDTHS and &DEFAULTWIDTHS run a data step to
   / create values for each variable.
   / YW005: Combined process for &WIDTHS and &DEFAULTWIDTHS into one. Added two
   / format statments to make wildcard in &WIDTHS and &DEFAULTSWIDTH work.
   /--------------------------------------------------------------------------------------*/
   
   %if %nrbquote(&defaultwidths) NE %then %do;
      data &workroot.defwidth;
         format &allvars ;
         length &defaultwidths;
         format &allvars $4999.;
         retain &allvars "";    
         stop;  
      run;
   
      %if &syserr GT 0 %then %do;
         %put %str(RTER)ROR: &sysmacroname: DATA STEP for DEFAULTSWIDTHS ended with a non-zero return code.;
         %goto macerror;
      %end;
   %end;   
     
   data &workroot.widths0;   
      %if %nrbquote(&widths) NE %then %do;
         format &allvars ;
         length &widths ; 
      %end;                      
      %if %nrbquote(&defaultwidths) NE %then %do;    
         if _n_ eq 0 then set &workroot.defwidth;
      %end;         
      format &allvars $4999.;      
      array _vars[*] _all_;
      length __name__ $32 __width__ 8;
   
      do _i_ = 1 to dim(_vars);
         _vars[_i_] = ' ';
         __name__   = upcase(vname(_vars[_i_]));      
         __width__  = vlength(_vars[_i_]);            
         if __width__ ne 4999 then output;
         end;
      stop;
      drop _i_;
      keep   __name__       __width__;
      rename __name__=name  __width__=width;
      run;

   %if &syserr GT 0 %then %do;
      %put %str(RTER)ROR: &sysmacroname: DATA STEP for DEFAULTSWIDTHS ended with a non-zero return code.;
      %goto macerror;
   %end;
   proc sort data=&workroot.widths0;
      by name;
      run;
   %if &syserr GT 0 %then %do;
      %put %str(RTER)ROR: &sysmacroname: PROC SORT ended with a non-zero return code.;
      %goto macerror;
   %end;
   
   proc sort data=&workroot.contents1;
      by name;
   run;
  
   data &workroot.contents2;
      merge &workroot.contents1 (in=_in_)
            &workroot.widths0;
      by name;
      if _in_;
   run;
      
   /*
   / YW003: check if flowvar has multiple word format value. If not, do not
   / pass variable to tu_split.
   /------------------------------------------------------------------------*/ 
   %if &numofflowvars gt 0 %then %do;
   
      data _null_;      
         set &dsetin(keep=&flowvarlist) end=eof;
         array &newvarprefix.1 {&numofflowvars} _TEMPORARY_ (
             %do i=1 %to &numofflowvars;
                 0
             %end;        
             );
         array &newvarprefix.5 {&numofflowvars} _TEMPORARY_ (
             %do i=1 %to &numofflowvars;
                 0
             %end;        
             );
             
         length &newvarprefix.3 &newvarprefix.4 &newvarprefix.6 $2000;    
         retain &newvarprefix.2 0 &newvarprefix.3 "" &newvarprefix.6 "";
             
         %do i=1 %to &numofflowvars;
            if ( not &newvarprefix.1{&i} ) or ( not &newvarprefix.5{&i} ) then 
               &newvarprefix.4=put(%scan(&flowvarlist, &i, %str( )), %qscan(&formatlist, &i, %str( )));

            if not &newvarprefix.1{&i} then 
            do;
               if compress(&newvarprefix.4) ne trim(left(&newvarprefix.4)) then 
               do;               
                  &newvarprefix.1{&i}=1;    
                  &newvarprefix.2=&newvarprefix.2 + 1;
                  &newvarprefix.3=trim(left(&newvarprefix.3))||' '||"%scan(&flowvarlist, &i, %str( ))";
               end;
            end;
                        
            if not &newvarprefix.5{&i} then 
            do;
               if trim(left(%scan(&flowvarlist, &i, %str( )))) ne trim(left(&newvarprefix.4)) then
               do;          
                  &newvarprefix.5{&i}=1;
               end;                    
             end;  
         %end;
         
         if eof then do;             
            do &newvarprefix.i = 1 to &numofflowvars;
               if not &newvarprefix.5{&newvarprefix.i} then
                  &newvarprefix.6=trim(left(&newvarprefix.6))||" "||scan(symget('formatlist'), &newvarprefix.i,' ');
            end;
            
            call symput('numofflowvars', put(&newvarprefix.2, 6.0));            
            call symput('flowvarlist', trim(left(&newvarprefix.3)));
            call symput('formatlist', trim(left(&newvarprefix.6)));
         end;
      run;
   %end;  /* end-if on &numofflowvars gt 0 */
               
   /* 
   / YW003: If the orderMethod='INTERNAL' and the variable needs to be passed
   / to tu_split, add an variable to keep the value and some ordering 
   / properties. 
   /------------------------------------------------------------------------*/    
    
   data &workroot.contents3;
      set &workroot.contents2 end=eof;   
      length modcolumn oldordervars addedordervars columns $2000 ;
      retain modcolumn oldordervars addedordervars ""
             columns;
      drop columns rx modcolumn oldordervars addedordervars _word columnLabelWidth;
       
      if _n_ eq 1 then columns=symget('modcolumns');
      if indexw(upcase(symget('flowvarlist')), name) then
      do;
         if missing(width) then 
         do;
            columnLabelWidth = 0;
            _word = scan(label,1,splitchar);
            do i=2 by 1 while(not missing(_word));
               columnLabelWidth = max(columnLabelWidth,length(_word));
               _word = scan(label,i,splitchar);
            end;                  
            width=min(columnLabelWidth, formatl);
         end;
         if width gt 2 then split=1;
      end; /* end-if on indexw(upcase(symget('flowvarlist')), name) */
      output;

      if split and ( upcase(orderMethod) EQ "INTERNAL" )
         %if %nrbquote(&formatlist) ne %then 
         %do;
            and (indexw(symget('formatlist'), formatSpec) eq 0)
         %end;
      then do;
         byvar=.;
         computeBeforePageVar=.;
         flowvar=0;
         linevar=.;
         noprint=1;
         overallsummary=.;
         pagevar=0;
         shareColvar=.;
         shareColVarindent=.;
         split=0;
         skipvar=0;
         nowidowvar=0;
         pagevar=0;
         width=1;    /* YW005: addeded to width=1 */
         oname="&newvarprefix."||compress(name);           
         
         rx=indexw(columns, name);
         
         if rx gt 0 then do;
            if rx eq 1 then do;
               columns=trim(oname)||' '||columns;
            end;
            else do;
               columns=substr(columns, 1, rx - 1)||' '||trim(oname)||' '||substr(columns,rx);
            end;
                    
            oldordervars=trim(left(oldordervars))||' '||left(name);
            addedordervars=trim(left(addedordervars))||' '||left(oname);
            name=oname;                        
            output;
         end;  /* end-if on rx > 0 */        
          
      end;  /* end-if on SPLIT and ORDER=INTERNAL */
  
      if eof then do;
         call symput('modcolumns', trim(columns));
         call symput('addedordervars', trim(addedordervars));
         call symput('oldordervars', trim(oldordervars));         
      end;
      
   run;

   %if &syserr GT 0 %then
   %do;
      %put %str(RTER)ROR: &sysmacroname: DATA STEP ended with a non-zero return code.;
      %goto macerror;
   %end;
   
   /*
   / YW003: This code is moved from the step above. 
   / Create COLUMN from &COLUMNS
   / Quoted string removed when &COLUMNS was checked above.
   / Use value of INDEXW to determine position in &COLUMNS.
   /-----------------------------------------------------------------*/  
  
   data &workroot.contents4;
      set &workroot.contents3;
      length columns $2000;      
      drop columns;
      retain columns;
      if _n_ eq 1 then columns = symget('modcolumns');
      column = indexw(upcase(columns),trim(upcase(name)));
      if column EQ 0 then column = .;      
   run;
   
   /*
   / YW003: Moved from the step right after parameter checking. Removed
   / the step that get ADDEDORDERVARS.
   / YW002: Find a variable in &ORDERVARS, &FLOWVARS, and hasing
   / a format associate with it. Duplicate the vairable and add the new variable
   / to &ORDERDATA, &COLUMN and &NOPRINTVARS
   /-----------------------------------------------------------------------------*/   
   %if %nrbquote(&addedordervars) ne %then %do;
   
      %let ordervars=&ordervars. &addedordervars;
      %let noprintvars=&noprintvars. &addedordervars;

      %put %str(RTN)OTE: &sysmacroname: &addedordervars has(ve) been added to COLUMNS, NOPRINTVARS and ORDERVARS.;
   
         /* YW002: add the variables to COLUMNS */
         data _null_;
            length pre columns newcolumns text textt $32761 var $32;
            columns=symget('newcolumns');           
            newcolumns=' ';
            
            do i=1 to 1000;
               rx =rxparse("$q");
               call rxsubstr(rx, columns, pos, len);
               if pos eq 0 then leave;
               if pos gt 1 then
                  pre=substr(columns, 1, pos - 1);
               else
                  pre='';
               text=pre;
               link addit;

               newcolumns=trim(left(newcolumns))||' '||trim(left(text))||' '||left(substr(columns, pos, len));
               columns=substr(columns, pos + len);
               call rxfree(rx);
            end;

            if columns ne '' then do;
               text=columns;
               link addit;           
               newcolumns=trim(left(newcolumns))||' '||trim(left(text));
            end;

            call symput('newcolumns', trim(left(newcolumns)));                   
       
            stop;
            return;

         ADDIT:
           
            text="+ "||left(text);
            textt=translate(text, ' ', '(', ' ', ')',  ' ', ',');            
            
            %let i = 1;
            %let w = %scan(&oldordervars, &i, %str( ));
            %let v = %scan(&addedordervars, &i, %str( ));

            %do %while(%nrbquote(&w) ne );
               ind=indexw(upcase(textt), upcase(trim(left("&w"))));
               if ind gt 0 then do;
                  var=compress("&v.");
                  text=substr(text, 1, ind - 1)||' '||trim(left(var))||' '||substr(text, ind);
                  textt=translate(text, ' ', '(', ' ', ')',  ' ', ',');                  
               end;

               %let i = %eval(&i + 1);
               %let v = %scan(&addedordervars, &i, %str( ));
               %let w = %scan(&oldordervars, &i, %str( ));
            %end; /* end of do-while loop */
            
            text=substr(text, 2);

            return;
      run;

      /* YW002: Add the variables to data set */
      data &workroot.temp1;
         set &dsetin(keep=&oldordervars);
         rename 
            %let i = 1;
            %do %while(%qscan(&oldordervars, &i, %str( )) ne );
               %scan(&oldordervars, &i, %str( )) = %scan(&addedordervars, &i, %str( ))
               %let i = %eval(&i + 1);
            %end; /* end of do-while loop */;        
         ;
      run;

       data &workroot.dsetin1;
          merge &workroot.temp1
                &dsetin;
       run;

       %let dsetin=&workroot.dsetin1;
   %end;  %*** end-if on ADDORDERVARS not blank ***;
 
   /*
   / Use PROC RANK to change values returned by INDEXW for:
   / byvar column computebeforepagevar sharecolvar linevar
   / to position in each variable list.
   / YW003: Changed data set name in DATA=.
   /------------------------------------------------------*/  
   proc rank data=&workroot.contents4 out=&workroot.contents5;
      var byvar column computeBeforePageVar shareColVar lineVar;
      run;
   
   %if &syserr GT 0 %then
   %do;
      %put %str(RTER)ROR: &sysmacroname: PROC RANK ended with a non-zero return code.;
      %goto macerror;
   %end;

   /*
   / Use PROC SUMMARY to find the total number of:
   / byvar column computeBeforePageVar shareColVar LineVar
   / as
   / byvar0 column0 computeBeforePageVar0 shareColVar0 lineVar0.
   /-----------------------------------------------------------*/
   proc summary data=&workroot.contents5;
      var byvar column computeBeforePageVar shareColVar lineVar;
      output out = &workroot.nums(drop=_type_ _freq_)
             max = byVar0 column0 computeBeforePageVar0 shareColVar0 lineVar0
             ;
      run;

   %if &syserr GT 0 %then
   %do;
      %put %str(RTER)ROR: &sysmacroname: PROC SUMMARY ended with a non-zero return code.;
      %goto macerror;
   %end;

   /*
   / Sort &DSETOUT by NAME.
   /---------------------------------*/
   proc sort data=&workroot.contents5;
      by name;
      run;
   %if &syserr GT 0 %then
   %do;
      %put %str(RTER)ROR: &sysmacroname: PROC SORT ended with a non-zero return code.;
      %goto macerror;
   %end;

   /*
   / Process the VARSPACING parameter using the same method as WIDTHS.
   /-----------------------------------------------------------------*/
   %if %bquote(&varSpacing) EQ %then
   %do;
      data &workroot.varspacing;
         length name $32 varSpacing 8;
         stop;
         name       = ' ';
         varSpacing = .;
         run;
   %end /* %bquote(&varSpacing) EQ */;
   %else
   %do;
      data &workRoot.varspacing;
         &varspacing;
         array _vars[*] _all_;
         length __name__ $32 __width__ 8;         
         drop _i_;
         keep   __name__       __width__;
         rename __name__=name  __width__=varSpacing;
         do _i_ = 1 to dim(_vars);
            __name__   = upcase(vname(_vars[_i_]));
            __width__  = _vars[_i_];
            output;
            end;
         stop;
       run;

      %if &syserr GT 0 %then %do;
         %put %str(RTER)ROR: &sysmacroname: DATA STEP for VARSPACING ended with a non-zero return code.;
         %goto macerror;
      %end;

      proc sort data=&workroot.varspacing;
         by name;
       run;

      %if &syserr GT 0 %then %do;
         %put %str(RTER)ROR: &sysmacroname: PROC SORT ended with a non-zero return code.;
         %goto macerror;
      %end;
   %end /* %else %do*/;

   
   data &workroot.contents6;
      if _n_ EQ 1 then set &workroot.nums;
      merge
         &workroot.contents5(in=in1)
         &workroot.varspacing
         &FootRefDset
         ;
      by name;
      length _word $100;
      drop _word i;
      
      if in1;
      if column;

      %if %bquote(&FootRefDset) EQ %then
      %do;
         refnum = ' ';
      %end;
      %else
      %do;
         if NOT missing(refnum) then label = trim(label)||splitchar||refnum;
      %end;

      if missing(varspacing) then varspacing = &colspacing;

      if sharecolvar then
      do;
         indent = sharecolvar*sharecolvarindent - sharecolvarindent -1;
      end;

      /*
      / Compute the column label width
      /----------------------------------------------------------------------*/
      columnLabelWidth = 0;
      _word = scan(label,1,splitchar);
      do i=2 by 1 while(not missing(_word));
         columnLabelWidth = max(columnLabelWidth,length(_word));
         _word = scan(label,i,splitchar);
      end;
      
      /*
      / Compute optimal width for each variable.
      /------------------------------------------------------------------------*/
      select;
         when(FLOWVAR) optimalWidth = min(formatl,columnLabelWidth);
         otherwise     optimalWidth = max(formatl,columnLabelWidth);
      end;

      output;
      if sharecolvar then
      do;
         if sharecolvar EQ sharecolvar0 then
         do;
            name        = '__TEMP__';
            column      = column + .5;
            computed    = 1;
            sharecolvar = sharecolvar + 1;
            type        = 2;
            length      = 200;
            format      = '$F';
            formatl     = 200;
            formatd     = 0;
            formatspec  = '$f200.0';
            noprint     = 0;
            order       = 0;
            display     = 0;
            split       = 0;
            if missing(width) then width = optimalWidth;
            output;
         end /* if sharecolvar EQ sharecolvar0*/;
      end /* if sharecolvar */;
   run;   
   
   %if &syserr GT 0 %then
   %do;
      %put %str(RTER)ROR: &sysmacroname: DATA STEP ended with a non-zero return code.;
      %goto macerror;
   %end;

   proc sort data=&workroot.contents6;
      by column;
   run;
 
   /*
   / Determine the total width of the report and left most print position.
   /
   / Create variables:
   /     reportWidth           Total widith of report.
   /     ls                    Report line size.
   /     ps                    Report page size.
   /     reportStartsAtColumn  Left most print position for first column.
   /--------------------------------------------------------------------------*/
   %let toowide = 0;
   data &workroot.colvars;
      keep reportWidth reportStartsAtColumn ls ps;
      set &workroot.contents6 end=eof;
      where NOT noprint;
      if missing(width) then width = optimalWidth;

      if _n_ EQ 1
         then cwidth = width;
         else cwidth = width + varspacing;

      reportWidth + cwidth;

      if eof then
      do;
         ls = input(symget('g_ls'),best.);
         ps = input(symget('g_ps'),best.);
         reportStartsAtColumn = ceil((1 + ls - reportWidth)/2);
         output;
         if reportwidth GT ls then call symput('toowide','1');
      end;
   run;

   %if &syserr GT 0 %then
   %do;
      %put %str(RTER)ROR: &sysmacroname: DATA STEP ended with a non-zero return code.;
      %goto macerror;
   %end;

   %if &toowide %then
   %do;
      %put %str(RTWARN)ING: &sysmacroname: This report is wider than the LS=&g_ls.;
   %end;

   /*
   / jhk: 2
   / Get Width and FLOW from __TEMP__ and put it on the shared column variables.
   / jhk: 2/2
   / Don't do step jhk:2 if SHARECOLVARS is blank.
   /------------------------------------------------------------------------------*/
   %if %nrbquote(&sharecolvars) NE %then
   %do;
      data &workroot.contents7;
         if _n_ = 1 then
         do;
            set &workroot.contents6
               (
                  keep   = name flowvar width optimalwidth
                  rename = (name=temp_name flowvar=temp_flowvar width=temp_width optimalwidth=temp_optimalwidth)
                  where  = (temp_name='__TEMP__')
               )
            ;
         end;
         set &workroot.contents6;

         if sharecolvar and name NE '__TEMP__' then
         do;
            if temp_flowvar then flowvar=1;
            width        = temp_width;
            optimalwidth = temp_optimalwidth;
         end;
         drop temp_:;
      run;
   %end;
   %else
   %do;
      data &workroot.contents7;
         set &workroot.contents6;
      run;
   %end;

   %if %sysfunc(fileref(_tu_pva)) gt 0 %then
   %do;
      filename _tu_pva CATALOG "work._tu_pva";
      filename _tu_pva list;
   %end;

   /* YW003: Added noleftalignvars */ 
   data _null_;
      set &workroot.contents7(where=(name NE '__TEMP__')) end=eof;
      retain varsin widthorwidthvars indentvars indentsofvars rename noleftalignvars;
      length varsin widthorwidthvars indentvars indentsofvars rename noleftalignvars $1000;
      /* YW003: Changed condition from 'flowvar & width GT 1' to 'split' */
      if split then  /* YW005: added (width gt 2) */
      do;
         varsin = trim(varsin) ||' '|| name;
         rename = trim(rename) ||' _SP_'|| trim(name) ||'='|| trim(name);
          
         if missing(width) then width = optimalwidth;
                 
         widthorwidthvars = trim(widthorwidthvars) || ' ' || left(put(width,best.));
         if indent > 0 then
         do;
            indentvars    = trim(indentvars) || ' ' || name;
            indentsofvars = trim(indentsofvars) || ' ' || left(put(indent+1,best.));
         end;
         /* YW003: if justified, left align the variable */
         if upcase(justify) not in ('RIGHT', 'LEFT', 'CENTER') then do;
            noleftalignvars = trim(noleftalignvars) ||' '|| name;         
         end;
      end;
      if eof then
      do;
         /* YW003: deleted formats and labels */
         /* YW001: Added linesize=2000 to the file statement */
         file _tu_pva('TU_SPLIT.source') linesize=2000;
         if not missing(varsin) then
         do;
            put '%tu_split';
            put +3 '(';
            put +6 "dsetin           = &dsetin,";
            put +6 "dsetout          = &workroot.dsetin,";
            put +6 'varsin           = ' varsin +(-1) ',';
            put +6 'noleftalignvars  = ' noleftalignvars +(-1) ',';      /* YW002, YW003 */
            put +6 'outvarprefix     = _SP_,';
            put +6 'widthorwidthvars = ' widthorwidthvars +(-1) ',';
            put +6 'indentvars       = ' indentvars +(-1) ',';
            put +6 'indentsofvars    = ' indentsofvars +(-1) ',';
            put +6 'splitchar        = ' splitChar +(-1) ',';
            put +6 'formats          = ,';
            put +6 'indentadjustyn   = Y,';
            put +6 'labels           = ,';
            put +6 'splitlabelyn     = N';
            put +3 ')';
            put '%let droplist = ' varsin +(-1) ';';
            put '%let renamelist = ' rename +(-1) ';';
            put '%let tu_splitcalled = 1;';
         end;
      end;
   run;

   %inc _tu_pva('TU_SPLIT.source');

   %if not &tu_splitcalled %then
   %do;
      data &workroot.contents8;          /* YW005: changed from &dsetout. */
         if _n_ EQ 1 then set &workroot.colvars;
         set &workroot.contents7;
      run;
      
      proc sort data=&workroot.contents8;
         by name;
      run;

      %if &syserr GT 0 %then %do;
         %put %str(RTER)ROR: &sysmacroname: DATA STEP ended with a non-zero return code.;
         %goto macerror;
      %end;
   %end;
   %else
   %do;
   
      /*
      / Get new variables to updata meta data
      /-------------------------------------------------------*/
      proc contents
            noprint
            data = &workroot.dsetin(keep = _SP_:)
            out  = &workroot.newcnts1(keep = name type length format just)
            ;
      run;
      data &workroot.newcnts2;
         set &workroot.newcnts1;
         name = upcase(name);
         if name EQ: '_SP_' & left(reverse(name)) NE: '0';
         name = substr(name,5);
      run;

      proc sort data=&workroot.newcnts2;
         by name;
      run;
      proc sort data=&workroot.contents7;
         by name;
      run;

      data &workroot.contents8;      /* YW005: changed from &dsetout. */
         if _n_ EQ 1 then set &workroot.colvars;
         update
            &workroot.contents7(in=in1)
            &workroot.newcnts2(in=in2)
            ;
         by name;
         if missing(width) then width = optimalWidth;
         if in2 then
         do;
            format     = '$f';
            formatl    = length;
            formatd    = 0;
            formatspec = left(trim(format)||trim(left(put(formatl,best.)))||'.'||trim(left(put(formatd,best.))));
         end;
         run;
      
      /*
      / Pass this work data set back to TU_DISPLAY as if it were &DSETIN
      /-------------------------------------------------------------------*/
      %let dsetinfrom_PVA = _displaydsetin;
      data &dsetinfrom_PVA;
         set
            &workroot.dsetin
               (
                  drop = &droplist
                  rename = (&renamelist)
               )
            ;
      run;
    
   %end;
     
   /*
   / YW005: Add split character to variable lables which were not passed
   / to tu_split and has split character in it.
   /-----------------------------------------------------------------------*/
   data &workroot.splitcnts; 
      set &workroot.contents8(keep=name label width splitChar split optimalwidth);
      length newlabel inwidthstr rinwidthstr llabel nlabel $200 alllabels $32761;      
      keep name newlabel;
      rename newlabel=label;
      by name;            
      if missing(width) then width=optimalwidth;  
      if ( width gt 2 ) and (( index(label, trim(left(split))) gt 0 ) or ( index(trim(left(label)), ' ') gt 0 ));
      llabel=label;
      newlabel='';

      do while (length(llabel) gt width);
         inwidthstr=substr(llabel, 1, width + 1)||'x';
         rinwidthstr=substr(left(reverse(inwidthstr)), 2);
         idx=index(rinwidthstr, compress(splitChar));
         if idx eq 0 then idx=index(rinwidthstr, " ");
         if (idx eq 0) or (idx gt width + 1) then nlabel=substr(llabel, 1, width);
         else if idx eq width + 1 then nlabel='';
         else nlabel=substr(llabel, 1, width - idx + 1);
         link addspt;

         if (idx eq 0) or (idx gt width + 1) then llabel=substr(llabel, width + 1);
         else llabel=substr(llabel, width + 3 - idx);
      end;

      nlabel=llabel;
      link addspt;
      alllabels=trim(left(alllabels))||' '||trim(left(name))||"='"||trim(newlabel)||"'";
      return;

   ADDSPT:
      if newlabel eq "" then newlabel = nlabel;
      else newlabel = trim(newlabel) || compress(splitChar) || nlabel;
      return;
   run;              
    
   data &dsetout;
      update &workroot.contents8
             &workroot.splitcnts;
      by name;
      if missing(width) then width=optimalwidth; 
   run; 

   /*
   / Added labels to data set and variables
   /-----------------------------------------------------------------------*/
   proc datasets nowarn nolist library=&dsetoutLib;
      modify &dsetoutMem(label='Variable attributes for TU_DISPLAY' sortedby=column);
      label
         reportWidth             = 'Width of report including spacing between columns'
         ls                      = 'Report Line Size'
         ps                      = 'Report Page Size'
         reportStartsAtColumn    = 'Left most column of report'
         byvar0                  = 'Number of BYVARS variables'
         column0                 = 'Number of COLUMNS variables'
         computeBeforePageVar0   = 'Number of COMPUTEBEFOREPAGEVARS variables'
         sharecolvar0            = 'Number of SHARECOLUMNVARS variables'
         linevar0                = 'Number of LINEVARS variables'
         oname                   = 'Original variable name (not UPCASED)'
         order                   = 'Order attribute  0,1'
         display                 = 'Display attribute  0,1'
         descending              = 'Descending attribute 0,1'
         ordermethod             = 'ORDER=E(ext or formatted) F(Freq) D(Data) I(Internal)'
         noprint                 = 'Noprint attribute 0,1'
         byvar                   = 'Position in by variable list'
         column                  = 'Position in column variable list'
         width                   = 'Column width'
         computeBeforePageVar    = 'Position in the compute before page variables list'
         formatspec              = 'Complete format compiled from (format formatl formatd)'
         shareColVar             = 'Position in the share column variables list'
         varSpacing              = 'Variable spacing'
         idVar                   = 'ID attribute 0,1'
         pageVar                 = 'Break after var page 0,1'
         skipVar                 = 'Break after var skip 0,1'
         flowVar                 = 'Flow attribute 0,1'
         lineVar                 = 'Position in the compute line variables list'
         computed                = 'Computed attribute .,1'
         noline                  = 'Noprint option for COMPUTEBEFOREPAGEVARS and LINEVARS'
         justify                 = 'Right left or centre justification'
         indent                  = 'Indentation for SHARECOLVARS'
         shareColVarIndent       = 'Value of ShareColVarsIndent'
         columnLabelWidth        = 'Column Label Width'
         splitChar               = 'The split character'
         optimalWidth            = 'Optimal Width'
         overallsummary          = 'Overall Summary 0,1'
         refnum                  = 'Footnote reference number'
         split                   = 'If tu_split is called'
         nowidowvar              = 'Variable whose values must be kept together on'
         ;
      run;
   quit;

   %if &syserr GT 0 %then %do;
      %put %str(RTER)ROR: &sysmacroname: PROC DATASETS ended with a non-zero return code.;
      %goto macerror;
   %end; 
   
   %goto exit;

%MacERROR:
    %put %str(RTE)RROR: &sysmacroname: Ending with error(s);
    %let g_abort = 1;
    %tu_abort()
                  
%exit:
   %tu_tidyup(rmdset=&workroot.:,glbmac=NONE);
   
   %if &g_debug lt 5 %then
   %do;  
      proc datasets nowarn nolist lib=work;
         delete _tu_pva:(memtype=cat);
         run;
      quit;
   %end;
   
   %if %sysfunc(fileref(_tu_pva)) eq 0 %then
   %do;
      filename _tu_pva clear;
   %end;
   
   %put RTNOTE: &sysmacroname: ending execution.;
   
%mend tu_pva;

