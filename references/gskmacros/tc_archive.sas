/******************************************************************************* 
|
| Program Name: tc_archive
|
| Program Version:  5 build 1
|
| MDP/Protocol ID: 
|
| Program Purpose: 
|
| SAS Version:  9.4
|
| Created By:   Lee Seymour
| Date:            30-Jan-2009
|
|******************************************************************************* 
| Change Log 
|
| Modified By:     Lee Seymour
| Date of Modification: 28-Aug-2014
|
| Modification ID: LS001
| Reason For Modification: To enable macro on migrated LINUX Servers 
|
| Modified By: Lee Seymour
| Date of Modification: 06-Dec-2016
| Modification ID: LS002
| Reason For Modification: To enable transport files to open automatically (HRT0317)
|                          1. Use SAS autocall macro LOC2XPT to create dataset
|                             transport files in V5 or V8 transport format
|                             instead of CPORT format.
|                          2. Update LINUX server names
|                          3. Fix small issue with summary report
|                          4. Rename i and j counter macro variables to avoid
|                             conflict with LOC2XPT
|
| Modified By: Lee Seymour
| Date of Modification: 18-Jan-2017
| Modification ID: LS003
| Reason For Modification: Use FORMAT=V8 option in call to LOC2XPT macro to 
|                          ensure variable labels are not truncated.
|
| Modified By: Lee Seymour
| Date of Modification: 03-May-2017
| New Version Number : v4 build 1
| Modification ID: LS004
| Reason For Modification: Use FORMAT=V9 option in call to LOC2XPT macro to 
|                          handle format names >8 characters (HRT0324)
|
| Modified By: Lee Seymour
| Date of Modification: 08-Aug-2017
| New Version Number : v5 build 1
| Modification ID: LS005
| Reason For Modification: When a dataset has a label >40 chars, copy the
|                          dataset to WORK and truncate the dataset label
|                          before calling the LOC2XPT macro (HRT0326)
|
********************************************************************************/ 
%macro tc_archive(sourcelib =  /* Full directory path for source dataset */
                  );

/******************************
* Define local macro variables
******************************/

options validvarname=v7;
title1 "Summary of Datasets/Catalogs found";

%global env;
/***************************************************************************************
* Identify the environment code is being run from and store in macro variable env
*****************************************************************************************/

filename hn  pipe 'echo $HOSTNAME';
filename ss pipe 'echo $SESSION_SVR';
filename iun pipe 'echo $_INIT_UTS_NODENAME';


data _null_;
  length _hostname hostname session_svr _init_uts_nodename $100;
  infile hn missover;  input hostname $;
  infile ss missover; input session_svr $;
  infile iun missover; input _init_uts_nodename $;
  if hostname ne '' then _hostname=upcase(hostname);
  else if session_svr ne '' then _hostname=upcase(session_svr);
  else if _init_uts_nodename ne '' then _hostname=upcase(_init_uts_nodename);
  else put 'RTE' 'RROR: unable to determine hostname from UNIX environment variables';
  call symput('host', trim(_hostname));
run;

/* LS002 Legacy server names left in place though code is redundant now as servers have been migrated and LOC2XPT is only in SAS 9.4. */

%if %sysfunc(indexw(USSUN8A UKWSV18,%upcase(&host))) %then %let env=leg_gw;
%else %if %sysfunc(indexw(HBU071 UPU150,%upcase(&host))) %then %let env=leg_sb;

/*LS001 Replaced phu058 with us1salx00259.  Added uk1salx00175 in advance of hbu211 migration*/
/* Modified syntax for identifying environment to resolve issue with 259 arenv environment spanning disks */
/*LS002 Added UK1SALX00148/US2SALX00080 as Linux development/test environments */
%else %if %sysfunc(indexw(HBU211 UK1SALX00175 UKWSV80D US1SALX00259 USSUNBV PHU059 UK1SALX00148 US2SALX00080,%upcase(&host))) %then 
%do;
       %if %index(%sysfunc(getoption(print)),arwork) %then %let env=arenv;
       %else %if %index(%sysfunc(getoption(print)),arprod) %then %let env=arenv;
       %else %if %index(%sysfunc(getoption(print)),dmwork) %then %let env=dmenv;

%end;
%else 
%do;
    %put Environment the driver is being run from cannot be identified;
    %goto error;
%end;



%put DEBUG: This code is running from &host /&env ;                        
                         

%if &env=arenv %then
%do; 
        %if %length(&sourcelib) gt 0 %then
        %put  %str(RTW)ARNING directory path &sourcelib is specified and will be ignored;
%end;


%if &env ne arenv %then
%do; 
        %if %length(&sourcelib) = 0 %then
        %do;
                %put  %str(RTE)RROR directory path SOURCELIB=&sourcelib is missing and is required;
                %goto error;
        %end;
        
%end;


/******************************************************
* Identify sourcelib if run in HARP arenv environment
******************************************************/

%if &env=arenv %then
%do;
    
        data _null_;
        sourcelib=symget('g_ardata');
        sourcelib=tranwrd(sourcelib,'ardata','  ');
        call symput('sourcelib',sourcelib);
        run;

