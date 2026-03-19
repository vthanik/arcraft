/*******************************************************************************
|
| Macro Name:      ta_archive
|
| Macro Version:   5 build 1
|
| SAS Version:     9.4
|
| Created By:      Anthony J Cooper
|
| Date:            22-Oct-2014
|
| Macro Purpose:   Create transport files for SAS datasets and catalogs
|
| Macro Design:    Procedure Style
|
|******************************************************************************* 
| Change Log 
|
| Modified By: Anthony J Cooper
| Date of Modification: 07-Dec-2016
| Modification ID: AJC001
| Reason For Modification: To enable transport files to open automatically (HRT0317)
|                          1. Use SAS autocall macro LOC2XPT to create dataset
|                             transport files in V5 or V8 transport format
|                             instead of CPORT format.
|                          2. Rename i and j counter macro variables to avoid
|                             conflict with LOC2XPT
|
| Modified By: Anthony J Cooper
| Date of Modification: 20-Jan-2017
| Modification ID: AJC002
| Reason For Modification: Use FORMAT=V8 option in call to LOC2XPT macro to 
|                          ensure variable labels are not truncated.
|
| Modified By: Anthony J Cooper
| Date of Modification: 28-Apr-2017
| New Version Number : v3 build 1
| Modification ID: AJC003
| Reason For Modification: Add options nofmterr to prevent issue when datasets 
|                          have user-defined SAS formats (HRT0323)
|
| Modified By: Anthony J Cooper
| Date of Modification: 03-May-2017
| New Version Number : v4 build 1
| Modification ID: AJC004
| Reason For Modification: Use FORMAT=V9 option in call to LOC2XPT macro to 
|                          handle format names >8 characters (HRT0324)
|
| Modified By: Anthony J Cooper
| Date of Modification: 10-Aug-2017
| New Version Number : v5 build 1
| Modification ID: AJC005
| Reason For Modification: When a dataset has a label >40 chars, copy the
|                          dataset to WORK and truncate the dataset label
|                          before calling the LOC2XPT macro (HRT0326)
|
********************************************************************************/ 

%macro ta_archive(
);

/* Redirect log file to the specified location
/----------------------------------------------------------------------------*/
proc printto log="&log" new;
run;

/*
/ Echo macro version number and values of parameters and global macro
/ variables to the log.
/----------------------------------------------------------------------------*/
  
%LOCAL MacroVersion;
%LET MacroVersion=5 build 1;

%put ************************************************************;
%put * Macro name: &sysmacroname,  Macro Version: &macroVersion ;
%put ************************************************************;
%put * &sysmacroname has been called with the following parameters: ;
%put * ;
%put _local_;
%put * ;
%put ************************************************************;
%put * The following global macro variables are used: ;
%put * ;
%put %upcase(GLOBAL archive_path) %unquote(&archive_path);
%put %upcase(GLOBAL log) %unquote(&log);
%put * ;
%put ************************************************************;

/*
/ Define local macro variables
/----------------------------------------------------------------------------*/
 
%LOCAL prefix;
%LET prefix=%substr(&sysmacroname,3);

/****************************************
* Check archive_path exists
****************************************/

%let rc=%sysfunc(filename(fileref,"&archive_path"));
%if %sysfunc(fexist(&fileref)) = 0 %then
%do;
   %put %str(RTE)RROR: &sysmacroname : Directory specified by archive_path(=&archive_path) does not exist;
   %goto error;
%end;

/*****************************************************************
* Identify all sub-dirs below the archive_path
* Write details to filename reference
* Read in file to a SAS dataset
*****************************************************************/

filename archdir pipe "ls -Rl &archive_path | grep '/' | grep -v 'drwx'"   ;

/*********************************************************************************************************
* Read in file containing list of subdirectories into a SAS dataset and remove file
* Create macro variable pathlist containing list of all subdirectories below the archive_path directory
* Creat macro variable pathcount containing the number of subdirectories below the archive_path directory
*********************************************************************************************************/

data &prefix._rep;
infile archdir dsd truncover end=last;
input path $1-1024;
path=tranwrd(path,':','');
run;

proc sql noprint;
select distinct trim(left(path)) into : pathlist
separated by ' '
from &prefix._rep ;
quit;

proc sql noprint;
select count(distinct(path)) into : pathcount
from &prefix._rep ;
quit;

proc datasets nolist;
delete &prefix._rep;
run;
        
/************************************************************************
* Archive macro defined to identify files to be converted to XPT files
************************************************************************/

