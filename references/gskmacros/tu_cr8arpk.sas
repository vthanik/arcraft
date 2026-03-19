/******************************************************************************* 
|
| Macro Name:      tu_cr8arpk.sas
|
| Macro Version:   2.1
|
| SAS Version:     9.1
|
| Created By:      Andrew Ratcliffe
|
| Date:            10-Dec-2004
|
| Macro Purpose:   This macro shall create an A&R PKCNC dataset from the 
|                  equivalent of a DM PK dataset, i.e. the equivalent of 
|                  ET-Tool output. 
|
| Macro Design:    PROCEDURE STYLE MACRO
| 
| Input Parameters:
|
| NAME              	DESCRIPTION                             	DEFAULT 
| DSETIN    		Specifies the name of the input DM PK dataset   [blank] (Req)
| 
| DSETINPERIOD 		Specifies the name of the input SI/DM PERIOD 	ardata.period (Opt)
|              		dataset
| 
| DSETINEXP 		Passed to tu_pkcncderv parameter of the same    ARDATA.EXPOSURE (Opt)
|            		name
| 
| EXPJOINBYVARS 	Passed to tu_pkcncderv parameter of the    	&g_centid &g_subjid pernum period visitnum visit (Opt)
|                	same name
| 
| DSETOUT   		Specifies the name of the A&R PKCNC output      [blank] (Req)
|           		dataset to be created                           
| 
| SMSFILE   		Specifies the name and location of the input    [blank] (Req)
|           		SMS2000 file. Passed as %tu_getsms2k's 
|           		parameter of the same name                      
| 
| SMSDELIM  		Passed to %tu_getsms2k as its DELIM parameter   |  (Req)
| 
| SMSKEEP   		Passed to %tu_getsms2k as its KEEP parameter    PCSMPID PCSPEC PCAN PCLLQC PCORRES PCORRESU SUBJID2000  (Req)
| 
| SMSRENAME 		Passed to %tu_getsms2k as its RENAME parameter  [blank]  (Opt)
| 
| JOINMSG   		Specifies whether unmatched records in joins    WARNING  (Req)
|           		(e.g. PK/SMS2000) should be treated as warnings 
|           		or errors
| 
| PCWTU     		Passed to tu_pkcncdervs parameter of the same  	g  (Opt)
|			name. Specifies the value to be placed into        
|           		the PCWTU variable in all rows. 
|           		Required if PCWTU is in the dataset plan 
| 
| ELTMSTDUNIT           Specifies the units to which ELTMNUM values     HRS (Opt) 
|                       shall be standardised
|
|                       Valid values: SEC, MIN, HRS, DAY
|
| DVTMSTDUNIT           Specifies the units to which derived durations  HRS (Opt) 
|                       shall be standardised
|
|                       Valid values: SEC, MIN, HRS, DAY
|
| IMPUTEBY              Specifies the variables by which the imput-     &g_centid &g_subjid pctypcd pcan pernum visitnum pcrfstdm ptmnum (Opt) 
|                       ation shall be done. The dataset is sorted 
|                       prior to imputation using any vars in IMPUTEBY
|                       which are found in the dataset. Imputation is  
|	                then performed, restarting whenever any IMPUTEBY 
|	                variable other than the last one changes.              
| 
| IMPUTETYPE       	Specifies either standard (S) or alternative    S (Opt) 
|                  	(A) imputation.
| 
| MERGEINCSUBJ       	Option to include SUBJID in PK merge. If Y, 	N (Req) 
|                  	merge on SUBJID PCSMPID, if N, merge on PCSMPID 
| 
| DELETEMISMERGES      	Option to delete miserged records. If Y, only  	Y (Req) 
|                  	records which exist in both DM dataset and 
| 			SMS will be retained.
| 
| Output: An A&R PKCNC dataset and it updates the exception 
|         report
|
| Global macro variables created:  None
|
| Macros called:
| (@) tr_putlocals
| (@) tu_putglobals
| (@) tu_chknames
| (@) tu_attrib
| (@) tu_getsms2k
| (@) tu_words
| (@) tu_maclist
| (@) tu_readdsplan
| (@) tu_isvarindsplan
| (@) tu_xcpsectioninit
| (@) tu_xcpput
| (@) tu_xcpsectionterm
| (@) tu_byid
| (@) tu_pkcncderv
| (@) tu_tidyup
| (@) tu_abort
|
| Examples:
|
|   %tu_cr8arpk(DSETIN= dmpk
|              ,DSETOUT= ardata.pkcnc
|              );
|
|******************************************************************************* 
| Change Log 
|
| Modified By: Trevor Welby             
| Date of Modification: 10-Dec-2004 
| New version number: 01-001      
| Modification ID: TQW9753-01-001
| Reason For Modification:  Slight modification to header text
|
| Modified By: Andrew Ratcliffe
| Date of Modification: 04-Feb-05
| New version number: 01-002 
| Modification ID: 
| Reason For Modification:  Add DSETINEXP and EXPJOINBYVARS parameters, and pass
|                            them to tu_pkcncderv.
|
| Modified By:             Andrew Ratcliffe
| Date of Modification:    09-Mar-05
| New version number:      01-003 
| Modification ID: 
| Reason For Modification:  Set g_abort=1 after each rterr message.
|
|
| Modified By:              Warwick Benger
| Date of Modification:     3-Oct-2008
| New version number:       02-001
| Modification ID:          WJB1
| Reason For Modification:  1. New macro parameter IMPUTETYPE to specify Standard or Alternative
|                               (passed to tu_pkcncderv)
|                           2. New macro parameter MERGEINCSUBJ
|                           3. New macro parameter DELETEMISMERGES
|                           4. Change to CRF/SMS merge vars to allow for inclusion of SUBJID per MERGEINCSUBJ
|                           5. Change to CRF/SMS merge to allow for deletion of records reported as unmerged
|                           6. Surfacing tu_pkcncderv parameter IMPUTEBY, change of defaults
|                           7. Change to exception reporting to report missing from CRF and missing from SMS
|                              in two separate sections of the exception file
|                           8. Add ELTMSTDUNIT parameter to pass to tu_pkcncderv 
|                           9. Add DVTMSTDUNIT parameter to pass to tu_pkcncderv 
|
********************************************************************************/ 