%end;



%put DEBUG: Source Library is &sourcelib;                        



/****************************************
* Validate sourcelib exists
****************************************/


%let rc=%sysfunc(filename(fileref,"&sourcelib"));
%if %sysfunc(fexist(&fileref)) = 0 %then
%do;
   %put %str(RTE)RROR : &sysmacroname : sourcelib does not exist;
%goto error;
%end;





/*****************************************************************
* Count directory levels in the sourcelib.
* If the specified sourcelib is not to an appropriate level 
* (i.e study or reporting effort) then issue message and abort
******************************************************************/


data _null_;
  wordCount = 1;
  do while ( scan( "&sourcelib", wordCount) ^= '');
    wordCount+1;
  end;
  wordCount+(-1);
  call symput('sourcelibcount',wordCount);
run;


%if %index(UPU150 HBU071,&HOST) and &sourcelibcount lt 4 %then
%do;
   %put %str(RTE)RROR : &sysmacroname :  SOURCELIB=&sourcelib is not specified to the correct directory level;
   %put Sourcelib must be specified to 4 directory levels  e.g. /bioenv/dartn/cpd/study/ ;
   %goto error;
%end;

%if %index(USSUN8A,&HOST) and &sourcelibcount lt 4 %then
%do;
   %put %str(RTE)RROR : &sysmacroname :  SOURCELIB=&sourcelib is not specified to the correct directory level;
   %put Sourcelib must be specified to 4 directory levels  e.g. /data/usmedstat/mdp/study/ ;
   %goto error;
%end;


%if %index(UKWSV18,&HOST) and &sourcelibcount lt 5 %then
%do;
   %put %str(RTE)RROR : &sysmacroname :  SOURCELIB=&sourcelib is not specified to the correct directory level;
   %put Sourcelib must be specified to 5 directory levels  e.g. /GW/ukmedstat/data/mdp/study/ ;
   %goto error;
%end;     

%if &env=dmenv and &sourcelibcount lt 5 %then
%do;
   %put %str(RTE)RROR : &sysmacroname :  SOURCELIB=&sourcelib is not specified to the correct directory level;
   %put Sourcelib must be specified to 5 directory levels  e.g. /dmenv/dmwork/cpd/study/repeff/;
   %goto error;
%end;     



/*****************************************************************
* Identify all sub-dirs below the sourcelib
* Write details to filename reference
* Read in file to a SAS dataset
* Set up destination libname for non-harp environment studies
*****************************************************************/

filename archdir pipe "ls -Rl &sourcelib | grep '/' | grep -v 'drwx'"                                  ;

/*********************************************************************************************************
* Read in file containing list of subdirectories into a SAS dataset and remove file
* Create macro variable pathlist containing list of all subdirectories below the sourcelib directory
* Creat macro variable pathcount containing the number of subdirectories below the sourcelib directory
* If run from the arenv environment append directory paths for compound and study level refdata dirs
*********************************************************************************************************/

data rep;
infile archdir dsd truncover;
input path $1-100;
path=tranwrd(path,':','');
run;

%if %upcase(&env)=ARENV %then
%do;

 data crefdir;
 attrib path length=$100;
 path=symget('g_cfmtdir');
 run;
 
 data srefdir;
 attrib path length=$100;
 path=symget('g_sfmtdir');
 run;
 
 data rep;
 set rep crefdir srefdir;
 run;
  

%end;

proc sql noprint;
select distinct trim(left(path)) into : pathlist
separated by ' '
from rep ;
quit;

proc sql noprint;
select count(distinct(path)) into : pathcount
from rep ;
quit;





/************************************************************************
* Archive macro defined to identify files to be converted to XPT files
************************************************************************/

