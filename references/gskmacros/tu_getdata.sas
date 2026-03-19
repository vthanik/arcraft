/****************************************************************************
| Macro Name    : tu_getdata.sas
|
| Macro Version : 4 
|                                                                            
| SAS version   : SAS v8.2                                                  
|                                                                            
| Created By    : Anup R Patel 
|                                                                            
| Date          : 01-Jul-2003
|                                                                            
| Macro Purpose : Takes input dataset and creates for the population  
|                 specified an analysis dataset and/or population 
|                 dataset 
|                                                                           
| Macro Design  : Procedure                                                          
|                                                                           
| Input Parameters :
|                                                                           
| NAME         DESCRIPTION                                DEFAULT
|                         
| DSETIN       Specifies the name of the input dataset    None
|              (Req)
|              Valid values: dataset name
|
| DSETOUT1     Specifies the name of the analysis         None
|              output dataset (Opt)
|              Valid values: V7 dataset name
|
| DSETOUT2     Specifies the name of the population       None
|              output dataset (Opt)
|              Valid values: V7 dataset name
|                                                                                       
|                                                                           
| Output: Will produce two forms of output
|         1) Analysis dataset
|         2) Population dataset                                                                  
|                                                                           
| Global macro variables created: None                                           
|                                                                           
|                                                                           
| Macros called :
| (@) tr_putlocals
| (@) tu_putglobals 
| (@) tu_chknames
| (@) tu_chkvarsexist
| (@) tu_tidyup
| (@) tu_abort
| (@) tu_words
| (@) tu_chkvartype
|
| Example:
| %tu_getdata(dsetin   = ardata.demo,
|             dsetout1 = analdata,
|             dsetout2 = popdata
|             );                                                         
|
| %tu_getdata(dsetin   = ardata.demo,
|             dsetout1 = ,
|             dsetout2 = popdata
|             );                                                         
|                                                                          
|                                                                            
| ************************************************************************** 
| Change Log :                                                               
|                                                                            
| Modified By : Anup Patel                                                             
| Date of Modification : 25-Sep-2003                                                   
| New Version Number : 1/2                                                   
| Modification ID :                                                          
| Reason For Modification : Corrected prompted by UTC testing.      
|                                            
| **************************************************************************  
| Modified By :             Yongwei Wang (YW62951)                                                             
| Date of Modification :    8-Oct-2003                                                   
| New Version Number :      1/3                                                   
| Modification ID :         yw003                                                 
| Reason For Modification : Modified the code to merge TRT data set with
|                           POP data set for crossover study. 
| ************************************************************************** 
| Modified By :             Barry Ashby (bra13711)                                                             
| Date of Modification :    15-Jan-2007                                                   
| New Version Number :      2/1                                                   
| Modification ID :         ba001                                                 
| Reason For Modification : Change requests: HRT0035, HRT0142.
|                           Subset analysis dataset creation for 
|                           crossover study based on pop data contents. Added
|                           parameter validation steps for g_trtdata, 
|                           g_popdata, dsetin. 
| *************************************************************************
| Modified By :             Barry Ashby (bra13711)                                                             
| Date of Modification :    19-Feb-2007                                                   
| New Version Number :      2/2
| Modification ID :         ba001                                                 
| Reason For Modification : Change request HRT0152.
|                           Added functionality to merge variables from the 
|                           pop dataset to the analysis dataset.  Also check
|                           if pop datasets variables exists and check they
|                           do not already exist in analysis dataset.
|*************************************************************************
| Modified By :             Rohit Wadhwa (rw690192)                                                             
| Date of Modification :    01-SEP-2012                                                   
| New Version Number :      3/1
| Modification ID :         rw01                                                
| Reason For Modification : Updated macro to include functionality for CDISC data.
|                           1.) Added Variable g_datatype which will have value IDSL or CDISC
|				            2.) Variable Studyid ang g_subjid will be used for merging input 
|				                data with POP  for CDISC study.
|			                3.) POP data will not be merged with TRT data for crossover
|			                    CDISC studies
|*************************************************************************
| Modified By :             Yongwei Wang (YW62951)                                                             
| Date of Modification :    26-Jun-2013                                                   
| New Version Number :      4                                                   
| Modification ID :         yw004                                                 
| Reason For Modification : Updated macro to take character version (Y or N) of &g_pop 
|                           variable  because AdAM.ADSL dataset may not have numeric 
|                           version of population flag variable.
**************************************************************************/

