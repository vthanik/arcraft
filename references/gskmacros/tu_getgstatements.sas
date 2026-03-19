/*----------------------------------------------------------------------------------------
| Macro Name        : TU_GETGSTATEMENTS 
|
| Macro Version     : 1
|
| SAS version       : SAS v8.2
|
| Created By        : Yongwei Wang
|
| Date              : 17-May-2006
|
| Macro Purpose     : This macro calls proc goptions to read SAS graph statements into
|                     a SAS data set
|
| Macro Design      : PROCEDURE STYLE
|
| Input Parameters  :
|
| Name                Description                                       Default
| ----------------------------------------------------------------------------------------
| DSETOUT             Specifies an output data set name                 _dsetout_
|                     Valid Values: A valid SAS data set name
|
| STATEMENTS          Specifies a list of SAS graph statements          AXIS TITLE 
|                     Valid Valus: One or more of AXIS TITLE            FOOTNOTE PATTERN 
|                     FOOTNOTE PATTERN LEGEND SYMBOL                    LEGEND SYMBOL        
|-----------------------------------------------------------------------------------------
| Output: The unit shall produce a SAS data set with SAS graph statements.
|-----------------------------------------------------------------------------------------
|Global macro variables created: None
|-----------------------------------------------------------------------------------------
| Macros called :
| (@) tr_putlocals
| (@) tu_abort
| (@) tu_chknames
| (@) tu_putglobals
| (@) tu_tidyup
| (@) tu_words
|-----------------------------------------------------------------------------------------
| Example:
|    %tu_getgstatements()
|-----------------------------------------------------------------------------------------
| Change Log :
|
| Modified By :
| Date of Modification :
| New Version Number :
| Modification ID :
| Reason For Modification :
+---------------------------------------------------------------------------------------*/

%macro tu_getgstatements(
   dsetout=_dsetout_,
   statements=AXIS TITLE FOOTNOTE PATTERN LEGEND SYMBOL
   );    
        
   /*
   / Call %tr_putlocals to echo the macro name and version.
   / Call %tu_putglobals to echo the parameter values and values of global macro
   /      variables to the log.
   /------------------------------------------------------------------------------------*/
   
   %local MacroVersion;
   %let MacroVersion = 1 build 1;

   %include "&g_refdata./tr_putlocals.sas";
   %tu_putglobals(varsin=)
   
   %local l_prefix l_ls l_ps l_tmp l_i;
   %let l_prefix=_gstate;
      
   /*
   / Perform parameter validation. After all have been validated, if an error is
   / found then call %tu_abort.
   /------------------------------------------------------------------------------------*/
                     
   %if %nrbquote(&dsetout) eq %then
   %do;   
      %let g_abort=1;
      %put RTE%str(RROR): &sysmacroname: Required parameter DSETOUT is not given.;
   %end;
   %else %if %tu_chknames(&dsetout, DATA) ne %then 
   %do;   
      %let g_abort=1;
      %put RTE%str(RROR): &sysmacroname: DSETOUT(=&dsetout) is not a valid SAS data set name.;
   %end;
      
   %let statements=%qupcase(&statements);
   %if %nrbquote(&statements) eq %then
   %do;   
      %let g_abort=1;
      %put RTE%str(RROR): &sysmacroname: Required parameter STATEMENTS is not given.;
   %end;
   %else %do l_i=1 %to %tu_words(&statements);
      %let l_tmp=%qscan(&statements, &l_i, %str( ));
      %if %sysfunc(indexw(AXIS TITLE FOOTNOTE PATTERN LEGEND SYMBOL, &l_tmp)) le 0 %then
      %do;      
         %let g_abort=1;
         %put RTE%str(RROR): &sysmacroname: Value &l_tmp given in STATEMENTS(=&statements) is invalid. Valid value should be one or more of AXIS TITLE FOOTNOTE PATTERN LEGEND SYMBOL.;
      %end;
   %end;                                                                         
   
   %if &g_abort gt 0 %then %goto macerr;
   
   /* Normal Process */
   
   /* Define a temporary catalog to save the log of proc goptions */                     
   filename _tmpfile  CATALOG "work.&l_prefix.cat.temprpt.output";
   
   /* Save the linesize and pagesize options */
   %let l_ls=%sysfunc(getoption(LINESIZE));
   %let l_ps=%sysfunc(getoption(PAGESIZE));   
   
   options LINESIZE=200 PAGESIZE=500;
   
   proc goptions nolist &statements;
   run;
   /* print the goptions to temporary log file */                                               
   proc printto log=_tmpfile;
   run;
   
   proc goptions nolist &statements;
   run;
      
   proc printto log=log;
   run;      
   
   options linesize=&l_ls pagesize=&l_ps;
   
   /* read in statements */                                   
   data &dsetout;
      length type $1  number 8 name type1 $12 text foot $1000;
      keep type text number name;
      retain flag 0;      
      infile _tmpfile length=len;
      input @;
      input @1 foot $varying300. len;      
      name=upcase(scan(left(foot), 1, ' '));
      if flag and (name eq 'NOTE:') then stop;
      
      if substr(name, 1, 5) eq "TITLE" then type='T';
      else if substr(name, 1, 8) eq "FOOTNOTE" then type='F';
      else if substr(name, 1, 4) eq "AXIS" then type='A';
      else if substr(name, 1, 6) eq "SYMBOL" then type='S';
      else if substr(name, 1, 6) eq "LEGEND" then type='L';      
      else if substr(name, 1, 7) eq "PATTERN" then type='P';      

      if type eq 'T' then fl=5;
      else if type eq 'F' then fl=8;
      else if type eq 'A' then fl=4;
      else if type eq 'S' then fl=6;
      else if type eq 'L' then fl=6;      
      else if type eq 'P' then fl=7;
      
      if ( length(name) gt fl + 2 ) or ( length(name) le fl ) then type='';
      
      if not missing(type) then
      do;
         len1=len;
         flag=1;
         do i=1 to 10;
            if substr(foot, length(foot)) eq ';' then leave;
            else do;
               input @;
               input @1 text $varying1000. len;
               foot=substr(foot, 1, len1)||substr(text, 1, len);
               len1=len+len1;          
            end;
         end; /* do i=1 to 10 */
         foot=left(foot);
         number=input(substr(name, fl + 1), 6.0);
         type1=substr(name, 1, fl);
         len1=length(foot);  
         if substr(foot, len1, 1)=';' then substr(foot, len1, 1)=' ';       
         text=left(substr(foot, length(name) + 1));  
         if indexw("&statements", type1) then output;   
      end; /* if not missing(type) */
   run;   
   filename _tmpfile clear;
   
   /* Sort output data set */
   proc sort data=&dsetout out=&dsetout;
      by type number;
   run;
   
   /* Delete temporary catalog */
   proc datasets nowarn nolist lib=work memtype=cat;
      delete &l_prefix:;
   run;
   quit; 
   
   %goto macend;
 
%MACERR:

   %let g_abort=1;
   %tu_abort(
      option=force
      );

%MACEND:

   /*
   / Call %tu_tidyup to delete temporary datasets 
   /------------------------------------------------------------------------------------*/

   %tu_tidyup(
       glbmac=none,
       rmdset=&l_prefix:
      );
   quit;

%mend tu_getgstatements;