%macro archive(inlibref=,   /* Input Library reference      */
               memtype=,    /* CATALOG or DATA              */
               lib= ,       /* Full input directory path    */
               outlib=,      /* Full output directory path  */
               count=
               );
                    
        /*********************************************************************************
        * Identify all datasets or catalogs that exist in the specified library
        *********************************************************************************/
                                                                                             
               proc sql;
                     create table memlist as
                     select memname
                     from sashelp.vmember
                     where libname ="INLIB"   
                     and memtype="&memtype";
                quit;
                run;
                
        /***************************************************************
        * Check if memlist contains 0 observations. i.e specified
        * libname contains no datasets.  If so then jump to end of loop
        * Populate filelist dataset with a record stating none found
        ***************************************************************/
        
                %let dsid=%sysfunc(open(memlist, is));
                
                %if %sysfunc(attrn(&dsid,nobs))=0 %then 
                %do;
                    %let dsid=%sysfunc(close(&dsid));
                    
                    %if %sysfunc(exist(filelist))=0 %then
                    %do; /* LS002 fix small report issue */
                         data filelist;
                           attrib files length=$32767;
                           attrib directory length=$60;
                           attrib type length=$8;
                            count=&count;
                            directory="&lib";
                            type="&memtype";
                            files="None";
                         run;
                    %end;
                    
                    %else
                    %do;
                        data filelist;
                        set filelist end=last;
                        output;
                        if last then do;
                            count=&count;
                            directory="&lib";
                            type="&memtype";
                            files="None";
                            output;
                        end;
                        run;
                    %end;
                    %put No Datasets found in &lib.;   
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
        * Create macro variable dsetlist which contains list of datasets/catalogs found
        ************************************************************************************/
                
                proc sort data = memlist;
                 by memname;
                run;
                
                data memlist1;
                  set memlist;
                  by memname;
                  retain name 0;
                  if first.memname then name = name+1;
                  memname=lowcase(memname);
                run;
                
                data _null_;
                  set memlist1 end=last;
                  if last then call symput('max',trim(left(put(name,8.))));
                run;
                
                data _null_;
                  set memlist1;
                  by name;
                  namec=put(name,3.);
                  %do j = 1 %to &max;
                   if _n_=&j then  call symput ('dset'||left(namec), memname);
                  %end;
                run;
                
                proc sql noprint;
                select distinct(memname) into : dsetlist
                separated by ' '
                from memlist
                ;
                quit; 
                
                
        /*******************************************************************
        * Populate filelist dataset with a record of entries found
        *******************************************************************/
        
                    %if %sysfunc(exist(filelist))=0 %then
                    %do; /* LS002 fix small report issue */
                         data filelist;
                           attrib files length=$32767;
                           attrib directory length=$60;
                           attrib type length=$8;
                            count=&count;
                            directory="&lib";
                            type="&memtype";
                            files="&dsetlist";
                         run;
                    %end;
                    %else
                    %do;
                        data filelist;
                        set filelist end=last;
                        output;
                        if last then do;
                            count=&count;
                            directory="&lib";
                            type="&memtype";
                            files= "&dsetlist."; 
                            output;
                        end;
                        run;
                    %end;
                
        /*******************************************************
        * Check to see if output directory exists.
        * If not then create it
        *******************************************************/
               %let rc=%sysfunc(filename(fileref)); 
               %let rc=%sysfunc(filename(fileref,"&outlib"));
               
               %if %sysfunc(fexist(&fileref)) = 0 %then
               %do;
                   x "mkdir -p &outlib";
               %end;
               
                
        /************************
        * Create transport files
        ************************/
                
               %do jj=1 %to &max; /* LS002 rename counter variable */

                  /****************************************************
                   * LS002 Handle datasets and catalogs separately
                   ****************************************************/

                   %if %upcase(&memtype) eq DATA %then
                   %do;
                       filename tranfile "&outlib/%trim(%left(&&dset&jj.)).xpt";

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
                                    format=V9); /* LS004 change V8 to V9 option */

                       %end;

                       %else
                       %do;

                           %put %str(RTW)ARNING: TC_ARCHIVE: Dataset label for dataset %upcase(%trim(&&dset&jj.)) in directory &lib. is >40 characters.;
                           %put %str(RTW)ARNING: TC_ARCHIVE: Dataset label will be truncated to 40 characters when creating the SAS transport file.;

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
                       libname libout  XPORT  "&outlib/%trim(%left(&&dset&jj.)).cpt";
                       proc cport &memtype=&inlibref..&&dset&jj memtype=&memtype file=libout;
                       run;
                   %end;
               %end;
                
                
                
               %endloop:
                
        /******************************************
        *  Tidy up memlist datasets
        ******************************************/
                
               proc datasets;
               delete memlist:;
               run;
        
           
%mend; /* end of archive macro */



                            
/*************************************************
* Loop over each subdirectory
* Output library is defined based on environment
* archive macro called twice:-
* 1) Datasets
* 2) Catalogs
*************************************************/

%do ii=1 %to &pathcount; /* LS002 rename counter variable */

         %let lib=%scan(&pathlist,&ii, %str( ));
         libname inlib "&lib";
        
        %if %upcase(&env) ne ARENV %then
        %do;
              %if &env=leg_sb %then %let outlib=%sysfunc(tranwrd(&lib,bioenv,bioenv/staging));
              %if %index(&lib,usmedstat) %then %let outlib=%sysfunc(tranwrd(&lib,usmedstat,usmedstat/staging));
              %if %index(&lib,ukmedstat) %then %let outlib=%sysfunc(tranwrd(&lib,ukmedstat/data,ukmedstat/data/staging));
              %if %upcase(&env)=DMENV %then %let outlib=%sysfunc(tranwrd(&lib,dmwork,dmwork/staging));
        %end;
        %else %if %upcase(&env) = ARENV %then %let outlib=&lib;

        
        %archive(inlibref=inlib,memtype=DATA, lib=&lib, outlib=&outlib, count=&ii);
        %archive(inlibref=inlib,memtype=CATALOG, lib=&lib, outlib=&outlib, count=&ii);
%end;


 
/********************************************************************
*  Produce summary report of all directories scanned and files found
********************************************************************/

 proc report data=filelist headline headskip split='!';
 columns count directory type files;
 define count /order noprint;
 define directory / order width=60 "Directory";
 define type / order width=8 "Type";
 define files/display width=60 flow "Files";
 break after directory / skip;
 run;


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


%mend;


