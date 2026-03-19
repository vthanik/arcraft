/******************************************************************************* 
|
| Macro Name:      tu_isvarindsplan.sas
|
| Macro Version:   3.0
|
| SAS Version:     9.3
|
| Created By:      Andrew Ratcliffe
|
| Date:            14-Dec-2004
|
| Macro Purpose:   This macro shall scan a dataset copy of the
|                  Dataset Plan and inform the caller of whether the specified
|                  variable is in the plan. In addition, if the specified 
|                  variable is in the plan, the attributes of the variable 
|                  shall be returned. 
|
|                  If any of the err!!or checking fails it shall be the callers
|                  responsibility to call the %tu_abort macro immediately after 
|                  calling this macro
|
| Macro Design:    FUNCTION STYLE MACRO
| 
| Input Parameters:
|
| NAME              DESCRIPTION                             DEFAULT 
|   REQUIRED
| DSETIN            Specifies the name of the input         [blank]
|                   Dataset Plan dataset (previously
|                   created, typically, by %tu_readdsplan)
|
| VAR               Specifies the name of the variable to   [blank]
|                   be searched for in the Dataset Plan
|   OPTIONAL
| ATTRIBMVAR        Specifies the name of a macro variable  [blank]
|                   into which %tu_isvarindsplan shall 
|                   place the attributes of the VAR 
|                   variable if it was found in the Dataset 
|                   Plan. If the VAR variable is not in 
|                   the plan, the ATTRIBMVAR macro variable 
|                   shall be set to blank.
|                   The attributes shall be taken from the 
|                   Dataset Plan and shall be set in the 
|                   macro variable so that they may be 
|                   used on an ATTRIB statement. The macro
|                   variable value shall include neither
|                   "attrib" nor the variable name.
| 
| Output: The macro resolves into a value, and optionally sets the
|         value of a second macro variable as specified by the 
|         ATTRIBMVAR parameter. 
|
|         The macro shall resolve to either Y or N to indicate whether the
|         VAR variable was found in the Dataset Plan 
|
| Global macro variables created:  None
|
| Macros called:
| (@) tu_chknames
| (@) tu_putglobals
|
| Examples:
|
|   (1)
|   %tu_readdsplan(dsetout=dsplan...
|   %if %tu_isvarindsplan(dsetin=dsplan,var=PCWTU) eq Y %then
|   %do; 
|
|   (2)
|   %tu_readdsplan(dsetout=dsplan...
|   %local varFound varAttrib;
|   %let varFound = %tu_isvarindsplan(dsetin=&prefix._dsplan,var=PCWTU,attribmvar=varAttrib);
|   %if &varFound eq Y %then
|   %do; 
|
|******************************************************************************* 
| Change Log 
|
| Modified By:             Andrew Ratcliffe, RTSL
| Date of Modification:    03-Feb-05
| New version number:      01-002
| Modification ID:         AR2
| Reason For Modification: Allow vartype values of date, time, and datetime in
|                           addition to char and num.
|                          Validate the vartype value.
|                          Replace %include of putlocals with in-line code in
|                           order to avoid macro resolving to "%include...".
|
| Modified by:             Yongwei Wang
| Date of modification:    02Apr2008
| New version number:      2/1
| Modification ID:         YW001
| Reason for modification: Based on change request HRT0193
|                          1.Echo macro name and version and local/global macro                                            
|                            variables to the log when g_debug > 0   
|                          2.Output &sysmacroname in all RTERROR messages.                                                 
|                          3.Output &sysmacroname and RTDEBUG in all debugging and                                         
|                            messages.  
|
| Modified By: 			   Lee Seymour
| Date of Modification:    22-Aug-2014
| New version number: 	   3/1
| Modification ID:         LS001
| Reason For Modification: To enable execution in SAS version 9.3 - HRT0302
|
| Modified By: 
| Date of Modification: 
| New version number: 
| Modification ID: 
| Reason For Modification: 
|
********************************************************************************/ 
%macro tu_isvarindsplan(dsetin =      /* type:ID Dataset Plan dataset name */
                       ,var =         /* Name of variable to search for */
                       ,attribmvar =  /* Name of macro variable to store the VAR attributes */
                       );

  /* Standard beginning */

  /* Cannot include tr_putlocals.sas in function-style macro */    /*AR4*/
  %local MacroVersion;
  %let MacroVersion = 2.0;
  
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

  /***********************************/
  /* Begin with parameter validation */
  /***********************************/

  /* Check that DSETIN exists */
  %if not %sysfunc(exist(&dsetin)) %then
  %do;
    %put RTE%str(RROR): &sysmacroname: DSETIN (&dsetin) does not exist;
    %let g_abort = 1;
  %end;

  /* Check that VAR is a valid variable name */
  %if %length(%tu_chknames(&var,VARIABLE)) %then
  %do;
    %put RTE%str(RROR): &sysmacroname: VAR (&var) is not a valid variable name;
    %let g_abort = 1;
  %end;

  %if &g_abort ge 1 %then
    %goto FINISH;

  /* Check that ATTRIBMVAR has already been 
     declared as global or local, i.e. by caller */
  %if %length(&attribmvar) gt 0 %then 
  %do;  /* Attribmvar is requested */
    %local gotAt;
    %let gotAt=N;

    %local dsid where;
    %let where = ;
    %let dsid = %sysfunc(open(sashelp.vmacro(where=(scope ne 'AUTOMATIC'))));
    %if &g_debug ge 1 %then
    %do;
      %let l_sysmsg=%sysfunc(sysmsg());  /*LS001*/
      %put RTD%str(EBUG): &sysmacroname: DSID=&dsid SYSMSG=&l_sysmsg; /*LS001*/
    %end;

    %local fetchrc name name_vn;
    %let name_vn = %sysfunc(varnum(&dsid,NAME));
    %let fetchrc = %sysfunc(fetch(&dsid)); %if &g_debug ge 1 %then %put RTD%str(EBUG): &sysmacroname: FETCHRC=&fetchrc;
    %do %while(&fetchrc eq 0 and &gotAt eq N);
      %let name = %sysfunc(getvarc(&dsid,&name_vn));
      %if &name eq %upcase(&attribmvar) %then
        %let gotAt = Y; %if &g_debug ge 1 %then %put RTD%str(EBUG): &sysmacroname: GOTAT=&gotAt;

      %let fetchrc = %sysfunc(fetch(&dsid)); %if &g_debug ge 1 %then %put RTD%str(EBUG): &sysmacroname: FETCHRC=&fetchrc;
    %end;

    %let rc = %sysfunc(close(&dsid)); %if &g_debug ge 1 %then %put RTD%str(EBUG): &sysmacroname: Close RC=&rc;

    %if &gotAt eq N %then
    %do;
      %put RTE%str(RROR): &sysmacroname: Value specified for ATTRIBMVAR (&attribmvar) is not a known macro variable. Declare it as 'local' beforehand;
      %let g_abort = 1;
    %end;
  %end; /* Attribmvar is requested */

  %if &g_abort ge 1 %then
    %goto FINISH;

  /*********************/
  /* Normal Processing */
  /*********************/
  %local inplan;
  %let inplan = N;

  /* Open the dataset plan, with WHERE varname eq "&var" */
  %local rc l_sysmsg;   /*LS001*/
  %local where;
  %let where = upcase(varname) eq "%upcase(&var)";
  %local dsid;
  %let dsid = %sysfunc(open(&dsetin(where=(&where)))); 
    %if &g_debug ge 1 %then
    %do;
      %let l_sysmsg=%sysfunc(sysmsg());  /*LS001*/
      %put RTD%str(EBUG): &sysmacroname: DSID=&dsid SYSMSG=&l_sysmsg; /*LS001*/
    %end;

  /* If we can fetch a record then the var is in the plan */
  %let rc = %sysfunc(fetch(&dsid)); %if &g_debug ge 1 %then %put RTD%str(EBUG): &sysmacroname: Fetch RC=&rc;

  %if &rc ne 0 %then
  %do; /* Variable is NOT in the Dataset Plan */
    %let inplan=N;
    %if %length(&attribmvar) gt 0 %then 
      %let &attribmvar = ;
  %end; /* Variable is NOT in the Dataset Plan */

  %else
  %do;  /* Variable is in the Dataset Plan */
    %let inplan=Y;

    %if %length(&attribmvar) gt 0 %then
    %do;  /* Attributes are required */

      /* Build the attributes string and assign to ATTRIBMVAR parameter */

      /* Begin by getting the values from the dataset */
      %local varlabel_vn varlabel;
      %let varlabel_vn = %sysfunc(varnum(&dsid,VARLABEL)); %if &g_debug ge 1 %then %put RTD%str(EBUG): &sysmacroname: VARLABEL_VN=&varlabel_vn;
      %let varlabel = %sysfunc(getvarc(&dsid,&varlabel_vn)); %if &g_debug ge 1 %then %put RTD%str(EBUG): &sysmacroname: VARLABEL=&varlabel;

      %local vartype vartype_vn;
      %let vartype_vn = %sysfunc(varnum(&dsid,vartype)); %if &g_debug ge 1 %then %put RTD%str(EBUG): &sysmacroname: vartype_VN=&vartype_vn;
      %let vartype = %sysfunc(getvarc(&dsid,&vartype_vn)); %if &g_debug ge 1 %then %put RTD%str(EBUG): &sysmacroname: vartype=&vartype;

      %local length length_vn;
      %let length_vn = %sysfunc(varnum(&dsid,length)); %if &g_debug ge 1 %then %put RTD%str(EBUG): &sysmacroname: length_VN=&length_vn;
      %let length = %sysfunc(getvarc(&dsid,&length_vn)); %if &g_debug ge 1 %then %put RTD%str(EBUG): &sysmacroname: length=&length;

      %local format format_vn;
      %let format_vn = %sysfunc(varnum(&dsid,format)); %if &g_debug ge 1 %then %put RTD%str(EBUG): &sysmacroname: format_VN=&format_vn;
      %let format = %sysfunc(getvarc(&dsid,&format_vn)); %if &g_debug ge 1 %then %put RTD%str(EBUG): &sysmacroname: format=&format;

      /* Now validate VARTYPE */        /*AR4*/
      %let vartype = %upcase(&vartype);
      %if &vartype ne NUM and
          &vartype ne CHAR and
          &vartype ne DATE and
          &vartype ne TIME and
          &vartype ne DATETIME %then
      %do;
        %put RTE%str(RROR): &sysmacroname: Value found for VARTYPE (&vartype) is not valid (should be NUM, CHAR, DATE, TIME, or DATETIME);
        %let g_abort = 1;
        %goto FINISH;        
      %end;

      /* Now build ATTRIBMVAR */
      %let &attribmvar = LABEL="&varlabel" LENGTH=;
      %if &vartype ne CHAR %then       /*AR4*/
      %do;
        %let &attribmvar = &&&attribmvar &length;
      %end;
      %else
      %do;
        %let &attribmvar = &&&attribmvar $&length;
      %end;

      %if %length(&format) gt 0 %then
      %do;
        %let &attribmvar = &&&attribmvar format=&format;
        %if not %index(&format,.) %then
          %let &attribmvar = &&&attribmvar...;
      %end;

      %if &g_debug ge 1 %then %put RTD%str(EBUG): &sysmacroname: attribmvar=&attribmvar=&&&attribmvar;
    
    %end; /* Attributes are required */
    
  %end; /* Variable is in the Dataset Plan */

  /* Do not forget to close the dataset! */
  %let rc = %sysfunc(close(&dsid)); %if &g_debug ge 1 %then %put RTD%str(EBUG): &sysmacroname: Close RC=&rc;

  %if &g_debug ge 1 %then 
  %do;
    %put RTD%str(EBUG): &sysmacroname: INPLAN=&inplan;
    %put RTD%str(EBUG): &sysmacroname: ATTRIBMVAR=&attribmvar=&&&attribmvar;
  %end;
  
  /* Resolve to value of inplan */
  &inplan

%FINISH:

%mend tu_isvarindsplan;


