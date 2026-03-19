/*
|
| Macro Name:       td_dm5
|
| Macro Version:    1
|
| SAS Version:      8
|
| Created By:       Yongwei Wang
|
| Date:             10DEC2004
|
| Macro Purpose:    A macro to create IDSL standard display DM5
|
| Macro Design:     Procedure style.
|
| Input Parameters:
|
| Name                Description                                       Default
| ----------------------------------------------------------------------------------------
| ACROSSVAR           Variable to transpose the data across to make     &g_trtcd
|                     columns of results. This is passed to the proc
|                     transpose ID statement hence the values of this
|                     variable will be used to name the new columns.
|                     Typically this will be the code variable
|                     containing treatment.
|                     Valid Values:
|                     Blank
|                     Name of a SAS variable that exists in
|                     DSETINNUMER
|
| ACROSSVARDECODE     A variable or format used in the construction of  &g_trtgrp
|                     labels for the result columns.
|                     Valid Values:
|                     If DENORMYN is not Y, blank
|                     Otherwise:
|                     Blank
|                     Name of a SAS variable that exists in
|                     DSETINNUMER
|                     An available SAS format
|
| BREAK1 BREAK2       For input of user-specified break statements      (Blank)
| BREAK3 BREAK4       Valid Values: valid PROC REPORT BREAK statements
| BREAK5              (without "break")
|                     The value of these parameters are passed
|                     directly to PROC REPORT as:
|                     BREAK &break1;
|
| BYVARS              By variables. The variables listed here are       (Blank)
|                     processed as standard SAS by variables
|                     Valid Values: one or more SAS variable names
|                     No formatting of the display for these variables
|                     is performed by %tu_display.  The user has the
|                     option of the standard SAS BY line, or using
|                     OPTIONS NOBYLINE and #BYVAL #BYVAR directives in
|                     title statements
|
| CENTREVARS          Variables to be displayed as centre justified     (Blank)
|                     Valid Values: one or more variable names that
|                     are also defined with COLUMNS
|                     Variables not appearing in any of the parameters
|                     CENTREVARS, LEFTVARS, or RIGHTVARS will be
|                     displayed using the PROC REPORT default.
|                     Character variables are left justified while
|                     numeric variables are right justified
|
| CODEDECODEVARPAIRS  Specifies code and decode variable pairs. Those   raceccd racec
|                     variables should be in parameter
|                     GROUPBYVARSNUMER. One variable in the pair will
|                     contain the code and the other will contain
|                     decode.
|                     Valid Values:  Blank or a list of SAS variable
|                     names in pairs that are given in
|                     GROUPBYVARSNUMER
|
| COLSPACING          The value of the between-column spacing           2
|                     Valid Values: positive integer
|
| COLUMNS             A PROC REPORT column statement specification.     raceccd racec
|                     Including spanning titles and variable names      summarylevel
|                     Valid Values: one or more variable names plus     tt_ac:
|                     other elements of valid PROC REPORT COLUMN
|                     statement syntax
|
| COMPLETETYPESVARS   Specify a list of variables which are in          _ALL_
|                     GROUPBYVARSANALY and the COMPLETETYPES given by
|                     PSOPTIONS should be applied to. If it equals
|                     _ALL_, all variables in GROUPBYVARSANALY will be
|                     included.
|                     Valid Values:
|                     _ALL_
|                     A list of variable names which are in
|                     GROUPBYVARSANALY
|
| COMPUTEBEFOREPAGEL  See Unit Specification for HARP Reporting Tools   (Blank)
| INES                TU_LIST[5] for complete details
|
| COMPUTEBEFOREPAGEV  See Unit Specification for HARP Reporting Tools   (Blank)
| ARS                 TU_LIST[5] for complete details
|
| COUNTDISTINCTWHATV  Variable(s) that contain values to be counted     &g_centid
| AR                  uniquely within any output grouping.              &g_subjid
|                     Valid Values:
|                     Blank
|                     Name of one or more SAS variables that exists in
|                     DSETINNUMER
|
| DDDATASETLABEL      Specifies the label to be applied to the DD       DD dataset for
|                     dataset                                           table DM5
|                     Valid Values:
|                     a non-blank text string
|
| DEFAULTWIDTHS       Specifies column widths for all variables not     racec 36
|                     listed in the WIDTHS parameter
|                     Valid Values: values of column names and numeric
|                     widths such as form valid syntax for a SAS
|                     LENGTH statement
|                     For variables that are not given widths through
|                     either the WIDTHS or DEFAULTWIDTHS parameter
|                     will be width optimised using:
|                     MAX (variables format width,
|                     width of  column header)
|
| DESCENDING          List of ORDERVARS that are given the PROC REPORT  (Blank)
|                     define statement attribute DESCENDING
|                     Valid Values: one or more variable names that
|                     are also defined with ORDERVARS
|
| DSETINDENOM         Input dataset containing data to be counted to    ardata.race
|                     obtain the denominator. This may or may not be
|                     the same as the dataset specified to
|                     DSETINNUMER.
|                     Valid Values:
|                     &g_popdata 
|                     any other valid SAS dataset reference
|
| DSETINNUMER         Input dataset containing data to be counted to    ardata.race
|                     obtain the numerator.
|                     Valid Values:
|                     Valid sas dataset name
|
| FLOWVARS            Variables to be defined with the flow option      racec
|                     Valid Values: one or more variable names that
|                     are also defined with COLUMNS
|                     Flow variables should be given a width through
|                     the WIDTHS.  If a flow variable does not have a
|                     width specified, the column width will be
|                     determined by
|                     MIN(variables format width,
|                     width of  column header)
|
| FORMATS             Variables and their format for display.           (Blank)
|                     Valid Values: values of column names and formats
|                     such as form valid syntax for a SAS FORMAT
|                     statement
|
| GROUPBYVARPOP       Specifies a list of variables to group by when    &g_trtcd
|                     counting big N using %tu_addbignvar. Usually one
|                     variable &g_trtcd.
|                     It will be passed to GROUPBYVARS of
|                     %tu_addbignvar. See Unit Specification for HARP
|                     Reporting Tools TU_ADDBIGNVAR[7]
|                     Required if ADDBIGNYN =Y
|                     Valid Values:
|                     Blank if ADDBIGNYN=N
|                     Otherwise, a list of valid SAS variable names
|                     that exist in population dataset created by
|                     %tu_freq's calling %tu_getdata
|
| GROUPBYVARSDENOM    Variables in DSETINDENOM to group the data by     &g_trtcd
|                     when counting to obtain the denominator.
|                     Valid Values:
|                     Blank, _NONE_ (to request an overall total for
|                     the whole dataset)
|                     Name of a SAS variable that exists in
|                     DSETINDENOM
|
| GROUPBYVARSNUMER    Variables in DSETINNUMER to group the data by,    &g_trtcd
|                     along with ACROSSVAR, when counting to obtain     (racec='n';
|                     the numerator. Additionally a set of brackets     raceccd='0')
|                     may be inserted within the variables to generate  racec raceccd
|                     records containing summary counts grouped by
|                     variables specified to the left of the brackets.
|                     Summary records created may be populated with
|                     values in the grouping variables by specifying
|                     variable value pairs within brackets, seperated
|                     by semi colons. eg aesoccd aesoc(aeptcd=0;
|                     aept="Any Event";) aeptcd aept.
|                     Valid Values:
|                     Blank
|                     Name of one or more SAS variables that exist in
|                     DSETINNUMER
|                     SAS assignment statements within brackets
|
| IDVARS              Variables to appear on each page if the report    racec
|                     is wider than 1 page. If no value is supplied to
|                     this parameter then all displayable order
|                     variables will be defined as IDVARS
|                     Valid Values: one or more variable names that
|                     are also defined with COLUMNS
|
| LABELS              Variables and their label for display. For use    (Blank)
|                     where label for display differs to the label in
|                     the display dataset.
|                     Valid Values: pairs of variable names and labels
|
| LEFTVARS            Variables to be displayed as left justified       (Blank)
|                     Valid Values: one or more variable names that
|                     are also defined with COLUMNS
|
| LINEVARS            List of order variables that are printed with     (Blank)
|                     LINE statements in PROC REPORT
|                     Valid Values: one or more variable names that
|                     are also defined with ORDERVARS
|                     These values shall be written with a BREAK
|                     BEFORE when the value of one of the variables
|                     changes. The variables will automatically be
|                     defined as NOPRINT
|
| NOPRINTVARS         Variables listed in the COLUMN parameter that     summaryLevel
|                     are given the PROC REPORT define statement        raceccd
|                     attribute noprint.
|                     Valid values: one or more variable names from
|                     DSETIN that are also defined with COLUMNS
|                     These variables are ORDERVARS used to control
|                     the order of the rows in the display.
|
| NOWIDOWVAR          Variable whose values must be kept together on a  (Blank)
|                     page
|                     Valid Values: names of one or more variables
|                     specified in COLUMNS
|
| ORDERDATA           Variables listed in the ORDERVARS parameter that  (Blank)
|                     are given the PROC REPORT define statement
|                     attribute order=data
|                     Valid Values: one or more variable names that
|                     are also defined with ORDERVARS
|                     Variables not listed in ORDERFORMATTED,
|                     ORDERFREQ, or ORDERDATA are given the define
|                     attribute order=internal
|
| ORDERFORMATTED      Variables listed in the ORDERVARS parameter that  (Blank)
|                     are given the PROC REPORT define statement
|                     attribute order=formatted
|                     Valid Values: one or more variable names that
|                     are also defined with ORDERVARS
|                     Variables not listed in ORDERFORMATTED,
|                     ORDERFREQ, or ORDERDATA are given the define
|                     attribute order=internal
|
| ORDERFREQ           Variables listed in the ORDERVARS parameter that  (Blank)
|                     are given the PROC REPORT define statement
|                     attribute order=freq
|                     Valid Values: one or more variable names  that
|                     are also defined with ORDERVARS
|                     Variables not listed in ORDERFORMATTED,
|                     ORDERFREQ, or ORDERDATA are given the define
|                     attribute order=internal
|
| ORDERVARS           List of variables that will receive the PROC      summaryLevel
|                     REPORT define statement attribute ORDER           raceccd 
|                     Valid Values: one or more variable names that
|                     are also defined with COLUMNS
|
| PAGEVARS            Variables whose change in value causes the        (Blank)
|                     display to continue on a new page
|                     Valid Values: one or more variable names that
|                     are also defined with COLUMNS
|
| POSTSUBSET          SAS expression to be applied to data immediately  (Blank)
|                     prior to creation of the permanent presentation
|                     dataset. Used for subsetting records required
|                     for computation but not for display.
|                     Valid Values:
|                     Blank
|                     A complete, syntactically valid SAS where or if
|                     statement for use in a data step
|
| PROPTIONS           PROC REPORT statement options to be used in       Headline
|                     addition to MISSING
|                     Valid Values: proc report options
|                     The option Missing can not be overridden
|
| PSCLASSOPTIONS      PROC SUMMARY Class Statement Options.             preloadfmt
|                     Valid Values:
|                     Blank
|                     Valid PROC SUMMARY CLASS Options (without the
|                     leading '/')
|                     Eg: PRELOADFMT  which can be used in
|                     conjunction with PSFORMAT and COMPLETETYPES
|                     (default in PSOPTIONS) to create records for
|                     possible categories that are specified in a
|                     format but which may not exist in data being
|                     summarised.
|
| PSFORMAT            Passed to the PROC SUMMARY FORMAT statement. The  raceccd $racehl.
|                     default format $RACEHL is the format for highest
|                     level race categories and racial combinations
|                     Valid Values:
|                     Blank
|                     Valid PROC SUMMARY FORMAT statement part.
|
| PSOPTIONS           PROC SUMMARY Options to use. MISSING ensures      COMPLETETYPES
|                     that class variables with missing values are      MISSING NWAY
|                     treated as a valid grouping. COMPLETETYPES adds
|                     records showing a freq or n of 0 to ensure a
|                     cartesian product of all class variables exists
|                     in the output. NWAY writes output for the lowest
|                     level  combinations of CLASS variables,
|                     suppressing all higher level totals.
|                     Valid Values:
|                     Blank
|                     One or more valid PROC SUMMARY options
|
| RACECCDVAR          Specifies the name of variable which represents   raceccd
|                     collected race code
|                     Valid Values:
|                     A valid SAS character variable name which exists
|                     in &dsetinnumer
|
| RACECVAR            Specifies the name of variable which represents   racec
|                     collected race
|                     Valid Values:
|                     A valid SAS character variable name which exists
|                     in &dsetinnumer
|
| RACEFMT             Specify format which represents the highest       $racehl
|                     level race categories and racial combinations
|                     Valid Values:
|                     A valid SAS format name in the current search
|                     format search path.
|                     Note: the macro will not check if it is valid.
|                     If it is not valid, a SAS error will be created
|
| RESULTPCTDPS        The reporting precision for percentages           0
|                     Valid Values:
|                     0 or any positive integer
|
| RESULTSTYLE         The appearance style of the result columns that   NUMERPCT
|                     will be displayed in the report. The chosen
|                     style will be placed in variable &RESULTVARNAME.
|                     Valid Values:
|                     As documented for tu_percent in [6]. In typical
|                     usage, NUMERPCT.
|
| RIGHTVARS           Variables to be displayed as right justified      (Blank)
|                     Valid Values: one or more variable names that
|                     are also defined with COLUMNS
|
| SHARECOLVARS        List of variables that will share print space.    (Blank)
|                     The attributes of the last variable in the list
|                     define the column width and flow options
|                     Valid Values: one or more SAS variable names
|
| SHARECOLVARSINDENT  Indentation factor for ShareColVars. Stacked      2
|                     values shall be progressively indented by
|                     multiples of ShareColVarsIndent
|                     Valid Values: positive integer
|
| SKIPVARS            Variables whose change in value causes the        (Blank)
|                     display to skip a line
|                     Valid Values: one or more variable names that
|                     are also defined with COLUMNS
|
| SPLITCHAR           The split character used in column labels. Used   ~
|                     in the creation of the label for the result
|                     columns, and in %tu_stackvar, %tu_display (PROC
|                     REPORT). Usually ~
|                     Valid Values: Valid SAS split character.
|
| SPSORTGROUPBYVARSD  Special sort: variables in DSETINDENOM to group   (Blank)
| ENOM                the data by when counting to obtain the
|                     denominator.
|                     Valid Values:
|                     Blank if SPSORTRESULTVARNAME is blank
|                     Otherwise,
|                     Blank
|                     _NONE_
|                     Name of a SAS variable that exists in
|                     DSETINDENOM
|
| SPSORTGROUPBYVARSN  Special sort: variables in DSETINNUMER to group   (Blank)
| UMER                the data by when counting to obtain the
|                     numerator.
|                     Valid Values:
|                     Blank if SPSORTRESULTVARNAME is blank
|                     Otherwise,
|                     Name of one or more SAS variables that exist in
|                     DSETINNUMER
|
| SPSORTRESULTSTYLE   Special sort: the appearance style of the result  (Blank)
|                     data that will be used to sequence the report.
|                     The chosen style will be placed in variable
|                     SPSORTRESULTVARNAME
|                     Valid Values:
|                     As documented for tu_percent in [6]. In typical
|                     usage, NUMERPCT.
|
| SPSORTRESULTVARNAM  Special sort: the name of a variable to be        (Blank)
| E                   created to hold the spSortResultStyle data when
|                     merging the special sort sequence records with
|                     the presentation data records.
|                     Valid values:
|                     Blank
|                     A valid SAS variable name.
|                     Eg tt_spSort.
|                     This variable is likely to be included in the
|                     columns and noprint parameters passed to
|                     tu_list.
|
| TOTALDECODE         Label for the total result column. Usually the    Total
|                     text Total
|                     Valid Values:
|                     Blank
|                     SAS data step expression resolving to a
|                     character.
|
| TOTALFORVAR         Passed to %tu_statswithtotal. Variable for which  &g_trtcd
|                     overall totals are required within all other
|                     grouped class variables. If not specified, no
|                     total will be produced. Can be one or a list of
|                     followings:
|                     1. Blank
|                     2. Name of a variable
|                     3. Variable with sub group of values inside of
|                     ( and ). In this case, the total is for
|                     subgroup of the values listed inside of ( and
|                     )
|                     4. A list of 2 or 3 separated by *. In this
|                     case, the overall total is based on more than
|                     one variable
|                     Valid Values:
|                     Can be one or a list of followings:
|                     1. Blank
|                     2. Name of a variable
|                     3. Variable with sub group of values inside of
|                     ( and )
|                     4. A list of 2 or 3 separated by *
|
| TOTALID             Value used to populate the variable specified in  999
|                     ACROSSVAR on data that represents the overall
|                     total for the ACROSSVAR variable.
|                     If no value is specified to this parameter then
|                     no overall total of the ACROSSVAR variable will
|                     be generated.
|                     Valid values:
|                     Blank
|                     A value that can be entered into &ACROSSVAR
|                     without SAS error or truncation
|
| VARSPACING          Spacing for individual columns                    (Blank)
|                     Valid Values: variable name followed by a
|                     spacing value, e.g.
|                     Varspacing=a 1 b 2 c 0
|                     This parameter does NOT allow SAS variable
|                     lists.
|                     These values will override the overall
|                     COLSPACING parameter.
|                     VARSPACING defines the number of blank
|                     characters to leave between the column being
|                     defined and the column immediately to its left
|
| WIDTHS              Variables and width to display                    (Blank)
|                     Valid Values: values of column names and numeric
|                     widths, a list of variables followed by a
|                     positive integer, e.g.
|
|                     widths = a b 10 c 12 d1-d4 6
|                     Numbered range lists are supported in this
|                     parameter however name range lists, name prefix
|                     lists, and special SAS name lists are not.
|                     Display layout will be optimised by default,
|                     however any specified widths will cause the
|                     default to be overridden
|
|-------------------------------------------------------------------------------
|
| Output: Printed output.
|
| Global macro variables created: NONE
|
|
| Macros called:
|
|(@) tr_putlocals
|(@) tu_abort
|(@) tu_chkvarsexist
|(@) tu_freq
|(@) tu_putglobals
|(@) tu_tidyup
|
| Example:
|    %td_dm5()
|
|-------------------------------------------------------------------------------
| Change Log
|
| Modified By:             Yongwei Wang
| Date of Modification:    9-Aug-2005
| New version number:      1/2
| Modification ID:         YW001
| Reason For Modification: Added check of existance of &dsetinnumer 
|-------------------------------------------------------------------------------
| Modified By:             Yongwei Wang
| Date of Modification:    10-Aug-2005
| New version number:      1/3
| Modification ID:         YW002
| Reason For Modification: Modified the message after calling %tu_chkvarsexist 
|-------------------------------------------------------------------------------
| Modified By:
| Date of Modification:
| New version number:
| Modification ID:
| Reason For Modification:
|
|-------------------------------------------------------------------------------*/

