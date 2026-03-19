/*******************************************************************************
|
| Macro Name:      tu_getsms2k
|
| Macro Version:   2
|
| SAS Version:     9.4
|
| Created By:      James McGiffen
|
| Date:            15-Dec-2004
|
| Macro Purpose:   The purpose of this macro is to make SMS2000 data available 
|                  to the caller by converting a vertical bar delimited text 
|                  file into a SAS dataset. Text strings will not be quoted.
|
| Macro Design:    Procedure Style
|
| Input Parameters:
|
| NAME            DESCRIPTION                          REQ/OPT  DEFAULT
| --------------  -----------------------------------  -------  ---------------
| DSETOUT         Specifies the name of the output     REQ      [blank]
|                 dataset to contain the SMS2000
|                 data
|
| KEEP            Specifies the names of the           REQ      PCSMPID
|                 variables to be kept in the                   PCSPEC
|                 output dataset                                PCAN
|                                                               PCLLQC
|                                                               PCORRES
|                                                               PCORRESU
|
| RENAME          Specifies optional renames to be     OPT      [blank]
|                 performed on the output dataset. 
|                 Note: for variables named in the 
|                 table in section "1.1. Purpose", 
|                 the rename parameter shall apply 
|                 to the SAS variable names, not 
|                 the original SMS2000 column names
|
| SMSFILE         Specifies the name and location of   REQ      [blank]
|                 the SMS2000 input file
|
| DELIM           Specifies the character to be used   REQ      | 
|                 to delimit the SMS2000 text file.
|
| Output:
|
| Global macro variables created: none
|
| Macros called:
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_chkvarsexist
| (@) tu_chknames
| (@) tu_abort
| (@) tu_tidyup
|
| Example:
|
|    %tu_getsms2k(dsetout =sms2k
|                ,keep    =PCSMPID PCSPEC PCAN PCLLQC PCORRES PCORRESU      
|                ,rename  =PCAN=ANALYTE
|                ,smsfile =/arenv/arwork/testdata/test
|                ,delim   =|
|                );
|
|******************************************************************************
| Change Log
|
| Modified By: Ian Barretto
| Date of Modification: 15th December 2004
| New version/draft number: 01-002
| Modification ID: IB10254.01-002
| Reason For Modification: Change to read in a SMS2000 file with varying 
|                          record line lengths.
|
| Modified By: Andrew Ratcliffe, RTSL
| Date of Modification: 20 January 2005
| New version/draft number: 01-003
| Modification ID: AR3
| Reason For Modification: Use TRANWRD to correctly translate || to "| |".
|                          Use &delim throughout - no hard-coded "|".
|
| Modified By: Andrew Ratcliffe, RTSL
| Date of Modification: 27 January 2005
| New version/draft number: 01-004
| Modification ID: AR4
| Reason For Modification: Check that DELIM is not blank.
|                          Allow quoted and unquoted values for DELIM.
|                          Remove non-standard debugging code.
|                          Use "!" for concatenation instead of "|" to aid clarity.
|                          Add underscore to temporary dataset names in order to 
|                           make them consistent with other macros.
|                          Validate the KEEP parameter before applying it.
|
| Modified By:              Anthony J Cooper
| Date of Modification:     06-Mar-2018
| New version/draft number: 2
| Modification ID:          AJC001
| Reason For Modification:  To handle the situation when there are more than
|                           two consecutive delimiters in the SMS2000 file.
|
*******************************************************************************/
%macro tu_getsms2k (dsetout =   /* Name of output dataset */
                   ,keep    =PCSMPID PCSPEC PCAN PCLLQC PCORRES PCORRESU /* Variables to be kept in output dataset */ 
                   ,rename  =   /* Optional renames */
                   ,smsfile =   /* type:IF Name and location of input file */
                   ,delim   =|  /* Delimiter of SMS file */
                   );

  /*
  / Echo parameter values and global macro variables to the log.
  /----------------------------------------------------------------------------*/
  %local MacroVersion;
  %let MacroVersion=2;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals();

  /*
  / PARAMETER VALIDATION
  /----------------------------------------------------------------------------*/

  %let dsetout = %nrbquote(&dsetout);
  %let keep    = %nrbquote(&keep);
  %let rename  = %nrbquote(&rename);
  %let smsfile = %nrbquote(&smsfile);
  %let delim   = %nrbquote(&delim);
 
  /*
  / Check for required parameters.
  /----------------------------------------------------------------------------*/
  %if &dsetout. eq %then
  %do;  /* DSETOUT is blank */ 
    %put %str(RTE)RROR: &sysmacroname.: The parameter DSETOUT is required.;
    %let g_abort=1;
  %end;  /* DSETOUT is blank */ 
  %else
  %do;  /* DSETOUT is non blank */  

    %if %nrbquote(%tu_chknames(&dsetout., data)) ne %then 
    %do; /* Verify DSETOUT is a valid dataset */
      %put %str(RTE)RROR: &sysmacroname.: The parameter DSETOUT (&dsetout.) is not a valid SAS datatset name.;
      %let g_abort=1;
    %end; /* Verify DSETOUT is a valid dataset */ 

  %end;  /* DSETOUT is non blank */
 
  %if &keep. eq %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: The parameter KEEP is required.;
    %let g_abort=1;
  %end;

  %if &smsfile. eq %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: The parameter SMSFILE is required.;
    %let g_abort=1;
  %end;
 
  %if &delim. eq %then    /*AR4*/
  %do;
    %put %str(RTE)RROR: &sysmacroname.: The parameter DELIM is required.;
    %let g_abort=1;
  %end;
 
  /*
  / Check for valid parameter values.
  /----------------------------------------------------------------------------*/
  %if %eval(%sysfunc(fileexist(&smsfile.)) gt 0) %then
  %do; /* SMSFILE exists */ 
    %put %str(RT)NOTE: &sysmacroname.: Found the file &smsfile.;
  %end;/* SMSFILE exists */ 
  %else
  %do;/* SMSFILE does not exist - abort macro */  
    %put %str(RTE)RROR: &sysmacroname.: The file identified by SMSFILE &smsfile. does not exist;
    %let g_abort=1;
  %end;/* SMSFILE does not exist - abort macro */  

  %tu_abort;

  /*
  / NORMAL PROCESSING
  /----------------------------------------------------------------------------*/

  %if &g_debug ge 1 %then
    %put RTD%str(EBUG): &sysmacroname: Beginning normal processing;

  %local prefix;

  %let prefix = %substr(&sysmacroname,3);  /*AR4*/

  /* Make sure that DELIM is a quoted string */  /*AR4*/
  %let delim = %unquote(&delim);
  %if %length(&delim) eq 1 %then
  %do;
    %let delim = "&delim";
  %end;

  /*
  / Read in the first line of the file to check the names
  / IB10254.01-002
  /----------------------------------------------------------------------------*/
  data &prefix._colnames &prefix._data;
    length allnames $1200.;
    infile "&smsfile" length=len;
    input @1 allnames $varying1200. len;
    if _n_ eq 1 then output &prefix._colnames;
    else output &prefix._data;
  run;

  %local numofvars i;
  /*
  / Determine the number of variables and assigned to Macro Variable : NUMOFVARS
  /----------------------------------------------------------------------------*/
  data _null_;
    set &prefix._colnames;
    /* 
    / The number of variables will be the difference between the length of the 
    / string - the delimiters
    /----------------------------------------------------------------------------*/
    numofvars=( length( compress(allnames) ) - length( compress(allnames, &delim.) ) ) + 1;  /*AR4*/
    call symput('numofvars',compress(put(numofvars,8.))); 
  run;

  %do i=1 %to &numofvars;
    %local varname&i.;
  %end;
  
  /*
  / Assign each variable name to the value of a macro variable  
  /----------------------------------------------------------------------------*/
  data &prefix._colchk;
    set &prefix._colnames;
    do i=1 to &numofvars;
      call symput(compress('varname'!!put(i,8.)),trim(scan(allnames,i,&delim.)));  /*AR4*/
    end;
  run;

  /* Check each variable to determine if it is valid or not 
  /  this could be done in one call but it gives better error 
  /  messages this way  
  /----------------------------------------------------------------------------*/
  %do i=1 %to &numofvars.;  /* Loop for each variable */

    %if %nrbquote(%tu_chknames(&&varname&i..,variable)) ne %then
    %do;  /* Verify valid SAS variable */
      %put %str(RTE)RROR: &sysmacroname.: The variable found on the smsfile &&varname&i. is not a valid SAS variable name.;
      %let g_abort=1;
    %end; /* Verify valid SAS variable */

  %end;  /* Loop for each variable */               
 
  %tu_abort;

  /*
  / Create a temporary output dataset
  /----------------------------------------------------------------------------*/
  data &prefix._sms10 (drop= allnames);
    length %do i=1 %to &numofvars.;
             &&varname&i. $100.
            %end;;
           
    set &prefix._data;

    /*
    / Reformat all names so that we create blank vars
    /----------------------------------------------------------------------------*/

    do while(index(allnames, &delim.!!&delim.) gt 0);
      allnames=tranwrd(allnames
                      ,&delim !! &delim
                      ,&delim !! " " !! &delim
                      );     /*AR3*/  /*AR4*/
    end; /* AJC001: handle >2 consecutive delimiters */
    
    /*
    / For each variable we have create the data for it
    /----------------------------------------------------------------------------*/
    %do i=1 %to &numofvars.;
      &&varname&i = trim(scan(allnames,&i.,&delim.));  /*AR4*/
    %end;

  run;            
   
  /*
  / Check that we have the correct variables in the dataset
  /----------------------------------------------------------------------------*/
  %if %length(%tu_chkvarsexist(&prefix._sms10, sample_number study_number subject_name period_name
             nominal_time nominal_time_units matrix_name analyte_name
             llq result_conc result_conc_units)) gt 0 %then
  %do;
    %put %str(RTE)RROR: &sysmacroname.: A variable that was expected on the input file is not found;
    %tu_abort(option=force);   
  %end;  
   
  /*
  / Create the final dataset- this is a bit inefficient but its in order 
  / to check the data
  /----------------------------------------------------------------------------*/
  data &prefix._sms20;  
    set &prefix._sms10 (rename=(sample_number=pcsmpid
                                subject_name=subjid2000
                                matrix_name=pcspec
                                analyte_name=pcan
                                llq=pcllqc
                                result_conc=pcorres
                                result_conc_units=pcorresu
                                study_number=studyid2000
                                period_name=period2000
                                nominal_time=pcptmnum2000
                                nominal_time_units=pcptmu2000
                                %if %length(&rename.) gt 0 %then &rename. ;)
                       );
  run;

  %if %length(&keep) gt 0 %then     /*AR4*/
  %do;  /* Validate the KEEP parameter */
    %local NotFound;
    %let NotFound = %tu_chkvarsexist(&prefix._sms20,&keep);
    %if %length(&NotFound) gt 0 %then
    %do;
      %put %str(RTE)RROR: &sysmacroname.: The output dataset does not contain the following KEEP variable(s): &NotFound;
      %tu_abort(option=force);   
    %end;  
  %end; /* Validate the KEEP parameter */
   
  data &dsetout;  
    set &prefix._sms20;
    %if %length(&keep) gt 0 %then
    %do;
      keep &keep;
    %end;
  run;  
  
  
  /*
  / Delete temporary datasets used in this macro.
  /----------------------------------------------------------------------------*/
  %tu_tidyup(rmdset=&prefix:
            ,glbmac=NONE
            );
  quit;

  %tu_abort;

%mend tu_getsms2k;
