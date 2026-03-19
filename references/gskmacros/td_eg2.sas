/*--------------------------------------------------------------------------------------------------
| Macro Name       : td_eg2.sas
|                 
| Macro Version    : 1
|                 
| SAS version      : SAS v8
|                 
| Created By       : Yongwei Wang (YW62951)
|                 
| Date             : 28-Jul-03
|                 
| Macro Purpose    : This unit shall create a table "Summary of ECG Values" defined in IDSL standard 
|                    data displays identified in the IDSL Data Display Standards. 
|
| Macro Design     : PROCEDURE STYLE
|                 
| Input Parameters :
|
| NAME              DESCRIPTION                                                DEFAULT
|--------------------------------------------------------------------------------------------------- 
| ANALYSISVARDPS	Specifies the number of decimal places to which data was   (Blank)
|                   captured. If not supplied, the format on the variables in 
|                   DSETIN will be used (if they exist). If different numbers 
|                   of DPs are required for the different ANALYSISVARS, the 
|                   parameter may be a list of: variable name = number of DPs
|                   The decimal places part will be saved in a temporary 
|                   variable and the variable name will be passed to the 
|                   ANALYSISVARDPSVAR parameter of %tu_statsfmt. If XMLINFMT 
|                   is not blank, ANALYSISVARDPS will be ignored. If both 
|                   XMLINFMT and ANALYSISVARDPS are blank, the value of 
|                   parameter ANALYSISVARFORMATDNAME of %tu_stats will be 
|                   passed to ANALYSISVARDPSVAR of %tu_statsfmt 
|                   Valid values: Can be one of following three:
|                   1. Blank
|                   2. Number-of-decimal-places
|                   3. variable1 = Number-of-decimal-places  < variable2 = 
|                      Number-of-decimal-places ?>   
|                      The variable1, variable2, ? must be the variables given 
|                      as ANALYSISVARS. See Unit Specification for HARP 
|                      Reporting Tools TU_STATSFMT
|
| ANALYSISVARS	    The variables to be analysed.                               eghr rr qt qtcf qtcb 
|                   Valid values: a list of SAS variables that exist in DSETIN  pr qrs
|                   
| BREAK1-5 	        For input of user-specified break statements                (Blank)
|                   Valid values: valid PROC REPORT BREAK statements (without 
|                   "break"). The value of these parameters are passed 
|                   directly to PROC REPORT as: BREAK &break1;
|
| BYVARS	        By variables. The variables listed here are processed as    (Blank)
|                   standard SAS by variables  
|                   Valid values: one or more variable names from DSETIN 
|                   No formatting of the display for these variables is 
|                   performed by %tu_display.  The user has the option of the 
|                   standard SAS BY line, or using OPTIONS NOBYLINE and #BYVAL 
|                   #BYVAR directives in title statements
|
| CENTREVARS	    Variables to be displayed as centre justified               (Blank)
|                   Valid values: one or more variable names from DSETIN that 
|                   are also defined with COLUMNS Variables not appearing in 
|                   any of the parameters CENTREVARS, LEFTVARS, or RIGHTVARS 
|                   will be displayed using the PROC REPORT default. Character
|                   variables are left justified while numeric variables are 
|                   right justified
|
| COLSPACING	    The value of the between-column spacing                     2
|                   Valid values: positive integer
|
| COLUMNS           A PROC REPORT column statement specification. Including     tt_avid tt_avnm 
|                   spanning titles and variable names                          &g_trtcd &g_trtgrp 
|                   Valid values: one or more variable names from DSETIN plus   tt_bnnm visitnum
|                   other elements of valid PROC REPORT COLUMN statement syntax visit N MEAN STD 
|                                                                               MEDIAN MIN MAX
|
| COMPUTEBEFOREPA	See Unit Specification for HARP Reporting Tools TU_LIST for (Blank)
| GELINES           complete details
|
| COMPUTEBEFOREPA	See Unit Specification for HARP Reporting Tools TU_LIST for (Blank)
| EVARS             complete details
|
| COUNTDISTINCTWH	Name of the variable(s) whose distinct values are counted   &g_centid &g_subjid
| ATVARPOP          when computing big N. Will be passed to 
|                   COUNTDISTINCTWHATVAR of %tu_addbignvar. Parameter is 
|                   required if BIGNVARNAME is given
|                   Valid values: As defined in Unit Specification for HARP 
|                   Reporting Tools TU_ADDBIGNVAR
|
| DDDATASETLABEL	Specifies the label to be applied to the DD dataset         DD dataset for      
|                   Valid values: a non-blank text string                       EG2 table
|
| DEFAULTWIDTHS 	Specifies column widths for all variables not listed in the (Blank)
|                   WIDTHS parameter
|                   Valid values: values of column names and numeric widths 
|                   such as form valid syntax for a SAS LENGTH statement For 
|                   variables that are not given widths through either the 
|                   WIDTHS or DEFAULTWIDTHS parameter will be width optimised 
|                   using: 
|                   MAX (variable's format width, width of  column header)
|
| DESCENDING	    List of ORDERVARS that are given the PROC REPORT define     (Blank)
|                   statement attribute DESCENDING
|                   Valid values: one or more variable names from DSETIN that
|                   are also defined with ORDERVARS
|
| DSETIN        	Specify an analysis dataset                                 ardata.ecg
|                   Valid values: name of an existing dataset meeting an IDSL 
|                   dataset specification .
|
| FLOWVARS       	Variables to be defined with the flow option                tt_avnm
|                   Valid values: one or more variable names from DSETIN that 
|                   are also defined with COLUMNS Flow variables should be 
|                   given a width through the WIDTHS.  If a flow variable does 
|                   not have a width specified, the column width will be 
|                   determined by MIN(variable's format width, width of  
|                   column header)
|
| FORMATS           Variables and their format for display. For use where       (Blank)
|                   format for display differs to the format on the DSETIN.
|                   Valid values: values of column names and formats such as 
|                   form valid syntax for a SAS FORMAT statement
|
| GROUPBYVARPOP	    Specifies a list of variables to group by when counting     &g_trtcd
|                   big N using %tu_addbignvar. Usually one variable &g_trtcd. 
|                   It will be passed to GROUPBYVARS of %tu_addbignvar. It is 
|                   required if BIGNVARNAME is given 
|                   Valid values: Blank, or a list of valid SAS variable names 
|                   that exist in population dataset created by 
|                   %tu_sumstatsincols calling %tu_getdata
| 
| GROUPBYVARSANALY	Specifies the variables whose values define the subgroup    &g_trtcd &g_trtgrp 
|                   combinations for the analysis. The variables can be         visitnum visit 
|                   divided by statements inside of '(' and ')' to represent 
|                   different levels of subgroup. See Purpose of Unit 
|                   Specification for HARP Reporting Tools TU_SUMSTATSINCOLS
|                   for details.
|                   Valid values: A list of valid SAS variable names with 
|                   (optionally) valid SAS statements in bracket. The first 
|                   and last words in the values must be variable names. The 
|                   variable names must exist in DSETIN. The SAS statements 
|                   must be in the format (variable = value;). Variable must 
|                   also appear after the closed bracket. Value must be the 
|                   same type as variable.
|
| IDVARS	        Variables to appear on each page if the report is wider     tt_avid tt_avnm
|                   than 1 page. If no value is supplied to this parameter      &g_trtcd &g_trtgrp
|                   then all displayable order variables will be defined as     tt_bnnm visitnum
|                   IDVARS                                                      visit
|                   Valid values: one or more variable names from DSETIN that 
|                   are also defined with COLUMNS
|
| LABELS            Variables and their label for display. For use where label  (Blank)
|                   for display differs to the label on the DSETIN 
|                   Valid values: pairs of variable names and labels
|
| LEFTVARS          Variables to be displayed as left justified                 (Blank)
|                   Valid values: one or more variable names from DSETIN that
|                   are also defined with COLUMNS
|
| LINEVARS	        List of order variables that are printed with LINE          (Blank)
|                   statements in PROC REPORT
|                   Valid values: one or more variable names from DSETIN that 
|                   are also defined with ORDERVARS These values shall be 
|                   written with a BREAK BEFORE when the value of one of the 
|                   variables changes. The variables will automatically be 
|                   defined as NOPRINT
|
| NOPRINTVARS       Variables listed in the COLUMN parameter that are given the tt_avid &g_trtcd
|                   PROC REPORT define statement attribute noprint              &visitnum
|                   Valid values: one or more variable names from DSETIN that 
|                   are also defined with COLUMNS These variables are ORDERVARS 
|                   used to control the order of the rows in the display
|
| NOWIDOWVAR        Variable whose values must be kept together on a page       (Blank)
|                   Valid values: names of one or more variables specified in 
|                   COLUMNS 
|
| ORDERDATA         Variables listed in the ORDERVARS parameter that are given  (Blank)
|                   the PROC REPORT define statement attribute order=data
|                   Valid values: one or more variable names from DSETIN that 
|                   are also defined with ORDERVARS Variables not listed in 
|                   ORDERFORMATTED, ORDERFREQ, or ORDERDATA are given the 
|                   define attribute order=internal
|
| ORDERFORMATTED    Variables listed in the ORDERVARS parameter that are given  (Blank)
|                   the PROC REPORT define statement attribute order=formatted
|                   Valid values: one or more variable names from DSETIN that 
|                   are also defined with ORDERVARS Variables not listed in 
|                   ORDERFORMATTED, ORDERFREQ, or ORDERDATA are given the 
|                   define attribute order=internal
|
| ORDERFREQ         Variables listed in the ORDERVARS parameter that are given  (Blank)
|                   the PROC REPORT define statement attribute order=freq
|                   Valid values: one or more variable names from DSETIN that 
|                   are also defined with ORDERVARS Variables not listed in 
|                   ORDERFORMATTED, ORDERFREQ, or ORDERDATA are given the 
|                   define attribute order=internal
|
| ORDERVARS         List of variables that will receive the PROC REPORT define  tt_avid tt_avnm
|                   statement attribute ORDER                                   &g_trtcd &g_trtgrp
|                   Valid values: one or more variable names from DSETIN that   tt_bnnm visitnum
|                   are also defined with COLUMNS                               visit
|
| OVERALLSUMMARY    Causes the macro to produce an overall summary line. Use    N
|                   with SHARECOLVARS
|                   Valid values: Y or Yes.  Any other values are treated as 
|                   NO
|
| PAGEVARS          Variables whose change in value causes the display to       (Blank)
|                   continue on a new page
|                   Valid values: one or more variable names from DSETIN that 
|                   are also defined with COLUMNS
|
| POSTSUBSET        Specifies a SAS IF condition (without "IF" in it), which    (Blank)
|                   will be applied to the dataset immediately prior to 
|                   creation of the DD dataset.
|                   Valid values: Blank, or a valid SAS statement that can be
|                   applied to the dataset prior to creation of the DD dataset
|
| PROPTIONS         PROC REPORT statement options to be used in addition to     Headline
|                   MISSING 
|                   Valid values: proc report options. The option 'Missing' can
|                   not be overridden
|
| RIGHTVARS         Variables to be displayed as right justified                (Blank)
|                   Valid values: one or more variable names from DSETIN that 
|                   are also defined with COLUMNS
|
| SHARECOLVARS      List of variables that will share print space. The          (Blank)
|                   attributes of the last variable in the list define the 
|                   column width and flow options
|                   Valid values: one or more variable names from DSETIN AE5 
|                   shows an example of this style of output The formatted 
|                   values of the variables shall be written above each other 
|                   in one column
|
| SHARECOLVARSIN    Indentation factor for ShareColVars. Stacked values shall   (Blank)
| DENT              be progressively indented by multiples of 
|                   ShareColVarsIndent
|                   Valid values: positive integer
|
| SKIPVARS          Variables whose change in value causes the display to skip  tt_avnm &g_trtgrp
|                   a line
|                   Valid values: one or more variable names from DSETIN that
|                   are also defined with COLUMNS
|
| SPLITCHAR         Specifies the split character to be passed to %tu_display   ~
|                   Valid values: one single character
|
| STACKVAR1         Specifies any variables that should be stacked together.    (Blank)
| STACKVAR15        See Unit Specification for HARP Reporting Tools 
|                   TU_STACKVAR for more detail regarding macro parameters that
|                   can be used in the macro call.  Note that the DSETIN 
|                   parameter will be passed by %tu_list and should not be 
|                   provided here
|
| STATSDPS          Specifies decimal places of statistical results of analysis (Blank)
|                   variables.  If the decimal positions for all variables 
|                   given by ANALYSISVARS are the same, it should be a list of 
|                   summary statistic variable name, '+' and an integer number. 
|                   For example, Mean +1 STD +2. The integer number means 
|                   number of decimal places. If any statistic variable in 
|                   STATSLIST is not in STATSDPS, the variable name and +0 will
|                   be automatically added to STATSDPS.  If the decimal 
|                   positions for all variables are not the same, it should be 
|                   a list of: analysis-var = list-described-above. For 
|                   example, heart=Mean +1 STD +2 resp=Mean +2 STD +2 The 
|                   decimal places without the variable name and equals-sign 
|                   will be passed to %tu_statsfmt.
|                   
|                   Valid values: Can be one of following three:
|                   1. Blank
|                   2. Statsdps
|                   3. Variable1 = statsdps  < variable2 = statdps ?>
|                      The variable1, variable2, ? should be the variables 
|                      specified for ANALYSISVARS. 
|                   Statdps is the same as STATSDPS parameter defined in 
|                   %tu_statsfmt. XMLINFMT and STATSDPS are mutually-
|                   exclusive. See Unit Specification for HARP Reporting Tools 
|                   TU_STATSFMT
|
| STATSLIST         Specifies a list of summary statistics to produce. May also N MIN MAX 
|                   specify correct PROC SUMMARY syntax to rename output        MEDIAN STD
|                   variable (N=number MEAN=average)                            MEAN
|                   Valid values: As defined for the STATSLIST parameter of 
|                   %tu_stats. See Unit Specification for HARP Reporting Tools 
|                   TU_STATS
|
| VARLABELSTYLE     Specifies the style of labels to be applied by the          SHORT
|                   %tu_labelvars macro
|                   Valid values: as specified by %tu_labelvars
|
| VARSPACING        Spacing for individual columns                              (Blank)
|                   Valid values: variable name followed by a spacing value, 
|                   e.g. Varspacing=a 1 b 2 c 0. This parameter does NOT allow
|                   SAS variable lists. These values will override the overall 
|                   COLSPACING parameter. VARSPACING defines the number of 
|                   blank characters to leave between the column being defined 
|                   and the column immediately to its left
|
| WIDTHS            Variables and width to display
|                   Valid values: values of column names and numeric widths, a  tt_avnm 14 
|                   list of variables followed by a positive integer, e.g.      &g_trtgrp 11
|                   widths = a b 10 c 12 d1-d4 6. Numbered range lists are      visit 9
|                   supported in this parameter however name range lists, name 
|                   prefix lists, and special SAS name lists are not. Display 
|                   layout will be optimised by default, however any specified 
|                   widths will cause the default to be overridden
|---------------------------------------------------------------------------------------------------
|
|---------------------------------------------------------------------------------------------------
| Output:   1. output file in plain ASCII text format containing a summary in columns data display 
|              matching the requirements specified as input parameters
|           2. SAS data set that forms the foundation of the data display (the "DD dataset").
|
| Global macro variables created:  None
|
| Macros called : 
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_nobs
| (@) tu_chkvarsexist
| (@) tu_putglobals
| (@) tu_sumstatsincols
|
| Example:  %ts_setup();
|           %td_eg2();
|    
|---------------------------------------------------------------------------------------------------
| Change Log :
|
| Modified By :             Yongwei Wang        
| Date of Modification :    13-May-2004
| New Version Number :      1/2
| Modification ID :         YW001
| Reason For Modification : Check the existance of variable EGSEQ in &DSETIN to add 
|                           (where=egseq EQ 1) to &DSETIN
|---------------------------------------------------------------------------------------------------
| Change Log :
|
| Modified By :             Yongwei Wang        
| Date of Modification :    26-May-2004
| New Version Number :      1/3
| Modification ID :         YW002
| Reason For Modification : Added change log for 1/2. Modified the fly-over text for DDDATASETLABEL
|
+-------------------------------------------------------------------------------------------------*/
 