%macro td_dm5(
   ACROSSVAR           =&g_trtcd,          /* Variable to transpose the data across to make columns of results. This is passed to the proc transpose ID statement */
   ACROSSVARDECODE     =&g_trtgrp,         /* A variable or format used in the construction of labels for the result columns. Usually &g_trtgrp */
   BREAK1              =,                  /* Break statements */
   BREAK2              =,                  /* Break statements */
   BREAK3              =,                  /* Break statements */
   BREAK4              =,                  /* Break statements */
   BREAK5              =,                  /* Break statements */
   BYVARS              =,                  /* By variables */
   CENTREVARS          =,                  /* Centre justify variables */
   CODEDECODEVARPAIRS  =raceccd racec,     /* Code and Decode variables in pairs */
   COLSPACING          =2,                 /* Value for between-column spacing */
   COLUMNS             =raceccd racec summarylevel tt_ac:, /* Columns to be included in the listing (plus spanned headers) */
   COMPLETETYPESVARS   =_ALL_,             /* Variables which COMPLETETYPES should be applied to */
   COMPUTEBEFOREPAGELINES=,                /* Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt : labelvar) */
   COMPUTEBEFOREPAGEVARS=,                 /* Names of variables that define the sort order for  Compute Before Page lines */
   COUNTDISTINCTWHATVAR=&g_centid &g_subjid, /* Variable(s) that contain values to be counted uniquely within any output grouping. Eg &g_subjid */
   DDDATASETLABEL      =DD dataset for table DM5, /* Label to be applied to the DD dataset */
   DEFAULTWIDTHS       =racec 36,          /* List of default column widths */
   DESCENDING          =,                  /* Descending ORDERVARS */
   DSETINDENOM         =ardata.race,        /* Input dataset containing data to be counted to obtain the denominator. */
   DSETINNUMER         =ardata.race,       /* Input dataset containing race data to be counted to obtain the numerator. */
   FLOWVARS            =racec,             /* Variables with flow option */
   FORMATS             =,                  /* Format specification (valid SAS syntax) */
   GROUPBYVARPOP       =&g_trtcd,          /* Variables to group by when counting big N */
   GROUPBYVARSDENOM    =&g_trtcd,          /* Variables in DSETINDENOM to group the data by when counting to obtain the denominator. */
   GROUPBYVARSNUMER    =&g_trtcd (racec='n'; raceccd='0') racec raceccd, /* Variables in DSETINNUMER to group the data by when counting to obtain the numerator. */
   IDVARS              =racec,             /* Variables to appear on each page of the report */
   LABELS              =,                  /* Label definitions (var=var label) */
   LEFTVARS            =,                  /* Left justify variables */
   LINEVARS            =,                  /* Order variables printed with LINE statements */
   NOPRINTVARS         =summaryLevel raceccd, /* No print variables, used to order the display */
   NOWIDOWVAR          =,                  /* List of variables whose values must be kept together on a page */
   ORDERDATA           =,                  /* ORDER=DATA variables */
   ORDERFORMATTED      =,                  /* ORDER=FORMATTED variables */
   ORDERFREQ           =,                  /* ORDER=FREQ variables */
   ORDERVARS           =summaryLevel raceccd, /* Order variables */
   PAGEVARS            =,                  /* Variables whose change in value causes the display to continue on a new page */
   POSTSUBSET          =,                  /* SAS expression to be applied to data immediately prior to creation of the permanent presentation dataset */
   PROPTIONS           =Headline,          /* PROC REPORT statement options */
   PSCLASSOPTIONS      =preloadfmt,        /* PROC SUMMARY CLASS Statement Options */
   PSFORMAT            =raceccd $racehl.,  /* Passed to the PROC SUMMARY FORMAT statement. */
   PSOPTIONS           =COMPLETETYPES MISSING NWAY, /* PROC SUMMARY Options to use */                                                                                                                                                                        
   RACECCDVAR          =raceccd,           /* Variable for collected race code */
   RACECVAR            =racec,             /* Variable for collected race */
   RACEFMT             =$racehl,           /* Format for &RACECCDVAR */
   RESULTPCTDPS        =0,                 /* The reporting precision for percentages Valid Values: 0 or any positive integer */                                                                                                                             
   RESULTSTYLE         =NUMERPCT,          /* The appearance style of the result columns that will be displayed in the report: */                                                                                                                            
   RIGHTVARS           =,                  /* Right justify variables */                                                                                                                                                                                     
   SHARECOLVARS        =,                  /* Order variables that share print space */                                                                                                                                                                      
   SHARECOLVARSINDENT  =2,                 /* Indentation factor */                                                                                                                                                                                          
   SKIPVARS            =,                  /* Variables whose change in value causes the display to skip a line */                                                                                                                                           
   SPLITCHAR           =~,                 /* The split character used in column labels. */                                                                                                                                                                  
   SPSORTGROUPBYVARSDENOM=,                /* Special sort: variables in DSETINDENOM to group the data by when counting to obtain the denominator. */                                                                                                        
   SPSORTGROUPBYVARSNUMER=,                /* Special sort: variables in DSETINNUMER to group the data by when counting to obtain the numerator. */                                                                                                          
   SPSORTRESULTSTYLE   =,                  /* Special sort: the appearance style of the result data that will be used to sequence the report. */                                                                                                             
   SPSORTRESULTVARNAME =,                  /* Special sort: the name of a variable to be created to hold the spSortResultStyle data when merging the special sort sequence records with the presentation data records. */                                    
   TOTALDECODE         =Total,             /* Label for the total result column. Usually the text Total */                                                                                                                                                   
   TOTALFORVAR         =&g_trtcd,          /* Variable(s) for which a overall total is required */                                                                                                                                                           
   TOTALID             =999,               /* Value used to populate the variable specified in ACROSSVAR on data that represents the overall total for the ACROSSVAR variable. */                                                                            
   VARSPACING          =,                  /* Column spacing for individual variables */                                                                                                                                                                     
   WIDTHS              =                   /* Column widths */   
   );

   %local MacroVersion;
   %let MacroVersion = 1;

   %include "&g_refdata/tr_putlocals.sas";
   %tu_putglobals()
   
   %local l_prefix l_var_len l_cdvar_len l_rc l_varprefix l_postsubset; 
   %let l_prefix=_TDDM5;
   %let l_var_len=80;
   %let l_cdvar_len=2;
   %let l_varprefix=__temp__;
                                                                     
   %if %qupcase(&g_analy_disp) eq D %then %goto displayit;
   
   /*
   /  Check if value of any macro specific required parameter is blank
   /-------------------------------------------------------------------------*/
   %if %nrbquote(&raceccdvar) eq %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: value of required parameter RACECCDVAR is blank.;
      %let g_abort=1;
   %end;  
   %if %nrbquote(&racecvar) eq %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: value of required parameter RACECVAR is blank.;
      %let g_abort=1;
   %end;  
   %if %nrbquote(&racefmt) eq %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: value of required parameter RACEFMT is blank.;
      %let g_abort=1;
   %end;                                                   
   %if %nrbquote(&dsetinnumer) eq %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: value of required parameter DSETINNUMER is blank.;
      %goto macerr;
   %end;  
   
   /*
   / YW001: Check if &dsetinnumer exist
   /-------------------------------------------------------------------------*/          
   %if %sysfunc(exist(&dsetinnumer)) EQ 0 %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: data set DSETINNUMER(=&dsetinnumer) does not exist.;
      %let g_abort=1;
   %end;        
   
   %if &g_abort eq 1 %then %goto macerr;  
   
   /*
   /  Check if &RACECCDVAR, &RACECVAR, &G_SUBJID and &G_CENTID exists in 
   /  &dsetinnumer.
   /-------------------------------------------------------------------------*/                                                                     
   %let l_rc=%tu_chkvarsexist(&dsetinnumer, &racecvar );      
   %if %nrbquote(&l_rc) ne %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: Variable RACECVAR(=&racecvar) does not exist in DSETINNUMER(=&dsetinnumer).;
      %let g_abort=1;
   %end;  
   
   %let l_rc=%tu_chkvarsexist(&dsetinnumer, &raceccdvar);      
   %if %nrbquote(&l_rc) ne %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: Variable RACECCDVAR(=&raceccdvar ) does not exist in DSETINNUMER(=&dsetinnumer).;
      %let g_abort=1;
   %end;  
   
   %let l_rc=%tu_chkvarsexist(&dsetinnumer, &g_subjid);      
   %if %nrbquote(&l_rc) ne %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: Variable G_SUBJID(=&g_subjid) does not exist in DSETINNUMER(=&dsetinnumer).;
      %let g_abort=1;
   %end;
   
   %let l_rc=%tu_chkvarsexist(&dsetinnumer, &g_centid);      
   %if %nrbquote(&l_rc) ne %then
   %do;
      %put %str(RTE)RROR: &sysmacroname: Variable G_CENTID(=&g_centid) does not exist in DSETINNUMER(=&dsetinnumer).;
      %let g_abort=1;
   %end;
        
   %if &g_abort eq 1 %then %goto macerr;
                   
   /*
   / Add '.' to &racefmt.
   /--------------------------------------------------------------------------*/        
   %if %index(&racefmt., %str(.)) eq 0 %then
   %do;
      %let racefmt=&racefmt..;
   %end;
   
   /*
   / Modify value of &RACECCDVAR to contain only highest level categories of 
   / race
   /--------------------------------------------------------------------------*/
   data &l_prefix.mod1;
      length &raceccdvar $4;
      set &dsetinnumer ;
      
      select (&raceccdvar);
      when ('11')  &raceccdvar='01';  
      when ('12')  &raceccdvar='02';  
      when ('13')  &raceccdvar='03A'; 
      when ('14')  &raceccdvar='03B'; 
      when ('15')  &raceccdvar='03B'; 
      when ('16')  &raceccdvar='03B';     
      when ('17')  &raceccdvar='04';  
      when ('18')  &raceccdvar='05';     
      when ('19')  &raceccdvar='05';    
      otherwise;  
      end;              
   run;
   
   proc sort data=&l_prefix.mod1 out=&l_prefix.sort;
      by &g_centid  &g_subjid &raceccdvar;
   run;
   
   /*
   / 1. Get combination of the race code and decode for each subject
   / 2. Calculate the length of variable &RACECVAR and &RACECCDVAR
   / 3. Output subjects in 'Asian' group twice. One assign &RACECCDVAR and 
   /    &RACECVAR with the sub-group, the other with main group
   /--------------------------------------------------------------------------*/   
   data  &l_prefix.mod2;
      length &l_varprefix.var &l_varprefix.cdvar $2000;
      set &l_prefix.sort end=eof;
      by &g_centid &g_subjid &raceccdvar;
      
      retain &l_varprefix.cdvar_len  &l_varprefix.var_len 2;
      retain &l_varprefix.cdvar &l_varprefix.var '';
      drop &l_varprefix.cdvar_len  &l_varprefix.var_len;
      
      /* get the first race and race code for a subject */
      if first.&g_subjid then 
      do;    
         &l_varprefix.cdvar=&raceccdvar;
         &l_varprefix.var=put(&l_varprefix.cdvar, &racefmt);        
         if &l_varprefix.var eq &l_varprefix.cdvar then
            &l_varprefix.var=&racecvar;                 
      end;
      else do;
         /* if no race code is assigned yet, get the race code from the current record */
         if missing(&l_varprefix.cdvar) then
         do;
            &l_varprefix.cdvar=&raceccdvar;
            &l_varprefix.var=put(&racecvar, &racefmt);        
         end;
         /* if current and previous race code are sub-races, set the race code to high level race */
         else if ( &raceccdvar in  ('03A' '03B') ) and ( &l_varprefix.cdvar in ('03A' '03B' '03')) then 
         do;
            &l_varprefix.cdvar='03';
            &l_varprefix.var=put(&raceccdvar, &racefmt);
         end;                           
         else do;
            /* if curent code is sub-race, set to high level race */
            if &raceccdvar in ('03A' '03B') then &raceccdvar='03';   
            if &l_varprefix.cdvar in ('03A' '03B') then 
            do;
               &l_varprefix.cdvar='03';                
               &l_varprefix.var=trim(left(put(&l_varprefix.cdvar, &racefmt)));
            end;
            if indexw(&l_varprefix.cdvar, &raceccdvar) eq 0 then 
            do;           
               &l_varprefix.cdvar=trim(left(&l_varprefix.cdvar))||' & '||trim(left(&raceccdvar));          
               &l_varprefix.var=trim(left(&l_varprefix.var))||' & '||trim(left(put(&raceccdvar, &racefmt)));
            end;            
         end;               
      end;      
    
      if last.&g_subjid then
      do;         
         /* Change the code and decode for &raceccd=03 */
         if &l_varprefix.cdvar eq '03' then
         do;
            &l_varprefix.cdvar='03C';
            &l_varprefix.var=put(&l_varprefix.cdvar, &racefmt);        
         end;
         
         /* re-order the combined races */ 
         if scan(&l_varprefix.cdvar, 2, ' ') ne '' then
            &l_varprefix.cdvar='999 '||trim(left(&l_varprefix.cdvar));
           
         output;         
           
         /* calculage the length of the variable */            
         &l_varprefix.cdvar_len=max(&l_varprefix.cdvar_len, length(&l_varprefix.cdvar));
         &l_varprefix.var_len=max(&l_varprefix.var_len, length(&l_varprefix.var));                     
           
          /* Outpu sub-group twice */
         if &l_varprefix.cdvar in ('03A' '03B' '03C') then
         do;
            &l_varprefix.cdvar='03';
            &l_varprefix.var=put(&l_varprefix.cdvar, &racefmt);        
            output;
         end;                       
      end;     
      
      if eof then
      do;
         call symput('l_var_len', put(&l_varprefix.var_len, 6.0));
         call symput('l_cdvar_len', put(&l_varprefix.cdvar_len, 6.0));
      end;                                    

   run;
    
   /*
   / Re-set the length of the variable and apply the format.
   /--------------------------------------------------------------------------*/   
   %let l_rc=0;
   data &l_prefix.final;
      length &raceccdvar $&l_cdvar_len. &racecvar $&l_var_len. ;  
      set &l_prefix.mod2;
      format &raceccdvar $&racefmt.;      
      drop &l_varprefix.cdvar &l_varprefix.var ;
      
      &raceccdvar=&l_varprefix.cdvar;
      &racecvar=&l_varprefix.var;
      
      if &raceccdvar eq '03C' then call symput('l_rc', '1');
   run;      
   
   /*             
   / Modify &POSTSUBSET to change value of &RACEC, while value of &RACECCD is 
   / combined and to remove &RACECCD while it equals '03C', if '03C' is not in 
   / data
   /--------------------------------------------------------------------------*/   
   proc sort data=&l_prefix.final out=&l_prefix.fmt(keep=&raceccdvar &racecvar) nodupkey;
      by &raceccdvar;
   run;
   
   data _null_;
      set &l_prefix.fmt end=eof;
      length &l_varprefix.postsubset $32761;      
      retain &l_varprefix.postsubset '' ;

      if scan(&raceccdvar, 2, ' ') ne '' then
         &l_varprefix.postsubset=trim(left(&l_varprefix.postsubset))||" if &raceccdvar eq '"||
                                 trim(left(&raceccdvar))||"' then &racecvar='"||
                                 trim(&racecvar)||"';";
      if eof then
      do;
         if &l_rc eq 0 then
            &l_varprefix.postsubset=trim(left(&l_varprefix.postsubset))||" if &raceccdvar eq '03C' then delete;";
         call symput('l_postsubset', trim(left(&l_varprefix.postsubset)));      
      end;    
   run;  
   
   %let l_postsubset=%nrbquote(&l_postsubset) &postsubset;
   