%macro archive(inlibref=,   /* Input Library reference      */
               memtype=,    /* CATALOG or DATA              */
               lib=         /* Full input directory path    */
               );

        /*********************************************************************************
        * Identify all datasets or catalogs that exist in the specified library
        *********************************************************************************/
                                                                                             
               proc sql;
                     create table &prefix._memlist as
                     select memname
                     from dictionary.members
                     where libname ="INLIB"   
                     and memtype="&memtype"
                     order by memname;
                quit;
                
        /***************************************************************
        * Check if memlist contains 0 observations. i.e specified
        * libname contains no datasets.  If so then jump to end of loop
        ***************************************************************/
        
                %let dsid=%sysfunc(open(&prefix._memlist, is));
                
                %if %sysfunc(attrn(&dsid,nobs))=0 %then 
                %do;
                    %let dsid=%sysfunc(close(&dsid));
                    %put RTNOTE: TA_ARCHIVE: No entries found in &lib. for memtype=&memtype;   
                    %goto endloop;
                %end;
                %else 
                %do;
                    %let dsid=%sysfunc(close(&dsid));
                %end;
             
             
        /************************************************************************************
        * If entries are found then :-
        * Create macro variable 'max' containing total number of datasets/catalogs found.
        * Create macro variables for each dataset/catalog dset1 dset2 dset3 etc.
        ************************************************************************************/
                
                data _null_;
                  set &prefix._memlist end=last;
                  by memname;
                  call symput ('dset'||strip(put(_n_,8.)), lowcase(memname));
                  if last then call symput('max',strip(put(_n_,8.)));
                run;
                
        /************************
        * Create transport files
        ************************/
                
               %do jj=1 %to &max; /* AJC001 rename counter variable */

                  /****************************************************
                   * AJC001 Handle datasets and catalogs separately
                   ****************************************************/

                   %if %upcase(&memtype) eq DATA %then
                   %do;
                       filename tranfile "&lib/%trim(%left(&&dset&jj.)).xpt";

                      /****************************************************
                       * LS005 Check dataset label length. If >40 characters
                       * copy the dataset to WORK and truncate the label.
                       ****************************************************/

                       proc sql noprint;
                         select memlabel into :ds_label trimmed
                         from dictionary.tables
                         where libname eq "%upcase(&inlibref.)" and memname eq "%upcase(&&dset&jj.)";
                       quit;

                       %if %length(&ds_label) <= 40 %then
                       %do;

                           %loc2xpt(filespec=tranfile,
                                    libref=&inlibref.,
                                    memlist=&&dset&jj.,
                                    format=V9); /* AJC004 change V8 to V9 option */

                       %end;

                       %else
                       %do;

                           %put %str(RTW)ARNING: TA_ARCHIVE: Dataset label for dataset %upcase(%trim(&&dset&jj.)) in directory &lib. is >40 characters.;
                           %put %str(RTW)ARNING: TA_ARCHIVE: Dataset label will be truncated to 40 characters when creating the SAS transport file.;

                           proc datasets library=work nolist;
                               copy in=&inlibref. out=work noclone;
                                   select &&dset&jj.;
                               modify &&dset&jj. (label="%substr(&ds_label,1,40)");
                           quit;

                           %loc2xpt(filespec=tranfile,
                                    libref=work,
                                    memlist=&&dset&jj.,
                                    format=V9);

                           proc datasets library=work nolist;
                               delete &&dset&jj.;
                           run;

                       %end;

                   %end;
                   %else
                   %do;
    				   libname libout  XPORT  "&lib/%trim(%left(&&dset&jj.)).cpt";
                       proc cport &memtype=&inlibref..&&dset&jj memtype=&memtype file=libout;
    	               run;
                   %end;

				   proc datasets library=&inlibref memtype=&memtype nolist;
                     delete &&dset&jj;
                   run;

                %end;

               %endloop:
                
        /******************************************
        *  Tidy up memlist datasets
        ******************************************/
                
               proc datasets nolist;
               delete &prefix._memlist:;
               run;
        
    %mend archive; /* end of archive macro */

    
/*************************************************
* Loop over each subdirectory
* archive macro called twice:-
* 1) Datasets
* 2) Catalogs
*************************************************/

options nofmterr; /* AJC003 */

%do ii=1 %to &pathcount; /* AJC001 rename counter variable */
        %let lib=%scan(&pathlist,&ii, %str( ));
        libname inlib "&lib";
        %archive(inlibref=inlib,memtype=DATA, lib=&lib);
        %archive(inlibref=inlib,memtype=CATALOG, lib=&lib);
%end;
 
%goto endmac;

/***************************************
* End macro in cases of e-rror messages
***************************************/
%error:

         %if %upcase(&sysenv) EQ BACK %then 
         %do;
             %put %str(RTE)RROR: ABORT program ;
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

%endmac:

%mend ta_archive;
%ta_archive;