%macro td_eg2(
   ANALYSISVARDPS          =,      /*Number of decimal places  to which data was captured*/
   ANALYSISVARS            =eghr rr qt qtcf qtcb pr qrs, /*Summary statistics analysis variables*/
   BREAK1                  =,      /*Break statements*/
   BREAK2                  =,      /*Break statements*/
   BREAK3                  =,      /*Break statements*/
   BREAK4                  =,      /*Break statements*/
   BREAK5                  =,      /*Break statements*/
   BYVARS                  =,      /*By variables*/
   CENTREVARS              =,      /*Centre justify variables*/
   COLSPACING              =2,     /*Value for between-column spacing*/
   COLUMNS                 =tt_avid tt_avnm &g_trtcd &g_trtgrp tt_bnnm visitnum visit N MEAN STD MEDIAN MIN MAX, /*Columns to be included in the listing (plus spanned headers)*/
   COMPUTEBEFOREPAGELINES  =,      /*Specifies the text to be produced for the Compute Before Page lines (labelkey labelfmt : labelvar)*/
   COMPUTEBEFOREPAGEVARS   =,      /*Names of variables that define the sort order for  Compute Before Page lines*/
   COUNTDISTINCTWHATVARPOP =&g_centid &g_subjid, /*Variables whose distinct values are counted when computing big N*/
   DDDATASETLABEL          =DD dataset for EG2 table, /* Label to be applied to the DD dataset */
   DEFAULTWIDTHS           =,	   /*List of default column widths*/
   DESCENDING              =,	   /*Descending ORDERVARS*/
   DSETIN                  =ardata.ecg, /*Input analysis dataset*/
   FLOWVARS                =tt_avnm, /*Variables with flow option*/
   FORMATS                 =,      /*Format specification (valid SAS syntax)*/
   GROUPBYVARPOP           =&g_trtcd, /*Variables to group by when counting big N */
   GROUPBYVARSANALY        =&g_trtcd &g_trtgrp visitnum visit, /*The variables whose values define the subgroup combinations for the analysis*/
   IDVARS                  =tt_avid tt_avnm &g_trtcd &g_trtgrp tt_bnnm visitnum visit, /*Variables to appear on each page of the report*/
   LABELS                  =,      /*Label definitions (var="var label")*/
   LEFTVARS                =,      /*Left justify variables*/
   LINEVARS                =,      /*Order variables printed with LINE statements*/
   NOPRINTVARS             =tt_avid &g_trtcd visitnum, /*No print variables, used to order the display*/
   NOWIDOWVAR              =,      /*List of variables whose values must be kept together on a page*/
   ORDERDATA               =,      /*ORDER=DATA variables*/
   ORDERFORMATTED          =,      /*ORDER=FORMATTED variables*/
   ORDERFREQ               =,      /*ORDER=FREQ variables*/
   ORDERVARS               =tt_avid tt_avnm &g_trtcd &g_trtgrp tt_bnnm visitnum visit, /*Order variables*/
   OVERALLSUMMARY          =N,     /*Overall summary line at top of tables*/
   PAGEVARS                =,      /*Variables whose change in value causes the display to continue on a new page*/
   POSTSUBSET              =,      /*SAS "IF" condition that applies to the presentation dataset.*/
   PROPTIONS               =Headline, /*PROC REPORT statement options*/
   RIGHTVARS               =,      /*Right justify variables*/
   SHARECOLVARS            =,      /*Order variables that share print space*/
   SHARECOLVARSINDENT      =2,     /*Indentation factor*/
   SKIPVARS                =tt_avnm &g_trtgrp, /*Variables whose change in value causes the display to skip a line */
   SPLITCHAR               =~,     /*Split character*/
   STACKVAR1               =,      /*Create stacked variables (e.g., stackvar1=%str(varsin=invid subjid, varout=st_inv_subj, sepc=/, splitc=~))*/
   STACKVAR2               =,      /*Create stacked variables */
   STACKVAR3               =,      /*Create stacked variables */
   STACKVAR4               =,      /*Create stacked variables */
   STACKVAR5               =,      /*Create stacked variables */
   STACKVAR6               =,      /*Create stacked variables */
   STACKVAR7               =,      /*Create stacked variables */
   STACKVAR8               =,      /*Create stacked variables */
   STACKVAR9               =,      /*Create stacked variables */
   STACKVAR10              =,      /*Create stacked variables */
   STACKVAR11              =,      /*Create stacked variables */
   STACKVAR12              =,      /*Create stacked variables */
   STACKVAR13              =,      /*Create stacked variables */
   STACKVAR14              =,      /*Create stacked variables */
   STACKVAR15              =,      /*Create stacked variables */
   STATSDPS                =MEDIAN +1 MEAN +1 STD +2, /*Number of decimal places of summary statistical resultsI*/
   STATSLIST               =N MIN MAX MEDIAN STD MEAN, /*List of required summary statistics, e.g. N Mean Median. (or N=number MIN=minimum)*/
   VARLABELSTYLE           =SHORT, /*Specifies the label style for variables*/  
   VARSPACING              =,      /*Column spacing for individual variables*/
   WIDTHS                  =tt_avnm 14 &g_trtgrp 11 visit 9 /*Column widths*/              
   );         

   %***--------------------------------------------------------------------***;
   %***- Write details of macro call to log                               -***;
   %***--------------------------------------------------------------------***;
   
   %LOCAL MacroVersion;
   %LET MacroVersion = 1;
 
   %INCLUDE "&g_refdata/tr_putlocals.sas";
   %tu_putglobals() 
   
   %***--------------------------------------------------------------------***;
   %***- IF EGSEQ in the input data set, keep only data with EGSEQ=1      -***;
   %***--------------------------------------------------------------------***;
   
   %IF %nrquote(&DSETIN) NE %THEN %DO;
      %IF %tu_nobs(&DSETIN) GT 0 %THEN %DO;     
         %IF %nrbquote(%tu_chkvarsexist(&DSETIN, EGSEQ)) EQ %THEN %DO;
            %LET DSETIN=&DSETIN (where=(egseq EQ 1));
         %END;
      %END;
   %END;        
    
   %***--------------------------------------------------------------------***;
   %***- Pass everything to tu_sumstatsincols                             -***;
   %***--------------------------------------------------------------------***;
       
   %tu_sumstatsincols(
      %***- parameters that are not the parameter of this macro -***;
      ALIGNYN                  =Y,
      ANALYSISVARNAME          =tt_avnm,
      ANALYSISVARORDERVARNAME  =tt_avid,
      BIGNVARNAME              =tt_bnnm,
      DISPLAY                  =Y,
      LABELVARSYN              =Y,     
      PSBYVARS                 =,
      PSCLASS                  =,
      PSCLASSOPTIONS           =,
      PSFORMAT                 =,
      PSFREQ                   =,
      PSOPTIONS                =MISSING NWAY,
      PSOUTPUT                 =,
      PSOUTPUTOPTIONS          =NOINHERIT,
      PSID                     =,
      PSTYPES                  =,
      PSWAYS                   =,
      PSWEIGHT                 =,
      XMLINFMT                 =,
      XMLMERGEVAR              =,
      
      %***- parameters for tu_sumstatsincols -***;   
      ANALYSISVARDPS           =&ANALYSISVARDPS,
      ANALYSISVARS             =&ANALYSISVARS,
      COUNTDISTINCTWHATVARPOP  =&COUNTDISTINCTWHATVARPOP,
      DSETIN                   =&DSETIN,
      GROUPBYVARPOP            =&GROUPBYVARPOP,
      GROUPBYVARSANALY         =&GROUPBYVARSANALY,
      STATSDPS                 =&STATSDPS,
      STATSLIST                =&STATSLIST,
                                                  
      %***- parameters that will pass to tu_list by tu_sumstatsincols -***;                                                   
      BREAK1                   =&BREAK1,
      BREAK2                   =&BREAK2,
      BREAK3                   =&BREAK3,
      BREAK4                   =&BREAK4,
      BREAK5                   =&BREAK5,
      BYVARS                   =&BYVARS,
      CENTREVARS               =&CENTREVARS,
      COLSPACING               =&COLSPACING,
      COLUMNS                  =&COLUMNS,                      
      COMPUTEBEFOREPAGELINES   =&COMPUTEBEFOREPAGELINES,
      COMPUTEBEFOREPAGEVARS    =&COMPUTEBEFOREPAGEVARS,
      DDDATASETLABEL           =&DDDATASETLABEL,
      DEFAULTWIDTHS            =&DEFAULTWIDTHS,
      DESCENDING               =&DESCENDING,
      FLOWVARS                 =&FLOWVARS,
      FORMATS                  =&FORMATS,
      IDVARS                   =&IDVARS, 
      LABELS                   =&LABELS,                      
      LEFTVARS                 =&LEFTVARS,
      LINEVARS                 =&LINEVARS,
      NOPRINTVARS              =&NOPRINTVARS,
      NOWIDOWVAR               =&NOWIDOWVAR,
      ORDERDATA                =&ORDERDATA,
      ORDERFORMATTED           =&ORDERFORMATTED,
      ORDERFREQ                =&ORDERFREQ,
      ORDERVARS                =&ORDERVARS,
      OVERALLSUMMARY           =&OVERALLSUMMARY,
      PAGEVARS                 =&PAGEVARS,
      POSTSUBSET               =&POSTSUBSET,
      PROPTIONS                =&PROPTIONS,
      RIGHTVARS                =&RIGHTVARS,
      SHARECOLVARS             =&SHARECOLVARS,                     
      SHARECOLVARSINDENT       =&SHARECOLVARSINDENT,   
      SKIPVARS                 =&SKIPVARS,
      SPLITCHAR                =&SPLITCHAR,
      STACKVAR1                =&STACKVAR1,
      STACKVAR10               =&STACKVAR10,
      STACKVAR11               =&STACKVAR11,
      STACKVAR12               =&STACKVAR12,
      STACKVAR13               =&STACKVAR13,
      STACKVAR14               =&STACKVAR14,
      STACKVAR15               =&STACKVAR15,
      STACKVAR2                =&STACKVAR2,
      STACKVAR3                =&STACKVAR3,
      STACKVAR4                =&STACKVAR4,
      STACKVAR5                =&STACKVAR5,
      STACKVAR6                =&STACKVAR6,
      STACKVAR7                =&STACKVAR7,
      STACKVAR8                =&STACKVAR8,
      STACKVAR9                =&STACKVAR9,
      VARLABELSTYLE            =&VARLABELSTYLE,
      VARSPACING               =&VARSPACING,
      WIDTHS                   =&WIDTHS                   
      )                        

   %if &g_abort eq 1 %then %do;
      %tu_abort()
   %end;
      
%mend td_eg2;  