%MACRO tu_getdata(
  dsetin    = , /* Input Dataset */
  dsetout1  = , /* Analysis output dataset */
  dsetout2  =   /* Population output dataset */
  );
                
  %LOCAL macroversion;
  %LET macroversion=4;
 
  %INCLUDE "&g_refdata/tr_putlocals.sas";
  /*rw01: Added global macro variable g_datatype in macro parameter*/
  %tu_putglobals(varsin=g_popdata g_pop g_subpop g_subset g_datatype);

  %LOCAL l_dsid l_rc l_keeppopvars l_trtdata prefix l_popdata dummy;
  %LET prefix=_getdata;

  /* ba001: If G_TRTDATA is not defined then use the following method to define TRT dataset for IDSL studies */        
  %IF %qupcase(&g_datatype) EQ IDSL %then %do;    
    %LET l_dsid =%sysfunc(open(sashelp.vmacro(where=(name="G_TRTDATA" and scope="GLOBAL")))); 
    %LET l_rc=%sysfunc(fetch(&l_dsid));
    %LET dummy =%sysfunc(close(&l_dsid));
  
    /* ba001: If G_TRTDATA exists then set local trtdata to that value */
    %IF &l_rc EQ 0 %THEN %LET l_trtdata=&g_trtdata;
    %ELSE %DO;  /* ba001: If G_TRTDATA does not exist */  
 
  /* 
  /  yw003: get data libname from &g_popdata. the code should be removed after the 
  /  l_trtdata be changed to global macro variable 
  /-------------------------------------------------------------------------------*/      

       %IF %index(&g_popdata, . ) GT 1 %THEN 
       %DO;
          %LET l_trtdata=%qsubstr(&g_popdata, 1, %index(&g_popdata, . ) - 1);
          %LET l_trtdata=&l_trtdata..TRT;
       %END;  
       %ELSE %LET l_trtdata=TRT;
    %END; /* %IF %LENGTH(&l_rc) EQ 0 */ 
  %END; /* %IF %qupcase(&g_datatype) EQ IDSL */ 
  
  /* ba001: If G_KEEPPOPVARS is not defined then set l_keeppopvars to blank. Otherwise set to &g_keeppopvars */  
  %LET l_dsid =%sysfunc(open(sashelp.vmacro(where=(name="G_KEEPPOPVARS" and scope="GLOBAL")))); 
  %LET l_rc=%sysfunc(fetch(&l_dsid));
  %LET dummy =%sysfunc(close(&l_dsid));
  %IF &l_rc EQ 0 %THEN %LET l_keeppopvars=&g_keeppopvars;
  %ELSE %let l_keeppopvars=;          
    
  /* Parameter Validation */
            
  /* Check that input dataset has been specified */
  
  %IF %LENGTH(&dsetin) EQ 0 %THEN
  %DO;
     %PUT RTE%STR(RROR): &sysmacroname: Input dataset DSETIN has not been specified; 
     %LET g_abort = 1;
  %END;
  
  /* Check that input dataset specified exists */
  
  %ELSE %IF %SYSFUNC(EXIST(&dsetin)) EQ 0 %THEN
  %DO;
     %PUT RTE%STR(RROR): &sysmacroname: Input dataset DSETIN(=&DSETIN) does not exist; 
     %LET g_abort = 1;
  %END;

  /* ba001: Check if g_centid and g_subjid exist in DSETIN */
  /* rw01: Updated the IF condition to execute following for IDSL studies only */
  %ELSE %IF %qupcase(&g_datatype) EQ IDSL and %length(%tu_chkvarsexist(&dsetin, %unquote(&g_centid &g_subjid))) gt 0 %THEN 
  %DO;
     %PUT RTE%str(RROR): &sysmacroname: Variable G_CENTID(=&g_centid) and/or G_SUBJID(=&g_subjid) does not exist in DSETIN(=&dsetin);       
     %LET g_abort=1;            
  %END;
  
  /* rw01: Check if Studyid and g_subjid exist in DSETIN for CDISC studies*/

  %ELSE %IF %qupcase(&g_datatype) EQ CDISC and %length(%tu_chkvarsexist(&dsetin, studyid %unquote(&g_subjid))) gt 0 %THEN 
  %DO;
     %PUT RTE%str(RROR): &sysmacroname: Variable Studyid and/or G_SUBJID(=&g_subjid) does not exist in DSETIN(=&dsetin);       
     %LET g_abort=1;            
  %END;

  
  /* Check that analysis output dataset specified is valid V7 dataset name */
  
  %IF %LENGTH(&dsetout1) NE 0 %THEN   
     %IF %length(%tu_chknames(namesin=&dsetout1, nametype = data)) %THEN 
     %DO;
        %PUT RTE%str(RROR): &sysmacroname: DSETOUT1 (=&dsetout1) is not a valid dataset name;
        %LET g_abort = 1;
     %END;
                            
  /* Check that population output dataset specified is valid V7 dataset name */     
  
  %IF %LENGTH(&dsetout2) NE 0 %THEN 
     %IF %length(%tu_chknames(namesin=&dsetout2, nametype = data)) %THEN 
     %DO;
        %PUT RTE%str(RROR): &sysmacroname: DSETOUT2 (=&dsetout2) is not a valid dataset name;
        %LET g_abort = 1;
     %END;
  
  /* Check that analysis dataset and/or population dataset has been specified */
  
  %IF %LENGTH(&dsetout1) EQ 0 AND %LENGTH(&dsetout2) EQ 0 %THEN
  %DO;
     %PUT RTE%STR(RROR): &sysmacroname: No output dataset(s) have been specified. Both DSETOUT1 and DSETOUT2 are blank.; 
     %LET g_abort = 1;
  %END;
  
  /* 
  / ba001: Check if g_centid and g_subjid exist in g_popdata dataset for IDSL studies
  / Check if Studyid and g_subjid exist in g_popdata dataset for CDISC studies
  /-----------------------------------------------------------------------------------*/

  %IF %nrbquote(&g_popdata) NE %THEN 
  %DO;
     %IF %SYSFUNC(EXIST(&g_popdata)) EQ 0 %THEN 
     %DO;      
        %PUT RTE%STR(RROR): &sysmacroname: dataset specified by G_POPDATA(=&g_popdata) does not exist; 
        %LET g_abort = 1;
     %END;
	 /*rw01: Updated check to execute only for IDSL studies */
     %ELSE %IF %qupcase(&g_datatype) EQ IDSL and %length(%tu_chkvarsexist(&g_popdata,%unquote(&g_centid &g_subjid))) GT 0 %THEN 
     %DO;
        %PUT RT%str(ERR)OR: &sysmacroname: Variable G_CENTID(=&g_centid) and/or G_SUBJID(=&g_subjid) does not exist in G_POPDATA(=&g_popdata);       
        %LET g_abort=1;            
     %END; 
	 /*rw01: Added check to execute only for CDISC studies */
     %ELSE %IF %qupcase(&g_datatype) EQ CDISC and %length(%tu_chkvarsexist(&g_popdata,studyid %unquote(&g_subjid))) GT 0 %THEN 
     %DO;
        %PUT RT%str(ERR)OR: &sysmacroname: Variable Studyid and/or G_SUBJID(=&g_subjid) does not exist in G_POPDATA(=&g_popdata);       
        %LET g_abort=1;            
     %END;       
                       
  %END; /* %IF %nrbquote(&g_popdata) NE */
  
  /* ba001: Check if g_centid and g_subjid exist in g_trtdata data*/
  /* rw01: Updated following check to execute for IDSL studies only*/
  
  %IF ( %qupcase(&g_stype) EQ XO ) and ( %nrbquote(&l_trtdata) NE ) and %qupcase(&g_datatype) EQ IDSL %THEN 
  %DO;          
     %IF %SYSFUNC(EXIST(&l_trtdata)) EQ 0 %THEN 
     %DO;      
        %PUT RTE%STR(RROR): &sysmacroname: Dataset specified by G_TRTDATA(=&l_trtdata) does not exist; 
        %LET g_abort = 1;
     %END;
     %ELSE %IF %length(%tu_chkvarsexist(&l_trtdata,%unquote(&g_centid &g_subjid))) gt 0 %THEN 
     %DO;
        %PUT RTE%str(RROR): &sysmacroname: Variable G_CENTID(=&g_centid) and/or G_SUBJID(=&g_subjid) does not exist in G_TRTDATA(=&l_trtdata);       
        %LET g_abort=1;            
     %END;
  %END; /* %IF ( %qupcase(&g_stype) EQ XO ) and ( %nrbquote(&l_trtdata) NE ) */
  
  /* Check if &g_popkeevars exist in &g_popdata */
  
  %IF ( %nrbquote(&l_keeppopvars) NE ) and ( %nrbquote(&dsetout1) NE ) %THEN 
  %DO;       
     %LET dummy=;
     %DO l_dsid=1 %TO %tu_words(&l_keeppopvars);
        %LET l_rc=%qscan(&l_keeppopvars, &l_dsid, %str( ));
        %IF %length(%tu_chkvarsexist(&g_popdata,%unquote(&l_rc))) gt 0 %THEN 
        %DO;
           %PUT RTE%str(RROR): &sysmacroname: Variable %qupcase(&l_rc) given in G_KEEPPOPVARS(=&l_keeppopvars) does not exist in G_POPDATA(=&g_popdata);       
           %LET g_abort=1;                       
        %END;
        %ELSE %IF %length(%tu_chkvarsexist(&dsetin,%unquote(&l_rc))) eq 0 %THEN 
        %DO;
           %PUT RTW%str(ARNING): &sysmacroname: Variable %qupcase(&l_rc) given in G_KEEPPOPVARS(=&l_keeppopvars) exists in both G_POPDATA(=&g_popdata) and DSETIN(=&dsetin);
           %PUT RTW%str(ARNING): &sysmacroname: Variable %qupcase(&l_rc) in DSETIN(=&dsetin) will be kept in DSETOUT1(=&DSETOUT1);
        %END;               
        %ELSE %DO;
           %LET dummy=&dummy &l_rc;
        %END;        
     %END; /* %DO l_dsid=1 %TO %tu_words(&l_keeppopvars) NE ) */
     
     %LET l_keeppopvars=&dummy;
  %END; /* %IF ( %nrbquote(&l_keeppopvars) NE ) and ( %nrbquote(&dsetout1) NE ) */    
    
  /* Begining of normal processing */

  %IF &g_abort EQ 0 %THEN 
  %DO;  
  
     /* 
     /  Create population dataset.                                             
     /                                                                        
     /  Subset population dataset for specified population parameter flag. If  
     /  no population parameter has been specified then keep all subjects from 
     /  the population dataset.                                                 
     /  If additional subsettig of the popualtion dataset has been specified   
     /  using G_SUBPOP, then carry out additional subsetting. Note, that an    
     /  assumption has been made that the population data contains all the     
     /  variables specified in the G_SUBPOP parameter.                         
	 /-------------------------------------------------------------------------*/

     %LET l_popdata=&g_popdata;

     /* yw003: merge POP data with TRT data and create new POP data set for IDSL studies*/
	 /* rw01: Updated the condition to execute for IDSL studies only */ 
     %IF %qupcase(%nrbquote(&g_stype)) EQ XO and %qupcase(&g_datatype) EQ IDSL %THEN 
     %DO;   
         PROC SORT DATA=&l_popdata out=&prefix._popdata nodupkey;
            BY &g_centid &g_subjid;
         RUN;
        
         PROC SORT DATA=&l_trtdata OUT=&prefix._trtdata;
            BY &g_centid &g_subjid;
         RUN;
         
         DATA &prefix._popdata;
            MERGE &prefix._popdata(IN=_IN_)
                  &prefix._trtdata;
            BY &g_centid &g_subjid;
            IF _IN_;
         RUN;
         %let l_popdata=&prefix._popdata;
     %END;   
     
     DATA &prefix._popdata
          %IF %nrbquote(&dsetout2) NE %THEN 
          %DO;
            &dsetout2
          %END;  /* yw003: added condition for &dsetout2 */
          ;
        SET &l_popdata %IF %LENGTH(&g_pop) NE 0 %THEN 
            %DO;
               %if %tu_chkvartype(&l_popdata, &g_pop) eq N %then
               %do;
                   (WHERE=(&g_pop=1))
               %end;
               %else %do;
                   (WHERE=(upcase(substr(&g_pop, 1, 1))='Y'))
               %end;
            %END; /* YW004: Added condition to use character version of &g_pop variable */
        ;
        %IF %symexist(g_subpop) %THEN %DO; 
		  %IF %LENGTH(%UNQUOTE(&g_subpop)) NE 0 %THEN IF %UNQUOTE(&g_subpop);
          ;
        %END; /*rw01: Added the condition to check existence of macro variable g_subpop */
        ;    
     RUN;

     /* Create analysis dataset if output dataset has been specifed */

     %IF %LENGTH(&dsetout1) NE 0 %THEN
     %DO;
        PROC SORT DATA=&dsetin out=&prefix._analydata;
	     %IF %symexist(g_subset) %THEN
 	     %DO;
             %IF %length(&g_subset) ne 0 %THEN 
             %DO;  
                WHERE %UNQUOTE(&g_subset); 
             %END;
          %END; /* rw01: Added condition to check existence of macro varaible */

          %IF %qupcase(&g_datatype) EQ IDSL %THEN 
          %DO;
              BY &g_centid &g_subjid;
          %END;/* rw01: Added condition to execute for IDSL studies */
          %IF %qupcase(&g_datatype) EQ CDISC %THEN 
          %DO;
              BY studyid &g_subjid;
          %END;/* rw01: Added condition and by variables to execute for CDISC studies */

        RUN;
        
        /* ba001: Added sort for merging data below */
		/* rw01: Updated condition to keep G_CENTID for IDSL and STUDYID for CDISC studies
				 Updated BY statement for IDSL and CDISC studies */
        PROC SORT DATA=&prefix._popdata (KEEP= %IF %qupcase(&g_datatype) EQ IDSL %THEN %DO; &g_centid %END;
                                               %IF %qupcase(&g_datatype) EQ CDISC %THEN %DO; studyid %END;    
                                               &g_subjid &l_keeppopvars) NODUPKEY;
           BY %IF %qupcase(&g_datatype) EQ IDSL %THEN %DO; &g_centid %END;
              %IF %qupcase(&g_datatype) EQ CDISC %THEN %DO; studyid %END;                                 
              &g_subjid;
        RUN;
        
        /* ba001: Create analysis data using merge of selective pop data based on keeppopvars contents */
		/* rw01: Updated BY statement for CDISC and IDSL studies */
        DATA &dsetout1;
           MERGE &prefix._analydata(in=_in1_) &prefix._popdata(in=_in2_);
           BY %IF %qupcase(&g_datatype) EQ IDSL %THEN %DO; &g_centid %END;
              %IF %qupcase(&g_datatype) EQ CDISC %THEN %DO; studyid %END;                                 
              &g_subjid;
           IF _in1_ AND _in2_;
        RUN;   
     %END; 
     
     /* Delete intermediate datasets */

     %tu_tidyup(rmdset = &prefix:,
                glbmac = none
                );
            
  %END; /* &g_abort EQ 0 */
     
  /* Call abort utility */   

  %tu_abort;
  
%MEND tu_getdata;
