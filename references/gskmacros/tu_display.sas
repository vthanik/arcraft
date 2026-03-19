/*
/
/ Macro Name: tu_display
/
/ Macro Version:   6 
/
/ SAS Version: 9.3
/
/ Created By: John Henry King
/
/ Date: 05/20/2003
/
/ Macro Purpose: A macro to print tables and listings.
/
/ Macro Design: Procedure style.
/
/ Input Parameters:
/
/ NAME                    DESCRIPTION                                          DEFAULT
/ ----------------------- ---------------------------------------------------- ----------
/ DSETIN                  Specifies the name of the input data set.            No default
/
/ FOOTREFDSET             Specifies the name of the dataset created by         work.footrefdset
/                         %TU_FOOTER that is used to create footnote references.
/                         This parameter is not documented in the Unit Specification
/                         but should be.
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
/ REF                     Fileref for PROC RREPORT destination defined before  tu_list
/                         this macro is called. It is only used when 
/                         &NOWIDOWVAR is not blank. It is used to recover the
/                         output destination.
/                       
/
/ Output: Printed output.
/
/ Global macro variables created: NONE
/
/
/ Macros called:
/
/(@) tr_putlocals
/(@) tu_abort
/(@) tu_nobs
/(@) tu_noreport
/(@) tu_putglobals
/(@) tu_pva
/(@) tu_tidyup
/
/ Example:
/
/  %tu_display
/     (
/        dsetin = sashelp.class,
/        columns = _all_
/     )
/
/
/
/**********************************************************************************************
/ Change Log
/
/ Modified By:             John King
/ Date of Modification:    18Aug2003
/ New version number:      1/2
/ Modification ID:
/ Reason For Modification: Comments from SCR.
/ ---------------------------------------------------------------------------------------------
/ Modified By:             John King
/ Date of Modification:    20Aug2003
/ New version number:      1/3
/ Modification ID:
/ Reason For Modification: Small addition needed for failed test.
/
/ ---------------------------------------------------------------------------------------------
/ Modified By:             John King
/ Date of Modification:    03Sep2003
/ New version number:      1/4
/ Modification ID:         jhk:1/4
/ Reason For Modification: 1) Add test for blank COLUMNS= parameter.
/                          2) Remove code to set OPTIONS MISSING=;
/
/ ---------------------------------------------------------------------------------------------
/ Modified By:            Paul Jarrett
/ Date of Modification:   22Oct2003
/ New version number:     1/5
/ Modification ID:        pbj:1/5
/ Reason For Modification: Remove semicolons from fly-over text.
/
/ ---------------------------------------------------------------------------------------------
/ Modified By:             John King
/ Date of Modification:    15Jan2004
/ New version number:      2/1
/ Modification ID:         jhk:2
/ Reason For Modification: 1) Fix problems with FLOWVARS and SharedColumnVars
/                          2) Fix bug in OVERALLSUMMARY=Y with ComputeBeforePageVars
/                          3) Removed OVERALLSUMARYFLAG and replaced it with SHARECOLVARFLAG
/                          4) Remove extra BLANK LINE at end of file or end of by group that
/                             can produce an extra page of output that is completely blank.
/                          5) Increase length of temporary variable from 500 to 5000.
/ ---------------------------------------------------------------------------------------------
/ Modified By:             John King
/ Date of Modification:    25Feb2004
/ New version number:      2/2
/ Modification ID:         jhk:2.2
/ Reason For Modification: 1) Added a local variable timesthrough to flag if it is the first
/                             time to call proc report. The break1-5 variables should only be
/                             called in the first call of proc report. It fixed a SAS error 
/                             message that stated 'break variable can not be found.'
/                          2) Combined two data steps, which is added at last modification and 
/                             is used to remove the extra records related to ANY EVENT, into 
/                             one so that the codes is easy to read and easy to maintain.
/                          3) Changed '=' to 'EQ' in condition statements.
/ ---------------------------------------------------------------------------------------------
/ Modified By:             Yongwei Wang
/ Date of Modification:    10May2004
/ New version number:      2/3
/ Modification ID:         YW001
/ Reason For Modification: Added a condition to the PROC REPORT, if &SHARCOLVARS is not blank, 
/                          so that the shared columns displayed correctly when one of 
/                          the &SHARECOLVARS is alos a skip variable.
/ ---------------------------------------------------------------------------------------------
/ Modified By:             Yongwei Wang
/ Date of Modification:    10May2004
/ New version number:      3/1
/ Modification ID:         YW002
/ Reason For Modification: - Made &BYVARS work while &SHARECOLVARS is not blank
/                          - Modify the code so that the length of &SHARECOLVARS can be more 
/                            than $200
/                          - Re-arrange the looping, which uses %goto statement, to replace
/                            the %goto statement with %do-%while
/                          - Made &NOWIDOWVAR work
/ ---------------------------------------------------------------------------------------------
/ Modified By:             Yongwei Wang
/ Date of Modification:    01Apr2008
/ New version number:      4/1
/ Modification ID:         YW003
/ Reason For Modification: Based on change request HRT0193:
/                          1. Remove code that writes proc contents and proc print output
/                             when g_debug ge 8 (2 places)
/                          2. Bring tidyup code in line with debugging principles (delete
/                             catalog when g_debug lt 5).
/                          3. Removed "filename _PVA clear;" and " delete _PVA:(memtype=cat);" 
/                             statement 
/ ---------------------------------------------------------------------------------------------
/ Modified By:             Shivam Kumar        
/ Date of Modification:    23Oct2013
/ New version number:      5/1
/ Modification ID:
/ Reason For Modification: To Remove repeated %then
/ ---------------------------------------------------------------------------------------------
/ Modified By:             Lee Seymour        
/ Date of Modification:    25Sep2014
/ New version number:      6/1
/ Modification ID:         LS001
/ Reason For Modification: HRT0303 - Additional validation steps added to ensure NOWIDOWVAR only
/                          contains one variable and is using a variable that contains values.
/                          Added a check for SYSERRORTEXT populated in addtion to checking SYSERR
/                          to ensure macro aborts if error results from proc report.  
/************************************************************************************************/