%macro tu_cr8arpk(
    dsetin=                     /* type:ID Name of input DM PK dataset */
   ,dsetinperiod=ardata.period  /* type:ID Name of input SI PERIOD dataset */
   ,dsetinexp = ARDATA.EXPOSURE /* type:ID Name of input A&R EXPOSURE dataset */
   ,expjoinbyvars = &g_centid &g_subjid pernum period visitnum visit /* Variables by which exposure is merged with PK data */
   ,dsetout=                    /* Output dataset */
   ,smsfile=                    /* type:IF Name of input SMS2000 file */
   ,smskeep=PCSMPID PCSPEC PCAN PCLLQC PCORRES PCORRESU subjid2000 /* Passed to %tu_getsms2k as its KEEP parameter */
   ,smsrename=                  /* Passed to %tu_getsms2k as its RENAME parameter */
   ,smsdelim=|                  /* Passed to %tu_getsms2k as its DELIM parameter */
   ,joinmsg=WARNING             /* Type of messages to be issued from joins (error or warning) */
   ,PCWTU = g                   /* Value to be placed into PCWTU variable */
   ,eltmstdunit=HRS             /* Units to which ELTMSTN values shall be standardised */
   ,dvtmstdunit=HRS             /* Units to which derived durations shall be standardised */
   ,imputeby=&g_centid &g_subjid pctypcd pcan pernum visitnum pcrfdsdm ptmnum /* Variables to impute by */
   ,imputetype=S                /* Imputation type. Specifies either standard (S) or alternative (A) imputation */
   ,mergeincsubj=N              /* Option to include SUBJID in PK merge. If Y, merge on SUBJID PCSMPID, if N, merge on PCSMPID  */
   ,deletemismerges=Y           /* Option to delete miserged records. If Y, only records which exist in both DM dataset and SMS will be retained. */
    );

  /*
  / Echo macro version number and values of parameters and global macro
  / variables to the log.
  /----------------------------------------------------------------------------*/
  %local MacroVersion /* Carries macro version number */
         prefix       /* Carries file prefix for work files */
         __debug_obs; /* Sets debug maximum number of observations */

  %let MacroVersion = 2;
  %let prefix=%substr(&sysmacroname,3);

  %include "&g_refdata/tr_putlocals.sas";
  %tu_putglobals(varsin=g_subjid g_dsplanfile)

  %if &g_debug ge 3 %then %let __debug_obs=obs=max;
  %else                   %let __debug_obs=obs=100;

  /*
  / PARAMETER VALIDATION
  /----------------------------------------------------------------------------*/
  %let dsetin=%nrbquote(&dsetin.);
  %let dsetout=%nrbquote(&dsetout.);
  %let dsetinperiod=%nrbquote(&dsetinperiod.); 
  %let mergeincsubj=%nrbquote(&mergeincsubj.); 
  %let deletemismerges=%nrbquote(&deletemismerges.); 

  %if %length(&dsetin)eq 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname: The DSETIN parameter must not be blank;
    %let g_abort=1;
  %end;
  %else
  %do;
    %if not %sysfunc(exist(&dsetin)) %then
    %do;
      %put RTE%str(RROR): &sysmacroname: The DSETIN dataset (&dsetin) does not exist;
      %let g_abort=1;
    %end;
  %end;

  %if %length(&dsetinperiod) gt 0 %then
  %do;
    %if not %sysfunc(exist(&dsetinperiod)) %then
    %do;
      %put RTE%str(RROR): &sysmacroname: The DSETINPERIOD dataset (&dsetinperiod) does not exist;
      %let g_abort=1;
    %end;
  %end;

  %if %length(&dsetout)eq 0 %then
  %do;
    %put RTE%str(RROR): &sysmacroname: The DSETOUT parameter must not be blank;
    %let g_abort=1;
  %end;
  %else
  %do;
    %if %length(%tu_chknames(&dsetout,DATA)) ne 0 %then
    %do;
      %put RTE%str(RROR): &sysmacroname: The DSETOUT parameter (&dsetout) does not specify a valid dataset name;
      %let g_abort=1;
    %end;
  %end;

