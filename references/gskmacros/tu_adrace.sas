/******************************************************************************* 
|
| Program Name    : tu_adrace.sas
|
| Program Version :  1 Build 1
|
| MDP/Protocol ID : 
|
| Program Purpose : This unit shall be a utility to facilitate the production of following variables RACEOR, RACECOMB, RACECDET and ARACE
                    using SDTM DM and supplemnetary DM domains.
|
| SAS Version     : SAS v9.4   
|
| Created By      : Sadhna 2 Singh  (ss909083)
| Date            : 9-June-2017
|
|******************************************************************************* 
|
| Input Parameters:
|
| NAME                      DESCRIPTION                                         REQ/OPT   DEFAULT
| -------------  ----------------------------------------------------------------------- ----------
| DSETIN           Specifies the dataset name for                               REQ       (SDTM.DM)    
|                  which the race variables are to be added  
|
|                  Valid values:  Any valid dataset which has
|                  RACE variable present in it and also has only one 
|                  record per subject.
|                   
| DSETINSUPP       Specifies the SDTM --SUPP dataset                            REQ       (SDTM.SUPPDM)
|                  (Eg:SUPPDM) that contains supplementary 
|                  information  
|
|                  Valid values: SDTM.SUPPDM                  
|
| LISTVAR          Specifies race variables name to be derived by the 
|                  the utility macro
|
|                  Valid values: ARACE or                                       REQ       (Blank)
|                  ARACE RACEOR RACECDET RACECOMB                                                                                 
|
| DSETOUT          Specifies the name of the output                             REQ       (Blank)
|                  dataset to be created.
|
|                  Valid values: valid dataset name but the name should
|                  not be same as input dataset name.
|
| Output:  This utility creates requested race variables in the output  dataset.
|
|
| Nested Macros: 
| (@) tu_putglobals
| (@) tu_abort
| (@) tu_chknames
| (@) tu_adsuppjoin 
| (@) tu_tidyup
| (@) tu_chkvarsexist
| (@) tu_chkdups
| (@) tu_words
|******************************************************************************* 
| Change Log 
|
| Modified By: 
| Date of Modification: 
|
| Modification ID: 
| Reason For Modification: 
|
********************************************************************************/ 

