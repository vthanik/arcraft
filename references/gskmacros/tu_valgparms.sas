/*******************************************************************************
|
| Macro Name:      tu_valgparms
|
| Macro Version:   4 Build 1
|
| SAS Version:     9.1
|                                                             
| Created By:      James McGiffen / Andrew Ratcliffe, RTSL
|
| Date:            13-Dec-2004
|
| Macro Purpose:   To validate the parameters passed to a supported
|                  graphics package macro. Any failing parameters will
|                  result in an RTERROR message being written to the log
|                  and g_abort being set to 1. Because of the large number
|                  of validations that are performed the macro will
|                  be permitted to issue %tu_abort
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME            DESCRIPTION                              REQ/OPT  DEFAULT
| --------------  -----------------------------------      -------  ---------------
| macroname       The graph macro that requires validation   REQ    [blank]
| --------------  -----------------------------------      -------  ---------------
|
| Output: Issues RT messages to the log and sets g_abort
|
| Global macro variables created: NONE
|
| Macros called:
| (@) tu_abort
| (@) tu_chkvarsexist
| (@) tu_chkvartype
| (@) tu_nobs
| (@) tu_putglobals
| (@) tu_tidyup
| (@) tu_unduplst
| (@) tu_words
| (@) tu_getdata
|
| Example:
|          %tu_valgparms(macroname=tu_pktfig);
|
|******************************************************************************
| Change Log
|
| Modified By:              Trevor Welby
| Date of Modification:     31-May-05
| New version/draft number: 01.002
| Modification ID:          TQW9753.01.002
| Reason For Modification: 
|                           The LegendType parameter now has valid 
|                           values of: ACROSS, INLINE and NONE
|                          
|                           Remove %local i dead code
|                       
|                           Verify that Alphabetic Versions of Logical Operators 
|                           are used throughout the code and change if needed.
|
|                           Code revised and made consistent
|
|                           Required parameters veryified as non-blank
|
|                           %tu_abort now permitted added in sections and at the end 
|
|                           The use of %upcase function removed extensively
|                           in line with source code reviewer comment
|
|                           Typographic errors corrected
|
|                           RTERROR messages wording made consistent
| 
|                           The macro now validates TU_PKTFIG package macro parameters
|                           for Set 2 release
|
|                           OUTFILE parameter now validated to check for directory
|
|                           Validation checks are performed alphabetically by parameter
|
|******************************************************************************
|
| Modified By:              Trevor Welby
| Date of Modification:     07-JUN-05
| New version/draft number: 01-003
| Modification ID:          TQW9753.01.003
| Reason For Modification:   
|                           Modify the logic for SYMBOLNUMBER and SYMBOLMAX
|                           macro variables that check the value of the 
|                           variable against a range of values.
|
|******************************************************************************
|
| Modified By:              Trevor Welby
| Date of Modification:     15-JUN-05
| New version/draft number: 01-004
| Modification ID:          TQW9753.01.004
| Reason For Modification: 
|                           Verify that PCLLQN is in DSETIN
|
|                           If YLLQ EQ Y then verify that STYLE is either MEAN
|                           or MEDIAN 
|******************************************************************************
|
| Modified by:             Yongwei Wang
| Date of modification:    02Apr2008
| New version number:      2/1
| Modification ID:         YW001
| Reason for modification: Based on change request HRT0193
|                          1. Echo macro name and version and local/global macro                                            
|                             variables to the log when g_debug > 0    
|                          2. Replaced %inc tr_putlocal.sas with %put statements
|******************************************************************************
|
| Modified By:             Warwick Benger
| Date of Modification:    30-Oct-09
| New version number:      03-001
| Modification ID:         WJB.3.01
| Reason For Modification: Based on change request HRT231
|                          removed: device font framepage frameplot getdatayn incllq 
|                                   labelvarsyn layout legendtype outfile symbolmax 
|                                   yllq xyzero 
|                          added:   frameaxes legendyn
|                          changed: valid values for LLQLINE
|                                   changed REPEATVAR to ZREPEATVAR and changed format
|                                   changes to required/optional variables
|                                   added call to tu_getdata
|******************************************************************************
| Modified By:             Shivam Kumar
| Date of Modification:    21-OCT-2013
| New version number:      04-001
| Modification ID:         
| Reason For Modification: Replace local macro variable sysmsg with l_sysmsg
*******************************************************************************/
%macro tu_valgparms(macroname=  /* Specifies the calling macro */  
                   );

  /* Echo parameter values and global macro variables to the log */
  %local MacroVersion ;
  %let MacroVersion=4 Build 1;
  
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
    
    %tu_putglobals();
    
  %end;

  %local prefix subsetDataset;
  %let prefix=%substr(&macroname.,3); 

  /* This macro will only perform validations for tu_pkfig currently */

  /* PARAMETER VALIDATION */
  %let macroname=%upcase(%nrbquote(&macroname));

  %if %length(&macroname) eq 0 %then
  %do;  /* Is blank */
    %put RTE%str(RROR): &macroname.: The MACRONAME parameter must not be blank;  
    %let g_abort=1;
  %end;  /* Is blank */
  %else
  %do;  /* Is not blank */
    %if %index("TU_PKTFIG","%upcase(&macroname)") eq 0 %then
    %do; /* Invalid MACRONAME */
      %put %str(RTE)RROR: &macroname.: The macro calling this macro (&macroname) is not supported;
       %let g_abort=1;;   
    %end; /* Invalid MACRONAME */
  %end;  /* Is not blank */

  %tu_abort;
 
  /* DSETIN : Verify that the dataset exists */
  %if %length(&dsetin) eq 0 %then
  %do;  /* DSETIN not provided */
    %put %str(RTE)RROR: &macroname.: DSETIN has not been specified.;
    %let g_abort=1;
  %end;  /* DSETIN not provided */
  %else %if not %sysfunc(exist(&dsetin)) %then
  %do;  /* DSETIN does not exist */
    %put %str(RTE)RROR: &macroname.: The dataset identified by DSETIN (&dsetin) does not exist;
    %let g_abort=1;
  %end;  /* DSETIN does not exist */

  %tu_abort;  
  /* NORMAL PROCESSING */

  /* Get data for selected population */ 
  %tu_getdata(dsetin=&dsetin
             ,dsetout1=&prefix._getdata);
  %let subsetDataset = &prefix._getdata;

  /* Verify that required parameters are non-blank */
  %local reqvars reqvar i;

  /* 
  /  [WJB.3.01] Per changes to tu_pktfig; 
  /  removed: device font framepage frameplot getdatayn incllq labelvarsyn layout legendtype outfile symbolmax yllq xyzero
  /  added: frameaxes legendyn legendlabel repeatvar varlabelstyle
  /----------------------------------------------------------------------------------------- */
  %let reqvars=bars boty figtype frameaxes legendyn llqline ptsize style topy xvar yvar varlabelstyle;               
  %let reqvar=;
  %do i=1 %to %tu_words(&reqvars);  
    %let reqvar=%scan(&reqvars,&i,%str( ));
    %if %nrbquote(&&&reqvar) eq %then
    %do;  /* Issue message */
      %put %str(RTE)RROR: &macroname.: Macro Parameter %upcase(&reqvar) must not be blank;
      %let g_abort=1;
    %end;  /* Issue message */
  %end; 

  %tu_abort;  

  /* BARS : Valid values */  /* [WJB.3.01] Add SDB */ 
  %if %index("SD" "SDB" "RANGE" "NONE","%upcase(&bars)") eq 0 %then
  %do;
    %put %str(RTE)RROR: &macroname.: BARS (&bars) is not: SD, SDB, RANGE or NONE;
    %let g_abort=1;
  %end;

  /* BOTY : Parameter is validated by sub-macros */

  /* BYSTYLE : Cross validation */
  %if %length(&byvars) gt 0 and %length(&bystyle) eq 0 %then
  %do;
    %put %str(RTE)RROR: &macroname.: BYSTYLE must not be blank when BYVARS (&byvars) is non blank;
    %let g_abort=1;
  %end;

  /* BYVARS : Validation */
  %if %length(&byvars) gt 0 %then
  %do;  /* BYVARS */
    %local notfound;
    %let notfound=%tu_chkvarsexist(&dsetin,%sysfunc(translate(&byvars.,%str( ),=)));
    %if %length(&notfound) gt 0 %then 
    %do;
      %put %str(RTE)RROR: &macroname.: The following BYVARS (&notfound) were not found in DSETIN (&dsetin);
      %let g_abort=1;
    %end;
  %end;  /* BYVARS */

  /* Generate actualBYvars (for use in other validation) */
  %local actualBYvars wordptr word;
  %let actualBYvars=;
  %let wordptr=1;
  %let word = %scan(&byvars,&wordptr);
  %do %until (%length(&word) eq 0);
    %if %index(&word,=) %then 
      %let actualBYvars = &actualBYvars %scan(&word,2,=) %scan(&word,1,=);
    %else 
      %let actualBYvars = &actualBYvars &word;
    %if &g_debug ge 1 %then
      %put RTD%str(EBUG): &sysmacroname: WORDPTR=&wordptr, WORD=&word, actualBYvars=&actualBYvars;
    %let wordptr=%eval(&wordptr+1);
    %let word = %scan(&byvars,&wordptr);
  %end;

  /* BYVARS : Verify that BYVARS is not in : XVAR, YVAR, ZVAR or ZREPEATVAR is checked below */
  
  /* FIGTYPE : Valid Values */ /* [WJB.3.01] removed cross-validation with LAYOUT */
  %if %index("LOG" "LINEAR" "LINEAR LOG","%upcase(&figtype)") eq 0 %then
  %do;  /* Invalid FIGTYPE */
    %put %str(RTE)RROR: &macroname.: FIGTYPE (&figtype) is not: LOG, LINEAR or LINEAR LOG;
    %let g_abort=1;  
  %end;  /* Invalid FIGTYPE */

  /* FORMATS : Not validated */

  /* GPTSIZE : Numeric */
  %if %length(&gptsize) ne 0 and %datatyp(&gptsize) ne NUMERIC %then
  %do;
    %put %str(RTE)RROR: &macroname.: GPTSIZE (&gptsize) is not a numeric value;
    %let g_abort=1;
  %end;

  /* HREF : Validation */
  %if %length(&href) ne 0 and %datatyp(&href) ne NUMERIC %then
  %do;
    %put %str(RTE)RROR: &macroname.: HREF (&href) is not a numeric value;
    %let g_abort=1;
  %end;

  /* LEGENDYN : Cross-validate with ZVAR */ /* [WJB.3.01] changed from LEGENDTYPE and removed cross-validation with LAYOUT */
  %if %length(&zvar) eq 0 and &legendyn ne N %then
  %do;
    %put %str(RTE)RROR: &macroname.: With no ZVAR, a legend cannot be produced - LEGENDYN must be set to N;
    %let g_abort=1;
  %end;

  /* LEGENDLABEL : Cross-validate with LEGENDYN */ 
  %if &legendyn eq Y and %index("Y" "N","%upcase(&legendlabel)") eq 0 %then %do;
      %put %str(RTE)RROR: &macroname.: LEGENDYN is Y, but LEGENDLABEL is not Y or N.;
      %let g_abort=1;
  %end;

  /* LLQLINE : Validated below */ /* [WJB.3.01] added L, C and R as valid values */
  %if %index("Y" "N" "L" "C" "R","%upcase(&llqline)") eq 0 %then
  %do;
    %put %str(RTE)RROR: &macroname.: LLQLINE (&llqline) is not N (No), Y (Yes), L (Yes, annotated to left), C (Yes, annotated to centre) or R (Yes, annotated to right);
    %let g_abort=1;
  %end;

  /* OUTFILE : Validation */

  /* Verify that OUTFILE contains a directory */
  %local OutSearch Dirlen;
  %let OutSearch=%scan(&outfile.,-1,/\);
  %if &g_debug. ge 1 %then
    %put RTD%str(EBUG) : &macroname. : OutSearch: &OutSearch;
  %let Dirlen=%length(&outfile)-%length(&OutSearch.);
  %if &g_debug. ge 1 %then
    %put  RTD%str(EBUG) : &macroname. : Dirlen: &Dirlen.;

  %if &Dirlen. eq 0 %then
  %do;  /* No Directory */
    %put RTE%str(RROR): &macroname.: OUTFILE (&outfile) does not include a directory name;
    %let g_abort=1;
  %end;  /* No Directory */
  %else
  %do;  /* Directory found */
    /* check that the directory exists */
    %local directory filelen;
    %let filelen=%length(%scan(&outfile.,-1,/\));
    %if &g_debug. ge 1 %then
      %put  RTD%str(EBUG) : &macroname. : Filelen: &filelen.;
    %let directory=%substr(&outfile.,1,%length(&outfile)-&filelen.-1);
    %if &g_debug. ge 1 %then
      %put  RTD%str(EBUG) : &macroname. : Directory: &directory.;
    %local fileref rc;
    %let fileref=fileref;
    %let rc=%sysfunc(filename(&fileref.,&directory.));
    %if &g_debug. ge 1 %then
      %put  RTD%str(EBUG) : &macroname. : Assigned fileref RC: &rc.;
    %if &rc. ne 0 %then
    %do;  /* Fileref invalid */
      %local l_sysmsg;
      %let l_sysmsg=%sysfunc(sysmsg());
      %put RTE%str(RROR): &macroname.: &l_sysmsg.;
      %let g_abort=1;
    %end;  /* Fileref invalid */
    %else
    %do;  /* Fileref valid */
      %local dirid;
      %let dirid=%sysfunc(dopen(&fileref.));
      %if &g_debug. ge 1 %then
        %put  RTD%str(EBUG) : &macroname. : DIRID: &dirid.;
      %if &dirid. eq 0 %then
      %do;  /* Directory does not exist */
        %put RTE%str(RROR): &macroname.: The directory specified by the OUTFILE (&outfile) parameter does not exist;
        %let g_abort=1;
      %end; /* Directory does not exist */
      %else
      %do;  /* Directory exists */
        /* tidy-up */
        %let rc=%sysfunc(dclose(&dirid.));
        %if &g_debug. ge 1 %then
          %put  RTD%str(EBUG) : &macroname. : Close directory RC: &rc.;
        %let rc=%sysfunc(filename(&fileref.));
        %if &g_debug. ge 1 %then
          %put  RTD%str(EBUG) : &macroname. : Deassign fileref RC: &rc.;
      %end; /* Directory exists */
    %end;  /* Fileref valid */
  %end; /* Directory found */

  /* PTSIZE : Numeric */
  %if %datatyp(&ptsize) ne NUMERIC %then
  %do;
    %put %str(RTE)RROR: &macroname.: PTSIZE (&ptsize) is not a numeric value;
    %let g_abort=1;
  %end;

  /* ZREPEATVAR : Validation 
  /  [WJB.3.01] updated to reflect changes from REPEATVAR to ZREPEATVAR and new format
  / Valid values are:    
  / 1) [blank]
  / 2) variable     
  / 3) variable=varcode     
  /---------------------------------------------------- */
  %if %length(&zrepeatvar) ne 0 %then
  %do;
    %if %length(&zvar) eq 0 %then
    %do;
      %put %str(RTE)RROR: &macroname.: In order to specify ZREPEATVAR, the ZVAR parameter must also be used;
      %let g_abort=1;
    %end;
    %local byperDecode byperCode;
    %let byperDecode=%scan(&zrepeatvar,1,=);
    %let byperCode=%scan(&zrepeatvar,2,=);
    %if %length(%tu_chkvarsexist(&dsetin.,&byperDecode.)) ne 0 %then
    %do;
      %put %str(RTE)RROR: &macroname.: The primary variable specified in the ZREPEATVAR parameter (&byperDecode.) does not exist in DSETIN (&dsetin);
      %let g_abort=1;
    %end;
    %if %length(&byperCode.) gt 0 %then
    %do;
      %if %length(%tu_chkvarsexist(&dsetin.,&byperCode.)) ne 0 %then
      %do;
        %put %str(RTE)RROR: &macroname.: The code variable specified in the ZREPEATVAR parameter (&byperCode.) does not exist in DSETIN (&dsetin);
        %let g_abort=1;
      %end;
    %end;
  %end; /* Do further checks */

  /* STYLE : Valid values */
  %if %index("MEAN" "MEDIAN" "INDIVIDUAL" "SPAGHETTI","%upcase(&style)") eq 0 %then
  %do;
    %put %str(RTE)RROR: &macroname.: STYLE (&style) is not: MEAN, MEDIAN, INDIVIDUAL or SPAGHETTI;
    %let g_abort=1;
  %end;

  /* SYMBOLCOLOR : Character */
  %if %length(&symbolcolor) ne 0 and %datatyp(&symbolcolor) ne CHAR %then
  %do;
    %put %str(RTE)RROR: &macroname.: SYMBOLCOLOR (&symbolcolor) is not a character value;
    %let g_abort=1;
  %end;

  /* SYMBOLINTERPOL : Character */
  %if %length(&symbolinterpol) ne 0 and %datatyp(&symbolinterpol) ne CHAR %then
  %do;
    %put %str(RTE)RROR: &macroname.: SYMBOLINTERPOL (&symbolinterpol) is not a character value;
    %let g_abort=1;
  %end;

  /* SYMBOLLINE : Numeric */
  %if %length(&symbolline) ne 0 %then
  %do;  /* Not blank */ 
    /* Check numeric and in range of 1-46 */
    %local symbolnumber i;
    %let symbolnumber=;
    %do i=1 %to %tu_words(&symbolline);   /* For each word */  
      %let symbolnumber=%scan(&symbolline,&i,%str( ));
      %if %datatyp(&symbolnumber) ne NUMERIC %then
      %do;  /* Not numeric */
        %put %str(RTE)RROR: &macroname.: Macro Parameter SYMBOLLINE (&symbolline) value (&symbolnumber) must be numeric;
        %let g_abort=1;
      %end;  /* Not numeric */
      %else
      %do;  /* Numeric [TQW9753.01.003] */
        %if not((1 le &symbolnumber) and (&symbolnumber le 46)) %then
        %do;  /* Not in range */
          %put %str(RTE)RROR: &macroname.: SYMBOLLINE (&symbolline) values are not in range : 1-46;
          %let g_abort=1;
        %end;  /* Not in range */
      %end;  /* Numeric */
    %end;  /* For each word */ 
  %end;  /* Not blank */

  /* SYMBOLOTHER : Character */
  %if %length(&symbolother) ne 0 %then
  %do;  /* Not blank */ 
    %if %datatyp(&symbolother) ne CHAR %then
    %do;  /* Not character */
      %put %str(RTE)RROR: &macroname.: SYMBOLOTHER (&symbolother) is not a character value;
      %let g_abort=1;
    %end;  /* Not character */
    %if %length(&symbolotherdelim) eq 0 %then
    %do;  /* Is blank */
        %put %str(RTE)RROR: &macroname.: SYMBOLOTHERDELIM (&symbolotherdelim) must not be blank when SYMBOLOTHER (&symbolother) is specified;
        %let g_abort=1;
    %end;  /* Is blank */
  %end;  /* Not blank */

  /* SYMBOLOTHERDELIM : Character */
  %if %length(&symbolotherdelim) ne 0 and %datatyp(&symbolotherdelim) ne CHAR %then
  %do;
    %put %str(RTE)RROR: &macroname.: SYMBOLOTHERDELIM (&symbolotherdelim) is not a character value;
    %let g_abort=1;
  %end;

  /* SYMBOLVALUE  : Character */
  %if %length(&symbolvalue) ne 0 and %datatyp(&symbolvalue) ne CHAR %then
  %do;
    %put %str(RTE)RROR: &macroname.: SYMBOLVALUE (&symbolvalue) is not a character value;
    %let g_abort=1;
  %end;

  /* TOPY : Parameter is validated by sub-macros */

  /* VREF : Validation */
  %if %length(&vref) ne 0 and %datatyp(&vref) ne NUMERIC %then
  %do;
    %put %str(RTE)RROR: &macroname.: VREF (&vref) is not a numeric value;
    %let g_abort=1;
  %end;

  /* XINT : Validation */
  %if %length(&xint) ne 0 and %datatyp(&xint) ne NUMERIC %then
  %do;
    %put %str(RTE)RROR: &macroname.: XINT (&xint) is not a numeric value;
    %let g_abort=1;
  %end;

  /* XLABEL : is not validated */

  /* XMAX : Validation */
  %if %length(&xmax) ne 0 and %datatyp(&xmax) ne NUMERIC %then
  %do;
    %put %str(RTE)RROR: &macroname.: XMAX (&xmax) is not a numeric value;
    %let g_abort=1;
  %end;

  /* XMIN : Validation */
  %if %length(&xmin) ne 0 and %datatyp(&xmin) ne NUMERIC %then
  %do;
    %put %str(RTE)RROR: &macroname.: XMIN (&xmin) is not a numeric value;
    %let g_abort=1;
  %end;

  /* XRANGE : Validation */
  %if (%length(&xmin) eq 0 or %length(&xint) eq 0 or %length(&xmax) eq 0) and %index("ALL" "BY","%upcase(&xrange)") eq 0 %then
  %do;
    %put %str(RTE)RROR: &macroname.: XRANGE (&xrange) is not ALL or BY;
    %let g_abort=1;
  %end;

  /* XVAR : Validation */
  /* if the vars have been selected then check they are ok */
  %local xvar_var xvar_unit xvar_wrds;
  %let xvar_wrds=%tu_words(&xvar, delim=%str( ));
 
 /* seperate the xvar variable */
  %let xvar_var=%scan(&xvar,1);
  *-- check that the xvar is on the dataset;
  %if %length(%tu_chkvarsexist(&dsetin,&xvar_var)) gt 0  %then 
  %do;
    %put %str(RTE)RROR: &macroname.: The variable identified by XVAR (&xvar_var) is not on the dataset identifed by DSETIN (&dsetin) ;
    %let g_abort=1;
  %end;
  %else %if %tu_chkvartype(&dsetin,&xvar_var) ne N %then
  %do;
    %put %str(RTE)RROR: &macroname.: XVAR (&xvar_var) is not a numeric variable;
    %let g_abort=1;
  %end;

  /* count the number of distinct units we have */
  %if &xvar_wrds gt 2 %then %do; /* [WJB.3.01] added validation for >2 variables (error) */
    %put %str(RTE)RROR: &macroname.: XVAR (&xvar) contains more than 2 variables (one for the value and one for the unit);
    %let g_abort=1;
  %end;
  %else %if &xvar_wrds eq 2 %then 
  %do;  /* Two xvar words - must validate units */
    %let xvar_unit=%scan(&xvar.,2);
    /* check that the units variable exists */
    %if %length(%tu_chkvarsexist(&dsetin,&xvar_unit)) gt 0  %then 
    %do;
      %put %str(RTE)RROR: &macroname.: The variable identified by XVAR UNIT (&xvar_unit) is not on the dataset identifed by DSETIN (&dsetin) ;
      %let g_abort=1;
    %end;
    %else %if %tu_chkvartype(&dsetin,&xvar_unit) ne C %then
    %do;
      %put %str(RTE)RROR: &macroname.: The XVAR unit variable (&xvar_unit) is not a character variable;
      %let g_abort=1;
    %end;
    %else %if %tu_nobs(&subsetDataset) ne 0 %then
    %do;  /* xvar units var does exist */
      /* Check that units are distinct for any instance of BYVARS */
      proc sql noprint;        
        create table &prefix.byvar_nounq_xunit as
        select 
          %if %length(&actualBYvars) ne 0 %then %tu_sqlnlist(&actualBYvars),; 
          count(*)
          from (select distinct %tu_sqlnlist(&actualBYvars &xvar_unit)
               from &subsetDataset)
         %if %length(&actualBYvars) ne 0 %then group by %tu_sqlnlist(&actualBYvars);
         having count(*) gt 1;
      quit;

      %if %sysfunc(exist(&prefix.byvar_nounq_xunit)) and %tu_nobs(&prefix.byvar_nounq_xunit) gt 0 %then %do;
        data _NULL_;
          set &prefix.byvar_nounq_xunit;
          put "RTE" "RROR: &macroname.: Dataset &dsetin contains multiple xvar units " %if %length(&actualBYvars) ne 0 %then "for " %sysfunc(tranwrd(&actualBYvars,%str( ),%str(=  )))=;;
        run;
        %let g_abort=1;
      %end;
    %end; /* xvar units var does exist */
  %end; /* Two xvar words - must validate units */

  /* YINT : Validation */
  %if %length(&yint) ne 0 and %datatyp(&yint) ne NUMERIC %then
  %do;
    %put %str(RTE)RROR: &macroname.: YINT (&yint) is not a numeric value;
    %let g_abort=1;
  %end;

  /* YLABEL : is not validated */

  /* YLOGBASE/YLOGSTYLE : Validation */
  %if &figtype ne LINEAR %then 
  %do; 
    %if %length(&ylogbase) eq 0 %then
    %do; /* Is blank */
      %put %str(RTE)RROR: &macroname.: YLOGBASE (&ylogbase) is required when FIGTYPE is not LINEAR;
      %let g_abort=1;
    %end; /* Is blank */
    %else
    %if %datatyp(&ylogbase) ne NUMERIC %then
    %do;  /* YLOGBASE : Numeric */
      %put %str(RTE)RROR: &macroname.: YLOGBASE (&ylogbase) is not a numeric value;
      %let g_abort=1;
    %end; /* YLOGBASE : Numeric */

    %if %length(&ylogstyle) eq 0 %then
    %do; /* Is blank */
      %put %str(RTE)RROR: &macroname.: YLOGSTYLE (&ylogstyle) is required when FIGTYPE is not LINEAR;
      %let g_abort=1;
    %end; /* Is blank */
    %else
    %do;  /* Is not blank */
      %if %index("EXPAND" "POWER","%upcase(&ylogstyle)") eq 0 %then
      %do;  /* YLOGSTYLE : Invalid values */
        %put %str(RTE)RROR: &macroname.: YLOGSTYLE (&ylogstyle) is not: EXPAND or POWER;
        %let g_abort=1;
      %end;  /* YLOGSTYLE : Invalid values */
    %end;  /* Is not blank */
  %end;

  /* YLOGMINBASIS : Validation */ /* [WJB.3.01] */
  %if %index("LLQ" "MINVAL","%upcase(&ylogminbasis)") eq 0 %then
  %do;
    %put %str(RTE)RROR: &macroname.: YLOGMINBASIS (&ylogminbasis) is not LLQ or MINVAL;
    %let g_abort=1;
  %end;

  /* YMAX : Validation */
  %if %length(&ymax) ne 0 and %datatyp(&ymax) ne NUMERIC %then
  %do;
    %put %str(RTE)RROR: &macroname.: YMAX (&ymax) is not a numeric value;
    %let g_abort=1;
  %end;

  /* YMIN : Validation */
  %if %length(&ymin) ne 0 and &ymin ne LLQ and %datatyp(&ymin) ne NUMERIC %then
  %do;
    %put %str(RTE)RROR: &macroname.: YMIN (&ymin) can be a numeric value or "LLQ";
    %let g_abort=1;
  %end;

  /* YRANGE : Validation */
  %if (%length(&ymin) eq 0 or %length(&yint) eq 0 or %length(&ymax) eq 0) and %index("ALL" "BY","%upcase(&yrange)") eq 0 %then
  %do;
    %put %str(RTE)RROR: &macroname.: YRANGE (&yrange) is not ALL or BY;
    %let g_abort=1;
  %end;

  /* YVAR : Validation */
  /* if the vars have been selected then check they are ok */
  %local yvar_var yvar_unit yvar_wrds;
  %let yvar_wrds=%tu_words(&yvar, delim=%str( ));
  /* separate the yvar variable */
  %let yvar_var=%scan(&yvar,1);
  *-- check that the yvar is on the dataset;
  %if %length(%tu_chkvarsexist(&dsetin,&yvar_var)) gt 0  %then
  %do;
    %put %str(RTE)RROR: &macroname.: The variable identified by YVAR (&Yvar_var) is not on the dataset identifed by DSETIN (&dsetin) ;
    %let g_abort=1;
  %end;
  %else %if %tu_chkvartype(&dsetin,&yvar_var) ne N %then
  %do;
    %put %str(RTE)RROR: &macroname.: YVAR (&yvar_var) is not a numeric variable;
    %let g_abort=1;
  %end;

  /* count the number of distinct units we have */
  %if &yvar_wrds gt 2 %then %do; /* [WJB.3.01] added validation for >2 variables (error) */
    %put %str(RTE)RROR: &macroname.: YVAR (&yvar) contains more than 2 variables (one for the value and one for the unit);
    %let g_abort=1;
  %end;
  %else %if &yvar_wrds eq 2 %then
  %do;
    %let yvar_unit=%scan(&yvar,2);
    /* check that the units variable exists */
    %if %length(%tu_chkvarsexist(&dsetin,&yvar_unit)) gt 0  %then
    %do;
      %put %str(RTE)RROR: &macroname.: The variable identified as the unit component of YVAR (&yvar_unit) is not on the dataset identifed by DSETIN (&dsetin) ;
      %let g_abort=1;
    %end;
    %else %if %tu_chkvartype(&dsetin,&yvar_unit) ne C %then
    %do;
      %put %str(RTE)RROR: &macroname.: The YVAR unit variable (&yvar_unit) is not a character variable;
      %let g_abort=1;
    %end;
    %else %if %tu_nobs(&subsetDataset) ne 0 %then
    %do;
      /* Check that units are distinct for any instance of BYVARS */
      proc sql noprint;        
        create table &prefix.byvar_nounq_yunit as
        select 
          %if %length(&actualBYvars) ne 0 %then %tu_sqlnlist(&actualBYvars),; 
          count(*)
          from (select distinct %tu_sqlnlist(&actualBYvars &yvar_unit)
                from &subsetDataset)
          %if %length(&actualBYvars) ne 0 %then group by %tu_sqlnlist(&actualBYvars);
          having count(*) gt 1;
      quit;

      %if %sysfunc(exist(&prefix.byvar_nounq_yunit)) and %tu_nobs(&prefix.byvar_nounq_yunit) gt 0 %then %do;
        data _NULL_;
          set &prefix.byvar_nounq_yunit;
          put "RTE" "RROR: &macroname.: Dataset &dsetin contains multiple yvar units " %if %length(&actualBYvars) ne 0 %then "for " %sysfunc(tranwrd(&actualBYvars,%str( ),%str(=  )))=;;
        run;
        %let g_abort=1;
      %end;
    %end;/* end of checking distinct yvar units */
  %end;/* end of unit validations*/

  /* ZVAR : Validation */
  %if %length(&zvar) ne 0 %then 
  %do;
    %local zvarDecode zvarCode;
    %let zvarDecode=%scan(&zvar,1,=);
    %let zvarCode  =%scan(&zvar,2,=);
    /* Validate zvarDecode */
    %if %length(%tu_chkvarsexist(&dsetin,&zvarDecode)) gt 0  %then 
    %do;
      %put %str(RTE)RROR: &macroname.: The primary variable identified by ZVAR (&zvarDecode) is not on the dataset identifed by DSETIN (&dsetin) ;
      %let g_abort=1;
    %end;
    %if %length(&zvarCode) gt 0 %then
    %do;  /* Validate zvarCode */
      %if %length(%tu_chkvarsexist(&dsetin,&zvarCode)) gt 0  %then 
      %do;
        %put %str(RTE)RROR: &macroname.: The coded variable identified by ZVAR (&zvarCode) is not on the dataset identifed by DSETIN (&dsetin) ;
        %let g_abort=1;
      %end;
    %end; /* Validate zvarCode */
  %end;

  /* FRAMEAXES LEGENDYN  : Valid values */
  %local vars var i;
  %let vars=frameAxes legendyn;
  %let var=;
  %do i=1 %to %tu_words(&vars); 
    %let var=%scan(&vars,&i.,%str( ));
    %if %index("Y" "N","%upcase(&&&var.)") eq 0  %then
    %do;
      %put %str(RTE)RROR: &macroname.: %upcase(&var) (&&&var..) is not: Y or N;
      %let g_abort=1;
    %end;
  %end;

  /* Check that vars are not in more than one of xvar, yvar, zvar, byvars, zrepeatvar */ /* [WJB.3.01] modified to reflect new ZREPEATVAR format */
  %local testdupl;
  %if %length(&xvar) gt 0 %then
    %let testdupl=&xvar ;
  %if %length(&yvar) gt 0 %then
    %let testdupl=&testdupl &yvar;
  %if %length(&zvar) gt 0 %then
  %do;
    %let testdupl=&testdupl %scan(&zvar,1,=);
  %end;
  %if %length(&byvars) gt 0 %then
    %let testdupl=&testdupl %sysfunc(translate(&byvars,%str( ),=));
  %if &macroname. eq TU_PKTFIG %then
  %do;
    %if %length(&zrepeatvar) ne 0 %then  
      %let testdupl=&testdupl. %scan(%sysfunc(compress(&zrepeatvar)),1,=); 
      %let testdupl=&testdupl. %scan(%sysfunc(compress(&zrepeatvar)),2,=); 
  %end;

  %local testduplun;
  %let testduplun=%tu_unduplst(&testdupl.);
  %if &g_debug ge 1 %then
    %put RTD%str(EBUG): &macroname.: TESTDUPL=!&testdupl! TESTDUPLUN=!&testduplun!;
  %if %length(&testdupl.) ne %length(&testduplun.) %then
  %do;
    %put %str(RTE)RROR: &macroname.: One or more variables were used repeatedly across XVAR, YVAR, ZVAR, BYVARS, and ZREPEATVAR;
    %let g_abort=1;
  %end; 


  /* Verify that PCLLQN is in DSETIN [TQW9753.01.004] */
  %local notfound;
  %let notfound=%tu_chkvarsexist(&dsetin,PCLLQN);
  %if (&llqline eq Y or &ymin eq LLQ 
   or ((&ymin le 0 or %length(&ymin) eq 0) and %sysfunc(indexw(&figtype,LOG)) and &ylogminbasis eq LLQ))
   and %length(&notfound.) gt 0 %then 
  %do;
    %put %str(RTE)RROR: &macroname.: The variable PCLLQN was not found in DSETIN (&dsetin);
    %let g_abort=1;
  %end;

  /*
  / Tidyup the session
  /---------------------------------------------------------------------------- */
  %tu_tidyup(rmdset=&prefix.:
             ,glbmac=NONE
             );
             
  %tu_abort;

%mend tu_valgparms;
