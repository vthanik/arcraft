/*----------------------------------------------------------------------------+
 | Macro Name    : tu_tidyup.sas
 |
 | Macro Version : 4
 |
 | SAS version   : SAS v8.2
 |
 | Created By    : Lee J. Seymour
 |
 | Date          : 08-May-03
 |
 | Macro Purpose : Performs removal of temporary SAS datasets and/or global
 |                 macro variables
 |
 | Macro Design  : Procedure
 |
 | Input Parameters :
 |
 | NAME       DESCRIPTION                                    DEFAULT
 |
 | rmdset     Specifies which datasets to remove. The
 |            default will remove all. Valid values
 |            are dataset name(s), prefix of dataset
 |            names _NONE_ or left blank.
 |
 | glbmac     Specifies global macro variables to remove
 |            Valid values, global macro variable names
 |            "none" or left blank.
 |
 | kpdset     Specifies datasets to keep if rmdset is
 |            blank. Valid values, dataset name(s),
 |             _ALL_ or left blank
 |
 | Output:    None
 |
 | Global macro variables created:  None
 |
 |
 | Macros called :
 | (@) tu_words
 | (@) tu_putglobals
 | (@) tu_abort
 |
 | **************************************************************************
 | Change Log :
 |
 | Modified By : Lee Seymour
 | Date of Modification : 09-Jul-03
 | New Version Number : 1/2
 | Modification ID : LS01
 | Reason For Modification : Changes after source code review
 |
 |
 | Modified By : Lee Seymour
 | Date of Modification : 10-Jul-03
 | New Version Number : 1/3
 | Modification ID : LS01
 | Reason For Modification : Added in memtype=view to remove data views ,
 |                           if kpdset=_ALL_ remove no datasets
 |                           Fixed removal of all datasets. Added comments
 |                           to log if nothing deleted
 |
 | Modified By : Lee Seymour
 | Date of Modification : 14-Jul-03
 | New Version Number : 1/4
 | Modification ID : LS01
 | Reason For Modification : Message to log if colon is used in rmdset without
 |                           a prefix
 |
 | Modified By : Yongwei Wang
 | Date of Modification : 18-May-04
 | New Version Number : 2 
 | Modification ID : YW001
 | Reason For Modification : Added 'quit;' to end the proc dataset.
 |
 |
 | Modified by:             Yongwei Wang
 | Date of modification:    02Apr2008
 | New version number:      3/1
 | Modification ID:         YW001
 | Reason for modification: Based on change request HRT0193
 |                          1. Echo macro name and version and local/global macro                                            
 |                             variables to the log when g_debug > 0    
 |                          2. Replaced %inc tr_putlocal.sas with %put statements
  |
 | Modified by:             Lee Seymour
 | Date of modification:    29Oct2013
 | New version number:      4/1
 | Modification ID:         LS002
 | Reason for modification: Replaced options with option in tu_abort calls
 |                             
  +----------------------------------------------------------------------------*/