/* WJB1: validation for new parameters  */
  %if &mergeincsubj ne N and &mergeincsubj ne Y %then %do;
    %put RTE%str(RROR): &sysmacroname: MERGEINCSUBJ=&mergeincsubj is not a valid selection. Valid values: Y or N;
    %let g_abort=1;  
  %end;

  %if &deletemismerges ne N and &deletemismerges ne Y %then %do;
    %put RTE%str(RROR): &sysmacroname: DELETEMISMERGES=&deletemismerges is not a valid selection. Valid values: Y or N;
    %let g_abort=1;  
  %end;

  /* SMSFILE, SMSKEEP, SMSRENAME, and SMSDELIM are validated by the tu_getsms2k macro
  /  JOINMSG is validated by the tu_xcpput macro
  /  PCWTU is validated by the tu_pkcncderv macro 
  /----------------------------------------------------------------------------    */

  %tu_abort;

  /*
  / NORMAL PROCESSING
  /----------------------------------------------------------------------------*/

  /* Get sms2k data, adjust attributes of vars to match Dataset Plan, and sort */
  %tu_getsms2k(smsfile=&smsfile
              ,keep=&smskeep
              ,rename=&smsrename
              ,dsetout=&prefix._sms2k_10
              ,delim=&smsdelim
              );

  /* What vars are in sms2k dataset? */
  %local sms2kvars;
  proc sql noprint;
    select name into: sms2kvars separated by ' '
      from sashelp.vcolumn
      where libname eq "WORK"
            and memname eq "%upcase(&prefix._sms2k_10)"
            ;
  quit;
  %if &g_debug ge 1 %then
  %do;
    %put RT%str(DEB)UG: &sysmacroname: SMS2KVARS=&sms2kvars;
  %end;

  /* For each var in sms2k dataset, see if it is in Plan, if so get attributes */
  %local i;
  %local sms2kvname0;
  %do i=1 %to %tu_words(string=&sms2kvars);
    %local sms2kvname&i sms2kvfound&i sms2kvattrib&i;
  %end;

  %tu_maclist(string=&sms2kvars
             ,prefix=sms2kvname
             ,cntname=sms2kvname0
             ,scope=local
             );
  %if &g_debug ge 1 %then
  %do;
    %put RT%str(DEB)UG: &sysmacroname: SMS2KVNAME0=&sms2kvname0;
    %do i=1 %to &sms2kvname0;
      %put RT%str(DEB)UG: &sysmacroname: SMS2KVNAME&i=&&&sms2kvname&i;
    %end;
  %end; 

  %tu_readdsplan(dsetout=work.&prefix._dsplan);

  %do i=1 %to &sms2kvname0;
    %let SMS2KVFOUND&i = %tu_isvarindsplan(dsetin=work.&prefix._dsplan
                                          ,var=&&&SMS2KVNAME&i
                                          ,attribmvar=SMS2KVATTRIB&i
                                          );
    %if &g_debug ge 1 %then
    %do;
      %put RT%str(DEB)UG: &sysmacroname: SMS2KVNAME&i=&&&sms2kvname&i; 
      %put RT%str(DEB)UG: &sysmacroname: SMS2KVFOUND&i=&&&sms2kvfound&i;
      %put RT%str(DEB)UG: &sysmacroname: SMS2KVATTRIB&i=&&&sms2kvattrib&i;
    %end;
  %end;

  /* Apply attributes */
  data &prefix._sms2k_20;
    attrib %do i=1 %to &sms2kvname0;
             %if &&&sms2kvfound&i eq Y %then
             %do;
               &&&sms2kvname&i &&&sms2kvattrib&i
             %end;
           %end;
           ;
    set &prefix._sms2k_10;
  run;

  /* If MERGEINCSUBJ=Y, pre-define merge vars to include SUBJID
  /  and ensure variable SUBJID exists in SMS2K dataset 
  ---------------------------------------------------- */ /* WJB1 */
  %local mergevars mergevarssql;
  data &prefix._sms2k_25;
    set &prefix._sms2k_20;
    %if "&mergeincsubj"="Y" %then %do;
      %let mergevars = SUBJID PCSMPID;
      %let mergevarssql = SUBJID, PCSMPID;
      subjid=input(subjid2000,8.);  /* WJB1 */
    %end;
    %else %do;
      %let mergevars = PCSMPID;
      %let mergevarssql = PCSMPID;
    %end;
  run;

  proc sort data=&prefix._sms2k_25 out=&prefix._sms2k_byid; /* WJB1 */
    by &mergevars;
  run;

  /* Sort input DM PK dataset, ready for merge with sms2k, and
  / rename variables too                                     
  /------------------------------------------------------------- */

  /* Prepare renames */
  %local renames;
  data _null_;
    set sashelp.vcolumn;
    %if %index(&dsetin,.) %then
    %do;
      where libname eq "%upcase(%scan(&dsetin,1,.))"
            and memname eq "%upcase(%scan(&dsetin,2,.))"
            ;
    %end;
    %else
    %do;
      where libname eq "WORK"
            and memname eq "%upcase(&dsetin)"
            ;
    %end;
    length renames $400;
    retain renames;
    select (upcase(name));
      when ("PKALLCOL") renames = trim(renames) !! " PKALLCOL=PCALLCOL";
      when ("PKSMPPH")  renames = trim(renames) !! " PKSMPPH=PCPH";
      when ("PKSEQ")    renames = trim(renames) !! " PKSEQ=PCSEQ";
      when ("PKSMPID")  renames = trim(renames) !! " PKSMPID=PCSMPID";
      when ("PKTYP")    renames = trim(renames) !! " PKTYP=PCTYP"; 
      when ("PKTYPCD")  renames = trim(renames) !! " PKTYPCD=PCTYPCD";
      when ("PKSMPVOL") renames = trim(renames) !! " PKSMPVOL=PCVOL"; 
      when ("PKSMPWT")  renames = trim(renames) !! " PKSMPWT=PCWT"; 
      when ("PKSTDT")   renames = trim(renames) !! " PKSTDT=PCSTDT"; 
      when ("PKSTTM")   renames = trim(renames) !! " PKSTTM=PCSTTM"; 
      when ("PKENDT")   renames = trim(renames) !! " PKENDT=PCENDT"; 
      when ("PKENTM")   renames = trim(renames) !! " PKENTM=PCENTM"; 
      otherwise; /* No rename reqd */
    end;
    call symput('RENAMES',renames);
  run;
  %if &g_debug ge 1 %then
  %do;
    %put RT%str(DEB)UG: &sysmacroname: RENAMES=&renames;
  %end;
  
  /* Do the sort, and apply the renames [WJB1] */
  proc sort data=&dsetin (rename=(&renames))
            out=&prefix._dmpk_byid;
    by &mergevars;  /* WJB1 */
  run;

  /* Check for duplicate merge vars in the PK SI dataset */ /* WJB1 */  
  proc sql;
  create table &prefix._duptemp as
    select *, count(*) as dupcount
    from &prefix._dmpk_byid
    group by &mergevarssql
    having count(*)>1;
  quit;
  proc sort data=&prefix._duptemp nodupkeys;
    by &mergevars;
  run;

  /* Count no. of sets of duplicate records  */
  %local dscount obscount;
  %let dscount=%sysfunc(OPEN(&prefix._duptemp,I));
  %let obscount=%eval(%sysfunc(ATTRN(&dscount,NOBS)));
  %let rc=%sysfunc(CLOSE(&dscount));

  /* Return errors as appropriate */
  %if &obscount > 0 %then %do;
    %if &obscount > 1 %then %do;
      %put RTE%str(RROR): &sysmacroname: There are &obscount sets of records with duplicate merge variables in DSETIN (&dsetin);
    %end;
    %else %if &obscount > 0 %then %do;
      %put RTE%str(RROR): &sysmacroname: There is 1 set of records with duplicate merge variables in DSETIN (&dsetin);
    %end;
    data _null_;
      set &prefix._duptemp end=finish;
      %if "&mergeincsubj"="Y" %then %do;
        put "RTE" "RROR: &sysmacroname: Duplicate merge variables: " SUBJID=", PKSMPID= " PCSMPID "- " dupcount " records.";
      %end;
      %else %do;
        put "RTE" "RROR: &sysmacroname: Duplicate merge variables: PKSMPID=" PCSMPID " - " dupcount " records.";
      %end;
    run;
    %let g_abort=1;  
  %end;
  %tu_abort;

  /* Merge the sms2k data with the DM PK data
  /  and perform exception reporting          
  /----------------------------------------------- */ /* WJB1 */

  /* 1 - Flag data from SMS2K but not CRF                 */
  data &prefix._pksmstemp;
    merge &prefix._dmpk_byid  (in=fromCRF)
          &prefix._sms2k_byid (in=fromSMS)
          end=finish;
    by &mergevars;  /* WJB1 */
    endrow=finish;
    fromCRFb=fromCRF;
    fromSMSb=fromSMS;
    %tu_xcpsectionInit(header=Merge CRF Data with SMS2K Data - Data from SMS2K but not CRF);
    if not fromCRF then do;
      %tu_byid(dsetin=&prefix._sms2k_byid
              ,invars=pcsmpid subjid2000
              ,outvar=__msg);
      %tu_xcpput("Data from SMS2K but not CRF: " !! __msg,&joinmsg);
    end;
    %tu_xcpsectionTerm(end=finish);
  run;

  /* 2 - Flag data from CRF but not SMS2K,
  /  and output rows to dataset per DELETEMISMERGES       
  /--------------------------------------------------- */
  data &prefix._pksms;
    set &prefix._pksmstemp;
    drop __msg subjid2000 endrow fromCRFb fromSMSb;
    %tu_xcpsectionInit(header=Merge CRF Data with SMS2K Data - Data from CRF but not SMS2K);
    if not fromSMSb then do;
        %tu_byid(dsetin=&prefix._dmpk_byid
                ,invars=&g_subjid visit ptm pcsmpid
                ,outvar=__msg);
        %tu_xcpput("Data from CRF but not SMS2K: " !! __msg,&joinmsg);
    end;
    if not fromCRFb or not fromSMSb then do;
      %if "&deletemismerges"="Y" %then %do;  /* WJB1 */
        delete;
      %end;
    end;
    %tu_xcpsectionTerm(end=endrow);
  run;
  %tu_abort;

  %if &g_debug ge 1 %then
  %do;
    title "RTD" "EBUG: &sysmacroname: Output From SMS2k Merge (&prefix._pksms) "
          'from %TU_CR8APRK';
    proc contents data=&prefix._pksms;
    run;
  %end;
  %if &g_debug ge 2 %then
  %do;
    title "RTD" "EBUG: &sysmacroname: Output From SMS2k Merge (&prefix._pksms, &__debug_obs) "
          'from %TU_CR8ARPK';
    proc print data=&prefix._pksms(&__debug_obs);
    run;
  %end;

  %tu_pkcncderv(DSETIN= &prefix._pksms
               ,DSETOUT= &prefix._pkcncderv
               ,dsetinperiod=&dsetinperiod
               ,dsetinexp=&dsetinexp
               ,expjoinbyvars=&expjoinbyvars
               ,joinmsg=&joinmsg
               ,pcwtu=&pcwtu
               ,eltmstdunit=&eltmstdunit /* WJB1  */
               ,dvtmstdunit=&dvtmstdunit /* WJB1  */
               ,imputeby=&imputeby       /* WJB1  */
               ,imputetype=&imputetype   /* WJB1  */
               );

  %tu_attrib(dsetin=&prefix._pkcncderv
            ,dsetout=&dsetout
            ,dsplan=&g_dsplanfile
            );

  %tu_tidyup(rmdset=&prefix:
            ,glbmac=NONE
            );
  quit;

  %tu_abort;

%mend tu_cr8arpk;
