/*----------------------------------------------------------------------------+
 | Macro Name    : tr_putlocals                                               |
 |                                                                            |
 | Macro Version   : 1                                                        |
 |                                                                            |
 | SAS version   : SAS v8.2                                                   |
 |                                                                            |
 | Created By    : Neeraj Malhotra                                            |
 |                                                                            |
 | Date          : 23-May-03                                                  |
 |                                                                            |
 | Macro Purpose : Put the macro name and version of a macro to the log.      |
 |                 Put the list of local variables used to the log.           |
 |                                                                            |
 | Macro Design  : SAS script                                                 |
 |                                                                            |
 | Input Parameters : none                                                    |
 |                                                                            |
 |                                                                            |
 |                                                                            |
 | Output: none                                                               |
 |                                                                            |
 | Global macro variables created: none                                       |
 |                                                                            |
 |                                                                            |
 | Macros called : none                                                       |
 |                                                                            |
 |                                                                            |
 | ************************************************************************** |
 | Change Log :                                                               |
 |                                                                            |
 | Modified By : Neeraj Malhotra                                              |
 | Date of Modification : 23-June-2003                                        |
 | New Version/draft number : 1.0/2                                           |
 | Modification ID : NM01                                                     |
 | Reason For Modification : Corrections prompted by SCR                      |
 |                                                                            |
 |                                                                            |
 +----------------------------------------------------------------------------*/


%put ************************************************************;
%put * Macro name: &sysmacroname,  Macro Version: &macroVersion ;
%put ************************************************************;

%put * &sysmacroname has been called with the following parameters: ;
%put * ;
%put _local_;
%put * ;
%put ************************************************************;
