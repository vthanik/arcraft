/******************************************************************************* 
|
| Macro Name:      tu_localisation
|
| Macro Version:   4.0
|
| SAS Version:     8.2
|
| Created By:      Neeraj Malhotra / Stephen Griffiths      
|
| Date:            21-May-2003
|
| Macro Purpose:   This macro shall create the three localisation formats $local, 
|                  $sex and $yesno
|
| Macro Design:    PROCEDURE STYLE MACRO
|                  Macro value dump to log file
|                  Parameter validation 
|                  Create copy of local.xml file
|                  Create formats
|                  Tidy-up
| 
| Input Parameters: None
|
| Output: Three SAS character formats dervived from the key / phrase pairs in the 
|         input file
|
| Global macro variables created:  None
|
| Macros called:
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_nobs
| (@) tu_chkvarsexist
| (@) tu_chkdups
|
|******************************************************************************* 
| Change Log 
|
| Modified By:              Stephen Griffiths
| Date of Modification:     22-Jul-03
| New version number:       1/2
| Modification ID:
| Reason For Modification:  Update to reflect change to tu_chkdups
|
|*******************************************************************************
| Modified By:              Yongwei Wang
| Date of Modification:     14-Dec-04
| New version number:       2/1
| Modification ID:          YW001
| Reason For Modification:  Added statement HTMLDECODE to decode the value of
|                           the PHRASE in XML file so that special characters 
|                           can be decoded.
|
|*******************************************************************************
| Modified By:              Shan Lee
| Date of Modification:     18-May-06
| New version number:       3/1
| Modification ID:          SL001
| Reason For Modification:  Changed parameter validation that checks if any 
|                           values of KEY are missing, so that an RTN-OTE is
|                           generated instead of an (RTE)RROR: we may wish to
|                           create a format that can map missing values (eg.
|                           " " -> "Missing"), and an (RTE)RROR places an 
|                           unnecesary restriction that prevents us from doing
|                           so.
|
|******************************************************************************** 
| Modified By:              Barry Ashby
| Date of Modification:     07-Nov-06
| New version number:       4/1
| Modification ID:          BA001
| Reason For Modification:  Changed XML libref to read-only so the file cannot
|                           be overwritten accidentally.
|
|********************************************************************************/ 

%macro tu_localisation();

  /*
  / output local and global macro var values to log
  /----------------------------------------------------------------------------*/
  %local MacroVersion ;
  %let MacroVersion = 4;
  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_refdata g_language )

  /*
  / Define local vars
  /----------------------------------------------------------------------------*/
  %local prefix chkdup;
  %let prefix=_localisation;

  /*
  / Parameter validation
  /----------------------------------------------------------------------------*/
  %if %length(&g_refdata) eq 0 %then 
  %do;
    %put %str(RTERR)%str(OR):TU_LOCALISATION: G_REFDATA is null;
    %let g_abort=1;
  %end;

  %if %length(&g_language) eq 0 %then
  %do;
    %put %str(RTERR)%str(OR):TU_LOCALISATION: G_LANGUAGE is null;
    %let g_abort=1;
  %end;

  %if &g_abort eq 1 %then %tu_abort();

  %if %sysfunc(fileexist(&g_refdata./tr_lang_&g_language..xml)) eq 0 %then
  %do;
    %put %str(RTERR)%str(OR):TU_LOCALISATION: Language XML file does not exist within &g_refdata;
    %let g_abort=1;
  %end;

  %if &g_abort eq 1 %then %tu_abort();

/* MOD BA001 for change request HRT0138 - XML file access will be read-only */
  libname refdata xml "&g_refdata./tr_lang_&g_language..xml" access=readonly;

  %if %sysfunc(exist(refdata.local))=0 %then
  %do;
    %put %str(RTERR)%str(OR):TU_LOCALISATION: Local dataset missing in XML directory;
    %let g_abort=1;
  %end;

  %if &g_abort eq 1 %then %tu_abort();

  %if %tu_nobs(refdata.local) eq 0 %then 
  %do;
    %put %str(RTERR)%str(OR):TU_LOCALISATION: REFDATA.LOCAL is empty;
    %let g_abort=1;
  %end;

  %if &g_abort eq 1 %then %tu_abort();

  %if %length(%tu_chkvarsexist(refdata.local,fmtname key phrase)) ge 1 %then
  %do;
    %put %str(RTERR)%str(OR):TU_LOCALISATION: One of FMTNAME, KEY, PHRASE missing from REFDATA.LOCAL;
    %let g_abort=1;
  %end;

  %if &g_abort eq 1 %then %tu_abort();

  %tu_chkdups(dsetin=refdata.local,
              byvars=fmtname key,
              retvar=chkdup,
              dsetout=&prefix.dups);

  %if &chkdup gt 0 %then 
  %do;
    %put %str(RTERR)%str(OR):TU_LOCALISATION: Duplicate values for FMTNAME KEY exist in REFDATA.LOCAL;
    %let g_abort=1;
  %end;

  data &prefix._miss_key;
    set refdata.local;
    if key=' ' then output;
  run;

  %if %tu_nobs(&prefix._miss_key) ne 0 %then
  %do;
    /* SL001 */
    %put %str(RTN)%str(OTE):TU_LOCALISATION: Missing values for KEY within REFDATA.LOCAL;
  %end;

  %if &g_abort eq 1 %then %tu_abort();

  /*
  / Create a copy of the local data set
  /-----------------------------------------------------------------------------*/
  data &prefix._fdset (rename=(phrase=label));
    set refdata.local;
    retain type 'C';
    start=upcase(key);
    /* YW001: Decode the PHRASE in XML so that special characters can be decoded */
    phrase=htmldecode(phrase);    
  run;

  /*
  / Create the format
  /-----------------------------------------------------------------------------*/
  proc format cntlin=&prefix._fdset;
  run;

  %if &syserr gt 0 %then %let g_abort=1;
 
  %tu_tidyup(rmdset=&prefix.:,
             glbmac=none);

  %tu_abort();

%mend tu_localisation;
