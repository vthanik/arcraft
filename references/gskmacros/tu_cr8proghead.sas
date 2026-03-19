/*---------------------------------------------------------------------------------------+ 
| Macro Name                   : TU_CR8PROGHEAD
|
| Macro Version                : 1 build 1
| 
| SAS version                  : SAS v8.2
| 
| Created By                   : James McGiffen
| 
| Date                         : March-2006
| 
| Macro Purpose                : This unit creates this header for a program
| 
| Macro Design                 : UTILITY STYLE
|
| Input Parameters             : 
| 
| NAME                DESCRIPTION                                       REQ/OPT  DEFAULT
| ----------------------------------------------------------------------------------------
| macname             Macro Name                                        REQ      
| macDesign           Macro Design                                      REQ      UTILITY
|----------------------------------------------------------------------------------------------
| Output                                :        A series of put statements to create this header block
| Global macro variables used           :        G_userid sysdate9 sysver
| 
| Macros called : 
|
|
| Example: %tu_cr8proghead(macname = tu_cr8proghead,macdesign = utility)
|
|------------------------------------------------------------------------------------------
| Change Log : 
|
| Modified By : 
| Date of Modification : 
| New Version Number : 
| Modification ID : 
| Reason For Modification : 
+---------------------------------------------------------------------------------------*/
%macro tu_cr8proghead (macname=, /*-name of the macro you want to create*/
                       macdesign = UTILITY /*- the type of macro you want to create*/
                      ); 
  /*--NP01 - Tidy up input macros and output details to log */
  %let macname = %nrbquote(&macname.);
  %let macdesign =%upcase(%nrbquote(&macdesign.));
                        
  %LOCAL MacroVersion prefix macroname;
  %LET MacroVersion = 1 build 1;
  %let macroname = &sysmacroname.;

  * Echo values of local and global macro variables to the log ;
  %INCLUDE "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_userid.)
  /*--NP3 - set prefix for work directories */
  %let prefix = %substr(&macroname.,3)_; 
  
  /*--NP - Parameter validation*/
  /*--PV01 - Check that both the required variables are not blank*/
  /*-- Cannot use valparms as this is to be used with a dataset*/
  %if &macname. = %then %do;
    %put %str(RTE)RROR: The macname parameter is required and is currently blank;
    %tu_abort(option = force);
  %end;
  %if &macDesign. = %then %do;
    %put %str(RTE)RROR: The macdesign parameter is required and is currently blank;
    %tu_abort(option = force);
  %end;


  /*--NPXX - create put statements.*/
  put "/*---------------------------------------------------------------------------------------+ ";
  put "| Macro Name                   : &MACNAME";
  put "|";
  put "| Macro Version                : 1 ";
  put "|"; 
  put "| SAS version                  : SAS v&sysver.";
  put "| ";
  put "| Created By                   : &g_userid.";
  put "|"; 
  put "| Date                         : &sysdate9";
  put "| ";
  put "| Macro Purpose                : ";
  put "| ";
  put "| Macro Design                 : &macdesign. STYLE";
  put "|";
  put "| Input Parameters             : ";
  put "| ";
  put "| NAME                DESCRIPTION                                       REQ/OPT  DEFAULT";
  put "| ----------------------------------------------------------------------------------------";
  put "|----------------------------------------------------------------------------------------------";
  put "| Output                                :  ";
  put "| Global macro variables created        :  ";
  put "| ";
  put "| Macros called : ";
  put "|";
  put "|";
  put "| Example:";
  put "|";
  put "|------------------------------------------------------------------------------------------";
  put "| Change Log : ";
  put "|";
  put "| Modified By : ";
  put "| Date of Modification : ";
  put "| New Version Number : ";
  put "| Modification ID : ";
  put "| Reason For Modification : ";
  put "+---------------------------------------------------------------------------------------*/";


%mend;