%macro tu_tidyup(
                 rmdset=,    /* Datasets to remove. Blank will remove all */
                 glbmac=,    /* Global macro variables to remove */
                 kpdset=     /* Datasets to keep                 */
                 );

    %local MacroVersion;
    %let MacroVersion = 4;
    
    
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

    /*
    / If value of g_debug is greater than or equal to 5 then
    / the tidyup macro will not remove any work datasets or
    / global macro variables
    /------------------------------------------------------------*/


 %if &g_debug lt 5 %then
  %do;

  %local dsn        /* Count of datasets on either rmdset or kpdset */
         rmexist    /* Datasets to remove that exist                */
         rmnoexist  /* Datasets do not exist in rmdset              */
         kpexist    /* Datasets to keep that exist                  */
         kpnoexist  /* Datasets do not exist in kpdset              */
         macvar     /* Global macro variable                        */
         mvn ;      /* Count of global macro variables              */


        /* Parameter Processing */

        /*
        / Check to see if datasets or views specified in rmdset or kpdset
        / exist or not.  If not create new local variable containing
        / only those that exist to avoid SAS error with proc datasets
        /--------------------------------------------------------------*/



      %if &rmdset ne and %index(&rmdset,:) eq 0 and %upcase(&rmdset) ne _NONE_ %then
      %do;
           %do dsn = 1 %to %tu_words(&rmdset) ;
                %if %sysfunc(exist(%scan(&rmdset,&dsn))) eq  0 %then
                %do;
                    %if %sysfunc(exist(%scan(&rmdset,&dsn),view)) eq 0 %then
                    %do;
                       %let rmnoexist = &rmnoexist %scan(&rmdset,&dsn);
                    %end;
                    %else %let rmexist=&rmexist %scan(&rmdset,&dsn);
                %end;  /* End of exist checks*/

               %else
               %do;
                   %let rmexist = &rmexist %scan(&rmdset,&dsn);
               %end;
           %end; /* End of do dsn loop*/
      %end; /* End of rmdset loop */
      %if %index(&rmdset,:) ne 0 %then %let rmexist=&rmdset;





      %if &kpdset ne and &kpdset ne _ALL_ %then
      %do;
           %do dsn = 1 %to  %tu_words(&kpdset)  ;
                %if %sysfunc(exist(%scan(&kpdset,&dsn))) eq  0 %then
                %do;
                   %if %sysfunc(exist(%scan(&kpdset,&dsn),view)) eq  0 %then
                   %do;
                       %let kpnoexist = &kpnoexist %scan(&kpdset,&dsn);
                   %end;
                   %else %let kpexist=&kpexist %scan(&kpdset,&dsn);
                %end;   /*End of exist checks*/

                %else
                %do;
                   %let kpexist = &kpexist %scan(&kpdset,&dsn);
                %end;
           %end; /* end of do dsn loop*/
      %end; /*End of kpdset loop*/
      %if %upcase(&kpdset)=_ALL_ %then %let kpexist=&kpdset;


        /* Comment to the log if datasets specified do not exist or if
        / rmdset and kpdset both specified.
        | If rmdset just contains a colon.
        /--------------------------------------------------------------*/

        %if &rmnoexist ne %then
        %do;
           %put %str(RTW)ARNING: &sysmacroname : Temporary work dataset(s)=> &rmnoexist <= do not exist but were specified to be deleted;
        %end;

        %if &kpnoexist ne %then
        %do;
           %put %str(RTW)ARNING: &sysmacroname : Temporary work dataset(s)=> &kpnoexist <= do not exist but were specified to be kept;
        %end;

        %if &rmexist ne and &kpexist ne %then
        %do;
           %put %str(RTW)ARNING: &sysmacroname : Datasets have been specified to be deleted and also kept.;
        %end;

        %if &rmexist eq : %then %do;
           %put %str(RTW)ARNING: &sysmacroname : The colon in rmdset should be preceded by a prefix;
        %end;


        /*
        /  Remove all temporary work datasets
        /--------------------------------------*/

        %if &rmexist eq  and &kpexist eq and &rmdset eq  %then %do;
            proc datasets kill memtype=(data view) nolist;
            quit;  /* yw001 */
            run;

            %if &syserr GT 0 %then
            %do;
                %let g_abort = 1;
                %put %str(RTE)RROR: &sysmacroname did not work;
                %tu_abort(option=force); /*LS002*/
            %end;
         %end;



        /*
        / Remove selected datasets
        /-----------------------------------*/

        %if &rmexist ne and %upcase(&rmexist) ne _NONE_ and &kpexist eq  %then
        %do;
            proc datasets memtype=(data view) nolist;
              delete &rmexist;
            run;

            %if &syserr GT 0 %then
            %do;
                %let g_abort = 1;
                %put %str(RTE)RROR: &sysmacroname did not work;
                %tu_abort(option=force); /*LS002*/
            %end;
        %end;

        /*
        / Remove all except those specified
        /----------------------------------*/

        %if &rmexist eq and &kpexist ne and %upcase(&kpexist) ne _ALL_ %then
        %do;
            proc datasets memtype=(data view) nolist;
              save &kpexist;
            run;

            %if &syserr GT 0 %then
            %do;
                %let g_abort = 1;
                %put %str(RTE)RROR: &sysmacroname did not work;
                %tu_abort(option=force);   /*LS002*/
            %end;
        %end;


        %if %upcase(&rmdset) eq _NONE_ or %upcase(&kpdset) eq _ALL_ %then
        %do;
            %put %str(RTN)OTE : &sysmacroname : No datasets were deleted ;
        %end;


        /*
        / Check global macro variables exist
        /----------------------------------*/

       %if &glbmac ne and %upcase(&glbmac) ne NONE %then
       %do;

           %do mvn = 1 %to %tu_words(&glbmac) ;
             %let macvar=%scan(&glbmac,&mvn);
             %let dsid =%sysfunc(open(sashelp.vmacro(where=(name="%upcase(&macvar)" and scope="GLOBAL"))));
             %let rc=%sysfunc(fetch(&dsid));
             %let closerc =%sysfunc(close(&dsid));

             %if &rc ne 0 %then
             %do;
               %put %str(RTW)ARNING: &sysmacroname: &macvar is not a Global Macro Variable.;
             %end;

             /*
             / Remove selected global macro variables
             /--------------------------------------------*/

             %else
             %do;
                 %symdel &macvar;
                 %put %str(RTN)OTE : &sysmacroname: Deleted &macvar (Global macro variable);
             %end;

         %end; /*Of do mvn loop */

       %end;  /* End of %if &glbmac ne and %upcase(&glbmac) ne NONE %then do */



        /*
        / Remove all global macro variables
        /----------------------------------------*/

        %if %upcase(&glbmac) eq  %then
        %do;

            data _tidyup;
               set sashelp.vmacro;
            run;

            data _null_;
               set _tidyup;
               if scope eq 'GLOBAL' then
                     call execute('%symdel ' || trim(left(name))||';');
            run;

         %put %str(RTN)OTE: &sysmacroname : All global macro variables deleted;


           proc datasets memtype=data;
             delete _tidyup;
           run;

        %end; /* Of global macro variable deletion  */


 %end;  /* End of g_debug do loop.*/

%tu_abort;

%mend tu_tidyup;