%macro tu_display (
   dsetin                  = ,                  /* Input dataset */
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

   shareColVars            = ,                  /* Order variables that share print space */
   shareCOlVarsIndent      = 2,                 /* Indentation factor */
   overallSummary          = NO,                /* Overall summary line at top of tables */

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

   proptions               = headline,          /* PROC REPORT statement options*/
   split                   = '~',               /* PROC REPORT split character */

   noWidowVar              = ,                   /* Variable whose values must be kept together on a page */  
   ref                     = tu_list             /* Fileref for PROC RREPORT destination defined before this macro */          
   );

   /*
   / This macro uses a SAS catalog to store source code written by the macro.
   / USING: filename &workroot CATALOG "work.&workroot";
   /
   / The source code is %included in the PROC REPORT step.
   /
   / There are 4 data steps that each write to a different catalog entry.
   / USING: file &workroot('CBPV.source');      Compute Before Page
   /        file &workroot('linevar.source');   Line variables
   /        file &workroot('SHCV.source');      Share column variables.
   /        file &workroot('SHCV1.source');     Re-assign values of share column variables.
   /        file &workroot('DEFINE.source');    Define statements, and SKIP and PAGE
   /                                            Break statements.
   /
   /-----------------------------------------------------------------------------------*/
   %local macroversion;
   %let macroversion = 5;

   %inc "&g_refdata/tr_putlocals.sas";
   %tu_putglobals(varsin=g_ls g_ps)

   %local
      workroot           /* temporary data set root name */
      toowide            /* report too wide flag */
      workrept           /* name of OUT= data set from PROC REPORT */
      workmeta           /* name for temporary meta data */
      shareColVarFlag    /* Flag variable for shared column variable printing */
      timesthrough       /* jhk:2/2 - Flag for first or second printing */  
      dsetinfrom_PVA     /* name given to copy of dsetin created by TU_PVA when TU_SPLIT is called */
      dropfrom2          /* drop list for second printing */
      newcolumns         /* YW001: columns with added sorting variables */
      nobsflag           /* YW002: if the looping data set is empty */
      byvarloops         /* YW002: Number of loops when looping over &byvars */
      subdsetin          /* YW002: Temporary data set used when looping over &byvars */
      subworkept         /* YW002: Temporary data set used when looping over &byvars */
      loopdsetin         /* YW002: Temporary data set used when looping over &byvars */
      templength         /* YW002: length of __temp__ */
      panels             /* YW002: for NOWIDOWVAR, panels per page */
      pages              /* YW002: for NOWIDOWVAR, number of pages per &NOWINDOWVAR level */
      fit                /* YW002: for NOWIDOWVAR, if group of &NOWINDOWVAR levels fit one page */
      initlvl            /* YW002: for NOWIDOWVAR, initial level of &NOWINDOWVAR in a group */
      tltlvls            /* YW002: for NOWIDOWVAR, total values of &NOWINDOWVAR for a group: ie total
                            number of VARLVLS that will fit onto one page. */
      j                  /* YW002: for NOWIDOWVAR, loop variable */
      oldfit             /* YW002: for NOWIDOWVAR, previous value of &fit */
      pagefoundflag      /* YW002: for NOWIDOWVAR, if a fited page has been found */
      varlvls            /* YW002: for NOWIDOWVAR, total levels of &NOWINDOWVAR: eg if aesoc and aept
                            are the sharecolvars, then this is the number of unique combinations of
			    values of aesoc and aept. */
      columnoffirstshcv  /* YW002: Column# of first share column variable */
      footer0            /* YW002: Number of footer, used when &NOWIDOWVAR is not blank */
      numofsummarylevels /* YW002: Number of levels of overallsummary */
      summarylevels      /* YW002: List of Levels of the overallsummary */
      overallsummaryvars /* YW002: List of overallsummary variables */
      ;

   %let dsetinfrom_PVA = &dsetin;  /* jhk:2 */
   %let toowide  = 0;
   %let workroot = %substr(&sysmacroname,3);
   %let timesthrough = 0;         /* jhk:2/2 */
   %let nobsflag = 1;                          /* yw002 */
   %let byvarloops = 0;                        /* yw002 */
   %let subdsetin = &workroot.subdsetin;       /* yw002 */
   %let subworkrept = &workroot.subworkrept;   /* yw002 */
   %let loopdsetin = &workroot.loopdsetin;     /* yw002 */    
   %let templength = 200;                      /* yw002 */    
   %let oldfit = 0;                            /* yw002 */  
   %let pagefoundflag = 0;                     /* yw002 */ 
   %let initlvl = 1;                           /* yw002 */ 
   %let fit = 0;                               /* yw002 */ 
   %let pages = 1;                             /* yw002 */ 
   %let panels = 1;                            /* yw002 */
   %let varlvls=1;                             /* yw002 */ 
   %let columnoffirstshcv=0;                   /* yw002 */
   %let numofsummarylevels=0;                  /* yw002 */
  
   /*
   / jhk:1/4
   / Check for blank columns parameter.
   /------------------------------------------------------------*/
   %if %nrbquote(&columns) EQ %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: Value of %nrstr(&columns) must not be blank.;
      %goto MacERROR;
   %end;

   /*
   / If input data &dsetin has 0 observations call %tu_NOREPORT
   /------------------------------------------------------------*/

   %if %nrbquote(&dsetin) EQ %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: Value of %nrstr(&destin) must not be blank.;
      %goto MacERROR;
   %end;

   %if NOT %sysfunc(exist(&dsetin)) %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: DSETIN=&dsetin does not exist;
      %goto MacERROR;
   %end;

   %if %tu_nobs(&dsetin) EQ 0 %then
   %do;
      %put %str(RTN)OTE: &sysmacroname: Calling %nrstr(%tu_NOREPORT);
      options ls=&g_ls ps=&g_ps;
      %tu_noreport()
      %goto exit;
   %end;

   /*
   / YW002: check the consistence between sharecolvars and overallsummary
   /----------------------------------------------------------------------*/

   %let summarylevels=1;
   %let overallsummary=%qupcase(&overallsummary);   
   %let overallsummaryvars=%qscan(&overallsummary, &summarylevels, %str( ));  
   
   %do %while(&overallsummaryvars ne );   
      %let summarylevels=%eval(&summarylevels + 1);
      %if (%qsubstr(&overallsummaryvars, 1, 1) eq Y) %then 
      %do;
         %let numofsummarylevels=1;
         %if (%qscan(&sharecolvars, &summarylevels, %str( )) EQ) %then
         %do;
            %put %str(RTER)ROR: &sysmacroname: OVERALLSUMMARY=YES but no enough SHARECOLVARS specified.;
            %let g_abort=1;
         %end;
      %end;
           
      %if ( &overallsummary eq Y ) or ( &overallsummary eq YES ) %then 
      %do;
         %if (%qscan(&sharecolvars, %eval(&summarylevels + 1), %str( )) NE) %then %let overallsummary=&overallsummary Y;
      %end;
      
      %let overallsummaryvars=%qscan(&overallsummary, &summarylevels, %str( ));
   %end;
      
   %if %nrbquote(&g_abort) eq 1 %then %goto MacERROR;  
      
   /*
   /  YW002: If &nowidowvar is not blank, check &ref.
   /-------------------------------------------------*/
   %if (%nrbquote(&nowidowvar) ne) %then
   %do;   
      %if ( %nrbquote(&ref) ne ) and ( %sysfunc(fileref(&ref)) gt 0 ) %then 
      %do;     
         %put %str(RTN)OTE: &sysmacroname: Both NOWIDOWVAR (=&nowidowvar) and REF (=&ref) are given, but file reference &ref is not assigned;
         %put %str(RTN)OTE: &sysmacroname: Set ref to blank;
         %let ref=;
      %end; 

   /* LS001
   / Check if NOWIDOWVAR containsmore than one variable
   / Check variable specified in NOWIDOWVAR is not missing for every observation
   /----------------------------------------------------------------------------*/
      %if %tu_words(&nowidowvar) gt 1 %then
      %do;
           %put %str(RTER)ROR: &sysmacroname: Multiple variables are found in NOWIDOWVAR=(&nowidowvar). Only one variable should be used;
           %goto MacERROR;
      %end;
      %else 
      %do;
         proc sql noprint; 
              select count(distinct &nowidowvar) into : missnowidowvar
              from &dsetin;
         quit;

         %if &missnowidowvar eq 0 %then 
          %do;
             %put %str(RTER)ROR: &sysmacroname: The variable &nowidowvar specified in NOWIDOWVAR contains missing values on all records;
             %goto MacERROR;
         %end;
      %end; /*End of nowidowvar not missing and is only one variable */
   %end; /* End of nowidowvar not missing */



   /*
   / Validate &split.
   /--------------------------------------*/
   %let split = %sysfunc(dequote(&split.%str( )));
   %if %bquote(&Split) EQ %then
   %do;
      %let g_abort=1;
      %put %str(RTER)ROR: &sysmacroname: SPLIT may not be null or blank;
      %goto MacERROR;
   %end;
   %else %let split = %sysfunc(quote(&Split));

   %tu_pva
      (
         dsetin                  = &dsetin,
         dsetout                 = work.&workroot.metadata,
         footrefdset             = &footrefdset,
         byVars                  = &byvars,
         computeBeforePageVars   = &computeBeforePageVars,

         columns                 = &columns,
         formats                 = &formats,
         widths                  = &widths,
         defaultWidths           = &defaultWidths,
         labels                  = &labels,

         orderVars               = &ordervars,
         noprintVars             = &noprintVars,

         shareColVars            = &shareColVars,
         shareColVarsIndent      = &shareColVarsIndent,
         overallSummary          = &numofsummarylevels,

         lineVars                = &lineVars,

         flowvars                = &flowvars,
         skipVars                = &skipVars,
         pageVars                = &pageVars,
         idVars                  = &idVars,

         break1                  = &break1,
         break2                  = &break2,
         break3                  = &break3,
         break4                  = &break4,
         break5                  = &break5,

         descending              = &descending,
         centreVars              = &centrevars,
         rightVars               = &rightVars,
         leftVars                = &leftVars,

         colSpacing              = &colSpacing,
         varSpacing              = &varSpacing,

         orderFormatted          = &orderFormatted,
         orderFreq               = &orderFreq,
         orderData               = &orderData,

         proptions               = &proptions,
         split                   = &split,

         noWidowVar              = &nowidowVar

      );

   %if %eval(&g_abort) %then %goto macERROR;

   /*
   / jhk:2 
   / updated the value of dsetin using value returned by TU_PVA
   / Removed the old comment.
   /------------------------------------------------------------*/
   %let dsetin = &dsetinfrom_PVA;
   %let columns = &newcolumns;    /* YW001 */


   %if &toowide %then
   %do;
      %put %str(RTWARN)ING: &sysmacroname: This report is wider than the LS=&g_ls.;
   %end;


   %if %sysfunc(fileref(&workroot)) %then
   %do;
      filename &workroot CATALOG "work.&workroot";
      filename &workroot list;            
      filename _winoutf  CATALOG "work.&workroot..temprpt.output" ;
   %end;

   %let workmeta = work.&workroot.metadata;
 
   /*
   /  YW002: Check if &nowdiowvar is found in &column by %tu_pva. Build 
   /  source code to add a group variable to mark the nowidowvar group.      
   /-----------------------------------------------------------------------*/  
   %if %nrbquote(&nowidowvar) ne %then
   %do;   
      proc sort data=work.&workroot.metadata out=&workroot.order;
         by column name;
      run;
      
      data _null_;      
         set  &workroot.order end=end;
         by column;
         retain count 0;
         file &workroot('ORDER.source');               
         if ( column and order ) or nowidowvar;
         count=count + 1;            
         
         /* initialize &nowidowvar group variable __temp__page_var */
         if count eq 1 then 
         do;
            put +3 'retain __temp__page_var 0;';                  
            put +3 'drop __temp__page_var1;';
            put +3 '__temp__page_var1=1;';                   
         end;
        
         /* The high level &sharecolvar should in the same page as the level below it */
         if sharecolvar then 
         do;
            put +3 'if ( lag(_break_) eq compress("' name '")) and (lag(__temp__) ne "" ) then __temp__page_var1=0;'; 
         end;
         /* Any change of &nowindowvar and variable before it should be the beginning of new group */
         put +3 'if __temp__page_var1 and (lag(' name ') ne ' name ') then do;';
         put +3 '   __temp__page_var=__temp__page_var + 1;';
         put +3 '   __temp__page_var1=0;';
         put +3 'end;';
         
         if nowidowvar then do;
            call symput('nowidowvar', trim(left(name)));         
            stop;
         end;               
      run;    
   
      /* 
      /  Build code to remove last skip in each printout group. Those skip may add a blank page to the output.
      /  It is only useful when both &nowidowvar and &sharecolvars are given.
      /------------------------------------------------------------------------------------------------------*/   
      data _null_;      
         set  &workroot.order end=end;
         by column;
         retain count 0;
         file &workroot('SHCV2.source');               
         if ( column and sharecolvar ) then count=1;
         if count;
         if skipvar and order and ( not sharecolvar ) then 
         do;
            put +3 '   if _break_ eq compress("' name '") then delete;';
         end;         
         if skipvar and order and sharecolvar then 
         do;
            put +3 '   if _break_ eq compress("' name '") and ( __temp__ eq "" ) ';
            put +3'       and (__temp__page_var eq lag(__temp__page_var)) then delete;';
         end;
      run;
      
   %end; /* end-if on &nowidowvar is not blank */

   /*
   /  YW002: Get a list of overall summary group variables and their indents.
   /  The summary group variable is the higher level variable of each sharecolvars.
   /  The list of variables are save in &overallsummaryvars and the indents are saved
   /  in &summarylevels. The &numofsummarylevels save the number of the variables.  
   /-------------------------------------------------------------------------------------*/  
   %if &numofsummarylevels %then
   %do;
      proc sort data=work.&workroot.metadata out=&workroot.summarylevel;
         by column name;
         where sharecolvar or (not noprint);
      run;
        
      data _null_;
         set &workroot.summarylevel end=end;
         by column name;
         length summarylevels overallsummaryvars $32761 lagname $200;
         retain numofsummarylevels levels 0 summarylevels overallsummaryvars '';
         
         lagname=lag1(name);        
         if sharecolvar and noprint then 
         do;        
            levels=levels + 1;
            if substr(scan("&overallsummary", levels, ' '), 1, 1) eq 'Y' then
            do;
               if missing(lagname) then
                  overallsummaryvars=trim(left(overallsummaryvars))||' _NULL_';
               else
                  overallsummaryvars=trim(left(overallsummaryvars))||' '||left(upcase(lagname));
               summarylevels=trim(left(summarylevels))||' '||left(put(indent, 6.0));
               numofsummarylevels=numofsummarylevels + 1;         
            end;
         end; /* end-if on sharecolvar and not noprint */
         
         if end then do;
            call symput('overallsummaryvars', trim(left(overallsummaryvars)));
            call symput('summarylevels', trim(left(summarylevels)));
            call symput('numofsummarylevels', left(put(numofsummarylevels, 6.0)));
         end;
      run;
   %end; /* end-if on &numofsummarylevels */

