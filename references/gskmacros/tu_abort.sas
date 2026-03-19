/*
| Macro name:     tu_abort.sas
|
| Macro version:  2
|
| SAS version:    8.2
|
| Created by:     Alfred Montalvo Jr
|
| Date:           22may2003
|
| Macro purpose:  The current macro will perform a controlled abort of program
|                 execution
|
| Macro design:   Procedure
|
| Input parameters:
|
|  Name         Description                        default
|  
|  options      Optional actions                   no default/blank
|               valid values include:
|               Force=abort or
|               Reset=reset g_abort values
|-----------------------------------------------------------------------------------
|  Output:
|-----------------------------------------------------------------------------------
|  Global macrop variables created:
|          Global macro variable G_ABORT that specifies the status of the
|          abort macro variable created by ts_setup.
|-----------------------------------------------------------------------------------
|  Macros called:
|  (@)tu_putglobals
|-----------------------------------------------------------------------------------
| Change Log
|
| Modified by: Alfred Montalvo Jr
| Date of modification: 02jul2003
| New version number: 1/2
| Modification ID: 01
| Reason for modification: remove comma from from keyword parameter and added 
|                          %include for tr_putlocals and macro call to tu_putglobals
|-----------------------------------------------------------------------------------
| Modified by: Alfred Montalvo Jr
| Date of modification: 03jul2003
| New version number: 1/3
| Modification ID: 01
| Reason for modification: remove validation check for missing value for OPTION
|                          macro parameter based on UTC output for tu_abort. Added
|                          value to varsin parameter for tu_putglobals macro call.
|                          Assigned value of -1 to g_abort to comply with error 
|                          processing section 2.3.3 of unit spec.
|-----------------------------------------------------------------------------------
| Modified by:             Yongwei Wang
| Date of modification:    02Apr2008
| New version number:      2/1
| Modification ID:         YW001
| Reason for modification: Based on change request HRT0193
|                          1. Change macro header style (for mfile)                                      
|                          2. Echo macro name and version and local/global macro                                            
|                             variables to the log when g_debug > 0    
|                          3. Replaced %inc tr_putlocal.sas with %put statements
|-----------------------------------------------------------------------------------
| Modified by:
| Date of modification:
| New version number:
| Modification ID:
| Reason for modification:
|-----------------------------------------------------------------------------------*/

%macro tu_abort(option=     /* optional actions               */
                );

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
      
      %tu_putglobals(varsin=g_abort)
      
   %end;
  
   /*  verify OPTION parameter is not missing and valid value is specified  */
   
   %if %bquote(&option) eq %then 
   %do;
          /* missing value OK  */  
   %end;
   %else %if %bquote(%upcase(&option)) eq RESET %then 
   %do;
          /* value OK  */
   %end;
   %else %if %bquote(%upcase(&option)) eq FORCE %then 
   %do;
          /* value OK  */
   %end;
   %else %do;
   
        %global g_abort;
        %let g_abort= -1;
        
        %put %str(RTE)RROR: TU_ABORT: - Macro parameter OPTION (option=&option) is not a valid value;
        %put %str(RTE)RROR: TU_ABORT: calling abort to stop executing program;
            
        data _null_;
             abort return 8;
        run;
           
   %end;

   %if %upcase(&option) EQ RESET %then 
   %do;
       %global g_abort;
       %let g_abort=0;
   %end;
   %else %if %upcase(&option) EQ FORCE OR &g_abort EQ 1 %then 
   %do;
         %if %upcase(&sysenv) EQ BACK %then 
         %do;
             %put %str(RTE)RROR: ABORT program G_ABORT=&g_abort.;
              data _null_;
                   abort return 8;
              run;
         %end;
         %else %if %upcase(&sysenv) EQ FORE %then 
         %do;
             %put %str(RTN)OTE: Options OBS=0 and NOREPLACE have been set as a result of the error.;
             %put %str(RTN)OTE: Before attempting any further code execution, reset these options;
             %put %str(RTN)OTE: with the following SAS statement: OPTIONS OBS=MAX REPLACE;
               options obs=0 noreplace;
         %end;
   %end;

%mend tu_abort;


