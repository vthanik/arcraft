/*----------------------------------------------------------------------------+
 | Macro Name    : tu_putglobals                                              |
 |                                                                            |
 | Macro version   : 1.0                                                      |
 |                                                                            |
 | SAS version   : SAS v8.2                                                   |
 |                                                                            |
 | Created By    : Neeraj Malhotra                                            |
 |                                                                            |
 | Date          : 23-May-03                                                  |
 |                                                                            |
 | Macro Purpose : Put a list of all Global Macro Variables used to the log.  |
 |                                                                            |
 | Macro Design  : Functional                                                 |
 |                                                                            |
 | Input Parameters :                                                         |
 |                                                                            |
 | NAME         DESCRIPTION                 DEFAULT                           |
 |                                                                            |
 | VARSIN       List of Global Macro        none                              |
 |              Variable names                                                |
 |                                                                            |
 |                                                                            |
 | Output:                                                                    |
 |                                                                            |
 | Global macro variables created: None                                       |
 |                                                                            |
 |                                                                            |
 | Macros called : None                                                       |
 |                                                                            |
 |                                                                            |
 | ************************************************************************** |
 | Change Log :                                                               |
 |                                                                            |
 | Modified By : Neeraj Malhotra                                              |
 | Date of Modification : 23-June-2003                                        |
 | New Version /draft number : 01.000.002                                     |
 | Modification ID : NM01                                                     |
 | Reason For Modification : Changes from SCR                                 |
 |                                                                            |
 | Change Log :                                                               |
 |                                                                            |
 | Modified By : Dave Booth                                                   |
 | Date of Modification : 27-June-2003                                        |
 | New Version /draft number : 01.000.003                                     |
 | Modification ID : DB01                                                     |
 | Reason For Modification : Draft number format, split %PUT RTWARNING        |
 |                                                                            |
 +----------------------------------------------------------------------------*/


%macro tu_putglobals(varsin=);


  %local word wordnum rc closerc pref;

  %if &varsin  ne %then %do;
    %put * The following global macro variables are used: ;
    %put * ;


    %let wordnum=1;
    %let pref = _PUTGLOBALS;

    %let word=%qscan(&varsin,&wordnum);


    %do %while(&word ne);
      /************************************************/
      /*             PARAMETER VALIDATION             */
      /************************************************/

      %let dsid = %sysfunc(open(sashelp.vmacro(where=(name="%upcase(&word)" and scope="GLOBAL"))));
      %let rc=%sysfunc(fetch(&dsid));
      %let closerc =%sysfunc(close(&dsid));


      %if &rc ne 0 %then
      %do;
        %put %STR(RTWARN)ING: TU_PUTGLOBALS: &word is not a Global Macro Variable.;
      %end;
      %else %do;
        %put %upcase(GLOBAL &word) %unquote(&&&word);
      %end;
      %let wordnum = %eval(&wordnum + 1);
      %let word=%qscan(&varsin,&wordnum);
    %end;
  %end;
  %else %do;
    %put This Macro does not use any Global Macro Variables;
  %end;

  %put * ;
  %put ************************************************************;

%mend tu_putglobals;