%put overallsummaryvars=&overallsummaryvars;              
%put summarylevels=&summarylevels;
%put numofsummarylevels=&numofsummarylevels;
   /* jhk:2 
   /  Set sharecolvarflag.
   /-----------------------------------------------------------------------*/                                     
   %if %nrbquote(&shareColVars) NE
      %then %let shareColVarFlag = 1;
      %else %let shareColVarFlag = 0;
   %if %nrbquote(&nowidowvar) NE 
      %then %let shareColVarFlag = 1;
  
   /* 
   /  YW002: Re-arrange the looping, which uses %goto statement, to replace 
   /  the %goto statement with %do-%while loop.
   /  If &SHARECOLVARS is not blank, or &NOWIDOWVARS is not blank, looping 
   /  over the step below twice, otherwise, looping only once. 
   /  If looping twice, the first loop will create a output data set. 
   /  The data set will be modified if &sharecolvars is given. The
   /  &overallsummary will be processed and the length of __temp__ will be
   /  reassigned because PROC REPORT can not have __temp__ longer than 200.
   /  The second loop will be used to creating final report.
   /-----------------------------------------------------------------------*/         
   %do %while ( &timesthrough lt 2 );
   
      %let timesthrough=%eval(&timesthrough + 1);
      %let workrept=work.&workroot.rept&shareColVarFlag;    /* jhk:2 */
    
      /*
      / Now write the code for PROC REPORT using the data from above.
      /-----------------------------------------------------------------*/
    
      /*
      / Write the statements associated with the compute before page vars
      /-------------------------------------------------------------------*/
      proc sort data=&workmeta out=work.&workroot.cbpv;
         where computebeforepagevar;
         by computebeforepagevar;
         run;
      %if &syserr GT 0 %then
      %do;
         %put %str(RTER)ROR: &sysmacroname: The PROC SORT step, for computeBeforePageVars ended with a non-zero return code.;
         %goto macerror;
      %end;
    
      data _null_;
         file &workroot('CBPV.source');
         do until(eof1);
            set
               work.&workroot.cbpv
               end = eof1
               ;
            put 'Break before ' name '/ page;';
         end;
    
         %if not &shareColVarFlag %then
         %do;         
            put 'Compute before _page_ / left;';
            do until(eof2);
               set
                  work.&workroot.cbpv
                  end = eof2
                  ;
               if NOT noline then put '   line ' name formatspec ';';
            end;
            put '   endcomp;';
         %end;
      run;
    
      /*
      / Write statements associated with linevars
      /-----------------------------------------------*/
      proc sort data=&workmeta out=work.&workroot.line;
         where linevar;
         by linevar;
      run;
      %if &syserr GT 0 %then
      %do;
         %put %str(RTER)ROR: &sysmacroname: The PROC SORT step, for lineVars, ended with a non-zero return code.;
         %goto macerror;
      %end;
      data _null_;
         file &workroot('linevar.source');
         set
            work.&workroot.line
            end = eof
            ;
         put 'Compute before ' name ';';
         if NOT noline then put 'Line @' reportStartsAtColumn name formatspec ';';
         put 'Endcomp;';
    
      run;
    
      /*
      / Write statements associated with the computed shareColVars
      /-------------------------------------------------------------------*/
      proc sort data=&workmeta out=work.&workroot.shcv;
         where .z LT shareColVar LE shareColVar0;
         by shareColVar;
      run;
      %if &syserr GT 0 %then
      %do;
         %put %str(RTER)ROR: &sysmacroname: The PROC SORT step, for shareColVars, ended with a non-zero return code.;
         %goto macerror;
      %end;
    
      /*
      / This is the regular way to define SHCV.
      / Modifications for OVERALLSUMMARY are done below.
      /
      / jhk:2
      / Changed condition Not &overallsummaryflag to sharecolvarflag
      /-------------------------------------------------------------*/
      %if &shareColVarFlag %then   
      %do;
         data _null_;
            file &workroot('SHCV.source');
            set
               work.&workroot.shcv
               end = eof;
               
            if _N_ eq 1 then do;
               call symput('columnoffirstshcv', put(column, 6.0));
            end;               
            if NOT eof then
            do;
               put 'Break before ' name '/ summarize;';
               put 'Compute before ' name ';';
               put +3 '   __temp__ = "' name '";';
               put +3 'endcomp;';
            end;
            else
            do;
               put 'Define __temp__ / id computed width=' width;
               /* jhk:2 - removed condition %if &overallsummary=1 & &overallsummaryflag=0 on the following statement */
               put +3 'Noprint';
               if flowvar then put +3 'Flow';
               if index(label, "'") gt 0 then
                  put +3 '%nrstr(' label $quote. ');';
               else 
                  put +3 "'" label +(-1) "';";
                                      
               /*  jkh:2
               /   If not flowvar, add indent to name.
               /   YW001: Moved codes, which assign value of __temp__, to
               /   SHCV1.source. Assign value of __temp__ to variable name.
               /-----------------------------------------------------------
               /   YW001: Add a condition to set the value of __temp__
               /----------------------------------------------------------*/                              
               put 'Compute __temp__ / character length=200;';
               put +3 "if missing(_break_) then do;";
               put +3 '   if ' name ' ne "" then ';
               put +3 '      __temp__ = "' name '";'; 
               put +3 '   else __temp__ = "";';    
               put +3 'end;';            
               put +3 'endcomp;';
    
               /*
               / Add __TEMP__ to the columns parameter
               /---------------------------------------------*/
               length string result $5000;    /* jhk:2 - increated from 500 to 5000 */
               string = symget('COLUMNS');
               rx = rxparse('$p <'||trim(name)||'> $s TO =1 " __TEMP__"');
               call rxchange(rx,1,trim(string),result);
               call rxfree(rx);
               call symput('COLUMNS',trim(result));
            end;
         run;
         %if &syserr GT 0 %then
         %do;
            %put %str(RTER)ROR: &sysmacroname: The DATA STEP to write Share column variable statments ended with a non-zero return code.;
            %goto macerror;
         %end;

         /*
         /  YW002: Prepare SHCV1.source which defines length of __temp__ and 
         /  re-assigns value of __temp__ so that __temp__ can be more than $200
         /--------------------------------------------------------------------*/
         data _null_;
            file &workroot('SHCV1.source');
            set work.&workroot.shcv end=eof;                        
            retain maxlength &templength;
            
            if flowvar then 
               maxlength=max(length + abs(indent) * int(2 * length/max(1, width)), maxlength);
            else
               maxlength=max(length + abs(indent) * 2, maxlength);
               
            if _n_ gt 1 then put +3 'else';                
                
            put +3 'if trim(left(__temp__)) eq trim(left("' name '")) then';
            
            if not split then    
            do;
               if indent GT 0 then put +3 '   __temp__ = repeat(" ",' indent ')||put(' name ',' formatspec ');';
               else                put +3 '   __temp__ =                         put(' name ',' formatspec ');';
            end;
            else put +3 '   __temp__ = ' name ';';
            
            if eof then do;
               call symput ('templength', put(int(maxlength), 6.0));
            end;   
         run;
         
      %end; /* end-if on &shareColVarFlag */
      
      /*
      / jhk2:
      / The output file SHVC.source has 0 lines, so there is NOTHING to include
      / in the PROC REPORT STEP.
      / Removed old comment here and removed the codes that modify SHCV and &COLUMNS
      /----------------------------------------------------------------------------*/
      %else
      %do;
         %put COLUMNS=&columns;
         data _null_;
            file &workroot('SHCV.source');
            put ' ';
            stop;
         run;
         %if &syserr GT 0 %then
         %do;
            %put %str(RTER)ROR: &sysmacroname: DATA STEP to modify COLUMNS ended with a non-zero return code.;
            %goto macerror;
         %end;
      %end;    
    
      /*
      / Write define statements
      /-------------------------------------*/
      data _null_;
         file &workroot('DEFINE.source');
         set
            &workmeta
            ;
         if NOT computed;
         if column then
         do;
            put 'Define ' name '/';
            if computed then put +3 'Computed';
            
            if order then
            do;
               put +3 'Order Order=' ordermethod;
               if descending then put +3 'Descending';
            end;
            if idvar    then put +3 'ID';
            if display  then put +3 'Display';
            %if &sharecolvarflag %then
            %do;
               put +3 'Noprint';
            %end;            
            %else %do;           
               if noprint  then put +3 'Noprint';
            %end;
    
            /*
            / jhk: 2
            / added processing to if name EQ '__TEMP__' AND flowvar.
            / Added NOT Sharecolvar to if flowvar. 
            /-------------------------------------------------------*/
            if      name EQ '__TEMP__' AND flowvar then put +3 'Flow';
            else if NOT Sharecolvar AND flowvar then put +3 'Flow';
            
            if not missing(justify) then put +3 justify;
            if not missing(varspacing) then put +3 'Spacing=' varspacing;
            if not missing(width) then put +3 'Width=' width;
            if formatl GT 0 then put +3 'Format=' formatspec;
            if not missing(label)
               then if index(label, "'") gt 0 then
                       put +6 '%nrstr(' label :$quote. ')';
                    else 
                       put +6 "'" label +(-1)"'";
               else put +6 name  :$quote.;
            put +3 ';';
            
            /* YW002: skip after last share column variable in first PROC REPORT call */
            %if &sharecolvarflag and ( %nrbquote(&sharecolvars) ne ) %then 
            %do;
               if skipvar and ( column ge &columnoffirstshcv ) and ( NOT computebeforepagevar ) and ( NOT byvar ) 
               then do;
                  put 'Break after ' name '/ skip;';
               end;
            %end;
            %else %if ( NOT &sharecolvarflag ) %then
            %do;
               if skipvar then
               do;
                  put 'Break after ' name '/ skip;';
               end;
            %end;
                         
            %if ( not &sharecolvarflag ) %then 
            %do;
               if pagevar then
               do;
                  put 'Break after ' name '/ page;';
               end;               
            %end;
    
         end; /* end-if on column */
      run;
      %if &syserr GT 0 %then
      %do;
         %put %str(RTER)ROR: &sysmacroname: The DATA STEP to write DEFINE statments ended with a non-zero return code.;
         %goto macerror;
      %end;
            
      /*
      /  YW002: If &SHARECOLVARS and/or &BYVARS is not blank, loop:
      /  1. If &timethroughs equals 1, looping over &BYVARS as follows:
      /     a) Get a data set with only one &byvars group     
      /     b) Call PROC REPORT to create a data set.
      /     c) Concatenate data set together.
      /     d) Change timethroughs to 2.
      /  2. If &timethroughs equals 2, loop over groups of &NOWIDOWVAR as follows:
      /     a) Add a new variable (__temp__var) to mark the unique &nowidowvar group
      /     b) Create a data set with only one records.
      /     c) Delet the temporary file
      /     d) Re-directory output to the temporary file
      /     e) Run PROC REPORT to create report
      /     f) If first loop, Count how many pages (panels) in the temporary file
      /     g) If first loop or fitted page just be output, create a subdataset which 
      /        includes a group of &nowidowvar and go to step c.
      /     h) Check if the report fit on one page (may have multiple panels)
      /     i) If not fit, Create a new subset to had one more &nowdiowvar
      /        value, create a subdataset and goto step c.
      /     j) If fit, Create a new subset to had one less &nowdiowvar
      /        value, create a subdataset and goto step c.
      /     k) If fitted page is found, re-direct output to final output destination 
      /        and go to step e.
      /     l) If there are still &nowidowvar groups, create a subdataset and goto step c.
      /---------------------------------------------------------------------------------*/          
      %let byvarloops=0;
      %let nobsflag=1;
      
      %do %until (&nobsflag eq 0);
                 
         %let byvarloops=%eval(&byvarloops + 1);
    
         /* 
         / YW002: Get a data set with only one &byvars group 
         /------------------------------------------------------*/          
         %if &shareColVarFlag and ( %nrbquote(&ByVars) ne ) %then
         %do;    
            %let nobsflag=0;
                               
            data &workroot.loopdsetin &workroot.subdsetin;
               %if &byvarloops gt 1 %then 
               %do;
                  set &loopdsetin;
               %end;
               %else %do;
                  set &dsetin;
               %end;
               by &byvars;
               retain __temp__ 0;
               drop __temp__;
               
               if __temp__ eq 0 then output &subdsetin;
               else do;
                  output &loopdsetin;               
                  call symput('nobsflag', '1');
               end;
                                      
               if %if %qupcase(%scan(&byvars, -1, %str( ))) eq NOTSORTED %then 
                  %do;
                      last.%scan(&byvars, -2, %str( ))
                  %end;
                  %else %do;
                      last.%scan(&byvars, -1, %str( ))               
                  %end; 
                  then __temp__=1;
            run;
            
            %let subdsetin=&workroot.subdsetin;
            %let loopdsetin=&workroot.loopdsetin;
                        
            %if &syserr GT 0 %then
            %do;
               %put %str(RTER)ROR: &sysmacroname: The DATA STEP to apply B&VARS (=&byvars) ended with a non-zero return code.;
               %goto macerror;
            %end;
         %end; /* end-if on &shareColVarFlag and ( &ByVars ne ) */            
         /*
         /  If first loop for &timesthrough equals 2, add a variable to mark a sequence 
         /  of &nowidowvar with same values, re-direct output to a tempoary file. Create 
         /  a report data set with only one record. The tempoary file will be used to count 
         /  how many pages (panels) a record will use.
         /----------------------------------------------------------------------------------*/          
         %else %if ( not &shareColVarFlag ) and ( %nrbquote(&nowidowvar) ne ) and ( &byvarloops eq 1 ) %then
         %do;
            /* add a variable to mark a sequence of &nowidowvar with same values */
            data &workroot.withwidowvar;
               set &dsetin end=end;                             
               %inc &workroot('ORDER.source') / nosource2;               
               if end then
               do;            
                  call symput ('varlvls', put(__temp__page_var, 6.0));
                  call symput ('tltlvls', put( max(1, int((&g_ps - 5) * __temp__page_var /_n_) ), 6.0 ));
               end;               
            run;
       
            %let loopdsetin=&workroot.withwidowvar;
            
            /* Create a report data set with only one record */
            data &workroot.one;
               set &loopdsetin;
               if _n_ eq 1 then output;
            run;  
            
            %let subdsetin=&workroot.one;           
            
            /* get number of footnotes */ 
            proc sql noprint;
               select count(type) into :footer0 from sashelp.vtitle
               where type='F';
               quit;
               
            %if &footer0 eq 0 %then 
            %do;
	       /*
	       / The "F" is simply used to mark the end of a page.
	       /------------------------------------------------*/
               footnote "F";
            %end;   
            
            /* re-direct output to a tempoary file */ 
            proc printto print=_winoutf;
            run;           
                       
         %end;                 
         
         /*
         /  If &nowidowvar is given, data set has been created by PROC REPORT and 
         /  fitted group of &nowidowvar values is found, re-direct output to the final 
         /  output direction, the call of PROC REPORT will create a part of fianl report.
         /--------------------------------------------------------------------------------*/  
         %else %if ( not &shareColVarFlag ) and ( %nrbquote(&nowidowvar) ne ) and &pagefoundflag %then
         %do;      
                                             
            %if &footer0 eq 0 %then 
            %do;
               footnote;
            %end;  
           
            proc printto 
               %if %nrbquote(&ref) ne %then 
               %do;
                  print=&ref
               %end;
               ;
            run;  
          
         %end;                        
         /*
         /  If &nowidowvar is given and data set has been created by PROC REPORT, 
         /  Get a subdatset with current group of &nowdiowvar values.
         /  Send PROC REPROT output to a temporary file to see if it fit a page.
         /--------------------------------------------------------------------------------*/  
         %else %if ( not &shareColVarFlag ) and ( %nrbquote(&nowidowvar) ne ) %then
         %do;              
            %if &subdsetin eq &workroot.nowdvar %then %let subdsetin=&workroot.nowdvar2;
            %else %let subdsetin=&workroot.nowdvar;               
            
            /* Get a subdatset with current group of &nowdiowvar values */
            data &subdsetin;
               set &loopdsetin end=eof;
               where __temp__page_var in (
                  %do j=1 %to &tltlvls;
                     %eval(&initlvl + &j - 1)
                  %end;
               );               
               
               /* delete the last break */
               if eof then do;
                  %inc &workroot('SHCV2.source');
               end;
            run;
            
            /* delete the temporary file */
            proc catalog cat=work.&workroot;
               delete temprpt.output;
            run;
            quit;
            
            %if &footer0 eq 0 %then 
            %do;
               footnote "F";
            %end; 
            
            /* direct output to tempoary file */
            proc printto print=_winoutf;
            run;                                 
         %end;
         /* &nowidowvar is not given, end %do %while loop on &nobsflag */
         %else %do;            
            %let subworkrept=&workrept;
            %let subdsetin=&dsetin;             
            %let nobsflag=0;      
         %end;   
         
         /*
         / Save the current setting of the SAS system option missing
         / Removed comment for jhk:1/4
         /-----------------------------------------------------------*/   
         proc report
            data=&subdsetin
               %if %nrbquote(&dropfrom2) NE %then
               %do;
                  (drop=&dropfrom2)   /* jhk:2 */
               %end;
               /*
               / jhk:2
               / Reset page size for sharecolvar.
               /--------------------------------------------*/       
               %if &sharecolvarflag %then
               %do;
                  out=&subworkrept ls=&g_ls ps=32767
               %end;
               %else
               %do;
                  ls=&g_ls ps=&g_ps
               %end;
            
               list missing split=&split &proptions        
               ;
            column
               &computebeforepagevars
               &columns
               ;
            %inc &workroot('DEFINE.source')  / nosource2;
            %inc &workroot('SHCV.source')    / nosource2;         

            %if not &sharecolvarflag %then 
            %do;
               %inc &workroot('CBPV.source')    / nosource2;            
               %inc &workroot('LINEVAR.source') / nosource2;   
            %end;
            
            %if ( %bquote(&byvars) NE ) and ( not &sharecolvarflag ) %then
            %do;
               by &byvars;
            %end;
            
            /* 
            / jkh:2/2 
            / The BREAK1-5 should only be used in the first call of proc report.
            / The old condition is on overallsumaryflag. 
            / YW002: If &sharecolvars is given, the BREAK1-5 should be used in the
            / first loop (because the variables will not be order variables any more) . 
            / Otherwise, they should be used in the last loop.
            /------------------------------------------------------------------------*/
            %if ( ( &timesthrough EQ 1 ) and ( ( %nrbquote(&nowidowvar) eq ) or ( %nrbquote(&sharecolvars) ne ) ) ) or 
                ( ( &timesthrough EQ 2 ) and ( ( %nrbquote(&nowidowvar) ne ) and ( %nrbquote(&sharecolvars) eq ) ) ) %then         
            %do;
               %if %nrbquote(&break1) NE %then
               %do;
                  break &break1;
               %end;
               %if %nrbquote(&break2) NE %then
               %do;
                  break &break2;
               %end;
               %if %nrbquote(&break3) NE %then
               %do;
                  break &break3;
               %end;
               %if %nrbquote(&break4) NE %then
               %do;
                  break &break4;
               %end;
               %if %nrbquote(&break5) NE %then
               %do;
                  break &break5;
               %end;
            %end;
         run;

         %if &syserr GT 0 or %length(&syserrortext) gt 0 %then  /*LS001*/
         %do;
            %put %str(RTER)ROR: &sysmacroname: The REPORT ended with a non-zero return code.;
            %goto macerror;
         %end;
         
         /*
         /  YW002: Move data step here, so that the code can apply to all &byvars group
         /  This is only for processing the data set created by PROC REPORT.
         /-----------------------------------------------------------------------------*/ 
         %if &shareColVarFlag %then
         %do;      
            
            /* YW002: Add the &byvars into &subworkrept data set */            
            %if %nrbquote(&byvars) ne %then
            %do;
               data &subworkrept;
                  if _n_ eq 1 then set &subdsetin;
                  retain _all_;            
                  set &subworkrept;
               run;
            %end;

            /*
            / Change &WORKREPT (the PROC REPORT OUT= data set) by removing
            / observations for the first few records.
            /
            / jhk:2
            / Change &WORKREPT (the output from PROC REPORT.) This output
            / will be the input the PROC REPORT on the second printing.
            /
            / Remove some records that may cause the pagination to get
            / out of line.
            / Remove when OVERALLSUMMAY the extra records related to
            / ANY EVENT.
            /
            / jhk:2/2
            / Combined two data step separeted by condition 
            / '&computebeforepagevars is not blank' to one step to make the 
            / code easy to read and easy to maintain.
            /----------------------------------------------------------------*/
            %if %nrbquote(&sharecolvars) ne %then
            %do;                                        
               data &subworkrept;                          
                  length __temp__  __flag__ $&templength.;
                  set &subworkrept end=eof;
                  %if %nrbquote(&computebeforepagevars) NE %then  
                  %do;
                     by &computebeforepagevars;
                  %end;
                  
                  /* YW002: Keep the __temp__ before changing it in SHCV1 */
                  drop __flag__;
                  __flag__=__temp__;
                  
                  /* YW002: include SHCV1.source */ 
                  %inc &workroot('SHCV1.source') ;
                  
                  /* 
                  / YW002: Remove higher levels for summary level and indent __temp__ for the 
                  / summary level. This is for more than two sharescolvars. 
                  /---------------------------------------------------------------------------*/ 
                  %do j=1 %to &numofsummarylevels;
                     retain __flag__&j._ 0;
                     drop   __flag__&j._;
                     
                     %if %nrbquote(&computebeforepagevars) NE %then  
                     %do;
                        if first.%scan(&computebeforepagevars,-1) then __flag__&j._ = 0;
                     %end;

                     if (_n_ eq 1) 
                        %if %scan(&overallsummaryvars, &j) ne _NULL_ %then 
                        %do;
                           or ( lag1(%scan(&overallsummaryvars, &j)) ne %scan(&overallsummaryvars, &j))
                        %end;
                     then __flag__&j._ = 0;
                     
                     if upcase(__flag__) eq upcase(_break_) then 
                     do;
                        __flag__&j._ = __flag__&j._ + 1;
                        if (__flag__&j._ ge &j) and 
                           (__flag__&j._ le &numofsummarylevels ) then delete;
                     end;
                     else if __flag__&j._ eq &numofsummarylevels then
                     do;                      
                         __flag__&j._ = __flag__&j._ + 1;
                        if %scan(&summarylevels, &j, %str( )) gt 0 then
                           __temp__ = repeat(' ',  %scan(&summarylevels, &j, %str( )))||left(__temp__);
                        else 
                           __temp__ = left(__temp__);
                     end; /* end-if on upcase(__flag__) eq upcase(_break_) */
                     
                  %end; /* end of do-to loop */
                                
                  %if %nrbquote(&computebeforepagevars) NE %then  
                  %do;
                     if last.%scan(&computebeforepagevars,-1) and not missing(_BREAK_) then delete;
                  %end;
                  %else
                  %do;
                     if eof and not missing(_BREAK_) then delete; 
                  %end;                  
               run;           
            
            %end;  /* end-if on &sharecolvars ne */
            
            /* YW002: Concatenate datasets for each &BYVARS together */            
            %if %nrbquote(&byvars) ne %then
            %do;             
               data &workrept;
                  set %if &byvarloops gt 1 %then 
                      %do;
                         &workrept 
                      %end;   
                      &subworkrept;
               run;
            %end;
            
         %end; /* end-if on &shareColVarFlag and ( &ByVars ne ) */
         
         /* 
         /  YW002: If &nowidowvar is given, check if the output fit the page. 
         /  The step is as follows:
         /  1. Use the first record to create a report.
         /  2. Count how many pages (panels) in the report.
         /  3. Create a subdataset which includes a group of &nowidowvars.
         /  4. Create a temporary report
         /  5. Check if the report fit on one page (may have multiple panels)
         /  6. If not fit, Create a new subset to had one more &nowdiowvar
         /     value and repeate step 4-6 until a fit is found.
         /  7. If fit, Create a new subset to had one less &nowdiowvar
         /     value and repeate step 4-5 and 7 until a not fit is found.
         /  8. Create the data set using the fitted &nowidowvars
         /------------------------------------------------------------------*/           
         
         /*
         / Use the first record to create a report.
         / Count how many pages (panels) in the report.
         /------------------------------------------------------*/
         %if ( not &shareColVarFlag ) and ( %nrbquote(&nowidowvar) ne ) and (&byvarloops eq 1) %then
         %do;
            proc printto;
            run;
            
            data _null_;
               infile _winoutf truncover end=end;              
               input ;
               
               if end then
               do;
                  call symput('panels', put(_n_, 6.0));
               end;
            run;                
         %end;  
         /* 
         / if a fitted &nowidowvar group is found, re-set macro variables for next group 
         /------------------------------------------------------------------------------*/
         %else %if ( not &shareColVarFlag ) and ( %nrbquote(&nowidowvar) ne ) and &pagefoundflag %then
         %do;
            
            /*
            /  If no more groups, exit from loop.
            /-----------------------------------------------------*/           
            %if %eval(&initlvl + &tltlvls -1) ge &varlvls %then
            %do;
               %let nobsflag=0;               
            %end;
        
            /*
            /  Set macro variables for sub-setting the data set
            /  pages:         how many pages a &nowidowvar value fit.
            /  oldfit:        if previous group of &nowdiowvar fits on one page
            /  subdsetin:     next subset data set name.
            /  pagefoundflag: flag to mark if a fitted page is found
            /  initlvl:       the __temp__var value for the first &nowidowvar
            /                 value in next loop
            /------------------------------------------------------------------*/       
            %let pages=1;
            %let oldfit=0;                        
            %let subdsetin=&workroot.nowdvar;
            %let pagefoundflag=0;
            %let initlvl=%eval(&initlvl + &tltlvls);           
         %end;
         /*
         /  If  a fitted &nowidowvar group is not found,  do follows:
         /  1. Read in the report created with current group of &nowidowvars
         /  2. Check if the report fit on one page (may have multiple panels)
         /  3. If not fit, set macro variables used with loop and have one more 
         /     &nowdiowvar value. Goto "%do %until (&nobsflag eq 0)" to create
         /     subdataset and new temporary report.
         /  4. If fit, set macro variables used with loop and have one less 
         /     &nowdiowvar value. Goto "%do %until (&nobsflag eq 0)" to create
         /     subdataset and new temporary report.
         /---------------------------------------------------------------------*/
         %else %if (not &shareColVarFlag) and ( %nrbquote(&nowidowvar) ne ) %then
         %do;             
            proc printto; 
            run;
            
            /* Check if current &nowidowvars group fit on one page */                
            data _null_;
               infile _winoutf truncover end=end;            
               input ;
            
               if end then 
                  if ( _n_ - &panels * &pages ) gt 0 then
                     call symput('fit', '1');
                  else
                     call symput('fit', '-1');
            run;
     
            /* no more records, output current group */
            %if ( ( &fit lt 0 ) and ( %eval(&initlvl + &tltlvls -1) ge &varlvls )) %then
            %do;
               %let pagefoundflag=1;            
            %end;       
            /* does not fit, but only one group, increase value of pages */
            %else %if ( &fit gt 0 ) and ( &tltlvls eq 1 ) %then
            %do;
               %let pages=%eval(&pages + 1);
               %let fit=-1;
               %let tltlvls=%eval(&tltlvls + 1);
            %end;               
            /* not fit in last group, but fit in this group, output current group */
            %else %if ( ( &oldfit gt 0 ) and ( &fit lt 0 ) ) %then
            %do;
               %let pagefoundflag=1;
            %end;
            /* fit in last group, but not fit in this group, output previous group */
            %else %if ( ( &oldfit lt 0 ) and ( &fit gt 0 ) ) %then
            %do;            
               %if &subdsetin eq &workroot.nowdvar %then %let subdsetin=&workroot.nowdvar2;
               %else %let subdsetin=&workroot.nowdvar;                           
               %let tltlvls=%eval(&tltlvls - 1);
               %let pagefoundflag=1;
            %end;
            /* does not fit, remove one group */
            %else %if &fit gt 0 %then %do;
               %let tltlvls=%eval(&tltlvls - 1);
            %end;
            /* not enough, add one more group */
            %else %if &fit lt 0 %then %do;
               %let tltlvls=%eval(&tltlvls + 1);
            %end;
   
            %let oldfit=&fit;
               
         %end; /* end-if on ( not &shareColVarFlag ) and ( %nrbquote(&nowidowvar ne ) */            
         
      %end; /* end of do-until on &nobsflag */
        
      /*
      / SHARECOLVARFLAG parameter is 1.
      /  1) no output was produced
      /  2) need to modify work.&workroot.rept
      /  3) go back and reprint data
      /  4) make workmeta back to original removing
      /     the SHARECOLVARS from the COLUMN variable.
      /  5) Change temp from COMPUTED to DISPLAY
      / jhk:2
      / Changed OVERALLSUMARYFLAG to SHARECOLVARFLAG
      /-----------------------------------------------*/
      %if ( %nrbquote(&shareColVars) ne ) and &shareColVarFlag %then
      %do;
         %let workmeta=&workmeta.3;
         data &workmeta;
            set work.&workroot.metadata;
    
            if name EQ '__TEMP__' then
            do;
               display  = 1;
               computed = 0;
               skipvar  = 0;
            end;
            else if sharecolvar then
            do;
               column = .;
            end;
            
            /* YW002: column after last share column variables should not be orderred */
            if ( column ge &columnoffirstshcv ) and ( NOT computebeforepagevar ) and ( NOT byvar ) 
            then do;
               order=0;
               skipvar=0;
            end;
    
            if noprint and ( NOT computebeforepagevar ) and ( NOT byvar ) then
            do;
               /*
               / jhk:2
               / Add noprint variables, which are not in COMPUTEBEFOREPAGEVAR to 
               / macro variable DROPFROM and remove these variables from the 
               / columns parameter
               /----------------------------------------------------------------*/
               column  = .;
               length dropfrom2 $5000;
               dropfrom2 = symget('DROPFROM2');
               dropfrom2 = trim(dropfrom2)||' '||name;
               call symput('DROPFROM2',trim(dropfrom2));
    
               length string result $5000;
               string = symget('COLUMNS');
               rx = rxparse('$p <'||trim(name)||'> $s TO " "');
               call rxchange(rx,1,trim(string),result);
               call rxfree(rx);
               call symput('COLUMNS',trim(result));
            end;
            drop dropfrom2 string result rx;
         run;
         
         %put %str(RTN)OTE: &sysmacroname: Modified COLUMNS=&columns;
        
      %end; /* end-if on &shareColVarFlag */
      
      %if not &shareColVarFlag %then
      %do;
         %let timesthrough=%eval(&timesthrough + 1);      
      %end;
    
      %let dsetin             = &workrept;
      %let shareColVarFlag    = 0;   /* jhk:2 */
      %let numofsummarylevels = 0;
  
   %end; /* end of do-while loop on &timesthrough le 2 */

 %goto exit;

 %MacERROR:
   %let g_abort=1;
   %put %str(RTE)RROR: &sysmacroname: Ending with error(s), setting G_ABORT=&g_abort and calling %nrstr(%tu_abort);
   %tu_abort()

 %exit:
   %tu_tidyup(rmdset=&workroot.:,glbmac=NONE);
   
   %if &g_debug LT 5 %then
   %do;     
      proc datasets nowarn nolist lib=work;
         delete &workroot:(memtype=cat);
         run;
      quit;
   %end;
   %if NOT %sysfunc(fileref(&workroot)) %then
   %do;
      filename &workroot clear;
      filename _winoutf ;
   %end;
   %put %str(RTN)OTE: &sysmacroname: ending execution.;

%mend tu_display;

