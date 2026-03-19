/*******************************************************************************
|
| Macro Name:     tu_xcpinit.sas
|
| Macro Version:  2
|
| SAS Version:    8.2
|
| Created By:     Trevor Welby
|
| Date:           8th October 2004
|
| Macro Purpose:  This macro shall open a connection to a new exception report
|                 and create a ODS template for subsequent use in writing to
|                 the report (%tu_xcpput).
|
| Macro Design:   Procedure style
|
| Input Parameters:
|
| NAME            DESCRIPTION                                   DEFAULT
|
| HEADER          Optionally specifies the header to be used    [blank]
|                 at the top of the report. For example, the
|                 caller may wish to specify a combination of
|                 study, date & time, and current macro name
|
| OUTFILE         Specifies the location and name of the        &g_pkdata/&g_fnc._recon
|                 exception report without the qualifier.
|                 The %tu_xcpinit macro shall allocate
|                 a file with the appropriate "html"
|                 qualifier
|
| TBLPATH         Specifies the name of the ODS                 xcprpt.tmplate
|                 template that shall be created for
|                 subsequent use in writing to the Exception
|                 Report file (by '%tu_xcpput') [TQW9753.02.001]
|
| ODSDEST         Specifies the ODS destination to which the    HTML (Req) 
|                 reconciliation report shall be written
|                                
| OUTFILESFX      Specifies the suffix (qualifier) to be        &odsdest (Req)
|                 applied to the output file name (&outfile) 
|
| Output:         &g_pkdata/&g_fnc._recon..html
|
| Global macro variables created: G_XCPODSDEST
|
| Macros called:
|(@) tu_putglobals
|(@) tu_tidyup
|(@) tu_abort
|
| Example:
|
| %tu_xcpinit(header=Exception Report Header)
|
|*******************************************************************************
| Change Log
|
| Modified By: Trevor Welby
| Date of Modification: 25th January 2005
| New version/draft number: 01-002
| Modification ID: TQW9753.01-002
| Reason For Modification: Increase the length of variable __xcpmsg from 100
|                          to 256 bytes. This is to avoid truncation of the
|                          exception report message(s)
|
|*******************************************************************************
| Change Log
|
| Modified By: Trevor Welby
| Date of Modification: 25th April 2005
| New version/draft number: 02-001
| Modification ID: TQW9753.02.001
| Reason For Modification: Change the location of the ODS template to
|                          the SASWORK Library.  This resolves a conflict
|                          that occurs with multiuser access.  Update access
|                          has been defined for the template path.                       
|
|                          Change the definition of the TBLPATH parameter.
|                          It previously defined the name of the template path.  
|                          It now defines the name of the template 
|
|                          Add calls to %tu_tidyup and %tu_abort at the end 
|                          of the macro call                    
|
|*******************************************************************************
| Modified by:             Yongwei Wang
| Date of modification:    02Apr2008
| New version number:      2/1
| Modification ID:         YW001
| Reason for modification: Based on change request HRT0193
|                          1. Echo macro name and version and local/global macro                                            
|                             variables to the log when g_debug > 0    
|                          2. Replaced %inc tr_putlocal.sas with %put statements
|*******************************************************************************
| Modified By:
| Date of Modification:
| New version/draft number:
| Modification ID:
| Reason For Modification:
|
********************************************************************************/

%macro tu_xcpinit(header=                          /* Exception report title                */
                 ,outfile=&g_pkdata/&g_fnc._recon  /* Exception report output file name     */
                 ,tblpath=xcprpt.tmplate           /* Name of ODS template                  */
                 ,odsdest=html                     /* Reconciliation Report ODS destination */
                 ,outfilesfx=&odsdest              /* Output filename qualifier             */ 
                 );

  /*
  / Echo values of parameters and global macro variables to the log.
  /------------------------------------------------------------------------------*/
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
    
    %tu_putglobals(varsin=g_pkdata g_fnc g_refdata);
    
  %end;

  /*
  / Perform parameter validation
  /------------------------------------------------------------------------------*/

  /*
  / verify OUTFILE parameter is not missing
  /------------------------------------------------------------------------------*/
  %if %bquote(&outfile) eq %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: Macro parameter OUTFILE (outfile=&outfile) is missing;
    %let g_abort = 1;
  %end;

  /*
  / verify TBLPATH parameter is not missing
  /------------------------------------------------------------------------------*/
  %if %bquote(&tblpath) eq %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: Macro parameter TBLPATH (tblpath=&tblpath) is missing;
    %let g_abort = 1;
  %end;

  /*
  / verify ODSDEST parameter is not missing
  /------------------------------------------------------------------------------*/
  %if %bquote(&odsdest) eq %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: Macro parameter ODSDEST (odsdest=&odsdest) is missing;
    %let g_abort = 1;
  %end;

  /*
  / verify OUTFILESFX parameter is not missing
  /------------------------------------------------------------------------------*/
  %if %bquote(&outfilesfx) eq %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: Macro parameter OUTFILESFX (outfilesfx=&outfilesfx) is missing;
    %let g_abort = 1;
  %end;

  %tu_abort;

  /*
  / Perform Normal Processing
  /------------------------------------------------------------------------------*/
  
  %local prefix; *[TQW9753.02.001];
  %let prefix=_xcpinit;
  
  /*
  / Pass the value of &odsdest parameter to a global macro variable to be                   
  / used by the %tu_xcpterm macro 
  /------------------------------------------------------------------------------*/
  %global g_xcpodsdest; 
  %let g_xcpodsdest=&odsdest;
 
  /*
  / Close the output destination to the listing device
  /------------------------------------------------------------------------------*/
  ods listing close;

  /*
  / Open the HTML output destination
  /------------------------------------------------------------------------------*/
  ods &odsdest body="&outfile..&outfilesfx";

  /*
  / Specify the ODS template search path [TQW9753.02.001]
  /------------------------------------------------------------------------------*/
  ods path work.odstempl(update) sashelp.tmplmst(read);

  /*
  / Create a template to put the exception messages. This is used by the %xcpput
  / macro
  /------------------------------------------------------------------------------*/
  proc template;
  define table &tblpath./store=work.odstempl; *[TQW9753.02.001];
    column __xcptype __xcpmsg;
      define __xcptype;
        width=12;
        header='Type';
        just=L;
      end;
      define __xcpmsg;	 
        width=256; /* [TQW9753.01-002] */
        header='Message';
        just=L;
      end;
  end;
  run;

  %if %length(&header) ne 0 %then
  %do;
    title1 "&header";
  %end;
  %else
  %do;
    title1 "";
  %end;  
  
 
  /*
  / Tidyup the session [TQW9753.02.001]
  /------------------------------------------------------------------------------*/
  %tu_tidyup(rmdset=&prefix:
             ,glbmac=NONE
             );
  quit;

  %tu_abort();  * [TQW9753.02.001];

%mend tu_xcpinit;