%DISPLAYIT:
  
   /*
   / Call tu_freq to create final output.
   /--------------------------------------------------------------------------*/   
   %tu_freq(
      acrossColListName       =acrossColList,
      acrossColVarPrefix      =tt_ac,
      acrossVar               =&acrossVar,
      acrossVarDecode         =&acrossVarDecode,
      addBigNYN               =Y,
      BigNVarName             =tt_bnnm,
      break1                  =&break1,
      break2                  =&break2,
      break3                  =&break3,
      break4                  =&break4,
      break5                  =&break5,
      byvars                  =&byVars,
      centrevars              =&centreVars,
      codeDecodeVarPairs      =&codeDecodeVarPairs,
      colspacing              =&colSpacing,
      columns                 =&columns,
      completetypesvars       =&completetypesvars,
      computebeforepagelines  =&computeBeforePageLines,
      computebeforepagevars   =&computeBeforePageVars,
      countDistinctWhatVar    =&countDistinctWhatVar,
      dddatasetlabel          =&dddatasetlabel,
      defaultwidths           =&defaultWidths,
      denormYN                =Y,
      descending              =&descending,
      display                 =Y,
      dsetinDenom             =&dsetinDenom,
      dsetinNumer             =&l_prefix.final,      
      dsetout                 =,
      flowvars                =&flowVars,
      formats                 =&formats,
      groupByVarPop           =&groupByVarPop,
      groupByVarsDenom        =&groupByVarsDenom,
      groupByVarsNumer        =&groupByVarsNumer,
      groupminmaxvar          =,
      idvars                  =&idVars,
      labels                  =&labels,     
      labelvarsyn             =Y,
      leftvars                =&leftVars,
      linevars                =&linevars,
      noprintVars             =&noPrintVars,
      nowidowvar              =&nowidowvar,
      orderdata               =&orderdata,
      orderformatted          =&orderformatted,
      orderfreq               =&orderfreq,
      ordervars               =&ordervars,
      overallsummary          =N,
      pagevars                =&pageVars,
      postSubset              =&l_postSubset,
      proptions               =&proptions,      
      psByvars                =,
      psClass                 =,
      psClassOptions          =&psClassOptions,
      psFormat                =&psformat,      
      psFreq                  =,
      psid                    =,
      psOptions               =&psoptions,     
      psOutput                =,
      psOutputOptions         =,
      psTypes                 =,
      psWays                  =,
      psWeight                =,
      remSummaryPctYN         =Y,
      resultPctDps            =&resultPctDps,
      resultStyle             =&resultStyle,
      resultVarName           =tt_result,
      rightVars               =&rightVars,
      rowLabelVarName         =,
      sharecolvars            =&sharecolvars,
      sharecolvarsindent      =&sharecolvarsindent,
      skipvars                =&skipVars,
      splitChar               =&splitChar,
      spSortGroupByVarsDenom  =&spSortGroupByVarsDenom,
      spSortGroupByVarsNumer  =&spSortGroupByVarsNumer,
      spSortResultStyle       =&spSortResultStyle,
      spSortResultVarName     =&spSortResultVarName,
      spSort2GroupByVarsDenom =,
      spSort2GroupByVarsNumer =,
      spSort2ResultStyle      =,
      spSort2ResultVarName    =,      
      stackvar1               =,
      stackvar2               =,
      stackvar3               =,
      stackvar4               =,
      stackvar5               =,
      stackvar6               =,
      stackvar7               =,
      stackvar8               =,
      stackvar9               =,
      stackvar10              =,
      stackvar11              =,
      stackvar12              =,
      stackvar13              =,
      stackvar14              =,
      stackvar15              =,
      summaryLevelVarName     =summaryLevel,
      totalDecode             =&totalDecode,
      totalForVar             =&totalForVar,
      totalID                 =&totalID,
      varlabelstyle           =SHORT,
      varspacing              =&varSpacing,
      varsToDenorm            =tt_result tt_pct,
      widths                  =&widths
      )
         
   %goto endmac;

%MACERR:
   %put %str(RTE)RROR: &sysmacroname: Ending with error(s);
   %let g_abort = 1;
   %tu_abort()

%ENDMAC:
   %tu_tidyup(
      rmdset=&l_prefix.:,
      glbmac=NONE);
      
   %put %str(RTN)OTE: &sysmacroname: ending execution.;   
      
%mend td_dm5;