%macro tu_adrace(
      dsetin=sdtm.dm 
    , dsetinsupp=sdtm.suppdm 
    , dsetout=
    , listvar=       
                 );

   /*
  / Echo parameter values and global macro variables to the log.
  /----------------------------------------------------------------------------*/

  %local MacroVersion;
  %let MacroVersion = 1;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_abort g_refdata g_subjid) 

  /*
  /  Set up local macro variables
  / ---------------------------------------------------------------------------*/

  %local prefix chkdup lastdset;
  %let prefix = _adrace;
  

  /*
  / PARAMETER VALIDATION
  /----------------------------------------------------------------------------*/

  %let dsetin             = %nrbquote(&dsetin.);
  %let dsetout            = %nrbquote(&dsetout.);
  %let dsetinsupp         = %nrbquote(%upcase(&dsetinsupp.));
  %let listvar            = %nrbquote(%upcase(&listvar.));


   /* Validating if non-missing values are provided for parameters DSETIN,  DSETINSUPP, LISTVAR and DSETOUT */
  %if &dsetin. eq %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETIN is a required parameter, provide a dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
  /* Validating if dataset has duplicates records per subject*/
  %else  %do;
     %if %SCAN(&dsetin,2,()) NE %STR() %then %do; 
        %tu_chkdups(dsetin = %SCAN(&dsetin,1,()),byvars = &g_subjid, retvar = chkdup,dsetout=chkdup);
     %end;
     %else %do;
        %tu_chkdups(dsetin = &dsetin,byvars = &g_subjid, retvar = chkdup,dsetout=chkdup); 
     %end;
     %if &chkdup > 0 %then %do;
        %put RTE%str(RROR:) &sysmacroname.: &DSETIN dataset contains more than one record per subject. Macro expects one record per subject in the dataset passed in DSETIN parameter.;
        %let g_abort = 1;
        %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
      %end;
  %end;

  %if &dsetout. eq %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETOUT is a required parameter, provide a dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

   %if &dsetinsupp. eq %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETINSUPP is a required parameter, provide a dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

   %if &listvar. eq %str() %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter LISTVAR is a required parameter, provide the list of required race variables.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Aborting the execution */
  %if &g_abort eq 1 %then
  %do;
    %tu_abort;
  %end;

   /* Validating if DSETIN, DSETINSUPP and DSETOUT are valid dataset names  and also if they exist */

   /* Validating if DSETIN valid dataset name */
  %if %tu_chknames(%scan(&dsetin., 1, %str(%() ), DATA ) ne %then %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETIN refers to dataset &dsetin which is not a valid dataset name;
    %let g_abort=1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

   /* Validating if DSETIN dataset exists */
  %if %SYSFUNC(EXIST(%scan(&dsetin, 1, %str(%() ) )) NE 1 %then %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETIN refers to dataset &dsetin which does not exist;
    %let g_abort=1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

 /* Validating if DSETINSUPP valid dataset name */
  %if %tu_chknames(%scan(&dsetinsupp., 1, %str(%() ), DATA ) ne %then %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETINSUPP refers to dataset &dsetinsupp which is not a valid dataset name;
     %let g_abort=1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
  /* Validating if DSETINSUPP dataset exists */
   %if %SYSFUNC(EXIST(%scan(&dsetinsupp., 1, %str(%() ) )) NE 1 %then %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETINSUPP refers to dataset &dsetinsupp. which does not exist;
    %let g_abort=1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
 /* Validating if DSETOUT valid dataset name */
  %if %tu_chknames(%scan(&dsetout., 1, %str(%() ), DATA ) ne %then %do;
    %put RTE%str(RROR:) &sysmacroname.: Macro Parameter DSETOUT refers to dataset &dsetout which is not a valid dataset name;
    %let g_abort=1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;

  /* Aborting the execution */
  %if &g_abort eq 1 %then %do;
    %tu_abort;
  %end;

    /* Validating if DSETOUT is not same as DSETIN */
  %if %qupcase(&dsetout.) eq %qupcase(%scan(&dsetin, 1, %str(%() )) %then
  %do;
    %put RTE%str(RROR:) &sysmacroname.: The Output dataset name is same as Input dataset name.;
    %let g_abort = 1;
    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
  %end;
    /* Aborting the execution */
  %if &g_abort eq 1 %then  %do;
    %tu_abort;
  %end;


   /* Validating LISTVAR: This parameter should either contain ARACE or 
	contain all the following variables as values: RACEOR RACECOMB RACECDET ARACE*/

  %if &listvar. ne %str() %then %do;
	  %if %tu_words(&listvar)=1 and %upcase(&listvar) ne ARACE %then
	  %do;
    	    %put RTE%str(RROR:) &sysmacroname.: Invalid value passed in LISTVAR parameter.If parameter LISTVAR has one value then it should be ARACE.;
    	    %let g_abort = 1;
    	    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;          
      %end;	
	  %else %if %tu_words(&listvar) > 1 and %tu_words(&listvar) <4 %then %do;
            %put RTE%str(RROR:) &sysmacroname.: Insufficient values passed in LISTVAR parameter.Parameter LISTVAR either takes one value which should be ARACE or takes four values which are  ARACE RACECOMB RACECDET RACEOR. ;
    	    %let g_abort = 1;
    	    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;  
	  %end;	
      %else  %if %tu_words(&listvar)=4 and (%sysfunc(find(%upcase(&listvar),ARACE))=0 or %sysfunc(find(%upcase(&listvar),RACECDET))=0 or %sysfunc(find(%upcase(&listvar),RACECOMB))=0 or %sysfunc(find(%upcase(&listvar),RACEOR))=0) %then %do;
    	    %put RTE%str(RROR:) &sysmacroname.: Invalid values passed in LISTVAR parameter. Parameter LISTVAR should have ARACE RACECOMB RACECDET RACEOR .;
    	    %let g_abort = 1;
    	    %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;          
      %end;		 
  %end;
   /*
  / Main Processing starts here.
  / ---------------------------------------------------------------------------*/

    /* Create work dataset if DSETIN contains dataset options */
  %if %SCAN(&dsetin,2,()) NE %STR() %then %do;
    data  &prefix._dsetin;
      set %unquote(&dsetin);
    run;

    %let lastdset=&prefix._dsetin;
  %end;
  %else %do;
    %let lastdset=&dsetin;
  %end;


    /* If the RACE variable does not  exist in the input dataset then throw error*/

   %if  %length(%tu_chkvarsexist(dsetin=&lastdset, varsin=race, returnexistvars=N)) ge 1 %then %do;
       %put RTE%str(RROR:) &sysmacroname.: Race variable should be present in &lastdset dataset.;
       %let g_abort = 1;
       %put RTN%str(OTE:) &sysmacroname.: The value of g_abort is being set to &g_abort;
       %if &g_abort eq 1 %then %do;
         %tu_abort;
       %end;
    %end;


  /* If the LISTVAR variables exist in the input dataset then dropping  them from input dataset*/

    %let existvars = %tu_chkvarsexist(dsetin=&lastdset, varsin=&listvar, returnexistvars=Y);

    %if %length(&existvars) ne 0 %then  %do;
        DATA &prefix._novarexist;
            SET &lastdset ;
            DROP &existvars;
            %put RTN%str(OTE:) &sysmacroname.: Following variables &existvars are dropped from &lastdset dataset as these variables are also requested in LISTVAR parameter for derivation.;  
        RUN;
        %let lastdset=&prefix._novarexist;
    %end;

    /* storing all the variables of the input dataset in a macro variable. Final output dataset should have: existing variables + variables specified in LISTVAR */

    %if %tu_words(&lastdset,delim=%str(.))=2 %then %do;
            PROC SQL NOPRINT;
        	 SELECT distinct name into : dsetinvars separated by " "
        	 FROM dictionary.columns
        	 WHERE UPCASE(libname)=UPCASE(SCAN("&lastdset.",1,".")) AND UPCASE(memtype)="DATA" and
        	 UPCASE(memname)=UPCASE(SCAN("&lastdset.",2,"."));
        	QUIT;
       %end;
       %else %do;
            PROC SQL noprint;
	         SELECT distinct name into : dsetinvars separated by " "
	         FROM DICTIONARY.COLUMNS
	        WHERE UPCASE(LIBNAME)="WORK" AND UPCASE(memtype)="DATA" and
	        UPCASE(MEMNAME)=%UPCASE("&lastdset.");
	        QUIT;
       %end;

    /* Calling tu_adsuppjoin to merge supplemental dataset with parent domain dataset */

  %tu_adsuppjoin(dsetin=&lastdset.,
                    dsetinsupp=&dsetinsupp.,
                    dsetout= &prefix._supp
                    );
    
    /*-creating macro variables TOTRACE (to store number of variables containing information of RACE#) and RACE to store the names of such variables-*/


    PROC SQL NOPRINT ;
    SELECT COUNT(name),name  INTO :totrace, :race SEPARATED BY " " 
    FROM dictionary.columns 
    WHERE UPCASE(libname)="WORK" AND UPCASE(memname)=%upcase("&prefix._supp")
    AND (ANYDIGIT(name)=5 AND UPCASE(name)  LIKE "RACE%") ;

    /*-creating macro variables TOTRACEOR (to store number of variables containing information of RACEOR#) and RACEOR to store the names of such variables-*/

    SELECT COUNT(name),name INTO :totraceor, :raceor SEPARATED BY " " 
    FROM dictionary.columns 
    WHERE UPCASE(libname)="WORK" AND UPCASE(memname)=%upcase("&prefix._supp")
    AND ((ANYDIGIT(name)=7 AND UPCASE(name)  like "RACE%") or (LENGTH(COMPRESS(name,,'d'))=6 AND UPCASE(name)  LIKE "RACE%")) 
    ;
    QUIT;
    

   /*
  / Domain specific derivations.
  / ---------------------------------------------------------------------------*/

     DATA &prefix._arace ;
     LENGTH &listvar $ 200;
          SET &prefix._supp;
          

          /*--array to group collected race variables (RACE#)--*/
          ARRAY dmrace(&totrace) $ &race. ;

           /*--array to group collected original race variables (RACEOR#)--*/
          ARRAY dmraceor(&totraceor) $ &raceor. ;

           /*--array to create variables to hold the part of  collected original race variables (RACEOR#) after "-" 
	   example: if raceor =WHITE - WHITE/CAUCASIAN/EUROPEAN HERITAGE then
           _dmraceor_ will be equal to WHITE/CAUCASIAN/EUROPEAN HERITAGE--*/
          ARRAY _dmraceor_ (&totraceor) $ 200 ; 
          
          *-creating a macro variable which will hold number of collected races for a subejct--;

          __nonmiss=0;
          DO __i=1 TO DIM(dmraceor) ;
              IF MISSING(dmraceor(__i))=0 THEN __nonmiss=__nonmiss+1;
          END;

          DO __i=1 TO __nonmiss ;
              IF UPCASE(dmraceor(__i))="AFRICAN AMERICAN/AFRICAN HERITAGE" THEN dmraceor(__i)="BLACK OR AFRICAN AMERICAN";
          END;

          DO __j=1 TO __nonmiss;
              _dmraceor_(__j)=IFC(INDEX(dmraceor[__j],"-")>0,STRIP(SCAN(dmraceor[__j],2,"-")),STRIP(dmraceor[__j]));
          END;

          
       *-code to programme analysis race variables (ARACE, RACECOMB RACECDET and RACEOR) for  subjects with MULTIPLE RACES--;
          IF UPCASE(race)='MULTIPLE' THEN 
              DO;
                  arace=STRIP(race);CALL SORTC(OF dmrace(*));racecomb=CATX(' & ',OF dmrace(*));
                  CALL SORTC(OF _dmraceor_(*));CALL SORTC(OF dmraceor(*));
                  DO __k=1 TO __nonmiss;
                      raceor=dmraceor(__k);OUTPUT;
                  END;
          END;
          *-code to programme analysis race variables (ARACE, RACECOMB  RACECDET and RACEOR) for ASIAN subjects--;
                
                    *--if Subject are ASIAN with only one sub race in ASIAN---;
          ELSE IF UPCASE(race) = "ASIAN" AND __nonmiss=1 THEN 
          DO;                                            
               arace=raceor1;
               raceor=raceor1;
               IF INDEX(UPCASE(raceor1),"CENTRAL")>0 AND INDEX(UPCASE(raceor1),"SOUTH")>0 THEN DO; racecomb=STRIP(SCAN(raceor1,2,"-"));
               racecdet=racecomb;OUTPUT;END;
               ELSE DO;racecomb="JAPANESE HERITAGE/EAST ASIAN HERITAGE/SOUTH EAST ASIAN HERITAGE";racecdet=STRIP(SCAN(raceor1,2,"-"));OUTPUT;END;
          END;
                    *--if Subject are ASIAN with more than one sub races in ASIAN---;
          ELSE IF UPCASE(race)="ASIAN" AND __nonmiss>1 THEN 
          DO;
               arace='MIXED ASIAN RACE';racecomb=arace; racecdet=arace;
               DO __l=1 TO __nonmiss;
                 raceor=STRIP(dmraceor(__l));OUTPUT;
               END;
          END;
           *-code to programme analysis race variables (ARACE, RACECOMB  RACECDET and RACEOR) for WHITE subjects--;

                *--if Subject are WHITE with only one sub race in WHITE---;
          ELSE IF UPCASE(race)="WHITE" AND __nonmiss=1 THEN 
          DO;
               arace=raceor1;
               raceor=raceor1;
               racecdet=STRIP(SCAN(raceor1,2,"-"));
               OUTPUT;                            
          END;         
                
                    *--if a subjetc are WHITE with more than one sub races in WHITE---;
          ELSE IF UPCASE(race)="WHITE" AND __nonmiss>1 THEN 
          DO;
               arace='MIXED WHITE RACE'; racecdet=arace;
               DO __m=1 TO __nonmiss;
                 raceor=STRIP(dmraceor(__m));OUTPUT;
               END;
          END;
          ELSE DO;
                arace=raceor1;raceor=raceor1;OUTPUT;
          END;
          DROP __: &race. &raceor. _dmraceor_:  ;
    RUN;

   /*
  / Code to output the correct variables and correct number of observations depending upon LISTVAR parameter
  / If LISTVAR just have  ARACE then number of records in DSETIN should match number of records in DSETOUT
  / otheriwse it might increase in DSETOUT due to various reasons e.g. multiple races.
  / --------------------------------------------------------------------------------------------------------------------------------------------*/

    %if %upcase(&listvar)=ARACE %then %do;
        PROC SORT DATA=&prefix._arace  ;
        BY &g_subjid.  &listvar. ;
        RUN;

        DATA &dsetout ;
            SET &prefix._arace;
            BY &g_subjid.  &listvar. ;
            IF FIRST.&g_subjid. ;
            KEEP &dsetinvars. &listvar. ;
        RUN;
    %end;
    %else %do;

       PROC SORT DATA=&prefix._arace  ;
       BY &g_subjid.  &listvar. ;
       RUN;

       DATA &dsetout ;
	   	 SET &prefix._arace ;
       	 KEEP &dsetinvars. &listvar. ;
       RUN;
    %end;

  /* Calling tu_tidyup to delete the temporary datasets. */

  %tu_tidyup(rmdset = &prefix.:,
             glbmac = none);

                    
%mend tu_adrace;

